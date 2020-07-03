# install k8s dashboard (with SSL)

```
# from https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/alternative.yaml
kubectl apply -f alternative.yaml
```

## install ingress

```
kubectl apply -f ingress.yaml
```

## generate access token

```
# from https://medium.com/@kanrangsan/creating-admin-user-to-access-kubernetes-dashboard-723d6c9764e4
kubectl apply -f dashboard-adminuser.yaml
kubectl apply -f admin-role-binding.yml
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}
```
