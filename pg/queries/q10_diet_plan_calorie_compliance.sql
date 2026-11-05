WITH plan_totals AS (
    SELECT dp.id                 AS plan_id,
           oi.caloric_variant_id,
           SUM(m.calories_kcal)  AS plan_kcal
    FROM "DailyPlan" dp
    JOIN "OrderItem" oi ON oi.id = dp.order_item_id
    JOIN "PlanItem" pi  ON pi.daily_plan_id = dp.id
    JOIN "Meal" m       ON m.id = pi.meal_id
    GROUP BY dp.id, oi.caloric_variant_id
),
deviations AS (
    SELECT pt.plan_id,
           cc.name                AS company_name,
           d.id                   AS diet_id,
           d.name                 AS diet_name,
           cv.calories            AS declared_kcal,
           pt.plan_kcal,
           pt.plan_kcal - cv.calories                         AS deviation_kcal,
           (pt.plan_kcal - cv.calories) * 100.0 / cv.calories AS deviation_pct
    FROM plan_totals pt
    JOIN "CaloricVariant" cv   ON cv.id = pt.caloric_variant_id
    JOIN "Diet" d              ON d.id = cv.diet_id
    JOIN "CateringCompany" cc  ON cc.id = d.catering_company_id
)
SELECT company_name,
       diet_name,
       declared_kcal,
       COUNT(*)                                              AS plans,
       ROUND(AVG(deviation_kcal), 1)                         AS avg_deviation_kcal,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
             (ORDER BY deviation_kcal)::numeric, 1)          AS median_deviation_kcal,
       ROUND(AVG(deviation_pct), 2)                          AS avg_error_pct,
       ROUND(AVG(ABS(deviation_pct)), 2)                     AS avg_abs_error_pct,
       ROUND(COUNT(*) FILTER (WHERE ABS(deviation_pct) <= 10)
             * 100.0 / COUNT(*), 1)                          AS share_within_10pct
FROM deviations
GROUP BY diet_id, company_name, diet_name, declared_kcal
ORDER BY share_within_10pct DESC, company_name, diet_name, declared_kcal;