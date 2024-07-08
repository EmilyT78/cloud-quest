variable "google_project_id" {
  type = string
  default = "cloud-quest-428515"
  description = "GCP Project ID"
}

variable "region" {
  type = string
  default = "us-central1"
  description = "Region hosting cloud resources"
}

variable "zone" {
  type = string
  default = "us-central1-a"
  description = "Region hosting cloud resources"
}

variable "cluster_name" {
  type = string
  default = "gcp-us-central-1-1"
  description = "Kubernetes cluster name"
}

variable "node_pool_name" {
  type = string
  default = "gke-standard-regional-node-pool"
  description = "Cluster node pool name"
}

variable "machine_type" {
  type = string
  default = "e2-micro"
  description = "Machine type for K8s compute resources"
}

variable "node_count" {
  type = number
  default = "2"
  description = "Number of nodes for the cluster"
}

variable "container_image" {
  type = string
  default = "cloud-quest-app"
  description = "Container image name from container registry"
}

variable "artifactory_repository_name" {
    type = string
    default = "quest-repo"
}

variable "kubernetes_deployment_name" {
    type = string
    default = "cloud-quest-app-deployment"
    description = "Metadata name of the kubernetes deployment"
}

variable "kubernetes_nodeport_service_name" {
  type = string
  default = "cloud-quest-app-nodeport-service"
  description = "Name of the Node port service to expose EIP"
}

variable "kubernetes_ingress_name" {
    type = string
    default = "cloud-quest-app-ingress"
    description = "Name of the ingress service"
}

variable "app_name" {
    type = string
    default = "quest-app"
    description = "App name inside the kubernetes deployment & services"
}