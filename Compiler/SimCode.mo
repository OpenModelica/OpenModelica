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

protected import DAEUtil;
protected import SCodeUtil;
protected import ClassInf;
protected import SimCodeC;
protected import SimCodeCSharp;
protected import Util;
protected import Debug;
protected import Error;
protected import Inst;
protected import InnerOuter;
protected import Settings;
protected import RTOpts;
protected import System;
protected import VarTransform;
protected import CevalScript;
protected import ModUtil;


public
type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
type ExtDestructor = tuple<String, DAE.ComponentRef>;
type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;
type HelpVarInfo = tuple<Integer, Exp.Exp, Integer>; // helpvarindex, expression, whenclause index


// Root data structure containing information required for templates to
// generate simulation code for a Modelica model.
uniontype SimCode
  record SIMCODE
    ModelInfo modelInfo;
    list<Function> functions;
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
    list<tuple<DAE.Exp, DAE.Exp>> delayedExps;
  end SIMCODE;
end SimCode;

// Root data structure containing information required for templates to
// generate C functions for Modelica/MetaModelica functions.
uniontype FunctionCode
  record FUNCTIONCODE
    String name;
    list<Function> functions;
    MakefileParams makefileParams;
    list<RecordDeclaration> extraRecordDecls;
  end FUNCTIONCODE;
end FunctionCode;

// Container for metadata about a Modelica model.
uniontype ModelInfo
  record MODELINFO
    String name;
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
    Integer numStateVars;
    Integer numAlgVars;
    Integer numParams;
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
    list<SimVar> inputVars;
    list<SimVar> outputVars;
    list<SimVar> paramVars;
    list<SimVar> stringAlgVars;
    list<SimVar> stringParamVars;
    list<SimVar> extObjVars;
  end SIMVARS;
end SimVars;

// Information about a variable in a Modelica model.
uniontype SimVar
  record SIMVAR
    DAE.ComponentRef name;
    DAE.ComponentRef origName;
    String comment;
    Integer index;
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
    list<String> includes;
    list<String> libs;
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
    //the name should become a Path because templates will take responsibility
    //for ident encodings an alternative is to expect names with dot notation
    //inside the string; an encoding function sholud be then imported
    DAE.ComponentRef name;
    Exp.Type ty;
    Option<Exp.Exp> value; // Default value
    list<DAE.Exp> instDims;
  end VARIABLE;
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
    DAE.ComponentRef componentRef;
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
    list<String> libs;
  end MAKEFILE_PARAMS;
end MakefileParams;

// Constants of this type defined below are used by templates to be able to
// generate different code depending on the context it is generated in.
uniontype Context
  record SIMULATION
    Boolean genDiscrete;
  end SIMULATION;
  record OTHER
  end OTHER;
end Context;


public constant Context contextSimulationNonDescrete = SIMULATION(false);
public constant Context contextSimulationDescrete    = SIMULATION(true);
public constant Context contextOther                 = OTHER();


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
  len := listLength(subs);
  noSub := len == 0;
end crefNoSub;

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
        subs = Util.listFlatten({subs1, subs2});
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

public function translateModel
"Entry point to translate a Modelica model for simulation.
    
 Called from other places in the compiler."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path className "path for the model";
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  input Ceval.Msg inMsg;
  input Exp.Exp inExp;
  input Boolean addDummy "if true, add a dummy state";
  output Env.Cache outCache;
  output Values.Value outValue;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
  output DAELow.DAELow outDAELow;
  output list<String> outStringLst;
  output String outString;
algorithm
  (outCache,outValue,outInteractiveSymbolTable,outDAELow,outStringLst,outString):=
  matchcontinue (inCache,inEnv,className,inInteractiveSymbolTable,inMsg,inExp,addDummy)
    local
      String filenameprefix,cname_str,filename,funcfilename,makefilename,file_dir;
      Absyn.Path classname;
      list<SCode.Class> p_1,sp;
      DAE.DAElist dae_1,dae;
      list<Env.Frame> env;
      list<DAE.Element> dael;
      list<Interactive.InstantiatedClass> ic_1,ic;
      DAELow.DAELow dlow,dlow_1,indexed_dlow,indexed_dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Exp.ComponentRef cr;
      Interactive.InteractiveSymbolTable st;
      Absyn.Program p,ptot;
      list<Interactive.InteractiveVariable> iv;
      list<Interactive.CompiledCFunction> cf;
      Ceval.Msg msg;
      Exp.Exp fileprefix;
      Env.Cache cache;
      String MakefileHeader;
      Values.Value outValMsg;
      SimCode simCode;
      list<Function> functions;
    case (cache,env,className,(st as Interactive.SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)),msg,fileprefix,addDummy)
      equation
        /* calculate stuff that we need to create SimCode data structure */
        (cache,Values.STRING(filenameprefix),SOME(_)) = Ceval.ceval(cache,env, fileprefix, true, SOME(st), NONE, msg);
        ptot = Dependency.getTotalProgram(className,p);
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env,_,dae) = Inst.instantiateClass(cache,InnerOuter.emptyInstHierarchy,p_1,className);
        dae = DAEUtil.transformIfEqToExpr(dae,false);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dae,env));
        dlow = DAELow.lower(dae, addDummy, true);
        Debug.fprint("bltdump", "Lowered DAE:\n");
        Debug.fcall("bltdump", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        (ass1,ass2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, (DAELow.INDEX_REDUCTION(),DAELow.EXACT(),DAELow.REMOVE_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m, mT, ass1, ass2);
        indexed_dlow = DAELow.translateDae(dlow_1,NONE);
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        Debug.fprint("bltdump", "indexed DAE:\n");
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("bltdump", DAELow.dump, indexed_dlow_1);
        Debug.fcall("bltdump", DAELow.dumpMatching, ass1);
        cname_str = Absyn.pathString(className);
        filename = Util.stringAppendList({filenameprefix,".cpp"});
        Debug.fprintln("dynload", "translateModel: Generating simulation code and functions.");
        funcfilename = Util.stringAppendList({filenameprefix,"_functions.cpp"});
        makefilename = Util.stringAppendList({filenameprefix,".makefile"});
        a_cref = Absyn.pathToCref(className);
        file_dir = CevalScript.getFileDir(a_cref, p);
        /* create SimCode data structure */
        (libs, functions) = createFunctions(p_1, dae, indexed_dlow_1,
                                            className, filenameprefix);
        simCode = createSimCode(dae, indexed_dlow_1, ass1, ass2, m, mT, comps,
                                className, filename, funcfilename,file_dir,
                                functions, libs);

        callTargetTemplates(simCode);
      then
        (cache,Values.STRING("SimCode: The model has been translated"),st,indexed_dlow_1,libs,file_dir);
  end matchcontinue;
end translateModel;

public function translateFunctions
"Entry point to translate Modelica/MetaModelica functions to C functions.
    
 Called from other places in the compiler."
  input String name;
  input list<DAE.Element> daeElements;
  input list<DAE.Type> metarecordTypes;
algorithm
  _ :=
  matchcontinue (name, daeElements, metarecordTypes)
    local
      list<Function> fns;
      list<String> libs;
      MakefileParams makefileParams;
      FunctionCode fnCode;
      list<RecordDeclaration> extraRecordDecls;
    case (name, daeElements, metarecordTypes)
      equation
        // Create FunctionCode
        (fns, extraRecordDecls) = elaborateFunctions(daeElements, metarecordTypes);
        libs = extractLibs(fns);
        makefileParams = createMakefileParams(libs);
        fnCode = FUNCTIONCODE(name, fns, makefileParams, extraRecordDecls);
        // Generate code
        _ = Tpl.tplString(SimCodeC.translateFunctions, fnCode);
      then
        ();
  end matchcontinue;
end translateFunctions;


/* Finds the called functions in DAELow and transforms them to a list of
   libraries and a list of Function uniontypes. */
protected function createFunctions
  input SCode.Program inProgram;
  input DAE.DAElist inDAElist;
  input DAELow.DAELow inDAELow;
  input Absyn.Path inPath;
  input String inString;
  output list<String> libs;
  output list<Function> functions;
algorithm
  (libs, functions) :=
  matchcontinue (inProgram,inDAElist,inDAELow,inPath,inString)
    local
      list<Absyn.Path> funcpaths;
      list<String> debugpathstrs,libs1,libs2,includes;
      String debugpathstr,debugstr,filenameprefix, str;
      list<DAE.Element> funcelems,elements;
      list<SCode.Class> p;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Absyn.Path path;
      list<Function> fns;
      SimCode sc;
    case (p,(dae as DAE.DAE(elementLst = elements)),dlow,path,filenameprefix)
      equation
        funcpaths = getCalledFunctions(dae, dlow);
        //Debug.fprint("info", "Found called functions: ") "debug" ;
        //debugpathstrs = Util.listMap(funcpaths, Absyn.pathString) "debug" ;
        //debugpathstr = Util.stringDelimitList(debugpathstrs, ", ") "debug" ;
        //Debug.fprintln("info", debugpathstr) "debug" ;
        funcelems = generateFunctions2(p, funcpaths);
        //debugstr = Print.getString();
        //Print.clearBuf();
        //Debug.fprintln("info", "Generating functions, call Codegen.\n") "debug" ;
        (_, libs1) = generateExternalObjectIncludes(dlow);
        //libs1 = {};
        //usless filter, all are already functions from generateFunctions2
        //funcelems := Util.listFilter(funcelems, DAEUtil.isFunction);
        (fns, _) = elaborateFunctions(funcelems, {}); // Do we need metarecords here as well?
        //TODO: libs ? see in Codegen.cPrintFunctionIncludes(cfns)
        libs2 = extractLibs(fns);
      then
        (Util.listUnion(libs1,libs2), fns);
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Creation of Modelica functions failed. "});
      then
        fail();
  end matchcontinue;
end createFunctions;

protected function getCalledFunctions
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
  input list<DAE.Element> daeElements;
  input list<DAE.Type> metarecordTypes;
  output list<Function> functions;
  output list<RecordDeclaration> extraRecordDecls;
protected
  list<Function> fns;
  list<String> outRecordTypes;
algorithm
  (fns, outRecordTypes) := elaborateFunctions2(daeElements, {},{});
  functions := listReverse(fns); // Is there a reason why we reverse here?
  (extraRecordDecls,_) := elaborateRecordDeclarationsFromTypes(metarecordTypes, {}, outRecordTypes);
end elaborateFunctions;

protected function elaborateFunctions2
  input list<DAE.Element> daeElements;
  input list<Function> inFunctions;
  input list<String> inRecordTypes;
  output list<Function> outFunctions;
  output list<String> outRecordTypes;
algorithm
  (outFunctions, outRecordTypes) :=
  matchcontinue (daeElements, inFunctions, inRecordTypes)
    local
      list<Function> accfns, fns;
      Function fn;
      list<String> rt, rt_1, rt_2;
      DAE.Element fel;
      list<DAE.Element> rest;
    case ({}, accfns, rt)
      then (accfns, rt);
    case ((DAE.FUNCTION(partialPrefix = true) :: rest), accfns, rt)
      equation
        // skip over partial functions
        (fns, rt_2) = elaborateFunctions2(rest, accfns, rt);
      then
        (fns, rt_2);
    case ((fel :: rest), accfns, rt)
      equation
        (fn, rt_1) = elaborateFunction(fel, rt);
        (fns, rt_2) = elaborateFunctions2(rest, (fn :: accfns), rt_1);
      then
        (fns, rt_2);
  end matchcontinue;
end elaborateFunctions2;

/* Does the actual work of transforming a DAE.FUNCTION to a Function. */
protected function elaborateFunction
  input DAE.Element inElement;
  input list<String> inRecordTypes;
  output Function outFunction;
  output list<String> outRecordTypes;
algorithm
  (outFunction,outRecordTypes):=
  matchcontinue (inElement,inRecordTypes)
    local
      String fn_name_str,fn_name_str_1,retstr,extfnname,lang,retstructtype,extfnname_1,n,str;
      list<DAE.Element> dae,bivars,orgdae,daelist,funrefs, algs, vars, invars, outvars;
      list<String> struct_strs,arg_strs,includes,libs,struct_strs_1,funrefStrs;
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
      list<String> rt, rt_1, struct_funrefs, struct_funrefs_int;
      list<Absyn.Path> funrefPaths;
      list<Variable> outVars, inVars, biVars, funArgs, varDecls;
      list<RecordDeclaration> recordDecls;
      list<Statement> body;
      DAE.InlineType inl;
      list<DAE.Element> daeElts;

    /* Modelica functions. */
    case (DAE.FUNCTION(path = fpath,
                       functions = {DAE.FUNCTION_DEF(body = daeElts)},
                       type_ = tp as (DAE.T_FUNCTION(funcArg=args, funcResultType=restype), _),
                       partialPrefix=false), rt)
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
        (FUNCTION(fpath,inVars,outVars,recordDecls,funArgs,varDecls,body),
         rt_1);
    /* External functions. */
    case (DAE.FUNCTION(path = fpath,
                       functions = {DAE.FUNCTION_EXT(body =  daeElts, externalDecl = extdecl)},
                       type_ = (tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_))),rt)
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
        (includes, libs) = generateExtFunctionIncludes(ann);
        simextargs = Util.listMap(extargs, extArgsToSimExtArgs);
        extReturn = extArgsToSimExtArgs(extretarg);
        (simextargs, extReturn) = fixOutputIndex(outVars, simextargs, extReturn);
      then
        (EXTERNAL_FUNCTION(fpath, extfnname, funArgs, simextargs, extReturn,
                           inVars, outVars, biVars, includes, libs, lang,
                           recordDecls),
         rt_1);
    /* Record constructor. */
    case (DAE.RECORD_CONSTRUCTOR(path = fpath, type_ = tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)),_)),_)), rt)
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
        (RECORD_CONSTRUCTOR(name, funArgs, recordDecls),
         rt_1);
    case (comp,rt)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.elaborateFunction failed"});
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
    //TODO: componentRef ?? can it be something other than CREF_IDENT here ?
    case (DAE.VAR(componentRef = id,
                  kind = DAE.VARIABLE(),
                  ty = daeType,
                  dims = inst_dims
                 ))
      equation
        expType = Types.elabType(daeType);
        inst_dims_exp = Util.listMap(inst_dims, indexSubscriptToExp);
      then VARIABLE(id,expType,NONE,inst_dims_exp);
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
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input DAELow.IncidenceMatrix inIncidenceMatrix5;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT6;
  input list<list<Integer>> inIntegerLstLst7;
  input Absyn.Path inPath8;
  input String inString9;
  input String inString10;
  input String inString11;
  input list<Function> functions;
  input list<String> libs;
  output SimCode simCode;
algorithm
  simCode :=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inIntegerLstLst7,inPath8,inString9,inString10,inString11,functions,libs)
    local
      String cname,out_str,in_str,c_eventchecking,s_code2,s_code3,cglobal,coutput,cstate,c_ode,s_code,cwhen,
      	czerocross,filename,funcfilename,fileDir;
      String extObjInclude; list<String> extObjIncludes;
      list<list<Integer>> blt_states,blt_no_states,comps;
      list<list<Integer>> contBlocks,discBlocks;
      Integer n_o,n_i,n_h,nres;
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
      list<tuple<DAE.Exp, DAE.Exp>> delayedExps;
      list<DAE.Exp> divLst;
      list<DAE.Statement> allDivStmts;
    case (dae,dlow,ass1,ass2,m,mt,comps,class_,filename,funcfilename,fileDir,functions,libs)
      equation
        cname = Absyn.pathString(class_);

        (blt_states, blt_no_states) = DAELow.generateStatePartition(comps, dlow, ass1, ass2, m, mt);

        (helpVarInfo, dlow2) = generateHelpVarInfo(dlow, comps);
        //(out_str,n_o) = generateOutputFunctionCode(dlow2);
        //(in_str,n_i) = generateInputFunctionCode(dlow2);
        n_h = listLength(helpVarInfo);

        residualEquations = createResidualEquations(dlow2, ass1, ass2);
        nres = listLength(residualEquations);

        //(s_code3) = generateInitialBoundParameterCode(dlow2);
        //cglobal = generateGlobalData(class_, dlow2, n_o, n_i, n_h, nres,fileDir);
        //coutput = generateComputeOutput(cname, dae, dlow2, ass1, ass2,m,mt, blt_no_states);
        //cstate = generateComputeResidualState(cname, dae, dlow2, ass1, ass2, blt_states);
        //c_ode = generateOdeCode(dlow2, blt_states, ass1, ass2, m, mt, class_);
        //s_code = generateInitialValueCode(dlow2);
        //cwhen = generateWhenClauses(cname, dae, dlow2, ass1, ass2, comps);
        //czerocross = generateZeroCrossing(cname, dae, dlow2, ass1, ass2, comps, helpVarInfo);
        extObjInfo = createExtObjInfo(dlow2);
        //extObjInclude = Util.stringDelimitList(extObjIncludes,"\n");
        //extObjInclude = Util.stringAppendList({"extern \"C\" {\n",extObjInclude,"\n}\n"});
        // Add model info
        modelInfo = createModelInfo(class_, dlow2, n_h, nres, fileDir);
        allEquations = createEquations(false, false, true, dae, dlow2, ass1, ass2, comps, helpVarInfo);
        allEquationsPlusWhen = createEquations(true, false, true, dae, dlow2, ass1, ass2, comps, helpVarInfo);
        stateContEquations = createEquations(false, false, false, dae, dlow2, ass1, ass2, blt_states, helpVarInfo);
        (contBlocks, discBlocks) = splitOutputBlocks(dlow2, ass1, ass2, m, mt, blt_no_states);
        nonStateContEquations = createEquations(false, false, true, dae, dlow2, ass1, ass2,
                                                contBlocks, helpVarInfo);
        nonStateDiscEquations = createEquations(false, useZerocrossing(), true, dae, dlow2, ass1, ass2,
                                                discBlocks, helpVarInfo);
        initialEquations = createInitialEquations(dlow2);
        parameterEquations = createParameterEquations(dlow2);
        removedEquations = createRemovedEquations(dlow2);
        algorithmAndEquationAsserts = createAlgorithmAndEquationAsserts(dlow2);
        zeroCrossings = createZeroCrossings(dlow2);
        zeroCrossingsNeedSave = createZeroCrossingsNeedSave(zeroCrossings, dae, dlow2, ass1, ass2, comps);
        whenClauses = createSimWhenClauses(dlow2);
        discreteModelVars = extractDiscreteModelVars(dlow2, mt);
        makefileParams = createMakefileParams(libs);
        delayedExps = extractDelayedExpressions(dlow2);
        
        // replace div operator with div operator with check of Division by zero
        (allEquations,divLst) = listMap1_2(allEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ONLY_VARIABLES()));        
        (allEquationsPlusWhen,_) = listMap1_2(allEquationsPlusWhen,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ONLY_VARIABLES()));        
        (stateContEquations,_) = listMap1_2(stateContEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ONLY_VARIABLES()));        
        (nonStateContEquations,_) = listMap1_2(nonStateContEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ONLY_VARIABLES()));        
        (nonStateDiscEquations,_) = listMap1_2(nonStateDiscEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ONLY_VARIABLES()));        
        (residualEquations,_) = listMap1_2(residualEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ALL()));        
        (initialEquations,_) = listMap1_2(initialEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ALL()));        
        (parameterEquations,_) = listMap1_2(parameterEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ALL()));        
        (removedEquations,_) = listMap1_2(removedEquations,addDivExpErrorMsgtoSimEqSystem,(dlow,DAELow.ONLY_VARIABLES()));        
        // add equations with only parameters as division expression
        allDivStmts = Util.listMap(divLst,generateParameterDivisionbyZeroTestEqn);
        parameterEquations = listAppend(parameterEquations,{SES_ALGORITHM(allDivStmts)});
        
        simCode = SIMCODE(modelInfo, functions, allEquations, allEquationsPlusWhen, stateContEquations,
                          nonStateContEquations, nonStateDiscEquations,
                          residualEquations, initialEquations,
                          parameterEquations, removedEquations,
                          algorithmAndEquationAsserts, zeroCrossings,
                          zeroCrossingsNeedSave, helpVarInfo, whenClauses,
                          discreteModelVars, extObjInfo, makefileParams,
                          delayedExps);
      then
        simCode;
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of simulation using code using templates failed"});
      then
        fail();
  end matchcontinue;
end createSimCode;

protected function extractDelayedExpressions
  input DAELow.DAELow dlow;
  output list<tuple<DAE.Exp, DAE.Exp>> delayedExps;
algorithm
  delayedExps := matchcontinue(dlow)
    local
      list<DAE.Exp> exps;
      list<list<DAE.Exp>> subexps;
    case (dlow)
      equation
        exps = DAELow.getAllExps(dlow);
        subexps = Util.listMap(exps, DAELow.findDelaySubExpressions);
        exps = Util.listFlatten(subexps);
        delayedExps = Util.listMap(exps, extractIdAndExpFromDelayExp);
      then
        delayedExps;
  end matchcontinue;
end extractDelayedExpressions;

function extractIdAndExpFromDelayExp
  input DAE.Exp delayCallExp;
  output tuple<DAE.Exp, DAE.Exp> delayedExp;
algorithm
  delayedExp :=
  matchcontinue (delayCallExp)
    local
      DAE.Exp id, e, delay, delayMax;
    case (DAE.CALL(path=Absyn.IDENT("delay"), expLst={id,e,delay,delayMax}))
      then ((id, e));
  end matchcontinue;
end extractIdAndExpFromDelayExp;

protected function createMakefileParams
  input list<String> libs;
  output MakefileParams makefileParams;
algorithm
  makefileParams :=
  matchcontinue (libs)
    local
      String omhome,header,ccompiler,cxxcompiler,linker,exeext,dllext,cflags,ldflags;
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
      then MAKEFILE_PARAMS(ccompiler, cxxcompiler, linker, exeext, dllext,
                           omhome, cflags, ldflags, libs);
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

      eqns = mT[varIndx+1]; // eqns continaing var
      true = crefNotInWhenEquation(cr,daelow,eqns);
      outString = buildDiscreteVarChangesAddEvent(0,cr);

  		/*strLst = Util.listMap2(eqns,buildDiscreteVarChangesVar2,cr,daelow);
  		outString = Util.stringDelimitList(strLst,"\n");*/

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
    case(cr,daelow as DAELow.DAELOW(orderedEqs=eqs),e::eqns) equation
      DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(_,cr2,exp,_)) = DAELow.equationNth(eqs,intAbs(e)-1);
      //We can asume the same component refs are solved in any else-branch.
      b1 = Exp.crefEqual(cr,cr2);
      b2 = Exp.expContains(exp,DAE.CREF(cr,DAE.ET_OTHER()));
      true = boolOr(b1,b2);
    then false;
    case(cr,daelow,_::eqns) equation
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
        _ = Tpl.tplString(SimCodeCSharp.translateModel, simCode);
      then ();
    case (simCode)
      equation
        false = RTOpts.debugFlag("CSharp");
        _ = Tpl.tplString(SimCodeC.translateModel, simCode);
      then ();
  end matchcontinue;
end callTargetTemplates;

protected function extractLibs
  input list<Function> fns;
  output list<String> libs;
algorithm
  libs :=
  matchcontinue (fns)
    local
      list<Function> restFns;
      list<String> fnLibs;
      list<String> libs;
      list<String> restLibs;
    case ({})
      then {};
    case (EXTERNAL_FUNCTION(libs=fnLibs) :: restFns)
      equation
        restLibs = extractLibs(restFns);
        libs = Util.listUnion(fnLibs, restLibs);
      then (libs);
    case (_ :: restFns)
      equation
        libs = extractLibs(restFns);
      then (libs);
  end matchcontinue;
end extractLibs;

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
        vLst = Util.listSelect2(vLst, dlow, mT, varNotSolvedInWhen);
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
  output list<SimWhenClause> simWhenClauses;
algorithm
  simWhenClauses :=
  matchcontinue (dlow)
    local
      list<DAELow.WhenClause> wc;
    case (DAELow.DAELOW(eventInfo=DAELow.EVENT_INFO(whenClauseLst=wc)))
      equation
        //simWhenClauses = Util.listMap(wc, whenClauseToSimWhenClause);
        simWhenClauses = createSimWhenClausesWithEqs(wc, dlow, 0);
      then
        simWhenClauses;
  end matchcontinue;
end createSimWhenClauses;

protected function createSimWhenClausesWithEqs
  input list<DAELow.WhenClause> whenClauses;
  input DAELow.DAELow dlow;
  input Integer currentWhenClauseIndex;
  output list<SimWhenClause> simWhenClauses;
algorithm
  simWhenClauses :=
  matchcontinue (whenClauses, dlow, currentWhenClauseIndex)
    local
      DAELow.WhenClause whenClause;
      list<DAELow.WhenClause> wc;
      DAELow.EquationArray eqs;
      list<DAELow.Equation> eqsLst;
      Option<DAELow.WhenEquation> whenEq;
      SimWhenClause simWhenClause;
      Integer nextIndex;
      list<SimWhenClause> simWhenClauses;
    case ({}, _, _)
      then {};
    case (whenClause :: wc, DAELow.DAELOW(orderedEqs=eqs), currentWhenClauseIndex)
      equation
        eqsLst = DAELow.equationList(eqs);
        whenEq = findWhenEquation(eqsLst, currentWhenClauseIndex);
        simWhenClause = whenClauseToSimWhenClause(whenClause, whenEq);
        nextIndex = currentWhenClauseIndex + 1;
        simWhenClauses = createSimWhenClausesWithEqs(wc, dlow, nextIndex);
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
  output SimWhenClause simWhenClause;
algorithm
  simWhenClause :=
  matchcontinue (whenClause, whenEq)
    local
      DAE.Exp cond;
      list<DAELow.ReinitStatement> reinits;
      list<DAE.ComponentRef> conditionVars;
    case (DAELow.WHEN_CLAUSE(condition=cond, reinitStmtLst=reinits), whenEq)
      equation
        conditionVars = Exp.getCrefFromExp(cond);
      then
        SIM_WHEN_CLAUSE(conditionVars, reinits, whenEq);
  end matchcontinue;
end whenClauseToSimWhenClause;

protected function createEquations
  input Boolean includeWhen;
  input Boolean skipDiscInZc;
  input Boolean genDiscrete;
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<list<Integer>> comps;
  input list<HelpVarInfo> helpVarInfo;
  output list<SimEqSystem> equations;
algorithm
  equations :=
  matchcontinue (includeWhen, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, comps, helpVarInfo)
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
    case (includeWhen, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, {}, helpVarInfo)
      then {};
    /* ignore when equations if we should not generate them */
    case (false, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.WHEN_EQUATION(_,_),_) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        equations = createEquations(false, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equations;
    /* ignore discrete if we should not generate them */
    case (includeWhen, skipDiscInZc, false, dae, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.EQUATION(_,_,_),v) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        true = hasDiscreteVar({v});
        equations = createEquations(includeWhen, skipDiscInZc, false, dae, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equations;
    /* ignore discrete in zero crossing if we should not generate them */
    case (includeWhen, true, genDiscrete, dae, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.EQUATION(_,_,_),v) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        true = hasDiscreteVar({v});
        zcEqns = DAELow.zeroCrossingsEquations(dlow);
        true = listMember(index, zcEqns);
        equations = createEquations(includeWhen, true, genDiscrete, dae, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equations;
    /* single equation */
    case (includeWhen, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, {index} :: restComps, helpVarInfo)
      equation
        equation_ = createEquation(index, dlow, ass1, ass2, helpVarInfo);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, restComps, helpVarInfo);
      then
        equation_ :: equations;
    /* multiple equations that must be solved together (algebraic loop) */
    case (includeWhen, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, (comp as (_ :: (_ :: _))) :: restComps, helpVarInfo)
      local
        list<SimEqSystem> equations_,equations1;
      equation
        equations_ = createOdeSystem(genDiscrete, dlow, ass1, ass2, comp, helpVarInfo);
        equations = createEquations(includeWhen, skipDiscInZc, genDiscrete, dae, dlow, ass1, ass2, restComps, helpVarInfo);
        equations1 = listAppend(equations_,equations); 
      then
        equations1;
    case (_,_,_,_,_,_,_,_,_)
      equation
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
        (DAELow.EQUATION(e1, e2,_),
         v as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,
                         flowPrefix,streamPrefix))
        = getEquationAndSolvedVar(eqNum, eqns, vars, ass2);
        isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        exp_ = Exp.solve(e1, e2, varexp);
      then
        SES_SIMPLE_ASSIGN(cr, exp_);
    /* single equation: state */
    case (eqNum,
          DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns),
          ass1, ass2, helpVarInfo)
      equation
        (DAELow.EQUATION(e1, e2,_),
         v as DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,
                         dae_var_attr,comment, flowPrefix,streamPrefix))
        = getEquationAndSolvedVar(eqNum, eqns, vars, ass2);
        varname = Exp.printComponentRefStr(cr);
        id = Util.stringAppendList({DAELow.derivativeNamePrefix, varname});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        exp_ = Exp.solve(e1, e2, varexp);
      then
        SES_SIMPLE_ASSIGN(cr_1, exp_);
    /* non-state non-linear */
    case (e,
          DAELow.DAELOW(orderedVars=vars,orderedEqs=eqns,arrayEqs=ae),
          ass1, ass2, helpVarInfo)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(cr,kind,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        isNonState(kind);
        //indxs = intString(indx);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        //(res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr}, {eqn},ae, cg_id);
        index = tick();
        index = eqNum; // Use the equation number as unique index
        repl = makeResidualReplacements({cr});
        resEqs = createNonlinearResidualEquations({eqn}, ae, repl);
      then
        SES_NONLINEAR(index, resEqs, {cr});
    /* state nonlinear */
    case (e,
          DAELow.DAELOW(orderedVars=vars,orderedEqs=eqns,arrayEqs=ae),
          ass1, ass2, helpVarInfo)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        //indxs = intString(indx);
        name = Exp.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        c_name = name; // Util.modelicaStringToCStr(name,true);
        id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        //(res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr_1}, {eqn},ae, cg_id);
        index = tick();
        index = eqNum; // Use the equation number as unique index
        repl = makeResidualReplacements({cr_1});
        resEqs = createNonlinearResidualEquations({eqn}, ae, repl);
      then
        SES_NONLINEAR(index, resEqs, {cr_1});
    ///* single equation: algorithm */
    //case (dae, DAELow.DAELOW(orderedVars=DAELow.VARIABLES(varArr=vararr),orderedEqs=eqns,algorithms=algs), ass1, ass2, eqNum)
    //  equation
    //    e_1 = eqNum - 1 "Algorithms Each algorithm should only be genated once." ;
    //    DAELow.ALGORITHM(indx,inputs,outputs,_) = DAELow.equationNth(eqns, e_1);
    //    alg = algs[indx + 1];
    //    DAE.ALGORITHM_STMTS(algStatements) = alg;
    //  then
    //    SES_ALGORITHM(algStatements);

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
        //(cfunc,cg_id_1) =
        //Codegen.generateAlgorithm(DAE.ALGORITHM(alg,source), cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
        DAE.ALGORITHM_STMTS(algStatements) = alg;
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
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = Util.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
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
  input VarTransform.VariableReplacements repl;
  output list<SimEqSystem> eqSystems;
algorithm
  eqSystems :=
  matchcontinue (eqs, arrayEqs, repl)
    local
      Integer cg_id,cg_id_1,indx_1,cg_id_2,indx,aindx;
      DAE.ExpType tp;
      DAE.Exp res_exp,res_exp_1,res_exp_2,e1,e2,e;
      String var,indx_str,stmt;
      list<DAELow.Equation> rest,rest2;
      DAELow.MultiDimEquation[:] aeqns;
      VarTransform.VariableReplacements repl;
      list<SimEqSystem> eqSystemsRest;
    case ({}, _, _)
      then {};
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest), aeqns, repl)
      equation
        tp = Exp.typeof(e1);
        res_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        res_exp_1 = Exp.simplify(res_exp);
        res_exp_2 = VarTransform.replaceExp(res_exp_1, repl, SOME(skipPreOperator));
        //(exp_func,var,cg_id_1) = Codegen.generateExpression(res_exp_2, cg_id, Codegen.simContext);
        //indx_str = intString(indx);
        //indx_1 = indx + 1;
        eqSystemsRest = createNonlinearResidualEquations(rest, aeqns, repl);
        //stmt = Util.stringAppendList({TAB,"res[",indx_str,"] = ",var,";"});
        //exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        //cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        SES_RESIDUAL(res_exp_2) :: eqSystemsRest;
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: rest), aeqns, repl)
      equation
        res_exp_1 = Exp.simplify(e);
        res_exp_2 = VarTransform.replaceExp(res_exp_1, repl, SOME(skipPreOperator));
        //(exp_func,var,cg_id_1) = Codegen.generateExpression(res_exp_2, cg_id, Codegen.simContext);
        //indx_str = intString(indx);
        //indx_1 = indx + 1;
        eqSystemsRest = createNonlinearResidualEquations(rest, aeqns, repl);
        //(cfunc,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest, aeqns,indx_1, repl, cg_id_1);
        //stmt = Util.stringAppendList({TAB,"res[",indx_str,"] = ",var,";"});
        //exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        //cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        SES_RESIDUAL(res_exp_2) :: eqSystemsRest;
    ///* An array equation */
    //case (rest as DAELow.ARRAY_EQUATION(aindx,_) :: _, aeqns, repl)
    //  equation
    //    (cfunc_1,cg_id_1,rest2,indx_1) = generateOdeSystem2NonlinearResidualsArrayEqn(aindx,rest,aeqns,indx,repl,cg_id);
    //    (cfunc_2,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest2, aeqns,indx_1, repl, cg_id_1);
    //    cfunc = Codegen.cMergeFns({cfunc_1,cfunc_2});
    //  then (cfunc,cg_id_2);
  end matchcontinue;
end createNonlinearResidualEquations;

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
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,daelow,subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      String s;
      DAELow.MultiDimEquation[:] ae;
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
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
        // States are solved for der(x) not x.
        cont_var1 = Util.listMap(cont_var, transformXToXd);
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,true);
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        equations_ = createOdeSystem2(false, false, cont_subsystem_dae, jac, jac_tp, block_,helpVarInfo);
      then
        equations_;
    /* mixed system of equations, both continous and discrete eqns*/
    case (true,(dlow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_,helpVarInfo)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
        // States are solved for der(x) not x.
        cont_var1 = Util.listMap(cont_var, transformXToXd);
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations.
        // Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,true);
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
      //  (s0,cg_id1,numValues) = generateMixedHeader(cont_eqn, cont_var, disc_eqn, disc_var, cg_id);
      //  (Codegen.CFUNCTION(rettp,fn,retrec,arg,locvars,init,stmts,cleanups),cg_id2,extra_funcs1) = generateOdeSystem2(true/*mixed system*/,true,cont_subsystem_dae, jac, jac_tp, cg_id1);
      //  stmts_1 = Util.listFlatten({{"{"},locvars,stmts,{"}"}}) "initialization of e.g. matrices for linsys must be done in each
      //      iteration, create new scope and put them first." ;
      //  s2_1 = Codegen.CFUNCTION(rettp,fn,retrec,arg,{},init,stmts_1,cleanups);
      //  (s4,cg_id3) = generateMixedFooter(cont_eqn, cont_var, disc_eqn, disc_var, cg_id2);
      //  (s3,cg_id4,_) = generateMixedSystemDiscretePartCheck(disc_eqn, disc_var, cg_id3,numValues);
      //  (s1,cg_id5,_) = generateMixedSystemStoreDiscrete(disc_var, 0, cg_id4);
      //  cfn = Codegen.cMergeFns({s0,s1,s2_1,s3,s4});
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
        var_lst_1 = Util.listMap(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(var_lst_1);
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc) "not used" ;
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        (v1,v2,subsystem_dae_1,m_2,mT_2) = DAELow.matchingAlgorithm(subsystem_dae, m_1, mt_1, (DAELow.NO_INDEX_REDUCTION(), DAELow.EXACT(), DAELow.KEEP_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m_2, mT_2, v1,v2);
        (subsystem_dae_2,m_3,mT_3,v1_1,v2_1,comps_1,r,t) = DAELow.tearingSystem(subsystem_dae_1,m_2,mT_2,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_3, mT_3,false) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac);
        equation_ = generateTearingSystem(v1_1,v2_1,comps_flat,rf,tf,false,genDiscrete,subsystem_dae_2, jac, jac_tp, helpVarInfo);
      then
        {equation_};
    /* continuous system of equations */
    case (genDiscrete,(daelow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,block_,helpVarInfo)
      equation
        // extract the variables and equations of the block.
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        // States are solved for der(x) not x.
        var_lst_1 = Util.listMap(var_lst, transformXToXd);
        vars_1 = DAELow.listVar(var_lst_1);
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc);
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,false);
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
      VarTransform.VariableReplacements av "alias-variables' hashtable";
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
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
        // get Tearingvar from crs
        // to use listNth cref and eqn_lst have to start at 1 and not at 0 -> right shift
        crefs1 = Util.listAddElementFirst(DAE.CREF_IDENT("shift",DAE.ET_REAL(),{}),crefs);
        eqn_lst1 = Util.listAddElementFirst(DAELow.EQUATION(DAE.RCONST(0.0),DAE.RCONST(0.0),DAE.SOURCE({},{},{},{})),eqn_lst);
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
        resEqs = createNonlinearResidualEquations(reqns, ae, repl);
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
        expr = Exp.solve(e1, e2, varexp);
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
    case (mixedEvent,_,dae,jac,jac_tp,block_,helpVarInfo)
      equation
        singleArrayEquation(dae); // fails if not single array eq
        equation_ = createSingleArrayEqnCode(dae, jac);
      then
        {equation_};
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
        (v1,v2,subsystem_dae_1,m_2,mT_2) = DAELow.matchingAlgorithm(d, m_1, mt_1, (DAELow.NO_INDEX_REDUCTION(), DAELow.EXACT(), DAELow.KEEP_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m_2, mT_2, v1,v2);
        (subsystem_dae_2,m_3,mT_3,v1_1,v2_1,comps_1,r,t) = DAELow.tearingSystem(subsystem_dae_1,m_2,mT_2,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);        
        equations_ = generateRelaxationSystem(m_3,mT_3,v1_1,v2_1,comps_flat,rf,tf,subsystem_dae_2,helpVarInfo);
      then
        equations_;
          
    /* Time varying jacobian. Linear system of equations that needs to
       be solved during runtime. */
    case (mixedEvent,_,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_TIME_VARYING(),block_,helpVarInfo)
      local
        list<DAELow.Var> dlowVars;
        list<SimVar> simVars;
        list<DAELow.Equation> dlowEqs;
        list<DAE.Exp> beqs;
        list<tuple<Integer, Integer, DAELow.Equation>> jac;
        list<tuple<Integer, Integer, SimEqSystem>> simJac;
      equation
        ////print("linearSystem of equations:");
        ////DAELow.dump(d);
        ////print("Jacobian:");print(DAELow.dumpJacobianStr(SOME(jac)));print("\n");
        //eqn_size = DAELow.equationSize(eqn);
        //unique_id = tick();
        //(s1,cg_id1) = generateOdeSystem2Declaration(mixedEvent,eqn_size, unique_id, cg_id);
        //(s2,cg_id2) = generateOdeSystem2PopulateAb(mixedEvent,jac, v, eqn, unique_id, cg_id1);
        //(s3,cg_id3) = generateOdeSystem2SolveCall(mixedEvent,eqn_size, unique_id, cg_id2);
        //(s4,cg_id4) = generateOdeSystem2CollectResults(mixedEvent,v, unique_id, cg_id3);
        //s = Codegen.cMergeFns({s1,s2,s3,s4});
        dlowVars = DAELow.varList(v);
        simVars = Util.listMap(dlowVars, dlowvarToSimvar);
        dlowEqs = DAELow.equationList(eqn);
        beqs = Util.listMap1(dlowEqs, dlowEqToExp, v);
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
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates);// get varnames and prefix $der for states.
        repl = makeResidualReplacements(crefs);
        resEqs = createNonlinearResidualEquations(eqn_lst, ae, repl);
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
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
        repl = makeResidualReplacements(crefs);
        resEqs = createNonlinearResidualEquations(eqn_lst, ae, repl);
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

protected function generateRelaxationSystem "function: generateRelaxationSystem
  author: Frenkel TUD

  Generates the actual simulation code for the relaxed system of equation
"
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
  matchcontinue (inM,inMT,inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,inDAELow,helpVarInfo)
    local
      Integer[:] ass1,ass2;
      list<Integer> block_,block_1,block_2,r,t;
      Integer size;
      DAELow.DAELow daelow,daelow1;
      list<tuple<Integer, Integer, DAELow.Equation>> jac,jacA;
      DAELow.JacobianType jac_tp;
      DAELow.Variables v,kv,exv;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      DAELow.EquationArray eqn,eqn1,reeqn,ineq;
      list<DAELow.Equation> eqn_lst,eqn_lst1,eqn_lst2,reqns,solved;
      list<DAELow.Var> var_lst;
      list<DAE.ComponentRef> crefs,X;
      DAELow.MultiDimEquation[:] ae;
      VarTransform.VariableReplacements repl;
      DAE.Algorithm[:] algorithms;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
      DAELow.IncidenceMatrix m;
      DAELow.IncidenceMatrixT mT;
      list<DAE.Exp> exp_lst,B,A_lst,Af;
      list<list<DAE.Exp>> A,An;
      list<SimEqSystem> eqns;
    case (m,mT,ass1,ass2,block_,r,t,
          daelow as DAELow.DAELOW(orderedVars=v,knownVars=kv,externalObjects=exv,aliasVars=av,orderedEqs=eqn,removedEqs=reeqn,initialEqs=ineq,arrayEqs=ae,algorithms=algorithms,eventInfo=eventInfo,extObjClasses=extObjClasses),helpVarInfo) 
      equation
        // get equations and variables
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        size = listLength(eqn_lst);
        // generate A
        A_lst = Util.listFill(DAE.RCONST(0.0),size);
        An = Util.listFill(A_lst,size);
        SOME(jac) = DAELow.calculateJacobian(v, eqn, ae, m, mT,false);
        // sort A
        jacA = Util.listMap2(jac,sortRelaxationSystemA,block_,ass1);
        A = generateRelaxationSystemA(jacA,An);
        // generate B
        exp_lst = generateRelaxationSystemB(eqn_lst,v);
        // sort b
        B = sortRelaxationSystemB(exp_lst,block_);
        // get names from variables
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
        // sort X
        X = sortRelaxationSystemX(crefs,block_,ass2);
        // gauss ellemination        
        solved = solveRelaxationSystem(A,X,B);
        // select equations
        block_1 = Util.listSelect1(block_,r,Util.listNotContains); 
        block_2 = listAppend(r,block_1);
        eqn_lst1 = sortSolvedRelaxationSystem(solved,solved,block_);
        // replace r in org eqn list
        reqns = Util.listMap1r(r,listNth1,eqn_lst1);
        eqn_lst2 = sortSolvedRelaxationSystem(reqns,eqn_lst,r);
        eqn1 = DAELow.listEquation(eqn_lst2);
        daelow1=DAELow.DAELOW(v,kv,exv,av,eqn1,reeqn,ineq,ae,algorithms,eventInfo,extObjClasses);
        // generade code for equations
        eqns = Util.listMap4(block_2,createEquation,daelow1, ass1, ass2, helpVarInfo);     
      then
        eqns;
    case (_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generateRelaxationSystem failed \n");
      then
        fail();
  end matchcontinue;
end generateRelaxationSystem;

protected function generateRelaxationSystemB "function: generateRelaxationSystemB
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input DAELow.Variables inVariables2;
  output list<DAE.Exp> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowEquationLst,inVariables2)
    local
      DAE.ExpType tp;
      DAE.Exp new_exp,rhs_exp,rhs_exp_1,rhs_exp_2,e1,e2,res_exp;
      list<DAELow.Equation> rest;
      list<DAE.Exp> rest1;
      DAELow.Variables v;
    case ({},_) then {};  
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),v)
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = DAELow.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = DAE.UNARY(DAE.UMINUS(tp),rhs_exp);
        rhs_exp_2 = Exp.simplify(rhs_exp_1);
        rest1 = generateRelaxationSystemB(rest,v);
      then
        rhs_exp_2::rest1;
    case ((DAELow.RESIDUAL_EQUATION(exp = res_exp) :: rest),v)
      equation
        rhs_exp = DAELow.getEqnsysRhsExp(res_exp, v);
        rhs_exp_1 = Exp.simplify(rhs_exp);
        rest1 = generateRelaxationSystemB(rest,v);
      then
        rhs_exp_1::rest1;
    case (_,_)
      equation
        Debug.fprint("failtrace", "generateRelaxationSystemB failed\n");
      then
        fail();
  end matchcontinue;
end generateRelaxationSystemB;

protected function listNth1 "function: listNth1
  author: Frenkel TUD
  Same as listNth but starts at 1
"
  input list<Type_a>  inALst;
  input Integer  inInteger;
  replaceable type Type_a subtypeof Any;
  output Type_a outA;
algorithm
  outA:= listNth(inALst,inInteger-1);
end listNth1;

protected function sortRelaxationSystemB "function: sortRelaxationSystemB
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAE.Exp>  inExpLst;
  input list<Integer> inIntegerLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inIntegerLst)
    local
      DAE.Exp e;
      list<DAE.Exp> elst,elst1;
      list<Integer> rest;
      Integer i;
    case (elst,{}) then {};  
    case (elst,i::rest)
      equation
        e = listNth(elst,i-1);
        elst1 = sortRelaxationSystemB(elst,rest);
      then
        e::elst1;
  end matchcontinue;
end sortRelaxationSystemB;

protected function sortSolvedRelaxationSystem "function: sortSolvedRelaxationSystem
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAELow.Equation>  inExpLst;
  input list<DAELow.Equation>  inExpLst1;
  input list<Integer> inIntegerLst;
  output list<DAELow.Equation> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inExpLst1,inIntegerLst)
    local
      DAELow.Equation e;
      list<DAELow.Equation> elst,elst1,res,res1;
      list<Integer> rest;
      Integer i;
    case (elst,elst1,{}) then elst1;  
    case (e::elst,elst1,i::rest)
      equation
        res = Util.listReplaceAt(e,i-1,elst1); 
        res1 = sortSolvedRelaxationSystem(elst,res,rest);
      then
        res1;
  end matchcontinue;
end sortSolvedRelaxationSystem;

protected function sortRelaxationSystemA "function: sortRelaxationSystemA
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input tuple<Integer, Integer, DAELow.Equation>  inJacElem;
  input list<Integer> inIntegerLst;
  input Integer[:] inIntegerArr;
  output tuple<Integer, Integer, DAELow.Equation> outJacElem;
algorithm
  outJacElem:=
  matchcontinue (inJacElem,inIntegerLst,inIntegerArr)
    local
      Integer z,z1,s,s1,e;
      DAELow.Equation eqn;
      list<Integer> comp;
      Integer[:] v1;
    case ( ((z,s,eqn)) ,comp,v1)
      equation
        z1 = Util.listPosition(z,comp);
        e = v1[s];
        s1 = Util.listPosition(e,comp);
      then
        ((z1,s1,eqn));
  end matchcontinue;
end sortRelaxationSystemA;

protected function generateRelaxationSystemA "function: generateRelaxationSystemA
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<tuple<Integer, Integer, DAELow.Equation>>  inJac;
  input list<list<DAE.Exp>> inA;
  output list<list<DAE.Exp>> outA;
algorithm
  outA:=
  matchcontinue (inJac,inA)
    local
      list<tuple<Integer, Integer, DAELow.Equation>> rest;
      list<list<DAE.Exp>> a,a1,a2;
      list<DAE.Exp> row,row1;
      DAE.Exp e,e1,e2;
      Integer z,s;
      DAELow.Equation eqn;
      DAE.ExpType tp;
    case ( {} ,a) then a;
    case ( ((z,s,DAELow.EQUATION(exp = e1,scalar = e2))::rest) ,a)
      equation
         tp = Exp.typeof(e1);
         e = DAE.BINARY(e1,DAE.SUB(tp),e2);
         row = listNth(a,z);
         row1 = Util.listReplaceAt(e,s,row); 
         a1 = Util.listReplaceAt(row1,z,a); 
         a2 = generateRelaxationSystemA(rest,a1);       
      then
        a2;      
    case ( ((z,s,DAELow.RESIDUAL_EQUATION(exp = e))::rest) ,a)
      equation
         row = listNth(a,z);
         row1 = Util.listReplaceAt(e,s,row); 
         a1 = Util.listReplaceAt(row1,z,a);        
         a2 = generateRelaxationSystemA(rest,a1);       
      then
        a2;
    case (((z,s,eqn)::rest),_)
      equation
        Debug.fprint("failtrace", "generateRelaxationSystemA failed\n");
        true = RTOpts.debugFlag("failtrace");
        DAELow.dumpEqns({eqn});
      then
        fail();        
    case (_,_)
      equation
        Debug.fprint("failtrace", "generateRelaxationSystemA failed\n");
      then
        fail();        
  end matchcontinue;
end generateRelaxationSystemA;

protected function sortRelaxationSystemX "function: sortRelaxationSystemB
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAE.ComponentRef>  inExpLst;
  input list<Integer> inIntegerLst;
  input Integer[:] inIntegerArr;
  output list<DAE.ComponentRef> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inIntegerLst,inIntegerArr)
    local
      DAE.ComponentRef c;
      list<DAE.ComponentRef> elst,elst1;
      list<Integer> rest;
      Integer i,e;
      Integer[:] v2;
    case (elst,{},_) then {};  
    case (elst,i::rest,v2)
      equation
        e = v2[i];
        c = listNth(elst,e-1);    
        elst1 = sortRelaxationSystemX(elst,rest,v2);
      then
        c::elst1;
  end matchcontinue;
end sortRelaxationSystemX;

protected function solveRelaxationSystem "function: solveRelaxationSystem
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<list<DAE.Exp>> inA;
  input list<DAE.ComponentRef>  inX;
  input list<DAE.Exp> inB;
  output list<DAELow.Equation> outEqnLst;
algorithm
  outEqnLst:=
  matchcontinue (inA,inX,inB)
    local
      list<DAE.Exp> row,b,b1;
      list<DAE.ComponentRef> x;
      list<DAELow.Equation> s;
      DAE.ComponentRef c;
      list<list<DAE.Exp>> resta,a1,a2;
      DAE.Exp a_0,b_0,e,e1;
      DAE.ExpType tp;
      DAELow.Equation eqn;
    case ((a_0::{})::{},c::{},b_0::{})
      equation
        // solution
        tp = Exp.typeof(a_0);
        e = DAE.BINARY(b_0,DAE.DIV(tp),a_0);
        e1 = Exp.simplify(e);
      then
        {DAELow.EQUATION(DAE.CREF(c,tp),e1,DAE.emptyElementSource)};      
    case ((a_0::row)::resta,c::x,b_0::b)
      equation
        (a1,b1) = solveRelaxationSystem1(a_0,row,resta,b_0,b);
        eqn = solveRelaxationSystem3((a_0::row)::resta,b_0::b,c::x);
        // next
        s = solveRelaxationSystem(a1,x,b1);
      then
        eqn::s;
  end matchcontinue;
end solveRelaxationSystem;

protected function solveRelaxationSystem1 "function: solveRelaxationSystem1
  author: Frenkel TUD
  Helper function to solveRelaxationSystem
"
  input DAE.Exp  inA_0;
  input list<DAE.Exp>  inRow;
  input list<list<DAE.Exp>> inA;
  input DAE.Exp  inB_0;
  input list<DAE.Exp> inB;
  output list<list<DAE.Exp>> outA;
  output list<DAE.Exp> outB;
algorithm
  (outA,outB):=
  matchcontinue (inA_0,inRow,inA,inB_0,inB)
    local
      list<list<DAE.Exp>> resta,a;
      list<DAE.Exp> row_0,row,row1,line,b,bn;
      DAE.Exp a_0,a_i,b_0,b_i,b1,b2;
      DAE.ExpType tp;
    case (a_0,row_0,(a_i::row)::{},b_0,b_i::{})
      equation
        // arow
        row1 = solveRelaxationSystem2(a_0,a_i,row_0,row);
        // b
        tp = Exp.typeof(b_i);
        b1 = DAE.BINARY(b_i,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(b_0,DAE.DIV(tp),a_0))); 
        b2 = Exp.simplify(b1);
      then
        ({row1},{b2});      
    case (a_0,row_0,(a_i::row)::resta,b_0,b_i::b)
      equation
        // arow
        row1 = solveRelaxationSystem2(a_0,a_i,row_0,row);
        // b
        tp = Exp.typeof(b_i);
        b1 = DAE.BINARY(b_i,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(b_0,DAE.DIV(tp),a_0))); 
        b2 = Exp.simplify(b1);
        // next 
        (a,bn) = solveRelaxationSystem1(a_0,row_0,resta,b_0,b);
      then
        (row1::a,b2::bn);
  end matchcontinue;
end solveRelaxationSystem1;

protected function solveRelaxationSystem2 "function: solveRelaxationSystem2
  author: Frenkel TUD
  Helper function to solveRelaxationSystem1
"
  input DAE.Exp  inA_0;
  input DAE.Exp  inA_i;
  input list<DAE.Exp> inARow_0;
  input list<DAE.Exp> inARow;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inA_0,inA_i,inARow_0,inARow)
    local
      list<DAE.Exp> rest,row_0,a;
      DAE.Exp a_0,a_j,a_i,e,e1,e2;
      DAE.ExpType tp;
    case (a_0,a_i,a_j::{},e::{})
      equation
        tp = Exp.typeof(e);
        e1 = DAE.BINARY(e,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(a_j,DAE.DIV(tp),a_0)));   
        e2 = Exp.simplify(e1);     
      then
        {e2};      
    case (a_0,a_i,a_j::row_0,e::rest)
      equation
        tp = Exp.typeof(e);
        e1 = DAE.BINARY(e,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(a_j,DAE.DIV(tp),a_0))); 
        e2 = Exp.simplify(e1);       
        // next
        a = solveRelaxationSystem2(a_0,a_i,row_0,rest);
      then
        e2::a;
  end matchcontinue;
end solveRelaxationSystem2;

protected function solveRelaxationSystem3 "function: solveRelaxationSystem3
  author: Frenkel TUD
  Helper function to solveRelaxationSystem
"
  input list<list<DAE.Exp>> inA;
  input list<DAE.Exp> inB;
  input list<DAE.ComponentRef> inX;
  output DAELow.Equation outEqn;
algorithm
  outEqn:=
  matchcontinue (inA,inB,inX)
    local
      list<list<DAE.Exp>> resta;
      list<DAE.Exp> restb,row;
      DAE.Exp a_0,b_0,e,e1;
      list<DAE.ComponentRef> x;
      DAE.ComponentRef c;
      DAE.ExpType tp;
    case ((a_0::row)::resta,b_0::restb,c::x)
      equation
        e = solveRelaxationSystem4(row,x);
        tp = Exp.typeof(e);
        e = DAE.BINARY(DAE.BINARY(b_0,DAE.SUB(tp),e),DAE.DIV(tp),a_0);
        e1 = Exp.simplify(e);
      then
        DAELow.EQUATION(DAE.CREF(c,tp),e1,DAE.emptyElementSource);        
  end matchcontinue;
end solveRelaxationSystem3;

protected function solveRelaxationSystem4 "function: solveRelaxationSystem4
  author: Frenkel TUD
  Helper function to solveRelaxationSystem3
"
  input list<DAE.Exp> inRow;
  input list<DAE.ComponentRef> inX;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inRow,inX)
    local
      list<DAE.Exp> rest;
      DAE.Exp b,e,e1,e2;
      list<DAE.ComponentRef> x;
      DAE.ComponentRef c;
      DAE.ExpType tp;
     case (e::{},c::{})
      equation
        tp = Exp.typeof(e);
      then
        DAE.BINARY(e,DAE.MUL(tp),DAE.CREF(c,DAE.ET_OTHER));     
    case (e::rest,c::x)
      equation
        tp = Exp.typeof(e);
        e1 = DAE.BINARY(e,DAE.MUL(tp),DAE.CREF(c,DAE.ET_OTHER));
        e2 = solveRelaxationSystem4(rest,x);
      then
        DAE.BINARY(e1,DAE.ADD(tp),e2);        
  end matchcontinue;
end solveRelaxationSystem4;

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
  output DAE.Exp exp_;
algorithm
  exp_ :=
  matchcontinue (dlowEq, v)
    local
      Integer row;
      Integer col;
      DAE.Exp e;
      DAE.Exp e1;
      DAE.Exp e2;
      DAE.Exp new_exp;
      DAE.Exp rhs_exp;
      DAE.Exp rhs_exp_1;
      DAE.Exp rhs_exp_2;
      DAE.ExpType tp;
    case (DAELow.RESIDUAL_EQUATION(exp=e), v)
      equation
        rhs_exp = DAELow.getEqnsysRhsExp(e, v);
        rhs_exp_1 = Exp.simplify(rhs_exp);
      then rhs_exp_1;
    case (DAELow.EQUATION(exp=e1, scalar=e2), v)
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = DAELow.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = DAE.UNARY(DAE.UMINUS(tp),rhs_exp);
        rhs_exp_2 = Exp.simplify(rhs_exp_1);
      then rhs_exp_2;
  end matchcontinue;
end dlowEqToExp;

protected function createSingleArrayEqnCode
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  output SimEqSystem equation_;
algorithm
  equation_ :=
  matchcontinue (inDAELow,inTplIntegerIntegerDAELowEquationLstOption)
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr,origname,cr_1;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAE.ElementSource source "the origin of the element";

    case (DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        orderedEqs = eqns,
                        removedEqs = se,
                        initialEqs = ie,
                        arrayEqs = ae,
                        algorithms = al,
                        eventInfo = ev),jac) /* eqn code cg var_id extra functions */
      local String cr_1_str;
      equation
        (DAELow.ARRAY_EQUATION(index=indx) :: _) = DAELow.equationList(eqns);
        DAELow.MULTIDIM_EQUATION(ds,e1,e2,source) = ae[indx + 1];
        ((DAELow.VAR(cr,_,_,_,_,_,_,_,origname,_,_,_,_,_) :: _)) = DAELow.varList(vars);
        // We need to strip subs from origname since they are removed in cr.
        cr_1 = Exp.crefStripLastSubs(origname);
        // Since we use origname we need to replace '.' with '$P' manually.
        cr_1_str = Util.modelicaStringToCStr(Exp.printComponentRefStr(cr_1),true); // stringAppend("$",Util.modelicaStringToCStr(Exp.printComponentRefStr(cr_1),true));
        cr_1 = DAE.CREF_IDENT(cr_1_str,DAE.ET_OTHER(),{});
        (e1,e2) = solveTrivialArrayEquation(cr_1,e1,e2);
        equation_ = createSingleArrayEqnCode2(cr_1, cr_1, e1, e2);
      then
        equation_;
    case (_,_)
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
      Algorithm.Algorithm alg;
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
        DAE.ALGORITHM_STMTS(algStatements) = alg;
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
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = Util.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,
          ". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,
          {message});
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
    case (cr,eltcr,(e1 as DAE.CREF(componentRef = cr2)),e2)
      equation
        true = Exp.crefEqual(cr, cr2);
        s1 = Exp.printComponentRefStr(eltcr);
        //(cfunc,s2,cg_id_1) = Codegen.generateExpression(e2, cg_id, Codegen.simContext);
        //stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s2,", &",s1,");"});
      then
        SES_ARRAY_CALL_ASSIGN(eltcr, e2);
    case (cr,eltcr,e1,(e2 as DAE.CREF(componentRef = cr2)))
      equation
        true = Exp.crefEqual(cr, cr2);
        s1 = Exp.printComponentRefStr(eltcr);
        //(cfunc,s2,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
        //stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s1,", &",s2,");"});
      then
      SES_ARRAY_CALL_ASSIGN(eltcr, e1);
    case (cr,eltcr,e1,e2) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e2);
        s1 = Exp.printComponentRefStr(eltcr);
        //(cfunc,s2,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
        //stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s1,", &",s2,");"});
      then
        SES_ARRAY_CALL_ASSIGN(cr2, e1);
    case (cr,eltcr,e1,e2) /* e1 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
        s1 = Exp.printComponentRefStr(eltcr);
        //(cfunc,s2,cg_id_1) = Codegen.generateExpression(e2, cg_id, Codegen.simContext);
        //stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s2,", &",s1,");"});
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
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<list<Integer>> blocks;
  output list<list<SimVar>> needSave;
algorithm
  needSave :=
  matchcontinue (zeroCrossings, dae, dlow, ass1, ass2, blocks)
    local
      DAELow.ZeroCrossing zc;
      list<DAELow.ZeroCrossing> rest_zc;
      list<Integer> eql;
      list<SimVar> needSaveTmp;
      list<list<SimVar>> needSave_rest;
    case ({}, _, _, _, _, _)
      then {};
    case ((zc as DAELow.ZERO_CROSSING(occurEquLst=eql)) :: rest_zc, dae, dlow,
          ass1, ass2, blocks)
      equation
        needSaveTmp = createZeroCrossingNeedSave(dae, dlow, ass1, ass2, eql,
                                                 blocks);
        needSave_rest = createZeroCrossingsNeedSave(rest_zc, dae, dlow, ass1,
                                                    ass2, blocks);
      then needSaveTmp :: needSave_rest;
  end matchcontinue;
end createZeroCrossingsNeedSave;

protected function createZeroCrossingNeedSave
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<Integer> eqns2;
  input list<list<Integer>> blocks;
  output list<SimVar> needSave;
algorithm
  needSave :=
  matchcontinue (dae, dlow, ass1, ass2, eqns2, blocks)
    local
      list<SimVar> crs;
      Integer cg_id,eqn_1,v,eqn,cg_id,cg_id_1,numValues;
      list<Integer> block_,rest;
      DAE.ComponentRef cr;
      String cr_str,save_stmt,rettp,fn,stmt;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,cont_var1;
      DAELow.Variables vars, vars_1,knvars,exvars;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
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
    case (_,_,_,_,{},_)
      then {};
    /* zero crossing for mixed system */
    case (dae, (dlow as DAELow.DAELOW(vars, knvars, exvars, av, eqns, se, ie, ae,
                                      al, ev, eoc)),
          ass1, ass2, (eqn :: rest), blocks)
      equation
        true = isPartOfMixedSystem(dlow, eqn, blocks, ass2);
        block_ = getZcMixedSystem(dlow, eqn, blocks, ass2);
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (dlowvar as DAELow.VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,_)) = DAELow.getVarAt(vars, v);
        crs = createZeroCrossingNeedSave(dae, dlow, ass1, ass2, rest, blocks);
        simvar = dlowvarToSimvar(dlowvar);
      then
        (simvar :: crs);
    /* zero crossing for single equation */
    case (dae, (dlow as DAELow.DAELOW(orderedVars = vars)), ass1, ass2,
          (eqn :: rest), blocks)
      local
        DAELow.Variables vars;
      equation
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (dlowvar as DAELow.VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,_)) = DAELow.getVarAt(vars, v);
        crs = createZeroCrossingNeedSave(dae, dlow, ass1, ass2, rest, blocks);
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
        name = Absyn.pathString(class_);
        directory = System.trim(fileDir, "\"");
        vars = createVars(dlow);
        SIMVARS(inputVars=iv, outputVars=ov) = vars;
        numOutVars = listLength(ov);
        numInVars = listLength(iv);
        varInfo = createVarInfo(dlow, numOutVars, numInVars, numHelpVars,
                                numResiduals);
      then
        MODELINFO(name, directory, varInfo, vars);
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
      Integer nx, ny, np, ng, next, ny_string, np_string, ng_1;
    case (dlow, numOutVars, numInVars, numHelpVars, numResiduals)
      equation
        (nx, ny, np, ng, next, ny_string, np_string) =
          DAELow.calculateSizes(dlow);
        ng_1 = filterNg(ng);
      then
        VARINFO(numHelpVars, ng_1, nx, ny, np, numOutVars, numInVars,
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
      then (SIMVARS({}, {}, {}, {}, {}, {}, {}, {}, {}));
    case (((var as DAELow.VAR(cr, kind, dir, _, _, _, _, indx, origname, _,
                              dae_var_attr, comment, flowPrefix, streamPrefix))
           :: vs))
      equation
        varsTmp1 = extractVarFromVar(var);
        varsTmp2 = extractVarsFromList(vs);
        vars = mergeVars(varsTmp1, varsTmp2);
      then
        vars;
    case ((_ :: vs))
      equation
        Error.addMessage(
          Error.INTERNAL_ERROR,
          {"extractVarsFromList failed"});
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
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
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
        inputVars = {};
        outputVars = {};
        paramVars = {};
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
        inputVars = addSimvarIfTrue(
          DAELow.isVarOnTopLevelAndInput(dlowVar), simvar, inputVars);
        outputVars = addSimvarIfTrue(
          DAELow.isVarOnTopLevelAndOutput(dlowVar), simvar, outputVars);
        paramVars = addSimvarIfTrue(
          isVarParam(dlowVar), simvar, paramVars);
        stringAlgVars = addSimvarIfTrue(
          isVarStringAlg(dlowVar), simvar, stringAlgVars);
        stringParamVars = addSimvarIfTrue(
          isVarStringParam(dlowVar), simvar, stringParamVars);
        extObjVars = addSimvarIfTrue(
          DAELow.isExtObj(dlowVar), simvar, extObjVars);
      then
        SIMVARS(stateVars, derivativeVars, algVars, inputVars, outputVars,
                paramVars, stringAlgVars, stringParamVars, extObjVars);
  end matchcontinue;
end extractVarFromVar;

protected function derVarFromStateVar
  input SimVar state;
  output SimVar deriv;
algorithm
  deriv :=
  matchcontinue (state)
    local
      DAE.Ident nameIdent;
      DAE.ExpType nameIdentType;
      list<DAE.Subscript> nameSubscriptLst;
      DAE.Ident origNameIdent;
      DAE.ExpType origNameIdentType;
      list<DAE.Subscript> origNameSubscriptLst;
      String comment;
      Integer index;
      Boolean isFixed;
      Exp.Type type_;
      Boolean isDiscrete;
      DAE.ComponentRef newName;
      DAE.ComponentRef newOrigName;
      DAE.Ident newNameIdent;
      DAE.Ident newOrigNameIdent;
      Option<DAE.ComponentRef> arrayCref;
    case (SIMVAR(DAE.CREF_IDENT(nameIdent, nameIdentType, nameSubscriptLst),
                 DAE.CREF_IDENT(origNameIdent, origNameIdentType,
                                origNameSubscriptLst),
                 comment, index, isFixed, type_, isDiscrete, arrayCref))
      equation
        newNameIdent = DAELow.derivativeNamePrefix +& nameIdent;
        newName = DAE.CREF_IDENT(newNameIdent, nameIdentType,
                                 nameSubscriptLst);
        newOrigNameIdent = changeNameForDerivative(origNameIdent);
        newOrigName = DAE.CREF_IDENT(newOrigNameIdent, origNameIdentType,
                                     origNameSubscriptLst);
        //TODO: transform arraycref?
        //arrayCref = getArrayCref(...);
      then
        SIMVAR(newName, newOrigName, comment, index, isFixed, type_,
               isDiscrete, arrayCref);
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
      list<SimVar> inputVars, inputVars1, inputVars2;
      list<SimVar> outputVars, outputVars1, outputVars2;
      list<SimVar> paramVars, paramVars1, paramVars2;
      list<SimVar> stringAlgVars, stringAlgVars1, stringAlgVars2;
      list<SimVar> stringParamVars, stringParamVars1, stringParamVars2;
      list<SimVar> extObjVars, extObjVars1, extObjVars2;
    case (SIMVARS(stateVars1, derivativeVars1, algVars1, inputVars1,
                  outputVars1, paramVars1, stringAlgVars1, stringParamVars1,
                  extObjVars1),
          SIMVARS(stateVars2, derivativeVars2, algVars2, inputVars2,
                  outputVars2, paramVars2, stringAlgVars2, stringParamVars2,
                  extObjVars2))
      equation
        stateVars = listAppend(stateVars1, stateVars2);
        derivativeVars = listAppend(derivativeVars1, derivativeVars2);
        algVars = listAppend(algVars1, algVars2);
        inputVars = listAppend(inputVars1, inputVars2);
        outputVars = listAppend(outputVars1, outputVars2);
        paramVars = listAppend(paramVars1, paramVars2);
        stringAlgVars = listAppend(stringAlgVars1, stringAlgVars2);
        stringParamVars = listAppend(stringParamVars1, stringParamVars2);
        extObjVars = listAppend(extObjVars1, extObjVars2);
      then
        SIMVARS(stateVars, derivativeVars, algVars, inputVars, outputVars,
                paramVars, stringAlgVars, stringParamVars, extObjVars);
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
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> extObjVars;
    case (SIMVARS(stateVars, derivativeVars, algVars, inputVars,
                  outputVars, paramVars, stringAlgVars, stringParamVars,
                  extObjVars))
      equation
        stateVars = Util.sort(stateVars, varIndexComparer);
        derivativeVars = Util.sort(derivativeVars, varIndexComparer);
        algVars = Util.sort(algVars, varIndexComparer);
        inputVars = Util.sort(inputVars, varIndexComparer);
        outputVars = Util.sort(outputVars, varIndexComparer);
        paramVars = Util.sort(paramVars, varIndexComparer);
        stringAlgVars = Util.sort(stringAlgVars, varIndexComparer);
        stringParamVars = Util.sort(stringParamVars, varIndexComparer);
        extObjVars = Util.sort(extObjVars, varIndexComparer);
      then SIMVARS(stateVars, derivativeVars, algVars, inputVars,
                   outputVars, paramVars, stringAlgVars, stringParamVars,
                   extObjVars);
  end matchcontinue;
end sortSimvarsOnIndex;

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
      list<SimVar> inputVars;
      list<SimVar> outputVars;
      list<SimVar> paramVars;
      list<SimVar> stringAlgVars;
      list<SimVar> stringParamVars;
      list<SimVar> extObjVars;
    /* no initial equations so nothing to do */
    case (_, {})
      then simvarsIn;
    case (SIMVARS(stateVars, derivativeVars, algVars, inputVars,
                  outputVars, paramVars, stringAlgVars, stringParamVars,
                  extObjVars), initialEqs)
      equation
        true = Util.boolAndList(Util.listMap(stateVars, simvarFixed));
        stateVars = Util.listMap1(stateVars, nonFixifyIfHasInit, initialEqs);
      then SIMVARS(stateVars, derivativeVars, algVars, inputVars,
                   outputVars, paramVars, stringAlgVars, stringParamVars,
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
      DAE.ComponentRef origName;
      String comment;
      Integer index;
      Boolean isFixed;
      Exp.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
      list<DAE.ComponentRef> initCrefs;
      String varNameStr;
    case (SIMVAR(name, origName, comment, index, isFixed, type_, isDiscrete, arrayCref), initialEqs)
      equation
        initCrefs = DAELow.equationsCrefs(initialEqs);
        (_ :: _) = Util.listSelect1(initCrefs, name, Exp.crefEqual);
        varNameStr = Exp.printComponentRefStr(origName);
        Error.addMessage(Error.SETTING_FIXED_ATTRIBUTE, {varNameStr});
      then SIMVAR(name, origName, comment, index, false, type_, isDiscrete, arrayCref);
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
      DAE.ComponentRef origname;
      DAE.ComponentRef arrayCrefInner;
      String flattenedName;
    case (DAELow.VAR(origVarName=origname))
      equation
        true = Exp.crefIsFirstArrayElt(origname);
        arrayCrefInner = Exp.crefStripLastSubs(origname);
        flattenedName = Exp.printComponentRefStr(arrayCrefInner);
        flattenedName = Util.modelicaStringToCStr(flattenedName, true);
        // TODO: is last step really ok?
        arrayCrefInner = DAE.CREF_IDENT(flattenedName, DAE.ET_OTHER(), {});
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
      VarTransform.VariableReplacements aliasVars "alias-variables' hashtable";
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
    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,NONE,_))
      equation
				(helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
				helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
				helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
      then (helpvars1,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,NONE,helpVarIndices),nextInd1);

    case (nextInd, DAE.STMT_WHEN(condition,statementLst,NONE,_))
      then ({(nextInd,condition,-1)},DAE.STMT_WHEN(condition, statementLst,NONE,{nextInd}),nextInd+1);

    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,SOME(elseWhen),_))
      equation
				(helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
				helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
				helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
        (helpvars2,statement,nextInd2) = generateHelpVarsInStatement(nextInd1,elseWhen);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,SOME(statement),helpVarIndices),nextInd1);

    case (nextInd, DAE.STMT_WHEN(condition,statementLst,SOME(elseWhen),_))
      equation
        (helpvars1,statement,nextInd1) = generateHelpVarsInStatement(nextInd+1,elseWhen);
      then ((nextInd,condition,-1)::helpvars1,
        DAE.STMT_WHEN(condition, statementLst,SOME(statement),{nextInd}),nextInd1);

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

protected function changeNameForDerivative
"function changeNameForDerivative
  author: x02lucpo
  helper function to generateVarNamesAndComments.
  Changes a string from \"a.b.c\" to \"a.b.der(c)\""
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString)
    local
      String var_name,der_var_name_1,origname,prefix,ret_str,origname_1;
      list<String> origname_lst,origname_lst_1;
    case (origname_1) /* print \"change_name_for_derivative FAILED\" */
      then "der("+& origname_1 +& ")";
/*
    case (origname) // catch the variable names a
      equation
        {var_name} = Util.stringSplitAtChar(origname, ".");
        der_var_name_1 = Util.stringAppendList({"der(",var_name,")"});
      then
        der_var_name_1;
    case (origname)
      equation
        origname_lst = Util.stringSplitAtChar(origname, ".");
        var_name = Util.listLast(origname_lst);
        origname_lst_1 = Util.listStripLast(origname_lst);
        der_var_name_1 = Util.stringAppendList({"der(",var_name,")"});
        prefix = Util.stringDelimitList(origname_lst_1, ".");
        ret_str = Util.stringAppendList({prefix,".",der_var_name_1});
      then
        ret_str;
    case (origname_1) // print \"change_name_for_derivative FAILED\"
      then origname_1;
*/
  end matchcontinue;
end changeNameForDerivative;

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
        res = Util.stringAppendList(
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
        res = Util.stringAppendList(
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

protected function getConditionList "
"

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
	str := Util.stringAppendList({"if (change(",crStr,")) { needToIterate=1; }"});
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
    case ((s :: ss),lst) /* rule	Util.list_list_map_1(lst,Util.list_make_2,s) => lst1 &
	Util.list_flatten(lst1) => lst1\' &
	generate_mixed_discrete_combination_values2(ss,lst) => lst2 &
	list_append(lst1\',lst2) => res
	---------------------------------
	generate_mixed_discrete_combination_values2(s::ss,lst) => res */
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
        singleAlgorithmSection2(eqns);
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
      Exp.Exp e12,e22,vTerm,res,rhs;
      list<Exp.Exp> terms;
      Exp.Type tp;

    // Solve simple linear equations.
    case(v,e1,e2)
      equation
        tp = Exp.typeof(e1);
        res = Exp.simplify(DAE.BINARY(e1,DAE.SUB_ARR(tp),e2));
        //print("simplified to :");print(Exp.printExpStr(res));print("\n");
        (vTerm as DAE.CREF(_,_),rhs) = Exp.getTermsContainingX(res,DAE.CREF(v,DAE.ET_OTHER()));
        //print("solved array equation to :");print(Exp.printExpStr(e1));print("=");
        //print(Exp.printExpStr(e2));print("\n");
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
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubsStringified); //Strip last subscripts
        strs = Util.listMap(crefs_1, Exp.printComponentRefStr); //convert crefs to strings
        s = Util.stringDelimitList(strs, ","); //convert to comma-separated form
        _ = Util.listReduce(crefs_1, Exp.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
    case (DAE.MATRIX(scalar = column))
      equation
        ((crefs as (cr :: _))) = Util.listMap(column, getVectorizedCrefFromExpMatrix);
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubsStringified);
        strs = Util.listMap(crefs_1, Exp.printComponentRefStr);
        s = Util.stringDelimitList(strs, ",");
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
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubsStringified); //Strip last subscripts
        strs = Util.listMap(crefs_1, Exp.printComponentRefStr); //convert crefs to strings
        s = Util.stringDelimitList(strs, ","); //convert to comma-separated form
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
        singleAlgorithmSection2(eqn_lst);
      then
        ();
  end matchcontinue;
end singleAlgorithmSection;

protected function singleAlgorithmSection2
  input list<DAELow.Equation> inDAELowEquationLst;
algorithm
  _:=
  matchcontinue (inDAELowEquationLst)
    local list<DAELow.Equation> res;
    case ({}) then ();
    case ((DAELow.ALGORITHM(index = _) :: res))
      equation
        singleAlgorithmSection2(res);
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
        singleArrayEquation2(eqn_lst);
      then
        ();
  end matchcontinue;
end singleArrayEquation;

protected function singleArrayEquation2
  input list<DAELow.Equation> inDAELowEquationLst;
algorithm
  _:=
  matchcontinue (inDAELowEquationLst)
    local list<DAELow.Equation> res;
    case ({}) then ();
    case ((DAELow.ARRAY_EQUATION(index = _) :: res))
      equation
        singleArrayEquation2(res);
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
        pstr = intString(pos);
        str = Util.stringAppendList({"xloc[",pstr,"]"});
        repl_1 = VarTransform.addReplacement(repl, cr, DAE.CREF(DAE.CREF_IDENT(str,DAE.ET_REAL(),{}),DAE.ET_REAL()));
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
      String index_str,name,c_name,res;
      Exp.ComponentRef cr;
      DAE.VarDirection dir;
      DAELow.Type tp;
      Option<Exp.Exp> exp,st;
      Option<Values.Value> v;
      list<Exp.Subscript> dim;
      Integer index;
      list<Absyn.Path> classes;
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
                     origVarName = name,
                     source = source,
                     values = attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix))
      equation
        index_str = intString(index);
        name = Exp.printComponentRefStr(cr);
        c_name = name; // adrpo: 2009-09-07 this doubles $!! c_name = Util.modelicaStringToCStr(name,true);
        res = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name}) "	Util.string_append_list({\"xd{\",index_str, \"}\"}) => res" ;
      then
        DAELow.VAR(DAE.CREF_IDENT(res,DAE.ET_REAL(),{}),DAELow.STATE_DER(),dir,tp,exp,v,dim,index,cr,source,attr,comment,flowPrefix,streamPrefix);

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
  input DAE.DAElist dae;
  output list<Absyn.Path> res;
  list<list<Absyn.Path>> pathslist;
algorithm
  res := matchcontinue(paths,accumulated,dae)
    local
      list<Absyn.Path> res,acc,rest;
      Absyn.Path path;
    case ({},accumulated,dae) then accumulated;
    case (path::rest,accumulated,dae)
      equation
        acc = getCalledFunctionsInFunction(path, accumulated, dae);
        res = getCalledFunctionsInFunctions(rest, acc, dae);
      then res;
  end matchcontinue;
end getCalledFunctionsInFunctions;

protected function getCalledFunctionsInFunction
"function: getCalledFunctionsInFunction
  Goes through the given DAE, finds the given function and collects
  the names of the functions called from within those functions"
  input Absyn.Path inPath;
  input list<Absyn.Path> accumulated;
  input DAE.DAElist inDAElist;
  output list<Absyn.Path> outAbsynPathLst;
algorithm
  outAbsynPathLst:=
  matchcontinue (inPath,accumulated,inDAElist)
    local
      String pathstr,debugpathstr;
      Absyn.Path path;
      list<DAE.Element> elements,funcelems;
      list<Exp.Exp> explist,fcallexps,fcallexps_1, fnrefs;
      list<Absyn.ComponentRef> crefs;
      list<Absyn.Path> calledfuncs,res1,res2,res,acc;
      list<String> debugpathstrs;
      DAE.DAElist dae;

    case (path,acc,DAE.DAE(elementLst = elements)) /* Don\'t fail here, ceval will generate the function later */
      equation
        {} = DAEUtil.getNamedFunction(path, elements);
        pathstr = Absyn.pathString(path);
        Error.addMessage(Error.LOOKUP_ERROR, {pathstr,"global scope"});
        //Debug.fprintln("failtrace", "SimCode.getCalledFunctionsInFunction: Class " +& pathstr +& " not found in global scope.");
      then
        path::acc;

    case (path,acc,(dae as DAE.DAE(elementLst = elements)))
      local
        list<DAE.Element> varlist;
        list<list<DAE.Element>> varlistlist;
        list<Absyn.Path> varfuncs, fnpaths, fns, referencedFuncs, reffuncs;
      equation
        false = listMember(path,acc);
        funcelems = DAEUtil.getNamedFunction(path, elements);
        explist = DAEUtil.getAllExps(funcelems);
        fcallexps = getMatchingExpsList(explist, matchCalls);
        fcallexps_1 = Util.listSelect(fcallexps, isNotBuiltinCall);
        calledfuncs = Util.listMap(fcallexps_1, getCallPath);

        /*-- MetaModelica Partial Function. sjoelund --*/

        // stefan - get all arguments of constant T_FUNCTION type and add to list
        fnrefs = getMatchingExpsList(explist, matchFnRefs);
        crefs = Util.listMap(fnrefs, getCrefFromExp);
        reffuncs = Util.listMap(crefs, Absyn.crefToPath);

        //fns = removeDuplicatePaths(fnpaths);
        calledfuncs = listAppend(reffuncs, calledfuncs);
        calledfuncs = removeDuplicatePaths(calledfuncs);

        varlistlist = Util.listMap(funcelems, getFunctionElementsList);
        varlist = Util.listFlatten(varlistlist);
        varlist = Util.listSelect(varlist, DAEUtil.isFunctionRefVar);
        varfuncs = Util.listMap(varlist, getFunctionRefVarPath);
        calledfuncs = Util.listSetDifference(calledfuncs, varfuncs) "Filter out function reference calls";
        /*--                                           --*/
        res = getCalledFunctionsInFunctions(calledfuncs, path::acc, dae);

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
  input Exp.Exp inExp;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inExp)
    local Absyn.Path path;
    case DAE.CALL(path = path) then path;
  end matchcontinue;
end getCallPath;

protected function getFunctionRefVarPath
"function: getFunctionRefVarFunctionPath
  Retrive the function name from a function variable."
  input DAE.Element inElem;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inElem)
    local Absyn.Path path;
    case DAE.VAR(ty = ((DAE.T_FUNCTION(_,_,_)),SOME(path))) then path;
  end matchcontinue;
end getFunctionRefVarPath;

protected function getFunctionElementsList
"function: getFunctionElementsList
  Retrives the dAEList of function (or external function)"
  input DAE.Element inElem;
  output list<DAE.Element> out;
algorithm
  outPath:=
  matchcontinue (inElem)
    local Absyn.Path path;
    case DAE.FUNCTION(functions = {DAE.FUNCTION_DEF(out)}) then out;
    case DAE.FUNCTION(functions = {DAE.FUNCTION_EXT(body=out)}) then out;
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
      String orignameStr, commentStr, name;
      Boolean isFixed;
      Exp.Type type_;
      Boolean isDiscrete;
      Option<DAE.ComponentRef> arrayCref;
    case ((dlowVar as DAELow.VAR(varName = cr,
                                 varKind = kind,
                                 varDirection = dir,
                                 arryDim = inst_dims,
                                 index = indx,
                                 origVarName = origname,
                                 values = dae_var_attr,
                                 comment = comment,
                                 varType = tp,
                                 flowPrefix = flowPrefix,
                                 streamPrefix = streamPrefix)))
    equation
      commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
      isFixed = DAELow.varFixed(dlowVar);
      type_ = DAELow.makeExpType(tp);
      isDiscrete = isVarDiscrete(tp, kind);
      arrayCref = getArrayCref(dlowVar);
    then
      SIMVAR(cr, origname, commentStr, indx, isFixed, type_, isDiscrete,
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

protected function generateFunctions2
"function: generateFunctions2
  author: PA
  Helper function to generateFunctions."
  input SCode.Program p;
  input list<Absyn.Path> paths;
  output list<DAE.Element> dae;
algorithm
  dae := generateFunctions3(p, paths, paths);
end generateFunctions2;

protected function generateFunctions3
"function: generateFunctions3
  Helper function to generateFunctions2"
  input SCode.Program inProgram1;
  input list<Absyn.Path> inAbsynPathLst2;
  input list<Absyn.Path> inAbsynPathLst3;
  output list<DAE.Element> outDAEElementLst;
algorithm
  outDAEElementLst:=
  matchcontinue (inProgram1,inAbsynPathLst2,inAbsynPathLst3)
    local
      list<Absyn.Path> allpaths,subfuncs,allpaths_1,paths_1,paths;
      DAE.DAElist fdae,dae,patched_dae;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<DAE.Element> elts,res;
      list<SCode.Class> p;
      Absyn.Path path;
      DAE.ExternalDecl extdecl;
      DAE.InlineType inl;
      Boolean partialPrefix;
      String s;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;

    case (_,{},allpaths) then {};  /* iterated over complete list */

    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InnerOuter.emptyInstHierarchy, p, path);
        DAE.DAE({DAE.FUNCTION(functions =
          DAE.FUNCTION_DEF(daeElts)::_,type_ = t,partialPrefix = partialPrefix,inlineType=inl,source = source)},funcs) = fdae;
        patched_dae = DAE.DAE({DAE.FUNCTION(path,{DAE.FUNCTION_DEF(daeElts)},t,partialPrefix,inl,source)},funcs);
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.FUNCTION(path,{DAE.FUNCTION_DEF(daeElts)},t,partialPrefix,inl,source)});
      then
        res;

    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InnerOuter.emptyInstHierarchy, p, path);
        DAE.DAE({DAE.FUNCTION(functions=
          DAE.FUNCTION_EXT(daeElts,extdecl)::_,type_ = t,partialPrefix = partialPrefix,inlineType=inl,source = source)},funcs) = fdae;
        patched_dae = DAE.DAE({DAE.FUNCTION(path,{DAE.FUNCTION_EXT(daeElts,extdecl)},t,partialPrefix,inl,source)},funcs);
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.FUNCTION(path,{DAE.FUNCTION_EXT(daeElts,extdecl)},t,partialPrefix,inl,source)});
      then
        res;

    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InnerOuter.emptyInstHierarchy, p, path);
        DAE.DAE({DAE.RECORD_CONSTRUCTOR(type_ = t,source = source)},funcs) = fdae;
        patched_dae = DAE.DAE({DAE.RECORD_CONSTRUCTOR(path,t,source)},funcs);
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.RECORD_CONSTRUCTOR(path,t,source)});
      then
        res;

    case (_,(path :: paths),_)
      equation
        s = Absyn.pathString(path);
        s = "SimCode.generateFunctions3 failed: " +& s +& "\n";
        print(s);
      then
        fail();
  end matchcontinue;
end generateFunctions3;

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
  output list<String> outStringLst1;
  output list<String> outStringLst2;
algorithm
  (outStringLst1,outStringLst2):=
  matchcontinue (inAbsynAnnotationOption)
    local
      list<String> libs,includes;
      list<Absyn.ElementArg> eltarg;
    case (SOME(Absyn.ANNOTATION(eltarg)))
      equation
        libs = generateExtFunctionIncludesLibstr(eltarg);
        includes = generateExtFunctionIncludesIncludestr(eltarg);
      then
        (includes,libs);
    case (NONE) then ({},{});
  end matchcontinue;
end generateExtFunctionIncludes;

protected function generateExtFunctionIncludesLibstr
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      String lib;
      list<Absyn.ElementArg> eltarg;
      list<Absyn.Exp> arr;
    case (eltarg)
      equation
        Absyn.CLASSMOD(_,SOME(Absyn.STRING(lib))) =
        Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Library",{}));
      then
        {lib};
    case (eltarg)
      equation
        Absyn.CLASSMOD(_,SOME(Absyn.ARRAY(arr))) =
        Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Library",{}));
      then
        Util.listMap(arr, Absyn.expString);
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
    local DAE.Exp e; DAE.ExpType t;
    case((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC()))) then {e};
    case(DAE.PARTEVALFUNCTION(ty = DAE.ET_FUNCTION_REFERENCE_VAR(),path=p,expList=expLst))
      local
        DAE.ComponentRef cref; Absyn.Path p; list<DAE.Exp> expLst,expLst_1;
      equation
        cref = Exp.pathToCref(p);
        e = Exp.makeCrefExp(cref,DAE.ET_FUNCTION_REFERENCE_VAR());
        expLst_1 = getMatchingExpsList(expLst,matchFnRefs);
      then
        e :: expLst_1;
    case(DAE.CALL(expLst = expLst))
      local
        list<DAE.Exp> expLst,expLst_1;
      equation
        expLst_1 = getMatchingExpsList(expLst,matchFnRefs);
      then
        expLst_1;
  end matchcontinue;
end matchFnRefs;

protected function addDivExpErrorMsgtosimJac
"function addDivExpErrorMsgtosimJac
  helper for addDivExpErrorMsgtoSimEqSystem."
  input tuple<Integer, Integer, SimEqSystem> inJac;
  input tuple<DAELow.DAELow,DAELow.DivZeroExpReplace> inDlowMode;
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
  input tuple<DAELow.DAELow,DAELow.DivZeroExpReplace> inDlowMode;
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
    case (SES_SIMPLE_ASSIGN(componentRef = cr, exp = e),inDlowMode)
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
  case(inExp) then DAE.STMT_NORETCALL(inExp);
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

end SimCode;
