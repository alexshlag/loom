#!/usr/bin/env bash
# batch-ingest.sh — Batch ingest orchestrator for multiple sources
# Purpose: Scan, cluster, and suggest wiki pages for batch processing
# Usage: ./scripts/batch-ingest.sh --scan <file1> [file2] [--threshold N]

set -uo pipefail

WIKI_DIR="${WIKI_DIR:-wiki/}"
LOG_FILE="logs/batch-ingest.log"
SOURCE_LIST=()
SCAN_MODE=false
CLUSTER_THRESHOLD=3  # min shared keywords to form cluster

# Logging
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M') $1"; }
log_warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M') $1" >&2; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M') $1" >&2; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --scan)
            SCAN_MODE=true
            shift
            # Collect remaining args as source list
            while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                SOURCE_LIST+=("$1")
                shift
            done
            ;;
        --threshold)
            CLUSTER_THRESHOLD="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --scan <file1> [file2] [--threshold N]"
            echo "Scans files, extracts metadata, clusters by shared keywords/entities"
            exit 0
            ;;
        *)
            if [[ "$SCAN_MODE" == true ]]; then
                SOURCE_LIST+=("$1")
            else
                log_error "Unknown option: $1 (use --scan to provide files)"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ ${#SOURCE_LIST[@]} -eq 0 ]]; then
    log_error "No source files provided. Usage: $0 --scan <file1> [file2] ..."
    exit 1
fi

log_info "Batch ingest scan started with ${#SOURCE_LIST[@]} sources"

# Write source list to temp file for Python to read
TMP_SOURCE_LIST=$(mktemp)
trap 'rm -f "$TMP_SOURCE_LIST"' EXIT

for src in "${SOURCE_LIST[@]}"; do
    echo "$src" >> "$TMP_SOURCE_LIST"
done

log_info "Source list written to $TMP_SOURCE_LIST"

# Phase 1 & 2: Extract metadata and cluster (Python-based)
python3 scripts/_batch_ingest.py "$TMP_SOURCE_LIST"
