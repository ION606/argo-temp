#!/usr/bin/env bash
# simple, robust bootstrap for your blahaj demo on minikube

set -Eeuo pipefail;

# ---- settings (tweak as you like) ------------------------------------------
PROFILE="${PROFILE:-minikube}";          # minikube profile name
CPUS="${CPUS:-2}";                       # cpu cores
MEMORY_MB="${MEMORY_MB:-15400}";         # memory in mb
ISTIO_VERSION="${ISTIO_VERSION:-1.22.1}"; # used only if INSTALL_ISTIO=1
INSTALL_ISTIO="${INSTALL_ISTIO:-0}";     # set to 1 to install istio-minimal
OPEN_ARGO="${OPEN_ARGO:-1}";             # set to 1 to port-forward argo ui
# ----------------------------------------------------------------------------

minikube delete || true;

echo "==> starting minikube...";
minikube start --driver="docker"

echo "==> using minikube's docker daemon for local builds...";
# eval "$(minikube docker-env)";

# build local images (only if paths exist)
if [[ -d apps/reef ]]; then
    echo "==> building local image: blahaj-bun:dev (reef ui)...";
    docker build -t blahaj-bun:dev -f apps/reef/Dockerfile apps/reef;
fi

if [[ -d apps/blahaj-common ]]; then
    echo "==> optionally building common app image (same tag) if services use it...";
    docker build -t blahaj-bun:dev -f apps/blahaj-common/bun.Dockerfile apps/blahaj-common || true;
fi

echo "==> installing argo cd (single-node) into namespace argocd...";
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -;
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml;

echo "==> waiting for argocd-server to be ready...";
kubectl -n argocd rollout status deploy/argocd-server --timeout=180s;

if [[ "${OPEN_ARGO}" == "1" ]]; then
    echo "==> argo admin password:";
    kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d; echo;
    echo "==> port-forwarding argo on https://localhost:9999 (ctrl-c to stop)...";
    kubectl -n argocd port-forward svc/argocd-server 9999:443 >/dev/null 2>&1 &
fi

echo "==> installing gateway api crds (if not present)...";
kubectl get crd gateways.gateway.networking.k8s.io &>/dev/null || {
    kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -;
}

if [[ "${INSTALL_ISTIO}" == "1" ]]; then
    echo "==> installing istio (minimal profile) for gateway api controller...";
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" sh -;
    "./istio-${ISTIO_VERSION}/bin/istioctl" install --set profile=minimal -y;
fi

# apply your demo manifests
echo "==> applying namespace, gateway and routes (environments/dev)...";
[[ -f environments/dev/namespace.yaml ]] && kubectl apply -f environments/dev/namespace.yaml;
[[ -f environments/dev/gateway.yaml   ]] && kubectl apply -f environments/dev/gateway.yaml;
[[ -f environments/dev/httproute.yaml ]] && kubectl apply -f environments/dev/httproute.yaml;

echo "==> deploying reef ui (kustomize or direct)...";
if [[ -f apps/reef/kustomization.yaml ]]; then
    kubectl apply -k apps/reef;
    elif [[ -f apps/reef/deployment.yaml ]]; then
    kubectl apply -f apps/reef/deployment.yaml;
    [[ -f apps/reef/service.yaml ]] && kubectl apply -f apps/reef/service.yaml;
fi

# optional: apply argo app-of-apps or child apps if present
for f in environments/dev/app-*.yaml environments/dev/app.yaml environments/dev/app-root.yaml; do
    [[ -f "$f" ]] && kubectl apply -f "$f";
done

echo "==> waiting briefly for services to appear...";
sleep 3;

# try to open the istio-managed gateway first (when istio is installed)
echo "==> discovering istio-managed gateway service...";
GW_SVC="$(kubectl -n istio-gateway get svc -l 'gateway.istio.io/managed=yes' \
-o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)";

if [[ -n "${GW_SVC}" ]]; then
    echo "==> opening gateway service ${GW_SVC} via minikube...";
    minikube service -n istio-gateway "${GW_SVC}" --url;
    exit 0;
fi

# fallback: open the reef service wherever it is
echo "==> no istio-managed gateway found; falling back to reef service...";
REEF_NS="$(kubectl get svc --all-namespaces -o jsonpath='{range .items[?(@.metadata.name=="reef")]}{.metadata.namespace}{"\n"}{end}' | head -n1)";
if [[ -z "${REEF_NS}" ]]; then
    echo "error: couldn't find a Service named 'reef' in any namespace."; exit 1;
fi

echo "==> opening reef service (ns=${REEF_NS}) via minikube...";
minikube service -n "${REEF_NS}" reef --url;
