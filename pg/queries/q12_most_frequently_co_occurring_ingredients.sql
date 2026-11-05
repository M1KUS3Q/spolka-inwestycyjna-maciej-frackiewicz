WITH total AS (
    SELECT COUNT(DISTINCT meal_id) AS total_meals
    FROM "MealIngredient"
),
ingredient_counts AS (
    SELECT ingredient_id, COUNT(DISTINCT meal_id) AS meals_with_ingredient
    FROM "MealIngredient"
    GROUP BY ingredient_id
),
pairs AS (
    SELECT a.ingredient_id AS ingredient_a,
           b.ingredient_id AS ingredient_b,
           COUNT(DISTINCT a.meal_id) AS meals_with_both
    FROM "MealIngredient" a
    JOIN "MealIngredient" b
      ON b.meal_id = a.meal_id
     AND a.ingredient_id < b.ingredient_id
    GROUP BY a.ingredient_id, b.ingredient_id
)
SELECT ia.name AS ingredient_a,
       ib.name AS ingredient_b,
       p.meals_with_both,
       ROUND(p.meals_with_both * 100.0 / t.total_meals, 2) AS co_occurrence_pct,
       ROUND(p.meals_with_both::numeric
             / (ca.meals_with_ingredient + cb.meals_with_ingredient - p.meals_with_both), 4)
                                                          AS jaccard
FROM pairs p
CROSS JOIN total t
JOIN "Ingredient" ia ON ia.id = p.ingredient_a
JOIN "Ingredient" ib ON ib.id = p.ingredient_b
JOIN ingredient_counts ca ON ca.ingredient_id = p.ingredient_a
JOIN ingredient_counts cb ON cb.ingredient_id = p.ingredient_b
ORDER BY p.meals_with_both DESC, jaccard DESC
LIMIT 20;