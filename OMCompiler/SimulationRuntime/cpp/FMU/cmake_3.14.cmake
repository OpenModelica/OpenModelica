#####################################################################################################
# OMCppFMU
set(OMC_SIMRT_CPP_FMU_SOURCES FMULogger.cpp)

add_library(OMCppFMU SHARED)
add_library(omc::simrt::cpp::fmu ALIAS OMCppFMU)

target_sources(OMCppFMU PRIVATE ${OMC_SIMRT_CPP_FMU_SOURCES})

target_link_libraries(OMCppFMU PUBLIC omc::simrt::cpp::config)
target_link_libraries(OMCppFMU PUBLIC omc::simrt::cpp::core::utils::extension)

install(TARGETS OMCppFMU)

# OMCppFMU_static
add_library(OMCppFMU_static STATIC)
add_library(omc::simrt::cpp::fmu::static ALIAS OMCppFMU_static)

target_sources(OMCppFMU_static PRIVATE ${OMC_SIMRT_CPP_FMU_SOURCES})

target_compile_definitions(OMCppFMU_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppFMU_static PUBLIC omc::simrt::cpp::config)

install(TARGETS OMCppFMU_static)
##


install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN *.h
)
