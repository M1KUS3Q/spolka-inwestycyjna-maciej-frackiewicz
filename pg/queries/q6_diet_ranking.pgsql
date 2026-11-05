SELECT
    company.name AS company_name,
    diet.name AS diet_name,

    COUNT(DISTINCT order_.id) AS order_count,
    COALESCE(SUM(item.quantity), 0) AS item_sum,
    COUNT(DISTINCT order_.user_id) AS client_count,

    ROUND(
        COALESCE(SUM(item.quantity), 0)::NUMERIC /
        NULLIF(COUNT(DISTINCT order_.id), 0),
        2
    ) AS avg_items_per_order
FROM
    "Diet" diet
    JOIN "CateringCompany" company ON company.id = diet.catering_company_id
    LEFT JOIN "CaloricVariant" variant ON variant.diet_id = diet.id
    JOIN "OrderItem" item ON item.caloric_variant_id = variant.id
    LEFT JOIN "Order" order_ ON order_.id = item.order_id
GROUP BY
    company.id,
    company.name,
    diet.id,
    diet.name
ORDER BY
    item_sum DESC,
    company.name,
    diet.name;