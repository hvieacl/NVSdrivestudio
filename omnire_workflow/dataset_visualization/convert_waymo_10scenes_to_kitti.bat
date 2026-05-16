@echo off
setlocal
if "%VIZ_ENV_NAME%"=="" set "VIZ_ENV_NAME=waymo-kitti-viz"
conda run -n "%VIZ_ENV_NAME%" python -m omnire_workflow.dataset_visualization.cli convert-ten
