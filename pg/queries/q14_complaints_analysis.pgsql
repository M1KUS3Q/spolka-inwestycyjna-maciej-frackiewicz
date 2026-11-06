-- 14. Analiza reklamacji według przedmiotu i czasu rozpatrywania
WITH complaint_base AS (SELECT c.id,
                               c.subject,
                               c.status,
                               to_char(c.created_at, 'YYYY-MM') AS month, -- to tez jest posgresowe
                               c.resolved_at,
                               EXTRACT(EPOCH FROM (c.resolved_at - c.created_at)) / 86400.0 -- nie uzywam days dla dokladnosci dalszych obliczen (avg itp)
                                                                AS resolution_days
                        FROM "Complaint" c)
SELECT month,
       subject,

       COUNT(*)                                                              AS total_complaints,
       COUNT(*) FILTER (WHERE status = 'RESOLVED')                           AS resolved_count,
       COUNT(*) FILTER (WHERE status != 'RESOLVED' and status != 'REJECTED') AS unresolved_count,
       COUNT(*) FILTER (WHERE status = 'REJECTED')                           AS rejected_count,


       ROUND(AVG(resolution_days) FILTER (WHERE resolved_at IS NOT NULL)::numeric, 2) -- ::numeric jest postgresa
                                                                             AS avg_resolution_days,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_days)
             FILTER (WHERE resolved_at IS NOT NULL)::numeric, 2)
                                                                             AS median_resolution_days,
       ROUND(MAX(resolution_days) FILTER (WHERE resolved_at IS NOT NULL)::numeric, 2)
                                                                             AS max_resolution_days,

       COUNT(*) FILTER (WHERE status = 'RESOLVED')                           AS status_resolved_count,

       ROUND(COUNT(*) FILTER (WHERE status = 'RESOLVED') * 100.0
                 / NULLIF(COUNT(*), 0), 2)                                   AS pct_resolved,

       ROUND(COUNT(*) FILTER (WHERE status = 'REJECTED') * 100.0
                 / NULLIF(COUNT(*), 0), 2)                                   AS pct_rejected

FROM complaint_base
GROUP BY month, subject
ORDER BY month, subject;