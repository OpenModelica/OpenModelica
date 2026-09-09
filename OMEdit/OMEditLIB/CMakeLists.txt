# file(GLOB_RECURSE OMEDITLIB_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

# file(GLOB_RECURSE OMEDITLIB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
# set(OMEDITLIB_SOURCES resource_omedit.qrc ${OMEDITLIB_SOURCES})


# This small module (OpenModelica/cmake/modules/Findbinutils.cmake) finds and sets up
# libbfd which is need for providing bactrace support for OMEdit.
# It is required always on MinGW for now. Can be made optional with some changes.
if(MINGW)
  find_package(binutils REQUIRED)
endif()

omc_add_subdirectory(Debugger/Parser)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

set(OMEDITLIB_SOURCES LSP/LSPClient.cpp
                      LSP/LSPFileWatcher.cpp
                      LSP/ModelicaLSPClient.cpp
                      Util/Helper.cpp
                      Util/Utilities.cpp
                      Util/StringHandler.cpp
                      Util/OutputPlainTextEdit.cpp
                      Util/DirectoryOrFileSelector.cpp
                      Util/NavigationManager.cpp
                      Util/NavigationManagerView.cpp
                      MainWindow.cpp
                      LoadCompiledModelDialog.cpp
                      OMC/OMCProxy.cpp
                      Modeling/Model.cpp
                      Modeling/MessagesWidget.cpp
                      Modeling/ItemDelegate.cpp
                      Modeling/LibraryTreeWidget.cpp
                      Modeling/ElementTreeWidget.cpp
                      Modeling/Commands.cpp
                      Modeling/ModelWidgetContainer.cpp
                      Modeling/ModelicaClassDialog.cpp
                      Modeling/FunctionArgumentDialog.cpp
                      Modeling/InstallLibraryDialog.cpp
                      Modeling/QuickInsertWidget.cpp
                      Search/SearchWidget.cpp
                      Options/OptionsDialog.cpp
                      Editors/BaseEditor.cpp
                      Editors/ModelicaEditor.cpp
                      Editors/TransformationsEditor.cpp
                      Editors/TextEditor.cpp
                      Editors/CEditor.cpp
                      Editors/CRMLEditor.cpp
                      Editors/MOSEditor.cpp
                      Editors/OMSimulatorEditor.cpp
                      Editors/MetaModelicaEditor.cpp
                      Editors/HTMLEditor.cpp
                      Plotting/PlotWindowContainer.cpp
                      Element/Element.cpp
                      Annotations/ShapeAnnotation.cpp
                      Element/CornerItem.cpp
                      Annotations/LineAnnotation.cpp
                      Annotations/PolygonAnnotation.cpp
                      Annotations/RectangleAnnotation.cpp
                      Annotations/EllipseAnnotation.cpp
                      Annotations/TextAnnotation.cpp
                      Annotations/BitmapAnnotation.cpp
                      Annotations/DynamicAnnotation.cpp
                      Annotations/BooleanAnnotation.cpp
                      Annotations/PointAnnotation.cpp
                      Annotations/RealAnnotation.cpp
                      Annotations/ColorAnnotation.cpp
                      Annotations/LinePatternAnnotation.cpp
                      Annotations/FillPatternAnnotation.cpp
                      Annotations/PointArrayAnnotation.cpp
                      Annotations/ArrowAnnotation.cpp
                      Annotations/SmoothAnnotation.cpp
                      Annotations/ExtentAnnotation.cpp
                      Annotations/BorderPatternAnnotation.cpp
                      Annotations/EllipseClosureAnnotation.cpp
                      Annotations/StringAnnotation.cpp
                      Annotations/TextAlignmentAnnotation.cpp
                      Annotations/TextStyleAnnotation.cpp
                      Element/ElementProperties.cpp
                      Element/Transformation.cpp
                      Modeling/DocumentationWidget.cpp
                      Simulation/TranslationFlagsWidget.cpp
                      Simulation/SimulationDialog.cpp
                      Simulation/SimulationOutputWidget.cpp
                      Simulation/SimulationOutputHandler.cpp
                      Simulation/OpcUaClient.cpp
                      Simulation/ArchivedSimulationsWidget.cpp
                      FMI/ImportFMUDialog.cpp
                      FMI/ImportFMUModelDescriptionDialog.cpp
                      FMI/FMUExportOutputWidget.cpp
                      Plotting/VariablesWidget.cpp
                      Plotting/DiagramWindow.cpp
                      Options/NotificationsDialog.cpp
                      Annotations/ShapePropertiesDialog.cpp
                      TransformationalDebugger/OMDumpXML.cpp
                      TransformationalDebugger/diff_match_patch.cpp
                      TransformationalDebugger/TransformationsWidget.cpp
                      Debugger/GDB/CommandFactory.cpp
                      Debugger/GDB/GDBAdapter.cpp
                      Debugger/StackFrames/StackFramesWidget.cpp
                      Debugger/Locals/LocalsWidget.cpp
                      Debugger/Locals/ModelicaValue.cpp
                      Debugger/Breakpoints/BreakpointMarker.cpp
                      Debugger/Breakpoints/BreakpointsWidget.cpp
                      Debugger/Breakpoints/BreakpointDialog.cpp
                      Debugger/DebuggerConfigurationsDialog.cpp
                      Debugger/Attach/AttachToProcessDialog.cpp
                      Debugger/Attach/ProcessListModel.cpp
                      CrashReport/backtrace.c
                      CrashReport/GDBBacktrace.cpp
                      CrashReport/CrashReportDialog.cpp
                      CRML/CRMLTranslateAsDialog.cpp
                      CRML/CRMLTranslatorOutputWidget.cpp
                      Git/GitCommands.cpp
                      Git/CommitChangesDialog.cpp
                      Git/RevertCommitsDialog.cpp
                      Git/CleanDialog.cpp
                      OMEditApplication.cpp
                      Traceability/TraceabilityGraphViewWidget.cpp
                      Traceability/TraceabilityInformationURI.cpp
                      OMS/OMSProxy.cpp
                      OMS/OMSModel.cpp
                      OMS/ModelDialog.cpp
                      OMS/ElementPropertiesDialog.cpp
                      OMS/SystemSimulationInformationDialog.cpp
                      OMS/OMSSimulationDialog.cpp
                      OMS/OMSSimulationOutputWidget.cpp
                      Animation/TimeManager.cpp
                      Util/ResourceCache.cpp
                      Util/NetworkAccessManager.cpp
                      Util/GitHubArtifactDownloader.cpp
                      FlatModelica/Expression.cpp
                      FlatModelica/ExpressionFuncs.cpp
                      FlatModelica/Parser.cpp
                      MCP/MCPServer.cpp
                      MCP/MCPToolsSimulation.cpp
                      MCP/MCPToolsDiagram.cpp
                      Search/FindUsageWidget.cpp
                      Animation/OpenGLWidget.cpp
                      Animation/AbstractAnimationWindow.cpp
                      Animation/ViewerWidget.cpp
                      Animation/AnimationWindow.cpp
                      Animation/ExtraShapes.cpp
                      Animation/Visualization.cpp
                      Animation/VisualizationMAT.cpp
                      Animation/VisualizationCSV.cpp
                      Animation/VisualizationFMU.cpp
                      Animation/FMUSettingsDialog.cpp
                      Animation/FMUWrapper.cpp
                      Animation/AbstractVisualizer.cpp
                      Animation/Shape.cpp
                      Animation/Vector.cpp
                      resource_omedit.qrc)

set(OMEDITLIB_HEADERS LSP/LSPClient.h
                      LSP/LSPFileWatcher.h
                      LSP/ModelicaLSPClient.h
                      LSP/LSPProtocol.h
                      Util/Helper.h
                      Util/Utilities.h
                      Util/StringHandler.h
                      Util/OutputPlainTextEdit.h
                      Util/DirectoryOrFileSelector.h
                      Util/NavigationManager.h
                      Util/NavigationManagerView.h
                      MainWindow.h
                      LoadCompiledModelDialog.h
                      OMC/OMCProxy.h
                      Modeling/Model.h
                      Modeling/MessagesWidget.h
                      Modeling/ItemDelegate.h
                      Modeling/LibraryTreeWidget.h
                      Modeling/ElementTreeWidget.h
                      Modeling/Commands.h
                      Modeling/ModelWidgetContainer.h
                      Modeling/ModelicaClassDialog.h
                      Modeling/FunctionArgumentDialog.h
                      Modeling/InstallLibraryDialog.h
                      Modeling/QuickInsertWidget.h
                      Search/SearchWidget.h
                      Options/OptionsDefaults.h
                      Options/OptionsDialog.h
                      Editors/BaseEditor.h
                      Editors/ModelicaEditor.h
                      Editors/TransformationsEditor.h
                      Editors/TextEditor.h
                      Editors/CEditor.h
                      Editors/CRMLEditor.h
                      Editors/MOSEditor.h
                      Editors/OMSimulatorEditor.h
                      Editors/MetaModelicaEditor.h
                      Editors/HTMLEditor.h
                      Plotting/PlotWindowContainer.h
                      Element/Element.h
                      Annotations/ShapeAnnotation.h
                      Element/CornerItem.h
                      Annotations/LineAnnotation.h
                      Annotations/PolygonAnnotation.h
                      Annotations/RectangleAnnotation.h
                      Annotations/EllipseAnnotation.h
                      Annotations/TextAnnotation.h
                      Annotations/BitmapAnnotation.h
                      Annotations/DynamicAnnotation.h
                      Annotations/BooleanAnnotation.h
                      Annotations/PointAnnotation.h
                      Annotations/RealAnnotation.h
                      Annotations/ColorAnnotation.h
                      Annotations/LinePatternAnnotation.h
                      Annotations/FillPatternAnnotation.h
                      Annotations/PointArrayAnnotation.h
                      Annotations/ArrowAnnotation.h
                      Annotations/SmoothAnnotation.h
                      Annotations/ExtentAnnotation.h
                      Annotations/BorderPatternAnnotation.h
                      Annotations/EllipseClosureAnnotation.h
                      Annotations/StringAnnotation.h
                      Annotations/TextAlignmentAnnotation.h
                      Annotations/TextStyleAnnotation.h
                      Element/ElementProperties.h
                      Element/Transformation.h
                      Modeling/DocumentationWidget.h
                      Modeling/qtwebengine_compat.h
                      Simulation/SimulationOptions.h
                      Simulation/TranslationFlagsWidget.h
                      Simulation/SimulationDialog.h
                      Simulation/SimulationOutputWidget.h
                      Simulation/SimulationOutputHandler.h
                      Simulation/OpcUaClient.h
                      Simulation/ArchivedSimulationsWidget.h
                      FMI/ImportFMUDialog.h
                      FMI/ImportFMUModelDescriptionDialog.h
                      FMI/FMUExportOutputWidget.h
                      Plotting/VariablesWidget.h
                      Plotting/DiagramWindow.h
                      Options/NotificationsDialog.h
                      Annotations/ShapePropertiesDialog.h
                      TransformationalDebugger/OMDumpXML.cpp
                      TransformationalDebugger/diff_match_patch.h
                      TransformationalDebugger/TransformationsWidget.h
                      Debugger/GDB/CommandFactory.h
                      Debugger/GDB/GDBAdapter.h
                      Debugger/StackFrames/StackFramesWidget.h
                      Debugger/Locals/LocalsWidget.h
                      Debugger/Locals/ModelicaValue.h
                      Debugger/Breakpoints/BreakpointMarker.h
                      Debugger/Breakpoints/BreakpointsWidget.h
                      Debugger/Breakpoints/BreakpointDialog.h
                      Debugger/DebuggerConfigurationsDialog.h
                      Debugger/Attach/AttachToProcessDialog.h
                      Debugger/Attach/ProcessListModel.h
                      CrashReport/backtrace.h
                      CrashReport/GDBBacktrace.h
                      CrashReport/CrashReportDialog.h
                      CRML/CRMLTranslateAsDialog.h
                      CRML/CRMLTranslatorOptions.h
                      CRML/CRMLTranslatorOutputWidget.h
                      Git/GitCommands.h
                      Git/CommitChangesDialog.h
                      Git/RevertCommitsDialog.h
                      Git/CleanDialog.h
                      OMEditApplication.h
                      Traceability/TraceabilityGraphViewWidget.h
                      Traceability/TraceabilityInformationURI.h
                      OMS/OMSProxy.h
                      OMS/OMSModel.h
                      OMS/ModelDialog.h
                      OMS/ElementPropertiesDialog.h
                      OMS/SystemSimulationInformationDialog.h
                      OMS/OMSSimulationDialog.h
                      OMS/OMSSimulationOutputWidget.h
                      Animation/TimeManager.h
                      Interfaces/InformationInterface.h
                      Interfaces/ModelInterface.h
                      Util/ResourceCache.h
                      Util/NetworkAccessManager.h
                      Util/GitHubArtifactDownloader.h
                      FlatModelica/Expression.h
                      FlatModelica/ExpressionFuncs.h
                      FlatModelica/Parser.h
                      MCP/MCPServer.h
                      MCP/MCPServerPrivate.h
                      Search/FindUsageWidget.h
                      Animation/OpenGLWidget.h
                      Animation/AbstractAnimationWindow.h
                      Animation/ViewerWidget.h
                      Animation/AnimationWindow.h
                      Animation/AnimationUtil.h
                      Animation/ExtraShapes.h
                      Animation/Visualization.h
                      Animation/VisualizationMAT.h
                      Animation/VisualizationCSV.h
                      Animation/VisualizationFMU.h
                      Animation/FMUSettingsDialog.h
                      Animation/FMUWrapper.h
                      Animation/AbstractVisualizer.h
                      Animation/Shape.h
                      Animation/Vector.h
                      Animation/rapidxml.hpp)

set(TS_FILES Resources/nls/OMEdit_de.ts
             Resources/nls/OMEdit_es.ts
             Resources/nls/OMEdit_fr.ts
             Resources/nls/OMEdit_it.ts
             Resources/nls/OMEdit_ja.ts
             Resources/nls/OMEdit_ro.ts
             Resources/nls/OMEdit_ru.ts
             Resources/nls/OMEdit_sv.ts
             Resources/nls/OMEdit_zh_CN.ts)

# Add the translation files.
find_package(Qt${OM_QT_MAJOR_VERSION} REQUIRED COMPONENTS LinguistTools)
# Create the output folder, lrelease doesn't do it automatically.
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Resources/nls)
set_source_files_properties(${TS_FILES} PROPERTIES OUTPUT_LOCATION "Resources/nls")
if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  qt_add_translation(OMEDITLIB_TRANSLATIONS ${TS_FILES})
else()
  qt5_add_translation(OMEDITLIB_TRANSLATIONS ${TS_FILES})
endif()

# Generated by the compiler build (C or Rust) into OMC_SCRIPTING_API_QT_DIR.
set(OMEDITLIB_HEADERS ${OMEDITLIB_HEADERS} ${OMC_SCRIPTING_API_QT_DIR}/OpenModelicaScriptingAPIQt.h)
set(OMEDITLIB_SOURCES ${OMEDITLIB_SOURCES} ${OMC_SCRIPTING_API_QT_DIR}/OpenModelicaScriptingAPIQt.cpp)
# Even though these are outputs of CMake custom commands, cmake fails to automatically recognize them as generated.
# My guess is that the directory difference is confusing it. So maunally mark them as generated.
set_source_files_properties(${OMC_SCRIPTING_API_QT_DIR}/OpenModelicaScriptingAPIQt.cpp GENERATED)
set_source_files_properties(${OMC_SCRIPTING_API_QT_DIR}/OpenModelicaScriptingAPIQt.h GENERATED)

# Quick 3D backend: ViewerWidget/ExtraShapes/OpenGLWidget have unguarded osg includes,
# so swap them for the Quick 3D sources (the shared Visualization* sources keep their
# osg parts behind OMEDIT_ANIMATION_QUICK3D guards). Mirrors the wasm source set.
if(OM_OMEDIT_ANIMATION_QUICK3D)
  list(REMOVE_ITEM OMEDITLIB_SOURCES
       Animation/ViewerWidget.cpp Animation/ExtraShapes.cpp Animation/OpenGLWidget.cpp)
  list(REMOVE_ITEM OMEDITLIB_HEADERS
       Animation/ViewerWidget.h Animation/ExtraShapes.h Animation/OpenGLWidget.h)
  list(APPEND OMEDITLIB_SOURCES
       Animation/Quick3D/Quick3DScene.cpp Animation/Quick3D/Quick3DViewerWidget.cpp
       Animation/Quick3D/Quick3DGeometry.cpp)
  list(APPEND OMEDITLIB_HEADERS
       Animation/Quick3D/Quick3DScene.h Animation/Quick3D/Quick3DViewerWidget.h
       Animation/Quick3D/Quick3DGeometry.h)
endif()

add_library(OMEditLib STATIC ${OMEDITLIB_SOURCES} ${OMEDITLIB_HEADERS} ${OMEDITLIB_TRANSLATIONS})

# Wait for the generated Qt API (rust_codegen); AUTOGEN_TARGET_DEPENDS so AUTOMOC waits too.
# In the prebuilt GUI-only build (RUST_OMC_PREBUILT_CDYLIB) there is no codegen target —
# the Qt sources are supplied ready-made — so only wire the dependency when it exists.
if(OM_OMC_ENABLE_RUST AND TARGET rust_codegen)
  add_dependencies(OMEditLib rust_codegen)
  set_property(TARGET OMEditLib APPEND PROPERTY AUTOGEN_TARGET_DEPENDS rust_codegen)
endif()

target_include_directories(OMEditLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
if(NOT OM_OMEDIT_ANIMATION_QUICK3D)
  # OpenSceneGraph does not provide imported targets yet. Add includes manually.
  target_include_directories(OMEditLib PUBLIC ${OPENSCENEGRAPH_INCLUDE_DIRS})
endif()

# qmake adds -DUNICODE by defult (As far as I can gather).
# So add it for CMake as well to avoid having to modify the code.
if(WIN32)
  # NOMINMAX: windows.h's min/max macros otherwise break std::numeric_limits<>::max() etc.
  target_compile_definitions(OMEditLib PRIVATE UNICODE NOMINMAX)
endif()

if(OM_ENABLE_ENCRYPTION)
  target_compile_definitions(OMEditLib PRIVATE OM_ENABLE_ENCRYPTION)
endif()

target_link_libraries(OMEditLib PUBLIC omedit::config)
target_link_libraries(OMEditLib PUBLIC OMParser)
target_link_libraries(OMEditLib PUBLIC omedit::debugger::parser)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Xml)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Widgets)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::PrintSupport)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::OpenGL)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Network)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Svg)

target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::WebEngineWidgets)

target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::OpenGL)
if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::OpenGLWidgets)
endif ()
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Network)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Svg)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Core5Compat)
endif ()

if (Qt${OM_QT_MAJOR_VERSION}HttpServer_FOUND)
  target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::HttpServer)
endif ()

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
  # Qt6::Svg is a prebuilt system shared library on Linux that itself needs the
  # system libz.so.1 (SVGZ/gzip decompression - the undefined 'inflateEnd'
  # symbol). OMSimulator/3rdParty/CMakeLists.txt defines ZLIB::ZLIB as an alias
  # for our in-tree *static* zlib (zlibstatic) so libzip's find_package(ZLIB)
  # resolves without a system zlib; since OMSimulator is processed before
  # OMEdit in the top-level build, that pre-existing ZLIB::ZLIB target makes
  # Qt6's own find_dependency(ZLIB) (triggered by find_package(Qt6 ... Svg) in
  # OMEdit/CMakeLists.txt) silently reuse it too (CMake's bundled FindZLIB.cmake
  # guards with if(NOT TARGET ZLIB::ZLIB)), so Qt6::Svg never gets linked
  # against the real system libz.so.1 it needs. Link it explicitly instead of
  # relying on ZLIB::ZLIB, which two different consumers need to mean two
  # different things here.
  find_library(OM_SYSTEM_ZLIB_LIB NAMES z)

  if (OM_SYSTEM_ZLIB_LIB)
    target_link_libraries(OMEditLib PUBLIC ${OM_SYSTEM_ZLIB_LIB})
  else ()
    message(WARNING
      "Could not find the system zlib (libz.so.1). "
      "Qt6::Svg may fail to link due to unresolved inflateEnd.")
  endif ()
endif ()

target_link_libraries(OMEditLib PUBLIC omc::3rd::opcua)
target_link_libraries(OMEditLib PUBLIC omc::3rd::simdjson)
target_link_libraries(OMEditLib PUBLIC omc::3rd::libzmq)
target_link_libraries(OMEditLib PUBLIC OMPlotLib)
target_link_libraries(OMEditLib PUBLIC OpenModelicaCompiler)
if(OM_OMEDIT_ANIMATION_QUICK3D)
  target_compile_definitions(OMEditLib PUBLIC OMEDIT_ANIMATION_QUICK3D)
  target_link_libraries(OMEditLib PUBLIC
    Qt${OM_QT_MAJOR_VERSION}::Quick Qt${OM_QT_MAJOR_VERSION}::Quick3D
    Qt${OM_QT_MAJOR_VERSION}::Qml Qt${OM_QT_MAJOR_VERSION}::QuickWidgets)
else()
  target_link_libraries(OMEditLib PUBLIC ${OPENSCENEGRAPH_LIBRARIES})
endif()
target_link_libraries(OMEditLib PUBLIC OpenGL::GL)

# Silence OpenGL deprecation warnings on macOS
if(APPLE)
  target_compile_definitions(OMEditLib PRIVATE GL_SILENCE_DEPRECATION)
endif()

if(MINGW)
  target_link_libraries(OMEditLib PUBLIC binutils::bfd)
  target_link_libraries(OMEditLib PUBLIC zlib)
endif()

target_include_directories(OMEditLib PUBLIC ${OMC_SCRIPTING_API_QT_DIR})

# Install the translation files
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/Resources/nls
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omedit
        FILES_MATCHING PATTERN "*.qm")

# Modelica language server shipped with OMEdit.
#
# The build downloads the standalone server for the target platform from the
# modelica-language-server release named by MODELICA_LS_VERSION and installs it
# beside OMEdit's translations, in <datarootdir>/omedit/ls/modelica. It brings
# its own runtime, so nothing else has to be installed to use it -- but it does
# not embed the tree-sitter grammar, so the two .wasm files are installed with
# it and must stay in the same directory.
#
# With *Server Executable* left empty on the Language Server options page OMEdit
# runs this server. The user can still download another release from that page,
# or point *Server Executable* at a server of their own; neither touches what is
# installed here.
#
# Escape hatches:
#   MODELICA_LS_DIR                     install an already-built server instead
#                                       of downloading one, e.g. when developing
#                                       against an unreleased version. Also the
#                                       way to build without network access.
#   OM_OMEDIT_BUNDLE_LANGUAGE_SERVER=OFF   ship no server at all.
option(OM_OMEDIT_BUNDLE_LANGUAGE_SERVER
       "Install the Modelica language server with OMEdit" ON)
set(MODELICA_LS_VERSION "0.3.3"
    CACHE STRING "modelica-language-server release to install, and the one the options page offers to download")
set(MODELICA_LS_DIR ""
    CACHE PATH "Directory holding an already-built modelica-language-server. Installed instead of downloading a release.")

# The options page offers this version for download, so it names the release
# OMEdit is tested with rather than always taking the newest one.
target_compile_definitions(OMEditLib PRIVATE MODELICA_LS_VERSION="${MODELICA_LS_VERSION}")

# Beside Resources/nls above. findBundledServer() looks here through
# <prefix>/share/omedit, which holds on Windows too: OMEdit.exe lives in bin/,
# so bin/../share/omedit resolves to the same place. OMEditGUI stages the same
# files next to the built executable, for running without installing.
#
# One directory per language under ls/, so a server for another language can be
# installed beside this one rather than sharing a directory with it -- the
# servers load runtime files from their own directory by name.
set(MODELICA_LS_INSTALL_DIR ${CMAKE_INSTALL_DATAROOTDIR}/omedit/ls/modelica)

if(WIN32)
  set(MODELICA_LS_EXE_NAME "modelica-language-server.exe")
else()
  set(MODELICA_LS_EXE_NAME "modelica-language-server")
endif()

if(MODELICA_LS_DIR)
  # A locally built server: the standalone binary and the two WASM files, which
  # must stay together. All three are installed, so all three must be present --
  # a configure that checked only the binary reported success and then failed at
  # install time.
  if(EXISTS "${MODELICA_LS_DIR}/${MODELICA_LS_EXE_NAME}"
     AND EXISTS "${MODELICA_LS_DIR}/tree-sitter-modelica.wasm"
     AND EXISTS "${MODELICA_LS_DIR}/web-tree-sitter.wasm")
    # PROGRAMS rather than FILES: the server has to be executable once installed.
    install(PROGRAMS "${MODELICA_LS_DIR}/${MODELICA_LS_EXE_NAME}"
            DESTINATION ${MODELICA_LS_INSTALL_DIR})
    install(FILES "${MODELICA_LS_DIR}/tree-sitter-modelica.wasm"
                  "${MODELICA_LS_DIR}/web-tree-sitter.wasm"
            DESTINATION ${MODELICA_LS_INSTALL_DIR})
    # Also handed to OMEditGUI, which puts them beside the built executable so a
    # build-tree OMEdit finds a server without being installed first.
    set(MODELICA_LS_STAGE_FILES "${MODELICA_LS_DIR}/tree-sitter-modelica.wasm;${MODELICA_LS_DIR}/web-tree-sitter.wasm" PARENT_SCOPE)
    set(MODELICA_LS_STAGE_EXE "${MODELICA_LS_DIR}/${MODELICA_LS_EXE_NAME}" PARENT_SCOPE)
    set(MODELICA_LS_STAGE_EXE_NAME "${MODELICA_LS_EXE_NAME}" PARENT_SCOPE)
    message(STATUS "Modelica language server: installing from ${MODELICA_LS_DIR}")
  else()
    message(WARNING "MODELICA_LS_DIR=${MODELICA_LS_DIR} does not contain ${MODELICA_LS_EXE_NAME} "
                    "and both WASM files - OMEdit will be installed without a language server")
  endif()
elseif(OM_OMEDIT_BUNDLE_LANGUAGE_SERVER)
  # Standalone build for the target platform. The release publishes one per
  # platform; there is no universal macOS binary, so a cross build picks the
  # asset for CMAKE_SYSTEM_*, not for the host.
  #
  # Bumping MODELICA_LS_VERSION means replacing every hash below. They are the
  # digests GitHub reports for the release assets, so they can be regenerated
  # rather than recomputed by hand:
  #
  #   gh api repos/OpenModelica/modelica-language-server/releases/tags/v<version> \
  #     --jq '.assets[] | select(.name | test("^modelica-language-server-(linux|macos|windows)"))
  #           | "\(.name)\t\(.digest)"'
  #
  set(_ls_asset "")
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
      set(_ls_asset "modelica-language-server-linux-arm64")
      set(_ls_sha256 "933936fec0c69ede57352e968fa04e4d20c77b056acc26efc67975698ca8623d")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
      set(_ls_asset "modelica-language-server-linux-x64")
      set(_ls_sha256 "5fa18d4444c68518a6ca3e91b31c65340c0cbe01751e940061f05072c3706eca")
    endif()
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
      set(_ls_asset "modelica-language-server-macos-arm64")
      set(_ls_sha256 "349c37f8da4a61706f799bd14d561db19aaca00c7394f61099cd79a5ba5441ca")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
      set(_ls_asset "modelica-language-server-macos-x64")
      set(_ls_sha256 "9b7abb1375c764cf86013ee7c8f20661e8add3d80ff8575c61c1a9be3ca87532")
    endif()
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # Only a 64-bit Windows build is published. CMAKE_SIZEOF_VOID_P is empty
    # until a compiler has been probed, so it only vetoes when it is set.
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$"
       AND (NOT CMAKE_SIZEOF_VOID_P OR CMAKE_SIZEOF_VOID_P EQUAL 8))
      set(_ls_asset "modelica-language-server-windows-x64.exe")
      set(_ls_sha256 "3622e8d68aa791dd45c17032f307df58991e33a2e9eac09a0fa483f3425fa5dc")
    endif()
  endif()

  # The hashes above belong to one release. Asking for another version still
  # works, unverified, rather than failing on a hash that cannot match.
  if(NOT MODELICA_LS_VERSION STREQUAL "0.3.3")
    set(_ls_sha256 "")
  endif()

  if(NOT _ls_asset)
    message(STATUS "Modelica language server: no standalone build published for "
                   "${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR} - OMEdit will be "
                   "installed without one, and can download or be pointed at a server at runtime")
  else()
    # The standalone build does not embed the tree-sitter grammar or its
    # runtime; it loads both from beside the executable. Without them the server
    # starts and answers initialize, but with no capabilities, and returns
    # nothing for hover and go to definition -- it aborts on
    # "failed to asynchronously prepare wasm". So all three files are downloaded
    # and installed together. The WASM assets are platform independent.
    set(_ls_assets
        "${_ls_asset}|${_ls_sha256}"
        "tree-sitter-modelica.wasm|fb9e1f0c33288fc301f50bff88bad28ebf2f79365b23482855a1a9e756c78e56"
        "web-tree-sitter.wasm|e8cddb21e0d899ff8613925742f6475838068a0d1b2405faa7087c08151ee3a2")

    # Keyed by version so bumping MODELICA_LS_VERSION re-downloads rather than
    # reusing stale files.
    set(_ls_cache "${CMAKE_BINARY_DIR}/downloads/modelica-language-server/${MODELICA_LS_VERSION}")
    set(_ls_have_all TRUE)
    foreach(_ls_entry ${_ls_assets})
      string(REPLACE "|" ";" _ls_parts "${_ls_entry}")
      list(GET _ls_parts 0 _ls_name)
      # An unpinned version leaves the platform asset's hash empty, which makes
      # the split one element long.
      set(_ls_hash "")
      list(LENGTH _ls_parts _ls_nparts)
      if(_ls_nparts GREATER 1)
        list(GET _ls_parts 1 _ls_hash)
      endif()
      set(_ls_file "${_ls_cache}/${_ls_name}")
      if(NOT EXISTS "${_ls_file}")
        set(_ls_url "https://github.com/OpenModelica/modelica-language-server/releases/download/v${MODELICA_LS_VERSION}/${_ls_name}")
        if(_ls_hash)
          message(STATUS "Modelica language server: downloading ${_ls_name} (v${MODELICA_LS_VERSION})…")
          file(DOWNLOAD "${_ls_url}" "${_ls_file}" EXPECTED_HASH SHA256=${_ls_hash}
               TLS_VERIFY ON SHOW_PROGRESS STATUS _ls_dl)
        else()
          message(STATUS "Modelica language server: downloading ${_ls_name} (v${MODELICA_LS_VERSION}, unverified)…")
          file(DOWNLOAD "${_ls_url}" "${_ls_file}" TLS_VERIFY ON SHOW_PROGRESS STATUS _ls_dl)
        endif()
        list(GET _ls_dl 0 _ls_dl_code)
        if(NOT _ls_dl_code EQUAL 0)
          file(REMOVE "${_ls_file}")
          set(_ls_have_all FALSE)
          message(WARNING "Failed to download ${_ls_name} (${_ls_dl})")
        endif()
      endif()
    endforeach()

    if(_ls_have_all)
      # PROGRAMS rather than FILES: the server has to be executable once
      # installed. The WASM files are read, not run.
      install(PROGRAMS "${_ls_cache}/${_ls_asset}"
              DESTINATION ${MODELICA_LS_INSTALL_DIR}
              RENAME ${MODELICA_LS_EXE_NAME})
      install(FILES "${_ls_cache}/tree-sitter-modelica.wasm"
                    "${_ls_cache}/web-tree-sitter.wasm"
              DESTINATION ${MODELICA_LS_INSTALL_DIR})
      # Also handed to OMEditGUI, which puts them beside the built executable so
      # a build-tree OMEdit finds a server without being installed first. The
      # binary is renamed there too, so pass the name it must end up with.
      set(MODELICA_LS_STAGE_FILES "${_ls_cache}/tree-sitter-modelica.wasm;${_ls_cache}/web-tree-sitter.wasm" PARENT_SCOPE)
      set(MODELICA_LS_STAGE_EXE "${_ls_cache}/${_ls_asset}" PARENT_SCOPE)
      set(MODELICA_LS_STAGE_EXE_NAME "${MODELICA_LS_EXE_NAME}" PARENT_SCOPE)
      message(STATUS "Modelica language server: installing ${_ls_asset} and its WASM files into ${MODELICA_LS_INSTALL_DIR}")
    else()
      # Not fatal: a build without network access still produces a working
      # OMEdit, and the user can download a server from the options page.
      message(WARNING "Modelica language server not downloaded - OMEdit will be installed without "
                      "one. Set OM_OMEDIT_BUNDLE_LANGUAGE_SERVER=OFF to skip this, or "
                      "MODELICA_LS_DIR to install a local build.")
    endif()
  endif()
endif()

# Same check the client makes at run time, made here instead so a bundle that
# would be silently useless is caught while building rather than by a user
# wondering why hover does nothing. It should never fire -- both branches above
# install all three files or none -- so it is an assertion, not a policy.
#
# A warning rather than an error, matching ModelicaLSPClient::missingRuntimeFiles:
# a future server may embed the grammar, and that must not fail the install.
if(MODELICA_LS_DIR OR OM_OMEDIT_BUNDLE_LANGUAGE_SERVER)
  install(CODE "
    set(_ls_dir \"\${CMAKE_INSTALL_PREFIX}/${MODELICA_LS_INSTALL_DIR}\")
    file(GLOB _ls_present \"\${_ls_dir}/*\")
    if(_ls_present)
      foreach(_ls_needed tree-sitter-modelica.wasm web-tree-sitter.wasm)
        if(NOT EXISTS \"\${_ls_dir}/\${_ls_needed}\")
          message(WARNING \"Modelica language server installed without \${_ls_needed}. \"
                          \"It will start but report no hover or go to definition results.\")
        endif()
      endforeach()
    endif()
  ")
endif()
