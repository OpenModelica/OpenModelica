#include <math.h>
#include "model_data.h"
#include "PDESolver.h"
#include "model.h"
#include "diff.h"

double pi = 3.14159265358979323846;

int setupArrayDimensions(struct MODEL_DATA* mData) {
    mData->nStateFields = 2;
    mData->nAlgebraicFields= 1;
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
    /*string.L*/mData->parameters[0] = 1;
    /*string.c*/mData->parameters[1] = 1;
    /*DomainLineSegment1D.l*/mData->parameters[2] = 1;
    /*DomainLineSegment1D.a*/mData->parameters[3] = 0;
    mData->isBc[mData->nStateFields*0 + 0] = 1;
    mData->isBc[mData->nStateFields*0 + 1] = 1;
    return 0;
}

double /*u0*/function_0(struct MODEL_DATA* mData, double x){
    return sin(4*pi/ /*string.L*/mData->parameters[0]*x);
}

int setupInitialState(struct MODEL_DATA* mData){
    int i;
    for (i=0; i<mData->M; i++){
        /*u*/mData->stateFields[mData->M*0 + i] = function_0(mData, mData->spaceField[mData->M*0 + i]);
        /*u_t*/mData->stateFields[mData->M*1 + i] = 0;
    }
    return 0;
}

double shapeFunction(struct MODEL_DATA *mData, double v)
{
    return /*DomainLineSegment1D.l*/mData->parameters[2]*v + /*DomainLineSegment1D.a*/mData->parameters[3];
}

// pder(u,t)   = u_t
// pder(u,x)   = u_x
// pder(u_t,t) = c pder(u_x,x)


int functionPDE(struct MODEL_DATA *mData, int dScheme)
{
    // both states and algebraics have their specific array for space derivatives

    // states u, u_t
    // algebraics u_x

    //we have u, u_t, pder(u,x), pder(u_t,x)

    // u_x          = pder(u,x)
    // pder(u_x,x)  = diff(u_x,x)
    // pder(u,t)    = u_t
    // pder(u_t,t)  = c pder(u_x,x)

    //u     stateFields[M*0
    //u_t   stateFields[M*1
    //u_x   algebraicFields[M*0


    int M = mData->M;
    int i;
    for (i = 0; i<M; i++){
        /*u_x*/mData->algebraicFields[M*0 + i] = mData->stateFieldsDerSpace[M*0 + i];
    }
    differentiateX(/*u_x*/&(mData->algebraicFields[M*0]), /*pder(u_x,x)*/&(mData->algebraicFieldsDerSpace[M*0]), mData, dScheme);
    for (i = 0; i<M; i++){
        /*pder(u,t)*/mData->stateFieldsDerTime[M*0 + i] = /*u_t*/mData->stateFields[M*1 + i];
        /*pder(u_t,t)*/mData->stateFieldsDerTime[M*1 + i]  = /*c*/mData->parameters[1]* /*pder(u_x,x)*/mData->algebraicFieldsDerSpace[M*0 + i];
    }
  return 0;
  //in this approach some arrays for space derivatives might be unused (here pder(u_t,x))
}

//int functionPDE_2(struct MODEL_DATA *mData)
//{
//    // all space derivatives of states and algebraics are stored as different algebraic fields
//    //---------------------------------
//    // TODO: pokracovat
//    //---------------------------------
//
//    // states u, u_t
//    // algebraics u_x
//
//    //we have u, u_t, pder(u,x), pder(u_t,x)
//
//    // u_x          = pder(u,x)
//    // pder(u_x,x)  = diff(u_x,x)
//    // pder(u,t)    = u_t
//    // pder(u_t,t)  = c pder(u_x,x)
//
//    //u     stateFields[M*0
//    //u_t   stateFields[M*1
//    //u_x   algebraicFields[M*0
//
//
//    int M = mData->M;
//    int i;
//    for (i = 0; i<M; i++){
//        /*u_x*/mData->algebraicFields[M*0 + i] = mData->stateFieldsDerSpace[M*0 + i];
//    }
//    diffx(/*u_x*/mData->algebraicFields[M*0], /*der(u_x,x)*/mData->algebraicFieldsDerSpace[M*0]);
//    for (i = 0; i<M; i++){
//        /*pder(u,t)*/mData->stateFieldsDerTime[M*0 + i] = /*u_t*/mData->stateFields[M*1 + i];
//        /*pder(u_t,t)*/mData->stateFieldsDerTime[M*1 + i]  = /*c*/mData->parameters[1]* /*pder(u_x,x)*/mData->algebraicFieldsDerSpace[M*0 + i];
//    }
//  return 0;
//  //this aproach is confusing as algebraics array is used for various fields
//}

int functionBC(struct MODEL_DATA *mData)
{
    int M = mData->M;
    mData->stateFields[mData->M*0 + 0] = 0;
    mData->stateFields[mData->M*0 + M-1] = 0;
    mData->stateFields[mData->M*1 + 0] = 0;
    mData->stateFields[mData->M*1 + M-1] = 0;

  return 0;
}

