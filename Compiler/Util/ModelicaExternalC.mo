/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package ModelicaExternalC
" file:        ModelicaExternalC.mo
  package:     ModelicaExternalC
  description: This file contains ModelicaExternalC external functions.


  This package contains ModelicaExternalC functions which are used by
  Ceval to evaluate functions that use these ModelicaExternalC functions.
  See e.g. the documentation in Modelica.Utilities for details."

function Streams_print
  input String string;
  input String fileName;
  external "C" ModelicaInternal_print(string,fileName) annotation(Library="ModelicaExternalC");
end Streams_print;

function Streams_readLine
  input String fileName;
  input Integer lineNumber;
  output String string;
  output Boolean endOfFile;
  external "C" string = ModelicaInternal_readLine(fileName,lineNumber,endOfFile) annotation(Library="ModelicaExternalC");
end Streams_readLine;

function Streams_countLines
  input String fileName;
  output Integer numberOfLines;
  external "C" numberOfLines=ModelicaInternal_countLines(fileName) annotation(Library="ModelicaExternalC");
end Streams_countLines;

function File_fullPathName
  input String fileName;
  output String outName;
  external "C" outName=ModelicaInternal_fullPathName(fileName) annotation(Library="ModelicaExternalC");
end File_fullPathName;

function File_stat
  input String name;
  output Integer fileType;
  external "C" fileType=ModelicaInternal_stat(name) annotation(Library="ModelicaExternalC");
end File_stat;

function Streams_close
  input String fileName;
  external "C" ModelicaStreams_closeFile(fileName) annotation(Library="ModelicaExternalC");
end Streams_close;

function Strings_compare
  input String string1;
  input String string2;
  input Boolean caseSensitive;
  output Integer result;

  external "C" result=ModelicaStrings_compare(string1,string2,caseSensitive) annotation(Library = "ModelicaExternalC");
end Strings_compare;

function Strings_advanced_scanReal
  input String string;
  input Integer startIndex;
  input Boolean unsigned;
  output Integer nextIndex;
  output Real number;

  external "C" ModelicaStrings_scanReal(string,startIndex,unsigned,nextIndex,number) annotation(Library = "ModelicaExternalC");
end Strings_advanced_scanReal;

function Strings_advanced_skipWhiteSpace
  input String string;
  input Integer startIndex(min = 1) = 1;
  output Integer nextIndex;

  external "C" nextIndex = ModelicaStrings_skipWhiteSpace(string,startIndex) annotation(Library = "ModelicaExternalC");
end Strings_advanced_skipWhiteSpace;

function ModelicaIO_readMatrixSizes
  input String fileName;
  input String matrixName;
  output Integer[2] dim;

  external "C" ModelicaIO_readMatrixSizes(fileName, matrixName, dim) annotation(Library = {"ModelicaIO", "ModelicaMatIO", "zlib"});
end ModelicaIO_readMatrixSizes;

function ModelicaIO_readRealMatrix
  input String fileName;
  input String matrixName;
  input Integer nrow;
  input Integer ncol;
  input Boolean verboseRead = true;
  output Real[nrow, ncol] matrix;

  external "C" ModelicaIO_readRealMatrix(fileName, matrixName, matrix, nrow, ncol, verboseRead)
  annotation(Library = {"ModelicaIO", "ModelicaMatIO", "zlib"});
end ModelicaIO_readRealMatrix;

annotation(__OpenModelica_Interface="util");
end ModelicaExternalC;
