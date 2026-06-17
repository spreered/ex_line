# Vendored LINE OpenAPI spec

Source of truth for conformance tests (`ExLine.Conformance`).

- Origin: <https://github.com/line/line-openapi>
- File: `messaging-api.yml`
- Pinned commit: `779d8ca9e632` (2026-04-13)

## Updating

Re-vendor and let the conformance tests re-check our output against the new spec:

```sh
COMMIT=<new-commit-sha>
curl -s "https://raw.githubusercontent.com/line/line-openapi/$COMMIT/messaging-api.yml" \
  -o test/support/line_openapi/messaging-api.yml
```

Then bump the commit above, `git diff` the YAML to see what changed, and run
`mix test`. Any spec change our code violates turns the relevant conformance test
red — fix the code, then commit.
