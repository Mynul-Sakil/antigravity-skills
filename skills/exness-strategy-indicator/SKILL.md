---
name: exness-strategy-indicator
description: "Use when asked to create, build, validate, and test Exness trading indicators and strategies, including TakeProfit Indie v5 scripts for Exness Web Terminal and MQL5 indicators or Expert Advisors for Exness MetaTrader 5."
---

# Exness Strategy & Indicator Builder

Create, validate, and locally test symmetric BUY/SELL indicators and trading strategies for Exness platforms.

## Platform Selection

| Platform | Language | Capabilities |
|---|---|---|
| **Exness Web Terminal** | TakeProfit Indie v5 (`# indie:lang_version = 5`) | Visual chart overlays, markers, levels, labels only (manual trade execution) |
| **Exness MetaTrader 5** | MQL5 (`.mq5`) | Visual indicators plus automated Expert Advisors (EAs) on desktop or Exness VPS |

Never promise automated order execution inside Exness Web Terminal Indie scripts; route automated execution requests to MQL5 Expert Advisors.

## Quick Start

Validate any Exness Indie v5 script locally before pasting into Exness Web Terminal:

```bash
python3 .agents/skills/exness-strategy-indicator/scripts/validate_indie_v5.py path/to/indicator.py
python3 -m unittest discover -s path/to/tests -v
```

## End-to-End Workflow

1. **Clarify Strategy Spec**: Confirm target platform(s), primary & fallback timeframes, symmetric BUY and SELL entry rules, liquidity/filter thresholds, and Stop-Loss / Take-Profit logic.
2. **Design & Implement**:
   - For **Indie v5**: Write a single self-contained script following [REFERENCE.md](REFERENCE.md) (valid `indie.color` names, `Optional[str]` annotations, `MutSeriesF.new(init=...)`, and native `self.time[0]` resampling instead of `calc_on`).
   - For **MQL5**: Write non-repainting closed-bar (`shift = 1`) indicator buffers or `CTrade` EA risk/lot logic per [REFERENCE.md](REFERENCE.md).
3. **Static Validation**: Run `scripts/validate_indie_v5.py` on Indie v5 scripts and fix all reported errors.
4. **Behavioral Testing**: Add `unittest` cases importing `scripts/indie_stub.py` covering BUY flow, SELL flow, non-repainting closed-bar timing, expiry, toggles, and zero-range/zero-volume edge cases.
5. **Delivery & Manual Verification**: Provide exact copy-paste instructions for Exness Web Terminal (`Cmd+A` replace -> Save / Add to Chart) or MT5 MetaEditor compile + Strategy Tester / Demo checks.

## Bundled Resources

- [REFERENCE.md](REFERENCE.md) — Indie v5 compiler/runtime rules, native multi-timeframe resampling, and MQL5 EA checklist.
- [EXAMPLES.md](EXAMPLES.md) — Minimal Indie v5 overlay, native resampling pattern, and MQL5 EA skeleton.
- [scripts/validate_indie_v5.py](scripts/validate_indie_v5.py) — Deterministic static linter for Exness Indie v5 scripts.
- [scripts/indie_stub.py](scripts/indie_stub.py) — Pure-Python Indie v5 runtime stub for local `unittest` verification.
