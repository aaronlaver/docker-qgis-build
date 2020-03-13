# 
# Docker image build dependencies based
# on ubuntu:bionic
#

NAME=qgis-build-deps


BUILDID=$(shell date +"%Y%m%d%H%M")
COMMITID=$(shell git rev-parse --short HEAD)

VERSION:=bionic
IMAGE:=ubuntu:bionic

BUILD_ARGS=--build-arg="IMAGE=$(IMAGE)"

BUILDIMAGE=$(NAME):$(VERSION)-$(COMMITID)

all:
	@echo "Usage: make [build|clean|clean-all]"


build:
	docker build --rm $(BUILD_ARGS) -t $(BUILDIMAGE) \
		-t $(NAME):$(VERSION) --cache-from $(NAME):$(VERSION) .

clean:
	docker rmi $(BUILDIMAGE)

clean-all:
	docker rmi -f $(shell docker images $(BUILDIMAGE) -q)

#
# Default qgis branch to build
# May be specified on command line
#
QGIS_BRANCH:=final-3_10_3

OS_DIST_TARGET:=debian
OS_DIST_VERSION:=buster

#------------
# arm 32 bits
#------------
ARM32_VERSION:=armv7hf-$(OS_DIST_VERSION)
ARM32_BASE_IMAGE=armv7hf-$(OS_DIST_TARGET):$(OS_DIST_VERSION)

arm32-deps:
	$(MAKE) arm-build-deps \
		ARM_VERSION=$(ARM32_VERSION) \
		ARM_BASE_IMAGE=$(ARM32_BASE_IMAGE)

arm32-build:
	$(MAKE) arm-build \
		ARM_VERSION=$(ARM32_VERSION) \
		ARM_BASE_IMAGE=$(ARM32_BASE_IMAGE)

#------------
# arm 64 bits
#------------
ARM64_VERSION=aarch64-$(OS_DIST_VERSION)
ARM64_BASE_IMAGE=aarch64-$(OS_DIST_TARGET):$(OS_DIST_VERSION)

arm64-deps:
	$(MAKE) arm-build-deps \
		ARM_VERSION=$(ARM64_VERSION) \
		ARM_BASE_IMAGE=$(ARM64_BASE_IMAGE)

arm64-build:
	$(MAKE) arm-build \
		ARM_VERSION=$(ARM64_VERSION) \
		ARM_BASE_IMAGE=$(ARM64_BASE_IMAGE)


#--------------
# raspberrypi3
#--------------
RPI3_VERSION=aarch64-$(OS_DIST_VERSION)
RPI3_BASE_IMAGE=aarch64-$(OS_DIST_TARGET):$(OS_DIST_VERSION)

rpi3-deps:
	$(MAKE) arm-build-deps \
		ARM_VERSION=$(RPI3_VERSION) \
		ARM_BASE_IMAGE=$(RPI3_BASE_IMAGE)

rpi3-build:
	$(MAKE) arm-build \
		ARM_VERSION=$(RPI3_VERSION) \
		ARM_BASE_IMAGE=$(RPI3_BASE_IMAGE)


arm-build-deps:
ifdef REGISTRY_PREFIX
	docker pull $(REGISTRY_PREFIX)$(NAME):$(ARM_VERSION) || true
endif
	docker build --rm -t $(NAME):$(ARM_VERSION) --cache-from $(REGISTRY_PREFIX)$(NAME):$(ARM_VERSION) \
		--build-arg="ARM_BASE_IMAGE=$(ARM_BASE_IMAGE)" -f Dockerfile.arm .
ifdef REGISTRY_PREFIX
	docker tag  $(NAME):$(ARM_VERSION) $(REGISTRY_PREFIX)$(NAME):$(ARM_VERSION)
	docker push $(REGISTRY_PREFIX)$(NAME):$(ARM_VERSION)
endif

arm-build: arm-build-deps
	docker build --rm \
		--build-arg QGIS_BRANCH=$(QGIS_BRANCH) \
		--build-arg BUILDIMAGE=$(REGISTRY_PREFIX)$(NAME):$(ARM_VERSION) \
		-t $(REGISTRY_PREFIX)qgis-build:$(QGIS_BRANCH)-$(ARM_VERSION) -f Dockerfile.build .
ifdef REGISTRY_PREFIX
	docker push $(REGISTRY_PREFIX)qgis-build:$(QGIS_BRANCH)-$(ARM_VERSION)
endif


