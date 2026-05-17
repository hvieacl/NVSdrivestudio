# OmniRe Environment Plan

Recommended conda environments:

| Environment | Use |
|---|---|
| `drivestudio` | OmniRe training, Waymo preprocessing, eval, offset rendering |
| `segformer` | sky/fine dynamic mask extraction |
| `4D-humans` | optional human pose extraction when preprocessed SMPL data is unavailable |
| `waymo-kitti-viz` | Waymo-to-KITTI conversion and dataset visualization |

## `drivestudio`

Used for the core DriveStudio/OmniRe code path:

```bash
bash omnire_workflow/setup_env.sh
```

Key packages include PyTorch 2.0 CUDA 11.7, Waymo Open Dataset devkit, PyTorch3D, gsplat, nvdiffrast, and SMPL-X.

## `segformer`

Used only for semantic mask extraction. This is separate because the upstream SegFormer workflow depends on older PyTorch/mmcv versions.

```bash
bash omnire_workflow/semantic_masks/setup_segformer_env.sh
```

After setup, download `segformer.b5.1024x1024.city.160k.pth` into `../SegFormer/pretrained/`, or set `SEGFORMER_CHECKPOINT` to its actual path.

## `waymo-kitti-viz`

Used for Waymo-to-KITTI conversion and point cloud/box visualization:

```bash
bash omnire_workflow/dataset_visualization/setup_visualization_env.sh
```

## Manual Assets

These files cannot always be downloaded reliably or automatically from cloud servers:

| Asset | Default path | Workflow |
|---|---|---|
| SegFormer B5 Cityscapes checkpoint | `../SegFormer/pretrained/segformer.b5.1024x1024.city.160k.pth` | `bash omnire_workflow/semantic_masks/download_segformer_checkpoint.sh` |
| SMPL neutral model | `smpl_models/SMPL_NEUTRAL.pkl` | Download from SMPL official website due to license |
| Waymo preprocessed human pose | `data/waymo/processed/training/<scene>/humanpose/smpl.pkl` | `bash omnire_workflow/human_pose/download_waymo_humanpose.sh` |
