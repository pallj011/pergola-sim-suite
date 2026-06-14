{{/*
MathWorks license environment shared by the MATLAB and Simulink components.
Call with (dict "ctx" $). Emits the env vars the mathworks/matlab image reads.
*/}}
{{- define "suite.mathworks.env" -}}
{{- $mw := .ctx.Values.global.mathworks -}}
- name: MLM_LICENSE_FILE
  value: {{ $mw.licenseServer | quote }}
- name: MATLAB_LICENSE_FILE
  value: {{ $mw.licenseServer | quote }}
- name: MWI_APP_PORT
  value: "8888"
{{- if $mw.acceptLicense }}
- name: MLM_LICENSE_TOKEN_OPTIONAL
  value: "true"
{{- end }}
{{- end -}}

{{/*
Guard rendering of MATLAB/Simulink unless the license agreement is accepted.
*/}}
{{- define "suite.mathworks.assertLicense" -}}
{{- if not .Values.global.mathworks.acceptLicense -}}
{{- fail "global.mathworks.acceptLicense must be set to true to deploy the MATLAB/Simulink components. Set it explicitly to confirm you have accepted the MathWorks license agreement, and configure global.mathworks.licenseServer." -}}
{{- end -}}
{{- if and (not .Values.global.mathworks.licenseServer) (not .Values.global.mathworks.licenseFileSecret) -}}
{{- fail "Configure either global.mathworks.licenseServer (port@host) or global.mathworks.licenseFileSecret for the MATLAB/Simulink components." -}}
{{- end -}}
{{- end -}}
