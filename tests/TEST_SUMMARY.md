# Process Instruction Tests — Summary

## Overview

Создан набор из **53 тестов** для проверки логики работы всех process-*.json файлов в проекте Loomana.

## Что тестируется

### 1. Структура процессных файлов ✅
| Тест | Что проверяет |
|------|--------------|
| Module field present | Все файлы имеют `module` поле |
| Steps list structure | Шаги — массив/объект с правильной структурой |
| Description present | Каждый процесс имеет описание |

### 2. Порядок шагов ✅
| Тест | Что проверяет |
|------|--------------|
| Steps ordered by number | Шаги идут по порядку (1→12) |
| Guardrails before analysis | Шаг 1 (guardrails) предшествует шагу 3 (analysis) |
| Hot cache before search | В query: hot cache (0.25) → search (1) |

### 3. Schema References ✅
| Тест | Что проверяет |
|------|--------------|
| Ingest schema refs exist | Все `schema_ref` в ingest指向 существующие файлы |
| Query schema refs exist | Все `schema_ref` в query指向 существующие файлы |

### 4. Error Handling ✅
| Тест | Что проверяет |
|------|--------------|
| Ingest error handling | `error_handling` секция с `schema_ref` |
| Query error handling | `error_handling` секция с `schema_ref` |

### 5. Cross-Process Transitions ✅
| Тест | Что проверяет |
|------|--------------|
| Web ingest flow | query → ingest переход определён |
| Cross-process triggers | Ingest имеет триггеры для lint и других процессов |

### 6. Working Memory Hooks ✅
| Тест | Что проверяет |
|------|--------------|
| on_start trigger | Ingest запускается с обновлением WM |
| on_complete trigger | Ingest завершается с очисткой WM и hot cache |

### 7. Script Existence ✅
| Тест | Что проверяет |
|------|--------------|
| Ingest scripts exist | Все `./scripts/*` в ingest существуют |
| Query scripts exist | Все `./scripts/*` в query существуют |

### 8. Branching Logic ✅
| Тест | Что проверяет |
|------|--------------|
| Step 6 branching | Шаг 6 имеет ветвления на 8a и 8b |
| Targets exist | Целевые шаги (step_8a_new_page, step_8b_update_page) существуют |

## Как запустить

```bash
# Все тесты
python3 run_tests.py

# Или через unittest
python3 -m unittest tests.test_process_ingest tests.test_process_integration \
                      tests.test_process_additional tests.test_process_commands -v
```

## Файлы тестов

| Файл | Количество тестов | Описание |
|------|-------------------|----------|
| `tests/test_process_ingest.py` | 27 | Ingest и Query базовая структура, cross-process consistency |
| `tests/test_process_integration.py` | 15 | Step ordering, schema refs, git conventions, scripts |
| `tests/test_process_additional.py` | 6 | Branching logic, trigger conditions, evaluation criteria |
| `tests/test_process_commands.py` | 3 | Script existence verification |

## Результаты

```
Ran 53 tests in 0.007s
OK — All tests passed!
```
