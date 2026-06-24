#!/usr/bin/env python3
"""
wiki_manifest_executor.py — Исполнитель декларативных манифестов wiki.

Читает JSON-манифест (или Markdown с embedded JSON), идёт по шагам:
  execute → evaluate result → branch to next step / error handler

Usage: python3 wiki_manifest_executor.py <manifest.json> [--verbose]
"""

import json, subprocess, os, sys, re, shutil


# ─── Типы действий (actions) ──────────────────────────────────────

def run_command(cmd, cwd=None):
    """Выполнить shell-команду, вернуть результат."""
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True,
        cwd=cwd or os.getcwd()
    )
    return {
        "exit_code": result.returncode,
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
        "success": result.returncode == 0
    }


def mkdir(paths, cwd=None):
    """Создать директории (поддержка nested)."""
    for p in paths:
        os.makedirs(os.path.join(cwd or os.getcwd(), p), exist_ok=True)
    return {"exit_code": 0, "stdout": f"Created dirs: {paths}", "stderr": ""}


def decode_base64(source_tag, target_path, cwd=None, manifest_context=None):
    """
    Декодировать Base64 из тега <file_content name="X">\n<base64>...</file_content>.
    
    source_tag формат: 'file_content[name=FILENAME]'
    """
    # Извлекаем имя файла
    match = re.search(r'name=(\S+)', source_tag)
    if not match:
        raise ValueError(f"Invalid source_tag format: {source_tag}")
    filename = match.group(1)
    
    # Пытаемся найти base64-блок в манифесте (передаётся через context)
    b64_data = None
    for item in (manifest_context or {}).get("base64_sources", []):
        if item.get("name") == filename:
            b64_data = item.get("content", "")
            break
    
    if not b64_data:
        raise ValueError(f"No base64 source found for {filename}")
    
    # Декодируем и пишем
    import base64 as b64mod
    try:
        decoded = b64mod.b64decode(b64_data)
        path = os.path.join(cwd or os.getcwd(), target_path)
        with open(path, "wb") as f:
            f.write(decoded)
        return {"exit_code": 0, "stdout": f"Decoded and wrote {path}", "stderr": ""}
    except Exception as e:
        return {"exit_code": 1, "stdout": "", "stderr": str(e)}


# ─── Executor core ────────────────────────────────────────────────

class ManifestExecutor:
    def __init__(self, manifest_path, verbose=False):
        self.verbose = verbose
        self.manifest_path = manifest_path
        
        # Парсим манифест (поддержка JSON и Markdown+JSON)
        with open(manifest_path, "r") as f:
            raw = f.read()
        
        try:
            self.manifest = json.loads(raw)
        except json.JSONDecodeError:
            # Попробовать извлечь JSON из Markdown
            json_match = re.search(r'\{[^}]+\}', raw, re.DOTALL)
            if json_match:
                self.manifest = json.loads(json_match.group())
            else:
                raise ValueError(f"Cannot parse manifest from {manifest_path}")
        
        # Собираем base64-источники из тега <file_content>
        self.base64_sources = []
        for match in re.finditer(r'<file_content name="(\S+)">\s*(.*?)\s*</file_content>', raw, re.DOTALL):
            self.base64_sources.append({
                "name": match.group(1),
                "content": match.group(2).replace("\n", "").strip()
            })
        manifest_context = {"base64_sources": self.base64_sources}

    def log(self, msg):
        if self.verbose:
            print(f"  {msg}")

    def execute_step(self, step):
        """Выполлить один шаг манифеста."""
        name = step.get("name", "unnamed")
        actions = step.get("actions", [])
        commands = step.get("commands", [])
        
        self.log(f"▶ {name}")
        
        # 1. Выполняем команды (ENV check style)
        for cmd_desc in commands:
            result = run_command(cmd_desc["cmd"])
            if not result["success"]:
                return {
                    "status": "FAIL",
                    "step_name": name,
                    "error": cmd_desc.get("err_msg", f"Command failed: {result['stderr'] or 'exit_code=' + str(result['exit_code'])}")
                }
        
        # 2. Выполняем actions (fs_deployment style)
        for action in actions:
            try:
                atype = action.get("action_type", action.get("action", ""))
                if atype == "mkdir":
                    run_result = mkdir(action["paths"])
                elif action.get("action") == "decode_base64":
                    run_result = decode_base64(
                        action["source_tag"],
                        action["target_path"],
                        manifest_context={"base64_sources": self.base64_sources}
                    )
                elif action["action"] == "chmod":
                    path = os.path.join(os.getcwd(), action["path"])
                    if not os.path.exists(path):
                        return {
                            "status": "FAIL",
                            "step_name": name,
                            "error": f"File does not exist: {action['path']}"
                        }
                    mode = int(action.get("mode", "0o755").replace("+x", ""), 8)
                    os.chmod(path, mode)
                    run_result = {"exit_code": 0, "stdout": "", "stderr": ""}
                elif action["action"] == "post_check":
                    run_result = run_command(action.get("cmd", ""))
                else:
                    self.log(f"  ⚠ Unknown action: {action['action']}")
                    continue
                
            except Exception as e:
                return {
                    "status": "FAIL",
                    "step_name": name,
                    "error": f"Action '{action.get('action')}' exception: {e}"
                }

        # 3. Post-check (если есть)
        if "post_check_cmd" in step:
            result = run_command(step["post_check_cmd"])
            if not result["success"]:
                return {
                    "status": "FAIL",
                    "step_name": name,
                    "error": f"Post-check failed: {result['stderr'] or 'exit_code=' + str(result['exit_code'])}"
                }

        # 4. Verification (если есть)
        if "verification" in step:
            result = run_command(step["verification"]["cmd"])
            expected = step["verification"].get("expected_exit_code", 0)
            if result["exit_code"] != expected:
                return {
                    "status": "FAIL",
                    "step_name": name,
                    "error": f"Verification failed: expected exit_code={expected}, got={result['exit_code']}. stderr: {result['stderr']}"
                }

        return {"status": "SUCCESS", "step_name": name}

    def run(self):
        """Запуск всего манифеста."""
        steps = self.manifest.get("steps", [])
        
        for step in steps:
            result = self.execute_step(step)
            
            if result["status"] == "SUCCESS":
                self.log(f"✓ {result['step_name']} PASSED")
                
                # Переходим к следующему шагу
                next_step_id = None
                evaluation = step.get("evaluation", {})
                for key, value in evaluation.items():
                    if key == "on_success":
                        ns = value.get("next_step") or str(value).replace("GOTO STEP: ", "").strip()
                        next_step_id = ns
                        break
                
                # Если нет explicit GOTO, ищем следующий шаг по порядку
                if not next_step_id:
                    self.log(f"  → Proceeding to next step")
                else:
                    self.log(f"  → Jumping to {next_step_id}")
                    
            else:
                self.log(f"✗ {result['step_name']} FAILED: {result.get('error', 'unknown')}")
                
                # Ищем error handler
                error_handler = None
                for s in steps:
                    if s.get("name") == "ERROR_HANDLER" or s.get("step") == "ERROR_HANDLER":
                        error_handler = s
                        break
                
                if not error_handler:
                    self.log(f"  ⚠ No ERROR_HANDLER found — aborting")
                    sys.exit(1)
                
                # Выполняем error handler
                self.log(f"  → Running ERROR_HANDLER...")
                instructions = error_handler.get("instructions", [])
                for instr in instructions:
                    self.log(f"  [EH] {instr}")


# ─── Main ─────────────────────────────────────────────────────────

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 wiki_manifest_executor.py <manifest.json>")
        sys.exit(1)
    
    manifest_path = sys.argv[1]
    verbose = "--verbose" in sys.argv
    
    try:
        executor = ManifestExecutor(manifest_path, verbose=verbose)
        executor.run()
    except Exception as e:
        print(f"FATAL: {e}")
        sys.exit(2)
