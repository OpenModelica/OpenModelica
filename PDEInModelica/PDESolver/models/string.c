int const M = 100;
int const nStatesPDE = 1;
int const nAlgebraicsPDE = 0;
int const nParametersPDE = 0;
int const nParameters = 3;

#include "../src/data.h"

int functionInitial(){
  for (i=0; i<M; i++){
    statesPDE[i][1] = ;
  }
  /*L*/parameters[0] = 1;
  /*c*/parameters[1] = 1;
  isBC[0][0] = true;int const M = 100;
int const nStatesPDE = 1;
int const nAlgebraicsPDE = 0;
int const nParametersPDE = 0;
int const nParameters = 2;

#include "data.h"

int functionInitial(){
  for (i=0; i<M; i++){
    statesPDE[i] = 1;
  }
  /*L*/parameters[0] = 1;
  /*c*/parameters[1] = 1;
  isBC[0][0] = true;
  isBC[1][0] = false;
  
  return 0;
}

int functionPDE()
{
  /*u_t*/statesDerTime[0] = - /*c*/parameters[1] * /*u_x*/statesDerSpace[0];
  return 0;
}

int functionBC(){
  statesPDE[0] = cos(2*pi*time);
  return 0;
}

  isBC[1][0] = false;
  
  return 0;
}

int functionPDE()
{
  /*u_t*/statesDerTime[0] = - /*c*/parameters[1] * /*u_x*/statesDerSpace[0];
  return 0;
}

int functionBC(){
  statesPDE[0] = cos(2*pi*time);
  return 0;
}
