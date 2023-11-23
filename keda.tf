resource "helm_release" "keda" {
  name      = "keda"
  repository = "https://kedacore.github.io/charts"
  chart     = "keda"
  version   = "2.12"  # Replace with the desired version
}
