
# until omc.exe does not work
# OMC Compiler
SET(OMC ${OMCTRUNCHOME}/build/bin/omcd.exe)
MESSAGE(" omc is " ${OMC})

# Test		
add_test (Abs ${OMC} ${CMAKE_CURRENT_SOURCE_DIR}/Abs.mo)