.PHONY: lint format

PROJECT_ROOT := $(shell git rev-parse --show-toplevel)

lint:
	selene ./lua/

format:
	stylua lua/
