kubectl delete -f deployment.yaml
kubectl delete -f service.yaml

kubectl delete -f elasticsearch.yaml -n elk
kubectl delete -f elasticsearch-service.yaml -n elk
kubectl delete -f kibana.yaml -n elk
kubectl delete -f kibana-service.yaml -n elk
kubectl delete -f logstash.yaml -n elk
kubectl delete -f logstash-service.yaml -n elk
# kubectl delete -f filebeat-config.yaml -n elk
# kubectl delete -f filebeat-daemonset.yaml -n elk