# Hardware build

I assembled the **leader and follower SO-101 arms from a kit** and calibrated both with `lerobot-calibrate`. The SO-101 is an open-source design by TheRobotStudio; the mechanical design is not mine.

The specs below are the standard SO-101 bill of materials; servo ratios and supplies can vary by kit vendor.

## Mechanical
- Two 6-DoF arms: a leader moved by hand and a follower that mirrors it.
- Structural parts: 3D-printed frame supplied with the kit.
- Fasteners: M2 and M3 socket-head screws and nuts.
- Bearings: 2x MF106ZZ (6x10x3 mm) in the gripper mechanism.
- Mounting: 4 desk C-clamps; an unclamped follower can drag itself off the desk at speed.

## Actuators
12 Feetech STS3215 serial bus servos (6 per arm) with absolute 12-bit magnetic encoders.

| Joint | Leader (easy to back-drive) | Follower (payload, precision) |
|---|---|---|
| 2 | 1x 7.4 V, 1:345 | 1x 12 V, 1:345 |
| 1 and 3 | 2x 7.4 V, 1:191 | 2x 12 V, 1:345 |
| 4, 5 and 6 (gripper) | 3x 7.4 V, 1:147 | 3x 12 V, 1:345 |

## Electronics and power
Each arm has its own bus and power supply.

| Component | Qty | Specification |
|---|---|---|
| Motor control board | 2 | Waveshare bus servo adapter (USB to TTL) |
| Leader power supply | 1 | 5 V 4 A DC, 5.5 x 2.1 mm barrel (underpowers the 7.4 V servos on purpose so they back-drive by hand) |
| Follower power supply | 1 | 12 V, 2-5 A DC, 5.5 x 2.1 mm barrel |
| USB-C cables | 2 | Control boards to host computer |

No separate microcontroller sits between the arms: the host computer reads the leader through one adapter and commands the follower through the other.

## Cameras
Two Intel RealSense cameras (D435i and D455), recorded as RGB video at 30 fps (no depth stream):
- `top`: overhead view of the workspace, 640 x 480.
- `wrist.left`: wrist-mounted camera, recorded 480 wide x 640 high (portrait).

## Scene
- Cube: pink, 7 x 7 cm.
- Bowl: yellow, 10 cm radius.
- Background: white; clear lighting.

## Host and software
- Host: Windows PC set up with the workshop guide ([setup_windows.md](setup_windows.md)).
- Hugging Face LeRobot with `scservo_sdk` for servo communication.
- Calibration: `lerobot-calibrate` run once per arm; the same IDs are reused in `config/local.*`.

Photos of the build can go in `assets/`.
