# This module respects
# PUGIXML_INSTALL_DIR

# This module defines
# PUGIXML_INCLUDE_DIR
# PUGIXML_LIBRARY
# PUGIXML_FOUND


#-- Clear the public variables
set (PUGIXML_FOUND "NO")

if (NOT PUGIXML_INSTALL_DIR)
    set (PUGIXML_INSTALL_DIR "Not Set" CACHE PATH "PugiXML install directory")
    mark_as_advanced(PUGIXML_INSTALL_DIR)
endif (NOT PUGIXML_INSTALL_DIR)

SET(PUGIXML_INC_SEARCH_DIR      ${PUGIXML_INSTALL_DIR}/include)
SET(PUGIXML_LIBRARY_SEARCH_DIR  ${PUGIXML_INSTALL_DIR}/lib)

# Find Header Files
find_path(PUGIXML_INCLUDE_DIR pugixml.hpp
PATHS ${PUGIXML_INC_SEARCH_DIR})
mark_as_advanced(PUGIXML_INCLUDE_DIR)

# Find library
find_library(PUGIXML_LIBRARY pugixml
PATHS ${PUGIXML_LIBRARY_SEARCH_DIR})

if (PUGIXML_INCLUDE_DIR)
if (PUGIXML_LIBRARY)
    set (PUGIXML_FOUND "YES")
    message(STATUS "Found pugiXML")
endif (PUGIXML_LIBRARY)
endif (PUGIXML_INCLUDE_DIR)

if (NOT PUGIXML_FOUND)
    message("ERROR: PugiXML NOT found! Please set PUGIXML_INSTALL_DIR accordingly.")
    message(STATUS "Looked for PugiXML in ${PUGIXML_INSTALL_DIR}")
    # do only throw fatal, if this pkg is REQUIRED
if (PUGIXML_FIND_REQUIRED)
message(FATAL_ERROR "Could NOT find PUGIXML library.")
endif (PUGIXML_FIND_REQUIRED)
endif (NOT PUGIXML_FOUND)

