# ELK-deployment


![Running Pods](images/elk-deployment.svg)


In this tutorial, I'll guide you through a step-by-step process for setting up the ELK stack (Elasticsearch, Logstash, and Kibana) and Filebeat on AKS cluster using YAML configuration files.

## Prerequisites

- A running Kubernetes cluster

## Step 1: Create a Namespace

First, create a namespace for the ELK stack:

```sh
kubectl create namespace elk
```

## Step 2: Filebeat Configuration
##### Filebeat ConfigMap (filebeat-configmap.yaml)
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
##### Filebeat DaemonSet (filebeat-daemonset.yaml)
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
          image: docker.elastic.co/beats/filebeat:7.17.0
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
##### Apply the Filebeat ConfigMap & Deamonset
```sh
kubectl -n elk apply -f filebeat-configmap.yaml
kubectl -n elk apply -f filebeat-daemonset.yaml 
```

## Step 3: Elasticsearch Configuration
##### Elasticsearch (elasticsearch-statefulset.yaml):

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
      containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
          ports:
            - containerPort: 9200
          env:
            - name: discovery.type
              value: "single-node"
          resources:
            limits:
              memory: "2Gi"
              cpu: "1"

```

##### Elasticsearch Service (elasticsearch-service.yaml):

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
##### Apply the Elasticsearch StatefulSet and Service files:

```sh
kubectl -n elk apply -f elasticsearch-statefulset.yaml
kubectl -n elk apply -f elasticsearch-service.yaml
```

## Step 4: Logstash Configuration

##### Logstash Deployment & ConfigMap (logstash.yaml):

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
          image: docker.elastic.co/logstash/logstash:7.17.0
          ports:
            - containerPort: 5044
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
        index => "logstash-%{+YYYY.MM.dd}"
      }
    }
```

##### Logstash Service (logstash-service.yaml):

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
##### Apply the Logstash Deployment, CofigMap and Service
```sh
kubectl -n elk apply -f logstash.yaml
kubectl -n elk apply -f logstash-service.yaml
```

## Step 5: Kibana Configuration
##### Kibana Deployment (kibana.yaml)

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
          image: docker.elastic.co/kibana/kibana:7.17.0 
          ports:
            - containerPort: 5601
          env:
            - name: ELASTICSEARCH_HOSTS
              value: "http://elasticsearch:9200"

```

##### Kibana Service (kibana-service.yaml):

```sh
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: elk
spec:
  type: Loadbalancer
  selector:
    app: kibana
  ports:
    - protocol: TCP
      port: 5601
      targetPort: 5601
```

##### Apply the Kibana Deployment and Service:

```sh
kubectl -n elk apply -f kibana.yaml
kubectl -n elk apply -f kibana-service.yaml
```

##### Next, check for all the running pods:

```sh
kubectl -n elk get pods 
```

![Running Pods](running-pods.png)


Run the command to get the LoadBalancerIP. Copy it and paste it on your favourite browser with port **<``LoadbalancerIP``>:5601**.


```sh
kubectl -n elk get svc 
```
<!-- ![Running Pods](running-pods.png) -->

Congratulations on setting up ELK and visualising your log data on Kibana.

## Conclusion

This structure provides a comprehensive guide for deploying the ELK Stack (Elasticsearch, Kibana, and Logstash) on Azure AKS using YAML configuring files.