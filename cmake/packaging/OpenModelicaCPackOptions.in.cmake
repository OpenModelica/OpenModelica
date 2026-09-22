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


## Package names #################################################################################
# omc, omedit, omplot, ... -- the names the Autoconf packaging used, not the
# openmodelica-<component> that CPack derives from the project name.
#
# This is an upgrade path, not a preference. apt upgrades a package by name; it has no way to
# guess that a differently named one supersedes it. A Debian or Ubuntu system carrying 1.27.1's
# omc would keep it for ever if what we published were called openmodelica-omc, and the user
# would be left on the last Autoconf release without ever being told. The same names are used for
# the RPMs, so that a package is called the same thing whichever format it ships in.
#
# Set before either generator's block, because everything else that names a package reads these:
# CPackDeb's get_component_package_name(), and so the .deb file names and the inter-package
# Depends generated from the components' DEPENDS; and the Requires loop in the RPM block below.
#
# A component whose package is not simply its own name is set first, and the loop then leaves it
# alone:
#   * meta, whose package is openmodelica -- what the install instructions tell people to ask
#     for, and not the "openmodelica-meta" its component name would give.
#   * omshellterminal, whose package has always been omshell-terminal.
#   * doc, which components.cmake does not currently pack. A bare "doc" is far too general a name
#     to let a loop invent, and openmodelica-doc is what its source package was called.
if(CPACK_GENERATOR MATCHES "^(DEB|RPM)$")
  foreach(_om_format IN ITEMS DEBIAN RPM)
    set(CPACK_${_om_format}_META_PACKAGE_NAME "openmodelica")
    set(CPACK_${_om_format}_OMSHELLTERMINAL_PACKAGE_NAME "omshell-terminal")
    set(CPACK_${_om_format}_DOC_PACKAGE_NAME "openmodelica-doc")
    foreach(_om_component IN LISTS CPACK_COMPONENTS_ALL)
      string(TOUPPER "${_om_component}" _om_component_upper)
      if(NOT CPACK_${_om_format}_${_om_component_upper}_PACKAGE_NAME)
        set(CPACK_${_om_format}_${_om_component_upper}_PACKAGE_NAME "${_om_component}")
      endif()
    endforeach()
  endforeach()
endif()


## Package Generator specific variables. ##########################################################################################

if(CPACK_GENERATOR STREQUAL "DEB")
  # Options and settings that are specific to Debian packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/deb.html
  # usage: cpack -G DEB

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
      "simrtcpp (= ${_om_deb_version}), omplot (= ${_om_deb_version}), \
gnuplot-nox, xsltproc")

  # OMEdit runs without either, so neither is a Depends: omsens is the sensitivity-analysis plugin
  # it loads if it is there, and omlibrary is the Modelica library cache -- OMEdit opens and edits
  # models without it, but every model that imports Modelica.* needs it, so an OMEdit installed on
  # its own is of little use. The Autoconf packaging pulled the plugin in by having omedit depend
  # on libomsensplugin; the dependency runs the other way here (a plugin needs its host, not the
  # other way round), so a Recommends is what keeps a default install the same.
  set(CPACK_DEBIAN_OMEDIT_PACKAGE_RECOMMENDS
      "omsens (= ${_om_deb_version}), omlibrary (= ${_om_deb_version})")

  ## The packages of the old layout ###############################################################
  # The Autoconf packaging split the libraries and the architecture-independent files into
  # packages of their own -- libomc, omc-common, libomcsimulation and the rest. This packaging
  # has no such split: what they held is inside omc, simrt, omplot and so on. Renaming the
  # packages was enough for the ones whose name survived; without what follows, nothing would
  # supersede these nine and an upgraded system would keep them installed for ever.
  #
  # Three fields:
  #   Replaces  lets this package own files the old one owns. There is in fact no overlap (the
  #             old packages install under /usr and these under /usr/local), but Replaces is
  #             also half of the idiom below, and dpkg wants it alongside Conflicts.
  #   Conflicts is what actually gets the old package removed. Replaces on its own only permits
  #             overwriting; it never uninstalls anything.
  #   Provides  keeps anything that still depends on the old name satisfiable while that happens.
  #
  # The Provides carry a version, and they have to. The old packages depend on each other with
  # version constraints -- libomc-dev wants `libomc (<< 20000)`, omedit wants
  # `libomc (>= <the nightly it was built from>)` -- and an *unversioned* Provides satisfies no
  # versioned dependency at all. With one, removing libomc leaves libomc-dev unsatisfiable, so
  # apt has to remove libomc-dev too; when it cannot (see the -dev note below) it gives up and
  # holds omc back, and with omc everything that depends on it. A versioned Provides satisfies
  # those constraints instead, and the removals stop cascading.
  #
  # It does not satisfy everything: 1.27.1's omc wants `libomc (= 1.27.1-1)` exactly, which no
  # Provides at a newer version can meet. That is harmless -- that omc is itself upgraded in the
  # same transaction -- but it is the reason this cannot be relied on alone.
  #
  # Debian names, so this is the DEB block only: the RPM side never had them. Its spec built one
  # openmodelica-<branch> package under /opt, not a set of component packages.
  #
  # A component this build did not produce supersedes nothing, the loop walking only
  # CPACK_COMPONENTS_ALL. That is the right way round: on armhf there is no simrtcpp, and there
  # was no libomccpp to replace either, and apt acts on a claim to replace a package whether or
  # not anything here supplies what it held.
  #
  # The old library packages, which nothing installs on purpose: apt pulled them in as
  # dependencies, so they are marked automatic and apt is willing to remove them to satisfy a
  # Conflicts. All three fields, and they are gone after the upgrade.
  set(_om_superseded_omc         "omc-common" "libomc")
  set(_om_superseded_simrt       "libomcsimulation")
  set(_om_superseded_simrtcpp    "libomccpp")
  set(_om_superseded_omplot      "libomplot")
  set(_om_superseded_omsimulator "libomsimulator")
  set(_om_superseded_omsens      "libomsensplugin")

  ## The -dev packages of the old layout: superseded, but deliberately not conflicted ############
  # libomc-dev and libomplot-dev are the two packages of the old layout that nothing else pulls
  # in -- no package depends on or recommends them, so a machine that has them has them because
  # somebody asked for the headers, and apt has them marked manual.
  #
  # That mark is the whole problem. apt will remove an automatically installed package to
  # satisfy Conflicts; it will not remove a manually installed one. It keeps the conflicting
  # package back instead, silently. With libomc-dev installed, a Conflicts on it does not
  # retire it -- it strands omc at the old version, and with omc every package that depends on
  # it, which is omedit, omnotebook, omshell, drmodelica, drcontrol and the metapackage. Ten
  # packages held back and no error, on exactly the developer machines most likely to have the
  # headers installed.
  #
  # So these two get Provides and Replaces but no Conflicts. Nothing is lost by that:
  #   * There is no file overlap to protect against. They installed headers and .so symlinks
  #     under /usr/include and /usr/lib; everything here goes under /usr/local. Conflicts was
  #     never resolving a real collision for them, only forcing a removal.
  #   * They do not survive the upgrade regardless. Each depends on its library package
  #     (libomc-dev on libomc, libomplot-dev on libomplot), which *is* conflicted and is removed
  #     in the same transaction. apt takes the -dev package with it rather than leave the
  #     dependency unsatisfied.
  # The upgrade then resolves, which is the point: it is better to leave a stale -dev package
  # behind for `apt autoremove` than to hold the entire tool chain back over it.
  set(_om_superseded_nodelete_omc    "libomc-dev")
  set(_om_superseded_nodelete_omplot "libomplot-dev")

  foreach(_om_component IN LISTS CPACK_COMPONENTS_ALL)
    string(TOUPPER "${_om_component}" _om_component_upper)
    set(_om_superseded_all ${_om_superseded_${_om_component}}
                           ${_om_superseded_nodelete_${_om_component}})
    if(_om_superseded_all)
      # Replaces names the packages bare; Provides pins each to this build's version.
      list(JOIN _om_superseded_all ", " _om_superseded_list)
      set(CPACK_DEBIAN_${_om_component_upper}_PACKAGE_REPLACES "${_om_superseded_list}")
      set(_om_provides_list "")
      foreach(_om_superseded IN LISTS _om_superseded_all)
        list(APPEND _om_provides_list "${_om_superseded} (= ${_om_deb_version})")
      endforeach()
      list(JOIN _om_provides_list ", " _om_provides_joined)
      set(CPACK_DEBIAN_${_om_component_upper}_PACKAGE_PROVIDES "${_om_provides_joined}")
    endif()
    if(_om_superseded_${_om_component})
      list(JOIN _om_superseded_${_om_component} ", " _om_conflicts_list)
      set(CPACK_DEBIAN_${_om_component_upper}_PACKAGE_CONFLICTS "${_om_conflicts_list}")
    endif()
  endforeach()

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

  # Every package's Requires, from the components' DEPENDS. CPackRPM has no counterpart to
  # CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS and never reads them, so without this each package
  # ships depending on nothing -- omc not even on the simrt it cannot run without. A dependency
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
        set(_om_dependency_package "${_om_dependency}")
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
      "simrtcpp = %{version}-%{release}, omplot = %{version}-%{release}, \
/usr/bin/gnuplot, /usr/bin/xsltproc")
  set(CPACK_RPM_OMEDIT_PACKAGE_RECOMMENDS
      "omsens = %{version}-%{release}, omlibrary = %{version}-%{release}")

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
