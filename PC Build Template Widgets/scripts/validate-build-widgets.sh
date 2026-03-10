#!/usr/bin/env bash
set -euo pipefail

BUILD_CODE="${1:-[CODE]}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${WIDGET_ROOT}/builds/${BUILD_CODE}"

if [[ ! -d "${TARGET_DIR}" ]]; then
  echo "Missing build directory: ${TARGET_DIR}" >&2
  exit 1
fi

MOTHERBOARD_FILE="$(find "${TARGET_DIR}" -maxdepth 1 -type f -name "*-04-motherboard-specs-table-*.html" | head -n 1)"
if [[ -z "${MOTHERBOARD_FILE}" ]]; then
  echo "Missing generated motherboard file in ${TARGET_DIR}" >&2
  exit 1
fi

YAML_FILE="${TARGET_DIR}/${BUILD_CODE}.yaml"
PERF_FILE="$(find "${TARGET_DIR}" -maxdepth 1 -type f -name "*-10-performance-graph-widget-*.html" | head -n 1)"

check_label_has_br() {
  local label="$1"
  local file="$2"

  awk -v label="${label}" '
    index($0, "<p class=\"gw-mobo-spec-label\">" label "</p>") > 0 { found=1; next }
    found && index($0, "<p class=\"gw-mobo-spec-value\">") > 0 {
      if (index($0, "<br") > 0) ok=1
      exit
    }
    END {
      if (!found) exit 2
      if (!ok) exit 1
    }
  ' "${file}"
  local code=$?
  if [[ ${code} -ne 0 ]]; then
    if [[ ${code} -eq 2 ]]; then
      echo "Validation failed: label not found: ${label}" >&2
    else
      echo "Validation failed: ${label} is missing <br> formatting in ${file}" >&2
    fi
    exit 1
  fi
}

check_label_has_br "Memory Support" "${MOTHERBOARD_FILE}"
check_label_has_br "Expansion Card Compatibility" "${MOTHERBOARD_FILE}"
check_label_has_br "M.2 Compatibility (3 Slots)" "${MOTHERBOARD_FILE}"
check_label_has_br "Networking" "${MOTHERBOARD_FILE}"
check_label_has_br "Rear I/O" "${MOTHERBOARD_FILE}"
check_label_has_br "Front I/O Headers" "${MOTHERBOARD_FILE}"

if [[ -f "${PERF_FILE}" && -f "${YAML_FILE}" ]]; then
  if grep -Eq '^[[:space:]]*<div class="gw-driver-bar [^"]*".*Driver Version: \?\?.*</div>[[:space:]]*$' "${PERF_FILE}" || \
     grep -Eqi '^[[:space:]]*<div class="gw-driver-bar [^"]*".*capture build.*</div>[[:space:]]*$' "${PERF_FILE}"; then
    echo "Validation failed: performance widget still contains placeholder driver text." >&2
    exit 1
  fi

  if ! grep -q "buildMetricsHTML(gameData)" "${PERF_FILE}"; then
    echo "Validation failed: performance widget is not using dynamic metric rendering." >&2
    exit 1
  fi

  python3 - "${YAML_FILE}" "${PERF_FILE}" <<'PY'
import re
import sys
from pathlib import Path

yaml_path = Path(sys.argv[1])
perf_path = Path(sys.argv[2])

yaml_text = yaml_path.read_text(encoding="utf-8")
perf_text = perf_path.read_text(encoding="utf-8")

results = []
in_raw = False
for line in yaml_text.splitlines():
    if re.match(r'^\s*raw_results:\s*$', line):
        in_raw = True
        continue
    if in_raw and re.match(r'^\s*[a-zA-Z0-9_]+\s*:\s*', line):
        break
    m = re.match(r'^\s*-\s*"(.+?)\s*-\s*[0-9]+(?:\.[0-9]+)?\s*FPS\s*\(@\s*([^)]+)\)\s*"\s*$', line)
    if in_raw and m:
        game = m.group(1).strip()
        key = re.sub(r'[^a-z0-9]+', '', game.lower()) or "game"
        results.append(key)

m = re.search(r'var GAME_ORDER = \[(.*?)\];', perf_text, flags=re.S)
if not m:
    print("Validation failed: performance widget missing GAME_ORDER.", file=sys.stderr)
    sys.exit(1)

html_keys = re.findall(r'"([^"]+)"', m.group(1))
if html_keys != results:
    print(
        "Validation failed: performance widget GAME_ORDER mismatch. "
        f"Expected {results}, got {html_keys}.",
        file=sys.stderr,
    )
    sys.exit(1)
PY
fi

echo "Validation passed: formatting checks succeeded for ${MOTHERBOARD_FILE}"
