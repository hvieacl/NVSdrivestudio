# Waymo Dataset Visualization Flow

This folder contains the Waymo dataset inspection workflow used to compare raw sensor/label data with OmniRe reconstruction output.

Core logic lives in the Python package:

```bash
python -m omnire_workflow.dataset_visualization.cli --help
```

The `.sh` files are Linux cloud-server launchers. The `.bat` files are Windows fallbacks.

## Linux Flow

Create the visualization environment:

```bash
bash omnire_workflow/dataset_visualization/setup_visualization_env.sh
```

Convert all ten local Waymo scenes into reconstruction-adjacent folders:

```bash
bash omnire_workflow/dataset_visualization/convert_waymo_10scenes_to_kitti.sh
```

Converted output layout:

```text
OutPut/waymo_training_10scenes/scene_<idx>/dataset_visualization/kitti
```

Check all converted folders:

```bash
bash omnire_workflow/dataset_visualization/check_waymo_10scenes_io.sh
```

Open a scene if the server has GUI/VNC/X11 support:

```bash
SCENE_IDX=114 END_FRAME=80 bash omnire_workflow/dataset_visualization/view_waymo_scene.sh
```

## Notes

- Conversion and I/O checks can run headlessly.
- The interactive viewer requires GUI support.
- The viewer source is bundled under `external_tools/3D-Detection-Tracking-Viewer`.
- The converter source is bundled under `external_tools/waymo_kitti_converter`.
