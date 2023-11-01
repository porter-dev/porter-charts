{{- define "generate_static_password" -}}
{{- /* Create "tmp_vars" dict inside ".Release" to store various stuff. */ -}}
{{- if not (index .Release "tmp_vars") -}}
{{-   $_ := set .Release "tmp_vars" dict -}}
{{- end -}}
{{- /* Some random ID of this password, in case there will be other random values alongside this instance. */ -}}
{{- $key := printf "%s_%s" .Release.Name "DB_PASS" -}}
{{- /* If a password isn't set and the $key does not yet exist in .Release.tmp_vars, then... */ -}}
{{- if .Values.config.masterUserPassword -}}
{{- /* ... set the specified password as $key */ -}}
{{-   $_ := set .Release.tmp_vars $key (.Values.config.masterUserPassword) -}}
{{- else -}}
{{- if not (index .Release.tmp_vars $key) -}}
{{- /* ... store random password under the $key */ -}}
{{-   $_ := set .Release.tmp_vars $key (randAlphaNum 20) -}}
{{- end -}}
{{- end -}}
{{- /* Retrieve previously generated value. */ -}}
{{- index .Release.tmp_vars $key -}}
{{- end -}}

{{- define "random_pw_reusable" -}}
  {{- if .Release.IsUpgrade -}}
    {{- $data := default dict (lookup "v1" "Secret" "porter-env-group" (printf "%s.1" .Values.config.name)).data -}}
    {{- if $data -}}
      {{- index $data "DB_PASS" | b64dec -}}
    {{- end -}}
  {{- else -}}
    {{- (include "generate_static_password" .) -}}
  {{- end -}}
{{- end -}}

{{- define "database_name" -}}
{{- if .Values.config.databaseName -}}
{{ .Values.config.databaseName }}
{{- else -}}
{{ .Values.config.name | snakecase | nospace }}
{{- end -}}
{{- end -}}
