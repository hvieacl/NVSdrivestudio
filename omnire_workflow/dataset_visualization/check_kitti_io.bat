@echo off
setlocal
if "%KITTI_ROOT%"=="" set "KITTI_ROOT=OutPut\waymo_training_10scenes\scene_114\dataset_visualization\kitti"
if "%CAMERA_ID%"=="" set "CAMERA_ID=0"
python -m omnire_workflow.dataset_visualization.check_kitti_io --kitti_root "%KITTI_ROOT%" --camera_id "%CAMERA_ID%"
