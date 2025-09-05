# Create namespace for ingress
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

# Deploy ingress-nginx via Helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    <<-EOF
    controller:
      service:
        annotations:
          # Example (enable NLB on AWS)
          # service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          # service.beta.kubernetes.io/aws-load-balancer-target-type: "ip"
    EOF
  ]
}
