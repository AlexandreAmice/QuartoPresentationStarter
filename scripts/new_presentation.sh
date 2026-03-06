#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") <deck-name> [--title "Deck Title"] [--no-render-entry]

Examples:
  $(basename "$0") my_talk
  $(basename "$0") committee_update --title "Committee Update"
USAGE
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

DECK_NAME=""
TITLE=""
ADD_RENDER_ENTRY=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --title)
      shift
      if [[ $# -eq 0 ]]; then
        echo "ERROR: --title requires a value." >&2
        exit 1
      fi
      TITLE="$1"
      shift
      ;;
    --no-render-entry)
      ADD_RENDER_ENTRY=false
      shift
      ;;
    -* )
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "${DECK_NAME}" ]]; then
        echo "ERROR: only one deck name is allowed." >&2
        usage >&2
        exit 1
      fi
      DECK_NAME="$1"
      shift
      ;;
  esac
done

if [[ -z "${DECK_NAME}" ]]; then
  echo "ERROR: deck name is required." >&2
  usage >&2
  exit 1
fi

if [[ ! "${DECK_NAME}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "ERROR: deck name must match [A-Za-z0-9_-]+." >&2
  exit 1
fi

TEMPLATE_DIR="${REPO_ROOT}/presentations/quickstart"
TARGET_DIR="${REPO_ROOT}/presentations/${DECK_NAME}"

if [[ ! -d "${TEMPLATE_DIR}" ]]; then
  echo "ERROR: template deck not found at ${TEMPLATE_DIR}" >&2
  exit 1
fi

if [[ -e "${TARGET_DIR}" ]]; then
  echo "ERROR: target deck already exists: presentations/${DECK_NAME}" >&2
  exit 1
fi

if [[ -z "${TITLE}" ]]; then
  TITLE="$(echo "${DECK_NAME}" | tr '_-' ' ' | sed -E 's/(^|[[:space:]])([[:alpha:]])/\1\U\2/g')"
fi

cp -R "${TEMPLATE_DIR}" "${TARGET_DIR}"

OLD_CSS="${TARGET_DIR}/quickstart.css"
NEW_CSS="${TARGET_DIR}/${DECK_NAME}.css"
if [[ -f "${OLD_CSS}" ]]; then
  mv "${OLD_CSS}" "${NEW_CSS}"
fi

for qmd in "${TARGET_DIR}/presentation.qmd" "${TARGET_DIR}/presentation.edit.qmd"; do
  SAFE_TITLE="$(printf '%s' "${TITLE}" | sed -e 's/[\\/&]/\\&/g')"
  SAFE_DECK_NAME="$(printf '%s' "${DECK_NAME}" | sed -e 's/[\\/&]/\\&/g')"
  sed -i "s/Quickstart Deck/${SAFE_TITLE}/g" "${qmd}"
  sed -i "s/quickstart\.css/${SAFE_DECK_NAME}.css/g" "${qmd}"
done

if [[ -f "${TARGET_DIR}/sections/title.qmd" ]]; then
  SAFE_TITLE="$(printf '%s' "${TITLE}" | sed -e 's/[\\/&]/\\&/g')"
  sed -i "s/Quickstart Template/${SAFE_TITLE}/g" "${TARGET_DIR}/sections/title.qmd"
fi

README_FILE="${TARGET_DIR}/README.md"
if [[ -f "${README_FILE}" ]]; then
  {
    printf '# %s\n\n' "${TITLE}"
    printf 'Deck scaffolded from `presentations/quickstart`.\n\n'
    printf -- '- Canonical deck: `presentation.qmd`\n'
    printf -- '- Edit mode deck: `presentation.edit.qmd`\n'
    printf -- '- Sections: `sections/*.qmd`\n'
    printf -- '- Deck-local css: `%s.css`\n' "${DECK_NAME}"
  } > "${README_FILE}"
fi

if [[ "${ADD_RENDER_ENTRY}" == true ]]; then
  QUARTO_FILE="${REPO_ROOT}/_quarto.yml"
  ENTRY="    - presentations/${DECK_NAME}/presentation.qmd"

  if [[ -f "${QUARTO_FILE}" ]] && ! rg -q "^\s*-\s+presentations/${DECK_NAME}/presentation\.qmd\s*$" "${QUARTO_FILE}"; then
    TMP_FILE="${QUARTO_FILE}.tmp.$$"
    awk -v entry="${ENTRY}" '
      /^  resources:/ && !added {
        print entry
        added=1
      }
      { print }
      END {
        if (!added) {
          print entry
        }
      }
    ' "${QUARTO_FILE}" > "${TMP_FILE}"
    mv "${TMP_FILE}" "${QUARTO_FILE}"
  fi
fi

echo "Created presentations/${DECK_NAME}"
if [[ "${ADD_RENDER_ENTRY}" == true ]]; then
  echo "Added presentations/${DECK_NAME}/presentation.qmd to _quarto.yml render list"
fi

echo "Next step: scripts/quarto_preview_watch_includes.sh presentations/${DECK_NAME}/presentation.qmd"
