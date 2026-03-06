# Quickstart Deck

Default starter deck for cloning into a new talk.

- Canonical deck: `presentation.qmd`
- Edit mode deck: `presentation.edit.qmd`
- Sections: `sections/*.qmd`
- Deck-local css: `quickstart.css`

Common commands:

```bash
# Full deck preview with include watching
scripts/quarto_preview_watch_includes.sh presentations/quickstart/presentation.qmd

# Focus one section in edit mode
scripts/presentation_edit_preview.sh presentations/quickstart agenda
```
