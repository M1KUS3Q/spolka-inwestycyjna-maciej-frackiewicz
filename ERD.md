# Diagram ERD - Agregator diet pudełkowych

## Diagram Mermaid

```mermaid
erDiagram
    Uzytkownik }o--o{ Uprawnienie : "posiada"
    Uzytkownik ||--o{ AdresDostawy : "okresla"
    Uzytkownik ||--o{ DaneFakturowe : "posiada"
    Uzytkownik ||--o{ Zamowienie : "sklada"
    Uzytkownik ||--o{ Ocena : "wystawia"
    Uzytkownik ||--o{ Reklamacja : "zglasza"

    FirmaCateringowa }o--o{ KodPocztowy : "obsluguje"
    FirmaCateringowa ||--o{ Dieta : "oferuje"
    FirmaCateringowa ||--o{ OknoDostawy : "okresla"
    FirmaCateringowa ||--o{ Ocena : "otrzymuje"

    Dieta ||--o{ WariantKaloryczny : "zawiera"
    Dieta }o--o{ PoraDnia : "obejmuje"

    WariantKaloryczny ||--o{ Cennik : "posiada określony"
    WariantKaloryczny ||--o{ PlanDnia : "okresla"
    WariantKaloryczny ||--o{ Zamowienie : "wybiera"

    Posilek }o--|{ PoraDnia : "przeznaczony na"
    Posilek }o--|{ Skladnik : "zawiera"
    Posilek }o--o{ Alergen : "zawiera"
    Posilek ||--o{ Ocena : "otrzymuje"

    PlanDnia ||--|{ PozycjaPlanu : "zawiera"
    PozycjaPlanu }o--|| PoraDnia : "przypisana do"
    PozycjaPlanu }o--|| Posilek : "serwuje"

    AdresDostawy ||--o{ Zamowienie : "dotyczy"
    AdresDostawy ||--|| KodPocztowy : "posiada"
    OknoDostawy ||--o{ Zamowienie : "wybrane okno"

    Zamowienie ||--|| Rozliczenie : "generuje"
    Zamowienie ||--|{ Doreczenie : "składa się z"
    Zamowienie ||--o{ Reklamacja : "dotyczy"

    DaneFakturowe ||--o{ Rozliczenie : "widnieje na"

    Doreczenie }o--|{ PlanDnia : "realizuje"
    Doreczenie |o--o| Reklamacja : "dotyczy"
    Doreczenie ||--o{ Ocena : "dotyczy"
```

