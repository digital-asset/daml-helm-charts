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
