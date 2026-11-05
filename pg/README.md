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

# Queries and functions

Proposed queries and functions shall be put in `queries/` and `functions/` respectively.
The file naming scheme is `q<number>_<short description>.sql` (numbers 1 to 20) for queries and `f<number>_<short description>.sql` (numbers 1 to 5) for functions.

## Running functions

In order to be accessible by the database the functions must be mounted as files in docker. If you want to test run a function, add a line to volumes inside docker-compose:

```
      - ./functions/<file>:/docker-entrypoint-initdb.d/<index>-<file>/:ro
```

where `index` is a number larger than that of the previous volume.

Currently the above is completely broken because the seeder wipes the functions from the db structure lmao