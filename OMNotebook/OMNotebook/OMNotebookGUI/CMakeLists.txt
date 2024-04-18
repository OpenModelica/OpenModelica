

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

add_executable(OMNotebook WIN32 MACOSX_BUNDLE ${OMNOTEBOOKLIB_SOURCES} ${OMNOTEBOOKLIB_HEADERS} rc_omnotebook.rc ${app_icon_macos})
target_compile_definitions(OMNotebook PRIVATE OMNOTEBOOKLIB_MOC_INCLUDE)

target_include_directories(OMNotebook PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OMNotebook PUBLIC Qt5::Xml)
target_link_libraries(OMNotebook PUBLIC Qt5::Widgets)
target_link_libraries(OMNotebook PUBLIC Qt5::PrintSupport)
target_link_libraries(OMNotebook PUBLIC OMPlotLib)
target_link_libraries(OMNotebook PUBLIC OpenModelicaCompiler)

if(APPLE)
  set_target_properties(OMNotebook PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist)
endif()


install(TARGETS OMNotebook
        BUNDLE DESTINATION ${OM_MACOS_INSTALL_BUNDLEDIR})
install(FILES stylesheet.xml
              commands.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/)
