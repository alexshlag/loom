#!/usr/bin/env bash
# check-new-sources.sh — проверяет raw/sources на новые пакеты, которых нет в meta/raw_registry.json
# Usage: ./scripts/check-new-sources.sh [raw_dir] [registry_file]
# Exit code: 0 = no new sources, 1 = new sources found (printed to stdout)

RAW_DIR="${1:-raw/sources/}"
REGISTRY_FILE="${2:-tracking/raw_registry.json}"

# Создаём registry, если не существует
if [ ! -f "$REGISTRY_FILE" ]; then
    mkdir -p "$(dirname "$REGISTRY_FILE")"
    echo '{"ingested_sources": []}' > "$REGISTRY_FILE"
fi

# Получаем список всех пакетов в raw/sources/
packages=$(ls -1d "$RAW_DIR"/SRC-* 2>/dev/null || true)

if [ -z "$packages" ]; then
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
    # Извлекаем ID (папку пакета)
    pkg_id=$(basename "$pkg")
    
    # Проверяем, есть ли в registry
    if ! echo "$ingested_ids" | grep -q "^${pkg_id}$"; then
        echo "NEW: $pkg_id"
        found_new=true
    fi
done <<< "$packages"

if [ "$found_new" = true ]; then
    exit 1
else
    exit 0
fi
