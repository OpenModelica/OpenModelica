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

#include "MatVer4.h"

#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

const char isBigEndian()
{
  union
  {
    uint32_t i32;
    uint8_t i8[4];
  } test = { 0x01020304 };
  return (1 == test.i8[0]);
}

size_t sizeofMatVer4Type(MatVer4Type_t type)
{
  switch (type)
  {
  case MatVer4Type_DOUBLE:
    return sizeof(double);
  case MatVer4Type_SINGLE:
    return sizeof(float);
  case MatVer4Type_INT32:
    return sizeof(int32_t);
  case MatVer4Type_CHAR:
    return sizeof(uint8_t);
  default:
    // Should never get here!
    assert(0);
    return 0;
  }
}

void writeMatrix_matVer4(FILE* file, const char* name, size_t rows, size_t cols, const void* matrixData, MatVer4Type_t type)
{
  MatVer4Header header;
  size_t size = sizeofMatVer4Type(type);

  header.type = (isBigEndian() ? 1000 : 0) + type;
  header.mrows = (unsigned int) rows;
  header.ncols = (unsigned int) cols;
  header.imagf = 0;
  header.namelen = (unsigned int) strlen(name) + 1;

  fwrite(&header, sizeof(MatVer4Header), 1, file);
  fwrite(name, sizeof(uint8_t), header.namelen, file);

  if (matrixData)
    fwrite(matrixData, size, rows * cols, file);
}

void updateHeader_matVer4(FILE* file, long position, const char* name, size_t rows, size_t additional_cols, MatVer4Type_t type)
{
  MatVer4Header header;

  long eof = ftell(file);
  fseek(file, position, SEEK_SET);
  fread(&header, sizeof(MatVer4Header), 1, file);

  assert(header.type == (isBigEndian() ? 1000 : 0) + type);
  assert(header.mrows == rows);
  assert(header.imagf == 0);
  assert(header.namelen == strlen(name) + 1);

  header.ncols += (unsigned int) additional_cols;

  fseek(file, position, SEEK_SET);
  fwrite(&header, sizeof(MatVer4Header), 1, file);
  fseek(file, eof, SEEK_SET);
}

void appendMatrix_matVer4(FILE* file, long position, const char* name, size_t rows, size_t cols, const void* matrixData, MatVer4Type_t type)
{
  size_t size = sizeofMatVer4Type(type);
  updateHeader_matVer4(file, position, name, rows, cols, type);
  fwrite(matrixData, size, rows * cols, file);
}

MatVer4Matrix* readMatVer4Matrix(FILE* file)
{
  MatVer4Matrix *matrix = (MatVer4Matrix*) malloc(sizeof(MatVer4Matrix));
  if (!matrix)
    return NULL;

  fread(&matrix->header, sizeof(MatVer4Header), 1, file);

  // skip name
  fseek(file, matrix->header.namelen, SEEK_CUR);

  MatVer4Type_t type = (MatVer4Type_t) (matrix->header.type % 100);
  size_t size = sizeofMatVer4Type(type);
  matrix->data = malloc(matrix->header.mrows * matrix->header.ncols * size);
  fread(matrix->data, size, matrix->header.mrows*matrix->header.ncols, file);

  return matrix;
}

void freeMatrix_matVer4(MatVer4Matrix** matrix)
{
  if (*matrix)
  {
    if ((*matrix)->data)
      free((*matrix)->data);
    free(*matrix);
    *matrix = NULL;
  }
}

void skipMatrix_matVer4(FILE* file)
{
  MatVer4Header header;
  fread(&header, sizeof(MatVer4Header), 1, file);

  // skip name
  fseek(file, header.namelen, SEEK_CUR);

  // skip data
  MatVer4Type_t type = (MatVer4Type_t) (header.type % 100);
  size_t size = sizeofMatVer4Type(type);
  fseek(file, header.mrows*header.ncols*size, SEEK_CUR);
}

#ifdef __cplusplus
}
#endif
