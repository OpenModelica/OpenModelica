


# We have our own module for this. CMake does not provide one yet.
find_package(Readline REQUIRED)

set(OMSHELL_TERMINAL_SOURCES src/mosh.cpp
                             src/omcinteractiveenvironment.cpp
                             src/options.cpp)

add_executable(OMShell-terminal ${OMSHELL_TERMINAL_SOURCES})

target_link_libraries(OMShell-terminal PRIVATE OpenModelicaCompiler)
target_link_libraries(OMShell-terminal PRIVATE Readline::Readline)

# This one belongs in its own component. It does not have anything to do
# with OMShell (GUI) and should be installable separately.
install(TARGETS OMShell-terminal
        COMPONENT omshellterminal)
