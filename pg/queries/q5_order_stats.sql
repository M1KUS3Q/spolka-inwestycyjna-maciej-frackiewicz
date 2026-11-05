SELECT
    company_id,
    company_name,
    order_count,

    completed_count,
    ROUND(100.0 * completed_count / NULLIF(order_count, 0), 2) AS completed_percent,

    new_count,
    ROUND(100.0 * new_count / NULLIF(order_count, 0), 2) AS new_percent,

    in_progress_count,
    ROUND(100.0 * in_progress_count / NULLIF(order_count, 0), 2) AS in_progress_percent,

    confirmed_count,
    ROUND(100.0 * confirmed_count / NULLIF(order_count, 0), 2) AS confirmed_percent,

    paid_count,
    ROUND(100.0 * paid_count / NULLIF(order_count, 0), 2) AS paid_percent,

    cancelled_count,
    ROUND(100.0 * cancelled_count / NULLIF(order_count, 0), 2) AS cancelled_percent

FROM (
    SELECT 
        company.id AS company_id,
        company.name AS company_name,

        COUNT(order_.id) AS order_count,
        COUNT(order_.id) FILTER (WHERE order_.status = 'COMPLETED') AS completed_count,
        COUNT(order_.id) FILTER (WHERE order_.status = 'NEW') AS new_count,
        COUNT(order_.id) FILTER (WHERE order_.status = 'IN_PROGRESS') AS in_progress_count,
        COUNT(order_.id) FILTER (WHERE order_.status = 'CONFIRMED') AS confirmed_count,
        COUNT(order_.id) FILTER (WHERE order_.status = 'PAID') AS paid_count,
        COUNT(order_.id) FILTER (WHERE order_.status = 'CANCELLED') AS cancelled_count
    FROM 
        "CateringCompany" company
        LEFT JOIN "DeliveryWindow" window_ ON window_.catering_company_id = company.id
        LEFT JOIN "Order" order_ ON order_.delivery_window_id = window_.id
    GROUP BY 
        company.id, 
        company.name
    ORDER BY
        company.id
) AS stats;




