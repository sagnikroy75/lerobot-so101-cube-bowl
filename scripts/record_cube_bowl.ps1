# Record teleoperated demonstrations for the SO-101 cube-to-bowl task (PowerShell).
# Thin wrapper around `lerobot-record`; settings live in config\default.ps1.
# Usage (Anaconda PowerShell Prompt, env active): .\scripts\record_cube_bowl.ps1 [extra args]
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. "$Root\config\default.ps1"
if (Test-Path "$Root\config\local.ps1") { . "$Root\config\local.ps1" }

if (-not (Get-Command lerobot-record -ErrorAction SilentlyContinue)) { throw "lerobot-record not found. Run: conda activate lerobot" }

$Cameras = $CAMERA_CONFIG
$Extra = @($EXTRA_RECORD_ARGS -split "\s+" | Where-Object { $_ })

Write-Host "Recording $NUM_EPISODES episodes -> $HF_USER/$DATASET_NAME"
Write-Host "Keys: Right arrow = save & next | Left arrow = discard & redo | Esc = stop, encode & upload"

lerobot-record `
  "--robot.type=so101_follower" `
  "--robot.port=$FOLLOWER_PORT" `
  "--robot.id=$FOLLOWER_ID" `
  "--robot.cameras=$Cameras" `
  "--teleop.type=so101_leader" `
  "--teleop.port=$LEADER_PORT" `
  "--teleop.id=$LEADER_ID" `
  "--display_data=true" `
  "--dataset.repo_id=$HF_USER/$DATASET_NAME" `
  "--dataset.single_task=$TASK" `
  "--dataset.num_episodes=$NUM_EPISODES" `
  "--dataset.reset_time_s=$RESET_TIME_S" `
  "--dataset.push_to_hub=true" `
  @Extra @args
