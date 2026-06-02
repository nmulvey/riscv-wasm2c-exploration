#!/usr/bin/env python3
"""Disassembly-grouping harness for the wasm2c sandboxing pipeline.

For each case under ``analysis/cases/*.c`` this drives the *same*
C -> clang:wasm -> wasm2c:C -> CC:native-object pipeline the real tests use
(via the Makefile's ``analysis-object`` target, so flags never drift), across
a small sweep of optimization/ABI knobs. It then disassembles a single
function of interest, groups the configurations that yield byte-identical
code, and writes a Markdown report.

Run it from inside ``nix develop`` (any toolchain shell):

    nix develop --command python3 analysis/analyze.py

The active toolchain is encoded in the output path
(``analysis/out/<toolchain-id>/<case>.md``) so reports from different shells
don't clobber each other.

Nothing here assumes a particular target architecture: the Makefile's
per-family block already resolved the compiler, ABI flags and include paths,
and the alignment knob (NO_STRICT_ALIGN) is translated per family there.
"""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CASES_DIR = ROOT / "analysis" / "cases"
OUT_ROOT = ROOT / "analysis" / "out"
BUILD_ROOT = ROOT / "build" / "analysis"

# Resolved in main(): pick a disassembler that can actually decode the *cross*
# objects. llvm-objdump (in the clang shells) is target-agnostic; the toolchain's
# own <prefix>objdump (the gcc shells ship that) targets the right arch. $OBJDUMP
# is only a last resort: the gcc-wrapper auto-exports OBJDUMP=objdump pointing at
# the *host* binutils, which can't disassemble ARM/RISC-V and must not be picked.
# All accept -d/--section=/--no-show-raw-insn and emit the same
# "Disassembly of section" header the parser keys on.
OBJDUMP = ""

# --- Flag sweep --------------------------------------------------------------
# Each axis is a list of (label, make-variable-overrides). The Cartesian
# product is the config matrix; identical disassembly across configs is the
# headline result. Add axes here -- they need no code changes elsewhere.
#
# Bounds checking is intentionally NOT an axis: on our 32-bit targets guard
# pages are unsupported, so wasm2c's BOUNDS_CHECK mode is always on (forcing
# WASM_RT_MEMCHECK_GUARD_PAGES=1 hits a #error in wasm-rt.h). The explicit
# range check is therefore always visible in the disassembly.
AXES: list[tuple[str, list[tuple[str, dict[str, str]]]]] = [
    (
        "opt",
        [
            ("O2", {"EXTRA_CFLAGS": "-O2"}),
            ("O3", {"EXTRA_CFLAGS": "-O3"}),
            ("Os", {"EXTRA_CFLAGS": "-Os"}),
        ],
    ),
    (
        "align",
        [
            ("strict", {"NO_STRICT_ALIGN": "0"}),
            ("unaligned", {"NO_STRICT_ALIGN": "1"}),
        ],
    ),
]


@dataclass(frozen=True)
class Config:
    cfgid: str
    make_vars: dict[str, str]


def all_configs() -> list[Config]:
    configs = []
    for combo in product(*[opts for _, opts in AXES]):
        cfgid = "-".join(label for label, _ in combo)
        merged: dict[str, str] = {}
        for _, mv in combo:
            merged.update(mv)
        configs.append(Config(cfgid, merged))
    return configs


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd, cwd=ROOT, text=True, capture_output=True, check=False, **kw
    )


def make_var(name: str) -> str:
    """Read a fully-expanded Make variable via the `print-%` target."""
    cp = run(["make", f"print-{name}"])
    if cp.returncode != 0:
        sys.exit(f"`make print-{name}` failed:\n{cp.stderr}")
    return cp.stdout.strip()


def resolve_objdump() -> str:
    if shutil.which("llvm-objdump"):
        return "llvm-objdump"
    prefix = make_var("TOOLCHAIN_PREFIX")
    if prefix:
        cand = f"{prefix}objdump"
        if shutil.which(cand):
            return cand
    env = os.environ.get("OBJDUMP")
    if env and shutil.which(env):
        return env
    sys.exit(
        "no target-capable objdump found: install llvm-objdump, provide a "
        "<toolchain-prefix>objdump on PATH, or set OBJDUMP=<path>."
    )


# --- Toolchain identification ------------------------------------------------
# Prefer the (Nix-provided) build env vars when present, since they carry the
# full ABI selection (march/mabi, mcpu/mfpu, ...) that the compiler alone
# can't always report. Fall back to querying the compiler directly otherwise.
def compiler_invocation() -> list[str]:
    cc = make_var("CC")
    archflags = make_var("ARCHFLAGS")
    return [cc, *archflags.split()]


def query_compiler(extra: list[str]) -> str:
    cp = run([*compiler_invocation(), *extra])
    return cp.stdout.strip() if cp.returncode == 0 else ""


def slugify_abiflags(abiflags: str) -> str:
    parts = []
    for tok in abiflags.split():
        if "=" in tok:
            parts.append(tok.split("=", 1)[1])
        elif tok.startswith("-m"):
            parts.append(tok[2:])
    return "-".join(p for p in parts if p) or "default"


def toolchain_id() -> tuple[str, dict[str, str]]:
    # triple: env first, else ask the compiler.
    triple = os.environ.get("TARGET_TRIPLE") or query_compiler(["-dumpmachine"])

    # compiler family: env USE_CLANG first, else sniff `--version`.
    use_clang = os.environ.get("USE_CLANG")
    if use_clang == "1":
        family = "clang"
    elif use_clang == "0":
        family = "gcc"
    else:
        ver_line = run([make_var("CC"), "--version"]).stdout.lower()
        family = "clang" if "clang" in ver_line else "gcc"

    version = query_compiler(["-dumpversion"]) or "unknown"

    # ABI slug: ABIFLAGS is built by the Makefile from the env vars (or its
    # own defaults), so it already honors "env first".
    abiflags = make_var("ABIFLAGS")
    slug = slugify_abiflags(abiflags)

    rtlib = os.environ.get("RTLIB", "")

    parts = [triple or "unknown-target", f"{family}{version}", slug]
    if rtlib:
        parts.append(rtlib)
    tcid = "_".join(parts)

    details = {
        "id": tcid,
        "target": triple or "(unknown)",
        "compiler": f"{family} {version}",
        "abiflags": abiflags,
        "rtlib": rtlib or "(n/a)",
        "source": "env vars where present, compiler query as fallback",
    }
    return tcid, details


# --- Per-case driving --------------------------------------------------------
FOCUS_RE = re.compile(r"^\s*//\s*FOCUS:\s*(\S+)", re.MULTILINE)
NATIVE_FOCUS_RE = re.compile(r"^\s*//\s*NATIVE_FOCUS:\s*(\S+)", re.MULTILINE)
INSN_RE = re.compile(r"^\s*[0-9a-fA-F]+:\s+(.*\S)\s*$")


def read_focus(case_src: Path) -> str:
    m = FOCUS_RE.search(case_src.read_text())
    if not m:
        sys.exit(f"{case_src}: missing `// FOCUS: <w2c_symbol>` marker")
    return m.group(1)


def read_native_focus(case_src: Path, focus: str, case: str) -> str:
    """Symbol of the *un-sandboxed* function in the native-direct object.

    Taken from a `// NATIVE_FOCUS:` marker, else derived by stripping the
    `w2c_<case>_` prefix off the wasm focus (valid for leaf exports).
    """
    m = NATIVE_FOCUS_RE.search(case_src.read_text())
    if m:
        return m.group(1)
    prefix = f"w2c_{case}_"
    if focus.startswith(prefix):
        return focus[len(prefix) :]
    sys.exit(
        f"{case_src}: add a `// NATIVE_FOCUS: <symbol>` marker "
        f"(could not derive it from FOCUS `{focus}`)"
    )


def list_w2c_symbols(obj: Path) -> list[str]:
    cp = run([OBJDUMP, "-t", str(obj)])
    syms = []
    for line in cp.stdout.splitlines():
        # `... g     F .text.<sec> <size> <name>`; keep global functions.
        m = re.search(r"\bg\s+F\s+\S+\s+[0-9a-fA-F]+\s+(w2c_\S+)$", line)
        if m:
            syms.append(m.group(1))
    return syms


# Customization always passed to Make, on top of each config's own axis
# overrides. -g is dropped so the disassembly is deterministic.
CONST_MAKE_VARS = {"DEBUG": "0"}


def config_make_vars(cfg: Config) -> dict[str, str]:
    mv = dict(CONST_MAKE_VARS)
    mv.update(cfg.make_vars)
    return mv


def config_flags_str(cfg: Config) -> str:
    return " ".join(f"{k}={v}" for k, v in sorted(config_make_vars(cfg).items()))


def build(case: str, cfg: Config, tcid: str, make_target: str, out_name: str) -> Path:
    out_dir = BUILD_ROOT / tcid / case / cfg.cfgid
    out_dir.mkdir(parents=True, exist_ok=True)

    make_cmd = [
        "make",
        make_target,
        f"CASE={case}",
        f"ANALYSIS_OUT={out_dir.relative_to(ROOT)}",
    ]
    make_cmd += [f"{k}={v}" for k, v in sorted(config_make_vars(cfg).items())]

    cp = run(make_cmd)
    if cp.returncode != 0:
        sys.exit(
            f"build failed for {case} [{cfg.cfgid}] ({make_target}):\n"
            f"$ {' '.join(make_cmd)}\n{cp.stdout}\n{cp.stderr}"
        )
    return out_dir / out_name


def disassemble(obj: Path, focus: str) -> list[str]:
    """Return the focus function's instructions (address-stripped).

    Disassembles by *section* (`.text.<focus>`, courtesy of
    -ffunction-sections) rather than by symbol: --disassemble-symbols stops at
    the next local label, which on RISC-V truncates the function at the first
    `.Lpcrel_hi*`.
    """
    section = f".text.{focus}"
    cp = run(
        [OBJDUMP, "-d", f"--section={section}", "--no-show-raw-insn", str(obj)]
    )
    if cp.returncode != 0 or "Disassembly of section" not in cp.stdout:
        avail = list_w2c_symbols(obj)
        sys.exit(
            f"could not disassemble section {section} in {obj}.\n"
            f"Available w2c_ function symbols:\n  "
            + "\n  ".join(avail)
            + f"\nFix the `// FOCUS:` marker in the case to one of these.\n"
            f"objdump stderr:\n{cp.stderr}"
        )

    insns = []
    for line in cp.stdout.splitlines():
        m = INSN_RE.match(line)
        if m:
            insns.append(re.sub(r"[ \t]+", " ", m.group(1)).strip())
    return insns


def group_disasm(results: dict[str, list[str]]) -> list[dict]:
    """Collapse {cfgid: instructions} into groups of identical disassembly."""
    groups: dict[str, dict] = {}
    for cfgid, insns in results.items():
        key = hashlib.sha1("\n".join(insns).encode()).hexdigest()
        g = groups.setdefault(key, {"insns": insns, "cfgs": []})
        g["cfgs"].append(cfgid)
    return sorted(groups.values(), key=lambda g: (-len(g["cfgs"]), g["cfgs"]))


def analyze_case(case_src: Path, tcid: str) -> str:
    case = case_src.stem
    focus = read_focus(case_src)
    native_focus = read_native_focus(case_src, focus, case)

    wasm_results: dict[str, list[str]] = {}
    native_results: dict[str, list[str]] = {}
    for cfg in all_configs():
        wobj = build(case, cfg, tcid, "analysis-object", f"{case}.wasm.o")
        wasm_results[cfg.cfgid] = disassemble(wobj, focus)

        nobj = build(case, cfg, tcid, "analysis-native-object", f"{case}.native.o")
        native_results[cfg.cfgid] = disassemble(nobj, native_focus)

    flags_by_cfg = {cfg.cfgid: config_flags_str(cfg) for cfg in all_configs()}

    return render_case_md(
        case,
        focus,
        native_focus,
        group_disasm(wasm_results),
        group_disasm(native_results),
        flags_by_cfg,
    )


def render_groups(
    groups: list[dict], flags_by_cfg: dict[str, str]
) -> list[str]:
    lines: list[str] = []
    for i, g in enumerate(groups, 1):
        n = len(g["cfgs"])
        lines += [
            f"#### Group {i} — {n} config{'' if n == 1 else 's'}, "
            f"{len(g['insns'])} instructions",
            "",
            "Configurations in this group (exact Make flags):",
            "",
        ]
        lines += [f"- `{c}` — `{flags_by_cfg[c]}`" for c in g["cfgs"]]
        lines += ["", "```asm", *g["insns"], "```", ""]
    return lines


def render_case_md(
    case: str,
    focus: str,
    native_focus: str,
    wasm_groups: list[dict],
    native_groups: list[dict],
    flags_by_cfg: dict[str, str],
) -> str:
    total = sum(len(g["cfgs"]) for g in wasm_groups)
    lines = [
        f"## `{case}`",
        "",
        f"- **Sandboxed focus symbol:** `{focus}` (C → wasm → wasm2c → native)",
        f"- **Native baseline symbol:** `{native_focus}` (C → native, no WASM)",
        f"- **Configurations swept:** {total}",
        "",
        "### Sandboxed (wasm2c) disassembly",
        "",
        f"{len(wasm_groups)} distinct disassembly "
        f"{'group' if len(wasm_groups) == 1 else 'groups'}.",
        "",
        *render_groups(wasm_groups, flags_by_cfg),
        "### Native baseline disassembly (no WASM)",
        "",
        f"{len(native_groups)} distinct disassembly "
        f"{'group' if len(native_groups) == 1 else 'groups'}.",
        "",
        *render_groups(native_groups, flags_by_cfg),
    ]
    return "\n".join(lines)


def main() -> None:
    global OBJDUMP
    OBJDUMP = resolve_objdump()

    cases = sorted(CASES_DIR.glob("*.c"))
    if not cases:
        sys.exit(f"no cases found under {CASES_DIR}")

    tcid, details = toolchain_id()
    out_dir = OUT_ROOT / tcid
    out_dir.mkdir(parents=True, exist_ok=True)

    header = [
        "# wasm2c sandboxing — disassembly analysis",
        "",
        "**Toolchain**",
        "",
        f"- target: `{details['target']}`",
        f"- compiler: `{details['compiler']}`",
        f"- ABI flags: `{details['abiflags']}`",
        f"- rtlib: `{details['rtlib']}`",
        f"- id: `{details['id']}`",
        f"- _resolved from: {details['source']}_",
        "",
        "**Canonical pipeline flags** (from the Makefile)",
        "",
        f"- `WASM_CFLAGS` = `{make_var('WASM_CFLAGS')}`",
        f"- `CFLAGS` = `{make_var('CFLAGS')}`",
        "",
        "---",
        "",
    ]

    for case_src in cases:
        body = analyze_case(case_src, tcid)
        report = "\n".join(header) + body
        out_file = out_dir / f"{case_src.stem}.md"
        out_file.write_text(report)
        print(f"wrote {out_file.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
