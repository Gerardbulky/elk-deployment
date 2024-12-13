kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# kubectl apply -f elasticsearch.yaml -n elk
# kubectl apply -f elasticsearch-service.yaml -n elk
# kubectl apply -f kibana.yaml -n elk
# kubectl apply -f kibana-service.yaml -n elk
# kubectl apply -f logstash.yaml -n elk
# kubectl apply -f logstash-service.yaml -n elk
# kubectl apply -f filebeat-config.yaml -n elk
# kubectl apply -f filebeat-daemonset.yaml -n elk