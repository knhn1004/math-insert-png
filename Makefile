.PHONY: build test clean run archive icons lint help

SCHEME     = MathInsert
PROJECT    = MathInsert.xcodeproj
BUILD_DIR  = build
DEST       = platform=macOS

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the app (debug)
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination '$(DEST)' \
		-derivedDataPath $(BUILD_DIR) \
		-quiet

release: ## Build the app (release)
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination '$(DEST)' \
		-derivedDataPath $(BUILD_DIR) \
		-quiet

test: ## Run unit tests
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination '$(DEST)' \
		-derivedDataPath $(BUILD_DIR) \
		-quiet

clean: ## Remove build artifacts
	xcodebuild clean \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-quiet
	rm -rf $(BUILD_DIR)

archive: ## Create .xcarchive for distribution
	xcodebuild archive \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-archivePath $(BUILD_DIR)/$(SCHEME).xcarchive \
		-destination '$(DEST)'

icons: ## Regenerate app icons
	python3 scripts/generate_icon.py

run: build ## Build and open the app
	open $(BUILD_DIR)/Build/Products/Debug/MathInsert.app

lint: ## Check Swift formatting (requires swift-format)
	swift-format lint --recursive MathInsert/ MathInsertTests/
