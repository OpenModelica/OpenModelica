.PHONY: generated_pdfs/dyOptInitialGuess.pdf generated_pdfs/cruntimedraft.pdf usersguide cppruntime-doc clean
all: generated_pdfs/dyOptInitialGuess.pdf

generated_pdfs/cruntimedraft.pdf:
	latexmk -outdir=generated_pdfs -pdf SimulationRuntime/c/src/cruntimedraft.tex

generated_pdfs/dyOptInitialGuess.pdf:
	latexmk -outdir=generated_pdfs -pdf SimulationRuntime/DynamicOptimization/src/dyOptInitialGuess.tex

usersguide:
	$(MAKE) -C UsersGuide html
	@# OMPython sucks at cleaning up...
	@killall omc >/dev/null 2>&1 || true
BUILDDIR=openmodelica-doc_$(BUILDDIR_VER)

cppruntime-doc:
	mkdir -p SimulationRuntime/cpp/Images
	cp images/logo.svg SimulationRuntime/cpp/Images/OMLogo.svg
	cd SimulationRuntime/cpp && cmake -G "Unix Makefiles" -DSOURCE_ROOT=../../../OMCompiler/SimulationRuntime/cpp && make Docs

cppruntime-doc-clean:
	rm SimulationRuntime/cpp/Makefile -f
	rm SimulationRuntime/cpp/CMakeCache.txt -f
	rm SimulationRuntime/cpp/cmake_install.cmake -f
	rm SimulationRuntime/cpp/CppRuntimeDoc.config -f
	rm SimulationRuntime/cpp/CMakeFiles -rf
	rm SimulationRuntime/cpp/Doc -rf
	rm SimulationRuntime/cpp/Images/OMLogo.svg -f

docs-internal: generated_pdfs/dyOptInitialGuess.pdf generated_pdfs/cruntimedraft.pdf usersguide cppruntime-doc
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

clean:

