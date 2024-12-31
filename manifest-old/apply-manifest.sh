kubectl apply -f flask-deployment.yaml
kubectl apply -f flask-service.yaml

kubectl apply -f elasticsearch-service.yaml
kubectl apply -f elasticsearch-statefulset.yaml
kubectl apply -f filebeat-configmap.yaml
kubectl apply -f filebeat-daemonset.yaml
# kubectl apply -f filebeat-rbac.yaml
kubectl apply -f logstash.yaml
kubectl apply -f logstash-service.yaml
kubectl apply -f kibana-service.yaml
kubectl apply -f kibana.yaml
kubectl apply -f logstash-service.yaml
kubectl apply -f logstash.yaml
# kubectl apply -f ingress.yaml
# kubectl apply -f issuer.yaml