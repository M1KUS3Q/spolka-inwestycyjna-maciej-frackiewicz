SELECT
    EXTRACT(MONTH FROM d.scheduled_date) AS month,
    COUNT(d.id) AS deliveries_count,
    COUNT(DISTINCT o.user_id) AS active_clients,
    ROUND(
        COUNT(d.id)::NUMERIC
        / COUNT(DISTINCT o.user_id),
        2
    ) AS avg_deliveries_per_client
FROM "Delivery" d
JOIN "Order" o
    ON o.id = d.order_id
WHERE d.scheduled_date >= DATE '2025-01-01'
  AND d.scheduled_date < DATE '2026-01-01'
GROUP BY EXTRACT(MONTH FROM d.scheduled_date)
ORDER BY month;