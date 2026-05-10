# Tag-driven release helpers for grc-wallet-images.
#
# Mainnet and testnet ship on independent version timelines. Each
# `release-*` target validates the working tree, creates a network-
# prefixed git tag, and pushes it to origin, which fires the matching
# job in .github/workflows/publish.yml. The publish workflow strips
# the prefix before publishing, so the image tag stays clean
# (`:vX.Y.Z` or `:vX.Y.Z-testnet`).
#
# Usage:
#   make release-mainnet VERSION=0.2.0
#   make release-testnet VERSION=0.5.3
#
# VERSION is the bare semver — no leading `v`, no network prefix.
# Both are added automatically.

.DEFAULT_GOAL := help
.PHONY: help release-mainnet release-testnet tags _check-version _check-clean

help:
	@echo "Targets:"
	@echo "  release-mainnet VERSION=X.Y.Z   tag mainnet-vX.Y.Z and push to origin"
	@echo "  release-testnet VERSION=X.Y.Z   tag testnet-vX.Y.Z and push to origin"
	@echo "  tags                            list recent tags per flavour"

release-mainnet: _check-version _check-clean
	@TAG="mainnet-v$(VERSION)"; \
	 if git rev-parse "$$TAG" >/dev/null 2>&1; then \
	   echo "error: tag $$TAG already exists"; exit 1; \
	 fi; \
	 echo "Creating tag $$TAG"; \
	 git tag "$$TAG"; \
	 echo "Pushing $$TAG to origin"; \
	 git push origin "$$TAG"

release-testnet: _check-version _check-clean
	@TAG="testnet-v$(VERSION)"; \
	 if git rev-parse "$$TAG" >/dev/null 2>&1; then \
	   echo "error: tag $$TAG already exists"; exit 1; \
	 fi; \
	 echo "Creating tag $$TAG"; \
	 git tag "$$TAG"; \
	 echo "Pushing $$TAG to origin"; \
	 git push origin "$$TAG"

_check-version:
	@if [ -z "$(VERSION)" ]; then \
	   echo "error: VERSION is required (e.g. make release-mainnet VERSION=0.2.0)"; \
	   exit 1; \
	 fi

# Refuse to release with a dirty working tree — a release tag should
# point at a clean commit, not at someone's WIP. Commit or stash first.
_check-clean:
	@if ! git diff --quiet || ! git diff --cached --quiet; then \
	   echo "error: working tree has uncommitted changes; commit or stash first"; \
	   exit 1; \
	 fi

tags:
	@echo "Recent mainnet tags:"
	@git tag --list 'mainnet-v*' --sort=-version:refname | head -5 | sed 's/^/  /'
	@echo
	@echo "Recent testnet tags:"
	@git tag --list 'testnet-v*' --sort=-version:refname | head -5 | sed 's/^/  /'
