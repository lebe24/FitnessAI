#!/usr/bin/env python3
"""
BeFit AI Flutter — test runner
================================
Runs `flutter test` across every test group and prints a structured
per-file, per-group summary.

Usage
-----
From the Flutter project root  OR  from test/py/:

    python3 test/py/test.py                       # run all tests
    python3 test/py/test.py --group viewmodels    # unit/viewmodels/ only
    python3 test/py/test.py --group usecases      # unit/usecases/ only
    python3 test/py/test.py --group repositories  # unit/repositories/ only
    python3 test/py/test.py --group widget        # widget_test.dart only
    python3 test/py/test.py --file test/unit/usecases/auth/auth_usecases_test.dart
    python3 test/py/test.py --verbose             # stream raw flutter output live
    python3 test/py/test.py --no-color            # plain text (CI / log files)
    python3 test/py/test.py --coverage            # add --coverage flag to flutter

Exit code
---------
  0  all tests passed
  1  one or more tests failed
  2  flutter binary not found or project missing
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

# ── Paths ──────────────────────────────────────────────────────────────────────

_SCRIPT_DIR   = Path(__file__).resolve().parent          # test/py/
_PROJECT_ROOT = _SCRIPT_DIR.parent.parent                # FitnessAI/
_TEST_ROOT    = _PROJECT_ROOT / "test"

_FLUTTER_BIN  = Path(os.getenv("FLUTTER_BIN", "/Users/lebemac/flutter/bin/flutter"))

# ── Test-group → path mapping ──────────────────────────────────────────────────

GROUPS: dict[str, str] = {
    "viewmodels":   "test/unit/viewmodels",
    "usecases":     "test/unit/usecases",
    "repositories": "test/unit/repositories",
    "unit":         "test/unit",
    "widget":       "test/widget_test.dart",
}

_GROUP_ORDER  = ["viewmodels", "usecases", "repositories", "widget", "unit", "other"]
_GROUP_LABELS = {
    "usecases":     "Use Cases",
    "repositories": "Repositories",
    "viewmodels":   "View Models",
    "unit":         "Unit (all)",
    "widget":       "Widget Smoke",
    "other":        "Other",
}

# ── ANSI helpers ───────────────────────────────────────────────────────────────

def _supports_color() -> bool:
    return sys.stdout.isatty() and os.getenv("TERM", "") != "dumb"


class C:
    RESET = BOLD = GREEN = RED = YELLOW = CYAN = DIM = MAGENTA = ""

    @classmethod
    def enable(cls) -> None:
        cls.RESET   = "\033[0m"
        cls.BOLD    = "\033[1m"
        cls.GREEN   = "\033[32m"
        cls.RED     = "\033[31m"
        cls.YELLOW  = "\033[33m"
        cls.CYAN    = "\033[36m"
        cls.MAGENTA = "\033[35m"
        cls.DIM     = "\033[2m"


# ── Data model ─────────────────────────────────────────────────────────────────

@dataclass
class FileResult:
    rel_path: str           # relative to project root
    passed:   int = 0
    failed:   int = 0
    failures: list[str] = field(default_factory=list)  # failing test names

    @property
    def ok(self) -> bool:
        return self.failed == 0


@dataclass
class GroupResult:
    name:  str
    files: list[FileResult] = field(default_factory=list)

    @property
    def passed(self) -> int:
        return sum(f.passed for f in self.files)

    @property
    def failed(self) -> int:
        return sum(f.failed for f in self.files)

    @property
    def ok(self) -> bool:
        return self.failed == 0


@dataclass
class RunResult:
    groups:    list[GroupResult] = field(default_factory=list)
    duration:  float  = 0.0
    exit_code: int    = -1
    raw:       str    = ""

    @property
    def total_passed(self) -> int:
        return sum(g.passed for g in self.groups)

    @property
    def total_failed(self) -> int:
        return sum(g.failed for g in self.groups)

    @property
    def ok(self) -> bool:
        return self.exit_code == 0


# ── Parser ─────────────────────────────────────────────────────────────────────
#
# flutter test --reporter expanded has two output formats:
#
# ALL-TESTS (multi-file run):
#   HH:MM +N: /abs/path/file_test.dart: test description
#   HH:MM +N -F: /abs/path/file_test.dart: failing test [E]
#
# SINGLE-TARGET (one file or one folder):
#   HH:MM +0: loading /abs/path/file_test.dart   ← shows which file
#   HH:MM +N: test description                    ← no file path prefix
#
# Summary (both modes):
#   HH:MM +N: All tests passed!
#   HH:MM +N -F: Some tests failed.
#
# Paths may contain spaces (e.g. "flutter Apps"). Non-greedy (.+?) handles this.
# The counter +N increments by 1 per passing test; we deduplicate by counter.

_COUNTER_PREFIX = re.compile(
    r"^\s*(?:\d{2}:\d{2}\s+)?\+(\d+)(?:\s+-(\d+))?:\s+(.*)"
)
_SUMMARY_RE = re.compile(
    r"\+(\d+)(?:\s+-(\d+))?:\s+(All tests passed|Some tests failed)"
)
_TEST_FILE_RE = re.compile(r"(/.+?_test\.dart):\s+(.*)")
_LOADING_RE   = re.compile(r"loading\s+(/.+?_test\.dart)\s*$")


def _rel(abs_path: str) -> str:
    try:
        return str(Path(abs_path).relative_to(_PROJECT_ROOT))
    except ValueError:
        return abs_path


def _group_for_rel(rel: str) -> str:
    p = rel.replace("\\", "/")
    if "unit/viewmodels"   in p: return "viewmodels"
    if "unit/usecases"     in p: return "usecases"
    if "unit/repositories" in p: return "repositories"
    if "widget_test"       in p: return "widget"
    return "other"


def parse_output(raw: str) -> tuple[dict[str, FileResult], int, int]:
    """Returns (files_by_rel, total_passed, total_failed)."""
    files: dict[str, FileResult] = {}
    seen_counters: set[int] = set()
    current_file: Optional[str] = None   # used in single-target mode

    for line in raw.splitlines():
        m = _COUNTER_PREFIX.match(line)
        if not m:
            continue

        counter  = int(m.group(1))
        n_failed = m.group(2)
        rest     = m.group(3).strip()

        # Loading line — captures which file is under test in single-target mode
        if lm := _LOADING_RE.match(rest):
            current_file = _rel(lm.group(1))
            if current_file not in files:
                files[current_file] = FileResult(rel_path=current_file)
            continue

        # Skip summary and blank lines
        if re.match(r"(All tests passed|Some tests failed|loading )", rest):
            continue
        if not rest:
            continue

        # Skip duplicate pass-counter entries (parallel isolate lines)
        if counter in seen_counters:
            continue
        seen_counters.add(counter)

        is_failure = ("[E]" in line) or (n_failed is not None)

        # Determine which file this test belongs to
        rel_path: Optional[str] = None
        test_name: str          = rest

        if fm := _TEST_FILE_RE.match(rest):
            # Multi-file mode: path is embedded in the line
            rel_path  = _rel(fm.group(1))
            test_name = fm.group(2).replace(" [E]", "").strip()
        elif current_file:
            # Single-target mode: attribute to the last "loading" file
            rel_path  = current_file
            test_name = rest.replace(" [E]", "").strip()
        else:
            continue   # can't attribute; skip

        if rel_path not in files:
            files[rel_path] = FileResult(rel_path=rel_path)

        fr = files[rel_path]
        if is_failure:
            fr.failed += 1
            fr.failures.append(test_name)
        else:
            fr.passed += 1

    # Use summary line as authoritative totals
    total_passed = total_failed = 0
    if sm := _SUMMARY_RE.search(raw):
        total_passed = int(sm.group(1))
        total_failed = int(sm.group(2) or 0)
    else:
        total_passed = sum(f.passed for f in files.values())
        total_failed = sum(f.failed for f in files.values())

    return files, total_passed, total_failed


def build_result(raw: str, exit_code: int, duration: float) -> RunResult:
    files, total_passed, total_failed = parse_output(raw)

    groups: dict[str, GroupResult] = {}
    for rel, fr in files.items():
        grp = _group_for_rel(rel)
        if grp not in groups:
            groups[grp] = GroupResult(name=grp)
        groups[grp].files.append(fr)

    # If parsed totals don't match summary, stash remainder in "other"
    parsed_p = sum(f.passed for f in files.values())
    parsed_f = sum(f.failed for f in files.values())
    delta_p  = total_passed - parsed_p
    delta_f  = total_failed - parsed_f
    if delta_p > 0 or delta_f > 0:
        if "other" not in groups:
            groups["other"] = GroupResult(name="other")
        groups["other"].files.append(
            FileResult(rel_path="(uncounted)", passed=delta_p, failed=delta_f)
        )

    result             = RunResult()
    result.groups      = list(groups.values())
    result.duration    = duration
    result.exit_code   = exit_code
    result.raw         = raw
    return result


# ── Runner ─────────────────────────────────────────────────────────────────────

def run_tests(
    target:   Optional[str],
    coverage: bool,
    verbose:  bool,
) -> RunResult:
    result = RunResult()

    if not _FLUTTER_BIN.exists():
        result.raw       = (
            f"Flutter binary not found: {_FLUTTER_BIN}\n"
            "Set FLUTTER_BIN env var to override."
        )
        result.exit_code = 2
        return result

    cmd: list[str] = [str(_FLUTTER_BIN), "test", "--reporter", "expanded"]
    if coverage:
        cmd.append("--coverage")
    if target:
        cmd.append(target)

    t0 = time.monotonic()

    if verbose:
        print(f"{C.DIM}$ {' '.join(cmd)}{C.RESET}\n")
        proc = subprocess.run(cmd, cwd=_PROJECT_ROOT)
        result.exit_code = proc.returncode
        result.duration  = time.monotonic() - t0
        return result

    proc = subprocess.run(
        cmd, cwd=_PROJECT_ROOT, capture_output=True, text=True,
    )
    elapsed = time.monotonic() - t0
    raw     = proc.stdout + proc.stderr
    return build_result(raw, proc.returncode, elapsed)


# ── Report ─────────────────────────────────────────────────────────────────────

_BAR  = "─" * 70
_DBAR = "═" * 70


def _ok_icon(ok: bool) -> str:
    return f"{C.GREEN}✓{C.RESET}" if ok else f"{C.RED}✗{C.RESET}"


def _count_line(passed: int, failed: int, elapsed: float = 0) -> str:
    p  = f"{C.GREEN}{passed} passed{C.RESET}"
    f_ = f"  {C.RED}{failed} failed{C.RESET}" if failed else ""
    t  = f"  {C.DIM}({elapsed:.1f}s){C.RESET}" if elapsed else ""
    return f"{p}{f_}{t}"


def print_report(result: RunResult) -> None:
    print(f"\n{C.BOLD}{_DBAR}{C.RESET}")
    print(f"{C.BOLD}  BEFIT AI FLUTTER — TEST REPORT{C.RESET}")
    print(f"{_DBAR}")

    sorted_groups = sorted(
        result.groups,
        key=lambda g: _GROUP_ORDER.index(g.name) if g.name in _GROUP_ORDER else 99,
    )

    for grp in sorted_groups:
        real_files = [f for f in grp.files if f.rel_path != "(uncounted)"]
        if not real_files and grp.passed == 0 and grp.failed == 0:
            continue

        label = _GROUP_LABELS.get(grp.name, grp.name.title())
        icon  = _ok_icon(grp.ok)
        count = _count_line(grp.passed, grp.failed)

        print(f"\n  {C.BOLD}{icon}  {C.CYAN}{label}{C.RESET}  {count}")
        print(f"  {_BAR[:66]}")

        for fr in sorted(real_files, key=lambda f: f.rel_path):
            file_icon = _ok_icon(fr.ok)
            short     = fr.rel_path.replace("test/unit/", "").replace("test/", "")
            total     = fr.passed + fr.failed
            cnt       = (
                f"{C.DIM}{fr.passed}p"
                + (f"  {C.RED}{fr.failed}f{C.DIM}" if fr.failed else "")
                + f"  ({total} tests){C.RESET}"
            )
            print(f"    {file_icon}  {short}  {cnt}")

            for name in fr.failures:
                print(f"         {C.RED}✗ {name}{C.RESET}")

    # ── totals ─────────────────────────────────────────────────────────────────
    print(f"\n  {_BAR}")
    print(
        f"  {C.BOLD}TOTAL{C.RESET}   "
        f"{_count_line(result.total_passed, result.total_failed, result.duration)}"
    )

    if result.ok:
        print(f"\n  {C.GREEN}{C.BOLD}✓  All tests passed.{C.RESET}\n")
    else:
        print(f"\n  {C.RED}{C.BOLD}✗  Some tests failed.{C.RESET}")
        _print_failures(result.raw)
        print()


def _print_failures(raw: str) -> None:
    """Print the failure detail block from raw flutter output."""
    lines:   list[str] = []
    capture            = False

    for line in raw.splitlines():
        if re.search(r"(FAILED|Error:|test failed)", line, re.IGNORECASE):
            capture = True
        if capture:
            lines.append(line)
        if len(lines) > 60:
            lines.append("  … (run with --verbose for full output)")
            break

    if lines:
        print(f"\n  {C.RED}── Failure detail ──{C.RESET}")
        for line in lines:
            print(f"  {C.DIM}{line}{C.RESET}")


# ── CLI ────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run BeFit AI Flutter tests with a structured report.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    mutex = parser.add_mutually_exclusive_group()
    mutex.add_argument(
        "--group", "-g",
        choices=list(GROUPS.keys()),
        metavar="GROUP",
        help=f"Run one group. Choices: {', '.join(GROUPS)}",
    )
    mutex.add_argument(
        "--file", "-f",
        metavar="PATH",
        help="Run a single test file (relative to project root)",
    )
    parser.add_argument("--verbose",  "-v", action="store_true",
                        help="Stream raw flutter output live")
    parser.add_argument("--no-color",       action="store_true",
                        help="Disable ANSI colours")
    parser.add_argument("--coverage",       action="store_true",
                        help="Pass --coverage to flutter test")
    args = parser.parse_args()

    if not args.no_color and _supports_color():
        C.enable()

    target: Optional[str] = None

    if args.group:
        rel    = GROUPS[args.group]
        target = str(_PROJECT_ROOT / rel)
        if not Path(target).exists():
            print(f"{C.RED}Error: path not found: {target}{C.RESET}")
            return 2
        label = _GROUP_LABELS.get(args.group, args.group)
        print(f"{C.CYAN}▶  Running group '{label}' → {rel}{C.RESET}")

    elif args.file:
        target = str(_PROJECT_ROOT / args.file)
        if not Path(target).exists():
            print(f"{C.RED}Error: file not found: {target}{C.RESET}")
            return 2
        print(f"{C.CYAN}▶  Running file: {args.file}{C.RESET}")

    else:
        print(f"{C.CYAN}▶  Running all Flutter tests …{C.RESET}")

    result = run_tests(target=target, coverage=args.coverage, verbose=args.verbose)

    if result.exit_code == 2 and not result.groups:
        print(f"{C.RED}Error: {result.raw}{C.RESET}")
        return 2

    if not args.verbose:
        print_report(result)

    return 0 if result.ok else 1


if __name__ == "__main__":
    sys.exit(main())
