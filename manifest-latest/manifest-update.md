# ELK Stack Update Guide

This guide provides instructions for updating the components of the ELK stack: Filebeat, Logstash, Elasticsearch, and Kibana.

## Prerequisites

- Backup your current configurations and data.

## Update Steps

### 1. Filebeat

1. **Update the Filebeat DaemonSet:**
    ```sh
    containers:
        - name: filebeat
          image: docker.elastic.co/beats/filebeat:8.17.0
    ```


### 2. Logstash

1. **Update the Logstash Deployment:**
    ```sh
    containers:
        - name: logstash
          image: docker.elastic.co/logstash/logstash:8.17.0

    ```
    As a best practice I implemented secrets.yaml to pass my creadential as environmental variable. Not recommended if using **Hashiscorp Vault**.

    Secret:
    ```sh
    apiVersion: v1
    kind: Secret
    metadata:
        name: elasticsearch-secret
    type: Opaque
    data:
        username: dXNlcm5hbWU=  # Base64 encoded
        password: cGFzc3dvcmQ=  # Base64 encoded
    ```
    
    env:
    ```sh
    env:
    - name: USERNAME
        valueFrom:
        secretKeyRef:
            name: my-secret
            key: username
    - name: PASSWORD
        valueFrom:
        secretKeyRef:
            name: my-secret
            key: password
    ```


### 3. Elasticsearch

1. **Upgrade Elasticsearch Statefulset:**
    ```sh
    containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:8.17.0
    ```

2. **Added security configurations:**
    i)    ``xpack.security.enabled``: **enables users to authenticate with credentials** when accessing elasticsearch. Enables RBAC and encryption(HTTPS). 
    ```sh
    - name: xpack.security.enabled
      value: "true"
    ```
    ii)    ``xpack.security.enrollment.enabled``: **enables new Nodes and Kibana to join the cluster by providing enrollment tokens**. After the cluster is fully set up and operational, you might **disable** this to avoid exposing enrollment tokens.
    ```sh
    - name: xpack.security.enrollment.enabled
      value: "true"
    ```
    iii) Similarly to Logstash, I used secrets.yaml to pass my credentials.   However, this approach is not recommended if you are using HashiCorp Vault to manage your credentials, as Vault provides a more secure and dynamic way to handle secrets.
    Secrets:
    ```sh
    apiVersion: v1
    kind: Secret
    metadata:
        name: elasticsearch-secret
        namespace: elk
    type: Opaque
    data:
        password: cGFzc3dvcmQ=  # Base64 encoded
    ```

   
3. **PV & PVC**

    I added PV and PVC to persist the data beyond the lifecycle of the pod.


4. **Use ``discovery.type`` only in Development Environment**
For **production environments**, use the following to configure a scalable cluster:

This setup allows the cluster to scale beyond 3 nodes.
```sh
- name: discovery.seed_hosts
  value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
- name: cluster.initial_master_nodes
  value: "elasticsearch-0"
```


### 4. Kibana

1. **Upgrade Kibana:**
    ```sh
    containers:
        - name: kibana
          image: docker.elastic.co/kibana/kibana:8.17.0
    ```

2. **Added configmap**
This will mount the data into the kibana container.
    ```sh
    apiVersion: v1
    kind: ConfigMap
    metadata:
        name: kibana-config
        namespace: elk
    data:
        kibana.yml: |
            server.name: kibana
            server.host: "0.0.0.0"
            elasticsearch.hosts: ["http://elasticsearch:9200"]
            elasticsearch.serviceAccountToken: "<elastic_token>"
            xpack.security.encryptionKey: "a_secure_random_key"
            xpack.encryptedSavedObjects.encryptionKey: "a_secure_random_key"
            xpack.reporting.encryptionKey: "a_secure_random_key"
            xpack.screenshotting.browser.chromium.disableSandbox: true

    ```

3. **Generates a secure random keys of 32 characters:**
    ```sh
    openssl rand -base64 32
    ```


## Getting Started

### 1. Filebeat

filebeat-daemonset.yaml
```sh
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: elk
  labels:
    k8s-app: filebeat
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      containers:
        - name: filebeat
          image: docker.elastic.co/beats/filebeat:8.17.0
          args: [
            "-c", "/etc/filebeat.yaml",
            "-e"
          ]
          volumeMounts:
            - name: config
              mountPath: /etc/filebeat.yaml
              subPath: filebeat.yaml
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
        - name: config
          configMap:
            name: filebeat-config
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
```

filebeat-configmap.yaml

```sh
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: elk
data:
  filebeat.yaml: |
    filebeat.inputs:
      - type: container
        paths:
          - /var/log/containers/*.log
        processors:
          - add_kubernetes_metadata:
              in_cluster: true

    output.logstash:
      hosts: ["logstash:5044"]
```

filebeat-rbac.yaml

```sh
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
  - kind: ServiceAccount
    name: default
    namespace: elk
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
```
Apply Filebeat

```sh
kubectl -n elk apply -f filebeat-daemonset.yaml
kubectl -n elk apply -f filebeat-configmap.yaml
kubectl -n elk apply -f filebeat-rbac.yaml
```

### 2. Logstash

logstash.yaml

```sh
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
  namespace: elk
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash
    spec:
      containers:
        - name: logstash
          image: docker.elastic.co/logstash/logstash:8.17.0
          ports:
            - containerPort: 5044
          env:
            - name: ELASTICSEARCH_USER
              valueFrom:
                secretKeyRef:
                  name: elasticsearch-secret
                  key: elastic-username
            - name: ELASTICSEARCH_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: elasticsearch-secret
                  key: elastic-password
          volumeMounts:
            - name: config-volume
              mountPath: /usr/share/logstash/pipeline/
      volumes:
        - name: config-volume
          configMap:
            name: logstash-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-config
  namespace: elk
data:
  logstash.conf: |
    input {
      beats {
        port => 5044
      }
    }
    output {
      elasticsearch {
        hosts => ["http://elasticsearch:9200"]
        user => "${ELASTICSEARCH_USER}"
        password => "${ELASTICSEARCH_PASSWORD}"
        index => "logstash-%{+YYYY.MM.dd}"
      }
    }

---
apiVersion: v1
kind: Secret
metadata:
  name: elasticsearch-secret
  namespace: elk
type: Opaque
data:
  elastic-username: ZWxhc3RpYw== # Base64 encoded value of "elastic"
  elastic-password: ZWxrcGFzc3dvcmQ= # Base64 encoded value of "elkpassword"
```

logstash-service.yaml

```sh
apiVersion: v1
kind: Service
metadata:
  name: logstash
  namespace: elk
spec:
  ports:
    - port: 5044
      targetPort: 5044
      protocol: TCP
  selector:
    app: logstash
```

Apply Logstash

```sh
kubectl -n elk apply -f logstash.yaml
kubectl -n elk apply -f logstash-service.yaml
```

### 3. Elasticsearch

elasticsearch-statefulset.yaml

```sh
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: elk
spec:
  serviceName: elasticsearch
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      initContainers:
        - name: fix-permissions
          image: busybox
          command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
          volumeMounts:
            - name: elasticsearch-data
              mountPath: /usr/share/elasticsearch/data
      containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:8.17.0
          ports:
            - containerPort: 9200
            - containerPort: 9300
          env:
            - name: discovery.type
              value: "single-node"
            - name: xpack.security.enabled
              value: "true"
            - name: xpack.security.enrollment.enabled
              value: "true"
            - name: ELASTIC_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: elasticsearch-secret
                  key: elastic-password
          resources:
            requests:
              memory: "1Gi"
              cpu: "500m"
            limits:
              memory: "2Gi"
              cpu: "1"
          volumeMounts:
            - name: elasticsearch-data
              mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
```

elasticsearch-secret.yaml

```sh
apiVersion: v1
kind: Secret
metadata:
  name: elasticsearch-secret
  namespace: elk
type: Opaque
data:
  elastic-username: ZWxhc3RpYw== # Base64 encoded value of "elastic"
  elastic-password: ZWxrcGFzc3dvcmQ= # Base64 encoded value of "elkpassword"
```

elasticsearch-service.yaml
```sh
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: elk
spec:
  type: ClusterIP
  selector:
    app: elasticsearch
  ports:
    - protocol: TCP
      port: 9200
      targetPort: 9200
```

Apply elasticsearch

```sh
kubectl -n elk apply -f elasticsearch-statefulset.yaml
kubectl -n elk apply -f elasticsearch-secret.yaml
kubectl -n elk apply -f elasticsearch-service.yaml
```

### 4. Generate Token

Run this command to create a service account token for Kibana to use to access elasticsearch:

```sh
kubectl -n elk exec $(kubectl get pods -n elk -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- bin/elasticsearch-service-tokens create elastic/kibana kibana-token
```
Copy the generated token and add it to kibana-config.yaml:

```sh
elasticsearch.serviceAccountToken: "<your-service-account-token>"
```

### 5. Kibana

kibana.yaml

```sh
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: elk
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
        - name: kibana
          image: docker.elastic.co/kibana/kibana:8.17.0
          ports:
            - containerPort: 5601
          volumeMounts:
            - name: kibana-config
              mountPath: /usr/share/kibana/config/kibana.yml
              subPath: kibana.yml
          resources:
            requests:
              memory: "2Gi"
              cpu: "500m"
            limits:
              memory: "4Gi"
              cpu: "1"
      volumes:
        - name: kibana-config
          configMap:
            name: kibana-config
```

kibana-configmap.yaml

```sh
apiVersion: v1
kind: ConfigMap
metadata:
  name: kibana-config
  namespace: elk
data:
  kibana.yml: |
    server.name: kibana
    server.host: "0.0.0.0"
    elasticsearch.hosts: ["http://elasticsearch:9200"]
    elasticsearch.serviceAccountToken: "AAEAAWVsYXN0aWMva2liYW5hL2tpYmFuYS10b2tlbjpWcHBrc3J0aFRPZVdoaGVMdFRldi1R"
    xpack.security.encryptionKey: "KMbIUEmceO/wCMlSv66rjKg8GTvdt4kkO4hY4Cp991E="
    xpack.encryptedSavedObjects.encryptionKey: "HXeldtxFPKSua7FLBP7yO/20f02Yk3SiEnyTAe2pzfU="
    xpack.reporting.encryptionKey: "+qJ7jH1HuQcFWRQJymsoF7Csu7tN/GoUyHSY2P4up5I="
    xpack.screenshotting.browser.chromium.disableSandbox: true
```

kibana-service.yaml

```sh
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: elk
spec:
  type: LoadBalancer
  selector:
    app: kibana
  ports:
    - protocol: TCP
      port: 5601
      targetPort: 5601
```
Apply kibana

```sh
kubectl -n elk apply -f kibana.yaml
kubectl -n elk apply -f kibana-configmap.yaml
kubectl -n elk apply -f kibana-service.yaml
```




## Verify your configuration

Check if Kibana can reach Elasticsearch:
```sh
kubectl -n elk exec pod/<kibana-pod-name> -- curl -u "elastic:<password>" http://<elasticsearch-host>:9200
```

Verify the token by making a direct curl request to Elasticsearch to ensure it is working:
```sh
kubectl -n elk exec pod/<kibana-pod-name> -- curl -H "Authorization: Bearer <Kibana-Token>" http://<elasticsearch-host>:9200
```

Verify the credentials using the Elasticsearch API are correct:
```sh
kubectl -n elk exec pod/<elasticsearch-pod-name> -- curl -X GET -u elastic:<password> "http://<elasticsearch-host>:9200"
```

Verify that logs are indexed in Elasticsearch under the ``logstash-*`` index:
```sh
curl -u elastic:<password> http://elasticsearch:9200/_cat/indices?v
```

Verify the environment variable in the Kibana pod:
```sh
kubectl -n elk exec -it pod/elasticsearch-<pod-id> -n elk -- env | grep ELASTIC_PASSWORD
```


# Optional Info
## Adding Users

Elasticsearch provides built-in users, such as:

**elastic**: The superuser account with full cluster access.
**kibana_system**: Used by Kibana to communicate with Elasticsearch.

#### 1. Create Custom Users:
If you need additional users, create them using the ``_security/user`` API.`
```sh
curl -X POST -u elastic "http://<elasticsearch-host>:9200/_security/user/my_user" -H "Content-Type: application/json" -d '{
  "password": "mypassword",
  "roles": ["read_only"]
}'
```

#### 2. Set Passwords for Built-in Users:
1. Using ``elasticsearch-setup-passwords`` tool. This tool will prompt you to set passwords for the built-in users

Access the elasticsearch pod
```sh
kubectl -n elk exec -it pod/elasticsearch-0 -- bash
```
```sh
./bin/elasticsearch-setup-passwords interactive
```

2. Alternatively, use the auto-setup mode:
```sh
./bin/elasticsearch-setup-passwords auto
```
#### 2b. Reset Passwords for specific User:
```sh
curl -X POST -u elastic "http://<elasticsearch-host>:9200/_security/user/elastic/_password" -H "Content-Type: application/json" -d '{
  "password": "newpassword"
}'
```

#### 3. Assigning Roles(RBAC) to Users:
Roles define the permissions for users. Use the ``_security/role`` API or the ``roles.yml`` file to create and assign roles.

i) Using ``_security/role``:

```sh
curl -X POST -u elastic "http://<elasticsearch-host>:9200/_security/role/read_only" -H "Content-Type: application/json" -d '{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["*"],
      "privileges": ["read"]
    }
  ]
}'
```
#### 4. Testing Authentication
Access the Elasticsearch Pod
```sh
kubectl -n elk exec -it pod/elasticsearch-0 -- bash
```
Verify credentials
```sh
curl -X GET -u <username>:<password> "http://<elasticsearch-host>:9200"
```

## SSL Certificates

**1. Generating SSL Certificates**
You can use the ``elasticsearch-certutil`` tool to generate the necessary certificates:
Run the following command in the Elasticsearch container

```sh
kubectl -n elk exec -it $(kubectl get pods -n elk -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- bin/elasticsearch-certutil http
```
This will prompt you to create a certificate. Follow the prompts to generate the certificate files.

**2. Extract the Generated Certificate:**
After the certificates are generated, copy them from the container to your local machine:

```sh
kubectl -n elk cp $(kubectl get pods -n elk -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}'):/usr/share/elasticsearch/elasticsearch-http.p12 ./elasticsearch-http.p12

```
**3. Mount the Certificate in the Pod:**
- Store the certificate in a Kubernetes secret:
```sh
kubectl -n elk create secret generic elasticsearch-http-cert --from-file=elasticsearch-http.p12
```

- Update your Elasticsearch manifest to mount the secret as a volume:

```sh
volumeMounts:
  - name: http-cert
    mountPath: /usr/share/elasticsearch/config/certs
    readOnly: true
volumes:
  - name: http-cert
    secret:
      secretName: elasticsearch-http-cert
```

**4 Update Elasticsearch Configuration:** Add the following to your Elasticsearch configuration (either in elasticsearch.yml or as environment variables in your manifest):

```sh
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/elasticsearch-http.p12
  keystore.password: <your-password>
```

**5. Apply Changes:**

```sh
kubectl -n elk apply -f elasticsearch-configmap.yaml
```
Restart the Elasticsearch pod:

```sh
kubectl -n elk rollout restart statefulset/elasticsearch
```

## Conclusion

You have successfully updated the ELK stack components. Ensure to monitor the logs for any issues and verify that data is being processed correctly.
