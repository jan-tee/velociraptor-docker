#!/bin/bash

REGISTRY="$( cat REGISTRY )"
VERSION="$( cat VERSION )"
TAG="${VERSION}"
IMAGE="${REGISTRY}/velociraptor"

if [ -z "$REGISTRY" ]; then
  echo "Error: REGISTRY file empty or not found. Add your container registry URL."
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION file is empty or not found."
  exit 1
fi

echo "${IMAGE} version: $VERSION"

docker build --tag ${IMAGE}:${VERSION} --build-arg TAG=${TAG} --file Dockerfile . && \
  docker push ${IMAGE}:${VERSION} && \
  docker tag ${IMAGE}:${VERSION} ${IMAGE}:latest && \
  docker push ${IMAGE}:latest || { echo "Error during build process."; exit 1; }

echo "Done."