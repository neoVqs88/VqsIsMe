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
- 以 `ses-015` 作为固定解剖锚点。其 micapipe 结构、表面和 atlas 阶段已完成，视觉 QC 已确认可用。
- 以 `ses-013` 作为 DWI 技术验证对象，而非最终稳定 SC 的唯一来源。该 session 的 LR/RL DWI 相位编码方向相反，且 `TotalReadoutTime` 一致；主 DWI 采用 LR，反向相位编码校正采用 LR/RL b=0 pair。
- FC 不重跑 micapipe `-proc_func`；拟从既有 fMRIPrep 后处理的 clean BOLD 提取，以保持与既有 propagation 分析一致的信号定义。
- 主分析单位是 fMRI session：每个通过 QC 的 session 产生一张 FC，并与稳定 SC 比较。DWI sessions 的作用是评估 SC 稳定性和构建稳定参考，而不是与每个 fMRI session 同日配对。

## 当前完成状态

| 阶段 | 状态 | 说明 |
| --- | --- | --- |
| Docker 与 micapipe 镜像 | 已确认可用 | 不代表处理已完成。 |
| 固定结构锚点 | 完成，QC 已确认 | 已运行结构、表面和 Schaefer-400 atlas 模块。 |
| DWI/SC pilot | 400 节点候选 SC 已生成，QC 待审 | `-rpe_all` 在 volume 配对阶段失败后，以 `rpe_pair` 完成 `proc_dwi` 的 11/11 步；随后 `ses-013` 的 10M SIFT2 SC 已完成。已从 450 节点输出派生对称、零对角的 400 节点皮层 SC 与标签表；尚须检查 TDI/tractography，并在 FC 生成后验证标签顺序。 |
| FC 提取 | 方案已确定 | 尚未批量提取或验证 parcel 对应。 |
| 稳定 SC 与 coupling | 未开始 | 需在各项 QC 后预先固定规则。 |

## 阶段验证台账

| 阶段 | 为什么做 | 当前产物 | 已完成的验证 | 尚未完成的验证 | 当前决策 |
| --- | --- | --- | --- | --- | --- |
| 固定结构锚点 | 为 DWI、tractography 和 FC 提供同一解剖参考与 `Schaefer-400` atlas。 | 表面、组织分割、个体 atlas。 | 结构视觉 QC 已确认可用。 | 无阻断性检查。 | 可作为后续阶段的固定参考。 |
| DWI 输入与 RPE 决策 | 确保扩散方向、反向 PE 与畸变校正信息可解释。 | 已验证 LR/RL 文件、bval/bvec 与 JSON。 | LR/RL PE 相反且 readout time 一致；完整 `rpe_all` 配对失败已定位。 | 不再尝试未经验证的梯度修改。 | 使用 LR 主 DWI 与 LR/RL b=0 pair。 |
| DWI 预处理 | 校正噪声、Gibbs、运动和 EPI 畸变，并构建 FOD/5TT。 | 预处理 DWI、b=0、mask、DTI、FOD、5TT、eddy QC。 | `proc_dwi` 11/11 步完成；输入 shell 数量正确；协作者未要求停止或重处理。 | eddy 的高 outlier 壳层仍是质量限制，需结合后续图像解释。 | 仅批准单 session SC pilot。 |
| SC tractography | 由 FOD、组织约束和 atlas 估计脑区间结构通路。 | 10M SIFT2 SC、TDI、450 节点 connectome。 | `SC-10M` 1/1 步完成；connectome slicer 成功运行。 | TDI/tractography 视觉 QC。 | 不批量运行其他 session SC。 |
| 400 皮层 SC 派生 | 使 SC 与主分析的 400 皮层 FC 节点集合相同。 | 对称、零对角 SIFT2/edge-length 矩阵及 400 标签表。 | 450 节点 LUT 构成已核对；正确排除 48 非皮层与 2 medial-wall 节点；矩阵为 400 x 400、对称、标签数为 400。 | TDI QC；未来 FC 标签顺序验证。 | 可作为候选 SC，不可直接解释 coupling。 |
| FC 与 coupling | 用相同 ROI 比较功能边权与结构边权。 | 尚无本轮 FC/coupling 输出。 | 已固定使用既有 clean BOLD 的原则。 | BOLD atlas 对齐、ROI 覆盖、FC 质量、SC/FC 标签一致性。 | 尚不开始 coupling。 |

这张台账是本项目的放行规则：任一阶段的“尚未完成验证”若会改变下一阶段输入或节点定义，就不能用“软件已完成”替代 QC。

## 当前 DWI 处理路径

`ses-013` 的原始尝试使用 `-rpe_all`：这要求 LR 与 RL 的每个扩散加权 volume 都能按梯度方向逐一配对。该步骤在 `dwifslpreproc` 中失败，因此没有产生可用的 DWI 预处理结果。

当前成功完成的 `proc_dwi` 使用 LR 作为主 DWI，并从 LR/RL 中提取 b=0 pair 估计 EPI 畸变场。随后针对 LR 的完整扩散加权数据完成 eddy、扩散模型和 FOD 等步骤。该选择不修改原始 LR/RL 数据，也不声称使用了两套完整 DWI 的合并信息。

目前已得到单 session 的 SC 衍生物，但尚不是可用于 coupling 的最终 SC。micapipe 的 connectome slicer 报告 atlas 级输出为 450 x 450：48 个皮层下/小脑节点、2 个 medial-wall 占位节点和 400 个 Schaefer 皮层 parcel。按 v0.2.3 LUT 的升序 `mics` 顺序，需以 Python 索引 `49:249` 与 `250:450` 提取皮层矩阵；在保存标签表并完成 tractography/connectome QC 前，不能将其与 400 节点 FC 配对。

## 刚完成的 400 节点 SC 是什么

micapipe 先以完整 atlas 生成 450 节点 GIFTI connectome。该版本的 MRtrix 输出只填充上三角，因此原始矩阵显示为非对称；这表示无向边的紧凑编码，不是方向性 SC 或 tractography 失败。

随后执行了三个不可混淆的步骤：

1. 根据内置 LUT 保留 400 个皮层 parcel，并排除 48 个皮层下/小脑节点和 2 个 medial-wall 占位节点。
2. 保存原始上三角矩阵作为审计版本。
3. 将上三角镜像到下三角、将对角线设为零，得到候选无向 SC 矩阵；同时保存完全同序的 400 行标签表。

这样做的目的不是改变 tractography 结果，而是把 micapipe 的存储格式转换为网络分析所需的方阵表示。后续 FC 也必须使用该标签表验证节点一一对应；矩阵同为 400 x 400 不足以证明可配对。

## DWI 与 SC 实施闸门

对每个计划纳入的 DWI session：

1. 核对主 DWI 与反向相位编码 DWI、bval/bvec 和 JSON 元数据。
2. 若完整 LR/RL DWI 的 `-rpe_all` 无法完成逐 volume 配对，则使用主 DWI 加 LR/RL b=0 pair 的 RPE 校正；确认日志实际使用 `-rpe_pair -align_seepi`。
3. 运行并检查 `-proc_dwi` 的 eddy 输出、DWI-T1 配准、brain mask、5TT、FOD 和 TDI。
4. QC 合格后运行 SC；所有 session 使用一致的 atlas、tractography 参数和输出规则。
5. 保存每张 SC 的 ROI 标签顺序、边权定义和 QC 指标。
6. 比较合格 SC 的相似性与质量，预先指定 medoid 或 consensus 稳定 SC 的规则。

runner 的 `qc-dwi <ses-XXX>` 命令只列出本次处理的 QC card、eddy 报告和关键 DWI 输出，用于在不重跑处理的前提下定位人工 QC 所需文件。

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
- [[关于科研经历/06-科研日志/2026-09-28|2026-09-28 科研日志]]
- [[关于科研经历/06-科研日志/2026-10-06|2026-10-06 科研日志]]
- [[关于科研经历/06-科研日志/2026-10-07|2026-10-07 科研日志]]
- [[micapipe runner 使用指南|项目 runner 使用指南]]
- [[关于科研经历/02-方法库/神经影像/micapipe DWI 到结构连接工作流|micapipe DWI 到 SC 工作流]]
- [[关于科研经历/02-方法库/神经影像/多session结构-功能耦合分析|可复用的 SC-FC 方法]]
- [[关于科研经历/01-研究项目/MyConnectome/质量控制/index|项目质量控制]]

[[关于科研经历/01-研究项目/MyConnectome/数据与运行记录/index|返回数据与运行记录]]
