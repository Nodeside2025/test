# Nodeside Ausbildung

Lern-Apps von Nodeside unter **https://www.nodeside.eu/ausbildung/**.

| App | Pfad | Inhalt |
|---|---|---|
| Lernfeld-Kompass MFA | `/ausbildung/mfa/` | Ausbildung Medizinische Fachangestellte in Schleswig-Holstein: 12 Lernfelder nach Ausbildungsjahr, Karteikarten, Übungsarbeiten mit Note, Prüfungstraining |

## Aufbau auf dem VPS

- Dateien: `/var/www/ausbildung/<app>/` (Besitzer `www-data`)
- nginx: `/etc/nginx/snippets/nodeside-ausbildung.conf`, eingebunden im HTTPS-Serverblock von `/etc/nginx/sites-available/nodeside.eu`
- Statische Seiten ohne Backend; der Lernfortschritt liegt im Browser (localStorage)

## Installieren / aktualisieren

Als root auf dem VPS:

```bash
curl -fsSL https://raw.githubusercontent.com/Nodeside2025/nodeside-ausbildung/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

Das Skript sichert vorher nach `/root/backups/`, prüft mit `nginx -t` und stellt bei Fehlern die alte Konfiguration wieder her.

## Dateien

- `nodeside-ausbildung-mfa.zip` – fertige App (index.html, sw.js, Manifest, Icons)
- `quellcode-mfa.zip` – Quellen: `src/data1.js` (LF 1–4), `data2.js` (LF 5–8), `data3.js` (LF 9–12), `app.js`, `shell.html`, `build.py`
- `install.sh` – Installation auf dem VPS
