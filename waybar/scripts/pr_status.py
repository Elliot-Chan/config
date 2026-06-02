#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import time
from datetime import datetime
from html import escape
from pathlib import Path


CODEX_SCRIPTS_DIR = Path("/home/elliot/.codex/scripts")
if str(CODEX_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(CODEX_SCRIPTS_DIR))
SKILLS_SHARED_DIR = Path("/home/elliot/.codex/skills/_shared")
if str(SKILLS_SHARED_DIR) not in sys.path:
    sys.path.insert(0, str(SKILLS_SHARED_DIR))

from gitcode_api_common import gitcode_api_get_json


HOME = Path.home()
CONFIG_FILE = Path(os.environ.get("WAYBAR_PR_STATUS_CONFIG", HOME / ".config" / "waybar" / "pr_status.json"))
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "waybar"
CACHE_FILE = CACHE_DIR / "pr_status.json"
WATCHER = HOME / ".codex" / "skills" / "gitcode-pr-create" / "scripts" / "watch_pr_test_status.py"
FETCH_TIMEOUT_SECONDS = 25
CACHE_TTL_SECONDS = int(os.environ.get("WAYBAR_PR_STATUS_CACHE_TTL", "240"))
ROTATE_SECONDS = int(os.environ.get("WAYBAR_PR_STATUS_ROTATE_SECONDS", "15"))

STATUS_ICONS = {
    "passed": "✓",
    "failed": "×",
    "pending": "…",
    "unknown": "?",
    "error": "!",
    "merged": "✓",
    "ready": "●",
    "blocking": "×",
}

STATUS_CLASSES = {
    "passed": "ok",
    "failed": "critical",
    "pending": "warn",
    "unknown": "unknown",
    "error": "critical",
    "merged": "ok",
    "ready": "ok",
    "blocking": "critical",
}

STATUS_COLORS = {
    "passed": "#a6e3a1",
    "failed": "#f38ba8",
    "pending": "#f9e2af",
    "unknown": "#a6adc8",
    "error": "#fab387",
    "merged": "#a6e3a1",
    "ready": "#94e2d5",
    "blocking": "#f38ba8",
}

REQUIRED_LABELS = (
    "sign-off-passed",
    "commitlint-passed",
    "codecheck-passed",
    "build-test-passed",
)


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def write_json(path, value):
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, ensure_ascii=False), encoding="utf-8")
    except OSError:
        pass


def normalize_prs(config):
    if not config:
        return []
    raw = config.get("prs", config if isinstance(config, list) else [])
    prs = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        owner_repo = str(item.get("owner_repo") or "").strip()
        pr_number = str(item.get("pr_number") or item.get("number") or "").strip()
        if "/" not in owner_repo or not pr_number:
            continue
        prs.append(
            {
                "owner_repo": owner_repo,
                "pr_number": pr_number,
                "label": str(item.get("label") or f"{owner_repo}#{pr_number}"),
            }
        )
    return prs


def cache_key(prs):
    return [[pr["owner_repo"], pr["pr_number"], pr["label"]] for pr in prs]


def fetch_snapshot(pr):
    command = [
        sys.executable,
        str(WATCHER),
        pr["owner_repo"],
        pr["pr_number"],
        "--once",
        "--json",
    ]
    completed = subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=FETCH_TIMEOUT_SECONDS,
        check=False,
    )
    if completed.stdout.strip():
        try:
            snapshot = json.loads(completed.stdout.strip().splitlines()[-1])
            snapshot["label"] = pr["label"]
            return snapshot
        except json.JSONDecodeError:
            pass

    return {
        "label": pr["label"],
        "owner_repo": pr["owner_repo"],
        "pr_number": pr["pr_number"],
        "status": "error",
        "source": "watcher",
        "reason": (completed.stderr or completed.stdout or f"watcher exited {completed.returncode}").strip(),
    }


def accepted_count(users):
    if not isinstance(users, list):
        return 0
    return sum(1 for user in users if isinstance(user, dict) and bool(user.get("accept")))


def bool_text(value):
    if value is True:
        return "ok"
    if value is False:
        return "missing"
    return "unknown"


def check_blockers(checks, counts, required_labels):
    blockers = []
    if checks.get("mergeable") is False:
        blockers.append("mergeable: false")
    if checks.get("ci") is False:
        blockers.append("ci: not passed")
    if checks.get("conflict") is False:
        blockers.append("conflict: unresolved")
    if checks.get("discussions") is False:
        blockers.append(
            "discussions: "
            f"{counts.get('unresolved_comments', 0)} unresolved / {counts.get('review_comments', 0)} total"
        )
    if checks.get("reviewers") is False or checks.get("approvers") is False:
        blockers.append(
            "reviewers: "
            f"{counts.get('reviewers_accept', 0)}/{counts.get('reviewers_required') or counts.get('reviewers_total', 0)} accepted"
        )
    if checks.get("testers") is False:
        blockers.append(
            "testers: "
            f"{counts.get('testers_accept', 0)}/{counts.get('testers_total', 0)} accepted"
        )
    if checks.get("required_labels") is False:
        missing = [label for label, present in required_labels.items() if not present]
        blockers.append("labels: missing " + ", ".join(missing))
    return blockers


def label_names(pr):
    labels = pr.get("labels")
    if not isinstance(labels, list):
        return []
    names = []
    for item in labels:
        name = item.get("name") if isinstance(item, dict) else item
        if name:
            names.append(str(name))
    return names


def fetch_comments(token, owner_repo, pr_number):
    rows = []
    for page in range(1, 6):
        payload = gitcode_api_get_json(
            token,
            f"/repos/{owner_repo}/pulls/{pr_number}/comments",
            query={"page": page, "per_page": 100},
        )
        if isinstance(payload, list):
            page_rows = payload
        elif isinstance(payload, dict):
            page_rows = []
            for key in ("comments", "data", "items", "records", "list"):
                value = payload.get(key)
                if isinstance(value, list):
                    page_rows = value
                    break
        else:
            page_rows = []
        rows.extend(row for row in page_rows if isinstance(row, dict))
        if len(page_rows) < 100:
            break
    return rows


def comment_resolved(row):
    value = row.get("resolved", row.get("is_resolved"))
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.lower() in ("true", "1", "yes", "resolved")
    return None


def review_comment_counts(rows):
    total = 0
    unresolved = 0
    inline = 0
    for row in rows:
        comment_type = str(row.get("comment_type") or row.get("type") or "")
        has_path = bool(row.get("diff_file") or row.get("path") or row.get("file_path"))
        is_inline = comment_type == "diff_comment" or has_path
        if not is_inline:
            continue
        total += 1
        inline += 1
        if comment_resolved(row) is False:
            unresolved += 1
    return {"total": total, "unresolved": unresolved, "inline": inline}


def short_blocker(text, limit=36):
    text = str(text or "").strip()
    replacements = {
        "reviewers: ": "rev ",
        "testers: ": "test ",
        "codeowners: ": "owner ",
        "discussions: ": "disc ",
        "labels: missing ": "label ",
        "ci: not passed": "ci",
        "conflict: unresolved": "conflict",
        "mergeable: false": "merge",
    }
    for old, new in replacements.items():
        if text.startswith(old):
            text = new + text[len(old) :]
            break
        if text == old:
            text = new
            break
    return text if len(text) <= limit else text[: limit - 1] + "…"


def short_label(label, owner_repo=None, pr_number=None):
    value = str(label or "").strip()
    if pr_number and (not value or value == f"{owner_repo}#{pr_number}"):
        repo = str(owner_repo or "").split("/")[-1]
        prefix = "".join(part[0] for part in repo.replace("-", "_").split("_") if part)
        return f"{prefix or 'pr'}{pr_number}"
    value = value.replace("runtime#", "r").replace("stdx#", "sx").replace("test#", "t")
    value = value.replace("#", "")
    return value


def short_blockers(blockers, limit=80):
    parts = [short_blocker(blocker, limit=28) for blocker in blockers]
    text = "; ".join(part for part in parts if part)
    return text if len(text) <= limit else text[: limit - 1] + "…"


def blocker_kind(text):
    text = str(text or "")
    if text.startswith("reviewers:"):
        return "review"
    if text.startswith("testers:"):
        return "test"
    if text.startswith("codeowners:"):
        return "owner"
    if text.startswith("discussions:"):
        return "disc"
    if text.startswith("labels:"):
        return "label"
    if text.startswith("ci:"):
        return "ci"
    if text.startswith("conflict:"):
        return "conflict"
    if text.startswith("mergeable:"):
        return "merge"
    return "block"


def blocker_summary(blockers):
    aliases = {
        "review": "r",
        "test": "t",
        "owner": "o",
        "disc": "d",
        "label": "l",
        "ci": "ci",
        "conflict": "c",
        "merge": "m",
        "block": "b",
    }
    kinds = []
    for blocker in blockers:
        kind = aliases.get(blocker_kind(blocker), "b")
        if kind not in kinds:
            kinds.append(kind)
    return "/".join(kinds)


def build_readiness_snapshot(target):
    token = os.environ.get("GITCODE_PR_TOKEN", "")
    if not token:
        return {
            "label": target["label"],
            "owner_repo": target["owner_repo"],
            "pr_number": target["pr_number"],
            "status": "error",
            "source": "readiness",
            "reason": "GITCODE_PR_TOKEN is not set",
        }

    pr = gitcode_api_get_json(token, f"/repos/{target['owner_repo']}/pulls/{target['pr_number']}")
    comments = fetch_comments(token, target["owner_repo"], target["pr_number"])
    mergeable = pr.get("mergeable_state") if isinstance(pr.get("mergeable_state"), dict) else {}
    switch = mergeable.get("merge_request_switch") if isinstance(mergeable.get("merge_request_switch"), dict) else {}
    labels = set(label_names(pr))
    reviewers = pr.get("approval_reviewers") if isinstance(pr.get("approval_reviewers"), list) else []
    testers = pr.get("testers") if isinstance(pr.get("testers"), list) else []
    assignees = pr.get("assignees") if isinstance(pr.get("assignees"), list) else []
    codeowners = [user for user in assignees if isinstance(user, dict) and user.get("code_owner")]
    review_counts = review_comment_counts(comments)
    required_labels = {label: label in labels for label in REQUIRED_LABELS}

    merged = bool(pr.get("merged_at") or pr.get("state") == "merged")
    checks = {
        "mergeable": bool(pr.get("mergeable") or mergeable.get("state")),
        "ci": mergeable.get("ci_state_passed"),
        "reviewers": mergeable.get("approval_reviewers_required_passed"),
        "approvers": mergeable.get("approval_approvers_required_passed"),
        "testers": mergeable.get("approval_testers_required_passed"),
        "discussions": mergeable.get("resolve_discussion_passed"),
        "conflict": mergeable.get("conflict_passed"),
        "required_labels": all(required_labels.values()),
    }

    counts = {
        "reviewers_accept": accepted_count(reviewers),
        "reviewers_total": len(reviewers),
        "reviewers_required": switch.get("approval_required_reviewers_count"),
        "testers_accept": accepted_count(testers),
        "testers_total": len(testers),
        "codeowners_accept": accepted_count(codeowners),
        "codeowners_total": len(codeowners),
        "review_comments": review_counts["total"],
        "unresolved_comments": review_counts["unresolved"],
        "inline_comments": review_counts["inline"],
    }
    blockers = check_blockers(checks, counts, required_labels)

    if merged:
        status = "merged"
        reason = f"merged at {pr.get('merged_at')}"
    else:
        unknown = [name for name, value in checks.items() if value is None]
        if blockers:
            status = "blocking"
            reason = blockers[0]
        elif unknown:
            status = "pending"
            reason = "unknown: " + ", ".join(unknown)
        else:
            status = "ready"
            reason = "merge conditions appear satisfied"

    return {
        "label": target["label"],
        "owner_repo": target["owner_repo"],
        "pr_number": target["pr_number"],
        "status": status,
        "source": "readiness",
        "reason": reason,
        "merged": merged,
        "title": pr.get("title"),
        "url": pr.get("html_url") or pr.get("url"),
        "checks": checks,
        "required_labels": required_labels,
        "counts": counts,
        "blockers": blockers,
    }


def load_or_fetch(prs):
    if not prs:
        return []
    cached = read_json(CACHE_FILE)
    if cached and cached.get("cache_key") == cache_key(prs):
        age = time.time() - float(cached.get("fetched_at", 0))
        if age <= CACHE_TTL_SECONDS:
            return cached.get("snapshots", [])

    snapshots = []
    for pr in prs:
        try:
            snapshots.append(build_readiness_snapshot(pr))
        except Exception as exc:
            snapshots.append(
                {
                    "label": pr["label"],
                    "owner_repo": pr["owner_repo"],
                    "pr_number": pr["pr_number"],
                    "status": "error",
                    "source": "readiness",
                    "reason": f"{exc.__class__.__name__}: {exc}",
                }
            )
    write_json(
        CACHE_FILE,
        {"fetched_at": time.time(), "cache_key": cache_key(prs), "snapshots": snapshots},
    )
    return snapshots


def status_class(snapshots):
    statuses = {snapshot.get("status", "unknown") for snapshot in snapshots}
    if "blocking" in statuses or "failed" in statuses or "error" in statuses:
        return "critical"
    if "pending" in statuses:
        return "warn"
    if "unknown" in statuses:
        return "unknown"
    return "ok"


def render(snapshots):
    if not snapshots:
        return {
            "text": "<span color='#89b4fa'>PR</span> <span color='#6c7086'>none</span>",
            "tooltip": f"PR status: no targets\nConfigure: {CONFIG_FILE}",
            "class": "unknown",
        }

    order = ("merged", "ready", "blocking", "pending", "unknown", "error")
    counts = {key: 0 for key in STATUS_ICONS}
    lines = []
    for snapshot in snapshots:
        status = snapshot.get("status", "unknown")
        counts[status if status in counts else "unknown"] += 1
        label = snapshot.get("label") or f"{snapshot.get('owner_repo')}#{snapshot.get('pr_number')}"
        source = snapshot.get("source", "--")
        reason = snapshot.get("reason", "--")
        lines.append(f"{label}: {status} ({source})")
        if reason:
            lines.append(f"  {reason}")
        details = snapshot.get("counts") or {}
        checks = snapshot.get("checks") or {}
        if details:
            reviewers_required = details.get("reviewers_required") or details.get("reviewers_total", 0)
            lines.append(
                "  "
                f"reviewers {details.get('reviewers_accept', 0)}/{reviewers_required}, "
                f"testers {details.get('testers_accept', 0)}/{details.get('testers_total', 0)}, "
                f"codeowners {details.get('codeowners_accept', 0)}/{details.get('codeowners_total', 0)}, "
                f"comments unresolved {details.get('unresolved_comments', 0)}/{details.get('review_comments', 0)}"
            )
        if checks:
            lines.append("  " + ", ".join(f"{name}={bool_text(value)}" for name, value in checks.items()))
        blockers = snapshot.get("blockers") or []
        if blockers:
            lines.append("  blockers:")
            lines.extend(f"    - {blocker}" for blocker in blockers)

    if len(snapshots) == 1:
        snapshot = snapshots[0]
        status = snapshot.get("status", "unknown")
        color = STATUS_COLORS.get(status, STATUS_COLORS["unknown"])
        label = snapshot.get("label") or f"{snapshot.get('owner_repo')}#{snapshot.get('pr_number')}"
        short = short_label(label, snapshot.get("owner_repo"), snapshot.get("pr_number"))
        status_text = "" if status == "blocking" else f" {escape(status)}"
        text = (
            f"<span color='#cdd6f4'>{escape(str(short))}</span> "
            f"<span color='{color}'>{status_text}</span>"
        )
        blockers = snapshot.get("blockers") or []
        if status == "blocking" and blockers:
            text += f" <span color='#f9e2af'>{escape(blocker_summary(blockers))}</span>"
    else:
        parts = []
        for status in order:
            if counts[status]:
                color = STATUS_COLORS[status]
                icon = STATUS_ICONS[status]
                parts.append(f"<span color='{color}'>{escape(icon)} {counts[status]}</span>")
        text = "<span color='#89b4fa'>PR</span> " + "  ".join(parts)
        blocking = [snapshot for snapshot in snapshots if snapshot.get("status") == "blocking"]
        if blocking:
            index = (int(time.time()) // max(1, ROTATE_SECONDS)) % len(blocking)
            first = blocking[index]
            label = first.get("label") or f"{first.get('owner_repo')}#{first.get('pr_number')}"
            short = short_label(label, first.get("owner_repo"), first.get("pr_number"))
            blockers = first.get("blockers") or []
            if blockers:
                text += (
                    " "
                    f"<span color='#6c7086'>|</span> "
                    f"<span color='#cdd6f4'>{escape(str(short))}</span> "
                    f"<span color='#f9e2af'>{escape(blocker_summary(blockers))}</span>"
                )
    tooltip = "\n".join(
        [
            f"PR status ({datetime.now().astimezone():%H:%M:%S})",
            *lines,
        ]
    )
    return {"text": text, "tooltip": tooltip, "class": status_class(snapshots)}


def main():
    config = read_json(CONFIG_FILE)
    prs = normalize_prs(config)
    output = render(load_or_fetch(prs))
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
