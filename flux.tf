resource "flux_bootstrap_git" "this" {
  path = "clusters/talos-cluster"
  components_extra = [
    "image-reflector-controller",
    "image-automation-controller"
  ]
  watch_all_namespaces = false
  depends_on = [
    talos_machine_bootstrap.talos,
  ]
}

