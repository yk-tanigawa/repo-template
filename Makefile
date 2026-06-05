SHELL := /bin/bash

ifneq (,$(wildcard .env.local))
include .env.local
export
endif

EXTERNAL_DATA_ROOT ?= $(PROJECT_EXTERNAL_DATA_ROOT)
PROJECT_RELATED_REPOS ?=

.PHONY: help setup setup-data setup-related-repos install dev build test lint format clean

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

setup: setup-data setup-related-repos
	@echo "Add project-specific setup checks"

setup-data:
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

setup-related-repos:
	@if [ -n "$(PROJECT_RELATED_REPOS)" ]; then \
		mkdir -p _repos; \
		for spec in $(PROJECT_RELATED_REPOS); do \
			name=$${spec%%:*}; \
			var=$${spec#*:}; \
			if [ "$$name" = "$$spec" ] || [ -z "$$name" ] || [ -z "$$var" ]; then \
				echo "ERROR: invalid PROJECT_RELATED_REPOS entry '$$spec'. Use link-name:ENV_VAR."; \
				exit 1; \
			fi; \
			case "$$var" in \
				[0-9]*|*[!A-Za-z0-9_]*) \
					echo "ERROR: invalid environment variable name '$$var' in PROJECT_RELATED_REPOS."; \
					exit 1; \
					;; \
			esac; \
			case "$$name" in \
				*/*|.*|*:*) \
					echo "ERROR: invalid _repos link name '$$name'. Use a plain directory name."; \
					exit 1; \
					;; \
			esac; \
			target="$${!var}"; \
			if [ -z "$$target" ]; then \
				echo "ERROR: $$var is not set for related repository '$$name'."; \
				exit 1; \
			fi; \
			if [ ! -d "$$target" ]; then \
				echo "ERROR: related repository target not found for $$name: $$target"; \
				exit 1; \
			fi; \
			link="_repos/$$name"; \
			if [ -L "$$link" ]; then \
				current=$$(readlink "$$link"); \
				if [ "$$current" != "$$target" ]; then \
					echo "Updating stale $$link symlink: $$current -> $$target"; \
					rm "$$link" && ln -s "$$target" "$$link"; \
				fi; \
			elif [ -e "$$link" ]; then \
				echo "ERROR: '$$link' exists and is not a symlink. Move it manually before re-running 'make setup'."; \
				exit 1; \
			else \
				echo "Creating $$link -> $$target"; \
				ln -s "$$target" "$$link"; \
			fi; \
			echo "OK: $$link -> $$(readlink "$$link")"; \
		done; \
	else \
		echo "PROJECT_RELATED_REPOS not set; skipping _repos/ symlink setup"; \
	fi

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
