{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "nginx-ingress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "nginx-ingress.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified controller name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "nginx-ingress.controller.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.controller.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.controller.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Construct the path for the publish-service.

By convention this will simply use the <namespace>/<controller-name> to match the name of the
service generated.

Users can provide an override for an explicit service they want bound via `.Values.controller.publishService.pathOverride`

*/}}
{{- define "nginx-ingress.controller.publishServicePath" -}}
{{- $defServiceName := printf "%s/%s" .Release.Namespace (include "nginx-ingress.controller.fullname" .) -}}
{{- $servicePath := default $defServiceName .Values.controller.publishService.pathOverride }}
{{- print $servicePath | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified default backend name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "nginx-ingress.defaultBackend.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.defaultBackend.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.defaultBackend.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "nginx-ingress.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "nginx-ingress.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "nginx-ingress.wallarmTarantoolPort" -}}3313{{- end -}}
{{- define "nginx-ingress.wallarmTarantoolName" -}}{{ .Values.controller.name }}-wallarm-tarantool{{- end -}}
{{- define "nginx-ingress.wallarmSecret" -}}{{ .Values.controller.name }}-secret{{- end -}}

{{- define "nginx-ingress.wallarmInitContainer" -}}
- name: addnode
  image: "{{ .Values.controller.image.repository }}:{{ .Values.controller.image.tag }}"
  imagePullPolicy: "{{ .Values.controller.image.pullPolicy }}"
  command:
  - sh
  - -c
{{- if eq .Values.controller.wallarm.fallback "on"}}
{{ print  "- /usr/share/wallarm-common/synccloud --one-time && /usr/share/wallarm-common/sync-ip-lists --one-time -l STDOUT && /usr/share/wallarm-common/sync-ip-lists-source --one-time -l STDOUT && chmod 0644 /etc/wallarm/* || true" | indent 2}}
{{- else }}
{{ print  "- /usr/share/wallarm-common/synccloud --one-time && /usr/share/wallarm-common/sync-ip-lists --one-time -l STDOUT && /usr/share/wallarm-common/sync-ip-lists-source --one-time -l STDOUT && chmod 0644 /etc/wallarm/*" | indent 2}}
{{- end}}
  env:
  - name: WALLARM_API_HOST
    value: {{ .Values.controller.wallarm.apiHost | default "api.wallarm.com" }}
  - name: WALLARM_API_PORT
    value: {{ .Values.controller.wallarm.apiPort | default "444" | quote }}
  - name: WALLARM_API_USE_SSL
    {{- if or (.Values.controller.wallarm.apiSSL) (eq (.Values.controller.wallarm.apiSSL | toString) "<nil>") }}
    value: "true"
    {{- else }}
    value: "false"
    {{- end }}
  - name: WALLARM_API_TOKEN
    valueFrom:
      secretKeyRef:
        key: token
        name: {{ template "nginx-ingress.wallarmSecret" . }}
  - name: WALLARM_SYNCNODE_OWNER
    value: www-data
  - name: WALLARM_SYNCNODE_GROUP
    value: www-data
  volumeMounts:
  - mountPath: /etc/wallarm
    name: wallarm
  - mountPath: /var/lib/wallarm-acl
    name: wallarm-acl
  securityContext:
    {{- if .Values.podSecurityPolicy.enabled }}
    runAsUser: {{ .Values.controller.image.runAsUser | default 65534 }}
    {{- else }}
    runAsUser: 0
    {{- end }}
  resources:
{{ toYaml .Values.controller.wallarm.addnode.resources | indent 4 }}
{{- end -}}

{{- define "nginx-ingress.wallarmExportEnvContainer" -}}
- name: exportenv
  image: "{{ .Values.controller.image.repository }}:{{ .Values.controller.image.tag }}"
  imagePullPolicy: "{{ .Values.controller.image.pullPolicy }}"
  command: ["sh", "-c", "while true; do timeout -k 15s 10m /usr/share/wallarm-common/export-environment -l STDOUT || true; sleep 3600; done"]
  volumeMounts:
  - mountPath: /etc/wallarm
    name: wallarm
  securityContext:
    {{- if .Values.podSecurityPolicy.enabled }}
    runAsUser: {{ .Values.controller.image.runAsUser | default 65534 }}
    {{- else }}
    runAsUser: 0
    {{- end }}
  resources:
{{ toYaml .Values.controller.wallarm.exportenv.resources | indent 4 }}
{{- end -}}

{{- define "nginx-ingress.wallarmSyncnodeContainer" -}}
- name: synccloud
  image: "{{ .Values.controller.image.repository }}:{{ .Values.controller.image.tag }}"
  imagePullPolicy: "{{ .Values.controller.image.pullPolicy }}"
  command:
  - sh
  - -c
  - /usr/share/wallarm-common/synccloud
  env:
  - name: WALLARM_API_HOST
    value: {{ .Values.controller.wallarm.apiHost | default "api.wallarm.com" }}
  - name: WALLARM_API_PORT
    value: {{ .Values.controller.wallarm.apiPort | default "444" | quote }}
  - name: WALLARM_API_USE_SSL
    {{- if or (.Values.controller.wallarm.apiSSL) (eq (.Values.controller.wallarm.apiSSL | toString) "<nil>") }}
    value: "true"
    {{- else }}
    value: "false"
    {{- end }}
  - name: WALLARM_API_TOKEN
    valueFrom:
      secretKeyRef:
        key: token
        name: {{ template "nginx-ingress.wallarmSecret" . }}
  - name: WALLARM_SYNCNODE_OWNER
    value: www-data
  - name: WALLARM_SYNCNODE_GROUP
    value: www-data
  - name: WALLARM_SYNCNODE_INTERVAL
    value: "{{ .Values.controller.wallarm.synccloud.wallarm_syncnode_interval_sec }}"
  volumeMounts:
  - mountPath: /etc/wallarm
    name: wallarm
  securityContext:
    {{- if .Values.podSecurityPolicy.enabled }}
    runAsUser: {{ .Values.controller.image.runAsUser | default 65534 }}
    {{- else }}
    runAsUser: 0
    {{- end }}
  resources:
{{ toYaml .Values.controller.wallarm.synccloud.resources | indent 4 }}
{{- end -}}

{{- define "nginx-ingress.wallarmSyncAclContainer" -}}
- name: sync-ip-lists
  image: "{{ .Values.controller.image.repository }}:{{ .Values.controller.image.tag }}"
  command: ["sh", "-c", "while true; do timeout -k 15s 3h /usr/share/wallarm-common/sync-ip-lists -l STDOUT || true; sleep 60; done"]
  volumeMounts:
  - mountPath: /etc/wallarm
    name: wallarm
  - mountPath: /var/lib/wallarm-acl
    name: wallarm-acl
  resources:
{{ toYaml .Values.controller.wallarm.acl.resources | indent 4 }}
  securityContext:
    {{- if .Values.podSecurityPolicy.enabled }}
    runAsUser: {{ .Values.controller.image.runAsUser | default 65534 }}
    {{- else }}
    runAsUser: 0
    {{- end }}
- name: sync-ip-lists-source
  image: "{{ .Values.controller.image.repository }}:{{ .Values.controller.image.tag }}"
  command: ["sh", "-c", "while true; do timeout -k 15s 3h /usr/share/wallarm-common/sync-ip-lists-source -l STDOUT || true; sleep 300; done"]
  volumeMounts:
  - mountPath: /etc/wallarm
    name: wallarm
  - mountPath: /var/lib/wallarm-acl
    name: wallarm-acl
  resources:
{{ toYaml .Values.controller.wallarm.mmdb.resources | indent 4 }}
  securityContext:
    {{- if .Values.podSecurityPolicy.enabled }}
    runAsUser: {{ .Values.controller.image.runAsUser | default 65534 }}
    {{- else }}
    runAsUser: 0
    {{- end }}
{{- end -}}

{{- define "nginx-ingress.wallarmCollectdContainer" -}}
- name: collectd
  image: "{{ .Values.controller.image.repository }}:{{ .Values.controller.image.tag }}"
  imagePullPolicy: "{{ .Values.controller.image.pullPolicy }}"
  args: ["/usr/sbin/collectd", "-f"]
  volumeMounts:
    - name: wallarm
      mountPath: /etc/wallarm
    - name: collectd-config
      mountPath: /etc/collectd
  resources:
{{ toYaml .Values.controller.wallarm.collectd.resources | indent 4 }}
  securityContext:
    {{- if .Values.podSecurityPolicy.enabled }}
    runAsUser: {{ .Values.controller.image.runAsUser | default 65534 }}
    {{- else }}
    runAsUser: 0
    {{- end }}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "deployment.apiVersion" -}}
{{- if semverCompare ">=1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1" -}}
{{- else -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for podSecurityPolicy.
*/}}
{{- define "podSecurityPolicy.apiVersion" -}}
{{- if semverCompare ">=1.10-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "policy/v1beta1" -}}
{{- else -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end -}}
