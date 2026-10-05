Reference results for the Modelica Standard Library 4.1.0 tests.

The files are converted from the official MSL reference results
(https://github.com/modelica/ModelicaStandardLibrary/tree/master/ReferenceResults,
commit 4c40388dde27ccb6702cea876adbf54c76d75b97). Each file holds the
comparisonSignals of the official reference, and the tests compare exactly
those signals.

Conversion, per model:
  filterSimulationResults("<Model>.csv", "<Model>.mat", {<comparisonSignals>},
                          removeDescription=true);
  xz -9e <Model>.mat

Files that would exceed 500 kB after compression are resampled with the
numberOfIntervals argument of filterSimulationResults (event points are not kept).

Never ever put a huge reference file in here.
If you are only going to test 3 trajectories, only add a reference file with 3 trajectories in it.
