-- 15. Częstotliwość reklamacji w relacji do liczby zamówień


WITH order_complaints AS (SELECT o.id                             AS order_id,
                                 dw.catering_company_id,
                                 TO_CHAR(o.created_at, 'YYYY-MM') AS month,
                                 COUNT(c.id)                      AS complaint_count
                          FROM "Order" o
                                   JOIN "DeliveryWindow" dw ON dw.id = o.delivery_window_id
                                   LEFT JOIN "Complaint" c ON c.order_id = o.id
                          GROUP BY o.id, dw.catering_company_id, o.created_at),
     stats AS (SELECT catering_company_id,
                      month,
                      COUNT(*)                                                             AS orders,
                      COUNT(*) FILTER (WHERE complaint_count > 0)                          AS orders_with_complaint,
                      SUM(complaint_count)                                                 AS complaints,
                      ROUND(COUNT(*) FILTER (WHERE complaint_count > 0) * 100.0
                                / NULLIF(COUNT(*), 0), 2)                                  AS pct_orders_with_complaint
               FROM order_complaints
               GROUP BY GROUPING SETS ( (catering_company_id, month),
                                        (catering_company_id)
                   ))
SELECT cc.id                                                   AS company_id,
       cc.name                                                 AS company_name,

       CASE WHEN s.month IS NULL THEN 'total' ELSE 'month' END AS row_scope,
       s.month,
       s.orders,
       s.orders_with_complaint,
       s.complaints,
       s.pct_orders_with_complaint
FROM stats s
         JOIN "CateringCompany" cc ON cc.id = s.catering_company_id

--WHERE s.complaints != s.orders_with_complaint
ORDER BY cc.name, s.month NULLS FIRST;
