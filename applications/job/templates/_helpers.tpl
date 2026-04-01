{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "docker-template.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "hook.name" -}}
{{- printf "%s-%s-hook" (.Release.Name | trunc 47) (randAlphaNum 10 | lower) }}
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
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
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
Name of the service account json secret to use with the CloudSQL proxy.
When using the new instances format, the secret is pre-created by Porter's backend.
*/}}
{{- define "cloudsql.serviceAccountJSONSecret" -}}
{{- $instances := default (list) .Values.cloudsql.instances -}}
{{- if and (gt (len $instances) 0) (index $instances 0).serviceAccountJSONSecret -}}
{{- (index $instances 0).serviceAccountJSONSecret -}}
{{- else -}}
{{- default (printf "cloudsql-secret-%s" (include "docker-template.fullname" .)) .Values.cloudsql.serviceAccountJSONSecret -}}
{{- end -}}
{{- end }}

{{/*
The connection string to be passed to the CloudSQL proxy.
For backwards compatibility, this concatenates targets from cloudsql.connectionName/dbPort, cloudsql.additionalConnection.connectionName/dbPort and cloudsql.connections.
Also supports the new cloudsql.instances format populated from the service connections field.
*/}}
{{- define "cloudsql.connectionString" -}}
{{- $singleConnection := .Values.cloudsql.connectionName -}}
{{- $additionalConnection := .Values.cloudsql.additionalConnection -}}
{{- $connections := default (list) .Values.cloudsql.connections -}}
{{- $instances := default (list) .Values.cloudsql.instances -}}
{{- $hasConnections := or $singleConnection (gt (len $connections) 0) $additionalConnection.enabled (gt (len $instances) 0) -}}
{{- $v1 := eq .Values.cloudsql.proxyVersion "v1" -}}
{{- if $hasConnections -}}

    {{- if not (gt (len $instances) 0) -}}
    {{- if $singleConnection -}}
        {{- $singleConnection -}}{{- if $v1 -}}=tcp:{{- .Values.cloudsql.dbPort -}}{{- end -}}
    {{- end -}}

    {{- if $additionalConnection.enabled -}}
        {{- if $singleConnection -}}{{- if $v1 -}},{{- else -}} {{- end -}}{{- end -}}
        {{- $additionalConnection.connectionName -}}{{- if $v1 -}}=tcp:{{- $additionalConnection.dbPort -}}{{- end -}}
    {{- end -}}
    {{- end -}}

    {{- range $index, $conn := $connections -}}
        {{- if or $index $singleConnection $additionalConnection.enabled -}}{{- if $v1 -}},{{- else -}} {{- end -}}{{- end -}}
        {{- $conn.name -}}{{- if $v1 -}}=tcp:{{- $conn.port -}}{{- end -}}
    {{- end -}}

    {{- range $index, $inst := $instances -}}
        {{- if or $index (gt (len $connections) 0) $singleConnection $additionalConnection.enabled -}}{{- if $v1 -}},{{- else -}} {{- end -}}{{- end -}}
        {{- $inst.connectionName -}}{{- if $v1 -}}=tcp:{{- $inst.dbPort -}}{{- end -}}
    {{- end -}}

{{- end -}}
{{- end -}}

{{/*
Build a YAML list of Cloud SQL instance names for the v2 proxy.
Each instance is emitted as a separate positional argument.
Supports both legacy fields and the new cloudsql.instances format.
*/}}
{{- define "cloudsql.v2InstanceList" -}}
{{- $items := list -}}
{{- $v2Instances := default (list) .Values.cloudsql.instances -}}
{{- if not (gt (len $v2Instances) 0) -}}
{{- if .Values.cloudsql.connectionName -}}
{{- $items = append $items (printf "%s?port=%v" .Values.cloudsql.connectionName .Values.cloudsql.dbPort) -}}
{{- end -}}
{{- if .Values.cloudsql.additionalConnection.enabled -}}
{{- $items = append $items (printf "%s?port=%v" .Values.cloudsql.additionalConnection.connectionName .Values.cloudsql.additionalConnection.dbPort) -}}
{{- end -}}
{{- end -}}
{{- range $conn := (default (list) .Values.cloudsql.connections) -}}
{{- $items = append $items (printf "%s?port=%v" $conn.name $conn.port) -}}
{{- end -}}
{{- range $inst := (default (list) .Values.cloudsql.instances) -}}
{{- $items = append $items (printf "%s?port=%v" $inst.connectionName $inst.dbPort) -}}
{{- end -}}
{{- toYaml $items -}}
{{- end -}}

{{/*
Return true if volumeMounts should be rendered in the main container

*/}}
{{- define "job.shouldRenderVolumeMounts" -}}
{{- if or .Values.pvc.enabled .Values.multiplePvc.enabled (and .Values.fileSecretMounts .Values.fileSecretMounts.enabled) .Values.hostVolumeMounts -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
