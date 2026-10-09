#!/usr/bin/env python3
"""Plot action trajectories from a LeRobot dataset (Hub repo or local folder).

Reads the dataset's parquet files directly (works for v2.x and v3 layouts), so it does not
depend on LeRobot's Python API.

Examples
  python analysis/plot_actions.py --repo-id sagnikroy75/so101_cube_bowl
  python analysis/plot_actions.py --local-dir ~/.cache/huggingface/lerobot/sagnikroy75/so101_cube_bowl

Outputs
  assets/action_trajectories.png   all episodes overlaid, one panel per joint
  assets/action_vs_state.png       leader command vs follower state for one episode (if available)
and prints a dataset summary (episodes, frames, durations, per-joint ranges).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

DEFAULT_JOINTS = ["shoulder_pan", "shoulder_lift", "elbow_flex", "wrist_flex", "wrist_roll", "gripper"]


def resolve_root(repo_id: str | None, local_dir: str | None) -> Path:
    if local_dir:
        return Path(local_dir).expanduser()
    if not repo_id:
        sys.exit("Provide --repo-id or --local-dir.")
    from huggingface_hub import snapshot_download

    return Path(snapshot_download(repo_id=repo_id, repo_type="dataset", allow_patterns=["meta/*", "data/*"]))


def joint_names(info: dict, dim: int) -> list[str]:
    names = info.get("features", {}).get("action", {}).get("names")
    if isinstance(names, dict):  # older layout: {"motors": [...]}
        names = next(iter(names.values()), None)
    if isinstance(names, list) and len(names) == dim:
        return [str(n) for n in names]
    return DEFAULT_JOINTS[:dim] if dim <= len(DEFAULT_JOINTS) else [f"dim_{i}" for i in range(dim)]


def load(root: Path) -> tuple[pd.DataFrame, dict]:
    files = sorted((root / "data").rglob("*.parquet"))
    if not files:
        sys.exit(f"No parquet files under {root / 'data'}")
    df = pd.concat((pd.read_parquet(f) for f in files), ignore_index=True)
    info_path = root / "meta" / "info.json"
    info = json.loads(info_path.read_text()) if info_path.exists() else {}
    if "frame_index" not in df:
        df["frame_index"] = df.groupby("episode_index").cumcount()
    return df.sort_values(["episode_index", "frame_index"]).reset_index(drop=True), info


def episode_arrays(df: pd.DataFrame, col: str) -> dict[int, np.ndarray]:
    return {int(ep): np.stack(g[col].to_numpy()).astype(float) for ep, g in df.groupby("episode_index")}


def print_summary(actions: dict[int, np.ndarray], fps: float, names: list[str]) -> None:
    lengths = np.array([len(a) for a in actions.values()])
    durations = lengths / fps
    print(f"Episodes: {len(actions)} | frames: {lengths.sum()} | fps: {fps:g}")
    print(f"Episode duration (s): mean {durations.mean():.1f}, median {np.median(durations):.1f}, "
          f"min {durations.min():.1f}, max {durations.max():.1f}")
    allact = np.concatenate(list(actions.values()))
    print("Per-joint action range:")
    for i, n in enumerate(names):
        print(f"  {n:>16}: min {allact[:, i].min():8.2f}  max {allact[:, i].max():8.2f}  std {allact[:, i].std():7.2f}")


def plot_trajectories(actions: dict[int, np.ndarray], fps: float, names: list[str], out: Path) -> None:
    dim = len(names)
    cols = 3
    rows = int(np.ceil(dim / cols))
    fig, axes = plt.subplots(rows, cols, figsize=(5 * cols, 3 * rows), squeeze=False, sharex=True)
    min_len = min(len(a) for a in actions.values())
    median = np.median(np.stack([a[:min_len] for a in actions.values()]), axis=0)
    for i, name in enumerate(names):
        ax = axes[i // cols][i % cols]
        for a in actions.values():
            ax.plot(np.arange(len(a)) / fps, a[:, i], lw=0.8, alpha=0.35, color="tab:blue")
        ax.plot(np.arange(min_len) / fps, median[:, i], lw=2, color="tab:red", label="median")
        ax.set_title(name)
        ax.grid(alpha=0.3)
        if i // cols == rows - 1:
            ax.set_xlabel("time (s)")
        if i % cols == 0:
            ax.set_ylabel("action (units as recorded)")
    for j in range(dim, rows * cols):
        axes[j // cols][j % cols].axis("off")
    axes[0][0].legend(loc="best")
    fig.suptitle(f"Teleoperated action trajectories ({len(actions)} episodes)")
    fig.tight_layout()
    out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out, dpi=150)
    plt.close(fig)
    print(f"Saved {out}")


def plot_action_vs_state(actions: dict[int, np.ndarray], states: dict[int, np.ndarray], ep: int,
                         fps: float, names: list[str], out: Path) -> None:
    a, s = actions[ep], states[ep]
    n = min(len(a), len(s))
    err = np.abs(a[:n] - s[:n]).mean(axis=0)
    print(f"Episode {ep}: mean |action - state| per joint -> " +
          ", ".join(f"{nm}={e:.2f}" for nm, e in zip(names, err)))
    dim = len(names)
    cols = 3
    rows = int(np.ceil(dim / cols))
    fig, axes = plt.subplots(rows, cols, figsize=(5 * cols, 3 * rows), squeeze=False, sharex=True)
    t = np.arange(n) / fps
    for i, name in enumerate(names):
        ax = axes[i // cols][i % cols]
        ax.plot(t, a[:n, i], label="action (leader)", lw=1.5)
        ax.plot(t, s[:n, i], label="state (follower)", lw=1.5, ls="--")
        ax.set_title(name)
        ax.grid(alpha=0.3)
    for j in range(dim, rows * cols):
        axes[j // cols][j % cols].axis("off")
    axes[0][0].legend(loc="best")
    fig.suptitle(f"Episode {ep}: commanded action vs measured follower state")
    fig.tight_layout()
    fig.savefig(out, dpi=150)
    plt.close(fig)
    print(f"Saved {out}")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--repo-id", help="Hugging Face dataset repo, e.g. sagnikroy75/so101_cube_bowl")
    p.add_argument("--local-dir", help="Local dataset folder (e.g. ~/.cache/huggingface/lerobot/<repo-id>)")
    p.add_argument("--out", default="assets/action_trajectories.png")
    p.add_argument("--state-out", default="assets/action_vs_state.png")
    p.add_argument("--episode", type=int, default=None, help="Episode for the action-vs-state plot (default: first)")
    args = p.parse_args()

    root = resolve_root(args.repo_id, args.local_dir)
    df, info = load(root)
    fps = float(info.get("fps", 30))
    actions = episode_arrays(df, "action")
    dim = next(iter(actions.values())).shape[1]
    names = joint_names(info, dim)

    print_summary(actions, fps, names)
    plot_trajectories(actions, fps, names, Path(args.out))

    if "observation.state" in df:
        states = episode_arrays(df, "observation.state")
        ep = args.episode if args.episode in actions else next(iter(actions))
        plot_action_vs_state(actions, states, ep, fps, names, Path(args.state_out))


if __name__ == "__main__":
    main()
