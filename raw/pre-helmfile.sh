#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
# Not using "-x" because we aren't debugging.
set -Eeuo pipefail

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Create "regcred" secret with GitHub registry credentials in all namespaces that need to pull private images.
for ns in \
  website \
; do
  if ! kubectl get ns "${ns}" &> /dev/null; then kubectl create ns "${ns}"; fi
  kubectl apply -n "${ns}" -f <(sops -d "${SCRIPT_DIR}/regcred.secret.yaml")
done

# Create "basic-auth" secret for prometheus and alertmanager.
if ! kubectl get ns kube-prometheus-stack &> /dev/null; then kubectl create ns kube-prometheus-stack; fi
kubectl apply -n kube-prometheus-stack -f <(sops -d "${SCRIPT_DIR}/basic-auth.secret.yaml")

# Create the rest of the secrets
while read -r f; do
  kubectl apply -f <(sops -d "$f")
done < <(find "${SCRIPT_DIR}" -name '*.secret.yaml' -and -not -name regcred.secret.yaml -and -not -name basic-auth.secret.yaml)

# Install CRDs for kube-prometheus-stack
# ...because `crds.enabled: true` is failing with lots of these errors:
#   ensure CRDs are installed first, resource mapping not found for name: "kube-prometheus-stack-prometheus" namespace: "kube-prometheus-stack" from "": no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
# https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack#from-60-x-to-61-x
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.75.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml

# For NVIDIA Operator
# https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html#operator-install-guide
# kubectl create ns gpu-operator
# kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
