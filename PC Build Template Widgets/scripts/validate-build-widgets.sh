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

echo "Validation passed: formatting checks succeeded for ${MOTHERBOARD_FILE}"
