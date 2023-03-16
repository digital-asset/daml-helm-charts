{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "canton-node.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "canton-node.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels (required in Helm 3.2+)

Usage:
{{ include "canton-node.labels" (list . "mycomponent") }}

Params (List):
  - Context - Dict - Required. The context for the template evaluation.
  - Component name - String - Required.
*/}}
{{- define "canton-node.labels" -}}
{{- $top       := index . 0 -}}
{{- $component := index . 1 -}}
app.kubernetes.io/component: {{ $component }}
app.kubernetes.io/instance: {{ $top.Release.Name }}
app.kubernetes.io/managed-by: {{ $top.Release.Service }}
app.kubernetes.io/name: {{ include "canton-node.name" $top }}-{{ $component }}
app.kubernetes.io/version: {{ $top.Chart.AppVersion }}
helm.sh/chart: {{ $top.Chart.Name }}-{{ $top.Chart.Version | replace "+" "_" }}
helm.sh/release-namespace: {{ $top.Release.Namespace }}
canton.io/domain: {{ $top.Values.common.domainName }}
{{- end -}}

{{/*
Selector labels

Usage:
{{ include "canton-node.selectorLabels" (list . "mycomponent") }}

Params (List):
  - Context - Dict - Required. The context for the template evaluation.
  - Component name - String - Required.
*/}}
{{- define "canton-node.selectorLabels" -}}
{{- $top       := index . 0 -}}
{{- $component := index . 1 -}}
app.kubernetes.io/name: {{ include "canton-node.name" $top }}-{{ $component }}
app.kubernetes.io/instance: {{ $top.Release.Name }}
{{- end -}}

{{/*
Define imageCredentials name.
*/}}
{{- define "canton-node.imagePullSecretName" -}}
{{- if .Values.imageCredentials.create -}}
  {{ printf "%s-%s" (include "canton-node.fullname" .) "registry" | trunc 63 | trimSuffix "-" }}
{{- else -}}
  {{ .Values.imageCredentials.name }}
{{- end -}}
{{- end -}}

{{- define "canton-node.imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.imageCredentials.registry (printf "%s:%s" .Values.imageCredentials.username .Values.imageCredentials.password | b64enc) | b64enc }}
{{- end }}
