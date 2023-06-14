SHELL := /bin/bash
DIST_DIR := dist
GO_SOURCES := Makefile $(shell find . -type f -name '*.go') .gomodtidy.done
ROBOT_SOURCES := $(shell find ./e2e_tests -type f -name '*.robot') $(shell find ./e2e_tests/resources -type f)
PYTHON_SOURCES := $(shell find ./e2e_tests -type f -name '*.py')

.DEFAULT_GOAL := help

.PHONY: all dist-all lint-all clean help

all: test dist-all ## Build all targets and perform testing

clean: ## Clean build artifacts
	rm -r dist e2e_tests/results .lint-*.done .gomodtidy.done 2>/dev/null || true

dist-all: ## Build all binary targets
dist-all: dist/caddy-put-linux-x86_64 dist/caddy-put-security-linux-x86_64

.PHONY: e2e-tests test
test: e2e-tests ## Run tests
e2e-tests:
e2e-tests: e2e_tests/results/.done
e2e_tests/results/.done: $(GO_SOURCES) $(ROBOT_SOURCES) $(shell find ./examples -type f)
	set +e; robot -d e2e_tests/results e2e_tests; exit_code=$$?; set -e; \
	(cd ./e2e_tests/results && ../resources/markdown_report_generator.py output.xml report.md --link_base=${REPORT_LINK_BASE}); \
	[[ $$exit_code -eq 0 ]] && touch $@ ; \
	exit $$exit_code;

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

lint-all: ## Run all linting tasks
lint-all: lint-go lint-robot lint-python

.PHONY: lint-go
lint-go: .lint-go.done ## Run Go code linting
.lint-go.done: $(GO_SOURCES)
	staticcheck ./...
	@if [ ! -z "$$(gofumpt -d -e .)" ] ; then \
		echo "gofumpt found issues:" ; \
		gofumpt -d -e . ; \
		exit 1 ; \
	fi
	touch $@

.PHONY: lint-robot
lint-robot: .lint-robot.done ## Run Robot Framework linting
.lint-robot.done: $(ROBOT_SOURCES) Makefile
	robot --dryrun ./e2e_tests
	rflint --recursive --configure TooFewTestSteps:0 --configure TooFewKeywordSteps:0 -e all ./e2e_tests
	touch $@

.PHONY: lint-python
lint-python: .lint-python.done ## Run Python code linting
.lint-python.done: $(PYTHON_SOURCES) Makefile
	pylint --max-line-length=120 $(PYTHON_SOURCES)
	touch $@

dist/caddy-put-security-linux-x86_64: ## Build Caddy with caddy-put-upload and caddy-security plugins
dist/caddy-put-security-linux-x86_64: $(GO_SOURCES) | $(DIST_DIR)
	go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
	rm -f caddy
	xcaddy build --with github.com/greenpau/caddy-security@v1.1.19 --with github.com/madworx/caddy-put-upload=.
	mv caddy $@

dist/caddy-put-linux-x86_64: ## Build Caddy with caddy-put-upload plugin
dist/caddy-put-linux-x86_64: $(GO_SOURCES) | $(DIST_DIR)
	GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -o $@ cmd/caddy/main.go

install-deps: ## Install dependencies
	pip3 install -r e2e_tests/resources/requirements.txt
	which xcaddy || go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
	which staticcheck || go install honnef.co/go/tools/cmd/staticcheck@latest
	which gofumpt || go install mvdan.cc/gofumpt@latest

go.mod:
	go mod init github.com/madworx/caddy-put-upload

go.sum: go.mod
	go mod tidy
	touch $@

.gomodtidy.done: go.sum
	touch $@

help: ## Print this help message
	@echo "Usage: make [target]"
	@echo "Targets:"
	@grep -h -E '^[a-zA-Z_/%0-9-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'

