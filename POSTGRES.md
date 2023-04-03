<img src="./images/daml-enterprise-logo.svg" width="400px">

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/digital-asset)](https://artifacthub.io/packages/search?repo=digital-asset)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)

# Postgresql database requirements


## Table of Contents

- [Introduction](#introduction)
- [Versions](#versions)
- [Before you begin](#before-you-begin)
- [Installing DAML Helm Charts](#installing-daml-helm-charts)
- [License](#license)

## Introduction

This document intends to describe the required postgres database setup as dependency for daml-helm-charts deployment.

## Versions

The following postresql major versions are tested and supported by our components:
- 11.x
- 12.x
- 13.x
- 14.x

## Network connection

The deployed components must have network connection to the database instance(s).
Connecting to the database is described in our helm charts README files.

## [Contributing guidelines](./CONTRIBUTING.md)

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
