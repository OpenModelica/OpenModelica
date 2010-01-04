/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/* File: simulation_runtime.h
 *
 * Description: This file is a C++ header file for the simulation runtime.
 * It contains solver functions and other simulation runtime specific functions
 */

#ifndef _SIMULATION_EVENTS_H
#define _SIMULATION_EVENTS_H

int initializeEventData();
void deinitializeEventData();

int checkForDiscreteVarChanges();
void calcEnabledZeroCrossings();
void CheckForNewEvents(double *t);
void CheckForInitialEvents(double *t);
void checkForInitialZeroCrossings(long*jroot);
void StartEventIteration(double *t);
void StateEventHandler(long jroot[], double *t);
void AddEvent(long);

void saveall();
void save(double & var);
double pre(double & var);
bool edge(double& var);
bool change(double& var);

double Sample(double t, double start ,double interval);
double sample(double start ,double interval);

double Less(double a,double b);
double LessEq(double a,double b);
double Greater(double a,double b);
double GreaterEq(double a,double b);

extern long inUpdate;

#define ZEROCROSSING(ind,exp) gout[ind] = (zeroCrossingEnabled[ind])?double(zeroCrossingEnabled[ind])*exp:1.0


#define RELATION(res,x,y,op1,op2)  { \
	double res1,res2,*statesBackup,*statesDerivativesBackup,*algebraicsBackup,timeBackup;\
	if (!inUpdate) { \
		res = (x) op1 (y); \
	}\
	else {\
		res = (x) op2 (y); \
		if (!res && ((x) op2##= (y))) { \
			timeBackup = localData->timeValue;\
			localData->timeValue = localData->oldTime;\
			statesBackup = localData->states; \
			localData->states = localData->oldStates; \
			statesDerivativesBackup = localData->statesDerivatives; \
			localData->statesDerivatives = localData->oldStatesDerivatives; \
			algebraicsBackup = localData->algebraics; \
			localData->algebraics = localData->oldAlgebraics; \
			res1 = (x)-(y);\
			localData->timeValue = localData->oldTime2;\
			localData->states = localData->oldStates2; \
			localData->statesDerivatives = localData->oldStatesDerivatives2; \
			localData->algebraics = localData->oldAlgebraics2; \
			res2 = (x)-(y);\
			localData->timeValue = timeBackup;\
			localData->states = statesBackup; \
			localData->statesDerivatives = statesDerivativesBackup; \
			localData->algebraics = algebraicsBackup; \
			res = res1 op2##= res2; \
		}\
	}\
}

#define RELATIONGREATER(res,x,y)    RELATION(res,x,y,>,>)
#define RELATIONLESS(res,x,y)       RELATION(res,x,y,<,<)
#define RELATIONGREATEREQ(res,x,y)  RELATION(res,x,y,>=,>)
#define RELATIONLESSEQ(res,x,y)     RELATION(res,x,y,<=,<)

#define noEvent(arg) arg
#define initial() localData->init

int
function_zeroCrossing(long *neqm, double *t, double *x, long *ng, double *gout, double *rpar, long* ipar);

int
handleZeroCrossing(long index);

int
function_when(int i);

extern long* zeroCrossingEnabled;


#define REL(res,x,y,op1)  { \
		res = (x) op1 (y); \
}

#define REGREATER(res,x,y)    REL(res,x,y,>)
#define RELESS(res,x,y)       REL(res,x,y,<)
#define REGREATEREQ(res,x,y)  REL(res,x,y,>=)
#define RELESSEQ(res,x,y)     REL(res,x,y,<=)

int
function_onlyZeroCrossings(double* gout ,double* t);

int CheckForNewEvent(int flag);

void EventHandle();

void FindRoot();

double BiSection(double*, double*, double*, double*, long int*);

int CheckZeroCrossings(long int*);

#define INTERVAL 1
#define NOINTERVAL 0

extern double TOL;

#endif
