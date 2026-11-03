# Seed data

Requires [uv](https://docs.astral.sh/uv/) and the database from `../pg/`
running. Dependencies are declared inline in `seed_database.py` (PEP 723), so
there is nothing to install manually.

## Run

From this directory (or `uv run seed/seed_database.py` from the repo root):

```sh
uv run seed_database.py
```

The script drops and recreates the schema, then fills it with fresh random
data. It reads `DATABASE_URL` if set and otherwise uses the Compose default:

```
postgresql://catering:catering@localhost:5432/catering
```

Set `SEED=42` to make a run reproducible. Every seeded account uses the demo
password `Zaq12wsx!`.

Reference data (ingredients, allergens, diets, postal codes, etc.) lives in
`resources/`.
