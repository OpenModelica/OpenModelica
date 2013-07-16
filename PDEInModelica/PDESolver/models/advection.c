
#include "data.h"
#include "PDESolver.h"
#include "model.h"
#include <math.h>
//#define _USE_MATH_DEFINES
//#include <math.h>
double pi = 3.14159265358979323846;

int setupArrayDimensions(struct DATA* data) {
    data->nStateFields = 1;
    data->nAlgebraicFields= 0;
    data->nParameterFields= 0;
    data->nParameters = 4;
    data->nDomainSegments = 3;
    return 0;
}



int setupModel(struct DATA* data)
{
    int i;
    /*interior:*/
    data->domainRange[0].v0 = 0; 
    data->domainRange[0].v1 = 1;
    /*left*/
    data->domainRange[1].v0 = 0;
    data->domainRange[1].v1 = 0;
    /*right*/
    data->domainRange[2].v0 = 1;
    data->domainRange[2].v1 = 1;
    for (i=0; i<data->M; i++){
        //TODO: should be done generaly, with some kind of stateInitial(x) function called from static code.(
        data->stateFields[data->M*0 + i] = 1;
    }
    /*advection.L*/data->parameters[0] = 1;
    /*advection.c*/data->parameters[1] = 1;
    /*DomainLineSegment1D.l*/data->parameters[2] = 1;
    /*DomainLineSegment1D.a*/data->parameters[3] = 0;
    data->isBc[data->nStateFields*0 + 0] = 1;
    data->isBc[data->nStateFields*0 + 1] = 0;
  
    return 0;
}

double shapeFunction(struct DATA *data, double v)
{
    return /*DomainLineSegment1D.l*/data->parameters[2]*v + /*DomainLineSegment1D.a*/data->parameters[3];
}


int functionPDE(struct DATA *data)
{
    int i;
    for (i = 0; i<data->M; i++)
        /*u_t*/data->stateFieldsDerTime[data->M*0 + i] = - /*c*/data->parameters[1] * /*u_x*/data->stateFieldsDerSpace[data->M*0 + i];
    return 0;
}

int functionBC(struct DATA *data)
{
    //should be writen generaly -- independent on particular grid
    data->stateFields[data->M*0 + 0] = cos(2*pi*data->time);
    return 0;
}

double eqSystemMaxEigenVal(struct DATA* data){
    return /*c*/data->parameters[1];
}