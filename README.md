# fleet-node

VLESS+WS node image for free PaaS fleets. One container, three processes:

- Caddy on :PORT (default 8080) — public face: /healthz returns 200, the WS path is reverse-proxied to Xray, everything else 404
- Xray on 127.0.0.1:8081 — VLESS+WS inbound, path /<UUID>-vl
- cloudflared (only when TUNNEL_TOKEN is set) — Argo tunnel to Caddy

Runtime configuration is entirely via environment variables:

- UUID (required) — VLESS user id; also determines the WS path
- PORT (optional, default 8080) — port Caddy listens on
- TUNNEL_TOKEN (optional) — Cloudflare Tunnel token; leave empty to serve on the platform's own ingress

The image is built by GitHub Actions and published to ghcr.io/iam-otakun/fleet-node:latest.
