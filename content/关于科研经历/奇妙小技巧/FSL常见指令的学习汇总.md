---
title: FSL常见指令的学习汇总
draft: false
tags:
  - fmri预处理
aliases:
date: 2026-04-17
---
### fslinfo
~~~
# 举例：
[hanlabundergrad2@bcm func]$ fslinfo sub-88_ses-1_task-rest_bold.nii.gz
data_type       INT16
dim1            64
dim2            64
dim3            48
dim4            200
datatype        4
pixdim1         3.437500
pixdim2         3.437500
pixdim3         3.400000
pixdim4         3.000000
cal_max         0.000000
cal_min         0.000000
file_type       NIFTI-1+
~~~
1. 基本维度信息

| 参数            | 值     | 含义                       |
| ------------- | ----- | ------------------------ |
| **data_type** | INT16 | 数据类型为16位整数，fMRI常用格式，节省空间 |
| **dim1**      | 64    | x轴体素数量（宽度）               |
| **dim2**      | 64    | y轴体素数量（深度）               |
| **dim3**      | 48    | z轴体素数量（高度/层数）            |
| **dim4**      | 200   | 时间点数量（volumes/TRs）       |
| **datatype**  | 4     | 编码值，对应INT16类型            |
2. 体素大小（空间分辨率）

| 参数 | 值 | 含义 |
|------|-----|------|
| **pixdim1** | 3.4375 mm | x方向体素大小 |
| **pixdim2** | 3.4375 mm | y方向体素大小 |
| **pixdim3** | 3.4000 mm | z方向体素大小（层厚） |
| **pixdim4** | 3.0000 s | TR（重复时间），每3秒采集一个全脑 |

3. 整体尺寸计算

- **单个全脑大小**：64 × 64 × 48 = **196,608 个体素**
- **总数据量**：196,608 × 200 = **39,321,600 个体素**
- **文件大小**：约 39.3M × 2字节 ≈ **75 MB**
- **扫描总时长**：200 × 3秒 = **600秒 = 10分钟**

3. 后续可以进行的命令：
```bash
# 1. 脑提取（去除非脑组织）
bet sub-88_ses-1_task-rest_bold.nii.gz sub-88_brain -F

# 2. 头动校正
mcflirt -in sub-88_ses-1_task-rest_bold -out sub-88_mc

# 3. 平滑（FWHM通常为体素大小2-3倍）
susan sub-88_mc -f 6 -b 3 -d 3.4

# 4. 高通滤波（去除低频漂移）
fslmaths sub-88_mc -bptf 100 10 sub-88_filtered
```
