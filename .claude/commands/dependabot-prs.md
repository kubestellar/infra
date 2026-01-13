# Dependabot PRs

Check and manage dependabot PRs across kubestellar repos.

## Arguments
- $ARGUMENTS: Optional action (check, merge, close-conflicts)

## Steps

### 1. Check all repos for dependabot PRs

Get all active (non-archived) repos and check each for dependabot PRs:
```bash
unset GITHUB_TOKEN && for repo in $(gh api orgs/kubestellar/repos --paginate --jq '.[] | select(.archived == false) | .name' | sort); do
  prs=$(unset GITHUB_TOKEN && gh pr list --repo kubestellar/$repo --author dependabot --state open --json number,title 2>/dev/null)
  if [ "$prs" != "[]" ] && [ -n "$prs" ]; then
    echo "=== kubestellar/$repo ==="
    echo "$prs" | jq -r '.[] | "  #\(.number): \(.title)"'
  fi
done
```

### 2. For each Go dependency PR, check for vulnerabilities

Clone the repo and checkout the PR branch:
```bash
cd /tmp && rm -rf ks-<repo> && git clone https://github.com/kubestellar/<repo>.git ks-<repo>
cd /tmp/ks-<repo> && gh pr checkout <number>
```

Run vulnerability check:
```bash
# Install if needed: go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
```

If vulnerabilities found:
- Check if the dependabot update fixes them
- If new vulnerabilities introduced, do NOT merge
- Comment on PR with findings

### 3. For each PR found:
1. Check CI status
2. Run govulncheck (for Go repos)
3. If passing, no conflicts, no new vulns: merge with `/lgtm` and `/approve`
4. If conflicting: close (will be recreated by dependabot)
5. If new vulnerabilities: comment and do not merge

### Merge command
```bash
unset GITHUB_TOKEN && gh pr comment <number> --repo kubestellar/<repo> --body "/lgtm"
unset GITHUB_TOKEN && gh pr comment <number> --repo kubestellar/<repo> --body "/approve"
```

### Close conflicting PRs
```bash
unset GITHUB_TOKEN && gh pr close <number> --repo kubestellar/<repo> --comment "Closing due to conflicts. Dependabot will recreate."
```

### Other vulnerability tools (optional)
- **npm audit** - For JavaScript/TypeScript repos (ui, docs)
- **trivy** - Container image scanning
- **snyk** - Multi-language vulnerability scanning
