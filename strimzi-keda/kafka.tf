
resource "helm_release" "strimzi" {
  name       = "strimzi"
  repository = "https://strimzi.io/charts/"
  chart      = "strimzi-kafka-operator"
  version    = "0.38.0" # Replace with the desired version

  set {
    name  = "operatorNamespaceLabels"
    value = "strimzi"
  }
}

resource "kubectl_manifest" "kafka_cluster" {
  depends_on = [helm_release.strimzi]
  yaml_body  = file("${path.module}/manifest/kafka_cluster.yaml")
}

resource "kubectl_manifest" "kafka-consumer-app" {
  depends_on = [kubectl_manifest.kafka_cluster, kubectl_manifest.kafka-topic-my-topic]
  yaml_body  = file("${path.module}/manifest/kafka_consumer.yaml")
}

resource "kubectl_manifest" "kafka-producer-job" {
  depends_on = [kubectl_manifest.kafka_cluster, kubectl_manifest.kafka-topic-my-topic, kubectl_manifest.kafka-consumer-app]
  yaml_body  = file("${path.module}/manifest/kafka_producer.yaml")
}

resource "kubectl_manifest" "kafka-topic-my-topic" {
  depends_on = [kubectl_manifest.kafka_cluster]
  yaml_body  = file("${path.module}/manifest/kafka-topic.yaml")
}

