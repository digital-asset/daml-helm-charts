{{/* vim: set filetype=mustache: */}}
{{/*
Generate storage configuration block.

Usage:
{{ include "canton-node.storage" (list . "manager") }}

Params (List):
  - Context - Dict - Required. The context for the template evaluation.
  - Component name - String - Required. Components with a sub key "storage" in values: "manager", "mediator" or "sequencer".
*/}}
{{ define "canton-node.storage" }}
{{- $top       := index . 0 -}}
{{- $component := index $top.Values (index . 1) }}
storage {
  type = postgres
  config {
    dataSourceClass = "org.postgresql.ds.PGSimpleDataSource"
    properties = {
      serverName = {{ $top.Values.storage.host | quote }}
      portNumber = {{ $top.Values.storage.port }}
      user = {{ $component.storage.user | quote }}
      password = ${?CANTON_DB_PASSWORD}
      databaseName = {{ $component.storage.database | quote }}
      ssl = {{ $top.Values.storage.ssl }}
      {{- if $top.Values.storage.ssl }}
      sslmode = {{ $top.Values.storage.sslMode | quote }}
      {{- if $top.Values.storage.certCAFilename }}
      sslrootcert = {{- include "postgresql.certPath" (list $top "certCAFilename") | quote -}}
      {{- end }}
      {{- if $top.Values.storage.certFilename }}
      sslcert = {{- include "postgresql.certPath" (list $top "certFilename") | quote -}}
      {{- end }}
      {{- if $top.Values.storage.certKeyFilename }}
      sslkey = {{- include "postgresql.certPath" (list $top "certKeyFilename") | quote -}}
      {{- end }}
      {{- end }}
    }
  }
  max-connections = {{ $component.storage.maxConnections }}
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
