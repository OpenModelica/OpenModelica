/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link?ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link?ping, Sweden.
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
 * from Link?ping University, either from the above address,
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

#define DDASRT ddasrt_

static const unsigned int maxOrder = 5;
static const unsigned int noStatistics = 5;
static const unsigned int infoLength = 15;


typedef struct DASSL_DATA{
	unsigned int* dasslStatistics;
	unsigned int* dasslStatisticsTmp;
	modelica_boolean reset;

	fortran_integer* info;

	fortran_integer idid;
	fortran_integer* ipar;
	void* rpar;
	/* size of work arrays for DASSL */
	fortran_integer liw;
	fortran_integer lrw;
	/* work arrays for DASSL */
	fortran_integer *iwork;
	double *rwork;

	fortran_integer NG_var;
	fortran_integer *jroot;

	/* Used when calculating residual for its side effects. (alg. var calc) */
	double *dummy_delta;


} DASSL_DATA;

/* main dassl function to make a step */
int
dasrt_step(_X_DATA* simData, SOLVER_INFO* solverInfo);


/* initial main dassl Data */
int
dasrt_initial(_X_DATA* simData, SOLVER_INFO* solverInfo, DASSL_DATA *dasslData);



#endif
