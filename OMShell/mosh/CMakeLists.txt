


# We have our own module for this. CMake does not provide one yet.
find_package(Readline REQUIRED)

set(OMSHELL_TERMINAL_SOURCES src/mosh.cpp
                             src/omcinteractiveenvironment.cpp
                             src/options.cpp)

add_executable(OMShell-terminal ${OMSHELL_TERMINAL_SOURCES})

target_link_libraries(OMShell-terminal PRIVATE OpenModelicaCompiler)
target_link_libraries(OMShell-terminal PRIVATE Readline::Readline)

install(TARGETS OMShell-terminal)
