set(OMC_FRONTEND_CPP_ABSYN_SOURCES
    Algorithm.cpp
    Annotation.cpp
    Class.cpp
    ClassDef.cpp
    Comment.cpp
    Component.cpp
    ComponentRef.cpp
    ConstrainingClass.cpp
    DefineUnit.cpp
    Element.cpp
    ElementAttributes.cpp
    ElementPrefixes.cpp
    Equation.cpp
    Expression.cpp
    Extends.cpp
    ExternalDecl.cpp
    FunctionArgs.cpp
    FunctionArgsList.cpp
    FunctionArgsIter.cpp
    Import.cpp
    ImportPath.cpp
    Iterator.cpp
    Modifier.cpp
    Operator.cpp
    Statement.cpp
    Subscript.cpp
    TypeSpec.cpp)

add_library(omcfrontendcppabsyn STATIC)
add_library(omc::compiler::frontendcpp::absyn ALIAS omcfrontendcppabsyn)

target_sources(omcfrontendcppabsyn PRIVATE ${OMC_FRONTEND_CPP_ABSYN_SOURCES})

target_include_directories(omcfrontendcppabsyn PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/..)
