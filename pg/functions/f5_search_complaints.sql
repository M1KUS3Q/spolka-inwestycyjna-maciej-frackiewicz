-- 5. Wyszukiwanie reklamacji według treści i przebiegu obsługi

CREATE OR REPLACE FUNCTION search_complaints(
    p_query       TEXT      DEFAULT NULL,
    p_user_id     INTEGER   DEFAULT NULL,
    p_company_id  INTEGER   DEFAULT NULL,
    p_status      VARCHAR   DEFAULT NULL,
    p_date_from   TIMESTAMP DEFAULT NULL,
    p_date_to     TIMESTAMP DEFAULT NULL,
    p_delivery_id INTEGER   DEFAULT NULL,
    p_resolved    BOOLEAN   DEFAULT NULL, -- Czy ticket został rozwiązany
    p_limit       INTEGER   DEFAULT 50    -- Limit wyników
)
RETURNS TABLE (
    complaint_id           INTEGER,
    subject                VARCHAR,
    description            TEXT,
    complaint_status       VARCHAR,
    decision_justification TEXT,
    created_at             TIMESTAMP,
    resolved_at            TIMESTAMP,
    user_email             VARCHAR,
    order_id               INTEGER,
    order_status           VARCHAR,
    delivery_id            INTEGER,
    delivery_status        VARCHAR,
    scheduled_date         DATE,
    delivered_at           TIMESTAMP,
    company_name           VARCHAR,
    relevance              REAL
)
LANGUAGE sql STABLE
AS $$
    SELECT
        c.id,
        c.subject,
        c.description,
        c.status,
        c.decision_justification,
        c.created_at,
        c.resolved_at,
        u.email,
        o.id,
        o.status,
        d.id,
        d.status,
        d.scheduled_date,
        d.delivered_at,
        cc.name,
        CASE
            WHEN p_query IS NULL OR length(trim(p_query)) = 0 THEN 0
            WHEN LOWER(c.subject)     LIKE '%' || LOWER(trim(p_query)) || '%' THEN 2
            WHEN LOWER(c.description) LIKE '%' || LOWER(trim(p_query)) || '%' THEN 1
            ELSE 0
        END::REAL AS relevance
    FROM "Complaint" c
    JOIN "Order" o            ON o.id = c.order_id
    JOIN "User" u             ON u.id = c.user_id
    JOIN "DeliveryWindow" dw  ON dw.id = o.delivery_window_id
    JOIN "CateringCompany" cc ON cc.id = dw.catering_company_id
    LEFT JOIN "Delivery" d    ON d.id = c.delivery_id
    WHERE
        (
            p_query IS NULL
            OR length(trim(p_query)) = 0
            OR LOWER(c.subject)     LIKE '%' || LOWER(trim(p_query)) || '%'
            OR LOWER(c.description) LIKE '%' || LOWER(trim(p_query)) || '%'
        )
        AND (p_user_id IS NULL OR c.user_id = p_user_id)
        AND (p_company_id IS NULL OR dw.catering_company_id = p_company_id)
        AND (p_status IS NULL OR c.status = p_status)
        AND (p_date_from IS NULL OR c.created_at >= p_date_from)
        AND (p_date_to IS NULL OR c.created_at <= p_date_to)
        AND (p_delivery_id IS NULL OR c.delivery_id = p_delivery_id)
        AND (p_resolved IS NULL OR (c.resolved_at IS NOT NULL) = p_resolved)
    ORDER BY
        relevance DESC,
        c.created_at DESC,
        c.id DESC
    LIMIT COALESCE(p_limit, 50);
$$;

-- Przykład użycia:
-- SELECT * FROM search_complaints(p_query => 'spóź', p_resolved => FALSE);