
Using your own OpenModelica
===========================
Adrian.Pop@liu.se
2018-06-28


Windows:
========
You compiled OpenModelica and now you have a directory called build
inside your OpenModelica cloned repository containing bin, lib and so on.
To use it you need to set two environment variables:
OPENMODELICAHOME=C:\Path\To\OpenModelica\build
OPENMODELICALIBRARY=C:\Path\To\OpenModelica\lib\omlibrary
NOTE: If you don't set these and have another OpenModelica
      system installation the dlls and libraries from that
	  installation will be used and you will have a lot
	  of issues.

In general I use mingw64 terminal to test omc or OMEdit.
To set the paths and the environment variables each time I
open the mingw64 terminal I have in my .bashrc as last line:
source ~/om.sh
and my om.sh contains:
#--- start om.sh
# set the path to git and svn executables
export PATH=$PATH:/c/bin/git/bin/:/c/bin/jdk/bin:/c/Program\ Files/TortoiseSVN/bin
# set the paths to my own compiled OpenModelica build directory
export OPENMODELICAHOME="c:\\home\\adrpo33\\dev\\OpenModelica\\build"
export OPENMODELICALIBRARY="c:\\home\\adrpo33\\dev\\OpenModelica\\build\\lib\\omlibrary"
echo $OPENMODELICAHOME
echo $OPENMODELICALIBRARY
echo $PATH
#--- end om.sh

Then you can start your mingw64 terminal and start omc or OMEdit from
OpenModelica/build/bin directory.

Linux:
======
On Linux we don't need to set any of the OPENMODELICAHOME or OPENMODELICALIBRARY
as the omc or OMEdit executables know where to use the libraries from via RPATH.

