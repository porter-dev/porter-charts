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
{{- define "docker-template.instance" -}}
{{- default .Release.Name .Values.instanceOverride -}}
{{- end -}}

{{- define "docker-template.selectorLabels" -}}
app.kubernetes.io/name: {{ include "docker-template.name" . }}
app.kubernetes.io/instance: {{ include "docker-template.instance" . }}
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
Return true if volumeMounts should be rendered in the main container
*/}}
{{- define "worker.shouldRenderVolumeMounts" -}}
{{- if or .Values.datadogSocketVolume.enabled .Values.pvc.enabled .Values.multiplePvc.enabled .Values.emptyDir.enabled (and .Values.fileSecretMounts .Values.fileSecretMounts.enabled) .Values.hostVolumeMounts .Values.additionalVolumes -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}