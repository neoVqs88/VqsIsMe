```python
class CAP(CAPGetter):

    """

    Co-Activation Patterns (CAPs) Class.

  

    Performs k-means clustering for CAP identification, computes temporal dynamics metrics, and

    provides visualization tools for analyzing brain activation patterns.

  

    .. important::

       Parcellation maps are expected to be in a standard MNI space. This is due to the

       ``CAP.caps2surf`` assuming that the parcellation map is in MNI standard space when

       transforming data between volumetric and surface spaces.

  

    Parameters

    ----------

    parcel_approach : :obj:`ParcelConfig`, :obj:`ParcelApproach`, or :obj:`str`, default=None

        Specifies the parcellation approach to use. Options are "Schaefer", "AAL", or "Custom". Can

        be initialized with parameters, as a nested dictionary, or loaded from a serialized file

        (i.e. pickle, joblib, json). For detailed documentation on the expected structure, see the

        type definitions for ``ParcelConfig`` and ``ParcelApproach`` in the "See Also" section.

  

        .. important::

           The default "regions" names for "AAL" was changed in versions >=0.31.0, which will group

           nodes differently.

  

    groups : :obj:`dict[str, list[str]]` or :obj:`None`, default=None

        Optional mapping of group names to lists of subject IDs for group-specific analyses. If

        None, on the first call of ``self.get_caps()``, "All Subjects" will be set as the default

        group name and be populated with the subject IDs in ``subject_timeseries``. Groups remain

        fixed for the entire instance of the class unless ``self.clear_groups()`` is used.
```

这段代码值得注意的地方很多。关于 [parcel_approach]() 的内容，请跳转至另一篇笔记。本笔记主要分析的是结尾部分关于 groups 的使用。

---

## 使用场景

### **场景A：单数据集分析**
```python
cap = CAP(parcel_approach="Schaefer")
result = cap.get_caps(subject_timeseries=data)

# 内部自动处理：
# - 创建 {"All Subjects": [subj1, subj2, ...]}
# - 用所有数据进行聚类分析
```

只进行一组分析，不进行对照组等等，流程方便。

### **场景B：多数据集分析**
```python
cap = CAP(parcel_approach="Schaefer")

# 分析第一批数据
result1 = cap.get_caps(subject_timeseries=dataset1)

# 分析第二批数据（不同的被试）
result2 = cap.get_caps(subject_timeseries=dataset2)

# 内部自动为每个数据集创建对应的分组
```

- 不需要为每个数据集重新创建 CAP 实例，使用相同的分析参数（parcel_approach、聚类方法等）
- 适合批量处理、模拟研究

### **场景C：自定义分组**
```python
# 提前定义分组（实验设计阶段）
groups = {
    "patient": ["ses_01", "ses_02", "ses_03"],
    "control": ["ses_04", "ses_05", "ses_06"]
}

# 初始化时就指定分组
cap = CAP(parcel_approach="Schaefer", groups=groups)

# 分别获取各组分析结果
patient_caps = cap.get_caps(
    subject_timeseries=full_data,  # 包含所有被试
    group_name="patient"
)

control_caps = cap.get_caps(
    subject_timeseries=full_data,
    group_name="control"
)
```

**设计优势**：
- 分组定义与数据加载分离，分组被"固化"，避免在复杂分析中误改

---

以上就是可能的使用方法。具体的使用，可以基于 MyConnectome 的使用方法进行一定的改进。例如可以通过读取 tsv 文件，从 tsv 文件中分离出行为变化，然后分成两组，进行分析等等。这个函数的设计方法值得借鉴。