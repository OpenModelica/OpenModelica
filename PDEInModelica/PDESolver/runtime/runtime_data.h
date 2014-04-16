#ifndef _RUNTIME_DATA_INCL
#define _RUNTIME_DATA_INCL

#include <iostream>
#include <fstream>
#include "model_data.h"
using namespace std;

enum DScheme {lax_friedrichs, forwardT_forwardS, forwardT_backwardS};
enum Exceptions {dSchemeE, generalSoverE};

struct RUNTIME_DATA {
    MODEL_DATA* modelData;
    double endTime;
    double dt; //time step
    double cfl; // Courant-Friedrichs-Lewy number (lambda*dt/dx < cfl)
    ofstream resultsFile;
    DScheme dScheme;
};

int writeStates(RUNTIME_DATA* rd);

#endif
