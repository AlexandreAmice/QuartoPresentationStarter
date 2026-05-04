#!/usr/bin/env bash
# Portable helpers for GNU/BSD (Linux/macOS) shell differences.
# Source this file from other scripts: `source "${SCRIPT_DIR}/compat.sh"`.

# abs_path PATH
# Absolute, lexically normalized path. Resolves symlinks on the existing
# ancestor directory and appends any non-existing tail (equivalent to
# GNU `realpath -m`).
abs_path() {
  local path="$1"
  if [[ "${path}" != /* ]]; then
    path="${PWD}/${path}"
  fi

  local rest="${path#/}"
  local -a parts=()
  local p
  while [[ -n "${rest}" ]]; do
    if [[ "${rest}" == */* ]]; then
      p="${rest%%/*}"
      rest="${rest#*/}"
    else
      p="${rest}"
      rest=""
    fi
    case "${p}" in
      ''|'.') ;;
      '..')
        if [[ ${#parts[@]} -gt 0 ]]; then
          parts=( "${parts[@]:0:${#parts[@]}-1}" )
        fi
        ;;
      *) parts+=( "${p}" ) ;;
    esac
  done
  local normalized=""
  if [[ ${#parts[@]} -gt 0 ]]; then
    for p in "${parts[@]}"; do
      normalized="${normalized}/${p}"
    done
  fi
  normalized="${normalized:-/}"

  local dir="${normalized}"
  local tail=""
  while [[ "${dir}" != "/" && ! -d "${dir}" ]]; do
    tail="/${dir##*/}${tail}"
    dir="${dir%/*}"
    [[ -z "${dir}" ]] && dir="/"
  done
  if [[ -d "${dir}" ]]; then
    printf '%s%s\n' "$(cd "${dir}" && pwd -P)" "${tail}"
  else
    printf '%s\n' "${normalized}"
  fi
}

# rel_path BASE PATH
# Path of PATH relative to BASE. Assumes PATH lives under BASE (true for
# all callers in this repo); otherwise returns PATH unchanged.
rel_path() {
  local base="$1"
  local path="$2"
  if [[ "${path}" == "${base}" ]]; then
    printf '.\n'
  elif [[ "${path}" == "${base}/"* ]]; then
    printf '%s\n' "${path#${base}/}"
  else
    printf '%s\n' "${path}"
  fi
}

# Detect the in-place sed flavor once, at source time.
if sed --version >/dev/null 2>&1; then
  _SED_INPLACE=( sed -i )
else
  _SED_INPLACE=( sed -i '' )
fi

# sed_inplace SED_ARGS... FILE
# In-place sed that works on both GNU sed (Linux) and BSD sed (macOS).
sed_inplace() {
  "${_SED_INPLACE[@]}" "$@"
}

# Detect the file watcher once, at source time.
# Prefer inotifywait on Linux (zero behavior change for existing users);
# fall back to fswatch (macOS default).
if command -v inotifywait >/dev/null 2>&1; then
  _WATCHER="inotifywait"
elif command -v fswatch >/dev/null 2>&1; then
  _WATCHER="fswatch"
else
  _WATCHER=""
fi

# watch_files_once FILE...
# Block until one of FILE changes, print the changed path, and return.
watch_files_once() {
  case "${_WATCHER}" in
    inotifywait)
      inotifywait --quiet \
        --event close_write,move_self,delete_self,move,delete,create \
        --format '%w%f' "$@" 2>/dev/null || true
      ;;
    fswatch)
      fswatch -1 "$@" 2>/dev/null || true
      ;;
    *)
      echo "ERROR: need inotifywait (Linux inotify-tools) or fswatch (macOS: 'brew install fswatch')." >&2
      return 1
      ;;
  esac
}

# require_watcher
# Fail fast if no supported file watcher was detected.
require_watcher() {
  if [[ -z "${_WATCHER}" ]]; then
    echo "ERROR: need inotifywait (Linux inotify-tools) or fswatch (macOS: 'brew install fswatch')." >&2
    return 1
  fi
  return 0
}
