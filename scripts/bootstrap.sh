#!/usr/bin/env bash
# One-time setup after cloning: fetch dependencies and generate sources.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/flutter_app"

flutter pub get
"$root/scripts/gen.sh"

echo "Bootstrap complete. Run scripts/verify.sh to check the project."
