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

## Concurrent connections

[Max connections](https://www.postgresql.org/docs/14/runtime-config-connection.html#GUC-MAX-CONNECTIONS) setting of Postgresql must be set according to the number of components installed and their client-side settings - which are handled as helm values. Please find these values in each charts README files. For example, `storage.maxConnections` under [Canton Participant Helm Chart](https://github.com/digital-asset/daml-helm-charts/tree/main/charts/canton-participant#participant-configuration).


A minimal reference installation using the default values in this repository in all helm charts requires at least 140 connections - although we recommend starting with 200 concurrent connections set on postgres side.

The minimal reference installation:
- Domain with two sequencers
- Participant
- HTTP JSON API service (optional, although part of the reference deployment)
- Trigger service (optional, although part of the reference deployment)


The deployed components must have network connection to the database instance(s).
Connecting to the database is described in our helm charts README files.

## Postgres debug

This section provides a few useful commands in case of issues with the database.


Check participant locks (active/passive mechanism):
```sql
SELECT * FROM pg_locks;
```

Find database IDs:
```sql
SELECT oid AS database_id,
       datname AS database_name,
       datallowconn AS allow_connect,
       datconnlimit AS connection_limit
FROM pg_database
ORDER BY oid;
```

All requests by specific user:
```sql
SELECT * FROM pg_stat_activity WHERE usename='participant1';
```

Server max connections:
```sql
show max_connections;
```

Total connections:
```sql
SELECT sum(numbackends) FROM pg_stat_database;
```

Total connections by user:
```sql
SELECT count(*) as connections, usename FROM pg_stat_activity GROUP BY usename ORDER BY connections DESC;
```
