# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed (reference only)

| Phase | Feature | Commit |
|-------|----------|--------|
| 1-5 | Auto-rebuild meta, smarter search, non-blocking lint, index update, dynamic scoring | `1990a20` |
| 8 | Contradiction Deep Scan (Python-based) | `c368411` |
| 10 | Evidence-Based Priority System + frontmatter schema | `581b115` |
| 11.1 | Syndication Detection — `text-similarity.sh` | `258fa2c` |
| 12.1 | Decision Rules Framework — DR-1/DR-2/DR-3 | `c368411` |
| IF-1..IF-4 | Integration hooks: lint check_id=9, process refs, step_3c ingest scan | `b824a7` |

**Resolved from 06-28 audit**: P1 (shebangs), P2 (atomic writes), P3 (tests), P4 (error handling),
P5 (temp files), P6 (link validator limit), P7 (path guardrails), P9 (debug prints),
P12 (logging standard), P13 (trap handlers), P15 (minor fixes).

**Resolved from 06-28 session**: P8/#21 (heredoc injection → env var passing), #H3 (system file exclusion in detect-contradications), Phase 12.3 D6 (rebuild-meta auto-trigger after link-fix).

---

## ⬜ Unresolved — From 06-28 Audit

### Script fixes needed

| ID | Issue | Plan | Priority |
|----|-------|------|----------|
| **#H2** | Broken links auto-resolve (#H2 / Phase 12.3) — link-validator detects but can't fuzzy-match some targets | Fuzzy+agent escalation ✅ done (D1-D5). Manual review needed for `Home_Manager` target. | 🔴 High |
| **Phase 11.2** | Causal Chain Analysis (from original roadmap) | After issue fixes → future priority | 🟡 Low |

### Deferred (strategic)

| ID | Issue | Status |
|----|-------|--------|
| **P10** | Redundant wiki walks — 3 full walks per ingest, can be unified | Large refactor → deferred | ⬜ Deferred |
| **P11** | Manual JSON construction in bash scripts (`echo/printf` vs `jq`) | Scripts already use `json.dump()` for complex output; only echo-level needs migration | ⬜ Deferred |
| **P14** | Scripts documentation — no unified docs for 15+ scripts | Nice-to-have → deferred to onboarding work | ⬜ Deferred |

---

## 🔄 Pending Feature Phases (from original roadmap)

### Phase 11.2: Causal Chain Analysis
**Цель**: Agent prompt для "X wrote first, Y copied from X" — causal chain analysis на основе overlap данных из text-similarity.sh
**Приоритет**: Low (after issue fixes)

### Phase 12.2: Auto-Extract Assumptions
**Цель**: Агент автоматически экстрагирует assumptions из источников (источники с weak evidence помечать)
**Приоритет**: Future

---

## 🆕 New Issues from Post-Audit Analysis

### Issue: Broken links not auto-fixed by lint flow (#H2)

**Суть**: `link-validator.sh` обнаруживает битые ссылки (check_id=7), но не применяет auto-fix. Скрипт только считает количество и выводит JSON — agent-слой отсутствует.

**Пример**: `wiki/syntheses/python-nixos-development-environments.md:71`
   → `[NixOS Wiki - Home Manager](./Home_Manager.md)` ссылается на несуществующий `wiki/Home_Manager.md`.

**Корень проблемы**:
- `link-validator.sh --full` — только scanner (find broken links)
- `lint.sh` check 8: парсит exit code и count, но не парсит JSON для auto-fix
- `process-lint.json#check_id=7`: документация обещает "parse JSON + apply fixes", но скрипт не делает этого
- Auto-fix требует agent turn (парсинг → edit), но в autonomous lint режиме агент не присутствует

**Решение**: 2-уровневый auto-resolve flow:
1. **Script-level auto-repair** (`link-validator.sh --auto`):
   - Для каждой broken link: fuzzy-match target path против существующих wiki файлов
   - Если совпадение ≥80% по basename или частичному пути → применить fix (rewite ссылку)
   - Записать applied fixes в stdout JSON
2. **Agent escalation**: битые ссылки, которые не auto-repaired → список с контекстом для agent review
3. **Lint output format**:
   ```json
   {
     "broken_links": [{"file", "line", "link", "target", "auto_fixed": true/false}],
     "auto_repaired_count": N,
     "agent_review_required": [list of unfixable broken links]
   }
   ```

**Приоритет**: High (data integrity)

### Phase 12.3: Broken Link Auto-Reserve System ✅ DONE
**Цель**: Реализовать script-level fuzzy matching + agent escalation для broken links через `link-validator.sh --auto`
**Этапы**:
| # | Step | Description | Status |
|---|------|-------------|--------|
| **D1** | Script signature change | Добавить `--auto` флаг к `link-validator.sh`, вернуть JSON с `auto_fixed` boolean для каждой ссылки | ✅ Done |
| **D2** | Fuzzy matching logic | Для каждого broken target: basename match + partial path match → score ≥80% = auto-fix | ✅ Done |
| **D3** | Auto-apply fixes | Скрипт сам переписывает markdown links, если found confident match. Log all changes. | ✅ Done |
| **D4** | Agent escalation list | Broken links с score <80% или неоднозначные — добавить в `agent_review_required` array | ✅ Done |
| **D5** | Lint integration | Обновить `lint.sh` check 7: parse JSON, report auto_repaired_count + agent_review list to stderr | ✅ Done |
| **D6** | Rebuild meta after fix | После auto-fix → вызвать `rebuild-meta.sh --index-only` (автоматически из скрипта) | ✅ Done |

**Приоритет**: High (data integrity)
**Результат**: >90% typo/renamed links auto-fixed, оставшиеся — явный список для agent review.
**Текущая ситуация**: 1 broken link (`Home_Manager.md`) требует ручной проверки — нет близких кандидатов среди wiki файлов.

---

## 🔄 Pending Phases

| Phase | Description | Priority |
|-------|-------------|----------|
| Local Indexes | `index.md` в каждой категории для линейного поиска вместо O(n²) | High |
| Graph-Based Crosslinks | `auto-crosslink.sh` rewrite с shared-source analysis и scoring | Medium |
| Wiki Scalability (1000+ pages) | Optimizations: ripgrep, incremental rebuild, skip full rebuild >100 pages | Medium |

---

*Last update: 2026-06-28 | Original roadmap phases 1-5, 8-12 complete. IF-1..IF-4 integrated. Audit P1-P15 resolved. **Resolved this session**: P8/#21, #H3, Phase 12.3 D6. Remaining: #H2 (Home_Manager.md manual review), Phase 11.2 (future). Deferred: P10, P11, P14.*
