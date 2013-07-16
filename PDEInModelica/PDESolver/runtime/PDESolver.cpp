
#include <stdio.h>
#include <stdlib.h>
#include <algorithm>
#include "data.h"
#include "model.h"
#include "PDESolver.h"
#include "schemes.h"
using namespace std;

int setupGrid(DATA* data){
    double vStart = data->domainRange[0].v0;
    double vEnd = data->domainRange[0].v1;
    int M = data->M;
    for (int i = 0; i<M; i++){
        data->spaceField[i] = shapeFunction(data, vStart + (vEnd - vStart)/(M-1)*i);
    };
    return 0;
}

int setupSimulation(DATA* data){
    data->M = 100;
    data->endTime = 10;
    data->cfl = 0.2;
    return 0;
}

double minDx(DATA* data){
    //here for equidistant grid:
    return (data->spaceField[data->M - 1] - data->spaceField[0]) / (data->M - 1);
}


int setDt(DATA* data){
    double lambda = eqSystemMaxEigenVal(data);
    double mDx = minDx(data);
    double dt = data->cfl*mDx/abs(lambda);
    data->dt = min(dt, data->endTime - data->time);
    return 0;
}



int updateSpaceDerivatives(DATA* data){
    //loop over all states:
    for (int iState=0; iState<data->nStateFields; iState++){
    //TODO: figure out boundary points !
    //loop over all grid nodes:
        for (int iNode=1; iNode<data->M-1; iNode++){
            lax_friedrichsX(data, iState, iNode);
        }
    }
    return 0;
}

int updateStates(DATA* data){
    //loop over all states:
    for (int iState=0; iState<data->nStateFields; iState++){
    //TODO: figure out boundary points !
    //loop over all grid nodes:
        for (int iNode=1; iNode<data->M-1; iNode++){
            lax_friedrichsT(data, iState, iNode);
        }
    }
    return 0;
}


int doStep(DATA* data){
    updateSpaceDerivatives(data);
    functionPDE(data);
    updateStates(data);
    return 0;
}

int main() {
    DATA dd;
    DATA* data = &dd;
    try{
        setupSimulation(data);
        setupArrayDimensions(data);
        initializeData(data);
        setupGrid(data);
        data->time = 0;
        setupModel(data);
        //do the numerics here!
        functionPDE(data);
        setDt(data);
        while (data->time < data->endTime) {
            doStep(data);
            data->time += data->dt;
            functionPDE(data);
            setDt(data);

        }

    }
    catch (int e){
        switch (e) { 
        case 0:
            puts("Inernal solver error\n");
            break;
        default:
            puts("Unknown error\n");
            break;
        }
    }


    puts("ahoj"); /* prints ahoj */
    getchar();
    freeData(data);
    return 0;
}

