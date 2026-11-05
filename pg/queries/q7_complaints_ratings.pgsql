WITH review_stats AS (
    SELECT
        catering_company_id,
        COALESCE(ROUND(AVG(rating), 2), 0) AS average_rating,
        COUNT(*) AS review_count
    FROM
        "Review"
    WHERE
        moderation_status = 'VISIBLE'
    GROUP BY
        catering_company_id
),
order_stats AS (
    SELECT
        window_.catering_company_id,
        COUNT(DISTINCT order_.id) AS order_count,
        COUNT(DISTINCT complaint.order_id) AS complained_order_count
    FROM
        "Order" order_
        JOIN "DeliveryWindow" window_ ON window_.id = order_.delivery_window_id
        LEFT JOIN "Complaint" complaint ON complaint.order_id = order_.id
    GROUP BY
        window_.catering_company_id
)
SELECT
    company.id,
    company.name,
    ROUND(
        100.0 * order_stats_.complained_order_count /
        NULLIF(order_stats_.order_count, 0),
        2
    ) AS complaint_percentage,
    review_stats_.average_rating,
    COALESCE(review_stats_.review_count, 0) AS review_count,
    order_stats_.order_count,
    order_stats_.complained_order_count
FROM
    "CateringCompany" company
    JOIN order_stats order_stats_ ON order_stats_.catering_company_id = company.id
    LEFT JOIN review_stats review_stats_ ON review_stats_.catering_company_id = company.id
ORDER BY
    complaint_percentage DESC,
    average_rating ASC;


