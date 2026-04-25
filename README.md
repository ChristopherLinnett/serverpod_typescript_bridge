# serverpod_typescript_bridge

Generate a fully-typed TypeScript client for a Serverpod project — the same way `serverpod generate` produces the Dart client today.

## Status

**Pre-alpha.** Under active construction. Not usable yet.

## What it will do

Given a Serverpod project, this package generates a sibling package
`<project_name>_typescript_client` containing:

- A typed TypeScript client for every endpoint
- TypeScript classes for every Serverpod model (with all primitive and complex
  type conversions handled)
- All Dart doc comments preserved as TSDoc
- A build-ready package (`tsconfig.json`, `package.json`, compiled `dist/`) so
  it can be consumed by any TypeScript/JavaScript frontend (React, Vue, etc.)

## Goals

- **Drop-in parity** with `serverpod generate` for the Dart client. Same options, same workflow.
- **No re-definition.** Endpoints, models, and docs come straight from the Serverpod project.
- **Type-safe end-to-end.** All Dart primitives map to ergonomic TypeScript primitives.
- **Zero runtime divergence.** The generated client uses the same wire protocol as the Dart client.

## Usage (planned)

```bash
# inside a Serverpod project
dart pub add --dev serverpod_typescript_bridge
dart run serverpod_typescript_bridge generate
```

This produces `<project_name>_typescript_client/` next to your existing
`<project_name>_client/` Dart package.

## License

TBD.
