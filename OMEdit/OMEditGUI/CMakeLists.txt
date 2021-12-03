

add_executable(OMEdit main.cpp rc_omedit.rc)

target_link_libraries(OMEdit PRIVATE OMEditLib)

install(TARGETS OMEdit)
