#!/usr/bin/env bash
# Local quality gate: mirrors the CI checks (docs/11-roadmap.md Definition of
# Done). Fails on the first problem.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/flutter_app"

echo "==> Ensuring generated sources are present"
"$root/scripts/gen.sh"

echo "==> Checking formatting"
dart format --set-exit-if-changed .

echo "==> Static analysis"
flutter analyze

echo "==> Tests"
flutter test

echo "All checks passed."
