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
*/}}
{{- define "canton-node.labels" -}}
app.kubernetes.io/component: participant
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ include "canton-node.name" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
helm.sh/release-namespace: {{ .Release.Namespace }}
canton.io/participant: {{ .Values.participantName }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "canton-node.selectorLabels" -}}
app.kubernetes.io/name: {{ include "canton-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

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
