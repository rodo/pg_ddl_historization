PostgreSQL Extension to historize in a table all DDL changes made on a database

# pg_ddl_log_historization
Historize the ddl changes inside PostgreSQL database

## Install

To install the extension, start by defining your connections
parameters in your shell as usual.

If your connection string is well set up, the install is easy as

```
$ make install
```

## Install with pg_tle

If you work with AWS RDS you can deploy the extension with
[pg_tle](https://github.com/aws/pg_tle), to build the file to deploy
it just do :

```
$ make pgtle
```

And execute the file pgtle.ddl_historization-0.3.sql on your instance

## Test

Tests are done using https://pgtap.org/

```
$ make test
```
