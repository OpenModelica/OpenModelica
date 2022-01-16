

set(OMSHELLLIB_SOURCES commandcompletion.cpp
                       omcinteractiveenvironment.cpp
                       oms.cpp
                       oms.qrc)

set(OMSHELLLIB_HEADERS commandcompletion.h
                       omcinteractiveenvironment.h
                       oms.h)


add_library(OMShellLib SHARED ${OMSHELLLIB_SOURCES} ${OMSHELLLIB_HEADERS})
target_compile_definitions(OMShellLib PRIVATE OMSHELLLIB_MOC_INCLUDE)

target_link_libraries(OMShellLib PUBLIC Qt5::Xml)
target_link_libraries(OMShellLib PUBLIC Qt5::Widgets)
target_link_libraries(OMShellLib PUBLIC Qt5::PrintSupport)
target_link_libraries(OMShellLib PUBLIC Qt5::WebKitWidgets)
target_link_libraries(OMShellLib PUBLIC OpenModelicaCompiler)

target_link_options(OMShellLib PRIVATE -Wl,--no-undefined)


add_executable(OMShell WIN32 MACOSX_BUNDLE main.cpp rc_omshell.rc)
target_link_libraries(OMShell PRIVATE OMShellLib)

install(TARGETS OMShellLib)
install(TARGETS OMShell)

install(FILES commands.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omshell)
