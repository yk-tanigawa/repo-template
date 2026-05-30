SHELL := /bin/bash

ifneq (,$(wildcard .env.local))
include .env.local
export
endif

EXTERNAL_DATA_ROOT ?= $(PROJECT_EXTERNAL_DATA_ROOT)

.PHONY: help setup install dev build test lint format clean

help:
	@echo "Available commands:"
	@echo "  make setup    - Prepare local machine-specific configuration"
	@echo "  make install  - Install project dependencies"
	@echo "  make dev      - Start local preview or development server"
	@echo "  make build    - Build or render the project"
	@echo "  make test     - Run tests"
	@echo "  make lint     - Run lint checks"
	@echo "  make format   - Apply formatting"
	@echo "  make clean    - Remove generated artifacts"

setup:
	@if [ -n "$(EXTERNAL_DATA_ROOT)" ]; then \
		if [ ! -d "$(EXTERNAL_DATA_ROOT)" ]; then \
			echo "ERROR: external data root not found: $(EXTERNAL_DATA_ROOT)"; \
			exit 1; \
		fi; \
		if [ -L _data ]; then \
			current=$$(readlink _data); \
			if [ "$$current" != "$(EXTERNAL_DATA_ROOT)" ]; then \
				echo "Updating stale _data/ symlink: $$current -> $(EXTERNAL_DATA_ROOT)"; \
				rm _data && ln -s "$(EXTERNAL_DATA_ROOT)" _data; \
			fi; \
		elif [ -e _data ]; then \
			echo "ERROR: '_data' exists and is not a symlink. Move it manually before re-running 'make setup'."; \
			exit 1; \
		else \
			echo "Creating _data/ symlink -> $(EXTERNAL_DATA_ROOT)"; \
			ln -s "$(EXTERNAL_DATA_ROOT)" _data; \
		fi; \
		echo "OK: _data/ -> $$(readlink _data)"; \
	else \
		echo "PROJECT_EXTERNAL_DATA_ROOT not set; skipping _data/ symlink setup"; \
	fi
	@echo "Add project-specific setup checks"

install:
	@echo "Replace with project-specific dependency installation"

dev:
	@echo "Replace with project-specific development server command"

build:
	@echo "Replace with project-specific build or render command"

test:
	@echo "Replace with project-specific test command"

lint:
	@echo "Replace with project-specific lint command"

format:
	@echo "Replace with project-specific format command"

clean:
	@echo "Replace with project-specific cleanup command"
