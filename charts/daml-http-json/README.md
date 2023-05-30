# HTTP JSON API service packed by Digital Asset

## Table of contents

- [Introduction](#introduction)
- [Prerequisites](#-prerequisites-)
- [TL;DR](#tldr)
- [Configuration and installation details](#configuration-and-installation-details)
- [Limitations](#limitations)
- [Parameters](#parameters)
- [License](#license)

---
## Introduction

HTTP JSON API service HA deployment

⚠️ Only PostgreSQL 🐘 is supported as storage backend, check our
[guidelines](https://github.com/digital-asset/daml-helm-charts/blob/main/POSTGRES.md).

---
## 🚦 Prerequisites 🚦

- Kubernetes `1.24+`
- Helm `3.9+`
- Preconfigured PostgreSQL resources for the HTTP JSON API service:
  - User/password
  - Database
- Ledger API (exposed by a Canton Participant connected to a Domain)
- [Cert-manager](https://cert-manager.io/docs/) + CSI driver (only if TLS is required by the Ledger API, optional but strongly recommended)

---
## TL;DR

```console
helm repo add digitalasset https://digital-asset.github.io/daml-helm-charts/
helm install myjson digitalasset/daml-http-json
```

#### Minimum viable configuration

Example configuration connecting to `participant1` in namespace `canton` within the same Kubernetes cluster.

⚠️ _TLS and JWT authentication are disabled_

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

---
## Configuration and installation details

### TLS

For each endpoint, there are two ways to provide certificates when TLS/mTLS is enabled.

⚠️ **Certificate rotation requires a restart of all components** ⚠️

#### Cert-manager (strongly recommended)

It is mandatory to have [Cert-manager](https://cert-manager.io/docs/) and its CSI driver already deployed
in your Kubernetes cluster. A CSI driver volume will be added only if an existing certificate issuer name
is defined with key `issuerName` (you can also use external issuer types), you may customize all the
Cert-manager CSI driver related values under `certManager`.

Example for the public endpoint:

```yaml
tls:
  enabled: true
  certManager:
    issuerName: "my-cert-manager-issuer"
```

#### Custom secrets

You must provide an existing secret with the required certificates.

Example with secret `http-json-tls` for the public endpoint used in participant deployment volume mount `tls-public`:

```yaml
tls:
  enabled: true
  ca: "/tls/ca.crt"
  chain: "/tls/chain.crt"
  key: "/tls/tls.key"

extraVolumes:
  - name: tls
    secret:
      secretName: http-json-tls
```

This secret must contain data with the right key names `ca.crt`, `chain.crt` and `tls.key`,
it will be mounted as files into folder `/tls`.

### Limitations

⚠️ **Upgrading to a different release is not supported for now** ⚠️

---
## Parameters

### Common parameters

| Name                      | Description                                                                                    | Value                          |
| ------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------ |
| `nameOverride`            | String to partially override `common.name` template (will maintain the release name)           | `""`                           |
| `fullnameOverride`        | String to fully override `common.fullname` template                                            | `""`                           |
| `replicaCount`            | Number of Participant pods to deploy                                                           | `1`                            |
| `image.registry`          | Docker image registry                                                                          | `digitalasset-docker.jfrog.io` |
| `image.repository`        | Docker image repository                                                                        | `http-json`                    |
| `image.tag`               | Docker image tag (immutable tags are recommended)                                              | `""`                           |
| `image.digest`            | Docker image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag` | `""`                           |
| `image.pullPolicy`        | Docker image pull policy. Allowed values: `Always`, `Never`, `IfNotPresent`                    | `IfNotPresent`                 |
| `image.pullSecrets`       | Specify Docker registry existing secret names as an array                                      | `[]`                           |
| `commonLabels`            | Add labels to all the deployed resources                                                       | `{}`                           |
| `certManager`             | Cert-manager CSI driver common configuration                                                   |                                |
| `certManager.duration`    | Requested duration the signed certificates will be valid for                                   | `87660h`                       |
| `certManager.renewBefore` | Time to renew the certificate before expiry. If empty `""` defaults to a third of `duration`   | `1h`                           |

### HTTP JSON API configuration

| Name                                | Description                                                                                                                                 | Value              |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| `storage`                           | PostgreSQL configuration                                                                                                                    |                    |
| `storage.host`                      | Server hostname                                                                                                                             | `postgres`         |
| `storage.port`                      | Server port                                                                                                                                 | `5432`             |
| `storage.database`                  | Database name                                                                                                                               | `json`             |
| `storage.user`                      | User name                                                                                                                                   | `json`             |
| `storage.existingSecret.name`       | Name of existing secret with user credentials                                                                                               | `""`               |
| `storage.existingSecret.key`        | Name of key in existing secret with user password                                                                                           | `""`               |
| `storage.ssl`                       | Enable TLS connection                                                                                                                       | `true`             |
| `storage.sslMode`                   | TLS mode. Allowed values: `disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`                                               | `require`          |
| `storage.sslRootCert`               | CA certificate file (PEM encoded X509v3). Intermediate certificate(s) that chain up to this root certificate can also appear in this file.  | `""`               |
| `storage.sslCert`                   | Client certificate file (PEM encoded X509v3)                                                                                                | `""`               |
| `storage.sslKey`                    | Client certificate key file (PKCS-12 or PKCS-8 DER)                                                                                         | `""`               |
| `storage.certificatesSecret`        | Name of an existing K8s secret that contains certificate files, mounted to `/pgtls` if not empty, provide K8s secret key names as filenames | `""`               |
| `storage.extraConnectionProperties` | Extra PostgreSQL JDBC driver connection URI properties (everything after `?`, start with `&`)                                               | `""`               |
| `storage.tablePrefix`               | Prefix for DB table names (to avoid collisions)                                                                                             | `""`               |
| `storage.poolSize`                  | DB connection pool maximum connections                                                                                                      | `10`               |
| `storage.minIdle`                   | DB connection pool minimum idle connections                                                                                                 | `4`                |
| `storage.idleTimeout`               | DB connection pool idle timeout                                                                                                             | `10s`              |
| `storage.connectionTimeout`         | DB connection pool timeout                                                                                                                  | `60s`              |
| `storage.startMode`                 | How the DB schema should be handled. Allowed values: `start-only`, `create-only`, `create-if-needed-and-start`, `create-and-start`          | `create-and-start` |
| `ledgerAPI.host`                    | Ledger API hostname                                                                                                                         | `participant`      |
| `ledgerAPI.port`                    | Ledger API port                                                                                                                             | `4001`             |
| `allowInsecureTokens`               | Allow connections without a reverse proxy providing HTTPS<br />**DO NOT ALLOW INSECURE TOKENS IN PRODUCTION**                               | `false`            |

### TLS configuration

| Name                               | Description                                                                                                                                           | Value                                                                                |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `tls.enabled`                      | Enable TLS to Ledger API (gRPC)                                                                                                                       | `false`                                                                              |
| `tls.certManager`                  | Cert-manager CSI driver configuration (only used when TLS is enabled), will automatically mount certificates in folder `/tls`                         |                                                                                      |
| `tls.certManager.issuerGroup`      | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                       | `cert-manager.io`                                                                    |
| `tls.certManager.issuerKind`       | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                          | `Issuer`                                                                             |
| `tls.certManager.issuerName`       | Cert-manager issuer name                                                                                                                              | `""`                                                                                 |
| `tls.certManager.fsGroup`          | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                        | `65532`                                                                              |
| `tls.ca`                           | CA certificate, if empty `""` JVM default trust store is used                                                                                         | `/tls/ca.crt`                                                                        |
| `tls.minimumServerProtocolVersion` | Minimum version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html) | `TLSv1.3`                                                                            |
| `tls.ciphers`                      | Specify ciphers allowed, if empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)                         | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |
| `mtls.enabled`                     | Enable mTLS to Ledger API (gRPC)                                                                                                                      | `false`                                                                              |
| `mtls.certManager`                 | Cert-manager CSI driver configuration (only used when TLS is enabled), will automatically mount certificates in folder `/mtls`                        |                                                                                      |
| `mtls.certManager.issuerGroup`     | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                       | `cert-manager.io`                                                                    |
| `mtls.certManager.issuerKind`      | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                          | `Issuer`                                                                             |
| `mtls.certManager.issuerName`      | Cert-manager issuer name                                                                                                                              | `""`                                                                                 |
| `mtls.certManager.fsGroup`         | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                        | `65532`                                                                              |
| `mtls.chain`                       | Certificate chain                                                                                                                                     | `/mtls/tls.crt`                                                                      |
| `mtls.key`                         | Certificate private key (PKCS-8)                                                                                                                      | `/mtls/tls.key`                                                                      |

### Logging

| Name         | Description                                                                       | Value   |
| ------------ | --------------------------------------------------------------------------------- | ------- |
| `logLevel`   | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` | `INFO`  |
| `logEncoder` | Logging encoder. Allowed values: `plain`, `json`                                  | `plain` |

### Container ports

| Name            | Description                               | Value  |
| --------------- | ----------------------------------------- | ------ |
| `ports.http`    | JSON API container port (HTTP)            | `3000` |
| `ports.metrics` | Promotheus exporter container port (HTTP) | `8081` |

### Deployment configuration

| Name                     | Description                                                               | Value |
| ------------------------ | ------------------------------------------------------------------------- | ----- |
| `environment`            | Container environment variables                                           | `{}`  |
| `environmentSecrets`     | Container secret environment variables                                    | `{}`  |
| `deployment.annotations` | Deployment extra annotations                                              | `{}`  |
| `deployment.labels`      | Deployment extra labels                                                   | `{}`  |
| `deployment.strategy`    | Deployment strategy                                                       | `{}`  |
| `pod.annotations`        | Extra annotations for Deployment pods                                     | `{}`  |
| `pod.labels`             | Extra labels for Deployment pods                                          | `{}`  |
| `affinity`               | Affinity for pods assignment                                              | `{}`  |
| `nodeSelector`           | Node labels for pods assignment                                           | `{}`  |
| `resources`              | Resources requests/limits for HTTP JSON API container                     | `{}`  |
| `tolerations`            | Tolerations for pods assignment                                           | `[]`  |
| `extraVolumeMounts`      | Specify extra list of additional volumeMounts for HTTP JSON API container | `[]`  |
| `extraVolumes`           | Specify extra list of additional volumes for HTTP JSON API pod            | `[]`  |

### Service configuration

| Name                    | Description                                                                          | Value       |
| ----------------------- | ------------------------------------------------------------------------------------ | ----------- |
| `service.type`          | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance` | `ClusterIP` |
| `service.annotations`   | Service extra annotations                                                            | `{}`        |
| `service.labels`        | Service extra labels                                                                 | `{}`        |
| `service.ports.http`    | JSON API port (HTTP)                                                                 | `7575`      |
| `service.ports.metrics` | Promotheus exporter service port (HTTP)                                              | `8081`      |

### Ingress configuration

| Name                  | Description                                                                                                        | Value                  |
| --------------------- | ------------------------------------------------------------------------------------------------------------------ | ---------------------- |
| `ingress.enabled`     | Enable ingress to HTTP JSON API service port `http` (HTTP)                                                         | `false`                |
| `ingress.annotations` | Ingress extra annotations                                                                                          | `{}`                   |
| `ingress.labels`      | Ingress extra labels                                                                                               | `{}`                   |
| `ingress.className`   | Set `ingressClassName` on the ingress record                                                                       | `""`                   |
| `ingress.hostname`    | Default host for the ingress resource                                                                              | `http-json.domain.com` |
| `ingress.path`        | Path to HTTP JSON API                                                                                              | `/`                    |
| `ingress.pathType`    | Determines the interpretation of the `Path` matching.  Allowed values: `Exact`, `Prefix`, `ImplementationSpecific` | `Prefix`               |
| `ingress.tls`         | Enable TLS configuration for `hostname`                                                                            | `[]`                   |

### Service Account and RBAC configuration

| Name                                          | Description                                                                                                        | Value   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------- |
| `serviceAccount.create`                       | Enable creation of service accounts for pod(s)                                                                     | `true`  |
| `serviceAccount.annotations`                  | Service Account extra annotations                                                                                  | `{}`    |
| `serviceAccount.labels`                       | Service Account extra labels                                                                                       | `{}`    |
| `serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API | `false` |
| `serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                 | `[]`    |
| `rbac.create`                                 | Enable creation of RBAC resources attached to the service accounts                                                 | `true`  |
| `rbac.rules`                                  | Custom RBAC rules to set                                                                                           | `[]`    |

### Monitoring configuration

| Name                                          | Description                                                                                                        | Value   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------- |
| `metrics.enabled`                             | Enable Prometheus metrics endpoint                                                                                 | `false` |
| `metrics.reportingInterval`                   | Metrics reporting interval                                                                                         | `30s`   |
| `metrics.podMonitor.enabled`                  | Creates a Prometheus Operator PodMonitor (also requires `metrics.enabled` to be `true`)                            | `false` |
| `metrics.podMonitor.jobLabel`                 | The label to use to retrieve the job name from                                                                     | `""`    |
| `metrics.podMonitor.podTargetLabels`          | PodTargetLabels transfers labels on the Kubernetes Pod onto the target                                             | `[]`    |
| `metrics.podMonitor.extraPodMetricsEndpoints` | Extra scrapeable endpoint configuration                                                                            | `[]`    |
| `metrics.podMonitor.sampleLimit`              | Per-scrape limit on number of scraped samples that will be accepted                                                | `0`     |
| `metrics.podMonitor.targetLimit`              | Limit on the number of scraped targets that will be accepted                                                       | `0`     |
| `metrics.podMonitor.labelLimit`               | Per-scrape limit on number of labels that will be accepted for a sample (Prometheus versions 2.27 and newer)       | `0`     |
| `metrics.podMonitor.labelNameLengthLimit`     | Per-scrape limit on length of labels name that will be accepted for a sample (Prometheus versions 2.27 and newer)  | `0`     |
| `metrics.podMonitor.labelValueLengthLimit`    | Per-scrape limit on length of labels value that will be accepted for a sample (Prometheus versions 2.27 and newer) | `0`     |

---
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
