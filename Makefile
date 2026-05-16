# Flutter Template Makefile

.PHONY: all run format analyze test test-ci fix upgrade clean

# Device to run on: chrome, macos, ios, android (default: chrome)
DEVICE ?= chrome
# Port for Flutter web dev server
WEB_PORT ?= 3000

# Shorthand for running commands in the app directory
APP = cd apps/brick_time

all: format analyze test

## Run the app (use DEVICE=macos, DEVICE=ios, etc.)
run:
	$(APP) && flutter run -d $(DEVICE)

format:
	dart format .

analyze:
	flutter analyze apps/

test:
	$(APP) && flutter test

test-ci:
	$(APP) && flutter test --reporter=compact

fix:
	dart fix --apply

upgrade:
	dart pub upgrade --major-versions --tighten

clean:
	$(APP) && flutter clean
