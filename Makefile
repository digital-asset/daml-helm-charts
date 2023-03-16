SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help
## help: Makefile: Prints this help message
help:
	@echo "Usage:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: refresh
## refresh: Makefile: (Re)generate markdown documentation for all helm charts
refresh:
	ls -d */ | xargs -t -I {} readme-generator-for-helm -v {}values.yaml -r {}README.md
	find */ -name README.md | xargs sed -i -ne '/^### TLS$$/ {p; r TLS.md'        -e ':a; n; /^##.*$$/ {p; b}; ba}; p;'
	find */ -name README.md | xargs sed -i -ne '/^## License$$/ {p; r LICENSE.md' -e ':a; n; /^##.*$$/ {p; b}; ba}; p;'
