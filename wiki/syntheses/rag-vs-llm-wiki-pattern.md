---
tags: [synthesis, rag, llm, knowledge-base, comparison]
date: 2026-06-24
sources: [raw/llm-wiki.md]
related: []
---

# Сравнение: RAG vs LLM Wiki Pattern (Compounding Knowledge Base)

## Контекст
Стандартный RAG и большинство систем работы с файлами (NotebookLM, ChatGPT file uploads) работают одинаково: пользователь загружает документы → LLM извлекает relevant chunks на каждый запрос → генерирует ответ. Это работает, но **LLM rediscovering knowledge from scratch on every question**.

## Анализ

### RAG / NotebookLM подход
* Извлечение фрагментов из raw documents в момент query
* Нет накопления знаний — каждый вопрос начинается с нуля
* Сложные вопросы требуют поиска и сборки фрагментов 5+ документов каждый раз
* Nothing is built up over time

### LLM Wiki Pattern подход
* **Incrementally builds and maintains a persistent wiki** — структурированная коллекция markdown-файлов между пользователем и raw источниками
* Знания компилируются один раз и *поддерживаются актуальными*, не пересчитываются при каждом query
* Cross-references уже есть, contradictions already flagged, synthesis отражает все прочитанные источники
* Wiki **compounds** с каждым новым источником или вопросом

## Выводы

| Параметр | RAG / NotebookLM | LLM Wiki Pattern |
|----------|------------------|------------------|
| **Knowledge accumulation** | ❌ Нет (rediscover on every query) | ✅ Да (persistent, compounding) |
| **Cross-references** | ❌ Автоматические из текста | ✅ Явные ссылки между страницами (уже есть в wiki) |
| **Contradiction detection** | ❌ Нет | ✅ При каждом ingest — flagging conflicts |
| **Maintenance burden** | Низкий (автоматический) | Высокий для человека, near-zero для LLM |
| **Сложные вопросы** | Требуют 5+ документов каждый раз | Wiki уже синтезировала ответы ранее |

## Связи:
* [LLM Wiki Pattern Concept](concepts/llm-wiki-pattern.md) — compounding knowledge base approach
* [Entity: Andrej Karpathy](entities/andrej-karpathy.md) — автор LLM Wiki Pattern

