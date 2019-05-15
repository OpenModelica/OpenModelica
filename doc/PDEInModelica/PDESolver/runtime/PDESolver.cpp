
#include <algorithm>
#include "model_data.h"
#include "runtime_data.h"
#include "model.h"
#include <math.h>
using namespace std;





int setupGrid(MODEL_DATA* mData){
    double vStart = mData->domainRange[0].v0;
    double vEnd = mData->domainRange[0].v1;
    int M = mData->M;
    for (int i = 0; i<M; i++){
        mData->spaceField[i] = shapeFunction(mData, vStart + (vEnd - vStart)/(M-1)*i);
    };
    return 0;
}

int setupSimulation(RUNTIME_DATA* rData){

    rData->modelData->M = 500;
    rData->endTime = 10;
    rData->cfl = 1;
//    rData->resultsFile.open("../../results.txt");
    return 0;
}

double minDx(MODEL_DATA* mData){
    //here for equidistant grid:
    return (mData->spaceField[mData->M - 1] - mData->spaceField[0]) / (mData->M - 1);
}


int setDt(RUNTIME_DATA* rData){
    MODEL_DATA* mData = rData->modelData;
//    double lambda = eqSystemMaxEigenVal(rData->modelData);
    double lambda = 1;
    double mDx = minDx(rData->modelData);
    double dt = rData->cfl*mDx/fabs(lambda);
    rData->dt = min(dt, rData->endTime - mData->time);
    return 0;
}




int updateSpaceDerivatives(RUNTIME_DATA* rData){
    MODEL_DATA* mData = rData->modelData;
    int M = mData->M;
    switch  (rData->dScheme)
    {
        case lax_friedrichs:
            //loop over all states:
            for (int iState=0; iState<mData->nStateFields; iState++){
                //left boundary, right side second-order difference:
                mData->stateFieldsDerSpace[iState*M + 0] = (-3*mData->stateFields[iState*M + 0] + 4*mData->stateFields[iState*M + 1] - mData->stateFields[iState*M + 2])/(mData->spaceField[iState*M + 2] - mData->spaceField[iState*M + 0]);
                    //(mData->stateFields[iState*M + 1] - mData->stateFields[iState*M])/(mData->spaceField[iState*M + 1] - mData->spaceField[iState*M + 0]);
                //loop over all inner grid nodes:
                for (int iNode=1; iNode<mData->M-1; iNode++){
                    //lax_friedrichsX(mData, iState, iNode);
                    mData->stateFieldsDerSpace[iState*M + iNode] = (mData->stateFields[iState*M + iNode + 1] - mData->stateFields[iState*M + iNode - 1])/(mData->spaceField[iState*M + iNode + 1] - mData->spaceField[iState*M + iNode - 1]);
                }
                // right boundary: left side second-order difference:
                mData->stateFieldsDerSpace[iState*M + M-1] = (3*mData->stateFields[iState*M + M-1] - 4*mData->stateFields[iState*M + M-2] + mData->stateFields[iState*M + M-3])/(mData->spaceField[iState*M + M-1] - mData->spaceField[iState*M + M-3]);
                    //(mData->stateFields[iState*M + M-1] - mData->stateFields[iState*M + M-2])/(mData->spaceField[iState*M + M-1] - mData->spaceField[iState*M + M-2]);
            }
            break;

        case forwardT_forwardS:
            cout << "this differential scheme is not implemented";
            throw dSchemeE;

        case forwardT_backwardS:
            //loop over all states:
            for (int iState=0; iState<mData->nStateFields; iState++){
                if (mData->isBc[iState*2+0] == 0) {
                    cout << "there must be boundary condition on left when forwardT_backwardS scheme is used for all states";
                    throw dSchemeE;
                }
                for (int iNode = 1; iNode < M; iNode++){
                    mData->stateFieldsDerSpace[iState*M + iNode] = (mData->stateFields[iState*M + iNode] - mData->stateFields[iState*M + iNode - 1])/(mData->spaceField[iState*M + iNode] - mData->spaceField[iState*M + iNode - 1]);
                }
            }
            break;

        default:
            cout << "this differential scheme is not implemented";
            throw dSchemeE;
    }
    return 0;
}

int updateStates(RUNTIME_DATA* rData){
    MODEL_DATA* mData = rData->modelData;
    int M = mData->M;
    switch  (rData->dScheme)
    {
        case lax_friedrichs:
            double leftOldState;
            double newState;
            //loop over all states:
            for (int iState=0; iState<mData->nStateFields; iState++){
                leftOldState = mData->stateFields[iState*M + 0];
                //left boundary:
                if (mData->isBc[iState*2+0] == 0)
                    //forward difference
                    mData->stateFields[iState*M + 0] += rData->dt*mData->stateFieldsDerTime[iState*M + 0];
                //loop over all grid nodes:
                for (int iNode=1; iNode<mData->M-1; iNode++){
                    //lax_friedrichsT(mData, iState, iNode);
                    newState = (leftOldState + mData->stateFields[iState*M + iNode + 1])/2 + rData->dt*mData->stateFieldsDerTime[iState*M + iNode];
                    leftOldState = mData->stateFields[iState*M + iNode];
                    mData->stateFields[iState*M + iNode] = newState;
                }
                if (mData->isBc[iState*2+1] == 0)
                    //forward difference
                    mData->stateFields[iState*M + M-1] += rData->dt*mData->stateFieldsDerTime[iState*M + M-1];
            }
            break;

        case forwardT_forwardS:
            cout << "this differential scheme is not implemented";
            throw dSchemeE;

        case forwardT_backwardS:
            //loop over all states:
            for (int iState=0; iState<mData->nStateFields; iState++){
                for (int iNode = 1; iNode < M; iNode++){
                    mData->stateFields[iState*M + iNode] += rData->dt*mData->stateFieldsDerTime[iState*M + iNode];
                }
            }
            break;

        default:
            cout << "this differential scheme is not implemented";
            throw dSchemeE;
    }
    //apply boundary conditions:
    functionBC(mData);
    return 0;
}


int doStep(RUNTIME_DATA* rData){
    updateSpaceDerivatives(rData);
    functionPDE(rData->modelData, (int)rData->dScheme);
    updateStates(rData);
    return 0;
}

int main() {
    RUNTIME_DATA rd;
    RUNTIME_DATA* rData = &rd;

    MODEL_DATA md;
    MODEL_DATA* mData = &md;
    rData->modelData = mData;
    int nSteps = 0;
    rData->dScheme = lax_friedrichs;//forwardT_backwardS;//



    try{
        setupSimulation(rData);
        setupArrayDimensions(mData);
        initializeData(mData);
        setupModelParameters(mData);
        setupGrid(mData);
        mData->time = 0;
        setupInitialState(mData);
        functionPDE(mData,(int)rData->dScheme);
        /*setDt(rData);
        writeStates(rData);*/

        //while (mData->time < rData->endTime) {
        //    doStep(rData);
        //    mData->time += rData->dt;
        //    functionPDE(mData,(int)rData->dScheme);
        //    setDt(rData);
        //    writeStates(rData);
        //    nSteps++;
        //}

    }
    catch (Exceptions e){
        switch (e) {
        case generalSoverE:
            puts("Internal solver error\n");
            break;
        case dSchemeE:
            puts("differential scheme error\n");
            break;
        default:
            puts("Unknown error\n");
            break;
        }
    }

    //rData->resultsFile.close();

    puts("Computation finished.");
    getchar();
    freeData(mData);
    return 0;
}

