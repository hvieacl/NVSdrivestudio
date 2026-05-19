@echo off
setlocal
if "%HUMANS4D_ENV_NAME%"=="" set "HUMANS4D_ENV_NAME=4D-humans"

git submodule update --init --recursive
conda env list | findstr /R /C:"^%HUMANS4D_ENV_NAME% " >nul
if errorlevel 1 conda create --name "%HUMANS4D_ENV_NAME%" python=3.10 -y

conda run -n "%HUMANS4D_ENV_NAME%" python -m pip install --upgrade pip
conda run -n "%HUMANS4D_ENV_NAME%" python -m pip install torch
conda run -n "%HUMANS4D_ENV_NAME%" python -m pip install -e "third_party\Humans4D[all]"
conda run -n "%HUMANS4D_ENV_NAME%" python -m pip install git+https://github.com/brjathu/PHALP.git
conda run -n "%HUMANS4D_ENV_NAME%" python -m pip install git+https://github.com/facebookresearch/pytorch3d.git --no-build-isolation
echo [OK] 4D-Humans env is ready: %HUMANS4D_ENV_NAME%
