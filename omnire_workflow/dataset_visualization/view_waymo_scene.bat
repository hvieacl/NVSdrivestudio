@echo off
setlocal
if "%VIZ_ENV_NAME%"=="" set "VIZ_ENV_NAME=waymo-kitti-viz"
if "%SCENE_IDX%"=="" set "SCENE_IDX=114"
if "%PROJECT_OUTPUT%"=="" set "PROJECT_OUTPUT=OutPut\waymo_training_10scenes"
if "%CAMERA_ID%"=="" set "CAMERA_ID=0"
if "%CLASSES%"=="" set "CLASSES=Car"
if "%START_FRAME%"=="" set "START_FRAME=0"
if "%END_FRAME%"=="" set "END_FRAME=-1"
conda run -n "%VIZ_ENV_NAME%" python omnire_workflow\dataset_visualization\view_kitti_scene.py --kitti_root "%PROJECT_OUTPUT%\scene_%SCENE_IDX%\dataset_visualization\kitti" --camera_id "%CAMERA_ID%" --classes "%CLASSES%" --start_frame "%START_FRAME%" --end_frame "%END_FRAME%"
