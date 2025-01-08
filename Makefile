

GOROOT ?= $(shell go env GOROOT)
GOPATH ?= $(shell go env GOPATH)

mockgen:
	@if ! command -v $(GOPATH)/bin/mockgen >/dev/null; then echo "Installing mockgen..."; go install go.uber.org/mock/mockgen@latest; fi
.PHONY: mockgen

mock_neuron/mocks.go: $(wildcard .generated/proto/github.com/cortexapps/neuron/*.go)
	@$(MAKE) mockgen
	@echo "Generating mocks for neuron"
	@mkdir -p mock_neuron
	$(GOPATH)/bin/mockgen github.com/cortexapps/neuron/.generated/proto/github.com/cortexapps/neuron CortexApiClient,NeuronAgentClient >mock_neuron/mocks.go
	@echo "Mocks generated"

test: mock_neuron/mocks.go
	@go mod tidy
	go test -v ./...


PUBLISH_DIR ?= /tmp/cortex-neuron-sdk-go
TARGET_REPO ?= git@github.com:cortexapps/neuron-go.git
CURRENT_SHA ?= $(shell git rev-parse HEAD)

publish: test
	@echo "Publishing SDK to $(PUBLISH_DIR)"
	@rm -rf $(PUBLISH_DIR)
	@git clone $(TARGET_REPO) $(PUBLISH_DIR)
	@cp -r . $(PUBLISH_DIR)
	@cd $(PUBLISH_DIR) && \
	if [ -n "$$(git status --porcelain)" ]; then \
		echo "Changes detected, publishing..."; \
		echo "$$(git status --porcelain)"; \
		git checkout -b "publish-$(CURRENT_SHA)" && \
		git add . && \
		git commit -m "Update SDK ($(CURRENT_SHA))" && \
		git push -f; \
	else \
		echo "No changes to publish"; \
	fi
