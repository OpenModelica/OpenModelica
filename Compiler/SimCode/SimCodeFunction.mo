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
"The entry points to this module is the translateFunctions function."

// public imports
public
import Absyn;
import DAE;
import HashTableCrefSimVar;
import HashTableStringToPath;
import Tpl;

uniontype FunctionCode
  "Root data structure containing information required for templates to
  generate C functions for Modelica/MetaModelica functions."
  record FUNCTIONCODE
    String name;
    Option<Function> mainFunction "This function is special; the 'in'-function should be generated for it";
    list<Function> functions;
    list<DAE.Exp> literals "shared literals";
    list<String> externalFunctionIncludes;
    MakefileParams makefileParams;
    list<RecordDeclaration> extraRecordDecls;
  end FUNCTIONCODE;
end FunctionCode;

// TODO: I believe some of these fields can be removed. Check to see what is
//       used in templates.
uniontype Function
  "Represents a Modelica or MetaModelica function."
  record FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<DAE.Statement> body;
    SCode.Visibility visibility;
    SourceInfo info;
  end FUNCTION;

  record PARALLEL_FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<DAE.Statement> body;
    SourceInfo info;
  end PARALLEL_FUNCTION;

  record KERNEL_FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<DAE.Statement> body;
    SourceInfo info;
  end KERNEL_FUNCTION;

  record EXTERNAL_FUNCTION
    Absyn.Path name;
    String extName;
    list<Variable> funArgs;
    list<SimExtArg> extArgs;
    SimExtArg extReturn;
    list<Variable> inVars;
    list<Variable> outVars;
    list<Variable> biVars;
    list<String> includes "this one is needed so that we know if we should generate the external function prototype or not";
    list<String> libs "need this one for C#";
    String language "C or Fortran";
    SCode.Visibility visibility;
    SourceInfo info;
    Boolean dynamicLoad;
  end EXTERNAL_FUNCTION;

  record RECORD_CONSTRUCTOR
    Absyn.Path name;
    list<Variable> funArgs;
    list<Variable> locals;
    SCode.Visibility visibility;
    SourceInfo info;
  end RECORD_CONSTRUCTOR;
end Function;

uniontype RecordDeclaration

  record RECORD_DECL_FULL
    String name "struct (record) name ? encoded";
    Option<String> aliasName "alias of struct (record) name ? encoded. Code generators can generate an aliasing typedef using this, and avoid problems when casting a record from one type to another (*(othertype*)(&var)), which only works if you have a lhs value.";
    Absyn.Path defPath "definition path";
    list<Variable> variables "only name and type";
  end RECORD_DECL_FULL;

  record RECORD_DECL_DEF
    Absyn.Path path "definition path .. encoded?";
    list<String> fieldNames;
  end RECORD_DECL_DEF;

end RecordDeclaration;

uniontype MakefileParams
  "Platform specific parameters used when generating makefiles."
  record MAKEFILE_PARAMS
    String ccompiler;
    String cxxcompiler;
    String linker;
    String exeext;
    String dllext;
    String omhome;
    String cflags;
    String ldflags;
    String runtimelibs "Libraries that are required by the runtime library";
    list<String> includes;
    list<String> libs;
    list<String> libPaths;
    String platform;
    String compileDir;
  end MAKEFILE_PARAMS;
end MakefileParams;

uniontype SimExtArg
  "Information about an argument to an external function."
  record SIMEXTARG
    DAE.ComponentRef cref;
    Boolean isInput;
    Integer outputIndex "> 0 if output";
    Boolean isArray;
    Boolean hasBinding "avoid double allocation";
    DAE.Type type_;
  end SIMEXTARG;
  record SIMEXTARGEXP
    DAE.Exp exp;
    DAE.Type type_;
  end SIMEXTARGEXP;
  record SIMEXTARGSIZE
    DAE.ComponentRef cref;
    Boolean isInput;
    Integer outputIndex "> 0 if output";
    DAE.Type type_;
    DAE.Exp exp;
  end SIMEXTARGSIZE;
  record SIMNOEXTARG end SIMNOEXTARG;
end SimExtArg;

uniontype Variable
  "a variable represents a name, a type and a possible default value"
  record VARIABLE
    DAE.ComponentRef name;
    DAE.Type ty;
    Option<DAE.Exp> value "default value";
    list<DAE.Exp> instDims;
    DAE.VarParallelism parallelism;
    DAE.VarKind kind;
  end VARIABLE;

  record FUNCTION_PTR
    String name;
    list<DAE.Type> tys;
    list<Variable> args;
    Option<DAE.Exp> defaultValue "default value";
  end FUNCTION_PTR;
end Variable;

uniontype Context
  "Constants of this type defined below are used by templates to be able to
  generate different code depending on the context it is generated in."
  record SIMULATION_CONTEXT
    Boolean genDiscrete;
  end SIMULATION_CONTEXT;

  record FUNCTION_CONTEXT
  end FUNCTION_CONTEXT;

  record ALGLOOP_CONTEXT
     Boolean genInitialisation;
     Boolean genJacobian;
  end ALGLOOP_CONTEXT;

   record JACOBIAN_CONTEXT
     Option<HashTableCrefSimVar.HashTable> jacHT;
   end JACOBIAN_CONTEXT;

  record OTHER_CONTEXT
  end OTHER_CONTEXT;

  record PARALLEL_FUNCTION_CONTEXT
  end PARALLEL_FUNCTION_CONTEXT;

  record ZEROCROSSINGS_CONTEXT
  end ZEROCROSSINGS_CONTEXT;

  record OPTIMIZATION_CONTEXT
  end OPTIMIZATION_CONTEXT;

  record FMI_CONTEXT
  end FMI_CONTEXT;

  record DAE_MODE_CONTEXT
  end DAE_MODE_CONTEXT;

  record OMSI_CONTEXT
    Option<HashTableCrefSimVar.HashTable> hashTable "used to get local SimVars and corresponding value references";
  end OMSI_CONTEXT;
end Context;

public constant Context contextSimulationNonDiscrete  = SIMULATION_CONTEXT(false);
public constant Context contextSimulationDiscrete     = SIMULATION_CONTEXT(true);
public constant Context contextFunction               = FUNCTION_CONTEXT();
public constant Context contextJacobian               = JACOBIAN_CONTEXT(NONE());
public constant Context contextAlgloopJacobian        = ALGLOOP_CONTEXT(false,true);
public constant Context contextAlgloopInitialisation  = ALGLOOP_CONTEXT(true,false);
public constant Context contextAlgloop                = ALGLOOP_CONTEXT(false,false);
public constant Context contextOther                  = OTHER_CONTEXT();
public constant Context contextParallelFunction       = PARALLEL_FUNCTION_CONTEXT();
public constant Context contextZeroCross              = ZEROCROSSINGS_CONTEXT();
public constant Context contextOptimization           = OPTIMIZATION_CONTEXT();
public constant Context contextFMI                    = FMI_CONTEXT();
public constant Context contextDAEmode                = DAE_MODE_CONTEXT();
public constant Context contextOMSI                   = OMSI_CONTEXT(NONE());

constant list<DAE.Exp> listExpLength1 = {DAE.ICONST(0)} "For CodegenC.tpl";
constant list<Variable> boxedRecordOutVars = VARIABLE(DAE.CREF_IDENT("",DAE.T_COMPLEX_DEFAULT_RECORD,{}),DAE.T_COMPLEX_DEFAULT_RECORD,NONE(),{},DAE.NON_PARALLEL(),DAE.VARIABLE())::{} "For CodegenC.tpl";

// protected imports
protected
import BaseHashTable;
import CodegenCFunctions;
import CodegenMidToC;
import Global;
import SimCodeFunctionUtil;
import MidCode;
import DAEToMid;

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
      Function mainFunction;
      list<Function> fns;
      list<String> includes, libs, libPaths,includeDirs;
      MakefileParams makefileParams;
      FunctionCode fnCode;
      list<RecordDeclaration> extraRecordDecls;
      list<DAE.Exp> literals;
      list<DAE.Function> daeElements;
      Tpl.Text midCode;
      list<MidCode.Function> midfuncs;
    case (_, _, SOME(daeMainFunction), daeElements, _, includes)
      equation
        // Create FunctionCode
        (daeElements,literals) = SimCodeFunctionUtil.findLiterals(daeMainFunction::daeElements);
        (mainFunction::fns, extraRecordDecls, includes, includeDirs, libs, libPaths) = SimCodeFunctionUtil.elaborateFunctions(program, daeElements, metarecordTypes, literals, includes);
        SimCodeFunctionUtil.checkValidMainFunction(name, mainFunction);
        makefileParams = SimCodeFunctionUtil.createMakefileParams(includeDirs, libs, libPaths, true);
        fnCode = FUNCTIONCODE(name, SOME(mainFunction), fns, literals, includes, makefileParams, extraRecordDecls);

        if Config.simCodeTarget() == "MidC" then
          _ = Tpl.tplString(CodegenCFunctions.translateFunctionHeaderFiles, fnCode);
          midfuncs = DAEToMid.DAEFunctionsToMid(mainFunction::fns);
          midCode = Tpl.tplCallWithFailError(CodegenMidToC.genProgram, MidCode.PROGRAM(name, midfuncs));
          _ = Tpl.textFileConvertLines(midCode, name + ".c");
        else
          _ = Tpl.tplString(CodegenCFunctions.translateFunctions, fnCode);
        end if;
      then
        ();
    case (_, _, NONE(), daeElements, _, includes)
      equation
        // Create FunctionCode
        (daeElements,literals) = SimCodeFunctionUtil.findLiterals(daeElements);
        (fns, extraRecordDecls, includes, includeDirs, libs, libPaths) = SimCodeFunctionUtil.elaborateFunctions(program, daeElements, metarecordTypes, literals, includes);
        makefileParams = SimCodeFunctionUtil.createMakefileParams(includeDirs, libs, libPaths, true);
        // remove OpenModelica.threadData.ThreadData
        fns = removeThreadDataFunction(fns, {});
        extraRecordDecls = removeThreadDataRecord(extraRecordDecls, {});
        fnCode = FUNCTIONCODE(name, NONE(), fns, literals, includes, makefileParams, extraRecordDecls);

        if Config.simCodeTarget() == "MidC" then
          _ = Tpl.tplString(CodegenCFunctions.translateFunctionHeaderFiles, fnCode);
          midfuncs = DAEToMid.DAEFunctionsToMid(fns);
          midCode = Tpl.tplCallWithFailError(CodegenMidToC.genProgram, MidCode.PROGRAM(name, midfuncs));
          _ = Tpl.textFileConvertLines(midCode, name + ".c");
        else
          _ = Tpl.tplString(CodegenCFunctions.translateFunctions, fnCode);
        end if;
      then
        ();

  end match;
end translateFunctions;

protected function removeThreadDataRecord
"remove OpenModelica.threadData.ThreadData
 as is already defined in openmodelica.h"
  input list<RecordDeclaration> inRecs;
  input list<RecordDeclaration> inAcc;
  output list<RecordDeclaration> outRecs;
algorithm
  outRecs := match(inRecs, inAcc)
    local
      Absyn.Path p;
      list<RecordDeclaration> acc, rest;
      RecordDeclaration r;

    case ({}, _) then listReverse(inAcc);

    case (RECORD_DECL_FULL(name = "OpenModelica_threadData_ThreadData")::rest, _)
     equation
       acc = removeThreadDataRecord(rest, inAcc);
     then
       acc;

    case (RECORD_DECL_DEF(path = Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("threadData",Absyn.IDENT("ThreadData"))))::rest, _)
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
  input list<Function> inFuncs;
  input list<Function> inAcc;
  output list<Function> outFuncs;
algorithm
  outFuncs := match(inFuncs, inAcc)
    local
      Absyn.Path p;
      list<Function> acc, rest;
      Function f;

    case ({}, _) then listReverse(inAcc);

    case (RECORD_CONSTRUCTOR(name = Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("OpenModelica",Absyn.QUALIFIED("threadData",Absyn.IDENT("ThreadData")))))::rest, _)
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
