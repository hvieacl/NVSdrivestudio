@echo off
setlocal EnableDelayedExpansion
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
if "%SCENE_IDS%"=="" set "SCENE_IDS=0 1 4 8 32 102 109 114 149 156"
if "%WORKERS%"=="" set "WORKERS=4"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=.\OutPut"
if "%PROJECT%"=="" set "PROJECT=waymo_training_10scenes"
if "%CONFIG_FILE%"=="" set "CONFIG_FILE=configs\omnire.yaml"
if "%DATASET%"=="" set "DATASET=waymo/3cams"
if "%START_TIMESTEP%"=="" set "START_TIMESTEP=0"
if "%END_TIMESTEP%"=="" set "END_TIMESTEP=-1"
set "PYTHONPATH=%CD%"
if not "%SKIP_PREPROCESS%"=="1" (
  conda run -n "%ENV_NAME%" python datasets/preprocess.py --data_root data/waymo/raw/ --target_dir data/waymo/processed --dataset waymo --split training --scene_ids %SCENE_IDS% --workers %WORKERS% --process_keys images lidar calib pose dynamic_masks objects
)
for %%S in (%SCENE_IDS%) do (
  conda run -n "%ENV_NAME%" python tools/train.py --config_file "%CONFIG_FILE%" --output_root "%OUTPUT_ROOT%" --project "%PROJECT%" --run_name "scene_%%S" dataset=%DATASET% data.scene_idx=%%S data.start_timestep=%START_TIMESTEP% data.end_timestep=%END_TIMESTEP%
)
