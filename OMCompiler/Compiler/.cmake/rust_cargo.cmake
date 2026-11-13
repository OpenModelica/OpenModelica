# omc_rust_cargo_command(<target-dir> [<dylib-name>]): sets _cargo_cmd,
# _target_flag, _out (the profile output directory) and _env for a release
# cargo build of a library the C/C++ side links. <dylib-name> names a macOS
# dylib after @rpath.
macro(omc_rust_cargo_command _rcc_target_dir)
  # Cross-compiling (RUST_OMC_TARGET): the same drivers as
  # SimulationRuntime/rust/CMakeLists.txt uses for libSimulationRuntimeRust.
  set(_cargo_cmd build)
  set(_target_flag "")
  set(_out ${_rcc_target_dir}/release)
  set(_env ${CMAKE_COMMAND} -E env)
  if(RUST_OMC_TARGET)
    set(_target_flag --target ${RUST_OMC_TARGET})
    set(_out ${_rcc_target_dir}/${RUST_OMC_TARGET}/release)
    if(RUST_OMC_TARGET MATCHES "windows-msvc$")
      set(_cargo_cmd xwin build)
    elseif(RUST_OMC_TARGET MATCHES "apple-darwin$")
      set(_cargo_cmd zigbuild)
      # zig ships no Apple frameworks, so the link needs the SDK (CoreFoundation,
      # via chrono's iana-time-zone).
      list(APPEND _env "SDKROOT=${CMAKE_OSX_SYSROOT}")
      if(${ARGC} GREATER 1)
        # ld64 would otherwise name the dylib by its path in this build tree;
        # @rpath defers that to whoever loads it.
        list(APPEND _env "RUSTFLAGS=-Clink-arg=-Wl,-install_name,@rpath/lib${ARGV1}.dylib")
      endif()
    elseif(RUST_OMC_TARGET MATCHES "linux-gnu$")
      # Plain `cargo build` is right for another Linux architecture, but the
      # linker has to be named or rustc calls the host `cc` -- which rejects the
      # AArch64-only --fix-cortex-a53-843419 that rustc passes for the target.
      string(TOUPPER ${RUST_OMC_TARGET} _res_target_env)
      string(REPLACE "-" "_" _res_target_env ${_res_target_env})
      list(APPEND _env "CARGO_TARGET_${_res_target_env}_LINKER=${CMAKE_C_COMPILER}"
           "PKG_CONFIG_ALLOW_CROSS=1"
           "PKG_CONFIG_LIBDIR=/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/pkgconfig:/usr/share/pkgconfig")
    endif()
  endif()
endmacro()
