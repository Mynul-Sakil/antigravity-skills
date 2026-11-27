# Exness Strategy & Indicator Reference

## 1. Exness Web Terminal — TakeProfit Indie v5

### Mandatory Structure & Imports
- Line 1 **must** be `# indie:lang_version = 5`.
- Allowed import roots: `math`, `indie`, `indie.algorithms`, `indie.math`.
- Exness Indie Script Editor accepts **one self-contained file** per indicator (do not split into local module imports).
- Use `class Main(MainContext):` when holding config attributes or list history, or `def Main(self, ...):` for simple indicators.

### Verified Constants & Types
- **`indie.color`**: Supported constants include `BLUE`, `AQUA`, `ORANGE`, `PURPLE`, `RED`, `GREEN`, `YELLOW`, `WHITE`, `GRAY`, `BLACK`, `FUCHSIA`, `LIME`, `MAROON`, `NAVY`, `OLIVE`, `SILVER`, `TEAL`, plus `color.rgba(...)` and `color.hex(...)`. Alpha transparency uses `color.BLUE(alpha=0.65)`.
  - **Trap**: `color.CYAN` does **not** exist (`Unknown member`). Always use `color.BLUE` or `color.AQUA`.
- **`indie.line_style`**: `SOLID`, `DASHED`, `DOTTED`.
- **`indie.plot.marker_style`**: `CIRCLE`, `CROSS`, `LABEL`, `NONE`.
- **`indie.plot.marker_position`**: `ABOVE`, `BELOW`, `CENTER`.

### Strict Static Typing & Compiler Traps
1. **No variable type rebinding**: Never reuse a `MutSeriesF.new(...)` variable name for a scalar `float`.
   - Wrong: `prev_sl = MutSeriesF.new(init=nan)` followed later by `prev_sl = active_sl[1]`.
   - Right: Name scalar snapshots distinctly (`prev_active_sl = active_sl[1]`).
2. **Nullable strings require `Optional[str]`**:
   - Wrong: `lbl = None` then `lbl = 'BUY'`.
   - Right: `from indie import Optional` and `lbl: Optional[str] = None`.
3. **Explicit container typing**: Annotate lists explicitly, e.g. `self._htf_highs: list[float] = []`.
4. **Helper function signatures**: Annotate parameter and return types on module-level helpers (e.g. `def _is_pivot_high(vals: list[float], left: int, right: int) -> bool:`).
5. **Plot decorator alignment**: The count and top-to-bottom order of `@plot.*` decorators on `Main` must **strictly match** the tuple returned by `Main.calc()` (or `def Main()`).

### Live-Tick-Safe State (`MutSeriesF`)
- Instantiate `MutSeriesF.new(init=...)` unconditionally at the top of `Main.calc(self)` (never inside conditional `if` branches).
- Compute bar `[0]` strictly from `[1]` plus current bar inputs so live intrabar ticks never corrupt historical state.
- Call built-in algorithms (`Atr.new(14)`, `Sma.new(self.volume, 20)`) unconditionally every bar.

### Multi-Timeframe Reliability on Exness Terminal
- **Known Exness runtime failure**: `self.calc_on(..., time_frame=...)` and `@param.time_frame` can fail with `"The selected timeframe is not supported"` on Exness Web Terminal (e.g., when the chart timeframe is `>=` the requested timeframe or the symbol feed restricts secondary timeframe requests).
- **Known Exness compiler failure**: `@param_ref` on `@sec_context` functions alongside `class Main(MainContext)` triggers missing-parameter errors on the referenced parameter.
- **Recommended Solution — Native `self.time[0]` Resampling**:
  - Aggregate bars inside `Main.calc(self)` using UTC timestamp buckets:
    ```python
    t_sec = raw_t / 1000.0 if raw_t > 1.0e11 else raw_t
    bucket = float(floor(t_sec / float(minutes * 60)))
    ```
  - Track the forming candle in `MutSeriesF` (`cur_bucket`, `cur_h`, `cur_l`, `cur_c`, `cur_v`).
  - Commit `(cur_h[1], cur_l[1], cur_c[1], cur_v[1])` to typed history lists (`self._htf_highs`, etc.) **only when `bucket > prev_bucket`**, guarded by `self._last_committed_bucket` to prevent duplicate appends on live ticks.
  - Supports arbitrary non-standard intervals (such as `45m` fallback when `15m` is neutral or choppy) with zero repainting.

---

## 2. Exness MetaTrader 5 (MQL5) Indicators & Expert Advisors

### Indicators (`.mq5`)
- Use `#property indicator_chart_window` for overlays and `SetIndexBuffer(..., INDICATOR_DATA)` with `PLOT_ARROW` / `EMPTY_VALUE`.
- Always read completed higher-timeframe and entry-timeframe bars at **`shift = 1`** (`iHigh`, `iLow`, `iClose`, `iTickVolume`) so historical signals never repaint.
- Add optional `SendNotification(...)` / `Alert(...)` guarded by a static `lastAlertTime` per bar.

### Automated Expert Advisors (`.mq5`)
- Use `#include <Trade\Trade.mqh>` (`CTrade trade;`) and isolate orders with `trade.SetExpertMagicNumber(InpMagic)`.
- **New-bar execution gate**: Trigger entry logic only when `iTime(_Symbol, PERIOD_M1, 0) != lastBarTime`.
- **Dynamic Lot Sizing**: Compute volume from risk %, SL distance in price, `SYMBOL_TRADE_TICK_VALUE`, and `SYMBOL_TRADE_TICK_SIZE`, clamped and stepped to `SYMBOL_VOLUME_MIN`, `SYMBOL_VOLUME_MAX`, and `SYMBOL_VOLUME_STEP`.
- **Broker Guardrails**:
  - Respect `SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)` before sending SL/TP.
  - Guard against wide spreads (`maxSpreadPoints`) during session rollovers or news spikes.
  - Include symmetric BUY and SELL position checks (`PositionsTotal()` filtered by `_Symbol` + `InpMagic`).
- **Rollout Sequence**: Compile cleanly in MetaEditor (0 errors) -> MT5 Strategy Tester (`Every tick based on real ticks`) -> Exness Demo account -> Exness VPS or MT5 VPS for 24/7 execution.
