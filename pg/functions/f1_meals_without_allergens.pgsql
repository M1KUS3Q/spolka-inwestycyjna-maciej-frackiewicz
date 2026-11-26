-- Example usage:
-- SELECT * FROM find_meals_without_allergens(ARRAY['Soja']::VARCHAR[])
CREATE OR REPLACE FUNCTION find_meals_without_allergens(
    p_allergens VARCHAR[]
)
RETURNS TABLE (
    meal_id INTEGER,
    meal_name VARCHAR,
    description TEXT,
    allergens VARCHAR[]
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        meal.id,
        meal.name,
        meal.description,
        COALESCE(
            array_agg(a.name ORDER BY a.name) FILTER (WHERE a.id IS NOT NULL),
            ARRAY[]::VARCHAR[]
        )
    FROM
        "Meal" meal
        LEFT JOIN "MealAllergen" ma ON ma.meal_id = meal.id
        LEFT JOIN "Allergen" a ON a.id = ma.allergen_id
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM "MealAllergen" ma2
            JOIN "Allergen" a2 ON a2.id = ma2.allergen_id
            WHERE ma2.meal_id = meal.id
              AND a2.name = ANY(p_allergens)
        )
    GROUP BY meal.id
    ORDER BY meal.name;
$$;
