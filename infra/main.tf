terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------
# VPC
# ---------------------------
resource "google_compute_network" "vpc" {
  name = "backend-vpc"
}

# ---------------------------
# FIREWALL
# ---------------------------
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# ---------------------------
# VM INSTANCE
# ---------------------------
resource "google_compute_instance" "vm" {
  name         = "my-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }
}

# ---------------------------
# Artifact Registry
# ---------------------------
resource "google_artifact_registry_repository" "docker_repo" {
  provider = google
  repository_id = "my-repo"
  format        = "DOCKER"
  location      = var.region
}

# ---------------------------
# Service Account for CI/CD
# ---------------------------
resource "google_service_account" "ci_cd" {
  account_id   = "github-deployer"
  display_name = "GitHub CI/CD Deployer"
}

# IAM roles
resource "google_project_iam_binding" "artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"

  members = [
    "serviceAccount:${google_service_account.ci_cd.email}"
  ]
}

resource "google_project_iam_binding" "compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"

  members = [
    "serviceAccount:${google_service_account.ci_cd.email}"
  ]
}

resource "google_project_iam_binding" "sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${google_service_account.ci_cd.email}"
  ]
}
