cmake_minimum_required (VERSION 2.6)

project(${MathName})
# add the solver default implementation library
add_library(${MathName} SHARED ArrayOperations.cpp Functions.cpp )


install (TARGETS ${MathName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES Functions.h
         ArrayOperations.h
         Utility.h
      DESTINATION include/omc/cpp/Math/Implementation)
install (FILES ../Interfaces/ILapack.h
         ../Interfaces/OMAPI.h
         DESTINATION include/omc/cpp/Math/Interfaces)
