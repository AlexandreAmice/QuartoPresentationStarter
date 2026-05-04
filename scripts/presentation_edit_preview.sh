#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WATCH_SCRIPT="${REPO_ROOT}/scripts/quarto_preview_watch_includes.sh"
# shellcheck source=compat.sh
source "${SCRIPT_DIR}/compat.sh"

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") [deck-dir] [section] [quarto preview args...]

Examples:
  $(basename "$0") presentations/quickstart
  $(basename "$0") presentations/showcase methods --no-browser --port 4302
USAGE
}

if [[ $# -gt 0 && ( "${1}" == "-h" || "${1}" == "--help" ) ]]; then
  usage
  exit 0
fi

DECK_DIR="presentations/quickstart"
if [[ $# -gt 0 && "${1}" != -* ]]; then
  DECK_DIR="${1%/}"
  shift
fi

EDIT_QMD_REL="${DECK_DIR}/presentation.edit.qmd"
EDIT_QMD="${REPO_ROOT}/${EDIT_QMD_REL}"
SECTIONS_DIR="${REPO_ROOT}/${DECK_DIR}/sections"

if [[ ! -f "${EDIT_QMD}" ]]; then
  echo "ERROR: edit deck not found: ${EDIT_QMD_REL}" >&2
  exit 1
fi
if [[ ! -d "${SECTIONS_DIR}" ]]; then
  echo "ERROR: sections directory not found: ${DECK_DIR}/sections" >&2
  exit 1
fi
if [[ ! -x "${WATCH_SCRIPT}" ]]; then
  echo "ERROR: watch script is missing or not executable: scripts/quarto_preview_watch_includes.sh" >&2
  exit 1
fi

SECTIONS=()
while IFS= read -r line; do
  SECTIONS+=( "${line}" )
done < <(
  {
    shopt -s nullglob
    for qmd in "${SECTIONS_DIR}"/*.qmd; do
      [[ -f "${qmd}" ]] || continue
      name="${qmd##*/}"
      printf '%s\n' "${name%.qmd}"
    done
  } | LC_ALL=C sort
)

if [[ ${#SECTIONS[@]} -eq 0 ]]; then
  echo "ERROR: no section qmd files found in ${DECK_DIR}/sections" >&2
  exit 1
fi

CURRENT_SECTION="$({
  sed -nE 's#.*\{\{< include sections/([^[:space:]]+)\.qmd >\}\}.*#\1#p' "${EDIT_QMD}" \
    | head -n 1
})"

SECTION=""
if [[ $# -gt 0 && "${1}" != -* ]]; then
  SECTION="${1}"
  shift
elif [[ -n "${CURRENT_SECTION}" ]]; then
  SECTION="${CURRENT_SECTION}"
else
  SECTION="${SECTIONS[0]}"
fi

is_valid_section=false
for known_section in "${SECTIONS[@]}"; do
  if [[ "${known_section}" == "${SECTION}" ]]; then
    is_valid_section=true
    break
  fi
done

if [[ "${is_valid_section}" != "true" ]]; then
  echo "ERROR: invalid section '${SECTION}' for deck '${DECK_DIR}'." >&2
  echo "Valid sections: ${SECTIONS[*]}" >&2
  echo >&2
  usage >&2
  exit 1
fi

sed_inplace -E \
  "s#\{\{< include sections/[^[:space:]]+\.qmd >\}\}#{{< include sections/${SECTION}.qmd >}}#g" \
  "${EDIT_QMD}"

if ! rg -q "\{\{< include sections/${SECTION}\.qmd >\}\}" "${EDIT_QMD}"; then
  echo "ERROR: failed to set section include in ${EDIT_QMD_REL}" >&2
  exit 1
fi

exec "${WATCH_SCRIPT}" "${EDIT_QMD_REL}" "$@"
