# Scripts Reference

This file documents scripts used by the Quarto presentation workflow.

## Script Index

| Script | Purpose | Writes/Modifies Files | Required Tools |
|---|---|---|---|
| `generate_math_macros.py` | Extract TeX-style macros and generate a MathJax include file | Writes the output include file | `python3` |
| `quarto_preview_watch_includes.sh` | Run `quarto preview` and auto-refresh when `{{< include ... >}}` dependencies change | Touches target `.qmd` to trigger refresh | `quarto`, `jq`, `inotifywait` |
| `presentation_edit_preview.sh` | Preview one section from `presentation.edit.qmd` | Rewrites active include line in `presentation.edit.qmd` | `quarto`, `jq`, `inotifywait`, `rg`, `find`, `sed` |
| `regenerate_asset_svgs.sh` | Rebuild standalone `.tex` assets into `.svg` (via PDF) | Writes/overwrites `.pdf` and `.svg` beside source | `latexmk` and (`inkscape` or `dvisvgm`) |
| `new_presentation.sh` | Scaffold a new deck from `presentations/quickstart` | Creates a new deck folder and optionally updates `_quarto.yml` | `bash`, `cp`, `mv`, `sed`, `awk`, `rg` |

## `generate_math_macros.py`

### Usage

```bash
python3 scripts/generate_math_macros.py <source1> [<source2> ...] [--output <output.html>] [--no-fallbacks]
```

### Defaults

- Output: `presentations/styles/presentation-macros.html`
- Adds fallback defs for `\bm`, `\bbone`, `\boondoxupr` unless `--no-fallbacks` is set

### Examples

```bash
python3 scripts/generate_math_macros.py sty_files/PresentationShortcuts.sty
python3 scripts/generate_math_macros.py sty_files/PresentationShortcuts.sty --output presentations/styles/presentation-macros.html
```

## `quarto_preview_watch_includes.sh`

### Usage

```bash
scripts/quarto_preview_watch_includes.sh [target-qmd] [quarto preview args...]
```

### Default target

- `presentations/quickstart/presentation.qmd`

### Example

```bash
scripts/quarto_preview_watch_includes.sh presentations/showcase/presentation.qmd --no-browser --port 4301
```

## `presentation_edit_preview.sh`

### Usage

```bash
scripts/presentation_edit_preview.sh [deck-dir] [section] [quarto preview args...]
```

### Default deck

- `presentations/quickstart`

### Example

```bash
scripts/presentation_edit_preview.sh presentations/showcase methods --no-browser --port 4302
```

### Side effect

- Rewrites one include line in `<deck-dir>/presentation.edit.qmd`.

## `regenerate_asset_svgs.sh`

### Usage

```bash
scripts/regenerate_asset_svgs.sh [assets-dir]
```

### Default

- `assets`

### Example

```bash
scripts/regenerate_asset_svgs.sh assets/tikz
```

## `new_presentation.sh`

### Usage

```bash
scripts/new_presentation.sh <deck-name> [--title "Deck Title"] [--no-render-entry]
```

### Example

```bash
scripts/new_presentation.sh my_talk --title "My Talk"
```

### Side effects

- Copies `presentations/quickstart` to `presentations/<deck-name>`.
- Renames `quickstart.css` to `<deck-name>.css`.
- Updates deck title strings in the copied QMD files.
- Adds `presentations/<deck-name>/presentation.qmd` to `_quarto.yml` unless `--no-render-entry` is used.
