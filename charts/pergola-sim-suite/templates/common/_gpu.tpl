{{/*
GPU scheduling fragments shared by components.

"suite.gpu.resources" — emits the limits entry for a GPU request.
  Call with (dict "ctx" $ "count" 1). Renders nothing if count is falsy.
*/}}
{{- define "suite.gpu.resources" -}}
{{- if .count -}}
{{ .ctx.Values.global.gpu.resourceName }}: {{ .count }}
{{- end -}}
{{- end -}}

{{/*
"suite.gpu.scheduling" — emits runtimeClassName, nodeSelector and tolerations
needed to land a pod on a GPU node. Call with (dict "ctx" $).
Merges global GPU scheduling with anything the component already set is left
to the component template; this only adds the global GPU bits.
*/}}
{{- define "suite.gpu.runtimeClass" -}}
{{- with .ctx.Values.global.gpu.runtimeClassName -}}
runtimeClassName: {{ . }}
{{- end -}}
{{- end -}}

{{- define "suite.gpu.nodeSelector" -}}
{{- with .ctx.Values.global.gpu.nodeSelector -}}
{{ toYaml . }}
{{- end -}}
{{- end -}}

{{- define "suite.gpu.tolerations" -}}
{{- with .ctx.Values.global.gpu.tolerations -}}
{{ toYaml . }}
{{- end -}}
{{- end -}}
