/*
===============================================================================
RAPORTY I WYSZUKIWANIE — BAZA PLATFORMY CATERINGOWEJ
Dialekt: PostgreSQL

Założenia:
- Skrypt jest przeznaczony do uruchomienia po utworzeniu tabel z projektu.
- Nazwy tabel zapisano w cudzysłowach, zgodnie z definicją schematu.
- Funkcje wyszukiwania są parametryzowane; raporty poniżej są 25 odrębnymi
  zapytaniami o różnym celu, a nie jednym zapytaniem z podmienianymi filtrami.
- Każdy SELECT raportowy należy uruchomić osobno (otrzymuje się osobny zestaw
  wyników). Wyniki zależą od danych zapisanych w bazie.
===============================================================================
*/

/* ---------------------------------------------------------------------------
   A. FUNKCJE WYSZUKIWANIA
   --------------------------------------------------------------------------- */

/* 1. Wyszukiwanie dań po frazie, porze posiłku, kaloryczności i białku.
      Można wykluczyć wiele alergenów jednocześnie, przekazując tablicę ID.
      Puste/null parametry nie zawężają danego kryterium.
*/
CREATE OR REPLACE FUNCTION search_meals(
    p_phrase TEXT DEFAULT NULL,
    p_mealtime_id INTEGER DEFAULT NULL,
    p_max_calories INTEGER DEFAULT NULL,
    p_min_protein NUMERIC DEFAULT NULL,
    p_excluded_allergen_ids INTEGER[] DEFAULT ARRAY[]::INTEGER[]
)
RETURNS TABLE (
    meal_id INTEGER,
    meal_name VARCHAR,
    weight_grams INTEGER,
    calories_kcal INTEGER,
    protein_g NUMERIC,
    mealtimes TEXT,
    allergens TEXT
)
LANGUAGE SQL
STABLE
AS $function$
    SELECT
        m.id,
        m.name,
        m.weight_grams,
        m.calories_kcal,
        m.protein_g,
        COALESCE((
            SELECT STRING_AGG(mt.name, ', ' ORDER BY mt.display_order)
            FROM "MealMealtime" mmt
            JOIN "Mealtime" mt ON mt.id = mmt.mealtime_id
            WHERE mmt.meal_id = m.id
        ), '—') AS mealtimes,
        COALESCE((
            SELECT STRING_AGG(a.name, ', ' ORDER BY a.name)
            FROM "MealAllergen" ma
            JOIN "Allergen" a ON a.id = ma.allergen_id
            WHERE ma.meal_id = m.id
        ), 'Brak przypisanych alergenów') AS allergens
    FROM "Meal" m
    WHERE
        (NULLIF(BTRIM(p_phrase), '') IS NULL
            OR m.name ILIKE '%' || BTRIM(p_phrase) || '%'
            OR m.description ILIKE '%' || BTRIM(p_phrase) || '%')
        AND (p_mealtime_id IS NULL OR EXISTS (
            SELECT 1
            FROM "MealMealtime" mmt
            WHERE mmt.meal_id = m.id
              AND mmt.mealtime_id = p_mealtime_id
        ))
        AND (p_max_calories IS NULL OR m.calories_kcal <= p_max_calories)
        AND (p_min_protein IS NULL OR m.protein_g >= p_min_protein)
        AND NOT EXISTS (
            SELECT 1
            FROM "MealAllergen" ma
            WHERE ma.meal_id = m.id
              AND ma.allergen_id = ANY(
                  COALESCE(p_excluded_allergen_ids, ARRAY[]::INTEGER[])
              )
        )
    ORDER BY m.name;
$function$;

/* 2. Wyszukiwanie firm cateringowych według obszaru dostaw i oferty.
      Miasto jest ustalane przez adresy przypisane do kodów pocztowych,
      które firma deklaruje jako obsługiwane.
*/
CREATE OR REPLACE FUNCTION search_catering_companies(
    p_city TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_diet_phrase TEXT DEFAULT NULL,
    p_only_verified BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    company_id INTEGER,
    company_name VARCHAR,
    verification_status VARCHAR,
    active_diets BIGINT,
    service_postal_codes TEXT
)
LANGUAGE SQL
STABLE
AS $function$
    SELECT
        c.id,
        c.name,
        c.verification_status,
        (
            SELECT COUNT(*)
            FROM "Diet" d
            WHERE d.catering_company_id = c.id
              AND d.is_active = TRUE
        ) AS active_diets,
        COALESCE((
            SELECT STRING_AGG(pc.code::TEXT, ', ' ORDER BY pc.code::TEXT)
            FROM "CateringCompanyPostalCode" ccp
            JOIN "PostalCode" pc ON pc.id = ccp.postal_code_id
            WHERE ccp.catering_company_id = c.id
        ), 'Brak zdefiniowanych kodów') AS service_postal_codes
    FROM "CateringCompany" c
    WHERE
        (p_only_verified IS DISTINCT FROM TRUE
            OR c.verification_status = 'VERIFIED')
        AND (NULLIF(BTRIM(p_postal_code), '') IS NULL OR EXISTS (
            SELECT 1
            FROM "CateringCompanyPostalCode" ccp
            JOIN "PostalCode" pc ON pc.id = ccp.postal_code_id
            WHERE ccp.catering_company_id = c.id
              AND pc.code::TEXT = BTRIM(p_postal_code)
        ))
        AND (NULLIF(BTRIM(p_city), '') IS NULL OR EXISTS (
            SELECT 1
            FROM "CateringCompanyPostalCode" ccp
            JOIN "DeliveryAddress" da
              ON da.postal_code_id = ccp.postal_code_id
            WHERE ccp.catering_company_id = c.id
              AND da.city ILIKE '%' || BTRIM(p_city) || '%'
        ))
        AND (NULLIF(BTRIM(p_diet_phrase), '') IS NULL OR EXISTS (
            SELECT 1
            FROM "Diet" d
            WHERE d.catering_company_id = c.id
              AND d.is_active = TRUE
              AND d.name ILIKE '%' || BTRIM(p_diet_phrase) || '%'
        ))
    ORDER BY c.name;
$function$;

/* 3. Wyszukiwanie zamówień po użytkowniku, statusie i przedziale dat.
      Granica p_created_to jest wyłączna, co ułatwia podawanie kolejnych dni.
*/
CREATE OR REPLACE FUNCTION search_orders(
    p_user_id INTEGER DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_created_from TIMESTAMP DEFAULT NULL,
    p_created_to TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    order_id INTEGER,
    created_at TIMESTAMP,
    order_status VARCHAR,
    customer_email VARCHAR,
    catering_company VARCHAR,
    delivery_address TEXT,
    billing_amount NUMERIC,
    paid_at TIMESTAMP
)
LANGUAGE SQL
STABLE
AS $function$
    SELECT
        o.id,
        o.created_at,
        o.status,
        u.email,
        c.name,
        CONCAT_WS(', ', da.street || ' ' || da.building_number,
                  da.apartment_number, da.city, pc.code::TEXT),
        b.amount,
        b.paid_at
    FROM "Order" o
    JOIN "User" u ON u.id = o.user_id
    JOIN "DeliveryAddress" da ON da.id = o.delivery_address_id
    JOIN "PostalCode" pc ON pc.id = da.postal_code_id
    JOIN "DeliveryWindow" dw ON dw.id = o.delivery_window_id
    JOIN "CateringCompany" c ON c.id = dw.catering_company_id
    LEFT JOIN "Billing" b ON b.order_id = o.id
    WHERE
        (p_user_id IS NULL OR o.user_id = p_user_id)
        AND (NULLIF(BTRIM(p_status), '') IS NULL OR o.status = BTRIM(p_status))
        AND (p_created_from IS NULL OR o.created_at >= p_created_from)
        AND (p_created_to IS NULL OR o.created_at < p_created_to)
    ORDER BY o.created_at DESC, o.id DESC;
$function$;

/* Przykładowe wywołania funkcji (odkomentować i dostosować ID do danych):

SELECT * FROM search_meals(
    p_phrase => 'kurczak',
    p_mealtime_id => 2,
    p_max_calories => 650,
    p_min_protein => 25,
    p_excluded_allergen_ids => ARRAY[1, 4]
);

SELECT * FROM search_catering_companies(
    p_city => 'Wrocław',
    p_postal_code => '50-001',
    p_diet_phrase => 'wege',
    p_only_verified => TRUE
);

SELECT * FROM search_orders(
    p_user_id => 12,
    p_status => 'COMPLETED',
    p_created_from => TIMESTAMP '2026-01-01 00:00:00',
    p_created_to => TIMESTAMP '2027-01-01 00:00:00'
);
*/


/* ---------------------------------------------------------------------------
   B. 25 RAPORTÓW I ZAPYTAŃ ANALITYCZNYCH
   --------------------------------------------------------------------------- */

/* RAPORT 01 — Operacyjna lista zamówień.
   LATERAL agreguje pozycje i dostawy niezależnie, dzięki czemu połączenie
   kilku relacji 1:N nie mnoży sztucznie liczby pozycji ani dostaw.
*/
SELECT
    o.id AS order_id,
    o.created_at,
    o.status,
    u.email AS customer_email,
    c.name AS catering_company,
    CONCAT_WS(', ', da.street || ' ' || da.building_number,
              da.apartment_number, da.city, pc.code::TEXT) AS delivery_address,
    item_summary.item_count,
    item_summary.total_quantity,
    item_summary.recipients,
    b.amount AS billed_amount,
    b.paid_at,
    delivery_summary.delivery_count,
    delivery_summary.last_scheduled_date,
    delivery_summary.delivery_statuses
FROM "Order" o
JOIN "User" u ON u.id = o.user_id
JOIN "DeliveryAddress" da ON da.id = o.delivery_address_id
JOIN "PostalCode" pc ON pc.id = da.postal_code_id
JOIN "DeliveryWindow" dw ON dw.id = o.delivery_window_id
JOIN "CateringCompany" c ON c.id = dw.catering_company_id
LEFT JOIN "Billing" b ON b.order_id = o.id
LEFT JOIN LATERAL (
    SELECT
        COUNT(*) AS item_count,
        COALESCE(SUM(oi.quantity), 0) AS total_quantity,
        STRING_AGG(DISTINCT oi.recipient, ', ' ORDER BY oi.recipient) AS recipients
    FROM "OrderItem" oi
    WHERE oi.order_id = o.id
) item_summary ON TRUE
LEFT JOIN LATERAL (
    SELECT
        COUNT(*) AS delivery_count,
        MAX(d.scheduled_date) AS last_scheduled_date,
        STRING_AGG(d.status, ', ' ORDER BY d.scheduled_date, d.id) AS delivery_statuses
    FROM "Delivery" d
    WHERE d.order_id = o.id
) delivery_summary ON TRUE
ORDER BY o.created_at DESC, o.id DESC;

/* RAPORT 02 — Miesięczne przychody z opłaconych dokumentów.
   SUM, AVG, MIN, MAX oraz suma narastająca (funkcja okna).
*/
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', b.paid_at)::DATE AS revenue_month,
        COUNT(*) AS paid_documents,
        SUM(b.amount) AS revenue,
        AVG(b.amount) AS average_document_value,
        MIN(b.amount) AS smallest_document,
        MAX(b.amount) AS largest_document
    FROM "Billing" b
    WHERE b.paid_at IS NOT NULL
    GROUP BY DATE_TRUNC('month', b.paid_at)::DATE
)
SELECT
    revenue_month,
    paid_documents,
    revenue,
    ROUND(average_document_value, 2) AS average_document_value,
    smallest_document,
    largest_document,
    SUM(revenue) OVER (ORDER BY revenue_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM monthly_revenue
ORDER BY revenue_month;

/* RAPORT 03 — Skuteczność rozliczeń według firmy i rodzaju dokumentu.
   Agregaty FILTER pokazują, jak grupować różne podzbiory tych samych danych.
*/
SELECT
    c.id AS company_id,
    c.name AS catering_company,
    b.document_type,
    COUNT(*) AS all_documents,
    COUNT(*) FILTER (WHERE b.paid_at IS NOT NULL) AS paid_documents,
    COUNT(*) FILTER (WHERE b.paid_at IS NULL) AS unpaid_documents,
    COALESCE(SUM(b.amount) FILTER (WHERE b.paid_at IS NOT NULL), 0) AS paid_amount,
    COALESCE(SUM(b.amount) FILTER (WHERE b.paid_at IS NULL), 0) AS outstanding_amount,
    ROUND(AVG(b.amount), 2) AS average_document_amount
FROM "Billing" b
JOIN "Order" o ON o.id = b.order_id
JOIN "DeliveryWindow" dw ON dw.id = o.delivery_window_id
JOIN "CateringCompany" c ON c.id = dw.catering_company_id
GROUP BY c.id, c.name, b.document_type
ORDER BY c.name, b.document_type;

/* RAPORT 04 — Struktura statusów zamówień oraz ich udział procentowy.
   SUM(COUNT(*)) OVER() oblicza mianownik bez dodatkowego podzapytania.
*/
WITH status_counts AS (
    SELECT o.status, COUNT(*) AS order_count
    FROM "Order" o
    GROUP BY o.status
)
SELECT
    status,
    order_count,
    ROUND((100.0 * order_count / NULLIF(SUM(order_count) OVER (), 0))::NUMERIC, 2)
        AS percentage_of_orders
FROM status_counts
ORDER BY order_count DESC, status;

/* RAPORT 05 — Terminowość i skuteczność dostaw według firmy cateringowej.
   Średni czas liczony jest wyłącznie dla dostaw oznaczonych jako DELIVERED.
*/
SELECT
    c.id AS company_id,
    c.name AS catering_company,
    COUNT(d.id) AS all_deliveries,
    COUNT(d.id) FILTER (WHERE d.status = 'DELIVERED') AS delivered_count,
    COUNT(d.id) FILTER (WHERE d.status = 'FAILED') AS failed_count,
    COUNT(d.id) FILTER (WHERE d.status = 'CANCELLED') AS cancelled_count,
    ROUND((100.0 * COUNT(d.id) FILTER (WHERE d.status = 'DELIVERED')
           / NULLIF(COUNT(d.id), 0))::NUMERIC, 2) AS delivery_success_percentage,
    AVG(d.delivered_at - d.scheduled_date::TIMESTAMP)
        FILTER (WHERE d.status = 'DELIVERED' AND d.delivered_at IS NOT NULL)
        AS average_delivery_time_from_scheduled_date
FROM "CateringCompany" c
JOIN "DeliveryWindow" dw ON dw.catering_company_id = c.id
JOIN "Order" o ON o.delivery_window_id = dw.id
JOIN "Delivery" d ON d.order_id = o.id
GROUP BY c.id, c.name
ORDER BY delivery_success_percentage DESC NULLS LAST, all_deliveries DESC;

/* RAPORT 06 — Miesięczna obsługa reklamacji w podziale na firmę.
   Czas rozpatrzenia jest przedziałem od utworzenia do decyzji.
*/
SELECT
    c.name AS catering_company,
    DATE_TRUNC('month', cp.created_at)::DATE AS complaint_month,
    COUNT(*) AS complaint_count,
    COUNT(*) FILTER (WHERE cp.status = 'OPEN') AS open_count,
    COUNT(*) FILTER (WHERE cp.status = 'IN_PROGRESS') AS in_progress_count,
    COUNT(*) FILTER (WHERE cp.status = 'RESOLVED') AS resolved_count,
    COUNT(*) FILTER (WHERE cp.status = 'REJECTED') AS rejected_count,
    AVG(cp.resolved_at - cp.created_at)
        FILTER (WHERE cp.resolved_at IS NOT NULL) AS average_resolution_time,
    MAX(cp.created_at) AS latest_complaint_date
FROM "Complaint" cp
JOIN "Order" o ON o.id = cp.order_id
JOIN "DeliveryWindow" dw ON dw.id = o.delivery_window_id
JOIN "CateringCompany" c ON c.id = dw.catering_company_id
GROUP BY c.name, DATE_TRUNC('month', cp.created_at)::DATE
ORDER BY complaint_month DESC, complaint_count DESC;

/* RAPORT 07 — Najczęstsze tematy reklamacji i ich charakterystyka.
   LENGTH/AVG mierzą przeciętną długość opisu, a FILTER rozdziela statusy.
*/
SELECT
    cp.subject,
    COUNT(*) AS complaint_count,
    COUNT(*) FILTER (WHERE cp.status IN ('OPEN', 'IN_PROGRESS')) AS unresolved_count,
    COUNT(*) FILTER (WHERE cp.status = 'RESOLVED') AS resolved_count,
    ROUND(AVG(CHAR_LENGTH(cp.description)), 1) AS average_description_length,
    AVG(cp.resolved_at - cp.created_at)
        FILTER (WHERE cp.resolved_at IS NOT NULL) AS average_resolution_time
FROM "Complaint" cp
GROUP BY cp.subject
ORDER BY complaint_count DESC, cp.subject;

/* RAPORT 08 — Statystyka widocznych ocen firm.
   Pokazuje średnią, medianę, odchylenie standardowe oraz liczność próby.
*/
SELECT
    c.id AS company_id,
    c.name AS catering_company,
    COUNT(r.id) FILTER (WHERE r.moderation_status = 'VISIBLE') AS visible_reviews,
    ROUND(AVG(r.rating) FILTER (WHERE r.moderation_status = 'VISIBLE'), 2)
        AS average_rating,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.rating::DOUBLE PRECISION)
        FILTER (WHERE r.moderation_status = 'VISIBLE') AS median_rating,
    ROUND((STDDEV_SAMP(r.rating) FILTER (WHERE r.moderation_status = 'VISIBLE'))::NUMERIC, 3)
        AS rating_standard_deviation,
    MIN(r.rating) FILTER (WHERE r.moderation_status = 'VISIBLE') AS minimum_rating,
    MAX(r.rating) FILTER (WHERE r.moderation_status = 'VISIBLE') AS maximum_rating
FROM "CateringCompany" c
LEFT JOIN "Review" r ON r.catering_company_id = c.id
GROUP BY c.id, c.name
HAVING COUNT(r.id) FILTER (WHERE r.moderation_status = 'VISIBLE') >= 3
ORDER BY average_rating DESC, visible_reviews DESC;

/* RAPORT 09 — Ranking firm na podstawie średniej oceny.
   DENSE_RANK nie pomija kolejnych pozycji przy remisach.
*/
WITH company_ratings AS (
    SELECT
        c.id,
        c.name,
        COUNT(r.id) AS review_count,
        AVG(r.rating) AS average_rating
    FROM "CateringCompany" c
    JOIN "Review" r ON r.catering_company_id = c.id
    WHERE r.moderation_status = 'VISIBLE'
    GROUP BY c.id, c.name
    HAVING COUNT(r.id) >= 3
)
SELECT
    DENSE_RANK() OVER (ORDER BY average_rating DESC) AS ranking_position,
    id AS company_id,
    name AS catering_company,
    review_count,
    ROUND(average_rating, 2) AS average_rating
FROM company_ratings
ORDER BY ranking_position, review_count DESC;

/* RAPORT 10 — Oceny dań i ich wartość energetyczna w przeliczeniu na 100 g.
   Uwzględniane są wyłącznie widoczne recenzje przypisane do konkretnego dania.
*/
SELECT
    m.id AS meal_id,
    m.name AS meal_name,
    m.weight_grams,
    m.calories_kcal,
    ROUND((m.calories_kcal * 100.0 / NULLIF(m.weight_grams, 0))::NUMERIC, 1)
        AS kcal_per_100g,
    COUNT(r.id) AS visible_review_count,
    ROUND(AVG(r.rating), 2) AS average_rating,
    RANK() OVER (ORDER BY AVG(r.rating) DESC NULLS LAST, COUNT(r.id) DESC)
        AS popularity_rank
FROM "Meal" m
LEFT JOIN "Review" r
    ON r.meal_id = m.id
   AND r.moderation_status = 'VISIBLE'
GROUP BY m.id, m.name, m.weight_grams, m.calories_kcal
ORDER BY popularity_rank, m.name;

/* RAPORT 11 — Statystyki odżywcze dań w podziale na porę posiłku.
   Mediana białka i odchylenie standardowe kalorii uzupełniają średnie.
*/
SELECT
    mt.id AS mealtime_id,
    mt.name AS mealtime,
    COUNT(DISTINCT m.id) AS meal_count,
    ROUND(AVG(m.calories_kcal), 1) AS average_calories,
    MIN(m.calories_kcal) AS minimum_calories,
    MAX(m.calories_kcal) AS maximum_calories,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY m.protein_g::DOUBLE PRECISION)
        AS median_protein_g,
    ROUND(STDDEV_POP(m.calories_kcal)::NUMERIC, 2) AS calories_standard_deviation,
    ROUND(AVG(m.fiber_g), 2) AS average_fiber_g,
    ROUND(AVG(m.salt_g), 2) AS average_salt_g
FROM "Mealtime" mt
JOIN "MealMealtime" mmt ON mmt.mealtime_id = mt.id
JOIN "Meal" m ON m.id = mmt.meal_id
GROUP BY mt.id, mt.name, mt.display_order
ORDER BY mt.display_order;

/* RAPORT 12 — Analiza cen wariantów kalorycznych diet.
   Mediana, odchylenie standardowe i cena za 1000 kcal ułatwiają porównanie.
*/
SELECT
    c.name AS catering_company,
    d.name AS diet_name,
    COUNT(cv.id) AS variant_count,
    MIN(cv.calories) AS minimum_calories,
    MAX(cv.calories) AS maximum_calories,
    ROUND(AVG(cv.base_price_per_day), 2) AS average_daily_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY cv.base_price_per_day::DOUBLE PRECISION) AS median_daily_price,
    ROUND(STDDEV_POP(cv.base_price_per_day), 2) AS price_standard_deviation,
    ROUND(AVG(cv.base_price_per_day * 1000.0 / NULLIF(cv.calories, 0)), 2)
        AS average_price_per_1000_kcal
FROM "Diet" d
JOIN "CateringCompany" c ON c.id = d.catering_company_id
JOIN "CaloricVariant" cv ON cv.diet_id = d.id
GROUP BY c.name, d.name
ORDER BY c.name, d.name;

/* RAPORT 13 — Wielkość oferty dietetycznej każdej firmy.
   COUNT(DISTINCT d.id) zapobiega zawyżeniu liczby diet przez ich warianty.
*/
SELECT
    c.id AS company_id,
    c.name AS catering_company,
    COUNT(DISTINCT d.id) AS all_diets,
    COUNT(DISTINCT d.id) FILTER (WHERE d.is_active = TRUE) AS active_diets,
    COUNT(DISTINCT d.id) FILTER (WHERE d.is_active = FALSE) AS inactive_diets,
    COUNT(cv.id) AS caloric_variants,
    COUNT(cv.id) FILTER (WHERE d.is_active = TRUE) AS variants_in_active_diets,
    ROUND(AVG(cv.base_price_per_day), 2) AS average_variant_price
FROM "CateringCompany" c
LEFT JOIN "Diet" d ON d.catering_company_id = c.id
LEFT JOIN "CaloricVariant" cv ON cv.diet_id = d.id
GROUP BY c.id, c.name
ORDER BY active_diets DESC, caloric_variants DESC, c.name;

/* RAPORT 14 — Pokrycie terytorialne firm cateringowych.
   STRING_AGG prezentuje obsługiwane kody pocztowe w jednym wierszu.
*/
SELECT
    c.id AS company_id,
    c.name AS catering_company,
    COUNT(DISTINCT ccp.postal_code_id) AS covered_postal_areas,
    STRING_AGG(DISTINCT pc.code::TEXT, ', ' ORDER BY pc.code::TEXT)
        AS covered_postal_codes
FROM "CateringCompany" c
LEFT JOIN "CateringCompanyPostalCode" ccp
    ON ccp.catering_company_id = c.id
LEFT JOIN "PostalCode" pc ON pc.id = ccp.postal_code_id
GROUP BY c.id, c.name
ORDER BY covered_postal_areas DESC, c.name;

/* RAPORT 15 — Miesięczne kohorty użytkowników i konwersja na pierwsze zamówienie.
   Pierwsze zamówienie jest liczone osobno dla każdego użytkownika.
*/
WITH first_orders AS (
    SELECT o.user_id, MIN(o.created_at) AS first_order_at
    FROM "Order" o
    GROUP BY o.user_id
), order_counts AS (
    SELECT o.user_id, COUNT(*) AS order_count
    FROM "Order" o
    GROUP BY o.user_id
)
SELECT
    DATE_TRUNC('month', u.created_at)::DATE AS registration_month,
    COUNT(*) AS registered_users,
    COUNT(*) FILTER (WHERE fo.first_order_at IS NOT NULL) AS users_with_order,
    ROUND((100.0 * COUNT(*) FILTER (WHERE fo.first_order_at IS NOT NULL)
           / NULLIF(COUNT(*), 0))::NUMERIC, 2) AS conversion_percentage,
    COUNT(*) FILTER (WHERE COALESCE(oc.order_count, 0) >= 2) AS repeat_customers,
    AVG(fo.first_order_at - u.created_at)
        FILTER (WHERE fo.first_order_at IS NOT NULL) AS average_time_to_first_order
FROM "User" u
LEFT JOIN first_orders fo ON fo.user_id = u.id
LEFT JOIN order_counts oc ON oc.user_id = u.id
GROUP BY DATE_TRUNC('month', u.created_at)::DATE
ORDER BY registration_month;

/* RAPORT 16 — Klienci powracający i ich wartość zakupów.
   Suma obejmuje tylko opłacone dokumenty; zamówienia bez dokumentu pozostają
   w zestawieniu dzięki LEFT JOIN.
*/
SELECT
    u.id AS user_id,
    u.email,
    u.first_name,
    u.last_name,
    COUNT(DISTINCT o.id) AS order_count,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'COMPLETED') AS completed_orders,
    COALESCE(SUM(b.amount) FILTER (WHERE b.paid_at IS NOT NULL), 0)
        AS total_paid_amount,
    ROUND(AVG(b.amount) FILTER (WHERE b.paid_at IS NOT NULL), 2)
        AS average_paid_order_value,
    MAX(o.created_at) AS most_recent_order
FROM "User" u
JOIN "Order" o ON o.user_id = u.id
LEFT JOIN "Billing" b ON b.order_id = o.id
GROUP BY u.id, u.email, u.first_name, u.last_name
HAVING COUNT(DISTINCT o.id) >= 2
ORDER BY total_paid_amount DESC, order_count DESC;

/* RAPORT 17 — Kontrola jakości adresów użytkowników.
   Wykrywa użytkowników bez adresu, bez adresu domyślnego lub z wieloma
   adresami domyślnymi. Nie zakłada, że ograniczenie to jest już wymuszone.
*/
SELECT
    u.id AS user_id,
    u.email,
    COUNT(uda.delivery_address_id) AS address_count,
    COUNT(uda.delivery_address_id) FILTER (WHERE uda.is_default IS TRUE)
        AS default_address_count,
    STRING_AGG(uda.label, ', ' ORDER BY uda.label) AS address_labels
FROM "User" u
LEFT JOIN "UserDeliveryAddress" uda ON uda.user_id = u.id
GROUP BY u.id, u.email
HAVING COUNT(uda.delivery_address_id) = 0
    OR COUNT(uda.delivery_address_id) FILTER (WHERE uda.is_default IS TRUE) <> 1
ORDER BY default_address_count, u.email;

/* RAPORT 18 — Struktura dokumentów według typu nabywcy i miejsca rozliczenia.
   Dane nabywcy są agregowane, bez ujawniania numerów NIP ani danych osobowych.
*/
SELECT
    COALESCE(bd.buyer_type, 'UNSPECIFIED') AS buyer_type,
    COALESCE(bd.city, 'Brak danych') AS billing_city,
    COALESCE(pc.code::TEXT, 'Brak kodu') AS postal_code,
    b.document_type,
    COUNT(*) AS document_count,
    SUM(b.amount) AS total_amount,
    ROUND(AVG(b.amount), 2) AS average_amount,
    COUNT(*) FILTER (WHERE b.paid_at IS NOT NULL) AS paid_count
FROM "Billing" b
LEFT JOIN "BillingData" bd ON bd.id = b.billing_data_id
LEFT JOIN "PostalCode" pc ON pc.id = bd.postal_code_id
GROUP BY
    COALESCE(bd.buyer_type, 'UNSPECIFIED'),
    COALESCE(bd.city, 'Brak danych'),
    COALESCE(pc.code::TEXT, 'Brak kodu'),
    b.document_type
ORDER BY buyer_type, billing_city, b.document_type;

/* RAPORT 19 — Wartość odżywcza dziennych planów posiłków.
   Sumy dotyczą wszystkich dań przypisanych do danego planu w danym dniu.
*/
SELECT
    dp.id AS daily_plan_id,
    dp.date AS plan_date,
    oi.recipient,
    COUNT(pi.meal_id) AS meal_occurrences,
    SUM(m.calories_kcal) AS total_calories_kcal,
    ROUND(SUM(m.protein_g), 2) AS total_protein_g,
    ROUND(SUM(m.fat_g), 2) AS total_fat_g,
    ROUND(SUM(m.carbs_g), 2) AS total_carbs_g,
    ROUND(SUM(m.fiber_g), 2) AS total_fiber_g,
    ROUND(SUM(m.salt_g), 2) AS total_salt_g,
    STRING_AGG(mt.name || ': ' || m.name, ' | ' ORDER BY mt.display_order)
        AS meal_schedule
FROM "DailyPlan" dp
JOIN "OrderItem" oi ON oi.id = dp.order_item_id
JOIN "PlanItem" pi ON pi.daily_plan_id = dp.id
JOIN "Mealtime" mt ON mt.id = pi.mealtime_id
JOIN "Meal" m ON m.id = pi.meal_id
GROUP BY dp.id, dp.date, oi.recipient
ORDER BY dp.date, oi.recipient;

/* RAPORT 20 — Kompletność dziennych planów względem wariantu kalorycznego.
   Porównuje pory posiłków wymagane przez wariant z faktycznie zaplanowanymi.
   Wykrywa również pory posiłków nieprzewidziane w danym wariancie.
*/
WITH plan_completeness AS (
    SELECT
        dp.id AS daily_plan_id,
        dp.date AS plan_date,
        oi.recipient,
        oi.caloric_variant_id,
        COUNT(DISTINCT cvm.mealtime_id) AS expected_mealtimes,
        COUNT(DISTINCT pi.mealtime_id) AS actual_mealtimes,
        COUNT(DISTINCT pi.mealtime_id) FILTER (
            WHERE pi.mealtime_id IS NOT NULL
              AND EXISTS (
                  SELECT 1
                  FROM "CaloricVariantMealtime" cvm2
                  WHERE cvm2.caloric_variant_id = oi.caloric_variant_id
                    AND cvm2.mealtime_id = pi.mealtime_id
              )
        ) AS correctly_planned_mealtimes,
        COUNT(DISTINCT pi.mealtime_id) FILTER (
            WHERE pi.mealtime_id IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM "CaloricVariantMealtime" cvm2
                  WHERE cvm2.caloric_variant_id = oi.caloric_variant_id
                    AND cvm2.mealtime_id = pi.mealtime_id
              )
        ) AS unexpected_mealtimes
    FROM "DailyPlan" dp
    JOIN "OrderItem" oi ON oi.id = dp.order_item_id
    LEFT JOIN "CaloricVariantMealtime" cvm
        ON cvm.caloric_variant_id = oi.caloric_variant_id
    LEFT JOIN "PlanItem" pi ON pi.daily_plan_id = dp.id
    GROUP BY dp.id, dp.date, oi.recipient, oi.caloric_variant_id
)
SELECT
    daily_plan_id,
    plan_date,
    recipient,
    expected_mealtimes,
    actual_mealtimes,
    correctly_planned_mealtimes,
    unexpected_mealtimes,
    CASE
        WHEN expected_mealtimes = 0 THEN 'NO_MEALTIMES_DEFINED'
        WHEN correctly_planned_mealtimes = expected_mealtimes
             AND unexpected_mealtimes = 0 THEN 'COMPLETE'
        ELSE 'INCOMPLETE_OR_INVALID'
    END AS plan_quality
FROM plan_completeness
ORDER BY plan_date, recipient;

/* RAPORT 21 — Skład dań: lista składników i alergenów.
   DISTINCT w agregatach zabezpiecza przed powieleniem nazw, ponieważ obie
   tabele łącznikowe mogą tworzyć iloczyn wierszy.
*/
SELECT
    m.id AS meal_id,
    m.name AS meal_name,
    COUNT(DISTINCT mi.ingredient_id) AS ingredient_count,
    COALESCE(STRING_AGG(DISTINCT i.name, ', ' ORDER BY i.name), 'Brak danych')
        AS ingredients,
    COUNT(DISTINCT ma.allergen_id) AS allergen_count,
    COALESCE(STRING_AGG(DISTINCT a.name, ', ' ORDER BY a.name),
             'Brak przypisanych alergenów') AS allergens
FROM "Meal" m
LEFT JOIN "MealIngredient" mi ON mi.meal_id = m.id
LEFT JOIN "Ingredient" i ON i.id = mi.ingredient_id
LEFT JOIN "MealAllergen" ma ON ma.meal_id = m.id
LEFT JOIN "Allergen" a ON a.id = ma.allergen_id
GROUP BY m.id, m.name
ORDER BY allergen_count DESC, ingredient_count DESC, m.name;

/* RAPORT 22 — Najczęściej współwystępujące pary składników.
   Samopołączenie tabeli MealIngredient tworzy pary bez powtórzeń (id < id).
*/
WITH ingredient_pairs AS (
    SELECT
        i1.id AS ingredient_1_id,
        i1.name AS ingredient_1,
        i2.id AS ingredient_2_id,
        i2.name AS ingredient_2,
        COUNT(DISTINCT mi1.meal_id) AS meals_together
    FROM "MealIngredient" mi1
    JOIN "MealIngredient" mi2
      ON mi2.meal_id = mi1.meal_id
     AND mi1.ingredient_id < mi2.ingredient_id
    JOIN "Ingredient" i1 ON i1.id = mi1.ingredient_id
    JOIN "Ingredient" i2 ON i2.id = mi2.ingredient_id
    GROUP BY i1.id, i1.name, i2.id, i2.name
    HAVING COUNT(DISTINCT mi1.meal_id) >= 2
)
SELECT
    DENSE_RANK() OVER (ORDER BY meals_together DESC) AS pair_rank,
    ingredient_1,
    ingredient_2,
    meals_together
FROM ingredient_pairs
ORDER BY pair_rank, ingredient_1, ingredient_2;

/* RAPORT 23 — Pary dań pojawiające się w tych samych planach dziennych.
   Wynik pomaga analizować powtarzalne zestawienia potraw w jadłospisach.
*/
SELECT
    m1.name AS first_meal,
    m2.name AS second_meal,
    COUNT(DISTINCT pi1.daily_plan_id) AS shared_daily_plans
FROM "PlanItem" pi1
JOIN "PlanItem" pi2
  ON pi2.daily_plan_id = pi1.daily_plan_id
 AND pi1.meal_id < pi2.meal_id
JOIN "Meal" m1 ON m1.id = pi1.meal_id
JOIN "Meal" m2 ON m2.id = pi2.meal_id
GROUP BY m1.id, m1.name, m2.id, m2.name
HAVING COUNT(DISTINCT pi1.daily_plan_id) >= 2
ORDER BY shared_daily_plans DESC, first_meal, second_meal;

/* RAPORT 24 — Wykorzystanie uprawnień przez aktywnych użytkowników.
   Odsetek odnosi się do wszystkich niearchiwizowanych kont, a nie do liczby
   użytkowników posiadających jakiekolwiek uprawnienie.
*/
WITH active_user_total AS (
    SELECT COUNT(*)::NUMERIC AS total_active_users
    FROM "User"
    WHERE archived = FALSE
), permission_usage AS (
    SELECT
        p.id,
        p.code,
        p.name,
        COUNT(DISTINCT up.user_id) FILTER (WHERE u.archived = FALSE)
            AS active_users_with_permission,
        COUNT(DISTINCT up.user_id) AS all_users_with_permission
    FROM "Permission" p
    LEFT JOIN "UserPermission" up ON up.permission_id = p.id
    LEFT JOIN "User" u ON u.id = up.user_id
    GROUP BY p.id, p.code, p.name
)
SELECT
    pu.code AS permission_code,
    pu.name AS permission_name,
    pu.active_users_with_permission,
    pu.all_users_with_permission,
    aut.total_active_users,
    ROUND((100.0 * pu.active_users_with_permission
           / NULLIF(aut.total_active_users, 0))::NUMERIC, 2)
        AS percentage_of_active_users
FROM permission_usage pu
CROSS JOIN active_user_total aut
ORDER BY pu.active_users_with_permission DESC, pu.code;

/* RAPORT 25 — Obciążenie moderatorów i czas reakcji na recenzje.
   Raport łączy log moderacji z recenzją i kontem moderatora.
*/
SELECT
    u.id AS moderator_id,
    u.email AS moderator_email,
    DATE_TRUNC('month', ml.created_at)::DATE AS moderation_month,
    COUNT(*) AS moderated_reviews,
    COUNT(*) FILTER (WHERE r.moderation_status = 'VISIBLE') AS currently_visible,
    COUNT(*) FILTER (WHERE r.moderation_status = 'HIDDEN') AS currently_hidden,
    COUNT(*) FILTER (WHERE r.moderation_status = 'PENDING') AS currently_pending,
    AVG(ml.created_at - r.created_at) AS average_time_to_moderation,
    ROUND(AVG(CHAR_LENGTH(ml.moderation_note)), 1) AS average_note_length
FROM "ModerationLog" ml
JOIN "User" u ON u.id = ml.user_id
JOIN "Review" r ON r.id = ml.review_id
GROUP BY u.id, u.email, DATE_TRUNC('month', ml.created_at)::DATE
ORDER BY moderation_month DESC, moderated_reviews DESC;

/* ---------------------------------------------------------------------------
   C. FUNKCJE AGREGUJĄCE — PODSUMOWANIE PRZYKŁADÓW W SKRYPCIE

   COUNT       — liczba rekordów / elementów (raporty 02–25).
   SUM         — sumy przychodów i wartości odżywczych (02, 03, 19).
   AVG         — średnia wartość dokumentu, ocena, czas dostawy (02, 05–12).
   MIN / MAX   — skrajne kwoty, kalorie, oceny i daty (02, 05, 11, 12).
   STDDEV_POP  — odchylenie standardowe całej populacji wariantów/cen (11–13).
   STDDEV_SAMP — odchylenie standardowe próby ocen (08).
   PERCENTILE_CONT — mediana rozkładu ocen, białka i cen (08, 11, 12).
   STRING_AGG  — składniki, alergeny, obszary dostaw i harmonogram (01, 14, 19, 21).
   FILTER      — różne warunki dla agregatów w jednym zestawieniu (03, 05–08,
                 13, 15–18, 20, 24, 25).

   Uwaga interpretacyjna:
   - AVG(PESEL) ani podobne statystyki identyfikatorów nie mają sensu.
   - Wartości liczbowe agregowane są tylko tam, gdzie mają znaczenie biznesowe.
   - Schemat nie zawiera tabeli płatności częściowych ani cennika historycznego;
     raporty finansowe korzystają z kwoty i daty płatności z tabeli Billing.
   --------------------------------------------------------------------------- */
