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
# Dart side: 77+ cases incl. e2e against both fixtures
dart analyze
dart test

# TypeScript runtime side: 60+ vitest cases
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
   cd test/fixtures/sample_server
   dart pub get
   cd sample_server
   serverpod generate
   ```
3. Commit the fixture changes alongside the regenerated `lib/src/generated/` and `../sample_client/lib/src/protocol/` files.
4. Update the smoke test (`test/sample_server_fixture_test.dart`) so the new surface is asserted.

## Running the integration tests locally

The `test/generate_command_test.dart` and `test/module_emission_test.dart` end-to-end tests:

1. Spawn the CLI as a subprocess against the relevant fixture
2. Type-check the generated TypeScript with the runtime's local `tsc`

Both rely on the runtime's `node_modules` having been installed (see the local-setup step above). Without it, the tsc step is silently skipped.

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
5. Commit + tag: `git tag v<version> && git push --tags`.
6. (Optional, deferred to v0.2) `dart pub publish` once stabilised.
