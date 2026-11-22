FROM cloudflare/cloudflared:latest AS cf
FROM ghcr.io/xtls/xray-core:latest AS xr
FROM caddy:2-alpine AS cd
FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
COPY --from=cf /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=xr /usr/local/bin/xray /usr/local/bin/xray
COPY --from=cd /usr/bin/caddy /usr/local/bin/caddy
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
