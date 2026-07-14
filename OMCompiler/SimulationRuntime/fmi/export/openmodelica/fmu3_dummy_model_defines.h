/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#ifndef FMU3_DUMMY_MODEL_DEFINES_H
#define FMU3_DUMMY_MODEL_DEFINES_H

#define MODEL_GUID "DUMMY-GUID"

/* Two reals: the state at index 0 and its derivative at index 1 (see
 * STATESDERIVATIVES below), so the dummy defines are internally consistent
 * when fmu3_model_interface.c is compiled against this placeholder. */
#define NUMBER_OF_REALS             2
#define NUMBER_OF_STATES            1
#define NUMBER_OF_REAL_INPUTS       1
#define NUMBER_OF_INTEGERS          1
#define NUMBER_OF_BOOLEANS          1
#define NUMBER_OF_STRINGS           1
#define NUMBER_OF_EVENT_INDICATORS  1
#define NUMBER_OF_EXTERNALFUNCTIONS 1
#define NUMBER_OF_EXTERNALOBJECTS   1
#define NUMBER_OF_CLOCKS            1

#define FMI3_REAL_VR_OFFSET           0
#define FMI3_INTEGER_VR_OFFSET        (NUMBER_OF_REALS)
#define FMI3_BOOLEAN_VR_OFFSET        (NUMBER_OF_REALS + NUMBER_OF_INTEGERS)
#define FMI3_STRING_VR_OFFSET         (NUMBER_OF_REALS + NUMBER_OF_INTEGERS + NUMBER_OF_BOOLEANS)
#define FMI3_BINARY_VR_OFFSET         (NUMBER_OF_REALS + NUMBER_OF_INTEGERS + NUMBER_OF_BOOLEANS + NUMBER_OF_STRINGS)
#define FMI3_CLOCK_VR_OFFSET          (NUMBER_OF_REALS + NUMBER_OF_INTEGERS + NUMBER_OF_BOOLEANS + NUMBER_OF_STRINGS + NUMBER_OF_EXTERNALOBJECTS)
#define FMI3_TIME_VR                  (NUMBER_OF_REALS + NUMBER_OF_INTEGERS + NUMBER_OF_BOOLEANS + NUMBER_OF_STRINGS + NUMBER_OF_EXTERNALOBJECTS + NUMBER_OF_CLOCKS)
#define FMI3_EVENT_INDICATOR_VR_START (FMI3_TIME_VR + 1)

#define STATES            { 0 }
#define STATESDERIVATIVES { 1 }

#endif /* FMU3_DUMMY_MODEL_DEFINES_H */
