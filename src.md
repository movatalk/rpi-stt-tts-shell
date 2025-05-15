rpi-stt-tts-shell/
├── README.md                  # Główny plik README projektu
├── Makefile                   # Główny Makefile
├── LICENSE                    # Plik licencji
│
├── bin/                       # Skrypty wykonywalne
│   ├── menu.sh                # Główne menu aplikacji
│   └── README.md              # Dokumentacja skryptów wykonalnych
│
├── fleet/                     # Narzędzia do zarządzania flotą urządzeń
│   ├── README.md              # Dokumentacja narzędzi fleet
│   ├── scan.sh                # Skrypt skanowania urządzeń
│   ├── deploy.sh              # Skrypt wdrażania projektu
│   └── test.sh                # Skrypt testowy dla wdrożeń
│
├── ssh/                       # Narzędzia do zarządzania konfiguracjami SSH
│   ├── README.md              # Dokumentacja narzędzi SSH
│   ├── manager.sh             # Menedżer hostów SSH
│   ├── hosts_from_csv.sh      # Generator konfiguracji hostów z CSV
│   └── hosts_csv_parser.py    # Parser CSV dla hostów SSH
│
├── rpi/                       # Skrypty i konfiguracje specyficzne dla Raspberry Pi
│   ├── README.md              # Dokumentacja skryptów dla Raspberry Pi
│   ├── config.sh              # Konfiguracja Raspberry Pi
│   ├── setup.sh               # Skrypt instalacyjny dla Raspberry Pi
│   └── respeaker.sh           # Konfiguracja ReSpeaker dla Raspberry Pi
│
├── zero3w/                    # Skrypty i konfiguracje specyficzne dla Radxa Zero 3W
│   ├── README.md              # Dokumentacja skryptów dla Radxa Zero 3W
│   ├── config.sh              # Konfiguracja Radxa Zero 3W
│   ├── poetry.sh              # Instalacja Poetry na Radxa Zero 3W
│   └── respeaker.sh           # Konfiguracja ReSpeaker dla Radxa Zero 3W
│
├── docs/                      # Dokumentacja projektu
│   ├── README.md              # Indeks dokumentacji
│   ├── scripts.md             # Dokumentacja skryptów
│   └── api.md                 # Dokumentacja API
│
└── src/                       # Kod źródłowy projektu
    ├── README.md              # Dokumentacja kodu źródłowego
    ├── __init__.py
    ├── assistant.py           # Główny moduł asystenta
    ├── stt/                   # Moduły rozpoznawania mowy
    ├── tts/                   # Moduły syntezy mowy
    └── plugins/               # Wtyczki rozszerzające funkcjonalność