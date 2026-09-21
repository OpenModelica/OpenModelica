# dpkg and rpm both refuse a version that does not start with a digit, and the OpenModelica
# version is a `git describe` that starts with a "v" (and, without tags to describe against,
# may be a bare commit hash). cmake/omc_git_revision.cmake turns that into a package version
# and leaves it empty when it cannot, in which case CPACK_PACKAGE_VERSION is still CPack's
# 0.1.1 default. Building a package named after that default is worse than not building one:
# it installs, it looks fine, and it never upgrades because every real version sorts above it.
if(CPACK_GENERATOR MATCHES "^(DEB|RPM)$" AND "@OM_PACKAGE_VERSION@" STREQUAL "")
  message(FATAL_ERROR
    "Cannot build a ${CPACK_GENERATOR} package: no version could be derived from "
    "'@SOURCE_REVISION_BASE@'. Configure against a checkout whose tags are present "
    "(`git fetch --tags`, and no --depth on the clone), or put the version to package in "
    "OMVERSION.txt.")
endif()


# No source packages. CPack's source packaging archives the whole source directory while
# ignoring only the VCS directories, so it includes the build directory -- and with it the
# multi-gigabyte archive it is at that moment writing into build_cmake/_CPack_Packages/.
# It never errors, it just grows, which looks like cpack hanging.
#
# It cannot be switched off from the project: setting CPACK_SOURCE_GENERATOR to "" does
# nothing, because CPack treats an empty value as unset and restores its own default. So
# refuse here. CPACK_INSTALLED_DIRECTORIES is set by CPackSourceConfig.cmake and by nothing
# else, which is what distinguishes a source run from a plain `cpack -G TXZ`.
#
# Release tarballs are made with git-archive-all in the apt-build repository, which handles
# the dozen git submodules the sources are spread over.
if(CPACK_INSTALLED_DIRECTORIES)
  message(FATAL_ERROR
    "OpenModelica does not build source packages: CPack would archive the build directory "
    "into itself. Use git-archive-all (apt-build repository) for a source tarball, or "
    "`cpack --config CPackConfig.cmake -G TXZ` for an archive of the *installation*.")
endif()


# One package per component, not one per component *group*. CPack's default here is
# ONE_PER_GROUP, which -- because components.cmake groups our components under "Runtimes"
# and "GUIClients" for the benefit of the graphical installers -- would produce two packages
# named after those groups instead of the omc/omedit/omsimulator/... packages the apt and rpm
# repositories are made of. Only the DEB, RPM and archive generators read this; the graphical
# installers keep showing the group tree either way.
set(CPACK_COMPONENTS_GROUPING IGNORE)


## The openmodelica metapackage ###################################################################
# What the 'meta' component (cmake/packaging/components.cmake) depends on -- the whole point of it.
# Only the DEB and RPM generators build a metapackage.
#
# The 1.27.1 package's list, not everything a build produces: omlibrary and simrtcpp are reached
# by Recommends from omedit and omc instead. Intersected with CPACK_COMPONENTS_ALL at cpack time,
# because the build decides which components exist (no omedit without the GUI clients, none of
# omlibrary under --no-omlibrary) and one depending on a package nobody built is one apt refuses
# to install.
if(CPACK_GENERATOR MATCHES "^(DEB|RPM)$")
  set(CPACK_COMPONENT_META_DEPENDS "")
  foreach(_om_meta_component IN ITEMS
          omc omplot omshell omshellterminal omnotebook drmodelica drcontrol omedit omsimulator)
    if(_om_meta_component IN_LIST CPACK_COMPONENTS_ALL)
      list(APPEND CPACK_COMPONENT_META_DEPENDS ${_om_meta_component})
    endif()
  endforeach()
endif()


## Package Generator specific variables. ##########################################################################################

if(CPACK_GENERATOR STREQUAL "DEB")
  # Options and settings that are specific to Debian packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/deb.html
  # usage: cpack -G DEB

  set(CPACK_PACKAGING_INSTALL_PREFIX "/usr/local")

  set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

  # The Debian revision. It stays at 1 because we never re-release a given upstream
  # version: every build describes a different commit and so has its own version. It is
  # part of the file name that the apt-build scripts and the apt pool have always used
  # (openmodelica_<version>-1_<arch>.deb), which is why it is spelled out rather than
  # left to CPack's default.
  set(CPACK_DEBIAN_PACKAGE_RELEASE "1")

  set(CPACK_DEBIAN_PACKAGE_MAINTAINER "OpenModelica Build System <${CPACK_PACKAGE_CONTACT}>")

  # Enable component based packaging (omc, omedit, omsimulator, simrtcpp ...)
  # See the file common.cmake for a list of the components.
  set(CPACK_DEB_COMPONENT_INSTALL ON)

  # Let dpkg-shlibdeps work out the Depends: from what the binaries actually link, the way
  # dh_shlibdeps did for the Autoconf packaging. Without it the packages carry no Depends at
  # all: they install into a clean container and then omc does not start, because nothing
  # pulled in libcurl, LAPACK or BLAS.
  #
  # PRIVATE_DIRS names the directory our own shared libraries live in. They have no package
  # of their own to be found in, so dpkg-shlibdeps has to be told where they are or it fails
  # with "no dependency information found" for every one of them.
  set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
  set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS_PRIVATE_DIRS
      "${CPACK_TEMPORARY_INSTALL_DIRECTORY}/@CMAKE_INSTALL_LIBDIR@")

  # Allow setting our own inter-component dependencies
  set(CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS ON)

  # Without this the metapackage would be called openmodelica-meta, after its component. The
  # name people (and the install instructions) actually use is the bare one.
  set(CPACK_DEBIAN_META_PACKAGE_NAME "openmodelica")

  # Simulating a model means generating C and building it, so omc needs a compiler, a make
  # and a cmake at *run* time. dpkg-shlibdeps cannot find these -- omc executes them, it
  # does not link them -- so they are named here.
  #
  # gfortran is here for its libgfortran.so *symlink*, not for the compiler: the generated
  # makefile links -lgfortran (the reference LAPACK needs it) and the linker will not take
  # the libgfortran.so.5 that libgfortran5 ships. dpkg-shlibdeps only ever finds the
  # runtime library, so the -dev half has to be asked for by name. The RPM spec has
  # required gcc-gfortran for the same reason.
  set(CPACK_DEBIAN_OMC_PACKAGE_DEPENDS
      "clang, cmake, build-essential, gfortran, libexpat1-dev, liblapack-dev, zip, unzip")

  # What omc can use but runs without, as the Autoconf packaging recommended them from this same
  # package. A Recommends rather than a Depends because none of it is needed to compile and
  # simulate a model, and because apt quietly skips one it cannot satisfy -- which is what armhf
  # needs, having no simrtcpp. (libomccpp was amd64-only for the same reason; CPack builds the
  # C++ runtime on arm64 as well.)
  #
  # simrtcpp is the C++ simulation runtime, reached with --simCodeTarget=Cpp; omplot is what
  # plot() calls; gnuplot and xsltproc are what the profiling report (--profiling, and the
  # blocks+html debug flag) shells out to. The 1.27.1 list also had libsaxonb-java, which nothing
  # in the sources refers to any more.
  set(_om_deb_version "${CPACK_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE}")
  set(CPACK_DEBIAN_OMC_PACKAGE_RECOMMENDS
      "openmodelica-simrtcpp (= ${_om_deb_version}), openmodelica-omplot (= ${_om_deb_version}), \
gnuplot-nox, xsltproc")

  # OMEdit runs without either, so neither is a Depends: omsens is the sensitivity-analysis plugin
  # it loads if it is there, and omlibrary is the Modelica library cache -- OMEdit opens and edits
  # models without it, but every model that imports Modelica.* needs it, so an OMEdit installed on
  # its own is of little use. The Autoconf packaging pulled the plugin in by having omedit depend
  # on libomsensplugin; the dependency runs the other way here (a plugin needs its host, not the
  # other way round), so a Recommends is what keeps a default install the same.
  set(CPACK_DEBIAN_OMEDIT_PACKAGE_RECOMMENDS
      "openmodelica-omsens (= ${_om_deb_version}), openmodelica-omlibrary (= ${_om_deb_version})")

  # Set the section control field
  # https://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections
  set(CPACK_DEBIAN_PACKAGE_SECTION "math")

  # The documentation is the same on every architecture.
  set(CPACK_DEBIAN_DOC_PACKAGE_ARCHITECTURE "all")
  set(CPACK_DEBIAN_DOC_PACKAGE_SECTION "doc")

elseif(CPACK_GENERATOR STREQUAL "RPM")
  # Options and settings that are specific to RPM packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/rpm.html
  # usage: cpack -G RPM

  # CPack's default for RPM, spelled out: the /usr/local the .deb side uses is in the loader's
  # search path on Debian and Ubuntu but on no Fedora or EL system, where our libraries under
  # /usr/local/lib would then not be found.
  set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")

  # <name>-<version>-<release>.<arch>.rpm, as createrepo and the rpm tools expect. CPack's own
  # name, OpenModelica-<version>-Linux-<component>.rpm, carries neither the package name nor
  # the architecture, and spells the version with the .deb's hyphens rather than ~.
  set(CPACK_RPM_FILE_NAME RPM-DEFAULT)

  # An RPM Version: field may not contain a hyphen -- rpm uses it to separate the version
  # from the release -- so the pre-release and the `git describe` suffix are joined with
  # "~" instead. rpm reads "~" the same way dpkg does, as sorting before the release, so
  # 1.28.0~dev~701~g50d49aa2dd still upgrades to 1.28.0.
  set(CPACK_RPM_PACKAGE_VERSION "@OM_PACKAGE_VERSION_RPM@")

  # Enable component based packaging (omc, omedit, omsimulator, simrtcpp ...)
  # See the file common.cmake for a list of the components.
  set(CPACK_RPM_COMPONENT_INSTALL ON)

  # As for DEB above: the metapackage is "openmodelica", not "openmodelica-meta".
  set(CPACK_RPM_META_PACKAGE_NAME "openmodelica")

  # Every package's Requires, from the components' DEPENDS. CPackRPM has no counterpart to
  # CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS and never reads them, so without this each package
  # ships depending on nothing -- openmodelica-omc not even on openmodelica-simrt. A dependency
  # is named by its own package, so the metapackage's rename is followed rather than assumed;
  # %{version}-%{release} pins one build's packages to each other, as (= version) does for .deb.
  foreach(_om_component IN LISTS CPACK_COMPONENTS_ALL)
    string(TOUPPER "${_om_component}" _om_component_upper)
    set(_om_component_requires "")
    foreach(_om_dependency IN LISTS CPACK_COMPONENT_${_om_component_upper}_DEPENDS)
      string(TOUPPER "${_om_dependency}" _om_dependency_upper)
      if(CPACK_RPM_${_om_dependency_upper}_PACKAGE_NAME)
        set(_om_dependency_package "${CPACK_RPM_${_om_dependency_upper}_PACKAGE_NAME}")
      else()
        set(_om_dependency_package "openmodelica-${_om_dependency}")
      endif()
      list(APPEND _om_component_requires "${_om_dependency_package} = %{version}-%{release}")
    endforeach()
    if(_om_component_requires)
      list(JOIN _om_component_requires ", " CPACK_RPM_${_om_component_upper}_PACKAGE_REQUIRES)
    endif()
  endforeach()

  # The tools omc runs rather than links, which rpmbuild's dependency generator cannot see:
  # CPACK_DEBIAN_OMC_PACKAGE_DEPENDS under RPM names, where build-essential is gcc, gcc-c++ and
  # make and the -dev packages are -devel. The Autoconf spec required these too, bar clang.
  set(_om_omc_tools "clang, cmake, gcc, gcc-c++, make, gcc-gfortran, expat-devel, lapack-devel, zip, unzip")
  if(CPACK_RPM_OMC_PACKAGE_REQUIRES)
    set(CPACK_RPM_OMC_PACKAGE_REQUIRES "${CPACK_RPM_OMC_PACKAGE_REQUIRES}, ${_om_omc_tools}")
  else()
    set(CPACK_RPM_OMC_PACKAGE_REQUIRES "${_om_omc_tools}")
  endif()

  # The same weak dependencies the DEB packages carry above. rpm has no package named
  # gnuplot-nox or xsltproc -- what each distribution calls them differs -- so those two are
  # asked for by the file they provide, which rpm resolves through its file index. Our own
  # packages are pinned with the spec's own %{version}-%{release}, which rpmbuild expands.
  # CPack drops these tags by itself on an rpm too old to support weak dependencies.
  set(CPACK_RPM_OMC_PACKAGE_RECOMMENDS
      "openmodelica-simrtcpp = %{version}-%{release}, openmodelica-omplot = %{version}-%{release}, \
/usr/bin/gnuplot, /usr/bin/xsltproc")
  set(CPACK_RPM_OMEDIT_PACKAGE_RECOMMENDS
      "openmodelica-omsens = %{version}-%{release}, openmodelica-omlibrary = %{version}-%{release}")

  # A short identifier, which is what the tag is for: CPACK_RESOURCE_FILE_LICENSE is the path of
  # the licence file, so rpm -qi printed a path off the build machine. OSMC-PL is what the
  # Autoconf spec declared; the text offers AGPL version 3 as an alternative.
  set(CPACK_RPM_PACKAGE_LICENSE "OSMC-PL")

  # The documentation is the same on every architecture.
  set(CPACK_RPM_DOC_PACKAGE_ARCHITECTURE "noarch")


elseif(CPACK_GENERATOR STREQUAL "productbuild")
  # Options and settings that are specific to macOS productbuild packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/productbuild.html
  # usage: cpack -G productbuild

  set(CPACK_PRODUCTBUILD_IDENTIFIER "org.openmodelica")

elseif(CPACK_GENERATOR STREQUAL "NSIS")
  # Options and settings that are specific to Windows NSIS packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/nsis.html
  # usage: cpack -G NSIS64

  set(CPACK_NSIS_MUI_ICON "@CMAKE_SOURCE_DIR@\\OpenModelica.ico")
  set(CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP "@CMAKE_SOURCE_DIR@\\openmodelica.bmp")
  set(CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP "@CMAKE_SOURCE_DIR@\\openmodelica.bmp")

  set(CPACK_NSIS_HELP_LINK      "https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/")
  set(CPACK_NSIS_URL_INFO_ABOUT "http://openmodelica.org")
  set(CPACK_NSIS_CONTACT        "openmodelica@ida.liu.se")

  # These need a bit more testing and work. The shortcuts do not work yet.
  set(CPACK_CREATE_DESKTOP_LINKS OMEdit)
  set(CPACK_CREATE_DESKTOP_LINKS OMNotebook)
  set(CPACK_CREATE_DESKTOP_LINKS OMShell)

  # Ask to modify path during installation
  set(CPACK_NSIS_MODIFY_PATH ON)

  # Ask to uninstall previous installation if the same version is installed.
  set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)

  # Ask to start OMEdit after installation. right now this says 'Start OpenModelica'.
  # The text at the second command below seems to be ignored for some reason.
  set(CPACK_NSIS_MUI_FINISHPAGE_RUN "OMEdit.exe")
  set(CPACK_NSIS_MUI_FINISHPAGE_RUN_TEXT "Start OpenModelica Connection Editor (OMEdit)")


endif()
