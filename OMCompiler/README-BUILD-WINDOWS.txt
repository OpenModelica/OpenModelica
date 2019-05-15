/* 
 * RCS: $Id: README-BUILD-WINDOWS.txt 11132 2012-02-14 14:32:13Z adrpo $ 
 */

How to set up a build machine for OpenModelica (Windows)
========================================================

VERSIONS
========
2012-11-01 [ZL]: Initial version

MACHINE
=======
Virtual Machine with
50 GB HDD
4 GB RAM
4 cores


STEPS
=====
-M: are mandatory steps
-O: are optional steps

-M Install Windows (7 x64 Pro + SP1)
-O Enable remote access to the machine
-O Set to show all notification icons
-M Install all (important) windows updates until there is no update
-O Get the IP of the machine and remote login to it
	cmd> ipconfig /all
-O Install a chrome (use Internet Explorer to download the installer)
	https://www.google.com/intl/en/chrome/browser/
	click on download
	accept and install
-M Create a directory c:\bin
-M Set (system) environment variable OMDev to c:\OMDev
-M Install TortoiseSVN (1.7.10.23359-x64-svn-1.7.7)
	http://tortoisesvn.net
	Direct link: http://iweb.dl.sourceforge.net/project/tortoisesvn/1.7.10/Application/TortoiseSVN-1.7.10.23359-x64-svn-1.7.7.msi
	Extra settings during install:
		- include command line client tools
	Install location: (default) c:\Program Files\ToroiseSVN\
-M Install python 2.7.3 (x86)
	http://www.python.org/download/releases/2.7.3/
	Direct link: http://www.python.org/ftp/python/2.7.3/python-2.7.3.msi
	Install location: c:\bin\python273\
-M Install JDK (7u9-windows-x64)
	http://www.oracle.com/technetwork/java/javase/downloads/index.html
	Direct link: http://download.oracle.com/otn-pub/java/jdk/7u9-b05/jdk-7u9-windows-x64.exe
	Install location: c:\bin\jdk170\
	JRE install location: (default)
-M Install NSIS (2.46)
	http://nsis.sourceforge.net/Download
	Direct link: http://prdownloads.sourceforge.net/nsis/nsis-2.46-setup.exe?download
	Install location: c:\bin\NSIS\
-M Install AccessControl plugin for NSIS
	http://nsis.sourceforge.net/AccessControl_plug-in
	Direct link: http://nsis.sourceforge.net/mediawiki/images/4/4a/AccessControl.zip
	1) Extract the zip file somewhere
	2) Copy the content of the extracted folder to c:\bin\nsis\ and choose to overwrite the existing folders.
-M Install qtsdk (QtSdk-online-win-x86-v1_2_1) NOTE: DO NOT USE the offline installer
	http://qt-project.org/downloads (Qt SDK version 1.2.1 Windows: Online installer - 15 MB)
	Direct link: http://www.developer.nokia.com/dp?uri=http%3A%2F%2Fsw.nokia.com%2Fid%2F23f71960-21d3-4b7a-9329-4d5484c49c68%2FQt_SDK_Win_online
	Install location: C:\bin\QtSDK\
	Custom installation
	Make sure that Qt SDK\Development Tools\Desktop Qt\Qt 4.8.0 (Desktop)\Desktop Qt 4.8.0 - MinGW is checked.
-M Install Visual C++ 2010 Express (vc_web.exe)
	http://www.microsoft.com/visualstudio/eng/downloads#d-2010-express
	Direct link: http://go.microsoft.com/?linkid=9709949
	Do not install silverlight
-M Install all (important) windows updates until there is no update
-M Create a directory c:\dev\OpenModelica_releases	
-M Get buildNightly.bat file and put it into c:\dev\OpenModelica_releases	
	Direct link: https://test.openmodelica.org/hudson/job/OM_Win_NIGHTLY_BUILD/ws/buildNightly.bat
-O Download console2
	http://sourceforge.net/projects/console/
	Direct link: http://sourceforge.net/projects/console/files/latest/download
	Extract it
	Copy and paste it to c:\bin\console2\
-M Open a command line window and run buildNightly.bat
	c:\dev\OpenModelica_releases>dir
	 Volume in drive C has no label.
	 Volume Serial Number is D4D7-4AB4
	
	 Directory of c:\dev\OpenModelica_releases
	
	10/31/2012  03:44 PM    <DIR>          .
	10/31/2012  03:44 PM    <DIR>          ..
	10/31/2012  03:43 PM             1,543 buildNightly.bat
	               1 File(s)          1,543 bytes
	               2 Dir(s)  30,379,155,456 bytes free

	c:\dev\OpenModelica_releases>buildNightly.bat
-M SVN cerificate: accept it (p)ermanently: p
-M SVN username/password prompts
	username: anonymous
	password: none
-M If c:\OMDev does not exist run the script again
-M Pop up window (windows firewall): idl.exe Allow access

buildNightly.bat
----------------
   The command should check out (update before each run) 3 repositories.
	c:\OMDev
	c:\dev\OpenModelica
	c:\dev\OpenModelica\Compiler\OpenModelicaSetup\
   It creates a folder for each revision in c:\dev\OpenModelicaReleases\{REVISION}\ and puts the results and installer here.
   If the script fails please delete the incomplete (usually empty) folder for that revision to ensure that the script generates everything again.
   
   If the script fails using multiple cores, make the following changes. If you do not have at least 6 cores please modify the line in the .bat file:

   %OMDEV%\tools\msys\bin\sh --login -i -c "time /c/dev/OpenModelica/Compiler/OpenModelicaSetup/BuildWindowsRelease.sh adrpo -j6"

   -j6 specifies the number of cores to compile if you have 4 use -j4 if it does not work use -j1 like:
   %OMDEV%\tools\msys\bin\sh --login -i -c "time /c/dev/OpenModelica/Compiler/OpenModelicaSetup/BuildWindowsRelease.sh adrpo -j1"

RESULTS
=======
...
Processed 1 file, writing output:
Adding plug-ins initializing function... Done!
Processing pages... Done!
Removing unused resources... Done!
Generating language tables... Done!
Generating uninstaller... Done!

Output: "c:\dev\OpenModelica\Compiler\OpenModelicaSetup\OpenModelica.exe"
Install: 7 pages (448 bytes), 2 sections (1 required) (2096 bytes), 17956 instructions (502768 bytes), 13587 strings (283263 bytes), 1 language table (322 bytes).
Uninstall: 3 pages (192 bytes),
1 section (1048 bytes), 364 instructions (10192 bytes), 181 strings (3095 bytes), 1 language table (254 bytes).
Datablock optimizer saved 23538141 bytes (~10.2%).

Using zlib compression.

EXE header size:               37888 / 35840 bytes
Install code:                 173943 / 789273 bytes
Install data:              205075458 / 701805878 bytes
Uninstall code+data:           12104 / 13458 bytes
CRC (0x593A92D7):                  4 / 4 bytes

Total size:                205299397 / 702644453 bytes (29.2%)
+ mv OpenModelica.exe /c/dev/OpenModelica_releases/13747/OpenModelica-revision-13747.exe
+ cd /c/dev/OpenModelica
+ svn log -v -r 13747:1
++ date +%Y-%m-%d_%H-%M
+ export DATESTR=2012-10-31_21-44
+ DATESTR=2012-10-31_21-44
+ echo 'Automatic build of OpenModelica by testwin.openmodelica.org at date: 2012-10-31_21-44 from revision: 13747'
+ echo ' '
+ echo 'Read OpenModelica-revision-13747-ChangeLog.txt for more info on changes.'
+ echo ' '
+ echo 'See also (match revision 13747 to build jobs):'
+ echo '  https://test.openmodelica.org/hudson/'
+ echo '  http://test.openmodelica.org/~marsj/MSL31/BuildModelRecursive.html'
+ echo '  http://test.openmodelica.org/~marsj/MSL32/BuildModelRecursive.html'
+ echo ' '
+ cat
+ echo ' '
+ echo 'Read more about OpenModelica at https://openmodelica.org'
+ echo 'Contact us at OpenModelica@ida.liu.se for further issues or questions.'
+ cd /c/dev/OpenModelica
+ echo 'Running testsuite trace'
Running testsuite trace
+ make -f Makefile.omdev.mingw -j6 testlog
+ echo 'Check HUDSON testserver for the testsuite trace here (match revision 13747 to build jobs): '
+ echo '  https://test.openmodelica.org/hudson/'
+ cat time.log
+ cat testsuite/testsuite-trace.txt
+ rm -f time.log
+ ls -lah /c/dev/OpenModelica_releases/13747/
total 208M
drwxr-xr-x 2 meta Administrators 4.0K Oct 31 22:27 .
drwxr-xr-x 3 meta Administrators    0 Oct 31 21:18 ..
-rw-r--r-- 1 meta Administrators  11M Oct 31 21:44 OpenModelica-revision-13747-ChangeLog.txt
-rw-r--r-- 1 meta Administrators 1.5K Oct 31 21:44 OpenModelica-revision-13747-README.txt
-rw-r--r-- 1 meta Administrators 546K Oct 31 22:27 OpenModelica-revision-13747-testsuite-trace.txt
-rwxr-xr-x 1 meta Administrators 196M Oct 31 21:43 OpenModelica-revision-13747.exe
+ cd /c/dev/OpenModelica_releases/13747/
+ ssh adrpo@build.openmodelica.org
Pseudo-terminal will not be allocated because stdin is not a terminal.
The authenticity of host 'build.openmodelica.org (130.236.190.138)' can't be established.
RSA key fingerprint is ef:54:15:4f:47:15:98:90:76:dc:b5:f1:87:29:0f:5f.
Are you sure you want to continue connecting (yes/no)? no
Host key verification failed.

real    91m31.139s
user    3m27.911s
sys     7m42.059s

c:\dev\OpenModelica_releases>REM c:\OMDev\tools\msys\bin\sh --login -i -c "time /c/dev/OpenModelica/Compiler/OpenModelicaSetup/BuildWindowsRelease.sh adrpo -j7 > /c/dev/OpenModelica_releases/trace-BuildWindowsRelease.txt 2>&1"

c:\dev\OpenModelica_releases>


==============================================
Zsolt Lattmann <Zsolt.Lattmann@vanderbilt.edu>
Adrian Pop <Adrian.Pop@liu.se>
