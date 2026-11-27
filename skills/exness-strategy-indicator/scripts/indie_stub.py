"""Lightweight pure-Python emulation of the TakeProfit Indie v5 runtime.

Allows importing and executing real production Indie v5 scripts under unittest
with non-lookahead multi-timeframe bar aggregation and per-bar MutSeriesF state.
"""

from __future__ import annotations

import importlib.util
from math import isnan, nan
from pathlib import Path
import sys
import types
from typing import Any, Callable, Optional


class SeriesF:
    """Read-only reverse-indexed float series ([0] is current bar, [1] is prior)."""

    def __init__(self, data: list[float] | None = None) -> None:
        self._data: list[float] = data if data is not None else []
        self._cursor: int = -1

    def _set_cursor(self, idx: int) -> None:
        self._cursor = idx

    def _push(self, val: float) -> None:
        self._data.append(float(val))
        self._cursor = len(self._data) - 1

    def __getitem__(self, offset: int) -> float:
        if offset < 0:
            raise IndexError("Indie series offset must be >= 0")
        pos = self._cursor - offset
        if pos < 0 or pos >= len(self._data):
            return nan
        return self._data[pos]


class MutSeriesF(SeriesF):
    """Mutable per-bar float series whose history advances one slot per bar."""

    def __init__(self, default: float = nan, size: int = 2) -> None:
        super().__init__([])
        self._default = float(default)
        self._size = size

    def _advance(self) -> None:
        self._data.append(self._default)
        self._cursor = len(self._data) - 1

    def __setitem__(self, offset: int, val: float) -> None:
        if offset != 0:
            raise IndexError("Only offset [0] can be assigned on MutSeriesF")
        if self._cursor < 0:
            self._advance()
        self._data[self._cursor] = float(val)

    @classmethod
    def new(
        cls,
        reset: float | None = None,
        init: float | None = None,
        size: int = 2,
    ) -> "MutSeriesF":
        ctx = _ACTIVE_CONTEXT
        if ctx is None:
            raise RuntimeError("MutSeriesF.new must be called inside an active Indie context")
        default_val = nan if init is None else float(init)
        s = ctx._next_mut_slot(default=default_val, size=size)
        if reset is not None:
            s[0] = float(reset)
        return s


class TimeFrame:
    """Represents an Indie TimeFrame parsed from string notation."""

    _MULTIPLIERS = {
        "m": 1,
        "h": 60,
        "D": 1440,
        "W": 10080,
    }

    def __init__(self, spec: str, minutes: int) -> None:
        self.spec = spec
        self.minutes = minutes

    @classmethod
    def from_str(cls, spec: str) -> "TimeFrame":
        unit = spec[-1]
        if unit not in cls._MULTIPLIERS:
            raise ValueError(f"Unsupported TimeFrame string: {spec}")
        qty = int(spec[:-1])
        return cls(spec=spec, minutes=qty * cls._MULTIPLIERS[unit])


class ColorValue:
    """Callable color constant supporting alpha transparency e.g. color.GREEN(0.5)."""

    def __init__(self, name: str, alpha: float = 1.0) -> None:
        self.name = name
        self.alpha = alpha

    def __call__(self, alpha: float) -> "ColorValue":
        return ColorValue(self.name, alpha=alpha)

    def __repr__(self) -> str:
        return f"Color({self.name}, alpha={self.alpha})"


class MarkerValue:
    """Represents a plotted chart marker returned by Main.calc()."""

    def __init__(
        self,
        value: float = nan,
        text: str | None = None,
        color: ColorValue | None = None,
    ) -> None:
        self.value = float(value)
        self.text = text
        self.color = color


class LineValue:
    """Represents a plotted chart line point returned by Main.calc()."""

    def __init__(self, value: float = nan, offset: int = 0) -> None:
        self.value = float(value)
        self.offset = offset


class _MarkerStyle:
    CIRCLE = "CIRCLE"
    CROSS = "CROSS"
    LABEL = "LABEL"
    NONE = "NONE"


class _MarkerPosition:
    ABOVE = "ABOVE"
    BELOW = "BELOW"
    CENTER = "CENTER"


class _LineStyle:
    SOLID = "SOLID"
    DASHED = "DASHED"
    DOTTED = "DOTTED"


class _PlotNamespace:
    Line = LineValue
    Marker = MarkerValue
    marker_style = _MarkerStyle
    marker_position = _MarkerPosition

    @staticmethod
    def line(**kwargs: Any) -> Callable[[Any], Any]:
        def decorator(target: Any) -> Any:
            plots = list(getattr(target, "_indie_plots", []))
            plots.insert(0, {"kind": "line", **kwargs})
            target._indie_plots = plots
            return target

        return decorator

    @staticmethod
    def marker(**kwargs: Any) -> Callable[[Any], Any]:
        def decorator(target: Any) -> Any:
            plots = list(getattr(target, "_indie_plots", []))
            plots.insert(0, {"kind": "marker", **kwargs})
            target._indie_plots = plots
            return target

        return decorator


class _ParamNamespace:
    @staticmethod
    def _register(kind: str, param_id: str, default: Any, **kwargs: Any) -> Callable[[Any], Any]:
        def decorator(target: Any) -> Any:
            params = list(getattr(target, "_indie_params", []))
            params.insert(0, {"kind": kind, "id": param_id, "default": default, **kwargs})
            target._indie_params = params
            return target

        return decorator

    @classmethod
    def int(cls, param_id: str, default: int = 0, **kwargs: Any) -> Callable[[Any], Any]:
        return cls._register("int", param_id, default, **kwargs)

    @classmethod
    def float(cls, param_id: str, default: float = 0.0, **kwargs: Any) -> Callable[[Any], Any]:
        return cls._register("float", param_id, default, **kwargs)

    @classmethod
    def bool(cls, param_id: str, default: bool = False, **kwargs: Any) -> Callable[[Any], Any]:
        return cls._register("bool", param_id, default, **kwargs)

    @classmethod
    def str(cls, param_id: str, default: str = "", **kwargs: Any) -> Callable[[Any], Any]:
        return cls._register("str", param_id, default, **kwargs)

    @classmethod
    def time_frame(cls, param_id: str, default: str = "15m", **kwargs: Any) -> Callable[[Any], Any]:
        return cls._register("time_frame", param_id, default, **kwargs)


def param_ref(param_id: str) -> Callable[[Any], Any]:
    """Attach a parameter reference ID onto a secondary context function."""

    def decorator(target: Any) -> Any:
        refs = list(getattr(target, "_indie_param_refs", []))
        refs.insert(0, param_id)
        target._indie_param_refs = refs
        return target

    return decorator


def indicator(title: str, overlay_main_pane: bool = True, **kwargs: Any) -> Callable[[Any], Any]:
    def decorator(target: Any) -> Any:
        target._indie_indicator = {"title": title, "overlay_main_pane": overlay_main_pane, **kwargs}
        return target

    return decorator


def sec_context(fn: Callable[..., Any]) -> Callable[..., Any]:
    fn._is_sec_context = True
    return fn


_ACTIVE_CONTEXT: "_BaseContext | None" = None


class _AlgoSeriesRegistry:
    """Tracks per-call-site algorithm state inside an active context."""

    def __init__(self) -> None:
        self._slots: list[SeriesF] = []
        self._call_idx: int = 0

    def reset_bar(self) -> None:
        self._call_idx = 0

    def next_slot(self, factory: Callable[[], SeriesF]) -> SeriesF:
        idx = self._call_idx
        self._call_idx += 1
        if idx >= len(self._slots):
            self._slots.append(factory())
        return self._slots[idx]


class _SmaAlgo:
    @staticmethod
    def new(source: SeriesF, length: int) -> SeriesF:
        ctx = _ACTIVE_CONTEXT
        if ctx is None:
            raise RuntimeError("Sma.new must be called inside an active Indie context")
        series = ctx._algo_registry.next_slot(SeriesF)
        values: list[float] = []
        valid = True
        for i in range(length):
            v = source[i]
            if isnan(v):
                valid = False
                break
            values.append(v)
        series._push(sum(values) / length if valid and length > 0 else nan)
        return series


class _AtrAlgo:
    @staticmethod
    def new(length: int) -> SeriesF:
        ctx = _ACTIVE_CONTEXT
        if ctx is None:
            raise RuntimeError("Atr.new must be called inside an active Indie context")
        series = ctx._algo_registry.next_slot(SeriesF)
        tr_vals: list[float] = []
        valid = True
        for i in range(length):
            h = ctx.high[i]
            l = ctx.low[i]
            prev_c = ctx.close[i + 1]
            if isnan(h) or isnan(l):
                valid = False
                break
            if isnan(prev_c):
                tr = h - l
            else:
                tr = max(h - l, abs(h - prev_c), abs(l - prev_c))
            tr_vals.append(tr)
        series._push(sum(tr_vals) / length if valid and length > 0 else nan)
        return series


class _BaseContext:
    def __new__(cls, *args: Any, **kwargs: Any) -> "_BaseContext":
        obj = super().__new__(cls)
        obj.open = SeriesF()
        obj.high = SeriesF()
        obj.low = SeriesF()
        obj.close = SeriesF()
        obj.volume = SeriesF()
        obj.time = SeriesF()
        obj.bar_index = -1
        obj._mut_series = []
        obj._algo_registry = _AlgoSeriesRegistry()
        obj._mut_cursor = 0
        obj._has_mut_init = False
        return obj

    def _next_mut_slot(self, default: float = nan, size: int = 2) -> MutSeriesF:
        idx = self._mut_cursor
        self._mut_cursor += 1
        if idx >= len(self._mut_series):
            s = MutSeriesF(default=default, size=size)
            s._advance()
            self._mut_series.append(s)
            return s
        return self._mut_series[idx]

    def new_mut_series_f(self, default: float = nan, size: int = 2) -> MutSeriesF:
        return self._next_mut_slot(default=default, size=size)

    def _push_bar(self, bar: dict[str, float], bar_idx: int) -> None:
        self.bar_index = bar_idx
        self.time._push(bar["time"])
        self.open._push(bar["open"])
        self.high._push(bar["high"])
        self.low._push(bar["low"])
        self.close._push(bar["close"])
        self.volume._push(bar["volume"])
        for s in self._mut_series:
            s._advance()
        self._mut_cursor = 0
        self._algo_registry.reset_bar()


class SecContext(_BaseContext):
    pass


class MainContext(_BaseContext):
    def __new__(cls, *args: Any, **kwargs: Any) -> "MainContext":
        obj = super().__new__(cls, *args, **kwargs)
        obj._sec_bindings = []
        return obj

    def calc_on(
        self,
        sec_context: Any,
        exchange: str | None = None,
        ticker: str | None = None,
        time_frame: TimeFrame | str | None = None,
        *,
        source: Any = None,
        lookahead: bool = False,
    ) -> SeriesF | tuple[SeriesF, ...]:
        tf = TimeFrame.from_str(time_frame) if isinstance(time_frame, str) else time_frame
        if tf is None:
            tf = TimeFrame.from_str("15m")

        out_series = tuple(SeriesF() for _ in range(5))
        binding = {
            "fn": sec_context,
            "time_frame": tf,
            "lookahead": lookahead,
            "outputs": out_series,
            "ctx": SecContext(),
            "last_closed_vals": tuple(nan for _ in range(5)),
        }
        self._sec_bindings.append(binding)
        return out_series


def install_indie_stub() -> types.ModuleType:
    """Install fake `indie` and submodules into sys.modules."""
    indie_mod = types.ModuleType("indie")
    indie_algo = types.ModuleType("indie.algorithms")

    color_ns = types.SimpleNamespace(
        GREEN=ColorValue("GREEN"),
        RED=ColorValue("RED"),
        AQUA=ColorValue("AQUA"),
        ORANGE=ColorValue("ORANGE"),
        PURPLE=ColorValue("PURPLE"),
        YELLOW=ColorValue("YELLOW"),
        WHITE=ColorValue("WHITE"),
        GRAY=ColorValue("GRAY"),
        BLUE=ColorValue("BLUE"),
    )

    indie_mod.indicator = indicator
    indie_mod.sec_context = sec_context
    indie_mod.param = _ParamNamespace
    indie_mod.param_ref = param_ref
    indie_mod.plot = _PlotNamespace
    indie_mod.color = color_ns
    indie_mod.line_style = _LineStyle
    indie_mod.MainContext = MainContext
    indie_mod.SecContext = SecContext
    indie_mod.SeriesF = SeriesF
    indie_mod.MutSeriesF = MutSeriesF
    indie_mod.Optional = Optional
    indie_mod.TimeFrame = TimeFrame

    indie_algo.Sma = _SmaAlgo
    indie_algo.Atr = _AtrAlgo
    indie_mod.algorithms = indie_algo

    sys.modules["indie"] = indie_mod
    sys.modules["indie.algorithms"] = indie_algo
    return indie_mod


def load_indicator_module(script_path: str | Path) -> types.ModuleType:
    """Load the Indie indicator script against the installed indie stub."""
    install_indie_stub()
    path = Path(script_path)
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module spec from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _aggregate_htf_bars(bars_1m: list[dict[str, float]], tf_minutes: int) -> list[dict[str, Any]]:
    """Aggregate 1m bars into higher-timeframe buckets, tracking close 1m index."""
    bucket_sec = tf_minutes * 60
    htf_bars: list[dict[str, Any]] = []
    cur_bucket: int | None = None
    cur: dict[str, Any] | None = None

    for idx, b in enumerate(bars_1m):
        bucket = int(b["time"]) // bucket_sec
        if cur_bucket is None or bucket != cur_bucket:
            if cur is not None:
                htf_bars.append(cur)
            cur_bucket = bucket
            cur = {
                "bucket": bucket,
                "time": float(bucket * bucket_sec),
                "open": float(b["open"]),
                "high": float(b["high"]),
                "low": float(b["low"]),
                "close": float(b["close"]),
                "volume": float(b["volume"]),
                "close_1m_idx": idx,
            }
        else:
            assert cur is not None
            cur["high"] = max(cur["high"], float(b["high"]))
            cur["low"] = min(cur["low"], float(b["low"]))
            cur["close"] = float(b["close"])
            cur["volume"] += float(b["volume"])
            cur["close_1m_idx"] = idx

    if cur is not None:
        htf_bars.append(cur)
    return htf_bars


def run_indicator(
    script_path: str | Path,
    bars_1m: list[dict[str, float]],
    params: dict[str, Any] | None = None,
) -> list[tuple[Any, ...]]:
    """Execute the Indie v5 Main indicator across 1m bars with non-lookahead HTF sync."""
    global _ACTIVE_CONTEXT
    mod = load_indicator_module(script_path)
    main_cls = mod.Main
    declared_params = getattr(main_cls, "_indie_params", [])
    overrides = params or {}

    init_kwargs: dict[str, Any] = {}
    for p in declared_params:
        val = overrides.get(p["id"], p["default"])
        if p["kind"] == "time_frame" and isinstance(val, str):
            val = TimeFrame.from_str(val)
        init_kwargs[p["id"]] = val

    instance: MainContext = main_cls(**init_kwargs)
    instance._has_mut_init = bool(instance._mut_series)

    htf_events_by_1m_idx: dict[int, list[tuple[dict[str, Any], tuple[float, ...]]]] = {}
    for binding in instance._sec_bindings:
        tf_min = binding["time_frame"].minutes
        htf_bars = _aggregate_htf_bars(bars_1m, tf_min)
        sec_ctx: SecContext = binding["ctx"]
        fn = binding["fn"]
        ref_ids = getattr(fn, "_indie_param_refs", [])
        ref_args = [init_kwargs[rid] for rid in ref_ids]

        bucket_sec = tf_min * 60
        for h_idx, hbar in enumerate(htf_bars):
            is_last = h_idx == len(htf_bars) - 1
            if is_last:
                last_1m_ts = int(bars_1m[hbar["close_1m_idx"]]["time"])
                if (last_1m_ts - int(hbar["time"])) < (bucket_sec - 60):
                    continue

            sec_ctx._push_bar(hbar, h_idx)
            _ACTIVE_CONTEXT = sec_ctx
            try:
                res = fn(sec_ctx, *ref_args)
            finally:
                _ACTIVE_CONTEXT = None
            sec_ctx._has_mut_init = True
            vals = tuple(float(v) for v in res) if isinstance(res, tuple) else (float(res),)

            visible_from_1m_idx = hbar["close_1m_idx"] + 1
            if visible_from_1m_idx < len(bars_1m):
                htf_events_by_1m_idx.setdefault(visible_from_1m_idx, []).append((binding, vals))

    results: list[tuple[Any, ...]] = []
    for idx, bar in enumerate(bars_1m):
        for binding, vals in htf_events_by_1m_idx.get(idx, []):
            binding["last_closed_vals"] = vals

        for binding in instance._sec_bindings:
            for s, v in zip(binding["outputs"], binding["last_closed_vals"]):
                s._push(v)

        instance._push_bar(bar, idx)
        _ACTIVE_CONTEXT = instance
        try:
            out = instance.calc()
        finally:
            _ACTIVE_CONTEXT = None
        instance._has_mut_init = True
        results.append(out if isinstance(out, tuple) else (out,))

    return results
