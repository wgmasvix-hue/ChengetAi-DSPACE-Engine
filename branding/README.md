# Branding

`logo.svg` (deployment-local, created from `logo.default.svg` on first start)
is mounted over the DSpace UI's header logo
(`assets/images/dspace-logo.svg` inside the `dspace-angular` container), so the
header shows your brand instead of the DSpace logo.

The easy way to change it:

```bash
chengetai brand "Dare Digital Resources"            # generates a text wordmark
chengetai brand "Dare Digital Resources" my-logo.svg  # or use your own SVG
```

`brand` also sets the site name (`DSPACE_NAME`, used in page titles and
emails) and restarts the UI. Hard-refresh the browser (Ctrl+Shift+R)
afterwards — the old logo is often cached.

For deeper white-labeling (homepage text, footer, colors) you need a themed
`dspace-angular` image — see `docs/CUSTOMIZATION.md`.
