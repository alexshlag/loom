#!/usr/bin/env bash
# orphan-pages.sh — находит страницы wiki без входящих ссылок (orphan pages)
# Оптимизация: использует meta/backlinks.json вместо O(n²) grep → O(1) lookup
# Usage: ./scripts/orphan-pages.sh [wiki_dir] [backlinks_json]
# Exit code: 0 = no orphans, 1 = orphans found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"
BACKLINKS_JSON="${2:-$PROJECT_ROOT/meta/backlinks.json}"

# Fallback: если backlinks.json отсутствует — используем grep
if [ ! -f "$BACKLINKS_JSON" ]; then
    echo "[!] Warning: $BACKLINKS_JSON not found, falling back to grep..." >&2
    # Оригинальная O(n²) логика (fallback)
fi

python3 -c "
import json, os, sys

wiki_dir = '${WIKI_DIR}'
backlinks_json_path = '${BACKLINKS_JSON}'

SYSTEM_FILES = {
    'log.md', 'issues.md', 'timeline.md', 'overview.md',
    'snapshot.md', 'index.md', 'hot.md', 'GIT-TROUBLESHOOTING.md',
    'GIT-WORKFLOW.md', 'Home_Manager.md'
}

# Собираем все wiki-страницы (исключая meta/)
all_pages = []
for root, dirs, files in os.walk(wiki_dir):
    if 'meta' in dirs:
        dirs.remove('meta')
    for f in files:
        if f.endswith('.md'):
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, wiki_dir)
            
            basename = os.path.basename(f)
            if basename in SYSTEM_FILES:
                continue
                
            all_pages.append(rel_path)

# Загружаем backlinks.json — извлекаем все target'ы (ключи JSON)
backlink_targets = set()
with open(backlinks_json_path) as f:
    data = json.load(f)
    
if isinstance(data, dict):
    if 'backlinks' in data:
        keys = list(data['backlinks'].keys())
    else:
        keys = list(data.keys())

# Преобразуем ключи JSON обратно в wiki-пути для сравнения
# Формат ключа: entities/page-name-md → нормализуем все к единому виду
normalized_keys = set()
for key in keys:
    # Ключ типа 'wiki/entities/pi-coding-agent.md' или 'entities-pi-coding-agent-md'
    normalized_keys.add(key)

# Находим орфанов — страницы без входящих ссылок (нет ключа в backlinks.json)
orphans = []
for page in all_pages:
    # Создаём ключ из пути: wiki/entities/pi-coding-agent.md → entities-pi-coding-agent-md
    normalized_key = page.replace('/', '-').replace('.', '-')  
    
    if normalized_key not in normalized_keys:
        orphans.append(page)

if len(orphans) > 0:
    print(f'[!] Orphan pages found ({len(orphans)}):')
    for orphan in sorted(orphans):
        print(f'    {orphan} (no backlinks)')
    
    print('\n[*] Suggestion: add crosslink from related entity/concept page')
    sys.exit(1)

print('[✓] No orphan pages found')
sys.exit(0)
" 2>/dev/null
