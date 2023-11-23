{{/* vim: set filetype=mustache: */}}
{{/*
Generate storage configuration block.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{ define "canton.storage" }}
storage {
  type = postgres
  config {
    dataSourceClass = "org.postgresql.ds.PGSimpleDataSource"
    properties = {
      serverName = {{ .Values.storage.host | quote }}
      portNumber = {{ .Values.storage.port }}
      user = {{ .Values.storage.user | quote }}
      password = ${?PGPASSWORD}
      databaseName = {{ .Values.storage.database | quote }}
      ssl = {{ .Values.storage.ssl }}
      {{- if .Values.storage.ssl }}
      sslmode = {{ .Values.storage.sslMode | quote }}
      {{- if .Values.storage.sslRootCert }}
      sslrootcert = {{ .Values.storage.sslRootCert | quote }}
      {{- end }}
      {{- if .Values.storage.sslCert }}
      sslcert = {{ .Values.storage.sslCert | quote }}
      {{- end }}
      {{- if .Values.storage.sslKey }}
      sslkey = {{ .Values.storage.sslKey | quote }}
      {{- end }}
      {{- end }}
    }
  }
  max-connections = {{ int .Values.storage.maxConnections }}
}
{{- end -}}
