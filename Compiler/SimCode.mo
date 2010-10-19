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


package SimCode
" file:	       SimCode.mo
  package:     SimCode
  description: Code generation using Susan templates

  RCS: $Id: SimCode.mo 3689 2009-02-26 07:38:30Z adrpo $

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


public import Exp;
public import Algorithm;
public import Values;
public import Types;
public import DAELow;
public import Env;
public import Dependency;
public import Interactive;
public import Absyn;
public import Ceval;
public import Tpl;
public import SCode;
public import DAE;
public import Inline;

protected import DAEUtil;
protected import SCodeUtil;
protected import ClassInf;
protected import SimCodeC;
protected import SimCodeCSharp;
protected import SimCodeFMU;
protected import Util;
protected import Debug;
protected import Error;
protected import Inst;
protected import InnerOuter;
protected import Settings;
protected import RTOpts;
protected import System;
protected import VarTransform;
protected import BackendVarTransform;
protected import CevalScript;
protected import ModUtil;
protected import DAEDump;
protected import PartFn;
protected import ValuesUtil;

public
type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
type ExtDestructor = tuple<String, DAE.ComponentRef>;
type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;
type HelpVarInfo = tuple<Integer, Exp.Exp, Integer>; // helpvarindex, expression, whenclause index
type JacobianMatrix = tuple<list<SimEqSystem>, list<SimVar>, String>;


// Root data structure containing information required for templates to
// generate simulation code for a Modelica model.
uniontype SimCode
  record SIMCODE
    ModelInfo modelInfo;
    list<Function> functions;
    list<String> externalFunctionIncludes;
    list<SimEqSystem> allEquations;
    list<SimEqSystem> allEquationsPlusWhen;
    list<SimEqSystem> stateContEquations;
    list<SimEqSystem> nonStateContEquations;
    list<SimEqSystem> nonStateDiscEquations;
    list<SimEqSystem> residualEquations;
    list<SimEqSystem> initialEquations;
    list<SimEqSystem> parameterEquations;
    list<SimEqSystem> removedEquations;
    list<DAE.Statement> algorithmAndEquationAsserts;
    list<DAELow.ZeroCrossing> zeroCrossings;
    list<list<SimVar>> zeroCrossingsNeedSave;
    list<HelpVarInfo> helpVarInfo;
    list<SimWhenClause> whenClauses;
    list<DAE.ComponentRef> discreteModelVars;
    ExtObjInfo extObjInfo;
    MakefileParams makefileParams;
    DelayedExpression delayedExps;
    list<JacobianMatrix> JacobianMatrixes;
    Option<SimulationSettings> simulationSettingsOpt;
    String fileNamePrefix;
    
    //*** a protected section *** not exported to SimCodeTV
    DAELow.DAELow daeLow "hidden from typeview - exprerimental; used by cref2simvar() for cref -> SIMVAR mapping available in templates";
  
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
    Function mainFunction "This function is special; the 'in'-function should be generated for it";
    list<Function> functions;
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
  end MODELINFO;
end ModelInfo;

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
    Integer numParams;
    Integer numIntParams;
    Integer numBoolParams;
    Integer numOutVars;
    Integer numInVars;
    Integer numResiduals;
    Integer numExternalObjects;
    Integer numStringAlgVars;
    Integer numStringParamVars;
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
    list<SimVar> paramVars;
    list<SimVar> intParamVars;
    list<SimVar> boolParamVars;
    list<SimVar> stringAlgVars;
    list<SimVar> stringParamVars;
    list<SimVar> extObjVars;
  end SIMVARS;
end SimVars;

// Information about a variable in a Modelica model.
uniontype SimVar
  record SIMVAR
    DAE.ComponentRef name;
    DAELow.VarKind varKind;
    String comment;
    String unit;
    String displayUnit;
    Integer index;
    Option<DAE.Exp> initialValue;
    Boolean isFixed;
    Exp.Type type_;
    Boolean isDiscrete;
    // arrayCref is the name of the array if this variable is the first in that
    // array
    Option<DAE.ComponentRef> arrayCref;
  end SIMVAR;
end SimVar;

// Represents a Modelica or MetaModelica function.
// TODO: I believe some of these fields can be removed. Check to see what is
//       used in templates.
uniontype Function
  record FUNCTION
    Absyn.Path name;
    list<Variable> inVars;
    list<Variable> outVars;
    list<RecordDeclaration> recordDecls;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<Statement> body;
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
    String language "C or Fortran";
    list<RecordDeclaration> recordDecls;
  end EXTERNAL_FUNCTION;
  record RECORD_CONSTRUCTOR
    Absyn.Path name;
    list<Variable> funArgs;
    list<RecordDeclaration> recordDecls;
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
    Exp.Type ty;
    Option<Exp.Exp> value; // Default value
    list<DAE.Exp> instDims;
  end VARIABLE;

  record FUNCTION_PTR
    String name;
    Exp.Type ty;
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
  end SES_RESIDUAL;
  record SES_SIMPLE_ASSIGN
    DAE.ComponentRef cref;
    DAE.Exp exp;
  end SES_SIMPLE_ASSIGN;
  record SES_ARRAY_CALL_ASSIGN
    DAE.ComponentRef componentRef;
    DAE.Exp exp;
  end SES_ARRAY_CALL_ASSIGN;
  record SES_ALGORITHM
    list<DAE.Statement> statements;
  end SES_ALGORITHM;
  record SES_LINEAR
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
    SimEqSystem cont;
    list<SimVar> discVars;
    list<SimEqSystem> discEqs;
    list<String> values;
    list<Integer> value_dims;
  end SES_MIXED;
  record SES_WHEN
    DAE.ComponentRef left;
    DAE.Exp right;
    list<tuple<DAE.Exp, Integer>> conditions; // condition, help var index
  end SES_WHEN;
end SimEqSystem;

uniontype SimWhenClause
  record SIM_WHEN_CLAUSE
    list<DAE.ComponentRef> conditionVars;
    list<DAELow.ReinitStatement> reinits;
    Option<DAELow.WhenEquation> whenEq;
    list<tuple<DAE.Exp, Integer>> conditions; // condition, help var index
  end SIM_WHEN_CLAUSE;
end SimWhenClause;

uniontype ExtObjInfo
  record EXTOBJINFO
    list<String> includes;
    list<ExtConstructor> constructors;
    list<ExtDestructor> destructors;
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
    list<String> libs;
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


public function valueblockVars
"Used by templates to get a list of variables from a valueblock."
  input DAE.Exp valueblock;
  output list<Variable> vars;
algorithm
  vars :=
  matchcontinue (valueblock)
    local
      list<DAE.Element> ld;
    case (DAE.VALUEBLOCK(localDecls=ld))
      equation
        ld = Util.listFilter(ld, isVarQ);
        vars = Util.listMap(ld, daeInOutSimVar);
      then vars;
  end matchcontinue;
end valueblockVars;

public function crefSubIsScalar
"Used by templates to determine if a component reference's subscripts are
 scalar."
  input DAE.ComponentRef cref;
  output Boolean isScalar;
  list<DAE.Subscript> subs;
algorithm
  subs := crefSubs(cref);
  isScalar := subsToScalar(subs);
end crefSubIsScalar;

public function crefNoSub
"Used by templates to determine if a component reference has no subscripts."
  input DAE.ComponentRef cref;
  output Boolean noSub;
  list<DAE.Subscript> subs;
  Integer len;
algorithm
	subs := crefSubs(cref);
	noSub := Util.isListEmpty(subs);
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
				res = Exp.crefHasScalarSubscripts(cref);
			then
				res;
	end matchcontinue;
end crefIsScalar;
         
function crefSubs
"Used by templates to get the subscript list from a component reference."
  input DAE.ComponentRef cref;
  output list<DAE.Subscript> subs;
algorithm
  subs :=
  matchcontinue (cref)
    local
      list<DAE.Subscript> subs1;
      list<DAE.Subscript> subs2;
      DAE.ComponentRef cref1;
    case (DAE.CREF_IDENT(subscriptLst=subs1))
      then subs1;
    case (DAE.CREF_QUAL(subscriptLst=subs1, componentRef=cref1))
      equation
        subs2 = crefSubs(cref1);
        subs = Util.listFlatten({subs1, subs2}); // ??? is this the same as listAppend(subs1, subs2);
      then subs;
  end matchcontinue;
end crefSubs;

public function buildCrefExpFromAsub
"Used by templates to convert an ASUB expression to a component reference
 with subscripts."
  input DAE.Exp cref;
  input list<DAE.Exp> subs;
  output DAE.Exp cRefOut;
algorithm
  cRefOut := matchcontinue(cref, subs)
    local
      DAE.Exp sub;
      DAE.ExpType ty;
      list<DAE.Exp> rest;
      DAE.ComponentRef crNew;
      list<DAE.Subscript> indexes;
    case (cref, {}) then cref;
    case (DAE.CREF(componentRef=crNew, ty=ty), subs)
      equation
        indexes = Util.listMap(subs, Exp.makeIndexSubscript);
        crNew = Exp.subscriptCref(crNew, indexes);
      then
        DAE.CREF(crNew, ty);
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
  outExp := matchcontinue (inCRefRecord,inVar)
    local
      DAE.ComponentRef cr,cr1;
      String name;
      DAE.ExpType tp;      
    case (cr,DAE.COMPLEX_VAR(name=name,tp=tp))
      equation
        cr1 = Exp.extendCref(cr,tp,name,{});
        outExp = Exp.makeCrefExp(cr1,tp);
      then
        outExp;
  end matchcontinue;  
end makeCrefRecordExp;

public function cref2simvar
"Used by templates to find SIMVAR for given cref (to gain representaion index info mainly)."
  input DAE.ComponentRef inCref;
  input SimCode simCode;
  output SimVar outSimVar;
algorithm
  outSimVar := matchcontinue(inCref, simCode)
    local
      DAELow.Variables vars;
      DAELow.Var daelowvar;
      DAE.ComponentRef cref, badcref;
      SimVar sv;
    
    case (cref, SIMCODE(daeLow = DAELow.DAELOW(orderedVars = vars))) 
      equation
        ((daelowvar :: _), _) = DAELow.getVar(cref, vars);        
      then dlowvarToSimvar(daelowvar);
    
    case (cref, SIMCODE(daeLow = DAELow.DAELOW(knownVars = vars))) 
      equation
        ((daelowvar :: _), _) = DAELow.getVar(cref, vars);        
      then dlowvarToSimvar(daelowvar);
    
    case (DAE.CREF_QUAL(ident = "$DER", componentRef = cref), SIMCODE(daeLow = DAELow.DAELOW(orderedVars = vars))) 
      equation
        ((daelowvar :: _), _) = DAELow.getVar(cref, vars);
        DAELow.VAR(varKind = DAELow.STATE()) = daelowvar;
        sv = dlowvarToSimvar(daelowvar);
      then derVarFromStateVar(sv);
    
    case (cref, _)
      equation
        badcref = DAE.CREF_IDENT("ERROR_cref2simvar_failed", DAE.ET_REAL, {});
      then
        SIMVAR(badcref, DAELow.STATE(), "", "", "", -1, NONE(), false, DAE.ET_REAL, false,NONE);
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
  derCref := DAELow.crefPrefixDer(inCref);
end derComponentRef;


/** end of TypeView published functions **/


public function createSimulationSettings
  input Real startTime;
  input Real stopTime;
  input Integer numberOfIntervals;
  input Real tolerance;
  input String method;
  input String options;
  input String outputFormat; 
  
  output SimulationSettings simSettings;  
protected
  Real stepSize;
algorithm
  numberOfIntervals := Util.if_(numberOfIntervals <= 0, 1, numberOfIntervals);
  stepSize := (stopTime -. startTime) /. intReal(numberOfIntervals);
  simSettings := SIMULATION_SETTINGS(
     startTime, stopTime, numberOfIntervals, stepSize, tolerance,
     method, options, outputFormat);
end createSimulationSettings;


public function generateModelCodeFMU
  "Generates code for a model by creating a SimCode structure and calling the
   template-based code generator on it."
  input SCode.Program program;
  input DAE.DAElist dae;
  input DAELow.DAELow indexedDAELow;
  input DAE.FunctionTree functionTree;
  input Absyn.Path className;
  input String filenamePrefix;
  input String fileDir;
  input Integer[:] equationIndices;
  input Integer[:] variableIndices;
  input DAELow.IncidenceMatrix incidenceMatrix;
  input DAELow.IncidenceMatrix incidenceMatrixT;
  input list<list<Integer>> strongComponents;
  input Option<SimulationSettings> simSettingsOpt;
  output DAELow.DAELow outIndexedDAELow;
  output list<String> libs;
  output Real timeSimCode;
  output Real timeTemplates;
  
  list<String> includes;
  list<Function> functions;
  DAE.DAElist dae2;
  String filename, funcfilename;
  SimCode simCode;
  Real timeSimCode, timeTemplates;
algorithm
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
  (libs, includes, functions, outIndexedDAELow, dae2) :=
    createFunctions(program, dae, indexedDAELow, functionTree, className);
  simCode := createSimCode(functionTree, outIndexedDAELow, equationIndices, 
    variableIndices, incidenceMatrix, incidenceMatrixT, strongComponents, 
    className, filenamePrefix, fileDir, functions, includes, libs, simSettingsOpt); 
  timeSimCode := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
  
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);   
  Tpl.tplNoret(SimCodeC.translateModel, simCode);  
  Tpl.tplNoret(SimCodeFMU.translateModel, simCode);
  timeTemplates := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);   
end generateModelCodeFMU;

public function translateModelFMU
"Entry point to translate a Modelica model for FMU export.
    
 Called from other places in the compiler."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output DAELow.DAELow outDAELow;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outDAELow,outStringLst,outFileDir,resultValues):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy, inSimSettingsOpt)
    local
      String filenameprefix,file_dir;
      list<SCode.Class> p_1;
      DAE.DAElist dae;
      list<Env.Frame> env;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      Ceval.Msg msg;
      //Exp.Exp fileprefix;
      Env.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p)),filenameprefix,addDummy, inSimSettingsOpt)
      equation
        /* calculate stuff that we need to create SimCode data structure */
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st), NONE, msg);
        ptot = Dependency.getTotalProgram(className,p);
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        funcs = Env.getFunctionTree(cache);
        dae = DAEUtil.transformationsBeforeBackend(dae);
        dlow = DAELow.lower(dae, funcs, addDummy, true);
        Debug.fprint("bltdump", "Lowered DAE:\n");
        Debug.fcall("bltdump", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        (ass1,ass2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, (DAELow.INDEX_REDUCTION(),DAELow.EXACT(),DAELow.REMOVE_SIMPLE_EQN()),funcs);
        // late Inline
        dlow_1 = Inline.inlineCalls(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()},dlow_1);
        (comps) = DAELow.strongComponents(m, mT, ass1, ass2);
        indexed_dlow = DAELow.translateDae(dlow_1,NONE);
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        Debug.fprint("bltdump", "indexed DAE:\n");
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("bltdump", DAELow.dump, indexed_dlow_1);
        Debug.fcall("bltdump", DAELow.dumpMatching, ass1);
        Debug.fcall("bltdump", DAELow.dumpComponents, comps);
        Debug.fprintln("dynload", "translateModel: Generating simulation code and functions.");
        a_cref = Absyn.pathToCref(className);
        file_dir = CevalScript.getFileDir(a_cref, p);
        timeBackend = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        (indexed_dlow_1, libs, timeSimCode, timeTemplates) 
         = generateModelCodeFMU(p_1, dae, indexed_dlow_1, funcs, className, filenameprefix,
          file_dir, ass1, ass2, m, mT, comps,inSimSettingsOpt);
        resultValues = 
          {("timeTemplates",Values.REAL(timeTemplates)),
           ("timeSimCode",  Values.REAL(timeSimCode)),
           ("timeBackend",  Values.REAL(timeBackend)),
           ("timeFrontend", Values.REAL(timeFrontend))
           };   
      then
        (cache,Values.STRING("SimCode: The model has been translated to FMU"),st,indexed_dlow,libs,file_dir, resultValues);
  end matchcontinue;
end translateModelFMU;

public function generateModelCode
  "Generates code for a model by creating a SimCode structure and calling the
   template-based code generator on it."
  input SCode.Program program;
  input DAE.DAElist dae;
  input DAELow.DAELow indexedDAELow;
  input DAE.FunctionTree functionTree;
  input Absyn.Path className;
  input String filenamePrefix;
  input String fileDir;
  input Integer[:] equationIndices;
  input Integer[:] variableIndices;
  input DAELow.IncidenceMatrix incidenceMatrix;
  input DAELow.IncidenceMatrix incidenceMatrixT;
  input list<list<Integer>> strongComponents;
  input Option<SimulationSettings> simSettingsOpt;
  output DAELow.DAELow outIndexedDAELow;
  output list<String> libs;
  output Real timeSimCode;
  output Real timeTemplates;
  
  list<String> includes;
  list<Function> functions;
  DAE.DAElist dae2;
  String filename, funcfilename;
  SimCode simCode;
  Real timeSimCode, timeTemplates;
algorithm
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
  (libs, includes, functions, outIndexedDAELow, dae2) :=
    createFunctions(program, dae, indexedDAELow, functionTree, className);
  simCode := createSimCode(functionTree, outIndexedDAELow, equationIndices, 
    variableIndices, incidenceMatrix, incidenceMatrixT, strongComponents, 
    className, filenamePrefix, fileDir, functions, includes, libs, simSettingsOpt); 
  timeSimCode := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
  
  System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);     
  callTargetTemplates(simCode);
  timeTemplates := System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);   
end generateModelCode;

public function translateModel
"Entry point to translate a Modelica model for simulation.
    
 Called from other places in the compiler."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input String inFileNamePrefix;
  input Boolean addDummy "if true, add a dummy state";
  input Option<SimulationSettings> inSimSettingsOpt;
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output DAELow.DAELow outDAELow;
  output list<String> outStringLst;
  output String outFileDir;
  output list<tuple<String,Values.Value>> resultValues;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outDAELow,outStringLst,outFileDir,resultValues):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inFileNamePrefix,addDummy, inSimSettingsOpt)
    local
      String filenameprefix,file_dir;
      list<SCode.Class> p_1;
      DAE.DAElist dae;
      list<Env.Frame> env;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      Ceval.Msg msg;
      //Exp.Exp fileprefix;
      Env.Cache cache;
      DAE.FunctionTree funcs;
      Real timeSimCode, timeTemplates, timeBackend, timeFrontend;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p)),filenameprefix,addDummy, inSimSettingsOpt)
      equation
        /* calculate stuff that we need to create SimCode data structure */
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        //(cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st), NONE, msg);
        ptot = Dependency.getTotalProgram(className,p);
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        timeFrontend = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        System.realtimeTick(CevalScript.RT_CLOCK_BUILD_MODEL);
        dae = DAEUtil.transformationsBeforeBackend(dae);
        funcs = Env.getFunctionTree(cache);
        dlow = DAELow.lower(dae, funcs, addDummy, true);
        Debug.fprint("bltdump", "Lowered DAE:\n");
        Debug.fcall("bltdump", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        (ass1,ass2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, (DAELow.INDEX_REDUCTION(),DAELow.EXACT(),DAELow.REMOVE_SIMPLE_EQN()),funcs);
        // late Inline
        dlow_1 = Inline.inlineCalls(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()},dlow_1);
        (comps) = DAELow.strongComponents(m, mT, ass1, ass2);
        indexed_dlow = DAELow.translateDae(dlow_1,NONE);
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        Debug.fprint("bltdump", "indexed DAE:\n");
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("bltdump", DAELow.dump, indexed_dlow_1);
        Debug.fcall("bltdump", DAELow.dumpMatching, ass1);
        Debug.fcall("bltdump", DAELow.dumpComponents, comps);
        Debug.fprintln("dynload", "translateModel: Generating simulation code and functions.");
        a_cref = Absyn.pathToCref(className);
        file_dir = CevalScript.getFileDir(a_cref, p);
        timeBackend = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        (indexed_dlow_1, libs, timeSimCode, timeTemplates) 
         = generateModelCode(p_1, dae, indexed_dlow_1, funcs, className, filenameprefix,
          file_dir, ass1, ass2, m, mT, comps,inSimSettingsOpt);
        resultValues = 
          {("timeTemplates",Values.REAL(timeTemplates)),
           ("timeSimCode",  Values.REAL(timeSimCode)),
           ("timeBackend",  Values.REAL(timeBackend)),
           ("timeFrontend", Values.REAL(timeFrontend))
           };   
      then
        (cache,Values.STRING("SimCode: The model has been translated"),st,indexed_dlow_1,libs,file_dir, resultValues);
  end matchcontinue;
end translateModel;

public function translateFunctions
"Entry point to translate Modelica/MetaModelica functions to C functions.
    
 Called from other places in the compiler."
  input String name;
  input DAE.Function daeMainFunction;
  input list<DAE.Function> daeElements;
  input list<DAE.Type> metarecordTypes;
algorithm
  _ :=
  matchcontinue (name, daeMainFunction, daeElements, metarecordTypes)
    local
      Function mainFunction;
      list<Function> fns;
      list<String> libs, includes;
      MakefileParams makefileParams;
      FunctionCode fnCode;
      list<RecordDeclaration> extraRecordDecls;
    case (name, daeMainFunction, daeElements, metarecordTypes)
      equation
        // Create FunctionCode
        /* TODO: Check if this is actually 100% certain to be the function given by name? */ 
        (mainFunction::fns, extraRecordDecls, includes, libs) = elaborateFunctions(daeMainFunction::daeElements, metarecordTypes);
        checkValidMainFunction(name, mainFunction);
        makefileParams = createMakefileParams(libs);
        fnCode = FUNCTIONCODE(name, mainFunction, fns, includes, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(SimCodeC.translateFunctions, fnCode);
      then
        ();
  end matchcontinue;
end translateFunctions;

protected function checkValidMainFunction
"Verifies that an in-function can be generated.
This is not the case if the input involves function-pointers."
  input String name;
  input Function fn;
algorithm
  _ := matchcontinue (name,fn)
    local
      list<Variable> inVars;
    case (_,FUNCTION(inVars = inVars))
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

protected function isFunctionPtr
"Checks if an input variable is a function pointer"
  input Variable var;
  output Boolean b;
algorithm
  b := matchcontinue var
    local
      String name;
    /* Yes, they are VARIABLE, not FUNCTION_PTR. */
    case FUNCTION_PTR(ty = _)
      then true;
    case _ then false;
  end matchcontinue;
end isFunctionPtr;

/* Finds the called functions in DAELow and transforms them to a list of
   libraries and a list of Function uniontypes. */
public function createFunctions
  input SCode.Program inProgram;
  input DAE.DAElist inDAElist;
  input DAELow.DAELow inDAELow;
  input DAE.FunctionTree functionTree;
  input Absyn.Path inPath;
  output list<String> libs;
  output list<String> includes;
  output list<Function> functions;
  output DAELow.DAELow outDAELow;
  output DAE.DAElist outDAE;
algorithm
  (libs, includes, functions, outDAELow, outDAE) :=
  matchcontinue (inProgram,inDAElist,inDAELow,functionTree,inPath)
    local
      list<Absyn.Path> funcPaths, funcRefPaths, funcNormalPaths;
      list<String> debugpathstrs,libs1,libs2,includes1,includes2;
      String debugpathstr,debugstr,filenameprefix, str;
      list<DAE.Function> funcelems,part_func_elems, funcRefElems, funcNormal;
      list<SCode.Class> p;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Absyn.Path path;
      list<Function> fns;
      SimCode sc;
      DAE.FunctionTree funcs;
      
    case (p,dae,dlow,functionTree,path)
      equation
        // get all the used functions from the function tree
        funcelems = DAEUtil.getFunctionList(functionTree);
        
        part_func_elems = PartFn.createPartEvalFunctions(funcelems);
        (dae, part_func_elems) = PartFn.partEvalDAE(dae, part_func_elems);
        (part_func_elems, dlow) = PartFn.partEvalDAELow(part_func_elems, dlow);
        funcelems = Util.listUnion(part_func_elems, part_func_elems);
        //funcelems = Util.listUnion(funcelems, part_func_elems);
        funcelems = Inline.inlineCallsInFunctions(funcelems,(NONE(),{DAE.NORM_INLINE(), DAE.AFTER_INDEX_RED_INLINE()}));
        //Debug.fprintln("info", "Generating functions, call Codegen.\n") "debug" ;
        (includes1, libs1) = generateExternalObjectIncludes(dlow);
        (fns, _, includes2, libs2) = elaborateFunctions(funcelems, {}); // Do we need metarecords here as well?
      then
        (Util.listUnion(libs1,libs2), Util.listUnion(includes1,includes2), fns, dlow, dae);
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Creation of Modelica functions failed. "});
      then
        fail();
  end matchcontinue;
end createFunctions;

public function getCalledFunctions
"Goes through the DAELow structure, finds all function calls, and returns them
in a list. Removes duplicates."
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  output list<Absyn.Path> res;
  list<Exp.Exp> explist,fcallexps,fcallexps_1,fcallexps_2;
  list<Absyn.Path> calledfuncs;
algorithm
  explist := DAELow.getAllExps(dlow);
  fcallexps := getMatchingExpsList(explist, matchCalls);
  fcallexps_1 := Util.listSelect(fcallexps, isNotBuiltinCall);
  fcallexps_2 := getMatchingExpsList(explist, matchFnRefs);
  calledfuncs := Util.listMap(listAppend(fcallexps_1,fcallexps_2), getCallPath);
  res := removeDuplicatePaths(calledfuncs);
end getCalledFunctions;

public function getCalledFunctionReferences
"Goes through the DAELow structure, finds all function references calls, 
 and returns them in a list. Removes duplicates."
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  output list<Absyn.Path> res;
  list<Exp.Exp> explist,fcallexps;
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
        explist = DAELow.getAllExps(dlow);
        fcallexps = getMatchingExpsList(explist, matchFnRefs);
        calledfuncs = Util.listMap(fcallexps, getCallPath);
        res = removeDuplicatePaths(calledfuncs);
      then res;
  end matchcontinue;     
end getCalledFunctionReferences;

protected function generateExternalObjectIncludes
"Generates the library paths for external objects"
  input DAELow.DAELow daelow;
  output list<String> includes;
  output list<String> libs;
algorithm
  (includes,libs) :=
  matchcontinue (daelow)
    local
      list<list<String>> libsL,includesL;
      DAELow.ExternalObjectClasses extObjs;
    case DAELow.DAELOW(extObjClasses = extObjs)
      equation
        (includesL, libsL) = Util.listMap_2(extObjs, generateExternalObjectInclude);
        includes = Util.listListUnion(includesL);
        libs = Util.listListUnion(libsL);
      then (includes,libs);
  end matchcontinue;
end generateExternalObjectIncludes;

protected function generateExternalObjectInclude
"Helper function to generateExteralObjectInclude"
  input DAELow.ExternalObjectClass extObjCls;
  output list<String> includes;
  output list<String> libs;
algorithm
  (includes,libs) :=
  matchcontinue(extObjCls)
    local
      Option<Absyn.Annotation> ann1,ann2;
      list<String> includes1,libs1,includes2,libs2;
    case (DAELow.EXTOBJCLASS(constructor=DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl=DAE.EXTERNALDECL(language=ann1))}),
      											destructor=DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl=DAE.EXTERNALDECL(language=ann2))})))
      equation
        (includes1,libs1) = generateExtFunctionIncludes(ann1);
        (includes2,libs2) = generateExtFunctionIncludes(ann2);
        includes = Util.listListUnion({includes1, includes2});
        libs = Util.listListUnion({libs1, libs2});
      then (includes,libs);
  end matchcontinue;
end generateExternalObjectInclude;

protected function elaborateFunctions
  input list<DAE.Function> daeElements;
  input list<DAE.Type> metarecordTypes;
  output list<Function> functions;
  output list<RecordDeclaration> extraRecordDecls;
  output list<String> includes;
  output list<String> libs;
protected
  list<Function> fns;
  list<String> outRecordTypes;
algorithm
  (functions, outRecordTypes, includes, libs) := elaborateFunctions2(daeElements,{},{},{},{});
  (extraRecordDecls,_) := elaborateRecordDeclarationsFromTypes(metarecordTypes, {}, outRecordTypes);
end elaborateFunctions;

protected function elaborateFunctions2
  input list<DAE.Function> daeElements;
  input list<Function> inFunctions;
  input list<String> inRecordTypes;
  input list<String> inIncludes;
  input list<String> inLibs;
  output list<Function> outFunctions;
  output list<String> outRecordTypes;
  output list<String> outIncludes;
  output list<String> outLibs;
algorithm
  (outFunctions, outRecordTypes, outIncludes, outLibs) :=
  matchcontinue (daeElements, inFunctions, inRecordTypes, inIncludes, inLibs)
    local
      list<Function> accfns, fns;
      Function fn;
      list<String> rt, rt_1, rt_2, includes, libs;
      DAE.Function fel;
      list<DAE.Function> rest;
    case ({}, accfns, rt, includes, libs)
      then (listReverse(accfns), rt, listReverse(includes), listReverse(libs));
    case ((DAE.FUNCTION(partialPrefix = true) :: rest), accfns, rt, includes, libs)
      equation
        // skip over partial functions
        (fns, rt_2, includes, libs) = elaborateFunctions2(rest, accfns, rt, includes, libs);
      then
        (fns, rt_2, includes, libs);
    case ((fel :: rest), accfns, rt, includes, libs)
      equation
        (fn, rt_1, includes, libs) = elaborateFunction(fel, rt, includes, libs);
        (fns, rt_2, includes, libs) = elaborateFunctions2(rest, (fn :: accfns), rt_1, includes, libs);
      then
        (fns, rt_2, includes, libs);
  end matchcontinue;
end elaborateFunctions2;

/* Does the actual work of transforming a DAE.FUNCTION to a Function. */
protected function elaborateFunction
  input DAE.Function inElement;
  input list<String> inRecordTypes;
  input list<String> inIncludes;
  input list<String> inLibs;
  output Function outFunction;
  output list<String> outRecordTypes;
  output list<String> outIncludes;
  output list<String> outLibs;
algorithm
  (outFunction,outRecordTypes,outIncludes,outLibs):=
  matchcontinue (inElement,inRecordTypes,includes,libs)
    local
      DAE.Function fn;
      String fn_name_str,fn_name_str_1,retstr,extfnname,lang,retstructtype,extfnname_1,n,str;
      list<DAE.Element> dae,bivars,orgdae,daelist,funrefs, algs, vars, invars, outvars;
      list<String> struct_strs,arg_strs,includes,libs,struct_strs_1,funrefStrs,fn_libs,fn_includes;
      Absyn.Path fpath;
      list<tuple<String, Types.Type>> args;
      Types.Type restype,tp;
      list<DAE.ExtArg> extargs;
      list<SimExtArg> simextargs;
      SimExtArg extReturn;
      DAE.ExtArg extretarg;
      Option<Absyn.Annotation> ann;
      DAE.ExternalDecl extdecl;
      DAE.Element comp;
      list<String> rt, rt_1, struct_funrefs, struct_funrefs_int,includes,libs;
      list<Absyn.Path> funrefPaths;
      list<Variable> outVars, inVars, biVars, funArgs, varDecls;
      list<RecordDeclaration> recordDecls;
      list<Statement> body;
      DAE.InlineType inl;
      list<DAE.Element> daeElts;

    /* Modelica functions. */
    case (DAE.FUNCTION(path = fpath,
                       functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
                       type_ = tp as (DAE.T_FUNCTION(funcArg=args, funcResultType=restype), _),
                       partialPrefix=false), rt, includes, libs)
      equation
        outVars = Util.listMap(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        inVars = Util.listMap(DAEUtil.getInputVars(daeElts), daeInOutSimVar);
        funArgs = Util.listMap(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, {}, rt);
        vars = Util.listFilter(daeElts, isVarQ);
        varDecls = Util.listMap(vars, daeInOutSimVar);
        algs = Util.listFilter(daeElts, DAEUtil.isAlgorithm);
        body = Util.listMap(algs, elaborateStatement);
      then
        (FUNCTION(fpath,inVars,outVars,recordDecls,funArgs,varDecls,body),rt_1,includes,libs);
    /* External functions. */
    case (DAE.FUNCTION(path = fpath,
                       functions = DAE.FUNCTION_EXT(body =  daeElts, externalDecl = extdecl)::_, // might be followed by derivative maps
                       type_ = (tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_))),rt,includes,libs)
      equation
        DAE.EXTERNALDECL(ident=extfnname, external_=extargs,
                         parameters=extretarg, returnType=lang, language=ann) = extdecl;
        outvars = DAEUtil.getOutputVars(daeElts);
        invars = DAEUtil.getInputVars(daeElts);
        bivars = DAEUtil.getBidirVars(daeElts);
        funArgs = Util.listMap(args, typesSimFunctionArg);
        outVars = Util.listMap(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        inVars = Util.listMap(DAEUtil.getInputVars(daeElts), daeInOutSimVar);
        biVars = Util.listMap(DAEUtil.getBidirVars(daeElts), daeInOutSimVar);
        (recordDecls,rt_1) = elaborateRecordDeclarations(daeElts, {}, rt);
        (fn_includes, fn_libs) = generateExtFunctionIncludes(ann);
        includes = Util.listUnion(fn_includes, includes);
        libs = Util.listUnion(fn_libs, libs);
        simextargs = Util.listMap(extargs, extArgsToSimExtArgs);
        extReturn = extArgsToSimExtArgs(extretarg);
        (simextargs, extReturn) = fixOutputIndex(outVars, simextargs, extReturn);
      then
        (EXTERNAL_FUNCTION(fpath, extfnname, funArgs, simextargs, extReturn,
                           inVars, outVars, biVars, lang, recordDecls),
         rt_1,includes,libs);
    /* Record constructor. */
    case (DAE.RECORD_CONSTRUCTOR(path = fpath, type_ = tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)),_)),_)), rt,includes,libs)
      local
        String  defhead, head, foot, body, decl1, decl2, assign_res, ret_var, record_var, record_var_dot, return_stmt;
        DAE.ExpType expType;
        list<String> arg_names, arg_tmp1, arg_tmp2, arg_assignments;
        Integer tnr;
        Absyn.Path name;
      equation
        funArgs = Util.listMap(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarationsForRecord(restype, {}, rt);
      then
        (RECORD_CONSTRUCTOR(name, funArgs, recordDecls),rt_1,includes,libs);
    case (fn,_,_,_)
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
  outString:=
  matchcontinue (inFuncArg)
    local
      Types.Type tty;
      Exp.Type expType;
      String name;
    case ((name, tty as (DAE.T_FUNCTION(funcArg = args, funcResultType = res_ty), _)))
      local
        list<Types.FuncArg> args;
        DAE.Type res_ty;
        Exp.Type res_exp_ty;
        list<Variable> var_args;
      equation
        //expType = Types.elabType(tty);
        res_exp_ty = Types.elabType(res_ty);
        var_args = Util.listMap(args, typesSimFunctionArg);
      then
        FUNCTION_PTR(name, res_exp_ty, var_args);
    case ((name,tty))
      equation
        expType = Types.elabType(tty);
      then
        VARIABLE(DAE.CREF_IDENT(name, expType, {}),expType,NONE,{});
  end matchcontinue;
end typesSimFunctionArg;

protected function daeInOutSimVar
  input DAE.Element inElement;
  output Variable outVar;
algorithm
  outVar := matchcontinue(inElement)
    local
      String name;
      Exp.Type expType;
      DAE.Type daeType;
      Exp.ComponentRef id;
      list<Exp.Subscript> inst_dims;
      list<DAE.Exp> inst_dims_exp;
      Option<DAE.Exp> binding;
      Variable var;
    case (DAE.VAR(componentRef = DAE.CREF_IDENT(ident=name),ty = daeType as (DAE.T_FUNCTION(funcArg=_),_)))
      equation
        var = typesSimFunctionArg((name,daeType));
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
  matchcontinue (extArg)
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
      then SIMEXTARG(componentRef, isInput, outputIndex, isArray, expType);
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
  end matchcontinue;
end extArgsToSimExtArgs;

protected function fixOutputIndex
  input list<Variable> outVars;
  input list<SimExtArg> simExtArgsIn;
  input SimExtArg extReturnIn;
  output list<SimExtArg> simExtArgsOut;
  output SimExtArg extReturnOut;
algorithm
  (simExtArgsOut, extReturnOut) :=
  matchcontinue (outVars, simExtArgsIn, extReturnIn)
    local
      DAE.ComponentRef cref;
      Boolean isInput;
      Integer outputIndex;
      Boolean isArray;
      DAE.ExpType type_;
      Integer newOutputIndex;
    case (outVars, simExtArgsIn, extReturnIn)
      equation
        simExtArgsOut = Util.listMap1(simExtArgsIn, assignOutputIndex, outVars);
        extReturnOut = assignOutputIndex(extReturnIn, outVars);
      then
        (simExtArgsOut, extReturnOut);
  end matchcontinue;
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
      Boolean isArray;
      DAE.ExpType type_;
      DAE.Exp exp;
      Integer newOutputIndex;
    case (SIMEXTARG(cref, isInput, outputIndex, isArray, type_), outVars)
      equation
        true = outputIndex == -1;
        newOutputIndex = findIndexInList(cref, outVars, 1);
      then SIMEXTARG(cref, isInput, newOutputIndex, isArray, type_);
    case (SIMEXTARGSIZE(cref, isInput, outputIndex, type_, exp), outVars)
      equation
        true = outputIndex == -1;
        newOutputIndex = findIndexInList(cref, outVars, 1);
      then SIMEXTARGSIZE(cref, isInput, newOutputIndex, type_, exp);
    case (simExtArgIn, _)
      then simExtArgIn;
  end matchcontinue;
end assignOutputIndex;

protected function findIndexInList
  input DAE.ComponentRef cref;
  input list<Variable> outVars;
  input Integer currentIndex;
  output Integer crefIndexInOutVars;
algorithm
  crefIndexInOutVars :=
  matchcontinue (cref, outVars, currentIndex)
    local
      DAE.ComponentRef name;
      list<Variable> restOutVars;
      String crefStr;
      String nameStr;
    case (cref, {}, currentIndex)
      then -1;
    case (cref, VARIABLE(name=name) :: restOutVars, currentIndex)
      equation
        crefStr = Exp.crefStr(cref);
        nameStr = Exp.crefStr(name);
        true = stringEqual(crefStr, nameStr);
      then currentIndex;
    case (cref, _ :: restOutVars, currentIndex)
      equation
        currentIndex = currentIndex + 1;
      then findIndexInList(cref, restOutVars, currentIndex);
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
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input DAELow.IncidenceMatrix inIncidenceMatrix5;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT6;
  input list<list<Integer>> inIntegerLstLst7;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> libs;
  input Option<SimulationSettings> simSettingsOpt;
  output SimCode simCode;
algorithm
  simCode :=
  matchcontinue (functionTree,inDAELow2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inIntegerLstLst7,inClassName,filenamePrefix,inString11,functions,externalFunctionIncludes,libs,simSettingsOpt)
    local
      String cname, filename, funcfilename, fileDir;
      list<list<Integer>> blt_states,blt_no_states,comps;
      list<list<Integer>> contBlocks,discBlocks;
      Integer n_h,nres,maxDelayedExpIndex;
      list<HelpVarInfo> helpVarInfo,helpVarInfo1;
      DAE.DAElist dae;
      DAELow.DAELow dlow,dlow2;
      Integer[:] ass1,ass2;
      list<Integer>[:] m,mt;
      Absyn.Path class_;
      // new variables
      SimCode simCode;
      ModelInfo modelInfo;
      list<SimEqSystem> allEquations;
      list<SimEqSystem> allEquationsPlusWhen;
      list<SimEqSystem> stateContEquations;
      list<SimEqSystem> nonStateContEquations;
      list<SimEqSystem> nonStateDiscEquations;
      list<SimEqSystem> residualEquations;
      list<SimEqSystem> initialEquations;
      list<SimEqSystem> parameterEquations;
      list<SimEqSystem> removedEquations;
      list<Algorithm.Statement> algorithmAndEquationAsserts;
      list<DAELow.ZeroCrossing> zeroCrossings;
      list<list<SimVar>> zeroCrossingsNeedSave;
      list<SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      ExtObjInfo extObjInfo;
      MakefileParams makefileParams;
      list<tuple<Integer, DAE.Exp>> delayedExps;
      list<DAE.Exp> divLst;
      list<DAE.Statement> allDivStmts;
      DAELow.Variables orderedVars,knownVars,vars;
      list<DAELow.Var> varlst,varlst1,varlst2;
      list<Function> functionList;
      
      list<JacobianMatrix> LinearMats;
                  
    case (functionTree,dlow,ass1,ass2,m,mt,comps,class_,filenamePrefix,fileDir,functions,externalFunctionIncludes,libs,simSettingsOpt)
      equation
        cname = Absyn.pathString(class_);
          
        (blt_states, blt_no_states) = DAELow.generateStatePartition(comps, dlow, ass1, ass2, m, mt);

        (helpVarInfo, dlow2) = generateHelpVarInfo(dlow, comps);
        n_h = listLength(helpVarInfo);

        residualEquations = createResidualEquations(dlow2, ass1, ass2);
        nres = listLength(residualEquations);

        extObjInfo = createExtObjInfo(dlow2);
        // Add model info
        modelInfo = createModelInfo(class_, dlow2, n_h, nres, fileDir);
        allEquations = createEquations(false, false, true, dlow2, ass1, ass2, comps, helpVarInfo);
        allEquationsPlusWhen = createEquations(true, false, true, dlow2, ass1, ass2, comps, helpVarInfo);
        stateContEquations = createEquations(false, false, false, dlow2, ass1, ass2, blt_states, helpVarInfo);
        (contBlocks, discBlocks) = splitOutputBlocks(dlow2, ass1, ass2, m, mt, blt_no_states);
        nonStateContEquations = createEquations(false, false, true, dlow2, ass1, ass2,
                                                contBlocks, helpVarInfo);
        nonStateDiscEquations = createEquations(false, useZerocrossing(), true, dlow2, ass1, ass2,
                                                discBlocks, helpVarInfo);
        initialEquations = createInitialEquations(dlow2);
        parameterEquations = createParameterEquations(dlow2);
        removedEquations = createRemovedEquations(dlow2);
        algorithmAndEquationAsserts = createAlgorithmAndEquationAsserts(dlow2);
        zeroCrossings = createZeroCrossings(dlow2);
        zeroCrossingsNeedSave = createZeroCrossingsNeedSave(zeroCrossings, dlow2, ass1, ass2, comps);
        whenClauses = createSimWhenClauses(dlow2, helpVarInfo);
        discreteModelVars = extractDiscreteModelVars(dlow2, mt);
        makefileParams = createMakefileParams(libs);
        (delayedExps,maxDelayedExpIndex) = extractDelayedExpressions(dlow2);

        // replace div operator with div operator with check of Division by zero
        orderedVars = DAELow.daeVars(dlow);
        knownVars = DAELow.daeKnVars(dlow);
      	varlst = DAELow.varList(orderedVars);
      	varlst1 = DAELow.varList(knownVars);
      	varlst2 = listAppend(varlst,varlst1);  
      	vars = DAELow.listVar(varlst2);         
        (allEquations,divLst) = listMap1_2(allEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ONLY_VARIABLES()));        
        (allEquationsPlusWhen,_) = listMap1_2(allEquationsPlusWhen,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ONLY_VARIABLES()));        
        (stateContEquations,_) = listMap1_2(stateContEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ONLY_VARIABLES()));        
        (nonStateContEquations,_) = listMap1_2(nonStateContEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ONLY_VARIABLES()));        
        (nonStateDiscEquations,_) = listMap1_2(nonStateDiscEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ONLY_VARIABLES()));        
        (residualEquations,_) = listMap1_2(residualEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ALL()));        
        (initialEquations,_) = listMap1_2(initialEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ALL()));        
        (parameterEquations,_) = listMap1_2(parameterEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ALL()));        
        (removedEquations,_) = listMap1_2(removedEquations,addDivExpErrorMsgtoSimEqSystem,(vars,varlst2,DAELow.ONLY_VARIABLES()));        
        // add equations with only parameters as division expression
        allDivStmts = Util.listMap(divLst,generateParameterDivisionbyZeroTestEqn);
        parameterEquations = listAppend(parameterEquations,{SES_ALGORITHM(allDivStmts)});
        
        // Replace variables in nonlinear equation systems with xloc[index]
        // variables.
        allEquations = applyResidualReplacements(allEquations);
        
        LinearMats = createLinearModelMatrixes(functionTree,dlow,ass1,ass2);
        simCode = SIMCODE(modelInfo,
          functions,
          externalFunctionIncludes,
          allEquations,
          allEquationsPlusWhen,
          stateContEquations,
          nonStateContEquations,
          nonStateDiscEquations,
          residualEquations,
          initialEquations,
          parameterEquations,
          removedEquations,
          algorithmAndEquationAsserts,
          zeroCrossings,
          zeroCrossingsNeedSave,
          helpVarInfo,
          whenClauses,
          discreteModelVars,
          extObjInfo,
          makefileParams,
          DELAYED_EXPRESSIONS(delayedExps, maxDelayedExpIndex),
          LinearMats,
          simSettingsOpt,
          filenamePrefix,
          dlow);
      then
        simCode;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of simulation using code using templates failed"});
      then
        fail();
  end matchcontinue;
end createSimCode;


protected function createLinearModelMatrixes
  input DAE.FunctionTree functions;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  output list<JacobianMatrix> JacobianMatrixes;
algorithm
  JacobianMatrixes :=
  matchcontinue (functions,inDAELow2,inIntegerArray3,inIntegerArray4)
    local
      DAE.DAElist dae;
      DAELow.DAELow dlow,deriveddlow1,deriveddlow2;
      Integer[:] ass1,ass2;

      //DAELow.Variables v,kv;
      list<DAELow.Var> derivedVariables, varlst,varlst1,varlst2, states, inputvars, outputvars;
      list<DAE.ComponentRef> comref_states, comref_inputvars, comref_outputvars;

      Integer[:] v1,v2;
      list<list<Integer>> comps1;
      list<SimEqSystem> JacAEquations;
      list<SimEqSystem> JacBEquations;
      list<SimEqSystem> JacCEquations;
      list<SimEqSystem> JacDEquations;
      list<SimVar> JacAVars, JacBVars, JacCVars, JacDVars;
 
      DAELow.Variables v,kv,exv;
      DAELow.AliasVariables av;
      DAELow.EquationArray e,re,ie;
      DAELow.MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      DAELow.EventInfo ev;
      DAELow.ExternalObjectClasses eoc;
      list<DAELow.Equation> e_lst,re_lst,ie_lst;
      list<DAE.Algorithm> algs;
      list<DAELow.MultiDimEquation> ae_lst;
 
      list<JacobianMatrix> LinearMats;   

    case (functions,dlow as DAELow.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),ass1,ass2)
      equation
        true = RTOpts.debugFlag("linearization");
        Debug.fcall("linmodel",print,"Generate Linear Model Matrices\n");
        
        // Prepare all needed variables
        //v = DAELow.daeVars(dlow);
        //kv = DAELow.daeKnVars(dlow);
      	varlst = DAELow.varList(v);
      	varlst1 = DAELow.varList(kv);
      	e_lst = DAELow.equationList(e);
      	varlst2 = listAppend(varlst,varlst1);
      	varlst = listReverse(varlst);
      	varlst1 = listReverse(varlst1);
      	varlst2 = listReverse(varlst2);  
        states = Util.listSelect(varlst,DAELow.isStateVar);
        inputvars = Util.listSelect(varlst1,DAELow.isVarOnTopLevelAndInput);
        outputvars = Util.listSelect(varlst2,DAELow.isVarOnTopLevelAndOutput);
        comref_states = Util.listMap(states,DAELow.varCref);
        comref_inputvars = Util.listMap(inputvars,DAELow.varCref);
        comref_outputvars = Util.listMap(outputvars,DAELow.varCref);
        
        //e_lst = replaceDerOpInEquationList(e_lst);
        //e_lst = solveDAELow(e_lst, varlst, arrayList(ass2));
        //e = DAELow.listEquation(e_lst);
        //dlow = DAELow.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc);
        // Create SimCode structure for Jacobian or rather for Linearization

        // Differentiate the System w.r.t states for matrices A and C
        Debug.fcall("linmodel",print,"Differentiate System w.r.t. states.\n");   
        deriveddlow1 = DAELow.generateSymbolicJacobian(dlow, functions, comref_states);
        Debug.fcall("linmodel",print,"Done! Create now Matrixes A and C for linear model.\n");
        
         // create Matrix A and variables
        Debug.fcall("jacdump2", print, "Dump of daelow for Matrix A.\n");
        (deriveddlow2, v1, v2, comps1) = DAELow.generateLinearMatrix(deriveddlow1,functions,comref_states,comref_states,varlst);
        JacAEquations = createEquations(true, false, true, deriveddlow2, v1, v2, comps1, {});
        v = DAELow.daeVars(deriveddlow2);
        derivedVariables = DAELow.varList(v);
        JacAVars =  Util.listMap(derivedVariables, dlowvarToSimvar);
        
        // create Matrix C and variables
        Debug.fcall("jacdump2", print, "Dump of daelow for Matrix C.\n");
        (deriveddlow2, v1, v2, comps1) = DAELow.generateLinearMatrix(deriveddlow1,functions,comref_outputvars,comref_states,varlst);
        JacCEquations = createEquations(true, false, true, deriveddlow2, v1, v2, comps1, {});
        v = DAELow.daeVars(deriveddlow2);
        derivedVariables = DAELow.varList(v);
        JacCVars =  Util.listMap(derivedVariables, dlowvarToSimvar);
        
        // Differentiate the System w.r.t states for matrices B and D
        Debug.fcall("linmodel",print,"Differentiate System w.r.t. inputs.\n");
        deriveddlow1 = DAELow.generateSymbolicJacobian(dlow, functions, comref_inputvars);
        Debug.fcall("linmodel",print,"Done! Create now Matrixes B and D for linear model.\n");

        // create Matrix B and variables
        Debug.fcall("jacdump2", print, "Dump of daelow for Matrix B.\n");
        (deriveddlow2, v1, v2, comps1) = DAELow.generateLinearMatrix(deriveddlow1,functions,comref_states,comref_inputvars,varlst);
        JacBEquations = createEquations(true, false, true, deriveddlow2, v1, v2, comps1, {});
        v = DAELow.daeVars(deriveddlow2);
        derivedVariables = DAELow.varList(v);
        JacBVars =  Util.listMap(derivedVariables, dlowvarToSimvar);
        
        // create Matrix D and variables
        Debug.fcall("jacdump2", print, "Dump of daelow for Matrix D.\n");
        (deriveddlow2, v1, v2, comps1) = DAELow.generateLinearMatrix(deriveddlow1,functions,comref_outputvars,comref_inputvars,varlst);
        JacDEquations = createEquations(true, false, true, deriveddlow2, v1, v2, comps1, {});
        v = DAELow.daeVars(deriveddlow2);
        derivedVariables = DAELow.varList(v);
        JacDVars =  Util.listMap(derivedVariables, dlowvarToSimvar);

        LinearMats = {(JacAEquations,JacAVars,"A"),(JacBEquations,JacBVars,"B"),(JacCEquations,JacCVars,"C"),(JacDEquations,JacDVars,"D")};  

      then
        LinearMats;
    case (_,dlow,ass1,ass2)
      equation
        false = RTOpts.debugFlag("linearization");
        LinearMats = {({},{},"A"),({},{},"B"),({},{},"C"),({},{},"D")};
      then
        LinearMats;        
    case (_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of LinearModel Matrixes code using templates failed"});
      then
        fail();
  end matchcontinue;
end createLinearModelMatrixes;

protected function solveDAELow
  input list<DAELow.Equation> inEqns;
  input list<DAELow.Var> inVars;
  input list<Integer> inAss2;
  output list<DAELow.Equation> outEqns;
algorithm
  outEqns := matchcontinue(inEqns, inVars, inAss2)
  local
      DAELow.Equation currEqn, currSolvedEqn;
      list<DAELow.Equation> restEqns, restSolvedEqns;
      list<DAELow.Var> vars;
      Integer currAss;
      list<Integer> restAss;
      DAELow.Var currVar;
      DAE.ComponentRef cref;
      
    case({}, _, _) then {};
    case(currEqn::restEqns, vars, currAss::restAss) equation
      currVar = listNth(vars, currAss-1);
      false = DAELow.isStateVar(currVar);
      cref = DAELow.varCref(currVar);
      currSolvedEqn = solveEqn(currEqn, cref);
      restSolvedEqns = solveDAELow(restEqns, vars, restAss);
    then currSolvedEqn::restSolvedEqns;
      
    case(currEqn::restEqns, vars, currAss::restAss) equation
      currVar = listNth(vars, currAss-1);
      true = DAELow.isStateVar(currVar);
      cref = DAELow.varCref(currVar);
      cref = DAELow.makeDerCref(cref);
      currSolvedEqn = solveEqn(currEqn, cref);
      restSolvedEqns = solveDAELow(restEqns, vars, restAss);
    then currSolvedEqn::restSolvedEqns;
  end matchcontinue;
end solveDAELow;

protected function solveEqn
  input DAELow.Equation inEqn;
  input DAE.ComponentRef inCref;
  output DAELow.Equation outEqn;
algorithm
  outEqn := matchcontinue(inEqn, inCref)
    case(DAELow.EQUATION(exp=lhs, scalar=rhs, source=source), cref)
      local
        DAE.ComponentRef cref;
        DAE.Exp lhs, rhs, exp;
        DAE.ElementSource source;
      equation
        exp = solve(lhs, rhs, DAE.CREF(cref, DAE.ET_REAL()));
    then DAELow.SOLVED_EQUATION(cref, exp, source);
      
    case(eqn, _) local DAELow.Equation eqn;
    then eqn;
  end matchcontinue;
end solveEqn;

protected function extractDelayedExpressions
  input DAELow.DAELow dlow;
  output list<tuple<Integer, DAE.Exp>> delayedExps;
  output Integer maxDelayedExpIndex;
algorithm
  (delayedExps,maxDelayedExpIndex) := matchcontinue(dlow)
    local
      list<DAE.Exp> exps;
    case (dlow)
      equation
        exps = DAELow.traverseDEALowExps(dlow,DAELow.findDelaySubExpressions,{});
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
  matchcontinue (delayCallExp)
    local
      DAE.Exp id, e, delay, delayMax;
      Integer i;
    case (DAE.CALL(path=Absyn.IDENT("delay"), expLst={DAE.ICONST(i),e,delay,delayMax}))
      then ((i, e));
  end matchcontinue;
end extractIdAndExpFromDelayExp;

protected function createMakefileParams
  input list<String> libs;
  output MakefileParams makefileParams;
algorithm
  makefileParams :=
  matchcontinue (libs)
    local
      String omhome,header,ccompiler,cxxcompiler,linker,exeext,dllext,cflags,ldflags,senddatalibs;
    case (libs)
      equation
        ccompiler = System.getCCompiler();
        cxxcompiler = System.getCXXCompiler();
        linker = System.getLinker();
        exeext = System.getExeExt();
        dllext = System.getDllExt();
        omhome = Settings.getInstallationDirectoryPath();
        omhome = System.trim(omhome, "\""); // Remove any quotation marks from omhome.
        cflags = System.getCFlags();
        ldflags = System.getLDFlags();
        senddatalibs = System.getSendDataLibs();
      then MAKEFILE_PARAMS(ccompiler, cxxcompiler, linker, exeext, dllext,
                           omhome, cflags, ldflags, senddatalibs, libs);
  end matchcontinue;
end createMakefileParams;

protected function generateHelpVarInfo
  input DAELow.DAELow dlow;
  input list<list<Integer>> comps;
  output list<HelpVarInfo> outHelpVarInfo;
  output DAELow.DAELow outDAELow;
algorithm
  (outHelpVarInfo, outDAELow) :=
  matchcontinue (dlow, comps)
    case (dlow, comps)
      local
        DAELow.DAELow dlow2;
        list<HelpVarInfo> helpVarInfo1;
        list<HelpVarInfo> helpVarInfo;
      equation
        helpVarInfo1 = helpVarInfoFromWhenConditionChecks(dlow, comps);
        (helpVarInfo, dlow2) = generateHelpVarsForWhenStatements(helpVarInfo1, dlow);
      then (helpVarInfo, dlow2);
  end matchcontinue;
end generateHelpVarInfo;

protected function helpVarInfoFromWhenConditionChecks
"Return a list of help variables that were introduced by when conditions?"
  input DAELow.DAELow inDAELow;
  input list<list<Integer>> comps;
  output list<HelpVarInfo> helpVarList;
algorithm
  helpVarLst :=
  matchcontinue (inDAELow, comps)
    local
      list<Integer> orderOfEquations,orderOfEquations_1;
      list<DAELow.Equation> eqnl;
      Integer n;
      list<HelpVarInfo> helpVarInfo1,helpVarInfo2,helpVarInfo;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      list<DAELow.WhenClause> whenClauseList;
      list<list<Integer>> blocks;
    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,eventInfo = DAELow.EVENT_INFO(whenClauseLst = whenClauseList))),blocks)
      equation
        orderOfEquations = generateEquationOrder(blocks);
        eqnl = DAELow.equationList(eqns);
        n = listLength(eqnl);
        orderOfEquations_1 = addMissingEquations(n, orderOfEquations);
        // First generate checks for all when equations, in the order of the sorted equations.
        (_, helpVarInfo1) = buildWhenConditionChecks4(orderOfEquations_1, eqnl, whenClauseList, 0);
        n = listLength(helpVarInfo1);
        // Generate checks also for when clauses without equations but containing reinit statements.
        (_, helpVarInfo2) = buildWhenConditionChecks2(whenClauseList, 0, n);
        helpVarInfo = listAppend(helpVarInfo1, helpVarInfo2);
      then
        (helpVarInfo);
    case (_,_)
      equation
        print("-build_when_condition_checks failed.\n");
      then
        fail();
  end matchcontinue;
end helpVarInfoFromWhenConditionChecks;

protected function buildDiscreteVarChanges "
For all discrete variables in the model, generate code that checks if they have changed and if so generate code
that add events to the event queue: if (change(<discretevar>)) { AddEvent(c1);...;AddEvent(cn)}

"
  input DAELow.DAELow daelow;
  input list<list<Integer>> comps;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrixT mT;
  output String outString;
algorithm
  outString := matchcontinue(daelow,comps,ass1,ass2,m,mT)
    local String s1,s2;
      list<Integer> b;
      list<list<Integer>> blocks;
      DAELow.Variables v;
      list<DAELow.Var> vLst;
    case (daelow as DAELow.DAELOW(orderedVars = v),blocks,ass1,ass2,m,mT)
      equation
      vLst = DAELow.varList(v);
      vLst = Util.listSelect(vLst,DAELow.isVarDiscrete); // select all discrete vars.
			outString = Util.stringDelimitList(Util.listMap2(vLst, buildDiscreteVarChangesVar,daelow,mT),"\n  ");
    then outString;
    case(_,_,_,_,_,_) equation
      print("buildDiscreteVarChanges failed\n");
      then fail();
  end matchcontinue;
end buildDiscreteVarChanges;

protected function buildDiscreteVarChangesVar "help function to buildDiscreteVarChanges"
  input DAELow.Var var;
  input DAELow.DAELow daelow;
  input DAELow.IncidenceMatrixT mT;
  output String outString;
algorithm
  outString := matchcontinue(var,daelow,mT)
    local list<String> strLst;
      Exp.ComponentRef cr;
      Integer varIndx;
      list<Integer> eqns;
    case(var as DAELow.VAR(varName=cr,index=varIndx), daelow,mT) equation
      eqns = mT[varIndx+1]; // eqns containing var
      true = crefNotInWhenEquation(cr,daelow,eqns);
      outString = buildDiscreteVarChangesAddEvent(0,cr);
    then outString;

    case(_,_,_) then "";
  end matchcontinue;
end buildDiscreteVarChangesVar;

protected function crefNotInWhenEquation "Returns true if cref is not solved in any of the equations
given as indices which is a when_equation"
  input Exp.ComponentRef cr;
  input DAELow.DAELow daelow;
  input list<Integer> eqns;
  output Boolean res;
algorithm
  res := matchcontinue(cr,daelow,eqns)
  local
    DAELow.EquationArray eqs;
    Integer e;
    Exp.ComponentRef cr2;
    Exp.Exp exp;
    Boolean b1,b2;
    case(cr,daelow,{}) then true;
    case(cr,daelow as DAELow.DAELOW(orderedEqs=eqs),e::eqns) 
      equation
        DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(_,cr2,exp,_)) = DAELow.equationNth(eqs,intAbs(e)-1);
        //We can asume the same component refs are solved in any else-branch.
        b1 = Exp.crefEqual(cr,cr2);
        b2 = Exp.expContains(exp,DAE.CREF(cr,DAE.ET_OTHER()));
        true = boolOr(b1,b2);
      then false;
    case(cr,daelow,_::eqns) 
      equation
        res = crefNotInWhenEquation(cr,daelow,eqns);
      then res;
  end matchcontinue;
end crefNotInWhenEquation;

// TODO: use another switch ... later make it first class option like -target or so
protected function callTargetTemplates
"Generate target code by passing the SimCode data structure to templates."
  input SimCode simCode;
algorithm
  (_) :=
  matchcontinue (simCode)
    case (simCode)
      equation
        true = RTOpts.debugFlag("CSharp");
        Tpl.tplNoret(SimCodeCSharp.translateModel, simCode);
      then ();
    case (simCode)
      equation
        false = RTOpts.debugFlag("CSharp");
        Tpl.tplNoret(SimCodeC.translateModel, simCode);
      then ();
  end matchcontinue;
end callTargetTemplates;

protected function elaborateRecordDeclarationsFromTypes
  input list<DAE.Type> inTypes;
  input list<RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) :=
  matchcontinue (inTypes, inAccRecordDecls, inReturnTypes)
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
  end matchcontinue;
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

    case ({}, accRecDecls, rt)
      then (accRecDecls,rt);
    case (((var as DAE.VAR(ty = ft)) :: rest), accRecDecls, rt)
      equation
        (accRecDecls,rt_1) = elaborateRecordDeclarationsForRecord(ft, accRecDecls, rt);
        (accRecDecls,rt_2) = elaborateRecordDeclarations(rest, accRecDecls, rt_1);
      then
        (accRecDecls,rt_2);
    case ((DAE.ALGORITHM(algorithm_ = algorithm_) :: rest), accRecDecls, rt)
      local
        Algorithm.Algorithm algorithm_;
        list<Exp.Exp> expl;
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        expl = Algorithm.getAllExps(algorithm_);
        expl = getMatchingExpsList(expl, matchMetarecordCalls);
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
  outStrs :=
  matchcontinue (inRecordType,inAccRecordDecls,inReturnTypes)
    local
      Absyn.Path path,name;
      list<Types.Var> varlst;
      String first_str, last_str, path_str;
      list<String> res,strs,rest_strs,decl_strs,rt,rt_1,rt_2,record_definition,fieldNames;
      list<RecordDeclaration> accRecDecls;
      list<Variable> vars;

      RecordDeclaration recDecl;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name), complexVarLst = varlst),SOME(path)), accRecDecls, rt)
      local  String sname;
      equation
        sname = Absyn.pathString(name);
        sname = ModUtil.pathStringReplaceDot(name, "_");
        failure(_ = Util.listGetMember(sname,rt));

        vars = Util.listMap(varlst, typesVar);

        rt_1 = sname :: rt;
        (accRecDecls,rt_2) = elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);
        recDecl = RECORD_DECL_FULL(sname, path, vars);
        accRecDecls = Util.listAppendElt(recDecl, accRecDecls);
      then (accRecDecls,rt_2);
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name), complexVarLst = varlst),_), accRecDecls, rt)
      then (accRecDecls,rt);
    case ((DAE.T_METARECORD(fields = varlst), SOME(path)), accRecDecls, rt)
      local  String sname;
      equation
        sname = ModUtil.pathStringReplaceDot(path, "_");
        failure(_ = Util.listGetMember(sname,rt));

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
  outStrs :=
  matchcontinue (inRecordTypes,inAccRecordDecls,inReturnTypes)
    local
      Types.Type ty;
      list<Types.Var> rest;
      list<String> res,strs,strs_rest,rt,rt_1,rt_2;
      list<RecordDeclaration> accRecDecls;
    case ({},accRecDecls,rt)
      then (accRecDecls,rt);
    case (DAE.TYPES_VAR(type_ = (ty as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_)))::rest,accRecDecls,rt)
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
  input list<Exp.Exp> inExpl;
  input list<RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls,outReturnTypes) := matchcontinue(inExpl, inAccRecordDecls, inReturnTypes)
    local
      list<String> rt,rt_1,rt_2,fieldNames;
      list<Exp.Exp> rest;
      String name;
      Absyn.Path path;
      list<RecordDeclaration> accRecDecls;

    case ({},accRecDecls,rt) then (accRecDecls,rt);
    case (DAE.METARECORDCALL(path=path,fieldNames=fieldNames)::rest, accRecDecls, rt)
      equation
        name = ModUtil.pathStringReplaceDot(path, "_");
        failure(_ = Util.listGetMember(name,rt));
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
  input DAELow.DAELow dlow;
  output ExtObjInfo extObjInfo;
algorithm
  extObjInfo :=
  matchcontinue (dlow)
    local
      DAELow.Variables evars;
      DAELow.ExternalObjectClasses eclasses;
      list<DAELow.Var> evarLst;
      list<String> includes;
      list<ExtConstructor> constructors;
      list<ExtDestructor> destructors;
      list<ExtAlias> aliases;
    case (dlow as DAELow.DAELOW(externalObjects=evars, extObjClasses=eclasses))
      equation
        evarLst = DAELow.varList(evars);
        (includes, _) = generateExternalObjectIncludes(dlow);
        (constructors, destructors, aliases) = extractExtObjInfo2(evarLst, eclasses);
      then EXTOBJINFO(includes, constructors, destructors, aliases);
  end matchcontinue;
end createExtObjInfo;

protected function extractExtObjInfo2
  input list<DAELow.Var> varLst;
  input DAELow.ExternalObjectClasses eclasses;
  output list<ExtConstructor> constructors;
  output list<ExtDestructor> destructors;
  output list<ExtAlias> aliases;
algorithm
  (constructors, destructors, aliases) :=
  matchcontinue (varLst, eclasses)
    local
      DAELow.Var v;
      list<DAELow.Var> vs;
      list<ExtConstructor> constructors1;
      list<ExtDestructor> destructors1;
      list<ExtAlias> aliases1;
    case ({}, eclasses)
      then ({}, {}, {});
    case (v :: vs, eclasses)
      equation
        (constructors1, destructors1, aliases1) = createExtObjInfoSingle(v, eclasses);
        (constructors, destructors, aliases) = extractExtObjInfo2(vs, eclasses);
        constructors = listAppend(constructors1, constructors);
        destructors = listAppend(destructors1, destructors);
        aliases = listAppend(aliases1, aliases);
      then (constructors, destructors, aliases);
  end matchcontinue;
end extractExtObjInfo2;

protected function createExtObjInfoSingle
  input DAELow.Var var;
  input DAELow.ExternalObjectClasses eclasses;
  output list<ExtConstructor> constructors;
  output list<ExtDestructor> destructors;
  output list<ExtAlias> aliases;
algorithm
  (constructors, destructors, aliases) :=
  matchcontinue (var, eclasses)
    local
      DAE.Element ctor, dstr;
      DAE.ComponentRef name;
      DAE.ComponentRef cr;
      list<DAE.Exp> args;
      Absyn.Path path1, path2;
      String cFuncStr, dFuncStr;
    case (_, {})
      then fail();
    // alias
    case (DAELow.VAR(varName=name, bindExp=SOME(DAE.CREF(cr,_)),
                     varKind=DAELow.EXTOBJ(_)), _)
      then ({}, {}, {(name, cr)});
    case (DAELow.VAR(varName=name), {})
      equation
        print("generateExternalObjectConstructorCall for var:");
        print(Exp.printComponentRefStr(name));print(" failed\n");
      then fail();
    // found class
    case (DAELow.VAR(varName=name, bindExp=SOME(DAE.CALL(expLst=args)),
                     varKind=DAELow.EXTOBJ(path1)),
          DAELow.EXTOBJCLASS(
            path=path2,
            constructor=DAE.FUNCTION(
              functions={DAE.FUNCTION_EXT(
                externalDecl=DAE.EXTERNALDECL(ident=cFuncStr))}),
            destructor=DAE.FUNCTION(
              functions={DAE.FUNCTION_EXT(
                externalDecl=DAE.EXTERNALDECL(ident=dFuncStr))})) :: _)
      equation
        true = ModUtil.pathEqual(path1, path2);
      then ({(name, cFuncStr, args)}, {(dFuncStr, name)}, {});
    // try next class
    case (var, (_ :: eclasses))
      equation
        (constructors, destructors, aliases) = createExtObjInfoSingle(var, eclasses);
      then (constructors, destructors, aliases);
  end matchcontinue;
end createExtObjInfoSingle;

protected function createAlgorithmAndEquationAsserts
  input DAELow.DAELow dlow;
  output list<Algorithm.Statement> algorithmAndEquationAsserts;
algorithm
  algorithmAndEquationAsserts :=
  matchcontinue (dlow)
    case(DAELow.DAELOW(algorithms=algs))
      local
        Algorithm.Algorithm[:] algs;
        list<Algorithm.Statement> res;
      equation
        res = createAlgorithmAndEquationAssertsFromAlgs(arrayList(algs));
      then res;
  end matchcontinue;
end createAlgorithmAndEquationAsserts;

protected function createAlgorithmAndEquationAssertsFromAlgs
  input list<Algorithm.Algorithm> algs;
  output list<Algorithm.Statement> algorithmAndEquationAsserts;
algorithm
  algorithmAndEquationAsserts :=
  matchcontinue (algs)
    local
      Algorithm.Statement stmt;
      list<Algorithm.Statement> restStmt;
      list<Algorithm.Algorithm> restAlgs;
    case ({})
      then ({});
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
  input DAELow.DAELow dlow;
  output list<SimEqSystem> removedEquations;
algorithm
  removedEquations :=
  matchcontinue (dlow)
    local
      DAELow.EquationArray r;
      list<DAELow.Equation> removedEquationsTmp;
    case (DAELow.DAELOW(removedEqs=r))
      equation
        removedEquationsTmp = DAELow.equationList(r);

        removedEquations = Util.listMap(removedEquationsTmp,
                                        dlowEqToSimEqSystem);
      then removedEquations;
  end matchcontinue;
end createRemovedEquations;

protected function extractDiscreteModelVars
  input DAELow.DAELow dlow;
  input DAELow.IncidenceMatrixT mT;
  output list<DAE.ComponentRef> discreteModelVars;
algorithm
  discreteModelVars :=
  matchcontinue (dlow, mT)
    local
      DAELow.Variables v;
      list<DAELow.Var> vLst;
      list<DAE.ComponentRef> vLst2;
    case (DAELow.DAELOW(orderedVars=v), mT)
      equation
        vLst = DAELow.varList(v);
        // select all discrete vars.
        vLst = Util.listSelect(vLst, DAELow.isVarDiscrete);
        // remove those vars that are solved in when equations
        //vLst = Util.listSelect2(vLst, dlow, mT, varNotSolvedInWhen);
        // replace var with cref
        vLst2 = Util.listMap(vLst, DAELow.varCref);
      then vLst2;
  end matchcontinue;
end extractDiscreteModelVars;

protected function varNotSolvedInWhen
  input DAELow.Var var;
  input DAELow.DAELow dlow;
  input DAELow.IncidenceMatrixT mT;
  output Boolean include;
algorithm
  include :=
  matchcontinue(var, dlow, mT)
    local
      Exp.ComponentRef cr;
      Integer varIndx;
      list<Integer> eqns;
    case(var as DAELow.VAR(varName=cr, index=varIndx), dlow, mT)
      equation
        eqns = mT[varIndx + 1];
        true = crefNotInWhenEquation(cr, dlow, eqns);
      then true;
    case(_,_,_)
      then false;
  end matchcontinue;
end varNotSolvedInWhen;

protected function createSimWhenClauses
  input DAELow.DAELow dlow;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimWhenClause> simWhenClauses;
algorithm
  simWhenClauses :=
  matchcontinue (dlow,helpVarInfo)
    local
      list<DAELow.WhenClause> wc;
    case (DAELow.DAELOW(eventInfo=DAELow.EVENT_INFO(whenClauseLst=wc)),helpVarInfo)
      equation
        simWhenClauses = createSimWhenClausesWithEqs(wc, wc, helpVarInfo, dlow, 0);
      then
        simWhenClauses;
  end matchcontinue;
end createSimWhenClauses;

protected function createSimWhenClausesWithEqs
  input list<DAELow.WhenClause> whenClauses;
  input list<DAELow.WhenClause> allwhenClauses;
  input list<HelpVarInfo> helpVarInfo;
  input DAELow.DAELow dlow;
  input Integer currentWhenClauseIndex;
  output list<SimWhenClause> simWhenClauses;
algorithm
  simWhenClauses :=
  matchcontinue (whenClauses, allwhenClauses, helpVarInfo, dlow, currentWhenClauseIndex)
    local
      DAELow.WhenClause whenClause;
      list<DAELow.WhenClause> wc,wc1;
      DAELow.EquationArray eqs;
      list<DAELow.Equation> eqsLst;
      Option<DAELow.WhenEquation> whenEq;
      SimWhenClause simWhenClause;
      Integer nextIndex;
      list<SimWhenClause> simWhenClauses;
    case ({}, _, _, _, _)
      then {};
    case (whenClause :: wc, wc1, helpVarInfo, DAELow.DAELOW(orderedEqs=eqs), currentWhenClauseIndex)
      equation
        eqsLst = DAELow.equationList(eqs);
        whenEq = findWhenEquation(eqsLst, currentWhenClauseIndex);
        simWhenClause = whenClauseToSimWhenClause(whenClause, whenEq, wc1, helpVarInfo, currentWhenClauseIndex);
        nextIndex = currentWhenClauseIndex + 1;
        simWhenClauses = createSimWhenClausesWithEqs(wc, wc1, helpVarInfo, dlow, nextIndex);
      then simWhenClause :: simWhenClauses;
  end matchcontinue;
end createSimWhenClausesWithEqs;

protected function findWhenEquation
  input list<DAELow.Equation> eqs;
  input Integer index;
  output Option<DAELow.WhenEquation> whenEq;
algorithm
  whenEq :=
  matchcontinue (eqs, index)
    local
      DAELow.WhenEquation eq,eq1;
      list<DAELow.Equation> restEqs;
      Integer eqindex;
    case ((DAELow.WHEN_EQUATION(whenEquation = eq)) :: restEqs, index)
      equation
        eq1 = findWhenEquation1(eq,index);
      then SOME(eq1);
    case (_ :: restEqs, index)
      equation
        whenEq = findWhenEquation(restEqs, index);
      then whenEq;
    case ({}, _)
      then NONE();
  end matchcontinue;
end findWhenEquation;

protected function findWhenEquation1
"function: findWhenEquation1
  Helper function to findWhenEquation."
  input DAELow.WhenEquation inWEqn;
  input Integer inInteger;
  output DAELow.WhenEquation outWEqn;
algorithm
  outWEqn := matchcontinue (inWEqn,inInteger)
    local
      Integer wc_ind,index;
      DAELow.WhenEquation weqn,we,we1;
               
    case(weqn as DAELow.WHEN_EQ(index = wc_ind,elsewhenPart = NONE()),index)
      equation
        (index == wc_ind) = true;
      then
        weqn;  
    case(weqn as DAELow.WHEN_EQ(index = wc_ind,elsewhenPart = SOME(we)),index)
      equation
        (index == wc_ind) = true;
      then
        weqn;              
    case(weqn as DAELow.WHEN_EQ(index = wc_ind,elsewhenPart = SOME(we)),index)
      equation
        we1 = findWhenEquation1(we,index);
      then
        we1;              
  end matchcontinue;
end findWhenEquation1;

protected function whenClauseToSimWhenClause
  input DAELow.WhenClause whenClause;
  input Option<DAELow.WhenEquation> whenEq;
  input list<DAELow.WhenClause> whenClauses;
  input list<HelpVarInfo> helpVarInfo;
  input Integer CurrentIndex;
  output SimWhenClause simWhenClause;
algorithm
  simWhenClause :=
  matchcontinue (whenClause, whenEq, whenClauses,helpVarInfo,CurrentIndex)
    local
      DAE.Exp cond;
      input list<DAELow.WhenClause> wc;
      list<DAELow.ReinitStatement> reinits;
      list<DAE.ComponentRef> conditionVars;
      Integer index_;
      list<Exp.Exp> conditions;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
    case (DAELow.WHEN_CLAUSE(condition=cond, reinitStmtLst=reinits), whenEq, wc, helpVarInfo,CurrentIndex)
      equation
        conditions = getConditionList(wc, CurrentIndex);
        conditionsWithHindex = Util.listMap1(conditions, addHindexForCondition, helpVarInfo);
        conditionVars = Exp.getCrefFromExp(cond);
      then
        SIM_WHEN_CLAUSE(conditionVars, reinits, whenEq, conditionsWithHindex);    
  end matchcontinue;
end whenClauseToSimWhenClause;

protected function createEquations
  input Boolean includeWhen;
  input Boolean skipDiscInZc;
  input Boolean genDiscrete;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<list<Integer>> comps;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> equations;
algorithm
  equations :=
  matchcontinue (includeWhen, skipDiscInZc, genDiscrete, dlow, ass1, ass2, comps, helpVarInfo)
    local
      list<Integer> comp;
      list<list<Integer>> restComps;
      list<DAELow.Equation> equations_2;
      SimEqSystem equation_;
      Integer index;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      DAELow.Var v;
      list<Integer> zcEqns;
    case (includeWhen, skipDiscInZc, genDiscrete, dlow, ass1, ass2, {}, helpVarInfo)
      then {};
    /* ignore when equations if we should not generate them */
    case (false, skipDiscInZc, genDiscrete, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.WHEN_EQUATION(_,_),_) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        equations = createEquations(false, skipDiscInZc, genDiscrete, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equations;
    /* ignore discrete if we should not generate them */
    case (includeWhen, skipDiscInZc, false, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.EQUATION(_,_,_),v) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        true = hasDiscreteVar({v});
        equations = createEquations(includeWhen, skipDiscInZc, false, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equations;
    /* ignore discrete in zero crossing if we should not generate them */
    case (includeWhen, true, genDiscrete, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.EQUATION(_,_,_),v) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        true = hasDiscreteVar({v});
        zcEqns = DAELow.zeroCrossingsEquations(dlow);
        true = listMember(index, zcEqns);
        equations = createEquations(includeWhen, true, genDiscrete, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equations;
    /* single equation */
    case (includeWhen, skipDiscInZc, genDiscrete, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        equation_ = createEquation(index, dlow, ass1, ass2, helpVarInfo);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equation_ :: equations;
    /* multiple equations that must be solved together (algebraic loop) */
    case (includeWhen, skipDiscInZc, genDiscrete, dlow, ass1, ass2, (comp as (_ :: (_ :: _))) :: restComps, helpVarInfo)
      local
        list<SimEqSystem> equations_,equations1;
      equation
        equations_ = createOdeSystem(genDiscrete, dlow, ass1, ass2, comp, helpVarInfo);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete, dlow, ass1, ass2, restComps, helpVarInfo);
        equations1 = listAppend(equations_,equations); 
      then
        equations1;
    case (_,_,_,_,_,_,{index} :: restComps,_)
      equation
        Debug.fprintln("failtrace"," Failed to create Equation with:" +& intString(index));
        Error.addMessage(Error.INTERNAL_ERROR, {"createEquations failed"});
      then
        fail();
    case (_,_,_,_,_,_,(comp as (_ :: (_ :: _))) :: restComps,_)
      local
        list<String> str;
      equation
        str = Util.listMap(comp,intString);
        Debug.fprintln("failtrace"," Failed to create Equation with:" +& System.stringAppendList(str));
        Error.addMessage(Error.INTERNAL_ERROR, {"createEquations failed"});
      then
        fail();        
  end matchcontinue;
end createEquations;

protected function createEquation
  input Integer eqNum;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<HelpVarInfo> helpVarInfo;
  output SimEqSystem equation_;
algorithm
  equation_ :=
  matchcontinue (eqNum, dlow, ass1, ass2, helpVarInfo)
    local
      list<Integer> restEqNums;
      list<DAELow.Equation> eqnsList;
      Exp.ComponentRef cr,origname, cr_1;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAELow.VarKind kind;
      DAELow.Var v;
      Exp.Exp e1;
      Exp.Exp e2;
      Exp.Exp varexp;
      Exp.Exp exp_;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      DAELow.Equation eqn;
      String varname;
      String name;
      String c_name;
      String id;
      Integer indx;
      Integer e_1;
      Integer e;
      Integer index;
      Algorithm.Algorithm alg;
      Algorithm.Algorithm[:] algs;
      list<DAE.Statement> algStatements;
      list<DAE.Exp> inputs,outputs;
      DAELow.VariableArray vararr;
      DAELow.MultiDimEquation[:] ae;
      VarTransform.VariableReplacements repl;
      list<SimEqSystem> resEqs;
      list<DAELow.WhenClause> wcl;
      Integer wcIndex;
      DAE.ComponentRef left;
      DAE.Exp right;
      list<DAE.Exp> conditions;
      list<tuple<DAE.Exp, Integer>> conditionsWithHindex;
      DAELow.WhenEquation whenEquation;
    /* when eq */
    case (eqNum,
          DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns, eventInfo=DAELow.EVENT_INFO(whenClauseLst=wcl)),
          ass1, ass2, helpVarInfo)
      equation
        (DAELow.WHEN_EQUATION(whenEquation,_),_) = getEquationAndSolvedVar(eqNum, eqns, vars, ass2);
        DAELow.WHEN_EQ(wcIndex, left, right, _) = whenEquation;
        conditions = getConditionList(wcl, wcIndex);
        conditionsWithHindex = Util.listMap1(conditions, addHindexForCondition, helpVarInfo);
      then
        SES_WHEN(left, right, conditionsWithHindex);
    /* single equation: non-state */
    case (eqNum,
          DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns),
          ass1, ass2, helpVarInfo)
      equation
        (DAELow.EQUATION(e1, e2,_), v as DAELow.VAR(varName = cr, varKind = kind))
          = getEquationAndSolvedVar(eqNum, eqns, vars, ass2);
        isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        exp_ = solve(e1, e2, varexp);
      then
        SES_SIMPLE_ASSIGN(cr, exp_);
    /* single equation: state */
    case (eqNum,
          DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns),
          ass1, ass2, helpVarInfo)
      equation
        (DAELow.EQUATION(e1, e2,_), v as DAELow.VAR(varName = cr, varKind = DAELow.STATE()))
          = getEquationAndSolvedVar(eqNum, eqns, vars, ass2);
        cr = DAELow.makeDerCref(cr);
        exp_ = solve(e1, e2, DAE.CREF(cr,DAE.ET_REAL()));
      then
        SES_SIMPLE_ASSIGN(cr, exp_);
    /* non-state non-linear */
    case (e,
          DAELow.DAELOW(orderedVars=vars,orderedEqs=eqns,arrayEqs=ae),
          ass1, ass2, helpVarInfo)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(varName = cr, varKind = kind)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = solve(e1, e2, varexp));
        index = tick();
        index = eqNum; // Use the equation number as unique index
        (resEqs,_) = createNonlinearResidualEquations({eqn}, ae, {});
      then
        SES_NONLINEAR(index, resEqs, {cr});
    /* state nonlinear */
    case (e,
          DAELow.DAELOW(orderedVars=vars,orderedEqs=eqns,arrayEqs=ae),
          ass1, ass2, helpVarInfo)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(varName = cr, varKind = DAELow.STATE())) =
          getEquationAndSolvedVar(e, eqns, vars, ass2);
        cr_1 = DAELow.crefPrefixDer(cr);
        varexp = DAE.CREF(cr_1, DAE.ET_REAL());
        failure(_ = solve(e1, e2, varexp));
        index = tick();
        index = eqNum; // Use the equation number as unique index
        (resEqs,_) = createNonlinearResidualEquations({eqn}, ae, {});
      then
        SES_NONLINEAR(index, resEqs, {cr_1});

    /* Algorithm for single variable. */
    case (e, DAELow.DAELOW(orderedVars=vars,orderedEqs=eqns,algorithms=alg), ass1, ass2, helpVarInfo)
      local
        Integer indx;
        list<DAE.Exp> algInputs,algOutputs;
        DAELow.Var v;
        DAE.ComponentRef varOutput;
        DAE.ElementSource source "the origin of the element";
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        true = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        DAE.ALGORITHM_STMTS(algStatements) = DAELow.collateAlgorithm(alg, NONE());
      then
        SES_ALGORITHM(algStatements);

    /* inverse Algorithm for single variable . */
    case (e, DAELow.DAELOW(orderedVars = vars, orderedEqs = eqns,algorithms=alg),ass1,ass2, helpVarInfo)
      local
        Integer indx;
        list<DAE.Exp> algInputs,algOutputs;
        DAELow.Var v;
        DAE.ComponentRef varOutput;
        String algStr,message;
        DAE.ElementSource source "the origin of the element";
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
				// We need to solve an inverse problem of an algorithm section.
        false = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        algStr =	DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = System.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();
  end matchcontinue;
end createEquation;

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
    case (_, {})
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Could not find help var index for condition"});
      then fail();
    case (condition, (hindex, e, _) :: restHelpVarInfo)
      equation
        true = Exp.expEqual(condition, e);
      then ((condition, hindex));
    case (condition, (hindex, e, _) :: restHelpVarInfo)
      equation
        false = Exp.expEqual(condition, e);
        conditionAndHindex = addHindexForCondition(condition, restHelpVarInfo);
      then conditionAndHindex;
  end matchcontinue;
end addHindexForCondition;

protected function createNonlinearResidualEquations
  input list<DAELow.Equation> eqs;
  input DAELow.MultiDimEquation[:] arrayEqs;
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output list<SimEqSystem> eqSystems;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (eqSystems,outEntrylst) :=
  matchcontinue (eqs, arrayEqs,inEntrylst)
    local
      Integer cg_id,cg_id_1,indx_1,cg_id_2,indx,aindx;
      DAE.ExpType tp;
      DAE.Exp res_exp,res_exp,e1,e2,e;
      String var,indx_str,stmt;
      list<DAELow.Equation> rest,rest2;
      DAELow.MultiDimEquation[:] aeqns;
      VarTransform.VariableReplacements repl;
      DAELow.Equation eq;
      list<SimEqSystem> eqSystemsRest;
      list<Integer> ds;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1,entrylst2;
      DAE.ComponentRef left;      
    case ({}, _, inEntrylst) then ({},inEntrylst);
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest), aeqns, inEntrylst)
      equation
        tp = Exp.typeof(e1);
        res_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        res_exp = Exp.simplify(res_exp);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,entrylst1) = createNonlinearResidualEquations(rest, aeqns, inEntrylst);
      then
        (SES_RESIDUAL(res_exp) :: eqSystemsRest,entrylst1);
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: rest), aeqns, inEntrylst)
      equation
        res_exp = Exp.simplify(e);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,entrylst1) = createNonlinearResidualEquations(rest, aeqns, inEntrylst);
      then
        (SES_RESIDUAL(res_exp) :: eqSystemsRest,entrylst1);
    /* An array equation */
    case ((DAELow.ARRAY_EQUATION(index=aindx) :: rest), aeqns, inEntrylst)
      equation
        DAELow.MULTIDIM_EQUATION(dimSize=ds,left=e1, right=e2) = aeqns[aindx+1];
        tp = Exp.typeof(e1);
        res_exp = DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = DAELow.getArrayEquationSub(aindx,ad,inEntrylst);
        res_exp = Exp.applyExpSubscripts(res_exp,subs);        
        res_exp = Exp.simplify(res_exp);
        res_exp = replaceDerOpInExp(res_exp);        
        (eqSystemsRest,entrylst2) = createNonlinearResidualEquations(rest, aeqns, entrylst1);
      then 
        (SES_RESIDUAL(res_exp) :: eqSystemsRest,entrylst2);
        
    case ((eq as DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(left = left, right = e2)))::rest,aeqns,inEntrylst)
      equation
        // This following does not work. It does not take index or elseWhen into account.
        // The generated code for the when-equation also does not solve a linear system; it uses the variables directly.
        /*
        tp = Exp.typeof(e2);
        e1 = DAE.CREF(left,tp);
        res_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        res_exp = Exp.simplify(res_exp);
        res_exp = replaceDerOpInExp(res_exp);
        (eqSystemsRest,entrylst1) = createNonlinearResidualEquations(rest, aeqns, inEntrylst);
      then
        (SES_RESIDUAL(res_exp) :: eqSystemsRest,entrylst1);
        */
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"non-linear equations within when-equations","Perform non-linear operations outside the when-equation (this is slower, but works)"},DAELow.equationInfo(eq));
      then
        fail();
        
    case (eq::_,_,_)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"SimCode.createNonlinearResidualEquations failed"},DAELow.equationInfo(eq));
      then
        fail();    
  end matchcontinue;
end createNonlinearResidualEquations;

protected function applyResidualReplacements
  "Replaces variables in nonlinear equation systems with xloc[index] variables."
  input list<SimEqSystem> inEqs;
  output list<SimEqSystem> outEqs;
algorithm
  outEqs := matchcontinue(inEqs)
    local
      SimEqSystem eq;
      list<SimEqSystem> rest_eqs;
    case ({}) then {};
    case (SES_NONLINEAR(index = index, eqs = eqs, crefs = crefs) :: rest_eqs)
      local
        Integer index;
        list<SimEqSystem> eqs;
        list<DAE.ComponentRef> crefs;
        VarTransform.VariableReplacements repl;
      equation
        repl = makeResidualReplacements(crefs);
        eqs = Util.listMap1(eqs, applyResidualReplacementsEqn, repl);
        rest_eqs = applyResidualReplacements(rest_eqs);
      then
        SES_NONLINEAR(index, eqs, crefs) :: rest_eqs;
    case (eq :: rest_eqs)
      equation
        rest_eqs = applyResidualReplacements(rest_eqs);
      then
        eq :: rest_eqs;
  end matchcontinue;
end applyResidualReplacements;

protected function applyResidualReplacementsEqn
  "Helper function to applyResidualReplacements. Replaces variables in an
    residual equation system."
  input SimEqSystem inEqn;
  input VarTransform.VariableReplacements repl;
  output SimEqSystem outEqn;
algorithm
  outEqn := matchcontinue(inEqn, repl)
    case (SES_RESIDUAL(res_exp), _)
      local
        DAE.Exp res_exp;
      equation
        res_exp = VarTransform.replaceExp(res_exp, repl, SOME(skipPreOperator));
      then
        SES_RESIDUAL(res_exp);
    case (_, _) then inEqn;
  end matchcontinue;
end applyResidualReplacementsEqn;

protected function createOdeSystem
  input Boolean genDiscrete "if true generate discrete equations";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> equations_;
algorithm
  equations_ :=
  matchcontinue (genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLst4,helpVarInfo)
    local
      String rettp,fn;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,var_lst_1,cont_var1;
      DAELow.Variables vars_1,vars,knvars,exvars;
      DAELow.AliasVariables av;
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,daelow,subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      String s;
      DAELow.MultiDimEquation[:] ae,ae1;
      list<DAELow.MultiDimEquation> mdelst;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      DAELow.ExternalObjectClasses eoc;
      list<String> retrec,arg,locvars,init,locvars,stmts,cleanups,stmts_1,stmts_2;
      Integer numValues;
      list<SimVar> simVarsDisc;
      list<SimEqSystem> discEqs;
      list<String> values;
      list<Integer> value_dims;
      SimEqSystem equation_;
    /* mixed system of equations, continuous part only */
    case (false,(daelow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_,helpVarInfo)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        true = isMixedSystem(var_lst,eqn_lst);
        mdelst = Util.listMap(arrayList(ae),replaceDerOpMultiDimEquations);
        ae1 = listArray(mdelst);        
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
        // States are solved for der(x) not x.
        cont_var1 = Util.listMap(cont_var, transformXToXd);
        vars_1 = DAELow.listVar(cont_var1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);        
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae1,al,ev,eoc);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae1, m_1, mt_1,true);
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        equations_ = createOdeSystem2(false, false, cont_subsystem_dae, jac, jac_tp, block_,helpVarInfo);
      then
        equations_;
    /* mixed system of equations, both continous and discrete eqns*/
    case (true,(dlow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_,helpVarInfo)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        true = isMixedSystem(var_lst,eqn_lst);
        mdelst = Util.listMap(arrayList(ae),replaceDerOpMultiDimEquations);
        ae1 = listArray(mdelst);        
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
        // States are solved for der(x) not x.
        cont_var1 = Util.listMap(cont_var, transformXToXd);
        vars_1 = DAELow.listVar(cont_var1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);        
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae1,al,ev,eoc);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations.
        // Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae1, m_1, mt_1,true);
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        {equation_} = createOdeSystem2(true, true, cont_subsystem_dae, jac, jac_tp, block_,helpVarInfo);
        simVarsDisc = Util.listMap(disc_var, dlowvarToSimvar);
        discEqs = extractDiscEqs(disc_eqn, disc_var);
        (values, value_dims) = extractValuesAndDims(cont_eqn, cont_var, disc_eqn, disc_var);
      then
        {SES_MIXED(equation_, simVarsDisc, discEqs, values, value_dims)};
        /* continuous system of equations try tearing algorithm*/
    case (genDiscrete,(daelow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,block_,helpVarInfo)
      local
        DAELow.DAELow subsystem_dae_1,subsystem_dae_2;
        Integer[:] v1,v2,v1_1,v2_1;
        DAELow.IncidenceMatrix m_2,m_3;
        DAELow.IncidenceMatrixT mT_2,mT_3;
        list<list<Integer>> comps,comps_1;
        list<Integer> comps_flat;
        list<list<Integer>> r,t;
        list<Integer> rf,tf;
      equation
        // check tearing
        true = RTOpts.debugFlag("tearing");
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2) "extract the variables and equations of the block." ;
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        mdelst = Util.listMap(arrayList(ae),replaceDerOpMultiDimEquations);
        ae1 = listArray(mdelst);        
        var_lst_1 = Util.listMap(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(var_lst_1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);        
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae1,al,ev,eoc) "not used" ;
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        (v1,v2,subsystem_dae_1,m_2,mT_2) = DAELow.matchingAlgorithm(subsystem_dae, m_1, mt_1, (DAELow.NO_INDEX_REDUCTION(), DAELow.EXACT(), DAELow.KEEP_SIMPLE_EQN()),DAEUtil.avlTreeNew());
        (comps) = DAELow.strongComponents(m_2, mT_2, v1,v2);
        (subsystem_dae_2,m_3,mT_3,v1_1,v2_1,comps_1,r,t) = DAELow.tearingSystem(subsystem_dae_1,m_2,mT_2,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae1, m_3, mT_3,false) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac);
        equation_ = generateTearingSystem(v1_1,v2_1,comps_flat,rf,tf,false,genDiscrete,subsystem_dae_2, jac, jac_tp, helpVarInfo);
      then
        {equation_};
    /* continuous system of equations */
    case (genDiscrete,(daelow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,block_,helpVarInfo)
      equation
        // extract the variables and equations of the block.
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        mdelst = Util.listMap(arrayList(ae),replaceDerOpMultiDimEquations);
        ae1 = listArray(mdelst);        
        // States are solved for der(x) not x.
        var_lst_1 = Util.listMap(var_lst, transformXToXd);
        vars_1 = DAELow.listVar(var_lst_1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae1,al,ev,eoc);
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae1, m_1, mt_1,false);
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac);
        equations_ = createOdeSystem2(false, genDiscrete, subsystem_dae, jac, jac_tp, block_,helpVarInfo);
      then
        equations_;
    case (_,_,_,_,_,_)
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
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input list<Integer> inIntegerLst5;
  input list<Integer> inIntegerLst6;
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input DAELow.JacobianType inJacobianType;
  input list<HelpVarInfo> helpVarInfo;
  output SimEqSystem equation_;
algorithm
  equation_:=
  matchcontinue (inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,mixedEvent,genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inJacobianType,helpVarInfo)
    local
      Integer[:] ass1,ass2;
      list<Integer> block_,block_1,r,t;
      Integer index;
      DAELow.DAELow daelow,daelow1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      DAELow.Variables v,kv,exv;
      DAELow.AliasVariables av;
      DAELow.EquationArray eqn,eqn1,reeqn,ineq;
      list<DAELow.Equation> eqn_lst,eqn_lst1,eqn_lst2,reqns;
      list<DAELow.Var> var_lst;
      list<DAE.ComponentRef> crefs,crefs1,tcrs;
      DAELow.MultiDimEquation[:] ae;
      Boolean genDiscrete;
      String str_id,size_str,func_name,start_stmt,end_stmt;
      VarTransform.VariableReplacements repl;
      DAE.Algorithm[:] algorithms;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
      list<SimEqSystem> simeqnsystem,simeqnsystem1,resEqs;
    case (ass1,ass2,block_,r,t,mixedEvent,_,
          daelow as DAELow.DAELOW(orderedVars=v,knownVars=kv,externalObjects=exv,aliasVars=av,orderedEqs=eqn,removedEqs=reeqn,initialEqs=ineq,arrayEqs=ae,algorithms=algorithms,eventInfo=eventInfo,extObjClasses=extObjClasses),jac,jac_tp,helpVarInfo)
           /* no analythic jacobian available. Generate non-linear system */
      equation
        // get equations and variables
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        // get names from variables
        crefs = Util.listMap(var_lst, DAELow.varCref);
        // get Tearingvar from crs
        // to use listNth cref and eqn_lst have to start at 1 and not at 0 -> right shift
        crefs1 = Util.listAddElementFirst(DAE.CREF_IDENT("shift",DAE.ET_REAL(),{}),crefs);
        eqn_lst1 = Util.listAddElementFirst(DAELow.EQUATION(DAE.RCONST(0.0),DAE.RCONST(0.0),DAE.emptyElementSource),eqn_lst);
        tcrs = Util.listMap1r(t,listNth,crefs1);
        repl = makeResidualReplacements(tcrs);
        // get residual eqns and other eqns
        reqns = Util.listMap1r(r,listNth,eqn_lst1);
        // remove residual equation from list of other equtions
        block_1 = Util.listSelect1(block_,r,Util.listNotContains);
        // replace tearing variables in other equations with x_loc[..]
        eqn_lst2 = generateTearingSystem1(eqn_lst,repl);
        eqn1 = DAELow.listEquation(eqn_lst2);
        daelow1=DAELow.DAELOW(v,kv,exv,av,eqn1,reeqn,ineq,ae,algorithms,eventInfo,extObjClasses);
        // generade code for other equations
        simeqnsystem = Util.listMap4(block_1,createEquation,daelow1, ass1, ass2, helpVarInfo);
        (resEqs,_) = createNonlinearResidualEquations(reqns, ae, {});
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

protected function generateTearingSystem1
 "function: generateTearingSystem1
  author: Frenkel TUD
  Helper function to generateTearingSystem1"
  input list<DAELow.Equation> inDAELowEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst := matchcontinue (inDAELowEquationLst,inVariableReplacements)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      list<DAELow.Equation> rest,rest2;
      DAELow.MultiDimEquation[:] aeqns;
      VarTransform.VariableReplacements repl;
      DAE.ElementSource source;
    case ({},_) then {};
    case ((DAELow.EQUATION(exp = e1,scalar = e2,source = source) :: rest),repl)
      equation
        rest2 = generateTearingSystem1(rest,repl);
        e1_1 = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
        e2_1 = VarTransform.replaceExp(e2, repl, SOME(skipPreOperator));
      then
        DAELow.EQUATION(e1_1,e2_1,source) :: rest2;
    case ((DAELow.RESIDUAL_EQUATION(exp = e1,source = source) :: rest),repl)
      equation
        rest2 = generateTearingSystem1(rest,repl);
        e1_1 = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
      then
        DAELow.RESIDUAL_EQUATION(e1_1,source) :: rest2;
  end matchcontinue;
end generateTearingSystem1;

protected function extractDiscEqs
  input list<DAELow.Equation> disc_eqn;
  input list<DAELow.Var> disc_var;
  output list<SimEqSystem> discEqsOut;
algorithm
  discEqsOut :=
  matchcontinue (disc_eqn, disc_var)
    local
      list<SimEqSystem> restEqs;
      Integer cg_id,indx_1,cg_id_1,cg_id_2,indx;
      DAE.ComponentRef cr;
      DAE.Exp varexp,expr,e1,e2;
      String var,indx_str,cr_str,stmt,stmt2;
      list<DAELow.Equation> eqns;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ({},_) then {};
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: eqns),(v :: vs))
      equation
        cr = DAELow.varCref(v);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = solve(e1, e2, varexp);
        restEqs = extractDiscEqs(eqns, vs);
      then
        SES_SIMPLE_ASSIGN(cr, expr) :: restEqs;
  end matchcontinue;
end extractDiscEqs;

protected function extractValuesAndDims
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input list<DAELow.Equation> inDAELowEquationLst3;
  input list<DAELow.Var> inDAELowVarLst4;
  output list<String> valuesRet;
  output list<Integer> value_dims;
algorithm
  (valuesRet, value_dims) :=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inDAELowEquationLst3,inDAELowVarLst4)
    local
      list<DAE.Exp> rels;
      list<list<String>> values,values_1;
      list<Integer> value_dims;
      list<String> values_2,ss;
      String s,s2,disc_len_str,values_len_str,stmt1,stmt2;
      Integer disc_len,values_len;
      list<DAELow.Equation> cont_e,disc_e;
      list<DAELow.Var> cont_v,disc_v;
    case (cont_e,cont_v,disc_e,disc_v)
      equation
        rels = mixedCollectRelations(cont_e, disc_e);
        (values,value_dims) = generateMixedDiscretePossibleValues2(rels, disc_v, 0);
        values_1 = generateMixedDiscreteCombinationValues(values);
        values_2 = Util.listFlatten(values_1);
        valuesRet = values_2;
      then
        (valuesRet, value_dims);
  end matchcontinue;
end extractValuesAndDims;

protected function createOdeSystem2
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input DAELow.JacobianType inJacobianType;
  input list<Integer> block_;
  input list<HelpVarInfo> helpVarInfo; 
  output list<SimEqSystem> equations_;
algorithm
  equations_ :=
  matchcontinue
    (mixedEvent,genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inJacobianType,block_,helpVarInfo)
    local
      Integer cg_id_1,cg_id,eqn_size,unique_id,cg_id1,cg_id2,cg_id3,cg_id4,cg_id5;
      DAELow.DAELow dae,d;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      DAELow.Variables v,kv;
      DAELow.EquationArray eqn;
      list<DAELow.Equation> eqn_lst;
      list<DAELow.Var> var_lst;
      list<DAE.ComponentRef> crefs;
      DAELow.MultiDimEquation[:] ae;
      Boolean genDiscrete;
      VarTransform.VariableReplacements repl;
      list<SimEqSystem> resEqs;
      list<String> blockIdStrLst;
      String blockIdStr;
      SimEqSystem equation_;

    /* A single array equation */
    case (mixedEvent,genDiscrete,dae,jac,jac_tp,block_,helpVarInfo)
      equation
        singleArrayEquation(dae); // fails if not single array eq
        equations_ = createSingleArrayEqnCode(mixedEvent,genDiscrete,dae,jac,jac_tp,block_,helpVarInfo);
      then
        equations_;
    /* A single algorithm section for several variables. */
    case (mixedEvent,genDiscrete,dae,jac,jac_tp,block_,helpVarInfo)
      equation
        singleAlgorithmSection(dae);
        equation_ = createSingleAlgorithmCode(dae, jac);
      then
        {equation_};
    /* constant jacobians. Linear system of equations (A x = b) where
       A and b are constants. TODO: implement symbolic gaussian elimination
       here. Currently uses dgesv as for next case */
    case (mixedEvent,genDiscrete,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_CONSTANT(),block_,helpVarInfo)
      local
        list<tuple<Integer, Integer, DAELow.Equation>> jac;
      equation
        eqn_size = DAELow.equationSize(eqn);
        // NOTE: Not impl. yet, use time_varying...
        equations_ = createOdeSystem2(mixedEvent, genDiscrete, d, SOME(jac),
                                     DAELow.JAC_TIME_VARYING(), block_,helpVarInfo);
      then
        equations_;

    /* constant jacobians. Linear system of equations (A x = b) where
       A and b are constants. TODO: implement symbolic gaussian elimination
       here. Currently uses dgesv as for next case */
    case (mixedEvent,genDiscrete,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_TIME_VARYING(),block_,helpVarInfo)
      local
        list<tuple<Integer, Integer, DAELow.Equation>> jac;
        DAELow.DAELow subsystem_dae_1,subsystem_dae_2;
        Integer[:] v1,v2,v1_1,v2_1;
        DAELow.IncidenceMatrix m,m_1,m_2,m_3;
        DAELow.IncidenceMatrixT mt_1,mT_2,mT_3;
        list<list<Integer>> comps,comps_1;
        list<Integer> comps_flat;
        list<list<Integer>> r,t;
        list<Integer> rf,tf;        
      equation
        // check Relaxation
        true = RTOpts.debugFlag("relaxation");
        m = DAELow.incidenceMatrix(d);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        (v1,v2,subsystem_dae_1,m_2,mT_2) = DAELow.matchingAlgorithm(d, m_1, mt_1, (DAELow.NO_INDEX_REDUCTION(), DAELow.EXACT(), DAELow.KEEP_SIMPLE_EQN()),DAEUtil.avlTreeNew());
        (comps) = DAELow.strongComponents(m_2, mT_2, v1,v2);
        (subsystem_dae_2,m_3,mT_3,v1_1,v2_1,comps_1,r,t) = DAELow.tearingSystem(subsystem_dae_1,m_2,mT_2,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);        
        equations_ = generateRelaxationSystem(mixedEvent,m_3,mT_3,v1_1,v2_1,comps_flat,rf,tf,subsystem_dae_2,helpVarInfo);
      then
        equations_;
          
    /* Time varying jacobian. Linear system of equations that needs to
       be solved during runtime. */
    case (mixedEvent,_,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn, arrayEqs = arrayEqs)),SOME(jac),DAELow.JAC_TIME_VARYING(),block_,helpVarInfo)
      local
        list<DAELow.Var> dlowVars;
        list<SimVar> simVars;
        list<DAELow.Equation> dlowEqs;
        list<DAE.Exp> beqs;
        list<tuple<Integer, Integer, DAELow.Equation>> jac;
        list<tuple<Integer, Integer, SimEqSystem>> simJac;
        DAELow.MultiDimEquation[:] arrayEqs;
      equation
        dlowVars = DAELow.varList(v);
        simVars = Util.listMap(dlowVars, dlowvarToSimvar);
        dlowEqs = DAELow.equationList(eqn);
        (beqs,_) = listMap3passthrough(dlowEqs, dlowEqToExp, v, arrayEqs, {});
        simJac = Util.listMap1(jac, jacToSimjac, v);
      then
        {SES_LINEAR(mixedEvent, simVars, beqs, simJac)};
    /* Time varying nonlinear jacobian. Non-linear system of equations. */
    case (mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),SOME(jac),DAELow.JAC_NONLINEAR(),block_,helpVarInfo)
      local
        list<tuple<Integer, Integer, DAELow.Equation>> jac;
        Integer index;
      equation
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        crefs = Util.listMap(var_lst, DAELow.varCref);
        (resEqs,_) = createNonlinearResidualEquations(eqn_lst, ae, {});
        index = Util.listFirst(block_); // use first equation nr as index
      then
        {SES_NONLINEAR(index, resEqs, crefs)};
    /* No analythic jacobian available. Generate non-linear system. */
    case (mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),NONE,DAELow.JAC_NO_ANALYTIC(),block_,helpVarInfo)
      local
        list<tuple<Integer, Integer, DAELow.Equation>> jac;
        Integer index;
      equation
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        crefs = Util.listMap(var_lst, DAELow.varCref);
        (resEqs,_) = createNonlinearResidualEquations(eqn_lst, ae, {});
        index = Util.listFirst(block_); // use first equation nr as index
      then
        {SES_NONLINEAR(index, resEqs, crefs)};
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createOdeSystem2 failed"});
      then
        fail();
  end matchcontinue;
end createOdeSystem2;
     
protected function replaceDerOpInEquationList
  "Replaces all der(cref) with $DER.cref in a list of equations."
  input list<DAELow.Equation> inEqns;
  output list<DAELow.Equation> outEqns;
algorithm
  outEqns := Util.listMap(inEqns, replaceDerOpInEquation);
end replaceDerOpInEquationList;     
         
protected function replaceDerOpMultiDimEquations
"Replaces all der(cref) with $DER.cref in an multidimequation."
	input DAELow.MultiDimEquation inMultiDimEquation;
	output DAELow.MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue(inMultiDimEquation)
    local
      list<Integer> ilst;
      DAE.Exp e1,e1_1,e2,e2_1;
      DAE.ElementSource source;

    case(DAELow.MULTIDIM_EQUATION(ilst,e1,e2,source))
      equation
        e1_1 = replaceDerOpInExp(e1);
        e2_1 = replaceDerOpInExp(e2);
      then
        DAELow.MULTIDIM_EQUATION(ilst,e1_1,e2_1,source);
    case(inMultiDimEquation) then inMultiDimEquation; 
  end matchcontinue;
end replaceDerOpMultiDimEquations;

protected function replaceDerOpInEquation
  "Replaces all der(cref) with $DER.cref in an equation."
  input DAELow.Equation inEqn;
  output DAELow.Equation outEqn;
algorithm
  outEqn := matchcontinue(inEqn)
    case (DAELow.EQUATION(exp = e1, scalar = e2, source = src))
      local
        DAE.Exp e1, e2;
        DAE.ElementSource src;
      equation
        e1 = replaceDerOpInExp(e1);
        e2 = replaceDerOpInExp(e2);
      then
        DAELow.EQUATION(e1, e2, src);
    case (_) then inEqn;
  end matchcontinue;
end replaceDerOpInEquation;

protected function replaceDerOpInExp
  "Replaces all der(cref) with $DER.cref in an expression."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  ((outExp, _)) := Exp.traverseExp(inExp, replaceDerOpInExpTraverser, NONE());
end replaceDerOpInExp;

protected function replaceDerOpInExpCond
  "Replaces der(cref) with $DER.cref in an expression, where the cref to replace
  is explicitly given."
  input DAE.Exp inExp;
  input DAE.ComponentRef cref;
  output DAE.Exp outExp;
algorithm
  ((outExp, _)) := Exp.traverseExp(inExp, replaceDerOpInExpTraverser, SOME(cref));
end replaceDerOpInExpCond;

protected function replaceDerOpInExpTraverser
  "Used with Exp.traverseExp to traverse an expression an replace calls to
  der(cref) with a component reference $DER.cref. If an optional component
  reference is supplied, then only that component reference is replaced.
  Otherwise all calls to der are replaced.
  
  This is done since some parts of the compiler can't handle der-calls, such as
  Derive.differentiateExp. Ideally these parts should be fixed so that they can
  handle der-calls, but until that happens we just replace the der-calls with
  crefs."
  input tuple<Exp.Exp, Option<DAE.ComponentRef>> inExp;
  output tuple<Exp.Exp, Option<DAE.ComponentRef>> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.ComponentRef cr, der_cr;
      DAE.Exp cref_exp;
      DAE.ComponentRef cref; 
    case ((DAE.CALL(path = Absyn.IDENT("der"),
                    expLst = {DAE.CREF(componentRef = cr)}),
           SOME(cref)))
      equation
        der_cr = DAELow.crefPrefixDer(cr);
        true = Exp.crefEqualNoStringCompare(der_cr, cref);
        cref_exp = DAE.CREF(der_cr, DAE.ET_REAL());
      then
        ((cref_exp, SOME(cref)));
    case ((DAE.CALL(path = Absyn.IDENT("der"),
                    expLst = {DAE.CREF(componentRef = cr)}),
           NONE()))
      equation
        cr = DAELow.makeDerCref(cr);
      then
        ((DAE.CREF(cr,DAE.ET_REAL()), NONE()));
    case (_) then inExp;
  end matchcontinue;
end replaceDerOpInExpTraverser;

protected function generateRelaxationSystem "function: generateRelaxationSystem
  author: Frenkel TUD

  Generates the actual simulation code for the relaxed system of equation
"
  input Boolean mixedEvent "true if generating the mixed system event code";
  input DAELow.IncidenceMatrix inM;
  input DAELow.IncidenceMatrixT inMT;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input list<Integer> inIntegerLst5;
  input list<Integer> inIntegerLst6;
  input DAELow.DAELow inDAELow;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> outEqns;
algorithm
  outEqns:=
  matchcontinue (mixedEvent,inM,inMT,inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,inDAELow,helpVarInfo)
    local
      Integer[:] ass1,ass2,ass1_1,ass2_1;
      list<Integer> block_,block_1,block_2,r,t;
      Integer size;
      DAELow.DAELow daelow,daelow1;
      DAELow.Variables v,v1,kv,exv;
      DAELow.AliasVariables av;
      DAELow.EquationArray eqn,eqn1,reeqn,ineq;
      list<DAELow.Equation> eqn_lst,reqn_lst;
      list<DAELow.Var> var_lst,tvar_lst;
      list<DAE.ComponentRef> crefs;
      DAELow.MultiDimEquation[:] ae;
      VarTransform.VariableReplacements repl;
      DAE.Algorithm[:] algorithms;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
      DAELow.IncidenceMatrix m;
      DAELow.IncidenceMatrixT mT;
      list<SimEqSystem> eqns,reqns,alleqns;
      VarTransform.VariableReplacements repl,repl_1;
    case (mixedEvent,m,mT,ass1,ass2,block_,r,t,
          daelow as DAELow.DAELOW(orderedVars=v,knownVars=kv,externalObjects=exv,aliasVars=av,orderedEqs=eqn,removedEqs=reeqn,initialEqs=ineq,arrayEqs=ae,algorithms=algorithms,eventInfo=eventInfo,extObjClasses=extObjClasses),helpVarInfo) 
      equation
        // get equations and variables
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        // get non relaxation equations
        block_1 = Util.listSelect1(block_,r,Util.listNotContains);
        // get names from variables
        crefs = Util.listMap(var_lst, DAELow.varCref);
        // generade replacement from non residual eqns           
        repl = VarTransform.emptyReplacements();
        (repl_1,eqns) = getRelaxationReplacements(block_1,ass2,crefs,eqn_lst,repl);
        // replace non tearing vars in residual eqns
        (reqn_lst,tvar_lst) = getRelaxedResidualEqns(r,ass2,crefs,var_lst,eqn_lst,repl_1);
        eqn1 = DAELow.listEquation(reqn_lst);
        v1 = DAELow.listVar(tvar_lst);
        size = listLength(reqn_lst);
        block_2 = Util.listIntRange(size);
        ass1_1 = listArray(block_2);
        ass2_1 = listArray(block_2);        
        daelow1=DAELow.DAELOW(v1,kv,exv,av,eqn1,reeqn,ineq,ae,algorithms,eventInfo,extObjClasses);
        // generate code for relaxation equations
        reqns = generateRelaxedResidualEqns(block_2,mixedEvent,daelow1, ass1_1, ass2_1, helpVarInfo);
        alleqns = listAppend(reqns,eqns);
      then
        alleqns;
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generateRelaxationSystem failed \n");
      then
        fail();
  end matchcontinue;
end generateRelaxationSystem;

protected function getRelaxationReplacements"
Author: Frenkel TUD 2010-09 function getRelaxationReplacements
  solves all equations and add the solution to the replacement"
  input list<Integer> inBlock;
  input Integer[:] inAss2;
  input list<DAE.ComponentRef> inCrefs;
  input list<DAELow.Equation> inEqnLst;
  input VarTransform.VariableReplacements inRepl;
  output VarTransform.VariableReplacements outRepl;
  output list<SimEqSystem> outEqns;
algorithm
  (outRepl,outEqns) := matchcontinue (inBlock,inAss2,inCrefs,inEqnLst,inRepl)
    local
      Integer e,s;
      list<Integer> block_;
      Integer[:] ass2;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef c;
      list<DAELow.Equation> eqnLst;
      DAELow.Equation eqn;
      VarTransform.VariableReplacements repl,repl1,repl2;
      DAE.Exp exp,e1,e2,varexp,exps;
      list<SimEqSystem> seqns;
    case ({},ass2,crefs,eqnLst,repl) then (repl,{});
    case (e::block_,ass2,crefs,eqnLst,repl)
      equation
        s = ass2[e];
        c = listNth(crefs,s-1);
        eqn = listNth(eqnLst,e-1);
        varexp = DAE.CREF(c,DAE.ET_REAL());
        exp = solveEquation(eqn, varexp);
        exps = VarTransform.replaceExp(exp,repl,NONE());
        repl1 = VarTransform.addReplacement(repl, c, exps);
        (repl2,seqns) = getRelaxationReplacements(block_,ass2,crefs,eqnLst,repl1);  
      then 
        (repl2,SES_SIMPLE_ASSIGN(c, exp)::seqns);
  end matchcontinue;
end getRelaxationReplacements;

protected function solveEquation"
Author: Frenkel TUD 2010-09 function solveEquation
  solves a equation"
  input DAELow.Equation inEqn;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inEqn,inExp)
    local
      DAE.Exp exp,e1,e2,sol;
    case (DAELow.EQUATION(exp = e1,scalar = e2),exp)
      equation
        sol = solve(e1, e2, exp);
      then 
        sol;
    case (DAELow.RESIDUAL_EQUATION(exp = e1),exp)
      equation
        // TODO: use type correct Zero
        sol = solve(e1, DAE.RCONST(0.0), exp);
      then 
        sol;        
  end matchcontinue;
end solveEquation;

protected function getRelaxedResidualEqns"
Author: Frenkel TUD 2010-09 function getRelaxedResidualEqns
  replace all non tearing vars with its solutions in the 
  residual eqns"
  input list<Integer> inBlock;
  input Integer[:] inAss2;
  input list<DAE.ComponentRef> inCrefs;
  input list<DAELow.Var> inVarLst;
  input list<DAELow.Equation> inEqnLst;
  input VarTransform.VariableReplacements inRepl;
  output list<DAELow.Equation> outEqnLst;
  output list<DAELow.Var> outVarLst;
algorithm
  (outEqnLst,outVarLst) := matchcontinue (inBlock,inAss2,inCrefs,inVarLst,inEqnLst,inRepl)
    local
      Integer e,s;
      list<Integer> block_;
      Integer[:] ass2;
      list<DAE.ComponentRef> crefs;
      DAE.ComponentRef c;
      list<DAELow.Equation> eqnLst,eqnLst1;
      DAELow.Equation eqn,eqn1;
      VarTransform.VariableReplacements repl,repl1,repl2;
      DAE.Exp exp,e1,e2,varexp;
      list<DAELow.Var> varlst,varlst1;
      DAELow.Var var;
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
  end matchcontinue;
end getRelaxedResidualEqns;

protected function generateRelaxedResidualEqns"
Author: Frenkel TUD 2010-09 function generateRelaxedResidualEqns
  generates the equations for the residual eqns"
  input list<Integer> inBlock;
  input Boolean mixedEvent "true if generating the mixed system event code"; 
  input DAELow.DAELow daelow;
  input Integer[:] Ass1;
  input Integer[:] Ass2;
  input list<HelpVarInfo> helpVarInfo;  
  output list<SimEqSystem> outEqnLst;
algorithm
  outEqnLst := matchcontinue (inBlock,mixedEvent,daelow, Ass1, Ass2, helpVarInfo)
    local
      Integer r;
      list<Integer> block_;
      DAELow.IncidenceMatrix m;
      DAELow.IncidenceMatrixT mT;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      list<SimVar> simVars;
      list<DAE.Exp> beqs;
      list<tuple<Integer, Integer, SimEqSystem>> simJac;
      SimEqSystem reqn;
      DAELow.Variables v;
      list<DAELow.Var> dlowVars;
      DAELow.EquationArray eqn;
      list<DAELow.Equation> dlowEqs;
      DAELow.MultiDimEquation[:] ae;      
    case ({r},mixedEvent,daelow, Ass1, Ass2, helpVarInfo)
      equation
       reqn = createEquation(r,daelow, Ass1, Ass2, helpVarInfo);        
      then 
        {reqn};
    case (block_ as _::_::_,mixedEvent,daelow as DAELow.DAELOW(orderedVars=v,orderedEqs=eqn,arrayEqs=ae), Ass1, Ass2, helpVarInfo)
      equation
        dlowVars = DAELow.varList(v);
        dlowEqs = DAELow.equationList(eqn);
				m = DAELow.incidenceMatrix(daelow);
        mT = DAELow.transposeMatrix(m);      
        SOME(jac) = DAELow.calculateJacobian(v, eqn, ae, m, mT,false);
        simVars = Util.listMap(dlowVars, dlowvarToSimvar);
        (beqs,_) = listMap3passthrough(dlowEqs, dlowEqToExp, v, ae, {});
        simJac = Util.listMap1(jac, jacToSimjac, v);
      then
        {SES_LINEAR(mixedEvent, simVars, beqs, simJac)};
  end matchcontinue;
end generateRelaxedResidualEqns;

protected function jacToSimjac
  input tuple<Integer, Integer, DAELow.Equation> jac;
  input DAELow.Variables v;
  output tuple<Integer, Integer, SimEqSystem> simJac;
algorithm
  simJac :=
  matchcontinue (jac, v)
    local
      Integer row;
      Integer col;
      DAE.Exp e;
      DAE.Exp rhs_exp;
      DAE.Exp rhs_exp_1;
    case ((row, col, DAELow.RESIDUAL_EQUATION(exp=e)), v)
      equation
//        rhs_exp = DAELow.getEqnsysRhsExp(e, v);
//        rhs_exp_1 = Exp.simplify(rhs_exp);
//      then ((row - 1, col - 1, SES_RESIDUAL(rhs_exp_1)));
      then ((row - 1, col - 1, SES_RESIDUAL(e)));
  end matchcontinue;
end jacToSimjac;

protected function dlowEqToExp
  input DAELow.Equation dlowEq;
  input DAELow.Variables v;
  input DAELow.MultiDimEquation[:] arrayEqs;
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output DAE.Exp exp_;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (exp_,outEntrylst) :=
  matchcontinue (dlowEq, v, arrayEqs, inEntrylst)
    local
      Integer row, col, index;
      DAE.Exp e;
      DAE.Exp e1,e2,new_exp,new_exp1,rhs_exp,rhs_exp_1,rhs_exp_2;
      DAE.ExpType tp,tp1;
      DAELow.Equation dlowEq;
      list<Integer> ds;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1;  
     case (DAELow.RESIDUAL_EQUATION(exp=e), v, arrayEqs,inEntrylst)
      equation
        rhs_exp = DAELow.getEqnsysRhsExp(e, v);
        rhs_exp_1 = Exp.simplify(rhs_exp);
      then (rhs_exp_1,inEntrylst);
    case (DAELow.EQUATION(exp=e1, scalar=e2), v, arrayEqs,inEntrylst)
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = DAELow.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = DAE.UNARY(DAE.UMINUS(tp),rhs_exp);
        rhs_exp_2 = Exp.simplify(rhs_exp_1);
      then (rhs_exp_2,inEntrylst);
    case (DAELow.ARRAY_EQUATION(index=index), v, arrayEqs,inEntrylst)
      equation
        DAELow.MULTIDIM_EQUATION(dimSize=ds,left=e1, right=e2) = arrayEqs[index+1];
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = DAELow.getArrayEquationSub(index,ad,inEntrylst);
        new_exp1 = Exp.applyExpSubscripts(new_exp,subs);
        rhs_exp = DAELow.getEqnsysRhsExp(new_exp1, v);
        tp1 = Exp.typeof(rhs_exp);
        rhs_exp_1 = DAE.UNARY(DAE.UMINUS(tp1),rhs_exp);
        rhs_exp_2 = Exp.simplify(rhs_exp_1);
      then (rhs_exp_2,entrylst1);     
    case (dlowEq,_,_,_)
      equation
        DAELow.dumpEqns({dlowEq});
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"dlowEqToExp failed"},DAELow.equationInfo(dlowEq));
      then
        fail();        
  end matchcontinue;
end dlowEqToExp;

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
  outTypeELst:=
  matchcontinue (inTypeALst,inFuncTypeTypeATypeBTypeCTypeDToTypeE,inTypeB,inTypeC,inTypeD)
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
  end matchcontinue;
end listMap3passthrough;

protected function createSingleArrayEqnCode
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input DAELow.JacobianType inJacobianType;
  input list<Integer> block_;
  input list<HelpVarInfo> helpVarInfo; 
  output list<SimEqSystem> equations_;  
algorithm
  equations_ :=
  matchcontinue
    (mixedEvent,genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inJacobianType,block_,helpVarInfo) 
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      DAE.Exp e1,e2;
      list<DAE.Exp> ea1,ea2;
      list<tuple<DAE.Exp,DAE.Exp>> ealst;
      list<DAELow.Equation> re;
      DAE.ComponentRef cr,origname,cr_1;
      DAELow.Variables vars,knvars,exvars;
      DAELow.EquationArray eqns,se,ie,eqns_1;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac,jac1;
      DAELow.JacobianType jac_tp;
      list<Integer>[:] m,m_1,mt_1;
      DAE.ElementSource source "the origin of the element";
      DAELow.AliasVariables av;
      DAELow.ExternalObjectClasses eoc;
      DAELow.DAELow subsystem_dae;
      SimEqSystem equation_;

    case (mixedEvent,genDiscrete,
          DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        externalObjects = exvars,
                        aliasVars = av,
                        orderedEqs = eqns,
                        removedEqs = se,
                        initialEqs = ie,
                        arrayEqs = ae,
                        algorithms = al,
                        eventInfo = ev,
                        extObjClasses = eoc),jac,inJacobianType,block_,helpVarInfo) /* eqn code cg var_id extra functions */
      local String cr_1_str;
      equation
        (DAELow.ARRAY_EQUATION(index=indx) :: _) = DAELow.equationList(eqns);
        DAELow.MULTIDIM_EQUATION(ds,e1,e2,source) = ae[indx + 1];
        ((DAELow.VAR(varName = cr) :: _)) = DAELow.varList(vars);
        // We need to strip subs from the name since they are removed in cr.
        cr_1 = Exp.crefStripLastSubs(cr);
        (e1,e2) = solveTrivialArrayEquation(cr_1,e1,e2);
        equation_ = createSingleArrayEqnCode2(cr_1, cr_1, e1, e2);
      then
        {equation_};
    case (mixedEvent,genDiscrete,
          DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        externalObjects = exvars,
                        aliasVars = av,
                        orderedEqs = eqns,
                        removedEqs = se,
                        initialEqs = ie,
                        arrayEqs = ae,
                        algorithms = al,
                        eventInfo = ev,
                        extObjClasses = eoc),jac,inJacobianType,block_,helpVarInfo) /* eqn code cg var_id extra functions */
      local String cr_1_str;
      equation
        (DAELow.ARRAY_EQUATION(index=indx) :: _) = DAELow.equationList(eqns);
        DAELow.MULTIDIM_EQUATION(ds,e1,e2,source) = ae[indx + 1];
        DAE.ARRAY(scalar=true,array=ea1) = e1;
        DAE.ARRAY(scalar=true,array=ea2) = e2;
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        eqns_1 = DAELow.listEquation(re); 
        subsystem_dae = DAELow.DAELOW(vars,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc);
         m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac1 = DAELow.calculateJacobian(vars, eqns, ae, m_1, mt_1,false);
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac1);
        equations_ = createOdeSystem2(mixedEvent, genDiscrete, subsystem_dae, jac1, jac_tp, block_,helpVarInfo);             
      then
        equations_;          
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"array equations currently only supported on form v = functioncall(...)"});
      then
        fail();
  end matchcontinue;
end createSingleArrayEqnCode;

protected function createSingleAlgorithmCode
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  output SimEqSystem equation_;
algorithm
  equation_ := matchcontinue (inDAELow,inTplIntegerIntegerDAELowEquationLstOption)
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      Exp.Exp e1,e2;
      Exp.ComponentRef cr,origname,cr_1;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      Algorithm.Algorithm alg,alg1;
      DAELow.EventInfo ev;
      list<Exp.ComponentRef> solvedVars,algOutVars;
      list<Exp.Exp> algOutExpVars;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      String message,algStr;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source "the origin of the element";

    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev),jac)
      equation
        (DAELow.ALGORITHM(indx,_,algOutExpVars,_) :: _) = DAELow.equationList(eqns);
        alg = al[indx + 1];
        solvedVars = Util.listMap(DAELow.varList(vars),DAELow.varCref);
        algOutVars = Util.listMap(algOutExpVars,Exp.expCref);
        // The variables solved for and the output variables of the algorithm must be the same.
        true = Util.listSetEqualOnTrue(solvedVars,algOutVars,Exp.crefEqual);
        DAE.ALGORITHM_STMTS(algStatements) = DAELow.collateAlgorithm(alg,NONE());
        equation_ = SES_ALGORITHM(algStatements);
      then equation_;
    /* Error message, inverse algorithms not supported yet */
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev),jac)
      equation
        (DAELow.ALGORITHM(indx,_,algOutExpVars,source) :: _) = DAELow.equationList(eqns);
        alg = al[indx + 1];
        solvedVars = Util.listMap(DAELow.varList(vars),DAELow.varCref);
        algOutVars = Util.listMap(algOutExpVars,Exp.expCref);

        // The variables solved for and the output variables of the algorithm must be the same.
        false = Util.listSetEqualOnTrue(solvedVars,algOutVars,Exp.crefEqual);
        algStr =	DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = System.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {
          "array equations currently only supported on form v = functioncall(...)"});
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
  output SimEqSystem equation_;
algorithm
  equation_ :=
  matchcontinue (inComponentRef1,inComponentRef2,inExp3,inExp4)
    local
      String s1,s2,stmt,s3,s4,s;
      Integer cg_id_1,cg_id;
      DAE.ComponentRef cr,eltcr,cr2;
      DAE.Exp e1,e2;
      DAE.ExpType ty;      
    case (cr,eltcr,(e1 as DAE.CREF(componentRef = cr2)),e2)
      equation
        true = Exp.crefEqual(cr, cr2);
      then
        SES_ARRAY_CALL_ASSIGN(eltcr, e2);
    case (cr,eltcr,e1,(e2 as DAE.CREF(componentRef = cr2)))
      equation
        true = Exp.crefEqual(cr, cr2);
      then
      SES_ARRAY_CALL_ASSIGN(eltcr, e1);
    case (cr,eltcr,(e1 as DAE.UNARY(exp=DAE.CREF(componentRef = cr2))),e2)
      equation
        true = Exp.crefEqual(cr, cr2);
        ty = Exp.typeof(e2);
      then
        SES_ARRAY_CALL_ASSIGN(eltcr, DAE.UNARY(DAE.UMINUS_ARR(ty),e2));
    case (cr,eltcr,e1,(e2 as DAE.UNARY(exp=DAE.CREF(componentRef = cr2))))
      equation
        true = Exp.crefEqual(cr, cr2);
        ty = Exp.typeof(e1);
      then
      SES_ARRAY_CALL_ASSIGN(eltcr, DAE.UNARY(DAE.UMINUS_ARR(ty),e1));       
    case (cr,eltcr,e1,DAE.UNARY(DAE.UMINUS_ARR(ty),e2))
      equation
         cr2 = getVectorizedCrefFromExp(e2);
      then
         SES_ARRAY_CALL_ASSIGN(cr2, DAE.UNARY(DAE.UMINUS_ARR(ty),e1));       
    case (cr,eltcr,DAE.UNARY(DAE.UMINUS_ARR(ty),e1),e2) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
         cr2 = getVectorizedCrefFromExp(e1);
      then
         SES_ARRAY_CALL_ASSIGN(cr2, DAE.UNARY(DAE.UMINUS_ARR(ty),e2));
    case (cr,eltcr,e1,e2) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e2);
      then
        SES_ARRAY_CALL_ASSIGN(cr2, e1);
    case (cr,eltcr,e1,e2) /* e1 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
      then
        SES_ARRAY_CALL_ASSIGN(cr2, e2);
    case (_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createSingleArrayEqnCode2 failed"});
      then
        fail();
  end matchcontinue;
end createSingleArrayEqnCode2;

protected function createResidualEquations
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  output list<SimEqSystem> residualEquations;
algorithm
  residualEquations :=
  matchcontinue (dlow, ass1, ass2)
    local
      list<DAELow.Var> vars_lst;
      list<DAELow.Equation> eqns_lst, se_lst, ie_lst, ie2_lst;
      list<DAELow.Equation> residualEquationsTmp;
      DAELow.Variables vars, knvars;
      DAELow.EquationArray eqns, se, ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      list<tuple<DAELow.Equation, list<DAE.Exp>>> divexplst;
    case ((dlow as DAELow.DAELOW(orderedVars=vars,
                                 knownVars=knvars,
                                 orderedEqs=eqns,
                                 removedEqs=se,
                                 initialEqs=ie,
                                 arrayEqs=ae,
                                 algorithms=al,
                                 eventInfo=ev)),
          ass1, ass2)
      equation
        vars_lst = DAELow.varList(vars);
        eqns_lst = DAELow.equationList(eqns);
        se_lst = DAELow.equationList(se);
        ie_lst = DAELow.equationList(ie);
        ie2_lst = generateInitialEquationsFromStart(vars_lst);
        eqns_lst = selectContinuousEquations(eqns_lst, 1, ass2, dlow);

        eqns_lst = Util.listMap(eqns_lst, DAELow.equationToResidualForm);
        se_lst = Util.listMap(se_lst, DAELow.equationToResidualForm);
        ie_lst = Util.listMap(ie_lst, DAELow.equationToResidualForm);
        ie2_lst = Util.listMap(ie2_lst, DAELow.equationToResidualForm);

        residualEquationsTmp = listAppend(eqns_lst, se_lst);
        residualEquationsTmp = listAppend(residualEquationsTmp, ie_lst);
        residualEquationsTmp = listAppend(residualEquationsTmp, ie2_lst);

        residualEquationsTmp = Util.listFilter(residualEquationsTmp,
                                               failUnlessResidual);

        residualEquations = Util.listMap(residualEquationsTmp,
                                         dlowEqToSimEqSystem);
      then
        residualEquations;
    case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
                         {"createResidualEquations failed"});
      then
        fail();
  end matchcontinue;
end createResidualEquations;

protected function dlowEqToSimEqSystem
  input DAELow.Equation inEquation;
  output SimEqSystem outEquation;
algorithm
  outEquation:=
  matchcontinue (inEquation)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp_;
    case (DAELow.SOLVED_EQUATION(cr, exp_, _))
      then SES_SIMPLE_ASSIGN(cr, exp_);
    case (DAELow.RESIDUAL_EQUATION(exp_, _))
      then SES_RESIDUAL(exp_);
  end matchcontinue;
end dlowEqToSimEqSystem;

protected function failUnlessResidual
  input DAELow.Equation eq;
algorithm
  _ :=
  matchcontinue (eq)
    case (DAELow.RESIDUAL_EQUATION(exp=_)) then ();
  end matchcontinue;
end failUnlessResidual;

protected function createInitialEquations
  input DAELow.DAELow dlow;
  output list<SimEqSystem> initialEquations;
algorithm
  initialEquations := matchcontinue (dlow)
    local
      list<DAELow.Equation> initialEquationsTmp;
      list<DAELow.Equation> initialEquationsTmp2;
      list<DAELow.Var> vars_lst;
      list<DAELow.Var> knvars_lst;
      list<DAELow.Equation> eqns_lst;
      DAELow.Variables vars;
      DAELow.Variables knvars;
    case (DAELow.DAELOW(orderedVars=vars, knownVars=knvars))
      equation
        initialEquationsTmp2 = {};
        // vars
        vars_lst = DAELow.varList(vars);
        initialEquationsTmp = createInitialAssignmentsFromStart(vars_lst);
        initialEquationsTmp2 = listAppend(initialEquationsTmp2, initialEquationsTmp);
        // kvars
        knvars_lst = DAELow.varList(knvars);
        initialEquationsTmp = createInitialAssignmentsFromStart(knvars_lst);
        initialEquationsTmp2 = listAppend(initialEquationsTmp2, initialEquationsTmp);

        initialEquations = Util.listMap(initialEquationsTmp2,
                                        dlowEqToSimEqSystem);
      then
        initialEquations;
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
                         {"createInitialEquations failed"});
      then
        fail();
  end matchcontinue;
end createInitialEquations;

protected function createParameterEquations
  input DAELow.DAELow dlow;
  output list<SimEqSystem> parameterEquations;
algorithm
  parameterEquations := matchcontinue (dlow)
    local
      list<DAELow.Equation> parameterEquationsTmp;
      list<DAELow.Equation> tempEqs;
      list<DAELow.Var> vars_lst;
      list<DAELow.Var> knvars_lst;
      list<DAELow.Equation> eqns_lst;
      DAELow.Variables vars;
      DAELow.Variables knvars;
    case (DAELow.DAELOW(orderedVars=vars, knownVars=knvars))
      equation
        parameterEquationsTmp = {};
        // kvars params
        knvars_lst = DAELow.varList(knvars);
        tempEqs = createInitialParamAssignments(knvars_lst);
        parameterEquationsTmp = listAppend(parameterEquationsTmp, tempEqs);

        parameterEquations = Util.listMap(parameterEquationsTmp,
                                          dlowEqToSimEqSystem);
        //?? why is this reversed ???
        parameterEquations = listReverse(parameterEquations);
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
  input list<DAELow.Var> vars;
  output list<DAELow.Equation> initialEquations;
algorithm
  initialEquations := matchcontinue (vars)
    local
      DAELow.Equation initialEquation;
      list<DAELow.Var> restVars;
      Option<DAE.VariableAttributes> attr;
      DAE.ComponentRef name;
      DAE.Exp startv;
      DAE.ElementSource source "the origin of the element";

    case ({}) then {};
    case (DAELow.VAR(values=attr, varName=name, source=source) :: restVars)
      /* also add an assignment for variables that have non-constant
         expressions, e.g. parameter values, as start.  NOTE: such start
         attributes can then not be changed in the text file, since the initial
         calc. will override those entries!  */
      equation
        startv = DAEUtil.getStartAttr(attr);
        false = Exp.isConst(startv);
        initialEquation = DAELow.SOLVED_EQUATION(name, startv, source);
        initialEquations = createInitialAssignmentsFromStart(restVars);
      then
        (initialEquation :: initialEquations);
    case (_ :: restVars)
      equation
        initialEquations = createInitialAssignmentsFromStart(restVars);
      then
        initialEquations;
  end matchcontinue;
end createInitialAssignmentsFromStart;

protected function createInitialParamAssignments
  input list<DAELow.Var> vars;
  output list<DAELow.Equation> initialEquations;
algorithm
  initialEquations :=
  matchcontinue (vars)
    local
      DAELow.Equation initialEquation;
      list<DAELow.Var> restVars;
      Option<DAE.VariableAttributes> attr;
      DAE.ComponentRef cr;
      DAE.Exp startv;
      DAE.Exp e;
      DAE.ElementSource source "the origin of the element";

    case ({}) then {};
    case (DAELow.VAR(varName=cr, bindExp=SOME(e), source = source) :: restVars)
      equation
        false = Exp.isConst(e);
        initialEquation = DAELow.SOLVED_EQUATION(cr, e, source);
        initialEquations = createInitialParamAssignments(restVars);
      then
        (initialEquation :: initialEquations);
    case (_ :: restVars)
      equation
        initialEquations = createInitialParamAssignments(restVars);
      then
        initialEquations;
  end matchcontinue;
end createInitialParamAssignments;

protected function createZeroCrossings
  input DAELow.DAELow dlow;
  output list<DAELow.ZeroCrossing> zc;
algorithm
  zeroCrossings :=
  matchcontinue (dlow)
    case (DAELow.DAELOW(eventInfo=DAELow.EVENT_INFO(zeroCrossingLst=zc)))
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
  input list<DAELow.ZeroCrossing> zeroCrossings;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<list<Integer>> blocks;
  output list<list<SimVar>> needSave;
algorithm
  needSave :=
  matchcontinue (zeroCrossings, dlow, ass1, ass2, blocks)
    local
      DAELow.ZeroCrossing zc;
      list<DAELow.ZeroCrossing> rest_zc;
      list<Integer> eql;
      list<SimVar> needSaveTmp;
      list<list<SimVar>> needSave_rest;
    case ({}, _, _, _, _)
      then {};
    case ((zc as DAELow.ZERO_CROSSING(occurEquLst=eql)) :: rest_zc, dlow,
          ass1, ass2, blocks)
      equation
        needSaveTmp = createZeroCrossingNeedSave(dlow, ass1, ass2, eql,
                                                 blocks);
        needSave_rest = createZeroCrossingsNeedSave(rest_zc, dlow, ass1,
                                                    ass2, blocks);
      then needSaveTmp :: needSave_rest;
  end matchcontinue;
end createZeroCrossingsNeedSave;

protected function createZeroCrossingNeedSave
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<Integer> eqns2;
  input list<list<Integer>> blocks;
  output list<SimVar> needSave;
algorithm
  needSave :=
  matchcontinue (dlow, ass1, ass2, eqns2, blocks)
    local
      list<SimVar> crs;
      Integer cg_id,eqn_1,v,eqn,cg_id,cg_id_1,numValues;
      list<Integer> block_,rest;
      DAE.ComponentRef cr;
      String cr_str,save_stmt,rettp,fn,stmt;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,cont_var1;
      DAELow.Variables vars, vars_1,knvars,exvars;
      DAELow.AliasVariables av;
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      list<String> retrec,arg,init,stmts,cleanups,stmts_1;
      DAE.DAElist dae;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      DAELow.ExternalObjectClasses eoc;
      DAELow.Var dlowvar;
      SimVar simvar;
    case (_,_,_,{},_)
      then {};
    /* zero crossing for mixed system */
    case ((dlow as DAELow.DAELOW(vars, knvars, exvars, av, eqns, se, ie, ae,
                                      al, ev, eoc)),
          ass1, ass2, (eqn :: rest), blocks)
      equation
        true = isPartOfMixedSystem(dlow, eqn, blocks, ass2);
        block_ = getZcMixedSystem(dlow, eqn, blocks, ass2);
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (dlowvar as DAELow.VAR(varName = cr)) = DAELow.getVarAt(vars, v);
        crs = createZeroCrossingNeedSave(dlow, ass1, ass2, rest, blocks);
        simvar = dlowvarToSimvar(dlowvar);
      then
        (simvar :: crs);
    /* zero crossing for single equation */
    case ((dlow as DAELow.DAELOW(orderedVars = vars)), ass1, ass2,
          (eqn :: rest), blocks)
      local
        DAELow.Variables vars;
      equation
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (dlowvar as DAELow.VAR(varName = cr)) = DAELow.getVarAt(vars, v);
        crs = createZeroCrossingNeedSave(dlow, ass1, ass2, rest, blocks);
        simvar = dlowvarToSimvar(dlowvar);
      then
        (simvar :: crs);
  end matchcontinue;
end createZeroCrossingNeedSave;

protected function createModelInfo
  input Absyn.Path class_;
  input DAELow.DAELow dlow;
  input Integer numHelpVars;
  input Integer numResiduals;
  input String fileDir;
  output ModelInfo modelInfo;
algorithm
  modelInfo :=
  matchcontinue (class_, dlow, numHelpVars, numResiduals, fileDir)
    local
      String name;
      String directory;
      VarInfo varInfo;
      SimVars vars;
      Integer numOutVars;
      Integer numInVars;
      list<SimVar> iv;
      list<SimVar> ov;
    case (class_, dlow, numHelpVars, numResiduals, fileDir)
      equation
        //name = Absyn.pathString(class_);
        directory = System.trim(fileDir, "\"");
        vars = createVars(dlow);
        SIMVARS(inputVars=iv, outputVars=ov) = vars;
        numOutVars = listLength(ov);
        numInVars = listLength(iv);
        varInfo = createVarInfo(dlow, numOutVars, numInVars, numHelpVars,
                                numResiduals);
      then
        MODELINFO(class_, directory, varInfo, vars);
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createModelInfo failed"});
      then
        fail();
  end matchcontinue;
end createModelInfo;

protected function createVarInfo
  input DAELow.DAELow dlow;
  input Integer numOutVars;
  input Integer numInVars;
  input Integer numHelpVars;
  input Integer numResiduals;
  output VarInfo varInfo;
algorithm
  varInfo :=
  matchcontinue (dlow, numOutVars, numInVars, numHelpVars, numResiduals)
    local
      Integer nx, ny, np, ng, ng_sam, ng_sam_1, next, ny_string, np_string, ng_1;
      Integer ny_int, np_int, ny_bool, np_bool;
    case (dlow, numOutVars, numInVars, numHelpVars, numResiduals)
      equation
        (nx, ny, np, ng, ng_sam, next, ny_string, np_string, ny_int, np_int, ny_bool, np_bool) =
          DAELow.calculateSizes(dlow);
        ng_1 = filterNg(ng);
        ng_sam_1 = filterNg(ng_sam);
      then
        VARINFO(numHelpVars, ng_1, ng_sam_1, nx, ny, ny_int, ny_bool, np, np_int, np_bool, numOutVars, numInVars,
                numResiduals, next, ny_string, np_string);
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createVarInfo failed"});
      then
        fail();
  end matchcontinue;
end createVarInfo;

protected function createVars
  input DAELow.DAELow dlow;
  output SimVars varsOut;
algorithm
  varsOut :=
  matchcontinue (dlow)
    local
      list<DAELow.Var> var_lst;
      list<DAELow.Var> knvar_lst;
      list<DAELow.Var> extvar_lst;
      DAELow.Variables vars;
      DAELow.Variables knvars;
      DAELow.Variables extvars;
      SimVars varsTmp;
      DAELow.EquationArray ie;
      list<DAELow.Equation> ie_lst;
    case (DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        externalObjects = extvars,
                        initialEqs=ie))
      equation
        /* Extract from variable list */
        var_lst = DAELow.varList(vars);
        varsOut = extractVarsFromList(var_lst);
        /* Extract from known variable list */
        knvar_lst = DAELow.varList(knvars);
        varsTmp = extractVarsFromList(knvar_lst);
        varsOut = mergeVars(varsOut, varsTmp);
        /* Extract from external object list */
        extvar_lst = DAELow.varList(extvars);
        varsTmp = extractVarsFromList(extvar_lst);
        varsOut = mergeVars(varsOut, varsTmp);
        /* sort variables on index */
        varsOut = sortSimvarsOnIndex(varsOut);
        /* Index of algebraic and parameters need 
        	 to fix due to separation of int Vars*/
        varsOut = fixIndex(varsOut);
        /* fix the initial thing */
        ie_lst = DAELow.equationList(ie);
        varsOut = fixInitialThing(varsOut, ie_lst);
      then
        varsOut;
  end matchcontinue;
end createVars;

protected function extractVarsFromList
  input list<DAELow.Var> varList;
  output SimVars varsOut;
algorithm
  varsOut :=
  matchcontinue (varList)
    local
      DAELow.Var var;
      Exp.ComponentRef cr, origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Integer indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> vs;
      SimVars varsTmp1;
      SimVars varsTmp2;
      SimVars vars;
    case ({})
      then (SIMVARS({}, {}, {}, {}, {}, {}, {}, {}, {},{},{},{},{}));
    case ((var :: vs))
      equation
        varsTmp1 = extractVarFromVar(var);
        varsTmp2 = extractVarsFromList(vs);
        vars = mergeVars(varsTmp1, varsTmp2);
      then
        vars;
    case ((_ :: vs))
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"extractVarsFromList failed"});
      then
        fail();
  end matchcontinue;
end extractVarsFromList;

// one dlow var can result in multiple simvars: input and output are a subset
// of algvars for example
protected function extractVarFromVar
  input DAELow.Var dlowVar;
  output SimVars varsOut;
algorithm
  varsOut :=
  matchcontinue (dlowVar)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> extObjVars;
      SimVar simvar;
      SimVar derivSimvar;
    case (dlowVar)
      equation
        /* start with empty lists */
        stateVars = {};
        derivativeVars = {};
        algVars = {};
        intAlgVars = {};
        boolAlgVars = {};
        inputVars = {};
        outputVars = {};
        paramVars = {};
        intParamVars = {};
        boolParamVars = {};
        stringAlgVars = {};
        stringParamVars = {};
        extObjVars = {};
        /* extract the sim var */
        simvar = dlowvarToSimvar(dlowVar);
        derivSimvar = derVarFromStateVar(simvar);
        /* figure out in which lists to put it */
        stateVars = addSimvarIfTrue(
          DAELow.isStateVar(dlowVar), simvar, stateVars);
        derivativeVars = addSimvarIfTrue(
          DAELow.isStateVar(dlowVar), derivSimvar, derivativeVars);
        algVars = addSimvarIfTrue(
          isVarAlg(dlowVar), simvar, algVars);
        intAlgVars = addSimvarIfTrue(
          isVarIntAlg(dlowVar), simvar, intAlgVars);
        boolAlgVars = addSimvarIfTrue(
          isVarBoolAlg(dlowVar), simvar, boolAlgVars);            
        inputVars = addSimvarIfTrue(
          DAELow.isVarOnTopLevelAndInput(dlowVar), simvar, inputVars);
        outputVars = addSimvarIfTrue(
          DAELow.isVarOnTopLevelAndOutput(dlowVar), simvar, outputVars);
        paramVars = addSimvarIfTrue(
          isVarParam(dlowVar), simvar, paramVars);
        intParamVars = addSimvarIfTrue(
          isVarIntParam(dlowVar), simvar, intParamVars);
        boolParamVars = addSimvarIfTrue(
          isVarBoolParam(dlowVar), simvar, boolParamVars);            
        stringAlgVars = addSimvarIfTrue(
          isVarStringAlg(dlowVar), simvar, stringAlgVars);
        stringParamVars = addSimvarIfTrue(
          isVarStringParam(dlowVar), simvar, stringParamVars);
        extObjVars = addSimvarIfTrue(
          DAELow.isExtObj(dlowVar), simvar, extObjVars);
      then
        SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars,
                paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, extObjVars);
  end matchcontinue;
end extractVarFromVar;

protected function derVarFromStateVar
  input SimVar state;
  output SimVar deriv;
algorithm
  deriv :=
  matchcontinue (state)
    local
      DAE.ComponentRef name;
      DAELow.VarKind kind;
      String comment, unit, displayUnit;
      Integer index;
      Option<DAE.Exp> initVal;
      Boolean isFixed;
      Exp.Type type_;
      Boolean isDiscrete;
      DAE.ComponentRef arrayCref;
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, isFixed, type_, isDiscrete, NONE()))
      equation
        name = DAELow.crefPrefixDer(name);
      then
        SIMVAR(name, DAELow.STATE_DER(), comment, unit, displayUnit, index, NONE(), isFixed, type_,
               isDiscrete, NONE());      
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, isFixed, type_, isDiscrete, SOME(arrayCref)))
      equation
        name = DAELow.crefPrefixDer(name);
        arrayCref = DAELow.crefPrefixDer(arrayCref);
      then
        SIMVAR(name, DAELow.STATE_DER(), comment, unit, displayUnit, index, NONE(), isFixed, type_,
               isDiscrete, SOME(arrayCref));
  end matchcontinue;
end derVarFromStateVar;

protected function addSimvarIfTrue
  input Boolean condition;
  input SimVar var;
  input list<SimVar> lst;
  output list<SimVar> res;
algorithm
  res :=
  matchcontinue (condition, var, lst)
    case (true, var, lst)
      then (var :: lst);
    case (false, var, lst)
      then lst;
  end matchcontinue;
end addSimvarIfTrue;

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
      list<SimVar> intParamVars, intParamVars1, intParamVars2;
      list<SimVar> boolParamVars, boolParamVars1, boolParamVars2;
      list<SimVar> stringAlgVars, stringAlgVars1, stringAlgVars2;
      list<SimVar> stringParamVars, stringParamVars1, stringParamVars2;
      list<SimVar> extObjVars, extObjVars1, extObjVars2;
    case (SIMVARS(stateVars1, derivativeVars1, algVars1, intAlgVars1, boolAlgVars1, inputVars1,
                  outputVars1, paramVars1, intParamVars1, boolParamVars1, stringAlgVars1, stringParamVars1,
                  extObjVars1),
          SIMVARS(stateVars2, derivativeVars2, algVars2, intAlgVars2, boolAlgVars2, inputVars2,
                  outputVars2, paramVars2, intParamVars2, boolParamVars2, stringAlgVars2, stringParamVars2,
                  extObjVars2))
      equation
        stateVars = listAppend(stateVars1, stateVars2);
        derivativeVars = listAppend(derivativeVars1, derivativeVars2);
        algVars = listAppend(algVars1, algVars2);
        intAlgVars = listAppend(intAlgVars1, intAlgVars2);
        boolAlgVars = listAppend(boolAlgVars1, boolAlgVars2);
        inputVars = listAppend(inputVars1, inputVars2);
        outputVars = listAppend(outputVars1, outputVars2);
        paramVars = listAppend(paramVars1, paramVars2);
        intParamVars = listAppend(intParamVars1, intParamVars2);
        boolParamVars = listAppend(boolParamVars1, boolParamVars2);
        stringAlgVars = listAppend(stringAlgVars1, stringAlgVars2);
        stringParamVars = listAppend(stringParamVars1, stringParamVars2);
        extObjVars = listAppend(extObjVars1, extObjVars2);
      then
        SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars, outputVars,
                paramVars,intParamVars,boolParamVars, stringAlgVars, stringParamVars, extObjVars);
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
  matchcontinue (unsortedSimvars)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> extObjVars;
    case (SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
                  outputVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars,
                  extObjVars))
      equation
        stateVars = Util.sort(stateVars, varIndexComparer);
        derivativeVars = Util.sort(derivativeVars, varIndexComparer);
        algVars = Util.sort(algVars, varIndexComparer);
        intAlgVars = Util.sort(intAlgVars, varIndexComparer);
        boolAlgVars = Util.sort(boolAlgVars, varIndexComparer);
        inputVars = Util.sort(inputVars, varIndexComparer);
        outputVars = Util.sort(outputVars, varIndexComparer);
        paramVars = Util.sort(paramVars, varIndexComparer);
        intParamVars = Util.sort(intParamVars, varIndexComparer);
        boolParamVars = Util.sort(boolParamVars, varIndexComparer);
        stringAlgVars = Util.sort(stringAlgVars, varIndexComparer);
        stringParamVars = Util.sort(stringParamVars, varIndexComparer);
        extObjVars = Util.sort(extObjVars, varIndexComparer);
      then SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
                   outputVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars,
                   extObjVars);
  end matchcontinue;
end sortSimvarsOnIndex;

protected function fixIndex
  input SimVars unfixedSimvars;
  output SimVars fixedSimvars;
algorithm
  unfixedSimvars :=
  matchcontinue (fixedSimvars)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> extObjVars;
    case (SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
                  outputVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars,
                  extObjVars))
      equation
        algVars = rewriteIndex(algVars, 0);
        intAlgVars = rewriteIndex(intAlgVars,0);
        boolAlgVars = rewriteIndex(boolAlgVars,0);
        paramVars = rewriteIndex(paramVars, 0);
        intParamVars = rewriteIndex(intParamVars, 0);
        boolParamVars = rewriteIndex(boolParamVars, 0);
        stringAlgVars = rewriteIndex(stringAlgVars, 0);
        stringParamVars = rewriteIndex(stringParamVars, 0);
      then SIMVARS(stateVars, derivativeVars, algVars,intAlgVars, boolAlgVars, inputVars,
                   outputVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars,
                   extObjVars);
  end matchcontinue;
end fixIndex;

protected function rewriteIndex
  input list<SimVar> inVars;
  input Integer index;
  output list<SimVar> outVars;
algorithm 
   outVars :=
   matchcontinue(inVars,index)
       local
      DAE.ComponentRef name;
      DAELow.VarKind kind;
      String comment, unit, displayUnit;
      Integer index;
      Option<DAE.Exp> initVal;
      Boolean isFixed;
      Exp.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      Integer index_;
      list<SimVar> rest,rest2;
    case ({},_) then {};  
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, isFixed, type_, isDiscrete, arrayCref)::rest,index_)
      equation
       rest2 = rewriteIndex(rest, index_ + 1);
      then (SIMVAR(name, kind, comment, unit, displayUnit, index_, initVal, isFixed, type_, isDiscrete, arrayCref)::rest2);
   end matchcontinue; 
end rewriteIndex;

protected function varIndexComparer
  input SimVar lhs;
  input SimVar rhs;
  output Boolean res;
algorithm
  res :=
  matchcontinue (lhs, rhs)
    local
      Integer lhsIndex;
      Integer rhsIndex;
    case (SIMVAR(index=lhsIndex), SIMVAR(index=rhsIndex))
      then rhsIndex < lhsIndex;
  end matchcontinue;
end varIndexComparer;

protected function fixInitialThing
  input SimVars simvarsIn;
  input list<DAELow.Equation> initialEqs;
  output SimVars simvarsOut;
algorithm
  simvarsOut :=
  matchcontinue (simvarsIn, initialEqs)
    local
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> intAlgVars;
      list<SimVar> boolAlgVars;
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
      list<SimVar> intParamVars;
      list<SimVar> boolParamVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> extObjVars;
    /* no initial equations so nothing to do */
    case (_, {})
      then simvarsIn;
    case (SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
                  outputVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars,
                  extObjVars), initialEqs)
      equation
        true = Util.boolAndList(Util.listMap(stateVars, simvarFixed));
        stateVars = Util.listMap1(stateVars, nonFixifyIfHasInit, initialEqs);
      then SIMVARS(stateVars, derivativeVars, algVars, intAlgVars, boolAlgVars, inputVars,
                   outputVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars,
                   extObjVars);
    /* not all were fixed so nothing to do */
    case (_, _)
      then simvarsIn;
  end matchcontinue;
end fixInitialThing;

protected function simvarFixed
  input SimVar simvar;
  output Boolean fixed_;
algorithm
  fixed_ :=
  matchcontinue (simvar)
    case (SIMVAR(isFixed=fixed_)) then fixed_;
    case (_) then fail();
  end matchcontinue;
end simvarFixed;

protected function nonFixifyIfHasInit
  input SimVar simvarIn;
  input list<DAELow.Equation> initialEqs;
  output SimVar simvarOut;
algorithm
  simvarOut :=
  matchcontinue (simvarIn, initialEqs)
    local
      DAE.ComponentRef name;
      DAELow.VarKind kind;
      String comment, unit, displayUnit;
      Integer index;
      Option<DAE.Exp> initVal;
      Boolean isFixed;
      Exp.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      list<DAE.ComponentRef> initCrefs;
      String varNameStr;
    case (SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, isFixed, type_, isDiscrete, arrayCref), initialEqs)
      equation
        initCrefs = DAELow.equationsCrefs(initialEqs);
        (_ :: _) = Util.listSelect1(initCrefs, name, Exp.crefEqual);
        varNameStr = Exp.printComponentRefStr(name);
        Error.addMessage(Error.SETTING_FIXED_ATTRIBUTE, {varNameStr});
      then SIMVAR(name, kind, comment, unit, displayUnit, index, initVal, false, type_, isDiscrete, arrayCref);
    case (_, _)
      then simvarIn;
  end matchcontinue;
end nonFixifyIfHasInit;

protected function getArrayCref
  input DAELow.Var var;
  output Option<DAE.ComponentRef> arrayCref;
algorithm
  arrayCref :=
  matchcontinue (var)
    local
      DAE.ComponentRef name;
      DAE.ComponentRef arrayCrefInner;
    case (DAELow.VAR(varName=name))
      equation
        true = Exp.crefIsFirstArrayElt(name);
        arrayCrefInner = Exp.crefStripLastSubs(name);
      then SOME(arrayCrefInner);
    case (_)
      then NONE();
  end matchcontinue;
end getArrayCref;

protected function unparseCommentOptionNoAnnotationNoQuote
  input Option<SCode.Comment> absynComment;
  output String commentStr;
algorithm
  outString :=
  matchcontinue (absynComment)
    case (SOME(SCode.COMMENT(_, SOME(commentStr)))) then commentStr;
    case (_) then "";
  end matchcontinue;
end unparseCommentOptionNoAnnotationNoQuote;

protected function generateHelpVarsForWhenStatements
	input list<HelpVarInfo> inHelpVarInfo;
	input DAELow.DAELow inDAELow;
	output list<HelpVarInfo> outHelpVarInfo;
	output DAELow.DAELow outDAELow;
algorithm
  (outHelpVarInfo,outDAELow) :=
  matchcontinue (inHelpVarInfo,inDAELow)
    local
      list<HelpVarInfo> helpvars, helpvars1;
      DAELow.Variables orderedVars;
      DAELow.Variables knownVars;
      DAELow.Variables externalObjects;
      DAELow.AliasVariables aliasVars;
      DAELow.EquationArray orderedEqs;
      DAELow.EquationArray removedEqs;
      DAELow.EquationArray initialEqs;
      DAELow.MultiDimEquation[:] arrayEqs;
      Algorithm.Algorithm[:] algorithms,algorithms2;
      list<Algorithm.Algorithm> algLst;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
    case	(helpvars,DAELow.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,
      removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses))
      equation
        (helpvars1,algLst,_) = generateHelpVarsInAlgorithms(listLength(helpvars),arrayList(algorithms));
        algorithms2 = listArray(algLst);
      then (listAppend(helpvars,helpvars1),DAELow.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,
        removedEqs,initialEqs,arrayEqs,algorithms2,eventInfo,extObjClasses));
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsForWhenStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsForWhenStatements;

protected function generateHelpVarsInAlgorithms
  input Integer nextInd "Index of next help variable";
  input list<Algorithm.Algorithm> inAlgLst;
  output list<HelpVarInfo> outHelpVars;
  output list<Algorithm.Algorithm> outAlgLst;
  output Integer n2;
algorithm
  (outHelpVars,outAlgLst,n2) := matchcontinue(nextInd,inAlgLst)
    local
      Integer nextInd,nextInd2,nextInd3;
      list<Algorithm.Statement> stmts, stmts2;
      list<Algorithm.Algorithm> rest,rest2;
      list<HelpVarInfo> helpvars1,helpvars2,helpvars;
    case (nextInd, {}) then ({},{},nextInd);
    case (nextInd, (DAE.ALGORITHM_STMTS(stmts))::rest)
      equation
        (helpvars1,rest2,nextInd2) = generateHelpVarsInAlgorithms(nextInd,rest);
        (helpvars2,stmts2,nextInd3) = generateHelpVarsInStatements(nextInd2,stmts);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,DAE.ALGORITHM_STMTS(stmts2)::rest2,nextInd3);
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
      list<Algorithm.Statement> rest, rest1;
      Integer nextInd, nextInd1, nextInd2;
      list<Integer> helpVarIndices, helpVarIndices1;
      Exp.Exp condition;
      list<Exp.Exp> el, el1;
	    list<Algorithm.Statement> statementLst;
	    Algorithm.Statement statement;
  	  Algorithm.Statement elseWhen;
	    list<HelpVarInfo> helpvars,helpvars1,helpvars2;
      String newIdent;
      String nextIndStr;
      Exp.Type ty;
      Boolean scalar;
      list<Integer> helpVarIndices1,helpVarIndices;
      DAE.ElementSource source;
    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,NONE,_,source))
      equation
				(helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
				helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
				helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
      then (helpvars1,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,NONE,helpVarIndices,source),nextInd1);

    case (nextInd, DAE.STMT_WHEN(condition,statementLst,NONE,_,source))
      then ({(nextInd,condition,-1)},DAE.STMT_WHEN(condition, statementLst,NONE,{nextInd},source),nextInd+1);

    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,SOME(elseWhen),_,source))
      equation
				(helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
				helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
				helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
        (helpvars2,statement,nextInd2) = generateHelpVarsInStatement(nextInd1,elseWhen);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,SOME(statement),helpVarIndices,source),nextInd1);

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
  input list<Exp.Exp> inExp;
  output list<HelpVarInfo> outHelpVars;
  output list<Exp.Exp> outExp;
  output Integer n1;
algorithm
  (outHelpVars,outExp,n2) := matchcontinue(n,inExp)
    local
      list<Exp.Exp> rest, el, el1;
      Integer nextInd, nextInd1;
      Exp.Exp condition;
	    list<HelpVarInfo> helpvars1;
      String newIdent;
      String nextIndStr;

    case (nextInd, {}) then ({},{},nextInd);

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
  input list<DAELow.Equation> eqnLst;
  input Integer eqnIndx; // iterator, starts at 1..n
	input Integer[:] ass2;
	input DAELow.DAELow daelow;
	output list<DAELow.Equation> outEqnLst;
algorithm
  outEqnLst := matchcontinue(eqnLst,eqnIndx,ass2,daelow)
    local
      DAELow.VariableArray vararr;
      DAELow.Var var;
      Integer v,v_1;
      Boolean b;
      DAELow.Equation e;
    case({},eqnIndx,ass2,daelow) then {};
    case(e::eqnLst,eqnIndx,ass2,daelow as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr)))
     equation
       v = ass2[eqnIndx];
       v_1 = v - 1;
       (var) = DAELow.vararrayNth(vararr, v_1);
       b = hasDiscreteVar({var});
       eqnLst = selectContinuousEquations(eqnLst,eqnIndx+1,ass2,daelow);
       eqnLst = Util.if_(b,eqnLst,e::eqnLst);
     then eqnLst;
  end matchcontinue;
end selectContinuousEquations;

protected function generateInitialEquationsFromStart "function: generateInitialEquationsFromStart

  This function generates equations from the expressions in the start
  attributes of variables. Only variables with a start value and
  fixed set to true is converted by this function. Fixed set to false
  means an initial guess, and is not considered here.
"
  input list<DAELow.Var> inDAELowVarLst;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowVarLst)
    local
      list<DAELow.Equation> eqns;
      DAELow.Var v;
      Exp.ComponentRef cr;
      DAELow.VarKind kind;
      Exp.Exp startv;
      Option<DAE.VariableAttributes> attr;
      list<DAELow.Var> vars;
      DAE.ElementSource source "the origin of the element";

    case ({}) then {};
    case (((v as DAELow.VAR(varName = cr,varKind = kind,values = attr,source=source)) :: vars)) /* add equations for variables with fixed = true */
      equation
        true = DAELow.varFixed(v);
        true = DAEUtil.hasStartAttr(attr);
        startv = DAEUtil.getStartAttr(attr);
        eqns = generateInitialEquationsFromStart(vars);
      then
        (DAELow.EQUATION(DAE.CREF(cr,DAE.ET_OTHER()),startv,source) :: eqns);
    case ((_ :: vars))
      equation
        eqns = generateInitialEquationsFromStart(vars);
      then
        eqns;
  end matchcontinue;
end generateInitialEquationsFromStart;

protected function buildWhenConditionChecks3
" Helper function to build_when_condition_checks.
  Generates code for checking one equation of one when clause.
"
  input list<Exp.Exp> whenConditions   "List of expressions from \"when {exp1, exp2, ...}\" ";
  input Integer whenClauseIndex        "When clause index";
  input Integer nextHelpIndex          "Next available help variable index";
  input Boolean isElseWhen					   "Whether this lase is an elsewhen or not";
  output String outString              "Generated c-code";
  output list<HelpVarInfo> helpVarLst;
algorithm
  (outString,helpVarLst):=
  matchcontinue (whenConditions,whenClauseIndex,nextHelpIndex,isElseWhen)
    local
      String i_str,helpVarIndexStr,res,resx,res_1;
      HelpVarInfo helpInfo;
      Integer helpVarIndex_1,i,helpVarIndex;
      list<HelpVarInfo> helpVarInfoList;
      Exp.Exp e;
      list<Exp.Exp> el;
    case ({},_,_,_) then ("",{});
    case ((e :: el),i,helpVarIndex, false)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        helpInfo = (helpVarIndex,e,i);
        res = System.stringAppendList(
          {"  if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
          " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,false);
        res_1 = stringAppend(res, resx);
      then
        (res_1,(helpInfo :: helpVarInfoList));
    case ((e :: el),i,helpVarIndex, true)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        helpInfo = (helpVarIndex,e,i);
        res = System.stringAppendList(
          {"  else if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
          " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,false);
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

protected function buildWhenConditionChecks2
" This function outputs checks for all when clauses that do not have equations but reinit statements.
"
  input list<DAELow.WhenClause> inDAELowWhenClauseLst1 "List of when clauses";
  input Integer whenClauseIndex "index of the first when clause in inDAELowWhenClauseLst1";
  input Integer nextHelpVarIndex;
  output String outString;
  output list<HelpVarInfo> helpVarLst;
algorithm
  (outString,helpVarLst):=
  matchcontinue (inDAELowWhenClauseLst1,whenClauseIndex,nextHelpVarIndex)
    local
      Integer i_1,i,nextHelpIndex,numberOfNewHelpVars,nextHelpIndex_1;
      String res,res2,res1;
      list<HelpVarInfo> helpVarInfoList,helpVarInfoList2,helpVarInfoList1;
      DAELow.WhenClause wc;
      list<DAELow.WhenClause> xs;
      list<Exp.Exp> el;
      Exp.Exp e;
    case ({},_,_) then ("",{});
    case (((wc as DAELow.WHEN_CLAUSE(reinitStmtLst = {})) :: xs),i,nextHelpIndex) /* skip if there are no reinit statements */
      equation
        i_1 = i + 1;
        (res,helpVarInfoList) = buildWhenConditionChecks2(xs, i_1, nextHelpIndex);
      then
        (res,helpVarInfoList);
    case (((wc as DAELow.WHEN_CLAUSE(condition = DAE.ARRAY(array = el))) :: xs),i,nextHelpIndex)
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
    case (((wc as DAELow.WHEN_CLAUSE(condition = e)) :: xs),i,nextHelpIndex)
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
  input list<DAELow.Equation> inDAELowEquationLst     "List of equations.";
  input list<DAELow.WhenClause> inDAELowWhenClauseLst "List of when clauses.";
  input Integer nextHelpVarIndex                      "index of the next generated help variable.";
  output String outString                             "Generated event checking code";
  output list<HelpVarInfo> helpVarLst									"List of help variables introduced in this function.";
algorithm
  (outString,helpVarLst):=
  matchcontinue (orderOfEquations,inDAELowEquationLst,inDAELowWhenClauseLst,nextHelpVarIndex)
    local
      Integer eqn,nextHelpIndex;
      String res2,res1,res;
      list<HelpVarInfo> helpVarInfoList2,helpVarInfoList1,helpVarInfoList;
      list<Integer> rest;
      list<DAELow.Equation> eqnl;
      list<DAELow.WhenClause> whenClauseList;
      DAELow.WhenEquation whenEq;

    case ({},_,_,_) then ("",{});

		/* equation is a WHEN_EQUATION */
    case ((eqn :: rest),eqnl,whenClauseList,nextHelpIndex)
      equation
        DAELow.WHEN_EQUATION(whenEquation=whenEq) = listNth(eqnl, eqn-1);
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
  input Option<DAELow.WhenEquation> whenEq            "The equation to check for";
  input list<DAELow.WhenClause> inDAELowWhenClauseLst "List of when clauses.";
  input Boolean isElseWhen                            "Whether the equation is inside an elsewhen or not.";
  input Integer nextHelpIndex                         "Next avalable help variable index.";
  output String outString                             "Generated event checking code";
  output list<HelpVarInfo> helpVarLst									"List of help variables introduced in this function.";
algorithm
  (outString, helpVarLst) :=
  matchcontinue (whenEq,inDAELowWhenClauseLst,isElseWhen, nextHelpIndex)
    local
      Boolean isElseWhen;
      Integer nextHelpInd, ind;
      Exp.ComponentRef cr;
      Exp.Exp exp;
      String res1,res2,res;
      Option<DAELow.WhenEquation> elsePart;
      list<Exp.Exp> conditionList;
      list<HelpVarInfo> helpVars1,helpVars2, helpVars;
      list<DAELow.WhenClause> whenClauseList;
    case (SOME(DAELow.WHEN_EQ(ind,cr,exp,elsePart)),whenClauseList,isElseWhen,nextHelpInd)
      equation
        conditionList = getConditionList(whenClauseList, ind);
        (res1,helpVars1) = buildWhenConditionChecks3(conditionList, ind, nextHelpInd,isElseWhen);
        (res2,helpVars2) = buildWhenConditionCheckForEquation(elsePart, whenClauseList, true,
          nextHelpInd + listLength(helpVars1));
        res = stringAppend(res1,res2);
        helpVars = listAppend(helpVars1,helpVars2);
      then
        (res,helpVars);
    case (NONE,_,_,_)
      then ("",{});
  end matchcontinue;
end buildWhenConditionCheckForEquation;

protected function getConditionList
  input list<DAELow.WhenClause> whenClauseList;
  input Integer index;
  output list<Exp.Exp> conditionList;
algorithm
  conditionList := matchcontinue (whenClauseList, index)
    local
      list<DAELow.WhenClause> whenClauseList;
      Integer ind;
      list<Exp.Exp> conditionList;
      Exp.Exp e;

    case (whenClauseList, ind)
      equation
        DAELow.WHEN_CLAUSE(condition=DAE.ARRAY(_,_,conditionList)) = listNth(whenClauseList, ind);
      then conditionList;
    case (whenClauseList, ind)
      equation
        DAELow.WHEN_CLAUSE(condition=e) = listNth(whenClauseList, ind);
      then {e};
  end matchcontinue;
end getConditionList;

protected function addMissingEquations "function: addMissingEquations
  Helper function to build_when_condition_checks
  Given an integer and a list of integers completes the list with missing
  integers upto the given integer.
"
  input Integer inInteger;
  input list<Integer> inIntegerLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger,inIntegerLst)
    local
      list<Integer> lst,lst_1,lst_2;
      Integer n_1,n;
    case (0,lst) then lst;
    case (n,lst)
      equation
        n_1 = n - 1;
        lst_1 = addMissingEquations(n_1, lst);
        _ = Util.listGetMember(n, lst);
      then
        lst_1;
    case (n,lst) /* missing equations must be added in correct order,
	 required in building whenConditionChecks4 */
      equation
        n_1 = n - 1;
        lst_1 = addMissingEquations(n_1, lst);
        lst_2 = listAppend(lst_1, {n});
      then
        lst_2;
  end matchcontinue;
end addMissingEquations;

protected function buildDiscreteVarChangesVar2
"Help relation to buildDiscreteVarChangesVar
 For an equation e  (not a when equation) containing a discrete variable v, if e contains a
 ZeroCrossing(i) generate 'if change(v) needToIterate=1;)'"
  input Integer eqn;
  input Exp.ComponentRef cr;
  input DAELow.DAELow daelow;
  output String outString;
algorithm
  outString := matchcontinue(eqn,cr,daelow)
  local DAELow.EquationArray eqns;
    DAELow.Equation e;
    list<DAELow.ZeroCrossing> zcLst;
    String crStr;
    list<String> strLst;
    list<Integer> zcIndxLst;

    case(eqn,cr,daelow as DAELow.DAELOW(eventInfo=DAELow.EVENT_INFO(zeroCrossingLst = zcLst)))
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
  input	list<DAELow.ZeroCrossing> zcLst;
  output list<Integer> eqns;
algorithm
  eqns := matchcontinue(eqn,i,zcLst)
    local list<Integer> eqnLst;
    case (_,_,{}) then {};
    case(eqn,i,DAELow.ZERO_CROSSING(occurEquLst=eqnLst)::zcLst) equation
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
  input Exp.ComponentRef cr;
  output String str;
protected
	String crStr,indxStr;
algorithm
	crStr := Exp.printComponentRefStr(cr);
	indxStr := intString(indx);
	str := System.stringAppendList({"if (change(",crStr,")) { needToIterate=1; }"});
end buildDiscreteVarChangesAddEvent;

protected function mixedCollectRelations "function: mixedCollectRelations
  author: PA
"
  input list<DAELow.Equation> c_eqn;
  input list<DAELow.Equation> d_eqn;
  output list<Exp.Exp> res;
  list<Exp.Exp> l1,l2;
algorithm
  l1 := mixedCollectRelations2(c_eqn);
  l2 := mixedCollectRelations2(d_eqn);
  res := listAppend(l1, l2);
end mixedCollectRelations;

protected function mixedCollectRelations2 "function: mixedCollectRelations2
  author: PA

  Helper function to mixed_collect_functions.
"
  input list<DAELow.Equation> inDAELowEquationLst;
  output list<Exp.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inDAELowEquationLst)
    local
      list<Exp.Exp> l1,l2,l3,res;
      Exp.Exp e1,e2;
      list<DAELow.Equation> es;
      Exp.ComponentRef cr;
    case ({}) then {};
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: es))
      equation
        l1 = Exp.getRelations(e1);
        l2 = Exp.getRelations(e2);
        l3 = mixedCollectRelations2(es);
        res = Util.listFlatten({l1,l2,l3});
      then
        res;
    case ((DAELow.SOLVED_EQUATION(componentRef = cr,exp = e1) :: es))
      equation
        l1 = Exp.getRelations(e1);
        l2 = mixedCollectRelations2(es);
        res = listAppend(l1, l2);
      then
        res;
    case (_) then {};
  end matchcontinue;
end mixedCollectRelations2;

protected function generateMixedDiscreteCombinationValues "function generateMixedDiscreteCombinationValues
  author: PA

  Generates all combinations of the values given as argument
"
  input list<list<String>> inStringLstLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inStringLstLst)
    local
      list<String> value;
      list<list<String>> values_1,values;
    case ({value}) then {value};  /* values */
    case (values)
      equation
        values_1 = generateMixedDiscreteCombinationValues1(values) "&
	Util.list_strip_last(values\') => values\'\'" ;
      then
        values_1;
  end matchcontinue;
end generateMixedDiscreteCombinationValues;

protected function generateMixedDiscreteCombinationValues1
  input list<list<String>> inStringLstLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inStringLstLst)
    local
      list<list<String>> value_1,values_1,values_2,values;
      list<String> value;
    case ({value}) /* values */
      equation
        value_1 = Util.listMap(value, Util.listCreate);
      then
        value_1;
    case ((value :: values))
      equation
        values_1 = generateMixedDiscreteCombinationValues1(values);
        values_2 = generateMixedDiscreteCombinationValues2(value, values_1);
      then
        values_2;
  end matchcontinue;
end generateMixedDiscreteCombinationValues1;

protected function generateMixedDiscreteCombinationValues2 "function generateMixedDiscreteCombinationValues2
  author: PA

  Helper function to generate_mixed_discrete_combination_values.
  Insert a list of values producing all combinations with given list of list
  of values.
"
  input list<String> inStringLst;
  input list<list<String>> inStringLstLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inStringLst,inStringLstLst)
    local
      list<list<String>> lst,lst_1,lst2,res;
      String s;
      list<String> ss;
    case ({},lst) then {};
    case ((s :: ss),lst) 
      equation
        lst_1 = Util.listMap1(lst, Util.listCons, s);
        lst2 = generateMixedDiscreteCombinationValues2(ss, lst);
        res = listAppend(lst_1, lst2);
      then
        res;
  end matchcontinue;
end generateMixedDiscreteCombinationValues2;

protected function generateMixedDiscretePossibleValues2 "function: generateMixedDiscretePossibleValues2

  Helper function to generate_mixed_discrete_possible_values.
"
  input list<Exp.Exp> inExpExpLst;
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output list<list<String>> outStringLstLst;
  output list<Integer> outIntegerLst;
algorithm
  (outStringLstLst,outIntegerLst):=
  matchcontinue (inExpExpLst,inDAELowVarLst,inInteger)
    local
      Integer cg_id;
      list<list<String>> values;
      list<Integer> dims;
      list<Exp.Exp> rels;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case (_,{},cg_id) then ({},{});  /* discrete vars cg var_id values value dimension */
    case (rels,(v :: vs),cg_id) /* booleans, generate true (1.0) and false (0.0) */
      equation
        DAELow.BOOL() = DAELow.varType(v);
        (values,dims) = generateMixedDiscretePossibleValues2(rels, vs, cg_id);
      then
        (({"1.0","0.0"} :: values),(2 :: dims));
    case (rels,(v :: vs),_)
      equation
        DAELow.INT() = DAELow.varType(v);
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Mixed system of equations with dicrete variables of type Integer not supported. Try to rewrite using Boolean variables."});
      then
        fail();
  end matchcontinue;
end generateMixedDiscretePossibleValues2;

protected function splitMixedEquations "function: splitMixedEquations
  author: PA

  Splits the equation of a mixed equation system into its continuous and
  discrete parts.

  Even though the matching algorithm might say that a discrete variable is solved in a specific equation
  (when part of a mixed system) this is not always correct. It might be impossible to solve the discrete
  variable from that equation, for instance solving v from equation x = v < 0; This happens for e.g. the Gear model.
  Instead, to split the equations and variables the following scheme is used:

  1. Split the variables into continuous and discrete.
  2. For each discrete variable v, select among the equations where it is present
   for an equation v = expr. (This could be done
   by looking at incidence matrix but for now we look through all equations. This is sufficiently
   efficient for small systems of mixed equations < 100)
  3. The equations not selected in step 2 are continuous equations.
"
  input list<DAELow.Equation> eqnLst;
  input list<DAELow.Var> varLst;
  output list<DAELow.Equation> contEqnLst;
  output list<DAELow.Var> contVarLst;
  output list<DAELow.Equation> discEqnLst;
  output list<DAELow.Var> discVarLst;
algorithm
  (contEqnLst,contVarLst,discEqnLst,discVarLst):=
  matchcontinue (eqnLst,varLst)
      case (eqnLst,varLst) equation
        discVarLst = Util.listSelect(varLst,DAELow.isVarDiscrete);
        contVarLst = Util.listSetDifferenceOnTrue(varLst,discVarLst,DAELow.varEqual);
			  discEqnLst = Util.listMap1(discVarLst,findDiscreteEquation,eqnLst);
			  contEqnLst = Util.listSetDifferenceOnTrue(eqnLst,discEqnLst,DAELow.equationEqual);
			  then (contEqnLst,contVarLst,discEqnLst,discVarLst);
  end matchcontinue;
end splitMixedEquations;

protected function findDiscreteEquation "help function to splitMixedEquations, finds the discrete equation
on the form v = expr for solving variable v"
  input DAELow.Var v;
  input list<DAELow.Equation> eqnLst;
  output DAELow.Equation eqn;
algorithm
  eqn := matchcontinue(v,eqnLst)
    local Exp.ComponentRef cr1,cr;
      Exp.Exp e2;
    case (v,(eqn as DAELow.EQUATION(DAE.CREF(cr,_),e2,_))::_) equation
      cr1=DAELow.varCref(v);
      true = Exp.crefEqual(cr1,cr);
    then eqn;
    case(v,(eqn as DAELow.EQUATION(e2,DAE.CREF(cr,_),_))::_) equation
      cr1=DAELow.varCref(v);
      true = Exp.crefEqual(cr1,cr);
    then eqn;
    case(v,_::eqnLst) equation
      eqn = findDiscreteEquation(v,eqnLst);
    then eqn;
    case(v,_) equation
      print("findDiscreteEquation failed, searching for ");
      print(Exp.printComponentRefStr(DAELow.varCref(v)));
      print("\n");
    then fail();
  end matchcontinue;
end findDiscreteEquation;

protected function isMixedSystem "function: isMixedSystem
  author: PA

  Returns true if the list of variables is an equation system contains
  both discrete and continuous variables.
"
  input list<DAELow.Var> inDAELowVarLst;
  input list<DAELow.Equation> inEqns;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELowVarLst,inEqns)
    local list<DAELow.Var> vs;
      list<DAELow.Equation> eqns;
				/* A single algorithm section (consists of several eqns) is not mixed system */
      case (vs,eqns) equation
        singleAlgorithmSection2(eqns,NONE());
      then false;
    case (vs,eqns)
      equation
        true = hasDiscreteVar(vs);
        true = hasContinousVar(vs);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end isMixedSystem;

protected function solveTrivialArrayEquation
"Solves some trivial array equations, like v+v2=foo(...), w.r.t. v is v=foo(...)-v2"
	input Exp.ComponentRef v;
	input Exp.Exp e1;
	input Exp.Exp e2;
	output Exp.Exp outE1;
	output Exp.Exp outE2;
algorithm
  (outE1,outE2) := matchcontinue(v,e1,e2)
    local
      Exp.Exp e12,e22,vTerm,res,rhs,f;
      list<Exp.Exp> terms,exps,exps_1,expl_1;
      Exp.Type tp;
      Boolean b;
      list<Boolean> bls; 
      DAE.ComponentRef c;     
    case (v,DAE.ARRAY( tp, b,exps as ((DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef=c)) :: _))),e2)
      equation
        (f::exps_1) = Util.listMap(exps, Exp.expStripLastSubs); //Strip last subscripts
        bls = Util.listMap1(exps_1, Exp.expEqual,f);
        true = Util.boolAndList(bls);
        c = Exp.crefStripLastSubs(c);
        (e12,e22) = solveTrivialArrayEquation(v,DAE.CREF(c,tp),DAE.UNARY(DAE.UMINUS_ARR(tp),e2));
      then  
        (e12,e22);
   case (v,e2,DAE.ARRAY( tp, b,exps as ((DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef=c)) :: _))))
      equation
        (f::exps_1) = Util.listMap(exps, Exp.expStripLastSubs); //Strip last subscripts
        bls = Util.listMap1(exps_1, Exp.expEqual,f);
        true = Util.boolAndList(bls);
        c = Exp.crefStripLastSubs(c);
        (e12,e22) = solveTrivialArrayEquation(v,DAE.UNARY(DAE.UMINUS_ARR(tp),e2),DAE.CREF(c,tp));
      then  
        (e12,e22);
    // Solve simple linear equations.
    case(v,e1,e2)
      equation
        tp = Exp.typeof(e1);
        res = Exp.simplify(DAE.BINARY(e1,DAE.SUB_ARR(tp),e2));
        (f,rhs) = Exp.getTermsContainingX(res,DAE.CREF(v,DAE.ET_OTHER()));
        (vTerm as DAE.CREF(_,_)) = Exp.simplify(f);
        rhs = Exp.simplify(rhs);
      then (vTerm,rhs);

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
  input Exp.Exp inExp;
  output Exp.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inExp)
    local
      list<Exp.ComponentRef> crefs,crefs_1;
      Exp.ComponentRef cr;
      list<String> strs;
      String s;
      list<Exp.Exp> expl;
      list<list<tuple<Exp.Exp, Boolean>>> column;
    case (DAE.ARRAY(array = expl))
      equation
        ((crefs as (cr :: _))) = Util.listMap(expl, Exp.expCref); //Get all CRefs from exp1.
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubs); //Strip last subscripts
        _ = Util.listReduce(crefs_1, Exp.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
    case (DAE.MATRIX(scalar = column))
      equation
        ((crefs as (cr :: _))) = Util.listMap(column, getVectorizedCrefFromExpMatrix);
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubs);
        _ = Util.listReduce(crefs_1, Exp.crefEqualReturn);
      then
        cr;
  end matchcontinue;
end getVectorizedCrefFromExp;

protected function getVectorizedCrefFromExpMatrix
"function: getVectorizedCrefFromExpMatrix
  author: KN
  Helper function for the 2D part of getVectorizedCrefFromExp
  Returns the component ref v if list of expressions is on form
   {v{1},v{2},...v{n}}  for some n."
  input list<tuple<Exp.Exp, Boolean>> column; //One column in a matrix.
  output Exp.ComponentRef outComponentRef; //The expanded column
algorithm
  outComponentRef:=
  matchcontinue (column)
    local
      list<tuple<Exp.Exp, Boolean>> col;
      list<Exp.ComponentRef> crefs,crefs_1;
      Exp.ComponentRef cr;
      list<String> strs;
      String s;
      list<Exp.Exp> expl;
    case (col)
      equation
        ((crefs as (cr :: _))) = Util.listMap(col, Exp.expCrefTuple); //Get all CRefs from the list of tuples.
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubs); //Strip last subscripts
        _ = Util.listReduce(crefs_1, Exp.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
		case (_)
		  equation
      then
        fail();
  end matchcontinue;
end getVectorizedCrefFromExpMatrix;

protected function singleAlgorithmSection
"function: singleAlgorithmSection
  author: PA
  Checks if a dae (subsystem) consists of a single algorithm section."
  input DAELow.DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Equation> eqn_lst;
      DAELow.Variables vars;
      DAELow.EquationArray eqnarr;
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqnarr))
      equation
        eqn_lst = DAELow.equationList(eqnarr);
        singleAlgorithmSection2(eqn_lst,NONE());
      then
        ();
  end matchcontinue;
end singleAlgorithmSection;

protected function singleAlgorithmSection2
  input list<DAELow.Equation> inDAELowEquationLst;
  input Option<Integer> Index;  
algorithm
  _:=
  matchcontinue (inDAELowEquationLst,Index)
    local 
      list<DAELow.Equation> res;
      Integer i,i1;
    case ({},_) then ();
    case ((DAELow.ALGORITHM(index = i) :: res),NONE())
      equation
        singleAlgorithmSection2(res,SOME(i));
      then
        ();      
    case ((DAELow.ALGORITHM(index = i) :: res),SOME(i1))
      equation
        true = intEq(i,i1);
        singleAlgorithmSection2(res,SOME(i1));
      then
        ();
  end matchcontinue;
end singleAlgorithmSection2;

protected function singleArrayEquation
"function: singleArrayEquation
  author: PA
  Checks if a dae (subsystem) consists of a single array equation."
  input DAELow.DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Equation> eqn_lst;
      DAELow.Variables vars;
      DAELow.EquationArray eqnarr;
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqnarr))
      equation
        eqn_lst = DAELow.equationList(eqnarr);
        singleArrayEquation2(eqn_lst,NONE);
      then
        ();
  end matchcontinue;
end singleArrayEquation;

protected function singleArrayEquation2
  input list<DAELow.Equation> inDAELowEquationLst;
  input Option<Integer> Index;
algorithm
  _:=
  matchcontinue (inDAELowEquationLst,Index)
    local 
      list<DAELow.Equation> res;
      Integer i,i1;
    case ({},_) then ();
    case ((DAELow.ARRAY_EQUATION(index = i) :: res),NONE)
      equation
        singleArrayEquation2(res,SOME(i));
      then
        ();
    case ((DAELow.ARRAY_EQUATION(index = i) :: res),SOME(i1))
      equation
        true = intEq(i,i1);
        singleArrayEquation2(res,SOME(i1));
      then
        ();        
  end matchcontinue;
end singleArrayEquation2;

protected function makeResidualReplacements "function: makeResidualReplacements
  author: PA

  This function makes replacement rules for variables occuring in a
  nonlinear equation system. They should be replaced by xloc{index}, i.e.
  an unique index in a xloc vector.
"
  input list<Exp.ComponentRef> crefs;
  output VarTransform.VariableReplacements repl_1;
  VarTransform.VariableReplacements repl,repl_1;
algorithm
  repl := VarTransform.emptyReplacements();
  repl_1 := makeResidualReplacements2(repl, crefs, 0);
end makeResidualReplacements;

protected function makeResidualReplacements2 "function makeResidualReplacements2
  author: PA

  Helper function to make_residual_replacements
"
  input VarTransform.VariableReplacements inVariableReplacements;
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input Integer inInteger;
  output VarTransform.VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  matchcontinue (inVariableReplacements,inExpComponentRefLst,inInteger)
    local
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      String pstr,str;
      Integer pos_1,pos;
      Exp.ComponentRef cr;
      list<Exp.ComponentRef> crs;
    case (repl,{},_) then repl;
    case (repl,(cr :: crs),pos)
      equation
        repl_1 = VarTransform.addReplacement(repl, cr, 
          DAE.CREF(DAE.CREF_IDENT("xloc", DAE.ET_ARRAY(DAE.ET_REAL(), {DAE.DIM_UNKNOWN}), {DAE.INDEX(DAE.ICONST(pos))}), 
                   DAE.ET_REAL()));
        pos_1 = pos + 1;
        repl_2 = makeResidualReplacements2(repl_1, crs, pos_1);
      then
        repl_2;
  end matchcontinue;
end makeResidualReplacements2;

protected function skipPreOperator "function: skipPreOperator

  Condition function, used in generate_ode_system2_nonlinear_residuals2.
  The variable in the pre operator should not be replaced in residual
  functions. This function is passed to replace_exp to ensure this.
"
  input Exp.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    case (_) then true;
  end matchcontinue;
end skipPreOperator;

protected function transformXToXd "function transformXToXd
  author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)
"
  input DAELow.Var inVar;
  output DAELow.Var outVar;
algorithm
  outVar := matchcontinue (inVar)
    local
      Exp.ComponentRef cr;
      DAE.VarDirection dir;
      DAELow.Type tp;
      Option<Exp.Exp> exp;
      Option<Values.Value> v;
      list<Exp.Subscript> dim;
      Integer index;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "the origin of the element";
    case (DAELow.VAR(varName = cr,
                     varKind = DAELow.STATE(),
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
        cr = DAELow.crefPrefixDer(cr);
      then
        DAELow.VAR(cr,DAELow.STATE_DER(),dir,tp,exp,v,dim,index,source,attr,comment,flowPrefix,streamPrefix);

    case (v)
      local DAELow.Var v;
      then
        v;
  end matchcontinue;
end transformXToXd;

protected function getEquationAndSolvedVar
"function: getEquationAndSolvedVar
  author: PA
  Retrieves the equation and the variable solved in that equation
  given an equation number and the variable assignments2"
  input Integer inInteger;
  input DAELow.EquationArray inEquationArray;
  input DAELow.Variables inVariables;
  input Integer[:] inIntegerArray;
  output DAELow.Equation outEquation;
  output DAELow.Var outVar;
algorithm
  (outEquation,outVar):=
  matchcontinue (inInteger,inEquationArray,inVariables,inIntegerArray)
    local
      Integer e_1,v,e;
      DAELow.Equation eqn;
      DAELow.Var var;
      DAELow.EquationArray eqns;
      DAELow.Variables vars;
      Integer[:] ass2;
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
        e_1 = e - 1;
        eqn = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        var = DAELow.getVarAt(vars, v);
      then
        (eqn,var);
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "SimCode.getEquationAndSolvedVar failed at index: " +& intString(e));
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar;

protected function isPartOfMixedSystem
"function: isPartOfMixedSystem
  Helper function to generateZeroCrossing2, returns true if any equation
  in the equation list of a zero-crossing is part of a mixed system."
  input DAELow.DAELow inDAELow;
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELow,inInteger,inIntegerLstLst,inIntegerArray)
    local
      list<Integer> block_;
      list<DAELow.Equation> eqn_lst;
      list<DAELow.Var> var_lst;
      Boolean res;
      DAELow.DAELow dae;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer e;
      list<list<Integer>> blocks;
      Integer[:] ass2;
    case ((dae as DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns)),e,blocks,ass2) /* equation blocks ass2 */
      equation
        block_ = DAELow.getEquationBlock(e, blocks);
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
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
  input DAELow.DAELow inDAELow;
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inDAELow,inInteger,inIntegerLstLst,inIntegerArray)
    local
      list<Integer> block_;
      list<DAELow.Equation> eqn_lst;
      list<DAELow.Var> var_lst;
      DAELow.DAELow dae;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer e;
      list<list<Integer>> blocks;
      Integer[:] ass2;
    case ((dae as DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns)),e,blocks,ass2) /* equation blocks ass2 */
      equation
        block_ = DAELow.getEquationBlock(e, blocks);
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
      then
        block_;
  end matchcontinue;
end getZcMixedSystem;

protected function splitOutputBlocks
"Splits the output blocks into two
  parts, one for continous output variables and one for discrete output values.
  This must be done to ensure that discrete variables are calculated before and
  after a discrete event."
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrix mT;
  input list<list<Integer>> blocks;
  output list<list<Integer>> contBlocks;
  output list<list<Integer>> discBlocks;
algorithm
  (contBlocks,discBlocks) := matchcontinue(dlow,ass1,ass2,m,mT,blocks)
    local DAELow.Variables vars,vars2,knvars;
      list<DAELow.Var> varLst, varLstDiscrete;
      DAELow.EquationArray eqns;
    case (dlow as DAELow.DAELOW(orderedVars=vars,knownVars = knvars,orderedEqs=eqns),ass1,ass2,m,mT,blocks) equation
      varLst = DAELow.varList(vars);
      varLstDiscrete = Util.listSelect(varLst,DAELow.isVarDiscrete);
      vars2 = DAELow.listVar(varLstDiscrete);
      (contBlocks,discBlocks,_) = splitOutputBlocks2(vars2,vars,knvars,eqns,ass1,ass2,m,mT,blocks);
    then (contBlocks,discBlocks);
  end matchcontinue;
end splitOutputBlocks;

protected function splitOutputBlocks2
  input DAELow.Variables discVars;
  input DAELow.Variables vars;
  input DAELow.Variables knvars;
  input DAELow.EquationArray eqns;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrix mT;
  input list<list<Integer>> blocks;
  output list<list<Integer>> contBlocks;
  output list<list<Integer>> discBlocks;
  output DAELow.Variables discVars;
algorithm
  (contBlocks,discBlocks,discVars) := matchcontinue(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blocks)
    local list<Integer> blck;

    /* discrete block */
    case(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blck::blocks)
      equation
        discVars = blockSolvesDiscrete(discVars,vars,knvars,eqns,blck,ass2,mT);
        (contBlocks,discBlocks,discVars) = splitOutputBlocks2(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blocks);
      then (contBlocks,blck::discBlocks,discVars);

    /* continous block */
    case(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blck::blocks)
      equation
        (contBlocks,discBlocks,discVars) = splitOutputBlocks2(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blocks);
      then (blck::contBlocks,discBlocks,discVars);

    case(discVars,vars,knvars,eqns,ass1,ass2,m,mT,{}) then ({},{},discVars);
  end matchcontinue;
end splitOutputBlocks2;

protected function blockSolvesDiscrete
"Help function to splitOutputBlocks
 succeds if the block solves for any discrete variable."
  input DAELow.Variables discVars;
  input DAELow.Variables vars;
  input DAELow.Variables knvars;
  input DAELow.EquationArray eqns;
  input list<Integer> blck;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrixT mT;
  output DAELow.Variables outDiscVars;
algorithm
  outDiscVars := matchcontinue(discVars,vars,knvars,eqns,blck,ass2,mT)
    local list<DAELow.Equation> eqn_lst; list<DAELow.Var> var_lst;
      /* Solves a discrete variable, typically in when-clause */
    case(discVars,vars,knvars,eqns,blck,ass2,mT)
      equation
      (eqn_lst,var_lst) = Util.listMap32(blck, getEquationAndSolvedVar, eqns, vars, ass2);
        _::_ = Util.listSelect(var_lst,DAELow.isVarDiscrete);
        discVars = DAELow.addVars(var_lst,discVars);
      then discVars;

      /* Equation has variablity discrete time */
    case(discVars,vars,knvars,eqns,blck,ass2,mT) equation
      (eqn_lst,var_lst) = Util.listMap32(blck, getEquationAndSolvedVar, eqns, discVars, ass2);
      var_lst = Util.listMap1(var_lst,DAELow.setVarKind,DAELow.DISCRETE());
      discVars = DAELow.addVars(var_lst,discVars);
      _::_ = Util.listSelect2(eqn_lst,discVars,knvars,DAELow.isDiscreteEquation);
      discVars = DAELow.addVars(var_lst,discVars);
      then discVars;
  end matchcontinue;
end blockSolvesDiscrete;

protected function getCalledFunctionsInFunctions
"function: getCalledFunctionsInFunctions
  Goes through the given DAE, finds the given functions and collects
  the names of the functions called from within those functions"
  input list<Absyn.Path> paths;
  input list<Absyn.Path> accumulated;
  input DAE.FunctionTree funcs;
  output list<Absyn.Path> res;
  list<list<Absyn.Path>> pathslist;
algorithm
  res := matchcontinue(paths,accumulated,funcs)
    local
      list<Absyn.Path> res,acc,rest;
      Absyn.Path path;
    case ({},accumulated,funcs) then accumulated;
    case (path::rest,accumulated,funcs)
      equation
        acc = getCalledFunctionsInFunction(path, accumulated, funcs);
        res = getCalledFunctionsInFunctions(rest, acc, funcs);
      then res;
  end matchcontinue;
end getCalledFunctionsInFunctions;

public function getCalledFunctionsInFunction
"function: getCalledFunctionsInFunction
  Goes through the given DAE, finds the given function and collects
  the names of the functions called from within those functions"
  input Absyn.Path inPath;
  input list<Absyn.Path> accumulated;
  input DAE.FunctionTree funcs;
  output list<Absyn.Path> outAbsynPathLst;
algorithm
  outAbsynPathLst:=
  matchcontinue (inPath,accumulated,funcs)
    local
      String pathstr,debugpathstr;
      Absyn.Path path;
      DAE.Function funcelem;
      list<DAE.Function> funcelems;
      list<DAE.Function> elements;
      list<Exp.Exp> explist,fcallexps,fcallexps_1, fnrefs;
      list<Absyn.ComponentRef> crefs;
      list<Absyn.Path> calledfuncs,res1,res2,res,acc;
      list<String> debugpathstrs;
      DAE.DAElist dae;
      
    case (path,acc,funcs)
      local
        list<DAE.Element> varlist;
        list<list<DAE.Element>> varlistlist;
        list<Absyn.Path> varfuncs, fnpaths, fns, referencedFuncs, reffuncs;
      equation
        false = listMember(path,acc);
        funcelem = DAEUtil.getNamedFunction(path, funcs);
        funcelems = {funcelem};
        explist = DAEUtil.getAllExpsFunctions(funcelems);
        fcallexps = getMatchingExpsList(explist, matchCalls);
        fcallexps_1 = Util.listSelect(fcallexps, isNotBuiltinCall);
        calledfuncs = Util.listMap(fcallexps_1, getCallPath);

        /*-- MetaModelica Partial Function --*/

        // get all arguments of constant T_FUNCTION type and add to list
        fnrefs = getMatchingExpsList(explist, matchFnRefs);
        crefs = Util.listMap(fnrefs, getCrefFromExp);
        reffuncs = Util.listMap(crefs, Absyn.crefToPath);

        //fns = removeDuplicatePaths(fnpaths)s
        calledfuncs = listAppend(reffuncs, calledfuncs);
        calledfuncs = removeDuplicatePaths(calledfuncs);

        varlistlist = Util.listMap(funcelems, getFunctionElementsList);
        varlist = Util.listFlatten(varlistlist);
        varfuncs = Util.listFold(varlist, DAEUtil.collectFunctionRefVarPaths, {});
        varfuncs = Util.listFold(Util.if_(RTOpts.acceptMetaModelicaGrammar(), explist, {}), DAEUtil.collectValueblockFunctionRefVars, varfuncs);
        calledfuncs = Util.listSetDifference(calledfuncs, varfuncs) "Filter out function reference calls";
        /*--                                           --*/
        res = getCalledFunctionsInFunctions(calledfuncs, path::acc, funcs);

        Debug.fprintln("info", "getCalledFunctionsInFunction: " +& Absyn.pathString(path)) "debug" ;
        Debug.fprint("info", "Found variable function refs to ignore: ") "debug" ;
        debugpathstrs = Util.listMap(varfuncs, Absyn.pathString) "debug" ;
        debugpathstr = Util.stringDelimitList(debugpathstrs, ", ") "debug" ;
        Debug.fprintln("info", debugpathstr) "debug" ;
        Debug.fprint("info", "Found called functions: ") "debug" ;
        debugpathstrs = Util.listMap(res, Absyn.pathString) "debug" ;
        debugpathstr = Util.stringDelimitList(debugpathstrs, ", ") "debug" ;
        Debug.fprintln("info", debugpathstr) "debug" ;
      then
        res;

    case (path,acc,funcs) /* Don\'t fail here, ceval will generate the function later */
      equation
        false = listMember(path,acc);
        failure(_ = DAEUtil.getNamedFunction(path, funcs));
        pathstr = Absyn.pathString(path);
        Debug.fprintln("failtrace", "SimCode.getCalledFunctionsInFunction: Class " 
          +& pathstr +& " not found in global scope.");
      then
        path::acc;

    case (path,acc,_)
      equation
        true = listMember(path,acc);
      then acc;

    case(_,_,_)
      equation
        Debug.fprint("failtrace", "SimCode.getCalledFunctionsInFunction failed\n");
      then fail();
  end matchcontinue;
end getCalledFunctionsInFunction;

protected function getCallPath
"function: getCallPath
  Retrive the function name from a CALL expression."
  input DAE.Exp inExp;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inExp)
    local
      Absyn.Path path;
      DAE.ComponentRef cref;
    case DAE.CALL(path = path) then path;
    case DAE.CREF(componentRef = cref)
      equation
        path = Exp.crefToPath(cref);
      then
        path;
  end matchcontinue;
end getCallPath;

protected function getFunctionElementsList
"function: getFunctionElementsList
  Retrives the dAEList of function (or external function)"
  input DAE.Function inElem;
  output list<DAE.Element> out;
algorithm
  outPath:=
  matchcontinue (inElem)
    local Absyn.Path path;
    case DAE.FUNCTION(functions = {DAE.FUNCTION_DEF(out)}) then out;
    case DAE.FUNCTION(functions = {DAE.FUNCTION_EXT(body=out)}) then out;
    case DAE.RECORD_CONSTRUCTOR(path = _) then {};
  end matchcontinue;
end getFunctionElementsList;

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
  input list<list<Integer>> inIntegerLstLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIntegerLstLst)
    local
      list<Integer> res,block_;
      list<list<Integer>> blocks;
      Integer eqn;
    case ({}) then {};
    case (((block_ as (_ :: (_ :: _))) :: blocks))
      equation
        res = generateEquationOrder(blocks) "For system of equations skip these" ;
      then
        res;
    case (((block_ as {eqn}) :: blocks))
      equation
        res = generateEquationOrder(blocks) "for single equations" ;
      then
        (eqn :: res);
    case (_)
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
  _ :=
  matchcontinue (inElement)
    local
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(kind=vk, direction=vd)
      equation
        isVarVarOrConstant(vk);
        isDirectionNotInput(vd);
      then ();
  end matchcontinue;
end isVarQ;

protected function isVarVarOrConstant
  input DAE.VarKind inVarKind;
algorithm
  _ :=
  matchcontinue (inVarKind)
    case DAE.VARIABLE() then ();
    case DAE.PARAM() then ();
  end matchcontinue;
end isVarVarOrConstant;

protected function isDirectionNotInput
  input DAE.VarDirection inVarDirection;
algorithm
  _ :=
  matchcontinue (inVarDirection)
    case DAE.OUTPUT() then ();
    case DAE.BIDIR() then ();
  end matchcontinue;
end isDirectionNotInput;

protected function filterNg
"Sets the number of zero crossings to zero if events are disabled."
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger :=
  matchcontinue (inInteger)
    local
      Integer ng;
    case _
      equation
        false = useZerocrossing();
      then
        0;
    case ng
      then ng;
  end matchcontinue;
end filterNg;

protected function useZerocrossing
  output Boolean res;
  Boolean flagSet;
algorithm
  flagSet := RTOpts.debugFlag("noevents");
  res := boolNot(flagSet);
end useZerocrossing;

protected function isNonState
"Fails if the given variable kind is state."
  input DAELow.VarKind inVarKind;
algorithm
  _ :=
  matchcontinue (inVarKind)
    case (DAELow.VARIABLE()) then ();
    case (DAELow.DUMMY_DER()) then ();
    case (DAELow.DUMMY_STATE()) then ();
    case (DAELow.DISCRETE()) then ();
    case (DAELow.STATE_DER()) then ();
  end matchcontinue;
end isNonState;

protected function hasDiscreteVar
"Returns true if var list contains a discrete time variable."
  input list<DAELow.Var> inDAELowVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean :=
  matchcontinue (inDAELowVarLst)
    local
      Boolean res;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ((DAELow.VAR(varKind=DAELow.DISCRETE()) :: _)) then true;
    case ((DAELow.VAR(varType=DAELow.INT()) :: _)) then true;
    case ((DAELow.VAR(varType=DAELow.BOOL()) :: _)) then true;
    case ((v :: vs))
      equation
        res = hasDiscreteVar(vs);
      then
        res;
    case ({}) then false;
  end matchcontinue;
end hasDiscreteVar;

protected function hasContinousVar
"Returns true if var list contains a continous time variable."
  input list<DAELow.Var> inDAELowVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean :=
  matchcontinue (inDAELowVarLst)
    local
      Boolean res;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ((DAELow.VAR(varKind=DAELow.VARIABLE()) :: _)) then true;
    case ((DAELow.VAR(varKind=DAELow.STATE()) :: _)) then true;
    case ((DAELow.VAR(varKind=DAELow.STATE_DER()) :: _)) then true;
    case ((DAELow.VAR(varKind=DAELow.DUMMY_DER()) :: _)) then true;
    case ((DAELow.VAR(varKind=DAELow.DUMMY_STATE()) :: _)) then true;
    case ((v :: vs))
      equation
        res = hasContinousVar(vs);
      then
        res;
    case ({}) then false;
  end matchcontinue;
end hasContinousVar;

protected function getCrefFromExp
"Assume input Exp is CREF and return the ComponentRef, fail otherwise."
  input Exp.Exp e;
  output Absyn.ComponentRef c;
algorithm
  c :=
  matchcontinue(e)
    local
      Exp.ComponentRef crefe;
      Absyn.ComponentRef crefa;
    case(DAE.CREF(componentRef = crefe))
      equation
        crefa = Exp.unelabCref(crefe);
      then
        crefa;
    case(e)
      equation
        print("SimCode.getCrefFromExp failed: input was not of type DAE.CREF");
      then
        fail();
  end matchcontinue;
end getCrefFromExp;

protected function isVarDiscrete
  input DAELow.Type tp;
  input DAELow.VarKind kind;
  output Boolean res;
algorithm
  res :=
  matchcontinue (tp, kind)
    case (DAELow.REAL(), DAELow.DISCRETE()) then true;
    case (_, DAELow.DISCRETE()) then true;
    case (DAELow.INT(), _) then true;
    case (DAELow.BOOL(), _) then true;
    case (DAELow.ENUMERATION(_), _) then true;
    case (_,_) then false;
  end matchcontinue;
end isVarDiscrete;

/* TODO: Is this correct? */
protected function isVarAlg
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.VarKind kind;
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* bool variable */
    case (DAELow.VAR(varKind = kind,
                     varType = typeVar as DAELow.BOOL()))
      then false;      
    /* int variable */
    case (DAELow.VAR(varKind = kind,
                     varType = typeVar as DAELow.INT()))
      then false;
    /* string variable */
    case (DAELow.VAR(varKind = kind,
                     varType = typeVar as DAELow.STRING()))
      then false;
    /* non-string variable */
    case (DAELow.VAR(varKind = kind))
      equation
        kind_lst = {DAELow.VARIABLE(), DAELow.DISCRETE(), DAELow.DUMMY_DER(),
                    DAELow.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarAlg;

/* TODO: Is this correct? */
protected function isVarStringAlg
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.VarKind kind;
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* string variable */
    case (DAELow.VAR(varKind = kind,
                     varType = typeVar as DAELow.STRING()))
      equation
        kind_lst = {DAELow.VARIABLE(), DAELow.DISCRETE(), DAELow.DUMMY_DER(),
                    DAELow.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarStringAlg;

protected function isVarIntAlg
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.VarKind kind;
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* int variable */
    case (DAELow.VAR(varKind = kind,
                     varType = typeVar as DAELow.INT()))
      equation
        
        kind_lst = {DAELow.VARIABLE(), DAELow.DISCRETE(), DAELow.DUMMY_DER(),
                    DAELow.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarIntAlg;

protected function isVarBoolAlg
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.VarKind kind;
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* int variable */
    case (DAELow.VAR(varKind = kind,
                     varType = typeVar as DAELow.BOOL()))
      equation
        
        kind_lst = {DAELow.VARIABLE(), DAELow.DISCRETE(), DAELow.DUMMY_DER(),
                    DAELow.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolAlg;

/* TODO: Is this correct? */
protected function isVarParam
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* bool variable */
    case (DAELow.VAR(varType = typeVar as DAELow.BOOL()))
      then false;      
    /* int variable */
    case (DAELow.VAR(varType = typeVar as DAELow.INT()))
      then false;
    /* string variable */
    case (DAELow.VAR(varType = typeVar as DAELow.STRING()))
      then false;
    /* non-string variable */
    case (var)
      equation
        true = DAELow.isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarParam;

/* TODO: Is this correct? */
protected function isVarStringParam
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* string variable */
    case (DAELow.VAR(varType = typeVar as DAELow.STRING()))
      equation
        true = DAELow.isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarStringParam;

protected function isVarIntParam
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* string variable */
    case (DAELow.VAR(varType = typeVar as DAELow.INT()))
      equation
        true = DAELow.isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarIntParam;

protected function isVarBoolParam
  input DAELow.Var var;
  output Boolean result;
algorithm
  result :=
  matchcontinue (var)
    local
      DAELow.Type typeVar;
      list<DAELow.VarKind> kind_lst;
    /* string variable */
    case (DAELow.VAR(varType = typeVar as DAELow.BOOL()))
      equation
        true = DAELow.isParam(var);
      then true;
    case (_)
      then false;
  end matchcontinue;
end isVarBoolParam;

protected function indexSubscriptToExp
  input DAE.Subscript subscript;
  output DAE.Exp exp_;
algorithm
  exp_ :=
  matchcontinue (subscript)
    case (DAE.INDEX(exp_)) then exp_;
    case (_) then DAE.ICONST(99); // TODO: Why do we end up here?
  end matchcontinue;
end indexSubscriptToExp;

protected function isNotBuiltinCall
"Return true if the given DAE.CALL is a call but not to a builtin function."
  input Exp.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean :=
  matchcontinue (inExp)
    local
      Boolean res, builtin;
    case DAE.CALL(builtin=builtin)
      equation
        res = boolNot(builtin);
      then
        res;
    case inExp then false;
  end matchcontinue;
end isNotBuiltinCall;

protected function typesVar
  input Types.Var inTypesVar;
  output Variable outVar;
algorithm
  outVar :=
  matchcontinue(inTypesVar)
    local
      String name;
      Types.Type typesType;
      Exp.Type expType;
    case (DAE.TYPES_VAR(name=name, type_=typesType))
      equation
        expType = Types.elabType(typesType);
      then VARIABLE(DAE.CREF_IDENT(name, expType, {}), expType, NONE, {});
  end matchcontinue;
end typesVar;

protected function dlowvarToSimvar
  input DAELow.Var dlowVar;
  output SimVar simVar;
algorithm
  simVar :=
  matchcontinue (dlowVar)
    local
      Exp.ComponentRef cr, origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      list<Exp.Subscript> inst_dims;
      Integer indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Option<SCode.Comment> comment;
      DAELow.Type tp;
      String orignameStr, commentStr, name, unit, displayUnit;
      Option<DAE.Exp> initVal;
      Boolean isFixed;
      Exp.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
    case ((dlowVar as DAELow.VAR(varName = cr,
                                 varKind = kind,
                                 varDirection = dir,
                                 arryDim = inst_dims,
                                 index = indx,
                                 values = dae_var_attr,
                                 comment = comment,
                                 varType = tp,
                                 flowPrefix = flowPrefix,
                                 streamPrefix = streamPrefix)))
    equation
      commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
      (unit, displayUnit) = extractVarUnit(dae_var_attr);
      initVal = getInitialValue(dlowVar);
      isFixed = DAELow.varFixed(dlowVar);
      type_ = DAELow.makeExpType(tp);
      isDiscrete = isVarDiscrete(tp, kind);
      arrayCref = getArrayCref(dlowVar);
    then
      SIMVAR(cr, kind, commentStr, unit, displayUnit, indx, initVal, isFixed, type_, isDiscrete,
             arrayCref);
  end matchcontinue;
end dlowvarToSimvar;

protected function subsToScalar
"Returns true if subscript results applied to variable or expression results in
scalar expression."
  input list<DAE.Subscript> inExpSubscriptLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExpSubscriptLst)
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
  end matchcontinue;
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
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
  list<list<DAE.Exp>> explists;
algorithm
  explists := Util.listMap1(inExps, getMatchingExps, inFn);
  outExpLst := Util.listFlatten(explists);
end getMatchingExpsList;

protected function getMatchingExps
"function: getMatchingExps
  Return all exps that match the given function.
  Inner exps may be returned separately but not
  extracted from the exp they are in, e.g.
    CALL(foo, {CALL(bar)}) will return
    {CALL(foo, {CALL(bar)}), CALL(bar,{})}
Implementation note: DAE.Exp contains VALUEBLOCKS,
  which can't be processed in Exp due to circular dependencies with DAE.
  In the future, this function should be moved to Exp."
  input DAE.Exp inExp;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
algorithm
  outExpLst:=
  matchcontinue (inExp,inFn)
    local
      list<DAE.Exp> exps,exps2,args,a,b,res,elts,elst,elist;
      DAE.Exp e,e1,e2,e3;
      Absyn.Path path;
      Boolean tuple_,builtin;
      list<tuple<DAE.Exp, Boolean>> flatexplst;
      list<list<tuple<DAE.Exp, Boolean>>> explst;
      Option<DAE.Exp> optexp;
      MatchFn fn;

    // First we check if the function matches
    case (e, fn)
      equation
        res = fn(e);
      then res;

    // Else: Traverse all Exps
    case ((e as DAE.CALL(path = path,expLst = args,tuple_ = tuple_,builtin = builtin)),fn)
      equation
        exps = getMatchingExpsList(args,fn);
      then
        exps;
    case (DAE.PARTEVALFUNCTION(expList = args),fn)
      equation
        res = getMatchingExpsList(args,fn);
      then
        res;
    case (DAE.BINARY(exp1 = e1,exp2 = e2),fn) /* Binary */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.UNARY(exp = e),fn) /* Unary */
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),fn) /* LBinary */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.LUNARY(exp = e),fn) /* LUnary */
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),fn) /* Relation */
      equation
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),fn)
      equation
        res = getMatchingExpsList({e1,e2,e3},fn);
      then
        res;
    case (DAE.ARRAY(array = elts),fn) /* Array */
      equation
        res = getMatchingExpsList(elts,fn);
      then
        res;
    case (DAE.MATRIX(scalar = explst),fn) /* Matrix */
      equation
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        res = getMatchingExpsList(elst,fn);
      then
        res;
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2),fn) /* Range */
      local list<DAE.Exp> e3;
      equation
        e3 = Util.optionToList(optexp);
        elist = listAppend({e1,e2}, e3);
        res = getMatchingExpsList(elist,fn);
      then
        res;
    case (DAE.TUPLE(PR = exps),fn) /* Tuple */
      equation
        res = getMatchingExpsList(exps,fn);
      then
        res;
    case (DAE.CAST(exp = e),fn)
      equation
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = e2),fn) /* Size */
      local Option<DAE.Exp> e2;
      equation
        a = Util.optionToList(e2);
        elist = e1 :: a;
        res = getMatchingExpsList(elist,fn);
      then
        res;

        /* MetaModelica list */
    case (DAE.CONS(_,e1,e2),fn)
      equation
        elist = {e1,e2};
        res = getMatchingExpsList(elist,fn);
      then res;

    case  (DAE.LIST(_,elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;

    case (e as DAE.METARECORDCALL(args = elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;

    case (DAE.META_TUPLE(elist), fn)
      equation
        res = getMatchingExpsList(elist, fn);
      then res;

   case (DAE.META_OPTION(SOME(e1)), fn)
      equation
        res = getMatchingExps(e1, fn);
      then res;

    case(DAE.ASUB(exp = e1),fn)
      equation
        res = getMatchingExps(e1,fn);
        then
          res;

    case(DAE.CREF(_,_),_) then {};

		case (DAE.REDUCTION(expr = e1), fn)
			equation
				res = getMatchingExps(e1, fn);
			then
				res;

    case (DAE.VALUEBLOCK(localDecls = ld,body = body,result = e),fn)
      local
    		list<DAE.Element> ld;
    		list<DAE.Statement> body;
      equation
        exps = DAEUtil.getAllExps(ld);
        exps2 = Algorithm.getAllExpsStmts(body);
        exps = listAppend(exps,exps2);
        res = getMatchingExpsList(e::exps,fn);
      then res;

    case (DAE.ICONST(_),_) then {};
    case (DAE.RCONST(_),_) then {};
    case (DAE.BCONST(_),_) then {};
    case (DAE.SCONST(_),_) then {};
    case (DAE.CODE(_,_),_) then {};
    case (DAE.END(),_) then {};
    case (DAE.META_OPTION(NONE),_) then {};

    case (e,_)
      equation
        Debug.fprintln("failtrace", "- SimCode.getMatchingExps failed: " +& Exp.printExpStr(e));
      then fail();

  end matchcontinue;
end getMatchingExps;

protected function matchCalls
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local list<DAE.Exp> args, exps; DAE.Exp e;
    case (e as DAE.CALL(expLst = args))
      equation
        exps = getMatchingExpsList(args,matchCalls);
      then
        e::exps;
  end matchcontinue;
end matchCalls;

protected function matchMetarecordCalls
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local list<DAE.Exp> args, exps; DAE.Exp e;
    case (e as DAE.METARECORDCALL(args = args))
      equation
        exps = getMatchingExpsList(args,matchMetarecordCalls);
      then
        e::exps;
  end matchcontinue;
end matchMetarecordCalls;

protected function generateExtFunctionIncludes
"function: generateExtFunctionIncludes
  Collects the includes and libs for an external function
  by investigating the annotation of an external function."
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
  output list<String> includes;
  output list<String> libs;
algorithm
  (includes,libs):=
  matchcontinue (inAbsynAnnotationOption)
    local
      list<Absyn.ElementArg> eltarg;
    case (SOME(Absyn.ANNOTATION(eltarg)))
      equation
        libs = generateExtFunctionIncludesLibstr(eltarg);
        includes = generateExtFunctionIncludesIncludestr(eltarg);
      then
        (includes,libs);
    case (NONE()) then ({},{});
  end matchcontinue;
end generateExtFunctionIncludes;

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
    
    // The library is not actually named libLapack.so.
    // Which is a problem, since MSL says it does.
    case Absyn.STRING("Lapack") then {"-llapack"};        
      
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
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      list<Absyn.ElementArg> eltarg;
      list<Absyn.Exp> arr;
      list<String> libs;
      list<list<String>> libsList;
      Absyn.Exp exp;
    case (eltarg)
      equation
        Absyn.CLASSMOD(_,SOME(Absyn.ARRAY(arr))) =
        Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Library",{}));
        libsList = Util.listMap(arr, getLibraryStringInGccFormat); 
      then
        Util.listFlatten(libsList);
    case (eltarg)
      equation
        Absyn.CLASSMOD(_,SOME(exp)) =
        Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Library",{}));
        libs = getLibraryStringInGccFormat(exp);
      then
        libs;
    case (_) then {};
  end matchcontinue;
end generateExtFunctionIncludesLibstr;

protected function generateExtFunctionIncludesIncludestr
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      String inc,inc_1;
      list<Absyn.ElementArg> eltarg;
    case (eltarg)
      equation
        Absyn.CLASSMOD(_,SOME(Absyn.STRING(inc))) = Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Include",{}));
        inc_1 = System.stringReplace(inc, "\\\"", "\"");
      then
        {inc_1};
    case (eltarg) then {};
  end matchcontinue;
end generateExtFunctionIncludesIncludestr;

protected function matchFnRefs
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local 
      DAE.Exp e; 
      DAE.ExpType t;
      list<DAE.Exp> expLst, expLst2;
    case((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = false)))) then {e};
    case(DAE.PARTEVALFUNCTION(ty = DAE.ET_FUNCTION_REFERENCE_VAR(),path=p,expList=expLst))
      local
        DAE.ComponentRef cref; Absyn.Path p;
      equation
        cref = Exp.pathToCref(p);
        e = Exp.makeCrefExp(cref,DAE.ET_FUNCTION_REFERENCE_VAR());
        expLst = getMatchingExpsList(expLst,matchFnRefs);
      then
        e :: expLst;
    case(DAE.CALL(expLst = expLst))
      local
        list<DAE.Exp> record_constructors;
      equation
        expLst2 = getMatchingExpsList(expLst,matchFnRefs);
        record_constructors = getImplicitRecordConstructors(expLst);
        expLst = listAppend(record_constructors, expLst2);
      then
        expLst;
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
        {} = Exp.crefLastSubs(cref);
        // Build a DAE.CREF from the record path.
        cref = Exp.pathToCref(record_path);
        record_cref = Exp.crefExp(cref);
        rest_expr = getImplicitRecordConstructors(rest_expr);
      then record_cref :: rest_expr;
    case (_ :: rest_expr)
      equation
        rest_expr = getImplicitRecordConstructors(rest_expr);
      then rest_expr;
  end matchcontinue;
end getImplicitRecordConstructors;

protected function addDivExpErrorMsgtosimJac
"function addDivExpErrorMsgtosimJac
  helper for addDivExpErrorMsgtoSimEqSystem."
  input tuple<Integer, Integer, SimEqSystem> inJac;
  input tuple<DAELow.Variables,list<DAELow.Var>,DAELow.DivZeroExpReplace> inDlowMode;
  output tuple<Integer, Integer, SimEqSystem> outJac;
  output list<DAE.Exp> outDivLst;
algorithm
  (outJac,outDivLst):=
  matchcontinue (inJac,inDlowMode)
    local
      Integer a,b;
      SimEqSystem ses;
      list<DAE.Exp> divLst;
    case ( inJac as (a,b,ses),inDlowMode) 
      equation
        (ses,divLst) = addDivExpErrorMsgtoSimEqSystem(ses,inDlowMode);
      then
       ((a,b,ses),divLst);   
   end matchcontinue;
end addDivExpErrorMsgtosimJac;
     
protected function addDivExpErrorMsgtoSimEqSystem
"function addDivExpErrorMsgtoSimEqSystem
  Traverses all subexpressions of an expression of an equation."
  input SimEqSystem inSES;
  input tuple<DAELow.Variables,list<DAELow.Var>,DAELow.DivZeroExpReplace> inDlowMode;
  output SimEqSystem outSES;
  output list<DAE.Exp> outDivLst;
algorithm
  (outSES,outDivLst):=
  matchcontinue (inSES,inDlowMode)
    local
      DAE.Exp e, e2;
      DAE.ComponentRef cr;
      Boolean partOfMixed;
      list<SimVar> vars;
      list<DAE.Exp> elst,elst1;
      list<tuple<Integer, Integer, SimEqSystem>> simJac,simJac1;
      Integer index;
      list<DAE.ComponentRef> crefs;
      SimEqSystem cont,cont1;
      list<SimEqSystem> discEqs,discEqs1;
      list<String> values;
      list<Integer> value_dims;
      list<tuple<DAE.Exp, Integer>> conditions;
      list<DAE.Exp> divLst,divLst1,divLst2;
    case (SES_RESIDUAL(exp = e),inDlowMode)
      equation
        (e,divLst) = DAELow.addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_RESIDUAL(e),divLst);      
    case (SES_SIMPLE_ASSIGN(cref = cr, exp = e),inDlowMode)
      equation
        (e,divLst) = DAELow.addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_SIMPLE_ASSIGN(cr, e),divLst);      
    case (SES_ARRAY_CALL_ASSIGN(componentRef = cr, exp = e),inDlowMode)
      equation
        (e,divLst) = DAELow.addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_ARRAY_CALL_ASSIGN(cr, e),divLst);      
/*
    case (SES_ALGORITHM(),inDlowMode)
      equation
        e = DAELow.addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        SES_ALGORITHM();
*/              
    case (SES_LINEAR(partOfMixed = partOfMixed,vars = vars, beqs = elst, simJac = simJac),inDlowMode)
      equation
        (simJac1,divLst) = listMap1_2(simJac,addDivExpErrorMsgtosimJac,inDlowMode);
        (elst1,divLst1) = listMap1_2(elst,DAELow.addDivExpErrorMsgtoExp,inDlowMode);
        divLst2 = listAppend(divLst,divLst1);
      then
        (SES_LINEAR(partOfMixed,vars,elst1,simJac1),divLst2);      
    case (SES_NONLINEAR(index = index,eqs = discEqs, crefs = crefs),inDlowMode)
      equation
        (discEqs,divLst) =  listMap1_2(discEqs,addDivExpErrorMsgtoSimEqSystem,inDlowMode);
      then
        (SES_NONLINEAR(index,discEqs,crefs),divLst);      
    case (SES_MIXED(cont = cont,discVars = vars, discEqs = discEqs, values = values, value_dims = value_dims),inDlowMode)
      equation
        (cont1,divLst) = addDivExpErrorMsgtoSimEqSystem(cont,inDlowMode);
        (discEqs1,divLst1) = listMap1_2(discEqs,addDivExpErrorMsgtoSimEqSystem,inDlowMode);
        divLst2 = listAppend(divLst,divLst1);
      then
        (SES_MIXED(cont1,vars,discEqs1,values,value_dims),divLst2);      
    case (SES_WHEN(left = cr, right = e, conditions = conditions),inDlowMode)
      equation
        (e,divLst) = DAELow.addDivExpErrorMsgtoExp(e,inDlowMode);
      then
        (SES_WHEN(cr,e,conditions),divLst);
    case (inSES,_) then (inSES,{});
  end matchcontinue;
end addDivExpErrorMsgtoSimEqSystem;

protected function generateParameterDivisionbyZeroTestEqn "
Author: Frenkel TUD 2010-04"
  input DAE.Exp inExp;
  output DAE.Statement outStm;
algorithm outStm := matchcontinue(inExp)
  local
    DAE.Exp e;
  case(inExp) then DAE.STMT_NORETCALL(inExp,DAE.emptyElementSource);
end matchcontinue;
end generateParameterDivisionbyZeroTestEqn;

public function listMap1_2 "
  Takes a list and a function over the elements and an additional argument returning a tuple of
  two types, which is applied for each element producing two new lists.
  See also listMap_2.
  "
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
  matchcontinue (inTypeALst,inFuncTypeTypeAToTypeBTypeC,extraArg)
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
  end matchcontinue;
end listMap1_2;
  
protected function solve
  input Exp.Exp lhs;
  input Exp.Exp rhs;
  input Exp.Exp exp;
  output Exp.Exp solvedExp;
algorithm
  solvedExp := matchcontinue(lhs, rhs, exp)
    local
      DAE.ComponentRef cr;
      Exp.Exp e1, e2, solved_exp;
    case (_, _, DAE.CREF(componentRef = cr))
      equation
        false = crefIsDerivative(cr);
        solved_exp = Exp.solve(lhs, rhs, exp);
      then
        solved_exp;    
    case (_, _, DAE.CREF(componentRef = cr))
      equation
        true = crefIsDerivative(cr);
        e1 = replaceDerOpInExpCond(lhs, cr);
        e2 = replaceDerOpInExpCond(rhs, cr);
        solved_exp = Exp.solve(e1, e2, exp);
      then
        solved_exp;
  end matchcontinue;
end solve;

protected function crefIsDerivative
  "Returns true if a component reference is a derivative, otherwise false."
  input DAE.ComponentRef cr;
  output Boolean isDer;
algorithm
  isDer := matchcontinue(cr)
    case (DAE.CREF_QUAL(ident = "$DER")) then true;
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
        unitStr = Exp.printExpStr(uexp);
        unitStr = System.stringReplace(unitStr,"\"","");
        unitStr = System.stringReplace(unitStr,"\\","\\\\");
        displayUnitStr = Exp.printExpStr(duexp);
        displayUnitStr = System.stringReplace(displayUnitStr,"\"","");        
        displayUnitStr = System.stringReplace(displayUnitStr,"\\","\\\\");
      then (unitStr, displayUnitStr);
    case ( SOME(DAE.VAR_ATTR_REAL(unit = SOME(uexp), displayUnit = NONE)) )
      equation
        unitStr = Exp.printExpStr(uexp);
        unitStr = System.stringReplace(unitStr,"\"","");
        unitStr = System.stringReplace(unitStr,"\\","\\\\");
      then (unitStr, unitStr);        
    case (_)
      then ("","");
  end matchcontinue;
end extractVarUnit;

protected function getInitialValue
"Extract initial value from DAELow.Variable, if it has any

(merged and modified generateInitData3 and generateInitData4)"
  input DAELow.Var daelowVar;
  output Option<DAE.Exp> initVal;
algorithm
  initVal := matchcontinue(daelowVar)
    local
      Option<DAE.VariableAttributes> dae_var_attr;
      Values.Value value;
      DAE.Exp e;
    case (DAELow.VAR(varKind = DAELow.VARIABLE(), varType = DAELow.STRING(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (DAELow.VAR(varKind = DAELow.VARIABLE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (DAELow.VAR(varKind = DAELow.DISCRETE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (DAELow.VAR(varKind = DAELow.STATE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (DAELow.VAR(varKind = DAELow.DUMMY_DER(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (DAELow.VAR(varKind = DAELow.DUMMY_STATE(), values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttrFail(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (DAELow.VAR(varKind = DAELow.PARAM(), varType = DAELow.STRING(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (DAELow.VAR(varKind = DAELow.PARAM(), bindValue = SOME(value)))
      equation
        e = ValuesUtil.valueExp(value);
        true = Exp.isConst(e);
      then
        SOME(e);
    /* String - Parameters without value binding. Investigate if it has start value */
    case (DAELow.VAR(varKind = DAELow.PARAM(), varType = DAELow.STRING(), bindValue = NONE, values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    /* Parameters without value binding. Investigate if it has start value */
    case (DAELow.VAR(varKind = DAELow.PARAM(), bindValue = NONE, values = dae_var_attr))
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        true = Exp.isConst(e);
      then
        SOME(e);
    case (_) then NONE();
  end matchcontinue;
end getInitialValue;

end SimCode;
