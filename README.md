# tabsh on Railway

Railway template and container image for [tabsh](https://github.com/Blaise1030/tabsh): shells and coding agents in a browser tab, with a board for every card.

Upstream ships release binaries that listen on 127.0.0.1 only. This image runs the checksum-verified binary behind Caddy, which:

- rewrites `Host` to `127.0.0.1:7681`, because tabsh refuses any DNS host name (its DNS-rebinding guard has no override);
- puts basic auth (`TABSH_USER` / `TABSH_PASSWORD`) on every path except `/api/*` and `/ws`, which tabsh itself refuses without its pairing token;
- serves `/healthz` from tabsh's public PWA manifest for Railway's healthchecker.

| File | What it is |
|---|---|
| `Dockerfile`, `Caddyfile`, `boot.sh` | The image (`ghcr.io/hmseeb/tabsh-railway`) |
| `template.json` | Template build sheet, the regeneration master |
| `upsert.py`, `publish.py`, `deploy_as_stranger.py` | Write, publish and test-deploy the template |
| `test/contract.sh` | Auth contract against a running deploy |
| `TEMPLATE_OVERVIEW.md` | Marketplace listing copy |

Run locally:

```sh
docker build -t tabsh-rw . && docker run --rm -p 8080:8080 -e TABSH_PASSWORD=change-me -v tabsh-data:/data tabsh-rw
test/contract.sh http://localhost:8080 change-me
```
