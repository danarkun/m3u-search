#!/usr/bin/env bash
# m3u-search.sh: download the M3U playlist and print every line that contains
# the search text (case-insensitive, literal match, can be anywhere in the line).
#
# Usage:
#   ./m3u-search.sh 'search text'
#   ./m3u-search.sh sky sports          # unquoted words are joined with spaces

BASE_URL="https://amazing-onyx.net/get.php"
USERNAME="Ernest"
PASSWORD="10312025"   # <-- put your real password here

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 'search text'" >&2
  exit 2
fi
pattern="$*"

# -G + --data-urlencode builds the query string safely, so special characters
# in the username or password are encoded correctly.
# tr strips Windows line endings. awk prints each line containing the pattern
# (plain text, no regex, case-insensitive) plus the line directly below it.
# The pattern is passed via ENVIRON so backslashes etc. are taken literally.
curl -fsSL -G "$BASE_URL" \
  --data-urlencode "username=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "type=m3u" \
| tr -d '\r' \
| PAT="$pattern" awk '
    BEGIN { p = tolower(ENVIRON["PAT"]) }
    index(tolower($0), p) { print; found = 1; after = 1; next }
    after                 { print; after = 0 }
    END { exit !found }
  '

status=("${PIPESTATUS[@]}")

if (( status[0] != 0 )); then
  echo "Download failed (curl exit code ${status[0]})." >&2
  exit 1
fi

if (( status[2] == 1 )); then
  echo "No matches for: $pattern" >&2
  exit 1
fi

exit "${status[2]}"
