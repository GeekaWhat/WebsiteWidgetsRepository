#!/usr/bin/env bash
set -euo pipefail

BUILD_CODE="${1:-[****]}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${REPO_ROOT}/PC Build Template Widgets"
ORDER_FILE="${TEMPLATE_DIR}/widget-order.txt"
TARGET_DIR="${TEMPLATE_DIR}/${BUILD_CODE}"

if [[ ! -f "${ORDER_FILE}" ]]; then
  echo "Missing order file: ${ORDER_FILE}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"
count=0

while IFS='|' read -r prefix source_file; do
  [[ -z "${prefix}" ]] && continue
  [[ -z "${source_file}" ]] && continue

  source_path="${TEMPLATE_DIR}/${source_file}"
  if [[ ! -f "${source_path}" ]]; then
    echo "Missing template file: ${source_path}" >&2
    exit 1
  fi

  base_name="${source_file%.html}"
  target_file="${prefix}-${base_name}-${BUILD_CODE}.html"
  cp "${source_path}" "${TARGET_DIR}/${target_file}"
  count=$((count + 1))
done < "${ORDER_FILE}"

echo "Generated ${count} widget files in: ${TARGET_DIR}"
