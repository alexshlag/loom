---
tags: [research, ingest, algorithm, comparison, optimization]
date: 2026-07-03
type: documentation
category: synthesis
sources: ["raw/sources/pi-github-repos/zosmaai/pi-llm-wiki/extensions/llm-wiki/lib/ingest-worker.ts", "raw/sources/pi-github-repos/AgriciDaniel/claude-obsidian/agents/wiki-ingest.md", "raw/sources/pi-github-repos/AgriciDaniel/claude-obsidian/skills/wiki-ingest/SKILL.md", "process-ingest.json"]
related: ["wiki/concepts/delta-tracking.md", "wiki/research/architecture-comparisons.md"]
---

# Сравление алгоритмов Ingest: Loomana vs pi-llm-wiki vs claude-obsidian

## Определение

Сравнительный анализ трёх проектов с LLM-powered wiki для выявления лучших практик в алгоритме ingestion. Исследование фокусируется на **надежности, масштабируемости и предотвращении ошибок** при ингесте источников.

---

## Контекст исследования

| Проект | Репозиторий | Stars | Основная парадигма |
|--------|-------------|-------|---------------------|
| **Loomana (loom)** | `local_wiki/loom` | — | JSON-процессы, delta-tracking, auto-crosslink scoring |
| **pi-llm-wiki** | `zosmaai/pi-llm-wiki` | ~130 | TypeScript extension, background synthesis, structured schemas |
| **claude-obsidian** | `AgriciDaniel/claude-obsidian` | — | Agent skills, per-file locking, mode-aware routing, address assignment |

---

## 1. Background Synthesis & Deterministic Commit (pi-llm-wiki)

### Механизм

Вместо того чтобы LLM писала файлы напрямую, sub-agent produces **ONE structured tool call** (`commit_synthesis`), а persistence layer делает полностью детерминированные file writes без LLM involvement.

```typescript
// extensions/llm-wiki/lib/ingest-worker.ts
export async function runIngestSynthesis(args: RunIngestSynthesisArgs): Promise<CommitResult> {
  const content = extracted.slice(0, maxChars ?? 24_000);
  // Runs in a sub-agent (non-blocking)
  await runSubAgent({
    model, apiKey, headers,
    systemPrompt: INGEST_SYSTEM,
    userPrompt: `Synthesize... EXTRACTED CONTENT:\n${content}`,
    tools: [commitTool],
    signal,
  });
  // Deterministic persistence (no LLM needed for file writes)
  if (committed) rebuildMetadataLight(paths);
  return committed;
}
```

### Структурированная схема (typed output)

```typescript
export const CommitSynthesisSchema = Type.Object({
  summary: Type.String({ minLength: 1, description: "2-3 paragraph summary of the source's key content." }),
  key_takeaways: Type.Array(Type.String({ minLength: 1 }), { description: "The most important points, one per item." }),
  entities: Type.Array(
    Type.Object({
      title: Type.String({ minLength: 1 }),
      description: Type.String({ description: "One-line description of the entity." }),
    }),
    { description: "Named entities mentioned in the source." },
  ),
  concepts: Type.Array(
    Type.Object({
      title: Type.String({ minLength: 1 }),
      definition: Type.String({ description: "One-line definition of the concept." }),
    }),
    { description: "Concepts discussed in the source." },
  ),
  quotes: Type.Optional(
    Type.Array(
      Type.Object({ text: Type.String({ minLength: 1 }), attribution: Type.Optional(Type.String()) }),
      { description: "Notable verbatim quotes." },
    ),
  ),
  contradictions: Type.Optional(
    Type.Array(Type.String({ minLength: 1 }), {
      description: "Tensions/contradictions with existing wiki content, if any.",
    }),
  ),
});
```

### Детерминированное persistence (без LLM)

```typescript
export function commitSynthesis(
  paths: VaultPaths,
  sourceId: string,
  manifest: Record<string, unknown>,
  data: SynthesisData,
): CommitResult {
  // Source page rewrite (skeleton → ingested)
  mkdirSync(join(paths.wiki, "sources"), { recursive: true });
  writeFileSync(result.sourcePage, buildIngestedSourcePage(manifest, data, date));

  // Entity pages — create if absent, link if present
  for (const e of data.entities) {
    const pagePath = join(paths.wiki, "entities", `${slug}.md`);
    if (existsSync(pagePath)) {
      result.entitiesLinked.push(slug);  // Skip existing, don't overwrite!
    } else {
      writeFileSync(pagePath, buildEntityPage(e.title, e.description, date, sourceId));
      result.entitiesCreated.push(slug);
    }
  }
}
```

### Ключевые особенности

1. **Non-blocking ingest** — capture never stalls user while pages are written
2. **Structured CommitSynthesisSchema** — typed output ensures consistency (TypeBox schema validation)
3. **Deterministic persistence** — `commitSynthesis()` writes files WITHOUT LLM involvement after the sub-agent produces structured output
4. **Idempotent create-or-link** — `existsSync()` → link if present, create if absent; safe re-ingest

### Преимущества для Loomana

- ✅ **Снижение риска галлюцинаций**: LLM только структурирует → deterministic write не зависит от stochastic LLM decisions
- ✅ **Неблокирующий workflow**: user может продолжать работу пока ingest идет в фоне
- ✅ **Testability**: file-writing logic unit-testable без LLM — можно тестировать отдельно от LLM calls
- ✅ **Idempotency**: re-ingest same source → same pages, safe to run multiple times

### Реализация для Loomana

Создать `scripts/ingest-worker.sh` как orchestration layer:
```bash
#!/bin/bash
# Parallel extraction + deterministic commit pattern:

# 1. Extract content (parallel, background)
python3 scripts/extract-content.py "$SOURCE" > /tmp/extracted.md &

# 2. Run synthesis sub-agent (background task via process-ingest.json)
python3 scripts/synthesis-subagent.py --input /tmp/extracted.md \
    --schema CommitSynthesisSchema.json \
    --tool commit_synthesis \
    --output /tmp/synthesis-output.json &

# 3. Deterministic file writes (no LLM, pure I/O)
python3 scripts/deterministic-commit.py --input /tmp/synthesis-output.json \
    --schema CommitSynthesisSchema.json --vault wiki/ &
```

**Приоритет:** High — это фундаментальное улучшение reliability + UX.

---

## Детали реализации Background Synthesis

### Почему это важно для Loomana

| Проблема | Текущее решение | Background synthesis |
|----------|-----------------|---------------------|
| User stalled during ingest | Block user until pages written | Capture never stalls — background sub-agent runs |
| LLM hallucination in file writes | Direct LLM calls to write files | Structured tool → deterministic commit (no LLM involvement) |
| Hard to test/write logic | Mixed stochastic LLM + I/O | Pure I/O layer, fully unit-testable |

### Архитектура компонентов

```
sources/  
├── extract-content.sh       # Parallel extraction from raw/
├── synthesis-subagent.py    # Background sub-agent with structured output
└── deterministic-commit.py  # Pure I/O persistence layer (no LLM)
```

### Flow diagram

```bash
# Step 1: User triggers ingest
user → scripts/ingest-worker.sh --source "path/to/file.md"

# Step 2: Background sub-agent runs synthesis
python3 scripts/synthesis-subagent.py \
    --input /tmp/extracted.md \
    --system-prompt INGEST_SYSTEM \
    --tool commit_synthesis \
    --output /tmp/synthesis-output.json &

# Step 3: Deterministic persistence (pure I/O)
python3 scripts/deterministic-commit.py \
    --input /tmp/synthesis-output.json \
    --schema CommitSynthesisSchema.json \
    --vault wiki/
```

### Schema validation before file writes

```json
{
  "schema": {
    "summary": {"type": "string", "minLength": 1},
    "key_takeaways": {"type": "array", "items": {"type": "string", "minLength": 1}},
    "entities": {"type": "array", "items": {
      "title": {"type": "string", "minLength": 1},
      "description": {"type": "string"}
    }},
    "concepts": {"type": "array", "items": {
      "title": {"type": "string", "minLength": 1},
      "definition": {"type": "string"}
    }}
  }
}
```

### Пример использования в Loomana

```bash
# После ingest: background synthesis triggers automatically
./scripts/ingest-worker.sh --source wiki/raw/SRC-001/doc.md \
    --background --schema CommitSynthesisSchema.json

# Sub-agent runs in background, produces structured output:
# /tmp/synthesis-output.json → deterministic-commit.py → wiki/entities/, wiki/concepts/
```

### Сравнение с текущим подходом Loomana

| Feature | Текущий (process-ingest.json) | Background synthesis |
|---------|-------------------------------|---------------------|
| Synchronous ingest | Yes — user waits for page writes | No — capture never stalls |
| LLM involvement in writes | Direct LLM calls to write files | Structured tool → deterministic commit |
| Idempotency | Manual check via delta tracking | Built-in existsSync() + link-if-present |
| Testability | Mixed stochastic LLM + I/O | Pure I/O layer, fully unit-testable |

---

## 2. Per-File Advisory Locking (claude-obsidian)

### Механизм

`scripts/wiki-lock.sh` — flock-based advisory locks per-file:

```bash
# Acquire — blocks if another writer holds the lock
if bash scripts/wiki-lock.sh acquire wiki/concepts/Foo.md; then
  # ... write page ...
  bash scripts/wiki-lock.sh release wiki/concepts/Foo.md
else
  sleep 2
  bash scripts/wiki-lock.sh acquire wiki/concepts/Foo.md && {
    # write …
    bash scripts/wiki-lock.sh release wiki/concepts/Foo.md
  } || echo "skipped (locked)"
fi
```

### Ключевые особенности

1. **Per-file granularity** — locks key on `sha1(<vault-relative-path>)` → concurrent writes to DIFFERENT pages run in parallel
2. **Age-based staleness** — default `STALE_AFTER_SEC=60`, crashed holder unblocks automatically
3. **Cross-process release** — simple `rm -f`, no PID matching required
4. **PostToolUse hook defers git add** if any locks held

### Преимущества для Loomana

- ✅ **Prevents silent corruption**: two parallel sub-agents writing same page can't trample each other
- ✅ **Parallel-safe ingest**: batch processing becomes safe without race conditions
- ✅ **Automatic recovery**: stale locks expire after 60s, no manual intervention needed

### Сравнение с текущей реализацией Loomana

| Feature | Loomana (текущий) | claude-obsidian |
|---------|-------------------|------------------|
| Concurrency control | None (single-writer only) | Advisory locks per-file |
| Race condition protection | Manual via process-lint.json | Automatic via wiki-lock.sh |
| Parallel sub-agents | Not supported (unsafe) | Supported safely |

### Реализация для Loomana

**Рекомендация:** Создать `scripts/wiki-lock.sh` как flock-based advisory lock script:
```bash
#!/bin/bash
# Usage: scripts/wiki-lock.sh acquire|release|clear-stale <path>
# Keys on sha1(<vault-relative-path>) for per-file granularity
STALE_AFTER_SEC=60
LOCK_DIR="wiki/meta/.locks"
```

**Приоритет:** Critical — это prevents most ingest errors from parallel processing.

---

## 3. Mode-Aware Path Routing (claude-obsidian)

### Механизм

`scripts/wiki-mode.py route <type> "<name>"` returns vault-relative path based on methodology mode:

```bash
SRC_PATH=$(python3 scripts/wiki-mode.py route source "Karpathy LLM Wiki")
# generic:      wiki/sources/Karpathy-LLM-Wiki.md
# lyt:          wiki/notes/Karpathy-LLM-Wiki.md (also update MOC)
# para:         wiki/resources/incoming/Karpathy-LLM-Wiki.md
# zettelkasten: wiki/20260517123456-Karpathy-LLM-Wiki.md

ENT_PATH=$(python3 scripts/wiki-mode.py route entity "Andrej Karpathy")
CON_PATH=$(python3 scripts/wiki-mode.py route concept "Compounding Vault Pattern")
```

### Ключевые особенности

1. **Dynamic path resolution** — same ingest, different folders based on vault mode
2. **Mode-specific follow-ups**:
   - **LYT**: update MOC after filing atomic note
   - **Zettelkasten**: filename includes timestamp ID
   - **PARA**: new ingests land in `wiki/resources/incoming/` by default

### Преимущества для Loomana

- ✅ **Future-proof architecture**: если пользователь захочет PARA/LYT/Zettelkasten, ingest автоматически адаптируется
- ✅ **Consistent routing** — orchestrator и sub-agents используют один и тот же router
- ✅ **Safe name sanitization** — path-traversal + control-char strip in `safe_name()`

### Сравнение с текущей реализацией Loomana

| Feature | Loomana (текущий) | claude-obsidian |
|---------|-------------------|------------------|
| Path assignment | Static directories (`entities/`, `concepts/`) | Dynamic via mode-aware router |
| Methodology support | Not implemented | LYT/PARA/Zettelkasten/Generic |
| Batch routing | Same path for all types | Mode-specific paths per type |

### Реализация для Loomana

**Рекомендация:** Создать `scripts/wiki-mode.py` (или `wiki-mode.sh`) для future-proofing:
```python
def route(type: str, name: str) -> Path:
    mode = read_vault_meta_mode()  # default = "generic"
    if type == "entity": return wiki/entities/{slug}.md
    elif type == "concept": return wiki/concepts/{slug}.md
    # ... mode-specific overrides for future modes
```

**Приоритет:** Low-Medium — не critical сейчас, но важно для долгосрочной архитектуры.

---

## 4. Address Assignment System (claude-obsidian)

### Механизм

Каждая новая страница получает stable address в frontmatter:

```yaml
address: c-000042
```

Формат: `c-<6-digit-counter>`. Allocation atomic via `flock` on `.vault-meta/.address.lock`:

```bash
ADDR=$(./scripts/allocate-address.sh)  # atomically reserves next address
# ADDR = "c-000042"; counter already incremented
```

### Ключевые особенности

1. **Idempotency rules** — if page already has `address:`, REUSE it (never allocate new one)
2. **Address map tracking** — `.raw/.manifest.json` stores path→address mappings for reuse on re-ingest
3. **Single-writer only** for allocator (flock-guarded), but pages can be parallel-safe via wiki-lock.sh
4. **Exclusions** — meta files, folds, legacy pages don't get addresses

### Преимущества для Loomana

- ✅ **Page renaming safe** — address stays stable across renames
- ✅ **Re-ingest idempotent** — same source → same page path → same address
- ✅ **Deterministic navigation** — addresses can be used for cross-references that survive renames

### Сравнение с текущей реализацией Loomana

| Feature | Loomana (текущий) | claude-obsidian |
|---------|-------------------|------------------|
| Stable identifiers | None | Address system with counter + map |
| Page rename handling | Broken links | Address reuse via address_map |
| Re-ingest idempotency | Hash-based delta tracking | Address reuse + hash tracking |

### Реализация для Loomana

**Рекомендация:** Интегрировать в текущий delta-tracking:
```json
// .raw/.manifest.json
{
  "sources": {
    ".raw/articles/article-slug.md": {
      "hash": "abc123",
      "ingested_at": "2026-04-08",
      "pages_created": ["wiki/entities/Person.md"],
      "address_map": {
        "wiki/entities/Person.md": "c-000042"
      }
    }
  }
}
```

**Приоритет:** Medium — useful for long-term maintainability, not critical for ingest reliability.

---

## 5. Contradiction Handling (claude-obsidian)

### Механизм

Explicit contradiction callouts on BOTH pages:

```markdown
> [!contradiction] Conflict with [[New Source]]
> [[Existing Page]] claims X. [[New Source]] says Y.
> Needs resolution. Check dates, context, and primary sources.

> [!contradiction] Contradicts [[Existing Page]]
> This source says Y, but existing wiki says X. See [[Existing Page]].
```

### Ключевые особенности

1. **Bidirectional flagging** — both old AND new pages reference each other
2. **No silent overwrites** — explicit `[!contradiction]` callouts force user review
3. **Custom CSS styling** — reddish-brown alert-triangle icon for visual prominence

### Преимущества для Loomana

- ✅ **Prevents data loss** — contradictions explicitly visible, not buried in updates
- ✅ **User awareness** — contradictions are impossible to miss
- ✅ **Traceability** — bidirectional links between conflicting sources

### Сравнение с текущей реализацией Loomana

| Feature | Loomana (текущий) | claude-obsidian |
|---------|-------------------|------------------|
| Contradiction detection | detect-contradications.sh (post-lint only) | Real-time during ingest |
| Visibility | Log entries, manual review | Explicit `[!contradiction]` callouts on pages |
| User notification | Silent | Automatic with bidirectional references |

### Реализация для Loomana

**Рекомендация:** Добавить в `process-ingest.json#step_3_analysis`:
```json
{
  "action": "check_for_contradications",
  "output_format": "> [!contradiction] Conflict with [[<source>]]\n- <existing claim>\n- <new claim>\n- Needs resolution"
}
```

**Приоритет:** High — это prevents silent overwrites and data corruption.

---

## 6. Source Layer Classification (Loomana) + Reality Cascade

### Текущая реализация Loomana

```json
{
  "source_layer_classification": {
    "options": ["code_reality", "live_state", "documentation"],
    "rules": [
      {"condition": "file_is_code_or_github_issue", "result": "code_reality"},
      {"condition": "file_is_api_response_or_metrics", "result": "live_state"},
      {"condition": "file_is_documentation_article", "result": "documentation"}
    ]
  }
}
```

### Ключевые особенности

1. **Auto-classify source layer** — agent determines type automatically during ingest
2. **Cascade priority for contradictions** — `code_reality(1) > live_state(2) > documentation(3)`
3. **Evidence grade auto-compute** — documented/corroborated/assertion_only per fact

### Преимущества

- ✅ **Automated source trust evaluation** — no manual configuration needed
- ✅ **Structured contradiction resolution** — cascade priority works without user intervention
- ✅ **Fact-level grading** — granular evidence tracking, not just page-level

### Сравнение с другими проектами

| Feature | Loomana | pi-llm-wiki | claude-obsidian |
|---------|---------|-------------|------------------|
| Source classification | Auto-detect with cascade priority | Manual (user provides) | None explicit |
| Evidence grading | Yes (documented/corroborated/assertion_only) | No | No |
| Contradiction cascade | Automated based on source type | User-driven | Explicit callouts only |

### Реализация для Loomana

**Рекомендация:** Улучшить auto-classification с better heuristics:
```json
{
  "action": "classify_source_layer",
  "heuristic_rules": [
    {"pattern": "contains code blocks AND github URL", "layer": "code_reality"},
    {"pattern": "timestamp <1h ago AND contains metrics/logs", "layer": "live_state"},
    {"default": "documentation"}
  ]
}
```

**Приоритет:** Medium — Loomana already has this, but can improve detection accuracy.

---

## 7. Binary Magic Byte Detection (pi-llm-wiki)

### Механизм

```typescript
const BINARY_SIGNATURES = [
  { bytes: [0x50, 0x4b, 0x03, 0x04], format: "zip" }, // ZIP / DOCX
  { bytes: [0x25, 0x50, 0x44, 0x46], format: "pdf" }, // PDF
  // ... 15+ binary signatures
];

export async function detectBinaryMagicBytes(filePath): Promise<string | null> {
  const handle = await open(filePath);
  const buffer = Buffer.alloc(8);
  await handle.read(buffer, 0, 8);
  for (const sig of BINARY_SIGNATURES) {
    if (buffer.slice(0, sig.bytes.length).equals(Buffer.from(sig.bytes))) {
      return sig.format;
    }
  }
  return null; // text format detected
}
```

### Ключевые особенности

1. **8-byte magic byte detection** — fast binary vs text classification without reading full file
2. **Comprehensive signatures** — covers PDF, DOCX, XLSX, PPTX, PNG, JPEG, TIFF, ELF, Mach-O, SQLite, etc.
3. **Format-aware extraction routing** — detected format → appropriate extractor (MarkItDown for documents, custom for images)

### Преимущества для Loomana

- ✅ **Fast classification** — no need to read entire file before knowing its type
- ✅ **Robust format detection** — magic bytes > extension-based detection (avoids misclassification)
- ✅ **Comprehensive coverage** — 15+ binary formats handled automatically

### Сравнение с текущей реализацией Loomana

| Feature | Loomana (текущий) | pi-llm-wiki | claude-obsidian |
|---------|-------------------|-------------|------------------|
| Binary detection | Extension-based (PDF, md, etc.) | Magic byte signatures | Extension + fallback |
| Auto-extraction routing | Manual selection | Automatic based on detected format | Manual/defuddle optional |

### Реализация для Loomana

**Рекомендация:** Создать `scripts/detect-binary-type.sh` с magic byte detection:
```bash
#!/bin/bash
# Usage: scripts/detect-binary-type.sh <file>
# Returns: pdf, docx, png, jpeg, text, etc. based on magic bytes
head -c8 "$1" | xxd -i | grep -q "0xff 0xd8 0xff" && echo "jpeg"
```

**Приоритет:** Low-Medium — useful for robustness, but not critical for current ingest workflow.

---

## Итоговая матрица улучшений для Loomana

| Улучшение | Источник | Приоритет | Сложность | Влияние на reliability |
|-----------|----------|-----------|-----------|------------------------|
| **Advisory locking (wiki-lock.sh)** | claude-obsidian | 🔴 Critical | Medium | Prevents silent corruption from parallel writes |
| **Background synthesis** | pi-llm-wiki | 🟠 High | Medium | Non-blocking ingest, better UX |
| **Structured CommitSynthesisSchema** | pi-llm-wiki | 🟠 High | Low | Deterministic output format |
| **Real-time contradiction flagging** | claude-obsidian | 🟡 High | Low | Prevents silent overwrites |
| **Mode-aware routing** | claude-obsidian | 🟢 Medium | Low | Future-proof for PARA/LYT/Zettelkasten |
| **Address assignment system** | claude-obsidian | 🟢 Low-Medium | Medium | Stable identifiers across renames |
| **Magic byte detection** | pi-llm-wiki | 🟢 Low | Low | Robust format classification |

---

## Рекомендации по внедрению (в порядке приоритета)

### Phase 1: Critical fixes (immediate)

1. ✅ Создать `scripts/wiki-lock.sh` — flock-based advisory locks per-file
2. ✅ Добавить real-time contradiction callouts в `process-ingest.json#step_3_analysis`
   ```json
   {
     "action": "check_for_contradications",
     "output_format": "> [!contradiction] Conflict with [[<source>]]"
   }
   ```

### Phase 2: High-impact improvements (next sprint)

1. ✅ Background synthesis via `scripts/ingest-worker.sh` — parallel extract + deterministic commit
2. ✅ Structured schema for synthesis output (JSON schema validation before file writes)

### Phase 3: Future-proofing (backlog)

1. Mode-aware routing (`wiki-mode.py`)
2. Address assignment system integration with delta-tracking
3. Magic byte detection for binary files

---

## Ключевые выводы

1. **claude-obsidian wins on concurrency safety** — advisory locking prevents most ingest errors from parallel processing
2. **pi-llm-wiki wins on deterministic output** — structured schemas + background synthesis = testable, reliable file writes
3. **Loomana already leads in source classification** — auto-detect + evidence grading is ahead of both competitors
4. **Hybrid approach recommended** — combine claude-obsidian locking + pi-llm-wiki deterministic synthesis for maximum reliability

---

## References

- `process-ingest.json` — текущий ingest algorithm Loomana
- `/tmp/pi-github-repos/zosmaai/pi-llm-wiki/extensions/llm-wiki/lib/ingest-worker.ts` — background synthesis implementation
- `/tmp/pi-github-repos/AgriciDaniel/claude-obsidian/skills/wiki-ingest/SKILL.md` — concurrency + routing rules
- `/tmp/pi-github-repos/AgriciDaniel/claude-obsidian/agents/wiki-ingest.md` — parallel sub-agent instructions

---

*Generated by research analysis on 2026-07-03. This page will be updated as implementations progress.*
