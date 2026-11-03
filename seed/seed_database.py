#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "faker>=37",
#     "psycopg[binary]>=3.2",
# ]
# ///
"""Fill the PostgreSQL schema with plausible demo data.

Static reference data lives in seed/resources/. PostgreSQL assigns every id;
the script reads them back with RETURNING to wire foreign keys. Each run
produces different data unless SEED is set.

    uv run seed/seed_database.py
    DATABASE_URL=postgresql://user:pass@localhost:5432/db uv run seed/seed_database.py
    SEED=42 uv run seed/seed_database.py
"""

from __future__ import annotations

import csv
import hashlib
import os
import random
from collections import defaultdict
from datetime import datetime, time, timedelta
from decimal import Decimal
from pathlib import Path

import psycopg
from faker import Faker

ROOT = Path(__file__).resolve().parent
RESOURCES = ROOT / "resources"
SCHEMA = ROOT.parent / "pg" / "createdb.sql"

DEMO_PASSWORD = "Zaq12wsx!"
SALT = "0123456789abcdef0123456789abcdef"
POSTAL_COUNT = 350
COMPANY_COUNT = 40
MEAL_COUNT = 400
USER_COUNT = 4000
ORDER_COUNT = 12_000
REVIEW_COUNT = 4_500
COMPLAINT_COUNT = 1_200

NOW = datetime.now()
TODAY = NOW.date()

fake = Faker("pl_PL")
if seed := os.getenv("SEED"):
    random.seed(int(seed))
    Faker.seed(int(seed))


def load(name: str) -> list[dict]:
    with open(RESOURCES / name, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


PERMISSIONS = load("permissions.csv")
MEALTIMES = load("mealtimes.csv")
ALLERGENS = load("allergens.csv")
INGREDIENTS = load("ingredients.csv")
MEAL_STYLES = load("meal_styles.csv")
DIETS = load("diets.csv")
POSTAL_CODES = load("postal_codes.csv")[:POSTAL_COUNT]
WINDOW_TIMES = [(time.fromisoformat(r["start"]), time.fromisoformat(r["end"]))
                for r in load("delivery_windows.csv")]
CALORIES = [int(r["calories"]) for r in load("calorie_variants.csv")]
COMPLAINT_SUBJECTS = [r["subject"] for r in load("complaint_subjects.csv")]

INGREDIENTS_BY_CATEGORY = defaultdict(list)
for ingredient in INGREDIENTS:
    INGREDIENTS_BY_CATEGORY[ingredient["category"]].append(ingredient["name"])

PASSWORD_HASH = (f"pbkdf2_sha256$100000${SALT}$"
                 f"{hashlib.pbkdf2_hmac('sha256', DEMO_PASSWORD.encode(), SALT.encode(), 100_000).hex()}")


def insert(cur, table: str, columns: list[str], rows: list[tuple], returning: bool = False) -> list[int]:
    if not rows:
        return []
    placeholders = ", ".join(["%s"] * len(columns))
    sql = f'INSERT INTO "{table}" ({", ".join(columns)}) VALUES ({placeholders})'
    if not returning:
        cur.executemany(sql, rows)
        return []
    cur.executemany(sql + " RETURNING id", rows, returning=True)
    return [result.fetchone()[0] for result in cur.results()]


def one(cur, table: str, columns: list[str], row: tuple) -> int:
    return insert(cur, table, columns, [row], True)[0]


def digits(length: int) -> str:
    return "".join(random.choices("0123456789", k=length))


def unique_phone(used: set[str]) -> str:
    while True:
        value = "+48" + digits(9)
        if value not in used:
            used.add(value)
            return value


def seed() -> None:
    dsn = os.getenv("DATABASE_URL", "postgresql://catering:catering@localhost:5432/catering")
    with psycopg.connect(dsn) as conn, conn.cursor() as cur:
        cur.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")
        cur.execute(SCHEMA.read_text(encoding="utf-8"))

        permission_ids = dict(zip(
            [p["code"] for p in PERMISSIONS],
            insert(cur, "Permission", ["code", "name", "description"],
                   [(p["code"], p["name"], p["description"]) for p in PERMISSIONS], True),
        ))

        mealtime_ids = insert(cur, "Mealtime", ["name", "display_order"],
                              [(m["name"], int(m["display_order"])) for m in MEALTIMES], True)
        mealtime_by_name = {m["name"]: mid for m, mid in zip(MEALTIMES, mealtime_ids)}

        allergen_ids = insert(cur, "Allergen", ["name", "description"],
                              [(a["name"], a["description"]) for a in ALLERGENS], True)

        ingredient_ids = dict(zip(
            [i["name"] for i in INGREDIENTS],
            insert(cur, "Ingredient", ["name"], [(i["name"],) for i in INGREDIENTS], True),
        ))

        postal_ids = insert(cur, "PostalCode", ["code"],
                            [(p["code"],) for p in POSTAL_CODES], True)
        postal = [{"id": pid, "city": p["city"]}
                  for p, pid in zip(POSTAL_CODES, postal_ids)]

        # companies and their offerings
        phones: set[str] = set()
        company_rows = []
        for _ in range(COMPANY_COUNT):
            company_rows.append((
                fake.unique.company() + " Catering", digits(10), digits(random.choice([9, 14])),
                fake.paragraph(nb_sentences=3), fake.company_email(), unique_phone(phones),
                random.choices(["VERIFIED", "PENDING", "REJECTED"], weights=[85, 10, 5])[0],
                fake.date_time_between(start_date="-3y", end_date="-90d"),
            ))
        company_ids = insert(cur, "CateringCompany",
                             ["name", "nip", "regon", "description", "contact_email",
                              "contact_phone", "verification_status", "created_at"],
                             company_rows, True)
        companies = [{"id": cid, "status": row[6]}
                     for row, cid in zip(company_rows, company_ids)]
        verified = [c for c in companies if c["status"] == "VERIFIED"] or companies

        coverage_rows = []
        postal_companies = defaultdict(list)
        for company in verified:
            for record in random.sample(postal, k=random.randint(30, 80)):
                coverage_rows.append((company["id"], record["id"]))
                postal_companies[record["id"]].append(company["id"])
        insert(cur, "CateringCompanyPostalCode",
               ["catering_company_id", "postal_code_id"], coverage_rows)

        window_rows = [(c["id"], start, end) for c in verified for start, end in WINDOW_TIMES]
        window_ids = insert(cur, "DeliveryWindow",
                            ["catering_company_id", "start_time", "end_time"], window_rows, True)
        company_windows = defaultdict(list)
        window_by_id = {}
        for row, window_id in zip(window_rows, window_ids):
            company_windows[row[0]].append(window_id)
            window_by_id[window_id] = (row[1], row[2])

        diet_rows = []
        for company in verified:
            for index, template in enumerate(random.sample(DIETS, k=random.randint(3, 5))):
                diet_rows.append((company["id"], template["name"], template["description"],
                                  index == 0 or random.random() < 0.9))
        diet_ids = insert(cur, "Diet", ["catering_company_id", "name", "description", "is_active"],
                          diet_rows, True)
        diets = [{"id": did, "company_id": row[0], "active": row[3]}
                 for row, did in zip(diet_rows, diet_ids)]

        variant_rows, variant_meta = [], []
        for diet in diets:
            for calories in CALORIES:
                price = Decimal(str(round(random.uniform(55, 110), 2)))
                variant_rows.append((diet["id"], calories, price))
                variant_meta.append((diet, price))
        variant_ids = insert(cur, "CaloricVariant", ["diet_id", "calories", "base_price_per_day"],
                             variant_rows, True)

        variant_mealtime_rows = []
        company_variants = defaultdict(list)
        for (diet, price), variant_id in zip(variant_meta, variant_ids):
            mealtimes = random.sample(mealtime_ids, k=random.randint(4, 5))
            variant_mealtime_rows += [(variant_id, mealtime_id) for mealtime_id in mealtimes]
            if diet["active"]:
                company_variants[diet["company_id"]].append(
                    {"id": variant_id, "price": price, "mealtimes": mealtimes})
        insert(cur, "CaloricVariantMealtime", ["caloric_variant_id", "mealtime_id"],
               variant_mealtime_rows)

        # meals: plausible names, random macros and allergens
        meal_names: set[str] = set()
        meal_rows, meal_meta = [], []
        meals_per_mealtime = MEAL_COUNT // len(MEALTIMES)
        for mealtime in MEALTIMES:
            styles = [s for s in MEAL_STYLES if s["mealtime"] == mealtime["name"]]
            for _ in range(meals_per_mealtime):
                while True:
                    style = random.choice(styles)
                    chosen = []
                    for category in style["categories"].split(";"):
                        options = [name for name in INGREDIENTS_BY_CATEGORY[category]
                                   if name not in chosen]
                        chosen.append(random.choice(options))
                    name = f'{style["style"]}: ' + ", ".join(chosen[:-1]) + f" i {chosen[-1]}"
                    if name not in meal_names:
                        meal_names.add(name)
                        break
                protein = round(random.uniform(8, 45), 1)
                fat = round(random.uniform(5, 35), 1)
                carbs = round(random.uniform(10, 75), 1)
                meal_rows.append((
                    name, fake.sentence(nb_words=10), random.randint(220, 520),
                    round(protein * 4 + carbs * 4 + fat * 9), protein, fat, carbs,
                    round(random.uniform(2, 12), 1), round(random.uniform(0.2, 2.5), 2),
                ))
                meal_meta.append({
                    "mealtime_id": mealtime_by_name[mealtime["name"]],
                    "ingredients": chosen,
                    "allergens": random.sample(allergen_ids, k=random.randint(0, 3)),
                })
        meal_ids = insert(cur, "Meal",
                          ["name", "description", "weight_grams", "calories_kcal", "protein_g",
                           "fat_g", "carbs_g", "fiber_g", "salt_g"], meal_rows, True)
        meal_mealtime_rows, meal_ingredient_rows, meal_allergen_rows = [], [], []
        meals_by_mealtime = defaultdict(list)
        for meta, meal_id in zip(meal_meta, meal_ids):
            meal_mealtime_rows.append((meal_id, meta["mealtime_id"]))
            meal_ingredient_rows += [(meal_id, ingredient_ids[name]) for name in meta["ingredients"]]
            meal_allergen_rows += [(meal_id, allergen_id) for allergen_id in meta["allergens"]]
            meals_by_mealtime[meta["mealtime_id"]].append(meal_id)
        insert(cur, "MealMealtime", ["meal_id", "mealtime_id"], meal_mealtime_rows)
        insert(cur, "MealIngredient", ["meal_id", "ingredient_id"], meal_ingredient_rows)
        insert(cur, "MealAllergen", ["meal_id", "allergen_id"], meal_allergen_rows)

        # users, permissions, addresses, billing data
        role_plan = [("ADMIN", None)] + [("MODERATOR", None)] * 10
        role_plan += [(random.choice(["COMPANY_OWNER", "COMPANY_STAFF", "COURIER"]),
                       random.choice(verified)) for _ in range(60)]
        role_plan += [("CLIENT", None)] * (USER_COUNT - len(role_plan))

        user_rows, user_meta = [], []
        for role, company in role_plan:
            first, last = fake.first_name(), fake.last_name()
            archived = role == "CLIENT" and random.random() < 0.03
            user_rows.append((
                company["id"] if company else None, fake.unique.email(), PASSWORD_HASH,
                unique_phone(phones), first, last, archived,
                fake.date_time_between(start_date="-3y", end_date="-30d"),
            ))
            user_meta.append({"role": role, "first_name": first, "last_name": last,
                              "archived": archived})
        user_ids = insert(cur, "User",
                          ["catering_company_id", "email", "password_hash", "phone_number",
                           "first_name", "last_name", "archived", "created_at"],
                          user_rows, True)
        users = [{"id": uid, **meta} for meta, uid in zip(user_meta, user_ids)]

        role_permissions = {
            "ADMIN": list(permission_ids),
            "MODERATOR": ["MODERATOR"],
            "COMPANY_OWNER": ["COMPANY_OWNER", "COMPANY_STAFF"],
            "COMPANY_STAFF": ["COMPANY_STAFF"],
            "COURIER": ["COURIER"],
            "CLIENT": ["CLIENT"],
        }
        insert(cur, "UserPermission", ["user_id", "permission_id"],
               [(u["id"], permission_ids[code])
                for u in users for code in role_permissions[u["role"]]])

        address_rows, address_meta = [], []
        for user in users:
            for index in range(random.randint(1, 2)):
                record = random.choice(postal)
                address_rows.append((
                    record["id"], record["city"], fake.street_name(),
                    str(random.randint(1, 150)),
                    str(random.randint(1, 80)) if random.random() < 0.7 else None,
                    str(random.randint(0, 10)) if random.random() < 0.7 else None,
                ))
                address_meta.append((user["id"], index))
        address_ids = insert(cur, "DeliveryAddress",
                             ["postal_code_id", "city", "street", "building_number",
                              "apartment_number", "floor"], address_rows, True)
        user_addresses = defaultdict(list)
        address_postal = {}
        user_address_rows = []
        for (user_id, index), row, address_id in zip(address_meta, address_rows, address_ids):
            user_addresses[user_id].append(address_id)
            address_postal[address_id] = row[0]
            user_address_rows.append((user_id, address_id,
                                      "Dom" if index == 0 else "Praca", index == 0))
        insert(cur, "UserDeliveryAddress",
               ["user_id", "delivery_address_id", "label", "is_default"], user_address_rows)

        billing_rows, billing_types = [], []
        for user in users:
            record = random.choice(postal)
            private = random.random() < 0.75
            billing_rows.append((
                user["id"], record["id"], "PRIVATE" if private else "COMPANY",
                None if private else fake.company(), None if private else digits(10),
                user["first_name"] if private else None,
                user["last_name"] if private else None,
                record["city"], fake.street_name(), str(random.randint(1, 120)), None,
            ))
            billing_types.append("PRIVATE" if private else "COMPANY")
        billing_ids = insert(cur, "BillingData",
                             ["user_id", "postal_code_id", "buyer_type", "company_name", "nip",
                              "first_name", "last_name", "city", "street", "building_number",
                              "apartment_number"], billing_rows, True)
        user_billing = {u["id"]: (bid, buyer)
                        for u, bid, buyer in zip(users, billing_ids, billing_types)}

        # orders, deliveries, daily plans, billing
        order_users = [u for u in users if u["role"] == "CLIENT" and not u["archived"]]
        if not order_users:
            order_users = [u for u in users if u["role"] == "CLIENT"]
        reviewable, complainable = [], []
        document_counter = 0

        for _ in range(ORDER_COUNT):
            user = random.choice(order_users)
            address_id = random.choice(user_addresses[user["id"]])
            company_id = random.choice(postal_companies.get(address_postal[address_id])
                                       or [c["id"] for c in verified])
            window_id = random.choice(company_windows[company_id])
            variant = random.choice(company_variants[company_id])

            created = fake.date_time_between(start_date="-2y", end_date="-1h")
            days = random.randint(5, 14)
            start = created.date() + timedelta(days=2)
            end = start + timedelta(days=days - 1)
            if random.random() < 0.05:
                status = "CANCELLED"
            elif end < TODAY:
                status = "COMPLETED"
            elif start > TODAY:
                status = "NEW" if (NOW - created).total_seconds() < 43_200 else "CONFIRMED"
            else:
                status = random.choice(["IN_PROGRESS", "PAID"])

            order_id = one(cur, "Order",
                           ["user_id", "delivery_address_id", "delivery_window_id",
                            "status", "created_at"],
                           (user["id"], address_id, window_id, status, created))

            delivery_info = {}
            if status != "NEW":
                delivery_rows = []
                for offset in range(days):
                    day = start + timedelta(days=offset)
                    delivered_at = None
                    if status == "CANCELLED":
                        delivery_status = "CANCELLED"
                    elif day < TODAY:
                        delivery_status = random.choices(["DELIVERED", "FAILED"],
                                                         weights=[97, 3])[0]
                    elif day > TODAY:
                        delivery_status = "PLANNED"
                    else:
                        delivery_status = random.choice(["PLANNED", "IN_TRANSIT"])
                    if delivery_status == "DELIVERED":
                        window_start, window_end = window_by_id[window_id]
                        minutes = ((window_end.hour * 60 + window_end.minute)
                                   - (window_start.hour * 60 + window_start.minute))
                        delivered_at = datetime.combine(day, window_start) + timedelta(
                            minutes=random.randrange(minutes))
                    delivery_rows.append((order_id, day, delivered_at, delivery_status))
                delivery_ids = insert(cur, "Delivery",
                                      ["order_id", "scheduled_date", "delivered_at", "status"],
                                      delivery_rows, True)
                for row, delivery_id in zip(delivery_rows, delivery_ids):
                    delivery_info[row[1]] = (delivery_id, row[2], row[3])

            item_rows, item_variants = [], []
            for index in range(random.choices([1, 2], weights=[70, 30])[0]):
                item_variant = random.choice(company_variants[company_id])
                quantity = random.choices([1, 2], weights=[85, 15])[0]
                recipient = (f'{user["first_name"]} {user["last_name"]}' if index == 0
                             else f"{fake.first_name()} {fake.last_name()}")
                item_rows.append((order_id, item_variant["id"], recipient,
                                  quantity, item_variant["price"]))
                item_variants.append(item_variant)
            item_ids = insert(cur, "OrderItem",
                              ["order_id", "caloric_variant_id", "recipient", "quantity",
                               "daily_price_snapshot"], item_rows, True)

            if status not in ("NEW", "CANCELLED"):
                plan_specs = []
                for item_id, item_variant in zip(item_ids, item_variants):
                    for offset in range(days):
                        day = start + timedelta(days=offset)
                        locked_at = max(
                            datetime.combine(day - timedelta(days=1), time(18, 0)),
                            created + timedelta(minutes=5))
                        meals = [(mealtime_id, random.choice(meals_by_mealtime[mealtime_id]))
                                 for mealtime_id in item_variant["mealtimes"]]
                        plan_specs.append((item_id, day, locked_at, meals))
                plan_ids = insert(cur, "DailyPlan", ["order_item_id", "date", "locked_at"],
                                  [(item_id, day, locked_at)
                                   for item_id, day, locked_at, _ in plan_specs], True)
                plan_item_rows, delivery_plan_rows = [], []
                for (item_id, day, locked_at, meals), plan_id in zip(plan_specs, plan_ids):
                    delivery_plan_rows.append((delivery_info[day][0], plan_id))
                    plan_item_rows += [(plan_id, mt, meal) for mt, meal in meals]
                insert(cur, "PlanItem", ["daily_plan_id", "mealtime_id", "meal_id"],
                       plan_item_rows)
                insert(cur, "DeliveryDailyPlan", ["delivery_id", "daily_plan_id"],
                       delivery_plan_rows)

            if status in ("CONFIRMED", "PAID", "IN_PROGRESS", "COMPLETED"):
                amount = sum((price * quantity * days
                              for _, _, _, quantity, price in item_rows), Decimal("0"))
                document_counter += 1
                billing_data_id, buyer_type = user_billing[user["id"]]
                document_type = "INVOICE" if buyer_type == "COMPANY" else "RECEIPT"
                prefix = "FV" if document_type == "INVOICE" else "PAR"
                paid_at = (created + timedelta(minutes=random.randint(5, 60))
                           if status in ("PAID", "IN_PROGRESS", "COMPLETED") else None)
                one(cur, "Billing",
                    ["order_id", "billing_data_id", "document_type", "document_number",
                     "amount", "paid_at"],
                    (order_id, billing_data_id, document_type,
                     f"{prefix}/{created.year}/{document_counter:06d}", amount, paid_at))

            for day, (delivery_id, delivered_at, delivery_status) in delivery_info.items():
                if delivery_status == "DELIVERED":
                    reviewable.append((delivery_id, order_id, user["id"], company_id, delivered_at))
                if delivery_status in ("DELIVERED", "FAILED"):
                    reference = delivered_at or datetime.combine(
                        day, window_by_id[window_id][0])
                    complainable.append((delivery_id, order_id, user["id"], reference))

        # reviews, moderation logs, complaints
        review_rows = []
        for delivery_id, order_id, user_id, company_id, delivered_at in random.sample(
                reviewable, k=min(REVIEW_COUNT, len(reviewable))):
            if delivered_at > NOW - timedelta(hours=2):
                continue
            review_time = delivered_at + timedelta(hours=random.randint(2, 168))
            if review_time > NOW - timedelta(hours=1):
                review_time = NOW - timedelta(hours=random.randint(1, 3))
            if review_time <= delivered_at:
                continue
            review_rows.append((
                user_id, company_id, delivery_id,
                random.choice(meal_ids) if random.random() < 0.7 else None,
                random.choices([5, 4, 3, 2, 1], weights=[45, 30, 12, 8, 5])[0],
                fake.sentence(nb_words=12) if random.random() < 0.85 else None,
                random.choices(["VISIBLE", "PENDING", "HIDDEN"], weights=[80, 10, 10])[0],
                review_time,
            ))
        review_ids = insert(cur, "Review",
                            ["user_id", "catering_company_id", "delivery_id", "meal_id",
                             "rating", "comment", "moderation_status", "created_at"],
                            review_rows, True)

        moderator_ids = [u["id"] for u in users if u["role"] == "MODERATOR"]
        log_rows = []
        for row, review_id in zip(review_rows, review_ids):
            moderation, review_time = row[6], row[7]
            if moderation == "HIDDEN" or (moderation == "VISIBLE" and random.random() < 0.2):
                log_time = review_time + timedelta(hours=random.randint(1, 24))
                if log_time > NOW - timedelta(minutes=5):
                    log_time = NOW - timedelta(minutes=random.randint(1, 30))
                if log_time > review_time:
                    log_rows.append((review_id, random.choice(moderator_ids),
                                     fake.sentence(nb_words=8), log_time))
        insert(cur, "ModerationLog", ["review_id", "user_id", "moderation_note", "created_at"],
               log_rows)

        complaint_rows = []
        for delivery_id, order_id, user_id, reference in random.sample(
                complainable, k=min(COMPLAINT_COUNT, len(complainable))):
            if reference > NOW - timedelta(hours=2):
                continue
            complaint_time = reference + timedelta(hours=random.randint(2, 72))
            if complaint_time > NOW - timedelta(hours=1):
                complaint_time = NOW - timedelta(hours=random.randint(1, 2))
            if complaint_time <= reference:
                continue
            status = random.choices(["RESOLVED", "REJECTED", "IN_PROGRESS", "OPEN"],
                                    weights=[50, 15, 20, 15])[0]
            closed = status in ("RESOLVED", "REJECTED")
            resolved_at = None
            if closed:
                resolved_at = min(complaint_time + timedelta(days=random.randint(1, 3)),
                                  NOW - timedelta(minutes=5))
                if resolved_at <= complaint_time:
                    resolved_at = complaint_time + timedelta(minutes=1)
            complaint_rows.append((
                user_id, order_id, delivery_id, random.choice(COMPLAINT_SUBJECTS),
                fake.paragraph(nb_sentences=2), status,
                fake.sentence(nb_words=10) if closed else None, complaint_time, resolved_at,
            ))
        insert(cur, "Complaint",
               ["user_id", "order_id", "delivery_id", "subject", "description", "status",
                "decision_justification", "created_at", "resolved_at"], complaint_rows)

        cur.execute("SELECT table_name FROM information_schema.tables "
                    "WHERE table_schema = 'public' ORDER BY table_name")
        total = 0
        print("\nSeeded rows:")
        for (table,) in cur.fetchall():
            cur.execute(f'SELECT count(*) FROM "{table}"')
            count = cur.fetchone()[0]
            total += count
            print(f"  {table:<30} {count:>9,}")
        print(f"  {'TOTAL':<30} {total:>9,}")
        print(f"\nDemo password for every account: {DEMO_PASSWORD}")


if __name__ == "__main__":
    seed()
