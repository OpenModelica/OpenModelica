
find_package(curl REQUIRED)
find_package(Intl REQUIRED)
find_package(Iconv REQUIRED)
# find_package(ZLIB REQUIRED)

set(OMC_RUNTIIME_SOURCES Error_omc.cpp Print_omc.c ErrorMessage.cpp
                            System_omc Lapack_omc.cpp Settings_omc.cpp
                            UnitParserExt_omc.cpp unitparser.cpp
                            IOStreamExt_omc.cpp Socket_omc.c
                            ZeroMQ_omc.c getMemorySize.c OMSimulator_omc.c
                            is_utf8.c om_curl.c om_unzip.c
                            ptolemyio_omc.cpp SimulationResults_omc.c
                            systemimplmisc.cpp
                            )

add_library(omcruntime STATIC ${OMC_RUNTIIME_SOURCES})
add_library(omc::compiler::runtime ALIAS omcruntime)
target_compile_features(omcruntime PRIVATE cxx_std_11)

target_link_libraries(omcruntime PUBLIC curl)
target_link_libraries(omcruntime PUBLIC Intl)
target_link_libraries(omcruntime PUBLIC iconv)
target_link_libraries(omcruntime PUBLIC omc::3rd::lpsolve55)
target_link_libraries(omcruntime PUBLIC OpenModelicaRuntimeC)
target_link_libraries(omcruntime PUBLIC omc::3rd::libzmq)
target_link_libraries(omcruntime PUBLIC omc::3rd::FMIL::minizip) # We use the minizip lib from 3rdParty/FMIL
# target_link_libraries(omcruntime PUBLIC omc::3rd::gc)

target_include_directories(omcruntime PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_include_directories(omcruntime PRIVATE ${SimulationRuntimeC_SOURCE_DIR}) #for openmodelica.h :/
target_include_directories(omcruntime PRIVATE ${OMCompiler_SOURCE_DIR}) #for revision.h

target_include_directories(omcruntime PRIVATE ${OMCompiler_SOURCE_DIR}/Compiler) #for OpenModelicaBootstrappingHeader.h :/
