WITH meal_profile AS (
    SELECT m.id                         AS meal_id,
           m.name                       AS meal_name,
           mt.id                        AS mealtime_id,
           mt.name                      AS mealtime_name,
           mt.display_order,
           m.calories_kcal,
           m.protein_g,
           m.fiber_g,
           m.salt_g,
           m.protein_g * 100.0 / m.calories_kcal AS protein_per_100kcal,
           m.fiber_g   * 100.0 / m.calories_kcal AS fiber_per_100kcal,
           m.salt_g    * 100.0 / m.calories_kcal AS salt_per_100kcal,
           m.protein_g * 4 * 100.0 / m.calories_kcal AS protein_energy_pct
    FROM "Meal" m
    JOIN "MealMealtime" mm ON mm.meal_id = m.id
    JOIN "Mealtime" mt     ON mt.id = mm.mealtime_id
    WHERE m.calories_kcal > 0
),
ranked AS (
    SELECT mp.*,
           RANK() OVER (PARTITION BY mealtime_id
                        ORDER BY protein_per_100kcal DESC) AS protein_rank,
           NTILE(4) OVER (PARTITION BY mealtime_id
                          ORDER BY salt_per_100kcal)       AS salt_quartile,
           COUNT(*) OVER (PARTITION BY mealtime_id)        AS meals_in_mealtime
    FROM meal_profile mp
)
SELECT mealtime_name,
       protein_rank                     AS rank_in_mealtime,
       meals_in_mealtime,
       meal_name,
       calories_kcal,
       ROUND(protein_per_100kcal, 2)    AS protein_g_per_100kcal,
       ROUND(protein_energy_pct, 1)     AS protein_energy_pct,
       ROUND(fiber_per_100kcal, 2)      AS fiber_g_per_100kcal,
       ROUND(salt_per_100kcal, 3)       AS salt_g_per_100kcal,
       CASE salt_quartile WHEN 1 THEN 'niska' WHEN 4 THEN 'wysoka' ELSE 'średnia' END
                                        AS zawartosc_soli
FROM ranked
WHERE protein_rank <= 5
ORDER BY display_order, protein_rank;