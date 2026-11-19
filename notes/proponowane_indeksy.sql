CREATE EXTENSION IF NOT EXISTS pg_trgm;

/* ===== A. KLUCZE OBCE I TABELE ŁĄCZNIKOWE =====
   Cel: szybkie złączenia oraz szybkie sprawdzanie CASCADE/RESTRICT/SET NULL.
   Przy indeksach odwrotnych tabel łącznikowych dopisuję drugą kolumnę, żeby
   zapytania typu "wszystko dla X" mogły korzystać z Index Only Scan. */

CREATE INDEX idx_user_company            ON "User"(catering_company_id)
    WHERE catering_company_id IS NOT NULL;            -- większość kont to klienci (NULL)
CREATE INDEX idx_userperm_permission     ON "UserPermission"(permission_id, user_id);      -- raport 24
CREATE INDEX idx_address_postal          ON "DeliveryAddress"(postal_code_id);
CREATE INDEX idx_userAddr_address        ON "UserDeliveryAddress"(delivery_address_id);
CREATE INDEX idx_billingdata_user        ON "BillingData"(user_id);
CREATE INDEX idx_billingdata_postal      ON "BillingData"(postal_code_id);
CREATE INDEX idx_ccpc_postal             ON "CateringCompanyPostalCode"(postal_code_id, catering_company_id); -- search_catering_companies
CREATE INDEX idx_window_company          ON "DeliveryWindow"(catering_company_id);
CREATE INDEX idx_mealmealtime_mealtime   ON "MealMealtime"(mealtime_id, meal_id);          -- search_meals, raport 11
CREATE INDEX idx_mealingredient_ing      ON "MealIngredient"(ingredient_id, meal_id);      -- raport 22
CREATE INDEX idx_mealallergen_allergen   ON "MealAllergen"(allergen_id, meal_id);          -- raport 21
CREATE INDEX idx_planitem_meal           ON "PlanItem"(meal_id, daily_plan_id);            -- raport 23
CREATE INDEX idx_deliverydp_plan         ON "DeliveryDailyPlan"(daily_plan_id, delivery_id);
CREATE INDEX idx_billing_billingdata     ON "Billing"(billing_data_id)
    WHERE billing_data_id IS NOT NULL;
CREATE INDEX idx_orderitem_variant       ON "OrderItem"(caloric_variant_id);
CREATE INDEX idx_order_address           ON "Order"(delivery_address_id);
CREATE INDEX idx_order_window            ON "Order"(delivery_window_id);                   -- Order -> firma (raporty 01, 03, 05, 06)
CREATE INDEX idx_complaint_user          ON "Complaint"(user_id);
CREATE INDEX idx_complaint_order         ON "Complaint"(order_id);
CREATE INDEX idx_review_user             ON "Review"(user_id);
CREATE INDEX idx_review_delivery         ON "Review"(delivery_id);
CREATE INDEX idx_modlog_user_created     ON "ModerationLog"(user_id, created_at);          -- FK + raport 25

/* ===== B. FUNKCJE WYSZUKIWANIA ===== */

-- ILIKE '%fraza%' nie korzysta z B-tree (wiodący wildcard). GIN z trigramami
-- rozbija tekst na 3-znakowe fragmenty i potrafi je odnaleźć w dowolnym miejscu.
CREATE INDEX idx_meal_name_trgm      ON "Meal"    USING GIN (name gin_trgm_ops);
CREATE INDEX idx_meal_desc_trgm      ON "Meal"    USING GIN (description gin_trgm_ops);
CREATE INDEX idx_diet_name_trgm      ON "Diet"    USING GIN (name gin_trgm_ops);
CREATE INDEX idx_address_city_trgm   ON "DeliveryAddress" USING GIN (city gin_trgm_ops);

-- search_orders: równość na user_id, potem sortowanie zgodne z ORDER BY
CREATE INDEX idx_order_user_created  ON "Order"(user_id, created_at DESC, id DESC);
-- wyszukiwanie bez użytkownika (zakres dat + ORDER BY, raport 01)
CREATE INDEX idx_order_created       ON "Order"(created_at DESC, id DESC);

-- search_catering_companies: tylko aktywne diety (zwykle większość, ale lista jest krótka)
CREATE INDEX idx_diet_active         ON "Diet"(catering_company_id) WHERE is_active;

/* ===== C. RAPORTY ANALITYCZNE ===== */

-- Rekomendacje/oceny (raporty 08, 09, 10): status jako 2. kolumna, rating w INCLUDE
-- -> Index Only Scan. Zwykły (nie częściowy) indeks, bo obsługuje też FK CASCADE.
CREATE INDEX idx_review_company_status ON "Review"(catering_company_id, moderation_status) INCLUDE (rating);
CREATE INDEX idx_review_meal_status    ON "Review"(meal_id, moderation_status) INCLUDE (rating)
    WHERE meal_id IS NOT NULL;

-- Zamówienia: elementy i dostawy w LATERAL (raport 01), dostawy per firma (05)
CREATE INDEX idx_orderitem_order     ON "OrderItem"(order_id) INCLUDE (quantity, recipient);
CREATE INDEX idx_delivery_order      ON "Delivery"(order_id) INCLUDE (scheduled_date, status);
-- "co mamy dziś do dostarczenia": mały indeks, bo większość dostaw jest już zakończona
CREATE INDEX idx_delivery_open       ON "Delivery"(scheduled_date) WHERE status IN ('PLANNED','IN_TRANSIT');

-- Finanse (raporty 02, 03, 18): tylko opłacone, kwota w liściu
CREATE INDEX idx_billing_paid        ON "Billing"(paid_at) INCLUDE (amount) WHERE paid_at IS NOT NULL;

-- Reklamacje (06, 07): kolejka nierozstrzygniętych jest mała
CREATE INDEX idx_complaint_unresolved ON "Complaint"(created_at) WHERE status IN ('OPEN','IN_PROGRESS');
CREATE INDEX idx_complaint_created    ON "Complaint"(created_at);

-- Plany dzienne (19, 20) i kohorty (15)
CREATE INDEX idx_dailyplan_date      ON "DailyPlan"(date);
CREATE INDEX idx_user_created        ON "User"(created_at);

-- (opcjonalnie dla milionów wierszy, tabele append-only)
-- CREATE INDEX idx_order_created_brin ON "Order" USING BRIN (created_at);

/* ===== D. INTEGRALNOŚĆ (indeks jako ograniczenie) ===== */
-- Dokładnie jeden adres domyślny na użytkownika. Raport 17 przestaje wtedy
-- wykrywać "wiele domyślnych", bo baza już na to nie pozwoli.
CREATE UNIQUE INDEX uq_userAddr_one_default ON "UserDeliveryAddress"(user_id) WHERE is_default;

-- Podwójne wiersze w "UNIQUE (diet_id, calories)": pokrywający wariant ceny
-- (opcjonalnie zamiast istniejącego ograniczenia, raport 12):
-- ALTER TABLE "CaloricVariant" DROP CONSTRAINT uq_variant_diet_calories,
--   ADD CONSTRAINT uq_variant_diet_calories UNIQUE (diet_id, calories) INCLUDE (base_price_per_day);
