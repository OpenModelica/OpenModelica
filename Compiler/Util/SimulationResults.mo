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

encapsulated package SimulationResults
" file:         SimulationResults.mo
  package:     SimulationResults
  description: Read simulation results into the Values.Value structure.

  RCS: $Id$

  "

public import Values;
protected import ValuesUtil;

public function val
  input String filename;
  input String varname;
  input Real timeStamp;
  output Real val;
external "C" val=SimulationResults_val(filename,varname,timeStamp);
end val;

public function readVariables
  input String filename;
  output list<String> vars;

  external "C" vars=SimulationResults_readVariables(filename) annotation(Library = "omcruntime");
end readVariables;

protected function readPtolemyplotDatasetWork
  input String inString;
  input list<String> inStringLst;
  input Integer inInteger;
  output Values.Value outValue;

  external "C" outValue=SimulationResults_readPtolemyplotDataset(inString,inStringLst,inInteger) annotation(Library = "omcruntime");
end readPtolemyplotDatasetWork;

public function readPtolemyplotDataset
  input String inString;
  input list<String> inStringLst;
  input Integer inInteger;
  output Values.Value outValue;
algorithm
  outValue := ValuesUtil.reverseMatrix(readPtolemyplotDatasetWork(inString,inStringLst,inInteger));
end readPtolemyplotDataset;

public function readSimulationResultSize
  input String filename;
  output Integer size;

  external "C" size=SimulationResults_readPtolemyplotDatasetSize(filename) annotation(Library = "omcruntime");
end readSimulationResultSize;

end SimulationResults;

