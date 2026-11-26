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
git -C "$dest" reset --hard "$revision"
python3 - "$dest" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1]) / "Write/wordcraft/crates/engine/src"
cmd = root / "cmd/file.rs"
io = root / "io.rs"
old = """    use std::io::Read;
    if crate::file_access::check_read(&path.to_string_lossy()).is_err() {
        return false;
    }
    let Ok(f) = std::fs::File::open(path) else { return false };
    let mut head = Vec::new();
    // The root element and its namespaces come first.
    if f.take(64 * 1024).read_to_end(&mut head).is_err() {
        return false;
    }"""
new = """    let Ok(head) = crate::io::read_file_prefix(&path.to_string_lossy(), 64 * 1024) else {
        return false;
    };"""
s = cmd.read_text()
assert s.count(old) == 1, "Unexpected upstream source"
cmd.write_text(s.replace(old, new))
with io.open("a") as f:
    f.write("""
#[cfg(not(target_arch = "wasm32"))]
pub(crate) fn read_file_prefix(path: &str, max: u64) -> Result<Vec<u8>, String> {
    use std::io::Read;
    crate::file_access::check_read(path)?;
    let mut bytes = Vec::new();
    std::fs::File::open(path).map_err(|e| e.to_string())?
        .take(max).read_to_end(&mut bytes).map_err(|e| e.to_string())?;
    Ok(bytes)
}
""")
PY
for engine in Write/wordcraft Tables/gridcraft Slides/deckcraft; do
  test -f "$dest/$engine/crates/engine/Cargo.toml"
  cargo metadata --manifest-path "$dest/$engine/crates/engine/Cargo.toml" --no-deps --format-version 1 >/dev/null
done
test -f "$dest/LICENSE"
test -f "$dest/CREDITS.md"
printf '%s\n' "Rustina source and engine manifests verified; compilation and Flutter integration are not yet verified."
