# helmfile-example

## Overview

This repo defines the Helm releases for most of our Kubernetes applications.

The external-dns and cert-manager releases are defined in the terraform repo, because they require resources outside of the Kubernetes cluster to function.

## Initial Setup

1. In .github/workflows/helmfile.yml:
  1. Set the `role-to-assume` to your `github-actions-your_env-k8s`.
  1. Ensure that update-kubeconfig is configured for the correct cluster.
1. In .sops.yaml, update the kms key arns to your arns.

## Process

When adding new charts or updating chart versions, you need to update the lockfile with:

```
helmfile deps
```

These Helm releases are currently being applied manually with:

```
helmfile apply
```

If we are removing something from the helmfile and need to uninstall it from the cluster manually with:

```
helm uninstall -n namespace release_name
```
