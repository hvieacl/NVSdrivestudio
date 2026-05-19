@echo off
setlocal
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
if "%SCENE_IDS%"=="" set "SCENE_IDS=0 1 2 3 4 5 6 7 8 9"
if "%DATA_ROOT%"=="" set "DATA_ROOT=data\\nuscenes\\processed_10Hz\\mini"

conda run -n "%ENV_NAME%" python nuscenes_workflow\semantic_masks\cli.py check --data_root "%DATA_ROOT%" --scene_ids "%SCENE_IDS%"
