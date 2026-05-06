"""Summary report generation for AI testing episodes.

Generates JSON and Markdown reports from episode results.
Adapted from stardrifter's runner.py report writing logic with
domain-specific strings removed.
"""

from __future__ import annotations

import json
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Mapping


def write_episode_artifacts(
    episode_dir: Path,
    config_dict: Dict[str, Any],
    result_payload: Dict[str, Any],
    input_log: List[Dict[str, Any]],
    telemetry: List[Dict[str, Any]],
    state_samples: List[Dict[str, Any]],
) -> None:
    """Write per-episode artifact files.

    Parameters
    ----------
    episode_dir:
        Directory for this episode's artifacts.
    config_dict:
        Serialized ``EpisodeConfig`` dataclass.
    result_payload:
        Summary payload for the episode.
    input_log:
        Per-step action records.
    telemetry:
        Per-step telemetry records.
    state_samples:
        Per-step observation snapshots.
    """
    (episode_dir / "logs").mkdir(parents=True, exist_ok=True)
    (episode_dir / "screenshots").mkdir(parents=True, exist_ok=True)
    _write_json(episode_dir / "config.json", config_dict)
    _write_json(episode_dir / "result.json", result_payload)
    _write_jsonl(episode_dir / "input_log.jsonl", input_log)
    _write_jsonl(episode_dir / "telemetry.jsonl", telemetry)
    _write_jsonl(episode_dir / "state_samples.jsonl", state_samples)


def write_suite_artifacts(
    output_dir: Path,
    results: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """Write suite-level manifest, summary and Markdown report.

    Parameters
    ----------
    output_dir:
        Root artifact directory.
    results:
        List of per-episode result payloads.

    Returns
    -------
    dict
        The summary payload that was written.
    """
    passed = sum(1 for item in results if item["status"] == "passed")
    failed = len(results) - passed
    manifest = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "runtime_advisory_only": True,
        "artifact_contract": "ai-automated-testing-framework-v0",
        "episodes": [item["episode_id"] for item in results],
    }
    summary = {
        "total": len(results),
        "passed": passed,
        "failed": failed,
        "results": results,
        "runtime_advisory_only": True,
    }
    _write_json(output_dir / "manifest.json", manifest)
    _write_json(output_dir / "summary.json", summary)
    _write_report(output_dir / "report.md", summary)
    return summary


def _write_report(path: Path, summary: Mapping[str, Any]) -> None:
    """Generate a Markdown report from the summary."""
    lines = [
        "# AI Automated Testing Exploration Report",
        "",
        "> Runtime advisory only. These no-training pilots do not replace "
        "Interaction or Experience acceptance.",
        "",
        f"- Total episodes: {summary['total']}",
        f"- Passed: {summary['passed']}",
        f"- Failed: {summary['failed']}",
        "",
        "| Episode | Env | Policy | Status | Reason |",
        "|---|---|---|---|---|",
    ]
    for item in summary["results"]:
        lines.append(
            f"| `{item['episode_id']}` | `{item['env_name']}` "
            f"| `{item['policy_name']}` | `{item['status']}` "
            f"| `{item['reason']}` |"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _json_default(value: Any) -> Any:
    if hasattr(value, "__dict__"):
        return asdict(value)
    return str(value)


def _write_json(path: Path, payload: Any) -> None:
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True, default=_json_default) + "\n",
        encoding="utf-8",
    )


def _write_jsonl(path: Path, records: List[Dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8") as fh:
        for record in records:
            fh.write(json.dumps(record, sort_keys=True, default=_json_default) + "\n")


__all__ = [
    "write_episode_artifacts",
    "write_suite_artifacts",
]
