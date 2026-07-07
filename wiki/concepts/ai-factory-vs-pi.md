---
tags: [agent-workflow-schema, harness-comparison, claude-obsidian-alternative]
date: 2026-06-24
sources: [wiki/entities/ai-factory.md, wiki/entities/pi-coding-agent.md]
related: []
---

# AI Factory vs Pi Coding Agent — Category Distinction

This page explores AI Factory vs Pi Coding Agent — Category Distinction as a key concept in our knowledge base.

## Определение

**Это не сравнение сущностей, а различение категорий.**

| Сущность | Категория | Природа |
|----------|-----------|---------|
| **AI Factory** | workflow schema / методология | Набор взаимосвязанных инструкций для организации работы. Не зависит от конкретного harness — можно запустить внутри Pi, OpenCode, Codex CLI или любого другого. |
| **Pi Coding Agent** | harness / runtime environment | Конкретная среда выполнения (как Cursor, Claude Code, Codex CLI). |

## Как они соотносятся

```
┌─────────────────────────────────────┐
│  User's Project                     │
│                                     │
│  ┌────────────────────────────────┐ │
│  │  Harness / Agent Runtime       │ │  ← Pi, Claude Code, Codex CLI...
│  │  (e.g., Pi Coding Agent)       │ │     are environments where you run code.
│  │  ┌───────────────────────────┐ │ │
│  │  │  AI Factory Schema        │ │ │  ← workflow instructions layer
│  │  │  (ingest, query, lint)    │ │ │      that can be applied to ANY harness.
│  │  └───────────────────────────┘ │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

- **AI Factory** можно добавить к любому проекту как схему организации работы
- **Pi** — это harness, который сам может использовать AI Factory workflow instructions или свои собственные (как в текущем проекте с AGENTS.md)

## Когда использовать каждую

| Ситуация | Что применяется |
|----------|-----------------|
| Нужна методология ingest → query → lint для wiki | AI Factory schema |
| Нужна runtime среда для TS extensions, skills, themes | Pi Coding Agent |
| Нужна схема работы + runtime | И то и другое (AI Factory instructions живут внутри Pi) |

---

*Created: 2026-06-24*

## Связи
* [AI Factory Entity](entities/ai-factory.md) — workflow schema (инструкции для любого harness)
* [Pi Coding Agent](entities/pi-coding-agent.md) — конкретная среда (harness runtime)

---

*Created: 2026-06-24*
