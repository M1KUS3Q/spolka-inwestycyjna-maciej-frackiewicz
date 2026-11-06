SELECT
    EXTRACT(MONTH FROM date.scheduled_date) AS month_,
    COUNT(date.id) AS deliveries_count,
    COUNT(DISTINCT order_.user_id) AS active_clients,
    ROUND(
        COUNT(date.id)::NUMERIC
        / COUNT(DISTINCT order_.user_id),
        2
    ) AS avg_deliveries_per_client
FROM
    "Delivery" date
JOIN
    "Order" order_ ON order_.id = date.order_id
WHERE
    date.scheduled_date >= DATE '2025-01-01'
    AND date.scheduled_date < DATE '2026-01-01'
GROUP BY
    EXTRACT(MONTH FROM date.scheduled_date)
ORDER BY
    month_;