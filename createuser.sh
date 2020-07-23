#!/bin/bash
#
# Create and sign a client cert for K3S access
# 
# adapted from https://github.com/rancher/k3s/issues/684
#
# create a user 'github' in the namespace 'gnuu' and the cluster name 'default'
# adapt rights and name in ./k3s-clients/github.yaml
#
# kubectl apply -f ./k3s-clients/github.yaml
#
# adapt cluster url, ca_path is default K3S
# user/password credentials can managed in /etc/rancher/k3s/k3s.yaml (alternate)
# kubeconf will generate in "ws" dir and can be used with
# export KUBECONFIG=/opt/k3s-clients/gen/kube/github.kubeconfig
#
# execute the script with bash to generate kubeconf and certs:
# ./createuser.sh


ws=/opt/k3s-clients
day=30

clus_name="default"
clus_ns="gnuu"
user="github"
clus_url="https://10.4.0.1:6443"
ca_path=/var/lib/rancher/k3s/server/tls
rm -f $ca_path/*-ca.srl

ctx=gen && mkdir -p $ws/$ctx/{kube,keys} && cd $ws/$ctx
ca1=client-ca
generate="keys/u-"$user
echo -e "\033[32m#>>GEN-KEY\033[0m"
#openssl genrsa -out $generate.key 2048
openssl ecparam -name prime256v1 -genkey -noout -out $generate.key
openssl req -new -key $generate.key -out $generate.csr -subj "/CN=${user}@${clus_name}/O=key-gen"
openssl x509 -req -in $generate.csr -CA $ca_path/$ca1.crt -CAkey $ca_path/$ca1.key -CAcreateserial -out $generate.crt -days $day

ca2=server-ca
embed=true
ctx2="$user@$clus_name"
config="kube/$user.kubeconfig"
echo -e "\033[32m#>>KUBE-CONFIG\033[0m"	
kubectl --kubeconfig=$config config set-cluster $clus_name --embed-certs=$embed --server=$clus_url --certificate-authority=$ca_path/$ca2.crt
kubectl --kubeconfig=$config config set-credentials $user --embed-certs=$embed --client-certificate=$generate.crt  --client-key=$generate.key
kubectl --kubeconfig=$config config set-context $ctx2 --cluster=$clus_name --namespace=$clus_ns --user=$user
kubectl --kubeconfig=$config config set current-context $ctx2
kubectl --kubeconfig=$config --context=$ctx2 get pods
