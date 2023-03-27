{{/* vim: set filetype=mustache: */}}
{{/*
Generic TLS block.

Params:
  - Admin API TLS configuration - String - Required. Common sub key "common.tls.admin".
*/}}
{{- define "canton.tls.admin" -}}
{{- $top  := index . 0 -}}
{{- if $top.enabled }}
tls {
  {{- with $top.trustCollectionFile }}
  trust-collection-file = {{ . | quote }}
  {{- end }}
  cert-chain-file = {{ $top.certChainFile | quote }}
  private-key-file = {{ $top.privateKeyFile | quote }}
  client-auth = {
    type = {{ $top.clientAuth.type }}
    admin-client {
      cert-chain-file = {{ $top.clientAuth.certChainFile | quote }}
      private-key-file = {{ $top.clientAuth.privateKeyFile | quote }}
    }
  }
  minimum-server-protocol-version = {{ include "canton.tls.minimumServerProtocolVersion" $top.minimumServerProtocolVersion }}
  ciphers = {{ include "canton.tls.ciphers" $top.ciphers }}
}
{{- end }}
{{- end -}}

{{/*
Generic remote TLS block.

Params:
  - Remote admin or public API TLS configuration - String - Required. Canton node sub key "tls.admin" or "tls.public".
*/}}
{{- define "canton.tls.remote" -}}
{{- $top  := index . 0 -}}
{{- if $top.enabled }}
tls {
  trust-collection-file = {{ $top.trustCollectionFile | default "/mtls/ca.crt" | quote }}
  client-cert = {
    cert-chain-file = {{ $top.certChainFile | default "/mtls/tls.crt" | quote }}
    private-key-file = {{ $top.privateKeyFile | default "/mtls/tls.key" | quote }}
  }
}
{{- end }}
{{- end -}}

{{/*
Sequencer public API TLS block (does not support mTLS).

Params:
  - Public API TLS configuration - String - Required. Common sub key "common.tls.public".
*/}}
{{- define "canton.sequencer.tls.public" -}}
{{- $top  := index . 0 -}}
{{- if $top.enabled }}
tls {
  cert-chain-file = {{ $top.certChainFile | quote }}
  private-key-file = {{ $top.privateKeyFile | quote }}
  minimum-server-protocol-version = {{ include "canton.tls.minimumServerProtocolVersion" $top.minimumServerProtocolVersion }}
  ciphers = {{ include "canton.tls.ciphers" $top.ciphers }}
}
{{- end }}
{{- end -}}

{{/*
Remote sequencer public API TLS block (does not support mTLS).

Params:
  - Remote public API TLS configuration - String - Required. Common sub key "common.tls.public".
*/}}
{{- define "canton.remoteSequencer.tls.public" -}}
{{- $top  := index . 0 -}}
{{- if $top.enabled }}
transport-security = true
{{- with $top.trustCollectionFile }}
custom-trust-certificates = {
  pem-file = {{ . | quote }}
}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Generate minimum TLS protocol version value for configuration.

Params:
  - Ciphers - Dict - Optional. TLS version string, if omitted or empty set value to null (use JVM defaults).
*/}}
{{- define "canton.tls.minimumServerProtocolVersion" -}}
{{- $local := dict "first" true -}}
{{- if . -}}
{{ . | quote }}
{{- else -}}
null
{{- end -}}
{{- end -}}

{{/*
Generate ciphers value for configuration.

Format: ["cipher1","cipher2"]

Params:
  - Ciphers - Dict - Optional. Ciphers list, if omitted or empty set value to null (use JVM defaults).
*/}}
{{- define "canton.tls.ciphers" -}}
{{- $local := dict "first" true -}}
{{- if . -}}
[
{{- range $cipher := . -}}
{{- if not $local.first -}}
,
{{- end -}}
{{- $cipher | quote -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
]
{{- else -}}
null
{{- end -}}
{{- end -}}


{{/*
Sequencer Kubernetes service full DNS name.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "canton.sequencer.serviceDNS" -}}
{{ template "common.fullname" . }}-sequencer.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Generate sequencer TLS certificate DNS names.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "canton.sequencer.tlsCertManagerDnsNames" -}}
{{- $local := dict "first" true -}}
{{- range $dns := list "localhost" (include "canton.sequencer.serviceDNS" .) .Values.sequencer.ingress.host .Values.sequencer.ingressRouteTCP.hostSNI -}}
{{- if $dns -}}
{{- if not $local.first -}}
,
{{- end -}}
{{- $dns -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}
{{- end -}}
