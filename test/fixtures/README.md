# Test fixtures

These are the parity oracles for `serverpod_typescript_bridge`. Every later issue's tests run against the artifacts checked in here.

## sample_server

A real Serverpod 4.1.2 mini-template project covering every feature the
generator supports. It is also a runnable server: `test/live_roundtrip_test.dart`
boots it and calls every endpoint through the generated TypeScript client. Layout:

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
| `endpoints/auth_endpoint.dart` | `requireLogin: true` class, over HTTP and over a stream. `lib/server.dart` installs an authentication handler that accepts one fixed token. |
| `endpoints/public_endpoint.dart` | `@unauthenticatedClientCall` per-method override. |
| `endpoints/legacy_endpoint.dart` | `@Deprecated` annotation passthrough. |
| `endpoints/streaming_endpoint.dart` | Output streams of primitives, models, a sealed type, enums and lists; an endless stream (client cancels); a stream that fails with a typed exception; input streams with a `Future` result, with no result, and echoed back. |
| `endpoints/enums_endpoint.dart` | Enums as arguments and returns, by index and by name, nullable, in lists and maps. |
| `endpoints/params_endpoint.dart` | Named and optional positional parameters; arguments that need encoding (`DateTime`, `Duration`, `BigInt`, `Set`, non-string-keyed `Map`, list of models); field defaults; vectors and geography; exception inheritance; a subclass returned as its parent; `Uri`. |
| `endpoints/chat_endpoint.dart` | Bidirectional streaming (input `Stream<T>` + output `Stream<T>`). |
| `models/user_profile.spy.yaml` | Simple class with all primitives + nullables; varied doc-comment styles. |
| `models/admin_profile.spy.yaml` | Non-sealed `extends:` inheritance. |
| `models/animal.spy.yaml` + `dog.spy.yaml` + `cat.spy.yaml` | Sealed hierarchy with two concrete subclasses (polymorphic dispatch oracle). |
| `models/priority.spy.yaml` | Enum, default `byIndex` serialization. |
| `models/colour.spy.yaml` | Enum, opts into `byName` serialization. |
| `models/not_found_exception.spy.yaml` | `SerializableException` subclass. |
| `models/app_exception.spy.yaml` + `quota_exception.spy.yaml` | An exception that extends another. |
| `models/settings.spy.yaml` | Fields with defaults (`int`, `String`, `bool`, enum, `double`). |
| `models/embedding.spy.yaml` | `Vector`, `HalfVector`, `SparseVector`, `Bit`, `GeographyPoint`. |

### Regenerating after edits

The `generated/` and `sample_client/lib/src/protocol/` directories are committed
deliberately — they're the reference output that the TypeScript generator's
output is compared against.

If you add or change an endpoint or model, run `tool/regenerate_fixtures.sh`
from the repository root (it uses the `serverpod_cli` the bridge is built
against, not a globally activated one) and commit the resulting changes to
`sample_server/lib/src/generated/` and `sample_client/lib/src/protocol/`
alongside your YAML/Dart edits.

### Why mini and not the standard template

The mini template skips Postgres/Docker setup, so the live test can start
the server with nothing but `dart bin/main.dart`. The standard template's
database scaffolding would add ~30 files of irrelevant noise.

### What's intentionally NOT here

- **Records** (Dart 3 records as endpoint params/returns) — not supported.
- **A method that reads two input streams one after the other.** Serverpod
  4.1.2 never closes such a call, with its own Dart client as much as with
  this one, so there is nothing to compare against.
- **Database tables/relations** — server-only; relations don't propagate to
  the client.
- **A separate module fixture** — landed in the issue covering module
  support.
