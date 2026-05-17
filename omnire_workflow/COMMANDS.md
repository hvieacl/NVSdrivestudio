# OmniRe Workflow Commands

Create the main environment:

```bash
bash omnire_workflow/setup_env.sh
```

Create the SegFormer mask environment:

```bash
bash omnire_workflow/semantic_masks/setup_segformer_env.sh
bash omnire_workflow/semantic_masks/download_segformer_checkpoint.sh
```

Check/download humanpose prerequisites:

```bash
SCENE_IDS="114" bash omnire_workflow/human_pose/check_waymo_humanpose.sh
bash omnire_workflow/human_pose/download_waymo_humanpose.sh
```

Run full preflight before long training:

```bash
SCENE_IDS="114" bash omnire_workflow/preflight_waymo_10scenes.sh
```

Extract required sky masks for one scene:

```bash
SCENE_IDS="114" bash omnire_workflow/semantic_masks/extract_waymo_masks.sh
```

Check masks:

```bash
SCENE_IDS="114" bash omnire_workflow/semantic_masks/check_waymo_masks.sh
```

Render an offset trajectory after training:

```bash
conda run -n drivestudio python omnire_workflow/render_offset_views.py \
  --resume_from OutPut/waymo_training_10scenes/scene_114/checkpoint_final.pth \
  --right_m 1.5 \
  --up_m 0.5 \
  --frames 150
```

Run one scene first:

```bash
PYTHONUNBUFFERED=1 SCENE_IDS="114" bash omnire_workflow/run_waymo_10scenes.sh 2>&1 | tee logs/runs/scene_114.log
```

Run all ten scenes:

```bash
PYTHONUNBUFFERED=1 bash omnire_workflow/run_waymo_10scenes.sh 2>&1 | tee logs/runs/waymo_10scenes.log
```

Create visualization environment and convert/check ten scenes:

```bash
bash omnire_workflow/dataset_visualization/setup_visualization_env.sh
bash omnire_workflow/dataset_visualization/convert_waymo_10scenes_to_kitti.sh
bash omnire_workflow/dataset_visualization/check_waymo_10scenes_io.sh
```
