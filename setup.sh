#!/usr/bin/env bash
# ------------------------------------------------------------------
#  LAN File Share - one-shot setup for Linux / WSL
#
#  Creates ~/fileshare/{data,www,conf,temp,logs}, copies the web UI,
#  drops in a password-file template, and generates nginx.conf with
#  your real paths.  Run it from inside the unzipped folder:
#
#      bash setup.sh
#
#  Override the location with:   SHARE_DIR=/some/where bash setup.sh
# ------------------------------------------------------------------
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SHARE="${SHARE_DIR:-$HOME/fileshare}"
USER_NAME="$(whoami)"

echo "Installing into: $SHARE"
mkdir -p "$SHARE/data" "$SHARE/www" "$SHARE/conf" "$SHARE/temp" "$SHARE/logs"

# web UI
cp "$HERE/www/index.html" "$SHARE/www/index.html"

# password file - don't clobber an existing one
if [ ! -f "$SHARE/conf/.htpasswd" ]; then
    cp "$HERE/conf/htpasswd.example" "$SHARE/conf/.htpasswd"
    echo "Created a starter password file at $SHARE/conf/.htpasswd"
else
    echo "Keeping your existing password file."
fi

# generate the nginx config with real paths
sed -e "s|__SHARE__|$SHARE|g" -e "s|__USER__|$USER_NAME|g" \
    "$HERE/nginx.conf.template" > "$SHARE/nginx.conf"

NGINX_BIN="nginx"
command -v nginx >/dev/null 2>&1 || NGINX_BIN="/usr/sbin/nginx"

cat <<EOF

Done.  Your share lives in:  $SHARE
Shared files go in:         $SHARE/data

Next steps
----------
 1. Set your login (edit the last line):
      nano $SHARE/conf/.htpasswd          #  format:  username:password

 2. Check the config:
      $NGINX_BIN -t -c $SHARE/nginx.conf

 3. Start it:
      $NGINX_BIN -c $SHARE/nginx.conf

 4. Open:  http://localhost:8080/

Stop it later with:   $NGINX_BIN -s stop -c $SHARE/nginx.conf
Reload after edits:   $NGINX_BIN -s reload -c $SHARE/nginx.conf
EOF
