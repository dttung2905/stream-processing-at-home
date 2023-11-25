resource "helm_release" "keda" {
  name      = "keda"
  repository = "https://kedacore.github.io/charts"
  chart     = "keda"
  version   = "2.12"  # Replace with the desired version
}

resource "kubectl_manifest" "kafka_scaled_object" {
  yaml_body = file("${path.module}/manifest/keda-scaled-object.yaml")
}
