/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * file:        ASSCEXT_omc.cpp
 * description: The ASSCEXT_omc.cpp file is the external implementation of
 *              MetaModelica package: Compiler/ASSC.mo.
 *              It contains the headers for ASSCEXT.cpp.
 *              This is used for the analytical to structural singularity conversion
 *              (ASSC) algorithm which is used for alias elimination and before index
 *              reduction.
 */

#include "meta/meta_modelica.h"
#include "ASSCEXT.cpp"
#include <stdlib.h>
#include "errorext.h"

extern "C" {

extern void ASSC_setMatrix(modelica_integer nvars, modelica_integer neqns, modelica_integer nz, modelica_metatype adj, modelica_metatype val)
{

  nv = nvars;
  ne = neqns;
  nnz = nz;

  int i=0;
  mmc_sint_t adj_i, val_i;
  int j=0;
  // ToDo: check if val and adj have same size
  modelica_integer nelts = MMC_HDRSLOTS(MMC_GETHDR(adj));

  // initialize column pointers
  if (col_ptrs) free(col_ptrs);
  col_ptrs = (int*) malloc((neqns+1) * sizeof(int));
  // initialize indices
  if (col_ids) free(col_ids);
  col_ids = (int*) malloc(nz * sizeof(int));
  // initialize values
  if (col_val) free(col_val);
  col_val = (int*) malloc(nz * sizeof(int));

  col_ptrs[0] = 0;
  for(i=0; i<neqns; ++i) {
    // ToDo: check if adj_col and val_col have same size
    modelica_metatype adj_col = MMC_STRUCTDATA(adj)[i];
    modelica_metatype val_col = MMC_STRUCTDATA(val)[i];

    while((MMC_GETHDR(adj_col) == MMC_CONSHDR) && (MMC_GETHDR(val_col) == MMC_CONSHDR)) {
      adj_i = MMC_UNTAGFIXNUM(MMC_CAR(adj_col));
      val_i = MMC_UNTAGFIXNUM(MMC_CAR(val_col));
      col_ids[j]    = (int)adj_i-1;
      col_val[j++]  = (int)val_i;
      adj_col = MMC_CDR(adj_col);
      val_col = MMC_CDR(val_col);
    }
    // add number of elements to last starting point to compute next starting point
    col_ptrs[i+1] = j;
  }
}

extern void ASSC_freeMatrix()
{
  if (col_ptrs) free(col_ptrs);
  if (col_ids) free(col_ids);
  if (col_val) free(col_val);
}

extern void ASSC_printMatrix()
{
  cout << "Sparse Matrix:" << endl << "================" << endl;

  for (int i=0; i<ne; ++i)
  {
    cout << i << ": ";
    for(int j=col_ptrs[i]; j < col_ptrs[i+1]; ++j)
      cout << "(" << col_ids[j] << "," << col_val[j] << ")";
    cout << endl;
  }
}

}
