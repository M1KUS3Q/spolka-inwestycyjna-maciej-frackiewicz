-- 16. Rozkład ocen firm cateringowych i ich wiarygodność statystyczna

WITH visible_reviews AS (SELECT r.catering_company_id,
                                r.rating
                         FROM "Review" r
                         WHERE r.moderation_status = 'VISIBLE'),
     overall AS (SELECT AVG(rating) AS avg_all_reviews,
                        10          AS prior_weight
                 FROM visible_reviews),
     stats AS (SELECT v.catering_company_id,
                      COUNT(*)                             AS reviews,
                      AVG(v.rating)                        AS avg_raw,
                      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY v.rating)
                                                           AS median_raw,
                      STDDEV_SAMP(v.rating)                AS stddev_raw,
                      COUNT(*) FILTER (WHERE v.rating = 1) AS rating_1,
                      COUNT(*) FILTER (WHERE v.rating = 2) AS rating_2,
                      COUNT(*) FILTER (WHERE v.rating = 3) AS rating_3,
                      COUNT(*) FILTER (WHERE v.rating = 4) AS rating_4,
                      COUNT(*) FILTER (WHERE v.rating = 5) AS rating_5
               FROM visible_reviews v
               GROUP BY v.catering_company_id)
SELECT cc.name,
       COALESCE(s.reviews, 0)                             AS reviews,
       ROUND(s.avg_raw::NUMERIC, 2)                       AS avg_rating,
       ROUND(((s.reviews * s.avg_raw + o.prior_weight * o.avg_all_reviews)
           / (s.reviews + o.prior_weight))::NUMERIC, 2)   AS weighted_rating,
       ROUND(s.median_raw::NUMERIC, 2)                    AS median_rating,
       ROUND(s.stddev_raw::NUMERIC, 3)                    AS stddev_rating,
       COALESCE(s.rating_1, 0)                            AS rating_1,
       COALESCE(s.rating_2, 0)                            AS rating_2,
       COALESCE(s.rating_3, 0)                            AS rating_3,
       COALESCE(s.rating_4, 0)                            AS rating_4,
       COALESCE(s.rating_5, 0)                            AS rating_5,
       CASE --sztucznie zawyzone, bo reviews wacha sie od ~100 do ~200
           WHEN COALESCE(s.reviews, 0) < 100 THEN 'small sample - unreliable'
           WHEN s.reviews < 150 THEN 'moderate sample'
           ELSE 'sufficient sample'
           END                                            AS reliability_label,
       (s.avg_raw > o.avg_all_reviews AND s.reviews < 10) AS high_rating_low_sample,
       ROUND(o.avg_all_reviews::NUMERIC, 2)               AS avg_all_companies
FROM "CateringCompany" cc
         CROSS JOIN overall o
         LEFT JOIN stats s ON s.catering_company_id = cc.id
ORDER BY weighted_rating DESC NULLS LAST, s.reviews DESC NULLS LAST, cc.name;