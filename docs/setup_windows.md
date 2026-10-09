# Windows environment setup

This follows the **HKUST USEL "LeRobot environment setup guide (Windows)"** workshop handout (dated 16/08/2026). Commands are reproduced from that handout; version numbers are the ones it specifies. Steps 9-11 (hardware bring-up) come from the LeRobot documentation, not the handout.

Run everything in **Anaconda PowerShell Prompt** (type it in the Windows search bar).

## 1. Install Miniconda (or Miniforge)
- Miniconda: <https://www.anaconda.com/download/success?reg=skipped>
- Miniforge: <https://conda-forge.org/download/>
- Install "Just Me". Leave "Add installation to my PATH" **unchecked** (the installer recommends against it).
- One conda distribution is enough in practice. The handout shows both installers.

## 2. Configure conda and create the environment
```powershell
conda config --set channel_priority strict   # avoids DLL errors on Windows
conda create -y -n lerobot python=3.12
# If conda asks you to accept channel Terms of Service, run the `conda tos accept ...` commands it prints.
conda activate lerobot                        # prompt must change from (base) to (lerobot); repeat in every new shell
```

## 3. Install ffmpeg (video decoding)
```powershell
conda install -c conda-forge ffmpeg
ffmpeg -version
```

## 4. Install PyTorch and torchvision (NVIDIA GPU only)
Skip this step if the machine has no dedicated NVIDIA GPU.
```powershell
pip install torch==2.11.0 torchvision==0.26.0 --force-reinstall --index-url https://download.pytorch.org/whl/cu128
```

## 5. Install LeRobot (one line at a time)
```powershell
pip install lerobot
pip install 'lerobot[core_scripts,training]'
pip install 'lerobot[feetech]'
```

## 6. Verify
```powershell
python
>>> import lerobot
>>> import scservo_sdk
>>> import torch
>>> torch.cuda.is_available()   # True on a GPU machine (the handout's screenshot shows False on a machine without one)
>>> exit()
```
`scripts/train_act.*` refuses to train on CPU unless you set `ALLOW_CPU=1`.

## 7. Hugging Face
```powershell
hf auth login        # choose "Paste an access token"; create a Write token under Settings -> Access Tokens
hf auth whoami
hf auth logout       # on shared computers
```
Never commit a token. `.gitignore` excludes `config/local.*`, `.env` and `*.token`; crop screenshots so no token is visible.

## 8. Weights & Biases (optional, monitoring only)
```powershell
wandb login
# or: $env:WANDB_API_KEY = "your-40-char-key-here"
```

## 9. Hardware bring-up (LeRobot docs; confirm what you actually ran)
```powershell
lerobot-find-port                # run once per arm to get COM ports
lerobot-find-cameras             # camera indices (two cameras)
lerobot-calibrate --robot.type=so101_follower --robot.port=COM3 --robot.id=my_follower_arm
lerobot-calibrate --teleop.type=so101_leader  --teleop.port=COM4 --teleop.id=my_leader_arm
```
Use the same IDs later in `config/local.*`; that is how LeRobot finds the calibration files.

## 10. Smoke-test teleoperation before recording
```powershell
lerobot-teleoperate --robot.type=so101_follower --robot.port=COM3 --robot.id=my_follower_arm `
  --teleop.type=so101_leader --teleop.port=COM4 --teleop.id=my_leader_arm --display_data=true
```

## 11. Run the pipeline
Copy `config/default.ps1` to `config/local.ps1`, set the ports, camera indices and arm IDs, then:
```powershell
.\scripts\record_cube_bowl.ps1
.\scripts\train_act.ps1
.\scripts\eval_act.ps1
```
The `.sh` versions are equivalent for Git Bash / WSL / Linux / macOS (`config/default.env` -> `config/local.env`).

## 12. Record your own environment (reproducibility)
```powershell
pip show lerobot                 # note the version in README.md
pip freeze > environment_freeze.txt
conda env export --no-builds > environment.yml
```
`scripts/train_act.*` also writes `pip_freeze.txt` next to the checkpoints.

## Flags differ between LeRobot versions
LeRobot's CLI changes between releases (for example, policy rollout moved from `lerobot-record --policy.path` to `lerobot-rollout`). If a flag is rejected, run `<command> --help` and adjust `scripts/` accordingly.
