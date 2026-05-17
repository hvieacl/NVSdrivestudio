@echo off
setlocal EnableDelayedExpansion
if "%SEGFORMER_ENV_NAME%"=="" set "SEGFORMER_ENV_NAME=segformer"
if "%SCENE_IDS%"=="" set "SCENE_IDS=0 1 4 8 32 102 109 114 149 156"
if "%DATA_ROOT%"=="" set "DATA_ROOT=data\waymo\processed\training"
if "%SEGFORMER_ROOT%"=="" set "SEGFORMER_ROOT=%CD%\..\SegFormer"
if "%SEGFORMER_CHECKPOINT%"=="" set "SEGFORMER_CHECKPOINT=%SEGFORMER_ROOT%\pretrained\segformer.b5.1024x1024.city.160k.pth"
if "%MASK_DEVICE%"=="" set "MASK_DEVICE=cuda:0"
if "%PROCESS_FINE_DYNAMIC_MASKS%"=="" set "PROCESS_FINE_DYNAMIC_MASKS=1"

set "EXTRA_ARGS="
if "%PROCESS_FINE_DYNAMIC_MASKS%"=="1" set "EXTRA_ARGS=--process_dynamic_mask"

conda run -n "%SEGFORMER_ENV_NAME%" python omnire_workflow\semantic_masks\cli.py extract --data_root "%DATA_ROOT%" --scene_ids "%SCENE_IDS%" --segformer_path "%SEGFORMER_ROOT%" --checkpoint "%SEGFORMER_CHECKPOINT%" --device "%MASK_DEVICE%" %EXTRA_ARGS%
conda run -n "%SEGFORMER_ENV_NAME%" python omnire_workflow\semantic_masks\cli.py check --data_root "%DATA_ROOT%" --scene_ids "%SCENE_IDS%"
