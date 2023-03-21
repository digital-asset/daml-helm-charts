# Contributing guidelines

Contributions are welcome via GitHub Pull Requests. This document outlines the process to help get your contribution accepted.

Any type of contribution is welcome; from new features, bug fixes, documentation improvements.

## How to contribute?

1. Fork this repository, develop and test your changes on a new branch.
2. Submit a pull request, the title of the PR starts with the chart name (e.g. `[canton/participant]`).
3. If your PR corresponds to an issue, add `Fixes #XXX` to your pull request description.

***NOTE***: To make the Pull Requests' (PRs) testing and merging process easier, please submit
changes to multiple charts in separate PRs. If there is too many changes to the same helm chart,
try also to break it down into separate PRs.

### Technical requirements

When submitting a PR make sure that it:
- Must follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles.

### Documentation requirements

#### TL;DR

* Run script: `make refresh`
* Verify the changes: `git diff`

#### Auto-generated `Parameters` section

Markdown `## Parameters` section of each Helm chart `README.md` is automatically generated based on formatted comments in `values.yaml`
using the latest version of Bitnami Labs' [Readme Generator For Helm](https://github.com/bitnami-labs/readme-generator-for-helm)
and no specific configuration file (defaults).

```sh
cd path/to/chart/
readme-generator -v values.yaml -r README.md
```

⚠️ `values.yaml` must be a valid YAML file before you run the `readme-generator` tool, otherwise you will get cryptic errors.
You can use `yamllint` to verify the file if you do not already have syntax/formatting validation in your favorite IDE.

#### Propagate identical blocks everywhere

* Starting `### TLS` with the content of [`TLS.md`](./TLS.md):

```sh
find */ -name README.md | xargs sed -i -ne '/^### TLS$/ {p; r templates/TLS.md' -e ':a; n; /^##.*$/ {p; b}; ba}; p;'
```

* Starting `## License` with the content of [`LICENSE.md`](./LICENSE.md):

```sh
find */ -name README.md | xargs sed -i -ne '/^## License$/ {p; r templates/LICENSE.md' -e ':a; n; /^##.*$/ {p; b}; ba}; p;'
```

⚠️ These amazing `sed` one-liners might break in edge cases, check the diff

### PR approval and release process

1. Changes are manually reviewed and tested by Digital Asset.
1. When the PR passes all tests, the PR is merged by the reviewer(s) in the GitHub `main` branch.
1. We will release a new Helm chart version with our CI/CD system and make it available in the repository and refresh ArtifactHub.
