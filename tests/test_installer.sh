#!/usr/bin/env bash
# Portable 17-suite E2E test harness for antigravity-skills
# Cleans up each test workspace immediately after its test completes, plus full EXIT cleanup.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SRC_REPO="$(cd "$SCRIPT_DIR/.." && pwd -P)"
INSTALLER="$SRC_REPO/install.sh"

TEST_ROOT="$(mktemp -d /tmp/agy-test-suite.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass() { printf "✅ PASS: %s\n" "$*"; }
fail() { printf "❌ FAIL: %s\n" "$*" >&2; exit 1; }

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [ "$actual" != "$expected" ]; then
    fail "$label (expected '$expected', got '$actual')"
  fi
}

count_dirs() {
  find "$1" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '
}

count_files() {
  find "$1" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' '
}

cleanup_case() {
  local p
  for p in "$@"; do
    case "$p" in
      "$TEST_ROOT"/*) rm -rf -- "$p" ;;
      *) fail "Refusing to clean path outside TEST_ROOT: $p" ;;
    esac
  done
}

echo "=== Test Sandbox: $TEST_ROOT ==="

# Build isolated upstream Git mirror from SRC_REPO
UPSTREAM="$TEST_ROOT/upstream-repo"
cp -R "$SRC_REPO" "$UPSTREAM"
rm -rf "$UPSTREAM/scripts/__pycache__"
git -C "$UPSTREAM" config user.email "test@example.com"
git -C "$UPSTREAM" config user.name "Test Runner"
git -C "$UPSTREAM" config uploadpack.allowFilter true
git -C "$UPSTREAM" config uploadpack.allowAnySHA1InWant true
git -C "$UPSTREAM" add -A
git -C "$UPSTREAM" commit -q -m "chore: snapshot for test run" || true

EMPTY_HOME="$TEST_ROOT/empty-home"
mkdir -p "$EMPTY_HOME"

export ANTIGRAVITY_SKILLS_REPO="$UPSTREAM"
export ANTIGRAVITY_SKILLS_BRANCH="main"

# ------------------------------------------------------------------------------
# TC-01: Bash 3.2 & Default Bash Syntax, Python AST, Line Ceiling (<800), profiles.json
# ------------------------------------------------------------------------------
/bin/bash -n "$INSTALLER"
bash -n "$INSTALLER"
python3 -B -c "import ast, pathlib; ast.parse(pathlib.Path('$SRC_REPO/scripts/installer_engine.py').read_text(encoding='utf-8'))"
LINES="$(wc -l < "$INSTALLER" | tr -d ' ')"
ENG_LINES="$(wc -l < "$SRC_REPO/scripts/installer_engine.py" | tr -d ' ')"
[ "$LINES" -lt 800 ] || fail "install.sh exceeded 800 lines ($LINES)"
[ "$ENG_LINES" -lt 800 ] || fail "scripts/installer_engine.py exceeded 800 lines ($ENG_LINES)"
python3 -B - "$SRC_REPO" <<'PYEOF'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
data = json.loads((root / "profiles.json").read_text(encoding="utf-8"))
for name, b in {"minimal": data["minimal"], **data["roles"]}.items():
    for s in b["skills"]:
        assert (root / "skills" / s / "SKILL.md").is_file(), f"{name}: missing skill {s}"
    for a in b["agents"]:
        assert (root / "agents" / a).is_file(), f"{name}: missing agent {a}"
    for r in b["rules"]:
        assert (root / "rules" / r).is_file(), f"{name}: missing rule {r}"
PYEOF
pass "TC-01: Syntax valid (/bin/bash, bash & Python AST), line counts install.sh=${LINES}/800 & engine=${ENG_LINES}/800, profiles.json verified"

# ------------------------------------------------------------------------------
# TC-02: Documentation Copy-Paste Audit (1 command per bash block, 0 '#' comments)
# ------------------------------------------------------------------------------
python3 -B - "$SRC_REPO/README.md" "$SRC_REPO/INSTALLATION.md" <<'PYEOF'
import re, sys
from pathlib import Path
for doc_path in sys.argv[1:]:
    text = Path(doc_path).read_text(encoding="utf-8")
    blocks = re.findall(r"```bash\n(.*?)```", text, flags=re.DOTALL)
    assert blocks, f"No bash blocks found in {doc_path}"
    for idx, blk in enumerate(blocks, 1):
        lines = [ln.strip() for ln in blk.strip().splitlines() if ln.strip()]
        assert len(lines) == 1, f"{doc_path} bash block #{idx} has {len(lines)} lines (must be 1): {lines}"
        assert not lines[0].startswith("#"), f"{doc_path} bash block #{idx} starts with comment: {lines[0]}"
PYEOF
pass "TC-02: Every bash code block in README.md & INSTALLATION.md is a single comment-free command"

# ------------------------------------------------------------------------------
# TC-03: --list-roles and --list-skills discovery flags
# ------------------------------------------------------------------------------
ROLES_OUT="$(HOME="$EMPTY_HOME" bash "$INSTALLER" --list-roles)"
echo "$ROLES_OUT" | grep -q "fullstack" || fail "--list-roles missing fullstack"
echo "$ROLES_OUT" | grep -q "c-suite -> founder" || fail "--list-roles missing alias"
SKILLS_CNT="$(HOME="$EMPTY_HOME" bash "$INSTALLER" --list-skills | grep -c '^  ')"
assert_eq "$SKILLS_CNT" "532" "--list-skills count"
pass "TC-03: --list-roles and --list-skills work non-interactively (532 skills listed)"

# ------------------------------------------------------------------------------
# TC-04: --dry-run immutability
# ------------------------------------------------------------------------------
DRY_WS="$TEST_ROOT/dry-ws"
DRY_HOME="$TEST_ROOT/dry-home"
mkdir -p "$DRY_WS" "$DRY_HOME"
HOME="$DRY_HOME" bash "$INSTALLER" --local --dir "$DRY_WS" --dry-run >/dev/null
HOME="$DRY_HOME" bash "$INSTALLER" --global --skill stock-analysis --dry-run >/dev/null
HOME="$DRY_HOME" bash "$INSTALLER" --copilot --local --dir "$DRY_WS" --dry-run >/dev/null
[ ! -e "$DRY_WS/.agents" ] || fail "--dry-run created .agents"
[ ! -e "$DRY_WS/.github" ] || fail "--dry-run created .github"
[ ! -e "$DRY_HOME/.gemini" ] || fail "--dry-run created .gemini"
cleanup_case "$DRY_WS" "$DRY_HOME"
pass "TC-04: --dry-run modifies zero files (cleaned up)"

# ------------------------------------------------------------------------------
# TC-05: Default = minimal (both --local and --global)
# ------------------------------------------------------------------------------
MIN_WS="$TEST_ROOT/min-ws"
MIN_HOME="$TEST_ROOT/min-home"
mkdir -p "$MIN_WS" "$MIN_HOME"
HOME="$MIN_HOME" bash "$INSTALLER" --local --dir "$MIN_WS" >/dev/null
assert_eq "$(count_dirs "$MIN_WS/.agents/skills")" "17" "local minimal skills"
[ -f "$MIN_WS/.agents/skills/multi-plan/SKILL.md" ] || fail "local minimal missing multi-plan"
assert_eq "$(count_files "$MIN_WS/.agents/agents")" "8" "local minimal agents"
assert_eq "$(count_files "$MIN_WS/.agents/rules")" "8" "local minimal rules"

HOME="$MIN_HOME" bash "$INSTALLER" --global >/dev/null
G_PLUG="$MIN_HOME/.gemini/config/plugins/antigravity-skills"
[ -f "$G_PLUG/plugin.json" ] || fail "global minimal missing plugin.json"
assert_eq "$(count_dirs "$G_PLUG/skills")" "17" "global minimal skills"
[ -f "$G_PLUG/skills/multi-plan/SKILL.md" ] || fail "global minimal missing multi-plan"
assert_eq "$(count_files "$G_PLUG/agents")" "8" "global minimal agents"
assert_eq "$(count_files "$G_PLUG/rules")" "8" "global minimal rules"
pass "TC-05: Default mode installs minimal (17 skills incl. multi-plan, 8 agents, 8 rules) for both --local and --global"

# ------------------------------------------------------------------------------
# TC-06: Single-Skill Sparse Install (--skill) + Python Helper Smoke Test
# ------------------------------------------------------------------------------
ONE_WS="$TEST_ROOT/one-ws"
mkdir -p "$ONE_WS"
HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$ONE_WS" --skill financial-analyst >/dev/null
assert_eq "$(count_dirs "$ONE_WS/.agents/skills")" "1" "fresh single skill count"
[ ! -d "$ONE_WS/.agents/agents" ] || fail "fresh --skill should not install agents"
[ ! -d "$ONE_WS/.agents/rules" ] || fail "fresh --skill should not install rules"
python3 -B "$ONE_WS/.agents/skills/financial-analyst/scripts/ratio_calculator.py" \
  "$ONE_WS/.agents/skills/financial-analyst/assets/sample_financial_data.json" >/dev/null
cleanup_case "$ONE_WS"
pass "TC-06: Fresh --skill installs ONLY 1 skill folder and bundled Python calculator executes cleanly (cleaned up)"

# ------------------------------------------------------------------------------
# TC-07: Typo Fuzzy Suggestion & Path Traversal Guard
# ------------------------------------------------------------------------------
TYPO_WS="$TEST_ROOT/typo-ws"
mkdir -p "$TYPO_WS"
set +e
TYPO_ERR="$(HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$TYPO_WS" --skill stock-analys 2>&1)"
TYPO_RC=$?
TRAV_ERR="$(HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$TYPO_WS" --skill ../etc/passwd 2>&1)"
TRAV_RC=$?
set -e
assert_eq "$TYPO_RC" "2" "typo exit code"
echo "$TYPO_ERR" | grep -q "stock-analysis" || fail "fuzzy suggestion missing stock-analysis: $TYPO_ERR"
assert_eq "$TRAV_RC" "2" "path traversal exit code"
[ ! -e "$TYPO_WS/.agents" ] || fail "failed --skill created .agents"
cleanup_case "$TYPO_WS"
pass "TC-07: Fuzzy typo suggestion ('stock-analysis') and path traversal guard work cleanly (cleaned up)"

# ------------------------------------------------------------------------------
# TC-08: Additive --skill on top of minimal + Selective --uninstall --skill
# ------------------------------------------------------------------------------
HOME="$MIN_HOME" bash "$INSTALLER" --local --dir "$MIN_WS" --skill stock-analysis,seo-audit >/dev/null
assert_eq "$(count_dirs "$MIN_WS/.agents/skills")" "19" "minimal + 2 skills = 19"
HOME="$MIN_HOME" bash "$INSTALLER" --local --dir "$MIN_WS" --uninstall --skill seo-audit --yes >/dev/null
assert_eq "$(count_dirs "$MIN_WS/.agents/skills")" "18" "after selective uninstall = 18"
[ -d "$MIN_WS/.agents/skills/stock-analysis" ] || fail "stock-analysis should remain"
[ ! -d "$MIN_WS/.agents/skills/seo-audit" ] || fail "seo-audit should be removed"
pass "TC-08: Additive --skill (17 -> 19) and selective --uninstall --skill (19 -> 18) work"

# ------------------------------------------------------------------------------
# TC-09: Role Pack (--role finance & alias --role c-suite)
# ------------------------------------------------------------------------------
ROLE_WS="$TEST_ROOT/role-ws"
ALIAS_WS="$TEST_ROOT/alias-ws"
mkdir -p "$ROLE_WS" "$ALIAS_WS"
HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$ROLE_WS" --role finance >/dev/null
assert_eq "$(count_dirs "$ROLE_WS/.agents/skills")" "13" "finance role skills"
assert_eq "$(count_files "$ROLE_WS/.agents/agents")" "2" "finance role agents"
assert_eq "$(count_files "$ROLE_WS/.agents/rules")" "9" "finance role rules"

HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$ALIAS_WS" --role c-suite >/dev/null
assert_eq "$(count_dirs "$ALIAS_WS/.agents/skills")" "17" "c-suite -> founder skills"
cleanup_case "$ROLE_WS" "$ALIAS_WS"
pass "TC-09: --role finance (13 skills) and --role c-suite alias (17 founder skills) verified (cleaned up)"

# ------------------------------------------------------------------------------
# TC-10: Full Pack (--all) + Reconcile Down to --minimal While Preserving Custom Files
# ------------------------------------------------------------------------------
ALL_WS="$TEST_ROOT/all-ws"
mkdir -p "$ALL_WS/.agents/skills/my-custom-skill"
printf -- "---\nname: my-custom-skill\ndescription: Custom\n---\n" > "$ALL_WS/.agents/skills/my-custom-skill/SKILL.md"
HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$ALL_WS" --all >/dev/null
assert_eq "$(count_dirs "$ALL_WS/.agents/skills")" "533" "532 managed + 1 custom"
assert_eq "$(count_files "$ALL_WS/.agents/agents")" "25" "all 25 agents"
assert_eq "$(count_files "$ALL_WS/.agents/rules")" "100" "all 100 rules"

HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$ALL_WS" --minimal >/dev/null
assert_eq "$(count_dirs "$ALL_WS/.agents/skills")" "18" "17 minimal + 1 preserved custom"
[ -f "$ALL_WS/.agents/skills/my-custom-skill/SKILL.md" ] || fail "custom skill deleted during slim-down"
cleanup_case "$ALL_WS"
pass "TC-10: --all installs 532/25/100 and --minimal slims down cleanly while preserving custom skills (cleaned up)"

# ------------------------------------------------------------------------------
# TC-11: Claude Code (--claude) across minimal, --skill, --role & --uninstall
# ------------------------------------------------------------------------------
CLAUDE_HOME="$TEST_ROOT/claude-home"
CLAUDE_WS="$TEST_ROOT/claude-ws"
mkdir -p "$CLAUDE_HOME/.claude/skills/personal-claude-skill" "$CLAUDE_WS"
echo '{"theme":"dark"}' > "$CLAUDE_HOME/.claude/settings.json"
echo "custom" > "$CLAUDE_HOME/.claude/skills/personal-claude-skill/SKILL.md"

HOME="$CLAUDE_HOME" bash "$INSTALLER" --claude --local --dir "$CLAUDE_WS" --skill stock-analysis >/dev/null
assert_eq "$(count_dirs "$CLAUDE_WS/.claude/skills")" "1" "claude --skill count"
[ ! -d "$CLAUDE_WS/.claude/agents" ] || fail "claude should not have agents/"

HOME="$CLAUDE_HOME" bash "$INSTALLER" --claude --global >/dev/null
assert_eq "$(count_dirs "$CLAUDE_HOME/.claude/skills")" "18" "17 minimal + 1 personal claude skill"
[ -f "$CLAUDE_HOME/.claude/skills/multi-plan/SKILL.md" ] || fail "claude minimal missing multi-plan"
HOME="$CLAUDE_HOME" bash "$INSTALLER" --claude --global --role frontend >/dev/null
assert_eq "$(count_dirs "$CLAUDE_HOME/.claude/skills")" "33" "claude minimal + frontend + personal"
HOME="$CLAUDE_HOME" bash "$INSTALLER" --claude --global --uninstall --yes >/dev/null
assert_eq "$(count_dirs "$CLAUDE_HOME/.claude/skills")" "1" "only personal claude skill remains"
[ -f "$CLAUDE_HOME/.claude/settings.json" ] || fail "claude settings.json lost"
cleanup_case "$CLAUDE_HOME" "$CLAUDE_WS"
pass "TC-11: Claude Code (--claude) verified across minimal, --skill, additive --role, and safe --uninstall (cleaned up)"

# ------------------------------------------------------------------------------
# TC-12: Stateful Live Upstream Update without bloating minimal
# ------------------------------------------------------------------------------
echo "" >> "$UPSTREAM/skills/stock-analysis/SKILL.md"
echo "<!-- v1.0.1 upstream update -->" >> "$UPSTREAM/skills/stock-analysis/SKILL.md"
echo "<!-- v1.0.1 unrelated skill -->" >> "$UPSTREAM/skills/kotlin-review/SKILL.md"
git -C "$UPSTREAM" add skills/stock-analysis/SKILL.md skills/kotlin-review/SKILL.md
git -C "$UPSTREAM" commit -q -m "feat: v1.0.1 skill updates"

(cd "$MIN_WS" && HOME="$EMPTY_HOME" bash "$INSTALLER" --update >/dev/null)
assert_eq "$(count_dirs "$MIN_WS/.agents/skills")" "18" "stateful --update kept exact 18 skills"
grep -q "v1.0.1 upstream update" "$MIN_WS/.agents/skills/stock-analysis/SKILL.md" || fail "stock-analysis did not receive v1.0.1 update"
[ ! -d "$MIN_WS/.agents/skills/kotlin-review" ] || fail "--update leaked unrelated skill into selective install"
cleanup_case "$MIN_WS" "$MIN_HOME"
pass "TC-12: Stateful --update pulls v1.0.1 changes without expanding 18-skill install to 532 (cleaned up)"

# ------------------------------------------------------------------------------
# TC-13: Backward Compatibility with Full Manual Git Clones
# ------------------------------------------------------------------------------
CLONE_WS="$TEST_ROOT/clone-ws"
mkdir -p "$CLONE_WS"
git clone -q --depth 1 "file://$UPSTREAM" "$CLONE_WS/.agents"
echo "<!-- v1.0.2 clone update -->" >> "$UPSTREAM/README.md"
git -C "$UPSTREAM" add README.md && git -C "$UPSTREAM" commit -q -m "docs: v1.0.2"
HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$CLONE_WS" --update >/dev/null
grep -q "v1.0.2 clone update" "$CLONE_WS/.agents/README.md" || fail "git clone fast-forward failed"
HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$CLONE_WS" --uninstall --yes >/dev/null
[ ! -e "$CLONE_WS/.agents" ] || fail "git clone uninstall failed"
cleanup_case "$CLONE_WS"
pass "TC-13: Legacy/manual full Git clones still fast-forward on --update and remove cleanly on --uninstall (cleaned up)"

# ------------------------------------------------------------------------------
# TC-14: Interactive 2-Step PTY Wizard (Target 1 -> Mode 4 Skill -> 'seo-audit')
# ------------------------------------------------------------------------------
PTY_WS="$TEST_ROOT/pty-ws"
mkdir -p "$PTY_WS"
python3 -B - "$INSTALLER" "$PTY_WS" "$UPSTREAM" <<'PYEOF'
import os, pty, select, sys, time
installer, ws_dir, upstream = sys.argv[1], sys.argv[2], sys.argv[3]
pid, master = pty.fork()
if pid == 0:
    os.chdir(ws_dir)
    os.environ["ANTIGRAVITY_SKILLS_REPO"] = upstream
    os.environ["HOME"] = ws_dir + "-home"
    os.execvp("bash", ["bash", installer])
buf = ""
s1 = s2 = s3 = False
deadline = time.time() + 30
while time.time() < deadline:
    r, _, _ = select.select([master], [], [], 0.2)
    if r:
        try:
            chunk = os.read(master, 4096).decode("utf-8", errors="replace")
            if not chunk: break
            buf += chunk
        except OSError: break
    if not s1 and "Select target [1-6]" in buf:
        os.write(master, b"1\n"); s1 = True
    if s1 and not s2 and "Select mode [1-4]" in buf:
        os.write(master, b"4\n"); s2 = True
    if s2 and not s3 and "Enter skill name(s)" in buf:
        os.write(master, b"seo-audit\n"); s3 = True
    wpid, status = os.waitpid(pid, os.WNOHANG)
    if wpid == pid:
        os.close(master)
        assert (os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1) == 0, f"PTY failed:\n{buf}"
        sys.exit(0)
os.close(master)
_, status = os.waitpid(pid, 0)
assert (os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1) == 0, f"PTY failed:\n{buf}"
PYEOF
assert_eq "$(count_dirs "$PTY_WS/.agents/skills")" "1" "PTY wizard single skill count"
[ -f "$PTY_WS/.agents/skills/seo-audit/SKILL.md" ] || fail "PTY wizard missing seo-audit"
cleanup_case "$PTY_WS"
pass "TC-14: Interactive 2-step /dev/tty wizard (Target 1 + Skill mode) verified via PTY (cleaned up)"

# ------------------------------------------------------------------------------
# TC-15: Security Regressions (symlink guard, --uninstall --role guard, excluded persistence, zero TMP leak)
# ------------------------------------------------------------------------------
SEC_WS="$TEST_ROOT/sec-ws"
SEC_TMP="$TEST_ROOT/sec-tmpdir"
OUTSIDE_FILE="$TEST_ROOT/outside-secret.txt"
mkdir -p "$SEC_WS" "$SEC_TMP"
TMPDIR="$SEC_TMP" HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$SEC_WS" >/dev/null
assert_eq "$(count_dirs "$SEC_TMP")" "0" "zero leaked temp dirs after normal exit"

set +e
HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$SEC_WS" --uninstall --role frontend --yes >/dev/null 2>&1
UN_ROLE_RC=$?
set -e
assert_eq "$UN_ROLE_RC" "2" "--uninstall --role must fail with exit 2"
assert_eq "$(count_dirs "$SEC_WS/.agents/skills")" "17" "skills intact after rejected --uninstall --role"

HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$SEC_WS" --uninstall --skill today-summary --yes >/dev/null
assert_eq "$(count_dirs "$SEC_WS/.agents/skills")" "16" "16 skills after excluding today-summary"
HOME="$EMPTY_HOME" bash "$INSTALLER" --local --dir "$SEC_WS" --update >/dev/null
assert_eq "$(count_dirs "$SEC_WS/.agents/skills")" "16" "today-summary stayed excluded across --update"

mkdir -p "$SEC_WS/.claude"
ln -s ../.agents/skills "$SEC_WS/.claude/skills"
set +e
HOME="$EMPTY_HOME" bash "$INSTALLER" --claude --local --dir "$SEC_WS" >/dev/null 2>&1
SYM_RC=$?
set -e
[ "$SYM_RC" -ne 0 ] || fail "symlinked .claude/skills should be blocked from direct overwrite"
assert_eq "$(count_dirs "$SEC_WS/.agents/skills")" "16" ".agents/skills untouched behind symlink"

echo "secret" > "$OUTSIDE_FILE"
printf '# @state {"base":"none","roles":[],"skills":[]}\n0000  ../../outside-secret.txt\n' > "$SEC_WS/.claude/.antigravity-skills.manifest"
rm -f "$SEC_WS/.claude/skills"
set +e
HOME="$EMPTY_HOME" bash "$INSTALLER" --claude --local --dir "$SEC_WS" --uninstall --force --yes >/dev/null 2>&1
TRAV_MAN_RC=$?
set -e
[ "$TRAV_MAN_RC" -ne 0 ] || fail "corrupted manifest path traversal must fail"
[ -f "$OUTSIDE_FILE" ] || fail "outside-secret.txt was deleted!"
cleanup_case "$SEC_WS" "$SEC_TMP" "$OUTSIDE_FILE"
pass "TC-15: Security guards verified (zero TMP leak, symlink guard, excluded persistence, manifest traversal block) (cleaned up)"

# ------------------------------------------------------------------------------
# TC-16: GitHub Copilot Local (--copilot --local) + .github/ Preservation + Live --update + --uninstall
# ------------------------------------------------------------------------------
COP_WS="$TEST_ROOT/copilot-ws"
mkdir -p "$COP_WS/.github/workflows"
echo "name: CI" > "$COP_WS/.github/workflows/ci.yml"
echo "# My custom repo instructions" > "$COP_WS/.github/copilot-instructions.md"

HOME="$EMPTY_HOME" bash "$INSTALLER" --copilot --local --dir "$COP_WS" >/dev/null
assert_eq "$(count_dirs "$COP_WS/.github/skills")" "17" "copilot local minimal skills"
assert_eq "$(count_files "$COP_WS/.github/instructions")" "8" "copilot local minimal instructions"
assert_eq "$(count_files "$COP_WS/.github/agents")" "8" "copilot local minimal agents"
grep -q 'applyTo: "\*\*"' "$COP_WS/.github/instructions/common-security.instructions.md" || fail "always_on rule missing applyTo **"
grep -q '^tools: \[read, search, execute\]' "$COP_WS/.github/agents/code-reviewer.agent.md" || fail "code-reviewer.agent.md tools mismatch"
! grep -q '^subagent:' "$COP_WS/.github/agents/code-reviewer.agent.md" || fail "subagent key leaked into .agent.md"

HOME="$EMPTY_HOME" bash "$INSTALLER" --copilot --local --dir "$COP_WS" --role frontend >/dev/null
assert_eq "$(count_dirs "$COP_WS/.github/skills")" "32" "copilot minimal + frontend skills"
grep -q 'applyTo: "\*\*/\*\.ts, \*\*/\*\.tsx, \*\*/\*\.js, \*\*/\*\.jsx"' "$COP_WS/.github/instructions/typescript-coding-style.instructions.md" || fail "typescript glob rule applyTo mismatch"
grep -q "# My custom repo instructions" "$COP_WS/.github/copilot-instructions.md" || fail "custom copilot-instructions.md overwritten"
[ -f "$COP_WS/.github/workflows/ci.yml" ] || fail ".github/workflows/ci.yml lost"

echo "" >> "$UPSTREAM/rules/common-security.md"
echo "<!-- copilot v1.0.3 rule update -->" >> "$UPSTREAM/rules/common-security.md"
git -C "$UPSTREAM" add rules/common-security.md && git -C "$UPSTREAM" commit -q -m "docs: v1.0.3 rule update"
(cd "$COP_WS" && HOME="$EMPTY_HOME" bash "$INSTALLER" --copilot --update >/dev/null)
grep -q "copilot v1.0.3 rule update" "$COP_WS/.github/instructions/common-security.instructions.md" || fail "transformed .instructions.md did not update"

HOME="$EMPTY_HOME" bash "$INSTALLER" --copilot --local --dir "$COP_WS" --uninstall --yes >/dev/null
[ ! -d "$COP_WS/.github/skills" ] || fail ".github/skills not cleaned on uninstall"
[ ! -d "$COP_WS/.github/instructions" ] || fail ".github/instructions not cleaned on uninstall"
[ ! -d "$COP_WS/.github/agents" ] || fail ".github/agents not cleaned on uninstall"
[ -f "$COP_WS/.github/workflows/ci.yml" ] || fail ".github/workflows/ci.yml deleted on uninstall"
[ -f "$COP_WS/.github/copilot-instructions.md" ] || fail ".github/copilot-instructions.md deleted on uninstall"
cleanup_case "$COP_WS"
pass "TC-16: GitHub Copilot --local verified (17 skills, .instructions.md, .agent.md, --role, --update, safe --uninstall) (cleaned up)"

# ------------------------------------------------------------------------------
# TC-17: GitHub Copilot Global (--copilot --global) + PTY Wizard Target 5
# ------------------------------------------------------------------------------
COP_HOME="$TEST_ROOT/copilot-home"
mkdir -p "$COP_HOME/.copilot/skills/my-personal-copilot-skill"
echo "custom" > "$COP_HOME/.copilot/skills/my-personal-copilot-skill/SKILL.md"
HOME="$COP_HOME" bash "$INSTALLER" --copilot --global >/dev/null
assert_eq "$(count_dirs "$COP_HOME/.copilot/skills")" "18" "copilot global 17 minimal + 1 personal"
[ ! -d "$COP_HOME/.copilot/instructions" ] || fail "copilot global should not install instructions/"
[ ! -d "$COP_HOME/.copilot/agents" ] || fail "copilot global should not install agents/"
HOME="$COP_HOME" bash "$INSTALLER" --copilot --global --skill financial-analyst >/dev/null
assert_eq "$(count_dirs "$COP_HOME/.copilot/skills")" "19" "copilot global + financial-analyst"
python3 -B "$COP_HOME/.copilot/skills/financial-analyst/scripts/ratio_calculator.py" \
  "$COP_HOME/.copilot/skills/financial-analyst/assets/sample_financial_data.json" >/dev/null
HOME="$COP_HOME" bash "$INSTALLER" --copilot --global --uninstall --yes >/dev/null
assert_eq "$(count_dirs "$COP_HOME/.copilot/skills")" "1" "only personal copilot skill remains"
cleanup_case "$COP_HOME"

COP_PTY_WS="$TEST_ROOT/copilot-pty-ws"
mkdir -p "$COP_PTY_WS"
python3 -B - "$INSTALLER" "$COP_PTY_WS" "$UPSTREAM" <<'PYEOF'
import os, pty, select, sys, time
installer, ws_dir, upstream = sys.argv[1], sys.argv[2], sys.argv[3]
pid, master = pty.fork()
if pid == 0:
    os.chdir(ws_dir)
    os.environ["ANTIGRAVITY_SKILLS_REPO"] = upstream
    os.environ["HOME"] = ws_dir + "-home"
    os.execvp("bash", ["bash", installer])
buf = ""
s1 = s2 = s3 = False
deadline = time.time() + 30
while time.time() < deadline:
    r, _, _ = select.select([master], [], [], 0.2)
    if r:
        try:
            chunk = os.read(master, 4096).decode("utf-8", errors="replace")
            if not chunk: break
            buf += chunk
        except OSError: break
    if not s1 and "Select target [1-6]" in buf:
        os.write(master, b"5\n"); s1 = True
    if s1 and not s2 and "Select mode [1-4]" in buf:
        os.write(master, b"4\n"); s2 = True
    if s2 and not s3 and "Enter skill name(s)" in buf:
        os.write(master, b"seo-audit\n"); s3 = True
    wpid, status = os.waitpid(pid, os.WNOHANG)
    if wpid == pid:
        os.close(master)
        assert (os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1) == 0, f"Copilot PTY failed:\n{buf}"
        sys.exit(0)
os.close(master)
_, status = os.waitpid(pid, 0)
assert (os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1) == 0, f"Copilot PTY failed:\n{buf}"
PYEOF
[ -f "$COP_PTY_WS/.github/skills/seo-audit/SKILL.md" ] || fail "Copilot PTY missing .github/skills/seo-audit/SKILL.md"
cleanup_case "$COP_PTY_WS"
pass "TC-17: GitHub Copilot --global (skills + Python calculator + safe uninstall) and PTY Target 5 verified (cleaned up)"

echo ""
echo "🎉 ALL 17 TEST SUITES PASSED SUCCESSFULLY!"
