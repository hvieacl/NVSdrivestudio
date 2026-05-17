# Semantic Mask Workflow

Waymo preprocessing extracts images, lidar, poses, coarse dynamic masks, and objects. It does not run semantic segmentation. OmniRe's Waymo configs load `sky_masks` by default, so this step is required before training unless you explicitly override `data.pixel_source.load_sky_mask=False`.

## Setup

Create the SegFormer environment:

```bash
bash omnire_workflow/semantic_masks/setup_segformer_env.sh
```

Download `segformer.b5.1024x1024.city.160k.pth` and place it under:

```text
../SegFormer/pretrained/segformer.b5.1024x1024.city.160k.pth
```

You can override paths with `SEGFORMER_ROOT` and `SEGFORMER_CHECKPOINT`.

## Extract Masks

One scene:

```bash
SCENE_IDS="114" bash omnire_workflow/semantic_masks/extract_waymo_masks.sh
```

All ten scenes:

```bash
bash omnire_workflow/semantic_masks/extract_waymo_masks.sh
```

The script generates:

- `data/waymo/processed/training/<scene>/sky_masks`
- `data/waymo/processed/training/<scene>/fine_dynamic_masks` when `PROCESS_FINE_DYNAMIC_MASKS=1`

## Check

```bash
SCENE_IDS="114" bash omnire_workflow/semantic_masks/check_waymo_masks.sh
```

## Training Integration

`omnire_workflow/run_waymo_10scenes.sh` checks sky masks before training. If masks are missing, it will try to generate them with the `segformer` environment. Set `AUTO_EXTRACT_MASKS=0` to fail fast instead, or `REQUIRE_SKY_MASKS=0` only for temporary debugging runs.
