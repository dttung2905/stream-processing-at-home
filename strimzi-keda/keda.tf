resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.12.0" # Replace with the desired version
}

resource "kubectl_manifest" "kafka_scaled_object" {
  depends_on = [kubectl_manifest.kafka_cluster, kubectl_manifest.kafka-topic-my-topic, kubectl_manifest.kafka-consumer-app]
  yaml_body  = file("${path.module}/manifest/keda-scaled-object.yaml")
}
