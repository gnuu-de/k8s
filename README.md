K8S Deployment GNUU
===================

Contents
--------


files/dirs          | description
------------------- | -------------------------------------------------
calico.yaml         | CNI network deployment (replace of flannel)
clusterissuer.yaml  | Let's Encrypt Cluster Issuer for Cert Manager
namespace.yaml      | Creates Namespace gnuu
pvc.yaml            | Creates a volume storage, mostly mount on /data with openebs
local-path.yaml     | Optional [local-path PVC](https://rancher.com/docs/k3s/latest/en/storage/) instead using openebs
rancher.yaml        | Value file for Rancher Deployment (optional)
apps                | Backend Web Services user + admin
active/             | News config web https://www.gnuu.de/config/
nginx/              | Static web https://www.gnuu.de
repo/               | GNUU Package repo https://www.gnuu.de/repo/ - currently uucp package is build with gnuu/uucp-build image and job.yaml to build & store the package in the repo
dashboard/          | Kubernetes-Dashboard https://dashboard.gnuu.de
uucp/               | UUCP Service Port 540
mail/               | Mail Service Port 25
matrix/             | Matrix Chat Community Gateway https://matrix.gnuu.de (incl. Bot to post webhooks from api service)
api                 | Webhook Payload Service for Dockerhub https://api.gnuu.de - will restart K8S deployments on new docker builds, see https://github.com/Praisebetoscience/dockerhub-webhook
wireguard/          | Wireguard Cluster VPN Service
k3s-clients         | RBAC for cluster user (administrative access with kubectl
aio                 | UUCP Client for send and receive news/mail (integration test)
backup/             | Backup job to sync data to S3



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

IPv6 DualStack (Kubernetes 1.21+)
---------------------------------

Requires start options of k3s in `/etc/systemd/system/k3s.service` described in `calico_ipv6.yaml`.:

```
ExecStart=/usr/local/bin/k3s \
    server \
  --no-flannel \
  --disable servicelb \
  --kube-apiserver-arg service-node-port-range=1-65535 \
  --kube-apiserver-arg service-cluster-ip-range=10.43.0.0/16,fc45:a71:55a6:1:2:1::/116 \
  --kube-apiserver-arg feature-gates="IPv6DualStack=true" \
  --kube-controller-manager-arg cluster-cidr=10.42.0.0/24,fc45:a71:55a6:1:2:2::/96 \
  --kube-controller-manager-arg feature-gates="IPv6DualStack=true" \
  --kube-controller-manager-arg service-cluster-ip-range=10.43.0.0/16,fc45:a71:55a6:1:2:1::/116 \
  --kube-controller-manager-arg node-cidr-mask-size-ipv4=24 \
  --kube-controller-manager-arg node-cidr-mask-size-ipv6=96 \ # 118
  --kubelet-arg feature-gates="IPv6DualStack=true" \
  --kube-proxy-arg feature-gates="IPv6DualStack=true" \
  --kube-proxy-arg cluster-cidr=10.42.0.0/24,fc45:a71:55a6:1:2:2::/96
```

Reload Daemin and Restart K3S

```
systemctl daemon-reload
systemctl restart k3s.service
```
Adapat IPv4 and IPv6 pool addresses if changes from k3s start script and ensure IPv6 NAT. 

```
"ipam": {
	              "type": "calico-ipam",
	              "assign_ipv4": "true",
	              "assign_ipv6": "true",
	              "nat-outgoing": "false",
	              "ipv4_pools": ["10.42.0.0/24"],
	              "ipv6_pools": ["fd45:a71:55a6:1:2:2::/96"]
	          },
---
- name: CALICO_IPV4POOL_CIDR
	              value: "10.42.0.0/24"
	            - name: CALICO_IPV6POOL_CIDR
	              value: "fd45:a71:55a6:1:2:2::/96"
---
- name: CALICO_IPV6POOL_NAT_OUTGOING
	              value: "true"
         
...
- name: FELIX_IPV6SUPPORT
	              value: "true"
```

Deployed Calico from the same manifest

```
kubectl apply -f calico_ipv6.yaml
```

Check Calico Controller and Node agent PODs are running

```
# kubectl -n kube-system get pods | grep cali
calico-node-twxmf                          1/1     Running     0          34m
calico-kube-controllers-74b8fbdb46-slhxn   1/1     Running     0          34m
```

Check IP Pools

```
# kubectl get ippools.crd.projectcalico.org
NAME                  AGE
default-ipv4-ippool   39m
default-ipv6-ippool   39m
```

Check IPv4 and IPv6 address assigned to PODs:

```
bash-5.0# ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 72:51:2B:80:AE:E4
          inet addr:10.42.0.194  Bcast:10.42.0.194  Mask:255.255.255.255
          inet6 addr: fd45:a71:55a6:1:2:3000:0:f01/128 Scope:Global
          inet6 addr: fe80::7051:2bff:fe80:aee4/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1440  Metric:1
          RX packets:25 errors:0 dropped:0 overruns:0 frame:0
          TX packets:25 errors:0 dropped:1 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2674 (2.6 KiB)  TX bytes:2590 (2.5 KiB)

```

Check connectivity 

```
bash-5.0# ping ipv4.google.com
PING ipv4.google.com (172.217.19.78): 56 data bytes
64 bytes from 172.217.19.78: seq=0 ttl=58 time=10.722 ms
64 bytes from 172.217.19.78: seq=1 ttl=58 time=10.592 ms

bash-5.0# ping ipv6.google.com
PING ipv6.google.com (2a00:1450:4016:80a::200e): 56 data bytes
64 bytes from 2a00:1450:4016:80a::200e: seq=0 ttl=118 time=21.472 ms
64 bytes from 2a00:1450:4016:80a::200e: seq=1 ttl=118 time=21.450 ms

```

Deployed Traefik from `traefik.yaml` (to apply in /var/lib/rancher/k3s/server/manifests/`) Helm Operator will automatically pickup and deploy a new version of Traefik Helm Chart. Important is the option `ipFamilyPolicy: RequireDualStack`. If the public ServiceIP stays in state `Pending` add the node ip-addresses as here.


Deployed Service Loadbalancer from `svclb-traefik.yaml` This DaemonSet use a special version of klipper-lb, which allows to configure IPv6 services and prevent duplicate configured HostPorts (for IPv4 and IPv6).


TLS Option on Traefik v2 Ingress
--------------------------------

To provide a more secure SSL service on Traefik Ingress there is a default TLSOption deployed from `nginx/tlsoption.yaml`.
Description of the feature here: https://doc.traefik.io/traefik/v2.2/https/tls/#tls-options


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

AIO
---

GNUU All-in-One (gnuuaio)

aio is a client app for send and receive news and e-mails. You
can use the client for your own:

* replace 6913306960783 with your own site id in aio/configmaps*
* replace password in configmap-aio-uucp.yml
* a web service on port 80 appears, extend with Ingress service
* browse to the Ingress address
* you will prompt on aio-0:
* username/password is linux/linux
* start alpine
* you can send/receive e-mails to 6913306960783.gnuu.de (or your site)
* depends on your newsfeed you can subscribe some newsgroups (e.g. de.test)
* cron will batch and transmit every 5 minutes packages from/to uucp.gnuu.de

Please note: there is no permanent storage attached, all data will be lost
after restart. If you need permanent data, extend the statefulset with volumes
(e.g. /var/spool, or /var)

