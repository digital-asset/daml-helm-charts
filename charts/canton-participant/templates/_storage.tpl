{{/* vim: set filetype=mustache: */}}
{{/*
Generate storage configuration block.
*/}}
{{ define "canton-node.storage" }}
storage {
  type = postgres
  config {
    dataSourceClass = "org.postgresql.ds.PGSimpleDataSource"
    properties = {
      serverName = {{ .Values.storage.host | quote }}
      portNumber = {{ .Values.storage.port }}
      user = {{ .Values.storage.user | quote }}
      password = ${?CANTON_DB_PASSWORD}
      databaseName = {{ .Values.storage.database | quote }}
      ssl = {{ .Values.storage.ssl }}
      {{- if .Values.storage.ssl }}
      sslmode = {{ .Values.storage.sslMode | quote }}
      {{- if .Values.storage.certCAFilename }}
      sslrootcert = {{- include "postgresql.certPath" (list . "certCAFilename") | quote -}}
      {{- end }}
      {{- if .Values.storage.certFilename }}
      sslcert = {{- include "postgresql.certPath" (list . "certFilename") | quote -}}
      {{- end }}
      {{- if .Values.storage.certKeyFilename }}
      sslkey = {{- include "postgresql.certPath" (list . "certKeyFilename") | quote -}}
      {{- end }}
      {{- end }}
    }
  }
  max-connections = {{ .Values.storage.maxConnections }}
}
{{- end -}}

{{/*
Return the path to the provided PostgreSQL certificate.

Usage:
{{ include "postgresql.certPath" (list . "key") }}

Params (List):
  - Context - Dict - Required. The context for the template evaluation.
  - Filename - String - Required. Cert file sub key of "storage" in values: "certCAFilename", "certFilename" or "certKeyFilename".
    If an existing secret is used, everything is mounted into /pgtls,
    provide a secret key name like "tls.cert". Otherwise provide the full path like "/path/to/file".
*/}}
{{- define "postgresql.certPath" -}}
{{- $top  := index . 0 -}}
{{- $file := index $top.Values.storage (index . 1) -}}
{{- if $top.Values.storage.certificatesSecret -}}
{{- printf "/pgtls/%s" $file -}}
{{- else -}}
{{- $file -}}
{{- end -}}
{{- end -}}
