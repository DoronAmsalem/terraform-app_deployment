resource "kubernetes_namespace" "weather-namespace" {
  metadata {
    name = "weather"
  }
  depends_on = [aws_eks_node_group.worker-node-group]
}


resource "kubernetes_deployment" "weather-deployment" {
  metadata {
    name      = "weather-app"
    namespace = kubernetes_namespace.weather-namespace.metadata[0].name
    labels = {
      app = "weather-app"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "weather-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "weather-app"
        }
      }

      spec {
        container {
          image = "doronamsalem/website:webserver"
          name  = "weather-app-server"
          port {
            container_port = 5000
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_namespace.weather-namespace]
}


resource "kubernetes_service" "weather-app-service" {
  metadata {
    name      = "weather-app-svc"
    namespace = kubernetes_namespace.weather-namespace.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.weather-deployment.metadata[0].labels.app
    }
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 5000
    }
  }
  depends_on = [kubernetes_deployment.weather-deployment]
}
