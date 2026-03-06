# Quarto reveal.js Presentation Starter

Minimal working example for building reusable presentation decks with Quarto + reveal.js.

This template is designed to balance two goals:
- show core capabilities of the workflow (`quickstart` + `showcase`)
- keep the starter clean so new users can clone and start writing immediately

## What is included

- `presentations/quickstart/`: default starter deck (small, editable, ready to copy)
- `presentations/showcase/`: optional feature-heavy demo deck (animations, media, mermaid, executable code sample)
- `presentations/styles/`: shared themes and include snippets
- `scripts/`: workflow helpers (macro generation, include-aware preview, section edit preview, asset regeneration)
- `assets/`: reusable sample media and TikZ source
- `refs/references.bib`: sample bibliography
- `sty_files/PresentationShortcuts.sty`: sample LaTeX macro source

Rendered outputs are intentionally not committed (`presentation.html`, `presentation_files/`) so this stays source-only.

## Requirements

### Required (base starter)

- `quarto`

### Recommended (authoring workflow)

- `jq`
- `inotifywait` (`inotify-tools` package)
- `rg` (ripgrep)

### Optional (specific features)

- `python3` for `make macros`
- `latexmk` + `inkscape` (or `dvisvgm`) for `scripts/regenerate_asset_svgs.sh`
- Jupyter/Python kernel for render-time Python execution in `presentations/showcase`

## Quick start

Preview default starter deck:

```bash
scripts/quarto_preview_watch_includes.sh presentations/quickstart/presentation.qmd --no-browser --port 4301
```

Render the project default (quickstart):

```bash
quarto render
```

Render showcase explicitly:

```bash
quarto render presentations/showcase/presentation.qmd
```

## Create your own deck

Scaffold a new deck from quickstart:

```bash
scripts/new_presentation.sh my_talk --title "My Talk"
```

This creates `presentations/my_talk/`, renames deck-local CSS, updates deck titles, and adds the deck to `_quarto.yml` render list.

Then preview it:

```bash
scripts/quarto_preview_watch_includes.sh presentations/my_talk/presentation.qmd
```

## Workflow helpers

Regenerate MathJax macro include from LaTeX macros:

```bash
make macros
```

One-section edit preview (`presentation.edit.qmd`):

```bash
scripts/presentation_edit_preview.sh presentations/quickstart agenda --no-browser --port 4302
```

Regenerate standalone TikZ assets:

```bash
scripts/regenerate_asset_svgs.sh assets/tikz
```

For script behavior and side effects, see `scripts/README.md`.
For theme usage, see `presentations/styles/README.md`.

## Reference

- Quarto reveal.js demo from Quarto docs:
  - <https://github.com/quarto-dev/quarto-web/blob/main/docs/presentations/revealjs/demo/index.qmd>
