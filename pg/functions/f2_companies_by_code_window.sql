CREATE OR REPLACE FUNCTION find_companies(
    p_postal_code postal_code,
    p_start_time TIME,
    p_end_time TIME,
)
RETURNS TABLE (
    company_id INTEGER,
    company_name VARCHAR,
    contact_email VARCHAR,
    contact_phone VARCHAR,
    verification_status VARCHAR,
    delivery_windows TEXT[],
    active_diet_count BIGINT
)
AS $$
BEGIN
    IF p_start_time >= p_end_time THEN
        RAISE EXCEPTION 'p_start_time >= p_end_time';
    END IF;

    RETURN QUERY
    WITH diet_count AS (
        SELECT
            COUNT(diet.id)
        FROM
            "Diet" diet
        WHERE
            diet.catering_company_id = company.id
            AND diet.is_active = TRUE
    )
    SELECT
        company.id,
        company.name,
        company.contact_email,
        company.contact_phone,
        company.verification_status,

        ARRAY_AGG(
            DISTINCT (
                window.start_time::TEXT || ' - ' ||
                window.end_time::TEXT
            )
            ORDER BY (
                window.start_time::TEXT || ' - ' ||
                window.end_time::TEXT
            )
        ),
        
        diet_count
    FROM
        "CateringCompany" company
        JOIN "CateringCompanyPostalCode" company_code ON company_code.catering_company_id = company.id
        JOIN "PostalCode" code ON code.id = company_code.postal_code_id
        JOIN "DeliveryWindow" window ON window.catering_company_id = company.id
    WHERE
        code.code = p_postal_code
        AND window.start_time <= p_start_time
        AND window.end_time >= p_end_time
        AND company.verification_status = 'VERIFIED'
    GROUP BY
        company.id,
        company.name,
        company.contact_email,
        company.contact_phone,
        company.verification_status
    ORDER BY company.name;
END;
$$;