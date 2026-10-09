<!--
Paste the BODY of this card into the dataset's README.md on the Hugging Face Hub.
LeRobot auto-generates a README with YAML front matter (including `configs:`); keep that front matter
and only add/merge the tags below.
-->
---
license: apache-2.0
task_categories:
  - robotics
tags:
  - LeRobot
  - so101
  - imitation-learning
  - pick-and-place
---

# SO-101 cube-to-bowl teleoperation dataset

30 teleoperated demonstrations of an SO-101 follower arm picking up a cube and placing it in a bowl, recorded with [LeRobot](https://github.com/huggingface/lerobot) during the HKUST USEL robot-arm imitation learning workshop. Used to train an ACT policy, published on the author's [Hugging Face profile](https://huggingface.co/sagnikroy75).

## Task
- Pick up a pink 7 x 7 cm cube and place it in a yellow bowl (10 cm radius).
- Success: the cube is released inside the bowl.

## Hardware and sensors
- Robot: SO-101 leader-follower pair (assembled from a kit) with Feetech servos. A human moved the leader arm; the follower mirrored it (`robot_type`: `so_follower`).
- Cameras: two Intel RealSense cameras (D435i and D455), RGB only: `top` (overhead) and `wrist.left` (wrist-mounted).
- Control rate: 30 fps.
- Scene: white background, clear lighting.

## Dataset structure
LeRobot dataset format v3.0 (`meta/`, `data/`, `videos/`).

| Feature | Shape / type | Description |
|---|---|---|
| `observation.images.top` | video, 480 x 640 x 3 (H x W x C), AV1, 30 fps | Overhead camera |
| `observation.images.wrist.left` | video, 640 x 480 x 3 (H x W x C), AV1, 30 fps | Wrist-mounted camera (portrait) |
| `observation.state` | float32, 6 | Measured follower positions: shoulder_pan, shoulder_lift, elbow_flex, wrist_flex, wrist_roll, gripper |
| `action` | float32, 6 | Leader arm positions for the same six joints, used as the target for the follower |
| `timestamp`, `frame_index`, `episode_index`, `index`, `task_index` | float / int | Bookkeeping |

## Statistics
| Metric | Value |
|---|---|
| Episodes | 30 (single `train` split, 0:30) |
| Total frames | 20,436 |
| Mean episode length | About 681 frames (22.7 s) |
| Tasks | 1 |

## Collection protocol
One operator. The cube started from the same fixed position in every episode and the bowl stayed fixed; the reset period was 20 s. See `data_collection_protocol.md` in the project repo.

## Intended use
Learning-from-demonstration experiments with low-cost arms (training and evaluating imitation policies such as ACT) and educational reference.

## Limitations
- Small dataset, one operator, one scene.
- A single fixed cube and bowl layout: a policy trained on this data should not be expected to generalise to other positions, lighting or objects.
- Calibration is specific to the arms used; reusing the data on other hardware needs care.

## Source and acknowledgements
Recorded by Sagnik Roy using LeRobot and workshop hardware provided by HKUST USEL. Built with Hugging Face LeRobot (Apache-2.0).

## Citation
```bibtex
@misc{roy_so101_cube_bowl,
  author       = {Sagnik Roy},
  title        = {SO-101 cube-to-bowl teleoperation dataset},
  year         = {2026},
  howpublished = {\url{https://huggingface.co/sagnikroy75}}
}
```
