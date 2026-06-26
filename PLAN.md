# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed Phases

| Phase | Feature | Commit |
|-------|----------|------|
| 1 | Auto-rebuild meta (`rebuild-meta.sh`) | `c368411` |
| 2 | Smarter search (priority categories) | `664358e` |
| 3 | Non-blocking lint (`lint.sh`) | `c368411` |
| 4 | Auto-update index.md (`--index-only`) | `f362a2d` |
| 5 | Dynamic priority + relevance scoring | `1990a20` |

---

## 🟡 Pending Phases (sorted by priority)

### Phase 8: Contradiction Deep Scan — Medium Priority ✅ Done
**Цель**: Автоматизировать deep comparison фактов из разных страниц (версии, цифры, даты).

| Шаг | Что | Приоритет |
|-----|------|------|
| 8.1 | `scripts/detect-contradications.sh` — Python-based deep scan | ✅ Complete |
| 8.2 | Интегрировать в lint.sh (check_id=8) | ✅ Complete in lint.sh |

### Phase 9: Summary Extraction → WM — Low Priority 🆕
**Цель**: Автоматизировать извлечение key_facts + contradictions для working_memory.

| Шаг | Что | Приоритет |
|-----|------|------|
| 9.1 | `scripts/extract-summary.sh` — H1 + first 3 sentences → structured JSON | New script |

---

## 📋 Next Actions

1. Закрыть теоретические вопросы T1-T6 (см. ниже)
2. Реализовать Evidence-Based Priority в `process-query.json#contradiction_resolution_flow`
3. Создать `scripts/verify-source.sh` для domain classification

---

## 🧠 Теоретические вопросы (Theory Issues)

> *Раздел для хранения вопросов теории, которые нужно закрыть перед реализацией.*
> *Каждый вопрос — потенциальный баг в алгоритме или архитектурный пробел.*

### T1: L0 vs L1 дублируют Hard Evidence
**Статус**: 🟡 Pending Discussion  
**Контекст**: `verification_rules.json` имеет `L0_HARD_Evidence` (priority 1) и `L1_LIVE_STATE_DECAY` (priority 2). Live-state лог/метрика — это тоже Hard Evidence. Два приоритета для одного типа данных → ambiguity.
**Вопрос**: Должны ли L0 и L1 быть объединены, или Live State должен иметь отдельный подтип?

### T2: Нет чёткого resolve-cascade
**Статус**: 🟡 Pending Discussion  
**Контекст**: `decision_matrix` содержит только булевые флаги. Если несколько правил сработали — кто побеждает? Нужен строгий порядок применения.
**Вопрос**: Как определить cascade order при конфликте приоритетов?

### T3: Domain classification без механизма определения
**Статус**: 🟡 Pending Discussion  
**Контекст**: Правила содержат `"context_domains": ["finance", ...]`, но скрипт не знает, в каком домене работает.
**Вопрос**: Как автоматически определить domain context для источника? Нужен отдельный классификатор или эвристика?

### T4: Полный рефакторинг contradiction_resolution_flow
**Статус**: 🟡 Pending Discussion  
**Контекст**: `process-query.json#step 2c` имеет `authoritative_source > temporal_conflict > user_review`. Новый JSON требует `hard_evidence > live_state > code_reality`. Это не дополнение — это замена.
**Вопрос**: Как совместить старый flow с Evidence-Based Priority без потери совместимости?

### T5: Code Reality vs Live State приоритет
**Статус**: 🟡 Pending Discussion  
**Контекст**: В техно-сценарии код > документации, но live-state может быть просто snapshot'ом старой метрики. Нужно правило: `if source_type == code → L0`, иначе `if timestamp < threshold → L1_Live`.
**Вопрос**: Как формализовать приоритет Code Reality vs Live State?

### T6: Syndication detection (source independence)
**Статус**: 🟢 Future Phase  
**Контекст**: Если все источники L4 ссылаются друг на друга — consensus должен понижать weight до L5 или ниже.
**Вопрос**: Как определить, что источники синдицированы (copy-paste друг друга)?

---

*Last theory update: 2026-06-27 | Issues T1-T6 identified during verification_rules.json analysis.*

---

## 🔄 Update Rules

- После каждой реализации → обновлять этот файл + git commit `schema | phase X completed`
- Устаревшие детали удалять при следующей чистке
- Live issues tracked in [issues.md](issues.md) — не дублировать здесь
- **Rule**: new phases sorted by priority (High → Medium → Low)

*Last update: 2026-06-27 | Phases 1-5, 8 done.*
