/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
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
 * from Linköping University, either from the above address,
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

#ifndef DASSL_H
#define DASSL_H

#include "solver_main.h"

#define DDASRT ddasrt_

static const unsigned int maxOrder = 5;
static const unsigned int numStatistics = 5;
static const unsigned int infoLength = 15;

enum DASSL_METHOD
{
  DASSL_UNKNOWN = 0,
  DASSL_RT,
  DASSL_WORT,
  DASSL_SYMJAC,
  DASSL_NUMJAC,
  DASSL_COLOREDSYMJAC,
  DASSL_INTERNALNUMJAC,
  DASSL_TEST,
  DASSL_MAX
};

typedef struct DASSL_DATA{

  int dasslMethod;

  unsigned int* dasslStatistics;
  unsigned int* dasslStatisticsTmp;

  fortran_integer* info;

  fortran_integer idid;
  fortran_integer* ipar;
  double** rpar;
  /* size of work arrays for DASSL */
  fortran_integer liw;
  fortran_integer lrw;
  /* work arrays for DASSL */
  fortran_integer *iwork;
  double *rwork;
  double *rtol;
  double *atol;

  fortran_integer ngdummy;
  fortran_integer ng;
  fortran_integer *jroot;

  /* varibales used in jacobian calculation */
  double sqrteps;
  double *ysave;
  double *delta_hh;
  double *newdelta;

} DASSL_DATA;

/* main dassl function to make a step */
int
dasrt_step(DATA* simData, SOLVER_INFO* solverInfo);


/* initial main dassl Data */
int
dasrt_initial(DATA* simData, SOLVER_INFO* solverInfo, DASSL_DATA *dasslData);

/* deinitial main dassl Data */
int
dasrt_deinitial(DASSL_DATA *dasslData);

#endif
