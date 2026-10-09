#!/usr/bin/env python3
"""Summarise autonomous evaluation trials from results/eval_trials.csv.

CSV columns: trial,timestamp,policy,outcome,time_s,notes
  outcome = success | partial | fail ; time_s = stopwatch completion time in seconds (may be blank)

Prints the success count, a 95% Wilson confidence interval, and completion-time statistics over the
successful, timed trials. With a handful of trials the interval is wide, so always report the raw
count (e.g. 5/5) next to any rate. The time summary also says which statistic (mean, best) is which,
so the CV wording can match the data.
"""
from __future__ import annotations

import sys
from math import sqrt
from pathlib import Path

import pandas as pd


def wilson(k: int, n: int, z: float = 1.96) -> tuple[float, float]:
    if n == 0:
        return 0.0, 0.0
    p = k / n
    denom = 1 + z * z / n
    centre = (p + z * z / (2 * n)) / denom
    half = z * sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / denom
    return max(0.0, centre - half), min(1.0, centre + half)


def main() -> None:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "results/eval_trials.csv")
    if not path.exists():
        sys.exit(f"{path} not found")
    df = pd.read_csv(path, encoding="utf-8-sig")
    n = len(df)
    if n == 0:
        print("No trials logged yet.")
        return
    counts = df["outcome"].str.lower().value_counts()
    k = int(counts.get("success", 0))
    lo, hi = wilson(k, n)
    print(f"Trials: {n} | success: {k} | partial: {int(counts.get('partial', 0))} | fail: {int(counts.get('fail', 0))}")
    print(f"Success rate: {k}/{n} = {100 * k / n:.0f}%  (95% Wilson CI {100 * lo:.0f}-{100 * hi:.0f}%)")

    if "time_s" in df:
        ok = df[df["outcome"].str.lower() == "success"]["time_s"].dropna()
        ok = pd.to_numeric(ok, errors="coerce").dropna()
        if len(ok):
            sd = ok.std(ddof=1) if len(ok) > 1 else float("nan")
            print(f"Completion time over {len(ok)} successful timed trials: "
                  f"mean {ok.mean():.2f} s, sd {sd:.2f} s, best {ok.min():.2f} s, worst {ok.max():.2f} s")


if __name__ == "__main__":
    main()
