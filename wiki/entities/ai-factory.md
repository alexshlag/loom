---
tags: [tool, cli, agent-skill-system, stack-agnostic, spec-driven]
date: 2026-06-24
sources: [raw/github/lee-to/ai-factory@2.x/]
related: [wiki/entities/pi-coding-agent.md]
---

# AI Factory

Stack-agnostic CLI tool and skill system for AI-powered development. One command sets up a full context-aware environment with relevant skills, MCP servers, and spec-driven workflows.

## Ключевые характеристики

- **Zero configuration** — `ai-factory init` анализирует проект, ставит релевантные skills и настраивает MCP
- **Spec-driven workflow** — structured feature development через explore → plan → improve → implement → verify → commit
- **Stack-agnostic** — работает с любым языком, фреймворком, платформой
- **Multi-agent support** — Claude Code, Cursor, Windsurf, Roo Code, Kilo Code, Codex CLI, Copilot и другие (17+ агентов)
- **Community skills ecosystem** — [skills.sh](https://skills.sh) для установки или генерации кастомных навыков

## Архитектура

```
ai-factory init → .ai-factory/config.yaml → DESCRIPTION.md + AGENTS.md + ARCHITECTURE.md
                                    ↓
                            /aif-explore → RESEARCH.md
                            /aif-plan → plans/<branch>.md
                            /aif-implement → commit checkpoints
                            /aif-fix → patches/ (self-improvement)
                            /aif-evolve → skill-context overrides
```

## Основные команды

| Команда | Назначение |
|---------|------------|
| `/aif` | Setup context — анализирует проект, генерирует описание и архитектуру |
| `/aif-explore` | Discovery before planning — исследует идеи без реализации |
| `/aif-grounded` | Reliability gate — evidence-only ответы с 100% confidence |
| `/aif-plan [fast\|full]` | Planning — создаёт план задач (fast: без ветки, full: с опциональной веткой) |
| `/aif-improve` | Refine plan — second-pass analysis, находит пропущенные задачи |
| `/aif-implement` | Execute plan — выполняет задачи по порядку с commit checkpoints |
| `/aif-verify [--strict]` | Check completeness — проверяет реализацию против плана |
| `/aif-fix [bug]` | Bug fix with logging + self-improvement patches |
| `/aif-evolve` | Skill evolution из accumulated patches → smarter skill-context |
| `/aif-loop` | Reflex Loop: PLAN→PRODUCE→EVALUATE→CRITIQUE→REFINE (6 фаз) |
| `/aif-roadmap` | Strategic milestone planning |
| `/aif-rules` | Project conventions and area-specific rules |
| `/aif-commit` | Conventional commit with context gates |
| `/aif-review [PR]` | Code review с read-only architecture/roadmap/rules gates |

## Сравнение: AI Factory vs Pi Coding Agent

Оба инструмента — агенты для кодинга, но с разным фокусом:

- **AI Factory**: CLI-first, stack-agnostic, community skills ecosystem (skills.sh), spec-driven workflow, multi-agent support
- **Pi**: Custom TS extensions, skill system built on pi SDK, deeper Obsidian/wiki integration, schema co-evolution

## Связи

- [skills.sh](https://skills.sh) — Skill marketplace для AI Factory
- [Agent Skills Spec](https://agentskills.io) — Specification для community skills
- [aif-handoff](https://github.com/lee-to/aif-handoff) — Autonomous Kanban board built on AI Factory

## Источники

- [GitHub: lee-to/ai-factory](https://github.com/lee-to/ai-factory) (967 stars, 89 forks)
- [Official Site: aif.cutcode.dev](https://aif.cutcode.dev)
- [Getting Started](raw/github/lee-to/ai-factory@2.x/getting-started.md)
- [Development Workflow](raw/github/lee-to/ai-factory@2.x/workflow.md)
- [Core Skills Reference](raw/github/lee-to/ai-factory@2.x/skills.md)

## Новые связи (2026-06-24)
* [AI Factory vs Pi — Category Distinction](concepts/ai-factory-vs-pi.md) — различение категорий: AI Factory = workflow schema, Pi = harness runtime
* [Pi Coding Agent](entities/pi-coding-agent.md) — конкретная среда (harness), в которой можно запустить AI Factory


* [LLM Wiki Pattern](concepts/llm-wiki-pattern.md) — compounding knowledge base подход, аналогичен AI Factory workflow для накопления знаний через LLM

