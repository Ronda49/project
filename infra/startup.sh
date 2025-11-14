#!/bin/bash
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

gcloud auth configure-docker ${region}-docker.pkg.dev -q

docker pull ${region}-docker.pkg.dev/${project_id}/my-backend-repo/fastapi-app:latest
docker run -d -p 80:80 ${region}-docker.pkg.dev/${project_id}/my-backend-repo/fastapi-app:latest
