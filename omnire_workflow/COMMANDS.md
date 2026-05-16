# OmniRe Workflow Commands

Create the main environment:

```bash
bash omnire_workflow/setup_env.sh
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
SCENE_IDS="114" bash omnire_workflow/run_waymo_10scenes.sh
```

Run all ten scenes:

```bash
bash omnire_workflow/run_waymo_10scenes.sh
```

Create visualization environment and convert/check ten scenes:

```bash
bash omnire_workflow/dataset_visualization/setup_visualization_env.sh
bash omnire_workflow/dataset_visualization/convert_waymo_10scenes_to_kitti.sh
bash omnire_workflow/dataset_visualization/check_waymo_10scenes_io.sh
```
