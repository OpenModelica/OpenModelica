
#include <math.h>
#include "model_data.h"
#include "PDESolver.h"
#include "model.h"

//#define _USE_MATH_DEFINES
//#include <math.h>
double pi = 3.14159265358979323846;

int setupArrayDimensions(struct MODEL_DATA* mData) {
    mData->nStateFields = 1;
    mData->nAlgebraicFields= 0;
    mData->nParameterFields= 0;
    mData->nParameters = 4;
    mData->nDomainSegments = 3;
    return 0;
}



int setupModelParameters(struct MODEL_DATA* mData)
{
    /*interior:*/
    mData->domainRange[0].v0 = 0;
    mData->domainRange[0].v1 = 1;
    /*left*/
    mData->domainRange[1].v0 = 0;
    mData->domainRange[1].v1 = 0;
    /*right*/
    mData->domainRange[2].v0 = 1;
    mData->domainRange[2].v1 = 1;
    /*advection.L*/mData->parameters[0] = 1;
    /*advection.c*/mData->parameters[1] = 1;
    /*DomainLineSegment1D.l*/mData->parameters[2] = 1;
    /*DomainLineSegment1D.a*/mData->parameters[3] = 0;
    mData->isBc[mData->nStateFields*0 + 0] = 1;
    mData->isBc[mData->nStateFields*0 + 1] = 0;
    return 0;
}

int setupInitialState(struct MODEL_DATA* mData){
    int i;
    for (i=0; i<mData->M; i++){
        //TODO: should be done generally, with some kind of stateInitial(x) function called from static code.(
        mData->stateFields[mData->M*0 + i] = 1;
    }
    return 0;
}

double shapeFunction(struct MODEL_DATA *mData, double v)
{
    return /*DomainLineSegment1D.l*/mData->parameters[2]*v + /*DomainLineSegment1D.a*/mData->parameters[3];
}


int functionPDE(struct MODEL_DATA *mData, int dScheme)
{
    int M = mData->M;
    int i;
    for (i = 0; i<M; i++)
        /*u_t*/mData->stateFieldsDerTime[M*0 + i] = - /*c*/mData->parameters[1] * /*u_x*/mData->stateFieldsDerSpace[mData->M*0 + i];
    return 0;
}

int functionBC(struct MODEL_DATA *mData)
{
    //should be writen generaly -- independent on particular grid
    int M = mData->M;
    mData->stateFields[M*0 + 0] = cos(2*pi*mData->time);
    return 0;
}

/*double eqSystemMaxEigenVal(struct MODEL_DATA* mData){
    return cmData->parameters[1];
}*/
