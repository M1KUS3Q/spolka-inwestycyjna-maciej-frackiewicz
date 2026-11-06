-- Example usage:
-- SELECT * FROM find_companies('00-001', '09:00', '12:00');
CREATE OR REPLACE FUNCTION find_companies(
    p_postal_code postal_code,
    p_start_time TIME,
    p_end_time TIME
)
RETURNS TABLE (
    company_id INTEGER,
    company_name VARCHAR,
    contact_email VARCHAR,
    contact_phone VARCHAR,
    verification_status VARCHAR,
    matching_delivery_windows TEXT[],
    active_diet_count BIGINT
)
LANGUAGE sql
AS $$
    SELECT
        company.id,
        company.name,
        company.contact_email,
        company.contact_phone,
        company.verification_status,

        ARRAY_AGG(
            window_.start_time::TEXT || ' - ' || window_.end_time::TEXT
            ORDER BY
                window_.start_time::TEXT || ' - ' || window_.end_time::TEXT
        ),

        COUNT(diet.id)
    FROM
        "CateringCompany" company
        JOIN "CateringCompanyPostalCode" company_code ON company_code.catering_company_id = company.id
        JOIN "PostalCode" code ON code.id = company_code.postal_code_id
        JOIN "DeliveryWindow" window_ ON window_.catering_company_id = company.id
        JOIN "Diet" diet ON diet.catering_company_id = company.id
    WHERE
        code.code = p_postal_code
        AND company.verification_status = 'VERIFIED'
        AND window_.start_time < p_end_time
        AND window_.end_time > p_start_time
    GROUP BY
        company.id,
        company.name,
        company.contact_email,
        company.contact_phone,
        company.verification_status
    ORDER BY company.name;
$$;
