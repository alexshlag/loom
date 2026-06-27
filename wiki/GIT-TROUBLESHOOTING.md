# Git Troubleshooting Guide for Loomana Wiki

## 🔍 Common Issues & Solutions

### Issue 1: "fatal: path is ignored"

**Symptoms**: `git add file` fails with "path is ignored by .gitignore"

**Solutions**:
```bash
# Check if file is ignored
git check-ignore -v <file>

# Force add (use with caution)
git add -f <file>

# Remove from ignore temporarily
# Edit .gitignore and comment out the line
```

### Issue 2: "error: commit message is empty"

**Symptoms**: `git commit` fails without message

**Solution**:
```bash
# Always provide a message
git commit -m "type | scope: description"

# Or use interactive mode
git commit
# Then type your message
```

### Issue 3: Pre-commit hook failed

**Symptoms**: Commit blocked by `.git/hooks/pre-commit`

**Diagnosis**:
```bash
# Run hook manually to see error
./.git/hooks/pre-commit --no-verify

# Check what's staged
git diff --cached --name-only
```

**Solution**:
- Ensure you're not modifying protected zones (`raw/`, `meta/`)
- Add required files (AGENTS.md, process-*.json) if changed
- Fix any validation errors in scripts

### Issue 4: "Your local changes to the working tree are uncommitted"

**Symptoms**: Can't switch branches or push

**Solution**:
```bash
# Commit your changes first
git add .
git commit -m "fix | resolved uncommitted changes"

# Or stash them (for later)
git stash
```

### Issue 5: Conflicting changes after pull

**Symptoms**: `git pull` fails with conflicts

**Solution**:
```bash
# See what conflicts
git status

# Resolve conflicts manually, then:
git add <resolved files>
git commit -m "merge | resolved conflicts"
```

### Issue 6: Lost changes after reset/hard reset

**Symptoms**: Changes disappeared after `git reset --hard`

**Solution**:
```bash
# If reflog is available:
git reflog
git reset HEAD~1  # Undo the last reset

# Or restore from backup if you have one
```

### Issue 7: Large files in commit (similarity_cache.json)

**Symptoms**: Commit too large, slow performance

**Solution**:
```bash
# Check size
ls -lh tracking/similarity_cache.json

# If too large (>10MB), consider:
# 1. Not committing it at all (remove from .gitignore exception)
# 2. Using git-lfs for large files
# 3. Compressing before commit
```

---

## 🛠 Quick Fixes

### Reset working directory to clean state
```bash
git reset --hard HEAD
git clean -fd
```

### View all commits (including ignored ones)
```bash
git log --all --oneline
```

### See what would be committed
```bash
git diff --cached  # Staged changes only
git diff          # Unstaged changes
```

---

## 📚 References

- [Git Documentation](https://git-scm.com/doc)
- [Pro Git Book](https://git-scm.com/book/en/v2)
- Loomana Wiki: `.git/GIT-WORKFLOW.md`
