WITH saved AS (
    -- saved adresses
    SELECT da.postal_code_id,
           da.city,
           COUNT(DISTINCT da.id)       AS saved_addresses,
           COUNT(DISTINCT uda.user_id) AS clients_with_address
    FROM "DeliveryAddress" da
    JOIN "UserDeliveryAddress" uda ON uda.delivery_address_id = da.id
    JOIN "UserPermission" up       ON up.user_id = uda.user_id
    JOIN "Permission" p            ON p.id = up.permission_id AND p.code = 'CLIENT'
    GROUP BY da.postal_code_id, da.city
),
orders_per_client AS (
    SELECT da.postal_code_id, da.city, o.user_id, COUNT(*) AS orders
    FROM "Order" o
    JOIN "DeliveryAddress" da ON da.id = o.delivery_address_id
    WHERE o.status <> 'CANCELLED'
    GROUP BY da.postal_code_id, da.city, o.user_id
),
activity AS (
    SELECT postal_code_id,
           city,
           SUM(orders)           AS orders,
           COUNT(*)              AS ordering_clients,
           ROUND(AVG(orders), 2) AS avg_orders_per_client,
           MAX(orders)           AS max_orders_single_client
    FROM orders_per_client
    GROUP BY postal_code_id, city
),
used_addresses AS (
    SELECT da.postal_code_id,
           da.city,
           COUNT(DISTINCT o.delivery_address_id) AS used_addresses
    FROM "Order" o
    JOIN "DeliveryAddress" da ON da.id = o.delivery_address_id
    WHERE o.status <> 'CANCELLED'
    GROUP BY da.postal_code_id, da.city
)
SELECT s.city,
       pc.code                                      AS postal_code,
       s.saved_addresses,
       s.clients_with_address,
       RANK() OVER (ORDER BY s.clients_with_address DESC) AS client_rank,
       COALESCE(a.orders, 0)                        AS orders,
       COALESCE(a.ordering_clients, 0)              AS ordering_clients,
       COALESCE(a.avg_orders_per_client, 0)         AS avg_orders_per_client,
       COALESCE(a.max_orders_single_client, 0)      AS max_orders_single_client,
       COALESCE(u.used_addresses, 0)                AS used_addresses,
       ROUND(COALESCE(u.used_addresses, 0) * 100.0 / s.saved_addresses, 1)
                                                    AS pct_addresses_used,
       ROUND(COALESCE(a.orders, 0)::numeric / s.saved_addresses, 2)
                                                    AS orders_per_saved_address
FROM saved s
JOIN "PostalCode" pc       ON pc.id = s.postal_code_id
LEFT JOIN activity a       ON a.postal_code_id = s.postal_code_id AND a.city = s.city
LEFT JOIN used_addresses u ON u.postal_code_id = s.postal_code_id AND u.city = s.city
ORDER BY s.clients_with_address DESC, orders DESC, s.city, pc.code;