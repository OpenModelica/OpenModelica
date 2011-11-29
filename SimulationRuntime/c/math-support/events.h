/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file events.h
 */

#ifndef _EVENTS_H_
#define _EVENTS_H_

#include "simulation_data.h"
#include "solver_main.h"
#include "list.h"

#ifdef __cplusplus
extern "C" {
#endif

  int initializeEventData();
  void deinitializeEventData();

  double BiSection(_X_DATA* data, double*, double*, double*, double*, LIST*, LIST*);

  int CheckZeroCrossings(_X_DATA *data, LIST *list, LIST*);

  void storeStartValues(_X_DATA *data);
  void storePreValues(_X_DATA *data);
  void storeStartValuesParam(_X_DATA *data);
  void storeInitialValuesParam(_X_DATA *data);
  /* void printAllPreValues(); */
  void resetAllHelpVars(_X_DATA *data);

  double Sample(double t, double start, double interval);
  double sample(_X_DATA *data, double start, double interval, int hindex);
  void initSample(_X_DATA *data, double start, double stop);

  double Less(double a, double b);
  double LessEq(double a, double b);
  double Greater(double a, double b);
  double GreaterEq(double a, double b);

  void checkTermination(_X_DATA *data);
  int checkForSampleEvent(_X_DATA *data, SOLVER_INFO* solverInfo);

  double getNextSampleTimeFMU(_X_DATA *data);

  static const int IterationMax = 200;

#define ZEROCROSSING(ind,exp) { \
  data->simulationInfo.zeroCrossings[ind] = exp; \
  }

#define RELATIONTOZC(res,exp1,exp2,index,op_w,op) { \
  if (index == -1){ \
  res = ((exp1) op (exp2)); \
  }else{ \
  res = data->simulationInfo.backupRelations[index];} \
  }
#define SAVEZEROCROSS(res,exp1,exp2,index,op_w,op) { \
  if (index == -1){ \
  res = ((exp1) op (exp2)); \
  } else{ \
  res = ((exp1) op (exp2)); \
  data->simulationInfo.backupRelations[index] = ((exp1) op (exp2)); \
  }\
  }


  int function_onlyZeroCrossings(_X_DATA *data, double* gout, double* t);
  int CheckForNewEvent(_X_DATA *data, modelica_boolean *sampleactived, double* currentTime);
  int EventHandle(_X_DATA *data, int, LIST *eventList);
  void FindRoot(_X_DATA *data, double*, LIST *eventList);
  int checkForDiscreteChanges(_X_DATA *data);
  void SaveZeroCrossings(_X_DATA *data);
  void SaveZeroCrossingsAfterEvent(_X_DATA *data);
  void initializeZeroCrossings(_X_DATA *data);
  void correctDirectionZeroCrossings(_X_DATA *data);
  int activateSampleEvents(_X_DATA *data);
  int function_updateSample(_X_DATA *data);

#define INTERVAL 1
#define NOINTERVAL 0

  extern double TOL;

  void debugPrintHelpVars();
  void deactivateSampleEvent();
  void deactivateSampleEventsandEquations();
  void debugSampleEvents();

#ifdef __cplusplus
}
#endif

#endif
