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
if "%REQUIRE_SKY_MASKS%"=="" set "REQUIRE_SKY_MASKS=1"
if "%AUTO_EXTRACT_MASKS%"=="" set "AUTO_EXTRACT_MASKS=1"
if "%SEGFORMER_ENV_NAME%"=="" set "SEGFORMER_ENV_NAME=segformer"
if "%SEGFORMER_ROOT%"=="" set "SEGFORMER_ROOT=%CD%\..\SegFormer"
if "%SEGFORMER_CHECKPOINT%"=="" set "SEGFORMER_CHECKPOINT=%SEGFORMER_ROOT%\pretrained\segformer.b5.1024x1024.city.160k.pth"
if "%MASK_DEVICE%"=="" set "MASK_DEVICE=cuda:0"
if "%PROCESS_FINE_DYNAMIC_MASKS%"=="" set "PROCESS_FINE_DYNAMIC_MASKS=1"
if "%REQUIRE_HUMANPOSE%"=="" set "REQUIRE_HUMANPOSE=1"
if "%AUTO_DOWNLOAD_HUMANPOSE%"=="" set "AUTO_DOWNLOAD_HUMANPOSE=1"
if "%HUMANPOSE_ARCHIVE_NAME%"=="" set "HUMANPOSE_ARCHIVE_NAME=waymo_processed_humanpose.zip"
if "%REQUIRE_SMPL_MODEL%"=="" set "REQUIRE_SMPL_MODEL=1"
if "%SMPL_MODEL%"=="" set "SMPL_MODEL=smpl_models\SMPL_NEUTRAL.pkl"
if "%EXTRA_ARGS%"=="" set "EXTRA_ARGS="
set "PYTHONPATH=%CD%"
if not "%SKIP_PREPROCESS%"=="1" (
  conda run -n "%ENV_NAME%" python datasets/preprocess.py --data_root data/waymo/raw/ --target_dir data/waymo/processed --dataset waymo --split training --scene_ids %SCENE_IDS% --workers %WORKERS% --process_keys images lidar calib pose dynamic_masks objects
)
if "%REQUIRE_SKY_MASKS%"=="1" (
  echo [workflow] Checking Waymo sky masks for scenes: %SCENE_IDS%
  conda run -n "%ENV_NAME%" python omnire_workflow\semantic_masks\cli.py check --data_root data\waymo\processed\training --scene_ids "%SCENE_IDS%"
  if errorlevel 1 (
    if not "%AUTO_EXTRACT_MASKS%"=="1" (
      echo [ERROR] Missing sky masks. Run omnire_workflow\semantic_masks\extract_waymo_masks.bat first, or set AUTO_EXTRACT_MASKS=1.
      exit /b 1
    )
    set "MASK_ARGS="
    if "%PROCESS_FINE_DYNAMIC_MASKS%"=="1" set "MASK_ARGS=--process_dynamic_mask"
    conda run -n "%SEGFORMER_ENV_NAME%" python omnire_workflow\semantic_masks\cli.py extract --data_root data\waymo\processed\training --scene_ids "%SCENE_IDS%" --segformer_path "%SEGFORMER_ROOT%" --checkpoint "%SEGFORMER_CHECKPOINT%" --device "%MASK_DEVICE%" !MASK_ARGS!
    conda run -n "%ENV_NAME%" python omnire_workflow\semantic_masks\cli.py check --data_root data\waymo\processed\training --scene_ids "%SCENE_IDS%"
    if errorlevel 1 exit /b 1
  )
)
if "%REQUIRE_HUMANPOSE%"=="1" (
  echo [workflow] Checking Waymo humanpose/SMPL prerequisites for scenes: %SCENE_IDS%
  set "HUMANPOSE_ARGS="
  if "%REQUIRE_SMPL_MODEL%"=="1" set "HUMANPOSE_ARGS=--require_smpl_model"
  conda run -n "%ENV_NAME%" python omnire_workflow\human_pose\cli.py check --data_root data\waymo\processed\training --scene_ids "%SCENE_IDS%" --smpl_model "%SMPL_MODEL%" !HUMANPOSE_ARGS!
  if errorlevel 1 (
    if "%AUTO_DOWNLOAD_HUMANPOSE%"=="1" (
      echo [workflow] Trying to download DriveStudio preprocessed Waymo humanpose package.
      conda run -n "%ENV_NAME%" python -m pip install gdown
      conda run -n "%ENV_NAME%" python omnire_workflow\human_pose\cli.py download-preprocessed --target_dir data --archive_name "%HUMANPOSE_ARCHIVE_NAME%"
    )
    conda run -n "%ENV_NAME%" python omnire_workflow\human_pose\cli.py check --data_root data\waymo\processed\training --scene_ids "%SCENE_IDS%" --smpl_model "%SMPL_MODEL%" !HUMANPOSE_ARGS!
    if errorlevel 1 exit /b 1
  )
)
for %%S in (%SCENE_IDS%) do (
  echo [workflow] Training scene %%S
  conda run -n "%ENV_NAME%" python tools/train.py --config_file "%CONFIG_FILE%" --output_root "%OUTPUT_ROOT%" --project "%PROJECT%" --run_name "scene_%%S" dataset=%DATASET% data.scene_idx=%%S data.start_timestep=%START_TIMESTEP% data.end_timestep=%END_TIMESTEP% %EXTRA_ARGS%
)
