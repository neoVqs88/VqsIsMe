---
title: micapipe DWI 到结构连接工作流
draft: false
tags:
  - 科研
  - 方法
  - 神经影像
  - micapipe
  - DWI
  - 结构连接
---

## 适用范围

本笔记说明如何将 BIDS 格式的 DWI 通过 micapipe 转为可审查的个体结构连接（SC）。适用于单个或多个 DWI session 均可用、并且已有可用 T1w 结构处理结果的情形。

它描述的是可复现的处理与质量控制框架。

## 它不以 fMRIPrep 输出为输入

micapipe 的 DWI-SC 流程读取原始 BIDS 的 T1w、DWI、bval、bvec 和采集 JSON；它不读取 fMRIPrep 的预处理 BOLD 或 confounds。

| 工具/阶段 | 输入模态 | 输出 | 在结构-功能研究中的角色 |
| --- | --- | --- | --- |
| micapipe 结构与 DWI/SC | T1w、DWI 与采集元数据 | 表面、atlas、FOD、tractogram、SC | 提供结构估计。 |
| fMRIPrep 与 BOLD 后处理 | BOLD、T1w 与采集元数据 | 预处理 BOLD、confounds、clean BOLD | 提供用于 FC 的时间序列。 |
| FC/coupling 分析 | clean BOLD、atlas、SC | FC 与 SC-FC coupling | 在标签严格对应后整合两种结果。 |

因此，已有 fMRIPrep 数据不表示可以跳过 DWI 的 micapipe 处理；反过来，micapipe 也不替代既定的 FC 预处理定义。

## 处理链条

```text
T1w 结构处理与 atlas
  -> DWI 输入/元数据验证
  -> 去噪、Gibbs 校正、TOPUP/eddy
  -> b=0-T1 配准、brain mask、5TT
  -> 扩散模型与 FOD
  -> DWI QC
  -> tractography 与 connectome
  -> SC QC、标签验证与稳定性评估
```

前一阶段的文件存在或软件报告完成，只表示可以进入下一阶段的检查；它不等于下一阶段自动获得科学上的有效性。

## 前置条件

1. 原始数据符合 BIDS，并有 DWI NIfTI、`bval`、`bvec` 与 JSON 元数据。
2. JSON 包含有效的 `PhaseEncodingDirection` 和 `TotalReadoutTime`。
3. T1w 的结构、表面和目标 atlas 已完成视觉 QC。
4. Docker/micapipe、FreeSurfer license、足够的磁盘空间和临时目录可用。
5. 在批量运行前，先选择一个 DWI session 做 pilot。

## 推荐的分阶段命令模式

以下是 runner 的抽象接口；将 `<RUNNER>` 替换为本地项目脚本，`ses-XXX` 替换为待处理 session。

```bash
# 1. 只验证输入，不处理数据
<RUNNER> verify-dwi ses-XXX

# 2. 结构 QC 通过后进行 DWI 预处理
<RUNNER> dwi ses-XXX --reviewed-structural-qc

# 3. 定位 QC 报告与关键衍生物
<RUNNER> qc-dwi ses-XXX

# 4. DWI QC 通过后才生成结构连接
<RUNNER> sc ses-XXX --reviewed-dwi-qc
```

显式的 QC 标记不是软件检查，而是操作者对前一阶段图像已经阅读的声明。批量命令应在 pilot SC 通过后使用。

## 每个阶段的输入、输出与问题

| 阶段 | 主要输入 | 关键输出 | 必须回答的问题 |
| --- | --- | --- | --- |
| 结构处理 | T1w | 表面、组织分割、atlas | atlas 和脑组织边界是否合理？ |
| DWI 验证 | DWI、bval/bvec、JSON | 验证结果 | 文件、方向、readout time 是否一致？ |
| DWI 预处理 | 主 DWI、可选 RPE | 预处理 DWI、b=0、mask、DTI、FOD、5TT | 运动与畸变校正后图像是否可信？ |
| DWI QC | eddy 报告与影像衍生物 | QC 判断 | 是否存在明显 dropout、错配或掩膜问题？ |
| SC | FOD、5TT、atlas | tractogram、TDI、connectome | 追踪和脑区标签是否可信？ |

## RPE：`rpe_all` 与 `rpe_pair`

反向相位编码（RPE）主要用于估计 EPI susceptibility distortion。它不是自动增加一套独立、可直接合并的白质证据。

- **`rpe_all`：** 主采集与反向采集的完整 DWI 一起参与校正。要求每个扩散加权 volume 在相反 PE 采集中可按 b 值与梯度方向匹配。只有在梯度表、volume 顺序和图像方向都已验证兼容时使用。
- **`rpe_pair`：** 从主/反向采集中各取 b=0 图像构建畸变场；后续模型与 tractography 使用主采集的完整 DWI。它不使用反向采集的扩散加权 volume。

若完整 RPE 模式报出 volume 无法匹配，不应在没有独立验证的情况下手工翻转 bvec 或修改原始元数据。优先采用 b=0 pair 是较保守的选择，但应在方法中明确：最终扩散模型只使用主 DWI。

## DWI QC：软件完成与可分析的区别

`COMPLETED` 说明命令成功结束。DWI 是否可作为 tractography 输入，至少要依次检查：

1. **eddy 报告：** 平均运动、outlier slice、残差与平均 b-shell 图。高 outlier 尤其集中于单一 b-shell 时，必须检查对应图像和受影响 volume。
2. **校正 b=0 到 T1 配准：** 脑轮廓、主要脑室和皮层边界不应系统性偏移。
3. **brain mask 与 5TT：** 不应大面积漏掉脑组织，或把颅骨、眼眶等纳入脑掩膜。
4. **WM FOD 与低密度 TDI：** 白质信号应连续、解剖上合理，没有明显截断、条纹或全脑方向性异常。

没有单一通用的 outlier 百分比阈值。应结合异常是否集中、图像外观、运动、残差和研究目标决定保留、重处理或排除 session。

## SC 生成与 QC

在 DWI QC 合格后，micapipe 使用 FOD、组织约束和 atlas 进行 tractography/connectome 汇总。每个 session 必须固定：

- atlas 与 ROI 节点集合；
- streamline 数、追踪和加权参数；
- connectome 边权定义与后处理；
- QC 与排除标准。

SC 后检查 tractography/TDI 的空间分布、connectome 是否存在异常空行列，以及 ROI 标签和行列顺序。矩阵维度相同不证明节点一一对应；后续与 FC 比较前必须程序化验证标签和顺序。

## 常见失败与处理原则

| 现象 | 不应做的事 | 首选下一步 |
| --- | --- | --- |
| Docker、镜像或 license 错误 | 反复启动处理。 | 先修复运行环境。 |
| 缺少 DWI 元数据或 LR/RL readout time 不一致 | 猜测或手写 JSON 值。 | 回到采集/BIDS 元数据核对。 |
| `rpe_all` volume 配对失败 | 盲目修改 bvec。 | 验证兼容性；必要时使用 b=0 pair。 |
| 软件完成但 eddy outlier 高 | 直接运行 SC。 | 阅读报告、平均 b-shell 和残差图。 |
| SC 矩阵已生成 | 立即解释边权为生物学纤维数量。 | 先完成 tractography、标签和跨 session QC。 |

## 可解释范围

SC 是基于扩散模型和 tractography 得到的连接估计。它受采集质量、校正、模型、追踪、atlas 和参数影响。跨 session 差异首先应视为测量稳定性问题；只有在严格 QC 与预注册规则支持下，才讨论其与功能或行为变量的关系。

## 相关笔记

- [[关于科研经历/02-方法库/神经影像/DWI、DTI与脑连接指标入门|DWI、DTI 与脑连接指标入门]]
- [[关于科研经历/02-方法库/神经影像/多session结构-功能耦合分析|多 session 结构-功能耦合分析]]

[[关于科研经历/02-方法库/神经影像/index|返回神经影像方法]]
