# Flutter Template Makefile

.PHONY: all run format analyze lint test test-ci fix upgrade clean app-icons app-splash app-assets precommit-install check-assets

# Device to run on: chrome, macos, ios, android (default: chrome)
DEVICE ?= chrome
# Integration test device. Defaults to host platform (macOS uses macos; others use chrome).
TEST_DEVICE ?= $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo macos; else echo chrome; fi)
# Port for Flutter web dev server
WEB_PORT ?= 3000

# Shorthand for running commands in the app directory
APP = cd apps/brick_timer
CATALOG = cd packages/lego_catalog
PRECOMMIT_VENV = .venv/pre-commit
PRECOMMIT_BIN = $(PRECOMMIT_VENV)/bin/pre-commit
ASSETS ?= go run github.com/bramp/assets/cmd/assets@latest
ASSETS_MANIFEST ?= assets.yaml

APP_DIR = apps/brick_timer
ICON_PNG = $(APP_DIR)/assets/app_icon.png
SPLASH_PNG = $(APP_DIR)/assets/splash.png
LOGO_ASSET_SVG = $(APP_DIR)/assets/logo.svg
TITLE_ASSET_SVG = $(APP_DIR)/assets/title.svg

# Load generated asset dependency rules if present.
-include .assets.mk

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

precommit-install:
	@if [ -x "$(PRECOMMIT_BIN)" ]; then \
		echo "pre-commit is already installed"; \
	else \
		python3 -m venv "$(PRECOMMIT_VENV)"; \
		"$(PRECOMMIT_VENV)/bin/pip" install pre-commit; \
	fi
	@"$(PRECOMMIT_BIN)" install

test:
	$(APP) && flutter test
	$(CATALOG) && dart test

test-ci:
	$(APP) && flutter test --reporter=compact
	$(APP) && for f in integration_test/*_test.dart; do \
		flutter test "$$f" --reporter=compact -d $(TEST_DEVICE) || exit $$?; \
	done
	$(CATALOG) && dart test --reporter=compact

fix:
	dart fix --apply

build_runner:
	$(APP) && dart run build_runner build --delete-conflicting-outputs

upgrade:
	dart pub upgrade --major-versions --tighten

clean:
	$(APP) && flutter clean
	rm -f .assets.mk

.assets.mk: $(ASSETS_MANIFEST)
	@$(ASSETS) gen --manifest $(ASSETS_MANIFEST) > .assets.mk

$(GENERATED_ASSET_FILES): .assets.mk
	@$(ASSETS) build --manifest $(ASSETS_MANIFEST) --target $@

check-assets: .assets.mk
	@$(ASSETS) check --manifest $(ASSETS_MANIFEST) --strict
	@$(ASSETS) verify --manifest $(ASSETS_MANIFEST)

app-icons: $(ICON_PNG)
	$(APP) && dart run flutter_launcher_icons

app-splash: $(SPLASH_PNG)
	$(APP) && dart run flutter_native_splash:create

app-assets: $(GENERATED_ASSET_FILES) app-icons app-splash
