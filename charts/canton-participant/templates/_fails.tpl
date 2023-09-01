{{/* vim: set filetype=mustache: */}}
{{/* Safeguards to avoid contradicting configuration values */}}

{{/*
Ensure type is correct if want to enable JWT authentication
*/}}
{{- define "participant.authServicesType" -}}
type = {{ .Values.authServices.type | quote }}
{{- if eq .Values.authServices.type "jwt-rs-256-jwks" }}
url = {{ .Values.authServices.url | quote }}
{{- else if has .Values.authServices.type (list "jwt-rs-256-crt" "jwt-es-256-crt" "jwt-es-512-crt") }}
certificate = {{ .Values.authServices.certificate | quote }}
{{- else }}
{{- fail (printf "invalid value '%s' for key 'authServices.type' (JWT authentication authorization type)" .Values.authServices.type) }}
{{- end }}
{{- end -}}

{{/*
Ensure domain ID is defined if want to use it in the bootstrap
*/}}
{{- define "participant.bootstrapDomainId" -}}
{{- if .Values.bootstrap.remoteSequencer.domain.id }}
val domainId = Some(DomainId.tryFromString({{ .Values.bootstrap.remoteSequencer.domain.id | quote }}))
{{- else }}
{{- fail "empty value for key 'bootstrap.remoteSequencer.domain.id' (Canton Domain ID)" }}
{{- end }}
{{- end -}}
