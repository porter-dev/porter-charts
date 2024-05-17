{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .secret (printf "%s:%s" .username .secret | b64enc) | b64enc }}
{{- end }}
{{- end }}