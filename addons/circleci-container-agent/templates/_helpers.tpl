{{/*
Expand the name of the chart.
*/}}
{{- define "container-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "container-agent.fullname" -}}
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
{{- define "container-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "container-agent.labels" -}}
helm.sh/chart: {{ include "container-agent.chart" . }}
{{ include "container-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "container-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "container-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
RBAC names
*/}}
{{- define "container-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "container-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name}}
{{- end }}
{{- end }}

{{- define "container-agent.roleName" -}}
{{- default (include "container-agent.fullname" .) .Values.rbac.role.name }}
{{- end }}

{{- define "container-agent.roleBindingName" -}}
{{- default (include "container-agent.fullname" .) .Values.rbac.roleBinding.name }}
{{- end }}

{{- define "container-agent.clusterRoleName" -}}
{{- default (include "container-agent.fullname" .) .Values.rbac.clusterRole.name }}
{{- end }}

{{- define "container-agent.clusterRoleBindingName" -}}
{{- default (include "container-agent.fullname" .) .Values.rbac.clusterRoleBinding.name }}
{{- end }}

{{- define "container-agent.tokens" -}}
{{- range $rc, $value := .Values.agent.resourceClasses -}}
{{- range $key, $value := $value -}}
{{- if eq $key "token" }}
{{ $rc | replace "/" "." }}: {{ $value | b64enc }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "container-agent.create-secret" -}}
{{- if include "container-agent.tokens" . -}}
true
{{- end }}
{{- end }}

{{- define "container-agent.token-secret" -}}
{{- if .Values.agent.customSecret }}
{{- .Values.agent.customSecret -}}
{{- else }}
{{- include "container-agent.fullname" . -}}
{{- end }}
{{- end }}