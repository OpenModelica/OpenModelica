cmake_minimum_required (VERSION 2.6)

project(${MathName})
# add the solver default implementation library
add_library(${MathName} SHARED ArrayOperations.cpp  )


install (TARGETS ${MathName} DESTINATION lib/omc)
install (FILES Functions.h
         ArrayOperations.h
      DESTINATION include/omc/cpp/Math/Implementation)
install (FILES ../Interfaces/ILapack.h
      DESTINATION include/omc/cpp/Math/Interfaces)
	  