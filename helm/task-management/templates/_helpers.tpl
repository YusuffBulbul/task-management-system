{{/*
Task Management System ortak Helm etiketleri.
*/}}
{{- define "task-management.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
app.kubernetes.io/part-of: task-management
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}