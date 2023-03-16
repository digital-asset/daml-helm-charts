{{/* vim: set filetype=mustache: */}}
{{/*
Generate remote-participants configuration block.
Ports and TLS configuration might be missing.
*/}}
{{ define "canton-node.remote-participants" }}
{{ range $participant := .Values.common.remoteParticipants }}
remote-participants {
  {{ $participant.name }} {
    ledger-api {
      address = {{ $participant.host }}
      port = {{ ($participant.ports).public | default 4001 }}
      {{- if or (($participant.tls).public).enabled (($participant.tls).admin).enabled }}
      {{- include "canton-node.remoteTLS" (list $participant.tls.public) | indent 6 }}
      {{- end }}
    }
    admin-api {
      address = {{ $participant.host }}
      port = {{ ($participant.ports).admin | default 4002 }}
      {{- if or (($participant.tls).public).enabled (($participant.tls).admin).enabled }}
      {{- include "canton-node.remoteTLS" (list $participant.tls.admin) | indent 6 }}
      {{- end }}
    }
  }
}
{{ end }}
{{ end }}

{{/*
Find if any of the participant requires TLS for either the admin or public API.
TLS configuration might be missing.
*/}}
{{- define "isParticipantTLS" -}}
{{- range $participant := .Values.common.remoteParticipants -}}
{{- if or (($participant.tls).public).enabled (($participant.tls).admin).enabled -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate remote-sequencers configuration block.
*/}}
{{ define "canton-node.remote-sequencers" }}
remote-sequencers {
  {{ .Values.common.sequencerName }} {
    public-api {
      address = "{{ template "canton-node.fullname" . }}-sequencer.{{ .Release.Namespace }}.svc.cluster.local"
      port = {{ .Values.sequencer.service.ports.public }}
      {{- include "canton-node.remoteSequencerPublicTLS" (list .Values.common.tls.public) | indent 6 }}
    }
    admin-api {
      address = "{{ template "canton-node.fullname" . }}-sequencer.{{ .Release.Namespace }}.svc.cluster.local"
      port = {{ .Values.sequencer.service.ports.admin }}
      {{- include "canton-node.remoteTLS" (list .Values.common.tls.admin) | indent 6 }}
    }
  }
}
{{ end }}

{{/*
Generate remote-mediators configuration block.
*/}}
{{ define "canton-node.remote-mediators" }}
remote-mediators {
  {{ .Values.common.mediatorName }} {
    admin-api {
      address = "{{ template "canton-node.fullname" . }}-mediator.{{ .Release.Namespace }}.svc.cluster.local"
      port = {{ .Values.mediator.service.ports.admin }}
      {{- include "canton-node.remoteTLS" (list .Values.common.tls.admin) | indent 6 }}
    }
  }
}
{{ end }}
