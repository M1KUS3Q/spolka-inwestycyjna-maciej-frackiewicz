SELECT
    company.name,
    diet.name,
    variant.calories,
    variant.base_price_per_day,
    COALESCE(SUM(item.quantity), 0) AS total_quantity,
    COUNT(item.id) AS order_item_count,
    COUNT(DISTINCT order_.id) AS order_count,
    COUNT(DISTINCT order_.user_id) AS customer_count,
    COALESCE(ROUND(AVG(item.quantity), 2), 0) AS avg_quantity
FROM
    "CaloricVariant" variant
    LEFT JOIN "OrderItem" item ON item.caloric_variant_id = variant.id
    LEFT JOIN "Order" order_ ON order_.id = item.order_id
    LEFT JOIN "Diet" diet ON diet.id = variant.diet_id
    LEFT JOIN "CateringCompany" company ON company.id = diet.catering_company_id
GROUP BY
    company.name,
    diet.name,
    variant.id,
    variant.calories,
    variant.base_price_per_day
ORDER BY
    total_quantity DESC;
