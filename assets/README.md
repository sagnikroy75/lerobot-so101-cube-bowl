# assets/

| File | Description |
|---|---|
| `wandb_loss.png` | Training loss curve from the Weights & Biases run (shown in the main README). |

Optional additions
- `demo.gif`: 8-15 s clip of the autonomous rollout. Make it with `ffmpeg -i demo.mp4 -vf "fps=12,scale=720:-1:flags=lanczos" -loop 0 demo.gif`, then embed it in the README with `![Autonomous rollout](assets/demo.gif)`.
- `action_trajectories.png` and `action_vs_state.png`: run `python analysis/plot_actions.py --repo-id sagnikroy75/so101_cube_bowl` (use your dataset repo id); the plots are written to this folder.
- `setup.jpg`: photo of the arms, both cameras, cube and bowl.

Keep the folder small (under ~15 MB) and never commit tokens, screenshots showing tokens, raw dataset `.mp4` recordings or model checkpoints.
