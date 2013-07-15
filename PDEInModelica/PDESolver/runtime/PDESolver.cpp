
#include <stdio.h>
#include <stdlib.h>
#include "data.h"
#include "model.h"
#include "PDESolver.h"

int setupGrid(DATA* data){
  double vStart = data->domainRange[0].v0;
  double vEnd = data->domainRange[0].v1;
  int M = data->M;
  for (int i = 0; i<M; i++){
    data->spaceField[i] = shapeFunction(data, vStart + (vEnd - vStart)/(M-1)*i);
  };
  return 0;
}


int main() {
  DATA data;
  DATA* dataPtr = &data;
  data.M = 100;
  setupArrayDimensions(dataPtr);
  initializeData(dataPtr);
  setupGrid(dataPtr);
  setupModel(dataPtr);
  //do the numerics here!

  puts("ahoj"); /* prints ahoj */
  getchar();
  freeData(dataPtr);
  return 0;
}

