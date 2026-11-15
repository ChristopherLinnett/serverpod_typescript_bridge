#!/usr/bin/env bash
# Regenerates the committed Serverpod output of the test fixtures
# (lib/src/generated/ and the Dart client's lib/src/protocol/).
#
# Runs the serverpod_cli this package resolves, not a globally activated
# `serverpod`: the fixtures' generated Dart is the reference the TypeScript
# output is compared against, so it has to come from the version in
# pubspec.yaml.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
dart pub get >/dev/null

package_config="$root/.dart_tool/package_config.json"
cli_root="$(
  grep -A1 '"name": "serverpod_cli"' "$package_config" \
    | sed -n 's/.*"rootUri": "file:\/\/\(.*\)".*/\1/p'
)"
if [[ -z "$cli_root" || ! -f "$cli_root/bin/serverpod_cli.dart" ]]; then
  echo "Could not locate serverpod_cli in $package_config" >&2
  exit 1
fi
echo "Using serverpod_cli at $cli_root"

for fixture in sample_server/sample_server sample_module/testmod_server; do
  workspace="$root/test/fixtures/${fixture%%/*}"
  (cd "$workspace" && dart pub get >/dev/null)
  echo "Generating $fixture"
  (
    cd "$root/test/fixtures/$fixture"
    dart run --packages="$package_config" "$cli_root/bin/serverpod_cli.dart" generate
  )
done
