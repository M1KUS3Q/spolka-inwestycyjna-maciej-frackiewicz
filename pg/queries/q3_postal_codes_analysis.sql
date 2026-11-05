with ActualOrders as (
    select
        "DeliveryWindow".catering_company_id,
        "DeliveryAddress".postal_code_id,
        Count("Order".id) as orders,
        Count(DISTINCT "Order".user_id) clients
    from "Order"
    join "DeliveryWindow" on "DeliveryWindow".id = delivery_window_id
    join "DeliveryAddress" on "DeliveryAddress".id = delivery_address_id
    group by
        "DeliveryWindow".catering_company_id,
        "DeliveryAddress".postal_code_id
)
select 
    "CateringCompany".name as company_name,
    "PostalCode".code as postal_code,
    ActualOrders.orders as total_orders,
    ActualOrders.clients as total_clients
from "CateringCompanyPostalCode"
join "CateringCompany" on "CateringCompany".id = "CateringCompanyPostalCode".catering_company_id
join "PostalCode" on "CateringCompanyPostalCode".postal_code_id = "PostalCode".id
left join ActualOrders on 
    "CateringCompanyPostalCode".postal_code_id = ActualOrders.postal_code_id AND
    "CateringCompany".id = ActualOrders.catering_company_id
order by
    company_name,
    postal_code

