# Train an ACT policy on the recorded dataset with LeRobot, logging to Weights & Biases (PowerShell).
# Thin wrapper around `lerobot-train`; settings live in config\default.ps1.
# Usage: .\scripts\train_act.ps1 [extra args]    (set $env:ALLOW_CPU = "1" to permit CPU training)
# Note: lerobot-train refuses to reuse an existing output_dir (unless resuming).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. "$Root\config\default.ps1"
if (Test-Path "$Root\config\local.ps1") { . "$Root\config\local.ps1" }

if (-not (Get-Command lerobot-train -ErrorAction SilentlyContinue)) { throw "lerobot-train not found. Run: conda activate lerobot" }

$Device = "cuda"
python -c "import sys, torch; print(f'torch {torch.__version__} | CUDA available: {torch.cuda.is_available()}'); sys.exit(0 if torch.cuda.is_available() else 1)"
if ($LASTEXITCODE -ne 0) {
  if ($env:ALLOW_CPU -eq "1") { Write-Warning "CUDA not available; training on CPU (very slow)."; $Device = "cpu" }
  else { throw "CUDA not available. Fix the PyTorch install (docs/setup_windows.md, step 4) or set `$env:ALLOW_CPU = '1'." }
}

$Out = "outputs/train/$POLICY_NAME"
$Extra = @($EXTRA_TRAIN_ARGS -split "\s+" | Where-Object { $_ })

lerobot-train `
  "--dataset.repo_id=$HF_USER/$DATASET_NAME" `
  "--policy.type=act" `
  "--output_dir=$Out" `
  "--job_name=$POLICY_NAME" `
  "--policy.device=$Device" `
  "--policy.repo_id=$HF_USER/$POLICY_NAME" `
  "--steps=$TRAIN_STEPS" `
  "--wandb.enable=true" `
  "--wandb.project=$WANDB_PROJECT" `
  @Extra @args

# Reproducibility: snapshot the exact package versions next to the checkpoints.
pip freeze | Out-File -Encoding utf8 "$Out/pip_freeze.txt"
Write-Host "Checkpoints + train_config.json in $Out ; package versions in $Out/pip_freeze.txt"
