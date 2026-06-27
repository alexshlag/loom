#!/usr/bin/env bash
# classify-source.sh — Domain classification for documentation sources
# Graceful by design: never fails, always returns JSON result

set -uo pipefail  # no errexit — we handle errors ourselves

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WHITELIST_FILE="$PROJECT_ROOT/tracking/domain_whitelist.json"
KNOWN_AUTHORS_FILE="$PROJECT_ROOT/tracking/known_authors.json"
LOG_DIR="$PROJECT_ROOT/logs"
CLASSIFY_LOG="$LOG_DIR/classify.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# ─── Usage ──────────────────────────────────────────────────────────
usage() {
    echo "Usage: $0 <url_or_domain> [--dry-run] [--verbose]"
    echo ""
    echo "Arguments:"
    echo "  url_or_domain   URL or domain to classify"
    echo "  --dry-run       Show what would happen without writing log"
    echo "  --verbose       Print classification steps to stderr"
    exit 0
}

# ─── Parse args ─────────────────────────────────────────────────────
URL=""
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h|usage) usage ;;
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        *) URL="$1"; shift ;;
    esac
done

# ─── Validation: input must be present ──────────────────────────────
if [[ -z "${URL:-}" ]]; then
    echo '{"source":"unknown","level":"L3_Community","confidence":0,"reason":"no_url_provided"}'
    exit 0
fi

log_msg() {
    if [[ "$DRY_RUN" == "false" ]]; then
        echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') | $1" >> "$CLASSIFY_LOG" 2>/dev/null || true
    fi
}

verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[classify] $1" >&2
    fi
}

# ─── Extract domain from URL ────────────────────────────────────────
extract_domain() {
    local url="$1"
    
    # Remove protocol
    local no_proto="${url%%://*}"
    if [[ "$no_proto" == "$url" ]]; then
        no_proto="${url#*//}"
    fi
    
    # Remove port, path, query, fragment
    local domain="${no_proto%%/*}"
    domain="${domain%%\?*}"
    domain="${domain%%@*}"
    
    echo "$domain" | tr '[:upper:]' '[:lower:]'
}

# ─── Check whitelist → L1 Official (auto-apply) ─────────────────────
check_whitelist() {
    local domain="$1"
    
    if [[ ! -f "$WHITELIST_FILE" ]]; then
        verbose_log "Whitelist not found, skipping"
        return 2
    fi
    
    # Use Python for robust JSON parsing
    local result
    result=$(python3 << PYEOF
import json, sys

try:
    with open("$WHITELIST_FILE") as f:
        data = json.load(f)
except Exception:
    sys.exit(2)

domain = "$domain"
for entry in data.get("whitelist", []):
    if entry.startswith("github.com/<"):
        continue  # placeholder
    if entry == domain or domain.endswith("." + entry):
        print(entry)
        sys.exit(0)

sys.exit(2)
PYEOF
    ) || true
    
    if [[ -z "$result" ]]; then
        return 1
    else
        echo "$result"
        return 0
    fi
}

# ─── Check known authors → L2 Expert (agent-review) ────────────────
check_known_authors() {
    local domain="$1"
    
    if [[ ! -f "$KNOWN_AUTHORS_FILE" ]]; then
        verbose_log "Known authors file not found, skipping"
        return 2
    fi
    
    local result
    result=$(python3 << PYEOF
import json, sys

try:
    with open("$KNOWN_AUTHORS_FILE") as f:
        data = json.load(f)
except Exception:
    sys.exit(2)

domain = "$domain"
for entry in data.get("authors", []):
    author_domain = entry.get("domain", "")
    if author_domain == domain or domain.endswith("." + author_domain):
        print(entry.get("name", "unknown"))
        sys.exit(0)

sys.exit(2)
PYEOF
    ) || true
    
    if [[ -z "$result" ]]; then
        return 1
    else
        echo "$result"
        return 0
    fi
}

# ─── Main classification logic (graceful fallback chain) ────────────
verbose_log "Starting classification for: $URL"

DOMAIN=$(extract_domain "$URL")
verbose_log "Extracted domain: $DOMAIN"

WHITELIST_MATCH=""
AUTHOR_MATCH=""

# Step 1: Check whitelist → L1 Official (auto-apply)
WHITLIST_RESULT="$(check_whitelist "$DOMAIN")" || true
if [[ $? -eq 0 ]]; then
    WHITLIST_MATCH="$WHITLIST_RESULT"
fi

# Step 2: Check known authors → L2 Expert (agent-review)  
AUTHOR_RESULT="$(check_known_authors "$DOMAIN")" || true
if [[ $? -eq 0 ]]; then
    AUTHOR_MATCH="$AUTHOR_RESULT"
fi

# Decision tree based on matches
if [[ -n "$WHITLIST_MATCH" ]]; then
    verbose_log "L1_Official: domain whitelist match ($WHITLIST_MATCH)"
    log_msg "classified: L1_Official for $URL (whitelist=$WHITLIST_MATCH)"
    echo "{\"source\":\"$URL\",\"domain\":\"$DOMAIN\",\"level\":\"L1_Official\",\"confidence\":1,\"reason\":\"matched_domain_whitelist\"}"
    exit 0

elif [[ -n "$AUTHOR_MATCH" ]]; then
    verbose_log "L2_Expert: known author match ($AUTHOR_MATCH)"
    log_msg "classified: L2_Expert for $URL (author=$AUTHOR_MATCH)"
    echo "{\"source\":\"$URL\",\"domain\":\"$DOMAIN\",\"level\":\"L2_Expert\",\"confidence\":0.7,\"reason\":\"matched_known_author\"}"
    exit 0

else
    verbose_log "L3_Community: no authority match (fallback)"
    log_msg "classified: L3_Community for $URL (no authority match)"
    echo "{\"source\":\"$URL\",\"domain\":\"$DOMAIN\",\"level\":\"L3_Community\",\"confidence\":0.3,\"reason\":\"no_authority_match\"}"
    exit 0
fi

exit 0
