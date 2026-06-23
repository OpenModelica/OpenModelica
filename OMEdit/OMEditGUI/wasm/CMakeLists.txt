cmake_minimum_required(VERSION 3.21)

# Standalone Qt-for-WebAssembly build of OMEdit. See HANDOFF.md for the full plan.
#
# *** WORK IN PROGRESS — does not link yet. ***
# This scaffold configures the proven pieces (qwt + OMPlotLib, copied from the
# OMNotebook wasm build) and an OMEditLib static target globbed from the native
# sources MINUS the Emscripten-hostile subsystems (Animation/OSG, Debugger/GDB,
# Git, MCP/HttpServer, OMS, FMI, CrashReport). Its purpose is to start surfacing
# compile errors for the guard grind (HANDOFF stages 3-4). The omc OmcSeq->worker
# bridge (HANDOFF "omc bridge") and the per-file __EMSCRIPTEN__ guards are still
# TODO, so the link stage will not succeed until those land.
#
# Configure (own scratch dir, NOT a build-* under the repo):
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
  Widgets PrintSupport Svg Xml Core5Compat Concurrent OpenGL OpenGLWidgets Network)
qt_standard_project_setup()

get_filename_component(OM_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(LIB    ${CMAKE_CURRENT_SOURCE_DIR}/../../OMEditLIB)
set(GUI    ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(OMPLOT ${OM_ROOT}/OMPlot/OMPlot/OMPlotGUI)
set(QWT    ${OM_ROOT}/OMPlot/qwt)
set(SIMRT  ${OM_ROOT}/OMCompiler/SimulationRuntime/c)
# Generated typed OMCInterface (OmcSeq ABI variant). Produced by mmtorust's
# scripting_api_qt pass; this path is the native-ABI build output for now.
set(SCRIPTING_API_QT ${OM_ROOT}/build-cmake-rust/OMCompiler/Compiler/scripting-api-qt)

# ---- qwt (static) ----
set(USE_QT6 ON CACHE BOOL "" FORCE)
set(QWT_WITH_EXAMPLES OFF CACHE BOOL "" FORCE)
set(OMQWT_LIBRARY_TYPE STATIC)
add_subdirectory(${QWT} ${CMAKE_BINARY_DIR}/qwt)

# ---- OMPlotLib (library only) — proven from the OMNotebook wasm build ----
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
# Scaffold: glob the native sources, then drop the subsystems stubbed on wasm.
# Replace with an explicit, guarded source list as the grind progresses.
file(GLOB_RECURSE OMEDITLIB_SOURCES ${LIB}/*.cpp)
file(GLOB_RECURSE OMEDITLIB_HEADERS ${LIB}/*.h)
# /generatedfiles/ holds stale pre-generated moc/ui/rcc output checked into the
# tree; AUTOMOC/AUTOUIC/AUTORCC regenerate them, so never compile the stale ones.
set(WASM_EXCLUDE_DIRS
  "/generatedfiles/"
  "/Animation/" "/Debugger/" "/OMS/" "/FMI/" "/Git/" "/MCP/" "/CrashReport/"
  "/TransformationalDebugger/" "/Traceability/")
foreach(pat ${WASM_EXCLUDE_DIRS})
  list(FILTER OMEDITLIB_SOURCES EXCLUDE REGEX "${pat}")
  list(FILTER OMEDITLIB_HEADERS EXCLUDE REGEX "${pat}")
endforeach()
# Pure native-only driver .cpp (subprocess / OPC-UA). Their headers still compile
# (QProcess paths guarded under QT_CONFIG(process)); the driver bodies get rewired
# to the omc worker later, so don't compile them now.
set(WASM_EXCLUDE_FILES
  "Simulation/SimulationOutputWidget.cpp"
  "Simulation/OpcUaClient.cpp")
foreach(f ${WASM_EXCLUDE_FILES})
  list(FILTER OMEDITLIB_SOURCES EXCLUDE REGEX "${f}")
endforeach()

# Generated typed interface (OmcSeq ABI). The matching omc_scripting_*/omc_seq_*/
# omc_abi_* symbols + omc_abi_call worker round-trip are the bridge TODO.
list(APPEND OMEDITLIB_SOURCES ${SCRIPTING_API_QT}/OpenModelicaScriptingAPIQt.cpp)
set_source_files_properties(${SCRIPTING_API_QT}/OpenModelicaScriptingAPIQt.cpp PROPERTIES GENERATED TRUE)

add_library(OMEditLib STATIC ${OMEDITLIB_SOURCES} ${OMEDITLIB_HEADERS}
  ${LIB}/resource_omedit.qrc)
# WITHOUT_OSG: OMEdit's maintained "no OpenSceneGraph animation" build flag
# (no osg on wasm). Guards the Animation includes/usages across MainWindow,
# PlotWindowContainer, SimulationDialog, ModelWidgetContainer, LibraryTreeWidget.
target_compile_definitions(OMEditLib PRIVATE OMC_RUST_ABI WITHOUT_OSG)
# omc_rust_embedding.h (self-contained threadData_t/MMC-free ABI) + the benign
# omc runtime metadata headers it pulls in.
set(RUST_OMC ${OM_ROOT}/OMCompiler/Compiler/OpenModelica.rs)
target_include_directories(OMEditLib PUBLIC ${LIB} ${SCRIPTING_API_QT}
  ${OM_ROOT}/OMEdit  # omedit_config.h (version defines)
  ${RUST_OMC}/libopenmodelica_compiler/include
  ${OM_ROOT}/OMCompiler/SimulationRuntime/c
  # OMSimulator C API header is declarations-only (compiles fine); the oms_*
  # implementation is stubbed at link (no OMSimulator on wasm v1).
  ${OM_ROOT}/OMSimulator/include
  # antlr4 C++ runtime + the generated Modelica lexer/parser headers
  # (OMParser/modelicaLexer.h) for FlatModelica/Parser.cpp. The OMParser lib is
  # not linked on wasm yet; the headers suffice for the static-lib compile.
  ${OM_ROOT}/OMParser/3rdParty/antlr4/runtime/Cpp/runtime/src
  ${OM_ROOT}/OMParser
  # ryu om_format.h (number formatting), included as "om_format.h".
  ${OM_ROOT}/OMCompiler/3rdParty/ryu/ryu
  # open62541 (OPC-UA) header for OpcUaClient — declarations only; the lib is not
  # linked on wasm (interactive simulation is unavailable), but as a STATIC lib
  # OMEditLib only needs the header to compile, not the symbols.
  ${OM_ROOT}/OMCompiler/3rdParty/open62541)
target_link_libraries(OMEditLib PUBLIC
  OMPlotLib Qt6::Widgets Qt6::Xml Qt6::PrintSupport Qt6::Svg Qt6::Concurrent
  Qt6::OpenGL Qt6::OpenGLWidgets Qt6::Core5Compat Qt6::Network)

# ---- OMEdit executable ----
qt_add_executable(OMEdit-qt ${GUI}/main.cpp)
target_link_libraries(OMEdit-qt PRIVATE OMEditLib)
target_link_options(OMEdit-qt PRIVATE
  -sASYNCIFY
  -sASYNCIFY_STACK_SIZE=131072
  -sALLOW_MEMORY_GROWTH=1
  # The single import the OmcSeq bridge suspends on (HANDOFF "omc bridge").
  -sASYNCIFY_IMPORTS=__omc_abi_call
  -sEXPORTED_RUNTIME_METHODS=UTF8ToString,stringToNewUTF8,FS)
