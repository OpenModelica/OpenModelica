/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef _OMS_MATVER4_H_
#define _OMS_MATVER4_H_

#include <stdio.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum MatVer4Type_t
{
  MatVer4Type_DOUBLE = 0,
  MatVer4Type_SINGLE = 10,
  MatVer4Type_INT32 = 20,
  MatVer4Type_CHAR = 51
} MatVer4Type_t;

typedef struct MatVer4Header
{
  unsigned int type;
  unsigned int mrows;
  unsigned int ncols;
  unsigned int imagf;
  unsigned int namelen;
} MatVer4Header;

typedef struct MatVer4Matrix
{
  MatVer4Header header;
  void *data;
} MatVer4Matrix;

int writeMatVer4Matrix_4(FILE* file, const char* name, size_t rows, size_t cols, const void* matrixData, MatVer4Type_t type);
int appendMatVer4Matrix_4(FILE* file, long position, const char* name, size_t rows, size_t cols, const void* matrixData, MatVer4Type_t type);
int writeMatVer4Header_4(FILE* file, long position, const char* name, size_t rows, size_t cols, MatVer4Type_t type);

MatVer4Matrix* readMatVer4Matrix_4(FILE* file);
void freeMatVer4Matrix_4(MatVer4Matrix** matrix);

int skipMatVer4Matrix_4(FILE* file);

#ifdef __cplusplus
}
#endif

#endif
