# Trigger service packed by Digital Asset

## TL;DR

```console
helm repo add digitalasset https://digital-asset.github.io/daml-helm-charts/
helm install mytrigger digitalasset/daml-trigger
```

#### Minimum viable configuration

Example configuration connecting to `participant1` in namespace `canton` within the same Kubernetes cluster (TLS/JWT disabled):

```yaml
storage:
  host: "<postgresql_server_host>"
  port: "<postgresql_server_port>"
  ssl: false
  database: "<postgresql_database_name>"
  user: "<postgresql_user_name>"
  # Use value from specified Kubernetes secret key as PostgreSQL password
  existingSecret:
    name: "<k8s_secret_name>"
    key: "<k8s_secret_key>"

ledgerAPI:
  host: "participant1-canton-participant.canton.svc.cluster.local"
```

## Introduction

Trigger service HA deployment

⚠️ Only PostgreSQL is supported as storage backend 🐘

## Prerequisites

- Kubernetes 1.23+
- Helm 3.2+
- Preconfigured PostgreSQL for the Trigger
  - User
  - Password
  - Database
- Ledger API (exposed by a Canton Participant connected to a Domain)
- Cert-manager + CSI driver (only if TLS is required by the Ledger API)

## Configuration and installation details

### TLS

To enable TLS (and/or mTLS) everywhere, it is mandatory to have [Cert-manager](https://cert-manager.io/docs/) and its CSI driver
already deployed in a specific namespace of your Kubernetes cluster. A certificate issuer must be ready to use (you can use
external issuer types), you may customize all the Cert-manager CSI driver related values:

```yaml
certManager:
  issuerGroup: "cert-manager.io"
  issuerKind: "Issuer"
  issuerName: "my-cert-manager-issuer"
```

## Limitations

⚠️ **Upgrading to a different release is not supported for now** ⚠️

## Parameters

### Common parameters

| Name                        | Description                                                                                    | Value                          |
| --------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------ |
| `nameOverride`              | String to partially override `common.name` template (will maintain the release name)           | `""`                           |
| `fullnameOverride`          | String to fully override `common.fullname` template                                            | `""`                           |
| `replicaCount`              | Number of Participant pods to deploy                                                           | `1`                            |
| `image.registry`            | Docker image registry                                                                          | `digitalasset-docker.jfrog.io` |
| `image.repository`          | Docker image repository                                                                        | `trigger-service`              |
| `image.tag`                 | Docker image tag (immutable tags are recommended)                                              | `""`                           |
| `image.digest`              | Docker image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag` | `""`                           |
| `image.pullPolicy`          | Docker image pull policy. Allowed values: `Always`, `Never`, `IfNotPresent`                    | `IfNotPresent`                 |
| `image.pullSecrets`         | Specify Docker registry secret names as an array                                               | `[]`                           |
| `commonLabels`              | Add labels to all the deployed resources                                                       | `{}`                           |
| `metrics.enabled`           | Enable Prometheus metrics endpoint                                                             | `false`                        |
| `metrics.reportingInterval` | Metrics reporting interval                                                                     | `30s`                          |

### Trigger configuration

| Name                           | Description                                                             | Value                      |
| ------------------------------ | ----------------------------------------------------------------------- | -------------------------- |
| `storage`                      | PostgreSQL configuration                                                |                            |
| `storage.host`                 | Server hostname                                                         | `postgres`                 |
| `storage.port`                 | Server port                                                             | `5432`                     |
| `storage.database`             | Database name                                                           | `trigger`                  |
| `storage.user`                 | User name                                                               | `trigger`                  |
| `storage.existingSecret.name`  | Name of existing secret with user credentials                           | `""`                       |
| `storage.existingSecret.key`   | Name of key in existing secret with user password                       | `""`                       |
| `storage.connectionProperties` | PostgreSQL JDBC driver connection URI properties (everything after `?`) | `ssl=true&sslmode=require` |
| `storage.tablePrefix`          | Prefix for DB table names (to avoid collisions)                         | `""`                       |
| `storage.poolSize`             | DB connection pool maximum connections                                  | `10`                       |
| `storage.minIdle`              | DB connection pool minimum idle connections                             | `4`                        |
| `storage.idleTimeout`          | DB connection pool idle timeout                                         | `10s`                      |
| `storage.connectionTimeout`    | DB connection pool timeout                                              | `60s`                      |
| `storage.certificatesSecret`   | Name of an existing secret containing certificates, mounted to `/pgtls` | `""`                       |
| `ledgerAPI.host`               | Ledger API hostname                                                     | `participant`              |
| `ledgerAPI.port`               | Ledger API port                                                         | `4001`                     |

### mTLS configuration

| Name                               | Description                                                                                                                     | Value                    |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `tls.enabled`                      | Enable mTLS to Ledger API (gRPC)                                                                                                | `false`                  |
| `tls.certManager`                  | Cert-manager CSI driver configuration (only used when TLS is enabled)                                                           |                          |
| `tls.certManager.issuerGroup`      | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc. | `cert-manager.io`        |
| `tls.certManager.issuerKind`       | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                    | `Issuer`                 |
| `tls.certManager.issuerName`       | Cert-manager issuer name                                                                                                        | `my-cert-manager-issuer` |
| `tls.trustCollectionFile`          | Trusted certificate(s), if omitted JVM default trust store is used                                                              | `/tls/ca.crt`            |
| `tls.certChainFile`                | Certificate                                                                                                                     | `/tls/tls.crt`           |
| `tls.privateKeyFile`               | Private key                                                                                                                     | `/tls/tls.key`           |
| `tls.minimumServerProtocolVersion` | Minimum TLS version allowed                                                                                                     | `TLSv1.3`                |
| `tls.ciphers`                      | Specify ciphers allowed, if set to `null` JVM defaults are used                                                                 | `null`                   |

### Logging

| Name         | Description                                                                       | Value   |
| ------------ | --------------------------------------------------------------------------------- | ------- |
| `logLevel`   | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` | `INFO`  |
| `logEncoder` | Logging encoder. Allowed values: `plain`, `json`                                  | `plain` |

### Container ports

| Name            | Description                               | Value  |
| --------------- | ----------------------------------------- | ------ |
| `ports.http`    | Trigger container port (HTTP)             | `8088` |
| `ports.metrics` | Promotheus exporter container port (HTTP) | `8081` |

### Deployment configuration

| Name                     | Description                                                              | Value |
| ------------------------ | ------------------------------------------------------------------------ | ----- |
| `environment`            | Container environment variables                                          | `{}`  |
| `environmentSecrets`     | Container secret environment variables                                   | `{}`  |
| `deployment.annotations` | Deployment extra annotations                                             | `{}`  |
| `deployment.labels`      | Deployment extra labels                                                  | `{}`  |
| `deployment.strategy`    | Deployment strategy                                                      | `{}`  |
| `pod.annotations`        | Extra annotations for Deployment pods                                    | `{}`  |
| `pod.labels`             | Extra labels for Deployment pods                                         | `{}`  |
| `affinity`               | Affinity for pods assignment                                             | `{}`  |
| `nodeSelector`           | Node labels for pods assignment                                          | `{}`  |
| `resources`              | Resources requests/limits for HTTP Trigger container                     | `{}`  |
| `tolerations`            | Tolerations for pods assignment                                          | `[]`  |
| `extraVolumeMounts`      | Specify extra list of additional volumeMounts for HTTP Trigger container | `[]`  |
| `extraVolumes`           | Specify extra list of additional volumes for HTTP Trigger pod            | `[]`  |

### Service configuration

| Name                              | Description                                                                          | Value       |
| --------------------------------- | ------------------------------------------------------------------------------------ | ----------- |
| `service.type`                    | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance` | `ClusterIP` |
| `service.annotations`             | Service extra annotations                                                            | `{}`        |
| `service.labels`                  | Service extra labels                                                                 | `{}`        |
| `service.ports.http`              | Trigger port (HTTP)                                                                  | `8088`      |
| `service.ports.metrics`           | Promotheus exporter service port (HTTP)                                              | `8081`      |
| `service.sessionAffinity.enabled` | Enable `ClientIP` based session affinity                                             | `true`      |
| `service.sessionAffinity.timeout` | Session timeout in seconds. Between `1` and `86400`                                  | `3600`      |

## License

Copyright &copy; 2023 Digital Asset (Switzerland) GmbH and/or its affiliates

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
