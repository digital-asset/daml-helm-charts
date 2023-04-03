# Postgresql database requirements

## Table of Contents

- [Introduction](#introduction)
- [Versions](#versions)
- [Network connection](#network-connection)

## Introduction

This document intends to describe the required postgres database setup as dependency for daml-helm-charts deployment.

Any postgresql database that meets the criterias work. 

Some SaaS solution examples:
https://azure.microsoft.com/en-us/products/postgresql/
https://cloud.google.com/sql/docs/postgres
https://aws.amazon.com/rds/postgresql/

## Versions

The following postresql major versions are tested and supported by our components:
- 11.x
- 12.x
- 13.x
- 14.x

## Concurrent connection

[Max connections](https://www.postgresql.org/docs/14/runtime-config-connection.html#GUC-MAX-CONNECTIONS) setting of Postgresql must be set according to the number of components installed and their client-side settings. Please find these settings in each charts README files. For example, `storage.maxConnections` under [Canton Participant Helm Chart](https://github.com/digital-asset/daml-helm-charts/tree/main/charts/canton-participant#participant-configuration).




A minimal reference installation using the default values in this repository in all helm charts requires at least 140 connections - although we recommend a safety margin of 250 connections.

The minimal reference installation:
- Domain with two sequencers
- Participant
- HTTP JSON API service (optional, although part of the reference deployment)
- Trigger service (optional, although part of the reference deployment)


The deployed components must have network connection to the database instance(s).
Connecting to the database is described in our helm charts README files.