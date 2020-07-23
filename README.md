K8S Deployment GNUU
===================

Contents
--------


files/dirs          | description
------------------- | -------------------------------------------------
clusterissuer.yaml  | Let's Encrypt Cluster Issuer for Cert Manager
namespace.yaml      | Creates Namespace gnuu
pvc.yaml            | Creates a volume storage, mostly mount on /data
apps                | Backend Web Services user + admin
nginx/              | Static web https://k8s.gnuu.de
repo/               | GNUU Package repo https://k8s.gnuu.de/repo/ - currently uucp package is build with gnuu/uucp-build image and job.yaml to build & store the package in the repo
dashboard/          | Kubernetes-Dashboard https://dashboard.gnuu.de
uucp/               | UUCP Service Port 540
mail/               | Mail Service Port 25
matrix/             | Matrix Chat Community Gateway https://matrix.gnuu.de (incl. Bot to post webhooks from api service)
api                 | Webhook Payload Service for Dockerhub https://api.gnuu.de - will restart K8S deployments on new docker builds, see https://github.com/Praisebetoscience/dockerhub-webhook
wireguard/          | Wireguard Cluster VPN Service
k3s-clients         | RBAC for cluster user (administrative access with kubectl



Secret Handling
---------------

Rename `createsecret.sh.template` to `createsecret.sh`, fill out and apply to the cluster directly after namespace creation. 

* mysql app user credentials

* api key for webhook api




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


Matrix Server #gnuu:matrix.org
------------------------------

Create Cluster User for kubectl Access
--------------------------------------

A user `github` will created to access the namespace `gnuu` and
access rights for PODs and Deployments (review k3s-clients/github.yaml).
Create this user:

```
./createuser.sh
```

Credentials genrated in /opt/k3s-clients/gen/kube/github.kubeconfig

Can be used for Github Actions, Travis Pipelines a.s.o.
Script can generate more users (adapt username in script and RBAC file)


Cluster Access Through WireGuard:
---------------------------------


On the client:

Ubuntu 18.04:

```
apt install linux-image-virtual
apt install linux-headers-$(uname -r)
apt install software-properties-common
add-apt-repository ppa:wireguard/wireguard
```

Ubuntu 18.04/20.04:

```
apt install wireguard-dkms wireguard-tools
```


```
wg genkey | tee privatekey | wg pubkey > publickey
wg genpsk > preshared
```

On K3S:

deployment come from  https://raw.githubusercontent.com/squat/kilo/master/manifests/kilo-k3s.yaml

```
kubectl apply -f wireguard/kilo-k3s.yaml
```

Grab the public key from the server

```
kubectl -n kube-system exec -it kilo-6m5xx -- wg show
```

On the client

Create a file /etc/wireguard/wg0.conf

```
[Interface]
Address = 10.4.0.3/16
ListenPort = 51820
Privatekey = cDfULS/uimDH3onp0oV/IymwltHD+6GhYbbdJZ+GXXA=

[Peer]
PublicKey = 3SbEAgiKws0YpCNc7G1SW1R3++EuZkIrNsB/FTCYPRY=
AllowedIPs = 10.4.0.1/16,10.43.0.0/16
Endpoint = k8s.gnuu.de:51820
```

* Privatekey - was generated before

* PublicKey - was catched from server

There are also [Windows Client Packages](https://www.wireguard.com/install/) available.

On K3S:

adjust PublicKey with the catched Publickey from server

```
kubectl apply -f wireguard/peer.yaml
```

On the client:

```
wg-quick up wg0
ping 10.4.0.1
```


Notes: 

* presharedkeys seems unsupported

* beware same host/netmasks on both sides

* learn about [Roaming](https://www.wireguard.com/#built-in-roaming) (server-client-connection through NAT without endpoint)

* initial connection in roaming must start from client


Kubernetes connection from client:

* copy /etc/rancher/k3s/k3s.yaml from K3S as KUBECONFIG

* replace 127.0.0.1 with the K3S Wireguard Endpoint, e.g. 10.4.0.1

* test connection, `kubectl get ns`

