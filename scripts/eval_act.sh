#!/usr/bin/env bash
# Run the trained ACT policy autonomously on the follower arm and log each trial.
# Uses `lerobot-rollout` (newer LeRobot); falls back to `lerobot-record --policy.path` (<= v0.5.1).
# For every trial you enter the outcome and the completion time (stopwatch, seconds); rows are
# appended to results/eval_trials.csv. Summarise with analysis/summarize_trials.py.
# Usage: scripts/eval_act.sh [extra args passed to the LeRobot command...]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/config/default.env"
if [[ -f "$ROOT/config/local.env" ]]; then source "$ROOT/config/local.env"; fi

POLICY="${POLICY_PATH:-${HF_USER}/${POLICY_NAME}}"
LOG="$ROOT/results/eval_trials.csv"
# The camera config must match what was used when the dataset was recorded.
CAMERAS="$CAMERA_CONFIG"

log_trial() {
  local i="$1" o="" t="" n=""
  while true; do
    read -r -p "Trial ${i} outcome [s=success / p=partial / f=fail]: " o
    case "$o" in s) o="success";; p) o="partial";; f) o="fail";; *) continue;; esac
    break
  done
  read -r -p "Completion time in seconds (blank if not timed): " t
  read -r -p "Notes (optional): " n
  n="${n//,/;}"
  [[ -f "$LOG" ]] || echo "trial,timestamp,policy,outcome,time_s,notes" > "$LOG"
  echo "${i},$(date -Iseconds),${POLICY},${o},${t},${n}" >> "$LOG"
}

if command -v lerobot-rollout >/dev/null 2>&1; then
  for i in $(seq 1 "$EVAL_TRIALS"); do
    read -r -p "Trial ${i}/${EVAL_TRIALS}: reset cube and bowl, then press Enter to start... " _
    lerobot-rollout \
      --strategy.type=base \
      --policy.path="$POLICY" \
      --robot.type=so101_follower \
      --robot.port="$FOLLOWER_PORT" \
      --robot.id="$FOLLOWER_ID" \
      --robot.cameras="$CAMERAS" \
      --task="$TASK" \
      --duration="$EVAL_DURATION_S" \
      "$@"
    log_trial "$i"
  done
else
  command -v lerobot-record >/dev/null || { echo "Neither lerobot-rollout nor lerobot-record found. Run: conda activate lerobot" >&2; exit 1; }
  echo "lerobot-rollout not found; using lerobot-record (older LeRobot). Eval dataset: ${HF_USER}/eval_${DATASET_NAME}"
  lerobot-record \
    --robot.type=so101_follower \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id="$FOLLOWER_ID" \
    --robot.cameras="$CAMERAS" \
    --display_data=true \
    --dataset.repo_id="${HF_USER}/eval_${DATASET_NAME}" \
    --dataset.single_task="$TASK" \
    --dataset.num_episodes="$EVAL_TRIALS" \
    --dataset.episode_time_s="$EVAL_DURATION_S" \
    --dataset.reset_time_s="$RESET_TIME_S" \
    --dataset.push_to_hub=false \
    --policy.path="$POLICY" \
    "$@"
  echo "Now log the outcome and time of each trial you just watched."
  for i in $(seq 1 "$EVAL_TRIALS"); do log_trial "$i"; done
fi

python "$ROOT/analysis/summarize_trials.py" "$LOG"
