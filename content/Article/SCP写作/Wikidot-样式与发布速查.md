---
title: Wikidot 样式与发布速查
draft: false
tags:
  - 创作
  - SCP
  - Wikidot
---

## 本地稿与 Sandbox 的区别

本目录使用 Markdown，供构思和存档；SCP Wiki 的 Sandbox 使用 Wikidot 语法。不要把 Wikidot 的主题或 CSS 代码直接放进 Quartz 页面。需要为本站单独设计页面样式时，应修改 `/home/vqs88/quartz/quartz/styles/custom.scss`。

## 最小 Sandbox 骨架

以下是可在 Sandbox 中预览的最小 Wikidot 结构；投递前应以目标站点的当前模板为准。

```text
[[>]]
[[module Rate]]
[[/>]]

**Item #:** SCP-XXXX

**Object Class:** Euclid

**Special Containment Procedures:**

**Description:**

**Addendum:**

[[footnoteblock]]
```

## 主题与组件

“SCP 风格 CSS”通常不是复制一段独立 CSS，而是引用 Wiki 已维护的主题或组件。英文 SCP Wiki 的 Black Highlighter 主题可在草稿顶部使用：

```text
[[include :scp-wiki:theme:black-highlighter-theme]]
```

这只适用于支持 Wikidot `include` 的页面；Quartz 不会解析它。先用基础主题完成可读的正文，再按需要从官方组件库选择分类条、侧栏等单一组件，避免样式盖过叙事。

## 投稿前必须确认

- 选定投稿的站点后，重新阅读该站的现行创作、反馈、许可和 AI 使用规则；各分站规则可能不同。
- 英文 SCP Wiki 的现行写作指南明确禁止生成式 AI 生成或协助生成面向读者的投稿文本。不要将 AI 生成的正文、改写文本或表层修改后的文本投往该站。
- 图片不是必需品；如使用，保留文件名、作者、来源链接及兼容许可，供许可框填写。
- 主站发布通常需要先在 Sandbox 预览、取得反馈，并使用实际可用的编号。

## 官方参考

- [How To Write An SCP](https://scp-wiki.wikidot.com/how-to-write-an-scp)
- [Black Highlighter Theme](https://scp-wiki.wikidot.com/theme:black-highlighter-theme)

[[Article/SCP写作/index|返回 SCP 写作区]]
