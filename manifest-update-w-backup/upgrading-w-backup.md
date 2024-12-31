# Upgrading ELK Stack with Backup

This guide provides step-by-step instructions to upgrade Kibana, Logstash, and Elasticsearch, including creating backups before the upgrade.

# Upgrading ELK Stack with Backup

This guide provides step-by-step instructions to upgrade Kibana, Logstash, and Elasticsearch, including creating backups before the upgrade.

###### Note
Upgrading ELK Stack configured using YAML files is different from upgrading Elastic Cloud. Elastic cloud does the upgrading for you but with a self-managed ELK Stack it requires manual intervention, updating the Yaml files, applying the changes and managing the upgrading process for each component (Elasticsearch, Logstash, Kibana, etc.).

## Prerequisites

- Ensure you have a backup of your data.
- Verify the compatibility of the new version with your existing plugins and configurations.
- Before upgrading [Prepare to upgrade from 7.x](https://www.elastic.co/guide/en/elastic-stack/current/upgrading-elastic-stack.html#prepare-to-upgrade)
- Review the [Elasticsearch](https://www.elastic.co/guide/en/elastic-stack/current/upgrading-elasticsearch.html) and [Kibana](https://www.elastic.co/guide/en/elastic-stack/current/upgrading-kibana.html) upgrade documentation.

## Steps to Upgrade:
##### Note
If you are currently on v7.x.x, **You cannot directly upgrade from v7.10.0 to v8.17.0** You must upgrade to an intermediate versions. In our case, we will upgrade from **v7.10.0** to **v7.17.0** before upgrading to **v8.17.0**:

## Step 1: Backup Your Data
We'll create a ConfigMap for our backed up data. To ensure the ``path.repo(/mount/backups)`` configuration is persistent, we will configure it using the ``ConfigMap`` and bake it into the ``elasticsearch-statefulset.yaml`` configuration. 

**1. Create a ConfigMap**

elasticsearch-configmap.yaml
```sh
apiVersion: v1
kind: ConfigMap
metadata:
  name: elasticsearch-config
  namespace: elk
data:
  elasticsearch.yml: |
    path.repo: ["/mount/backups"]
    discovery.type: single-node
    xpack.security.enabled: false
```
**2. Modify the elasticsearch-statefulSet.yaml file:**
The elasticsearch statefulset has been updated to Mount the ConfigMap and Backup directory of the Node into the StatefulSet:
```sh
initContainers:
  # This should be added under "initContainer":
  # It adds permission to the backups path
  # Starts Here
  - name: fix-backup-permissions
    image: busybox
    command: ["sh", "-c", "chown -R 1000:1000 /mount/backups && chmod -R 770 /mount/backups"]
    volumeMounts:
      - name: backup-mount
        mountPath: /mount/backups
        # END
containers:
  - name: elasticsearch
    image: docker.elastic.co/elasticsearch/elasticsearch:8.17.0
    ports:
      - containerPort: 9200
    volumeMounts:
      - name: elasticsearch-data
        mountPath: /usr/share/elasticsearch/data
        # This should be added under "volumeMounts":
        # It mounts backup path into the container
        # Starts Here
      - name: backup-mount
        mountPath: /mount/backups
        # Mount ConfigMap path into container
      - name: elasticsearch-config
        mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
        subPath: elasticsearch.yml
# Backup path on the Node
volumes:
  # Backup path on the Node
  - name: backup-mount
    hostPath:
      path: /mount/backups
      type: DirectoryOrCreate
  # ConfigMap on the Node
  - name: elasticsearch-config
    configMap:
      name: elasticsearch-config
      # End
```
**3. Apply the changes:**
```sh
kubectl apply -f elasticsearch-config.yaml
kubectl apply -f elasticsearch-statefulset.yaml
```
 - Restart Elasticsearch statefulset:
```sh
kubectl -n elk rollout restart statefulset elasticsearch
```

**4. Verify path.repo is correctly applied to elasticsearch-statefulset**
If you don't want to expose your service externally, you can use ``kubectl port-forward`` to access Elasticsearch from your local machine.

- Run Port Forwarding:
```sh
kubectl -n elk port-forward svc/elasticsearch 9200:9200
```

- Ensure the directory /mount/backups on the host has the correct permissions:
```sh
sudo chmod -R 770 /mount/backups
sudo chown -R 1000:1000 /mount/backups
```

- Access the Elasticsearch Pod shell
```sh
kubectl -n elk exec -it pod/elasticsearch-0 -- bash
```

- Check if the ``/mount/backups`` exist and has read and write permissions:
```sh 
ls -ld /mount/backups
```

- verify that the path.repo setting is applied
```sh 
curl -u elastic:elkpassword -X GET "http://localhost:9200/_nodes/settings?pretty"
```

- Check if the Snapshot Repository is created:
```sh
curl -u elastic:elkpassword -X PUT "http://localhost:9200/_snapshot/elk_backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/mount/backups"
  }
}'

```

- Verify if there's any backed up data:
```sh
ls -l /mount/backups
```

**5a. Create a Snapshot**
Run the following command to create a snapshot of all indices:

```sh
curl -u elastic:elkpassword -X PUT "http://localhost:9200/_snapshot/elk_backup/snapshot_1?wait_for_completion=true" -H 'Content-Type: application/json' -d'
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": true
}'
```
- ``indices: "*"`` backs up all indices. You can specify specific indices if needed.
- ``ignore_unavailable: true`` skips any unavailable indices.
- ``include_global_state: true`` includes the cluster state in the snapshot.

If successful, you’ll see a response like this:
```sh
{
  "snapshot": {
    "snapshot": "snapshot_1",
    "uuid": "some-unique-id",
    "version_id": 8010099,
    "version": "8.1.0",
    "indices": ["index_1", "index_2"],
    "state": "SUCCESS",
    ...
  }
}
```
**b. Verify the Snapshot**
You can list all snapshots in the repository to confirm the snapshot was created:

```sh
curl -u elastic:elkpassword -X GET "http://localhost:9200/_snapshot/elk_backup/_all?pretty"
```


#### Step 2: After Update is completed:

**6. Restoring a Snapshot**
If you need to restore data from a snapshot, you can use the following command:

```sh
curl -u elastic:elkpassword -X POST "http://localhost:9200/_snapshot/elk_backup/snapshot_1/_restore" -H 'Content-Type: application/json' -d'
{
  "indices": "*",
  "include_global_state": true
}'
```

- Replace ``snapshot_1`` with the name of the snapshot you want to restore.
- You can specify specific indices instead of ``"*"`` if you only want to restore certain indices.

##### 7. Monitoring and Automation

**a. Monitor Snapshots**
Elasticsearch provides APIs to monitor snapshots:

- Check the status of all snapshots:
```sh
curl -u elastic:elkpassword -X GET "http://localhost:9200/_snapshot/elk_backup/_status?pretty"
```
**b. Automate Backups**
To ensure regular backups, you can:
- Use a cron job to periodically execute the snapshot creation API.
- Integrate with tools like Curator or custom scripts.

**8. Best Practices for Production**
- ``Offsite Backups:`` Periodically copy the ``/mount/backups`` directory to a remote storage system (e.g., AWS S3, Azure Blob Storage, or a network file share) for disaster recovery.
- ``Retention Policy:`` Implement a retention policy to delete old snapshots and save storage space.
```sh
curl -u elastic:elkpassword -X DELETE "http://localhost:9200/_snapshot/elk_backup/snapshot_1"
```
- ``Test Restores:`` Regularly test restoring snapshots to ensure the backup process is working as expected.
