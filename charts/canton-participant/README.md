# Canton Participant packed by Digital Asset

## TL;DR

```console
helm repo add digitalasset https://digital-asset.github.io/daml-helm-charts/
helm install participant1 digitalasset/canton/participant
```

### Minimum viable configuration

Example `participant1` configuration (TLS/JWT disabled):

```yaml
participantName: "participant1"

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
```

## Introduction

Canton Participant HA deployment (active/passive)

⚠️ Only PostgreSQL is supported as storage backend 🐘

## Prerequisites

- Kubernetes 1.23+
- Helm 3.2+
- Preconfigured PostgreSQL for the Participant
  - User
  - Password
  - Database
- Cert-manager + CSI driver (only if TLS is enabled)
- Canton Domain

## Configuration and installation details

### Bootstrap

Bootstrap is done in the Canton Domain Helm chart for now.

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

### Exposing the Ledger API using Traefik (gRPC on HTTP/2 + TLS)

Requirements
* TLS is enabled and terminated by the Canton nodes
* Traefik Ingress Controller deployed inside your K8s cluster with its Custom Resource Definitions (CRDs)
* A network load balancer in front of your K8s cluster to reach the Ingress Controller
* A DNS record targeting the load balancer
* A Traefik custom resource `IngressRouteTCP` to expose the Ledger API, forwarding traffic to participants
service port `public` with TLS passthrough

```
ingressRouteTCP:
  enabled: true
  hostSNI: "ledger.mydomain.com"
  tls:
    passthrough: true
```

## Limitations

⚠️ **Upgrading to a different release is not supported for now** ⚠️

## Parameters

### Common parameters

| Name                | Description                                                                                             | Value                                                         |
| ------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `nameOverride`      | String to partially override `canton-node.name` template (will maintain the release name)               | `""`                                                          |
| `fullnameOverride`  | String to fully override `canton-node.fullname` template                                                | `""`                                                          |
| `replicaCount`      | Number of Participant pods to deploy. Allowed values: `1` (active/passive HA, scaling up does not work) | `1`                                                           |
| `image.repository`  | Canton Docker image repository                                                                          | `digitalasset-docker.jfrog.io/digitalasset/canton-enterprise` |
| `image.tag`         | Canton Docker image tag (immutable tags are recommended)                                                | `""`                                                          |
| `image.digest`      | Canton Docker image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag`   | `""`                                                          |
| `image.pullPolicy`  | Canton Docker image pull policy. Allowed values: `Always`, `Never`, `IfNotPresent`                      | `IfNotPresent`                                                |
| `image.pullSecrets` | Specify Canton Docker registry secret names as an array                                                 | `[]`                                                          |
| `commonLabels`      | Add labels to all the deployed resources                                                                | `{}`                                                          |
| `metrics.enabled`   | Enable Prometheus metrics endpoint                                                                      | `false`                                                       |

### Participant configuration

| Name                          | Description                                                                                                                                                                                                   | Value          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `participantName`             | Mandatory Canton Participant name                                                                                                                                                                             | `participant1` |
| `storage`                     | PostgreSQL configuration                                                                                                                                                                                      |                |
| `storage.host`                | Server hostname                                                                                                                                                                                               | `postgres`     |
| `storage.port`                | Server port                                                                                                                                                                                                   | `5432`         |
| `storage.database`            | Database name                                                                                                                                                                                                 | `participant1` |
| `storage.user`                | User name                                                                                                                                                                                                     | `canton`       |
| `storage.existingSecret.name` | Name of existing secret with user credentials                                                                                                                                                                 | `""`           |
| `storage.existingSecret.key`  | Name of key in existing secret with user password                                                                                                                                                             | `""`           |
| `storage.maxConnections`      | Database connection pool maximum connections                                                                                                                                                                  | `10`           |
| `storage.ssl`                 | Enable TLS connection                                                                                                                                                                                         | `true`         |
| `storage.sslMode`             | TLS mode. Allowed values: `disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`                                                                                                                 | `require`      |
| `storage.certificatesSecret`  | Name of an existing K8s secret that contains certificate files, mounted to `/pgtls`, provide K8s secret key names as cert filenames. If empty `""`, provide the full path to cert files like `/path/to/file`. | `""`           |
| `storage.certCAFilename`      | CA certificate file (PEM encoded X509v3). Intermediate certificate(s) that chain up to this root certificate can also appear in this file.                                                                    | `ca.crt`       |
| `storage.certFilename`        | Client certificate file (PEM encoded X509v3)                                                                                                                                                                  | `tls.crt`      |
| `storage.certKeyFilename`     | Client certificate key file (PKCS-12 or PKCS-8 DER)                                                                                                                                                           | `key.der`      |

### Logging

| Name              | Description                                                                       | Value   |
| ----------------- | --------------------------------------------------------------------------------- | ------- |
| `logLevel`        | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` |         |
| `logLevel.root`   | Canton and external libraries, but not `stdout`                                   | `INFO`  |
| `logLevel.canton` | Only the Canton logger                                                            | `INFO`  |
| `logLevel.stdout` | Usually the text displayed in the Canton console                                  | `INFO`  |
| `logEncoder`      | Logging encoder. Allowed values: `plain`, `json`                                  | `plain` |

### TLS configuration

| Name                                      | Description                                                                                                                                               | Value                                                                                |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `tls.certManager`                         | Cert-manager CSI driver configuration (only used when TLS is enabled)                                                                                     |                                                                                      |
| `tls.certManager.issuerGroup`             | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                           | `cert-manager.io`                                                                    |
| `tls.certManager.issuerKind`              | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                              | `Issuer`                                                                             |
| `tls.certManager.issuerName`              | Cert-manager issuer name                                                                                                                                  | `my-cert-manager-issuer`                                                             |
| `tls.public.enabled`                      | Enable TLS on Ledger API (gRPC), Cert-manager CSI driver will automatically mount certificates in folders `/tls` and `/mtls`                              | `false`                                                                              |
| `tls.public.trustCollectionFile`          | CA certificate, if empty `""` JVM default trust store is used                                                                                             | `/tls/ca.crt`                                                                        |
| `tls.public.certChainFile`                | Certificate                                                                                                                                               | `/tls/tls.crt`                                                                       |
| `tls.public.privateKeyFile`               | Certificate key (PKCS-8)                                                                                                                                  | `/tls/tls.key`                                                                       |
| `tls.public.clientAuth`                   | mTLS configuration                                                                                                                                        |                                                                                      |
| `tls.public.clientAuth.type`              | Define whether clients need to authenticate as well. Allowed values: `none`, `optional` or `require`                                                      | `require`                                                                            |
| `tls.public.clientAuth.certChainFile`     | Certificate                                                                                                                                               | `/mtls/tls.crt`                                                                      |
| `tls.public.clientAuth.privateKeyFile`    | Certificate key (PKCS-8)                                                                                                                                  | `/mtls/tls.key`                                                                      |
| `tls.public.minimumServerProtocolVersion` | Minimum TLS version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html) | `TLSv1.3`                                                                            |
| `tls.public.ciphers`                      | Specify ciphers allowed, if empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)                             | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |
| `tls.admin.enabled`                       | Enable TLS on admin API (gRPC), Cert-manager CSI driver will automatically mount certificates in folders `/tls` and `/mtls`                               | `false`                                                                              |
| `tls.admin.trustCollectionFile`           | CA certificate, if empty `""` JVM default trust store is used                                                                                             | `/tls/ca.crt`                                                                        |
| `tls.admin.certChainFile`                 | Certificate                                                                                                                                               | `/tls/tls.crt`                                                                       |
| `tls.admin.privateKeyFile`                | Certificate key (PKCS-8)                                                                                                                                  | `/tls/tls.key`                                                                       |
| `tls.admin.clientAuth`                    | mTLS configuration                                                                                                                                        |                                                                                      |
| `tls.admin.clientAuth.type`               | Define whether clients need to authenticate as well (mTLS). Allowed values: `none`, `optional` or `require`                                               | `require`                                                                            |
| `tls.admin.clientAuth.certChainFile`      | Certificate                                                                                                                                               | `/mtls/tls.crt`                                                                      |
| `tls.admin.clientAuth.privateKeyFile`     | Certificate key (PKCS-8)                                                                                                                                  | `/mtls/tls.key`                                                                      |
| `tls.admin.minimumServerProtocolVersion`  | Minimum TLS version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html) | `TLSv1.3`                                                                            |
| `tls.admin.ciphers`                       | Specify ciphers allowed, if empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)                             | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |

### Authentication configuration

| Name                       | Description                                                                                              | Value                                 |
| -------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `authServices.enabled`     | Enabled JWT authentication                                                                               | `false`                               |
| `authServices.type`        | Certificate type of authorizations. Allowed values: `jwt-rs-256-crt`, `jwt-es-256-crt`, `jwt-es-512-crt` | `jwt-rs-256-jwks`                     |
| `authServices`             | `url`, `certificate` and `secret` are mutually exclusive, set only one and comment out the others        |                                       |
| `authServices.url`         | URL to JWKS (only for type `jwt-rs-256-jwks`)                                                            | `https://mydomain.com/auth/jwks.json` |
| `authServices.certificate` | Path to RS256 certificate used to sign JWTs (only for type `jwt-rs-256-crt`)                             |                                       |
| `authServices.secret`      | Plaintext secret (only for type `unsafe-jwt-hmac-256`)<br />**DO NOT USE IN PRODUCTION**                 |                                       |

### Container ports

| Name            | Description                                                                                 | Value  |
| --------------- | ------------------------------------------------------------------------------------------- | ------ |
| `ports.public`  | Ledger API container port (gRPC)                                                            | `4001` |
| `ports.admin`   | Admin API container port (gRPC)                                                             | `4002` |
| `ports.health`  | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled) | `4003` |
| `ports.metrics` | Promotheus exporter container port (HTTP)                                                   | `8081` |

### Deployment configuration

| Name                     | Description                                                             | Value |
| ------------------------ | ----------------------------------------------------------------------- | ----- |
| `environment`            | Container environment variables                                         | `{}`  |
| `environmentSecrets`     | Container secret environment variables                                  | `{}`  |
| `deployment.annotations` | Deployment extra annotations                                            | `{}`  |
| `deployment.labels`      | Deployment extra labels                                                 | `{}`  |
| `pod.annotations`        | Extra annotations for Deployment pods                                   | `{}`  |
| `pod.labels`             | Extra labels for Deployment pods                                        | `{}`  |
| `affinity`               | Affinity for pods assignment                                            | `{}`  |
| `nodeSelector`           | Node labels for pods assignment                                         | `{}`  |
| `resources`              | Resources requests/limits for Canton container                          | `{}`  |
| `tolerations`            | Tolerations for pods assignment                                         | `[]`  |
| `livenessProbe`          | Override `livenessProbe` default configuration                          | `{}`  |
| `readinessProbe`         | Override `readinessProbe` default configuration                         | `{}`  |
| `extraVolumeMounts`      | Specify extra list of additional volumeMounts for participant container | `[]`  |
| `extraVolumes`           | Specify extra list of additional volumes for participant pod            | `[]`  |

### Service configuration

| Name                    | Description                                                                          | Value       |
| ----------------------- | ------------------------------------------------------------------------------------ | ----------- |
| `service.type`          | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance` | `ClusterIP` |
| `service.annotations`   | Service extra annotations                                                            | `{}`        |
| `service.labels`        | Service extra labels                                                                 | `{}`        |
| `service.ports.public`  | Ledger API service port (gRPC)                                                       | `4001`      |
| `service.ports.admin`   | Admin API service port (gRPC)                                                        | `4002`      |
| `service.ports.metrics` | Promotheus exporter service port (HTTP)                                              | `8081`      |

### Ingress configuration

| Name                  | Description                                                                                                        | Value    |
| --------------------- | ------------------------------------------------------------------------------------------------------------------ | -------- |
| `ingress.enabled`     | Enable ingress to participant service port `public`, aka the Ledger API (gRPC)                                     | `false`  |
| `ingress.annotations` | Ingress extra annotations                                                                                          | `{}`     |
| `ingress.labels`      | Ingress extra labels                                                                                               | `{}`     |
| `ingress.className`   | Set `ingressClassName` on the ingress record                                                                       | `""`     |
| `ingress.host`        | Default host for the ingress resource (DNS record to cluster load balancer)                                        | `""`     |
| `ingress.path`        | Path to participant Ledger API                                                                                     | `/`      |
| `ingress.pathType`    | Determines the interpretation of the `Path` matching.  Allowed values: `Exact`, `Prefix`, `ImplementationSpecific` | `Prefix` |
| `ingress.tls`         | Enable TLS configuration for `hostname`                                                                            | `[]`     |

### Traefik IngressRouteTCP configuration

| Name                          | Description                                                                                                 | Value           |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------- | --------------- |
| `ingressRouteTCP.enabled`     | Enable Traefik `IngressRouteTCP` (CRD) to participant service port `public`, aka the Ledger API (gRPC)      | `false`         |
| `ingressRouteTCP.annotations` | IngressRouteTCP extra annotations                                                                           | `{}`            |
| `ingressRouteTCP.labels`      | IngressRouteTCP extra labels                                                                                | `{}`            |
| `ingressRouteTCP.entryPoints` | Traefik entrypoints for this IngressRouteTCP. Available by default: `web` (port 80), `websecure` (port 443) | `["websecure"]` |
| `ingressRouteTCP.hostSNI`     | DNS record to cluster load balancer                                                                         | `""`            |
| `ingressRouteTCP.tls`         | Define TLS certificate configuration                                                                        | `{}`            |

### Service Account

| Name                                          | Description                                                                                                         | Value   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`                       | Enable creation of ServiceAccount for participant pod(s)                                                            | `false` |
| `serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API  | `true`  |
| `serviceAccount.annotations`                  | Service Account extra annotations                                                                                   | `{}`    |
| `serviceAccount.labels`                       | Service Account extra labels                                                                                        | `{}`    |
| `serviceAccount.imagePullSecrets`             | List of references to secrets in the same namespace to use for pulling any images in pods using this ServiceAccount | `{}`    |
| `serviceAccount.secrets`                      | List of secrets allowed to be used by pods running using this ServiceAccount                                        | `{}`    |


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
