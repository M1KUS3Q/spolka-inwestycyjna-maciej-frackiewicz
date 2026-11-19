WITH total_meals AS (SELECT COUNT(*) AS total
                     FROM "Meal"),
     allergen_overall AS (SELECT ma.allergen_id,
                                 COUNT(DISTINCT ma.meal_id) AS meals_with_allergen,
                                 COUNT(*)                   AS assignments
                          FROM "MealAllergen" ma
                          GROUP BY ma.allergen_id),
     mealtime_totals AS (SELECT mm.mealtime_id,
                                COUNT(DISTINCT mm.meal_id) AS meals_in_mealtime
                         FROM "MealMealtime" mm
                         GROUP BY mm.mealtime_id),
     allergen_mealtime AS (SELECT ma.allergen_id,
                                  mm.mealtime_id,
                                  COUNT(DISTINCT ma.meal_id) AS meals_with_allergen
                           FROM "MealAllergen" ma
                                    JOIN "MealMealtime" mm ON mm.meal_id = ma.meal_id
                           GROUP BY ma.allergen_id, mm.mealtime_id)
SELECT a.name                               AS allergen,
       COALESCE(ao.meals_with_allergen, 0)  AS meals_with_allergen,
       ROUND(COALESCE(ao.meals_with_allergen, 0) * 100.0 / NULLIF(t.total, 0), 2)
                                            AS pct_of_all_meals,
       COALESCE(ao.assignments, 0)          AS allergen_assignments,
       mt.name                              AS mealtime,
       COALESCE(amt.meals_with_allergen, 0) AS meals_with_allergen_in_mealtime,
       mtot.meals_in_mealtime,
       ROUND(COALESCE(amt.meals_with_allergen, 0) * 100.0 / NULLIF(mtot.meals_in_mealtime, 0), 2)
                                            AS pct_of_mealtime_meals,
       DENSE_RANK()                            OVER (ORDER BY COALESCE(ao.meals_with_allergen, 0) DESC)
                                                           AS allergen_rank
FROM "Allergen" a
         CROSS JOIN "Mealtime" mt
         CROSS JOIN total_meals t
         LEFT JOIN allergen_overall ao ON ao.allergen_id = a.id
         JOIN mealtime_totals mtot ON mtot.mealtime_id = mt.id
         LEFT JOIN allergen_mealtime amt ON amt.allergen_id = a.id
    AND amt.mealtime_id = mt.id
ORDER BY COALESCE(ao.meals_with_allergen, 0) DESC, a.name, mt.display_order;
