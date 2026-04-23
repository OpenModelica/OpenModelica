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

#include "meta/meta_modelica.h"

extern int Print_saveAndClearBuf(threadData_t *threadData);
extern void Print_restoreBuf(threadData_t *threadData, int handle);
extern void Print_printErrorBuf(threadData_t *threadData, const char* str);
extern void Print_printBuf(threadData_t *threadData, const char* str);
extern void Print_printBufLen(threadData_t *threadData, const char* str, long len);
extern int Print_hasBufNewLineAtEnd(threadData_t *threadData);
extern int Print_getBufLength(threadData_t *threadData);
extern const char* Print_getString(threadData_t *threadData);
extern const char* Print_getErrorString(threadData_t *threadData);
extern void Print_clearErrorBuf(threadData_t *threadData);
extern void Print_clearBuf(threadData_t *threadData);
extern void Print_printBufSpace(threadData_t *threadData,int numSpace);
extern void Print_printBufNewLine(threadData_t *threadData);
extern void Print_writeBuf(threadData_t *threadData,const char* filename);
extern void Print_writeBufConvertLines(threadData_t *threadData,const char* filename);
