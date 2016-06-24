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

encapsulated package SimCodeFunction
"The entry points to this module is the translateFunctions fuction."

// public imports
public
import Absyn;
import DAE;
import HashTableStringToPath;
import Tpl;
import SimCode;

// protected imports
protected
import BaseHashTable;
import CodegenCFunctions;
import Global;
import SimCodeFunctionUtil;

public function translateFunctions "
  Entry point to translate Modelica/MetaModelica functions to C functions.
  Called from other places in the compiler."
  input Absyn.Program program;
  input String name;
  input Option<DAE.Function> optMainFunction;
  input list<DAE.Function> idaeElements;
  input list<DAE.Type> metarecordTypes;
  input list<String> inIncludes;
algorithm
  setGlobalRoot(Global.optionSimCode, NONE());
  _ := match (program, name, optMainFunction, idaeElements, metarecordTypes, inIncludes)
    local
      DAE.Function daeMainFunction;
      SimCode.Function mainFunction;
      list<SimCode.Function> fns;
      list<String> includes, libs, libPaths,includeDirs;
      SimCode.MakefileParams makefileParams;
      SimCode.FunctionCode fnCode;
      list<SimCode.RecordDeclaration> extraRecordDecls;
      list<DAE.Exp> literals;
      list<DAE.Function> daeElements;

    case (_, _, SOME(daeMainFunction), daeElements, _, includes)
      equation
        // Create SimCode.FunctionCode
        (daeElements,literals) = SimCodeFunctionUtil.findLiterals(daeMainFunction::daeElements);
        (mainFunction::fns, extraRecordDecls, includes, includeDirs, libs,libPaths) = SimCodeFunctionUtil.elaborateFunctions(program, daeElements, metarecordTypes, literals, includes);
        SimCodeFunctionUtil.checkValidMainFunction(name, mainFunction);
        makefileParams = SimCodeFunctionUtil.createMakefileParams(includeDirs, libs,libPaths, true);
        fnCode = SimCode.FUNCTIONCODE(name, SOME(mainFunction), fns, literals, includes, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(CodegenCFunctions.translateFunctions, fnCode);
      then
        ();
    case (_, _, NONE(), daeElements, _, includes)
      equation
        // Create SimCode.FunctionCode
        (daeElements,literals) = SimCodeFunctionUtil.findLiterals(daeElements);
        (fns, extraRecordDecls, includes, includeDirs, libs,libPaths) = SimCodeFunctionUtil.elaborateFunctions(program, daeElements, metarecordTypes, literals, includes);
        makefileParams = SimCodeFunctionUtil.createMakefileParams(includeDirs, libs,libPaths, true);
        // remove OpenModelica.threadData.ThreadData
        fns = removeThreadDataFunction(fns, {});
        extraRecordDecls = removeThreadDataRecord(extraRecordDecls, {});

        fnCode = SimCode.FUNCTIONCODE(name, NONE(), fns, literals, includes, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(CodegenCFunctions.translateFunctions, fnCode);
      then
        ();
  end match;
end translateFunctions;

protected function removeThreadDataRecord
"remove OpenModelica.threadData.ThreadData
 as is already defined in openmodelica.h"
  input list<SimCode.RecordDeclaration> inRecs;
  input list<SimCode.RecordDeclaration> inAcc;
  output list<SimCode.RecordDeclaration> outRecs;
algorithm
  outRecs := match(inRecs, inAcc)
    local
      Absyn.Path p;
      list<SimCode.RecordDeclaration> acc, rest;
      SimCode.RecordDeclaration r;

    case ({}, _) then listReverse(inAcc);

    case (SimCode.RECORD_DECL_FULL(name = "OpenModelica_threadData_ThreadData")::rest, _)
     equation
       acc = removeThreadDataRecord(rest, inAcc);
     then
       acc;

    case (SimCode.RECORD_DECL_DEF(path = Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("threadData",Absyn.IDENT("ThreadData"))))::rest, _)
     equation
       acc = removeThreadDataRecord(rest, inAcc);
     then
       acc;

    case (r::rest, _)
     equation
       acc = removeThreadDataRecord(rest, r::inAcc);
     then
       acc;

  end match;
end removeThreadDataRecord;

protected function removeThreadDataFunction
"remove OpenModelica.threadData.ThreadData
 as is already defined in openmodelica.h"
  input list<SimCode.Function> inFuncs;
  input list<SimCode.Function> inAcc;
  output list<SimCode.Function> outFuncs;
algorithm
  outFuncs := match(inFuncs, inAcc)
    local
      Absyn.Path p;
      list<SimCode.Function> acc, rest;
      SimCode.Function f;

    case ({}, _) then listReverse(inAcc);

    case (SimCode.RECORD_CONSTRUCTOR(name = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("threadData",Absyn.IDENT("ThreadData")))))::rest, _)
     equation
       acc = removeThreadDataFunction(rest, inAcc);
     then
       acc;

    case (f::rest, _)
     equation
       acc = removeThreadDataFunction(rest, f::inAcc);
     then
       acc;

  end match;
end removeThreadDataFunction;

public function getCalledFunctionsInFunction
"Goes through the given DAE, finds the given function and collects
  the names of the functions called from within those functions"
  input Absyn.Path path;
  input DAE.FunctionTree funcs;
  output list<Absyn.Path> outPaths;
protected
  HashTableStringToPath.HashTable ht;
algorithm
  ht := HashTableStringToPath.emptyHashTable();
  ht := SimCodeFunctionUtil.getCalledFunctionsInFunction2(path,Absyn.pathStringNoQual(path),ht,funcs);
  outPaths := BaseHashTable.hashTableValueList(ht);
end getCalledFunctionsInFunction;

annotation(__OpenModelica_Interface="backend");
end SimCodeFunction;
