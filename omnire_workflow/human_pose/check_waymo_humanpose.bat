@echo off
setlocal
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
if "%SCENE_IDS%"=="" set "SCENE_IDS=0 1 4 8 32 102 109 114 149 156"
if "%DATA_ROOT%"=="" set "DATA_ROOT=data\waymo\processed\training"
if "%SMPL_MODEL%"=="" set "SMPL_MODEL=smpl_models\SMPL_NEUTRAL.pkl"
if "%REQUIRE_SMPL_MODEL%"=="" set "REQUIRE_SMPL_MODEL=1"
set "ARGS="
if "%REQUIRE_SMPL_MODEL%"=="1" set "ARGS=--require_smpl_model"
conda run -n "%ENV_NAME%" python omnire_workflow\human_pose\cli.py check --data_root "%DATA_ROOT%" --scene_ids "%SCENE_IDS%" --smpl_model "%SMPL_MODEL%" %ARGS%
