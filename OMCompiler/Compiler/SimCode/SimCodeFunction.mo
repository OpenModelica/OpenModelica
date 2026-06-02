/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SimCodeFunction
"The entry points to this module is the translateFunctions function."

// public imports
public import Absyn;
public import AbsynUtil;
public import DAE;
public import HashTableCrefSimVar;
public import HashTableStringToPath;

// private imports
protected import BaseHashTable;
protected import ComponentReferenceBasics;
protected import ExpressionBasics;
protected import Error;
protected import List;
protected import SCode;
protected import TypesDump;

public uniontype FunctionCode
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
public uniontype Function
  "Represents a Modelica, MetaModelica or external function."
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

  function toString
  "Print for debugging purpose"
    input Function func;
    output String str = "";
  algorithm
    str := match func
      local
        String tmp = "";
        list<String> ls;
      case FUNCTION() algorithm
        tmp := tmp + "name: " + AbsynUtil.pathString(func.name);
      then "FUNCTION(" + tmp + ")";
      case PARALLEL_FUNCTION() algorithm
        tmp := tmp + "name: " + AbsynUtil.pathString(func.name);
      then "PARALLEL_FUNCTION(" + tmp + ")";
      case KERNEL_FUNCTION() algorithm
        tmp := tmp + "name: " + AbsynUtil.pathString(func.name);
      then "KERNEL_FUNCTION(" + tmp + ")";
      case EXTERNAL_FUNCTION() algorithm
        tmp := "\n";
        tmp := tmp + "  name: " + AbsynUtil.pathString(func.name) + ",\n";
        tmp := tmp + "  extName: " + func.extName + ",\n";
        ls := List.map(func.funArgs, Variable.toString);
        tmp := tmp + "  funArgs: {" + stringDelimitList(ls, ", ") + "},\n";
        ls := List.map(func.extArgs, SimExtArg.toString);
        tmp := tmp + "  extArgs: {" + stringDelimitList(ls, ", ") + "},\n";
        tmp := tmp + "  extReturn: " + SimExtArg.toString(func.extReturn) + ",\n";
        ls := List.map(func.inVars, Variable.toString);
        tmp := tmp + "  inVars: {" + stringDelimitList(ls, ", ") + "},\n";
        ls := List.map(func.outVars, Variable.toString);
        tmp := tmp + "  outVars: {" + stringDelimitList(ls, ", ") + "},\n";
        ls := List.map(func.biVars, Variable.toString);
        tmp := tmp + "  biVars: {" + stringDelimitList(ls, ", ") + "},\n";
        tmp := tmp + "  includes: {" + stringDelimitList(func.includes, ", ") + "},\n";
        tmp := tmp + "  libs: {" + stringDelimitList(func.libs, ", ") + "},\n";
        tmp := tmp + "  language: " + func.language + "\n";
      then "EXTERNAL_FUNCTION(" + tmp + ")";
      case RECORD_CONSTRUCTOR() algorithm
        tmp := tmp + "name: " + AbsynUtil.pathString(func.name);
      then "RECORD_CONSTRUCTOR(" + tmp + ")";
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
      then fail();
    end match;
  end toString;
end Function;

public uniontype RecordDeclaration

  record RECORD_DECL_FULL
    String name "struct (record) name ? encoded";
    Option<String> aliasName "alias of struct (record) name ? encoded. Code generators can generate an aliasing typedef using this, and avoid problems when casting a record from one type to another (*(othertype*)(&var)), which only works if you have a lhs value.";
    Absyn.Path defPath "definition path";
    list<Variable> variables "only name and type";
    Boolean usedExternally "If the record is passed to an external function at any point, we need to generate conversion functions for it (for instance to convert 'modelica_integer' to 'int')";
  end RECORD_DECL_FULL;

  record RECORD_DECL_ADD_CONSTRCTOR
    String ctor_name "A unique name for the new constor. e.g. R_1_3() if it needs the 1st an 3rd members as inputs";
    String name "The record's name";
    list<Variable> variables "The members with the ones that need outisde binding marked. e.g 1st and 3rd elements will have bind_from_outside=true ";
  end RECORD_DECL_ADD_CONSTRCTOR;

  record RECORD_DECL_DEF
    Absyn.Path path "definition path .. encoded?";
    list<String> fieldNames;
  end RECORD_DECL_DEF;

end RecordDeclaration;

public uniontype MakefileParams
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

public uniontype SimExtArg
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

  function toString
    input SimExtArg simExtArg;
    output String str = "";
  algorithm
    str := match simExtArg
      local
        String tmp = "";
      case SIMEXTARG() algorithm
        tmp := tmp + "cref: " + ComponentReferenceBasics.printComponentRefStr(simExtArg.cref);
        tmp := if simExtArg.isInput then tmp + ", isInput: true" else tmp + ", isInput: false";
        tmp := tmp + ", outputIndex: " + intString(simExtArg.outputIndex);
        tmp := if simExtArg.isArray then tmp + ", isArray: true" else tmp + ", isArray: false";
        tmp := if simExtArg.hasBinding then tmp + ", hasBinding: true" else tmp + ", hasBinding: false";
        tmp := tmp + ", type: " + TypesDump.unparseType(simExtArg.type_);
      then "SIMEXTARG(" + tmp + ")";

      case SIMEXTARGEXP() algorithm
        tmp := tmp + "exp: " + ExpressionBasics.printExpStr(simExtArg.exp);
        tmp := tmp + ", type: " + TypesDump.unparseType(simExtArg.type_);
      then "SIMEXTARGEXP(" + tmp + ")";

      case SIMEXTARGSIZE() algorithm
        tmp := tmp + "cref: " + ComponentReferenceBasics.printComponentRefStr(simExtArg.cref);
        tmp := if simExtArg.isInput then tmp + ", isInput: true" else tmp + ", isInput: false";
        tmp := tmp + ", outputIndex: " + intString(simExtArg.outputIndex);
        tmp := tmp + ", type: " + TypesDump.unparseType(simExtArg.type_);
        tmp := tmp + ", exp: " + ExpressionBasics.printExpStr(simExtArg.exp);
      then "SIMEXTARGSIZE(" + tmp + ")";

      case SIMNOEXTARG()
      then "SIMNOEXTARG()";

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
      then fail();
    end match;
  end toString;
end SimExtArg;

public uniontype Variable
  "A variable represents a name, a type and a possible default value"
  record VARIABLE
    DAE.ComponentRef name;
    DAE.Type ty;
    Option<DAE.Exp> value "default value";
    list<DAE.Dimension> instDims;
    DAE.VarParallelism parallelism;
    DAE.VarKind kind;
    Boolean bind_from_outside;
  end VARIABLE;

  record FUNCTION_PTR
    String name;
    list<DAE.Type> tys;
    list<Variable> args;
    Option<DAE.Exp> defaultValue "default value";
  end FUNCTION_PTR;

  function toString
    input Variable variable;
    output String str = "";
  algorithm
    str := match variable
      local
        String tmp = "";
      case VARIABLE() algorithm
        tmp := tmp + "name: " + ComponentReferenceBasics.printComponentRefStr(variable.name);
        tmp := tmp + ", type: " + TypesDump.unparseType(variable.ty);
      then "VARIABLE(" + tmp + ")";
      case FUNCTION_PTR() algorithm
        tmp := tmp + "name: " + variable.name;
      then "FUNCTION_PTR(" + tmp + ")";
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for an unknown reason."});
      then fail();
    end match;
  end toString;
end Variable;

public uniontype Context
  "Constants of this type defined below are used by templates to be able to
  generate different code depending on the context it is generated in."
  record SIMULATION_CONTEXT
    Boolean genDiscrete;
  end SIMULATION_CONTEXT;

  record FUNCTION_CONTEXT
    String cref_prefix;
    Boolean is_parallel;
  end FUNCTION_CONTEXT;

  record ALGLOOP_CONTEXT
    Boolean genInitialisation;
    Boolean genJacobian;
  end ALGLOOP_CONTEXT;

  record JACOBIAN_CONTEXT
    String name;
    Option<HashTableCrefSimVar.HashTable> jacHT;
  end JACOBIAN_CONTEXT;

  record OTHER_CONTEXT
  end OTHER_CONTEXT;

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
public constant Context contextFunction               = FUNCTION_CONTEXT("", false);
public constant Context contextJacobian               = JACOBIAN_CONTEXT("", NONE());
public constant Context contextAlgloopJacobian        = ALGLOOP_CONTEXT(false,true);
public constant Context contextAlgloopInitialisation  = ALGLOOP_CONTEXT(true,false);
public constant Context contextAlgloop                = ALGLOOP_CONTEXT(false,false);
public constant Context contextOther                  = OTHER_CONTEXT();
public constant Context contextParallelFunction       = FUNCTION_CONTEXT("", true);
public constant Context contextZeroCross              = ZEROCROSSINGS_CONTEXT();
public constant Context contextOptimization           = OPTIMIZATION_CONTEXT();
public constant Context contextFMI                    = FMI_CONTEXT();
public constant Context contextDAEmode                = DAE_MODE_CONTEXT();
public constant Context contextOMSI                   = OMSI_CONTEXT(NONE());

constant list<DAE.Exp> listExpLength1 = {DAE.ICONST(0)} "For CodegenC.tpl";
constant list<Variable> boxedRecordOutVars = VARIABLE(DAE.CREF_IDENT("",DAE.T_COMPLEX_DEFAULT_RECORD,{}),DAE.T_COMPLEX_DEFAULT_RECORD,NONE(),{},DAE.NON_PARALLEL(),DAE.VARIABLE(), false)::{} "For CodegenC.tpl";

annotation(__OpenModelica_Interface="simcode_types");
end SimCodeFunction;
