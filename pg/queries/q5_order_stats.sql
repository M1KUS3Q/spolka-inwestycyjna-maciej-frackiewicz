SELECT
    company_id,
    company_name,

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

        COUNT(*) AS order_count,
        COUNT(*) FILTER (WHERE order_.status = 'COMPLETED') AS completed_count,
        COUNT(*) FILTER (WHERE order_.status = 'NEW') AS new_count,
        COUNT(*) FILTER (WHERE order_.status = 'IN_PROGRESS') AS in_progress_count,
        COUNT(*) FILTER (WHERE order_.status = 'CONFIRMED') AS confirmed_count,
        COUNT(*) FILTER (WHERE order_.status = 'PAID') AS paid_count,
        COUNT(*) FILTER (WHERE order_.status = 'CANCELLED') AS cancelled_count
    FROM 
        "Order" order_
        INNER JOIN "DeliveryWindow" window ON window.id = order_.delivery_window_id
        INNER JOIN "CateringCompany" company ON company.id = window.catering_company_id
    GROUP BY 
        company.id, 
        company.name
) AS stats;
