# Check PR CI Status & Comments

Check CI status and review comments for a PR, then address any issues.

## Arguments
- $ARGUMENTS: repo/number (e.g., "kubestellar/3655" or "docs/640")

## Steps

### 1. Check CI Status
```bash
unset GITHUB_TOKEN && gh pr checks <number> --repo kubestellar/<repo>
```

### 2. Fix CI Failures
- **DCO fails**: Amend commit with `-s` flag and force push
- **PR Title fails**: Update title with emoji prefix (✨🐛📖📝⚠️🌱)
- **Tests fail**: Investigate and fix code issues

### 3. Review Comments
```bash
unset GITHUB_TOKEN && gh pr view <number> --repo kubestellar/<repo> --comments
```

### 4. Address Reviewer Feedback
For each comment from copilot, reviewers, or bots:
1. Read and understand the feedback
2. Make necessary code changes
3. Commit with DCO sign-off
4. Reply to comment explaining how it was addressed

### 5. Re-check Status
After all fixes, verify CI passes:
```bash
unset GITHUB_TOKEN && gh pr checks <number> --repo kubestellar/<repo>
```

Report summary of what was fixed and current status.
