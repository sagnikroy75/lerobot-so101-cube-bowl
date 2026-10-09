# Run the trained ACT policy autonomously on the follower arm and log each trial (PowerShell).
# Uses `lerobot-rollout` (newer LeRobot); falls back to `lerobot-record --policy.path` (<= v0.5.1).
# For every trial you enter the outcome and the completion time (stopwatch, seconds); rows are
# appended to results\eval_trials.csv. Summarise with analysis\summarize_trials.py.
# Usage: .\scripts\eval_act.ps1 [extra args passed to the LeRobot command]
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. "$Root\config\default.ps1"
if (Test-Path "$Root\config\local.ps1") { . "$Root\config\local.ps1" }

$Policy = if ($POLICY_PATH) { $POLICY_PATH } else { "$HF_USER/$POLICY_NAME" }
$Log = "$Root\results\eval_trials.csv"
# The camera config must match what was used when the dataset was recorded.
$Cameras = $CAMERA_CONFIG

function Add-Trial([int]$i) {
  do { $o = (Read-Host "Trial $i outcome [s=success / p=partial / f=fail]").Trim().ToLower() } until ($o -in @("s", "p", "f"))
  $outcome = @{ s = "success"; p = "partial"; f = "fail" }[$o]
  $t = (Read-Host "Completion time in seconds (blank if not timed)").Trim()
  $notes = (Read-Host "Notes (optional)") -replace ",", ";"
  if (-not (Test-Path $Log)) { [System.IO.File]::WriteAllText($Log, "trial,timestamp,policy,outcome,time_s,notes`n") }
  $line = "$i,$(Get-Date -Format s),$Policy,$outcome,$t,$notes`n"
  [System.IO.File]::AppendAllText($Log, $line)
}

if (Get-Command lerobot-rollout -ErrorAction SilentlyContinue) {
  for ($i = 1; $i -le [int]$EVAL_TRIALS; $i++) {
    Read-Host "Trial $i/${EVAL_TRIALS}: reset cube and bowl, then press Enter to start" | Out-Null
    lerobot-rollout `
      "--strategy.type=base" `
      "--policy.path=$Policy" `
      "--robot.type=so101_follower" `
      "--robot.port=$FOLLOWER_PORT" `
      "--robot.id=$FOLLOWER_ID" `
      "--robot.cameras=$Cameras" `
      "--task=$TASK" `
      "--duration=$EVAL_DURATION_S" `
      @args
    Add-Trial $i
  }
}
else {
  if (-not (Get-Command lerobot-record -ErrorAction SilentlyContinue)) { throw "Neither lerobot-rollout nor lerobot-record found. Run: conda activate lerobot" }
  Write-Host "lerobot-rollout not found; using lerobot-record (older LeRobot). Eval dataset: $HF_USER/eval_$DATASET_NAME"
  lerobot-record `
    "--robot.type=so101_follower" `
    "--robot.port=$FOLLOWER_PORT" `
    "--robot.id=$FOLLOWER_ID" `
    "--robot.cameras=$Cameras" `
    "--display_data=true" `
    "--dataset.repo_id=$HF_USER/eval_$DATASET_NAME" `
    "--dataset.single_task=$TASK" `
    "--dataset.num_episodes=$EVAL_TRIALS" `
    "--dataset.episode_time_s=$EVAL_DURATION_S" `
    "--dataset.reset_time_s=$RESET_TIME_S" `
    "--dataset.push_to_hub=false" `
    "--policy.path=$Policy" `
    @args
  Write-Host "Now log the outcome and time of each trial you just watched."
  for ($i = 1; $i -le [int]$EVAL_TRIALS; $i++) { Add-Trial $i }
}

python "$Root\analysis\summarize_trials.py" $Log
