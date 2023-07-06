

if(APPLE)
  set(MACOSX_BUNDLE_ICON_FILE omedit.icns)

  # The following tells CMake where to find and install the file itself.
  set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/../OMEditLIB/Resources/icons/omedit.icns")
  set_source_files_properties(${app_icon_macos} PROPERTIES
       MACOSX_PACKAGE_LOCATION "Resources")
else()
  set(app_icon_macos "")
endif()

add_executable(OMEdit WIN32 MACOSX_BUNDLE main.cpp rc_omedit.rc ${app_icon_macos})
target_link_libraries(OMEdit PRIVATE OMEditLib)

if(APPLE)
  set_target_properties(OMEdit PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist)
endif()

install(TARGETS OMEdit
        BUNDLE DESTINATION ${OM_MACOS_INSTALL_BUNDLEDIR})


# Install the runtime dependency dlls if we are on MSYS/UCRT64.
if(OM_OMEDIT_INSTALL_RUNTIME_DLLS AND MINGW)

  # Escape the environment variable path
  if(NOT DEFINED ENV{OMDEV})
    message(FATAL_ERROR "Environment variable \"OMDEV\" is not set.")
  endif()
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    string(REPLACE "\\" "/" OMDEV_MSYS_ESCAPED "$ENV{OMDEV}\\tools\\msys")
    set(UCRT_DIR "${OMDEV_MSYS_ESCAPED}/ucrt64")
    message(STATUS "MSYS environment UCRT64: ${OMDEV}\\tools\\msys")
  else()
    message(FATAL_ERROR "No 32-bit version of UCRT available!")
  endif()

  find_path(UCRT_BIN_DIR libbrotlicommon.dll
            PATHS ${UCRT_DIR}/bin
            REQUIRED
            NO_DEFAULT_PATH)
  message(STATUS "UCRT_BIN_DIR: ${UCRT_BIN_DIR}")

  # Install the Qt plugins directories. Note the slash at the end.
  install(DIRECTORY ${UCRT_DIR}/share/qt5/plugins/
          TYPE BIN)

  # Install the runtime dlls to the binary folder.
  # TODO: link to these libraries and use install with runtime dependencies
  install(FILES
            ${UCRT_BIN_DIR}/libbrotlicommon.dll
            ${UCRT_BIN_DIR}/libbrotlidec.dll
            ${UCRT_BIN_DIR}/libbz2-1.dll
            ${UCRT_BIN_DIR}/libcrypto-3-x64.dll  # TODO AHeu: Use find_library
            ${UCRT_BIN_DIR}/libcurl-4.dll
            ${UCRT_BIN_DIR}/libdouble-conversion.dll
            ${UCRT_BIN_DIR}/libexpat-1.dll
            ${UCRT_BIN_DIR}/libfontconfig-1.dll
            ${UCRT_BIN_DIR}/libfreetype-6.dll
            ${UCRT_BIN_DIR}/libgcc_s_seh-1.dll
            ${UCRT_BIN_DIR}/libgfortran-5.dll
            ${UCRT_BIN_DIR}/libglib-2.0-0.dll
            ${UCRT_BIN_DIR}/libgraphite2.dll
            ${UCRT_BIN_DIR}/libharfbuzz-0.dll
            ${UCRT_BIN_DIR}/libiconv-2.dll
            ${UCRT_BIN_DIR}/libicudt72.dll    # TODO AHeu: Use find_library
            ${UCRT_BIN_DIR}/libicuin72.dll
            ${UCRT_BIN_DIR}/libicuuc72.dll
            ${UCRT_BIN_DIR}/libidn2-0.dll
            ${UCRT_BIN_DIR}/libintl-8.dll
            ${UCRT_BIN_DIR}/libjpeg-8.dll
            ${UCRT_BIN_DIR}/liblzma-5.dll
            ${UCRT_BIN_DIR}/libnghttp2-14.dll
            ${UCRT_BIN_DIR}/libopenblas.dll
            ${UCRT_BIN_DIR}/libOpenThreads.dll
            ${UCRT_BIN_DIR}/libosg.dll
            ${UCRT_BIN_DIR}/libosgDB.dll
            ${UCRT_BIN_DIR}/libosgGA.dll
            ${UCRT_BIN_DIR}/libosgText.dll
            ${UCRT_BIN_DIR}/libosgUtil.dll
            ${UCRT_BIN_DIR}/libosgViewer.dll
            #${UCRT_BIN_DIR}/libpcre-1.dll
            ${UCRT_BIN_DIR}/libpcre2-16-0.dll
            ${UCRT_BIN_DIR}/libpng16-16.dll
            ${UCRT_BIN_DIR}/libpsl-5.dll
            ${UCRT_BIN_DIR}/libquadmath-0.dll
            ${UCRT_BIN_DIR}/libsqlite3-0.dll
            ${UCRT_BIN_DIR}/libssh2-1.dll
            ${UCRT_BIN_DIR}/libssl-3-x64.dll    # TODO AHeu: Use find_library
            ${UCRT_BIN_DIR}/libstdc++-6.dll
            ${UCRT_BIN_DIR}/libsystre-0.dll
            ${UCRT_BIN_DIR}/libtre-5.dll
            ${UCRT_BIN_DIR}/libunistring-5.dll
            ${UCRT_BIN_DIR}/libwebp-7.dll
            ${UCRT_BIN_DIR}/libwinpthread-1.dll
            ${UCRT_BIN_DIR}/libwoff2common.dll
            ${UCRT_BIN_DIR}/libwoff2dec.dll
            ${UCRT_BIN_DIR}/libxml2-2.dll
            ${UCRT_BIN_DIR}/libxslt-1.dll
            ${UCRT_BIN_DIR}/libzstd.dll
            ${UCRT_BIN_DIR}/Qt5Core.dll
            ${UCRT_BIN_DIR}/Qt5Gui.dll
            ${UCRT_BIN_DIR}/Qt5Multimedia.dll
            ${UCRT_BIN_DIR}/Qt5MultimediaWidgets.dll
            ${UCRT_BIN_DIR}/Qt5Network.dll
            ${UCRT_BIN_DIR}/Qt5OpenGL.dll
            ${UCRT_BIN_DIR}/Qt5Positioning.dll
            ${UCRT_BIN_DIR}/Qt5PrintSupport.dll
            ${UCRT_BIN_DIR}/Qt5Qml.dll
            ${UCRT_BIN_DIR}/Qt5QmlModels.dll
            ${UCRT_BIN_DIR}/Qt5Quick.dll
            ${UCRT_BIN_DIR}/Qt5Sensors.dll
            ${UCRT_BIN_DIR}/Qt5Svg.dll
            ${UCRT_BIN_DIR}/Qt5WebChannel.dll
            ${UCRT_BIN_DIR}/Qt5WebKit.dll
            ${UCRT_BIN_DIR}/Qt5WebKitWidgets.dll
            ${UCRT_BIN_DIR}/Qt5Widgets.dll
            ${UCRT_BIN_DIR}/Qt5Xml.dll
            ${UCRT_BIN_DIR}/Qt5XmlPatterns.dll
            ${UCRT_BIN_DIR}/zlib1.dll
          TYPE BIN)
endif()
