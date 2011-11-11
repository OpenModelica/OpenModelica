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


#ifndef ERROR_H
#define ERROR_H

#include <setjmp.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/* global JumpBuffer */
extern jmp_buf globalJmpbuf;

/* global debug-flags */
extern unsigned int globalDebugFlags;

/* debug options */
extern const unsigned int DF_NONE;
extern const unsigned int DF_SOLVER;

#define MSG(type, stream, msg, ...) {fprintf(stream,"%s |  %d | %s\n        |> ", type, __LINE__, __FILE__); fprintf(stream, msg, __VA_ARGS__); fprintf(stream, "\n"); fflush(NULL);}

#define INFO(msg, ...)        {MSG("info   ", stdout, msg, __VA_ARGS__);}
#define WARNING(msg, ...)     {MSG("warning", stdout, msg, __VA_ARGS__);}
#define THROW(msg, ...)       {MSG("error  ", stderr, msg, __VA_ARGS__); longjmp(globalJmpbuf, 1);}
#define ASSERT(exp, msg, ...) {if(!exp){MSG("assert ", stderr, msg, __VA_ARGS__); longjmp(globalJmpbuf, 1);}}

#define DEBUG_INFO(flag, msg, ...) {if(flag & globalDebugFlags) INFO(msg, __VA_ARGS__);}

#ifdef __cplusplus
}
#endif

#endif
