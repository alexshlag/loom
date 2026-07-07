---
tags: [harness, wiki-setup, design-idea, pending]
date: 2026-07-01
type: documentation
category: concept
sources:
  - "conversation/2026-07-01"
related:
  - "wiki/concepts/natural-memory.md"
---

# Harness-Aware Wiki Setup Flow

This page explores Harness-Aware Wiki Setup Flow as a key concept in our knowledge base.

## Definition

Идея автоматической настройки wiki-контекста для конкретного harness (Pi, Claude Code, Cursor и т.д.). Каждый harness имеет свои инструменты, конвенции и точки конфигурации — setup flow должен их учитывать.

## Core Idea

1. **Auto-detection**: `harness/detect.sh` определяет текущий harness, версию, capabilities
2. **Wiki check**: `scripts/wiki-check.sh` проверяет наличие ключевых файлов (`AGENTS.md`, `process-*.json`, `scripts/`, `meta/`) и папок wiki
3. **Gap detection**: если файлы wiki ✅ но harness не настроен → предложение auto-setup
4. **Conditional execution**: setup выполняется только с явного согласия пользователя

## Proposed Structure

```
harness/
├── detect.sh          # auto-detect harness name, version, capabilities
└── [name]/            # per-harness config directory
    ├── settings.json  # what to configure (tools, hooks, skills)
    └── checklist.md   # step-by-step setup instructions
```

## Flow

```
detect.sh → identify harness + version
           ↓
wiki-check.sh → verify wiki structure (files ✅ / gaps ❌)
               ↓
harness-config check → tools registered? hooks configured? skills loaded?
                      ↓
if all ✅ → done
if harness gap → propose setup to user
                ↓
user says "Yes" → execute harness-specific setup automatically
```

## Status: **pending** (idea phase, not implemented)

- [ ] Design discussion needed
- [ ] Structure/algorithm not finalized
- [ ] Implementation deferred until ready

## Related Ideas

- Harness-specific capabilities detection
- Auto-skill registration per harness
- Hook-based wiki integration (pre-commit, post-query hooks)

---
*Created: 2026-07-01 | Status: idea only, not implemented*
