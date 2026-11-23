#!/usr/bin/env bash
# Fails if a spec file changed relative to BASE without its info.version being
# bumped to a valid, newer YYYY.MM.DD date.
#
# Usage: .github/scripts/check-version-bump.sh <base-ref-or-sha>
# Example (locally): .github/scripts/check-version-bump.sh origin/main
set -euo pipefail

BASE="$(git merge-base "${1:?usage: $0 <base-ref-or-sha>}" HEAD)"
SPECS=(edgegap-v1-openapi.yaml edgegap-v2-openapi.yaml)

# Print the first "  version:" value under the top-level "info:" block.
info_version() {
  awk '
    /^info:/ { in_info = 1; next }
    in_info && /^[^ ]/ { exit }
    in_info && /^  version:/ { sub(/^  version:[ ]*/, ""); gsub(/["\047]/, ""); print; exit }
  '
}

# "Today" is allowed to be off by one day either way (UTC), so contributors in
# any timezone aren't rejected.
max_date="$(date -u -d tomorrow +%Y.%m.%d)"
min_today="$(date -u -d yesterday +%Y.%m.%d)"
failed=0

for spec in "${SPECS[@]}"; do
  if git diff --quiet "$BASE" HEAD -- "$spec"; then
    echo "✔ $spec: unchanged, no bump needed"
    continue
  fi

  head_version="$(info_version < "$spec")"
  base_version="$(git show "$BASE:$spec" 2>/dev/null | info_version || true)"

  if [[ ! "$head_version" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$ ]] \
     || ! date -u -d "${head_version//./-}" >/dev/null 2>&1; then
    echo "::error file=$spec::info.version '$head_version' must be a valid date in YYYY.MM.DD format"
    failed=1
  elif [[ "$head_version" > "$max_date" ]]; then
    echo "::error file=$spec::info.version '$head_version' is in the future"
    failed=1
  elif [[ -n "$base_version" && "$head_version" < "$base_version" ]]; then
    echo "::error file=$spec::info.version '$head_version' is older than the base version '$base_version'. Set it to today's date (YYYY.MM.DD)."
    failed=1
  elif [[ -n "$base_version" && "$head_version" == "$base_version" && "$head_version" < "$min_today" ]]; then
    # Equal to base is only fine when base is already today's date
    # (e.g. a second spec change merged on the same day).
    echo "::error file=$spec::$spec changed but info.version was not bumped (still '$head_version'). Set it to today's date (YYYY.MM.DD)."
    failed=1
  elif [[ "$head_version" == "$base_version" ]]; then
    echo "✔ $spec: version already today's date ($head_version)"
  else
    echo "✔ $spec: version bumped ${base_version:-<new file>} -> $head_version"
  fi
done

exit "$failed"
