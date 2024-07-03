# Cloud Quest
This repository contains the IaC code, Dockerfiles, sample app code that was deployed. 
## Overview
This project is a Cloud deployment quest Terraform to deploy the container onto (container orchestration tool (gke or some other k8s)) in (cloud provider) environment. The deployed application has been provided, and this journey depicts the components and process of deploying and protecting this app with a LB and TLS protection.
## The Components/Deployment Process
Outline the steps taken to deploy the application
1. Created Githib repo for git versioning and tracking
2. Created TF files to deploy app in Docker container --> then deploy into cloud provider env in a container orchestration tool --> then deploy the load balancer (after first steps) --> then deploy the TLS
3. TF will deploy the container in Cloud provider env
4. Deploy the LB - from in GCP (or AWS) - in front of the app
5. Deploy TLS (https://) 
## Testing and Verification/Instructions for Review
1. Hit the endpoints
2. Review the TF
## Code Review and Access (do I need this section)
1. Review the TF 
## Next Steps and Considerations
Given more time, how would I improve/components to update?
- If app needs to be scalable I would use K8s (if I decide to not se k8s), for a simpler container deployment in the cloud - I would use a single container deployer (i.e. 
## Conclusion/Feedback
