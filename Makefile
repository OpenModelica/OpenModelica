.PHONY: generated_pdfs/dyOptInitialGuess.pdf generated_pdfs/cruntimedraft.pdf usersguide
all: generated_pdfs/dyOptInitialGuess.pdf
generated_pdfs/cruntimedraft.pdf:
	latexmk -outdir=generated_pdfs -lualatex SimulationRuntime/c/src/cruntimedraft.tex
generated_pdfs/dyOptInitialGuess.pdf:
	latexmk -outdir=generated_pdfs -lualatex SimulationRuntime/DynamicOptimization/src/dyOptInitialGuess.tex
usersguide:
	$(MAKE) -C UsersGuide html
	@# OMPython sucks at cleaning up...
	@killall omc >/dev/null 2>&1
BUILDDIR=openmodelica-doc_$(BUILDDIR_VER)
docs-internal: generated_pdfs/dyOptInitialGuess.pdf generated_pdfs/cruntimedraft.pdf usersguide
	@test ! -z "$(BUILDDIR_VER)" || (echo Call docs, not docs-internal directly; false)
	@test ! -z "$(BUILDDIR)"
	rm -rf ./$(BUILDDIR)
	mkdir -p ./$(BUILDDIR)/SystemDocumentation "./$(BUILDDIR)/OpenModelicaUsersGuide"
	cp generated_pdfs/cruntimedraft.pdf generated_pdfs/dyOptInitialGuess.pdf OpenModelicaMetaProgramming.pdf OpenModelicaSystem.pdf OpenModelicaTemplateProgramming.pdf "./$(BUILDDIR)/SystemDocumentation"
	cp ModelicaTutorialFritzson.pdf "./$(BUILDDIR)/"
	cp -a UsersGuide/build/html/* "./$(BUILDDIR)/OpenModelicaUsersGuide"
	tar cJf "$(BUILDDIR).orig.tar.xz" "./$(BUILDDIR)"
docs:
	test -f ../common/semver.sh
	$(MAKE) docs-internal BUILDDIR_VER="`cd ../ && ./common/semver.sh | sed -e 's/-dev[.]/~dev-/' -e 's/^v//'`"
