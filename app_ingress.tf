# ---- Deployment, Service and Ingress (app_ingress.tf) ----

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

          # Use the computed ECR image URI from locals.image
          image = local.image

          port {
            container_port = var.container_port
          }

          # NOTE: Database env/secret removed from Terraform-managed Deployment.
          # Provide DB config via other secure mechanism if needed (ExternalSecrets, IRSA + app fetch, CI, or manual k8s secret).

          # Readiness probe - adjust path if your app exposes a different health path
          readiness_probe {
            http_get {
              path = "/"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 2
            failure_threshold     = 5
          }

          # Optional: resources (uncomment and tune if needed)
          # resources {
          #   limits = {
          #   cpu    = "500m"
          #   memory = "512Mi"
          #   }
          #   requests = {
          #     cpu    = "250m"
          #     memory = "256Mi"
          #   }
          # }
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

# Ingress via manifest to keep annotations
resource "kubernetes_manifest" "app_ingress" {
  manifest = yamldecode(<<-YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${var.app_name}-ingress
  namespace: ${var.namespace}
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/proxy-body-size: "2048m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
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
