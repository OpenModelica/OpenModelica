
# Includes
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
INCLUDE_DIRECTORIES($ENV{OMDEV}/tools/rml/include/plain)

IF(USE_MODPAR)
  SET(OBJECTS  Codegen.cpp 
	TaskMerging.cpp
	TaskGraph.cpp 
	MergeRule.cpp 
	SingleChildMerge.cpp 
	DuplicateParentMerge.cpp 
	MergeAllParents.cpp 
	MergeSiblings.cpp 
	Schedule.cpp 
	TaskGraphExt.cpp 
	solvers.cpp)
ELSE(USE_MODPAR)
  SET(OBJECTS  TaskGraphExt_stub.cpp)
ENDIF(USE_MODPAR)

#add_definitions(/Ob2 /Ox /O2 /Ot /Oy /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /FD /EHsc /MT /W3 /nologo /c /TP /wd4311 /wd4312)
add_definitions(/MT)
ADD_LIBRARY(libmodpar ${OBJECTS})

