# raw

This directory contains raw Kubernetes Object yaml files. This is for things like CRD objects or secrets that are not part of a Helm release. All secrets are encrypted with `sops`.

The naming convention is:

```
name.namespace.yaml
```

or, for secrets:

```
name.namespace.secret.yaml
```
