/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * This file contains constants and macros used by llvm_gen.
 * Macros deciding on bitsize for integers etc should be defined here.
 */
#ifndef _LLVM_GEN_MODELICA_CONSTANTS_H
#define _LLVM_GEN_MODELICA_CONSTANTS_H
//Comment out for debug messages.
#define DBG(...) //fprintf(stderr, __VA_ARGS__)

//Specifies how many bits we have for our integers in the enviroment.
//A macro (not a file-scope `const`) so this header can be included in more
//than one translation unit without colliding at link time, and so it is
//evaluated where modelica_integer is in scope rather than here.
#define NBITS_MODELICA_INTEGER (sizeof(modelica_integer) * 8)

#ifdef __cplusplus
extern "C" {
#endif
enum {
	MODELICA_INTEGER = 1,
	MODELICA_BOOLEAN = 2,
	MODELICA_REAL = 3,
	MODELICA_METATYPE = 4,
	MODELICA_TUPLE = 5,
	MODELICA_VOID = 6,
	/* Special pointer types */
	MODELICA_INTEGER_PTR = 11,
	MODELICA_BOOLEAN_PTR = 22,
	MODELICA_REAL_PTR = 33,
	MODELICA_METATYPE_PTR = 44,
	MODELICA_TUPLE_PTR = 55
  };
#ifdef __cplusplus
}
#endif
#endif
