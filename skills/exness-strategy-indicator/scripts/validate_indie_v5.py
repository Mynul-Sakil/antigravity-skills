#!/usr/bin/env python3
"""validate_indie_v5.py — Deterministic static linter for Exness Indie v5 scripts.

Catches common Exness Web Terminal compiler and runtime errors locally using stdlib only:
  1. Line 1 must be `# indie:lang_version = 5`
  2. Valid Python AST
  3. Only allowed import roots (`math`, `indie`)
  4. Only documented `indie.color.*` members (flags `color.CYAN`, etc.)
  5. Flags Exness-unsupported patterns (`@param_ref`, `calc_on`, `param.time_frame`) unless `--allow-calc-on`
  6. `@plot.*` decorator count on `Main` matches every return tuple length in `Main.calc` / `def Main`
  7. No `MutSeriesF.new(...)` variable rebound to another type inside `Main.calc` / `def Main`
  8. No unannotated `var = None` later assigned a string inside `Main.calc` / `def Main`
"""

from __future__ import annotations

import argparse
import ast
from pathlib import Path
import sys

VALID_COLORS = {
    "AQUA",
    "BLACK",
    "BLUE",
    "FUCHSIA",
    "GRAY",
    "GREEN",
    "LIME",
    "MAROON",
    "NAVY",
    "OLIVE",
    "ORANGE",
    "PURPLE",
    "RED",
    "SILVER",
    "TEAL",
    "WHITE",
    "YELLOW",
    "rgba",
    "hex",
}

ALLOWED_IMPORT_ROOTS = {"math", "indie"}


def _is_mut_series_new_call(node: ast.AST) -> bool:
    return (
        isinstance(node, ast.Call)
        and isinstance(node.func, ast.Attribute)
        and isinstance(node.func.value, ast.Name)
        and node.func.value.id == "MutSeriesF"
        and node.func.attr == "new"
    )


def _find_entry_func(tree: ast.Module) -> tuple[ast.FunctionDef | None, list[ast.AST]]:
    """Return the Main calculation FunctionDef and the decorators attached to Main."""
    for node in tree.body:
        if isinstance(node, ast.ClassDef) and node.name == "Main":
            for item in node.body:
                if isinstance(item, ast.FunctionDef) and item.name == "calc":
                    return item, list(node.decorator_list)
            return None, list(node.decorator_list)
        if isinstance(node, ast.FunctionDef) and node.name == "Main":
            return node, list(node.decorator_list)
    return None, []


def _count_plot_decorators(decorators: list[ast.AST]) -> int:
    count = 0
    for dec in decorators:
        call = dec.func if isinstance(dec, ast.Call) else dec
        if (
            isinstance(call, ast.Attribute)
            and isinstance(call.value, ast.Name)
            and call.value.id == "plot"
        ):
            count += 1
    return count


def validate_script(path: Path, allow_calc_on: bool = False) -> list[str]:
    """Return a list of human-readable error strings (empty list means valid)."""
    errors: list[str] = []
    try:
        source = path.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"Unable to read {path}: {exc}"]

    lines = source.splitlines()
    if not lines or lines[0].strip() != "# indie:lang_version = 5":
        errors.append("Line 1: Must start with exact directive `# indie:lang_version = 5`")

    try:
        tree = ast.parse(source, filename=str(path))
    except SyntaxError as exc:
        errors.append(f"Line {exc.lineno}: Python syntax error: {exc.msg}")
        return errors

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                root = alias.name.split(".")[0]
                if root not in ALLOWED_IMPORT_ROOTS:
                    errors.append(f"Line {node.lineno}: Disallowed import `{alias.name}`")
        elif isinstance(node, ast.ImportFrom) and node.module is not None:
            root = node.module.split(".")[0]
            if root not in ALLOWED_IMPORT_ROOTS:
                errors.append(f"Line {node.lineno}: Disallowed import from `{node.module}`")
        elif isinstance(node, ast.Attribute):
            if isinstance(node.value, ast.Name) and node.value.id == "color":
                if node.attr not in VALID_COLORS:
                    errors.append(
                        f"Line {node.lineno}: Unknown member `color.{node.attr}` "
                        f"(use valid indie.color such as BLUE, AQUA, ORANGE, PURPLE, RED, GREEN)"
                    )
            if not allow_calc_on:
                if isinstance(node.value, ast.Name) and node.value.id == "param" and node.attr == "time_frame":
                    errors.append(
                        f"Line {node.lineno}: `param.time_frame` risks runtime error on Exness Terminal; "
                        "prefer native `self.time[0]` resampling (or pass --allow-calc-on)"
                    )
                if node.attr == "calc_on":
                    errors.append(
                        f"Line {node.lineno}: `calc_on` risks 'selected timeframe is not supported' on Exness Terminal; "
                        "prefer native `self.time[0]` resampling (or pass --allow-calc-on)"
                    )
        elif isinstance(node, ast.Name) and node.id == "param_ref":
            errors.append(
                f"Line {node.lineno}: `@param_ref` fails when bound to `class Main(MainContext)` in Exness Terminal"
            )

    calc_fn, main_decorators = _find_entry_func(tree)
    if calc_fn is None:
        errors.append("Missing `Main` entry point (`class Main(MainContext)` with `calc` or `def Main`)")
        return errors

    plot_count = _count_plot_decorators(main_decorators)
    ret_nodes = [n for n in ast.walk(calc_fn) if isinstance(n, ast.Return)]
    if plot_count > 0:
        for r in ret_nodes:
            if isinstance(r.value, ast.Tuple):
                if len(r.value.elts) != plot_count:
                    errors.append(
                        f"Line {r.lineno}: Return tuple length ({len(r.value.elts)}) "
                        f"does not match @plot.* count ({plot_count})"
                    )
            elif plot_count != 1:
                errors.append(
                    f"Line {r.lineno}: Expected {plot_count}-element return tuple matching @plot.* decorators"
                )

    mut_vars: set[str] = set()
    unannotated_none_vars: set[str] = set()
    for n in ast.walk(calc_fn):
        if isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name):
            name = n.targets[0].id
            if _is_mut_series_new_call(n.value):
                mut_vars.add(name)
            elif name in mut_vars:
                errors.append(
                    f"Line {n.lineno}: Cannot rebind `MutSeriesF` variable `{name}` to another value/type"
                )
            if isinstance(n.value, ast.Constant) and n.value.value is None:
                unannotated_none_vars.add(name)
            elif name in unannotated_none_vars and isinstance(n.value, ast.Constant) and isinstance(n.value.value, str):
                errors.append(
                    f"Line {n.lineno}: Variable `{name}` initialized as `None` then assigned `str`; "
                    f"annotate `{name}: Optional[str] = None`"
                )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate an Exness Indie v5 script.")
    parser.add_argument("script", help="Path to the Indie v5 .py script")
    parser.add_argument(
        "--allow-calc-on",
        action="store_true",
        help="Allow calc_on / param.time_frame (disabled by default due to Exness runtime restriction)",
    )
    args = parser.parse_args()

    target = Path(args.script)
    errs = validate_script(target, allow_calc_on=args.allow_calc_on)
    if errs:
        for e in errs:
            print(f"ERROR: {e}", file=sys.stderr)
        return 1

    print(f"OK: {target} passed all Exness Indie v5 checks.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
