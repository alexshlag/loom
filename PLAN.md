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

### Phase 10: Evidence-Based Priority System — High Priority
**Цель**: Реализовать cascade order (`Code Reality → Live State → Documentation`) на основе решённых T1-T6.

| Шаг | Что | Приоритет |
|-----|------|----------|
| 10.1 | Добавить `type: code_reality | live_state | documentation` в frontmatter schema | High |
| 10.2 | Переписать `contradiction_resolution_flow` в `process-query.json` — заменить старый flow на новый cascade-based | ✅ Done (2026-06-27) |
| 10.3 | Создать `scripts/classify-source.sh` — парсит URL, проверяет whitelist доменов для docs | Medium |
| 10.4 | Добавить `evidence_grade` extraction в agent prompt при ingest/query | ✅ Done (2026-06-27) |

### Phase 11: Syndication Detection — Medium Priority (T6)
**Цель**: Detect copy-paste chains и понижать weight dependent sources.

| Шаг | Что | Приоритет |
|-----|------|----------|
| 11.1 | `scripts/text-similarity.sh` — finds overlapping text (90%+ match) | Medium |
| 11.2 | Agent prompt для causal chain analysis: "X wrote first, Y copied from X" | Low |

### Phase 12: Contextual Split & Assumption Chain — Future (из сценариев 3-5)
**Цель**: Поддерживать `context_tags`, `assumptions`, `contradicts_when` в fact-level metadata.

| Шаг | Что | Приоритет |
|-----|------|----------|
| 12.1 | Расширить frontmatter schema для `facts[].contexts[]`, `facts[].assumptions[]` | Low |
| 12.2 | Agent prompt для auto-extracting assumptions из источников | Future |

---

*Last theory update: 2026-06-27 | T1-T6 discussed and resolved via dialog.md chain.*

---

## 🧠 Теоретические вопросы (Theory Issues)

> *Раздел для хранения вопросов теории, которые нужно закрыть перед реализацией.*
> *Каждый вопрос — потенциальный баг в алгоритме или архитектурный пробел.*

### T1: L0 vs L1 дублируют Hard Evidence ✅ Resolved
**Контекст**: `verification_rules.json` имеет `L0_HARD_Evidence` (priority 1) и `L1_LIVE_STATE_DECAY` (priority 2).
**Решение**: Не дубликат. Это **два разных типа фактов**, а не два уровня авторитетности одного:
- **L0 Code Reality** — код в репозитории (machine-verifiable, deterministic)
- **L1 Live State** — метрики/логи прямо сейчас (ephemeral но observable)
Оба — эмпирические факты. Агент при verification классифицирует fact как `type: code_reality | live_state | documentation`. Это type classification, не authority level.

### T2: Нет чёткого resolve-cascade ✅ Resolved
**Контекст**: `decision_matrix` содержит только булевые флаги.
**Решение**: Жёсткий порядок — **не приоритеты доменов**, а тип факта:
```yaml
cascade_order:
  - priority: 1, type: code_reality
  - priority: 2, type: live_state
  - priority: 3, type: documentation, evidence_grade depends on source + corroboration
```
При конфликте берётся rule с lowest priority number. Если одинаковый priority → agent review.

### T3: Domain classification без механизма определения 🟡 Partially Resolved
**Контекст**: Правила содержат `"context_domains": [...]`, но скрипт не знает домен.
**Решение**: Domain-классификатор нужен **только для Level 3 (documentation)**. Для L0/L1 type определяется автоматически по типу файла.
```yaml
domain_classification:
  method: URL parse → extract domain
  whitelist_check: true → L1 Official (auto)
                 false → check frontmatter.author_level
                    expert/company → L2 Expert (agent-review)
                    unknown → L3 Community (temporal/user_review)
```
Механизм: `scripts/classify-source.sh` парсит URL, проверяет whitelist. Agent + human для niche доменов.

### T4: Полный рефакторинг contradiction_resolution_flow ✅ Resolved
**Контекст**: Старый flow — `authoritative_source > temporal_conflict > user_review`. Новый требует `hard_evidence > live_state > code_reality`.
**Решение**: **Полная замена, не дополнение**. Старый flow удаляется:
```yaml
new_contradiction_flow:
  step_1: classify each source type → code_reality | live_state | documentation
  step_2: apply cascade: code_reality > live_state > documentation
  step_3: for docs: evidence_grade (documented > corroborated > assertion_only)
  step_4: if agent_confidence < threshold → human_review
```

### T5: Code Reality vs Live State приоритет ✅ Resolved
**Контекст**: Код > документации, но live-state может быть snapshot'ом старой метрики.
**Решение**: Формализация:
```yaml
code_vs_live_state:
  rule_1: if source_type == code → L0 (always)
  rule_2: if timestamp < threshold AND source_type != code → L1 Live State
  exception: live более свежий + код не исправлен → prioritize_live
```
Пример: docs говорят `getChat()` работает. GitHub issue показывает infinite loop → если issue открыт, код не зафиксирован как исправленный — Live State > Code Reality.

### T6: Syndication detection (source independence) 🟡 Partially Resolved
**Контекст**: Если все источники L4 ссылаются друг на друга — consensus должен понижать weight до L5.
**Решение**: Syndication detection = **определение copy-paste chain**:
```yaml
syndication_detection:
  method: text_similarity + source attribution analysis
  step_1: Script finds overlapping text (90%+ match)
  step_2: Agent determines causal chain ("X wrote first, Y copied from X")
  step_3: Consensus of dependent sources → LOWER weight
```
Результат: **1 независимый источник с доказательствами > 50 зависимых**.

---

*Last theory update: 2026-06-27 | Issues T1-T6 identified during verification_rules.json analysis.*

---

## 🔄 Update Rules

- После каждой реализации → обновлять этот файл + git commit `schema | phase X completed`
- Устаревшие детали удалять при следующей чистке
- Live issues tracked in [issues.md](issues.md) — не дублировать здесь
- **Rule**: new phases sorted by priority (High → Medium → Low)

*Last update: 2026-06-27 | T1-T6 resolved. Ready for Phase 10 implementation.*
