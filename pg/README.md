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

`createdb.sql` and every file in `functions/` are mounted into the container's
init directory, so they are applied automatically the first time the data
volume is created. Init scripts do **not** run again on later starts.

The seeder in `../seed/` leaves the schema alone: it truncates every table in
the `public` schema and refills it. Functions and indexes survive a re-seed.

If port `5432` is already taken, change the host side of the `ports` mapping.

# Queries and functions

Proposed queries and functions shall be put in `queries/` and `functions/` respectively.
The file naming scheme is `q<number>_<short description>.sql` (numbers 1 to 20) for queries and `f<number>_<short description>.sql` (numbers 1 to 5) for functions.

## Running functions

Every function is mounted into the container's init directory by a volume in
`docker-compose.yml`. To add a new one, append a line to `volumes` and give it
the next free index:

```
      - ./functions/<file>:/docker-entrypoint-initdb.d/<index>-function.sql:ro
```

Because init scripts only run when the data volume is created, a function
added later is **not** picked up by restarting the container (`docker compose
restart` / `up -d` are enough only the first time). Either load it manually
into the running database:

```sh
docker compose exec -T db psql -U catering -d catering \
  -v ON_ERROR_STOP=1 < functions/f1_meals_without_allergens.pgsql
```

or recreate the volume with `docker compose down -v && docker compose up -d`,
which drops all data, so run the seeder afterwards.

Re-seeding does not remove functions — it only truncates data.

Inside the container the mounted files are renamed to `<index>-function.sql`,
so an already mounted function can be reloaded from an interactive session:

```sh
docker compose exec db psql -U catering -d catering
# \i /docker-entrypoint-initdb.d/02-function.sql
```

Note that a function's SQL name need not match its filename:
`f1_meals_without_allergens.pgsql` creates `find_meals_without_allergens`.
Check the definition before calling it.

Test a function (this also works with `EXPLAIN`; for the inner query plan use
`auto_explain` with `auto_explain.log_nested_statements = on`, since a plain
`EXPLAIN` on a function call only shows a `Function Scan`):

```sh
docker compose exec db psql -U catering -d catering -c \
  "SELECT * FROM find_meals_without_allergens(ARRAY['Jaja','Soja']::VARCHAR[]);"
```