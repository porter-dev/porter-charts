{{/* The name of the application this chart installs */}}
{{- define "ack-lambda-controller.app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ack-lambda-controller.app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* The name and version as used by the chart label */}}
{{- define "ack-lambda-controller.chart.name-version" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* The name of the service account to use */}}
{{- define "ack-lambda-controller.service-account.name" -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}

{{- define "ack-lambda-controller.watch-namespace" -}}
{{- if eq .Values.installScope "namespace" -}}
{{ .Values.watchNamespace | default .Release.Namespace }}
{{- end -}}
{{- end -}}

{{/* The mount path for the shared credentials file */}}
{{- define "ack-lambda-controller.aws.credentials.secret_mount_path" -}}
{{- "/var/run/secrets/aws" -}}
{{- end -}}

{{/* The path the shared credentials file is mounted */}}
{{- define "ack-lambda-controller.aws.credentials.path" -}}
{{ $secret_mount_path := include "ack-lambda-controller.aws.credentials.secret_mount_path" . }}
{{- printf "%s/%s" $secret_mount_path .Values.aws.credentials.secretKey -}}
{{- end -}}

{{/* The rules a of ClusterRole or Role */}}
{{- define "ack-lambda-controller.rbac-rules" -}}
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - secrets
  verbs:
  - get
  - list
  - patch
  - watch
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ec2.services.k8s.aws
  resources:
  - securitygroups
  - securitygroups/status
  - subnets
  - subnets/status
  verbs:
  - get
  - list
- apiGroups:
  - iam.services.k8s.aws
  resources:
  - roles
  - roles/status
  verbs:
  - get
  - list
- apiGroups:
  - kafka.services.k8s.aws
  resources:
  - clusters
  - clusters/status
  verbs:
  - get
  - list
- apiGroups:
  - kms.services.k8s.aws
  resources:
  - keys
  - keys/status
  verbs:
  - get
  - list
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - aliases
  - codesigningconfigs
  - eventsourcemappings
  - functions
  - functionurlconfigs
  - layerversions
  - versions
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - aliases/status
  - codesigningconfigs/status
  - eventsourcemappings/status
  - functions/status
  - functionurlconfigs/status
  - layerversions/status
  - versions/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - mq.services.k8s.aws
  resources:
  - brokers
  - brokers/status
  verbs:
  - get
  - list
- apiGroups:
  - s3.services.k8s.aws
  resources:
  - buckets
  - buckets/status
  verbs:
  - get
  - list
- apiGroups:
  - secretsmanager.services.k8s.aws
  resources:
  - secrets
  - secrets/status
  verbs:
  - get
  - list
- apiGroups:
  - services.k8s.aws
  resources:
  - fieldexports
  - iamroleselectors
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - services.k8s.aws
  resources:
  - fieldexports/status
  - iamroleselectors/status
  verbs:
  - get
  - patch
  - update
{{- end }}

{{/* Convert k/v map to string like: "key1=value1,key2=value2,..." */}}
{{- define "ack-lambda-controller.feature-gates" -}}
{{- $list := list -}}
{{- range $k, $v := .Values.featureGates -}}
{{- $list = append $list (printf "%s=%s" $k ( $v | toString)) -}}
{{- end -}}
{{ join "," $list }}
{{- end -}}
