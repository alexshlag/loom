---
tags: [entity, coding-agent, terminal]
date: 2026-06-24
sources: [raw/sources/SRC-2025-06-24-001/pi-dev-docs-latest.md]
related: []
---

# Pi Coding Agent

Минимальный терминальный код-агент (harness), расширяемый через TypeScript-расширения, skills, prompt templates и темы. Подключается к subscription или API-key провайдерам для работы с LLM.

## Ключевые характеристики:
* **Минимальное ядро** — остаётся небольшим, но расширяется через плагины
* **TypeScript-расширения** — инструменты, команды, события, кастомный UI
* **Skills** — переиспользуемые on-demand возможности агента
* **Prompt templates** — переиспользуемые промпты из slash-команд
* **Темы** — встроенные и пользовательские терминальные темы
* **Pi packages** — упаковка и обмен расширениями, skills, промптами, темами
* **Программное использование** — SDK для Node.js, RPC mode, JSON event stream, TUI компоненты

## Установка:
```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
# или на Linux/macOS:
curl -fsSL https://pi.dev/install.sh | sh
```

## Связи:
* [Документация](https://pi.dev/docs/latest) — полный справочник
* [Using Pi](https://pi.dev/docs/latest/usage) — interactive mode, slash commands, context files
* [Providers](https://pi.dev/docs/latest/providers) — subscription и API-key setup
* [Security](https://pi.dev/docs/latest/security) — project trust, sandbox boundaries
* [Containerization](https://pi.dev/docs/latest/containerization) — sandbox with Gondolin, Docker, OpenShell
* [Settings](https://pi.dev/docs/latest/settings) — global and project settings
* [Sessions](https://pi.dev/docs/latest/sessions) — session management, branching
* [Compaction](https://pi.dev/docs/latest/compaction) — context compaction
* [Extensions](https://pi.dev/docs/latest/extensions) — TypeScript modules for tools, commands, events
* [Skills](https://pi.dev/docs/latest/skills) — Agent Skills для переиспользуемых возможностей
* [Prompt templates](https://pi.dev/docs/latest/prompt-templates) — reusable prompts из slash-команд
* [Themes](https://pi.dev/docs/latest/themes) — built-in и custom терминальные темы
* [Custom models](https://pi.dev/docs/latest/models) — добавление model entries
* [Custom providers](https://pi.dev/docs/latest/custom-provider) — custom APIs и OAuth flows
* [SDK](https://pi.dev/docs/latest/sdk) — embed pi в Node.js приложениях
* [RPC mode](https://pi.dev/docs/latest/rpc) — интеграция через stdin/stdout JSONL
* [TUI components](https://pi.dev/docs/latest/tui) — кастомный terminal UI для расширений
* [Keybindings](https://pi.dev/docs/latest/keybindings) — default shortcuts и custom keybindings
* [Sessions](https://pi.dev/docs/latest/sessions) — session management, branching и tree navigation
* [Compaction](https://pi.dev/docs/latest/compaction) — context compaction и branch summarization
* [Development](https://pi.dev/docs/latest/development) — local setup, project structure, debugging
* [Using Pi](https://pi.dev/docs/latest/usage) — интерактивный режим, slash-команды, контекстные файлы, CLI reference
* [Providers](https://pi.dev/docs/latest/providers) — настройка subscription и API-key
* [Security](https://pi.dev/docs/latest/security) — доверие проекта, границы sandbox, отчёт об уязвимостях
* [Containerization](https://pi.dev/docs/latest/containerization) — sandbox с Gondolin, Docker или OpenShell
* [Settings](https://pi.dev/docs/latest/settings) — глобальные и проектные настройки
* [Sessions](https://pi.dev/docs/latest/sessions) — управление сеансами, ветвление, навигация по дереву
* [Compaction](https://pi.dev/docs/latest/compaction) — компактификация контекста и суммаризация веток

## Источники:
* `raw/sources/SRC-2025-06-24-001/pi-dev-docs-latest.md` — https://pi.dev/docs/latest (оригинал)

## Обновлено 2026-06-24 — новое уточнение
* Добавлены: Keybindings, Sessions, Compaction, Development, Windows/Termux/tmux links
* **Uninstall:** `npm uninstall -g @earendil-works/pi-coding-agent` (также pnpm/yarn/bun)
* **Аутентификация:** `/login` для subscription providers или `ANTHROPIC_API_KEY`
* Дополнительные разделы: Windows, Termux, tmux, Terminal setup
