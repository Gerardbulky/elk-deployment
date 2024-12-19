kubectl apply -f apache-deployment.yaml
kubectl apply -f apache-service.yaml

kubectl apply -f elasticsearch.yaml
kubectl apply -f elasticsearch-service.yaml
kubectl apply -f filebeat.yaml
kubectl apply -f filebeat-daemonset.yaml
kubectl apply -f logstash.yaml
kubectl apply -f logstash-service.yaml
kubectl apply -f kibana.yaml
kubectl apply -f kibana-service.yaml
