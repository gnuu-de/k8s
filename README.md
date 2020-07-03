K8S Deployment GNUU
===================

Contents
--------


clusterissuer.yaml Let's Encrypt Cluster Issuer for Cert Manager

namespace.yaml Creates Namespace gnuu

pvc.yaml Creates a volume storage, mostly mount on /data


nginx/ Static web https://k8s.gnuu.de

dashboard/ Kubernetes-Dashboard https://dashboard.gnuu.de

uucp/ UUCP Service Port 540

mail/ Mail Service Port 25


Exposed Cluster Services MAIL, NEWS, UUCP:
------------------------------------------

Adapt externalIP in service deployment to the host network ip. 

```
  externalIPs:
    - 10.9.3.171
```

Set kubectl context

```
kubectl config set-context --current --namespace=gnuu
```

