/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ModelicaExternalC
" file:        ModelicaExternalC.mo
  package:     ModelicaExternalC
  description: This file contains ModelicaExternalC external functions.

  RCS: $Id$

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

function Streams_close
  input String fileName;
  external "C" ModelicaStreams_closeFile(fileName) annotation(Library="ModelicaExternalC");
end Streams_close;

end ModelicaExternalC;
