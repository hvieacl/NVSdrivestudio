@echo off
setlocal
if "%SEGFORMER_ENV_NAME%"=="" set "SEGFORMER_ENV_NAME=segformer"
if "%SEGFORMER_ROOT%"=="" set "SEGFORMER_ROOT=%CD%\..\SegFormer"

conda env list | findstr /R /C:"^%SEGFORMER_ENV_NAME% " >nul
if errorlevel 1 conda create -n "%SEGFORMER_ENV_NAME%" python=3.8 -y

conda run -n "%SEGFORMER_ENV_NAME%" python -m pip install --upgrade pip==23.3.2
conda run -n "%SEGFORMER_ENV_NAME%" python -m pip install torch==1.8.1+cu111 torchvision==0.9.1+cu111 torchaudio==0.8.1 -f https://download.pytorch.org/whl/torch_stable.html
conda run -n "%SEGFORMER_ENV_NAME%" python -m pip install timm==0.3.2 pylint debugpy opencv-python-headless attrs ipython tqdm imageio scikit-image omegaconf
conda run -n "%SEGFORMER_ENV_NAME%" python -m pip install mmcv-full==1.2.7 --no-cache-dir

if not exist "%SEGFORMER_ROOT%\.git" git clone --depth 1 https://github.com/NVlabs/SegFormer "%SEGFORMER_ROOT%"
conda run -n "%SEGFORMER_ENV_NAME%" python -m pip install -e "%SEGFORMER_ROOT%"

if not exist "%SEGFORMER_ROOT%\pretrained" mkdir "%SEGFORMER_ROOT%\pretrained"
echo [OK] SegFormer env is ready: %SEGFORMER_ENV_NAME%
echo [NEXT] Download the checkpoint with:
echo        nuscenes_workflow\semantic_masks\download_segformer_checkpoint.bat
if "%DOWNLOAD_SEGFORMER_CHECKPOINT%"=="1" call nuscenes_workflow\semantic_masks\download_segformer_checkpoint.bat
