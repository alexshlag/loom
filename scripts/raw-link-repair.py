#!/usr/bin/env python3
"""raw-link-repair — Convert relative markdown links in raw GitHub sources to permalinks."""
import sys, re, os, json, logging

logging.basicConfig(stream=sys.stderr, level=logging.INFO, format='%(message)s')

raw_dir = sys.argv[1].rstrip('/') if len(sys.argv) > 1 else "raw"
dry_run = sys.argv[2] == "true" if len(sys.argv) > 2 and sys.argv[2] != "" else False

abs_raw = os.path.abspath(raw_dir)

logging.info(f"[*] Scanning: {raw_dir}")

# Extract repo metadata from raw_dir path (expects github/{owner}/{repo}[@{branch}] pattern)
owner = repo_name = branch = "UNKNOWN"
parts = abs_raw.split(os.sep)
for i, p in enumerate(parts):
    if p == 'github' and i + 2 < len(parts):
        owner = parts[i+1]
        rb = parts[i+2]
        if '@' in rb:
            repo_name, branch = rb.split('@', 1)
        else:
            repo_name = rb
            branch = 'HEAD'
        break

# If we couldn't extract from path, try reverse lookup from parent
if owner == "UNKNOWN" and abs_raw.startswith(os.path.abspath("raw")):
    raw_rel = abs_raw[len(os.path.abspath("raw"))+1:]
    raw_parts = raw_rel.split('/')
    for i, p in enumerate(raw_parts):
        if p == 'github' and i + 2 < len(raw_parts):
            owner = raw_parts[i+1]
            rb = raw_parts[i+2]
            if '@' in rb:
                repo_name, branch = rb.split('@', 1)
            else:
                repo_name = rb
                branch = 'HEAD'
            break

logging.info(f"[*] Repo metadata: owner={owner}, repo={repo_name}, branch={branch}")

if owner == "UNKNOWN":
    logging.warning("[!] No GitHub repo metadata found in path — exiting")
    sys.exit(0)

repairs = []
file_count = 0
repaired_files = 0

for root, _, files in os.walk(raw_dir):
    for fname in files:
        if not fname.endswith('.md'):
            continue
        
        filepath = os.path.join(root, fname)
        abs_path = os.path.abspath(filepath)
        
        if not abs_path.startswith(abs_raw):
            continue
        
        file_count += 1
        
        try:
            with open(filepath, 'rb') as f:
                raw_bytes = f.read()
            content = raw_bytes.decode('utf-8', errors='replace')
            if not content.strip():
                continue
        except (IOError, OSError):
            continue
        
        # Pattern: markdown links [text](./path.md) or [text](../path/to/file.md#anchor) or just [text](file.md)
        pattern = r'\]\(([A-Za-z_\-./]*\.md(?:#[a-zA-Z0-9_-]*)?)\)'
        
        def replacer(match):
            link_path = match.group(1)
            
            if link_path.startswith('http'):
                return match.group(0)
            
            # Clean: strip leading ./ or ../ and subdirectories, keep just filename
            cleaned_link = re.sub(r'^(\.\./)+', '', link_path).lstrip('./')
            
            permalink = f"https://github.com/{owner}/{repo_name}/blob/{branch}/{cleaned_link.strip('/')}"
            
            return ']' + '(' + permalink + ')'
        
        new_content = re.sub(pattern, replacer, content)
        
        if new_content != content:
            repaired_files += 1
            
            old_links = list(set(re.findall(r'\]\(([A-Za-z_\-./]*\.md)\)', content)))
            
            for old in old_links:
                cleaned = re.sub(r'^(\.\./)+', '', old).lstrip('./')
                repairs.append({
                    "original": f"({old})",
                    "repaired": f"https://github.com/{owner}/{repo_name}/blob/{branch}/{cleaned.strip('/')}"
                })
            
            if not dry_run:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                
                logging.info(f"[✓] {filepath}")
            else:
                logging.info(f"[D] {filepath}")

print(json.dumps({"dry_run": dry_run, "total_repairs": len(repairs), "files_scanned": file_count, "repaired_files": repaired_files, "repairs": repairs}))
logging.info(f"[✓] Scanned: {file_count} files, Repaired: {repaired_files} files")
