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

# Apache Ranger PDP Image

Ranger PDP is a standalone policy decision point. It downloads policies from Ranger Admin and
answers authorization requests over REST on port 6500.

## Build

Run from the `release` directory:

```bash
export RANGER_VERSION=2.9.0
docker build --build-arg RANGER_VERSION=${RANGER_VERSION} -f Dockerfile.ranger-pdp -t ranger-pdp:latest .
```

## Run

With Ranger Admin running as described in [README.md](README.md):

```bash
docker run -d \
  -e RANGER_ADMIN_URL=http://ranger-admin.rangernw:6080 \
  -e RANGER_ADMIN_PASSWORD=rangerR0cks! \
  -e RANGER_PDP_DELEGATION_USERS=ranger \
  --name ranger-pdp --hostname ranger-pdp.rangernw --network rangernw -p 6500:6500 ranger-pdp:latest
```

## Try It

Check that the PDP is ready:

```bash
curl -s http://localhost:6500/health/ready
```

Ask for a decision. The `X-Forwarded-User` header identifies the caller; requests without it are rejected with `401`:

```bash
curl -s -X POST http://localhost:6500/authz/v1/authorize \
  -H 'Content-Type: application/json' \
  -H 'X-Forwarded-User: ranger' \
  -d '{"requestId":"req-1",
       "user":{"name":"analyst"},
       "access":{"resource":{"name":"column:db1/tbl1/col1"},"permissions":["select"]},
       "context":{"serviceName":"dev_hive","serviceType":"hive"}}'
```

A resource is named `<resourceType>:<value>`, where the value follows the service's resource
hierarchy (`database/table/column` for hive). A caller may ask about *another* user only when it
is listed in `RANGER_PDP_DELEGATION_USERS`; otherwise the request is rejected with `403`.

The PDP also serves `/health/live`, and Prometheus metrics at `/metrics`.

## Authentication

The PDP refuses to start unless at least one inbound authentication handler is usable, so
this image always configures **header-based authentication**. By default, the username is read
from `X-Forwarded-User`; set `RANGER_PDP_AUTHN_HEADER_USERNAME` to change it, or
`RANGER_PDP_AUTHN_HEADER_SPIFFE` to authenticate services by SPIFFE ID instead. Header authn
trusts its input, so run the PDP behind a proxy or mesh that sets the header and strips any
client-supplied copy. JWT and Kerberos can be enabled alongside it.

## Configuration

On every start the entrypoint renders `conf/ranger-pdp-site.xml` from a YAML file whose keys are
`ranger-pdp-site.xml` property names:

- By default it uses `ranger-pdp-site-defaults.yaml`, baked into the image
  ([source](scripts/pdp/ranger-pdp-site-defaults.yaml)). Its values reference environment variables
  as `${VAR:-default}`, so common settings can be changed with `docker run -e`; see that file for the
  full list.
- To drive the configuration yourself, set `RANGER_PDP_SITE_YAML` to your own YAML file. It replaces
  the defaults entirely: keys it leaves out take the PDP's built-in defaults, and environment
  variables apply only where your file references them.

`${VAR}` references are expanded after the YAML is parsed, so environment values are used verbatim
(use `$$` for a literal `$`). Lists are joined with commas, and properties that end up empty are left
out so the PDP applies its built-in default.

On Kubernetes, your YAML fits naturally in a ConfigMap, with secrets injected as environment variables:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ranger-pdp-config
data:
  ranger-pdp-site.yaml: |
    ranger.authz.default.policy.rest.url: http://ranger-admin:6080
    ranger.authz.default.policy.rest.client.password: "${RANGER_ADMIN_PASSWORD}"
    ranger.authz.init.services: [dev_hive, dev_hdfs]
    ranger.pdp.authn.header.username: X-Forwarded-User
    ranger.pdp.http.connector.maxThreads: 400
```

Mount it at a path of its own (e.g. `/etc/ranger/pdp`) and set
`RANGER_PDP_SITE_YAML=/etc/ranger/pdp/ranger-pdp-site.yaml`; the entrypoint writes into `conf/`, so
don't mount the ConfigMap over that directory.

To manage the XML yourself, mount a complete file at `/opt/ranger/pdp/conf/ranger-pdp-site.xml`;
YAML and environment variables are then ignored, though the entrypoint still refuses to start the
PDP if that file leaves no authentication handler usable.

