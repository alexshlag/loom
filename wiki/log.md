# Wiki Log

## [2026-06-23] ingest | Инициализация wiki — структура и инструкции восстановлены

---

## [2026-06-23] guardrails | реализована Schema-level блокировка direct edits к raw/ и meta/

## [2026-06-24] ingest | Pi Coding Agent — https://pi.dev/docs/latest

## [2026-06-24] ingest | Python Development on NixOS — https://wiki.nixos.org/wiki/Python

## [2026-06-24] query | Основные способы создания сред разработки Python для NixOS

## [2026-06-24] ingest | raw/llm-wiki.md — LLM Wiki Pattern (Andrej Karpathy)
* Создана entity: Andrej Karpathy
* Создан concept: LLM Wiki Pattern
* Создан synthesis: RAG vs LLM Wiki Pattern
* Обновлено: overview.md, index.md

## [2026-06-24] query | LLM Wiki Pattern — сравнение реализации с идеей Karpathy
* Создан AGENTS.md (markdown schema document по оригинальной идее Karpathy)
* Добавлен compounding workflow в process-query: step 2.6 compounding_decision, enhanced save_conditions
* Теперь answers сохраняются как новые страницы при novel insights/synthesis — wiki compounds

## [2026-06-24] schema | AGENTS.md created matching Karpathy's original concept
* Markdown schema document co-evolves between human and LLM
* Defines structure, workflows (ingest/query/lint), guardrails, page formats
* Replaces rigid JSON-only approach with flexible evolving schema

## [2026-06-24] lint | Первый полный lint-аудит wiki
* Создан issues.md — отчёт о проблемах (5 категорий: frontmatter, broken_links, date_inconsistency, orphan_pages, process_improvements)
* Обновлён process-lint.md.json:
  - Добавлены thresholds для trigger conditions
  - check_id=6: date_consistency_check
  - Уточнены правила missing_frontmatter (required vs optional fields)
  - Указан lint_script_path (scripts/run-lint.sh)
  - Добавлен frontmatter_schema
* Найдено 3 issues по broken_links, 1 date inconsistency, 2 missing frontmatter

## [2026-06-24] ingest | AI Factory — https://github.com/lee-to/ai-factory
* Создана entity: AI Factory (wiki/entities/ai-factory.md)
* Raw sources сохранены в raw/github/lee-to/ai-factory@2.x/
* Tags: tool, cli, agent-skill-system, stack-agnostic, spec-driven

## [2026-06-24] schema | Добавлен режим execution_modes в AGENTS.md
* Глобальный default: silent. По запросу пользователя → verbose (пошаговый trace)
* Переключение: "давай проверим" / "verbose mode" / "покажи шаги"
* Авто-возврат к silent после 3 verbose-ответов
* В AGENTS.md добавлен раздел `## ⚙️ Execution Modes` с примером JSON для process_query
* В process-lint.md.json добавлён execution_mode (default: silent, trigger for verbose)
* Логирование в verbose зависит от процесса: [✓] success, [✗] issue, [!] warning

## [2026-06-24] concept | AI Factory vs Pi — Category Distinction
* Создан concept: wiki/concepts/ai-factory-vs-pi.md
* Уточнено: AI Factory = workflow schema (запускается на любом harness), Pi = harness runtime

## [2026-06-24] schema | AGENTS.md v4 — добавлено правило Date Convention Rule
* Issue #3 (date consistency): root cause identified — agent confused source capture dates with page creation dates
* Fix: added `📅 Date Convention Rule` to AGENTS.md specifying `system_current_date_only` for frontmatter dates
* JSON schema added to prevent future drift: `never_derive_from: [source_filename, raw_timestamps]`
* Schema version bumped from 3 → 4


## [2026-06-24] lint | Cleanup — Home_Manager artifact removed, @process-lint.md.json improvement noted
* Удалён `wiki/Home_Manager.md` (снимок jpg, не markdown) — артефакт захвата без frontmatter и категории
* Задача для future: улучшить @process-lint.md.json чтобы детектить untracked image artifacts
* Wiki структура чистая: 8 content pages + meta files, все ссылки работают

