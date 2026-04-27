---
tags:
  - fmri预处理
  - CAPs分析
date: 2026-04-22
---


`fmriprep` 生成文件位于实验室服务器位置：
~~~
\\wsl.localhost\Ubuntu-22.04\home\gpu\MyConFmriPrep\BIDS\derivatives\test
~~~

在此处，存放有四个文件夹分别为：
~~~
fmriprep  fmriprep_mid  

fmriprep_mid_old  fmriprep_old
~~~

比较重要的是前两个文件夹，使用**6个**session，其中包含**2个**anat文件，用于检验是否可以实现在anat不全的情形下进行纵向数据预处理分析，具体运行的代码如下：

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

在该命令脚本中可以找到源文件地点和中间文件生成目录，以及一些重要的参数。

---

对于后两个文件夹，是只使用了 ses-030 进行试验的情形，可以用于更细致地查阅在只有一个输入 session 时的情况。