@echo off
setlocal
if "%HUMANS4D_ENV_NAME%"=="" set "HUMANS4D_ENV_NAME=4D-humans"
if "%SCENE_IDS%"=="" set "SCENE_IDS=0 1 4 8 32 102 109 114 149 156"
if "%DATA_ROOT%"=="" set "DATA_ROOT=data\waymo\processed\training"
if "%SAVE_TEMP%"=="" set "SAVE_TEMP=0"
if "%VERBOSE%"=="" set "VERBOSE=0"
if "%FPS%"=="" set "FPS=12"
set "ARGS="
if "%SAVE_TEMP%"=="1" set "ARGS=%ARGS% --save_temp"
if "%VERBOSE%"=="1" set "ARGS=%ARGS% --verbose"
conda run -n "%HUMANS4D_ENV_NAME%" python waymo_workflow\human_pose\cli.py extract --data_root "%DATA_ROOT%" --scene_ids "%SCENE_IDS%" --fps "%FPS%" %ARGS%
