# Changelog

| Notation | Scope
|--- |---
| [Canton] | `canton-domain` + `canton-participant` Helm charts
| [Domain] | `canton-domain` Helm chart
| [Participant] | `canton-participant` Helm chart
| [Daml] | `daml-http-json` + `daml-trigger` Helm charts
| [JSON] | `daml-http-json` Helm chart
| [Trigger] | `daml-trigger` Helm chart
| [All] |All Helm charts

## `0.5.0`

* Daml Enterprise `2.7.4`
* [All] Rename PostgreSQL password environment variable to `PGPASSWORD`
* [All] Move all mounted configuration files to `/etc/<canton|http-json|trigger>`
* [Canton] Feed a raw node bootstrap script (key: `bootstrapScript`)
* [Participant] Fix `Ingress` templating error
* [Participant] Database transactions asynchronous commits enabled by default (key: `storage.asyncCommitEnabled`)
* [Participant] Add command service settings (key: `commandService`), prepended to the node bootstrap script
  ```yaml
  commandService:
    maxCommandsInFlight: 10000
    maxRate: 200
    maxDirtyRequests: 500
    maxBurstFactor: 10
  ```
* [Participant] Add caching configuration (key: `caching`)
  ```yaml
  caching:
    maxContractStateCacheSize: 1000000
    maxContractKeyStateCacheSize: 1000000
    maxTransactionsInMemoryFanOutBufferSize: 100000
    contractStore:
      maxSize: 1000000
      expireAfterAccess: "10m"
  ```

#### Breaking changes ⚠️

* [Canton] Key `bootstrap` renamed to `bootstrapHook`
* [Canton] Key `testing.bootstrap` renamed to `test.bootstrapHook`
* [Domain] Bootstrap hook is enabled by default to connect all components together (key: `bootstrapHook.enabled`)

## `0.4.0`

* Daml Enterprise `2.7.1`
* [All] Reword to "container image(s)" everywhere (remove "Docker")
* [Canton] Feed a raw node configuration file to override templates (key: `configOverride`)
* [Domain] mTLS configuration truly optional in remote participant(s) bootstrap (key: `testing.bootstrap.remoteParticipants[*].mtls`)
* [Participant] Verifying target domain ID option in bootstrap (key: `bootstrap.remoteSequencer.domain.verifyId`)

---

While it's not recommended in production, and should only be used in development environments,
you can now connect any participant to a domain, without any beforehand operation required.

##### Domain

Open topology is enabled

```yaml
bootstrap:
  enabled: true

manager:
  topology:
    open: true
```

##### Participant

Verifying remote domain ID is disabled

```yaml
bootstrap:
  enabled: true
  remoteSequencer:
    domain:
      verifyId: false
```

## `0.3.0`

* Daml Enterprise `2.7.0`
* [All] Default values:
  * `JDK_JAVA_OPTIONS` environment variable
  * Container resources (CPU/RAM requests/limits)
* [All] Cert-manager CSI driver global default values: `issuerGroup`, `issuerKind`, `fsGroup`
* [Canton] Network policies (alpha)
* [Participant] Custom admin user (key `authServices.additionalAdminUserId`)

## `0.2.0`

* Daml Enterprise `2.6.5`
* [All] Define security context for pods/containers
* [Canton] New [distroless](https://github.com/GoogleContainerTools/distroless)
based Canton container image with user `nonroot` (UID=GID=`65532`)
* [Participant] JWT authentication custom audience (key `authServices.targetAudience`)
* [Participant] Automated domain registration (development only)

  ```yaml
  testing:
    bootstrap:
      automaticDomainRegistration: true
      remoteDomainManager:
  ...
  ```

#### Breaking changes ⚠️

Canton Domain values

---
```yaml
bootstrap:
  remoteParticipants: []
```

Moving to

```yaml
testing:
  bootstrap:
    remoteParticipants: []
```
---

## `0.1.0`

Initial public release (beta)

* Daml Enterprise `2.6.4`

## `0.0.x`

Initial work (alpha)
