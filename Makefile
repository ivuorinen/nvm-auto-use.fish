# Makefile for nvm-auto-use.fish

# URLs and constants
FISHER_BASE := https://raw.githubusercontent.com/jorgebucaran/fisher/main
FISHER_URL := $(FISHER_BASE)/functions/fisher.fish

.PHONY: help install-tools lint lint-fish lint-markdown lint-json \
	lint-fix lint-check lint-editorconfig test test-ci test-unit \
	test-integration clean

# Default target
help:
	@echo "Available targets:"
	@echo "  install-tools    - Install all linting tools"
	@echo "  lint            - Run all linting checks"
	@echo "  lint-fish       - Lint Fish shell files"
	@echo "  lint-markdown   - Lint Markdown files"
	@echo "  lint-json       - Lint JSON files"
	@echo "  lint-fix        - Fix auto-fixable linting issues"
	@echo "  lint-check      - Check linting without fixing"
	@echo "  lint-editorconfig - Check EditorConfig compliance"
	@echo "  test            - Run tests (install plugin locally)"
	@echo "  test-ci         - Run tests in CI environment"
	@echo "  test-unit       - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  clean           - Clean temporary files"

# Install all required linting tools
install-tools:
	@echo "Installing linting tools..."
	@if ! command -v markdownlint >/dev/null 2>&1; then \
		echo "Installing markdownlint-cli..."; \
		npm install -g markdownlint-cli; \
	else \
		echo "markdownlint-cli already installed"; \
	fi
	@if ! command -v jsonlint >/dev/null 2>&1; then \
		echo "Installing jsonlint..."; \
		npm install -g jsonlint; \
	else \
		echo "jsonlint already installed"; \
	fi
	@if ! command -v jq >/dev/null 2>&1; then \
		echo "Installing jq..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install jq; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get install -y jq; \
		elif command -v yum >/dev/null 2>&1; then \
			sudo yum install -y jq; \
		else \
			echo "Please install jq manually"; \
		fi; \
	else \
		echo "jq already installed"; \
	fi
	@echo "All linting tools installed!"

# Run all linting checks
lint: lint-fish lint-markdown lint-json lint-editorconfig

# Lint Fish shell files
lint-fish:
	@echo "Linting Fish files..."
	@find . \
		-name "*.fish" \
		-type f \
		-exec sh -c \
		'echo "Checking $$1..."; \
		fish_indent --check "$$1" || { \
			echo "Formatting issues found in $$1"; exit 1; }' \
		sh {} \;
	@echo "Validating Fish syntax..."
	@fish -n functions/*.fish completions/*.fish 2>/dev/null || { \
		echo "Syntax errors found in Fish files"; \
		exit 1; \
	}
	@echo "Fish files passed linting!"

# Lint Markdown files
lint-markdown:
	@echo "Linting Markdown files..."
	@if command -v markdownlint >/dev/null 2>&1; then \
		markdownlint --config .markdownlint.json *.md || { \
			echo "Markdown linting failed"; \
			exit 1; \
		}; \
	else \
		echo "markdownlint not found, skipping markdown linting"; \
	fi
	@echo "Markdown files passed linting!"

# Lint JSON files
lint-json:
	@echo "Linting JSON files..."
	@find . \
		-name "*.json" \
		-type f \
		-exec sh -c \
		'file="$$1"; echo "Checking $$file..."; \
		if command -v jsonlint >/dev/null 2>&1; then \
			jsonlint "$$file" >/dev/null || { \
				echo "JSON syntax error in $$file"; exit 1; }; \
		elif command -v jq >/dev/null 2>&1; then \
			jq empty "$$file" >/dev/null || { \
				echo "JSON syntax error in $$file"; exit 1; }; \
		else \
			echo "No JSON linter found, skipping $$file"; fi' \
		sh {} \;
	@echo "JSON files passed linting!"

# Check EditorConfig compliance
lint-editorconfig:
	@echo "Checking EditorConfig compliance..."
	@if command -v editorconfig-checker >/dev/null 2>&1; then \
		editorconfig-checker; \
	elif command -v ec >/dev/null 2>&1; then \
		ec; \
	else \
		echo "Installing editorconfig-checker..."; \
		.github/install_editorconfig-checker.sh; \
		editorconfig-checker; \
	fi
	@echo "EditorConfig compliance passed!"

# Fix auto-fixable linting issues
lint-fix:
	@echo "Fixing linting issues..."
	@echo "Formatting Fish files..."
	@find . -name "*.fish" -type f -exec fish_indent --write {} \;
	@if command -v markdownlint >/dev/null 2>&1; then \
		echo "Fixing Markdown files..."; \
		markdownlint --config .markdownlint.json --fix *.md 2>/dev/null || true; \
	fi
	@echo "Linting fixes applied!"

# Check linting without fixing
lint-check: lint

# Test the plugin by installing it locally
test:
	@echo "Testing plugin installation..."
	@if command -v fisher >/dev/null 2>&1; then \
		fisher install .; \
		echo "Plugin installed successfully!"; \
		echo "Run 'fisher remove ivuorinen/nvm-auto-use.fish' to uninstall"; \
	else \
		echo "Fisher not found. Please install Fisher package manager first."; \
		exit 1; \
	fi

# Test in CI environment with Fish shell
test-ci:
	@echo "Testing plugin installation in CI..."
	@fish -c "\
		curl -sL $(FISHER_URL) | source; \
		fisher install jorgebucaran/fisher; \
		if fisher list | string match -q '*ivuorinen/nvm-auto-use.fish*'; \
			echo 'Plugin already installed, skipping installation'; \
		else; \
			fisher install .; \
		end; \
		echo 'Plugin test completed successfully in CI!'"

# Run unit tests
test-unit:
	@echo "Running unit tests..."
	@chmod +x tests/test_runner.fish
	@for test in tests/unit/*.fish; do \
		echo "Running $$test..."; \
		fish "$$test" || exit 1; \
	done
	@echo "Unit tests completed!"

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	@chmod +x tests/test_runner.fish
	@for test in tests/integration/*.fish; do \
		echo "Running $$test..."; \
		fish "$$test" || exit 1; \
	done
	@echo "Integration tests completed!"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.tmp" -type f -delete 2>/dev/null || true
	@find . -name ".DS_Store" -type f -delete 2>/dev/null || true
	@nvm_cache clear 2>/dev/null || true
	@echo "Cleanup complete!"
