{{/* vim: set filetype=mustache: */}}
{{/*
Generate PostgreSQL JDBC driver connection URL.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "storage.url" -}}
jdbc:postgresql://{{ .Values.storage.host }}:{{ .Values.storage.port }}/{{ .Values.storage.database }}?ssl={{ .Values.storage.ssl }}
{{- if .Values.storage.ssl -}}
{{- with .Values.storage.sslMode -}}&sslmode={{ . }}{{- end -}}
{{- with .Values.storage.sslRootCert -}}&sslrootcert={{ . }}{{- end -}}
{{- with .Values.storage.sslCert -}}&sslcert={{ . }}{{- end -}}
{{- with .Values.storage.sslKey -}}&sslkey={{ . }}{{- end -}}
{{- with .Values.storage.extraConnectionProperties -}}{{ . }}{{- end -}}
{{- end -}}
{{- end -}}
