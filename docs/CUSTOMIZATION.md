# Customization Guide

How to adapt a deployment created from this template — and where each kind of
change belongs.

## Golden rule

**Template vs. deployment:** if a change should apply to *every* ChengetAi
DSpace instance, make it in this template repository and pull it into
deployments. If it is specific to *one* site, it belongs in that deployment's
gitignored files (`.env`, `config/local.cfg`) or in that deployment's own
repository history — never back in the template.

## Configuration layers (lowest to highest precedence)

1. **Image defaults** — `dspace.cfg` and friends baked into the DSpace images
2. **`config/local.cfg`** — mounted into the backend; the right place for most
   backend settings (handle prefix, auth methods, submission config, limits)
3. **Environment variables in `docker-compose.yml`** — reserved for values that
   come from `.env` (URLs, database, Solr, mail)

Don't set the same property in more than one layer. After changing
`config/local.cfg`, restart the backend: `docker compose restart dspace`.

## Common customizations

### Site identity

- Name: `DSPACE_NAME` in `.env`
- Default language: `default.locale` in `config/local.cfg`

### Authentication (LDAP / Shibboleth / OIDC)

Configure in `config/local.cfg` using the standard DSpace
`authentication-*.cfg` properties. Reference:
[DSpace Authentication Plugins](https://wiki.lyrasis.org/display/DSDOC/Authentication+Plugins).

### Handle prefix

Register a prefix at https://www.handle.net, then set `handle.prefix` in
`config/local.cfg`. Do this **before** ingesting real content — existing items
keep the prefix they were minted with.

### UI theming

The stock `dspace/dspace-angular` image ships the default theme with runtime
configuration only (colors/logo swaps require a custom build). For a branded
theme:

1. Create a theme in a fork of [dspace-angular](https://github.com/DSpace/dspace-angular)
   following the [UI customization docs](https://wiki.lyrasis.org/display/DSDOC/User+Interface+Customization)
2. Build and publish an image, e.g. `ghcr.io/wgmasvix-hue/chengetai-dspace-angular:<tag>`
3. Point the deployment at it by overriding the frontend image in a
   `docker-compose.override.yml`:

```yaml
services:
  dspace-angular:
    image: ghcr.io/wgmasvix-hue/chengetai-dspace-angular:9.0-chengetai.1
```

If the ChengetAi theme should be the default for all deployments, bake the
image reference into this template's `docker-compose.yml` instead.

### Metadata schemas, submission forms, workflows

These are backend configuration (`config/local.cfg` plus files under
`/dspace/config/` such as `submission-forms.xml`). To override whole config
files, add additional read-only mounts to a `docker-compose.override.yml`:

```yaml
services:
  dspace:
    volumes:
      - ./config/submission-forms.xml:/dspace/config/submission-forms.xml:ro
```

Commit such override files to the deployment's repository (they are not
secrets) and consider promoting them to the template if broadly useful.

## Keeping deployments up to date with the template

In a deployment created from this template:

```bash
git remote add template https://github.com/wgmasvix-hue/ChengetAi-DSPACE-Engine.git
git fetch template
git merge template/main
```

Because deployment state lives only in gitignored files, template updates
merge cleanly in the normal case.
