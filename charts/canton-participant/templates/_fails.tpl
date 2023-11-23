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
{{- if .Values.bootstrapHook.remoteSequencer.domain.id }}
val domainId = Some(DomainId.tryFromString({{ .Values.bootstrapHook.remoteSequencer.domain.id | quote }}))
{{- else }}
{{- fail "empty value for key 'bootstrapHook.remoteSequencer.domain.id' (Canton Domain ID)" }}
{{- end }}
{{- end -}}

{{/*
Enable KMS configuration for either AWS or GCP
*/}}
{{- define "canton.kms" -}}
crypto {
  private-key-store.encryption {
    type = kms
    wrapper-key-id = { str = {{ required "KMS is enabled you must provide a wrapper key" .Values.kms.key }} }
  }
  {{- if .Values.kms.aws.region }}
  kms {
    type = aws
    region = {{ .Values.kms.aws.region | quote }}
    multi-region-key = {{ .Values.kms.aws.multiRegion }}
    audit-logging = {{ .Values.kms.auditLogging }}
  }
  {{- else if or .Values.common.kms.gcp.locationId .Values.common.kms.gcp.projectId .Values.common.kms.gcp.keyRingId }}
  kms {
    type = gcp
    location-id = {{ .Values.kms.gcp.locationId | quote }}
    project-id = {{ .Values.kms.gcp.projectId | quote }}
    key-ring-id = {{ .Values.kms.gcp.keyRingId | quote }}
    audit-logging = {{ .Values.kms.auditLogging }}
  }
  {{- else }}
  {{- fail "KMS is enabled you must configure either AWS or GCP" }}
  {{- end }}
}
{{- end -}}
