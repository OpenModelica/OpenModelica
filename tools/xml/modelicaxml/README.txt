
In order to compile ModelicaXML on Linux or Cygwin you will need:

Antlr v2:
http://www.antlr2.org/download/antlr-2.7.7.tar.gz

Xerces-c:
http://xml.apache.org/xerces-c/
Check your system, it might be that you already have it.
In Cygwin is in:
/usr/include/xercesc
/usr/lib/xerces-c25.dll.a


Edit the apropriate makefiles:
Linux:  Makefile and Makefile_parser
Cygwin: Makefile.cygwin and Makefile_parser.cygwin
and change ANTLR_HOME, CLASSPATH and XERCESC_HOME
to point to the tools you installed above.
Also change the linker libraries i.e.: -lxerces-cVERSION

Build ModelicaXML:
Linux:  make
Cygwin: make -f Makefile.cygwin


Adrian Pop [adrpo@ida.liu.se]
2007-06-12
