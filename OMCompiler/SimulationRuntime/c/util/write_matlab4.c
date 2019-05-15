/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include "read_matlab4.h"
#include "write_matlab4.h"

extern const char *omc_mat_Aclass;

typedef struct {
  uint32_t type;
  uint32_t mrows;
  uint32_t ncols;
  uint32_t imagf;
  uint32_t namelen;
} MHeader_t;

/* Matrix list: "Aclass" "name" "description" "dataInfo" "data_1" "data_2" */

/* Returns 0 on success */
int writeMatVer4AclassNormal(FILE *fout)
{
  const char Aclass_normal[] = "A1 bt. ir1 na  Nj  oe  rc  mt  ao  lr   y   ";
  return writeMatVer4Matrix(fout, "Aclass", 4, 11, Aclass_normal, sizeof(int8_t));
}

// writes MAT-file matrix header to file
int writeMatVer4MatrixHeader(FILE *fout,const char *name, int rows, int cols, unsigned int size)
{
  typedef struct MHeader {
    uint32_t type;
    uint32_t mrows;
    uint32_t ncols;
    uint32_t imagf;
    uint32_t namelen;
  } MHeader_t;
  const int endian_test = 1;
  MHeader_t hdr;

  int type = 0;
  if(size == 1 /* char */)
    type = 51;
  if(size == 4 /* int32 */)
    type = 20;

  /* create matrix header structure */
  hdr.type = 1000*((*(char*)&endian_test) == 0) + type;
  hdr.mrows = rows;
  hdr.ncols = cols;
  hdr.imagf = 0;
  hdr.namelen = strlen(name)+1;

  /* write header to file */
  return !(1 == fwrite(&hdr, sizeof(MHeader_t), 1, fout) && 1 == fwrite(name, sizeof(char)*hdr.namelen, 1, fout));
}

int writeMatVer4Matrix(FILE *fout, const char *name, int rows, int cols, const void *matrixData, unsigned int size)
{
  /* write data */
  return !(0==writeMatVer4MatrixHeader(fout, name, rows, cols, size) && 1 == fwrite(matrixData, (size)*rows*cols, 1, fout));
}
