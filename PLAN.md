# PLAN: Wiki Improvement Roadmap (2026-06-26)

---

## ✅ Completed Phases

| Phase | Feature | Status | Commit |
|-------|---------|--------|------|
| 1 | Auto-rebuild meta (`rebuild-meta.sh`) | ✅ Done | `c368411` |
| 2 | Smarter search (priority categories) | ✅ Done | `664358e` |
| 3 | Non-blocking lint (`lint.sh`) | ✅ Done | `c368411` |
| 4 | Auto-update index.md (`--index-only`) | ✅ Done | `f362a2d` |
| 5 | Dynamic priority + relevance scoring | ✅ Done | `1990a20` |
| 7.1 | Auto-crosslink script (`auto-crosslink.sh`) | ✅ Done | pending |
| 7.2 | Integration in process-ingest.json | ✅ Done | pending |
| 6.1 | Search history + auto-save (`meta/search_history.json`) | ✅ Done | pending |
| 6.2 | Context-aware search bias (`wiki-search.sh` Phase 6) | ✅ Done | pending |

**Canonical sources**: All scripts in `scripts/`, process files reference them via `schema_ref`.

---

## 🟡 Pending Phases (sorted by priority)

### Phase 8: Contradiction Deep Scan — Medium Priority 🆕
**Цель**: Автоматизировать deep comparison фактов из разных страниц (версии, цифры, даты).

| Шаг | Что | Файл | Приоритет |
|-----|-----|------|-----------|
| 8.1 | `scripts/detect-contradications.sh` — парсит frontmatter.date + ключевые факты, строит матрицу | New script | Medium (soft check) |
| 8.2 | Интегрировать в process-query.json step 2 (pre-synthesis check) | `process-query.json#synthesis` | Low |

### Phase 9: Summary Extraction → WM — Low Priority 🆕
**Цель**: Автоматизировать извлечение key_facts + contradictions для working_memory.

| Шаг | Что | Файл | Приоритет |
|-----|-----|------|-----------|
| 9.1 | `scripts/extract-summary.sh` — H1 + first 3 sentences → structured JSON | New script | Low (token saving) |

---

## 📋 Next Actions

1. **Phase 8: detect-contradications.sh** — реализация auto-contrast scan
2. **Issue #4** — Authoritative Sources Criteria (see [issues.md](issues.md))
3. **AGENTS.md Phase 5 section** — missing link in Schema (checked, needs update)

### 🧠 Future Architecture Discussions (Phase 6 extensions)
See [PLAN_PHASE_6_FUTURE.md](PLAN_PHASE_6_FUTURE.md) for:
- Context bubbles (3 active pages strategy)
- Wiki as swap space for context overflow  
- Relevance markers + auto-compaction rules
- Topic reset triggers

---

## 🔄 Update Rules

- После каждой реализации → обновлять этот файл + git commit `schema | phase X completed`
- Устаревшие детали удалять при следующем чистке
- Live issues tracked in [issues.md](issues.md) — не дублировать здесь
- **Rule**: new phases sorted by priority (High → Medium → Low)

*Last update: 2026-06-27 | Phases 1-5, 6.1+6.2, 7.1+7.2 done; Phase 8 pending.*

### Phase 8: Contradiction Deep Scan — Medium Priority ✅ Done 🆕
**Цель**: Автоматизировать deep comparison фактов из разных страниц (версии, цифры, даты).

| Шаг | Что | Файл | Приоритет |
|-----|-----|------|-----------|
| 8.1 | `scripts/detect-contradications.sh` — Python-based deep scan | ✅ Done | ✅ Complete |
| 8.2 | Интегрировать в lint.sh (check_id=8) | ✅ Done in lint.sh | ✅ Complete |


*Last update: 2026-06-27 | Phases 1-5, 6.1+6.2, 7.1+7.2, 8 done.*

---

## 🧠 Contradiction Resolution Flow (Phase 8 extension)

**Принцип**: Не удалять старое → маркировать противоречие с ссылкой на альтернативный источник.

| Компонент | Статус | Описание |
|-----------|--------|----------|
| `detect-contradications.sh` | ✅ Done | Python-based deep scan, returns JSON with resolution_hint |
| process-query.json#2c | ✅ Done | contradiction_resolution step — append_to_section_or_create |
| Schema template | ✅ Already in AGENTS.md | `## Обновлено [DATE] — conflicting info` format |

**Алгоритм при обнаружении противоречия**:
1. Agent читает page с конфликтом из lint output
2. Проверяет наличие секции `## Обновлено`
3. Если нет → создаёт её
4. Если есть → добавляет новый пункт (не перезаписывает!)
5. Обновляет frontmatter: `has_contradiction: true`

**Дальнейшие шаги**:
- [ ] Auto-fix flow для contradictions в process-ingest.json
- [ ] Integration with issue #4 (Authoritative Sources Criteria from LM Studio)
- [ ] Visual indicator in graph view (conflicting edges)

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

