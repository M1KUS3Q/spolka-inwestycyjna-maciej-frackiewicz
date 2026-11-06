# Propozycje kwerend

1. Wielowymiarowa ocena działalności firm cateringowych

Zestawienie firm cateringowych według ich wyników operacyjnych. Dla każdej firmy należy przedstawić liczbę obsłużonych zamówień, sumę wystawionych rachunków, liczbę zrealizowanych i nieudanych dostaw, liczbę reklamacji oraz średnią ocenę z widocznych opinii. Wyniki powinny pozwalać na porównanie firm i wskazanie tych, które osiągają najlepsze rezultaty.

2. Miesięczna analiza przychodów firm cateringowych

Zestawienie wartości wystawionych rachunków w kolejnych miesiącach, z podziałem na firmy cateringowe. Dla każdego miesiąca należy pokazać sumę kwot, liczbę dokumentów, średnią wartość dokumentu oraz kwoty opłacone i nieopłacone. Można dodatkowo porównać wynik z poprzednim miesiącem i wskazać miesiące o największym wzroście lub spadku.

3. Wykorzystanie obszarów dostaw poszczególnych firm

Analiza kodów pocztowych, na których firma deklaruje możliwość dostarczania posiłków, w zestawieniu z rzeczywistymi zamówieniami. Wyniki powinny wskazywać liczbę obsłużonych zamówień dla każdego kodu pocztowego, liczbę klientów korzystających z dostaw oraz obszary, na których firma ma zadeklarowany zasięg, ale nie odnotowała zamówień.

4. Analiza obciążenia i skuteczności okien dostaw.

Celem zapytania jest zbadanie, które przedziały godzinowe (okna dostaw) są najbardziej obciążone w poszczególnych firmach cateringowych i jak przekłada się to na skuteczność kurierów. Dla każdej firmy oraz okna dostawy należy wyświetlić: łączną liczbę zaplanowanych kursów, liczbę dostaw udanych i nieudanych. Dodatkowo kwerenda powinna obliczać wskaźnik sukcesu (procent dostaw zakończonych sukcesem), co pozwoli zidentyfikować godziny, w których najczęściej dochodzi do problemów logistycznych (np. przez poranne korki).


5. Struktura statusów zamówień w poszczególnych firmach

Porównanie aktualnego rozkładu statusów zamówień pomiędzy firmami cateringowymi. Wyniki powinny pokazywać liczbę oraz procent zamówień w każdym statusie, z uwzględnieniem miesiąca utworzenia zamówienia. Pozwoli to wskazać firmy, w których relatywnie dużo zamówień pozostaje na etapie nowego lub potwierdzonego zamówienia, a także te z większym udziałem zamówień anulowanych.

6. Ranking popularności diet

7. Zestawienie porównawcze reklamacji i ocen w danej firmie pozwalające na weryfikację powiązania tych dwóch kryteriów.

8. Ranking rentowności wariantów kalorycznych

9. Ranking posiłków o najlepszym profilu odżywczym względem kalorii

Zestawienie posiłków przypisanych do poszczególnych pór dnia pod kątem ich wartości odżywczej w przeliczeniu na 100 kcal. Dla każdego posiłku należy obliczyć zawartość białka, błonnika i soli na 100 kcal oraz udział energii pochodzącej z białka, a następnie uszeregować posiłki w obrębie tej samej pory dnia według zawartości białka. Wyniki powinny wskazywać pięć posiłków o najlepszym profilu białkowym w każdej porze dnia, wraz z informacją, czy ich zawartość soli należy do najniższej, średniej czy najwyższej ćwiartki w tej porze dnia.

10. Zgodność kaloryczności jadłospisów z wybranym wariantem diety

Dla każdego dziennego planu należy obliczyć całkowitą kaloryczność posiłków przypisanych do wszystkich pór dnia, a następnie porównać ją z kalorycznością wariantu, który został zamówiony. Wyniki powinny wskazywać średnie i medianowe odchylenie od założonej kaloryczności, procentowy błąd oraz udział planów mieszczących się w przedziale ±10% wartości deklarowanej.

11. Różnorodność składników w dziennych planach żywieniowych

Dla każdego dziennego planu należy określić liczbę różnych składników wykorzystanych we wszystkich posiłkach tego dnia. Następnie można obliczyć średnią, medianę i minimum różnorodności składników dla poszczególnych diet oraz wariantów kalorycznych. Kwerenda pozwoli porównać, które diety oferują najbardziej zróżnicowane jadłospisy.

12. Najczęściej współwystępujące pary składników

Wyszukanie par składników, które najczęściej występują razem w tych samych posiłkach. Dla każdej pary należy obliczyć liczbę posiłków zawierających oba składniki, częstość ich wspólnego występowania oraz wskaźnik Jaccarda, czyli stosunek liczby posiłków zawierających oba składniki do liczby posiłków zawierających przynajmniej jeden z nich.

13. Analiza występowania alergenów w ofercie posiłków

Zestawienie alergenów według liczby posiłków, w których występują, wraz z procentowym udziałem tych posiłków w całej ofercie. Dodatkowo należy przedstawić rozkład występowania alergenów według pory dnia. Wyniki powinny umożliwiać wskazanie alergenów najczęściej występujących w ofercie oraz pór dnia, w których ich obecność jest najbardziej powszechna.

14. Analiza reklamacji według przedmiotu i czasu rozpatrywania

Zestawienie reklamacji według miesiąca zgłoszenia (format `YYYY-MM`) i tematu. Dla każdej pary miesiąc–temat podawana jest liczba wszystkich reklamacji oraz jej podział według statusu na osobne kolumny: zakończone pozytywnie dla klienta (`RESOLVED`), odrzucone (`REJECTED`) i nierozpatrzone (pozostałe statusy). Dla reklamacji z ustawionym `resolved_at` liczony jest średni, medianowy i maksymalny czas od zgłoszenia do rozstrzygnięcia, w dniach z ułamkami, żeby nie tracić dokładności w dalszych obliczeniach. Odsetki reklamacji zakończonych pozytywnie i odrzuconych liczone są względem wszystkich reklamacji danego tematu w danym miesiącu.

15. Częstotliwość reklamacji w relacji do liczby zamówień

Porównanie firm cateringowych pod kątem częstości występowania reklamacji. Firma jest przypisana do zamówienia przez okno dostawy (`DeliveryWindow`). Dla każdej firmy podawana jest liczba zamówień, liczba zamówień z co najmniej jedną reklamacją, łączna liczba reklamacji i procent zamówień objętych reklamacją. Wynik jest rozbity na miesiące utworzenia zamówienia (`YYYY-MM`) i uzupełniony wierszem zbiorczym firmy (`row_scope = 'total'`, `month IS NULL`). Wiersz zbiorczy jest liczony z danych źródłowych, a nie jako średnia z miesięcy.

16. Rozkład ocen firm cateringowych i ich wiarygodność statystyczna

Porównanie firm na podstawie widocznych opinii klientów (`moderation_status = 'VISIBLE'`). Oprócz średniej oceny podawane są: mediana, odchylenie standardowe z próby, liczba opinii i liczba ocen z poszczególnych przedziałów (1–5). Ocena ważona (`weighted_rating`) przybliża średnią firmy do średniej globalnej z wagą 10 opinii (`prior_weight`) i według niej sortowany jest ranking. Etykieta `reliability_label` klasyfikuje próbę jako małą (poniżej 100 opinii), umiarkowaną (100–149) lub wystarczającą (150 i więcej). Progi dobrano do liczby opinii w danych (ok. 100–200 na firmę) i są przyjętym założeniem. Flaga `high_rating_low_sample` wskazuje firmy ze średnią powyżej globalnej, ale z liczbą opinii mniejszą niż 10. Firmy bez opinii pozostają w wyniku (0 opinii, pozostałe statystyki `NULL`).

17. Oceny poszczególnych posiłków w opiniach klientów

Ranking posiłków według ocen z opinii. Wiersz opisuje parę posiłek–firma, dzięki czemu można porównać ten sam posiłek między firmami. Uwzględniane są wyłącznie opinie widoczne i przypisane do konkretnego posiłku (`meal_id IS NOT NULL`). Każdy wiersz zawiera trzy poziomy średnich: (1) tego posiłku u danej firmy, z liczbą opinii, (2) tego posiłku we wszystkich firmach, z liczbą opinii, liczbą firm i pozycją w rankingu (remisy rozstrzyga liczba opinii), (3) wszystkich posiłków danej firmy, z liczbą opinii i liczbą ocenianych posiłków. Pozwala to ocenić posiłek na tle jego wyników u innych firm i na tle pozostałych posiłków tej samej firmy. Mediany i odchylenie standardowe pominięto, bo przy małej liczbie opinii na parę posiłek–firma niewiele wnoszą. Opinie o firmie niepowiązane z posiłkiem nie wchodzą do średniej firmy (ogólna ocena firmy jest w zapytaniu 16).

18. Analiza aktywności zakupowej klientów według miesięcy

19. Geograficzny rozkład klientów i zamówień

Zestawienie liczby klientów i zamówień według miasta oraz kodu pocztowego. Dodatkowo należy obliczyć średnią liczbę zamówień przypadającą na klienta, wskazać obszary z największą liczbą klientów oraz porównać liczbę zapisanych adresów dostawy z faktyczną aktywnością zakupową w danym obszarze.

20. Aktywność moderatorów i czas obsługi opinii

Analiza pracy moderatorów na podstawie wpisów w dzienniku moderacji. Dla każdego moderatora należy wyznaczyć liczbę obsłużonych opinii, średni i medianowy czas od wystawienia opinii do utworzenia wpisu moderacyjnego oraz rozkład aktualnych statusów opinii, których wpisy dotyczą. Wyniki powinny umożliwiać porównanie aktywności moderatorów i czasu obsługi.

# Propozycje funkcji

1. Wyszukiwanie posiłków bez określonych alergenów

2. Wyszukiwanie firm cateringowych obsługujących określony obszar

Funkcja zwracająca firmy cateringowe, które oferują dostawy pod wskazany kod pocztowy. Oprócz zgodności z obszarem dostaw funkcja powinna uwzględniać status weryfikacji firmy oraz dostępność okien dostaw odpowiadających wskazanemu przedziałowi godzinowemu. Wyniki mogą zawierać nazwy firm, dane kontaktowe, dostępne okna dostaw i liczbę aktywnych diet w ofercie.

3. Wyszukiwanie diet według oczekiwanej kaloryczności i ceny

Funkcja pozwalająca klientowi odnaleźć dostępne diety i ich warianty kaloryczne na podstawie:

- minimalnej i maksymalnej kaloryczności;
- maksymalnej ceny dziennej;
- wybranej firmy cateringowej lub dowolnej firmy;
- statusu aktywności diety.

Wyniki powinny zawierać nazwę firmy, nazwę diety, kaloryczność wariantu i jego cenę. Dodatkowo wyniki mogą być sortowane według różnicy pomiędzy kalorycznością wariantu a preferowaną przez użytkownika wartością docelową.

4. Wyszukiwanie zamówień i ich pełnych informacji operacyjnych

Funkcja służąca do wyszukiwania zamówień na potrzeby obsługi klienta i administracji. Kryteria powinny obejmować:

- identyfikator użytkownika lub fragment adresu e-mail;
- przedział dat utworzenia zamówienia;
- jeden lub więcej statusów zamówienia;
- status dostawy;
- identyfikator dostawy lub numer dokumentu rozliczeniowego;
- informację, czy zamówienie posiada reklamację.

Wyniki powinny zwracać zamówienia wraz z danymi klienta, adresem dostawy, informacjami o dostawach, pozycjami zamówienia, wariantami diet oraz dokumentami rozliczeniowymi.

5. Wyszukiwanie reklamacji według treści i przebiegu obsługi

Funkcja umożliwiająca wyszukiwanie reklamacji na podstawie tekstu w temacie lub opisie zgłoszenia. Dodatkowe parametry powinny pozwalać na ograniczenie wyników do:

- konkretnego użytkownika lub firmy cateringowej;
- wybranego statusu reklamacji;
- przedziału dat zgłoszenia;
- reklamacji powiązanych z konkretną dostawą;
- reklamacji rozstrzygniętych lub nadal otwartych.

Wyniki powinny zawierać dane reklamacji, powiązanego zamówienia i dostawy, status, uzasadnienie decyzji oraz daty zgłoszenia i rozstrzygnięcia. Wyszukiwanie tekstowe może wykorzystywać mechanizm pełnotekstowego wyszukiwania PostgreSQL i sortowanie według trafności dopasowania.