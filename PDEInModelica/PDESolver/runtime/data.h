#ifndef _DOUBLE_PAIR
#define _DOUBLE_PAIR
struct DoublePair {
    double v0;
    double v1;
};
#endif

#ifndef _DATA
#define _DATA
struct DATA {
    int M;        //number of grid points
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
    double* parameterFields;//[iParameter*M + iNode];
    double* spaceField;//[iNode];  space independent variable (x)
    int*   isBc;//[iState*2 + (0 = left) or (1 = right)]; Is there a BC?
    double* parameters;
    double time;
    double endTime;
    double dt; //time step
    double cfl; // Courant–Friedrichs–Lewy number (lambda*dt/dx < cfl)
};

#endif
int initializeData(struct DATA *d);
int freeData(struct DATA *d);
