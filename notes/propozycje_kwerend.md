20 kwerend SQL oraz 5 funkcji wyszukiwania. Zestaw obejmuje różne obszary systemu cateringu: firmy, zamówienia, dostawy, diety, posiłki, składniki, alergeny, użytkowników, reklamacje i opinie.

Kwerendy są pomyślane tak, aby wymagały czegoś więcej niż prostego filtrowania danych. Wykorzystują wielotabelowe połączenia, grupowanie, podzapytania, agregacje, analizę rozkładów, porównania i funkcje okna. Poniżej przedstawiam wyłącznie opisy i założenia — bez implementacji.

# I. Propozycje 20 kwerend SQL

## A. Firmy cateringowe, zamówienia i dostawy

1\. Wielowymiarowa ocena działalności firm cateringowych

Zestawienie firm cateringowych według ich wyników operacyjnych. Dla każdej firmy należy przedstawić liczbę obsłużonych zamówień, sumę wystawionych rachunków, liczbę zrealizowanych i nieudanych dostaw, liczbę reklamacji oraz średnią ocenę z widocznych opinii. Wyniki powinny pozwalać na porównanie firm i wskazanie tych, które osiągają najlepsze rezultaty.

Agregacje: `COUNT`, `COUNT(DISTINCT)`, `SUM`, `AVG`. Warto zadbać o osobne agregowanie danych z różnych relacji, żeby wielokrotne połączenia nie zawyżały liczby zamówień, dostaw lub opinii.

2\. Miesięczna analiza przychodów firm cateringowych

Zestawienie wartości wystawionych rachunków w kolejnych miesiącach, z podziałem na firmy cateringowe. Dla każdego miesiąca należy pokazać sumę kwot, liczbę dokumentów, średnią wartość dokumentu oraz kwoty opłacone i nieopłacone. Można dodatkowo porównać wynik z poprzednim miesiącem i wskazać miesiące o największym wzroście lub spadku.

Agregacje: `SUM`, `COUNT`, `AVG`, `FILTER`. Przydatna będzie również funkcja okna `LAG`. Opłacenie dokumentu należy rozpoznawać na podstawie niepustego `paid_at`.

3\. Wykorzystanie obszarów dostaw poszczególnych firm

Analiza kodów pocztowych, na których firma deklaruje możliwość dostarczania posiłków, w zestawieniu z rzeczywistymi zamówieniami. Wyniki powinny wskazywać liczbę obsłużonych zamówień dla każdego kodu pocztowego, liczbę klientów korzystających z dostaw oraz obszary, na których firma ma zadeklarowany zasięg, ale nie odnotowała zamówień.

Agregacje: `COUNT(DISTINCT)`, `COUNT`, `SUM`. Kwerenda wymaga zestawienia zadeklarowanego obszaru działalności z kodami pocztowymi adresów dostaw.

4\. Analiza obciążenia i skuteczności okien dostaw.

Celem zapytania jest zbadanie, które przedziały godzinowe (okna dostaw) są najbardziej obciążone w poszczególnych firmach cateringowych i jak przekłada się to na skuteczność kurierów. Dla każdej firmy oraz okna dostawy należy wyświetlić: łączną liczbę zaplanowanych kursów, liczbę dostaw udanych i nieudanych. Dodatkowo kwerenda powinna obliczać wskaźnik sukcesu (procent dostaw zakończonych sukcesem), co pozwoli zidentyfikować godziny, w których najczęściej dochodzi do problemów logistycznych (np. przez poranne korki).


5\. Struktura statusów zamówień w poszczególnych firmach

Porównanie aktualnego rozkładu statusów zamówień pomiędzy firmami cateringowymi. Wyniki powinny pokazywać liczbę oraz procent zamówień w każdym statusie, z uwzględnieniem miesiąca utworzenia zamówienia. Pozwoli to wskazać firmy, w których relatywnie dużo zamówień pozostaje na etapie nowego lub potwierdzonego zamówienia, a także te z większym udziałem zamówień anulowanych.

Agregacje: `COUNT`, `COUNT(DISTINCT)`, `FILTER`. Udziały procentowe powinny być liczone względem liczby zamówień w odpowiedniej grupie.

## B. Diety, warianty kaloryczne i posiłki

6\. Popularność diet i wariantów kalorycznych

Ranking diet oraz wariantów kalorycznych na podstawie rzeczywistych zamówień. Dla każdego wariantu należy przedstawić liczbę zamówień, sumę zamówionych zestawów, liczbę różnych klientów oraz średnią liczbę zestawów przypadającą na zamówienie. Wyniki powinny umożliwiać porównanie popularności wariantów w ramach jednej diety i pomiędzy firmami.

Agregacje: `COUNT`, `COUNT(DISTINCT)`, `SUM`, `AVG`.

7\. Statystyczne porównanie cen wariantów kalorycznych

Analiza cen dziennych wariantów kalorycznych w ramach poszczególnych diet. Dla każdej diety należy wyznaczyć minimalną, maksymalną, średnią i medianę ceny, odchylenie standardowe oraz rozstęp cenowy. Dodatkowo można wskazać warianty, których cena znacząco odbiega od przeciętnej ceny pozostałych wariantów tej samej diety.

Agregacje: `MIN`, `MAX`, `AVG`, `STDDEV_POP`, `PERCENTILE_CONT`. Kwerenda pozwala zaprezentować zarówno proste statystyki opisowe, jak i identyfikowanie wartości odstających.

8\. Porównanie wartości odżywczych posiłków według pory dnia

Zestawienie posiłków przypisanych do poszczególnych pór dnia, takich jak śniadanie, obiad czy kolacja. Dla każdej pory należy policzyć liczbę dostępnych posiłków oraz średnią i medianę kalorii, białka, tłuszczu, węglowodanów, błonnika i soli. Warto także przedstawić minimalną i maksymalną wartość kaloryczną posiłku w danej kategorii.

Agregacje: `COUNT`, `AVG`, `MIN`, `MAX`, `PERCENTILE_CONT`.

9\. Ranking posiłków o najlepszym profilu odżywczym względem kalorii

Zestawienie posiłków przypisanych do poszczególnych pór dnia pod kątem ich wartości odżywczej w przeliczeniu na 100 kcal. Dla każdego posiłku należy obliczyć zawartość białka, błonnika i soli na 100 kcal oraz udział energii pochodzącej z białka, a następnie uszeregować posiłki w obrębie tej samej pory dnia według zawartości białka. Wyniki powinny wskazywać pięć posiłków o najlepszym profilu białkowym w każdej porze dnia, wraz z informacją, czy ich zawartość soli należy do najniższej, średniej czy najwyższej ćwiartki w tej porze dnia.

Agregacje: 'COUNT' jako funkcja okna. Zamiast klasycznego grupowania kwerenda wykorzystuje funkcje okna 'RANK', 'NTILE' i 'COUNT(*) OVER', dzięki czemu każdy posiłek jest porównywany wyłącznie z posiłkami tej samej pory dnia. Posiłek przypisany do kilku pór dnia pojawia się w rankingu każdej z nich osobno, a posiłki o zerowej kaloryczności są pomijane, aby uniknąć dzielenia przez zero.


10\. Zgodność kaloryczności jadłospisów z wybranym wariantem diety

Dla każdego dziennego planu należy obliczyć całkowitą kaloryczność posiłków przypisanych do wszystkich pór dnia, a następnie porównać ją z kalorycznością wariantu, który został zamówiony. Wyniki powinny wskazywać średnie i medianowe odchylenie od założonej kaloryczności, procentowy błąd oraz udział planów mieszczących się w przedziale ±10% wartości deklarowanej.

Agregacje: `SUM`, `AVG`, `PERCENTILE_CONT`, `COUNT`, `FILTER`. To kwerenda łącząca informacje o zamówieniach, wariantach kalorycznych, planach dziennych i posiłkach.

11\. Różnorodność składników w dziennych planach żywieniowych

Dla każdego dziennego planu należy określić liczbę różnych składników wykorzystanych we wszystkich posiłkach tego dnia. Następnie można obliczyć średnią, medianę i minimum różnorodności składników dla poszczególnych diet oraz wariantów kalorycznych. Kwerenda pozwoli porównać, które diety oferują najbardziej zróżnicowane jadłospisy.

Agregacje: `COUNT(DISTINCT)`, `AVG`, `MIN`, `MAX`, `PERCENTILE_CONT`.

12\. Najczęściej współwystępujące pary składników

Wyszukanie par składników, które najczęściej występują razem w tych samych posiłkach. Dla każdej pary należy obliczyć liczbę posiłków zawierających oba składniki, częstość ich wspólnego występowania oraz wskaźnik Jaccarda, czyli stosunek liczby posiłków zawierających oba składniki do liczby posiłków zawierających przynajmniej jeden z nich.

Agregacje: `COUNT(DISTINCT)`. Wymaga połączenia tabeli składników z samą sobą przez relację posiłków. Należy wyeliminować pary, w których składnik jest zestawiany sam ze sobą, i unikać powtórnego prezentowania tej samej pary w odwrotnej kolejności.

13\. Analiza występowania alergenów w ofercie posiłków

Zestawienie alergenów według liczby posiłków, w których występują, wraz z procentowym udziałem tych posiłków w całej ofercie. Dodatkowo należy przedstawić rozkład występowania alergenów według pory dnia. Wyniki powinny umożliwiać wskazanie alergenów najczęściej występujących w ofercie oraz pór dnia, w których ich obecność jest najbardziej powszechna.

Agregacje: `COUNT(DISTINCT)`, `COUNT`, `FILTER`. Warto odróżnić liczbę posiłków zawierających dany alergen od liczby przypisań alergenu do posiłków.

## C. Klienci, reklamacje i opinie

14\. Analiza reklamacji według przedmiotu i czasu rozpatrywania

Zestawienie reklamacji według tematu, statusu i miesiąca zgłoszenia. Dla reklamacji rozstrzygniętych należy obliczyć średni, medianowy i maksymalny czas od zgłoszenia do rozstrzygnięcia. Dodatkowo należy wskazać liczbę reklamacji nierozpatrzonych i odsetek reklamacji zakończonych pozytywnie dla klienta lub odrzuconych.

Agregacje: `COUNT`, `AVG`, `MAX`, `PERCENTILE_CONT`, `FILTER`. Warto analizować czas rozpatrywania wyłącznie dla reklamacji, które mają ustawione `resolved_at`.

15\. Częstotliwość reklamacji w relacji do liczby zamówień

Porównanie firm cateringowych pod kątem częstości występowania reklamacji. Dla każdej firmy należy obliczyć liczbę zamówień, liczbę zamówień, których dotyczyła przynajmniej jedna reklamacja, oraz procent zamówień objętych reklamacją. Analizę można wykonać w podziale na miesiące, aby wykryć okresy pogorszenia jakości obsługi.

Agregacje: `COUNT(DISTINCT)`, `COUNT`, `FILTER`. Istotne jest liczenie unikalnych zamówień z reklamacją, a nie samych zgłoszeń, ponieważ jedno zamówienie może mieć więcej niż jedną reklamację.

16\. Rozkład ocen firm cateringowych i ich wiarygodność statystyczna

Porównanie firm na podstawie widocznych opinii klientów. Oprócz średniej oceny należy przedstawić medianę, odchylenie standardowe, liczbę opinii oraz liczbę ocen z poszczególnych przedziałów. Warto wskazać firmy, które mają wysoką średnią, ale niewielką liczbę opinii, oraz firmy o bardziej stabilnym rozkładzie ocen.

Agregacje: `AVG`, `PERCENTILE_CONT`, `STDDEV_POP`, `COUNT`, `FILTER`. Uwzględnienie liczebności próby pozwala uniknąć bezkrytycznego porównywania średnich opartych na bardzo różnej liczbie opinii.

17\. Oceny poszczególnych posiłków w opiniach klientów

Ranking posiłków według ocen przypisywanych im w opiniach. Dla każdego posiłku należy przedstawić liczbę opinii, średnią i medianę oceny oraz odchylenie standardowe. Można również porównać wyniki tego samego posiłku pomiędzy firmami, o ile występuje on w ofercie różnych firm.

Agregacje: `COUNT`, `AVG`, `PERCENTILE_CONT`, `STDDEV_POP`. Należy uwzględniać tylko opinie przypisane do konkretnego posiłku i zdecydować, czy analizowane mają być wyłącznie opinie widoczne.

18\. Analiza kohort klientów i ich aktywności zakupowej

Podział klientów na kohorty według miesiąca utworzenia konta. Dla każdej kohorty należy obliczyć liczbę zarejestrowanych użytkowników, procent klientów składających pierwsze zamówienie w ciągu 30 dni od rejestracji oraz średnią liczbę zamówień w pierwszych 90 dniach aktywności. Dodatkowym elementem może być mediana czasu między pierwszym a drugim zamówieniem.

Agregacje: `COUNT`, `COUNT(DISTINCT)`, `AVG`, `PERCENTILE_CONT`. Kwerenda wymaga analizy dat rejestracji i zamówień, a także wyznaczania przedziałów czasowych względem rejestracji konkretnego klienta.

19\. Geograficzny rozkład klientów i zamówień

Zestawienie liczby klientów i zamówień według miasta oraz kodu pocztowego. Dodatkowo należy obliczyć średnią liczbę zamówień przypadającą na klienta, wskazać obszary z największą liczbą klientów oraz porównać liczbę zapisanych adresów dostawy z faktyczną aktywnością zakupową w danym obszarze.

Agregacje: `COUNT(DISTINCT)`, `COUNT`, `AVG`, `MAX`. Kwerenda może uwzględniać zarówno adresy dostaw, jak i dane adresowe wykorzystywane do fakturowania, ale powinny być prezentowane jako odrębne kategorie.

20\. Aktywność moderatorów i czas obsługi opinii

Analiza pracy moderatorów na podstawie wpisów w dzienniku moderacji. Dla każdego moderatora należy wyznaczyć liczbę obsłużonych opinii, średni i medianowy czas od wystawienia opinii do utworzenia wpisu moderacyjnego oraz rozkład aktualnych statusów opinii, których wpisy dotyczą. Wyniki powinny umożliwiać porównanie aktywności moderatorów i czasu obsługi.

Agregacje: `COUNT`, `AVG`, `PERCENTILE_CONT`, `MIN`, `MAX`. Warto uwzględnić również użytkowników zarchiwizowanych, ponieważ archiwizacja konta nie oznacza usunięcia historii ich działań.

# II. Propozycje 5 funkcji wyszukiwania

Funkcje mogą być zaprojektowane jako funkcje zwracające zestaw rekordów. Ich celem nie powinno być wyłącznie sprawdzanie jednego parametru, lecz wyszukiwanie uwzględniające relacje pomiędzy tabelami, kryteria wykluczające i odpowiednie sortowanie.

1\. Wyszukiwanie posiłków według składu, alergenów i wartości odżywczych

Funkcja umożliwiająca wyszukiwanie posiłków na podstawie wielu kryteriów jednocześnie. Powinna uwzględniać:

- wymagane składniki, które muszą występować w posiłku;
- składniki, których obecność ma wykluczać posiłek;
- alergeny, których posiłek nie może zawierać;
- zakres kaloryczności i masy posiłku;
- minimalną zawartość białka lub maksymalną zawartość tłuszczu;
- porę dnia, w której posiłek może być serwowany.

Wyniki powinny prezentować pełne dane odżywcze, składniki oraz alergeny posiłku. Możliwe jest również sortowanie według kaloryczności, zawartości białka lub podobieństwa do podanych kryteriów.

2\. Wyszukiwanie firm cateringowych obsługujących określony obszar

Funkcja zwracająca firmy cateringowe, które oferują dostawy pod wskazany kod pocztowy. Oprócz zgodności z obszarem dostaw funkcja powinna uwzględniać status weryfikacji firmy oraz dostępność okien dostaw odpowiadających wskazanemu przedziałowi godzinowemu. Wyniki mogą zawierać nazwy firm, dane kontaktowe, dostępne okna dostaw i liczbę aktywnych diet w ofercie.

3\. Wyszukiwanie diet według oczekiwanej kaloryczności i ceny

Funkcja pozwalająca klientowi odnaleźć dostępne diety i ich warianty kaloryczne na podstawie:

- minimalnej i maksymalnej kaloryczności;
- maksymalnej ceny dziennej;
- wybranej firmy cateringowej lub dowolnej firmy;
- statusu aktywności diety.

Wyniki powinny zawierać nazwę firmy, nazwę diety, kaloryczność wariantu i jego cenę. Dodatkowo wyniki mogą być sortowane według różnicy pomiędzy kalorycznością wariantu a preferowaną przez użytkownika wartością docelową.

4\. Wyszukiwanie zamówień i ich pełnych informacji operacyjnych

Funkcja służąca do wyszukiwania zamówień na potrzeby obsługi klienta i administracji. Kryteria powinny obejmować:

- identyfikator użytkownika lub fragment adresu e-mail;
- przedział dat utworzenia zamówienia;
- jeden lub więcej statusów zamówienia;
- status dostawy;
- identyfikator dostawy lub numer dokumentu rozliczeniowego;
- informację, czy zamówienie posiada reklamację.

Wyniki powinny zwracać zamówienia wraz z danymi klienta, adresem dostawy, informacjami o dostawach, pozycjami zamówienia, wariantami diet oraz dokumentami rozliczeniowymi.

5\. Wyszukiwanie reklamacji według treści i przebiegu obsługi

Funkcja umożliwiająca wyszukiwanie reklamacji na podstawie tekstu w temacie lub opisie zgłoszenia. Dodatkowe parametry powinny pozwalać na ograniczenie wyników do:

- konkretnego użytkownika lub firmy cateringowej;
- wybranego statusu reklamacji;
- przedziału dat zgłoszenia;
- reklamacji powiązanych z konkretną dostawą;
- reklamacji rozstrzygniętych lub nadal otwartych.

Wyniki powinny zawierać dane reklamacji, powiązanego zamówienia i dostawy, status, uzasadnienie decyzji oraz daty zgłoszenia i rozstrzygnięcia. Wyszukiwanie tekstowe może wykorzystywać mechanizm pełnotekstowego wyszukiwania PostgreSQL i sortowanie według trafności dopasowania.

# III. Funkcje agregujące, które warto zaprezentować

W powyższych propozycjach można wykorzystać różne funkcje agregujące, tak aby nie sprowadzać całego zestawu do zwykłego liczenia rekordów.

| Funkcja                | Przykładowe zastosowanie w bazie                                                      |
| ---------------------- | ------------------------------------------------------------------------------------- |
| `COUNT(*)`             | Liczba zamówień, reklamacji, dostaw lub posiłków.                                     |
| `COUNT(DISTINCT ...)`  | Liczba różnych klientów, zamówień objętych reklamacją lub unikalnych składników.      |
| `SUM(...)`             | Łączna wartość rachunków lub łączna kaloryczność planu dziennego.                     |
| `AVG(...)`             | Średnia ocena firmy, średnia cena wariantów lub średni czas rozpatrywania reklamacji. |
| `MIN(...)`             | Najniższa cena wariantu lub najniższa kaloryczność posiłku.                           |
| `MAX(...)`             | Najwyższa ocena, cena lub czas rozpatrywania reklamacji.                              |
| `STDDEV_POP(...)`      | Zróżnicowanie ocen, cen lub wartości odżywczych.                                      |
| `VAR_POP(...)`         | Wariancja ocen lub cen w ramach wybranej grupy.                                       |
| `PERCENTILE_CONT(0.5)` | Mediana cen, ocen, czasów obsługi lub liczby składników.                              |
| `PERCENTILE_CONT(0.9)` | Dziewięćdziesiąty percentyl czasu rozpatrywania reklamacji.                           |
| `FILTER`               | Obliczanie w jednym zestawieniu liczby dostaw według różnych statusów.                |

Dodatkowo warto zastosować funkcje okna, takie jak `LAG`, `RANK`, `DENSE_RANK` czy `ROW_NUMBER`. Nie są to funkcje agregujące, ale dobrze uzupełniają analizy statystyczne i rankingowe, np. przy porównywaniu miesięcznych przychodów lub tworzeniu rankingów firm i posiłków.

# IV. Na co zwrócić uwagę przy realizacji

W schemacie są pewne ograniczenia, które warto uwzględnić, żeby kwerendy były merytorycznie poprawne:

1\. Unikanie zawyżania agregacji. Tabele takie jak `OrderItem`, `Delivery`, `Review` i `Complaint` mogą powodować zwielokrotnienie rekordów przy wielokrotnym łączeniu. W analizach wielowymiarowych warto najpierw agregować dane w osobnych podzapytaniach lub CTE, a następnie łączyć wyniki.

2\. Rozróżnienie kwoty rachunku i ceny dziennej. `Billing.amount` przechowuje kwotę dokumentu, natomiast `OrderItem.daily_price_snapshot` jest ceną dzienną. Nie należy traktować sumy cen dziennych jako całkowitego przychodu z zamówień bez uwzględnienia okresu świadczenia usługi.

3\. Uwzględnienie aktualnego charakteru statusów. `Order.status` i `Delivery.status` przechowują aktualny status, nie historię jego zmian. Na ich podstawie można analizować aktualną strukturę statusów, ale nie rekonstruować pełnej ścieżki zmian zamówienia.

4\. Poprawne przypisywanie firmy do zamówienia. Firma jest powiązana z zamówieniem przez `DeliveryWindow`, natomiast dieta zamówiona w `OrderItem` wskazuje firmę przez `CaloricVariant` i `Diet`. Schemat nie wymusza zgodności tych dwóch powiązań, więc warto przyjąć i konsekwentnie stosować założenie dotyczące przypisania zamówienia do firmy.

5\. Poprawne liczenie czasu dostaw. Dostępna jest data planowana i faktyczny znacznik czasu dostawy, ale nie ma planowanej godziny dostawy. Nie należy zatem wyciągać wniosków o punktualności godzinowej.
