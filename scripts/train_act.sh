#!/usr/bin/env bash
# Train an ACT policy on the recorded dataset with LeRobot, logging to Weights & Biases.
# Thin wrapper around `lerobot-train`; settings live in config/default.env.
# Usage: scripts/train_act.sh [extra lerobot-train args...]
# Note: lerobot-train refuses to reuse an existing output_dir (unless resuming).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/config/default.env"
if [[ -f "$ROOT/config/local.env" ]]; then source "$ROOT/config/local.env"; fi

command -v lerobot-train >/dev/null || { echo "lerobot-train not found. Run: conda activate lerobot" >&2; exit 1; }

DEVICE="cuda"
if ! python - <<'PY'
import sys, torch
print(f"torch {torch.__version__} | CUDA available: {torch.cuda.is_available()}")
sys.exit(0 if torch.cuda.is_available() else 1)
PY
then
  if [[ "${ALLOW_CPU:-0}" == "1" ]]; then
    echo "CUDA not available; training on CPU (very slow)." >&2; DEVICE="cpu"
  else
    echo "CUDA not available. Fix the PyTorch install (docs/setup_windows.md, step 4) or set ALLOW_CPU=1." >&2; exit 1
  fi
fi

OUT="outputs/train/${POLICY_NAME}"

# shellcheck disable=SC2086
lerobot-train \
  --dataset.repo_id="${HF_USER}/${DATASET_NAME}" \
  --policy.type=act \
  --output_dir="$OUT" \
  --job_name="$POLICY_NAME" \
  --policy.device="$DEVICE" \
  --policy.repo_id="${HF_USER}/${POLICY_NAME}" \
  --steps="$TRAIN_STEPS" \
  --wandb.enable=true \
  --wandb.project="$WANDB_PROJECT" \
  $EXTRA_TRAIN_ARGS \
  "$@"

# Reproducibility: snapshot the exact package versions next to the checkpoints.
pip freeze > "$OUT/pip_freeze.txt"
echo "Checkpoints + train_config.json in $OUT ; package versions in $OUT/pip_freeze.txt"
