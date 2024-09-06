#!/bin/bash

# Pull the Docker image tarball from GitHub Actions artifact
curl -L -o docker-image.tar "https://github.com/mr-mister007/react/releases/download/latest/docker-image.tar"

# Load the Docker image
docker load -i docker-image.tar

# Stop and remove the existing container if it exists
docker stop my-react-container || true
docker rm my-react-container || true

# Run the new container
docker run -d --name my-react-container -p 80:80 my-react-app
