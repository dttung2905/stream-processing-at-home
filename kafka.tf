
resource "helm_release" "strimzi" {
  name      = "strimzi"
  repository = "https://strimzi.io/charts/"
  chart     = "strimzi-kafka-operator"
  version   = "0.38.0"  # Replace with the desired version

  set {
    name  = "operatorNamespaceLabels"
    value = "strimzi"
  }
}

resource "kubectl_manifest" "kafka_cluster" {
  yaml_body = file("${path.module}/kafka_cluster.yaml")
}

resource "kubectl_manifest" "kafka-consumer-app" {
  yaml_body = file("${path.module}/kafka_consumer.yaml")
}

resource "kubectl_manifest" "kafka-topic-my-topic" {
  yaml_body = file("${path.module}/kafka_consumer.yaml")
}

