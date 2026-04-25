# serverpod_typescript_bridge

Generate a fully-typed TypeScript client for a Serverpod project — drop-in parity with `serverpod generate` for the Dart client.

## Status

**v0.1 — usable.** The generator produces a tsc-clean, type-safe TypeScript client for any Serverpod project against the surface listed below. See the support matrix for known limitations.

## Quick start

```bash
# inside your Serverpod server package
dart pub add --dev serverpod_typescript_bridge

# generate the TS client (runs npm install + npm run build by default,
# so the output is import-ready)
dart run serverpod_typescript_bridge generate
```

Pass `--no-build` if you want source files only (e.g. you're on
pnpm/yarn/bun, or your CI runs the build step itself).

This writes a sibling package to your existing Dart client:

```
my_app/
├── my_app_server/                   # your Serverpod server package
├── my_app_client/                   # serverpod-generated Dart client
└── my_app_typescript_client/        # serverpod_typescript_bridge output
    ├── package.json
    ├── tsconfig.json
    └── src/
        ├── client.ts                # top-level Client
        ├── protocol.ts              # SerializationManager + dispatch
        ├── runtime/                 # vendored runtime (HTTP + WS)
        ├── protocol/                # one TS class per model
        └── endpoints/               # one TS class per endpoint
```

Then in your TS/React app:

```ts
import { Client } from 'my_app_typescript_client';

const client = new Client('https://api.my-app.com');
const greeting = await client.greeting.sayHello('world');
```

## Supported in v0.1

| Feature | Status | Notes |
|---|---|---|
| Endpoint methods (unary HTTP) | ✅ | required/optional positional + named params |
| Doc-comment passthrough | ✅ | Dart `///` and `{@template}`/`{@macro}` → TSDoc |
| `@unauthenticatedClientCall` | ✅ | flips `authenticated: false` per call |
| `@Deprecated` | ✅ | propagates to JSDoc `@deprecated` |
| Primitives | ✅ | int, double, String, bool, DateTime, Duration, BigInt, UuidValue, ByteData |
| Collections | ✅ | `List<T>`, `Set<T>`, `Map<String,V>`, `Map<K,V>` (non-string-keyed wire form) |
| Nullables | ✅ | `T?` → `T \| null`; `copyWith` honours explicit `null` |
| Sealed hierarchies | ✅ | discriminated-union TS type + `<Name>Base.fromJson` dispatch on `__className__` |
| Multi-level sealed | ✅ | every concrete subclass dispatches through every sealed ancestor |
| Enums | ✅ | both `byIndex` and `byName` |
| Exceptions | ✅ | `SerializableException` subclasses extend `Error` and round-trip via `Protocol` |
| Modules (`type: module`) | ✅ | emits `<Nickname>Caller extends ModuleEndpointCaller` + `modulePrefix` const |
| Module-prefix `__className__` | ✅ | Protocol switch normalises `<prefix>.<Class>` → bare `<Class>` |
| HTTP unary calls | ✅ | fetch-based; status mapping; auth header; one-shot 401 refresh |
| Output streams | ✅ | `Stream<T>` returns → `AsyncIterable<T>`; WebSocket transport |
| Bidirectional streams | ✅ | `Stream<T>` parameter → `streams: { name: AsyncIterable<T> }`; values forwarded as `MethodStreamMessage` frames |
| Typed exceptions | ✅ | `{className, data}` envelope decoded via `Protocol.deserializeByClassName` |

## Out of scope for v0.1

| Feature | Tracker |
|---|---|
| Records (Dart 3 records as endpoint params/return) | post-v0.1 |
| Watch mode (`-w`) | post-v0.1 |
| Module client npm publishing (currently vendored) | v0.2 |
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
      --[no-]build  After emitting source, run `npm install` + `npm run build`
                    in the output directory so it is import-ready (default: on).
```

## How it works

The generator is a Dart-side tool that reuses **`serverpod_cli`'s public analyzer** to load the IR for your Serverpod project, then walks that IR and emits TypeScript. Because the IR is the same one Serverpod uses internally, there's no parser drift — every feature Serverpod knows about flows through automatically.

The generated client depends on a small TypeScript runtime that ships *vendored* inside each generated package (under `src/runtime/`). v0.2 will publish the runtime to npm and switch generated packages to declare it as a dependency; existing v0.1 clients re-generate cleanly into v0.2.

For the full architecture, see [docs/architecture.md](docs/architecture.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE).
