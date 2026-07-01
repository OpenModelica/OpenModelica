

set(OMNOTEBOOKLIB_SOURCES  qtapp.cpp
                           cellapplication.cpp
                           cellparserfactory.cpp
                           stylesheet.cpp
                           cellcommandcenter.cpp
                           chaptercountervisitor.cpp
                           omcinteractiveenvironment.cpp
                           textcell.cpp
                           cellcommands.cpp
                           commandcompletion.cpp
                           ModelicaTextHighlighter.cpp
                           textcursorcommands.cpp
                           cell.cpp
                           printervisitor.cpp
                           treeview.cpp
                           cellcursor.cpp
                           puretextvisitor.cpp
                           updategroupcellvisitor.cpp
                           celldocument.cpp
                           inputcell.cpp
                           qcombobox_search.cpp
                           updatelinkvisitor.cpp
                           cellfactory.cpp
                           notebook.cpp
                           xmlparser.cpp
                           searchform.cpp
                           cellgroup.cpp
                           serializingvisitor.cpp
                           graphcell.cpp
                           latexcell.cpp
                           indent.cpp
                           res_qt.qrc)

set(OMNOTEBOOKLIB_HEADERS application.h
                          command.h
                          serializingvisitor.h
                          cellapplication.h
                          commandunit.h
                          stripstring.h
                          cellcommandcenter.h
                          cursorcommands.h
                          omcinteractiveenvironment.h
                          stylesheet.h
                          cellcommands.h
                          cursorposvisitor.h
                          ModelicaTextHighlighter.h
                          cellcursor.h
                          document.h
                          otherdlg.h
                          textcell.h
                          celldocument.h
                          documentview.h
                          parserfactory.h
                          textcursorcommands.h
                          celldocumentview.h
                          factory.h
                          printervisitor.h
                          treeview.h
                          cellfactory.h
                          puretextvisitor.h
                          updategroupcellvisitor.h
                          cellgroup.h
                          imagesizedlg.h
                          qcombobox_search.h
                          updatelinkvisitor.h
                          cell.h
                          inputcelldelegate.h
                          removehighlightervisitor.h
                          visitor.h
                          cellstyle.h
                          inputcell.h
                          replaceallvisitor.h
                          xmlnodename.h
                          chaptercountervisitor.h
                          nbparser.h
                          resource1.h
                          xmlparser.h
                          commandcenter.h
                          notebookcommands.h
                          rule.h
                          commandcompletion.h
                          notebook.h
                          searchform.h
                          graphcell.h
                          latexcell.h
                          indent.h)



if(APPLE)
  set(MACOSX_BUNDLE_ICON_FILE OMNotebook_icon.icns)

  # The following tells CMake where to find and install the file itself.
  set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/Resources/OMNotebook_icon.icns")
  set_source_files_properties(${app_icon_macos} PROPERTIES
       MACOSX_PACKAGE_LOCATION "Resources")
else()
  set(app_icon_macos "")
endif()

add_executable(OMNotebook WIN32 ${OMNOTEBOOKLIB_SOURCES} ${OMNOTEBOOKLIB_HEADERS} rc_omnotebook.rc ${app_icon_macos})
target_compile_definitions(OMNotebook PRIVATE OMNOTEBOOKLIB_MOC_INCLUDE)

target_include_directories(OMNotebook PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OMNotebook PUBLIC Qt${OM_QT_MAJOR_VERSION}::Xml)
target_link_libraries(OMNotebook PUBLIC Qt${OM_QT_MAJOR_VERSION}::Widgets)
target_link_libraries(OMNotebook PUBLIC Qt${OM_QT_MAJOR_VERSION}::PrintSupport)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMNotebook PUBLIC Qt6::Core5Compat)
endif ()

target_link_libraries(OMNotebook PUBLIC OMPlotLib)
target_link_libraries(OMNotebook PUBLIC OpenModelicaCompiler)

omc_install_gui_client(OMNotebook)
if(APPLE)
  set_target_properties(OMNotebook PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist)
endif()

if(MSVC)

else()
  # Enable extra compilation warnings, but disable missing-field-initializers
  # which causes false positives for MMC_TRY_TOP.
  target_compile_options(OMNotebook PRIVATE -Wall -Wextra -Wno-missing-field-initializers -Wsuggest-override)
endif()

if(MINGW)
  # Find windeployqt6
  find_program(WINDEPLOYQT_EXECUTABLE
    NAMES windeployqt windeployqt6
    HINTS "${MSYSTEM_PREFIX_ESCAPED}/bin"
    REQUIRED
  )

  install(CODE "
    message(STATUS \"Running windeployqt6 on OMNotebook...\")
    execute_process(
      COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
        --no-compiler-runtime
        --no-system-d3d-compiler
        --no-quick-import
        --libdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\"
        --translationdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/share/qt6/translations\"
        \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/OMNotebook.exe\"
      RESULT_VARIABLE WINDEPLOYQT_RESULT
      OUTPUT_VARIABLE WINDEPLOYQT_OUTPUT
      ERROR_VARIABLE  WINDEPLOYQT_ERROR
    )
    if(NOT WINDEPLOYQT_RESULT EQUAL 0)
      message(FATAL_ERROR \"windeployqt6 failed:\n\${WINDEPLOYQT_OUTPUT}\n\${WINDEPLOYQT_ERROR}\")
    endif()
    message(STATUS \"windeployqt6 output: \${WINDEPLOYQT_OUTPUT}\")
  ")
endif()

install(FILES stylesheet.xml
              commands.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/)
