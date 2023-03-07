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

//import Absyn;
//import BackendDAE;
//import DAE;
import SimCode;

//protected
//import Algorithm;
//import Autoconf;
//import Config;
//import DAEDump;
//import Error;
//import Expression;
//import File;
//import File.Escape.JSON;
//import writeCref = ComponentReference.writeCref;
//import expStr = ExpressionDump.printExpStr;
import List;
//import PrefixUtil;
//import SimCodeUtil;
//import SimCodeFunctionUtil;
//import SCodeDump;
import System;
import Util;

function serialize
  input SimCode.SimCode code;
protected
  array<Integer> columnPointers, rowIndices;
  String path = code.fileNamePrefix + "_sparsityPatterns/";
algorithm
  System.systemCall("mkdir -p '" + path + "'");
  for jac in code.jacobianMatrices loop
    columnPointers := listArray(0 :: list(listLength(Util.tuple22(column)) for column in jac.sparsity));
    rowIndices := listArray(List.flatten(list(Util.tuple22(column) for column in jac.sparsity)));
    serializeJacobian(path + jac.matrixName + ".bin", arrayLength(columnPointers), arrayLength(rowIndices), columnPointers, rowIndices);
  end for;
end serialize;

function serializeJacobian
  input String name;
  input Integer numCols;
  input Integer nnz;
  input array<Integer> colPtrs;
  input array<Integer> rowInds;
protected
external "C" serializeC(name, numCols, nnz, colPtrs, rowInds) annotation(Include="
static void serializeC(const char* name, int numCols, int nnz, modelica_metatype colPtrs, modelica_metatype rowInds)
{
  FILE * pFile;
  unsigned int i, j;

  pFile = fopen(name, \"wb\");

  /* compute and write sparsePattern->leadindex */
  j = 0;
  for (i = 0; i < numCols; i++) {
    j += MMC_UNTAGFIXNUM(MMC_STRUCTDATA(colPtrs)[i]);
    fwrite(&j, sizeof(unsigned int), 1, pFile);
  }

  /* write sparsePattern->index */
  for (i = 0; i < nnz; i++) {
    j = MMC_UNTAGFIXNUM(MMC_STRUCTDATA(rowInds)[i]);
    fwrite(&j, sizeof(unsigned int), 1, pFile);
  }

  /* TODO write sparsePattern->colorCols */

  fclose(pFile);
}
");
end serializeJacobian;

annotation(__OpenModelica_Interface="backend");
end SerializeSparsityPattern;
