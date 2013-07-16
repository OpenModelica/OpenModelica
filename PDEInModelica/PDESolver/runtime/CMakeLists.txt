INCLUDE_DIRECTORIES(../models)
LINK_DIRECTORIES(../models)
ADD_LIBRARY(runtime PDESolver.cpp PDESolver.h schemes.cpp schemes.h data.cpp data.h)

