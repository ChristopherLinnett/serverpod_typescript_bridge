# Contributing to serverpod_typescript_bridge

## Local setup

```bash
git clone https://github.com/ChristopherLinnett/serverpod_typescript_bridge
cd serverpod_typescript_bridge
dart pub get

# install the vendored TypeScript runtime's deps (vitest, tsc)
cd lib/runtime/typescript && npm install && cd -
```

## Running the test suites

The project has two test layers — a Dart suite (generator + analyzer + e2e) and a TypeScript suite (runtime).

```bash
# Dart side: 112 cases (as of v0.3.0) incl. e2e against both fixtures and
# the live round trip against a running fixture server (needs Node 22+)
dart analyze
dart test

# TypeScript runtime side: 96 vitest cases
cd lib/runtime/typescript
npm run typecheck
npm test
```

Both layers must pass before opening a PR.

## Adding a new fixture case

The two fixtures live under `test/fixtures/`:

- **`sample_server/`** — the v0.1 parity oracle: a server-type Serverpod project covering every supported feature.
- **`sample_module/`** — a minimal module-type Serverpod project.

To add a new feature surface (e.g. exercising a new wire-format edge case):

1. Add or edit the relevant `.dart` endpoint or `.spy.yaml` model under `test/fixtures/sample_server/sample_server/lib/src/{endpoints,models}/`.
2. Regenerate Serverpod's own server + Dart-client output:
   ```bash
   tool/regenerate_fixtures.sh
   ```
   The script runs the `serverpod_cli` this package resolves rather than whatever `serverpod` is activated globally — the fixtures' generated Dart is the reference output, so it has to come from the version in `pubspec.yaml`.
3. Commit the fixture changes alongside the regenerated `lib/src/generated/` and `../sample_client/lib/src/protocol/` files.
4. Update the smoke test (`test/sample_server_fixture_test.dart`) so the new surface is asserted.
5. Add a check to `test/live/roundtrip.mjs` that calls the new surface on the running server and asserts what comes back. A feature is supported when that check passes, not when its output type-checks.

## Running the integration tests locally

The `test/generate_command_test.dart` and `test/module_emission_test.dart` end-to-end tests:

1. Spawn the CLI as a subprocess against the relevant fixture
2. Type-check the generated TypeScript with the runtime's local `tsc`

Both rely on the runtime's `node_modules` having been installed (see the local-setup step above). Without it, the tsc step is silently skipped.

`test/live_roundtrip_test.dart` goes further: it starts the `sample_server` fixture as a real Serverpod server on three free ports, generates and builds its client into a temp directory, and runs `test/live/roundtrip.mjs` against it with Node. It stops the server and removes the temp directory when it finishes. To iterate on one check by hand, start the server yourself and point the script at it:

```bash
cd test/fixtures/sample_server/sample_server
for s in API INSIGHTS WEB; do
  export SERVERPOD_${s}_SERVER_PUBLIC_HOST=localhost SERVERPOD_${s}_SERVER_PUBLIC_SCHEME=http
done
export SERVERPOD_API_SERVER_PORT=18080 SERVERPOD_API_SERVER_PUBLIC_PORT=18080
export SERVERPOD_INSIGHTS_SERVER_PORT=18081 SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT=18081
export SERVERPOD_WEB_SERVER_PORT=18082 SERVERPOD_WEB_SERVER_PUBLIC_PORT=18082
dart bin/main.dart &
cd - && dart run serverpod_typescript_bridge generate \
  -d test/fixtures/sample_server/sample_server -o /tmp/sample_typescript_client
node test/live/roundtrip.mjs /tmp/sample_typescript_client/dist/index.js http://localhost:18080/
```

## Coding conventions

- Match the existing emitter style: indent-aware writer, no string-templating libraries.
- Comments explain *why*, never *what*.
- Don't write multi-paragraph docstrings — one short line max.
- Tests cover real scenarios, not implementation details. Prefer integration tests against the fixture over mock-heavy unit tests.

## Release procedure (maintainer)

1. Bump `version:` in `pubspec.yaml`.
2. Update `CHANGELOG.md`.
3. Verify the full suite is green: `dart analyze && dart test && (cd lib/runtime/typescript && npm test)`.
4. Run the external smoke-test: generate against a non-fixture Serverpod project (e.g. a fresh `serverpod create -t mini -n smoke` outside this repo) and verify the output is `tsc --noEmit` clean.
5. Commit + tag + push (commit AND tag): `git commit -am "Release v<version>" && git tag v<version> && git push --follow-tags`.
6. (Optional, post-v0.2) `dart pub publish` once stabilised. Until then consumers install via the git-ref `dev_dependencies` form documented in the top-level [README](README.md).
