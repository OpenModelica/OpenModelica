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


#ifndef DIVISION_H
#define DIVISION_H

#include "openmodelica.h"

/* #define CHECK_NAN */
#ifdef CHECK_NAN
#define DIVISION(a,b,c) (((b) != 0) ? (isnan_error(((a) / (b)), c, __FILE__, __LINE__)) : ((a) / division_error(b, c, __FILE__, __LINE__)))
#else
#define DIVISION(a,b,c) (((b) != 0) ? ((a) / (b)) : ((a==0)?a:((a) / division_error_time(b, c, time, __FILE__, __LINE__,data->simulationInfo.noThrowDivZero?1:0))))
#endif
#define DIVISIONNOTIME(a,b,c) (((b) != 0) ? ((a) / (b)) : ((a==0)?a:((a) / division_error(b, c, __FILE__, __LINE__))))

modelica_real division_error_time(modelica_real b, const char* division_str, modelica_real time, const char* file, long line, modelica_boolean noThrow);
modelica_real division_error(modelica_real b, const char* division_str, const char* file, long line);
modelica_real isnan_error(modelica_real b, const char* division_str, const char* file, long line);

#endif
