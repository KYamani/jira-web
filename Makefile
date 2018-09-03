REPOSITORY ?= jira/web
VERSION    ?= 3.14.2
BUILD_ID   ?= 2

REGISTRY   ?= docker-registry.sec.cloudwatt.com
IMAGE      ?= $(REGISTRY)/$(REPOSITORY):$(VERSION)-$(BUILD_ID)

BUILD_OPTIONS = -t $(IMAGE)
ifdef http_proxy
BUILD_OPTIONS += --build-arg http_proxy=$(http_proxy)
endif
ifdef https_proxy
BUILD_OPTIONS += --build-arg https_proxy=$(https_proxy)
endif

BUILD_OPTIONS += --build-arg application_version=$(APPLICATION_VERSION)

BUILD_OPTIONS += $(BUILD_LABELS)

default: build

build:
	docker build --force-rm --no-cache --pull=false $(BUILD_OPTIONS) .

push:
	docker push $(IMAGE)

print-%:
	@echo '$($*)'

