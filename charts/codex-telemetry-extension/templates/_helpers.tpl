{{- define "codex-telemetry-extension.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "codex-telemetry-extension.fullname" -}}
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

{{- define "codex-telemetry-extension.labels" -}}
app.kubernetes.io/name: {{ include "codex-telemetry-extension.name" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "codex-telemetry-extension.normalizer.fullname" -}}
{{- printf "%s-normalizer" (include "codex-telemetry-extension.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "codex-telemetry-extension.evaluator.fullname" -}}
{{- printf "%s-evaluator" (include "codex-telemetry-extension.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "codex-telemetry-extension.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "codex-telemetry-extension.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
