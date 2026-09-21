# add_custom_command's JOB_SERVER_AWARE is CMake 3.28+. Older CMake does not
# recognise the keyword and folds both words into the preceding keyword's
# arguments instead -- after WORKING_DIRECTORY that silently yields a working
# directory of `TRUE`. Expand this in its place.
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.28)
  set(OMC_JOB_SERVER_AWARE JOB_SERVER_AWARE TRUE)
else()
  set(OMC_JOB_SERVER_AWARE "")
endif()
