{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
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
Kubernetes and Helm standard labels.
*/}}
{{- define "common.labels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/part-of: canton
app.kubernetes.io/version: {{ .Chart.AppVersion }}
canton.io/participant: {{ .Values.participantName }}
helm.sh/chart: {{ include "common.chart" . }}
{{- end -}}

{{/*
Labels to use in matchLabels and selector.
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "common.name" . }}
{{- end -}}

{{/*
Return image for containers.
*/}}
{{- define "common.image" -}}
{{- $separator := ":" -}}
{{- $termination := .Values.image.tag | default .Chart.AppVersion -}}
{{- if .Values.image.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .Values.image.digest -}}
{{- end -}}
{{- if .Values.image.registry }}
    {{- printf "%s/%s%s%s" .Values.image.registry .Values.image.repository $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s" .Values.image.repository $separator $termination -}}
{{- end -}}
{{- end -}}

{{/*
Return image for console containers.
*/}}
{{- define "console.image" -}}
{{- $separator := ":" -}}
{{- $termination := .Values.console.image.tag | default (print .Chart.AppVersion "-debug") -}}
{{- if .Values.console.image.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .Values.console.image.digest -}}
{{- end -}}
{{- if .Values.image.registry }}
    {{- printf "%s/%s%s%s" .Values.image.registry .Values.console.image.repository $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s" .Values.console.image.repository $separator $termination -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use

Params (List):
  - Context - Dict - Required. Current context for the template evaluation.
  - Component name - String - Required. Components with a sub key "serviceAccount" in values: "bootstrap", "console", ""
*/}}
{{- define "common.serviceAccountName" -}}
{{- $top           := index . 0 -}}
{{- $componentName := index . 1 -}}
{{- $component     := index $top.Values $componentName -}}
{{- if $top.Values.serviceAccount.create -}}
    {{- if $componentName -}}
        {{ default (printf "%s-%s" (include "common.fullname" $top) $componentName) $component.serviceAccount.name }}
    {{- else -}}
        {{ default (include "common.fullname" $top) $top.Values.serviceAccount.name }}
    {{- end -}}
{{- else -}}
    {{ default "default" $component.serviceAccount.name }}
{{- end -}}
{{- end -}}
