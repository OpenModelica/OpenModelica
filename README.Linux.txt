Debian/Ubuntu Compile Cheat Sheet (or read on for the full guide)
=================================================================

Note: $ means run this command as *non-root*. If you must run the command as super-user (you don't), do it under sudo and hope omc did not detect it or your build might fail.
$ sudo su -c "echo deb http://build.openmodelica.org/apt precise nightly >> /etc/apt/sources.list"
$ sudo su -c "echo deb-src http://build.openmodelica.org/apt precise nightly >> /etc/apt/sources.list"
$ sudo apt-get update
$ sudo apt-get build-dep openmodelica
$ svn co https://openmodelica.org/svn/OpenModelica/trunk OpenModelica
$ cd OpenModelica
$ autoconf
$ ./configure --with-omniORB
$ make # or make omc if you only want the omc core and not the qtclients



How to compile on Linux/BSD (all from source)
===================================================

$ ./configure --prefix=/usr/local
$ make
$ sudo make install

But first you need to install dependencies:
    rml+mmc (http://www.ida.liu.se/~pelab/rml/)
        Just grab it from subversion:
        svn co https://openmodelica.org/svn/MetaModelica/trunk mmc
        user: anonymous
        pass: none
    rml needs smlnj: http://www.smlnj.org (working version v110.xx) and/or mlton (mlton.org)
    mico or omniORB:
        omniORB:
          Is well maintained by Linux distributions. This makes it our default choice.
        mico:
          http://www.mico.org - tested on 2.3.11, 2.3.12, 2.3.13
          Note: for newer gcc compilers you might need to add
            #include <limits.h> in orb/fast_array.cc
    java     version > 1.4
    gcc      (tested with most of the versions; 4.4 is preferred over 4.5, 4.6, 4.7 and 4.8 because the newer compilers are *much* slower at compiling code)
    readline & libreadlineX-dev, currently X=5
    liblpsolve: http://www.cs.sunysb.edu/~algorith/implement/lpsolve/distrib/lp_solve_5.5.0.11_source.tar.gz
    sqlite3
OpenModelica uses Qt for plotting functionality and graphical. You will need:
    Qt 4.x.x (http://trolltech.com - >= 4.4.3? 4.6?)
    libqwt
OMOptim uses some packages for its optimization algorithms
    paradisEO (http://paradiseo.gforge.inria.fr/ - tested with 1.3 beta; see the OpenModelica .deb installer for the directory structure or send openmodelica <at> ida.liu.se a listing of the files paradiseo installs to /usr/local/ to have the Makefiles updated). Newer versions of ParadisEO do not work.
Note:
    FreeBSD versions of smlnj/mlton only compile using 32-bit versions of the OS. For 64-bit versions, it might be possible to compile OpenModelica using the bootstrapped compiler (then rml-mmc is not needed).
    The rml-mmc package needs some manual changes, too.

How to compile on Ubuntu Linux (using available binary packages for dependencies)
=================================================================================

You need:
    antlr
        $ sudo apt-get install antlr libantlr-dev
    rml+mmc see above and:
        $ sudo apt-get install libsmlnj-smlnj
        or if you like to use mlton
        $ sudo apt-get install mlton
    java
        you need to install OpenJDK Java runtime or Sun Java runtime
        $ sudo apt-get install openjdk-6-jre
        $ sudo update-java-alternatives -s java-6-openjdk
        or
        $ sudo apt-get install sun-java6-jre
        $ sudo update-java-alternatives -s java-6-sun
    Qt and friends
        you need readline and Qt dev stuff to compile omc and mosh (OMShell)
        $ sudo apt-get install libreadline5-dev libqt4-dev libqtwebkit-dev libqwt5-qt4-dev
    paradiseo
      sudo apt-get install paradiseo (using the OpenModelica repository)
    sqlite3
        $ sudo apt-get install sqlite3 libsqlite3-dev
    liblpsolve55
      You can now use the version from the Ubuntu repository
        $ sudo apt-get install liblpsolve55-dev
        
      Alternatively you can compile lpsolve yourself:
        Download the library:
         http://www.cs.sunysb.edu/~algorith/implement/lpsolve/distrib/lp_solve_5.5.0.11_source.tar.gz
        and unpack it, then call in the top folder: 
        $ make -f Makefile.Linux
        then copy lpsolve55/liblpsolve55.a to /usr/local/lib
      Note that some versions of lp_solve depends on libsuitesparse-dev, which provides -lcolamd.


NOTE:
  We assume you took the source from Subversion in a subdirectory called "trunk".
  If you used some other name, replace "trunk" below with your directory.

Setting your environment for compiling OpenModelica
===================================================
  If rmlc is not on the PATH, set RMLHOME to rml installation, e.g.
  /usr/local/rml/x86-linux-gcc/

  If you plan to use mico corba with OMC you need to:
  - set the PATH to path/to/mico/bin (for the idl compiler and mico-cpp)
  - set the LD_LIBRARY_PATH to path/to/installed/mico/lib (for mico libs)
  - set the PATH: $ export PATH=${PATH}:/path/to/installed/mico/bin
    + this is for executables: idl, mico-cpp and mico-config

To Compile OpenModelica
  run:
    $ ./configure --with-omniORB=/path/to/omniORB (if you want omc to use omniORB corba)
    $ ./configure --with-CORBA=/path/to/mico (if you want omc to use mico corba)
    $ ./configure --without-CORBA            (if you want omc to use sockets)
  in the trunk directory
  Make sure that all makefiles are created. Check carefully for error messages.

    $ make omc       (to build omc and simulation runtime)
    $ make mosh      (to build OMShell-terminal)
    $ make qtclients (to build Qt based clients: OMShell, ext, OMNotebook; requires CORBA)

  After the compilation the results are in the path/to/trunk/build.
  To run the testsuite:
    $ make test
  Note: Some Modelica Standard Library functions depend on LAPACK.
        On Ubuntu, this is installed by lpsolve dependencies.
        If you compiled omc using a static lpsolve, it is possible that you
        don't have LAPACK installed.

  If you run into problems read the GENERAL NOTES below and if that
  does not help, subscribe to the OpenModelicaInterest list:
    https://www.openmodelica.org/index.php/home/mailing-list
  and then sent us an email at [OpenModelicaInterest@ida.liu.se].

How to run
==========
For debugging purposes it can be useful to start OMShell and omc in two different termnials.
For this use:
trunk/build/bin/omc +d=interactive      (if you configured with --without-CORBA) or
trunk/build/bin/omc +d=interactiveCorba (if you comfigured with --with-CORBA=path/to/mico)

trunk/build/bin/OMShell-terminal -noserv         (if you configured with --without-CORBA) or
trunk/build/bin/OMShell-terminal -noserv -corba  (if you configured with --with-CORBA=path/to/mico)

( The -noserv argument will prevent mosh from starting its own omc in the background )

If you want to change the port number of the socket connection you
will have to do it manually in mosh.cpp and Compiler/Main.mo.

Example Session
===============
Here is a short example session.

$ cd trunk/build/bin
$ ./OMShell-terminal
OpenModelica 1.9.0
Copyright (c) OSMC 2002-2013
To get help on using OMShell and OpenModelica, type "help()" and press enter.
>> loadModel(Modelica)
true

>> instantiateModel(Modelica.Electrical.Analog.Basic.Resistor)
"class Modelica.Electrical.Analog.Basic.Resistor
Real v(quantity = "ElectricPotential", unit = "V") "Voltage drop between the two pins (= p.v - n.v)";
Real i(quantity = "ElectricCurrent", unit = "A") "Current flowing from pin p to pin n";
Real p.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
Real p.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
Real n.v(quantity = "ElectricPotential", unit = "V") "Potential at the pin";
Real n.i(quantity = "ElectricCurrent", unit = "A") "Current flowing into the pin";
parameter Real R(quantity = "Resistance", unit = "Ohm", start = 1.0) "Resistance";
equation
  R * i = v;
  v = p.v - n.v;
  0.0 = p.i + n.i;
  i = p.i;
  n.i = 0.0;
  p.i = 0.0;
end Modelica.Electrical.Analog.Basic.Resistor;
"
Warning, parameter R has no value

>> a:=1:5;
>> b:=3:8
{3,4,5,6,7,8}
>> a*b
Incompatible argument types to operation scalar product, left type: Integer[5],\
 right type: Integer[6]
Incompatible argument types to operation scalar product, left type: Real[5],\
 right type: Real[6]
Cannot resolve type of expression a*b (expressions :{a[1],a[2],a[3],a[4],a[5]},\
 {b[1],b[2],b[3],b[4],b[5],b[6]} types: Integer[5], Integer[6])

>> b:=3:7;
>> a*b
85
>>> listVariables()
{a, b}
>>

Bootstrapped compiler
=====================

To compile OpenModelica without the use of rml-mmc:
$ autoconf
$ ./configure --without-rml
$ make bootstrap-from-tarball

To recompile (once you have a working build/bin/omc)
$ make bootstrap-from-compiled

WARNING: The bootstrapped compiler has not been tested on all combinations of compilers and operating systems. It did work on 64-bit Ubuntu with GCC 4.4, but not on 64-bit Fedora Core with GCC 4.7.

CentOS 6 Hints (RPM, command-line only; for clients, add CORBA, readline)
=========================================================================
yum install tar gcc-c++ autoconf sqlite-devel java expat-devel lpsolve-devel lapack-devel make patch gettext
also needs cmake > 2.8; not in default repos; try http://dl.atrpms.net/el6-x86_64/atrpms/testing/cmake-2.8.8-4.el6.x86_64.rpm
./configure --without-rml --disable-omshell-terminal --disable-modelica3d
make -j8 bootstrap-from-tarball

GENERAL NOTES:
==============
- Fedora Core 4 has a missing symlink. To fix it, in /usr/lib do:
  ln -s libg2c.so.0 libg2c.so
  Otherwise the testsuite will fail when generating simulation code.

- On some Linux systems when running simulate(Model, ...) the
  executable for the Model enters an infinite loop. To fix this, add -ffloat-store to CFLAGS

Last updated 2014-01-30. Much is still outdated.
