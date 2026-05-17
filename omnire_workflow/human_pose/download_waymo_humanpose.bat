@echo off
setlocal
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
if "%TARGET_DIR%"=="" set "TARGET_DIR=data"
if "%GDOWN_ID%"=="" set "GDOWN_ID=1QrtMrPAQhfSABpfgQWJZA2o_DDamL_7_"
conda run -n "%ENV_NAME%" python -m pip install gdown
conda run -n "%ENV_NAME%" python omnire_workflow\human_pose\cli.py download-preprocessed --target_dir "%TARGET_DIR%" --gdown_id "%GDOWN_ID%"
