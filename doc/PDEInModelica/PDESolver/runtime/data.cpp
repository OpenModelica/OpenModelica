/*
 * data.c
 *
 *  Created on: 2.7.2013
 *      Author: janek
 */
#include <iostream>
//#include <fstream>
//#include"stdio.h"
#include"stdlib.h"
#include "model_data.h"
#include "runtime_data.h"

//using namespace std;


int initializeData(MODEL_DATA *d)
{
    int M = d->M;
    d->domainRange              = (DoublePair*)calloc(d->nDomainSegments,sizeof(DoublePair));
    d->stateFields              = (double*)calloc(M*d->nStateFields,sizeof(double));
    d->stateFieldsDerTime       = (double*)calloc(M*d->nStateFields,sizeof(double));
    d->stateFieldsDerSpace      = (double*)calloc(M*d->nStateFields,sizeof(double));
    d->algebraicFields          = (double*)calloc(M*d->nAlgebraicFields,sizeof(double));
    d->algebraicFieldsDerSpace  = (double*)calloc(M*d->nAlgebraicFields,sizeof(double));
    d->parameterFields          = (double*)calloc(M*d->nParameterFields,sizeof(double));
    d->spaceField               = (double*)calloc(M,sizeof(double));
    d->isBc                     = (int*)calloc(2*d->nStateFields,sizeof(int));
    d->parameters               = (double*)calloc(d->nParameters,sizeof(double));
    d->time = 0;
    return 0;
}

int freeData(MODEL_DATA *d)
{
    free(d->stateFields);
    free(d->stateFieldsDerTime);
    free(d->stateFieldsDerSpace);
    free(d->algebraicFields);
    free(d->algebraicFieldsDerSpace);
    free(d->parameterFields);
    free(d->spaceField);
    free(d->isBc);
    free(d->parameters);
    return 0;
}

int writeStates(RUNTIME_DATA* rd)
{
    MODEL_DATA* md = rd->modelData;
    int M = md->M;
    ofstream* file = &rd->resultsFile;
    file->open("../results.txt",ofstream::trunc);
    for (int iNode = 0; iNode<M; iNode++){
        *file << md->spaceField[iNode];
        for (int iState = 0; iState < md->nStateFields; iState++)
            *file << "\t" << md->stateFields[iState*M + iNode];
        *file << "\n";
    }
    file->close();
    return 0;
}
