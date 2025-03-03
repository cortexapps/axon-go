

GOROOT ?= $(shell go env GOROOT)
GOPATH ?= $(shell go env GOPATH)

mockgen:
	@if ! command -v $(GOPATH)/bin/mockgen >/dev/null; then echo "Installing mockgen..."; go install go.uber.org/mock/mockgen@latest; fi
.PHONY: mockgen

mock_axon/mocks.go: $(wildcard .generated/proto/github.com/cortexapps/axon/*.go)
	@$(MAKE) mockgen
	@echo "Generating mocks for axon"
	@mkdir -p mock_axon
	$(GOPATH)/bin/mockgen github.com/cortexapps/axon/.generated/proto/github.com/cortexapps/axon CortexApiClient,AxonAgentClient >mock_axon/mocks.go
	@echo "Mocks generated"

test: mock_axon/mocks.go
	@go mod tidy
	go test -v ./...


PUBLISH_DIR ?= /tmp/cortex-axon-sdk-go
TARGET_REPO ?= git@github.com:cortexapps/axon-go.git
CURRENT_SHA ?= $(shell git rev-parse HEAD)

publish: test
	@echo "Publishing SDK to $(PUBLISH_DIR)"	
	@rm -rf $(PUBLISH_DIR)
	@git clone $(TARGET_REPO) $(PUBLISH_DIR)
	@cp -r . $(PUBLISH_DIR)
	@cd $(PUBLISH_DIR) && git checkout -b "publish-$(CURRENT_SHA)" && git add . && git commit -m "Update SDK ($(CURRENT_SHA))" && git push
	