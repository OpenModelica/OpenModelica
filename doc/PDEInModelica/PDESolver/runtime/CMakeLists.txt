INCLUDE_DIRECTORIES(../models)
LINK_DIRECTORIES(../models)
ADD_LIBRARY(runtime PDESolver.cpp data.cpp model_data.h runtime_data.h PDESolver.h)

#ADD_LIBRARY(runtime PDESolver.cpp PDESolver.h schemes.cpp schemes.h data.cpp model_data.h runtime_data.h)
