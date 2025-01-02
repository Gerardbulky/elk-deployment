# Deploying Container Images With Azure Container Registry(ACR)

![Ports](images/ELK-Stack.png)

When working with Azure, setting up the right environment is the first step toward managing your applications effectively. 

In this guide, we'll walk through the process of creating: 
- ``Resource Group``
- ``Virtual Machine (VM)`` 
- ``Clone the repository``
- ``Building a Docker image``
- ``Push Image to an Azure Container Registry (ACR)``
- ``Deploy Image Azure Kubernetes Service (AKS)``

## Prerequisites
- An active Azure account.

## Create a Resource Group
A resource group is a container for managing your Azure resources. A resource group is essential because deleting a resources group will delete all the resources( eg, VM, cluster), all at once, instead of deleting them individually yourself. To create a new resource group, follow the steps below.

Go to your Azure portal and in the search bar, type ``resource`` and click on the first one.

![Resouce -group](images/resource-group.png)


Now click on **``Create``** and add your Resource group name as shown below:

![Resouce -group](images/resource-group-name.png)

Click on the ``Next : Tags`` button below which will take you to the tag page. Add a tag as shown below:
**Note**
    Tagging your resources is important for tracking usage and managing costs across different environments effectively. 

![Resouce -group](images/resource-tag.png)

Then click on the **``Next:Review + create``** button, which will take you to the page shown below:

![Resouce -group](images/resource-group-validate.png)

Click **``Create``**. This will create your resource group.

## Create a Virtual Machine(VM)
##### 1. Setting up
Next, we will create a VM within our resource group. In this VM we will install and configure **``kubectl``**, so we can communicate with the K8s cluter from the **CLI**. To create a VM, follow the steps below:

Go to your Azure portal and in the search bar, type ``virtual`` and click on the first one.

![Resouce -group](images/vm.png)

Click on it, then click on **``Create``**, then **``Azure Virtual machine``**

Fill the information as show below:

![Resouce -group](images/vm-setup.png)

![Resouce -group](images/vm-setup2.png)

Leave everything as it is and click on **``Tags``**

Put in your tags, then click on **``Review + create``**.

![Resouce -group](images/tags.png)

You will see all the information about your VM to be created. Click **``Create``**

![Resouce -group](images/create-vm.png)

Now click on the **``Download``** button to download your RSA Key

![Resouce -group](images/rsa-key.png)

Congratulations, That's it with setting up your VM. 

##### 2a. Connect via SSH
To connect to the VM, click on **``connect``**, **``connect``**, then click on **``Select``**

A window will pop up on the side of your screen to **``copy and execute SSH command``**

Copy the command and paste it on your Notepad.

![Resouce -group](images/connect-via-ssh.png)

##### 2b. Connect via CLI
Now create a folder on your PC, name it anything you want. Put the key you created into the folder. Right-click on the folder and open it using a CLI. In my case I am using Git Bash.

![Resouce -group](images/git-bash.png)

Write **``ls``** on the your terminal and you will be to see your key.

![Resouce -group](images/your-key.png)

Now to connect to your VM. Paste the **``SSH command``** you copied before on the terminal. Replace **`` ~/.ssh/id_rsa.pem``** with your key.pem.

```sh 
ssh -i elk-vm_key.pem elk-user@20.235.147.13
```

![Resouce -group](images/replaced-key.png)


Press **``enter``** and type **``yes``** to confirm.

![Resouce -group](images/fingerprint.png)

Congratulations! You have now SSH into your VM and now connected to your VM from your CLI.

![Resouce -group](images/ssh-into-vm.png)



#### Installing Docker

```sh
# Installing Docker 
#!/bin/bash
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker elk-user
sudo systemctl restart docker
sudo chmod 777 /var/run/docker.sock
```


## Clone the repository

To build the image locally, first we will clone the repository and cd into the flask-app directory that contains the Dockerfile and use the commands to build the docker image. Run the commands below:


```sh
git clone https://github.com/Gerardbulky/ELK-Stack-Deployment.git
```

```sh
cd ELK-Stack-Deployment/flask-app
```

```sh
docker build -t flask-image:latest .
```
Run the image using:
```sh
docker run -d -p 5000:5000 flask-image:latest
```

Check if the docker image is running:
```sh
docker ps
```

<!-- ##### How It Works:
When you run a container with -p 5000:80, any traffic sent to port 5000 on the `` host `` will be forwarded to port 80 inside the container. 
**For example:**
    If the application is running inside the container on port 80, you can access it from your host machine via http://<<IP:address>>:5000  


![Ports](images/ports.png) -->



#### Update Network Security Group Rules
In other to access our application over Port 5000, we need to update the NSG rules.

Go to ``Virtual machines``, then go to ``Network settings`` and Click on it:

![Netwrok Settings](images/nsg.png)

Click on `` Create port rule ``

![Netwrok Settings](images/inbound-port.png)

Fill the information as below and click ``Add``.

![Netwrok Settings](images/port.png)

#### Access Application
Now go to your web browser, and add your Virtual machines IP Address and port 5000 as shown below:

http://<<IP:address>>:5000

## Build & Push Image To Container Registry
Azure Container Registry allows us to store, build and deploy images on Azure. We will need to create a registry to store our image.

We will need to install the Azure CLI to create our ACR account.

#### Install Azure CLI
```sh
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

```sh
az login
```

Copy the URL and paste to your favourite browser and the code. This will log you into your Azure account from your terminal.

![Netwrok Settings](images/url-code.png)

#### Create Azure Registry

Replace the ``<container_registry_name>`` with your container name. It should be in small letters and no hyphen(-) and it should be unique. My container name is ``elkcontainer``, use something else:

```sh
az acr create --resource-group Elk-demo \
              --name <container_registry_name> \
              --sku Basic \
              --tags Tags=elk-tag
```
    

After creating Container Registry, you can view that by going to the Azure portal and on the search bar, type ``container registries`` and click on it.

![Ports](images/container-registries.png)

That will take you to the ACR portal. Take note on the ``login server url`` as you will need it to push your image to your image to the container registry.

![Ports](images/azure-login-url.png)


#### Build & Push Image To Container Registry 
Before pushing the image, we must authenticate with the Azure Container Registry(ACR). In the Azure CLI, run the command to log you into the ACR:

```sh
az acr login --name <container_registry_name>
```
Build the Image:

```sh
docker build -t <container_registry_name>.azurecr.io/flask-image:latest .
```
Push Image:
```sh
docker push <container_registry_name>.azurecr.io/flask-image:latest
```
After the push, verify that the image is in your Azure Container Registry:
```sh
az acr repository list --name <container_registry_name> --output table
```

## Deploying Image to AKS
To create an AKS cluster, you can follow the steps below.
If you're experienced with Azure, you can skip the networking setup. If you're new to AKS or Azure, I recommend following each step to understand the related services better.

Go to your Azure portal and in the search bar, type ``kubernetes`` and click on the first one. 

![Ports](images/k8s.png)

Click on **Create**, then Kubernetes cluster.

![Ports](images/k8s-cluster.png)

Select your resource group name. Click on "Next" to proceed.


![Ports](images/azure-vnets.png)

Provide the name of your Virtual Network and click on Next.

In the ``Node pools``, update the name and click ``Update``.

![Ports](images/node-name.png)


In the ``Networking``, Select kubelet and Calico as Network policy.

![Ports](images/network.png)

Now go to ``Tags``, add your tag and click on ``Review + Create``

![Ports](images/k8s-tag.png)

Once your deployment is complete, click on ``Go to resource``.

![Ports](images/go-to-resource.png)


Click on **Connect**.

![Ports](images/connect-to-cluster.png)

We will run these commands in our terminal to connect to our cluster but first, we need to kubectl.

#### Install Kubectl

```sh
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
```

![Ports](images/kubectl-install.png)


```sh
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl.sha256
```

![Ports](images/kubectl-install-2.png)


```sh
sha256sum -c kubectl.sha256
```

![Ports](images/kubectl-install-3.png)

```sh
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
```

![Ports](images/kubectl-install-4.png)

```sh
kubectl version --client
```

![Ports](images/kubectl-version.png)


#### Connect Azure AKS to CLI
From your CLI, run both commands to connect to AKS.

![Ports](images/connect-to-cluster.png)

![Ports](images/connect-to-aks.png)


Now, you can run the command to list the nodes.


```sh
kubectl get nodes
```

![Ports](images/kubectl-get-pods.png)








#### Grant AKS Access to ACR
Before running the kubectl apply, we need to grant access to the ACR and to do so, we need to attach the ACR to the AKS cluster so it can pull the image.

```sh
az aks update -n <aks-cluster-name> -g <resource-group-name> --attach-acr <acr-name>
```
To confirm the AKS cluster can pull images from ACR, run:

```sh
az acr list --resource-group <resource-group-name> --query "[].{acrLoginServer:loginServer}" --output table
```

It will display the ``registry login server``
![registry-login-server](images/registry-login-server.png)



#### Deploy Application yaml
Now, let’s try to deploy the Apache application on AKS

From your terminal, 

```sh
nano deployment.yaml
```

Paste the code snippet. Replace  ``<container-registry-name>`` with your ACR name.

```sh
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-deployment
  labels: 
    app: flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-app
  template: 
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask-container
        image: <container-registry-name>.azurecr.io/flask-image:latest
        ports:
        - containerPort: 5000
```
Type ``Ctrl + x`` to exit
Type ``y + Enter``

```sh
kubectl apply -f deployment.yml
```

![registry-login-server](images/kubectl-apply.png)


```sh
kubectl get pods
```

![registry-login-server](images/kubectl-get-pods.png)


Now, Let's host the application outside of the Kubernetes Cluster by creating a service for the application.

```sh
nano service.yaml
```


```sh
apiVersion: v1
kind: Service
metadata:
  name: flask-service
spec:
  selector:
    app: flask-app
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 5000
```

Type ``Ctrl + x`` to exit
Type ``y + Enter``

```sh
kubectl apply -f service.yaml
```
![registry-login-server](images/service.png)

```sh
kubectl get svc
```

![registry-login-server](images/external-ip.png)

Copy  the ``EXTERNAL-IP Address and paste on your favourite browser and add port 5000, to view your application Live.





# Setting Up ELK Stack on Kubernetes: A Step-by-Step Guide
### ``** NOTE: I need to explain why daemonset, stableset, configMap is used **``

In this tutorial, I'll guide you through a step-by-step process for setting up the ELK stack (Elasticsearch, Logstash, and Kibana) on AKS cluster using YAML configuration files. We will setup NGINX Ingress and cert manager to encrypt our KIBANA dashboard over a secured HTTPS.

## Prerequisites

- A running Kubernetes cluster
- `kubectl` installed and configured to interact with your cluster
- Helm package manager installed

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
kubectl apply -f filebeat-configmap.yaml
kubectl apply -f filebeat-daemonset.yaml 
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
      initContainers:
        - name: fix-permissions
          image: busybox
          command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
          volumeMounts:
            - name: elasticsearch-data
              mountPath: /usr/share/elasticsearch/data
      containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
          ports:
            - containerPort: 9200
          env:
            - name: discovery.type    # Elasticsearch uses cluster ``discovery`` to discover and communicate with other Nodes. It will result to failure if no other Nodes are found. 
              value: "single-node"    # Setting ``discovery.type`` to "single-node" disables the cluster discovery mechanism. It functions as a standalone node and avoids looking for other nodes. This is particularly useful for ``development``, testing, or ``when running a single-node deployment in production``.
          # env:    # Only use if you need to scale the replica to more than 3 
          #   - name: discovery.seed_hosts
          #     value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
          #   - name: cluster.initial_master_nodes
          #     value: "elasticsearch-0"
            - name: xpack.security.enabled
              value: "true"
            - name: ELASTIC_PASSWORD
              value: "elkpassword"
          resources:
            limits:
              memory: "2Gi"
              cpu: "1"
          volumeMounts:
            - name: elasticsearch-data
              mountPath: /usr/share/elasticsearch/data  # Mounts the persistent volume inside the Elasticsearch container.
      volumes:
        - name: elasticsearch-data
          persistentVolumeClaim:
            claimName: elasticsearch-pvc

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
kubectl apply -f elasticsearch-statefulset.yaml
kubectl apply -f elasticsearch-service.yaml
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
kubectl apply -f logstash.yaml
kubectl apply -f logstash-service.yaml
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
          image: docker.elastic.co/kibana/kibana:7.17.0   #Old version 7.10.0
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
  type: ClusterIP
  selector:
    app: kibana
  ports:
    - protocol: TCP
      port: 5601
      targetPort: 5601
```

##### Apply the Kibana Deployment and Service:

```sh
kubectl apply -f kibana.yaml
kubectl apply -f kibana-service.yaml
```

##### Next, check for all the running pods:
```sh
kubectl get pods -n elk
```
![Running Pods](images/running-pods.png)

At this stage, we can either expose our Kibana dashboard using either LoadBalancer, Port Forwarding or Ingress. 


## Exposing Kibana service externally using Nginx Ingress & Cert Manager

This guide will show you how to set up Cert-Manager and NGINX Ingress on Kubernetes to automate TLS certificate management with Let’s Encrypt.
**Ingress** is a Kubernetes resource that manages external access to services within a cluster, typically HTTP and HTTPS traffic.
**Cert-Manager** automates the process of obtaining and renewing TLS certificates from providers like Let’s Encrypt. It integrates seamlessly with Ingress controllers (e.g., NGINX) to handle certificate management automatically.

##### Step 1: Create a Namespace

First, let's create a dedicated namespace for the Ingress controller:

```sh
kubectl create namespace ingress-basic 
```
##### Step 2. Installing Helm
Helm is a package manager for Kubernetes that simplifies the deployment and management of applications. First, we’ll install Helm.

```sh
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
Verify the installation:

```sh
helm version
```
##### Step 3.  Installing NGINX Ingress Controller
The NGINX Ingress Controller manages HTTP and HTTPS traffic within Kubernetes. We’ll install it using Helm.

Add the Helm repository:
```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```
![Running Pods](images/nginx.png)

Before running the next command, Go to Azure Account search for Azure Load Balancer, and click on it.

![Loadbalancer](images/loadbalancer.png)

There can be many load balancers if you have created if the load balancer name is Kubernetes click on it.

![Loadbalancer page](images/loadbalancer-page.png)
Once you land on the Kubernetes load balancer page, Click on Frontend IP Configuration and copy the IP address.

![IP Address](images/ip-address.png)

Next, install the Helm chart using the command below. Be sure to replace ``<PUBLIC-IP>`` with the Public IP address you copied in the earlier steps.

```sh
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-basic \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.service.externalTrafficPolicy=Local \
    --set controller.service.loadBalancerIP="<PUBLIC-IP>"

```

![Cert Manager Installed](images/cert-manager-installed.png)

To check if Ingress is installed, run the following command and ensure all pods are running.

![Running Pods](images/validate-pods-running.png)

Next, we’ll configure an SSL certificate for our application, which will be deployed within the next hour.

Run the following command to label ingress-basic for validation:
```sh
kubectl label namespace ingress-basic cert-manager.io/disable-validation=true
```

![Ingress Validation](images/Ingress-validation.png)

Add the cert manager helm repo and update the repo
```sh
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

![Cert Manager Repo](images/cert-manager-repo.png)


To configure SSL for our application, we need to create Custom Resource Definitions (CRDs). 

Run the following command:
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml
```

![Custom Cert Manager](images/custom-cert-manager.png)


Install the cert manager helm chart

```sh
helm install cert-manager jetstack/cert-manager \
  --namespace ingress-basic \
  --version v1.7.1
```

![Custom Cert Manager Installed](images/custom-manager-installed.png)

Validate whether cert-manager pods are running or not

![Custom Cert Manager Installed](images/validate-all-pods-running.png)


#### Step 4. Cluster Issuer Configuration
In this step, we’ll set up the Cluster Issuer, which handles SSL certificate management for our application.

##### Issuer (issuer.yaml)

```sh
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: letsencrypt
spec:
 acme:
   server: https://acme-v02.api.letsencrypt.org/directory
   email: <your-email-address.com> # You must replace this email address with your own. Let's Encrypt will use this to contact you when your cert is about to expire.
   privateKeySecretRef:
    name: letsencrypt 
   solvers:
   - http01:
       ingress:
         class: nginx
         podTemplate:
           spec:
             nodeSelector:
               "kubernetes.io/os": linux
```

Run the following command:
```sh
kubectl apply -f issuer.yaml
```

#### Step 5. Ingress Configuration

At this stage, we will update the ingress file by adding annotations and configuring TLS settings.

```sh
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingresslb
  namespace: elk  # Make sure this matches the namespace of your configuration files'
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    nginx.ingress.kubernetes.io/proxy-read-timeout: "120"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "120"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - <Add-your-domain-name>
    secretName: tls-secret
  rules:
    - host: <Add-your-domain-name>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kibana
                port:
                  number: 5601
```

Run the following command:
```sh
kubectl apply -f ingress.yaml
```


##### Step 6: Verify Cert-Manager has issued a certificate:
The ``tls secret`` is the value of the ``secretName`` in the Ingress file

```sh
kubectl describe certificate tls-secret -n elk
```
![Ingress Validation](images/certificate-ready.png)

```sh
kubectl get cert
```
![Ingress Validation](images/cert-true.png)


##### Step 7: Verify ingress:

```sh
kubectl get ingress -n elk
```

![Ingress Validation](images/ingress.png)

I've added the public IP provided by Ingress on my domain provider.

![DNS Records](images/dns-record.png)

Hit the hostname from your browser, and you should see the Kibana dashboard.

Congratulations! You have successfully deployed the ELK Stack to your AKS cluster with HTTPS enabled.

![Kibana Dashboard](images/kibana-dashboard-empty.png)

## Conclusion

This structure provides a comprehensive guide for deploying the ELK Stack (Elasticsearch, Kibana, and Logstash) on Azure AKS using YAML configuring files and ensuring security best practices for production environments.

For more detailed configurations and customizations, refer to the official [Elastic Helm Charts documentation](https://github.com/elastic/helm-charts).


## Contact
If you have questions or would like to discuss further, feel free to reach out to me or connect me directly on my [LinkedIn Profile](https://www.linkedin.com/in/gerard-ambe-80050b152/).


