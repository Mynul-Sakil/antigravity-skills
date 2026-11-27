# Exness Strategy & Indicator Examples

## 1. Minimal Exness Indie v5 BUY/SELL Overlay Indicator

```python
# indie:lang_version = 5
from math import isnan, nan
from indie import indicator, param, plot, color, line_style, MainContext, MutSeriesF, Optional
from indie.algorithms import Sma, Atr


@indicator('Minimal BUY/SELL Example', overlay_main_pane=True)
@param.int('fast_len', default=9, min=1, title='Fast SMA')
@param.int('slow_len', default=21, min=1, title='Slow SMA')
@plot.line(title='Fast SMA', color=color.BLUE, line_style=line_style.SOLID, line_width=2)
@plot.line(title='Slow SMA', color=color.ORANGE, line_style=line_style.DASHED, line_width=2)
@plot.marker(title='Signal Marker', style=plot.marker_style.LABEL, position=plot.marker_position.BELOW, color=color.GREEN, size=3)
class Main(MainContext):
    def __init__(self, fast_len: int, slow_len: int):
        self._fast_len = fast_len
        self._slow_len = slow_len

    def calc(self):
        fast = Sma.new(self.close, self._fast_len)
        slow = Sma.new(self.close, self._slow_len)
        atr = Atr.new(14)[0]
        signal_count = MutSeriesF.new(init=0.0)
        signal_count[0] = 0.0 if isnan(signal_count[1]) else signal_count[1]

        marker_val = nan
        marker_txt: Optional[str] = None
        if not isnan(fast[1]) and not isnan(slow[1]) and not isnan(atr):
            if fast[1] <= slow[1] and fast[0] > slow[0]:
                marker_val = self.low[0]
                marker_txt = 'BUY'
                signal_count[0] = signal_count[0] + 1.0

        return (
            plot.Line(fast[0]),
            plot.Line(slow[0]),
            plot.Marker(value=marker_val, text=marker_txt),
        )
```

---

## 2. Native Non-Repainting `1m -> 15m` Resampling Pattern (Indie v5)

```python
from math import floor, isnan, nan
from indie import MutSeriesF


def _resample_step(
    raw_t: float,
    high_v: float,
    low_v: float,
    close_v: float,
    vol_v: float,
    minutes: int,
    prev_bucket: float,
    prev_h: float,
    prev_l: float,
    prev_c: float,
    prev_v: float,
) -> tuple[float, float, float, float, float, bool, float, float, float, float, float]:
    if isnan(raw_t):
        return prev_bucket, prev_h, prev_l, prev_c, prev_v, False, nan, nan, nan, nan, 0.0
    t_sec = raw_t / 1000.0 if raw_t > 1.0e11 else raw_t
    bucket = float(floor(t_sec / float(minutes * 60)))
    if isnan(prev_bucket):
        return bucket, high_v, low_v, close_v, vol_v, False, nan, nan, nan, nan, 0.0
    if bucket > prev_bucket:
        return bucket, high_v, low_v, close_v, vol_v, True, prev_bucket, prev_h, prev_l, prev_c, prev_v
    return prev_bucket, max(prev_h, high_v), min(prev_l, low_v), close_v, prev_v + vol_v, False, nan, nan, nan, nan, 0.0
```

Commit closed HTF bars inside `Main.calc(self)` only when `is_new_htf_bar` is `True` and `closed_bucket > self._last_committed_bucket`.

---

## 3. Symmetric Exness MT5 MQL5 Expert Advisor Skeleton

```mql5
#property strict
#include <Trade\Trade.mqh>

input double   InpRiskPercent   = 1.0;
input double   InpRR            = 2.0;
input int      InpMaxSpreadPts  = 30;
input ulong    InpMagic         = 20261127;

CTrade trade;
datetime lastBarTime = 0;

int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   return(INIT_SUCCEEDED);
}

double CalcLots(double slDistancePrice)
{
   if(slDistancePrice <= 0.0) return(0.0);
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRiskPercent / 100.0);
   double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0.0 || tickSize <= 0.0) return(0.0);
   double rawLots = riskMoney / ((slDistancePrice / tickSize) * tickVal);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double stepped = MathFloor(rawLots / step) * step;
   return(MathMax(minLot, MathMin(maxLot, NormalizeDouble(stepped, 2))));
}

void OnTick()
{
   datetime curBar = iTime(_Symbol, PERIOD_M1, 0);
   if(curBar == lastBarTime) return;
   lastBarTime = curBar;

   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > InpMaxSpreadPts) return;
   // Evaluate closed bar (shift = 1) buyCond / sellCond and call trade.Buy / trade.Sell
}
```
