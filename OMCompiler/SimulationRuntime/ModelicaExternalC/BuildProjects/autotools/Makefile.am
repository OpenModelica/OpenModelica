lib_LTLIBRARIES = libzlib.la libModelicaExternalC.la libModelicaMatIO.la libModelicaIO.la libModelicaStandardTables.la
libModelicaExternalC_la_SOURCES      = ../../C-Sources/ModelicaFFT.c ../../C-Sources/ModelicaInternal.c ../../C-Sources/ModelicaRandom.c ../../C-Sources/ModelicaStrings.c
libModelicaExternalC_la_LIBADD       = @LIBMATH@
libModelicaIO_la_SOURCES             = ../../C-Sources/ModelicaIO.c
libModelicaIO_la_LIBADD              = libModelicaMatIO.la
libModelicaMatIO_la_SOURCES          = ../../C-Sources/ModelicaMatIO.c ../../C-Sources/snprintf.c
libModelicaStandardTables_la_SOURCES = ../../C-Sources/ModelicaStandardTables.c ../../C-Sources/ModelicaStandardTablesUsertab.c
libModelicaStandardTables_la_LIBADD  = libModelicaMatIO.la @LIBMATH@

# If the OS does not have zlib available, compile it and include it together with libModelicaStandardTables
if INCLUDEZLIB
libzlib_la_SOURCES = ../../C-Sources/zlib/adler32.c ../../C-Sources/zlib/compress.c ../../C-Sources/zlib/crc32.c ../../C-Sources/zlib/deflate.c ../../C-Sources/zlib/gzclose.c ../../C-Sources/zlib/gzlib.c ../../C-Sources/zlib/gzread.c ../../C-Sources/zlib/gzwrite.c ../../C-Sources/zlib/infback.c ../../C-Sources/zlib/inffast.c ../../C-Sources/zlib/inflate.c ../../C-Sources/zlib/inftrees.c ../../C-Sources/zlib/trees.c ../../C-Sources/zlib/uncompr.c ../../C-Sources/zlib/zutil.c
libModelicaMatIO_la_LIBADD           = libzlib.la @LIBZLIB@ @LIBHDF5@
else
libModelicaMatIO_la_LIBADD           = @LIBZLIB@ @LIBHDF5@
endif
libModelicaMatIO_la_LIBADD           = @LIBHDF5@
libzlib_la_LIBADD = @LIBZLIB@
