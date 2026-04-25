# serverpod_typescript_bridge

Generate a fully-typed TypeScript client for a Serverpod project — drop-in parity with `serverpod generate` for the Dart client.

## Status

**v0.2 — module-aware.** The generator produces a tsc-clean, type-safe TypeScript client for any Serverpod project, including projects that depend on modules (`serverpod_auth_idp_server`, `serverpod_cloud_storage_s3`, etc.). Module clients are generated in-place as siblings of the app client and wired through `file:..` deps — no npm publishing required.

## Quick start

The package isn't published to pub.dev yet — install via git ref. Add this to your Serverpod server package's `pubspec.yaml`:

```yaml
dev_dependencies:
  serverpod_typescript_bridge:
    git:
      url: https://github.com/ChristopherLinnett/serverpod_typescript_bridge.git
      ref: v0.2.4   # or any later tag
```

Then:

```bash
cd path/to/your_app_server
dart pub get
dart run serverpod_typescript_bridge generate
```

`generate` runs `npm install` + `npm run build` for every module client (in dependency order) and then the app client, so the entire graph is import-ready when it exits. Pass `--no-build` to emit source only (e.g. on pnpm/yarn/bun, or in CI pipelines that drive the build step themselves).

This writes a sibling package to your existing Dart client. If your server depends on Serverpod modules, each is generated as an additional sibling and the app client picks them up via `file:..` deps:

```
my_app/
├── my_app_server/                                # your Serverpod server package
├── my_app_client/                                # serverpod-generated Dart client
├── serverpod_auth_idp_typescript_client/         # auto-generated (per module dep)
├── serverpod_cloud_storage_s3_typescript_client/ # auto-generated (per module dep)
└── my_app_typescript_client/                     # serverpod_typescript_bridge output
    ├── package.json                              # `file:..` deps wired automatically
    ├── tsconfig.json
    └── src/
        ├── client.ts                # top-level Client
        ├── protocol.ts              # SerializationManager + dispatch
        ├── runtime/                 # vendored runtime (HTTP + WS)
        ├── protocol/                # one TS class per model
        └── endpoints/               # one TS class per endpoint
```

Pass `--no-gen-modules` to skip recursive module generation (e.g. when module clients are managed separately).

In your TS/React app, install the generated package as a `file:` dep (one-time setup):

```bash
cd path/to/your_react_app
npm install ../my_app_typescript_client
```

Then import and use it:

```ts
import { Client, GetJoinedDivesRequest } from 'my_app_typescript_client';

const client = new Client('https://api.my-app.com');

// Nullable model fields can be omitted (default to null at construction):
const dives = await client.dives.getJoinedDives(
  new GetJoinedDivesRequest({ isCompleted: false, count: 10, offset: 0 }),
);

// Cross-module types resolve through their generated package:
import { AuthSuccess } from 'serverpod_auth_idp_typescript_client';
```

## Supported in v0.2

| Feature | Status | Notes |
|---|---|---|
| Endpoint methods (unary HTTP) | ✅ | required/optional positional + named params |
| Doc-comment passthrough | ✅ | Dart `///` and `{@template}`/`{@macro}` → TSDoc |
| `@unauthenticatedClientCall` | ✅ | flips `authenticated: false` per call |
| `@Deprecated` | ✅ | propagates to JSDoc `@deprecated` |
| Primitives | ✅ | int, double, String, bool, DateTime, Duration, BigInt, UuidValue, ByteData |
| Collections | ✅ | `List<T>`, `Set<T>`, `Map<String,V>`, `Map<K,V>` (non-string-keyed wire form) |
| Nullables | ✅ | `T?` → `T \| null`; nullable fields are OMITTABLE on model/exception constructor `init` bags (default to `null`); `copyWith` honours explicit `null` vs "leave alone" |
| Sealed hierarchies | ✅ | discriminated-union TS type + `<Name>Base.fromJson` dispatch on `__className__` |
| Multi-level sealed | ✅ | every concrete subclass dispatches through every sealed ancestor |
| Enums | ✅ | both `byIndex` and `byName` |
| Exceptions | ✅ | `SerializableException` subclasses extend `Error` and round-trip via `Protocol` |
| Modules (`type: module`) | ✅ | emits `<Nickname>Caller extends ModuleEndpointCaller` + `modulePrefix` const |
| Module dependencies (consumer side) | ✅ | recursively generates a TS client per module, wires `file:..` deps in `package.json`, emits cross-package `import { Name } from '<module-pkg>';` lines |
| Cross-module protocol dispatch | ✅ | Protocol switch routes `<prefix>.<Class>` envelopes through the matching module's `<Name>(.fromJson\|Codec.fromJson\|Base.fromJson)` |
| HTTP unary calls | ✅ | fetch-based; status mapping; auth header; one-shot 401 refresh |
| Output streams | ✅ | `Stream<T>` returns → `AsyncIterable<T>`; WebSocket transport |
| Bidirectional streams | ✅ | `Stream<T>` parameter → `streams: { name: AsyncIterable<T> }`; values forwarded as `MethodStreamMessage` frames |
| Typed exceptions | ✅ | `{className, data}` envelope decoded via `Protocol.deserializeByClassName` |

## Out of scope (post-v0.2)

| Feature | Tracker |
|---|---|
| Records (Dart 3 records as endpoint params/return) | post-v0.2 |
| Watch mode (`-w`) | post-v0.2 |
| Typed module-Caller surface (currently `Modules.<nickname>: unknown` stub; cross-package types resolve directly through their imports) | post-v0.2 |
| `dart run serverpod_typescript_bridge inspect` polish | works, but undocumented; primarily a debug surface |

## CLI reference

```
$ dart run serverpod_typescript_bridge --help

Generate a TypeScript client for a Serverpod project.

Usage: serverpod_typescript_bridge <command> [arguments]

Commands:
  generate   Generate the TypeScript client package next to the Serverpod project.
  inspect    Print the parsed protocol IR as JSON (for debugging).

Options:
  -d, --directory   Path to the Serverpod server package (auto-detected if omitted).
  -o, --output      Path to the TypeScript client package to (re-)generate.
                    Defaults to <server>/../<name>_typescript_client/.
                    Override via `typescript_client_package_path` in
                    `config/generator.yaml`.
      --[no-]build         After emitting source, run `npm install` + `npm run build`
                           in every generated client (modules first, then the app)
                           so the entire graph is import-ready (default: on). Build
                           failures for a module are non-fatal and printed to stderr.
      --[no-]gen-modules   Recursively generate TS clients for every Serverpod
                           module the project depends on, as siblings of the app
                           client (default: on). The app client picks them up via
                           `file:..` deps wired automatically into `package.json`.
```

### Customising module client paths

By default each module client is generated at `<server>/../<module-stripped-of-_server>_typescript_client/` and named `<module-stripped>_typescript_client` in npm. Override per module via `config/generator.yaml`:

```yaml
typescript_client_modules:
  serverpod_auth_idp_server:
    output: ../my_custom_path
    npm_name: '@my-org/auth-idp-ts'
```

## How it works

The generator is a Dart-side tool that reuses **`serverpod_cli`'s public analyzer** to load the IR for your Serverpod project, then walks that IR and emits TypeScript. Because the IR is the same one Serverpod uses internally, there's no parser drift — every feature Serverpod knows about flows through automatically.

The generated client depends on a small TypeScript runtime that ships *vendored* inside each generated package (under `src/runtime/`). Module dependencies are detected by scanning `.dart_tool/package_config.json` for packages whose `config/generator.yaml` declares `type: module`. Each module's IR is loaded the same way the app's is, used to build a cross-package class index, and emitted as its own sibling TypeScript client; the app client then declares each module client as a `file:..` dependency so a single `npm install` resolves the whole graph in place.

For the full architecture, see [docs/architecture.md](docs/architecture.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE).
