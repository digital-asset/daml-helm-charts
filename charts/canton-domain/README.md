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
* Bootstrap Hook
* Console
* Domain Topology Manager (active/passive)
* Mediator (active/passive)
* Sequencer (active/active)

⚠️ Only PostgreSQL 🐘 is supported as storage backend, check our
[guidelines](https://github.com/digital-asset/daml-helm-charts/blob/main/POSTGRES.md).

---
## 🚦 Prerequisites 🚦

- **Canton Enterprise image** copied to your own private container image registry
- Kubernetes `1.24+`
- Helm `3.9+`
- Preconfigured PostgreSQL resources for each component (3): Domain Topology Manager, Mediator and Sequencer
  - 3 users/passwords
  - 3 databases
- [Cert-manager](https://cert-manager.io/docs/) + CSI driver (only if TLS is enabled, optional but strongly recommended)

---
## TL;DR

```console
helm repo add digital-asset https://digital-asset.github.io/daml-helm-charts/
helm install mydomain digital-asset/canton-domain
```

### Minimum viable configuration

Example domain `mydomain` configuration.

⚠️ _TLS is disabled_

```yaml
common:
  domainName: "mydomain"
  mediatorName: "mymediator"
  sequencerName: "mysequencer"

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

### Bootstrap Hook

A Helm hook is used to initialize your domain just after all the other resources from the Helm chart
have been successfully installed. This **idempotent** Canton bootstrap script will run as a Kubernetes job,
it will be retried multiple times on errors before the overall Helm chart installation/upgrade is
considered failed.

#### Development environments

* You can allow and connect multiple remote participants listed in `testing.bootstrapHook.remoteParticipants`.
Example development configuration bootstrapping a domain `mydomain` and a remote participant `participant1`
in namespace `canton` within the same Kubernetes cluster:

⚠️ _Requires that the participants are already running and that the bootstrap hook is allowed to call
their admin API enpoint_

```yaml
testing:
  bootstrapHook:
    remoteParticipants:
      - name: "participant1"
        host: "participant1-canton-participant.canton.svc.cluster.local"
```

* You can configure the domain with an open topology, so that any participant can connect
(see [Daml Documentation](https://docs.daml.com/canton/usermanual/manage_domains.html#permissioned-domainsusing)):

⚠️ _Any participant that can reach the sequencer public API will be able to connect to the domain,
without any verification made_

```yaml
manager:
  topology:
    open: true
```

### Console

You can deploy a canton console pod:

```yaml
console:
  enabled: true
```

Use the Kubernetes CLI to execute a command in the container:

```console
kubectl -n <k8s_namespace> exec -it <k8s_pod_name> -- java -jar /<filename>.jar -c /canton/remote.conf --no-tty
```

### TLS

For each endpoint, there are two ways to provide certificates when TLS/mTLS is enabled.

⚠️ **Certificate rotation requires a restart of all components** ⚠️

#### Cert-manager (recommended)

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

Example with secret `mydomain-tls-public` for the public endpoint used in sequencer deployment volume mount `tls-public`:

```yaml
common:
  tls:
    public:
      enabled: true
      ca: "/tls-public/ca.crt"
      chain: "/tls-public/chain.crt"
      key: "/tls-public/tls.key"

sequencer:
  extraVolumes:
    - name: tls-public
      secret:
        secretName: mydomain-tls-public
```

This secret must contain data with the right key names `ca.crt`, `chain.crt` and `tls.key`,
it will be mounted as files into folder `/tls-public`.

⚠️ _If you enable the bootstrap hook and/or console, do not forget to also provide them a certificate._

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

### Limitations

⚠️ **Upgrading to a different release is not supported for now** ⚠️

---
## Parameters

### Global parameters

| Name                         | Description                                                                                                        | Value                          |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------ |
| `nameOverride`               | String to partially override `common.name` template (will maintain the release name)                               | `""`                           |
| `fullnameOverride`           | String to fully override `common.fullname` template                                                                | `""`                           |
| `image.registry`             | Canton container image registry                                                                                    | `digitalasset-docker.jfrog.io` |
| `image.repository`           | Canton container image repository                                                                                  | `canton-enterprise`            |
| `image.tag`                  | Canton container image tag (immutable tags are recommended)                                                        | `""`                           |
| `image.digest`               | Canton container image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag`           | `""`                           |
| `image.pullPolicy`           | Canton container image pull policy. Allowed values: `Always`, `Never`, `IfNotPresent`                              | `IfNotPresent`                 |
| `image.pullSecrets`          | Specify container registry existing secret names as an array                                                       | `[]`                           |
| `commonLabels`               | Add labels to all the deployed resources                                                                           | `{}`                           |
| `certManager`                | Cert-manager CSI driver defaults                                                                                   |                                |
| `certManager.duration`       | Requested certificates validity period. If empty `""` defaults to `720h`                                           | `87660h`                       |
| `certManager.renewBefore`    | Time to renew the certificate before expiry. If empty `""` defaults to a third of `duration`                       | `1h`                           |
| `certManager.issuerGroup`    | Issuer group. Allowed values: `cert-manager.io`, `cas-issuer.jetstack.io`, `cert-manager.k8s.cloudflare.com`, etc. | `cert-manager.io`              |
| `certManager.issuerKind`     | Issuer kind. Allowed values: `Issuer`, `ClusterIssuer`, `GoogleCASIssuer`, `OriginIssuer`, etc.                    | `Issuer`                       |
| `certManager.fsGroup`        | FS Group of mounted files, should be paired with and match container `runAsGroup`                                  | `65532`                        |
| `serviceAccount.create`      | Enable creation of service accounts for pod(s)                                                                     | `true`                         |
| `rbac.create`                | Enable creation of RBAC resources attached to the service accounts                                                 | `true`                         |
| `metrics.enabled`            | Enable Prometheus metrics endpoint                                                                                 | `false`                        |
| `metrics.podMonitor.enabled` | Creates a Prometheus Operator PodMonitor for all components (also requires `metrics.enabled` to be `true`)         | `false`                        |

### Global PostgreSQL configuration

| Name                          | Description                                                                                                                                 | Value          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
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

### Bootstrap Hook configuration (not merged with `common` parameters)

| Name                                                        | Description                                                                                                                                          | Value                                                 |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `bootstrapHook`                                             | Initialize your domain and remote participant(s) listed in `testing.bootstrapHook.remoteParticipants`                                                |                                                       |
| `bootstrapHook.enabled`                                     | Enable Job (Helm chart hook), will create one or more ephemeral Pods                                                                                 | `true`                                                |
| `bootstrapHook.backoffLimit`                                | Specifies the number of retries before marking this job failed                                                                                       | `2`                                                   |
| `bootstrapHook.activeDeadlineSeconds`                       | Specifies the duration in seconds relative to the startTime that the job may be continuously active before the system tries to terminate it          | `600`                                                 |
| `bootstrapHook.commandsTimeout`                             | Script commands timeout. Example values: `10s`, `10m' or `10h`                                                                                       | `1m`                                                  |
| `bootstrapHook.logLevel`                                    | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`                                                                    |                                                       |
| `bootstrapHook.logLevel.root`                               | Canton and external libraries, but not `stdout`                                                                                                      | `INFO`                                                |
| `bootstrapHook.logLevel.canton`                             | Only the Canton logger                                                                                                                               | `INFO`                                                |
| `bootstrapHook.logLevel.stdout`                             | Usually the text displayed in the Canton console                                                                                                     | `INFO`                                                |
| `bootstrapHook.environment`                                 | Environment variables (not merged with `common.environment`)                                                                                         |                                                       |
| `bootstrapHook.environmentSecrets`                          | Secret environment variables (not merged with `common.environmentSecrets`)                                                                           | `{}`                                                  |
| `bootstrapHook.environment.JDK_JAVA_OPTIONS`                | Java launcher environment variable                                                                                                                   | `-XX:InitialRAMPercentage=70 -XX:MaxRAMPercentage=70` |
| `bootstrapHook.job`                                         | Job and Helm hook configuration                                                                                                                      |                                                       |
| `bootstrapHook.job.annotations`                             | Job extra annotations                                                                                                                                | `{}`                                                  |
| `bootstrapHook.job.labels`                                  | Job extra labels                                                                                                                                     | `{}`                                                  |
| `bootstrapHook.job.helmHook`                                | Annotation `helm.sh/hook` value                                                                                                                      | `post-install,post-upgrade`                           |
| `bootstrapHook.job.helmHookWeight`                          | Annotation `helm.sh/hook-weight` value                                                                                                               | `5`                                                   |
| `bootstrapHook.job.helmHookDeletePolicy`                    | Annotation `helm.sh/hook-delete-policy` value                                                                                                        | `before-hook-creation`                                |
| `bootstrapHook.pod.annotations`                             | Extra annotations for bootstrap Job pods                                                                                                             | `{}`                                                  |
| `bootstrapHook.pod.labels`                                  | Extra labels for bootstrap Job pods                                                                                                                  | `{}`                                                  |
| `bootstrapHook.pod.securityContext.enabled`                 | Enable bootstrap Job pods Security Context                                                                                                           | `true`                                                |
| `bootstrapHook.pod.securityContext.fsGroup`                 | Special supplemental GID that applies to all containers in a pod                                                                                     | `65532`                                               |
| `bootstrapHook.pod.securityContext.fsGroupChangePolicy`     | Defines behavior of changing ownership and permission of the volume before being exposed inside pods. Valid values are `OnRootMismatch` and `Always` | `Always`                                              |
| `bootstrapHook.pod.securityContext.sysctls`                 | List of namespaced sysctls used for the pod                                                                                                          | `[]`                                                  |
| `bootstrapHook.securityContext.enabled`                     | Enable bootstrap container Security Context                                                                                                          | `true`                                                |
| `bootstrapHook.securityContext.readOnlyRootFilesystem`      | Whether this container has a read-only root filesystem                                                                                               | `false`                                               |
| `bootstrapHook.securityContext.runAsGroup`                  | The GID to run the entrypoint of the container process                                                                                               | `65532`                                               |
| `bootstrapHook.securityContext.runAsNonRoot`                | Indicates that the container must run as a non-root user                                                                                             | `true`                                                |
| `bootstrapHook.securityContext.runAsUser`                   | The UID to run the entrypoint of the container process                                                                                               | `65532`                                               |
| `bootstrapHook.affinity`                                    | Affinity for pods assignment                                                                                                                         | `{}`                                                  |
| `bootstrapHook.nodeSelector`                                | Node labels for pods assignment                                                                                                                      | `{}`                                                  |
| `bootstrapHook.resources`                                   | Resources requests/limits for bootstrap container                                                                                                    |                                                       |
| `bootstrapHook.tolerations`                                 | Tolerations for pods assignment                                                                                                                      | `[]`                                                  |
| `bootstrapHook.extraVolumeMounts`                           | Specify extra list of additional volumeMounts for bootstrap container                                                                                | `[]`                                                  |
| `bootstrapHook.extraVolumes`                                | Specify extra list of additional volumes for bootstrap pod                                                                                           | `[]`                                                  |
| `bootstrapHook.serviceAccount.annotations`                  | Service Account extra annotations                                                                                                                    | `{}`                                                  |
| `bootstrapHook.serviceAccount.labels`                       | Service Account extra labels                                                                                                                         | `{}`                                                  |
| `bootstrapHook.serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                   | `false`                                               |
| `bootstrapHook.serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                                                   | `[]`                                                  |
| `bootstrapHook.rbac.rules`                                  | Custom RBAC rules to set                                                                                                                             | `[]`                                                  |

### Console configuration (not merged with `common` parameters)

| Name                                                  | Description                                                                                                                                          | Value                                                 |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `console`                                             | Single console pod for administration/debug of all the other components                                                                              |                                                       |
| `console.enabled`                                     | Enable Deployment                                                                                                                                    | `false`                                               |
| `console.terminationGracePeriodSeconds`               | Stop the pod immediately by default, tailing `/dev/null` to stay up                                                                                  | `0`                                                   |
| `console.image`                                       | Specific container image to be able to start a Canton console. Reusing `image.registry`, `image.pullPolicy` and `image.pullSecrets`                  |                                                       |
| `console.image.repository`                            | Canton console container image repository                                                                                                            | `canton-enterprise`                                   |
| `console.image.tag`                                   | Canton console container image tag (immutable tags are recommended)                                                                                  | `""`                                                  |
| `console.image.digest`                                | Canton console container image digest in the way `sha256:aa...`. If this parameter is set, overrides `image.tag`                                     | `""`                                                  |
| `console.environment`                                 | Environment variables (not merged with `common.environment`)                                                                                         |                                                       |
| `console.environmentSecrets`                          | Secret environment variables (not merged with `common.environmentSecrets`)                                                                           | `{}`                                                  |
| `console.environment.JDK_JAVA_OPTIONS`                | Java launcher environment variable                                                                                                                   | `-XX:InitialRAMPercentage=70 -XX:MaxRAMPercentage=70` |
| `console.deployment.annotations`                      | Deployment extra annotations                                                                                                                         | `{}`                                                  |
| `console.deployment.labels`                           | Deployment extra labels                                                                                                                              | `{}`                                                  |
| `console.deployment.strategy`                         | Deployment strategy                                                                                                                                  | `{}`                                                  |
| `console.pod.annotations`                             | Extra annotations for console Deployment pods                                                                                                        | `{}`                                                  |
| `console.pod.labels`                                  | Extra labels for console Deployment pods                                                                                                             | `{}`                                                  |
| `console.pod.securityContext.enabled`                 | Enable console Deployment pods Security Context                                                                                                      | `true`                                                |
| `console.pod.securityContext.fsGroup`                 | Special supplemental GID that applies to all containers in a pod                                                                                     | `65532`                                               |
| `console.pod.securityContext.fsGroupChangePolicy`     | Defines behavior of changing ownership and permission of the volume before being exposed inside pods. Valid values are `OnRootMismatch` and `Always` | `Always`                                              |
| `console.pod.securityContext.sysctls`                 | List of namespaced sysctls used for the pod                                                                                                          | `[]`                                                  |
| `console.securityContext.enabled`                     | Enable console container Security Context                                                                                                            | `true`                                                |
| `console.securityContext.readOnlyRootFilesystem`      | Whether this container has a read-only root filesystem                                                                                               | `false`                                               |
| `console.securityContext.runAsGroup`                  | The GID to run the entrypoint of the container process                                                                                               | `65532`                                               |
| `console.securityContext.runAsNonRoot`                | Indicates that the container must run as a non-root user                                                                                             | `true`                                                |
| `console.securityContext.runAsUser`                   | The UID to run the entrypoint of the container process                                                                                               | `65532`                                               |
| `console.affinity`                                    | Affinity for pods assignment                                                                                                                         | `{}`                                                  |
| `console.nodeSelector`                                | Node labels for pods assignment                                                                                                                      | `{}`                                                  |
| `console.resources`                                   | Resources requests/limits for console container                                                                                                      |                                                       |
| `console.tolerations`                                 | Tolerations for pods assignment                                                                                                                      | `[]`                                                  |
| `console.extraVolumeMounts`                           | Specify extra list of additional volumeMounts for console container                                                                                  | `[]`                                                  |
| `console.extraVolumes`                                | Specify extra list of additional volumes for console pod                                                                                             | `[]`                                                  |
| `console.serviceAccount.annotations`                  | Service Account extra annotations                                                                                                                    | `{}`                                                  |
| `console.serviceAccount.labels`                       | Service Account extra labels                                                                                                                         | `{}`                                                  |
| `console.serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                   | `false`                                               |
| `console.serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                                                   | `[]`                                                  |
| `console.rbac.rules`                                  | Custom RBAC rules to set                                                                                                                             | `[]`                                                  |

### Common parameters for all components

| Name                                             | Description                                                                                                                                                      | Value                                                                                |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `common.domainName`                              | Mandatory Canton Domain name                                                                                                                                     | `mydomain`                                                                           |
| `common.mediatorName`                            | Mandatory Canton Mediator name                                                                                                                                   | `mymediator`                                                                         |
| `common.sequencerName`                           | Mandatory Canton Sequencer name                                                                                                                                  | `mysequencer`                                                                        |
| `common.logEncoder`                              | Logging encoder. Allowed values: `plain`, `json`                                                                                                                 | `plain`                                                                              |
| `common.tls`                                     | TLS configuration                                                                                                                                                |                                                                                      |
| `common.tls.public.enabled`                      | Enable TLS on sequencer public API (gRPC)                                                                                                                        | `false`                                                                              |
| `common.tls.public.certManager`                  | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/tls-public` |                                                                                      |
| `common.tls.public.certManager.issuerGroup`      | Issuer group, defaults to `certManager.issuerGroup` if empty                                                                                                     | `""`                                                                                 |
| `common.tls.public.certManager.issuerKind`       | Issuer kind, defaults to `certManager.issuerKind` if empty                                                                                                       | `""`                                                                                 |
| `common.tls.public.certManager.issuerName`       | Issuer name                                                                                                                                                      | `""`                                                                                 |
| `common.tls.public.ca`                           | CA certificate, if empty `""` JVM default trust store is used                                                                                                    | `/tls-public/ca.crt`                                                                 |
| `common.tls.public.chain`                        | Certificate chain                                                                                                                                                | `/tls-public/tls.crt`                                                                |
| `common.tls.public.key`                          | Certificate private key (PKCS-8)                                                                                                                                 | `/tls-public/tls.key`                                                                |
| `common.tls.public.minimumServerProtocolVersion` | Minimum version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)            | `TLSv1.3`                                                                            |
| `common.tls.public.ciphers`                      | Specify ciphers allowed, if empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)                                    | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |
| `common.tls.admin.enabled`                       | Enable TLS on admin API (gRPC)                                                                                                                                   | `false`                                                                              |
| `common.tls.admin.certManager`                   | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/tls-admin`  |                                                                                      |
| `common.tls.admin.certManager.issuerGroup`       | Issuer group, defaults to `certManager.issuerGroup` if empty                                                                                                     | `""`                                                                                 |
| `common.tls.admin.certManager.issuerKind`        | Issuer kind, defaults to `certManager.issuerKind` if empty                                                                                                       | `""`                                                                                 |
| `common.tls.admin.certManager.issuerName`        | Issuer name                                                                                                                                                      | `""`                                                                                 |
| `common.tls.admin.ca`                            | CA certificate, if empty `""` JVM default trust store is used                                                                                                    | `/tls-admin/ca.crt`                                                                  |
| `common.tls.admin.chain`                         | Certificate chain                                                                                                                                                | `/tls-admin/tls.crt`                                                                 |
| `common.tls.admin.key`                           | Certificate private key (PKCS-8)                                                                                                                                 | `/tls-admin/tls.key`                                                                 |
| `common.tls.admin.minimumServerProtocolVersion`  | Minimum version allowed: `TLSv1.2` or `TLSv1.3`. If empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)            | `TLSv1.3`                                                                            |
| `common.tls.admin.ciphers`                       | Specify ciphers allowed, if empty `""` JVM defaults are used [[documentation]](https://www.java.com/en/configure_crypto.html)                                    | `["TLS_AES_128_GCM_SHA256","TLS_AES_256_GCM_SHA384","TLS_CHACHA20_POLY1305_SHA256"]` |
| `common.mtls`                                    | mTLS configuration                                                                                                                                               |                                                                                      |
| `common.mtls.admin.enabled`                      | Define whether clients need to authenticate as well using mTLS                                                                                                   | `false`                                                                              |
| `common.mtls.admin.certManager`                  | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/mtls-admin` |                                                                                      |
| `common.mtls.admin.certManager.issuerGroup`      | Issuer group, defaults to `certManager.issuerGroup` if empty                                                                                                     | `""`                                                                                 |
| `common.mtls.admin.certManager.issuerKind`       | Issuer kind, defaults to `certManager.issuerKind` if empty                                                                                                       | `""`                                                                                 |
| `common.mtls.admin.certManager.issuerName`       | Issuer name                                                                                                                                                      | `""`                                                                                 |
| `common.mtls.admin.ca`                           | CA certificate, if empty `""` JVM default trust store is used                                                                                                    | `/mtls-admin/ca.crt`                                                                 |
| `common.mtls.admin.chain`                        | Certificate chain                                                                                                                                                | `/mtls-admin/tls.crt`                                                                |
| `common.mtls.admin.key`                          | Certificate private key (PKCS-8)                                                                                                                                 | `/mtls-admin/tls.key`                                                                |

### Common parameters for the `bootstrap` and `console` only

| Name                                    | Description                              | Value   |
| --------------------------------------- | ---------------------------------------- | ------- |
| `common.features`                       | Enable additional commands               |         |
| `common.features.enablePreviewCommands` | Enable preview commands (unstable)       | `false` |
| `common.features.enableTestingCommands` | Enable testing commands (for developers) | `false` |
| `common.features.enableRepairCommands`  | Enable manual repair commands            | `false` |

### Common parameters for the `manager`, `mediator` and `sequencer` only

| Name                                             | Description                                                                                                                                          | Value                                                                             |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `common.logLevel`                                | Log4j logging levels. Allowed values: `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR`                                                                    |                                                                                   |
| `common.logLevel.root`                           | Canton and external libraries, but not `stdout`                                                                                                      | `INFO`                                                                            |
| `common.logLevel.canton`                         | Only the Canton logger                                                                                                                               | `INFO`                                                                            |
| `common.logLevel.stdout`                         | Usually the text displayed in the Canton console                                                                                                     | `INFO`                                                                            |
| `common.environment`                             | Environment variables                                                                                                                                |                                                                                   |
| `common.environmentSecrets`                      | Secret environment variables                                                                                                                         | `{}`                                                                              |
| `common.environment.JDK_JAVA_OPTIONS`            | Java launcher environment variable                                                                                                                   | `-XX:+ExitOnOutOfMemoryError -XX:InitialRAMPercentage=70 -XX:MaxRAMPercentage=70` |
| `common.pod.securityContext.enabled`             | Enable pods Security Context                                                                                                                         | `true`                                                                            |
| `common.pod.securityContext.fsGroup`             | Special supplemental GID that applies to all containers in a pod                                                                                     | `65532`                                                                           |
| `common.pod.securityContext.fsGroupChangePolicy` | Defines behavior of changing ownership and permission of the volume before being exposed inside pods. Valid values are `OnRootMismatch` and `Always` | `Always`                                                                          |
| `common.pod.securityContext.sysctls`             | List of namespaced sysctls used for the pod                                                                                                          | `[]`                                                                              |
| `common.securityContext.enabled`                 | Enable containers Security Context                                                                                                                   | `true`                                                                            |
| `common.securityContext.readOnlyRootFilesystem`  | Whether this container has a read-only root filesystem                                                                                               | `false`                                                                           |
| `common.securityContext.runAsGroup`              | The GID to run the entrypoint of the container process                                                                                               | `65532`                                                                           |
| `common.securityContext.runAsNonRoot`            | Indicates that the container must run as a non-root user                                                                                             | `true`                                                                            |
| `common.securityContext.runAsUser`               | The UID to run the entrypoint of the container process                                                                                               | `65532`                                                                           |
| `common.kms`                                     | Key Management Service (KMS) configuration                                                                                                           |                                                                                   |
| `common.kms.enabled`                             | Enable KMS to encrypt/decrypt the node private keys stored in database.<br />Configure only one provider (`aws` or `gcp`)                            | `false`                                                                           |
| `common.kms.auditLogging`                        | Enable logging of every call made to KMS                                                                                                             | `false`                                                                           |
| `common.kms.aws`                                 | AWS KMS specific options                                                                                                                             |                                                                                   |
| `common.kms.aws.region`                          | AWS region                                                                                                                                           | `""`                                                                              |
| `common.kms.aws.multiRegion`                     | Allow this key to be replicated into other AWS regions                                                                                               | `false`                                                                           |
| `common.kms.gcp`                                 | GCP KMS specific options                                                                                                                             |                                                                                   |
| `common.kms.gcp.locationId`                      | GCP location ID                                                                                                                                      | `""`                                                                              |
| `common.kms.gcp.projectId`                       | GCP project ID                                                                                                                                       | `""`                                                                              |
| `common.kms.gcp.keyRingId`                       | GCP key ring ID                                                                                                                                      | `""`                                                                              |

### Network Policy

| Name                           | Description                       | Value  |
| ------------------------------ | --------------------------------- | ------ |
| `common.networkpolicy.enabled` | Enable Network Policy definitions | `true` |
| `common.networkpolicy.labels`  | Network Policy extra labels       | `{}`   |

### Domain Topology Manager configuration

| Name                                                  | Description                                                                                                                                                                       | Value       |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `manager.storage.database`                            | Manager database name                                                                                                                                                             | `mydomain`  |
| `manager.storage.user`                                | Manager user name                                                                                                                                                                 | `canton`    |
| `manager.storage.existingSecret.name`                 | Name of existing secret with user credentials                                                                                                                                     | `""`        |
| `manager.storage.existingSecret.key`                  | Name of key in existing secret with user password                                                                                                                                 | `""`        |
| `manager.storage.maxConnections`                      | Database connection pool maximum connections                                                                                                                                      | `10`        |
| `manager.configOverride`                              | Raw Canton configuration file `canton { ... }`                                                                                                                                    | `""`        |
| `manager.bootstrapScript`                             | Raw Canton bootstrap script, automatically ran after node has started                                                                                                             | `""`        |
| `manager.kms.key`                                     | Wrapper key<br />AWS KMS: key ARN, key alias or key ID<br />AWS GCP: full name like `projects/<project_name>/locations/<location>/keyRings/<key_ring_name>/cryptoKeys/<key_name>` | `""`        |
| `manager.ports.admin`                                 | Admin API container port (gRPC)                                                                                                                                                   | `4801`      |
| `manager.ports.health`                                | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled)                                                                                       | `4803`      |
| `manager.ports.metrics`                               | Promotheus exporter container port (HTTP)                                                                                                                                         | `8081`      |
| `manager.replicaCount`                                | Number of Domain Topology Manager pods to deploy. Allowed values: `1` (active/passive HA, scaling up does not work)                                                               | `1`         |
| `manager.environment`                                 | Environment variables,merged with `common.environment`                                                                                                                            | `{}`        |
| `manager.environmentSecrets`                          | Secret environment variables,merged with `common.environmentSecrets`                                                                                                              | `{}`        |
| `manager.deployment.annotations`                      | Deployment extra annotations                                                                                                                                                      | `{}`        |
| `manager.deployment.labels`                           | Deployment extra labels                                                                                                                                                           | `{}`        |
| `manager.pod.annotations`                             | Extra annotations for Deployment pods                                                                                                                                             | `{}`        |
| `manager.pod.labels`                                  | Extra labels for Deployment pods                                                                                                                                                  | `{}`        |
| `manager.affinity`                                    | Affinity for pods assignment                                                                                                                                                      | `{}`        |
| `manager.nodeSelector`                                | Node labels for pods assignment                                                                                                                                                   | `{}`        |
| `manager.resources`                                   | Resources requests/limits for manager container                                                                                                                                   |             |
| `manager.tolerations`                                 | Tolerations for pods assignment                                                                                                                                                   | `[]`        |
| `manager.livenessProbe`                               | Override `livenessProbe` default configuration                                                                                                                                    | `{}`        |
| `manager.readinessProbe`                              | Override `readinessProbe` default configuration                                                                                                                                   | `{}`        |
| `manager.service.type`                                | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance`                                                                                              | `ClusterIP` |
| `manager.service.annotations`                         | Service extra annotations                                                                                                                                                         | `{}`        |
| `manager.service.labels`                              | Service extra labels                                                                                                                                                              | `{}`        |
| `manager.service.ports.admin`                         | Admin API service port (gRPC)                                                                                                                                                     | `4801`      |
| `manager.service.ports.metrics`                       | Promotheus exporter service port (HTTP)                                                                                                                                           | `8081`      |
| `manager.extraVolumeMounts`                           | Specify extra list of additional volumeMounts for manager container                                                                                                               | `[]`        |
| `manager.extraVolumes`                                | Specify extra list of additional volumes for manager pod                                                                                                                          | `[]`        |
| `manager.topology.open`                               | `true`: domain is open, anyone who can connect to the sequencer can join<br />`false`: new participants are only accepted if their `ParticipantState` has already been registered | `false`     |
| `manager.uniqueContractKeys`                          | Enable Unique Contract Keys (UCK) mode in your domain.<br />⚠️ This mode cannot be disabled once it has been enabled                                                              | `false`     |
| `manager.serviceAccount.annotations`                  | Service Account extra annotations                                                                                                                                                 | `{}`        |
| `manager.serviceAccount.labels`                       | Service Account extra labels                                                                                                                                                      | `{}`        |
| `manager.serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                                                | `false`     |
| `manager.serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                                                                                | `[]`        |
| `manager.rbac.rules`                                  | Custom RBAC rules to set                                                                                                                                                          | `[]`        |
| `manager.podMonitor.labels`                           | Pod Monitor extra labels                                                                                                                                                          | `{}`        |
| `manager.podMonitor.jobLabel`                         | The label to use to retrieve the job name from                                                                                                                                    | `""`        |
| `manager.podMonitor.podTargetLabels`                  | PodTargetLabels transfers labels on the Kubernetes Pod onto the target                                                                                                            | `[]`        |
| `manager.podMonitor.extraPodMetricsEndpoints`         | Extra scrapeable endpoint configuration                                                                                                                                           | `[]`        |
| `manager.podMonitor.sampleLimit`                      | Per-scrape limit on number of scraped samples that will be accepted                                                                                                               | `0`         |
| `manager.podMonitor.targetLimit`                      | Limit on the number of scraped targets that will be accepted                                                                                                                      | `0`         |
| `manager.podMonitor.labelLimit`                       | Per-scrape limit on number of labels that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                      | `0`         |
| `manager.podMonitor.labelNameLengthLimit`             | Per-scrape limit on length of labels name that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                 | `0`         |
| `manager.podMonitor.labelValueLengthLimit`            | Per-scrape limit on length of labels value that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                | `0`         |

### Mediator configuration

| Name                                                   | Description                                                                                                                                                                       | Value        |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| `mediator.storage.database`                            | Mediator database name                                                                                                                                                            | `mymediator` |
| `mediator.storage.user`                                | Mediator user name                                                                                                                                                                | `canton`     |
| `mediator.storage.existingSecret.name`                 | Name of existing secret with user credentials                                                                                                                                     | `""`         |
| `mediator.storage.existingSecret.key`                  | Name of key in existing secret with user password                                                                                                                                 | `""`         |
| `mediator.storage.maxConnections`                      | Database connection pool maximum connections                                                                                                                                      | `10`         |
| `mediator.configOverride`                              | Raw Canton configuration file `canton { ... }`                                                                                                                                    | `""`         |
| `mediator.bootstrapScript`                             | Raw Canton bootstrap script, automatically ran after node has started                                                                                                             | `""`         |
| `mediator.kms.key`                                     | Wrapper key<br />AWS KMS: key ARN, key alias or key ID<br />AWS GCP: full name like `projects/<project_name>/locations/<location>/keyRings/<key_ring_name>/cryptoKeys/<key_name>` | `""`         |
| `mediator.ports.admin`                                 | Admin API container port (gRPC)                                                                                                                                                   | `4602`       |
| `mediator.ports.health`                                | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled)                                                                                       | `4603`       |
| `mediator.ports.metrics`                               | Promotheus exporter container port (HTTP)                                                                                                                                         | `8081`       |
| `mediator.replicaCount`                                | Number of Mediator pods to deploy. Allowed values: `1` (active/passive HA, scaling up does not work)                                                                              | `1`          |
| `mediator.environment`                                 | Environment variables,merged with `common.environment`                                                                                                                            | `{}`         |
| `mediator.environmentSecrets`                          | Secret environment variables,merged with `common.environmentSecrets`                                                                                                              | `{}`         |
| `mediator.deployment.annotations`                      | Deployment extra annotations                                                                                                                                                      | `{}`         |
| `mediator.deployment.labels`                           | Deployment extra labels                                                                                                                                                           | `{}`         |
| `mediator.pod.annotations`                             | Extra annotations for Deployment pods                                                                                                                                             | `{}`         |
| `mediator.pod.labels`                                  | Extra labels for Deployment pods                                                                                                                                                  | `{}`         |
| `mediator.affinity`                                    | Affinity for pods assignment                                                                                                                                                      | `{}`         |
| `mediator.nodeSelector`                                | Node labels for pods assignment                                                                                                                                                   | `{}`         |
| `mediator.resources`                                   | Resources requests/limits for manager container                                                                                                                                   |              |
| `mediator.tolerations`                                 | Tolerations for pods assignment                                                                                                                                                   | `[]`         |
| `mediator.livenessProbe`                               | Override `livenessProbe` default configuration                                                                                                                                    | `{}`         |
| `mediator.readinessProbe`                              | Override `readinessProbe` default configuration                                                                                                                                   | `{}`         |
| `mediator.service.type`                                | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance`                                                                                              | `ClusterIP`  |
| `mediator.service.annotations`                         | Service extra annotations                                                                                                                                                         | `{}`         |
| `mediator.service.labels`                              | Service extra labels                                                                                                                                                              | `{}`         |
| `mediator.service.ports.admin`                         | Admin API service port (gRPC)                                                                                                                                                     | `4602`       |
| `mediator.service.ports.metrics`                       | Promotheus exporter service port (HTTP)                                                                                                                                           | `8081`       |
| `mediator.extraVolumeMounts`                           | Specify extra list of additional volumeMounts for mediator container                                                                                                              | `[]`         |
| `mediator.extraVolumes`                                | Specify extra list of additional volumes for mediator pod                                                                                                                         | `[]`         |
| `mediator.serviceAccount.annotations`                  | Service Account extra annotations                                                                                                                                                 | `{}`         |
| `mediator.serviceAccount.labels`                       | Service Account extra labels                                                                                                                                                      | `{}`         |
| `mediator.serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                                                | `false`      |
| `mediator.serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                                                                                | `[]`         |
| `mediator.rbac.rules`                                  | Custom RBAC rules to set                                                                                                                                                          | `[]`         |
| `mediator.podMonitor.labels`                           | Pod Monitor extra labels                                                                                                                                                          | `{}`         |
| `mediator.podMonitor.jobLabel`                         | The label to use to retrieve the job name from                                                                                                                                    | `""`         |
| `mediator.podMonitor.podTargetLabels`                  | PodTargetLabels transfers labels on the Kubernetes Pod onto the target                                                                                                            | `[]`         |
| `mediator.podMonitor.extraPodMetricsEndpoints`         | Extra scrapeable endpoint configuration                                                                                                                                           | `[]`         |
| `mediator.podMonitor.sampleLimit`                      | Per-scrape limit on number of scraped samples that will be accepted                                                                                                               | `0`          |
| `mediator.podMonitor.targetLimit`                      | Limit on the number of scraped targets that will be accepted                                                                                                                      | `0`          |
| `mediator.podMonitor.labelLimit`                       | Per-scrape limit on number of labels that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                      | `0`          |
| `mediator.podMonitor.labelNameLengthLimit`             | Per-scrape limit on length of labels name that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                 | `0`          |
| `mediator.podMonitor.labelValueLengthLimit`            | Per-scrape limit on length of labels value that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                | `0`          |

### Sequencer configuration

| Name                                                    | Description                                                                                                                                                                       | Value           |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `sequencer.type`                                        | Sequencer type                                                                                                                                                                    | `database`      |
| `sequencer.storage.database`                            | Sequencer database name                                                                                                                                                           | `mysequencer`   |
| `sequencer.storage.user`                                | Sequencer user name                                                                                                                                                               | `canton`        |
| `sequencer.storage.existingSecret.name`                 | Name of existing secret with user credentials                                                                                                                                     | `""`            |
| `sequencer.storage.existingSecret.key`                  | Name of key in existing secret with user password                                                                                                                                 | `""`            |
| `sequencer.storage.maxConnections`                      | Database connection pool maximum connections                                                                                                                                      | `10`            |
| `sequencer.config`                                      | Sequencer extra configuration, to use along a custom `sequencer.type`                                                                                                             | `""`            |
| `sequencer.configOverride`                              | Raw Canton configuration file `canton { ... }`                                                                                                                                    | `""`            |
| `sequencer.bootstrapScript`                             | Raw Canton bootstrap script, automatically ran after node has started                                                                                                             | `""`            |
| `sequencer.kms.key`                                     | Wrapper key<br />AWS KMS: key ARN, key alias or key ID<br />AWS GCP: full name like `projects/<project_name>/locations/<location>/keyRings/<key_ring_name>/cryptoKeys/<key_name>` | `""`            |
| `sequencer.ports.public`                                | Ledger API container port (gRPC)                                                                                                                                                  | `4401`          |
| `sequencer.ports.admin`                                 | Admin API container port (gRPC)                                                                                                                                                   | `4402`          |
| `sequencer.ports.health`                                | Health check port for gRPC liveness and readiness probes, not exposed (TLS always disabled)                                                                                       | `4403`          |
| `sequencer.ports.metrics`                               | Promotheus exporter container port (HTTP)                                                                                                                                         | `8081`          |
| `sequencer.replicaCount`                                | Number of Sequencer pods to deploy                                                                                                                                                | `1`             |
| `sequencer.environment`                                 | Environment variables,merged with `common.environment`                                                                                                                            | `{}`            |
| `sequencer.environmentSecrets`                          | Secret environment variables,merged with `common.environmentSecrets`                                                                                                              | `{}`            |
| `sequencer.deployment.annotations`                      | Deployment extra annotations                                                                                                                                                      | `{}`            |
| `sequencer.deployment.labels`                           | Deployment extra labels                                                                                                                                                           | `{}`            |
| `sequencer.deployment.strategy`                         | Deployment strategy                                                                                                                                                               | `{}`            |
| `sequencer.pod.annotations`                             | Extra annotations for Deployment pods                                                                                                                                             | `{}`            |
| `sequencer.pod.labels`                                  | Extra labels for Deployment pods                                                                                                                                                  | `{}`            |
| `sequencer.affinity`                                    | Affinity for pods assignment                                                                                                                                                      | `{}`            |
| `sequencer.nodeSelector`                                | Node labels for pods assignment                                                                                                                                                   | `{}`            |
| `sequencer.resources`                                   | Resources requests/limits for manager container                                                                                                                                   |                 |
| `sequencer.tolerations`                                 | Tolerations for pods assignment                                                                                                                                                   | `[]`            |
| `sequencer.livenessProbe`                               | Override `livenessProbe` default configuration                                                                                                                                    | `{}`            |
| `sequencer.readinessProbe`                              | Override `readinessProbe` default configuration                                                                                                                                   | `{}`            |
| `sequencer.service.type`                                | Service type. Allowed values: `ExternalName`, `ClusterIP`, `NodePort`, `LoadBalance`                                                                                              | `ClusterIP`     |
| `sequencer.service.annotations`                         | Service extra annotations                                                                                                                                                         | `{}`            |
| `sequencer.service.labels`                              | Service extra labels                                                                                                                                                              | `{}`            |
| `sequencer.service.ports.public`                        | Ledger API service port (gRPC)                                                                                                                                                    | `4401`          |
| `sequencer.service.ports.admin`                         | Admin API service port (gRPC)                                                                                                                                                     | `4402`          |
| `sequencer.service.ports.metrics`                       | Promotheus exporter service port (HTTP)                                                                                                                                           | `8081`          |
| `sequencer.service.sessionAffinity.enabled`             | Enable `ClientIP` based session affinity                                                                                                                                          | `true`          |
| `sequencer.service.sessionAffinity.timeout`             | Session timeout in seconds. Between `1` and `86400`                                                                                                                               | `3600`          |
| `sequencer.extraVolumeMounts`                           | Specify extra list of additional volumeMounts for sequencer container                                                                                                             | `[]`            |
| `sequencer.extraVolumes`                                | Specify extra list of additional volumes for sequencer pod                                                                                                                        | `[]`            |
| `sequencer.ingress.enabled`                             | Enable ingress to sequencer service port `public` (gRPC)                                                                                                                          | `false`         |
| `sequencer.ingress.annotations`                         | Ingress extra annotations                                                                                                                                                         | `{}`            |
| `sequencer.ingress.labels`                              | Ingress extra labels                                                                                                                                                              | `{}`            |
| `sequencer.ingress.className`                           | Set `ingressClassName` on the ingress record                                                                                                                                      | `""`            |
| `sequencer.ingress.host`                                | Fully qualified domain name of a network host                                                                                                                                     | `""`            |
| `sequencer.ingress.path`                                | Path to sequencer **public API**                                                                                                                                                  | `/`             |
| `sequencer.ingress.pathType`                            | Determines the interpretation of the `Path` matching.  Allowed values: `Exact`, `Prefix`, `ImplementationSpecific`                                                                | `Prefix`        |
| `sequencer.ingress.tls`                                 | Enable TLS configuration for `hostname`                                                                                                                                           | `[]`            |
| `sequencer.ingressRouteTCP.enabled`                     | Enable Traefik `IngressRouteTCP` (CRD) to sequencer service port `public` (gRPC)                                                                                                  | `false`         |
| `sequencer.ingressRouteTCP.annotations`                 | IngressRouteTCP extra annotations                                                                                                                                                 | `{}`            |
| `sequencer.ingressRouteTCP.labels`                      | IngressRouteTCP extra labels                                                                                                                                                      | `{}`            |
| `sequencer.ingressRouteTCP.entryPoints`                 | Traefik entrypoints for this IngressRouteTCP. Available by default: `web` (port 80), `websecure` (port 443)                                                                       | `["websecure"]` |
| `sequencer.ingressRouteTCP.hostSNI`                     | DNS record to cluster load balancer                                                                                                                                               | `""`            |
| `sequencer.ingressRouteTCP.tls`                         | Define TLS certificate configuration                                                                                                                                              | `{}`            |
| `sequencer.serviceAccount.annotations`                  | Service Account extra annotations                                                                                                                                                 | `{}`            |
| `sequencer.serviceAccount.labels`                       | Service Account extra labels                                                                                                                                                      | `{}`            |
| `sequencer.serviceAccount.automountServiceAccountToken` | API token automatically mounted into pods using this ServiceAccount. Set to `false` if pods do not use the K8s API                                                                | `false`         |
| `sequencer.serviceAccount.extraSecrets`                 | List of extra secrets allowed to be used by pods running using this ServiceAccount                                                                                                | `[]`            |
| `sequencer.rbac.rules`                                  | Custom RBAC rules to set                                                                                                                                                          | `[]`            |
| `sequencer.podMonitor.labels`                           | Pod Monitor extra labels                                                                                                                                                          | `{}`            |
| `sequencer.podMonitor.jobLabel`                         | The label to use to retrieve the job name from                                                                                                                                    | `""`            |
| `sequencer.podMonitor.podTargetLabels`                  | PodTargetLabels transfers labels on the Kubernetes Pod onto the target                                                                                                            | `[]`            |
| `sequencer.podMonitor.extraPodMetricsEndpoints`         | Extra scrapeable endpoint configuration                                                                                                                                           | `[]`            |
| `sequencer.podMonitor.sampleLimit`                      | Per-scrape limit on number of scraped samples that will be accepted                                                                                                               | `0`             |
| `sequencer.podMonitor.targetLimit`                      | Limit on the number of scraped targets that will be accepted                                                                                                                      | `0`             |
| `sequencer.podMonitor.labelLimit`                       | Per-scrape limit on number of labels that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                      | `0`             |
| `sequencer.podMonitor.labelNameLengthLimit`             | Per-scrape limit on length of labels name that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                 | `0`             |
| `sequencer.podMonitor.labelValueLengthLimit`            | Per-scrape limit on length of labels value that will be accepted for a sample (Prometheus versions 2.27 and newer)                                                                | `0`             |

### Automated testing configuration (do not use in production)

| Name                                                                             | Description                                                                                                                                                                        | Value |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `testing.bootstrapHook.remoteParticipants`                                       | List of remote Canton participants, only the `bootstrap` and `console`  will connect to them.<br />`name` and `host` are mandatory for each of them, otherwise the default is used | `[]`  |
| `testing.bootstrapHook.remoteParticipants[*].name`                               | Participant name                                                                                                                                                                   |       |
| `testing.bootstrapHook.remoteParticipants[*].host`                               | Participant hostname                                                                                                                                                               |       |
| `testing.bootstrapHook.remoteParticipants[*].ports.admin`                        | Participant admin port (gRPC)                                                                                                                                                      |       |
| `testing.bootstrapHook.remoteParticipants[*].tls.admin.enabled`                  | Enable TLS to Participant admin API                                                                                                                                                |       |
| `testing.bootstrapHook.remoteParticipants[*].tls.admin.ca`                       | Participant TLS CA certificate                                                                                                                                                     |       |
| `testing.bootstrapHook.remoteParticipants[*].tls.admin.certManager`              | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/tls-<participant_name>`       |       |
| `testing.bootstrapHook.remoteParticipants[*].tls.admin.certManager.issuerGroup`  | Issuer group, defaults to `certManager.issuerGroup` if empty                                                                                                                       |       |
| `testing.bootstrapHook.remoteParticipants[*].tls.admin.certManager.issuerKind`   | Issuer kind, defaults to `certManager.issuerKind` if empty                                                                                                                         |       |
| `testing.bootstrapHook.remoteParticipants[*].tls.admin.certManager.issuerName`   | Issuer name                                                                                                                                                                        |       |
| `testing.bootstrapHook.remoteParticipants[*].mtls.admin.enabled`                 | Enable mTLS to Participant admin API                                                                                                                                               |       |
| `testing.bootstrapHook.remoteParticipants[*].mtls.admin.chain`                   | Bootstrap hook and console mTLS certificate chain                                                                                                                                  |       |
| `testing.bootstrapHook.remoteParticipants[*].mtls.admin.key`                     | Bootstrap hook and console mTLS certificate key (PKCS-8)                                                                                                                           |       |
| `testing.bootstrapHook.remoteParticipants[*].mtls.admin.certManager`             | Cert-manager CSI driver configuration (only used when TLS is enabled and `issuerName` is defined), will automatically mount certificates in folder `/mtls-<participant_name>`      |       |
| `testing.bootstrapHook.remoteParticipants[*].mtls.admin.certManager.issuerGroup` | Issuer group, defaults to `certManager.issuerGroup` if empty                                                                                                                       |       |
| `testing.bootstrapHook.remoteParticipants[*].mtls.admin.certManager.issuerKind`  | Issuer kind, defaults to `certManager.issuerKind` if empty                                                                                                                         |       |
| `testing.bootstrapHook.remoteParticipants[*].mtls.admin.certManager.issuerName`  | Issuer name                                                                                                                                                                        |       |


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
