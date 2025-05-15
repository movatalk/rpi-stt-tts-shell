# Makefile dla projektu rpi-stt-tts-shell
# Autor: Tom Sapletta
# Data: 15 maja 2025

.PHONY: all install scan deploy test clean docs help run update-deps

# Zmienne konfiguracyjne
PYTHON = python3
PIP = pip3
POETRY = poetry
PROJECT_NAME = rpi-stt-tts-shell
SCAN_SCRIPT = scan.sh
DEPLOY_SCRIPT = deploy.sh
TEST_SCRIPT = test_script.sh
PROJECT_DIR = project_files
CSV_FILE = raspberry_pi_devices.csv
LOG_DIR = deployment_logs
DOC_DIR = docs

# Domyślny cel
all: help

# Instalacja projektu lokalnie używając Poetry
install:
	@echo "Instalowanie projektu $(PROJECT_NAME) przy użyciu Poetry..."
	$(POETRY) install
	@echo "Instalacja zakończona."

# Instalacja projektu lokalnie używając pip
install-pip:
	@echo "Instalowanie projektu $(PROJECT_NAME) przy użyciu pip..."
	$(PIP) install -e .
	@echo "Instalacja zakończona."

# Skanowanie sieci w poszukiwaniu urządzeń Raspberry Pi
scan:
	@echo "Skanowanie sieci w poszukiwaniu urządzeń Raspberry Pi..."
	chmod +x $(SCAN_SCRIPT)
	./$(SCAN_SCRIPT)
	@echo "Skanowanie zakończone. Wyniki zapisano w $(CSV_FILE)."

# Skanowanie określonego zakresu sieci
scan-range:
	@echo "Podaj zakres sieci do skanowania (np. 192.168.1.0/24):"
	@read range && chmod +x $(SCAN_SCRIPT) && ./$(SCAN_SCRIPT) -r $$range
	@echo "Skanowanie zakończone. Wyniki zapisano w $(CSV_FILE)."

# Wdrażanie projektu na wszystkie wykryte urządzenia
deploy:
	@echo "Wdrażanie projektu na wszystkie wykryte urządzenia Raspberry Pi..."
	@if [ ! -f $(CSV_FILE) ]; then \
		echo "BŁĄD: Plik $(CSV_FILE) nie istnieje. Najpierw uruchom 'make scan'."; \
		exit 1; \
	fi
	chmod +x $(DEPLOY_SCRIPT)
	./$(DEPLOY_SCRIPT)
	@echo "Wdrażanie zakończone. Logi zapisano w katalogu $(LOG_DIR)."

# Wdrażanie projektu na określone urządzenie IP
deploy-ip:
	@echo "Podaj adres IP urządzenia Raspberry Pi:"
	@read ip && chmod +x $(DEPLOY_SCRIPT) && ./$(DEPLOY_SCRIPT) -i $$ip
	@echo "Wdrażanie zakończone. Logi zapisano w katalogu $(LOG_DIR)."

# Wdrażanie projektu z niestandardowymi parametrami
deploy-custom:
	@echo "Podaj nazwę użytkownika SSH [pi]:"
	@read user && user=$${user:-pi} && \
	echo "Podaj hasło SSH [raspberry]:" && \
	read password && password=$${password:-raspberry} && \
	echo "Podaj katalog zdalny [/home/$$user/$(PROJECT_NAME)]:" && \
	read remote_dir && remote_dir=$${remote_dir:-/home/$$user/$(PROJECT_NAME)} && \
	chmod +x $(DEPLOY_SCRIPT) && \
	./$(DEPLOY_SCRIPT) -u $$user -p $$password -r $$remote_dir
	@echo "Wdrażanie zakończone. Logi zapisano w katalogu $(LOG_DIR)."

# Przygotowanie plików projektu
prepare-files:
	@echo "Przygotowanie plików projektu do wdrożenia..."
	mkdir -p $(PROJECT_DIR)
	$(POETRY) build
	cp -r dist/* $(PROJECT_DIR)/
	cp $(TEST_SCRIPT) $(PROJECT_DIR)/
	@echo "Pliki projektu przygotowane w katalogu $(PROJECT_DIR)."

# Uruchomienie testów lokalnie
test:
	@echo "Uruchamianie testów projektu $(PROJECT_NAME)..."
	$(POETRY) run pytest
	@echo "Testy zakończone."

# Generowanie dokumentacji
docs:
	@echo "Generowanie dokumentacji projektu $(PROJECT_NAME)..."
	mkdir -p $(DOC_DIR)
	$(POETRY) run pdoc --html --output-dir $(DOC_DIR) $(PROJECT_NAME)
	@echo "Dokumentacja wygenerowana w katalogu $(DOC_DIR)."

# Czyszczenie plików tymczasowych
clean:
	@echo "Czyszczenie plików tymczasowych..."
	rm -rf dist build *.egg-info __pycache__ .pytest_cache
	@echo "Czyszczenie zakończone."

# Czyszczenie wszystkich plików generowanych
clean-all: clean
	@echo "Czyszczenie wszystkich plików generowanych..."
	rm -rf $(LOG_DIR) $(DOC_DIR)
	@echo "Czy chcesz usunąć również plik CSV z wykrytymi urządzeniami? [y/N]"
	@read ans && [ "$$ans" = "y" ] && rm -f $(CSV_FILE) || true
	@echo "Czyszczenie zakończone."

# Aktualizacja zależności
update-deps:
	@echo "Aktualizacja zależności projektu..."
	$(POETRY) update
	@echo "Zależności zaktualizowane."

# Uruchomienie aplikacji
run:
	@echo "Uruchamianie aplikacji $(PROJECT_NAME)..."
	$(POETRY) run python -m $(PROJECT_NAME)
	@echo "Aplikacja zakończona."

# Uruchomienie aplikacji z uprawnieniami administratora
run-sudo:
	@echo "Uruchamianie aplikacji $(PROJECT_NAME) z uprawnieniami administratora..."
	sudo $(POETRY) run python -m $(PROJECT_NAME)
	@echo "Aplikacja zakończona."

# Pełny cykl: skanowanie, przygotowanie, wdrożenie
full-cycle: scan prepare-files deploy
	@echo "Pełny cykl wdrożenia zakończony pomyślnie."

# Wyświetlenie pomocy
help:
	@echo "$(PROJECT_NAME) - Makefile"
	@echo ""
	@echo "Dostępne cele:"
	@echo "  install         - Instalacja projektu lokalnie używając Poetry"
	@echo "  install-pip     - Instalacja projektu lokalnie używając pip"
	@echo "  scan            - Skanowanie sieci w poszukiwaniu urządzeń Raspberry Pi"
	@echo "  scan-range      - Skanowanie określonego zakresu sieci"
	@echo "  deploy          - Wdrażanie projektu na wszystkie wykryte urządzenia"
	@echo "  deploy-ip       - Wdrażanie projektu na określone urządzenie IP"
	@echo "  deploy-custom   - Wdrażanie projektu z niestandardowymi parametrami"
	@echo "  prepare-files   - Przygotowanie plików projektu do wdrożenia"
	@echo "  test            - Uruchomienie testów lokalnie"
	@echo "  docs            - Generowanie dokumentacji"
	@echo "  clean           - Czyszczenie plików tymczasowych"
	@echo "  clean-all       - Czyszczenie wszystkich plików generowanych"
	@echo "  update-deps     - Aktualizacja zależności"
	@echo "  run             - Uruchomienie aplikacji"
	@echo "  run-sudo        - Uruchomienie aplikacji z uprawnieniami administratora"
	@echo "  full-cycle      - Pełny cykl: skanowanie, przygotowanie, wdrożenie"
	@echo "  help            - Wyświetlenie tej pomocy"
	@echo ""
	@echo "Przykład użycia:"
	@echo "  make scan       # Skanowanie sieci"
	@echo "  make deploy     # Wdrożenie projektu"
	@echo ""