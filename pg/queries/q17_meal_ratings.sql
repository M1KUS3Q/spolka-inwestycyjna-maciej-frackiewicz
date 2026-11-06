-- 17. Oceny poszczególnych posiłków w opiniach klientów

WITH reviewed AS (
    SELECT r.meal_id,
           r.catering_company_id,
           r.rating
    FROM "Review" r
    WHERE r.moderation_status = 'VISIBLE'
      AND r.meal_id IS NOT NULL
),
meal_company AS (
    SELECT meal_id,
           catering_company_id,
           COUNT(*)                                         AS reviews,
           AVG(rating)                                      AS avg_raw,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating)
                                                            AS median_raw
    FROM reviewed
    GROUP BY meal_id, catering_company_id
),
meal_overall AS (
    SELECT meal_id,
           COUNT(*)                                         AS reviews,
           AVG(rating)                                      AS avg_raw,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating)
                                                            AS median_raw,
           COUNT(DISTINCT catering_company_id)              AS companies_reviewing,
           RANK() OVER (ORDER BY AVG(rating) DESC, COUNT(*) DESC)
                                                            AS meal_rank
    FROM reviewed
    GROUP BY meal_id
),
company_all_meals AS (
    SELECT catering_company_id,
           COUNT(*)                                         AS reviews,
           COUNT(DISTINCT meal_id)                          AS meals_reviewed,
           AVG(rating)                                      AS avg_raw
    FROM reviewed
    GROUP BY catering_company_id
)
--ukrylem mediany, bo przy tak niskich liczbach review jednak mija sie to z celem, a jest duzo danych juz i tak
SELECT m.name                                               AS meal_name,
       cc.name                                              AS company_name,
       mc.reviews                                           AS meal_company_reviews,
       ROUND(mc.avg_raw::numeric, 2)                        AS meal_company_avg_rating,
      -- ROUND(mc.median_raw::numeric, 2)                     AS meal_company_median_rating,
       mo.reviews                                           AS meal_overall_reviews,
       ROUND(mo.avg_raw::numeric, 2)                        AS meal_overall_avg_rating,
      -- ROUND(mo.median_raw::numeric, 2)                     AS meal_overall_median_rating,
       mo.companies_reviewing                               AS meal_companies_reviewing,
       ca.reviews                                           AS company_all_meals_reviews,
       ca.meals_reviewed                                    AS company_meals_reviewed,
       ROUND(ca.avg_raw::numeric, 2)                        AS company_all_meals_avg_rating,
       mo.meal_rank                                         AS meal_overall_rank
FROM meal_company mc
JOIN meal_overall mo        ON mo.meal_id = mc.meal_id
JOIN company_all_meals ca   ON ca.catering_company_id = mc.catering_company_id
JOIN "Meal" m               ON m.id = mc.meal_id
JOIN "CateringCompany" cc   ON cc.id = mc.catering_company_id
ORDER BY mo.meal_rank, cc.name;