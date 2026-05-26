add_subdirectory(Absyn)

# Libraries
##################################################################################################
set(OMC_FRONTEND_CPP_SOURCES
    Attributes.cpp
    Binding.cpp
    Class.cpp
    ClassNode.cpp
    ClassTree.cpp
    ComplexType.cpp
    Component.cpp
    ComponentNode.cpp
    ComponentRef.cpp
    ConstrainingClass.cpp
    Dimension.cpp
    Import.cpp
    Inst.cpp
    InstNode.cpp
    InstNodeType.cpp
    MetaModelica.cpp
    Modifier.cpp
    NameNode.cpp
    Path.cpp
    Prefixes.cpp
    Restriction.cpp
    SourceInfo.cpp
    Subscript.cpp
    Type.cpp)

# ######################################################################################################################
# Library: omcruntime
add_library(omcfrontendcpp STATIC)
add_library(omc::compiler::frontendcpp ALIAS omcfrontendcpp)

target_sources(omcfrontendcpp PRIVATE ${OMC_FRONTEND_CPP_SOURCES})

target_link_libraries(omcfrontendcpp PUBLIC omc::compiler::frontendcpp::absyn)
target_link_libraries(omcfrontendcpp PUBLIC omc::simrt::runtime)

target_include_directories(omcfrontendcpp PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

if (MSVC)

else()
  target_compile_options(omcfrontendcpp PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Include what you see
# Ensures all C++ files include all used headers, no transient includes
find_program(IWYU_PATH NAMES include-what-you-use iwyu)
message(STATUS "IWYU: ${IWYU_PATH}")
if(IWYU_PATH)
  set(IWYU_COMMAND ${IWYU_PATH} -Xiwyu --no_fwd_decls)
  set_property(TARGET omcfrontendcpp PROPERTY CXX_INCLUDE_WHAT_YOU_USE ${IWYU_PATH})
  set_property(TARGET omcfrontendcppabsyn PROPERTY CXX_INCLUDE_WHAT_YOU_USE ${IWYU_PATH})
endif()
