@echo off
setlocal
if "%SEGFORMER_ENV_NAME%"=="" set "SEGFORMER_ENV_NAME=segformer"
if "%SEGFORMER_ROOT%"=="" set "SEGFORMER_ROOT=%CD%\..\SegFormer"
if "%SEGFORMER_CHECKPOINT%"=="" set "SEGFORMER_CHECKPOINT=%SEGFORMER_ROOT%\pretrained\segformer.b5.1024x1024.city.160k.pth"
if "%HF_URL%"=="" set "HF_URL=https://huggingface.co/chromics/segformer.b5.1024x1024.city.160k.pth/resolve/main/segformer.b5.1024x1024.city.160k.pth"
if "%GDOWN_ID%"=="" set "GDOWN_ID=1e7DECAH0TRtPZM6hTqRGoboq1XPqSmuj"

for %%I in ("%SEGFORMER_CHECKPOINT%") do if not exist "%%~dpI" mkdir "%%~dpI"

if exist "%SEGFORMER_CHECKPOINT%" (
  echo [OK] Checkpoint already exists: %SEGFORMER_CHECKPOINT%
  dir "%SEGFORMER_CHECKPOINT%"
  exit /b 0
)

echo [workflow] Downloading SegFormer checkpoint to: %SEGFORMER_CHECKPOINT%
curl -L "%HF_URL%" -o "%SEGFORMER_CHECKPOINT%.tmp"
if errorlevel 1 goto try_gdown
move /Y "%SEGFORMER_CHECKPOINT%.tmp" "%SEGFORMER_CHECKPOINT%"
dir "%SEGFORMER_CHECKPOINT%"
exit /b 0

:try_gdown
del "%SEGFORMER_CHECKPOINT%.tmp" 2>nul
conda run -n "%SEGFORMER_ENV_NAME%" python -m pip install gdown
conda run -n "%SEGFORMER_ENV_NAME%" gdown "%GDOWN_ID%" -O "%SEGFORMER_CHECKPOINT%"
dir "%SEGFORMER_CHECKPOINT%"
