# Agregator diet pudełkowych

## 1. Streszczenie projektu i potrzeby informacyjne

System stanowi platformę agregującą oferty wielu niezależnych firm cateringowych (diet pudełkowych), umożliwiając klientom przeglądanie, porównywanie, konfigurowanie i zamawianie posiłków oraz całych diet z dostawą pod wskazany adres.

### Potrzeby informacyjne

Baza danych musi gromadzić i przetwarzać informacje dotyczące:

* Firm cateringowych, ich danych rejestrowych (NIP, REGON), obsługiwanych zakresów kodów pocztowych oraz godzin pracy.

* Użytkowników platformy, ich danych adresowych, danych do faktur, preferencji dietetycznych oraz poziomów dostępu i uprawnień.

* Menu, planów dietetycznych (np. keto, sport, wege, standard), wariantów kalorycznych (np. 1500 kcal, 2000 kcal, 2500 kcal) oraz cen zależnych od długości trwania zamówienia.

* Szczegółowego składu dań/posiłków, wartości makro- i mikroskładników (kalorie, białko, tłuszcze, węglowodany, błonnik, sól) oraz alergenów.

* Harmonogramu zamówień (dni dostaw, wykluczenia weekendów, preferowane okna czasowe doręczeń).

* Rozliczeń finansowych (metody płatności, paragony fiskalne, faktury VAT dla firm i osób prywatnych).

* Opinii, ocen dań i cateringów, moderacji treści oraz historii zgłoszeń reklamacyjnych.

## 2. Zakres projektu

### W zakres projektu wchodzi (co baza danych uwzględnia):

* Ewidencja firm cateringowych i obsługiwanych przez nie zakresów kodów pocztowych.

* Kompleksowy katalog posiłków, składników, alergenów i wartości odżywczych.

* Zarządzanie planami dietetycznymi i ich wariantami kalorycznymi oraz cennikami.

* Rejestracja klientów, zapisane adresy (dom, praca itp.) oraz zarządzanie kontami pracowników, moderatorów i administratorów.

* Składanie zamówień abonamentowych i jednorazowych, harmonogramowanie dostaw dzień po dniu.

* Zapisywanie informacji o płątności (paragon, faktura vat, faktura imienna, kwota płatności)

* System ocen, recenzji, reklamacji posiłków oraz moderacja opinii.

### Poza zakresem projektu (czego baza danych nie uwzględnia):

* Bezpośrednia integracja API z bramkami płatności (np. Stripe, PayU) – w bazie rejestrowane są wyłącznie informacje o formie wystawienego rachunku i kwocie.

* Zarządzanie flotą kurierską i logistyką dostaw (np. algorytmy optymalizacji tras, telemetria GPS) – system weryfikuje jedynie, czy kod pocztowy klienta znajduje się w obsługiwanym przez catering zakresie.

* Integracja z drukarkami fiskalnymi i fizycznymi systemami POS firm cateringowych – baza przechowuje dane do wydruku paragonu/faktury, ale nie steruje urządzeniami fiskalnymi.

* Rzeczywisty magazyn surowców kuchennych (ERP/WMS) – brak stanów magazynowych mąki, mięsa czy warzyw u podwykonawców; model skupia się na recepturze gotowego dania i jego wartościach odżywczych.

## 3. Role użytkowników i mechanizm autoryzacji

System wymusza uwierzytelnianie użytkowników (login/e-mail + zahashowane haslo) oraz wspiera 4 poziomy uprawnien:

1. **Klient (Użytkownik końcowy)**:

   * Rejestracja i logowanie.

   * Zarządzanie własnym profilem, preferencjami i wieloma adresami dostawy.

   * Wyszukiwanie, filtrowanie i porównywanie ofert cateringowych.

   * Składanie zamówień, wybór okna dostawy, płatność i wybór dokumentu sprzedaży (faktura/paragon).

   * Wstrzymywanie dostaw w wybrane dni (funkcja urlopu) w ramach trwającego abonamentu.

   * Wystawianie ocen i komentarzy po zrealizowanej dostawie oraz zgłaszanie reklamacji.

2. **Menedżer / Pracownik cateringu**:

   * Dostęp do panelu przypisanego do konkretnej firmy cateringowej.

   * Tworzenie i edycja menu: dodawanie posiłków, modyfikacja składników, alergenów, tabeli makroskładników.

   * Konfigurowanie diet: dostępne posiłki, ceny, kaloryka

   * Podgląd harmonogramu zamówień i zestawień posiłków do przygotowania na dany dzień.

   * Definiowanie obsługiwanych zakresów kodów pocztowych.

3. **Moderator opinii**:

   * Przeglądanie nowo dodanych opinii i komentarzy wystawianych przez klientów.

   * Ukrywanie lub usuwanie komentarzy naruszających regulamin platformy.

4. **Administrator systemu**:

   * Pełne zarządzanie użytkownikami, rolami i blokadami kont.

   * Weryfikacja i akceptacja wniosków nowych firm cateringowych o dołączenie do platformy.

   * Nadzór nad globalnym słownikiem alergenów i jednostek odżywczych.

## 4. Wymagania funkcjonalne i reguły biznesowe

### Uwierzytelnianie i profil użytkownika

* Każde konto musi być powiązane z unikalnym adresem e-mail.

* Hasła przechowywane są wyłącznie w postaci bezpiecznego hasha.

* Klient może zdefiniować wiele adresów doręczeń, ale tylko jeden może być oznaczony jako domyślny.

### Oferta i menu

* Każdy posiłek musi mieć przypisane: unikalną nazwę, opis, gramaturę, listę składników, listę alergenów oraz tabelę wartości odżywczych.
* Dieta składa się z określonej liczby posiłków dziennie (np. 3, 5 lub 6 posiłków) i może być oferowana w zdefiniowanych wariantach kalorycznych.

* Firma może modyfikować menu z wyprzedzeniem; zmiany w posiłkach na dany dzień zostają zablokowane na 24 godziny przed planowaną dostawą.

### Zamówienia i płatności

* Zamówienie musi określać: firmę cateringową, rodzaj diety, kaloryczność, datę rozpoczęcia i zakończenia, adres oraz okno czasowe doręczenia

* Każde zamówienie generuje dokładnie jeden rekord rozliczeniowy: paragon fiskalny, fakturę vat, faktura imienna (B2C), kwota płatności.

* Jeśli klient wybiera fakturę, wymagane jest podanie poprawnych danych nabywcy (dla firm: NIP, pełna nazwa, adres siedziby; dla osób fizycznych: imię, nazwisko, adres).

### Dostawa

* Złożenie zamówienia z dostawą pod konkretny adres jest możliwe wyłącznie, gdy kod pocztowy tego adresu mieści się w puli kodów pocztowych obsługiwanych przez wybraną firmę cateringową.

* Każdy dzień trwania zamówienia abonamentowego traktowany jest jako osobna zaplanowana realizacja dostawy.

### Oceny 

* Klient może ocenić danie lub firmę (skala 1–5 gwiazdek + opcjonalny komentarz) wyłącznie po dacie planowanej dostawy powiązanej z danym posiłkiem.
