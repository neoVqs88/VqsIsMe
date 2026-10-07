---
title: micapipe Runner 使用指南
draft: true
tags:
  - 科研
  - MyConnectome
  - micapipe
  - Docker
  - DWI
  - SC
---

## 这份脚本解决什么问题

`run_myconnectome_micapipe.sh` 是本项目调用 micapipe 的 Bash runner。该程序会使用 micapipe 将结构处理、DWI 预处理、QC 文件定位和结构连接（SC）生成拆为明确阶段，并在运行前检查最容易出错的条件。

它的目标是让每一次处理都回答三个问题：输入是否正确、当前允许运行哪个阶段、结果应该去哪里检查。

## 整体流程

```text
固定结构像
  -> structure
  -> 人工结构 QC
  -> verify-dwi
  -> dwi
  -> DWI QC
  -> sc
  -> tractography/connectome QC
  -> 多张合格 SC 的稳定性评估
  -> 与既有 clean BOLD 构建的 FC 进行 coupling 分析
```

项目中固定结构锚点与 DWI session 可以不同：结构像提供稳定的表面、组织分割和 atlas，DWI session 提供扩散方向信息。这样做不把单次 DWI 的差异直接解释为短期白质重塑。

## micapipe 与 fMRIPrep 的输入输出

这两个工具服务于不同数据模态，不能互相替代。

```text
原始 BIDS 的 T1w + 原始 BIDS 的 DWI
  -> micapipe
  -> 个体表面、atlas、预处理 DWI、FOD、tractogram、SC

原始 BIDS 的 BOLD + T1w
  -> 已有 fMRIPrep 与后处理流程
  -> clean BOLD、confounds
  -> 独立 FC 提取

micapipe SC + 从 clean BOLD 提取的 FC
  -> 在相同 atlas 标签顺序下计算 SC-FC coupling
```

当前 runner 传给 micapipe 的是原始 BIDS 根目录中的 T1w 和 DWI，不是 fMRIPrep 输出。`structure` 读取 T1w；`dwi` 读取 LR/RL DWI、bval、bvec 和 JSON；`sc` 复用 micapipe 已生成的结构和 DWI 衍生物。

已有的 fMRIPrep clean BOLD 不进入 `structure`、`dwi` 或 `sc`。它会在之后的 FC 阶段与同一 `Schaefer-400` atlas 一起使用，提取 ROI 时间序列和 FC 矩阵。

| 阶段 | 输入 | 主要输出 | 使用 fMRIPrep 衍生物？ |
| --- | --- | --- | --- |
| `structure` | 原始 T1w、license | 表面、组织分割、个体 atlas | 否 |
| `dwi` | 原始 LR/RL DWI、bval/bvec、JSON、结构结果 | 预处理 DWI、b=0、mask、DTI、FOD、5TT | 否 |
| `sc` | FOD、5TT、atlas、DWI-T1 变换 | tractogram、TDI、SC 矩阵 | 否 |
| FC 提取 | clean BOLD、对应 atlas | ROI 时间序列、FC 矩阵 | 是 |
| coupling | 通过 QC 的 SC 和 FC | session 级 coupling | 间接使用 |

## 脚本如何组织

### 1. 配置区

脚本开头将数据、输出、临时目录、日志、容器镜像、线程数和 streamline 数定义为环境变量。默认值服务于本项目，但可在运行前覆盖，例如：

```bash
THREADS=12 TRACTS=5M <RUNNER_DIR>/run_myconnectome_micapipe.sh sc ses-013 --reviewed-dwi-qc
```

常用变量的角色如下：

| 变量                   | 作用                                   |
| -------------------- | ------------------------------------ |
| `BIDS`               | 原始 BIDS 数据的只读输入目录。                   |
| `OUT`                | micapipe 衍生物输出目录。                    |
| `TMP`                | 临时工作目录；处理失败时可能保留诊断文件。                |
| `LOG_DIR`            | 每次容器运行的终端日志。                         |
| `STRUCTURAL_SESSION` | 固定解剖锚点。                              |
| `THREADS`            | 容器可用 CPU 线程数。                        |
| `TRACTS`             | 每次 SC tractography 的 streamline 采样数。 |

### 2. 保护机制

- `set -Eeuo pipefail`：未定义变量、失败命令或管道失败都会停止脚本，避免错误被忽略。
- 原始 BIDS 在 Docker 中以只读方式挂载；micapipe 输出、日志和临时文件写入项目工作目录。
- 对 NFS 输出目录，优先挂载已验证可访问的项目或 derivatives 父目录，而不是临时单独挂载深层 session/connectomes 子目录；Docker daemon 可能因嵌套路径权限而拒绝后者。
- `prepare_environment` 在每次处理前检查 Docker、镜像、license 和必要目录。
- `validate_dwi` 检查 LR/RL NIfTI、bval、bvec、JSON 是否齐全，并确认相位编码方向相反、readout time 相同。
- `require_structural_qc` 确保存在结构 QC card 后才允许 DWI 或 SC。

命令中的 `--reviewed-structural-qc` 与 `--reviewed-dwi-qc` 是人为确认闸门，不是自动 QC 算法。传入该标记意味着操作者已完成相应视觉检查。

### 3. Docker 调用

`run_micapipe` 会统一构造 Docker 命令：挂载输入、输出、临时目录和 FreeSurfer license，然后将具体 micapipe 参数附加到容器命令。每次运行同时写入带时间戳的日志，因此终端中断后仍可追溯实际参数和错误信息。

## 子命令：何时使用、做了什么

| 命令                                     | 作用                                                 | 不会做什么                    |
| -------------------------------------- | -------------------------------------------------- | ------------------------ |
| `structure`                            | 运行结构、表面、post-structural 和 `Schaefer-400` atlas 阶段。 | 不处理 DWI 或 BOLD。          |
| `verify-dwi ses-XXX`                   | 只检查某个 DWI session 的文件和元数据。                         | 不生成任何影像衍生物。              |
| `verify-dwi-all`                       | 对预先列出的 DWI session 重复元数据检查。                        | 不代表这些 session 均可通过影像 QC。 |
| `dwi ses-XXX --reviewed-structural-qc` | 完成 DWI 去噪、畸变/运动校正、DTI、FOD、掩膜与 DWI-T1 配准。           | 不生成 SC。                  |
| `qc-dwi ses-XXX`                       | 列出 DWI QC card、eddy 报告和关键输出。                       | 不重跑处理，也不判定图像合格。          |
| `sc ses-XXX --reviewed-dwi-qc`         | 在已通过 DWI QC 的前提下运行 tractography 和 connectome。      | 不计算 FC 或 SC-FC coupling。 |
| `status`                               | 列出现有 QC JSON card。                                 | 不验证 card 的图像内容。          |

`dwi-all` 与 `sc-all` 应只在单 session pilot 的输出和 QC 都已确认后使用；它们顺序执行，不会自动筛掉低质量 session。

## 本项目的 DWI 决策

每个 DWI session 有 LR 与 RL 反向相位编码采集。最初尝试的完整 `rpe_all` 模式要求 LR/RL 每个扩散加权 volume 的梯度方向可逐一配对，但 `ses-013` 未能满足这一条件。

当前 runner 采用：LR 作为主 DWI，LR/RL 的 b=0 pair 用于估计 EPI susceptibility distortion。随后 DTI、FOD 和 tractography 均使用 LR 的完整扩散加权数据。该选择保留了可靠的主采集和反向 PE 畸变校正信息，但不应描述为合并两套完整 DWI。

## 运行后的判断顺序

1. `COMPLETED` 表示流程运行结束，不等于图像质量可接受。
2. DWI 后先阅读 eddy 报告、b=0-T1 配准、brain mask、FOD 和低密度 TDI。
3. 仅在 DWI QC 合格时运行 SC。
4. SC 后检查 tractography/TDI、connectome、atlas 标签及矩阵顺序。
5. 仅将通过全部 QC 的 SC 纳入稳定 SC 候选；FC 处理和 coupling 另行进行。

## 相关笔记

- [[micapipe结构处理与SC-FC实施方案|项目实施方案与当前状态]]
- [[可复现命令/从450节点connectome派生400皮层SC|450 节点到 400 皮层 SC 的可复现命令]]
- [[关于科研经历/02-方法库/神经影像/micapipe DWI 到结构连接工作流|可复用的 micapipe DWI 到 SC 方法]]
- [[关于科研经历/02-方法库/神经影像/多session结构-功能耦合分析|后续 SC-FC coupling 方法]]

[[关于科研经历/01-研究项目/MyConnectome/数据与运行记录/index|返回数据与运行记录]]
