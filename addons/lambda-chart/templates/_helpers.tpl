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
  - ""
  resources:
  - secrets
  verbs:
  - get
  - list
  - patch
  - watch
- apiGroups:
  - ec2.services.k8s.aws
  resources:
  - securitygroups
  verbs:
  - get
  - list
- apiGroups:
  - ec2.services.k8s.aws
  resources:
  - securitygroups/status
  verbs:
  - get
  - list
- apiGroups:
  - ec2.services.k8s.aws
  resources:
  - subnets
  verbs:
  - get
  - list
- apiGroups:
  - ec2.services.k8s.aws
  resources:
  - subnets/status
  verbs:
  - get
  - list
- apiGroups:
  - iam.services.k8s.aws
  resources:
  - roles
  verbs:
  - get
  - list
- apiGroups:
  - iam.services.k8s.aws
  resources:
  - roles/status
  verbs:
  - get
  - list
- apiGroups:
  - kafka.services.k8s.aws
  resources:
  - clusters
  verbs:
  - get
  - list
- apiGroups:
  - kafka.services.k8s.aws
  resources:
  - clusters/status
  verbs:
  - get
  - list
- apiGroups:
  - kms.services.k8s.aws
  resources:
  - keys
  verbs:
  - get
  - list
- apiGroups:
  - kms.services.k8s.aws
  resources:
  - keys/status
  verbs:
  - get
  - list
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - aliases
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
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - codesigningconfigs
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
  - codesigningconfigs/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - eventsourcemappings
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
  - eventsourcemappings/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - functions
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
  - functions/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - functionurlconfigs
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
  - functionurlconfigs/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - lambda.services.k8s.aws
  resources:
  - layerversions
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
  - layerversions/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - lambda.services.k8s.aws
  resources:
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
  - versions/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - mq.services.k8s.aws
  resources:
  - brokers
  verbs:
  - get
  - list
- apiGroups:
  - mq.services.k8s.aws
  resources:
  - brokers/status
  verbs:
  - get
  - list
- apiGroups:
  - s3.services.k8s.aws
  resources:
  - buckets
  verbs:
  - get
  - list
- apiGroups:
  - s3.services.k8s.aws
  resources:
  - buckets/status
  verbs:
  - get
  - list
- apiGroups:
  - services.k8s.aws
  resources:
  - adoptedresources
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
  - adoptedresources/status
  verbs:
  - get
  - patch
  - update
- apiGroups:
  - services.k8s.aws
  resources:
  - fieldexports
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
  verbs:
  - get
  - patch
  - update
{{- end }}