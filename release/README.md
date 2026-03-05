<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# Apache Ranger Images

[ranger-tools/release](https://github.com/apache/ranger-tools/release) contains utilities to publish docker images for released Ranger versions. 

## Usage

### Build Images

To build the images, run the following commands from the `release` directory:

```bash
export RANGER_VERSION=2.8.0
docker build -f Dockerfile.ranger-postgres -t ranger-db:latest .
docker build -f Dockerfile.ranger-solr -t ranger-solr:latest .
docker build --build-arg RANGER_VERSION=${RANGER_VERSION} -f Dockerfile.ranger -t ranger:latest .
```

### Run Containers

To run the containers, use the following commands:

```bash
docker network create rangernw

export ZK_VERSION=3.9.2
docker run -d --name ranger-zk --hostname ranger-zk.rangernw --network rangernw -p 2181:2181 zookeeper:${ZK_VERSION}

docker run -d --name ranger-solr --hostname ranger-solr.rangernw --network rangernw -p 8983:8983 ranger-solr:latest \
  solr-precreate ranger_audits /opt/solr/server/solr/configsets/ranger_audits/

docker run -d \
  -e POSTGRES_PASSWORD=rangerR0cks! \
  -e RANGER_DB_USER=rangeradmin \
  -e RANGER_DB_PASSWORD=rangerR0cks! \
  -e HIVE_DB_USER=hive \
  -e HIVE_DB_PASSWORD=rangerR0cks! \
  --name ranger-db --hostname ranger-db.rangernw --network rangernw --health-cmd='su -c "pg_isready -q" postgres' --health-interval=10s --health-timeout=2s --health-retries=30 ranger-db:latest

docker run -d --name ranger-admin --hostname ranger-admin.rangernw --network rangernw -p 6080:6080 ranger:latest
```
### Access Ranger Admin UI

Once the containers are running, you can access the Ranger Admin UI by navigating to `http://localhost:6080` in your web browser. The default credentials are: `admin/rangerR0cks!`