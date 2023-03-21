<img src="./images/daml-enterprise-logo.svg" width="400px">

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/digital-asset)](https://artifacthub.io/packages/search?repo=digital-asset)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)

# Daml Enterprise Helm Charts

Daml Enterprise deployment with high availability, ready to install in Kubernetes using [Helm](https://github.com/helm/helm).

## Updating `README.md` for each chart

### TL;DR

* Run script: `make refresh`
* Verify the changes: `git diff`
* Create a fork, create a new branch, commit your changes and open a pull request

### Auto-generated 'Parameters' section

Markdown `## Parameters` section of each Helm chart `README.md` is automatically generated based on comments in `values.yaml`
using the latest version of Bitnami Labs' [Readme Generator For Helm](https://github.com/bitnami-labs/readme-generator-for-helm)
and no specific configuration file (defaults).

```console
cd path/to/chart/
readme-generator -v values.yaml -r README.md
```

⚠️ `values.yaml` must be a valid YAML file before you run the `readme-generator` tool, otherwise you will get cryptic errors.
You can use `yamllint` to verify the file if you do not already have syntax/formatting validation in your favorite IDE.

### Propagate identical blocks everywhere

* Starting `### TLS` with the content of [`TLS.md`](./TLS.md):

```sh
find */ -name README.md | xargs sed -i -ne '/^### TLS$/ {p; r TLS.md' -e ':a; n; /^##.*$/ {p; b}; ba}; p;'
```

* Starting `## License` with the content of [`LICENSE.md`](./LICENSE.md):

```sh
find */ -name README.md | xargs sed -i -ne '/^## License$/ {p; r LICENSE.md' -e ':a; n; /^##.*$/ {p; b}; ba}; p;'
```

⚠️ These amazing `sed` one-liners might break in edge cases, check the diff

## License

Copyright &copy; 2023 Digital Asset (Switzerland) GmbH and/or its affiliates

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
