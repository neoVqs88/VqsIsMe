[[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/fMRIPrep与传统流程对比|预处理流程对比]] | [[fMRIPrep试验结果|本地试验结果]]

## 第一部分：总体声明

```markdown
Results included in this manuscript come from preprocessing
performed using *fMRIPrep* 25.2.5
(@fmriprep1; @fmriprep2; RRID:SCR_016216),
which is based on *Nipype* 1.10.0
(@nipype1; @nipype2; RRID:SCR_002502).
```

### 🔍 知识点拆解

| 要素                  | 含义                                        | 重要性   |
| ------------------- | ----------------------------------------- | ----- |
| **fMRIPrep 25.2.5** | 版本号，确保可重复性                                | ⭐⭐⭐⭐⭐ |
| **RRID:SCR_016216** | Research Resource Identifier，论文中引用工具的标准ID | ⭐⭐⭐⭐  |
| **Nipype**          | 底层工作流引擎，连接不同工具（AFNI/FSL/ANTs等）            | ⭐⭐⭐   |

### 💡 为什么要这样做？
- 科学可重复性的核心：明确说明使用的**工具名称、版本、唯一标识符**
- 不同版本的fMRIPrep可能有不同的默认参数，记录版本号至关重要

---

## 第二部分：结构像预处理

### 2.1 偏场校正

```markdown
Each T1w image was corrected for intensity
non-uniformity (INU) with `N4BiasFieldCorrection` [@n4], distributed with ANTs 2.6.2
[@ants, RRID:SCR_004757].
```

#### 🔍 知识点拆解

| 概念 | 解释 |
|------|------|
| **INU / 偏场** | MRI图像中，由于射频线圈不均匀，同一组织在不同位置亮度不同 |
| **N4BiasFieldCorrection** | ANTs中的算法，迭代估计偏场并校正 |

#### 📊 图示理解

```
校正前：                    校正后：
┌────────────────┐         ┌────────────────┐
│ ░░░░▒▒▒▒████░░ │         │ ░░░░░░░░░░░░░░ │
│ 左侧暗，右侧亮   │   →→→   │ 亮度均匀一致     │
└────────────────┘         └────────────────┘
```

#### 💡 为什么要这样做？
- 没有偏场校正：同一组织被错误分割成不同组织
- 直接影响：后续的**组织分割（CSF/WM/GM）准确性**

#### 注意：
这一步在我们原来的脚本是没有进行的。这是一个不足的地方，这会导致组织分割出现问题，靠近颅底的WM可能被错分为GM，小脑区域的CSF被错分为WM。，后续WM/CSF回归会引入错误信号，配准质量下降。

---

### 2.2 颅骨剥离

```markdown
The T1w-reference was then skull-stripped with a *Nipype* implementation of
the `antsBrainExtraction.sh` workflow (from ANTs), using OASIS30ANTs
as target template.
```

#### 🔍 知识点拆解

| 概念 | 解释 |
|------|------|
| **颅骨剥离** | 从T1w图像中去除颅骨、头皮等非脑组织 |
| **OASIS30ANTs** | 一个标准模板（30个OASIS数据平均，ANTs格式） |

#### 💡 为什么要这样做？
- 功能连接分析只需要**大脑组织**
- 头皮/颅骨信号会引入**生理噪声**（心跳、呼吸）
- 提高后续配准的准确性

#### 注意：

原脚本使用的是`AFNI`的`3dSkullStrip`，而不是`antsBrainExtraction`，区别如下：

| 方面       | `3dSkullStrip` (AFNI) | `antsBrainExtraction` (ANTs) |
| -------- | --------------------- | ---------------------------- |
| **算法**   | 边缘检测 + 区域生长           | 模板配准 + 概率图谱                  |
| **速度**   | 快（~2-5秒/被试）           | 慢（~30-60秒/被试）                |
| **鲁棒性**  | 对T1w质量敏感              | 更鲁棒                          |
| **小脑处理** | 经常失败（保留颅骨）            | 较好                           |
| **颅底处理** | 可能过度剥离                | 更准确                          |
##### 3dSkullStrip（传统脚本）

```
步骤1: 边缘检测          步骤2: 区域生长        步骤3: 脑组织提取
┌─────┐                 ┌─────┐                ┌─────┐
│  █  │ 寻找强度梯度      │ ███ │ 从脑中心向外     │███ │
│ ██  │ 大的边界         │█████│ 生长直到遇到     │████│
│  █  │                 │ ███ │ 边界            │███ │
└─────┘                 └─────┘                └─────┘
        ↑                      ↑                      ↑
   依赖强度阈值            依赖初始种子点          容易"跑出去"
```

**常见问题**：
- 小脑区域：颅骨较薄 → 梯度不明显 → 剥离失败
- 低组织对比度：边界检测失败 → 保留颅骨

##### antsBrainExtraction（fMRIPrep）

```
步骤1: 配准到模板        步骤2: 模板mask变换     步骤3: 精细调整
┌─────┐   配准   ┌─────┐   ┌─────┐              ┌─────┐
│你的脑│ ────→   │模板脑│   │mask │ 配准回你的空间 │████ │
│     │         │     │   │  ██ │ ─────────→   │███  │
└─────┘         └─────┘   └─────┘              └─────┘
      ↑                      ↑                       ↑
   利用先验知识           概率性mask           局部精细分割
```

**优势**：
- 利用**模板先验**（知道脑大概在哪里）
- 不依赖局部梯度
- 小脑、脑干、颅底都处理得很好

##### 🧪 实际对比测试

| 场景             | 3dSkullStrip | antsBrainExtraction |
| -------------- | ------------ | ------------------- |
| **高质量T1w**     | 良好           | 优秀                  |
| **低质量T1w（运动）** | 差（常失败）       | 可接受                 |
| **小脑区域**       | 常失败（留颅骨）     | 良好                  |
| **颅底**         | 过度剥离         | 适当                  |
| **儿童脑（较小）**    | 差            | 可（配准调整）             |

##### 💡 对功能连接的影响

```
问题1：剥离不足（保留颅骨/头皮）
┌────────────────┐
│ ██████ 头皮信号 │ ← 引入生理噪声（心跳、呼吸）
│ ████ 颅骨信号   │ ← 信号无生理意义
│ ████ 脑组织     │ ← 目标区域
└────────────────┘
影响：噪声增大，功能连接相关性降低

问题2：过度剥离（丢失脑组织）
┌────────────────┐
│                │
│  ████ 脑组织    │ ← 小脑皮层被剥离
│  ████          │ ← 枕叶部分丢失
└────────────────┘
影响：数据不完整，特别是小脑相关功能连接
```

---

##### 具体受影响的指标：

```
🔴 最受影响：
- 基于WM/CSF的噪声回归（mask不准确）
- 小脑相关功能连接（剥离可能不完整）
- GM体积/厚度的组间比较（偏场影响分割）

🟡 中度影响：
- 全脑功能连接模式
- 种子点相关分析（如果种子点在易错区域）

🟢 影响较小：
- 组内对比（同样的错误系统性地存在）
- 大的功能网络（DMN、FPN等）
```

---

### 2.3 组织分割

```markdown
Brain tissue segmentation of cerebrospinal fluid (CSF),
white-matter (WM) and gray-matter (GM) was performed on
the brain-extracted T1w using `fast` [FSL (version unknown), RRID:SCR_002823, @fsl_fast].
```

#### 🔍 知识点拆解

| 组织 | 缩写 | 在fMRI中的作用 |
|------|------|----------------|
| **脑脊液** | CSF | 噪声回归（生理噪声） |
| **白质** | WM | 噪声回归（无神经活动） |
| **灰质** | GM | **目标区域**（BOLD信号来源） |

#### 📊 分割结果示意图

```
T1w图像 → FAST分割 →
    ├── GM（灰质）: 大脑皮层，BOLD信号来源
    ├── WM（白质）: 内部纤维束，无明显BOLD信号
    └── CSF（脑脊液）: 脑室和脑沟，心脏/呼吸噪声
```

#### 💡 为什么要分割？
- 从WM和CSF提取噪声信号用于后续回归
- 这是**CompCor噪声去除**的基础

---

### 2.4 鲁棒模板构建

```markdown
An anatomical T1w-reference map was computed after registration of
15 <module 'nipype.interfaces.image' from '/app/.pixi/envs/fmriprep/lib/python3.12/site-packages/nipype/interfaces/image.py'> images (after INU-correction) using
`mri_robust_template` [FreeSurfer 7.3.2, @fs_template].
```

#### 🔍 知识点拆解

| 概念 | 解释 |
|------|------|
| **mri_robust_template** | FreeSurfer工具，将多个T1w图像对齐后平均 |
| **15 images** | 如果BIDS中有多个T1w，fMRIPrep会全部利用 |

#### 💡 为什么要这样做？
- 单个T1w可能有伪影或运动
- 多图像平均 → **信噪比更高**的参考图

---

### 2.5 表面重建

```markdown
Brain surfaces were reconstructed using `recon-all` [FreeSurfer 7.3.2,
RRID:SCR_001847, @fs_reconall], and the brain mask estimated
previously was refined with a custom variation of the method to reconcile
ANTs-derived and FreeSurfer-derived segmentations of the cortical
gray-matter of Mindboggle [RRID:SCR_002438, @mindboggle].
```

#### 🔍 知识点拆解

| 概念 | 解释 |
|------|------|
| **recon-all** | FreeSurfer的核心，重建大脑皮层表面 |
| **表面重建** | 生成pial表面、白质表面、膨胀表面 |
| **Mindboggle** | 用于验证分割质量的工具 |

#### 📊 表面 vs 体素

```
体素空间（Volumetric）:        表面空间（Surface）:
┌───┬───┬───┐                  ╱‾‾‾╲
│ █ │ █ │ ◇ │                 ╱     ╲
├───┼───┼───┤                │   ●   │   ● = 皮层顶点
│ ◇ │ █ │ ◇ │                 ╲     ╱
├───┼───┼───┤                  ╲___╱
│ ◇ │ ◇ │ █ │
└───┴───┴───┘
3D立方体网格               2D曲面网格
```

#### 💡 为什么要表面重建？
- 皮层分析（皮层厚度、表面积）
- BOLD信号投影到皮层表面
- **如果不做皮层分析，可以用 `--fs-no-reconall` 跳过**

---

### 2.6 空间标准化

```markdown
Volume-based spatial normalization to one standard space (MNI152NLin2009cAsym) was performed through
nonlinear registration with `antsRegistration` (ANTs 2.6.2),
using brain-extracted versions of both T1w reference and the T1w template.
```

#### 🔍 知识点拆解

| 概念                      | 解释                                          |
| ----------------------- | ------------------------------------------- |
| **MNI152NLin2009cAsym** | 标准模板空间，152个被试平均，2009c版本，非对称                 |
| **非线性配准**               | 使用`antsRegistration`，可以弯曲变形（vs 线性配准只能刚性+仿射） |
| **TemplateFlow**        | 模板管理工具，确保使用正确的模板版本                          |

#### 📊 线性 vs 非线性配准

```
线性配准（FLIRT）:          非线性配准（ANTS）:
┌────┐      ┌────┐          ┌────┐      ┌────┐
│    │      │    │          │    │      │ ⌒ │  ← 可以弯曲
│ ○  │  →   │ ○  │          │ ○  │  →   │ ○  │
│    │      │    │          │    │      │    │
└────┘      └────┘          └────┘      └────┘
只能平移/旋转/缩放          可以局部变形
```

#### 💡 为什么用非线性？
- 每个人大脑形状不同
- 线性配准只能整体对齐，局部错位可达**5-10mm**
- 非线性配准可将错位降到**1-2mm**

---

## 第三部分：功能像预处理

### 3.1 头动校正

```markdown
Head-motion parameters with respect to the BOLD reference
(transformation matrices, and six corresponding rotation and translation
parameters) are estimated before any spatiotemporal filtering using
`mcflirt` [FSL <ver>, @mcflirt].
```

#### 🔍 知识点拆解

| 概念 | 解释 |
|------|------|
| **mcflirt** | FSL的运动校正工具 |
| **6个参数** | 3个平移（x, y, z）+ 3个旋转（roll, pitch, yaw） |
| **参考体积** | 通常用第1个volume或平均volume |

#### 📊 六个运动参数

```
平移 (Translation):          旋转 (Rotation):
  x: 左右移动                  roll:  左右倾斜（绕x轴）
  y: 前后移动                  pitch: 点头抬头（绕y轴）  
  z: 上下移动                  yaw:   左右转头（绕z轴）
```

#### 💡 为什么要运动校正？
- 头动会使体素信号混入相邻体素
- 即使是**0.5mm的头动**也会显著影响功能连接
- 运动校正后，还需要**回归运动参数**去除残余影响

---

### 3.2 功能→结构配准

```markdown
The BOLD reference was then co-registered to the T1w reference using
`bbregister` (FreeSurfer) which implements boundary-based registration [@bbr].
Co-registration was configured with six degrees of freedom.
```

#### 🔍 知识点拆解

| 概念 | 解释 |
|------|------|
| **bbregister** | 基于边界的配准（Boundary-Based Registration） |
| **6自由度** | 3平移 + 3旋转（刚性配准） |
| **边界** | 使用GM/WM边界作为配准特征 |

#### 📊 BBR原理

```
功能像(EPI)           T1w结构像              配准结果
  低分辨率           高分辨率            
   模糊              清晰边界            
   ┌──┐              ┌──┐                 ┌──┐
   │░░│              │██│                 │██│
   │░░│              │██│                 │░░│ ← 功能像边界
   └──┘              └──┘                 └──┘
   对齐到GM/WM边界                        成功配准
```

#### 💡 为什么用BBR而不是普通配准？
- EPI图像分辨率低，GM/WM边界模糊
- BBR利用结构像的**清晰边界**作为参考
- 比基于互信息的配准**精度更高**

---

### 3.3 层时校正

```markdown
BOLD runs were slice-time corrected to 0.545s (0.5 of slice acquisition range
0s-1.09s) using `3dTshift` from AFNI  [@afni, RRID:SCR_005927].
```

#### 🔍 知识点拆解

| 概念 | 解释 |
|------|------|
| **层时校正** | 补偿不同层采集时间差 |
| **0.5参考** | 以中层（第N/2层）为参考，校正其他层 |
| **采集范围0s-1.09s** | TR=2.18s，每层间隔约1090ms/层数 |

#### 📊 层时校正原理

```
未校正（TR=2s，10层）:         校正后（所有层对齐到中层）:
时间 →
层1 ■■■■■□                    层1 ■■■■■□
层2  ■■■■■□                   层2 ■■■■■□
层3   ■■■■■□                  层3 ■■■■■□
...                           每层信号都被时间平移
层10     ■■■■■□               使其在时间上对齐
```

#### 💡 为什么要层时校正？
- 不同层在不同时刻采集，但被当作同时处理
- 功能连接分析假设**同时性**
- 特别是TR较长（>2s）时，层时差异可达**1秒以上**

---

### 3.4 噪声指标计算

```markdown
Several confounding time-series were calculated based on the
*preprocessed BOLD*: framewise displacement (FD), DVARS and
three region-wise global signals.
FD was computed using two formulations following Power (absolute sum of
relative motions, @power_fd_dvars) and Jenkinson (relative root mean square
displacement between affines, @mcflirt).
```

#### 🔍 知识点拆解

| 指标 | 计算方式 | 阈值 | 含义 |
|------|----------|------|------|
| **FD (Power)** | 运动参数的绝对差值求和 | >0.5mm | 头动剧烈 |
| **FD (Jenkinson)** | 仿射矩阵间的RMS位移 | 同左 | 另一种头动估计 |
| **DVARS** | 全脑信号一阶微分的RMS | >1.5 | 信号突变 |
关于这部分的具体分析，详见 [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/confounds参数详解|confounds 参数详解]]。

#### 📊 FD和DVARS的可视化

```
FD (mm)                          DVARS (变化量)
2.0│      ▲                      150│  ▲
1.5│    ▲     ▲                   100│ ▲ ▲
1.0│  ▲ ▲   ▲                阈值→ 50│▲ ▲ ▲
0.5┼────────▲────────                 └────────
   │     异常帧                       ← 异常帧
   └──────────────────                   识别
```

#### 💡 为什么计算这些指标？
- 识别需要**censoring（删除）的坏帧**
- 排除运动过多的被试
- 作为论文中的质量报告

---

### 3.5 CompCor噪声回归

```markdown
Additionally, a set of physiological regressors were extracted to
allow for component-based noise correction [*CompCor*, @compcor].
Principal components are estimated after high-pass filtering the
*preprocessed BOLD* time-series (using a discrete cosine filter with
128s cut-off) for the two *CompCor* variants: temporal (tCompCor)
and anatomical (aCompCor).
```

#### 🔍 知识点拆解

| 概念           | 解释                        |
| ------------ | ------------------------- |
| **CompCor**  | 基于主成分分析的噪声去除方法            |
| **aCompCor** | 用结构像定义的WM/CSF mask中的PCA成分 |
| **tCompCor** | 用功能像中变异最大的2%体素的PCA成分      |
| **高通128s**   | 去除<0.008Hz的超低频漂移          |

#### 📊 CompCor原理

```
简单平均信号（老方法）:        CompCor（fMRIPrep方法）:
        
WM区域 → 平均 → 1个信号        WM区域 → PCA →  主成分1 (方差70%)
                                          →  主成分2 (方差15%)  
CSF区域 → 平均 → 1个信号        CSF区域 → PCA →  主成分1 (方差60%)
                                          →  主成分2 (方差10%)
       总回归量 = 2                 总回归量 = 4-6（根据需要保留）
```

#### 💡 为什么CompCor更好？
- 单一平均信号假设WM/CSF内信号均匀 → **不成立**
- PCA保留最重要的噪声成分
- 用更少的回归量解释更多的噪声方差

参见 [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/CompCor与噪声回归|CompCor 与噪声回归]]。

---

### 3.6 非线性扩展

```markdown
The confound time series derived from head motion estimates and global
signals were expanded with the inclusion of temporal derivatives and
quadratic terms for each [@confounds_satterthwaite_2013].
```

#### 🔍 知识点拆解

| 扩展项 | 公式 | 作用 |
|--------|------|------|
| **原始** | x(t) | 当前时刻噪声 |
| **一阶导数** | x'(t) | 前一时刻噪声的影响 |
| **二次项** | x²(t) | 非线性噪声成分 |

#### 💡 为什么要扩展？
- 噪声模型更灵活
- 原始27个回归量 → 扩展到81个（6运动×3 + 全局×3 + WM×3 + CSF×3）
- Satterthwaite 2013证明能更有效去除噪声

---

## 📊 完整流程图解

```
原始BOLD数据
    │
    ├─→ 头动校正（mcflirt）→ 6个运动参数 → 扩展（导数+平方）→ 18个
    │
    ├─→ 层时校正（3dTshift）
    │
    ├─→ 配准到T1（bbregister）
    │
    └─→ 噪声估计
          │
          ├─→ aCompCor（WM/CSF PCA）→ 约6个
          ├─→ tCompCor（变异体素PCA）→ 约6个
          ├─→ 全局信号 → 3个（原始+导数+平方）
          └─→ FD/DVARS → 质量评估
```

---

## 🎯 对你做CAPs的影响

| fMRIPrep步骤 | 对CAPs是否必要 | 说明 |
|-------------|---------------|------|
| 偏场校正 | ✅ 必要 | 提高分割质量 |
| 颅骨剥离 | ✅ 必要 | 减少噪声 |
| 组织分割 | ✅ 必要 | 用于WM/CSF回归 |
| 表面重建 | ❌ 可跳过 | CAPs通常用体素空间 |
| 非线性配准 | ✅ 理想 | 组水平对齐更好 |
| 头动校正 | ✅ 必要 | |
| 层时校正 | ✅ 建议 | 特别是TR>2s |
| CompCor | ⚠️ 替代方案 | CAPs论文用简单平均 |
| 导数/二次扩展 | ✅ 建议 | 提高噪声去除效果 |

---

## 📝 论文中需要报告的内容

基于这份CITATION.md，你需要在论文的方法部分报告：

```markdown
fMRI data were preprocessed using fMRIPrep 25.2.5 [RRID:SCR_016216]. 
Key preprocessing steps included:
- Intensity non-uniformity correction (N4BiasFieldCorrection)
- Skull stripping (antsBrainExtraction.sh) using OASIS30ANTs template
- Tissue segmentation (FAST) into CSF, WM, and GM
- Head motion correction (mcflirt) with 6 affine parameters
- Slice-time correction (3dTshift) to middle slice
- Boundary-based registration (bbregister) from functional to T1w
- Nonlinear registration (antsRegistration) to MNI152NLin2009cAsym space
- Nuisance regression using aCompCor (WM/CSF PCA components), 
  global signal, and motion parameters with temporal derivatives and 
  quadratic terms
- Frames with FD > 0.5 mm or DVARS > 1.5 were marked as outliers
```

---

希望这个逐段解析对你有帮助！如果你想深入了解某个具体步骤（比如CompCor的计算细节，或者如何解读HTML可视化报告），请告诉我！
