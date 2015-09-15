#pragma once
#ifndef id3D63AD28_5E5E_4CDD_96B370DC5B2241A5
#define id3D63AD28_5E5E_4CDD_96B370DC5B2241A5


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


/*
 Mahder.Gebremedhin@liu.se  2014-02-19
*/

#include <simulation_data.h>


#ifdef __cplusplus
extern "C" {
#endif

typedef void (*FunctionType)(DATA *, threadData_t*);

void PM_Model_init(const char* , DATA* , threadData_t*, FunctionType*);

void PM_functionInitialEquations(int size, DATA* data, threadData_t* threadData, FunctionType*);

void PM_functionDAE(int size, DATA* data, threadData_t* threadData, FunctionType*);

void PM_functionODE(int size, DATA* data, threadData_t* threadData, FunctionType*);

void PM_functionAlg(int size, DATA* data, threadData_t* threadData, FunctionType*);

void dump_times();



#ifdef __cplusplus
}
#endif



#endif // header
