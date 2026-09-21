~~~
docker run --rm -it \
    -v /home/gpu/MyConFmriPrep/BIDS:/data:ro \
    -v /home/gpu/MyConFmriPrep/BIDS/derivatives/fmriprep:/out \
    -v /home/gpu/MyConFmriPrep/BIDS/derivatives/fmriprep_mid:/work \
    -v /home/gpu/license/license.txt:/opt/freesurfer/license.txt:ro \
    nipreps/fmriprep:25.2.5 \
    /data /out participant \
    --participant-label 01 \
    --session-label 030,031,032,033,034,035 \
    --task-id rest \
    --skip-bids-validation \
    --subject-anatomical-reference unbiased \
    --no-track-sessions \
    --ignore fieldmaps t2w sbref \
    --output-spaces MNI152NLin2009cAsym:res-2 \
    --bold2anat-init t1w \
    --bold2anat-dof 6 \
    --force bbr \
    --slice-time-ref 0.5 \
    --output-layout bids \
    --notrack \
    -w /work
~~~

## 相关页面

- [[关于科研经历/01-研究项目/MyConnectome-CAPs/数据与运行记录/fMRIPrep试验结果|fMRIPrep 试验结果]]
- [[关于科研经历/02-方法库/fMRI预处理/fMRIPrep/fMRIPrep报告阅读|fMRIPrep 报告阅读]]
- [[关于科研经历/02-方法库/CAPs/CAPs原始预处理方案|CAPs 原始预处理方案]]
- [[关于科研经历/01-研究项目/MyConnectome-CAPs/数据与运行记录/index|返回数据与运行记录]]
