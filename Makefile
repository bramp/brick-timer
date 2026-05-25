# Flutter Template Makefile

.PHONY: all run format analyze lint test test-ci fix upgrade clean app-artwork app-icons app-splash app-assets check-app-artwork-mtime app-pngs app-svgs precommit-install

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

ARTWORK_DIR = artwork
APP_DIR = apps/brick_timer
ICON_SVG = $(ARTWORK_DIR)/logo.svg
SPLASH_SVG = $(ARTWORK_DIR)/splash.svg
TITLE_SVG = $(ARTWORK_DIR)/title.svg
ICON_PNG = $(APP_DIR)/assets/app_icon.png
SPLASH_PNG = $(APP_DIR)/assets/splash.png
LOGO_ASSET_SVG = $(APP_DIR)/assets/logo.svg
TITLE_ASSET_SVG = $(APP_DIR)/assets/title.svg
ICON_SIZE ?= 1024
SPLASH_SIZE ?= 2048

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

# Convert source SVG artwork into PNG assets used by icon/splash generators.
$(ICON_PNG): $(ICON_SVG)
	@mkdir -p $(dir $@)
	@if command -v rsvg-convert >/dev/null 2>&1; then \
		rsvg-convert -a -w $(ICON_SIZE) -h $(ICON_SIZE) "$(ICON_SVG)" -o "$@"; \
	else \
		echo "Missing SVG renderer: rsvg-convert."; \
		echo "Install with: brew install librsvg (macOS) or apt-get install librsvg2-bin (Ubuntu)."; \
		exit 1; \
	fi

$(SPLASH_PNG): $(SPLASH_SVG)
	@mkdir -p $(dir $@)
	@if command -v rsvg-convert >/dev/null 2>&1; then \
		rsvg-convert -a -w $(SPLASH_SIZE) -h $(SPLASH_SIZE) "$(SPLASH_SVG)" -o "$@"; \
	else \
		echo "Missing SVG renderer: rsvg-convert."; \
		echo "Install with: brew install librsvg (macOS) or apt-get install librsvg2-bin (Ubuntu)."; \
		exit 1; \
	fi

# Regenerate PNG artwork used by the platform generators.
app-pngs:
	@$(MAKE) -B $(ICON_PNG) $(SPLASH_PNG)

# Copy SVG artwork used directly by app UI.
$(LOGO_ASSET_SVG): $(ICON_SVG)
	@mkdir -p $(dir $@)
	@cp "$(ICON_SVG)" "$@"

$(TITLE_ASSET_SVG): $(TITLE_SVG)
	@mkdir -p $(dir $@)
	@cp "$(TITLE_SVG)" "$@"

app-svgs:
	@$(MAKE) -B $(LOGO_ASSET_SVG) $(TITLE_ASSET_SVG)

app-icons: app-pngs
	$(APP) && dart run flutter_launcher_icons

app-splash: app-pngs
	$(APP) && dart run flutter_native_splash:create

app-assets: app-svgs app-icons app-splash

# CI-friendly check: fail if the SVG source was modified after the generated PNG.
check-app-artwork-mtime:
	@test -f "$(ICON_PNG)" || (echo "Missing generated file: $(ICON_PNG). Run 'make app-assets'." && exit 1)
	@test -f "$(SPLASH_PNG)" || (echo "Missing generated file: $(SPLASH_PNG). Run 'make app-assets'." && exit 1)
	@test -f "$(LOGO_ASSET_SVG)" || (echo "Missing generated file: $(LOGO_ASSET_SVG). Run 'make app-assets'." && exit 1)
	@test -f "$(TITLE_ASSET_SVG)" || (echo "Missing generated file: $(TITLE_ASSET_SVG). Run 'make app-assets'." && exit 1)
	@icon_svg_ts="$$(git log -1 --format=%ct -- "$(ICON_SVG)" 2>/dev/null)"; \
	icon_png_ts="$$(git log -1 --format=%ct -- "$(ICON_PNG)" 2>/dev/null)"; \
	splash_svg_ts="$$(git log -1 --format=%ct -- "$(SPLASH_SVG)" 2>/dev/null)"; \
	splash_png_ts="$$(git log -1 --format=%ct -- "$(SPLASH_PNG)" 2>/dev/null)"; \
	logo_svg_ts="$$(git log -1 --format=%ct -- "$(ICON_SVG)" 2>/dev/null)"; \
	logo_asset_ts="$$(git log -1 --format=%ct -- "$(LOGO_ASSET_SVG)" 2>/dev/null)"; \
	title_svg_ts="$$(git log -1 --format=%ct -- "$(TITLE_SVG)" 2>/dev/null)"; \
	title_asset_ts="$$(git log -1 --format=%ct -- "$(TITLE_ASSET_SVG)" 2>/dev/null)"; \
	if [ -z "$$icon_svg_ts" ]; then icon_svg_ts="$$(stat -f %m "$(ICON_SVG)" 2>/dev/null || stat -c %Y "$(ICON_SVG)" 2>/dev/null)"; fi; \
	if [ -z "$$icon_png_ts" ]; then icon_png_ts="$$(stat -f %m "$(ICON_PNG)" 2>/dev/null || stat -c %Y "$(ICON_PNG)" 2>/dev/null)"; fi; \
	if [ -z "$$splash_svg_ts" ]; then splash_svg_ts="$$(stat -f %m "$(SPLASH_SVG)" 2>/dev/null || stat -c %Y "$(SPLASH_SVG)" 2>/dev/null)"; fi; \
	if [ -z "$$splash_png_ts" ]; then splash_png_ts="$$(stat -f %m "$(SPLASH_PNG)" 2>/dev/null || stat -c %Y "$(SPLASH_PNG)" 2>/dev/null)"; fi; \
	if [ -z "$$logo_svg_ts" ]; then logo_svg_ts="$$(stat -f %m "$(ICON_SVG)" 2>/dev/null || stat -c %Y "$(ICON_SVG)" 2>/dev/null)"; fi; \
	if [ -z "$$logo_asset_ts" ]; then logo_asset_ts="$$(stat -f %m "$(LOGO_ASSET_SVG)" 2>/dev/null || stat -c %Y "$(LOGO_ASSET_SVG)" 2>/dev/null)"; fi; \
	if [ -z "$$title_svg_ts" ]; then title_svg_ts="$$(stat -f %m "$(TITLE_SVG)" 2>/dev/null || stat -c %Y "$(TITLE_SVG)" 2>/dev/null)"; fi; \
	if [ -z "$$title_asset_ts" ]; then title_asset_ts="$$(stat -f %m "$(TITLE_ASSET_SVG)" 2>/dev/null || stat -c %Y "$(TITLE_ASSET_SVG)" 2>/dev/null)"; fi; \
	if [ -z "$$icon_svg_ts" ] || [ -z "$$icon_png_ts" ] || [ -z "$$splash_svg_ts" ] || [ -z "$$splash_png_ts" ] || [ -z "$$logo_asset_ts" ] || [ -z "$$title_svg_ts" ] || [ -z "$$title_asset_ts" ]; then \
		echo "Unable to determine timestamps for artwork files."; \
		exit 1; \
	fi; \
	if [ "$$icon_svg_ts" -gt "$$icon_png_ts" ]; then \
		echo "$(ICON_SVG) is newer than $(ICON_PNG) in git history. Run 'make app-assets' and commit outputs."; \
		exit 1; \
	fi; \
	if [ "$$splash_svg_ts" -gt "$$splash_png_ts" ]; then \
		echo "$(SPLASH_SVG) is newer than $(SPLASH_PNG) in git history. Run 'make app-assets' and commit outputs."; \
		exit 1; \
	fi; \
	if [ "$$logo_svg_ts" -gt "$$logo_asset_ts" ]; then \
		echo "$(ICON_SVG) is newer than $(LOGO_ASSET_SVG) in git history. Run 'make app-assets' and commit outputs."; \
		exit 1; \
	fi; \
	if [ "$$title_svg_ts" -gt "$$title_asset_ts" ]; then \
		echo "$(TITLE_SVG) is newer than $(TITLE_ASSET_SVG) in git history. Run 'make app-assets' and commit outputs."; \
		exit 1; \
	fi; \
	echo "Artwork git-history check passed."
