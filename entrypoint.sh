#!/bin/sh
# Free-fleet PaaS node.
#   Caddy on :PORT (default 8080) — public face: /healthz -> 200, WS path -> xray, else 404
#   xray on :8081 — VLESS+WS inbound, path /<UUID>-vl
#   cloudflared (only when TUNNEL_TOKEN set) — Argo tunnel to Caddy
# Env: UUID (required), PORT (default 8080), TUNNEL_TOKEN (optional)
set -e
PORT="${PORT:-8080}"
if [ -z "$UUID" ]; then
  echo "UUID env is required" >&2
  exit 1
fi
WS_PATH="/${UUID}-vl"
cat > /tmp/xray.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 8081,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "${UUID}"}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "${WS_PATH}"}
      }
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
cat > /tmp/Caddyfile <<EOF
{
  admin off
  auto_https off
}
:${PORT} {
  handle /healthz {
    respond "ok" 200
  }
  handle ${WS_PATH} {
    reverse_proxy 127.0.0.1:8081
  }
  handle {
    respond "" 404
  }
}
EOF
if [ -n "$TUNNEL_TOKEN" ]; then
  echo "starting cloudflared (argo, http2)"
  ( while true; do
      cloudflared tunnel --no-autoupdate --protocol http2 run --token "$TUNNEL_TOKEN"
      echo "cloudflared exited, retry in 5s" >&2
      sleep 5
    done ) &
fi
echo "starting caddy on :${PORT}"
caddy run --config /tmp/Caddyfile --adapter caddyfile &
echo "starting xray on :8081 path ${WS_PATH}"
exec xray run -config /tmp/xray.json
