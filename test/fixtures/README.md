# Test fixtures

These are the parity oracles for `serverpod_typescript_bridge`. Every later issue's tests run against the artifacts checked in here.

## sample_server

A real Serverpod 3.4.7 mini-template project covering every feature the v0.1
generator must support. Layout:

```
sample_server/
├── pubspec.yaml          # workspace root (Dart pub workspaces)
├── sample_server/        # the actual server package
│   ├── pubspec.yaml
│   ├── lib/src/
│   │   ├── endpoints/    # the surface to be generated
│   │   ├── models/       # YAML model definitions
│   │   └── generated/    # serverpod-generated server code (committed)
│   └── ...
└── sample_client/        # serverpod-generated dart client (committed)
```

### What each piece exercises

| File | Feature |
|---|---|
| `endpoints/primitives_endpoint.dart` | All primitives: int, double, String, bool, DateTime, Duration, BigInt, UuidValue, ByteData. Includes `{@template}` / `{@macro}` doc-comment passthrough. |
| `endpoints/models_endpoint.dart` | Custom-model in/out, non-sealed inheritance return, exposes a sealed round-trip surface for the issue #6 emitter, typed exception throw. |
| `endpoints/collections_endpoint.dart` | `List<T>`, `Set<T>`, `Map<String,T>`, `Map<int,T>` (non-string-key wire form). |
| `endpoints/nullables_endpoint.dart` | All-nullable params and returns. |
| `endpoints/auth_endpoint.dart` | `requireLogin: true` class. |
| `endpoints/public_endpoint.dart` | `@unauthenticatedClientCall` per-method override. |
| `endpoints/legacy_endpoint.dart` | `@Deprecated` annotation passthrough. |
| `endpoints/streaming_endpoint.dart` | Output-only `Stream<T>` return. |
| `endpoints/chat_endpoint.dart` | Bidirectional streaming (input `Stream<T>` + output `Stream<T>`). |
| `models/user_profile.spy.yaml` | Simple class with all primitives + nullables; varied doc-comment styles. |
| `models/admin_profile.spy.yaml` | Non-sealed `extends:` inheritance. |
| `models/animal.spy.yaml` + `dog.spy.yaml` + `cat.spy.yaml` | Sealed hierarchy with two concrete subclasses (polymorphic dispatch oracle). |
| `models/priority.spy.yaml` | Enum, default `byIndex` serialization. |
| `models/colour.spy.yaml` | Enum, opts into `byName` serialization. |
| `models/not_found_exception.spy.yaml` | `SerializableException` subclass. |

### Regenerating after edits

The `generated/` and `sample_client/lib/src/protocol/` directories are committed
deliberately — they're the reference output that the TypeScript generator's
output is compared against.

If you add or change an endpoint or model:

```bash
cd test/fixtures/sample_server
dart pub get
cd sample_server
serverpod generate
```

Commit the resulting changes to `sample_server/lib/src/generated/` and
`sample_client/lib/src/protocol/` alongside your YAML/Dart edits.

### Why mini and not the standard template

The mini template skips Postgres/Docker setup. We never run the server in
unit tests — the fixture exists purely to feed Serverpod's analyzer with a
diverse surface. The standard template's database scaffolding would add
~30 files of irrelevant noise.

### What's intentionally NOT here

- **Records** (Dart 3 records as endpoint params/returns) — deferred to
  post-v0.1.
- **Database tables/relations** — server-only; relations don't propagate to
  the client.
- **A separate module fixture** — landed in the issue covering module
  support.
