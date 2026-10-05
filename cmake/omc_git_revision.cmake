
set(SOURCE_REVISION "unknown")

if (EXISTS ${CMAKE_SOURCE_DIR}/OMVERSION.txt)
  file(READ ${CMAKE_SOURCE_DIR}/OMVERSION.txt SOURCE_REVISION)
  string(STRIP "${SOURCE_REVISION}" SOURCE_REVISION)
else ()
  ## Get the revision info. The version is saved in the variable SOURCE_REVISION
  find_package(Git)
  if(Git_FOUND)
    execute_process(COMMAND
      ${GIT_EXECUTABLE} describe --match "v*.*" --always
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      OUTPUT_VARIABLE SOURCE_REVISION
      ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  endif()
endif ()

# The raw `git describe`, e.g. "v1.28.0-dev-701-g50d49aa2dd". Every version string below
# is a rendering of this one input.
set(SOURCE_REVISION_BASE "${SOURCE_REVISION}")

## Parse the describe #####################################################################
# git describe puts the tag first and appends "-<commits since the tag>-g<hash>" when the
# checkout is not exactly on it, so the tail is peeled off first and what is left is the
# tag: "v<major>.<minor>[.<patch>][-<pre-release>]".
#
# Everything here stays empty if the input is not a version at all -- OMVERSION.txt may
# hold anything, and `git describe --always` falls back to a bare commit hash in a
# repository whose tags are missing (a shallow CI clone, a source export without them).
# The version strings below then fall back to reporting that input verbatim, and
# packaging refuses to run on it (cmake/packaging/OpenModelicaCPackOptions.in.cmake).
set(OM_VERSION_CORE "")        # 1.28.0
set(OM_VERSION_PRERELEASE "")  # dev.701
set(OM_VERSION_BUILD "")       # g50d49aa2dd

string(REGEX REPLACE "^v" "" _om_describe "${SOURCE_REVISION_BASE}")

if(_om_describe MATCHES "^([0-9]+)\\.([0-9]+)")
  # The "-<count>-g<hash>" git describe appends. Anchored at the end, so a pre-release
  # that contains digits and hyphens of its own is not mistaken for it.
  set(_om_commits "")
  set(_om_hash "")
  if(_om_describe MATCHES "^(.+)-([0-9]+)-(g[0-9a-f]+)$")
    set(_om_tag "${CMAKE_MATCH_1}")
    set(_om_commits "${CMAKE_MATCH_2}")
    set(_om_hash "${CMAKE_MATCH_3}")
  else()
    set(_om_tag "${_om_describe}")
  endif()

  # Split the tag into the version core and the pre-release after the first hyphen.
  if(_om_tag MATCHES "^([0-9]+\\.[0-9]+(\\.[0-9]+)?)-(.+)$")
    set(OM_VERSION_CORE "${CMAKE_MATCH_1}")
    set(OM_VERSION_PRERELEASE "${CMAKE_MATCH_3}")
  else()
    set(OM_VERSION_CORE "${_om_tag}")
  endif()

  # SemVer requires all three numbers; a "v1.28" tag would otherwise not be a version.
  if(NOT OM_VERSION_CORE MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
    set(OM_VERSION_CORE "${OM_VERSION_CORE}.0")
  endif()

  # The commit count belongs in the pre-release, where SemVer compares an all-digit
  # identifier numerically, so 1.28.0-dev.701 < 1.28.0-dev.1000 < 1.28.0. As one
  # identifier ("dev-701-g...") it would be compared as ASCII and 1000 would sort first.
  #
  # With no pre-release in the tag there is nothing to count from: commits after a plain
  # v1.27.0 come *after* that release, so calling them 1.27.0-<n> -- which sorts before
  # it -- would be wrong, and the release they precede is not known here. They go in the
  # build metadata instead, which SemVer ignores when comparing.
  if(OM_VERSION_PRERELEASE AND _om_commits)
    set(OM_VERSION_PRERELEASE "${OM_VERSION_PRERELEASE}.${_om_commits}")
  elseif(_om_commits)
    set(OM_VERSION_BUILD "${_om_commits}")
  endif()

  if(_om_hash)
    list(APPEND OM_VERSION_BUILD "${_om_hash}")
  endif()
endif()

## The version omc reports ################################################################
# `omc --version` prints this (CONFIG_REVISION -> CONFIG_VERSION, see OMCompiler/revision.h.in
# and Settings_getVersionNr), and it also goes into the generationTool of every FMU and
# init XML omc writes. A valid SemVer 2.0.0 version, behind the "v" that tags and releases
# have always been named with -- SemVer itself has no opinion on that prefix, it just is
# not part of the version:
#
#   v1.28.0-dev.701+g50d49aa2dd.cmake
#    ^core  ^pre-release  ^build metadata
#
# The build system that produced this omc is the last build-metadata identifier, so it
# does not affect precedence: the same commit built two ways is the same version.
function(omc_semver out_var build_tag)
  set(_build ${OM_VERSION_BUILD} ${build_tag})
  string(REPLACE ";" "." _build "${_build}")
  set(_version "v${OM_VERSION_CORE}")
  if(OM_VERSION_PRERELEASE)
    string(APPEND _version "-${OM_VERSION_PRERELEASE}")
  endif()
  string(APPEND _version "+${_build}")
  set(${out_var} "${_version}" PARENT_SCOPE)
endfunction()

if(OM_VERSION_CORE)
  omc_semver(SOURCE_REVISION "cmake")
  # The Rust omc reports the same version tagged "rust" where this one says "cmake";
  # rust_omc.cmake writes it to the revision file cargo reads.
  omc_semver(SOURCE_REVISION_RUST "rust")
else()
  # Not a version we can parse. Report the input as it came, as this always used to.
  set(SOURCE_REVISION "${SOURCE_REVISION_BASE}-cmake")
  set(SOURCE_REVISION_RUST "${SOURCE_REVISION_BASE}-rust")
endif()

omc_add_to_report(SOURCE_REVISION)

## The version the packages are built with ################################################
# Neither package manager takes the string above: a Debian version has to start with a
# digit, and an RPM Version: field may not contain a hyphen at all -- which rules out both
# the "v" and the SemVer pre-release separator.
#
# Both of them do have their own spelling of "sorts before the release", the "~" that
# dpkg and rpm read the way SemVer reads "-", so the same ordering survives the
# translation. The renderings are the ones the Autoconf/Makefile packaging produced --
# see update-source-repo.py in the apt-build repository -- so that the packages CPack
# builds keep the names the apt and rpm repositories, the scripts that index them and
# everyone's sources.list already use:
#
#   v1.28.0-dev-701-g50d49aa2dd  ->  1.28.0~dev-701-g50d49aa2dd  (Debian, plus a -1 revision)
#                                ->  1.28.0~dev~701~g50d49aa2dd  (RPM)
#
# Note this is the *raw describe* re-punctuated, not the SemVer string re-punctuated: the
# published packages have been named this way for years and an upgrade only happens if the
# new version sorts above the installed one.
set(OM_PACKAGE_VERSION "")
set(OM_PACKAGE_VERSION_RPM "")
set(OM_PACKAGE_VERSION_MAJOR "")
set(OM_PACKAGE_VERSION_MINOR "")
set(OM_PACKAGE_VERSION_PATCH "")

if(OM_VERSION_CORE)
  # Only the tag's own first hyphen is the pre-release separator; the ones git describe
  # appends are not. Splitting at it by hand rather than with a REGEX REPLACE: CMake
  # re-anchors "^" after a replacement, so an anchored pattern goes on matching further
  # into the string and "1.27.0-3-gabcdef1" would come out as "1.27.0~3~gabcdef1".
  set(OM_PACKAGE_VERSION "${_om_describe}")
  string(FIND "${OM_PACKAGE_VERSION}" "-" _om_first_dash)
  if(_om_first_dash GREATER -1)
    string(SUBSTRING "${OM_PACKAGE_VERSION}" 0 ${_om_first_dash} _om_version_head)
    math(EXPR _om_rest_start "${_om_first_dash} + 1")
    string(SUBSTRING "${OM_PACKAGE_VERSION}" ${_om_rest_start} -1 _om_version_rest)
    set(OM_PACKAGE_VERSION "${_om_version_head}~${_om_version_rest}")
  endif()
  string(REPLACE "-" "~" OM_PACKAGE_VERSION_RPM "${OM_PACKAGE_VERSION}")

  # CPack defaults these to 0.1.1 and some generators build paths and registry keys out
  # of them, so give them the real numbers rather than leaving them to be noticed later.
  string(REPLACE "." ";" _om_core_parts "${OM_VERSION_CORE}")
  list(GET _om_core_parts 0 OM_PACKAGE_VERSION_MAJOR)
  list(GET _om_core_parts 1 OM_PACKAGE_VERSION_MINOR)
  list(GET _om_core_parts 2 OM_PACKAGE_VERSION_PATCH)
endif()

omc_add_to_report(OM_PACKAGE_VERSION)
