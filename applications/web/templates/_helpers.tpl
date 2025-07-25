{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "docker-template.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "docker-template.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "docker-template.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | trimSuffix "."}}
{{- end }}

{{/*
Generate a KEDA ScaledObject's HPA name(only meant for B/G deployments)
*/}}
{{- define "docker-template.kedaHpa" -}}
{{- printf "keda-hpa-%s-%s" .name .tag }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "docker-template.labels" -}}
helm.sh/chart: {{ include "docker-template.chart" . }}
{{ include "docker-template.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "docker-template.selectorLabels" -}}
app.kubernetes.io/name: {{ include "docker-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "docker-template.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "docker-template.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the service account json secret to use with the CloudSQL proxy
*/}}
{{- define "cloudsql.serviceAccountJSONSecret" -}}
{{- default (printf "cloudsql-secret-%s" (include "docker-template.fullname" .)) .Values.cloudsql.serviceAccountJSONSecret }}
{{- end }}


{{/* 
The connection string to be passed to the CloudSQL proxy.
For backwards compatibility, this concatenates targets from cloudsql.connectionName/dbPort, cloudsql.additionalConnection.connectionName/dbPort in addition to the cloudsql.connections list
*/}}
{{- define "cloudsql.connectionString" -}}
{{- $singleConnection := .Values.cloudsql.connectionName -}}
{{- $additionalConnection := .Values.cloudsql.additionalConnection -}}
{{- $connections := default (list) .Values.cloudsql.connections -}}
{{- $hasConnections := or $singleConnection (gt (len $connections) 0) $additionalConnection.enabled -}}
{{- if $hasConnections -}}
    
    {{- if $singleConnection -}}
        {{- $singleConnection -}}=tcp:{{.Values.cloudsql.dbPort }}
    {{- end -}}

    {{- if $additionalConnection.enabled -}}
        {{- if $singleConnection }},{{ end -}}
        {{ $additionalConnection.connectionName }}=tcp:{{ $additionalConnection.dbPort }}
    {{- end -}}

    {{- range $index, $conn := $connections -}} 
        {{- if or $index $singleConnection $additionalConnection.enabled }},{{ end -}}
        {{ $conn.name }}=tcp:{{ $conn.port }}
    {{- end -}}

{{- end }}
{{- end }}

{{/*
Get the EFS mount path for a given volume. If an override is provided, use that.
Otherwise, use the default path /data/efs/<fullname>
*/}}
{{- define "docker-template.efsMountPath" -}}
{{- if .mountPath -}}
{{- .mountPath -}}
{{- else -}}
{{- printf "/data/efs/%s" .fullname -}}
{{- end -}}
{{- end -}}

{{/*
Get the EFS resource name. If index is 0, don't append it to the name.
*/}}
{{- define "docker-template.efsName" -}}
{{- $name := printf "efs-%s" .fullname -}}
{{- if ne (.index | int) 0 -}}
{{- printf "%s-%d" $name (.index | int) -}}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/*
Renders the full block of annotations for the ingress.
This helper uses the global .Values object.
*/}}
{{- define "ingressAnnotations" -}}
{{- $ingress := .Values.ingress -}}
{{- $customPaths := $ingress.custom_paths -}}
{{- $annotations := dict
  "nginx.ingress.kubernetes.io/proxy-body-size" "50m"
  "nginx.ingress.kubernetes.io/proxy-send-timeout" "60"
  "nginx.ingress.kubernetes.io/proxy-read-timeout" "60"
  "nginx.ingress.kubernetes.io/proxy-connect-timeout" "60"
-}}
{{- if and (gt (len $customPaths) 0) $ingress.rewriteCustomPathsEnabled }}
  {{- $_ := set $annotations "nginx.ingress.kubernetes.io/rewrite-target" "/" -}}
{{- end }}
{{- if $ingress.tls -}}
  {{- if not (hasKey $ingress.annotations "cert-manager.io/cluster-issuer") -}}
    {{- if $ingress.wildcard -}}
      {{- $_ := set $annotations "cert-manager.io/cluster-issuer" "letsencrypt-prod-wildcard" -}}
    {{- else -}}
      {{- $_ := set $annotations "cert-manager.io/cluster-issuer" "letsencrypt-prod" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- $userAnnotations := $ingress.annotations -}}
{{- if hasKey $ingress.annotations "normal" -}}
  {{- $userAnnotations = $ingress.annotations.normal -}}
{{- end -}}

{{- $cleanedUserAnnotations := dict -}}
{{- range $k, $v := $userAnnotations -}}
  {{- if and $v (not (eq $v "null")) -}}
    {{- $_ := set $cleanedUserAnnotations $k $v -}}
  {{- end -}}
{{- end -}}

{{- $_ := mergeOverwrite $annotations $cleanedUserAnnotations -}}

{{- range $k, $v := $annotations }}
{{ $k }}: {{ $v | toString | trimPrefix "\"" | trimSuffix "\"" | quote }}
{{- end }}

{{- end -}}

{{/*
Return true if volumeMounts should be rendered in the main container

*/}}
{{- define "shouldRenderVolumeMounts" -}}
{{- if or .Values.datadogSocketVolume.enabled .Values.resources.requests.nvidiaGpu .Values.awsEfsStorage .Values.pvc.enabled .Values.emptyDir.enabled (and .Values.fileSecretMounts .Values.fileSecretMounts.enabled) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}