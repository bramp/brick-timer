.DEFAULT_GOAL := all

.PHONY: all deps run format analyze lint test test-ci test-unit-ci test-integration-ci fix upgrade clean app-icons app-splash app-assets precommit-install check-assets regen-flutter verify-android-package

# Device to run on: chrome, macos, ios, android (default: chrome)
DEVICE ?= chrome
# Integration test device. Defaults to host platform (macOS uses macos; others use chrome).
TEST_DEVICE ?= $(shell if [ "$$(uname -s)" = "Darwin" ]; then echo macos; else echo chrome; fi)
# Port for Flutter web dev server
WEB_PORT ?= 3000

# Shorthand for running commands in the app directory
APP = cd apps/bricktimer
CATALOG = cd packages/lego_catalog
PRECOMMIT_VENV = .venv/pre-commit
PRECOMMIT_BIN = $(PRECOMMIT_VENV)/bin/pre-commit
ASSETS ?= go run github.com/bramp/assets/cmd/assets@latest
ASSETS_MANIFEST ?= assets.yaml

APP_DIR = apps/bricktimer
ICON_PNG = $(APP_DIR)/assets/app_icon.png
SPLASH_PNG = $(APP_DIR)/assets/splash.png
LOGO_ASSET_SVG = $(APP_DIR)/assets/logo.svg
TITLE_ASSET_SVG = $(APP_DIR)/assets/title.svg

all: deps format analyze test

# Load generated asset dependency rules if present.
-include .assets.mk

deps:
	flutter pub get --enforce-lockfile

## Run the app (use DEVICE=macos, DEVICE=ios, etc.)
run:
	$(APP) && flutter run -d $(DEVICE)

format:
	@find apps packages \
		\( -name build -o -name .dart_tool \) -prune -o \
		-name '*.dart' -print0 | xargs -0 dart format

analyze:
	dart analyze --fatal-infos apps/bricktimer_service packages/lego_catalog
	$(APP) && flutter analyze --no-pub --fatal-infos

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
	$(APP) && flutter test --no-pub
	$(CATALOG) && dart test

test-unit-ci:
	$(APP) && flutter test --no-pub --reporter=compact
	$(CATALOG) && dart test --reporter=compact

test-integration-ci:
	$(APP) && for f in integration_test/*_test.dart; do \
		flutter test "$$f" --no-pub --reporter=compact -d $(TEST_DEVICE) || exit $$?; \
	done

test-ci: test-unit-ci test-integration-ci

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
	@$(ASSETS) verify -manifest $(ASSETS_MANIFEST) -strict

app-icons: $(ICON_PNG)
	$(APP) && dart run flutter_launcher_icons

app-splash: $(SPLASH_PNG)
	$(APP) && dart run flutter_native_splash:create

app-assets: $(GENERATED_ASSET_FILES) app-icons app-splash

## Regenerate Flutter platform scaffolding for existing app.
## Run occasionally after Flutter SDK upgrades to refresh generated host files.
regen-flutter:
	$(APP) && flutter create . \
		--org net.bramp \
		--platforms=android,ios,macos,linux,windows,web \
		--android-language kotlin
	@rm -f $(APP_DIR)/README.md $(APP_DIR)/analysis_options.yaml
	$(MAKE) verify-android-package

## Guard against accidental package-name regressions during regeneration.
verify-android-package:
	@grep -q 'namespace = "net.bramp.bricktimer"' $(APP_DIR)/android/app/build.gradle.kts || (echo "Expected Android namespace net.bramp.bricktimer" && exit 1)
	@grep -q 'applicationId = "net.bramp.bricktimer"' $(APP_DIR)/android/app/build.gradle.kts || (echo "Expected Android applicationId net.bramp.bricktimer" && exit 1)
