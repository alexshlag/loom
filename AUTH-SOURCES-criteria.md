# AUTH-SOURCES: Authoritative Sources Criteria (Issue #4)

**Статус**: 🟡 Pending User Decision  
**Создано**: 2026-06-27  
**Каноническая ссылка**: `issues.md#issue-4` → эта страница для обсуждения  

---

## 📖 Контекст

В `process-query.json#contradiction_resolution_flow` определён приоритет:
`authoritative_source > temporal_conflict > user_review`.

Но **нет механизма** автоматического определения, какой источник authoritative.  
Без этого `apply-contradiction-fix.sh` не может автоматически применять authoritative fix — только agent-review mode.

---

## ❓ Вопросы для решения

### Вариант A) Domain-based (жёсткий whitelist доменов)
```yaml
criteria:
  - domain_whitelist:
    - "github.com/<org>/<repo>@<version>"
    - "wikipedia.org"
    - "docs.<official>.com"
    - "*.mdn.*"
  # Всё, что не в whitelist → fallback на temporal/user_review
```

**Плюсы**:
- ✅ Просто автоматизировать (grep домена из URL/frontmatter)
- ✅ Чёткий критерий — нет двусмысленности

**Минусы**:
- ❌ Niche темы не попадают в whitelist → бесполезно
- ❌ Требует поддержки списка доменов

---

### Вариант B) Metadata-driven (система тегов при ingest)
```yaml
criteria:
  - frontmatter.source_type = "official"
  - frontmatter.author_level = "expert" | "company" | "community"
  # Гибкая система весов
```

**Плюсы**:
- ✅ Гибко, работает для любого домена
- ✅ Расширяемо (новые типы источников без изменения скрипта)

**Минусы**:
- ❌ Требует ручных меток при ingest → extra step
- ❌ Risk of inconsistent tagging across user sessions

---

### Вариант C) Hybrid (domain whitelist + metadata override) ⭐ Favorite
```yaml
criteria:
  - PRIMARY: domain in whitelist? → auto-official
  - FALLBACK: check frontmatter.author_level
    if expert/company → authoritative
    else → temporal/user_review
```

**Плюсы**:
- ✅ Лучшее из двух миров
- ✅ Domain = fast path (автоматически)
- ✅ Metadata = fallback for niche topics

**Минусы**:
- ❌ Сложнее скрипт проверки (2 шага вместо 1)

---

## 🎯 Критерии авторитетности (предложение)

| Level | Criteria | Auto-detect? | Example |
|-------|----------|-------------|---------|
| **L1 — Official** | Domain в whitelist + домен совпадает с entity | ✅ Да | `github.com/openai/...@v3.0`, `wikipedia.org/GPT-4` |
| **L2 — Expert** | Автор = известный эксперт/компания (frontmatter author match) | ⚠️ Partial | Author в YAML → check against known_experts.json |
| **L3 — Community** | Open-source wiki, no authoritative attribution | ❌ Нет | `hackernoon.com/article`, community blogs |
| **L4 — Personal** | User notes, personal opinions | ❌ Нет | `raw/notes/...`, `wiki/notes/` |

### Decision Tree:
```
Is source in domain_whitelist? → Yes → L1 (auto-apply)
                                → No  → Is author in known_experts? → Yes → L2 (agent-review)
                                                                       → No  → Fallback to temporal/user_review
```

---

## 📝 Решение (заполнить после обсуждения)

**Выбранный вариант**: _______________  
**Дата решения**: _______________  
**Домены в whitelist**: _______________  
**Известные эксперты/компании**: _______________  

**Реализовано в**: _______________  
**Status after decision**: ✅ Done / 🟡 Draft

---

*Last update: 2026-06-27 | Waiting for user input on hybrid approach.*
