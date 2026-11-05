with CompanyReviews as (
    select 
        catering_company_id, 
        AVG(rating) as Average_review
    from 
        "Review"
    where
        moderation_status = 'VISIBLE'
    group by
        catering_company_id
),
CompanyFinances as (
    select 
        "DeliveryWindow".catering_company_id,
        Count("Order".id) as Number_of_orders,
        Sum("Billing".amount) as Sum_of_billings
    from
        "Order"
    join "DeliveryWindow" on "DeliveryWindow".id = "Order".delivery_window_id
    left join "Billing" on "Billing".order_id = "Order".id
    group by "DeliveryWindow".catering_company_id
),
CompanyDeliveries as (
    select 
        "DeliveryWindow".catering_company_id,
        Count(*) filter (where "Delivery".status = 'FAILED') as Failed_orders,
        Count(*) filter (where "Delivery".status = 'DELIVERED') as Delivered_orders
    from 
        "Delivery"
    join "Order" on "Order".id = "Delivery".order_id
    join "DeliveryWindow" on "Order".delivery_window_id = "DeliveryWindow".id
    group by "DeliveryWindow".catering_company_id
),
CompanyComplaints as (
    select 
        "DeliveryWindow".catering_company_id,
        Count("Complaint".id) as Number_of_complaints
    from 
        "Complaint"
    join "Order" on "Order".id = "Complaint".order_id
    join "DeliveryWindow" on "DeliveryWindow".id = "Order".delivery_window_id
    group by
        "DeliveryWindow".catering_company_id
)
select 
    c.name,
    CompanyReviews.Average_review,
    CompanyFinances.Number_of_orders,
    CompanyFinances.Sum_of_billings,
    CompanyDeliveries.Failed_orders,
    CompanyDeliveries.Delivered_orders,
    CompanyComplaints.Number_of_complaints
from "CateringCompany" c
left join CompanyReviews on c.id = CompanyReviews.catering_company_id
left join CompanyFinances on c.id = CompanyFinances.catering_company_id
left join CompanyDeliveries on c.id = CompanyDeliveries.catering_company_id
left join CompanyComplaints on c.id = CompanyComplaints.catering_company_id
order by c.name;
