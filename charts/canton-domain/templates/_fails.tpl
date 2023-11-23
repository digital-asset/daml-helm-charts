{{/*
Enable KMS configuration for either AWS or GCP
*/}}
{{ define "canton.kms" }}
{{- $top       := index . 0 }}
{{- $componentName := index . 1 }}
{{- $component := index $top.Values $componentName }}
crypto {
  private-key-store.encryption {
    type = kms
    wrapper-key-id = { str = {{ required "KMS is enabled you must provide a wrapper key" $component.kms.key }} }
  }
  {{- if $top.Values.common.kms.aws.region }}
  kms {
    type = aws
    region = {{ $top.Values.common.kms.aws.region | quote }}
    multi-region-key = {{ $top.Values.common.kms.aws.multiRegion }}
    audit-logging = {{ $top.Values.common.kms.auditLogging }}
  }
  {{- else if or $top.Values.common.kms.gcp.locationId $top.Values.common.kms.gcp.projectId $top.Values.common.kms.gcp.keyRingId }}
  kms {
    type = gcp
    location-id = {{ $top.Values.common.kms.gcp.locationId | quote }}
    project-id = {{ $top.Values.common.kms.gcp.projectId | quote }}
    key-ring-id = {{ $top.Values.common.kms.gcp.keyRingId | quote }}
    audit-logging = {{ $top.Values.common.kms.auditLogging }}
  }
  {{- else }}
  {{- fail "KMS is enabled you must configure either AWS or GCP" }}
  {{- end }}
}
{{- end -}}
