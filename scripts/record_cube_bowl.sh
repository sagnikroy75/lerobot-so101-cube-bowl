#!/usr/bin/env bash
# Record teleoperated demonstrations for the SO-101 cube-to-bowl task.
# Thin wrapper around `lerobot-record`; all settings live in config/default.env.
# Usage: scripts/record_cube_bowl.sh [extra lerobot-record args...]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/config/default.env"
if [[ -f "$ROOT/config/local.env" ]]; then source "$ROOT/config/local.env"; fi

command -v lerobot-record >/dev/null || { echo "lerobot-record not found. Run: conda activate lerobot" >&2; exit 1; }

CAMERAS="$CAMERA_CONFIG"

echo "Recording ${NUM_EPISODES} episodes -> ${HF_USER}/${DATASET_NAME}"
echo "Keys: Right arrow = save & next | Left arrow = discard & redo | Esc = stop, encode & upload"

# EXTRA_RECORD_ARGS is intentionally unquoted so it splits into separate flags.
# shellcheck disable=SC2086
lerobot-record \
  --robot.type=so101_follower \
  --robot.port="$FOLLOWER_PORT" \
  --robot.id="$FOLLOWER_ID" \
  --robot.cameras="$CAMERAS" \
  --teleop.type=so101_leader \
  --teleop.port="$LEADER_PORT" \
  --teleop.id="$LEADER_ID" \
  --display_data=true \
  --dataset.repo_id="${HF_USER}/${DATASET_NAME}" \
  --dataset.single_task="$TASK" \
  --dataset.num_episodes="$NUM_EPISODES" \
  --dataset.reset_time_s="$RESET_TIME_S" \
  --dataset.push_to_hub=true \
  $EXTRA_RECORD_ARGS \
  "$@"
