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

#define USE_ASSERTS

/* global JumpBuffer */
extern jmp_buf globalJmpbuf;

/* global debug-flags */
extern unsigned int globalDebugFlags;

/* debug options */
extern const unsigned int LOG_NONE;
extern const unsigned int LOG_STATS;
extern const unsigned int LOG_INIT;
extern const unsigned int LOG_SOLVER;
extern const unsigned int LOG_JAC;
extern const unsigned int LOG_ENDJAC;
extern const unsigned int LOG_NONLIN_SYS;
extern const unsigned int LOG_EVENTS;
extern const unsigned int LOG_ZEROCROSSINGS;
extern const unsigned int LOG_DEBUG;
extern const unsigned int LOG_RES_INIT;

#define MSG_H(type, stream)   do{fprintf(stream, "%s | [line] %d | [file] %s\n", type, __LINE__, __FILE__); fflush(NULL);}while(0)
#define MSG_T(type, stream)   do{fprintf(stream, "%s | ", type);}while(0)
#define MSG_F(stream)         do{fprintf(stream, "\n"); fflush(NULL);}while(0)

#define MSG(type, stream, msg)    do{MSG_T(type, stream); fprintf(stream, msg); MSG_F(stream);}while(0)
#define MSG1(type, stream, msg, a)    do{MSG_T(type, stream); fprintf(stream, msg, a); MSG_F(stream);}while(0)
#define MSG2(type, stream, msg, a, b)    do{MSG_T(type, stream); fprintf(stream, msg, a, b); MSG_F(stream);}while(0)
#define MSG3(type, stream, msg, a, b, c)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c); MSG_F(stream);}while(0)
#define MSG4(type, stream, msg, a, b, c, d)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c, d); MSG_F(stream);}while(0)
#define MSG5(type, stream, msg, a, b, c, d, e)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e); MSG_F(stream);}while(0)
#define MSG6(type, stream, msg, a, b, c, d, e, f)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f); MSG_F(stream);}while(0)
#define MSG7(type, stream, msg, a, b, c, d, e, f, g)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g); MSG_F(stream);}while(0)
#define MSG8(type, stream, msg, a, b, c, d, e, f, g, h)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g, h); MSG_F(stream);}while(0)
#define MSG9(type, stream, msg, a, b, c, d, e, f, g, h, i)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g, h, i); MSG_F(stream);}while(0)
#define MSG10(type, stream, msg, a, b, c, d, e, f, g, h, i, j)    do{MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g, h, i, j); MSG_F(stream);}while(0)

#define MSG_NEL(type, stream, msg)   do{MSG_T(type, stream); fprintf(stream, msg);}while(0)
#define MSG1_NEL(type, stream, msg, a)   do{MSG_T(type, stream); fprintf(stream, msg, a);}while(0)

#define MSG_NELA(stream, msg)   do{fprintf(stream, msg);}while(0)
#define MSG1_NELA(stream, msg, a)   do{fprintf(stream, msg, a);}while(0)

#define INFO(msg)        do{MSG("info   ", stdout, msg);}while(0)
#define INFO1(msg, a)        do{MSG1("info   ", stdout, msg, a);}while(0)
#define INFO2(msg, a, b)        do{MSG2("info   ", stdout, msg, a, b);}while(0)
#define INFO3(msg, a, b, c)        do{MSG3("info   ", stdout, msg, a, b, c);}while(0)
#define INFO4(msg, a, b, c, d)        do{MSG4("info   ", stdout, msg, a, b, c, d);}while(0)
#define INFO5(msg, a, b, c, d, e)        do{MSG5("info   ", stdout, msg, a, b, c, d, e);}while(0)
#define INFO6(msg, a, b, c, d, e, f)        do{MSG6("info   ", stdout, msg, a, b, c, d, e, f);}while(0)
#define INFO7(msg, a, b, c, d, e, f, g)        do{MSG7("info   ", stdout, msg, a, b, c, d, e, f, g);}while(0)
#define INFO8(msg, a, b, c, d, e, f, g, h)        do{MSG8("info   ", stdout, msg, a, b, c, d, e, f, g, h);}while(0)
#define INFO9(msg, a, b, c, d, e, f, g, h, i)        do{MSG9("info   ", stdout, msg, a, b, c, d, e, f, g, h, i);}while(0)
#define INFO10(msg, a, b, c, d, e, f, g, h, i, j)        do{MSG10("info   ", stdout, msg, a, b, c, d, e, f, g, h, i, j);}while(0)

#define INFO_AL(msg)     do{MSG("       ", stdout, msg);}while(0)
#define INFO_AL1(msg, a)     do{MSG1("       ", stdout, msg, a);}while(0)
#define INFO_AL2(msg, a, b)     do{MSG2("       ", stdout, msg, a, b);}while(0)
#define INFO_AL3(msg, a, b, c)     do{MSG3("       ", stdout, msg, a, b, c);}while(0)
#define INFO_AL4(msg, a, b, c, d)     do{MSG4("       ", stdout, msg, a, b, c, d);}while(0)
#define INFO_AL5(msg, a, b, c, d, e)     do{MSG5("       ", stdout, msg, a, b, c, d, e);}while(0)
#define INFO_AL6(msg, a, b, c, d, e, f)     do{MSG6("       ", stdout, msg, a, b, c, d, e, f);}while(0)
#define INFO_AL7(msg, a, b, c, d, e, f, g)     do{MSG7("       ", stdout, msg, a, b, c, d, e, f, g);}while(0)
#define INFO_AL8(msg, a, b, c, d, e, f, g, h)     do{MSG8("       ", stdout, msg, a, b, c, d, e, f, g, h);}while(0)
#define INFO_AL9(msg, a, b, c, d, e, f, g, h, i)     do{MSG9("       ", stdout, msg, a, b, c, d, e, f, g, h, i);}while(0)
#define INFO_AL10(msg, a, b, c, d, e, f, g, h, i, j)     do{MSG10("       ", stdout, msg, a, b, c, d, e, f, g, h, i, j);}while(0)

#define WARNING(msg)     do{MSG("warning", stdout, msg);}while(0)
#define WARNING1(msg, a)     do{MSG1("warning", stdout, msg, a);}while(0)
#define WARNING2(msg, a, b)     do{MSG2("warning", stdout, msg, a, b);}while(0)
#define WARNING3(msg, a, b, c)     do{MSG3("warning", stdout, msg, a, b, c);}while(0)
#define WARNING4(msg, a, b, c, d)     do{MSG4("warning", stdout, msg, a, b, c, d);}while(0)
#define WARNING5(msg, a, b, c, d, e)     do{MSG5("warning", stdout, msg, a, b, c, d, e);}while(0)
#define WARNING6(msg, a, b, c, d, e, f)     do{MSG6("warning", stdout, msg, a, b, c, d, e, f);}while(0)
#define WARNING7(msg, a, b, c, d, e, f, g)     do{MSG7("warning", stdout, msg, a, b, c, d, e, f, g);}while(0)
#define WARNING8(msg, a, b, c, d, e, f, g, h)     do{MSG8("warning", stdout, msg, a, b, c, d, e, f, g, h);}while(0)
#define WARNING9(msg, a, b, c, d, e, f, g, h, i)     do{MSG9("warning", stdout, msg, a, b, c, d, e, f, g, h, i);}while(0)
#define WARNING10(msg, a, b, c, d, e, f, g, h, i, j)     do{MSG10("warning", stdout, msg, a, b, c, d, e, f, g, h, i, j);}while(0)

#define WARNING_AL(msg)  do{INFO_AL(msg);}while(0)
#define WARNING_AL1(msg, a)  do{INFO_AL1(msg, a);}while(0)
#define WARNING_AL2(msg, a, b)  do{INFO_AL2(msg, a, b);}while(0)
#define WARNING_AL3(msg, a, b, c)  do{INFO_AL3(msg, a, b, c);}while(0)
#define WARNING_AL4(msg, a, b, c, d)  do{INFO_AL4(msg, a, b, c, d);}while(0)
#define WARNING_AL5(msg, a, b, c, d, e)  do{INFO_AL5(msg, a, b, c, d, e);}while(0)
#define WARNING_AL6(msg, a, b, c, d, e, f)  do{INFO_AL6(msg, a, b, c, d, e, f);}while(0)
#define WARNING_AL7(msg, a, b, c, d, e, f, g)  do{INFO_AL7(msg, a, b, c, d, e, f, g);}while(0)
#define WARNING_AL8(msg, a, b, c, d, e, f, g, h)  do{INFO_AL8(msg, a, b, c, d, e, f, g, h);}while(0)
#define WARNING_AL9(msg, a, b, c, d, e, f, g, h, i)  do{INFO_AL9(msg, a, b, c, d, e, f, g, h, i);}while(0)
#define WARNING_AL10(msg, a, b, c, d, e, f, g, h, i, j)  do{INFO_AL10(msg, a, b, c, d, e, f, g, h, i, j);}while(0)

#define THROW(msg)       do{MSG_H("throw  ", stderr); MSG("       ", stderr, msg); longjmp(globalJmpbuf, 1);}while(0)
#define THROW1(msg, a)       do{MSG_H("throw  ", stderr); MSG1("       ", stderr, msg, a); longjmp(globalJmpbuf, 1);}while(0)
#define THROW2(msg, a, b)       do{MSG_H("throw  ", stderr); MSG2("       ", stderr, msg, a, b); longjmp(globalJmpbuf, 1);}while(0)
#define THROW3(msg, a, b, c)       do{MSG_H("throw  ", stderr); MSG3("       ", stderr, msg, a, b, c); longjmp(globalJmpbuf, 1);}while(0)
#define THROW4(msg, a, b, c, d)       do{MSG_H("throw  ", stderr); MSG4("       ", stderr, msg, a, b, c, d); longjmp(globalJmpbuf, 1);}while(0)
#define THROW5(msg, a, b, c, d, e)       do{MSG_H("throw  ", stderr); MSG5("       ", stderr, msg, a, b, c, d, e); longjmp(globalJmpbuf, 1);}while(0)
#define THROW6(msg, a, b, c, d, e, f)       do{MSG_H("throw  ", stderr); MSG6("       ", stderr, msg, a, b, c, d, e, f); longjmp(globalJmpbuf, 1);}while(0)
#define THROW7(msg, a, b, c, d, e, f, g)       do{MSG_H("throw  ", stderr); MSG7("       ", stderr, msg, a, b, c, d, e, f, g); longjmp(globalJmpbuf, 1);}while(0)
#define THROW8(msg, a, b, c, d, e, f, g, h)       do{MSG_H("throw  ", stderr); MSG8("       ", stderr, msg, a, b, c, d, e, f, g, h); longjmp(globalJmpbuf, 1);}while(0)
#define THROW9(msg, a, b, c, d, e, f, g, h, i)       do{MSG_H("throw  ", stderr); MSG9("       ", stderr, msg, a, b, c, d, e, f, g, h, i); longjmp(globalJmpbuf, 1);}while(0)
#define THROW10(msg, a, b, c, d, e, f, g, h, i, j)       do{MSG_H("throw  ", stderr); MSG10("       ", stderr, msg, a, b, c, d, e, f, g, h, i, j); longjmp(globalJmpbuf, 1);}while(0)

#ifdef USE_ASSERTS
#define ASSERT(exp, msg) do{if(!(exp)){MSG_H("assert ", stderr); MSG("       ", stderr, msg); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT1(exp, msg, a) do{if(!(exp)){MSG_H("assert ", stderr); MSG1("       ", stderr, msg, a); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT2(exp, msg, a, b) do{if(!(exp)){MSG_H("assert ", stderr); MSG2("       ", stderr, msg, a, b); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT3(exp, msg, a, b, c) do{if(!(exp)){MSG_H("assert ", stderr); MSG3("       ", stderr, msg, a, b, c); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT4(exp, msg, a, b, c, d) do{if(!(exp)){MSG_H("assert ", stderr); MSG4("       ", stderr, msg, a, b, c, d); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT5(exp, msg, a, b, c, d, e) do{if(!(exp)){MSG_H("assert ", stderr); MSG5("       ", stderr, msg, a, b, c, d, e); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT6(exp, msg, a, b, c, d, e, f) do{if(!(exp)){MSG_H("assert ", stderr); MSG6("       ", stderr, msg, a, b, c, d, e, f); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT7(exp, msg, a, b, c, d, e, f, g) do{if(!(exp)){MSG_H("assert ", stderr); MSG7("       ", stderr, msg, a, b, c, d, e, f, g); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT8(exp, msg, a, b, c, d, e, f, g, h) do{if(!(exp)){MSG_H("assert ", stderr); MSG8("       ", stderr, msg, a, b, c, d, e, f, g, h); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT9(exp, msg, a, b, c, d, e, f, g, h, i) do{if(!(exp)){MSG_H("assert ", stderr); MSG9("       ", stderr, msg, a, b, c, d, e, f, g, h, i); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT10(exp, msg, a, b, c, d, e, f, g, h, i, j) do{if(!(exp)){MSG_H("assert ", stderr); MSG10("       ", stderr, msg, a, b, c, d, e, f, g, h, i, j); longjmp(globalJmpbuf, 1);}}while(0)
#else
#define ASSERT(exp, msg) 
#define ASSERT1(exp, msg, a) 
#define ASSERT2(exp, msg, a, b) 
#define ASSERT3(exp, msg, a, b, c) 
#define ASSERT4(exp, msg, a, b, c, d) 
#define ASSERT5(exp, msg, a, b, c, d, e) 
#define ASSERT6(exp, msg, a, b, c, d, e, f) 
#define ASSERT7(exp, msg, a, b, c, d, e, f, g) 
#define ASSERT8(exp, msg, a, b, c, d, e, f, g, h) 
#define ASSERT9(exp, msg, a, b, c, d, e, f, g, h, i) 
#define ASSERT10(exp, msg, a, b, c, d, e, f, g, h, i, j)
#endif

#define DEBUG_FLAG(flag) (flag & globalDebugFlags)
#define DEBUG_INFO(flag, msg)    do{if(DEBUG_FLAG(flag)) MSG("debug  ", stdout, msg);}while(0)
#define DEBUG_INFO1(flag, msg, a)    do{if(DEBUG_FLAG(flag)) MSG1("debug  ", stdout, msg, a);}while(0)
#define DEBUG_INFO2(flag, msg, a, b)    do{if(DEBUG_FLAG(flag)) MSG2("debug  ", stdout, msg, a, b);}while(0)
#define DEBUG_INFO3(flag, msg, a, b, c)    do{if(DEBUG_FLAG(flag)) MSG3("debug  ", stdout, msg, a, b, c);}while(0)
#define DEBUG_INFO4(flag, msg, a, b, c, d)    do{if(DEBUG_FLAG(flag)) MSG4("debug  ", stdout, msg, a, b, c, d);}while(0)
#define DEBUG_INFO5(flag, msg, a, b, c, d, e)    do{if(DEBUG_FLAG(flag)) MSG5("debug  ", stdout, msg, a, b, c, d, e);}while(0)
#define DEBUG_INFO6(flag, msg, a, b, c, d, e, f)    do{if(DEBUG_FLAG(flag)) MSG6("debug  ", stdout, msg, a, b, c, d, e, f);}while(0)
#define DEBUG_INFO7(flag, msg, a, b, c, d, e, f, g)    do{if(DEBUG_FLAG(flag)) MSG7("debug  ", stdout, msg, a, b, c, d, e, f, g);}while(0)
#define DEBUG_INFO8(flag, msg, a, b, c, d, e, f, g, h)    do{if(DEBUG_FLAG(flag)) MSG8("debug  ", stdout, msg, a, b, c, d, e, f, g, h);}while(0)
#define DEBUG_INFO9(flag, msg, a, b, c, d, e, f, g, h, i)    do{if(DEBUG_FLAG(flag)) MSG9("debug  ", stdout, msg, a, b, c, d, e, f, g, h, i);}while(0)
#define DEBUG_INFO10(flag, msg, a, b, c, d, e, f, g, h, i, j)   do{if(DEBUG_FLAG(flag)) MSG10("debug  ", stdout, msg, a, b, c, d, e, f, g, h, i, j);}while(0)

#define DEBUG_INFO_NEL(flag, msg)   do{if(DEBUG_FLAG(flag)) MSG_NEL("debug  ", stdout, msg);}while(0)
#define DEBUG_INFO_NEL1(flag, msg, a)   do{if(DEBUG_FLAG(flag)) MSG1_NEL("debug  ", stdout, msg, a);}while(0)

#define DEBUG_INFO_NELA(flag, msg)   do{if(DEBUG_FLAG(flag)) MSG_NELA(stdout, msg);}while(0)
#define DEBUG_INFO_NELA1(flag, msg, a)   do{if(DEBUG_FLAG(flag)) MSG1_NELA(stdout, msg, a);}while(0)

#define DEBUG_INFO_AL(flag, msg) do{if(DEBUG_FLAG(flag)) INFO_AL(msg);}while(0)
#define DEBUG_INFO_AL1(flag, msg, a) do{if(DEBUG_FLAG(flag)) INFO_AL1(msg, a);}while(0)
#define DEBUG_INFO_AL2(flag, msg, a, b) do{if(DEBUG_FLAG(flag)) INFO_AL2(msg, a, b);}while(0)
#define DEBUG_INFO_AL3(flag, msg, a, b, c) do{if(DEBUG_FLAG(flag)) INFO_AL3(msg, a, b, c);}while(0)
#define DEBUG_INFO_AL4(flag, msg, a, b, c, d) do{if(DEBUG_FLAG(flag)) INFO_AL4(msg, a, b, c, d);}while(0)
#define DEBUG_INFO_AL5(flag, msg, a, b, c, d, e) do{if(DEBUG_FLAG(flag)) INFO_AL5(msg, a, b, c, d, e);}while(0)
#define DEBUG_INFO_AL6(flag, msg, a, b, c, d, e, f) do{if(DEBUG_FLAG(flag)) INFO_AL6(msg, a, b, c, d, e, f);}while(0)
#define DEBUG_INFO_AL7(flag, msg, a, b, c, d, e, f, g) do{if(DEBUG_FLAG(flag)) INFO_AL7(msg, a, b, c, d, e, f, g);}while(0)
#define DEBUG_INFO_AL8(flag, msg, a, b, c, d, e, f, g, h) do{if(DEBUG_FLAG(flag)) INFO_AL8(msg, a, b, c, d, e, f, g, h);}while(0)
#define DEBUG_INFO_AL9(flag, msg, a, b, c, d, e, f, g, h, i) do{if(DEBUG_FLAG(flag)) INFO_AL9(msg, a, b, c, d, e, f, g, h, i);}while(0)
#define DEBUG_INFO_AL10(flag, msg, a, b, c, d, e, f, g, h, i, j) do{if(DEBUG_FLAG(flag)) INFO_AL10(msg, a, b, c, d, e, f, g, h, i, j);}while(0)

#ifdef __cplusplus
}
#endif

#endif
