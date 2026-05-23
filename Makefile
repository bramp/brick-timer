# Flutter Template Makefile

.PHONY: all run format analyze lint test test-ci fix upgrade clean

# Device to run on: chrome, macos, ios, android (default: chrome)
DEVICE ?= chrome
# Port for Flutter web dev server
WEB_PORT ?= 3000

# Shorthand for running commands in the app directory
APP = cd apps/brick_timer
CATALOG = cd packages/lego_catalog

all: format analyze test

## Run the app (use DEVICE=macos, DEVICE=ios, etc.)
run:
	$(APP) && flutter run -d $(DEVICE)

format:
	dart format .

analyze:
	dart analyze --fatal-infos .
	$(APP) && flutter analyze --fatal-infos

lint: analyze

test:
	$(APP) && flutter test
	$(CATALOG) && dart test

test-ci:
	$(APP) && flutter test --reporter=compact
	$(CATALOG) && dart test --reporter=compact

fix:
	dart fix --apply

build_runner:
	$(APP) && dart run build_runner build --delete-conflicting-outputs

upgrade:
	dart pub upgrade --major-versions --tighten

clean:
	$(APP) && flutter clean
