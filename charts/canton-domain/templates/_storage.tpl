{{/* vim: set filetype=mustache: */}}
{{/*
Generate storage configuration block.

Usage:
{{ include "canton.storage" (list . "manager") }}

Params (List):
  - Context - Dict - Required. Current context for the template evaluation.
  - Component name - String - Required. Components with a sub key "storage" in values: "manager", "mediator" or "sequencer".
*/}}
{{ define "canton.storage" }}
{{- $top       := index . 0 }}
{{- $componentName := index . 1 }}
{{- $component := index $top.Values $componentName }}
storage {
  type = postgres
  config {
    dataSourceClass = "org.postgresql.ds.PGSimpleDataSource"
    properties = {
      serverName = {{ $top.Values.storage.host | quote }}
      portNumber = {{ $top.Values.storage.port }}
      user = {{ $component.storage.user | quote }}
      password = ${?PGPASSWORD}
      databaseName = {{ $component.storage.database | quote }}
      ssl = {{ $top.Values.storage.ssl }}
      {{- if $top.Values.storage.ssl }}
      sslmode = {{ $top.Values.storage.sslMode | quote }}
      {{- if $top.Values.storage.sslRootCert }}
      sslrootcert = {{ $top.Values.storage.sslRootCert | quote }}
      {{- end }}
      {{- if $top.Values.storage.sslCert }}
      sslcert = {{ $top.Values.storage.sslCert | quote }}
      {{- end }}
      {{- if $top.Values.storage.sslKey }}
      sslkey = {{ $top.Values.storage.sslKey | quote }}
      {{- end }}
      {{- end }}

    }
  }
  max-connections = {{ int $component.storage.maxConnections }}
}
{{- end -}}
