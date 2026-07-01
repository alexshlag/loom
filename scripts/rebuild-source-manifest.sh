#!/usr/bin/env bash
# rebuild-source-manifest.sh — Rebuild centralized source manifest for delta tracking
# Purpose: Scan all raw/SRC-* sources, check hashes against corrected copies,
#          output meta/source-manifest.json with status of each source.
# Usage: ./scripts/rebuild-source-manifest.sh [--scan-only]
#   --scan-only: Only print summary to stdout, don't write manifest

set -uo pipefail

WIKI_DIR="${WIKI_DIR:-wiki/}"
RAW_BASE="raw/sources"
CORRECTED_BASE="raw/corrected"
MANIFEST_FILE="meta/source-manifest.json"
LOG_FILE="wiki/log.md"

log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M') $1"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M') $1" >&2; }

SCAN_ONLY="false"
if [[ "${1:-}" == "--scan-only" ]]; then
    SCAN_ONLY="true"
fi

# --- Main logic: use python3 for robust JSON generation ---

log_info "Starting source manifest rebuild..."

export SCAN_ONLY
python3 << 'PYEOF'
import json, hashlib, os, glob
from datetime import datetime
SCAN_ONLY = os.environ.get("SCAN_ONLY", "false") == "true"

RAW_BASE = "raw/sources"
CORRECTED_BASE = "raw/corrected"
MANIFEST_FILE = "meta/source-manifest.json"

def compute_sha256(filepath):
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest()

# Find all source files (excluding corrected copies)
all_sources = []
for pattern in [os.path.join(RAW_BASE, "*", "*.md"), os.path.join(RAW_BASE, "*/*.md")]:
    for src_file in glob.glob(pattern):
        if "/corrected/" not in src_file:
            all_sources.append(src_file)

# Deduplicate - some files match multiple patterns
all_sources = list(set(all_sources))

all_sources.sort()
print(f"[INFO] Found {len(all_sources)} source files to process")

manifest_entries = []
processed_count = 0
unprocessed_count = 0
duplicate_count = 0

for src_file in all_sources:
    hash_orig = compute_sha256(src_file)
    
    # Determine source ID from path (extract SRC-XXXX-YYYY pattern)
    src_dir = os.path.basename(os.path.dirname(src_file))
    src_id = src_dir
    
    # Check if corrected copy exists with matching hash
    corrected_file = os.path.join(CORRECTED_BASE, src_id, os.path.basename(src_file.replace('.md', '.md')))
    
    has_corrected = False
    status = "unprocessed"
    
    manifest_path = os.path.join(CORRECTED_BASE, src_id, ".manifest.json")
    
    if os.path.exists(corrected_file):
        if os.path.exists(manifest_path):
            with open(manifest_path) as f:
                existing_manifest = json.load(f)
            hash_orig_from_manifest = existing_manifest.get("hash_original", "")
            
            # Check if original hash matches (no re-ingest needed)
            if hash_orig == hash_orig_from_manifest:
                status = "processed"
                has_corrected = True
                processed_count += 1
                duplicate_count += 1
            else:
                # Original changed since last ingest — needs re-ingest
                status = "stale"
                has_corrected = True
                unprocessed_count += 1
        else:
            # Corrected file exists but no manifest — generate it
            hash_corr = compute_sha256(corrected_file)
            
            new_manifest = {
                "original_path": src_file,
                "corrected_path": corrected_file,
                "hash_original": hash_orig,
                "hash_corrected": hash_corr,
                "date_ingested": datetime.now().strftime("%Y-%m-%d"),
                "status": "processed"
            }
            
            os.makedirs(os.path.dirname(manifest_path), exist_ok=True)
            with open(manifest_path, 'w') as f:
                json.dump(new_manifest, f, indent=2)
            
            status = "processed"
            has_corrected = True
            processed_count += 1
    else:
        # No corrected copy — needs processing
        unprocessed_count += 1
    
    manifest_entries.append({
        "source_path": src_file,
        "corrected_base": os.path.join(CORRECTED_BASE, src_id),
        "hash_original": hash_orig,
        "status": status,
        "has_corrected_copy": has_corrected
    })

# Write centralized manifest
manifest_timestamp = datetime.now().strftime("%Y-%m-%dT%H:%M:%S+03:00")

if SCAN_ONLY:
    print("=== Source Manifest Scan ===")
    print(f"Timestamp: {manifest_timestamp}")
    print(f"Total sources: {len(all_sources)}")
    print(f"Processed (no re-ingest needed): {processed_count}")
    print(f"Stale/Unprocessed (need action): {unprocessed_count}")
else:
    os.makedirs(os.path.dirname(MANIFEST_FILE), exist_ok=True)
    
    final_manifest = {
        "timestamp": manifest_timestamp,
        "total_sources": len(all_sources),
        "processed_count": processed_count,
        "unprocessed_count": unprocessed_count,
        "duplicate_count": duplicate_count,
        "sources": manifest_entries
    }
    
    with open(MANIFEST_FILE, 'w') as f:
        json.dump(final_manifest, f, indent=2)
    
    print(f"[INFO] Wrote manifest to {MANIFEST_FILE}")

print(f"[INFO] Manifest rebuild complete: {len(all_sources)} sources, {processed_count} processed, {unprocessed_count} unprocessed/stale")
PYEOF

exit $?
