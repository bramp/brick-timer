# Rebrickable API Reference (Local)

This repository uses the Rebrickable v3 LEGO API.

This file is a local developer reference so you do not need to hunt through
the live docs for common integration details.

## Official Docs

- Main docs: https://rebrickable.com/api/
- Interactive docs: https://rebrickable.com/api/v3/docs/
- API base URL used by this repo: https://rebrickable.com/api/v3/lego
- Package-local OpenAPI snapshot:
  `packages/lego_catalog/docs/rebrickable_openapi.json`

## Authentication

Use an API key in the `Authorization` header:

```http
Authorization: key YOUR_REBRICKABLE_API_KEY
```

The app and CLI pull this from:

- `REBRICKABLE_API_KEY` environment variable, or
- explicit `--api-key` CLI flag.

## Endpoints Used In This Repo

### Search Sets

- Method: `GET`
- Path: `/sets/`
- Full URL: `https://rebrickable.com/api/v3/lego/sets/`

Common query params currently used by this repo:

- `search` (string)
- `page_size` (int)

Example:

```http
GET /api/v3/lego/sets/?search=Lamborghini&page_size=20
Authorization: key YOUR_REBRICKABLE_API_KEY
```

### Set Details

- Method: `GET`
- Path: `/sets/{set_num}/`
- Full URL example:
  `https://rebrickable.com/api/v3/lego/sets/42115-1/`

Example:

```http
GET /api/v3/lego/sets/42115-1/
Authorization: key YOUR_REBRICKABLE_API_KEY
```

## Project Code References

- Backend implementation:
  `packages/lego_catalog/lib/src/backends/rebrickable_backend.dart`
- CLI entrypoint:
  `packages/lego_catalog/bin/lego_catalog.dart`

## Refreshing This Local Reference

When the integration changes, update this file and include:

- the new endpoint/params,
- the reason for the change,
- and the date of the update in the commit message.

Refresh the package-local OpenAPI snapshot with:

```bash
curl -fL "https://rebrickable.com/api/v3/swagger/?format=openapi" \
  | jq . > packages/lego_catalog/docs/rebrickable_openapi.json
```
