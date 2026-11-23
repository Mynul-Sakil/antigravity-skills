#!/usr/bin/env bash
# antigravity-skills — Selective Installer, Updater & Uninstaller
# Targets: Antigravity (default) | --claude | --copilot
# Modes:   --minimal (default) | --skill <name> | --role <role> | --all
# Repo:    https://github.com/Mynul-Sakil/antigravity-skills

if [ -z "${BASH_VERSION:-}" ]; then
  echo "[ERR] Please run this script with bash (e.g., 'bash install.sh')." >&2
  exit 1
fi

set -euo pipefail

# Global scope so Bash 3.2 EXIT trap sees TMP_DIR after main() returns
TMP_DIR=""
cleanup() {
  if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
    rm -rf -- "$TMP_DIR"
  fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM HUP

main() {
  local REPO_URL="${ANTIGRAVITY_SKILLS_REPO:-https://github.com/Mynul-Sakil/antigravity-skills.git}"
  local BRANCH="${ANTIGRAVITY_SKILLS_BRANCH:-main}"
  local MANIFEST_NAME=".antigravity-skills.manifest"

  local AGENT="antigravity" EXPLICIT_AGENT=0 SCOPE="" ACTION="auto" EXPLICIT_BASE=""
  local REQ_ROLES_CSV="" REQ_SKILLS_CSV="" LIST_MODE=""
  local PROJECT_DIR="$PWD" EXPLICIT_DIR=0 DRY_RUN=0 FORCE=0 ASSUME_YES=0

  local C_GREEN="" C_BLUE="" C_YELLOW="" C_RED="" C_BOLD="" C_RESET=""
  if [ -t 1 ]; then
    C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_YELLOW='\033[1;33m'
    C_RED='\033[0;31m'; C_BOLD='\033[1m'; C_RESET='\033[0m'
  fi

  info() { printf "%b[INFO]%b %s\n" "$C_BLUE" "$C_RESET" "$*"; }
  ok()   { printf "%b[OK]%b   %s\n" "$C_GREEN" "$C_RESET" "$*"; }
  warn() { printf "%b[WARN]%b %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2; }
  err()  { printf "%b[ERR]%b  %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
  die()  { err "$1"; exit "${2:-1}"; }

  usage() {
    cat <<'EOF'
Antigravity Skills — Selective Installer, Updater & Uninstaller

Usage:
  ./install.sh [options]
  curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- [options]

Target Scope Options:
  --local, --workspace    Install or update in current/project directory
                          (Antigravity: ./.agents | Claude Code: ./.claude/skills
                           GitHub Copilot: ./.github/{skills,instructions,agents})
  --global                Install or update globally across all projects
                          (Antigravity: ~/.gemini/config/plugins/antigravity-skills
                           Claude Code: ~/.claude/skills | GitHub Copilot: ~/.copilot/skills)
  --claude                Target Claude Code instead of Antigravity
  --copilot               Target GitHub Copilot instead of Antigravity
  --dir <path>            Override target project directory (implies --local if scope omitted)

Install Mode Options (Default on fresh install: --minimal):
  --minimal               Install curated core pack (17 skills, 8 subagents, 8 rules) [DEFAULT]
  --all                   Install full catalog (532 skills, 25 subagents, 100 rules)
  --skill <name[,name2]>  Install specific skill(s) without downloading the whole repo (additive)
  --role <role[,role2]>   Install curated role pack(s) via sparse checkout (additive)
                          Roles: frontend, backend, fullstack, qa, security, devops,
                                 ai-ml, finance, product, marketing, founder (alias: c-suite)
  --list-roles            List all available --role packs with counts and exit
  --list-skills           List all available skill names and exit

Action Options:
  --update                Update existing installation (preserves your installed mode/skills)
  --uninstall             Safely remove installed files (or combine with --skill <name>)
  --force                 Back up conflicting modified files to .backups/ and overwrite
  --yes, -y               Skip interactive confirmation prompts (for --uninstall)
  --dry-run               Preview planned actions without modifying any files
  --help, -h              Show this help message

Examples:
  ./install.sh                                      # Interactive 2-step menu (Location + Mode)
  ./install.sh --local                              # Install Minimal pack in ./.agents
  ./install.sh --global                             # Install Minimal pack globally
  ./install.sh --local --all                        # Install all 532 skills in ./.agents
  ./install.sh --local --skill stock-analysis       # Install ONLY 'stock-analysis' skill
  ./install.sh --global --role fullstack            # Install 'fullstack' role pack globally
  ./install.sh --claude --local --skill seo-audit   # Install 'seo-audit' in ./.claude/skills
  ./install.sh --copilot --local                    # Install Minimal pack in ./.github/
  ./install.sh --copilot --global                   # Install Minimal skills in ~/.copilot/skills
  ./install.sh --update                             # Update existing local/global installation
EOF
  }

  canon_dir() { (cd -- "$1" 2>/dev/null && pwd -P); }
  has_tty()   { (: </dev/tty) 2>/dev/null; }

  validate_tokens_csv() {
    local raw="$1" label="$2" current="$3" normalized tok
    local -a toks=()
    normalized="$(printf "%s" "$raw" | tr ' \t' ',,')"
    IFS=',' read -r -a toks <<< "$normalized"
    for tok in "${toks[@]+"${toks[@]}"}"; do
      [ -n "$tok" ] || continue
      case "$tok" in
        *[!a-zA-Z0-9._-]*|..|.)
          die "Invalid $label identifier '$tok'. Only letters, digits, '.', '_', and '-' are allowed." 2 ;;
      esac
      current="${current:+$current,}$tok"
    done
    [ -n "$current" ] || die "Missing valid $label name." 2
    printf "%s" "$current"
  }

  prompt_confirm() {
    local msg="$1" reply=""
    [ "$ASSUME_YES" -eq 1 ] && return 0
    has_tty || die "Confirmation required in non-interactive session. Re-run with --yes." 2
    printf "%s [y/N]: " "$msg" >/dev/tty
    read -r reply </dev/tty || true
    case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
  }

  normalize_repo_url() {
    if [ -d "$1" ]; then printf "file://%s" "$(canon_dir "$1")"; else printf "%s" "$1"; fi
  }

  is_our_repo_clone() {
    local dir="$1" real_dir top origin_url norm_repo
    [ -d "$dir" ] && [ -d "$dir/.git" ] || return 1
    real_dir="$(canon_dir "$dir" || true)"
    [ -n "$real_dir" ] || return 1
    top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
    [ "$top" = "$real_dir" ] || return 1
    origin_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
    case "$origin_url" in file://*) [ -d "${origin_url#file://}" ] && origin_url="file://$(canon_dir "${origin_url#file://}")" ;; esac
    norm_repo="$(normalize_repo_url "$REPO_URL")"
    case "$origin_url" in
      *antigravity-skills*|"$REPO_URL"|"$norm_repo") return 0 ;;
      *) [ -d "$REPO_URL" ] && [ "$origin_url" = "$(canon_dir "$REPO_URL")" ] && return 0; return 1 ;;
    esac
  }

  while [ $# -gt 0 ]; do
    case "$1" in
      --local|--workspace) [ "$SCOPE" = "global" ] && die "Cannot combine --local and --global." 2; SCOPE="local"; shift ;;
      --global) [ "$SCOPE" = "local" ] && die "Cannot combine --local and --global." 2; SCOPE="global"; shift ;;
      --claude) [ "$EXPLICIT_AGENT" -eq 1 ] && [ "$AGENT" != "claude" ] && die "Cannot combine multiple agent flags." 2; AGENT="claude"; EXPLICIT_AGENT=1; shift ;;
      --copilot|--github-copilot) [ "$EXPLICIT_AGENT" -eq 1 ] && [ "$AGENT" != "copilot" ] && die "Cannot combine multiple agent flags." 2; AGENT="copilot"; EXPLICIT_AGENT=1; shift ;;
      --antigravity) [ "$EXPLICIT_AGENT" -eq 1 ] && [ "$AGENT" != "antigravity" ] && die "Cannot combine multiple agent flags." 2; AGENT="antigravity"; EXPLICIT_AGENT=1; shift ;;
      --dir|--project-dir) [ $# -ge 2 ] || die "Missing path argument for $1" 2; PROJECT_DIR="$2"; EXPLICIT_DIR=1; shift 2 ;;
      --minimal) [ "$EXPLICIT_BASE" = "all" ] && die "Cannot combine --minimal and --all." 2; EXPLICIT_BASE="minimal"; shift ;;
      --all) [ "$EXPLICIT_BASE" = "minimal" ] && die "Cannot combine --minimal and --all." 2; EXPLICIT_BASE="all"; shift ;;
      --skill|--skills) [ $# -ge 2 ] || die "Missing skill name for $1" 2; REQ_SKILLS_CSV="$(validate_tokens_csv "$2" "skill" "$REQ_SKILLS_CSV")"; shift 2 ;;
      --role|--roles) [ $# -ge 2 ] || die "Missing role name for $1" 2; REQ_ROLES_CSV="$(validate_tokens_csv "$2" "role" "$REQ_ROLES_CSV")"; shift 2 ;;
      --list-roles) LIST_MODE="roles"; shift ;;
      --list-skills) LIST_MODE="skills"; shift ;;
      --update) [ "$ACTION" = "uninstall" ] && die "Cannot combine --update and --uninstall." 2; ACTION="update"; shift ;;
      --uninstall) [ "$ACTION" = "update" ] && die "Cannot combine --update and --uninstall." 2; ACTION="uninstall"; shift ;;
      --force) FORCE=1; shift ;;
      --yes|-y) ASSUME_YES=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --help|-h) usage; exit 0 ;;
      *) err "Unknown option: $1"; usage >&2; exit 2 ;;
    esac
  done

  if [ "$EXPLICIT_BASE" = "all" ] && { [ -n "$REQ_SKILLS_CSV" ] || [ -n "$REQ_ROLES_CSV" ]; }; then
    die "Cannot combine --all with --skill or --role." 2
  fi
  if [ "$ACTION" = "uninstall" ] && { [ -n "$EXPLICIT_BASE" ] || [ -n "$REQ_ROLES_CSV" ]; }; then
    die "Cannot combine --uninstall with --minimal, --all, or --role (only --skill <name> is supported for partial removal)." 2
  fi

  command -v git >/dev/null 2>&1 || die "'git' is required. Please install git first." 1

  local PYTHON_BIN=""
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  elif command -v python >/dev/null 2>&1 && python -c 'import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)' 2>/dev/null; then
    PYTHON_BIN="python"
  else
    die "'python3' (3.8+) is required for profile resolution and safe SHA-256 manifest sync." 1
  fi

  local CLONE_URL LOCAL_PROFILES_FALLBACK="" LOCAL_ENGINE_FALLBACK=""
  CLONE_URL="$(normalize_repo_url "$REPO_URL")"
  if [ -d "$REPO_URL" ]; then
    local canon_repo=""
    canon_repo="$(canon_dir "$REPO_URL")"
    [ -f "$canon_repo/profiles.json" ] && LOCAL_PROFILES_FALLBACK="$canon_repo/profiles.json"
    [ -f "$canon_repo/scripts/installer_engine.py" ] && LOCAL_ENGINE_FALLBACK="$canon_repo/scripts/installer_engine.py"
  fi

  stage_repo_trees() {
    local want_full="${1:-0}" cloned=0
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR/repo/.git" ]; then
      if [ "$want_full" -eq 1 ] && [ "$(git -C "$TMP_DIR/repo" config --bool remote.origin.promisor 2>/dev/null || true)" = "true" ]; then
        rm -rf -- "$TMP_DIR/repo"
      else return 0; fi
    fi
    [ -n "$TMP_DIR" ] || TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'antigravity-skills')"
    info "Fetching package from ${REPO_URL} (${BRANCH})..."
    if [ "$want_full" -eq 1 ]; then
      GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --no-checkout --branch "$BRANCH" "$CLONE_URL" "$TMP_DIR/repo"
      return 0
    fi
    case "$CLONE_URL" in
      file://*)
        local up_cmd="git -c uploadpack.allowFilter=true -c uploadpack.allowAnySHA1InWant=true upload-pack"
        GIT_TERMINAL_PROMPT=0 git -c "remote.origin.uploadpack=$up_cmd" clone --upload-pack="$up_cmd" \
          --quiet --depth 1 --filter=blob:none --no-checkout --branch "$BRANCH" "$CLONE_URL" "$TMP_DIR/repo" 2>/dev/null && cloned=1 ;;
      *)
        GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --filter=blob:none --no-checkout \
          --branch "$BRANCH" "$CLONE_URL" "$TMP_DIR/repo" 2>/dev/null && cloned=1 ;;
    esac
    if [ "$cloned" -eq 0 ]; then
      rm -rf -- "$TMP_DIR/repo"
      GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --no-checkout --branch "$BRANCH" "$CLONE_URL" "$TMP_DIR/repo"
    fi
  }

  # Execute modular Python engine (scripts/installer_engine.py) for list & sync
  run_py_engine() {
    local engine_cmd="$1" repo_dir="$2" engine_file=""
    if [ -n "$TMP_DIR" ]; then
      engine_file="$TMP_DIR/installer_engine.py"
      if git -C "$repo_dir" show "HEAD:scripts/installer_engine.py" > "$engine_file" 2>/dev/null; then
        "$PYTHON_BIN" -B "$engine_file" "$@"
        return $?
      fi
    fi
    if [ -n "$LOCAL_ENGINE_FALLBACK" ] && [ -f "$LOCAL_ENGINE_FALLBACK" ]; then
      "$PYTHON_BIN" -B "$LOCAL_ENGINE_FALLBACK" "$@"
      return $?
    fi
    die "Installer engine 'scripts/installer_engine.py' not found in repository." 1
  }

  # Inline offline-capable Python uninstaller (requires zero network access)
  run_py_uninstall() {
    "$PYTHON_BIN" -B - "$@" <<'PYEOF'
import hashlib, json, os, shutil, sys
from pathlib import Path

dst_root, manifest_name = Path(sys.argv[1]), sys.argv[2]
dry_run, force = (sys.argv[3] == "1"), (sys.argv[4] == "1")
target_skills = [s.strip() for s in sys.argv[5].split(",") if s.strip()]
manifest_path = dst_root / manifest_name

def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def is_clean_rel(rel: str) -> bool:
    if not rel or rel.startswith("/") or "\\" in rel: return False
    p = Path(rel)
    return (not p.is_absolute()) and (".." not in p.parts) and ("." not in p.parts)

def safe_target_path(root: Path, rel: str) -> Path:
    if not is_clean_rel(rel): sys.exit(f"[ERR]  Invalid relative path in manifest: '{rel}'")
    if root.is_symlink(): sys.exit(f"[ERR]  Refusing to operate on symlinked root '{root}'.")
    cur = root
    for part in Path(rel).parts[:-1]:
        cur = cur / part
        if cur.is_symlink(): sys.exit(f"[ERR]  Refusing to traverse symlinked directory '{cur}'.")
    p = root / rel
    r_real = os.path.realpath(str(root))
    p_real = os.path.realpath(str(p.parent)) if p.parent.exists() else r_real
    if os.path.commonpath([r_real, p_real]) != r_real: sys.exit(f"[ERR]  Path containment check blocked '{rel}'")
    return p

def prune_empty_parents(p: Path, stop_root: Path):
    parent = p.parent
    while parent != stop_root and parent.exists() and not parent.is_symlink():
        ds = parent / ".DS_Store"
        if ds.is_file() and not ds.is_symlink(): ds.unlink()
        pc = parent / "__pycache__"
        if pc.is_dir() and not pc.is_symlink() and all(c.is_file() and c.suffix in (".pyc", ".pyo") for c in pc.iterdir()):
            shutil.rmtree(pc)
        if any(parent.iterdir()): break
        parent.rmdir(); parent = parent.parent

if manifest_path.is_symlink(): sys.exit(f"[ERR]  Refusing to read symlinked manifest '{manifest_path}'")
state, entries = {"base": "all", "roles": [], "skills": [], "excluded": []}, {}
for idx, ln in enumerate(manifest_path.read_text(encoding="utf-8").splitlines()):
    if idx == 0 and ln.startswith("# @state "):
        try:
            p = json.loads(ln[len("# @state "):])
            state = {"base": p.get("base", "minimal"), "roles": list(p.get("roles", [])),
                     "skills": list(p.get("skills", [])), "excluded": list(p.get("excluded", []))}
        except Exception: pass
    elif not ln.startswith("#") and "  " in ln:
        h, rel = ln.split("  ", 1)
        rel_s = rel.strip()
        if not is_clean_rel(rel_s): sys.exit(f"[ERR]  Corrupted or unsafe path in {manifest_path}: '{rel_s}'")
        entries[rel_s] = h.strip()

if target_skills:
    present = {r.split("/")[1] for r in entries if r.startswith("skills/") and r.count("/") >= 2}
    missing = [s for s in target_skills if s not in present]
    if missing: sys.stderr.write(f"[WARN] Skill(s) not installed in {dst_root}: {', '.join(missing)}\n")

removed = preserved = 0
kept = {}
for rel, old_hash in sorted(entries.items()):
    remove_it = (not target_skills) or any(rel.startswith(f"skills/{s}/") for s in target_skills)
    if not remove_it:
        kept[rel] = old_hash; continue
    df = safe_target_path(dst_root, rel)
    if df.is_symlink() or not df.is_file(): continue
    if force or sha256_file(df) == old_hash:
        removed += 1
        if not dry_run: df.unlink(); prune_empty_parents(df, dst_root)
    else:
        preserved += 1

if target_skills:
    explicit_sk, excl = set(state.get("skills", [])), set(state.get("excluded", []))
    for s in target_skills:
        if s in explicit_sk: explicit_sk.discard(s)
        elif state.get("base") != "none" or state.get("roles"): excl.add(s)
    state["skills"], state["excluded"] = sorted(explicit_sk), sorted(excl)
    if not [r for r in kept if r != "plugin.json"] and "plugin.json" in kept:
        pf = safe_target_path(dst_root, "plugin.json")
        if not pf.is_symlink() and pf.is_file() and (force or sha256_file(pf) == kept["plugin.json"]):
            removed += 1
            if not dry_run: pf.unlink()
        kept.pop("plugin.json", None)

if not dry_run:
    if kept:
        clean_state = {"base": state["base"], "roles": state["roles"], "skills": state["skills"]}
        if state.get("excluded"): clean_state["excluded"] = sorted(set(state["excluded"]))
        header = "# @state " + json.dumps(clean_state, separators=(",", ":"))
        manifest_path.write_text("\n".join([header] + [f"{h}  {r}" for r, h in sorted(kept.items())]) + "\n", encoding="utf-8")
    else:
        manifest_path.unlink()
        if dst_root.exists() and not dst_root.is_symlink() and not any(dst_root.iterdir()):
            dst_root.rmdir()
pfx = "[DRY-RUN] " if dry_run else ""
print(f"{pfx}Uninstall summary -> removed managed files: {removed}, preserved modified/custom files: {preserved}")
PYEOF
  }

  if [ -n "$LIST_MODE" ]; then
    stage_repo_trees 0
    run_py_engine "list" "$TMP_DIR/repo" "$LIST_MODE" "$LOCAL_PROFILES_FALLBACK"
    exit 0
  fi

  [ "$EXPLICIT_DIR" -eq 1 ] && [ -z "$SCOPE" ] && SCOPE="local"
  if [ "$SCOPE" != "global" ]; then
    if [ "$EXPLICIT_DIR" -eq 1 ]; then
      if [ ! -d "$PROJECT_DIR" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then info "[DRY-RUN] Would create project directory: $PROJECT_DIR"; else mkdir -p -- "$PROJECT_DIR"; fi
      fi
      [ -d "$PROJECT_DIR" ] && PROJECT_DIR="$(canon_dir "$PROJECT_DIR")"
    else
      PROJECT_DIR="$(canon_dir "$PROJECT_DIR")"
    fi
  fi

  if [ -z "$SCOPE" ] && [ "$ACTION" = "update" ]; then
    local has_local=0 has_global=0
    if [ "$AGENT" = "antigravity" ]; then
      if [ "$(basename -- "$PROJECT_DIR")" = ".agents" ] && is_our_repo_clone "$PROJECT_DIR"; then has_local=1
      elif is_our_repo_clone "$PROJECT_DIR/.agents" || [ -f "$PROJECT_DIR/.agents/$MANIFEST_NAME" ]; then has_local=1; fi
      if is_our_repo_clone "${HOME}/.gemini/config/plugins/antigravity-skills" || [ -f "${HOME}/.gemini/config/plugins/antigravity-skills/$MANIFEST_NAME" ]; then has_global=1; fi
    elif [ "$AGENT" = "copilot" ]; then
      [ -f "$PROJECT_DIR/.github/$MANIFEST_NAME" ] && has_local=1
      [ -f "${HOME}/.copilot/$MANIFEST_NAME" ] && has_global=1
    else
      [ -f "$PROJECT_DIR/.claude/$MANIFEST_NAME" ] && has_local=1
      [ -f "${HOME}/.claude/$MANIFEST_NAME" ] && has_global=1
    fi
    if [ "$has_local" -eq 1 ] && [ "$has_global" -eq 0 ]; then SCOPE="local"
    elif [ "$has_global" -eq 1 ] && [ "$has_local" -eq 0 ]; then SCOPE="global"
    elif [ "$has_local" -eq 1 ] && [ "$has_global" -eq 1 ]; then SCOPE="both"
    else die "No existing $AGENT installation detected to update. Run without --update (or pass --local / --global) to install." 1; fi
  fi

  if [ -z "$SCOPE" ]; then
    has_tty || die "Non-interactive session detected without a scope flag. Pass --local or --global (e.g., curl -fsSL .../install.sh | bash -s -- --local)." 2
    local def_target="1"
    [ "$EXPLICIT_AGENT" -eq 1 ] && [ "$AGENT" = "claude" ] && def_target="3"
    [ "$EXPLICIT_AGENT" -eq 1 ] && [ "$AGENT" = "copilot" ] && def_target="5"
    printf "\n%bAntigravity Skills — Step 1/2: Choose Target Location%b\n" "$C_BOLD" "$C_RESET" >/dev/tty
    printf "  1) Antigravity    — Current Directory (%s/.agents)\n" "$PROJECT_DIR" >/dev/tty
    printf "  2) Antigravity    — Global Plugin     (%s/.gemini/config/plugins/antigravity-skills)\n" "$HOME" >/dev/tty
    printf "  3) Claude Code    — Current Directory (%s/.claude/skills)\n" "$PROJECT_DIR" >/dev/tty
    printf "  4) Claude Code    — Global            (%s/.claude/skills)\n" "$HOME" >/dev/tty
    printf "  5) GitHub Copilot — Current Directory (%s/.github)\n" "$PROJECT_DIR" >/dev/tty
    printf "  6) GitHub Copilot — Global            (%s/.copilot/skills)\n" "$HOME" >/dev/tty
    printf "\nSelect target [1-6] (default: %s): " "$def_target" >/dev/tty
    local choice=""
    read -r choice </dev/tty || true
    case "${choice:-$def_target}" in
      1) AGENT="antigravity"; SCOPE="local" ;;
      2) AGENT="antigravity"; SCOPE="global" ;;
      3) AGENT="claude";      SCOPE="local" ;;
      4) AGENT="claude";      SCOPE="global" ;;
      5) AGENT="copilot";     SCOPE="local" ;;
      6) AGENT="copilot";     SCOPE="global" ;;
      *) die "Invalid selection: $choice" 2 ;;
    esac

    if [ "$ACTION" = "auto" ] && [ -z "$EXPLICIT_BASE" ] && [ -z "$REQ_ROLES_CSV" ] && [ -z "$REQ_SKILLS_CSV" ]; then
      printf "\n%bAntigravity Skills — Step 2/2: Choose Install Mode%b\n" "$C_BOLD" "$C_RESET" >/dev/tty
      printf "  1) Minimal  — Essential core (17 skills, 8 subagents, 8 rules) [default]\n" >/dev/tty
      printf "  2) All      — Full library   (532 skills, 25 subagents, 100 rules)\n" >/dev/tty
      printf "  3) Role     — Curated pack   (frontend, backend, fullstack, qa, security, devops, ai-ml, finance, product, marketing, founder)\n" >/dev/tty
      printf "  4) Skill    — Specific skill(s) without downloading full repo\n" >/dev/tty
      printf "\nSelect mode [1-4] (default: 1): " >/dev/tty
      local mchoice=""
      read -r mchoice </dev/tty || true
      case "${mchoice:-1}" in
        1) EXPLICIT_BASE="minimal" ;;
        2) EXPLICIT_BASE="all" ;;
        3)
          printf "\nAvailable roles:\n  1) frontend    2) backend     3) fullstack   4) qa\n  5) security    6) devops      7) ai-ml       8) finance\n  9) product    10) marketing  11) founder (c-suite)\n" >/dev/tty
          printf "Enter role number(s) or name(s) (comma/space separated): " >/dev/tty
          local rinput="" rtok rname mapped="" rnorm
          local -a rtoks=()
          read -r rinput </dev/tty || true
          rnorm="$(printf "%s" "$rinput" | tr ' \t' ',,')"
          IFS=',' read -r -a rtoks <<< "$rnorm"
          for rtok in "${rtoks[@]+"${rtoks[@]}"}"; do
            [ -n "$rtok" ] || continue
            case "$rtok" in
              1) rname="frontend" ;; 2) rname="backend" ;; 3) rname="fullstack" ;; 4) rname="qa" ;;
              5) rname="security" ;; 6) rname="devops" ;; 7) rname="ai-ml" ;; 8) rname="finance" ;;
              9) rname="product" ;; 10) rname="marketing" ;; 11) rname="founder" ;; *) rname="$rtok" ;;
            esac
            mapped="${mapped:+$mapped,}$rname"
          done
          REQ_ROLES_CSV="$(validate_tokens_csv "$mapped" "role" "")" ;;
        4)
          printf "Enter skill name(s) (comma/space separated, e.g. stock-analysis): " >/dev/tty
          local sinput=""
          read -r sinput </dev/tty || true
          REQ_SKILLS_CSV="$(validate_tokens_csv "$sinput" "skill" "")" ;;
        *) die "Invalid mode selection: $mchoice" 2 ;;
      esac
    fi
  fi

  uninstall_manifest_target() {
    local target_root="$1" skills_only_csv="${2:-}"
    [ -f "$target_root/$MANIFEST_NAME" ] || die "No manifest found at $target_root/$MANIFEST_NAME — refusing to delete untracked directory." 1
    if [ "$DRY_RUN" -eq 0 ]; then
      if [ -n "$skills_only_csv" ]; then
        prompt_confirm "Remove skill(s) [$skills_only_csv] from $target_root?" || { warn "Uninstall cancelled."; return 0; }
      else
        prompt_confirm "Remove antigravity-skills managed files from $target_root (custom files will be preserved)?" || { warn "Uninstall cancelled."; return 0; }
      fi
    fi
    run_py_uninstall "$target_root" "$MANIFEST_NAME" "$DRY_RUN" "$FORCE" "$skills_only_csv"
  }

  git_update_clone() {
    local target_dir="$1" dirty=""
    dirty="$(git -C "$target_dir" status --porcelain --untracked-files=no 2>/dev/null || true)"
    if [ -n "$dirty" ]; then
      if [ "$FORCE" -eq 1 ]; then
        local stash_msg="antigravity-skills-backup-$(date +%Y%m%d-%H%M%S)"
        if [ "$DRY_RUN" -eq 1 ]; then
          info "[DRY-RUN] Would stash local modifications as '$stash_msg' before updating."
        else
          warn "Stashing local tracked edits as '$stash_msg' (restore anytime with: git -C \"$target_dir\" stash pop)"
          git -C "$target_dir" stash push -m "$stash_msg" >/dev/null
        fi
      else
        err "Local tracked modifications detected in $target_dir:"; printf "%s\n" "$dirty" >&2
        die "Stash or discard your changes first, or re-run with --force to auto-stash and update." 1
      fi
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      info "[DRY-RUN] Would fetch '$BRANCH' from '$REPO_URL' and fast-forward '$target_dir'."; return 0
    fi
    local before_rev after_rev
    before_rev="$(git -C "$target_dir" rev-parse --short HEAD)"
    GIT_TERMINAL_PROMPT=0 git -C "$target_dir" fetch --quiet origin "$BRANCH"
    git -C "$target_dir" merge --quiet --ff-only FETCH_HEAD
    after_rev="$(git -C "$target_dir" rev-parse --short HEAD)"
    if [ "$before_rev" = "$after_rev" ]; then ok "Already up to date at $target_dir ($after_rev)."
    else ok "Updated $target_dir ($before_rev -> $after_rev)."; fi
  }

  safe_rm_clone_dir() {
    local target_dir="$1" real_target="" base status_all=""
    real_target="$(canon_dir "$target_dir" || true)"
    [ -n "$real_target" ] && [ "$real_target" != "/" ] && [ "$real_target" != "$HOME" ] || die "Invalid target directory: $target_dir" 1
    base="$(basename -- "$real_target")"
    [ "$base" = ".agents" ] || [ "$base" = "antigravity-skills" ] || die "Safety guard blocked removal of unexpected directory: $real_target" 1
    is_our_repo_clone "$real_target" || die "Refusing to delete $real_target: not verified as an antigravity-skills clone." 1
    status_all="$(git -C "$real_target" status --porcelain 2>/dev/null || true)"
    if [ -n "$status_all" ] && [ "$FORCE" -eq 0 ]; then
      err "Uncommitted or untracked files exist inside $real_target:"; printf "%s\n" "$status_all" >&2
      die "Move/commit custom files first, or pass --force to delete anyway." 1
    fi
    [ "$DRY_RUN" -eq 1 ] && { info "[DRY-RUN] Would remove directory: $real_target"; return 0; }
    prompt_confirm "Permanently remove $real_target?" || { warn "Uninstall cancelled."; return 0; }
    rm -rf -- "$real_target"
    ok "Removed $real_target."
  }

  run_for_scope() {
    local cur_scope="$1" target_dir="" want_full=0
    [ "$EXPLICIT_BASE" = "all" ] && want_full=1
    if [ "$AGENT" = "antigravity" ]; then
      if [ "$cur_scope" = "local" ]; then
        if [ "$(basename -- "$PROJECT_DIR")" = ".agents" ] && is_our_repo_clone "$PROJECT_DIR"; then target_dir="$PROJECT_DIR"
        elif is_our_repo_clone "$PROJECT_DIR" && [ "$EXPLICIT_DIR" -eq 0 ]; then
          die "Current directory ($PROJECT_DIR) is already an antigravity-skills source repository. Use '--global' or '--local --dir /path/to/your-project'." 2
        else target_dir="${PROJECT_DIR}/.agents"; fi
      else
        target_dir="${HOME}/.gemini/config/plugins/antigravity-skills"
      fi

      if [ "$ACTION" = "uninstall" ]; then
        [ -e "$target_dir" ] || { warn "Nothing installed at $target_dir."; return 0; }
        if is_our_repo_clone "$target_dir"; then
          [ -z "$REQ_SKILLS_CSV" ] || die "$target_dir is a full Git clone. Run --uninstall without --skill to remove the clone first." 1
          safe_rm_clone_dir "$target_dir"; return 0
        fi
        [ -f "$target_dir/$MANIFEST_NAME" ] || die "Target $target_dir was not installed by antigravity-skills (no matching git origin or manifest)." 1
        uninstall_manifest_target "$target_dir" "$REQ_SKILLS_CSV"; return 0
      fi

      if is_our_repo_clone "$target_dir"; then
        if { [ -n "$EXPLICIT_BASE" ] && [ "$EXPLICIT_BASE" != "all" ]; } || [ -n "$REQ_ROLES_CSV" ] || [ -n "$REQ_SKILLS_CSV" ]; then
          warn "$target_dir is a full Git clone (all 532 skills already present); fast-forwarding clone. (Run --uninstall first if you want a slim selective install.)"
        fi
        info "Existing antigravity-skills Git clone detected at $target_dir — updating..."
        git_update_clone "$target_dir"
        return 0
      fi
    elif [ "$AGENT" = "copilot" ]; then
      if [ "$cur_scope" = "local" ]; then target_dir="${PROJECT_DIR}/.github"; else target_dir="${HOME}/.copilot"; fi
      if [ "$ACTION" = "uninstall" ]; then
        [ -f "$target_dir/$MANIFEST_NAME" ] || { warn "No managed GitHub Copilot installation manifest found at $target_dir."; return 0; }
        uninstall_manifest_target "$target_dir" "$REQ_SKILLS_CSV"; return 0
      fi
    else
      if [ "$cur_scope" = "local" ]; then target_dir="${PROJECT_DIR}/.claude"; else target_dir="${HOME}/.claude"; fi
      if [ "$ACTION" = "uninstall" ]; then
        [ -f "$target_dir/$MANIFEST_NAME" ] || { warn "No managed Claude Code installation manifest found at $target_dir."; return 0; }
        uninstall_manifest_target "$target_dir" "$REQ_SKILLS_CSV"; return 0
      fi
    fi

    if [ "$ACTION" = "update" ] && [ ! -f "$target_dir/$MANIFEST_NAME" ]; then
      die "No existing $AGENT installation manifest found at $target_dir. Run without --update to install." 1
    fi
    stage_repo_trees "$want_full"
    run_py_engine "sync" "$TMP_DIR/repo" "$target_dir" "$MANIFEST_NAME" "$AGENT" "$cur_scope" \
      "$EXPLICIT_BASE" "$REQ_ROLES_CSV" "$REQ_SKILLS_CSV" "$LOCAL_PROFILES_FALLBACK" "$DRY_RUN" "$FORCE"
    if [ "$AGENT" = "antigravity" ]; then
      ok "Antigravity customization ready at $target_dir"
      [ "$DRY_RUN" -eq 0 ] && [ "$cur_scope" = "local" ] && [ -d "${PROJECT_DIR}/.git" ] && \
        info "Tip: Add '.agents/' to ${PROJECT_DIR}/.gitignore (or .git/info/exclude) if you want to keep it untracked in your app repo."
      [ "$cur_scope" = "local" ] && [ -d "${HOME}/.gemini/config/plugins/antigravity-skills" ] && \
        info "Note: Global plugin (~/.gemini/config/plugins/antigravity-skills) is also installed; workspace ./.agents takes precedence here."
      [ "$cur_scope" = "global" ] && [ -d "${PROJECT_DIR}/.agents/skills" ] && [ "$PROJECT_DIR" != "$target_dir" ] && \
        info "Note: Current directory also has ./.agents/skills, which overrides global skills inside $PROJECT_DIR."
    elif [ "$AGENT" = "copilot" ]; then
      if [ "$cur_scope" = "local" ]; then
        ok "GitHub Copilot customization ready in $target_dir/{skills,instructions,agents}"
        [ "$DRY_RUN" -eq 0 ] && [ -d "${PROJECT_DIR}/.git" ] && \
          info "Tip: Commit .github/{skills,instructions,agents} to enable GitHub Copilot Cloud Coding Agent on GitHub.com (you may add .github/.antigravity-skills.manifest to .gitignore)."
      else
        ok "GitHub Copilot personal skills ready in $target_dir/skills"
      fi
    else
      ok "Claude Code skills ready in $target_dir/skills"
    fi
    return 0
  }

  if [ "$SCOPE" = "both" ]; then run_for_scope "local"; run_for_scope "global"; else run_for_scope "$SCOPE"; fi
}

main "$@"
