kubectl apply -f apache-deployment.yaml
kubectl apply -f apache-service.yaml

kubectl apply -f elasticsearch.yaml -n elk
kubectl apply -f elasticsearch-service.yaml -n elk
kubectl apply -f kibana.yaml -n elk
kubectl apply -f kibana-service.yaml -n elk
kubectl apply -f logstash.yaml -n elk
kubectl apply -f logstash-service.yaml -n elk
kubectl apply -f filebeat.yaml -n elk
kubectl apply -f ingress.yaml -n elk