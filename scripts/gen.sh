#!/usr/bin/env bash
# Regenerate all generated sources (localizations + Drift/code-gen outputs).
# Generated files are not committed; run this after cloning or changing schemas.
set -euo pipefail

cd "$(dirname "$0")/../flutter_app"

flutter gen-l10n

# Run build_runner only if any code-generation annotations exist yet.
if grep -rqsE "part '.*\.g\.dart'|@DriftDatabase|@DriftAccessor" lib; then
  dart run build_runner build
fi
