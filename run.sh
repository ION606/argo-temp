# see https://www.solo.io/blog/istio-ambient-argo-cd-kind-15-minutes

minikube delete

set -a
source .env
set +a

minikube start --driver=docker
kubectl create namespace argocd || true

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.5/manifests/install.yaml

echo "Waiting for Argo CD server pod to be ready..."
kubectl wait --namespace argocd --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s

kubectl port-forward svc/argocd-server -n argocd 9999:443 &> forward.txt &

echo "installing Kubernetes Gateway CRDs"
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.0.0" | kubectl apply -f -; }

echo "Applying Application manifests with ISTIO_VERSION=$ISTIO_VERSION"
for f in charts/*.yaml; do
    echo " -> $f"
    envsubst < "$f" | kubectl apply -f -
done

sleep 5

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo
