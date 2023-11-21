# Qt Widgets for Technical Applications
# available at http://www.http://qwt.sourceforge.net/
#
# The module defines the following variables:
#  QWT_FOUND - the system has Qwt
#  QWT_INCLUDE_DIR - where to find qwt_plot.h
#  QWT_INCLUDE_DIRS - qwt includes
#  QWT_LIBRARY - where to find the Qwt library
#  QWT_LIBRARIES - aditional libraries
#  QWT_MAJOR_VERSION - major version
#  QWT_MINOR_VERSION - minor version
#  QWT_PATCH_VERSION - patch version
#  QWT_VERSION_STRING - version (ex. 5.2.1)
#  QWT_ROOT_DIR - root dir (ex. /usr/local)

#=============================================================================
# Copyright 2010-2023, Julien Schueller
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies, 
# either expressed or implied, of the FreeBSD Project.
#=============================================================================

find_path (QWT_INCLUDE_DIR
  NAMES qwt_plot.h
  HINTS ${QT_INCLUDE_DIR}
  PATH_SUFFIXES qwt qwt6 qt${QT_DEFAULT_MAJOR_VERSION}/qwt qt${QT_DEFAULT_MAJOR_VERSION}/qwt6
)

set (QWT_INCLUDE_DIRS ${QWT_INCLUDE_DIR})

# version
set (_VERSION_FILE ${QWT_INCLUDE_DIR}/qwt_global.h)
if (EXISTS ${_VERSION_FILE})
  file (STRINGS ${_VERSION_FILE} _VERSION_LINE REGEX "define[ ]+QWT_VERSION_STR")
  if (_VERSION_LINE)
    string (REGEX REPLACE ".*define[ ]+QWT_VERSION_STR[ ]+\"(.*)\".*" "\\1" QWT_VERSION_STRING "${_VERSION_LINE}")
    string (REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\1" QWT_MAJOR_VERSION "${QWT_VERSION_STRING}")
    string (REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\2" QWT_MINOR_VERSION "${QWT_VERSION_STRING}")
    string (REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\3" QWT_PATCH_VERSION "${QWT_VERSION_STRING}")
  endif ()
endif ()


# check version
set (_QWT_VERSION_MATCH TRUE)
if (Qwt_FIND_VERSION AND QWT_VERSION_STRING)
  if (Qwt_FIND_VERSION_EXACT)
    if (NOT Qwt_FIND_VERSION VERSION_EQUAL QWT_VERSION_STRING)
      set (_QWT_VERSION_MATCH FALSE)
    endif ()
  else ()
    if (QWT_VERSION_STRING VERSION_LESS Qwt_FIND_VERSION)
      set (_QWT_VERSION_MATCH FALSE)
    endif ()
  endif ()
endif ()


find_library (QWT_LIBRARY
  NAMES qwt qwt-qt${QT_DEFAULT_MAJOR_VERSION}
  HINTS ${QT_LIBRARY_DIR}
)

set (QWT_LIBRARIES ${QWT_LIBRARY})


# try to guess root dir from include dir
if (QWT_INCLUDE_DIR)
  string (REGEX REPLACE "(.*)/include.*" "\\1" QWT_ROOT_DIR ${QWT_INCLUDE_DIR})
# try to guess root dir from library dir
elseif (QWT_LIBRARY)
  string (REGEX REPLACE "(.*)/lib[/|32|64].*" "\\1" QWT_ROOT_DIR ${QWT_LIBRARY})
endif ()


# handle the QUIETLY and REQUIRED arguments
include (FindPackageHandleStandardArgs)
find_package_handle_standard_args (Qwt
  REQUIRED_VARS QWT_LIBRARY QWT_INCLUDE_DIR _QWT_VERSION_MATCH
  VERSION_VAR QWT_VERSION_STRING)

mark_as_advanced (
  QWT_LIBRARY
  QWT_LIBRARIES
  QWT_INCLUDE_DIR
  QWT_INCLUDE_DIRS
  QWT_MAJOR_VERSION
  QWT_MINOR_VERSION
  QWT_PATCH_VERSION
  QWT_VERSION_STRING
  QWT_ROOT_DIR
)
