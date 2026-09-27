# Obsidian / Quartz Content Source

This directory is the editable Obsidian vault and the sole source for the Quartz site's content. It has no local application package or test suite.

## Publishing Workflow

- Edit content only here. Do not edit `/home/vqs88/quartz/content/`: it is a generated mirror and will be overwritten.
- From `/home/vqs88/quartz`, mirror this vault with `bash code/sync_to_quartz.sh`, then verify with `npx quartz build`.
- The sync uses `rsync --delete`; files that exist only in Quartz `content/` will be deleted. It excludes only `.obsidian/`, `.trash/`, and `*.tmp`.
- Quartz requires Node `>=22` and npm `>=10.9.2`. Its available checks are `npm run check` (TypeScript and Prettier) and `npm test`.
- Do not commit, push, alter Git history, or publish unless explicitly requested.

## Public Content Boundaries

- Anything copied to Quartz `content/` may be public. Quartz ignores `private`, `template`, `templates`, `.obsidian`, `copilot`, and `AGENTS.md`; drafts are also removed from the built site.
- Never put credentials, tokens, private addresses, private schedules, passwords, or meeting links in publishable files. Keep local Obsidian state in `.obsidian/`.
- `calendar/calendar.ics` is intentionally public and is served as `/calendar/calendar.ics`.

## Content Conventions

- Formal notes need YAML frontmatter with `title`, `draft`, and `tags`. Use only boolean `true` or `false` for `draft`; unfinished, private, and `99-待整理` material must be `true`.
- Use Obsidian wiki links when adding or renaming pages: `[[path/to/note|label]]`. When moving a note, update inbound links and search for old paths after building.
- Topic directories use `index.md` as a navigable entry page that lists direct child notes. Preserve original research records, commands, and conclusions; structural work should not rewrite findings.
- `关于科研经历/` is organized by numbered areas: projects (`01`), reusable methods (`02`), lab operations (`03`), computing/tools (`04`), resources (`05`), dated research logs (`06`), paper reading (`07`), and drafts (`99`). Keep project results, reusable methods, and chronological logs distinct; link reusable conclusions from their formal note instead of duplicating them in a log.
- Existing unnumbered research folders are legacy content. Do not relocate them without updating affected links and navigation.

## Site-Specific Layout

- `index.md` has a layout contract in `/home/vqs88/quartz/quartz/styles/custom.scss`: its first paragraph is the enlarged hero text, and the first `##` followed immediately by a bullet list renders as the three entry cards. Keep `## 内容入口` in that position when editing the homepage.
- Quartz configuration and visual changes belong in `/home/vqs88/quartz`: `quartz.config.ts`, `quartz.layout.ts`, and `quartz/styles/custom.scss`, not in this vault.
- The Quartz config resolves Markdown links using the shortest path and derives dates from frontmatter, then Git, then filesystem metadata. Add explicit frontmatter dates when a stable displayed date matters.

## Verification

- For content or structural changes, verify required frontmatter, index navigation, and moved-link references; then sync and run `npx quartz build` in `/home/vqs88/quartz`.
- Run `git diff --check` in the relevant repository. A build warning about untracked files lacking Git dates is expected before a commit; do not commit solely to suppress it.
