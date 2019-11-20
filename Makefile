SHELL := /usr/bin/env bash

IMAGENAME=securekubernetes
IMAGEREPO=securekubernetes/$(IMAGENAME)
WORKDIR=/data
SERVEPORT=8080

DOCKER=docker build -t $(IMAGEREPO):latest .
COMMAND=docker run --rm -v `pwd`:$(WORKDIR)
BUILD=$(COMMAND) $(IMAGEREPO):latest build
SERVE=$(COMMAND) -p $(SERVEPORT):$(SERVEPORT) $(IMAGEREPO):latest serve
PUBLISH=$(COMMAND) -v $(HOME)/.gitconfig:/root/.gitconfig:ro -v $(HOME)/.ssh:/root/.ssh:ro -it $(IMAGEREPO):latest gh-deploy --clean
DEBUGSHELL=$(COMMAND) -v $(HOME)/.gitconfig:/root/.gitconfig:ro -v $(HOME)/.ssh:/root/.ssh:ro -it --entrypoint "sh" $(IMAGEREPO):latest

dockerbuild:
	@echo "Building $(IMAGEREPO):latest"
	@$(DOCKER)
dockerpush:
	@echo "Building $(IMAGEREPO):latest"
	@$(DOCKER)

build:
	@echo "Running site build in $(IMAGEREPO):latest"
	@$(BUILD)
serve:
	@echo "Starting $(IMAGEREPO):latest on port localhost:$(SERVEPORT)"
	@$(SERVE)
publish:
	@echo "Publishing to GH-Pages"
	@$(PUBLISH)
	@git stash && git stash clear
shell:
	@echo "Running a shell inside the container"
	@$(DEBUGSHELL)

.PHONY: dockerbuild build serve publish shell
