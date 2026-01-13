# KubeStellar Infrastructure Project

## Repository Structure

The kubestellar org has 20+ repos. Key ones:
- **infra** - CI/CD infrastructure, Prow config, reusable workflows
- **kubestellar** - Main project
- **docs** - Documentation site (kubestellar.io/docs)
- **kubeflex** - KubeFlex project
- **ui** - UI project

## Prow CI

- **Dashboard**: https://prow2.kubestellar.io (public), https://prow2-private.kubestellar.io (private)
- **Namespace**: `prow` for components, `test-pods` for jobs
- **Config files**:
  - `/clusters/prow/manifests/prow/` - Kubernetes manifests
  - `/prow/config.yaml` - Main Prow config (in infra repo configmap)
  - `/prow/plugins.yaml` - Plugin config
  - `/prow/jobs/` - Job definitions

### Common Prow Operations
```bash
# Check job status
oc get prowjobs -n prow --sort-by=.metadata.creationTimestamp | tail -20

# View component logs
oc logs -n prow deployment/deck-public
oc logs -n prow deployment/hook
oc logs -n prow deployment/tide

# Trigger job manually (via Prow rerun)
# Use the rerun button on prow2.kubestellar.io after logging in
```

## GitHub Actions & Workflows

### Reusable Workflows (in infra repo)
Located in `.github/workflows/reusable-*.yml`:
- `reusable-greetings.yml` - Welcome messages
- `reusable-feedback.yml` - Survey links
- `reusable-label-helper.yml` - Slash commands for labels
- `reusable-scorecard.yml` - OpenSSF scorecard
- `reusable-stale.yml` - Stale issue management
- `reusable-image-scanning.yml` - Trivy scanning

### Sync Workflow
`sync-workflows.yml` distributes caller workflows to all public, non-archived repos.
Caller workflows are in `caller-workflows/` directory.

### GitHub Actions Discipline
All workflow action references must use commit hashes (not tags).
- Managed via `.gha-reversemap.yml`
- Update with `hack/gha-reversemap.sh update-action-version <action>`
- Apply with `hack/gha-reversemap.sh apply-reversemap`

## Labelsync

Periodic job syncs labels across all repos using `/prow/labels.yaml`.
- Dynamically discovers repos via GitHub API
- Skips archived repos
- Job: `ci-infra-prow-labelsync`

## Common Tasks

### Create PR across repos
1. Clone repo to /tmp/ks-<reponame>
2. Create branch, make changes
3. Commit with DCO: `git commit -s`
4. Push and create PR with emoji title

### Check CI on PR
```bash
unset GITHUB_TOKEN && gh pr checks <number> --repo kubestellar/<repo>
```

### Merge PR
```bash
unset GITHUB_TOKEN && gh pr comment <number> --repo kubestellar/<repo> --body "/lgtm"
unset GITHUB_TOKEN && gh pr comment <number> --repo kubestellar/<repo> --body "/approve"
# Or force merge:
unset GITHUB_TOKEN && gh pr merge <number> --repo kubestellar/<repo> --merge --admin
```

## Working Directories

- Repos cloned to: `/tmp/ks-<reponame>`
- Infra work: `/Users/andan02/ks-ci-fixes/infra`
