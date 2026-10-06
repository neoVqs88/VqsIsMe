~~~
fMRI Preprocessing. The fMRI data were preprocessed using FCP
scripts (1) (version 1.1-beta; available at www.nitrc.org/frs/
shownotes.php?release_id=938) with small modifications. By
combining tools provided by AFNI (2) and FSL (www.fmrib.ox.
ac.uk/fsl/) softwarepackages, the scripts performed the typical
preprocessing steps of functional connectivity analysis. Major steps
include motion correction, spatial smoothing with a Gaussian kernel
(FWHM =4 mm), temporal filtering with a bandpass filter (0.005
∼0.1 Hz), and the removal of linear and quadratic temporal trends.
In addition, the brain-averaged signal, the time series of regions of
interest in the white matter and cerebrospinal fluid, and six affine
motion parameters were regressed out from the dataset. The fMRI
data of eachsubject wasfirstspatially coregistered to high-resolution
anatomical images and then to the 152-brain Montreal Neurological
Institute (MNI) space.
Several modifications were made to the original scripts: the
spatial registration between the functional [echo-planar image
(EPI)] and anatomical (T1-weighted) images was implemented
using the align_epi_anat.py routine (3) in AFNI, which resulted in
a small improvement in registration in superior–inferior direction.
Additionally, the preprocessed fMRI data were resampled to 3 ×
3 ×3mm3intheMNIspace,andthesignal of each voxel was de
meaned normalized by its temporal SD.
Giventhat global signal regression (GSR) duringpreprocessing
may have undesirable consequences (4, 5), a separate set of data
were preprocessed identically except not including the GSR step.
~~~
这是 `CAPs` 原始论文使用的分析方法，是后续实现和质量控制的基线。

## 相关页面

- [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/面向CAPs的后处理流程|从 fMRIPrep 到 CAPs 的后处理清单]]
- [[预处理质量评分任务|预处理质量评分任务]]
- [[CAPs的K值稳定性分析|K 选择工作流]]
- [[关于科研经历/02-方法库/CAPs/index|返回 CAPs 方法库]]
