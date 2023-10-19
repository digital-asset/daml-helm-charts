{{/* vim: set filetype=mustache: */}}
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
Participant Kubernetes service full DNS name.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "participant.serviceDNS" -}}
{{ template "common.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Generate participant public API TLS certificate DNS names.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "participant.tls.public.certManagerDnsNames" -}}
{{- $local := dict "first" true -}}
{{- range $dns := list (include "participant.serviceDNS" .) .Values.ingress.host .Values.ingressRouteTCP.hostSNI -}}
{{- if $dns -}}
{{- if not $local.first -}}
,
{{- end -}}
{{- $dns -}}
{{- $_ := set $local "first" false -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate remote sequencer connection URL.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "sequencer.url" -}}
{{- if .Values.bootstrapHook.remoteSequencer.tls.enabled -}}
https
{{- else -}}
http
{{- end -}}
://{{ .Values.bootstrapHook.remoteSequencer.host }}
{{- with .Values.bootstrapHook.remoteSequencer.port -}}
:{{ . }}
{{- end -}}
{{- end -}}
