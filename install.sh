#!/usr/bin/env bash
# Nodeside Ausbildung – Installation/Update auf dem VPS (als root ausführen)
# Legt den Bereich https://www.nodeside.eu/ausbildung/ an, erste App: /ausbildung/mfa/
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Nodeside2025/nodeside-ausbildung/main"
TARGET="/var/www/ausbildung"
SNIPPET="/etc/nginx/snippets/nodeside-ausbildung.conf"
SITECONF="/etc/nginx/sites-available/nodeside.eu"
TS="$(date +%Y-%m-%d_%H%M)"

echo "== 1/6 Backup"
mkdir -p /root/backups
tar -czf "/root/backups/nodeside-backup-${TS}.tar.gz" /var/www/nodeside.eu /var/www/portal /var/www/portal-data /etc/nginx $( [ -d "$TARGET" ] && echo "$TARGET" ) 2>/dev/null
cp "$SITECONF" "/root/backups/nodeside.eu.nginx-${TS}.conf"
echo "   /root/backups/nodeside-backup-${TS}.tar.gz"

echo "== 2/6 App herunterladen"
TMP="$(mktemp -d)"
curl -fsSL "$REPO_RAW/nodeside-ausbildung-mfa.zip" -o "$TMP/mfa.zip"
command -v unzip >/dev/null || apt-get install -y -qq unzip
unzip -q "$TMP/mfa.zip" -d "$TMP/mfa"
test -s "$TMP/mfa/index.html" && grep -q "</html>" "$TMP/mfa/index.html" || { echo "index.html unvollständig – Abbruch"; exit 1; }

echo "== 3/6 Dateien nach $TARGET/mfa"
mkdir -p "$TARGET/mfa"
cp -a "$TMP/mfa/." "$TARGET/mfa/"
chown -R www-data:www-data "$TARGET"
find "$TARGET" -type d -exec chmod 755 {} +
find "$TARGET" -type f -exec chmod 644 {} +
rm -rf "$TMP"

echo "== 4/6 nginx-Bereich /ausbildung"
cat > "$SNIPPET" <<'EOF'
# Nodeside Ausbildung – eigener Bereich (/var/www/ausbildung)
location = /ausbildung  { return 301 /ausbildung/; }
location = /ausbildung/ { return 302 /ausbildung/mfa/; }
location ^~ /ausbildung/ {
    alias /var/www/ausbildung/;
    index index.html;
    try_files $uri $uri/ =404;
    add_header Cache-Control "no-cache" always;
    add_header X-Content-Type-Options nosniff always;
}
EOF
if ! grep -q "snippets/nodeside-ausbildung.conf" "$SITECONF"; then
  # nur im ersten Serverblock (HTTPS) direkt nach der root-Zeile einfügen
  sed -i '0,/^\s*root \/var\/www\/nodeside\.eu;/s//&\n    include snippets\/nodeside-ausbildung.conf;/' "$SITECONF"
fi
grep -n "nodeside-ausbildung" "$SITECONF"

echo "== 5/6 nginx prüfen"
if nginx -t; then
  systemctl reload nginx
else
  echo "nginx -t fehlgeschlagen – stelle alte Konfiguration wieder her"
  cp "/root/backups/nodeside.eu.nginx-${TS}.conf" "$SITECONF"
  rm -f "$SNIPPET"
  nginx -t && systemctl reload nginx
  exit 1
fi

echo "== 6/6 Live-Test"
sleep 1
for u in /ausbildung/mfa/ /ausbildung/mfa/sw.js /ausbildung/mfa/manifest.webmanifest /ausbildung/mfa/icon-192.png; do
  printf "   %-40s %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code} %{size_download}B' "https://www.nodeside.eu$u")"
done
printf "   %-40s %s\n" "Startseite nodeside.eu" "$(curl -s -o /dev/null -w '%{http_code}' https://www.nodeside.eu/)"
echo "FERTIG: https://www.nodeside.eu/ausbildung/mfa/"
