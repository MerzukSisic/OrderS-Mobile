# Dokumentacija sistema preporuke

## Svrha

Sistem preporuke u aplikaciji OrderS sluzi za prikaz proizvoda koji su relevantni korisniku u trenutnom kontekstu narucivanja. Mobilna aplikacija koristi preporuke na ekranu proizvoda i prikazuje objasnjenje preporuke kada ga API vrati kroz polje `reason`.

## Integracija u mobilnoj aplikaciji

Mobilna aplikacija koristi sljedece endpoint-e:

- `GET /recommendations?userId={id}&count={count}` za personalizovane preporuke.
- `GET /recommendations/popular?count={count}` za popularne proizvode.
- `GET /recommendations/time-based?hour={hour}&count={count}` za preporuke zasnovane na dobu dana.

Pozivi su implementirani u `RecommendationsApiService`, a stanje se vodi kroz `RecommendationsProvider`. Aplikacija paralelno ucitava personalizovane, popularne i vremenski zasnovane preporuke pomocu `Future.wait`.

## Objasnjive preporuke

Response model proizvoda podrzava polje:

- `reason` - tekstualno objasnjenje zasto je proizvod preporucen.

Mobilna aplikacija prikazuje ovo objasnjenje uz preporuceni proizvod kada je polje popunjeno. Time korisnik vidi razlog preporuke, npr. popularnost proizvoda, slicnost s prethodnim odabirima ili relevantnost za trenutno doba dana.

## Ocekivani signali za bodovanje

Backend treba koristiti stvarne podatke iz sistema, a ne staticki mock:

- historiju narudzbi korisnika;
- popularnost proizvoda;
- kategoriju proizvoda;
- vrijeme narudzbe;
- dostupnost proizvoda.

Ako se signal prikuplja i cuva u bazi, mora ucestvovati u bodovanju ili dokumentacija treba jasno navesti zasto se ne koristi.

## Ocekivano ponasanje

Preporuke trebaju biti sortirane po izracunatom score-u od najrelevantnije prema manje relevantnoj. Nedostupni proizvodi se ne bi trebali preporucivati. Ako nema dovoljno personalizovanih podataka, sistem moze koristiti popularne ili vremenski zasnovane preporuke kao fallback.

## Napomena za pregled

Ovaj mobilni repozitorij sadrzi klijentsku integraciju i prikaz preporuka. Implementaciju algoritma, upis signala i scoring potrebno je provjeriti u backend API repozitoriju.
