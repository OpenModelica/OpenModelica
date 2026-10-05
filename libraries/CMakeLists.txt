# Note that omc needs to be built and INSTALLED before you can add the libs for testing.
# The reason being omc needs to be in a folder **/bin to work. Otherwise it will refuse to run
# Plus it needs to know where find the shared libs it needs. That is structured to work for install.
set(LIBS_DIR_FOR_TESTING ${CMAKE_CURRENT_SOURCE_DIR}/.openmodelica/libraries)
add_custom_target(libs-for-testing
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${LIBS_DIR_FOR_TESTING}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${LIBS_DIR_FOR_TESTING}
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/index.json ${LIBS_DIR_FOR_TESTING}
    COMMAND ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/omc index.mos

    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)


## The Modelica libraries that are shipped with an OpenModelica installation ###########################
# This downloads the libraries listed in install-index.json into a scratch
# directory in the build tree and stages the resulting package cache, i.e. the downloaded archives plus
# install-index.json as the index, in OMLIBRARY_STAGE_DIR. Installing then copies that cache to
# <prefix>/share/omlibrary/cache, which is where omc's package manager looks for it
# (PackageManagement.getInstallationCachePath), so that installPackage() works without network access.
#
# Just like libs-for-testing above this needs an already INSTALLED omc, since omc refuses to run unless
# it lives in a **/bin directory and it needs to find the shared libs it depends on.
#
# install-index.mos uses the current working directory as HOME, so omc downloads to
# <work dir>/.openmodelica/cache and unpacks to <work dir>/.openmodelica/libraries. Only the archives
# are shipped; the unpacked libraries are a byproduct. The download cache is deliberately not cleared
# between runs so that already downloaded archives are reused; see OMLIBRARY_ARCHIVES below for which
# of them end up in the installation.
set(OMLIBRARY_WORK_DIR ${CMAKE_CURRENT_BINARY_DIR}/installing)
set(OMLIBRARY_STAGE_DIR ${CMAKE_CURRENT_BINARY_DIR}/omlibrary)
# The working directory has to exist before the custom commands below are run.
file(MAKE_DIRECTORY ${OMLIBRARY_WORK_DIR})

# The archives to stage, i.e. the file names the "zipfile" urls in install-index.json end with. omc
# keeps everything it has ever downloaded in the working directory, so after a library update the
# superseded archives are still lying there. Picking the ones the index refers to keeps them out of
# the installation instead of shipping tens of megabytes of unreachable packages.
set_property(DIRECTORY APPEND PROPERTY
             CMAKE_CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/install-index.json)
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/install-index.json OMLIBRARY_INDEX)
string(REGEX MATCHALL "\"zipfile\"[ \t]*:[ \t]*\"[^\"]+\"" OMLIBRARY_ZIP_URLS "${OMLIBRARY_INDEX}")
set(OMLIBRARY_ARCHIVES "")
foreach(zip_url IN LISTS OMLIBRARY_ZIP_URLS)
  string(REGEX REPLACE "^.*/" "" archive "${zip_url}")
  string(REGEX REPLACE "\"$" "" archive "${archive}")
  list(APPEND OMLIBRARY_ARCHIVES ${OMLIBRARY_WORK_DIR}/.openmodelica/cache/${archive})
endforeach()
list(REMOVE_DUPLICATES OMLIBRARY_ARCHIVES)

add_custom_target(omlibrary
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${OMLIBRARY_WORK_DIR}/.openmodelica/libraries
    COMMAND ${CMAKE_COMMAND} -E make_directory ${OMLIBRARY_WORK_DIR}/.openmodelica/libraries
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/install-index.json ${OMLIBRARY_WORK_DIR}/.openmodelica/libraries/index.json
    COMMAND ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/omc ${CMAKE_CURRENT_SOURCE_DIR}/install-index.mos

    COMMAND ${CMAKE_COMMAND} -E remove_directory ${OMLIBRARY_STAGE_DIR}/cache
    COMMAND ${CMAKE_COMMAND} -E make_directory ${OMLIBRARY_STAGE_DIR}/cache
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/install-index.json ${OMLIBRARY_STAGE_DIR}/cache/index.json
    COMMAND ${CMAKE_COMMAND} -E copy ${OMLIBRARY_ARCHIVES} ${OMLIBRARY_STAGE_DIR}/cache

    WORKING_DIRECTORY ${OMLIBRARY_WORK_DIR}
    COMMENT "Downloading the Modelica libraries to be shipped with the installation."
)

# The staging directory has to exist at configure time, otherwise the install rule below fails on a
# build in which 'omlibrary' was never built. In that case an empty cache directory is installed.
file(MAKE_DIRECTORY ${OMLIBRARY_STAGE_DIR}/cache)
install(DIRECTORY ${OMLIBRARY_STAGE_DIR}/cache
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omlibrary
    COMPONENT omlibrary)
