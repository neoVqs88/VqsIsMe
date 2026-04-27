# 原始脚本分析：

这些脚本是一个标准的**fMRI预处理流程**（基于AFNI、FSL、FLIRT等工具），用于处理结构像和功能像。下面是每个脚本中使用的**核心指令**及其作用。
## 📁 `1_anatpreproc.sh` – 结构像预处理

| 指令                       | 作用                          |
| ------------------------ | --------------------------- |
| `3drefit -deoblique`     | 去除图像中的斜交（deoblique），使图像轴对齐  |
| `3dresample -orient RPI` | 重定向图像方向为RPI（右、后、下），FSL友好    |
| `3dSkullStrip`           | 去除颅骨，提取大脑区域                 |
| `3dcalc`                 | 将去颅骨后的脑组织二值化并应用到原图，生成大脑mask |

---

## 📁 `2_funcpreproc_non_filter.sh` – 功能像预处理（无滤波版）

| 指令                              | 作用                         |
| ------------------------------- | -------------------------- |
| `3dcalc`                        | 丢弃前几个时间点（TR）               |
| `3drefit -deoblique`            | 去斜交                        |
| `3dresample -orient RPI`        | 定向为RPI                     |
| `3dTstat -mean`                 | 计算平均功能像作为运动校正的参考           |
| `3dvolreg -Fourier -twopass`    | 运动校正（Fourier插值，两轮对齐）       |
| `3dAutomask`                    | 自动生成脑mask                  |
| `fslmaths -kernel gauss -fmean` | 空间平滑（高斯核）                  |
| `fslmaths -ing 10000`           | 全局均值缩放（grand-mean scaling） |
| `3dDetrend -polort 2`           | 去除线性和二次趋势（detrend）         |
| `fslmaths -Tmin -bin`           | 生成最终预处理后的脑mask             |

---

## 📁 `3_registration.sh` – 配准

| 指令                  | 作用                       |
| ------------------- | ------------------------ |
| `flirt`             | FSL线性配准（功能→T1，T1→标准空间）   |
| `convert_xfm`       | 转换/合并变换矩阵                |
| `align_epi_anat.py` | AFNI的EPI-T1配准（支持非线性、大偏移） |
| `3dAFNItoNIFTI`     | AFNI格式转NIFTI             |
| `3dresample`        | 重采样图像到目标空间               |

> 注：脚本中使用了多种配准策略，最终目标是生成 `example_func2standard.mat` 等矩阵。

---

## 📁 `4_segment.sh` – 组织分割（WM/CSF）

| 指令                       | 作用                      |
| ------------------------ | ----------------------- |
| `fast`                   | FSL的分割工具，生成WM/CSF/GM概率图 |
| `flirt`                  | 将概率图配准到功能空间             |
| `fslmaths -kernel gauss` | 平滑分割图以匹配功能数据平滑度         |
| `fslmaths -mas`          | 与先验模板（如MNI WM/CSF）取交集   |
| `fslmaths -thr -bin`     | 阈值化和二值化生成最终mask         |
| `3dmaskave`（在后续脚本）       | 提取WM/CSF信号              |

---

## 📁 `5_nuisance.sh` 和 `6_nuisance_with_gsl.sh` – 噪声回归

| 指令                      | 作用                         |
| ----------------------- | -------------------------- |
| `awk`                   | 提取运动参数（6个方向）               |
| `3dmaskave`             | 从global/WM/CSF mask中提取平均信号 |
| `sed`                   | 动态生成FSL的.fsf模型文件           |
| `feat_model`            | 生成了设计矩阵（nuisance.mat）      |
| `film_gls`              | 广义最小二乘回归，计算残差              |
| `3dTstat -mean`         | 计算残差均值                     |
| `3dcalc`                | 去均值后加100（标准化到~100）         |
| `flirt` / `3dAllineate` | 将残差图像重采样到MNI空间             |

> `6_nuisance_with_gsl.sh` 与 `5_nuisance.sh` 的核心区别在于：是否包含**global signal**作为回归变量（GSL = global signal regression）。

---

## 总结：核心工具链

| 工具                 | 用途                      |
| ------------------ | ----------------------- |
| **AFNI**           | 去斜交、重定向、运动校正、去趋势、mask生成 |
| **FSL (FLIRT)**    | 线性配准、空间平滑、分割、噪声回归       |
| **FSL (FAST)**     | 组织分割                    |
| **FSL (film_gls)** | 基于GLM的噪声回归              |
| **awk / sed**      | 文件处理和模板生成               |

---

# 新`pipeline`的使用——`fmriprep`的使用
## 🧠 fMRIPrep 做了什么？（基于CITATION.md）

### 一、结构像预处理

| 步骤 | 工具 | 作用 |
|------|------|------|
| 强度非均匀性校正 | `N4BiasFieldCorrection` (ANTs) | 消除MRI图像中的偏场效应 |
| 颅骨剥离 | `antsBrainExtraction.sh` | 提取大脑，使用OASIS30ANTs模板 |
| 组织分割 | `fast` (FSL) | 分割CSF、WM、GM |
| 鲁棒模板构建 | `mri_robust_template` (FreeSurfer) | 从多个T1w图像生成参考模板 |
| 表面重建 | `recon-all` (FreeSurfer) | 重建大脑皮层表面 |
| 空间标准化 | `antsRegistration` (ANTs) | 非线性配准到MNI152NLin2009cAsym |

### 二、功能像预处理

| 步骤 | 工具 | 作用 |
|------|------|------|
| 头动校正 | `mcflirt` (FSL) | 估计6个运动参数 |
| BOLD→T1配准 | `bbregister` (FreeSurfer) | 基于边界的配准（6 DOF） |
| 层时校正 | `3dTshift` (AFNI) | 校正不同层采集时间差 |
| 噪声回归 | **CompCor** (aCompCor + tCompCor) | 基于主成分的生理噪声去除 |
| 运动伪影标记 | FD (Power + Jenkinson), DVARS | 识别运动异常帧 |
| 全局信号 | CSF、WM、全脑mask中提取 | 用于后续回归 |
| 重采样 | `nitransforms` (三次B样条) | 单步插值完成所有变换 |

---

## ⚖️ 相同点 vs 不同点

### ✅ 相同点（核心理念一致）

| 处理步骤 | 传统脚本 | fMRIPrep |
|----------|----------|----------|
| 颅骨剥离 | ✅ `3dSkullStrip` | ✅ `antsBrainExtraction` |
| 组织分割 | ✅ `fast` | ✅ `fast` |
| 头动校正 | ✅ `3dvolreg` | ✅ `mcflirt` |
| 空间平滑 | ✅ `fslmaths -kernel gauss` | ✅ 默认开启（可配置） |
| 噪声回归 | ✅ WM/CSF/GS + 运动参数 | ✅ CompCor + 运动参数 + GS |
| 带通滤波 | ✅ `3dFourier`（被注释） | ✅ 通过CompCor的高通（128s） |
| 配准到MNI | ✅ `flirt` + 重采样 | ✅ `antsRegistration`（非线性） |
| 全局信号回归 | ✅ 支持（with_gsl版本） | ✅ 支持（可选） |

---

### 🔄 不同点（关键差异）

| 方面 | 传统脚本 | fMRIPrep | 优势对比 |
|------|----------|----------|----------|
| **配准方式** | 线性 `flirt` | 非线性 `antsRegistration` | ✅ fMRIPrep 更精确 |
| **层时校正** | ❌ 未实现 | ✅ `3dTshift` | ✅ fMRIPrep 更完整 |
| **噪声回归** | 手动提取WM/CSF信号 | CompCor（PCA降维） | ✅ fMRIPrep 更先进 |
| **运动检测** | 仅输出运动参数 | FD + DVARS + 异常帧标记 | ✅ fMRIPrep 更全面 |
| **表面重建** | ❌ 无 | ✅ FreeSurfer `recon-all` | ✅ fMRIPrep 支持皮层分析 |
| **偏场校正** | ❌ 无 | ✅ `N4BiasFieldCorrection` | ✅ fMRIPrep 更鲁棒 |
| **多运行处理** | 单次运行 | 批量处理94个BOLD runs | ✅ fMRIPrep 自动化 |
| **插值方式** | 线性/`wsinc5` | 三次B样条 | ✅ fMRIPrep 更平滑 |
| **可重复性** | 手动脚本，依赖环境 | BIDS标准 + 容器化 | ✅ fMRIPrep 更强 |
| **引用支持** | 需手动整理 | 自动生成CITATION.md | ✅ fMRIPrep 更方便 |

---

### ❌ 传统脚本有但fMRIPrep没有（或不同实现）的步骤

| 传统脚本 | fMRIPrep | 说明 |
|----------|----------|------|
| 丢弃前N个TR | 保留所有TR，通过motion outlier标记 | fMRIPrep不主动丢弃，让用户决定 |
| 全局均值缩放（×10000） | 默认不做 | fMRIPrep保留原始尺度 |
| 去趋势（3dDetrend） | 通过CompCor的高通滤波实现 | 理念不同 |
| 显式的带通滤波 | 通过CompCor + 高通（128s） | fMRIPrep不强制带通 |

---

## 📊 流程对比图

```
传统脚本流程:
T1w → 去斜交 → 重定向RPI → 颅骨剥离 → FAST分割
         ↓
BOLD → 丢TR → 去斜交 → 重定向 → 头动校正 → 颅骨剥离 → 平滑 → 缩放 → 去趋势 → 回归(WM/CSF/运动) → 配准MNI

fMRIPrep流程:
T1w → 偏场校正 → 颅骨剥离 → FAST分割 → 表面重建 → 非线性配准MNI
         ↓
BOLD → 头动校正 → 层时校正 → 配准到T1 → CompCor噪声估计 → 单步重采样到MNI
```

---

## 🎯 总结：你应该如何选择？

| 场景 | 推荐 |
|------|------|
| **发表论文，追求标准化** | ✅ **fMRIPrep**（学界公认，可重复性强） |
| **处理少量数据，快速查看** | 传统脚本（更灵活，但需手动检查） |
| **需要皮层分析（FreeSurfer）** | ✅ **fMRIPrep** |
| **需要GSR（全局信号回归）** | 两者都支持 |
| **处理扭曲严重的EPI** | ✅ **fMRIPrep**（支持fieldmap校正） |
| **老旧集群，无法安装容器** | 传统脚本 |

---

## 💡 附加说明

你的传统脚本中**层时校正被省略了**，这是一个重要的缺失。fMRIPrep默认做了层时校正，这对TR > 2s的数据尤其重要。

另外，你的传统脚本中带通滤波被注释掉了（`cp rest_gms.nii.gz rest_filt.nii.gz`），意味着实际上**没有做滤波**，而fMRIPrep通过CompCor的高通滤波（128s）间接实现了部分滤波效果。