

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


add_executable(OMNotebook ${OMNOTEBOOKLIB_SOURCES} ${OMNOTEBOOKLIB_HEADERS} rc_omnotebook.rc)
target_compile_definitions(OMNotebook PRIVATE OMNOTEBOOKLIB_MOC_INCLUDE)

target_include_directories(OMNotebook PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OMNotebook PUBLIC Qt5::Xml)
target_link_libraries(OMNotebook PUBLIC Qt5::Widgets)
target_link_libraries(OMNotebook PUBLIC Qt5::PrintSupport)
target_link_libraries(OMNotebook PUBLIC Qt5::WebKitWidgets)
target_link_libraries(OMNotebook PUBLIC OMPlotLib)
target_link_libraries(OMNotebook PUBLIC OpenModelicaCompiler)

# target_link_options(OMNotebook PRIVATE -Wl,--no-undefined)


# add_executable(OMNotebook qtapp.cpp)
# target_link_libraries(OMNotebook PRIVATE OMNotebookLib)

# install(TARGETS OMNotebookLib)
install(TARGETS OMNotebook)

install(FILES stylesheet.xml
              commands.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/)
