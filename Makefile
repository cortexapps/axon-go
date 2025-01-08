

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
