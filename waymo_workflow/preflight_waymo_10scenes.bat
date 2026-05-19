@echo off
setlocal
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
if "%SCENE_IDS%"=="" set "SCENE_IDS=0 1 4 8 32 102 109 114 149 156"
conda run -n "%ENV_NAME%" python waymo_workflow\preflight.py --scene_ids "%SCENE_IDS%" --check_imports
