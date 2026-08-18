/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

 /*! \file jacobian_symbolical.c
 */

#include "jacobianSymbolical.h"


/**
 * \brief Generic computation of the colored Jacobian.
 *
 * Exploiting coloring and sparse structure. Used from DASSL and IDA solvers.
 * Only matrix storing format differs for them and therefore setJacElement function
 * is used to access matrix A.
 *
 * \param rows                Number of rows of jacobian.
 * \param columns             Number of columns of jacobian.
 * \param spp                 Pointer to sparse pattern.
 * \param matrixA             Internal data of solvers to store jacobian.
 * \param jacobian            Analytic Jacobian.
 * \param data                Runtime data struct.
 * \param threadData          Thread data for error handling
 * \param setJacElement       Function to set element (i,j) in matrix A.
 */
void genericColoredSymbolicJacobianEvaluation(int rows, int columns, SPARSE_PATTERN* spp,
                                              void* matrixA, JACOBIAN* jacobian, DATA* data,
                                              threadData_t* threadData,
                                              setJacElementFunc setJacElement)
{
  JACOBIAN* t_jac = jacobian;

  unsigned int i, j, currentIndex, nth;

  for (i=0; i < spp->maxColors; i++) {
     if (t_jac->isRowEval == 1) {
       /* Row evaluation: sparse pattern is CSR, colorCols encodes row colors. */
       for (j=0; j < rows; j++) {
         if (spp->colorCols[j]-1 == i) {
           t_jac->seedVars[j] = 1;
         }
       }

       data->callback->functionJacADJ_column(data, threadData, t_jac, NULL);

       for (j=0; j < rows; j++) {
         if (spp->colorCols[j]-1 == i) {
           nth = spp->leadindex[j];
           while (nth < spp->leadindex[j+1]) {
             currentIndex = spp->index[nth];
             (*setJacElement)(j, currentIndex, nth, t_jac->resultVars[currentIndex], matrixA, rows);
             nth++;
           }
           t_jac->seedVars[j] = 0;
         }
       }
       // avoid accumulation
       for (j=0; j < rows; j++) {
          t_jac->resultVars[j] = 0;
       }
       // reset tmp vars
       for (j=0; j < t_jac->sizeTmpVars; j++) {
          t_jac->tmpVars[j] = 0;
       }
     } else {
       /* Column evaluation: sparse pattern is CSC, colorCols encodes column colors. */
       for (j=0; j < columns; j++) {
         if (spp->colorCols[j]-1 == i) {
           t_jac->seedVars[j] = 1;
         }
       }

       data->callback->functionJacA_column(data, threadData, t_jac, NULL);

       for (j=0; j < columns; j++) {
         if (spp->colorCols[j]-1 == i) {
           nth = spp->leadindex[j];
           while (nth < spp->leadindex[j+1]) {
             currentIndex = spp->index[nth];
             (*setJacElement)(currentIndex, j, nth, t_jac->resultVars[currentIndex], matrixA, rows);
             nth++;
           }
           t_jac->seedVars[j] = 0;
         }
       }
     }
   }
}
