@echo off
setlocal
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
git submodule update --init --recursive
conda create -n "%ENV_NAME%" python=3.9 -y
conda run -n "%ENV_NAME%" python -m pip install --upgrade pip
conda run -n "%ENV_NAME%" python -m pip install chumpy==0.70 --no-build-isolation
powershell -NoProfile -Command "Get-Content requirements.txt | Where-Object { $_ -ne 'chumpy' } | Set-Content $env:TEMP\drivestudio_requirements_no_chumpy.txt"
conda run -n "%ENV_NAME%" python -m pip install -r "%TEMP%\drivestudio_requirements_no_chumpy.txt"
conda run -n "%ENV_NAME%" python -m pip install ninja fvcore iopath
conda run -n "%ENV_NAME%" python -m pip install git+https://github.com/nerfstudio-project/gsplat.git@v1.3.0 --no-build-isolation
conda run -n "%ENV_NAME%" python -m pip install git+https://github.com/facebookresearch/pytorch3d.git@v0.7.4 --no-build-isolation
conda run -n "%ENV_NAME%" python -m pip install git+https://github.com/NVlabs/nvdiffrast.git --no-build-isolation
conda run -n "%ENV_NAME%" python -m pip install -e third_party\smplx
conda run -n "%ENV_NAME%" pip install waymo-open-dataset-tf-2-11-0==1.6.0
