# OrderS — Mobilna Aplikacija
**Autor:** Merzuk Šišić (IB220060)  
**Predmet:** Razvoj softvera II  
**Akademska godina:** 2024/2025

---

## 📋 Sadržaj
1. [Opis aplikacije](#opis-aplikacije)
2. [Tehnologije](#tehnologije)
3. [Pokretanje aplikacije](#pokretanje-aplikacije)
4. [Login podaci](#login-podaci)
5. [Build APK](#build-apk)
6. [Struktura projekta](#struktura-projekta)

---

## 🎯 Opis aplikacije

OrderS mobilna aplikacija razvijena je u Flutteru i namijenjena je operativnom osoblju kafića — konobarima, šankerima, kuharima i administratorima. Svaka uloga dobija prilagođeno iskustvo prema dodijeljenim pravima pristupa.

### Funkcionalnosti po ulogama:

**Konobar:**
- ✅ Upravljanje stolovima (grid prikaz s vizualnim statusima)
- ✅ Kreiranje narudžbi s odabirom priloga (AccompanimentGroups)
- ✅ Pregled historije narudžbi
- ✅ Generisanje računa za gosta, kuhinju i šank

**Šanker / Kuhar:**
- ✅ Pregled narudžbi po statusu (Pending / Preparing / Ready)
- ✅ Prihvatanje i odbijanje narudžbi
- ✅ Ažuriranje statusa stavki

**Admin (mobilna):**
- ✅ Dashboard s prihodima i statistikama
- ✅ Upravljanje proizvodima, kategorijama, korisnicima
- ✅ Inventar s filtriranjem po skladištu i AdjustInventoryDialog (dodaj/oduzmi/postavi)
- ✅ Nabavka (Procurement + Stripe plaćanje) s validacijom dostupnih zaliha
- ✅ Plaćanje Pending procurement narudžbi direktno iz liste
- ✅ Upravljanje stolovima — kreiranje/uređivanje na zasebnim stranicama s Location dropdownom
- ✅ Upravljanje skladištima — kreiranje/uređivanje s product listom i AddProductDialog
- ✅ Print računa (gost/kuhinja/šank) na admin order detail ekranu
- ✅ Statistike s grafikonima (fl_chart)

### Povezani repozitoriji:
- ⚙️ **Backend API:** [OrdersAPI repo]
- 🖥️ **Desktop aplikacija:** [rs2-desktop repo]

---

## 🛠️ Tehnologije

- **Flutter 3.19+** — Cross-platform mobile (Android/iOS)
- **Provider** — State management (ChangeNotifier pattern)
- **Dio** — HTTP klijent s interceptorima za JWT
- **shared_preferences** — Lokalno čuvanje JWT tokena
- **fl_chart** — Grafikoni za statistike i dashboard
- **Stripe Flutter SDK** — Payment Sheet za procurement plaćanja
- **flutter_dotenv** — Runtime učitavanje `.env` konfiguracije (Stripe ključ)

---

## 🚀 Pokretanje aplikacije

### Preduvjeti:
- Flutter SDK 3.19+
- Android Studio s AVD emulatorom (API 21+)
- Pokrenuti backend: `docker-compose up --build` u OrdersAPI repou

### Pokretanje iz source koda:
```bash
git clone <URL_OVOG_REPOA>
cd orders_mobile

flutter pub get

flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5220/api
```

### Instalacija prebuilt APK-a:
```bash
# Ekstraktovati build arhivu (šifra: fit)
7z x fit-build-26-02-22.zip

# Instalirati na AVD emulator
cd build/app/outputs/flutter-apk/
adb install app-release.apk

# Ili drag & drop APK fajl direktno u emulator
```

---

## 🔐 Login podaci

| Email | Lozinka | Uloga |
|---|---|---|
| admin@orders.com | password123 | Admin |
| marko@orders.com | password123 | Waiter |
| ana@orders.com | password123 | Bartender |
| kuhar@orders.com | password123 | Kitchen |

> **Napomena:** Backend mora biti pokrenut prije logina. API adresa za AVD emulator je `http://10.0.2.2:5220/api`.

---

## 📦 Build APK

```bash
flutter clean
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:5220/api
```

**Lokacija outputa:** `build/app/outputs/flutter-apk/app-release.apk`

Build arhiva se nalazi u root folderu repoa: `fit-build-26-02-22-mobile.zip` (split arhiva, šifra: `fit`).

---

## 📁 Struktura projekta

```
orders_mobile/
├── lib/
│   ├── core/
│   │   ├── services/api/          # API servisi (auth, orders, products...)
│   │   └── config/                # EnvConfig — dart-define API adresa
│   ├── models/                    # Data modeli
│   ├── providers/                 # State management (Provider)
│   ├── screens/                   # Ekrani po ulogama
│   │   ├── auth/                  # Login, Splash
│   │   ├── waiter/                # Stolovi, Narudžbe, Checkout
│   │   ├── bar/                   # Šanker ekrani
│   │   ├── kitchen/               # Kuhar ekrani
│   │   └── admin/                 # Dashboard, Proizvodi, Inventar...
│   ├── widgets/                   # Reusable komponente
│   └── main.dart
├── build/app/outputs/flutter-apk/ # APK output
├── fit-build-26-02-22.zip         # Build arhiva (šifra: fit)
└── .env.zip                       # Konfiguracijski fajl (šifra: fit)
```

---

*OrderS — RS2 2024/2025 — Merzuk Šišić — IB220060*