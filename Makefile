# Makefile for nvm-auto-use.fish

# URLs and constants
FISHER_BASE := https://raw.githubusercontent.com/jorgebucaran/fisher/main
FISHER_URL := $(FISHER_BASE)/functions/fisher.fish

# Tool versions (managed by Renovate via ivuorinen/renovate-config)
# renovate: datasource=npm depName=markdownlint-cli
MARKDOWNLINT_CLI_VERSION := 0.48.0
# renovate: datasource=npm depName=jsonlint
JSONLINT_VERSION := 1.6.3
# renovate: datasource=npm depName=markdown-table-formatter
MARKDOWN_TABLE_FORMATTER_VERSION := 1.7.0
# editorconfig-checker-disable-next-line
# renovate: datasource=github-releases depName=editorconfig-checker/editorconfig-checker
EDITORCONFIG_CHECKER_VERSION := v3.6.1

.PHONY: help install-tools lint lint-fish lint-markdown lint-md-tables \
	lint-json lint-fix lint-check lint-editorconfig test test-ci \
	test-unit test-integration clean

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
# markdownlint-cli and jsonlint are run via `npx --yes` at version pinned
# above (Renovate-managed), so they do not need a global install. We only
# need to make sure jq is available for JSON validation fallback.
install-tools:
	@echo "Installing linting tools..."
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
lint: lint-fish lint-markdown lint-md-tables lint-json lint-editorconfig

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

# Lint Markdown files (recursive — picks up docs/, tests/, etc.)
# Runs markdownlint-cli at the Renovate-pinned version via npx so CI and
# local environments use the same version.
lint-markdown:
	@echo "Linting Markdown files..."
	@find . -name '*.md' -type f \
		-not -path './node_modules/*' \
		-not -path './docs/audit/*' \
		-not -path './.claude/rules/*' \
		-print0 \
		| xargs -0 npx --yes markdownlint-cli@$(MARKDOWNLINT_CLI_VERSION) \
			--config .markdownlint.json || { \
				echo "Markdown linting failed"; \
				exit 1; \
			}
	@echo "Markdown files passed linting!"

# Verify Markdown tables are formatted (column-aligned). markdown-table-formatter
# reads stdin and exits 1 in --check mode when reformatting would change output.
lint-md-tables:
	@echo "Checking Markdown table formatting..."
	@status=0; \
	for file in $$(find . -name '*.md' -type f \
		-not -path './node_modules/*' \
		-not -path './docs/audit/*'); do \
		echo "Checking $$file..."; \
		npx --yes markdown-table-formatter@$(MARKDOWN_TABLE_FORMATTER_VERSION) \
			--check <"$$file" >/dev/null \
			|| { echo "Table formatting issue in $$file"; status=1; }; \
	done; \
	exit $$status
	@echo "Markdown tables passed formatting check!"

# Lint JSON files
# Prefers jq (system tool) when available; falls back to jsonlint via npx
# at the Renovate-pinned version.
lint-json:
	@echo "Linting JSON files..."
	@find . \
		-name "*.json" \
		-type f \
		-not -path './node_modules/*' \
		-exec sh -c \
		'file="$$1"; echo "Checking $$file..."; \
		if command -v jq >/dev/null 2>&1; then \
			jq empty "$$file" >/dev/null || { \
				echo "JSON syntax error in $$file"; exit 1; }; \
		else \
			npx --yes jsonlint@$(JSONLINT_VERSION) -q "$$file" || { \
				echo "JSON syntax error in $$file"; exit 1; }; \
		fi' \
		sh {} \;
	@echo "JSON files passed linting!"

# Check EditorConfig compliance
# Installer pulls the Renovate-pinned release tag when no system binary exists.
lint-editorconfig:
	@echo "Checking EditorConfig compliance..."
	@if command -v editorconfig-checker >/dev/null 2>&1; then \
		editorconfig-checker; \
	elif command -v ec >/dev/null 2>&1; then \
		ec; \
	else \
		echo "Installing editorconfig-checker $(EDITORCONFIG_CHECKER_VERSION)..."; \
		EC_VERSION='$(EDITORCONFIG_CHECKER_VERSION)' \
			.github/install_editorconfig-checker.sh; \
		PATH="$$PWD/bin:$$PATH" editorconfig-checker; \
	fi
	@echo "EditorConfig compliance passed!"

# Fix auto-fixable linting issues
lint-fix:
	@echo "Fixing linting issues..."
	@echo "Formatting Fish files..."
	@find . -name "*.fish" -type f -exec fish_indent --write {} \;
	@echo "Fixing Markdown files..."
	@find . -name '*.md' -type f \
		-not -path './node_modules/*' \
		-not -path './docs/audit/*' \
		-not -path './.claude/rules/*' \
		-print0 \
		| xargs -0 npx --yes markdownlint-cli@$(MARKDOWNLINT_CLI_VERSION) \
			--config .markdownlint.json --fix 2>/dev/null \
		|| true
	@echo "Aligning Markdown tables..."
	@for file in $$(find . -name '*.md' -type f \
		-not -path './node_modules/*' \
		-not -path './docs/audit/*'); do \
		tmp=$$(mktemp); \
		if npx --yes markdown-table-formatter@$(MARKDOWN_TABLE_FORMATTER_VERSION) \
				<"$$file" >"$$tmp" 2>/dev/null; then \
			mv "$$tmp" "$$file"; \
		else \
			rm -f "$$tmp"; \
		fi; \
	done
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
	@command -v fish >/dev/null 2>&1 \
		&& fish -c 'nvm_cache clear' 2>/dev/null \
		|| true
	@echo "Cleanup complete!"
