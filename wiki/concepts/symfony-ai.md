---
tags: [llm-integration, symfony-ai, rag-patterns, embedding-vector]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Symfony AI Component


This page explores Symfony AI Component as a key concept in our knowledge base.


## Definition

Symfony AI — set of components integrating LLM capabilities into PHP applications. Unified interface for OpenAI, Anthropic, Google Gemini, Azure providers. Adopted by Symfony Core in mid-2025; shipped with ~35 model bridges and 24 vector store integrations as of June 2026.

## Components Architecture

### Platform Component
Unified `invoke()` API across AI providers — abstracts away provider-specific details:
- **Providers**: OpenAI, Anthropic (Claude), Google Gemini, Azure OpenAI
- **35+ model bridges** for different LLM models across all providers
- Single interface to switch providers without changing application code

### Agent Component
Framework for building AI agents on top of Platform + Store:
- Agents interact with users and perform tasks via tool calling
- Built-in support for function calling from LLMs
- Tool services registered → LLM can invoke them during conversations
- Workflow management for multi-step agent operations

### Store Component
Vector database abstraction for RAG (Retrieval-Augmented Generation):
```php
// Store interface — abstract vector DB operations
interface VectorStoreInterface {
    public function add(Document $document, array $metadata = []): void;
    public function search(string $query, int $limit = 10): array;
    public function delete(array $ids): void;
}
```

### Supported Vector Stores (24+)
| Category | Backends |
|----------|----------|
| **Cloud** | Pinecone, ChromaDB, Cloudflare R2 |
| **Database** | PostgreSQL/PGVector, MySQL/MariaDB, MongoDB, SQLite/SurrealDB |
| **Search** | Elasticsearch, OpenSearch, Meilisearch, Qdrant, Milvus, Neo4j |
| **Others** | Redis (via cache adapter), ClickHouse |

## RAG Implementation Pattern

```
1. Documents → Platform (embeddings via AI provider)
2. Embeddings → Store (vector DB storage)  
3. User query → Store.search() → similar documents retrieved
4. Retrieved docs + user query → Platform.invoke(LLM) → generated response
```

## Integration with Symfony Framework
- Configure agents, platforms, stores via YAML configuration files
- Services auto-wired through DI container like any other service
- Bundle provides seamless integration: `symfony/ai-bundle` for framework users

## Best Practices

1. **Platform abstraction** — never hardcode provider-specific API calls; use unified invoke() interface
2. **Store component for RAG** — don't write raw vector DB queries directly; use Store's abstraction layer
3. **Tool calling pattern** — register tools as Symfony services → LLM agents can call them naturally
4. **Cache embeddings** — store computed vectors in application cache to avoid re-embedding on repeat queries

## Связи
- [Symfony Entity](entities/symfony.md) — AI component is part of modern Symfony 7+ ecosystem
- [Service Container](concepts/service-container.md) — AI services registered and autowired through standard DI container
- [Hexagonal Architecture](concepts/hexagonal-architecture.md) — AI providers/DBs are Infrastructure layer adapters; Agent logic belongs in Application layer
