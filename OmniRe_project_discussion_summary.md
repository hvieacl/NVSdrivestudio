# OmniRe 项目讨论整理

## 1. OmniRe 的训练数据组织

OmniRe 把一个场景组织成多帧、多相机图像集合。以 Waymo `3cams` 为例：

```text
img_idx = timestep * num_cams + camera_idx
```

所以 198 帧、3 个相机就是：

```text
198 x 3 = 594 张训练图像
```

`train_image_set` 是训练采样池，`full_image_set` 是当前场景所有已加载视角。在 `test_image_stride=0` 时，所有图像都进入训练，所以 `full_image_set` 基本等于训练集。

训练时不是按时间顺序喂数据，而是从 `train_image_set` 里随机采一张图。因此 OmniRe 更接近 NeRF/3DGS 的多视角优化，而不是按视频时序递推训练的 video model。

## 2. RGB 多视角一致性如何体现

OmniRe 没有显式的 pairwise multi-view loss。也就是说，它没有直接约束：

```text
frame A 的某个像素和 frame B 的某个像素必须表示同一个 3D 点
```

它的 RGB 一致性是隐式的：

```text
同一套 3D Gaussian 参数
反复被不同时间、不同相机视角的 RGB 图像监督
```

每一步训练采样一张图，渲染当前 Gaussian 场景，然后和 GT RGB 做 L1/SSIM loss。由于所有视角共享同一套 3D 表达，如果某个 3D 结构在多个视角中都可见，它就会被这些视角共同约束。

但这个一致性有明显局限：

```text
不是显式几何匹配
不是光流监督
不是跨视角 patch matching
不是 dense correspondence
```

所以树冠、交通灯、远处建筑高层这类区域，如果 LiDAR 没覆盖、多视图重叠弱、遮挡复杂，就容易在偏离视角下退化。

## 3. Error Buffer 的作用

error buffer 是训练采样策略，不是模型结构。

它的设计目的是：周期性用当前模型渲染全数据集，计算预测图和 GT 图的 RGB 差异，然后把误差大的图像赋予更高采样概率。

简化理解：

```text
当前模型渲得差的图
后续更容易被采样训练
```

不过默认配置里：

```yaml
cache_buffer_freq: -1
```

所以周期性更新 error buffer 实际是关闭的。除非手动改成正数，比如：

```bash
trainer.optim.cache_buffer_freq=2000
```

否则训练主要还是随机采样图像。

## 4. 深度监督来自稀疏 LiDAR

OmniRe 有深度监督，但不是稠密深度。它使用 LiDAR 投影到相机图像上的 sparse depth map。

配置里有：

```yaml
losses:
  depth:
    w: 0.01
```

训练时只在 LiDAR 有效像素上计算 depth loss：

```text
gt_depth > 0 的像素才参与深度监督
```

这解释了可视化中看到的问题：Waymo LiDAR 主要覆盖道路、车辆低矮区域，对树冠、信号灯、高处建筑、线缆覆盖很弱。因此这些区域主要靠 RGB loss 和 Gaussian 正则补，几何不稳定。

## 5. Sky 的处理方式

OmniRe 不把天空当成普通 3D Gaussian 重建，而是用一个环境光/天空模型：

```yaml
Sky:
  type: models.modules.EnvLight
```

渲染时大致是：

```text
final_rgb = gaussian_rgb + sky_rgb * (1 - gaussian_opacity)
```

sky mask 的作用是告诉模型哪些区域应该是天空，从而约束 Gaussian 不要在天空区域乱长。

风险是：如果 `sky_masks/*.png` 有空洞或误分，尤其在树冠、建筑边缘、交通灯附近，就可能导致：

```text
真实前景被当成天空
天空边界处几何被压掉
边缘出现脏点、漂浮、拉丝
```

## 6. SH 颜色和新视角纹理退化

OmniRe 中每个 3D Gaussian 的颜色不是固定 RGB，而是 SH 系数表示的视角相关颜色。

代码逻辑可以概括为：

```text
viewdir = Gaussian center -> camera center 的方向
rgb = spherical_harmonics(viewdir, SH coefficients)
```

所以在一个具体视角下，每个 Gaussian 会查询出一个 RGB，然后这个颜色用于该 Gaussian 的 splatting footprint。

这里存在一个重要问题：如果某个 Gaussian 的背面方向从未被训练视角看到，那么这个方向上的 SH 颜色没有直接监督。新视角虽然可以查询 SH，但查询出来的是低阶球谐函数的外推结果，不一定是真实背面纹理。

因此偏离视角下可能出现：

```text
颜色糊化
纹理错位
反面颜色不可信
动态物体边缘拉丝
高处结构重影
```

这不是单纯实现 bug，而是当前 3DGS/SH 表达在稀疏视角监督下的典型弱点。

## 7. Novel View 与 Offset View 的区别

OmniRe 内置 novel view 轨迹变化较小，所以它更多是在训练轨迹附近轻微移动。

后来使用的 offset view 是人为把相机轨迹偏移，例如右移 2m、上移等，用来暴露跨视角泛化能力。

观察结论是：

```text
小偏移：效果还可以
大偏移：高处结构、树、交通灯、车辆背面、遮挡边界明显退化
```

这说明模型对训练视角附近拟合较好，但真正的几何一致性和未观测纹理仍然有限。

## 8. Waymo 与 nuScenes Workflow 的取舍

Waymo 部分拆成：

```text
waymo_workflow/
```

nuScenes mini 部分新增：

```text
nuscenes_workflow/
```

nuScenes mini 默认走 no-SMPL 配置：

```text
configs/omnire_nuscenes_no_smpl.yaml
```

原因是 mini 数据集通常没有现成 `humanpose/smpl.pkl`，强行启用 SMPL 会阻塞训练。nuScenes workflow 保留：

```text
images
lidar
calib
dynamic_masks
objects
sky_masks
vis_lidar
```

不再做 Waymo-to-KITTI 可视化转换，直接使用 OmniRe 自带的：

```bash
render.vis_lidar=True
```

## 9. 当前核心研究判断

对 OmniRe 的问题判断可以概括为：

```text
OmniRe 在训练视角上可以通过 RGB loss 拟合得很好；
但它的几何和纹理不是完全由真实 3D 约束出来的。
```

具体弱点来自几处叠加：

```text
LiDAR 稀疏，且高度覆盖有限
RGB consistency 是隐式的，不是显式跨视图匹配
SH 颜色对未观测方向是外推
动态物体、树冠、交通灯、天空边界监督弱
sky mask 错误会影响几何生长
```

因此后续如果要研究 3D Gaussian 基元性质，比较有价值的实践方向是：

```text
分析单个 Gaussian 的视角覆盖范围
统计每个 Gaussian 被哪些相机/帧监督过
分析 SH 不同方向的颜色方差
找出 novel view 退化区域对应的 Gaussian 是否缺少多视角观测
对比 LiDAR 覆盖区域和非覆盖区域的重建质量
```

这比单纯看最终视频更能证明问题来源。

## 10. 相关代码索引

### 数据集、多帧、多相机组织

- `configs/datasets/waymo/3cams.yaml`
  - Waymo 3 相机配置。
  - 关键字段：`data.pixel_source.cameras: [0, 1, 2]`、`test_image_stride: 0`、`load_smpl: True`。

- `configs/datasets/nuscenes/6cams.yaml`
  - nuScenes 6 相机配置。
  - 关键字段：`data_root: data/nuscenes/processed_10Hz/mini`、`dataset: nuscenes`、`cameras: [0, 1, 2, 3, 4, 5]`。

- `datasets/waymo/waymo_sourceloader.py`
  - `WaymoPixelSource.load_cameras()`
  - 负责逐个加载相机，并生成统一图像索引：

```python
unique_img_idx = torch.arange(len(camera), device=self.device) * len(self.camera_list) + idx
```

- `datasets/base/pixel_source.py`
  - `ScenePixelSource.create_all_filelist()`
  - 负责每个相机内按 timestep 收集图像路径。

- `datasets/driving_dataset.py`
  - `DrivingDataset.split_train_test()`
  - 负责把 timestep 展开成 image index：

```python
train_indices.append(t * self.pixel_source.num_cams + cam)
```

- `datasets/driving_dataset.py`
  - `DrivingDataset.build_split_wrapper()`
  - 负责构造：

```text
train_image_set
test_image_set
full_image_set
```

其中 `full_image_set` 使用：

```python
split_indices=np.arange(self.pixel_source.num_imgs).tolist()
```

### 训练采样与 Error Buffer

- `datasets/base/split_wrapper.py`
  - `SplitWrapper.next()`
  - 训练时每一步从 `train_image_set` 取图：

```python
img_idx = self.datasource.propose_training_image(candidate_indices=self.split_indices)
```

- `datasets/base/pixel_source.py`
  - `ScenePixelSource.propose_training_image()`
  - 负责随机采样或按 error buffer 加权采样：

```python
img_idx = random.choice(candidate_indices)
```

或：

```python
idx = torch.multinomial(image_mean_error, 1, replacement=False).item()
```

- `datasets/base/pixel_source.py`
  - `CameraData.build_image_error_buffer()`
  - 初始化低分辨率 error map。

- `datasets/base/pixel_source.py`
  - `CameraData.update_image_error_maps()`
  - 计算预测 RGB 和 GT RGB 的逐像素误差：

```python
image_error_maps = torch.abs(gt_rgbs - pred_rgbs).mean(dim=-1)
```

- `datasets/base/pixel_source.py`
  - `ScenePixelSource.update_image_error_maps()`
  - 汇总每张图的平均误差，形成图像级采样权重。

- `tools/train.py`
  - error buffer 更新触发位置。
  - 条件是：

```python
trainer.optim_general.cache_buffer_freq > 0
step % trainer.optim_general.cache_buffer_freq == 0
```

- `configs/omnire.yaml`
  - 默认配置：

```yaml
cache_buffer_freq: -1
```

因此默认不启用周期性 error buffer 更新。

### RGB Loss 与多视角隐式一致性

- `tools/train.py`
  - 主训练循环中调用：

```python
image_infos, cam_infos = dataset.train_image_set.next(train_step_camera_downscale)
outputs = trainer(image_infos, cam_infos)
```

- `models/trainers/base.py`
  - `BasicTrainer.compute_losses()`
  - RGB loss 计算位置：

```python
gt_rgb = image_infos["pixels"] * valid_loss_mask[..., None]
predicted_rgb = outputs["rgb"] * valid_loss_mask[..., None]
Ll1 = torch.abs(gt_rgb - predicted_rgb).mean()
```

- `configs/omnire.yaml`
  - RGB 和 SSIM 权重：

```yaml
losses:
  rgb:
    w: 0.8
  ssim:
    w: 0.2
```

### 稀疏 LiDAR 深度监督

- `models/trainers/base.py`
  - `BasicTrainer.compute_losses()`
  - 深度监督只在 LiDAR hit 的像素上生效：

```python
gt_depth = image_infos["lidar_depth_map"]
lidar_hit_mask = (gt_depth > 0).float() * valid_loss_mask
depth_loss = self.depth_loss_fn(pred_depth, gt_depth, lidar_hit_mask)
```

- `configs/omnire.yaml`
  - 深度损失配置：

```yaml
depth:
  w: 0.01
  inverse_depth: False
  normalize: False
  loss_type: l1
```

- `datasets/driving_dataset.py`
  - `DrivingDataset.project_lidar_pts_on_images()`
  - 用于将 LiDAR 点投影到相机图像中，形成稀疏深度监督。

### Sky / EnvLight 处理

- `configs/omnire.yaml`
  - Sky 模型配置：

```yaml
Sky:
  type: models.modules.EnvLight
  params:
    resolution: 1024
```

- `models/trainers/base.py`
  - Sky 合成逻辑：

```python
outputs["rgb_sky"] = sky_model(image_infos)
outputs["rgb_sky_blend"] = outputs["rgb_sky"] * (1.0 - outputs["opacity"])
outputs["rgb"] = outputs["rgb_gaussians"] + outputs["rgb_sky"] * (1.0 - outputs["opacity"])
```

- `configs/omnire.yaml`
  - 控制是否在视频中输出 sky 相关结果：

```yaml
render:
  vis_sky: False
```

### SH 颜色与视角相关渲染

- `models/gaussians/vanilla.py`
  - 静态背景 Gaussian 的 SH 查询位置：

```python
viewdirs = self._means.detach() - cam.camtoworlds.data[..., :3, 3]
viewdirs = viewdirs / viewdirs.norm(dim=-1, keepdim=True)
rgbs = spherical_harmonics(n, viewdirs, colors)
```

- `models/nodes/rigid.py`
  - 刚体动态节点的 SH 颜色查询。

- `models/nodes/deformable.py`
  - 可变形动态节点的 SH 颜色查询。

- `models/nodes/smpl.py`
  - SMPL 人体节点的 SH 颜色查询。

这些文件共同说明：每个 Gaussian 在当前相机方向下查询一个 RGB，未被训练视角覆盖的方向主要依赖 SH 外推。

### Gaussian 节点类型与 SMPL

- `configs/omnire.yaml`
  - 默认包含：

```yaml
Background
RigidNodes
DeformableNodes
SMPLNodes
Sky
Affine
CamPose
```

- `models/trainers/scene_graph.py`
  - `MultiTrainer._init_models()`
  - 根据配置动态创建各类模型。

- `models/trainers/scene_graph.py`
  - `MultiTrainer.init_gaussians_from_dataset()`
  - 从 LiDAR、object annotation、SMPL annotation 初始化不同 Gaussian 节点。

- `configs/omnire_nuscenes_no_smpl.yaml`
  - nuScenes mini 使用的 no-SMPL 配置。
  - 删除 `SMPLNodes`，训练时配合：

```bash
data.pixel_source.load_smpl=False
```

### 渲染、LiDAR 可视化与视频输出

- `tools/train.py`
  - 训练过程中的可视化和视频输出。
  - 当配置启用：

```yaml
render:
  vis_lidar: True
```

会把 LiDAR 可视化相关结果加入输出。

- `tools/eval.py`
  - 单独评估/渲染入口。
  - 同样支持：

```yaml
render.vis_lidar=True
render.vis_sky=True
```

- `models/video_utils.py`
  - 负责把不同 render key 组织成视频，包括 full render、class-wise render、sky、LiDAR 等。

### Workflow 文件

- `waymo_workflow/`
  - Waymo 10 scenes 的环境、预处理、SegFormer sky mask、human pose、训练 workflow。

- `nuscenes_workflow/`
  - nuScenes mini 10 scenes 的下载、预处理、SegFormer sky mask、preflight、训练 workflow。

- `nuscenes_workflow/run_nuscenes_mini_10scenes.sh`
  - nuScenes mini 主流程。
  - 默认：

```bash
DATASET="nuscenes/6cams"
CONFIG_FILE="configs/omnire_nuscenes_no_smpl.yaml"
EXTRA_ARGS="render.vis_lidar=True render.render_full=True render.render_test=False data.pixel_source.load_smpl=False"
```

- `nuscenes_workflow/download_nuscenes_mini.sh`
  - 下载并解压 `v1.0-mini.tgz`。

- `nuscenes_workflow/semantic_masks/`
  - nuScenes sky mask / fine dynamic mask 检查与提取。

### 数据预处理入口

- `datasets/preprocess.py`
  - 统一数据预处理入口。
  - 支持：

```text
waymo
nuscenes
kitti
pandaset
argoverse
nuplan
```

- `datasets/nuscenes/nuscenes_preprocess.py`
  - nuScenes 预处理实现。
  - `NuScenesProcessor.convert_one()`
  - `NuScenesProcessor.convert_one_interpolated()`
  - 插值模式由：

```bash
--interpolate_N
```

控制。`INTERPOLATE_N=4` 时输出路径匹配：

```text
data/nuscenes/processed_10Hz/mini
```
