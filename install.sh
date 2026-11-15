#!/usr/bin/env bash
# antigravity-skills — Selective Installer, Updater & Uninstaller
# Modes: --minimal (default) | --skill <name> | --role <role> | --all
# Repo:  https://github.com/Mynul-Sakil/antigravity-skills

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
                          (Antigravity: ./.agents | Claude Code: ./.claude/skills)
  --global                Install or update globally across all projects
                          (Antigravity: ~/.gemini/config/plugins/antigravity-skills
                           Claude Code: ~/.claude/skills)
  --claude                Target Claude Code instead of Antigravity
  --dir <path>            Override target project directory (implies --local if scope omitted)

Install Mode Options (Default on fresh install: --minimal):
  --minimal               Install curated core pack (17 skills, 8 subagents, 8 rules) [DEFAULT]
  --all                   Install full catalog (526 skills, 25 subagents, 100 rules)
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
  ./install.sh --local --all                        # Install all 526 skills in ./.agents
  ./install.sh --local --skill stock-analysis       # Install ONLY 'stock-analysis' skill
  ./install.sh --global --role fullstack            # Install 'fullstack' role pack globally
  ./install.sh --claude --local --skill seo-audit   # Install 'seo-audit' in ./.claude/skills
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
      --claude) AGENT="claude"; EXPLICIT_AGENT=1; shift ;;
      --antigravity) AGENT="antigravity"; EXPLICIT_AGENT=1; shift ;;
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

  local CLONE_URL LOCAL_PROFILES_FALLBACK=""
  CLONE_URL="$(normalize_repo_url "$REPO_URL")"
  if [ -d "$REPO_URL" ] && [ -f "$REPO_URL/profiles.json" ]; then
    LOCAL_PROFILES_FALLBACK="$(canon_dir "$REPO_URL")/profiles.json"
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

  # Unified Python engine for list, sparse-sync, and selective/full manifest uninstall
  run_py_engine() {
    "$PYTHON_BIN" - "$@" <<'PYEOF'
import difflib, hashlib, json, os, shutil, subprocess, sys, time
from pathlib import Path

cmd = sys.argv[1]

def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def load_profiles(repo_dir: str, fallback_prof: str):
    res = subprocess.run(["git", "-C", repo_dir, "show", "HEAD:profiles.json"], capture_output=True, text=True)
    if res.returncode == 0:
        return json.loads(res.stdout)
    if fallback_prof and Path(fallback_prof).is_file():
        return json.loads(Path(fallback_prof).read_text(encoding="utf-8"))
    return None

def is_clean_rel(rel: str) -> bool:
    if not rel or rel.startswith("/") or "\\" in rel:
        return False
    p = Path(rel)
    return (not p.is_absolute()) and (".." not in p.parts) and ("." not in p.parts)

def safe_target_path(dst_root: Path, rel: str) -> Path:
    if not is_clean_rel(rel):
        sys.exit(f"[ERR]  Invalid relative path in manifest: '{rel}'")
    if dst_root.is_symlink():
        sys.exit(f"[ERR]  Refusing to operate on symlinked root '{dst_root}'.")
    cur = dst_root
    for part in Path(rel).parts[:-1]:
        cur = cur / part
        if cur.is_symlink():
            sys.exit(f"[ERR]  Refusing to traverse symlinked directory '{cur}'. Manage the target directory directly instead.")
    p = dst_root / rel
    dst_real = os.path.realpath(str(dst_root))
    parent_real = os.path.realpath(str(p.parent)) if p.parent.exists() else dst_real
    if os.path.commonpath([dst_real, parent_real]) != dst_real:
        sys.exit(f"[ERR]  Path containment check blocked '{rel}'")
    return p

def load_manifest(manifest_path: Path):
    state, entries = {"base": "none", "roles": [], "skills": [], "excluded": []}, {}
    if manifest_path.is_symlink():
        sys.exit(f"[ERR]  Refusing to read symlinked manifest '{manifest_path}'")
    if not manifest_path.is_file():
        return False, state, entries
    state = {"base": "all", "roles": [], "skills": [], "excluded": []}
    for idx, ln in enumerate(manifest_path.read_text(encoding="utf-8").splitlines()):
        if idx == 0 and ln.startswith("# @state "):
            try:
                p = json.loads(ln[len("# @state "):])
                state = {"base": p.get("base", "minimal"), "roles": list(p.get("roles", [])),
                         "skills": list(p.get("skills", [])), "excluded": list(p.get("excluded", []))}
            except Exception:
                pass
        elif not ln.startswith("#") and "  " in ln:
            h, rel = ln.split("  ", 1)
            rel_s = rel.strip()
            if not is_clean_rel(rel_s):
                sys.exit(f"[ERR]  Corrupted or unsafe path in {manifest_path}: '{rel_s}'")
            entries[rel_s] = h.strip()
    return True, state, entries

def save_manifest(manifest_path: Path, dst_root: Path, state: dict, entries: dict):
    dst_root.mkdir(parents=True, exist_ok=True)
    clean_state = {"base": state["base"], "roles": state["roles"], "skills": state["skills"]}
    if state.get("excluded"):
        clean_state["excluded"] = sorted(set(state["excluded"]))
    header = "# @state " + json.dumps(clean_state, separators=(",", ":"))
    body = [f"{h}  {r}" for r, h in sorted(entries.items())]
    manifest_path.write_text("\n".join([header] + body) + "\n", encoding="utf-8")

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

if cmd == "list":
    repo_dir, mode, fallback_prof = sys.argv[2:5]
    if mode == "skills":
        out = subprocess.check_output(["git", "-C", repo_dir, "ls-tree", "-r", "--name-only", "HEAD"], text=True)
        skills = sorted({p.split("/")[1] for p in out.splitlines() if p.startswith("skills/") and p.endswith("/SKILL.md") and p.count("/") == 2})
        print(f"Available skills ({len(skills)}):")
        for s in skills:
            print(f"  {s}")
    else:
        data = load_profiles(repo_dir, fallback_prof)
        if not data:
            sys.exit("[ERR]  profiles.json not found in repository.")
        m = data["minimal"]
        print(f"Default Profile:\n  {'minimal':<12} ({len(m['skills']):>2} skills, {len(m['agents']):>2} agents, {len(m['rules']):>2} rules) - {m['description']}\n")
        print("Available --role Packs:")
        for rname, r in data["roles"].items():
            print(f"  {rname:<12} ({len(r['skills']):>2} skills, {len(r['agents']):>2} agents, {len(r['rules']):>2} rules) - {r['description']}")
        if data.get("aliases"):
            print("\nAliases: " + ", ".join(f"{k} -> {v}" for k, v in data["aliases"].items()))

elif cmd == "sync":
    (repo_dir, dst_raw, manifest_name, agent, cur_scope,
     explicit_base, roles_csv, skills_csv, fallback_prof, dry_s, force_s) = sys.argv[2:13]
    dry_run, force = (dry_s == "1"), (force_s == "1")
    src_root, dst_root = Path(repo_dir), Path(dst_raw)
    manifest_path = dst_root / manifest_name

    tree_out = subprocess.check_output(["git", "-C", repo_dir, "ls-tree", "-r", "--name-only", "HEAD"], text=True)
    tree_files = [p for p in tree_out.splitlines() if p and "__pycache__" not in p and not p.endswith((".pyc", ".DS_Store"))]
    all_skills = sorted({p.split("/")[1] for p in tree_files if p.startswith("skills/") and p.endswith("/SKILL.md") and p.count("/") == 2})
    all_skill_set = set(all_skills)
    prof_data = load_profiles(repo_dir, fallback_prof)

    cli_roles = [r.strip() for r in roles_csv.split(",") if r.strip()]
    cli_skills = [s.strip() for s in skills_csv.split(",") if s.strip()]

    if cli_roles:
        if not prof_data:
            sys.exit("[ERR]  profiles.json not found in repository.")
        aliases, valid_roles = prof_data.get("aliases", {}), prof_data.get("roles", {})
        resolved = []
        for r in cli_roles:
            tr = aliases.get(r, r)
            if tr not in valid_roles:
                sys.stderr.write(f"[ERR]  Unknown role '{r}'. Available roles: {', '.join(valid_roles)}\n")
                sys.exit(2)
            resolved.append(tr)
        cli_roles = resolved

    for s in cli_skills:
        if s not in all_skill_set:
            close = difflib.get_close_matches(s, all_skills, n=5, cutoff=0.45)
            subs = [k for k in all_skills if s.lower() in k.lower() and k not in close][:3]
            hints = (close + subs)[:5]
            msg = f" Did you mean: {', '.join(hints)}?" if hints else " Run with --list-skills to browse."
            sys.stderr.write(f"[ERR]  Skill '{s}' not found.{msg}\n")
            sys.exit(2)

    has_existing, old_state, old_manifest = load_manifest(manifest_path)
    old_excl = set(old_state.get("excluded", [])) - set(cli_skills)
    if explicit_base == "all":
        new_state, sync_mode = {"base": "all", "roles": [], "skills": [], "excluded": []}, "RECONCILE"
    elif explicit_base == "minimal":
        new_state, sync_mode = {"base": "minimal", "roles": sorted(set(cli_roles)), "skills": sorted(set(cli_skills)), "excluded": []}, "RECONCILE"
    elif cli_roles or cli_skills:
        sync_mode = "ADDITIVE"
        if old_state["base"] == "all":
            new_state = {"base": "all", "roles": [], "skills": [], "excluded": sorted(old_excl)}
        else:
            new_state = {"base": old_state["base"], "roles": sorted(set(old_state["roles"]) | set(cli_roles)),
                         "skills": sorted(set(old_state["skills"]) | set(cli_skills)), "excluded": sorted(old_excl)}
    else:
        sync_mode = "RECONCILE"
        new_state = old_state if has_existing else {"base": "minimal", "roles": [], "skills": [], "excluded": []}

    if (new_state["base"] == "minimal" or new_state["roles"]) and not prof_data:
        sys.exit("[ERR]  profiles.json is required to resolve minimal/role bundles.")

    excl_set = set(new_state.get("excluded", []))
    def collect(st):
        if st["base"] == "all":
            if excl_set:
                return sorted(all_skill_set - excl_set), "ALL", "ALL"
            return None, None, None
        sk, ag, rl = set(st["skills"]), set(), set()
        if st["base"] == "minimal":
            m = prof_data["minimal"]
            sk.update(m["skills"]); ag.update(m["agents"]); rl.update(m["rules"])
        for r in st["roles"]:
            rb = prof_data["roles"][r]
            sk.update(rb["skills"]); ag.update(rb["agents"]); rl.update(rb["rules"])
        sk -= excl_set
        return sorted(sk), sorted(ag), sorted(rl)

    f_state = {"base": "none", "roles": sorted(set(cli_roles)), "skills": sorted(set(cli_skills)), "excluded": []} if sync_mode == "ADDITIVE" else new_state
    f_sk, f_ag, f_rl = collect(f_state)

    patterns, synced_prefixes, wanted_set = [], [], set()
    if agent == "antigravity" and cur_scope == "global" and "plugin.json" in tree_files:
        patterns.append("/plugin.json"); synced_prefixes.append("plugin.json"); wanted_set.add("plugin.json")

    if f_sk is None:
        patterns.append("/skills/"); synced_prefixes.append("skills/")
        if agent == "antigravity":
            patterns.extend(["/agents/", "/rules/"]); synced_prefixes.extend(["agents/", "rules/"])
        for tf in tree_files:
            if tf.startswith("skills/") or (agent == "antigravity" and tf.startswith(("agents/", "rules/"))):
                wanted_set.add(tf)
    else:
        sk_pfx = tuple(f"skills/{s}/" for s in f_sk)
        for s in f_sk:
            patterns.append(f"/skills/{s}/"); synced_prefixes.append(f"skills/{s}/")
        for tf in tree_files:
            if sk_pfx and tf.startswith(sk_pfx):
                wanted_set.add(tf)
        if agent == "antigravity":
            if f_ag == "ALL":
                patterns.extend(["/agents/", "/rules/"]); synced_prefixes.extend(["agents/", "rules/"])
                wanted_set.update(tf for tf in tree_files if tf.startswith(("agents/", "rules/")))
            else:
                for a in f_ag:
                    ra = f"agents/{a}"
                    if ra in tree_files:
                        patterns.append(f"/{ra}"); synced_prefixes.append(ra); wanted_set.add(ra)
                for r in f_rl:
                    rr = f"rules/{r}"
                    if rr in tree_files:
                        patterns.append(f"/{rr}"); synced_prefixes.append(rr); wanted_set.add(rr)

    parts = []
    if sync_mode == "ADDITIVE":
        if cli_roles: parts.append("role=" + ",".join(cli_roles))
        if cli_skills: parts.append("skill=" + ",".join(cli_skills))
        label = "additive (" + " + ".join(parts) + ")"
    else:
        if new_state["base"] != "none": parts.append(new_state["base"])
        if new_state["roles"]: parts.append("role=" + ",".join(new_state["roles"]))
        if new_state["skills"]: parts.append("skill=" + ",".join(new_state["skills"]))
        label = " + ".join(parts) if parts else "custom"
    print(f"[INFO] Syncing {agent} ({cur_scope}) [mode: {label}] -> {dst_root}")

    if patterns:
        git_env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
        if f_sk is None:
            is_prom = subprocess.run(["git", "-C", repo_dir, "config", "--bool", "remote.origin.promisor"],
                                     capture_output=True, text=True).stdout.strip() == "true"
            if is_prom and subprocess.run(["git", "-C", repo_dir, "fetch", "--quiet", "--refetch", "origin", "HEAD"], check=False, env=git_env, capture_output=True).returncode == 0:
                subprocess.run(["git", "-C", repo_dir, "config", "--unset", "remote.origin.promisor"], check=False)
                subprocess.run(["git", "-C", repo_dir, "config", "--unset", "remote.origin.partialclonefilter"], check=False)
        has_sparse = subprocess.run(["git", "-C", repo_dir, "sparse-checkout", "-h"], capture_output=True).returncode == 0
        if has_sparse:
            subprocess.run(["git", "-C", repo_dir, "sparse-checkout", "init", "--no-cone"], check=True, env=git_env, capture_output=True)
            subprocess.run(["git", "-C", repo_dir, "sparse-checkout", "set", "--no-cone", "--stdin"],
                           input="\n".join(patterns) + "\n", text=True, check=True, env=git_env, capture_output=True)
            subprocess.run(["git", "-C", repo_dir, "checkout", "--quiet", "-f", "HEAD"], check=True, env=git_env, capture_output=True)
        else:
            clean_p = [p.lstrip("/").rstrip("/") for p in patterns]
            subprocess.run(["git", "-C", repo_dir, "checkout", "--quiet", "HEAD", "--", *clean_p], check=True, env=git_env, capture_output=True)

    backup_root = dst_root / ".backups" / time.strftime("%Y%m%d-%H%M%S")
    added = updated = unchanged = preserved = pruned = 0
    new_manifest = {}

    for rel in sorted(wanted_set):
        sf = src_root / rel
        if sf.is_symlink() or not sf.is_file():
            sys.exit(f"[ERR]  Expected sparse-checkout file missing or symlinked: {rel}")
        s_hash = sha256(sf)
        df = safe_target_path(dst_root, rel)
        if df.is_symlink():
            preserved += 1
            continue
        if not df.exists():
            added += 1; new_manifest[rel] = s_hash
            if not dry_run:
                df.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(sf, df)
        else:
            d_hash = sha256(df)
            if d_hash == s_hash:
                unchanged += 1; new_manifest[rel] = s_hash
            elif rel in old_manifest and old_manifest[rel] == d_hash:
                updated += 1; new_manifest[rel] = s_hash
                if not dry_run: shutil.copy2(sf, df)
            elif force:
                updated += 1; new_manifest[rel] = s_hash
                if not dry_run:
                    bf = backup_root / rel
                    bf.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(df, bf); shutil.copy2(sf, df)
            else:
                preserved += 1
                if rel in old_manifest: new_manifest[rel] = old_manifest[rel]

    for rel, old_hash in sorted(old_manifest.items()):
        if rel in wanted_set:
            continue
        in_scope = (sync_mode == "RECONCILE") or any(
            (rel.startswith(p) if p.endswith("/") else rel == p) for p in synced_prefixes
        )
        df = safe_target_path(dst_root, rel)
        if not in_scope:
            if not df.is_symlink() and df.is_file():
                new_manifest[rel] = old_hash
            continue
        if not df.is_symlink() and df.is_file():
            if sha256(df) == old_hash:
                pruned += 1
                if not dry_run:
                    df.unlink(); prune_empty_parents(df, dst_root)
            else:
                preserved += 1

    if not dry_run:
        save_manifest(manifest_path, dst_root, new_state, new_manifest)
    sk_cnt = len({r.split("/")[1] for r in new_manifest if r.startswith("skills/") and r.count("/") >= 2})
    pfx = "[DRY-RUN] " if dry_run else ""
    print(f"{pfx}Sync summary -> active skills: {sk_cnt} | added: {added}, updated: {updated}, unchanged: {unchanged}, preserved custom: {preserved}, pruned: {pruned}")

elif cmd == "uninstall":
    dst_root, manifest_name = Path(sys.argv[2]), sys.argv[3]
    dry_run, force = (sys.argv[4] == "1"), (sys.argv[5] == "1")
    target_skills = [s.strip() for s in sys.argv[6].split(",") if s.strip()]
    manifest_path = dst_root / manifest_name
    _, state, entries = load_manifest(manifest_path)

    if target_skills:
        present = {r.split("/")[1] for r in entries if r.startswith("skills/") and r.count("/") >= 2}
        missing = [s for s in target_skills if s not in present]
        if missing:
            sys.stderr.write(f"[WARN] Skill(s) not installed in {dst_root}: {', '.join(missing)}\n")

    removed = preserved = 0
    kept = {}
    for rel, old_hash in sorted(entries.items()):
        remove_it = (not target_skills) or any(rel.startswith(f"skills/{s}/") for s in target_skills)
        if not remove_it:
            kept[rel] = old_hash
            continue
        df = safe_target_path(dst_root, rel)
        if df.is_symlink() or not df.is_file():
            continue
        if force or sha256(df) == old_hash:
            removed += 1
            if not dry_run:
                df.unlink(); prune_empty_parents(df, dst_root)
        else:
            preserved += 1

    if target_skills:
        explicit_sk = set(state.get("skills", []))
        excl = set(state.get("excluded", []))
        for s in target_skills:
            if s in explicit_sk:
                explicit_sk.discard(s)
            elif state.get("base") != "none" or state.get("roles"):
                excl.add(s)
        state["skills"] = sorted(explicit_sk)
        state["excluded"] = sorted(excl)
        if not [r for r in kept if r != "plugin.json"] and "plugin.json" in kept:
            pf = safe_target_path(dst_root, "plugin.json")
            if not pf.is_symlink() and pf.is_file() and (force or sha256(pf) == kept["plugin.json"]):
                removed += 1
                if not dry_run: pf.unlink()
            kept.pop("plugin.json", None)

    if not dry_run:
        if kept:
            save_manifest(manifest_path, dst_root, state, kept)
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
    printf "\n%bAntigravity Skills — Step 1/2: Choose Target Location%b\n" "$C_BOLD" "$C_RESET" >/dev/tty
    printf "  1) Antigravity — Current Directory (%s/.agents)\n" "$PROJECT_DIR" >/dev/tty
    printf "  2) Antigravity — Global Plugin     (%s/.gemini/config/plugins/antigravity-skills)\n" "$HOME" >/dev/tty
    printf "  3) Claude Code — Current Directory (%s/.claude/skills)\n" "$PROJECT_DIR" >/dev/tty
    printf "  4) Claude Code — Global            (%s/.claude/skills)\n" "$HOME" >/dev/tty
    printf "\nSelect target [1-4] (default: %s): " "$def_target" >/dev/tty
    local choice=""
    read -r choice </dev/tty || true
    case "${choice:-$def_target}" in
      1) AGENT="antigravity"; SCOPE="local" ;;
      2) AGENT="antigravity"; SCOPE="global" ;;
      3) AGENT="claude";      SCOPE="local" ;;
      4) AGENT="claude";      SCOPE="global" ;;
      *) die "Invalid selection: $choice" 2 ;;
    esac

    if [ "$ACTION" = "auto" ] && [ -z "$EXPLICIT_BASE" ] && [ -z "$REQ_ROLES_CSV" ] && [ -z "$REQ_SKILLS_CSV" ]; then
      printf "\n%bAntigravity Skills — Step 2/2: Choose Install Mode%b\n" "$C_BOLD" "$C_RESET" >/dev/tty
      printf "  1) Minimal  — Essential core (17 skills, 8 subagents, 8 rules) [default]\n" >/dev/tty
      printf "  2) All      — Full library   (526 skills, 25 subagents, 100 rules)\n" >/dev/tty
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
    run_py_engine "uninstall" "$target_root" "$MANIFEST_NAME" "$DRY_RUN" "$FORCE" "$skills_only_csv"
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
          warn "$target_dir is a full Git clone (all 526 skills already present); fast-forwarding clone. (Run --uninstall first if you want a slim selective install.)"
        fi
        info "Existing antigravity-skills Git clone detected at $target_dir — updating..."
        git_update_clone "$target_dir"
        return 0
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
    else
      ok "Claude Code skills ready in $target_dir/skills"
    fi
    return 0
  }

  if [ "$SCOPE" = "both" ]; then run_for_scope "local"; run_for_scope "global"; else run_for_scope "$SCOPE"; fi
}

main "$@"
