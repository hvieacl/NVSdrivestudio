# Human Pose and SMPL Workflow

OmniRe's Waymo config enables SMPL by default:

- `data.pixel_source.load_smpl=True`
- `model.SMPLNodes` exists in `configs/omnire.yaml`

That means two inputs are needed before training:

- `smpl_models/SMPL_NEUTRAL.pkl`
- `data/waymo/processed/training/<scene>/humanpose/smpl.pkl`

## Check

```bash
SCENE_IDS="114" bash omnire_workflow/human_pose/check_waymo_humanpose.sh
```

## SMPL Model

The SMPL neutral model is license gated and cannot be downloaded automatically by this repo. Download SMPL v1.1 from:

```text
https://smpl.is.tue.mpg.de/download.php
```

Then copy:

```text
SMPL_python_v.1.1.0/smpl/models/basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl
```

to:

```text
smpl_models/SMPL_NEUTRAL.pkl
```

## Download Preprocessed Waymo Human Pose

DriveStudio provides preprocessed humanpose for the Waymo example scenes:

```bash
bash omnire_workflow/human_pose/download_waymo_humanpose.sh
```

If Google Drive is unavailable on the server, download `waymo_processed_humanpose.zip` manually using the ID in `docs/HumanPose.md`, place it under `data/`, then run:

```bash
unzip -o data/waymo_processed_humanpose.zip -d data
```

## Run Human Pose Extraction Yourself

Use this only when the preprocessed package does not include your scene:

```bash
bash omnire_workflow/human_pose/setup_4dhumans_env.sh
SCENE_IDS="114" bash omnire_workflow/human_pose/extract_waymo_humanpose.sh
```

The extraction path is slower and may download additional 4D-Humans/PHALP checkpoints.
