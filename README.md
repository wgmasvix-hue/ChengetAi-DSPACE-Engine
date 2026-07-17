# ChengetAi DSpace Engine — Deployment Template

**The dedicated template for all ChengetAi DSpace deployments.**

This repository is the single source of truth for standing up a DSpace instance
(backend REST API, Angular frontend, PostgreSQL, Solr) with Docker. Every new
deployment — development, staging, or production — starts from this template.

## Stack

| Service         | Image                                  | Purpose                            |
|-----------------|----------------------------------------|------------------------------------|
| `dspace`        | `dspace/dspace`                        | DSpace backend (REST API / server) |
| `dspace-angular`| `dspace/dspace-angular`                | DSpace frontend (Angular UI)       |
| `dspacedb`      | `dspace/dspace-postgres-pgcrypto`      | PostgreSQL database with pgcrypto  |
| `dspacesolr`    | `dspace/dspace-solr`                   | Solr search/discovery cores        |
| `proxy`         | `nginx` (production overlay only)      | TLS termination and reverse proxy  |

The DSpace version is pinned in `.env` via `DSPACE_VER` (default `dspace-9_x`)
so all services stay on matching releases.

## Quick start — the `chengetai` deploy CLI

On a fresh Ubuntu/Debian server, two commands take you from nothing to a
running DSpace:

```bash
curl -fsSL https://raw.githubusercontent.com/wgmasvix-hue/ChengetAi-DSPACE-Engine/main/install.sh | sudo bash
chengetai deploy
```

The installer clones this template into `/opt/chengetai` (override with
`CHENGETAI_HOME`), installs Docker and the compose plugin, and links the
`chengetai` command into your PATH. `chengetai deploy` then walks you through
an interactive setup (site name, dev/production mode, hostname, admin email —
the database password is generated for you), runs environment checks, starts
the stack, waits for the backend to come up, and creates your administrator
account.

```
chengetai init             interactive setup (.env + config/local.cfg)
chengetai deploy           checks + pull + start + wait + create admin
chengetai status           service status and deployment URLs
chengetai logs [service]   tail logs
chengetai admin            create an administrator account
chengetai backup           snapshot database + assetstore
chengetai restore <dir>    restore a snapshot
chengetai reindex          rebuild the search index
chengetai upgrade <tag>    backup, bump DSPACE_VER, migrate, reindex
chengetai doctor           check docker, RAM, disk, TLS certs, mail
chengetai nginx            HTTPS setup: certs (Let's Encrypt or self-signed) + proxy
chengetai nginx renew      renew certificates and reload the proxy
chengetai nginx status     certificate expiry and proxy state
```

Going public is one more command after `deploy`: `chengetai nginx` switches
the deployment to production mode, obtains a Let's Encrypt certificate for
your hostname (or generates a self-signed one for testing), starts the nginx
proxy on ports 80/443, and installs a weekly auto-renewal cron job.

### Manual quick start (without the installer)

```bash
git clone https://github.com/wgmasvix-hue/ChengetAi-DSPACE-Engine.git my-deployment
cd my-deployment
sudo ./scripts/bootstrap.sh    # fresh server only: installs make + Docker
./bin/chengetai deploy         # or the make/docker compose flow below
```

Prefer raw tooling? Every CLI command has a `make` target or plain
`docker compose` equivalent (see the Makefile), so the stack also works
without the CLI:

```bash
cp .env.example .env                          # set POSTGRES_PASSWORD + URLs
cp config/local.cfg.example config/local.cfg
make up && make admin
```

Then open:

- Frontend: http://localhost:4000
- REST API: http://localhost:8080/server
- Solr admin (bound to localhost only): http://localhost:8983/solr

## Production deployment

Production adds an nginx reverse proxy with TLS in front of the UI and API:

```bash
cp .env.example .env
# edit .env: set DEPLOY_ENV=production, DSPACE_HOSTNAME, strong POSTGRES_PASSWORD,
# and point DSPACE_UI_URL / DSPACE_REST_URL at your public hostname

# place TLS certificates
mkdir -p nginx/certs
# nginx/certs/fullchain.pem and nginx/certs/privkey.pem

make up-prod     # or: docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full production checklist
(DNS, certificates, mail, backups, upgrades).

## Repository layout

```
.
├── bin/
│   └── chengetai             # The deploy CLI (linked to /usr/local/bin by install.sh)
├── install.sh                # One-line installer: clone + bootstrap + link CLI
├── docker-compose.yml        # Core stack (backend, frontend, db, solr)
├── docker-compose.prod.yml   # Production overlay (nginx + TLS, restart policies)
├── .env.example              # All tunables — copy to .env per deployment
├── Makefile                  # Shortcuts: make up / down / logs / backup / restore
├── config/
│   └── local.cfg.example     # DSpace backend overrides (mounted into the container)
├── nginx/
│   └── nginx.conf.template   # Reverse proxy config (envsubst on DSPACE_HOSTNAME)
├── scripts/
│   ├── bootstrap.sh          # Prepare a fresh Ubuntu/Debian server (make, Docker)
│   ├── init-admin.sh         # Create the first DSpace administrator
│   ├── backup.sh             # Dump database + assetstore to ./backups
│   └── restore.sh            # Restore a backup produced by backup.sh
└── docs/
    ├── DEPLOYMENT.md         # Full deployment guide and production checklist
    └── CUSTOMIZATION.md      # Theming, configuration, and per-site changes
```

## Using this repo as a template

1. On GitHub, enable **Settings → Template repository** so new deployments can
   be created with *"Use this template"* instead of forking.
2. One deployment = one repository (or one branch) created from this template.
   Deployment-specific state lives only in `.env`, `config/local.cfg`, and
   `nginx/certs/` — all of which are gitignored.
3. Improvements that benefit every deployment are made **here**, then pulled
   into deployments. Never patch a deployment in a way you'd want everywhere.

## Operations

| Task                    | CLI                            | Make equivalent                           |
|-------------------------|--------------------------------|-------------------------------------------|
| Start / stop            | `chengetai up` / `down`        | `make up` / `make down`                   |
| Tail logs               | `chengetai logs`               | `make logs`                               |
| Create admin account    | `chengetai admin`              | `make admin`                              |
| Backup db + assetstore  | `chengetai backup`             | `make backup`                             |
| Restore a backup        | `chengetai restore <dir>`      | `make restore BACKUP=backups/<timestamp>` |
| Reindex discovery       | `chengetai reindex`            | `make reindex`                            |
| Upgrade DSpace version  | `chengetai upgrade <tag>`      | bump `DSPACE_VER` in `.env`, see docs     |

## License

Configuration in this template is provided under the MIT license.
DSpace itself is licensed under the [DSpace BSD License](https://github.com/DSpace/DSpace/blob/main/LICENSE).
