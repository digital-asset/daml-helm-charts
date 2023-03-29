# Canton Domain packed by Digital Asset

⚠️ _**Daml Enterprise only**_ ⚠️


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

Canton Domain HA deployment

Components:
* Bootstrap
* Console
* Domain Topology Manager (active/passive)
* Mediator (active/passive)
* Sequencer (active/active)

⚠️ Only PostgreSQL is supported as storage backend 🐘

---

## 🚦 Prerequisites 🚦

- Kubernetes 1.23+
- Helm 3.2+
- Preconfigured PostgreSQL for the Domain Topology Manager, Mediator and Sequencer
  - User
  - Password
  - Database
- Cert-manager + CSI driver (only if TLS is enabled)
- **Canton Enterprise docker images** copied to your own private Docker registry
- Canton Participant(s)

---

## TL;DR

```console
helm repo add digitalasset https://digital-asset.github.io/daml-helm-charts/
helm install mydomain digitalasset/canton-domain
```

### Minimum viable configuration

Example `mydomain` configuration bootstrapping a single `participant1` in namespace `canton` within the same Kubernetes cluster (TLS disabled):

```yaml
bootstrap:
  enabled: true

console:
  enabled: true

common:
  domainName: "mydomain"
  mediatorName: "mymediator"
  sequencerName: "mysequencer"
  remoteParticipants:
    - name: "participant1"
      host: "participant1-canton-participant.canton.svc.cluster.local"

storage:
  host: "<postgresql_server_host>"
  port: "<postgresql_server_port>"
  ssl: false

# Domain Topology Manager database, user, password
manager:
  storage:
    database: "<postgresql_database_name>"
    user: "<postgresql_user_name>"
    # Use value from specified Kubernetes secret key as PostgreSQL password
    existingSecret:
      name: "<k8s_secret_name>"
      key: "<k8s_secret_key>"

# Mediator database, user, password
mediator:
  storage:
    database: "<postgresql_database_name>"
    user: "<postgresql_user_name>"
    # Use value from specified Kubernetes secret key as PostgreSQL password
    existingSecret:
      name: "<k8s_secret_name>"
      key: "<k8s_secret_key>"

# Sequencer database, user, password
sequencer:
  storage:
    database: "<postgresql_database_name>"
    user: "<postgresql_user_name>"
    # Use value from specified Kubernetes secret key as PostgreSQL password
    existingSecret:
      name: "<k8s_secret_name>"
      key: "<k8s_secret_key>"
```


---
## Configuration and installation details

### Bootstrap

A Helm hook is used to initialize your domain and remote participant(s) listed in `common.remoteParticipants` just after all
the other resources from the Helm chart are successfully install. This Canton bootstrap **idempotent** script will run as a
Kubernetes job, it will be retried multiple times on errors before the overall Helm chart installation/upgrade is considered failed.

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

### Exposing the sequencer public API using Traefik (gRPC on HTTP/2 + TLS)

Requirements
* TLS is enabled and terminated by the Canton nodes
* Traefik Ingress Controller deployed inside your K8s cluster with its Custom Resource Definitions (CRDs)
* A network load balancer in front of your K8s cluster to reach the Ingress Controller
* A DNS record targeting the load balancer
* A Traefik custom resource `IngressRouteTCP` to expose the sequencer public API, forwarding traffic to sequencers
service port `public` with TLS passthrough

```
sequencer:
  ingressRouteTCP:
    enabled: true
    hostSNI: "mysequencer.mydomain.com"
    tls:
      passthrough: true
```

## Limitations

⚠️ **Upgrading to a different release is not supported for now** ⚠️

## Parameters

### Global parameters

| Name                | Description                                                                                           | Value                            |
| ------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------------- |
| `nameOverride`      | String to partially override `common.name` template (will maintain the release name)                  | `""`                             |
| `fullnameOverride`  | String to fully override `common.fullname` template                                                   | `""`                             |
| `image.registry`    | Canton Docker image registry                                                                          | `digitalasset-docker.jfrog.io`   |
| `image.repository`  | Canton Docker image repository                                                                        | `digitalasset/canton-enterprise` |
| `image.tag`         | Canton Docker image tag (immutable tags are recommended)                                              | `""`                             |
| `image.digest`      | Canton Docker image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag` | `""`                             |
| `image.pullPolicy`  | Canton Docker image pull policy. Allowed values: `Always`, `Never`, `IfNotPresent`                    | `IfNotPresent`                   |
| `image.pullSecrets` | Specify Canton Docker registry secret names as an array                                               | `[]`                             |
| `commonLabels`      | Add labels to all the deployed resources                                                              | `{}`                             |
| `metrics.enabled`   | Enable Prometheus metrics endpoint on Domain Topology Manager, Mediator and Sequencer                 | `false`                          |

### Global PostgreSQL configuration

| Name                          | Description                                                                                                                                                                                                   | Value          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
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

### Bootstrap configuration (not merged with `common` parameters)

| Name                                                     | Description                                                                                                                                 | Value                       |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| `bootstrap`                                              | Initialize your domain and remote participant(s) listed in `common.remoteParticipants`                                                      |                             |
| `bootstrap.enabled`                                      | Enable Job (Helm chart hook), will create one or more ephemeral Pods                                                                        | `false`                     |
| `bootstrap.backoffLimit`                                 | Specifies the number of retries before marking this job failed                                                                              | `2`                         |
| `bootstrap.activeDeadlineSeconds`                        | Specifies the duration in seconds relative to the startTime that the job may be continuously active before the system tries to terminate it | `600`                       |
| `bootstrap.participants`                                 | Participant(s) specific settings                                                                                                            |                             |
| `bootstrap.participants.resourceLimits`                  | Set Participant(s) resource limits                                                                                                          |                             |
| `bootstrap.participants.resourceLimits.maxRate`          | The maximum rate of command submissions through the Ledger API. Negative value = no limit.                                                  | `10000`                     |
| `bootstrap.participants.resourceLimits.maxDirtyRequests` | The maximum number of dirty requests. Negative value = no limit.                                                                            | `1000`                      |
| `bootstrap.logLevel`                                     | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`                                                           |                             |
| `bootstrap.logLevel.root`                                | Canton and external libraries, but not `stdout`                                                                                             | `INFO`                      |
| `bootstrap.logLevel.canton`                              | Only the Canton logger                                                                                                                      | `INFO`                      |
| `bootstrap.logLevel.stdout`                              | Usually the text displayed in the Canton console                                                                                            | `INFO`                      |
| `bootstrap.environment`                                  | Environment variables (not merged with `common.environment`)                                                                                | `{}`                        |
| `bootstrap.environmentSecrets`                           | Secret environment variables (not merged with `common.environmentSecrets`)                                                                  | `{}`                        |
| `bootstrap.job`                                          | Job and Helm hook configuration                                                                                                             |                             |
| `bootstrap.job.annotations`                              | Job extra annotations                                                                                                                       | `{}`                        |
| `bootstrap.job.labels`                                   | Job extra labels                                                                                                                            | `{}`                        |
| `bootstrap.job.helmHook`                                 | Annotation `helm.sh/hook` value                                                                                                             | `post-install,post-upgrade` |
| `bootstrap.job.helmHookWeight`                           | Annotation `helm.sh/hook-weight` value                                                                                                      | `5`                         |
| `bootstrap.job.helmHookDeletePolicy`                     | Annotation `helm.sh/hook-delete-policy` value                                                                                               | `before-hook-creation`      |
| `bootstrap.pod.annotations`                              | Extra annotations for Job pods                                                                                                              | `{}`                        |
| `bootstrap.pod.labels`                                   | Extra labels for Job pods                                                                                                                   | `{}`                        |
| `bootstrap.affinity`                                     | Affinity for pods assignment                                                                                                                | `{}`                        |
| `bootstrap.nodeSelector`                                 | Node labels for pods assignment                                                                                                             | `{}`                        |
| `bootstrap.resources`                                    | Resources requests/limits for bootstrap container                                                                                           | `{}`                        |
| `bootstrap.tolerations`                                  | Tolerations for pods assignment                                                                                                             | `[]`                        |
| `bootstrap.extraVolumeMounts`                            | Specify extra list of additional volumeMounts for bootstrap container                                                                       | `[]`                        |
| `bootstrap.extraVolumes`                                 | Specify extra list of additional volumes for bootstrap pod                                                                                  | `[]`                        |

### Console configuration (not merged with `common` parameters)

| Name                                    | Description                                                             | Value   |
| --------------------------------------- | ----------------------------------------------------------------------- | ------- |
| `console`                               | Single console pod for administration/debug of all the other components |         |
| `console.enabled`                       | Enable Deployment                                                       | `false` |
| `console.terminationGracePeriodSeconds` | Stop the pod immediately by default, tailing `/dev/null` to stay up     | `0`     |
| `console.deployment.annotations`        | Deployment extra annotations                                            | `{}`    |
| `console.deployment.labels`             | Deployment extra labels                                                 | `{}`    |
| `console.deployment.strategy`           | Deployment strategy                                                     | `{}`    |
| `console.pod.annotations`               | Extra annotations for Deployment pods                                   | `{}`    |
| `console.pod.labels`                    | Extra labels for Deployment pods                                        | `{}`    |
| `console.affinity`                      | Affinity for pods assignment                                            | `{}`    |
| `console.nodeSelector`                  | Node labels for pods assignment                                         | `{}`    |
| `console.resources`                     | Resources requests/limits for console container                         | `{}`    |
| `console.tolerations`                   | Tolerations for pods assignment                                         | `[]`    |
| `console.extraVolumeMounts`             | Specify extra list of additional volumeMounts for console container     | `[]`    |
| `console.extraVolumes`                  | Specify extra list of additional volumes for console pod                | `[]`    |

### Common parameters for all components

| Name                                                          | Description                                                                                                                                                                        | Value                                                                                |
| ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `common.domainName`                                           | Mandatory Canton Domain name                                                                                                                                                       | `mydomain`                                                                           |
| `common.mediatorName`                                         | Mandatory Canton Mediator name                                                                                                                                                     | `mymediator`                                                                         |
| `common.sequencerName`                                        | Mandatory Canton Sequencer name                                                                                                                                                    | `mysequencer`                                                                        |
| `common.remoteParticipants`                                   | List of remote Canton participants, only the `bootstrap` and `console`  will connect to them.<br />`name` and `host` are mandatory for each of them, otherwise the default is used | `[]`                                                                                 |
| `common.remoteParticipants[*].name`                           | Participant name                                                                                                                                                                   |                                                                                      |
| `common.remoteParticipants[*].host`                           | Participant hostname                                                                                                                                                               |                                                                                      |
| `common.remoteParticipants[*].ports.public`                   | Participant Ledger API port (gRPC)                                                                                                                                                 |                                                                                      |
| `common.remoteParticipants[*].ports.admin`                    | Participant admin port (gRPC)                                                                                                                                                      |                                                                                      |
| `common.remoteParticipants[*].tls`                            | Participant TLS configuration                                                                                                                                                      |                                                                                      |
| `common.remoteParticipants[*].tls.public.enabled`             | Enabled mTLS for Ledger API traffic                                                                                                                                                |                                                                                      |
| `common.remoteParticipants[*].tls.public.trustCollectionFile` | CA certificate                                                                                                                                                                     |                                                                                      |
| `common.remoteParticipants[*].tls.public.certChainFile`       | Certificate                                                                                                                                                                        |                                                                                      |
| `common.remoteParticipants[*].tls.public.privateKeyFile`      | Certificate key (PKCS-8)                                                                                                                                                           |                                                                                      |
| `common.remoteParticipants[*].tls.admin.enabled`              | Enabled mTLS for admin API traffic                                                                                                                                                 |                                                                                      |
| `common.remoteParticipants[*].tls.admin.trustCollectionFile`  | CA certificate                                                                                                                                                                     |                                                                                      |
| `common.remoteParticipants[*].tls.admin.certChainFile`        | Certificate                                                                                                                                                                        |                                                                                      |
| `common.remoteParticipants[*].tls.admin.privateKeyFile`       | Certificate key (PKCS-8)                                                                                                                                                           |                                                                                      |
| `common.logEncoder`                                           | Logging encoder. Allowed values: `plain`, `json`                                                                                                                                   | `plain`                                                                              |
| `common.tls`                                                  | TLS configuration                                                                                                                                                                  |                                                                                      |
| `common.tls.certManager`                                      | Cert-manager CSI driver configuration (onyly used when TLS is enabled)                                                                                                             |                                                                                      |
| `common.tls.certManager.issuerGroup`                          | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                                    | `cert-manager.io`                                                                    |
| `common.tls.certManager.issuerKind`                           | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                                       | `Issuer`                                                                             |
| `common.tls.certManager.issuerName`                           | Cert-manager issuer name                                                                                                                                                           | `my-cert-manager-issuer`                                                             |
| `common.tls.public`                                           | Only for `sequencer`                                                                                                                                                               |                                                                                      |
| `common.tls.public.enabled`                                   | Enable TLS on Ledger API (gRPC), Cert-manager CSI driver will automatically mount certificates in folders `/tls` and `/mtls`                                                       | `false`                                                                              |
| `common.tls.public.trustCollectionFile`                       | CA certificate, if empty `""` JVM default trust store is used                                                                                                                      | `/tls/ca.crt`                                                                        |
| `common.tls.public.certChainFile`                             | Certificate                                                                                                                                                                        | `/tls/tls.crt`                                                                       |
| `common.tls.public.privateKeyFile`                            | Certificate key (PKCS-8)                                                                                                                                                           | `/tls/tls.key`                                                                       |
| `common.tls.public.clientAuth`                                | mTLS configuration                                                                                                                                                                 |                                                                                      |
| `common.tls.public.clientAuth.type`                           | Define whether clients need to authenticate as well. Allowed values: `none`, `optional` or `require`                                                                               | `require`                                                                            |
| `common.tls.public.clientAuth.certChainFile`                  | Certificate                                                                                                                                                                        | `/mtls/tls.crt`                                                                      |
| `common.tls.public.clientAuth.privateKeyFile`                 | Certificate key (PKCS-8)                                                                                                                                                           | `/mtls/tls.key`                                                                      |
| `common.tls.public.minimumServerProtocolVersion`              | Minimum TLS version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[docs]]https://www.java.com/en/configure_crypto.html)                                    | `TLSv1.3`                                                                            |
| `common.tls.public.ciphers`                                   | Specify ciphers allowed, if empty `""` JVM defaults are used [[docs]]https://www.java.com/en/configure_crypto.html)                                                                | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |
| `common.tls.admin`                                            | For `manager`, `mediator` and `sequencer`                                                                                                                                          |                                                                                      |
| `common.tls.admin.enabled`                                    | Enable TLS on admin API (gRPC), Cert-manager CSI driver will automatically mount certificates in folders `/tls` and `/mtls`                                                        | `false`                                                                              |
| `common.tls.admin.trustCollectionFile`                        | CA certificate, if empty `""` JVM default trust store is used                                                                                                                      | `/tls/ca.crt`                                                                        |
| `common.tls.admin.certChainFile`                              | Certificate                                                                                                                                                                        | `/tls/tls.crt`                                                                       |
| `common.tls.admin.privateKeyFile`                             | Certificate key                                                                                                                                                                    | `/tls/tls.key`                                                                       |
| `common.tls.admin.clientAuth`                                 | mTLS configuration                                                                                                                                                                 |                                                                                      |
| `common.tls.admin.clientAuth.type`                            | Define whether clients need to authenticate as well (mTLS). Allowed values: `none`, `optional` or `require`                                                                        | `require`                                                                            |
| `common.tls.admin.clientAuth.certChainFile`                   | Certificate                                                                                                                                                                        | `/mtls/tls.crt`                                                                      |
| `common.tls.admin.clientAuth.privateKeyFile`                  | Certificate key                                                                                                                                                                    | `/mtls/tls.key`                                                                      |
| `common.tls.admin.minimumServerProtocolVersion`               | Minimum TLS version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[docs]]https://www.java.com/en/configure_crypto.html)                                    | `TLSv1.3`                                                                            |
| `common.tls.admin.ciphers`                                    | Specify ciphers allowed, if empty `""` JVM defaults are used [[docs]]https://www.java.com/en/configure_crypto.html)                                                                | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |
| `common.Service`                                              | Account for pods                                                                                                                                                                   |                                                                                      |
| `common.serviceAccount.create`                                | Enable creation of ServiceAccount for participant pod(s)                                                                                                                           | `false`                                                                              |
| `common.serviceAccount.automountServiceAccountToken`          | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                                                 | `true`                                                                               |
| `common.serviceAccount.annotations`                           | Service Account extra annotations                                                                                                                                                  | `{}`                                                                                 |
| `common.serviceAccount.labels`                                | Service Account extra labels                                                                                                                                                       | `{}`                                                                                 |
| `common.serviceAccount.imagePullSecrets`                      | List of references to secrets in the same namespace to use for pulling any images in pods using this ServiceAccount                                                                | `{}`                                                                                 |
| `common.serviceAccount.secrets`                               | List of secrets allowed to be used by pods running using this ServiceAccount                                                                                                       | `{}`                                                                                 |

### Common parameters for the `boostrap` and `console` only

| Name                                    | Description                              | Value   |
| --------------------------------------- | ---------------------------------------- | ------- |
| `common.features`                       | Enable additional commands               |         |
| `common.features.enablePreviewCommands` | Enable preview commands (unstable)       | `false` |
| `common.features.enableTestingCommands` | Enable testing commands (for developers) | `false` |
| `common.features.enableRepairCommands`  | Enable manual repair commands            | `false` |

### Common parameters for the `manager`, `mediator` and `sequencer` only

| Name                        | Description                                                                       | Value  |
| --------------------------- | --------------------------------------------------------------------------------- | ------ |
| `common.logLevel`           | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` |        |
| `common.logLevel.root`      | Canton and external libraries, but not `stdout`                                   | `INFO` |
| `common.logLevel.canton`    | Only the Canton logger                                                            | `INFO` |
| `common.logLevel.stdout`    | Usually the text displayed in the Canton console                                  | `INFO` |
| `common.environment`        | Environment variables                                                             | `{}`   |
| `common.environmentSecrets` | Secret environment variables                                                      | `{}`   |

### Domain Topology Manager configuration

| Name                                             | Description                                                                                                                                                                       | Value       |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `manager.storage.database`                       | Manager database name                                                                                                                                                             | `mydomain`  |
| `manager.storage.user`                           | Manager user name                                                                                                                                                                 | `canton`    |
| `manager.storage.existingSecret.name`            | Name of existing secret with user credentials                                                                                                                                     | `""`        |
| `manager.storage.existingSecret.key`             | Name of key in existing secret with user password                                                                                                                                 | `""`        |
| `manager.storage.maxConnections`                 | Database connection pool maximum connections                                                                                                                                      | `10`        |
| `manager.ports.admin`                            | Admin API container port (gRPC)                                                                                                                                                   | `4801`      |
| `manager.ports.health`                           | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled)                                                                                       | `4803`      |
| `manager.ports.metrics`                          | Promotheus exporter container port (HTTP)                                                                                                                                         | `8081`      |
| `manager.replicaCount`                           | Number of Domain Topology Manager pods to deploy. Allowed values: `1` (active/passive HA, scaling up does not work)                                                               | `1`         |
| `manager.environment`                            | Environment variables,merged with `common.environment`                                                                                                                            | `{}`        |
| `manager.environmentSecrets`                     | Secret environment variables,merged with `common.environmentSecrets`                                                                                                              | `{}`        |
| `manager.deployment.annotations`                 | Deployment extra annotations                                                                                                                                                      | `{}`        |
| `manager.deployment.labels`                      | Deployment extra labels                                                                                                                                                           | `{}`        |
| `manager.pod.annotations`                        | Extra annotations for Deployment pods                                                                                                                                             | `{}`        |
| `manager.pod.labels`                             | Extra labels for Deployment pods                                                                                                                                                  | `{}`        |
| `manager.affinity`                               | Affinity for pods assignment                                                                                                                                                      | `{}`        |
| `manager.nodeSelector`                           | Node labels for pods assignment                                                                                                                                                   | `{}`        |
| `manager.resources`                              | Resources requests/limits for manager container                                                                                                                                   | `{}`        |
| `manager.tolerations`                            | Tolerations for pods assignment                                                                                                                                                   | `[]`        |
| `manager.livenessProbe`                          | Override `livenessProbe` default configuration                                                                                                                                    | `{}`        |
| `manager.readinessProbe`                         | Override `readinessProbe` default configuration                                                                                                                                   | `{}`        |
| `manager.service.type`                           | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance`                                                                                              | `ClusterIP` |
| `manager.service.annotations`                    | Service extra annotations                                                                                                                                                         | `{}`        |
| `manager.service.labels`                         | Service extra labels                                                                                                                                                              | `{}`        |
| `manager.service.ports.admin`                    | Admin API service port (gRPC)                                                                                                                                                     | `4801`      |
| `manager.service.ports.metrics`                  | Promotheus exporter service port (HTTP)                                                                                                                                           | `8081`      |
| `manager.extraVolumeMounts`                      | Specify extra list of additional volumeMounts for bootstrap container                                                                                                             | `[]`        |
| `manager.extraVolumes`                           | Specify extra list of additional volumes for bootstrap pod                                                                                                                        | `[]`        |
| `manager.topology.open`                          | `true`: domain is open, anyone who can connect to the sequencer can join<br />`false`: new participants are only accepted if their `ParticipantState` has already been registered | `false`     |
| `manager.topology.requireParticipantCertificate` | Participant must provide a certificate of its identity before being added to the domain                                                                                           | `false`     |

### Mediator configuration

| Name                                   | Description                                                                                          | Value        |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------ |
| `mediator.storage.database`            | Mediator database name                                                                               | `mymediator` |
| `mediator.storage.user`                | Mediator user name                                                                                   | `canton`     |
| `mediator.storage.existingSecret.name` | Name of existing secret with user credentials                                                        | `""`         |
| `mediator.storage.existingSecret.key`  | Name of key in existing secret with user password                                                    | `""`         |
| `mediator.storage.maxConnections`      | Database connection pool maximum connections                                                         | `10`         |
| `mediator.ports.admin`                 | Admin API container port (gRPC)                                                                      | `4602`       |
| `mediator.ports.health`                | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled)          | `4603`       |
| `mediator.ports.metrics`               | Promotheus exporter container port (HTTP)                                                            | `8081`       |
| `mediator.replicaCount`                | Number of Mediator pods to deploy. Allowed values: `1` (active/passive HA, scaling up does not work) | `1`          |
| `mediator.environment`                 | Environment variables,merged with `common.environment`                                               | `{}`         |
| `mediator.environmentSecrets`          | Secret environment variables,merged with `common.environmentSecrets`                                 | `{}`         |
| `mediator.deployment.annotations`      | Deployment extra annotations                                                                         | `{}`         |
| `mediator.deployment.labels`           | Deployment extra labels                                                                              | `{}`         |
| `mediator.pod.annotations`             | Extra annotations for Deployment pods                                                                | `{}`         |
| `mediator.pod.labels`                  | Extra labels for Deployment pods                                                                     | `{}`         |
| `mediator.affinity`                    | Affinity for pods assignment                                                                         | `{}`         |
| `mediator.nodeSelector`                | Node labels for pods assignment                                                                      | `{}`         |
| `mediator.resources`                   | Resources requests/limits for manager container                                                      | `{}`         |
| `mediator.tolerations`                 | Tolerations for pods assignment                                                                      | `[]`         |
| `mediator.livenessProbe`               | Override `livenessProbe` default configuration                                                       | `{}`         |
| `mediator.readinessProbe`              | Override `readinessProbe` default configuration                                                      | `{}`         |
| `mediator.service.type`                | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance`                 | `ClusterIP`  |
| `mediator.service.annotations`         | Service extra annotations                                                                            | `{}`         |
| `mediator.service.labels`              | Service extra labels                                                                                 | `{}`         |
| `mediator.service.ports.admin`         | Admin API service port (gRPC)                                                                        | `4602`       |
| `mediator.service.ports.metrics`       | Promotheus exporter service port (HTTP)                                                              | `8081`       |
| `mediator.extraVolumeMounts`           | Specify extra list of additional volumeMounts for bootstrap container                                | `[]`         |
| `mediator.extraVolumes`                | Specify extra list of additional volumes for bootstrap pod                                           | `[]`         |

### Sequencer configuration

| Name                                        | Description                                                                                                        | Value           |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------- |
| `sequencer.storage.database`                | Sequencer database name                                                                                            | `mymediator`    |
| `sequencer.storage.user`                    | Sequencer user name                                                                                                | `canton`        |
| `sequencer.storage.existingSecret.name`     | Name of existing secret with user credentials                                                                      | `""`            |
| `sequencer.storage.existingSecret.key`      | Name of key in existing secret with user password                                                                  | `""`            |
| `sequencer.storage.maxConnections`          | Database connection pool maximum connections                                                                       | `10`            |
| `sequencer.ports.public`                    | Ledger API container port (gRPC)                                                                                   | `4401`          |
| `sequencer.ports.admin`                     | Admin API container port (gRPC)                                                                                    | `4402`          |
| `sequencer.ports.health`                    | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled)                        | `4403`          |
| `sequencer.ports.metrics`                   | Promotheus exporter container port (HTTP)                                                                          | `8081`          |
| `sequencer.replicaCount`                    | Number of Sequencer pods to deploy                                                                                 | `2`             |
| `sequencer.environment`                     | Environment variables,merged with `common.environment`                                                             | `{}`            |
| `sequencer.environmentSecrets`              | Secret environment variables,merged with `common.environmentSecrets`                                               | `{}`            |
| `sequencer.deployment.annotations`          | Deployment extra annotations                                                                                       | `{}`            |
| `sequencer.deployment.labels`               | Deployment extra labels                                                                                            | `{}`            |
| `sequencer.deployment.strategy`             | Deployment strategy                                                                                                | `{}`            |
| `sequencer.pod.annotations`                 | Extra annotations for Deployment pods                                                                              | `{}`            |
| `sequencer.pod.labels`                      | Extra labels for Deployment pods                                                                                   | `{}`            |
| `sequencer.affinity`                        | Affinity for pods assignment                                                                                       | `{}`            |
| `sequencer.nodeSelector`                    | Node labels for pods assignment                                                                                    | `{}`            |
| `sequencer.resources`                       | Resources requests/limits for manager container                                                                    | `{}`            |
| `sequencer.tolerations`                     | Tolerations for pods assignment                                                                                    | `[]`            |
| `sequencer.livenessProbe`                   | Override `livenessProbe` default configuration                                                                     | `{}`            |
| `sequencer.readinessProbe`                  | Override `readinessProbe` default configuration                                                                    | `{}`            |
| `sequencer.service.type`                    | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance`                               | `ClusterIP`     |
| `sequencer.service.annotations`             | Service extra annotations                                                                                          | `{}`            |
| `sequencer.service.labels`                  | Service extra labels                                                                                               | `{}`            |
| `sequencer.service.ports.public`            | Ledger API service port (gRPC)                                                                                     | `4401`          |
| `sequencer.service.ports.admin`             | Admin API service port (gRPC)                                                                                      | `4402`          |
| `sequencer.service.ports.metrics`           | Promotheus exporter service port (HTTP)                                                                            | `8081`          |
| `sequencer.service.sessionAffinity.enabled` | Enable `ClientIP` based session affinity                                                                           | `true`          |
| `sequencer.service.sessionAffinity.timeout` | Session timeout in seconds. Between `1` and `86400`                                                                | `3600`          |
| `sequencer.extraVolumeMounts`               | Specify extra list of additional volumeMounts for bootstrap container                                              | `[]`            |
| `sequencer.extraVolumes`                    | Specify extra list of additional volumes for bootstrap pod                                                         | `[]`            |
| `sequencer.ingress.enabled`                 | Enable ingress to sequencer service port `public` (gRPC)                                                           | `false`         |
| `sequencer.ingress.annotations`             | Ingress extra annotations                                                                                          | `{}`            |
| `sequencer.ingress.labels`                  | Ingress extra labels                                                                                               | `{}`            |
| `sequencer.ingress.className`               | Set `ingressClassName` on the ingress record                                                                       | `""`            |
| `sequencer.ingress.host`                    | Default host for the ingress resource (DNS record to cluster load balancer)                                        | `""`            |
| `sequencer.ingress.path`                    | Path to sequencer **public API**                                                                                   | `/`             |
| `sequencer.ingress.pathType`                | Determines the interpretation of the `Path` matching.  Allowed values: `Exact`, `Prefix`, `ImplementationSpecific` | `Prefix`        |
| `sequencer.ingress.tls`                     | Enable TLS configuration for `hostname`                                                                            | `[]`            |
| `sequencer.ingressRouteTCP.enabled`         | Enable Traefik `IngressRouteTCP` (CRD) to sequencer service port `public` (gRPC)                                   | `false`         |
| `sequencer.ingressRouteTCP.annotations`     | IngressRouteTCP extra annotations                                                                                  | `{}`            |
| `sequencer.ingressRouteTCP.labels`          | IngressRouteTCP extra labels                                                                                       | `{}`            |
| `sequencer.ingressRouteTCP.entryPoints`     | Traefik entrypoints for this IngressRouteTCP. Available by default: `web` (port 80), `websecure` (port 443)        | `["websecure"]` |
| `sequencer.ingressRouteTCP.hostSNI`         | DNS record to cluster load balancer                                                                                | `""`            |
| `sequencer.ingressRouteTCP.tls`             | Define TLS certificate configuration                                                                               | `{}`            |

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
