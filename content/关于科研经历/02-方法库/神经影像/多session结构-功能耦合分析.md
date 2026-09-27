---
title: 多 session 结构-功能耦合分析
draft: true
tags:
  - 科研
  - 方法
  - 神经影像
  - 结构功能耦合
  - micapipe
---

## 适用问题

当同一个体有多次 fMRI、但结构连接（SC）预期相对稳定时，可检验每次功能连接（FC）在多大程度上与稳定 SC 对齐。该方法描述 FC 相对所选结构估计的统计一致性，不把它当作因果连接或白质变化的直接证据。

```text
稳定 SC + 某次 fMRI 的 FC -> session 级 SC-FC coupling
```

## 概念与主指标

- **SC**：由 DWI tractography 得到的脑区间连接权重，例如 streamline 数或 SIFT2 权重。它是通路的估计，不是轴突计数。
- **FC**：同一次扫描中 ROI BOLD 时间序列的统计依赖，常用 Pearson 相关；它不等于解剖连接或因果影响。
- **SC-FC coupling**：同一组脑区对上，SC 边权模式与 FC 边权模式的相关。

对每个 fMRI session `s`，去除对角线并严格配对两个矩阵的上三角边。对非负、偏态 SC 边可使用预先指定的变换：

```text
C_s = cor(upper_triangle(log(1 + SC_stable)),
          upper_triangle(FC_s))
```

相关类型、SC 变换、零边处理和分析边集必须在查看状态关联前固定。除全脑 `C_s` 外，也可固定某个 ROI，比较其 SC 与 FC 行向量，得到区域耦合图。

## 前置条件

1. SC 和 FC 必须使用同一 atlas、相同 ROI 标签与完全相同的行列顺序。两个矩阵同为 `N x N` 并不能保证节点对应。
2. 保存每张矩阵的 parcel 标签表，并在计算前程序化比较标签和顺序。
3. 先明确主分析使用哪些节点。若皮层下或小脑 FC 的标签对应尚未验证，应先限制至已验证的皮层 ROI。
4. 将每个 fMRI session 的时间点数、ROI 覆盖情况、运动和其他 QC 指标与 FC 一同保存。

## 从 DWI 到可用 SC

### 1. 固定解剖参考

先完成结构处理、表面重建和目标 atlas 到个体空间的映射。视觉检查 brain mask、white surface、pial surface 和 atlas 映射；这些步骤不合格时，后续 DWI-SC 都可能因 ROI 错配而失效。

### 2. 单 session DWI 验证

在批量处理前，选择一个具备完整元数据的 DWI 做技术验证：

1. 核对主 DWI、反向相位编码 DWI、bval/bvec 和 JSON 元数据。
2. 反向相位编码采集都含完整扩散加权 volumes 时，按工具文档使用适配的完整 RPE 模式，例如 micapipe 的 `-rpe_all`。
3. 检查 eddy/运动估计、校正后的 b=0 与结构像配准、DWI brain mask、组织约束、FOD 和低密度 TDI。
4. 仅在上述 QC 合格后运行 tractography 和 connectome 生成。

SC 的 tractography 参数、atlas、边权定义和后处理必须跨 session 保持一致。streamline 数是计算采样参数，不是生物学纤维数量。

### 3. 稳定 SC 的定义

不要未经检查直接平均多张单次 SC。建议：

1. 对每张合格 SC 使用同一节点集合和边权变换。
2. 计算 SC 间相似性，并与 DWI 运动、配准和其他 QC 对照。
3. 预先指定稳定参考：可选择与其余 SC 平均相似性最高的 medoid SC；共识 SC 可作为敏感性分析。

单次 DWI-SC 的差异可能来自头动、SNR、校正、tractography 随机性或分区误差，不能直接解释为白质重塑。

## 从 BOLD 到 FC

1. 选择已经定义好预处理策略的 BOLD，并避免为 coupling 临时加入未预先声明的滤波、回归或 censoring。
2. 将离散 atlas 标签图重采样到 BOLD 网格时使用最近邻插值，避免线性插值混合 ROI 标签。
3. 提取每个 ROI 的平均时间序列，记录覆盖不足的 ROI。
4. 计算 ROI 间相关得到 FC；如后续模型需要，可对 FC 边进行 Fisher `r-to-z` 变换。

空间平滑、全局信号回归和运动处理会改变 FC 定义。若它们可能影响结论，应作为清楚标记的敏感性分析，而不是在主分析中隐式改变。

## 统计与稳健性

每个 fMRI session 对应一个全脑 coupling 值及其 QC 协变量。若将 coupling 与状态、行为或其他 session 级指标关联：

- 预先定义协变量，如 mean FD 和扫描质量。
- 考虑重复测量的时间结构；同一个体的多次 session 不是独立人群样本。
- 区域耦合涉及多重比较，应报告效应量、空间图和合适的校正。
- 至少检查稳定 SC 的选择、全边/非零 SC 边、距离影响、平滑、全局信号和高运动 session 排除的敏感性。

距离尤其重要：相邻脑区往往同时有更高的结构与功能相关，未处理的距离效应可能夸大 coupling。

## 可解释范围

可以表述为：某次 FC 与所选稳定 SC 更一致或更不一致；该对齐程度与预先指定的变量存在关联。

不能表述为：某条白质纤维导致特定 BOLD 事件；单次 tractography 差异证明真实结构重塑；或 coupling 关联证明神经因果方向。

## 实施检查表

- [ ] 结构、表面和 atlas 视觉 QC 合格。
- [ ] 每个纳入 DWI 的元数据和 DWI QC 合格。
- [ ] SC 与 FC 的 parcel 标签和顺序已程序化验证。
- [ ] 稳定 SC 规则、主指标与敏感性分析已预先确定。
- [ ] FC 的去噪定义、运动协变量和排除规则已记录。
- [ ] 主分析与探索性分析分开报告。

## 相关项目实践

- [[关于科研经历/01-研究项目/MyConnectome-CAPs/数据与运行记录/micapipe结构处理与SC-FC实施方案|MyConnectome 的 micapipe 实施方案]]

## 参考文献

- Honey, C. J., et al. (2009). *Predicting human resting-state functional connectivity from structural connectivity*. PNAS, 106(6), 2035-2040. https://doi.org/10.1073/pnas.0811168106
- Suárez, L. E., Markello, R. D., Betzel, R. F., & Mišić, B. (2020). *Linking structure and function in macroscale brain networks*. Trends in Cognitive Sciences, 24(4), 302-315. https://doi.org/10.1016/j.tics.2020.01.008
- Vázquez-Rodríguez, B., et al. (2019). *Gradients of structure-function tethering across neocortex*. Nature Communications, 10, 4460. https://doi.org/10.1038/s41467-019-13622-3

[[关于科研经历/02-方法库/神经影像/index|返回神经影像方法]]
