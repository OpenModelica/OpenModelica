INCLUDE_DIRECTORIES(../models)
LINK_DIRECTORIES(../models)
ADD_LIBRARY(runtime PDESolver.cpp PDESolver.h data.cpp data.h)

