# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# see https://hub.docker.com/_/eclipse-temurin/tags
ARG RANGER_BASE_JAVA_VERSION=8

# Ubuntu 22.04 LTS
FROM eclipse-temurin:${RANGER_BASE_JAVA_VERSION}-jdk-jammy

# Install packages
RUN apt update -q \
    && DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends \
        bc \
        iputils-ping \
        pdsh \
        python3 \
        python3-pip \
        python-is-python3 \
        ssh \
        tzdata \
        vim \
        xmlstarlet \
    && apt clean

# Install Python modules
RUN pip install apache-ranger requests \
    && rm -rf ~/.cache/pip

# Set environment variables
ENV RANGER_DIST=/home/ranger/dist
ENV RANGER_SCRIPTS=/home/ranger/scripts
ENV RANGER_HOME=/opt/ranger
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# setup groups, users, directories
RUN groupadd ranger \
    && for u in ranger rangeradmin rangerusersync rangertagsync rangerkms; do \
      useradd -g ranger -ms /bin/bash $u; \
    done

RUN groupadd hadoop \
    && for u in hdfs yarn hive hbase kafka ozone; do \
      useradd -g hadoop -ms /bin/bash $u; \
    done

RUN groupadd knox \
    && useradd -g knox -ms /bin/bash knox

# setup directories
RUN mkdir -p /home/ranger/dist /home/ranger/scripts /opt/ranger && \
    chown -R ranger:ranger /home/ranger /opt/ranger && \
    chmod +rx /home/ranger /home/ranger/dist /home/ranger/scripts

ENTRYPOINT [ "/bin/bash" ]
