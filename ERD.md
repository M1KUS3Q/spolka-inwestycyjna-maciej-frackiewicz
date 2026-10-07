# Diagram ERD - Agregator diet pudełkowych

Poniżej znajduje się diagram obiektowo-związkowy (ERD) dla systemu agregatora diet pudełkowych, zaprojektowany na podstawie pliku `README.md` oraz zgodnie z wytycznymi.

## Założenia zrealizowane na diagramie:
1. **Brak encji asocjacyjnych**: Zgodnie z poleceniem, relacje wiele-do-wielu (N:N) zostały zamodelowane bezpośrednio (np. `Posilek }o--o{ Skladnik`), bez tworzenia pośrednich, asocjacyjnych encji łączących.
2. **Liczba encji**: Diagram zawiera równo 20 unikalnych encji bazodanowych pokrywających pełen zakres logiki systemu z dokumentacji.
3. **Relacje**: W modelu prawidłowo uwzględniono zróżnicowane typy relacji (1:1, 1:N oraz N:N).

## Diagram Mermaid

```mermaid
erDiagram
    Uzytkownik {
        int id PK
        string email "unikalny"
        string haslo_hash
        string numer_telefonu "unikalny"
        boolean czy_aktywny
    }
    
    Rola {
        int id PK
        string nazwa "Klient, Pracownik, Moderator, Admin"
    }

    AdresDostawy {
        int id PK
        string miasto
        string ulica
        string kod_pocztowy
        string nr_budynku
        string nr_lokalu
        boolean czy_domyslny
    }

    DaneFakturowe {
        int id PK
        string nip
        string nazwa_firmy
        string imie
        string nazwisko
        string pelny_adres
    }

    FirmaCateringowa {
        int id PK
        string nazwa
        string nip
        string regon
        string godziny_pracy
        boolean czy_zweryfikowana
    }

    ZakresKodowPocztowych {
        int id PK
        string kod_od
        string kod_do
    }

    Dieta {
        int id PK
        string nazwa
        string opis
    }

    WariantKaloryczny {
        int id PK
        int wartosc_kcal
    }

    Cennik {
        int id PK
        int czas_trwania_dni
        float cena
    }

    PoraDnia {
        int id PK
        string nazwa "np. Sniadanie"
    }

    Posilek {
        int id PK
        string nazwa "unikalna"
        string opis
        int gramatura
    }

    WartoscOdzywcza {
        int id PK
        int kalorie
        float bialko
        float tluszcze
        float weglowodany
        float blonnik
        float sol
    }

    Skladnik {
        int id PK
        string nazwa
    }

    Alergen {
        int id PK
        string nazwa
        string opis
    }

    Zamowienie {
        int id PK
        date data_zamowienia
        date data_poczatkowa
        date data_koncowa
        time okno_dostawy_od
        time okno_dostawy_do
    }

    Rozliczenie {
        int id PK
        float kwota
        string typ_dokumentu "paragon, f_vat, f_imienna"
        string status_platnosci
    }

    MetodaPlatnosci {
        int id PK
        string nazwa "Karta, BLIK, Przelew"
    }

    DzienDostawy {
        int id PK
        date data_realizacji
        string status_dostawy
    }

    Ocena {
        int id PK
        int gwiazdki "1-5"
        string komentarz
        date data_wystawienia
        boolean czy_ukryta
    }

    Reklamacja {
        int id PK
        string tresc
        string status
        date data_zgloszenia
    }

    %% Relacje (związki)
    Uzytkownik }o--o{ Rola : "posiada"
    Uzytkownik ||--o{ AdresDostawy : "definiuje"
    Uzytkownik ||--o{ DaneFakturowe : "posiada"
    Uzytkownik ||--o{ Zamowienie : "sklada"
    Uzytkownik ||--o{ Ocena : "wystawia"
    Uzytkownik ||--o{ Reklamacja : "zglasza"
    
    FirmaCateringowa ||--o{ Uzytkownik : "zatrudnia"
    FirmaCateringowa ||--o{ ZakresKodowPocztowych : "obsluguje"
    FirmaCateringowa ||--o{ Dieta : "oferuje"
    FirmaCateringowa ||--o{ Posilek : "przygotowuje"
    FirmaCateringowa ||--o{ Zamowienie : "realizuje"
    FirmaCateringowa ||--o{ Ocena : "otrzymuje"
    
    Dieta }o--o{ WariantKaloryczny : "dostepna w wariantach"
    Dieta }o--o{ PoraDnia : "zawiera"
    Dieta }o--o{ Posilek : "sklada sie z"
    Dieta ||--o{ Cennik : "posiada"
    Dieta ||--o{ Zamowienie : "dotyczy"
    
    WariantKaloryczny ||--o{ Cennik : "dotyczy"
    WariantKaloryczny ||--o{ Zamowienie : "okresla"
    
    Posilek }o--o{ PoraDnia : "serwowany w"
    Posilek ||--|| WartoscOdzywcza : "posiada makroskladniki"
    Posilek }o--o{ Skladnik : "zawiera"
    Posilek }o--o{ Alergen : "moze zawierac"
    Posilek ||--o{ Ocena : "otrzymuje"
    
    AdresDostawy ||--o{ Zamowienie : "miejsce dostawy"
    
    Zamowienie ||--|| Rozliczenie : "generuje"
    Zamowienie ||--|{ DzienDostawy : "dzieli sie na"
    Zamowienie ||--o{ Reklamacja : "dotyczy"
    
    Rozliczenie }o--|| MetodaPlatnosci : "wykorzystuje"
    DaneFakturowe ||--o{ Rozliczenie : "widnieje na"
    
    DzienDostawy }o--o{ Posilek : "dostarcza"
    DzienDostawy ||--o{ Ocena : "pozwala ocenic"
    DzienDostawy ||--o{ Reklamacja : "dotyczy dnia"
    DzienDostawy ||--o{ DaneFakturowe : "sperma"
```

