#!/usr/bin/env bash
# ==============================================================================
# antigravity-skills — Smart Installer, Updater & Uninstaller
# Repository: https://github.com/Mynul-Sakil/antigravity-skills
#
# Supports:
#   - Antigravity Workspace (Current Directory: ./.agents)
#   - Antigravity Global Plugin (~/.gemini/config/plugins/antigravity-skills)
#   - Claude Code Workspace (Current Directory: ./.claude/skills)
#   - Claude Code Global (~/.claude/skills)
#   - Automatic install-or-update detection, non-destructive merges, & uninstall
# ==============================================================================

if [ -z "${BASH_VERSION:-}" ]; then
  echo "[ERR] Please run this script with bash (e.g., 'bash install.sh')." >&2
  exit 1
fi

set -euo pipefail

main() {
  local REPO_URL="${ANTIGRAVITY_SKILLS_REPO:-https://github.com/Mynul-Sakil/antigravity-skills.git}"
  local BRANCH="${ANTIGRAVITY_SKILLS_BRANCH:-main}"
  local MANIFEST_NAME=".antigravity-skills.manifest"

  local AGENT="antigravity"
  local SCOPE=""
  local ACTION="auto"
  local PROJECT_DIR="$PWD"
  local EXPLICIT_DIR=0
  local DRY_RUN=0
  local FORCE=0
  local ASSUME_YES=0

  local TMP_DIR=""
  cleanup() {
    if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
      rm -rf -- "$TMP_DIR"
    fi
  }
  trap cleanup EXIT INT TERM HUP

  # Colors (disabled when stdout is not a terminal)
  local C_GREEN="" C_BLUE="" C_YELLOW="" C_RED="" C_BOLD="" C_RESET=""
  if [ -t 1 ]; then
    C_GREEN='\033[0;32m'
    C_BLUE='\033[0;34m'
    C_YELLOW='\033[1;33m'
    C_RED='\033[0;31m'
    C_BOLD='\033[1m'
    C_RESET='\033[0m'
  fi

  info() { printf "%b[INFO]%b %s\n" "$C_BLUE" "$C_RESET" "$*"; }
  ok()   { printf "%b[OK]%b   %s\n" "$C_GREEN" "$C_RESET" "$*"; }
  warn() { printf "%b[WARN]%b %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2; }
  err()  { printf "%b[ERR]%b  %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
  die()  { err "$1"; exit "${2:-1}"; }

  usage() {
    cat <<'EOF'
Antigravity Skills — Installer, Updater & Uninstaller

Usage:
  ./install.sh [options]
  curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- [options]

Target Scope Options:
  --local, --workspace    Install or update in current/project directory
                          (Antigravity: ./.agents | Claude Code: ./.claude)
  --global                Install or update globally across all projects
                          (Antigravity: ~/.gemini/config/plugins/antigravity-skills
                           Claude Code: ~/.claude)
  --claude                Target Claude Code instead of Antigravity
  --dir <path>            Override target project directory (implies --local if scope omitted)

Action Options:
  --update                Update an existing installation in place
  --uninstall             Safely remove installed files (preserves custom user files)
  --force                 Back up conflicting modified files to .backups/ and overwrite
  --yes, -y               Skip interactive confirmation prompts (for --uninstall)
  --dry-run               Preview planned actions without modifying any files
  --help, -h              Show this help message

Environment Overrides:
  ANTIGRAVITY_SKILLS_REPO    Override Git repository URL or local path
  ANTIGRAVITY_SKILLS_BRANCH  Override Git branch (default: main)

Examples:
  ./install.sh                            # Interactive menu (asks Current Dir vs Global)
  ./install.sh --local                    # Install or update ./.agents in current directory
  ./install.sh --global                   # Install or update global Antigravity plugin
  ./install.sh --update                   # Auto-detect and update installed scope(s)
  ./install.sh --claude --local           # Install or update skills in ./.claude/skills
  ./install.sh --claude --global          # Install or update skills in ~/.claude/skills
  ./install.sh --global --uninstall       # Uninstall global Antigravity plugin
EOF
  }

  canon_dir() {
    (cd "$1" 2>/dev/null && pwd -P)
  }

  has_tty() {
    (: </dev/tty) 2>/dev/null
  }

  prompt_confirm() {
    local msg="$1"
    if [ "$ASSUME_YES" -eq 1 ]; then
      return 0
    fi
    if ! has_tty; then
      die "Confirmation required in non-interactive session. Re-run with --yes." 2
    fi
    local reply=""
    printf "%s [y/N]: " "$msg" >/dev/tty
    read -r reply </dev/tty || true
    case "$reply" in
      y|Y|yes|YES) return 0 ;;
      *) return 1 ;;
    esac
  }

  normalize_repo_url() {
    local raw="$1"
    if [ -d "$raw" ]; then
      printf "file://%s" "$(canon_dir "$raw")"
    else
      printf "%s" "$raw"
    fi
  }

  is_our_repo_clone() {
    local dir="$1"
    [ -d "$dir" ] || return 1
    [ -d "$dir/.git" ] || return 1

    local real_dir top origin_url norm_repo
    real_dir="$(canon_dir "$dir" || true)"
    [ -n "$real_dir" ] || return 1

    top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
    [ "$top" = "$real_dir" ] || return 1

    origin_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
    norm_repo="$(normalize_repo_url "$REPO_URL")"

    case "$origin_url" in
      *antigravity-skills*|"$REPO_URL"|"$norm_repo")
        return 0
        ;;
      *)
        if [ -d "$REPO_URL" ] && [ "$origin_url" = "$(canon_dir "$REPO_URL")" ]; then
          return 0
        fi
        return 1
        ;;
    esac
  }

  # Parse CLI arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --local|--workspace)
        if [ "$SCOPE" = "global" ]; then
          die "Cannot combine --local and --global." 2
        fi
        SCOPE="local"
        shift
        ;;
      --global)
        if [ "$SCOPE" = "local" ]; then
          die "Cannot combine --local and --global." 2
        fi
        SCOPE="global"
        shift
        ;;
      --claude)
        AGENT="claude"
        shift
        ;;
      --antigravity)
        AGENT="antigravity"
        shift
        ;;
      --dir|--project-dir)
        [ $# -ge 2 ] || die "Missing path argument for $1" 2
        PROJECT_DIR="$2"
        EXPLICIT_DIR=1
        shift 2
        ;;
      --update)
        ACTION="update"
        shift
        ;;
      --uninstall)
        ACTION="uninstall"
        shift
        ;;
      --force)
        FORCE=1
        shift
        ;;
      --yes|-y)
        ASSUME_YES=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        err "Unknown option: $1"
        usage >&2
        exit 2
        ;;
    esac
  done

  if [ "$EXPLICIT_DIR" -eq 1 ] && [ -z "$SCOPE" ]; then
    SCOPE="local"
  fi

  command -v git >/dev/null 2>&1 || die "'git' is required. Please install git first." 1

  # Resolve PROJECT_DIR if local
  if [ "$EXPLICIT_DIR" -eq 1 ]; then
    if [ ! -d "$PROJECT_DIR" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        info "[DRY-RUN] Would create project directory: $PROJECT_DIR"
      else
        mkdir -p "$PROJECT_DIR"
      fi
    fi
    if [ -d "$PROJECT_DIR" ]; then
      PROJECT_DIR="$(canon_dir "$PROJECT_DIR")"
    fi
  else
    PROJECT_DIR="$(canon_dir "$PROJECT_DIR")"
  fi

  local CLONE_URL
  CLONE_URL="$(normalize_repo_url "$REPO_URL")"

  # Auto-detect scope on --update when no scope flag was provided
  if [ -z "$SCOPE" ] && [ "$ACTION" = "update" ]; then
    local has_local=0 has_global=0
    if [ "$AGENT" = "antigravity" ]; then
      if [ "$(basename "$PROJECT_DIR")" = ".agents" ] && is_our_repo_clone "$PROJECT_DIR"; then
        has_local=1
      elif is_our_repo_clone "$PROJECT_DIR/.agents" || [ -f "$PROJECT_DIR/.agents/$MANIFEST_NAME" ]; then
        has_local=1
      fi
      if is_our_repo_clone "${HOME}/.gemini/config/plugins/antigravity-skills" || [ -f "${HOME}/.gemini/config/plugins/antigravity-skills/$MANIFEST_NAME" ]; then
        has_global=1
      fi
    else
      [ -f "$PROJECT_DIR/.claude/$MANIFEST_NAME" ] && has_local=1
      [ -f "${HOME}/.claude/$MANIFEST_NAME" ] && has_global=1
    fi

    if [ "$has_local" -eq 1 ] && [ "$has_global" -eq 0 ]; then
      SCOPE="local"
    elif [ "$has_global" -eq 1 ] && [ "$has_local" -eq 0 ]; then
      SCOPE="global"
    elif [ "$has_local" -eq 1 ] && [ "$has_global" -eq 1 ]; then
      SCOPE="both"
    else
      die "No existing $AGENT installation detected to update. Run without --update (or pass --local / --global) to install." 1
    fi
  fi

  # Interactive target selection if scope is still unset
  if [ -z "$SCOPE" ]; then
    if ! has_tty; then
      die "Non-interactive session detected without a scope flag. Pass --local or --global (e.g., curl -fsSL .../install.sh | bash -s -- --local)." 2
    fi

    printf "\n%bAntigravity Skills — Choose Target Location%b\n" "$C_BOLD" "$C_RESET" >/dev/tty
    printf "  1) Antigravity — Current Directory (%s/.agents)\n" "$PROJECT_DIR" >/dev/tty
    printf "  2) Antigravity — Global Plugin     (%s/.gemini/config/plugins/antigravity-skills)\n" "$HOME" >/dev/tty
    printf "  3) Claude Code — Current Directory (%s/.claude/skills)\n" "$PROJECT_DIR" >/dev/tty
    printf "  4) Claude Code — Global            (%s/.claude/skills)\n" "$HOME" >/dev/tty
    printf "\nSelect option [1-4] (default: 1): " >/dev/tty
    local choice=""
    read -r choice </dev/tty || true
    choice="${choice:-1}"
    case "$choice" in
      1) AGENT="antigravity"; SCOPE="local" ;;
      2) AGENT="antigravity"; SCOPE="global" ;;
      3) AGENT="claude";      SCOPE="local" ;;
      4) AGENT="claude";      SCOPE="global" ;;
      *) die "Invalid selection: $choice" 2 ;;
    esac
  fi

  stage_temp_repo() {
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR/repo" ]; then
      return 0
    fi
    TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'antigravity-skills')"
    info "Fetching latest package from ${REPO_URL} (${BRANCH})..."
    GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --branch "$BRANCH" "$CLONE_URL" "$TMP_DIR/repo"
  }

  # Manifest-driven non-destructive sync (used for pre-existing .agents/ and all .claude/ installs)
  sync_with_manifest() {
    local target_root="$1"
    local subdirs_csv="$2"

    stage_temp_repo

    if command -v python3 >/dev/null 2>&1; then
      python3 - "$TMP_DIR/repo" "$target_root" "$subdirs_csv" "$MANIFEST_NAME" "$DRY_RUN" "$FORCE" <<'PYEOF'
import hashlib
import os
import shutil
import sys
import time
from pathlib import Path

src_root = Path(sys.argv[1])
dst_root = Path(sys.argv[2])
subdirs = [s.strip() for s in sys.argv[3].split(",") if s.strip()]
manifest_name = sys.argv[4]
dry_run = sys.argv[5] == "1"
force = sys.argv[6] == "1"

manifest_path = dst_root / manifest_name
old_manifest = {}
if manifest_path.is_file():
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        if "  " in line:
            h, rel = line.split("  ", 1)
            old_manifest[rel.strip()] = h.strip()

def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

src_files = {}
for sd in subdirs:
    sp = src_root / sd
    if not sp.is_dir():
        continue
    for f in sorted(sp.rglob("*")):
        if f.is_file():
            rel = f.relative_to(src_root).as_posix()
            if "__pycache__" in rel or rel.endswith(".pyc") or rel.endswith(".DS_Store"):
                continue
            src_files[rel] = f

ts = time.strftime("%Y%m%d-%H%M%S")
backup_root = dst_root / ".backups" / ts

added = 0
updated = 0
unchanged = 0
preserved = 0
pruned = 0
new_manifest = {}

for rel, sf in sorted(src_files.items()):
    s_hash = sha256(sf)
    df = dst_root / rel
    if not df.exists():
        added += 1
        new_manifest[rel] = s_hash
        if not dry_run:
            df.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(sf, df)
    else:
        d_hash = sha256(df)
        if d_hash == s_hash:
            unchanged += 1
            new_manifest[rel] = s_hash
        elif rel in old_manifest and old_manifest[rel] == d_hash:
            updated += 1
            new_manifest[rel] = s_hash
            if not dry_run:
                shutil.copy2(sf, df)
        elif force:
            updated += 1
            new_manifest[rel] = s_hash
            if not dry_run:
                bf = backup_root / rel
                bf.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(df, bf)
                shutil.copy2(sf, df)
        else:
            preserved += 1
            if rel in old_manifest:
                new_manifest[rel] = old_manifest[rel]

# Prune files that were in old_manifest, removed upstream, and unmodified locally
for rel, old_hash in sorted(old_manifest.items()):
    if rel not in src_files:
        df = dst_root / rel
        if df.is_file():
            if sha256(df) == old_hash:
                pruned += 1
                if not dry_run:
                    df.unlink()
                    parent = df.parent
                    while parent != dst_root and parent.exists() and not any(parent.iterdir()):
                        parent.rmdir()
                        parent = parent.parent
            else:
                preserved += 1

if not dry_run:
    dst_root.mkdir(parents=True, exist_ok=True)
    lines = [f"{h}  {r}" for r, h in sorted(new_manifest.items())]
    manifest_path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")

prefix = "[DRY-RUN] " if dry_run else ""
print(f"{prefix}Sync summary -> added: {added}, updated: {updated}, unchanged: {unchanged}, preserved custom: {preserved}, pruned obsolete: {pruned}")
PYEOF
    else
      # Fallback when python3 is unavailable: non-destructive copy
      info "python3 not found; using POSIX non-destructive file copy..."
      local sd
      IFS=',' read -r -a sd_arr <<< "$subdirs_csv"
      for sd in "${sd_arr[@]}"; do
        [ -d "$TMP_DIR/repo/$sd" ] || continue
        if [ "$DRY_RUN" -eq 1 ]; then
          info "[DRY-RUN] Would copy $sd/ into $target_root/$sd/"
        else
          mkdir -p "$target_root/$sd"
          cp -Rn "$TMP_DIR/repo/$sd/." "$target_root/$sd/" 2>/dev/null || cp -R "$TMP_DIR/repo/$sd/." "$target_root/$sd/"
        fi
      done
    fi
  }

  uninstall_manifest_target() {
    local target_root="$1"
    local manifest_file="$target_root/$MANIFEST_NAME"
    if [ ! -f "$manifest_file" ]; then
      die "No manifest found at $manifest_file — refusing to delete untracked directory." 1
    fi

    if [ "$DRY_RUN" -eq 0 ]; then
      prompt_confirm "Remove antigravity-skills managed files from $target_root (custom files will be preserved)?" || {
        warn "Uninstall cancelled."
        return 0
      }
    fi

    if command -v python3 >/dev/null 2>&1; then
      python3 - "$target_root" "$MANIFEST_NAME" "$DRY_RUN" "$FORCE" <<'PYEOF'
import hashlib
import sys
from pathlib import Path

dst_root = Path(sys.argv[1])
manifest_path = dst_root / sys.argv[2]
dry_run = sys.argv[3] == "1"
force = sys.argv[4] == "1"

def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

removed = 0
preserved = 0
for line in manifest_path.read_text(encoding="utf-8").splitlines():
    if "  " not in line:
        continue
    old_hash, rel = line.split("  ", 1)
    df = dst_root / rel.strip()
    if not df.is_file():
        continue
    if force or sha256(df) == old_hash.strip():
        removed += 1
        if not dry_run:
            df.unlink()
            parent = df.parent
            while parent != dst_root and parent.exists() and not any(parent.iterdir()):
                parent.rmdir()
                parent = parent.parent
    else:
        preserved += 1

if not dry_run:
    manifest_path.unlink()
    if dst_root.exists() and not any(dst_root.iterdir()):
        dst_root.rmdir()

prefix = "[DRY-RUN] " if dry_run else ""
print(f"{prefix}Uninstall summary -> removed managed files: {removed}, preserved modified/custom files: {preserved}")
PYEOF
    else
      die "python3 is required for manifest-based uninstallation." 1
    fi
  }

  git_update_clone() {
    local target_dir="$1"
    local dirty=""
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
        err "Local tracked modifications detected in $target_dir:"
        printf "%s\n" "$dirty" >&2
        die "Commit or stash your changes first, or re-run with --force to auto-stash and update." 1
      fi
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      info "[DRY-RUN] Would fetch '$BRANCH' from '$REPO_URL' and fast-forward '$target_dir'."
      return 0
    fi

    local before_rev after_rev
    before_rev="$(git -C "$target_dir" rev-parse --short HEAD)"
    GIT_TERMINAL_PROMPT=0 git -C "$target_dir" fetch --quiet origin "$BRANCH"
    git -C "$target_dir" merge --quiet --ff-only FETCH_HEAD
    after_rev="$(git -C "$target_dir" rev-parse --short HEAD)"

    if [ "$before_rev" = "$after_rev" ]; then
      ok "Already up to date at $target_dir ($after_rev)."
    else
      ok "Updated $target_dir ($before_rev -> $after_rev)."
    fi
  }

  safe_rm_clone_dir() {
    local target_dir="$1"
    local real_target=""
    real_target="$(canon_dir "$target_dir" || true)"
    [ -n "$real_target" ] || die "Invalid target directory: $target_dir" 1
    [ "$real_target" != "/" ] || die "Refusing to remove /" 1
    [ "$real_target" != "$HOME" ] || die "Refusing to remove HOME" 1

    local base
    base="$(basename "$real_target")"
    if [ "$base" != ".agents" ] && [ "$base" != "antigravity-skills" ]; then
      die "Safety guard blocked removal of unexpected directory name: $real_target" 1
    fi

    is_our_repo_clone "$real_target" || die "Refusing to delete $real_target: not verified as an antigravity-skills clone." 1

    local status_all=""
    status_all="$(git -C "$real_target" status --porcelain 2>/dev/null || true)"
    if [ -n "$status_all" ] && [ "$FORCE" -eq 0 ]; then
      err "Uncommitted or untracked files exist inside $real_target:"
      printf "%s\n" "$status_all" >&2
      die "Move/commit custom files first, or pass --force to delete anyway." 1
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      info "[DRY-RUN] Would remove directory: $real_target"
      return 0
    fi

    prompt_confirm "Permanently remove $real_target?" || {
      warn "Uninstall cancelled."
      return 0
    }

    rm -rf -- "$real_target"
    ok "Removed $real_target."
  }

  run_for_scope() {
    local cur_scope="$1"
    local target_dir=""

    if [ "$AGENT" = "antigravity" ]; then
      if [ "$cur_scope" = "local" ]; then
        # Case D1: Running directly inside .agents checkout
        if [ "$(basename "$PROJECT_DIR")" = ".agents" ] && is_our_repo_clone "$PROJECT_DIR"; then
          target_dir="$PROJECT_DIR"
        # Case D2: Running inside standalone source checkout without --dir
        elif is_our_repo_clone "$PROJECT_DIR" && [ "$EXPLICIT_DIR" -eq 0 ]; then
          die "Current directory ($PROJECT_DIR) is already an antigravity-skills source repository. Use '--global' or '--local --dir /path/to/your-project'." 2
        else
          target_dir="${PROJECT_DIR}/.agents"
        fi
      else
        target_dir="${HOME}/.gemini/config/plugins/antigravity-skills"
      fi

      if [ "$ACTION" = "uninstall" ]; then
        if [ ! -e "$target_dir" ]; then
          warn "Nothing installed at $target_dir."
          return 0
        fi
        if is_our_repo_clone "$target_dir"; then
          safe_rm_clone_dir "$target_dir"
        elif [ -f "$target_dir/$MANIFEST_NAME" ]; then
          uninstall_manifest_target "$target_dir"
        else
          die "Target $target_dir was not installed by antigravity-skills (no matching git origin or manifest)." 1
        fi
        return 0
      fi

      # Install or Update for Antigravity
      if [ ! -e "$target_dir" ]; then
        if [ "$ACTION" = "update" ]; then
          die "Target $target_dir does not exist yet. Run without --update to install." 1
        fi
        info "Installing Antigravity bundle ($cur_scope) -> $target_dir"
        if [ "$DRY_RUN" -eq 1 ]; then
          info "[DRY-RUN] Would clone '$REPO_URL' (branch '$BRANCH') into '$target_dir' (576 skills, 25 subagents, 100 rules)."
        else
          mkdir -p "$(dirname "$target_dir")"
          GIT_TERMINAL_PROMPT=0 git clone --quiet --depth 1 --branch "$BRANCH" "$CLONE_URL" "$target_dir"
          ok "Installed 576 skills, 25 subagents, and 100 rules at $target_dir"
          if [ "$cur_scope" = "local" ] && [ -d "${PROJECT_DIR}/.git" ]; then
            info "Tip: Add '.agents/' to ${PROJECT_DIR}/.gitignore (or .git/info/exclude) if you want to keep it untracked in your app repo."
          fi
        fi
      elif is_our_repo_clone "$target_dir"; then
        info "Existing antigravity-skills installation detected at $target_dir — updating..."
        git_update_clone "$target_dir"
      else
        if [ "$ACTION" = "update" ] && [ ! -f "$target_dir/$MANIFEST_NAME" ]; then
          die "Existing directory $target_dir has no antigravity-skills manifest. Run without --update to merge into it." 1
        fi
        info "Pre-existing folder detected at $target_dir — performing non-destructive merge (custom files preserved)..."
        sync_with_manifest "$target_dir" "skills,agents,rules"
        ok "Completed non-destructive sync into $target_dir"
      fi

      # Coexistence advisory
      if [ "$cur_scope" = "local" ] && [ -d "${HOME}/.gemini/config/plugins/antigravity-skills" ]; then
        info "Note: Global plugin (~/.gemini/config/plugins/antigravity-skills) is also installed; workspace ./.agents takes precedence in this project."
      elif [ "$cur_scope" = "global" ] && [ -d "${PROJECT_DIR}/.agents/skills" ] && [ "$PROJECT_DIR" != "$target_dir" ]; then
        info "Note: Current directory also has ./.agents/skills, which overrides global skills when working inside $PROJECT_DIR."
      fi

    else
      # AGENT == "claude"
      if [ "$cur_scope" = "local" ]; then
        target_dir="${PROJECT_DIR}/.claude"
      else
        target_dir="${HOME}/.claude"
      fi

      if [ "$ACTION" = "uninstall" ]; then
        if [ ! -f "$target_dir/$MANIFEST_NAME" ]; then
          warn "No managed Claude Code installation manifest found at $target_dir."
          return 0
        fi
        uninstall_manifest_target "$target_dir"
        return 0
      fi

      if [ "$ACTION" = "update" ] && [ ! -f "$target_dir/$MANIFEST_NAME" ]; then
        die "No existing Claude Code installation manifest found at $target_dir. Run without --update to install." 1
      fi

      info "Syncing 576 Claude Code skills ($cur_scope) -> $target_dir/skills (existing Claude configs preserved)..."
      sync_with_manifest "$target_dir" "skills"
      ok "Claude Code skills ready in $target_dir/skills"
    fi
  }

  if [ "$SCOPE" = "both" ]; then
    run_for_scope "local"
    run_for_scope "global"
  else
    run_for_scope "$SCOPE"
  fi
}

main "$@"
