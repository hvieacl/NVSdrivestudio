@echo off
setlocal
if "%VIZ_ENV_NAME%"=="" set "VIZ_ENV_NAME=waymo-kitti-viz"
conda create -n "%VIZ_ENV_NAME%" python=3.8 -y
conda run -n "%VIZ_ENV_NAME%" python -m pip install --upgrade pip
conda run -n "%VIZ_ENV_NAME%" pip install tensorflow==2.11.* waymo-open-dataset-tf-2-11-0==1.6.0 opencv-python tqdm matplotlib numpy==1.21.3 vedo==2021.0.6 vtk==9.0.3 opencv-python==4.5.4.58 matplotlib==3.4.3
