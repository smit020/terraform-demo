# ---- Deployment, Service and Ingress (app_ingress.tf) ----
# NOTE: variable declarations were moved to variables.tf

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.image
          args  = ["-text=hello-from-ecr-test"]

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_svc" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Use kubernetes_manifest to create an Ingress with explicit networking.k8s.io/v1 API
resource "kubernetes_manifest" "app_ingress" {
  manifest = yamldecode(<<-YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${var.app_name}-ingress
  namespace: ${var.namespace}
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${var.app_name}
            port:
              number: ${var.service_port}
YAML
  )
}
