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

## Quick start (development)

```bash
# 1. Start a new deployment from this template
git clone https://github.com/wgmasvix-hue/ChengetAi-DSPACE-Engine.git my-deployment
cd my-deployment

# 2. Configure it
cp .env.example .env
# edit .env — at minimum set POSTGRES_PASSWORD

# 3. Launch the stack
make up          # or: docker compose up -d

# 4. Create the first administrator account
make admin       # or: ./scripts/init-admin.sh
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
├── docker-compose.yml        # Core stack (backend, frontend, db, solr)
├── docker-compose.prod.yml   # Production overlay (nginx + TLS, restart policies)
├── .env.example              # All tunables — copy to .env per deployment
├── Makefile                  # Shortcuts: make up / down / logs / backup / restore
├── config/
│   └── local.cfg.example     # DSpace backend overrides (mounted into the container)
├── nginx/
│   └── nginx.conf.template   # Reverse proxy config (envsubst on DSPACE_HOSTNAME)
├── scripts/
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

| Task                    | Command                                  |
|-------------------------|------------------------------------------|
| Start / stop            | `make up` / `make down`                  |
| Tail logs               | `make logs`                              |
| Create admin account    | `make admin`                             |
| Backup db + assetstore  | `make backup`                            |
| Restore a backup        | `make restore BACKUP=backups/<timestamp>`|
| Reindex discovery       | `make reindex`                           |
| Upgrade DSpace version  | bump `DSPACE_VER` in `.env`, see docs    |

## License

Configuration in this template is provided under the MIT license.
DSpace itself is licensed under the [DSpace BSD License](https://github.com/DSpace/DSpace/blob/main/LICENSE).
