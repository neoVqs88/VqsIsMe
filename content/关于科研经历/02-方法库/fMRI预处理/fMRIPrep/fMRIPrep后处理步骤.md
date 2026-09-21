## 🏆 fMRIPrep 更好的方面

| 方面         | 为什么更好                                                       |
| ---------- | ----------------------------------------------------------- |
| **配准精度**   | 非线性配准（ANTs）vs 线性（FLIRT），[[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/配准方法差异|差异]]显著 |
| **偏场校正**   | 传统脚本完全缺失，fMRIPrep用N4校正                                      |
| **层时校正**   | 传统脚本缺失，fMRIPrep默认做                                          |
| **噪声回归**   | CompCor（PCA降维）vs 简单提取平均信号                                   |
| **运动质量评估** | FD + DVARS + 异常帧标记，传统脚本只有运动参数                               |
| **可重复性**   | BIDS标准 + 容器化，传统脚本依赖特定环境                                     |
| **多被试处理**  | 自动化程度高，不容易出错                                                |
| **引用支持**   | 自动生成CITATION.md，便于论文写作                                      |

---

## ⚠️ fMRIPrep 的不足

### 1. **计算资源需求高**
- 传统脚本：几十分钟/被试
- fMRIPrep：**数小时/被试**（尤其是FreeSurfer recon-all）
- 解决方案：使用 `--fs-no-reconall` 跳过表面重建（如不需要皮层分析）

### 2. **某些自由度降低**
- 层时校正：fMRIPrep强制对齐到某个参考层（通常是中间层）
- 平滑：默认开启（但可关闭：`--no-spatial-smoothing`）
- 滤波：不显式做带通滤波，依赖CompCor的高通（128s）

---

## 🔧 你必须进一步做的预处理（fMRIPrep输出后）

fMRIPrep输出的 `*_preproc.nii.gz` **并不适合直接用于功能连接分析**。你需要额外处理：

### ✅ 必要步骤

| 步骤            | 原因                                             | 如何做                                                               |
| ------------- | ---------------------------------------------- | ----------------------------------------------------------------- |
| **1. 带通滤波**   | fMRIPrep只做了高通（128s），未做低通（去除高频生理噪声）             | `3dBandpass -dt ${TR} -lower 0.008 -upper 0.1` 或 `fslmaths -bptf` |
| **2. 去线性趋势**  | fMRIPrep未去除扫描过程中的缓慢漂移                          | `3dDetrend -polort 1`                                             |
| **3. 应用运动回归** | fMRIPrep输出confounds文件，但**未自动回归**               | 使用 `film_gls` 或 `3dDeconvolve` 回归运动参数 + CompCor                   |
| **4. 去除异常帧**  | fMRIPrep标记了FD > 0.5mm或DVARS > 1.5的帧，但**未自动删除** | 使用 `3dcalc -expr 'step(0.5 - FD)'` 生成mask，或使用 `censor` 文件         |
计算平均FD，如果太大则删除该run，平均阈值0.5mm；

或 
fmri_run 中某个frame 头动超过3mm，该frame删除
### ⚠️ 可选但推荐的步骤

| 步骤 | 说明 |
|------|------|
| **全局信号回归** | 如果你的研究问题允许，建议尝试有/无GSR两种方案 |
| **scrubbing** | 删除运动过大的TR（而非仅回归） |
| **滤波前插补** | 删除TR后需用 `3dDespike` 或线性插值处理间断 |

---

## 📋 推荐的后处理流程（fMRIPrep之后）

```bash
# 假设你已经跑完了fMRIPrep，输出在 fmriprep/ 目录

# 1. 提取confounds（运动 + CompCor + 全局信号）
# confounds文件在 fmriprep/sub-<subject>/func/ 下

# 2. 回归噪声（用3dDeconvolve或film_gls）
3dDeconvolve -input ${preproc}.nii.gz \
    -mask ${mask}.nii.gz \
    -polort 1 \
    -num_stimts 20 \
    -stim_file 1 motion.1D[0] -stim_label 1 roll \
    -stim_file 2 motion.1D[1] -stim_label 2 pitch \
    ... \
    -stim_file 13 csf_comp.1D -stim_label 13 csfPC1 \
    -stim_file 14 wm_comp.1D -stim_label 14 wmPC1 \
    -x1D X.mat -errts ${residuals}.nii.gz

# 3. 带通滤波（0.008-0.1 Hz，常用）
3dFourier -highpass 0.008 -lowpass 0.1 -prefix ${filtered}.nii.gz ${residuals}.nii.gz

# 4. 去趋势（如果上一步未做）
3dDetrend -polort 1 -prefix ${detrended}.nii.gz ${filtered}.nii.gz

# 5. 注意：fMRIPrep已经配准到MNI空间，无需再次配准
```

---

## 🎯 简化版：如果你只想快速开始

```bash
# fMRIPrep命令行（跳过表面重建节省时间）
fmriprep-docker \
    --fs-no-reconall \
    --output-spaces MNI152NLin2009cAsym:res-2 \
    --no-spatial-smoothing \
    --participant_label sub-01 \
    ./bids_dir ./output_dir participant

# 后续用python（nilearn）处理更简单
from nilearn import image, masking
from nilearn.interfaces.fmriprep import load_confounds

# 加载fMRIPrep confounds
confounds = load_confounds(
    "sub-01_task-rest_bold.nii.gz",
    strategy=["motion", "high_pass", "compcor"],
    motion="full",
    compcor="anat_combined",
    n_compcor=5
)

# 回归 + 滤波
from nilearn.regions import clean_img
cleaned = clean_img(
    img,
    confounds=confounds,
    detrend=True,
    low_pass=0.1,
    high_pass=0.008,
    t_r=2.0
)
```

---

## 📊 总结表格

| 事项              | 结论                            |
| --------------- | ----------------------------- |
| fMRIPrep是否整体更好？ | ✅ **是**，尤其是配准、噪声控制、可重复性       |
| fMRIPrep有不足吗？   | ⚠️ 计算资源需求高、黑箱、某些固定参数          |
| fMRIPrep输出能用吗？  | ❌ **不能直接用**，需额外滤波+回归          |
| 必须做哪些后处理？       | 运动回归 + CompCor回归 + 带通滤波 + 去趋势 |
| 是否需要GSR？        | 看研究问题，运动大的数据建议尝试              |
| 是否需要scrubbing？  | 运动大的被试建议做                     |

---

**一句话总结**：fMRIPrep是目前最好的**自动化预处理pipeline**之一，但它不是终点——**你仍然需要做后处理回归和滤波**才能得到可用的功能连接数据。

## 相关页面

- [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/confounds参数详解|FD、DVARS 与 confounds 参数]]：选择质量控制和回归变量。
- [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/CompCor与噪声回归|CompCor 与噪声回归]]：理解回归量与滤波的原理。
- [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/面向CAPs的后处理流程|面向 CAPs 的完整后处理清单]]。
- [[关于科研经历/02-方法库/CAPs/CAPs原始预处理方案|CAPs 原始论文的预处理要求]]。
- [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/index|返回 fMRIPrep 方法库]]
