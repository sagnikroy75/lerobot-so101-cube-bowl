# Data collection protocol

## Setup
| Item | Value |
|---|---|
| Task | Pick up the cube and place it in the bowl |
| Episodes recorded | 30 (20,436 frames at 30 fps; about 22.7 s per episode on average) |
| Operator | 1 (me) |
| Control | Leader arm teleoperation, follower mirrors joint positions |
| Cameras | Two Intel RealSense cameras (D435i, D455): `top` (overhead) and `wrist.left` (wrist-mounted), 30 fps |
| Cube | Pink, 7 x 7 cm |
| Bowl | Yellow, 10 cm radius |
| Lighting / background | Clear lighting, white background |
| Reset period | 20 s between episodes |

## Scene variation
- The cube was returned to the same fixed start position before every episode.
- The bowl stayed in a fixed position.
- The dataset therefore covers a single layout; it does not include varied cube or bowl positions.

## Per-episode procedure
1. Place the cube at its fixed start position.
2. Start recording; teleoperate: approach, grasp, lift, move over the bowl, release, return to rest.
3. `Right arrow` saves and moves on; `Left arrow` discards and re-records; `Esc` ends the session, encodes video and uploads.
4. During the reset period, return the arm to rest and re-place the cube.

## Evaluation protocol
- 5 autonomous trials with the cube and bowl in the same positions as in the demonstrations; reset by hand before each trial.
- Completion time measured with a stopwatch.
- Success = cube released inside the bowl. All 5 trials succeeded (5/5).
- Times (s): 9.34, 9.52, 9.88, 10.21, 10.67 (mean 9.92, best 9.34). Per-trial rows are in `results/eval_trials.csv`.

## Known limitations
- One operator, one scene, small dataset, one fixed cube and bowl layout.
