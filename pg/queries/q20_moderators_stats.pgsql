select
    "User".first_name,
    "User".last_name,
    Count("ModerationLog".id) as handled_reviews,
    Avg("ModerationLog".created_at - "Review".created_at) as average_handle_time,
    percentile_cont(0.5) within GROUP (ORDER BY ("ModerationLog".created_at - "Review".created_at)) AS median_handle_time,
    Count("Review".id) filter (where "Review".moderation_status = 'VISIBLE') as visible_reviews,
    Count("Review".id) filter (where "Review".moderation_status = 'HIDDEN') as hidden_reviews
from "ModerationLog"
join "Review" on "ModerationLog".review_id = "Review".id
join "User" on "ModerationLog".user_id = "User".id
group by
    "User".id,
    "User".first_name,
    "User".last_name