#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ASSETS_INPUT="${1:-assets}"
ASSETS_DIR="$(realpath -m "${REPO_ROOT}/${ASSETS_INPUT}")"

if [[ ! -d "${ASSETS_DIR}" ]]; then
  echo "ERROR: assets directory not found: ${ASSETS_INPUT}" >&2
  exit 1
fi

if ! command -v latexmk >/dev/null 2>&1; then
  echo "ERROR: latexmk is required but not on PATH." >&2
  exit 1
fi

if command -v inkscape >/dev/null 2>&1; then
  SVG_BACKEND="inkscape"
elif command -v dvisvgm >/dev/null 2>&1; then
  SVG_BACKEND="dvisvgm"
else
  echo "ERROR: inkscape or dvisvgm is required but neither is on PATH." >&2
  exit 1
fi

echo "Using SVG backend: ${SVG_BACKEND}"

ASSETS_REL="$(realpath --relative-to="${REPO_ROOT}" "${ASSETS_DIR}")"

mapfile -t TEX_FILES < <(
  cd "${REPO_ROOT}" && find "${ASSETS_REL}" -type f -name '*.tex' | LC_ALL=C sort
)

if [[ ${#TEX_FILES[@]} -eq 0 ]]; then
  echo "No .tex files found under ${ASSETS_REL}."
  exit 0
fi

processed=0
skipped=0
failed=0

for tex_rel in "${TEX_FILES[@]}"; do
  tex_abs="${REPO_ROOT}/${tex_rel}"

  if ! rg -q '\\documentclass(\[[^]]*\])?\{standalone\}' "${tex_abs}"; then
    echo "SKIP ${tex_rel} (not standalone)"
    ((skipped+=1))
    continue
  fi

  tex_dir="$(dirname "${tex_abs}")"
  tex_file="$(basename "${tex_abs}")"
  pdf_file="${tex_file%.tex}.pdf"
  svg_file="${tex_file%.tex}.svg"

  has_raster=false
  if rg -q '\\includegraphics' "${tex_abs}"; then
    has_raster=true
  fi

  echo "BUILD ${tex_rel}$(${has_raster} && echo ' [has raster images]' || true)"
  if ! (cd "${tex_dir}" && latexmk -pdf -interaction=nonstopmode "${tex_file}" >/dev/null); then
    echo "FAIL  ${tex_rel} (latexmk failed)"
    ((failed+=1))
    continue
  fi

  if [[ ! -f "${tex_dir}/${pdf_file}" ]]; then
    echo "FAIL  ${tex_rel} (missing ${pdf_file})"
    ((failed+=1))
    continue
  fi

  convert_ok=false
  if [[ "${SVG_BACKEND}" == "inkscape" ]]; then
    if (cd "${tex_dir}" && inkscape --pdf-poppler "${pdf_file}" --export-type=svg --export-filename="${svg_file}" >/dev/null 2>&1); then
      convert_ok=true
    fi
  else
    extra_flags=""
    if ${has_raster}; then
      extra_flags="--gs"
    fi
    # shellcheck disable=SC2086
    if (cd "${tex_dir}" && dvisvgm --pdf ${extra_flags} "${pdf_file}" -o "${svg_file}" >/dev/null); then
      convert_ok=true
    fi
  fi

  if ! ${convert_ok}; then
    echo "FAIL  ${tex_rel} (svg conversion failed)"
    ((failed+=1))
    continue
  fi

  echo "OK    ${tex_rel} -> ${tex_rel%.tex}.svg"
  ((processed+=1))
done

echo
echo "Summary: ${processed} converted, ${skipped} skipped, ${failed} failed"

if [[ ${failed} -gt 0 ]]; then
  exit 1
fi
