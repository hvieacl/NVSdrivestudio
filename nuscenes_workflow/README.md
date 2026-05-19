# nuScenes Mini Workflow

This workflow runs the 10 scenes in `v1.0-mini` with OmniRe training and built-in
LiDAR visualization (`render.vis_lidar=True`). It intentionally does not include
Waymo-to-KITTI conversion or dataset visualization tools.

## Server Quick Start

```bash
cd ~/autodl-tmp/NVSdrivestudio
source /root/miniconda3/etc/profile.d/conda.sh
conda activate drivestudio
mkdir -p logs/runs
```

Install the nuScenes devkit if it is not already available:

```bash
bash nuscenes_workflow/setup_nuscenes_deps.sh \
  2>&1 | tee logs/runs/setup_nuscenes_deps.log
```

Download nuScenes mini:

```bash
bash nuscenes_workflow/download_nuscenes_mini.sh \
  2>&1 | tee logs/runs/download_nuscenes_mini.log
```

Run all 10 scenes:

```bash
PYTHONUNBUFFERED=1 bash nuscenes_workflow/run_nuscenes_mini_10scenes.sh \
  2>&1 | tee logs/runs/nuscenes_mini_10scenes.log
```

## Defaults

- Raw data: `data/nuscenes/raw`
- Processed data: `data/nuscenes/processed_10Hz/mini`
- Scenes: `0 1 2 3 4 5 6 7 8 9`
- Dataset config: `nuscenes/6cams`
- Training config: `configs/omnire_nuscenes_no_smpl.yaml`
- Rendering: `render.vis_lidar=True`, `render.render_full=True`, `render.render_test=False`
- SMPL: disabled by default with `data.pixel_source.load_smpl=False`

## Useful Overrides

Process only one scene:

```bash
SCENE_IDS="0" PYTHONUNBUFFERED=1 bash nuscenes_workflow/run_nuscenes_mini_10scenes.sh
```

Skip preprocessing after data is processed:

```bash
SCENE_IDS="0 1" SKIP_PREPROCESS=1 PYTHONUNBUFFERED=1 \
bash nuscenes_workflow/run_nuscenes_mini_10scenes.sh
```

Use 3 cameras instead of 6:

```bash
DATASET="nuscenes/3cams" EXTRA_ARGS="render.vis_lidar=True render.render_full=True render.render_test=False data.pixel_source.load_smpl=False" \
bash nuscenes_workflow/run_nuscenes_mini_10scenes.sh
```
