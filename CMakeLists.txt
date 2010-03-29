
# get all files in directory dir
FILE(GLOB DOCS *.pdf)
INSTALL(FILES ${DOCS} DESTINATION doc)
