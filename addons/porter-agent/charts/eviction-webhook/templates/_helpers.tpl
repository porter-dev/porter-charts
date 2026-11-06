{{- define "eviction-webhook.fullname" -}}
{{ .Release.Name }}-eviction-webhook
{{- end }}

{{- define "eviction-webhook.selectorLabels" -}}
app.kubernetes.io/name: eviction-webhook
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "eviction-webhook.labels" -}}
{{ include "eviction-webhook.selectorLabels" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* mode fails the render on anything but audit or enforce. */}}
{{- define "eviction-webhook.mode" -}}
{{- if not (has .Values.mode (list "audit" "enforce")) -}}
{{- fail (printf "evictionWebhook.mode must be audit or enforce, got %q" .Values.mode) -}}
{{- end -}}
{{- .Values.mode | quote -}}
{{- end }}
