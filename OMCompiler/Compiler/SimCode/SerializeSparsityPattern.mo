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

import SimCode;
import List;
import System;
import Util;

function serialize
  input SimCode.SimCode code;
protected
  array<Integer> columnPointers, rowIndices, columns;
  String path = code.fileNamePrefix + "_sparsityPatterns/";
  String fname;
algorithm
  if 0 <> System.systemCall("mkdir -p '" + path + "'") then
    Error.addInternalError(getInstanceName() + " failed to create directory " + path, sourceInfo());
    fail();
  end if;
  for jac in code.jacobianMatrices loop
    fname := path + jac.matrixName + ".bin";
    columnPointers := listArray(0 :: list(listLength(Util.tuple22(column)) for column in jac.sparsity));
    rowIndices := listArray(List.flatten(list(Util.tuple22(column) for column in jac.sparsity)));
    serializeJacobian(fname, arrayLength(columnPointers), arrayLength(rowIndices), columnPointers, rowIndices);
    for color in jac.coloredCols loop
      columns := listArray(color);
      serializeColor(fname, arrayLength(columns), columns);
    end for;
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
    FILE* pFile = omc_fopen(name, \"wb\");


    /* compute and write sparsePattern->leadindex */
    j = 0;
    for (i = 0; i < numCols; i++) {
      j += MMC_UNTAGFIXNUM(MMC_STRUCTDATA(colPtrs)[i]);
      omc_fwrite(&j, sizeof(unsigned int), 1, pFile);
    }

    /* write sparsePattern->index */
    for (i = 0; i < nnz; i++) {
      j = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(rowInds)[i]);
      omc_fwrite(&j, sizeof(unsigned int), 1, pFile);
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
    FILE* pFile = fopen(name, \"ab\");

    /* write sparsePattern->colorCols */
    for (i = 0; i < size; i++) {
      j = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(columns)[i]);
      omc_fwrite(&j, sizeof(unsigned int), 1, pFile);
    }

    fclose(pFile);
  }
  ");
  end serializeColor;

annotation(__OpenModelica_Interface="backend");
end SerializeSparsityPattern;
