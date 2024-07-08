terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.35.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
}

provider "google" {
  project = var.google_project_id
}

data "google_client_config" "default" {}

data "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.artifactory_repository_name
  project = var.google_project_id
}
# artifacts/docker/cloud-quest-428515/us-central1/quest-repo/cloud-quest-app

data "google_artifact_registry_docker_image" "image" {
  location      = data.google_artifact_registry_repository.repo.location
  repository_id = data.google_artifact_registry_repository.repo.repository_id
  image_name    = var.container_image
}

resource "google_container_cluster" "primary" {
  name = var.cluster_name
  location = var.zone
  initial_node_count = var.node_count
  # Configuration of the default node pool
  node_config {
    machine_type = var.machine_type 
  }
}

provider "kubernetes" {
  host     = "https://${google_container_cluster.primary.endpoint}"
  # Configure service account token for authentication
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}


resource "kubernetes_deployment_v1" "app" {
  metadata {
    name = var.kubernetes_deployment_name
  }
  
  spec {
    replicas = 2

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
          name  = var.container_image  # Matching the container name from Dockerfile
          image = data.google_artifact_registry_docker_image.image.self_link
          port {
            container_port = 3000
          }
        }
      }
    }
  }
  
}

resource "kubernetes_service_v1" "nodeport" {
  metadata {
    name =  var.kubernetes_nodeport_service_name
    namespace = "default"
  }
  spec {
    selector = {
        app = var.app_name
    }

    port {
      port = 5000
      target_port = 3000
      protocol = "TCP"
    }
    
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = var.kubernetes_ingress_name
  }

  spec {
    default_backend {
      service {
        name = var.kubernetes_nodeport_service_name
        port {
          number = 5000
        }
      }
    }

    rule {
      http {
        path {
          backend {
            service {
                name = var.kubernetes_nodeport_service_name
                port {
                    number = 5000
                }
            }
          }
        }
      }
    }

    tls {
        hosts = [ "35.201.86.196" ]
        secret_name = "quest-app-tls"
    }
  }
}

