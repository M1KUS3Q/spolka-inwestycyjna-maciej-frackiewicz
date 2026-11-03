# PostgreSQL

The local database runs in Docker Compose, so the same commands work on macOS,
Windows and Linux. Only Docker is required.

## Start / stop

From this directory:

```sh
docker compose up -d
docker compose down
docker compose down -v   # also deletes the data volume
```

Connection string:

```
postgresql://catering:catering@localhost:5432/catering
```

`createdb.sql` is mounted into the container's init directory, so it is applied
automatically the first time the data volume is created. The seeder in
`../seed/` drops and recreates the schema on every run.

If port `5432` is already taken, change the host side of the `ports` mapping.
