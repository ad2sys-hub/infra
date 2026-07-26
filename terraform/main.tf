terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

# Cluster GKE (Souverain)
resource "google_container_cluster" "aurora_nexus_cluster" {
  name     = "aurora-nexus-cluster"
  location = var.zone

  # Nous enlevons le pool par défaut car nous voulons gérer les nouds manuellement
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnetwork.name
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "aurora-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.aurora_nexus_cluster.name
  node_count = 2

  node_config {
    machine_type = "e2-standard-4"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    labels = {
      env = "production"
    }
    tags = ["gke-node", "aurora-nexus"]
  }
}

# Réseau VPC
resource "google_compute_network" "vpc_network" {
  name                    = "aurora-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "aurora-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.name
}
