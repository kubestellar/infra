# Create PR

Create a PR with proper DCO sign-off and emoji title.

## Arguments
- $ARGUMENTS: Description of what to create (will prompt for details if needed)

## Requirements (MUST FOLLOW)
1. **DCO**: All commits MUST be signed with `-s` flag
2. **Title**: MUST start with emoji (✨ feature | 🐛 bug | 📖 docs | 🌱 other)
3. **Body**: Include Summary, Related issues, Test plan sections

## Steps

1. Determine target repo and branch
2. Make code changes
3. Stage and commit with DCO: `git add . && git commit -s -m "message"`
4. Push branch: `git push -u origin <branch>`
5. Create PR with proper title:
```bash
unset GITHUB_TOKEN && gh pr create --title "🐛 Fix description" --body "$(cat <<'EOF'
## Summary
- Brief description

## Related issue(s)
Fixes #

## Test plan
- [ ] Test item

---
Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
6. Run /check-pr to verify CI passes
