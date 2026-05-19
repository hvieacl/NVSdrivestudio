@echo off
setlocal
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
if "%SCENE_IDS%"=="" set "SCENE_IDS=0 1 4 8 32 102 109 114 149 156"
if "%DATA_ROOT%"=="" set "DATA_ROOT=data\waymo\processed\training"

conda run -n "%ENV_NAME%" python waymo_workflow\semantic_masks\cli.py check --data_root "%DATA_ROOT%" --scene_ids "%SCENE_IDS%"
