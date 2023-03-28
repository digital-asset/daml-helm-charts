{{/* vim: set filetype=mustache: */}}
{{/*
Generate remote-participants configuration block.
Ports and TLS configuration might be missing.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{ define "canton.remoteParticipants" }}
{{ range $participant := .Values.common.remoteParticipants }}
remote-participants {
  {{ $participant.name }} {
    ledger-api {
      address = {{ $participant.host }}
      port = {{ ($participant.ports).public | default 4001 }}
      {{- if or (($participant.tls).public).enabled (($participant.tls).admin).enabled }}
      {{- include "canton.tls.remote" (list $participant.tls.public) | indent 6 }}
      {{- end }}
    }
    admin-api {
      address = {{ $participant.host }}
      port = {{ ($participant.ports).admin | default 4002 }}
      {{- if or (($participant.tls).public).enabled (($participant.tls).admin).enabled }}
      {{- include "canton.tls.remote" (list $participant.tls.admin) | indent 6 }}
      {{- end }}
    }
  }
}
{{ end }}
{{ end }}

{{/*
Find if any of the participant requires TLS for either the admin or public API.
TLS configuration might be missing.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{- define "canton.participant.isTLS" -}}
{{- range $participant := .Values.common.remoteParticipants -}}
{{- if or (($participant.tls).public).enabled (($participant.tls).admin).enabled -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate remote-sequencers configuration block.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{ define "canton.remoteSequencers" }}
remote-sequencers {
  {{ .Values.common.sequencerName }} {
    public-api {
      address = "{{ template "common.fullname" . }}-sequencer.{{ .Release.Namespace }}.svc.cluster.local"
      port = {{ .Values.sequencer.service.ports.public }}
      {{- include "canton.remoteSequencer.tls.public" (list .Values.common.tls.public) | indent 6 }}
    }
    admin-api {
      address = "{{ template "common.fullname" . }}-sequencer.{{ .Release.Namespace }}.svc.cluster.local"
      port = {{ .Values.sequencer.service.ports.admin }}
      {{- include "canton.tls.remote" (list .Values.common.tls.admin) | indent 6 }}
    }
  }
}
{{ end }}

{{/*
Generate remote-mediators configuration block.

Params:
  - Context - Dict - Required. Current context for the template evaluation.
*/}}
{{ define "canton.remoteMediators" }}
remote-mediators {
  {{ .Values.common.mediatorName }} {
    admin-api {
      address = "{{ template "common.fullname" . }}-mediator.{{ .Release.Namespace }}.svc.cluster.local"
      port = {{ .Values.mediator.service.ports.admin }}
      {{- include "canton.tls.remote" (list .Values.common.tls.admin) | indent 6 }}
    }
  }
}
{{ end }}
