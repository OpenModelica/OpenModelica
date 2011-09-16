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

encapsulated package SimCode
" file:        SimCode.mo
  package:     SimCode
  description: Code generation using Susan templates

  RCS: $Id$

  The entry points to this module are the translateModel function and the
  translateFunctions fuction.

  Except for the entry points, the only other public functions are those that
  can be imported and called from templates.
  
  The number of imported functions should be kept as low as possible. Today
  some of them are needed to generate target code from templates. More careful
  design of data structures passed to templates should reduce the number of
  imported functions needed.

  Many of the functions in this module were originally copied from the Codegen
  and SimCodegen modules.
"

// public imports
public import Absyn;
public import Algorithm;
public import BackendDAE;
public import BackendDAEUtil;
public import Ceval;
public import DAE;
public import Dependency;
public import Env;
public import HashTableExpToIndex;
public import HashTableStringToPath;
public import Inline;
public import Interactive;
public import SCode;
public import Tpl;
public import Types;
public import Values;

// protected imports
protected import BackendDAECreate;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendDump;
protected import BackendEquation;
protected import BackendQSS;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashTable;
protected import Builtin;
protected import CevalScript;
protected import ClassInf;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import InnerOuter;
protected import Inst;
protected import Mod;
protected import ModUtil;
protected import PartFn;
protected import RTOpts;
protected import SCodeUtil;
protected import Settings;
protected import SimCodeC;
protected import SimCodeCpp;
protected import SimCodeCSharp;
protected import SimCodeDump;
protected import SimCodeFMU;
protected import SimCodeQSS;
protected import SimCodeAdevs;
protected import System;
protected import Util;
protected import ValuesUtil;
protected import VarTransform;


public
type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
type ExtDestructor = tuple<String, DAE.ComponentRef>;
type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;
type HelpVarInfo = tuple<Integer, DAE.Exp, Integer>; // helpvarindex, expression, whenclause index
type SampleCondition = tuple<DAE.Exp,Integer>; // helpvarindex, expression,
type JacobianColumn = tuple<list<SimEqSystem>, list<SimVar>, String>;
type JacobianMatrix = tuple<list<JacobianColumn>,list<SimVar>,String>;
  
public constant list<DAE.Exp> listExpLength1 = {DAE.ICONST(0)} "For SimCodeC.tpl";

// Root data structure containing information required for templates to
// generate simulation code for a Modelica model.
uniontype SimCode
  record SIMCODE
    ModelInfo modelInfo;
    list<DAE.Exp> literals "shared literals";
    list<RecordDeclaration> recordDecls;
    list<String> externalFunctionIncludes;
    list<SimEqSystem> allEquations;
    list<SimEqSystem> odeEquations;
    list<SimEqSystem> algebraicEquations;
    list<SimEqSystem> residualEquations;
    list<SimEqSystem> initialEquations;
    list<SimEqSystem> parameterEquations;
    list<SimEqSystem> removedEquations;
    list<DAE.Statement> algorithmAndEquationAsserts;
    list<BackendDAE.ZeroCrossing> zeroCrossings;
    list<SampleCondition> sampleConditions;
    list<SimEqSystem> sampleEquations;
    list<HelpVarInfo> helpVarInfo;
    list<SimWhenClause> whenClauses;
    list<DAE.ComponentRef> discreteModelVars;
    ExtObjInfo extObjInfo;
    MakefileParams makefileParams;
    DelayedExpression delayedExps;
    list<JacobianMatrix> jacobianMatrixes;
    Option<SimulationSettings> simulationSettingsOpt;
    String fileNamePrefix;
    
    //*** a protected section *** not exported to SimCodeTV
    HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
  end SIMCODE;
end SimCode;

// Delayed expressions type
uniontype DelayedExpression
  record DELAYED_EXPRESSIONS
    list<tuple<Integer, DAE.Exp>> delayedExps;
    Integer maxDelayedIndex;
  end DELAYED_EXPRESSIONS;
end DelayedExpression;

// Root data structure containing information required for templates to
// generate C functions for Modelica/MetaModelica functions.
uniontype FunctionCode
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

// Container for metadata about a Modelica model.
uniontype ModelInfo
  record MODELINFO
    Absyn.Path name;
    String directory;
    VarInfo varInfo;
    SimVars vars;
    list<Function> functions;
    //Files files "all the files from Absyn.Info and DAE.ELementSource";
  end MODELINFO;
end ModelInfo;

type Files = list<FileInfo>;

uniontype FileInfo 
  "contains all the .mo files present in all Absyn.Info and DAE.ElementSource.info 
   of all the variables, functions, etc from SimCode that have origin info.
   it is used to generate the file information in one place and use an index
   whenever we need to refer to one file from a var or function.
   this is done so that we don't repeat long filenames everywhere."
  record FILEINFO
    String fileName "fileName where the class/component is defined in";
    Boolean isReadOnly "isReadOnly : (true|false). Should be true for libraries";    
  end FILEINFO;
end FileInfo;

// Number of variables of various types in a Modelica model.
uniontype VarInfo
  record VARINFO
    Integer numHelpVars;
    Integer numZeroCrossings;
    Integer numTimeEvents;
    Integer numStateVars;
    Integer numAlgVars;
    Integer numIntAlgVars;
    Integer numBoolAlgVars;
    Integer numAlgAliasVars;
    Integer numIntAliasVars;
    Integer numBoolAliasVars;
    Integer numParams;
    Integer numIntParams;
    Integer numBoolParams;
    Integer numOutVars;
    Integer numInVars;
    Integer numResiduals;
    Integer numExternalObjects;
    Integer numStringAlgVars;
    Integer numStringParamVars;
    Integer numStringAliasVars;
    Integer numJacobianVars;
    Option <Integer> dimODE1stOrder;
    Option <Integer> dimODE2ndOrder;
  end VARINFO;
end VarInfo;

// Container for metadata about variables in a Modelica model.
uniontype SimVars
  record SIMVARS
    list<SimVar> stateVars;
    list<SimVar> derivativeVars;
    list<SimVar> algVars;
    list<SimVar> intAlgVars;
    list<SimVar> boolAlgVars;
    list<SimVar> inputVars;
    list<SimVar> outputVars;
    list<SimVar> aliasVars;
    list<SimVar> intAliasVars;
    list<SimVar> boolAliasVars;
    list<SimVar> paramVars;
    list<SimVar> intParamVars;
    list<SimVar> boolParamVars;
    list<SimVar> stringAlgVars;
    list<SimVar> stringParamVars;
    list<SimVar> stringAliasVars;
    list<SimVar> extObjVars;
    list<SimVar> jacobianVars; //all vars for the matrices A,B,C,D
    list<SimVar> constVars;
    list<SimVar> intConstVars;
    list<SimVar> boolConstVars;
    list<SimVar> stringConstVars;
  end SIMVARS;
end SimVars;

// Information about a variable in a Modelica model.
uniontype SimVar
  record SIMVAR
    DAE.ComponentRef name;
    BackendDAE.VarKind varKind;
    String comment;
    String unit;
    String displayUnit;
    Integer index;
    Option<DAE.Exp> initialValue;
    Option<DAE.Exp> nominalValue;
    Boolean isFixed;
    DAE.ExpType type_;
    Boolean isDiscrete;
    // arrayCref is the name of the array if this variable is the first in that
    // array
    Option<DAE.ComponentRef> arrayCref;
    AliasVariable aliasvar;
    DAE.ElementSource source;
    Causality causality;
    Option<Integer> variable_index;
    list <String> numArrayElement;
    
  end SIMVAR;
end SimVar;

uniontype AliasVariable
  record NOALIAS end NOALIAS;
  record ALIAS 
    DAE.ComponentRef varName;
  end ALIAS;
  record NEGATEDALIAS 
    DAE.ComponentRef varName;
  end NEGATEDALIAS;
end AliasVariable;

uniontype Causality
  record NONECAUS end NONECAUS;
  record INTERNAL end INTERNAL;
  record OUTPUT end OUTPUT;
  record INPUT end INPUT;
end Causality;

// Represents a Modelica or MetaModelica function.
// TODO: I believe some of these fields can be removed. Check to see what is
//       used in templates.
uniontype Function
  record FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<Statement> body;
    Absyn.Info info;
  end FUNCTION;
  record EXTERNAL_FUNCTION
    Absyn.Path name;
    String extName;
    list<Variable> funArgs;
    list<SimExtArg> extArgs;
    SimExtArg extReturn;
    list<Variable> inVars;
    list<Variable> outVars;
    list<Variable> biVars;
    list<String> libs; //need this one for C#
    String language "C or Fortran";
    Absyn.Info info;
    Boolean dynamicLoad;
  end EXTERNAL_FUNCTION;
  record RECORD_CONSTRUCTOR
    Absyn.Path name;
    list<Variable> funArgs;
    Absyn.Info info;
  end RECORD_CONSTRUCTOR;
end Function;

uniontype RecordDeclaration
  record RECORD_DECL_FULL
    String name; // struct (record) name ? encoded
    Absyn.Path defPath; //definition path
    list<Variable> variables; //only name and type
  end RECORD_DECL_FULL;
  record RECORD_DECL_DEF
    Absyn.Path path; //definition path .. encoded ?
    list<String> fieldNames;
  end RECORD_DECL_DEF;
end RecordDeclaration;

// Information about an argument to an external function.
uniontype SimExtArg
  record SIMEXTARG
    DAE.ComponentRef cref;
    Boolean isInput;
    Integer outputIndex; // > 0 if output
    Boolean isArray;
    Boolean hasBinding "avoid double allocation";
    DAE.ExpType type_;
  end SIMEXTARG;
  record SIMEXTARGEXP
    DAE.Exp exp;
    DAE.ExpType type_;
  end SIMEXTARGEXP;
  record SIMEXTARGSIZE
    DAE.ComponentRef cref;
    Boolean isInput;
    Integer outputIndex; // > 0 if output
    DAE.ExpType type_;
    DAE.Exp exp;
  end SIMEXTARGSIZE;
  record SIMNOEXTARG end SIMNOEXTARG;
end SimExtArg;

/* a variable represents a name, a type and a possible default value */
uniontype Variable
  record VARIABLE
    DAE.ComponentRef name;
    DAE.ExpType ty;
    Option<DAE.Exp> value; // Default value
    list<DAE.Exp> instDims;
  end VARIABLE;
  
  record FUNCTION_PTR
    String name;
    list<DAE.ExpType> tys;
    list<Variable> args;
  end FUNCTION_PTR;
end Variable;

// TODO: Replace Statement with just list<Algorithm.Statement>?
uniontype Statement
  record ALGORITHM
    list<Algorithm.Statement> statementLst; // in functions
  end ALGORITHM;
end Statement;

// Represents a single equation or a system of equations that must be solved
// together.
uniontype SimEqSystem
  record SES_RESIDUAL
    DAE.Exp exp;
    DAE.ElementSource source;
  end SES_RESIDUAL;
  record SES_SIMPLE_ASSIGN
    DAE.ComponentRef cref;
    DAE.Exp exp;
    DAE.ElementSource source;
  end SES_SIMPLE_ASSIGN;
  record SES_ARRAY_CALL_ASSIGN
    DAE.ComponentRef componentRef;
    DAE.Exp exp;
    DAE.ElementSource source;
  end SES_ARRAY_CALL_ASSIGN;
  record SES_ALGORITHM
    list<DAE.Statement> statements;
  end SES_ALGORITHM;
  record SES_LINEAR
    Integer index;
    Boolean partOfMixed;
    list<SimVar> vars;
    list<DAE.Exp> beqs;
    list<tuple<Integer, Integer, SimEqSystem>> simJac;
  end SES_LINEAR;
  record SES_NONLINEAR
    Integer index;
    list<SimEqSystem> eqs;
    list<DAE.ComponentRef> crefs;
  end SES_NONLINEAR;
  record SES_MIXED
    Integer index;
    SimEqSystem cont;
    list<SimVar> discVars;
    list<SimEqSystem> discEqs;
    list<Integer> values;
    list<Integer> value_dims;
  end SES_MIXED;
  record SES_WHEN
    DAE.ComponentRef left;
    DAE.Exp right;
    list<tuple<DAE.Exp, Integer>> conditions; // condition, help var index
    Option<SimEqSystem> elseWhen;
    DAE.ElementSource source;
  end SES_WHEN;
end SimEqSystem;

uniontype SimWhenClause
  record SIM_WHEN_CLAUSE
    list<DAE.ComponentRef> conditionVars;
    list<BackendDAE.WhenOperator> reinits;
    Option<BackendDAE.WhenEquation> whenEq;
    list<tuple<DAE.Exp, Integer>> conditions; // condition, help var index
  end SIM_WHEN_CLAUSE;
end SimWhenClause;

uniontype ExtObjInfo
  record EXTOBJINFO
    list<SimVar> vars;
    list<ExtAlias> aliases;
  end EXTOBJINFO;
end ExtObjInfo;

// Platform specific parameters used when generating makefiles.
uniontype MakefileParams
  record MAKEFILE_PARAMS
    String ccompiler;
    String cxxcompiler;
    String linker;
    String exeext;
    String dllext;
    String omhome;
    String cflags;
    String ldflags;
    String senddatalibs;
    list<String> includes;
    list<String> libs;
    String platform;
  end MAKEFILE_PARAMS;
end MakefileParams;


uniontype SimulationSettings 
  "Settings for simulation init file header."
  record SIMULATION_SETTINGS
    Real startTime;
    Real stopTime;
    Integer numberOfIntervals;
    Real stepSize;
    Real tolerance;
    String method;
    String options;
    String outputFormat;
    String variableFilter;
    Boolean measureTime;
    String cflags;
  end SIMULATION_SETTINGS;
end SimulationSettings;

// Constants of this type defined below are used by templates to be able to
// generate different code depending on the context it is generated in.
uniontype Context
  record SIMULATION
    Boolean genDiscrete;
  end SIMULATION;
  record FUNCTION_CONTEXT
  end FUNCTION_CONTEXT;
  record OTHER
  end OTHER;
  record INLINE_CONTEXT
  end INLINE_CONTEXT;
end Context;


public constant Context contextSimulationNonDiscrete  = SIMULATION(false);
public constant Context contextSimulationDiscrete     = SIMULATION(true);
public constant Context contextInlineSolver           = INLINE_CONTEXT();
public constant Context contextFunction               = FUNCTION_CONTEXT();
public constant Context contextOther                  = OTHER();


public function elementVars
"Used by templates to get a list of variables from a valueblock."
  input list<DAE.Element> ld;
  output list<Variable> vars;
algorithm
  ld := Util.listFilter(ld, isVarQ);
  vars := Util.listMap(ld, daeInOutSimVar);
end elementVars;

public function crefSubIsScalar
"Used by templates to determine if a component reference's subscripts are
 scalar."
  input DAE.ComponentRef cref;
  output Boolean isScalar;
protected
  list<DAE.Subscript> subs;
algorithm
  subs := ComponentReference.crefSubs(cref);
  isScalar := subsToScalar(subs);
end crefSubIsScalar;

public function crefNoSub
"Used by templates to determine if a component reference has no subscripts."
  input DAE.ComponentRef cref;
  output Boolean noSub;
algorithm
  noSub := boolNot(ComponentReference.crefHaveSubs(cref));
end crefNoSub;

public function crefIsScalar
  "Whether a component reference is a scalar depends on what context we are in.
  If we are generating code for a function, then only crefs without subscripts
  are scalar. If we are generating code for simulation though, then crefs with
  only constant subscripts are also scalars, since a variable is generated for
  each element of an array in the model."
  input DAE.ComponentRef cref;
  input Context context;
  output Boolean isScalar;
algorithm
  isScalar := matchcontinue(cref, context)
    local
      Boolean res;
    case (_, FUNCTION_CONTEXT())
      equation
        res = crefNoSub(cref);
      then
        res;
    case (_, _)
      equation
        res = ComponentReference.crefHasScalarSubscripts(cref);
      then
        res;
  end matchcontinue;
end crefIsScalar;

public function buildCrefExpFromAsub
"Used by templates to convert an ASUB expression to a component reference
 with subscripts."
  input DAE.Exp cref;
  input list<DAE.Exp> subs;
  output DAE.Exp cRefOut;
algorithm
  cRefOut := matchcontinue(cref, subs)
    local
      DAE.Exp crefExp;
      DAE.ExpType ty;
      DAE.ComponentRef crNew;
      list<DAE.Subscript> indexes;
      
    case (cref, {}) then cref;
    case (DAE.CREF(componentRef=crNew, ty=ty), subs)
      equation
        indexes = Util.listMap(subs, Expression.makeIndexSubscript);
        crNew = ComponentReference.subscriptCref(crNew, indexes);
        crefExp = Expression.makeCrefExp(crNew, ty);
      then
        crefExp;
  end matchcontinue;
end buildCrefExpFromAsub;

public function incrementInt
"Used by templates to create new integers that are increments of another."
  input Integer inInt;
  input Integer increment;
  output Integer outInt;
algorithm
  outInt := inInt + increment;
end incrementInt;

public function decrementInt
"Used by templates to create new integers that are increments of another."
  input Integer inInt;
  input Integer decrement;
  output Integer outInt;
algorithm
  outInt := inInt - decrement;
end decrementInt;

public function makeCrefRecordExp
"function: makeCrefRecordExp
  Helper function to generate records."
  input DAE.ComponentRef inCRefRecord;
  input DAE.ExpVar inVar;
  output DAE.Exp outExp;
algorithm
  outExp := match (inCRefRecord,inVar)
    local
      DAE.ComponentRef cr,cr1;
      String name;
      DAE.ExpType tp;
    case (cr,DAE.COMPLEX_VAR(name=name,tp=tp))
      equation
        cr1 = ComponentReference.crefPrependIdent(cr,name,{},tp);
        outExp = Expression.makeCrefExp(cr1,tp);
      then
        outExp;
  end match;
end makeCrefRecordExp;

public function cref2simvar
"Used by templates to find SIMVAR for given cref (to gain representaion index info mainly)."
  input DAE.ComponentRef inCref;
  input SimCode simCode;
  output SimVar outSimVar;
algorithm
  outSimVar := matchcontinue(inCref, simCode)
    local
      DAE.ComponentRef cref, badcref;
      SimVar sv;
      HashTableCrefToSimVar crefToSimVarHT;
      String errstr;
      
    case (cref, SIMCODE(crefToSimVarHT = crefToSimVarHT) )
      equation
        sv = get(cref, crefToSimVarHT);
      then sv;
        
    case (cref, _)
      equation
        badcref = ComponentReference.makeCrefIdent("ERROR_cref2simvar_failed", DAE.ET_REAL(), {});
        //errstr = "Template did not find the simulation variable for "+& ComponentReference.printComponentRefStr(cref) +& ". ";
        //Error.addMessage(Error.INTERNAL_ERROR, {errstr});
      then
        SIMVAR(badcref, BackendDAE.STATE(), "", "", "", -1, NONE(), NONE(), false, DAE.ET_REAL(), false, NONE(), NOALIAS(), DAE.emptyElementSource, INTERNAL(),NONE(),{});
  end matchcontinue;
end cref2simvar;

public function derComponentRef
"Used by templates to derrive a cref in a der(cref) expression.
 Particularly, this function is called for the C# code generator,
 while for C/C++, it is solved by prefixing the cref with '$P$DER' in daeExpCall() template.
 The prefixing technique is not usable for C#, because there is no macroprocessor in C#.  
 TODO: all der(cref) expressions should be eliminated before the expressions enter templates
       to pull this logic (and this function) out of templates."
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef derCref;
algorithm
  derCref := ComponentReference.crefPrefixDer(inCref);
end derComponentRef;

public function hackArrayReverseToCref
"This is a hack transformation of an expanded array back to its cref.
It is used in daeExpArray() (for C# yet) to optimize the generated code.
TODO: This function should not exist! 
Rather the array should not be let expanded when SimCode is entering templates. 
"
  input DAE.Exp inExp;
  input Context context;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp, context)
    local
      list<DAE.Exp> aRest;
      DAE.ComponentRef cr;
      DAE.ExpType aty;
      DAE.Exp crefExp;
      
    case(DAE.ARRAY(ty=aty, scalar=true, array =(DAE.CREF(componentRef=cr) ::aRest)),context)
      equation
        failure(FUNCTION_CONTEXT()=context); //only in the function context
        { DAE.INDEX(DAE.ICONST(1)) } = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = isArrayExpansion(aRest, cr, 2);
        crefExp = Expression.makeCrefExp(cr, aty);
      then 
        crefExp;
        
    case(inExp, _) then inExp;
        
  end matchcontinue;
end hackArrayReverseToCref;

protected function isArrayExpansion
"Helper funtion to hackArrayReverseToCref."
  input list<DAE.Exp> inArrayElems;
  input DAE.ComponentRef inCref;
  input Integer index;
  output Boolean isExpanded;
algorithm
  isExpanded := matchcontinue(inArrayElems, inCref, index)
    local
      list<DAE.Exp> aRest;
      Integer i;
      DAE.ComponentRef cr;
    case({}, _,_) then true;
    case (DAE.CREF(componentRef=cr) :: aRest, inCref, index) 
      equation
        { DAE.INDEX(DAE.ICONST(i)) } = ComponentReference.crefLastSubs(cr);
        true = (i == index);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = ComponentReference.crefEqualNoStringCompare(inCref,cr);
      then isArrayExpansion(aRest, inCref, index+1);
    case (_, _,_) then false;
  end matchcontinue;
end isArrayExpansion;

public function hackMatrixReverseToCref
"This is a hack transformation of an expanded matrix back to its cref.
It is used in daeExpMatrix() (for C# yet) to optimize the generated code.
TODO: This function should not exist! 
Rather the matrix should not be let expanded when SimCode is entering templates 
"
  input DAE.Exp inExp;
  input Context context;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp, context)
    local
      DAE.ComponentRef cr;
      DAE.ExpType aty;
      list<list<DAE.Exp>> rows;
      DAE.Exp crefExp;
      
    case(DAE.MATRIX(ty=aty, matrix = rows as (((DAE.CREF(componentRef=cr))::_)::_) ),context)
      equation
        failure(FUNCTION_CONTEXT()=context);
        { DAE.INDEX(DAE.ICONST(1)), DAE.INDEX(DAE.ICONST(1)) } = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = isMatrixExpansion(rows, cr, 1, 1);
        crefExp = Expression.makeCrefExp(cr, aty);
      then 
        crefExp;
        
    case(inExp, _) then inExp;
        
  end matchcontinue;
end hackMatrixReverseToCref;


public function hackGetFirstExternalFunctionLib
"This is a hack to get the original library name given to an external function.
TODO: redesign OMC and Modelica specification so they are not so C/C++ centric."
  input list<String> libs;
  output String outFirstLib;
algorithm
  outFirstLib := matchcontinue (libs)
    local
      String lib;
    
    case(libs)
      equation
        lib = Util.listLast(libs);
        lib = System.stringReplace(lib,"-l","");
      then 
        lib;
    
    case(_) then "NO_LIB";
      
  end matchcontinue;
end hackGetFirstExternalFunctionLib;


protected function isMatrixExpansion
"Helper funtion to hackMatrixReverseToCref."
  input list<list<DAE.Exp>> rows;
  input DAE.ComponentRef inCref;
  input Integer rowIndex;
  input Integer colIndex;
  output Boolean isExpanded;
algorithm
  isExpanded := matchcontinue(rows, inCref, rowIndex, colIndex)
    local
      list<list<DAE.Exp>> restRows;
      list<DAE.Exp> restElems;
      Integer r,c;
      DAE.ComponentRef cr;
    case({}, _,_,_) then true;
    case({} :: restRows, inCref, rowIndex,_) then isMatrixExpansion(restRows, inCref, rowIndex+1, 1);
    case ( (DAE.CREF(componentRef=cr) :: restElems) :: restRows, inCref, rowIndex, colIndex) 
      equation
        { DAE.INDEX(DAE.ICONST(r)), DAE.INDEX(DAE.ICONST(c)) } = ComponentReference.crefLastSubs(cr);
        true = (r == rowIndex) and (c == colIndex);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = ComponentReference.crefEqualNoStringCompare(inCref,cr);
      then isMatrixExpansion(restElems :: restRows, inCref, rowIndex, colIndex+1);
    else false;
  end matchcontinue;
end isMatrixExpansion;

public function createAssertforSqrt
   input DAE.Exp inExp;
   output DAE.Exp outExp;
algorithm
  outExp := 
  matchcontinue (inExp)
  case(_) then DAE.RELATION(inExp,DAE.GREATEREQ(DAE.ET_REAL()),DAE.RCONST(0.0),-1,NONE());
  end matchcontinue;
end createAssertforSqrt;

public function createDAEString
   input String inString;
   output DAE.Exp outExp;
   annotation(__OpenModelica_EarlyInline = true);
algorithm
  outExp := DAE.SCONST(inString);
end createDAEString;

public function appendAllequations
  input list<JacobianMatrix> inJacobianMatrix;
  output list<SimEqSystem> outEqn;
algorithm 
  outEqn := 
  matchcontinue(inJacobianMatrix)
      local
        list<JacobianColumn> column;
        list<SimEqSystem> tmp,tmp1;
        list<JacobianMatrix> rest;
    case ((column,_,_)::rest)
      equation
        tmp = appendAllequation(column);
        tmp1 = appendAllequations(rest);
        tmp1 = listAppend(tmp,tmp1);
      then tmp1;
   case({}) then {};
end matchcontinue;
end appendAllequations;

protected function appendAllequation
  input list<JacobianColumn> inJacobianMatrix;
  output list<SimEqSystem> outEqn;
algorithm 
  outEqn := 
  matchcontinue(inJacobianMatrix)
      local
        list<SimEqSystem> tmp,tmp1;
        list<JacobianColumn> rest;
    case (((tmp,_,_)::rest))
      equation
        tmp1 = appendAllequation(rest);
        tmp1 = listAppend(tmp,tmp1);
      then tmp1;
   case({}) then {};
end matchcontinue;
end appendAllequation;

public function appendAllVars
  input list<JacobianMatrix> inJacobianMatrix;
  output list<SimVar> outVars;
algorithm 
  outVars := 
  matchcontinue(inJacobianMatrix)
      local
        list<SimVar> tmp,tmp1;
        list<JacobianMatrix> rest;
    case ((_,tmp,_)::rest)
      equation
        tmp1 = appendAllVars(rest);
        tmp1 = listAppend(tmp,tmp1);
      then tmp1;
   case({}) then {};
end matchcontinue;
end appendAllVars;

public function appendLists
  input list<SimEqSystem> inEqn1;
  input list<SimEqSystem> inEqn2;
  output list<SimEqSystem> outEqn;
algorithm 
  outEqn := listAppend(inEqn1,inEqn2);
end appendLists;


/** end of TypeView published functions **/


public function createSimulationSettings
  input Real startTime;
  input Real stopTime;
  input Integer numberOfIntervals;
  input Real tolerance;
  input String method;
  input String options;
  input String outputFormat;
  input String variableFilter;
  input Boolean measureTime;
  input String cflags;
  output SimulationSettings simSettings;
  protected
  Real stepSize;
algorithm
  numberOfIntervals := Util.if_(numberOfIntervals <= 0, 1, numberOfIntervals);
  stepSize := (stopTime -. startTime) /. intReal(numberOfIntervals);
  simSettings := SIMULATION_SETTINGS(
    startTime, stopTime, numberOfIntervals, stepSize, tolerance,
    method, options, outputFormat, variableFilter, measureTime, cflags);
end createSimulationSettings;


public function generateModelCodeFMU
  "Generates code for a model by creating a SimCode structure and calling the
   template-based code generator on it."
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree functionTree;
  input Absyn.Program p;
  input DAE.DAElist dae;
  input Absyn.Path className;
  input String filenamePrefix;
  input Option<SimulationSettings> simSettingsOpt;
  input array<Integer> equationIndices;
  input array<Integer> variableIndices;
  input BackendDAE.StrongComponents strongComponents;
  output BackendDAE.BackendDAE outIndexedBackendDAE;
  output list<String> libs;
  output String fileDir;
  output Real timeBackend;
  output Real timeSimCode;
  output Real timeTemplates;
protected 
  list<String> includes,includeDirs;
  list<Function> functions;
  // DAE.DAElist dae2;
  String filename, funcfilename;
  SimCode simCode;
  list<RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  Absyn.ComponentRef a_cref;
  list<DAE.Exp> literals;
algorithm
  timeBackend := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScript.getFileDir(a_cref, p);
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
  (libs, includes, includeDirs, recordDecls, functions, outIndexedBackendDAE, _, literals) :=
  createFunctions(dae, inBackendDAE, functionTree, className);
  simCode := createSimCode(functionTree, outIndexedBackendDAE,
    className, filenamePrefix, fileDir, functions, includes, includeDirs, libs, simSettingsOpt, recordDecls, literals);
  timeSimCode := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
  Debug.execStat("SimCode",CevalScript.RT_CLOCK_BUILD_MODEL);
  
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
  Tpl.tplNoret(SimCodeFMU.translateModel, simCode);
  timeTemplates := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
end generateModelCodeFMU;


public function translateModelFMU
"Entry point to translate a Modelica model for FMU export.
    
 Called from other places in the compiler."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy, inSimSettingsOpt)
    local
      String filenameprefix,file_dir,resstr;
      list<SCode.Element> p_1;
      DAE.DAElist dae;
      list<Env.Frame> env;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      array<list<Integer>> m,mT;
      array<Integer> ass1,ass2;
      BackendDAE.StrongComponents comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Interactive.SymbolTable st;
      Absyn.Program p,ptot;
      //DAE.Exp fileprefix;
      Env.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p)),filenameprefix,addDummy, inSimSettingsOpt)
      equation
        /* calculate stuff that we need to create SimCode data structure */
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st),NONE(), msg);
        ptot = Dependency.getTotalProgram(className,p);
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        funcs = Env.getFunctionTree(cache);
        dae = DAEUtil.transformationsBeforeBackend(cache,dae);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae,funcs,true);
        (dlow_1 as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1,ass2,comps))})) = BackendDAEUtil.getSolvedSystem(cache, env, dlow, funcs,
          NONE(), NONE(), NONE());
        Debug.fprintln("dynload", "translateModel: Generating simulation code and functions.");
        (indexed_dlow_1,libs,file_dir,timeBackend,timeSimCode,timeTemplates) = 
          generateModelCodeFMU(dlow_1,funcs,p, dae,  className, filenameprefix, inSimSettingsOpt,ass1,ass2,comps);
        resultValues = 
        {("timeTemplates",Values.REAL(timeTemplates)),
          ("timeSimCode",  Values.REAL(timeSimCode)),
          ("timeBackend",  Values.REAL(timeBackend)),
          ("timeFrontend", Values.REAL(timeFrontend))
          };
          resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," has been translated to FMU"});
      then
        (cache,Values.STRING(resstr),st,indexed_dlow_1,libs,file_dir, resultValues);
    case (_,_,className,_,_,_, _)
      equation        
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," could not been translated to FMU"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then
        fail();
  end matchcontinue;
end translateModelFMU;


public function generateModelCode
  "Generates code for a model by creating a SimCode structure and calling the
   template-based code generator on it."
   
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree functionTree;
  input Absyn.Program p;
  input DAE.DAElist dae;
  input Absyn.Path className;
  input String filenamePrefix;
  input Option<SimulationSettings> simSettingsOpt;
  output BackendDAE.BackendDAE outIndexedBackendDAE;
  output list<String> libs;
  output String fileDir;
  output Real timeBackend;
  output Real timeSimCode;
  output Real timeTemplates;
protected 
  
  list<String> includes,includeDirs;
  list<Function> functions;
  // DAE.DAElist dae2;
  String filename, funcfilename;
  SimCode simCode;
  list<RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  Absyn.ComponentRef a_cref;
  BackendQSS.QSSinfo qssInfo;
  list<DAE.Exp> literals;
algorithm
  timeBackend := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScript.getFileDir(a_cref, p);
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
  (libs, includes, includeDirs, recordDecls, functions, outIndexedBackendDAE, _, literals) :=
  createFunctions(dae, inBackendDAE, functionTree, className);
  simCode := createSimCode(functionTree, outIndexedBackendDAE, 
    className, filenamePrefix, fileDir, functions, includes, includeDirs, libs, simSettingsOpt, recordDecls, literals);

  timeSimCode := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
  Debug.execStat("SimCode",CevalScript.RT_CLOCK_BUILD_MODEL);
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
  
  callTargetTemplates(simCode,inBackendDAE,RTOpts.simCodeTarget());
  timeTemplates := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
end generateModelCode;

// TODO: use another switch ... later make it first class option like -target or so
// Update: inQSSrequiredData passed in order to call BackendQSS and generate the extra structures needed for QSS simulation.
protected function callTargetTemplates
"Generate target code by passing the SimCode data structure to templates."
  input SimCode simCode;
  input BackendDAE.BackendDAE inQSSrequiredData;
  input String target;
algorithm
  _ := match (simCode,inQSSrequiredData,target)
    local
      BackendDAE.BackendDAE outIndexedBackendDAE;
      array<Integer> equationIndices, variableIndices;
      BackendDAE.IncidenceMatrix incidenceMatrix;
      BackendDAE.IncidenceMatrixT incidenceMatrixT;
      BackendDAE.StrongComponents strongComponents;
      BackendQSS.QSSinfo qssInfo;
      
    case (simCode,_,"CSharp")
      equation
        Tpl.tplNoret(SimCodeCSharp.translateModel, simCode);
      then ();
   case (simCode,_,"Cpp")
      equation
        Tpl.tplNoret(SimCodeCpp.translateModel, simCode);
      then ();
   case (simCode,_,"Adevs")
      equation
        Tpl.tplNoret(SimCodeAdevs.translateModel, simCode);
      then ();
    case (simCode,outIndexedBackendDAE as BackendDAE.DAE(eqs={
        BackendDAE.EQSYSTEM(m=SOME(incidenceMatrix), mT=SOME(incidenceMatrixT), matching=BackendDAE.MATCHING(equationIndices, variableIndices,strongComponents))
      }),"QSS")
      equation
        Debug.trace("Generating QSS solver code\n");
        qssInfo = BackendQSS.generateStructureCodeQSS(outIndexedBackendDAE, equationIndices, variableIndices, incidenceMatrix, incidenceMatrixT, strongComponents);
        Tpl.tplNoret2(SimCodeQSS.translateModel, simCode, qssInfo);
      then ();
    case (simCode,_,"C")
      equation
        Tpl.tplNoret(SimCodeC.translateModel, simCode);
      then ();
    case (simCode,_,"Dump")
      equation
        // Yes, do this better later on...
        print(Tpl.tplString(SimCodeDump.dumpSimCode, simCode));
      then ();
    case (_,_,target)
      equation
        target = "Unknown template target: " +& target;
        Error.addMessage(Error.INTERNAL_ERROR, {target});
      then fail();
  end match;
end callTargetTemplates;



public function translateModel
"Entry point to translate a Modelica model for simulation.
    
 Called from other places in the compiler."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy, inSimSettingsOpt)
    local
      String filenameprefix,file_dir,resstr;
      list<SCode.Element> p_1;
      DAE.DAElist dae;
      list<Env.Frame> env;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      array<list<Integer>> m,mT;
      array<Integer> ass1,ass2;
      BackendDAE.StrongComponents comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Interactive.SymbolTable st;
      Absyn.Program p,ptot;
      //DAE.Exp fileprefix;
      Env.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;

    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p)),filenameprefix,addDummy, inSimSettingsOpt)
      equation
        // calculate stuff that we need to create SimCode data structure 
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st),NONE(), msg);
        ptot = Dependency.getTotalProgram(className,p);
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        dae = DAEUtil.transformationsBeforeBackend(cache,dae);
        funcs = Env.getFunctionTree(cache);
        dlow = BackendDAECreate.lower(dae,funcs,true);
        dlow_1 = BackendDAEUtil.getSolvedSystem(cache, env, dlow, funcs,
          NONE(), NONE(), NONE());
        (indexed_dlow_1,libs,file_dir,timeBackend,timeSimCode,timeTemplates) = 
          generateModelCode(dlow_1,funcs,p, dae,  className, filenameprefix, inSimSettingsOpt);
        resultValues = 
        {("timeTemplates",Values.REAL(timeTemplates)),
          ("timeSimCode",  Values.REAL(timeSimCode)),
          ("timeBackend",  Values.REAL(timeBackend)),
          ("timeFrontend", Values.REAL(timeFrontend))
          };
        resstr = Util.if_(RTOpts.debugFlag("failtrace"),Absyn.pathStringNoQual(className),"");
        resstr = stringAppendList({"SimCode: The model ",resstr," has been translated"});
        //        resstr = "SimCode: The model has been translated";
      then
        (cache,Values.STRING(resstr),st,indexed_dlow_1,libs,file_dir, resultValues);
    case (_,_,className,_,_,_, _)
      equation        
        true = RTOpts.debugFlag("failtrace");
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," could not been translated"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then
        fail();
  end matchcontinue;
end translateModel;

public function translateFunctions
"Entry point to translate Modelica/MetaModelica functions to C functions.
    
 Called from other places in the compiler."
  input String name;
  input Option<DAE.Function> optMainFunction;
  input list<DAE.Function> daeElements;
  input list<DAE.Type> metarecordTypes;
  input list<String> includes;
algorithm
  _ := match (name, optMainFunction, daeElements, metarecordTypes, includes)
    local
      DAE.Function daeMainFunction;
      Function mainFunction;
      list<Function> fns;
      list<String> libs, includes, includeDirs;
      MakefileParams makefileParams;
      FunctionCode fnCode;
      list<RecordDeclaration> extraRecordDecls;
      list<DAE.Exp> literals;
    case (name, SOME(daeMainFunction), daeElements, metarecordTypes, includes)
      equation
        // Create FunctionCode
        (daeElements,literals) = findLiterals(daeMainFunction::daeElements);
        (mainFunction::fns, extraRecordDecls, includes, includeDirs, libs) = elaborateFunctions(daeElements, metarecordTypes, literals, includes);
        checkValidMainFunction(name, mainFunction);
        makefileParams = createMakefileParams(includeDirs, libs);
        fnCode = FUNCTIONCODE(name, SOME(mainFunction), fns, literals, includes, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(SimCodeC.translateFunctions, fnCode);
      then
        ();
    case (name, NONE(), daeElements, metarecordTypes, includes)
      equation
        // Create FunctionCode
        (daeElements,literals) = findLiterals(daeElements);
        (fns, extraRecordDecls, includes, includeDirs, libs) = elaborateFunctions(daeElements, metarecordTypes, literals, includes);
        makefileParams = createMakefileParams(includeDirs, libs);
        fnCode = FUNCTIONCODE(name, NONE(), fns, literals, includes, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(SimCodeC.translateFunctions, fnCode);
      then
        ();
  end match;
end translateFunctions;

protected function findLiterals
  "Finds all literal expressions in functions"
  input list<DAE.Function> fns;
  output list<DAE.Function> ofns;
  output list<DAE.Exp> literals;
algorithm
  (ofns,(_,_,literals)) := DAEUtil.traverseDAEFunctions(
    fns, findLiteralsHelper,
    (0,HashTableExpToIndex.emptyHashTableSized(BaseHashTable.bigBucketSize),{}));
  literals := listReverse(literals);
end findLiterals;

protected function simulationFindLiterals
  "Finds all literal expressions in the DAE"
  input BackendDAE.BackendDAE dae;
  input list<DAE.Function> fns;
  output list<DAE.Function> ofns;
  output list<DAE.Exp> literals;
protected
  Integer i;
  HashTableExpToIndex.HashTable ht;
algorithm
  (ofns,(i,ht,literals)) := DAEUtil.traverseDAEFunctions(
    fns, findLiteralsHelper,
    (0,HashTableExpToIndex.emptyHashTableSized(BaseHashTable.bigBucketSize),{}));
  ((i,ht,literals)) := BackendDAEUtil.traverseBackendDAEExps(dae, findLiteralsHelper, (i,ht,literals));
  literals := listReverse(literals);
end simulationFindLiterals;

protected function findLiteralsHelper
  input tuple<DAE.Exp,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> inTpl;
  output tuple<DAE.Exp,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> outTpl;
protected
  DAE.Exp exp;
  tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> tpl;
algorithm
  (exp,tpl) := inTpl;
  ((exp,tpl)) := Expression.traverseExp(exp,replaceLiteralExp,tpl);
  ((exp,tpl)) := Expression.traverseExpTopDown(exp,replaceLiteralArrayExp,tpl);
  outTpl := (exp,tpl);
end findLiteralsHelper;

protected function replaceLiteralArrayExp
  "The tuples contain:
  * The expression to be replaced (or not)
  * Index of next literal
  * HashTable Exp->Index (Number of the literal)
  * The list of literals
  
  Handles only array expressions (needs to be performed in a top-down fashion)
  "
  input tuple<DAE.Exp,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> inTpl;
  output tuple<DAE.Exp,Boolean,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      DAE.Exp exp;
      tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> tpl;
    case ((exp as DAE.ARRAY(array=_),_))
      equation
        isLiteralArrayExp(exp);
        ((exp,tpl)) = replaceLiteralExp2(inTpl);
      then ((exp,false,tpl));
    case ((exp as DAE.ARRAY(array=_),tpl))
      equation
        failure(isLiteralArrayExp(exp));
      then ((exp,false,tpl));
    case ((exp,tpl)) then ((exp,true,tpl));
  end matchcontinue;
end replaceLiteralArrayExp;

protected function replaceLiteralExp
  "The tuples contain:
  * The expression to be replaced (or not)
  * Index of next literal
  * HashTable Exp->Index (Number of the literal)
  * The list of literals
  "
  input tuple<DAE.Exp,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> inTpl;
  output tuple<DAE.Exp,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      DAE.Exp exp;
      String msg;
      tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> t;
    case ((exp,_))
      equation
        failure(isLiteralExp(exp));
      then inTpl;
    case ((exp,_))
      equation
        isTrivialLiteralExp(exp);
      then inTpl;
    case ((exp,t))
      equation
        exp = listToCons(exp);
      then Expression.traverseExp(exp,replaceLiteralExp,t); // All sublists should also be added as literals...
    case ((exp,_))
      equation
        failure(_ = listToCons(exp));
      then replaceLiteralExp2(inTpl);
    case ((exp,_))
      equation
        msg = "SimCode.replaceLiteralExp failed. Falling back to not replacing "+&ExpressionDump.printExpStr(exp)+&".";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then inTpl;
  end matchcontinue;
end replaceLiteralExp;

protected function replaceLiteralExp2
  "The tuples contain:
  * The expression to be replaced (or not)
  * Index of next literal
  * HashTable Exp->Index (Number of the literal)
  * The list of literals
  "
  input tuple<DAE.Exp,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> inTpl;
  output tuple<DAE.Exp,tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>>> outTpl;
algorithm
  outTpl := matchcontinue inTpl
    local
      DAE.Exp exp,nexp;
      Integer i,ix;
      list<DAE.Exp> l;
      DAE.ExpType et;
      HashTableExpToIndex.HashTable ht;
    case ((exp,(i,ht,l)))
      equation
        ix = BaseHashTable.get(exp,ht);
        et = Expression.typeof(exp);
        nexp = DAE.SHARED_LITERAL(ix,et);
      then ((nexp,(i,ht,l)));
    case ((exp,(i,ht,l)))
      equation
        ht = BaseHashTable.add((exp,i),ht);
        et = Expression.typeof(exp);
        nexp = DAE.SHARED_LITERAL(i,et);
      then ((nexp,(i+1,ht,exp::l)));
  end matchcontinue;
end replaceLiteralExp2;

protected function listToCons
"Converts a DAE.LIST to a chain of DAE.CONS"
  input DAE.Exp e;
  output DAE.Exp o;
algorithm
  o := match e
    local
      list<DAE.Exp> es;
      DAE.ExpType ty;
    case DAE.LIST(es as _::_) then listToCons2(es);
  end match;
end listToCons;

protected function listToCons2
"Converts a DAE.LIST to a chain of DAE.CONS"
  input list<DAE.Exp> es;
  output DAE.Exp o;
algorithm
  o := match es
    local
      DAE.Exp car,cdr;
    case ({}) then DAE.LIST({});
    case (car::es)
      equation
        cdr = listToCons2(es);
      then DAE.CONS(car,cdr);
  end match;
end listToCons2;

protected function isTrivialLiteralExp
"Succeeds if the expression should not be translated to a constant literal because it is too simple"
  input DAE.Exp exp;
algorithm
  _ := match exp
    case DAE.BOX(DAE.SCONST(_)) then fail();
    case DAE.BOX(DAE.RCONST(_)) then fail();
    case DAE.BOX(_) then ();
    case DAE.ICONST(_) then ();
    case DAE.BCONST(_) then ();
    case DAE.RCONST(_) then ();
    case DAE.ENUM_LITERAL(index = _) then ();
    case DAE.LIST(valList={}) then ();
    case DAE.META_OPTION(NONE()) then ();
    case DAE.SHARED_LITERAL(index=_) then ();
    else fail();
  end match;
end isTrivialLiteralExp;

protected function isLiteralArrayExp
  input DAE.Exp exp;
algorithm
  _ := match exp
    local
      DAE.Exp e1,e2;
      list<DAE.Exp> expl;
    case DAE.SCONST(_) then ();
    case DAE.ICONST(_) then ();
    case DAE.RCONST(_) then ();
    case DAE.BCONST(_) then ();
    case DAE.ARRAY(array=expl) equation Util.listMap0(expl,isLiteralArrayExp); then ();
    case DAE.ENUM_LITERAL(index = _) then ();
    case DAE.META_OPTION(NONE()) then ();
    case DAE.META_OPTION(SOME(exp)) equation isLiteralArrayExp(exp); then ();
    case DAE.BOX(exp) equation isLiteralArrayExp(exp); then ();
    case DAE.CONS(car = e1, cdr = e2) equation isLiteralArrayExp(e1); isLiteralArrayExp(e2); then ();
    case DAE.LIST(valList = expl) equation Util.listMap0(expl,isLiteralArrayExp); then ();
    case DAE.META_TUPLE(expl) equation Util.listMap0(expl,isLiteralArrayExp); then ();
    case DAE.METARECORDCALL(args=expl) equation Util.listMap0(expl,isLiteralArrayExp); then ();
    case DAE.SHARED_LITERAL(index=_) then ();
    else fail();
  end match;
end isLiteralArrayExp;

protected function isLiteralExp
"Returns if the expression may be replaced by a constant literal"
  input DAE.Exp exp;
algorithm
  _ := match exp
    local
      DAE.Exp e1,e2;
      list<DAE.Exp> expl;
    case DAE.SCONST(_) then ();
    case DAE.ICONST(_) then ();
    case DAE.RCONST(_) then ();
    case DAE.BCONST(_) then ();
    case DAE.ENUM_LITERAL(index = _) then ();
    case DAE.META_OPTION(NONE()) then ();
    case DAE.META_OPTION(SOME(exp)) equation isLiteralExp(exp); then ();
    case DAE.BOX(exp) equation isLiteralExp(exp); then ();
    case DAE.CONS(car = e1, cdr = e2) equation isLiteralExp(e1); isLiteralExp(e2); then ();
    case DAE.LIST(valList = expl) equation Util.listMap0(expl,isLiteralExp); then ();
    case DAE.META_TUPLE(expl) equation Util.listMap0(expl,isLiteralExp); then ();
    case DAE.METARECORDCALL(args=expl) equation Util.listMap0(expl,isLiteralExp); then ();
    case DAE.SHARED_LITERAL(index=_) then ();
    else fail();
  end match;
end isLiteralExp;

protected function checkValidMainFunction
"Verifies that an in-function can be generated.
This is not the case if the input involves function-pointers."
  input String name;
  input Function fn;
algorithm
  _ := matchcontinue (name,fn)
    local
      list<Variable> inVars;
    case (_,FUNCTION(functionArguments = inVars))
      equation
        failure(_ = Util.listSelectFirst(inVars, isFunctionPtr));
      then ();
    case (_,EXTERNAL_FUNCTION(inVars = inVars))
      equation
        failure(_ = Util.listSelectFirst(inVars, isFunctionPtr));
      then ();
    case (name,_)
      equation
        Error.addMessage(Error.GENERATECODE_INVARS_HAS_FUNCTION_PTR,{name});
      then fail();
  end matchcontinue;
end checkValidMainFunction;

public function isBoxedFunction
"Verifies that an in-function can be generated.
This is not the case if the input involves function-pointers."
  input Function fn;
  output Boolean b;
algorithm
  b := matchcontinue fn
    local
      list<Variable> inVars,outVars;
    case (FUNCTION(functionArguments = inVars, outVars = outVars))
      equation
        Util.listMap0(inVars, isBoxedArg);
        Util.listMap0(outVars, isBoxedArg);
      then true;
    case (EXTERNAL_FUNCTION(inVars = inVars, outVars = outVars))
      equation
        Util.listMap0(inVars, isBoxedArg);
        Util.listMap0(outVars, isBoxedArg);
      then true;
    else false;
  end matchcontinue;
end isBoxedFunction;

protected function isFunctionPtr
"Checks if an input variable is a function pointer"
  input Variable var;
  output Boolean b;
algorithm
  b := matchcontinue var
    local
      /* Yes, they are VARIABLE, not FUNCTION_PTR. */
    case FUNCTION_PTR(tys = _)
    then true;
    case _ then false;
  end matchcontinue;
end isFunctionPtr;

protected function isBoxedArg
"Checks if a variable is a boxed datatype"
  input Variable var;
algorithm
  _ := match var
    case FUNCTION_PTR(tys = _) then ();
    case VARIABLE(ty = DAE.ET_BOXED(_)) then ();
    case VARIABLE(ty = DAE.ET_METATYPE()) then ();
    case VARIABLE(ty = DAE.ET_STRING()) then ();
  end match;
end isBoxedArg;

/* Finds the called functions in BackendDAE and transforms them to a list of
 libraries and a list of Function uniontypes. */
public function createFunctions
  input DAE.DAElist inDAElist;
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.FunctionTree functionTree;
  input Absyn.Path inPath;
  output list<String> libs;
  output list<String> includes;
  output list<String> includeDirs;
  output list<RecordDeclaration> recordDecls;
  output list<Function> functions;
  output BackendDAE.BackendDAE outBackendDAE;
  output DAE.DAElist outDAE;
  output list<DAE.Exp> literals;  
algorithm
  (libs, includes, includeDirs, recordDecls, functions, outBackendDAE, outDAE, literals) :=
  matchcontinue (inDAElist,inBackendDAE,functionTree,inPath)
    local
      list<String> libs1,libs2,includes1,includes2,includeDirs1,includeDirs2;
      list<DAE.Function> funcelems,part_func_elems;
      DAE.DAElist dae;
      BackendDAE.BackendDAE dlow;
      Absyn.Path path;
      list<Function> fns;
      
    case (dae,dlow,functionTree,path)
      equation
        // get all the used functions from the function tree
        funcelems = DAEUtil.getFunctionList(functionTree);
        
        part_func_elems = PartFn.createPartEvalFunctions(funcelems);
        (dae, part_func_elems) = PartFn.partEvalDAE(dae, part_func_elems);
        (dlow, part_func_elems) = BackendDAEUtil.mapEqSystemAndFold1(dlow, PartFn.partEvalBackendDAE, true /*dummy*/, part_func_elems);
        funcelems = Util.listUnion(part_func_elems, part_func_elems);
        //funcelems = Util.listUnion(funcelems, part_func_elems);
        funcelems = Inline.inlineCallsInFunctions(funcelems,(NONE(),{DAE.NORM_INLINE(), DAE.AFTER_INDEX_RED_INLINE()}));
        //Debug.fprintln("info", "Generating functions, call Codegen.\n") "debug" ;
        (funcelems,literals) = simulationFindLiterals(dlow,funcelems);
        
        (fns, recordDecls, includes2, includeDirs2, libs2) = elaborateFunctions(funcelems, {}, literals, {}); // Do we need metarecords here as well?
      then
        (libs2, includes2, includeDirs2, recordDecls, fns, dlow, dae, literals);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Creation of Modelica functions failed. "});
      then
        fail();
  end matchcontinue;
end createFunctions;

public function getCalledFunctionReferences
"Goes through the BackendDAE structure, finds all function references calls, 
 and returns them in a list. Removes duplicates."
  input DAE.DAElist dae;
  input BackendDAE.BackendDAE dlow;
  output list<Absyn.Path> res;
  list<DAE.Exp> explist,fcallexps;
  list<Absyn.Path> calledfuncs;
algorithm
  res := matchcontinue(dae, dlow)
    case (dae, dlow)
      equation
        false = RTOpts.acceptMetaModelicaGrammar();
      then {};
    case (dae, dlow)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        fcallexps = BackendDAEUtil.traverseBackendDAEExps(dlow,matchFnRefs,{});
        calledfuncs = Util.listMap(fcallexps, getCallPath);
        res = removeDuplicatePaths(calledfuncs);
      then res;
  end matchcontinue;
end getCalledFunctionReferences;

protected function elaborateFunctions
  input list<DAE.Function> daeElements;
  input list<DAE.Type> metarecordTypes;
  input list<DAE.Exp> literals;
  input list<String> includes;
  output list<Function> functions;
  output list<RecordDeclaration> extraRecordDecls;
  output list<String> outIncludes;
  output list<String> includeDirs;
  output list<String> libs;
protected
  list<Function> fns;
  list<String> outRecordTypes;
algorithm
  (extraRecordDecls, outRecordTypes) := elaborateRecordDeclarationsForMetarecords(literals,{},{});
  (functions, outRecordTypes, extraRecordDecls, outIncludes, includeDirs, libs) := elaborateFunctions2(daeElements,{},outRecordTypes,extraRecordDecls,includes,{},{});
  (extraRecordDecls,_) := elaborateRecordDeclarationsFromTypes(metarecordTypes, extraRecordDecls, outRecordTypes);
end elaborateFunctions;

protected function elaborateFunctions2
  input list<DAE.Function> daeElements;
  input list<Function> inFunctions;
  input list<String> inRecordTypes;
  input list<RecordDeclaration> inDecls;
  input list<String> inIncludes;
  input list<String> includeDirs;
  input list<String> inLibs;
  output list<Function> outFunctions;
  output list<String> outRecordTypes;
  output list<RecordDeclaration> outDecls;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<String> outLibs;
algorithm
  (outFunctions, outRecordTypes, outDecls, outIncludes, outIncludeDirs, outLibs) :=
  matchcontinue (daeElements, inFunctions, inRecordTypes, inDecls, inIncludes, includeDirs, inLibs)
    local
      list<Function> accfns, fns;
      Function fn;
      list<String> rt, rt_1, rt_2, includes, libs;
      DAE.Function fel;
      list<DAE.Function> rest;
      list<RecordDeclaration> decls;
      String name;
    case ({}, accfns, rt, decls, includes, includeDirs, libs)
    then (listReverse(accfns), rt, decls, listReverse(includes), includeDirs, listReverse(libs));
    case ((DAE.FUNCTION(type_ = (DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isBuiltin=DAE.FUNCTION_BUILTIN_PTR())),_)) :: rest), accfns, rt, decls, includes, includeDirs, libs)
      equation
        // skip over builtin functions
        (fns, rt_2, decls, includes, includeDirs, libs) = elaborateFunctions2(rest, accfns, rt, decls, includes, includeDirs, libs);
      then
        (fns, rt_2, decls, includes, includeDirs, libs);
    case ((DAE.FUNCTION(partialPrefix = true) :: rest), accfns, rt, decls, includes, includeDirs, libs)
      equation
        // skip over partial functions
        (fns, rt_2, decls, includes, includeDirs, libs) = elaborateFunctions2(rest, accfns, rt, decls, includes, includeDirs, libs);
      then
        (fns, rt_2, decls, includes, includeDirs, libs);
    case (DAE.FUNCTION(functions = DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(language="builtin"))::_)::rest,accfns,rt,decls,includes,includeDirs,libs)
      equation
        // skip over builtin functions
        (fns, rt_2, decls, includes, includeDirs, libs) = elaborateFunctions2(rest, accfns, rt, decls, includes, includeDirs, libs);
      then
        (fns, rt_2, decls, includes, includeDirs, libs);
        
    case (DAE.FUNCTION(functions = DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(name=name,language="C"))::_)::rest,accfns,rt,decls,includes,includeDirs,libs)
      equation
        // skip over builtin functions
        true = listMember(name,SCode.knownExternalCFunctions);
        (fns, rt_2, decls, includes, includeDirs, libs) = elaborateFunctions2(rest, accfns, rt, decls, includes, includeDirs, libs);
      then
        (fns, rt_2, decls, includes, includeDirs, libs);

    case ((fel :: rest), accfns, rt, decls, includes, includeDirs, libs)
      equation
        (fn, rt_1, decls, includes, includeDirs, libs) = elaborateFunction(fel, rt, decls, includes, includeDirs, libs);
        (fns, rt_2, decls, includes, includeDirs, libs) = elaborateFunctions2(rest, (fn :: accfns), rt_1, decls, includes, includeDirs, libs);
      then
        (fns, rt_2, decls, includes, includeDirs, libs);
  end matchcontinue;
end elaborateFunctions2;

/* Does the actual work of transforming a DAE.FUNCTION to a Function. */
protected function elaborateFunction
  input DAE.Function inElement;
  input list<String> inRecordTypes;
  input list<RecordDeclaration> inRecordDecls;
  input list<String> inIncludes;
  input list<String> includeDirs;
  input list<String> inLibs;
  output Function outFunction;
  output list<String> outRecordTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<String> outLibs;
algorithm
  (outFunction,outRecordTypes,outRecordDecls,outIncludes,outIncludeDirs,outLibs):=
  matchcontinue (inElement,inRecordTypes,inRecordDecls,inIncludes,includeDirs,inLibs)
    local
      DAE.Function fn;
      String extfnname,lang,str;
      list<DAE.Element> algs, vars; //, bivars, invars, outvars;
      list<String> includes,libs,fn_libs,fn_includes,fn_includeDirs,rt,rt_1;
      Absyn.Path fpath;
      list<DAE.FuncArg> args;
      Types.Type restype,tp;
      list<DAE.ExtArg> extargs;
      list<SimExtArg> simextargs;
      SimExtArg extReturn;
      DAE.ExtArg extretarg;
      Option<SCode.Annotation> ann;
      DAE.ExternalDecl extdecl;
      list<Variable> outVars, inVars, biVars, funArgs, varDecls;
      list<RecordDeclaration> recordDecls;
      list<Statement> bodyStmts;
      list<DAE.Element> daeElts;
      Absyn.Path name;
      DAE.ElementSource source;
      Absyn.Info info;
      Boolean dynamicLoad;
      
      // Modelica functions.
    case (DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = tp as (DAE.T_FUNCTION(funcArg=args, funcResultType=restype), _),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs)
      equation
        outVars = Util.listMap(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = Util.listMap(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = Util.listFilter(daeElts, isVarQ);
        varDecls = Util.listMap(vars, daeInOutSimVar);
        algs = Util.listFilter(daeElts, DAEUtil.isAlgorithm);
        bodyStmts = Util.listMap(algs, elaborateStatement);
        info = DAEUtil.getElementSourceFileInfo(source);
      then
        (FUNCTION(fpath,outVars,funArgs,varDecls,bodyStmts,info),rt_1,recordDecls,includes,includeDirs,libs);
        
        // External functions.
    case (DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_EXT(body =  daeElts, externalDecl = extdecl)::_, // might be followed by derivative maps
      type_ = (tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_))),rt,recordDecls,includes,includeDirs,libs)
      equation
        DAE.EXTERNALDECL(name=extfnname, args=extargs,
          returnArg=extretarg, language=lang, ann=ann) = extdecl;
        //outvars = DAEUtil.getOutputVars(daeElts);
        //invars = DAEUtil.getInputVars(daeElts);
        //bivars = DAEUtil.getBidirVars(daeElts);
        funArgs = Util.listMap(args, typesSimFunctionArg);
        outVars = Util.listMap(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        inVars = Util.listMap(DAEUtil.getInputVars(daeElts), daeInOutSimVar);
        biVars = Util.listMap(DAEUtil.getBidirVars(daeElts), daeInOutSimVar);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        (fn_includes, fn_includeDirs, fn_libs,dynamicLoad) = generateExtFunctionIncludes(fpath,ann);
        includes = Util.listUnion(fn_includes, includes);
        includeDirs = Util.listUnion(fn_includeDirs, includeDirs);
        libs = Util.listUnion(fn_libs, libs);
        simextargs = Util.listMap(extargs, extArgsToSimExtArgs);
        extReturn = extArgsToSimExtArgs(extretarg);
        (simextargs, extReturn) = fixOutputIndex(outVars, simextargs, extReturn);
        info = DAEUtil.getElementSourceFileInfo(source);
        // make lang to-upper as we have FORTRAN 77 and Fortran 77 in the Modelica Library!
        lang = System.toupper(lang);
      then
        (EXTERNAL_FUNCTION(fpath, extfnname, funArgs, simextargs, extReturn,
          inVars, outVars, biVars, fn_libs, lang, info, dynamicLoad),
          rt_1,recordDecls,includes,includeDirs,libs);
        
        // Record constructor.
    case (DAE.RECORD_CONSTRUCTOR(path = fpath, source = source, type_ = tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)),_)),_)), rt,recordDecls,includes,includeDirs,libs)
      equation
        funArgs = Util.listMap(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarationsForRecord(restype, recordDecls, rt);
        info = DAEUtil.getElementSourceFileInfo(source);
      then
        (RECORD_CONSTRUCTOR(name, funArgs, info),rt_1,recordDecls,includes,includeDirs,libs);
        
        // failure
    case (fn,_,_,_,_,_)
      equation 
        str = "SimCode.elaborateFunction failed for function: \n" +& DAEDump.dumpFunctionStr(fn);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end elaborateFunction;

protected function typesSimFunctionArg
"function: generateFunctionArgs
  Generates code from a function argument."
  input Types.FuncArg inFuncArg;
  output Variable outVar;
algorithm
  outVar := matchcontinue (inFuncArg)
    local
      Types.Type tty;
      DAE.ExpType expType;
      String name;
      DAE.ComponentRef cref_;
      list<Types.FuncArg> args;
      DAE.Type res_ty;
      list<DAE.ExpType> etys;
      list<Variable> var_args;
      list<DAE.Type> tys;
      
    case ((name, tty as (DAE.T_FUNCTION(funcArg = args, funcResultType = (DAE.T_TUPLE(tys),_)), _),_))
      equation
        var_args = Util.listMap(args, typesSimFunctionArg);
        etys = Util.listMap(tys, Types.elabType);
      then
        FUNCTION_PTR(name, etys, var_args);
        
    case ((name, tty as (DAE.T_FUNCTION(funcArg = args, funcResultType = (DAE.T_NORETCALL(),_)), _),_))
      equation
        var_args = Util.listMap(args, typesSimFunctionArg);
      then
        FUNCTION_PTR(name, {}, var_args);
        
    case ((name, tty as (DAE.T_FUNCTION(funcArg = args, funcResultType = res_ty), _),_))
      equation
        expType = Types.elabType(res_ty);
        var_args = Util.listMap(args, typesSimFunctionArg);
      then
        FUNCTION_PTR(name, {expType}, var_args);
        
    case ((name,tty,_))
      equation
        expType = Types.elabType(tty);
        cref_  = ComponentReference.makeCrefIdent(name, expType, {});
      then
        VARIABLE(cref_,expType,NONE(),{});
  end matchcontinue;
end typesSimFunctionArg;

protected function daeInOutSimVar
  input DAE.Element inElement;
  output Variable outVar;
algorithm
  outVar := matchcontinue(inElement)
    local
      String name;
      DAE.ExpType expType;
      DAE.Type daeType;
      Expression.ComponentRef id;
      list<Expression.Subscript> inst_dims;
      list<DAE.Exp> inst_dims_exp;
      Option<DAE.Exp> binding;
      Variable var;
    case (DAE.VAR(componentRef = DAE.CREF_IDENT(ident=name),ty = daeType as (DAE.T_FUNCTION(funcArg=_),_)))
      equation
        var = typesSimFunctionArg((name,daeType,DAE.C_VAR()));
      then var;
        
    case (DAE.VAR(componentRef = id,
      ty = daeType,
      binding = binding,
      dims = inst_dims
    ))
      equation
        expType = Types.elabType(daeType);
        inst_dims_exp = Util.listMap(inst_dims, indexSubscriptToExp);
      then VARIABLE(id,expType,binding,inst_dims_exp);
    case (_)
      equation
        // TODO: ArrayEqn fails here
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.daeInOutSimVar failed\n"});
      then
        fail();
  end matchcontinue;
end daeInOutSimVar;

protected function extArgsToSimExtArgs
  input DAE.ExtArg extArg;
  output SimExtArg simExtArg;
algorithm
  simExtArg :=
  match (extArg)
    local
      DAE.ComponentRef componentRef;
      DAE.Attributes attributes;
      DAE.Type type_;
      Boolean isInput;
      Boolean isOutput;
      Boolean isArray;
      DAE.ExpType expType;
      DAE.Exp exp_;
      Integer outputIndex;
    case DAE.EXTARG(componentRef, attributes, type_)
      equation
        isInput = Types.isInputAttr(attributes);
        isOutput = Types.isOutputAttr(attributes);
        outputIndex = Util.if_(isOutput, -1, 0); // correct output index is added later by fixOutputIndex
        isArray = Types.isArray(type_);
        expType = Types.elabType(type_);
      then SIMEXTARG(componentRef, isInput, outputIndex, isArray, false /*fixed later*/, expType);
    case DAE.EXTARGEXP(exp_, type_)
      equation
        expType = Types.elabType(type_);
      then SIMEXTARGEXP(exp_, expType);
    case DAE.EXTARGSIZE(componentRef, attributes, type_, exp_)
      equation
        isInput = Types.isInputAttr(attributes);
        isOutput = Types.isOutputAttr(attributes);
        outputIndex = Util.if_(isOutput, -1, 0); // correct output index is added later by fixOutputIndex
        expType = Types.elabType(type_);
      then SIMEXTARGSIZE(componentRef, isInput, outputIndex, expType, exp_);
    case DAE.NOEXTARG()
    then SIMNOEXTARG();
  end match;
end extArgsToSimExtArgs;

protected function fixOutputIndex
  input list<Variable> outVars;
  input list<SimExtArg> simExtArgsIn;
  input SimExtArg extReturnIn;
  output list<SimExtArg> simExtArgsOut;
  output SimExtArg extReturnOut;
algorithm
  (simExtArgsOut, extReturnOut) := match (outVars, simExtArgsIn, extReturnIn)
    local
    case (outVars, simExtArgsIn, extReturnIn)
      equation
        simExtArgsOut = Util.listMap1(simExtArgsIn, assignOutputIndex, outVars);
        extReturnOut = assignOutputIndex(extReturnIn, outVars);
      then
        (simExtArgsOut, extReturnOut);
  end match;
end fixOutputIndex;

protected function assignOutputIndex
  input SimExtArg simExtArgIn;
  input list<Variable> outVars;
  output SimExtArg simExtArgOut;
algorithm
  simExtArgOut :=
  matchcontinue (simExtArgIn, outVars)
    local
      DAE.ComponentRef cref;
      Boolean isInput;
      Integer outputIndex; // > 0 if output
      Boolean isArray,hasBinding;
      DAE.ExpType type_;
      DAE.Exp exp;
      Integer newOutputIndex;
    
    case (SIMEXTARG(cref, isInput, outputIndex, isArray, _, type_), outVars)
      equation
        true = outputIndex == -1;
        (newOutputIndex,hasBinding) = findIndexInList(cref, outVars, 1);
      then 
        SIMEXTARG(cref, isInput, newOutputIndex, isArray, hasBinding, type_);
    
    case (SIMEXTARGSIZE(cref, isInput, outputIndex, type_, exp), outVars)
      equation
        true = outputIndex == -1;
        (newOutputIndex,_) = findIndexInList(cref, outVars, 1);
      then 
        SIMEXTARGSIZE(cref, isInput, newOutputIndex, type_, exp);
            
    case (simExtArgIn, _)
      then 
        simExtArgIn;
  end matchcontinue;
end assignOutputIndex;

protected function findIndexInList
  input DAE.ComponentRef cref;
  input list<Variable> outVars;
  input Integer currentIndex;
  output Integer crefIndexInOutVars;
  output Boolean hasBinding;
algorithm
  (crefIndexInOutVars,hasBinding) :=
  matchcontinue (cref, outVars, currentIndex)
    local
      DAE.ComponentRef name;
      list<Variable> restOutVars;
      Option<DAE.Exp> v;
    case (cref, {}, currentIndex) then (-1,false);
    case (cref, VARIABLE(name=name,value=v) :: restOutVars, currentIndex)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cref,name);
      then (currentIndex,Util.isSome(v));
    case (cref, _ :: restOutVars, currentIndex)
      equation
        currentIndex = currentIndex + 1;
        (currentIndex,hasBinding) = findIndexInList(cref, restOutVars, currentIndex);
      then (currentIndex,hasBinding);
  end matchcontinue;
end findIndexInList;

protected function elaborateStatement
  input DAE.Element inElement;
  output Statement outStatement;
algorithm
  (outStatement):=
  matchcontinue (inElement)
    local
      list<Algorithm.Statement> stmts;
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)))
    then
      ALGORITHM(stmts);
    case (_)
      equation
        Debug.fprint("failtrace", "# SimCode.elaborateStatement failed\n");
      then
        fail();
  end matchcontinue;
end elaborateStatement;

// Copied from SimCodegen.generateSimulationCode.
protected function createSimCode
  input DAE.FunctionTree functionTree;
  input BackendDAE.BackendDAE inBackendDAE2;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input Option<SimulationSettings> simSettingsOpt;
  input list<RecordDeclaration> recordDecls;
  input list<DAE.Exp> literals;
  output SimCode simCode;
algorithm
  simCode :=
  matchcontinue (functionTree,inBackendDAE2,inClassName,filenamePrefix,inString11,functions,externalFunctionIncludes,includeDirs,libs,simSettingsOpt,recordDecls,literals)
    local
      String cname,   fileDir;
      BackendDAE.StrongComponents comps,blt_states,blt_no_states,contBlocks,contBlocks1,discBlocks,blt_states1,blt_no_states1;
      Integer n_h,nres,maxDelayedExpIndex;
      list<HelpVarInfo> helpVarInfo;
      BackendDAE.BackendDAE dlow,dlow2;
      array<Integer> ass1,ass2;
      array<list<Integer>> m,mt;
      Absyn.Path class_;
      // new variables
      ModelInfo modelInfo;
      list<SimEqSystem> allEquations;
      list<SimEqSystem> odeEquations;         // --> functionODE
      list<SimEqSystem> algebraicEquations;   // --> functionAlgebraics
      list<SimEqSystem> residualEquations;    // --> initial_residual
      list<SimEqSystem> initialEquations;     // --> initial_function
      list<SimEqSystem> parameterEquations;
      list<SimEqSystem> removedEquations;
      list<SimEqSystem> sampleEquations;
      list<Algorithm.Statement> algorithmAndEquationAsserts;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<SimWhenClause> whenClauses;
      list<SampleCondition> sampleConditions;
      list<BackendDAE.Equation> sampleEqns;
      list<DAE.ComponentRef> discreteModelVars;
      ExtObjInfo extObjInfo;
      MakefileParams makefileParams;
      list<tuple<Integer, DAE.Exp>> delayedExps;
      list<DAE.Exp> divLst;
      list<DAE.Statement> allDivStmts;
      list<BackendDAE.Variables> orderedVars;
      BackendDAE.Variables knownVars,vars;
      list<BackendDAE.Var> varlst,varlst1,varlst2;
      list<RecordDeclaration> recordDecls;
      
      list<JacobianMatrix> LinearMatrices;
      HashTableCrefToSimVar crefToSimVarHT;
      Boolean ifcpp;
      BackendDAE.EqSystem syst;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      
    case (functionTree,dlow as BackendDAE.DAE(systs,shared),class_,filenamePrefix,fileDir,functions,externalFunctionIncludes,includeDirs,libs,simSettingsOpt,recordDecls,literals)
      equation
        ifcpp = stringEqual(RTOpts.simCodeTarget(),"Cpp");
         //Debug.fcall("cppvar",print, "is that Cpp? : " +& Dump.printBoolStr(ifcpp) +& "\n");
        cname = Absyn.pathStringNoQual(class_);
               
        (helpVarInfo,dlow2,sampleEqns) = generateHelpVarInfo(dlow);
        dlow2 = BackendDAEUtil.checkInitialSystem(dlow2,functionTree);
        
        residualEquations = createResidualEquations(dlow2);
        nres = listLength(residualEquations);
        
        extObjInfo = createExtObjInfo(shared);
        
        whenClauses = createSimWhenClauses(dlow2, helpVarInfo);
        zeroCrossings = createZeroCrossings(dlow2);
        (sampleConditions,helpVarInfo) = createSampleConditions(zeroCrossings,helpVarInfo);
        sampleEquations = createSampleEquations(sampleEqns);
        n_h = listLength(helpVarInfo);
        
        // Add model info
        modelInfo = createModelInfo(class_, dlow2, functions, n_h, nres, fileDir,ifcpp);
        
        // equation generation for euler, dassl2, rungekutta
        {syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1,ass2,comps))} = systs;
        (blt_states,blt_no_states) = BackendDAEUtil.generateStatePartition(syst);
        blt_no_states1=Util.if_(ifcpp,comps,blt_no_states); 
        blt_states1=Util.if_(ifcpp,comps,blt_states);

        (contBlocks, discBlocks) = splitOutputBlocks(dlow2, ass1, ass2, blt_no_states1);
        contBlocks1=Util.if_(ifcpp,discBlocks,blt_no_states1); 
        odeEquations = createEquations(false, false, ifcpp, false, false, dlow2, blt_states1, helpVarInfo);
        algebraicEquations = createEquations(ifcpp, false, ifcpp, false, false, dlow2, contBlocks1, helpVarInfo);
        allEquations = createEquations(true, false, true, false, false, dlow2, comps, helpVarInfo);

        // Assertions and crap
        initialEquations = createInitialEquations(dlow2);
        parameterEquations = createParameterEquations(dlow2);
        removedEquations = createRemovedEquations(dlow2);
        algorithmAndEquationAsserts = createAlgorithmAndEquationAsserts(dlow2);
        discreteModelVars = extractDiscreteModelVars(dlow2);
        makefileParams = createMakefileParams(externalFunctionIncludes,libs);
        (delayedExps,maxDelayedExpIndex) = extractDelayedExpressions(dlow2);
        
        // replace div operator with div operator with check of Division by zero
        orderedVars = Util.listMap(systs,BackendVariable.daeVars);
        knownVars = BackendVariable.daeKnVars(shared);
        varlst = Util.listMapFlat(orderedVars,BackendDAEUtil.varList);
        varlst1 = BackendDAEUtil.varList(knownVars);
        varlst2 = listAppend(varlst,varlst1);
        vars = BackendDAEUtil.listVar(varlst2);
        (allEquations,divLst) = listMap1_2(allEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        (odeEquations,_) = listMap1_2(odeEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        (algebraicEquations,_) = listMap1_2(algebraicEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        (residualEquations,_) = listMap1_2(residualEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ALL()));
        (initialEquations,_) = listMap1_2(initialEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ALL()));
        (parameterEquations,_) = listMap1_2(parameterEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ALL()));
        (removedEquations,_) = listMap1_2(removedEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        // add equations with only parameters as division expression
        allDivStmts = Util.listMap(divLst,generateParameterDivisionbyZeroTestEqn);
        parameterEquations = listAppend(parameterEquations,{SES_ALGORITHM(allDivStmts)});
        
        // Replace variables in nonlinear equation systems with xloc[index]
        // variables.
        allEquations = Util.listMap(allEquations,applyResidualReplacements);

        // generate jacobian or linear model matrices
        // can be activeted by debug flag "+d=jacobian|linearization"        
        LinearMatrices = createJacobianCC(functionTree,dlow,ass1,ass2,comps);
        LinearMatrices = createLinearModelMatrixes(functionTree,dlow,LinearMatrices);       
        modelInfo = expandModelInfoVars(LinearMatrices,modelInfo);
        
        Debug.fcall("execHash",print, "*** SimCode -> generate cref2simVar hastable: " +& realString(clock()) +& "\n" );
        crefToSimVarHT = createCrefToSimVarHT(modelInfo);
        Debug.fcall("execHash",print, "*** SimCode -> generate cref2simVar hastable done!: " +& realString(clock()) +& "\n" );        
       
        simCode = SIMCODE(modelInfo,
          literals,
          recordDecls,
          externalFunctionIncludes,
          allEquations,
          odeEquations,
          algebraicEquations,
          residualEquations,
          initialEquations,
          parameterEquations,
          removedEquations,
          algorithmAndEquationAsserts,
          zeroCrossings,
          sampleConditions,
          sampleEquations,
          helpVarInfo,
          whenClauses,
          discreteModelVars,
          extObjInfo,
          makefileParams,
          DELAYED_EXPRESSIONS(delayedExps, maxDelayedExpIndex),
          LinearMatrices,
          simSettingsOpt,
          filenamePrefix,
          crefToSimVarHT);
        
        Debug.fcall("execFiles",print, "*** SimCode -> collect all files started: " +& realString(clock()) +& "\n" );
        // adrpo: collect all the files from Absyn.Info and DAE.ElementSource
        // simCode = collectAllFiles(simCode);
        Debug.fcall("execFiles",print, "*** SimCode -> collect all files done!: " +& realString(clock()) +& "\n" );
      then
        simCode;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Transformation from optimised DAE to simulation code structure failed"});
      then
        fail();
  end matchcontinue;
end createSimCode;

protected function expandModelInfoVars
"Expand Modelinfo with jacobain Vars"
  input list<JacobianMatrix> inJacs;
  input ModelInfo inModelinfo;
  output ModelInfo outModelinfo;
algorithm
  outModelinfo := 
  match (inJacs,inModelinfo)
    local
      list<SimVar> jacvars;
      SimVars linearVars,vars,simvarsandlinearvars;
      ModelInfo minfo;
      Absyn.Path name;
      String dir;
      VarInfo varinfo;
      list<Function> functions;
      Integer nx, ny, np, ng, ng_sam, ng_sam_1, next, ny_string, np_string, ng_1;
      Integer nhv,nin, nresi, nout, ny_int, np_int, ny_bool, np_bool, na, na_int, na_bool, na_string;
      Integer njacvars;
      Option<Integer> dim1,dim2;
      case(inJacs,minfo as (MODELINFO(name,dir,VARINFO(nhv, ng_1, ng_sam_1, nx, ny, ny_int, ny_bool, na, na_int, na_bool, np, np_int, np_bool, nout, nin,
          nresi, next, ny_string, np_string, na_string,_,dim1,dim2),vars,functions)))
        equation
          jacvars = appendAllVars(inJacs);
          jacvars = rewriteIndex(jacvars,0);
          njacvars = listLength(jacvars);
          linearVars = SIMVARS({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},{},{},{},{},{},jacvars,{},{},{},{});
          simvarsandlinearvars = mergeVars(vars,linearVars);
        then MODELINFO(name, dir, VARINFO(nhv, ng_1, ng_sam_1, nx, ny, ny_int, ny_bool, na, na_int, na_bool, np, np_int, np_bool, nout, nin,
          nresi, next, ny_string, np_string, na_string, njacvars,dim1,dim2), simvarsandlinearvars, functions);
   end match;
end expandModelInfoVars;

protected function createLinearModelMatrixes
"fuction creates the linear model matrices column-wise
 author: wbraun"
  input DAE.FunctionTree functions;
  input BackendDAE.BackendDAE inBackendDAE2;
  input list<JacobianMatrix> injacobianMatrixes;
  output list<JacobianMatrix> outJacobianMatrixes;
algorithm
  outJacobianMatrixes :=
  matchcontinue (functions,inBackendDAE2,injacobianMatrixes)
    local
      BackendDAE.BackendDAE dlow;
      
      list<BackendDAE.Var>  varlst, knvarlst, varlst_tmp, states, inputvars, inputvars2, outputvars, paramvars;
      list<DAE.ComponentRef> comref_states, comref_inputvars, comref_outputvars, comref_vars, comref_knvars;
      
      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray e;
      
      list<JacobianMatrix> linearModelMatrices;
      JacobianMatrix linearModelMatrix;
      
    case (functions,dlow as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars = v,orderedEqs = e)::{},BackendDAE.SHARED(knownVars = kv)),_)
      equation
        true = RTOpts.debugFlag("linearization");
        
        // Prepare all needed variables
        varlst = BackendDAEUtil.varList(v);
        comref_vars = Util.listMap(varlst,BackendVariable.varCref);
        knvarlst = BackendDAEUtil.varList(kv);
        comref_knvars = Util.listMap(knvarlst,BackendVariable.varCref);
        states = BackendVariable.getAllStateVarFromVariables(v);
        states = Util.sort(states, BackendVariable.varIndexComparer);
        inputvars = Util.listSelect(knvarlst,BackendVariable.isInput);
        inputvars = Util.sort(inputvars, BackendVariable.varIndexComparer);
        paramvars = Util.listSelect(knvarlst, BackendVariable.isParam);
        paramvars = Util.sort(paramvars,  BackendVariable.varIndexComparer);
        inputvars2 = Util.listSelect(knvarlst,BackendVariable.isVarOnTopLevelAndInput);
        inputvars2 = Util.sort(inputvars2, BackendVariable.varIndexComparer);
        outputvars = Util.listSelect(varlst,BackendVariable.isVarOnTopLevelAndOutput);
        outputvars = Util.sort(outputvars, BackendVariable.varIndexComparer);
        
        comref_states = Util.listMap(states,BackendVariable.varCref);
        comref_inputvars = Util.listMap(inputvars2,BackendVariable.varCref);
        comref_outputvars = Util.listMap(outputvars,BackendVariable.varCref);
        
        // Differentiate the System w.r.t states for matrices A
        Debug.fcall("execStat",print, "*** analytical Jacobians -> generated system for matrix A : " +& realString(clock()) +& "\n" );
        linearModelMatrix = createJacobianColumns(functions,dlow,comref_states,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),comref_states, comref_states,varlst,(comref_vars,comref_knvars),listLength(states),"A");
        linearModelMatrices = {linearModelMatrix};

        // Differentiate the System w.r.t inputs for matrices B
        Debug.fcall("execStat",print, "*** analytical Jacobians -> generated system for matrix B : " +& realString(clock()) +& "\n" );
        linearModelMatrix = createJacobianColumns(functions,dlow,comref_inputvars,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),comref_inputvars,comref_states,varlst,(comref_vars,comref_knvars),listLength(states),"B");
        linearModelMatrices = listAppend(linearModelMatrices,{linearModelMatrix});

        // Differentiate the System w.r.t states for matrices C
        Debug.fcall("execStat",print, "*** analytical Jacobians -> generated system for matrix C : " +& realString(clock()) +& "\n" );
        linearModelMatrix = createJacobianColumns(functions,dlow,comref_states,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),comref_states,comref_outputvars,varlst,(comref_vars,comref_knvars),listLength(states),"C");
        linearModelMatrices = listAppend(linearModelMatrices,{linearModelMatrix});
        
        // Differentiate the System w.r.t inputs for matrices D
        Debug.fcall("execStat",print, "*** analytical Jacobians -> generated system for matrix D : " +& realString(clock()) +& "\n" );
        linearModelMatrix = createJacobianColumns(functions,dlow,comref_inputvars,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),comref_inputvars,comref_outputvars,varlst,(comref_vars,comref_knvars),listLength(states),"D");
        linearModelMatrices = listAppend(linearModelMatrices,{linearModelMatrix});
        
      then
        linearModelMatrices;
    case (_,dlow,linearModelMatrices)
      equation
        false = RTOpts.debugFlag("linearization");
        true = RTOpts.debugFlag("jacobian");
      then
        linearModelMatrices;

    case (_,dlow,_)
      equation
        false = RTOpts.debugFlag("linearization");
        false = RTOpts.debugFlag("jacobian");
        linearModelMatrices = {({},{},"A"),({},{},"B"),({},{},"C"),({},{},"D")};
      then
        linearModelMatrices;
    case (_, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of LinearModel Matrixes code using templates failed"});
      then
        fail();
  end matchcontinue;
end createLinearModelMatrixes;

protected function createJacobianCC
"fuction creates the jacobian column-wise
 author: wbraun"
  input DAE.FunctionTree functions;
  input BackendDAE.BackendDAE inBackendDAE2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input BackendDAE.StrongComponents inComps;
  output list<JacobianMatrix> outjacobianMatrixes;
algorithm
  outjacobianMatrixes :=
  matchcontinue (functions,inBackendDAE2,inIntegerArray3,inIntegerArray4,inComps)
    local
      BackendDAE.BackendDAE dlow;
      array<Integer> ass1,ass2;
      BackendDAE.StrongComponents blt_states,comps;
      
      list<BackendDAE.Var>  varlst, knvarlst, varlst_tmp, states, inputvars, paramvars;
      list<DAE.ComponentRef> comref_states,comref_vars,comref_knvars;
      
      BackendDAE.Variables v,kv,newVars;
      BackendDAE.EquationArray e,newEqns;
      
      JacobianMatrix linearModelMatrix;
      list<JacobianMatrix> linearModelMatrices;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      
    case (functions,dlow as BackendDAE.DAE({syst as BackendDAE.EQSYSTEM(orderedVars = v,orderedEqs = e)},shared as BackendDAE.SHARED(knownVars = kv)),ass1,ass2,comps)
      equation
        true = RTOpts.debugFlag("jacobian");
        
        (blt_states, _) = BackendDAEUtil.generateStatePartition(syst);
        
        newEqns = BackendDAEUtil.listEquation({});
        newVars = BackendDAEUtil.emptyVars();
        (newEqns, newVars) = splitoutEquationAndVars(blt_states,e,v,newEqns,newVars);
        dlow = BackendDAE.DAE(BackendDAE.EQSYSTEM(newVars,newEqns,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
         
        // Prepare all needed variables
        varlst_tmp = BackendDAEUtil.varList(v);
        comref_vars = Util.listMap(varlst_tmp,BackendVariable.varCref);
        varlst_tmp = BackendDAEUtil.varList(kv);
        comref_knvars = Util.listMap(varlst_tmp,BackendVariable.varCref);
        varlst = BackendDAEUtil.varList(newVars);
        knvarlst = BackendDAEUtil.varList(kv);
        states = BackendVariable.getAllStateVarFromVariables(newVars);
        states = Util.sort(states, BackendVariable.varIndexComparer);
        inputvars = Util.listSelect(knvarlst,BackendVariable.isInput);
        inputvars = Util.sort(inputvars, BackendVariable.varIndexComparer);
        paramvars = Util.listSelect(knvarlst, BackendVariable.isParam);
        paramvars = Util.sort(paramvars,  BackendVariable.varIndexComparer);
        
        comref_states = Util.listMap(states,BackendVariable.varCref);
        
        Debug.fcall("execStat",print, "*** analytical Jacobians -> generated system for matrix A : " +& realString(clock()) +& "\n" );
        linearModelMatrix = createJacobianColumns(functions,dlow,comref_states,BackendDAEUtil.listVar(states),BackendDAEUtil.listVar(inputvars),BackendDAEUtil.listVar(paramvars),comref_states,comref_states,varlst,(comref_vars,comref_knvars),listLength(states),"A");
        // add empty matrices B,C,D
        linearModelMatrices = {linearModelMatrix,({},{},"B"),({},{},"C"),({},{},"D")};
      then
        linearModelMatrices;
    case (_,dlow,ass1,ass2,_)
      equation
        false = RTOpts.debugFlag("jacobian");
        linearModelMatrices = {({},{},"A"),({},{},"B"),({},{},"C"),({},{},"D")};
      then
        linearModelMatrices;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of Jacobian Matrix code using templates failed"});
      then
        fail();
  end matchcontinue;
end createJacobianCC;

protected function splitoutEquationAndVars
" helper fuction of createJacobianCC
 author: wbraun"
  input BackendDAE.StrongComponents inNeededBlocks;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqnsNew;
  input BackendDAE.Variables inVarsNew;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.Variables outVars;
algorithm 
  (outEqns,outVars) := matchcontinue( inNeededBlocks,inEqns,inVars, inEqnsNew, inVarsNew)
  local
    BackendDAE.StrongComponent comp;
    BackendDAE.StrongComponents rest;
    BackendDAE.Equation eqn;
    BackendDAE.Var var;
    list<BackendDAE.Equation> eqn_lst;
    list<BackendDAE.Var> var_lst;
    BackendDAE.EquationArray eqnsNew;
    BackendDAE.Variables varsNew;
    case ({},inEqns,inVars,eqnsNew,varsNew) then (eqnsNew,varsNew);
    case (comp::rest,inEqns,inVars,eqnsNew,varsNew)
      equation
      (eqnsNew,varsNew) = splitoutEquationAndVars(rest,inEqns,inVars,eqnsNew,varsNew);
      (eqn_lst,var_lst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, inEqns, inVars);
      eqnsNew = BackendEquation.addEquations(eqn_lst, eqnsNew);
      varsNew = BackendVariable.addVars(var_lst, varsNew);
    then (eqnsNew,varsNew);
 end matchcontinue;
end splitoutEquationAndVars;

protected function createJacobianColumns
" helper fuction of createJacobianCC
 author: wbraun"
  input DAE.FunctionTree inFunctions;
  input BackendDAE.BackendDAE inBackendDAE;
  input list<DAE.ComponentRef> inDiffVars;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParameterVars;
  input list<DAE.ComponentRef> inDiffVars1;
  input list<DAE.ComponentRef> indifferentiatedVars;
  input list<BackendDAE.Var> inVars;
  input tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>> inOrigTuple;
  input Integer inNoDiffVars;
  input String inName;
  output JacobianMatrix outColumnns;
algorithm
  outColumnns :=
  matchcontinue (inFunctions,inBackendDAE,inDiffVars,inStateVars,inInputVars,inParameterVars,inDiffVars1,indifferentiatedVars,inVars,inOrigTuple,inNoDiffVars,inName)
    local
      list<JacobianColumn> resultList;
      JacobianColumn result;
      list<BackendDAE.Var> diffedVars;
      list<SimVar> jacVars;
      DAE.ComponentRef inDiffVar;
      list<DAE.ComponentRef> rest,diffVars;
      list<DAE.ComponentRef> inOrigVars,inOrigKnVars;
      Integer column;
    case (_,_,{},_,_,_,inDiffVars1,indifferentiatedVars,inVars,_,_,inName)
      equation
        diffedVars = BackendDAEOptimize.createJacVars(inVars,inDiffVars1,indifferentiatedVars);
        ((jacVars,_)) =  BackendVariable.traverseBackendDAEVars(BackendDAEUtil.listVar(diffedVars),traversingdlowvarToSimvar,({},BackendDAEUtil.emptyVars()));
      then (({},jacVars,inName));
    case (inFunctions,inBackendDAE,inDiffVar::rest,inStateVars,inInputVars,inParameterVars,diffVars,indifferentiatedVars,inVars,(inOrigVars,inOrigKnVars),inNoDiffVars,inName)
      equation
        column = inNoDiffVars - (listLength(rest)+1);
        result = createJacobianColumn(inFunctions,inBackendDAE,inDiffVar,inStateVars,inInputVars,inParameterVars,indifferentiatedVars,inVars,(inOrigVars,inOrigKnVars),column);
        ((resultList,jacVars,inName)) = createJacobianColumns(inFunctions,inBackendDAE,rest,inStateVars,inInputVars,inParameterVars,diffVars,indifferentiatedVars,inVars,(inOrigVars,inOrigKnVars),inNoDiffVars,inName);
      then
        ((result::resultList,jacVars,inName));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.createJacobianColumns failed"});
      then
        fail();
  end matchcontinue;
end createJacobianColumns;

protected function createJacobianColumn
" helper fuction of createJacobianCC
 author: wbraun"
  input DAE.FunctionTree inFunctions;
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.ComponentRef inDiffVar;
  input BackendDAE.Variables inStateVars;
  input BackendDAE.Variables inInputVars;
  input BackendDAE.Variables inParameterVars;
  input list<DAE.ComponentRef> inDifferentiatedVars;
  input list<BackendDAE.Var> inVars;
  input tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>> inOrigTuple;
  input Integer inNoColumn;
  output tuple<list<SimEqSystem>,list<SimVar>,String> outColumnn;
algorithm
  outColumnn :=
  matchcontinue (inFunctions,inBackendDAE,inDiffVar,inStateVars,inInputVars,inParameterVars,inDifferentiatedVars,inVars,inOrigTuple,inNoColumn)
    local
      BackendDAE.BackendDAE backendDAE;
      array<Integer> ass1,ass2;
      BackendDAE.StrongComponents comps;
      
      list<DAE.ComponentRef> inOrigVars,inOrigKnVars,comref_vars;
      
      list<SimEqSystem> columnEquations;
      list<SimVar> columnVars;
      list<SimVar> columnVarsKn;
      
      BackendDAE.Shared shared,shared1;
      BackendDAE.EqSystem syst;
      BackendDAE.Variables vars, knvars, empty;
      
      String name;
    case (inFunctions,inBackendDAE,inDiffVar,inStateVars,inInputVars,inParameterVars,inDifferentiatedVars,inVars,(inOrigVars,inOrigKnVars),inNoColumn)
      equation

        name = ComponentReference.printComponentRefStr(inDiffVar);
        
        // Differentiate the ODE system w.r.t states for jacobian
        Debug.fcall("execStat",print,"Differentiate System w.r.t. "+& name +& ".\n");
        backendDAE = BackendDAEOptimize.generateSymbolicJacobian(inBackendDAE, inFunctions, {inDiffVar}, inStateVars, inInputVars, inParameterVars);
        
        // create equations and variables
        (backendDAE as BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))},shared=shared)) = BackendDAEOptimize.generateLinearMatrix(backendDAE,inFunctions,inDifferentiatedVars,{inDiffVar},inVars,inNoColumn);
        columnEquations = createEquations(false, false, false, false, true, backendDAE, comps, {});
        Debug.fcall("execStat",print, "*** analytical Jacobians column "+& intString(inNoColumn) +& " for " +& name +& " created: " +& realString(clock()) +& "\n");
        
        vars = BackendVariable.daeVars(syst);
        knvars = BackendVariable.daeKnVars(shared);
        knvars = Util.listFold(inOrigVars, BackendVariable.deleteVar,knvars);
        knvars = Util.listFold(inOrigKnVars, BackendVariable.deleteVar,knvars);        
        empty = BackendDAEUtil.emptyVars();
        ((columnVars,_)) =  BackendVariable.traverseBackendDAEVars(vars,traversingdlowvarToSimvar,({},empty));
        ((columnVarsKn,_)) =  BackendVariable.traverseBackendDAEVars(knvars,traversingdlowvarToSimvar,({},empty));
        columnVars = listAppend(columnVars,columnVarsKn);
        columnVars = listReverse(columnVars);
        Debug.fcall("execStat",print, "*** analytical Jacobians column "+& intString(inNoColumn) +& " for " +& name +& " created: " +& realString(clock()) +& "\n");
        
      then
        ((columnEquations,columnVars,intString(inNoColumn)));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.createJacobianColumn failed"});
      then
        fail();
  end matchcontinue;
end createJacobianColumn;

protected function collectDelayExpressions
"Put expression into a list if it is a call to delay().
Useable as a function parameter for Expression.traverseExpression."
  input tuple<DAE.Exp, list<DAE.Exp>> inTuple;
  output tuple<DAE.Exp, list<DAE.Exp>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      list<DAE.Exp> l;
    case ((e as DAE.CALL(path = Absyn.IDENT("delay")), l))
    then ((e, e :: l));
    case inTuple then inTuple;
  end matchcontinue;
end collectDelayExpressions;

protected function findDelaySubExpressions
"Return all subexpressions of inExp that are calls to delay()"
  input tuple<DAE.Exp,list<DAE.Exp>> itpl;
  output tuple<DAE.Exp,list<DAE.Exp>> otpl;
protected
  DAE.Exp e;
  list<DAE.Exp> el;
algorithm
  (e,el) := itpl;
  otpl := Expression.traverseExp(e, collectDelayExpressions, el);
end findDelaySubExpressions;

protected function extractDelayedExpressions
  input BackendDAE.BackendDAE dlow;
  output list<tuple<Integer, DAE.Exp>> delayedExps;
  output Integer maxDelayedExpIndex;
algorithm
  (delayedExps,maxDelayedExpIndex) := matchcontinue(dlow)
    local
      list<DAE.Exp> exps;
    case (dlow)
      equation
        exps = BackendDAEUtil.traverseBackendDAEExps(dlow,findDelaySubExpressions,{});
        delayedExps = Util.listMap(exps, extractIdAndExpFromDelayExp);
        maxDelayedExpIndex = Util.listFold(Util.listMap(delayedExps, Util.tuple21), intMax, -1);
      then
        (delayedExps,maxDelayedExpIndex+1);
    case (_)
      equation
        Debug.fprintln("failtrace", "- SimCode.extractDelayedExpressions failed");
      then
        fail();
  end matchcontinue;
end extractDelayedExpressions;

function extractIdAndExpFromDelayExp
  input DAE.Exp delayCallExp;
  output tuple<Integer, DAE.Exp> delayedExp;
algorithm
  delayedExp :=
  match (delayCallExp)
    local
      DAE.Exp  e, delay, delayMax;
      Integer i;
    case (DAE.CALL(path=Absyn.IDENT("delay"), expLst={DAE.ICONST(i),e,delay,delayMax}))
    then ((i, e));
  end match;
end extractIdAndExpFromDelayExp;

protected function createMakefileParams
  input list<String> includes;
  input list<String> libs;
  output MakefileParams makefileParams;
protected
  String omhome,ccompiler,cxxcompiler,linker,exeext,dllext,cflags,ldflags,senddatalibs,platform;
algorithm
  ccompiler := System.getCCompiler();
  cxxcompiler := System.getCXXCompiler();
  linker := System.getLinker();
  exeext := System.getExeExt();
  dllext := System.getDllExt();
  omhome := Settings.getInstallationDirectoryPath();
  omhome := System.trim(omhome, "\""); // Remove any quotation marks from omhome.
  cflags := System.getCFlags();
  ldflags := System.getLDFlags();
  senddatalibs := System.getSendDataLibs();
  platform := System.platform();
  makefileParams := MAKEFILE_PARAMS(ccompiler, cxxcompiler, linker, exeext, dllext,
        omhome, cflags, ldflags, senddatalibs, includes, libs, platform);
end createMakefileParams;

protected function generateHelpVarInfo
  input BackendDAE.BackendDAE dlow;
  output list<HelpVarInfo> outHelpVarInfo;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<BackendDAE.Equation> outSampleEqns;
algorithm
  outHelpVarInfo := helpVarInfoFromWhenConditionChecks(dlow);
  (outHelpVarInfo, dlow) := generateHelpVarsForWhenStatements(outHelpVarInfo, dlow);
  // Generate HelpVars for sample call outside whenclause
  // additional collect all these equations
  (outBackendDAE,(outHelpVarInfo,outSampleEqns)) := BackendDAEUtil.mapEqSystemAndFold(dlow,searchForSampleOutsideWhen,(outHelpVarInfo,{}));
end generateHelpVarInfo;

protected function searchForSampleOutsideWhen
  input BackendDAE.EqSystem syst;
  input tuple<BackendDAE.Shared,tuple<list<HelpVarInfo>,list<BackendDAE.Equation>>> tpl;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,tuple<list<HelpVarInfo>,list<BackendDAE.Equation>>> otpl;
algorithm
  (osyst,otpl) := matchcontinue (syst,tpl)
    local
      list<HelpVarInfo> helpvars;
      BackendDAE.Variables orderedVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables externalObjects;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray orderedEqs;
      list<BackendDAE.Equation> eqnsList;
      BackendDAE.EquationArray removedEqs;
      BackendDAE.EquationArray initialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      array<Algorithm.Algorithm> algorithms;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      list<BackendDAE.Equation> sampleEquations;
      BackendDAE.Shared shared;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
    case (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching),(shared,(helpvars,sampleEquations)))
      equation
        eqnsList = BackendDAEUtil.equationList(orderedEqs);
        (eqnsList,sampleEquations,(_,helpvars)) = BackendEquation.traverseBackendDAEExpsEqnListOutEqn(eqnsList, sampleEquations, sampleFinder,  (listLength(helpvars)-1,helpvars));
        orderedEqs = BackendDAEUtil.listEquation(eqnsList);
      then (BackendDAE.EQSYSTEM(orderedVars,orderedEqs,m,mT,matching),(shared,(helpvars,sampleEquations)));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"searchForSampleOutsideWhen failed"});
      then fail();
  end matchcontinue;
end searchForSampleOutsideWhen;

protected function sampleFinder
"function: sampleFinder
  Helper function to sample in equation."
  input tuple<DAE.Exp, tuple<Integer,list<HelpVarInfo>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, Boolean, tuple<Integer,list<HelpVarInfo>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  match (inTplExpExpTplExpExpLstVariables)
    local
      Integer nhelpvars,nhelpvars1;
      DAE.Exp e;
      list<HelpVarInfo> helpvars;
      Boolean b;
    case ((e,(nhelpvars,helpvars)))
      equation
        ((e,(nhelpvars1,helpvars))) = Expression.traverseExp(e, findSampleInExps, (nhelpvars,helpvars));
        b = nhelpvars1 > nhelpvars;
      then ((e,b,(nhelpvars1,helpvars)));
  end match;
end sampleFinder;

protected function findSampleInExps "function: findSampleInExps

  Collects zero crossings
"
  input tuple<DAE.Exp, tuple<Integer,list<HelpVarInfo>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, tuple<Integer,list<HelpVarInfo>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      Integer nhelpvars;
      list<HelpVarInfo> helpvars;
      DAE.Exp e;
      Absyn.Path name;
      list<DAE.Exp> args_;
      Boolean tup,builtin_;
      DAE.ExpType exty;
      DAE.InlineType inty;
      DAE.CallAttributes attr;
    case (((e as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr)),(nhelpvars,helpvars)))
      equation
        nhelpvars = nhelpvars+1;
        args_ = listAppend(args_,{DAE.ICONST(nhelpvars)});
        e = DAE.CALL(name, args_, attr);
        helpvars = listAppend(helpvars,{(nhelpvars,e,-1)});
      then ((e,(nhelpvars,helpvars)));
    case ((e,(nhelpvars,helpvars)))
    then ((e,(nhelpvars,helpvars)));
  end matchcontinue;
end findSampleInExps;

protected function helpVarInfoFromWhenConditionChecks
"Return a list of help variables that were introduced by when conditions?"
  input BackendDAE.BackendDAE inBackendDAE;
  output list<HelpVarInfo> helpVarList;
algorithm
  helpVarList :=
  matchcontinue (inBackendDAE)
    local
      list<Integer> orderOfEquations,orderOfEquations_1;
      Integer n;
      list<HelpVarInfo> helpVarInfo1,helpVarInfo2,helpVarInfo;
      BackendDAE.BackendDAE dlow;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.WhenClause> whenClauseList;
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(eqs=systs,shared=shared as BackendDAE.SHARED(eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = whenClauseList))))
      equation
        helpVarInfo1 = Util.listFlatten(Util.listMap1(systs,helpVarInfoFromWhenConditionChecks1,shared));
        n = listLength(helpVarInfo1);
        // Generate checks also for when clauses without equations but containing reinit statements.
        (_, helpVarInfo2) = buildWhenConditionChecks2(whenClauseList, 0, n);
        helpVarInfo = listAppend(helpVarInfo1, helpVarInfo2);
      then
        (helpVarInfo);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCode.helpVarInfoFromWhenConditionChecks failed"});
      then
        fail();
  end matchcontinue;
end helpVarInfoFromWhenConditionChecks;

protected function helpVarInfoFromWhenConditionChecks1
"Return a list of help variables that were introduced by when conditions?"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output list<HelpVarInfo> helpVarList;
algorithm
  helpVarList :=
  matchcontinue (syst,shared)
    local
      list<Integer> orderOfEquations,orderOfEquations_1;
      Integer n;
      list<HelpVarInfo> helpVarInfo1,helpVarInfo2,helpVarInfo;
      BackendDAE.BackendDAE dlow;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.WhenClause> whenClauseList;
      BackendDAE.StrongComponents comps;
    case (BackendDAE.EQSYSTEM(orderedEqs = eqns, matching = BackendDAE.MATCHING(comps=comps)),shared as BackendDAE.SHARED(eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = whenClauseList)))
      equation
        orderOfEquations = generateEquationOrder(comps);
        n = BackendDAEUtil.equationSize(eqns);
        orderOfEquations_1 = addMissingEquations(n, listReverse(orderOfEquations));
        // First generate checks for all when equations, in the order of the sorted equations.
        (_, helpVarInfo) = buildWhenConditionChecks4(orderOfEquations_1, eqns, whenClauseList, 0);
      then
        (helpVarInfo);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCode.helpVarInfoFromWhenConditionChecks1 failed"});
      then
        fail();
  end matchcontinue;
end helpVarInfoFromWhenConditionChecks1;

protected function buildDiscreteVarChanges "
For all discrete variables in the model, generate code that checks if they have changed and if so generate code
that add events to the event queue: if (change(<discretevar>)) { AddEvent(c1);...;AddEvent(cn)}

"
  input BackendDAE.BackendDAE daelow;
  input list<list<Integer>> comps;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  output String outString;
algorithm
  outString := matchcontinue(daelow,comps,ass1,ass2,m,mT)
    local String s1,s2;
      list<Integer> b;
      list<list<Integer>> blocks;
      BackendDAE.Variables v;
      list<BackendDAE.Var> vLst;
    case (daelow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = v)::{}),blocks,ass1,ass2,m,mT)
      equation
        vLst = BackendVariable.getAllDiscreteVarFromVariables(v); // select all discrete vars.
        outString = Util.stringDelimitList(Util.listMap2(vLst, buildDiscreteVarChangesVar,daelow,mT),"\n  ");
      then outString;
    case(_,_,_,_,_,_) equation
      print("buildDiscreteVarChanges failed\n");
    then fail();
  end matchcontinue;
end buildDiscreteVarChanges;

protected function buildDiscreteVarChangesVar "help function to buildDiscreteVarChanges"
  input BackendDAE.Var var;
  input BackendDAE.BackendDAE daelow;
  input BackendDAE.IncidenceMatrixT mT;
  output String outString;
algorithm
  outString := matchcontinue(var,daelow,mT)
    local list<String> strLst;
      Expression.ComponentRef cr;
      Integer varIndx;
      list<Integer> eqns;
    case(var as BackendDAE.VAR(varName=cr,index=varIndx), daelow,mT) equation
      eqns = mT[varIndx+1]; // eqns containing var
      true = crefNotInWhenEquation(cr,daelow,eqns);
      outString = buildDiscreteVarChangesAddEvent(0,cr);
    then outString;
      
    case(_,_,_) then "";
  end matchcontinue;
end buildDiscreteVarChangesVar;

protected function crefNotInWhenEquation "Returns true if cref is not solved in any of the equations
given as indices which is a when_equation"
  input Expression.ComponentRef cr;
  input BackendDAE.BackendDAE daelow;
  input list<Integer> eqns;
  output Boolean res;
algorithm
  res := matchcontinue(cr,daelow,eqns)
    local
      BackendDAE.EquationArray eqs;
      Integer e;
      Expression.ComponentRef cr2;
      DAE.Exp exp;
      Boolean b1,b2;
      
    case(cr,daelow,{}) then true;
      
    case(cr,daelow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedEqs=eqs)::{}),e::eqns) 
      equation
        BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(_,cr2,exp,_)) = BackendDAEUtil.equationNth(eqs,intAbs(e)-1);
        //We can asume the same component refs are solved in any else-branch.
        b1 = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        b2 = Expression.expContains(exp,Expression.crefExp(cr));
        true = boolOr(b1,b2);
      then false;
        
    case(cr,daelow,_::eqns) 
      equation
        res = crefNotInWhenEquation(cr,daelow,eqns);
      then res;
  end matchcontinue;
end crefNotInWhenEquation;

protected function elaborateRecordDeclarationsFromTypes
  input list<DAE.Type> inTypes;
  input list<RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) :=
  match (inTypes, inAccRecordDecls, inReturnTypes)
    local
      list<RecordDeclaration> accRecDecls;
      DAE.Type firstType;
      list<DAE.Type> restTypes;
    case ({}, accRecDecls, inReturnTypes)
    then (accRecDecls, inReturnTypes);
    case (firstType :: restTypes, accRecDecls, inReturnTypes)
      equation
        (accRecDecls, inReturnTypes) =
        elaborateRecordDeclarationsForRecord(firstType, accRecDecls, inReturnTypes);
        (accRecDecls, inReturnTypes) =
        elaborateRecordDeclarationsFromTypes(restTypes, accRecDecls, inReturnTypes);
      then (accRecDecls, inReturnTypes);
  end match;
end elaborateRecordDeclarationsFromTypes;

protected function elaborateRecordDeclarations
"function elaborateRecordDeclarations
Translate all records used by varlist to structs."
  input list<DAE.Element> inVars;
  input list<RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) :=
  matchcontinue (inVars, inAccRecordDecls, inReturnTypes)
    local
      DAE.Element var;
      list<DAE.Element> rest;
      Types.Type ft;
      list<String> rt, rt_1, rt_2;
      list<RecordDeclaration> accRecDecls;
      Algorithm.Algorithm algorithm_;
      list<DAE.Exp> expl;
      
    case ({}, accRecDecls, rt) then (accRecDecls,rt);
      
    case (((var as DAE.VAR(ty = ft)) :: rest), accRecDecls, rt)
      equation
        (accRecDecls,rt_1) = elaborateRecordDeclarationsForRecord(ft, accRecDecls, rt);
        (accRecDecls,rt_2) = elaborateRecordDeclarations(rest, accRecDecls, rt_1);
      then
        (accRecDecls,rt_2);
        
    case ((DAE.ALGORITHM(algorithm_ = algorithm_) :: rest), accRecDecls, rt)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        ((_,expl)) = BackendDAEUtil.traverseAlgorithmExps(algorithm_, Expression.traverseSubexpressionsHelper, (matchMetarecordCalls,{}));
        (accRecDecls,rt_2) = elaborateRecordDeclarationsForMetarecords(expl, accRecDecls, rt);
        //TODO: ? what about rest ? , can be there something else after the ALGORITHM
        (accRecDecls,rt_2) = elaborateRecordDeclarations(rest, accRecDecls, rt_2);
      then
        (accRecDecls,rt_2);
        
    case ((_ :: rest), accRecDecls, rt)
      equation
        (accRecDecls,rt_1) = elaborateRecordDeclarations(rest, accRecDecls, rt);
      then
        (accRecDecls,rt_1);
  end matchcontinue;
end elaborateRecordDeclarations;

protected function elaborateRecordDeclarationsForRecord
"function generateRecordDeclarations
Helper function to generateStructsForRecords."
  input Types.Type inRecordType;
  input list<RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) :=
  matchcontinue (inRecordType,inAccRecordDecls,inReturnTypes)
    local
      Absyn.Path path,name;
      list<Types.Var> varlst;
      String    sname;
      list<String> rt,rt_1,rt_2,fieldNames;
      list<RecordDeclaration> accRecDecls;
      list<Variable> vars;
      Integer index;
      RecordDeclaration recDecl;
      
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name), complexVarLst = varlst),SOME(path)), accRecDecls, rt)
      equation
        sname = ModUtil.pathStringReplaceDot(name, "_");
        false = listMember(sname,rt);
        vars = Util.listMap(varlst, typesVar);
        rt_1 = sname :: rt;
        (accRecDecls,rt_2) = elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);
        recDecl = RECORD_DECL_FULL(sname, path, vars);
        accRecDecls = Util.listAppendElt(recDecl, accRecDecls);
      then (accRecDecls,rt_2);
        
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name), complexVarLst = varlst),_), accRecDecls, rt)
    then (accRecDecls,rt);
        
    case ((DAE.T_METARECORD(index = index, fields = varlst), SOME(path)), accRecDecls, rt)
      equation
        sname = ModUtil.pathStringReplaceDot(path, "_");
        false = listMember(sname,rt);
        fieldNames = Util.listMap(varlst, generateVarName);
        accRecDecls = RECORD_DECL_DEF(path, fieldNames) :: accRecDecls;
        rt_1 = sname::rt;
        (accRecDecls,rt_2) = elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);
      then (accRecDecls,rt_2);
        
    case ((_,_), accRecDecls, rt)
    then (accRecDecls,rt);
        
    case ((_,_), accRecDecls, rt) then
      (RECORD_DECL_FULL("#an odd record#", Absyn.IDENT("?noname?"), {}) :: accRecDecls ,rt);
  end matchcontinue;
end elaborateRecordDeclarationsForRecord;

protected function generateVarName
  input DAE.Var inVar;
  output String outName;
algorithm
  outName :=
  matchcontinue (inVar)
    local
      DAE.Ident name;
    case DAE.TYPES_VAR(name = name)
    then name;
    case (_)
    then "NULL";
  end matchcontinue;
end generateVarName;

protected function elaborateNestedRecordDeclarations
"function elaborateNestedRecordDeclarations
Helper function to elaborateRecordDeclarations."
  input list<Types.Var> inRecordTypes;
  input list<RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) := matchcontinue (inRecordTypes,inAccRecordDecls,inReturnTypes)
    local
      Types.Type ty;
      list<Types.Var> rest;
      list<String> rt,rt_1,rt_2;
      list<RecordDeclaration> accRecDecls;
    case ({},accRecDecls,rt)
    then (accRecDecls,rt);
    case (DAE.TYPES_VAR(ty = (ty as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_)))::rest,accRecDecls,rt)
      equation
        (accRecDecls,rt_1) = elaborateRecordDeclarationsForRecord(ty,accRecDecls,rt);
        (accRecDecls,rt_2) = elaborateNestedRecordDeclarations(rest,accRecDecls,rt_1);
      then (accRecDecls,rt_2);
    case (_::rest,accRecDecls,rt)
      equation
        (accRecDecls,rt_1) = elaborateNestedRecordDeclarations(rest,accRecDecls,rt);
      then (accRecDecls,rt_1);
  end matchcontinue;
end elaborateNestedRecordDeclarations;

protected function elaborateRecordDeclarationsForMetarecords
  input list<DAE.Exp> inExpl;
  input list<RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) := matchcontinue(inExpl, inAccRecordDecls, inReturnTypes)
    local
      list<String> rt,rt_1,rt_2,fieldNames;
      list<DAE.Exp> rest;
      String name;
      Absyn.Path path;
      list<RecordDeclaration> accRecDecls;
      
    case ({},accRecDecls,rt) then (accRecDecls,rt);
    case (DAE.METARECORDCALL(path=path,fieldNames=fieldNames)::rest, accRecDecls, rt)
      equation
        name = ModUtil.pathStringReplaceDot(path, "_");
        false = listMember(name,rt);
        accRecDecls = RECORD_DECL_DEF(path, fieldNames) :: accRecDecls;
        rt_1 = name::rt;
        (accRecDecls,rt_2) = elaborateRecordDeclarationsForMetarecords(rest, accRecDecls, rt_1);
      then (accRecDecls,rt_2);
    case (_::rest, accRecDecls, rt)
      equation
        (accRecDecls,rt_1) = elaborateRecordDeclarationsForMetarecords(rest, accRecDecls, rt);
      then (accRecDecls,rt_1);
  end matchcontinue;
end elaborateRecordDeclarationsForMetarecords;

protected function createExtObjInfo
  input BackendDAE.Shared shared;
  output ExtObjInfo extObjInfo;
algorithm
  extObjInfo := match shared
    local
      BackendDAE.Variables evars;
      list<BackendDAE.Var> evarLst;
      list<ExtAlias> aliases;
      list<SimVar> simvars;
    case BackendDAE.SHARED(externalObjects=evars)
      equation
        evarLst = BackendDAEUtil.varList(evars);
        (simvars,aliases) = extractExtObjInfo2(evarLst,evars);
      then EXTOBJINFO(simvars,aliases);
  end match;
end createExtObjInfo;

protected function extractExtObjInfo2
  input list<BackendDAE.Var> varLst;
  input BackendDAE.Variables evars;
  output list<SimVar> vars;
  output list<ExtAlias> aliases;
algorithm
  (vars,aliases) := match (varLst,evars)
    local
      BackendDAE.Var bv;
      SimVar sv;
      list<BackendDAE.Var> vs;
      DAE.ComponentRef cr,name;
    case ({},_) then ({},{});
    case (BackendDAE.VAR(varName=name, bindExp=SOME(DAE.CREF(cr,_)),varKind=BackendDAE.EXTOBJ(_))::vs,evars)
      equation
        (vars,aliases) = extractExtObjInfo2(vs,evars);
      then (vars,(name, cr)::aliases);
    case (bv::vs,evars)
      equation
        sv = dlowvarToSimvar(bv,NONE(),evars);
        (vars,aliases) = extractExtObjInfo2(vs,evars);
      then (sv::vars,aliases);
  end match;
end extractExtObjInfo2;

protected function createAlgorithmAndEquationAsserts
  input BackendDAE.BackendDAE dlow;
  output list<Algorithm.Statement> algorithmAndEquationAsserts;
algorithm
  algorithmAndEquationAsserts := match (dlow)
    local
      array<Algorithm.Algorithm> algs;
      list<Algorithm.Statement> res,res1;
      BackendDAE.EquationArray eqns;
      
    case(BackendDAE.DAE(shared=BackendDAE.SHARED(algorithms=algs),eqs=BackendDAE.EQSYSTEM(orderedEqs=eqns)::{}))
      equation
        res = createAlgorithmAndEquationAssertsFromAlgs(arrayList(algs));
        res1 = BackendDAEUtil.traverseBackendDAEExpsEqns(eqns,findSqrtCallsforAsserts,{});
        res = listAppend(res,res1);
      then res;
  end match;
end createAlgorithmAndEquationAsserts;

protected function findSqrtCallsforAsserts
  input tuple<DAE.Exp, list<Algorithm.Statement>> inTpl;
  output tuple<DAE.Exp, list<Algorithm.Statement>> outTpl;
algorithm
  outTpl :=
  matchcontinue inTpl
    local  
      DAE.Exp exp;
      list<Algorithm.Statement> inasserts;
    case ((exp,inasserts))
      equation
        ((_,inasserts)) = Expression.traverseExp(exp,findSqrtCallsforAssertsExps,inasserts);
       then
        ((exp,inasserts));
    case inTpl then inTpl;
  end matchcontinue;
end findSqrtCallsforAsserts;

protected function findSqrtCallsforAssertsExps
  input tuple<DAE.Exp, list<Algorithm.Statement>> inTuple;
  output tuple<DAE.Exp, list<Algorithm.Statement>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      String estr;
      Algorithm.Statement addAssert;
      list<Algorithm.Statement> inasserts;
    
    // special case for time, it is never part of the equation system  
    case (((e as DAE.CALL(path=Absyn.IDENT(name="sqrt"), expLst={e1})),inasserts))
      equation
        estr = "Model error: Argument of sqrt should be >= 0";
        addAssert = DAE.STMT_ASSERT(DAE.RELATION(e1,DAE.GREATEREQ(DAE.ET_REAL()),DAE.RCONST(0.0),-1,NONE()),DAE.SCONST(estr),DAE.emptyElementSource);
      then ((e, addAssert::inasserts));
    
    case inTuple then inTuple;
  end matchcontinue;
end findSqrtCallsforAssertsExps;


protected function createAlgorithmAndEquationAssertsFromAlgs
  input list<Algorithm.Algorithm> algs;
  output list<Algorithm.Statement> algorithmAndEquationAsserts;
algorithm
  algorithmAndEquationAsserts := matchcontinue (algs)
    local
      Algorithm.Statement stmt;
      list<Algorithm.Statement> restStmt;
      list<Algorithm.Algorithm> restAlgs;
      
    case ({}) then ({});
      
    case((DAE.ALGORITHM_STMTS({stmt as DAE.STMT_ASSERT(cond =_)})) :: restAlgs)
      equation
        restStmt = createAlgorithmAndEquationAssertsFromAlgs(restAlgs);
      then (stmt :: restStmt);
        
    case(_ :: restAlgs)
      equation
        restStmt = createAlgorithmAndEquationAssertsFromAlgs(restAlgs);
      then (restStmt);
  end matchcontinue;
end createAlgorithmAndEquationAssertsFromAlgs;

protected function createRemovedEquations
  input BackendDAE.BackendDAE dlow;
  output list<SimEqSystem> removedEquations;
algorithm
  removedEquations := match (dlow)
    local
      BackendDAE.EquationArray r;
      array<Algorithm.Algorithm> algs;
      BackendDAE.Variables vars;
      list<DAE.Algorithm> varasserts;
      list<SimEqSystem> simvarasserts;
      
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars)::{}, shared=BackendDAE.SHARED(removedEqs=r,algorithms=algs)))
      equation
        ((removedEquations,_)) = BackendEquation.traverseBackendDAEEqns(r,traversedlowEqToSimEqSystem,({},algs));
        
        // get minmax and nominal asserts
        varasserts = BackendVariable.traverseBackendDAEVars(vars,createVarMinMaxAssert,{});
        simvarasserts = Util.listMap(varasserts,dlowAlgToSimEqSystem);
        removedEquations = listAppend(removedEquations, simvarasserts);
        
      then removedEquations;
  end match;
end createRemovedEquations;

protected function traversedlowEqToSimEqSystem
  input tuple<BackendDAE.Equation, tuple<list<SimEqSystem>,array<Algorithm.Algorithm>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<list<SimEqSystem>,array<Algorithm.Algorithm>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local 
      BackendDAE.Equation e;
      SimEqSystem se;
      list<SimEqSystem> seqnlst;
      array<Algorithm.Algorithm> algs;
    case ((e,(seqnlst,algs)))
      equation
        se = dlowEqToSimEqSystem(e,algs);
      then ((e,(se::seqnlst,algs)));
    case inTpl then inTpl;
  end matchcontinue;
end traversedlowEqToSimEqSystem;

protected function traversingisVarDiscreteCrefFinder
"autor: Frenkel TUD 2010-11"
  input tuple<BackendDAE.Var, list<DAE.ComponentRef>> inTpl;
  output tuple<BackendDAE.Var, list<DAE.ComponentRef>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<DAE.ComponentRef> cr_lst;
      DAE.ComponentRef cr;
    case ((v,cr_lst))
      equation
        true = BackendDAEUtil.isVarDiscrete(v);
        cr = BackendVariable.varCref(v);
      then ((v,cr::cr_lst));
    case inTpl then inTpl;
  end matchcontinue;
end traversingisVarDiscreteCrefFinder;

protected function extractDiscreteModelVars
  input BackendDAE.BackendDAE dlow;
  output list<DAE.ComponentRef> discreteModelVars;
algorithm
  discreteModelVars := match (dlow)
    local
      BackendDAE.Variables v;
      BackendDAE.EquationArray e;
      list<DAE.ComponentRef> vLst1,vLst2;
      
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=e)::{}))
      equation
        // select all discrete vars.
        // remove those vars that are solved in when equations
        //vLst = Util.listSelect2(vLst, dlow, mT, varNotSolvedInWhen);
        // replace var with cref
        vLst1 = BackendEquation.traverseBackendDAEEqns(e,traversingisVarDiscreteCrefFinder2,{});
        vLst2 = BackendVariable.traverseBackendDAEVars(v,traversingisVarDiscreteCrefFinder,{});
        vLst2 = Util.listUnionComp(vLst1, vLst2, ComponentReference.crefEqual);
      then vLst2;
  end match;
end extractDiscreteModelVars;

protected function traversingisVarDiscreteCrefFinder2
"autor: Frenkel TUD 2010-11"
  input tuple<BackendDAE.Equation, list<DAE.ComponentRef>> inTpl;
  output tuple<BackendDAE.Equation, list<DAE.ComponentRef>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Equation e;
      list<DAE.Exp> expl1;
      list<DAE.ComponentRef> cr_lst,cr_lst1;
    case ((e as BackendDAE.ALGORITHM(out=expl1) ,cr_lst))
      equation
        true = BackendEquation.equationAlgorithm(e);
        cr_lst1 = Util.listMap(expl1,Expression.expCref);
        cr_lst1 = listAppend(cr_lst,cr_lst1);
      then ((e,cr_lst1));
    case inTpl then inTpl;
  end matchcontinue;
end traversingisVarDiscreteCrefFinder2;

protected function varNotSolvedInWhen
  input BackendDAE.Var var;
  input BackendDAE.BackendDAE dlow;
  input BackendDAE.IncidenceMatrixT mT;
  output Boolean include;
algorithm
  include := matchcontinue(var, dlow, mT)
    local
      Expression.ComponentRef cr;
      Integer varIndx;
      list<Integer> eqns;
      
    case(var as BackendDAE.VAR(varName=cr, index=varIndx), dlow, mT)
      equation
        eqns = mT[varIndx + 1];
        true = crefNotInWhenEquation(cr, dlow, eqns);
      then true;
        
    case(_,_,_) then false;
        
  end matchcontinue;
end varNotSolvedInWhen;

protected function createSimWhenClauses
  input BackendDAE.BackendDAE dlow;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimWhenClause> simWhenClauses;
algorithm
  simWhenClauses := match (dlow,helpVarInfo)
    local
      list<BackendDAE.WhenClause> wc;
      
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(whenClauseLst=wc))),helpVarInfo)
      equation
        simWhenClauses = createSimWhenClausesWithEqs(wc, wc, helpVarInfo, dlow, 0);
      then
        simWhenClauses;
  end match;
end createSimWhenClauses;

protected function createSimWhenClausesWithEqs
  input list<BackendDAE.WhenClause> whenClauses;
  input list<BackendDAE.WhenClause> allwhenClauses;
  input list<HelpVarInfo> helpVarInfo;
  input BackendDAE.BackendDAE dlow;
  input Integer currentWhenClauseIndex;
  output list<SimWhenClause> simWhenClauses;
algorithm
  simWhenClauses :=
  match (whenClauses, allwhenClauses, helpVarInfo, dlow, currentWhenClauseIndex)
    local
      BackendDAE.WhenClause whenClause;
      list<BackendDAE.WhenClause> wc,wc1;
      BackendDAE.EquationArray eqs;
      Option<BackendDAE.WhenEquation> whenEq;
      SimWhenClause simWhenClause;
      Integer nextIndex;
      
    case ({}, _, _, _, _) then {};
      
    case (whenClause :: wc, wc1, helpVarInfo, BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedEqs=eqs)::{}), currentWhenClauseIndex)
      equation
        ((whenEq,_)) = BackendEquation.traverseBackendDAEEqnsWithStop(eqs,findWhenEquation,(NONE(),currentWhenClauseIndex));
        simWhenClause = whenClauseToSimWhenClause(whenClause, whenEq, wc1, helpVarInfo, currentWhenClauseIndex);
        nextIndex = currentWhenClauseIndex + 1;
        simWhenClauses = createSimWhenClausesWithEqs(wc, wc1, helpVarInfo, dlow, nextIndex);
      then simWhenClause :: simWhenClauses;
  end match;
end createSimWhenClausesWithEqs;

protected function findWhenEquation
  input tuple<BackendDAE.Equation, tuple<Option<BackendDAE.WhenEquation>,Integer>> inTpl;
  output tuple<BackendDAE.Equation, Boolean, tuple<Option<BackendDAE.WhenEquation>,Integer>> outTpl;
algorithm
  outTpl := matchcontinue (inTpl)
    local
      BackendDAE.WhenEquation eq;
      BackendDAE.Equation eqn;
      tuple<Option<BackendDAE.WhenEquation>,Integer> tplowei,tplowei1;
      Boolean b;
    case ((eqn as BackendDAE.WHEN_EQUATION(whenEquation = eq), tplowei))
      equation
        ((_,b,tplowei1)) = findWhenEquation1((eq,tplowei));
      then ((eqn,b,tplowei1));
    case ((eqn,tplowei)) then ((eqn,true,tplowei));
  end matchcontinue;
end findWhenEquation;

protected function findWhenEquation1
"function: findWhenEquation1
Helper function to findWhenEquation."
  input tuple<BackendDAE.WhenEquation, tuple<Option<BackendDAE.WhenEquation>,Integer>> inTpl;
  output tuple<BackendDAE.WhenEquation, Boolean, tuple<Option<BackendDAE.WhenEquation>,Integer>> outTpl;
algorithm
  outTpl := matchcontinue (inTpl)
    local
      Integer wc_ind,index;
      BackendDAE.WhenEquation weqn,we;
      tuple<Option<BackendDAE.WhenEquation>,Integer> tplowei,tplowei1;
      Boolean b;
    case((weqn as BackendDAE.WHEN_EQ(index = wc_ind),(_,index)))
      equation
        true = intEq(index,wc_ind);
      then
        ((weqn,false,(SOME(weqn),index)));
        
    case((weqn as BackendDAE.WHEN_EQ(index = wc_ind,elsewhenPart = SOME(we)),tplowei))
      equation
        ((weqn,b,tplowei1)) = findWhenEquation1((we,tplowei));
      then
        ((weqn,b,tplowei1));
    case ((weqn,tplowei)) then ((weqn,true,tplowei));
  end matchcontinue;
end findWhenEquation1;

protected function whenClauseToSimWhenClause
  input BackendDAE.WhenClause whenClause;
  input Option<BackendDAE.WhenEquation> whenEq;
  input list<BackendDAE.WhenClause> whenClauses;
  input list<HelpVarInfo> helpVarInfo;
  input Integer CurrentIndex;
  output SimWhenClause simWhenClause;
algorithm
  simWhenClause := match (whenClause, whenEq, whenClauses,helpVarInfo,CurrentIndex)
    local
      DAE.Exp cond;
      list<BackendDAE.WhenClause> wc;
      list<BackendDAE.WhenOperator> reinits;
      list<DAE.ComponentRef> conditionVars;
      list<DAE.Exp> conditions;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
      
    case (BackendDAE.WHEN_CLAUSE(condition=cond, reinitStmtLst=reinits), whenEq, wc, helpVarInfo,CurrentIndex)
      equation
        conditions = getConditionList(wc, CurrentIndex);
        conditionsWithHindex =  Util.listMap2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
        conditionVars = Expression.extractCrefsFromExp(cond);
      then
        SIM_WHEN_CLAUSE(conditionVars, reinits, whenEq, conditionsWithHindex);
  end match;
end whenClauseToSimWhenClause;

public function createEquations
  input Boolean includeWhen;
  input Boolean skipDiscInZc;
  input Boolean genDiscrete;
  input Boolean skipDiscInAlgorithm;
  input Boolean linearSystem "if true generate allway a linear system";
  input BackendDAE.BackendDAE dlow;
  input BackendDAE.StrongComponents comps;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> equations;
algorithm
  equations := matchcontinue (includeWhen, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, linearSystem, dlow, comps, helpVarInfo)
    local
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents restComps;
      Integer index,vindex;
      BackendDAE.Variables vars,vars1;
      BackendDAE.EquationArray eqns,eqns1;
      array<DAE.Algorithm> algs;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      BackendDAE.Var v;
      list<BackendDAE.Equation> eqnlst;
      list<BackendDAE.Var> varlst;
      list<Integer> zcEqns,eqnslst;
      list<SimEqSystem> equations_,equations1;
      list<String> str;
      String s;
      array<Integer> ass1,ass2;
      
      // handle empty
    case (includeWhen, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, linearSystem, dlow, {}, helpVarInfo) then {};
      
      // ignore when equations if we should not generate them
    case (false, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, linearSystem, dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedEqs=eqns)::{}), BackendDAE.SINGLEEQUATION(eqn=index) :: restComps, helpVarInfo)
      equation
        BackendDAE.WHEN_EQUATION(_,_) = BackendDAEUtil.equationNth(eqns, index-1);
        equations = createEquations(false, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, linearSystem, dlow, restComps, helpVarInfo);
      then
        equations;
        
        // ignore discrete if we should not generate them
    case (includeWhen, skipDiscInZc, false, skipDiscInAlgorithm, linearSystem, dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars)::{}), BackendDAE.SINGLEEQUATION(var=index) :: restComps, helpVarInfo)
      equation
        v = BackendVariable.getVarAt(vars,index);
        true = BackendVariable.hasDiscreteVar({v});
        equations = createEquations(includeWhen, skipDiscInZc, false,  skipDiscInAlgorithm, linearSystem, dlow, restComps, helpVarInfo);
      then
        equations;
        
        // ignore discrete in zero crossing if we should not generate them
    case (includeWhen, true, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{}), BackendDAE.SINGLEEQUATION(eqn=index,var=vindex) :: restComps, helpVarInfo)
      equation
        v = BackendVariable.getVarAt(vars,vindex);
        true = BackendVariable.hasDiscreteVar({v});
        zcEqns = BackendDAECreate.zeroCrossingsEquations(dlow);
        true = listMember(index, zcEqns);
        equations = createEquations(includeWhen, true, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, restComps, helpVarInfo);
      then
        equations;
        
        // single equation 
    case (includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, BackendDAE.SINGLEEQUATION(eqn=index,var=vindex) :: restComps, helpVarInfo)
      equation
        equations1 = createEquation(index, vindex, dlow, helpVarInfo, linearSystem, skipDiscInAlgorithm);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, restComps, helpVarInfo);
        equations = listAppend(equations1,equations);
      then
        equations;
       
      // A single array equation
    case (includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{},shared=BackendDAE.SHARED(arrayEqs=ae)), (comp as BackendDAE.SINGLEARRAY(eqns=eqnslst)) :: restComps, helpVarInfo)
      equation
        (eqnlst,varlst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        ae1 = Util.arrayMap(ae,replaceDerOpMultiDimEquations);
        // States are solved for der(x) not x.
        varlst = Util.listMap(varlst, transformXToXd);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqns1 = BackendDAEUtil.listEquation(eqnlst);
        vars1 = BackendDAEUtil.listVar(varlst);        
        equations1 = createSingleArrayEqnCode(genDiscrete,eqns1,ae1,vars1,helpVarInfo,index);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, restComps, helpVarInfo);
        equations = listAppend(equations1,equations);
      then
        equations;
        
        // A single algorithm section for several variables.
    case (includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{},shared=BackendDAE.SHARED(algorithms=algs)), (comp as BackendDAE.SINGLEALGORITHM(eqns=eqnslst)) :: restComps, helpVarInfo)
      equation
        (eqnlst,varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        varlst = Util.listMap(varlst, transformXToXd);
        eqns1 = BackendDAEUtil.listEquation(eqnlst);
        vars1 = BackendDAEUtil.listVar(varlst);
        equations1 = createSingleAlgorithmCode(eqns1,algs,vars1,skipDiscInAlgorithm);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, restComps, helpVarInfo);
        equations = listAppend(equations1,equations);
      then
        equations;      
       
        // a linear system of equations 
    case (includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, comp :: restComps, helpVarInfo)
      equation
        equations_ = createOdeSystem(genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, comp, helpVarInfo);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, dlow, restComps, helpVarInfo);
        equations1 = listAppend(equations_,equations);
      then
        equations1;
       
    // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createEquations failed"});
      then
        fail();
  end matchcontinue;
end createEquations;
/*
protected function addStartValueHomotopy "function: addStartValueHomotopy
  author: lochel
  
  returns /$_lambda * inExp + (1-$_lambda) * startValue/ if possible
"
  input DAE.Exp inExp;
  input Option< .DAE.VariableAttributes> inVarAttr;
  input Boolean includeStartValueHomotopy;
  output DAE.Exp out;
algorithm
  out := matchcontinue(inExp, inVarAttr, includeStartValueHomotopy)
    local
      DAE.Exp lambda, startValue, e1, e2, e3, e4;
      
    case(inExp, SOME( .DAE.VAR_ATTR_REAL(initial_=SOME(startValue))), true) equation
      false = Expression.expContainsAnyIfExp(inExp);
      lambda = DAE.CREF(DAE.CREF_IDENT("$_lambda", DAE.ET_REAL, {}), DAE.ET_REAL);
      e1 = DAE.BINARY(DAE.RCONST(1.0), DAE.SUB(DAE.ET_REAL), lambda);
      e2 = DAE.BINARY(lambda, DAE.MUL(DAE.ET_REAL), inExp);
      e3 = DAE.BINARY(e1, DAE.MUL(DAE.ET_REAL), startValue);
      e4 = DAE.BINARY(e2, DAE.ADD(DAE.ET_REAL), e3);
    then e4;
    
    case(inExp, _, _)
    then inExp;
    
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCode.mo: addStartValueHomotopy failed"});
    then fail();
  end matchcontinue;
end addStartValueHomotopy;

protected function addStartValueHomotopyToOdeSystem 
  "author: lochel"
  input list<BackendDAE.Equation> inEqns;
  input list<BackendDAE.Var> inVars;
  input Boolean includeStartValueHomotopy;
  output list<BackendDAE.Equation> out;
algorithm
  out := matchcontinue(inEqns, inVars, includeStartValueHomotopy)
    local
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      list<BackendDAE.Equation> eqns;
      list<BackendDAE.Var> vars;
      
      Option< .DAE.VariableAttributes> varAttr;
      DAE.Exp exp, lambda, e1, startValue;
      DAE.Exp scalar "scalar" ;
      DAE.ElementSource source "origin of equation";
    
    case({}, {}, _)
    then {};
      
    case(eqn::eqns, (var as BackendDAE.VAR(values=varAttr))::vars, true) equation
      BackendDAE.EQUATION(exp, scalar, source) = eqn;
      // lambda = DAE.CREF(DAE.CREF_IDENT("$_lambda", DAE.ET_REAL, {}), DAE.ET_REAL);
      // e1 = DAE.BINARY(DAE.RCONST(1.0), DAE.SUB(DAE.ET_REAL), lambda);
      // eqn = BackendDAE.EQUATION(DAE.BINARY(DAE.BINARY(lambda, DAE.MUL(DAE.ET_REAL), exp), DAE.ADD(DAE.ET_REAL), DAE.BINARY(e1, DAE.MUL(DAE.ET_REAL), startValue)), DAE.BINARY(lambda, DAE.MUL(DAE.ET_REAL), scalar), source);
      scalar = addStartValueHomotopy(scalar, varAttr, true);
      eqn = BackendDAE.EQUATION(exp, scalar, source);
      eqns = addStartValueHomotopyToOdeSystem(eqns, vars, true);
    then eqn::eqns;
    
    case(eqn::eqns, var::vars, includeStartValueHomotopy) equation
      eqns = addStartValueHomotopyToOdeSystem(eqns, vars, includeStartValueHomotopy);
    then eqn::eqns;
    
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCode.mo: addStartValueHomotopyToOdeSystem failed"});
    then fail();
  end matchcontinue;
end addStartValueHomotopyToOdeSystem;
*/
protected function createEquation
  input Integer eqNum;
  input Integer varNum;
  input BackendDAE.BackendDAE dlow;
  input list<HelpVarInfo> helpVarInfo;
  input Boolean linearSystem "if true generate allway a linear system";
  input Boolean skipDiscInAlgorithm;
  output list<SimEqSystem> equation_;
algorithm
  equation_ := matchcontinue (eqNum, varNum, dlow, helpVarInfo, linearSystem, skipDiscInAlgorithm)
    local
      Expression.ComponentRef cr, cr_1;
      BackendDAE.VarKind kind;
      Option< .DAE.VariableAttributes> values;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      Integer indx, index, wcIndex;
      Algorithm.Algorithm alg;
      array<Algorithm.Algorithm> algs;
      list<DAE.Statement> algStatements;
      list<DAE.Exp> conditions,algInputs;
      array<BackendDAE.MultiDimEquation> ae;
      list<SimEqSystem> resEqs;
      list<BackendDAE.WhenClause> wcl;
      DAE.ComponentRef left,varOutput;
      DAE.Exp e1,e2,varexp,exp_,right;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
      BackendDAE.WhenEquation whenEquation,elseWhen;
      String algStr,message,eqStr;
      DAE.ElementSource source;
      list<DAE.Statement> asserts;
      SimEqSystem elseWhenEquation;
      
      // solve always a linear equations 
    case (eqNum, varNum,
        dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{}),
        helpVarInfo, true, skipDiscInAlgorithm)
      equation
        BackendDAE.EQUATION(e1, e2, source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.VAR(varName = cr, varKind = kind) = BackendVariable.getVarAt(vars,varNum);
        varexp = Expression.crefExp(cr);
        (exp_,asserts) = ExpressionSolve.solveLin(e1, e2, varexp);
        source = DAEUtil.addSymbolicTransformationSolve(true, source, cr, e1, e2, exp_, asserts);
        // TODO: Add SES_ALGORITHM(asserts) here? Why not?
      then
        {SES_SIMPLE_ASSIGN(cr, exp_, source)};
        // non-state non-linear
    case (eqNum, varNum,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::{},shared=BackendDAE.SHARED(arrayEqs=ae,algorithms=algs)),
        helpVarInfo, true, skipDiscInAlgorithm)
      equation
        (eqn as BackendDAE.EQUATION(e1, e2, source)) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        (v as BackendDAE.VAR(varName = cr, varKind = kind)) = BackendVariable.getVarAt(vars,varNum);
        varexp = Expression.crefExp(cr);
        failure((_,_) = solve(e1, e2, varexp));
        eqStr = BackendDump.equationStr(eqn);
        message = ComponentReference.printComponentRefStr(cr);
        Error.addMessage(Error.WARNING_JACOBIAN_EQUATION_SOLVE,{eqStr,message,message});
      then
        {SES_SIMPLE_ASSIGN(cr, DAE.RCONST(0.0) , source)};  
              
        // when eq without else
    case (eqNum, varNum,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{},shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(whenClauseLst=wcl))),
        helpVarInfo, false, skipDiscInAlgorithm)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation,source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.WHEN_EQ(wcIndex, left, right, NONE()) = whenEquation;
        conditions = getConditionList(wcl, wcIndex);
        conditionsWithHindex =  Util.listMap2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        {SES_WHEN(left,right,conditionsWithHindex,NONE(),source)};
        
        // when eq with else
    case (eqNum, varNum,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{}, shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(whenClauseLst=wcl))),
        helpVarInfo, false, skipDiscInAlgorithm)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation,source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.WHEN_EQ(wcIndex, left, right, SOME(elseWhen)) = whenEquation;
        elseWhenEquation = createElseWhenEquation(elseWhen,wcl,helpVarInfo,source);
        conditions = getConditionList(wcl, wcIndex);
        conditionsWithHindex =  Util.listMap2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        {SES_WHEN(left,right,conditionsWithHindex,SOME(elseWhenEquation),source)};
        
        // single equation: non-state
    case (eqNum, varNum,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{}),
        helpVarInfo, false, skipDiscInAlgorithm)
      equation
        BackendDAE.EQUATION(e1, e2, source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        (v as BackendDAE.VAR(varName = cr, varKind = kind, values=values)) = BackendVariable.getVarAt(vars,varNum);
        true = BackendVariable.isNonStateVar(v);
        varexp = Expression.crefExp(cr);
        (exp_,asserts) = solve(e1, e2, varexp);
        source = DAEUtil.addSymbolicTransformationSolve(true, source, cr, e1, e2, exp_, asserts);
      then
        {SES_ALGORITHM(asserts),SES_SIMPLE_ASSIGN(cr, exp_, source)};
        
        // single equation: state
    case (eqNum, varNum,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns)::{}),
        helpVarInfo, false, skipDiscInAlgorithm)
      equation
        BackendDAE.EQUATION(e1, e2, source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.VAR(varName = cr, varKind = BackendDAE.STATE(), values=values) = BackendVariable.getVarAt(vars,varNum);        
        cr = ComponentReference.crefPrefixDer(cr);
        (exp_,asserts) = solve(e1, e2, Expression.crefExp(cr));
        source = DAEUtil.addSymbolicTransformationSolve(true, source, cr, e1, e2, exp_, asserts);
      then
        {SES_ALGORITHM(asserts),SES_SIMPLE_ASSIGN(cr, exp_, source)};
        
        // non-state non-linear
    case (eqNum, varNum,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::{},shared=BackendDAE.SHARED(arrayEqs=ae,algorithms=algs)),
        helpVarInfo, false, skipDiscInAlgorithm)
      equation
        (eqn as BackendDAE.EQUATION(e1, e2, source)) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        (v as BackendDAE.VAR(varName = cr, varKind = kind)) = BackendVariable.getVarAt(vars,varNum);
        true = BackendVariable.isNonStateVar(v);
        varexp = Expression.crefExp(cr);
        failure((_,_) = solve(e1, e2, varexp));
        //index = tick();
        index = eqNum; // Use the equation number as unique index
        (resEqs,_) = createNonlinearResidualEquations({eqn}, ae, algs, {});
      then
        {SES_NONLINEAR(index, resEqs, {cr})};
        
        // state nonlinear
    case (eqNum, varNum,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::{},shared=BackendDAE.SHARED(arrayEqs=ae,algorithms=algs)),
        helpVarInfo, false, skipDiscInAlgorithm)
      equation
        (eqn as BackendDAE.EQUATION(e1, e2, source)) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.VAR(varName = cr, varKind = BackendDAE.STATE()) = BackendVariable.getVarAt(vars,varNum); 
        cr_1 = ComponentReference.crefPrefixDer(cr);
        varexp = Expression.crefExp(cr_1);
        failure((_,_) = solve(e1, e2, varexp));
        // index = tick();
        index = eqNum; // Use the equation number as unique index
        (resEqs,_) = createNonlinearResidualEquations({eqn}, ae, algs, {});
      then
        {SES_NONLINEAR(index, resEqs, {cr_1})};
        
        // Algorithm for single variable.
    case (eqNum, varNum, BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::{},shared=BackendDAE.SHARED(algorithms=algs)), helpVarInfo, false, true)
      equation
        BackendDAE.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source)  = BackendDAEUtil.equationNth(eqns, eqNum-1);
        v = BackendVariable.getVarAt(vars,varNum); 
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        true = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        alg = algs[indx + 1];
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
        algStatements = BackendDAEUtil.removediscreteAssingments(algStatements, vars);
      then
        {SES_ALGORITHM(algStatements)};
        
        // Algorithm for single variable.
    case (eqNum, varNum, BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::{},shared=BackendDAE.SHARED(algorithms=algs)), helpVarInfo, false, false)
      equation
        BackendDAE.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        v = BackendVariable.getVarAt(vars,varNum); 
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        true = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        alg = algs[indx + 1];
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      then
        {SES_ALGORITHM(algStatements)};
        
        // inverse Algorithm for single variable.
    case (eqNum, varNum, BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns)::{},shared=BackendDAE.SHARED(algorithms=algs)), helpVarInfo, false, skipDiscInAlgorithm)
      equation
        BackendDAE.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        v = BackendVariable.getVarAt(vars,varNum);
        // We need to solve an inverse problem of an algorithm section.
        false = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        alg = algs[indx + 1];
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();
        // Algorithm for single variable.
    case (eqNum, varNum, BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::{},shared=BackendDAE.SHARED(algorithms=algs)), helpVarInfo, true, false)
      equation
        BackendDAE.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        v = BackendVariable.getVarAt(vars,varNum);
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        true = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        alg = algs[indx + 1];
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      then
        {SES_ALGORITHM(algStatements)};
        
        // inverse Algorithm for single variable.
    case (eqNum, varNum, BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns)::{},shared=BackendDAE.SHARED(algorithms=algs)), helpVarInfo, true, skipDiscInAlgorithm)
      equation
        BackendDAE.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        v = BackendVariable.getVarAt(vars,varNum);
        // We need to solve an inverse problem of an algorithm section.
        false = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        alg = algs[indx + 1];
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();
  end matchcontinue;
end createEquation;

protected function createElseWhenEquation
  input BackendDAE.WhenEquation elseWhen;
  input list<BackendDAE.WhenClause> wcl;
  input list<HelpVarInfo> helpVarInfo;
  input DAE.ElementSource source;
  output SimEqSystem equation_;
algorithm
  equation_ :=
  match (elseWhen, wcl, helpVarInfo, source)
    local
      Integer wcIndex;
      DAE.ComponentRef left;
      DAE.Exp  right;
      BackendDAE.WhenEquation elseWhenEquation;
      SimEqSystem simElseWhenEq;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
      list<DAE.Exp> conditions;
      // when eq without else
    case (elseWhen as BackendDAE.WHEN_EQ(index=wcIndex, left=left, right=right, elsewhenPart= NONE()), wcl, helpVarInfo, source)
      equation
        conditions = getConditionList(wcl, wcIndex);
        conditionsWithHindex = Util.listMap2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        SES_WHEN(left, right, conditionsWithHindex, NONE(), source);
        
        // when eq with else
    case (elseWhen as BackendDAE.WHEN_EQ(index=wcIndex, left=left,right=right, elsewhenPart = SOME(elseWhenEquation)), wcl, helpVarInfo, source)
      equation
        simElseWhenEq = createElseWhenEquation(elseWhenEquation,wcl,helpVarInfo,source);
        conditions = getConditionList(wcl, wcIndex);
        conditionsWithHindex = Util.listMap2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        SES_WHEN(left,right,conditionsWithHindex,SOME(simElseWhenEq),source);
  end match;
end createElseWhenEquation;

protected function createSampleEquations
" function: createSampleEquations
author: wbraun
Create SimCodeEqns from Backend Equation list.
used for create Sample equations."
  input list<BackendDAE.Equation> inEqns;
  output list<SimEqSystem> outEqns;
algorithm
  outEqns := matchcontinue (inEqns)
    local
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqns;
      list<SimEqSystem> simeqns;
      String eqstr;
      DAE.Exp e2;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
    case ({}) then {};
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr, exp = e2, source = source)::eqns)
      equation
        simeqns = createSampleEquations(eqns);
      then
        (SES_SIMPLE_ASSIGN(cr, e2, source)::simeqns);
    case(BackendDAE.EQUATION(exp = DAE.CREF(componentRef = cr), scalar = e2, source = source)::eqns)
      equation
        simeqns = createSampleEquations(eqns);
      then
        (SES_SIMPLE_ASSIGN(cr, e2, source)::simeqns);
    case (eq::eqns)
      equation
        eqstr = BackendDump.equationStr(eq);
        Error.addCompilerWarning("sample call in equation: " +& eqstr +& "not supported, yet!");
        simeqns = createSampleEquations(eqns);
      then (simeqns);
  end matchcontinue;
end createSampleEquations;

protected function addHindexForCondition
  input DAE.Exp condition;
  input list<HelpVarInfo> helpVarInfo;
  output tuple<DAE.Exp, Integer> conditionAndHindex;
algorithm
  conditionAndHindex :=
  matchcontinue (condition, helpVarInfo)
    local
      Integer hindex;
      DAE.Exp e;
      list<HelpVarInfo> restHelpVarInfo;
    case (condition, (hindex, e, _) :: restHelpVarInfo)
      equation
        true = Expression.expEqual(condition, e);
      then ((condition, hindex));
    case (condition, (hindex, e, _) :: restHelpVarInfo)
      equation
        false = Expression.expEqual(condition, e);
        conditionAndHindex = addHindexForCondition(condition, restHelpVarInfo);
      then conditionAndHindex;
  end matchcontinue;
end addHindexForCondition;

protected function addHelpForCondition
  input DAE.Exp condition;
  input list<HelpVarInfo> helpVarInfo;
  input list<HelpVarInfo> helpVarInfo1;
  output tuple<DAE.Exp, Integer> conditionAndHindex;
algorithm
  conditionAndHindex :=
  matchcontinue (condition, helpVarInfo, helpVarInfo1)
    local
      Integer hindex;
      DAE.Exp e;
      list<HelpVarInfo> restHelpVarInfo;
      Absyn.Path name;
      list<DAE.Exp> args_;
      Boolean tup,builtin_;
      DAE.ExpType exty;
      DAE.InlineType inty;
      DAE.Exp condition1;
      DAE.CallAttributes attr;
    case (_, {},_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Could not find help var index for condition"});
      then fail();
    case (condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr), (hindex, e, _) :: restHelpVarInfo, helpVarInfo1)
      equation
        args_ = listAppend(args_,{DAE.ICONST(hindex)});
        condition1 = DAE.CALL(name, args_, attr);
        true = Expression.expEqual(condition1, e);
        //s1 = ExpressionDump.printExpStr(condition1);
        //s2 = ExpressionDump.printExpStr(e);
        //print("Added Hindex for \n ** Condition: " +& s1 +& "  HelpVar exp: " +& s2 +& " with index : " +& intString(hindex) +&  "\n");
      then ((condition1, hindex));
    case (condition, (hindex, e, _) :: restHelpVarInfo, helpVarInfo1)
      equation
        ((condition,_)) = Expression.traverseExp(condition, addHForSample, helpVarInfo1);
        true = Expression.expEqual(condition, e);
        //s1 = ExpressionDump.printExpStr(condition);
        //s2 = ExpressionDump.printExpStr(e);
        //print("Added Hindex for \n ** Condition: " +& s1 +& "  HelpVar exp: " +& s2 +& " with index : " +& intString(hindex) +& "\n");
      then ((condition, hindex));
    case (condition, (hindex, e, _) :: restHelpVarInfo, helpVarInfo1)
      equation
        ((condition,_)) = Expression.traverseExp(condition, addHForSample, helpVarInfo1);
        false = Expression.expEqual(condition, e);
        //s1 = ExpressionDump.printExpStr(condition);
        //s2 = ExpressionDump.printExpStr(e);
        //print("NOT Added Hindex for \n ** Condition: " +& s1 +& "  HelpVar exp: " +& s2 +& " with index : " +& intString(hindex) +& "\n");
        conditionAndHindex = addHelpForCondition(condition, restHelpVarInfo, helpVarInfo1);
      then conditionAndHindex;
  end matchcontinue;
end addHelpForCondition;

protected function addHForSample
    input tuple<DAE.Exp, list<HelpVarInfo>> inTplExp;
    output tuple<DAE.Exp, list<HelpVarInfo>> outTplExp;
algorithm 
 outTplExp := matchcontinue(inTplExp)
   local
   DAE.Exp condition;
   list<HelpVarInfo> helpvars;
   String s1;
  case ((condition, helpvars))
    equation
      s1 = ExpressionDump.printExpStr(condition);
      //print("### start match for condition: " +& s1 +& "\n");
      condition = matchwithHelpVars(condition,helpvars);
    then ((condition,helpvars));
  case ((condition, helpvars)) then ((condition,helpvars));
 end matchcontinue;
end addHForSample;

protected function matchwithHelpVars
    input DAE.Exp inCondition;
    input list<HelpVarInfo> inHelpVars;
    output DAE.Exp outCondition;
algorithm 
 outCondition := matchcontinue(inCondition,inHelpVars)
   local
   DAE.Exp condition,condition1;
   Integer hindex;
   DAE.Exp e;
   list<HelpVarInfo> restHelpVarInfo;
   Absyn.Path name;
   list<DAE.Exp> args_;
   Boolean tup,builtin_;
   DAE.ExpType exty;
   DAE.InlineType inty;
   DAE.CallAttributes attr;
  case(condition, {}) then condition;
  case (condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr), (hindex, e, _) :: restHelpVarInfo)
      equation
        args_ = listAppend(args_,{DAE.ICONST(hindex)});
        condition1 = DAE.CALL(name, args_, attr);
        true = Expression.expEqual(condition1, e);
        //s1 = ExpressionDump.printExpStr(condition1);
        //s2 = ExpressionDump.printExpStr(e);
        //print("** matchwithHelpVar TRUE CASE** :\n Condition: " +& s1 +& " --  HelpVar Exp: " +& s2 +& "\n");
      then condition1;
    case (condition, (hindex, e, _) :: restHelpVarInfo)
      equation
        false = Expression.expEqual(condition, e);
        //s1 = ExpressionDump.printExpStr(condition);
        //s2 = ExpressionDump.printExpStr(e);
        //print("** matchwithHelpVar FALSE CASE** :\n Condition: " +& s1 +& " --  HelpVar Exp: " +& s2 +& "\n");
        condition = matchwithHelpVars(condition, restHelpVarInfo);
      then condition;
 end matchcontinue;
end matchwithHelpVars;


protected function createNonlinearResidualEquations
  input list<BackendDAE.Equation> eqs;
  input array<BackendDAE.MultiDimEquation> arrayEqs;
  input array< .DAE.Algorithm> algs;
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output list<SimEqSystem> eqSystems;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (eqSystems,outEntrylst) :=
  matchcontinue (eqs, arrayEqs, algs, inEntrylst)
    local
      Integer indx,aindx;
      DAE.ExpType tp;
      DAE.Exp res_exp,e1,e2,e;
      list<DAE.Exp> explst;
      list<BackendDAE.Equation> rest;
      array<BackendDAE.MultiDimEquation> aeqns;
      BackendDAE.Equation eq;
      list<SimEqSystem> eqSystemsRest,eqSystlst;
      list<Integer> ds;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1,entrylst2;
      DAE.ComponentRef left;
      String eqstr;
      DAE.Algorithm alg;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
      
    case ({}, _, _, inEntrylst) then ({},inEntrylst);
      
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2,source=source) :: rest), aeqns, algs, inEntrylst)
      equation
        tp = Expression.typeof(e1);
        res_exp = Expression.expSub(e1,e2);
        (res_exp,_) = ExpressionSimplify.simplify(res_exp);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,entrylst1) = createNonlinearResidualEquations(rest, aeqns, algs, inEntrylst);
      then
        (SES_RESIDUAL(res_exp,source) :: eqSystemsRest,entrylst1);
        
    case ((BackendDAE.RESIDUAL_EQUATION(exp = e,source = source) :: rest), aeqns, algs, inEntrylst)
      equation
        (res_exp,_) = ExpressionSimplify.simplify(e);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,entrylst1) = createNonlinearResidualEquations(rest, aeqns, algs, inEntrylst);
      then
        (SES_RESIDUAL(res_exp,source) :: eqSystemsRest,entrylst1);
        
        // An array equation
    case ((BackendDAE.ARRAY_EQUATION(index=aindx) :: rest), aeqns, algs, inEntrylst)
      equation
        BackendDAE.MULTIDIM_EQUATION(dimSize=ds,left=e1, right=e2, source=source) = aeqns[aindx+1];
        tp = Expression.typeof(e1);
        res_exp = Expression.expSub(e1,e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = BackendDAEUtil.getArrayEquationSub(aindx,ad,inEntrylst);
        res_exp = Expression.applyExpSubscripts(res_exp,subs);
        (res_exp,_) = ExpressionSimplify.simplify(res_exp);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,entrylst2) = createNonlinearResidualEquations(rest, aeqns, algs, entrylst1);
      then 
        (SES_RESIDUAL(res_exp,source) :: eqSystemsRest,entrylst2);
        
    case ((eq as BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = left, right = e2)))::rest,aeqns,algs,inEntrylst)
      equation
        // This following does not work. It does not take index or elseWhen into account.
        // The generated code for the when-equation also does not solve a linear system; it uses the variables directly.
        /*
         tp = Expression.typeof(e2);
         e1 = Expression.makeCrefExp(left,tp);
         res_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
         res_exp = ExpressionSimplify.simplify(res_exp);
         res_exp = replaceDerOpInExp(res_exp);
         (eqSystemsRest,entrylst1) = createNonlinearResidualEquations(rest, aeqns, algs, inEntrylst);
         then
         (SES_RESIDUAL(res_exp) :: eqSystemsRest,entrylst1);
         */
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"non-linear equations within when-equations","Perform non-linear operations outside the when-equation (this is slower, but works)"},BackendEquation.equationInfo(eq));
      then
        fail();
        
    case ((BackendDAE.ALGORITHM(index = indx,out=explst,source=source) :: rest), aeqns, algs, inEntrylst)
      equation
        alg = algs[indx + 1];
        explst = Util.listMap(explst,replaceDerOpInExp);
        eqSystlst = Util.listMap1(explst,makeSES_RESIDUAL,source);
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg,NONE());
        (eqSystemsRest,entrylst1) = createNonlinearResidualEquations(rest, aeqns, algs, inEntrylst);
        eqSystemsRest = listAppend(eqSystlst,eqSystemsRest);
      then
        (SES_ALGORITHM(algStatements)::eqSystemsRest,entrylst1);
        
    case (eq::_,_,_,_)
      equation
        eqstr = BackendDump.equationStr(eq);
        eqstr = stringAppend("SimCode.createNonlinearResidualEquations failed for equation: ",eqstr);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {eqstr},BackendEquation.equationInfo(eq));
      then
        fail();
  end matchcontinue;
end createNonlinearResidualEquations;

protected function makeSES_RESIDUAL
  input DAE.Exp inExp;
  input DAE.ElementSource source;
  output SimEqSystem outSimEqn;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outSimEqn := SES_RESIDUAL(inExp,source);
end makeSES_RESIDUAL;

protected function applyResidualReplacements
  "Replaces variables in nonlinear equation systems with xloc[index] variables."
  input SimEqSystem inEqs;
  output SimEqSystem outEqs;
algorithm
  outEqs := match inEqs
    local
      SimEqSystem eq,cont;
      list<SimEqSystem> rest_eqs,eqs,discEqs;
      Integer index;
      list<DAE.ComponentRef> crefs;
      VarTransform.VariableReplacements repl;
      list<SimVar> discVars;
      list<Integer> values,value_dims;
      
    case SES_NONLINEAR(index = index, eqs = eqs, crefs = crefs)
      equation
        repl = makeResidualReplacements(crefs);
        eqs = Util.listMap1(eqs, applyResidualReplacementsEqn, repl);
      then
        SES_NONLINEAR(index, eqs, crefs);
        
    case SES_MIXED(index,cont,discVars,discEqs,values,value_dims)
      equation
        cont = applyResidualReplacements(cont);
      then SES_MIXED(index,cont,discVars,discEqs,values,value_dims);

    else inEqs;
  end match;
end applyResidualReplacements;

protected function applyResidualReplacementsEqn
  "Helper function to applyResidualReplacements. Replaces variables in an
    residual equation system."
  input SimEqSystem inEqn;
  input VarTransform.VariableReplacements repl;
  output SimEqSystem outEqn;
algorithm
  outEqn := matchcontinue(inEqn, repl)
    local
      DAE.Exp res_exp,exp;
      DAE.ElementSource source;
      
    case (SES_RESIDUAL(exp,source), _)
      equation
        (res_exp,true) = VarTransform.replaceExp(exp, repl, SOME(skipPreOperator));
        source = DAEUtil.addSymbolicTransformationSubstitution(true,source,exp,res_exp);
      then
        SES_RESIDUAL(res_exp,source);
    else inEqn;
  end matchcontinue;
end applyResidualReplacementsEqn;

protected function changeJactype
  input BackendDAE.JacobianType inJactype;
  output BackendDAE.JacobianType outJactype;
algorithm 
  outJactype := match(inJactype)
    local
      BackendDAE.JacobianType jacType;
    case (jacType as BackendDAE.JAC_NONLINEAR()) then BackendDAE.JAC_TIME_VARYING();
    case (jacType) then jacType;
  end match;
end changeJactype;

protected function createOdeSystem
  input Boolean genDiscrete "if true generate discrete equations";
  input Boolean skipDiscInAlgorithm "if true skip discrete algorithm vars";
  input Boolean linearSystem "if true generate allway a linear system";
  input BackendDAE.BackendDAE inBackendDAE1;
  input BackendDAE.StrongComponent inComp;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> equations_;
algorithm
  equations_ :=
  matchcontinue(genDiscrete, skipDiscInAlgorithm, linearSystem, inBackendDAE1, inComp, helpVarInfo)
    local
      list<BackendDAE.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<BackendDAE.Var> var_lst,cont_var,disc_var,var_lst_1,cont_var1;
      BackendDAE.Variables vars_1,vars,knvars,exvars,knvars_1;
      BackendDAE.AliasVariables av,ave;
      BackendDAE.EquationArray eqns_1,eqns,se,ie,eeqns,eieqns;
      BackendDAE.BackendDAE cont_subsystem_dae,daelow,subsystem_dae;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<Algorithm.Algorithm> al;
      BackendDAE.EventInfo ev;
      array<Integer> ass1,ass2;
      list<Integer> ieqns,ivars,disc_eqns,disc_vars;
      BackendDAE.ExternalObjectClasses eoc;
      list<SimVar> simVarsDisc;
      list<SimEqSystem> discEqs;
      list<Integer> values;
      list<Integer> value_dims;
      SimEqSystem equation_;
      BackendDAE.BackendDAE subsystem_dae_1,subsystem_dae_2;
      array<Integer> v1,v2,v1_1,v2_1;
      BackendDAE.IncidenceMatrix m_2,m_3,m;
      BackendDAE.IncidenceMatrixT mT_2,mT_3,mt;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp,comp1;
      list<Integer> comps_flat;
      list<list<Integer>> r,t,comps_1;
      list<Integer> rf,tf;
      Integer index;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
      // create always a linear system of equations 
    case (genDiscrete,skipDiscInAlgorithm,true,(daelow as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns)::{},BackendDAE.SHARED(knownVars = knvars,arrayEqs = ae,algorithms = al))),comp as BackendDAE.EQUATIONSYSTEM(eqns=ieqns,vars=ivars,jac=jac,jacType=jac_tp),helpVarInfo)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem create system (create linear jacobian).");
        //print("\ncreateOdeSystem -> Linear: ...\n");
        //BackendDump.printEquations(block_,daelow);
        // extract the variables and equations of the block.
        eqn_lst = BackendEquation.getEqns(ieqns,eqns);
        var_lst = Util.listMap1r(ivars, BackendVariable.getVarAt, vars);
        index = Util.listFirst(ieqns);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        ae1 = Util.arrayMap(ae,replaceDerOpMultiDimEquations);
        // States are solved for der(x) not x.
        var_lst_1 = Util.listMap(var_lst, transformXToXd);
        vars_1 = BackendDAEUtil.listVar(var_lst_1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        knvars_1 = BackendEquation.equationsVars(eqns_1,knvars);
        // if BackendDAEUtil.JAC_NONLINEAR() then set to time_varying
        jac_tp = changeJactype(jac_tp);
        equations_ = createOdeSystem2(false, genDiscrete, skipDiscInAlgorithm, vars_1,knvars_1,eqns_1,ae1,al,jac, jac_tp, helpVarInfo,index);
      then
        equations_;
    case (genDiscrete,skipDiscInAlgorithm,true,(daelow as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns)::{},BackendDAE.SHARED(knownVars = knvars, externalObjects = exvars, arrayEqs = ae,algorithms = al, eventInfo = ev, extObjClasses = eoc))),comp as BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns=disc_eqns,disc_vars=disc_vars),helpVarInfo)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem create mixed system (create linear jacobian).");
        //print("\ncreateOdeSystem -> Linear: ...\n");
        //BackendDump.printEquations(block_,daelow);
        // extract the variables and equations of the block.
        (eqn_lst,var_lst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        ae1 = Util.arrayMap(ae,replaceDerOpMultiDimEquations);
        var_lst_1 = Util.listMap(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = BackendDAEUtil.listVar(var_lst_1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        ave = BackendDAEUtil.emptyAliasVariables();
        eeqns = BackendDAEUtil.listEquation({});
        knvars_1 = BackendEquation.equationsVars(eqns_1,knvars);
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(knvars_1,exvars,ave,eeqns,eeqns,ae1,al,ev,eoc,BackendDAE.ALGEQSYSTEM());
        (m,mt) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.ABSOLUTE());
        subsystem_dae = BackendDAE.DAE({syst},shared);
        jac = BackendDAEUtil.calculateJacobian(vars_1, eqns_1, ae1, m, mt,false) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = BackendDAEUtil.analyzeJacobian(subsystem_dae, jac);
        // if BackendDAEUtil.JAC_NONLINEAR() then set to time_varying
        jac_tp = changeJactype(jac_tp);
        equations_ = createOdeSystem2(false, genDiscrete, skipDiscInAlgorithm, vars_1,knvars_1,eqns_1,ae1,al,jac, jac_tp, helpVarInfo,index);
      then
        equations_;
          
        // mixed system of equations, continuous part only
    case (false, skipDiscInAlgorithm, false,daelow,BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1),helpVarInfo)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem create mixed system continuous part.");
        equations_ = createEquations(true,false,false,skipDiscInAlgorithm,false,daelow,{comp1},helpVarInfo);
      then
        equations_;
        
        // mixed system of equations, both continous and discrete eqns
    case (true, skipDiscInAlgorithm, false,(daelow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns)::{},shared=BackendDAE.SHARED(knownVars=knvars))),BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1,disc_eqns=ieqns,disc_vars=ivars),helpVarInfo)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem create mixed system.");
        //print("\ncreateOdeSystem -> Mixed: cont. and discrete\n");
        //BackendDump.printEquations(block_,dlow);
        disc_eqn = BackendEquation.getEqns(ieqns,eqns); 
        disc_var = Util.listMap1r(ivars, BackendVariable.getVarAt, vars);
        {equation_} = createEquations(true,false,false,skipDiscInAlgorithm,false,daelow,{comp1},helpVarInfo);  
        simVarsDisc = Util.listMap2(disc_var, dlowvarToSimvar,NONE(),knvars);
        discEqs = extractDiscEqs(disc_eqn, disc_var);
        // adrpo: TODO! FIXME! THIS FUNCTION is madness!
        //        for 34 discrete values you need a list of 34 about 4926277576697053184 times!!!
        (ieqns,ivars) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp1);
        cont_eqn = BackendEquation.getEqns(ieqns,eqns);
        cont_var = Util.listMap1r(ivars, BackendVariable.getVarAt, vars);
        (values, value_dims) = extractValuesAndDims(cont_eqn, cont_var, disc_eqn, disc_var); // ({1,0},{2});
        index = Util.listFirst(ieqns);
        //(values, value_dims) = ({1,0},{2});
      then
        {SES_MIXED(index, equation_, simVarsDisc, discEqs, values, value_dims)};
        
        // continuous system of equations try tearing algorithm
    case (genDiscrete, skipDiscInAlgorithm, false,(daelow as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns)::{},BackendDAE.SHARED(knownVars = knvars, externalObjects = exvars, arrayEqs = ae,algorithms = al, eventInfo = ev, extObjClasses = eoc))),comp,helpVarInfo)
      equation
        //print("\ncreateOdeSystem -> Tearing: ...\n");
        // check tearing
        true = RTOpts.debugFlag("tearing");
        (eqn_lst,var_lst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        ae1 = Util.arrayMap(ae,replaceDerOpMultiDimEquations);
        var_lst_1 = Util.listMap(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = BackendDAEUtil.listVar(var_lst_1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        ave = BackendDAEUtil.emptyAliasVariables();
        eeqns = BackendDAEUtil.listEquation({});
        knvars_1 = BackendEquation.equationsVars(eqns_1,knvars);
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(knvars_1,exvars,ave,eeqns,eeqns,ae1,al,ev,eoc,BackendDAE.ALGEQSYSTEM());
        (m,mt) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.ABSOLUTE());
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,SOME(m),SOME(mt),BackendDAE.NO_MATCHING());
        subsystem_dae = BackendDAE.DAE({syst},shared);
        (subsystem_dae_1 as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(v1,v2,comps))})) = BackendDAEUtil.transformBackendDAE(subsystem_dae,DAEUtil.avlTreeNew(),SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE());
        (subsystem_dae_2 as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(m=SOME(m_3),mT=SOME(mT_3))}),v1_1,v2_1,comps_1,r,t) = BackendDAEOptimize.tearingSystem(subsystem_dae_1,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);
        jac = BackendDAEUtil.calculateJacobian(vars_1, eqns_1, ae1, m_3, mT_3,false) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = BackendDAEUtil.analyzeJacobian(subsystem_dae, jac);
        equation_ = generateTearingSystem(v1_1,v2_1,comps_flat,rf,tf,false,genDiscrete,subsystem_dae_2, jac, jac_tp, helpVarInfo);
      then
        {equation_};
        /* continuous system of equations */
    case (genDiscrete, skipDiscInAlgorithm, false,(daelow as BackendDAE.DAE(BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns)::{},BackendDAE.SHARED(knownVars = knvars, externalObjects = exvars, arrayEqs = ae,algorithms = al, eventInfo = ev, extObjClasses = eoc))),comp as BackendDAE.EQUATIONSYSTEM(jac=jac,jacType=jac_tp),helpVarInfo)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem create continuous system.");
        //print("\ncreateOdeSystem -> Cont sys: ...\n");
        // extract the variables and equations of the block.
        (eqn_lst,var_lst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        //BackendDump.dumpEqns(eqn_lst);
        //BackendDump.dumpVars(var_lst);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        ae1 = Util.arrayMap(ae,replaceDerOpMultiDimEquations);
        // States are solved for der(x) not x.
        var_lst_1 = Util.listMap(var_lst, transformXToXd);
        vars_1 = BackendDAEUtil.listVar(var_lst_1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        knvars_1 = BackendEquation.equationsVars(eqns_1,knvars);
        equations_ = createOdeSystem2(false, genDiscrete, skipDiscInAlgorithm, vars_1,knvars_1,eqns_1,ae1,al, jac, jac_tp, helpVarInfo,index);
      then
        equations_;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createOdeSystem failed"});
      then
        fail();
  end matchcontinue;
end createOdeSystem;

protected function generateTearingSystem "function: generateTearingSystem
  author: Frenkel TUD

  Generates the actual simulation code for the teared system of equation
"
  input array<Integer> inIntegerArray2;
  input array<Integer> inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input list<Integer> inIntegerLst5;
  input list<Integer> inIntegerLst6;
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input BackendDAE.BackendDAE inBackendDAE;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerBackendDAEEquationLstOption;
  input BackendDAE.JacobianType inJacobianType;
  input list<HelpVarInfo> helpVarInfo;
  output SimEqSystem equation_;
algorithm
  equation_:=
  matchcontinue (inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,mixedEvent,genDiscrete,inBackendDAE,inTplIntegerIntegerBackendDAEEquationLstOption,inJacobianType,helpVarInfo)
    local
      array<Integer> ass1,ass2;
      list<Integer> block_,block_1,r,t;
      Integer index;
      BackendDAE.BackendDAE daelow,daelow1;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      BackendDAE.Variables v,kv,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqn,eqn1,reeqn,ineq;
      list<BackendDAE.Equation> eqn_lst,eqn_lst1,eqn_lst2,reqns;
      list<DAE.ComponentRef> crefs,crefs1,tcrs;
      array<BackendDAE.MultiDimEquation> ae;
      VarTransform.VariableReplacements repl;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      list<SimEqSystem> simeqnsystem,simeqnsystem1,resEqs;
      list<list<SimEqSystem>> simeqnsystemlst;
      BackendDAE.Shared shared;
    case (ass1,ass2,block_,r,t,mixedEvent,_,
        daelow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=eqn)::{},shared=shared as BackendDAE.SHARED(arrayEqs=ae,initialEqs=ineq,algorithms=algorithms)),jac,jac_tp,helpVarInfo)
      /* no analythic jacobian available. Generate non-linear system */
      equation
        // get equations and variables
        eqn_lst = BackendDAEUtil.equationList(eqn);
        // get names from variables
        crefs = BackendVariable.getAllCrefFromVariables(v);
        // get Tearingvar from crs
        // to use listNth cref and eqn_lst have to start at 1 and not at 0 -> right shift
        crefs1 = Util.listAddElementFirst(ComponentReference.makeCrefIdent("shift",DAE.ET_REAL(),{}),crefs);
        eqn_lst1 = Util.listAddElementFirst(BackendDAE.EQUATION(DAE.RCONST(0.0),DAE.RCONST(0.0),DAE.emptyElementSource),eqn_lst);
        tcrs = Util.listMap1r(t,listNth,crefs1);
        repl = makeResidualReplacements(tcrs);
        // get residual eqns and other eqns
        reqns = Util.listMap1r(r,listNth,eqn_lst1);
        // remove residual equation from list of other equtions
        block_1 = Util.listSelect1(block_,r,Util.notListMember);
        // replace tearing variables in other equations with x_loc[..]
        eqn_lst2 = generateTearingSystem1(eqn_lst,repl);
        eqn1 = BackendDAEUtil.listEquation(eqn_lst2);
        daelow1=BackendDAE.DAE(BackendDAE.EQSYSTEM(v,eqn1,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        // generade code for other equations
        simeqnsystemlst = Util.listMap3(block_1,generateTearingOtherEqns,daelow1, ass2, helpVarInfo);
        simeqnsystem = Util.listFlatten(simeqnsystemlst);
        (resEqs,_) = createNonlinearResidualEquations(reqns, ae, algorithms, {});
        index = Util.listFirst(block_); // use first equation nr as index
        simeqnsystem1 = listAppend(simeqnsystem,resEqs);
      then
        SES_NONLINEAR(index, simeqnsystem1, tcrs);
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generateTearingSystem failed \n");
      then
        fail();
  end matchcontinue;
end generateTearingSystem;

protected function generateTearingOtherEqns
  input Integer inEq;
  input BackendDAE.BackendDAE inBackendDAE;
  input array<Integer> inAss2;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> simeqnsystem;
protected 
  Integer i;  
algorithm
  i := inAss2[inEq];
  simeqnsystem := createEquation(inEq, i, inBackendDAE, helpVarInfo, true, false);
end generateTearingOtherEqns;

protected function generateTearingSystem1
  "function: generateTearingSystem1
  author: Frenkel TUD
  Helper function to generateTearingSystem1"
  input list<BackendDAE.Equation> inBackendDAEEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<BackendDAE.Equation> outBackendDAEEquationLst;
algorithm
  outBackendDAEEquationLst := match (inBackendDAEEquationLst,inVariableReplacements)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      list<BackendDAE.Equation> rest,rest2;
      VarTransform.VariableReplacements repl;
      DAE.ElementSource source;
      Boolean b1,b2;
    case ({},_) then {};
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2,source = source) :: rest),repl)
      equation
        rest2 = generateTearingSystem1(rest,repl);
        (e1_1,b1) = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
        (e2_1,b2) = VarTransform.replaceExp(e2, repl, SOME(skipPreOperator));
        source = DAEUtil.addSymbolicTransformationSubstitution(b1,source,e1,e1_1);
        source = DAEUtil.addSymbolicTransformationSubstitution(b2,source,e2,e2_1);
      then
        BackendDAE.EQUATION(e1_1,e2_1,source) :: rest2;
    case ((BackendDAE.RESIDUAL_EQUATION(exp = e1,source = source) :: rest),repl)
      equation
        rest2 = generateTearingSystem1(rest,repl);
        (e1_1,b1) = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
        source = DAEUtil.addSymbolicTransformationSubstitution(b1,source,e1,e1_1);
      then
        BackendDAE.RESIDUAL_EQUATION(e1_1,source) :: rest2;
  end match;
end generateTearingSystem1;

protected function extractDiscEqs
  input list<BackendDAE.Equation> disc_eqn;
  input list<BackendDAE.Var> disc_var;
  output list<SimEqSystem> discEqsOut;
algorithm
  discEqsOut :=
  match (disc_eqn, disc_var)
    local
      list<SimEqSystem> restEqs;
      DAE.ComponentRef cr;
      DAE.Exp varexp,expr,e1,e2;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
      DAE.ElementSource source;
    case ({},_) then {};
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2,source = source) :: eqns),(v :: vs))
      equation
        cr = BackendVariable.varCref(v);
        varexp = Expression.crefExp(cr);
        (expr,_) = solve(e1, e2, varexp);
        restEqs = extractDiscEqs(eqns, vs);
      then
        SES_SIMPLE_ASSIGN(cr, expr, source) :: restEqs;
  end match;
end extractDiscEqs;

protected function extractValuesAndDims
  input list<BackendDAE.Equation> inBackendDAEEquationLst1;
  input list<BackendDAE.Var> inBackendDAEVarLst2;
  input list<BackendDAE.Equation> inBackendDAEEquationLst3;
  input list<BackendDAE.Var> inBackendDAEVarLst4;
  output list<Integer> valuesRet;
  output list<Integer> value_dims;
algorithm
  (valuesRet, value_dims) :=
  match (inBackendDAEEquationLst1,inBackendDAEVarLst2,inBackendDAEEquationLst3,inBackendDAEVarLst4)
    local
      list<DAE.Exp> rels;
      list<list<Integer>> values,values_1;
      list<Integer> values_2;
      list<BackendDAE.Equation> cont_e,disc_e;
      list<BackendDAE.Var> cont_v,disc_v;
      
    case (cont_e,cont_v,disc_e,disc_v)
      equation
        rels = mixedCollectRelations(cont_e, disc_e);
        (values,value_dims) = generateMixedDiscretePossibleValues2(rels, disc_v, 0);
        values_1 = generateMixedDiscreteCombinationValues(values);
        values_2 = Util.listFlatten(values_1);
        valuesRet = values_2;
      then
        (valuesRet, value_dims);
  end match;
end extractValuesAndDims;

protected function createOdeSystem2
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input Boolean skipDiscInAlgorithm;
  input BackendDAE.Variables inVars;  
  input BackendDAE.Variables inKnVars;  
  input BackendDAE.EquationArray inEquationArray;
  input array<BackendDAE.MultiDimEquation> inArrayEqs;
  input array<DAE.Algorithm> inAlg;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerBackendDAEEquationLstOption;
  input BackendDAE.JacobianType inJacobianType;
  input list<HelpVarInfo> helpVarInfo;
  input Integer inIndx;
  output list<SimEqSystem> equations_;
algorithm
  equations_ :=
  matchcontinue
    (mixedEvent,genDiscrete,skipDiscInAlgorithm,inVars,inKnVars,inEquationArray,inArrayEqs,inAlg,inTplIntegerIntegerBackendDAEEquationLstOption,inJacobianType,helpVarInfo,inIndx)
    local
      Integer eqn_size;
      BackendDAE.BackendDAE subsystem_dae,subsystem_dae_1,subsystem_dae_2;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> optJac;
      BackendDAE.JacobianType jac_tp;
      BackendDAE.Variables v,kv,evars;
      BackendDAE.EquationArray eqn,eeqns;
      list<BackendDAE.Equation> eqn_lst;
      list<DAE.ComponentRef> crefs;
      array<BackendDAE.MultiDimEquation> ae;
      BackendDAE.EventInfo ev;
      list<SimEqSystem> resEqs;
      SimEqSystem equation_;
      BackendDAE.IncidenceMatrix m,m_2,m_3;
      BackendDAE.IncidenceMatrixT mt_1,mT_2,mT_3;
      BackendDAE.StrongComponents comps;
      list<Integer> comps_flat;
      list<list<Integer>> r,t;
      list<Integer> rf,tf;
      list<SimVar> simVars;
      list<BackendDAE.Equation> dlowEqs;
      list<DAE.Exp> beqs;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<tuple<Integer, Integer, SimEqSystem>> simJac;
      Integer index,linInfo;
      array< .DAE.Algorithm> algorithms;
      list<list<Real>> jacVals;
      list<Real> rhsVals,solvedVals;
      BackendDAE.AliasVariables ave;
      list<DAE.ElementSource> sources;
      list<DAE.ComponentRef> names;
      list<list<BackendDAE.Value>> comps_1;
      array<Integer> v1,v2,v1_1,v2_1;
      
        // constant jacobians. Linear system of equations (A x = b) where
        // A and b are constants. TODO: implement symbolic gaussian elimination
        // here. Currently uses dgesv as for next case
    case (mixedEvent,genDiscrete,skipDiscInAlgorithm,v,kv,eqn,ae,algorithms,SOME(jac),BackendDAE.JAC_CONSTANT(),helpVarInfo,inIndx)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem2 create linear system(const jacobian).");
        eqn_size = BackendDAEUtil.equationSize(eqn);
        ((simVars,_)) = BackendVariable.traverseBackendDAEVars(v,traversingdlowvarToSimvar,({},kv));
        simVars = listReverse(simVars);
        ((_,_,_,beqs,sources)) = BackendEquation.traverseBackendDAEEqns(eqn,BackendEquation.equationToExp,(v,ae,{},{},{}));
        beqs = listReverse(beqs);
        rhsVals = ValuesUtil.valueReals(Util.listMap(beqs,Ceval.cevalSimple));
        jacVals = BackendDAEOptimize.evaluateConstantJacobian(listLength(simVars),jac);
        (solvedVals,linInfo) = System.dgesv(jacVals,rhsVals);
        names = Util.listMap(simVars,varName);
        checkLinearSystem(linInfo,names,jacVals,rhsVals);
        // TODO: Move these to known vars :/ This is done in the wrong phase of the compiler... Also, if done as an optimization module, we can optimize more!
        sources = Util.listMap1(sources, DAEUtil.addSymbolicTransformation, DAE.LINEAR_SOLVED(names,jacVals,rhsVals,solvedVals));
        equations_ = Util.listThread3Map(simVars,solvedVals,sources,generateSolvedEquation);
      then
        equations_;
        
        // constant jacobians. Linear system of equations (A x = b) where
        // A and b are constants. TODO: implement symbolic gaussian elimination
        // here. Currently uses dgesv as for next case
    case (mixedEvent,genDiscrete,skipDiscInAlgorithm,v,kv,eqn,ae,algorithms,SOME(jac),BackendDAE.JAC_TIME_VARYING(),helpVarInfo,inIndx)
      equation
        // check Relaxation
        true = RTOpts.debugFlag("relaxation");
        ave = BackendDAEUtil.emptyAliasVariables();
        evars = BackendDAEUtil.emptyVars();
        eeqns = BackendDAEUtil.listEquation({});
        subsystem_dae = BackendDAE.DAE(BackendDAE.EQSYSTEM(v,eqn,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},BackendDAE.SHARED(evars,evars,ave,eeqns,eeqns,ae,algorithms,BackendDAE.EVENT_INFO({},{}),{},BackendDAE.ALGEQSYSTEM() ));
        (subsystem_dae_1 as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(v1,v2,comps))})) = BackendDAEUtil.transformBackendDAE(subsystem_dae,DAEUtil.avlTreeNew(),SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE());
        (subsystem_dae_2,v1_1,v2_1,comps_1,r,t) = BackendDAEOptimize.tearingSystem(subsystem_dae_1,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);
        equations_ = generateRelaxationSystem(mixedEvent,v1_1,v2_1,comps_flat,rf,tf,subsystem_dae_2,helpVarInfo);
      then
        equations_;
        
        // Time varying jacobian. Linear system of equations that needs to be solved during runtime.
    case (mixedEvent,_,skipDiscInAlgorithm,v,kv,eqn,ae,algorithms,SOME(jac),BackendDAE.JAC_TIME_VARYING(),helpVarInfo,inIndx)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem2 create linear system(time varying jacobian).");
        ((simVars,_)) = BackendVariable.traverseBackendDAEVars(v,traversingdlowvarToSimvar,({},kv));
        simVars = listReverse(simVars);
        ((_,_,_,beqs,_)) = BackendEquation.traverseBackendDAEEqns(eqn,BackendEquation.equationToExp,(v,ae,{},{},{}));
        beqs = listReverse(beqs);
        simJac = Util.listMap1(jac, jacToSimjac, v);
      then
        {SES_LINEAR(inIndx, mixedEvent, simVars, beqs, simJac)};
        
        // Time varying nonlinear jacobian. Non-linear system of equations.
    case (mixedEvent,_,skipDiscInAlgorithm,v,kv,eqn,ae,algorithms,SOME(jac),BackendDAE.JAC_NONLINEAR(),helpVarInfo,inIndx)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem2 create non-linear system with jacobian.");
        eqn_lst = BackendDAEUtil.equationList(eqn);
        crefs = BackendVariable.getAllCrefFromVariables(v);
        (resEqs,_) = createNonlinearResidualEquations(eqn_lst, ae, algorithms, {});
      then
        {SES_NONLINEAR(inIndx, resEqs, crefs)};
        
        // No analytic jacobian available. Generate non-linear system.
    case (mixedEvent,_,skipDiscInAlgorithm,v,kv,eqn,ae,algorithms,NONE(),BackendDAE.JAC_NO_ANALYTIC(),helpVarInfo,inIndx)
      equation
        Debug.fprintln("failtrace", "SimCode.createOdeSystem2 create non-linear system without jacobian.");
        eqn_lst = BackendDAEUtil.equationList(eqn);
        crefs = BackendVariable.getAllCrefFromVariables(v);
        (resEqs,_) = createNonlinearResidualEquations(eqn_lst, ae, algorithms, {});
      then
        {SES_NONLINEAR(inIndx, resEqs, crefs)};
        
        // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createOdeSystem2 failed"});
      then
        fail();
  end matchcontinue;
end createOdeSystem2;

protected function checkLinearSystem
  input Integer info;
  input list<DAE.ComponentRef> vars;
  input list<list<Real>> jac;
  input list<Real> rhs;
algorithm
  _ := matchcontinue (info,vars,jac,rhs)
    local
      String infoStr,syst,varnames,varname,rhsStr,jacStr;
    case (0,_,_,_) then ();
    case (info,vars,jac,rhs)
      equation
        true = info > 0;
        varname = ComponentReference.printComponentRefStr(listGet(vars,info));
        infoStr = intString(info);
        varnames = Util.stringDelimitList(Util.listMap(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = Util.stringDelimitList(Util.listMap(rhs, realString)," ;\n  ");
        jacStr = Util.stringDelimitList(Util.listMap1(Util.listListMap(jac,realString),Util.stringDelimitList," , ")," ;\n  ");
        syst = stringAppendList({"\n[\n  ", jacStr, "\n]\n  *\n[\n  ",varnames,"\n]\n  =\n[\n  ",rhsStr,"\n]"});
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
      then fail();
    case (info,vars,jac,rhs)
      equation
        true = info < 0;
        varnames = Util.stringDelimitList(Util.listMap(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = Util.stringDelimitList(Util.listMap(rhs, realString)," ; ");
        jacStr = Util.stringDelimitList(Util.listMap1(Util.listListMap(jac,realString),Util.stringDelimitList," , ")," ; ");
        syst = stringAppendList({"[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
      then fail();
  end matchcontinue;
end checkLinearSystem;

protected function generateSolvedEquation
  input SimVar var;
  input Real val;
  input DAE.ElementSource source;
  output SimEqSystem eq;
protected
  DAE.ComponentRef name;
algorithm
  SIMVAR(name=name) := var;
  eq := SES_SIMPLE_ASSIGN(name,DAE.RCONST(val),source); 
end generateSolvedEquation;

protected function replaceDerOpInEquationList
  "Replaces all der(cref) with $DER.cref in a list of equations."
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := Util.listMap(inEqns, replaceDerOpInEquation);
end replaceDerOpInEquationList;

protected function replaceDerOpMultiDimEquations
"Replaces all der(cref) with $DER.cref in an multidimequation."
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  output BackendDAE.MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue(inMultiDimEquation)
    local
      list<Integer> ilst;
      DAE.Exp e1,e1_1,e2,e2_1;
      DAE.ElementSource source;
      
    case(BackendDAE.MULTIDIM_EQUATION(ilst,e1,e2,source))
      equation
        e1_1 = replaceDerOpInExp(e1);
        e2_1 = replaceDerOpInExp(e2);
      then
        BackendDAE.MULTIDIM_EQUATION(ilst,e1_1,e2_1,source);
    case(inMultiDimEquation) then inMultiDimEquation;
  end matchcontinue;
end replaceDerOpMultiDimEquations;

protected function replaceDerOpInEquation
  "Replaces all der(cref) with $DER.cref in an equation."
  input BackendDAE.Equation inEqn;
  output BackendDAE.Equation outEqn;
algorithm
  outEqn := matchcontinue(inEqn)
    local
      DAE.Exp e1, e2;
      DAE.ElementSource src;
      DAE.ComponentRef cr;
      
    case (BackendDAE.EQUATION(exp = e1, scalar = e2, source = src))
      equation
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
      then
        BackendDAE.EQUATION(e1, e2, src);
        
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1, source = src))
      equation
        e1 = replaceDerOpInExp(e1);
      then
        BackendDAE.RESIDUAL_EQUATION(e1, src);
        
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr,exp = e1, source = src))
      equation
        e1 = replaceDerOpInExp(e1);
      then
        BackendDAE.SOLVED_EQUATION(cr,e1, src);
        
    case (_) then inEqn;
        
  end matchcontinue;
end replaceDerOpInEquation;

protected function replaceDerOpInExp
  "Replaces all der(cref) with $DER.cref in an expression."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  ((outExp, _)) := Expression.traverseExp(inExp, replaceDerOpInExpTraverser, NONE());
end replaceDerOpInExp;

protected function replaceDerOpInExpCond
  "Replaces der(cref) with $DER.cref in an expression, where the cref to replace
  is explicitly given."
  input tuple<DAE.Exp,Option<DAE.ComponentRef>> inTpl;
  output tuple<DAE.Exp,Option<DAE.ComponentRef>> outTpl;
  protected
  DAE.Exp e;
  Option<DAE.ComponentRef> cr;
algorithm
  (e,cr) := inTpl;
  outTpl := Expression.traverseExp(e, replaceDerOpInExpTraverser, cr);
end replaceDerOpInExpCond;

protected function replaceDerOpInExpTraverser
  "Used with Expression.traverseExp to traverse an expression an replace calls to
  der(cref) with a component reference $DER.cref. If an optional component
  reference is supplied, then only that component reference is replaced.
  Otherwise all calls to der are replaced.
  
  This is done since some parts of the compiler can't handle der-calls, such as
  Derive.differentiateExpression. Ideally these parts should be fixed so that they can
  handle der-calls, but until that happens we just replace the der-calls with
  crefs."
  input tuple<DAE.Exp, Option<DAE.ComponentRef>> inExp;
  output tuple<DAE.Exp, Option<DAE.ComponentRef>> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.ComponentRef cr, der_cr;
      DAE.Exp cref_exp;
      DAE.ComponentRef cref;
      
    case ((DAE.CALL(path = Absyn.IDENT("der"),expLst = {DAE.CREF(componentRef = cr)}),
        SOME(cref)))
      equation
        der_cr = ComponentReference.crefPrefixDer(cr);
        true = ComponentReference.crefEqualNoStringCompare(der_cr, cref);
        cref_exp = Expression.crefExp(der_cr);
      then
        ((cref_exp, SOME(cref)));
        
    case ((DAE.CALL(path = Absyn.IDENT("der"),expLst = {DAE.CREF(componentRef = cr)}),
        NONE()))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
        cref_exp = Expression.crefExp(cr);
      then
        ((cref_exp, NONE()));
    case (_) then inExp;
  end matchcontinue;
end replaceDerOpInExpTraverser;

protected function generateRelaxationSystem "function: generateRelaxationSystem
  author: Frenkel TUD
  Generates the actual simulation code for the relaxed system of equation"
  input Boolean mixedEvent "true if generating the mixed system event code";
  input array<Integer> inIntegerArray2;
  input array<Integer> inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input list<Integer> inIntegerLst5;
  input list<Integer> inIntegerLst6;
  input BackendDAE.BackendDAE inBackendDAE;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> outEqns;
algorithm
  outEqns := matchcontinue (mixedEvent,inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,inBackendDAE,helpVarInfo)
    local
      array<Integer> ass1,ass2,ass1_1,ass2_1;
      list<Integer> block_,block_1,block_2,r,t;
      Integer size;
      BackendDAE.BackendDAE daelow,daelow1;
      BackendDAE.Variables v,v1,kv,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqn,eqn1,reeqn,ineq;
      list<BackendDAE.Equation> eqn_lst,reqn_lst;
      list<BackendDAE.Var> var_lst,tvar_lst;
      list<DAE.ComponentRef> crefs;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algorithms;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      list<SimEqSystem> eqns,reqns,alleqns;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.Shared shared;
      
    case (mixedEvent,ass1,ass2,block_,r,t,
        daelow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=eqn)::{},shared=shared),helpVarInfo) 
      equation
        // get equations and variables
        eqn_lst = BackendDAEUtil.equationList(eqn);
        var_lst = BackendDAEUtil.varList(v);
        // get non relaxation equations
        block_1 = Util.listSelect1(block_,r,Util.notListMember);
        // get names from variables
        crefs = BackendVariable.getAllCrefFromVariables(v);
        crefs = listReverse(crefs);
        // generade replacement from non residual eqns           
        repl = BackendVarTransform.emptyReplacements();
        (repl_1,eqns) = getRelaxationReplacements(block_1,ass2,crefs,eqn_lst,repl);
        // replace non tearing vars in residual eqns
        (reqn_lst,tvar_lst) = getRelaxedResidualEqns(r,ass2,crefs,var_lst,eqn_lst,repl_1);
        eqn1 = BackendDAEUtil.listEquation(reqn_lst);
        v1 = BackendDAEUtil.listVar(tvar_lst);
        size = listLength(reqn_lst);
        block_2 = Util.listIntRange(size);
        ass1_1 = listArray(block_2);
        ass2_1 = listArray(block_2);
        daelow1=BackendDAE.DAE(BackendDAE.EQSYSTEM(v1,eqn1,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},shared);
        // generate code for relaxation equations
        reqns = generateRelaxedResidualEqns(block_2,mixedEvent,daelow1, ass1_1, ass2_1, helpVarInfo);
        alleqns = listAppend(reqns,eqns);
      then
        alleqns;
        
    else
      equation
        Debug.fprint("failtrace", "- SimCode.generateRelaxationSystem failed \n");
      then
        fail();
  end matchcontinue;
end generateRelaxationSystem;

protected function getRelaxationReplacements"
Author: Frenkel TUD 2010-09 function getRelaxationReplacements
  solves all equations and add the solution to the replacement"
  input list<Integer> inBlock;
  input array<Integer> inAss2;
  input list<DAE.ComponentRef> inCrefs;
  input list<BackendDAE.Equation> inEqnLst;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
  output list<SimEqSystem> outEqns;
algorithm
  (outRepl,outEqns) := match (inBlock,inAss2,inCrefs,inEqnLst,inRepl)
    local
      Integer e,s;
      list<Integer> block_;
      array<Integer> ass2;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef c;
      list<BackendDAE.Equation> eqnLst;
      BackendDAE.Equation eqn;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
      DAE.Exp exp,varexp,exps;
      list<SimEqSystem> seqns;
      DAE.ElementSource source;
      
    case ({},ass2,crefs,eqnLst,repl) then (repl,{});
      
    case (e::block_,ass2,crefs,eqnLst,repl)
      equation
        s = ass2[e];
        c = listNth(crefs,s-1);
        eqn = listNth(eqnLst,e-1);
        varexp = Expression.crefExp(c);
        (exp,_) = solveEquation(eqn, varexp);
        (exps,_) = BackendVarTransform.replaceExp(exp,repl,NONE());
        repl1 = BackendVarTransform.addReplacement(repl, c, exps);
        source = BackendEquation.equationSource(eqn);
        (repl2,seqns) = getRelaxationReplacements(block_,ass2,crefs,eqnLst,repl1);
      then 
        (repl2,SES_SIMPLE_ASSIGN(c, exp, source)::seqns);
  end match;
end getRelaxationReplacements;

protected function solveEquation"
Author: Frenkel TUD 2010-09 function solveEquation
  solves a equation"
  input BackendDAE.Equation inEqn;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (outExp,outAsserts) := match (inEqn,inExp)
    local
      DAE.Exp exp,e1,e2,sol,zero;
      DAE.ExpType tp;
      list<DAE.Statement> asserts;
      DAE.ComponentRef cr;
      
    case (BackendDAE.EQUATION(exp = e1,scalar = e2),exp)
      equation
        (sol,asserts) = solve(e1, e2, exp);
      then 
        (sol,asserts);
        
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1),exp)
      equation
        tp = Expression.typeof(e1);
        (zero,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
        (sol,asserts) = solve(e1, zero, exp);
      then 
        (sol,asserts);
          
    case (BackendDAE.SOLVED_EQUATION(componentRef= cr, exp = e1),exp)
      equation
        e2 = Expression.crefExp(cr);
        (sol,asserts) = solve(e1, e2, exp);
      then 
        (sol,asserts);
    case (_,_)
      equation
        Debug.fprint("failtrace", "- SimCode.solveEquation failed \n");
      then
        fail();
  end match;
end solveEquation;

protected function getRelaxedResidualEqns"
Author: Frenkel TUD 2010-09 function getRelaxedResidualEqns
  replace all non tearing vars with its solutions in the 
  residual eqns"
  input list<Integer> inBlock;
  input array<Integer> inAss2;
  input list<DAE.ComponentRef> inCrefs;
  input list<BackendDAE.Var> inVarLst;
  input list<BackendDAE.Equation> inEqnLst;
  input BackendVarTransform.VariableReplacements inRepl;
  output list<BackendDAE.Equation> outEqnLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  (outEqnLst,outVarLst) := match (inBlock,inAss2,inCrefs,inVarLst,inEqnLst,inRepl)
    local
      Integer e,s;
      list<Integer> block_;
      array<Integer> ass2;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef c;
      list<BackendDAE.Equation> eqnLst,eqnLst1;
      BackendDAE.Equation eqn,eqn1;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Var> varlst,varlst1;
      BackendDAE.Var var;
      
    case ({},_,_,_,_,_) then ({},{});
      
    case (e::block_,ass2,crefs,varlst,eqnLst,repl)
      equation
        s = ass2[e];
        c = listNth(crefs,s-1);
        var = listNth(varlst,s-1);
        eqn = listNth(eqnLst,e-1);
        {eqn1} = BackendVarTransform.replaceEquations({eqn},repl);
        (eqnLst1,varlst1) = getRelaxedResidualEqns(block_,ass2,crefs,varlst,eqnLst,repl);
      then 
        ((eqn1::eqnLst1),(var::varlst1));
  end match;
end getRelaxedResidualEqns;

protected function generateRelaxedResidualEqns"
Author: Frenkel TUD 2010-09 function generateRelaxedResidualEqns
  generates the equations for the residual eqns"
  input list<Integer> inBlock;
  input Boolean mixedEvent "true if generating the mixed system event code";
  input BackendDAE.BackendDAE daelow;
  input array<Integer> Ass1;
  input array<Integer> Ass2;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> outEqnLst;
algorithm
  outEqnLst := match (inBlock,mixedEvent,daelow, Ass1, Ass2, helpVarInfo)
    local
      Integer r,i;
      list<Integer> block_;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<SimVar> simVars;
      list<DAE.Exp> beqs;
      list<tuple<Integer, Integer, SimEqSystem>> simJac;
      list<SimEqSystem> reqns;
      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray eqn;
      list<BackendDAE.Equation> dlowEqs;
      array<BackendDAE.MultiDimEquation> ae;
      Integer index;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    case ({r},mixedEvent,daelow, Ass1, Ass2, helpVarInfo)
      equation
        i = Ass2[r];
        reqns = createEquation(r, i, daelow, helpVarInfo, false, false);
      then 
        reqns;
        
    case (block_ as _::_::_,mixedEvent,BackendDAE.DAE(eqs=(syst as BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=eqn))::{},shared=shared as BackendDAE.SHARED(knownVars=kv,arrayEqs=ae)), Ass1, Ass2, helpVarInfo)
      equation
        (m,mT) = BackendDAEUtil.incidenceMatrix(syst, shared, BackendDAE.NORMAL());
        //mT = BackendDAEUtil.transposeMatrix(m);
        SOME(jac) = BackendDAEUtil.calculateJacobian(v, eqn, ae, m, mT,false);
        ((simVars,_)) = BackendVariable.traverseBackendDAEVars(v,traversingdlowvarToSimvar,({},kv));
        simVars = listReverse(simVars);
        ((_,_,_,beqs,_)) = BackendEquation.traverseBackendDAEEqns(eqn,BackendEquation.equationToExp,(v,ae,{},{},{}));
        beqs = listReverse(beqs);
        simJac = Util.listMap1(jac, jacToSimjac, v);
        index = Util.listFirst(block_); // use first equation nr as index
      then
        {SES_LINEAR(index, mixedEvent, simVars, beqs, simJac)};
  end match;
end generateRelaxedResidualEqns;

protected function jacToSimjac
  input tuple<Integer, Integer, BackendDAE.Equation> jac;
  input BackendDAE.Variables v;
  output tuple<Integer, Integer, SimEqSystem> simJac;
algorithm
  simJac := match (jac, v)
    local
      Integer row;
      Integer col;
      DAE.Exp e;
      DAE.ElementSource source;
      
    case ((row, col, BackendDAE.RESIDUAL_EQUATION(exp=e,source=source)), v)
      equation
        // rhs_exp = BackendDAEUtil.getEqnsysRhsExp(e, v);
        // rhs_exp_1 = ExpressionSimplify.simplify(rhs_exp);
        // then ((row - 1, col - 1, SES_RESIDUAL(rhs_exp_1)));
      then 
        ((row - 1, col - 1, SES_RESIDUAL(e,source)));
  end match;
end jacToSimjac;

protected function listMap3passthrough "function listMap3passthrough
  Takes a list and a function and three extra arguments passed to the function.
  The function produces one new value which is used for creating a new list.
  The 3.th extra agruments are passed through"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aType_bType_cType_dToType_e inFuncTypeTypeATypeBTypeCTypeDToTypeE;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  output list<Type_e> outTypeELst;
  output Type_d outTypeD;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aType_bType_cType_dToType_e
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    output Type_e outTypeE;
    output Type_d outTypeD;
  end FuncTypeType_aType_bType_cType_dToType_e;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  (outTypeELst,outTypeD) := match (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeE,inTypeB,inTypeC,inTypeD)
    local
      Type_e f_1;
      list<Type_e> r_1;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aType_bType_cType_dToType_e fn;
      Type_b extraarg1;
      Type_c extraarg2;
      Type_d extraarg3,extraarg31,extraarg32;
      
    case ({},_,_,_,extraarg3) then ({},extraarg3);
      
    case ((f :: r),fn,extraarg1,extraarg2,extraarg3)
      equation
        (r_1,extraarg31) = listMap3passthrough(r, fn, extraarg1, extraarg2, extraarg3);
        (f_1,extraarg32) = fn(f, extraarg1, extraarg2, extraarg31);
      then
        ((f_1 :: r_1),extraarg32);
  end match;
end listMap3passthrough;

protected function createSingleArrayEqnCode
  input Boolean genDiscrete;
  input BackendDAE.EquationArray inEquationArray;
  input array<BackendDAE.MultiDimEquation> inArrayEqs;
  input BackendDAE.Variables inVars;
  input list<HelpVarInfo> helpVarInfo;
  input Integer inIndex;
  output list<SimEqSystem> equations_;
algorithm
  equations_ := matchcontinue(genDiscrete,inEquationArray,inArrayEqs,inVars,helpVarInfo,inIndex) 
    local
      Integer indx;
      list<Integer> ds;
      DAE.Exp e1,e2;
      list<DAE.Exp> ea1,ea2;
      list<tuple<DAE.Exp,DAE.Exp>> ealst;
      list<BackendDAE.Equation> re;
      DAE.ComponentRef cr,cr_1;
      BackendDAE.Variables vars,evars;
      BackendDAE.EquationArray eqns,eeqns,eqns_1;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<Algorithm.Algorithm> al;
      array<list<Integer>> m,mt;
      DAE.ElementSource source;
      BackendDAE.AliasVariables av;
      BackendDAE.BackendDAE subsystem_dae;
      SimEqSystem equation_;
      array<Integer> v1,v2;
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    case (genDiscrete,eqns,ae,vars,helpVarInfo,inIndex)
      equation
        BackendDAE.ARRAY_EQUATION(index=indx) = BackendDAEUtil.equationNth(eqns,0);
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,source) = ae[indx + 1];
        BackendDAE.VAR(varName = cr) = BackendVariable.getVarAt(vars,1);
        // We need to strip subs from the name since they are removed in cr.
        cr_1 = ComponentReference.crefStripLastSubs(cr);
        ((e1,_)) = BackendDAEUtil.collateArrExp((e1,NONE()));
        ((e2,_)) = BackendDAEUtil.collateArrExp((e2,NONE()));
        (e1,e2) = solveTrivialArrayEquation(cr_1,e1,e2);
        equation_ = createSingleArrayEqnCode2(cr_1, cr_1, e1, e2, source);
      then
        {equation_};
        
    case (genDiscrete,eqns,ae,vars,helpVarInfo,inIndex)
      equation
        BackendDAE.ARRAY_EQUATION(index=indx) = BackendDAEUtil.equationNth(eqns,0);
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,source) = ae[indx + 1];
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
        ea1 = BackendDAEUtil.collateArrExpList(ea1,NONE());
        ea2 = BackendDAEUtil.collateArrExpList(ea2,NONE());
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,BackendEquation.generateEQUATION,source);
        eqns_1 = BackendDAEUtil.listEquation(re);
        av = BackendDAEUtil.emptyAliasVariables();
        eeqns = BackendDAEUtil.listEquation({});
        evars = BackendDAEUtil.listVar({});
        al = listArray({});
        ae1 = listArray({});
        syst = BackendDAE.EQSYSTEM(vars,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(evars,evars,av,eeqns,eeqns,ae1,al,BackendDAE.EVENT_INFO({},{}),{},BackendDAE.ARRAYSYSTEM());
        subsystem_dae = BackendDAE.DAE({syst},shared);
        (subsystem_dae as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))})) = BackendDAEUtil.transformBackendDAE(subsystem_dae,DAEUtil.avlTreeNew(),SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.ALLOW_UNDERCONSTRAINED())),NONE());
        equations_ = createEquations(false, true, genDiscrete, false, false, subsystem_dae, comps, helpVarInfo);
      then
        equations_;
        
        // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"array equations currently only supported on form v = functioncall(...)"});
      then
        fail();
  end matchcontinue;
end createSingleArrayEqnCode;

protected function createSingleAlgorithmCode
  input BackendDAE.EquationArray inEquationArray;
  input array< .DAE.Algorithm> inAlgorithms;
  input BackendDAE.Variables inVars;
  input Boolean skipDiscinAlgorithm;
  output list<SimEqSystem> equations_;
algorithm
  equations_ := matchcontinue (inEquationArray,inAlgorithms,inVars,skipDiscinAlgorithm)
    local
      Integer indx;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<Algorithm.Algorithm> al;
      Algorithm.Algorithm alg;
      list<Expression.ComponentRef> solvedVars,algOutVars;
      list<DAE.Exp> algOutExpVars;
      String message,algStr;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
      
      // normal call
    case (eqns,al,vars,false)
      equation
        BackendDAE.ALGORITHM(indx,_,algOutExpVars,_) = BackendDAEUtil.equationNth(eqns,0);
        alg = al[indx + 1];
        solvedVars = BackendVariable.getAllCrefFromVariables(vars);
        algOutVars = Util.listMap(algOutExpVars,Expression.expCref);
        // The variables solved for and the output variables of the algorithm must be the same.
        true = Util.listSetEqualOnTrue(solvedVars,algOutVars,ComponentReference.crefEqualNoStringCompare);
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg,NONE());
      then {SES_ALGORITHM(algStatements)};
        
        // remove discrete Vars
    case (eqns,al,vars,true)
      equation
        BackendDAE.ALGORITHM(indx,_,algOutExpVars,_) = BackendDAEUtil.equationNth(eqns,0);
        alg = al[indx + 1];
        solvedVars = BackendVariable.getAllCrefFromVariables(vars);
        algOutVars = Util.listMap(algOutExpVars,Expression.expCref);
        // The variables solved for and the output variables of the algorithm must be the same.
        true = Util.listSetEqualOnTrue(solvedVars,algOutVars,ComponentReference.crefEqualNoStringCompare);
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg,NONE());
        algStatements = BackendDAEUtil.removediscreteAssingments(algStatements,vars);
      then {SES_ALGORITHM(algStatements)};
        
        // Error message, inverse algorithms not supported yet
    case (eqns,al,vars,skipDiscinAlgorithm)
      equation
        BackendDAE.ALGORITHM(indx,_,algOutExpVars,source) = BackendDAEUtil.equationNth(eqns,0);
        alg = al[indx + 1];
        solvedVars = BackendVariable.getAllCrefFromVariables(vars);
        algOutVars = Util.listMap(algOutExpVars,Expression.expCref);
        // The variables solved for and the output variables of the algorithm must be the same.
        false = Util.listSetEqualOnTrue(solvedVars,algOutVars,ComponentReference.crefEqualNoStringCompare);
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();
        
        // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCode.createSingleAlgorithmCode failed!"});
      then
        fail();
  end matchcontinue;
end createSingleAlgorithmCode;

// TODO: are the cases really correct?
protected function createSingleArrayEqnCode2
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.Exp inExp3;
  input DAE.Exp inExp4;
  input DAE.ElementSource source;
  output SimEqSystem equation_;
algorithm
  equation_ := matchcontinue (inComponentRef1,inComponentRef2,inExp3,inExp4,source)
    local
      DAE.ComponentRef cr,eltcr,cr2;
      DAE.Exp e1,e2;
      DAE.ExpType ty;
      
    case (cr,eltcr,(e1 as DAE.CREF(componentRef = cr2)),e2,source)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        SES_ARRAY_CALL_ASSIGN(eltcr, e2, source);
        
    case (cr,eltcr,e1,(e2 as DAE.CREF(componentRef = cr2)),source)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        SES_ARRAY_CALL_ASSIGN(eltcr, e1, source);
        
    case (cr,eltcr,(e1 as DAE.UNARY(exp=DAE.CREF(componentRef = cr2))),e2,source)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        ty = Expression.typeof(e2);
        e2 = Expression.negate(e2);
      then
        SES_ARRAY_CALL_ASSIGN(eltcr, e2, source);
        
    case (cr,eltcr,e1,(e2 as DAE.UNARY(exp=DAE.CREF(componentRef = cr2))),source)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        e1 = Expression.negate(e1);
      then
        SES_ARRAY_CALL_ASSIGN(eltcr, e1, source);
        
    case (cr,eltcr,e1,DAE.UNARY(DAE.UMINUS_ARR(ty),e2),source)
      equation
        cr2 = getVectorizedCrefFromExp(e2);
        e1 = Expression.negate(e1);
      then
        SES_ARRAY_CALL_ASSIGN(cr2, e1, source);
        
    case (cr,eltcr,DAE.UNARY(DAE.UMINUS_ARR(ty),e1),e2,source) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
        e2 = Expression.negate(e2);
      then
        SES_ARRAY_CALL_ASSIGN(cr2, e2, source);
        
    case (cr,eltcr,e1,e2,source) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e2);
      then
        SES_ARRAY_CALL_ASSIGN(cr2, e1, source);
        
    case (cr,eltcr,e1,e2,source) /* e1 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
      then
        SES_ARRAY_CALL_ASSIGN(cr2, e2, source);
        
        // failure
    case (cr,_,e1,e2,_)
      /*
       equation
       s1 = ExpressionDump.printExpStr(e1);
       s2 = ExpressionDump.printExpStr(e2);
       s3 = ComponentReference.crefStr(cr);
       s = stringAppendList({"SimCode.createSingleArrayEqnCode2 failed for: ", s1, " = " , s2, " solve for ", s3 });
       Error.addMessage(Error.INTERNAL_ERROR, {s});
       */        
    then
      fail();
  end matchcontinue;
end createSingleArrayEqnCode2;

protected function addLambdaToEquationList
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(inEqns)
  local
    BackendDAE.Equation eqn;
    list<BackendDAE.Equation> eqns;
    DAE.Exp e1, e2, lambda;
    DAE.ElementSource es;
    
    case({}) then {};
      
    case(BackendDAE.EQUATION(e1, e2, es)::eqns) equation
      lambda = DAE.CREF(DAE.CREF_IDENT("$_lambda", DAE.ET_REAL(), {}), DAE.ET_REAL());
      e1 = DAE.BINARY(lambda, DAE.MUL(DAE.ET_REAL()), e1);
      e2 = DAE.BINARY(lambda, DAE.MUL(DAE.ET_REAL()), e2);
      eqn = BackendDAE.EQUATION(e1, e2, es);
      eqns = addLambdaToEquationList(eqns);
    then eqn::eqns;
      
    case(BackendDAE.RESIDUAL_EQUATION(e1, es)::eqns) equation
      lambda = DAE.CREF(DAE.CREF_IDENT("$_lambda", DAE.ET_REAL(), {}), DAE.ET_REAL());
      e1 = DAE.BINARY(lambda, DAE.MUL(DAE.ET_REAL()), e1);
      eqn = BackendDAE.RESIDUAL_EQUATION(e1, es);
      eqns = addLambdaToEquationList(eqns);
    then eqn::eqns;
      
    case(eqn::eqns) equation
      BackendDump.dumpEquation(eqn);
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCode.mo: addLambdaToEquationList failed"});
    then fail();
  end matchcontinue;
end addLambdaToEquationList;

protected function generateStartValueResiduals
"lochel"
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(inVars)
  local
    BackendDAE.Var var;
    list<BackendDAE.Var> vars;
    BackendDAE.Equation eqn;
    list<BackendDAE.Equation> eqns;
    DAE.Exp e, e1, e2, lambda, crefExp, startExp;
    DAE.ComponentRef cref;
    DAE.ExpType tp;
    case({}) then {};
      
    case(var::vars) equation
      SOME(startExp) = BackendVariable.varStartValueOption(var);
      lambda = DAE.CREF(DAE.CREF_IDENT("$_lambda", DAE.ET_REAL(), {}), DAE.ET_REAL());
      cref = BackendVariable.varCref(var);
      crefExp = DAE.CREF(cref, DAE.ET_REAL());
      
      e1 = DAE.BINARY(DAE.RCONST(1.0), DAE.SUB(DAE.ET_REAL()), lambda);
      
      e = Expression.crefExp(cref);
      tp = Expression.typeof(e);
      startExp = Expression.makeBuiltinCall("pre", {e}, tp);
      e2 = DAE.BINARY(crefExp, DAE.SUB(DAE.ET_REAL()), startExp);
      
      e1 = DAE.BINARY(e1, DAE.MUL(DAE.ET_REAL()), e2);
      eqn = BackendDAE.RESIDUAL_EQUATION(e1, DAE.emptyElementSource);
      eqns = generateStartValueResiduals(vars);
    then eqn::eqns;
      
    case(var::vars) equation
      eqns = generateStartValueResiduals(vars);
    then eqns;
      
    case(_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCode.mo: generateStartValueResiduals failed"});
    then fail();
  end matchcontinue;
end generateStartValueResiduals;

protected function createResidualEquations
  input BackendDAE.BackendDAE dae;
  output list<SimEqSystem> residualEquations;
algorithm
  residualEquations := matchcontinue (dae)
    local
      list<BackendDAE.Equation> eqns_lst, se_lst, ie_lst, ie2_lst, ie3_lst;
      BackendDAE.Variables vars, knvars;
      BackendDAE.EquationArray eqns, se, ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<Algorithm.Algorithm> al;
      BackendDAE.EventInfo ev;
      list<SimEqSystem> resEqus1,resEqus2,resEqus3;
      BackendDAE.AliasVariables av;
      BackendDAE.EqSystems systs;
      
    case (dae as BackendDAE.DAE(eqs=systs,shared=BackendDAE.SHARED(knownVars=knvars,initialEqs=ie,aliasVars=av,algorithms=al)))
      equation
        (_,ie2_lst) = BackendDAEUtil.mapEqSystemAndFold(dae,createResidualEquations1,{});
        ((ie2_lst,_)) = BackendVariable.traverseBackendDAEVars(knvars,generateInitialEquationsFromStart,(ie2_lst,av));
        ie2_lst = listReverse(ie2_lst);
        
        /*
        ((_,_,_,eqns_lst)) = BackendEquation.traverseBackendDAEEqns(eqns,selectContinuousEquations,(1, ass2, vars,{}));
        eqns_lst = listReverse(eqns_lst);

        eqns_lst = Util.listMap(eqns_lst, BackendEquation.equationToResidualForm);
        eqns_lst = Util.listFilter(eqns_lst, failUnlessResidual);
        resEqus1 = Util.listMap1(eqns_lst, dlowEqToSimEqSystem,al);
        
        se_lst = BackendEquation.traverseBackendDAEEqns(se,BackendDAEUtil.traverseequationToResidualForm,{});
        se_lst = replaceDerOpInEquationList(se_lst);
        se_lst = listReverse(se_lst);
        se_lst = Util.listFilter(se_lst, failUnlessResidual);
        resEqus2 = Util.listMap1(se_lst, dlowEqToSimEqSystem,al);
        */
        
        ie_lst = BackendEquation.traverseBackendDAEEqns(ie,BackendDAEUtil.traverseequationToResidualForm,{});
        ie_lst = replaceDerOpInEquationList(ie_lst);
        ie_lst = listReverse(ie_lst);
        ie_lst = Util.listFilter(ie_lst, failUnlessResidual);
        ie_lst = addLambdaToEquationList(ie_lst);
        resEqus1 = Util.listMap1(ie_lst, dlowEqToSimEqSystem,al);
        
        ie2_lst = Util.listMap(ie2_lst, BackendEquation.equationToResidualForm);
        ie2_lst = Util.listFilter(ie2_lst, failUnlessResidual);
        ie2_lst = addLambdaToEquationList(ie2_lst);
        resEqus2 = Util.listMap1(ie2_lst, dlowEqToSimEqSystem,al);
        
        ie3_lst = generateStartValueResiduals(Util.listFlatten(Util.listMapMap(systs,BackendVariable.daeVars,BackendDAEUtil.varList)));
        resEqus3 = Util.listMap1(ie3_lst, dlowEqToSimEqSystem, al);
        
        residualEquations = listAppend(resEqus1, resEqus2);
        residualEquations = listAppend(residualEquations, resEqus3);
        //residualEquations = listAppend(resEqus1,resEqus3);
        //residualEquations = listAppend(residualEquations, resEqus4);
      then
        residualEquations;
        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createResidualEquations failed"});
      then
        fail();
  end matchcontinue;
end createResidualEquations;

protected function createResidualEquations1
  input BackendDAE.EqSystem syst;
  input tuple<BackendDAE.Shared,list<BackendDAE.Equation>> sharedExtra;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,list<BackendDAE.Equation>> osharedExtra;
algorithm
  (osyst,osharedExtra) := matchcontinue (syst,sharedExtra)
    local
      list<BackendDAE.Equation> eqns_lst, se_lst, ie_lst, ie2_lst, ie3_lst;
      BackendDAE.Variables vars, knvars;
      BackendDAE.EquationArray eqns, se, ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<Algorithm.Algorithm> al;
      BackendDAE.EventInfo ev;
      list<SimEqSystem> resEqus1,resEqus2,resEqus3;
      BackendDAE.AliasVariables av;
      BackendDAE.Shared shared;
      
    case (BackendDAE.EQSYSTEM(orderedVars=vars),(shared as BackendDAE.SHARED(aliasVars=av),ie2_lst))
      equation
        ((ie2_lst,_)) = BackendVariable.traverseBackendDAEVars(vars,generateInitialEquationsFromStart,(ie2_lst,av));
      then (syst,(shared,ie2_lst));
        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createResidualEquations failed"});
      then
        fail();
  end matchcontinue;
end createResidualEquations1;

protected function dlowEqToSimEqSystem
  input BackendDAE.Equation inEquation;
  input array<Algorithm.Algorithm> algs;
  output SimEqSystem outEquation;
algorithm
  outEquation := match (inEquation,algs)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp_;
      Algorithm.Algorithm alg;
      Integer indx;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
      
    case (BackendDAE.SOLVED_EQUATION(cr, exp_, source),_) then SES_SIMPLE_ASSIGN(cr, exp_, source);
      
    case (BackendDAE.RESIDUAL_EQUATION(exp_, source),_) then SES_RESIDUAL(exp_, source);
      
    case (BackendDAE.ALGORITHM(index=indx),algs)
      equation
        alg = algs[indx + 1];
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      then
        SES_ALGORITHM(algStatements);
  end match;
end dlowEqToSimEqSystem;

protected function dlowAlgToSimEqSystem
  input DAE.Algorithm inAlg;
  output SimEqSystem outEquation;
algorithm
  outEquation := match (inAlg)
    local
      DAE.Algorithm alg;
      list<DAE.Statement> algStatements;
    case (alg)
      equation
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      then
        SES_ALGORITHM(algStatements);
  end match;
end dlowAlgToSimEqSystem;

protected function failUnlessResidual
  input BackendDAE.Equation eq;
algorithm
  _ := match (eq)
    case (BackendDAE.RESIDUAL_EQUATION(exp=_)) then ();
  end match;
end failUnlessResidual;

protected function createInitialEquations
  input BackendDAE.BackendDAE dlow;
  output list<SimEqSystem> initialEquations;
algorithm
  initialEquations := matchcontinue (dlow)
    local
      BackendDAE.Variables vars,knvars;
      array<DAE.Algorithm> algs;
      list<BackendDAE.Equation> initialEquationsTmp,initialEquationsTmp2;
      BackendDAE.AliasVariables av;
      
      // this is the old version if the new fails 
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars)::{}, shared=BackendDAE.SHARED(aliasVars=av, algorithms=algs)))
      equation
        // vars
        ((initialEquationsTmp2,_)) = BackendVariable.traverseBackendDAEVars(vars,createInitialAssignmentsFromStart,({},av));
        initialEquationsTmp2 = listReverse(initialEquationsTmp2);
        // kvars
        //((initialEquationsTmp,_)) = BackendVariable.traverseBackendDAEVars(knvars,createInitialAssignmentsFromStart,({},av));
        //initialEquationsTmp = listReverse(initialEquationsTmp);
        //initialEquationsTmp2 = listAppend(initialEquationsTmp2, initialEquationsTmp);
        
        initialEquations = Util.listMap1(initialEquationsTmp2,
          dlowEqToSimEqSystem,algs);
      then
        initialEquations;
        
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createInitialEquations failed"});
      then
        fail();
  end matchcontinue;
end createInitialEquations;

protected function createParameterEquations
  input BackendDAE.BackendDAE dlow;
  output list<SimEqSystem> parameterEquations;
algorithm
  parameterEquations := matchcontinue (dlow)
    local
      list<BackendDAE.Equation> parameterEquationsTmp;
      BackendDAE.Variables vars,knvars,extobj,v,kn;
      array<Algorithm.Algorithm> algs;
      BackendDAE.EquationArray ie,pe,emptyeqns;
      list<SimEqSystem> inalgs,simvarasserts;
      list<DAE.Algorithm> ialgs,varasserts,varasserts1;
      BackendDAE.BackendDAE paramdlow,paramdlow1;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      BackendDAE.ExternalObjectClasses extObjClasses;
      BackendDAE.AliasVariables alisvars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      array<Integer> v1,v2;
      list<Integer> lv1,lv2;
      BackendDAE.StrongComponents comps;
      list<BackendDAE.Var> lv,lkn;
      list<HelpVarInfo> helpVarInfo;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars)::{},shared=BackendDAE.SHARED(knownVars=knvars,externalObjects=extobj,initialEqs=ie,algorithms=algs,arrayEqs=arrayEqs,extObjClasses=extObjClasses)))
      equation
        // kvars params
        ((parameterEquationsTmp,lv,lkn,lv1,lv2,_)) = BackendVariable.traverseBackendDAEVars(knvars,createInitialParamAssignments,({},{},{},{},{},1));
        
        // sort the equations
        emptyeqns = BackendDAEUtil.listEquation({});
        pe = BackendDAEUtil.listEquation(parameterEquationsTmp);
        alisvars = BackendDAEUtil.emptyAliasVariables();
        v = BackendDAEUtil.listVar(lv);
        kn = BackendDAEUtil.listVar(lkn);
        syst = BackendDAE.EQSYSTEM(v,pe,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(kn,extobj,alisvars,emptyeqns,emptyeqns,arrayEqs,algs,BackendDAE.EVENT_INFO({},{}),extObjClasses,BackendDAE.PARAMETERSYSTEM());
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,shared);
        paramdlow = BackendDAE.DAE({syst},shared);
        //mT = BackendDAEUtil.transposeMatrix(m);
        v1 = listArray(lv1);
        v2 = listArray(lv2);
        Debug.fcall("paramdlowdump", print,"Param DAE:\n");
        Debug.fcall("paramdlowdump", BackendDump.dump,paramdlow);
        Debug.fcall("paramdlowdump", BackendDump.dumpIncidenceMatrix,m);
        Debug.fcall("paramdlowdump", BackendDump.dumpIncidenceMatrixT,mT);
        Debug.fcall("paramdlowdump", BackendDump.dumpMatching,v1);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(v1,v2,{}));
        (syst,comps) = BackendDAETransform.strongComponents(syst, shared);
        paramdlow = BackendDAE.DAE({syst},shared);
        Debug.fcall("paramdlowdump", BackendDump.dumpComponents,comps);
        
        (helpVarInfo, paramdlow1,_) = generateHelpVarInfo(paramdlow);
        parameterEquations = createEquations(false, false, true, false, false, paramdlow1, comps, helpVarInfo);
        
        ialgs = BackendEquation.getUsedAlgorithmsfromEquations(ie,algs);
        inalgs = Util.listMap(ialgs,dlowAlgToSimEqSystem);
        // get minmax and nominal asserts
        varasserts = BackendVariable.traverseBackendDAEVars(knvars,createVarAsserts,{});
        varasserts1 = BackendVariable.traverseBackendDAEVars(vars,createVarNominalAssert,varasserts);
        simvarasserts = Util.listMap(varasserts1,dlowAlgToSimEqSystem);
        
        parameterEquations = listAppend(parameterEquations, inalgs);
        parameterEquations = listAppend(parameterEquations, simvarasserts);
      then
        parameterEquations;
        
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"createParameterEquations failed"});
      then
        fail();
  end matchcontinue;
end createParameterEquations;

protected function createInitialAssignmentsFromStart
  input tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.AliasVariables>> inTpl;
  output tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.AliasVariables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)  
    local
      BackendDAE.Var var;
      BackendDAE.Equation initialEquation;
      list<BackendDAE.Equation> eqns;
      Option<DAE.VariableAttributes> attr;
      DAE.ComponentRef name;
      DAE.Exp startv;
      DAE.ElementSource source;
      BackendDAE.AliasVariables av;
      
      // also add an assignment for variables that have non-constant
      // expressions, e.g. parameter values, as start.  NOTE: such start
      // attributes can then not be changed in the text file, since the initial
      // calc. will override those entries!    
    case ((var as BackendDAE.VAR(varName=name, source=source),(eqns,av)))
      equation
        NOALIAS() = getAliasVar(var,SOME(av));
        startv = BackendVariable.varStartValueFail(var);
        false = Expression.isConst(startv);
        initialEquation = BackendDAE.SOLVED_EQUATION(name, startv, source);
      then
        ((var,(initialEquation :: eqns,av)));
 
    case (inTpl) then inTpl;
  end matchcontinue;
end createInitialAssignmentsFromStart;

protected function createInitialParamAssignments
  input tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>,list<BackendDAE.Var>,list<Integer>,list<Integer>,Integer>> inTpl;
  output tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>,list<BackendDAE.Var>,list<Integer>,list<Integer>,Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl) 
    local
      BackendDAE.Var var,var1;
      BackendDAE.Equation initialEquation;
      list<BackendDAE.Equation> eqns;
      DAE.ComponentRef cr;
      DAE.Exp e,cre;
      DAE.ElementSource source;
      list<Integer> v1,v2;
      Integer pos,epos;
      list<BackendDAE.Var> v,kn;
      
    case ((var as BackendDAE.VAR(varName=cr, bindExp=SOME(e), source = source),(eqns,v,kn,v1,v2,pos)))
      equation
        false = Expression.isConst(e);
        cre = Expression.crefExp(cr);
        initialEquation = BackendDAE.EQUATION(cre, e, source);
        epos = listLength(v1)+1;
        var1 = BackendVariable.setVarKind(var,BackendDAE.VARIABLE());
      then
        ((var,(initialEquation :: eqns,var1::v,kn,epos::v1,pos::v2,pos+1)));
        
    case ((var,(eqns,v,kn,v1,v2,pos)))
      equation
        var1 = BackendVariable.setVarKind(var,BackendDAE.PARAM());
      then ((var,(eqns,v,var1::kn,v1,v2,pos)));
  end matchcontinue;
end createInitialParamAssignments;

protected function createVarAsserts
  input tuple<BackendDAE.Var, list<DAE.Algorithm>> inTpl;
  output tuple<BackendDAE.Var, list<DAE.Algorithm>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl) 
    local
      BackendDAE.Var var;
      list<DAE.Algorithm> asserts,asserts1,asserts2;
      DAE.ComponentRef name;
      DAE.ElementSource source;
      BackendDAE.VarKind kind;
      Option<DAE.VariableAttributes> attr;
      
    case ((var as BackendDAE.VAR(varName=name, varKind=kind, values = attr, source = source),asserts))
      equation
        ((_,asserts1)) = createVarMinMaxAssert((var,asserts));
        ((_,asserts2)) = createVarNominalAssert((var,asserts1));
      then
        ((var,asserts2));
        
    case inTpl
      then inTpl;
  end matchcontinue;
end createVarAsserts;

protected function createVarNominalAssert
  input tuple<BackendDAE.Var, list<DAE.Algorithm>> inTpl;
  output tuple<BackendDAE.Var, list<DAE.Algorithm>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl) 
    local
      BackendDAE.Var var;
      list<DAE.Algorithm> asserts,asserts1,nominal;
      DAE.ComponentRef name;
      DAE.ElementSource source;
      BackendDAE.VarKind kind;
      Option<DAE.VariableAttributes> attr;
      BackendDAE.Type varType;
      
    case ((var as BackendDAE.VAR(varName=name, varKind=kind, values = attr, varType=varType, source = source),asserts))
      equation
        nominal = BackendVariable.getNominalAssert(attr,name,source,kind,varType);
        asserts1 = listAppend(asserts,nominal);
      then
        ((var,asserts1));
        
    case inTpl
      then inTpl;
  end matchcontinue;
end createVarNominalAssert;

protected function createVarMinMaxAssert
  input tuple<BackendDAE.Var, list<DAE.Algorithm>> inTpl;
  output tuple<BackendDAE.Var, list<DAE.Algorithm>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl) 
    local
      BackendDAE.Var var;
      list<DAE.Algorithm> asserts,asserts1,minmax;
      DAE.ComponentRef name;
      DAE.ElementSource source;
      BackendDAE.VarKind kind;
      Option<DAE.VariableAttributes> attr;
      BackendDAE.Type varType;
      
    case ((var as BackendDAE.VAR(varName=name, varKind=kind, values = attr, varType=varType, source = source),asserts))
      equation
        minmax = BackendVariable.getMinMaxAsserts(attr,name,source,kind,varType);
        asserts1 = listAppend(asserts,minmax);
      then
        ((var,asserts1));
        
    case inTpl
      then inTpl;
  end matchcontinue;
end createVarMinMaxAssert;


protected function createSampleConditions
" function filter sample events 
  and add the corresponding helpVar index to the sample"
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input list<HelpVarInfo> inHelpVarInfo;
  output list<SampleCondition> outSample;
  output list<HelpVarInfo> outHelpVarInfo;
algorithm
  (outSample, outHelpVarInfo) := matchcontinue (inZeroCrossings,inHelpVarInfo)
    local
      list<BackendDAE.ZeroCrossing> rest;
      DAE.Exp e;
      SampleCondition res;
      list<HelpVarInfo> newHelpVars;
    case ({}, inHelpVarInfo) then ({},inHelpVarInfo) ;
    case (BackendDAE.ZERO_CROSSING(relation_ = e as DAE.CALL(path = Absyn.IDENT("sample")))::rest, inHelpVarInfo)
      equation
        (res,newHelpVars) = addHForConditionSample(e,inHelpVarInfo,listLength(inHelpVarInfo));
        inHelpVarInfo = listAppend(inHelpVarInfo,newHelpVars);
        (outSample, inHelpVarInfo) = createSampleConditions(rest,inHelpVarInfo);
      then
        ((res::outSample),inHelpVarInfo);
    case (_::rest, inHelpVarInfo)
      equation
        (outSample,inHelpVarInfo) = createSampleConditions(rest,inHelpVarInfo);
      then
        (outSample,inHelpVarInfo);
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createSampleConditions failed"});
      then
        fail();
  end matchcontinue;
end createSampleConditions;

protected function addHForConditionSample
  input DAE.Exp condition;
  input list<HelpVarInfo> helpVarInfo;
  input Integer nHelpVar;
  output SampleCondition conditionAndHindex;
  output list<HelpVarInfo> outhelpVarInfo;
algorithm
  (conditionAndHindex, outhelpVarInfo):=
  matchcontinue (condition, helpVarInfo, nHelpVar)
    local
      Integer hindex,nh;
      DAE.Exp e;
      list<HelpVarInfo> newHelpVar,restHelpVarInfo;
      Absyn.Path name;
      list<DAE.Exp> args_;
      Boolean tup,builtin_;
      DAE.ExpType exty;
      DAE.InlineType inty;
      DAE.CallAttributes attr;
    // if no HelpVar created yet, create one
    case (condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr), {}, nh)
      equation
        nh = nh + 1;
        args_ = listAppend(args_,{DAE.ICONST(nh)});
        condition = DAE.CALL(name, args_, attr);
        //Error.addMessage(Error.INTERNAL_ERROR, {"Could not find help var index for Sample condition"});
      then ((condition,nh),{(nh,condition,-1)});
    case (condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr), (hindex, e, _) :: restHelpVarInfo,_)
      equation
        args_ = listAppend(args_,{DAE.ICONST(hindex)});
        condition = DAE.CALL(name, args_, attr);
        true = Expression.expEqual(condition, e);
      then ((condition, hindex),{});
    case (condition, (hindex, e, _) :: restHelpVarInfo,nh)
      equation
        false = Expression.expEqual(condition, e);
        (conditionAndHindex, newHelpVar) = addHForConditionSample(condition, restHelpVarInfo,nh);
      then (conditionAndHindex,newHelpVar);
  end matchcontinue;
end addHForConditionSample;

protected function createZeroCrossings
  input BackendDAE.BackendDAE dlow;
  output list<BackendDAE.ZeroCrossing> zc;
algorithm
  zc := matchcontinue (dlow)
    
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst=zc))))
    then
      zc;
  
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createZeroCrossings failed"});
      then
        fail();
  end matchcontinue;
end createZeroCrossings;

protected function createZeroCrossingsNeedSave
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  input BackendDAE.BackendDAE dlow;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.StrongComponents blocks;
  output list<list<SimVar>> needSave;
algorithm
  needSave := match (zeroCrossings, dlow, ass1, ass2, blocks)
    local
      BackendDAE.ZeroCrossing zc;
      list<BackendDAE.ZeroCrossing> rest_zc;
      list<Integer> eql;
      list<SimVar> needSaveTmp;
      list<list<SimVar>> needSave_rest;
      
    case ({}, _, _, _, _) then {};
      
    case ((zc as BackendDAE.ZERO_CROSSING(occurEquLst=eql)) :: rest_zc, dlow, ass1, ass2, blocks)
      equation
        needSaveTmp = createZeroCrossingNeedSave(dlow, ass1, ass2, eql, blocks);
        needSave_rest = createZeroCrossingsNeedSave(rest_zc, dlow, ass1, ass2, blocks);
      then 
        needSaveTmp :: needSave_rest;
        
  end match;
end createZeroCrossingsNeedSave;

protected function createZeroCrossingNeedSave
  input BackendDAE.BackendDAE dlow;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> eqns2;
  input BackendDAE.StrongComponents blocks;
  output list<SimVar> needSave;
algorithm
  needSave := matchcontinue (dlow, ass1, ass2, eqns2, blocks)
    local
      list<SimVar> crs;
      Integer eqn_1,v,eqn;
      BackendDAE.StrongComponent block_;
      list<Integer> rest;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars, knvars,exvars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<Algorithm.Algorithm> al;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Var dlowvar;
      SimVar simvar;
      
      // handle empty
    case (_,_,_,{},_) then {};
      
      // zero crossing for mixed system
    case ((dlow as BackendDAE.DAE(eqs = BackendDAE.EQSYSTEM(orderedVars=vars)::{}, shared=BackendDAE.SHARED(knownVars = knvars))),
      ass1, ass2, (eqn :: rest), blocks)
      equation
        true = isPartOfMixedSystem(dlow, eqn, blocks, ass2);
        block_ = getZcMixedSystem(dlow, eqn, blocks, ass2);
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (dlowvar as BackendDAE.VAR(varName = cr)) = BackendVariable.getVarAt(vars, v);
        crs = createZeroCrossingNeedSave(dlow, ass1, ass2, rest, blocks);
        simvar = dlowvarToSimvar(dlowvar,NONE(),knvars);
      then
        (simvar :: crs);
        
        // zero crossing for single equation
    case ((dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars)::{}, shared=BackendDAE.SHARED(knownVars = knvars))), ass1, ass2,
        (eqn :: rest), blocks)
      equation
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (dlowvar as BackendDAE.VAR(varName = cr)) = BackendVariable.getVarAt(vars, v);
        crs = createZeroCrossingNeedSave(dlow, ass1, ass2, rest, blocks);
        simvar = dlowvarToSimvar(dlowvar,NONE(),knvars);
      then
        (simvar :: crs);
        
        // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.createZeroCrossingNeedSave failed"});
      then
        fail();
  end matchcontinue;
end createZeroCrossingNeedSave;

protected function createModelInfo
  input Absyn.Path class_;
  input BackendDAE.BackendDAE dlow;
  input list<Function> functions;
  input Integer numHelpVars;
  input Integer numResiduals;
  input String fileDir;
  input Boolean ifcpp;
  output ModelInfo modelInfo;
algorithm
  modelInfo :=
  matchcontinue (class_, dlow, functions, numHelpVars, numResiduals, fileDir,ifcpp)
    local
      String directory;
      VarInfo varInfo;
      SimVars vars;
      list<SimVar> stateVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> stringAliasVars;
      list<SimVar> extObjVars;
      list<SimVar> jacobianVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
      Integer nx,ny,np,na,next,numOutVars,numInVars,ny_int,np_int,na_int,ny_bool,np_bool,dim_1,dim_2;
      Integer na_bool,ny_string,np_string,na_string;
      list<SimVar> states1,states_lst,states_lst2,der_states_lst;
      list<SimVar> states_2,derivatives_2,derivative;
    
    case (class_, dlow, functions, numHelpVars, numResiduals, fileDir, true)
      equation
        //name = Absyn.pathStringNoQual(class_);
        directory = System.trim(fileDir, "\"");
        (vars as SIMVARS(stateVars=stateVars,derivativeVars=derivative,algVars=algVars,intAlgVars=intAlgVars,boolAlgVars=boolAlgVars,
                       inputVars=inputVars,outputVars=outputVars,aliasVars=aliasVars,intAliasVars=intAliasVars,boolAliasVars=boolAliasVars,
                       paramVars=paramVars,intParamVars=intParamVars,boolParamVars=boolParamVars,stringAlgVars=stringAlgVars,stringParamVars=stringParamVars,
                       stringAliasVars=stringAliasVars,extObjVars=extObjVars,jacobianVars=jacobianVars,constVars=constVars,intConstVars=intConstVars,boolConstVars=boolConstVars,stringConstVars=stringConstVars))=createVars(dlow);
        nx = listLength(stateVars);
        ny = listLength(algVars);
        ny_int = listLength(intAlgVars);
        ny_bool = listLength(boolAlgVars);
        numOutVars = listLength(outputVars);
        numInVars = listLength(inputVars);
        na = listLength(aliasVars);
        na_int = listLength(intAliasVars);
        na_bool = listLength(boolAliasVars);
        np = listLength(paramVars);
        np_int = listLength(intParamVars);
        np_bool = listLength(boolParamVars);
        ny_string = listLength(stringAlgVars);
        np_string = listLength(stringParamVars);
        na_string = listLength(stringAliasVars);
        next = listLength(extObjVars);
        (dim_1,dim_2)= dimensions(dlow);
        varInfo = createVarInfo(dlow,nx, ny, np, na, next, numOutVars, numInVars, numHelpVars, numResiduals,
                 ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,dim_1,dim_2);
         states1 = stateindex1(stateVars,dlow);
         states_lst= setStatesVectorIndex(states1);
         der_states_lst = generateDerStates(states_lst);
         states_lst2 =listAppend(states_lst,der_states_lst);
         states_2 = replaceindex1(stateVars,states_lst);
          //Debug.fcall("cppvar",print," replace der varibales: \n " +&dumpVarinfoList(states_lst2));
         derivatives_2=replaceindex1(derivative,der_states_lst);
         //Debug.fcall("cppvar",print,"state varibales: \n " +&dumpVarinfoList(states_lst2));
      then
        MODELINFO(class_, directory, varInfo, SIMVARS(states_2,derivatives_2,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,
                  intAliasVars,boolAliasVars,paramVars,intParamVars,boolParamVars,stringAlgVars,stringParamVars,stringAliasVars,extObjVars,jacobianVars,constVars,intConstVars,boolConstVars,stringConstVars), 
                  functions);
    
    case (class_, dlow, functions, numHelpVars, numResiduals, fileDir, false)
      equation
        //name = Absyn.pathStringNoQual(class_);
        directory = System.trim(fileDir, "\"");
        vars = createVars(dlow);
        SIMVARS(stateVars=stateVars,algVars=algVars,intAlgVars=intAlgVars,boolAlgVars=boolAlgVars,
                inputVars=inputVars,outputVars=outputVars,aliasVars=aliasVars,intAliasVars=intAliasVars,boolAliasVars=boolAliasVars,
                paramVars=paramVars,intParamVars=intParamVars,boolParamVars=boolParamVars,stringAlgVars=stringAlgVars,
                stringParamVars=stringParamVars,stringAliasVars=stringAliasVars,extObjVars=extObjVars,constVars=constVars,intConstVars=intConstVars,boolConstVars=boolConstVars,stringConstVars=stringConstVars) = vars;
        nx = listLength(stateVars);
        ny = listLength(algVars);
        ny_int = listLength(intAlgVars);
        ny_bool = listLength(boolAlgVars);
        numOutVars = listLength(outputVars);
        numInVars = listLength(inputVars);
        na = listLength(aliasVars);
        na_int = listLength(intAliasVars);
        na_bool = listLength(boolAliasVars);
        np = listLength(paramVars);
        np_int = listLength(intParamVars);
        np_bool = listLength(boolParamVars);
        ny_string = listLength(stringAlgVars);
        np_string = listLength(stringParamVars);
        na_string = listLength(stringAliasVars);
        next = listLength(extObjVars);
        varInfo = createVarInfo(dlow,nx, ny, np, na, next, numOutVars, numInVars, numHelpVars, numResiduals,
                 ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,0,0);
      then
        MODELINFO(class_, directory, varInfo, vars, functions);
    
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.createModelInfo failed"});
      then
        fail();
  end matchcontinue;
end createModelInfo;


protected function createVarInfo
  input BackendDAE.BackendDAE dlow;
  input Integer nx;
  input Integer ny;
  input Integer np;
  input Integer na;
  input Integer next;
  input Integer numOutVars;
  input Integer numInVars;
  input Integer numHelpVars;
  input Integer numResiduals;
  input Integer ny_int;
  input Integer np_int;
  input Integer na_int;
  input Integer ny_bool;
  input Integer np_bool;
  input Integer na_bool;
  input Integer ny_string;
  input Integer np_string;
  input Integer na_string;
  input Integer dim_1;
  input Integer dim_2;
  output VarInfo varInfo;
algorithm
  varInfo :=
  matchcontinue (dlow, nx, ny, np, na, next, numOutVars, numInVars, numHelpVars, numResiduals,
                 ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,dim_1,dim_2)
    local
      Integer ng, ng_sam, ng_sam_1, ng_1;
      String s1,s2;
    case (dlow, nx, ny, np, na, next, numOutVars, numInVars, numHelpVars, numResiduals,
                 ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,dim_1,dim_2)
      equation
        (ng, ng_sam) = BackendDAEUtil.numberOfZeroCrossings(dlow);
        ng_1 = filterNg(ng);
        ng_sam_1 = filterNg(ng_sam);
      then
        VARINFO(numHelpVars, ng_1, ng_sam_1, nx, ny, ny_int, ny_bool, na, na_int, na_bool, np, np_int, np_bool, numOutVars, numInVars,
          numResiduals, next, ny_string, np_string, na_string, 0,SOME(dim_1),SOME(dim_2));
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createVarInfoCPP failed"});
      then
        fail();
  end matchcontinue;
end createVarInfo;

protected function createVars
  input BackendDAE.BackendDAE dlow;
  output SimVars varsOut;
algorithm
  varsOut :=
  match (dlow)
    local
      BackendDAE.Variables vars;
      BackendDAE.Variables knvars;
      BackendDAE.Variables removedvars;
      BackendDAE.Variables extvars;
      BackendDAE.EquationArray ie;
      BackendDAE.AliasVariables aliasVars;
      list<DAE.ComponentRef> initCrefs;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars)::{},shared=BackendDAE.SHARED(
      knownVars = knvars, initialEqs=ie,
      externalObjects = extvars,
      aliasVars = aliasVars as BackendDAE.ALIASVARS(aliasVars = removedvars))))
      equation
        /* Extract from variable list */  
        ((varsOut,_,_)) = BackendVariable.traverseBackendDAEVars(vars,extractVarsFromList,(SIMVARS({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},{},{},{},{},{},{},{},{},{},{}),aliasVars,knvars));
        /* Extract from known variable list */
        ((varsOut,_,_)) = BackendVariable.traverseBackendDAEVars(knvars,extractVarsFromList,(varsOut,aliasVars,knvars));
        /* Extract from removed variable list */
        ((varsOut,_,_)) = BackendVariable.traverseBackendDAEVars(removedvars,extractVarsFromList,(varsOut,aliasVars,knvars));
        /* Extract from external object list */
        ((varsOut,_,_)) = BackendVariable.traverseBackendDAEVars(extvars,extractVarsFromList,(varsOut,aliasVars,knvars));
        /* sort variables on index */
        varsOut = sortSimvarsOnIndex(varsOut);
        /* Index of algebraic and parameters need 
         to fix due to separation of int Vars*/
        varsOut = fixIndex(varsOut);
        /* fix the initial thing */
        initCrefs = BackendEquation.getAllCrefFromEquations(ie);
        varsOut = fixInitialThing(varsOut, initCrefs);
      then
        varsOut;
  end match;
end createVars;

protected function extractVarsFromList
  input tuple<BackendDAE.Var, tuple<SimVars,BackendDAE.AliasVariables,BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<SimVars,BackendDAE.AliasVariables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:= matchcontinue (inTpl)      
    local
      BackendDAE.Var var;
      SimVars vars,varsTmp1,varsTmp2;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.Variables v;
    case ((var,(vars,aliasVars,v)))
      equation
        varsTmp1 = extractVarFromVar(var,aliasVars,v);
        varsTmp2 = mergeVars(varsTmp1, vars);
      then
        ((var,(varsTmp2,aliasVars,v)));
    case (inTpl) then inTpl;
  end matchcontinue;
end extractVarsFromList;

// one dlow var can result in multiple simvars: input and output are a subset
// of algvars for example
protected function extractVarFromVar
  input BackendDAE.Var dlowVar;
  input BackendDAE.AliasVariables inAliasVars;
  input BackendDAE.Variables inVars;
  output SimVars varsOut;
algorithm
  varsOut :=
  match (dlowVar,inAliasVars,inVars)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> stringAliasVars;
      list<SimVar> extObjVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
      SimVar simvar;
      SimVar derivSimvar;
      BackendDAE.Variables v;
      Boolean isalias;
    case (dlowVar,inAliasVars,v)
      equation
        /* start with empty lists */
        stateVars = {};
        derivativeVars = {};
        algVars = {};
        intAlgVars = {};
        boolAlgVars = {};
        inputVars = {};
        outputVars = {};
        aliasVars = {};
        intAliasVars = {};
        boolAliasVars = {};
        paramVars = {};
        intParamVars = {};
        boolParamVars = {};
        stringAlgVars = {};
        stringParamVars = {};
        stringAliasVars = {};
        extObjVars = {};
        constVars = {};
        intConstVars = {};
        boolConstVars = {};
        stringConstVars = {};
        /* extract the sim var */
        simvar = dlowvarToSimvar(dlowVar,SOME(inAliasVars),v);
        derivSimvar = derVarFromStateVar(simvar);
        isalias = isAliasVar(simvar);
        /* figure out in which lists to put it */
        stateVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isStateVar(dlowVar), simvar, stateVars);
        derivativeVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isStateVar(dlowVar), derivSimvar, derivativeVars);
        algVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarAlg(dlowVar), simvar, algVars);
        intAlgVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarIntAlg(dlowVar), simvar, intAlgVars);
        boolAlgVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarBoolAlg(dlowVar), simvar, boolAlgVars);
        inputVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarOnTopLevelAndInput(dlowVar), simvar, inputVars);
        outputVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarOnTopLevelAndOutput(dlowVar), simvar, outputVars);
        paramVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarParam(dlowVar), simvar, paramVars);
        intParamVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarIntParam(dlowVar), simvar, intParamVars);
        boolParamVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarBoolParam(dlowVar), simvar, boolParamVars);
        stringAlgVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarStringAlg(dlowVar), simvar, stringAlgVars);
        stringParamVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarStringParam(dlowVar), simvar, stringParamVars);
        extObjVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isExtObj(dlowVar), simvar, extObjVars);
        aliasVars = addSimvarIfTrue( isalias and
          BackendVariable.isVarAlg(dlowVar), simvar, aliasVars);
        intAliasVars = addSimvarIfTrue( isalias and
          BackendVariable.isVarIntAlg(dlowVar), simvar, intAliasVars);
        boolAliasVars = addSimvarIfTrue( isalias and
          BackendVariable.isVarBoolAlg(dlowVar), simvar, boolAliasVars);
        stringAliasVars = addSimvarIfTrue( isalias and
          BackendVariable.isVarStringAlg(dlowVar), simvar, stringAliasVars);
        constVars =addSimvarIfTrue((not isalias) and
          BackendVariable.isVarConst(dlowVar), simvar, constVars);
        intConstVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarIntConst(dlowVar), simvar, intConstVars);
        boolConstVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarBoolConst(dlowVar), simvar, boolConstVars);
        stringConstVars = addSimvarIfTrue((not isalias) and
          BackendVariable.isVarStringConst(dlowVar), simvar, stringConstVars);
      then
        SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars,
          aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
          stringAlgVars, stringParamVars, stringAliasVars, extObjVars,{},constVars,intConstVars,boolConstVars,stringConstVars);
  end match;
end extractVarFromVar;

protected function derVarFromStateVar
  input SimVar state;
  output SimVar deriv;
algorithm
  deriv :=
  match (state)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind kind;
      String comment, unit, displayUnit;
      Integer index;
      Option<DAE.Exp> initVal, nomVal;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      DAE.ComponentRef arrayCref;
      DAE.ElementSource source;
      Option<Integer> variable_index;
      list <String> numArrayElement;
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, nomVal, isFixed, type_, isDiscrete, NONE(),_, source,_,NONE(),numArrayElement))
      equation
        name = ComponentReference.crefPrefixDer(name);
      then
        SIMVAR(name, BackendDAE.STATE_DER(), comment, unit, displayUnit, index, NONE(), nomVal, isFixed, type_, isDiscrete, NONE(), NOALIAS(), source, INTERNAL(),NONE(),numArrayElement);
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, nomVal, isFixed, type_, isDiscrete, SOME(arrayCref),_, source,_,NONE(),numArrayElement))
      equation
        name = ComponentReference.crefPrefixDer(name);
        arrayCref = ComponentReference.crefPrefixDer(arrayCref);
      then
        SIMVAR(name, BackendDAE.STATE_DER(), comment, unit, displayUnit, index, NONE(), nomVal, isFixed, type_, isDiscrete, SOME(arrayCref), NOALIAS(), source, INTERNAL(),NONE(),numArrayElement);
  end match;
end derVarFromStateVar;


protected function dumpVar
  input SimVar inVar;
algorithm
  _ := matchcontinue(inVar)
  local
    DAE.ComponentRef name,name2;
    AliasVariable aliasvar;
    String s1,s2;
    case (SIMVAR(name= name, aliasvar = NOALIAS()))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        print(" No Alias for var : " +& s1 +& "\n");
     then ();
    case (SIMVAR(name= name, aliasvar = ALIAS(varName = name2)))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        s2 = ComponentReference.printComponentRefStr(name2);
        print(" Alias for var " +& s1 +& " is " +& s2 +& "\n");
    then ();
    case (SIMVAR(name= name, aliasvar = NEGATEDALIAS(varName = name2)))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        s2 = ComponentReference.printComponentRefStr(name2);
        print(" Minus Alias for var " +& s1 +& " is " +& s2 +& "\n");
     then ();
   end matchcontinue;
end dumpVar;

protected function addSimvarIfTrue
  input Boolean condition;
  input SimVar var;
  input list<SimVar> lst;
  output list<SimVar> res;
algorithm
  res :=
  match (condition, var, lst)
    case (true, var, lst)
    then (var :: lst);
    case (false, var, lst)
    then lst;
  end match;
end addSimvarIfTrue;

protected function isAliasVar
  input SimVar var;
  output Boolean res;
algorithm
  res :=
  match (var)
    case (SIMVAR(aliasvar=NOALIAS()))
    then false;
  else
    then true;
  end match;
end isAliasVar;

protected function mergeVars
  input SimVars vars1;
  input SimVars vars2;
  output SimVars varsResult;
algorithm
  varsResult :=
  matchcontinue (vars1, vars2)
    local
      list<SimVar> stateVars, stateVars1, stateVars2;
      list<SimVar> derivativeVars, derivativeVars1, derivativeVars2;
      list<SimVar> algVars, algVars1, algVars2;
      list<SimVar> intAlgVars, intAlgVars1, intAlgVars2;
      list<SimVar> boolAlgVars, boolAlgVars1, boolAlgVars2;
      list<SimVar> inputVars, inputVars1, inputVars2;
      list<SimVar> outputVars, outputVars1, outputVars2;
      list<SimVar> paramVars, paramVars1, paramVars2;
      list<SimVar> aliasVars, intAliasVars, boolAliasVars, stringAliasVars;
      list<SimVar> aliasVars1, intAliasVars1, boolAliasVars1, stringAliasVars1;
      list<SimVar> aliasVars2, intAliasVars2, boolAliasVars2, stringAliasVars2;
      list<SimVar> intParamVars, intParamVars1, intParamVars2;
      list<SimVar> boolParamVars, boolParamVars1, boolParamVars2;
      list<SimVar> stringAlgVars, stringAlgVars1, stringAlgVars2;
      list<SimVar> stringParamVars, stringParamVars1, stringParamVars2;
      list<SimVar> extObjVars, extObjVars1, extObjVars2;
      list<SimVar> jacVars, jacVars1, jacVars2;
      list<SimVar> constVars, constVars1, constVars2;
      list<SimVar> intConstVars, intConstVars1, intConstVars2;
      list<SimVar> boolConstVars, boolConstVars1, boolConstVars2;
      list<SimVar> stringConstVars, stringConstVars1, stringConstVars2;
    case (SIMVARS(stateVars1, derivativeVars1, algVars1, intAlgVars1, boolAlgVars1, inputVars1,
           outputVars1, aliasVars1, intAliasVars1, boolAliasVars1, paramVars1, intParamVars1, boolParamVars1,
           stringAlgVars1, stringParamVars1, stringAliasVars1, extObjVars1,jacVars1,constVars1,intConstVars1,boolConstVars1,stringConstVars1),
      SIMVARS(stateVars2, derivativeVars2, algVars2, intAlgVars2, boolAlgVars2, inputVars2,
           outputVars2, aliasVars2, intAliasVars2, boolAliasVars2, paramVars2, intParamVars2, boolParamVars2,
           stringAlgVars2, stringParamVars2,stringAliasVars2,extObjVars2,jacVars2,constVars2,intConstVars2,boolConstVars2,stringConstVars2))
      equation
        stateVars = listAppend(stateVars1, stateVars2);
        derivativeVars = listAppend(derivativeVars1, derivativeVars2);
        algVars = listAppend(algVars1, algVars2);
        intAlgVars = listAppend(intAlgVars1, intAlgVars2);
        boolAlgVars = listAppend(boolAlgVars1, boolAlgVars2);
        inputVars = listAppend(inputVars1, inputVars2);
        outputVars = listAppend(outputVars1, outputVars2);
        aliasVars = listAppend(aliasVars1, aliasVars2);
        intAliasVars = listAppend(intAliasVars1, intAliasVars2);
        boolAliasVars = listAppend(boolAliasVars1, boolAliasVars2);
        paramVars = listAppend(paramVars1, paramVars2);
        intParamVars = listAppend(intParamVars1, intParamVars2);
        boolParamVars = listAppend(boolParamVars1, boolParamVars2);
        stringAlgVars = listAppend(stringAlgVars1, stringAlgVars2);
        stringParamVars = listAppend(stringParamVars1, stringParamVars2);
        stringAliasVars = listAppend(stringAliasVars1, stringAliasVars2);
        extObjVars = listAppend(extObjVars1, extObjVars2);
        jacVars = listAppend(jacVars1, jacVars2);
        constVars = listAppend(constVars1, constVars2);
        intConstVars = listAppend(intConstVars1, intConstVars2);
        boolConstVars = listAppend(boolConstVars1, boolConstVars2);
        stringConstVars = listAppend(stringConstVars1, stringConstVars2);
      then
        SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars,
          aliasVars,intAliasVars,boolAliasVars,paramVars,intParamVars,boolParamVars,
          stringAlgVars, stringParamVars, stringAliasVars, extObjVars,jacVars,constVars,intConstVars,boolConstVars,stringConstVars);
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"mergeVars failed"});
      then
        fail();
  end matchcontinue;
end mergeVars;

protected function sortSimvarsOnIndex
  input SimVars unsortedSimvars;
  output SimVars sortedSimvars;
algorithm
  sortedSimvars :=
  match (unsortedSimvars)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> stringAliasVars;
      list<SimVar> extObjVars;
      list<SimVar> jacVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
    case (SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars,jacVars,constVars,intConstVars,boolConstVars,stringConstVars))
      equation
        stateVars = Util.sort(stateVars, varIndexComparer);
        derivativeVars = Util.sort(derivativeVars, varIndexComparer);
        algVars = Util.sort(algVars, varIndexComparer);
        intAlgVars = Util.sort(intAlgVars, varIndexComparer);
        boolAlgVars = Util.sort(boolAlgVars, varIndexComparer);
        inputVars = Util.sort(inputVars, varIndexComparer);
        outputVars = Util.sort(outputVars, varIndexComparer);
        aliasVars = Util.sort(aliasVars, varIndexComparer);
        intAliasVars = Util.sort(intAliasVars, varIndexComparer);
        boolAliasVars = Util.sort(boolAliasVars, varIndexComparer);
        paramVars = Util.sort(paramVars, varIndexComparer);
        intParamVars = Util.sort(intParamVars, varIndexComparer);
        boolParamVars = Util.sort(boolParamVars, varIndexComparer);
        stringAlgVars = Util.sort(stringAlgVars, varIndexComparer);
        stringParamVars = Util.sort(stringParamVars, varIndexComparer);
        stringAliasVars = Util.sort(stringAliasVars, varIndexComparer);
        extObjVars = Util.sort(extObjVars, varIndexComparer);
        jacVars = Util.sort(jacVars, varIndexComparer);
        constVars = Util.sort(constVars, varIndexComparer);
        intConstVars = Util.sort(intConstVars, varIndexComparer);
        boolConstVars = Util.sort(boolConstVars, varIndexComparer);
        stringConstVars = Util.sort(stringConstVars, varIndexComparer);
        
      then SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
        outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
        stringAlgVars, stringParamVars, stringAliasVars, extObjVars,jacVars,constVars,intConstVars,boolConstVars,stringConstVars);
  end match;
end sortSimvarsOnIndex;

protected function fixIndex
  input SimVars unfixedSimvars;
  output SimVars fixedSimvars;
algorithm
  fixedSimvars := match (unfixedSimvars)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> stringAliasVars;
      list<SimVar> extObjVars;
      list<SimVar> jacVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
  
      
    case (SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars,jacVars,constVars,intConstVars,boolConstVars,stringConstVars))
      equation
        algVars = rewriteIndex(algVars, 0);
        intAlgVars = rewriteIndex(intAlgVars,0);
        boolAlgVars = rewriteIndex(boolAlgVars,0);
        paramVars = rewriteIndex(paramVars, 0);
        intParamVars = rewriteIndex(intParamVars, 0);
        boolParamVars = rewriteIndex(boolParamVars, 0);
        aliasVars = rewriteIndex(aliasVars, 0);
        intAliasVars = rewriteIndex(intAliasVars, 0);
        boolAliasVars = rewriteIndex(boolAliasVars, 0);
        stringAlgVars = rewriteIndex(stringAlgVars, 0);
        stringParamVars = rewriteIndex(stringParamVars, 0);
        stringAliasVars = rewriteIndex(stringAliasVars, 0);
        jacVars = rewriteIndex(jacVars, 0);
        constVars = rewriteIndex(constVars, 0);
        intConstVars = rewriteIndex(intConstVars, 0);
        boolConstVars = rewriteIndex(boolConstVars, 0);
        stringConstVars = rewriteIndex(stringConstVars, 0);
      then SIMVARS(stateVars, derivativeVars, algVars,intAlgVars, boolAlgVars, inputVars,
        outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
        stringAlgVars, stringParamVars, stringAliasVars, extObjVars,jacVars,constVars,intConstVars,boolConstVars,stringConstVars);
  end match;
end fixIndex;

protected function rewriteIndex
  input list<SimVar> inVars;
  input Integer index;
  output list<SimVar> outVars;
algorithm 
  outVars :=
  match(inVars,index)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind kind;
      String comment, unit, displayUnit;
      Option<DAE.Exp> initVal, nomVal;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      Integer index_;
      AliasVariable aliasvar;
      list<SimVar> rest,rest2;
      DAE.ElementSource source;
      Causality causality;
      Option<Integer> variable_index;
      list <String> numArrayElement;
    case ({},_) then {};
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement)::rest,index_)
      equation
        rest2 = rewriteIndex(rest, index_ + 1);
      then (SIMVAR(name, kind, comment, unit, displayUnit, index_, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement)::rest2);
  end match;
end rewriteIndex;

protected function varIndexComparer
  input SimVar lhs;
  input SimVar rhs;
  output Boolean res;
algorithm
  res :=
  match (lhs, rhs)
    local
      Integer lhsIndex;
      Integer rhsIndex;
    case (SIMVAR(index=lhsIndex), SIMVAR(index=rhsIndex))
    then rhsIndex < lhsIndex;
  end match;
end varIndexComparer;

protected function fixInitialThing
  input SimVars simvarsIn;
  input list<DAE.ComponentRef> initCrefs;
  output SimVars simvarsOut;
algorithm
  simvarsOut :=
  matchcontinue (simvarsIn, initCrefs)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> aliasVars;
      list<SimVar> intAliasVars;
      list<SimVar> boolAliasVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> stringAliasVars;
      list<SimVar> extObjVars;
      list<SimVar> jacVars;
      list<SimVar> constVars;
      list<SimVar> intConstVars;
      list<SimVar> boolConstVars;
      list<SimVar> stringConstVars;
      /* no initial equations so nothing to do */
    case (_, {}) then simvarsIn;
    case (SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars, 
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars,jacVars,constVars,intConstVars,boolConstVars,stringConstVars), initCrefs)
      equation
        true = Util.listMapAllValue(stateVars, simvarFixed,true);
        stateVars = Util.listMap1(stateVars, nonFixifyIfHasInit, initCrefs);
      then SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
        outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars, 
        stringAlgVars, stringParamVars, stringAliasVars, extObjVars,jacVars,constVars,intConstVars,boolConstVars,stringConstVars);
      /* not all were fixed so nothing to do */
    else simvarsIn;
  end matchcontinue;
end fixInitialThing;

protected function simvarFixed
  input SimVar simvar;
  output Boolean fixed_;
algorithm
  fixed_ :=
  match (simvar)
    case (SIMVAR(isFixed=fixed_)) then fixed_;
    case (_) then fail();
  end match;
end simvarFixed;

protected function nonFixifyIfHasInit
  input SimVar simvarIn;
  input list<DAE.ComponentRef> initCrefs;
  output SimVar simvarOut;
algorithm
  simvarOut :=
  matchcontinue (simvarIn, initCrefs)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind kind;
      String comment, unit, displayUnit;
      Integer index;
      Option<DAE.Exp> initVal, nomVal;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      AliasVariable aliasvar;
      String varNameStr;
      DAE.ElementSource source;
      Absyn.Info info;
      Causality causality;
      Option<Integer> variable_index;
      list <String> numArrayElement;
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement), initCrefs)
      equation
        (_ :: _) = Util.listSelect1(initCrefs, name, ComponentReference.crefEqualNoStringCompare);
        varNameStr = ComponentReference.printComponentRefStr(name);
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.SETTING_FIXED_ATTRIBUTE, {varNameStr}, info);
      then SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, nomVal, false, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement);
    case (_, _) then simvarIn;
  end matchcontinue;
end nonFixifyIfHasInit;


protected function createCrefToSimVarHT
  input ModelInfo modelInfo;
  output HashTableCrefToSimVar outHT;
algorithm
  outHT :=  matchcontinue (modelInfo)
    local
      HashTableCrefToSimVar ht;
      list<SimVar> stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, aliasVars, intAliasVars, boolAliasVars, stringAliasVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, extObjVars,constVars,intConstVars,boolConstVars,stringConstVars;
    case (MODELINFO(vars = SIMVARS(
      stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, 
      _/*inputVars*/, _/*outputVars*/, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars, 
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars,constVars,intConstVars,boolConstVars,stringConstVars,_)))
      equation
        ht = emptyHashTable();
        ht = Util.listFold(stateVars, addSimVarToHashTable, ht);
        ht = Util.listFold(derivativeVars, addSimVarToHashTable, ht);
        ht = Util.listFold(algVars, addSimVarToHashTable, ht);
        ht = Util.listFold(intAlgVars, addSimVarToHashTable, ht);
        ht = Util.listFold(boolAlgVars, addSimVarToHashTable, ht);
        ht = Util.listFold(paramVars, addSimVarToHashTable, ht);
        ht = Util.listFold(intParamVars, addSimVarToHashTable, ht);
        ht = Util.listFold(boolParamVars, addSimVarToHashTable, ht);
        ht = Util.listFold(aliasVars, addSimVarToHashTable, ht);
        ht = Util.listFold(intAliasVars, addSimVarToHashTable, ht);
        ht = Util.listFold(boolAliasVars, addSimVarToHashTable, ht);
        ht = Util.listFold(stringAlgVars, addSimVarToHashTable, ht);
        ht = Util.listFold(stringParamVars, addSimVarToHashTable, ht);
        ht = Util.listFold(stringAliasVars, addSimVarToHashTable, ht);
        ht = Util.listFold(extObjVars, addSimVarToHashTable, ht);
        ht = Util.listFold(constVars, addSimVarToHashTable, ht);
        ht = Util.listFold(intConstVars, addSimVarToHashTable, ht);
        ht = Util.listFold(boolConstVars, addSimVarToHashTable, ht);
        ht = Util.listFold(stringConstVars, addSimVarToHashTable, ht);
      then
        ht;
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createCrefToSimVarHT failed"});
      then
        fail();
  end matchcontinue;
end createCrefToSimVarHT;

protected function addSimVarToHashTable
  input SimVar simvarIn;
  input  HashTableCrefToSimVar inHT;
  output HashTableCrefToSimVar outHT;
algorithm
  outHT :=
  matchcontinue (simvarIn, inHT)
    local
      DAE.ComponentRef cr, acr;
      SimVar sv;
      
    case (sv as SIMVAR(name = cr, arrayCref = NONE()), inHT)
      equation
        outHT = add((cr,sv), inHT);
      then outHT;
        //add the whole array crefs to the hashtable, too
    case (sv as SIMVAR(name = cr, arrayCref = SOME(acr)), inHT)
      equation
        outHT = add((acr,sv), inHT);
        outHT = add((cr,sv), outHT);
      then outHT;
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"addSimVarToHashTable failed"});
      then
        fail();
  end matchcontinue;
end addSimVarToHashTable;


protected function getAliasVar
  input BackendDAE.Var inVar;
  input Option<BackendDAE.AliasVariables> inAliasVars;
  output AliasVariable outAlias;
algorithm
  outAlias :=
  matchcontinue (inVar,inAliasVars)
    local
      DAE.ComponentRef name;
      BackendDAE.Variables aliasVars;
      BackendDAE.Var var;
      DAE.Exp e;
      AliasVariable alias;
    case (BackendDAE.VAR(varName=name),SOME(BackendDAE.ALIASVARS(aliasVars = aliasVars)))
      equation
        ((var :: _),_) = BackendVariable.getVar(name,aliasVars);
        // does not work
        //e = BaseHashTable.get(name,varMappings);
        e = BackendVariable.varBindExp(var);
        alias = getAliasVar1(e,var);
      then alias;
    case(_,_) then NOALIAS();
  end matchcontinue;
end getAliasVar;

protected function getAliasVar1
  input DAE.Exp inExp;
  input BackendDAE.Var inVar;
  output AliasVariable outAlias;
algorithm
  outAlias :=
  matchcontinue (inExp,inVar)
    local
      DAE.ComponentRef name;
      Absyn.Path fname;
    
    case (DAE.CREF(componentRef=name),inVar) then ALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CREF(componentRef=name)),inVar) then NEGATEDALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CREF(componentRef=name)),inVar) then NEGATEDALIAS(name);
    case (DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)}),inVar)
      equation
       true = BackendVariable.isDummyDerVar(inVar);
    then ALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})),inVar)
      equation
       true = BackendVariable.isDummyDerVar(inVar);
    then NEGATEDALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})),inVar)
      equation
       true = BackendVariable.isDummyDerVar(inVar);
    then NEGATEDALIAS(name);
    case (DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)}),inVar)
      equation
      Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then ALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})),inVar)
      equation
       Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then NEGATEDALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})),inVar)
      equation
       Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then NEGATEDALIAS(name);
    case(_,_) then NOALIAS();
  end matchcontinue;
end getAliasVar1;

protected function getArrayCref
  input BackendDAE.Var var;
  output Option<DAE.ComponentRef> arrayCref;
algorithm
  arrayCref :=
  matchcontinue (var)
    local
      DAE.ComponentRef name;
      DAE.ComponentRef arrayCrefInner;
    case (BackendDAE.VAR(varName=name))
      equation
        true = ComponentReference.crefIsFirstArrayElt(name);
        arrayCrefInner = ComponentReference.crefStripLastSubs(name);
      then SOME(arrayCrefInner);
    case (_)
    then NONE();
  end matchcontinue;
end getArrayCref;

protected function unparseCommentOptionNoAnnotationNoQuote
  input Option<SCode.Comment> absynComment;
  output String commentStr;
algorithm
  commentStr := matchcontinue (absynComment)
    case (SOME(SCode.COMMENT(_, SOME(commentStr)))) then commentStr;
    case (_) then "";
  end matchcontinue;
end unparseCommentOptionNoAnnotationNoQuote;

protected function generateHelpVarsForWhenStatements
  input list<HelpVarInfo> inHelpVarInfo;
  input BackendDAE.BackendDAE inBackendDAE;
  output list<HelpVarInfo> outHelpVarInfo;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  (outHelpVarInfo,outBackendDAE) :=
  matchcontinue (inHelpVarInfo,inBackendDAE)
    local
      list<HelpVarInfo> helpvars, helpvars1;
      BackendDAE.Variables orderedVars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables externalObjects;
      BackendDAE.AliasVariables aliasVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EquationArray removedEqs;
      BackendDAE.EquationArray initialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs;
      array<Algorithm.Algorithm> algorithms,algorithms2;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;
    case  (helpvars,BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,
      removedEqs,arrayEqs,algorithms,eventInfo,extObjClasses,btp)))
      equation
        (helpvars1,algorithms2,_) = generateHelpVarsInAlgorithms(listLength(helpvars),algorithms);
      then (listAppend(helpvars,helpvars1),BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,
        removedEqs,arrayEqs,algorithms2,eventInfo,extObjClasses,btp)));
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsForWhenStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsForWhenStatements;

protected function generateHelpVarsInAlgorithmsDispatch
  input Integer nextInd "Index of next help variable";
  input array<Algorithm.Algorithm> inAlgArr;
  input Integer index;
  input Integer sizeOfArr;
  input array<Algorithm.Algorithm> accAlgArr;
  output list<HelpVarInfo> outHelpVars;
  output array<Algorithm.Algorithm> outAlgArr;
  output Integer n2;
algorithm
  (outHelpVars,outAlgArr,n2) := matchcontinue(nextInd, inAlgArr, index, sizeOfArr, accAlgArr)
    local
      list<HelpVarInfo> helpVars,helpVars1,helpVars2;
      Integer i, n, nextInd1, nextInd2;
      list<Algorithm.Statement> stmts, stmts2;
      
      // stop the loop
    case (nextInd, inAlgArr, i, n, accAlgArr)
      equation
        false = intLt(i, n);
      then
        ({}, accAlgArr, nextInd);
        
        // loop body
    case (nextInd, inAlgArr, i, n, accAlgArr)
      equation
        true = intLt(i, n);
        //  get the element
        DAE.ALGORITHM_STMTS(stmts) = arrayGet(inAlgArr, i+1);
        (helpVars1,stmts2,nextInd1) = generateHelpVarsInStatements(nextInd,stmts);
        accAlgArr = arrayUpdate(accAlgArr, i+1, DAE.ALGORITHM_STMTS(stmts2));
        (helpVars2,accAlgArr,nextInd2) = generateHelpVarsInAlgorithmsDispatch(nextInd1, inAlgArr, i + 1, n, accAlgArr);
        helpVars = listAppend(helpVars1,helpVars2);
      then 
        (helpVars,accAlgArr,nextInd);
  end matchcontinue;
end generateHelpVarsInAlgorithmsDispatch;

protected function generateHelpVarsInAlgorithms
  input Integer nextInd "Index of next help variable";
  input array<Algorithm.Algorithm> inAlgArr;
  output list<HelpVarInfo> outHelpVars;
  output array<Algorithm.Algorithm> outAlgArr;
  output Integer n2;
algorithm
  (outHelpVars,outAlgArr,n2) := matchcontinue(nextInd,inAlgArr)
    local
      array<Algorithm.Algorithm> outArr;
      list<HelpVarInfo> helpVars;
      
    case (nextInd, inAlgArr)
      equation
        outArr = arrayCopy(inAlgArr);
        (helpVars,outArr,nextInd) = generateHelpVarsInAlgorithmsDispatch(nextInd, inAlgArr, 0, arrayLength(inAlgArr), outArr);
      then 
        (helpVars,outArr,nextInd);
        
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generateHelpVarsInAlgorithms failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInAlgorithms;

protected function generateHelpVarsInStatements
  input Integer n "Index of next help variable";
  input list<Algorithm.Statement> inStmtLst;
  output list<HelpVarInfo> outHelpVars;
  output list<Algorithm.Statement> outStmtLst;
  output Integer n1;
algorithm
  (outHelpVars,outStmtLst,n1) := matchcontinue(n,inStmtLst)
    local
      list<Algorithm.Statement> rest, rest1;
      Integer nextInd, nextInd1, nextInd2;
      Algorithm.Statement statement,statement1;
      list<HelpVarInfo> helpvars,helpvars1,helpvars2;
      
    case (nextInd, {}) then ({},{},nextInd);
      
    case (nextInd, statement::rest)
      equation
        (helpvars1,rest1,nextInd1) = generateHelpVarsInStatements(nextInd,rest);
        (helpvars2,statement1,nextInd2) = generateHelpVarsInStatement(nextInd1,statement);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,statement1::rest1,nextInd2);
        
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsInStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInStatements;

protected function generateHelpVarsInStatement
  input Integer n "Index of next help variable";
  input Algorithm.Statement inStmt;
  output list<HelpVarInfo> outHelpVars;
  output Algorithm.Statement outStmt;
  output Integer n1;
algorithm
  (outHelpVars,outStmt,n1) := matchcontinue(n,inStmt)
    local
      Integer nextInd, nextInd1, nextInd2;
      list<Integer> helpVarIndices, helpVarIndices1;
      DAE.Exp condition;
      list<DAE.Exp> el, el1;
      list<Algorithm.Statement> statementLst;
      Algorithm.Statement statement;
      Algorithm.Statement elseWhen;
      list<HelpVarInfo> helpvars,helpvars1,helpvars2;
      DAE.ExpType ty;
      Boolean scalar;
      DAE.ElementSource source;
      Absyn.Path name;
      list<DAE.Exp> args_;
      Boolean tup,builtin_;
      DAE.ExpType exty;
      DAE.InlineType inty;
      DAE.CallAttributes attr;
      
    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,NONE(),_,source))
      equation
        (helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
        helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
        helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
      then (helpvars1,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,NONE(),helpVarIndices,source),nextInd1);
        
    case (nextInd, DAE.STMT_WHEN(condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr),statementLst,NONE(),_,source))
      equation
        args_ = listAppend(args_,{DAE.ICONST(nextInd)});
        condition = DAE.CALL(name, args_, attr);
      then ({(nextInd,condition,-1)},DAE.STMT_WHEN(condition, statementLst,NONE(),{nextInd},source),nextInd+1);
        
    case (nextInd, DAE.STMT_WHEN(condition,statementLst,NONE(),_,source))
    then ({(nextInd,condition,-1)},DAE.STMT_WHEN(condition, statementLst,NONE(),{nextInd},source),nextInd+1);
        
    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,SOME(elseWhen),_,source))
      equation
        (helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
        helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
        helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
        (helpvars2,statement,nextInd2) = generateHelpVarsInStatement(nextInd1,elseWhen);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,SOME(statement),helpVarIndices,source),nextInd1);
        
    case (nextInd, DAE.STMT_WHEN(condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr),statementLst,SOME(elseWhen),_,source))
      equation
        args_ = listAppend(args_,{DAE.ICONST(nextInd)});
        condition = DAE.CALL(name, args_, attr);
        (helpvars1,statement,nextInd1) = generateHelpVarsInStatement(nextInd+1,elseWhen);
      then ((nextInd,condition,-1)::helpvars1,
          DAE.STMT_WHEN(condition, statementLst,SOME(statement),{nextInd},source),nextInd1);
        
    case (nextInd, DAE.STMT_WHEN(condition,statementLst,SOME(elseWhen),_,source))
      equation
        (helpvars1,statement,nextInd1) = generateHelpVarsInStatement(nextInd+1,elseWhen);
      then ((nextInd,condition,-1)::helpvars1,
          DAE.STMT_WHEN(condition, statementLst,SOME(statement),{nextInd},source),nextInd1);
        
    case (nextInd, statement) then ({},statement,nextInd);
        
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsInStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInStatement;

protected function generateHelpVarsInArrayCondition
  input Integer n "Index of next help variable";
  input list<DAE.Exp> inExp;
  output list<HelpVarInfo> outHelpVars;
  output list<DAE.Exp> outExp;
  output Integer n1;
algorithm
  (outHelpVars,outExp,n1) := matchcontinue(n,inExp)
    local
      list<DAE.Exp> rest,  el1;
      Integer nextInd, nextInd1;
      DAE.Exp condition;
      list<HelpVarInfo> helpvars1;
      Absyn.Path name;
      list<DAE.Exp> args_;
      Boolean tup,builtin_;
      DAE.ExpType exty;
      DAE.CallAttributes attr;
      
    case (nextInd, {}) then ({},{},nextInd);
      
    case (nextInd, ((condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr))::rest))
      equation
        args_ = listAppend(args_,{DAE.ICONST(nextInd)});
        condition = DAE.CALL(name, args_, attr);
        (helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd+1,rest);
      then ((nextInd,condition,-1)::helpvars1,condition::el1,nextInd1);
        
        
    case (nextInd, condition::rest)
      equation
        (helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd+1,rest);
      then ((nextInd,condition,-1)::helpvars1,condition::el1,nextInd1);
        
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsInArrayCondition failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInArrayCondition;

protected function selectContinuousEquations
"function selectContinuousEquations
  Returns only the equations that are solved for a continous variable."
  input tuple<BackendDAE.Equation, tuple<Integer,array<Integer>,BackendDAE.Variables,list<BackendDAE.Equation>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<Integer,array<Integer>,BackendDAE.Variables,list<BackendDAE.Equation>>> outTpl;
algorithm
  outTpl := matchcontinue (inTpl)
    local  
      BackendDAE.Variables vars;
      BackendDAE.Var var;
      Integer v,eqnIndx;
      Boolean b;
      BackendDAE.Equation e;
      array<Integer> ass2;
      list<BackendDAE.Equation> eqnLst,eqnLst1;
    case ((e,(eqnIndx,ass2,vars,eqnLst)))
      equation
        v = ass2[eqnIndx];
        var = BackendVariable.getVarAt(vars,v);
        b = BackendVariable.hasDiscreteVar({var});
        eqnLst1 = Util.listConsOnTrue(not b,e,eqnLst);
      then ((e,(eqnIndx+1,ass2,vars,eqnLst1)));
    case (inTpl) then inTpl;
  end matchcontinue;
end selectContinuousEquations;

protected function generateInitialEquationsFromStart "function: generateInitialEquationsFromStart
  This function generates equations from the expressions in the start
  attributes of variables. Only variables with a start value and
  fixed set to true is converted by this function. Fixed set to false
  means an initial guess, and is not considered here."
  input tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.AliasVariables>> inTpl;
  output tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.AliasVariables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)      
    local
      list<BackendDAE.Equation> eqns;
      BackendDAE.Var v;
      Expression.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.Exp e,startv;
      DAE.ExpType tp;
      Option<DAE.VariableAttributes> attr;
      DAE.ElementSource source;
      BackendDAE.AliasVariables av;
      
    case (((v as BackendDAE.VAR(varName = cr,varKind = kind,values = attr,source=source)),(eqns,av))) /* add equations for variables with fixed = true */
      equation
        NOALIAS() = getAliasVar(v,SOME(av));
        BackendVariable.isVarKindVariable(kind);
        true = BackendVariable.varFixed(v);
        true = DAEUtil.hasStartAttr(attr);
        //startv = DAEUtil.getStartAttr(attr);
        e = Expression.crefExp(cr);
        tp = Expression.typeof(e);
        startv = Expression.makeBuiltinCall("pre", {e}, tp);
      then
        ((v,(BackendDAE.EQUATION(e,startv,source)::eqns,av)));
    case (((v as BackendDAE.VAR(varName = cr,varKind = BackendDAE.STATE(),values = attr,source=source)),(eqns,av))) /* add equations for variables with fixed = true */
      equation
        NOALIAS() = getAliasVar(v,SOME(av));
        true = BackendVariable.varFixed(v);
        false = DAEUtil.hasStartAttr(attr);
        //startv = DAEUtil.getStartAttr(attr);
        e = Expression.crefExp(cr);
        tp = Expression.typeof(e);
        startv = Expression.makeBuiltinCall("pre", {e}, tp);
      then
        ((v,(BackendDAE.EQUATION(e,startv,source)::eqns,av)));
    case ((inTpl)) then inTpl;
  end matchcontinue;
end generateInitialEquationsFromStart;

protected function buildWhenConditionChecks3
" Helper function to build_when_condition_checks.
  Generates code for checking one equation of one when clause.
"
  input list<DAE.Exp> whenConditions   "List of expressions from \"when {exp1, exp2, ...}\" ";
  input Integer whenClauseIndex        "When clause index";
  input Integer nextHelpIndex          "Next available help variable index";
  input Boolean isElseWhen             "Whether this lase is an elsewhen or not";
  output String outString              "Generated c-code";
  output list<HelpVarInfo> helpVarLst;
algorithm
  (outString,helpVarLst):=
  matchcontinue (whenConditions,whenClauseIndex,nextHelpIndex,isElseWhen)
    local
      String i_str,helpVarIndexStr,res,resx,res_1;
      HelpVarInfo helpInfo;
      Integer helpVarIndex_1,i,helpVarIndex;
      list<HelpVarInfo> helpVarInfoList, helpVarInfo1;
      DAE.Exp e;
      list<DAE.Exp> el;
      Absyn.Path name;
      list<DAE.Exp> args_;
      Boolean tup,builtin_;
      DAE.ExpType exty;
      DAE.InlineType inty;
      DAE.CallAttributes attr;
    
    case ({},_,_,_) then ("",{});
    
    //expand sample conditions with helpindex
    case ((e as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr)) :: el,i,helpVarIndex, false)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        args_ = listAppend(args_,{DAE.ICONST(helpVarIndex)});
        e = DAE.CALL(name, args_, attr);
        helpInfo = (helpVarIndex,e,i);
        res = stringAppendList(
          {"  if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
            " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,false);
        res_1 = stringAppend(res, resx);
      then
        (res_1,(helpInfo :: helpVarInfoList));
    //expand sample conditions with helpindex
    case ((e as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr)) :: el,i,helpVarIndex, true)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        args_ = listAppend(args_,{DAE.ICONST(helpVarIndex)});
        e = DAE.CALL(name, args_, attr);
        helpInfo = (helpVarIndex,e,i);
        res = stringAppendList(
          {"  else if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
            " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,true);
        res_1 = stringAppend(res, resx);
      then
        (res_1,(helpInfo :: helpVarInfoList));
    
    case ((e :: el),i,helpVarIndex, false)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        //add HelpVar for sample and add hindex to sample call
        ((e,(helpVarInfo1, helpVarIndex_1))) = Expression.traverseExp(e, addHindexSample, ({},helpVarIndex));
        helpInfo = (helpVarIndex,e,i);
        res = stringAppendList(
          {"  if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
            " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex_1 + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,false);
        helpVarInfoList = listAppend(helpVarInfo1,helpVarInfoList);
        res_1 = stringAppend(res, resx);
      then
        (res_1,(helpInfo :: helpVarInfoList));
    
    case ((e :: el),i,helpVarIndex, true)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        //add HelpVar for sample and add hindex to sample call
        ((e,(helpVarInfo1, helpVarIndex_1))) = Expression.traverseExp(e, addHindexSample, ({},helpVarIndex));
        helpInfo = (helpVarIndex,e,i);
        res = stringAppendList(
          {"  else if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
            " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex_1 + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,true);
        helpVarInfoList = listAppend(helpVarInfo1,helpVarInfoList);
        res_1 = stringAppend(res, resx);
      then
        (res_1,(helpInfo :: helpVarInfoList));
    
    case (_,_,_,_)
      equation
        print("-build_when_condition_checks3 failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks3;


protected function addHindexSample
  input tuple<DAE.Exp, tuple<list<HelpVarInfo>,Integer>> inTuple;
  output tuple<DAE.Exp, tuple<list<HelpVarInfo>,Integer>> outTuple;
algorithm
  (outTuple):=
  matchcontinue (inTuple)
    local
      HelpVarInfo helpInfo;
      Integer helpVarIndex;
      list<HelpVarInfo> helpVarInfoList;
      DAE.Exp e;
      Absyn.Path name;
      list<DAE.Exp> args_;
      Boolean tup,builtin_;
      DAE.ExpType exty;
      DAE.CallAttributes attr;
    case ((e as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr),(helpVarInfoList,helpVarIndex)))
      equation
        helpVarIndex = helpVarIndex + 1;
        args_ = listAppend(args_,{DAE.ICONST(helpVarIndex)});
        e = DAE.CALL(name, args_, attr);
        helpInfo = (helpVarIndex,e,-1);
      then
        ((e,((helpInfo :: helpVarInfoList),helpVarIndex)));
     case ((e,(helpVarInfoList,helpVarIndex))) then ((e,(helpVarInfoList,helpVarIndex)));
    end matchcontinue;
end addHindexSample;


protected function buildWhenConditionChecks2
" This function outputs checks for all when clauses that do not have equations but reinit statements.
"
  input list<BackendDAE.WhenClause> inBackendDAEWhenClauseLst1 "List of when clauses";
  input Integer whenClauseIndex "index of the first when clause in inBackendDAEWhenClauseLst1";
  input Integer nextHelpVarIndex;
  output String outString;
  output list<HelpVarInfo> helpVarLst;
algorithm
  (outString,helpVarLst):=
  matchcontinue (inBackendDAEWhenClauseLst1,whenClauseIndex,nextHelpVarIndex)
    local
      Integer i_1,i,nextHelpIndex,numberOfNewHelpVars,nextHelpIndex_1;
      String res,res2,res1;
      list<HelpVarInfo> helpVarInfoList,helpVarInfoList2,helpVarInfoList1;
      BackendDAE.WhenClause wc;
      list<BackendDAE.WhenClause> xs;
      list<DAE.Exp> el;
      DAE.Exp e;
    case ({},_,_) then ("",{});
    case (((wc as BackendDAE.WHEN_CLAUSE(reinitStmtLst = {})) :: xs),i,nextHelpIndex) /* skip if there are no reinit statements */
      equation
        i_1 = i + 1;
        (res,helpVarInfoList) = buildWhenConditionChecks2(xs, i_1, nextHelpIndex);
      then
        (res,helpVarInfoList);
    case (((wc as BackendDAE.WHEN_CLAUSE(condition = DAE.ARRAY(array = el))) :: xs),i,nextHelpIndex)
      equation
        i_1 = i + 1;
        (res2,helpVarInfoList2) = buildWhenConditionChecks2(xs, i_1, nextHelpIndex);
        numberOfNewHelpVars = listLength(helpVarInfoList2);
        nextHelpIndex_1 = nextHelpIndex + numberOfNewHelpVars;
        (res1,helpVarInfoList1) = buildWhenConditionChecks3(el, i, nextHelpIndex_1,false);
        res = stringAppend(res1, res2);
        helpVarInfoList = listAppend(helpVarInfoList1, helpVarInfoList2);
      then
        (res,helpVarInfoList);
    case (((wc as BackendDAE.WHEN_CLAUSE(condition = e)) :: xs),i,nextHelpIndex)
      equation
        i_1 = i + 1;
        (res2,helpVarInfoList2) = buildWhenConditionChecks2(xs, i_1, nextHelpIndex);
        numberOfNewHelpVars = listLength(helpVarInfoList2);
        nextHelpIndex_1 = nextHelpIndex + numberOfNewHelpVars;
        (res1,helpVarInfoList1) = buildWhenConditionChecks3({e}, i, nextHelpIndex_1,false);
        res = stringAppend(res1, res2);
        helpVarInfoList = listAppend(helpVarInfoList1, helpVarInfoList2);
      then
        (res,helpVarInfoList);
    case (_,_,_)
      equation
        print("-build_when_condition_checks2 failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks2;

protected function buildWhenConditionChecks4
" Helper function to build_when_condition_checks
  This function generates checks for each when clause, sorted according to the order in which
  the equations inside them are sorted. The function buildWhenConditionChecks2 takes care
  of all the when clauses that does not contain equations (only reinit).
"
  input list<Integer> orderOfEquations                "The sorting order of the equations.";
  input BackendDAE.EquationArray inBackendDAEEquationLst     "List of equations.";
  input list<BackendDAE.WhenClause> inBackendDAEWhenClauseLst "List of when clauses.";
  input Integer nextHelpVarIndex                      "index of the next generated help variable.";
  output String outString                             "Generated event checking code";
  output list<HelpVarInfo> helpVarLst                  "List of help variables introduced in this function.";
algorithm
  (outString,helpVarLst):=
  matchcontinue (orderOfEquations,inBackendDAEEquationLst,inBackendDAEWhenClauseLst,nextHelpVarIndex)
    local
      Integer eqn,nextHelpIndex;
      String res2,res1,res;
      list<HelpVarInfo> helpVarInfoList2,helpVarInfoList1,helpVarInfoList;
      list<Integer> rest;
      BackendDAE.EquationArray eqnl;
      list<BackendDAE.WhenClause> whenClauseList;
      BackendDAE.WhenEquation whenEq;
      
    case ({},_,_,_) then ("",{});
      
      /* equation is a WHEN_EQUATION */
    case ((eqn :: rest),eqnl,whenClauseList,nextHelpIndex)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation=whenEq) = BackendDAEUtil.equationNth(eqnl, eqn-1);
        (res2, helpVarInfoList2) = buildWhenConditionChecks4(rest, eqnl, whenClauseList, nextHelpIndex);
        (res1, helpVarInfoList1) = buildWhenConditionCheckForEquation(SOME(whenEq), whenClauseList, false,
          nextHelpIndex + listLength(helpVarInfoList2));
        res = stringAppend(res1, res2);
        helpVarInfoList = listAppend(helpVarInfoList1, helpVarInfoList2);
      then
        (res,helpVarInfoList);
        
    case ((_ :: rest),eqnl,whenClauseList,nextHelpIndex)
      equation
        (res,helpVarInfoList) = buildWhenConditionChecks4(rest, eqnl, whenClauseList, nextHelpIndex);
      then
        (res,helpVarInfoList);
    case (_,_,_,_)
      equation
        print("-build_when_condition_checks4 failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks4;

protected function buildWhenConditionCheckForEquation "
  Generates eventchecking code given a when equation.
"
  input Option<BackendDAE.WhenEquation> whenEq            "The equation to check for";
  input list<BackendDAE.WhenClause> inBackendDAEWhenClauseLst "List of when clauses.";
  input Boolean isElseWhen                            "Whether the equation is inside an elsewhen or not.";
  input Integer nextHelpIndex                         "Next avalable help variable index.";
  output String outString                             "Generated event checking code";
  output list<HelpVarInfo> helpVarLst                  "List of help variables introduced in this function.";
algorithm
  (outString, helpVarLst) :=
  match (whenEq,inBackendDAEWhenClauseLst,isElseWhen, nextHelpIndex)
    local
      Integer nextHelpInd, ind;
      Expression.ComponentRef cr;
      DAE.Exp exp;
      String res1,res2,res;
      Option<BackendDAE.WhenEquation> elsePart;
      list<DAE.Exp> conditionList;
      list<HelpVarInfo> helpVars1,helpVars2, helpVars;
      list<BackendDAE.WhenClause> whenClauseList;
    case (SOME(BackendDAE.WHEN_EQ(ind,cr,exp,elsePart)),whenClauseList,isElseWhen,nextHelpInd)
      equation
        conditionList = getConditionList(whenClauseList, ind);
        (res1,helpVars1) = buildWhenConditionChecks3(conditionList, ind, nextHelpInd,isElseWhen);
        (res2,helpVars2) = buildWhenConditionCheckForEquation(elsePart, whenClauseList, true,
          nextHelpInd + listLength(helpVars1));
        res = stringAppend(res1,res2);
        helpVars = listAppend(helpVars1,helpVars2);
      then
        (res,helpVars);
    case (NONE(),_,_,_)
    then ("",{});
  end match;
end buildWhenConditionCheckForEquation;

protected function getConditionList
  input list<BackendDAE.WhenClause> whenClauseList;
  input Integer index;
  output list<DAE.Exp> conditionList;
algorithm
  conditionList := matchcontinue (whenClauseList, index)
    local
      Integer ind;
      DAE.Exp e;
      
    case (whenClauseList, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=DAE.ARRAY(_,_,conditionList)) = listNth(whenClauseList, ind);
      then conditionList;
    case (whenClauseList, ind)
      equation
        BackendDAE.WHEN_CLAUSE(condition=e) = listNth(whenClauseList, ind);
      then {e};
  end matchcontinue;
end getConditionList;

protected function addMissingEquations "function: addMissingEquations
  Helper function to build_when_condition_checks
  Given an integer and a list of integers completes the list with missing
  integers upto the given integer.
"
  input Integer inInteger;
  input list<Integer> inIntegerLst "accumulator; reverse the list before calling this function---";
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger,inIntegerLst)
    local
      list<Integer> lst,lst_1;
      Integer n_1,n;
    case (0,lst) then listReverse(lst);
    case (n,lst)
      equation
        true = listMember(n, lst);
        n_1 = n-1;
      then addMissingEquations(n_1, lst);
    case (n,lst) /* missing equations must be added in correct order, required in building whenConditionChecks4 */
      equation
        n_1 = n-1;
        lst_1 = addMissingEquations(n_1, lst);
      then n::lst_1;
  end matchcontinue;
end addMissingEquations;

protected function buildDiscreteVarChangesVar2
"Help relation to buildDiscreteVarChangesVar
 For an equation e  (not a when equation) containing a discrete variable v, if e contains a
 ZeroCrossing(i) generate 'if change(v) needToIterate=1;)'"
  input Integer eqn;
  input Expression.ComponentRef cr;
  input BackendDAE.BackendDAE daelow;
  output String outString;
algorithm
  outString := matchcontinue(eqn,cr,daelow)
    local BackendDAE.EquationArray eqns;
      BackendDAE.Equation e;
      list<BackendDAE.ZeroCrossing> zcLst;
      String crStr;
      list<String> strLst;
      list<Integer> zcIndxLst;
      
    case(eqn,cr,daelow as BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst))))
      equation
        zcIndxLst = zeroCrossingsContainIndex(eqn,0,zcLst);
        strLst = Util.listMap1(zcIndxLst,buildDiscreteVarChangesAddEvent,cr);
        outString = Util.stringDelimitList(strLst,"\n");
      then outString;
    case(_,_,_) equation
      print("buildDiscreteVarChangesVar2 failed\n");
    then fail();
  end matchcontinue;
end buildDiscreteVarChangesVar2;

protected function zeroCrossingsContainIndex "Returns the zero crossing indices that contains equation
given by input index."
  input Integer eqn "equation index";
  input Integer i "iterator for zc starts at 0 to n-1 zero crossings";
  input  list<BackendDAE.ZeroCrossing> zcLst;
  output list<Integer> eqns;
algorithm
  eqns := matchcontinue(eqn,i,zcLst)
    local list<Integer> eqnLst;
    case (_,_,{}) then {};
    case(eqn,i,BackendDAE.ZERO_CROSSING(occurEquLst=eqnLst)::zcLst) equation
      true = listMember(eqn,eqnLst);
      eqns = zeroCrossingsContainIndex(eqn,i+1,zcLst);
    then  i::eqns;
    case(eqn,i,_::zcLst) equation
      eqns = zeroCrossingsContainIndex(eqn,i+1,zcLst);
    then  eqns;
  end matchcontinue;
end zeroCrossingsContainIndex;

protected function buildDiscreteVarChangesAddEvent
"help function to buildDiscreteVarChangesVar2
 Generates 'if (change(v)) needToIterate=1 for and index i and variable v"
  input Integer indx;
  input Expression.ComponentRef cr;
  output String str;
protected
  String crStr,indxStr;
algorithm
  crStr := ComponentReference.printComponentRefStr(cr);
  indxStr := intString(indx);
  str := stringAppendList({"if (change(",crStr,")) { needToIterate=1; }"});
end buildDiscreteVarChangesAddEvent;

protected function mixedCollectRelations "function: mixedCollectRelations
  author: PA
"
  input list<BackendDAE.Equation> c_eqn;
  input list<BackendDAE.Equation> d_eqn;
  output list<DAE.Exp> res;
protected
  list<DAE.Exp> l1,l2;
algorithm
  l1 := mixedCollectRelations2(c_eqn);
  l2 := mixedCollectRelations2(d_eqn);
  res := listAppend(l1, l2);
end mixedCollectRelations;

protected function mixedCollectRelations2 "function: mixedCollectRelations2
  author: PA

  Helper function to mixed_collect_functions.
"
  input list<BackendDAE.Equation> inBackendDAEEquationLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inBackendDAEEquationLst)
    local
      list<DAE.Exp> l1,l2,l3,res;
      DAE.Exp e1,e2;
      list<BackendDAE.Equation> es;
      Expression.ComponentRef cr;
    case ({}) then {};
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2) :: es))
      equation
        l1 = Expression.getRelations(e1);
        l2 = Expression.getRelations(e2);
        l3 = mixedCollectRelations2(es);
        res = Util.listFlatten({l1,l2,l3});
      then
        res;
    case ((BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e1) :: es))
      equation
        l1 = Expression.getRelations(e1);
        l2 = mixedCollectRelations2(es);
        res = listAppend(l1, l2);
      then
        res;
    case (_) then {};
  end matchcontinue;
end mixedCollectRelations2;

protected function generateMixedDiscreteCombinationValues "function generateMixedDiscreteCombinationValues
  author: PA
  Generates all combinations of the values given as argument"
  input list<list<Integer>> inStringLstLst;
  output list<list<Integer>> outStringLstLst;
algorithm
  outStringLstLst := matchcontinue (inStringLstLst)
    local
      list<Integer> value;
      list<list<Integer>> values_1,values;
      
    case ({value}) then {value};
      
    case (values)
      equation
        values_1 = generateMixedDiscreteCombinationValues1(values);
      then
        values_1;
  end matchcontinue;
end generateMixedDiscreteCombinationValues;

protected function generateMixedDiscreteCombinationValues1
  input list<list<Integer>> inStringLstLst;
  output list<list<Integer>> outStringLstLst;
algorithm
  outStringLstLst := matchcontinue (inStringLstLst)
    local
      list<list<Integer>> values_1,values_2,values;
      list<Integer> value;
      
    case (values as {value}) then values;
      
    case (value :: values)
      equation
        values_1 = generateMixedDiscreteCombinationValues1(values);
        values_2 = generateMixedDiscreteCombinationValues2(value, values_1);
      then
        values_2;
  end matchcontinue;
end generateMixedDiscreteCombinationValues1;

protected function generateMixedDiscreteCombinationValues2 "
function generateMixedDiscreteCombinationValues2
  author: PA
  Helper function to generateMixedDiscreteCombinationValues.
  Insert a list of values producing all combinations with given list of list of values."
  input list<Integer> inStringLst;
  input list<list<Integer>> inStringLstLst;
  output list<list<Integer>> outStringLstLst;
algorithm
  outStringLstLst := match (inStringLst,inStringLstLst)
    local
      list<list<Integer>> lst,lst_1,lst2,res;
      Integer s;
      list<Integer> ss;
      
    case ({},lst) then {};
      
    case ((s :: ss),lst) 
      equation
        lst_1 = Util.listMap1(lst, Util.listCons, s);
        lst2 = generateMixedDiscreteCombinationValues2(ss, lst);
        res = listAppend(lst_1, lst2);
      then
        res;
  end match;
end generateMixedDiscreteCombinationValues2;

protected function generateMixedDiscretePossibleValues2 "function: generateMixedDiscretePossibleValues2
  Helper function to generateMixedDiscretePossibleValues."
  input list<DAE.Exp> inExpExpLst;
  input list<BackendDAE.Var> inBackendDAEVarLst;
  input Integer inInteger;
  output list<list<Integer>> outStringLstLst;
  output list<Integer> outIntegerLst;
algorithm
  (outStringLstLst,outIntegerLst) := matchcontinue (inExpExpLst,inBackendDAEVarLst,inInteger)
    local
      Integer cg_id;
      list<list<Integer>> values;
      list<Integer> dims;
      list<DAE.Exp> rels;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
      
    case (_,{},cg_id) then ({},{});  /* discrete vars cg var_id values value dimension */
      
    case (rels,(v :: vs),cg_id) /* booleans, generate true (1.0) and false (0.0) */
      equation
        BackendDAE.BOOL() = BackendVariable.varType(v);
        (values,dims) = generateMixedDiscretePossibleValues2(rels, vs, cg_id);
      then
        ({1,0} :: values, 2 :: dims);
        
    case (rels,(v :: vs),_)
      equation
        BackendDAE.INT() = BackendVariable.varType(v);
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Mixed system of equations with dicrete variables of type Integer not supported. Try to rewrite using Boolean variables."});
      then
        fail();
  end matchcontinue;
end generateMixedDiscretePossibleValues2;

protected function isMixedSystem "function: isMixedSystem
  author: PA

  Returns true if the list of variables is an equation system contains
  both discrete and continuous variables.
"
  input list<BackendDAE.Var> inBackendDAEVarLst;
  input list<BackendDAE.Equation> inEqns;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inBackendDAEVarLst,inEqns)
    local list<BackendDAE.Var> vs;
      list<BackendDAE.Equation> eqns;
      /* A single algorithm section (consists of several eqns) is not mixed system */
    case (vs,eqns) equation
      singleAlgorithmSectionList(eqns,NONE());
    then false;
    case (vs,eqns)
      equation
        true = BackendVariable.hasDiscreteVar(vs);
        true = BackendVariable.hasContinousVar(vs);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end isMixedSystem;

protected function solveTrivialArrayEquation
"Solves some trivial array equations, like v+v2=foo(...), w.r.t. v is v=foo(...)-v2"
  input Expression.ComponentRef v;
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outE1;
  output DAE.Exp outE2;
algorithm
  (outE1,outE2) := matchcontinue(v,e1,e2)
    local
      DAE.Exp e,e12,e22,vTerm,res,rhs,f;
      list<DAE.Exp> exps,exps_1;
      DAE.ExpType tp;
      Boolean b;
      DAE.ComponentRef c;
      
    case (v,DAE.ARRAY( tp, b,exps as ((DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef=c)) :: _))),e2)
      equation
        (f::exps_1) = Util.listMap(exps, Expression.expStripLastSubs); //Strip last subscripts
        Util.listMap1AllValue(exps_1, Expression.expEqual, f, true);
        c = ComponentReference.crefStripLastSubs(c);
        (e12,e22) = solveTrivialArrayEquation(v,Expression.makeCrefExp(c,tp),Expression.negate(e2));
      then  
        (e12,e22);
        
    case (v,e2,DAE.ARRAY( tp, b,exps as ((DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef=c)) :: _))))
      equation
        (f::exps_1) = Util.listMap(exps, Expression.expStripLastSubs); //Strip last subscripts
        Util.listMap1AllValue(exps_1, Expression.expEqual, f, true);
        c = ComponentReference.crefStripLastSubs(c);
        (e12,e22) = solveTrivialArrayEquation(v,Expression.negate(e2),Expression.makeCrefExp(c,tp));
      then  
        (e12,e22);
        
        // Solve simple linear equations.
    case(v,e1,e2)
      equation
        e = Expression.expSub(e1,e2);
        (res,_) = ExpressionSimplify.simplify(e);
        (f,rhs) = Expression.getTermsContainingX(res,Expression.crefExp(v));
        (vTerm as DAE.CREF(_,_),_) = ExpressionSimplify.simplify(f);
        (rhs,_) = ExpressionSimplify.simplify(Expression.negate(rhs));
      then 
        (vTerm,rhs);
        
        // not succeded to solve, return unsolved equation., catched later.
    case(v,e1,e2) then (e1,e2);
  end matchcontinue;
end solveTrivialArrayEquation;

protected function getVectorizedCrefFromExp
"function: getVectorizedCrefFromExp
  author: PA
  Returns the component ref v if expression is on form
   {v{1},v{2},...v{n}}  for some n.
  TODO: implement for 2D as well."
  input DAE.Exp inExp;
  output Expression.ComponentRef outComponentRef;
algorithm
  outComponentRef := match (inExp)
    local
      list<Expression.ComponentRef> crefs,crefs_1;
      Expression.ComponentRef cr;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> column;
      
    case (DAE.ARRAY(array = expl))
      equation
        ((crefs as (cr :: _))) = Util.listMap(expl, Expression.expCref); //Get all CRefs from exp1.
        crefs_1 = Util.listMap(crefs, ComponentReference.crefStripLastSubs); //Strip last subscripts
        _ = Util.listReduce(crefs_1, ComponentReference.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
        
    case (DAE.MATRIX(matrix = column))
      equation
        expl = Util.listFlatten(column);
        ((crefs as (cr :: _))) = Util.listMap(expl, Expression.expCref); //Get all CRefs from exp1.
        crefs_1 = Util.listMap(crefs, ComponentReference.crefStripLastSubs); //Strip last subscripts
        _ = Util.listReduce(crefs_1, ComponentReference.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
  end match;
end getVectorizedCrefFromExp;

protected function singleAlgorithmSection
"function: singleAlgorithmSection
  author: PA
  Checks if a dae (subsystem) consists of a single algorithm section."
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _:=
  match (inBackendDAE)
    local
      BackendDAE.EquationArray eqnarr;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedEqs = eqnarr)::{}))
      equation
        SOME(_) = BackendEquation.traverseBackendDAEEqnsWithStop(eqnarr,singleAlgorithmSection2,NONE());
      then
        ();
  end match;
end singleAlgorithmSection;

protected function singleAlgorithmSectionList
"function: singleAlgorithmSection
  author: Frenkel TUD 2010-11
  Checks if a list of equations consists of a single algorithm section."
  input list<BackendDAE.Equation> inBackendDAEEquationLst;
  input Option<Integer> Index;
algorithm
  _:=
  match (inBackendDAEEquationLst,Index)
    local 
      list<BackendDAE.Equation> res;
      Integer i,i1;
    case ({},_) then ();
    case ((BackendDAE.ALGORITHM(index = i) :: res),NONE())
      equation
        singleAlgorithmSectionList(res,SOME(i));
      then
        ();
    case ((BackendDAE.ALGORITHM(index = i) :: res),SOME(i1))
      equation
        true = intEq(i,i1);
        singleAlgorithmSectionList(res,SOME(i1));
      then
        ();
  end match;
end singleAlgorithmSectionList;

protected function singleAlgorithmSection2
  input tuple<BackendDAE.Equation,Option<Integer>> inTpl;
  output tuple<BackendDAE.Equation,Boolean,Option<Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local 
      BackendDAE.Equation e;
      Integer i,i1;
    case ((e as BackendDAE.ALGORITHM(index = i),NONE()))
    then ((e,true,SOME(i)));
    case ((e as BackendDAE.ALGORITHM(index = i),SOME(i1)))
      equation
        true = intEq(i,i1);
      then
        ((e,true,SOME(i1)));
    case ((e,_)) then ((e,false,NONE()));
  end matchcontinue;
end singleAlgorithmSection2;

protected function singleArrayEquation
"function: singleArrayEquation
  author: PA
  Checks if a dae (subsystem) consists of a single array equation."
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _:=
  match (inBackendDAE)
    local
      BackendDAE.EquationArray eqnarr;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedEqs = eqnarr)::{}))
      equation
        SOME(_) = BackendEquation.traverseBackendDAEEqnsWithStop(eqnarr,singleArrayEquation2,NONE());
      then
        ();
  end match;
end singleArrayEquation;

protected function singleArrayEquation2
  input tuple<BackendDAE.Equation,Option<Integer>> inTpl;
  output tuple<BackendDAE.Equation,Boolean,Option<Integer>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local 
      BackendDAE.Equation e;
      Integer i,i1;
    case ((e as BackendDAE.ARRAY_EQUATION(index = i),NONE()))
    then ((e,true,SOME(i)));
    case ((e as BackendDAE.ARRAY_EQUATION(index = i),SOME(i1)))
      equation
        true = intEq(i,i1);
      then
        ((e,true,SOME(i1)));
    case ((e,_)) then ((e,false,NONE()));
  end matchcontinue;
end singleArrayEquation2;

protected function makeResidualReplacements "function: makeResidualReplacements
  author: PA

  This function makes replacement rules for variables occuring in a
  nonlinear equation system. They should be replaced by xloc{index}, i.e.
  an unique index in a xloc vector.
"
  input list<Expression.ComponentRef> crefs;
  output VarTransform.VariableReplacements repl_1;
protected
  VarTransform.VariableReplacements repl;
algorithm
  repl := VarTransform.emptyReplacements();
  repl_1 := makeResidualReplacements2(repl, crefs, 0);
end makeResidualReplacements;

protected function makeResidualReplacements2 "function makeResidualReplacements2
  author: PA

  Helper function to make_residual_replacements"
  input VarTransform.VariableReplacements inVariableReplacements;
  input list<Expression.ComponentRef> inExpComponentRefLst;
  input Integer inInteger;
  output VarTransform.VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements := match (inVariableReplacements,inExpComponentRefLst,inInteger)
    local
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      Integer pos_1,pos;
      DAE.ComponentRef cr,cref_;
      list<Expression.ComponentRef> crs;
      
    case (repl,{},_) then repl;
      
    case (repl,(cr :: crs),pos)
      equation
        cref_ = ComponentReference.makeCrefIdent("xloc", DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_UNKNOWN()}), {DAE.INDEX(DAE.ICONST(pos))});
        repl_1 = VarTransform.addReplacement(repl, cr, Expression.crefExp(cref_));
        pos_1 = pos + 1;
        repl_2 = makeResidualReplacements2(repl_1, crs, pos_1);
      then
        repl_2;
  end match;
end makeResidualReplacements2;

protected function skipPreOperator "function: skipPreOperator
  Condition function, used in generate_ode_system2_nonlinear_residuals2.
  The variable in the pre operator should not be replaced in residual
  functions. This function is passed to replace_exp to ensure this."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    case (_) then true;
  end matchcontinue;
end skipPreOperator;

protected function transformXToXd "function transformXToXd
  author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar)
    local
      Expression.ComponentRef cr;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> exp;
      Option<Values.Value> v;
      list<Expression.Subscript> dim;
      Integer index;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "the origin of the element";
      BackendDAE.Var backendVar;
      
    case (BackendDAE.VAR(varName = cr,
      varKind = BackendDAE.STATE(),
      varDirection = dir,
      varType = tp,
      bindExp = exp,
      bindValue = v,
      arryDim = dim,
      index = index,
      source = source,
      values = attr,
      comment = comment,
      flowPrefix = flowPrefix,
      streamPrefix = streamPrefix))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
      then
        BackendDAE.VAR(cr,BackendDAE.STATE_DER(),dir,tp,exp,v,dim,index,source,attr,comment,flowPrefix,streamPrefix);
        
    case (backendVar)
    then
      backendVar;
  end matchcontinue;
end transformXToXd;

protected function isPartOfMixedSystem
"function: isPartOfMixedSystem
  Helper function to generateZeroCrossing2, returns true if any equation
  in the equation list of a zero-crossing is part of a mixed system."
  input BackendDAE.BackendDAE inBackendDAE;
  input Integer inInteger;
  input BackendDAE.StrongComponents inComps;
  input array<Integer> inIntegerArray;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inBackendDAE,inInteger,inComps,inIntegerArray)
    local
      BackendDAE.StrongComponent block_;
      list<BackendDAE.Equation> eqn_lst;
      list<BackendDAE.Var> var_lst;
      Boolean res;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      Integer e;
      BackendDAE.StrongComponents blocks;
      array<Integer> ass2;
    case ((dae as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns)::{})),e,blocks,ass2) /* equation blocks ass2 */
      equation
        block_ = BackendDAEUtil.getEquationBlock(e, blocks);
        (eqn_lst,var_lst,_) = BackendDAETransform.getEquationAndSolvedVar(block_, eqns, vars);
        res = isMixedSystem(var_lst,eqn_lst);
      then
        res;
    case (_,_,_,_) then false;
  end matchcontinue;
end isPartOfMixedSystem;

protected function getZcMixedSystem
"function: getZcMixedSystem
  Helper function to generateZeroCrossing2,
  returns true if any equation in the equation list
  of a zero-crossing is part of a mixed system."
  input BackendDAE.BackendDAE inBackendDAE;
  input Integer inInteger;
  input BackendDAE.StrongComponents inIntegerLstLst;
  input array<Integer> inIntegerArray;
  output BackendDAE.StrongComponent outIntegerLst;
algorithm
  outIntegerLst:=
  match (inBackendDAE,inInteger,inIntegerLstLst,inIntegerArray)
    local
      BackendDAE.StrongComponent block_;
      list<BackendDAE.Equation> eqn_lst;
      list<BackendDAE.Var> var_lst;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      Integer e;
      BackendDAE.StrongComponents blocks;
      array<Integer> ass2;
    case ((dae as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns)::{})),e,blocks,ass2) /* equation blocks ass2 */
      equation
         block_ = BackendDAEUtil.getEquationBlock(e, blocks);
        (eqn_lst,var_lst,_) = BackendDAETransform.getEquationAndSolvedVar(block_, eqns, vars);
        true = isMixedSystem(var_lst,eqn_lst);
      then
        block_;
  end match;
end getZcMixedSystem;

protected function splitOutputBlocks
"Splits the output blocks into two
  parts, one for continous output variables and one for discrete output values.
  This must be done to ensure that discrete variables are calculated before and
  after a discrete event."
  input BackendDAE.BackendDAE dlow;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.StrongComponents inComps;
  output BackendDAE.StrongComponents contBlocks;
  output BackendDAE.StrongComponents discBlocks;
algorithm
  (contBlocks,discBlocks) := match(dlow,ass1,ass2,inComps)
    local 
      BackendDAE.Variables vars,vars2,knvars;
      list<BackendDAE.Var>  varLstDiscrete;
      BackendDAE.EquationArray eqns;
    case (dlow as BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns)::{},shared=BackendDAE.SHARED(knownVars = knvars)),ass1,ass2,inComps)
      equation
        varLstDiscrete = BackendVariable.getAllDiscreteVarFromVariables(vars);
        vars2 = BackendDAEUtil.listVar(varLstDiscrete);
        (contBlocks,discBlocks,_) = splitOutputBlocks2(vars2,vars,knvars,eqns,inComps);
      then (contBlocks,discBlocks);
  end match;
end splitOutputBlocks;

protected function splitOutputBlocks2
  input BackendDAE.Variables discVars;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.StrongComponents blocks;
  output BackendDAE.StrongComponents contBlocks;
  output BackendDAE.StrongComponents discBlocks;
  output BackendDAE.Variables outDiscVars;
algorithm
  (contBlocks,discBlocks,outDiscVars) := matchcontinue(discVars,vars,knvars,eqns,blocks)
    local 
      BackendDAE.StrongComponent blck;
      
      /* discrete block */
    case(discVars,vars,knvars,eqns,blck::blocks)
      equation
        discVars = blockSolvesDiscrete(discVars,vars,knvars,eqns,blck);
        (contBlocks,discBlocks,discVars) = splitOutputBlocks2(discVars,vars,knvars,eqns,blocks);
      then (contBlocks,blck::discBlocks,discVars);
        
        /* continous block */
    case(discVars,vars,knvars,eqns,blck::blocks)
      equation
        (contBlocks,discBlocks,discVars) = splitOutputBlocks2(discVars,vars,knvars,eqns,blocks);
      then (blck::contBlocks,discBlocks,discVars);
        
    case(discVars,vars,knvars,eqns,{}) then ({},{},discVars);
  end matchcontinue;
end splitOutputBlocks2;

protected function blockSolvesDiscrete
"Help function to splitOutputBlocks
 succeds if the block solves for any discrete variable."
  input BackendDAE.Variables discVars;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.StrongComponent blck;
  output BackendDAE.Variables outDiscVars;
algorithm
  outDiscVars := matchcontinue(discVars,vars,knvars,eqns,blck)
    local list<BackendDAE.Equation> eqn_lst; list<BackendDAE.Var> var_lst;
      /* Solves a discrete variable, typically in when-clause */
    case(discVars,vars,knvars,eqns,blck)
      equation
        (eqn_lst,var_lst,_) = BackendDAETransform.getEquationAndSolvedVar(blck, eqns, vars);
        _::_ = Util.listSelect(var_lst,BackendDAEUtil.isVarDiscrete);
        discVars = BackendVariable.addVars(var_lst,discVars);
      then discVars;
        
        /* Equation has variablity discrete time */
    case(discVars,vars,knvars,eqns,blck) equation
      (eqn_lst,var_lst,_) = BackendDAETransform.getEquationAndSolvedVar(blck, eqns, discVars);
      var_lst = Util.listMap1(var_lst,BackendVariable.setVarKind,BackendDAE.DISCRETE());
      discVars = BackendVariable.addVars(var_lst,discVars);
      _::_ = Util.listSelect2(eqn_lst,discVars,knvars,BackendDAEUtil.isDiscreteEquation);
      discVars = BackendVariable.addVars(var_lst,discVars);
    then discVars;
  end matchcontinue;
end blockSolvesDiscrete;

protected function getCalledFunctionsInFunctions
"function: getCalledFunctionsInFunctions
  Goes through the given DAE, finds the given functions and collects
  the names of the functions called from within those functions"
  input list<Absyn.Path> paths;
  input HashTableStringToPath.HashTable ht;
  input DAE.FunctionTree funcs;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (paths,ht,funcs)
    local
      list<Absyn.Path> rest;
      Absyn.Path path;
    case ({},ht,funcs) then ht;
    case (path::rest,ht,funcs)
      equation
        ht = getCalledFunctionsInFunction2(path, Absyn.pathStringNoQual(path), ht, funcs);
        ht = getCalledFunctionsInFunctions(rest, ht, funcs);
      then ht;
  end match;
end getCalledFunctionsInFunctions;

public function getCalledFunctionsInFunction
"function: getCalledFunctionsInFunction
  Goes through the given DAE, finds the given function and collects
  the names of the functions called from within those functions"
  input Absyn.Path path;
  input DAE.FunctionTree funcs;
  output list<Absyn.Path> outPaths;
protected
  HashTableStringToPath.HashTable ht;
algorithm
  ht := HashTableStringToPath.emptyHashTable();
  ht := getCalledFunctionsInFunction2(path,Absyn.pathStringNoQual(path),ht,funcs);
  outPaths := BaseHashTable.hashTableValueList(ht);
end getCalledFunctionsInFunction;

protected function getCalledFunctionsInFunction2
"function: getCalledFunctionsInFunction
  Goes through the given DAE, finds the given function and collects
  the names of the functions called from within those functions"
  input Absyn.Path inPath;
  input String pathstr;
  input HashTableStringToPath.HashTable ht "paths to not add";
  input DAE.FunctionTree funcs;
  output HashTableStringToPath.HashTable outHt "paths to not add";
algorithm
  outHt := matchcontinue (inPath,pathstr,ht,funcs)
    local
      String str;
      Absyn.Path path;
      DAE.Function funcelem;
      list<Absyn.Path> calledfuncs, varfuncs;
      list<DAE.Element> els;
      
    case (path,pathstr,ht,_)
      equation
        _ = BaseHashTable.get(Absyn.pathStringNoQual(path), ht);
      then ht;
        
    case (path,pathstr,ht,funcs)
      equation
        funcelem = DAEUtil.getNamedFunction(path, funcs);
        els = DAEUtil.getFunctionElements(funcelem);
        // Function reference variables are filtered out
        varfuncs = Util.listFold(els, DAEUtil.collectFunctionRefVarPaths, {});
        (_,(_,varfuncs)) = DAEUtil.traverseDAE2(Util.if_(RTOpts.acceptMetaModelicaGrammar(), els, {}),Expression.traverseSubexpressionsHelper,(DAEUtil.collectValueblockFunctionRefVars,varfuncs));
        (_,(_,(calledfuncs,_))) = DAEUtil.traverseDAE2(els,Expression.traverseSubexpressionsHelper,(matchNonBuiltinCallsAndFnRefPaths,({},varfuncs)));
        ht = BaseHashTable.add((pathstr,path),ht);
        ht = getCalledFunctionsInFunctions(calledfuncs, ht, funcs);
      then ht;
        
    case (path,pathstr,ht,funcs)
      equation
        failure(_ = DAEUtil.getNamedFunction(path, funcs));
        str = "SimCode.getCalledFunctionsInFunction2: Class " +& pathstr +& " not found in global scope.";
        Error.addMessage(Error.INTERNAL_ERROR,{str});
      then
        fail();
  end matchcontinue;
end getCalledFunctionsInFunction2;

protected function getCallPath
"function: getCallPath
  Retrive the function name from a CALL expression."
  input DAE.Exp inExp;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue (inExp)
    local
      Absyn.Path path;
      DAE.ComponentRef cref;
      
    case DAE.CALL(path = path) then path;
      
    case DAE.CREF(componentRef = cref)
      equation
        path = ComponentReference.crefToPath(cref);
      then
        path;
  end matchcontinue;
end getCallPath;

protected function removeDuplicatePaths
"Remove duplicate Paths in a list of Paths."
  input list<Absyn.Path> inAbsynPathLst;
  output list<Absyn.Path> outAbsynPathLst;
algorithm
  outAbsynPathLst:=
  matchcontinue (inAbsynPathLst)
    local
      list<Absyn.Path> restwithoutfirst,recresult,rest;
      Absyn.Path first;
    case {} then {};
    case (first :: rest)
      equation
        restwithoutfirst = removePathFromList(rest, first);
        recresult = removeDuplicatePaths(restwithoutfirst);
      then
        (first :: recresult);
  end matchcontinue;
end removeDuplicatePaths;

protected function removePathFromList
  input list<Absyn.Path> inAbsynPathLst;
  input Absyn.Path inPath;
  output list<Absyn.Path> outAbsynPathLst;
algorithm
  outAbsynPathLst:=
  matchcontinue (inAbsynPathLst,inPath)
    local
      list<Absyn.Path> res,rest;
      Absyn.Path first,path;
    case ({},_) then {};
    case ((first :: rest),path)
      equation
        true = ModUtil.pathEqual(first, path);
        res = removePathFromList(rest, path);
      then
        res;
    case ((first :: rest),path)
      equation
        false = ModUtil.pathEqual(first, path);
        res = removePathFromList(rest, path);
      then
        (first :: res);
  end matchcontinue;
end removePathFromList;

protected function generateEquationOrder
  input BackendDAE.StrongComponents inComps;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inComps)
    local
      list<Integer> res;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents blocks;
      Integer eqn;
    case ({}) then {};
    case (BackendDAE.SINGLEEQUATION(eqn=eqn) :: blocks)
      equation
        res = generateEquationOrder(blocks) "for single equations" ;
      then
        (eqn :: res);
    case (comp :: blocks)
      equation
        res = generateEquationOrder(blocks) "For system of equations skip these" ;
      then
        res;
    else
      equation
        print("- SimCode.generateEquationOrder failed\n");
      then
        fail();
  end matchcontinue;
end generateEquationOrder;

protected function isVarQ
"Succeeds if inElement is a variable or constant that is not input."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    local
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(kind=vk, direction=vd)
      equation
        isVarVarOrConstant(vk);
        isDirectionNotInput(vd);
      then ();
  end match;
end isVarQ;

protected function isVarVarOrConstant
  input DAE.VarKind inVarKind;
algorithm
  _ := match (inVarKind)
    case DAE.VARIABLE() then ();
    case DAE.PARAM() then ();
  end match;
end isVarVarOrConstant;

protected function isDirectionNotInput
  input DAE.VarDirection inVarDirection;
algorithm
  _ := match (inVarDirection)
    case DAE.OUTPUT() then ();
    case DAE.BIDIR() then ();
  end match;
end isDirectionNotInput;

protected function filterNg
"Sets the number of zero crossings to zero if events are disabled."
  input Integer ng;
  output Integer outInteger;
algorithm
  outInteger := Util.if_(useZerocrossing(),ng,0);
end filterNg;

protected function useZerocrossing
  output Boolean res;
protected
  Boolean flagSet;
algorithm
  flagSet := RTOpts.debugFlag("noevents");
  res := boolNot(flagSet);
end useZerocrossing;

protected function getCrefFromExp
"Assume input Exp is CREF and return the ComponentRef, fail otherwise."
  input DAE.Exp e;
  output Absyn.ComponentRef c;
algorithm
  c := match (e)
    local
      Expression.ComponentRef crefe;
      Absyn.ComponentRef crefa;
      
    case(DAE.CREF(componentRef = crefe))
      equation
        crefa = ComponentReference.unelabCref(crefe);
      then
        crefa;
        
    else
      equation
        print("SimCode.getCrefFromExp failed: input was not of type DAE.CREF");
      then
        fail();
  end match;
end getCrefFromExp;

protected function indexSubscriptToExp
  input DAE.Subscript subscript;
  output DAE.Exp exp_;
algorithm
  exp_ := match (subscript)
    case (DAE.INDEX(exp_)) then exp_;
    else DAE.ICONST(99); // TODO: Why do we end up here?
  end match;
end indexSubscriptToExp;

protected function isNotBuiltinCall
"Return true if the given DAE.CALL is a call but not to a builtin function."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExp)
    local
      Boolean res, builtin;
    case DAE.CALL(attr=DAE.CALL_ATTR(builtin=builtin))
      equation
        res = boolNot(builtin);
      then
        res;
    else false;
  end match;
end isNotBuiltinCall;

protected function typesVar
  input Types.Var inTypesVar;
  output Variable outVar;
algorithm
  outVar := match (inTypesVar)
    local
      String name;
      Types.Type typesType;
      DAE.ExpType expType;
      DAE.ComponentRef cref_;
    case (DAE.TYPES_VAR(name=name, ty=typesType))
      equation
        expType = Types.elabType(typesType);
        cref_ = ComponentReference.makeCrefIdent(name, expType, {});
      then VARIABLE(cref_, expType,NONE(), {});
  end match;
end typesVar;

protected function dlowvarToSimvar
  input BackendDAE.Var dlowVar;
  input Option<BackendDAE.AliasVariables> optAliasVars;
  input BackendDAE.Variables inVars;
  output SimVar simVar;
algorithm
  simVar := match (dlowVar,optAliasVars,inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      list<Expression.Subscript> inst_dims;
      list<String> numArrayElement;
      Integer indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<SCode.Comment> comment;
      BackendDAE.Type tp;
      String  commentStr,  unit, displayUnit,NumarrayElement,idxs_str1;
      Option<DAE.Exp> initVal;
      Option<DAE.Exp> nomVal;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      AliasVariable aliasvar;
      DAE.ElementSource source;
      Absyn.Info info;
      BackendDAE.Variables vars;
      Causality caus;
    case ((dlowVar as BackendDAE.VAR(varName = cr,
      varKind = kind,
      varDirection = dir,
      arryDim = inst_dims,
      index = indx,
      values = dae_var_attr,
      comment = comment,
      varType = tp,
      flowPrefix = flowPrefix,
      streamPrefix = streamPrefix,
      source = source)),optAliasVars,vars)
      equation
        commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
        (unit, displayUnit) = extractVarUnit(dae_var_attr);
        initVal = getInitialValue(dlowVar);
        nomVal = getNominalValue(dlowVar);
        checkInitVal(initVal,source);
        isFixed = BackendVariable.varFixed(dlowVar);
        type_ = BackendDAEUtil.makeExpType(tp);
        isDiscrete = BackendVariable.isVarDiscrete(dlowVar);
        arrayCref = getArrayCref(dlowVar);
        aliasvar = getAliasVar(dlowVar,optAliasVars);
        caus = getCausality(dlowVar,vars);
        numArrayElement=arraydim1(inst_dims);       
      then
        SIMVAR(cr, kind, commentStr, unit, displayUnit, indx, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, caus,NONE(),numArrayElement);
  end match;
end dlowvarToSimvar;

protected function checkInitVal
  input Option<DAE.Exp> oexp;
  input DAE.ElementSource source;
algorithm
  _ := match (oexp,source)
    local
      Absyn.Info info;
      String str;
      DAE.Exp exp;
    case (NONE(),_) then ();
    case (SOME(DAE.RCONST(_)),_) then ();
    case (SOME(DAE.ICONST(_)),_) then ();
    case (SOME(DAE.SCONST(_)),_) then ();
    case (SOME(DAE.BCONST(_)),_) then ();
    // adrpo, 2011-04-18 -> enumeration literal is OK also
    case (SOME(DAE.ENUM_LITERAL(index = _)),_) then ();
    case (SOME(exp),DAE.SOURCE(info=info))
      equation
        str = "Initial value of unknown type: " +& ExpressionDump.printExpStr(exp);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then ();
  end match;
end checkInitVal;

protected function getCausality
  input BackendDAE.Var dlowVar;
  input BackendDAE.Variables inVars;
  output Causality caus;
algorithm
  caus := matchcontinue (dlowVar,inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables knvars;
    case (BackendDAE.VAR(varName = DAE.CREF_IDENT(ident = _), varDirection = DAE.OUTPUT()),_) then OUTPUT();
    case (BackendDAE.VAR(varName = cr,varDirection = DAE.INPUT()),knvars)
      equation
        (_,_) = BackendVariable.getVar(cr, knvars);
      then INPUT();
    case(_,_) then INTERNAL();
  end matchcontinue;
end getCausality;

protected function traversingdlowvarToSimvar
"autor: Frenkel TUD 2010-11"
  input tuple<BackendDAE.Var, tuple<list<SimVar>,BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<list<SimVar>,BackendDAE.Variables>> outTpl;
algorithm
  outTpl := match (inTpl)
    local
      BackendDAE.Var v;
      list<SimVar> sv_lst;
      SimVar sv;
      BackendDAE.Variables vars;
    case ((v,(sv_lst,vars)))
      equation
        sv = dlowvarToSimvar(v,NONE(),vars);
      then ((v,(sv::sv_lst,vars)));
    case inTpl then inTpl;
  end match;
end traversingdlowvarToSimvar;

protected function subsToScalar
"Returns true if subscript results applied to variable or expression results in
scalar expression."
  input list<DAE.Subscript> inExpSubscriptLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExpSubscriptLst)
    local
      Boolean b;
      list<DAE.Subscript> r;
    case {} then true;
    case (DAE.SLICE(exp = _) :: _) then false;
    case (DAE.WHOLEDIM() :: _) then false;
    case (DAE.INDEX(exp = _) :: r)
      equation
        b = subsToScalar(r);
      then
        b;
  end match;
end subsToScalar;

protected function appendNonpresentPaths
"function: appendNonpresentPaths
  Appends the paths in first argument to the two path lists given as second
  and third argument, given that the path is not present in the second path list."
  input list<Absyn.Path> inAbsynPathLst1;
  input list<Absyn.Path> inAbsynPathLst2;
  input list<Absyn.Path> inAbsynPathLst3;
  output list<Absyn.Path> outAbsynPathLst1;
  output list<Absyn.Path> outAbsynPathLst2;
algorithm
  (outAbsynPathLst1,outAbsynPathLst2):=
  matchcontinue (inAbsynPathLst1,inAbsynPathLst2,inAbsynPathLst3)
    local
      list<Absyn.Path> allpaths,iterpaths,paths,allpaths_1,iterpaths_1,allpaths_2,iterpaths_2;
      Absyn.Path path;
      
    case ({},allpaths,iterpaths) then (allpaths,iterpaths);  /* paths to append all paths iterated paths updated all paths update iterated paths */
      
    case ((path :: paths),allpaths,iterpaths)
      equation
        _ = Util.listGetMemberOnTrue(path, allpaths, ModUtil.pathEqual);
        (allpaths,iterpaths) = appendNonpresentPaths(paths, allpaths, iterpaths);
      then
        (allpaths,iterpaths);
        
    case ((path :: paths),allpaths,iterpaths)
      equation
        failure(_ = Util.listGetMemberOnTrue(path, allpaths, ModUtil.pathEqual));
        allpaths_1 = listAppend(allpaths, {path});
        iterpaths_1 = listAppend(iterpaths, {path});
        (allpaths_2,iterpaths_2) = appendNonpresentPaths(paths, allpaths_1, iterpaths_1);
      then
        (allpaths_2,iterpaths_2);
  end matchcontinue;
end appendNonpresentPaths;

public function getMatchingExpsList
  input list<DAE.Exp> inExps;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input tuple<DAE.Exp,list<DAE.Exp>> itpl;
    output tuple<DAE.Exp,list<DAE.Exp>> otpl;
  end MatchFn;
algorithm
  ((_,outExpLst)) := Expression.traverseExpList(inExps,inFn,{});
end getMatchingExpsList;

protected function matchNonBuiltinCallsAndFnRefPaths
"The extra argument is a tuple<list,list>; the second list is the list of variable
names to filter out (so we don't add function references variables)"
  input tuple<DAE.Exp,tuple<list<Absyn.Path>,list<Absyn.Path>>> itpl;
  output tuple<DAE.Exp,tuple<list<Absyn.Path>,list<Absyn.Path>>> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      DAE.Exp e;
      Absyn.Path path;
      list<Absyn.Path> acc,filter;
    case ((e as DAE.CALL(path = path, attr = DAE.CALL_ATTR(builtin = false)),(acc,filter)))
      equation
        path = Absyn.makeNotFullyQualified(path);
        false = Util.listMemberWithCompareFunc(path,filter,Absyn.pathEqual);
      then ((e,(path::acc,filter)));
    case ((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = false)),(acc,filter)))
      equation
        path = Absyn.crefToPath(getCrefFromExp(e));
        false = Util.listMemberWithCompareFunc(path,filter,Absyn.pathEqual);
      then ((e,(path::acc,filter)));
    case itpl then itpl;
  end matchcontinue;
end matchNonBuiltinCallsAndFnRefPaths;

protected function matchCalls
"Used together with getMatchingExps"
  input tuple<DAE.Exp,list<DAE.Exp>> itpl;
  output tuple<DAE.Exp,list<DAE.Exp>> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      DAE.Exp e;
      list<DAE.Exp> acc;
    case ((e as DAE.CALL(expLst = _),acc)) then ((e,e::acc));
    case itpl then itpl;
  end matchcontinue;
end matchCalls;

protected function matchMetarecordCalls
"Used together with getMatchingExps"
  input tuple<DAE.Exp,list<DAE.Exp>> itpl;
  output tuple<DAE.Exp,list<DAE.Exp>> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      DAE.Exp e;
      list<DAE.Exp> acc;
      Integer index;
    case ((e as DAE.METARECORDCALL(index = index),acc))
      equation
        false = -1 == index;
      then ((e,e::acc));
    case itpl then itpl;
  end matchcontinue;
end matchMetarecordCalls;

protected function generateExtFunctionIncludes
"function: generateExtFunctionIncludes
  Collects the includes and libs for an external function
  by investigating the annotation of an external function."
  input Absyn.Path path;
  input Option<SCode.Annotation> inAbsynAnnotationOption;
  output list<String> includes;
  output list<String> includeDirs;
  output list<String> libs;
  output Boolean dynamcLoad;
algorithm
  (includes,includeDirs,libs,dynamcLoad):=
  match (path,inAbsynAnnotationOption)
    local
      SCode.Mod mod;
      Boolean b;

    case (path,SOME(SCode.ANNOTATION(mod)))
      equation
        b = generateExtFunctionDynamicLoad(mod);
        libs = generateExtFunctionIncludesLibstr(mod);
        includes = generateExtFunctionIncludesIncludestr(mod);
        libs = generateExtFunctionLibraryDirectoryFlags(path,mod,libs);
        includeDirs = generateExtFunctionIncludeDirectoryFlags(path,mod,includes);
      then
        (includes,includeDirs,libs,b);
    case (_,NONE()) then ({},{},{},false);
  end match;
end generateExtFunctionIncludes;

protected function generateExtFunctionIncludeDirectoryFlags
  "Process LibraryDirectory and IncludeDirectory"
  input Absyn.Path path;
  input SCode.Mod inMod;
  input list<String> includes;
  output list<String> outDirs;
algorithm
  outDirs := matchcontinue (path,inMod,includes)
    local
      String str;
    case (_,_,{}) then {};
    case (_,_,_)
      equation
        SCode.MOD(binding = SOME((Absyn.STRING(str), _))) =
          Mod.getUnelabedSubMod(inMod, "IncludeDirectory");
        str = CevalScript.getFullPathFromUri(str,false);
        str = "\"-I"+&str+&"\"";
      then {str};
    case (path,_,_)
      equation
        str = "modelica://" +& Absyn.pathStringNoQual(path) +& "/Resources/Include";
        str = CevalScript.getFullPathFromUri(str,false);
        str = "\"-I"+&str+&"\"";
      then {str};
        // Read Absyn.Info instead?
    else {};
  end matchcontinue;
end generateExtFunctionIncludeDirectoryFlags;

protected function generateExtFunctionLibraryDirectoryFlags
  "Process LibraryDirectory and IncludeDirectory"
  input Absyn.Path path;
  input SCode.Mod inMod;
  input list<String> libs;
  output list<String> outLibs;
algorithm
  outLibs := matchcontinue (path,inMod,libs)
    local
      String str,str1,str2,str3,platform1,platform2;
    case (_,_,{}) then {};
    case (_,_,libs)
      equation
        SCode.MOD(binding = SOME((Absyn.STRING(str), _))) =
          Mod.getUnelabedSubMod(inMod, "LibraryDirectory");
        str = CevalScript.getFullPathFromUri(str,false);
        platform1 = System.openModelicaPlatform();
        platform2 = System.modelicaPlatform();
        str1 = Util.if_(platform1 ==& "", "", "\"-L" +& str +& "/" +& platform1 +& "\"");
        str2 = Util.if_(platform2 ==& "", "", "\"-L" +& str +& "/" +& platform2 +& "\"");
        str3 ="\"-L" +& str +& "\"";
        libs = str1::str2::str3::libs;
      then libs;
    case (path,_,libs)
      equation
        str = "modelica://" +& Absyn.pathStringNoQual(path) +& "/Resources/Library";
        str = CevalScript.getFullPathFromUri(str,false);
        platform1 = System.openModelicaPlatform();
        platform2 = System.modelicaPlatform();
        str1 = Util.if_(platform1 ==& "", "", "\"-L" +& str +& "/" +& platform1 +& "\"");
        str2 = Util.if_(platform2 ==& "", "", "\"-L" +& str +& "/" +& platform2 +& "\"");
        str3 ="\"-L" +& str +& "\"";
        libs = str1::str2::str3::libs;
      then libs;
    else libs;
  end matchcontinue;
end generateExtFunctionLibraryDirectoryFlags;

protected function getLibraryStringInGccFormat
"Takes an Absyn.STRING describing a library and outputs a list
of strings corresponding to it.
Note: Normally only outputs a single string, but Lapack on MinGW is special."
  input Absyn.Exp exp;
  output list<String> strs;
algorithm
  strs := matchcontinue exp
    local
      String str,str2,omhome,omhomelib,lpsolvelib;
      
    // Lapack on MinGW/Windows is linked against f2c
    case Absyn.STRING("Lapack")
      equation
        true = "Windows_NT" ==& System.os();
      then {"-llapack-mingw", "-ltmglib-mingw", "-lblas-mingw", "-lf2c"};
      
    // omcruntime on windows needs linking with mico2313 and wsock and then some :)
    case Absyn.STRING(str as "omcruntime")
      equation
        true = "Windows_NT" ==& System.os();
        str = "-l" +& str;
        strs = getLibraryStringInGccFormat(Absyn.STRING("Lapack"));
        strs = str :: "-lexpat" :: "-lsqlite3" :: "-llpsolve55" :: "-lmico2313" :: "-lws2_32" :: "-lregex" :: strs;
      then 
        strs;
        
    // The library is not actually named libLapack.so.
    // Which is a problem, since MSL says it does.
    case Absyn.STRING("Lapack") then {"-llapack"};
        
    // Wonder if there may be issues if we have duplicates in the Corba libs
    // and the other libs. Some other developer will probably swear over this
    // hack some day, but at least I get an early weekend.
    case Absyn.STRING("OpenModelicaCorba")
      equation
        str = System.getCorbaLibs();
      then {str};
        
    // If omcruntime is linked statically against omniORB, we need to include those here as well
    case Absyn.STRING(str as "omcruntime")
      equation
        false = "Windows_NT" ==& System.os();
      then 
        System.getRuntimeLibs();
        
    // If the string contains a dot, it's a good path that should not be prefix -l
    case Absyn.STRING(str)
      equation
        false = -1 == System.stringFind(str, ".");
      then {str};
        
    // If the string starts with a -, it's probably -l or -L gcc flags
    case Absyn.STRING(str)
      equation
        true = "-" ==& stringGetStringChar(str, 1);
      then {str};
        
    case Absyn.STRING(str)
      equation
        str = "-l" +& str;
      then {str};
        
    case _
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Failed to process Library annotation for external function"});
      then fail();
  end matchcontinue;
end getLibraryStringInGccFormat;

protected function generateExtFunctionIncludesLibstr
  input SCode.Mod inMod;
  output list<String> outStringLst;
algorithm
  outStringLst:= matchcontinue (inMod)
    local
      list<Absyn.Exp> arr;
      list<String> libs;
      list<list<String>> libsList;
      Absyn.Exp exp;
    case (_)
      equation
        SCode.MOD(binding = SOME((Absyn.ARRAY(arr), _))) =
          Mod.getUnelabedSubMod(inMod, "Library");
        libsList = Util.listMap(arr, getLibraryStringInGccFormat);
      then
        Util.listFlatten(libsList);
    case (_)
      equation
        SCode.MOD(binding = SOME((exp, _))) =
          Mod.getUnelabedSubMod(inMod, "Library");
        libs = getLibraryStringInGccFormat(exp);
      then
        libs;
    else {};
  end matchcontinue;
end generateExtFunctionIncludesLibstr;

protected function generateExtFunctionIncludesIncludestr
  input SCode.Mod inMod;
  output list<String> outStringLst;
algorithm
  outStringLst:= matchcontinue (inMod)
    local
      String inc,inc_1;
    case (_)
      equation
        SCode.MOD(binding = SOME((Absyn.STRING(inc), _))) =
          Mod.getUnelabedSubMod(inMod, "Include");
        inc_1 = System.stringReplace(inc, "\\\"", "\"");
      then
        {inc_1};
    else {};
  end matchcontinue;
end generateExtFunctionIncludesIncludestr;

protected function generateExtFunctionDynamicLoad
  input SCode.Mod inMod;
  output Boolean outDynamicLoad;
algorithm
  outDynamicLoad:= matchcontinue (inMod)
    local
      list<Absyn.Exp> arr;
      list<String> libs;
      list<list<String>> libsList;
      Boolean b;
    case (_)
      equation
        SCode.MOD(binding = SOME((Absyn.BOOL(b), _))) =
          Mod.getUnelabedSubMod(inMod, "DynamicLoad");
      then
        b;
    else false;
  end matchcontinue;
end generateExtFunctionDynamicLoad;

protected function matchFnRefs
"Used together with getMatchingExps"
  input tuple<DAE.Exp,list<DAE.Exp>> itpl;
  output tuple<DAE.Exp,list<DAE.Exp>> otpl;
algorithm
  otpl := matchcontinue itpl
    local
      DAE.Exp e,e2;
      list<DAE.Exp> acc;
      DAE.ComponentRef cref;
      Absyn.Path p;
      
    case ((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = false)),acc)) then ((e,e::acc));
      
    case ((e as DAE.PARTEVALFUNCTION(ty = DAE.ET_FUNCTION_REFERENCE_VAR(),path=p),acc))
      equation
        cref = ComponentReference.pathToCref(p);
        e2 = Expression.makeCrefExp(cref,DAE.ET_FUNCTION_REFERENCE_VAR());
      then
        ((e,e2::acc));
        
    case itpl then itpl;
        
  end matchcontinue;
end matchFnRefs;

public function getImplicitRecordConstructors
  "If a record instance is sent to a function we need to generate code for the
  record constructor even if it's not explicitly called, because the constructor
  is used by the generated code. This function checks the arguments of a
  function for these implicit record constructor calls and returns a list of all
  record constructors that are used."
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue(inExpLst)
    local
      DAE.ComponentRef cref;
      DAE.ExpType record_type;
      Absyn.Path record_path;
      list<DAE.Exp> rest_expr;
      DAE.Exp record_cref;
    case ({}) then {};
      // A record component reference.
    case (DAE.CREF(
      componentRef = cref, 
      ty = (record_type as DAE.ET_COMPLEX(
        complexClassType = ClassInf.RECORD(path = record_path)))) :: rest_expr)
      equation
        // Make sure it has no subscripts, i.e. it's a component reference for
        // an entire record instance.
        {} = ComponentReference.crefLastSubs(cref);
        // Build a DAE.CREF from the record path.
        cref = ComponentReference.pathToCref(record_path);
        record_cref = Expression.crefExp(cref);
        rest_expr = getImplicitRecordConstructors(rest_expr);
      then record_cref :: rest_expr;
    case (_ :: rest_expr)
      equation
        rest_expr = getImplicitRecordConstructors(rest_expr);
      then rest_expr;
  end matchcontinue;
end getImplicitRecordConstructors;

public function addDivExpErrorMsgtoExp "
  Author: Frenkel TUD 2010-02, Adds the error msg to Expression.Div."
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inDlowMode;
  output DAE.Exp outExp;
  output list<DAE.Exp> outDivLst;
algorithm 
  (outExp,outDivLst) := match(inExp,inDlowMode)
    local 
      DAE.Exp exp;
      BackendDAE.DivZeroExpReplace dzer;
      list<DAE.Exp> divlst;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      
    case(inExp,inDlowMode as (vars,varlst,dzer))
      equation
        ((exp,(_,_,_,divlst))) = Expression.traverseExp(inExp, traversingDivExpFinder, (vars,varlst,dzer,{}));
      then
        (exp,divlst);
  end match;
end addDivExpErrorMsgtoExp;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      BackendDAE.DivZeroExpReplace dzer;
      list<DAE.Exp> divLst;
      DAE.Exp e,e1,e2;
      Expression.Type ty;
      String se;
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2),(vars,varlst,dzer,divLst)))
      equation
        true = Expression.isConst(e2);
        false = Expression.isZero(e2);
      then ((e, (vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2),(vars,varlst,dzer,divLst)))
      equation
        (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
      then ((DAE.CALL(Absyn.IDENT("DIVISION"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL())), (vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
      equation
        (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
      then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL()))::divLst) ));
        
        /*
         case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARR(ty),exp2 = e2), dlowmode as (dlow,_)))
         then ((e, dlowmode ));
         */    
        
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
      equation
        true = Expression.isConst(e2);
        false = Expression.isZero(e2);
      then ((e, (vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
      equation
        (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
      then ((DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL())), (vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
      equation
        (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
      then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL()))::divLst) ));
        
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
      equation
        true = Expression.isConst(e2);
        false = Expression.isZero(e2);
      then ((e, (vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
      equation
        (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
      then ((DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL())), (vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
      equation
        (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
      then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL()))::divLst) ));
    case(inExp) then (inExp);
  end matchcontinue;
end traversingDivExpFinder;

protected function traversingDivExpFinder1 "
Author: Frenkel TUD 2010-02 
  helper for traversingDivExpFinder"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inMode;
  output String outString;
  output Boolean outBool;
algorithm
  (outString,outBool) := match(inExp1,inExp2,inMode)
    local
      DAE.Exp e,e2;
      String se;
      list<DAE.ComponentRef> crlst;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      list<Boolean> boollst;
      Boolean bres;
      
    case( e , e2, (vars,varlst,BackendDAE.ALL()) )
      equation
        // generade modelica strings
        se = generadeDivExpErrorMsg(e,e2,vars);
      then 
        (se,false);
        
    case( e , e2, (vars,varlst,BackendDAE.ONLY_VARIABLES()) )
      equation
        // generade modelica strings
        se = generadeDivExpErrorMsg(e,e2,vars);
        // check if expression contains variables
        crlst = Expression.extractCrefsFromExp(e2);
        boollst = Util.listMap1r(crlst,BackendVariable.isVarKnown,varlst);
        bres = Util.boolOrList(boollst);
      then 
        (se,bres);
  end match;
end traversingDivExpFinder1;

protected  function generadeDivExpErrorMsg "
Author: Frenkel TUD 2010-02. varOrigCref"
  input DAE.Exp inExp;
  input DAE.Exp inDivisor;
  input BackendDAE.Variables inVars;
  output String outString;
  protected 
  String se,se2,s,s1;
algorithm
  se := ExpressionDump.printExp2Str(inExp,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  se2 := ExpressionDump.printExp2Str(inDivisor,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  s := stringAppend(se," because ");
  s1 := stringAppend(s,se2);
  outString := stringAppend(s1," == 0");
end generadeDivExpErrorMsg;

protected function addDivExpErrorMsgtosimJac
"function addDivExpErrorMsgtosimJac
  helper for addDivExpErrorMsgtoSimEqSystem."
  input tuple<Integer, Integer, SimEqSystem> inJac;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inDlowMode;
  output tuple<Integer, Integer, SimEqSystem> outJac;
  output list<DAE.Exp> outDivLst;
algorithm
  (outJac,outDivLst) := match (inJac,inDlowMode)
    local
      Integer a,b;
      SimEqSystem ses;
      list<DAE.Exp> divLst;
    case ( inJac as (a,b,ses),inDlowMode) 
      equation
        (ses,divLst) = addDivExpErrorMsgtoSimEqSystem(ses,inDlowMode);
      then
        ((a,b,ses),divLst);
  end match;
end addDivExpErrorMsgtosimJac;

protected function addDivExpErrorMsgtoSimEqSystem
"function addDivExpErrorMsgtoSimEqSystem
  Traverses all subexpressions of an expression of an equation."
  input SimEqSystem inSES;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inDlowMode;
  output SimEqSystem outSES;
  output list<DAE.Exp> outDivLst;
algorithm
  (outSES,outDivLst):=
  matchcontinue (inSES,inDlowMode)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      Boolean partOfMixed;
      list<SimVar> vars;
      list<DAE.Exp> elst,elst1;
      list<tuple<Integer, Integer, SimEqSystem>> simJac,simJac1;
      Integer index;
      list<DAE.ComponentRef> crefs;
      SimEqSystem cont,cont1,elseWhenEq,elseWhen;
      list<SimEqSystem> discEqs,discEqs1;
      list<Integer> values;
      list<Integer> value_dims;
      list<tuple<DAE.Exp, Integer>> conditions;
      list<DAE.Exp> divLst,divLst1,divLst2;
      DAE.ElementSource source;
      
    case (SES_RESIDUAL(exp = e, source = source),inDlowMode)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_RESIDUAL(e,source),divLst);
    case (SES_SIMPLE_ASSIGN(cref = cr, exp = e, source = source),inDlowMode)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_SIMPLE_ASSIGN(cr, e, source),divLst);
    case (SES_ARRAY_CALL_ASSIGN(componentRef = cr, exp = e, source = source),inDlowMode)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_ARRAY_CALL_ASSIGN(cr, e, source),divLst);
        /*
         case (SES_ALGORITHM(),inDlowMode)
         equation
         e = addDivExpErrorMsgtoExp(e,inDlowMode);
         then
         SES_ALGORITHM();
         */              
    case (SES_LINEAR(index,partOfMixed,vars,elst,simJac),inDlowMode)
      equation
        (simJac1,divLst) = listMap1_2(simJac,addDivExpErrorMsgtosimJac,inDlowMode);
        (elst1,divLst1) = listMap1_2(elst,addDivExpErrorMsgtoExp,inDlowMode);
        divLst2 = listAppend(divLst,divLst1);
      then
        (SES_LINEAR(index,partOfMixed,vars,elst1,simJac1),divLst2);
    case (SES_NONLINEAR(index = index,eqs = discEqs, crefs = crefs),inDlowMode)
      equation
        (discEqs,divLst) =  listMap1_2(discEqs,addDivExpErrorMsgtoSimEqSystem,inDlowMode);
      then
        (SES_NONLINEAR(index,discEqs,crefs),divLst);
    case (SES_MIXED(index,cont,vars,discEqs,values,value_dims),inDlowMode)
      equation
        (cont1,divLst) = addDivExpErrorMsgtoSimEqSystem(cont,inDlowMode);
        (discEqs1,divLst1) = listMap1_2(discEqs,addDivExpErrorMsgtoSimEqSystem,inDlowMode);
        divLst2 = listAppend(divLst,divLst1);
      then
        (SES_MIXED(index,cont1,vars,discEqs1,values,value_dims),divLst2);
        /*    case (SES_WHEN(left = cr, right = e, conditions = conditions),inDlowMode)
         equation
         (e,divLst) = addDivExpErrorMsgtoExp(e,inDlowMode);
         then
         (SES_WHEN(cr,e,conditions),divLst);*/
        
    case (SES_WHEN(left = cr, right = e, conditions = conditions, elseWhen= NONE(), source = source),inDlowMode)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_WHEN(cr,e,conditions,NONE(),source),divLst);
    case (SES_WHEN(left = cr, right = e, conditions = conditions, elseWhen= SOME(elseWhen), source = source),inDlowMode)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,inDlowMode);
        (elseWhenEq,divLst1) = addDivExpErrorMsgtoSimEqSystem(elseWhen, inDlowMode);
        divLst2 = listAppend(divLst,divLst1);
      then
        (SES_WHEN(cr,e,conditions,SOME(elseWhenEq),source),divLst2);
    case (inSES,_) then (inSES,{});
  end matchcontinue;
end addDivExpErrorMsgtoSimEqSystem;

protected function generateParameterDivisionbyZeroTestEqn "
Author: Frenkel TUD 2010-04"
  input DAE.Exp inExp;
  output DAE.Statement outStm;
algorithm outStm := match(inExp)
  local
  case(inExp) then DAE.STMT_NORETCALL(inExp,DAE.emptyElementSource);
end match;
end generateParameterDivisionbyZeroTestEqn;

public function listMap1_2 "
  Takes a list and a function over the elements and an additional argument returning a tuple of
  two types, which is applied for each element producing two new lists.
  See also listMap_2."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  input Type_d extraArg;
  output list<Type_b> outTypeBLst;
  output list<Type_c> outTypeCLst;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_d subtypeof Any;
  partial function FuncTypeType_aToType_bType_c
    input Type_a inTypeA;
    input Type_d extraArg;
    output Type_b outTypeB;
    output list<Type_c> outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end FuncTypeType_aToType_bType_c;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  (outTypeBLst,outTypeCLst):=
  match (inTypeALst,inFuncTypeTypeAToTypeBTypeC,extraArg)
    local
      Type_b f1_1;
      list<Type_c> f2_1;
      list<Type_b> r1_1;
      list<Type_c> r2_1,r2_2;
      Type_a f;
      list<Type_a> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_,_) then ({},{});
    case ((f :: r),fn,extraArg)
      equation
        (f1_1,f2_1) = fn(f,extraArg);
        (r1_1,r2_1) = listMap1_2(r, fn,extraArg);
        r2_2 = listAppend(f2_1,r2_1);
      then
        ((f1_1 :: r1_1),r2_2);
  end match;
end listMap1_2;

protected function solve
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.Exp exp;
  output DAE.Exp solvedExp;
  output list<DAE.Statement> outAsserts;
algorithm
  (solvedExp,outAsserts) := matchcontinue(lhs, rhs, exp)
    local
      DAE.ComponentRef cr;
      DAE.Exp e1, e2, solved_exp;
      list<DAE.Statement> asserts;
      
    case (_, _, DAE.CREF(componentRef = cr))
      equation
        false = crefIsDerivative(cr);
        (solved_exp,asserts) = ExpressionSolve.solve(lhs, rhs, exp);
      then
        (solved_exp,asserts);
        
    case (_, _, DAE.CREF(componentRef = cr))
      equation
        true = crefIsDerivative(cr);
        ((e1,_)) = replaceDerOpInExpCond((lhs, SOME(cr)));
        ((e2,_)) = replaceDerOpInExpCond((rhs, SOME(cr)));
        (solved_exp,asserts) = ExpressionSolve.solve(e1, e2, exp);
      then
        (solved_exp,asserts);
  end matchcontinue;
end solve;

protected function crefIsDerivative
  "Returns true if a component reference is a derivative, otherwise false."
  input DAE.ComponentRef cr;
  output Boolean isDer;
algorithm
  isDer := matchcontinue(cr)
    local DAE.Ident ident; Boolean b;
    case (DAE.CREF_QUAL(ident = ident))
      equation
        b = stringEq(ident,DAE.derivativeNamePrefix);
      then b;
    case (_) then false;
  end matchcontinue;
end crefIsDerivative;

protected function extractVarUnit
"Extract variable's unit and displayUnit as strings from 
 DAE.VariablesAttributes structures.
 
 Author: asodja, 2010-03-11
"
  input Option<DAE.VariableAttributes> var_attr;
  output String unitStr;
  output String displayUnitStr;
algorithm
  (unitStr, displayUnitStr) := matchcontinue(var_attr)
    local
      DAE.Exp uexp, duexp;
    case ( SOME(DAE.VAR_ATTR_REAL(unit = SOME(uexp), displayUnit = SOME(duexp) )) )
      equation
        unitStr = ExpressionDump.printExpStr(uexp);
        unitStr = System.stringReplace(unitStr,"\"","");
        unitStr = System.stringReplace(unitStr,"\\","\\\\");
        displayUnitStr = ExpressionDump.printExpStr(duexp);
        displayUnitStr = System.stringReplace(displayUnitStr,"\"","");
        displayUnitStr = System.stringReplace(displayUnitStr,"\\","\\\\");
      then (unitStr, displayUnitStr);
    case ( SOME(DAE.VAR_ATTR_REAL(unit = SOME(uexp), displayUnit = NONE())) )
      equation
        unitStr = ExpressionDump.printExpStr(uexp);
        unitStr = System.stringReplace(unitStr,"\"","");
        unitStr = System.stringReplace(unitStr,"\\","\\\\");
      then (unitStr, unitStr);
    case (_)
    then ("","");
  end matchcontinue;
end extractVarUnit;

protected function getInitialValue
"Extract initial value from BackendDAE.Variable, if it has any

(merged and modified generateInitData3 and generateInitData4)"
  input BackendDAE.Var daelowVar;
  output Option<DAE.Exp> initVal;
algorithm
  initVal := matchcontinue(daelowVar)
    local
      Option<DAE.VariableAttributes> dae_var_attr;
      Values.Value value;
      DAE.Exp e;
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE(), varType = BackendDAE.STRING(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.STATE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), varType = BackendDAE.STRING(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConst(e);
      then
        SOME(e);
        /* String - Parameters without value binding. Investigate if it has start value */
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), varType = BackendDAE.STRING(), bindValue = NONE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
        /* Parameters without value binding. Investigate if it has start value */
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), bindValue = NONE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        true = Expression.isConst(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.EXTOBJ(_), bindExp = SOME(e)))
      then
        SOME(e);
    case (_) then NONE();
  end matchcontinue;
end getInitialValue;

protected function getNominalValue
"Extract nominal value from BackendDAE.Variable, if it has any"
  input BackendDAE.Var daelowVar;
  output Option<DAE.Exp> nomVal;
algorithm
  nomVal := matchcontinue(daelowVar)
    local
      Option<DAE.VariableAttributes> dae_var_attr;
      Values.Value value;
      DAE.Exp e;

    case (BackendDAE.VAR(varType = BackendDAE.REAL(), values = dae_var_attr)) equation
      e = DAEUtil.getNominalAttrFail(dae_var_attr);
      true = Expression.isConst(e);
    then SOME(e);
      
    case (_) equation
    then NONE();
  end matchcontinue;
end getNominalValue;


/****** HashTable ComponentRef -> SimVar ******/
/* a workaround to enable "cross public import" */ 


/* HashTable instance specific code */

public
type Key = DAE.ComponentRef;
type Value = SimVar;

protected function hashFunc "
  author: PA

  Calculates a hash value for DAE.ComponentRef
"
  input Key cr;
  output Integer res;
protected
  String crstr;
algorithm
  crstr := ComponentReference.printComponentRefStr(cr);
  res := stringHashDjb2(crstr);
end hashFunc;

protected function keyEqual
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
  res := ComponentReference.crefEqualNoStringCompare(key1,key2);
end keyEqual;

/* end of HashTable instance specific code */

/* Generic hashtable code below!! */
public
uniontype HashTableCrefToSimVar
  record HASHTABLE
    array<list<tuple<Key,Integer>>> hashTable " hashtable to translate Key to array indx" ;
    ValueArray valueArr "Array of values" ;
    Integer bucketSize "bucket size" ;
    Integer numberOfEntries "number of entries in hashtable" ;
  end HASHTABLE;
end HashTableCrefToSimVar;

uniontype ValueArray "array of values are expandable, to amortize the cost of adding elements in a more
efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable" ;
    Integer arrSize "size of crefArray" ;
    array<Option<tuple<Key,Value>>> valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

/*
 public function cloneHashTable "
 Author BZ 2008-06
 Make a stand-alone-copy of hashtable.
 "
 input HashTableCrefToSimVar inHash;
 output HashTableCrefToSimVar outHash;
 algorithm outHash := matchcontinue(inHash)
 local
 array<list<tuple<Key,Integer>>> arg1,arg1_2;
 Integer arg3,arg4,arg3_2,arg4_2,arg21,arg21_2,arg22,arg22_2;
 array<Option<tuple<Key,Value>>> arg23,arg23_2;
 case(HASHTABLE(arg1,VALUE_ARRAY(arg21,arg22,arg23),arg3,arg4))
 equation
 arg1_2 = arrayCopy(arg1);
 arg21_2 = arg21;
 arg22_2 = arg22;
 arg23_2 = arrayCopy(arg23);
 arg3_2 = arg3;
 arg4_2 = arg4;
 then
 HASHTABLE(arg1_2,VALUE_ARRAY(arg21_2,arg22_2,arg23_2),arg3_2,arg4_2);
 end matchcontinue;
 end cloneHashTable;
 
 public function nullHashTable "
 author: PA
 
 Returns an empty HashTable.
 Using the bucketsize 100 and array size 10.
 "
 output HashTableCrefToSimVar hashTable;
 array<list<tuple<Key,Integer>>> arr;
 list<Option<tuple<Key,Value>>> lst;
 array<Option<tuple<Key,Value>>> emptyarr;
 algorithm
 arr := fill({}, 0);
 emptyarr := listArray({});
 hashTable := HASHTABLE(arr,VALUE_ARRAY(0,0,emptyarr),0,0);
 end nullHashTable;
 */

public function emptyHashTable "
  author: PA
  Returns an empty HashTable.
  Using the bucketsize 100 and array size 10."
  output HashTableCrefToSimVar hashTable;
protected
  array<list<tuple<Key,Integer>>> arr;
  list<Option<tuple<Key,Value>>> lst;
  array<Option<tuple<Key,Value>>> emptyarr;
algorithm
  arr := arrayCreate(1000, {});
  emptyarr := arrayCreate(100, NONE());
  hashTable := HASHTABLE(arr,VALUE_ARRAY(0,100,emptyarr),1000,0);
end emptyHashTable;

/*
 public function isEmpty "Returns true if hashtable is empty"
 input HashTableCrefToSimVar hashTable;
 output Boolean res;
 algorithm
 res := matchcontinue(hashTable)
 case(HASHTABLE(_,_,_,0)) then true;
 case(_) then false;
 end matchcontinue;
 end isEmpty;
 */

public function add "
  author: PA

  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value.
"
  input tuple<Key,Value> entry;
  input HashTableCrefToSimVar hashTable;
  output HashTableCrefToSimVar outHashTable;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
        
        /* adding when already present => Updating value */
    case ((newv as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then HASHTABLE(hashvec,varr_1,bsize,n);
    case (_,_)
      equation
        print("- HashTableCrefToSimVar.add failed\n");
      then
        fail();
  end matchcontinue;
end add;
/*
 public function anyKeyInHashTable "Returns true if any of the keys are present in the hashtable. Stops and returns true upon first occurence"
 input list<Key> keys;
 input HashTableCrefToSimVar ht;
 output Boolean res;
 algorithm
 res := matchcontinue(keys,ht)
 local Key key;
 case({},ht) then false;
 case(key::keys,ht) equation
 _ = get(key,ht);
 then true;
 case(_::keys,ht) then anyKeyInHashTable(keys,ht);
 end matchcontinue;
 end anyKeyInHashTable;
 
 public function addListNoUpd "adds several keys with the same value, using addNuUpdCheck. Can be used to use HashTable as a Set"
 input list<Key> keys;
 input Value v;
 input HashTableCrefToSimVar ht;
 output HashTableCrefToSimVar outHt;
 algorithm
 ht := matchcontinue(keys,v,ht)
 local Key key;
 case ({},v,ht) then ht;
 case(key::keys,v,ht) equation
 ht = addNoUpdCheck((key,v),ht);
 ht = addListNoUpd(keys,v,ht);
 then ht;
 end matchcontinue;
 end addListNoUpd;
 */
public function addNoUpdCheck "
  author: PA

  Add a Key-Value tuple to hashtable.
  If the Key-Value tuple already exists, the function updates the Value.
"
  input tuple<Key,Value> entry;
  input HashTableCrefToSimVar hashTable;
  output HashTableCrefToSimVar outHashTable;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      ValueArray varr_1,varr;
      list<tuple<Key,Integer>> indexes;
      array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      tuple<Key,Value> v,newv;
      Key key;
      Value value;
      
      // adding when not existing previously 
    case ((v as (key,value)),(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then HASHTABLE(hashvec_1,varr_1,bsize,n_1);
        
        // failure
    case (_,_)
      equation
        print("- HashTableCrefToSimVar.addNoUpdCheck failed\n");
      then
        fail();
  end matchcontinue;
end addNoUpdCheck;
/*
 public function delete "
 author: PA
 
 delete the Value associatied with Key from the HashTable.
 Note: This function does not delete from the index table, only from the ValueArray.
 This means that a lot of deletions will not make the HashTable more compact, it will still contain
 a lot of incices information.
 "
 input Key key;
 input HashTableCrefToSimVar hashTable;
 output HashTableCrefToSimVar outHahsTable;
 algorithm
 outVariables:=
 matchcontinue (key,hashTable)
 local
 Integer hval,indx,newpos,n,n_1,bsize,indx_1;
 ValueArray varr_1,varr;
 list<tuple<Key,Integer>> indexes;
 array<list<tuple<Key,Integer>>> hashvec_1,hashvec;
 String name_str;
 tuple<Key,Value> v,newv;
 Key key;
 Value value;
 // * adding when already present => Updating value * /
  case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
  equation
  (_,indx) = get1(key, hashTable);
  indx_1 = indx - 1;
  varr_1 = valueArrayClearnth(varr, indx);
  then HASHTABLE(hashvec,varr_1,bsize,n);
  case (_,hashTable)
  equation
  print("-HashTableCrefToSimVar.delete failed\n");
  print("content:"); dumpHashTable(hashTable);
  then
  fail();
  end matchcontinue;
  end delete;
  */

public function get "
author: PA

   Returns a Value given a Key and a HashTable.
"
  input Key key;
  input HashTableCrefToSimVar hashTable;
  output Value value;
algorithm
  (value,_):= get1(key,hashTable);
end get;

protected function get1 "help function to get"
  input Key key;
  input HashTableCrefToSimVar hashTable;
  output Value value;
  output Integer indx;
algorithm
  (value,indx):=
  match (key,hashTable)
    local
      Integer hval,hashindx,bsize,n;
      list<tuple<Key,Integer>> indexes;
      Value v;
      array<list<tuple<Key,Integer>>> hashvec;
      ValueArray varr;
      Key k;
    case (key,(hashTable as HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = get2(key, indexes);
        (k, v) = valueArrayNth(varr, indx);
        true = keyEqual(k, key);
      then
        (v,indx);
  end match;
end get1;

protected function get2 "
 author: PA

  Helper function to get
"
  input Key key;
  input list<tuple<Key,Integer>> keyIndices;
  output Integer index;
algorithm
  index :=
  matchcontinue (key,keyIndices)
    local
      Key key2;
      list<tuple<Key,Integer>> xs;
    case (key,((key2,index) :: _))
      equation
        true = keyEqual(key, key2);
      then
        index;
    case (key,(_ :: xs))
      equation
        index = get2(key, xs);
      then
        index;
  end matchcontinue;
end get2;
/*
 public function hashTableValueList "return the Value entries as a list of Values"
 input HashTableCrefToSimVar hashTable;
 output list<Value> valLst;
 algorithm
 valLst := Util.listMap(hashTableList(hashTable),Util.tuple22);
 end hashTableValueList;
 
 public function hashTableKeyList "return the Key entries as a list of Keys"
 input HashTableCrefToSimVar hashTable;
 output list<Key> valLst;
 algorithm
 valLst := Util.listMap(hashTableList(hashTable),Util.tuple21);
 end hashTableKeyList;
 
 public function hashTableList "returns the entries in the hashTable as a list of tuple<Key,Value>"
 input HashTableCrefToSimVar hashTable;
 output list<tuple<Key,Value>> tplLst;
 algorithm
 tplLst := matchcontinue(hashTable)
 local ValueArray varr;
 case(HASHTABLE(valueArr = varr)) equation
 tplLst = valueArrayList(varr);
 then tplLst;
 end matchcontinue;
 end hashTableList;
 
 public function valueArrayList "
 author: PA
 Transforms a ValueArray to a tuple<Key,Value> list
 "
 input ValueArray valueArray;
 output list<tuple<Key,Value>> tplLst;
 algorithm
 tplLst :=
 matchcontinue (valueArray)
 local
 array<Option<tuple<Key,Value>>> arr;
 tuple<Key,Value> elt;
 Integer lastpos,n,size;
 list<tuple<Key,Value>> lst;
 case (VALUE_ARRAY(numberOfElements = 0,valueArray = arr)) then {};
 case (VALUE_ARRAY(numberOfElements = 1,valueArray = arr))
 equation
 SOME(elt) = arr[0 + 1];
 then
 {elt};
 case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr))
 equation
 lastpos = n - 1;
 lst = valueArrayList2(arr, 0, lastpos);
 then
 lst;
 end matchcontinue;
 end valueArrayList;
 
 protected function valueArrayList2 "Helper function to valueArrayList"
 input array<Option<tuple<Key,Value>>> inVarOptionArray1;
 input Integer inInteger2;
 input Integer inInteger3;
 output list<tuple<Key,Value>> outVarLst;
 algorithm
 outVarLst:=
 matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
 local
 tuple<Key,Value> v;
 array<Option<tuple<Key,Value>>> arr;
 Integer pos,lastpos,pos_1;
 list<tuple<Key,Value>> res;
 case (arr,pos,lastpos)
 equation
 (pos == lastpos) = true;
 SOME(v) = arr[pos + 1];
 then
 {v};
 case (arr,pos,lastpos)
 equation
 pos_1 = pos + 1;
 SOME(v) = arr[pos + 1];
 res = valueArrayList2(arr, pos_1, lastpos);
 then
 (v :: res);
 case (arr,pos,lastpos)
 equation
 pos_1 = pos + 1;
 NONE = arr[pos + 1];
 res = valueArrayList2(arr, pos_1, lastpos);
 then
 (res);
 end matchcontinue;
 end valueArrayList2;
 */
public function valueArrayLength "
  author: PA

  Returns the number of elements in the ValueArray
"
  input ValueArray valueArray;
  output Integer size;
algorithm
  size := match (valueArray)
    case (VALUE_ARRAY(numberOfElements = size)) then size;
  end match;
end valueArrayLength;

public function valueArrayAdd "function: valueArrayAdd
  author: PA
  Adds an entry last to the ValueArray, increasing array size
  if no space left by factor 1.4
"
  input ValueArray valueArray;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray:=
  matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<tuple<Key,Value>>> arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,size,arr_1);
        
    case (VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),entry)
      equation
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(entry));
      then
        VALUE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation
        print("-HashTableCrefToSimVar.valueArrayAdd failed\n");
      then
        fail();
  end matchcontinue;
end valueArrayAdd;

public function valueArraySetnth "function: valueArraySetnth
  author: PA
  Set the n:th variable in the ValueArray to value.
"
  input ValueArray valueArray;
  input Integer pos;
  input tuple<Key,Value> entry;
  output ValueArray outValueArray;
algorithm
  outValueArray:=
  matchcontinue (valueArray,pos,entry)
    local
      array<Option<tuple<Key,Value>>> arr_1,arr;
      Integer n,size;
    case (VALUE_ARRAY(n,size,arr),pos,entry)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        VALUE_ARRAY(n,size,arr_1);
    case (_,_,_)
      equation
        print("-HashTableCrefToSimVar.valueArraySetnth failed\n");
      then
        fail();
  end matchcontinue;
end valueArraySetnth;
/*
 public function valueArrayClearnth "
 author: PA
 Clears the n:th variable in the ValueArray (set to NONE).
 "
 input ValueArray valueArray;
 input Integer pos;
 output ValueArray outValueArray;
 algorithm
 outValueArray:=
 matchcontinue (valueArray,pos)
 local
 array<Option<tuple<Key,Value>>> arr_1,arr;
 Integer n,size,pos;
 case (VALUE_ARRAY(n,size,arr),pos)
 equation
 (pos < size) = true;
 arr_1 = arrayUpdate(arr, pos + 1, NONE);
 then
 VALUE_ARRAY(n,size,arr_1);
 case (_,_)
 equation
 print("-HashTableCrefToSimVar.valueArrayClearnth failed\n");
 then
 fail();
 end matchcontinue;
 end valueArrayClearnth;
 */
public function valueArrayNth "function: valueArrayNth
  author: PA

  Retrieve the n:th Vale from ValueArray, index from 0..n-1.
 "
  input ValueArray valueArray;
  input Integer pos;
  output Key key;
  output Value value;
algorithm
  (key, value) :=
  matchcontinue (valueArray,pos)
    local
      Key k;
      Value v;
      Integer n;
      array<Option<tuple<Key,Value>>> arr;
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        SOME((k,v)) = arr[pos + 1];
      then
        (k, v);
    case (VALUE_ARRAY(numberOfElements = n,valueArray = arr),pos)
      equation
        (pos < n) = true;
        NONE() = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;


/***** end of HashTable ComponentRef -> SimVar *******/

public function functionInfo
  input Function fn;
  output Absyn.Info info;
algorithm
  info := match fn
    case FUNCTION(info = info) then info;
    case EXTERNAL_FUNCTION(info = info) then info;
    case RECORD_CONSTRUCTOR(info = info) then info;
  end match;
end functionInfo;


function twodigit
  input Integer i;
  output String outS;
algorithm
  outS := 
  matchcontinue (i)
    local String s;
    case (i)
      equation
        (i < 10) = true;
        s = intString(i);
        s = stringAppend("0",s);
      then
        s;
    case (i)
      then
        intString(i);
  end matchcontinue;
end twodigit;




/**************************************/
/************* for index ***************/

protected function setVariableDerIndex "
Author bz 2008-06
This function investigates the system of equations finding an order for derivative variables.
It only selects variables that have an derivative order, order=0 (no derivative) will not be included.
"
  input BackendDAE.BackendDAE inDlow;
  output list<tuple<DAE.ComponentRef, Integer>> outOrder;
algorithm outOrder := matchcontinue(inDlow)
  local
    BackendDAE.Variables dovars;
    BackendDAE.EquationArray deqns;
    list<BackendDAE.Equation> eqns;
    list<BackendDAE.Var> vars;
    list<Expression.Exp> derExps;
    list<tuple<DAE.ComponentRef, Integer>> variableIndex;
    list<list<DAE.ComponentRef>> firstOrderVars;
    list<DAE.ComponentRef> firstOrderVarsFiltered;
    String eq_str;
    BackendDAE.EqSystem syst;
  case(inDlow as BackendDAE.DAE(eqs={syst}))
    equation
      
      dovars = BackendVariable.daeVars(syst);
      deqns = BackendEquation.daeEqns(syst);
      vars = BackendDAEUtil.varList(dovars);
      eqns = BackendDAEUtil.equationList(deqns);
      derExps = makeCallDerExp(vars);
      Debug.fcall("cppvar",print, " possible der exp: " +& Util.stringDelimitList(Util.listMap(derExps, ExpressionDump.printExpStr), ", ") +& "\n");
      eqns = flattenEqns(eqns,inDlow);
     // eq_str=dumpEqLst(eqns);
      // Debug.fcall("cppvar",print,"filtered eq's " +& eq_str +& "\n");
      (variableIndex,firstOrderVars) = Util.listMap22(derExps,locateDerAndSerachOtherSide,eqns,eqns);
       Debug.fcall("cppvar",print,"united variables \n");
      firstOrderVarsFiltered = Util.listFold(firstOrderVars,Util.listUnion,{});
      Debug.fcall("cppvar",print,"list fold variables \n");
      variableIndex = setFirstOrderInSecondOrderVarIndex(variableIndex,firstOrderVarsFiltered);
     // Debug.fcall("cppvar",print,"Deriving Variable indexis:\n" +& dumpVariableindex(variableIndex) +& "\n");
     then
      variableIndex;
  case(_)
      equation
         print(" Failure in setVariableDerIndex \n");
         then fail();
 end matchcontinue;
end setVariableDerIndex;

protected function flattenEqns "
This function flattens all equations
"
input list<BackendDAE.Equation> eqns;
input BackendDAE.BackendDAE dlow;
output list<BackendDAE.Equation> oeqns;
algorithm oeqns := matchcontinue(eqns, dlow)
  local 
    BackendDAE.Equation eq;
    BackendDAE.WhenEquation when_eq;
    BackendDAE.EquationArray eqns_array;
    list<BackendDAE.Equation> rest,rec,le;
    list<list<BackendDAE.Equation>> lle;
    Integer idx;
    String str;
  case({},_) then {};
    case( (eq as BackendDAE.EQUATION(exp=_)) ::rest , dlow)
    equation
      rec = flattenEqns(rest,dlow);
      rec = Util.listUnionElt(eq,rec);
      then
        rec;
     case( (eq as BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(_,_,_,_))) ::rest , dlow)
     equation
       str = BackendDump.equationStr(eq);
       Debug.fcall("cppvar",print,"Found When eq " +& str +& "\n");
       rec = flattenEqns(rest,dlow);
       //rec = Util.listUnionElt(eq,rec);
      then
        rec;
     case( (eq as BackendDAE.ALGORITHM(index=_)) ::rest , dlow)
     equation
       //str = DAELow.equationStr(eq);
       rec = flattenEqns(rest,dlow);
       rec = Util.listUnionElt(eq,rec);
      then
        rec;
     case( (eq as BackendDAE.ARRAY_EQUATION(index=_)) ::rest , dlow)
     equation
       //str = DAELow.equationStr(eq);
       rec = flattenEqns(rest,dlow);
       rec = Util.listUnionElt(eq,rec);
      then
        rec;
            
  case(_::rest,dlow)
    equation 
     // str = BackendDAE.equationStr(eq);
      Debug.fcall("cppvar",print," FAILURE IN flattenEqns possible unsupported equation...\n" /*+& str*/);
    then
      fail();
   end matchcontinue;
end flattenEqns;

protected function makeCallDerExp "
Author bz 2008-06
For all state-variables, generate an der(var) expression. 
"
  input list<BackendDAE.Var> inVars;
  output list<Expression.Exp> outDerExps;
algorithm outDerExps := matchcontinue(inVars)
  local
    BackendDAE.Var v;
    list<BackendDAE.Var> vars;
    list<Expression.Exp> rec;
    DAE.ComponentRef cr;
  case({}) then {};
  case((v as BackendDAE.VAR(varKind = BackendDAE.STATE(),varName = cr))::vars)
    equation
      //true = DAELow.isStateVar(v);
      rec = makeCallDerExp(vars);
    then
      DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(cr,DAE.ET_REAL())},DAE.callAttrBuiltinReal)::rec;
  //case((v as DAELow.VAR(varKind = DAELow.DUMMY_STATE(),varName = cr))::vars)
   // equation
      //true = DAELow.isStateVar(v);
   //   rec = makeCallDerExp(vars);
   // then
    //  DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(cr,DAE.ET_OTHER())},false,false,DAE.ET_OTHER(),DAE.NO_INLINE())::rec;
  case(v::vars)
    equation
      rec = makeCallDerExp(vars);
    then
      rec;
end matchcontinue;
end makeCallDerExp;

protected function locateDerAndSerachOtherSide "
Author bz 2008-06
helper function for setVariableDerIndex, locates the equation(/s) containing the current derivate.
From there search for the variable beeing derived, exclude 'current equation'
"
  input Expression.Exp derExp;
  input list<BackendDAE.Equation> inEqns;
  input list<BackendDAE.Equation> inEqnsOrg;
  output tuple<DAE.ComponentRef, Integer> out;
  output list<DAE.ComponentRef> sysOrdOneVars;
algorithm (out,sysOrdOneVars) := matchcontinue(derExp,inEqns,inEqnsOrg)
  local 
    Expression.Exp e1,e2,deriveVar;
    list<Boolean> b;
    list<BackendDAE.Equation> eqs;
    BackendDAE.Equation eq;
    list<Expression.Exp> expCref;
    list<DAE.ComponentRef> crefs;
    DAE.ComponentRef cr;
    Integer rec,i1;
    list<tuple<DAE.ComponentRef, Integer>> multipleHits;
    tuple<DAE.ComponentRef, Integer> highestIndex;
  case( (derExp as DAE.CALL( expLst = {DAE.CREF(cr,_)})), {},_) then ((cr,0),{});
  case( (derExp as DAE.CALL( expLst = {deriveVar as DAE.CREF(cr,_)})), (eq as BackendDAE.EQUATION(e1,e2,_))::eqs,inEqnsOrg)
    equation
      true = Expression.expEqual(e1,derExp);
      inEqnsOrg = Util.listRemoveOnTrue(eq,Util.isEqual,inEqnsOrg);
      Debug.fcall("cppvar",print, "\nFound equation containing " +& ExpressionDump.printExpStr(derExp) +& " Other side: " +& ExpressionDump.printExpStr(e2) +& ", extracted crefs: " +& ExpressionDump.printExpStr(deriveVar) +& "\n");
      (rec,crefs) = locateDerAndSerachOtherSide2(DAE.CALL(Absyn.IDENT("der"),{e2},DAE.callAttrBuiltinReal),inEqnsOrg);
      (highestIndex as (_,i1),_) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
      rec = rec+1;
      highestIndex = Util.if_(i1>rec,highestIndex,(cr,rec-1));
      //highestIndex = (cr,1);
    then
      (highestIndex,crefs);
  case( (derExp as DAE.CALL( expLst = {deriveVar as DAE.CREF(cr,_)})), (eq as BackendDAE.EQUATION(e1,e2,_))::eqs,inEqnsOrg)
    equation
      true = Expression.expEqual(e2,derExp);
      inEqnsOrg = Util.listRemoveOnTrue(eq,Util.isEqual,inEqnsOrg);
      Debug.fcall("cppvar",print, "\nFound equation containing " +& ExpressionDump.printExpStr(derExp) +& " Other side: " +& ExpressionDump.printExpStr(e1) +& ", extracted crefs: " +& ExpressionDump.printExpStr(deriveVar) +& "\n");
      (rec,crefs) = locateDerAndSerachOtherSide2(DAE.CALL(Absyn.IDENT("der"),{e1},DAE.callAttrBuiltinReal),inEqnsOrg);
      (highestIndex as (_,i1),_) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
      rec = rec+1;
      highestIndex = Util.if_(i1>rec,highestIndex,(cr,rec-1));
      //highestIndex = (cr,1);
    then
      (highestIndex,crefs);
  case(derExp, (eq as BackendDAE.EQUATION(e1,e2,_))::eqs,inEqnsOrg)
    equation
      false = Expression.expEqual(e1,derExp);
      false = Expression.expEqual(e2,derExp);
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);
 case(derExp, (eq as BackendDAE.ARRAY_EQUATION(index=_))::eqs,inEqnsOrg)
    equation
      Debug.fcall("cppvar",print, "\nFound  array equation is not supported yet  searching for varibale index  \n");
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);
  case(derExp, (eq as BackendDAE.IF_EQUATION(indx=_))::eqs,inEqnsOrg)
    equation
      Debug.fcall("cppvar",print, "\nFound  if equation is not supported yet  searching for varibale index  \n");
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);
 case(derExp, (eq as BackendDAE.ALGORITHM(index=_))::eqs,inEqnsOrg)
    equation
      Debug.fcall("cppvar",print, "\nFound  algorithm is not supported yet  searching for varibale index  \n");
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);
 
end matchcontinue;
end locateDerAndSerachOtherSide;

protected function locateDerAndSerachOtherSide2 "
Author bz 2008-06
helper function for locateDerAndSerachOtherSide
"
  input Expression.Exp inDer;
  input list<BackendDAE.Equation> inEqns;
  output Integer oi;
  output list<DAE.ComponentRef> firstOrderDers;
algorithm (oi,firstOrderDers) := matchcontinue(inDer,inEqns)
  case(DAE.CALL(expLst = {DAE.CREF(_,_)}),inEqns)
    equation
      (oi,firstOrderDers) = locateDerAndSerachOtherSide22(inDer,inEqns);
    then
      (oi,firstOrderDers);
  case(_,_) then (0,{});
end matchcontinue;
  end locateDerAndSerachOtherSide2;
  
protected function locateDerAndSerachOtherSide22 "
Author bz 2008-06
recursivly search equations for der(..) expressions.
When found, return 1... this since we are only interested in second order system, at most.
If we do not find any more derivative, 0 is returned. 
"
  input Expression.Exp inDer;
  input list<BackendDAE.Equation> inEqns;
  output Integer oi;
  output list<DAE.ComponentRef> firstOrderDers;
algorithm (oi,firstOrderDers) := matchcontinue(inDer,inEqns)
  local
    Expression.Exp e1,e2;
    DAE.ComponentRef cr;
    list<Expression.Exp> args;
    list<BackendDAE.Equation> rest;
  case(_,{}) then (0,{});
  case(inDer,(BackendDAE.EQUATION(e1,e2,_)::rest))
    equation
      true = Expression.expEqual(inDer,e1);
      {cr} = Expression.extractCrefsFromExp(e1);
      Debug.fcall("cppvar",BackendDump.debugStrExpStrExpStrExpStr,(" found derivative for ",inDer," in equation ",e1," = ",e2, "\n"));
    then
      (1,{cr});
  case(inDer,(BackendDAE.EQUATION(e1,e2,_)::rest))
    equation
      true = Expression.expEqual(inDer,e2);
      {cr} = Expression.extractCrefsFromExp(e2);
      Debug.fcall("cppvar",BackendDump.debugStrExpStrExpStrExpStr,(" found derivative for ",inDer," in equation ",e1," = ",e2,"\n"));
    then
      (1,{cr});
  case(inDer,(BackendDAE.EQUATION(e1,e2,_)::rest))
    equation
      Debug.fcall("cppvar",BackendDump.debugExpStrExpStrExpStr,(inDer," NOT contained in ",e1," = ",e2,"\n"));
      (oi,firstOrderDers) = locateDerAndSerachOtherSide22(inDer,rest);
    then
      (oi,firstOrderDers);
end matchcontinue;
end locateDerAndSerachOtherSide22;

protected function setFirstOrderInSecondOrderVarIndex "
Author bz 2008-06
"
  input list<tuple<DAE.ComponentRef, Integer>> inRefs;
  input list<DAE.ComponentRef> firstOrderInSec;
  output list<tuple<DAE.ComponentRef, Integer>> outRefs;
algorithm (outRefs) := matchcontinue(inRefs,firstOrderInSec)
  local
    list<tuple<DAE.ComponentRef, Integer>> rest;
    Integer idx;
    DAE.ComponentRef cr;
    list<Boolean> bl;
    
  case({},_) then {};
  case((cr,_)::rest,firstOrderInSec)
    equation
      bl = Util.listMap1(firstOrderInSec,ComponentReference.crefEqual,cr);
      true = Util.boolOrList(bl);
      rest = setFirstOrderInSecondOrderVarIndex(rest,firstOrderInSec);
    then
      (cr,2)::rest;
  case((cr,1)::rest,firstOrderInSec)
    equation      
      rest = setFirstOrderInSecondOrderVarIndex(rest,firstOrderInSec);
    then
      (cr,1)::rest;
  case((cr,idx)::rest,firstOrderInSec)
    equation      
      rest = setFirstOrderInSecondOrderVarIndex(rest,firstOrderInSec);
    then
      (cr,idx)::rest;
end matchcontinue;
end setFirstOrderInSecondOrderVarIndex;

/********* for dimension *******/

protected function calculateVariableDimensions "
Calcuates the dimesion of the statevaribale with order 0,1,2
"
   input list<tuple<DAE.ComponentRef, Integer>> in_vars;
   output Integer OutInteger1; //number of ordinary differential equations of 1st order
   output Integer OutInteger2; //number of ordinary differential equations of 2st order
  
algorithm (OutInteger1,OutInteger2) := matchcontinue(in_vars)
  local
    list<tuple<DAE.ComponentRef, Integer>> rest;
    DAE.ComponentRef cr;
    Integer nvar1,nvar2;
  case({}) then (0,0);
  case((cr,0)::rest)
    equation
     (nvar1,nvar2) = calculateVariableDimensions(rest);
    then
      (nvar1+1,nvar2);
  case((cr,_)::rest)
    equation      
      (nvar1,nvar2) = calculateVariableDimensions(rest);
    then
      (nvar1,nvar2+1);
end matchcontinue;
end calculateVariableDimensions;

/********************/
protected function dimensions

input BackendDAE.BackendDAE dae_low;
output Integer OutInteger1; //number of ordinary differential equations of 1st order
output Integer OutInteger2; //number of ordinary differential equations of 2st order
algorithm (OutInteger1,OutInteger2):= matchcontinue(dae_low)
  local 
    Integer nvar1,nvar2;
    list<tuple<DAE.ComponentRef, Integer>> ordered_states;
  case(dae_low)
    equation
       ordered_states=setVariableDerIndex(dae_low);
      (nvar1,nvar2)=calculateVariableDimensions(ordered_states);
      then
        (nvar1,nvar2);
end matchcontinue;
end dimensions;

/******************/
/******************/
protected function stateindex 

  input DAE.ComponentRef var;
  input list<tuple<DAE.ComponentRef, Integer>> odered_vars;
  output Integer new_index;
algorithm (new_index) := matchcontinue(var,odered_vars)
  local DAE.ComponentRef cr;
        list<tuple<DAE.ComponentRef, Integer>> rest;
        Integer i;
  case(_,{}) then (-1);
  case(var ,((cr,i)::_))    
    equation
      true = ComponentReference.crefEqual(var,cr);
    Debug.fcall("cppvarindex",BackendDump.debugStrCrefStrIntStr,(" found state variable ",var," with index: ",i,"\n"));
  // Debug.fcall("cppvar",print, +& " with index: " +& intString(i) +& "\n");
    then 
      (i);
  case(var,_::rest)
    equation
     
      (i)=stateindex(var,rest);
       Debug.fcall("cppvarindex",BackendDump.debugStrCrefStrIntStr,(" state variable ",var," with index: ",i,"\n"));
  
   //  Debug.fcall("cppvar",print, +& " with index: " +& intString(i) +& "\n");
    then (i);
end matchcontinue;
end stateindex;

protected function stateindex1

 
 input list<SimVar> stateVars;
 input BackendDAE.BackendDAE dae_low;
 output list<SimVar> stateVars1;
algorithm (stateVars1):= matchcontinue(stateVars,dae_low)
  local 
     list<SimVar> new_list;
     SimVar new_simvar;
     SimVar v;
     list<SimVar> rest;
  case({},dae_low)
     then 
       {};
  case((v as SIMVAR(name=_))::rest,dae_low)
     equation
      new_list= stateindex1(rest,dae_low);
      new_simvar =stateindex2(v,dae_low);
    
     then
      (new_simvar::new_list);
end matchcontinue;
end stateindex1;

protected function stateindex2
 input SimVar stateVars;
 input BackendDAE.BackendDAE dae_low;
 output SimVar outSimVar;
algorithm (outSimVar):= matchcontinue(stateVars,dae_low)
  local 
    list<tuple<DAE.ComponentRef, Integer>> ordered_states;
    Integer new_index;
    DAE.ComponentRef name;
    BackendDAE.VarKind varKind;
    String comment,unit,displayUnit;
    Integer index;
    Option<DAE.Exp> initialValue;
    Option<DAE.Exp> nominalValue;
    Boolean isFixed,isDiscrete;
    DAE.ExpType type_;
    // arrayCref is the name of the array if this variable is the first in that
    // array
    Option<DAE.ComponentRef> arrayCref;
    AliasVariable aliasvar;
    DAE.ElementSource source;
    Causality causality;
    Option<Integer> variable_index;
    list <String> numArrayElement;
  case(SIMVAR(name=name,varKind=varKind,comment=comment,unit=unit,displayUnit=displayUnit,index=index,initialValue=initialValue,nominalValue=nominalValue,isFixed=isFixed,type_=type_,isDiscrete=isDiscrete,arrayCref=arrayCref,aliasvar=aliasvar,source=source,causality=causality,variable_index=variable_index,numArrayElement=numArrayElement),dae_low)
     equation
      Debug.fcall("cppvarindex",BackendDump.debugStrCrefStr,(" search index for state variable ",name,"\n"));
      ordered_states=setVariableDerIndex(dae_low);
      new_index=stateindex(name,ordered_states);
           
    then 
     SIMVAR(name,varKind,comment,unit,displayUnit,new_index,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
end matchcontinue;
end stateindex2;


protected function setStatesVectorIndex "
sorts the states in the state vector correponding to the variable index (0,1,2) and
sets the vectorindex attribute for each state variable in the states vector(z)
e.g der(x)=y
    der(y)=a
    der(z)=a -> z={z,x,y}
"
input list<SimVar> in_vars;
output list<SimVar> out_vars;
algorithm out_vars := matchcontinue(in_vars)
  local
    list<SimVar>  vars1,vars2,vars3,vars4,vars5;
   Integer i;
  case(in_vars)
    equation
      (vars1,vars2,vars3) =  partitionStatesVector(in_vars);
       vars4 = listAppend(vars1,vars2);
       vars5 = listAppend(vars4,vars3);
       vars5=setStatesVectorIndex2(vars5,0);
    then 
       vars5;
end matchcontinue;
end setStatesVectorIndex;

protected function setStatesVectorIndex2"
Help function for setStatesVectorIndex
iterates the states vector an increments the vector index of each variable
"
input list<SimVar> in_vars;
input Integer index;
output list<SimVar> out_vars;
algorithm
  out_vars := matchcontinue(in_vars,index)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Option<DAE.Exp> initialValue;
      Option<DAE.Exp> nominalValue;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      // arrayCref is the name of the array if this variable is the first in that
      // array
      Option<DAE.ComponentRef> arrayCref;
      AliasVariable aliasvar;
      DAE.ElementSource source;
      Causality causality;
      Option<Integer> variable_index;
      list<SimVar> rest,indexed_vector;
      list <String> numArrayElement;
    case({},_) then {};
    case(SIMVAR(name=name,varKind=varKind,comment=comment,unit=unit,displayUnit=displayUnit,initialValue=initialValue,nominalValue=nominalValue,isFixed=isFixed,type_=type_,isDiscrete=isDiscrete,arrayCref=arrayCref,aliasvar=aliasvar,source=source,causality=causality,variable_index=variable_index,numArrayElement=numArrayElement) :: rest,index)
      equation
        indexed_vector = setStatesVectorIndex2(rest,index+1);
      then 
        SIMVAR(name,varKind,comment,unit,displayUnit,index,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,SOME(index),numArrayElement)::indexed_vector;
  end matchcontinue;
end setStatesVectorIndex2;


protected function partitionStatesVector "
partitioning the input vector into 3 state vectors  including   variables with corresponding variable indexes 0,1,2  
e.g  der(x) = y;
     der(y)= a;
     der(z) =a;
     z=b -> output:  {z} {x} {y}
"
  input list<SimVar> in_vars "list with unsorted state variables";
  output list<SimVar> oder_0;
  output list<SimVar> oder_1;
  output list<SimVar> oder_2;
algorithm (oder_0,oder_1,oder_2):= matchcontinue(in_vars)
  local
    list<SimVar> rest, vars1,vars2,vars3;
    SimVar variable;
    Integer vi;
  case({}) then ({},{},{});
  case((variable as SIMVAR(index=vi))::rest)
    equation
      (vars1,vars2,vars3)    =    partitionStatesVector(rest);
      (vars1,vars2,vars3)    =    addVariableToStateVector(vars1,vars2,vars3,variable,vi);
    then 
     (vars1,vars2,vars3);
 
end matchcontinue;
end partitionStatesVector;

protected function addVariableToStateVector "
Helper function for setVectorIndexes;
"
  input list<SimVar> in_0;
  input list<SimVar> in_1;
  input list<SimVar> in_2;
  input SimVar variable;
  input Integer variable_index;
  output list<SimVar>  out_0;
  output list<SimVar>  out_1;
  output list<SimVar>  out_2;
algorithm (out_0,out_1,out_2) := matchcontinue(in_0,in_1,in_2,variable,variable_index)
  case(in_0,in_1,in_2,variable,0) then (variable::in_0,in_1,in_2);
  case(in_0,in_1,in_2,variable,1) then (in_0,variable::in_1,in_2);
  case(in_0,in_1,in_2,variable,2) then (in_0,in_1,variable::in_2);
  case(_,_,_,_,_) equation print(" failure in addVariableToStateVector  \n"); then fail();
end matchcontinue;
end addVariableToStateVector;

protected function generateDerStates "
generates for each state in the states vector a corresponding der state
"
  input list<SimVar> in_varinfo_lst;
  output list<SimVar> out_varinfo_lst;
algorithm out_varinfo_lst := matchcontinue(in_varinfo_lst)
  local 
    list<SimVar> rest,dv_list;
    SimVar v;
    SimVar dv;
    Integer var_index;
    String s;
  case({}) then {};
  case( v::rest )
    equation
      dv = generateDerStates2(v);
     // s= dumpVarInfo(dv);
      //Debug.fcall("cppvar",print,"Generate der state" +& s +& "\n" );
      dv_list = generateDerStates(rest);
     then
       dv::dv_list;
  end matchcontinue;
end generateDerStates;

protected function generateDerStates2 "
Helper function for varsToVarInfo2
"
   input SimVar in_vf;
   output SimVar out_vf;
 
algorithm
  out_vf := matchcontinue(in_vf)
    local 
      DAE.ComponentRef name;
      BackendDAE.VarKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Option<DAE.Exp> initialValue;
      Option<DAE.Exp> nominalValue;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      // arrayCref is the name of the array if this variable is the first in that
      // array
      Option<DAE.ComponentRef> arrayCref;
      AliasVariable aliasvar;
      DAE.ElementSource source;
      Causality causality;
      Option<Integer> variable_index;
      DAE.ComponentRef cr_1;
      String name_str,id_str;
      list <String> numArrayElement;
    case(SIMVAR(name,varKind,comment,unit,displayUnit,0,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)) 
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = stringAppendList({DAE.derivativeNamePrefix,"." ,name_str});
        cr_1 = ComponentReference.makeCrefIdent(id_str,DAE.ET_REAL(),{});
      then
        SIMVAR(cr_1,varKind,comment,unit,displayUnit,0,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
    case(SIMVAR(name,varKind,comment,unit,displayUnit,1,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)) 
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = stringAppendList({DAE.derivativeNamePrefix,".",name_str});
        cr_1 = ComponentReference.makeCrefIdent(id_str,DAE.ET_REAL(),{});
      then
        SIMVAR(cr_1,varKind,comment,unit,displayUnit,1,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
    
    case(SIMVAR(name,varKind,comment,unit,displayUnit,2,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)) 
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = stringAppendList({DAE.derivativeNamePrefix,".",name_str});
        cr_1 = ComponentReference.makeCrefIdent(id_str,DAE.ET_REAL(),{});
      then
        SIMVAR(cr_1,varKind,comment,unit,displayUnit,2,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
  end matchcontinue;
end generateDerStates2;


protected function replaceindex 

  input SimVar var;
  input list<SimVar> statevarlist;
  output SimVar newvar;
algorithm
  newvar := matchcontinue(var,statevarlist)
    local
      list<SimVar> rest,rest1;
      DAE.ComponentRef name,name1;
      BackendDAE.VarKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Integer index,index1;
      Option<DAE.Exp> initialValue;
      Option<DAE.Exp> nominalValue;
      Boolean isFixed;
      DAE.ExpType type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      AliasVariable aliasvar;
      DAE.ElementSource source;
      Causality causality;
      Option <Integer> variable_index;
      Integer variable_index1;
      SimVar v,newvar1;
      list <String> numArrayElement;
  
  case((v as SIMVAR(name,varKind,comment,unit,displayUnit,index,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)),SIMVAR(name1,_,_,_,_,index1,_,_,_,_,_,_,_,_,_,SOME(variable_index1),_)::_)    
    equation
      Debug.fcall("cppvarindex",BackendDump.debugStrCrefStrCrefStr,(" compare variable ",name,"with ",name1,"\n"));
      true = ComponentReference.crefEqual(name,name1);
    then 
      SIMVAR(name,varKind,comment,unit,displayUnit,variable_index1,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,SOME(index1),numArrayElement);
  case((v as SIMVAR(name,varKind,comment,unit,displayUnit,index,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)),_::rest1)
    equation
       newvar1=replaceindex(v,rest1);
    then newvar1;
   else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Vector index for der variable was not found"});
      then
        fail();
    
end matchcontinue;
end replaceindex;

protected function replaceindex1 

 input list<SimVar> Vars;
 input list<SimVar> stateVars;
 output list<SimVar> newVars;
algorithm (newVars):= matchcontinue(Vars,stateVars)
  local 
     list<SimVar> new_list;
     SimVar new_simvar;
     SimVar v;
     list<SimVar> rest;
  case({},stateVars)
     then 
       {};
  case((v as SIMVAR(name=_))::rest,stateVars)
     equation
      new_list= replaceindex1(rest,stateVars);
      new_simvar =replaceindex(v,stateVars);
    
     then
      (new_simvar::new_list);
end matchcontinue;

end replaceindex1;


protected function varName
  input SimVar var;
  output DAE.ComponentRef name;
algorithm
  SIMVAR(name=name) := var;
end varName;

protected function arraydim
  "Returns a string representation of a subscript."
  input Expression.Subscript subscript;
  output String str;
algorithm
  str := match(subscript)
    local
      Integer i;
      String res;
      Absyn.Path enum_lit;
    case (DAE.INDEX(exp = DAE.ICONST(integer = i)))
      equation
        res = intString(i);
        Debug.fcall("cppsim1",print, "arraydim1: " +& res  +& "\n" );
      then
        res;
    case (DAE.INDEX(exp = DAE.ENUM_LITERAL(name = enum_lit)))
      equation
        res = Absyn.pathString(enum_lit);
        Debug.fcall("cppsim1",print, "arraydim2: " +& res  +& "\n" );
      then
        res;
  end match;
end arraydim;

public function countDynamicExternalFunctions
  input list<Function> inFncLst;
  output Integer outDynLoadFuncs;
algorithm
  outDynLoadFuncs:= matchcontinue(inFncLst)
  local 
     list<Function> rest;
     Function fn;
     Integer i;
  case({})
     then 
       0;
  case(EXTERNAL_FUNCTION(dynamicLoad=true)::rest)
     equation
      i = countDynamicExternalFunctions(rest);
    then 
      intAdd(i,1);
  case(fn::rest)
    equation
      i = countDynamicExternalFunctions(rest);
    then 
      i;
end matchcontinue;
end countDynamicExternalFunctions;

protected function getFilesFromSimVar
  input SimVar inSimVar;
  input Files inFiles;
  output SimVar outSimVar;
  output Files outFiles;
algorithm
  (outSimVar,outFiles) := match(inSimVar, inFiles)
    local
      Files files;
      DAE.ElementSource source;
      
    case (SIMVAR(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimVar,files);               
  end match;
end getFilesFromSimVar;

protected function arraydim1 ""
  input list<Expression.Subscript> subscript1;
  output list<String> outString;
algorithm outString := matchcontinue(subscript1)
  local
     Expression.Subscript subscript;
    String s1;
    list<String> s2;
    list<Expression.Subscript> rest;
  case({}) then {};
  case( subscript::rest )
    equation
      s1=  arraydim(subscript);
      s2= arraydim1(rest);
    then
       (s1 :: s2);
end matchcontinue;
end arraydim1;

protected function getFilesFromSimVars
  input SimVars inSimVars;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inSimVars, inFiles)
    local
      Files files;
      list<SimVar> stateVars,derivativeVars,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,intAliasVars,
                   boolAliasVars,paramVars,intParamVars,boolParamVars,stringAlgVars,stringParamVars,stringAliasVars,
                   extObjVars,jacobianVars,constVars,intConstVars,boolConstVars,stringConstVars;      
      
    case (SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars, 
                  paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, jacobianVars, constVars,intConstVars,boolConstVars,stringConstVars),
          files)
      equation
        (_, files) = Util.listListMapAndFold(
                       {stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars, 
                        paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, jacobianVars, constVars,intConstVars,boolConstVars,stringConstVars}, 
                       getFilesFromSimVar, files);
      then 
        files;               
  end match;
end getFilesFromSimVars;

protected function getFilesFromFunctions
  input list<Function> functions;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(functions, inFiles)
    local
      Files files;
      list<Function> rest;
      Absyn.Info info;

    // handle empty
    case ({}, files) then files;
    
    // handle FUNCTION
    case (FUNCTION(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);        
      then
        files;

    // handle EXTERNAL_FUNCTION
    case (EXTERNAL_FUNCTION(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);        
      then
        files;
    
    // handle RECORD_CONSTRUCTOR
    case (RECORD_CONSTRUCTOR(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);
      then
        files;
  end match;
end getFilesFromFunctions;

protected function getFilesFromSimEqSystemOpt
  input Option<SimEqSystem> inSimEqSystemOpt;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inSimEqSystemOpt, inFiles)
    local
      Files files;
      SimEqSystem sys;
      
    case (NONE(), files) then files;
    case (SOME(sys), files)
      equation
        (_, files) = getFilesFromSimEqSystem(sys, files);
      then 
        files;
  end match;
end getFilesFromSimEqSystemOpt;

protected function getFilesFromSimEqSystem
  input SimEqSystem inSimEqSystem;
  input Files inFiles;
  output SimEqSystem outSimEqSystem;
  output Files outFiles;  
algorithm
  (outSimEqSystem,outFiles) := match(inSimEqSystem, inFiles)
    local
      Files files;
      DAE.ElementSource source;
      list<DAE.Statement> statements;
      list<SimVar> vars;
      list<tuple<Integer, Integer, SimEqSystem>> simJac;
      list<SimEqSystem> systems;
      SimEqSystem system;
      Option<SimEqSystem> systemOpt;
      
    case (SES_RESIDUAL(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimEqSystem,files);
    
    case (SES_SIMPLE_ASSIGN(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimEqSystem,files);
    
    case (SES_ARRAY_CALL_ASSIGN(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimEqSystem,files);
        
    case (SES_ALGORITHM(statements), files)
      equation
        files = getFilesFromStatements(statements, files);
      then 
        (inSimEqSystem,files);
    
    case (SES_LINEAR(vars = vars, simJac = simJac), files)
      equation
        (_, files) = Util.listMapAndFold(vars, getFilesFromSimVar, files);
        systems = Util.listMap(simJac, Util.tuple33);
        files = getFilesFromSimEqSystems({systems}, files);
      then 
        (inSimEqSystem,files);
    
    case (SES_NONLINEAR(eqs = systems), files)
      equation
        files = getFilesFromSimEqSystems({systems}, files);
      then 
        (inSimEqSystem,files);
    
    case (SES_MIXED(cont = system, discVars = vars, discEqs = systems), files)
      equation
        (_, files) = Util.listMapAndFold(vars, getFilesFromSimVar, files);
        files = getFilesFromSimEqSystems({system::systems}, files);
      then 
        (inSimEqSystem,files);
        
    case (SES_WHEN(source = source, elseWhen = systemOpt), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromSimEqSystemOpt(systemOpt, files);
      then 
        (inSimEqSystem,files);
        
  end match;
end getFilesFromSimEqSystem;

protected function getFilesFromSimEqSystems
  input list<list<SimEqSystem>> inSimEqSystems;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inSimEqSystems, inFiles)
    local
      Files files;
      
    case (inSimEqSystems, files)
      equation
        (_, files) = Util.listListMapAndFold(inSimEqSystems, getFilesFromSimEqSystem, files);
      then 
        files;               
  end match;
end getFilesFromSimEqSystems;

protected function getFilesFromStatementsElse
  input DAE.Else inElse;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inElse, inFiles)
    local
      Files files;
      list<DAE.Statement> rest,stmts;
      DAE.Else elsePart;
      
    case (DAE.NOELSE(), files) then files;
      
    case (DAE.ELSEIF(statementLst = stmts, else_ = elsePart), files)
      equation
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatementsElse(elsePart, files);
      then
        files;
    
    case (DAE.ELSE(statementLst = stmts), files)
      equation
        files = getFilesFromStatements(stmts, files);
      then
        files;
  end match;
end getFilesFromStatementsElse;

protected function getFilesFromStatementsElseWhen
  input Option<DAE.Statement> inStatementOpt;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inStatementOpt, inFiles)
    local
      Files files;
      DAE.Statement stmt;
      
    case (NONE(), files) then files;
    case (SOME(stmt), files) then getFilesFromStatements({stmt}, files);
  end match;
end getFilesFromStatementsElseWhen;

protected function getFilesFromStatements
  input list<DAE.Statement> inStatements;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inStatements, inFiles)
    local
      Files files;
      DAE.ElementSource source;
      list<DAE.Statement> rest,stmts;
      DAE.Else elsePart;
      Option<DAE.Statement> elseWhen;      
      
    // handle empty
    case ({}, files) then files;
      
    case (DAE.STMT_ASSIGN(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
    
    case (DAE.STMT_TUPLE_ASSIGN(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
    
    case (DAE.STMT_ASSIGN_ARR(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
    
    case (DAE.STMT_IF(source = source, statementLst = stmts, else_ = elsePart)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatementsElse(elsePart, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_FOR(source = source, statementLst = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_WHILE(source = source, statementLst = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_WHEN(source = source, statementLst = stmts, elseWhen = elseWhen)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatementsElseWhen(elseWhen, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_ASSERT(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_TERMINATE(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_REINIT(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_NORETCALL(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_RETURN(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_BREAK(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_FAILURE(source = source, body = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
    
    case (DAE.STMT_TRY(source = source, tryBody = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_CATCH(source = source, catchBody = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
        
    case (DAE.STMT_THROW(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then 
        files;
  end match;
end getFilesFromStatements;

protected function getFilesFromWhenClausesReinits
  input list<BackendDAE.WhenOperator> inWhenOperators;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inWhenOperators, inFiles)
    local
      Files files;
      DAE.ElementSource source;
      list<BackendDAE.WhenOperator> rest; 
      
    // handle empty
    case ({}, files) then files;
      
    case (BackendDAE.REINIT(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromWhenClausesReinits(rest, files);
      then 
        files;
    
  end match;
end getFilesFromWhenClausesReinits;

protected function getFilesFromWhenClauses
  input list<SimWhenClause> inSimWhenClauses;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inSimWhenClauses, inFiles)
    local
      Files files;
      list<SimWhenClause> rest;
      list<BackendDAE.WhenOperator> reinits; 
      
    // handle empty
    case ({}, files) then files;
      
    case (SIM_WHEN_CLAUSE(reinits = reinits)::rest, files)
      equation
        files = getFilesFromWhenClausesReinits(reinits, files);
        files = getFilesFromWhenClauses(rest, files);
      then 
        files;
    
  end match;
end getFilesFromWhenClauses;

protected function getFilesFromExtObjInfo
  input ExtObjInfo inExtObjInfo;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inExtObjInfo, inFiles)
    local
      Files files;
      list<SimVar> vars;
      
    case (EXTOBJINFO(vars = vars), files)
      equation
        (_, files) = Util.listMapAndFold(vars, getFilesFromSimVar, files);
      then 
        files;
    
  end match;
end getFilesFromExtObjInfo;

protected function getFilesFromJacobianMatrixes
  input list<JacobianMatrix> inJacobianMatrixes;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inJacobianMatrixes, inFiles)
    local
      Files files;
      list<JacobianMatrix> rest;
      list<JacobianColumn> onemat;
      list<SimEqSystem> systems;
      list<SimVar> vars;
   
    // handle empty   
    case ({}, files) then files;
    
    // handle rest  
    case ((onemat,_,_)::rest, files)
      equation
        files = getFilesFromJacobianMatrix(onemat, files);
        files = getFilesFromJacobianMatrixes(rest, files);
      then 
        files;

  end match;
end getFilesFromJacobianMatrixes;

protected function getFilesFromJacobianMatrix
  input list<JacobianColumn> inJacobianMatrixes;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inJacobianMatrixes, inFiles)
    local
      Files files;
      list<JacobianColumn> rest;
      list<SimEqSystem> systems;
      list<SimVar> vars;
   
    // handle empty   
    case ({}, files) then files;
    
    // handle rest  
    case ((systems, vars, _)::rest, files)
      equation
        files = getFilesFromSimEqSystems({systems}, files);
        (_, files) = Util.listMapAndFold(vars, getFilesFromSimVar, files);
        files = getFilesFromJacobianMatrix(rest, files);
      then 
        files;

  end match;
end getFilesFromJacobianMatrix;

protected function collectAllFiles
  input SimCode inSimCode;
  output SimCode outSimCode;
algorithm
  outSimCode := matchcontinue(inSimCode)
    local
      ModelInfo modelInfo;
      list<DAE.Exp> literals "shared literals";
      list<RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimEqSystem> allEquations,odeEquations,algebraicEquations,residualEquations,initialEquations,parameterEquations,removedEquations,sampleEquations;
      list<DAE.Statement> algorithmAndEquationAsserts;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<SampleCondition> sampleConditions;
      list<HelpVarInfo> helpVarInfo;
      list<SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      ExtObjInfo extObjInfo;
      MakefileParams makefileParams;
      DelayedExpression delayedExps;
      list<JacobianMatrix> jacobianMatrixes;
      Option<SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      HashTableCrefToSimVar crefToSimVarHT;
      Absyn.Path name;
      String directory;
      VarInfo varInfo;
      SimVars vars;
      list<Function> functions;
      Files files "all the files from Absyn.Info and DAE.ELementSource";      

    case inSimCode
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
      then
        inSimCode;
    
    case SIMCODE(modelInfo,literals,recordDecls,externalFunctionIncludes,allEquations,odeEquations,algebraicEquations,residualEquations,initialEquations, 
                 parameterEquations,removedEquations,algorithmAndEquationAsserts,zeroCrossings,sampleConditions,sampleEquations,helpVarInfo,whenClauses,
                 discreteModelVars,extObjInfo,makefileParams,delayedExps,jacobianMatrixes,simulationSettingsOpt,fileNamePrefix,crefToSimVarHT)
      equation
        MODELINFO(name, directory, varInfo, vars, functions) = modelInfo;
        files = {};
        files = getFilesFromSimVars(vars, files);
        files = getFilesFromFunctions(functions, files);
        files = getFilesFromSimEqSystems({allEquations,odeEquations,algebraicEquations,residualEquations,
                                          initialEquations,parameterEquations,removedEquations,sampleEquations}, files);
        files = getFilesFromStatements(algorithmAndEquationAsserts, files);
        files = getFilesFromWhenClauses(whenClauses, files);   
        files = getFilesFromExtObjInfo(extObjInfo, files);
        files = getFilesFromJacobianMatrixes(jacobianMatrixes, files);
        files = Util.sort(files, greaterFileInfo);
        modelInfo = MODELINFO(name, directory, varInfo, vars, functions);
      then
        SIMCODE(modelInfo,literals,recordDecls,externalFunctionIncludes,allEquations,odeEquations,algebraicEquations,residualEquations,initialEquations, 
                  parameterEquations,removedEquations,algorithmAndEquationAsserts,zeroCrossings,sampleConditions,sampleEquations,helpVarInfo,whenClauses,
                  discreteModelVars,extObjInfo,makefileParams,delayedExps,jacobianMatrixes,simulationSettingsOpt,fileNamePrefix,crefToSimVarHT);
                  
    case inSimCode
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.collectAllFiles failed to collect files from SimCode!"});        
      then
        inSimCode;
  end matchcontinue;
end collectAllFiles;

protected function getFilesFromDAEElementSource
  input DAE.ElementSource inSource;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inSource, inFiles)
    local
      Files files;
      Absyn.Info info;
      
    case (DAE.SOURCE(info = info), files) 
      equation
        files = getFilesFromAbsynInfo(info, files);
      then 
        files;
  end match;
end getFilesFromDAEElementSource;

protected function getFilesFromAbsynInfo
  input Absyn.Info inInfo;
  input Files inFiles;
  output Files outFiles;
algorithm
  outFiles := match(inInfo, inFiles)
    local
      Files files;
      String f;
      Boolean ro;
      FileInfo fi;
      
    case (Absyn.INFO(fileName = f, isReadOnly = ro), files) 
      equation
        fi = FILEINFO(f, ro);
        // add it only if is not already there!
        files = Util.listConsOnTrue(not listMember(fi, files), fi, files);
      then 
        files;
  end match;
end getFilesFromAbsynInfo;

protected function equalFileInfo
"compare to FileInfo and return true if the filenames are equal, isReadOnly is ignored here"
  input FileInfo inFileInfo1;
  input FileInfo inFileInfo2;
  output Boolean isMatch;
protected
  String f1, f2;
algorithm
  FILEINFO(f1, _) := inFileInfo1;
  FILEINFO(f2, _) := inFileInfo2;
  isMatch := stringEq(f1, f2);
end equalFileInfo;

protected function greaterFileInfo
"compare to FileInfo and returns true if the fileName1 is greater than fileName2, isReadOnly is ignored here"
  input FileInfo inFileInfo1;
  input FileInfo inFileInfo2;
  output Boolean isGreater;
protected
  String f1, f2;
  Integer compare;
algorithm
  FILEINFO(f1, _) := inFileInfo1;
  FILEINFO(f2, _) := inFileInfo2;
  compare := stringCompare(f1, f2);
  isGreater := intGt(compare, 0);
end greaterFileInfo;

protected function getFileIndexFromFiles
"fetch the index in the list of files"
  input String file;
  input Files files;
  output Integer index;
algorithm
  index := matchcontinue(file, files)
    local
      Integer i;
      
    case (file, files)
      equation
        i = Util.listFindWithCompareFunc(files, FILEINFO(file, false), equalFileInfo, false);
      then
        i; 
  end matchcontinue;
end getFileIndexFromFiles;

public function fileName2fileIndex
"Used by templates to find a fileIndex for given fileName"
  input String inFileName;
  input Files inFiles;
  output Integer outFileIndex;
algorithm
  outFileIndex := matchcontinue(inFileName, inFiles)
    local
      String errstr;
      String file;
      Files files;
      Integer index;
      
    case (file, files)
      equation
        index = getFileIndexFromFiles(file, files);
      then 
        index;
        
    case (file, _)
      equation
        //errstr = "Template did not find the file: "+& file +& " in the SimCode.modelInfo.files.";
        //Error.addMessage(Error.INTERNAL_ERROR, {errstr});
      then
        -1;
  end matchcontinue;
end fileName2fileIndex;

end SimCode;
