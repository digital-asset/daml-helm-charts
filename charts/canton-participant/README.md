# Canton Participant packed by Digital Asset

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

Canton Participant HA deployment (active/passive)

⚠️ Only PostgreSQL 🐘 is supported as storage backend, check our
[guidelines](https://github.com/digital-asset/daml-helm-charts/blob/main/POSTGRES.md).

---
## 🚦 Prerequisites 🚦

- Kubernetes `1.24+`
- Helm `3.9+`
- Preconfigured PostgreSQL resources for the Participant:
  - User/password
  - Database
- [Cert-manager](https://cert-manager.io/docs/) + CSI driver (only if TLS is enabled, optional but strongly recommended)
- Canton Domain

---
## TL;DR

```console
helm repo add digitalasset https://digital-asset.github.io/daml-helm-charts/
helm install participant1 digitalasset/canton-participant
```

### Minimum viable configuration

Example participant `participant1` configuration (bootstrapped by a domain in namespace `canton` within the same Kubernetes cluster).

⚠️ _TLS and JWT authentication are disabled_

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

---
## Configuration and installation details

### Bootstrap

Bootstrap is done in the Canton Domain Helm chart for now.

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
  public:
    enabled: true
    certManager:
      issuerName: "my-cert-manager-issuer"
```

#### Custom secrets

You must provide an existing secret with the required certificates.

Example with secret `participant1-tls-public` for the public endpoint used in participant deployment volume mount `tls-public`:

```yaml
tls:
  public:
    enabled: true
    ca: "/tls-public/ca.crt"
    chain: "/tls-public/chain.crt"
    key: "/tls-public/tls.key"

extraVolumes:
  - name: tls-public
    secret:
      secretName: participant1-tls-public
```

This secret must contain data with the right key names `ca.crt`, `chain.crt` and `tls.key`,
it will be mounted as files into folder `/tls-public`.

⚠️ _If you enable the bootstrap and/or console, do not forget to also provide them a certificate._

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

### Limitations

⚠️ **Upgrading to a different release is not supported for now** ⚠️

---
## Parameters

### Common parameters

| Name                      | Description                                                                                               | Value                          |
| ------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `nameOverride`            | String to partially override `common.name` template (will maintain the release name)                      | `""`                           |
| `fullnameOverride`        | String to fully override `common.fullname` template                                                       | `""`                           |
| `replicaCount`            | Number of Participant pods to deploy. Allowed values: `1` (active/passive HA, scaling up does not work)   | `1`                            |
| `image.registry`          | Canton Docker image registry                                                                              | `digitalasset-docker.jfrog.io` |
| `image.repository`        | Canton Docker image repository                                                                            | `canton-enterprise`            |
| `image.tag`               | Canton Docker image tag (immutable tags are recommended)                                                  | `""`                           |
| `image.digest`            | Canton Docker image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag`     | `""`                           |
| `image.pullPolicy`        | Canton Docker image pull policy. Allowed values: `Always`, `Never`, `IfNotPresent`                        | `IfNotPresent`                 |
| `image.pullSecrets`       | Specify Docker registry existing secret names as an array                                                 | `[]`                           |
| `commonLabels`            | Add labels to all the deployed resources                                                                  | `{}`                           |
| `certManager.duration`    | Cert-manager requested certificates validity period. If empty `""` defaults to `720h`                     | `87660h`                       |
| `certManager.renewBefore` | Cert-manager time to renew the certificate before expiry. If empty `""` defaults to a third of `duration` | `1h`                           |

### Participant configuration

| Name                          | Description                                                                                                                                 | Value          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `participantName`             | Mandatory Canton Participant name                                                                                                           | `participant1` |
| `uniqueContractKeys`          | When enabled, Participant can only connect to a Domain with unique contract keys enabled as well                                            | `false`        |
| `storage`                     | PostgreSQL configuration                                                                                                                    |                |
| `storage.host`                | Server hostname                                                                                                                             | `postgres`     |
| `storage.port`                | Server port                                                                                                                                 | `5432`         |
| `storage.database`            | Database name                                                                                                                               | `participant1` |
| `storage.user`                | User name                                                                                                                                   | `canton`       |
| `storage.existingSecret.name` | Name of existing secret with user credentials                                                                                               | `""`           |
| `storage.existingSecret.key`  | Name of key in existing secret with user password                                                                                           | `""`           |
| `storage.ssl`                 | Enable TLS connection                                                                                                                       | `true`         |
| `storage.sslMode`             | TLS mode. Allowed values: `disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`                                               | `require`      |
| `storage.sslRootCert`         | CA certificate file (PEM encoded X509v3). Intermediate certificate(s) that chain up to this root certificate can also appear in this file.  | `""`           |
| `storage.sslCert`             | Client certificate file (PEM encoded X509v3)                                                                                                | `""`           |
| `storage.sslKey`              | Client certificate key file (PKCS-12 or PKCS-8 DER)                                                                                         | `""`           |
| `storage.certificatesSecret`  | Name of an existing K8s secret that contains certificate files, mounted to `/pgtls` if not empty, provide K8s secret key names as filenames | `""`           |
| `storage.maxConnections`      | Database connection pool maximum connections                                                                                                | `10`           |

### Bootstrap configuration

| Name                                                    | Description                                                                                                                                                            | Value                       |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| `bootstrap`                                             | Initialize your participant, connecting to a remote sequencer                                                                                                          |                             |
| `bootstrap.enabled`                                     | Enable Job (Helm chart hook), will create one or more ephemeral Pods                                                                                                   | `false`                     |
| `bootstrap.backoffLimit`                                | Specifies the number of retries before marking this job failed                                                                                                         | `2`                         |
| `bootstrap.activeDeadlineSeconds`                       | Specifies the duration in seconds relative to the startTime that the job may be continuously active before the system tries to terminate it                            | `600`                       |
| `bootstrap.commandsTimeout`                             | Script commands timeout. Example values: `10s`, `10m' or `10h`                                                                                                         | `1m`                        |
| `bootstrap.remoteSequencer`                             | Remote sequencer connection configuration                                                                                                                              |                             |
| `bootstrap.remoteSequencer.domainAlias`                 | Domain alias                                                                                                                                                           | `mydomain`                  |
| `bootstrap.remoteSequencer.domainId`                    | Mandatory Domain ID                                                                                                                                                    | `""`                        |
| `bootstrap.remoteSequencer.host`                        | Sequencer host                                                                                                                                                         | `mysequencer.domain.com`    |
| `bootstrap.remoteSequencer.port`                        | Sequencer port, if empty `""` HTTP/HTTPS default is used (`80`/`443`)                                                                                                  | `""`                        |
| `bootstrap.remoteSequencer.tls.enabled`                 | Enable TLS to Sequencer                                                                                                                                                | `false`                     |
| `bootstrap.remoteSequencer.tls.certManager`             | Cert-manager CSI driver configuration (only used if TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/tls-<domain_alias>` |                             |
| `bootstrap.remoteSequencer.tls.certManager.issuerGroup` | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                        | `cert-manager.io`           |
| `bootstrap.remoteSequencer.tls.certManager.issuerKind`  | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                           | `Issuer`                    |
| `bootstrap.remoteSequencer.tls.certManager.issuerName`  | Cert-manager issuer name                                                                                                                                               | `""`                        |
| `bootstrap.remoteSequencer.tls.certManager.fsGroup`     | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                                         | `65532`                     |
| `bootstrap.remoteSequencer.tls.ca`                      | CA certificate, if empty `""` JVM default trust store is used                                                                                                          | `/tls-mydomain/ca.crt`      |
| `bootstrap.remoteSequencer.initialRetryDelay`           | Initial retry delay. Example values: `10s`, `10m' or `10h`                                                                                                             | `30s`                       |
| `bootstrap.remoteSequencer.maxRetryDelay`               | Maximum retry delay. Example values: `10s`, `10m' or `10h`                                                                                                             | `10m`                       |
| `bootstrap.logLevel`                                    | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`                                                                                      |                             |
| `bootstrap.logLevel.root`                               | Canton and external libraries, but not `stdout`                                                                                                                        | `INFO`                      |
| `bootstrap.logLevel.canton`                             | Only the Canton logger                                                                                                                                                 | `INFO`                      |
| `bootstrap.logLevel.stdout`                             | Usually the text displayed in the Canton console                                                                                                                       | `INFO`                      |
| `bootstrap.environment`                                 | Environment variables                                                                                                                                                  | `{}`                        |
| `bootstrap.environmentSecrets`                          | Secret environment variables                                                                                                                                           | `{}`                        |
| `bootstrap.job`                                         | Bootstrap Job and Helm hook configuration                                                                                                                              |                             |
| `bootstrap.job.annotations`                             | Job extra annotations                                                                                                                                                  | `{}`                        |
| `bootstrap.job.labels`                                  | Job extra labels                                                                                                                                                       | `{}`                        |
| `bootstrap.job.helmHook`                                | Annotation `helm.sh/hook` value                                                                                                                                        | `post-install,post-upgrade` |
| `bootstrap.job.helmHookWeight`                          | Annotation `helm.sh/hook-weight` value                                                                                                                                 | `5`                         |
| `bootstrap.job.helmHookDeletePolicy`                    | Annotation `helm.sh/hook-delete-policy` value                                                                                                                          | `before-hook-creation`      |
| `bootstrap.pod.annotations`                             | Extra annotations for bootstrap Job pods                                                                                                                               | `{}`                        |
| `bootstrap.pod.labels`                                  | Extra labels for bootstrap Job pods                                                                                                                                    | `{}`                        |
| `bootstrap.pod.securityContext.enabled`                 | Enable bootstrap Job pods Security Context                                                                                                                             | `true`                      |
| `bootstrap.pod.securityContext.fsGroup`                 | Special supplemental GID that applies to all containers in a pod                                                                                                       | `65532`                     |
| `bootstrap.pod.securityContext.fsGroupChangePolicy`     | Defines behavior of changing ownership and permission of the volume before being exposed inside pods. Valid values are `OnRootMismatch` and `Always`                   | `Always`                    |
| `bootstrap.pod.securityContext.sysctls`                 | List of namespaced sysctls used for the pod                                                                                                                            | `[]`                        |
| `bootstrap.securityContext.enabled`                     | Enable bootstrap container Security Context                                                                                                                            | `true`                      |
| `bootstrap.securityContext.readOnlyRootFilesystem`      | Whether this container has a read-only root filesystem                                                                                                                 | `false`                     |
| `bootstrap.securityContext.runAsGroup`                  | The GID to run the entrypoint of the container process                                                                                                                 | `65532`                     |
| `bootstrap.securityContext.runAsNonRoot`                | Indicates that the container must run as a non-root user                                                                                                               | `true`                      |
| `bootstrap.securityContext.runAsUser`                   | The UID to run the entrypoint of the container process                                                                                                                 | `65532`                     |
| `bootstrap.affinity`                                    | Affinity for pods assignment                                                                                                                                           | `{}`                        |
| `bootstrap.nodeSelector`                                | Node labels for pods assignment                                                                                                                                        | `{}`                        |
| `bootstrap.resources`                                   | Resources requests/limits for bootstrap container                                                                                                                      | `{}`                        |
| `bootstrap.tolerations`                                 | Tolerations for pods assignment                                                                                                                                        | `[]`                        |
| `bootstrap.extraVolumeMounts`                           | Specify extra list of additional volumeMounts for bootstrap container                                                                                                  | `[]`                        |
| `bootstrap.extraVolumes`                                | Specify extra list of additional volumes for bootstrap pod                                                                                                             | `[]`                        |
| `bootstrap.serviceAccount.create`                       | Creation of `ServiceAccount` for bootstrap pod(s) is enabled with global switch `serviceAccount.create`                                                                |                             |
| `bootstrap.serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                                     | `false`                     |
| `bootstrap.serviceAccount.annotations`                  | Service Account extra annotations                                                                                                                                      | `{}`                        |
| `bootstrap.serviceAccount.labels`                       | Service Account extra labels                                                                                                                                           | `{}`                        |
| `bootstrap.serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                                                                     | `[]`                        |
| `bootstrap.rbac.create`                                 | Creation of RBAC resources for bootstrap pod(s) is enabled with global switch `rbac.create`                                                                            |                             |
| `bootstrap.rbac.rules`                                  | Custom RBAC rules to set                                                                                                                                               | `[]`                        |

### Console configuration

| Name                                                  | Description                                                                                                                                          | Value                     |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| `console`                                             | Single console pod for administration/debug of all the other components                                                                              |                           |
| `console.enabled`                                     | Enable Deployment                                                                                                                                    | `false`                   |
| `console.terminationGracePeriodSeconds`               | Stop the pod immediately by default, tailing `/dev/null` to stay up                                                                                  | `0`                       |
| `console.image`                                       | Specific Docker image to be able to start a Canton console. Reusing `image.registry`, `image.pullPolicy` and `image.pullSecrets`                     |                           |
| `console.image.repository`                            | Canton console Docker image repository                                                                                                               | `canton-enterprise-debug` |
| `console.image.tag`                                   | Canton console Docker image tag (immutable tags are recommended)                                                                                     | `""`                      |
| `console.image.digest`                                | Canton console Docker image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag`                                        | `""`                      |
| `console.environment`                                 | Environment variables                                                                                                                                | `{}`                      |
| `console.environmentSecrets`                          | Secret environment variables                                                                                                                         | `{}`                      |
| `console.deployment.annotations`                      | Deployment extra annotations                                                                                                                         | `{}`                      |
| `console.deployment.labels`                           | Deployment extra labels                                                                                                                              | `{}`                      |
| `console.deployment.strategy`                         | Deployment strategy                                                                                                                                  | `{}`                      |
| `console.pod.annotations`                             | Extra annotations for console Deployment pods                                                                                                        | `{}`                      |
| `console.pod.labels`                                  | Extra labels for console Deployment pods                                                                                                             | `{}`                      |
| `console.pod.securityContext.enabled`                 | Enable console Deployment pods Security Context                                                                                                      | `true`                    |
| `console.pod.securityContext.fsGroup`                 | Special supplemental GID that applies to all containers in a pod                                                                                     | `65532`                   |
| `console.pod.securityContext.fsGroupChangePolicy`     | Defines behavior of changing ownership and permission of the volume before being exposed inside pods. Valid values are `OnRootMismatch` and `Always` | `Always`                  |
| `console.pod.securityContext.sysctls`                 | List of namespaced sysctls used for the pod                                                                                                          | `[]`                      |
| `console.securityContext.enabled`                     | Enable console container Security Context                                                                                                            | `true`                    |
| `console.securityContext.readOnlyRootFilesystem`      | Whether this container has a read-only root filesystem                                                                                               | `false`                   |
| `console.securityContext.runAsGroup`                  | The GID to run the entrypoint of the container process                                                                                               | `65532`                   |
| `console.securityContext.runAsNonRoot`                | Indicates that the container must run as a non-root user                                                                                             | `true`                    |
| `console.securityContext.runAsUser`                   | The UID to run the entrypoint of the container process                                                                                               | `65532`                   |
| `console.affinity`                                    | Affinity for pods assignment                                                                                                                         | `{}`                      |
| `console.nodeSelector`                                | Node labels for pods assignment                                                                                                                      | `{}`                      |
| `console.resources`                                   | Resources requests/limits for console container                                                                                                      | `{}`                      |
| `console.tolerations`                                 | Tolerations for pods assignment                                                                                                                      | `[]`                      |
| `console.extraVolumeMounts`                           | Specify extra list of additional volumeMounts for console container                                                                                  | `[]`                      |
| `console.extraVolumes`                                | Specify extra list of additional volumes for console pod                                                                                             | `[]`                      |
| `console.serviceAccount.create`                       | Creation of `ServiceAccount` for console pod(s) is enabled with global switch `serviceAccount.create`                                                |                           |
| `console.serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                   | `false`                   |
| `console.serviceAccount.annotations`                  | Service Account extra annotations                                                                                                                    | `{}`                      |
| `console.serviceAccount.labels`                       | Service Account extra labels                                                                                                                         | `{}`                      |
| `console.serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                                                   | `[]`                      |
| `console.rbac.create`                                 | Creation of RBAC resources for console pod(s) is enabled with global switch `rbac.create`                                                            |                           |
| `console.rbac.rules`                                  | Custom RBAC rules to set                                                                                                                             | `[]`                      |

### Common parameters for the `boostrap` and `console` only

| Name                                    | Description                              | Value   |
| --------------------------------------- | ---------------------------------------- | ------- |
| `common.features`                       | Enable additional commands               |         |
| `common.features.enablePreviewCommands` | Enable preview commands (unstable)       | `false` |
| `common.features.enableTestingCommands` | Enable testing commands (for developers) | `false` |
| `common.features.enableRepairCommands`  | Enable manual repair commands            | `false` |

### Logging

| Name              | Description                                                                       | Value   |
| ----------------- | --------------------------------------------------------------------------------- | ------- |
| `logLevel`        | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` |         |
| `logLevel.root`   | Canton and external libraries, but not `stdout`                                   | `INFO`  |
| `logLevel.canton` | Only the Canton logger                                                            | `INFO`  |
| `logLevel.stdout` | Usually the text displayed in the Canton console                                  | `INFO`  |
| `logEncoder`      | Logging encoder. Allowed values: `plain`, `json`                                  | `plain` |

### TLS configuration

| Name                                      | Description                                                                                                                                                      | Value                                                                                |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `tls.public.enabled`                      | Enable TLS on Ledger API (gRPC)                                                                                                                                  | `false`                                                                              |
| `tls.public.certManager`                  | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/tls-public` |                                                                                      |
| `tls.public.certManager.issuerGroup`      | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                  | `cert-manager.io`                                                                    |
| `tls.public.certManager.issuerKind`       | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                     | `Issuer`                                                                             |
| `tls.public.certManager.issuerName`       | Cert-manager issuer name                                                                                                                                         | `""`                                                                                 |
| `tls.public.certManager.fsGroup`          | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                                   | `65532`                                                                              |
| `tls.public.certManager.ipSans`           | IP addresses the certificate will be requested for.                                                                                                              | `0.0.0.0`                                                                            |
| `tls.public.ca`                           | CA certificate, if empty `""` JVM default trust store is used                                                                                                    | `/tls-public/ca.crt`                                                                 |
| `tls.public.chain`                        | Certificate chain                                                                                                                                                | `/tls-public/tls.crt`                                                                |
| `tls.public.key`                          | Certificate private key (PKCS-8)                                                                                                                                 | `/tls-public/tls.key`                                                                |
| `tls.public.minimumServerProtocolVersion` | Minimum version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)            | `TLSv1.3`                                                                            |
| `tls.public.ciphers`                      | Specify ciphers allowed, if empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)                                    | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |
| `tls.admin.enabled`                       | Enable TLS on admin API (gRPC)                                                                                                                                   | `false`                                                                              |
| `tls.admin.certManager`                   | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/tls-admin`  |                                                                                      |
| `tls.admin.certManager.issuerGroup`       | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                  | `cert-manager.io`                                                                    |
| `tls.admin.certManager.issuerKind`        | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                     | `Issuer`                                                                             |
| `tls.admin.certManager.issuerName`        | Cert-manager issuer name                                                                                                                                         | `""`                                                                                 |
| `tls.admin.certManager.fsGroup`           | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                                   | `65532`                                                                              |
| `tls.admin.ca`                            | CA certificate, if empty `""` JVM default trust store is used                                                                                                    | `/tls-admin/ca.crt`                                                                  |
| `tls.admin.chain`                         | Certificate chain                                                                                                                                                | `/tls-admin/tls.crt`                                                                 |
| `tls.admin.key`                           | Certificate private key (PKCS-8)                                                                                                                                 | `/tls-admin/tls.key`                                                                 |
| `tls.admin.minimumServerProtocolVersion`  | Minimum version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)            | `TLSv1.3`                                                                            |
| `tls.admin.ciphers`                       | Specify ciphers allowed, if empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)                                    | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |

### mTLS configuration

| Name                                  | Description                                                                                                                                                       | Value                  |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| `mtls.public.enabled`                 | Define whether clients need to authenticate as well using mTLS                                                                                                    | `false`                |
| `mtls.public.certManager`             | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/mtls-public` |                        |
| `mtls.public.certManager.issuerGroup` | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                   | `cert-manager.io`      |
| `mtls.public.certManager.issuerKind`  | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                      | `Issuer`               |
| `mtls.public.certManager.issuerName`  | Cert-manager issuer name                                                                                                                                          | `""`                   |
| `mtls.public.certManager.fsGroup`     | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                                    | `65532`                |
| `mtls.public.ca`                      | CA certificate, if empty `""` JVM default trust store is used                                                                                                     | `/mtls-public/ca.crt`  |
| `mtls.public.chain`                   | Certificate chain                                                                                                                                                 | `/mtls-public/tls.crt` |
| `mtls.public.key`                     | Certificate private key (PKCS-8)                                                                                                                                  | `/mtls-public/tls.key` |
| `mtls.admin.enabled`                  | Define whether clients need to authenticate as well using mTLS                                                                                                    | `false`                |
| `mtls.admin.certManager`              | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/mtls-admin`  |                        |
| `mtls.admin.certManager.issuerGroup`  | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                   | `cert-manager.io`      |
| `mtls.admin.certManager.issuerKind`   | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                      | `Issuer`               |
| `mtls.admin.certManager.issuerName`   | Cert-manager issuer name                                                                                                                                          | `""`                   |
| `mtls.admin.certManager.fsGroup`      | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                                    | `65532`                |
| `mtls.admin.ca`                       | CA certificate, if empty `""` JVM default trust store is used                                                                                                     | `/mtls-admin/ca.crt`   |
| `mtls.admin.chain`                    | Certificate chain                                                                                                                                                 | `/mtls-admin/tls.crt`  |
| `mtls.admin.key`                      | Certificate private key (PKCS-8)                                                                                                                                  | `/mtls-admin/tls.key`  |

### Authentication configuration

| Name                          | Description                                                                                                      | Value                                 |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `authServices.enabled`        | Enabled JWT authentication                                                                                       | `false`                               |
| `authServices.type`           | Type of authorization. Allowed values: `jwt-rs-256-jwks`, `jwt-rs-256-crt`, `jwt-es-256-crt`, `jwt-es-512-crt`   | `jwt-rs-256-jwks`                     |
| `authServices.url`            | URL to JWKS (only used for type `jwt-rs-256-jwks`)                                                               | `https://mydomain.com/auth/jwks.json` |
| `authServices.certificate`    | Path to certificate used to sign JWTs (only used for types `jwt-rs-256-crt`, `jwt-es-256-crt`, `jwt-es-512-crt`) | `/path/to/jwt.crt`                    |
| `authServices.targetAudience` | Custom JWT token audience                                                                                        | `""`                                  |

### Container ports

| Name            | Description                                                                                 | Value  |
| --------------- | ------------------------------------------------------------------------------------------- | ------ |
| `ports.public`  | Ledger API container port (gRPC)                                                            | `4001` |
| `ports.admin`   | Admin API container port (gRPC)                                                             | `4002` |
| `ports.health`  | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled) | `4003` |
| `ports.metrics` | Promotheus exporter container port (HTTP)                                                   | `8081` |

### Deployment configuration

| Name                                      | Description                                                                                                                                          | Value    |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `environment`                             | Container environment variables                                                                                                                      | `{}`     |
| `environmentSecrets`                      | Container secret environment variables                                                                                                               | `{}`     |
| `deployment.annotations`                  | Deployment extra annotations                                                                                                                         | `{}`     |
| `deployment.labels`                       | Deployment extra labels                                                                                                                              | `{}`     |
| `pod.annotations`                         | Extra annotations for Deployment pods                                                                                                                | `{}`     |
| `pod.labels`                              | Extra labels for Deployment pods                                                                                                                     | `{}`     |
| `pod.securityContext.enabled`             | Enable pods Security Context                                                                                                                         | `true`   |
| `pod.securityContext.fsGroup`             | Special supplemental GID that applies to all containers in a pod                                                                                     | `65532`  |
| `pod.securityContext.fsGroupChangePolicy` | Defines behavior of changing ownership and permission of the volume before being exposed inside pods. Valid values are `OnRootMismatch` and `Always` | `Always` |
| `pod.securityContext.sysctls`             | List of namespaced sysctls used for the pod                                                                                                          | `[]`     |
| `securityContext.enabled`                 | Enable containers Security Context                                                                                                                   | `true`   |
| `securityContext.readOnlyRootFilesystem`  | Whether this container has a read-only root filesystem                                                                                               | `false`  |
| `securityContext.runAsGroup`              | The GID to run the entrypoint of the container process                                                                                               | `65532`  |
| `securityContext.runAsNonRoot`            | Indicates that the container must run as a non-root user                                                                                             | `true`   |
| `securityContext.runAsUser`               | The UID to run the entrypoint of the container process                                                                                               | `65532`  |
| `affinity`                                | Affinity for pods assignment                                                                                                                         | `{}`     |
| `nodeSelector`                            | Node labels for pods assignment                                                                                                                      | `{}`     |
| `resources`                               | Resources requests/limits for Canton container                                                                                                       | `{}`     |
| `tolerations`                             | Tolerations for pods assignment                                                                                                                      | `[]`     |
| `livenessProbe`                           | Override `livenessProbe` default configuration                                                                                                       | `{}`     |
| `readinessProbe`                          | Override `readinessProbe` default configuration                                                                                                      | `{}`     |
| `extraVolumeMounts`                       | Specify extra list of additional volumeMounts for participant container                                                                              | `[]`     |
| `extraVolumes`                            | Specify extra list of additional volumes for participant pod                                                                                         | `[]`     |

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
| `metrics.podMonitor.enabled`                  | Creates a Prometheus Operator PodMonitor (also requires `metrics.enabled` to be `true`)                            | `false` |
| `metrics.podMonitor.labels`                   | Pod Monitor extra labels                                                                                           | `{}`    |
| `metrics.podMonitor.jobLabel`                 | The label to use to retrieve the job name from                                                                     | `""`    |
| `metrics.podMonitor.podTargetLabels`          | PodTargetLabels transfers labels on the Kubernetes Pod onto the target                                             | `[]`    |
| `metrics.podMonitor.extraPodMetricsEndpoints` | Extra scrapeable endpoint configuration                                                                            | `[]`    |
| `metrics.podMonitor.sampleLimit`              | Per-scrape limit on number of scraped samples that will be accepted                                                | `0`     |
| `metrics.podMonitor.targetLimit`              | Limit on the number of scraped targets that will be accepted                                                       | `0`     |
| `metrics.podMonitor.labelLimit`               | Per-scrape limit on number of labels that will be accepted for a sample (Prometheus versions 2.27 and newer)       | `0`     |
| `metrics.podMonitor.labelNameLengthLimit`     | Per-scrape limit on length of labels name that will be accepted for a sample (Prometheus versions 2.27 and newer)  | `0`     |
| `metrics.podMonitor.labelValueLengthLimit`    | Per-scrape limit on length of labels value that will be accepted for a sample (Prometheus versions 2.27 and newer) | `0`     |

### Automated testing configuration (do not use in production)

| Name                                                                 | Description                                                                                                                                                             | Value                          |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `testing.bootstrap.automaticDomainRegistration`                      | Automatically adds the participant in the domain allow-list.                                                                                                            | `false`                        |
| `testing.bootstrap.remoteDomainManager`                              | Remote domain manager connection configuration                                                                                                                          |                                |
| `testing.bootstrap.remoteDomainManager.host`                         | Domain manager host                                                                                                                                                     | `""`                           |
| `testing.bootstrap.remoteDomainManager.port`                         | Domain manager port                                                                                                                                                     | `4801`                         |
| `testing.bootstrap.remoteDomainManager.tls.enabled`                  | Enable TLS to Domain manager                                                                                                                                            | `false`                        |
| `testing.bootstrap.remoteDomainManager.tls.certManager`              | Cert-manager CSI driver configuration (only used if TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/tls-domain-manager`  |                                |
| `testing.bootstrap.remoteDomainManager.tls.certManager.issuerGroup`  | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                         | `cert-manager.io`              |
| `testing.bootstrap.remoteDomainManager.tls.certManager.issuerKind`   | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                            | `Issuer`                       |
| `testing.bootstrap.remoteDomainManager.tls.certManager.issuerName`   | Cert-manager issuer name                                                                                                                                                | `""`                           |
| `testing.bootstrap.remoteDomainManager.tls.certManager.fsGroup`      | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                                          | `65532`                        |
| `testing.bootstrap.remoteDomainManager.tls.ca`                       | CA certificate, if empty `""` JVM default trust store is used                                                                                                           | `/tls-domain-manager/ca.crt`   |
| `testing.bootstrap.remoteDomainManager.mtls.enabled`                 | Enable mTLS to Domain manager                                                                                                                                           | `false`                        |
| `testing.bootstrap.remoteDomainManager.mtls.certManager`             | Cert-manager CSI driver configuration (only used if TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/mtls-domain-manager` |                                |
| `testing.bootstrap.remoteDomainManager.mtls.certManager.issuerGroup` | Cert-Manager issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc.                                         | `cert-manager.io`              |
| `testing.bootstrap.remoteDomainManager.mtls.certManager.issuerKind`  | Cert-Manager issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                                                            | `Issuer`                       |
| `testing.bootstrap.remoteDomainManager.mtls.certManager.issuerName`  | Cert-manager issuer name                                                                                                                                                | `""`                           |
| `testing.bootstrap.remoteDomainManager.mtls.certManager.fsGroup`     | Cert-manager FS Group of mounted files, should be paired with and match container `runAsGroup`                                                                          | `65532`                        |
| `testing.bootstrap.remoteDomainManager.mtls.chain`                   | Certificate chain                                                                                                                                                       | `/mtls-domain-manager/tls.crt` |
| `testing.bootstrap.remoteDomainManager.mtls.key`                     | Certificate private key (PKCS-8)                                                                                                                                        | `/mtls-domain-manager/tls.key` |

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
