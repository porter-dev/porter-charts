{{- /*
Shared by hosted-web, hosted-worker, and hosted-job. The three copies must stay identical,
because template names are global across the subcharts of one umbrella release.
*/ -}}

{{- define "hosted.fullname" -}}
{{- .Values.fullnameOverride | default (printf "%s-%s" .Release.Name .Chart.Name) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hosted.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "hosted.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "hosted.selectorLabels" . }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "hosted.podLabels" -}}
{{ include "hosted.selectorLabels" . }}
porter.run/application-name: {{ .Release.Name | quote }}
{{- with .Values.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "hosted.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- .Values.serviceAccount.name | default (include "hosted.fullname" .) -}}
{{- else -}}
{{- .Values.serviceAccount.name | default "default" -}}
{{- end -}}
{{- end -}}

{{- /* The umbrella release sets global.image. A standalone job install sets image instead. */ -}}
{{- define "hosted.image" -}}
{{- $image := .Values.image -}}
{{- if and .Values.global .Values.global.image .Values.global.image.repository -}}
{{- $image = .Values.global.image -}}
{{- end -}}
{{- toJson $image -}}
{{- end -}}

{{- define "hosted.podSpec" -}}
{{- $image := include "hosted.image" . | fromJson -}}
serviceAccountName: {{ include "hosted.serviceAccountName" . }}
terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
{{- with .Values.runtimeClassName }}
runtimeClassName: {{ . | quote }}
{{- end }}
{{- with $image.imagePullSecret }}
imagePullSecrets:
  - name: {{ . }}
{{- end }}
{{- end -}}

{{- /* The main container. Porter reads a job's exit code from the container named after the service. */ -}}
{{- define "hosted.container" -}}
{{- $image := include "hosted.image" . | fromJson -}}
name: {{ include "hosted.fullname" . }}
image: {{ printf "%s:%s" $image.repository $image.tag | quote }}
imagePullPolicy: {{ eq $image.tag "latest" | ternary "Always" "IfNotPresent" }}
{{- with trim .Values.container.command }}
command:
  {{- range splitList " " . }}
  - {{ . | quote }}
  {{- end }}
{{- end }}
{{- if or .Values.configMapRefs .Values.secretRefs }}
{{- if ne (len .Values.configMapRefs) (len .Values.secretRefs) }}
{{- fail "configMapRefs and secretRefs must be the same length" }}
{{- end }}
envFrom:
  {{- range $index, $configMap := .Values.configMapRefs }}
  - configMapRef:
      name: {{ $configMap }}
  - secretRef:
      name: {{ index $.Values.secretRefs $index }}
  {{- end }}
{{- end }}
env:
  - name: PORTER_APP_SERVICE_NAME
    value: {{ include "hosted.fullname" . | quote }}
  - name: PORTER_IMAGE_TAG
    value: {{ $image.tag | quote }}
  - name: PORTER_POD_REVISION
    value: {{ .Release.Revision | quote }}
  - name: PORTER_RESOURCES_CPU
    value: {{ .Values.resources.requests.cpu | quote }}
  - name: PORTER_RESOURCES_RAM
    value: {{ .Values.resources.requests.memory | quote }}
  - name: PORTER_RESOURCES_REPLICAS
    value: {{ .Values.replicaCount | quote }}
  - name: PORTER_POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: PORTER_POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP
  - name: PORTER_NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  {{- /* A PORTERSECRET_<secret> value reads the key of the same name from that Secret. */}}
  {{- range $key, $value := .Values.container.env.normal }}
  {{- $parts := splitList "_" (toString $value) }}
  - name: {{ $key }}
    {{- if and (eq (len $parts) 2) (eq (first $parts) "PORTERSECRET") }}
    valueFrom:
      secretKeyRef:
        name: {{ last $parts }}
        key: {{ $key }}
    {{- else }}
    value: {{ $value | quote }}
    {{- end }}
  {{- end }}
resources:
  {{- include "hosted.resources" .Values.resources | nindent 2 }}
{{- end -}}

{{- define "hosted.resources" -}}
requests:
  cpu: {{ .requests.cpu }}
  memory: {{ .requests.memory }}
limits:
  {{- if .setCPULimits }}
  cpu: {{ .limits.cpu | default .requests.cpu }}
  {{- end }}
  memory: {{ .limits.memory | default .requests.memory }}
{{- end -}}

{{- /* Renders one probe. A command probe runs the command, and any other probe calls the path on the http port. */ -}}
{{- define "hosted.probe" -}}
{{- if .command }}
exec:
  command:
    {{- range splitList " " (trim .command) }}
    - {{ . | quote }}
    {{- end }}
{{- else }}
httpGet:
  path: {{ .path }}
  port: http
{{- end }}
initialDelaySeconds: {{ .initialDelaySeconds }}
periodSeconds: {{ .periodSeconds }}
timeoutSeconds: {{ .timeoutSeconds }}
failureThreshold: {{ .failureThreshold }}
{{- end -}}

{{- define "hosted.probes" -}}
{{- range $name := list "livenessProbe" "readinessProbe" "startupProbe" }}
{{- $probe := get $.Values.health $name }}
{{- if $probe.enabled }}
{{ $name }}:
  {{- include "hosted.probe" $probe | trim | nindent 2 }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "hosted.hpa" -}}
{{- if .Values.autoscaling.enabled -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "hosted.fullname" . }}
  labels:
    {{- include "hosted.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "hosted.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
    {{- range $resource, $target := dict "cpu" .Values.autoscaling.targetCPUUtilizationPercentage "memory" .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- if $target }}
    - type: Resource
      resource:
        name: {{ $resource }}
        target:
          type: Utilization
          averageUtilization: {{ $target }}
    {{- end }}
    {{- end }}
{{- end -}}
{{- end -}}

{{- define "hosted.pdb" -}}
{{- if .Values.podDisruptionBudget.enabled -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "hosted.fullname" . }}
  labels:
    {{- include "hosted.labels" . | nindent 4 }}
spec:
  minAvailable: {{ printf "%d%%" (int .Values.podDisruptionBudget.minAvailablePercentage) | quote }}
  selector:
    matchLabels:
      {{- include "hosted.selectorLabels" . | nindent 6 }}
{{- end -}}
{{- end -}}

{{- define "hosted.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "hosted.serviceAccountName" . }}
  labels:
    {{- include "hosted.labels" . | nindent 4 }}
{{- end -}}
{{- end -}}
