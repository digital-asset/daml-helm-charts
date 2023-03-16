{{/* vim: set filetype=mustache: */}}
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
Participant Kuberneres service full DNS name
*/}}
{{- define "participant.serviceDNS" -}}
{{ template "canton-node.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Generate participant TLS certificate DNS names
*/}}
{{- define "participant.tlsCertManagerDnsNames" -}}
{{- $local := dict "first" true -}}
{{- range $dns := list "localhost" (include "participant.serviceDNS" .) .Values.ingress.host .Values.ingressRouteTCP.hostSNI -}}
{{- if $dns -}}
{{- if not $local.first -}}
,
{{- end -}}
{{- $dns -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}
{{- end -}}
