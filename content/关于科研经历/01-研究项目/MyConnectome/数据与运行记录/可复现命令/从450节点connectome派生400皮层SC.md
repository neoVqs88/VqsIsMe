---
title: 从 450 节点 Connectome 派生 400 皮层 SC
draft: true
tags:
  - 科研
  - MyConnectome
  - SC
  - Schaefer-400
  - 可复现命令
---

## 状态

**已成功执行。** 修正 Docker 挂载、conda 环境与上三角编码后，命令生成了 400 x 400 矩阵、400 个标签、原始上三角审计版本，以及对称零对角版本。终端确认 `Raw upper-triangular: True`、`Symmetric after conversion: True`、`Labels: 400`。

## 目的

从 micapipe v0.2.3 生成的 450 x 450 完整 `Schaefer-400` connectome GIFTI，派生仅含 400 个皮层 parcel 的：

- SIFT2 结构连接边权矩阵；
- 平均 streamline 边长度矩阵；
- 与矩阵行列完全对应的标签表。

该命令不重跑 tractography，不修改原始 450 节点 GIFTI。

## 前置条件

1. `SC-10M_acq-ses-013` 已报告 `COMPLETED`。
2. `full-connectome.shape.gii` 与 `full-edgeLengths.shape.gii` 已位于 connectomes 目录。
3. Docker 可运行 `micalab/micapipe:v0.2.3`。
4. 操作者对 derivatives 根目录有写权限。

## 原理与节点规则

450 节点依次包含 48 个皮层下/小脑节点、1 个左半球 medial-wall、200 个左皮层 parcel、1 个右半球 medial-wall 和 200 个右皮层 parcel。根据 micapipe v0.2.3 内置 LUT 的升序 `mics` 顺序，400 个皮层节点的 Python 索引为：

```python
np.r_[np.arange(49, 249), np.arange(250, 450)]
```

不能直接取前 400 行列。

## 命令

本命令依赖前序 QC 步骤已在当前 shell 定义 `BASE`，其值应为本次结构 session 目录。命令会从 `BASE` 自动推导 derivatives 根目录，并先验证该目录存在；不要手动输入任何尖括号占位符。

```bash
: "${BASE:?请先设置 BASE 为 micapipe 的 ses-015 输出目录}"
DERIV_ROOT="${BASE%/micapipe_v0.2.0/sub-01/ses-015}"
[[ -d "$DERIV_ROOT" ]] || {
  printf '无法从 BASE 推导 derivatives 目录：%s\n' "$DERIV_ROOT" >&2
  exit 1
}

docker run --rm -i \
  --user "$(id -u):$(id -g)" \
  -v "$DERIV_ROOT:/derivatives" \
  --entrypoint /neurodocker/startup.sh \
  micalab/micapipe:v0.2.3 python - <<'PY'
import nibabel as nib
import numpy as np
import pandas as pd
from pathlib import Path

conn = Path(
    "/derivatives/micapipe_v0.2.0/sub-01/ses-015/"
    "dwi/acq-ses-013/connectomes"
)
out = conn / "cortex400"
out.mkdir(exist_ok=True)

weights = nib.load(
    conn / "sub-01_ses-015_space-dwi_atlas-schaefer-400_"
           "desc-iFOD2-10M-SIFT2_full-connectome.shape.gii"
).darrays[0].data
lengths = nib.load(
    conn / "sub-01_ses-015_space-dwi_atlas-schaefer-400_"
           "desc-iFOD2-10M-SIFT2_full-edgeLengths.shape.gii"
).darrays[0].data

assert weights.shape == (450, 450), weights.shape
assert lengths.shape == (450, 450), lengths.shape

idx = np.r_[np.arange(49, 249), np.arange(250, 450)]
weights_upper = weights[np.ix_(idx, idx)]
lengths_upper = lengths[np.ix_(idx, idx)]

def upper_to_symmetric(matrix):
    # micapipe/MRtrix stores each undirected edge in the upper triangle.
    if not np.allclose(np.tril(matrix, -1), 0):
        raise RuntimeError("Expected an upper-triangular micapipe connectome")
    symmetric = np.triu(matrix, 1)
    symmetric = symmetric + symmetric.T
    np.fill_diagonal(symmetric, 0)
    return symmetric

cortex_weights = upper_to_symmetric(weights_upper)
cortex_lengths = upper_to_symmetric(lengths_upper)

lut = pd.read_csv(
    "/opt/micapipe/parcellations/lut/lut_schaefer-400_mics.csv"
).sort_values("mics")
labels = lut.loc[lut["label"] != "medial_wall"].copy()
assert len(labels) == 400, len(labels)
labels.insert(0, "matrix_index", np.arange(400))

np.savetxt(
    out / "schaefer400_cortex_sift2_upper.tsv",
    weights_upper,
    delimiter="\t",
    fmt="%.8g",
)
np.savetxt(
    out / "schaefer400_cortex_sift2.tsv",
    cortex_weights,
    delimiter="\t",
    fmt="%.8g",
)
np.savetxt(
    out / "schaefer400_cortex_edge_lengths_upper.tsv",
    lengths_upper,
    delimiter="\t",
    fmt="%.8g",
)
np.savetxt(
    out / "schaefer400_cortex_edge_lengths.tsv",
    cortex_lengths,
    delimiter="\t",
    fmt="%.8g",
)
labels.to_csv(out / "schaefer400_cortex_labels.tsv", sep="\t", index=False)

print("Raw upper-triangular:", np.allclose(np.tril(weights_upper, -1), 0))
print("SC shape:", cortex_weights.shape)
print("Symmetric after conversion:", np.allclose(cortex_weights, cortex_weights.T))
print("Labels:", len(labels))
print("Output:", out)
PY
```

`/neurodocker/startup.sh` 会激活 micapipe conda 环境。不要用 `--entrypoint python`，因为它会跳过环境初始化，导致 `nibabel` 不可用。

## 预期输出

终端应显示：

```text
Raw upper-triangular: True
SC shape: (400, 400)
Symmetric after conversion: True
Labels: 400
```

输出目录 `connectomes/cortex400/` 应包含：

- `schaefer400_cortex_sift2_upper.tsv`：从原始 GIFTI 切出的上三角编码，保留供审计。
- `schaefer400_cortex_sift2.tsv`：对称、零对角的候选 SC 边权矩阵，用于后续 coupling。
- `schaefer400_cortex_edge_lengths_upper.tsv`：上三角编码的平均 streamline 长度。
- `schaefer400_cortex_edge_lengths.tsv`：对称、零对角的平均 streamline 长度。
- `schaefer400_cortex_labels.tsv`：400 行标签表。

## 停止规则与后续

- 若 Docker 挂载、`nibabel` 导入、矩阵维度或标签数量任一检查失败，停止，不使用任何新增输出。
- 命令成功后仍需检查 TDI/tractography，并在 FC 提取后以 `schaefer400_cortex_labels.tsv` 程序化验证 SC/FC 标签与顺序。

[[关于科研经历/01-研究项目/MyConnectome/数据与运行记录/可复现命令/index|返回可复现命令]]
