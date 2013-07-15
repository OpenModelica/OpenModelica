INCLUDE_DIRECTORIES(../runtime)
LINK_DIRECTORIES(../runtime)
ADD_EXECUTABLE(advection advection.c model.h)
TARGET_LINK_LIBRARIES(advection runtime)