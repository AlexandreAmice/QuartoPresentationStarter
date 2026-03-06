.PHONY: macros preview-quickstart preview-showcase render render-showcase new-deck

MACRO_SOURCE ?= sty_files/PresentationShortcuts.sty
MACRO_OUTPUT ?= presentations/styles/presentation-macros.html
PREVIEW_ARGS ?=

macros:
	python3 scripts/generate_math_macros.py $(MACRO_SOURCE) --output $(MACRO_OUTPUT)

preview-quickstart:
	./scripts/quarto_preview_watch_includes.sh presentations/quickstart/presentation.qmd $(PREVIEW_ARGS)

preview-showcase:
	./scripts/quarto_preview_watch_includes.sh presentations/showcase/presentation.qmd $(PREVIEW_ARGS)

render:
	quarto render

render-showcase:
	quarto render presentations/showcase/presentation.qmd

new-deck:
	./scripts/new_presentation.sh $(DECK_NAME)
