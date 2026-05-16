@echo off
setlocal
if "%ENV_NAME%"=="" set "ENV_NAME=drivestudio"
git submodule update --init --recursive
conda create -n "%ENV_NAME%" python=3.9 -y
conda run -n "%ENV_NAME%" python -m pip install --upgrade pip
conda run -n "%ENV_NAME%" pip install -r requirements.txt
conda run -n "%ENV_NAME%" pip install git+https://github.com/nerfstudio-project/gsplat.git@v1.3.0
conda run -n "%ENV_NAME%" pip install git+https://github.com/facebookresearch/pytorch3d.git
conda run -n "%ENV_NAME%" pip install git+https://github.com/NVlabs/nvdiffrast
conda run -n "%ENV_NAME%" pip install -e third_party\smplx
conda run -n "%ENV_NAME%" pip install waymo-open-dataset-tf-2-11-0==1.6.0
