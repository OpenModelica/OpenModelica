################################################################
# Qwt Widget Library
# Copyright (C) 1997   Josef Wilgen
# Copyright (C) 2002   Uwe Rathmann
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Qwt License, Version 1.0
################################################################

######################################################################
# qmake internal options
######################################################################

CONFIG           += qt
CONFIG           += warn_on
CONFIG           += no_keywords
CONFIG           += silent
CONFIG           -= depend_includepath

# CONFIG += sanitize
# CONFIG += pedantic

# older Qt headers result in tons of warnings with modern compilers and flags
unix:lessThan(QT_MAJOR_VERSION, 5) CONFIG += qtsystemincludes

# CONFIG += c++11

c++11 {
    CONFIG           += strict_c++
}

sanitize {

    CONFIG += sanitizer
    CONFIG += sanitize_address
    #CONFIG *= sanitize_memory
    CONFIG *= sanitize_undefined
}

# Include the generated moc files in the corresponding cpp file
# what increases the compile time significantly

DEFINES += QWT_MOC_INCLUDE=1
# DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000

######################################################################
# release/debug mode
######################################################################

win32 {
    # On Windows you can't mix release and debug libraries.
    # The designer is built in release mode. If you like to use it
    # you need a release version. For your own application development you
    # might need a debug version.
    # Enable debug_and_release + build_all if you want to build both.

    CONFIG           += debug_and_release
    CONFIG           += build_all
}
else {

    CONFIG           += release

    VER_MAJ           = $${QWT_VER_MAJ}
    VER_MIN           = $${QWT_VER_MIN}
    VER_PAT           = $${QWT_VER_PAT}
    VERSION           = $${QWT_VERSION}
}

linux-g++ | linux-g++-64 {
    #CONFIG           += separate_debug_info
    #QMAKE_CXXFLAGS   *= -Wfloat-equal
    #QMAKE_CXXFLAGS   *= -Wshadow
    #QMAKE_CXXFLAGS   *= -Wpointer-arith
    #QMAKE_CXXFLAGS   *= -Wconversion
    #QMAKE_CXXFLAGS   *= -Wsign-compare
    #QMAKE_CXXFLAGS   *= -Wsign-conversion
    #QMAKE_CXXFLAGS   *= -Wlogical-op
    #QMAKE_CXXFLAGS   *= -Werror=format-security
    #QMAKE_CXXFLAGS   *= -std=c++11

    # avoid warnings since gcc9
    # QMAKE_CXXFLAGS   *= -Wno-deprecated-copy

    # when using the gold linker ( Qt < 4.8 ) - might be
    # necessary on non linux systems too
    #QMAKE_LFLAGS += -lrt
}

######################################################################
# paths for building qwt
######################################################################

MOC_DIR      = moc
RCC_DIR      = resources

!debug_and_release {

    # in case of debug_and_release object files
    # are built in the release and debug subdirectories
    OBJECTS_DIR       = obj
}

unix {

    exists( $${QMAKE_LIBDIR_QT}/libomqwt.* ) {

        # On some Linux distributions the Qwt libraries are installed
        # in the same directory as the Qt libraries. Unfortunately
        # qmake always adds QMAKE_LIBDIR_QT at the beginning of the
        # linker path, so that the installed libraries will be
        # used instead of the local ones.

        error( "local build will conflict with $${QMAKE_LIBDIR_QT}/libqwt.*" )
    }
}
