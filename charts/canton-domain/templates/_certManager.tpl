{{/* vim: set filetype=mustache: */}}
{{/*
Generate Cert-manager CSI driver block.

Key encoding is enforced, only PKCS8 is supported.

Params (List):
  - Context - Dict - Required. Current context for the template evaluation.
  - Component name - String - Required. "server", "console", etc. (can be an empty string).
  - Name - String - Required. Kubernetes CSI name.
  - Volume attributes - Dict - Required. Cert-manager CSI volume attributes.
  - DNS names - String - Required. Certificate DNS names (can be an empty string).
*/}}
{{ define "certManager.csi" }}
{{- $top              := index . 0 }}
{{- $component        := index . 1 }}
{{- $name             := index . 2 }}
{{- $volumeAttributes := index . 3 }}
{{- $volumeAttributes := set $volumeAttributes "dnsNames"    (index . 4) }}
{{- $volumeAttributes := set $volumeAttributes "duration"    $top.Values.certManager.duration }}
{{- $volumeAttributes := set $volumeAttributes "renewBefore" $top.Values.certManager.renewBefore }}
{{- $volumeAttributes := set $volumeAttributes "commonName"  (join "-" (compact (list (include "common.fullname" $top) $component $name))) }}
- name: {{ $name }}
  csi:
    driver: csi.cert-manager.io
    readOnly: true
    volumeAttributes:
      csi.cert-manager.io/issuer-group: {{ $volumeAttributes.issuerGroup | default $top.Values.certManager.issuerGroup | quote }}
      csi.cert-manager.io/issuer-kind: {{ $volumeAttributes.issuerKind | default $top.Values.certManager.issuerKind | quote }}
      csi.cert-manager.io/issuer-name: {{ $volumeAttributes.issuerName | quote }}
      csi.cert-manager.io/key-encoding: "PKCS8"
      csi.cert-manager.io/common-name: {{ $volumeAttributes.commonName | quote }}
      {{- with $volumeAttributes.dnsNames }}
      csi.cert-manager.io/dns-names: {{ . | quote }}
      {{- end }}
      {{- with $volumeAttributes.ipSans }}
      csi.cert-manager.io/ip-sans: {{ . | quote }}
      {{- end }}
      csi.cert-manager.io/fs-group: {{ $top.Values.certManager.fsGroup | quote }}
      {{- with $volumeAttributes.duration }}
      csi.cert-manager.io/duration: {{ $volumeAttributes.duration | quote }}
      {{- end }}
      {{- with $volumeAttributes.renewBefore }}
      csi.cert-manager.io/renew-before: {{ . | quote }}
      {{- end }}
{{- end }}
