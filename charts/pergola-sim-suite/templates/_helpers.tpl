{{/*
Shared helpers for the pergola-sim-suite chart.
*/}}

{{/* Base name of the suite. */}}
{{- define "suite.name" -}}
{{- default .Chart.Name .Values.global.suiteName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Fully qualified release name. */}}
{{- define "suite.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "suite.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Per-component fullname: <release>-<component>. */}}
{{- define "suite.componentFullname" -}}
{{- printf "%s-%s" .Release.Name .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels applied to every object. */}}
{{- define "suite.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ include "suite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Component-scoped selector labels. Call with a dict:
  (dict "ctx" $ "component" "gazebo")
*/}}
{{- define "suite.selectorLabels" -}}
app.kubernetes.io/name: {{ .component }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{/* Resolve an image ref, applying the optional global registry prefix. */}}
{{- define "suite.image" -}}
{{- $registry := .ctx.Values.global.imageRegistry -}}
{{- if $registry -}}
{{ $registry }}{{ .repository }}:{{ .tag }}
{{- else -}}
{{ .repository }}:{{ .tag }}
{{- end -}}
{{- end -}}

{{/* Render imagePullSecrets if any are set globally. */}}
{{- define "suite.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets -}}
imagePullSecrets:
{{ toYaml . | indent 2 }}
{{- end -}}
{{- end -}}
