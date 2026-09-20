## 问题现象

运行 `fsleyes reg/highres.nii.gz reg/example_func2highres_afni.nii.gz` 后，功能像显示为 **“一团皱巴巴的不明体素”**，完全无法与结构像重合。

## 核心结论（最终定位）

**功能像的平均信号强度异常低（只有正常值的 1/3），导致图像对比度极差，配准算法找不到任何可识别的脑结构特征，从而产生错误的变换。**

---

## 完整排查流程（共 7 步）

### 第 1 步：确认是普遍问题还是个别 session 问题

**目的**：判断是所有数据都失败，还是只有某个 session 失败。

```bash
# 列出所有 session 的预处理结果
for ses_dir in reg/ses-*/; do
    ses=$(basename ${ses_dir})
    if [ -f "${ses_dir}/example_func2highres_afni.nii.gz" ]; then
        echo "=== ${ses} ==="
        fslstats ${ses_dir}/example_func2highres_afni.nii.gz -V
    fi
done
```

**发现**：只有 ses-012 失败，其他正常 → 问题定位到特定 session。

---

### 第 2 步：检查功能像和结构像的原始图像

**目的**：肉眼判断图像质量、朝向、视野是否正常。

```bash
# 分别打开功能像和结构像
fsleyes ses-012/func/sub-01_ses-012_task-rest_run-1_sbref.nii.gz &
fsleyes ses-012/anat/sub-01_ses-012_T1w.nii.gz &
```

**注意**：`fsleyes` 的正确用法是 `fsleyes 图像1 图像2`，不要加 `-cm hot` 等选项在末尾，否则会报错。更稳妥的方式是先打开 GUI 窗口，然后把文件拖进去。

**观察要点**：
- 功能像中能否看到清晰的脑结构？
- 功能像和结构像的朝向是否一致（头都朝上，鼻子都朝前）？
- 两者的视野（FOV）是否大致重叠？

---

### 第 3 步：对比维度和体素大小

**目的**：排除因扫描参数不一致导致的配准失败。

```bash
# 功能像对比
echo "=== ses-012 func ==="
fslhd ses-012/func/sub-01_ses-012_task-rest_run-1_bold.nii.gz | grep -E "dim[123]|pixdim[123]"

echo "=== ses-013 func ==="
fslhd ses-013/func/sub-01_ses-013_task-rest_run-1_bold.nii.gz | grep -E "dim[123]|pixdim[123]"

# 结构像对比
echo "=== ses-012 T1w ==="
fslhd ses-012/anat/sub-01_ses-012_T1w.nii.gz | grep -E "dim[123]|pixdim[123]"

echo "=== ses-013 T1w ==="
fslhd ses-013/anat/sub-01_ses-013_T1w.nii.gz | grep -E "dim[123]|pixdim[123]"
```

**发现**：ses-012 和 ses-013 的维度和体素大小完全一致 → 排除参数差异。

---

### 第 4 步：检查元数据（相位编码方向、读出时间）

**目的**：确认功能像的扫描参数是否正常，特别是与 fmap 相关的参数。

```bash
# 检查 PhaseEncodingDirection 和 TotalReadoutTime
echo "=== ses-012 ==="
cat ses-012/func/sub-01_ses-012_task-rest_run-1_bold.json | grep -E "PhaseEncodingDirection|TotalReadoutTime"

echo "=== ses-013 ==="
cat ses-013/func/sub-01_ses-013_task-rest_run-1_bold.json | grep -E "PhaseEncodingDirection|TotalReadoutTime"
```

**发现**：两者参数一致（都是 `"j-"` 和 `0.0294501`）→ 排除元数据问题。

---

### 第 5 步：检查 fmap 的影响

**目的**：判断 fmap 的存在是否是配准失败的原因。

```bash
# 查看 session 目录结构，确认是否有 fmap
ls ses-012/
ls ses-013/
```

**发现**：
- ses-012 有 fmap（dir-AP 和 dir-PA 文件）
- ses-013 没有 fmap
- 但 ses-013 配准正常，而 ses-012 失败 → 排除“有 fmap 就会失败”的假设

---
你说得对，这一步非常关键，我漏掉了。这一步实际上排除了一个重要的可能性：**问题不在结构像，而在功能像本身**。

让我把它补充进去，放在第 5 步和第 6 步之间。

---

### 第 5.5 步：换用不同的结构像进行配准（排除结构像问题）

**目的**：判断配准失败是因为功能像本身有问题，还是因为功能像与特定结构像不匹配。

```bash
cd /home/hanlabundergrad2/MyconnectomeTest/Test1/ses-012

# 提取功能像平均
fslmaths func/sub-01_ses-012_task-rest_run-1_bold.nii.gz -Tmean mean_func.nii.gz

# 尝试 1：用 ses-012 自己的结构像
epi_reg --epi=mean_func.nii.gz \
        --t1=anat/sub-01_ses-012_T1w.nii.gz \
        --t1brain=anat/sub-01_ses-012_T1w_brain.nii.gz \
        --out=test_self_anat

# 尝试 2：用 ses-013 的结构像（时间上接近的正常 session）
epi_reg --epi=mean_func.nii.gz \
        --t1=../ses-013/anat/sub-01_ses-013_T1w.nii.gz \
        --t1brain=../ses-013/anat/sub-01_ses-013_T1w_brain.nii.gz \
        --out=test_other_anat

# 尝试 3：用 FreeSurfer 生成的平均模板（如果已经生成）
epi_reg --epi=mean_func.nii.gz \
        --t1=../template_fastsurfer.nii.gz \
        --t1brain=../template_fastsurfer_brain.nii.gz \
        --out=test_template_anat

# 检查所有结果
fsleyes anat/sub-01_ses-012_T1w.nii.gz test_self_anat.nii.gz &
fsleyes ../ses-013/anat/sub-01_ses-013_T1w.nii.gz test_other_anat.nii.gz &
fsleyes ../template_fastsurfer.nii.gz test_template_anat.nii.gz &
```

**预期结果**：
- 如果换用任何结构像都失败 → 问题在功能像本身
- 如果只有某个特定结构像失败 → 问题在那个结构像

**实际情况**：三种尝试全部失败 → 结论明确：**问题出在 ses-012 的功能像，而不是结构像**。
### 这一步的重要性

这一步排除了两个常见的错误假设：

1. **“是不是结构像和功能像的 session 不匹配？”** → 试了它自己的结构像，也不行
2. **“是不是单个结构像有问题？”** → 试了平均模板（融合了所有结构像），也不行

一旦确认是功能像本身的问题，排查方向就从“配准参数/结构像”转向了“功能像质量”。

---

### 第 6 步：检查功能像的信号强度（关键！）

**目的**：定量评估功能像的图像质量。

```bash
# 计算所有 session 的功能像平均信号强度
for ses in 011 012 013 015 018 021 024 027 030 033 036 041 044 046 049; do
    mean_val=$(fslstats /path/to/ses-${ses}/func/sub-01_ses-${ses}_task-rest_run-1_bold.nii.gz -M 2>/dev/null)
    echo "ses-${ses}: ${mean_val}"
done
```

**发现**：

| session | 平均信号强度 |
|---------|-------------|
| ses-011 | 2671 |
| ses-012 | **899** ❌ |
| ses-013 | 2591 |
| ses-015 | 2539 |
| ... | ... |
| ses-049 | 2374 |

**ses-012 的信号强度只有正常值的 1/3！**

---

## 问题根源

**信号强度低 → 图像对比度差 → 脑组织与背景无法区分 → 配准算法找不到特征点 → 变换错误 → “一团皱巴巴的体素”**

可能的原因：
- RF 线圈校准失败
- 被试头部位置偏离线圈中心
- 扫描仪当天状态异常
- dcm2niix 转换时的缩放错误

---

## 解决方案

### 对于坏 session：
**直接放弃**。在纵向研究中，丢弃一个质量不合格的时间点是标准做法。

### 对于后续分析：
建立一个快速 QC 流程，在处理前自动筛除信号异常的 session：

```bash
# 快速筛查脚本
for ses in ses-*/; do
    mean_val=$(fslstats ${ses}/func/*_bold.nii.gz -M 2>/dev/null)
    if (( $(echo "$mean_val < 1500" | bc -l) )); then
        echo "WARNING: ${ses} signal too low (${mean_val}), skipping"
    else
        echo "OK: ${ses} (${mean_val})"
    fi
done
```

---

## 经验教训

1. **配准失败的第一反应**：先检查功能像的原始质量，而不是疯狂调参数
2. **信号强度是最直接的 QC 指标**：`fslstats *.nii.gz -M` 只要 0.1 秒
3. **纵向数据必然有坏 session**：质量控制不是可选项，是必选项
4. **不要假设公开数据都是干净的**：MyConnectome 是科研项目数据，不是生产级产品
5. **对比法是最快的诊断工具**：拿一个正常 session 和问题 session 逐项对比，差异很快就能找到

---

## 快速参考命令汇总

| 检查项 | 命令 |
|--------|------|
| 信号强度 | `fslstats func.nii.gz -M` |
| 维度和体素 | `fslhd func.nii.gz \| grep -E "dim[123]\|pixdim[123]"` |
| 元数据 | `cat *.json \| grep -E "PhaseEncodingDirection\|TotalReadoutTime"` |
| 暴力配准 | `flirt -in func.nii.gz -ref struct.nii.gz -dof 12 -searchrx -180 180 -searchry -180 180 -searchrz -180 180` |
| 批量筛查 | `for ses in */; do fslstats ${ses}/func/*_bold.nii.gz -M; done` |
## 完整排查流程

| 步骤 | 检查内容 | 目的 |
|------|----------|------|
| 1 | 确认是个别 session 还是普遍问题 | 定位问题范围 |
| 2 | 肉眼检查功能像和结构像 | 判断图像质量、朝向、视野 |
| 3 | 对比维度和体素大小 | 排除扫描参数差异 |
| 4 | 检查元数据（PhaseEncodingDirection 等） | 排除参数设置问题 |
| 5 | 检查 fmap 的影响 | 排除畸变校正问题 |
| **5.5** | **换用不同结构像配准** | **判断是功能像还是结构像的问题** |
| 6 | 暴力搜索配准 | 排除算法初始化问题 |
| 7 | 检查功能像信号强度 | 定量评估图像质量 |

