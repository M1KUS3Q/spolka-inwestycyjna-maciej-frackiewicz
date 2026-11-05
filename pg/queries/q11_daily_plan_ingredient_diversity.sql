WITH plan_diversity AS (
    SELECT dp.id                          AS plan_id,
           oi.caloric_variant_id,
           COUNT(DISTINCT mi.ingredient_id) AS distinct_ingredients
    FROM "DailyPlan" dp
    JOIN "OrderItem" oi       ON oi.id = dp.order_item_id
    JOIN "PlanItem" pi        ON pi.daily_plan_id = dp.id
    JOIN "MealIngredient" mi  ON mi.meal_id = pi.meal_id
    GROUP BY dp.id, oi.caloric_variant_id
)
SELECT cc.name                         AS company_name,
       d.name                          AS diet_name,
       cv.calories                     AS variant_kcal,
       COUNT(*)                        AS plans,
       ROUND(AVG(pd.distinct_ingredients), 2) AS avg_ingredients,
       PERCENTILE_CONT(0.5) WITHIN GROUP
           (ORDER BY pd.distinct_ingredients) AS median_ingredients,
       MIN(pd.distinct_ingredients)    AS min_ingredients,
       MAX(pd.distinct_ingredients)    AS max_ingredients
FROM plan_diversity pd
JOIN "CaloricVariant" cv   ON cv.id = pd.caloric_variant_id
JOIN "Diet" d              ON d.id = cv.diet_id
JOIN "CateringCompany" cc  ON cc.id = d.catering_company_id
GROUP BY d.id, cc.name, d.name, cv.id, cv.calories
ORDER BY avg_ingredients DESC;