# Diagram ERD - Agregator diet pudełkowych

## Diagram Mermaid

```mermaid
erDiagram
    User }o--o{ Permission : "has"
    User ||--o{ DeliveryAddress : "specifies"
    User ||--o{ BillingData : "has"
    User ||--o{ Order : "places"
    User ||--o{ Review : "submits"
    User ||--o{ Complaint : "submits"
    User }o--o| CateringCompany : "works at"

    CateringCompany }o--o{ PostalCode : "services"
    CateringCompany ||--o{ Diet : "offers"
    CateringCompany ||--o{ DeliveryWindow : "specifies"
    CateringCompany ||--o{ Review : "receives"

    Diet ||--o{ CaloricVariant : "contains"
    Diet }o--|{ Mealtime : "includes"

    OrderItem }o--|| CaloricVariant : "selects"
    OrderItem ||--|{ DailyPlan : "has delivery days"

    Meal }o--|{ Mealtime : "intended for"
    Meal }o--|{ Ingredient : "contains"
    Meal }o--o{ Allergen : "contains"
    Meal |o--o{ Review : "receives"

    DailyPlan ||--|{ PlanItem : "contains"
    PlanItem }o--|| Mealtime : "assigned to"
    PlanItem }o--|| Meal : "serves"

    DeliveryAddress ||--o{ Order : "applies to"
    DeliveryAddress }o--|| PostalCode : "has"
    DeliveryWindow ||--o{ Order : "selected window"

    Order ||--|{ OrderItem : "contains items"
    Order ||--|| Billing : "generates"
    Order ||--|{ Delivery : "consists of"
    Order ||--o{ Complaint : "applies to"

    BillingData |o--o{ Billing : "appears on"

    Delivery }o--|{ DailyPlan : "fulfills"
    Delivery |o--o| Complaint : "applies to"
    Delivery |o--o{ Review : "applies to"
```

## Uwagi do modelu

* `OrderItem` reprezentuje jedną pozycję zamówienia, czyli dietę jednego domownika w ramach zamówienia. Atrybuty: `recipient` (etykieta, np. „Tata"), opcjonalnie `quantity` (gdy kilka osób bierze ten sam wariant i te same dni).

* `DailyPlan` to konkretny plan dnia z atrybutem `date` (dni wybrane przez danego domownika). Fizyczne doręczenie (`Delivery`) może realizować wiele planów z różnych dni i różnych domowników.

* „Dokładnie jeden posiłek na porę dnia" wymusza unikalność pary (DailyPlan, Mealtime) w `PlanItem` — niewyrażalne w diagramie ERD.

