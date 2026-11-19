#include "simulation/solver/spatialDistribution.h"
#include "util/omc_error.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Reads, failures and checkpoint restoration must preserve committed history. */
int main(void)
{
  DATA data = {0};
  MODEL_DATA model = {0};
  SIMULATION_INFO info = {0};
  SIMULATION_DATA point = {0};
  SIMULATION_DATA* points[] = {&point};
  threadData_t thread = {0};
  threadData_t* threadData = &thread;
  _index_t length = 2;
  double grid[] = {0, 1}, values[] = {0, 0};
  real_array initialPoints = {1, &length, grid, 0, 0};
  real_array initialValues = {1, &length, values, 0, 0};
  int ok = 1;

  model.nSpatialDistributions = 1;
  data.modelData = &model;
  data.simulationInfo = &info;
  data.localData = points;
  info.spatialDistributionData = allocSpatialDistribution(1);
  initSpatialDistribution(&data, threadData, 0, &initialPoints, &initialValues, 2);

  /* Store inlet 0 at x=0 and inlet 2 at x=0.5. */
  double outlet;
  spatialDistribution(&data, threadData, 0, 0, 1, &outlet);
  storeSpatialDistribution(&data, threadData, 0, 0, 0, 0, 1);
  storeSpatialDistribution(&data, threadData, 0, 2, 0, 0.5, 1);

  size_t words = spatialDistributionStateWords(&data, NULL);
  double* before = malloc(words * sizeof(double));
  double* after = malloc(words * sizeof(double));
  spatialDistributionStateWords(&data, before);

  /* Read out of order; expect inlet 2, outlet 1 and unchanged history. */
  double repeated;
  ok &= spatialDistribution(&data, threadData, 0, 1.25, 1, &outlet) == 2;
  spatialDistribution(&data, threadData, 0, 0.75, 1, &repeated);
  spatialDistribution(&data, threadData, 0, 1.25, 1, &repeated);
  ok &= fabs(outlet - 1) < 1e-12 && outlet == repeated;
  spatialDistributionStateWords(&data, after);
  ok &= memcmp(before, after, words * sizeof(double)) == 0;

  /* Change x slightly; the outlet should change with slope 4. */
  double shifted;
  spatialDistribution(&data, threadData, 0, 1.25 + 1e-6, 1, &shifted);
  ok &= fabs((shifted - outlet) / 1e-6 - 4) < 1e-8;

  /* Read past the available history; expect an error and no history changes. */
  spatialDistribution(&data, threadData, 0, 2, 1, &outlet);
  ok &= omc_error_take(threadData) && spatialDistributionNeedsHistory(&data, 1) && isnan(outlet);
  spatialDistributionStateWords(&data, after);
  ok &= memcmp(before, after, words * sizeof(double)) == 0;

  /* Store inlet 4, then restore the saved history; the inlet should be 2 again. */
  storeSpatialDistribution(&data, threadData, 0, 4, 0, 1, 1);
  ok &= spatialDistribution(&data, threadData, 0, 1, 1, NULL) == 4;
  ok &= setSpatialDistributionStateWords(&data, before, words, TRUE) == words;
  ok &= spatialDistribution(&data, threadData, 0, 1.25, 1, &outlet) == 2;
  ok &= fabs(outlet - 1) < 1e-12;

  /* Negative flow should give inlet 2, outlet 1 and slope -4, with or without out1. */
  freeSpatialDistribution(info.spatialDistributionData, 1);
  free(info.spatialDistributionData);
  info.spatialDistributionData = allocSpatialDistribution(1);
  initSpatialDistribution(&data, threadData, 0, &initialPoints, &initialValues, 2);
  spatialDistribution(&data, threadData, 0, 0, 0, NULL);
  storeSpatialDistribution(&data, threadData, 0, 0, 2, -0.5, 0);
  outlet = spatialDistribution(&data, threadData, 0, -1.25, 0, NULL);
  spatialDistribution(&data, threadData, 0, -1.25, 0, &repeated);
  ok &= repeated == 2;
  shifted = spatialDistribution(&data, threadData, 0, -1.25 + 1e-6, 0, NULL);
  ok &= fabs(outlet - 1) < 1e-12;
  ok &= fabs((shifted - outlet) / 1e-6 + 4) < 1e-8;

  free(before);
  free(after);
  freeSpatialDistribution(info.spatialDistributionData, 1);
  free(info.spatialDistributionData);
  if (!ok) fprintf(stderr, "spatialDistribution history check failed\n");
  return !ok;
}
