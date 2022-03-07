

add_executable(OMEdit WIN32 MACOSX_BUNDLE main.cpp rc_omedit.rc)
target_link_libraries(OMEdit PRIVATE OMEditLib)

install(TARGETS OMEdit)


# Install the runtime dependency dlls if we are on MSYS/MinGW.
if(OM_OMEDIT_INSTALL_RUNTIME_DLLS AND MINGW)

  # Escape the environment variable path
  string(REPLACE "\\" "/" OMDEV_ESCAPED $ENV{OMDev})

  # Check if 64 bit
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(MINGWDIR ${OMDEV_ESCAPED}/tools/msys/mingw64/)
  else()
    set(MINGWDIR ${OMDEV_ESCAPED}/tools/msys/mingw32/)
  endif()

  # Install the Qt plugins directories. Note the slash at the end.
  install(DIRECTORY ${MINGWDIR}/share/qt5/plugins/
          TYPE BIN)

  # Install the runtime dlls to the binary folder.
  install(FILES
            ${MINGWDIR}/bin/libbrotlicommon.dll
            ${MINGWDIR}/bin/libbrotlidec.dll
            ${MINGWDIR}/bin/libbz2-1.dll
            ${MINGWDIR}/bin/libcrypto-1_1-x64.dll
            ${MINGWDIR}/bin/libcurl-4.dll
            ${MINGWDIR}/bin/libdouble-conversion.dll
            ${MINGWDIR}/bin/libexpat-1.dll
            ${MINGWDIR}/bin/libfontconfig-1.dll
            ${MINGWDIR}/bin/libfreetype-6.dll
            ${MINGWDIR}/bin/libgcc_s_seh-1.dll
            ${MINGWDIR}/bin/libgfortran-5.dll
            ${MINGWDIR}/bin/libglib-2.0-0.dll
            ${MINGWDIR}/bin/libgraphite2.dll
            ${MINGWDIR}/bin/libharfbuzz-0.dll
            ${MINGWDIR}/bin/libiconv-2.dll
            ${MINGWDIR}/bin/libicudt67.dll
            ${MINGWDIR}/bin/libicuin67.dll
            ${MINGWDIR}/bin/libicuuc67.dll
            ${MINGWDIR}/bin/libidn2-0.dll
            ${MINGWDIR}/bin/libintl-8.dll
            ${MINGWDIR}/bin/libjpeg-8.dll
            ${MINGWDIR}/bin/liblzma-5.dll
            ${MINGWDIR}/bin/libnghttp2-14.dll
            ${MINGWDIR}/bin/libopenblas.dll
            ${MINGWDIR}/bin/libOpenThreads.dll
            ${MINGWDIR}/bin/libosg.dll
            ${MINGWDIR}/bin/libosgDB.dll
            ${MINGWDIR}/bin/libosgGA.dll
            ${MINGWDIR}/bin/libosgText.dll
            ${MINGWDIR}/bin/libosgUtil.dll
            ${MINGWDIR}/bin/libosgViewer.dll
            ${MINGWDIR}/bin/libpcre-1.dll
            ${MINGWDIR}/bin/libpcre2-16-0.dll
            ${MINGWDIR}/bin/libpng16-16.dll
            ${MINGWDIR}/bin/libpsl-5.dll
            ${MINGWDIR}/bin/libquadmath-0.dll
            ${MINGWDIR}/bin/libsqlite3-0.dll
            ${MINGWDIR}/bin/libssh2-1.dll
            ${MINGWDIR}/bin/libssl-1_1-x64.dll
            ${MINGWDIR}/bin/libstdc++-6.dll
            ${MINGWDIR}/bin/libsystre-0.dll
            ${MINGWDIR}/bin/libtre-5.dll
            ${MINGWDIR}/bin/libunistring-2.dll
            ${MINGWDIR}/bin/libwebp-7.dll
            ${MINGWDIR}/bin/libwinpthread-1.dll
            ${MINGWDIR}/bin/libwoff2common.dll
            ${MINGWDIR}/bin/libwoff2dec.dll
            ${MINGWDIR}/bin/libxml2-2.dll
            ${MINGWDIR}/bin/libxslt-1.dll
            ${MINGWDIR}/bin/libzstd.dll
            ${MINGWDIR}/bin/Qt5Core.dll
            ${MINGWDIR}/bin/Qt5Gui.dll
            ${MINGWDIR}/bin/Qt5Multimedia.dll
            ${MINGWDIR}/bin/Qt5MultimediaWidgets.dll
            ${MINGWDIR}/bin/Qt5Network.dll
            ${MINGWDIR}/bin/Qt5OpenGL.dll
            ${MINGWDIR}/bin/Qt5Positioning.dll
            ${MINGWDIR}/bin/Qt5PrintSupport.dll
            ${MINGWDIR}/bin/Qt5Qml.dll
            ${MINGWDIR}/bin/Qt5QmlModels.dll
            ${MINGWDIR}/bin/Qt5Quick.dll
            ${MINGWDIR}/bin/Qt5Sensors.dll
            ${MINGWDIR}/bin/Qt5Svg.dll
            ${MINGWDIR}/bin/Qt5WebChannel.dll
            ${MINGWDIR}/bin/Qt5WebKit.dll
            ${MINGWDIR}/bin/Qt5WebKitWidgets.dll
            ${MINGWDIR}/bin/Qt5Widgets.dll
            ${MINGWDIR}/bin/Qt5Xml.dll
            ${MINGWDIR}/bin/Qt5XmlPatterns.dll
            ${MINGWDIR}/bin/zlib1.dll
          TYPE BIN)
endif()
