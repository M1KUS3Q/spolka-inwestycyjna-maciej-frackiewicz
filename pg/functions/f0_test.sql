CREATE OR REPLACE FUNCTION search_catering_companies(search_query TEXT)
RETURNS TABLE (
    company_id INTEGER,
    company_name VARCHAR,
    company_description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        company.id,
        company.name,
        company.description
    FROM 
        "CateringCompany" company
    WHERE 
        company.name ILIKE '%' || search_query || '%'
        OR company.description ILIKE '%' || search_query || '%';
END;
$$ LANGUAGE plpgsql;