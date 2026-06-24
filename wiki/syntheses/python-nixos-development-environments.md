---
tags: [synthesis, nixos, python, development-environment]
date: 2025-06-24
sources: [wiki/concepts/python-nixos-development.md, raw/sources/SRC-2025-06-24-002/nixos-python-wiki.md]
related: []
---

# Основные способы создания сред разработки Python на NixOS

## Контекст
Вопрос: какие основные подходы к созданию изолированных сред разработки для Python существуют в экосистеме NixOS? Исходный источник — [NixOS Wiki - Python](https://wiki.nixos.org/wiki/Python).

## Анализ

### Способ 1: Nixpkgs infrastructure через `shell.nix` ⭐ (рекомендуется)
Создание декларативного файла `shell.nix`:
```nix
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/<commit>.tar.gz") {};
in pkgs.mkShell {
  packages = [
    (pkgs.python3.withPackages (p: with p; [ pandas requests ]))
  ];
}
```
**Плюсы:** воспроизводимость через pin-commit, нативная интеграция с Nix.

### Способ 2: Nix overlay для зависимостей
Переопределение Python через overlay для добавления `LD_LIBRARY_PATH`:
```nix
nixpkgs.overlays = [(self: super: rec {
  pythonldlibpath = lib.makeLibraryPath (with super; [ zlib zstd stdenv.cc.cc ... ]);
})];
```

### Способ 3: nix-ld для глобальной настройки путей к библиотекам
```nix
programs.nix-ld = { enable = true; libraries = with pkgs; [...]; };
```
Позволяет использовать precompiled C-библиотеки в NixOS.

### Способ 4: buildFHSEnv (рекомендуется для FHS)
Создание полноценного FHS-окружения:
```nix
pkgs.buildFHSEnv { name = "fhs"; targetPkgs = _: [ pkgs.python3 ]; }
```

### Способ 5: venv
Классический подход через Nix-shell:
```bash
$ nix-shell -p python3 --command "python -m venv .venv --copies"
```

### Способ 6-10: Альтернативные менеджеры пакетов
| Менеджер | Описание | Особенности |
|----------|----------|-------------|
| **uv** (Rust) | Заменяет pip/pip-tools/poetry/pyenv/virtualenv | Быстрый, не требует Python |
| **poetry + poetry2nix** | Nix-derivation из pyproject.toml | Для современных проектов |
| **micromamba** | Изолированные среды conda | Требует FHS-обёртку |
| **conda** | Нативный менеджер | Через `conda-shell` |
| **pixi** | Современная альтернатива conda | Требует FHS для активации |

## Выводы
1. **shell.nix + Nixpkgs** — основной рекомендуемый подход для типовой разработки
2. **buildFHSEnv** — лучший выбор при работе с precompiled C-библиотеками
3. **uv** и **poetry2nix** — перспективные современные альтернативы классическим менеджерам
4. Все способы позволяют работать как в локальной среде (`nix-shell`), так и на системном уровне (`environment.systemPackages`)

## Связи
* [Python Development Environments on NixOS](concepts/python-nixos-development.md) — исходная концепция
* [NixOS Wiki - Home Manager](/wiki/Home_Manager) — FHS-обёртка для pixi через Home Manager
* [Nixpkgs Manual - Contributing Guidelines](https://nixos.org/nixpkgs/manual/#contributing-guidelines)

## Обновлено 2025-06-24 — синтез по запросу пользователя