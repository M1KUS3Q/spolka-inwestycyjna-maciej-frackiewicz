CREATE OR REPLACE FUNCTION search_diets(
    p_min_kcal    integer DEFAULT NULL,
    p_max_kcal    integer DEFAULT NULL,
    p_max_price   numeric DEFAULT NULL,
    p_company_id  bigint  DEFAULT NULL,   -- NULL = any company
    p_is_active   boolean DEFAULT TRUE,   -- NULL = active and inactive
    p_target_kcal integer DEFAULT NULL    -- NULL = sort by price
)
RETURNS TABLE (
    company_id       bigint,
    company_name     text,
    diet_id          bigint,
    diet_name        text,
    diet_description text,
    is_active        boolean,
    variant_id       bigint,
    calories         integer,
    price_per_day    numeric,
    kcal_diff        integer
)
LANGUAGE sql STABLE AS $$
    SELECT cc.id::bigint,
           cc.name::text,
           d.id::bigint,
           d.name::text,
           d.description::text,
           d.is_active,
           cv.id::bigint,
           cv.calories::integer,
           cv.base_price_per_day::numeric,
           (cv.calories - p_target_kcal)::integer
    FROM "CaloricVariant" cv
    JOIN "Diet" d             ON d.id = cv.diet_id
    JOIN "CateringCompany" cc ON cc.id = d.catering_company_id
    WHERE cc.verification_status = 'VERIFIED'
      AND (p_min_kcal   IS NULL OR cv.calories <= p_max_kcal OR p_max_kcal IS NULL)
      AND (p_min_kcal   IS NULL OR cv.calories >= p_min_kcal)
      AND (p_max_kcal   IS NULL OR cv.calories <= p_max_kcal)
      AND (p_max_price  IS NULL OR cv.base_price_per_day <= p_max_price)
      AND (p_company_id IS NULL OR cc.id = p_company_id)
      AND (p_is_active  IS NULL OR d.is_active = p_is_active)
    ORDER BY ABS(cv.calories - p_target_kcal) NULLS LAST,
             cv.base_price_per_day,
             cc.name,
             d.name
$$;