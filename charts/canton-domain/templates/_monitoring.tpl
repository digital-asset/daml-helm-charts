{{/* vim: set filetype=mustache: */}}
{{/*
Generic monitoring block.

Usage:
{{ include "canton.monitoring" (list . "manager") }}

Params (List):
  - Context - Dict - Required. Current context for the template evaluation.
  - Component name - String - Required. Components with a sub key "ports.metrics" in values: "manager", "mediator" or "sequencer".
*/}}
{{- define "canton.monitoring" -}}
{{- $top       := index . 0 -}}
{{- $component := index $top.Values (index . 1) -}}
{{- if $top.Values.metrics.enabled }}
monitoring.metrics.reporters = [{
  type = prometheus
  address = "0.0.0.0"
  port = {{ $component.ports.metrics }}
}]
{{- end }}
{{- end -}}
