# Git Troubleshooting Guide for Loomana Wiki

## 🔍 Common Issues & Solutions

### Issue 1: "fatal: path is ignored"

**Symptoms**: `git add file` fails with "path is ignored by .gitignore"

**Solutions**:
```bash
# Check if file is ignored
git check-ignore -v <file>

# ⚠️ Force add — используйте ТОЛЬКО с разрешения пользователя
# Это может нарушить правила проекта (protected zones)
git add -f <file>

# Remove from ignore temporarily by editing .gitignore
# Comment out the line, then:
git add <file>
```

### Issue 2: "error: commit message is empty"

**Symptoms**: `git commit` fails without message

**Solution**:
```bash
# Always provide a message with proper format
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
- **Do not bypass guardrails** — they protect the project integrity

### Issue 4: "Your local changes to the working tree are uncommitted"

**Symptoms**: Can't switch branches or push

**Solution**:
```bash
# Commit your changes first (specify files, don't use git add .)
git add <specific-files>
git commit -m "type | scope: description"

# Or stash them for later (safer than committing everything)
git stash

# If you need to discard changes (use with caution!)
# Only safe for files NOT in protected zones
git checkout -- <file>
```

### Issue 5: Conflicting changes after pull

**Symptoms**: `git pull` fails with conflicts

**Solution**:
```bash
# See what conflicts
git status

# Resolve conflicts manually, then commit
git add <resolved files>
git commit -m "merge | resolved conflicts"
```

### Issue 6: Lost changes after reset/hard reset

**Symptoms**: Changes disappeared after `git reset --hard`

**Solution**:
```bash
# If reflog is available (recovery attempt)
git reflog
# Try to restore from previous commit if needed

# Or restore from backup if you have one
# Note: This may result in data loss — use with caution
```

### Issue 7: Large files in commit (similarity_cache.json)

**Symptoms**: Commit too large, slow performance

**Solution**:
```bash
# Check size
ls -lh tracking/similarity_cache.json

# If too large (>10MB), consider:
# 1. Not committing it at all (it's already in .gitignore)
# 2. Using git-lfs for large files
# 3. Compressing before commit
```

---

## 🛠 Quick Fixes

### Reset working directory to clean state ⚠️ DANGEROUS

**WARNING**: These operations can delete files and bypass protected zones!

```bash
# ❌ DO NOT USE: Deletes untracked files including potentially important ones
git clean -fd

# ⚠️ Use with extreme caution: Resets to last commit
# Only use if you understand what you're doing
git reset --hard HEAD
```

### Safer alternatives:

```bash
# Reset only staged changes (safer)
git reset

# Discard changes in specific file
git checkout -- <file>

# Restore from backup if available
cp backup/<file> <file>
```

---

## 📚 References

- [Git Documentation](https://git-scm.com/doc)
- [Pro Git Book](https://git-scm.com/book/en/v2)
- Loomana Wiki: `wiki/GIT-WORKFLOW.md`
