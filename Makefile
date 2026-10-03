REMOTE ?= origin
PROTECTED_BRANCHES ?= main master develop dev

# Shared local-check scripts, one level up in the workspace (same scripts the git hooks use).
PRE_PUSH_SCRIPT ?= ../scripts/pre-push.sh
PRE_COMMIT_SCRIPT ?= ../scripts/pre-commit.sh

.PHONY: clean-merged-branches dry-run-clean-merged-branches l10n check-hardcoded check check-fast check-app

## Regenerate Dart translation maps from ARB source files
l10n:
	cd packages/app && dart run tools/generate_trad_from_arb.dart

## Detect probable hardcoded user-facing strings in Flutter/UI code
check-hardcoded:
	cd packages/app && dart run tools/check_hardcoded_strings.dart

clean-merged-branches:
	@set -e; \
	git fetch --prune $(REMOTE); \
	default_branch=$$(git symbolic-ref --quiet --short refs/remotes/$(REMOTE)/HEAD 2>/dev/null | sed 's#^$(REMOTE)/##'); \
	if [ -z "$$default_branch" ]; then \
		default_branch="main"; \
	fi; \
	current_branch=$$(git rev-parse --abbrev-ref HEAD); \
	protected="$(PROTECTED_BRANCHES) $$default_branch $$current_branch"; \
	echo "Remote: $(REMOTE)"; \
	echo "Default branch: $$default_branch"; \
	echo "Protected branches: $$protected"; \
	git branch --format='%(refname:short)' | while read -r branch; do \
		[ -z "$$branch" ] && continue; \
		if echo "$$protected" | tr ' ' '\n' | grep -Fxq "$$branch"; then \
			continue; \
		fi; \
		is_stale=0; \
		track=$$(git for-each-ref --format='%(upstream:track)' "refs/heads/$$branch"); \
		if [ "$$track" = "[gone]" ]; then \
			is_stale=1; \
			reason="remote tracking branch is gone"; \
		elif ! git cherry -v "$$default_branch" "$$branch" | grep -q "^+"; then \
			is_stale=1; \
			reason="all commits are squashed/merged into $$default_branch"; \
		fi; \
		if [ $$is_stale -eq 1 ]; then \
			echo "Deleting local stale branch ($$reason): $$branch"; \
			git branch -D "$$branch"; \
		fi; \
	done

dry-run-clean-merged-branches:
	@set -e; \
	git fetch --prune $(REMOTE); \
	default_branch=$$(git symbolic-ref --quiet --short refs/remotes/$(REMOTE)/HEAD 2>/dev/null | sed 's#^$(REMOTE)/##'); \
	if [ -z "$$default_branch" ]; then \
		default_branch="main"; \
	fi; \
	current_branch=$$(git rev-parse --abbrev-ref HEAD); \
	protected="$(PROTECTED_BRANCHES) $$default_branch $$current_branch"; \
	echo "Remote: $(REMOTE)"; \
	echo "Default branch: $$default_branch"; \
	echo "Protected branches: $$protected"; \
	echo "Branches that would be deleted:"; \
	git branch --format='%(refname:short)' | while read -r branch; do \
		[ -z "$$branch" ] && continue; \
		if echo "$$protected" | tr ' ' '\n' | grep -Fxq "$$branch"; then \
			continue; \
		fi; \
		is_stale=0; \
		track=$$(git for-each-ref --format='%(upstream:track)' "refs/heads/$$branch"); \
		if [ "$$track" = "[gone]" ]; then \
			is_stale=1; \
			reason="remote tracking branch is gone"; \
		elif ! git cherry -v "$$default_branch" "$$branch" | grep -q "^+"; then \
			is_stale=1; \
			reason="all commits are squashed/merged into $$default_branch"; \
		fi; \
		if [ $$is_stale -eq 1 ]; then \
			echo " - $$branch ($$reason)"; \
		fi; \
	done

# Full local gate: analyze + every package's tests (delegates to the shared pre-push hook)
check:
	node ../manager/scripts/sync-copilot-tools.mjs --check
	node --test ../manager/scripts/sync-copilot-tools.test.mjs
	@if [ ! -f "$(PRE_PUSH_SCRIPT)" ]; then \
		echo "❌ $(PRE_PUSH_SCRIPT) introuvable : ce clone n'a pas les scripts partagés du workspace."; \
		echo "   Lance le gate à la main depuis $(CURDIR) :"; \
		echo "     dart analyze packages/runner packages/shared"; \
		echo "     (cd packages/app && flutter analyze)"; \
		echo "     (cd packages/runner && dart test)"; \
		echo "     (cd packages/shared && dart test)"; \
		echo "     (cd packages/app && flutter test)"; \
		exit 1; \
	fi
	bash $(PRE_PUSH_SCRIPT) "$(CURDIR)"
	@echo "✅ check : gate local complet OK (analyze + tests runner/shared/app)"

# Fast local gate: format + analyze (delegates to the shared pre-commit hook)
check-fast:
	node ../manager/scripts/sync-copilot-tools.mjs --check
	@if [ ! -f "$(PRE_COMMIT_SCRIPT)" ]; then \
		echo "❌ $(PRE_COMMIT_SCRIPT) introuvable : ce clone n'a pas les scripts partagés du workspace."; \
		echo "   Lance à la main : cd packages/app && flutter analyze --no-fatal-warnings ."; \
		exit 1; \
	fi
	bash $(PRE_COMMIT_SCRIPT) "$(CURDIR)"
	@echo "✅ check-fast : vérifications pre-commit OK"

# Mobile app only: flutter analyze then flutter test inside packages/app (fast iteration)
check-app:
	cd packages/app && flutter analyze
	cd packages/app && flutter test
	@echo "✅ check-app : analyzer + tests de l'app mobile OK"
