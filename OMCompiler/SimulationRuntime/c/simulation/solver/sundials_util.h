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

/*! \file sundials_util.h
 */

#ifndef _SUNDIALS_URIL_H
#define _SUNDIALS_URIL_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef OMC_FMI_RUNTIME
  #include "omc_config.h"
#endif

#ifdef WITH_SUNDIALS
#include <sundials/sundials_matrix.h>

void setJacElementSundialsSparse(int row, int column, int nth, double value, void* Jac, int nRows);
int _omc_SUNMatScaleIAdd_Sparse(realtype c, SUNMatrix A);
SUNMatrix _omc_SUNSparseMatrixVecScaling(SUNMatrix A, N_Vector vScale);

#endif /* WITH_SUNDIALS */

#ifdef __cplusplus
};
#endif

#endif /* _SUNDIALS_URIL_H */
