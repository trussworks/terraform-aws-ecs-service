`.PHONY: ensure_pre_commit
ensure_pre_commit: .git/hooks/pre-commit ## Ensure pre-commit is installed
.git/hooks/pre-commit: /usr/local/bin/pre-commit
	pre-commit install
	pre-commit install-hooks

.PHONY: pre_commit_tests
pre_commit_tests: ensure_pre_commit ## Run pre-commit tests
	pre-commit run --all-files --show-diff-on-failure

.PHONY: test
test: pre_commit_tests
	go test -count 1 -v -timeout 90m ./test/...

.PHONY: clean
clean:
	rm -f .*.stamp
