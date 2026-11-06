-- Example usage:
-- SELECT * FROM find_meals_without_allergens(ARRAY['Gluten', 'Laktoza', 'Jaja', 'Soja']::VARCHAR[])
CREATE OR REPLACE FUNCTION find_meals_without_allergens(
    p_allergens VARCHAR[]
)
RETURNS TABLE (
    meal_id INTEGER,
    meal_name VARCHAR,
    description TEXT,
    allergens VARCHAR[]
)
LANGUAGE plpgsql
AS $$
    SELECT
        meal.id,
        meal.name,
        meal.description,
        COALESCE(
            (
                SELECT
                    ARRAY_AGG(allergen.name ORDER BY allergen.name)
                FROM
                    "MealAllergen" meal_allergen
                    JOIN "Allergen" allergen ON allergen.id = meal_allergen.allergen_id
                WHERE
                    meal_allergen.meal_id = meal.id
            ),
            ARRAY[]::VARCHAR[]
        )
    FROM
        "Meal" meal
    WHERE
        NOT EXISTS (
            SELECT
                1
            FROM
                "MealAllergen" meal_allergen
                JOIN "Allergen" allergen ON allergen.id = meal_allergen.allergen_id
            WHERE
                meal_allergen.meal_id = meal.id
                AND allergen.name = ANY(p_allergens)
        )
    ORDER BY meal.name;
$$;

