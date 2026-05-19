# Semantic Mask Workflow

nuScenes preprocessing extracts images, lidar, poses, coarse dynamic masks, and objects. It does not run semantic segmentation. OmniRe's nuScenes configs load `sky_masks` by default, so this step is required before training unless you explicitly override `data.pixel_source.load_sky_mask=False`.

## Setup

Create the SegFormer environment:

```bash
bash nuscenes_workflow/semantic_masks/setup_segformer_env.sh
```

Download `segformer.b5.1024x1024.city.160k.pth`:

```bash
bash nuscenes_workflow/semantic_masks/download_segformer_checkpoint.sh
```

The default target is `../SegFormer/pretrained/segformer.b5.1024x1024.city.160k.pth`.
You can override paths with `SEGFORMER_ROOT` and `SEGFORMER_CHECKPOINT`.

## Extract Masks

One scene:

```bash
SCENE_IDS="0" bash nuscenes_workflow/semantic_masks/extract_nuscenes_masks.sh
```

All ten scenes:

```bash
bash nuscenes_workflow/semantic_masks/extract_nuscenes_masks.sh
```

The script generates:

- `data/nuscenes/processed_10Hz/mini/<scene>/sky_masks`
- `data/nuscenes/processed_10Hz/mini/<scene>/fine_dynamic_masks` when `PROCESS_FINE_DYNAMIC_MASKS=1`

## Check

```bash
SCENE_IDS="0" bash nuscenes_workflow/semantic_masks/check_nuscenes_masks.sh
```

## Training Integration

`nuscenes_workflow/run_nuscenes_mini_10scenes.sh` checks sky masks before training. If masks are missing, it will try to generate them with the `segformer` environment. Set `AUTO_EXTRACT_MASKS=0` to fail fast instead, or `REQUIRE_SKY_MASKS=0` only for temporary debugging runs.
