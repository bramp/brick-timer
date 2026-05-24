# Flutter Template Makefile

.PHONY: all run format analyze lint test test-ci fix upgrade clean app-artwork app-icons app-splash app-assets check-app-artwork-mtime app-pngs

# Device to run on: chrome, macos, ios, android (default: chrome)
DEVICE ?= chrome
# Port for Flutter web dev server
WEB_PORT ?= 3000

# Shorthand for running commands in the app directory
APP = cd apps/brick_timer
CATALOG = cd packages/lego_catalog

ARTWORK_DIR = artwork
APP_DIR = apps/brick_timer
ICON_SVG = $(ARTWORK_DIR)/logo.svg
SPLASH_SVG = $(ARTWORK_DIR)/splash.svg
ICON_PNG = $(APP_DIR)/assets/app_icon.png
SPLASH_PNG = $(APP_DIR)/assets/splash.png
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

app-icons: app-pngs
	$(APP) && dart run flutter_launcher_icons

app-splash: app-pngs
	$(APP) && dart run flutter_native_splash:create

app-assets: app-icons app-splash

# CI-friendly check: fail if source SVGs are newer than generated PNG inputs.
check-app-artwork-mtime:
	@test -f "$(ICON_PNG)" || (echo "Missing generated file: $(ICON_PNG). Run 'make app-assets'." && exit 1)
	@test -f "$(SPLASH_PNG)" || (echo "Missing generated file: $(SPLASH_PNG). Run 'make app-assets'." && exit 1)
	@if [ "$(ICON_SVG)" -nt "$(ICON_PNG)" ]; then \
		echo "$(ICON_SVG) is newer than $(ICON_PNG). Run 'make app-assets' and commit outputs."; \
		exit 1; \
	fi
	@if [ "$(SPLASH_SVG)" -nt "$(SPLASH_PNG)" ]; then \
		echo "$(SPLASH_SVG) is newer than $(SPLASH_PNG). Run 'make app-assets' and commit outputs."; \
		exit 1; \
	fi
	@echo "Artwork mtime check passed."
