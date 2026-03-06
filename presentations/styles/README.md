# Shared Presentation Styles

Shared Quarto/reveal.js CSS themes and include snippets.

## Themes

- `neutral-academic.css` (default): neutral professional baseline
- `academic-clean.css`: blue-tinted variant
- `monochrome-formal.css`: print-like grayscale variant

Use in deck front matter:

```yaml
format:
  revealjs:
    css:
      - ../styles/neutral-academic.css
      - <deck>.css
```

## Include Snippets

- `presentation-macros.html`: generated MathJax macros
- `reveal-preview-restore-slide.html`: keep slide position across preview reloads
- `reveal-citation-hover-only.html`: hide refs slide while preserving hover previews

Optional usage example:

```yaml
format:
  revealjs:
    include-before-body:
      - ../styles/presentation-macros.html
      - ../styles/reveal-preview-restore-slide.html
      - ../styles/reveal-citation-hover-only.html
```

## Regenerate macros include

```bash
python3 scripts/generate_math_macros.py sty_files/PresentationShortcuts.sty \
  --output presentations/styles/presentation-macros.html
```
