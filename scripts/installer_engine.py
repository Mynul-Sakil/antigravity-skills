#!/usr/bin/env python3
"""Antigravity Skills — Sparse-checkout sync, profile resolver, and Copilot transformer.

Stdlib-only engine invoked by install.sh for `list` and `sync` commands.
"""

from __future__ import annotations

import difflib
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Set, Tuple

COPILOT_TOOL_MAP: Dict[str, List[str]] = {
    "read_file": ["read", "search"],
    "edit_file": ["edit"],
    "write_file": ["edit"],
    "run_command": ["execute"],
    "manage_task": ["execute"],
}

FRONTMATTER_RE = re.compile(r"^---\r?\n(.*?)\r?\n---\r?\n?(.*)$", re.DOTALL)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_profiles(repo_dir: str, fallback_prof: str) -> Optional[dict]:
    res = subprocess.run(
        ["git", "-C", repo_dir, "show", "HEAD:profiles.json"],
        capture_output=True,
        text=True,
    )
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
            sys.exit(
                f"[ERR]  Refusing to traverse symlinked directory '{cur}'. "
                "Manage the target directory directly instead."
            )
    p = dst_root / rel
    dst_real = os.path.realpath(str(dst_root))
    parent_real = os.path.realpath(str(p.parent)) if p.parent.exists() else dst_real
    if os.path.commonpath([dst_real, parent_real]) != dst_real:
        sys.exit(f"[ERR]  Path containment check blocked '{rel}'")
    return p


def load_manifest(manifest_path: Path) -> Tuple[bool, dict, Dict[str, str]]:
    empty_state = {"base": "none", "roles": [], "skills": [], "excluded": []}
    if manifest_path.is_symlink():
        sys.exit(f"[ERR]  Refusing to read symlinked manifest '{manifest_path}'")
    if not manifest_path.is_file():
        return False, empty_state, {}
    state = {"base": "all", "roles": [], "skills": [], "excluded": []}
    entries: Dict[str, str] = {}
    for idx, ln in enumerate(manifest_path.read_text(encoding="utf-8").splitlines()):
        if idx == 0 and ln.startswith("# @state "):
            try:
                p = json.loads(ln[len("# @state ") :])
                state = {
                    "base": p.get("base", "minimal"),
                    "roles": list(p.get("roles", [])),
                    "skills": list(p.get("skills", [])),
                    "excluded": list(p.get("excluded", [])),
                }
            except Exception:
                pass
        elif not ln.startswith("#") and "  " in ln:
            h, rel = ln.split("  ", 1)
            rel_s = rel.strip()
            if not is_clean_rel(rel_s):
                sys.exit(f"[ERR]  Corrupted or unsafe path in {manifest_path}: '{rel_s}'")
            entries[rel_s] = h.strip()
    return True, state, entries


def save_manifest(manifest_path: Path, dst_root: Path, state: dict, entries: Dict[str, str]) -> None:
    dst_root.mkdir(parents=True, exist_ok=True)
    clean_state = {"base": state["base"], "roles": state["roles"], "skills": state["skills"]}
    if state.get("excluded"):
        clean_state["excluded"] = sorted(set(state["excluded"]))
    header = "# @state " + json.dumps(clean_state, separators=(",", ":"))
    body = [f"{h}  {r}" for r, h in sorted(entries.items())]
    manifest_path.write_text("\n".join([header] + body) + "\n", encoding="utf-8")


def prune_empty_parents(p: Path, stop_root: Path) -> None:
    parent = p.parent
    while parent != stop_root and parent.exists() and not parent.is_symlink():
        ds = parent / ".DS_Store"
        if ds.is_file() and not ds.is_symlink():
            ds.unlink()
        pc = parent / "__pycache__"
        if (
            pc.is_dir()
            and not pc.is_symlink()
            and all(c.is_file() and c.suffix in (".pyc", ".pyo") for c in pc.iterdir())
        ):
            shutil.rmtree(pc)
        if any(parent.iterdir()):
            break
        parent.rmdir()
        parent = parent.parent


def transform_rule_to_copilot(raw_text: str) -> bytes:
    """Convert an Antigravity rule (.md) into a Copilot .instructions.md file."""
    text = raw_text.replace("\r\n", "\n")
    m = FRONTMATTER_RE.match(text)
    apply_to = "**"
    body = text
    if m:
        fm, body = m.group(1), m.group(2)
        trig_m = re.search(r"^trigger:\s*(.+)$", fm, flags=re.MULTILINE)
        glob_m = re.search(r"^globs:\s*(.+)$", fm, flags=re.MULTILINE)
        trigger = trig_m.group(1).strip().strip("\"'") if trig_m else "always_on"
        if trigger == "glob" and glob_m:
            apply_to = glob_m.group(1).strip().strip("\"'")
    escaped_apply = apply_to.replace("\\", "\\\\").replace('"', '\\"')
    rendered = f'---\napplyTo: "{escaped_apply}"\n---\n\n{body.lstrip()}'
    if not rendered.endswith("\n"):
        rendered += "\n"
    return rendered.encode("utf-8")


def transform_agent_to_copilot(raw_text: str, stem: str) -> bytes:
    """Convert an Antigravity subagent (.md) into a Copilot .agent.md file."""
    text = raw_text.replace("\r\n", "\n")
    m = FRONTMATTER_RE.match(text)
    name = stem
    desc = f"Specialist {stem} agent"
    mapped_tools: List[str] = []
    body = text
    if m:
        fm, body = m.group(1), m.group(2)
        nm = re.search(r"^name:\s*(.+)$", fm, flags=re.MULTILINE)
        dm = re.search(r"^description:\s*(.+)$", fm, flags=re.MULTILINE)
        tm = re.search(r"^tools:\s*\[([^\]]*)\]", fm, flags=re.MULTILINE)
        if nm:
            name = nm.group(1).strip().strip("\"'")
        if dm:
            desc = dm.group(1).strip()
        if tm:
            for tok in tm.group(1).split(","):
                clean = tok.strip().strip("\"'")
                for ctool in COPILOT_TOOL_MAP.get(clean, []):
                    if ctool not in mapped_tools:
                        mapped_tools.append(ctool)
    if not mapped_tools:
        mapped_tools = ["read", "search"]
    if not (desc.startswith('"') and desc.endswith('"')) and not (desc.startswith("'") and desc.endswith("'")):
        desc = '"' + desc.replace("\\", "\\\\").replace('"', '\\"') + '"'
    tools_yaml = ", ".join(mapped_tools)
    rendered = f"---\nname: {name}\ndescription: {desc}\ntools: [{tools_yaml}]\n---\n\n{body.lstrip()}"
    if not rendered.endswith("\n"):
        rendered += "\n"
    return rendered.encode("utf-8")


def map_dest_rel(src_rel: str, agent: str) -> str:
    if agent != "copilot":
        return src_rel
    if src_rel.startswith("rules/") and src_rel.endswith(".md"):
        stem = Path(src_rel).stem
        return f"instructions/{stem}.instructions.md"
    if src_rel.startswith("agents/") and src_rel.endswith(".md"):
        stem = Path(src_rel).stem
        return f"agents/{stem}.agent.md"
    return src_rel


def render_target_bytes(src_file: Path, src_rel: str, agent: str) -> bytes:
    if agent == "copilot":
        if src_rel.startswith("rules/") and src_rel.endswith(".md"):
            return transform_rule_to_copilot(src_file.read_text(encoding="utf-8"))
        if src_rel.startswith("agents/") and src_rel.endswith(".md"):
            return transform_agent_to_copilot(src_file.read_text(encoding="utf-8"), src_file.stem)
    return src_file.read_bytes()


def cmd_list(args: Sequence[str]) -> None:
    repo_dir, mode, fallback_prof = args[0:3]
    if mode == "skills":
        out = subprocess.check_output(
            ["git", "-C", repo_dir, "ls-tree", "-r", "--name-only", "HEAD"], text=True
        )
        skills = sorted(
            {
                p.split("/")[1]
                for p in out.splitlines()
                if p.startswith("skills/") and p.endswith("/SKILL.md") and p.count("/") == 2
            }
        )
        print(f"Available skills ({len(skills)}):")
        for s in skills:
            print(f"  {s}")
        return

    data = load_profiles(repo_dir, fallback_prof)
    if not data:
        sys.exit("[ERR]  profiles.json not found in repository.")
    m = data["minimal"]
    print(
        f"Default Profile:\n  {'minimal':<12} "
        f"({len(m['skills']):>2} skills, {len(m['agents']):>2} agents, {len(m['rules']):>2} rules) "
        f"- {m['description']}\n"
    )
    print("Available --role Packs:")
    for rname, r in data["roles"].items():
        print(
            f"  {rname:<12} "
            f"({len(r['skills']):>2} skills, {len(r['agents']):>2} agents, {len(r['rules']):>2} rules) "
            f"- {r['description']}"
        )
    if data.get("aliases"):
        print("\nAliases: " + ", ".join(f"{k} -> {v}" for k, v in data["aliases"].items()))


def resolve_cli_requests(
    roles_csv: str, skills_csv: str, prof_data: Optional[dict], all_skills: List[str]
) -> Tuple[List[str], List[str]]:
    cli_roles = [r.strip() for r in roles_csv.split(",") if r.strip()]
    cli_skills = [s.strip() for s in skills_csv.split(",") if s.strip()]
    all_skill_set = set(all_skills)

    if cli_roles:
        if not prof_data:
            sys.exit("[ERR]  profiles.json not found in repository.")
        aliases, valid_roles = prof_data.get("aliases", {}), prof_data.get("roles", {})
        resolved: List[str] = []
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
    return cli_roles, cli_skills


def collect_bundle(st: dict, prof_data: Optional[dict], all_skill_set: Set[str], excl_set: Set[str]):
    if st["base"] == "all":
        if excl_set:
            return sorted(all_skill_set - excl_set), "ALL", "ALL"
        return None, None, None
    sk, ag, rl = set(st["skills"]), set(), set()
    if st["base"] == "minimal":
        m = prof_data["minimal"]
        sk.update(m["skills"])
        ag.update(m["agents"])
        rl.update(m["rules"])
    for r in st["roles"]:
        rb = prof_data["roles"][r]
        sk.update(rb["skills"])
        ag.update(rb["agents"])
        rl.update(rb["rules"])
    sk -= excl_set
    return sorted(sk), sorted(ag), sorted(rl)


def sparse_checkout_patterns(repo_dir: str, patterns: List[str], full_checkout: bool) -> None:
    if not patterns:
        return
    git_env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
    if full_checkout:
        is_prom = (
            subprocess.run(
                ["git", "-C", repo_dir, "config", "--bool", "remote.origin.promisor"],
                capture_output=True,
                text=True,
            ).stdout.strip()
            == "true"
        )
        if is_prom and (
            subprocess.run(
                ["git", "-C", repo_dir, "fetch", "--quiet", "--refetch", "origin", "HEAD"],
                check=False,
                env=git_env,
                capture_output=True,
            ).returncode
            == 0
        ):
            subprocess.run(["git", "-C", repo_dir, "config", "--unset", "remote.origin.promisor"], check=False)
            subprocess.run(
                ["git", "-C", repo_dir, "config", "--unset", "remote.origin.partialclonefilter"], check=False
            )
    has_sparse = subprocess.run(["git", "-C", repo_dir, "sparse-checkout", "-h"], capture_output=True).returncode == 0
    if has_sparse:
        subprocess.run(
            ["git", "-C", repo_dir, "sparse-checkout", "init", "--no-cone"],
            check=True,
            env=git_env,
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", repo_dir, "sparse-checkout", "set", "--no-cone", "--stdin"],
            input="\n".join(patterns) + "\n",
            text=True,
            check=True,
            env=git_env,
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", repo_dir, "checkout", "--quiet", "-f", "HEAD"],
            check=True,
            env=git_env,
            capture_output=True,
        )
    else:
        clean_p = [p.lstrip("/").rstrip("/") for p in patterns]
        subprocess.run(
            ["git", "-C", repo_dir, "checkout", "--quiet", "HEAD", "--", *clean_p],
            check=True,
            env=git_env,
            capture_output=True,
        )


def cmd_sync(args: Sequence[str]) -> None:
    (
        repo_dir,
        dst_raw,
        manifest_name,
        agent,
        cur_scope,
        explicit_base,
        roles_csv,
        skills_csv,
        fallback_prof,
        dry_s,
        force_s,
    ) = args[0:11]
    dry_run, force = (dry_s == "1"), (force_s == "1")
    src_root, dst_root = Path(repo_dir), Path(dst_raw)
    manifest_path = dst_root / manifest_name

    tree_out = subprocess.check_output(
        ["git", "-C", repo_dir, "ls-tree", "-r", "--name-only", "HEAD"], text=True
    )
    tree_files = [
        p for p in tree_out.splitlines() if p and "__pycache__" not in p and not p.endswith((".pyc", ".DS_Store"))
    ]
    all_skills = sorted(
        {p.split("/")[1] for p in tree_files if p.startswith("skills/") and p.endswith("/SKILL.md") and p.count("/") == 2}
    )
    prof_data = load_profiles(repo_dir, fallback_prof)
    cli_roles, cli_skills = resolve_cli_requests(roles_csv, skills_csv, prof_data, all_skills)

    has_existing, old_state, old_manifest = load_manifest(manifest_path)
    old_excl = set(old_state.get("excluded", [])) - set(cli_skills)
    if explicit_base == "all":
        new_state, sync_mode = {"base": "all", "roles": [], "skills": [], "excluded": []}, "RECONCILE"
    elif explicit_base == "minimal":
        new_state, sync_mode = (
            {"base": "minimal", "roles": sorted(set(cli_roles)), "skills": sorted(set(cli_skills)), "excluded": []},
            "RECONCILE",
        )
    elif cli_roles or cli_skills:
        sync_mode = "ADDITIVE"
        if old_state["base"] == "all":
            new_state = {"base": "all", "roles": [], "skills": [], "excluded": sorted(old_excl)}
        else:
            new_state = {
                "base": old_state["base"],
                "roles": sorted(set(old_state["roles"]) | set(cli_roles)),
                "skills": sorted(set(old_state["skills"]) | set(cli_skills)),
                "excluded": sorted(old_excl),
            }
    else:
        sync_mode = "RECONCILE"
        new_state = old_state if has_existing else {"base": "minimal", "roles": [], "skills": [], "excluded": []}

    if (new_state["base"] == "minimal" or new_state["roles"]) and not prof_data:
        sys.exit("[ERR]  profiles.json is required to resolve minimal/role bundles.")

    excl_set = set(new_state.get("excluded", []))
    f_state = (
        {"base": "none", "roles": sorted(set(cli_roles)), "skills": sorted(set(cli_skills)), "excluded": []}
        if sync_mode == "ADDITIVE"
        else new_state
    )
    f_sk, f_ag, f_rl = collect_bundle(f_state, prof_data, set(all_skills), excl_set)

    include_agents_rules = (agent == "antigravity") or (agent == "copilot" and cur_scope == "local")
    patterns: List[str] = []
    synced_prefixes: List[str] = []
    wanted_map: Dict[str, str] = {}

    if agent == "antigravity" and cur_scope == "global" and "plugin.json" in tree_files:
        patterns.append("/plugin.json")
        synced_prefixes.append("plugin.json")
        wanted_map["plugin.json"] = "plugin.json"

    if f_sk is None:
        patterns.append("/skills/")
        synced_prefixes.append("skills/")
        if include_agents_rules:
            patterns.extend(["/agents/", "/rules/"])
            synced_prefixes.extend(["agents/", "instructions/" if agent == "copilot" else "rules/"])
        for tf in tree_files:
            if tf.startswith("skills/") or (include_agents_rules and tf.startswith(("agents/", "rules/"))):
                wanted_map[map_dest_rel(tf, agent)] = tf
    else:
        sk_pfx = tuple(f"skills/{s}/" for s in f_sk)
        for s in f_sk:
            patterns.append(f"/skills/{s}/")
            synced_prefixes.append(f"skills/{s}/")
        for tf in tree_files:
            if sk_pfx and tf.startswith(sk_pfx):
                wanted_map[tf] = tf
        if include_agents_rules:
            if f_ag == "ALL":
                patterns.extend(["/agents/", "/rules/"])
                synced_prefixes.extend(["agents/", "instructions/" if agent == "copilot" else "rules/"])
                for tf in tree_files:
                    if tf.startswith(("agents/", "rules/")):
                        wanted_map[map_dest_rel(tf, agent)] = tf
            else:
                for a in f_ag:
                    ra = f"agents/{a}"
                    if ra in tree_files:
                        da = map_dest_rel(ra, agent)
                        patterns.append(f"/{ra}")
                        synced_prefixes.append(da)
                        wanted_map[da] = ra
                for r in f_rl:
                    rr = f"rules/{r}"
                    if rr in tree_files:
                        dr = map_dest_rel(rr, agent)
                        patterns.append(f"/{rr}")
                        synced_prefixes.append(dr)
                        wanted_map[dr] = rr

    parts = []
    if sync_mode == "ADDITIVE":
        if cli_roles:
            parts.append("role=" + ",".join(cli_roles))
        if cli_skills:
            parts.append("skill=" + ",".join(cli_skills))
        label = "additive (" + " + ".join(parts) + ")"
    else:
        if new_state["base"] != "none":
            parts.append(new_state["base"])
        if new_state["roles"]:
            parts.append("role=" + ",".join(new_state["roles"]))
        if new_state["skills"]:
            parts.append("skill=" + ",".join(new_state["skills"]))
        label = " + ".join(parts) if parts else "custom"
    print(f"[INFO] Syncing {agent} ({cur_scope}) [mode: {label}] -> {dst_root}")

    sparse_checkout_patterns(repo_dir, patterns, full_checkout=(f_sk is None))

    backup_root = dst_root / ".backups" / time.strftime("%Y%m%d-%H%M%S")
    added = updated = unchanged = preserved = pruned = 0
    new_manifest: Dict[str, str] = {}

    for dest_rel, src_rel in sorted(wanted_map.items()):
        sf = src_root / src_rel
        if sf.is_symlink() or not sf.is_file():
            sys.exit(f"[ERR]  Expected sparse-checkout file missing or symlinked: {src_rel}")
        payload = render_target_bytes(sf, src_rel, agent)
        s_hash = sha256_bytes(payload)
        df = safe_target_path(dst_root, dest_rel)
        if df.is_symlink():
            preserved += 1
            continue
        if not df.exists():
            added += 1
            new_manifest[dest_rel] = s_hash
            if not dry_run:
                df.parent.mkdir(parents=True, exist_ok=True)
                df.write_bytes(payload)
                if agent != "copilot" or not src_rel.startswith(("rules/", "agents/")):
                    shutil.copymode(sf, df)
        else:
            d_hash = sha256_file(df)
            if d_hash == s_hash:
                unchanged += 1
                new_manifest[dest_rel] = s_hash
            elif dest_rel in old_manifest and old_manifest[dest_rel] == d_hash:
                updated += 1
                new_manifest[dest_rel] = s_hash
                if not dry_run:
                    df.write_bytes(payload)
            elif force:
                updated += 1
                new_manifest[dest_rel] = s_hash
                if not dry_run:
                    bf = backup_root / dest_rel
                    bf.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(df, bf)
                    df.write_bytes(payload)
            else:
                preserved += 1
                if dest_rel in old_manifest:
                    new_manifest[dest_rel] = old_manifest[dest_rel]

    for rel, old_hash in sorted(old_manifest.items()):
        if rel in wanted_map:
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
            if sha256_file(df) == old_hash:
                pruned += 1
                if not dry_run:
                    df.unlink()
                    prune_empty_parents(df, dst_root)
            else:
                preserved += 1

    if not dry_run:
        save_manifest(manifest_path, dst_root, new_state, new_manifest)
    sk_cnt = len({r.split("/")[1] for r in new_manifest if r.startswith("skills/") and r.count("/") >= 2})
    pfx = "[DRY-RUN] " if dry_run else ""
    print(
        f"{pfx}Sync summary -> active skills: {sk_cnt} | "
        f"added: {added}, updated: {updated}, unchanged: {unchanged}, "
        f"preserved custom: {preserved}, pruned: {pruned}"
    )


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("[ERR]  Missing engine subcommand (list | sync).")
    cmd = sys.argv[1]
    if cmd == "list":
        cmd_list(sys.argv[2:])
    elif cmd == "sync":
        cmd_sync(sys.argv[2:])
    else:
        sys.exit(f"[ERR]  Unknown engine subcommand: {cmd}")


if __name__ == "__main__":
    main()
