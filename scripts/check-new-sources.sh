#!/usr/bin/env bash
# check-new-sources.sh — проверяет raw/sources на новые пакеты, которых нет в tracking/raw_registry.json
# Usage: ./scripts/check-new-sources.sh [--quick] [raw_dir] [registry_file]
# Exit code: 0 = no new sources, 1 = new sources found (printed to stdout), 2 = cached_skip (--quick only)
#
# Modes:
#   default — полный режим: выводит NEW: <package_id> для каждого нового пакета
#   --quick — быстрый режим: только exit_code, без вывода пакетов. Кэширует timestamp (~1h).

QUICK=false
if [[ "$1" == "--quick" ]]; then
    QUICK=true
    shift
fi
RAW_DIR="${1:-raw/sources/}"
REGISTRY_FILE="${2:-tracking/raw_registry.json}"
CACHE_FILE="tracking/last_check.json"

# Создаём registry, если не существует
mkdir -p "$(dirname "$REGISTRY_FILE")"
if [ ! -f "$REGISTRY_FILE" ]; then
    echo '{"ingested_sources": []}' > "$REGISTRY_FILE"
fi

# --- Quick mode: cache check (skip if checked <1h ago) ---
if [ "$QUICK" = true ] && [ -f "$CACHE_FILE" ]; then
    last_check=$(python3 -c "import json; print(json.load(open('$CACHE_FILE')).get('last_check', 0))")
    now=$(date +%s)
    if [ $((now - last_check)) -lt 3600 ]; then
        exit 2
    fi
fi

# --- Scan for new sources ---
packages=$(ls -1d "$RAW_DIR"/SRC-* 2>/dev/null || true)

if [ -z "$packages" ]; then
    if [ "$QUICK" = true ]; then
        # Обновляем кэш, чтобы не стучать каждый раз
        echo "{\"last_check\": $(date +%s)}" > "$CACHE_FILE"
    fi
    exit 0
fi

# Считаем уже обработанные ID из registry
ingested_ids=$(python3 -c "
import json, sys
with open('$REGISTRY_FILE') as f:
    data = json.load(f)
sources = set(data.get('ingested_sources', []))
for s in sources:
    print(s)
")

# Сравниваем
found_new=false
while IFS= read -r pkg; do
    pkg_id=$(basename "$pkg")
    
    if ! echo "$ingested_ids" | grep -q "^${pkg_id}$"; then
        if [ "$QUICK" != true ]; then
            echo "NEW: $pkg_id"
        fi
        found_new=true
    fi
done <<< "$packages"

if [ "$found_new" = true ]; then
    if [ "$QUICK" = true ]; then
        # Обновляем кэш, чтобы не стучать каждый раз
        echo "{\"last_check\": $(date +%s)}" > "$CACHE_FILE"
    fi
    exit 1
else
    if [ "$QUICK" = true ]; then
        # Обновляем кэш — новых нет, нет смысла проверять снова
        echo "{\"last_check\": $(date +%s)}" > "$CACHE_FILE"
    fi
    exit 0
fi
