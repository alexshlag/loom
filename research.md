# Harness-Independent Wiki Operations

## Проблема

Проект `claude-obsidian` (https://github.com/AgriciDaniel/claude-obsidian) — это Compound Vault с полным набором Agent Skills, но его хуковая логика завязана на Claude Code:

| Хук | Что делает | Где определено |
|-----|-----------|----------------|
| `PostToolUse` | После Write/Edit → `git add wiki/.raw/ && git commit` | `.claude/hooks.json` |
| `SessionStart` | Загружает `wiki/hot.md` при старте сессии | `.claude/hooks.json` |
| `PostCompact` | Перечитывает hot.md после компакции контекста | `.claude/hooks.json` |
| `Stop` | Уведомляет обновить hot.md в конце ответа | `.claude/hooks.json` |

В Pi (и других harnesses) **нет аналога hooks.json**. Прямая переносимость ломается.

## Решение: вынести логику в скрипты + инструкции агенту

Заменить декларативные хуки на набор bash-скриптов, которые вызываются агентом по инструкции. Это делает проект harness-independent — работает одинаково в Claude Code, Pi, Codex, OpenCode.

---

## Скрипты

### 1. `scripts/git-auto-commit.sh` (эмуляция PostToolUse)

```bash
#!/usr/bin/env bash
# Auto-commits wiki changes after Write/Edit tool calls
# Harness-independent: any agent calls this explicitly after writing files

set -euo pipefail

# Safety checks
[ -d .git ] || exit 0
[ -f .vault-meta/auto-commit.disabled ] && exit 0

# Respect concurrency via wiki-lock (if available)
if [ -x scripts/wiki-lock.sh ]; then
  LOCK_LIST=$(bash scripts/wiki-lock.sh list 2>/dev/null) || {
    mkdir -p .vault-meta
    printf '%s wiki-lock failed; deferred auto-commit\n' \
      "$(date '+%Y-%m-%dT%H:%M:%SZ')" >> .vault-meta/hook.log
    exit 0
  }
  [ -n "$LOCK_LIST" ] && exit 0   # another writer active — skip safely
fi

# Stage only wiki paths (never project junk)
git add -- wiki/ .raw/ .vault-meta/ 2>/dev/null || exit 0

# Only commit if there are changes (avoid empty commits)
git diff --cached --quiet -- wiki/ .raw/ .vault-meta/ || \
  git commit -m "wiki: auto-commit $(date '+%Y-%m-%d %H:%M')" -- wiki/ .raw/ .vault-meta/ 2>/dev/null || true

exit 0
```

### 2. `scripts/load-hot-cache.sh` (эмуляция SessionStart)

```bash
#!/usr/bin/env bash
# Loads wiki/hot.md into stdout for agent to consume at session start
# Returns 1 if no vault detected, 0 otherwise

[ -f wiki/hot.md ] || exit 1

echo "=== HOT CACHE ==="
cat wiki/hot.md
echo "=== END HOT CACHE ==="

exit 0
```

### 3. `scripts/restore-hot-cache.sh` (эмуляция PostCompact)

```bash
#!/usr/bin/env bash
# Re-reads hot.md after context compaction
# Compaction discards hook-injected context; this restores it mid-session

[ -f wiki/hot.md ] || exit 1

echo "=== HOT CACHE RESTORED ==="
cat wiki/hot.md
echo "=== END HOT CACHE ==="

exit 0
```

### 4. `scripts/check-wiki-changes.sh` (эмуляция Stop)

```bash
#!/usr/bin/env bash
# Detects whether wiki files were modified since session start
# Returns 1 if no changes, 0 if there are changes needing hot.md update

[ -d .git ] || exit 1
[ -d wiki ]    || exit 1

CHANGED=$(git diff --name-only HEAD 2>/dev/null | grep '^wiki/' || true)
[ -z "$CHANGED" ] && exit 1

cat <<'PROMPT'
=== WIKI CHANGES DETECTED ===
Modified: $CHANGED

Update wiki/hot.md with a summary (under 500 words):
- Last Updated, Key Recent Facts, Recent Changes, Active Threads
=== END PROMPT ===

exit 0
```

---

## Инструкции для агента (в AGENTS.md или SKILL.md)

```markdown
## Harness-Independent Wiki Operations

Эти скрипты обрабатывают все пост-операционные задачи. **Вызывайте их когда указано** — работают одинаково в любом harness.

### Пост-запись коммит
После каждого Write/Edit, который трогает wiki-файлы → выполнить:
```bash
bash scripts/git-auto-commit.sh
```
Никогда не запускайте `git add *` напрямую — скрипт сам стейджит только `wiki/`, `.raw/`, и `.vault-meta/`. Также он уважает wiki-lock concurrency.

### Начало сессии: загрузка hot cache
При старте сессии (или возврате) → выполнить молча:
```bash
bash scripts/load-hot-cache.sh || true   # silent если нет vault
```
Агент должен прочитать вывод internally и продолжить — не анонсировать что было загружено.

### После компакции контекста
Если во время long session контекст был compacted, перечитать:
```bash
bash scripts/restore-hot-cache.sh || true
```
Compact-контексты выбрасывают injected content; это восстанавливает его.

### Гигиена конца сессии
Перед завершением сессии, где была работа с wiki → проверить и обновить hot.md:
```bash
if bash scripts/check-wiki-changes.sh 2>/dev/null; then
  # Агент читает prompt output и обновляет wiki/hot.md accordingly
fi
```

### Concurrency awareness (wiki-lock)
Перед записью в любую wiki-страницу:
1. Проверить, существует ли `scripts/wiki-lock.sh`
2. Если да — получить advisory lock перед Write/Edit:
   ```bash
   bash scripts/wiki-lock.sh acquire <path>
   # ... write via Write/Edit ...
   bash scripts/wiki-lock.sh release <path>
   ```
3. Пропустить auto-commit если locks active (другой writer может быть в flight)

### Delta tracking
Перед ingestion нового файла → проверить `.raw/.manifest.json`:
- Если hash совпадает — skip, сказать "Already ingested"
- Если нет или файла нет → proceed с ingest и обновить manifest после

```

---

## Сравнение: claude-obsidian vs наше решение

| Аспект | claude-obsidian | Наше решение |
|--------|-----------------|--------------|
| PostToolUse | hooks.json (Claude Code only) | `git-auto-commit.sh` + инструкция |
| SessionStart | hooks.json + prompt injection | `load-hot-cache.sh` + инструкция |
| PostCompact | hooks.json prompt | `restore-hot-cache.sh` + инструкция |
| Stop | hooks.json command | `check-wiki-changes.sh` + instruction |
| Harness dependency | Claude Code / MCP plugins | **Ничего** — pure bash + instructions |
| TypeScript extensions | Not needed | Not needed |
| Cross-project referencing | CLAUDE.md based | Same, works in any harness |

## Преимущества подхода

1. **Zero dependencies on harness internals** — работает в Pi, Claude Code, Codex, OpenCode, или любом future agent
2. **Инструкции вместо кода** — агент получает чёткий trigger-паттерн: "после Write → run script"
3. **Все существующие скрипты сохраняют ценность** — wiki-lock.sh, allocate-address.sh, detect-transport.sh, wiki-mode.py уже есть и работают без изменений
4. **Самодостаточность** — проект не требует внешних плагинов, MCP серверов, или специальных хуков harness'а

---

## Next steps

1. ✅ Создать 4 скрипта в `scripts/` (git-auto-commit.sh, load-hot-cache.sh, restore-hot-cache.sh, check-wiki-changes.sh)
2. ✅ Добавить секцию инструкций в AGENTS.md или отдельный SKILL.md
3. ✅ Обновить существующие Skills (wiki-ingest, save, wiki-fold) чтобы они вызывали `git-auto-commit.sh` после Write/Edit
4. ✅ Добавить инструкцию о hot-cache в bootstrap-секцию AGENTS.md

## Источники вдохновения

- claude-obsidian hooks: `/home/andrew/projects/claude-obsidian/hooks/hooks.json`
- Loomana git conventions: `AGENTS.md#🔖 Git Conventions` — agent-driven, no harness dependencies
- Agent Skills spec: cross-platform standard (kepano convention)
