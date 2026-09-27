---
title: micapipe 结构处理与 SC-FC 实施方案
draft: true
tags:
  - 科研
  - MyConnectome
  - micapipe
  - 结构功能耦合
---

## 项目定位

本项目保留既有 propagation 分析为主线，并将 SC-FC coupling 作为机制性扩展：检验不同 fMRI session 的 FC 与同一稳定个人 SC 估计之间的对齐程度。该设计不将单次 DWI 的差异直接解释为白质在短期内重塑。

## 已确定的实施决策

- 主分析使用 400 个皮层 ROI 的 `Schaefer-400` atlas；皮层下和小脑节点在确认可与 FC 严格对应前不纳入主分析。
- 以 `ses-015` 作为固定解剖锚点。其 micapipe 结构、表面和 atlas 阶段已完成，但正式接受前仍需视觉 QC。
- 以 `ses-013` 作为 DWI 技术验证对象，而非最终稳定 SC 的唯一来源。该 session 的 LR/RL DWI 相位编码方向相反，且 `TotalReadoutTime` 一致。
- FC 不重跑 micapipe `-proc_func`；拟从既有 fMRIPrep 后处理的 clean BOLD 提取，以保持与既有 propagation 分析一致的信号定义。
- 主分析单位是 fMRI session：每个通过 QC 的 session 产生一张 FC，并与稳定 SC 比较。DWI sessions 的作用是评估 SC 稳定性和构建稳定参考，而不是与每个 fMRI session 同日配对。

## 当前完成状态

| 阶段 | 状态 | 说明 |
| --- | --- | --- |
| Docker 与 micapipe 镜像 | 已确认可用 | 不代表处理已完成。 |
| 固定结构锚点 | 流程完成，QC 待审 | 已运行结构、表面和 Schaefer-400 atlas 模块。 |
| DWI pilot | 输入元数据已核对 | 尚未确认 `-proc_dwi`、`-SC` 或 QC 结果。 |
| FC 提取 | 方案已确定 | 尚未批量提取或验证 parcel 对应。 |
| 稳定 SC 与 coupling | 未开始 | 需在各项 QC 后预先固定规则。 |

## DWI 与 SC 实施闸门

对每个计划纳入的 DWI session：

1. 核对主 DWI 与反向相位编码 DWI、bval/bvec 和 JSON 元数据。
2. 运行并检查 `-proc_dwi` 的 eddy 输出、DWI-T1 配准、brain mask、5TT、FOD 和 TDI。
3. QC 合格后运行 SC；所有 session 使用一致的 atlas、tractography 参数和输出规则。
4. 保存每张 SC 的 ROI 标签顺序、边权定义和 QC 指标。
5. 比较合格 SC 的相似性与质量，预先指定 medoid 或 consensus 稳定 SC 的规则。

## FC 与 coupling 实施闸门

1. 用最近邻插值将同一 `Schaefer-400` 标签图匹配至每个 clean BOLD 的网格。
2. 保存每个 parcel 的覆盖情况、标签表、时间点数和运动 QC 指标。
3. 在确认 SC 与 FC 的 parcel 标签及行列顺序完全一致后，才逐边计算 coupling。
4. 将所有皮层边、非零 SC 边、稳定 SC 定义、运动、平滑、GSR 和距离影响列为预先标记的敏感性分析。

## 不应作出的结论

- 单次 tractography 差异不能证明真实白质重塑。
- SC-FC coupling 高低不天然代表更健康或更有效。
- coupling 与 propagation 的关联不证明神经因果方向。

## 相关笔记

- [[关于科研经历/06-科研日志/2026-09-27|2026-09-27 科研日志]]
- [[关于科研经历/02-方法库/神经影像/多session结构-功能耦合分析|可复用的 SC-FC 方法]]
- [[关于科研经历/01-研究项目/MyConnectome-CAPs/质量控制/index|项目质量控制]]

[[关于科研经历/01-研究项目/MyConnectome-CAPs/数据与运行记录/index|返回数据与运行记录]]
