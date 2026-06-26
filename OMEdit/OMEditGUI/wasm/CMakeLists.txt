cmake_minimum_required(VERSION 3.21)

# Qt-for-WebAssembly build of OMEdit. See HANDOFF.md.
# Standalone configure (own scratch dir, NOT a build-* under the repo):
#   source /opt/emsdk/emsdk_env.sh
#   TC=/opt/Qt/6.10.2/wasm_singlethread/lib/cmake/Qt6/qt.toolchain.cmake
#   cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$TC \
#     -DQT_HOST_PATH=/opt/Qt/6.10.2/gcc_64 -S . -B /tmp/omedit-test
project(OMEditQtWasm LANGUAGES C CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_CXX_STANDARD 17)

find_package(Qt6 REQUIRED COMPONENTS
  Widgets PrintSupport Svg Xml Core5Compat Concurrent OpenGL OpenGLWidgets Network
  CorePrivate
  Quick Quick3D Qml QuickWidgets)
qt_standard_project_setup()

# Qt forces -sERROR_ON_UNDEFINED_SYMBOLS=1 via Qt6::Platform; emcc takes the last
# -s flag and interface options come after target_link_options, so appending =0
# here is the only place it wins (lets the dead-feature symbols be deferred imports).
if(TARGET Qt6::Platform)
  set_property(TARGET Qt6::Platform APPEND PROPERTY
    INTERFACE_LINK_OPTIONS -sERROR_ON_UNDEFINED_SYMBOLS=0)
endif()

get_filename_component(OM_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(LIB    ${CMAKE_CURRENT_SOURCE_DIR}/../../OMEditLIB)
set(GUI    ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(OMPLOT ${OM_ROOT}/OMPlot/OMPlot/OMPlotGUI)
set(QWT    ${OM_ROOT}/OMPlot/qwt)
set(SIMRT  ${OM_ROOT}/OMCompiler/SimulationRuntime/c)
# Generated typed OMCInterface; overridden by the integrated build.
set(SCRIPTING_API_QT_DIR "${OM_ROOT}/build-cmake-rust/OMCompiler/Compiler/scripting-api-qt"
    CACHE PATH "Directory of the generated OpenModelicaScriptingAPIQt{.cpp,.h,ABI.h}.")
set(SCRIPTING_API_QT ${SCRIPTING_API_QT_DIR})

# ---- qwt (static) ----
set(USE_QT6 ON CACHE BOOL "" FORCE)
set(QWT_WITH_EXAMPLES OFF CACHE BOOL "" FORCE)
set(OMQWT_LIBRARY_TYPE STATIC)
add_subdirectory(${QWT} ${CMAKE_BINARY_DIR}/qwt)

# ---- OMPlotLib (library only) ----
add_library(OMPlotLib STATIC
  ${OMPLOT}/Plot.cpp ${OMPLOT}/PlotZoomer.cpp ${OMPLOT}/Legend.cpp
  ${OMPLOT}/PlotPanner.cpp ${OMPLOT}/PlotPicker.cpp ${OMPLOT}/PlotGrid.cpp
  ${OMPLOT}/PlotCurve.cpp ${OMPLOT}/PlotWindow.cpp ${OMPLOT}/PlotWindowContainer.cpp
  ${OMPLOT}/PlotMainWindow.cpp ${OMPLOT}/ScaleDraw.cpp ${OMPLOT}/LogScaleEngine.cpp
  ${OMPLOT}/LinearScaleEngine.cpp ${OMPLOT}/resource_omplot.qrc
  ${OMPLOT}/OMPlot.h ${OMPLOT}/PlotZoomer.h ${OMPLOT}/Legend.h ${OMPLOT}/PlotPanner.h
  ${OMPLOT}/PlotPicker.h ${OMPLOT}/PlotGrid.h ${OMPLOT}/PlotCurve.h ${OMPLOT}/PlotWindow.h
  ${OMPLOT}/PlotWindowContainer.h ${OMPLOT}/PlotMainWindow.h ${OMPLOT}/ScaleDraw.h
  ${OMPLOT}/LogScaleEngine.h ${OMPLOT}/LinearScaleEngine.h
  ${SIMRT}/util/read_matlab4.c ${SIMRT}/util/read_csv.c ${SIMRT}/util/libcsv.c
  ${SIMRT}/util/omc_numbers.c
  # TODO: give OMEdit its own copy; reuse the OMNotebook stdio shim for now.
  ${OM_ROOT}/OMNotebook/OMNotebook/OMNotebookGUI/wasm/omc_file_shim.c)
target_compile_definitions(OMPlotLib PRIVATE OMPLOTLIB_MOC_INCLUDE)
target_include_directories(OMPlotLib PUBLIC ${OMPLOT} PRIVATE ${SIMRT})
target_link_libraries(OMPlotLib PUBLIC
  Qt6::Widgets Qt6::PrintSupport Qt6::Svg Qt6::Core5Compat omqwt)

# ---- OMEditLib (static) ----
# Glob the native sources minus the subsystems stubbed on wasm. /generatedfiles/
# is stale checked-in moc/ui/rcc output that AUTOMOC/AUTOUIC/AUTORCC regenerate.
file(GLOB_RECURSE OMEDITLIB_SOURCES ${LIB}/*.cpp)
file(GLOB_RECURSE OMEDITLIB_HEADERS ${LIB}/*.h)
# OMS is compiled (MainWindow constructs OMSProxy at startup; its oms_* externs
# defer). Debugger is excluded: it is GDB-over-QProcess, and MainWindow's debugger
# construction/usage is guarded out under __EMSCRIPTEN__.
set(WASM_EXCLUDE_DIRS
  "/generatedfiles/"
  "/Animation/" "/Debugger/" "/FMI/" "/Git/" "/MCP/" "/CrashReport/"
  "/TransformationalDebugger/" "/Traceability/")
foreach(pat ${WASM_EXCLUDE_DIRS})
  list(FILTER OMEDITLIB_SOURCES EXCLUDE REGEX "${pat}")
  list(FILTER OMEDITLIB_HEADERS EXCLUDE REGEX "${pat}")
endforeach()
# Native-only .cpp (subprocess / OPC-UA); their headers still compile and their
# symbols defer (the features are unavailable on web v1).
set(WASM_EXCLUDE_FILES
  "Simulation/SimulationOutputWidget.cpp"
  "Simulation/OpcUaClient.cpp"
  "OMS/OMSSimulationOutputWidget.cpp")
foreach(f ${WASM_EXCLUDE_FILES})
  list(FILTER OMEDITLIB_SOURCES EXCLUDE REGEX "${f}")
endforeach()

# Generated OMCInterface + its worker bridge (gen_bridge.py turns the ABI header
# into JSON forwarders that define the omc_scripting_*/omc_seq_*/omc_abi_* symbols).
list(APPEND OMEDITLIB_SOURCES ${SCRIPTING_API_QT}/OpenModelicaScriptingAPIQt.cpp)
set_source_files_properties(${SCRIPTING_API_QT}/OpenModelicaScriptingAPIQt.cpp PROPERTIES GENERATED TRUE)
set(OMC_BRIDGE_CPP ${CMAKE_BINARY_DIR}/OpenModelicaScriptingAPIQtBridge.cpp)
add_custom_command(OUTPUT ${OMC_BRIDGE_CPP}
  COMMAND python3 ${CMAKE_CURRENT_SOURCE_DIR}/gen_bridge.py
          ${SCRIPTING_API_QT}/OpenModelicaScriptingAPIQtABI.h ${OMC_BRIDGE_CPP}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/gen_bridge.py
          ${SCRIPTING_API_QT}/OpenModelicaScriptingAPIQtABI.h
  COMMENT "Generating the omc OmcSeq->worker bridge")
list(APPEND OMEDITLIB_SOURCES ${OMC_BRIDGE_CPP})
set_source_files_properties(${OMC_BRIDGE_CPP} PROPERTIES SKIP_AUTOMOC ON)

# ryu number formatting (ryu_hr_tdzp) + wasm startup stubs (wasm_stubs.cpp).
list(APPEND OMEDITLIB_SOURCES
  ${OM_ROOT}/OMCompiler/3rdParty/ryu/ryu/om_format.c
  ${OM_ROOT}/OMCompiler/3rdParty/ryu/ryu/d2s.c
  ${CMAKE_CURRENT_SOURCE_DIR}/wasm_stubs.cpp
  # OMS C API (OMSimulator has no wasm build) + the excluded sim/OMS-sim output
  # widgets' moc-referenced methods: no-op definitions so the app links/loads.
  ${CMAKE_CURRENT_SOURCE_DIR}/oms_stubs.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/sim_widget_stubs.cpp
  # QAbstractFileEngineHandler that serves worker-VFS files to main-thread QFile.
  ${CMAKE_CURRENT_SOURCE_DIR}/worker_vfs_engine.cpp)
set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/worker_vfs_engine.cpp PROPERTIES SKIP_AUTOMOC ON)
# TimeManager drives the result-replay time slider in VariablesWidget. It is the
# one Animation/ source that has no OpenSceneGraph/GL dependency (just rtclock +
# QTimer), so compile it (rtclock entry points are provided by wasm_stubs.cpp)
# rather than guarding its ~40 use sites out.
list(APPEND OMEDITLIB_SOURCES ${LIB}/Animation/TimeManager.cpp)
# 3D animation via Qt Quick 3D (OSG does not build for wasm). The renderer-neutral
# data classes + the Quick 3D backend; the OSG renderer sources (ViewerWidget,
# ExtraShapes, GLWidget/OpenGLWidget, the OSGScene/UpdateVisitor parts of
# Visualization.cpp) stay out via the OMEDIT_ANIMATION_QUICK3D guards. FMU animation
# (VisualizationFMU/FMUWrapper/FMUSettingsDialog) is excluded (no fmilib on wasm).
list(APPEND OMEDITLIB_SOURCES
  ${LIB}/Animation/AbstractVisualizer.cpp
  ${LIB}/Animation/Shape.cpp
  ${LIB}/Animation/Vector.cpp
  ${LIB}/Animation/Visualization.cpp
  ${LIB}/Animation/VisualizationMAT.cpp
  ${LIB}/Animation/VisualizationCSV.cpp
  ${LIB}/Animation/AbstractAnimationWindow.cpp
  ${LIB}/Animation/AnimationWindow.cpp
  ${LIB}/Animation/Quick3D/Quick3DScene.cpp
  ${LIB}/Animation/Quick3D/Quick3DViewerWidget.cpp
  ${LIB}/Animation/Quick3D/Quick3DGeometry.cpp)
set_source_files_properties(
  ${OM_ROOT}/OMCompiler/3rdParty/ryu/ryu/om_format.c
  ${OM_ROOT}/OMCompiler/3rdParty/ryu/ryu/d2s.c
  # ryu parent dir (d2s.c includes "ryu/ryu.h"), scoped so it doesn't rebuild the lib.
  PROPERTIES SKIP_AUTOMOC ON INCLUDE_DIRECTORIES ${OM_ROOT}/OMCompiler/3rdParty/ryu)

add_library(OMEditLib STATIC ${OMEDITLIB_SOURCES} ${OMEDITLIB_HEADERS}
  ${LIB}/resource_omedit.qrc)
# WITHOUT_OSG: no OpenSceneGraph animation. OMC_RUST_ABI: the MMC-free embedding
# ABI (omc_rust_embedding.h). PUBLIC so main.cpp inherits both.
# OMEDIT_ANIMATION_QUICK3D selects the Qt Quick 3D animation backend (over OSG).
# WITHOUT_OSG is intentionally NOT defined: it gates off the animation *features*
# (the New Animation action, addAnimationWindow, simulate-with-animation), which are
# now available through the Quick 3D backend. OSG-renderer code stays out via the
# OMEDIT_ANIMATION_QUICK3D guards in Animation/, not via WITHOUT_OSG.
target_compile_definitions(OMEditLib PUBLIC OMC_RUST_ABI OMEDIT_ANIMATION_QUICK3D)
set(RUST_OMC ${OM_ROOT}/OMCompiler/Compiler/OpenModelica.rs)
# Headers for subsystems whose libs aren't linked on wasm (OMSimulator, antlr/
# OMParser, open62541) compile fine for the static lib; the symbols are deferred.
target_include_directories(OMEditLib PUBLIC ${LIB} ${SCRIPTING_API_QT}
  ${OM_ROOT}/OMEdit
  ${RUST_OMC}/libopenmodelica_compiler/include
  ${OM_ROOT}/OMCompiler/SimulationRuntime/c
  ${OM_ROOT}/OMSimulator/include
  ${OM_ROOT}/OMParser/3rdParty/antlr4/runtime/Cpp/runtime/src
  ${OM_ROOT}/OMParser
  ${OM_ROOT}/OMCompiler/3rdParty/ryu/ryu
  ${OM_ROOT}/OMCompiler/3rdParty/open62541)
target_link_libraries(OMEditLib PUBLIC
  OMPlotLib Qt6::Widgets Qt6::Xml Qt6::PrintSupport Qt6::Svg Qt6::Concurrent
  Qt6::OpenGL Qt6::OpenGLWidgets Qt6::Core5Compat Qt6::Network Qt6::CorePrivate
  # Qt Quick 3D animation backend
  Qt6::Quick Qt6::Quick3D Qt6::Qml Qt6::QuickWidgets)

# ---- OMEdit executable ----
qt_add_executable(OMEdit-qt ${GUI}/main.cpp)
target_link_libraries(OMEdit-qt PRIVATE OMEditLib)
# Static wasm build: the QtQuick/QtQuick3D/QtQml QML plugins must be linked for the
# animation View3D. The scene QML is built from inline strings (QQmlComponent::setData),
# which qmlimportscanner can't see, so a tiny module whose .qml carries the imports
# makes the scanner pull in (and statically register) those plugins.
qt_add_qml_module(OMEdit-qt
  URI OMEditAnimImports
  VERSION 1.0
  QML_FILES qml/AnimImports.qml)
target_link_options(OMEdit-qt PRIVATE
  -sASYNCIFY
  -sASYNCIFY_STACK_SIZE=131072
  -sALLOW_MEMORY_GROWTH=1
  # Only the pre-main-loop reply wait suspends via raw Asyncify. All other waits
  # (worker init included) run post-main-loop through a nested QEventLoop, i.e.
  # Qt's own Asyncify import, so they need not be listed here.
  -sASYNCIFY_IMPORTS=omedit_await_call
  # Dead-feature symbols stay deferred imports that abort if reached
  # (ERROR_ON_UNDEFINED_SYMBOLS=0, set via Qt6::Platform above); everything else links.
  -Wl,--allow-undefined
  -sEXPORTED_RUNTIME_METHODS=UTF8ToString,stringToNewUTF8,FS,lengthBytesUTF8,stringToUTF8)

# -g2 keeps wasm function names in browser traces.
option(OMEDIT_WASM_DEBUG "Build OMEdit-qt with debug function names" ON)
if(OMEDIT_WASM_DEBUG)
  target_link_options(OMEdit-qt PRIVATE -g2)
endif()

# Diagnostic only. -sASSERTIONS makes emscripten print the exact expected-vs-actual
# signature + offending function on a function-pointer-cast trap (instead of the bare
# "function signature mismatch"). Caveat: ASSERTIONS' checkInt32 aborts on Qt's
# NaN-into-int write in QLocalTime (release tolerates it), so an ASSERTIONS build may
# stop there first; keep OFF for normal builds.
option(OMEDIT_WASM_ASSERTIONS "Build OMEdit-qt with -sASSERTIONS (diagnostic)" OFF)
if(OMEDIT_WASM_ASSERTIONS)
  target_link_options(OMEdit-qt PRIVATE -sASSERTIONS=1)
endif()

# Diagnostic/unblock. Routes indirect calls through varargs trampolines so a
# function-pointer call whose pointer type != the call-site type no longer traps
# ("function signature mismatch"). If this clears the post-qt_add_qml_module crash,
# the blocker is a fp-cast signature mismatch (heavy: bigger/slower wasm).
option(OMEDIT_WASM_EMULATE_FP_CASTS "Build OMEdit-qt with -sEMULATE_FUNCTION_POINTER_CASTS (diagnostic)" OFF)
if(OMEDIT_WASM_EMULATE_FP_CASTS)
  target_link_options(OMEdit-qt PRIVATE -sEMULATE_FUNCTION_POINTER_CASTS=1)
endif()
