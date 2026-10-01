{{/*
The Certificate and Secret name for one host of the service.
A hash of the host keeps the name unique, because different hosts can map to the same readable part.
*/}}
{{- define "hosted-web.tlsSecretName" -}}
{{- $fullName := index . 0 -}}
{{- $host := index . 1 -}}
{{- $readable := printf "%s-%s" $fullName ($host | replace "." "-") | trunc 244 | trimSuffix "-" -}}
{{- printf "%s-%s" $readable (sha256sum $host | trunc 8) -}}
{{- end -}}
