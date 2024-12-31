# Upgrading Elasticsearch and Kibana

This guide provides step-by-step instructions for upgrading Elasticsearch and Kibana to the latest version.
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

### Elasticsearch Upgrade

1. Stop Elasticsearch service:
    ```sh
    sudo systemctl stop elasticsearch
    ```

2. Install the new version:
    ```sh
    sudo dpkg -i elasticsearch-<version>.deb
    ```

3. Start Elasticsearch service:
    ```sh
    sudo systemctl start elasticsearch
    ```

### Logstash Upgrade

1. Stop Logstash service:
    ```sh
    sudo systemctl stop logstash
    ```

2. Install the new version:
    ```sh
    sudo dpkg -i logstash-<version>.deb
    ```

3. Start Logstash service:
    ```sh
    sudo systemctl start logstash
    ```

### Kibana Upgrade

1. Stop Kibana service:
    ```sh
    sudo systemctl stop kibana
    ```

2. Install the new version:
    ```sh
    sudo dpkg -i kibana-<version>.deb
    ```

3. Start Kibana service:
    ```sh
    sudo systemctl start kibana
    ```

## Verification

1. Verify Elasticsearch:
    ```sh
    curl -X GET "localhost:9200/"
    ```

2. Verify Logstash:
    ```sh
    sudo systemctl status logstash
    ```

3. Verify Kibana:
    ```sh
    sudo systemctl status kibana
    ```

## Rollback (if needed)

1. Restore Elasticsearch snapshot:
    ```sh
    POST _snapshot/my_backup/snapshot_1/_restore
    ```

2. Restore Logstash configuration:
    ```sh
    cp /path/to/backup/* /etc/logstash/conf.d/
    ```

3. Restore Kibana configuration:
    ```sh
    cp /path/to/backup/kibana.yml /etc/kibana/
    ```


## Conclusion

You have successfully upgraded Elasticsearch and Kibana to the latest version. Ensure to monitor the services and verify that everything is functioning as expected.
