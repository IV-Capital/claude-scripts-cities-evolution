# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a collection of Claude Code skills, prompt templates, and reference documentation for content production workflows — specifically YouTube script production with AI-generated video footage. There is no build system, package manager, or test suite — the project consists entirely of markdown files, shell scripts, and zip archives.

## Repository Structure

- `.claude/skills/` — Installed Claude Code skills (each skill is a directory with `SKILL.md` as entrypoint)
- `skills/` — Source zip archives of skills (originals before extraction)
- `docs/TEAM_LEAD_PROMPT.md` — Multi-agent Team Lead prompt for YouTube script production (~80KB, detailed orchestration protocol with Phase 5.5 cost estimation)
- `docs/NICHE_STYLE_GUIDE_TEMPLATE.md` — Шаблон адаптации под конкретный канал и нишу (заполнить и сохранить как `docs/ref/NICHE_STYLE_GUIDE.md` в проекте скрипта)
- `docs/specific/` — Reference documents (video attention strategies, skill installation guide)

## Skills

Twelve project-level skills are configured in `.claude/skills/`:

### User-invocable skills

| Skill | Invocation | Key Tools | Purpose |
|---|---|---|---|
| `article-extractor` | `/article-extractor <url>` | Bash, Write | Extract clean article text from URLs |
| `content-research-writer` | `/content-research-writer` | (default) | Research and writing assistant |
| `editor` | `/editor` | (default) | Professional editing and proofreading |
| `video-analyzer` | `/video-analyzer <video_path>` | Bash (ffmpeg) | Analyze video by extracting frames |
| `video-report` | `/video-report` | (default) | Generate video reports |
| `youtube-transcript` | `/youtube-transcript <url>` | Bash, Read, Write | Download YouTube transcripts |
| `sora-2-pro-prompting` | `/sora-2-pro-prompting` | Read | Sora 2 Pro video generation prompts |
| `kling-video-prompting` | `/kling-video-prompting` | Read | Kling AI video generation prompts |
| `google-flow-prompting` | `/google-flow-prompting` | Read | Google Flow (Veo 3.1) video generation prompts |

### Background knowledge skills (non-invocable)

| Skill | Purpose |
|---|---|
| `video-gen-prompts` | Cross-service comparison and prompt adaptation guide (Sora 2, Kling, Flow) |
| `ai-service-selector` | Decision matrix for choosing video generation service per scene |
| `production-cost-estimator` | Production cost calculation methodology and pricing tables |

### Skill details

- `video-analyzer` bundles a helper script at `scripts/extract_frames.sh` — reference it via `${CLAUDE_SKILL_DIR}/scripts/extract_frames.sh`.
- Video generation prompting skills (`sora-2-pro-prompting`, `kling-video-prompting`, `google-flow-prompting`) each contain `references/` subdirectories with detailed pricing, prompt architecture, and camera reference documents.
- `ai-service-selector` includes "Premium Start" temporal quality strategy: premium models for first ~3 minutes, economy models (Flow Veo 3.1 Fast = free) after.
- `production-cost-estimator` covers Sora 2, Kling, Flow, and ElevenLabs pricing; outputs `COST_ESTIMATE.md`.

## Video Generation Services

This project works exclusively with three AI video generation services:
- **Sora 2 Pro** (OpenAI) — cinematic quality, human subjects, complex motion
- **Kling AI** — stylized content, camera movements, abstract visuals, budget-friendly
- **Google Flow / Veo 3.1** — atmospheric shots, establishing footage, free iteration on Ultra

No other video generation services (Runway, Hailuo, Midjourney, Flux, etc.) are used.

## Permissions

Git write operations are denied in `.claude/settings.local.json` — all git commands that modify state (commit, push, checkout, merge, etc.) are blocked. Read-only git commands (status, log, diff) are allowed. File read/write/edit is scoped to this project directory only.

## Language

User communicates in Russian. Documentation and prompts are a mix of Russian and English.
