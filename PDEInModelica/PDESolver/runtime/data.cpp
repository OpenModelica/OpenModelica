/*
 * data.c
 *
 *  Created on: 2.7.2013
 *      Author: janek
 */
#include"stdio.h"
#include"stdlib.h"
#include "data.h"



int initializeData(DATA *d)
{
	int M = d->M;
	d->domainRange			= (DoublePair*)calloc(d->nDomainSegments,sizeof(DoublePair));
	d->stateFields 			= (double*)calloc(M*d->nStateFields,sizeof(double));
	d->stateFields[M*(d->nStateFields - 1) + 4] = 2.0;
	d->stateFieldsDerTime 	= (double*)calloc(M*d->nStateFields,sizeof(double));
	d->stateFieldsDerSpace 	= (double*)calloc(M*d->nStateFields,sizeof(double));
	d->algebraicFields 		= (double*)calloc(M*d->nAlgebraicFields,sizeof(double));
	d->parameterFields 		= (double*)calloc(M*d->nParameterFields,sizeof(double));
	d->spaceField 			= (double*)calloc(M,sizeof(double));
	d->isBc 				= (int*)calloc(2*d->nStateFields,sizeof(int));
	d->parameters			= (double*)calloc(d->nParameters,sizeof(double));
	d->time = 0;
	return 0;
}

int freeData(DATA *d)
{
	free(d->stateFields);
	free(d->stateFieldsDerTime);
	free(d->stateFieldsDerSpace);
	free(d->algebraicFields);
	free(d->parameterFields);
	free(d->spaceField);
	free(d->isBc);
	free(d->parameters);
	return 0;
}
