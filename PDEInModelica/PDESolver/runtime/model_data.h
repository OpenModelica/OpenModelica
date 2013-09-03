#ifndef _DATA_INCL
#define _DATA_INCL

//#include <iostream>
//#include <fstream>
//using namespace std;

struct DoublePair {
    double v0;
    double v1;
};


struct MODEL_DATA {
    int M;                      //number of grid points
    int nStateFields;
    int nAlgebraicFields;
    int nParameterFields;
    int nParameters;
    int nDomainSegments;
    struct DoublePair* domainRange; //range of shape-function parameter forming the domain. First pair describes the interior, than follow the boundaries
    double* stateFields;//[iState*M + iNode];
    double* stateFieldsDerTime;//[iState*M + iNode];
    double* stateFieldsDerSpace;//[iState*M + iNode];
    double* algebraicFields;//[iAlgebraic*M + iNode];
    double* algebraicFieldsDerSpace;//[iAlgebraic*M + iNode];
    double* parameterFields;//[iParameter*M + iNode];
    double* spaceField;//[iNode];  space independent variable (x)
    int*    isBc;//[iState*2 + (0 = left) or (1 = right)]; Is there a BC?
    double* parameters;
    double time;
};


int initializeData(struct MODEL_DATA *d);
int freeData(struct MODEL_DATA *d);

#endif
