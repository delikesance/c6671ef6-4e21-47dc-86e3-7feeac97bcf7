REMOTE ?= origin
PROTECTED_BRANCHES ?= main master develop dev

.PHONY: clean-merged-branches dry-run-clean-merged-branches l10n check-hardcoded

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
