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

#define MSG_T(type, stream)    fprintf(stream, "%s | ", type)
#define MSG_F(stream)    fprintf(stream, "\n"); fflush(NULL)
#define MSG(type, stream, msg)    {MSG_T(type, stream); fprintf(stream, msg); MSG_F(stream);}
#define MSG1(type, stream, msg, a)    {MSG_T(type, stream); fprintf(stream, msg, a); MSG_F(stream);}
#define MSG2(type, stream, msg, a, b)    {MSG_T(type, stream); fprintf(stream, msg, a, b); MSG_F(stream);}
#define MSG3(type, stream, msg, a, b, c)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c); MSG_F(stream);}
#define MSG4(type, stream, msg, a, b, c, d)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c, d); MSG_F(stream);}
#define MSG5(type, stream, msg, a, b, c, d, e)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e); MSG_F(stream);}
#define MSG6(type, stream, msg, a, b, c, d, e, f)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f); MSG_F(stream);}
#define MSG7(type, stream, msg, a, b, c, d, e, f, g)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g); MSG_F(stream);}
#define MSG8(type, stream, msg, a, b, c, d, e, f, g, h)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g, h); MSG_F(stream);}
#define MSG9(type, stream, msg, a, b, c, d, e, f, g, h, i)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g, h, i); MSG_F(stream);}
#define MSG10(type, stream, msg, a, b, c, d, e, f, g, h, i, j)    {MSG_T(type, stream); fprintf(stream, msg, a, b, c, d, e, f, g, h, i, j); MSG_F(stream);}

#define INFO(msg)        {MSG("info   ", stdout, msg);}
#define INFO1(msg, a)        {MSG1("info   ", stdout, msg, a);}
#define INFO2(msg, a, b)        {MSG2("info   ", stdout, msg, a, b);}
#define INFO3(msg, a, b, c)        {MSG3("info   ", stdout, msg, a, b, c);}
#define INFO4(msg, a, b, c, d)        {MSG4("info   ", stdout, msg, a, b, c, d);}
#define INFO5(msg, a, b, c, d, e)        {MSG5("info   ", stdout, msg, a, b, c, d, e);}
#define INFO6(msg, a, b, c, d, e, f)        {MSG6("info   ", stdout, msg, a, b, c, d, e, f);}
#define INFO7(msg, a, b, c, d, e, f, g)        {MSG7("info   ", stdout, msg, a, b, c, d, e, f, g);}
#define INFO8(msg, a, b, c, d, e, f, g, h)        {MSG8("info   ", stdout, msg, a, b, c, d, e, f, g, h);}
#define INFO9(msg, a, b, c, d, e, f, g, h, i)        {MSG9("info   ", stdout, msg, a, b, c, d, e, f, g, h, i);}
#define INFO10(msg, a, b, c, d, e, f, g, h, i, j)        {MSG10("info   ", stdout, msg, a, b, c, d, e, f, g, h, i, j);}

#define INFO_AL(msg)     {MSG("       ", stdout, msg);}
#define INFO_AL1(msg, a)     {MSG1("       ", stdout, msg, a);}
#define INFO_AL2(msg, a, b)     {MSG2("       ", stdout, msg, a, b);}
#define INFO_AL3(msg, a, b, c)     {MSG3("       ", stdout, msg, a, b, c);}
#define INFO_AL4(msg, a, b, c, d)     {MSG4("       ", stdout, msg, a, b, c, d);}
#define INFO_AL5(msg, a, b, c, d, e)     {MSG5("       ", stdout, msg, a, b, c, d, e);}
#define INFO_AL6(msg, a, b, c, d, e, f)     {MSG6("       ", stdout, msg, a, b, c, d, e, f);}
#define INFO_AL7(msg, a, b, c, d, e, f, g)     {MSG7("       ", stdout, msg, a, b, c, d, e, f, g);}
#define INFO_AL8(msg, a, b, c, d, e, f, g, h)     {MSG8("       ", stdout, msg, a, b, c, d, e, f, g, h);}
#define INFO_AL9(msg, a, b, c, d, e, f, g, h, i)     {MSG9("       ", stdout, msg, a, b, c, d, e, f, g, h, i);}
#define INFO_AL10(msg, a, b, c, d, e, f, g, h, i, j)     {MSG10("       ", stdout, msg, a, b, c, d, e, f, g, h, i, j);}

#define WARNING(msg)     {MSG("warning", stdout, msg);}
#define WARNING1(msg, a)     {MSG1("warning", stdout, msg, a);}
#define WARNING2(msg, a, b)     {MSG2("warning", stdout, msg, a, b);}
#define WARNING3(msg, a, b, c)     {MSG3("warning", stdout, msg, a, b, c);}
#define WARNING4(msg, a, b, c, d)     {MSG4("warning", stdout, msg, a, b, c, d);}
#define WARNING5(msg, a, b, c, d, e)     {MSG5("warning", stdout, msg, a, b, c, d, e);}
#define WARNING6(msg, a, b, c, d, e, f)     {MSG6("warning", stdout, msg, a, b, c, d, e, f);}
#define WARNING7(msg, a, b, c, d, e, f, g)     {MSG7("warning", stdout, msg, a, b, c, d, e, f, g);}
#define WARNING8(msg, a, b, c, d, e, f, g, h)     {MSG8("warning", stdout, msg, a, b, c, d, e, f, g, h);}
#define WARNING9(msg, a, b, c, d, e, f, g, h, i)     {MSG9("warning", stdout, msg, a, b, c, d, e, f, g, h, i);}
#define WARNING10(msg, a, b, c, d, e, f, g, h, i, j)     {MSG10("warning", stdout, msg, a, b, c, d, e, f, g, h, i, j);}

#define WARNING_AL(msg)  {INFO_AL(msg);}
#define WARNING_AL1(msg, a)  {INFO_AL1(msg, a);}
#define WARNING_AL2(msg, a, b)  {INFO_AL2(msg, a, b);}
#define WARNING_AL3(msg, a, b, c)  {INFO_AL3(msg, a, b, c);}
#define WARNING_AL4(msg, a, b, c, d)  {INFO_AL4(msg, a, b, c, d);}
#define WARNING_AL5(msg, a, b, c, d, e)  {INFO_AL5(msg, a, b, c, d, e);}
#define WARNING_AL6(msg, a, b, c, d, e, f)  {INFO_AL6(msg, a, b, c, d, e, f);}
#define WARNING_AL7(msg, a, b, c, d, e, f, g)  {INFO_AL7(msg, a, b, c, d, e, f, g);}
#define WARNING_AL8(msg, a, b, c, d, e, f, g, h)  {INFO_AL8(msg, a, b, c, d, e, f, g, h);}
#define WARNING_AL9(msg, a, b, c, d, e, f, g, h, i)  {INFO_AL9(msg, a, b, c, d, e, f, g, h, i);}
#define WARNING_AL10(msg, a, b, c, d, e, f, g, h, i, j)  {INFO_AL10(msg, a, b, c, d, e, f, g, h, i, j);}

#define THROW(msg)       {MSG_H("throw  ", stderr); MSG("       ", stderr, msg); longjmp(globalJmpbuf, 1);}
#define THROW1(msg, a)       {MSG_H("throw  ", stderr); MSG1("       ", stderr, msg, a); longjmp(globalJmpbuf, 1);}
#define THROW2(msg, a, b)       {MSG_H("throw  ", stderr); MSG2("       ", stderr, msg, a, b); longjmp(globalJmpbuf, 1);}
#define THROW3(msg, a, b, c)       {MSG_H("throw  ", stderr); MSG3("       ", stderr, msg, a, b, c); longjmp(globalJmpbuf, 1);}
#define THROW4(msg, a, b, c, d)       {MSG_H("throw  ", stderr); MSG4("       ", stderr, msg, a, b, c, d); longjmp(globalJmpbuf, 1);}
#define THROW5(msg, a, b, c, d, e)       {MSG_H("throw  ", stderr); MSG5("       ", stderr, msg, a, b, c, d, e); longjmp(globalJmpbuf, 1);}
#define THROW6(msg, a, b, c, d, e, f)       {MSG_H("throw  ", stderr); MSG6("       ", stderr, msg, a, b, c, d, e, f); longjmp(globalJmpbuf, 1);}
#define THROW7(msg, a, b, c, d, e, f, g)       {MSG_H("throw  ", stderr); MSG7("       ", stderr, msg, a, b, c, d, e, f, g); longjmp(globalJmpbuf, 1);}
#define THROW8(msg, a, b, c, d, e, f, g, h)       {MSG_H("throw  ", stderr); MSG8("       ", stderr, msg, a, b, c, d, e, f, g, h); longjmp(globalJmpbuf, 1);}
#define THROW9(msg, a, b, c, d, e, f, g, h, i)       {MSG_H("throw  ", stderr); MSG9("       ", stderr, msg, a, b, c, d, e, f, g, h, i); longjmp(globalJmpbuf, 1);}
#define THROW10(msg, a, b, c, d, e, f, g, h, i, j)       {MSG_H("throw  ", stderr); MSG10("       ", stderr, msg, a, b, c, d, e, f, g, h, i, j); longjmp(globalJmpbuf, 1);}

#ifdef USE_ASSERTS
#define ASSERT(exp, msg) {if(!(exp)){MSG_H("assert ", stderr); MSG("       ", stderr, msg); longjmp(globalJmpbuf, 1);}}
#define ASSERT1(exp, msg, a) {if(!(exp)){MSG_H("assert ", stderr); MSG1("       ", stderr, msg, a); longjmp(globalJmpbuf, 1);}}
#define ASSERT2(exp, msg, a, b) {if(!(exp)){MSG_H("assert ", stderr); MSG2("       ", stderr, msg, a, b); longjmp(globalJmpbuf, 1);}}
#define ASSERT3(exp, msg, a, b, c) {if(!(exp)){MSG_H("assert ", stderr); MSG3("       ", stderr, msg, a, b, c); longjmp(globalJmpbuf, 1);}}
#define ASSERT4(exp, msg, a, b, c, d) {if(!(exp)){MSG_H("assert ", stderr); MSG4("       ", stderr, msg, a, b, c, d); longjmp(globalJmpbuf, 1);}}
#define ASSERT5(exp, msg, a, b, c, d, e) {if(!(exp)){MSG_H("assert ", stderr); MSG5("       ", stderr, msg, a, b, c, d, e); longjmp(globalJmpbuf, 1);}}
#define ASSERT6(exp, msg, a, b, c, d, e, f) {if(!(exp)){MSG_H("assert ", stderr); MSG6("       ", stderr, msg, a, b, c, d, e, f); longjmp(globalJmpbuf, 1);}}
#define ASSERT7(exp, msg, a, b, c, d, e, f, g) {if(!(exp)){MSG_H("assert ", stderr); MSG7("       ", stderr, msg, a, b, c, d, e, f, g); longjmp(globalJmpbuf, 1);}}
#define ASSERT8(exp, msg, a, b, c, d, e, f, g, h) {if(!(exp)){MSG_H("assert ", stderr); MSG8("       ", stderr, msg, a, b, c, d, e, f, g, h); longjmp(globalJmpbuf, 1);}}
#define ASSERT9(exp, msg, a, b, c, d, e, f, g, h, i) {if(!(exp)){MSG_H("assert ", stderr); MSG9("       ", stderr, msg, a, b, c, d, e, f, g, h, i); longjmp(globalJmpbuf, 1);}}
#define ASSERT10(exp, msg, a, b, c, d, e, f, g, h, i, j) {if(!(exp)){MSG_H("assert ", stderr); MSG10("       ", stderr, msg, a, b, c, d, e, f, g, h, i, j); longjmp(globalJmpbuf, 1);}}
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
#define DEBUG_INFO(flag, msg)    {if(DEBUG_FLAG(flag)) MSG("debug  ", stdout, msg);}
#define DEBUG_INFO1(flag, msg, a)    {if(DEBUG_FLAG(flag)) MSG1("debug  ", stdout, msg, a);}
#define DEBUG_INFO2(flag, msg, a, b)    {if(DEBUG_FLAG(flag)) MSG2("debug  ", stdout, msg, a, b);}
#define DEBUG_INFO3(flag, msg, a, b, c)    {if(DEBUG_FLAG(flag)) MSG3("debug  ", stdout, msg, a, b, c);}
#define DEBUG_INFO4(flag, msg, a, b, c, d)    {if(DEBUG_FLAG(flag)) MSG4("debug  ", stdout, msg, a, b, c, d);}
#define DEBUG_INFO5(flag, msg, a, b, c, d, e)    {if(DEBUG_FLAG(flag)) MSG5("debug  ", stdout, msg, a, b, c, d, e);}
#define DEBUG_INFO6(flag, msg, a, b, c, d, e, f)    {if(DEBUG_FLAG(flag)) MSG6("debug  ", stdout, msg, a, b, c, d, e, f);}
#define DEBUG_INFO7(flag, msg, a, b, c, d, e, f, g)    {if(DEBUG_FLAG(flag)) MSG7("debug  ", stdout, msg, a, b, c, d, e, f, g);}
#define DEBUG_INFO8(flag, msg, a, b, c, d, e, f, g, h)    {if(DEBUG_FLAG(flag)) MSG8("debug  ", stdout, msg, a, b, c, d, e, f, g, h);}
#define DEBUG_INFO9(flag, msg, a, b, c, d, e, f, g, h, i)    {if(DEBUG_FLAG(flag)) MSG9("debug  ", stdout, msg, a, b, c, d, e, f, g, h, i);}
#define DEBUG_INFO10(flag, msg, a, b, c, d, e, f, g, h, i, j)    {if(DEBUG_FLAG(flag)) MSG10("debug  ", stdout, msg, a, b, c, d, e, f, g, h, i, j);}

#define DEBUG_INFO_AL(flag, msg) {if(DEBUG_FLAG(flag)) INFO_AL(msg);}
#define DEBUG_INFO_AL1(flag, msg, a) {if(DEBUG_FLAG(flag)) INFO_AL1(msg, a);}
#define DEBUG_INFO_AL2(flag, msg, a, b) {if(DEBUG_FLAG(flag)) INFO_AL2(msg, a, b);}
#define DEBUG_INFO_AL3(flag, msg, a, b, c) {if(DEBUG_FLAG(flag)) INFO_AL3(msg, a, b, c);}
#define DEBUG_INFO_AL4(flag, msg, a, b, c, d) {if(DEBUG_FLAG(flag)) INFO_AL4(msg, a, b, c, d);}
#define DEBUG_INFO_AL5(flag, msg, a, b, c, d, e) {if(DEBUG_FLAG(flag)) INFO_AL5(msg, a, b, c, d, e);}
#define DEBUG_INFO_AL6(flag, msg, a, b, c, d, e, f) {if(DEBUG_FLAG(flag)) INFO_AL6(msg, a, b, c, d, e, f);}
#define DEBUG_INFO_AL7(flag, msg, a, b, c, d, e, f, g) {if(DEBUG_FLAG(flag)) INFO_AL7(msg, a, b, c, d, e, f, g);}
#define DEBUG_INFO_AL8(flag, msg, a, b, c, d, e, f, g, h) {if(DEBUG_FLAG(flag)) INFO_AL8(msg, a, b, c, d, e, f, g, h);}
#define DEBUG_INFO_AL9(flag, msg, a, b, c, d, e, f, g, h, i) {if(DEBUG_FLAG(flag)) INFO_AL9(msg, a, b, c, d, e, f, g, h, i);}
#define DEBUG_INFO_AL10(flag, msg, a, b, c, d, e, f, g, h, i, j) {if(DEBUG_FLAG(flag)) INFO_AL10(msg, a, b, c, d, e, f, g, h, i, j);}

#ifdef __cplusplus
}
#endif

#endif
