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
    Uzytkownik }o--o| FirmaCateringowa : "pracuje w"

    FirmaCateringowa }o--o{ KodPocztowy : "obsluguje"
    FirmaCateringowa ||--o{ Dieta : "oferuje"
    FirmaCateringowa ||--o{ OknoDostawy : "okresla"
    FirmaCateringowa ||--o{ Ocena : "otrzymuje"

    Dieta ||--o{ WariantKaloryczny : "zawiera"
    Dieta }o--|{ PoraDnia : "obejmuje"

    WariantKaloryczny ||--o{ Cennik : "posiada określony"

    PozycjaZamowienia }o--|| WariantKaloryczny : "wybiera"
    PozycjaZamowienia ||--|{ PlanDnia : "ma dni dostaw"

    Posilek }o--|{ PoraDnia : "przeznaczony na"
    Posilek }o--|{ Skladnik : "zawiera"
    Posilek }o--o{ Alergen : "zawiera"
    Posilek ||--o{ Ocena : "otrzymuje"

    PlanDnia ||--|{ PozycjaPlanu : "zawiera"
    PozycjaPlanu }o--|| PoraDnia : "przypisana do"
    PozycjaPlanu }o--|| Posilek : "serwuje"

    AdresDostawy ||--o{ Zamowienie : "dotyczy"
    AdresDostawy }o--|| KodPocztowy : "posiada"
    OknoDostawy ||--o{ Zamowienie : "wybrane okno"

    Zamowienie ||--|{ PozycjaZamowienia : "zawiera pozycje"
    Zamowienie ||--|| Rozliczenie : "generuje"
    Zamowienie ||--|{ Doreczenie : "składa się z"
    Zamowienie ||--o{ Reklamacja : "dotyczy"

    DaneFakturowe |o--o{ Rozliczenie : "widnieje na"

    Doreczenie }o--|{ PlanDnia : "realizuje"
    Doreczenie |o--o| Reklamacja : "dotyczy"
    Doreczenie ||--o{ Ocena : "dotyczy"
```

## Uwagi do modelu

* `PozycjaZamowienia` reprezentuje jedną pozycję zamówienia, czyli dietę jednego domownika w ramach zamówienia. Atrybuty: `domownik` (etykieta, np. „Tata"), opcjonalnie `ilosc` (gdy kilka osób bierze ten sam wariant i te same dni).

* `PlanDnia` to konkretny plan dnia z atrybutem `data` (dni wybrane przez danego domownika). Fizyczne doręczenie (`Doreczenie`) może realizować wiele planów z różnych dni i różnych domowników.

* „Dokładnie jeden posiłek na porę dnia" wymusza unikalność pary (PlanDnia, PoraDnia) w `PozycjaPlanu` — niewyrażalne w diagramie ERD.

