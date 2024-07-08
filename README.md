# Cloud Quest
This repository contains the Terraform code, Dockerfiles, and sample app code that was deployed. 
## Overview
This project is a Cloud deployment excercise which containerizes the preconfigured app (/src,/bin/,package.json) into a Docker container (Dockerfile), using Terraform to deploy the container into Kubernetes deployment hosted in Google Kubernetes Engine (container orchestration tool) on Google Cloud (GCP). Kubernetes service of type NodePort and Ingress (which deploys a GCP Load Balancer) is configured in front of the containered app for public external IP access. TLS is also configured for further security. This journey depicts the process of deploying this application and the proceeding components (Docker --> Artifact Registry repo --> Terraform --> K8s --> GKE --> K8s Services/Networking (NodePort & Ingress with Load Balancer) --> TLS) as well as how to test and access this deployment. All code used is hosted in this Github repo.
## The Components/Deployment Process
Cloud Quest Stages and steps
1. Githib repo for git versioning and tracking: 
    - https://github.com/EmilyT78/cloud-quest.git
2. Dockerfile (`cloud-quest/Dockerfile`) and `docker build` to build the app image 
3. Instantiate GCP Artifact Registry (AR) repo resource to hold the built image: 
    - `us-central1-docker.pkg.dev/cloud-quest-428515/quest-repo`
4. Push the Dockerfile to AR repo
    - `gcloud auth configure-docker us-central1-docker.pkg.dev`
    - `docker push us-central1-docker.pkg.dev/cloud-quest-428515/quest-repo/cloud-quest-app:v1.0`
5. Create Terraform resource to deploy the AR stored Docker image into Kuberentes container
    - ```
        spec {
            container {
            ...
            image = data.google_artifact_registry_docker_image.image.self_link
            ...
            }
        }
      ```
    - You cannot use containerd to build container images. Linux images with containerd include the Docker binary so that you can use Docker to build and push images. However, we don't recommend using individual containers and local nodes to run commands to build images. https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd#building_container_images_with_containerd
6. Define the K8s resource instance in Terraform main.tf, specifying GCP GKE as the K8s API host & cloud container orchestration tool
    - ```
        resource "google_container_cluster" "primary" {...}
      ```
    - ```
        provider "kubernetes" { 
            host     = "https://${google_container_cluster.primary.endpoint}"
        }
      ```
      
    - ```
        resource "kubernetes_deployment_v1" "app" {
            metadata {...}
            spec {
                template {
                    spec {
                        ...
                        image = data.google_artifact_registry_docker_image.image.self_link
                        port {
                            container_port = 3000
                        }
                    }
                }
            }
        }
        ```
7. Deploy the NodePort to handle porting to the exposed container port deployed on GKE and
    - ```
        resource "kubernetes_service_v1" "nodeport" {
            ...
            spec {
                ...
                port {
                port = 5000
                target_port = 3000
                protocol = "TCP"
                }
                type = "NodePort"
            }
        }
        ```
8. Deploy Ingress K8s services which creates a GCP load balancer to expose the Application IP for internet access
    - ```
        resource "kubernetes_ingress_v1" "ingress" {
            ...
            spec {
                default_backend {
                    service {
                        name = var.kubernetes_nodeport_service_name
                        port {
                        number = 5000
                        }
                    }
                }
            }
        }
        ```
9. Now that the app is externally exposed by the Ingress service GCP External Application Load Balancers IP at http://35.201.86.196 (`kubectl get ingress cloud-quest-app-ingress`), I navigated to the index page to get the SECRET_WORD
    - Added the SECRET_WORD as an environment variable in the Dockerfile
        - ```
            # Set env variable from the quest
            ENV SECRET_WORD=TwelveFactor
          ```
    - Ran `docker build -t quest-image:v1.1 .` again with a new tag :v1.1
    - Tagged the image again with the updated tag and same name of the Docker image stored in AR repo: 
        - `docker tag quest-image:v1.1 us-central1-docker.pkg.dev/cloud-quest-428515/quest-repo/cloud-quest-app:v1.1`
    - Pushed the second build image with updated tag to the AR repo: 
        - `docker push us-central1-docker.pkg.dev/cloud-quest-428515/quest-repo/cloud-quest-app:v1.1`
9. Generate a self-signed cert for the TLS (https://...) to use
10. Create the secret based on the cert using: ` kubectl create secret tls quest-app-tls     --namespace default     --key key.pem     --cert cert.pem`
10. Enable TLS in the Ingress service for secure access to the IP endpoint, specifying the secret_name to point to the cert
    - ```
        resource "kubernetes_ingress_v1" "ingress" {
            ...
            spec {
                default_backend {
                    service {
                        name = var.kubernetes_nodeport_service_name
                        port {
                        number = 5000
                        }
                    }
                }
            }
            tls {
                hosts = [ "35.201.86.196" ] # Exposed external application IP for TLS to secure
                secret_name = "quest-app-tls"
            }
        }
        ```
11. Terraform providers are specified (google + kubernetes) in main.tf - 
    - After each new infrastructure resource was defined in Terraform I ran these steps in order: `terraform validate`, `terraform plan`, `terraform apply` to test the resource deployment was working. These terraform commands were ran at each stage below:
        - After defining AR data source, GKE, and K8s resource
        - After creation of NodePort service
        - After creation of Ingress service
## Instructions for Review
How you can test/review this project
1. Access the index page endpoint at the external `<ip>` location where the app is deployed, provided by the Ingress Service GCP load balancer - https://35.201.86.196
2. Each component can be tested as follows (where `<ip>` is the location):
   1. Public cloud & index page (contains the secret word) - `http(s)://<ip_or_host>[:port]/`
   1. Docker check - `http(s)://<ip>[:port]/docker`
    -  Deploying the container through GKE uses containerd instead of Docker, therefore it says it does not show as using Docker container. However, Dockerfile & build image was used to deploy into GKE.
   1. Secret Word check - `http(s)://<ip>[:port]/secret_word`
   1. Load Balancer check  - `http(s)://<ip_or_host>[:port]/loadbalanced`
   1. TLS check - `http(s)://<ip_or_host>[:port]/tls`
3. Review the Docker image resources that were containerized
    - cloud-quest/
        - Dockerfile
        - dockerignore
4. Review the Terraform IaC code that created the resources
    - cloud-quest/terraform/
        - main.tf
        - variable.tf
5. Review the attached screenshots in the project submission email of the Google Cloud resources in GCP console.
## Testing and Verification
1. Tested Dockerfile by running locally
    - `docker run -p quest-image`
2. Tested Terraform configuration with
    - `terraform validate` 
    - `terraform plan`
3. Verified resource deployment through kubectl and GCP console
    - Check Kubernetes deployment 
        - `kubectl get ns`
        - `kubectl get pods -n <namespace>`
        - `kubectl logs <pod-name>`
        - `kubectl describe pod <pod-name>`
    - Check NodePort Service deployment
        - `kubectl get svc`
    - Check Ingress Service deployment
        - `kubectl get ingress`
    
## Next Steps and Considerations
"Given more time, I would improve..."
Discuss any shortcomings/immaturities in your solution and the reasons behind them (lack of time is a perfectly fine reason!)

Given more time, I would improve:
- The Docker image build process to use a more streamlined image build management service, such as Google Cloud Build for automated push to an image registry service (i.e. Dockerhub for cloud agnostic access, Artifact Registry in the case of GCP). 
- The Google Kubernetes Engine configuration to use more managed auto-scaling features (autopilot) for scaling to application compute needs.
- I would consider more of the differences between Ingress to ClusterIP services, vs Ingress to NodePort services, vs LoadBalancer to either of those backend services instead of relying on the Ingress --> NodePort structure I have, which I did for easier understanding as NodePort explicitly exposes the ports of all nodes and helped me understand the networking component easier. There may be a more efficient way to handle the load balancing configuration if I had more time to learn.
- I would implement an official TLS signed certificate for secure handling. 
- I would improve the structure and organization of the Terraform code - separate the Google infrastructure pieces (GKE, Artifact Registry) from the Kubernetes resource deployment piece for easier readability, and easier management of each separate resource.
- I would add more documentation/comments in the code to clearly explain the purpose of each deployment and resources.
- I would also try to deploy this on other clouds as well to compare the services and pros and cons of each service.
