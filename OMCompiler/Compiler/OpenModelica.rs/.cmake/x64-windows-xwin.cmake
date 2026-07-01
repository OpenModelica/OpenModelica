# vcpkg overlay triplet: cross-build Windows x64 deps from Linux by chainloading
# the xwin toolchain. Use with --overlay-triplets=<this dir>; see README.
# Leave VCPKG_CMAKE_SYSTEM_NAME unset (empty = desktop Windows; the literal
# "Windows" makes VCPKG_TARGET_IS_WINDOWS false); the toolchain sets it.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/xwin-toolchain.cmake")
set(VCPKG_BUILD_TYPE release)
