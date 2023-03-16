{{/* vim: set filetype=mustache: */}}
{{/*
Generic TLS block.
*/}}
{{- define "canton-node.adminTLS" -}}
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
  minimum-server-protocol-version = {{ include "canton-node.tlsMinimumServerProtocolVersion" $top.minimumServerProtocolVersion }}
  ciphers = {{ include "canton-node.tlsCiphers" $top.ciphers }}
}
{{- end }}
{{- end -}}

{{/*
Generic remote TLS block.
*/}}
{{- define "canton-node.remoteTLS" -}}
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
*/}}
{{- define "canton-node.sequencerPublicTLS" -}}
{{- $top  := index . 0 -}}
{{- if $top.enabled }}
tls {
  cert-chain-file = {{ $top.certChainFile | quote }}
  private-key-file = {{ $top.privateKeyFile | quote }}
  minimum-server-protocol-version = {{ include "canton-node.tlsMinimumServerProtocolVersion" $top.minimumServerProtocolVersion }}
  ciphers = {{ include "canton-node.tlsCiphers" $top.ciphers }}
}
{{- end }}
{{- end -}}

{{/*
Remote sequencer public API TLS block (does not support mTLS).
*/}}
{{- define "canton-node.remoteSequencerPublicTLS" -}}
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

Usage:
{{ include "canton-node.tlsMinimumServerProtocolVersion" .path.to.minimumServerProtocolVersion }}

Params:
  - Ciphers - Dict - Optional. TLS version string, if omitted or empty set value to null (use JVM defaults)
*/}}
{{- define "canton-node.tlsMinimumServerProtocolVersion" -}}
{{- $local := dict "first" true -}}
{{- if . -}}
{{ . | quote }}
{{- else -}}
null
{{- end -}}
{{- end -}}

{{/*
Generate ciphers value for configuration.

Usage:
{{ include "canton-node.tlsCiphers" .path.to.ciphers }}

Params:
  - Ciphers - Dict - Optional. Ciphers list, if omitted or empty set value to null (JVM defaults)
*/}}
{{- define "canton-node.tlsCiphers" -}}
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
Sequencer Kuberneres service full DNS name
*/}}
{{- define "sequencer.serviceDNS" -}}
{{ template "canton-node.fullname" . }}-sequencer.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Generate sequencer TLS certificate DNS names
*/}}
{{- define "sequencer.tlsCertManagerDnsNames" -}}
{{- $local := dict "first" true -}}
{{- range $dns := list "localhost" (include "sequencer.serviceDNS" .) .Values.sequencer.ingress.host .Values.sequencer.ingressRouteTCP.hostSNI -}}
{{- if $dns -}}
{{- if not $local.first -}}
,
{{- end -}}
{{- $dns -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}
{{- end -}}
