/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2023, Open Source Modelica Consortium (OSMC),
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

/** \file sundials_util.c
 */

#include "util/omc_error.h"

#include "sundials_util.h"
#include <sundials/sundials_matrix.h>
#include <sunmatrix/sunmatrix_sparse.h>
#include <nvector/nvector_serial.h>


#ifdef WITH_SUNDIALS

#define UNUSED(x) (void)(x)   /* Surpress compiler warnings for unused function input */

/**
 * @brief Set element of sparse Sundials matrix.
 *
 * Jac(row, column) = val.
 *
 * @param row       Row of matrix element.
 * @param column    Column of matrix element.
 * @param nth       Sparsity pattern lead index.
 * @param value     Value to set in position (i,j).
 * @param Jac       Pointer to double array storing matrix.
 * @param nRows     Number of rows of Jacobian matrix, unused.
 */
void setJacElementSundialsSparse(int row, int column, int nth, double value, void* Jac, int nRows)
{
  UNUSED(nRows);   /* Disables compiler warning */

  SUNMatrix A = (SUNMatrix) Jac;
  /* TODO: Remove this check for performance reasons? */
  if (SM_SPARSETYPE_S(A) != CSC_MAT) {
    errorStreamPrint(LOG_STDOUT, 0,
                     "In function setJacElementSundialsSparse: Wrong sparse format "
                     "of SUNMatrix A.");
  }

  if (column > 0 && SM_INDEXPTRS_S(A)[column] == 0) {
    SM_INDEXPTRS_S(A)[column] = nth;
  }
  SM_INDEXVALS_S(A)[nth] = row;
  SM_DATA_S(A)[nth] = value;
}

#endif /* WITH_SUNDIALS */

