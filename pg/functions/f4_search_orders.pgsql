CREATE OR REPLACE FUNCTION search_orders(
    p_user_id         INTEGER   DEFAULT NULL,
    p_email_fragment  TEXT      DEFAULT NULL,
    p_created_from    TIMESTAMP DEFAULT NULL,
    p_created_to      TIMESTAMP DEFAULT NULL,
    p_statuses        VARCHAR[] DEFAULT NULL,
    p_delivery_status VARCHAR   DEFAULT NULL,
    p_delivery_id     INTEGER   DEFAULT NULL,
    p_document_number VARCHAR   DEFAULT NULL,
    p_has_complaint   BOOLEAN   DEFAULT NULL
)
RETURNS TABLE (
    order_id             INTEGER,
    order_status         VARCHAR,
    created_at           TIMESTAMP,
    user_id              INTEGER,
    client_email         VARCHAR,
    client_name          TEXT,
    company_name         VARCHAR,
    delivery_window      TEXT,
    delivery_postal_code CHAR(6),
    delivery_city        VARCHAR,
    delivery_street      TEXT,
    has_complaint        BOOLEAN
)
LANGUAGE sql STABLE
AS $$
    SELECT
        o.id,
        o.status,
        o.created_at,
        u.id,
        u.email,
        u.first_name || ' ' || u.last_name,
        cc.name,
        dw.start_time::TEXT || ' - ' || dw.end_time::TEXT,
        pc.code,
        da.city,
        da.street || ' ' || da.building_number
            || COALESCE('/' || da.apartment_number, ''),
        EXISTS (SELECT 1 FROM "Complaint" c WHERE c.order_id = o.id)
    FROM "Order" o
    JOIN "User" u                 ON u.id = o.user_id
    JOIN "DeliveryAddress" da     ON da.id = o.delivery_address_id
    JOIN "PostalCode" pc          ON pc.id = da.postal_code_id
    JOIN "DeliveryWindow" dw      ON dw.id = o.delivery_window_id
    JOIN "CateringCompany" cc     ON cc.id = dw.catering_company_id
    WHERE
        (p_user_id IS NULL OR o.user_id = p_user_id)
        AND (p_email_fragment IS NULL OR u.email ILIKE '%' || p_email_fragment || '%')
        AND (p_created_from IS NULL OR o.created_at >= p_created_from)
        AND (p_created_to IS NULL OR o.created_at < p_created_to)
        AND (p_statuses IS NULL OR o.status = ANY(p_statuses))
        AND (
            p_delivery_status IS NULL
            OR EXISTS (
                SELECT 1 FROM "Delivery" d
                WHERE d.order_id = o.id AND d.status = p_delivery_status
            )
        )
        AND (
            p_delivery_id IS NULL
            OR EXISTS (
                SELECT 1 FROM "Delivery" d
                WHERE d.order_id = o.id AND d.id = p_delivery_id
            )
        )
        AND (
            p_document_number IS NULL
            OR EXISTS (
                SELECT 1 FROM "Billing" b
                WHERE b.order_id = o.id AND b.document_number = p_document_number
            )
        )
        AND (
            p_has_complaint IS NULL
            OR EXISTS (SELECT 1 FROM "Complaint" c WHERE c.order_id = o.id) = p_has_complaint
        )
    ORDER BY o.created_at DESC, o.id DESC;
$$;

-- Przykład użycia:
-- SELECT * FROM search_orders(p_email_fragment => 'gmail', p_has_complaint => TRUE);