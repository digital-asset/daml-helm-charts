{{/*
Enable KMS configuration for either AWS or GCP
*/}}
{{- define "canton.kms" -}}
crypto {
  private-key-store.encryption {
    type = kms
    wrapper-key-id = { str = {{ required .Values.kms.key }} }
  }
  {{- if .Values.kms.aws.region }}
  kms {
    type = aws
    region = {{ required .Values.kms.aws.region | quote }}
    multi-region-key = {{ .Values.kms.aws.multiRegion }}
    audit-logging = {{ .Values.kms.auditLogging }}
  }
  {{- else if .Values.kms.gcp.locationId }}
  gcp {
    type = gcp
    location-id = {{ required .Values.kms.gcp.locationId | quote }}
    project-id = {{ required .Values.kms.gcp.projectId | quote }}
    keyRing-id = {{ required .Values.kms.gcp.keyRingId | quote }}
    audit-logging = {{ .Values.kms.auditLogging }}
  }
  {{- else }}
  {{- fail "KMS is enabled you must provide configure either AWS or GCP" }}
  {{- end }}
}
{{- end -}}
