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
encapsulated package HpcOmBenchmark
" file:        HpcOmBenchmark.mo
  package:     HpcOmBenchmark
  description: HpcOmBenchmark contains the whole logic to measure the communication and processing time.

"

protected import HpcOmBenchmarkExt;
protected import System;

public function benchSystem
  output tuple<tuple<Integer,Integer>,tuple<Integer,Integer>> oTime; //required time for <op,com>

protected
  Integer comCostM,comCostN,opCostM,opCostN;
  list<Integer> opCosts, comCosts;
  String s1,s2;
algorithm
    //Don't use the opCost-calculation, the values are bad for equation systems
    opCosts := HpcOmBenchmarkExt.requiredTimeForOp();
    true := listLength(opCosts) == 2;
    opCostM := listGet(opCosts,1); //m
    opCostN := listGet(opCosts,2); //n
    s1 := intString(opCostM);
    s2 := intString(opCostN);
    //print("Test op y= " + s1 + " * x + " + s2 + "\n");

    comCosts := HpcOmBenchmarkExt.requiredTimeForComm();
    comCostM := listGet(comCosts,1); //m
    comCostN := listGet(comCosts,2); //n
    s1 := intString(comCostM);
    s2 := intString(comCostN);
    //print("Test comm y= " + s1 + " * x + " + s2 + "\n");

    oTime := ((opCostM,opCostN),(comCostM,comCostN));
end benchSystem;

public function readCalcTimesFromFile "author: marcusw
  Tries to find a file named <%iFileNamePrefix%>.xml or <%iFileNamePrefix%>.json. If such a file exists, the
  calculation times are read out. If not, the function will fail."
  input String iFileNamePrefix;
  output list<tuple<Integer,Integer,Real>> calcTimes; //<simEqIdx,numberOfCalcs,calcTimeSum>
protected
  String fullFileName;
  list<tuple<Integer,Integer,Real>> tmpCalcTimes;
algorithm
  calcTimes := matchcontinue(iFileNamePrefix)
    case(_)
      equation
        fullFileName = iFileNamePrefix + ".json";
        SOME(_) = System.getFileModificationTime(fullFileName);
        //json-file does exist
        print("Using json-file\n");
        tmpCalcTimes = readCalcTimesFromJson(fullFileName);
      then tmpCalcTimes;
    case(_)
      equation
        fullFileName = iFileNamePrefix + ".xml";
        SOME(_) = System.getFileModificationTime(fullFileName);
        //xml-file does exist
        tmpCalcTimes = readCalcTimesFromXml(fullFileName);
      then tmpCalcTimes;
    else
      equation
        print("readCalcTimesFromFile: No valid profiling-file found.\n");
      then fail();
  end matchcontinue;
end readCalcTimesFromFile;

protected function readCalcTimesFromXml "author: marcusw
  Reads the calculation times of the different simCode-equations out of the given xml-file (fileName). Make sure that the file exists before invoking this
  method, otherwise it will return an misleading error-message.
  Deprecated since commit r20267. Use the generated *.json-file instead."
  input String fileName;
  output list<tuple<Integer,Integer,Real>> calcTimes; //<simEqIdx,numberOfCalcs,calcTimeSum>
protected
  list<Real> tmpResult;
algorithm
  tmpResult := HpcOmBenchmarkExt.readCalcTimesFromXml(fileName);
  calcTimes := expandCalcTimes(tmpResult,{});
end readCalcTimesFromXml;

protected function readCalcTimesFromJson "author: marcusw
  Reads the calculation times of the different simCode-equations out of the given json-file (fileName). Make sure that the file exists before invoking this
  method, otherwise it will return an misleading error-message."
  input String fileName;
  output list<tuple<Integer,Integer,Real>> calcTimes; //<simEqIdx,numberOfCalcs,calcTimeSum>
protected
  list<Real> tmpResult;
algorithm
  tmpResult := HpcOmBenchmarkExt.readCalcTimesFromJson(fileName);
  calcTimes := expandCalcTimes(tmpResult,{});
end readCalcTimesFromJson;

protected function expandCalcTimes "author: marcusw
  Takes a list of real vars and puts the first three entries into the tuple list. Afterwards it will cut off these entries and repeat with a tail-recursive call."
  input list<Real> iList;
  input list<tuple<Integer,Integer,Real>> iTuples; //<eqIdx,numOfCalcs,calcTimeSum> attention: eqIdx starts with zero
  output list<tuple<Integer,Integer,Real>> oTuples;
protected
  Real eqIdx, numOfCalcs, calcTimeSum;
  Integer intNumOfCalcs,intEqIdx;
  list<Real> rest;
  list<tuple<Integer,Integer,Real>> tmpTuples;
algorithm
  oTuples := matchcontinue(iList, iTuples)
  case(numOfCalcs::calcTimeSum::eqIdx::rest,_)
    equation
      //print("readCalcTimesFromXml1 eqIdx: " + intString(realInt(eqIdx)) + " numOfCalcs: " + intString(realInt(numOfCalcs)) + " calcTime: " + realString(calcTimeSum) + " \n");
      intNumOfCalcs = realInt(numOfCalcs);
      intEqIdx = realInt(eqIdx);
      tmpTuples = expandCalcTimes(rest, (intEqIdx,intNumOfCalcs,calcTimeSum)::iTuples);
    then tmpTuples;
  case ({},_)
    then iTuples;
  else
    equation
      print("expandCalcTimes: Invalid number of list-entries\n");
    then fail();
  end matchcontinue;
end expandCalcTimes;

annotation(__OpenModelica_Interface="backend");
end HpcOmBenchmark;
