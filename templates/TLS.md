
To enable TLS (and/or mTLS) everywhere, it is mandatory to have [Cert-manager](https://cert-manager.io/docs/) and its CSI driver
already deployed in a specific namespace of your Kubernetes cluster. A certificate issuer must be ready to use (you can use
external issuer types), you may customize all the Cert-manager CSI driver related values:

```yaml
certManager:
  issuerGroup: "cert-manager.io"
  issuerKind: "Issuer"
  issuerName: "my-cert-manager-issuer"
```

