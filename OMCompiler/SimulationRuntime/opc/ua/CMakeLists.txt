cmake_minimum_required(VERSION 3.14)
project(omopcua)


add_library(omopcua STATIC)
target_sources(omopcua PRIVATE omc_opc_ua.c)

target_link_libraries(omopcua PRIVATE omc::3rd::opcua)

install(TARGETS omopcua)
