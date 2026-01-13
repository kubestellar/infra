# Merge PR

Add lgtm/approve labels and merge a PR.

## Arguments
- $ARGUMENTS: repo/number (e.g., "kubestellar/3655" or "docs/640")

## Steps

1. Parse repo and PR number from arguments
2. Add lgtm: `unset GITHUB_TOKEN && gh pr comment <number> --repo kubestellar/<repo> --body "/lgtm"`
3. Add approve: `unset GITHUB_TOKEN && gh pr comment <number> --repo kubestellar/<repo> --body "/approve"`
4. Wait 15 seconds for labels to be applied
5. Check if mergeable: `unset GITHUB_TOKEN && gh pr checks <number> --repo kubestellar/<repo> | grep tide`
6. If still blocked, force merge: `unset GITHUB_TOKEN && gh pr merge <number> --repo kubestellar/<repo> --merge --admin`
7. Verify merged status
