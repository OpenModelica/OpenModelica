# This little ugly hack allows us to use linux pthreads and Window's
# PThreads4W library interchangeably without having to put if-else
# checks everywhere.
# It will  use either CMake's own Threads package or, if we are building for MSVC, will use PThreads4W from
# local installation (e.g vcpkg managed)

# If you want to use PThreads no matter the OS (even on Windows like
# 3rdParty/GC and our runtime libraries do) just link to OMCPThreads::OMCPThreads
# anywhere in OpenModelica since this file will be included in the top
# level CMakeLists.txt.


if(MSVC)
  find_package(pthreads CONFIG REQUIRED)
  add_library(OMCPThreads INTERFACE)
  target_link_libraries(OMCPThreads INTERFACE PThreads4W::PThreads4W)
else()
  find_package(Threads)
  add_library(OMCPThreads INTERFACE)
  target_link_libraries(OMCPThreads INTERFACE Threads::Threads)
  target_link_libraries(OMCPThreads INTERFACE ${CMAKE_DL_LIBS})
endif()

target_compile_definitions(OMCPThreads INTERFACE OM_HAVE_PTHREADS)

add_library(OMCPThreads::OMCPThreads ALIAS OMCPThreads)
