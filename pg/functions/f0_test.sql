CREATE OR REPLACE FUNCTION search_catering_companies(search_query TEXT)
RETURNS TABLE (
    company_id INTEGER,
    company_name VARCHAR,
    company_description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cc.id,
        cc.name,
        cc.description
    FROM 
        "CateringCompany" cc
    WHERE 
        cc.name ILIKE '%' || search_query || '%'
        OR cc.description ILIKE '%' || search_query || '%';
END;
$$ LANGUAGE plpgsql;