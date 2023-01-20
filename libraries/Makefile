BUILD_DIR=build/
OMC=omc
SVN_DIRS="MSL 3.2.1" "MSL 3.1" "MSL 2.2.2" "MSL 1.6" "Biochem" "NewTables" "Modelica_EmbeddedSystems" "ADGenKinetics" "BondGraph" "Buildings" "IndustrialControlSystems" "LinearMPC" "OpenHydraulics" "RealTimeCoordinationLibrary" "PowerFlow" "EEnStorage" "InstantaneousSymmetricalComponents"
host_short=no
RPATH_QMAKE=
CMAKE_RPATH = CC="$(CC)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" CPPFLAGS="$(CPPFLAGS)" LDFLAGS="$(RPATH_QMAKE)" cmake

default: core
.PHONY: macports Modelica\ 3.2.1.patch Modelica\ 1.6.patch Modelica\ trunk.patch Complex\ trunk.patch ModelicaTest\ trunk.patch ModelicaServices\ trunk.patch

include Makefile.libs

core: $(CORE_TARGET)
$(CORE_TARGET):
	rm -rf $(BUILD_DIR) build
	mkdir -p $(BUILD_DIR)
	$(MAKE) $(CORE_LIBS)
	touch $@

all: $(ALL_TARGET)
$(ALL_TARGET):
	rm -rf $(BUILD_DIR) build
	mkdir -p $(BUILD_DIR)
	$(MAKE) $(ALL_LIBS)
	touch $@

python-update: Makefile.numjobs config.done
	rm -rf $(BUILD_DIR) build
	rm -f *.uses
	# Tags are fetched by check-update
	$(MAKE) all-work
	@# Could run uses and test at the same time, but this way we get nicer error-messages and a faster error if the uses fail (they are a lot faster than test)
	$(MAKE) uses
all-work: config.done Makefile.numjobs
	mkdir -p $(BUILD_DIR) svn
	./update-library.py -n `cat Makefile.numjobs` --build-dir $(BUILD_DIR) --omc $(OMC)
config.done: Makefile
	which rm > /dev/null
	which svn > /dev/null
	which git > /dev/null
	$(OMC) +version > /dev/null
	which xargs > /dev/null
	#which xsltproc > /dev/null
	which xpath > /dev/null
	touch config.done
Makefile.numjobs:
	@echo 7 > $@
	@echo "*** Setting number of jobs to 5. 1 makes things too slow and 5 threads. Set $@ if you want to change it ***"

test: config.done Makefile.numjobs
	rm -f error.log test-valid.*.mos
	find $(BUILD_DIR)/*.mo $(BUILD_DIR)/*/package.mo -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './test-valid.sh "$(OMC)" "$(BUILD_DIR)" "$$1"' sh
	test ! -f error.log || cat error.log
	test ! -f error.log
	rm -f error.log test-valid.*.mos
uses: config.done Makefile.numjobs
	find $(BUILD_DIR)/*.uses -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './check-uses.sh "$(BUILD_DIR)" "$$1"' sh
clean:
	rm -f *.rev *.uses  test-valid.*.mos config.done
	rm -rf build debian-build $(SVN_DIRS)

check-latest: config.done Makefile.numjobs
	@echo "Looking for more recent versions of packages"
	rm -rf build .customBuild
	mkdir -p build
	./update-library.py -n `cat Makefile.numjobs` --check-latest
	rm -rf .customBuild
add-missing: config.done Makefile.numjobs
	@echo "Adding missing github repositories using trunk / latest revision"
	./update-library.py -n `cat Makefile.numjobs` --add-missing

MACPORTSTARBALL=macports-build/openmodelicalibraries_$(GITREVISION).tar.xz
dist-tarball:
	test "$(BUILD_DIR)" = "build/"
	$(MAKE) GITREVISION=`git show -s --format="%ad" --date="iso" | tr -d -- - | cut "-d " -f1-2 | tr -d : | tr " " -` dist-tarball-internal
dist-tarball-internal:
	test ! -z $(GITREVISION)
	$(MAKE) all
	rm -f build/*.uses build/*.ok build/*.license build/*.depends build/*.last_change build/*.breaks build/*.std build/*.provides build/*.provided
	rm -rf openmodelicalibraries_$(GITREVISION)/
	mkdir -p openmodelicalibraries_$(GITREVISION)/
	mv build openmodelicalibraries_$(GITREVISION)/libraries
	cp templates/macports/Makefile.in templates/macports/configure.in openmodelicalibraries_$(GITREVISION)/
	mkdir -p macports-build
	tar cJf $(MACPORTSTARBALL) openmodelicalibraries_$(GITREVISION)
#	sed -e "s/@REV@/$(GITREVISION)/" \
#        -e "s/@MD5@/`openssl md5 $(MACPORTSTARBALL) | cut -d \  -f 2`/" \
#        -e "s/@SHA1@/`openssl sha1 $(MACPORTSTARBALL) | cut -d \  -f 2`/" \
#        -e "s/@RMD160@/`openssl rmd160 $(MACPORTSTARBALL) | cut -d \  -f 2`/" templates/macports/Portfile.in > macports-build/Portfile

macports:
	$(MAKE) GITREVISION=`git show -s --format="%ad" --date="iso" | tr -d -- - | cut "-d " -f1-2 | tr -d : | tr " " -` macports-internal
macports-internal:
	test -f .remote/macports
	rsync --delete -a rsync://build.openmodelica.org/macports macports
	find $(BUILD_DIR)/*.ok -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './macports-build.sh "$$1"' sh
	rm -rf macports/lang/omlib-all/
	mkdir -p macports/lang/openmodelicalibraries/
	( cd build ; sed s/@REV@/$(GITREVISION)/ ../templates/macports/Portfile.in | sed "s/@DEPENDS@/`../macports-all-depends.sh`/" > ../macports/lang/openmodelicalibraries/Portfile )
	.remote/macports

# .remote/control-files: Directory where the list of packages should be stored. Used by a shell-script + apt-ftparchive
# .remote/pool: Directory where the deb-packages and sources should be stored
debian: config.done Makefile.numjobs .remote/control-files .remote/pool
	rm -rf debian-build
	mkdir -p debian-build
	scp "`cat .remote/control-files`/nightly-library-files" .remote/nightly-library-files
	scp "`cat .remote/control-files`/nightly-library-sources" .remote/nightly-library-sources
	find $(BUILD_DIR)/*.ok -print0 | xargs -0 -n 1 -P `cat Makefile.numjobs` sh -c './debian-build.sh "$$1"' sh
	./check-debian.sh
	diff -u .remote/nightly-library-files nightly-library-files || true
	diff -u .remote/nightly-library-sources nightly-library-sources || true
rpm: config.done .remote/rpmpool .remote/pool
	rm -rf rpm-build
	mkdir -p rpm-build
	@# Can't run rpm-build in parallel because alien can't be run in parallel
	cat .remote/nightly-library-files | xargs -n 1 sh -c './rpm-build.sh "$$1"' sh
	./rpm-build.sh $(TIMESTAMP)
upload: config.done .remote/control-files .remote/pool
	diff -u .remote/nightly-library-files nightly-library-files || (! stat -t debian-build/*.deb >/dev/null 2>&1) || rsync --ignore-existing debian-build/*.deb debian-build/*.tar.gz debian-build/*.tar.xz debian-build/*.dsc "`cat .remote/pool`"
	scp nightly-library-files nightly-library-sources "`cat .remote/control-files`"
	scp "`cat .remote/control-files`/nightly-library-files" .remote/nightly-library-files
	scp "`cat .remote/control-files`/nightly-library-sources" .remote/nightly-library-sources
	./check-debian.sh
upload-rpm: .remote/rpmpool
	(! stat -t rpm-build/*.rpm >/dev/null 2>&1) || rsync --ignore-existing rpm-build/*.rpm "`cat .remote/rpmpool`"

Modelica\ 3.2.1.patch:
	-diff -u -x .svn -x .git -x Library -r git/Modelica/Modelica build/Modelica\ 3.2.1 > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
Modelica\ 1.6.patch:
	-diff -u -x .svn -x .git -x Library -r "git/Modelica/Modelica 1.6" "build/Modelica 1.6" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
Modelica\ trunk.patch:
	-diff -u -x .svn -x .git -x Library -r "git/Modelica/Modelica" "build/Modelica trunk" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
ModelicaTest\ trunk.patch:
	-diff -u -x .svn -x .git -x Library -r "git/Modelica/ModelicaTest" "build/ModelicaTest trunk" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
ModelicaServices\ trunk.patch:
	-diff -u -x .svn -x .git -x Library -r "git/Modelica/ModelicaServices" "build/ModelicaServices trunk" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
Complex\ trunk.patch:
	-diff -u "git/Modelica/Complex.mo" "build/Complex trunk.mo" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
Modelica\ 3.2.2.patch:
	-diff -u -x .svn -x .git -x Library -r "git/Modelica/Modelica" "build/Modelica 3.2.2" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
ModelicaServices\ 3.2.2.patch:
	-diff -u -w -x .svn -x .git -x Library -r "git/Modelica/ModelicaServices" "build/ModelicaServices 3.2.2" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
Modelica\ 3.2.3.patch:
	-diff -u -x .svn -x .git -x Library -r "git/Modelica/Modelica" "build/Modelica 3.2.3" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
ModelicaServices\ 3.2.3.patch:
	-diff -u -w -x .svn -x .git -x Library -r "git/Modelica/ModelicaServices" "build/ModelicaServices 3.2.3" > "$@.tmp"
	sed -i /^Only.in/d "$@.tmp"
	sed -i 's/^\([+-][+-][+-]\) "\([^"]*\)"/\1 \2/' "$@.tmp"
	mv "$@.tmp" "$@"
