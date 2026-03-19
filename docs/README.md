# Documentation Schemas

## Cangjie API index

- Schema: `cangjie-doc-index.schema.json`
- Example: `cangjie-doc-index.example.json`

Recommended conventions:

- Use `id` as the stable primary key. Do not derive identity from `doc_url`.
- Keep `summary_md` short and put long-form docs in `details_md`.
- Store `doc_url` as a stable relative path when the renderer is local.
- Fill `search_text` during indexing so UI and search backends do not need to concatenate fields at query time.
- For overloaded callables, keep both a stable `id` and a separate `overload_key`.

## Build

Generate a `docs-index.json` artifact locally:

```sh
python3 scripts/build-docs-index.py --source docs/cangjie-doc-index.example.json --output dist/docs-index.json
```

The repository also includes a GitHub Actions workflow at `.github/workflows/docs-index.yml` that builds the same artifact on push, pull request, or manual dispatch and uploads it as the `docs-index` artifact.
