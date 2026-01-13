# Prow Status

Check Prow component health and recent job status.

## Steps

1. Check Prow pods:
```bash
oc get pods -n prow
```

2. Check recent prowjobs:
```bash
oc get prowjobs -n prow --sort-by=.metadata.creationTimestamp | tail -15
```

3. Check for failed jobs:
```bash
oc get prowjobs -n prow --field-selector=status.state=failure --sort-by=.metadata.creationTimestamp | tail -10
```

4. If issues found, check component logs:
```bash
oc logs -n prow deployment/deck-public --tail=50
oc logs -n prow deployment/hook --tail=50
oc logs -n prow deployment/tide --tail=50
```

5. Report summary of Prow health and any issues
