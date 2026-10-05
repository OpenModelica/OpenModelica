# Test 1
add_executable(01_test_assc
  01_test_3x3.cpp
)

target_link_libraries(01_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 01_test_assc COMMAND 01_test_assc)


# Test 2
add_executable(02_test_assc
  02_singular_4x4.cpp
)

target_link_libraries(02_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 02_test_assc COMMAND 02_test_assc)

# Test 3
add_executable(03_test_assc
  03_test_4x4.cpp
)

target_link_libraries(03_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 03_test_assc COMMAND 03_test_assc)

# Test 4
add_executable(04_test_assc
  04_test_10x10.cpp
)

target_link_libraries(04_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 04_test_assc COMMAND 04_test_assc)

# Test 5
add_executable(05_test_assc
  05_singular_10x10.cpp
)

target_link_libraries(05_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 05_test_assc COMMAND 05_test_assc)

# Test 6
add_executable(06_test_assc
  06_test_10x10.cpp
)

target_link_libraries(06_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 06_test_assc COMMAND 06_test_assc)

# Test 7
add_executable(07_test_assc
  07_test_4x4.cpp
)

target_link_libraries(07_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 07_test_assc COMMAND 07_test_assc)

# Test 8
add_executable(08_test_assc
  08_initial_singular_4x4.cpp
)

target_link_libraries(08_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 08_test_assc COMMAND 08_test_assc)

# Test 9
add_executable(09_test_assc
  09_singular_5x5.cpp
)

target_link_libraries(09_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 09_test_assc COMMAND 09_test_assc)

# Test 10
add_executable(10_test_assc
  10_test_5x5.cpp
)

target_link_libraries(10_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 10_test_assc COMMAND 10_test_assc)

# Test 11
add_executable(11_test_assc
  11_test_6x6.cpp
)

target_link_libraries(11_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 11_test_assc COMMAND 11_test_assc)

# Test 12
add_executable(12_test_assc
  12_test_7x7.cpp
)

target_link_libraries(12_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 12_test_assc COMMAND 12_test_assc)

# Test 13
add_executable(13_test_assc
  13_test_8x8.cpp
)

target_link_libraries(13_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 13_test_assc COMMAND 13_test_assc)

# Test 14
add_executable(14_test_assc
  14_test_9x9.cpp
)

target_link_libraries(14_test_assc PRIVATE SimulationRuntimeC OpenModelicaCompiler)
add_test(NAME 14_test_assc COMMAND 14_test_assc)

# Target

add_custom_target(ctestsuite-runtime-assc DEPENDS
  01_test_assc
  02_test_assc
  03_test_assc
  04_test_assc
  05_test_assc
  06_test_assc
  07_test_assc
  08_test_assc
  09_test_assc
  10_test_assc
  11_test_assc
  12_test_assc
  13_test_assc
  14_test_assc
)
