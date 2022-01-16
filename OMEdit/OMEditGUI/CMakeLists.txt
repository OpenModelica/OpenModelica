

add_executable(OMEdit WIN32 MACOSX_BUNDLE main.cpp rc_omedit.rc)

target_link_libraries(OMEdit PRIVATE OMEditLib)

install(TARGETS OMEdit)
