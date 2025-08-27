# build locally and and load into minikube
docker build -t blahaj-bun:dev -f apps/blahaj-common/bun.Dockerfile apps/blahaj-common;
docker build -t blahaj-bun:dev -f apps/reef/Dockerfile apps/reef;
minikube image load blahaj-bun:dev;

# apply k8s (plus existing kelp/coral/bubbles apps)
kubectl apply -f apps/reef/kustomization.yaml -n demo --server-side --force-conflicts || true;
kubectl -n demo apply -f apps/reef/deployment.yaml;
kubectl -n demo apply -f apps/reef/kustomization.yaml;

# ensure gateway + route exist (from env files)
kubectl -n demo apply -f environments/dev/gateway.yaml;
kubectl -n demo apply -f environments/dev/httproute.yaml;

# open the gateway service
minikube service -n istio-gateway -l gateway.istio.io/managed=yes --url
# isit http://<host>:80/  (cards!)
