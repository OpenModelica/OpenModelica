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

encapsulated package SerializeSparsityPattern

import List;
import SimCode;
import Util;

function serialize
  input SimCode.SimCode code;
  output String dummy = "";
protected
  array<Integer> columnPointers, rowIndices, columns;
  String fname;
  Boolean adj;
  list<tuple<Integer, list<Integer>>> pattern;
  list<list<Integer>> colorList;
algorithm
  // TODO: redo naming variables
  for jac in code.jacobianMatrices loop
    // pick sparsity and coloring depending on adjoint
    adj := jac.isAdjoint;
    print("adjoint in serialize: " + boolString(adj) + " for jacobian matrix: " + jac.matrixName + "\n");
    print("colored rows laenge: " + intString(listLength(jac.coloredRows)) + " " + boolString(listEmpty(jac.coloredRows)) + "\n");
    print("colored cols laenge: " + intString(listLength(jac.coloredCols)) + " " + boolString(listEmpty(jac.coloredCols)) + "\n");
    pattern := if adj then jac.sparsityT else jac.sparsity;
    // prefer row coloring if available for adjoint, otherwise fall back to column coloring
    colorList := if adj then (if not listEmpty(jac.coloredRows) then jac.coloredRows else jac.coloredCols) else jac.coloredCols;
    if not listEmpty(pattern) then
      fname := code.fileNamePrefix + "_Jac" + jac.matrixName + ".bin";
      columnPointers := listArray(0 :: list(listLength(Util.tuple22(column)) for column in pattern));
      rowIndices := listArray(List.flatten(list(Util.tuple22(column) for column in pattern)));
      serializeJacobian(fname, arrayLength(columnPointers), arrayLength(rowIndices), columnPointers, rowIndices);
      for color in colorList loop
        columns := listArray(color);
        serializeColor(fname, arrayLength(columns), columns);
      end for;
    end if;
  end for;
end serialize;

// *********************
// write to binary stuff
// *********************

protected
  function serializeJacobian
    input String name;
    input Integer numCols;
    input Integer nnz;
    input array<Integer> colPtrs;
    input array<Integer> rowInds;
  external "C" serializeJ(name, numCols, nnz, colPtrs, rowInds) annotation(Include="
  extern FILE* omc_fopen(const char *filename, const char *mode);
  extern size_t omc_fwrite(void *buffer, size_t size, size_t count, FILE *stream);

  static void serializeJ(const char* name, int numCols, int nnz, modelica_metatype colPtrs, modelica_metatype rowInds)
  {
    unsigned int i, j;
    size_t count;
    FILE* pFile = omc_fopen(name, \"wb\");
    if (pFile == NULL) {
      throwStreamPrint(NULL, \"Could not open sparsity pattern file %s.\", name);
    }

    /* compute and write sparsePattern->leadindex */
    j = 0;
    for (i = 0; i < numCols; i++) {
      j += (unsigned int) MMC_UNTAGFIXNUM(MMC_STRUCTDATA(colPtrs)[i]);
      count = omc_fwrite(&j, sizeof(unsigned int), 1, pFile);
      if (count != 1) {
        throwStreamPrint(NULL, \"Error while writing sparsePattern->leadindex. Expected %d, got %zu\", 1, count);
      }
    }

    /* write sparsePattern->index */
    for (i = 0; i < nnz; i++) {
      j = (unsigned int) MMC_UNTAGFIXNUM(MMC_STRUCTDATA(rowInds)[i]);
      count = omc_fwrite(&j, sizeof(unsigned int), 1, pFile);
      if (count != 1) {
        throwStreamPrint(NULL, \"Error while writing sparsePattern->index. Expected %d, got %zu\", 1, count);
      }
    }

    fclose(pFile);
  }
  ");
  end serializeJacobian;

  function serializeColor
    input String name;
    input Integer size;
    input array<Integer> columns;
  external "C" serializeC(name, size, columns) annotation(Include="
  extern FILE* omc_fopen(const char *filename, const char *mode);
  extern size_t omc_fwrite(void *buffer, size_t size, size_t count, FILE *stream);

  static void serializeC(const char* name, int size, modelica_metatype columns)
  {
    unsigned int i, j;
    size_t count;
    FILE* pFile = fopen(name, \"ab\");
    if (pFile == NULL) {
      throwStreamPrint(NULL, \"Could not open sparsity pattern file %s.\", name);
    }

    /* write sparsePattern->colorCols */
    for (i = 0; i < size; i++) {
      j = (unsigned int) MMC_UNTAGFIXNUM(MMC_STRUCTDATA(columns)[i]);
      count = omc_fwrite(&j, sizeof(unsigned int), 1, pFile);
      if (count != 1) {
        throwStreamPrint(NULL, \"Error while writing sparsePattern->colorCols. Expected %d, got %zu\", 1, count);
      }
    }

    fclose(pFile);
  }
  ");
  end serializeColor;

annotation(__OpenModelica_Interface="backend");
end SerializeSparsityPattern;
