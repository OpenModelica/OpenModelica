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
extern const unsigned int LV_NONE;
extern const unsigned int LV_STATS;
extern const unsigned int LV_INIT;
extern const unsigned int LV_SOLVER;
extern const unsigned int LV_JAC;
extern const unsigned int LV_ENDJAC;
extern const unsigned int LV_NONLIN_SYS;
extern const unsigned int LV_EVENTS;
extern const unsigned int LV_ZEROCROSSINGS;
extern const unsigned int LV_DEBUG;
extern const unsigned int LV_LOG_RES_INIT;

#define MSG_H(type, stream)    {fprintf(stream, "%s | [line] %d | [file] %s\n", type, __LINE__, __FILE__); fflush(NULL);}
#define MSG(type, stream, ...) {fprintf(stream, "%s > ", type); fprintf(stream, __VA_ARGS__); fprintf(stream, "\n"); fflush(NULL);}

#define INFO(...)        {MSG("info   ", stdout, __VA_ARGS__);}
#define INFO_AL(...)     {MSG("       ", stdout, __VA_ARGS__);}

#define WARNING(...)     {MSG("warning", stdout, __VA_ARGS__);}
#define WARNING_AL(...)  {INFO_AL(__VA_ARGS__);}

#define THROW(...)       {MSG_H("throw  ", stderr); MSG("       ", stderr, __VA_ARGS__); longjmp(globalJmpbuf, 1);}
#define ASSERT(exp, ...) {if(!(exp)){MSG_H("assert ", stderr); MSG("       ", stderr, __VA_ARGS__); longjmp(globalJmpbuf, 1);}}

#define DEBUG_FLAG(flag) (flag & globalDebugFlags)
#define DEBUG_INFO(flag, ...)    {if(DEBUG_FLAG(flag)){MSG_H("debug  ", stdout); INFO(__VA_ARGS__);}}
#define DEBUG_INFO_AL(flag, ...) {if(DEBUG_FLAG(flag)) INFO_AL(__VA_ARGS__);}

#ifdef __cplusplus
}
#endif

#endif
