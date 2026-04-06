.PHONY: docs clean-docs build test lint

COLLECTION_NS = csmart
COLLECTION_NAME = swift
DOCS_DIR = docs

docs: $(DOCS_DIR)/build.sh
	cd $(DOCS_DIR) && pip install -q -r requirements.txt && ./build.sh

$(DOCS_DIR)/build.sh:
	mkdir -p $(DOCS_DIR)
	antsibull-docs sphinx-init \
		--use-current \
		--squash-hierarchy \
		--dest-dir $(DOCS_DIR) \
		$(COLLECTION_NS).$(COLLECTION_NAME)

clean-docs:
	rm -rf $(DOCS_DIR)

build:
	ansible-galaxy collection build --force

lint:
	yamllint -s .
	ansible-lint

test:
	molecule test
