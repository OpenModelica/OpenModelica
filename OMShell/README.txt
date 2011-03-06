2011-03-06 [adeel.asghar@liu.se]
------------------------------

Windows
------------------------------

OMShell uses Qt 4.7.0
------------------------------
- Download the Qt SDK for windows from http://qt.nokia.com/downloads. The SDK also contains the Qt Creator.

OmniORB
------------------------------
- OMShell uses the OmniORB 4.1.4.
- If you have OMDev downloaded then make sure its environment variable (OMDEV) is also set. OmniORB is included in OMDev package.
- If you don't have OMDev then download OmniORB from 
https://openmodelica.ida.liu.se/svn/OpenModelica/installers/windows/OMDev/lib/omniORB-4.1.4-mingw and set the path in 
OMShellGUI.pro file accordingly.
- Load the project in Qt Creator, build and run.
- Copy omniORB414_rt.dll and omniORB414_rtd.dll from /omniORB-4.1.4-mingw/bin/x86_win32 to /location-where-OMShell.exe-is-created.

------------------------------
Adeel.
adeel.asghar@liu.se