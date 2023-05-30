# PostgreSQL requirements for Daml Enterprise Helm Charts deployment

Any PostgreSQL server that meets these criteria is compatible.

Example SaaS solutions:

* Amazon [RDS for PostgreSQL](https://aws.amazon.com/rds/postgresql/) or [Aurora PostgreSQL](https://aws.amazon.com/fr/rds/aurora/)
* Azure [Database for PostgreSQL](https://azure.microsoft.com/en-us/products/postgresql/)
* Google [Cloud SQL](https://cloud.google.com/sql/docs/postgres) or [Cloud Spanner](https://cloud.google.com/spanner/docs/)

## Table of contents

- [Supported versions](#supported-versions)
- [Minimum server size](#minimum-server-size)
- [Availability](#availability)
- [Concurrent connections](#concurrent-connections)
- [SSL/TLS](#tls)
- [Debugging](#debugging)

---
## Supported versions

PostgreSQL server versions `11` to `14` are supported by Canton and Daml services.

## Minimum server size

If you install each Helm chart once (Domain, Participant, HTTP JSON API service & Trigger service)
using a shared PostgreSQL server for all databases, you should start with 4 vCPUs/cores and 16Go RAM.

## Availability

Your PostgresQL server should be highly available. Each Canton/Daml component always needs to be connected to its own database.

## Concurrent connections

You should verify your [PostgreSQL server maximum allowed connections](https://www.postgresql.org/docs/14/runtime-config-connection.html#GUC-MAX-CONNECTIONS),
espically if you share the same instance for all components, to allow all of them to connect without issues.

The open-source PostgreSQL server default is `100`, a good start is to set `max_connections` to at least `200`. Remember that
you also need to have enough room for system (WAL, autovacuum, replication, etc.) and admin connections.

On most cloud providers' SaaS solution, the default server max connections is scaled according to your instance size
and its available memory.

Client side settings are also available in Helm values, you can find them in the `Parameters` section of each chart readme.
For Canton nodes you can set `storage.maxConnections`. For Daml services you can set `storage.poolSize`
and `storage.minIdle`.

An HA deployment of all the Helm charts in this repository with the default values requires around `120` connections:
- Single Domain with two Sequencers
- Single Participant
- Single HTTP JSON API service
- Single Trigger service

## TLS

We strongly recommend to enable and enforce TLS for connections to your PostgreSQL server (Helm charts default).
Please refer to the relevant [PostgreSQL server and client documentation](https://www.postgresql.org/docs/).

On most cloud providers' SaaS solution, server SSL/TLS is enabled by default and certificates are signed by a public CA.
In your `storage` values, `sslRootCert`, `sslCert` and `sslKey` can be left with an empty string value `""`.
The default JVM trust store with common public CA certificates will be used.

## Scaling

In case your PostgreSQL server load gets high you can either or both:
- Scale vertically using a bigger server with more CPU/RAM
- Scale horizontally and host each database on a different PostgreSQL server

---
## Debugging

A few useful PostgreSQL queries below in case of issues with your server and/or databases.

#### Check locks

```sql
SELECT * FROM pg_locks;
```

#### Display database IDs and connection information

```sql
SELECT oid AS db_id,
       datname AS db_name,
       datallowconn AS db_allow_connect,
       datconnlimit AS db_connection_limit
FROM pg_database
ORDER BY oid;
```

#### All requests by specific user

Using `psql` can list roles/users with `\du+` then:

```sql
SELECT * FROM pg_stat_activity WHERE usename='<role_name>';
```

#### Display server max connections setting

```sql
show max_connections;
```

#### Total connections to server

```sql
SELECT sum(numbackends) FROM pg_stat_database;
```

#### Total connections to server per role/user

```sql
SELECT count(*) as connections, usename FROM pg_stat_activity GROUP BY usename ORDER BY connections DESC;
```
