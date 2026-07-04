---
tags: [ nixos, python, development-environment]
date: 2026-06-24
sources: [raw/corrected/SRC-2025-06-24-002/nixos-python-wiki.md]
related: [wiki/syntheses/python-nixos-development-environments.md]
---

# Python Development Environments on NixOS


This page explores Python Development Environments on NixOS as a key concept in our knowledge base.


## Определение:
[[Python Development Environments]] on [[NixOS]] — методология создания изолированных сред разработки для [[Python]] в [[NixOS]], аналогичная virtualenv или conda, но с использованием декларативной системы сборки [[Nix]].

## Принципы работы:

### 1. Использование инфраструктуры Nixpkgs через `shell.nix` (рекомендуется)
- Создание файла `shell.nix` с пингом на конкретный commit Nixpkgs для воспроизводимости
- Определение необходимых пакетов через `python3.withPackages()`
- Сборка среды через `nix-shell` или `nix develop`

### 2. Работа с отсутствующими пакетами (not in Nixpkgs)
- Создание собственных nix-выражений через `buildPythonPackage`
- Использование `fetchPypi`, `pyproject.nix`, `poetry2nix` для упаковки
- Переопределение атрибутов Python через `.override {}`

### 3. Обработка скомпилированных библиотек (precompiled without nix)
Для пакетов, которые зависят от внешних C-библиотек:

**Решения:**
* **Nix overlay** — переопределение python для добавления `LD_LIBRARY_PATH`
* **nix-ld** — глобальная настройка путей к библиотекам через `programs.nix-ld`
* **buildFHSEnv** (рекомендуется) — создание FHS-окружения с необходимыми пакетами
* **wrapProgram** — обёртка исполняемого файла с добавлением путей к библиотекам

### 4. Альтернативные менеджеры пакетов
* **venv** — `nix-shell -p python3 --command "python -m venv .venv"`
* **uv** — быстрый менеджер на Rust, replaces pip/pip-tools/poetry/pyenv/virtualenv
* [Clippy](entities/rust-clippy.md) — linting tool для Rust, демонстрирует подход static analysis в compile-time
* **poetry & poetry2nix** — создание Nix-derivation из pyproject.toml
* **micromamba** — изолированные среды conda с FHS-обёрткой
* **conda** — нативный менеджер conda в NixOS через `conda-shell`
* **pixi** — современная альтернатива conda, требует FHS для активации

## Контекст и применение:

### Для разработки (shell.nix):
```nix
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/commit.tar.gz") {};
in pkgs.mkShell {
  packages = [
    (pkgs.python3.withPackages (p: with p; [ pandas requests ]))
  ];
}
```

### Для системной установки:
```nix
environment.systemPackages = with pkgs; [
  (python3.withPackages (p: with p; [ pandas requests ]))
];
```

## Примеры:

1. **Разработка с pandas + requests**: `shell.nix` через `pkgs.mkShell`
2. **Упаковка собственного пакета**: toolz.nix + buildPythonPackage + fetchPypi
3. **Несколько версий Python**: `lib.meta.lowPrio python314` + `python313`

## Связи:
* [Home Manager docs](https://nixos.org/manual/hm/) — external reference — использование FHS-обёртки для pixi через Home Manager
* [Nixpkgs Manual - Contributing Guidelines](https://nixos.org/nixpkgs/manual/#contributing-guidelines) — правила внесения пакетов Python
* [search.nixos.org/packages](https://search.nixos.org/packages) — поиск Python-пакетов в Nixpkgs
* [poetry2nix](https://github.com/nix-community/poetry2nix) — создание Nix-derivation из pyproject.toml

## Источники:
* `raw/corrected/SRC-2025-06-24-002/nixos-python-wiki.md` — https://wiki.nixos.org/wiki/Python (оригинал)

## Reconciliation note (#H2)
> Эта страница и [syntheses/python-nixos-development-environments.md](syntheses/python-nixos-development-environments.md) обе используют один источник (SRC-2025-06-24-002). Они охватывают одну тему из разных углов:
> - **Эта страница** — практическое руководство и принципы
> - **Синтез** — структурированный анализ способов с выводами
> Обе страницы согласованы, дублирование намеренное для разных целей чтения.

## Updated [2026-07-03] — shared source note
- **Group key**: `date:2025-06-24` (contradictions_deep scan)
- **Finding**: Pages using same SRC-2025-06-24 sources may have version drift if source updates
- **Resolution**: Reconciliation note (#H2) already documents shared relationship with syntheses page
- **Cleanup**: Removed duplicate entries from Updates section (Installing Multiple Versions x2, Performance x2)
- **Source:** `detect-contradications.sh` contradiction group `date:2025-06-24`

## Обновления (2026-06-24)
* Добавлено: **R packages в Python через rpy2** — секция про R integration
* Добавлено: **Nix shell (new command line)** — `nix shell --impure --expr '(import <nixpkgs> {}).python3.withPackages(...)'`
* Добавлено: **Упаковка приложений** — buildPythonApplication для Flask, pyproject.nix
* Добавлено: **Contribution guidelines** — pkgs/development/python-modules/<name>/default.nix (libraries), all-packages.nix (applications)
* Добавлено: **Special Modules (GNOME)** — GObject introspection с wrapGAppsHook
* Добавлено: **Debug Build** — enableDebug = true override для Python-пакетов
* Добавлено: **Installing Multiple Versions** — lib.meta.lowPrio/highPrio без конфликтов
* Добавлено: **Installing Multiple Versions** — lib.meta.lowPrio/highPrio без конфликтов
* Добавлено: **Performance** — 30-40% regression на синтетических бенчмарках, в реальном мире минимально (pylint scan: 5.5%)

## Примеры
* **nix develop** — вход в изолированную среду с нужными зависимостями: `nix develop github:nixos/nixpkgs#python3`
* **nix build .#hello-world** — сборка из local flake: `nix build -v --show-build-log --accept-flake-config --refresh .#hello-world`
* **nix shell nixpkgs#python3** — временный доступ к Python в текущей сессии без установки: `nix shell nixpkgs#python3; python3 --version`
* **NixOS module integration** — использование flake-зависимостей в NixOS конфигурации через `imports = [ (import ./flake.nix) ]`

