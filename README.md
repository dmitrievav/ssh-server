# Kubernetes ssh port forwarding

Here is an example of forwarding localhost port to MYSQL RDS port via k8s POD, but could be whatever you want.

## Create a secret:

```
kubectl create secret generic ssh-pub-key \
--from-file=${HOME}/.ssh/id_rsa.pub
```

## Deploy ssh server:

```
cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    description: "ssh server"
  labels:
    app: ssh-server
  name: ssh-server
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: ssh-server
    spec:
      containers:
      - name: ssh-server
        image: dmitrievav/ssh-server
        ports:
        - containerPort: 22
          name: ssh-server-port
        env:
        - name: SSH_PUB_KEY
          valueFrom:
            secretKeyRef:
              name: ssh-pub-key
              key: id_rsa.pub
EOF

```

## Redirect ssh port via kubernetes api to local host:

Run in separate console

```
while true; do \
    kubectl port-forward $(kubectl get pod -l app=ssh-server -o jsonpath='{.items[0].metadata.name}') 2222:22; \
    sleep 1; \
done
```

## Make ssh tunnel to RDS via ssh server and map it to local host 3306

Run in separate console

```
while true; do \
    lsof -Pni :3306 > /dev/null 2>&1 || ssh root@127.0.0.1 -p 2222 -f -N \
    -L 3306:REDACTED.eu-central-1.rds.amazonaws.com:3306
    sleep 1; \
done
```

## Copy sql file to current folder

```
ls -1
db_dump-20190529.sql
```

## Import sql files to remote DB

```
docker run --name=mysql-client \
  -it \
  -v $(PWD):/tmp \
  --rm mysql \
    sh -c " \
      apt-get update; \
      apt-get install pv; \
      pv /tmp/db_dump-20190529.sql | \
      mysql \
        -hhost.docker.internal \
        -uaccesscontrol -Daccesscontrol -psome_password
    "
```

## Clean up

```
kubectl delete deployment ssh-server
kubectl delete secret ssh-pub-key
```