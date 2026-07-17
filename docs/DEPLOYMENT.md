# Deployment Guide

This guide walks through deploying a DSpace instance from this template, from
a local development stack to a hardened production deployment.

**Shortest path:** the `chengetai` deploy CLI automates sections 1–3 of this
guide. On a fresh Ubuntu/Debian server:

```bash
curl -fsSL https://raw.githubusercontent.com/wgmasvix-hue/ChengetAi-DSPACE-Engine/main/install.sh | sudo bash
chengetai deploy
```

The rest of this document explains what the CLI does under the hood, and is
the reference for manual or non-Debian deployments.

## Prerequisites

- Docker Engine 24+ with the Docker Compose plugin (`docker compose version`)
- `make` (optional convenience — every target has a raw `docker compose` equivalent)
- 8 GB RAM minimum (backend + Solr are memory-hungry), 4 CPU cores recommended
- For production: a DNS name pointing at the host, and TLS certificates

On a fresh Ubuntu/Debian server, install everything in one step:

```bash
sudo ./scripts/bootstrap.sh
```

## 1. Create a deployment from the template

Each deployment gets its own repository (via GitHub's *"Use this template"*)
or its own clone. The template files are never edited in a deployment — all
per-site state lives in gitignored files:

| File               | Purpose                              | Created from             |
|--------------------|--------------------------------------|--------------------------|
| `.env`             | Ports, URLs, credentials, versions   | `.env.example`           |
| `config/local.cfg` | DSpace backend configuration         | `config/local.cfg.example` |
| `nginx/certs/`     | TLS certificate and key (production) | your CA / Let's Encrypt  |

```bash
cp .env.example .env
cp config/local.cfg.example config/local.cfg
```

Edit `.env` and set at minimum `POSTGRES_PASSWORD`. Without it the stack
refuses to start (the compose file enforces it).

## 2. Development deployment

```bash
make up
make logs        # wait for "Server startup" from the backend
make admin       # create the first administrator
```

- Frontend: http://localhost:4000
- REST API: http://localhost:8080/server (HAL browser at /server for testing)
- Solr admin: http://localhost:8983/solr (localhost only)

First startup runs Flyway database migrations automatically and can take a few
minutes; subsequent starts are fast.

## 3. Production deployment

### 3.1 Configure

In `.env`:

```bash
DEPLOY_ENV=production
DSPACE_HOSTNAME=repository.yourdomain.org
DSPACE_UI_URL=https://repository.yourdomain.org
DSPACE_REST_URL=https://repository.yourdomain.org/server
POSTGRES_PASSWORD=<strong random password>
MAIL_SERVER=<your smtp relay>          # registration & notifications need mail
MAIL_FROM_ADDRESS=noreply@yourdomain.org
```

### 3.2 TLS certificates + nginx (automated)

One command does the whole HTTPS setup:

```bash
chengetai nginx
```

It confirms your public hostname (switching `.env` to production mode and
rewriting the URLs if needed), obtains a Let's Encrypt certificate via a
dockerized certbot (`chengetai nginx selfsigned` generates a throwaway cert
for testing instead), installs the PEMs into `nginx/certs/`, starts the stack
behind the proxy, and adds a weekly renewal cron job
(`/etc/cron.d/chengetai-cert-renew`). Requirements: DNS for the hostname
already points at this server, and port 80 is reachable from the internet.

Manage it afterwards with:

```bash
chengetai nginx status   # certificate subject, expiry, proxy state
chengetai nginx renew    # force a renewal now (also what the cron job runs)
```

**Manual alternative** — bring your own certificates by placing PEM files at:

```
nginx/certs/fullchain.pem
nginx/certs/privkey.pem
```

then run `make up-prod`. On renewal, re-copy the files and
`docker compose restart proxy`.

### 3.3 Launch

```bash
make up-prod   # not needed if chengetai nginx already started the stack
make admin
```

In production only nginx (ports 80/443) is exposed; the backend, UI, database,
and Solr are reachable solely on the internal compose network.

### 3.4 Production checklist

- [ ] `POSTGRES_PASSWORD` is strong and stored in a secrets manager
- [ ] Real handle prefix registered and set in `config/local.cfg`
- [ ] Mail delivery tested (`docker compose exec dspace /dspace/bin/dspace test-email`)
- [ ] Nightly `make backup` scheduled (cron/systemd timer) and backups shipped off-host
- [ ] Restore procedure tested at least once (`make restore BACKUP=...`)
- [ ] Host firewall allows only 22/80/443 inbound
- [ ] Monitoring on `https://<host>/server/actuator/health` (backend health endpoint)

## 4. Upgrades

1. Take a backup: `make backup`
2. Bump `DSPACE_VER` in `.env` (one minor version at a time for major upgrades;
   read the [DSpace release notes](https://wiki.lyrasis.org/display/DSDOC/Release+Notes) first)
3. `make pull && make up-prod` (or `make up`) — migrations run automatically on start
4. Rebuild the search index: `make reindex`
5. Verify the UI, submission workflow, and search

## 5. Routine operations

| Task            | Command |
|-----------------|---------|
| Status          | `make ps` |
| Logs            | `make logs` |
| Backup          | `make backup` |
| Restore         | `make restore BACKUP=backups/<timestamp>` |
| Reindex search  | `make reindex` |
| Backend CLI     | `docker compose exec dspace /dspace/bin/dspace <command>` |

## Troubleshooting

- **Backend restarts repeatedly on first boot** — usually the database wasn't
  ready or `POSTGRES_PASSWORD` changed after the `pgdata` volume was created.
  Check `docker compose logs dspacedb dspace`.
- **UI shows "Service Unavailable"** — the Angular SSR can't reach the REST
  API. Verify `DSPACE_REST_HOST=dspace` and that the backend reports healthy.
- **Search returns nothing after a restore or upgrade** — run `make reindex`.
- **Uploads fail over ~512 MB** — raise `client_max_body_size` in
  `nginx/nginx.conf.template` and the multipart limits in `config/local.cfg`.
