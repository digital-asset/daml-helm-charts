<img src="./images/daml-enterprise-logo.svg" width="400px">

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/digital-asset)](https://artifacthub.io/packages/search?repo=digital-asset)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)

# Postgresql database requirements


## Table of Contents

- [Introduction](#introduction)
- [Versions](#versions)
- [Network connection](#network-connection)
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

[Max connections](https://www.postgresql.org/docs/14/runtime-config-connection.html#GUC-MAX-CONNECTIONS) setting of Postgresql must be set according to the number of components installed.
A minimal reference installation using the default values in this repository in all helm charts requires at least 140 connections. 

The deployed components must have network connection to the database instance(s).
Connecting to the database is described in our helm charts README files.

For example:
[Canton domain](https://github.com/digital-asset/daml-helm-charts/tree/main/charts/canton-domain#minimum-viable-configuration)
Under storage values.

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
