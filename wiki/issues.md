# Wiki Issues — Результаты lint-проверки

## Дата проверки: 2026-06-24

### 1. Missing Frontmatter (check_id=5)
| Файл | Проблема |
|------|----------|
| `wiki/overview.md` | Нет YAML-фронтматтера вообще |
| `wiki/timeline.md` | Нет фронтматтера, только пустые `--- ---` |

### 2. Broken Relative Links (check_id=5)
| Файл | Ссылка | Проблема |
|------|--------|----------|
| `entities/andrej-karpathy.md` | `[Synthesis: Python NixOS Dev Environments](syntheses/python-nixos-development-environments.md)` | Нет `../` — путь разрешается как `wiki/entities/syntheses/...`, файла нет |
| `syntheses/python-nixos-dev.md` | `[/wiki/Home_Manager]` | Абсолютный путь с `/wiki/` не работает из wiki-контекста |

### 3. Date Inconsistency (check_id=1)
- `entities/pi-coding-agent.md`: `date: 2025-06-24`, но секция обновления говорит «Обновлено **2026**-06-24» — год в date vs updated не совпадает

### 4. Orphan Pages (check_id=2)
- `wiki/overview.md`, `wiki/timeline.md` — существуют, но **не упомянуты** в index.md ни в одной категории
- `meta/backlinks.json` пустой (`{"backlinks": {}}`) — фактических бэклинков нет

### 5. Lint Process Issues (проверка process-lint.md.json)
1. Нет обязательных полей фронтматтера: требуется `[tags, date, sources]`, `related` может быть пустым
2. Нет проверки согласованности дат (год в `date:` vs год в секциях обновления)
3. Относительные ссылки — нет стандарта wiki-relative vs filesystem-relative путей
4. Нет проверки дубликатов title внутри одной категории
5. Trigger conditions не имеют конкретных thresholds

---

*Создано: 2026-06-24 | Lint run #1 | Всего issues: 5 категорий, ~8 конкретных проблем*
