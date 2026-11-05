with MealIngredients as (
    select 
        "MealIngredient".meal_id,
        String_agg("Ingredient".name, ', ') as ingredients_list
    from "MealIngredient"
    join "Ingredient" on "MealIngredient".ingredient_id = "Ingredient".id
    Group by
        "MealIngredient".meal_id
),
MealAllergens as (
    select 
        "MealAllergen".meal_id,
        String_agg("Allergen".name, ', ') as allergens_list
    from "MealAllergen"
    join "Allergen" on "MealAllergen".allergen_id = "Allergen".id
    Group by
        "MealAllergen".meal_id
)
select 
    "Meal".name as meal_name,
    "Mealtime".name as mealtime_name,
    "Meal".calories_kcal,
    "Meal".protein_g,
    "Meal".fat_g,
    MealIngredients.ingredients_list,
    MealAllergens.allergens_list
from "Meal"
join "MealMealtime" on "MealMealtime".meal_id = "Meal".id
join "Mealtime" on "MealMealtime".mealtime_id = "Mealtime".id
left join MealIngredients on "Meal".id = MealIngredients.meal_id
left join MealAllergens on "Meal".id = MealAllergens.meal_id
where
    "Mealtime".name = 'Obiad'
    and "Meal".calories_kcal between 400 and 800
    and "Meal".protein_g >= 30
    and "Meal".fat_g <= 20

    and exists(
            select * from "MealIngredient"
            join "Ingredient" on "MealIngredient".ingredient_id = "Ingredient".id
            where "MealIngredient".meal_id = "Meal".id and "Ingredient".name = 'Łosoś'
        )
    and not exists(
            select * from "MealIngredient"
            join "Ingredient" on "MealIngredient".ingredient_id = "Ingredient".id
            where "MealIngredient".meal_id = "Meal".id and "Ingredient".name = 'Cebula'
        )
    
    and not exists(
            select * from "MealAllergen"
            join "Allergen" on "MealAllergen".allergen_id = "Allergen".id
            where "MealAllergen".meal_id = "Meal".id and "Allergen".name = 'Sezam'
        )
    
order by 
    "Meal".calories_kcal ASC
