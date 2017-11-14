# Makefile for Sphinx documentation
#

OPENMODELICA_ROOT = $(CURDIR)/../../
# OMPython needs this
OPENMODELICAHOME := $(OPENMODELICA_ROOT)/build/

# You can set these variables from the command line.

SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
PAPER         =
BUILDDIR      = build

ALLDEP = source/openmodelica.bib source/interface.inc $(OMEDIT_ICONS) $(OMOPTIM_ICONS)

# User-friendly check for sphinx-build
ifeq ($(shell which $(SPHINXBUILD) >/dev/null 2>&1; echo $$?), 1)
$(error The '$(SPHINXBUILD)' command was not found. Make sure you have Sphinx installed, then set the SPHINXBUILD environment variable to point to the full path of the '$(SPHINXBUILD)' executable. Alternatively you can add the directory with the executable to your PATH. If you don't have Sphinx installed, grab it from http://sphinx-doc.org/)
endif

# Internal variables.
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
ALLSPHINXOPTS   = -d $(BUILDDIR)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) source
# the i18n builder cannot share the environment and doctrees with the others
I18NSPHINXOPTS  = $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) source

.PHONY: help clean html htmlmathpng dirhtml singlehtml pickle json htmlhelp qthelp devhelp epub latex latexpdf text man changes linkcheck doctest coverage gettext readme

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  html           to make standalone HTML files"
	@echo "  htmlmathpng    to make standalone HTML files using dvipng instead of dvisvgm"
	@echo "  dirhtml        to make HTML files named index.html in directories"
	@echo "  singlehtml     to make a single large HTML file"
	@echo "  pickle         to make pickle files"
	@echo "  json           to make JSON files"
	@echo "  htmlhelp       to make HTML files and a HTML help project"
	@echo "  qthelp         to make HTML files and a qthelp project"
	@echo "  applehelp      to make an Apple Help Book"
	@echo "  devhelp        to make HTML files and a Devhelp project"
	@echo "  epub           to make an epub"
	@echo "  latex          to make LaTeX files, you can set PAPER=a4 or PAPER=letter"
	@echo "  latexpdf       to make LaTeX files and run them through pdflatex"
	@echo "  latexpdfja     to make LaTeX files and run them through platex/dvipdfmx"
	@echo "  text           to make text files"
	@echo "  man            to make manual pages"
	@echo "  texinfo        to make Texinfo files"
	@echo "  info           to make Texinfo files and run them through makeinfo"
	@echo "  gettext        to make PO message catalogs"
	@echo "  changes        to make an overview of all changed/added/deprecated items"
	@echo "  xml            to make Docutils-native XML files"
	@echo "  pseudoxml      to make pseudoxml-XML files for display purposes"
	@echo "  linkcheck      to check all external links for integrity"
	@echo "  doctest        to run all doctests embedded in the documentation (if enabled)"
	@echo "  coverage       to run coverage check of the documentation (if enabled)"

clean:
	rm -rf $(BUILDDIR)/*

html: all-dep
	$(SPHINXBUILD) -b html -t nomathjax $(ALLSPHINXOPTS) $(BUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)/html."

htmlmathpng: all-dep
	$(SPHINXBUILD) -b html -t nomathjax $(ALLSPHINXOPTS) $(BUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)/html."

htmlmathjax: all-dep
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(BUILDDIR)/htmlmathjax
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)/htmlmathjax."

dirhtml: all-dep
	$(SPHINXBUILD) -b dirhtml -t nomathjax $(ALLSPHINXOPTS) $(BUILDDIR)/dirhtml
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)/dirhtml."

singlehtml: all-dep
	$(SPHINXBUILD) -b singlehtml -t nomathjax $(ALLSPHINXOPTS) $(BUILDDIR)/singlehtml
	@echo
	@echo "Build finished. The HTML page is in $(BUILDDIR)/singlehtml."

pickle: all-dep
	$(SPHINXBUILD) -b pickle $(ALLSPHINXOPTS) $(BUILDDIR)/pickle
	@echo
	@echo "Build finished; now you can process the pickle files."

json: all-dep
	$(SPHINXBUILD) -b json $(ALLSPHINXOPTS) $(BUILDDIR)/json
	@echo
	@echo "Build finished; now you can process the JSON files."

htmlhelp: all-dep
	$(SPHINXBUILD) -b htmlhelp $(ALLSPHINXOPTS) $(BUILDDIR)/htmlhelp
	@echo
	@echo "Build finished; now you can run HTML Help Workshop with the" \
	      ".hhp project file in $(BUILDDIR)/htmlhelp."

qthelp: all-dep
	$(SPHINXBUILD) -b qthelp $(ALLSPHINXOPTS) $(BUILDDIR)/qthelp
	@echo
	@echo "Build finished; now you can run "qcollectiongenerator" with the" \
	      ".qhcp project file in $(BUILDDIR)/qthelp, like this:"
	@echo "# qcollectiongenerator $(BUILDDIR)/qthelp/OpenModelicaUsersGuide.qhcp"
	@echo "To view the help file:"
	@echo "# assistant -collectionFile $(BUILDDIR)/qthelp/OpenModelicaUsersGuide.qhc"

applehelp: all-dep
	$(SPHINXBUILD) -b applehelp $(ALLSPHINXOPTS) $(BUILDDIR)/applehelp
	@echo
	@echo "Build finished. The help book is in $(BUILDDIR)/applehelp."
	@echo "N.B. You won't be able to view it unless you put it in" \
	      "~/Library/Documentation/Help or install it in your application" \
	      "bundle."

devhelp: all-dep
	$(SPHINXBUILD) -b devhelp $(ALLSPHINXOPTS) $(BUILDDIR)/devhelp
	@echo
	@echo "Build finished."
	@echo "To view the help file:"
	@echo "# mkdir -p $$HOME/.local/share/devhelp/OpenModelicaUsersGuide"
	@echo "# ln -s $(BUILDDIR)/devhelp $$HOME/.local/share/devhelp/OpenModelicaUsersGuide"
	@echo "# devhelp"

epub: all-dep
	$(SPHINXBUILD) -b epub -t nomathjax $(ALLSPHINXOPTS) $(BUILDDIR)/epub
	@echo
	@echo "Build finished. The epub file is in $(BUILDDIR)/epub."

latexpdf: all-dep
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(BUILDDIR)/latex
	@echo "Running LaTeX files through pdflatex..."
	$(MAKE) -C $(BUILDDIR)/latex all-pdf
	@echo "pdflatex finished; the PDF files are in $(BUILDDIR)/latex."

latexpdfja: all-dep
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(BUILDDIR)/latex
	@echo "Running LaTeX files through platex and dvipdfmx..."
	$(MAKE) -C $(BUILDDIR)/latex all-pdf-ja
	@echo "pdflatex finished; the PDF files are in $(BUILDDIR)/latex."

text: all-dep
	$(SPHINXBUILD) -b text $(ALLSPHINXOPTS) $(BUILDDIR)/text
	@echo
	@echo "Build finished. The text files are in $(BUILDDIR)/text."

man: all-dep
	$(SPHINXBUILD) -b man $(ALLSPHINXOPTS) $(BUILDDIR)/man
	@echo
	@echo "Build finished. The manual pages are in $(BUILDDIR)/man."

texinfo: all-dep
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(BUILDDIR)/texinfo
	@echo
	@echo "Build finished. The Texinfo files are in $(BUILDDIR)/texinfo."
	@echo "Run \`make' in that directory to run these through makeinfo" \
	      "(use \`make info' here to do that automatically)."

info: all-dep
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(BUILDDIR)/texinfo
	@echo "Running Texinfo files through makeinfo..."
	make -C $(BUILDDIR)/texinfo info
	@echo "makeinfo finished; the Info files are in $(BUILDDIR)/texinfo."

gettext: all-dep
	$(SPHINXBUILD) -b gettext $(I18NSPHINXOPTS) $(BUILDDIR)/locale
	@echo
	@echo "Build finished. The message catalogs are in $(BUILDDIR)/locale."

changes: all-dep
	$(SPHINXBUILD) -b changes $(ALLSPHINXOPTS) $(BUILDDIR)/changes
	@echo
	@echo "The overview file is in $(BUILDDIR)/changes."

linkcheck: all-dep
	$(SPHINXBUILD) -b linkcheck $(ALLSPHINXOPTS) $(BUILDDIR)/linkcheck
	@echo
	@echo "Link check complete; look for any errors in the above output " \
	      "or in $(BUILDDIR)/linkcheck/output.txt."

doctest: all-dep
	$(SPHINXBUILD) -b doctest $(ALLSPHINXOPTS) $(BUILDDIR)/doctest
	@echo "Testing of doctests in the sources finished, look at the " \
	      "results in $(BUILDDIR)/doctest/output.txt."

coverage: all-dep
	$(SPHINXBUILD) -b coverage $(ALLSPHINXOPTS) $(BUILDDIR)/coverage
	@echo "Testing of coverage in the sources finished, look at the " \
	      "results in $(BUILDDIR)/coverage/python.txt."

xml: all-dep
	$(SPHINXBUILD) -b xml $(ALLSPHINXOPTS) $(BUILDDIR)/xml
	@echo
	@echo "Build finished. The XML files are in $(BUILDDIR)/xml."

pseudoxml: all-dep
	$(SPHINXBUILD) -b pseudoxml $(ALLSPHINXOPTS) $(BUILDDIR)/pseudoxml
	@echo
	@echo "Build finished. The pseudo-XML files are in $(BUILDDIR)/pseudoxml."

latex: all-dep source/logo.pdf source/media/systemoverview.pdf
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(BUILDDIR)/latex
	@echo
	@echo "Build finished; the LaTeX files are in $(BUILDDIR)/latex."
	@echo "Run \`make' in that directory to run these through (pdf)latex" \
	      "(use \`make latexpdf' here to do that automatically)."
ADDED_SVGS=$(wildcard source/ProfilingTest_*.svg)
addedPdfs: $(ADDED_SVGS:%.svg=%.pdf)
pdf: latex
	$(MAKE) addedPdfs
	sed -i "s/usepackage.utf8..inputenc./usepackage[utf8x]{inputenc}/" build/latex/OpenModelicaUsersGuide.tex
	sed -i -e "/^ *\\\\DeclareUnicodeCharacter/d" build/latex/OpenModelicaUsersGuide.tex
	# sphinx seems to only handle .* extension for images?
	sed -i "s,{\(media/[A-Za-z_0-9.-]*\)[.][*],{`pwd`/source/\1.pdf,g" build/latex/OpenModelicaUsersGuide.tex
	sed -i "s,{ProfilingTest_prof[.]\([^.]*\)[.]thumb[.]svg,{`pwd`/source/ProfilingTest_prof-\1-thumb.pdf,g" build/latex/OpenModelicaUsersGuide.tex
	(cd build/latex && latexmk -pdf OpenModelicaUsersGuide.tex)
source/logo.pdf: source/logo.svg
	inkscape -f $< -A $@
source/media/systemoverview.pdf: source/media/systemoverview.svg
	inkscape -f $< --export-pdf $@
%.pdf: %.svg
	inkscape -f $< --export-pdf $@
	FNAME=`echo $@ | sed "s/[.]/-/g" | sed "s/-pdf/.pdf/g"`; if test "$$FNAME" != "$@"; then cp -a "$@" "$$FNAME"; fi
source/openmodelica.bib: resolve-crossref.py ../bibliography/openmodelica.bib
	python resolve-crossref.py "../bibliography/openmodelica.bib" source/openmodelica.bib
source/interface.inc: interface.mos
	@mkdir -p tmp
	$(OPENMODELICA_ROOT)/build/bin/omc -g=MetaModelica -d=nogen interface.mos
	mv interface.inc $@

OMEDIT_ICONS_BASE=connect-mode.svg transition-mode.svg parametric-plot-window.svg plot-window.svg re-simulate.svg tlm-simulate.svg interface-data.svg simulation-parameters.svg
OMEDIT_ICONS_SVG=$(OMEDIT_ICONS_BASE:%=source/media/omedit-icons/%)
OMEDIT_ICONS_PDF=$(OMEDIT_ICONS_SVG:%.svg=%.pdf)
OMEDIT_ICONS_PNG=$(OMEDIT_ICONS_SVG:%.svg=%.png)
OMEDIT_ICONS=$(OMEDIT_ICONS_SVG) $(OMEDIT_ICONS_PNG) $(OMEDIT_ICONS_PDF)

OMOPTIM_ICONS_BASE=Add.png
OMOPTIM_ICONS=$(OMOPTIM_ICONS_BASE:%=source/media/omoptim-icons/%)

all-dep: $(ALLDEP) source/media/mathematica-notebooks.pdf source/media/mdt-create-project.pdf source/media/mdt-build-prompt.pdf source/simoptions.inc source/omchelptext.rst source/tracreleases.rst

source/media/omedit-icons/%.svg: $(OPENMODELICA_ROOT)/OMEdit/OMEdit/OMEditGUI/Resources/icons/%.svg
	@mkdir -p source/media/omedit-icons
	cp -a "$<" "$@"

source/media/omedit-icons/%.png: source/media/omedit-icons/%.svg
	inkscape "$<" --export-png="$@"
source/media/omedit-icons/%.pdf: source/media/omedit-icons/%.svg
	inkscape "$<" --export-pdf="$@"

source/media/omoptim-icons/%.png: $(OPENMODELICA_ROOT)/OMOptim/OMOptim/GUI/Resources/icons/%.png
	@mkdir -p source/media/omoptim-icons
	cp -a "$<" "$@"

readme/sphinxcontribopenmodelica.py: source/sphinxcontribopenmodelica.py
	cp -a "$<" "$@"
readme: readme/sphinxcontribopenmodelica.py
	ln -sf ../source/aplot.svg readme
	sphinx-build -b html -t nomathjax -d build/readme/doctrees readme build/readme/html
source/simoptions.inc:
	$(OPENMODELICA_ROOT)/build/bin/omc +help=simulation-sphinxoutput > "$@.tmp"
	mv "$@.tmp" "$@"
source/omchelptext.rst:
	$(OPENMODELICA_ROOT)/build/bin/omc +help=omcall-sphinxoutput > "$@.tmp"
	mv "$@.tmp" "$@"
source/tracreleases.rst: source/tracreleases.py
	cd source && python ./tracreleases.py
