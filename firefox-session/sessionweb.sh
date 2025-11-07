#!/bin/bash
set -eou pipefail

PROXY_TYPE=""
PROXY_HOST=""
PROXY_PORT=""
TMP_RAM_SIZE=64

while [ $# -gt 0 ]; do
  case "$1" in
    --proxy-type)
      PROXY_TYPE="${2:-}"; shift 2;;
    --proxy-host)
      PROXY_HOST="${2:-}"; shift 2;;
    --proxy-port)
      PROXY_PORT="${2:-}"; shift 2;;
    --tmp-size)
      TMP_RAM_SIZE="${2:-$TMP_RAM_SIZE}"; shift 2;;
    --help|-h)
      echo "Usage: $0 [--proxy-type socks|http] [--proxy-host HOST] [--proxy-port PORT] [--tmp-size MB]"
      exit 0;;
    *)
      echo "Unknown option: $1" >&2
      exit 1;;
  esac
done

FIREFOX_BIN="$(command -v firefox || true)"
if [ -z "$FIREFOX_BIN" ]; then
  echo "[#] Firefox binary not found in PATH."
  exit 2
fi

TMP_BASE="$(mktemp -d /tmp/firefox-opsec.XXXXXXXX)"
chmod 700 "$TMP_BASE"

TMP_PROFILE="${TMP_BASE}/profile"

if mountpoint -q "$TMP_BASE"; then
  echo "[#] $TMP_BASE already mount."
else
  echo "[#] Mount of tmpfs on $TMP_BASE (${TMP_RAM_SIZE}M)..."
  sudo mount -t tmpfs -o size="${TMP_RAM_SIZE}M",noatime tmpfs "$TMP_BASE"
fi

mkdir -p "$TMP_PROFILE"
if [ ! -d "$TMP_PROFILE" ]; then
    echo "[!] Impossible de créer le dossier $TMP_PROFILE"
    exit 1
fi

chmod 700 "$TMP_PROFILE"

cleanup () {
  set +e
  echo "[#] CLEANUP..."
  if [ -n "${FIREFFOX_PID:-}" ]; then
    if kill -0 "$FIREFOX_PID" 2>/dev/null; then
      echo "[#] Killign firefox (pid $FIREFOX_PID)..."
      kill "$FIREFOX_PID" 2>/dev/null || true
      sleep 1
    fi
  fi
  if mountpoint -q "$TMP_BASE"; then
    echo "[#] Unmounting $TMP_BASE..."
    sudo umount "$TMP_BASE" 2>/dev/null || unmount -l "$TMP_BASE" 2>/dev/null || true
  fi
  if [ -d "$TMP_BASE" ]; then
    echo "[#] Finding and removing $TMP_BASE..."
    find "$TMP_BASE" -type f 2>/dev/null
    rm -rf "$TMP_BASE" 2>/dev/null || true
  fi
  echo "[#] CLEANUP finished."
}

USERJS_PATH="${TMP_PROFILE}/user.js"

PROXY_PREFS=""
if [ -n "$PROXY_HOST" ] && [ -n "$PROXY_PORT" ]; then
  case "${PROXY_TYPE}" in
    socks)
      PROXY_PREFS=$(cat <<EOF
user_pref("network.proxy.type", 1);
user_pref("network.proxy.socks", "${PROXY_HOST}");
user_pref("network.proxy.socks_port", ${PROXY_PORT});
# utiliser le DNS distant quand SOCKS
user_pref("network.proxy.socks_remote_dns", true);
EOF
);;
  http)
    PROXY_PREFS=$(cat <<EOF
user_pref("network.proxy.type", 1);
user_pref("network.proxy.http", "${PROXY_HOST}");
user_pref("network.proxy.http_port", ${PROXY_PORT});
user_pref("network.proxy.no_proxies_on", "localhost, 127.0.0.1");
EOF
);;
  *)
    PROXY_PREFS='user_pref("network.proxy.type", 0);';;
  esac
else
  PROXY_PREFS='user_pref("network.proxy.type", 0);'
fi

cat >> "$USERJS_PATH" <<'COMMON_PREFS'
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.firstparty.isolate", true);
user_pref("network.cookie.cookieBehavior", 1);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.prefetch-next", false);
user_pref("browser.send_pings", false);
user_pref("media.peerconnection.enabled", false);
user_pref("dom.webnotifications.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("browser.privatebrowsing.autostart", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
COMMON_PREFS

printf "%s\n" "$PROXY_PREFS" >> "$USERJS_PATH"

chmod 600 "$USERJS_PATH"

echo "[#] Starting of the firefox session..."
"$FIREFOX_BIN" --no-remote --new-instance -profile "$TMP_PROFILE" >/dev/null 2>&1 & FIREFOX_PID=$!


echo "[#] Firefox pid: $FIREFOX_PID"

wait "$FIREFOX_PID" || true

cleanup
