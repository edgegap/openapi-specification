# Agent guidance

This repo holds Edgegap's public OpenAPI 3.0 specifications:

- `edgegap-v1-openapi.yaml` — v1 API
- `edgegap-v2-openapi.yaml` — v2 API

The specs are maintained by hand. Keep edits minimal and preserve the existing
formatting (2-space indentation, `>-` folded descriptions, field order).

## Rules for every change to a spec

1. **Bump `info.version`** in every spec file you change, to today's date in
   `YYYY.MM.DD` format (e.g. `2026.11.23`). It's at the top of the file under
   `info:`. Only bump the files you actually changed.
2. **Match the real API.** The specs document what the API actually accepts
   and returns. Don't document fields, constraints or pagination the API doesn't
   have. If you're unsure how the API behaves, ask before changing the spec.
3. **Keep v1 and v2 consistent** for concepts they share. For example,
   environment variables use `is_hidden` (not `is_secret`) in both.
4. **Check the whole file** for other copies of what you're changing. The same
   schema is often defined inline in a path and again under
   `components/schemas`.

## Checks

Every PR to `main` must pass these required checks (enforced by a ruleset,
`main` can't be pushed to directly):

- `Validate edgegap-v1-openapi.yaml` / `Validate edgegap-v2-openapi.yaml` —
  validates each spec in Swagger Editor
  (`.github/workflows/validate-openapi.yml`).
- `Check spec version bump` — fails if a spec changed without its
  `info.version` being set to today's date
  (`.github/workflows/check-version-bump.yml`).

Run the version check locally before opening a PR:

```sh
bash .github/scripts/check-version-bump.sh origin/main
```
