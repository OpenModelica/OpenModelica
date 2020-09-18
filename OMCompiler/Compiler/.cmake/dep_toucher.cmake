

file(READ ${REV_DEP_FILE} DEPENDEE_LIST)

foreach(OMC_MM_SOURCE ${DEPENDEE_LIST})
    # message("Touching ${INTERFACE_FILES_DIR}/${OMC_MM_SOURCE}.interface.mo.tmp")
    file(TOUCH_NOCREATE ${INTERFACE_FILES_DIR}/${OMC_MM_SOURCE}.interface.mo.tmp)
endforeach()