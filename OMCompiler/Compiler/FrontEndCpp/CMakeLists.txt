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

set(CC ${CMAKE_C_COMPILER})
set(CXX ${CMAKE_CXX_COMPILER})

if (MSVC)

else()
  target_compile_options(omcfrontendcpp PRIVATE -Wall -Wextra -Wpedantic)
endif()
