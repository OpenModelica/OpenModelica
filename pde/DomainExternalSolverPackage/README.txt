Installation:

All paths are relative to the directory where this file was found.


Install rheolef and setup the environment variables accordingly as in
rheolef.sh. Edit 
  ModelicaLibraries/ExternalC/extsolverrun.sh 
accordingly.

Install bamg and edit 
  ModelicaLibraries/ExternalC/bamgrun.bat 
so that it is found. 

In a cygwin shell and rheolef paths correctly set up, run "make" in
 ModelicaLibraries/ExternalC and 
 ModelicaLibraries/ExternalC/rheolef . 
To run the tests, run "make runtests" in 
  ModelicaLibraries/ExternalC/test

Set the environment variables in paths.bat (or paths.sh) in Windows so that
Dymola can use them.

Load the script "Applications/mosfiles/setup.mos" in Dymola.

Open one of the files in "Applications/" , e.g. testFEM.mo. Make sure
"Applications" is current directory in Dymola and run the script
"mosfiles/femforms_translate.mos". Make sure all the function compilations
return true. Otherwise something is wrong. See the "Simulation" tab for possible
errors. Possibly also run the script "mosfiles/femforms_translate2.mos".

Translate e.g. the model MyGenericBoundaryDiffusionTest. If there are messages
like 

  "Mesh file not found. Returning dummy mesh size {4,3,3}. Run simulate and
  retranslate."

then run simulate in order that the mesh file is generated, and translate again
to read in the mesh file. Then you should be able to simulate.

Visualization in MATLAB:

Add the folder Applications/MFiles to matlab m-file path, e.g. by selecting
File->Set Path in Matlab and adding a folder. Run following commands in matlab,
while the current directory is Applications:

showmesh('MyGenericBoundaryPoissonTest.mat','pde.ddomain')
showfield_ind('MyGenericBoundaryPoissonTest.mat','pde.fd')

showmesh('MyGenericBoundaryDiffusionTest.mat','pde.ddomain')
showfieldt_ind('MyGenericBoundaryDiffusionTest.mat','pde.fd',timestep)
showmesh('MyGenericBoundaryDiffusionTest.mat','pde.ddomain.mesh')


Troubleshooting
---------------
If translation works but something is not working during simulation, try running
the dymosim.exe from the command line to see any error messages from the
execution of external programs.

Error messages like "vector size incorrect" may appear during simulation. This
is caused by change of matrix sizes because of change of mesh or change of
boundary conditions (number of unknown/blocked values change). When simulation
starts, the mesh is regenerated so that next translation will get the correct
mesh sizes (verify number of reported scalars during translation). Next
simulation will then be correct.
