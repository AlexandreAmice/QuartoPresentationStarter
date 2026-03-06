#!/usr/bin/env bash
set -euo pipefail

# Work around Quarto preview not re-rendering when {{< include ... >}} files change.
# Watches include dependencies and touches the root qmd to trigger preview refresh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ $# -gt 0 ]]; then
  TARGET_INPUT="$1"
  shift
else
  TARGET_INPUT="presentations/quickstart/presentation.qmd"
fi

if ! command -v quarto >/dev/null 2>&1; then
  echo "ERROR: quarto is not available on PATH." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required for include dependency parsing." >&2
  exit 1
fi
if ! command -v inotifywait >/dev/null 2>&1; then
  echo "ERROR: inotifywait is required (package: inotify-tools)." >&2
  exit 1
fi

TARGET_ABS="$(realpath -m "${TARGET_INPUT}")"
if [[ ! -f "${TARGET_ABS}" ]]; then
  echo "ERROR: target file not found: ${TARGET_INPUT}" >&2
  exit 1
fi
TARGET_REL="$(realpath --relative-to="${REPO_ROOT}" "${TARGET_ABS}")"

declare -a WATCH_FILES=()

collect_watch_files() {
  local inspect_json
  local source_rel
  local target_rel
  local include_rel
  local include_abs

  inspect_json="$(cd "${REPO_ROOT}" && quarto inspect "${TARGET_REL}")"

  WATCH_FILES=("${TARGET_ABS}")
  while IFS=$'\t' read -r source_rel target_rel; do
    [[ -n "${source_rel}" && -n "${target_rel}" ]] || continue

    if [[ "${target_rel}" == /* ]]; then
      include_rel="${target_rel#/}"
    else
      include_rel="$(dirname "${source_rel}")/${target_rel}"
    fi
    include_abs="$(realpath -m "${REPO_ROOT}/${include_rel}")"
    if [[ -f "${include_abs}" ]]; then
      WATCH_FILES+=("${include_abs}")
    fi
  done < <(
    jq -r --arg file "${TARGET_REL}" '
      (.fileInformation[$file].includeMap // [])
      | .[]
      | [.source, .target]
      | @tsv
    ' <<<"${inspect_json}"
  )
}

watch_loop() {
  local changed_path

  while true; do
    collect_watch_files
    changed_path="$({
      inotifywait \
        --quiet \
        --event close_write,move_self,delete_self,move,delete,create \
        --format '%w%f' \
        "${WATCH_FILES[@]}" 2>/dev/null || true
    })"
    [[ -n "${changed_path}" ]] || continue
    if [[ "${changed_path}" != "${TARGET_ABS}" ]]; then
      touch "${TARGET_ABS}"
    fi
  done
}

watch_loop &
WATCH_PID=$!

cleanup() {
  if kill -0 "${WATCH_PID}" >/dev/null 2>&1; then
    kill "${WATCH_PID}" >/dev/null 2>&1 || true
    wait "${WATCH_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

cd "${REPO_ROOT}"
quarto preview "${TARGET_REL}" "$@"
