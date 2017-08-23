# ssh-server docker image

You can use this docker image as you want.
But initially it was supposed to be used on top of kubernetes,
to ssh in kubernetes nodes without using any real bastion host.

## 1. Create a namespace:

```
kubectl get namespace ssh-server 2>/dev/null || \
kubectl create namespace ssh-server
```

## 2. Create a secret:

```
kubectl create secret generic ssh-pub-key \
--from-file=${HOME}/.ssh/id_rsa.pub \
-n ssh-server
```

## 3. Deploy ssh server:

```
kubectl create -f k8s.yaml
```

## 4. List kubernetes node ip addresses:

```
kubectl get nodes \
-L failure-domain.beta.kubernetes.io/zone,kubernetes.io/role -o wide | \
tr "-" "." | \
sed -E 's/ip\.(([0-9]+\.){4,4}).*internal/\1/' | \
sed -E 's/\. / /'
```

## 5. Make ssh tunnel via kubernetes api

```
while true; do \
    kubectl port-forward \
    $(kubectl get pods -n ssh-server | grep ssh-server | awk '{print $1}') \
    10022:22 -n ssh-server; \
    sleep 1; \
done
```

## 6. Prepare ~/.ssh/config

It is an example, you have substitute all IPs.

```
Host k8s-staging-bastion
    HostName 127.0.0.1
    User root
    port 10022

Host k8s-staging-master-a
    HostName 10.8.201.123

Host k8s-staging-master-b
    HostName 10.8.202.139

Host k8s-staging-master-c
    HostName 10.8.203.152

Host k8s-staging-node-a
    HostName 10.8.201.196

Host k8s-staging-node-b
    HostName 10.8.202.231

Host k8s-staging-node-c
    HostName 10.8.203.31

Host k8s-staging-* !k8s-staging-bastion
    ProxyCommand ssh -q -a -k -x -W %h:%p k8s-staging-bastion
    IdentityFile ~/.ssh/id_rsa.pub
    User admin
```

## 7. Now you can ssh like:

```
ssh k8s-staging-node-a
```