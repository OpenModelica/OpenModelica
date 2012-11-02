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

encapsulated package SimCodeUtil
" file:        SimCodeUtil.mo
  package:     SimCodeUtil
  description: Code generation using Susan templates

  RCS: $Id: SimCode.mo 12794 2012-09-05 16:52:31Z perost $

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
public import Env;
public import HashTableExpToIndex;
public import HashTableStringToPath;
public import HashTableCrSimVars;
public import Inline;
public import Interactive;
public import SCode;
public import Tpl;
public import Types;
public import Values;
public import SimCode;

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
protected import BaseHashSet;
protected import Builtin;
protected import CevalScript;
protected import CheckModel;
protected import ClassInf;
protected import CodegenC;
protected import CodegenFMU;
protected import CodegenQSS;
protected import CodegenAdevs;
protected import CodegenCSharp;
protected import CodegenCpp;
protected import CodegenXML;
protected import CodegenJava;
protected import ComponentReference;
protected import Config;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import ExpressionSolve;
protected import Flags;
protected import HashSet;
protected import List;
protected import Mod;
protected import PartFn;
protected import PriorityQueue;
protected import Settings;
protected import SimCodeDump;
protected import System;
protected import Util;
protected import ValuesUtil;
//protected import ReduceDAE;



public function elementVars
"Used by templates to get a list of variables from a valueblock."
  input list<DAE.Element> ild;
  output list<SimCode.Variable> vars;
protected
  list<DAE.Element> ld;
algorithm
  ld := List.filter(ild, isVarQ);
  vars := List.map(ld, daeInOutSimVar);
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
  input SimCode.Context context;
  output Boolean isScalar;
algorithm
  isScalar := matchcontinue(cref, context)
    local
      Boolean res;
    case (_, SimCode.FUNCTION_CONTEXT())
      equation
        res = crefNoSub(cref);
      then
        res;
    case (_, SimCode.PARALLEL_FUNCTION_CONTEXT())
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
      DAE.Type ty;
      DAE.ComponentRef crNew;
      list<DAE.Subscript> indexes;
      
    case (_, {}) then cref;
    case (DAE.CREF(componentRef=crNew, ty=ty), _)
      equation
        indexes = List.map(subs, Expression.makeIndexSubscript);
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
  input DAE.Var inVar;
  output DAE.Exp outExp;
algorithm
  outExp := match (inCRefRecord,inVar)
    local
      DAE.ComponentRef cr,cr1;
      String name;
      DAE.Type tp;
    case (cr,DAE.TYPES_VAR(name=name,ty=tp))
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
  input SimCode.SimCode simCode;
  output SimCode.SimVar outSimVar;
algorithm
  outSimVar := matchcontinue(inCref, simCode)
    local
      DAE.ComponentRef cref, badcref;
      SimCode.SimVar sv;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      
    case (cref, SimCode.SIMCODE(crefToSimVarHT = crefToSimVarHT) )
      equation
        sv = get(cref, crefToSimVarHT);
      then sv;
        
    case (cref, _)
      equation
        badcref = ComponentReference.makeCrefIdent("ERROR_cref2simvar_failed", DAE.T_REAL_DEFAULT, {});
        //errstr = "Template did not find the simulation variable for "+& ComponentReference.printComponentRefStr(cref) +& ". ";
        //Error.addMessage(Error.INTERNAL_ERROR, {errstr});
      then
        SimCode.SIMVAR(badcref, BackendDAE.STATE(), "", "", "", -1, NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT, false, NONE(), SimCode.NOALIAS(), DAE.emptyElementSource, SimCode.INTERNAL(),NONE(),{});
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
  input SimCode.Context context;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp, context)
    local
      list<DAE.Exp> aRest;
      DAE.ComponentRef cr;
      DAE.Type aty;
      DAE.Exp crefExp;
      
    case(DAE.ARRAY(ty=aty, scalar=true, array =(DAE.CREF(componentRef=cr) ::aRest)),_)
      equation
        failure(SimCode.FUNCTION_CONTEXT()=context); //only in the function context
        failure(SimCode.PARALLEL_FUNCTION_CONTEXT()=context); //only in the function context
        { DAE.INDEX(DAE.ICONST(1)) } = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = isArrayExpansion(aRest, cr, 2);
        crefExp = Expression.makeCrefExp(cr, aty);
      then 
        crefExp;
        
    case (_, _) then inExp;
        
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
    case (DAE.CREF(componentRef=cr) :: aRest, _, _) 
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
  input SimCode.Context context;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp, context)
    local
      DAE.ComponentRef cr;
      DAE.Type aty;
      list<list<DAE.Exp>> rows;
      DAE.Exp crefExp;
      
    case(DAE.MATRIX(ty=aty, matrix = rows as (((DAE.CREF(componentRef=cr))::_)::_) ),_)
      equation
        failure(SimCode.FUNCTION_CONTEXT()=context);
        failure(SimCode.PARALLEL_FUNCTION_CONTEXT()=context); //only in the function context
        { DAE.INDEX(DAE.ICONST(1)), DAE.INDEX(DAE.ICONST(1)) } = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = isMatrixExpansion(rows, cr, 1, 1);
        crefExp = Expression.makeCrefExp(cr, aty);
      then 
        crefExp;
        
    case (_, _) then inExp;
        
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
    
    case _
      equation
        lib = List.last(libs);
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
    case({} :: restRows,_,_,_) then isMatrixExpansion(restRows, inCref, rowIndex+1, 1);
    case ( (DAE.CREF(componentRef=cr) :: restElems) :: restRows, _, _, _) 
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
  match (inExp)
    case(_)
      equation
        // Simplify things like abs(exp) >= 0 to exp
        (outExp,_) = ExpressionSimplify.simplify(DAE.RELATION(inExp,DAE.GREATEREQ(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE()));
      then outExp;
  end match;
end createAssertforSqrt;

public function createDAEString
   input String inString;
   output DAE.Exp outExp;
   annotation(__OpenModelica_EarlyInline = true);
algorithm
  outExp := DAE.SCONST(inString);
end createDAEString;

public function appendAllequations
  input list<SimCode.JacobianMatrix> inJacobianMatrix;
  output list<SimCode.SimEqSystem> outEqn;
algorithm 
  outEqn := 
  match(inJacobianMatrix)
      local
        list<SimCode.JacobianColumn> column;
        list<SimCode.SimEqSystem> tmp,tmp1;
        list<SimCode.JacobianMatrix> rest;
    case ((column,_,_,_,_,_)::rest)
      equation
        tmp = appendAllequation(column);
        tmp1 = appendAllequations(rest);
        tmp1 = listAppend(tmp,tmp1);
      then tmp1;
   case({}) then {};
end match;
end appendAllequations;

protected function appendAllequation
  input list<SimCode.JacobianColumn> inJacobianColumn;
  output list<SimCode.SimEqSystem> outEqn;
algorithm 
  outEqn := 
  match(inJacobianColumn)
      local
        list<SimCode.SimEqSystem> tmp,tmp1;
        list<SimCode.JacobianColumn> rest;
    case (((tmp,_,_)::rest))
      equation
        tmp1 = appendAllequation(rest);
        tmp1 = listAppend(tmp,tmp1);
      then tmp1;
   case({}) then {};
end match;
end appendAllequation;

public function appendLists
  input list<SimCode.SimEqSystem> inEqn1;
  input list<SimCode.SimEqSystem> inEqn2;
  output list<SimCode.SimEqSystem> outEqn;
algorithm 
  outEqn := listAppend(inEqn1,inEqn2);
end appendLists;


/** end of TypeView published functions **/


public function createSimulationSettings
  input Real startTime;
  input Real stopTime;
  input Integer inumberOfIntervals;
  input Real tolerance;
  input String method;
  input String options;
  input String outputFormat;
  input String variableFilter;
  input Boolean measureTime;
  input String cflags;
  output SimCode.SimulationSettings simSettings;
protected
  Real stepSize;
  Integer numberOfIntervals;
algorithm
  numberOfIntervals := Util.if_(inumberOfIntervals <= 0, 1, inumberOfIntervals);
  stepSize := (stopTime -. startTime) /. intReal(numberOfIntervals);
  simSettings := SimCode.SIMULATION_SETTINGS(
    startTime, stopTime, numberOfIntervals, stepSize, tolerance,
    method, options, outputFormat, variableFilter, measureTime, cflags);
end createSimulationSettings;


public function generateModelCodeFMU
  "Generates code for a model by creating a SimCode structure and calling the
   template-based code generator on it."
  input BackendDAE.BackendDAE inBackendDAE;
  input Absyn.Program p;
  input DAE.DAElist dae;
  input Absyn.Path className;
  input String filenamePrefix;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  output BackendDAE.BackendDAE outIndexedBackendDAE;
  output list<String> libs;
  output String fileDir;
  output Real timeBackend;
  output Real timeSimCode;
  output Real timeTemplates;
protected 
  list<String> includes,includeDirs;
  list<SimCode.Function> functions;
  // DAE.DAElist dae2;
  String filename, funcfilename;
  SimCode.SimCode simCode;
  list<SimCode.RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  Absyn.ComponentRef a_cref;
  tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
algorithm
  timeBackend := System.realtimeTock(CevalScript.RT_CLOCK_BACKEND);
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScript.getFileDir(a_cref, p);
  System.realtimeTick(CevalScript.RT_CLOCK_SIMCODE);
  (libs, includes, includeDirs, recordDecls, functions, outIndexedBackendDAE, _, literals) :=
  createFunctions(dae, inBackendDAE, className);
  simCode := createSimCode(outIndexedBackendDAE,
    className, filenamePrefix, fileDir, functions, includes, includeDirs, libs, simSettingsOpt, recordDecls, literals,Absyn.FUNCTIONARGS({},{}));
  timeSimCode := System.realtimeTock(CevalScript.RT_CLOCK_SIMCODE);
  Debug.execStat("SimCode",CevalScript.RT_CLOCK_SIMCODE);
  
  System.realtimeTick(CevalScript.RT_CLOCK_TEMPLATES);
  callTargetTemplatesFMU(simCode, Config.simCodeTarget());
  timeTemplates := System.realtimeTock(CevalScript.RT_CLOCK_TEMPLATES);
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
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
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
      DAE.DAElist dae;
      list<Env.Frame> env;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow_1;
      list<String> libs;
      Interactive.SymbolTable st;
      Absyn.Program p;
      //DAE.Exp fileprefix;
      Env.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
    case (cache,env,_,st as Interactive.SYMBOLTABLE(ast=p),filenameprefix,_, _)
      equation
        /* calculate stuff that we need to create SimCode data structure */
        System.realtimeTick(CevalScript.RT_CLOCK_FRONTEND);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st),NONE(), msg);
        (cache,env,dae,st) = CevalScript.runFrontEnd(cache,env,className,st,false);
        timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_FRONTEND);
        System.realtimeTick(CevalScript.RT_CLOCK_BACKEND);
        funcs = Env.getFunctionTree(cache);
        dae = DAEUtil.transformationsBeforeBackend(cache,env,dae);
        dlow = BackendDAECreate.lower(dae,cache,env);
        dlow_1 = BackendDAEUtil.getSolvedSystem(dlow,NONE(), NONE(), NONE(), NONE());
        Debug.fprintln(Flags.DYN_LOAD, "translateModel: Generating simulation code and functions.");
        (indexed_dlow_1,libs,file_dir,timeBackend,timeSimCode,timeTemplates) = 
          generateModelCodeFMU(dlow_1, p, dae,  className, filenameprefix, inSimSettingsOpt);
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
    case (_,_,_,_,_,_, _)
      equation        
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," could not be translated to FMU"});
        Error.addMessage(Error.INTERNAL_ERROR, {resstr});
      then
        fail();
  end matchcontinue;
end translateModelFMU;


public function generateModelCode
  "Generates code for a model by creating a SimCode structure and calling the
   template-based code generator on it."
   
  input BackendDAE.BackendDAE inBackendDAE;
  input Absyn.Program p;
  input DAE.DAElist dae;
  input Absyn.Path className;
  input String filenamePrefix;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input Absyn.FunctionArgs args;
  output BackendDAE.BackendDAE outIndexedBackendDAE;
  output list<String> libs;
  output String fileDir;
  output Real timeBackend;
  output Real timeSimCode;
  output Real timeTemplates;
protected 
  
  list<String> includes,includeDirs;
  list<SimCode.Function> functions;
  // DAE.DAElist dae2;
  String filename, funcfilename;
  SimCode.SimCode simCode;
  list<SimCode.RecordDeclaration> recordDecls;
  BackendDAE.BackendDAE indexed_dlow,indexed_dlow_1;
  Absyn.ComponentRef a_cref;
  BackendQSS.QSSinfo qssInfo;
  tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
  list<SimCode.JacobianMatrix> LinearMatrices;
algorithm
  timeBackend := System.realtimeTock(CevalScript.RT_CLOCK_BACKEND);
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScript.getFileDir(a_cref, p);
  System.realtimeTick(CevalScript.RT_CLOCK_SIMCODE);
  (libs, includes, includeDirs, recordDecls, functions, outIndexedBackendDAE, _, literals) :=
  createFunctions(dae, inBackendDAE, className);
  simCode := createSimCode(outIndexedBackendDAE, 
    className, filenamePrefix, fileDir, functions, includes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args);

  timeSimCode := System.realtimeTock(CevalScript.RT_CLOCK_SIMCODE);
  Debug.execStat("SimCode",CevalScript.RT_CLOCK_SIMCODE);
  
  System.realtimeTick(CevalScript.RT_CLOCK_TEMPLATES);
  callTargetTemplates(simCode,inBackendDAE,Config.simCodeTarget());
  timeTemplates := System.realtimeTock(CevalScript.RT_CLOCK_TEMPLATES);
end generateModelCode;

// TODO: use another switch ... later make it first class option like -target or so
// Update: inQSSrequiredData passed in order to call BackendQSS and generate the extra structures needed for QSS simulation.
protected function callTargetTemplates
"Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
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
      String str;
      SimCode.SimCode sc;
      
    case (_,_,"CSharp")
      equation
        Tpl.tplNoret(CodegenCSharp.translateModel, simCode);
      then ();
   case (_,_,"Cpp")
      equation
        Tpl.tplNoret(CodegenCpp.translateModel, simCode);
      then ();
   case (_,_,"Adevs")
      equation
        Tpl.tplNoret(CodegenAdevs.translateModel, simCode);
      then ();
    case (_,outIndexedBackendDAE as BackendDAE.DAE(eqs={
        BackendDAE.EQSYSTEM(m=SOME(incidenceMatrix), mT=SOME(incidenceMatrixT), matching=BackendDAE.MATCHING(equationIndices, variableIndices,strongComponents))
      }),"QSS")
      equation
        Debug.trace("Generating code for QSS solver\n");
        (qssInfo,sc) = BackendQSS.generateStructureCodeQSS(outIndexedBackendDAE, equationIndices, variableIndices, incidenceMatrix, incidenceMatrixT, strongComponents,simCode);
        Tpl.tplNoret2(CodegenQSS.translateModel, sc,qssInfo);
      then ();
    case (_,_,"C")
      equation
        Tpl.tplNoret(CodegenC.translateModel, simCode);
      then ();        
    case (_,_,"Dump")
      equation
        // Yes, do this better later on...
        print(Tpl.tplString(SimCodeDump.dumpSimCode, simCode));
      then ();
    case (_,_,"XML")
      equation
        Tpl.tplNoret(CodegenXML.translateModel, simCode);
      then ();
    case (_,_,"Java")
      equation
        Tpl.tplNoret(CodegenJava.translateModel, simCode);
      then ();
    case (_,_,_)
      equation
        str = "Unknown template target: " +& target;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end callTargetTemplates;

protected function callTargetTemplatesFMU
"Generate target code by passing the SimCode data structure to templates."
  input SimCode.SimCode simCode;
  input String target;
algorithm
  _ := match (simCode,target)
    local
      String str;
      
    case (_,"C")
      equation
        Tpl.tplNoret(CodegenFMU.translateModel, simCode);
      then ();        
    case (_,"Dump")
      equation
        // Yes, do this better later on...
        print(Tpl.tplString(SimCodeDump.dumpSimCode, simCode));
      then ();
    case (_,_)
      equation
        str = "Unknown template target: " +& target;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end callTargetTemplatesFMU;

public function translateModel
"Entry point to translate a Modelica model for simulation.
    
 Called from other places in the compiler."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.SymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimCode.SimulationSettings> inSimSettingsOpt;
  input Absyn.FunctionArgs args "labels for remove terms";
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.SymbolTable outInteractiveSymbolTable;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outBackendDAE,outStringLst,outFileDir,resultValues):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy, inSimSettingsOpt, args)
    local
      String filenameprefix,file_dir,resstr;
      DAE.DAElist dae;
      list<Env.Frame> env;
      BackendDAE.BackendDAE dlow,dlow_1,indexed_dlow_1;
      list<String> libs;
      Interactive.SymbolTable st;
      Absyn.Program p;
      //DAE.Exp fileprefix;
      Env.Cache cache;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;

    case (cache,env,_,(st as Interactive.SYMBOLTABLE(ast = p)),filenameprefix,_, _,_)
      equation
        // calculate stuff that we need to create SimCode data structure 
        System.realtimeTick(CevalScript.RT_CLOCK_FRONTEND);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st),NONE(), msg);
        (cache,env,dae,st) = CevalScript.runFrontEnd(cache,env,className,st,false);
        timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_FRONTEND);
        System.realtimeTick(CevalScript.RT_CLOCK_BACKEND);
        dae = DAEUtil.transformationsBeforeBackend(cache,env,dae);
        dlow = BackendDAECreate.lower(dae,cache,env);
        dlow_1 = BackendDAEUtil.getSolvedSystem(dlow,NONE(), NONE(), NONE(), NONE());
        (indexed_dlow_1,libs,file_dir,timeBackend,timeSimCode,timeTemplates) = 
          generateModelCode(dlow_1, p, dae,  className, filenameprefix, inSimSettingsOpt, args);
        resultValues = 
        {("timeTemplates",Values.REAL(timeTemplates)),
          ("timeSimCode",  Values.REAL(timeSimCode)),
          ("timeBackend",  Values.REAL(timeBackend)),
          ("timeFrontend", Values.REAL(timeFrontend))
          };          
        resstr = Util.if_(Flags.isSet(Flags.FAILTRACE),Absyn.pathStringNoQual(className),"");
        resstr = stringAppendList({"SimCode: The model ",resstr," has been translated"});
        //        resstr = "SimCode: The model has been translated";
      then
        (cache,Values.STRING(resstr),st,indexed_dlow_1,libs,file_dir, resultValues);
    case (_,_,_,_,_,_,_,_)
      equation        
        true = Flags.isSet(Flags.FAILTRACE);
        resstr = Absyn.pathStringNoQual(className);
        resstr = stringAppendList({"SimCode: The model ",resstr," could not be translated"});
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
  input list<DAE.Function> idaeElements;
  input list<DAE.Type> metarecordTypes;
  input list<String> inIncludes;
algorithm
  _ := match (name, optMainFunction, idaeElements, metarecordTypes, inIncludes)
    local
      DAE.Function daeMainFunction;
      SimCode.Function mainFunction;
      list<SimCode.Function> fns;
      list<String> includes, libs, includeDirs;
      SimCode.MakefileParams makefileParams;
      SimCode.FunctionCode fnCode;
      list<SimCode.RecordDeclaration> extraRecordDecls;
      list<DAE.Exp> literals;
      list<DAE.Function> daeElements;
      
    case (_, SOME(daeMainFunction), daeElements, _, includes)
      equation
        // Create SimCode.FunctionCode
        (daeElements,literals) = findLiterals(daeMainFunction::daeElements);
        (mainFunction::fns, extraRecordDecls, includes, includeDirs, libs) = elaborateFunctions(daeElements, metarecordTypes, literals, includes);
        checkValidMainFunction(name, mainFunction);
        makefileParams = createMakefileParams(includeDirs, libs);
        fnCode = SimCode.FUNCTIONCODE(name, SOME(mainFunction), fns, literals, includes, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(CodegenC.translateFunctions, fnCode);
      then
        ();
    case (_, NONE(), daeElements, _, includes)
      equation
        // Create SimCode.FunctionCode
        (daeElements,literals) = findLiterals(daeElements);
        (fns, extraRecordDecls, includes, includeDirs, libs) = elaborateFunctions(daeElements, metarecordTypes, literals, includes);
        makefileParams = createMakefileParams(includeDirs, libs);
        fnCode = SimCode.FUNCTIONCODE(name, NONE(), fns, literals, includes, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(CodegenC.translateFunctions, fnCode);
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
  output tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
algorithm
  (ofns,literals) := DAEUtil.traverseDAEFunctions(
    fns, findLiteralsHelper,
    (0,HashTableExpToIndex.emptyHashTableSized(BaseHashTable.bigBucketSize),{}));
  // Broke things :(
  // ((i,ht,literals)) := BackendDAEUtil.traverseBackendDAEExpsNoCopyWithUpdate(dae, findLiteralsHelper, (i,ht,literals));
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
    case ((exp as DAE.MATRIX(matrix=_),_))
      equation
        isLiteralArrayExp(exp);
        ((exp,tpl)) = replaceLiteralExp2(inTpl);
      then ((exp,false,tpl));
    case ((exp as DAE.MATRIX(matrix=_),tpl))
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
      DAE.Type et;
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
    case DAE.LIST(es as _::_) then listToCons2(es);
  end match;
end listToCons;

protected function listToCons2
"Converts a DAE.LIST to a chain of DAE.CONS"
  input list<DAE.Exp> ies;
  output DAE.Exp o;
algorithm
  o := match ies
    local
      DAE.Exp car,cdr;
      list<DAE.Exp> es;
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
  input DAE.Exp iexp;
algorithm
  _ := match iexp
    local
      DAE.Exp e1,e2,exp;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> expll;
      
    case DAE.SCONST(_) then ();
    case DAE.ICONST(_) then ();
    case DAE.RCONST(_) then ();
    case DAE.BCONST(_) then ();
    case DAE.ARRAY(array=expl) equation List.map_0(expl,isLiteralArrayExp); then ();
    case DAE.MATRIX(matrix=expll) equation List.map_0(List.flatten(expll),isLiteralArrayExp); then ();
    case DAE.ENUM_LITERAL(index = _) then ();
    case DAE.META_OPTION(NONE()) then ();
    case DAE.META_OPTION(SOME(exp)) equation isLiteralArrayExp(exp); then ();
    case DAE.BOX(exp) equation isLiteralArrayExp(exp); then ();
    case DAE.CONS(car = e1, cdr = e2) equation isLiteralArrayExp(e1); isLiteralArrayExp(e2); then ();
    case DAE.LIST(valList = expl) equation List.map_0(expl,isLiteralArrayExp); then ();
    case DAE.META_TUPLE(expl) equation List.map_0(expl,isLiteralArrayExp); then ();
    case DAE.METARECORDCALL(args=expl) equation List.map_0(expl,isLiteralArrayExp); then ();
    case DAE.SHARED_LITERAL(index=_) then ();
    else fail();
  end match;
end isLiteralArrayExp;

protected function isLiteralExp
"Returns if the expression may be replaced by a constant literal"
  input DAE.Exp iexp;
algorithm
  _ := match iexp
    local
      DAE.Exp e1,e2,exp;
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
    case DAE.LIST(valList = expl) equation List.map_0(expl,isLiteralExp); then ();
    case DAE.META_TUPLE(expl) equation List.map_0(expl,isLiteralExp); then ();
    case DAE.METARECORDCALL(args=expl) equation List.map_0(expl,isLiteralExp); then ();
    case DAE.SHARED_LITERAL(index=_) then ();
    else fail();
  end match;
end isLiteralExp;

protected function checkValidMainFunction
"Verifies that an in-function can be generated.
This is not the case if the input involves function-pointers."
  input String name;
  input SimCode.Function fn;
algorithm
  _ := matchcontinue (name,fn)
    local
      list<SimCode.Variable> inVars;
    case (_,SimCode.FUNCTION(functionArguments = inVars))
      equation
        failure(_ = List.selectFirst(inVars, isFunctionPtr));
      then ();
    case (_,SimCode.EXTERNAL_FUNCTION(inVars = inVars))
      equation
        failure(_ = List.selectFirst(inVars, isFunctionPtr));
      then ();
    case (_,_)
      equation
        Error.addMessage(Error.GENERATECODE_INVARS_HAS_FUNCTION_PTR,{name});
      then fail();
  end matchcontinue;
end checkValidMainFunction;

public function isBoxedFunction
"Verifies that an in-function can be generated.
This is not the case if the input involves function-pointers."
  input SimCode.Function fn;
  output Boolean b;
algorithm
  b := matchcontinue fn
    local
      list<SimCode.Variable> inVars,outVars;
    case (SimCode.FUNCTION(functionArguments = inVars, outVars = outVars))
      equation
        List.map_0(inVars, isBoxedArg);
        List.map_0(outVars, isBoxedArg);
      then true;
    case (SimCode.EXTERNAL_FUNCTION(inVars = inVars, outVars = outVars))
      equation
        List.map_0(inVars, isBoxedArg);
        List.map_0(outVars, isBoxedArg);
      then true;
    else false;
  end matchcontinue;
end isBoxedFunction;

protected function isFunctionPtr
"Checks if an input variable is a function pointer"
  input SimCode.Variable var;
  output Boolean b;
algorithm
  b := matchcontinue var
    local
      /* Yes, they are VARIABLE, not SimCode.FUNCTION_PTR. */
    case SimCode.FUNCTION_PTR(tys = _)
    then true;
    case _ then false;
  end matchcontinue;
end isFunctionPtr;

protected function isBoxedArg
"Checks if a variable is a boxed datatype"
  input SimCode.Variable var;
algorithm
  _ := match var
    case SimCode.FUNCTION_PTR(tys = _) then ();
    case SimCode.VARIABLE(ty = DAE.T_METABOXED(source = _)) then ();
    case SimCode.VARIABLE(ty = DAE.T_METATYPE(source = _)) then ();
    case SimCode.VARIABLE(ty = DAE.T_STRING(source = _)) then ();
  end match;
end isBoxedArg;

/* Finds the called functions in BackendDAE and transforms them to a list of
 libraries and a list of SimCode.Function uniontypes. */
public function createFunctions
  input DAE.DAElist inDAElist;
  input BackendDAE.BackendDAE inBackendDAE;
  input Absyn.Path inPath;
  output list<String> libs;
  output list<String> includes;
  output list<String> includeDirs;
  output list<SimCode.RecordDeclaration> recordDecls;
  output list<SimCode.Function> functions;
  output BackendDAE.BackendDAE outBackendDAE;
  output DAE.DAElist outDAE;
  output tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
algorithm
  (libs, includes, includeDirs, recordDecls, functions, outBackendDAE, outDAE, literals) :=
  matchcontinue (inDAElist,inBackendDAE,inPath)
    local
      list<String> libs2,includes2,includeDirs2;
      list<DAE.Function> funcelems,part_func_elems;
      DAE.DAElist dae;
      BackendDAE.BackendDAE dlow;
      DAE.FunctionTree functionTree;
      Absyn.Path path;
      list<SimCode.Function> fns;
      list<DAE.Exp> lits;
      
    case (dae,dlow as BackendDAE.DAE(shared=BackendDAE.SHARED(functionTree=functionTree)),path)
      equation
        // get all the used functions from the function tree
        funcelems = DAEUtil.getFunctionList(functionTree);
        part_func_elems = PartFn.createPartEvalFunctions(funcelems);
        (dae, part_func_elems) = PartFn.partEvalDAE(dae, part_func_elems);
        part_func_elems = PartFn.partEvalBackendDAE(dlow,part_func_elems);
        funcelems = List.union(part_func_elems, part_func_elems);
        //funcelems = List.union(funcelems, part_func_elems);
        funcelems = Inline.inlineCallsInFunctions(funcelems,(NONE(),{DAE.NORM_INLINE(), DAE.AFTER_INDEX_RED_INLINE()}),{});
        //Debug.fprintln(Flags.INFO, "Generating functions, call Codegen.\n") "debug" ;
        (funcelems,literals as (_,_,lits)) = simulationFindLiterals(dlow,funcelems);
        (fns, recordDecls, includes2, includeDirs2, libs2) = elaborateFunctions(funcelems, {}, lits, {}); // Do we need metarecords here as well?
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
        false = Config.acceptMetaModelicaGrammar();
      then {};
    case (dae, dlow)
      equation
        true = Config.acceptMetaModelicaGrammar();
        fcallexps = BackendDAEUtil.traverseBackendDAEExps(dlow,matchFnRefs,{});
        calledfuncs = List.map(fcallexps, getCallPath);
        res = removeDuplicatePaths(calledfuncs);
      then res;
  end matchcontinue;
end getCalledFunctionReferences;

public function elaborateFunctions
  input list<DAE.Function> daeElements;
  input list<DAE.Type> metarecordTypes;
  input list<DAE.Exp> literals;
  input list<String> includes;
  output list<SimCode.Function> functions;
  output list<SimCode.RecordDeclaration> extraRecordDecls;
  output list<String> outIncludes;
  output list<String> includeDirs;
  output list<String> libs;
protected
  list<SimCode.Function> fns;
  list<String> outRecordTypes;
algorithm
  (extraRecordDecls, outRecordTypes) := elaborateRecordDeclarationsForMetarecords(literals,{},{});
  (functions, outRecordTypes, extraRecordDecls, outIncludes, includeDirs, libs) := elaborateFunctions2(daeElements,{},outRecordTypes,extraRecordDecls,includes,{},{});
  (extraRecordDecls,_) := elaborateRecordDeclarationsFromTypes(metarecordTypes, extraRecordDecls, outRecordTypes);
end elaborateFunctions;

protected function elaborateFunctions2
  input list<DAE.Function> daeElements;
  input list<SimCode.Function> inFunctions;
  input list<String> inRecordTypes;
  input list<SimCode.RecordDeclaration> inDecls;
  input list<String> inIncludes;
  input list<String> inIncludeDirs;
  input list<String> inLibs;
  output list<SimCode.Function> outFunctions;
  output list<String> outRecordTypes;
  output list<SimCode.RecordDeclaration> outDecls;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<String> outLibs;
algorithm
  (outFunctions, outRecordTypes, outDecls, outIncludes, outIncludeDirs, outLibs) :=
  matchcontinue (daeElements, inFunctions, inRecordTypes, inDecls, inIncludes, inIncludeDirs, inLibs)
    local
      list<SimCode.Function> accfns, fns;
      SimCode.Function fn;
      list<String> rt, rt_1, rt_2, includes, libs;
      DAE.Function fel;
      list<DAE.Function> rest;
      list<SimCode.RecordDeclaration> decls;
      String name;
      list<String> includeDirs;
      Absyn.Path path;
      
    case ({}, accfns, rt, decls, includes, includeDirs, libs)
    then (listReverse(accfns), rt, decls, includes, includeDirs, libs);
    case ((DAE.FUNCTION(path=path,type_ = DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isBuiltin=DAE.FUNCTION_BUILTIN_PTR()))) :: rest), accfns, rt, decls, includes, includeDirs, libs)
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

/* Does the actual work of transforming a DAE.FUNCTION to a SimCode.Function. */
protected function elaborateFunction
  input DAE.Function inElement;
  input list<String> inRecordTypes;
  input list<SimCode.RecordDeclaration> inRecordDecls;
  input list<String> inIncludes;
  input list<String> inIncludeDirs;
  input list<String> inLibs;
  output SimCode.Function outFunction;
  output list<String> outRecordTypes;
  output list<SimCode.RecordDeclaration> outRecordDecls;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<String> outLibs;
algorithm
  (outFunction,outRecordTypes,outRecordDecls,outIncludes,outIncludeDirs,outLibs):=
  matchcontinue (inElement,inRecordTypes,inRecordDecls,inIncludes,inIncludeDirs,inLibs)
    local
      DAE.Function fn;
      String extfnname,lang,str;
      list<DAE.Element> algs, vars; //, bivars, invars, outvars;
      list<String> includes,libs,fn_libs,fn_includes,fn_includeDirs,rt,rt_1;
      Absyn.Path fpath;
      list<DAE.FuncArg> args;
      Types.Type restype,tp;
      list<DAE.ExtArg> extargs;
      list<SimCode.SimExtArg> simextargs;
      SimCode.SimExtArg extReturn;
      DAE.ExtArg extretarg;
      Option<SCode.Annotation> ann;
      DAE.ExternalDecl extdecl;
      list<SimCode.Variable> outVars, inVars, biVars, funArgs, varDecls;
      list<SimCode.RecordDeclaration> recordDecls;
      list<SimCode.Statement> bodyStmts;
      list<DAE.Element> daeElts;
      Absyn.Path name;
      DAE.ElementSource source;
      Absyn.Info info;
      Boolean dynamicLoad;
      list<String> includeDirs;
      DAE.FunctionAttributes funAttrs;
      
      // Modelica functions.
    case (DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = tp as DAE.T_FUNCTION(funcArg=args, funcResultType=restype, functionAttributes=funAttrs),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs)
      equation
        
        DAE.FUNCTION_ATTRIBUTES(_,_,_, DAE.FP_NON_PARALLEL()) = funAttrs;
        
        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = List.map(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = List.filter(daeElts, isVarQ);
        varDecls = List.map(vars, daeInOutSimVar);
        algs = List.filter(daeElts, DAEUtil.isAlgorithm);
        bodyStmts = List.map(algs, elaborateStatement);
        info = DAEUtil.getElementSourceFileInfo(source);
      then
        (SimCode.FUNCTION(fpath,outVars,funArgs,varDecls,bodyStmts,info),rt_1,recordDecls,includes,includeDirs,libs);
        
        
     case (DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = tp as DAE.T_FUNCTION(funcArg=args, funcResultType=restype, functionAttributes=funAttrs),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs)
      equation
        
        DAE.FUNCTION_ATTRIBUTES(_,_,_, DAE.FP_KERNEL_FUNCTION()) = funAttrs;
        
        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = List.map(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = List.filter(daeElts, isVarNotInputNotOutput);
        varDecls = List.map(vars, daeInOutSimVar);
        algs = List.filter(daeElts, DAEUtil.isAlgorithm);
        bodyStmts = List.map(algs, elaborateStatement);
        info = DAEUtil.getElementSourceFileInfo(source);
      then
        (SimCode.KERNEL_FUNCTION(fpath,outVars,funArgs,varDecls,bodyStmts,info),rt_1,recordDecls,includes,includeDirs,libs);   
        
        
    case (DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = tp as DAE.T_FUNCTION(funcArg=args, funcResultType=restype, functionAttributes = funAttrs),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs)
      equation
        
        DAE.FUNCTION_ATTRIBUTES(_,_,_,DAE.FP_PARALLEL_FUNCTION()) = funAttrs;
        
        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = List.map(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = List.filter(daeElts, isVarQ);
        varDecls = List.map(vars, daeInOutSimVar);
        algs = List.filter(daeElts, DAEUtil.isAlgorithm);
        bodyStmts = List.map(algs, elaborateStatement);
        info = DAEUtil.getElementSourceFileInfo(source);
      then
        (SimCode.PARALLEL_FUNCTION(fpath,outVars,funArgs,varDecls,bodyStmts,info),rt_1,recordDecls,includes,includeDirs,libs);
        
/*    
     //mahge930: kernel functions
    case (DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = tp as DAE.T_FUNCTION(funcArg=args, funcResultType=restype, functionAttributes = funAttrs),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs)
      equation
        
        DAE.FUNCTION_ATTRIBUTES(_,_,_, DAE.FP_KERNEL_FUNCTION()) = funAttrs;
        
        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = List.map(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = List.filter(daeElts, isVarQ);
        varDecls = List.map(vars, daeInOutSimVar);
        algs = List.filter(daeElts, DAEUtil.isAlgorithm);
        bodyStmts = List.map(algs, elaborateStatement);
        info = DAEUtil.getElementSourceFileInfo(source);
        
        
        outVars = Util.listMap(DAEUtil.getOutputVars(daeElts), daeInOutSimVarKernelInterface);     
        //outVars = Util.listMap(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);     
       
        funArgs = Util.listMap(args, typesSimFunctionArgKernelInterface);     
        //funArgs = Util.listMap(args, typesSimFunctionArg);     

        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        
        //kernel function "vardecls" shouldn't include output vars.
        vars = Util.listFilter(daeElts, isVarNotInputNotOutput);
        varDecls = Util.listMap(vars, daeInOutSimVar);
        algs = Util.listFilter(daeElts, DAEUtil.isAlgorithm);
        bodyStmts = Util.listMap(algs, elaborateStatement);
        
      then
        (KERNEL_FUNCTION(fpath,outVars,funArgs,varDecls,bodyStmts,info),rt_1,recordDecls,includes,includeDirs,libs);
*/
        
        // External functions.
    case (DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_EXT(body =  daeElts, externalDecl = extdecl)::_, // might be followed by derivative maps
      type_ = (tp as DAE.T_FUNCTION(funcArg = args,funcResultType = restype))),rt,recordDecls,includes,includeDirs,libs)
      equation
        DAE.EXTERNALDECL(name=extfnname, args=extargs,
          returnArg=extretarg, language=lang, ann=ann) = extdecl;
        //outvars = DAEUtil.getOutputVars(daeElts);
        //invars = DAEUtil.getInputVars(daeElts);
        //bivars = DAEUtil.getBidirVars(daeElts);
        funArgs = List.map(args, typesSimFunctionArg);
        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        inVars = List.map(DAEUtil.getInputVars(daeElts), daeInOutSimVar);
        biVars = List.map(DAEUtil.getBidirVars(daeElts), daeInOutSimVar);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        (fn_includes, fn_includeDirs, fn_libs, dynamicLoad) = generateExtFunctionIncludes(fpath,ann);
        includes = List.union(fn_includes, includes);
        includeDirs = List.union(fn_includeDirs, includeDirs);
        libs = List.union(fn_libs, libs);
        simextargs = List.map(extargs, extArgsToSimExtArgs);
        extReturn = extArgsToSimExtArgs(extretarg);
        (simextargs, extReturn) = fixOutputIndex(outVars, simextargs, extReturn);
        info = DAEUtil.getElementSourceFileInfo(source);
        // make lang to-upper as we have FORTRAN 77 and Fortran 77 in the Modelica Library!
        lang = System.toupper(lang);
      then
        (SimCode.EXTERNAL_FUNCTION(fpath, extfnname, funArgs, simextargs, extReturn,
          inVars, outVars, biVars, fn_libs, lang, info, dynamicLoad),
          rt_1, recordDecls, includes, includeDirs, libs);
        
        // Record constructor.
    case (DAE.RECORD_CONSTRUCTOR(path = fpath, source = source, type_ = tp as DAE.T_FUNCTION(funcArg = args,funcResultType = restype as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)))), rt,recordDecls,includes,includeDirs,libs)
      equation
        funArgs = List.map(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarationsForRecord(restype, recordDecls, rt);
        info = DAEUtil.getElementSourceFileInfo(source);
      then
        (SimCode.RECORD_CONSTRUCTOR(name, funArgs, info),rt_1,recordDecls,includes,includeDirs,libs);
        
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
  output SimCode.Variable outVar;
algorithm
  outVar := matchcontinue (inFuncArg)
    local
      Types.Type tty;
      String name;
      DAE.ComponentRef cref_;
      list<Types.FuncArg> args;
      DAE.Type res_ty;
      list<SimCode.Variable> var_args;
      list<DAE.Type> tys;
      
    case ((name, tty as DAE.T_FUNCTION(funcArg = args, funcResultType = DAE.T_TUPLE(tupleType = tys)), _, _))
      equation
        var_args = List.map(args, typesSimFunctionArg);
        tys = List.map(tys, Types.simplifyType);
      then
        SimCode.FUNCTION_PTR(name, tys, var_args);
        
    case ((name, tty as DAE.T_FUNCTION(funcArg = args, funcResultType = DAE.T_NORETCALL(source = _)),_,_))
      equation
        var_args = List.map(args, typesSimFunctionArg);
      then
        SimCode.FUNCTION_PTR(name, {}, var_args);
        
    case ((name, tty as DAE.T_FUNCTION(funcArg = args, funcResultType = res_ty),_,_))
      equation
        res_ty = Types.simplifyType(res_ty);
        var_args = List.map(args, typesSimFunctionArg);
      then
        SimCode.FUNCTION_PTR(name, {res_ty}, var_args);
        
    case ((name,tty,_,_))
      equation
        tty = Types.simplifyType(tty);
        cref_  = ComponentReference.makeCrefIdent(name, tty, {});
      then
        SimCode.VARIABLE(cref_,tty,NONE(),{}, DAE.NON_PARALLEL());
  end matchcontinue;
end typesSimFunctionArg;

protected function daeInOutSimVar
  input DAE.Element inElement;
  output SimCode.Variable outVar;
algorithm
  outVar := matchcontinue(inElement)
    local
      String name;
      DAE.Type daeType;
      Expression.ComponentRef id;
      DAE.VarParallelism prl;
      list<Expression.Subscript> inst_dims;
      list<DAE.Exp> inst_dims_exp;
      Option<DAE.Exp> binding;
      SimCode.Variable var;
    case (DAE.VAR(componentRef = DAE.CREF_IDENT(ident=name),ty = daeType as DAE.T_FUNCTION(funcArg=_)))
      equation
        var = typesSimFunctionArg((name,daeType,DAE.C_VAR(),NONE()));
      then var;
        
    case (DAE.VAR(componentRef = id,
      parallelism = prl,
      ty = daeType,
      binding = binding,
      dims = inst_dims
    ))
      equation
        daeType = Types.simplifyType(daeType);
        inst_dims_exp = List.map(inst_dims, indexSubscriptToExp);
      then SimCode.VARIABLE(id,daeType,binding,inst_dims_exp,prl);
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
  output SimCode.SimExtArg simExtArg;
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
      DAE.Exp exp_;
      Integer outputIndex;
    
    case DAE.EXTARG(componentRef, attributes, type_)
      equation
        isInput = Types.isInputAttr(attributes);
        isOutput = Types.isOutputAttr(attributes);
        outputIndex = Util.if_(isOutput, -1, 0); // correct output index is added later by fixOutputIndex
        isArray = Types.isArray(type_, {});
        type_ = Types.simplifyType(type_);
      then SimCode.SIMEXTARG(componentRef, isInput, outputIndex, isArray, false /*fixed later*/, type_);
    
    case DAE.EXTARGEXP(exp_, type_)
      equation
        type_ = Types.simplifyType(type_);
      then SimCode.SIMEXTARGEXP(exp_, type_);
    
    case DAE.EXTARGSIZE(componentRef, attributes, type_, exp_)
      equation
        isInput = Types.isInputAttr(attributes);
        isOutput = Types.isOutputAttr(attributes);
        outputIndex = Util.if_(isOutput, -1, 0); // correct output index is added later by fixOutputIndex
        type_ = Types.simplifyType(type_);
      then SimCode.SIMEXTARGSIZE(componentRef, isInput, outputIndex, type_, exp_);
    
    case DAE.NOEXTARG() then SimCode.SIMNOEXTARG();
  end match;
end extArgsToSimExtArgs;

protected function fixOutputIndex
  input list<SimCode.Variable> outVars;
  input list<SimCode.SimExtArg> simExtArgsIn;
  input SimCode.SimExtArg extReturnIn;
  output list<SimCode.SimExtArg> simExtArgsOut;
  output SimCode.SimExtArg extReturnOut;
algorithm
  (simExtArgsOut, extReturnOut) := match (outVars, simExtArgsIn, extReturnIn)
    local
    case (_, _, _)
      equation
        simExtArgsOut = List.map1(simExtArgsIn, assignOutputIndex, outVars);
        extReturnOut = assignOutputIndex(extReturnIn, outVars);
      then
        (simExtArgsOut, extReturnOut);
  end match;
end fixOutputIndex;

protected function assignOutputIndex
  input SimCode.SimExtArg simExtArgIn;
  input list<SimCode.Variable> outVars;
  output SimCode.SimExtArg simExtArgOut;
algorithm
  simExtArgOut :=
  matchcontinue (simExtArgIn, outVars)
    local
      DAE.ComponentRef cref;
      Boolean isInput;
      Integer outputIndex; // > 0 if output
      Boolean isArray,hasBinding;
      DAE.Type type_;
      DAE.Exp exp;
      Integer newOutputIndex;
    
    case (SimCode.SIMEXTARG(cref, isInput, outputIndex, isArray, _, type_), _)
      equation
        true = outputIndex == -1;
        (newOutputIndex,hasBinding) = findIndexInList(cref, outVars, 1);
      then 
        SimCode.SIMEXTARG(cref, isInput, newOutputIndex, isArray, hasBinding, type_);
    
    case (SimCode.SIMEXTARGSIZE(cref, isInput, outputIndex, type_, exp), _)
      equation
        true = outputIndex == -1;
        (newOutputIndex,_) = findIndexInList(cref, outVars, 1);
      then 
        SimCode.SIMEXTARGSIZE(cref, isInput, newOutputIndex, type_, exp);
            
    case (_, _)
      then 
        simExtArgIn;
  end matchcontinue;
end assignOutputIndex;

protected function findIndexInList
  input DAE.ComponentRef cref;
  input list<SimCode.Variable> outVars;
  input Integer inCurrentIndex;
  output Integer crefIndexInOutVars;
  output Boolean hasBinding;
algorithm
  (crefIndexInOutVars,hasBinding) :=
  matchcontinue (cref, outVars, inCurrentIndex)
    local
      DAE.ComponentRef name;
      list<SimCode.Variable> restOutVars;
      Option<DAE.Exp> v;
      Integer currentIndex;
    
    case (_, {}, currentIndex) then (-1,false);
    case (_, SimCode.VARIABLE(name=name,value=v) :: restOutVars, currentIndex)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cref,name);
      then (currentIndex,Util.isSome(v));
    case (_, _ :: restOutVars, currentIndex)
      equation
        currentIndex = currentIndex + 1;
        (currentIndex,hasBinding) = findIndexInList(cref, restOutVars, currentIndex);
      then (currentIndex,hasBinding);
  end matchcontinue;
end findIndexInList;

protected function elaborateStatement
  input DAE.Element inElement;
  output SimCode.Statement outStatement;
algorithm
  (outStatement):=
  matchcontinue (inElement)
    local
      list<Algorithm.Statement> stmts;
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)))
    then
      SimCode.ALGORITHM(stmts);
    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE, "# SimCode.elaborateStatement failed\n");
      then
        fail();
  end matchcontinue;
end elaborateStatement;

// Copied from SimCodegen.generateSimulationCode.
protected function createSimCode
  input BackendDAE.BackendDAE inBackendDAE;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<SimCode.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCode.RecordDeclaration> recordDecls;
  input tuple<Integer,HashTableExpToIndex.HashTable,list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  output SimCode.SimCode simCode;
algorithm
  simCode :=
  matchcontinue (inBackendDAE,inClassName,filenamePrefix,inString11,functions,externalFunctionIncludes,includeDirs,libs,simSettingsOpt,recordDecls,literals,args)
    local
      String cname,   fileDir;
      Integer n_h,maxDelayedExpIndex, uniqueEqIndex, numberofNonLinearSys, numberofEqns, numberOfInitialEquations, numberOfInitialAlgorithms;
      list<SimCode.HelpVarInfo> helpVarInfo;
      BackendDAE.BackendDAE dlow,dlow2;
      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symJacs;
      Absyn.Path class_;
      // new variables
      SimCode.ModelInfo modelInfo;
      list<SimCode.SimEqSystem> allEquations;
      list<list<SimCode.SimEqSystem>> odeEquations;   // --> functionODE
      list<SimCode.SimEqSystem> algebraicEquations;   // --> functionAlgebraics
      list<SimCode.SimEqSystem> residuals;            // --> initial_residual
      list<SimCode.SimEqSystem> initialEquations;     // --> initial_equations
      list<SimCode.SimEqSystem> startValueEquations;  // --> updateBoundStartValues
      list<SimCode.SimEqSystem> parameterEquations;   // --> updateBoundParameters
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> sampleEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<DAE.Constraint> constraints;
      list<BackendDAE.ZeroCrossing> zeroCrossings, sampleZC;
      list<SimCode.SimWhenClause> whenClauses;
      list<SimCode.SampleCondition> sampleConditions;
      list<BackendDAE.Equation> sampleEqns;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      list<tuple<Integer, DAE.Exp>> delayedExps;
      list<tuple<DAE.Exp,DAE.ElementSource>> divLst;
      list<DAE.Statement> allDivStmts;
      list<BackendDAE.Variables> orderedVars;
      BackendDAE.Variables knownVars,vars;
      list<BackendDAE.Var> varlst,varlst1,varlst2;
      
      list<SimCode.JacobianMatrix> LinearMatrices;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      Boolean ifcpp,hasDivStmts,initialSystemSolved;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.EquationArray removedEqs;
      array<DAE.Constraint> constrsarr;
      
      list<DAE.Exp> lits;
      list<SimCode.SimVar> tempvars;
      
      SimCode.JacobianMatrix jacG;
    case (dlow,class_,_,fileDir,_,_,_,_,_,_,_,_)
      equation
        System.tmpTickReset(0);
        ifcpp = stringEqual(Config.simCodeTarget(),"Cpp");
         //Debug.fcall(Flags.CPP_VAR,print, "is that Cpp? : " +& Dump.printBoolStr(ifcpp) +& "\n");
        cname = Absyn.pathStringNoQual(class_);
       
        // check if the Sytems has states
        dlow = BackendDAEUtil.addDummyStateIfNeeded(dlow);
        
        (helpVarInfo, dlow2, sampleEqns) = generateHelpVarInfo(dlow);
        BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=removedEqs, 
                                                          constraints = constrsarr,
                                                          functionTree = functionTree,
                                                          symjacs = symJacs)) = dlow2;
        
        extObjInfo = createExtObjInfo(shared);
        
        whenClauses = createSimWhenClauses(dlow2, helpVarInfo);
        zeroCrossings = getZeroCrossings(dlow2, ifcpp);
        sampleZC = getSamples(dlow2);
        zeroCrossings = Util.if_(ifcpp,listAppend(zeroCrossings,sampleZC),zeroCrossings);
        (sampleConditions, helpVarInfo) = prepareSampleConditions(sampleZC,helpVarInfo,{});
        zeroCrossings = updateSamplesConditionsinZC(zeroCrossings,helpVarInfo,sampleConditions,{});
        (uniqueEqIndex,sampleEquations) = createSampleEquations(sampleEqns,1,{});
        n_h = listLength(helpVarInfo);
        
        // initialization stuff
        (residuals, initialEquations, numberOfInitialEquations, numberOfInitialAlgorithms, uniqueEqIndex, tempvars, initialSystemSolved) = createInitialResiduals(dlow2, uniqueEqIndex, {}, helpVarInfo);
        (jacG, uniqueEqIndex) = createInitialMatrices(dlow2, uniqueEqIndex);
 
        // Add model info
        modelInfo = createModelInfo(class_, dlow2, functions, {}, n_h, numberOfInitialEquations, numberOfInitialAlgorithms, fileDir,ifcpp);
        
        // equation generation for euler, dassl2, rungekutta
        (uniqueEqIndex,odeEquations,algebraicEquations,allEquations,tempvars) = createEquationsForSystems(systs,shared,helpVarInfo,uniqueEqIndex,{},{},{},tempvars);
        
        modelInfo = addTempVars(tempvars,modelInfo);
        
        odeEquations = makeEqualLengthLists(odeEquations,Config.noProc());

        // Assertions and crap
        // create parameter equations
        ((uniqueEqIndex,startValueEquations)) = BackendDAEUtil.foldEqSystem(dlow2,createStartValueEquations,(uniqueEqIndex,{}));
        ((uniqueEqIndex,parameterEquations)) = BackendDAEUtil.foldEqSystem(dlow2,createVarNominalAssertFromVars,(uniqueEqIndex,{}));
        (uniqueEqIndex,parameterEquations) = createParameterEquations(shared,uniqueEqIndex,parameterEquations,initialSystemSolved);        
        ((uniqueEqIndex,removedEquations)) = BackendEquation.traverseBackendDAEEqns(removedEqs,traversedlowEqToSimEqSystem,(uniqueEqIndex,{}));
        
        ((uniqueEqIndex,algorithmAndEquationAsserts)) = BackendDAEUtil.foldEqSystem(dlow2,createAlgorithmAndEquationAsserts,(uniqueEqIndex,{}));
        discreteModelVars = BackendDAEUtil.foldEqSystem(dlow2,extractDiscreteModelVars,{});
        makefileParams = createMakefileParams(includeDirs,libs);
        (delayedExps,maxDelayedExpIndex) = extractDelayedExpressions(dlow2);
        
        //append removed equation to all equations, since these are actually 
        //just the algorithms without outputs
        algebraicEquations = listAppend(algebraicEquations,removedEquations);
        allEquations = listAppend(allEquations,removedEquations);
        
        // update indexNonLinear in SES_NONLINEAR and count
        (initialEquations, numberofEqns, numberofNonLinearSys) = indexNonLinSysandCountEqns(initialEquations, 0, 0);
        (parameterEquations, numberofEqns, numberofNonLinearSys) = indexNonLinSysandCountEqns(parameterEquations, numberofEqns, numberofNonLinearSys);
        (allEquations, numberofEqns, numberofNonLinearSys) = indexNonLinSysandCountEqns(allEquations, numberofEqns, numberofNonLinearSys);
                
        // replace div operator with div operator with check of Division by zero
        orderedVars = List.map(systs,BackendVariable.daeVars);
        knownVars = BackendVariable.daeKnVars(shared);
        varlst = List.mapFlat(orderedVars,BackendDAEUtil.varList);
        varlst1 = BackendDAEUtil.varList(knownVars);        
        varlst2 = listAppend(varlst,varlst1);    
        vars = BackendDAEUtil.listVar1(varlst2);
        (allEquations,divLst) = listMap1_2(allEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        (odeEquations,_) = listListMap1_2(odeEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        (algebraicEquations,_) = listMap1_2(algebraicEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        (residuals,_) = listMap1_2(residuals, addDivExpErrorMsgtoSimEqSystem, (vars, varlst2, BackendDAE.ALL()));
        (startValueEquations,_) = listMap1_2(startValueEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ALL()));
        (parameterEquations,_) = listMap1_2(parameterEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ALL()));
        (removedEquations,_) = listMap1_2(removedEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,BackendDAE.ONLY_VARIABLES()));
        // add equations with only parameters as division expression
        allDivStmts = List.map(divLst,generateParameterDivisionbyZeroTestEqn);
        hasDivStmts = listLength(allDivStmts)>0;
        parameterEquations = Debug.bcallret2(hasDivStmts, listAppend, parameterEquations,{SimCode.SES_ALGORITHM(uniqueEqIndex,allDivStmts)},parameterEquations);
        uniqueEqIndex = Util.if_(hasDivStmts, uniqueEqIndex+1,uniqueEqIndex);
        numberofEqns = Util.if_(hasDivStmts, numberofEqns+1,numberofEqns);
        modelInfo = addNumEqnsandNonLinear(modelInfo, numberofEqns, numberofNonLinearSys);
        
        // generate jacobian or linear model matrices
        LinearMatrices = createJacobianLinearCode(symJacs, modelInfo, uniqueEqIndex);
        LinearMatrices = jacG::LinearMatrices;
        
        Debug.fcall(Flags.EXEC_HASH,print, "*** SimCode -> generate cref2simVar hastable: " +& realString(clock()) +& "\n" );
        crefToSimVarHT = createCrefToSimVarHT(modelInfo);
        Debug.fcall(Flags.EXEC_HASH,print, "*** SimCode -> generate cref2simVar hastable done!: " +& realString(clock()) +& "\n" );
        
        constraints = arrayList(constrsarr);
        
        simCode = SimCode.SIMCODE(modelInfo,  
          {}, // Set by the traversal below... 
          recordDecls,
          externalFunctionIncludes,
          allEquations,
          odeEquations,
          algebraicEquations,
          residuals,
          initialEquations,
          startValueEquations,
          parameterEquations,
          removedEquations,
          algorithmAndEquationAsserts,
          constraints,
          zeroCrossings,
          sampleConditions,
          sampleEquations,
          helpVarInfo,
          whenClauses,
          discreteModelVars,
          extObjInfo,
          makefileParams,
          SimCode.DELAYED_EXPRESSIONS(delayedExps, maxDelayedExpIndex),
          LinearMatrices,
          simSettingsOpt,
          filenamePrefix,
          crefToSimVarHT);
        (simCode,(_,_,lits)) = traverseExpsSimCode(simCode,findLiteralsHelper,literals);
        simCode = setSimCodeLiterals(simCode,listReverse(lits));
        Debug.fcall(Flags.EXEC_FILES,print, "*** SimCode -> collect all files started: " +& realString(clock()) +& "\n" );
        // adrpo: collect all the files from Absyn.Info and DAE.ElementSource
        // simCode = collectAllFiles(simCode);
        Debug.fcall(Flags.EXEC_FILES,print, "*** SimCode -> collect all files done!: " +& realString(clock()) +& "\n" );
      then
        simCode;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCode.mo: function createSimCode failed [Transformation from optimised DAE to simulation code structure failed]"});
      then
        fail();
  end matchcontinue;
end createSimCode;

protected function addTempVars
  input list<SimCode.SimVar> tempVars;
  input SimCode.ModelInfo modelInfo;
  output SimCode.ModelInfo omodelInfo;
algorithm
  omodelInfo := match(tempVars,modelInfo)
    local
      Absyn.Path name;
      String directory;
      SimCode.VarInfo varInfo;
      SimCode.SimVars vars;
      list<SimCode.SimVar> stateVars,derivativeVars,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,intAliasVars,boolAliasVars,paramVars,intParamVars,boolParamVars;
      list<SimCode.SimVar> stringAlgVars,stringParamVars,stringAliasVars,extObjVars,constVars,intConstVars,boolConstVars,stringConstVars;
      list<SimCode.Function> functions;
      list<String> labels;
      Integer numHelpVars,numZeroCrossings,numTimeEvents,numRelations;
      Integer numStateVars,numAlgVars,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,numBoolAliasVars;
      Integer numParams,numIntParams,numBoolParams,numOutVars,numInVars;
      Integer numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars;
      Integer numStringParamVars,numStringAliasVars;
      Option<Integer> dimODE1stOrder,dimODE2ndOrder;
      Integer numNonLinearResFunctions, numEqns;
    case({},_) then modelInfo;
    case(_,SimCode.MODELINFO(name,directory,varInfo,vars,functions,labels))
      equation
        SimCode.VARINFO(numHelpVars,numZeroCrossings,numTimeEvents,numRelations,numStateVars,numAlgVars,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,numBoolAliasVars,numParams,
           numIntParams,numBoolParams,numOutVars,numInVars,numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars,
           numStringParamVars,numStringAliasVars,numEqns,numNonLinearResFunctions,dimODE1stOrder,dimODE2ndOrder) = varInfo;
        SimCode.SIMVARS(stateVars,derivativeVars,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,intAliasVars,boolAliasVars,paramVars,intParamVars,boolParamVars,
               stringAlgVars,stringParamVars,stringAliasVars,extObjVars,constVars,intConstVars,boolConstVars,stringConstVars) = vars;
        
       (numAlgVars,algVars,numIntAlgVars,intAlgVars,numBoolAlgVars,boolAlgVars,numStringAlgVars,stringAlgVars)=
          addTempVars1(tempVars,numAlgVars,listReverse(algVars),numIntAlgVars,listReverse(intAlgVars),numBoolAlgVars,listReverse(boolAlgVars),numStringAlgVars,listReverse(stringAlgVars));

        algVars = listReverse(algVars);
        intAlgVars = listReverse(intAlgVars);
        boolAlgVars = listReverse(boolAlgVars);
        stringAlgVars = listReverse(stringAlgVars);

        varInfo = SimCode.VARINFO(numHelpVars,numZeroCrossings,numTimeEvents,numRelations,numStateVars,numAlgVars,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,numBoolAliasVars,numParams,
           numIntParams,numBoolParams,numOutVars,numInVars,numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars,
           numStringParamVars,numStringAliasVars,numEqns,numNonLinearResFunctions,dimODE1stOrder,dimODE2ndOrder);
        vars = SimCode.SIMVARS(stateVars,derivativeVars,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,intAliasVars,boolAliasVars,paramVars,intParamVars,boolParamVars,
               stringAlgVars,stringParamVars,stringAliasVars,extObjVars,constVars,intConstVars,boolConstVars,stringConstVars);
      then
       SimCode.MODELINFO(name,directory,varInfo,vars,functions,labels); 
  end match;
end addTempVars;

protected function addTempVars1
  input list<SimCode.SimVar> tempVars;
  input Integer numAlgVars;
  input list<SimCode.SimVar> algVars;
  input Integer numIntAlgVars;
  input list<SimCode.SimVar> intAlgVars;
  input Integer numBoolAlgVars;
  input list<SimCode.SimVar> boolAlgVars;
  input Integer numStringAlgVars;
  input list<SimCode.SimVar> stringAlgVars;
  output Integer onumAlgVars;
  output list<SimCode.SimVar> oalgVars;
  output Integer onumIntAlgVars;
  output list<SimCode.SimVar> ointAlgVars;
  output Integer onumBoolAlgVars;
  output list<SimCode.SimVar> oboolAlgVars;
  output Integer onumStringAlgVars;
  output list<SimCode.SimVar> ostringAlgVars;
algorithm
  (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars) := 
   match(tempVars,numAlgVars,algVars,numIntAlgVars,intAlgVars,numBoolAlgVars,boolAlgVars,numStringAlgVars,stringAlgVars)
     local
      SimCode.SimVar var;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef name;
      BackendDAE.VarKind varKind;
      String comment,unit;
      String displayUnit;
      Integer index;
      Option<DAE.Exp> minValue,maxValue,initialValue,nominalValue;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      SimCode.AliasVariable aliasvar;
      DAE.ElementSource source;
      SimCode.Causality causality;
      Option<Integer> variable_index;
      list<String> numArrayElement;
     case({},_,_,_,_,_,_,_,_) then (numAlgVars,algVars,numIntAlgVars,intAlgVars,numBoolAlgVars,boolAlgVars,numStringAlgVars,stringAlgVars);     
     case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_ as DAE.T_INTEGER(varLst=_),
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)::rest,_,_,_,_,_,_,_,_)
       equation
         var = SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,numIntAlgVars,minValue,maxValue,initialValue,nominalValue,isFixed,type_,
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars) = 
         addTempVars1(rest,numAlgVars,algVars,numIntAlgVars+1,var::intAlgVars,numBoolAlgVars,boolAlgVars,numStringAlgVars,stringAlgVars);
       then
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars);
     case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_ as DAE.T_BOOL(varLst=_),
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)::rest,_,_,_,_,_,_,_,_)
       equation
         var = SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,numBoolAlgVars,minValue,maxValue,initialValue,nominalValue,isFixed,type_,
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars) = 
         addTempVars1(rest,numAlgVars,algVars,numIntAlgVars,intAlgVars,numBoolAlgVars+1,var::boolAlgVars,numStringAlgVars,stringAlgVars);
       then
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars); 
     case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_ as DAE.T_STRING(varLst=_),
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)::rest,_,_,_,_,_,_,_,_)
       equation
         var = SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,numStringAlgVars,minValue,maxValue,initialValue,nominalValue,isFixed,type_,
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars) = 
         addTempVars1(rest,numAlgVars,algVars,numIntAlgVars,intAlgVars,numBoolAlgVars,boolAlgVars,numStringAlgVars+1,var::stringAlgVars);
       then
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars);                 
     case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_,
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)::rest,_,_,_,_,_,_,_,_)
       equation
         var = SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,numAlgVars,minValue,maxValue,initialValue,nominalValue,isFixed,type_,
          isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars) = 
         addTempVars1(rest,numAlgVars+1,var::algVars,numIntAlgVars,intAlgVars,numBoolAlgVars,boolAlgVars,numStringAlgVars,stringAlgVars);
       then
         (onumAlgVars,oalgVars,onumIntAlgVars,ointAlgVars,onumBoolAlgVars,oboolAlgVars,onumStringAlgVars,ostringAlgVars);
   end match;  
end addTempVars1;

protected function addNumEqnsandNonLinear
  input SimCode.ModelInfo modelInfo;
  input Integer numEqns;  
  input Integer numNonLinearSys;
  output SimCode.ModelInfo omodelInfo;
algorithm
  omodelInfo := match(modelInfo, numEqns, numNonLinearSys)
    local
      Absyn.Path name;
      String directory;
      SimCode.VarInfo varInfo;
      SimCode.SimVars vars;
      list<SimCode.Function> functions;
      list<String> labels;
      Integer numHelpVars,numZeroCrossings,numTimeEvents,numRelations;
      Integer numStateVars,numAlgVars,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,numBoolAliasVars;
      Integer numParams,numIntParams,numBoolParams,numOutVars,numInVars;
      Integer numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars;
      Integer numStringParamVars,numStringAliasVars;
      Option<Integer> dimODE1stOrder,dimODE2ndOrder;
    case(SimCode.MODELINFO(name,directory,varInfo,vars,functions,labels),_,_)
      equation
        SimCode.VARINFO(numHelpVars,numZeroCrossings,numTimeEvents,numRelations,numStateVars,numAlgVars,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,numBoolAliasVars,numParams,
          numIntParams,numBoolParams,numOutVars,numInVars,numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars,  
          numStringParamVars,numStringAliasVars,_,_,dimODE1stOrder,dimODE2ndOrder) = varInfo;
        varInfo = SimCode.VARINFO(numHelpVars,numZeroCrossings,numTimeEvents,numRelations,numStateVars,numAlgVars,numIntAlgVars,numBoolAlgVars,numAlgAliasVars,numIntAliasVars,numBoolAliasVars,numParams,
          numIntParams,numBoolParams,numOutVars,numInVars,numInitialEquations,numInitialAlgorithms,numInitialResiduals,numExternalObjects,numStringAlgVars,  
          numStringParamVars,numStringAliasVars,numEqns,numNonLinearSys,dimODE1stOrder,dimODE2ndOrder);
        then SimCode.MODELINFO(name,directory,varInfo,vars,functions,labels);
  end match;
end addNumEqnsandNonLinear;

protected function createEquationsForSystems
  input BackendDAE.EqSystems inSysts;
  input BackendDAE.Shared shared;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<list<SimCode.SimEqSystem>> inOdeEquations;
  input list<SimCode.SimEqSystem> inAlgebraicEquations;
  input list<SimCode.SimEqSystem> inAllEquations;
  input list<SimCode.SimVar> itempvars;
  output Integer ouniqueEqIndex;
  output list<list<SimCode.SimEqSystem>> oodeEquations;
  output list<SimCode.SimEqSystem> oalgebraicEquations;
  output list<SimCode.SimEqSystem> oallEquations;
  output list<SimCode.SimVar> otempvars;
algorithm
  (ouniqueEqIndex,oodeEquations,oalgebraicEquations,oallEquations,otempvars) := 
  match (inSysts,shared,helpVarInfo,iuniqueEqIndex,inOdeEquations,inAlgebraicEquations,inAllEquations,itempvars)
    local
      list<SimCode.SimEqSystem> odeEquations1,algebraicEquations1,allEquations1;
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      BackendDAE.EqSystems systs;
      list<list<SimCode.SimEqSystem>> odeEquations;
      list<SimCode.SimEqSystem> algebraicEquations;
      list<SimCode.SimEqSystem> allEquations;
      Integer uniqueEqIndex;
      array<Integer> ass1,ass2,stateeqnsmark;
      BackendDAE.Variables vars;
      list<SimCode.SimVar> tempvars;
    case ({},_,_,_,odeEquations,algebraicEquations,allEquations,_)
      then (iuniqueEqIndex,odeEquations,algebraicEquations,allEquations,itempvars);
    
    case ((syst as BackendDAE.EQSYSTEM(orderedVars=vars,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2,comps=comps)))::systs,_,_,_,odeEquations,algebraicEquations,allEquations,_)
      equation
        (syst,_,_) = BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.ABSOLUTE());
        stateeqnsmark = arrayCreate(BackendDAEUtil.equationArraySizeDAE(syst), 0);        
        stateeqnsmark = BackendDAEUtil.markStateEquations(syst, stateeqnsmark, ass1, ass2);
        (odeEquations1,algebraicEquations1,allEquations1,uniqueEqIndex,tempvars) = createEquationsForSystem1(stateeqnsmark, syst, shared, comps, helpVarInfo,iuniqueEqIndex,itempvars);
        odeEquations = odeEquations1::odeEquations;
        algebraicEquations = listAppend(algebraicEquations,algebraicEquations1);
        allEquations = listAppend(allEquations,allEquations1);
        (uniqueEqIndex,odeEquations,algebraicEquations,allEquations,tempvars) = createEquationsForSystems(systs,shared,helpVarInfo,uniqueEqIndex,odeEquations,algebraicEquations,allEquations,tempvars);
     then (uniqueEqIndex,odeEquations,algebraicEquations,allEquations,tempvars);
         
  end match;
end createEquationsForSystems;

protected function addJacobianstoSimCode
  input SimCode.SimCode inSimCode;
  input list<SimCode.JacobianMatrix> inJacobians;
  output SimCode.SimCode outSimCode;
algorithm
  outSimCode := match(inSimCode,inJacobians)
    local
      SimCode.ModelInfo modelInfo;
      list<DAE.Exp> literals "shared literals";
      list<SimCode.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<list<SimCode.SimEqSystem>> odeEquations;
      list<SimCode.SimEqSystem> allEquations,algebraicEquations,residualEquations,startValueEquations,parameterEquations,removedEquations,sampleEquations,algorithmAndEquationAsserts;
      list<SimCode.SimEqSystem> initialEquations;
      list<DAE.Constraint> constraints;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<SimCode.SampleCondition> sampleConditions;
      list<SimCode.HelpVarInfo> helpVarInfo;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      list<String> labels;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      Absyn.Path name;
      String directory;
      SimCode.VarInfo varInfo;
      SimCode.SimVars vars;
      list<SimCode.Function> functions;     

    case (SimCode.SIMCODE(modelInfo,literals,recordDecls,externalFunctionIncludes,allEquations,odeEquations,algebraicEquations,residualEquations,initialEquations,startValueEquations, 
                 parameterEquations,removedEquations,algorithmAndEquationAsserts,constraints,zeroCrossings,sampleConditions,sampleEquations,helpVarInfo,whenClauses,
                 discreteModelVars,extObjInfo,makefileParams,delayedExps,_,simulationSettingsOpt,fileNamePrefix,crefToSimVarHT),inJacobians)
      then
        SimCode.SIMCODE(modelInfo,literals,recordDecls,externalFunctionIncludes,allEquations,odeEquations,algebraicEquations,residualEquations,initialEquations,startValueEquations, 
                  parameterEquations,removedEquations,algorithmAndEquationAsserts,constraints,zeroCrossings,sampleConditions,sampleEquations,helpVarInfo,whenClauses,
                  discreteModelVars,extObjInfo,makefileParams,delayedExps,inJacobians,simulationSettingsOpt,fileNamePrefix,crefToSimVarHT);
                  
  end match;
end addJacobianstoSimCode;


protected function createJacobianLinearCode
  input BackendDAE.SymbolicJacobians inSymjacs;
  input SimCode.ModelInfo inModelInfo;
  input Integer uniqueEqIndex;
  output list<SimCode.JacobianMatrix> res;
algorithm
  res := matchcontinue (inSymjacs, inModelInfo, uniqueEqIndex)
    local 
      BackendDAE.SymbolicJacobians symjacs;
      Boolean b;
    case (_,_,_)
      equation
        //true = Flags.isSet(Flags.JACOBIAN);
        System.realtimeTick(BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
        //b = Flags.disableDebug(Flags.EXEC_STAT);
        // The jacobian code requires single systems;
        // I did not rewrite it to take advantage of any parallelism in the code
        (res,_) = createSymbolicJacobianssSimCode(inSymjacs,inModelInfo,uniqueEqIndex,{"A","B","C","D"});
        // if optModule is not activated add dummy matrices
        res = addLinearizationMatrixes(res);
        //_ = Flags.set(Flags.EXEC_STAT, b);
        Debug.execStat("generated analytical Jacobians SimCode. : ",BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
        _ = System.realtimeTock(BackendDAE.RT_CLOCK_EXECSTAT_JACOBIANS);
      then res;
    else
      equation
        res = {({},{},"A",({},({},{})),{},0),({},{},"B",({},({},{})),{},0),({},{},"C",({},({},{})),{},0),({},{},"D",({},({},{})),{},0)};
      then res;
  end matchcontinue;
end createJacobianLinearCode;

protected function createSymbolicJacobianssSimCode
"fuction creates the linear model matrices column-wise
 author: wbraun"
  input BackendDAE.SymbolicJacobians inSymJacobians;
  input SimCode.ModelInfo inModelInfo;
  input Integer iuniqueEqIndex;
  input list<String> inNames;
  output list<SimCode.JacobianMatrix> outJacobianMatrixes;
  output Integer ouniqueEqIndex;
algorithm
  (outJacobianMatrixes,ouniqueEqIndex) :=
  matchcontinue (inSymJacobians, inModelInfo, iuniqueEqIndex, inNames)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StrongComponents comps;
      BackendDAE.Variables vars, knvars, empty;
      
      DAE.ComponentRef x;
      list<BackendDAE.Var>  diffVars, diffedVars, alldiffedVars;
      list<DAE.ComponentRef> diffCompRefs, diffedCompRefs;

      Integer uniqueEqIndex;
      
      list<String> restnames;
      String name, s, dummyVar;

      SimCode.SimVars simvars;      
      list<SimCode.SimEqSystem> columnEquations;
      list<SimCode.SimVar> columnVars;
      list<SimCode.SimVar> columnVarsKn;
      list<SimCode.SimVar> seedVars, indexVars;
      
      list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern;
      list<list<DAE.ComponentRef>> colsColors;
      Integer maxColor; 
      
      BackendDAE.SymbolicJacobians rest;
      list<SimCode.JacobianMatrix> linearModelMatrices;

    case ({},_,_,_) then ({},iuniqueEqIndex);
    // if nothing is generated
    case (((NONE(),({},({},{})),{}))::rest,_,_,name::restnames)
      equation
        (linearModelMatrices,uniqueEqIndex) = createSymbolicJacobianssSimCode(rest, inModelInfo, iuniqueEqIndex, restnames);
        linearModelMatrices = listAppend({(({},{},name,({},({},{})),{},0))},linearModelMatrices);
     then
        (linearModelMatrices,uniqueEqIndex);
    // if only sparsity pattern is generated       
    case (((NONE(),(sparsepattern,(diffCompRefs,diffedCompRefs)),colsColors))::rest,SimCode.MODELINFO(vars=simvars),_,name::restnames)
      equation
        (_,(_,seedVars)) = traveseSimVars(simvars, findSimVars, (diffCompRefs, {}));
        
        (_,(_,indexVars)) = traveseSimVars(simvars, findSimVars, (diffedCompRefs, {}));

        maxColor = listLength(colsColors);
        s = intString(listLength(diffedCompRefs));

        (linearModelMatrices,uniqueEqIndex) = createSymbolicJacobianssSimCode(rest, inModelInfo, iuniqueEqIndex, restnames);
        linearModelMatrices = listAppend({(({(({},{},s))},seedVars, name, (sparsepattern,(seedVars,indexVars)), colsColors, maxColor))},linearModelMatrices);
     then
        (linearModelMatrices,uniqueEqIndex);
    case (((SOME((BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))},
                                    shared=shared), name,
                                    diffVars, diffedVars, alldiffedVars)),(sparsepattern,(diffCompRefs,diffedCompRefs)),colsColors))::rest,
                                    SimCode.MODELINFO(vars=simvars),_,_::restnames)
      equation
        
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> creating SimCode equations for Matrix " +& name +& " time: " +& realString(clock()) +& "\n");
        (columnEquations,_,uniqueEqIndex,_) = createEquations(false, false, false, false, true, syst, shared, comps, {},iuniqueEqIndex,{});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> created all SimCode equations for Matrix " +& name +&  " time: " +& realString(clock()) +& "\n");

        // create SimCode.SimVars from jacobian vars
        dummyVar = ("dummyVar" +& name);
        x = DAE.CREF_IDENT(dummyVar, DAE.T_REAL_DEFAULT,{});
        vars = BackendDAEUtil.listVar1(diffedVars);
        columnVars = creatallDiffedVars(alldiffedVars, x, vars, 0, (name,false),{});
        
        knvars = BackendVariable.daeKnVars(shared);
        empty = BackendDAEUtil.emptyVars();
        ((columnVarsKn,_)) =  BackendVariable.traverseBackendDAEVars(knvars,traversingdlowvarToSimvar,({},empty));
        columnVars = listAppend(columnVars,columnVarsKn);
        columnVars = listReverse(columnVars);

        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> create all SimCode vars for Matrix " +& name +& " time: " +& realString(clock()) +& "\n");
              
        (_,(_,seedVars)) = traveseSimVars(simvars, findSimVars, (diffCompRefs, {}));
        (_,(_,indexVars)) = traveseSimVars(simvars, findSimVars, (diffedCompRefs, {}));
        maxColor = listLength(colsColors);        
        s =  intString(listLength(diffedVars));

        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> transformed to SimCode for Matrix " +& name +& " time: " +& realString(clock()) +& "\n");

        (linearModelMatrices,uniqueEqIndex) = createSymbolicJacobianssSimCode(rest, inModelInfo, uniqueEqIndex,restnames);
        linearModelMatrices = listAppend({(({((columnEquations,columnVars,s))},seedVars,name,(sparsepattern,(seedVars,indexVars)),colsColors,maxColor))},linearModelMatrices);
     then
        (linearModelMatrices,uniqueEqIndex);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of symbolic matrix SimCode (SimCode.createSymbolicJacobianssSimCode) failed"});
      then
        fail();
  end matchcontinue;
end createSymbolicJacobianssSimCode;

protected function findSimVars
  input tuple<SimCode.SimVar, tuple<list<DAE.ComponentRef>,list<SimCode.SimVar>>> inTuple;
  output tuple<SimCode.SimVar, tuple<list<DAE.ComponentRef>,list<SimCode.SimVar>>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
  local
    DAE.ComponentRef cref;
    list<DAE.ComponentRef> crefs;
    list<SimCode.SimVar> simvars;
    SimCode.SimVar var;
  case((var as (SimCode.SIMVAR(name=cref)), (crefs,simvars)))
    equation
      true = listMember(cref, crefs);
      true = List.notMember(var, simvars);
    then ((var, (crefs, listAppend(simvars,{var}))));
  case(_) then inTuple;
  end matchcontinue;
end findSimVars; 

protected function creatallDiffedVars
  // function: help function for creatallDiffedVars
  // author: wbraun
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inIndex;
  input tuple<String,Boolean> inMatrixName;
  input list<SimCode.SimVar> iVars;
  output list<SimCode.SimVar> outVars;
algorithm
  outVars := matchcontinue(inVars, inCref,inAllVars,inIndex,inMatrixName,iVars)
  local
    BackendDAE.Var  v1;
    SimCode.SimVar r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<BackendDAE.Var> restVar;
   
    case({}, _, _, _, _,_)
    then listReverse(iVars);
    // skip for dicrete variable
    case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.DISCRETE())::restVar,cref,_,_, _, _) equation
     then
       creatallDiffedVars(restVar,cref,inAllVars,inIndex, inMatrixName,iVars);    
 
     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,_,_, _, _) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = BackendDAEOptimize.differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = SimCode.SIMVAR(derivedCref, BackendDAE.STATE_DER(), "","","",inIndex,NONE(),NONE(),NONE(),NONE(),false,DAE.T_REAL_DEFAULT,false,NONE(),SimCode.NOALIAS(),DAE.emptyElementSource,SimCode.NONECAUS(),NONE(),{});
    then 
      creatallDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName,r1::iVars);
      
    case(BackendDAE.VAR(varName=currVar)::restVar,cref,_,_, _, _) equation
      ({v1}, _) = BackendVariable.getVar(currVar, inAllVars);
      derivedCref = BackendDAEOptimize.differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = SimCode.SIMVAR(derivedCref, BackendDAE.STATE_DER(), "","","",inIndex,NONE(),NONE(),NONE(),NONE(),false,DAE.T_REAL_DEFAULT,false,NONE(),SimCode.NOALIAS(),DAE.emptyElementSource,SimCode.NONECAUS(),NONE(),{});
    then 
      creatallDiffedVars(restVar, cref, inAllVars, inIndex+1, inMatrixName,r1::iVars); 
 
     case(BackendDAE.VAR(varName=currVar,varKind=BackendDAE.STATE())::restVar,cref,_,_, _, _) equation
      currVar = ComponentReference.crefPrefixDer(currVar);
      derivedCref = BackendDAEOptimize.differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = SimCode.SIMVAR(derivedCref, BackendDAE.VARIABLE(), "","","",-1,NONE(),NONE(),NONE(),NONE(),false,DAE.T_REAL_DEFAULT,false,NONE(),SimCode.NOALIAS(),DAE.emptyElementSource,SimCode.NONECAUS(),NONE(),{});
    then 
      creatallDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName,r1::iVars);
      
    case(BackendDAE.VAR(varName=currVar)::restVar,cref,_,_, _, _) equation
      derivedCref = BackendDAEOptimize.differentiateVarWithRespectToX(currVar, cref, inMatrixName);
      r1 = SimCode.SIMVAR(derivedCref, BackendDAE.VARIABLE(), "","","",-1,NONE(),NONE(),NONE(),NONE(),false,DAE.T_REAL_DEFAULT,false,NONE(),SimCode.NOALIAS(),DAE.emptyElementSource,SimCode.NONECAUS(),NONE(),{});
    then 
      creatallDiffedVars(restVar, cref, inAllVars, inIndex, inMatrixName,r1::iVars);
 
    else
     equation
      Error.addMessage(Error.INTERNAL_ERROR, {"SimCodeUtil.creatallDiffedVars failed"});
    then fail();
  end matchcontinue;
end creatallDiffedVars;

protected function addLinearizationMatrixes
"fuction creates the jacobian column-wise
 author: wbraun"
  input list<SimCode.JacobianMatrix> injacobianMatrixes;
  output list<SimCode.JacobianMatrix> outjacobianMatrixes;
algorithm
  outjacobianMatrixes :=
  matchcontinue (injacobianMatrixes)
    local
      SimCode.JacobianMatrix inSymJacs;
    case (inSymJacs::{})      
      equation
        outjacobianMatrixes = {inSymJacs,({},{},"B",({},({},{})),{},0),({},{},"C",({},({},{})),{},0),({},{},"D",({},({},{})),{},0)};
      then
        outjacobianMatrixes;
    case _      
      equation
        true = (4 == listLength(injacobianMatrixes));
      then
        injacobianMatrixes;
    else then {({},{},"A",({},({},{})),{},0),({},{},"B",({},({},{})),{},0),({},{},"C",({},({},{})),{},0),({},{},"D",({},({},{})),{},0)};
  end matchcontinue;
end addLinearizationMatrixes;


protected function indexNonLinSysandCountEqns
" function updateNonLinearSys
function counts equations
 and updates index of nonlinear systems"
  input list<SimCode.SimEqSystem> inEqns;
  input Integer inCountEquation;
  input Integer inNonLinSysIndex;  
  output list<SimCode.SimEqSystem> outEqns;
  output Integer outCountEquation;
  output Integer outNonLinSysIndex;
algorithm
  (outEqns, outCountEquation, outNonLinSysIndex) := matchcontinue(inEqns, inCountEquation, inNonLinSysIndex)
    local
      Integer index, indx1, indx2;
      list<SimCode.SimEqSystem> eqs, rest, res;
      list<DAE.ComponentRef> crefs;
      SimCode.SimEqSystem eq,cont;
      list<SimCode.SimVar> discVars;
      list<SimCode.SimEqSystem> discEqs;
      list<Integer> values;
      list<Integer> value_dims;      
    case ({},_,_) 
    then ({},inCountEquation,inNonLinSysIndex);
    case(SimCode.SES_NONLINEAR(index, eqs, crefs, _)::rest, _, _)
      equation
        (res, indx1, indx2) = indexNonLinSysandCountEqns(rest,inCountEquation+1,inNonLinSysIndex+1);
        res = listAppend({SimCode.SES_NONLINEAR(index, eqs, crefs, inNonLinSysIndex)},res);
      then (res, indx1, indx2);
    case(SimCode.SES_MIXED(index, cont, discVars, discEqs)::rest, _, _)
      equation
        ({cont}, indx1, indx2) = indexNonLinSysandCountEqns({cont},inCountEquation,inNonLinSysIndex);  
        (res, indx1, indx2) = indexNonLinSysandCountEqns(rest, indx1+1, indx2);
        res = listAppend({SimCode.SES_MIXED(index, cont, discVars, discEqs)},res);
      then (res, indx1, indx2);          
    case(eq::rest, _, _)
      equation
        (res,indx1, indx2) = indexNonLinSysandCountEqns(rest, inCountEquation+1, inNonLinSysIndex);
        res = listAppend({eq},res);
      then (res, indx1, indx2);
  end matchcontinue;
end indexNonLinSysandCountEqns;

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
    case _ then inTuple;
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
    case _
      equation
        exps = BackendDAEUtil.traverseBackendDAEExps(dlow,findDelaySubExpressions,{});
        delayedExps = List.map(exps, extractIdAndExpFromDelayExp);
        maxDelayedExpIndex = List.fold(List.map(delayedExps, Util.tuple21), intMax, -1);
      then
        (delayedExps,maxDelayedExpIndex+1);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.extractDelayedExpressions failed"});
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
  output SimCode.MakefileParams makefileParams;
protected
  String omhome,ccompiler,cxxcompiler,linker,exeext,dllext,cflags,ldflags,rtlibs,platform;
algorithm
  ccompiler := System.getCCompiler();
  cxxcompiler := System.getCXXCompiler();
  linker := System.getLinker();
  exeext := System.getExeExt();
  dllext := System.getDllExt();
  omhome := Settings.getInstallationDirectoryPath();
  omhome := System.trim(omhome, "\""); // Remove any quotation marks from omhome.
  cflags := System.getCFlags();
  cflags := Debug.bcallret2(Flags.isSet(Flags.OPENMP),stringAppend,cflags," -fopenmp",cflags);
  ldflags := System.getLDFlags();
  rtlibs := System.getRTLibs();
  platform := System.modelicaPlatform();
  makefileParams := SimCode.MAKEFILE_PARAMS(ccompiler, cxxcompiler, linker, exeext, dllext,
        omhome, cflags, ldflags, rtlibs, includes, libs, platform);
end createMakefileParams;

protected function generateHelpVarInfo
  input BackendDAE.BackendDAE idlow;
  output list<SimCode.HelpVarInfo> outHelpVarInfo;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<BackendDAE.Equation> outSampleEqns;
algorithm
  (outHelpVarInfo) := helpVarInfoFromWhenConditionChecks(idlow);
  // Generate HelpVars for sample call outside whenclause
  // additional collect all these equations
  (outHelpVarInfo, outBackendDAE, outSampleEqns) := generateHelpVarsForWhenStatements(outHelpVarInfo, idlow);
end generateHelpVarInfo;

protected function sampleFinder
"function: sampleFinder
  Helper function to sample in equation."
  input tuple<DAE.Exp, tuple<Integer,list<SimCode.HelpVarInfo>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, Boolean, tuple<Integer,list<SimCode.HelpVarInfo>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  match (inTplExpExpTplExpExpLstVariables)
    local
      Integer nhelpvars,nhelpvars1;
      DAE.Exp e;
      list<SimCode.HelpVarInfo> helpvars;
      Boolean b;
    case ((e,(nhelpvars,helpvars)))
      equation
        ((e,(nhelpvars1,helpvars))) = Expression.traverseExp(e, findSampleInExps, (nhelpvars,helpvars));
        b = nhelpvars1 > nhelpvars;
      then ((e,b,(nhelpvars1,helpvars)));
  end match;
end sampleFinder;

protected function findSampleInExps "function: findSampleInExps
  Collects zero crossings"
  input tuple<DAE.Exp, tuple<Integer,list<SimCode.HelpVarInfo>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, tuple<Integer,list<SimCode.HelpVarInfo>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      Integer nhelpvars;
      list<SimCode.HelpVarInfo> helpvars;
      DAE.Exp e;
      Absyn.Path name;
      list<DAE.Exp> args_;
      DAE.CallAttributes attr;
    case (((e as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr)),(nhelpvars,helpvars)))
      equation
        args_ = listAppend(args_,{DAE.ICONST(nhelpvars)});
        e = DAE.CALL(name, args_, attr);
        helpvars = listAppend(helpvars,{(nhelpvars,e,-1)});
        nhelpvars = nhelpvars+1;
      then ((e,(nhelpvars,helpvars)));
    case ((e,(nhelpvars,helpvars)))
    then ((e,(nhelpvars,helpvars)));
  end matchcontinue;
end findSampleInExps;

protected function helpVarInfoFromWhenConditionChecks
"Return a list of help variables that were introduced by when conditions?"
  input BackendDAE.BackendDAE inBackendDAE;
  output list<SimCode.HelpVarInfo> helpVarList;
algorithm
  helpVarList :=
  matchcontinue (inBackendDAE)
    local
      Integer n;
      list<SimCode.HelpVarInfo> helpVarInfo;
      list<BackendDAE.WhenClause> whenClauseList;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
    case (BackendDAE.DAE(eqs=systs,shared=shared as BackendDAE.SHARED(eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = whenClauseList))))
      equation
        ((n,helpVarInfo)) = List.fold(systs,helpVarInfoFromWhenConditionChecks1,(0,{}));
        // Generate checks also for when clauses without equations but containing reinit statements.
        helpVarInfo= buildWhenConditionChecks2(whenClauseList, n, helpVarInfo);
      then
        helpVarInfo;
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
  input tuple<Integer,list<SimCode.HelpVarInfo>> inTpl;
  output tuple<Integer,list<SimCode.HelpVarInfo>> outTpl;
algorithm
  outTpl :=
  matchcontinue (syst,inTpl)
    local
      list<Integer> orderOfEquations,orderOfEquations_1;
      Integer n,helpVarIndex;
      list<SimCode.HelpVarInfo> helpVarInfo;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponents comps;
      array<Boolean> selectedeqns;
    case (BackendDAE.EQSYSTEM(orderedEqs = eqns, matching = BackendDAE.MATCHING(comps=comps)),(helpVarIndex,helpVarInfo))
      equation
        n = BackendDAEUtil.equationArraySize(eqns);
        selectedeqns = arrayCreate(n,false);
        orderOfEquations = generateEquationOrder(comps,selectedeqns,{});
        orderOfEquations_1 = addMissingEquations(n,selectedeqns,{});
        orderOfEquations_1 = listAppend(orderOfEquations_1,orderOfEquations);
        // First generate checks for all when equations, in the order of the sorted equations.
        (helpVarIndex,helpVarInfo) = buildWhenConditionChecks4(orderOfEquations_1, eqns, helpVarIndex,helpVarInfo);
        outTpl = (helpVarIndex,helpVarInfo);
      then
        outTpl;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCode.helpVarInfoFromWhenConditionChecks1 failed"});
      then
        fail();
  end matchcontinue;
end helpVarInfoFromWhenConditionChecks1;

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
        BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left=cr2,right=exp)) = BackendDAEUtil.equationNth(eqs,intAbs(e)-1);
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
  input list<SimCode.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCode.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) :=
  match (inTypes, inAccRecordDecls, inReturnTypes)
    local
      list<SimCode.RecordDeclaration> accRecDecls;
      DAE.Type firstType;
      list<DAE.Type> restTypes;
      list<String> returnTypes;
      
    case ({}, accRecDecls, _)
    then (accRecDecls, inReturnTypes);
    case (firstType :: restTypes, accRecDecls, _)
      equation
        (accRecDecls, returnTypes) =
        elaborateRecordDeclarationsForRecord(firstType, accRecDecls, inReturnTypes);
        (accRecDecls, returnTypes) =
        elaborateRecordDeclarationsFromTypes(restTypes, accRecDecls, returnTypes);
      then (accRecDecls, returnTypes);
  end match;
end elaborateRecordDeclarationsFromTypes;

protected function elaborateRecordDeclarations
"function elaborateRecordDeclarations
Translate all records used by varlist to structs."
  input list<DAE.Element> inVars;
  input list<SimCode.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCode.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) :=
  matchcontinue (inVars, inAccRecordDecls, inReturnTypes)
    local
      DAE.Element var;
      list<DAE.Element> rest;
      Types.Type ft;
      list<String> rt, rt_1, rt_2;
      list<SimCode.RecordDeclaration> accRecDecls;
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
        true = Config.acceptMetaModelicaGrammar();
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
  input list<SimCode.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCode.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) :=
  matchcontinue (inRecordType,inAccRecordDecls,inReturnTypes)
    local
      Absyn.Path path,name;
      list<Types.Var> varlst;
      String    sname;
      list<String> rt,rt_1,rt_2,fieldNames;
      list<SimCode.RecordDeclaration> accRecDecls;
      list<SimCode.Variable> vars;
      Integer index;
      SimCode.RecordDeclaration recDecl;
      
    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name), varLst = varlst, source = {path}), accRecDecls, rt)
      equation
        sname = Absyn.pathStringReplaceDot(name, "_");
        false = listMember(sname,rt);
        vars = List.map(varlst, typesVar);
        rt_1 = sname :: rt;
        (accRecDecls,rt_2) = elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);
        recDecl = SimCode.RECORD_DECL_FULL(sname, path, vars);
        accRecDecls = List.appendElt(recDecl, accRecDecls);
      then (accRecDecls,rt_2);
        
    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name), varLst = varlst), accRecDecls, rt)
    then (accRecDecls,rt);
           
    case (DAE.T_METARECORD(index = index, fields = varlst, source = {path}), accRecDecls, rt)
      equation
        sname = Absyn.pathStringReplaceDot(path, "_");
        false = listMember(sname,rt);
        fieldNames = List.map(varlst, generateVarName);
        accRecDecls = SimCode.RECORD_DECL_DEF(path, fieldNames) :: accRecDecls;
        rt_1 = sname::rt;
        (accRecDecls,rt_2) = elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);
      then (accRecDecls,rt_2);
        
    case (_, accRecDecls, rt)
    then (accRecDecls,rt);
        
    case (_, accRecDecls, rt) then
      (SimCode.RECORD_DECL_FULL("#an odd record#", Absyn.IDENT("?noname?"), {}) :: accRecDecls ,rt);
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
  input list<SimCode.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCode.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) := matchcontinue (inRecordTypes,inAccRecordDecls,inReturnTypes)
    local
      Types.Type ty;
      list<Types.Var> rest;
      list<String> rt,rt_1,rt_2;
      list<SimCode.RecordDeclaration> accRecDecls;
    case ({},accRecDecls,rt)
    then (accRecDecls,rt);
    case (DAE.TYPES_VAR(ty = ty as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)))::rest,accRecDecls,rt)
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
  input list<SimCode.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCode.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) := matchcontinue(inExpl, inAccRecordDecls, inReturnTypes)
    local
      list<String> rt,rt_1,rt_2,fieldNames;
      list<DAE.Exp> rest;
      String name;
      Absyn.Path path;
      list<SimCode.RecordDeclaration> accRecDecls;
      
    case ({},accRecDecls,rt) then (accRecDecls,rt);
    case (DAE.METARECORDCALL(path=path,fieldNames=fieldNames)::rest, accRecDecls, rt)
      equation
        name = Absyn.pathStringReplaceDot(path, "_");
        false = listMember(name,rt);
        accRecDecls = SimCode.RECORD_DECL_DEF(path, fieldNames) :: accRecDecls;
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
  output SimCode.ExtObjInfo extObjInfo;
algorithm
  extObjInfo := match shared
    local
      BackendDAE.Variables evars;
      list<BackendDAE.Var> evarLst;
      list<SimCode.ExtAlias> aliases;
      list<SimCode.SimVar> simvars;
    case BackendDAE.SHARED(externalObjects=evars)
      equation
        evarLst = BackendDAEUtil.varList(evars);
        (simvars,aliases) = extractExtObjInfo2(evarLst,evars,{},{});
      then SimCode.EXTOBJINFO(simvars,aliases);
  end match;
end createExtObjInfo;

protected function extractExtObjInfo2
  input list<BackendDAE.Var> varLst;
  input BackendDAE.Variables evars;
  input list<SimCode.SimVar> ivars;
  input list<SimCode.ExtAlias> ialiases;
  output list<SimCode.SimVar> vars;
  output list<SimCode.ExtAlias> aliases;
algorithm
  (vars,aliases) := match (varLst,evars,ivars,ialiases)
    local
      BackendDAE.Var bv;
      SimCode.SimVar sv;
      list<BackendDAE.Var> vs;
      DAE.ComponentRef cr,name;
    case ({},_,_,_) then (listReverse(ivars),listReverse(ialiases));
    case (BackendDAE.VAR(varName=name, bindExp=SOME(DAE.CREF(cr,_)),varKind=BackendDAE.EXTOBJ(_))::vs,_,_,_)
      equation
        (vars,aliases) = extractExtObjInfo2(vs,evars,ivars,(name, cr)::ialiases);
      then (vars,aliases);
    case (bv::vs,_,_,_)
      equation
        sv = dlowvarToSimvar(bv,NONE(),evars);
        (vars,aliases) = extractExtObjInfo2(vs,evars,sv::ivars,ialiases);
      then (vars,aliases);
  end match;
end extractExtObjInfo2;

protected function createAlgorithmAndEquationAsserts
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer,list<SimCode.SimEqSystem>> acc;
  output tuple<Integer,list<SimCode.SimEqSystem>> algorithmAndEquationAsserts;
algorithm
  algorithmAndEquationAsserts := matchcontinue (syst,shared,acc)
    local
      list<SimCode.SimEqSystem> simeqns;
      list<DAE.Algorithm> res;
      BackendDAE.EquationArray eqns,reqns;
      BackendDAE.Variables vars;
      list<SimCode.SimEqSystem> result;
      Integer uniqueEqIndex;
      
    case (BackendDAE.EQSYSTEM(orderedEqs=eqns, orderedVars = vars),BackendDAE.SHARED(removedEqs=reqns),(uniqueEqIndex,simeqns))
      equation
        // get Modelica and sqrt asserts
        res = BackendEquation.traverseBackendDAEEqns(eqns,createAlgorithmAndEquationAssertsFromAlgsEqnTraverser,{});
        res = BackendEquation.traverseBackendDAEEqns(reqns,createAlgorithmAndEquationAssertsFromAlgsEqnTraverser,res);
        // get minmax and nominal asserts
        res = BackendVariable.traverseBackendDAEVars(vars,createVarMinMaxAssert,res);
        (result,uniqueEqIndex) = List.mapFold(res,dlowAlgToSimEqSystem,uniqueEqIndex);
        result = listAppend(result,simeqns);
      then ((uniqueEqIndex,result));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"createAlgorithmAndEquationAsserts failed"});
      then fail();
  end matchcontinue;
end createAlgorithmAndEquationAsserts;

protected function assertCollector
  input DAE.Statement inStmt;
  input list<DAE.Algorithm> inAcc;
  output list<DAE.Algorithm> outAcc;
algorithm
  outAcc := match(inStmt,inAcc)
    case (DAE.STMT_ASSERT(cond =_),_)
      then 
        DAE.ALGORITHM_STMTS({inStmt})::inAcc;
    else
      then 
        inAcc;
  end match;
end assertCollector;

protected function createAlgorithmAndEquationAssertsFromAlgsEqnTraverser
  "Help function to e.g. traverserexpandDerEquation"
  input tuple<BackendDAE.Equation,list<DAE.Algorithm>> tpl;
  output tuple<BackendDAE.Equation,list<DAE.Algorithm>> outTpl;
algorithm
  outTpl := match(tpl)
    local
      list<DAE.Algorithm> res;
      list<DAE.Statement> stmts; 
      BackendDAE.Equation eqn; 
    // get Modelica Asserts
    case ((eqn as BackendDAE.ALGORITHM(alg= DAE.ALGORITHM_STMTS(stmts)),res))
      equation
        res = List.fold(stmts,assertCollector,res);
      then
        ((eqn,res));
    // get sqrt asserts
    case((eqn,res))
      equation
        (eqn,(_,res)) = BackendEquation.traverseBackendDAEExpsEqn(eqn,Expression.traverseSubexpressionsHelper,(findSqrtCallsforAssertsExps,res));
      then 
        ((eqn,res));
  end match;
end createAlgorithmAndEquationAssertsFromAlgsEqnTraverser;

protected function findSqrtCallsforAssertsExps
  input tuple<DAE.Exp, list<DAE.Algorithm>> inTuple;
  output tuple<DAE.Exp, list<DAE.Algorithm>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e,e1;
      String estr;
      DAE.Algorithm addAssert;
      list<DAE.Algorithm> inasserts;
    
    // sqrt 
    case (((e as DAE.CALL(path=Absyn.IDENT(name="sqrt"), expLst={e1})),inasserts))
      equation
        estr = "Model error: Argument of sqrt(" +& ExpressionDump.printExpStr(e1) +& ") should be >= 0";
        addAssert = DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(DAE.RELATION(e1,DAE.GREATEREQ(DAE.T_REAL_DEFAULT),DAE.RCONST(0.0),-1,NONE()),DAE.SCONST(estr),DAE.ASSERTIONLEVEL_ERROR,DAE.emptyElementSource)});
      then ((e, addAssert::inasserts));
    
    case _ then inTuple;
  end matchcontinue;
end findSqrtCallsforAssertsExps;

protected function createRemovedEquations
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input list<SimCode.SimEqSystem> acc;
  output list<SimCode.SimEqSystem> removedEquations;
algorithm
  removedEquations := matchcontinue (syst,shared,acc)
    local
      BackendDAE.EquationArray r;
      BackendDAE.Variables vars;
      list<DAE.Algorithm> varasserts;
      list<SimCode.SimEqSystem> simvarasserts;
      
    case (BackendDAE.EQSYSTEM(orderedVars = vars), BackendDAE.SHARED(removedEqs=r), acc)
      equation
        // get minmax and nominal asserts
        varasserts = BackendVariable.traverseBackendDAEVars(vars,createVarMinMaxAssert,{});
        (simvarasserts,_) = List.mapFold(varasserts,dlowAlgToSimEqSystem,0);
        removedEquations = listAppend(simvarasserts,acc);
        
      then removedEquations;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"createRemovedEquations failed"});
      then fail();
  end matchcontinue;
end createRemovedEquations;

protected function traversedlowEqToSimEqSystem
  input tuple<BackendDAE.Equation, tuple<Integer,list<SimCode.SimEqSystem>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<Integer,list<SimCode.SimEqSystem>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local 
      BackendDAE.Equation e;
      SimCode.SimEqSystem se;
      list<SimCode.SimEqSystem> seqnlst;
      Integer uniqueEqIndex;
    case ((e,(uniqueEqIndex,seqnlst)))
      equation
        (se,uniqueEqIndex) = dlowEqToSimEqSystem(e,uniqueEqIndex);
      then ((e,(uniqueEqIndex,se::seqnlst)));
    case _ then inTpl;
  end matchcontinue;
end traversedlowEqToSimEqSystem;

protected function extractDiscreteModelVars
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input list<DAE.ComponentRef> acc;
  output list<DAE.ComponentRef> discreteModelVars;
algorithm
  discreteModelVars := matchcontinue (syst,shared,acc)
    local
      BackendDAE.Variables v;
      BackendDAE.EquationArray e;
      list<DAE.ComponentRef> vLst2;
      
    case (BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=e),_,_)
      equation
        // select all discrete vars.
        // remove those vars that are solved in when equations
        // replace var with cref
        vLst2 = BackendVariable.traverseBackendDAEVars(v,traversingisVarDiscreteCrefFinder,{});
        vLst2 = listAppend(vLst2,acc);
        //vLst2 = List.unionOnTrue(vLst2, vLst1, ComponentReference.crefEqual);
      then vLst2;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCode.extractDiscreteModelVars failed"});
      then fail();
  end matchcontinue;
end extractDiscreteModelVars;

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
    case _ then inTpl;
  end matchcontinue;
end traversingisVarDiscreteCrefFinder;

protected function createSimWhenClauses
  input BackendDAE.BackendDAE dlow;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  output list<SimCode.SimWhenClause> osimWhenClauses;
algorithm
  osimWhenClauses := matchcontinue (dlow,helpVarInfo)
    local
      list<BackendDAE.WhenClause> wc;
      BackendDAE.EqSystems systs;
      list<SimCode.SimWhenClause> simWhenClauses;
      
    case (BackendDAE.DAE(eqs=systs,shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(whenClauseLst=wc))),_)
      equation
        simWhenClauses = List.fold1(systs,createSimWhenClausesEqs,helpVarInfo,{});
        simWhenClauses =  List.fold1(wc,whenClauseToSimWhenClause,helpVarInfo,simWhenClauses);
      then
        listReverse(simWhenClauses);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCode.createSimWhenClauses failed"});
      then fail();
  end matchcontinue;
end createSimWhenClauses;

protected function createSimWhenClausesEqs
  input BackendDAE.EqSystem syst;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input list<SimCode.SimWhenClause> isimWhenClauses;
  output list<SimCode.SimWhenClause> osimWhenClauses;
algorithm
  osimWhenClauses := match (syst,helpVarInfo,isimWhenClauses)
    local
      BackendDAE.EquationArray eqs;
    case (BackendDAE.EQSYSTEM(orderedEqs=eqs),_,_)
      equation
        ((osimWhenClauses,_)) = BackendEquation.traverseBackendDAEEqns(eqs,findWhenEquation,(isimWhenClauses,helpVarInfo));
      then
        osimWhenClauses;
  end match;
end createSimWhenClausesEqs;

protected function findWhenEquation
  input tuple<BackendDAE.Equation, tuple<list<SimCode.SimWhenClause>,list<SimCode.HelpVarInfo>>> inTpl;
  output tuple<BackendDAE.Equation, tuple<list<SimCode.SimWhenClause>,list<SimCode.HelpVarInfo>>> outTpl;
algorithm
  outTpl := matchcontinue (inTpl)
    local
      BackendDAE.WhenEquation eq;
      BackendDAE.Equation eqn;
      list<SimCode.SimWhenClause> scw;
      list<SimCode.HelpVarInfo> helpVarInfo;     
    case ((eqn as BackendDAE.WHEN_EQUATION(whenEquation = eq), (scw,helpVarInfo)))
      equation
        scw = findWhenEquation1(eq,helpVarInfo,scw);
      then ((eqn,(scw,helpVarInfo)));
    else then inTpl;
  end matchcontinue;
end findWhenEquation;

protected function findWhenEquation1
  input BackendDAE.WhenEquation inWEqn;
  input list<SimCode.HelpVarInfo> helpVarInfo; 
  input list<SimCode.SimWhenClause> iscw;
  output list<SimCode.SimWhenClause> oscw;
algorithm
  oscw := match(inWEqn,helpVarInfo,iscw)
    local
      DAE.Exp cond;
      list<DAE.Exp> conditions;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex; 
      list<DAE.ComponentRef> conditionVars; 
      BackendDAE.WhenEquation we;
    case (BackendDAE.WHEN_EQ(condition=cond, elsewhenPart=NONE()),_,_)
      equation
        conditions = getConditionList(cond);
        conditionsWithHindex =  List.map2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
        conditionVars = Expression.extractCrefsFromExp(cond);        
      then
        SimCode.SIM_WHEN_CLAUSE(conditionVars, {}, SOME(inWEqn), conditionsWithHindex)::iscw;
    case (BackendDAE.WHEN_EQ(condition=cond, elsewhenPart=SOME(we)),_,_)
      equation
        conditions = getConditionList(cond);
        conditionsWithHindex =  List.map2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
        conditionVars = Expression.extractCrefsFromExp(cond);        
      then
        findWhenEquation1(we,helpVarInfo,SimCode.SIM_WHEN_CLAUSE(conditionVars, {}, SOME(inWEqn), conditionsWithHindex)::iscw);        
  end match;
end findWhenEquation1; 

protected function whenClauseToSimWhenClause
  input BackendDAE.WhenClause whenClause;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input list<SimCode.SimWhenClause> isimWhenClauses;
  output list<SimCode.SimWhenClause> osimWhenClauses;
algorithm
  osimWhenClauses := match (whenClause, helpVarInfo, isimWhenClauses)
    local
      DAE.Exp cond;
      list<BackendDAE.WhenOperator> reinits;
      list<DAE.ComponentRef> conditionVars;
      list<DAE.Exp> conditions;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
      
    case (BackendDAE.WHEN_CLAUSE(condition=cond, reinitStmtLst=reinits), _,_)
      equation
        conditions = getConditionList(cond);
        conditionsWithHindex =  List.map2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
        conditionVars = Expression.extractCrefsFromExp(cond);
      then
        SimCode.SIM_WHEN_CLAUSE(conditionVars, reinits, NONE(), conditionsWithHindex)::isimWhenClauses;
  end match;
end whenClauseToSimWhenClause;

protected function createEquationsForSystem1
  input array<Integer> stateeqnsmark;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.StrongComponents comps;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> odeEquations;
  output list<SimCode.SimEqSystem> algebraicEquations;
  output list<SimCode.SimEqSystem> allEquations;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (odeEquations,algebraicEquations,allEquations,ouniqueEqIndex,otempvars) := matchcontinue (stateeqnsmark, syst, shared, comps, helpVarInfo, iuniqueEqIndex,itempvars)
    local
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents restComps;
      Integer e,index,vindex,uniqueEqIndex;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.Var v;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqnlst;
      list<BackendDAE.Var> varlst;
      list<Integer> eqnslst;
      list<SimCode.SimEqSystem> equations1,noDiscEquations1;
      Boolean bwhen,bdisc,bdynamic;
      list<SimCode.SimVar> tempvars;
      // handle empty
    case (_, _, _, {},_,_,_) then ({},{},{},iuniqueEqIndex,itempvars);
        // single equation 
    case (_, BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns), _, BackendDAE.SINGLEEQUATION(eqn=index,var=vindex) :: restComps, _, _,_)
      equation
        eqn = BackendDAEUtil.equationNth(eqns, index-1);
        // ignore when equations if we should not generate them
        bwhen = BackendEquation.isWhenEquation(eqn);
        // ignore discrete if we should not generate them
        v = BackendVariable.getVarAt(vars,index);
        bdisc = BackendVariable.isVarDiscrete(v);
        // block is dynamic, belong in dynamic section
        bdynamic = BackendDAEUtil.blockIsDynamic({index}, stateeqnsmark);
        (equations1,uniqueEqIndex,tempvars) = createEquation(index, vindex, syst, shared, helpVarInfo, false, false,iuniqueEqIndex,itempvars);
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars) = createEquationsForSystem1(stateeqnsmark, syst, shared, restComps, helpVarInfo,uniqueEqIndex,tempvars);
        odeEquations = Debug.bcallret2(bdynamic and (not bwhen), listAppend, equations1, odeEquations,odeEquations);
        algebraicEquations = Debug.bcallret2((not bdynamic) and (not bwhen), listAppend, equations1, algebraicEquations,algebraicEquations);
        allEquations = listAppend(equations1,allEquations);
      then
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars);
       
      // A single array equation
    case (_, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_, (comp as BackendDAE.SINGLEARRAY(eqn=e)) :: restComps, _, _,_)
      equation
        // block is dynamic, belong in dynamic section
        bdynamic = BackendDAEUtil.blockIsDynamic({e}, stateeqnsmark);        
        (eqnlst,varlst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, transformXToXd);
        (equations1,noDiscEquations1,uniqueEqIndex,tempvars) = createSingleArrayEqnCode(true,eqnlst,varlst,helpVarInfo,iuniqueEqIndex,itempvars);
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars) = createEquationsForSystem1(stateeqnsmark, syst, shared, restComps, helpVarInfo,uniqueEqIndex,tempvars);
        odeEquations = Debug.bcallret2(bdynamic, listAppend, noDiscEquations1, odeEquations,odeEquations);
        algebraicEquations = Debug.bcallret2((not bdynamic), listAppend, noDiscEquations1, algebraicEquations,algebraicEquations);
        allEquations = listAppend(equations1,allEquations);
      then
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars);
        
        // A single algorithm section for several variables.
    case (_, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_, (comp as BackendDAE.SINGLEALGORITHM(eqn=e)) :: restComps, _, _,_)
      equation
        // block is dynamic, belong in dynamic section
        bdynamic = BackendDAEUtil.blockIsDynamic({e}, stateeqnsmark);        
        (eqnlst,varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        varlst = List.map(varlst, transformXToXd);
        (equations1,uniqueEqIndex) = createSingleAlgorithmCode(eqnlst,varlst,false,iuniqueEqIndex);
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars) = createEquationsForSystem1(stateeqnsmark, syst, shared, restComps, helpVarInfo,uniqueEqIndex,itempvars);
        odeEquations = Debug.bcallret2(bdynamic, listAppend, equations1, odeEquations,odeEquations);
        algebraicEquations = Debug.bcallret2((not bdynamic), listAppend, equations1, algebraicEquations,algebraicEquations);
        allEquations = listAppend(equations1,allEquations);
      then
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars);      
       
      // A single complex equation
    case (_, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_, (comp as BackendDAE.SINGLECOMPLEXEQUATION(eqn=e)) :: restComps, _, _,_)
      equation
        // block is dynamic, belong in dynamic section
        bdynamic = BackendDAEUtil.blockIsDynamic({e}, stateeqnsmark);        
        (eqnlst,varlst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, transformXToXd);
        (equations1,uniqueEqIndex,tempvars) = createSingleComplexEqnCode(listGet(eqnlst,1),varlst,helpVarInfo,iuniqueEqIndex,itempvars);
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars) = createEquationsForSystem1(stateeqnsmark, syst, shared, restComps, helpVarInfo,uniqueEqIndex,tempvars);
        odeEquations = Debug.bcallret2(bdynamic, listAppend, equations1, odeEquations,odeEquations);
        algebraicEquations = Debug.bcallret2((not bdynamic), listAppend, equations1, algebraicEquations,algebraicEquations);
        allEquations = listAppend(equations1,allEquations);
      then
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars);
                 
        // a system of equations 
    case (_, _, _, comp :: restComps, _,_,_)
      equation
        // block is dynamic, belong in dynamic section
        (eqnslst,_) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        bdynamic = BackendDAEUtil.blockIsDynamic(eqnslst, stateeqnsmark);        
        (equations1,noDiscEquations1,uniqueEqIndex,tempvars) = createOdeSystem(true,  false, false, syst, shared, comp, helpVarInfo,iuniqueEqIndex,itempvars);
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars) = createEquationsForSystem1(stateeqnsmark, syst, shared, restComps, helpVarInfo,uniqueEqIndex,tempvars);
        odeEquations = Debug.bcallret2(bdynamic, listAppend, noDiscEquations1, odeEquations,odeEquations);
        algebraicEquations = Debug.bcallret2((not bdynamic), listAppend, noDiscEquations1, algebraicEquations,algebraicEquations);
        allEquations = listAppend(equations1,allEquations);
      then
        (odeEquations,algebraicEquations,allEquations,uniqueEqIndex,tempvars);
       
    // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createEquationsForSystem1 failed"});
      then
        fail();
  end matchcontinue;
end createEquationsForSystem1;

protected function createEquations
  input Boolean includeWhen;
  input Boolean skipDiscInZc;
  input Boolean genDiscrete;
  input Boolean skipDiscInAlgorithm;
  input Boolean linearSystem "if true always generate a linear system";
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.StrongComponents comps;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations;
  output list<SimCode.SimEqSystem> noDiscEquations;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equations,noDiscEquations,ouniqueEqIndex,otempvars) := matchcontinue (includeWhen, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, linearSystem, syst, shared, comps, helpVarInfo, iuniqueEqIndex,itempvars)
    local
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents restComps;
      Integer index,vindex,uniqueEqIndex;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.Var v;
      list<BackendDAE.Equation> eqnlst;
      list<BackendDAE.Var> varlst;
      list<Integer> zcEqns,eqnslst;
      list<SimCode.SimEqSystem> equations_,equations1,noDiscEquations1;
      list<SimCode.SimVar> tempvars;
      // handle empty
    case (_,_,_,_,_,_, _, {},_,_,_) then ({},{},iuniqueEqIndex,itempvars);
      
      // ignore when equations if we should not generate them
    case (false, _, _, _, _, BackendDAE.EQSYSTEM(orderedEqs=eqns), _, BackendDAE.SINGLEEQUATION(eqn=index) :: restComps, _, _,_)
      equation
        BackendDAE.WHEN_EQUATION(size=_) = BackendDAEUtil.equationNth(eqns, index-1);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(false, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo, iuniqueEqIndex,itempvars);
      then
        (equations,noDiscEquations,uniqueEqIndex,tempvars);
        
        // ignore discrete if we should not generate them
    case (_, _, false, _, _, BackendDAE.EQSYSTEM(orderedVars=vars), _, BackendDAE.SINGLEEQUATION(var=index) :: restComps, _, _,_)
      equation
        v = BackendVariable.getVarAt(vars,index);
        true = BackendVariable.isVarDiscrete(v);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(includeWhen, skipDiscInZc, false,  skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo, iuniqueEqIndex,itempvars);
      then
        (equations,noDiscEquations,uniqueEqIndex,tempvars);
        
        // ignore discrete in zero crossing if we should not generate them
    case (_, true, _, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _, BackendDAE.SINGLEEQUATION(eqn=index,var=vindex) :: restComps, _, _,_)
      equation
        v = BackendVariable.getVarAt(vars,vindex);
        true = BackendVariable.isVarDiscrete(v);
        zcEqns = BackendDAECreate.zeroCrossingsEquations(syst,shared);
        true = listMember(index, zcEqns);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(includeWhen, true, genDiscrete,  skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo, iuniqueEqIndex,itempvars);
      then
        (equations,noDiscEquations,uniqueEqIndex,tempvars);
        
        // single equation 
    case (_, _, _, _, _, _, _, BackendDAE.SINGLEEQUATION(eqn=index,var=vindex) :: restComps, _, _,_)
      equation
        (equations1,uniqueEqIndex,tempvars) = createEquation(index, vindex, syst, shared, helpVarInfo, linearSystem, skipDiscInAlgorithm,iuniqueEqIndex,itempvars);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo,uniqueEqIndex,tempvars);
        equations = listAppend(equations1,equations);
        noDiscEquations = listAppend(equations1,noDiscEquations);
      then
        (equations,noDiscEquations,uniqueEqIndex,tempvars);
       
      // A single array equation
    case (_, _, _, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_, (comp as BackendDAE.SINGLEARRAY(eqn=index)) :: restComps, _, _,_)
      equation
        (eqnlst,varlst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, transformXToXd);
        (equations1,noDiscEquations1,uniqueEqIndex,tempvars) = createSingleArrayEqnCode(genDiscrete,eqnlst,varlst,helpVarInfo,iuniqueEqIndex,itempvars);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo, uniqueEqIndex,tempvars);
        equations = listAppend(equations1,equations);
        noDiscEquations = listAppend(noDiscEquations1,noDiscEquations);
      then
        (equations,noDiscEquations,uniqueEqIndex,tempvars);
        
        // A single algorithm section for several variables.
    case (_, _, _, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_, (comp as BackendDAE.SINGLEALGORITHM(eqn=index)) :: restComps, _, _,_)
      equation
        (eqnlst,varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        varlst = List.map(varlst, transformXToXd);
        (equations1,uniqueEqIndex) = createSingleAlgorithmCode(eqnlst,varlst,skipDiscInAlgorithm,iuniqueEqIndex);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo, uniqueEqIndex,itempvars);
        equations = listAppend(equations1,equations);
        noDiscEquations = listAppend(equations1,noDiscEquations);
      then
        (equations,noDiscEquations,uniqueEqIndex,tempvars);      
       
      // A single complex equation
    case (_, _, _, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_, (comp as BackendDAE.SINGLECOMPLEXEQUATION(eqn=index)) :: restComps, _, _,_)
      equation
        (eqnlst,varlst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, transformXToXd);
        (equations1,uniqueEqIndex,tempvars) = createSingleComplexEqnCode(listGet(eqnlst,1),varlst,helpVarInfo,iuniqueEqIndex,itempvars);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo,uniqueEqIndex,tempvars);
        equations = listAppend(equations1,equations);
        noDiscEquations = listAppend(equations1,noDiscEquations);
      then
        (equations,noDiscEquations,uniqueEqIndex,tempvars);
                 
        // a system of equations 
    case (_, _, _, _, _, _, _, comp :: restComps, _,_,_)
      equation
        (equations_,noDiscEquations1,uniqueEqIndex,tempvars) = createOdeSystem(genDiscrete,  skipDiscInAlgorithm, linearSystem, syst, shared, comp, helpVarInfo,iuniqueEqIndex,itempvars);
        (equations,noDiscEquations,uniqueEqIndex,tempvars) = createEquations(includeWhen, skipDiscInZc, genDiscrete,  skipDiscInAlgorithm, linearSystem, syst, shared, restComps, helpVarInfo,uniqueEqIndex,tempvars);
        equations1 = listAppend(equations_,equations);
        noDiscEquations = listAppend(noDiscEquations1,noDiscEquations);  
      then
        (equations1,noDiscEquations,uniqueEqIndex,tempvars);
       
    // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createEquations failed"});
      then
        fail();
  end matchcontinue;
end createEquations;

protected function addAssertEqn
  input list<DAE.Statement> asserts;
  input list<SimCode.SimEqSystem> iequations;
  input Integer iuniqueEqIndex;
  output list<SimCode.SimEqSystem> oequations;
  output Integer ouniqueEqIndex;
algorithm
  (oequations,ouniqueEqIndex) := match(asserts,iequations,iuniqueEqIndex)
    case({},_,_) then (iequations,iuniqueEqIndex);
    else
     then
       (SimCode.SES_ALGORITHM(iuniqueEqIndex,asserts)::iequations,iuniqueEqIndex+1);
  end match;
end addAssertEqn;

protected function createEquation
  input Integer eqNum;
  input Integer varNum;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Boolean linearSystem "if true generate allway a linear system";
  input Boolean skipDiscInAlgorithm;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equation_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equation_,ouniqueEqIndex,otempvars) := matchcontinue (eqNum, varNum, syst, shared, helpVarInfo, linearSystem, skipDiscInAlgorithm,iuniqueEqIndex,itempvars)
    local
      Expression.ComponentRef cr, cr_1;
      BackendDAE.VarKind kind;
      Option< .DAE.VariableAttributes> values;
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn;
      Integer    uniqueEqIndex;
      list<DAE.Statement> algStatements;
      list<DAE.Exp> conditions;
      list<SimCode.SimEqSystem> resEqs;
      list<BackendDAE.WhenClause> wcl;
      DAE.ComponentRef left,varOutput;
      DAE.Exp e1,e2,varexp,exp_,right,cond;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
      BackendDAE.WhenEquation whenEquation,elseWhen;
      String algStr,message,eqStr;
      DAE.ElementSource source;
      list<DAE.Statement> asserts;
      SimCode.SimEqSystem elseWhenEquation;
      BackendVarTransform.VariableReplacements repl;
      DAE.Algorithm alg;
      list<SimCode.SimVar> tempvars;
      // solve always a linear equations 
    case (_, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_,
        _, true, _,_,_)
      equation
        BackendDAE.EQUATION(e1, e2, source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.VAR(varName = cr, varKind = kind) = BackendVariable.getVarAt(vars,varNum);
        varexp = Expression.crefExp(cr);
        (exp_,asserts) = ExpressionSolve.solveLin(e1, e2, varexp);
        source = DAEUtil.addSymbolicTransformationSolve(true, source, cr, e1, e2, exp_, asserts);
        (resEqs,uniqueEqIndex) = addAssertEqn(asserts,{SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,cr, exp_, source)},iuniqueEqIndex+1);
      then
        (resEqs,uniqueEqIndex,itempvars);
        
        // non-state non-linear
    case (_, _, BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,
        _, true, _,_,_)
      equation
        (eqn as BackendDAE.EQUATION(e1, e2, source)) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        (v as BackendDAE.VAR(varName = cr, varKind = kind)) = BackendVariable.getVarAt(vars,varNum);
        varexp = Expression.crefExp(cr);
        failure((_,_) = solve(e1, e2, varexp));
        eqStr = BackendDump.equationStr(eqn);
        message = ComponentReference.printComponentRefStr(cr);
        Error.addMessage(Error.WARNING_JACOBIAN_EQUATION_SOLVE,{eqStr,message,message});
      then
        ({SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,cr, DAE.RCONST(0.0) , source)},iuniqueEqIndex+1,itempvars);  
              
        // when eq without else
    case (_, _,
        BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(whenClauseLst=wcl)),
        _, false, _,_,_)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation=whenEquation,source=source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.WHEN_EQ(cond, left, right, NONE()) = whenEquation;
        conditions = getConditionList(cond);
        conditionsWithHindex =  List.map2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        ({SimCode.SES_WHEN(iuniqueEqIndex,left,right,conditionsWithHindex,NONE(),source)},iuniqueEqIndex+1,itempvars);
        
        // when eq with else
    case (_, _,
        BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(whenClauseLst=wcl)),
        _, false, _,_,_)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation=whenEquation,source=source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.WHEN_EQ(cond, left, right, SOME(elseWhen)) = whenEquation;
        elseWhenEquation = createElseWhenEquation(elseWhen,wcl,helpVarInfo,source);
        conditions = getConditionList(cond);
        conditionsWithHindex =  List.map2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        ({SimCode.SES_WHEN(iuniqueEqIndex,left,right,conditionsWithHindex,SOME(elseWhenEquation),source)},iuniqueEqIndex+1,itempvars);
        
        // single equation: non-state
    case (_, _,
        BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_,
        _, false, _,_,_)
      equation
        BackendDAE.EQUATION(e1, e2, source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        (v as BackendDAE.VAR(varName = cr, varKind = kind, values=values)) = BackendVariable.getVarAt(vars,varNum);
        true = BackendVariable.isNonStateVar(v);
        varexp = Expression.crefExp(cr);
        (exp_,asserts) = solve(e1, e2, varexp);
        source = DAEUtil.addSymbolicTransformationSolve(true, source, cr, e1, e2, exp_, asserts);
        (resEqs,uniqueEqIndex) = addAssertEqn(asserts,{SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,cr, exp_, source)},iuniqueEqIndex+1);
      then
        (resEqs,uniqueEqIndex,itempvars);
        
        // single equation: state
    case (_, _,
        BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),_,
        _, false, _,_,_)
      equation
        BackendDAE.EQUATION(e1, e2, source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.VAR(varName = cr, varKind = BackendDAE.STATE(), values=values) = BackendVariable.getVarAt(vars,varNum);        
        cr = ComponentReference.crefPrefixDer(cr);
        (exp_,asserts) = solve(e1, e2, Expression.crefExp(cr));
        source = DAEUtil.addSymbolicTransformationSolve(true, source, cr, e1, e2, exp_, asserts);
        (resEqs,uniqueEqIndex) = addAssertEqn(asserts,{SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,cr, exp_, source)},iuniqueEqIndex+1);
      then
        (resEqs,uniqueEqIndex,itempvars);
        
        // non-state non-linear
    case (_, _,
        BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,
        _, false, _,_,_)
      equation
        (eqn as BackendDAE.EQUATION(e1, e2, source)) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        (v as BackendDAE.VAR(varName = cr, varKind = kind)) = BackendVariable.getVarAt(vars,varNum);
        true = BackendVariable.isNonStateVar(v);
        varexp = Expression.crefExp(cr);
        failure((_,_) = solve(e1, e2, varexp));
        //index = System.tmpTick();
        (resEqs,uniqueEqIndex,tempvars) = createNonlinearResidualEquations({eqn},iuniqueEqIndex,itempvars);
      then
        ({SimCode.SES_NONLINEAR(uniqueEqIndex, resEqs, {cr},0)},uniqueEqIndex+1,tempvars);
        
        // state nonlinear
    case (_, _,
        BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,
        _, false, _,_,_)
      equation
        (eqn as BackendDAE.EQUATION(e1, e2, source)) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        BackendDAE.VAR(varName = cr, varKind = BackendDAE.STATE()) = BackendVariable.getVarAt(vars,varNum); 
        cr_1 = ComponentReference.crefPrefixDer(cr);
        varexp = Expression.crefExp(cr_1);
        failure((_,_) = solve(e1, e2, varexp));
        //index = System.tmpTick();
        (resEqs,uniqueEqIndex,tempvars) = createNonlinearResidualEquations({eqn},iuniqueEqIndex,itempvars);
      then
        ({SimCode.SES_NONLINEAR(uniqueEqIndex, resEqs, {cr_1},0)},uniqueEqIndex+1,tempvars);
        
        // Algorithm for single variable.
    case (_, _, BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_, _, false, true,_,_)
      equation
        BackendDAE.ALGORITHM(alg=alg)  = BackendDAEUtil.equationNth(eqns, eqNum-1);
        varOutput::{} = CheckModel.algorithmOutputs(alg);
        v = BackendVariable.getVarAt(vars,varNum); 
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        true = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
        algStatements = BackendDAEUtil.removediscreteAssingments(algStatements, vars);
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex,algStatements)},iuniqueEqIndex+1,itempvars);
        
        // Algorithm for single variable.
    case (_, _, BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_, _, false, false,_,_)
      equation
        BackendDAE.ALGORITHM(alg=alg) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        varOutput::{} = CheckModel.algorithmOutputs(alg);
        v = BackendVariable.getVarAt(vars,varNum); 
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        true = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex,algStatements)},iuniqueEqIndex+1,itempvars);
        
        // inverse Algorithm for single variable.
    case (_, _, BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),_, _, false, _,_,_)
      equation
        BackendDAE.ALGORITHM(alg=alg,source=source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        varOutput::{} = CheckModel.algorithmOutputs(alg);
        v = BackendVariable.getVarAt(vars,varNum);
        // We need to solve an inverse problem of an algorithm section.
        false = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This has not been implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();
        // Algorithm for single variable.
    case (_, _, BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_, _, true, false,_,_)
      equation
        BackendDAE.ALGORITHM(alg=alg,source=source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        varOutput::{} = CheckModel.algorithmOutputs(alg);
        v = BackendVariable.getVarAt(vars,varNum);
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        true = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex,algStatements)},iuniqueEqIndex+1,itempvars);
        
        // inverse Algorithm for single variable.
    case (_, _, BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),_, _, true, _,_,_)
      equation
        BackendDAE.ALGORITHM(alg=alg,source=source) = BackendDAEUtil.equationNth(eqns, eqNum-1);
        varOutput::{} = CheckModel.algorithmOutputs(alg);
        v = BackendVariable.getVarAt(vars,varNum);
        // We need to solve an inverse problem of an algorithm section.
        false = ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v),varOutput);
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This has not been implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();
  end matchcontinue;
end createEquation;

protected function createElseWhenEquation
  input BackendDAE.WhenEquation elseWhen;
  input list<BackendDAE.WhenClause> wcl;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input DAE.ElementSource source;
  output SimCode.SimEqSystem equation_;
algorithm
  equation_ :=
  match (elseWhen, wcl, helpVarInfo, source)
    local
      DAE.ComponentRef left;
      DAE.Exp  right,cond;
      BackendDAE.WhenEquation elseWhenEquation;
      SimCode.SimEqSystem simElseWhenEq;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
      list<DAE.Exp> conditions;
      // when eq without else
    case (BackendDAE.WHEN_EQ(condition=cond, left=left, right=right, elsewhenPart= NONE()), _, _, _)
      equation
        conditions = getConditionList(cond);
        conditionsWithHindex = List.map2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        SimCode.SES_WHEN(0,left, right, conditionsWithHindex, NONE(), source);
        
        // when eq with else
    case (BackendDAE.WHEN_EQ(condition=cond, left=left,right=right, elsewhenPart = SOME(elseWhenEquation)), _, _, _)
      equation
        simElseWhenEq = createElseWhenEquation(elseWhenEquation,wcl,helpVarInfo,source);
        conditions = getConditionList(cond);
        conditionsWithHindex = List.map2(conditions, addHelpForCondition, helpVarInfo, helpVarInfo);
      then
        SimCode.SES_WHEN(0,left,right,conditionsWithHindex,SOME(simElseWhenEq),source);
  end match;
end createElseWhenEquation;

protected function createSampleEquations
" function: createSampleEquations
author: wbraun
Create SimCodeEqns from Backend Equation list.
used for create Sample equations."
  input list<BackendDAE.Equation> inEqns;
  input Integer iIndex;
  input list<SimCode.SimEqSystem> iSamEqns;
  output Integer oIndex;
  output list<SimCode.SimEqSystem> oSamEqns;
algorithm
  (oIndex,oSamEqns) := matchcontinue (inEqns,iIndex,iSamEqns)
    local
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqns;
      list<SimCode.SimEqSystem> simeqns;
      String eqstr;
      DAE.Exp e2;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      Integer index;
    case ({},_,_) then (iIndex,listReverse(iSamEqns));
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr, exp = e2, source = source)::eqns,_,_)
      equation
        (index,simeqns) = createSampleEquations(eqns,iIndex+1,SimCode.SES_SIMPLE_ASSIGN(iIndex,cr, e2, source)::iSamEqns);
      then
        (index,simeqns);
    case(BackendDAE.EQUATION(exp = DAE.CREF(componentRef = cr), scalar = e2, source = source)::eqns,_,_)
      equation
        (index,simeqns) = createSampleEquations(eqns,iIndex+1,SimCode.SES_SIMPLE_ASSIGN(iIndex,cr, e2, source)::iSamEqns);
      then
        (index,simeqns);        
    case (eq::eqns,_,_)
      equation
        eqstr = BackendDump.equationStr(eq);
        Error.addCompilerWarning("sample call in equation: " +& eqstr +& "not supported, yet!");
        (index,simeqns) = createSampleEquations(eqns,iIndex,iSamEqns);
      then
        (index,simeqns);
  end matchcontinue;
end createSampleEquations;

protected function addHindexForCondition
  input DAE.Exp condition;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  output tuple<DAE.Exp, Integer> conditionAndHindex;
algorithm
  conditionAndHindex :=
  matchcontinue (condition, helpVarInfo)
    local
      Integer hindex;
      DAE.Exp e;
      list<SimCode.HelpVarInfo> restHelpVarInfo;
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
  input DAE.Exp icondition;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input list<SimCode.HelpVarInfo> helpVarInfo1;
  output tuple<DAE.Exp, Integer> conditionAndHindex;
algorithm
  conditionAndHindex :=
  matchcontinue (icondition, helpVarInfo, helpVarInfo1)
    local
      Integer hindex;
      DAE.Exp e;
      list<SimCode.HelpVarInfo> restHelpVarInfo;
      Absyn.Path name;
      list<DAE.Exp> args_;
      DAE.Exp condition1;
      DAE.CallAttributes attr;
      DAE.Exp condition;
      
    case (_, {},_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Could not find help var index for condition"});
      then fail();
    case (condition as DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr), (hindex, e, _) :: restHelpVarInfo, _)
      equation
        args_ = listAppend(args_,{DAE.ICONST(hindex)});
        condition1 = DAE.CALL(name, args_, attr);
        true = Expression.expEqual(condition1, e);
        //s1 = ExpressionDump.printExpStr(condition1);
        //s2 = ExpressionDump.printExpStr(e);
        //print("Added Hindex for \n ** Condition: " +& s1 +& "  HelpVar exp: " +& s2 +& " with index : " +& intString(hindex) +&  "\n");
      then ((condition1, hindex));
    case (condition, (hindex, e, _) :: restHelpVarInfo, _)
      equation
        ((condition,_)) = Expression.traverseExp(condition, addHForSample, helpVarInfo1);
        true = Expression.expEqual(condition, e);
        //s1 = ExpressionDump.printExpStr(condition);
        //s2 = ExpressionDump.printExpStr(e);
        //print("Added Hindex for \n ** Condition: " +& s1 +& "  HelpVar exp: " +& s2 +& " with index : " +& intString(hindex) +& "\n");
      then ((condition, hindex));
    case (condition, (hindex, e, _) :: restHelpVarInfo, _)
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
    input tuple<DAE.Exp, list<SimCode.HelpVarInfo>> inTplExp;
    output tuple<DAE.Exp, list<SimCode.HelpVarInfo>> outTplExp;
algorithm 
 outTplExp := matchcontinue(inTplExp)
   local
   DAE.Exp condition;
   list<SimCode.HelpVarInfo> helpvars;
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
    input list<SimCode.HelpVarInfo> inHelpVars;
    output DAE.Exp outCondition;
algorithm 
 outCondition := matchcontinue(inCondition,inHelpVars)
   local
   DAE.Exp condition,condition1;
   Integer hindex;
   DAE.Exp e;
   list<SimCode.HelpVarInfo> restHelpVarInfo;
   Absyn.Path name;
   list<DAE.Exp> args_;
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

protected function createNonlinearResidualEquationsComplex
  input DAE.Exp inExp;
  input DAE.Exp inExp1;
  input DAE.ElementSource source;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equations_,ouniqueEqIndex,otempvars) := matchcontinue (inExp,inExp1,source,iuniqueEqIndex,itempvars)
    local
      DAE.ComponentRef cr,crtmp;
      DAE.Exp e1,e2,e1_1,e2_1,etmp;
      DAE.Statement stms;
      DAE.Type tp;
      list<DAE.Var> varLst;
      list<DAE.Exp> e1lst,e2lst;
      SimCode.SimEqSystem simeqn;
      list<SimCode.SimEqSystem> eqSystlst,eqSystlst1;
      list<tuple<DAE.Exp,DAE.Exp>> exptl,exptl1;
      list<DAE.ComponentRef> crefs;
      Integer uniqueEqIndex;
      Absyn.Path path,rpath;
      String ident;
      list<SimCode.SimVar> tempvars;
    /* a = f() */ 
    case (e1 as DAE.CREF(componentRef = cr),e2,_,_,_)
      equation
        //((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        (tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(path)))  = Expression.typeof(e1);
        // tmp
        ident = System.stringReplace(Absyn.pathString(path),".","_");
        crtmp = ComponentReference.makeCrefIdent("$TMP_" +& ident +& intString(iuniqueEqIndex), tp, {});
        tempvars = greateTempVars(varLst,crtmp,itempvars);
        // 0 = a - tmp        
        e1lst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        e2lst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,crtmp);
        exptl = List.threadTuple(e1lst,e2lst);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(exptl,makeSES_RESIDUAL1,source,iuniqueEqIndex);       
        // tmp = f(x,y)
        etmp = Expression.crefExp(crtmp);
        stms = DAE.STMT_ASSIGN(tp,etmp,e2_1,source);
        eqSystlst = SimCode.SES_ALGORITHM(uniqueEqIndex,{stms})::eqSystlst;
      then
         (eqSystlst,uniqueEqIndex+1,tempvars);
    /* f() = a */    
    case (e1,(e2 as DAE.CREF(componentRef = cr)),_,_,_)
      equation
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        //((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        (tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(path)))  = Expression.typeof(e2);
        // tmp
        ident = System.stringReplace(Absyn.pathString(path),".","_");
        crtmp = ComponentReference.makeCrefIdent("$TMP_" +& ident +& intString(iuniqueEqIndex), tp, {});
        tempvars = greateTempVars(varLst,crtmp,itempvars);
        // 0 = a - tmp        
        e1lst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        e2lst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,crtmp);
        exptl = List.threadTuple(e1lst,e2lst);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(exptl,makeSES_RESIDUAL1,source,iuniqueEqIndex);       
        // tmp = f(x,y)
        etmp = Expression.crefExp(crtmp);
        stms = DAE.STMT_ASSIGN(tp,etmp,e1_1,source);
        eqSystlst = SimCode.SES_ALGORITHM(uniqueEqIndex,{stms})::eqSystlst;
      then
         (eqSystlst,uniqueEqIndex+1,tempvars);        
    /* Record() = f() */  
    case (e1 as DAE.CALL(path=path,expLst=e2lst,attr=DAE.CALL_ATTR(ty= tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(rpath)))),e2,_,_,_)
      equation
        true = Absyn.pathEqual(path, rpath);
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        // tmp = f() 
        ident = System.stringReplace(Absyn.pathString(path),".","_");
        cr = ComponentReference.makeCrefIdent("$TMP_" +& ident +& intString(iuniqueEqIndex), tp, {});
        e1_1 = Expression.crefExp(cr);
        stms = DAE.STMT_ASSIGN(tp,e1_1,e2_1,source);
        simeqn = SimCode.SES_ALGORITHM(iuniqueEqIndex,{stms});
        uniqueEqIndex = iuniqueEqIndex + 1;
        // Record()-tmp = 0
        e1lst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        exptl = List.threadTuple(e1lst,e2lst);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(exptl,makeSES_RESIDUAL1,source,uniqueEqIndex);
        eqSystlst = simeqn::eqSystlst;
        tempvars = greateTempVars(varLst,cr,itempvars);
      then
         (eqSystlst,uniqueEqIndex,tempvars);   
    /* Record() = f() */  
    case (e1,e2 as DAE.CALL(path=path,expLst=e2lst,attr=DAE.CALL_ATTR(ty= tp as DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(rpath)))),_,_,_)
      equation
        true = Absyn.pathEqual(path, rpath);
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        // tmp = f() 
        ident = System.stringReplace(Absyn.pathString(path),".","_");
        cr = ComponentReference.makeCrefIdent("$TMP_" +& ident +& intString(iuniqueEqIndex), tp, {});
        e2_1 = Expression.crefExp(cr);
        stms = DAE.STMT_ASSIGN(tp,e2_1,e1_1,source);
        simeqn = SimCode.SES_ALGORITHM(iuniqueEqIndex,{stms});
        uniqueEqIndex = iuniqueEqIndex + 1;
        // Record()-tmp = 0
        e1lst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr);
        exptl = List.threadTuple(e1lst,e2lst);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(exptl,makeSES_RESIDUAL1,source,uniqueEqIndex);
        eqSystlst = simeqn::eqSystlst;
        tempvars = greateTempVars(varLst,cr,itempvars);
      then
         (eqSystlst,uniqueEqIndex,tempvars);              
        // failure
    case (e1,e2,_,_,_)
      /*
       equation
       s1 = ExpressionDump.printExpStr(e1);
       s2 = ExpressionDump.printExpStr(e2);
       s3 = ComponentReference.crefStr(cr);
       s = stringAppendList({"SimCode.createSingleComplexEqnCode2 failed for: ", s1, " = " , s2, " solve for ", s3 });
       Error.addMessage(Error.INTERNAL_ERROR, {s});
       */        
    then
      fail();
  end matchcontinue;
end createNonlinearResidualEquationsComplex;

protected function greateArrayTempVar
  input DAE.ComponentRef name;
  input list<Integer> dims;
  input list<DAE.Exp> inTmpCrefsLst;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimVar> otempvars;
algorithm
  otempvars := match(name,dims,inTmpCrefsLst,itempvars)
    local
      list<DAE.Exp> rest;
      list<SimCode.SimVar> tempvars;
      DAE.Type ty;
      DAE.ComponentRef cr;
      SimCode.SimVar var;
      list<String> slst;
    case(_,_,{},_) then itempvars;

    case(_,_,DAE.CREF(cr, ty)::rest,_)
      equation
        slst = List.map(dims,intString);
        var = SimCode.SIMVAR(cr,BackendDAE.VARIABLE(),"","","",0,NONE(),NONE(),NONE(),NONE(),false,ty,false,SOME(name),SimCode.NOALIAS(),DAE.emptyElementSource,SimCode.NONECAUS(),NONE(),slst);
        tempvars = greateTempVarsforCrefs(rest,{var}); 
      then
        listAppend(listReverse(tempvars),itempvars);
  end match;
end greateArrayTempVar;

protected function greateTempVarsforCrefs
  input list<DAE.Exp> inTmpCrefsLst;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimVar> otempvars;
algorithm
  otempvars := match(inTmpCrefsLst,itempvars)
    local
      list<DAE.Exp> rest;
      list<SimCode.SimVar> tempvars;
      DAE.Type ty;
      DAE.ComponentRef cr;
      SimCode.SimVar var;
    case({},_) then itempvars;

    case(DAE.CREF(cr, ty)::rest,_)
      equation
        var = SimCode.SIMVAR(cr,BackendDAE.VARIABLE(),"","","",0,NONE(),NONE(),NONE(),NONE(),false,ty,false,NONE(),SimCode.NOALIAS(),DAE.emptyElementSource,SimCode.NONECAUS(),NONE(),{});
      then
        greateTempVarsforCrefs(rest,var::itempvars); 
  end match;
end greateTempVarsforCrefs;

protected function greateTempVars
  input list<DAE.Var> varLst;
  input DAE.ComponentRef inCrefPrefix;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimVar> otempvars;
algorithm
  otempvars := match(varLst,inCrefPrefix,itempvars)
    local
      list<DAE.Var> rest,varlst;
      list<SimCode.SimVar> tempvars;
      DAE.Ident name;
      DAE.Type ty;
      DAE.ComponentRef cr;
      SimCode.SimVar var;
    case({},_,_) then itempvars;
    case(DAE.TYPES_VAR(name=name,ty=ty as DAE.T_COMPLEX(varLst=varlst,complexClassType=ClassInf.RECORD(_)))::rest,_,_)
      equation
        cr = ComponentReference.crefPrependIdent(inCrefPrefix, name, {}, ty);
        tempvars = greateTempVars(rest,cr,itempvars); 
      then
        greateTempVars(rest,cr,tempvars);
    case(DAE.TYPES_VAR(name=name,ty=ty)::rest,_,_)
      equation
        cr = ComponentReference.crefPrependIdent(inCrefPrefix, name, {}, ty);
        var = SimCode.SIMVAR(cr,BackendDAE.VARIABLE(),"","","",0,NONE(),NONE(),NONE(),NONE(),false,ty,false,NONE(),SimCode.NOALIAS(),DAE.emptyElementSource,SimCode.NONECAUS(),NONE(),{});
      then
        greateTempVars(rest,inCrefPrefix,var::itempvars); 
  end match;
end greateTempVars;

protected function moveDivToMul
  input list<DAE.Exp> iExpLst;
  input list<DAE.Exp> iExpLstAcc;
  input list<DAE.Exp> iExpMuls;
  output list<DAE.Exp> oExpLst;
  output list<DAE.Exp> oExpMuls;
algorithm
  (oExpLst,oExpMuls) := match(iExpLst,iExpLstAcc,iExpMuls)
    local 
      DAE.Exp e,e1,e2,res;
      list<DAE.Exp> rest,acc,elst,elst1;
    case ({},_,_) then (iExpLstAcc,iExpMuls);
    // a/b 
    case (DAE.BINARY(exp1=e1,operator=DAE.DIV(ty=_),exp2=e2)::rest,_,_)
      equation
         acc = List.map1(iExpLstAcc,Expression.expMul,e2);
         rest = List.map1(rest,Expression.expMul,e2);
         rest = ExpressionSimplify.simplifyList(rest,{});
        (elst,elst1) = moveDivToMul(rest,e1::acc,e2::iExpMuls);
      then
        (elst,elst1);
    case (DAE.BINARY(exp1=e1,operator=DAE.DIV_ARRAY_SCALAR(ty=_),exp2=e2)::rest,_,_)
      equation
         acc = List.map1(iExpLstAcc,Expression.expMul,e2);
         rest = List.map1(rest,Expression.expMul,e2);
         rest = ExpressionSimplify.simplifyList(rest,{});
        (elst,elst1) = moveDivToMul(rest,e1::acc,e2::iExpMuls);
      then
        (elst,elst1);
    case (e::rest,_,_)
      equation
        (elst,elst1) = moveDivToMul(rest,e::iExpLstAcc,iExpMuls);
      then
        (elst,elst1);
  end match;
end moveDivToMul;

protected function createNonlinearResidualExp
"function createNonlinearResidualExp
  autor Frenkel TUD 2012-10
  do some numerical helpfull thinks like
  a = b/c - > a*c-b"
  input DAE.Exp iExp1;
  input DAE.Exp iExp2;
  output DAE.Exp resExp;
algorithm
  resExp := matchcontinue(iExp1,iExp2)
    local
      DAE.Exp e,e1,e2,res;
      list<DAE.Exp> explst,explst1,mexplst;
      DAE.Type ty;
    case(_,_)
      equation
        true = Expression.isZero(iExp1);
      then
        iExp2;
    case(_,_)
      equation
        true = Expression.isZero(iExp2);
      then
        iExp1;
    case(_,_)
      equation
        ty = Expression.typeof(iExp1);
        true = Types.isIntegerOrRealOrSubTypeOfEither(ty);
        // get terms        
        explst = Expression.terms(iExp1);
        explst1 = Expression.terms(iExp2);
        // get all divisors and multiply them to the other terms
        (explst,mexplst) = moveDivToMul(explst,{},{});
        e = Expression.makeProductLst(mexplst);
        (e,_) = ExpressionSimplify.simplify(e);
        explst1 = List.map1(explst1,Expression.expMul,e);
        explst1 = ExpressionSimplify.simplifyList(explst1,{});
        (explst1,mexplst) = moveDivToMul(explst1,{},{});
        e = Expression.makeProductLst(mexplst);
        (e,_) = ExpressionSimplify.simplify(e);
        explst = List.map1(explst,Expression.expMul,e);
        explst1 = List.map(explst1,Expression.negate);
        explst = listAppend(explst,explst1);
        res = Expression.makeSum(explst);
        (res,_) = ExpressionSimplify.simplify(res);
      then 
        res;
    case(_,_)
      equation
        ty = Expression.typeof(iExp1);
        true = Types.isBooleanOrSubTypeBoolean(ty);
        res = DAE.LUNARY(DAE.NOT(ty),DAE.RELATION(iExp1,DAE.EQUAL(ty),iExp2,-1,NONE()));
      then
        res;
    case(_,_)
      equation
        ty = Expression.typeof(iExp1);
        true = Types.isStringOrSubTypeString(ty);
        res = DAE.LUNARY(DAE.NOT(ty),DAE.RELATION(iExp1,DAE.EQUAL(ty),iExp2,-1,NONE()));
      then
        res;
    else
      equation
        res = Expression.expSub(iExp1,iExp2);
       (res,_) = ExpressionSimplify.simplify(res);
      then 
        res;
  end matchcontinue;
end createNonlinearResidualExp;

protected function createNonlinearResidualEquations
  input list<BackendDAE.Equation> eqs;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> eqSystems;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (eqSystems,ouniqueEqIndex,otempvars) :=
  matchcontinue (eqs,iuniqueEqIndex,itempvars)
    local
      Integer size,uniqueEqIndex;
      DAE.Exp res_exp,e1,e2,e;
      list<DAE.Exp> explst,explst1,e2lst;
      list<BackendDAE.Equation> rest;
      BackendDAE.Equation eq;
      list<SimCode.SimEqSystem> eqSystemsRest,eqSystlst;
      list<Integer> ds;
      list<Option<Integer>> ad;
      DAE.ComponentRef left;
      String eqstr;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
      list<tuple<DAE.Exp,DAE.Exp>> exptl,exptl1;
      list<DAE.ComponentRef> crefs, crefstmp;
      list<list<DAE.Subscript>> subslst;
      list<SimCode.SimVar> tempvars;
      BackendVarTransform.VariableReplacements repl;
      DAE.Type ty;
    case ({},_,_) then ({},iuniqueEqIndex,itempvars);
      
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source) :: rest,_,_)
      equation
        res_exp = createNonlinearResidualExp(e1,e2);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(rest,iuniqueEqIndex,itempvars);
      then
        (SimCode.SES_RESIDUAL(uniqueEqIndex,res_exp,source) :: eqSystemsRest,uniqueEqIndex+1,tempvars);
        
    case (BackendDAE.RESIDUAL_EQUATION(exp = e,source = source) :: rest,_,_)
      equation
        (res_exp,_) = ExpressionSimplify.simplify(e);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(rest,iuniqueEqIndex,itempvars);
      then
        (SimCode.SES_RESIDUAL(uniqueEqIndex,res_exp,source) :: eqSystemsRest,uniqueEqIndex+1,tempvars);
   
    // An array equation
    case (BackendDAE.ARRAY_EQUATION(dimSize=ds,left=e1, right=e2, source=source) :: rest,_,_)
      equation
        ty = Expression.typeof(e1);
        left = ComponentReference.makeCrefIdent("$TMP_" +& intString(iuniqueEqIndex), ty, {});
        res_exp = createNonlinearResidualExp(e1,e2);
        res_exp = replaceDerOpInExp(res_exp);
        crefstmp = ComponentReference.expandCref(left,false);
        explst1 = List.map(crefstmp,Expression.crefExp);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(explst1,makeSES_RESIDUAL,source,iuniqueEqIndex);
        eqSystlst = SimCode.SES_ARRAY_CALL_ASSIGN(uniqueEqIndex,left,res_exp,source)::eqSystlst;
        tempvars = greateArrayTempVar(left,ds,explst1,itempvars);
        (eqSystemsRest,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(rest,uniqueEqIndex+1,tempvars);
        eqSystemsRest = listAppend(eqSystlst,eqSystemsRest);                
      then 
        (eqSystemsRest,uniqueEqIndex+1,tempvars);     

        // An complex equation
    case (BackendDAE.COMPLEX_EQUATION(size=size,left=e1, right=e2, source=source) :: rest,_,_)
      equation
        (e1,_) = ExpressionSimplify.simplify(e1);
        e1 = replaceDerOpInExp(e1);
        (e2,_) = ExpressionSimplify.simplify(e2);
        e2 = replaceDerOpInExp(e2);
        (eqSystlst,uniqueEqIndex,tempvars) = createNonlinearResidualEquationsComplex(e1,e2,source,iuniqueEqIndex,itempvars);
        (eqSystemsRest,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(rest,uniqueEqIndex,tempvars);
        eqSystemsRest = listAppend(eqSystlst,eqSystemsRest);
      then 
        (eqSystemsRest,uniqueEqIndex,tempvars);        

        
    case ((eq as BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = left, right = e2)))::rest,_,_)
      equation
        // This following does not work. It does not take index or elseWhen into account.
        // The generated code for the when-equation also does not solve a linear system; it uses the variables directly.
        /*
         tp = Expression.typeof(e2);
         e1 = Expression.makeCrefExp(left,tp);
         res_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
         res_exp = ExpressionSimplify.simplify(res_exp);
         res_exp = replaceDerOpInExp(res_exp);
         (eqSystemsRest) = createNonlinearResidualEquations(rest,repl,uniqueEqIndex );
         then
         (SimCode.SES_RESIDUAL(0,res_exp) :: eqSystemsRest,entrylst1);
         */
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"non-linear equations within when-equations","Perform non-linear operations outside the when-equation (this is slower, but works)"},BackendEquation.equationInfo(eq));
      then
        fail();
   
    case ((BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(algStatements),source=source) :: rest),_,_)
      equation
        crefs = CheckModel.algorithmOutputs(DAE.ALGORITHM_STMTS(algStatements));
        //BackendDump.debugStrCrefLstStr(("Crefs : ", crefs, ",", "\n"));
        (crefstmp,repl) = createTmpCrefs(crefs, iuniqueEqIndex, {}, BackendVarTransform.emptyReplacements());
        //BackendDump.debugStrCrefLstStr(("Crefs : ", crefstmp, ",", "\n"));
        explst = List.map(crefs,Expression.crefExp);
        explst = List.map(explst,replaceDerOpInExp);
        
        //BackendDump.dumpAlgorithms({DAE.ALGORITHM_STMTS(algStatements)},0);
        (algStatements,_) = BackendVarTransform.replaceStatementLst(algStatements, repl, SOME(BackendVarTransform.skipPreOperator), {}, false);
        //BackendDump.dumpAlgorithms({DAE.ALGORITHM_STMTS(algStatements)},0);
        
        explst1 = List.map(crefstmp,Expression.crefExp);
        explst1 = List.map(explst1,replaceDerOpInExp);
        tempvars = greateTempVarsforCrefs(explst1,itempvars);
        
        // 0 = a - tmp        
        exptl = List.threadTuple(explst,explst1);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(exptl,makeSES_RESIDUAL1,source,iuniqueEqIndex);

        eqSystlst = SimCode.SES_ALGORITHM(uniqueEqIndex,algStatements)::eqSystlst;
        //Tpl.tplPrint(SimCodeDump.dumpEqs, eqSystlst);
        
        (eqSystemsRest,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(rest,uniqueEqIndex,tempvars);
        eqSystemsRest = listAppend(eqSystlst,eqSystemsRest);
      then
        (eqSystemsRest,uniqueEqIndex+1,tempvars);   
                
    case (eq::_,_,_)
      equation
        eqstr = BackendDump.equationStr(eq);
        eqstr = stringAppend("SimCode.createNonlinearResidualEquations failed for equation: ",eqstr);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {eqstr},BackendEquation.equationInfo(eq));
      then
        fail();
  end matchcontinue;
end createNonlinearResidualEquations;

public function dimsToAllIndexes
  input DAE.Dimensions inDims;
  output list<list<Integer>> outIndexes;
protected
  list<Integer> ilst;
  list<list<Integer>> lstlst;
algorithm
  ilst := Expression.dimensionsSizes(inDims);
  lstlst := List.map(ilst,List.intRange);
  outIndexes := dimsToAllIndexes1(lstlst);
end dimsToAllIndexes;

protected function dimsToAllIndexes1
  input list<list<Integer>> inDims;
  output list<list<Integer>> oAllIndex;
algorithm
  oAllIndex := match(inDims)
    local
      list<Integer> dims;
      list<list<Integer>> rest,indxes;
    case (dims::{})
      equation
        indxes = List.map(dims,List.create);
      then
        indxes;
    case (dims::rest)
      equation
        indxes = dimsToAllIndexes1(rest);
        // cons for each element in dims
        indxes = List.fold1(dims,dimsToAllIndexes2,indxes,{});
      then
        indxes;
  end match;
end dimsToAllIndexes1;

protected function dimsToAllIndexes2
  input Integer i;
  input list<list<Integer>> iIndex;
  input list<list<Integer>> iAllIndex;
  output list<list<Integer>> oAllIndex;
algorithm
  oAllIndex := List.map1(iIndex,List.consr,i);
  oAllIndex := listAppend(iAllIndex,oAllIndex);
end dimsToAllIndexes2;

protected function createTmpCrefs
  input list<DAE.ComponentRef> inCrefs;
  input Integer iuniqueEqIndex;
  input list<DAE.ComponentRef> inCrefsAcc;
  input BackendVarTransform.VariableReplacements iRepl;
  output list<DAE.ComponentRef> outCrefs;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (outCrefs,oRepl) := match(inCrefs, iuniqueEqIndex, inCrefsAcc, iRepl)
    local
      DAE.ComponentRef cref, crtmp;
      list<DAE.ComponentRef> rest, result;
      DAE.Type tp;
      String ident;
      BackendVarTransform.VariableReplacements repl;
    case({},_,_,_) then (listReverse(inCrefsAcc),iRepl);
    case(cref::rest,_,_,_) 
      equation
        ident = ComponentReference.printComponentRefStr(cref);
        ident = System.stringReplace(ident,".","$P");
        ident = System.stringReplace(ident,"[","$rB");
        ident = System.stringReplace(ident,"]","$lB");
        tp = ComponentReference.crefLastType(cref);
        crtmp = ComponentReference.makeCrefIdent("$TMP_" +& ident +& "_" +& intString(iuniqueEqIndex), tp, {});
        repl = BackendVarTransform.addReplacement(iRepl, cref, DAE.CREF(crtmp,tp), SOME(BackendVarTransform.skipPreOperator));
        (result,repl) = createTmpCrefs(rest, iuniqueEqIndex,crtmp::inCrefsAcc,repl);
      then 
        (result,repl);
  end match;
end createTmpCrefs;

protected function makeSES_RESIDUAL
  input DAE.Exp inExp;
  input DAE.ElementSource source;
  input Integer uniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer ouniqueEqIndex;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outSimEqn := SimCode.SES_RESIDUAL(uniqueEqIndex,inExp,source);
  ouniqueEqIndex := uniqueEqIndex+1;
end makeSES_RESIDUAL;

protected function makeSES_RESIDUAL1
  input tuple<DAE.Exp,DAE.Exp> inTpl;
  input DAE.ElementSource source;
  input Integer uniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer ouniqueEqIndex;
protected
  DAE.Exp e1,e2,e;
algorithm
  (e1,e2) := inTpl;
  e := createNonlinearResidualExp(e1,e2);
  outSimEqn := SimCode.SES_RESIDUAL(uniqueEqIndex,e,source);
  ouniqueEqIndex := uniqueEqIndex +1;
end makeSES_RESIDUAL1;

protected function makeSES_SIMPLE_ASSIGN
  input tuple<DAE.Exp,DAE.Exp> inTpl;
  input DAE.ElementSource source;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer ouniqueEqIndex;
protected
  DAE.Exp e;
  DAE.ComponentRef cr;
algorithm
  (DAE.CREF(cr,_),e) := inTpl;
  outSimEqn := SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,cr,e,source);
  ouniqueEqIndex := iuniqueEqIndex+1;
end makeSES_SIMPLE_ASSIGN;

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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponent inComp;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output list<SimCode.SimEqSystem> noDiscequations_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equations_,noDiscequations_,ouniqueEqIndex,otempvars) :=
  matchcontinue(genDiscrete, skipDiscInAlgorithm, linearSystem, isyst, ishared, inComp, helpVarInfo, iuniqueEqIndex,itempvars)
    local
      list<BackendDAE.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<BackendDAE.Var> var_lst,cont_var,disc_var,var_lst_1;
      BackendDAE.Variables vars_1,vars,knvars,exvars,ave;
      BackendDAE.EquationArray eqns_1,eqns,eeqns;
      BackendDAE.BackendDAE subsystem_dae;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo ev;
      list<Integer> ieqns,ivars,disc_eqns,disc_vars;
      BackendDAE.ExternalObjectClasses eoc;
      list<SimCode.SimVar> simVarsDisc;
      list<SimCode.SimEqSystem> discEqs;
      list<Integer> values,value_dims,comps_flat,rf,tf;
      SimCode.SimEqSystem equation_;
      BackendDAE.BackendDAE subsystem_dae_1,subsystem_dae_2;
      array<Integer> v1,v2,v1_1,v2_1;
      BackendDAE.IncidenceMatrix m_3,m;
      BackendDAE.IncidenceMatrixT mT_3,mt;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp,comp1;
      list<list<Integer>> r,t,comps_1;
      Integer index,uniqueEqIndex;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      String msg;
      list<SimCode.SimVar> tempvars;
      list<tuple<Integer,list<Integer>>> eqnvartpllst;
      Boolean b;
      // create always a linear system of equations 
    case (_,_,true,syst as BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),shared as BackendDAE.SHARED(knownVars = knvars, constraints = constrs, classAttrs = clsAttrs,functionTree=funcs),comp as BackendDAE.EQUATIONSYSTEM(eqns=ieqns,vars=ivars,jac=jac,jacType=jac_tp),_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem create system (create linear jacobian).");
        //print("\ncreateOdeSystem -> Linear: ...\n");
        //BackendDump.printEquations(block_,daelow);
        // extract the variables and equations of the block.
        eqn_lst = BackendEquation.getEqns(ieqns,eqns);
        var_lst = List.map1r(ivars, BackendVariable.getVarAt, vars);
        (jac,jac_tp) = updateJacobian(jac,jac_tp,var_lst,eqn_lst,ishared);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        // States are solved for der(x) not x.
        var_lst_1 = List.map(var_lst, transformXToXd);
        vars_1 = BackendDAEUtil.listVar1(var_lst_1);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        // if BackendDAEUtil.JAC_NONLINEAR() then set to time_varying
        jac_tp = changeJactype(jac_tp);
        (equations_,uniqueEqIndex,tempvars) = createOdeSystem2(false, skipDiscInAlgorithm, vars_1,knvars,eqns_1,constrs,clsAttrs,jac, jac_tp,helpVarInfo,funcs,iuniqueEqIndex,itempvars);
      then
        (equations_,equations_,uniqueEqIndex,tempvars);
    case (_,_,true,BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),BackendDAE.SHARED(knownVars = knvars, externalObjects = exvars, constraints = constrs, classAttrs=clsAttrs,cache=cache,env=env,functionTree=funcs, eventInfo = ev, extObjClasses = eoc),comp as BackendDAE.MIXEDEQUATIONSYSTEM(disc_eqns=disc_eqns,disc_vars=disc_vars),_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem create mixed system (create linear jacobian).");
        //print("\ncreateOdeSystem -> Linear: ...\n");
        //BackendDump.printEquations(block_,daelow);
        // extract the variables and equations of the block.
        (eqn_lst,var_lst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        var_lst_1 = List.map(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = BackendDAEUtil.listVar1(var_lst_1);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (m,mt) = BackendDAEUtil.incidenceMatrix(syst, BackendDAE.ABSOLUTE());
        jac = BackendDAEUtil.calculateJacobian(vars_1, eqns_1, m, false,ishared) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = BackendDAEUtil.analyzeJacobian(vars_1,eqns_1,jac);
        // if BackendDAEUtil.JAC_NONLINEAR() then set to time_varying
        jac_tp = changeJactype(jac_tp);
        (equations_,uniqueEqIndex,tempvars) = createOdeSystem2(false, skipDiscInAlgorithm, vars_1,knvars,eqns_1,constrs,clsAttrs,jac, jac_tp, helpVarInfo,funcs,iuniqueEqIndex,itempvars);
      then
        (equations_,equations_,uniqueEqIndex,tempvars);
          
        // mixed system of equations, continuous part only
    case (false, _, false,syst,shared,BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1),_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem create mixed system continuous part.");
        (_,noDiscequations_,uniqueEqIndex,tempvars) = createEquations(true,false,false,skipDiscInAlgorithm,false,syst,shared,{comp1},helpVarInfo,iuniqueEqIndex,itempvars);
      then
        ({},noDiscequations_,uniqueEqIndex,tempvars);
        
        // mixed system of equations, both continous and discrete eqns
    case (true, _, false,syst as BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),shared as BackendDAE.SHARED(knownVars=knvars),BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp1,disc_eqns=ieqns,disc_vars=ivars),_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem create mixed system.");
        //print("\ncreateOdeSystem -> Mixed: cont. and discrete\n");
        //BackendDump.printEquations(block_,dlow);
        disc_eqn = BackendEquation.getEqns(ieqns,eqns); 
        disc_var = List.map1r(ivars, BackendVariable.getVarAt, vars);
        (_,{equation_},uniqueEqIndex,tempvars) = createEquations(true,false,false,skipDiscInAlgorithm,false,syst,shared,{comp1},helpVarInfo,iuniqueEqIndex,itempvars);
        simVarsDisc = List.map2(disc_var, dlowvarToSimvar,NONE(),knvars);
        discEqs = extractDiscEqs(disc_eqn, disc_var);
        //was madness        
      then
        ({SimCode.SES_MIXED(uniqueEqIndex, equation_, simVarsDisc, discEqs)},{equation_},uniqueEqIndex+1,tempvars);
        
        // continuous system of equations try tearing algorithm
    case (_, _, false,syst as BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),shared as BackendDAE.SHARED(knownVars = knvars, externalObjects = exvars, constraints = constrs,classAttrs=clsAttrs,cache=cache,env=env, eventInfo = ev, extObjClasses = eoc),comp,_,_,_)
      equation
        //print("\ncreateOdeSystem -> Tearing: ...\n");
        // check tearing
        true = Flags.isSet(Flags.TEARING);
        (eqn_lst,var_lst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        var_lst_1 = List.map(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = BackendDAEUtil.listVar1(var_lst_1);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        ave = BackendDAEUtil.emptyVars();
        eeqns = BackendDAEUtil.listEquation({});
        funcs = DAEUtil.avlTreeNew();
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(knvars,exvars,ave,eeqns,eeqns,constrs,clsAttrs,cache,env,funcs,ev,eoc,BackendDAE.ALGEQSYSTEM(),{});
        (m,mt) = BackendDAEUtil.incidenceMatrix(syst, BackendDAE.ABSOLUTE());
        syst = BackendDAE.EQSYSTEM(vars_1,eqns_1,SOME(m),SOME(mt),BackendDAE.NO_MATCHING());
        subsystem_dae = BackendDAE.DAE({syst},shared);
        (subsystem_dae_1 as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(v1,v2,comps))})) = BackendDAEUtil.transformBackendDAE(subsystem_dae,SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE(),NONE());
        (subsystem_dae_2 as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(m=SOME(m_3),mT=SOME(mT_3))}),v1_1,v2_1,comps_1,r,t) = BackendDAEOptimize.tearingSystem(subsystem_dae_1,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = List.flatten(comps_1);
        rf = List.flatten(r);
        tf = List.flatten(t);
        jac = BackendDAEUtil.calculateJacobian(vars_1, eqns_1, m_3, false,shared) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = BackendDAEUtil.analyzeJacobian(vars_1,eqns_1,jac);
        (equation_,uniqueEqIndex,tempvars) = generateTearingSystem(v1_1,v2_1,comps_flat,rf,tf,subsystem_dae_2, jac, jac_tp, helpVarInfo,iuniqueEqIndex,itempvars);
      then
        ({equation_},{equation_},uniqueEqIndex,tempvars);
        /* continuous system of equations */
    case (_, _, false,BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),BackendDAE.SHARED(knownVars = knvars, externalObjects = exvars, constraints = constrs,classAttrs=clsAttrs,functionTree=funcs, eventInfo = ev, extObjClasses = eoc),comp as BackendDAE.EQUATIONSYSTEM(jac=jac,jacType=jac_tp),_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem create continuous system.");
        //print("\ncreateOdeSystem -> Cont sys: ...\n");
        // extract the variables and equations of the block.
        (eqn_lst,var_lst,index) = BackendDAETransform.getEquationAndSolvedVar(comp,eqns,vars);
        //BackendDump.dumpEqns(eqn_lst);
        //BackendDump.dumpVars(var_lst);
        (jac,jac_tp) = updateJacobian(jac,jac_tp,var_lst,eqn_lst,ishared);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        // States are solved for der(x) not x.
        var_lst_1 = List.map(var_lst, transformXToXd);
        vars_1 = BackendDAEUtil.listVar1(var_lst_1);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        (equations_,uniqueEqIndex,tempvars) = createOdeSystem2(false, skipDiscInAlgorithm, vars_1,knvars,eqns_1,constrs,clsAttrs, jac, jac_tp, helpVarInfo,funcs,iuniqueEqIndex,itempvars);
      then
        (equations_,equations_,uniqueEqIndex,tempvars);
    case (_, _, false,BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqns),_,comp as BackendDAE.TORNSYSTEM(tearingvars=tf, residualequations=rf, otherEqnVarTpl=eqnvartpllst, linear=b),_,_,_)
      equation
        (equations_,uniqueEqIndex,tempvars) = createTornSystem(b, skipDiscInAlgorithm, tf,rf,eqnvartpllst, isyst, ishared, helpVarInfo,iuniqueEqIndex,itempvars);
      then
        (equations_,equations_,uniqueEqIndex,tempvars);        
    else
      equation
        msg = "createOdeSystem failed for " +& BackendDump.printComponent(inComp);
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end matchcontinue;
end createOdeSystem;

protected function updateJacobian
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inJacobian;
  input BackendDAE.JacobianType inJacobianType;
  input list<BackendDAE.Var> inVars;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.Shared ishared;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> oJacobian;
  output BackendDAE.JacobianType oJacobianType;
algorithm
  (oJacobian,oJacobianType) := match(inJacobian,inJacobianType,inVars,inEqns,ishared)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.EqSystem syst;
      BackendDAE.IncidenceMatrix m;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
    case (SOME(_),_,_,_,_) then (inJacobian,inJacobianType);
    case (NONE(),_,_,_,_)
      equation
        vars = BackendDAEUtil.listVar1(inVars);
        eqns = BackendDAEUtil.listEquation(inEqns);
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING());
        (m,_) = BackendDAEUtil.incidenceMatrix(syst, BackendDAE.ABSOLUTE());
        jac = BackendDAEUtil.calculateJacobian(vars, eqns, m, false,ishared) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = BackendDAEUtil.analyzeJacobian(vars,eqns,jac);
      then
        (jac,jac_tp);          
  end match;
end updateJacobian;

protected function createTornSystem
  input Boolean liniear; 
  input Boolean skipDiscInAlgorithm "if true skip discrete algorithm vars";
  input list<Integer> tearingVars;
  input list<Integer> residualEqns;
  input list<tuple<Integer,list<Integer>>> otherEqns;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
   (equations_,ouniqueEqIndex,otempvars) := 
   matchcontinue(liniear,skipDiscInAlgorithm,tearingVars,residualEqns,otherEqns,isyst,ishared,helpVarInfo,iuniqueEqIndex,itempvars)
     local
       list<BackendDAE.Var> tvars;
       list<BackendDAE.Equation> reqns;
       BackendDAE.Variables vars;
       BackendDAE.EquationArray eqns;
       BackendVarTransform.VariableReplacements repl;
       list<SimCode.SimVar> tempvars;
       list<SimCode.SimEqSystem> simequations,resEqs,simequations1;
       Integer uniqueEqIndex;
       list<DAE.ComponentRef> tcrs,crefs;
       list<DAE.Exp> elst,ecrlst;
       list<tuple<DAE.Exp,DAE.Exp>> exptl; 
     // linear case
     /* TODO */
     // nonliniear case  
     case(_,_,_,_,_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns),_,_,_,_)
       equation
         //get tearing vars
         tvars = List.map1r(tearingVars, BackendVariable.getVarAt, vars);
         tvars = List.map(tvars, transformXToXd);
         // get residual eqns
         reqns = BackendEquation.getEqns(residualEqns, eqns);
         reqns = replaceDerOpInEquationList(reqns);
         // generate residual replacements
         tcrs = List.map(tvars,BackendVariable.varCref);
         // generate other equations
         (simequations,uniqueEqIndex,tempvars) = createTornSystemOtherEqns(otherEqns,skipDiscInAlgorithm,isyst,ishared,helpVarInfo,iuniqueEqIndex,itempvars,{});
        (resEqs,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(reqns,uniqueEqIndex,tempvars);
        simequations = listAppend(simequations,resEqs);
       then
         ({SimCode.SES_NONLINEAR(uniqueEqIndex, simequations, tcrs,0)},uniqueEqIndex+1,tempvars);
   end matchcontinue;
end createTornSystem;

protected function createTornSystemOtherEqns
  input list<tuple<Integer,list<Integer>>> otherEqns;
  input Boolean skipDiscInAlgorithm "if true skip discrete algorithm vars";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  input list<SimCode.SimEqSystem> isimequations;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
   (equations_,ouniqueEqIndex,otempvars) := 
   matchcontinue(otherEqns,skipDiscInAlgorithm,isyst,ishared,helpVarInfo,iuniqueEqIndex,itempvars,isimequations)
     local
       BackendDAE.EquationArray eqns;
       list<SimCode.SimVar> tempvars;
       list<SimCode.SimEqSystem> simequations;
       Integer uniqueEqIndex,eqnindx;
       BackendDAE.Equation eqn;
       list<Integer> vars;
       list<tuple<Integer,list<Integer>>> rest;
       BackendDAE.EqSystem syst;
       BackendDAE.StrongComponent comp;
     case({},_,_,_,_,_,_,_)
       then
         (isimequations,iuniqueEqIndex,itempvars);
     case((eqnindx,vars)::rest,_,BackendDAE.EQSYSTEM(orderedEqs=eqns),_,_,_,_,_)
       equation
         // get Eqn
         eqn = BackendDAEUtil.equationNth(eqns, eqnindx-1);
         // generate comp
         comp = createTornSystemOtherEqns1(eqn,eqnindx,vars);
         (simequations,_,uniqueEqIndex,tempvars) = createEquations(false, false, true, skipDiscInAlgorithm, false, isyst, ishared, {comp}, helpVarInfo, iuniqueEqIndex, itempvars);
         simequations = listAppend(isimequations,simequations);
         // generade other equations
         (simequations,uniqueEqIndex,tempvars) = createTornSystemOtherEqns(rest,skipDiscInAlgorithm,isyst,ishared,helpVarInfo,uniqueEqIndex,tempvars,simequations);
       then
         (simequations,uniqueEqIndex,tempvars);
   end matchcontinue;
end createTornSystemOtherEqns;

protected function createTornSystemOtherEqns1
  input BackendDAE.Equation eqn;
  input Integer eqnindx;
  input list<Integer> varindx;
  output BackendDAE.StrongComponent ocomp;
algorithm
  ocomp := match(eqn,eqnindx,varindx)
    local
      Integer v;
    case (BackendDAE.EQUATION(exp=_),_,v::{})
      then
        BackendDAE.SINGLEEQUATION(eqnindx,v);
    case (BackendDAE.RESIDUAL_EQUATION(exp=_),_,v::{})
      then
        BackendDAE.SINGLEEQUATION(eqnindx,v);
    case (BackendDAE.SOLVED_EQUATION(source=_),_,v::{})
      then
        BackendDAE.SINGLEEQUATION(eqnindx,v);
    case (BackendDAE.ARRAY_EQUATION(dimSize=_),_,_)
      then
        BackendDAE.SINGLEARRAY(eqnindx, varindx);
    case (BackendDAE.ALGORITHM(size=_),_,_)
      then
        BackendDAE.SINGLEALGORITHM(eqnindx, varindx);
    case (BackendDAE.COMPLEX_EQUATION(size=_),_,_)
      then
        BackendDAE.SINGLECOMPLEXEQUATION(eqnindx, varindx);
    else
      equation
        print("SimCodeUtil.createTornSystemOtherEqns1 failed for\n");
        BackendDump.dumpEqns({eqn});
        print("Eqn: " +& intString(eqnindx) +& " Vars: " +& stringDelimitList(List.map(varindx,intString),", ") +& "\n");
      then
        fail();
  end match;
end createTornSystemOtherEqns1;

protected function generateTearingSystem "function: generateTearingSystem
  author: Frenkel TUD

  Generates the actual simulation code for the teared system of equation
"
  input array<Integer> ass1;
  input array<Integer> ass2;
  input list<Integer> inIntegerLst4;
  input list<Integer> inIntegerLst5;
  input list<Integer> inIntegerLst6;
  input BackendDAE.BackendDAE inBackendDAE;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerBackendDAEEquationLstOption;
  input BackendDAE.JacobianType inJacobianType;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output SimCode.SimEqSystem equation_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equation_,ouniqueEqIndex,otempvars):=
  matchcontinue (ass1,ass2,inIntegerLst4,inIntegerLst5,inIntegerLst6,inBackendDAE,inTplIntegerIntegerBackendDAEEquationLstOption,inJacobianType,helpVarInfo,iuniqueEqIndex,itempvars)
    local
      list<Integer> block_,block_1,r,t;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      BackendDAE.Variables v;
      BackendDAE.EquationArray eqn,eqn1;
      list<BackendDAE.Equation> eqn_lst,eqn_lst1,eqn_lst2,reqns;
      list<DAE.ComponentRef> crefs,crefs1,tcrs;
      BackendVarTransform.VariableReplacements repl;
      list<SimCode.SimEqSystem> simeqnsystem,simeqnsystem1,resEqs;
      list<list<SimCode.SimEqSystem>> simeqnsystemlst;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      DAE.ComponentRef cr;
      BackendDAE.Equation eq;
      Integer uniqueEqIndex;
      list<SimCode.SimVar> tempvars;
    case (_,_,block_,r,t,BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=eqn)::{},
      shared=shared),jac,jac_tp,_,_,_)
      /* no analytic jacobian available. Generate non-linear system */
      equation
        // get equations and variables
        eqn_lst = BackendDAEUtil.equationList(eqn);
        // get names from variables
        crefs = BackendVariable.getAllCrefFromVariables(v);
        // get Tearingvar from crs
        // to use listNth cref and eqn_lst have to start at 1 and not at 0 -> right shift
        cr = ComponentReference.makeCrefIdent("shift",DAE.T_REAL_DEFAULT,{});
        crefs1 = listReverse(crefs);
        crefs1 = cr :: crefs1;
        eq = BackendDAE.EQUATION(DAE.RCONST(0.0),DAE.RCONST(0.0),DAE.emptyElementSource);
        eqn_lst1 = eq :: eqn_lst;
        tcrs = List.map1r(t,listNth,crefs1);
        // get residual eqns and other eqns
        reqns = List.map1r(r,listNth,eqn_lst1);
        // remove residual equation from list of other equtions
        block_1 = List.select1(block_,List.notMember,r);
        eqn1 = BackendDAEUtil.listEquation(eqn_lst);
        syst = BackendDAE.EQSYSTEM(v,eqn1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        // generade code for other equations
        (simeqnsystemlst,(uniqueEqIndex,tempvars)) = List.map1Fold(block_1,generateTearingOtherEqns,(syst,shared,ass2,helpVarInfo),(iuniqueEqIndex,itempvars));
        simeqnsystem = List.flatten(simeqnsystemlst);
        (resEqs,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(reqns,uniqueEqIndex,tempvars);
        simeqnsystem1 = listAppend(simeqnsystem,resEqs);
      then
        (SimCode.SES_NONLINEAR(uniqueEqIndex, simeqnsystem1, tcrs,0),uniqueEqIndex+1,tempvars);
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "-generateTearingSystem failed \n");
      then
        fail();
  end matchcontinue;
end generateTearingSystem;

protected function generateTearingOtherEqns
  input Integer inEq;
  input tuple<BackendDAE.EqSystem,BackendDAE.Shared,array<Integer>,list<SimCode.HelpVarInfo>> inTpl;
  input tuple<Integer,list<SimCode.SimVar>> iuniqueEqIndex;
  output list<SimCode.SimEqSystem> simeqnsystem;
  output tuple<Integer,list<SimCode.SimVar>> ouniqueEqIndex;
protected 
  Integer i,index; 
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
  array<Integer> inAss2;
  list<SimCode.HelpVarInfo> helpVarInfo;
  list<SimCode.SimVar> tempvars;   
algorithm
  (syst,shared,inAss2,helpVarInfo) := inTpl;
  i := inAss2[inEq];
  (index,tempvars) := iuniqueEqIndex;
  (simeqnsystem,index,tempvars) := createEquation(inEq, i, syst, shared, helpVarInfo, true, false,index,tempvars);
  ouniqueEqIndex := (index,tempvars);
end generateTearingOtherEqns;

protected function extractDiscEqs
  input list<BackendDAE.Equation> disc_eqn;
  input list<BackendDAE.Var> disc_var;
  output list<SimCode.SimEqSystem> discEqsOut;
algorithm
  discEqsOut :=
  match (disc_eqn, disc_var)
    local
      list<SimCode.SimEqSystem> restEqs;
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
        SimCode.SES_SIMPLE_ASSIGN(0,cr, expr, source) :: restEqs;
    // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.extractDiscEqs failed!"});
      then
        fail();
  end match;
end extractDiscEqs;

protected function extractValuesAndDims
  input list<BackendDAE.Var> disc_v;
  output list<Integer> valuesRet;
  output list<Integer> value_dims;
algorithm
  (valuesRet, value_dims) :=
  match (disc_v)
    local
      list<list<Integer>> values,values_1;      
    case (_)
      equation
        (values,value_dims) = generateMixedDiscretePossibleValues2(disc_v, 0);
        values_1 = generateMixedDiscreteCombinationValues(values);
        valuesRet = List.flatten(values_1);
      then
        (valuesRet, value_dims);
    // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.extractValuesAndDims failed!"});
      then
        fail();        
  end match;
end extractValuesAndDims;

protected function createOdeSystem2
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean skipDiscInAlgorithm;
  input BackendDAE.Variables inVars;  
  input BackendDAE.Variables inKnVars;  
  input BackendDAE.EquationArray inEquationArray;
  input array<DAE.Constraint> inConstrs;
  input array<DAE.ClassAttributes> inClassAttrs;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inJacobian;
  input BackendDAE.JacobianType inJacobianType;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input DAE.FunctionTree inFuncs;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equations_,ouniqueEqIndex,otempvars) :=
  matchcontinue
    (mixedEvent,skipDiscInAlgorithm,inVars,inKnVars,inEquationArray,inConstrs,inClassAttrs,inJacobian,inJacobianType,helpVarInfo,inFuncs,iuniqueEqIndex,itempvars)
    local
      Integer uniqueEqIndex;
      BackendDAE.BackendDAE subsystem_dae,subsystem_dae_1,subsystem_dae_2;
      BackendDAE.Variables v,kv,evars;
      BackendDAE.EquationArray eqn,eeqns;
      list<BackendDAE.Equation> eqn_lst;
      list<DAE.ComponentRef> crefs;
      Env.Cache cache;
      list<SimCode.SimEqSystem> resEqs;
      BackendDAE.StrongComponents comps;
      list<Integer> comps_flat;
      list<list<Integer>> r,t;
      list<Integer> rf,tf;
      list<SimCode.SimVar> simVars;
      list<DAE.Exp> beqs;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      Integer linInfo;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      list<list<Real>> jacVals;
      list<Real> rhsVals,solvedVals;
      BackendDAE.Variables ave;
      list<DAE.ElementSource> sources;
      list<DAE.ComponentRef> names;
      list<list<Integer>> comps_1;
      array<Integer> v1,v2,v1_1,v2_1;
      BackendVarTransform.VariableReplacements repl; 
      list<SimCode.SimVar> tempvars;
      String str;
        // constant jacobians. Linear system of equations (A x = b) where
        // A and b are constants. TODO: implement symbolic gaussian elimination
        // here. Currently uses dgesv as for next case
    case (_,_,v,kv,eqn,constrs,clsAttrs,SOME(jac),BackendDAE.JAC_CONSTANT(),_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem2 create linear system(const jacobian).");
        ((simVars,_)) = BackendVariable.traverseBackendDAEVars(v,traversingdlowvarToSimvar,({},kv));
        simVars = listReverse(simVars);
        ((_,beqs,sources,_)) = BackendEquation.traverseBackendDAEEqns(eqn,BackendEquation.equationToExp,(v,{},{},SOME(inFuncs)));
        beqs = listReverse(beqs);
        rhsVals = ValuesUtil.valueReals(List.map(beqs,Ceval.cevalSimple));
        jacVals = BackendDAEOptimize.evaluateConstantJacobian(listLength(simVars),jac);
        (solvedVals,linInfo) = System.dgesv(jacVals,rhsVals);
        names = List.map(simVars,varName);
        checkLinearSystem(linInfo,names,jacVals,rhsVals);
        // TODO: Move these to known vars :/ This is done in the wrong phase of the compiler... Also, if done as an optimization module, we can optimize more!
        sources = List.map1(sources, DAEUtil.addSymbolicTransformation, DAE.LINEAR_SOLVED(names,jacVals,rhsVals,solvedVals));
        (equations_,uniqueEqIndex) = List.thread3MapFold(simVars,solvedVals,sources,generateSolvedEquation,iuniqueEqIndex);
      then
        (equations_,uniqueEqIndex,itempvars);
        
        // constant jacobians. Linear system of equations (A x = b) where
        // A and b are constants. TODO: implement symbolic gaussian elimination
        // here. Currently uses dgesv as for next case
    case (_,_,v,kv,eqn,constrs,clsAttrs,SOME(jac),BackendDAE.JAC_TIME_VARYING(),_,_,_,_)
      equation
        // check Relaxation
        true = Flags.isSet(Flags.RELAXATION);
        ave = BackendDAEUtil.emptyVars();
        evars = BackendDAEUtil.emptyVars();
        eeqns = BackendDAEUtil.listEquation({});
        cache = Env.emptyCache();
        subsystem_dae = BackendDAE.DAE(BackendDAE.EQSYSTEM(v,eqn,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},BackendDAE.SHARED(evars,evars,ave,eeqns,eeqns,constrs,clsAttrs,cache,{},inFuncs,BackendDAE.EVENT_INFO({},{},{},{},0),{},BackendDAE.ALGEQSYSTEM(),{}));
        (subsystem_dae_1 as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(v1,v2,comps))})) = BackendDAEUtil.transformBackendDAE(subsystem_dae,SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT())),NONE(),NONE());
        (subsystem_dae_2,v1_1,v2_1,comps_1,r,t) = BackendDAEOptimize.tearingSystem(subsystem_dae_1,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = List.flatten(comps_1);
        rf = List.flatten(r);
        tf = List.flatten(t);
        (equations_,uniqueEqIndex,tempvars) = generateRelaxationSystem(mixedEvent,v1_1,v2_1,comps_flat,rf,tf,subsystem_dae_2,helpVarInfo,iuniqueEqIndex,itempvars);
      then
       (equations_,uniqueEqIndex,tempvars);
        
        // Time varying jacobian. Linear system of equations that needs to be solved during runtime.
    case (_,_,v,kv,eqn,constrs,clsAttrs,SOME(jac),BackendDAE.JAC_TIME_VARYING(),_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem2 create linear system(time varying jacobian).");
        ((simVars,_)) = BackendVariable.traverseBackendDAEVars(v,traversingdlowvarToSimvar,({},kv));
        simVars = listReverse(simVars);
        ((_,beqs,_,_)) = BackendEquation.traverseBackendDAEEqns(eqn,BackendEquation.equationToExp,(v,{},{},SOME(inFuncs)));
        beqs = listReverse(beqs);
        simJac = List.map1(jac, jacToSimjac, v);
      then
        ({SimCode.SES_LINEAR(iuniqueEqIndex, mixedEvent, simVars, beqs, simJac)},iuniqueEqIndex+1,itempvars);
        
        // Time varying nonlinear jacobian. Non-linear system of equations.
    case (_,_,v,kv,eqn,constrs,clsAttrs,SOME(jac),BackendDAE.JAC_NONLINEAR(),_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem2 create non-linear system with jacobian.");
        eqn_lst = BackendDAEUtil.equationList(eqn);
        crefs = BackendVariable.getAllCrefFromVariables(v);
        (resEqs,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(eqn_lst,iuniqueEqIndex,itempvars);
      then
        ({SimCode.SES_NONLINEAR(uniqueEqIndex, resEqs, crefs,0)},uniqueEqIndex+1,tempvars);
        
        // No analytic jacobian available. Generate non-linear system.
    case (_,_,v,kv,eqn,constrs,clsAttrs,NONE(),BackendDAE.JAC_NO_ANALYTIC(),_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE, "SimCode.createOdeSystem2 create non-linear system without jacobian.");
        eqn_lst = BackendDAEUtil.equationList(eqn);
        crefs = BackendVariable.getAllCrefFromVariables(v);
        (resEqs,uniqueEqIndex,tempvars) = createNonlinearResidualEquations(eqn_lst,iuniqueEqIndex,itempvars);
      then
        ({SimCode.SES_NONLINEAR(uniqueEqIndex, resEqs, crefs,0)},uniqueEqIndex+1,tempvars);
        
        // failure
    else
      equation
        str = BackendDump.jacobianTypeStr(inJacobianType);
        str = stringAppendList({"createOdeSystem2 failed for ",str});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
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
    case (_,_,_,_)
      equation
        true = info > 0;
        varname = ComponentReference.printComponentRefStr(listGet(vars,info));
        infoStr = intString(info);
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ;\n  ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ;\n  ");
        syst = stringAppendList({"\n[\n  ", jacStr, "\n]\n  *\n[\n  ",varnames,"\n]\n  =\n[\n  ",rhsStr,"\n]"});
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst,infoStr,varname});
      then fail();
    case (_,_,_,_)
      equation
        true = info < 0;
        varnames = stringDelimitList(List.map(vars,ComponentReference.printComponentRefStr)," ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString)," ; ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac,realString),stringDelimitList," , ")," ; ");
        syst = stringAppendList({"[", jacStr, "] * [",varnames,"] = [",rhsStr,"]"});
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv",syst});
      then fail();
  end matchcontinue;
end checkLinearSystem;

protected function generateSolvedEquation
  input SimCode.SimVar var;
  input Real val;
  input DAE.ElementSource source;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem eq;
  output Integer ouniqueEqIndex;
protected
  DAE.ComponentRef name;
algorithm
  SimCode.SIMVAR(name=name) := var;
  eq := SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,name,DAE.RCONST(val),source); 
  ouniqueEqIndex := iuniqueEqIndex+1;
end generateSolvedEquation;

protected function replaceDerOpInEquationList
  "Replaces all der(cref) with $DER.cref in a list of equations."
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := List.map(inEqns, replaceDerOpInEquation);
end replaceDerOpInEquationList;

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
      list<Integer> dimSize;
      Integer size;
      DAE.Algorithm alg;
      list<DAE.Statement> stmts,stmts1;
      
    case (BackendDAE.EQUATION(exp = e1, scalar = e2, source = src))
      equation
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
      then
        BackendDAE.EQUATION(e1, e2, src);
        
    case (BackendDAE.ARRAY_EQUATION(dimSize=dimSize,left = e1, right = e2, source = src))
      equation
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
      then
        BackendDAE.ARRAY_EQUATION(dimSize,e1,e2,src);    
        
    case (BackendDAE.COMPLEX_EQUATION(size=size,left = e1, right = e2, source = src))
      equation
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
      then
        BackendDAE.COMPLEX_EQUATION(size,e1,e2,src);
        
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
        
    case (BackendDAE.ALGORITHM(size=size,alg=alg as DAE.ALGORITHM_STMTS(statementLst = stmts),source=src))
      equation
        (stmts1,_) = DAEUtil.traverseDAEEquationsStmts(stmts,replaceDerOpInExpTraverser,NONE());
        alg = Util.if_(referenceEq(stmts,stmts1),alg,DAE.ALGORITHM_STMTS(stmts1));
      then
        BackendDAE.ALGORITHM(size,alg,src);         
        
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
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> outEqns;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (outEqns,ouniqueEqIndex,otempvars) := matchcontinue (mixedEvent,inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,inBackendDAE,helpVarInfo,iuniqueEqIndex,itempvars)
    local
      array<Integer> ass1,ass2,ass1_1,ass2_1;
      list<Integer> block_,block_1,block_2,r,t;
      Integer size,uniqueEqIndex;
      BackendDAE.Variables v,v1;
      BackendDAE.EquationArray eqn,eqn1;
      list<BackendDAE.Equation> eqn_lst,reqn_lst;
      list<BackendDAE.Var> var_lst,tvar_lst;
      list<DAE.ComponentRef> crefs;
      list<SimCode.SimEqSystem> eqns,reqns,alleqns;
      BackendVarTransform.VariableReplacements repl,repl_1;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      list<SimCode.SimVar> tempvars;
    case (_,ass1,ass2,block_,r,t,
        BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=eqn)::{},shared=shared),_,_,_) 
      equation
        // get equations and variables
        eqn_lst = BackendDAEUtil.equationList(eqn);
        var_lst = BackendDAEUtil.varList(v);
        // get non relaxation equations
        block_1 = List.select1(block_,List.notMember,r);
        // get names from variables
        crefs = BackendVariable.getAllCrefFromVariables(v);
        crefs = listReverse(crefs);
        // generade replacement from non residual eqns           
        repl = BackendVarTransform.emptyReplacements();
        (repl_1,eqns,uniqueEqIndex) = getRelaxationReplacements(block_1,ass2,crefs,eqn_lst,repl,iuniqueEqIndex);
        // replace non tearing vars in residual eqns
        (reqn_lst,tvar_lst) = getRelaxedResidualEqns(r,ass2,crefs,var_lst,eqn_lst,repl_1);
        eqn1 = BackendDAEUtil.listEquation(reqn_lst);
        v1 = BackendDAEUtil.listVar(tvar_lst);
        size = listLength(reqn_lst);
        block_2 = List.intRange(size);
        ass1_1 = listArray(block_2);
        ass2_1 = listArray(block_2);
        syst = BackendDAE.EQSYSTEM(v1,eqn1,NONE(),NONE(),BackendDAE.MATCHING(ass1_1, ass2_1, {}));
        // generate code for relaxation equations
        (reqns,uniqueEqIndex,tempvars) = generateRelaxedResidualEqns(block_2,mixedEvent,syst,shared,helpVarInfo,uniqueEqIndex,itempvars);
        alleqns = listAppend(reqns,eqns);
      then
        (alleqns,uniqueEqIndex,tempvars);
        
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "- SimCode.generateRelaxationSystem failed \n");
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
  input Integer iuniqueEqIndex;
  output BackendVarTransform.VariableReplacements outRepl;
  output list<SimCode.SimEqSystem> outEqns;
  output Integer ouniqueEqIndex;
algorithm
  (outRepl,outEqns,ouniqueEqIndex) := match (inBlock,inAss2,inCrefs,inEqnLst,inRepl,iuniqueEqIndex)
    local
      Integer e,s,uniqueEqIndex;
      list<Integer> block_;
      array<Integer> ass2;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef c;
      list<BackendDAE.Equation> eqnLst;
      BackendDAE.Equation eqn;
      BackendVarTransform.VariableReplacements repl,repl1,repl2;
      DAE.Exp exp,varexp,exps;
      list<SimCode.SimEqSystem> seqns;
      DAE.ElementSource source;
      
    case ({},ass2,crefs,eqnLst,repl,_) then (repl,{},iuniqueEqIndex);
      
    case (e::block_,ass2,crefs,eqnLst,repl,_)
      equation
        s = ass2[e];
        c = listGet(crefs,s);
        eqn = listGet(eqnLst,e);
        varexp = Expression.crefExp(c);
        (exp,_) = solveEquation(eqn, varexp);
        (exps,_) = BackendVarTransform.replaceExp(exp,repl,NONE());
        repl1 = BackendVarTransform.addReplacement(repl, c, exps,NONE());
        source = BackendEquation.equationSource(eqn);
        (repl2,seqns,uniqueEqIndex) = getRelaxationReplacements(block_,ass2,crefs,eqnLst,repl1,iuniqueEqIndex+1);
      then 
        (repl2,SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,c, exp, source)::seqns,uniqueEqIndex);
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
      DAE.Type tp;
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
        Debug.fprint(Flags.FAILTRACE, "- SimCode.solveEquation failed \n");
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
        c = listGet(crefs,s);
        var = listGet(varlst,s);
        eqn = listGet(eqnLst,e);
        (eqn1::_,_) = BackendVarTransform.replaceEquations({eqn},repl,NONE());
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
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> outEqnLst;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (outEqnLst,ouniqueEqIndex,otempvars) := match (inBlock,mixedEvent,syst,shared,helpVarInfo,iuniqueEqIndex,itempvars)
    local
      Integer r,i,uniqueEqIndex;
      list<Integer> block_;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<SimCode.SimVar> simVars;
      list<DAE.Exp> beqs;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      list<SimCode.SimEqSystem> reqns;
      BackendDAE.Variables v,kv;
      BackendDAE.EquationArray eqn;
      array<Integer> Ass2;
      list<SimCode.SimVar> tempvars;
      DAE.FunctionTree funcs;
    case ({r},_,BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass2=Ass2)),_,_,_,_)
      equation
        i = Ass2[r];
        (reqns,uniqueEqIndex,tempvars) = createEquation(r, i, syst, shared, helpVarInfo, false, false,iuniqueEqIndex,itempvars);
      then 
        (reqns,uniqueEqIndex,tempvars);
        
    case (block_ as _::_::_,_,BackendDAE.EQSYSTEM(orderedVars=v,orderedEqs=eqn),BackendDAE.SHARED(knownVars=kv,functionTree=funcs), _,_,_)
      equation
        (m,mT) = BackendDAEUtil.incidenceMatrix(syst, BackendDAE.NORMAL());
        //mT = BackendDAEUtil.transposeMatrix(m);
        SOME(jac) = BackendDAEUtil.calculateJacobian(v, eqn, m, false,shared);
        ((simVars,_)) = BackendVariable.traverseBackendDAEVars(v,traversingdlowvarToSimvar,({},kv));
        simVars = listReverse(simVars);
        ((_,beqs,_,_)) = BackendEquation.traverseBackendDAEEqns(eqn,BackendEquation.equationToExp,(v,{},{},SOME(funcs)));
        beqs = listReverse(beqs);
        simJac = List.map1(jac, jacToSimjac, v);
      then
        ({SimCode.SES_LINEAR(iuniqueEqIndex, mixedEvent, simVars, beqs, simJac)},iuniqueEqIndex+1,itempvars);
  end match;
end generateRelaxedResidualEqns;

protected function jacToSimjac
  input tuple<Integer, Integer, BackendDAE.Equation> jac;
  input BackendDAE.Variables v;
  output tuple<Integer, Integer, SimCode.SimEqSystem> simJac;
algorithm
  simJac := match (jac, v)
    local
      Integer row;
      Integer col;
      DAE.Exp e;
      DAE.ElementSource source;
      
    case ((row, col, BackendDAE.RESIDUAL_EQUATION(exp=e,source=source)), _)
      equation
        // rhs_exp = BackendDAEUtil.getEqnsysRhsExp(e, v,NONE());
        // rhs_exp_1 = ExpressionSimplify.simplify(rhs_exp);
        // then ((row - 1, col - 1, SimCode.SES_RESIDUAL(rhs_exp_1)));
      then 
        ((row - 1, col - 1, SimCode.SES_RESIDUAL(0,e,source)));
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


protected function createSingleComplexEqnCode
  input BackendDAE.Equation inEquation;
  input list<BackendDAE.Var> inVars;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equations_,ouniqueEqIndex,otempvars) := matchcontinue(inEquation,inVars,helpVarInfo,iuniqueEqIndex,itempvars) 
    local
      Integer uniqueEqIndex;
      DAE.Exp e1,e2;
      DAE.ElementSource source;
      list<DAE.ComponentRef> crefs;
      BackendVarTransform.VariableReplacements repl;
      list<SimCode.SimEqSystem> resEqs;
      list<SimCode.SimVar> tempvars;
    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2,source=source),_,_,_,_)
      equation
        crefs = List.map(inVars,BackendVariable.varCref);
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
        (equations_,uniqueEqIndex,tempvars) = createSingleComplexEqnCode2(crefs, e1, e2, iuniqueEqIndex, itempvars, source);
      then
        (equations_,uniqueEqIndex,tempvars);
       
    case (BackendDAE.COMPLEX_EQUATION(source=_),_,_,_,_)
      equation
        crefs = List.map(inVars,BackendVariable.varCref);
        (resEqs,uniqueEqIndex,tempvars) = createNonlinearResidualEquations({inEquation},iuniqueEqIndex,itempvars);
      then
        ({SimCode.SES_NONLINEAR(uniqueEqIndex, resEqs, crefs,0)},uniqueEqIndex+1,tempvars);       
        // failure
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"complex equations currently only supported on form v = functioncall(...)"});
      then
        fail();
  end matchcontinue;
end createSingleComplexEqnCode;

// TODO: are the cases really correct?
protected function createSingleComplexEqnCode2
  input list<DAE.ComponentRef> crefs;
  input DAE.Exp inExp3;
  input DAE.Exp inExp4;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  input DAE.ElementSource source;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equations_,ouniqueEqIndex,otempvars) := matchcontinue (crefs,inExp3,inExp4,iuniqueEqIndex,itempvars,source)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Exp e1,e2,e1_1,e2_1;
      DAE.Statement stms;
      DAE.Type tp;
      Absyn.Path path,rpath;
      list<DAE.Exp> expLst,crexplst;
      DAE.Ident ident;
      list<tuple<DAE.Exp,DAE.Exp>> exptl;
      SimCode.SimEqSystem simeqn;
      list<SimCode.SimEqSystem> eqSystlst;
      list<SimCode.SimVar> tempvars;
      Integer uniqueEqIndex;
      list<DAE.Var> varLst;
      HashSet.HashSet ht;
    case (_,e1 as DAE.CREF(componentRef = cr2),e2,_,_,_)
      equation
        List.map1rAllValue(crefs,ComponentReference.crefPrefixOf,true,cr2);
        //((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(SOME(inFuncs),false)));
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        tp = Expression.typeof(e1);
        stms = DAE.STMT_ASSIGN(tp,e1,e2_1,source);
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex,{stms})},iuniqueEqIndex+1,itempvars);
        
    case (_,e1,e2 as DAE.CREF(componentRef = cr2),_,_,_)
      equation
        List.map1rAllValue(crefs,ComponentReference.crefPrefixOf,true,cr2);
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        //((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(SOME(inFuncs)),false)));
        tp = Expression.typeof(e2);
        stms = DAE.STMT_ASSIGN(tp,e2,e1_1,source);
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex,{stms})},iuniqueEqIndex+1,itempvars);
        
    /* Record() = f()  */ 
    case (_,e1 as DAE.CALL(path=path,expLst=expLst,attr=DAE.CALL_ATTR(ty= tp as DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path=rpath),varLst=varLst))),e2,_,_,_)
      equation
        true = Absyn.pathEqual(path, rpath);
        ht = HashSet.emptyHashSet();
        ht = List.fold(crefs,BaseHashSet.add,ht);
        List.foldAllValue(expLst,createSingleComplexEqnCode3,true,ht); 
        ((e2_1,(_,_))) = BackendDAEUtil.extendArrExp((e2,(NONE(),false)));
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        // tmp = f() 
        ident = System.stringReplace(Absyn.pathString(path),".","_");
        cr1 = ComponentReference.makeCrefIdent("$TMP_" +& ident +& intString(iuniqueEqIndex), tp, {});
        e1_1 = Expression.crefExp(cr1);
        stms = DAE.STMT_ASSIGN(tp,e1_1,e2_1,source);
        simeqn = SimCode.SES_ALGORITHM(iuniqueEqIndex,{stms});
        uniqueEqIndex = iuniqueEqIndex + 1;
        // Record()=tmp
        crexplst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr1);
        exptl = List.threadTuple(expLst,crexplst);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(exptl,makeSES_SIMPLE_ASSIGN,source,uniqueEqIndex);
        eqSystlst = simeqn::eqSystlst;
        tempvars = greateTempVars(varLst,cr1,itempvars);
      then
        (eqSystlst,uniqueEqIndex,tempvars);

    /* f() = Record()  */ 
    case (_,e1,e2 as DAE.CALL(path=path,expLst=expLst,attr=DAE.CALL_ATTR(ty= tp as DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path=rpath),varLst=varLst))),_,_,_)
      equation
        true = Absyn.pathEqual(path, rpath);
        ht = HashSet.emptyHashSet();
        ht = List.fold(crefs,BaseHashSet.add,ht);
        List.foldAllValue(expLst,createSingleComplexEqnCode3,true,ht);         
        ((e1_1,(_,_))) = BackendDAEUtil.extendArrExp((e1,(NONE(),false)));
        //true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        // tmp = f() 
        ident = System.stringReplace(Absyn.pathString(path),".","_");
        cr1 = ComponentReference.makeCrefIdent("$TMP_" +& ident +& intString(iuniqueEqIndex), tp, {});
        e2_1 = Expression.crefExp(cr1);
        stms = DAE.STMT_ASSIGN(tp,e2_1,e1_1,source);
        simeqn = SimCode.SES_ALGORITHM(iuniqueEqIndex,{stms});
        uniqueEqIndex = iuniqueEqIndex + 1;
        // Record()=tmp
        crexplst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr1);
        exptl = List.threadTuple(expLst,crexplst);
        (eqSystlst,uniqueEqIndex) = List.map1Fold(exptl,makeSES_SIMPLE_ASSIGN,source,uniqueEqIndex);
        eqSystlst = simeqn::eqSystlst;
        tempvars = greateTempVars(varLst,cr1,itempvars);
      then
        (eqSystlst,uniqueEqIndex,tempvars);
        
        // failure
    case (_,e1,e2,_,_,_)
      /*
       equation
       s1 = ExpressionDump.printExpStr(e1);
       s2 = ExpressionDump.printExpStr(e2);
       s3 = ComponentReference.crefStr(cr);
       s = stringAppendList({"SimCode.createSingleComplexEqnCode2 failed for: ", s1, " = " , s2, " solve for ", s3 });
       Error.addMessage(Error.INTERNAL_ERROR, {s});
       */        
    then
      fail();
  end matchcontinue;
end createSingleComplexEqnCode2;

protected function createSingleComplexEqnCode3
  input DAE.Exp inExp;
  input HashSet.HashSet iht;
  output Boolean outB;
  output HashSet.HashSet oht;
algorithm
  (outB,oht) := matchcontinue(inExp,iht)
    local
      DAE.ComponentRef cr;
      HashSet.HashSet ht;  
    case (DAE.CREF(componentRef=cr),_)
      equation
        _ = BaseHashSet.get(cr,iht);
        ht = BaseHashSet.delete(cr, iht);
      then
        (true,ht);
    else
      (false,iht);
  end matchcontinue;  
end createSingleComplexEqnCode3;

protected function createSingleArrayEqnCode
  input Boolean genDiscrete;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Var> inVars;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output list<SimCode.SimEqSystem> noDiscequations;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
algorithm
  (equations_,noDiscequations,ouniqueEqIndex,otempvars) := matchcontinue(genDiscrete,inEquations,inVars,helpVarInfo,iuniqueEqIndex,itempvars) 
    local
      list<Integer> ds;
      list<Option<Integer>> ad;
      DAE.Exp e1,e2;
      list<DAE.Exp> ea1,ea2;
      list<tuple<DAE.Exp,DAE.Exp>> ealst;
      list<BackendDAE.Equation> re;
      list<BackendDAE.Var> vars;
      DAE.ComponentRef cr,cr_1;
      BackendDAE.Variables evars,vars1;
      BackendDAE.EquationArray eeqns,eqns_1;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      DAE.FunctionTree funcs;
      DAE.ElementSource source;
      BackendDAE.Variables av;
      BackendDAE.BackendDAE subsystem_dae;
      SimCode.SimEqSystem equation_;
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Integer uniqueEqIndex;
      String str;
      list<list<DAE.Subscript>> subslst;
      list<SimCode.SimVar> tempvars;

    case (_,BackendDAE.ARRAY_EQUATION(left=e1,right=e2,source=source)::_,BackendDAE.VAR(varName = cr)::_,_,_,_)
      equation
        // We need to strip subs from the name since they are removed in cr.
        cr_1 = ComponentReference.crefStripLastSubs(cr);
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
        ((e1,_)) = BackendDAEUtil.collateArrExp((e1,NONE()));
        ((e2,_)) = BackendDAEUtil.collateArrExp((e2,NONE()));
        (e1,e2) = solveTrivialArrayEquation(cr_1,e1,e2);
        (equation_,uniqueEqIndex) = createSingleArrayEqnCode2(cr_1, cr_1, e1, e2, iuniqueEqIndex, source);
      then
        ({equation_},{equation_},uniqueEqIndex,itempvars);
      
    case (_,BackendDAE.ARRAY_EQUATION(left=e1,right=e2,source=source)::_,vars,_,_,_)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
        ea1 = BackendDAEUtil.collateArrExpList(ea1,NONE());
        ea2 = BackendDAEUtil.collateArrExpList(ea2,NONE());
        ealst = List.threadTuple(ea1,ea2);
        re = List.map1(ealst,BackendEquation.generateEQUATION,source);
        eqns_1 = BackendDAEUtil.listEquation(re);
        av = BackendDAEUtil.emptyVars();
        eeqns = BackendDAEUtil.listEquation({});
        evars = BackendDAEUtil.listVar1({});
        constrs = listArray({});
        clsAttrs = listArray({});
        cache = Env.emptyCache();
        funcs = DAEUtil.avlTreeNew();
        vars1 = BackendDAEUtil.listVar1(vars);
        syst = BackendDAE.EQSYSTEM(vars1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(evars,evars,av,eeqns,eeqns,constrs,clsAttrs,cache,{},funcs, BackendDAE.EVENT_INFO({},{},{},{},0),{},BackendDAE.ARRAYSYSTEM(),{});
        subsystem_dae = BackendDAE.DAE({syst},shared);
        (BackendDAE.DAE({syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))},shared)) = BackendDAEUtil.transformBackendDAE(subsystem_dae,SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.ALLOW_UNDERCONSTRAINED())),NONE(),NONE());
        (equations_,noDiscequations,uniqueEqIndex,tempvars) = createEquations(false, false, genDiscrete, false, false, syst, shared, comps, helpVarInfo, iuniqueEqIndex,itempvars);
      then
        (equations_,noDiscequations,uniqueEqIndex,tempvars);    
    case (_,BackendDAE.ARRAY_EQUATION(dimSize=ds,left=e1,right=e2,source=source)::_,vars,_,_,_)
      equation
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
        ad = List.map(ds,Util.makeOption);
        subslst = BackendDAEUtil.arrayDimensionsToRange(ad);
        subslst = BackendDAEUtil.rangesToSubscripts(subslst);
        ea1 = List.map1r(subslst,Expression.applyExpSubscripts,e1);
        ea2 = List.map1r(subslst,Expression.applyExpSubscripts,e2);
        ealst = List.threadTuple(ea1,ea2);
        re = List.map1(ealst,BackendEquation.generateEQUATION,source);
        eqns_1 = BackendDAEUtil.listEquation(re);
        av = BackendDAEUtil.emptyVars();
        eeqns = BackendDAEUtil.listEquation({});
        evars = BackendDAEUtil.listVar1({});
        constrs = listArray({});
        clsAttrs = listArray({});
        cache = Env.emptyCache();
        funcs = DAEUtil.avlTreeNew();
        vars1 = BackendDAEUtil.listVar1(vars);
        syst = BackendDAE.EQSYSTEM(vars1,eqns_1,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(evars,evars,av,eeqns,eeqns,constrs,clsAttrs,cache,{},funcs, BackendDAE.EVENT_INFO({},{},{},{},0),{},BackendDAE.ARRAYSYSTEM(),{});
        subsystem_dae = BackendDAE.DAE({syst},shared);
        (BackendDAE.DAE({syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))},shared)) = BackendDAEUtil.transformBackendDAE(subsystem_dae,SOME((BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.ALLOW_UNDERCONSTRAINED())),NONE(),NONE());
        (equations_,noDiscequations,uniqueEqIndex,tempvars) = createEquations(false, false, genDiscrete, false, false, syst, shared, comps, helpVarInfo, iuniqueEqIndex,itempvars);
      then
        (equations_,noDiscequations,uniqueEqIndex,tempvars);  
        // failure
    else
      equation
        str = BackendDump.dumpEqnsStr(inEquations);
        str = "for Eqn: " +& str +& "\narray equations currently only supported on form v = functioncall(...)";
        Error.addMessage(Error.INTERNAL_ERROR,{str});
      then
        fail();
  end matchcontinue;
end createSingleArrayEqnCode;

protected function createSingleAlgorithmCode
  input list<BackendDAE.Equation> eqns;
  input list<BackendDAE.Var> vars;
  input Boolean skipDiscinAlgorithm;
  input Integer iuniqueEqIndex;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
algorithm
  (equations_,ouniqueEqIndex) := matchcontinue (eqns,vars,skipDiscinAlgorithm,iuniqueEqIndex)
    local
      Algorithm.Algorithm alg;
      list<Expression.ComponentRef> solvedVars,algOutVars;
      String message,algStr;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
 
      // normal call
    case (BackendDAE.ALGORITHM(alg=alg)::_,_,false,_)
      equation
        solvedVars = List.map(vars,BackendVariable.varCref);
        algOutVars = CheckModel.algorithmOutputs(alg);
        // The variables solved for musst all be part of the output variables of the algorithm.
        List.map2AllValue(solvedVars,List.isMemberOnTrue,true,algOutVars,ComponentReference.crefEqualNoStringCompare);
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg,NONE());
      then 
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex,algStatements)},iuniqueEqIndex+1);
        
        // remove discrete Vars
    case (BackendDAE.ALGORITHM(alg=alg)::_,_,true,_)
      equation
        solvedVars = List.map(vars,BackendVariable.varCref);
        algOutVars = CheckModel.algorithmOutputs(alg);
        // The variables solved for musst all be part of the output variables of the algorithm.
        List.map2AllValue(solvedVars,List.isMemberOnTrue,true,algOutVars,ComponentReference.crefEqualNoStringCompare);
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg,NONE());
        algStatements = BackendDAEUtil.removediscreteAssingments(algStatements,BackendDAEUtil.listVar1(vars));
      then 
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex,algStatements)},iuniqueEqIndex+1);
        
        // Error message, inverse algorithms not supported yet
    case (BackendDAE.ALGORITHM(alg=alg,source=source)::_,_,_,_)
      equation
        solvedVars = List.map(vars,BackendVariable.varCref);
        algOutVars = CheckModel.algorithmOutputs(alg);
        // The variables solved for musst all be part of the output variables of the algorithm.
        failure(List.map2AllValue(solvedVars,List.isMemberOnTrue,true,algOutVars,ComponentReference.crefEqualNoStringCompare));
        algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This has not been implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then
         fail();      
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
  input Integer iuniqueEqIndex;
  input DAE.ElementSource source;
  output SimCode.SimEqSystem equation_;
  output Integer ouniqueEqIndex;
algorithm
  (equation_,ouniqueEqIndex) := matchcontinue (inComponentRef1,inComponentRef2,inExp3,inExp4,iuniqueEqIndex,source)
    local
      DAE.ComponentRef cr,eltcr,cr2;
      DAE.Exp e1,e2;
      DAE.Type ty;
      
    case (cr,eltcr,(e1 as DAE.CREF(componentRef = cr2)),e2,_,_)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,eltcr, e2, source),iuniqueEqIndex+1);
        
    case (cr,eltcr,e1,(e2 as DAE.CREF(componentRef = cr2)),_,_)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,eltcr, e1, source),iuniqueEqIndex+1);
        
    case (cr,eltcr,(e1 as DAE.UNARY(exp=DAE.CREF(componentRef = cr2))),e2,_,_)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        ty = Expression.typeof(e2);
        e2 = Expression.negate(e2);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,eltcr, e2, source),iuniqueEqIndex+1);
        
    case (cr,eltcr,e1,(e2 as DAE.UNARY(exp=DAE.CREF(componentRef = cr2))),_,_)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        e1 = Expression.negate(e1);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,eltcr, e1, source),iuniqueEqIndex+1);
        
    case (cr,eltcr,e1,DAE.UNARY(DAE.UMINUS_ARR(ty),e2),_,_)
      equation
        cr2 = getVectorizedCrefFromExp(e2);
        e1 = Expression.negate(e1);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,cr2, e1, source),iuniqueEqIndex+1);
        
    case (cr,eltcr,DAE.UNARY(DAE.UMINUS_ARR(ty),e1),e2,_,_) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
        e2 = Expression.negate(e2);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,cr2, e2, source),iuniqueEqIndex+1);
        
    case (cr,eltcr,e1,e2,_,_) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e2);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,cr2, e1, source),iuniqueEqIndex+1);
        
    case (cr,eltcr,e1,e2,_,_) /* e1 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex,cr2, e2, source),iuniqueEqIndex+1);
        
        // failure
    case (cr,_,e1,e2,_,_)
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

protected function createInitSymbolicJacobianssSimCode
"fuction creates the linear model matrices column-wise"
  input BackendDAE.SymbolicJacobian inJacobian;
  input BackendDAE.BackendDAE inBackendDAE;
  input Integer inUniqueEqIndex;
  output SimCode.JacobianMatrix outJacobian;
  output Integer outUniqueEqIndex;
algorithm
  (outJacobian, outUniqueEqIndex) := matchcontinue(inJacobian, inBackendDAE, inUniqueEqIndex)
    local
      BackendDAE.StrongComponents comps;
      
      list<BackendDAE.Var>  seedlst,  origVarslst,  diffVars, diffedVars, derivedVariableslst, alldiffedVars;
      list<DAE.ComponentRef>   comref_seedVars, comref_vars;
      
      BackendDAE.Variables v;
      
      list< tuple<BackendDAE.Var,Integer> > sortdiffvars;
      
      SimCode.JacobianMatrix jacobian;
      
      
      String name;
      
      list<SimCode.SimEqSystem> columnEquations;
      list<SimCode.SimVar> columnVars;
      list<SimCode.SimVar> columnVarsKn;
      list<SimCode.SimVar> seedVars, indexVars;
      
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      BackendDAE.EqSystems systs;
      BackendDAE.Variables vars, origVars, knvars, empty;
      String s;
      
      list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>> sparsepattern;
      BackendDAE.SparseColoring colsColors;
      list<Integer> varsIndexes;
      Integer maxColor;
      
      DAE.ComponentRef x;
      String dummyVarName;
      BackendDAE.Variables derivedVariables;
      Integer uniqueEqIndex;
      
    case ((BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))}, shared=shared),
          name, diffVars, diffedVars, alldiffedVars),
          BackendDAE.DAE(eqs=systs),
          uniqueEqIndex) equation
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> creating SimCode equations for Matrix " +& name +& " time: " +& realString(clock()) +& "\n");
        (columnEquations, _, uniqueEqIndex,_) = createEquations(false, false, false, false, true, syst, shared, comps, {}, uniqueEqIndex,{});
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> created all SimCode equations for Matrix " +& name +&  " time: " +& realString(clock()) +& "\n");
        
        
        origVarslst = BackendVariable.equationSystemsVarsLst(systs,{});
        origVars = BackendDAEUtil.listVar1(origVarslst);

        // create SimCode.SimVars from jacobian vars
        vars = BackendVariable.daeVars(syst);
        knvars = BackendVariable.daeKnVars(shared);
        empty = BackendDAEUtil.emptyVars();
        
        v = BackendDAEUtil.listVar1(diffedVars);

        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> create all SimCode vars for Matrix " +& name +& " time: " +& realString(clock()) +& "\n");
        s =  intString(listLength(diffedVars));
        comref_vars = List.map(listReverse(diffVars), BackendVariable.varCref);
        seedlst = List.map1(comref_vars, BackendDAEOptimize.createSeedVars, (name,false));
        //comref_seedVars = List.map(seedlst, BackendVariable.varCref);
                
        ((seedVars,_)) = List.fold(diffVars,traversingdlowvarToSimvarFold,({},BackendDAEUtil.emptyVars()));
        seedVars = sortSimVars1(seedVars);
        ((indexVars,_)) = List.fold(diffedVars,traversingdlowvarToSimvarFold,({},BackendDAEUtil.emptyVars()));
        indexVars = sortSimVars1(indexVars);

        dummyVarName = ("dummyVar" +& name);
        x = DAE.CREF_IDENT(dummyVarName,DAE.T_REAL_DEFAULT,{});
        columnVars = creatallDiffedVars(alldiffedVars, x, v, 0, (name,false),{});
        ((columnVarsKn,_)) =  BackendVariable.traverseBackendDAEVars(knvars,traversingdlowvarToSimvar,({},empty));
        columnVars = listAppend(columnVars,columnVarsKn);
        columnVars = listReverse(columnVars);
        Debug.fcall(Flags.JAC_DUMP, print, "analytical Jacobians -> transformed to SimCode for Matrix " +& name +& " time: " +& realString(clock()) +& "\n");
        
        // generate sparse pattern
        ((sparsepattern,(_,_)),colsColors) = BackendDAEOptimize.generateSparsePattern(inBackendDAE, diffVars, diffedVars);
        
        maxColor = listLength(colsColors);
                      
        jacobian = (({((columnEquations,columnVars,s))},seedVars,name,(sparsepattern,(seedVars,columnVars)),colsColors,maxColor));
    then (jacobian, uniqueEqIndex);
       
    else equation
        Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCode.mo: createInitSymbolicJacobianssSimCode failed"});
    then fail();
  end matchcontinue;
end createInitSymbolicJacobianssSimCode;

protected function createInitialMatrices "function: createInitialMatrices
  author: lochel
  This function generates matrices for initialization."
  input BackendDAE.BackendDAE inDAE;
  input Integer inIniqueEqIndex;
  output SimCode.JacobianMatrix outJacG;
  output Integer outIniqueEqIndex;
algorithm
  (outJacG, outIniqueEqIndex) := matchcontinue(inDAE, inIniqueEqIndex)
    local
      BackendDAE.BackendDAE DAE, DAE2;
      
      BackendDAE.SymbolicJacobian jacobian;
      SimCode.JacobianMatrix jacG;
      Integer iniqueEqIndex;
      
    case(DAE, _) equation
      true = Flags.isSet(Flags.SYMBOLIC_INITIALIZATION);
      (jacobian, DAE2) = BackendDAEOptimize.generateInitialMatrices(DAE);
      (jacG, iniqueEqIndex) = createInitSymbolicJacobianssSimCode(jacobian, DAE2, inIniqueEqIndex);
    then (jacG, iniqueEqIndex);
      
    case(DAE, _) equation
      jacG = ({}, {}, "G", ({},({},{})), {}, 0);
    then (jacG, inIniqueEqIndex);
        
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCode.mo: createInitialMatrices failed"});
    then fail();
  end matchcontinue;
end createInitialMatrices;

protected function createInitialResiduals "function createInitialResiduals
  author: lochel
  This function generates all initial_residuals."
  input BackendDAE.BackendDAE inDAE;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimVar> itempvars;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  output list<SimCode.SimEqSystem> outResiduals;
  output list<SimCode.SimEqSystem> outInitialEqns;
  output Integer outNumberOfInitialEquations;
  output Integer outNumberOfInitialAlgorithms;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimVar> otempvars;
  output Boolean initialSystemSolved;
algorithm
  (outResiduals, outInitialEqns, outNumberOfInitialEquations, outNumberOfInitialAlgorithms, ouniqueEqIndex, otempvars, initialSystemSolved) := matchcontinue(inDAE, iuniqueEqIndex, itempvars, helpVarInfo)
    local
      BackendDAE.EqSystems eqs;
      BackendDAE.EquationArray initialEqs,removedEqs;
      list<SimCode.SimVar> tempvars;
      Integer uniqueEqIndex;
      
      list<BackendDAE.Equation> initialEqs_lst;
      Integer numberOfInitialEquations, numberOfInitialAlgorithms;
      
      list<SimCode.SimEqSystem> residual_equations,residual_equations1,allEquations,removedEquations,knvarseqns,aliasEquations;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.Variables knvars,aliasVars;
      
    // try to solve the inital system symbolical.
    case(_, _, _, _)  equation
      true = Flags.isSet(Flags.SOLVE_INITIAL_SYSTEM);
      // generate initalsystem
      (_,BackendDAE.DAE(systs,shared as BackendDAE.SHARED(knownVars=knvars,aliasVars=aliasVars,removedEqs=removedEqs))) = BackendDAEUtil.solveInitialSystem(inDAE);
      // generate equations from the solved systems
      (uniqueEqIndex,_,_,allEquations,tempvars) = createEquationsForSystems(systs,shared,helpVarInfo,iuniqueEqIndex,{},{},{},itempvars);
      // generate equations from the removed equations
      ((uniqueEqIndex,removedEquations)) = BackendEquation.traverseBackendDAEEqns(removedEqs,traversedlowEqToSimEqSystem,(uniqueEqIndex,{}));
      allEquations = listAppend(allEquations,removedEquations);
      // generate equations from the knvown unfixed variables
      ((uniqueEqIndex,knvarseqns)) = BackendVariable.traverseBackendDAEVars(knvars,traverseKnVarsToSimEqSystem,(uniqueEqIndex,{}));
      allEquations = listAppend(allEquations,knvarseqns);
      // generate equations from the alias variables
      ((uniqueEqIndex,aliasEquations)) = BackendVariable.traverseBackendDAEVars(aliasVars,traverseAliasVarsToSimEqSystem,(uniqueEqIndex,{}));
      allEquations = listAppend(allEquations,aliasEquations);
    then ({}, allEquations, 0, 0, uniqueEqIndex, tempvars, true);
    
    case(_, _, _, _) equation
      (initialEqs_lst, numberOfInitialEquations, numberOfInitialAlgorithms) = BackendDAEOptimize.collectInitialEquations(inDAE);
      (residual_equations, uniqueEqIndex, tempvars) = createNonlinearResidualEquations(initialEqs_lst, iuniqueEqIndex, itempvars); 
    then (residual_equations, {}, numberOfInitialEquations, numberOfInitialAlgorithms, uniqueEqIndex, tempvars, Flags.isSet(Flags.SOLVE_INITIAL_SYSTEM));

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCodeUtil.mo: createInitialResiduals failed"});
    then fail();
  end matchcontinue;
end createInitialResiduals;


protected function traverseKnVarsToSimEqSystem
  "autor: Frenkel TUD 2012-10"
   input tuple<BackendDAE.Var, tuple<Integer,list<SimCode.SimEqSystem>>> inTpl;
   output tuple<BackendDAE.Var, tuple<Integer,list<SimCode.SimEqSystem>>> outTpl;
algorithm
  outTpl:= matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      Integer uniqueEqIndex;
      list<SimCode.SimEqSystem> eqns;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      DAE.ElementSource source;
    case ((v as BackendDAE.VAR(varName = cr,bindExp=SOME(exp),source=source),(uniqueEqIndex,eqns)))
      equation
        false = BackendVariable.varFixed(v);
      then
        ((v,(uniqueEqIndex+1,SimCode.SES_SIMPLE_ASSIGN(uniqueEqIndex,cr,exp,source)::eqns)));
    else then inTpl;
  end matchcontinue;
end traverseKnVarsToSimEqSystem;

protected function traverseAliasVarsToSimEqSystem
  "autor: Frenkel TUD 2012-10"
   input tuple<BackendDAE.Var, tuple<Integer,list<SimCode.SimEqSystem>>> inTpl;
   output tuple<BackendDAE.Var, tuple<Integer,list<SimCode.SimEqSystem>>> outTpl;
algorithm
  outTpl:= match (inTpl)
    local
      BackendDAE.Var v;
      Integer uniqueEqIndex;
      list<SimCode.SimEqSystem> eqns;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      DAE.ElementSource source;
    case ((v as BackendDAE.VAR(varName = cr,bindExp=SOME(exp),source=source),(uniqueEqIndex,eqns)))
      then
        ((v,(uniqueEqIndex+1,SimCode.SES_SIMPLE_ASSIGN(uniqueEqIndex,cr,exp,source)::eqns)));
  end match;
end traverseAliasVarsToSimEqSystem;

protected function dlowEqToSimEqSystem
  input BackendDAE.Equation inEquation;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem outEquation;
  output Integer ouniqueEqIndex;
algorithm
  (outEquation,ouniqueEqIndex) := match (inEquation,iuniqueEqIndex)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp_;
      Algorithm.Algorithm alg;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
      
    case (BackendDAE.SOLVED_EQUATION(cr, exp_, source),_) then (SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex,cr, exp_, source),iuniqueEqIndex+1);
      
    case (BackendDAE.RESIDUAL_EQUATION(exp_, source),_) then (SimCode.SES_RESIDUAL(iuniqueEqIndex,exp_, source),iuniqueEqIndex+1);

    case (BackendDAE.ALGORITHM(alg=alg),_)
      equation
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      then
        (SimCode.SES_ALGORITHM(iuniqueEqIndex,algStatements),iuniqueEqIndex+1);
      
  end match;
end dlowEqToSimEqSystem;

protected function dlowAlgToSimEqSystem
  input DAE.Algorithm inAlg;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem outEquation;
  output Integer ouniqueEqIndex;
algorithm
  (outEquation,ouniqueEqIndex) := match (inAlg,iuniqueEqIndex)
    local
      list<DAE.Statement> algStatements;
    case (_,_)
      equation
        DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(inAlg, NONE());
      then
        (SimCode.SES_ALGORITHM(iuniqueEqIndex,algStatements),iuniqueEqIndex+1);
  end match;
end dlowAlgToSimEqSystem;

protected function filterNonConstant
  input BackendDAE.Equation eq;
  output Boolean b;
algorithm
  b := matchcontinue (eq)
    local
      DAE.Exp exp,e1,e2;
      Boolean b1;
      DAE.ElementSource source;
    case (BackendDAE.RESIDUAL_EQUATION(exp=exp)) then (not Expression.isConst(exp));

    case (BackendDAE.EQUATION(exp = e1,scalar = e2, source = source))
      equation
        true = Expression.isConst(e1);
        true = Expression.isConst(e2);
        b1 = Expression.expEqual(e1, e2);
        // Error.addSourceMessage(inErrorMsg, inMessageTokens, inInfo)
      then
        false;
    
    case (BackendDAE.ARRAY_EQUATION(left = e1,right = e2,source = source))
      equation
        true = Expression.isConst(e1);
        true = Expression.isConst(e2);
        b1 = Expression.expEqual(e1, e2);
        // Error.addSourceMessage(inErrorMsg, inMessageTokens, inInfo)
      then
        false;
    
    case (BackendDAE.COMPLEX_EQUATION(left = e1,right = e2,source = source))
      equation
        true = Expression.isConst(e1);
        true = Expression.isConst(e2);
        b1 = Expression.expEqual(e1, e2);
        // Error.addSourceMessage(inErrorMsg, inMessageTokens, inInfo)
      then
        false;     
    else
     then
       true;
  end matchcontinue;
end filterNonConstant;


protected function failUnlessResidual
  input BackendDAE.Equation eq;
algorithm
  _ := match (eq)
    case (BackendDAE.RESIDUAL_EQUATION(exp=_)) then ();
  end match;
end failUnlessResidual;

protected function createVarNominalAssertFromVars
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer,list<SimCode.SimEqSystem>> acc;
  output tuple<Integer,list<SimCode.SimEqSystem>> nominalAsserts;
algorithm
  nominalAsserts := match (syst,shared,acc)
    local
      list<DAE.Algorithm> asserts1;
      list<SimCode.SimEqSystem> asserts2;
      BackendDAE.Variables vars;
      Integer uniqueEqIndex;
      list<SimCode.SimEqSystem> simeqns;
    case (BackendDAE.EQSYSTEM(orderedVars=vars),_,(uniqueEqIndex,simeqns))
      equation
        asserts1 = BackendVariable.traverseBackendDAEVars(vars,createVarNominalAssert,{});
        (asserts2,uniqueEqIndex) = List.mapFold(asserts1,dlowAlgToSimEqSystem,uniqueEqIndex);
      then ((uniqueEqIndex,listAppend(asserts2,simeqns)));
  end match;
end createVarNominalAssertFromVars;

protected function createStartValueEquations
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer,list<SimCode.SimEqSystem>> acc;
  output tuple<Integer,list<SimCode.SimEqSystem>> startValueEquations;
algorithm
  startValueEquations := matchcontinue (syst, shared, acc)
    local
      BackendDAE.Variables vars,av;
      list<BackendDAE.Equation>  startValueEquationsTmp2;
      list<SimCode.SimEqSystem> simeqns,simeqns1;
      Integer uniqueEqIndex;
      
    // this is the old version if the new fails 
    case (BackendDAE.EQSYSTEM(orderedVars=vars), BackendDAE.SHARED(aliasVars=av),(uniqueEqIndex,simeqns)) equation
      // vars
      ((startValueEquationsTmp2,_)) = BackendVariable.traverseBackendDAEVars(vars,createInitialAssignmentsFromStart,({},av));
      startValueEquationsTmp2 = listReverse(startValueEquationsTmp2);
      // kvars
      //((startValueEquationsTmp,_)) = BackendVariable.traverseBackendDAEVars(knvars,createInitialAssignmentsFromStart,({},av));
      //startValueEquationsTmp = listReverse(startValueEquationsTmp);
      //startValueEquationsTmp2 = listAppend(startValueEquationsTmp2, startValueEquationsTmp);
      
      (simeqns1,uniqueEqIndex) = List.mapFold(startValueEquationsTmp2, dlowEqToSimEqSystem, uniqueEqIndex);
    then
      ((uniqueEqIndex,listAppend(simeqns1, simeqns)));
        
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"createStartValueEquations failed"});
    then fail();
  end matchcontinue;
end createStartValueEquations;

protected function createParameterEquations
  input BackendDAE.Shared inShared;
  input Integer iuniqueEqIndex;
  input list<SimCode.SimEqSystem> acc;
  input Boolean initialSystemSolved;
  output Integer ouniqueEqIndex;
  output list<SimCode.SimEqSystem> parameterEquations;
algorithm
  (ouniqueEqIndex,parameterEquations) := matchcontinue (inShared,iuniqueEqIndex,acc,initialSystemSolved)
    local
      list<BackendDAE.Equation> parameterEquationsTmp;
      BackendDAE.Variables knvars,extobj,v,kn;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      BackendDAE.EquationArray ie,pe,emptyeqns,remeqns;
      list<SimCode.SimEqSystem> simvarasserts,inalgs;
      list<DAE.Algorithm> varasserts,ialgs;
      BackendDAE.BackendDAE paramdlow;
      BackendDAE.ExternalObjectClasses extObjClasses;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mT;
      array<Integer> v1,v2;
      list<Integer> lv1,lv2;
      BackendDAE.StrongComponents comps;
      list<BackendDAE.Var> lv,lkn;
      list<SimCode.HelpVarInfo> helpVarInfo;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      BackendDAE.Variables aliasVars,alisvars;
      
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo einfo;
      BackendDAE.BackendDAEType btp;
      BackendDAE.SymbolicJacobians symjacs;
      Integer uniqueEqIndex;
      
    case (BackendDAE.SHARED(knownVars=knvars,externalObjects=extobj,aliasVars=aliasVars,
                            initialEqs=ie,removedEqs=remeqns,constraints=constrs,classAttrs=clsAttrs,cache=cache,env=env,
                            extObjClasses=extObjClasses,functionTree=funcs,eventInfo=einfo,backendDAEType=btp,symjacs=symjacs),_,_,_)
      equation
        // kvars params
        ((parameterEquationsTmp,lv,lkn,lv1,lv2,_)) = BackendVariable.traverseBackendDAEVars(knvars,createInitialParamAssignments,({},{},{},{},{},1));
        
        // sort the equations
        emptyeqns = BackendDAEUtil.listEquation({});
        pe = BackendDAEUtil.listEquation(parameterEquationsTmp);
        alisvars = BackendDAEUtil.emptyVars();
        v = BackendDAEUtil.listVar(lv);
        kn = BackendDAEUtil.listVar(lkn);
        funcs = DAEUtil.avlTreeNew();
        syst = BackendDAE.EQSYSTEM(v,pe,NONE(),NONE(),BackendDAE.NO_MATCHING());
        shared = BackendDAE.SHARED(kn,extobj,alisvars,emptyeqns,emptyeqns,constrs,clsAttrs,cache,env,funcs,BackendDAE.EVENT_INFO({},{},{},{},0),extObjClasses,BackendDAE.PARAMETERSYSTEM(),{});
        (syst,m,mT) = BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL());
        paramdlow = BackendDAE.DAE({syst},shared);
        //mT = BackendDAEUtil.transposeMatrix(m);
        v1 = listArray(lv1);
        v2 = listArray(lv2);
        Debug.fcall(Flags.PARAM_DLOW_DUMP, print,"Param DAE:\n");
        Debug.fcall(Flags.PARAM_DLOW_DUMP, BackendDump.dump,paramdlow);
        Debug.fcall(Flags.PARAM_DLOW_DUMP, BackendDump.dumpIncidenceMatrix,m);
        Debug.fcall(Flags.PARAM_DLOW_DUMP, BackendDump.dumpIncidenceMatrixT,mT);
        Debug.fcall(Flags.PARAM_DLOW_DUMP, BackendDump.dumpMatching,v1);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(v1,v2,{}));
        (syst,comps) = BackendDAETransform.strongComponents(syst, shared);
        paramdlow = BackendDAE.DAE({syst},shared);
        Debug.fcall(Flags.PARAM_DLOW_DUMP, BackendDump.dumpComponents,comps);
                                                                             
        (helpVarInfo, BackendDAE.DAE({syst},shared),_) = generateHelpVarInfo(paramdlow);
        (parameterEquations,_,uniqueEqIndex,_) = createEquations(false, false, true, false, false, syst, shared, comps, helpVarInfo,iuniqueEqIndex,{});
    
        ialgs = BackendEquation.traverseBackendDAEEqns(ie,traverseAlgorithmFinder,{});
        ialgs = listReverse(ialgs);
        (inalgs,uniqueEqIndex) = List.mapFold(ialgs,dlowAlgToSimEqSystem,uniqueEqIndex);
        // get minmax and nominal asserts
        varasserts = BackendVariable.traverseBackendDAEVars(knvars,createVarAsserts,{});
        (simvarasserts,uniqueEqIndex) = List.mapFold(varasserts,dlowAlgToSimEqSystem,uniqueEqIndex);
        
        // do not append the inital algorithms to the parameter equation if the system is solved symbolically
        parameterEquations = Debug.bcallret2(not initialSystemSolved,listAppend,parameterEquations, inalgs, parameterEquations);
        parameterEquations = listAppend(parameterEquations, simvarasserts);
        parameterEquations = listAppend(parameterEquations, acc);
      then
        (uniqueEqIndex,parameterEquations);
        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"createParameterEquations failed"});
      then fail();
  end matchcontinue;
end createParameterEquations;

protected function traverseAlgorithmFinder "function: traverseAlgorithmFinder
  author: Frenkel TUD 2010-12
  collect all used algorithms"
  input tuple<BackendDAE.Equation, list<DAE.Algorithm>> inTpl;
  output tuple<BackendDAE.Equation, list<DAE.Algorithm>> outTpl;
algorithm
  outTpl := matchcontinue (inTpl)
    local
      BackendDAE.Equation eqn;
      DAE.Algorithm alg;
      list<DAE.Algorithm> algs;
      case ((eqn as BackendDAE.ALGORITHM(alg=alg),algs))
        then
          ((eqn,alg::algs));
    case _ then inTpl;
  end matchcontinue;
end traverseAlgorithmFinder;

protected function createInitialAssignmentsFromStart
  input tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)  
    local
      BackendDAE.Var var;
      BackendDAE.Equation initialEquation;
      list<BackendDAE.Equation> eqns;
      DAE.ComponentRef name;
      DAE.Exp startv;
      DAE.ElementSource source;
      BackendDAE.Variables av;
      
      // also add an assignment for variables that have non-constant
      // expressions, e.g. parameter values, as start.  NOTE: such start
      // attributes can then not be changed in the text file, since the initial
      // calc. will override those entries!    
    case ((var as BackendDAE.VAR(varName=name, source=source),(eqns,av)))
      equation
        SimCode.NOALIAS() = getAliasVar(var,SOME(av));
        startv = BackendVariable.varStartValueFail(var);
        false = Expression.isConst(startv);
        initialEquation = BackendDAE.SOLVED_EQUATION(name, startv, source);
      then
        ((var,(initialEquation :: eqns,av)));
 
    case _ then inTpl;
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
        
    case _
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
        
    case _
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
        
    case _
      then inTpl;
  end matchcontinue;
end createVarMinMaxAssert;

protected function prepareSampleConditions
" function filter sample events 
  and add the corresponding helpVar index to the sample"
  input list<BackendDAE.ZeroCrossing> inSamples;
  input list<SimCode.HelpVarInfo> inHelpVarInfo;
  input list<SimCode.SampleCondition> iSample;
  output list<SimCode.SampleCondition> outSample;
  output list<SimCode.HelpVarInfo> outHelpVarInfo; 
algorithm
  (outSample, outHelpVarInfo) := matchcontinue (inSamples,inHelpVarInfo,iSample)
    local
      list<BackendDAE.ZeroCrossing> rest, accumLst;
      BackendDAE.ZeroCrossing zc;
      DAE.Exp e,e_1;
      SimCode.SampleCondition res;
      Integer indexh;
      list<SimCode.HelpVarInfo> newHelpVars, helpVarInfo;
      
    case ({}, _, _) then (listReverse(iSample),inHelpVarInfo) ;
    case ((zc as BackendDAE.ZERO_CROSSING(relation_ = e as DAE.CALL(path = Absyn.IDENT("sample"))))::rest, _, _)
      equation
        (res,newHelpVars) = addHForConditionSample(e,inHelpVarInfo,listLength(inHelpVarInfo));
        helpVarInfo = listAppend(inHelpVarInfo,newHelpVars);
        (outSample, helpVarInfo) = prepareSampleConditions(rest,helpVarInfo,res::iSample);
      then
        (outSample, helpVarInfo);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"prepareSampleConditions failed"});
      then
        fail();
  end matchcontinue;
end prepareSampleConditions;

protected function updateSamplesConditionsinZC
" function filter sample events 
  and add the corresponding helpVar index to the sample"
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input list<SimCode.HelpVarInfo> inHelpVarInfo;
  input list<SimCode.SampleCondition> iSample;
  input list<BackendDAE.ZeroCrossing> inZeroAccumCrossings;  
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;  
algorithm
  (outZeroCrossings) := matchcontinue (inZeroCrossings,inHelpVarInfo,iSample,inZeroAccumCrossings)
    local
      list<BackendDAE.ZeroCrossing> rest, accumLst;
      BackendDAE.ZeroCrossing zc;
      DAE.Exp e,e_1;
      SimCode.SampleCondition res;
      Integer indexh;
      list<SimCode.HelpVarInfo> newHelpVars, helpVarInfo;
      list<Integer> occurEquLst, occurWhenLst;
      
    case ({}, _, _, _) then (inZeroAccumCrossings) ;
    case ((BackendDAE.ZERO_CROSSING(relation_ = e, occurEquLst=occurEquLst , occurWhenLst=occurWhenLst))::rest, _, _, accumLst)
      equation
        ((e_1,_)) = Expression.traverseExpTopDown(e, traverseSampleAndReplacewithH, inHelpVarInfo);
        accumLst = listAppend(accumLst, {BackendDAE.ZERO_CROSSING(e_1,occurEquLst,occurWhenLst)});        
        (accumLst) = updateSamplesConditionsinZC(rest,inHelpVarInfo,iSample,accumLst);
      then
        (accumLst);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"updateSamplesConditionsinZC failed"});
      then
        fail();
  end matchcontinue;
end updateSamplesConditionsinZC;

protected function addHForConditionSample
  input DAE.Exp icondition;
  input list<SimCode.HelpVarInfo> helpVarInfo;
  input Integer nHelpVar;
  output SimCode.SampleCondition conditionAndHindex;
  output list<SimCode.HelpVarInfo> outhelpVarInfo;
algorithm
  (conditionAndHindex, outhelpVarInfo):=
  matchcontinue (icondition, helpVarInfo, nHelpVar)
    local
      Integer hindex,nh;
      DAE.Exp e;
      list<SimCode.HelpVarInfo> newHelpVar,restHelpVarInfo;
      Absyn.Path name;
      list<DAE.Exp> args_;
      DAE.CallAttributes attr;
      DAE.Exp condition;
      
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

protected function traverseSampleAndReplacewithH
"
  take a sample call and add an index to that.
  author: wbraun
"
  input tuple<DAE.Exp, list<SimCode.HelpVarInfo>> inTpl;
  output tuple<DAE.Exp,  Boolean, list<SimCode.HelpVarInfo>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
  local
    DAE.Exp e, e1;
    list<SimCode.HelpVarInfo> helpVarInfo;
    Absyn.Path name;

    case (((e as DAE.CALL(path = name as Absyn.IDENT("sample"))),helpVarInfo))
      equation
        ((e1,_),{}) = addHForConditionSample(e, helpVarInfo, listLength(helpVarInfo));
      then ((e1, true, helpVarInfo)); 
        
    case ((e,helpVarInfo)) then ((e, true, helpVarInfo));
  end matchcontinue;
end traverseSampleAndReplacewithH;

protected function getZeroCrossings
  input BackendDAE.BackendDAE dlow;
  input Boolean inifcpp;
  output list<BackendDAE.ZeroCrossing> zc;
algorithm
  zc := matchcontinue (dlow, inifcpp)
    
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst=zc))),false)
    then
      zc;

    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(relationsLst=zc))),true)
    then
      zc;
  
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"getZeroCrossings failed"});
      then
        fail();
  end matchcontinue;
end getZeroCrossings;

protected function getSamples
  input BackendDAE.BackendDAE dlow;
  output list<BackendDAE.ZeroCrossing> zc;
algorithm
  zc := matchcontinue (dlow)
    
    case (BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(sampleLst=zc))))
    then
      zc;
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"getSamples failed"});
      then
        fail();
  end matchcontinue;
end getSamples;

protected function createZeroCrossingsNeedSave
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  input BackendDAE.BackendDAE dlow;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.StrongComponents blocks;
  output list<list<SimCode.SimVar>> needSave;
algorithm
  needSave := match (zeroCrossings, dlow, ass1, ass2, blocks)
    local
      BackendDAE.ZeroCrossing zc;
      list<BackendDAE.ZeroCrossing> rest_zc;
      list<Integer> eql;
      list<SimCode.SimVar> needSaveTmp;
      list<list<SimCode.SimVar>> needSave_rest;
      
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
  output list<SimCode.SimVar> needSave;
algorithm
  needSave := matchcontinue (dlow, ass1, ass2, eqns2, blocks)
    local
      list<SimCode.SimVar> crs;
      Integer eqn_1,v,eqn;
      BackendDAE.StrongComponent block_;
      list<Integer> rest;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars, knvars,exvars,av;
      BackendDAE.EquationArray eqns,se,ie;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Var dlowvar;
      SimCode.SimVar simvar;
      
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
  input list<SimCode.Function> functions;
  input list<String> labels;
  input Integer numHelpVars;
  input Integer numInitialEquations;
  input Integer numInitialAlgorithms;
  input String fileDir;
  input Boolean ifcpp;
  output SimCode.ModelInfo modelInfo;
algorithm
  modelInfo :=
  matchcontinue (class_, dlow, functions, labels, numHelpVars, numInitialEquations, numInitialAlgorithms, fileDir,ifcpp)
    local
      String directory;
      SimCode.VarInfo varInfo;
      SimCode.SimVars vars;
      list<SimCode.SimVar> stateVars;
      list<SimCode.SimVar> algVars;
      list<SimCode.SimVar> intAlgVars;
      list<SimCode.SimVar> boolAlgVars;
      list<SimCode.SimVar> inputVars;
      list<SimCode.SimVar> outputVars;
      list<SimCode.SimVar> aliasVars;
      list<SimCode.SimVar> intAliasVars;
      list<SimCode.SimVar> boolAliasVars;
      list<SimCode.SimVar> paramVars;
      list<SimCode.SimVar> intParamVars;
      list<SimCode.SimVar> boolParamVars;
      list<SimCode.SimVar> stringAlgVars;
      list<SimCode.SimVar> stringParamVars;
      list<SimCode.SimVar> stringAliasVars;
      list<SimCode.SimVar> extObjVars;
      list<SimCode.SimVar> constVars;
      list<SimCode.SimVar> intConstVars;
      list<SimCode.SimVar> boolConstVars;
      list<SimCode.SimVar> stringConstVars;
      Integer nx,ny,np,na,next,numOutVars,numInVars,ny_int,np_int,na_int,ny_bool,np_bool,dim_1,dim_2;
      Integer na_bool,ny_string,np_string,na_string;
      list<SimCode.SimVar> states1,states_lst,states_lst2,der_states_lst;
      list<SimCode.SimVar> states_2,derivatives_2,derivative;
    
    case (_, _, _, _, _, _, _, _, true)
      equation
        //name = Absyn.pathStringNoQual(class_);
        directory = System.trim(fileDir, "\"");
        (vars as SimCode.SIMVARS(stateVars=stateVars,derivativeVars=derivative,algVars=algVars,intAlgVars=intAlgVars,boolAlgVars=boolAlgVars,
                       inputVars=inputVars,outputVars=outputVars,aliasVars=aliasVars,intAliasVars=intAliasVars,boolAliasVars=boolAliasVars,
                       paramVars=paramVars,intParamVars=intParamVars,boolParamVars=boolParamVars,stringAlgVars=stringAlgVars,stringParamVars=stringParamVars,
                       stringAliasVars=stringAliasVars,extObjVars=extObjVars,constVars=constVars,intConstVars=intConstVars,boolConstVars=boolConstVars,stringConstVars=stringConstVars))=createVars(dlow);
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
        Debug.fcall(Flags.CPP,print,"create varinfo \n");
        varInfo = createVarInfo(dlow,nx, ny, np, na, next, numOutVars, numInVars, numHelpVars, numInitialEquations, numInitialAlgorithms,
                 ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,dim_1,dim_2);
         Debug.fcall(Flags.CPP,print,"create state index \n");
         states1 = stateindex1(stateVars,dlow);
          Debug.fcall(Flags.CPP,print,"set state index \n");
         states_lst= setStatesVectorIndex(states1);
         Debug.fcall(Flags.CPP,print,"gernerate der states  \n");
         der_states_lst = generateDerStates(states_lst);
         states_lst2 =listAppend(states_lst,der_states_lst);
         Debug.fcall(Flags.CPP,print,"replace index in states \n");
         states_2 = replaceindex1(stateVars,states_lst);
         // Debug.fcall(Flags.CPP_VAR,print," replace der varibales: \n " +&dumpVarinfoList(states_lst2));
          Debug.fcall(Flags.CPP,print,"replace index in der states  \n");
         derivatives_2=replaceindex1(derivative,der_states_lst);
         //Debug.fcall(Flags.CPP_VAR,print,"state varibales: \n " +&dumpVarinfoList(states_lst2));
      then
        SimCode.MODELINFO(class_, directory, varInfo, SimCode.SIMVARS(states_2,derivatives_2,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,
                  intAliasVars,boolAliasVars,paramVars,intParamVars,boolParamVars,stringAlgVars,stringParamVars,stringAliasVars,extObjVars,constVars,intConstVars,boolConstVars,stringConstVars), 
                  functions, labels);
    
    case (_, _, _, _, _, _, _, _, false)
      equation
        //name = Absyn.pathStringNoQual(class_);
        directory = System.trim(fileDir, "\"");
        vars = createVars(dlow);
        SimCode.SIMVARS(stateVars=stateVars,algVars=algVars,intAlgVars=intAlgVars,boolAlgVars=boolAlgVars,
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
        varInfo = createVarInfo(dlow,nx, ny, np, na, next, numOutVars, numInVars, numHelpVars, numInitialEquations, numInitialAlgorithms,
                 ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,0,0);
      then
        SimCode.MODELINFO(class_, directory, varInfo, vars, functions, labels);
    
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
  input Integer numInitialEquations;
  input Integer numInitialAlgorithms;
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
  output SimCode.VarInfo varInfo;
algorithm
  varInfo :=
  matchcontinue (dlow, nx, ny, np, na, next, numOutVars, numInVars, numHelpVars, numInitialEquations, numInitialAlgorithms,
                 ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,dim_1,dim_2)
    local
      Integer ng, ng_sam, ng_rel, numInitialResiduals;
    case (_, _, _, _, _, _, _, _, _, _, _,
                 _, _, _, _, _, _, _, _, _,_,_)
      equation
        (ng, ng_sam, ng_rel) = BackendDAEUtil.numberOfZeroCrossings(dlow);
        ng = filterNg(ng);
        ng_sam = filterNg(ng_sam);
        ng_rel = filterNg(ng_rel);        
        numInitialResiduals = numInitialEquations+numInitialAlgorithms;
      then
        SimCode.VARINFO(numHelpVars, ng, ng_sam, ng_rel, nx, ny, ny_int, ny_bool, na, na_int, na_bool, np, np_int, np_bool, numOutVars, numInVars,
          numInitialEquations, numInitialAlgorithms, numInitialResiduals, next, ny_string, np_string, na_string, 0, 0, SOME(dim_1),SOME(dim_2));
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createVarInfo failed"});
      then
        fail();
  end matchcontinue;
end createVarInfo;

protected function createVars
  input BackendDAE.BackendDAE dlow;
  output SimCode.SimVars varsOut;
algorithm
  varsOut :=
  match (dlow)
    local
      BackendDAE.Variables knvars;
      BackendDAE.Variables removedvars;
      BackendDAE.Variables extvars;
      BackendDAE.EquationArray ie;
      BackendDAE.Variables aliasVars;
      list<DAE.ComponentRef> initCrefs;
      BackendDAE.EqSystems systs;
    case (BackendDAE.DAE(eqs=systs,shared=BackendDAE.SHARED(
      knownVars = knvars, initialEqs=ie,
      externalObjects = extvars,
      aliasVars = aliasVars)))
      equation
        /* Extract from variable list */
        ((varsOut,_,_)) = List.fold1(List.map(systs,BackendVariable.daeVars),BackendVariable.traverseBackendDAEVars,extractVarsFromList,(SimCode.emptySimVars,aliasVars,knvars));
        /* Extract from known variable list */
        ((varsOut,_,_)) = BackendVariable.traverseBackendDAEVars(knvars,extractVarsFromList,(varsOut,aliasVars,knvars));
        /* Extract from removed variable list */
        ((varsOut,_,_)) = BackendVariable.traverseBackendDAEVars(aliasVars,extractVarsFromList,(varsOut,aliasVars,knvars));
        /* Extract from external object list */
        ((varsOut,_,_)) = BackendVariable.traverseBackendDAEVars(extvars,extractVarsFromList,(varsOut,aliasVars,knvars));
        /* sort variables on index */
        varsOut = sortSimvars(stringEqual(Config.simCodeTarget(),"Cpp"),varsOut);
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
  input tuple<BackendDAE.Var, tuple<SimCode.SimVars,BackendDAE.Variables,BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<SimCode.SimVars,BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:= matchcontinue (inTpl)      
    local
      BackendDAE.Var var;
      SimCode.SimVars vars;
      BackendDAE.Variables aliasVars,v;
    case ((var,(vars,aliasVars,v)))
      equation
        vars = extractVarFromVar(var,aliasVars,v,vars);
      then
        ((var,(vars,aliasVars,v)));
    else then inTpl;
  end matchcontinue;
end extractVarsFromList;

// one dlow var can result in multiple simvars: input and output are a subset
// of algvars for example
protected function extractVarFromVar
  input BackendDAE.Var dlowVar;
  input BackendDAE.Variables inAliasVars;
  input BackendDAE.Variables inVars;
  input SimCode.SimVars varsIn;
  output SimCode.SimVars varsOut;
algorithm
  varsOut :=
  match (dlowVar,inAliasVars,inVars,varsIn)
    local
      list<SimCode.SimVar> stateVars;
      list<SimCode.SimVar> derivativeVars;
      list<SimCode.SimVar> algVars;
      list<SimCode.SimVar> intAlgVars;
      list<SimCode.SimVar> boolAlgVars;
      list<SimCode.SimVar> inputVars;
      list<SimCode.SimVar> outputVars;
      list<SimCode.SimVar> aliasVars;
      list<SimCode.SimVar> intAliasVars;
      list<SimCode.SimVar> boolAliasVars;
      list<SimCode.SimVar> paramVars;
      list<SimCode.SimVar> intParamVars;
      list<SimCode.SimVar> boolParamVars;
      list<SimCode.SimVar> stringAlgVars;
      list<SimCode.SimVar> stringParamVars;
      list<SimCode.SimVar> stringAliasVars;
      list<SimCode.SimVar> extObjVars;
      list<SimCode.SimVar> constVars;
      list<SimCode.SimVar> intConstVars;
      list<SimCode.SimVar> boolConstVars;
      list<SimCode.SimVar> stringConstVars;
      SimCode.SimVar simvar;
      SimCode.SimVar derivSimvar;
      BackendDAE.Variables v;
      Boolean isalias;
    case (_,_,v,
      SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars,
          aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
          stringAlgVars, stringParamVars, stringAliasVars, extObjVars,constVars,intConstVars,boolConstVars,stringConstVars))
      equation
        /* extract the sim var */
        simvar = dlowvarToSimvar(dlowVar,SOME(inAliasVars),v);
        derivSimvar = derVarFromStateVar(simvar);
        isalias = isAliasVar(simvar);
        /* figure out in which lists to put it */
        stateVars = List.consOnTrue((not isalias) and
          BackendVariable.isStateVar(dlowVar), simvar, stateVars);
        derivativeVars = List.consOnTrue((not isalias) and
          BackendVariable.isStateVar(dlowVar), derivSimvar, derivativeVars);
        algVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarAlg(dlowVar), simvar, algVars);
        intAlgVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarIntAlg(dlowVar), simvar, intAlgVars);
        boolAlgVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarBoolAlg(dlowVar), simvar, boolAlgVars);
        inputVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarOnTopLevelAndInput(dlowVar), simvar, inputVars);
        outputVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarOnTopLevelAndOutput(dlowVar), simvar, outputVars);
        paramVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarParam(dlowVar), simvar, paramVars);
        intParamVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarIntParam(dlowVar), simvar, intParamVars);
        boolParamVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarBoolParam(dlowVar), simvar, boolParamVars);
        stringAlgVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarStringAlg(dlowVar), simvar, stringAlgVars);
        stringParamVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarStringParam(dlowVar), simvar, stringParamVars);
        extObjVars = List.consOnTrue((not isalias) and
          BackendVariable.isExtObj(dlowVar), simvar, extObjVars);
        aliasVars = List.consOnTrue( isalias and
          BackendVariable.isVarAlg(dlowVar), simvar, aliasVars);
        intAliasVars = List.consOnTrue( isalias and
          BackendVariable.isVarIntAlg(dlowVar), simvar, intAliasVars);
        boolAliasVars = List.consOnTrue( isalias and
          BackendVariable.isVarBoolAlg(dlowVar), simvar, boolAliasVars);
        stringAliasVars = List.consOnTrue( isalias and
          BackendVariable.isVarStringAlg(dlowVar), simvar, stringAliasVars);
        constVars =List.consOnTrue((not isalias) and
          BackendVariable.isVarConst(dlowVar), simvar, constVars);
        intConstVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarIntConst(dlowVar), simvar, intConstVars);
        boolConstVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarBoolConst(dlowVar), simvar, boolConstVars);
        stringConstVars = List.consOnTrue((not isalias) and
          BackendVariable.isVarStringConst(dlowVar), simvar, stringConstVars);
      then
        SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars,
          aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
          stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars);
  end match;
end extractVarFromVar;

protected function derVarFromStateVar
  input SimCode.SimVar state;
  output SimCode.SimVar deriv;
algorithm
  deriv :=
  match (state)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind kind;
      String comment, unit, displayUnit;
      Integer index;
      Option<DAE.Exp> minVal, maxVal;
      Option<DAE.Exp> initVal, nomVal;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      DAE.ComponentRef arrayCref;
      DAE.ElementSource source;
      list<String> numArrayElement;
    case (SimCode.SIMVAR(name, kind, comment, unit, displayUnit, index, minVal, maxVal, initVal, nomVal, isFixed, type_, isDiscrete, NONE(),_, source,_,NONE(),numArrayElement))
      equation
        name = ComponentReference.crefPrefixDer(name);
      then
        SimCode.SIMVAR(name, BackendDAE.STATE_DER(), comment, unit, displayUnit, index, minVal, maxVal, NONE(), nomVal, isFixed, type_, isDiscrete, NONE(), SimCode.NOALIAS(), source, SimCode.INTERNAL(),NONE(),numArrayElement);
    case (SimCode.SIMVAR(name, kind, comment, unit, displayUnit, index, minVal, maxVal, initVal, nomVal, isFixed, type_, isDiscrete, SOME(arrayCref),_, source,_,NONE(),numArrayElement))
      equation
        name = ComponentReference.crefPrefixDer(name);
        arrayCref = ComponentReference.crefPrefixDer(arrayCref);
      then
        SimCode.SIMVAR(name, BackendDAE.STATE_DER(), comment, unit, displayUnit, index, minVal, maxVal, NONE(), nomVal, isFixed, type_, isDiscrete, SOME(arrayCref), SimCode.NOALIAS(), source, SimCode.INTERNAL(),NONE(),numArrayElement);
  end match;
end derVarFromStateVar;


protected function dumpVar
  input SimCode.SimVar inVar;
algorithm
  _ := matchcontinue(inVar)
  local
    DAE.ComponentRef name,name2;
    SimCode.AliasVariable aliasvar;
    String s1,s2;
    case (SimCode.SIMVAR(name= name, aliasvar = SimCode.NOALIAS()))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        print(" No Alias for var : " +& s1 +& "\n");
     then ();
    case (SimCode.SIMVAR(name= name, aliasvar = SimCode.ALIAS(varName = name2)))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        s2 = ComponentReference.printComponentRefStr(name2);
        print(" Alias for var " +& s1 +& " is " +& s2 +& "\n");
    then ();
    case (SimCode.SIMVAR(name= name, aliasvar = SimCode.NEGATEDALIAS(varName = name2)))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        s2 = ComponentReference.printComponentRefStr(name2);
        print(" Minus Alias for var " +& s1 +& " is " +& s2 +& "\n");
     then ();
   end matchcontinue;
end dumpVar;

protected function isAliasVar
  input SimCode.SimVar var;
  output Boolean res;
algorithm
  res :=
  match (var)
    case (SimCode.SIMVAR(aliasvar=SimCode.NOALIAS()))
    then false;
  else
    then true;
  end match;
end isAliasVar;

protected function sortSimvars
  input Boolean isCpp;
  input SimCode.SimVars unsortedSimvars;
  output SimCode.SimVars sortedSimvars;
algorithm
  sortedSimvars :=
  match (isCpp,unsortedSimvars)
    local
      list<SimCode.SimVar> stateVars;
      list<SimCode.SimVar> derivativeVars;
      list<SimCode.SimVar> algVars;
      list<SimCode.SimVar> intAlgVars;
      list<SimCode.SimVar> boolAlgVars;
      list<SimCode.SimVar> inputVars;
      list<SimCode.SimVar> outputVars;
      list<SimCode.SimVar> aliasVars;
      list<SimCode.SimVar> intAliasVars;
      list<SimCode.SimVar> boolAliasVars;
      list<SimCode.SimVar> paramVars;
      list<SimCode.SimVar> intParamVars;
      list<SimCode.SimVar> boolParamVars;
      list<SimCode.SimVar> stringAlgVars;
      list<SimCode.SimVar> stringParamVars;
      list<SimCode.SimVar> stringAliasVars;
      list<SimCode.SimVar> extObjVars;
      list<SimCode.SimVar> constVars;
      list<SimCode.SimVar> intConstVars;
      list<SimCode.SimVar> boolConstVars;
      list<SimCode.SimVar> stringConstVars;
      HashSet.HashSet set;
    // runtime CPP, there it is not necesarry to sort the arrays because different memory management
    case (true,SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars))
      equation 
        // but for runtime CPP also the incomplete arrays need one special element to generate the array 
        // search all arrays with array information
        set = HashSet.emptyHashSet();
        set = List.fold(stateVars,collectArrayFirstVars,set);
        set = List.fold(derivativeVars,collectArrayFirstVars,set);
        set = List.fold(algVars,collectArrayFirstVars,set);
        set = List.fold(intAlgVars,collectArrayFirstVars,set);
        set = List.fold(boolAlgVars,collectArrayFirstVars,set);
        set = List.fold(inputVars,collectArrayFirstVars,set);
        set = List.fold(outputVars,collectArrayFirstVars,set);
        set = List.fold(aliasVars,collectArrayFirstVars,set);
        set = List.fold(intAliasVars,collectArrayFirstVars,set);
        set = List.fold(boolAliasVars,collectArrayFirstVars,set);
        set = List.fold(paramVars,collectArrayFirstVars,set);
        set = List.fold(intParamVars,collectArrayFirstVars,set);
        set = List.fold(boolParamVars,collectArrayFirstVars,set);
        set = List.fold(stringAlgVars,collectArrayFirstVars,set);
        set = List.fold(stringParamVars,collectArrayFirstVars,set);
        set = List.fold(stringAliasVars,collectArrayFirstVars,set);
        set = List.fold(extObjVars,collectArrayFirstVars,set);
        set = List.fold(constVars,collectArrayFirstVars,set);
        set = List.fold(intConstVars,collectArrayFirstVars,set);
        set = List.fold(boolConstVars,collectArrayFirstVars,set);
        set = List.fold(stringConstVars,collectArrayFirstVars,set);
        // add array information to incomplete arrays
        (stateVars,set) = List.mapFold(stateVars,setArrayElementnoFirst, set);
        (derivativeVars,set) = List.mapFold(derivativeVars,setArrayElementnoFirst, set);
        (algVars,set) = List.mapFold(algVars,setArrayElementnoFirst, set);
        (intAlgVars,set) = List.mapFold(intAlgVars,setArrayElementnoFirst, set);
        (boolAlgVars,set) = List.mapFold(boolAlgVars,setArrayElementnoFirst, set);
        (inputVars,set) = List.mapFold(inputVars,setArrayElementnoFirst, set);
        (outputVars,set) = List.mapFold(outputVars,setArrayElementnoFirst, set);
        (aliasVars,set) = List.mapFold(aliasVars,setArrayElementnoFirst, set);
        (intAliasVars,set) = List.mapFold(intAliasVars,setArrayElementnoFirst, set);
        (boolAliasVars,set) = List.mapFold(boolAliasVars,setArrayElementnoFirst, set);
        (paramVars,set) = List.mapFold(paramVars,setArrayElementnoFirst, set);
        (intParamVars,set) = List.mapFold(intParamVars,setArrayElementnoFirst, set);
        (boolParamVars,set) = List.mapFold(boolParamVars,setArrayElementnoFirst, set);
        (stringAlgVars,set) = List.mapFold(stringAlgVars,setArrayElementnoFirst, set);
        (stringParamVars,set) = List.mapFold(stringParamVars,setArrayElementnoFirst, set);
        (stringAliasVars,set) = List.mapFold(stringAliasVars,setArrayElementnoFirst, set);
        (extObjVars,set) = List.mapFold(extObjVars,setArrayElementnoFirst, set);
        (constVars,set) = List.mapFold(constVars,setArrayElementnoFirst, set);
        (intConstVars,set) = List.mapFold(intConstVars,setArrayElementnoFirst, set);
        (boolConstVars,set) = List.mapFold(boolConstVars,setArrayElementnoFirst, set);
        (stringConstVars,set) = List.mapFold(stringConstVars,setArrayElementnoFirst, set);        
      then SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
        outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
        stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars);
    // other runtimes
    case (_,SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars))
      equation
        stateVars = sortSimVars1(stateVars);
        derivativeVars = sortSimVars1(derivativeVars);
        algVars = sortSimVars1(algVars);
        intAlgVars = sortSimVars1(intAlgVars);
        boolAlgVars = sortSimVars1(boolAlgVars);
        inputVars = sortSimVars1(inputVars);
        outputVars = sortSimVars1(outputVars);
        aliasVars = sortSimVars1(aliasVars);
        intAliasVars = sortSimVars1(intAliasVars);
        boolAliasVars = sortSimVars1(boolAliasVars);
        paramVars = sortSimVars1(paramVars);
        intParamVars = sortSimVars1(intParamVars);
        boolParamVars = sortSimVars1(boolParamVars);
        stringAlgVars = sortSimVars1(stringAlgVars);
        stringParamVars = sortSimVars1(stringParamVars);
        stringAliasVars = sortSimVars1(stringAliasVars);
        extObjVars = sortSimVars1(extObjVars);
        constVars = sortSimVars1(constVars);
        intConstVars = sortSimVars1(intConstVars);
        boolConstVars = sortSimVars1(boolConstVars);
        stringConstVars = sortSimVars1(stringConstVars);
        
      then SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
        outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
        stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars);
  end match;
end sortSimvars;

protected function setArrayElementnoFirst
"function: setArrayElementnoFirst
  author: Frenkel TUD 2012-10"
  input SimCode.SimVar iVar;
  input HashSet.HashSet iSet;
  output SimCode.SimVar oVar;
  output HashSet.HashSet oSet;
algorithm
  (oVar,oSet) := matchcontinue(iVar,iSet)
    local
      DAE.ComponentRef cr;
      SimCode.SimVar var;
      HashSet.HashSet set;
    case (SimCode.SIMVAR(name=cr,arrayCref=SOME(_)),_)
      then
       (iVar,iSet);
    case (SimCode.SIMVAR(name=cr,numArrayElement=_::_,arrayCref=NONE()),_)
      equation
        _::_ = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        false = BaseHashSet.has(cr,iSet);
        var = addSimVarArrayCref(iVar,cr);
        set = BaseHashSet.add(cr, iSet);
      then
       (var,set);
    else then (iVar,iSet);
  end matchcontinue;
end setArrayElementnoFirst;

protected function addSimVarArrayCref
"function: addSimVarArrayCref
  author: Frenkel TUD 2012-10"
  input SimCode.SimVar iVar;
  input DAE.ComponentRef arrayCref;
  output SimCode.SimVar oVar;
algorithm
  oVar := match(iVar,arrayCref)
    local
      DAE.ComponentRef cr;
      DAE.ComponentRef name;
      BackendDAE.VarKind varKind;
      String comment,unit,displayUnit;
      Integer index;
      Option<DAE.Exp> minValue,maxValue,initialValue,nominalValue;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      SimCode.AliasVariable aliasvar;
      DAE.ElementSource source;
      SimCode.Causality causality;
      Option<Integer> variable_index;
      list<String> numArrayElement;      
    case (SimCode.SIMVAR(name=cr,varKind=varKind,comment=comment,unit=unit,displayUnit=displayUnit,index=index,
                         minValue=minValue,maxValue=maxValue,initialValue=initialValue,nominalValue=nominalValue,
                         isFixed=isFixed,type_=type_,isDiscrete=isDiscrete,aliasvar=aliasvar,source=source,
                         causality=causality,variable_index=variable_index,numArrayElement=numArrayElement),_)
      then
        SimCode.SIMVAR(cr,varKind,comment,unit,displayUnit,index,
                         minValue,maxValue,initialValue,nominalValue,
                         isFixed,type_,isDiscrete,SOME(arrayCref),aliasvar,source,
                         causality,variable_index,numArrayElement);
  end match;
end addSimVarArrayCref;

protected function collectArrayFirstVars
"function: collectArrayFirstVars
  author: Frenkel TUD 2012-10"
  input SimCode.SimVar var;
  input HashSet.HashSet iSet;
  output HashSet.HashSet oSet;
algorithm
  oSet := match(var,iSet)
    local
      DAE.ComponentRef cr;
    case (SimCode.SIMVAR(name=cr,arrayCref=SOME(_)),_)
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
      then
        BaseHashSet.add(cr, iSet);
    else then iSet;
  end match;
end collectArrayFirstVars;

protected function sortSimVars1
"function: sortSimVars1
  author: Frenkel TUD 2012-09"
  input list<SimCode.SimVar> unsorted;
  output list<SimCode.SimVar> sorted; 
protected
  list<SimCode.SimVar> vars;
  HashTableCrSimVars.HashTable ht;
  list<list<SimCode.SimVar>> varslstlst;      
algorithm
  // extract Array SimCode.SimVars from List
  ht := HashTableCrSimVars.emptyHashTable();
 (vars,ht) := extractArrayVars(unsorted,{},ht);
  // sort array vars
  varslstlst := BaseHashTable.hashTableValueList(ht);
  sorted := sortSimVars2(varslstlst,vars);
end sortSimVars1;

protected function extractArrayVars
"function: extractArrayVars
  author: Frenkel TUD 2012-09"
  input list<SimCode.SimVar> inVars;
  input list<SimCode.SimVar> iscalarVars;
  input HashTableCrSimVars.HashTable iHt;
  output list<SimCode.SimVar> scalarVars;
  output HashTableCrSimVars.HashTable oHt;
algorithm
  (scalarVars,oHt) := match(inVars,iscalarVars,iHt)
    local
      HashTableCrSimVars.HashTable ht;
      SimCode.SimVar var;
      list<SimCode.SimVar> rest,vars;
      DAE.ComponentRef cr,crnosub;
    case ({},_,_) 
      then
        (iscalarVars,iHt);       
    case((var as SimCode.SIMVAR(name=cr,numArrayElement=_::_))::rest,_,_)
      equation
        crnosub = ComponentReference.crefStripLastSubs(cr);
        ht = addSimVarHashTableCrSimVars(crnosub,var,iHt);
        (vars,ht) = extractArrayVars(rest,iscalarVars,ht);
      then 
        (vars,ht);
    case(var::rest,_,_)
      equation
        (vars,ht) = extractArrayVars(rest,var::iscalarVars,iHt);
      then 
        (vars,ht); 
  end match;
end extractArrayVars;

protected function addSimVarHashTableCrSimVars
"function: addSimVarHashTableCrSimVars
  author: Frenkel TUD 2012-09"
  input DAE.ComponentRef crnosub;
  input SimCode.SimVar var;
  input HashTableCrSimVars.HashTable iHt;
  output HashTableCrSimVars.HashTable oHt;
algorithm
  oHt := matchcontinue(crnosub,var,iHt)
    local
      DAE.ComponentRef cr;
      list<SimCode.SimVar> varlst;
      HashTableCrSimVars.HashTable ht;
    case (_,_,_)
      equation
        varlst = BaseHashTable.get(crnosub,iHt);
        ht = BaseHashTable.add((crnosub,var::varlst), iHt);
      then
        ht;
    case(_,_,_)
      equation
        ht = BaseHashTable.add((crnosub,{var}), iHt);
      then
        ht;
  else
    equation
      print("SimCodeUtil.addSimVarHashTableCrSimVars failed!\n");
    then
      fail();        
  end matchcontinue;
end addSimVarHashTableCrSimVars;

protected function sortSimVars2
"function: sortSimVars2
  author: Frenkel TUD 2012-09"
  input list<list<SimCode.SimVar>> varlstlst;
  input list<SimCode.SimVar> iVars;
  output list<SimCode.SimVar> sortedVars;
algorithm
  sortedVars := match(varlstlst,iVars)
    local
      list<list<SimCode.SimVar>> rest;
      list<SimCode.SimVar> unsorted,sorted;
      SimCode.SimVar var;
    case ({},_)
      then
        iVars; 
    case (({})::rest,_)
      then
        sortSimVars2(rest,iVars);
    // only on element, no sort needed
    case ((var::{})::rest,_)
      then
        sortSimVars2(rest,var::iVars);
    case (unsorted::rest,_)
      equation
        sorted = sortArrayVars(unsorted,iVars);
      then
        sortSimVars2(rest,sorted);
  end match;
end sortSimVars2;

protected function sortArrayVars
"function: sortArrayVars
  author: Frenkel TUD 2012-09"
  input list<SimCode.SimVar> varlst;
  input list<SimCode.SimVar> iVars;
  output list<SimCode.SimVar> sortedVars;
algorithm
  sortedVars := matchcontinue(varlst,iVars)
    local
      array<Option<SimCode.SimVar>> vararray;
      DAE.ComponentRef cr;
      DAE.Type tp;
      Integer size,listsize;
      DAE.Dimensions dims;
      list<Integer> dimsint;
      
      String crstr;
    case (_,_)
      equation
        SimCode.SIMVAR(name=cr)::_ = varlst;
        // get last type
        tp = ComponentReference.crefLastType(cr);
        // get size of last type
        size = Expression.sizeOf(tp);
        listsize = listLength(varlst);
        // only sort if all vars there
        true = intEq(size,listsize);
        // alloc the array 
        vararray = arrayCreate(size,NONE());
        // insert vars in array
        dims = Expression.arrayDimension(tp);
        dimsint = Expression.dimensionsSizes(dims);
        vararray = List.fold1(varlst,insertArrayVars,dimsint,vararray);
        // get vars from array sorted
        sortedVars = getVarsFromArray(size,vararray,iVars);
     then
        sortedVars;
  case (_,_)
    equation
      SimCode.SIMVAR(name=cr)::_ = varlst;
      crstr = ComponentReference.printComponentRefStr(cr);
      Debug.fprintln(Flags.FAILTRACE, "SimCodeUtil.sortArrayVars failed on " +& crstr +& "\n");
      //sortedVars = List.sort(varlst,comparingArrayVarsIndexes);
      sortedVars = varlst;
      sortedVars = listAppend(sortedVars,iVars);
    then
      sortedVars; 
  else
    equation
      print("SimCodeUtil.sortArrayVars failed!\n");
    then
      fail();     
  end matchcontinue;   
end sortArrayVars;

protected function comparingArrayVarsIndexes1
"function: comparingArrayVarsIndexes1
  author: Frenkel TUD
  Helper function for comparingArrayVarsIndexes.
  Check if a element of a non scalar has his place
  before or after another element in a one
  dimensional array."
  input list<Integer> inlist;
  input list<Integer> inlist1;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (inlist, inlist1)
    local
      list<Integer> index,index1;
      Integer val1,val2;
    case ({},_) then true;
    case (val1::index,val2::index1)
      equation
        true = intEq(val1,val2);
      then
       comparingArrayVarsIndexes1(index,index1);
    case (val1::index,val2::index1)
      then
       val1 > val2;
  end matchcontinue;
end comparingArrayVarsIndexes1;

protected function comparingArrayVarsIndexes
"function: comparingArrayVarsIndexes
  author: Frenkel TUD
  Comparing two NonScalars.
  Example:  A[2,2],A[1,1] -> {A[1,1],A[2,2]}"
  input SimCode.SimVar invar1;
  input SimCode.SimVar invar2;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (invar1,invar2)
    local
      DAE.ComponentRef varName1, varName2;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
    case (SimCode.SIMVAR(name = varName1),SimCode.SIMVAR(name = varName2))
      equation
        subscriptLst = ComponentReference.crefLastSubs(varName1);
        subscriptLst1 = ComponentReference.crefLastSubs(varName2);
      then
        comparingArrayVarsIndexes1(Expression.subscriptsInt(subscriptLst),Expression.subscriptsInt(subscriptLst1));
    case (_,_) then true;
  end matchcontinue;
end comparingArrayVarsIndexes;

protected function getVarsFromArray
"function: getVarsFromArray
  author: Frenkel TUD 2012-09"
  input Integer index;
  input array<Option<SimCode.SimVar>> arr;
  input list<SimCode.SimVar> iVars;
  output list<SimCode.SimVar> sortedVars;
algorithm
  sortedVars := matchcontinue(index,arr,iVars)
    local
      SimCode.SimVar var;
    case (_,_,_)
      equation
        true = intGt(index,0);
        SOME(var) = arr[index];
      then
        getVarsFromArray(index-1,arr,var::iVars);
    case (_,_,_)
      equation
        true = intGt(index,0);
      then
        getVarsFromArray(index-1,arr,iVars);
    case (_,_,_)
      then
        iVars;
  end matchcontinue;  
end getVarsFromArray;

protected function insertArrayVars
"function: insertArrayVars
  author: Frenkel TUD 2012-09"
  input SimCode.SimVar var;
  input list<Integer> dims;
  input array<Option<SimCode.SimVar>> iarr;
  output array<Option<SimCode.SimVar>> oarr;
protected
  array<Option<SimCode.SimVar>> vararray;
  DAE.ComponentRef cr;
  list<DAE.Subscript> subscriptLst;
  list<Integer> indexes;
  Integer index;
algorithm
  // get Subscripts
  SimCode.SIMVAR(name=cr) := var;
  subscriptLst := ComponentReference.crefLastSubs(cr);
  indexes := Expression.subscriptsInt(subscriptLst);
  // print("ArrayLength " +& intString(arrayLength(iarr)) +& " : " +& stringDelimitList(List.map(subscriptLst,ExpressionDump.subscriptString),", ") +& "\n");   
  // print("indexes " +& stringDelimitList(List.map(indexes,intString),", ") +& "\n");   
  // print("dims " +& stringDelimitList(List.map(dims,intString),", ") +& "\n");   
  // calculate Place in Array
  index := calculateIndex(indexes,dims);
  // print("index " +& intString(index) +& "\n");   
  // insert Var in array
  oarr := arrayUpdate(iarr,index,SOME(var));
end insertArrayVars;

protected function calculateIndex
"function: calculateIndex
  author: Frenkel TUD 2012-09
  Helper function for insertArrayVars.
  Calculate based on the dimensions and the
  indexes the place of the element in a one
  dimensional array."
  input list<Integer> inindex;
  input list<Integer> dimlist;
  output Integer value;
algorithm
  value:=
  matchcontinue (inindex,dimlist)
    local
      list<Integer> index_lst,dim_lst;
      Integer value1,index,dim;
    case ({},{}) then 1;
    case (index::{},_) then index;
    case (index::index_lst,dim::dim_lst)
      equation
        value = calculateIndex(index_lst,dim_lst);
        value1 = List.fold(dim_lst,intMul,1);
        value1 = value + (index-1)*value1;
      then
        value1;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCodeUtil.calculateIndex failed\n"});
      then
        fail();
  end matchcontinue;
end calculateIndex;

protected function fixIndex
  input SimCode.SimVars unfixedSimvars;
  output SimCode.SimVars fixedSimvars;
algorithm
  fixedSimvars := match (unfixedSimvars)
    local
      list<SimCode.SimVar> stateVars;
      list<SimCode.SimVar> derivativeVars;
      list<SimCode.SimVar> algVars;
      list<SimCode.SimVar> intAlgVars;
      list<SimCode.SimVar> boolAlgVars;
      list<SimCode.SimVar> inputVars;
      list<SimCode.SimVar> outputVars;
      list<SimCode.SimVar> aliasVars;
      list<SimCode.SimVar> intAliasVars;
      list<SimCode.SimVar> boolAliasVars;
      list<SimCode.SimVar> paramVars;
      list<SimCode.SimVar> intParamVars;
      list<SimCode.SimVar> boolParamVars;
      list<SimCode.SimVar> stringAlgVars;
      list<SimCode.SimVar> stringParamVars;
      list<SimCode.SimVar> stringAliasVars;
      list<SimCode.SimVar> extObjVars;
      list<SimCode.SimVar> constVars;
      list<SimCode.SimVar> intConstVars;
      list<SimCode.SimVar> boolConstVars;
      list<SimCode.SimVar> stringConstVars;
  
      
    case (SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars,intConstVars, boolConstVars,stringConstVars))
      equation
        stateVars = rewriteIndex(stateVars, 0);
        derivativeVars = rewriteIndex(derivativeVars, 0);
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
        constVars = rewriteIndex(constVars, 0);
        intConstVars = rewriteIndex(intConstVars, 0);
        boolConstVars = rewriteIndex(boolConstVars, 0);
        stringConstVars = rewriteIndex(stringConstVars, 0);
        extObjVars = rewriteIndex(extObjVars, 0);
        inputVars = rewriteIndex(inputVars, 0);
        outputVars = rewriteIndex(outputVars, 0);
      then SimCode.SIMVARS(stateVars, derivativeVars, algVars,intAlgVars, boolAlgVars, inputVars,
        outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
        stringAlgVars, stringParamVars, stringAliasVars, extObjVars,constVars,intConstVars,boolConstVars,stringConstVars);
  end match;
end fixIndex;

protected function rewriteIndex
  input list<SimCode.SimVar> inVars;
  input Integer iindex;
  output list<SimCode.SimVar> outVars;
algorithm 
  outVars :=
  match(inVars,iindex)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind kind;
      String comment, unit, displayUnit;
      Option<DAE.Exp> minVal, maxVal;
      Option<DAE.Exp> initVal, nomVal;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      Integer index_;
      SimCode.AliasVariable aliasvar;
      list<SimCode.SimVar> rest,rest2;
      DAE.ElementSource source;
      SimCode.Causality causality;
      list<String> numArrayElement;
      Integer index;
      
    case ({},_) then {};
    case (SimCode.SIMVAR(name, kind, comment, unit, displayUnit, index, minVal, maxVal, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement)::rest,index_)
      equation
        rest2 = rewriteIndex(rest, index_ + 1);
      then (SimCode.SIMVAR(name, kind, comment, unit, displayUnit, index_, minVal, maxVal, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement)::rest2);
  end match;
end rewriteIndex;

protected function varIndexComparer
  input SimCode.SimVar lhs;
  input SimCode.SimVar rhs;
  output Boolean res;
algorithm
  res :=
  match (lhs, rhs)
    local
      Integer lhsIndex;
      Integer rhsIndex;
      DAE.ComponentRef cr1,cr2;
    case (SimCode.SIMVAR(name=cr1,index=lhsIndex), SimCode.SIMVAR(name=cr2,index=rhsIndex))
      equation
        res = rhsIndex < lhsIndex;
      then res;
  end match;
end varIndexComparer;

protected function fixInitialThing
  input SimCode.SimVars simvarsIn;
  input list<DAE.ComponentRef> initCrefs;
  output SimCode.SimVars simvarsOut;
algorithm
  simvarsOut :=
  matchcontinue (simvarsIn, initCrefs)
    local
      list<SimCode.SimVar> stateVars;
      list<SimCode.SimVar> derivativeVars;
      list<SimCode.SimVar> algVars;
      list<SimCode.SimVar> intAlgVars;
      list<SimCode.SimVar> boolAlgVars;
      list<SimCode.SimVar> inputVars;
      list<SimCode.SimVar> outputVars;
      list<SimCode.SimVar> aliasVars;
      list<SimCode.SimVar> intAliasVars;
      list<SimCode.SimVar> boolAliasVars;
      list<SimCode.SimVar> paramVars;
      list<SimCode.SimVar> intParamVars;
      list<SimCode.SimVar> boolParamVars;
      list<SimCode.SimVar> stringAlgVars;
      list<SimCode.SimVar> stringParamVars;
      list<SimCode.SimVar> stringAliasVars;
      list<SimCode.SimVar> extObjVars;
      list<SimCode.SimVar> constVars;
      list<SimCode.SimVar> intConstVars;
      list<SimCode.SimVar> boolConstVars;
      list<SimCode.SimVar> stringConstVars;
      /* no initial equations so nothing to do */
    case (_, {}) then simvarsIn;
    case (SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars, 
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars), _)
      equation
        true = List.mapAllValueBool(stateVars, simvarFixed,true);
        stateVars = List.map1(stateVars, nonFixifyIfHasInit, initCrefs);
      then SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
        outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars, 
        stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars);
      /* not all were fixed so nothing to do */
    else simvarsIn;
  end matchcontinue;
end fixInitialThing;

protected function simvarFixed
  input SimCode.SimVar simvar;
  output Boolean fixed_;
algorithm
  fixed_ :=
  match (simvar)
    case (SimCode.SIMVAR(isFixed=fixed_)) then fixed_;
    case (_) then fail();
  end match;
end simvarFixed;

protected function nonFixifyIfHasInit
  input SimCode.SimVar simvarIn;
  input list<DAE.ComponentRef> initCrefs;
  output SimCode.SimVar simvarOut;
algorithm
  simvarOut :=
  matchcontinue (simvarIn, initCrefs)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind kind;
      String comment, unit, displayUnit;
      Integer index;
      Option<DAE.Exp> minVal, maxVal;
      Option<DAE.Exp> initVal, nomVal;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      SimCode.AliasVariable aliasvar;
      String varNameStr;
      DAE.ElementSource source;
      Absyn.Info info;
      SimCode.Causality causality;
      list<String> numArrayElement;
    case (SimCode.SIMVAR(name, kind, comment, unit, displayUnit, index, minVal, maxVal, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement), _)
      equation
        (_ :: _) = List.select1(initCrefs, ComponentReference.crefEqualNoStringCompare, name);
        varNameStr = ComponentReference.printComponentRefStr(name);
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.SETTING_FIXED_ATTRIBUTE, {varNameStr}, info);
      then SimCode.SIMVAR(name, kind, comment, unit, displayUnit, index, minVal, maxVal, initVal, nomVal, false, type_, isDiscrete, arrayCref, aliasvar, source, causality,NONE(),numArrayElement);
    case (_, _) then simvarIn;
  end matchcontinue;
end nonFixifyIfHasInit;


protected function createCrefToSimVarHT
  input SimCode.ModelInfo modelInfo;
  output SimCode.HashTableCrefToSimVar outHT;
algorithm
  outHT :=  matchcontinue (modelInfo)
    local
      SimCode.HashTableCrefToSimVar ht;
      list<SimCode.SimVar> stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, aliasVars, intAliasVars, boolAliasVars, stringAliasVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, extObjVars,constVars,intConstVars,boolConstVars,stringConstVars;
    case (SimCode.MODELINFO(vars = SimCode.SIMVARS(
      stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, 
      _/*inputVars*/, _/*outputVars*/, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars, 
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars)))
      equation
        ht = emptyHashTable();
        ht = List.fold(stateVars, addSimVarToHashTable, ht);
        ht = List.fold(derivativeVars, addSimVarToHashTable, ht);
        ht = List.fold(algVars, addSimVarToHashTable, ht);
        ht = List.fold(intAlgVars, addSimVarToHashTable, ht);
        ht = List.fold(boolAlgVars, addSimVarToHashTable, ht);
        ht = List.fold(paramVars, addSimVarToHashTable, ht);
        ht = List.fold(intParamVars, addSimVarToHashTable, ht);
        ht = List.fold(boolParamVars, addSimVarToHashTable, ht);
        ht = List.fold(aliasVars, addSimVarToHashTable, ht);
        ht = List.fold(intAliasVars, addSimVarToHashTable, ht);
        ht = List.fold(boolAliasVars, addSimVarToHashTable, ht);
        ht = List.fold(stringAlgVars, addSimVarToHashTable, ht);
        ht = List.fold(stringParamVars, addSimVarToHashTable, ht);
        ht = List.fold(stringAliasVars, addSimVarToHashTable, ht);
        ht = List.fold(extObjVars, addSimVarToHashTable, ht);
        ht = List.fold(constVars, addSimVarToHashTable, ht);
        ht = List.fold(intConstVars, addSimVarToHashTable, ht);
        ht = List.fold(boolConstVars, addSimVarToHashTable, ht);
        ht = List.fold(stringConstVars, addSimVarToHashTable, ht);
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
  input SimCode.SimVar simvarIn;
  input  SimCode.HashTableCrefToSimVar inHT;
  output SimCode.HashTableCrefToSimVar outHT;
algorithm
  outHT :=
  matchcontinue (simvarIn, inHT)
    local
      DAE.ComponentRef cr, acr;
      SimCode.SimVar sv;
      
    case (sv as SimCode.SIMVAR(name = cr, arrayCref = NONE()), _)
      equation
        outHT = add((cr,sv), inHT);
      then outHT;
        //add the whole array crefs to the hashtable, too
    case (sv as SimCode.SIMVAR(name = cr, arrayCref = SOME(acr)), _)
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
  input Option<BackendDAE.Variables> inAliasVars;
  output SimCode.AliasVariable outAlias;
algorithm
  outAlias :=
  matchcontinue (inVar,inAliasVars)
    local
      DAE.ComponentRef name;
      BackendDAE.Variables aliasVars;
      BackendDAE.Var var;
      DAE.Exp e;
      SimCode.AliasVariable alias;
    case (BackendDAE.VAR(varName=name),SOME(aliasVars))
      equation
        ((var :: _),_) = BackendVariable.getVar(name,aliasVars);
        // does not work
        //e = BaseHashTable.get(name,varMappings);
        e = BackendVariable.varBindExp(var);
        (e,_) = ExpressionSimplify.simplify(e);
        alias = getAliasVar1(e,var);
      then alias;
    case(_,_) then SimCode.NOALIAS();
  end matchcontinue;
end getAliasVar;

protected function getAliasVar1
  input DAE.Exp inExp;
  input BackendDAE.Var inVar;
  output SimCode.AliasVariable outAlias;
algorithm
  outAlias :=
  matchcontinue (inExp,inVar)
    local
      DAE.ComponentRef name;
      Absyn.Path fname;
    
    case (DAE.CREF(componentRef=name),_) then SimCode.ALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CREF(componentRef=name)),_) then SimCode.NEGATEDALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CREF(componentRef=name)),_) then SimCode.NEGATEDALIAS(name);
    case (DAE.LUNARY(operator=DAE.NOT(_),exp=DAE.CREF(componentRef=name)),_) then SimCode.NEGATEDALIAS(name);
    case (DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)}),_)
      equation
      Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then SimCode.ALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS(_),exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})),_)
      equation
       Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then SimCode.NEGATEDALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(_),exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})),_)
      equation
       Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then SimCode.NEGATEDALIAS(name);
    case(_,_) then SimCode.NOALIAS();
  end matchcontinue;
end getAliasVar1;

public function getArrayCref
  input DAE.ComponentRef name;
  output Option<DAE.ComponentRef> arrayCref;
algorithm
  arrayCref :=
  matchcontinue (name)
    local
      DAE.ComponentRef arrayCrefInner;
    case (_)
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
  input list<SimCode.HelpVarInfo> inHelpVarInfo;
  input BackendDAE.BackendDAE inBackendDAE;
  output list<SimCode.HelpVarInfo> outHelpVarInfo;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<BackendDAE.Equation> outSampleEqns;
algorithm
  (outHelpVarInfo,outBackendDAE,outSampleEqns) :=
  matchcontinue (inHelpVarInfo,inBackendDAE)
    local
      list<SimCode.HelpVarInfo> helpvars;
      BackendDAE.Variables knownVars;
      BackendDAE.Variables externalObjects;
      BackendDAE.Variables aliasVars;
      BackendDAE.EquationArray removedEqs;
      BackendDAE.EquationArray initialEqs;
      array<DAE.Constraint> constrs;
      array<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;      
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo eventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses;
      BackendDAE.EqSystems eqs;
      BackendDAE.BackendDAEType btp;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.Equation> sampleEqns;
    case  (helpvars,BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,
      removedEqs,constrs,clsAttrs,cache,env,funcs,eventInfo,extObjClasses,btp,symjacs)))
      equation
        (eqs,(_,helpvars,sampleEqns)) = List.mapFold(eqs,generateHelpVarsForWhenStatements1,(listLength(helpvars),helpvars,{}));
        (removedEqs,(_,helpvars,sampleEqns)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(removedEqs,generateHelpVarsForWhenStatements2,(listLength(helpvars),helpvars,sampleEqns));
        (initialEqs,(_,helpvars,sampleEqns)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(initialEqs,generateHelpVarsForWhenStatements2,(listLength(helpvars),helpvars,sampleEqns));
      then 
        (helpvars,BackendDAE.DAE(eqs,BackendDAE.SHARED(knownVars,externalObjects,aliasVars,initialEqs,
        removedEqs,constrs,clsAttrs,cache,env,funcs,eventInfo,extObjClasses,btp,symjacs)),sampleEqns);
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsForWhenStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsForWhenStatements;

protected function generateHelpVarsForWhenStatements1 "function: generateHelpVarsForWhenStatements1
  helper for generateHelpVarsForWhenStatements."
    input BackendDAE.EqSystem syst;
    input tuple<Integer,list<SimCode.HelpVarInfo>,list<BackendDAE.Equation>> iTpl;
    output BackendDAE.EqSystem osyst;
    output tuple<Integer,list<SimCode.HelpVarInfo>,list<BackendDAE.Equation>> oTpl;
algorithm
  (osyst,oTpl) := match (syst,iTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Matching matching;
      Integer size;
      list<SimCode.HelpVarInfo> helpvarinfo;
      list<BackendDAE.Equation> sampleEquations;
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),(size,helpvarinfo,sampleEquations))
      equation
        (eqns,(size,helpvarinfo,sampleEquations)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,generateHelpVarsForWhenStatements2,(size,helpvarinfo,sampleEquations));
      then
        (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),(size,helpvarinfo,sampleEquations));
  end match;
end generateHelpVarsForWhenStatements1;

protected function generateHelpVarsForWhenStatements2
  input tuple<BackendDAE.Equation,tuple<Integer,list<SimCode.HelpVarInfo>,list<BackendDAE.Equation>>> tpl;
  output tuple<BackendDAE.Equation,tuple<Integer,list<SimCode.HelpVarInfo>,list<BackendDAE.Equation>>> outTpl;
algorithm
  outTpl := match(tpl)
    local
      Integer size,hsize;
      DAE.ElementSource source;
      list<SimCode.HelpVarInfo> helpvarinfo,helpVars1;  
      list<Algorithm.Statement> stmts;   
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> sampleEquations;  
      Boolean b;
    case((BackendDAE.ALGORITHM(size=size, alg=DAE.ALGORITHM_STMTS(stmts), source=source),(hsize,helpvarinfo,sampleEquations)))
      equation
        (helpVars1,stmts,hsize) = generateHelpVarsInStatements(hsize,stmts);
        helpvarinfo = listAppend(helpVars1,helpvarinfo);
      then
        ((BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS(stmts),source),(hsize,helpvarinfo,sampleEquations)));
    case((eqn as BackendDAE.WHEN_EQUATION(size=_),(hsize,helpvarinfo,sampleEquations)))
      then
        ((eqn,(hsize,helpvarinfo,sampleEquations))); 
    case((eqn,(hsize,helpvarinfo,sampleEquations)))
      equation
        (eqn,b,(hsize,helpvarinfo)) = BackendEquation.traverseBackendDAEExpsEqnOutEqn(eqn,sampleFinder,(hsize,helpvarinfo));
        sampleEquations = List.consOnTrue(b, eqn, sampleEquations);      
      then 
        ((eqn,(hsize,helpvarinfo,sampleEquations)));
  end match;
end generateHelpVarsForWhenStatements2;

protected function generateHelpVarsInStatements
  input Integer n "Index of next help variable";
  input list<Algorithm.Statement> inStmtLst;
  output list<SimCode.HelpVarInfo> outHelpVars;
  output list<Algorithm.Statement> outStmtLst;
  output Integer n1;
algorithm
  (outHelpVars,outStmtLst,n1) := matchcontinue(n,inStmtLst)
    local
      list<Algorithm.Statement> rest, rest1;
      Integer nextInd, nextInd1, nextInd2;
      Algorithm.Statement statement,statement1;
      list<SimCode.HelpVarInfo> helpvars,helpvars1,helpvars2;
      
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
  output list<SimCode.HelpVarInfo> outHelpVars;
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
      list<SimCode.HelpVarInfo> helpvars,helpvars1,helpvars2;
      DAE.Type ty;
      Boolean scalar;
      DAE.ElementSource source;
      Absyn.Path name;
      list<DAE.Exp> args_;
      DAE.CallAttributes attr;
      
    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,NONE(),_,source))
      equation
        (helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
        helpVarIndices1 = List.intRange(nextInd1-nextInd);
        helpVarIndices = List.map1(helpVarIndices1,intAdd,nextInd-1);
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
        helpVarIndices1 = List.intRange(nextInd1-nextInd);
        helpVarIndices = List.map1(helpVarIndices1,intAdd,nextInd-1);
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
  output list<SimCode.HelpVarInfo> outHelpVars;
  output list<DAE.Exp> outExp;
  output Integer n1;
algorithm
  (outHelpVars,outExp,n1) := matchcontinue(n,inExp)
    local
      list<DAE.Exp> rest,  el1;
      Integer nextInd, nextInd1;
      DAE.Exp condition;
      list<SimCode.HelpVarInfo> helpvars1;
      Absyn.Path name;
      list<DAE.Exp> args_;
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
        eqnLst1 = List.consOnTrue(not b,e,eqnLst);
      then ((e,(eqnIndx+1,ass2,vars,eqnLst1)));
    case (inTpl) then inTpl;
  end matchcontinue;
end selectContinuousEquations;

protected function generateInitialEquationsFromStart "function: generateInitialEquationsFromStart
  This function generates equations from the expressions in the start
  attributes of variables. Only variables with a start value and
  fixed set to true is converted by this function. Fixed set to false
  means an initial guess, and is not considered here."
  input tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<list<BackendDAE.Equation>,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)      
    local
      list<BackendDAE.Equation> eqns;
      BackendDAE.Var v;
      Expression.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.Exp e,startv;
      DAE.Type tp;
      Option<DAE.VariableAttributes> attr;
      DAE.ElementSource source;
      BackendDAE.Variables av;
      
    case (((v as BackendDAE.VAR(varName = cr,varKind = kind,values = attr,source=source)),(eqns,av))) /* add equations for variables with fixed = true */
      equation
        SimCode.NOALIAS() = getAliasVar(v,SOME(av));
        BackendVariable.isVarKindVariable(kind);
        true = BackendVariable.varFixed(v);
        true = DAEUtil.hasStartAttr(attr);
        //startv = DAEUtil.getStartAttr(attr);
        e = Expression.crefExp(cr);
        tp = Expression.typeof(e);
        startv = Expression.makeBuiltinCall("$_start", {e}, tp);
      then
        ((v,(BackendDAE.EQUATION(e,startv,source)::eqns,av)));
    case (((v as BackendDAE.VAR(varName = cr,varKind = BackendDAE.STATE(),values = attr,source=source)),(eqns,av))) /* add equations for variables with fixed = true */
      equation
        SimCode.NOALIAS() = getAliasVar(v,SOME(av));
        true = BackendVariable.varFixed(v);
        false = DAEUtil.hasStartAttr(attr);
        //startv = DAEUtil.getStartAttr(attr);
        e = Expression.crefExp(cr);
        tp = Expression.typeof(e);
        startv = Expression.makeBuiltinCall("$_start", {e}, tp);
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
  input Integer nextHelpIndex          "Next available help variable index";
  input list<SimCode.HelpVarInfo> helpVarLst;
  output Integer onextHelpIndex          "Next available help variable index";
  output list<SimCode.HelpVarInfo> ohelpVarLst;
algorithm
  (onextHelpIndex,ohelpVarLst) := matchcontinue (whenConditions,nextHelpIndex,helpVarLst)
    local
      Integer helpVarIndex;
      list<SimCode.HelpVarInfo> helpVarInfo;
      DAE.Exp e;
      list<DAE.Exp> el;
      Absyn.Path name;
      list<DAE.Exp> args_;
      DAE.CallAttributes attr;
    
    case ({},_,_) then (nextHelpIndex,helpVarLst);
    
    //expand sample conditions with helpindex
    case (DAE.CALL(path = name as Absyn.IDENT("sample"),expLst=args_,attr=attr) :: el,_,_)
      equation
        args_ = listAppend(args_,{DAE.ICONST(nextHelpIndex)});
        e = DAE.CALL(name, args_, attr);
        (helpVarIndex,helpVarInfo) =  buildWhenConditionChecks3(el, nextHelpIndex + 1,(nextHelpIndex,e,-1)::helpVarLst);
      then
        (helpVarIndex,helpVarInfo);
    case (e :: el,_,_)
      equation
        //add HelpVar for sample and add hindex to sample call
        ((e,(helpVarInfo,helpVarIndex))) = Expression.traverseExp(e, addHindexSample, (helpVarLst,nextHelpIndex));
        (helpVarIndex,helpVarInfo) =  buildWhenConditionChecks3(el, helpVarIndex + 1,(nextHelpIndex,e,-1)::helpVarInfo);
      then
        (helpVarIndex,helpVarInfo);
    
    else
      equation
        print("-SimCode.buildWhenConditionChecks3 failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks3;


protected function addHindexSample
  input tuple<DAE.Exp, tuple<list<SimCode.HelpVarInfo>,Integer>> inTuple;
  output tuple<DAE.Exp, tuple<list<SimCode.HelpVarInfo>,Integer>> outTuple;
algorithm
  (outTuple):=
  matchcontinue (inTuple)
    local
      SimCode.HelpVarInfo helpInfo;
      Integer helpVarIndex;
      list<SimCode.HelpVarInfo> helpVarInfoList;
      DAE.Exp e;
      Absyn.Path name;
      list<DAE.Exp> args_;
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
  input Integer nextHelpVarIndex;
  input list<SimCode.HelpVarInfo> helpVarLst;
  output list<SimCode.HelpVarInfo> ohelpVarLst;
algorithm
  ohelpVarLst :=
  matchcontinue (inBackendDAEWhenClauseLst1,nextHelpVarIndex,helpVarLst)
    local
      Integer nextHelpVarIndex1;
      list<SimCode.HelpVarInfo> helpVarLst1;
      list<BackendDAE.WhenClause> xs;
      list<DAE.Exp> el;
      DAE.Exp e;
    case ({},_,_) then helpVarLst;
    /* skip if there are no reinit statements */
    case (BackendDAE.WHEN_CLAUSE(reinitStmtLst = {}) :: xs,_,_) 
      then
        buildWhenConditionChecks2(xs,nextHelpVarIndex,helpVarLst);
    case (BackendDAE.WHEN_CLAUSE(condition = e) :: xs,_,_)
      equation
        el = getConditionList(e);
        (nextHelpVarIndex1,helpVarLst1) = buildWhenConditionChecks3(el,nextHelpVarIndex,helpVarLst);
      then
        buildWhenConditionChecks2(xs,nextHelpVarIndex1,helpVarLst1);
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
  input BackendDAE.EquationArray eqnl     "List of equations.";
  input Integer ihelpVarIndex                      "index of the next generated help variable.";
  input list<SimCode.HelpVarInfo> ihelpVarLst                  "List of help variables introduced in this function.";
  output Integer ohelpVarIndex;
  output list<SimCode.HelpVarInfo> ohelpVarLst                  "List of help variables introduced in this function.";
algorithm
  (ohelpVarIndex,ohelpVarLst):=
  matchcontinue (orderOfEquations,eqnl,ihelpVarIndex,ihelpVarLst)
    local
      Integer eqn,nextHelpIndex;
      list<SimCode.HelpVarInfo> helpVarInfoList;
      list<Integer> rest;
      BackendDAE.WhenEquation whenEq;
    case ({},_,_,_) then (ihelpVarIndex,ihelpVarLst);     
      /* equation is a WHEN_EQUATION */
    case ((eqn :: rest),_,_,_)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation=whenEq) = BackendDAEUtil.equationNth(eqnl, eqn-1);
        (nextHelpIndex,helpVarInfoList) = buildWhenConditionCheckForEquation(SOME(whenEq),ihelpVarIndex,ihelpVarLst);
        (nextHelpIndex,helpVarInfoList) = buildWhenConditionChecks4(rest, eqnl, nextHelpIndex,helpVarInfoList);
      then
        (nextHelpIndex,helpVarInfoList);       
    case (_ :: rest,_,_,_)
      equation
        (nextHelpIndex,helpVarInfoList) = buildWhenConditionChecks4(rest, eqnl,ihelpVarIndex,ihelpVarLst);
      then
        (nextHelpIndex,helpVarInfoList);
  end matchcontinue;
end buildWhenConditionChecks4;

protected function buildWhenConditionCheckForEquation "
  Generates eventchecking code given a when equation.
"
  input Option<BackendDAE.WhenEquation> whenEq            "The equation to check for";
  input Integer ihelpVarIndex                      "index of the next generated help variable.";
  input list<SimCode.HelpVarInfo> ihelpVarLst                  "List of help variables introduced in this function.";
  output Integer ohelpVarIndex;
  output list<SimCode.HelpVarInfo> ohelpVarLst                  "List of help variables introduced in this function.";
algorithm
  (ohelpVarIndex,ohelpVarLst):=
  match (whenEq,ihelpVarIndex,ihelpVarLst)
    local
      Integer nextHelpInd;
      DAE.Exp cond;
      Option<BackendDAE.WhenEquation> elsePart;
      list<DAE.Exp> conditionList;
      list<SimCode.HelpVarInfo> helpVars;
    case (SOME(BackendDAE.WHEN_EQ(condition=cond,elsewhenPart=elsePart)),_,_)
      equation
        conditionList = getConditionList(cond);
        (nextHelpInd,helpVars) = buildWhenConditionChecks3(conditionList,ihelpVarIndex,ihelpVarLst);
        (nextHelpInd,helpVars) = buildWhenConditionCheckForEquation(elsePart,nextHelpInd,helpVars);
      then
        (nextHelpInd,helpVars);
    case (NONE(),_,_) then (ihelpVarIndex,ihelpVarLst);
  end match;
end buildWhenConditionCheckForEquation;

protected function getConditionList
  input DAE.Exp condition;
  output list<DAE.Exp> conditionList;
algorithm
  conditionList := match (condition)
    case DAE.ARRAY(array=conditionList) then conditionList;
    else then {condition};
  end match;
end getConditionList;

protected function addMissingEquations "function: addMissingEquations
  Helper function to build_when_condition_checks
  Given an integer and a list of integers completes the list with missing
  integers upto the given integer.
"
  input Integer n;
  input array<Boolean> selectedeqns;
  input list<Integer> inIntegerLst "accumulator; reverse the list before calling this function---";
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (n,selectedeqns,inIntegerLst)
    case (0,_,_) then listReverse(inIntegerLst);
    case (_,_,_)
      equation
        true = selectedeqns[n];
      then 
        addMissingEquations(n-1,selectedeqns, inIntegerLst);
    case (_,_,_) /* missing equations must be added in correct order, required in building whenConditionChecks4 */
      then 
        addMissingEquations(n-1,selectedeqns, n::inIntegerLst);
  end matchcontinue;
end addMissingEquations;

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

protected function generateMixedDiscreteCombinationValues "function generateMixedDiscreteCombinationValues
  author: PA
  Generates all combinations of the values given as argument"
  input list<list<Integer>> iValues;
  output list<list<Integer>> oValues;
algorithm
  oValues := match (iValues)
    local
      list<Integer> value;
    case ({value}) then {value};
    else
      then
        generateMixedDiscreteCombinationValues1(iValues);
  end match;
end generateMixedDiscreteCombinationValues;

protected function generateMixedDiscreteCombinationValues1
  input list<list<Integer>> iValues;
  output list<list<Integer>> oValues;
algorithm
  oValues := matchcontinue (iValues)
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
        lst_1 = List.map1(lst, List.consr, s);
        lst2 = generateMixedDiscreteCombinationValues2(ss, lst);
        res = listAppend(lst_1, lst2);
      then
        res;
  end match;
end generateMixedDiscreteCombinationValues2;

protected function generateMixedDiscretePossibleValues2 "function: generateMixedDiscretePossibleValues2
  Helper function to generateMixedDiscretePossibleValues."
  input list<BackendDAE.Var> inBackendDAEVarLst;
  input Integer inInteger;
  output list<list<Integer>> outStringLstLst;
  output list<Integer> outIntegerLst;
algorithm
  (outStringLstLst,outIntegerLst) := matchcontinue (inBackendDAEVarLst,inInteger)
    local
      Integer cg_id;
      list<list<Integer>> values;
      list<Integer> dims;
      list<DAE.Exp> rels;
      BackendDAE.Var v;
      list<BackendDAE.Var> vs;
      
    case ({},cg_id) then ({},{});  /* discrete vars cg var_id values value dimension */
      
    case ((v :: vs),cg_id) /* booleans, generate true (1.0) and false (0.0) */
      equation
        DAE.T_BOOL(source = _) = BackendVariable.varType(v);
        (values,dims) = generateMixedDiscretePossibleValues2(vs, cg_id);
      then
        ({1,0} :: values, 2 :: dims);
        
    case ((v :: vs),_)
      equation
        DAE.T_INTEGER(source = _) = BackendVariable.varType(v);
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
    case (vs,BackendDAE.ALGORITHM(alg=_)::{})
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
      DAE.Type tp;
      Boolean b;
      DAE.ComponentRef c;
      
    case (_,DAE.ARRAY( tp, b,exps as ((DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef=c)) :: _))),_)
      equation
        (f::exps_1) = List.map(exps, Expression.expStripLastSubs); //Strip last subscripts
        List.map1AllValue(exps_1, Expression.expEqual, true, f);
        c = ComponentReference.crefStripLastSubs(c);
        (e12,e22) = solveTrivialArrayEquation(v,Expression.makeCrefExp(c,tp),Expression.negate(e2));
      then  
        (e12,e22);
        
    case (_,_,DAE.ARRAY( tp, b,exps as ((DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef=c)) :: _))))
      equation
        (f::exps_1) = List.map(exps, Expression.expStripLastSubs); //Strip last subscripts
        List.map1AllValue(exps_1, Expression.expEqual, true, f);
        c = ComponentReference.crefStripLastSubs(c);
        (e12,e22) = solveTrivialArrayEquation(v,Expression.negate(e2),Expression.makeCrefExp(c,tp));
      then  
        (e12,e22);
        
        // Solve simple linear equations.
    case(_,_,_)
      equation
        e = Expression.expSub(e1,e2);
        (res,_) = ExpressionSimplify.simplify(e);
        (f,rhs) = Expression.getTermsContainingX(res,Expression.crefExp(v));
        (vTerm,_) = ExpressionSimplify.simplify(f);
        (e22,rhs) = solveTrivialArrayEquation2(vTerm,rhs);
      then 
        (e22,rhs);
        
        // not succeded to solve, return unsolved equation., catched later.
    case (_,_,_) then (e1,e2);
  end matchcontinue;
end solveTrivialArrayEquation;

protected function solveTrivialArrayEquation2
"function: solveTrivialArrayEquation2
  author: Frenkel TUD - 2012-07
  helper for solveTrivialArrayEquation"
  input DAE.Exp e1;
  input DAE.Exp e2;
  output DAE.Exp outE1;
  output DAE.Exp outE2;
algorithm
  (outE1,outE2) := match(e1,e2)
    local
      DAE.Exp lhs,rhs;
    case(DAE.CREF(componentRef=_),_)
      equation
        (rhs,_) = ExpressionSimplify.simplify(Expression.negate(e2));
      then 
        (e1,rhs);

    case(DAE.UNARY(exp=lhs as DAE.CREF(componentRef=_)),_)
      equation
        (rhs,_) = ExpressionSimplify.simplify(e2);
      then 
        (lhs,rhs);

  end match;
end solveTrivialArrayEquation2;

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
        ((crefs as (cr :: _))) = List.map(expl, Expression.expCref); //Get all CRefs from exp1.
        crefs_1 = List.map(crefs, ComponentReference.crefStripLastSubs); //Strip last subscripts
        _ = List.reduce(crefs_1, ComponentReference.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
        
    case (DAE.MATRIX(matrix = column))
      equation
        expl = List.flatten(column);
        ((crefs as (cr :: _))) = List.map(expl, Expression.expCref); //Get all CRefs from exp1.
        crefs_1 = List.map(crefs, ComponentReference.crefStripLastSubs); //Strip last subscripts
        _ = List.reduce(crefs_1, ComponentReference.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
  end match;
end getVectorizedCrefFromExp;

protected function getExpCref
  input DAE.Exp inExp;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inExp)
   local
     DAE.ComponentRef cr;
    case (DAE.CREF(componentRef=cr)) then cr;
  end match;
end getExpCref;

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
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> exp;
      Option<Values.Value> v;
      list<Expression.Subscript> dim;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      BackendDAE.Var backendVar;
      
    case (BackendDAE.VAR(varName = cr,
      varKind = BackendDAE.STATE(),
      varDirection = dir,
      varParallelism = prl,
      varType = tp,
      bindExp = exp,
      bindValue = v,
      arryDim = dim,
      source = source,
      values = attr,
      comment = comment,
      connectorType = ct))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
      then
        BackendDAE.VAR(cr,BackendDAE.STATE_DER(),dir,prl,tp,exp,v,dim,source,attr,comment,ct);
        
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

protected function getCalledFunctionsInFunctions
"function: getCalledFunctionsInFunctions
  Goes through the given DAE, finds the given functions and collects
  the names of the functions called from within those functions"
  input list<Absyn.Path> paths;
  input HashTableStringToPath.HashTable inHt;
  input DAE.FunctionTree funcs;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (paths,inHt,funcs)
    local
      list<Absyn.Path> rest;
      Absyn.Path path;
      HashTableStringToPath.HashTable ht; 
      
    case ({},ht,_) then ht;
    case (path::rest,ht,_)
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
  input HashTableStringToPath.HashTable inHt "paths to not add";
  input DAE.FunctionTree funcs;
  output HashTableStringToPath.HashTable outHt "paths to not add";
algorithm
  outHt := matchcontinue (inPath,pathstr,inHt,funcs)
    local
      String str;
      Absyn.Path path;
      DAE.Function funcelem;
      list<Absyn.Path> calledfuncs, varfuncs;
      list<DAE.Element> els;
      HashTableStringToPath.HashTable ht;
      
    case (path,_,ht,_)
      equation
        _ = BaseHashTable.get(Absyn.pathStringNoQual(path), ht);
      then ht;
        
    case (path,_,ht,_)
      equation
        funcelem = DAEUtil.getNamedFunction(path, funcs);
        els = DAEUtil.getFunctionElements(funcelem);
        // SimCode.Function reference variables are filtered out
        varfuncs = List.fold(els, DAEUtil.collectFunctionRefVarPaths, {});
        (_,(_,varfuncs)) = DAEUtil.traverseDAE2(Util.if_(Config.acceptMetaModelicaGrammar(), els, {}),Expression.traverseSubexpressionsHelper,(DAEUtil.collectValueblockFunctionRefVars,varfuncs));
        (_,(_,(calledfuncs,_))) = DAEUtil.traverseDAE2(els,Expression.traverseSubexpressionsHelper,(matchNonBuiltinCallsAndFnRefPaths,({},varfuncs)));
        ht = BaseHashTable.add((pathstr,path),ht);
        ht = getCalledFunctionsInFunctions(calledfuncs, ht, funcs);
      then ht;
        
    case (path,_,ht,_)
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
        true = Absyn.pathEqual(first, path);
        res = removePathFromList(rest, path);
      then
        res;
    case ((first :: rest),path)
      equation
        false = Absyn.pathEqual(first, path);
        res = removePathFromList(rest, path);
      then
        (first :: res);
  end matchcontinue;
end removePathFromList;

protected function generateEquationOrder
  input BackendDAE.StrongComponents inComps;
  input array<Boolean> selectedeqns;
  input list<Integer> iIntegerLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inComps,selectedeqns,iIntegerLst)
    local
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents blocks;
      Integer eqn;
    case ({},_,_) then listReverse(iIntegerLst);
    //  for single equations 
    case (BackendDAE.SINGLEEQUATION(eqn=eqn) :: blocks,_,_)
      equation
        _  = arrayUpdate(selectedeqns,eqn,true);
      then
        generateEquationOrder(blocks,selectedeqns,eqn::iIntegerLst);
    // "For system of equations skip these" 
    case (comp :: blocks,_,_)
      then
        generateEquationOrder(blocks,selectedeqns,iIntegerLst) ;
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

/*mahge: kernel functions*/
protected function isVarNotInputNotOutput
"Succeeds if inElement is a variable or constant that is not input or output.
needed in kernel functions since they shouldn't have output vars."
  input DAE.Element inElement;
algorithm
  _ := match (inElement)
    local
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(kind=vk, direction=vd)
      equation
        isVarVarOrConstant(vk);
        isDirectionNotInputNotOutput(vd);
      then ();
  end match;
end isVarNotInputNotOutput;

protected function isVarVarOrConstant
  input DAE.VarKind inVarKind;
algorithm
  _ := match (inVarKind)
    case DAE.VARIABLE() then ();
    case DAE.PARAM() then ();
    case DAE.CONST() then ();
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

protected function isDirectionNotInputNotOutput
  input DAE.VarDirection inVarDirection;
algorithm
  _ := match (inVarDirection)
    case DAE.BIDIR() then ();
  end match;
end isDirectionNotInputNotOutput;

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
  flagSet := Flags.isSet(Flags.NO_EVENTS);
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

protected function scodeParallelismToDAEParallelism
  input SCode.Parallelism inParallelism;
  output DAE.VarParallelism outParallelism;
algorithm
  outParallelism := match(inParallelism)
    case(SCode.PARGLOBAL())    then DAE.PARGLOBAL();
    case(SCode.PARLOCAL())     then DAE.PARLOCAL();
    case(SCode.NON_PARALLEL()) then DAE.NON_PARALLEL();
  end match;
end scodeParallelismToDAEParallelism;

protected function typesVar
  input Types.Var inTypesVar;
  output SimCode.Variable outVar;
algorithm
  outVar := match (inTypesVar)
    local
      String name;
      Types.Type ty;
      DAE.ComponentRef cref_;
      DAE.Attributes attr;
      SCode.Parallelism scPrl;
      DAE.VarParallelism prl;
      
    case (DAE.TYPES_VAR(name=name, attributes = attr, ty=ty))
      equation
        ty = Types.simplifyType(ty);
        cref_ = ComponentReference.makeCrefIdent(name, ty, {});
        DAE.ATTR(parallelism = scPrl) = attr;
        prl = scodeParallelismToDAEParallelism(scPrl);
      then SimCode.VARIABLE(cref_, ty, NONE(), {}, prl);
  end match;
end typesVar;

public function dlowvarToSimvar
  input BackendDAE.Var dlowVar;
  input Option<BackendDAE.Variables> optAliasVars;
  input BackendDAE.Variables inVars;
  output SimCode.SimVar simVar;
algorithm
  simVar := match (dlowVar,optAliasVars,inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      list<Expression.Subscript> inst_dims;
      list<String> numArrayElement;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      BackendDAE.Type tp;
      String  commentStr,  unit, displayUnit;
      Option<DAE.Exp> minValue, maxValue;
      Option<DAE.Exp> initVal;
      Option<DAE.Exp> nomVal;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      SimCode.AliasVariable aliasvar;
      DAE.ElementSource source;
      BackendDAE.Variables vars;
      SimCode.Causality caus;
    case ((BackendDAE.VAR(varName = cr,
      varKind = kind,
      varDirection = dir,
      arryDim = inst_dims,
      values = dae_var_attr,
      comment = comment,
      varType = tp,
      source = source)),_,vars)
      equation
        commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
        (unit, displayUnit) = extractVarUnit(dae_var_attr);
        (minValue, maxValue) = getMinMaxValues(dlowVar);
        initVal = getInitialValue(dlowVar);
        nomVal = getNominalValue(dlowVar);
        checkInitVal(initVal,source);
        isFixed = BackendVariable.varFixed(dlowVar);
        type_ = tp;
        isDiscrete = BackendVariable.isVarDiscrete(dlowVar);
        arrayCref = getArrayCref(cr);
        aliasvar = getAliasVar(dlowVar,optAliasVars);
        caus = getCausality(dlowVar,vars);
        numArrayElement=arraydim1(inst_dims);
        // print("name: " +& ComponentReference.printComponentRefStr(cr) +& "indx: " +& intString(indx) +& "\n");
      then
        SimCode.SIMVAR(cr, kind, commentStr, unit, displayUnit, -1 /* use -1 to get an error in simulation if something failed */,
        minValue, maxValue, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, caus,NONE(),numArrayElement);
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
    case (SOME(DAE.CALL(attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.EXTERNAL_OBJ(path=_))))),_) then ();
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
  output SimCode.Causality caus;
algorithm
  caus := matchcontinue (dlowVar,inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables knvars;
    case (BackendDAE.VAR(varName = DAE.CREF_IDENT(ident = _), varDirection = DAE.OUTPUT()),_) then SimCode.OUTPUT();
    case (BackendDAE.VAR(varName = cr,varDirection = DAE.INPUT()),knvars)
      equation
        (_,_) = BackendVariable.getVar(cr, knvars);
      then SimCode.INPUT();
    case(_,_) then SimCode.INTERNAL();
  end matchcontinue;
end getCausality;

protected function traversingdlowvarToSimvarFold
"autor: Frenkel TUD 2010-11"
  input BackendDAE.Var v;
  input tuple<list<SimCode.SimVar>,BackendDAE.Variables> inTpl;
  output tuple<list<SimCode.SimVar>,BackendDAE.Variables> outTpl;
algorithm
  ((_,outTpl)) := traversingdlowvarToSimvar((v,inTpl));
end traversingdlowvarToSimvarFold;

protected function traversingdlowvarToSimvar
"autor: Frenkel TUD 2010-11"
  input tuple<BackendDAE.Var, tuple<list<SimCode.SimVar>,BackendDAE.Variables>> inTpl;
  output tuple<BackendDAE.Var, tuple<list<SimCode.SimVar>,BackendDAE.Variables>> outTpl;
algorithm
  outTpl := match (inTpl)
    local
      BackendDAE.Var v;
      list<SimCode.SimVar> sv_lst;
      SimCode.SimVar sv;
      BackendDAE.Variables vars;
    case ((v,(sv_lst,vars)))
      equation
        sv = dlowvarToSimvar(v,NONE(),vars);
      then ((v,(sv::sv_lst,vars)));
    case _ then inTpl;
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
        _ = List.getMemberOnTrue(path, allpaths, Absyn.pathEqual);
        (allpaths,iterpaths) = appendNonpresentPaths(paths, allpaths, iterpaths);
      then
        (allpaths,iterpaths);
        
    case ((path :: paths),allpaths,iterpaths)
      equation
        failure(_ = List.getMemberOnTrue(path, allpaths, Absyn.pathEqual));
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
        false = List.isMemberOnTrue(path,filter,Absyn.pathEqual);
      then ((e,(path::acc,filter)));
    case ((e as DAE.PARTEVALFUNCTION(path = path),(acc,filter)))
      equation
        path = Absyn.makeNotFullyQualified(path);
        false = List.isMemberOnTrue(path,filter,Absyn.pathEqual);
      then ((e,(path::acc,filter)));
    case ((e as DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_FUNC(builtin = false)),(acc,filter)))
      equation
        path = Absyn.crefToPath(getCrefFromExp(e));
        false = List.isMemberOnTrue(path,filter,Absyn.pathEqual);
      then ((e,(path::acc,filter)));
    case _ then itpl;
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
    case _ then itpl;
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

    case (_,SOME(SCode.ANNOTATION(mod)))
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
    case (_,_,_)
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
  input list<String> inLibs;
  output list<String> outLibs;
algorithm
  outLibs := matchcontinue (path,inMod,inLibs)
    local
      String str,str1,str2,str3,platform1,platform2;
      list<String> libs;
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
    case (_,_,libs)
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
    else inLibs;
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
      String str;
      
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
        strs = str :: "-fopenmp" :: "-lintl" :: "-liconv" :: "-lexpat" :: "-lsqlite3" :: "-llpsolve55" :: "-lmico2313" :: "-lws2_32" :: "-lregex" :: strs;
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
        libsList = List.map(arr, getLibraryStringInGccFormat);
      then
        List.flatten(libsList);
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
      DAE.Type ty;
      
    case ((e as DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_FUNC(builtin = false)),acc)) then ((e,e::acc));
      
    case ((e as DAE.PARTEVALFUNCTION(ty = ty as DAE.T_FUNCTION_REFERENCE_VAR(source = _),path=p),acc))
      equation
        cref = ComponentReference.pathToCref(p);
        e2 = Expression.makeCrefExp(cref,ty);
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
      DAE.Type record_type;
      Absyn.Path record_path;
      list<DAE.Exp> rest_expr;
      DAE.Exp record_cref;
    case ({}) then {};
      // A record component reference.
    case (DAE.CREF(
      componentRef = cref, 
      ty = (record_type as DAE.T_COMPLEX(
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

protected function addDivExpErrorMsgtoExp "
  Author: Frenkel TUD 2010-02, Adds the error msg to Expression.Div."
  input DAE.Exp inExp;
  input tuple<DAE.ElementSource,tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace>> inDlowMode;
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
      DAE.ElementSource source;
      
    case(_,(source,(vars,varlst,dzer)))
      equation
         false = Expression.traverseCrefsFromExp(inExp,traversingXLOCExpFinder,false);
        ((exp,(_,_,_,_,divlst))) = Expression.traverseExp(inExp, traversingDivExpFinder, (source,vars,varlst,dzer,{}));
      then
        (exp,divlst);
  end match;
end addDivExpErrorMsgtoExp;

protected function traversingXLOCExpFinder "
Author: Frenkel TUD 2010-02"
  input DAE.ComponentRef inCref;
  input Boolean inB;
  output Boolean  outB;
algorithm
  outB := match(inCref,inB)
    case( DAE.CREF_IDENT(ident="xloc",identType=DAE.T_ARRAY(dims={DAE.DIM_UNKNOWN()})) ,_ )
      then true;
   case(_,_) then inB;
  end match;
end traversingXLOCExpFinder;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02"
  input tuple<DAE.Exp, tuple<DAE.ElementSource,BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > inExp;
  output tuple<DAE.Exp, tuple<DAE.ElementSource,BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > outExp;
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
      DAE.ElementSource source;
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2),(source,vars,varlst,dzer,divLst)))
      equation
        true = Expression.isConst(e2);
        false = Expression.isZero(e2);
      then ((e, (source,vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2),(source,vars,varlst,dzer,divLst)))
      equation
        (se,true) = traversingDivExpFinder1(e,e2,source,(vars,varlst,dzer));
      then ((DAE.CALL(Absyn.IDENT("DIVISION"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL())), (source,vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2), (source,vars,varlst,dzer,divLst)))
      equation
        (se,false) = traversingDivExpFinder1(e,e2,source,(vars,varlst,dzer));
      then ((e, (source,vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL()))::divLst) ));
        
        /*
         case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARR(ty),exp2 = e2), dlowmode as (dlow,_)))
         then ((e, dlowmode ));
         */    
        
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (source,vars,varlst,dzer,divLst)))
      equation
        true = Expression.isConst(e2);
        false = Expression.isZero(e2);
      then ((e, (source,vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (source,vars,varlst,dzer,divLst)))
      equation
        (se,true) = traversingDivExpFinder1(e,e2,source,(vars,varlst,dzer));
      then ((DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL())), (source,vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (source,vars,varlst,dzer,divLst)))
      equation
        (se,false) = traversingDivExpFinder1(e,e2,source,(vars,varlst,dzer));
      then ((e, (source,vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL()))::divLst) ));
        
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (source,vars,varlst,dzer,divLst)))
      equation
        true = Expression.isConst(e2);
        false = Expression.isZero(e2);
      then ((e, (source,vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (source,vars,varlst,dzer,divLst)))
      equation
        (se,true) = traversingDivExpFinder1(e,e2,source,(vars,varlst,dzer));
      then ((DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL())), (source,vars,varlst,dzer,divLst) ));
    case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (source,vars,varlst,dzer,divLst)))
      equation
        (se,false) = traversingDivExpFinder1(e,e2,source,(vars,varlst,dzer));
      then ((e, (source,vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {e1,e2,DAE.SCONST(se)}, DAE.CALL_ATTR(ty, false, true, DAE.NO_INLINE(), DAE.NO_TAIL()))::divLst) ));
    case _ then (inExp);
  end matchcontinue;
end traversingDivExpFinder;

protected function traversingDivExpFinder1 "
Author: Frenkel TUD 2010-02 
  helper for traversingDivExpFinder"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource source;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inMode;
  output String outString;
  output Boolean outBool;
algorithm
  (outString,outBool) := match(inExp1,inExp2,source,inMode)
    local
      DAE.Exp e,e2;
      String se;
      list<DAE.ComponentRef> crlst;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      list<Boolean> boollst;
      Boolean bres;
      
    case( e , e2, _, (vars,varlst,BackendDAE.ALL()) )
      equation
        // generade modelica strings
        se = generadeDivExpErrorMsg(e,e2,vars,source);
      then 
        (se,false);
        
    case( e , e2, _, (vars,varlst,BackendDAE.ONLY_VARIABLES()) )
      equation
        // generade modelica strings
        se = generadeDivExpErrorMsg(e,e2,vars,source);
        // check if expression contains variables
        crlst = Expression.extractCrefsFromExp(e2);
        boollst = List.map1r(crlst,BackendVariable.isVarKnown,varlst);
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
  input DAE.ElementSource source;
  output String outString;
protected 
  String se,se2,s,fileName;
  Integer lns;
algorithm
  se := ExpressionDump.printExp2Str(inExp,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  se2 := ExpressionDump.printExp2Str(inDivisor,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  Absyn.INFO(fileName=fileName,lineNumberStart=lns) := DAEUtil.getElementSourceFileInfo(source);
  s := intString(lns);
  outString := stringAppendList({se," because ",se2," == 0: File: ",fileName," Line: ",s});
end generadeDivExpErrorMsg;

protected function addDivExpErrorMsgtosimJac
"function addDivExpErrorMsgtosimJac
  helper for addDivExpErrorMsgtoSimEqSystem."
  input tuple<Integer, Integer, SimCode.SimEqSystem> inJac;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inDlowMode;
  output tuple<Integer, Integer, SimCode.SimEqSystem> outJac;
  output list<tuple<DAE.Exp,DAE.ElementSource>> outDivLst;
algorithm
  (outJac,outDivLst) := match (inJac,inDlowMode)
    local
      Integer a,b;
      SimCode.SimEqSystem ses;
      list<tuple<DAE.Exp,DAE.ElementSource>> divLst;
    case ( (a,b,ses),_) 
      equation
        (ses,divLst) = addDivExpErrorMsgtoSimEqSystem(ses,inDlowMode);
      then
        ((a,b,ses),divLst);
  end match;
end addDivExpErrorMsgtosimJac;

protected function addSourcetoDivLst
  input DAE.Exp e;
  input DAE.ElementSource source;
  output tuple<DAE.Exp,DAE.ElementSource> outTpl;
algorithm
  outTpl := (e,source);
end addSourcetoDivLst;

protected function addDivExpErrorMsgtoSimEqSystem
"function addDivExpErrorMsgtoSimEqSystem
  Traverses all subexpressions of an expression of an equation."
  input SimCode.SimEqSystem inSES;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inDlowMode;
  output SimCode.SimEqSystem outSES;
  output list<tuple<DAE.Exp,DAE.ElementSource>> outDivLst;
algorithm
  (outSES,outDivLst):=
  matchcontinue (inSES,inDlowMode)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      Boolean partOfMixed;
      list<SimCode.SimVar> vars;
      list<DAE.Exp> elst,elst1;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac,simJac1;
      Integer index, indexNonLinear;
      list<DAE.ComponentRef> crefs;
      SimCode.SimEqSystem cont,cont1,elseWhenEq,elseWhen;
      list<SimCode.SimEqSystem> discEqs,discEqs1;
      list<Integer> values;
      list<Integer> value_dims;
      list<tuple<DAE.Exp, Integer>> conditions;
      list<DAE.Exp> divLst,divLst1;
      DAE.ElementSource source;
      list<tuple<DAE.Exp,DAE.ElementSource>> divtplLst,divtplLst1,divtplLst2;
      
    case (SimCode.SES_RESIDUAL(index= index, exp = e, source = source),_)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,(source,inDlowMode));
        divtplLst = List.map1(divLst,addSourcetoDivLst,source);
      then
        (SimCode.SES_RESIDUAL(index,e,source),divtplLst);
    case (SimCode.SES_SIMPLE_ASSIGN(index= index, cref = cr, exp = e, source = source),_)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,(source,inDlowMode));
        divtplLst = List.map1(divLst,addSourcetoDivLst,source);
      then
        (SimCode.SES_SIMPLE_ASSIGN(index, cr, e, source),divtplLst);
    case (SimCode.SES_ARRAY_CALL_ASSIGN(index = index, componentRef = cr, exp = e, source = source),_)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,(source,inDlowMode));
        divtplLst = List.map1(divLst,addSourcetoDivLst,source);
      then
        (SimCode.SES_ARRAY_CALL_ASSIGN(index,cr, e, source),divtplLst);
        /*
         case (SimCode.SES_ALGORITHM(),inDlowMode)
         equation
         e = addDivExpErrorMsgtoExp(e,(source,inDlowMode));
         then
         SimCode.SES_ALGORITHM();
         */              
    case (SimCode.SES_LINEAR(index,partOfMixed,vars,elst,simJac),_)
      equation
        (simJac1,divtplLst) = listMap1_2(simJac,addDivExpErrorMsgtosimJac,inDlowMode);
        (elst1,divLst1) = listMap1_2(elst,addDivExpErrorMsgtoExp,(DAE.emptyElementSource,inDlowMode));
        divtplLst1 = List.map1(divLst1,addSourcetoDivLst,DAE.emptyElementSource);
        divtplLst2 = listAppend(divtplLst,divtplLst1);
      then
        (SimCode.SES_LINEAR(index,partOfMixed,vars,elst1,simJac1),divtplLst2);
    case (SimCode.SES_NONLINEAR(index = index,eqs = discEqs, crefs = crefs, indexNonLinear = indexNonLinear),_)
      equation
        (discEqs,divtplLst) =  listMap1_2(discEqs,addDivExpErrorMsgtoSimEqSystem,inDlowMode);
      then
        (SimCode.SES_NONLINEAR(index,discEqs,crefs,indexNonLinear),divtplLst);
    case (SimCode.SES_MIXED(index,cont,vars,discEqs),_)
      equation
        (cont1,divtplLst) = addDivExpErrorMsgtoSimEqSystem(cont,inDlowMode);
        (discEqs1,divtplLst1) = listMap1_2(discEqs,addDivExpErrorMsgtoSimEqSystem,inDlowMode);
        divtplLst2 = listAppend(divtplLst,divtplLst1);
      then
        (SimCode.SES_MIXED(index,cont1,vars,discEqs1),divtplLst2);
        /*    case (SimCode.SES_WHEN(left = cr, right = e, conditions = conditions),inDlowMode)
         equation
         (e,divLst) = addDivExpErrorMsgtoExp(e,(source,inDlowMode));
         then
         (SimCode.SES_WHEN(cr,e,conditions),divLst);*/
        
    case (SimCode.SES_WHEN(index = index, left = cr, right = e, conditions = conditions, elseWhen= NONE(), source = source),_)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,(source,inDlowMode));
        divtplLst = List.map1(divLst,addSourcetoDivLst,source);
      then
        (SimCode.SES_WHEN(index,cr,e,conditions,NONE(),source),divtplLst);
    case (SimCode.SES_WHEN(index = index, left = cr, right = e, conditions = conditions, elseWhen= SOME(elseWhen), source = source),_)
      equation
        (e,divLst) = addDivExpErrorMsgtoExp(e,(source,inDlowMode));
        (elseWhenEq,divtplLst1) = addDivExpErrorMsgtoSimEqSystem(elseWhen, inDlowMode);
        divtplLst = List.map1(divLst,addSourcetoDivLst,source);
        divtplLst2 = listAppend(divtplLst,divtplLst1);
      then
        (SimCode.SES_WHEN(index,cr,e,conditions,SOME(elseWhenEq),source),divtplLst2);
    case (_,_) then (inSES,{});
  end matchcontinue;
end addDivExpErrorMsgtoSimEqSystem;

protected function generateParameterDivisionbyZeroTestEqn "
Author: Frenkel TUD 2010-04"
  input tuple<DAE.Exp,DAE.ElementSource> inExp;
  output DAE.Statement outStm;
algorithm outStm := match(inExp)
  local
    DAE.Exp e;
    DAE.ElementSource s;
  case((e,s)) then DAE.STMT_NORETCALL(e,s);
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
    case ((f :: r),fn,_)
      equation
        (f1_1,f2_1) = fn(f,extraArg);
        (r1_1,r2_1) = listMap1_2(r, fn,extraArg);
        r2_2 = listAppend(f2_1,r2_1);
      then
        ((f1_1 :: r1_1),r2_2);
  end match;
end listMap1_2;

public function listListMap1_2 "
  Takes a list and a function over the elements and an additional argument returning a tuple of
  two types, which is applied for each element producing two new lists.
  See also listMap_2."
  input list<list<Type_a>> inTypeALst;
  input FuncTypeType_aToType_bType_c inFuncTypeTypeAToTypeBTypeC;
  input Type_d extraArg;
  output list<list<Type_b>> outTypeBLst;
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
      list<Type_b> f1_1;
      list<Type_c> f2_1;
      list<list<Type_b>> r1_1;
      list<Type_c> r2_1,r2_2;
      list<Type_a> f;
      list<list<Type_a>> r;
      FuncTypeType_aToType_bType_c fn;
    case ({},_,_) then ({},{});
    case ((f :: r),fn,_)
      equation
        (f1_1,f2_1) = listMap1_2(f,fn,extraArg);
        (r1_1,r2_1) = listListMap1_2(r,fn,extraArg);
        r2_2 = listAppend(f2_1,r2_1);
      then
        ((f1_1 :: r1_1),r2_2);
  end match;
end listListMap1_2;

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

protected function getMinMaxValues
"extract min/max values from BackendDAE.Variable and check whether they are constant"
  input BackendDAE.Var inDAELowVar;
  output Option<DAE.Exp> outMinValue;
  output Option<DAE.Exp> outMaxValue;
algorithm
  (outMinValue, outMaxValue) := matchcontinue(inDAELowVar)
    local
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Exp minValue, maxValue;

    case(BackendDAE.VAR(varType=DAE.T_REAL(source=_), values=dae_var_attr))
      equation
        (SOME(minValue), SOME(maxValue)) = DAEUtil.getMinMaxValues(dae_var_attr);
        true = Expression.isConstValue(minValue);
        true = Expression.isConstValue(maxValue);
      then (SOME(minValue), SOME(maxValue));
      
    case(BackendDAE.VAR(varType=DAE.T_REAL(source=_), values=dae_var_attr))
      equation
        (SOME(minValue), NONE()) = DAEUtil.getMinMaxValues(dae_var_attr);
        true = Expression.isConstValue(minValue);
      then (SOME(minValue), NONE());
      
    case(BackendDAE.VAR(varType=DAE.T_REAL(source=_), values=dae_var_attr))
      equation
        (NONE(), SOME(maxValue)) = DAEUtil.getMinMaxValues(dae_var_attr);
        true = Expression.isConstValue(maxValue);
      then (NONE(), SOME(maxValue));
      
    else (NONE(), NONE());
  end matchcontinue;
end getMinMaxValues;

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
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE(), varType = DAE.T_STRING(source = _), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.STATE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), varType = DAE.T_STRING(source = _), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConstValue(e);
      then
        SOME(e);
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Expression.isConstValue(e);
      then
        SOME(e);
        /* String - Parameters without value binding. Investigate if it has start value */
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), varType = DAE.T_STRING(source = _), bindValue = NONE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
      then
        SOME(e);
        /* Parameters without value binding. Investigate if it has start value */
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), bindValue = NONE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Expression.isConstValue(e);
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
      DAE.Exp e;

    case (BackendDAE.VAR(varType = DAE.T_REAL(source = _), values = dae_var_attr)) equation
      e = DAEUtil.getNominalAttrFail(dae_var_attr);
      true = Expression.isConstValue(e);
    then SOME(e);
      
    case (_) equation
    then NONE();
  end matchcontinue;
end getNominalValue;


/****** HashTable ComponentRef -> SimCode.SimVar ******/
/* a workaround to enable "cross public import" */ 


/* HashTable instance specific code */

protected function hashFunc "
  author: PA

  Calculates a hash value for DAE.ComponentRef
"
  input SimCode.Key cr;
  output Integer res;
protected
  String crstr;
algorithm
  crstr := ComponentReference.printComponentRefStr(cr);
  res := stringHashDjb2(crstr);
end hashFunc;

protected function keyEqual
  input SimCode.Key key1;
  input SimCode.Key key2;
  output Boolean res;
algorithm
  res := ComponentReference.crefEqualNoStringCompare(key1,key2);
end keyEqual;

/* end of HashTable instance specific code */


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
  output SimCode.HashTableCrefToSimVar hashTable;
protected
  array<list<tuple<SimCode.Key,Integer>>> arr;
  list<Option<tuple<SimCode.Key,SimCode.Value>>> lst;
  array<Option<tuple<SimCode.Key,SimCode.Value>>> emptyarr;
algorithm
  arr := arrayCreate(1000, {});
  emptyarr := arrayCreate(100, NONE());
  hashTable := SimCode.HASHTABLE(arr,SimCode.VALUE_ARRAY(0,100,emptyarr),1000,0);
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
  input tuple<SimCode.Key,SimCode.Value> entry;
  input SimCode.HashTableCrefToSimVar hashTable;
  output SimCode.HashTableCrefToSimVar outHashTable;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      SimCode.ValueArray varr_1,varr;
      list<tuple<SimCode.Key,Integer>> indexes;
      array<list<tuple<SimCode.Key,Integer>>> hashvec_1,hashvec;
      tuple<SimCode.Key,SimCode.Value> v,newv;
      SimCode.Key key;
      SimCode.Value value;
      /* Adding when not existing previously */
    case ((v as (key,value)),(SimCode.HASHTABLE(hashvec,varr,bsize,n)))
      equation
        failure((_) = get(key, hashTable));
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then SimCode.HASHTABLE(hashvec_1,varr_1,bsize,n_1);
        
        /* adding when already present => Updating value */
    case ((newv as (key,value)),(SimCode.HASHTABLE(hashvec,varr,bsize,n)))
      equation
        (_,indx) = get1(key, hashTable);
        //print("adding when present, indx =" );print(intString(indx));print("\n");
        indx_1 = indx - 1;
        varr_1 = valueArraySetnth(varr, indx, newv);
      then SimCode.HASHTABLE(hashvec,varr_1,bsize,n);
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
  input tuple<SimCode.Key,SimCode.Value> entry;
  input SimCode.HashTableCrefToSimVar hashTable;
  output SimCode.HashTableCrefToSimVar outHashTable;
algorithm
  outHashTable := matchcontinue (entry,hashTable)
    local
      Integer hval,indx,newpos,n,n_1,bsize,indx_1;
      SimCode.ValueArray varr_1,varr;
      list<tuple<SimCode.Key,Integer>> indexes;
      array<list<tuple<SimCode.Key,Integer>>> hashvec_1,hashvec;
      String name_str;
      tuple<SimCode.Key,SimCode.Value> v,newv;
      SimCode.Key key;
      SimCode.Value value;
      
      // adding when not existing previously 
    case ((v as (key,value)),(hashTable as SimCode.HASHTABLE(hashvec,varr,bsize,n)))
      equation
        hval = hashFunc(key);
        indx = intMod(hval, bsize);
        newpos = valueArrayLength(varr);
        varr_1 = valueArrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, ((key,newpos) :: indexes));
        n_1 = valueArrayLength(varr_1);
      then SimCode.HASHTABLE(hashvec_1,varr_1,bsize,n_1);
        
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
  input SimCode.Key key;
  input SimCode.HashTableCrefToSimVar hashTable;
  output SimCode.Value value;
algorithm
  (value,_):= get1(key,hashTable);
end get;

protected function get1 "help function to get"
  input SimCode.Key key;
  input SimCode.HashTableCrefToSimVar hashTable;
  output SimCode.Value value;
  output Integer indx;
algorithm
  (value,indx):=
  match (key,hashTable)
    local
      Integer hval,hashindx,bsize,n;
      list<tuple<SimCode.Key,Integer>> indexes;
      SimCode.Value v;
      array<list<tuple<SimCode.Key,Integer>>> hashvec;
      SimCode.ValueArray varr;
      SimCode.Key k;
    case (_,(SimCode.HASHTABLE(hashvec,varr,bsize,n)))
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
  input SimCode.Key key;
  input list<tuple<SimCode.Key,Integer>> keyIndices;
  output Integer index;
algorithm
  index :=
  matchcontinue (key,keyIndices)
    local
      SimCode.Key key2;
      list<tuple<SimCode.Key,Integer>> xs;
    case (_,((key2,index) :: _))
      equation
        true = keyEqual(key, key2);
      then
        index;
    case (_,(_ :: xs))
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
 valLst := List.map(hashTableList(hashTable),Util.tuple22);
 end hashTableValueList;
 
 public function hashTableKeyList "return the Key entries as a list of Keys"
 input HashTableCrefToSimVar hashTable;
 output list<Key> valLst;
 algorithm
 valLst := List.map(hashTableList(hashTable),Util.tuple21);
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
  input SimCode.ValueArray valueArray;
  output Integer size;
algorithm
  size := match (valueArray)
    case (SimCode.VALUE_ARRAY(numberOfElements = size)) then size;
  end match;
end valueArrayLength;

public function valueArrayAdd "function: valueArrayAdd
  author: PA
  Adds an entry last to the ValueArray, increasing array size
  if no space left by factor 1.4
"
  input SimCode.ValueArray valueArray;
  input tuple<SimCode.Key,SimCode.Value> entry;
  output SimCode.ValueArray outValueArray;
algorithm
  outValueArray:=
  matchcontinue (valueArray,entry)
    local
      Integer n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<tuple<SimCode.Key,SimCode.Value>>> arr_1,arr,arr_2;
      Real rsize,rexpandsize;
    case (SimCode.VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),_)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(entry));
      then
        SimCode.VALUE_ARRAY(n_1,size,arr_1);
        
    case (SimCode.VALUE_ARRAY(numberOfElements = n,arrSize = size,valueArray = arr),_)
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
        SimCode.VALUE_ARRAY(n_1,newsize,arr_2);
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
  input SimCode.ValueArray valueArray;
  input Integer pos;
  input tuple<SimCode.Key,SimCode.Value> entry;
  output SimCode.ValueArray outValueArray;
algorithm
  outValueArray:=
  matchcontinue (valueArray,pos,entry)
    local
      array<Option<tuple<SimCode.Key,SimCode.Value>>> arr_1,arr;
      Integer n,size;
    case (SimCode.VALUE_ARRAY(n,size,arr),_,_)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(entry));
      then
        SimCode.VALUE_ARRAY(n,size,arr_1);
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
 Integer n,size;
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
  input SimCode.ValueArray valueArray;
  input Integer pos;
  output SimCode.Key key;
  output SimCode.Value value;
algorithm
  (key, value) :=
  matchcontinue (valueArray,pos)
    local
      SimCode.Key k;
      SimCode.Value v;
      Integer n;
      array<Option<tuple<SimCode.Key,SimCode.Value>>> arr;
    case (SimCode.VALUE_ARRAY(numberOfElements = n,valueArray = arr),_)
      equation
        (pos < n) = true;
        SOME((k,v)) = arr[pos + 1];
      then
        (k, v);
    case (SimCode.VALUE_ARRAY(numberOfElements = n,valueArray = arr),_)
      equation
        (pos < n) = true;
        NONE() = arr[pos + 1];
      then
        fail();
  end matchcontinue;
end valueArrayNth;


/***** end of HashTable ComponentRef -> SimCode.SimVar *******/

public function functionInfo
  input SimCode.Function fn;
  output Absyn.Info info;
algorithm
  info := match fn
    case SimCode.FUNCTION(info = info) then info;
    case SimCode.EXTERNAL_FUNCTION(info = info) then info;
    case SimCode.RECORD_CONSTRUCTOR(info = info) then info;
  end match;
end functionInfo;

public function eqInfo
  input SimCode.SimEqSystem eq;
  output Absyn.Info info;
algorithm
  info := match eq
    case SimCode.SES_RESIDUAL(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_SIMPLE_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_ARRAY_CALL_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_WHEN(source=DAE.SOURCE(info=info)) then info;
  end match;
end eqInfo;

function twodigit
  input Integer i;
  output String outS;
algorithm
  outS := 
  matchcontinue (i)
    local String s;
    case _
      equation
        (i < 10) = true;
        s = intString(i);
        s = stringAppend("0",s);
      then
        s;
    case _
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
  input BackendDAE.EqSystems inEqSystems;
  output list<tuple<DAE.ComponentRef, Integer>> outOrder;
algorithm outOrder := matchcontinue(inDlow,inEqSystems)
  local
    list<tuple<DAE.ComponentRef, Integer>> variableIndex;
     list<tuple<DAE.ComponentRef, Integer>> variableIndex2;
      list<tuple<DAE.ComponentRef, Integer>> variableIndex3;
    BackendDAE.EqSystem syst;
    BackendDAE.EqSystems systs;
 case(_,{})
     then
     {};
 case(_,syst::systs)
    equation
      Debug.fcall(Flags.CPP_VAR,print, " set  variabale der index for eqsystem"+& "\n");
     variableIndex =  setVariableDerIndex2(inDlow,syst);
      variableIndex2 = setVariableDerIndex(inDlow,systs);
    variableIndex3 = listAppend(variableIndex,variableIndex2);
      then
         variableIndex3; 
  case(_,_)
      equation
         print(" Failure in setVariableDerIndex \n");
         then fail();
 end matchcontinue;
end setVariableDerIndex;


protected function setVariableDerIndex2 "
Author bz 2008-06
This function investigates the system of equations finding an order for derivative variables.
It only selects variables that have an derivative order, order=0 (no derivative) will not be included.
" 
  input BackendDAE.BackendDAE inDlow;      
  input BackendDAE.EqSystem syst;
  output list<tuple<DAE.ComponentRef, Integer>> outOrder;
algorithm outOrder := matchcontinue(inDlow,syst)
  local
    BackendDAE.Variables dovars;
    BackendDAE.EquationArray deqns;
    list<BackendDAE.Equation> eqns;
    list<BackendDAE.Var> vars;
    list<Expression.Exp> derExps;
    list<tuple<DAE.ComponentRef, Integer>> variableIndex;
    list<list<DAE.ComponentRef>> firstOrderVars;
    list<DAE.ComponentRef> firstOrderVarsFiltered;
  case(_,_)
    equation
      Debug.fcall(Flags.CPP_VAR,print, " set variabale der index"+& "\n");
      dovars = BackendVariable.daeVars(syst);
      deqns = BackendEquation.daeEqns(syst);
      vars = BackendDAEUtil.varList(dovars);
      eqns = BackendDAEUtil.equationList(deqns);
      derExps = makeCallDerExp(vars);
      Debug.fcall(Flags.CPP_VAR,print, " possible der exp: " +& stringDelimitList(List.map(derExps, ExpressionDump.printExpStr), ", ") +& "\n");
      eqns = flattenEqns(eqns,inDlow);
     // eq_str=dumpEqLst(eqns);
      // Debug.fcall(Flags.CPP_VAR,print,"filtered eq's " +& eq_str +& "\n");
      (variableIndex,firstOrderVars) = List.map2_2(derExps,locateDerAndSerachOtherSide,eqns,eqns);
       Debug.fcall(Flags.CPP_VAR,print,"united variables \n");
      firstOrderVarsFiltered = List.fold(firstOrderVars,List.union,{});
      Debug.fcall(Flags.CPP_VAR,print,"list fold variables \n");
      variableIndex = setFirstOrderInSecondOrderVarIndex(variableIndex,firstOrderVarsFiltered);
     // Debug.fcall(Flags.CPP_VAR,print,"Deriving Variable indexis:\n" +& dumpVariableindex(variableIndex) +& "\n");
     then
      variableIndex;
  case(_,_)
      equation
         print(" Failure in setVariableDerIndex2 \n");
         then fail();
 end matchcontinue;
end setVariableDerIndex2;




protected function flattenEqns "
This function flattens all equations
"
input list<BackendDAE.Equation> eqns;
input BackendDAE.BackendDAE dlow;
output list<BackendDAE.Equation> oeqns;
algorithm oeqns := matchcontinue(eqns, dlow)
  local 
    BackendDAE.Equation eq;
    list<BackendDAE.Equation> rest,rec;
    String str;
  case({},_) then {};
    case( (eq as BackendDAE.EQUATION(exp=_)) ::rest , _)
    equation
      rec = flattenEqns(rest,dlow);
      rec = List.unionElt(eq,rec);
      then
        rec;
     case( (eq as BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(condition=_))) ::rest , _)
     equation
       str = BackendDump.equationStr(eq);
       Debug.fcall(Flags.CPP_VAR,print,"Found When eq " +& str +& "\n");
       rec = flattenEqns(rest,dlow);
       //rec = List.unionElt(eq,rec);
      then
        rec;
     case( (eq as BackendDAE.ALGORITHM(size=_)) ::rest , _)
     equation
       //str = DAELow.equationStr(eq);
       rec = flattenEqns(rest,dlow);
       rec = List.unionElt(eq,rec);
      then
        rec;
     case( (eq as BackendDAE.ARRAY_EQUATION(dimSize=_)) ::rest , _)
     equation
       //str = DAELow.equationStr(eq);
       rec = flattenEqns(rest,dlow);
       rec = List.unionElt(eq,rec);
      then
        rec;        
     case( (eq as BackendDAE.COMPLEX_EQUATION(size=_)) ::rest , _)
     equation
       //str = DAELow.equationStr(eq);
       rec = flattenEqns(rest,dlow);
       rec = List.unionElt(eq,rec);
      then
        rec;                     
  case(_::rest,_)
    equation 
     // str = BackendDAE.equationStr(eq);
      Debug.fcall(Flags.CPP_VAR,print," FAILURE IN flattenEqns possible unsupported equation...\n" /*+& str*/);
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
      DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(cr,DAE.T_REAL_DEFAULT)},DAE.callAttrBuiltinReal)::rec;
  //case((v as DAELow.VAR(varKind = DAELow.DUMMY_STATE(),varName = cr))::vars)
   // equation
      //true = DAELow.isStateVar(v);
   //   rec = makeCallDerExp(vars);
   // then
    //  DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(cr,DAE.T_UNKNOWN_DEFAULT)},false,false,DAE.T_UNKNOWN_DEFAULT,DAE.NO_INLINE())::rec;
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
    list<BackendDAE.Equation> eqs, eqsOrg;
    BackendDAE.Equation eq;
    list<DAE.ComponentRef> crefs;
    DAE.ComponentRef cr;
    Integer rec,i1;
    tuple<DAE.ComponentRef, Integer> highestIndex;
    
  case( (DAE.CALL( expLst = {DAE.CREF(cr,_)})), {},_) then ((cr,0),{});
  case( (DAE.CALL( expLst = {deriveVar as DAE.CREF(cr,_)})), (eq as BackendDAE.EQUATION(e1,e2,_))::eqs,_)
    equation
      true = Expression.expEqual(e1,derExp);
      eqsOrg = List.removeOnTrue(eq,Util.isEqual,inEqnsOrg);
      Debug.fcall(Flags.CPP_VAR,print, "\nFound equation containing " +& ExpressionDump.printExpStr(derExp) +& " Other side: " +& ExpressionDump.printExpStr(e2) +& ", extracted crefs: " +& ExpressionDump.printExpStr(deriveVar) +& "\n");
      (rec,crefs) = locateDerAndSerachOtherSide2(DAE.CALL(Absyn.IDENT("der"),{e2},DAE.callAttrBuiltinReal),eqsOrg);
      (highestIndex as (_,i1),_) = locateDerAndSerachOtherSide(derExp,eqs,eqsOrg);
      rec = rec+1;
      highestIndex = Util.if_(i1>rec,highestIndex,(cr,rec-1));
      //highestIndex = (cr,1);
    then
      (highestIndex,crefs);
  case( (DAE.CALL( expLst = {deriveVar as DAE.CREF(cr,_)})), (eq as BackendDAE.EQUATION(e1,e2,_))::eqs,_)
    equation
      true = Expression.expEqual(e2,derExp);
      eqsOrg = List.removeOnTrue(eq,Util.isEqual,inEqnsOrg);
      Debug.fcall(Flags.CPP_VAR,print, "\nFound equation containing " +& ExpressionDump.printExpStr(derExp) +& " Other side: " +& ExpressionDump.printExpStr(e1) +& ", extracted crefs: " +& ExpressionDump.printExpStr(deriveVar) +& "\n");
      (rec,crefs) = locateDerAndSerachOtherSide2(DAE.CALL(Absyn.IDENT("der"),{e1},DAE.callAttrBuiltinReal),eqsOrg);
      (highestIndex as (_,i1),_) = locateDerAndSerachOtherSide(derExp,eqs,eqsOrg);
      rec = rec+1;
      highestIndex = Util.if_(i1>rec,highestIndex,(cr,rec-1));
      //highestIndex = (cr,1);
    then
      (highestIndex,crefs);
  case(_, (eq as BackendDAE.EQUATION(e1,e2,_))::eqs,_)
    equation
      false = Expression.expEqual(e1,derExp);
      false = Expression.expEqual(e2,derExp);
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);
  case(_, (eq as BackendDAE.ARRAY_EQUATION(left=e1,right=e2))::eqs,_)
    equation
      false = Expression.expEqual(e1,derExp);
      false = Expression.expEqual(e2,derExp);
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs); 
  case(_, (eq as BackendDAE.COMPLEX_EQUATION(left=e1,right=e2))::eqs,_)
    equation
      false = Expression.expEqual(e1,derExp);
      false = Expression.expEqual(e2,derExp);
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);             
  case(_, (eq as BackendDAE.IF_EQUATION(conditions=_))::eqs,_)
    equation
      Debug.fcall(Flags.CPP_VAR,print, "\nFound  if equation is not supported yet  searching for varibale index  \n");
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);
 case(_, (eq as BackendDAE.ALGORITHM(alg=_))::eqs,_)
    equation
      Debug.fcall(Flags.CPP_VAR,print, "\nFound  algorithm is not supported yet  searching for varibale index  \n");
      (highestIndex,crefs) = locateDerAndSerachOtherSide(derExp,eqs,inEqnsOrg);
    then
      (highestIndex,crefs);
 
end matchcontinue;
end locateDerAndSerachOtherSide;

protected function locateDerAndSerachOtherSide2 "
Author bz 2008-06
helper function for locateDerAndSerachOtherSide"
  input Expression.Exp inDer;
  input list<BackendDAE.Equation> inEqns;
  output Integer oi;
  output list<DAE.ComponentRef> firstOrderDers;
algorithm (oi,firstOrderDers) := matchcontinue(inDer,inEqns)
  case(DAE.CALL(expLst = {DAE.CREF(_,_)}),_)
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
    list<BackendDAE.Equation> rest;
  case(_,{}) then (0,{});
  case(_,(BackendDAE.EQUATION(e1,e2,_)::rest))
    equation
      true = Expression.expEqual(inDer,e1);
      {cr} = Expression.extractCrefsFromExp(e1);
      Debug.fcall(Flags.CPP_VAR,BackendDump.debugStrExpStrExpStrExpStr,(" found derivative for ",inDer," in equation ",e1," = ",e2, "\n"));
    then
      (1,{cr});
  case(_,(BackendDAE.EQUATION(e1,e2,_)::rest))
    equation
      true = Expression.expEqual(inDer,e2);
      {cr} = Expression.extractCrefsFromExp(e2);
      Debug.fcall(Flags.CPP_VAR,BackendDump.debugStrExpStrExpStrExpStr,(" found derivative for ",inDer," in equation ",e1," = ",e2,"\n"));
    then
      (1,{cr});
  case(_,(BackendDAE.EQUATION(e1,e2,_)::rest))
    equation
      Debug.fcall(Flags.CPP_VAR,BackendDump.debugExpStrExpStrExpStr,(inDer," NOT contained in ",e1," = ",e2,"\n"));
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
  case((cr,_)::rest,_)
    equation
      bl = List.map1(firstOrderInSec,ComponentReference.crefEqual,cr);
      true = Util.boolOrList(bl);
      rest = setFirstOrderInSecondOrderVarIndex(rest,firstOrderInSec);
    then
      (cr,2)::rest;
  case((cr,1)::rest,_)
    equation      
      rest = setFirstOrderInSecondOrderVarIndex(rest,firstOrderInSec);
    then
      (cr,1)::rest;
  case((cr,idx)::rest,_)
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
    BackendDAE.EqSystems eqsystems;
  case(BackendDAE.DAE(eqs=eqsystems))
    equation
       ordered_states=setVariableDerIndex(dae_low,eqsystems);
      (nvar1,nvar2)=calculateVariableDimensions(ordered_states);
      then
        (nvar1,nvar2);
  case(_)
    equation print(" failure in dimensions  \n"); then fail();
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
  case (_,{}) then (-1);
  case (_,((cr,i)::_))    
    equation
      true = ComponentReference.crefEqual(var,cr);
    Debug.fcall(Flags.CPP_VAR_INDEX,BackendDump.debugStrCrefStrIntStr,(" found state variable ",var," with index: ",i,"\n"));
  // Debug.fcall(Flags.CPP_VAR,print, +& " with index: " +& intString(i) +& "\n");
    then 
      (i);
  case(_,_::rest)
    equation
     
      (i)=stateindex(var,rest);
       Debug.fcall(Flags.CPP_VAR_INDEX,BackendDump.debugStrCrefStrIntStr,(" state variable ",var," with index: ",i,"\n"));
  
   //  Debug.fcall(Flags.CPP_VAR,print, +& " with index: " +& intString(i) +& "\n");
    then (i);
end matchcontinue;
end stateindex;

protected function stateindex1

 
 input list<SimCode.SimVar> stateVars;
 input BackendDAE.BackendDAE dae_low;
 output list<SimCode.SimVar> stateVars1;
algorithm (stateVars1):= matchcontinue(stateVars,dae_low)
  local 
     list<SimCode.SimVar> new_list;
     SimCode.SimVar new_simvar;
     SimCode.SimVar v;
     list<SimCode.SimVar> rest;
  case({},_)
     then 
       {};
  case((v as SimCode.SIMVAR(name=_))::rest,_)
     equation
      new_list= stateindex1(rest,dae_low);
      new_simvar =stateindex2(v,dae_low);
    
     then
      (new_simvar::new_list);
   case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"stateindex1 failed"});
      then
        fail();
end matchcontinue;
end stateindex1;

protected function stateindex2
 input SimCode.SimVar stateVars;
 input BackendDAE.BackendDAE dae_low;
 output SimCode.SimVar outSimVar;
algorithm (outSimVar):= match(stateVars,dae_low)
  local 
    list<tuple<DAE.ComponentRef, Integer>> ordered_states;
    Integer new_index;
    DAE.ComponentRef name;
    BackendDAE.VarKind varKind;
    String comment,unit,displayUnit;
    Integer index;
    Option<DAE.Exp> minValue;
    Option<DAE.Exp> maxValue;
    Option<DAE.Exp> initialValue;
    Option<DAE.Exp> nominalValue;
    Boolean isFixed,isDiscrete;
    DAE.Type type_;
    // arrayCref is the name of the array if this variable is the first in that
    // array
    Option<DAE.ComponentRef> arrayCref;
    SimCode.AliasVariable aliasvar;
    DAE.ElementSource source;
    SimCode.Causality causality;
    Option<Integer> variable_index;
    list<String> numArrayElement;
    BackendDAE.EqSystems eqsystems;
  case(SimCode.SIMVAR(name=name,varKind=varKind,comment=comment,unit=unit,displayUnit=displayUnit,index=index,minValue=minValue,maxValue=maxValue,initialValue=initialValue,nominalValue=nominalValue,isFixed=isFixed,type_=type_,isDiscrete=isDiscrete,arrayCref=arrayCref,aliasvar=aliasvar,source=source,causality=causality,variable_index=variable_index,numArrayElement=numArrayElement),BackendDAE.DAE(eqs=eqsystems))
     equation
      Debug.fcall(Flags.CPP_VAR_INDEX,BackendDump.debugStrCrefStr,(" search index for state variable ",name,"\n"));
      ordered_states=setVariableDerIndex(dae_low,eqsystems);
      new_index=stateindex(name,ordered_states);
           
    then 
     SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,new_index,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
end match;
end stateindex2;


protected function setStatesVectorIndex "
sorts the states in the state vector correponding to the variable index (0,1,2) and
sets the vectorindex attribute for each state variable in the states vector(z)
e.g der(x)=y
    der(y)=a
    der(z)=a -> z={z,x,y}
"
input list<SimCode.SimVar> in_vars;
output list<SimCode.SimVar> out_vars;
algorithm out_vars := matchcontinue(in_vars)
  local
    list<SimCode.SimVar>  vars1,vars2,vars3,vars4,vars5;
  case _
    equation
      (vars1,vars2,vars3) =  partitionStatesVector(in_vars);
       vars4 = listAppend(vars1,vars2);
       vars5 = listAppend(vars4,vars3);
       vars5=setStatesVectorIndex2(vars5,0);
    then 
       vars5;
   case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"setStatesVectorIndex failed"});
      then
        fail();
end matchcontinue;
end setStatesVectorIndex;

protected function setStatesVectorIndex2"
Help function for setStatesVectorIndex
iterates the states vector an increments the vector index of each variable
"
input list<SimCode.SimVar> in_vars;
input Integer index;
output list<SimCode.SimVar> out_vars;
algorithm
  out_vars := match(in_vars,index)
    local
      DAE.ComponentRef name;
      BackendDAE.VarKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Option<DAE.Exp> minValue;
      Option<DAE.Exp> maxValue;
      Option<DAE.Exp> initialValue;
      Option<DAE.Exp> nominalValue;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      // arrayCref is the name of the array if this variable is the first in that
      // array
      Option<DAE.ComponentRef> arrayCref;
      SimCode.AliasVariable aliasvar;
      DAE.ElementSource source;
      SimCode.Causality causality;
      Option<Integer> variable_index;
      list<SimCode.SimVar> rest,indexed_vector;
      list<String> numArrayElement;
    case({},_) then {};
    case(SimCode.SIMVAR(name=name,varKind=varKind,comment=comment,unit=unit,displayUnit=displayUnit,minValue=minValue,maxValue=maxValue,initialValue=initialValue,nominalValue=nominalValue,isFixed=isFixed,type_=type_,isDiscrete=isDiscrete,arrayCref=arrayCref,aliasvar=aliasvar,source=source,causality=causality,variable_index=variable_index,numArrayElement=numArrayElement) :: rest,_)
      equation
        indexed_vector = setStatesVectorIndex2(rest,index+1);
      then 
        SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,SOME(index),numArrayElement)::indexed_vector;
  end match;
end setStatesVectorIndex2;


protected function partitionStatesVector "
partitioning the input vector into 3 state vectors  including   variables with corresponding variable indexes 0,1,2  
e.g  der(x) = y;
     der(y)= a;
     der(z) =a;
     z=b -> output:  {z} {x} {y}
"
  input list<SimCode.SimVar> in_vars "list with unsorted state variables";
  output list<SimCode.SimVar> oder_0;
  output list<SimCode.SimVar> oder_1;
  output list<SimCode.SimVar> oder_2;
algorithm (oder_0,oder_1,oder_2):= match(in_vars)
  local
    list<SimCode.SimVar> rest, vars1,vars2,vars3;
    SimCode.SimVar variable;
    Integer vi;
  case({}) then ({},{},{});
  case((variable as SimCode.SIMVAR(index=vi))::rest)
    equation
      (vars1,vars2,vars3)    =    partitionStatesVector(rest);
      (vars1,vars2,vars3)    =    addVariableToStateVector(vars1,vars2,vars3,variable,vi);
    then 
     (vars1,vars2,vars3);
 
end match;
end partitionStatesVector;

protected function addVariableToStateVector "
Helper function for setVectorIndexes;
"
  input list<SimCode.SimVar> in_0;
  input list<SimCode.SimVar> in_1;
  input list<SimCode.SimVar> in_2;
  input SimCode.SimVar variable;
  input Integer variable_index;
  output list<SimCode.SimVar>  out_0;
  output list<SimCode.SimVar>  out_1;
  output list<SimCode.SimVar>  out_2;
algorithm (out_0,out_1,out_2) := matchcontinue(in_0,in_1,in_2,variable,variable_index)
  case (_,_,_,_,0) then (variable::in_0,in_1,in_2);
  case (_,_,_,_,1) then (in_0,variable::in_1,in_2);
  case (_,_,_,_,2) then (in_0,in_1,variable::in_2);
  case(_,_,_,_,_) equation print(" failure in addVariableToStateVector  \n"); then fail();
end matchcontinue;
end addVariableToStateVector;

protected function generateDerStates "
generates for each state in the states vector a corresponding der state
"
  input list<SimCode.SimVar> in_varinfo_lst;
  output list<SimCode.SimVar> out_varinfo_lst;
algorithm out_varinfo_lst := matchcontinue(in_varinfo_lst)
  local 
    list<SimCode.SimVar> rest,dv_list;
    SimCode.SimVar v;
    SimCode.SimVar dv;
  case({}) then {};
  case( v::rest )
    equation
      dv = generateDerStates2(v);
     // s= dumpVarInfo(dv);
      //Debug.fcall(Flags.CPP_VAR,print,"Generate der state" +& s +& "\n" );
      dv_list = generateDerStates(rest);
     then
       dv::dv_list;
   case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generateDerStates failed"});
      then
        fail();   
  end matchcontinue;
end generateDerStates;

protected function generateDerStates2 "
Helper function for varsToVarInfo2
"
   input SimCode.SimVar in_vf;
   output SimCode.SimVar out_vf;
 
algorithm
  out_vf := match(in_vf)
    local 
      DAE.ComponentRef name;
      BackendDAE.VarKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Option<DAE.Exp> minValue;
      Option<DAE.Exp> maxValue;
      Option<DAE.Exp> initialValue;
      Option<DAE.Exp> nominalValue;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      // arrayCref is the name of the array if this variable is the first in that
      // array
      Option<DAE.ComponentRef> arrayCref;
      SimCode.AliasVariable aliasvar;
      DAE.ElementSource source;
      SimCode.Causality causality;
      Option<Integer> variable_index;
      DAE.ComponentRef cr_1;
      String name_str,id_str;
      list<String> numArrayElement;
      Integer i;
    /*case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,0,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)) 
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = stringAppendList({DAE.derivativeNamePrefix,"." ,name_str});
        cr_1 = ComponentReference.makeCrefIdent(id_str,DAE.T_REAL_DEFAULT,{});
      then
        SimCode.SIMVAR(cr_1,varKind,comment,unit,displayUnit,0,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
    case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,1,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)) 
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = stringAppendList({DAE.derivativeNamePrefix,".",name_str});
        cr_1 = ComponentReference.makeCrefIdent(id_str,DAE.T_REAL_DEFAULT,{});
      then
        SimCode.SIMVAR(cr_1,varKind,comment,unit,displayUnit,1,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
    
    case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,2,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)) 
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = stringAppendList({DAE.derivativeNamePrefix,".",name_str});
        cr_1 = ComponentReference.makeCrefIdent(id_str,DAE.T_REAL_DEFAULT,{});
      then
        SimCode.SIMVAR(cr_1,varKind,comment,unit,displayUnit,2,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
       */
     case(SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,i,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)) 
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = stringAppendList({DAE.derivativeNamePrefix,".",name_str});
        cr_1 = ComponentReference.makeCrefIdent(id_str,DAE.T_REAL_DEFAULT,{});
      then
        SimCode.SIMVAR(cr_1,varKind,comment,unit,displayUnit,i,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement);
    /*case (SimCode.SIMVAR(name,_,_,_,_,i,_,_,_,_,_,_,_,_,_,_,_))
      equation
        name_str = ComponentReference.printComponentRefStr(name);
        id_str = intString(i);
        Debug.fcall(Flags.CPP,print,"generateDerStates2 failed for " +& name_str +& "and index " +& id_str +& "\n" );
        Error.addMessage(Error.INTERNAL_ERROR, {"generateDerStates2 failed " });
      then
        fail();
        */   
  end match;
end generateDerStates2;


protected function replaceindex 

  input SimCode.SimVar var;
  input list<SimCode.SimVar> statevarlist;
  output SimCode.SimVar newvar;
algorithm
  newvar := matchcontinue(var,statevarlist)
    local
      list<SimCode.SimVar> rest1;
      DAE.ComponentRef name,name1;
      BackendDAE.VarKind varKind;
      String comment;
      String unit;
      String displayUnit;
      Integer index,index1;
      Option<DAE.Exp> minValue;
      Option<DAE.Exp> maxValue;
      Option<DAE.Exp> initialValue;
      Option<DAE.Exp> nominalValue;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      SimCode.AliasVariable aliasvar;
      DAE.ElementSource source;
      SimCode.Causality causality;
      Option <Integer> variable_index;
      Integer variable_index1;
      SimCode.SimVar v,newvar1;
      list<String> numArrayElement;
  case((v as SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)),SimCode.SIMVAR(name=name1,index=index1,variable_index=SOME(variable_index1))::_)    
    equation
      Debug.fcall(Flags.CPP_VAR_INDEX,BackendDump.debugStrCrefStrCrefStr,(" compare variable ",name,"with ",name1,"\n"));
      true = ComponentReference.crefEqual(name,name1);
    then 
      SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,variable_index1,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,SOME(index1),numArrayElement);
  case((v as SimCode.SIMVAR(name,varKind,comment,unit,displayUnit,index,minValue,maxValue,initialValue,nominalValue,isFixed,type_,isDiscrete,arrayCref,aliasvar,source,causality,variable_index,numArrayElement)),_::rest1)
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

 input list<SimCode.SimVar> Vars;
 input list<SimCode.SimVar> stateVars;
 output list<SimCode.SimVar> newVars;
algorithm (newVars):= match(Vars,stateVars)
  local 
     list<SimCode.SimVar> new_list;
     SimCode.SimVar new_simvar;
     SimCode.SimVar v;
     list<SimCode.SimVar> rest;
  case({},_)
     then 
       {};
  case((v as SimCode.SIMVAR(name=_))::rest,_)
     equation
      new_list= replaceindex1(rest,stateVars);
      new_simvar =replaceindex(v,stateVars);
    
     then
      (new_simvar::new_list);
end match;

end replaceindex1;


public function varName
  input SimCode.SimVar var;
  output DAE.ComponentRef name;
algorithm
  SimCode.SIMVAR(name=name) := var;
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
        Debug.fcall(Flags.CPP_SIM1,print, "arraydim1: " +& res  +& "\n" );
      then
        res;
    case (DAE.INDEX(exp = DAE.ENUM_LITERAL(name = enum_lit)))
      equation
        res = Absyn.pathString(enum_lit);
        Debug.fcall(Flags.CPP_SIM1,print, "arraydim2: " +& res  +& "\n" );
      then
        res;
  end match;
end arraydim;

public function countDynamicExternalFunctions
  input list<SimCode.Function> inFncLst;
  output Integer outDynLoadFuncs;
algorithm
  outDynLoadFuncs:= matchcontinue(inFncLst)
  local 
     list<SimCode.Function> rest;
     SimCode.Function fn;
     Integer i;
  case({})
     then 
       0;
  case(SimCode.EXTERNAL_FUNCTION(dynamicLoad=true)::rest)
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
  input SimCode.SimVar inSimVar;
  input SimCode.Files inFiles;
  output SimCode.SimVar outSimVar;
  output SimCode.Files outFiles;
algorithm
  (outSimVar,outFiles) := match(inSimVar, inFiles)
    local
      SimCode.Files files;
      DAE.ElementSource source;
      
    case (SimCode.SIMVAR(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimVar,files);               
  end match;
end getFilesFromSimVar;

public function arraydim1 ""
  input list<DAE.Subscript> subscript1;
  output list<String> outString;
algorithm outString := match(subscript1)
  local
     DAE.Subscript subscript;
    String s1;
    list<String> s2;
    list<DAE.Subscript> rest;
  case({}) then {};
  case( subscript::rest )
    equation
      s1=  arraydim(subscript);
      s2= arraydim1(rest);
    then
       (s1 :: s2);
end match;
end arraydim1;

protected function getFilesFromSimVars
  input SimCode.SimVars inSimVars;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inSimVars, inFiles)
    local
      SimCode.Files files;
      list<SimCode.SimVar> stateVars,derivativeVars,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,intAliasVars,
                   boolAliasVars,paramVars,intParamVars,boolParamVars,stringAlgVars,stringParamVars,stringAliasVars,
                   extObjVars,constVars,intConstVars,boolConstVars,stringConstVars;      
      
    case (SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars, 
                  paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars,intConstVars,boolConstVars,stringConstVars),
          files)
      equation
        (_, files) = List.mapFoldList(
                       {stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars, 
                        paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars,intConstVars,boolConstVars,stringConstVars}, 
                       getFilesFromSimVar, files);
      then 
        files;               
  end match;
end getFilesFromSimVars;

protected function getFilesFromFunctions
  input list<SimCode.Function> functions;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(functions, inFiles)
    local
      SimCode.Files files;
      list<SimCode.Function> rest;
      Absyn.Info info;

    // handle empty
    case ({}, files) then files;
    
    // handle FUNCTION
    case (SimCode.FUNCTION(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);        
      then
        files;

    // handle EXTERNAL_FUNCTION
    case (SimCode.EXTERNAL_FUNCTION(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);        
      then
        files;
    
    // handle RECORD_CONSTRUCTOR
    case (SimCode.RECORD_CONSTRUCTOR(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);
      then
        files;
  end match;
end getFilesFromFunctions;

protected function getFilesFromSimEqSystemOpt
  input Option<SimCode.SimEqSystem> inSimEqSystemOpt;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inSimEqSystemOpt, inFiles)
    local
      SimCode.Files files;
      SimCode.SimEqSystem sys;
      
    case (NONE(), files) then files;
    case (SOME(sys), files)
      equation
        (_, files) = getFilesFromSimEqSystem(sys, files);
      then 
        files;
  end match;
end getFilesFromSimEqSystemOpt;

protected function getFilesFromSimEqSystem
  input SimCode.SimEqSystem inSimEqSystem;
  input SimCode.Files inFiles;
  output SimCode.SimEqSystem outSimEqSystem;
  output SimCode.Files outFiles;  
algorithm
  (outSimEqSystem,outFiles) := match(inSimEqSystem, inFiles)
    local
      SimCode.Files files;
      DAE.ElementSource source;
      list<DAE.Statement> statements;
      list<SimCode.SimVar> vars;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      list<SimCode.SimEqSystem> systems;
      SimCode.SimEqSystem system;
      Option<SimCode.SimEqSystem> systemOpt;
      
    case (SimCode.SES_RESIDUAL(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimEqSystem,files);
    
    case (SimCode.SES_SIMPLE_ASSIGN(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimEqSystem,files);
    
    case (SimCode.SES_ARRAY_CALL_ASSIGN(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then 
        (inSimEqSystem,files);
        
    case (SimCode.SES_ALGORITHM(statements=statements), files)
      equation
        files = getFilesFromStatements(statements, files);
      then 
        (inSimEqSystem,files);
    
    case (SimCode.SES_LINEAR(vars = vars, simJac = simJac), files)
      equation
        (_, files) = List.mapFold(vars, getFilesFromSimVar, files);
        systems = List.map(simJac, Util.tuple33);
        files = getFilesFromSimEqSystems({systems}, files);
      then 
        (inSimEqSystem,files);
    
    case (SimCode.SES_NONLINEAR(eqs = systems), files)
      equation
        files = getFilesFromSimEqSystems({systems}, files);
      then 
        (inSimEqSystem,files);
    
    case (SimCode.SES_MIXED(cont = system, discVars = vars, discEqs = systems), files)
      equation
        (_, files) = List.mapFold(vars, getFilesFromSimVar, files);
        files = getFilesFromSimEqSystems({system::systems}, files);
      then 
        (inSimEqSystem,files);
        
    case (SimCode.SES_WHEN(source = source, elseWhen = systemOpt), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromSimEqSystemOpt(systemOpt, files);
      then 
        (inSimEqSystem,files);
        
  end match;
end getFilesFromSimEqSystem;

protected function getFilesFromSimEqSystems
  input list<list<SimCode.SimEqSystem>> inSimEqSystems;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inSimEqSystems, inFiles)
    local
      SimCode.Files files;
      
    case (inSimEqSystems, files)
      equation
        (_, files) = List.mapFoldList(inSimEqSystems, getFilesFromSimEqSystem, files);
      then 
        files;               
  end match;
end getFilesFromSimEqSystems;

protected function getFilesFromStatementsElse
  input DAE.Else inElse;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inElse, inFiles)
    local
      SimCode.Files files;
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
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inStatementOpt, inFiles)
    local
      SimCode.Files files;
      DAE.Statement stmt;
      
    case (NONE(), files) then files;
    case (SOME(stmt), files) then getFilesFromStatements({stmt}, files);
  end match;
end getFilesFromStatementsElseWhen;

protected function getFilesFromStatements
  input list<DAE.Statement> inStatements;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inStatements, inFiles)
    local
      SimCode.Files files;
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
    
    case (DAE.STMT_PARFOR(source = source, statementLst = stmts)::rest, files)
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
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inWhenOperators, inFiles)
    local
      SimCode.Files files;
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
  input list<SimCode.SimWhenClause> inSimWhenClauses;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inSimWhenClauses, inFiles)
    local
      SimCode.Files files;
      list<SimCode.SimWhenClause> rest;
      list<BackendDAE.WhenOperator> reinits; 
      
    // handle empty
    case ({}, files) then files;
      
    case (SimCode.SIM_WHEN_CLAUSE(reinits = reinits)::rest, files)
      equation
        files = getFilesFromWhenClausesReinits(reinits, files);
        files = getFilesFromWhenClauses(rest, files);
      then 
        files;
    
  end match;
end getFilesFromWhenClauses;

protected function getFilesFromExtObjInfo
  input SimCode.ExtObjInfo inExtObjInfo;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inExtObjInfo, inFiles)
    local
      SimCode.Files files;
      list<SimCode.SimVar> vars;
      
    case (SimCode.EXTOBJINFO(vars = vars), files)
      equation
        (_, files) = List.mapFold(vars, getFilesFromSimVar, files);
      then 
        files;
    
  end match;
end getFilesFromExtObjInfo;

protected function getFilesFromJacobianMatrixes
  input list<SimCode.JacobianMatrix> inJacobianMatrixes;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inJacobianMatrixes, inFiles)
    local
      SimCode.Files files;
      list<SimCode.JacobianMatrix> rest;
      list<SimCode.JacobianColumn> onemat;
      list<SimCode.SimEqSystem> systems;
      list<SimCode.SimVar> vars;
   
    // handle empty   
    case ({}, files) then files;
    
    // handle rest  
    case ((onemat,_,_,_,_,_)::rest, files)
      equation
        files = getFilesFromJacobianMatrix(onemat, files);
        files = getFilesFromJacobianMatrixes(rest, files);
      then 
        files;

  end match;
end getFilesFromJacobianMatrixes;

protected function getFilesFromJacobianMatrix
  input list<SimCode.JacobianColumn> inJacobianMatrixes;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inJacobianMatrixes, inFiles)
    local
      SimCode.Files files;
      list<SimCode.JacobianColumn> rest;
      list<SimCode.SimEqSystem> systems;
      list<SimCode.SimVar> vars;
   
    // handle empty   
    case ({}, files) then files;
    
    // handle rest  
    case ((systems, vars, _)::rest, files)
      equation
        files = getFilesFromSimEqSystems({systems}, files);
        (_, files) = List.mapFold(vars, getFilesFromSimVar, files);
        files = getFilesFromJacobianMatrix(rest, files);
      then 
        files;

  end match;
end getFilesFromJacobianMatrix;

protected function collectAllFiles
  input SimCode.SimCode inSimCode;
  output SimCode.SimCode outSimCode;
algorithm
  outSimCode := matchcontinue(inSimCode)
    local
      SimCode.ModelInfo modelInfo;
      list<DAE.Exp> literals "shared literals";
      list<SimCode.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<list<SimCode.SimEqSystem>> odeEquations;
      list<SimCode.SimEqSystem> allEquations,algebraicEquations,residualEquations,startValueEquations,parameterEquations,removedEquations,sampleEquations,algorithmAndEquationAsserts;
      list<SimCode.SimEqSystem> initialEquations;
      list<DAE.Constraint> constraints;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<SimCode.SampleCondition> sampleConditions;
      list<SimCode.HelpVarInfo> helpVarInfo;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      list<String> labels;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      Absyn.Path name;
      String directory;
      SimCode.VarInfo varInfo;
      SimCode.SimVars vars;
      list<SimCode.Function> functions;
      SimCode.Files files "all the files from Absyn.Info and DAE.ELementSource";      

    case inSimCode
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
        inSimCode;
    
    case SimCode.SIMCODE(modelInfo,literals,recordDecls,externalFunctionIncludes,allEquations,odeEquations,algebraicEquations,residualEquations,initialEquations,startValueEquations, 
                 parameterEquations,removedEquations,algorithmAndEquationAsserts,constraints,zeroCrossings,sampleConditions,sampleEquations,helpVarInfo,whenClauses,
                 discreteModelVars,extObjInfo,makefileParams,delayedExps,jacobianMatrixes,simulationSettingsOpt,fileNamePrefix,crefToSimVarHT)
      equation
        SimCode.MODELINFO(name, directory, varInfo, vars, functions, labels) = modelInfo;
        files = {};
        files = getFilesFromSimVars(vars, files);
        files = getFilesFromFunctions(functions, files);
        files = getFilesFromSimEqSystems(allEquations::algebraicEquations::residualEquations::
                                         startValueEquations::parameterEquations::removedEquations::algorithmAndEquationAsserts::sampleEquations::odeEquations, files);
        files = getFilesFromWhenClauses(whenClauses, files);   
        files = getFilesFromExtObjInfo(extObjInfo, files);
        files = getFilesFromJacobianMatrixes(jacobianMatrixes, files);
        files = List.sort(files, greaterFileInfo);
        modelInfo = SimCode.MODELINFO(name, directory, varInfo, vars, functions, labels);
      then
        SimCode.SIMCODE(modelInfo,literals,recordDecls,externalFunctionIncludes,allEquations,odeEquations,algebraicEquations,residualEquations,initialEquations,startValueEquations, 
                  parameterEquations,removedEquations,algorithmAndEquationAsserts,constraints,zeroCrossings,sampleConditions,sampleEquations,helpVarInfo,whenClauses,
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
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inSource, inFiles)
    local
      SimCode.Files files;
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
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inInfo, inFiles)
    local
      SimCode.Files files;
      String f;
      Boolean ro;
      SimCode.FileInfo fi;
      
    case (Absyn.INFO(fileName = f, isReadOnly = ro), files) 
      equation
        fi = SimCode.FILEINFO(f, ro);
        // add it only if is not already there!
        files = List.consOnTrue(not listMember(fi, files), fi, files);
      then 
        files;
  end match;
end getFilesFromAbsynInfo;

protected function equalFileInfo
"compare to SimCode.FileInfo and return true if the filenames are equal, isReadOnly is ignored here"
  input SimCode.FileInfo inFileInfo1;
  input SimCode.FileInfo inFileInfo2;
  output Boolean isMatch;
protected
  String f1, f2;
algorithm
  SimCode.FILEINFO(f1, _) := inFileInfo1;
  SimCode.FILEINFO(f2, _) := inFileInfo2;
  isMatch := stringEq(f1, f2);
end equalFileInfo;

protected function greaterFileInfo
"compare to SimCode.FileInfo and returns true if the fileName1 is greater than fileName2, isReadOnly is ignored here"
  input SimCode.FileInfo inFileInfo1;
  input SimCode.FileInfo inFileInfo2;
  output Boolean isGreater;
protected
  String f1, f2;
  Integer compare;
algorithm
  SimCode.FILEINFO(f1, _) := inFileInfo1;
  SimCode.FILEINFO(f2, _) := inFileInfo2;
  compare := stringCompare(f1, f2);
  isGreater := intGt(compare, 0);
end greaterFileInfo;

protected function getFileIndexFromFiles
"fetch the index in the list of files"
  input String file;
  input SimCode.Files files;
  output Integer index;
algorithm
  index := matchcontinue(file, files)
    local
      Integer i;
      
    case (file, files)
      equation
        i = List.positionOnTrue(SimCode.FILEINFO(file, false), files, equalFileInfo);
      then
        i; 
  end matchcontinue;
end getFileIndexFromFiles;

public function fileName2fileIndex
"Used by templates to find a fileIndex for given fileName"
  input String inFileName;
  input SimCode.Files inFiles;
  output Integer outFileIndex;
algorithm
  outFileIndex := matchcontinue(inFileName, inFiles)
    local
      String errstr;
      String file;
      SimCode.Files files;
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

protected function makeEqualLengthLists
  "Greedy algorithm for scheduling. Very simple:
  Calculate the weight of each eq.system, sort these s.t.
  the most expensive system is treated first. Add
  this eq.system to the block with the least cost at the moment.
  "
  input list<list<SimCode.SimEqSystem>> inLst;
  input Integer i;
  output list<list<SimCode.SimEqSystem>> olst;
algorithm
  olst := matchcontinue (inLst,i)
    local
      list<SimCode.SimEqSystem> l;
      PriorityQueue.T q;
      list<tuple<Integer,list<SimCode.SimEqSystem>>> prios;
      list<list<SimCode.SimEqSystem>> lst;

    case (lst,_)
      equation
        false = Flags.isSet(Flags.OPENMP) or Flags.isSet(Flags.PTHREADS);
        l = List.flatten(lst);
      then l::{};
    case (lst,0) then lst;
    case (lst,1)
      equation
        l = List.flatten(lst);
      then l::{};
    case (lst,_)
      equation
        q = List.fold(List.fill((0,{}),i),PriorityQueue.insert,PriorityQueue.empty);
        prios = List.map(lst,calcPriority);
        q = List.fold(prios,makeEqualLengthLists2,q);
        lst = List.map(PriorityQueue.elements(q),Util.tuple22);
      then lst;
  end matchcontinue;
end makeEqualLengthLists;

protected function makeEqualLengthLists2
  input tuple<Integer,list<SimCode.SimEqSystem>> elt;
  input PriorityQueue.T iq;
  output PriorityQueue.T oq;
algorithm
  oq := match (elt,iq)
    local
      list<SimCode.SimEqSystem> l1,l2;
      Integer i1,i2;
      PriorityQueue.T q;
      
    case ((i1,l1),q)
      equation
        // print("priorities before: " +& stringDelimitList(List.map(List.map(PriorityQueue.elements(q),Util.tuple21),intString),",") +& "\n");
        (q,(i2,l2)) = PriorityQueue.deleteAndReturnMin(q);
        // print("priorities (popped): " +& stringDelimitList(List.map(List.map(PriorityQueue.elements(q),Util.tuple21),intString),",") +& "\n");
        q = PriorityQueue.insert((i1+i2,listAppend(l2,l1)),q);
        // print("priorities after (i1=" +& intString(i1) +& "): " +& stringDelimitList(List.map(List.map(PriorityQueue.elements(q),Util.tuple21),intString),",") +& "\n");
      then q;
  end match;
end makeEqualLengthLists2;

protected function calcPriority
  input list<SimCode.SimEqSystem> eqs;
  output tuple<Integer,list<SimCode.SimEqSystem>> prio;
protected
  Integer i;
algorithm
  (_,i) := traverseExpsEqSystems(eqs, Expression.complexityTraverse, 1 /* Each system has cost 1 even if it's as simple as der(x)=1.0 */, {});
  prio := (i,eqs);
end calcPriority;

protected function traveseSimVars
  input SimCode.SimVars inSimVars;
  input Func func;
  input tpl iTpl;
  output SimCode.SimVars outSimVars;
  output tpl oTpl;
  replaceable type tpl subtypeof Any;
  partial function Func
    input tuple<SimCode.SimVar, tpl> tpl;
    output tuple<SimCode.SimVar, tpl> otpl;
  end Func;
algorithm
  (outSimVars, oTpl) := matchcontinue(inSimVars, func, iTpl)
    local 
     list<SimCode.SimVar> stateVars,derivativeVars,algVars,intAlgVars,boolAlgVars,inputVars,outputVars,aliasVars,intAliasVars,
                   boolAliasVars,paramVars,intParamVars,boolParamVars,stringAlgVars,stringParamVars,stringAliasVars,
                   extObjVars,constVars,intConstVars,boolConstVars,stringConstVars;
     tpl intpl;      
      
    case (SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars, 
                  paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars),_,intpl)
         equation
           (stateVars,intpl) = List.mapFoldTuple(stateVars, func, intpl);
           (derivativeVars,intpl) = List.mapFoldTuple(derivativeVars, func, intpl);
           (algVars,intpl) = List.mapFoldTuple(algVars, func, intpl);
           (intAlgVars,intpl) = List.mapFoldTuple(intAlgVars, func, intpl);
           (boolAlgVars,intpl) = List.mapFoldTuple(boolAlgVars, func, intpl);
           (outputVars,intpl) = List.mapFoldTuple(outputVars, func, intpl);
           (aliasVars,intpl) = List.mapFoldTuple(aliasVars, func, intpl);
           (intAliasVars,intpl) = List.mapFoldTuple(intAliasVars, func, intpl);
           (boolAliasVars,intpl) = List.mapFoldTuple(boolAliasVars, func, intpl);
           (paramVars,intpl) = List.mapFoldTuple(intParamVars, func, intpl);
           (intParamVars,intpl) = List.mapFoldTuple(paramVars, func, intpl);
           (boolParamVars,intpl) = List.mapFoldTuple(boolParamVars, func, intpl);
           (stringAlgVars,intpl) = List.mapFoldTuple(stateVars, func, intpl);
           (stateVars,intpl) = List.mapFoldTuple(stringAlgVars, func, intpl);
           (stringParamVars,intpl) = List.mapFoldTuple(stringParamVars, func, intpl);
           (stringAliasVars,intpl) = List.mapFoldTuple(stringAliasVars, func, intpl);
           (extObjVars,intpl) = List.mapFoldTuple(extObjVars, func, intpl);
           (intConstVars,intpl) = List.mapFoldTuple(intConstVars, func, intpl);
           (boolConstVars,intpl) = List.mapFoldTuple(boolConstVars, func, intpl);
           (stringConstVars,intpl) = List.mapFoldTuple(stringConstVars, func, intpl);
         then (SimCode.SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars, 
                  paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars,intConstVars,boolConstVars,stringConstVars),intpl);
    case (_,_,_) then fail();
  end matchcontinue;
end traveseSimVars;


protected function traverseExpsSimCode
  input SimCode.SimCode simCode;
  input Func func;
  input A ia;
  output SimCode.SimCode outSimCode;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input tuple<DAE.Exp,A> tpl;
    output tuple<DAE.Exp,A> otpl;
  end Func;
algorithm
  (outSimCode,oa) := match (simCode,func,ia)
    local
      SimCode.ModelInfo modelInfo;
      list<DAE.Exp> literals "shared literals";
      list<SimCode.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimCode.SimEqSystem> allEquations;
      list<list<SimCode.SimEqSystem>> odeEquations;
      list<SimCode.SimEqSystem> algebraicEquations;
      list<SimCode.SimEqSystem> residualEquations;
      list<SimCode.SimEqSystem> initialEquations;
      list<SimCode.SimEqSystem> startValueEquations;
      list<SimCode.SimEqSystem> parameterEquations;
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      list<DAE.Constraint> constraints;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<SimCode.SampleCondition> sampleConditions;
      list<SimCode.SimEqSystem> sampleEquations;
      list<SimCode.HelpVarInfo> helpVarInfo;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      //*** a protected section *** not exported to SimCodeTV
      SimCode.HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      A a;

    case (SimCode.SIMCODE(modelInfo, literals, recordDecls, externalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, initialEquations, startValueEquations, parameterEquations, removedEquations, algorithmAndEquationAsserts, constraints, zeroCrossings, sampleConditions, sampleEquations, helpVarInfo, whenClauses, discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT),_,a)
      equation
        (literals,a) = List.mapFoldTuple(literals,func,a);
        (allEquations,a) = traverseExpsEqSystems(allEquations,func,a,{});
        (odeEquations,a) = traverseExpsEqSystemsList(odeEquations,func,a,{});
        (algebraicEquations,a) = traverseExpsEqSystems(algebraicEquations,func,a,{});
        (residualEquations,a) = traverseExpsEqSystems(residualEquations,func,a,{});
        (initialEquations,a) = traverseExpsEqSystems(initialEquations,func,a,{});
        (startValueEquations,a) = traverseExpsEqSystems(startValueEquations,func,a,{});
        (parameterEquations,a) = traverseExpsEqSystems(parameterEquations,func,a,{});
        (removedEquations,a) = traverseExpsEqSystems(removedEquations,func,a,{});
        (algorithmAndEquationAsserts,a) = traverseExpsEqSystems(algorithmAndEquationAsserts,func,a,{});
        /* TODO:zeroCrossing */
        /* TODO:sampleConditions */
        (sampleEquations,a) = traverseExpsEqSystems(sampleEquations,func,a,{});
        /* TODO:whenClauses */
        /* TODO:discreteModelVars */
        /* TODO:extObjInfo */
        /* TODO:delayedExps */
        /* TODO:jacobianMatrixes */
      then (SimCode.SIMCODE(modelInfo, literals, recordDecls, externalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, initialEquations, startValueEquations, parameterEquations, removedEquations, algorithmAndEquationAsserts, constraints, zeroCrossings, sampleConditions, sampleEquations, helpVarInfo, whenClauses, discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT),a);
  end match;
end traverseExpsSimCode;

protected function traverseExpsEqSystemsList
  input list<list<SimCode.SimEqSystem>> ieqs;
  input Func func;
  input A ia;
  input list<list<SimCode.SimEqSystem>> acc;
  output list<list<SimCode.SimEqSystem>> oeqs;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input tuple<DAE.Exp,A> tpl;
    output tuple<DAE.Exp,A> otpl;
  end Func;
algorithm
  (oeqs,oa) := match (ieqs,func,ia,acc)
    local
      list<SimCode.SimEqSystem> eq;
      A a;
      list<list<SimCode.SimEqSystem>> eqs;
    
    case ({},_,a,_) then (listReverse(acc),a);
    case (eq::eqs,_,a,_)
      equation
        (eq,a) = traverseExpsEqSystems(eq,func,a,{});
        (oeqs,a) = traverseExpsEqSystemsList(eqs,func,a,eq::acc);
      then (oeqs,a);
  end match;
end traverseExpsEqSystemsList;

protected function traverseExpsEqSystems
  input list<SimCode.SimEqSystem> ieqs;
  input Func func;
  input A ia;
  input list<SimCode.SimEqSystem> acc;
  output list<SimCode.SimEqSystem> oeqs;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input tuple<DAE.Exp,A> tpl;
    output tuple<DAE.Exp,A> otpl;
  end Func;
algorithm
  (oeqs,oa) := match (ieqs,func,ia,acc)
    local
      SimCode.SimEqSystem eq;
      A a;
      list<SimCode.SimEqSystem> eqs;
    
    case ({},_,a,_) then (listReverse(acc),a);
    case (eq::eqs,_,a,_)
      equation
        (eq,a) = traverseExpsEqSystem(eq,func,a);
        (oeqs,a) = traverseExpsEqSystems(eqs,func,a,eq::acc);
      then (oeqs,a);
  end match;
end traverseExpsEqSystems;

protected function traverseExpsEqSystem
  input SimCode.SimEqSystem eq;
  input Func func;
  input A ia;
  output SimCode.SimEqSystem oeq;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input tuple<DAE.Exp,A> tpl;
    output tuple<DAE.Exp,A> otpl;
  end Func;
algorithm
  (oeq,oa) := match (eq,func,ia)
    local
      DAE.Exp exp,right;
      DAE.ComponentRef cr,left;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      list<DAE.Statement> stmts;
      SimCode.SimEqSystem cont;
      list<SimCode.SimEqSystem> discEqs,eqs;
      Integer index,indexNonLinear;
      Boolean partOfMixed;
      list<SimCode.SimVar> vars,discVars;
      list<DAE.Exp> beqs;
      list<DAE.ComponentRef> crefs;
      list<Integer> values,values_dims;
      list<tuple<DAE.Exp, Integer>> conditions;
      Option<SimCode.SimEqSystem> elseWhen;
      DAE.ElementSource source;
      A a;
    case (SimCode.SES_RESIDUAL(index,exp,source),_,a)
      equation
        ((exp,a)) = func((exp,a));
      then (SimCode.SES_RESIDUAL(index,exp,source),a);
    case (SimCode.SES_SIMPLE_ASSIGN(index,cr,exp,source),_,a)
      equation
        ((exp,a)) = func((exp,a));
      then (SimCode.SES_SIMPLE_ASSIGN(index,cr,exp,source),a);
    case (SimCode.SES_ARRAY_CALL_ASSIGN(index,cr,exp,source),_,a)
      equation
        ((exp,a)) = func((exp,a));
      then (SimCode.SES_ARRAY_CALL_ASSIGN(index,cr,exp,source),a);
    case (SimCode.SES_ALGORITHM(index,stmts),_,a)
      equation
        /* TODO: Me */
      then (SimCode.SES_ALGORITHM(index,stmts),a);
    case (SimCode.SES_LINEAR(index,partOfMixed,vars,beqs,simJac),_,a)
      equation
        /* TODO: Me */
      then (SimCode.SES_LINEAR(index,partOfMixed,vars,beqs,simJac),a);
    case (SimCode.SES_NONLINEAR(index,eqs,crefs,indexNonLinear),_,a)
      equation
        /* TODO: Me */
      then (SimCode.SES_NONLINEAR(index,eqs,crefs,indexNonLinear),a);
    case (SimCode.SES_MIXED(index,cont,discVars,discEqs),_,a)
      equation
        /* TODO: Me */
      then (SimCode.SES_MIXED(index,cont,discVars,discEqs),a);
    case (SimCode.SES_WHEN(index,left,right,conditions,elseWhen,source),_,a)
        /* TODO: Me */
      then (SimCode.SES_WHEN(index,left,right,conditions,elseWhen,source),a);
  end match;
end traverseExpsEqSystem;

protected function setSimCodeLiterals
  input SimCode.SimCode simCode;
  input list<DAE.Exp> literals;
  output SimCode.SimCode outSimCode;
algorithm
  outSimCode := match (simCode,literals)
    local
      SimCode.ModelInfo modelInfo;
      list<SimCode.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimCode.SimEqSystem> allEquations;
      list<list<SimCode.SimEqSystem>> odeEquations;
      list<SimCode.SimEqSystem> algebraicEquations;
      list<SimCode.SimEqSystem> residualEquations;
      list<SimCode.SimEqSystem> initialEquations;
      list<SimCode.SimEqSystem> startValueEquations;
      list<SimCode.SimEqSystem> parameterEquations;
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      list<DAE.Constraint> constraints;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<SimCode.SampleCondition> sampleConditions;
      list<SimCode.SimEqSystem> sampleEquations;
      list<SimCode.HelpVarInfo> helpVarInfo;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      //*** a protected section *** not exported to SimCodeTV
      SimCode.HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";

    case (SimCode.SIMCODE(modelInfo, _, recordDecls, externalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, initialEquations, startValueEquations, parameterEquations, removedEquations, algorithmAndEquationAsserts, constraints, zeroCrossings, sampleConditions, sampleEquations, helpVarInfo, whenClauses, discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT),_)
      then SimCode.SIMCODE(modelInfo, literals, recordDecls, externalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, initialEquations, startValueEquations, parameterEquations, removedEquations, algorithmAndEquationAsserts, constraints, zeroCrossings, sampleConditions, sampleEquations, helpVarInfo, whenClauses, discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT);
  end match;
end setSimCodeLiterals;

protected function eqSystemWCET
  "Calculate the estimated worst-case execution time of the system for partitioning"
  input SimCode.SimEqSystem eqs;
  output tuple<SimCode.SimEqSystem,Integer> tpl;
protected
  Integer i;
algorithm
  (_,i) := traverseExpsEqSystems({eqs}, Expression.complexityTraverse, 0, {});
  tpl := (eqs,i);
end eqSystemWCET;

end SimCodeUtil;
