#!/usr/bin/env bats
# text-similarity.sh — unit tests via bats

setup() {
    SCRIPT="$BATS_TEST_DIRTEXT/../scripts/text-similarity.sh"
    TMPDIR=$(mktemp -d)
}

teardown() {
    rm -rf "$TMPDIR"
}

@test "pairwise mode: high similarity files" {
    echo "Hello world test document about RAG systems and how they work together" > "$TMPDIR/file1.md"
    echo "Hello world test document about RAG systems and how they work in practice" > "$TMPDIR/file2.md"
    
    result=$(bash "$SCRIPT" "$TMPDIR/file1.md" "$TMPDIR/file2.md")
    similarity=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['similarity'])")
    
    assert [ "$(echo "$similarity > 50 | bc -l" | grep -c '1')" = "1" ], "High similarity should be > 50%"
}

@test "pairwise mode: low similarity files" {
    echo "Quantum computing uses qubits and superposition principles" > "$TMPDIR/file1.md"
    echo "RAG systems combine retrieval with generation to reduce hallucinations" > "$TMPDIR/file2.md"
    
    result=$(bash "$SCRIPT" "$TMPDIR/file1.md" "$TMPDIR/file2.md")
    similarity=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['similarity'])")
    
    assert [ "$(echo "$similarity < 30 | bc -l" | grep -c '1')" = "1" ], "Low similarity should be < 30%"
}

@test "empty input: graceful fallback" {
    result=$(bash "$SCRIPT")
    mode=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['mode'])")
    
    assert [ "$mode" = "error" ], "Empty input should return error mode"
}

@test "missing file: graceful fallback" {
    result=$(bash "$SCRIPT" "/tmp/nonexistent.md" "/tmp/also-nonexistent.md")
    similarity=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['similarity'])")
    
    assert [ "$(echo "$similarity = 0" | bc -l | grep -c '1')" = "1" ], "Missing file should return 0 similarity"
}

@test "scan_all mode: finds high-similarity pairs" {
    mkdir -p "$TMPDIR/wiki"
    
    cat > "$TMPDIR/wiki/page1.md" << EOF
---
tags: [test]
date: 2026-06-27
---
# Page One

This is a test document with common content about RAG systems and how they work.
EOF
    
    cat > "$TMPDIR/wiki/page2.md" << EOF
---
tags: [test]
date: 2026-06-27
---
# Page Two

This is a test document with common content about RAG systems and how they work together.
EOF
    
    result=$(bash "$SCRIPT" --scan-all)
    count=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
    
    assert [ "$(echo "$count >= 1 | bc -l" | grep -c '1')" = "1" ], "Scan should find at least one match"
}
