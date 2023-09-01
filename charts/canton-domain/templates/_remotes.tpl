{{/* vim: set filetype=mustache: */}}
{{/*
Generate remote-participants configuration block.
Ports and TLS configuration might be missing.
The bootstrap and console are not using the remote participant(s) public API (aka Ledger API),
hence the empty string address and default port number.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{ define "remoteParticipants" }}
{{ range $remoteParticipant := .Values.testing.bootstrap.remoteParticipants }}
remote-participants {
  {{ $remoteParticipant.name }} {
    ledger-api {
      address = ""
      port = 4001
    }

    admin-api {
      address = {{ $remoteParticipant.host }}
      port = {{ ($remoteParticipant.ports).admin | default 4002 }}
      {{- if (($remoteParticipant.tls).admin).enabled }}
      {{- if (($remoteParticipant.mtls).admin).enabled }}
      {{- include "canton.tls.remote" (list $remoteParticipant.tls.admin $remoteParticipant.mtls.admin) | indent 6 }}
      {{- else }}
      {{- include "canton.tls.remote" (list $remoteParticipant.tls.admin nil) | indent 6 }}
      {{- end }}
      {{- end }}
    }
  }
}
{{ end }}
{{ end }}

{{/*
Generate bootstrap and console TLS and mTLS certificate volumeMounts for remote participant(s) using the Cert-manager CSI driver.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "remoteParticipants.volumeMounts" }}
{{- range $remoteParticipant := .Values.testing.bootstrap.remoteParticipants }}
{{- if (($remoteParticipant.tls).admin).enabled }}
- name: tls-{{ $remoteParticipant.name }}
  mountPath: "/tls-{{ $remoteParticipant.name }}"
  readOnly: true
{{- if (($remoteParticipant.mtls).admin).enabled }}
- name: mtls-{{ $remoteParticipant.name }}
  mountPath: "/mtls-{{ $remoteParticipant.name }}"
  readOnly: true
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate remote participant TLS name.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "remoteParticipant.tls.name" -}}
{{- print "tls-" . -}}
{{- end -}}

{{/*
Generate remote participant mTLS name.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "remoteParticipant.mtls.name" -}}
{{- print "mtls-" . -}}
{{- end -}}

{{/*
Generate bootstrap and console TLS and mTLS certificate volumes for remote participant(s) using the Cert-manager CSI driver.

Optional sub keys:
- "remoteParticipant.tls.admin.certManager.issuerGroup"
- "remoteParticipant.tls.admin.certManager.issuerKind"
- "remoteParticipant.tls.admin.certManager.fsGroup"
- "remoteParticipant.mtls.admin.certManager.issuerGroup"
- "remoteParticipant.mtls.admin.certManager.issuerKind"
- "remoteParticipant.mtls.admin.certManager.fsGroup"

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "remoteParticipants.volumes" }}
{{- $top              := index . 0 }}
{{- $component        := index . 1 }}
{{- range $remoteParticipant := $top.Values.testing.bootstrap.remoteParticipants }}
{{- if and (($remoteParticipant.tls).admin).enabled ((($remoteParticipant.tls).admin).certManager).issuerName }}
# Dummy certificate only used to mount the root CA certificate
{{- include "certManager.csi" (list $top $component (include "remoteParticipant.tls.name" $remoteParticipant.name) $remoteParticipant.tls.admin.certManager "") }}
{{- if and (($remoteParticipant.mtls).admin).enabled ((($remoteParticipant.mtls).admin).certManager).issuerName }}
{{- include "certManager.csi" (list $top $component (include "remoteParticipant.mtls.name" $remoteParticipant.name) $remoteParticipant.mtls.admin.certManager "") }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
