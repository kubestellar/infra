# infra

This repository contains tools and configuration files for the testing and automation needs of the `kubestellar` organizations.

## Prow (CI)

There is 1 Kubernetes cluster that make up the Prow CI system for kubestellar.

* The `prow` cluster holds Prow itself (Deck, Horologium, Sinker, Plank, ...), but besides a few exceptions, no actual Prow jobs are executed here. This cluster is separated from the other to make sure some sensitive secrets (like the Github token) are not available to "random" Prow jobs that could just `echo` and steal it.
* The `build` cluster is where most of the Prow jobs are executed. This cluster is auto-scaling and holds nothing but the Prow jobs.

To access Prow, there are 2 instances of its UI:

* https://prow2-private.kubestellar.io/ is the _internal_ Deck, available only to authenticated users (users part of the `kubestellar-dev` organization). This deck shows _all_ repositories and offers a way to rerun a Prowjob.
* https://prow2.kubestellar.io/ is the _public_ Deck, available to everyone, but read-only.
