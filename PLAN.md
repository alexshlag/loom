# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed Phases

| Phase | Feature | Commit |
|-------|----------|--------|
| 1 | Auto-rebuild meta (`rebuild-meta.sh`) | `c368411` |
| 2 | Smarter search (priority categories) | `664358e` |
| 3 | Non-blocking lint (`lint.sh`) | `c368411` |
| 4 | Auto-update index.md (`--index-only`) | `f362a2d` |
| 5 | Dynamic priority + relevance scoring | `1990a20` |
| 8 | Contradiction Deep Scan | `c368411` |

---

## 📋 Phase 10: Evidence-Based Priority System — ✅ Complete

**Цель**: Cascade-based приоритеты (`Code Reality → Live State → Documentation with evidence_grade`) + **Arbitration Layer** (objective vs subjective facts).

| Шаг | Что | Статус | Commit |
|-----|------|--------|--------|
| 10.2 | Переписать `contradiction_resolution_flow` в cascade-based | ✅ Done | `258fa2c` |
| 10.1 + 10.4 | Frontmatter schema: `type`, `evidence_grade` extraction | ✅ Done | `581b115` |
| 10.3 | Создать `scripts/classify-source.sh` — domain whitelist, graceful fallback | ✅ Done | `8a77d80` |

---

## 🟡 Pending Phases (sorted by priority)

### Phase 11: Syndication Detection — ✅ Complete
**Цель**: Detect copy-paste chains и понижать weight dependent sources.

| Шаг | Что | Приоритет |
|------|------|----------|
| **11.1** | `scripts/text-similarity.sh` — n-gram pairwise & scan-all comparison, configurable --gram-size flag (2-6) | ✅ Done |
| **11.2** | Agent prompt для causal chain analysis: "X wrote first, Y copied from X" | Low |

### Phase 12: Decision Rules Framework — ✅ Complete
**Цель**: Таблица decision rules для agent при интерпретации сигналов из скриптов/источников. Scripts detect → agent evaluates.

| Шаг | Что | Приоритет |
|-----|------|----------|
| **12.1** | `AGENTS.md#decision_rules` — DR-1 (overlap neutral), DR-2 (correction evidence), DR-3 (authorship) | ✅ Done |
| 12.2 | Agent prompt для auto-extracting assumptions из источников | Future |

---

## 📋 Integration Fixes (Phase 12 completion)

| Fix | File | Change |
|-----|------|--------|
| **IF-1** | `scripts/lint.sh` | Added check_id=9: text similarity scan (--scan-all --threshold 90) |
| **IF-2** | `process-lint.json` | Added lint_check for check_id=9 with schema_ref → AGENTS.md#decision_rules |
| **IF-3** | `process-query.json` | Added decision_rules_schema_ref at steps[4], DR-2 trigger in agent_prompt |
| **IF-4** | `process-ingest.json` | Added module-level decision_rules_schema_ref |

---



## ✅ Completed Integration Fixes

| Fix | File | Change | Status |
|-----|------|----------|--------|
| **IF-1** | `scripts/lint.sh` | Added check_id=9: text similarity scan (--scan-all --threshold 90) | ✅ Done |
| **IF-2** | `process-lint.json` | Added lint_check for check_id=9 with schema_ref → AGENTS.md#decision_rules | ✅ Done |
| **IF-3** | `process-query.json` | Added decision_rules_schema_ref at steps[4] (step_3 result_fixation), DR-2 trigger in agent_prompt | ✅ Done |
| **IF-4** | `process-ingest.json` | Added module-level decision_rules_schema_ref + step_3c post_integration_overlap_scan | ✅ Done |

## 🔄 Completed Spec: Ingest Post-Integration Scan

| File | Step | Spec | Status |
|------|------|------|--------|
| `process-ingest.json#step_3c` | post_integration_overlap_scan | [INGEST_TEXT_SIMILARITY_TRIGGER.md](INGEST_TEXT_SIMILARITY_TRIGGER.md) | ✅ Done |

**Description**: После создания/обновления страницы — сканировать wiki на overlap ≥90%, agent применяет DR-1/DR-2. Аналогично lint hook (check_id=9), но с immediate feedback для ingest flow.

---

## 🧠 Теоретические вопросы (Theory Issues) — All Resolved ✅

> *Раздел для хранения вопросов теории, которые нужно закрыть перед реализацией.*
> *Все T1-T6 закрыты через dialog.md цепочку обсуждений. T7 (correction vs blind copy) resolved via DR-2.*

### T1: L0 vs L1 дублируют Hard Evidence ✅ Resolved
**Решение**: Не дубликат. Это **два разных типа фактов**, а не два уровня авторитетности одного:
- **L0 Code Reality** — код в репозитории (machine-verifiable, deterministic)
- **L1 Live State** — метрики/логи прямо сейчас (ephemeral но observable)

### T2: Нет чёткого resolve-cascade ✅ Resolved
**Решение**: Жёсткий порядок — не приоритеты доменов, а тип факта: `code_reality > live_state > documentation`.

### T3: Domain classification без механизма определения ✅ Resolved
**Решение**: `scripts/classify-source.sh` — domain whitelist + known authors. Fallback chain при ошибках.

### T4: Полный рефакторинг contradiction_resolution_flow ✅ Resolved
**Решение**: Полная замена старого flow (`authoritative_source → temporal_conflict → user_review`) на cascade-based логику + **arbitration_layer**.

### T5: Code Reality vs Live State приоритет ✅ Resolved
**Решение**: Формализован в `process-query.json` с exception для более свежего live-state.

### T6: Syndication detection (source independence) 🟡 Partially Resolved
**Решение**: Script text match → agent causal chain → reduced consensus weight. Реализация — Phase 11.

---

## 🔄 Update Rules

- После каждой реализации → обновлять этот файл + git commit `schema | phase X completed`
- Устаревшие детали удалять при следующей чистке
- Live issues tracked in [issues.md](issues.md) — не дублировать здесь
- **Rule**: new phases sorted by priority (High → Medium → Low)

*Last update: 2026-06-27 | Phase 10+12 complete. Lint hook + process refs integrated. Spec: INGEST_TEXT_SIMILARITY_TRIGGER.md*
