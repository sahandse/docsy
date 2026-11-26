#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
dest="${1:-$root/.dart_tool/rustina-office}"
revision=c310c1d788603853cf22affc1b23fb10f1033239
mkdir -p "$dest"
if [[ ! -d "$dest/.git" ]]; then
  git init "$dest"
  git -C "$dest" remote add origin https://github.com/RustinaCo/Office.git
fi
git -C "$dest" fetch --depth=1 https://github.com/RustinaCo/Office.git "$revision"
git -C "$dest" checkout --detach FETCH_HEAD
test "$(git -C "$dest" rev-parse HEAD)" = "$revision"
for engine in Write/wordcraft Tables/gridcraft Slides/deckcraft; do
  test -f "$dest/$engine/crates/engine/Cargo.toml"
  cargo metadata --manifest-path "$dest/$engine/crates/engine/Cargo.toml" --no-deps --format-version 1 >/dev/null
done
test -f "$dest/LICENSE"
test -f "$dest/CREDITS.md"
printf '%s\n' "Rustina source and engine manifests verified; compilation and Flutter integration are not yet verified."
