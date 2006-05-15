OMShell compilation on Linux/Unix
----------------------------------------
Adrian Pop [adrpo@ida.liu.se] 2006-05-15
----------------------------------------


You will need mico-2.x.x for this.
- go to trunk/OMShell
- edit OMShell.pro according to your installation
  + run 'mico-config' 
  + replace LIBS in OMShell.pro with the output 
    you got from 'mico-config'
  + edit the INCLUDEPATH and give the mico include 
    path there.
- run qmake OMShell.pro
- run make


Cheers,
Adrian/