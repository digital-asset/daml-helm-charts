# Postgresql database requirements

## Table of Contents

- [Introduction](#introduction)
- [Versions](#versions)
- [Network connection](#network-connection)

## Introduction

This document intends to describe the required postgres database setup as dependency for daml-helm-charts deployment.

## Versions

The following postresql major versions are tested and supported by our components:
- 11.x
- 12.x
- 13.x
- 14.x

## Concurrent connection

[Max connections](https://www.postgresql.org/docs/14/runtime-config-connection.html#GUC-MAX-CONNECTIONS) setting of Postgresql must be set according to the number of components installed.
A minimal reference installation using the default values in this repository in all helm charts requires at least 140 connections - although we recommend a safety margin of 250 connections.

The minimal reference installation:
- Domain with two sequencers
- Participant
- HTTP JSON API service
- Trigger service


The deployed components must have network connection to the database instance(s).
Connecting to the database is described in our helm charts README files.