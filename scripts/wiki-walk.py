#!/usr/bin/env python3
"""wiki-walk.py — Single-pass wiki file index and metadata collector.

Architecture: orchestrator for all scripts that need to scan the wiki directory.
- One os.walk() call, one disk I/O pass
- Output structured JSON with page data consumed by consumers (registry, backlinks, similarity)
- Eliminates triple-walk in rebuild-meta.sh (+30% latency saved)
"""

import json
import os
import re
import sys

# ─── Constants ──────────────────────────────────────────────────────────────
WIKI_DIR = os.environ.get("WIKI_DIR", "wiki")
META_DIR = os.environ.get("META_DIR", "meta")
SYSTEM_FILES_EXCLUDED = {
    'log.md', 'issues.md', 'timeline.md', 'overview.md',
    'snapshot.md', 'index.md', 'GIT-TROUBLESHOOTING.md', 'hot.md'
}

# ─── Data Extraction Utilities ──────────────────────────────────────────────

def parse_frontmatter(content):
    """Extract frontmatter fields from markdown content."""
    tags, date_str, sources_list = [], '', []
    aliases_list = []

    for line in content.split('\n')[:10]:
        if line.startswith('tags:'):
            raw_tags = re.findall(r'\[(.*?)\]', line)
            tags = [t.strip() for t in ','.join(raw_tags).split(',') if t.strip()]
        elif line.startswith('date:'):
            date_str = line.split(': ', 1)[1].strip() if ': ' in line else ''
        elif line.startswith('sources:'):
            raw_sources = re.findall(r'\[(.*?)\]', line)
            sources_list = [s.strip().strip('"').strip("'") for s in ','.join(raw_sources).split(',') if s.strip()]
        elif line.startswith('aliases:'):
            raw_aliases = re.findall(r'["\']([^"\']+)["\']', '[{}]'.format(','.join(raw_tags)) if raw_tags else '')
            aliases_list = [a.strip() for a in raw_aliases]

    return {
        'tags': tags,
        'date': date_str,
        'sources': sources_list,
        'aliases': aliases_list
    }


def extract_summary(content, max_len=180):
    """Extract first paragraph summary from markdown content."""
    lines = content.split('\n')

    # Find frontmatter end
    fm_end = 0
    dashes_count = 0
    for i, line in enumerate(lines):
        if line.strip() == '---':
            dashes_count += 1
            if dashes_count == 2:
                fm_end = i + 1
                break

    # Collect non-empty, non-heading lines until first H2 or max_len chars
    summary_parts = []
    for i in range(fm_end, len(lines)):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith('# '):
            continue
        if stripped.startswith('## '):
            break
        # Skip pure markdown formatting lines
        if re.match(r'^\*{1,4}\w+\*{1,4}$', stripped):
            continue
        summary_parts.append(stripped)

    full_text = ' '.join(summary_parts[:6])
    if len(full_text) <= max_len:
        return full_text
    snippet = full_text[:max_len]
    # Smart truncation at sentence boundary or bracket
    last_dot = max(snippet.rfind('.'), snippet.rfind('!'), snippet.rfind('?'))
    if last_dot > 30:
        return snippet[:last_dot + 1].strip()
    for ch in [')', ']', ',', ';']:
        idx = snippet.rfind(ch)
        if idx > 25:
            return snippet[:idx + 1].strip()
    return snippet[:max_len - 3] + '...'


def extract_links(content):
    """Extract [[text](path)] links and related field from frontmatter."""
    links = re.findall(r'\[([^\]]+)\]\(([^#)]+)(?:#[^)]+)?\)', content)

    # Extract related: [] field
    related = []
    for line in content.split('\n')[:20]:
        if line.strip().startswith('related:'):
            raw = re.findall(r'\[(.*)\]', line)
            if raw:
                related = [p.strip().strip('"').strip("'") for p in raw[0].split(',') if p.strip()]

    return links, related


def categorize_path(rel_path):
    """Determine wiki category from relative path."""
    parts = rel_path.split('/')
    categories = {
        'entities': 'entities',
        'concepts': 'concepts',
        'comparisons': 'comparisons',
        'syntheses': 'syntheses',
        'notes': 'notes',
        'projects': 'projects',
        'bibliography': 'bibliography',
        'resources': 'resources',
    }

    # Check directory segments
    for part in parts:
        if part in categories.values():
            return part

    # Root-level files (e.g., overview.md, snapshot.md)
    if len(parts) <= 1 and not parts[0].startswith('.'):
        basename = os.path.basename(rel_path).replace('.md', '').lower()
        if basename in ('overview', 'snapshot'):
            return 'overviews'
        elif basename == 'timeline':
            return 'timeline'

    return None


# ─── Single Walk — Collect All Data ──────────────────────────────────────────

def walk_wiki():
    """Single os.walk() pass over wiki/ returning structured data."""
    pages_data = []
    all_backlinks = {}  # target_id -> list of backlink dicts
    category_pages = {}  # category_key -> list of page dicts for index

    for root, dirs, files in os.walk(WIKI_DIR):
        # Exclude meta/ and raw/ directories (and subdirs)
        if 'meta' in dirs:
            dirs.remove('meta')
        if 'raw' in dirs:
            dirs.remove('raw')

        for fname in sorted(files):
            if not fname.endswith('.md'):
                continue
            if fname in SYSTEM_FILES_EXCLUDED or fname.startswith('.'):
                continue

            fpath = os.path.join(root, fname)
            rel_path = os.path.relpath(fpath, WIKI_DIR).replace('/', '-').replace('.', '-')
            rel_path_slash = os.path.relpath(fpath, WIKI_DIR)

            try:
                with open(fpath, 'r', encoding='utf-8') as f:
                    content = f.read(4096)  # Read enough for frontmatter + summary
            except Exception:
                continue

            title_match = re.search(r'^# (.+)', content, re.MULTILINE)
            title = title_match.group(1).strip() if title_match else fname.replace('.md', '').replace('-', ' ').title()

            # Parse all data in one pass
            fm = parse_frontmatter(content)
            links, related_links = extract_links(content)
            summary = extract_summary(content)
            category = categorize_path(rel_path_slash)

            # Build page entry for registry
            pages_data.append({
                'id': rel_path.replace('wiki/', ''),
                'title': title,
                'path': os.path.relpath(fpath, '.'),
                'rel_path': rel_path_slash,
                'category': category or 'unknown',
                'tags': fm['tags'],
                'date': fm['date'],
                'sources': fm['sources'],
                'aliases': fm['aliases'],
                'links_outgoing': [path.rstrip('/') for _, path in links],
                'summary': summary,
            })

            # Add backlinks for each outgoing link target
            for _, path in links:
                cleaned = path.lstrip('./').lstrip('/') if not path.startswith('../') else path
                target_id = cleaned.replace('/', '-').replace('.', '').rstrip('/')
                if target_id:
                    all_backlinks.setdefault(target_id, []).append({
                        'from': rel_path_slash,
                        'context': f'[text]({path}) in {fname}',
                    })

            # Collect for index.md generation
            if category and category != 'unknown':
                page_entry = {
                    'title': title,
                    'path': rel_path_slash,
                    'summary': summary,
                    'tags': fm['tags'],
                    'aliases': fm['aliases'][:2],
                }
                category_pages.setdefault(category, []).append(page_entry)

    return pages_data, all_backlinks, category_pages


# ─── CLI Output Modes ────────────────────────────────────────────────────────

def output_registry():
    """Output registry.json format."""
    pages_data, _, _ = walk_wiki()
    print(json.dumps({'pages': pages_data}, indent=2, ensure_ascii=False))


def output_backlinks():
    """Output backlinks.json format."""
    _, all_backlinks, _ = walk_wiki()

    # Deduplicate backlinks per target
    final_backlinks = {}
    for target, sources in all_backlinks.items():
        seen = set()
        deduped = []
        for s in sources:
            key = (s.get('from'), s.get('context', ''))
            if not any(k == key for k in seen):
                seen.add(key)
                deduped.append(s)
        final_backlinks[target] = deduped

    print(json.dumps({'backlinks': final_backlinks}, indent=2, ensure_ascii=False))


def output_index():
    """Output index.md content."""
    _, _, category_pages = walk_wiki()

    # Read categories from rules/categories.json
    cat_file = os.path.join(os.environ.get("SCRIPT_DIR", "scripts"), "..", "rules", "categories.json")
    CATEGORY_ORDER = []
    CATEGORIES_LABELS = {}
    try:
        with open(cat_file) as f:
            cat_data = json.load(f)
        CATEGORY_ORDER = [c["key"] for c in cat_data.get("categories", [])]
        lang = os.environ.get('LOCALE', 'en')
        CATEGORIES_LABELS = {}
        for c in cat_data.get("categories", []):
            labels = c.get("label", {})
            CATEGORIES_LABELS[c["key"]] = labels.get(lang, labels.get('en', c['key'].title()))
    except Exception:
        CATEGORY_ORDER = ['entities', 'concepts', 'comparisons', 'syntheses', 'overviews', 'notes', 'meetings', 'projects', 'bibliography', 'resources']
        CATEGORIES_LABELS = {'entities': 'Entities', 'concepts': 'Concepts', 'comparisons': 'Comparisons', 'syntheses': 'Syntheses', 'overviews': 'Overviews', 'notes': 'Notes', 'meetings': 'Meetings', 'projects': 'Projects', 'bibliography': 'Bibliography', 'resources': 'Resources'}

    lines = ['# Wiki Index', '', '']
    for cat_key in CATEGORY_ORDER:
        display_name = CATEGORIES_LABELS.get(cat_key, cat_key.title())
        pages_list = category_pages.get(cat_key, [])
        lines.append('## ' + display_name)
        if not pages_list:
            lines.append('')
        else:
            for page in sorted(pages_list, key=lambda x: x['title']):
                tag_str = ' '.join(f'[{t}]' for t in page.get('tags', [])[:3]) if page.get('tags') else ''
                alias_str = ' '.join(f'[{a}]' for a in page.get('aliases', [])[:2]) if page.get('aliases') else ''
                extra = f' — {tag_str}' + (f' ({alias_str})' if alias_str else '') if tag_str else ''
                lines.append('* [' + page['title'] + '](' + page['path'] + ') — ' + page['summary'] + extra)
        lines.append('')

    print('\n'.join(lines))


def output_json():
    """Output comprehensive JSON with all data (for unified-pass.sh consumption)."""
    pages_data, all_backlinks, category_pages = walk_wiki()

    # Deduplicate backlinks
    final_backlinks = {}
    for target, sources in all_backlinks.items():
        seen = set()
        deduped = []
        for s in sources:
            key = (s.get('from'), s.get('context', ''))
            if not any(k == key for k in seen):
                seen.add(key)
                deduped.append(s)
        final_backlinks[target] = deduped

    result = {
        'pages': pages_data,
        'backlinks': final_backlinks,
        'categories': category_pages,
        'page_count': len(pages_data),
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))


# ─── Main CLI ────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: wiki-walk.py [--registry|--backlinks|--index|--json]", file=sys.stderr)
        sys.exit(1)

    mode = sys.argv[1]
    output_map = {
        '--registry': output_registry,
        '--backlinks': output_backlinks,
        '--index': output_index,
        '--json': output_json,
    }

    if mode in output_map:
        output_map[mode]()
    else:
        print(f"[!] Unknown mode: {mode}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
