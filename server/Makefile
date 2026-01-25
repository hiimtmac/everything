.PHONY: build push build-push clean info

# Image configuration
REGISTRY := ghcr.io/hiimtmac
REPO := everything
SERVICE := server
PLATFORM ?= linux/arm64

# Full image reference
IMAGE := $(REGISTRY)/$(REPO):$(SERVICE)

# Build the Docker image
build:
	docker buildx build \
		--platform $(PLATFORM) \
		--tag $(IMAGE) \
		--load \
		.

# Push the image to GitHub Container Registry
push:
	docker push $(IMAGE)

# Build and push in one step (for CI/CD)
build-push:
	docker buildx build \
		--platform $(PLATFORM) \
		--tag $(IMAGE) \
		--push \
		.

# Remove local image
clean:
	docker rmi $(IMAGE) || true

# Show current configuration
info:
	@echo "Image: $(IMAGE)"
	@echo "Platform: $(PLATFORM)"
