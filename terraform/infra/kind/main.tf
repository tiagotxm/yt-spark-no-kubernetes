terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "0.6.0"
    }
  

    helm = {
      source  = "hashicorp/helm"
      version = "= 2.5.1"
    }
  
  
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm/"
  chart            = "argo-cd"
  namespace        = "gitops"
  create_namespace = true
  version          = "7.3.6"
  verify           = false
  values           = [file("config.yaml")]
}

resource "kind_cluster" "default" {
    name = var.cluster_name
    node_image = "kindest/node:v1.27.1"
    kind_config  {
        kind = "Cluster"
        api_version = "kind.x-k8s.io/v1alpha4"
        node {
            role = "control-plane"
        }
        node {
            role =  "worker"
        }
        node {
            role =  "worker"
        }
    }
}