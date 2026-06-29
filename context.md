# Context — Wiki Schema Decisions Log

## 🎯 Purpose
Файл для фиксации решений по вопросам, которые требуют обсуждения перед implementation. Каждый вопрос → обсуждение → решение → ссылка на issues.md, PLAN.md.

---

## ❓ Wiki Page Templates & Format Schema (Phase 13)

### Q1: Universal structure vs Type-specific templates
**Проблема:** Agent применяет consistent pattern на практике, но нет формального описания в инструкциях.

#### Research findings (Obsidian conventions)
| Практика | Как в Obsidian | Наш аналог |
|----------|---------------|------------|
| Frontmatter/Properties | YAML `---` блок с metadata (**везде одинаковый**) | ✅ У нас: `tags`, `date`, `sources`, `related` |
| Templates per note type | Каждый тип → свой шаблон, секции гибкие внутри | ⚠️ Пока нет — agent решает сам |
| Consistent section order | Все Area notes → одинаковые секции в порядке | ⚠️ Ad-hoc паттерны на практике |
| Minimal folder hierarchy | Numeric prefixes, shallow nesting | ✅ У нас: `entities/concepts/syntheses/comparisons` |

#### 📊 Inventory всех типов wiki-страниц (36 страниц)

| # | Тип страницы | Кол-во | Примеры | Фактическая структура |
|---|-------------|--------|---------|----------------------|
| **1** | **Entity** | 5–6 | `pi-coding-agent.md`, `symfony.md` | frontmatter → Definition → Key characteristics → Связи |\n| **2** | **Concept** | 14+ | `llm-wiki.md`, `hexagonal-architecture.md` | frontmatter → Definition/Определение → Principles/Architecture |
| **3** | **Synthesis** | 2 | `python-nixos-development-environments.md` | frontmatter → Контекст → Анализ → Выводы |\n| **4** | **Comparison** | 2 | `llm-wiki-implementations.md` | frontmatter → Overview/Введение → Table → Deep Dive → Pros/Cons → Итог |

> ⚠️ **Замечание:** Entity имеет 5 страниц, но в inventory фактически 6 сущностей (ai-factory, andrej-karpathy, loomana, nvidia, pi-coding-agent, symfony).

**Варианты решений:**
| Вариант | Описание | Плюсы | Минусы |
|---------|----------|-------|--------|
| **A) Generic template + type modifiers** | Единый каркас (frontmatter → ## Sections → ## Связи), agent выбирает секции по контексту | Максимальная гибкость, проще maintain | Риск inconsistent structure между страницами |\n| **B) Per-type templates** | Чёткие структуры: Entity→X, Concept→Y, Synthesis→Z | Consistent output, easy to validate | Rigidity — не учитывает edge cases |
| **C) Hybrid (recommended)** | Generic frontmatter + flexible sections (agent сам решает какие секции нужны), но minimum required для каждого типа | Гибкость knowledge base + predictable baseline | Сложнее описать в schema |

**Принятое решение:** ✅ **Вариант C (Hybrid)**
- Universal frontmatter (identical for all types) — обязательная, machine-readable metadata section
- Section order: **recommended but not enforced** — preserves flexibility while providing consistency baseline
- Each type has minimum required sections defined in AGENTS.md → `AGENTS.md#page-templates`
- Agent selects additional sections based on context, follows recommended structure
- Editing common templates requires user approval — **free editing prohibited**

---

### Q2: Summary pages vs Synthesis pages structure
**Проблема:** В AGENTS.md есть правила создания summary/faq_pages с `type=faq_summary`, но нет описания структуры страницы. Synthesis используют pattern "Контекст → Анализ → Итог".

**Ключевой вопрос:** should faq_summary иметь другую структуру, чем regular synthesis?

**Принятое решение:** ✅ **A) Unified structure + type marker**
- Summary pages = Synthesis pages with `type: faq_summary` in frontmatter
- No separate structure — agent follows standard synthesis pattern (Контекст → Анализ → Выводы)
- Difference only in `type` field and creation rules (auto-create threshold ≥3 wiki sources)
- Canonical: `AGENTS.md#summary_pages`

---

### Q3: Section naming conventions (Russian vs English)
**Проблема:** Mix русского и английского в секциях ("## Ключевые характеристики", "## Definition", "## Контекст", "## Введение"). Нужна ли стандартизация языков?

**Принятое решение:** ✅ **C) English-only headers** — section titles in English for consistency and machine-readability
- Content language follows source (Russian/English/bilingual)
- Headers: `## Definition`, `## Key Characteristics`, `## Principles`, `## Context`, `## Analysis`, `## Conclusions`
- Rationale: consistent parsing, better grep/search behavior, universal reference across languages
- Exception: if entire source is in Russian and no English translation exists → use Russian headers (documented)

---

### Q4: Comparison pages — table vs prose format
**Проблема:** `llm-wiki.md` использует detailed table + prose. `symfony-ux.md` — compact table only. Should we standardize?

**Варианты решений:**
| Вариант | Описание |
|---------|----------|
| **A) Flexible** | Agent chooses: simple comparisons → table, complex → prose + tables |
| **B) Standard format** | Mandatory structure: Overview Table → Deep Dive Analysis → Pros/Cons → Recommendation |

**Принятое решение:** ⬜ _Обсуждение pending_

---

### Q6: Language Policy for Wiki Headers & Responses ✅

**Проблема:** Mix русского и английского в заголовках секций. Нужно решение для consistent navigation.

**Принятое решение:** 🌐 **Hybrid language policy (3 principles)**

| Principle | Rule |
|-----------|------|
| **Page headers = English** | All template section titles in English (`## Definition`, `## Key Characteristics`, etc.). Provides consistent structural anchors for agent navigation. |
| **Content follows source** | Write content in original language (Russian, English, bilingual). No forced translation at ingest. |
| **Response translation** | Agent translates headers to match user's question language. Russian query → `Определение`. English query → `Definition`. |

**Примеры:**
- Page has `## Definition` (English header) + content in Russian → normal, bilingual page is expected state
- User asks in Russian about this page → agent responds with "В разделе **Определение** сказано..." (translated header)
- User asks in English → agent uses "In the **Definition** section..."

**Current state:** ~70% of existing pages use Russian headers, ~30% English. Future pages follow new policy (English templates). Migration not required — current state acceptable for test/experimental phase.

> Canonical: `AGENTS.md#language_policy` → full rules in AGENTS.md#language_policy

---

### Q5: Universal Frontmatter — restructuring ✅

**Проблема**: Текущая структура фронтматтера не соответствует фактическому использованию:
- `tags` задан как ограниченный enum `[entity|concept|synthesis|comparison]`, но используется свободно
- `type` (documentation/code_reality/live_state) не заполняется ни одной страницей, но критичен для cascade-алгоритма
- `evidence_grade` нигде не используется вручную
- Отсутствует поле для указания раздела wiki (entity/concept/synthesis/comparison)

**Принятое решение:**
```yaml
---
tags: []                    # свободные keyword-теги без ограничений
date: YYYY-MM-DD            # текущая дата системы
type: documentation         # reality layer: documentation | code_reality | live_state
category: entity            # раздел wiki: entity | concept | synthesis | comparison | note | project | bibliography | resource
sources: []                 # откуда данные (raw/..., wiki paths, web_search)
related: []                 # связанные wiki-страницы
---
```

**Ключевые изменения:**
| Поле | Было | Стало | Почему |
|------|-------|-------|--------|
| `tags` | Ограниченный enum → `[entity\|concept\|...]` | **Свободный массив keyword-тегов** | Tags = классификация, не enum |
| `type` | Reality layer (не заполняется) | **Reality layer остаётся `type`**: `documentation \| code_reality \| live_state` | Cascade-алгоритм противоречий зависит от этого |
| ~~отсутствует~~ | ✅ Новое поле | **`category`**: `entity \| concept \| synthesis \| comparison \| note \| project \| bibliography \| resource` | Определяет куда поставить страницу |
| `evidence_grade` | Optional enum (не используется) | **Auto-computed агентом при ingest** | Не ручное — agent автоматически определяет grade из анализа источника |

**Миграция:**
- Старые страницы → agent добавит `category` и `type` при следующем обновлении
- `evidence_grade` → вычисляется автоматически (documented/corroborated/assertion_only) при ingest из documentation sources

---

## 📝 Notes from Discussion
_(Здесь будут фиксироваться решения после обсуждения)_
