#!/usr/bin/env bash
set -euo pipefail

BUILD_CODE="${1:-[CODE]}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIDGET_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ORDER_FILE="${WIDGET_ROOT}/config/widget-order.txt"
SOURCE_DIR="${WIDGET_ROOT}/templates"
TARGET_DIR="${WIDGET_ROOT}/builds/${BUILD_CODE}"
VALIDATE_SCRIPT="${WIDGET_ROOT}/scripts/validate-build-widgets.sh"
RENDER_SCRIPT="${WIDGET_ROOT}/scripts/render-build-widgets.rb"

if [[ ! -f "${ORDER_FILE}" ]]; then
  echo "Missing order file: ${ORDER_FILE}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"
count=0

while IFS='|' read -r prefix source_file; do
  [[ -z "${prefix}" ]] && continue
  [[ -z "${source_file}" ]] && continue

  # Tolerate CRLF in widget-order.txt when running via Git Bash on Windows.
  prefix="${prefix%$'\r'}"
  source_file="${source_file%$'\r'}"

  base_name="${source_file%.html}"
  source_path="${SOURCE_DIR}/${source_file}"
  if [[ ! -f "${source_path}" ]]; then
    echo "Missing template file: ${source_path}" >&2
    exit 1
  fi

  target_file="${prefix}-${base_name}-${BUILD_CODE}.html"
  cp "${source_path}" "${TARGET_DIR}/${target_file}"
  count=$((count + 1))
done < "${ORDER_FILE}"

echo "Generated ${count} widget files in: ${TARGET_DIR}"

if [[ -f "${RENDER_SCRIPT}" ]]; then
  ruby "${RENDER_SCRIPT}" "${BUILD_CODE}"
fi

if [[ -x "${VALIDATE_SCRIPT}" ]]; then
  "${VALIDATE_SCRIPT}" "${BUILD_CODE}"
else
  echo "Warning: validation script not executable: ${VALIDATE_SCRIPT}" >&2
  exit 1
fi
