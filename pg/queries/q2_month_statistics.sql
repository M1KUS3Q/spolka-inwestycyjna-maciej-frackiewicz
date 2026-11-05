with Month_statistics as (
    select 
        "CateringCompany".name,
        TO_CHAR("Order".created_at, 'YYYY-MM') as Billing_month,
        Sum("Billing".amount) as total_amount,
        Count("Billing".document_number) as number_of_documents,
        Avg("Billing".amount) as average_amount,
        Sum("Billing".amount) filter (where "Billing".paid_at is not null) as paid_amount,
        Sum("Billing".amount) filter (where "Billing".paid_at is null) as unpaid_amount

    from "Billing" 
    join "Order" on "Billing".order_id = "Order".id
    join "DeliveryWindow" on "Order".delivery_window_id = "DeliveryWindow".id
    join "CateringCompany" on "DeliveryWindow".catering_company_id = "CateringCompany".id
    group by
        "CateringCompany".name,
        Billing_month
)
select
    Month_statistics.name,
    Month_statistics.Billing_month,
    Month_statistics.total_amount,
    Month_statistics.number_of_documents,
    Month_statistics.average_amount,
    Month_statistics.paid_amount,
    Month_statistics.unpaid_amount,
    lag(total_amount) over (PARTITION BY name order by Billing_month) AS prev_month_amount,
    (total_amount - LAG(total_amount) OVER (PARTITION BY name ORDER BY Billing_month)) as month_difference
from
    Month_statistics
