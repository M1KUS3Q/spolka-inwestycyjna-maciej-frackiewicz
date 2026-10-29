import os
import re
import random
from datetime import datetime, date, time, timedelta
from decimal import Decimal

from faker import Faker
from sqlalchemy import (
    create_engine, Column, Integer, String, Text, Boolean,
    Date, Time, DateTime, Numeric, ForeignKey, CheckConstraint,
    UniqueConstraint, event, text
)
from sqlalchemy.orm import declarative_base, sessionmaker

SEED_VALUE = 42
random.seed(SEED_VALUE)
Faker.seed(SEED_VALUE)

fake = Faker("pl_PL")

fake.seed_instance(SEED_VALUE)

DB_FILENAME = "catering.db"
SQL_FILENAME = "createdb.sql"

CONFIG = {
    "NUM_POSTAL_CODES": 350,
    "NUM_COMPANIES": 40,
    "NUM_MEALS": 400,
    "NUM_USERS": 4000,          # 4 tysiące klientów
    "NUM_ORDERS": 12000,        # 12 tysięcy zamówień na przestrzeni 2 lat
    "DAYS_PER_ORDER_MIN": 5,    # krótsze zamówienia testowe
    "DAYS_PER_ORDER_MAX": 14,   # dłuższe plany abonamentowe
    "NUM_REVIEWS": 4500,        # spora baza opinii
    "NUM_COMPLAINTS": 1200,     # ok. 10% zamówień ma jakieś zgłoszenie
}

Base = declarative_base()

# 1. MODELE ORM (SQLAlchemy)

class PostalCode(Base):
    __tablename__ = "PostalCode"
    id = Column(Integer, primary_key=True)
    code = Column(String(6), nullable=False, unique=True)
    __table_args__ = (
        CheckConstraint("code GLOB '[0-9][0-9]-[0-9][0-9][0-9]'", name="chk_postal_code"),
    )


class CateringCompany(Base):
    __tablename__ = "CateringCompany"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    nip = Column(String(10), nullable=False, unique=True)
    regon = Column(String(14), nullable=False, unique=True)
    description = Column(Text, nullable=True)
    contact_email = Column(String, nullable=False)
    contact_phone = Column(String, nullable=False)
    verification_status = Column(String, nullable=False, default="PENDING")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Permission(Base):
    __tablename__ = "Permission"
    id = Column(Integer, primary_key=True)
    code = Column(String, nullable=False, unique=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)


class Mealtime(Base):
    __tablename__ = "Mealtime"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    display_order = Column(Integer, nullable=False, unique=True)


class Meal(Base):
    __tablename__ = "Meal"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    description = Column(Text, nullable=False)
    weight_grams = Column(Integer, nullable=False)
    calories_kcal = Column(Integer, nullable=False)
    protein_g = Column(Numeric(6, 2), nullable=False)
    fat_g = Column(Numeric(6, 2), nullable=False)
    carbs_g = Column(Numeric(6, 2), nullable=False)
    fiber_g = Column(Numeric(6, 2), nullable=False)
    salt_g = Column(Numeric(6, 2), nullable=False)


class Ingredient(Base):
    __tablename__ = "Ingredient"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)


class Allergen(Base):
    __tablename__ = "Allergen"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False, unique=True)
    description = Column(String, nullable=True)


class User(Base):
    __tablename__ = "User"
    id = Column(Integer, primary_key=True)
    catering_company_id = Column(Integer, ForeignKey("CateringCompany.id", onupdate="CASCADE", ondelete="SET NULL"), nullable=True)
    email = Column(String, nullable=False, unique=True)
    password_hash = Column(String, nullable=False)
    phone_number = Column(String, nullable=False, unique=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    archived = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class UserPermission(Base):
    __tablename__ = "UserPermission"
    user_id = Column(Integer, ForeignKey("User.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    permission_id = Column(Integer, ForeignKey("Permission.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)


class DeliveryAddress(Base):
    __tablename__ = "DeliveryAddress"
    id = Column(Integer, primary_key=True)
    postal_code_id = Column(Integer, ForeignKey("PostalCode.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    city = Column(String, nullable=False)
    street = Column(String, nullable=False)
    building_number = Column(String, nullable=False)
    apartment_number = Column(String, nullable=True)
    floor = Column(String, nullable=True)


class UserDeliveryAddress(Base):
    __tablename__ = "UserDeliveryAddress"
    user_id = Column(Integer, ForeignKey("User.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    delivery_address_id = Column(Integer, ForeignKey("DeliveryAddress.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    label = Column(String, nullable=False)
    is_default = Column(Boolean, nullable=False, default=False)


class BillingData(Base):
    __tablename__ = "BillingData"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("User.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    postal_code_id = Column(Integer, ForeignKey("PostalCode.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    buyer_type = Column(String, nullable=False)
    company_name = Column(String, nullable=True)
    nip = Column(String(10), nullable=True)
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    city = Column(String, nullable=False)
    street = Column(String, nullable=False)
    building_number = Column(String, nullable=False)
    apartment_number = Column(String, nullable=True)


class CateringCompanyPostalCode(Base):
    __tablename__ = "CateringCompanyPostalCode"
    catering_company_id = Column(Integer, ForeignKey("CateringCompany.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    postal_code_id = Column(Integer, ForeignKey("PostalCode.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)


class DeliveryWindow(Base):
    __tablename__ = "DeliveryWindow"
    id = Column(Integer, primary_key=True)
    catering_company_id = Column(Integer, ForeignKey("CateringCompany.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)


class Diet(Base):
    __tablename__ = "Diet"
    id = Column(Integer, primary_key=True)
    catering_company_id = Column(Integer, ForeignKey("CateringCompany.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)


class CaloricVariant(Base):
    __tablename__ = "CaloricVariant"
    id = Column(Integer, primary_key=True)
    diet_id = Column(Integer, ForeignKey("Diet.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    calories = Column(Integer, nullable=False)
    base_price_per_day = Column(Numeric(8, 2), nullable=False)


class CaloricVariantMealtime(Base):
    __tablename__ = "CaloricVariantMealtime"
    caloric_variant_id = Column(Integer, ForeignKey("CaloricVariant.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    mealtime_id = Column(Integer, ForeignKey("Mealtime.id", onupdate="CASCADE", ondelete="RESTRICT"), primary_key=True)


class MealMealtime(Base):
    __tablename__ = "MealMealtime"
    meal_id = Column(Integer, ForeignKey("Meal.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    mealtime_id = Column(Integer, ForeignKey("Mealtime.id", onupdate="CASCADE", ondelete="RESTRICT"), primary_key=True)


class MealIngredient(Base):
    __tablename__ = "MealIngredient"
    meal_id = Column(Integer, ForeignKey("Meal.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    ingredient_id = Column(Integer, ForeignKey("Ingredient.id", onupdate="CASCADE", ondelete="RESTRICT"), primary_key=True)


class MealAllergen(Base):
    __tablename__ = "MealAllergen"
    meal_id = Column(Integer, ForeignKey("Meal.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    allergen_id = Column(Integer, ForeignKey("Allergen.id", onupdate="CASCADE", ondelete="RESTRICT"), primary_key=True)


class Order(Base):
    __tablename__ = "Order"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("User.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    delivery_address_id = Column(Integer, ForeignKey("DeliveryAddress.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    delivery_window_id = Column(Integer, ForeignKey("DeliveryWindow.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    status = Column(String, nullable=False, default="NEW")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class OrderItem(Base):
    __tablename__ = "OrderItem"
    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey("Order.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    caloric_variant_id = Column(Integer, ForeignKey("CaloricVariant.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    recipient = Column(String, nullable=False)
    quantity = Column(Integer, nullable=False, default=1)
    daily_price_snapshot = Column(Numeric(8, 2), nullable=False)


class DailyPlan(Base):
    __tablename__ = "DailyPlan"
    id = Column(Integer, primary_key=True)
    order_item_id = Column(Integer, ForeignKey("OrderItem.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    date = Column(Date, nullable=False)
    locked_at = Column(DateTime, nullable=False)


class PlanItem(Base):
    __tablename__ = "PlanItem"
    daily_plan_id = Column(Integer, ForeignKey("DailyPlan.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    mealtime_id = Column(Integer, ForeignKey("Mealtime.id", onupdate="CASCADE", ondelete="RESTRICT"), primary_key=True)
    meal_id = Column(Integer, ForeignKey("Meal.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)


class Delivery(Base):
    __tablename__ = "Delivery"
    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey("Order.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    scheduled_date = Column(Date, nullable=False)
    delivered_at = Column(DateTime, nullable=True)
    status = Column(String, nullable=False, default="PLANNED")


class DeliveryDailyPlan(Base):
    __tablename__ = "DeliveryDailyPlan"
    delivery_id = Column(Integer, ForeignKey("Delivery.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)
    daily_plan_id = Column(Integer, ForeignKey("DailyPlan.id", onupdate="CASCADE", ondelete="CASCADE"), primary_key=True)


class Billing(Base):
    __tablename__ = "Billing"
    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey("Order.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False, unique=True)
    billing_data_id = Column(Integer, ForeignKey("BillingData.id", onupdate="CASCADE", ondelete="SET NULL"), nullable=True)
    document_type = Column(String, nullable=False)
    document_number = Column(String, nullable=True, unique=True)
    amount = Column(Numeric(10, 2), nullable=False)
    paid_at = Column(DateTime, nullable=True)


class Review(Base):
    __tablename__ = "Review"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("User.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    catering_company_id = Column(Integer, ForeignKey("CateringCompany.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    delivery_id = Column(Integer, ForeignKey("Delivery.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False)
    meal_id = Column(Integer, ForeignKey("Meal.id", onupdate="CASCADE", ondelete="SET NULL"), nullable=True)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    moderation_status = Column(String, nullable=False, default="VISIBLE")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class ModerationLog(Base):
    __tablename__ = "ModerationLog"
    id = Column(Integer, primary_key=True)
    review_id = Column(Integer, ForeignKey("Review.id", onupdate="CASCADE", ondelete="CASCADE"), nullable=False, unique=True)
    user_id = Column(Integer, ForeignKey("User.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    moderation_note = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Complaint(Base):
    __tablename__ = "Complaint"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("User.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    order_id = Column(Integer, ForeignKey("Order.id", onupdate="CASCADE", ondelete="RESTRICT"), nullable=False)
    delivery_id = Column(Integer, ForeignKey("Delivery.id", onupdate="CASCADE", ondelete="SET NULL"), nullable=True, unique=True)
    subject = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String, nullable=False, default="OPEN")
    decision_justification = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)


# 2. INICJALIZACJA BAZY Z PLIKU SQL

def init_db_from_sql(engine, sql_path: str):
    """Tworzy strukturę bazy danych z pliku createdb.sql (dostosowując CREATE DOMAIN do SQLite)."""
    if os.path.exists(sql_path):
        with open(sql_path, "r", encoding="utf-8") as f:
            sql_script = f.read()

        # SQLite nie wspiera CREATE DOMAIN - zamieniamy na bezpośredni CHECK w tabeli PostalCode
        sql_script = re.sub(
            r"CREATE\s+DOMAIN\s+postal_code\s+AS\s+CHAR\(6\)\s+CHECK\s*\(\s*VALUE\s+GLOB\s+'\[0-9\]\[0-9\]-\[0-9\]\[0-9\]\[0-9\]'\s*\)\s*;",
            "",
            sql_script,
            flags=re.IGNORECASE,
        )
        sql_script = sql_script.replace(
            "code postal_code NOT NULL UNIQUE",
            "code CHAR(6) NOT NULL UNIQUE CHECK (code GLOB '[0-9][0-9]-[0-9][0-9][0-9]')",
        )

        raw_conn = engine.raw_connection()
        try:
            raw_conn.executescript(sql_script)
            raw_conn.commit()
        finally:
            raw_conn.close()
    else:
        Base.metadata.create_all(engine)


# 3. FUNKCJE POMOCNICZE GENERUJĄCE DANE

def generate_unique_values(generator_func, count: int) -> list:
    seen = set()
    values = []
    while len(values) < count:
        val = generator_func()
        if val not in seen:
            seen.add(val)
            values.append(val)
    return values


def random_digits(length: int) -> str:
    return "".join(random.choices("0123456789", k=length))


# 4. GŁÓWNA LOGIKA WYPEŁNIANIA BAZY

def seed_database():
    if os.path.exists(DB_FILENAME):
        os.remove(DB_FILENAME)

    engine = create_engine(f"sqlite:///{DB_FILENAME}", echo=False)

    # Włączenie sprawdzania kluczy obcych w SQLite dla każdego połączenia
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys = ON;")
        cursor.close()

    print("1. Tworzenie schematu bazy danych...")
    init_db_from_sql(engine, SQL_FILENAME)

    Session = sessionmaker(bind=engine)
    session = Session()

    # A. TABELE SŁOWNIKOWE (wprowadzane ręcznie / kontrolowanie)
    print("2. Wypełnianie tabel słownikowych (Permission, Mealtime, Allergen, Ingredient)...")

    permissions_data = [
        ("CLIENT", "Klient", "Składanie zamówień, wybór posiłków i zarządzanie kontem"),
        ("COMPANY_OWNER", "Właściciel cateringu", "Pełne zarządzanie ofertą i konfiguracją firmy cateringowej"),
        ("COMPANY_STAFF", "Pracownik cateringu", "Obsługa zamówień, diet oraz harmonogramu dostaw"),
        ("COURIER", "Kurier", "Realizacja dostaw i zmiana ich statusów"),
        ("MODERATOR", "Moderator", "Moderacja opinii oraz obsługa zgłoszeń reklamacyjnych"),
        ("ADMIN", "Administrator systemu", "Pełne uprawnienia administracyjne w systemie"),
    ]
    permissions = [
        Permission(id=i + 1, code=code, name=name, description=desc)
        for i, (code, name, desc) in enumerate(permissions_data)
    ]
    session.add_all(permissions)

    mealtimes_data = [
        ("Śniadanie", 1),
        ("II Śniadanie", 2),
        ("Obiad", 3),
        ("Podwieczorek", 4),
        ("Kolacja", 5),
    ]
    mealtimes = [
        Mealtime(id=i + 1, name=name, display_order=order)
        for i, (name, order) in enumerate(mealtimes_data)
    ]
    session.add_all(mealtimes)

    allergens_data = [
        ("Gluten", "Zboża zawierające gluten (pszenica, żyto, jęczmień, owies)"),
        ("Skorupiaki", "Kraby, krewetki, homary i produkty pochodne"),
        ("Jaja", "Jaja kurze i produkty pochodne"),
        ("Ryby", "Ryby i produkty rybne"),
        ("Orzeszki ziemne", "Arachidy, masło orzechowe i oleje arachidowe"),
        ("Soja", "Nasiona soi, tofu, sos sojowy"),
        ("Mleko i laktoza", "Mleko krowie, nabiał, serwatka"),
        ("Orzechy", "Migdały, orzechy włoskie, laskowe, nerkowca"),
        ("Seler", "Korzeń i nać selera"),
        ("Gorczyca", "Musztarda i przyprawy z gorczycą"),
        ("Sezam", "Nasiona sezamu, pasta tahini"),
        ("Łubin", "Mąka łubinowa i nasiona łubinu"),
    ]
    allergens = [
        Allergen(id=i + 1, name=name, description=desc)
        for i, (name, desc) in enumerate(allergens_data)
    ]
    session.add_all(allergens)

    ingredients_names = [
        "Pierś z kurczaka", "Filet z indyka", "Łosoś norweski", "Dorsz", "Tofu naturalne",
        "Wołowina", "Ryż basmati", "Ryż brązowy", "Kasza gryczana", "Kasza jaglana",
        "Komosa ryżowa (Quinoa)", "Makaron pełnoziarnisty", "Płatki owsiane", "Brokuły", "Szpinak",
        "Jarmuż", "Pomidory koktajlowe", "Ogórek zielony", "Papryka czerwona", "Cukinia",
        "Bakłażan", "Awokado", "Bataty", "Ziemniaki", "Marchew", "Soczewica czerwona",
        "Ciecierzyca", "Fasola czerwona", "Twaróg chudy", "Jogurt grecki", "Mleko kokosowe",
        "Mozzarella", "Ser feta", "Jaja kurze", "Oliwa z oliwek", "Olej lniany", "Masło orzechowe",
        "Pestki dyni", "Nasiona słonecznika", "Nasiona chia", "Migdały", "Orzechy włoskie",
        "Jagody", "Maliny", "Truskawki", "Banan", "Jabłko", "Mango", "Czosnek", "Imbir",
        "Kurkuma", "Bazylia świeża", "Kolendra", "Miód pszczeli", "Syrop klonowy",
    ]
    ingredients = [
        Ingredient(id=i + 1, name=name)
        for i, name in enumerate(ingredients_names)
    ]
    session.add_all(ingredients)
    session.commit()

    # B. KODY POCZTOWE I FIRMY CATERINGOWE
    print("3. Generowanie kodów pocztowych i firm cateringowych...")

    postal_codes_str = generate_unique_values(
        lambda: f"{random.randint(10, 99)}-{random.randint(100, 999)}",
        CONFIG["NUM_POSTAL_CODES"],
    )
    postal_codes = [
        PostalCode(id=i + 1, code=code)
        for i, code in enumerate(postal_codes_str)
    ]
    session.add_all(postal_codes)

    company_nips = generate_unique_values(lambda: random_digits(10), CONFIG["NUM_COMPANIES"])
    company_regons = generate_unique_values(
        lambda: random_digits(random.choice([9, 14])), CONFIG["NUM_COMPANIES"]
    )

    companies = []
    company_PostalCodes = []
    delivery_windows = []
    diets = []
    caloric_variants = []
    cv_mealtimes = []

    dw_id = 1
    diet_id = 1
    cv_id = 1
    variant_to_company = {}
    variant_to_mealtimes = {}
    company_to_windows = {}

    diet_templates = [
        ("Standard", "Zbilansowana dieta codzienna oparta na pełnowartościowych produktach."),
        ("Sport", "Dieta wysokobiałkowa dla osób aktywnych fizycznie."),
        ("Wege", "Dieta wegetariańska wykluczająca mięso i ryby."),
        ("Keto", "Dieta ketogeniczna o niskiej zawartości węglowodanów."),
        ("Niski IG", "Dieta o niskim indeksie glikemicznym wspierająca gospodarkę cukrową."),
    ]

    company_to_variants = {i + 1: [] for i in range(CONFIG["NUM_COMPANIES"])}
    pc_to_companies = {}

    for i in range(CONFIG["NUM_COMPANIES"]):
        cid = i + 1
        companies.append(
            CateringCompany(
                id=cid,
                name=f"{fake.company()} Catering #{cid}",
                nip=company_nips[i],
                regon=company_regons[i],
                description=fake.paragraph(nb_sentences=3),
                contact_email=f"kontakt{cid}@{fake.free_email_domain()}",
                contact_phone=f"+48{random_digits(9)}",
                verification_status=random.choices(
                    ["VERIFIED", "PENDING", "REJECTED"], weights=[80, 15, 5]
                )[0],
                created_at=fake.date_time_between(start_date="-2y", end_date="-6m"),
            )
        )

        # Obsługiwane kody pocztowe przez firmę
        sampled_pcs = random.sample(postal_codes, k=random.randint(30, 80))
        for pc in sampled_pcs:
            company_PostalCodes.append(
                CateringCompanyPostalCode(catering_company_id=cid, postal_code_id=pc.id)
            )
            pc_to_companies.setdefault(pc.id, []).append(cid)

        # Okna dostaw (start_time < end_time)
        windows_slots = [
            (time(2, 0), time(5, 0)),
            (time(5, 0), time(7, 30)),
            (time(7, 30), time(10, 0)),
        ]
        company_to_windows[cid] = []
        for start_t, end_t in windows_slots:
            delivery_windows.append(
                DeliveryWindow(
                    id=dw_id,
                    catering_company_id=cid,
                    start_time=start_t,
                    end_time=end_t,
                )
            )
            company_to_windows[cid].append(dw_id)
            dw_id += 1

        # Diety i warianty kaloryczne
        for d_name, d_desc in random.sample(diet_templates, k=random.randint(3, 5)):
            diets.append(
                Diet(
                    id=diet_id,
                    catering_company_id=cid,
                    name=d_name,
                    description=d_desc,
                    is_active=True,
                )
            )
            for cal in [1500, 1800, 2000, 2500]:
                price = Decimal(str(round(55.0 + (cal / 100.0) * 1.8 + random.uniform(-5, 8), 2)))
                variant_obj = CaloricVariant(
                    id=cv_id,
                    diet_id=diet_id,
                    calories=cal,
                    base_price_per_day=price,
                )
                caloric_variants.append(variant_obj)
                variant_to_company[cv_id] = cid

                company_to_variants[cid].append(variant_obj)

                # Przypisanie pór posiłków do wariantu (np. 4 lub 5 posiłków dziennie)
                active_mts = [1, 2, 3, 4, 5] if cal >= 1800 else [1, 3, 4, 5]
                variant_to_mealtimes[cv_id] = active_mts
                for mt_id in active_mts:
                    cv_mealtimes.append(
                        CaloricVariantMealtime(caloric_variant_id=cv_id, mealtime_id=mt_id)
                    )
                cv_id += 1
            diet_id += 1

    session.add_all(companies)
    session.flush()

    session.add_all(company_PostalCodes)
    session.add_all(delivery_windows)
    session.add_all(diets)
    session.flush()

    session.add_all(caloric_variants)
    session.flush()

    session.add_all(cv_mealtimes)
    session.commit()

    # C. POSIŁKI I ICH POWIĄZANIA (Składniki, Alergeny, Pory posiłków)
    print("4. Generowanie posiłków oraz ich składników i alergenów...")

    meals = []
    meal_mealtimes = []
    meal_ingredients = []
    meal_allergens = []
    mealtime_to_meals = {mt.id: [] for mt in mealtimes}

    dish_prefixes = [
        "Sałatka z", "Pieczony filet i", "Krem z", "Makaron pełnoziarnisty i",
        "Kasza z warzywami i", "Owsianka i", "Koktajl proteinowy i", "Tarta wytrawna i",
        "Curry z mlekiem kokosowym i", "Bowl z komosą ryżową i", "Risotto warzywne i",
    ]

    for i in range(CONFIG["NUM_MEALS"]):
        mid = i + 1
        main_ing = random.choice(ingredients_names)
        prefix = random.choice(dish_prefixes)
        meal_name = f"{prefix} {main_ing.lower()} #{mid}"

        protein = round(random.uniform(8.0, 45.0), 1)
        fat = round(random.uniform(5.0, 35.0), 1)
        carbs = round(random.uniform(10.0, 75.0), 1)
        fiber = round(random.uniform(2.0, 12.0), 1)
        salt = round(random.uniform(0.2, 2.5), 2)
        kcal = int(protein * 4 + carbs * 4 + fat * 9)

        meals.append(
            Meal(
                id=mid,
                name=meal_name,
                description=fake.sentence(nb_words=10),
                weight_grams=random.randint(220, 520),
                calories_kcal=kcal,
                protein_g=Decimal(str(protein)),
                fat_g=Decimal(str(fat)),
                carbs_g=Decimal(str(carbs)),
                fiber_g=Decimal(str(fiber)),
                salt_g=Decimal(str(salt)),
            )
        )

        # Każde danie pasuje do 1-2 pór posiłków
        chosen_mts = random.sample([mt.id for mt in mealtimes], k=random.randint(1, 2))
        for mt_id in chosen_mts:
            meal_mealtimes.append(MealMealtime(meal_id=mid, mealtime_id=mt_id))
            mealtime_to_meals[mt_id].append(mid)

        # 3 do 7 składników na posiłek
        for ing in random.sample(ingredients, k=random.randint(3, 7)):
            meal_ingredients.append(MealIngredient(meal_id=mid, ingredient_id=ing.id))

        # 0 do 3 alergenów na posiłek
        for alg in random.sample(allergens, k=random.randint(0, 3)):
            meal_allergens.append(MealAllergen(meal_id=mid, allergen_id=alg.id))

    session.add_all(meals)
    session.flush()

    session.add_all(meal_mealtimes)
    session.add_all(meal_ingredients)
    session.add_all(meal_allergens)
    session.commit()

    # D. UŻYTKOWNICY, UPRAWNIENIA, ADRESY I DANE BILINGOWE

    print("5. Generowanie użytkowników, adresów dostaw oraz danych bilingowych...")

    user_phones = generate_unique_values(lambda: f"+48{random_digits(9)}", CONFIG["NUM_USERS"])
    users = []
    user_permissions = []
    delivery_addresses = []
    user_delivery_addresses = []
    billing_data_list = []

    addr_id = 1
    bdata_id = 1
    user_to_addresses = {}
    user_to_billing_data = {}
    moderator_ids = []

    address_to_pc = {}
    serviced_pc_ids = list(pc_to_companies.keys())

    for i in range(CONFIG["NUM_USERS"]):
        uid = i + 1
        fname = fake.first_name()
        lname = fake.last_name()

        # Pierwszych 15 użytkowników to moderatorzy, kolejnych 50 to pracownicy firm cateringowych
        catering_cid = None
        if uid <= 15:
            role_id = 5  # MODERATOR
            moderator_ids.append(uid)
        elif uid <= 65:
            role_id = random.choice([2, 3, 4])  # COMPANY_OWNER / STAFF / COURIER
            catering_cid = random.randint(1, CONFIG["NUM_COMPANIES"])
        else:
            role_id = 1  # CLIENT

        users.append(
            User(
                id=uid,
                catering_company_id=catering_cid,
                email=f"user{uid}.{fake.user_name()}@{fake.free_email_domain()}",
                password_hash=fake.sha256(),
                phone_number=user_phones[i],
                first_name=fname,
                last_name=lname,
                archived=random.choices([False, True], weights=[95, 5])[0],
                created_at=fake.date_time_between(start_date="-2y", end_date="now"),
            )
        )
        user_permissions.append(UserPermission(user_id=uid, permission_id=role_id))

        # 1 do 2 adresów dostawy na użytkownika
        num_addrs = random.randint(1, 2)
        user_to_addresses[uid] = []
        for a_idx in range(num_addrs):
            pc_id = random.choice(serviced_pc_ids)
            address_to_pc[addr_id] = pc_id
            delivery_addresses.append(
                DeliveryAddress(
                    id=addr_id,
                    postal_code_id=pc.id,
                    city=fake.city(),
                    street=fake.street_name(),
                    building_number=str(random.randint(1, 150)),
                    apartment_number=str(random.randint(1, 80)) if random.random() < 0.7 else None,
                    floor=str(random.randint(0, 10)) if random.random() < 0.7 else None,
                )
            )
            user_delivery_addresses.append(
                UserDeliveryAddress(
                    user_id=uid,
                    delivery_address_id=addr_id,
                    label="Dom" if a_idx == 0 else "Praca",
                    is_default=(a_idx == 0),
                )
            )
            user_to_addresses[uid].append(addr_id)
            addr_id += 1

        # Dane bilingowe (respektujące chk_billing_buyer_details)
        buyer_type = random.choices(["PRIVATE", "COMPANY"], weights=[75, 25])[0]
        pc_bill = random.choice(postal_codes)
        if buyer_type == "COMPANY":
            b_company = fake.company()
            b_nip = random_digits(10)
            b_fname, b_lname = None, None
        else:
            b_company, b_nip = None, None
            b_fname, b_lname = fname, lname

        billing_data_list.append(
            BillingData(
                id=bdata_id,
                user_id=uid,
                postal_code_id=pc_bill.id,
                buyer_type=buyer_type,
                company_name=b_company,
                nip=b_nip,
                first_name=b_fname,
                last_name=b_lname,
                city=fake.city(),
                street=fake.street_name(),
                building_number=str(random.randint(1, 120)),
                apartment_number=str(random.randint(1, 50)) if random.random() < 0.5 else None,
            )
        )
        user_to_billing_data[uid] = (bdata_id, buyer_type)
        bdata_id += 1

    session.add_all(users)
    session.add_all(delivery_addresses)
    session.flush()

    session.add_all(user_permissions)
    session.add_all(user_delivery_addresses)
    session.add_all(billing_data_list)
    session.commit()

    # E. ZAMÓWIENIA, POZYCJE, PLANY DZIENNE, DOSTAWY I ROZLICZENIA (WYSOKI WOLUMEN)

    print("6. Generowanie zamówień, planów dziennych, dostaw i płatności (kilkadziesiąt tysięcy rekordów)...")

    orders = []
    order_items = []
    daily_plans = []
    plan_items = []
    deliveries = []
    delivery_daily_plans = []
    billings = []

    oi_id = 1
    dp_id = 1
    deliv_id = 1
    bill_id = 1

    # Przechowujemy metadane o dostawach do późniejszego generowania spójnych opinii i reklamacji
    delivery_meta = []  # krotki: (delivery_id, order_id, user_id, company_id, created_at)
    all_variants = list(caloric_variants)

    for i in range(CONFIG["NUM_ORDERS"]):
        oid = i + 1
        uid = random.randint(1, CONFIG["NUM_USERS"])
        u_addr_id = random.choice(user_to_addresses[uid])

        addr_pc_id = address_to_pc[u_addr_id]
        cid = random.choice(pc_to_companies[addr_pc_id])

        dw_chosen = random.choice(company_to_windows[cid])

        order_created = fake.date_time_between(start_date="-2y", end_date="-10d")
        order_status = random.choices(
            ["COMPLETED", "IN_PROGRESS", "PAID", "CONFIRMED", "NEW", "CANCELLED"],
            weights=[50, 20, 12, 8, 5, 5],
        )[0]

        orders.append(
            Order(
                id=oid,
                user_id=uid,
                delivery_address_id=u_addr_id,
                delivery_window_id=dw_chosen,
                status=order_status,
                created_at=order_created,
            )
        )

        num_days = random.randint(CONFIG["DAYS_PER_ORDER_MIN"], CONFIG["DAYS_PER_ORDER_MAX"])
        start_date = (order_created + timedelta(days=2)).date()

        # Tworzymy rekordy Delivery dla każdego dnia zamówienia
        date_to_delivery_id = {}
        for d_offset in range(num_days):
            sched_date = start_date + timedelta(days=d_offset)
            if order_status == "COMPLETED":
                d_status = "DELIVERED"
                deliv_at = datetime.combine(sched_date, time(random.randint(4, 7), random.randint(0, 59)))
            elif order_status == "CANCELLED":
                d_status = "CANCELLED"
                deliv_at = None
            else:
                d_status = random.choice(["PLANNED", "IN_TRANSIT", "DELIVERED"])
                deliv_at = (
                    datetime.combine(sched_date, time(6, 15))
                    if d_status == "DELIVERED"
                    else None
                )

            deliveries.append(
                Delivery(
                    id=deliv_id,
                    order_id=oid,
                    scheduled_date=sched_date,
                    delivered_at=deliv_at,
                    status=d_status,
                )
            )
            date_to_delivery_id[sched_date] = deliv_id
            delivery_meta.append((deliv_id, oid, uid, cid, order_created))
            deliv_id += 1

        # 1 lub 2 pozycje zamówienia (OrderItem)
        num_items = random.choices([1, 2], weights=[70, 30])[0]
        total_order_amount = Decimal("0.00")

        available_company_variants = company_to_variants[cid]

        for item_idx in range(num_items):
            cv = random.choice(available_company_variants)
            qty = random.choices([1, 2], weights=[85, 15])[0]
            price_snap = cv.base_price_per_day

            order_items.append(
                OrderItem(
                    id=oi_id,
                    order_id=oid,
                    caloric_variant_id=cv.id,
                    recipient=fake.first_name(),
                    quantity=qty,
                    daily_price_snapshot=price_snap,
                )
            )
            total_order_amount += price_snap * qty * num_days

            # DailyPlan oraz PlanItem dla każdego dnia zamówienia
            active_mealtimes = variant_to_mealtimes[cv.id]
            for d_offset in range(num_days):
                plan_date = start_date + timedelta(days=d_offset)
                locked_ts = datetime.combine(plan_date - timedelta(days=1), time(18, 0))

                daily_plans.append(
                    DailyPlan(
                        id=dp_id,
                        order_item_id=oi_id,
                        date=plan_date,
                        locked_at=locked_ts,
                    )
                )

                # Powiązanie dostawy z planem dziennym
                delivery_daily_plans.append(
                    DeliveryDailyPlan(
                        delivery_id=date_to_delivery_id[plan_date],
                        daily_plan_id=dp_id,
                    )
                )

                # Wybór posiłków na każdą porę dnia (PlanItem)
                for mt_id in active_mealtimes:
                    chosen_meal_id = random.choice(mealtime_to_meals[mt_id])
                    plan_items.append(
                        PlanItem(
                            daily_plan_id=dp_id,
                            mealtime_id=mt_id,
                            meal_id=chosen_meal_id,
                        )
                    )

                dp_id += 1
            oi_id += 1

        # Rozliczenie (Billing) dla zamówienia
        bdata_id_user, b_type = user_to_billing_data[uid]
        doc_type = "INVOICE" if b_type == "COMPANY" else "RECEIPT"
        is_paid = order_status in ("PAID", "IN_PROGRESS", "COMPLETED")
        doc_num = f"{'FV' if doc_type == 'INVOICE' else 'PAR'}/{order_created.year}/{oid:06d}"

        billings.append(
            Billing(
                id=bill_id,
                order_id=oid,
                billing_data_id=bdata_id_user,
                document_type=doc_type,
                document_number=doc_num,
                amount=total_order_amount,
                paid_at=order_created + timedelta(minutes=15) if is_paid else None,
            )
        )
        bill_id += 1

    session.add_all(orders)
    session.flush()

    session.add_all(order_items)
    session.add_all(deliveries)
    session.flush()

    session.add_all(daily_plans)
    session.flush()

    session.add_all(delivery_daily_plans)
    session.add_all(plan_items)
    session.add_all(billings)
    session.commit()

    # F. OPINIE, LOGI MODERACJI I REKLAMACJE

    print("7. Generowanie opinii, logów moderacji oraz reklamacji...")

    reviews = []
    moderation_logs = []
    complaints = []

    sampled_for_reviews = random.sample(delivery_meta, k=min(CONFIG["NUM_REVIEWS"], len(delivery_meta)))
    mod_id = 1

    for idx, (d_id, o_id, u_id, c_id, o_created) in enumerate(sampled_for_reviews):
        rev_id = idx + 1
        mod_status = random.choices(["VISIBLE", "PENDING", "HIDDEN"], weights=[80, 10, 10])[0]
        rev_created = o_created + timedelta(days=random.randint(3, 8))

        reviews.append(
            Review(
                id=rev_id,
                user_id=u_id,
                catering_company_id=c_id,
                delivery_id=d_id,
                meal_id=random.randint(1, CONFIG["NUM_MEALS"]) if random.random() < 0.7 else None,
                rating=random.choices([5, 4, 3, 2, 1], weights=[45, 30, 12, 8, 5])[0],
                comment=fake.sentence(nb_words=12) if random.random() < 0.85 else None,
                moderation_status=mod_status,
                created_at=rev_created,
            )
        )

        # Jeśli opinia była ukryta lub sprawdzana, dodajemy wpis w ModerationLog
        if mod_status in ("HIDDEN", "VISIBLE") and random.random() < 0.35:
            moderation_logs.append(
                ModerationLog(
                    id=mod_id,
                    review_id=rev_id,
                    user_id=random.choice(moderator_ids),
                    moderation_note=fake.sentence(nb_words=8),
                    created_at=rev_created + timedelta(hours=random.randint(1, 24)),
                )
            )
            mod_id += 1

    # Reklamacje (delivery_id w tabeli Complaint ma ograniczenie UNIQUE)
    sampled_for_complaints = random.sample(delivery_meta, k=min(CONFIG["NUM_COMPLAINTS"], len(delivery_meta)))
    complaint_subjects = [
        "Opóźniona dostawa", "Uszkodzone opakowanie posiłku",
        "Brak jednego z posiłków w torbie", "Niezgodność kaloryczności",
        "Zostawienie paczki pod złym adresem",
    ]

    for idx, (d_id, o_id, u_id, c_id, o_created) in enumerate(sampled_for_complaints):
        comp_id = idx + 1
        c_status = random.choices(["RESOLVED", "REJECTED", "IN_PROGRESS", "OPEN"], weights=[50, 15, 20, 15])[0]
        c_created = o_created + timedelta(days=random.randint(2, 5))
        is_closed = c_status in ("RESOLVED", "REJECTED")

        complaints.append(
            Complaint(
                id=comp_id,
                user_id=u_id,
                order_id=o_id,
                delivery_id=d_id,
                subject=random.choice(complaint_subjects),
                description=fake.paragraph(nb_sentences=2),
                status=c_status,
                decision_justification=fake.sentence(nb_words=10) if is_closed else None,
                created_at=c_created,
                resolved_at=c_created + timedelta(days=random.randint(1, 3)) if is_closed else None,
            )
        )

    session.add_all(reviews)
    session.flush()

    session.add_all(moderation_logs)
    session.add_all(complaints)
    session.commit()

    # PODSUMOWANIE LICZBY REKORDÓW

    print("\n=== PODSUMOWANIE WYGENEROWANYCH REKORDÓW ===")
    total_records = 0
    for table in Base.metadata.sorted_tables:
        count = session.execute(text(f'SELECT COUNT(*) FROM "{table.name}"')).scalar()
        total_records += count
        print(f" - {table.name:<28}: {count:>8} rekordów")
    print("=" * 44)
    print(f" ŁĄCZNIE W BAZIE DANYCH       : {total_records:>8} rekordów")

    session.close()


if __name__ == "__main__":
    seed_database()