{{/* vim: set filetype=mustache: */}}
{{/*
Generic TLS block.

Params:
  - Admin API TLS configuration - String - Required. Common sub key "common.tls.admin".
  - Admin API mTLS configuration - String - Required. Common sub key "common.mtls.admin".
*/}}
{{- define "canton.tls.admin" -}}
{{- $tls  := index . 0 -}}
{{- $mtls  := index . 1 -}}
{{- if $tls.enabled }}
tls {
  cert-chain-file = {{ $tls.chain | quote }}
  private-key-file = {{ $tls.key | quote }}
  {{- if $mtls.enabled }}
  {{- if ne $mtls.ca "" }}
  trust-collection-file = {{ $mtls.ca | quote }}
  {{- end }}
  client-auth = {
    type = "require"
    admin-client {
      cert-chain-file = ""
      private-key-file = ""
    }
  }
  {{- end }}
  minimum-server-protocol-version = {{ include "canton.tls.minimumServerProtocolVersion" $tls.minimumServerProtocolVersion }}
  ciphers = {{ include "canton.tls.ciphers" $tls.ciphers }}
}
{{- end }}
{{- end -}}

{{/*
Generic remote TLS block.

Params:
  - Remote admin or public API TLS configuration - String - Required. Canton node sub key "tls.admin" or "tls.public".
  - Remote admin or public API mTLS configuration - String - Required. Canton node sub key "mtls.admin" or "mtls.public".
*/}}
{{- define "canton.tls.remote" -}}
{{- $tls  := index . 0 -}}
{{- $mtls  := index . 1 -}}
{{- if $tls.enabled }}
tls {
  trust-collection-file = {{ $tls.ca | default "" | quote }}
  {{- if $mtls.enabled }}
  client-cert = {
    cert-chain-file = {{ $mtls.chain | default "" | quote }}
    private-key-file = {{ $mtls.key | default "" | quote }}
  }
  {{- end }}
}
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
Domain Topology Manager Kubernetes service full DNS name.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "manager.serviceDNS" -}}
{{ template "common.fullname" . }}-manager.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Mediator Kubernetes service full DNS name.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "mediator.serviceDNS" -}}
{{ template "common.fullname" . }}-mediator.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Sequencer Kubernetes service full DNS name.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "sequencer.serviceDNS" -}}
{{ template "common.fullname" . }}-sequencer.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Generate sequencer public TLS certificate DNS names.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "sequencer.tls.public.certManagerDnsNames" -}}
{{- $local := dict "first" true -}}
{{- range $dns := list (include "sequencer.serviceDNS" .) .Values.sequencer.ingress.host .Values.sequencer.ingressRouteTCP.hostSNI -}}
{{- if $dns -}}
{{- if not $local.first -}}
,
{{- end -}}
{{- $dns -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}
{{- end -}}
