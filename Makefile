.PHONY: add run

add:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Error: Please provide a filename"; \
		echo "Usage: make add my-post-title"; \
		exit 1; \
	fi
	./hugo new content content/posts/$(filter-out $@,$(MAKECMDGOALS)).en.md

run:
	./hugo server --buildDrafts

%:
	@:
