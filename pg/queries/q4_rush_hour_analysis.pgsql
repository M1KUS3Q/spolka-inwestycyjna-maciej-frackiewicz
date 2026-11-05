select 
    "CateringCompany".name,
    "DeliveryWindow".start_time,
    "DeliveryWindow".end_time,
    Count("Delivery".id) as total_deliveries,
    Count("Delivery".id) filter (where "Delivery".status = 'DELIVERED') as delivered_deliveries,
    Count("Delivery".id) filter (where "Delivery".status = 'FAILED') as failed_deliveries,
    (Count("Delivery".id) filter (where "Delivery".status = 'DELIVERED') * 100.0) / Count("Delivery".id) as success_rate_percent
from "Delivery"
join "Order" on "Delivery".order_id = "Order".id 
join "DeliveryWindow" on "Order".delivery_window_id = "DeliveryWindow".id
join "CateringCompany" on "DeliveryWindow".catering_company_id = "CateringCompany".id
group by
    "CateringCompany".name,
    "DeliveryWindow".start_time,
    "DeliveryWindow".end_time
order by
    "CateringCompany".name,
    total_deliveries DESC
