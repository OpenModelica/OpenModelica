
# get all files in directory dir
FILE(GLOB ALL_MO *.mo)
FILE(GLOB ALL_MOS *.mos)
FILE(GLOB ALL_ONB *.onb)
FILE(GLOB ALL_C *.c)
FILE(GLOB ALL_H *.h)

SET(DOCS ${ALL_MO} ${ALL_MOS} ${ALL_ONB} ${ALL_C} ${ALL_H})
INSTALL(FILES ${DOCS} DESTINATION testmodels)
