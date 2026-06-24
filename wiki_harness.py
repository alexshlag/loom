#!/usr/bin/env python3
"""
wiki_harness — минимальный агент для работы с wiki.

Аналог chebupelka, но с расширенным набором инструментов:
  - bash (исполнение команд)
  - read_file (чтение файлов проекта)
  - write_file (запись файлов)
  - find_wiki_pages (поиск по структуре wiki)

Цикл тот же: LLM → tool_calls → execute → result → repeat.
"""

import json, sys, subprocess, os
import requests


# ─── Конфигурация LLM ──────────────────────────────────────────────

LLM_BASE_URL = "http://localhost:1234/v1"  # LM Studio
LLM_API_KEY = "not-needed"  # LM Studio не требует ключа
LLM_MODEL = "qwen3.6-35b-a3b-2.6763bpw.gguf"

LLM_HEADERS = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {LLM_API_KEY}"
}
MAX_TURNS = 100


# ─── System Prompt — специализированный для wiki ─────────────────────

SYSTEM_PROMPT = """\
You are a Wiki Management Agent. Your job is to help users maintain, organize, and query a knowledge base (wiki).

Available tools:
1. `bash` — execute shell commands, read/write files, run scripts.
2. `read_file` — read the full contents of a file. Returns text content.
3. `write_file` — write or overwrite a file with given content at a specified path.
4. `find_wiki_pages` — search for wiki pages by topic or tag. Returns matching paths and titles.

Workflow:
- Use tools to explore the repository, read files, edit structures.
- For ingest tasks: analyze sources, create entity/concept pages, update index.md.
- For query tasks: search wiki, synthesize answers from multiple pages.
- When done, reply with natural language answer (no tool call).

Be concise. Explain what you're doing before each command."""


# ─── Tool definitions (JSON Schema for OpenAI-compatible API) ──────

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "bash",
            "description": "Execute a shell command and return stdout/stderr.",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string", "description": "The bash command to execute."}
                },
                "required": ["command"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Read the full contents of a file at the given path.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "File path relative to project root."}
                },
                "required": ["path"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "write_file",
            "description": "Write or overwrite a file at the given path.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "File path relative to project root."},
                    "content": {"type": "string", "description": "Content to write to the file."}
                },
                "required": ["path", "content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "find_wiki_pages",
            "description": "Search for wiki pages matching a topic. Returns paths and titles.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Topic or tag to search."}
                },
                "required": ["query"]
            }
        }
    }
]


# ─── Tool implementations ──────────────────────────────────────────

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))


def run_bash(command: str) -> str:
    """Выполнить bash-команду и вернуть результат."""
    try:
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True,
            timeout=120, cwd=PROJECT_ROOT
        )
        out = result.stdout + (f"\nSTDERR:\n{result.stderr}" if result.stderr else "")
        return f"Exit code: {result.returncode}\n{out}"
    except subprocess.TimeoutExpired:
        return "Error: command timed out after 120s"


def read_file(path: str) -> str:
    """Прочитать файл по пути."""
    full_path = os.path.join(PROJECT_ROOT, path)
    if not os.path.exists(full_path):
        return f"File not found: {path}"
    try:
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()
        # Ограничим вывод 10KB для безопасности
        if len(content) > 10000:
            return content[:10000] + "\n... (truncated, original length: {} bytes)".format(len(content))
        return content
    except Exception as e:
        return f"Error reading {path}: {e}"


def write_file(path: str, content: str) -> str:
    """Записать файл."""
    full_path = os.path.join(PROJECT_ROOT, path)
    try:
        # Создаём директории если нужно
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(content)
        return f"OK: wrote {len(content)} bytes to {path}"
    except Exception as e:
        return f"Error writing {path}: {e}"


def find_wiki_pages(query: str) -> str:
    """Поиск страниц wiki."""
    # Ищем markdown файлы в wiki/ и raw/ по имени или содержимому
    results = []

    def search_dir(dir_path):
        for root, dirs, files in os.walk(dir_path):
            for fname in files:
                if not fname.endswith(".md"):
                    continue
                fpath = os.path.join(root, fname)
                rel_path = os.path.relpath(fpath, PROJECT_ROOT)
                # Ищем в имени файла
                if query.lower() in fname.lower():
                    results.append(rel_path)

    search_dir(os.path.join(PROJECT_ROOT, "wiki"))
    search_dir(os.path.join(PROJECT_ROOT, "raw"))

    if not results:
        return f"No wiki pages found matching '{query}'"

    return f"Found {len(results)} page(s):\n" + "\n".join(f"- {r}" for r in sorted(results))


# ─── Tool registry ────────────────────────────────────────────────

TOOLS_MAP = {
    "bash": run_bash,
    "read_file": read_file,
    "write_file": write_file,
    "find_wiki_pages": find_wiki_pages,
}


def call_tool(name: str, arguments: dict) -> str:
    """Вызвать инструмент по имени."""
    func = TOOLS_MAP.get(name)
    if not func:
        return f"Error: unknown tool '{name}'"
    try:
        return func(**arguments)
    except Exception as e:
        return f"Error calling {name}: {e}"


# ─── LLM call ──────────────────────────────────────────────────────

def call_llm(messages):
    """Отправить запрос к LLM и получить ответ."""
    payload = {
        "model": LLM_MODEL,
        "messages": messages,
        "tools": TOOLS,
        "tool_choice": "auto",
        "temperature": 0.1,
        "max_tokens": 4096
    }

    response = requests.post(
        f"{LLM_BASE_URL}/chat/completions",
        json=payload,
        headers=LLM_HEADERS
    )
    response.raise_for_status()
    
    msg = response.json()["choices"][0]["message"]
    content = (msg.get("content") or "").strip()
    tool_calls = msg.get("tool_calls") or []
    return content, tool_calls


# ─── Agent Loop ────────────────────────────────────────────────────

def agent_loop(user_message: str) -> None:
    """Основной цикл агента."""
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message}
    ]
    
    for turn in range(1, MAX_TURNS + 1):
        print(f"\n{'='*60}\n🔄 Turn {turn}\n{'='*60}")
        
        content, tool_calls = call_llm(messages)
        
        if content:
            print(f"\n🤖 {content}")
        if not tool_calls:
            label = "(no text output)" if not content else ""
            print(label or "")
            print("✅ Agent finished")
            return
        
        # Обрабатываем вызовы инструментов
        for tc in tool_calls:
            name = tc["function"]["name"]
            args = json.loads(tc["function"]["arguments"])
            tc_id = tc.get("id") or ""
            
            print(f"\n🔧 Tool: {name}({json.dumps(args, ensure_ascii=False)})")
            result = call_tool(name, args)
            safe_result = result[:500] + ("..." if len(result) > 500 else "")
            print(f"   → {safe_result}")
            
            assistant_msg = {"role": "assistant", "tool_calls": [tc]}
            if content:
                assistant_msg["content"] = content
            messages.append(assistant_msg)
            messages.append({
                "role": "tool",
                "tool_call_id": tc_id,
                "content": result
            })


if __name__ == "__main__":
    prompt = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else ""
    if not prompt.strip():
        print("Usage: python3 wiki_harness.py <task>")
        sys.exit(1)
    
    agent_loop(prompt)
