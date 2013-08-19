cmake_minimum_required (VERSION 2.6)

project(${MathName})
# add the solver default implementation library
add_library(${MathName} STATIC ArrayOperations.cpp Functions.cpp )


install (TARGETS ${MathName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Math/Functions.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/ArrayOperations.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/Utility.h
      DESTINATION include/omc/cpp/Core/Math)
install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Math/ILapack.h
         ${CMAKE_SOURCE_DIR}/Include/Core/Math/OMAPI.h
         DESTINATION include/omc/cpp/Core/Math)
