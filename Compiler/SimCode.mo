package SimCode
" file:	       SimCodegen.mo
  package:     SimCodegen
  description: A new Module (SimCode) that contains data structures for representing equation code.
   
It should be possible to represent: 
*	Expressions (Exp.mo) 
*	Algorithms (Algorithm.mo) 
*	Functions  (functionODE, residualFunctions, etc). 
*	Linear systems (A and b matrix) list<tuple<Integer,Integer,Exp>>
*	NonLinear systems (residuals) 
*	Mixed linear systems  (A and b matrix, discrete variables (with domain information)) 
*	Mixed nonlinear systems (residuals, discrete variables (with domain information)) 
*	Jacobians list<tuple<Integer,Integer,Exp>> 
*	Data about variables, components, zero-crossings, etc (e.g. strings of originalname, equation, etc)

 RCS: $Id: SimCode.mo 3689 2009-02-26 07:38:30Z adrpo $
"

/** types in the output AST **/
public import Exp;
public import Algorithm;
public import Values;

public import Types;


/** additional types for the translation calls **/
public import DAELow;
public import Env;
public import Interactive;
public import Absyn;
public import Ceval;
public import Tpl;

//?? why these should be public, when it works in CevalScript as protected? -> Adrian
// Adrian: in general when you return form a public function in a package a type
//         defined in another package, that package import should be public too!
public import SCode;
public import DAE;

protected import DAEUtil;
protected import ValuesUtil;
protected import SCodeUtil;
protected import ClassInf;
protected import SimCodeC;

protected import Util;
protected import Debug;
protected import Error;
protected import Inst;
protected import InstanceHierarchy;
protected import Print;
protected import SimCodegen;
protected import RTOpts;
protected import System;

protected import CevalScript;


public
function listLengthExp
  input list<DAE.Exp> lst;
  output Integer len;
algorithm
  len := listLength(lst);
end listLengthExp;

public
function listLengthStr
  input list<String> lst;
  output Integer len;
algorithm
  len := listLength(lst);
end listLengthStr;

public
function listLengthSimVar
  input list<SimVar> lst;
  output Integer len;
algorithm
  len := listLength(lst);
end listLengthSimVar;

public
function listLengthOptionInt
  input list<Option<Integer>> lst;
  output Integer len;
algorithm
  len := listLength(lst);
end listLengthOptionInt;

public
function listLengthMatrix1
  input list<list<tuple<DAE.Exp,Boolean>>> lst;
  output Integer len;
algorithm
  len := listLength(lst);
end listLengthMatrix1;

public
function listLengthMatrix2
  input list<tuple<DAE.Exp,Boolean>> lst;
  output Integer len;
algorithm
  len := listLength(lst);
end listLengthMatrix2;

public
function listLengthSubscript
  input list<DAE.Subscript> lst;
  output Integer len;
algorithm
  len := listLength(lst);
end listLengthSubscript;

// Assume that cref is CREF_IDENT
public
function crefSubIsScalar
  input DAE.ComponentRef cref;
  output Boolean isScalar;
algorithm
  isScalar :=
  matchcontinue (cref)
    local
      list<DAE.Subscript> subs;
    case (DAE.CREF_IDENT(subscriptLst=subs)) then subsToScalar(subs);
    case _ then false;
  end matchcontinue;
end crefSubIsScalar;

// Assume that cref is CREF_IDENT
public
function crefNoSub
  input DAE.ComponentRef cref;
  output Boolean noSub;
algorithm
  noSub :=
  matchcontinue (cref)
    local
      list<DAE.Subscript> subs;
    case (DAE.CREF_IDENT(subscriptLst={})) then true;
    case (DAE.CREF_IDENT(subscriptLst=subs)) then false;
    case _
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {""});
      then
        fail();
  end matchcontinue;
end crefNoSub;

protected
function subsToScalar "function: subsToScalar

  Returns true if subscript results applied to variable or expression
  results in scalar expression.
"
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

public function buildCrefExpFromAsub
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

/************** FUNCTIONS ***********/
/* a type to use for function return, parameters and variable declarations is based on Exp.Type */
public

type Path = Absyn.Path;
type Ident = String; // encoded ?
type Type = Exp.Type;

/* variables are used in function argument list and declaration list */
type Variables = list<Variable>;
type Statements = list<Statement>;

type FunctionArguments = Variables;
type FunctionBody = Statements;
type VariableDeclarations = Variables;

type Includes = list<String>;
type Libs = list<String>;

uniontype FunctionName
  record FUNCTION_NAME
    /* we need the model name as we might generate C++ code modelName::functionName */
    String modelName    "the model containing the function"; 
    String functionName "the name of the function";
  end FUNCTION_NAME;
end FunctionName;

/* a variable represents a name, a type and a possible default value */
uniontype Variable
  record VARIABLE
    //the name should become a Path because templates will take responsibility for ident encodings
    //an alternative is to expect names with dot notation inside the string; an encoding function sholud be then imported
    DAE.ComponentRef       name   "variable name";
    Type          ty    "variable type";
    Option<Exp.Exp> value "variable default value";
    //list<Exp.Exp> instDims "for array allocation, DAE.ICONST() or DAE.CREF()"; //only on input vars (dimensions) dependens
//??st missing    VariableAttributes attributes "Based on DAE.VariableAttributes, but possibly extended"; 
    list<DAE.Exp> instDims;
  end VARIABLE;  
end Variable;


uniontype Equations
   record RESIDUAL_EQUATION
      Exp.Exp residual;
   end RESIDUAL_EQUATION;
   
   /* What is needed more here??? */

end Equations;

uniontype Statement
  record ALGORITHM
    list<Algorithm.Statement> statementLst; // in functions
  end ALGORITHM;
  
  /*
  record VAR_DECL_SCALAR
    Variable var;    
  end VAR_DECL_SCALAR;
  
  record VAR_DECL_ARRAY
    Variable var;   
    list<Exp.Exp> dims; 
  end VAR_DECL_ARRAY;
  */
  record BLOCK // a workaroud for the VALUEBLOCK ... should be redesigned inside Exp/DAE
    VariableDeclarations variableDeclarations "the declarations of local variables";
    FunctionBody body;
  end BLOCK;
  
  record SYSTEM
     System stmt;
  end SYSTEM;

  record WHEN_CHECK //see code in  SimCodegen.buildWhenConditionChecks3
    Integer whenClauseIndex;
    Integer helpVarIndex;
    Boolean isElseWhen;
  end WHEN_CHECK;
  
  record DISCRETE_CHECK //see code in  SimCodegen.buildDiscreteVarChangesAddEvent
    Exp.ComponentRef componentRef;
  end DISCRETE_CHECK;

/* 
??  SimCodegen.generateOutputFunctionCode2/generateInputFunctionCode2
  Integer index;
  Exp.ComponentRef cr;  
  assign_str = Util.stringAppendList({"localData->outputVars[",i_str,"] =",cr_str,";"});
  assign_str = Util.stringAppendList({cr_str," = localData->inputVars[",i_str,"];"});

?? SimCodegen.generateInitialResidualEqn  
  Exp.Exp e ... var 
  assign = Util.stringAppendList({"localData->initialResiduals[i++] = ",var,";"});
*/
end Statement;

/* Functions */
uniontype Function
  record FUNCTION    
//??    ReturnType returnType     "the return type of the function";
    Path name;
    Variables inVars;
    Variables outVars;
    list<RecordDeclaration> recordDecls; 
    //FunctionName functionName "the function name";
    FunctionArguments functionArguments "the function arguments";
    VariableDeclarations variableDeclarations "the declarations of local variables";
    FunctionBody body;
  end FUNCTION;

  record EXTERNAL_FUNCTION
//??    ReturnType returnType     "the return type of the function";
    FunctionName functionName "the function name";
    FunctionArguments functionArguments "the function arguments";
    VariableDeclarations variableDeclarations "the declarations of local variables";
    Includes includes "the list of possible needed includes";
    Libs libs "the list of dependent libraries";
    String language " \"C\" or \"Fortran\" according to language specification";
  end EXTERNAL_FUNCTION;
end Function;

uniontype RecordDeclaration
  record RECORD_DECL_FULL
    Ident name; // struct (record) name ? encoded
    Path defPath; //definition path   
    Variables variables; //only name and type
    //Types.Type fullType;
  end RECORD_DECL_FULL;
  
  record RECORD_DECL_DEF
    Path path; //definition path .. encoded ?    
    list<Ident> fieldNames;
  end RECORD_DECL_DEF;
end RecordDeclaration;


/*
*	Linear systems (A and b matrix) list<tuple<Integer,Integer,Exp>>
*	NonLinear systems (residuals) 
*	Mixed linear systems  (A and b matrix, discrete variables (with domain information)) 
*	Mixed nonlinear systems (residuals, discrete variables (with domain information)) 
*	Jacobians list<tuple<Integer,Integer,Exp>> 
*	Data about variables, components, zero-crossings, etc (e.g. strings of originalname, equation, etc)
*/

type SparseMatrix = list<tuple<Integer,Integer,Exp.Exp>>;

type Jacobian = SparseMatrix;

uniontype System
  
  record LINEAR_SYSTEM
    Variables solvedFor;
    SparseMatrix A;
    SparseMatrix b;
  end LINEAR_SYSTEM;
  
  record NON_LINEAR_SYSTEM
    Variables solvedFor;
    Equations residuals;
    Jacobian jac;
  end NON_LINEAR_SYSTEM;
  
  record MIXED_SYSTEM
    Variables discreteVars;
    System continouosSystem;
//??    Statements discreteAssignments;
  end MIXED_SYSTEM;   
  
end System;

/* Is this required? 
to be able to generate different code depending on what method we use to solve a system we also have SolvingMethod */
//?? type SystemCode = tuple<System, SolvingMethod>;

type GlobalVariables = Variables;

type MacroDefinitions = list<String> "for preprocessor macros";

type Includes = list<String> " for model-specific include-files, each string contain only the file-name";

// Root data structure containing information required for templates to
// generate simulation code.
uniontype SimCode
  record SIMCODE
    ModelInfo modelInfo;
//    MacroDefinitions macroDefinitions "requires target code to have a preprocessor, or preprocessor must be done before code generation";
//    Includes includes "include files";
//    GlobalVariables globalVars ;
    list<Function> functions;
    list<SimEqSystem> allEquations;
    list<SimEqSystem> stateContEquations;
    list<SimEqSystem> nonStateContEquations;
    list<SimEqSystem> nonStateDiscEquations;
    list<SimEqSystem> residualEquations;
    list<SimEqSystem> initialEquations;
    list<SimEqSystem> parameterEquations;
    list<SimEqSystem> removedEquations;
    list<DAELow.ZeroCrossing> zeroCrossings;
    list<list<SimVar>> zeroCrossingsNeedSave;
    list<HelpVarInfo> helpVarInfo;
    list<SimWhenClause> whenClauses;
    list<DAE.ComponentRef> discreteModelVars;
  end SIMCODE;
end SimCode;

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
  record SES_NOT_IMPLEMENTED
    String msg;
  end SES_NOT_IMPLEMENTED;
end SimEqSystem;

uniontype Context
  record SIMULATION end SIMULATION;
  record OTHER end OTHER;
end Context;

function createSimulationContext
  output Context context;
algorithm
  context := SIMULATION();
end createSimulationContext;

function createOtherContext
  output Context context;
algorithm
  context := OTHER();
end createOtherContext;

uniontype SimWhenClause
  record SIM_WHEN_CLAUSE
    list<DAE.ComponentRef> conditionVars;
    list<DAELow.ReinitStatement> reinits;
    Option<DAELow.WhenEquation> whenEq;
  end SIM_WHEN_CLAUSE;
end SimWhenClause;

uniontype ModelInfo
  record MODELINFO
    String name;
    String directory;
    VarInfo varInfo;
    SimVars vars;
  end MODELINFO;
end ModelInfo;

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

uniontype SimVar
  record SIMVAR
    DAE.ComponentRef name;
    DAE.ComponentRef origName;
    String comment;
    Integer index;
    Boolean isFixed;
    Exp.Type type_;
    Boolean isDiscrete;
    Option<DAE.ComponentRef> arrayCref; // if this var is the first in an array
  end SIMVAR;
end SimVar;

uniontype TargetSettings
  record TS_C
    String CCompiler;
    String CXXCompiler;
    String linker;
    // ... everything needed for makefile generation ... CevalScript.generateMakefileHeader()
  end TS_C;
end TargetSettings;
    

/*********************************************************/
/*********************************************************/
/*********************************************************/

public function translateModel
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
        ptot = Interactive.getTotalProgram(className,p);
        p_1 = SCodeUtil.translateAbsyn2SCode(ptot);
        (cache,env,_,dae as DAE.DAE(dael)) = 
        Inst.instantiateClass(cache,InstanceHierarchy.emptyInstanceHierarchy,p_1,className);
        ((dae as DAE.DAE(dael))) = DAEUtil.transformIfEqToExpr(dae);
        ic_1 = Interactive.addInstantiatedClass(ic, Interactive.INSTCLASS(className,dael,env));
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
                                functions);
        /* feed SimCode data structure to template to produce target code: this
           generates Model.cpp, Model_functions.cpp, and Makefile */
        _ = Tpl.tplString(SimCodeC.translateModel, simCode);
        /* generate makefile in old way since it's not implemented in
           templates yet */
        SimCodegen.generateMakefile(makefilename, filenameprefix, libs,
                                    file_dir);
      then
        (cache,Values.STRING("SimCode: The model has been translated"),st,indexed_dlow_1,libs,file_dir);
  end matchcontinue;
end translateModel;

/* Finds the called functions in DAELow and transforms them to a list of
   libraries and a list of Function uniontypes. */
public function createFunctions 
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
        funcpaths = SimCodegen.getCalledFunctions(dae, dlow);
        //Debug.fprint("info", "Found called functions: ") "debug" ;
        //debugpathstrs = Util.listMap(funcpaths, Absyn.pathString) "debug" ;
        //debugpathstr = Util.stringDelimitList(debugpathstrs, ", ") "debug" ;
        //Debug.fprintln("info", debugpathstr) "debug" ;
        funcelems = SimCodegen.generateFunctions2(p, funcpaths);
        //debugstr = Print.getString();
        //Print.clearBuf();
        //Debug.fprintln("info", "Generating functions, call Codegen.\n") "debug" ;
        //(_,libs1) = SimCodegen.generateExternalObjectIncludes(dlow);
        libs1 = {};
        //usless filter, all are already functions from generateFunctions2
        //funcelems := Util.listFilter(funcelems, DAEUtil.isFunction);
        fns = elaborateFunctions(funcelems);
        //TODO: libs ? see in Codegen.cPrintFunctionIncludes(cfns)
        libs2 = {};
      then
        (Util.listUnion(libs1,libs2), fns);
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Code generation of Modelica functions failed. "});
      then
        fail();
  end matchcontinue;
end createFunctions;

protected function elaborateFunctions 
  input list<DAE.Element> daeElements;
  output list<Function> functions;
protected
  list<Function> fns;  
algorithm
  (fns, _) := elaborateFunctions2(daeElements, {},{});
  functions := listReverse(fns);  
end elaborateFunctions;

protected function elaborateFunctions2 
  input list<DAE.Element> daeElements;
  input list<Function> inFunctions;
  input list<String> inRecordTypes;
  output list<Function> outFunctions;
  output list<String> outRecordTypes;
algorithm
  (outFunctions, outRecordTypes):=
  matchcontinue (daeElements, inFunctions, inRecordTypes)
    local
      list<Function> accfns, fns;
      Function fn;
      list<String> rt, rt_1, rt_2;
      DAE.Element fel;
      list<DAE.Element> rest;
    case ({},accfns,rt) then (accfns,rt);
    case ((fel :: rest),accfns,rt)
      equation
        (fn,rt_1) = elaborateFunction(fel, rt);
        (fns,rt_2) = elaborateFunctions2(rest, fn::accfns, rt_1);        
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
      list<DAE.Element> dae,bivars,orgdae,daelist,funrefs, algs, vars;
      list<String> struct_strs,arg_strs,includes,libs,struct_strs_1,funrefStrs;
      //CFunction head_cfn,body_cfn,cfn,rcw_fn,func_decl,ext_decl;
      Absyn.Path fpath;
      list<tuple<String, Types.Type>> args;
      Types.Type restype,tp;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extretarg;
      Option<Absyn.Annotation> ann;
      DAE.ExternalDecl extdecl;
      //list<CFunction> cfns;
      DAE.Element comp;
      list<String> rt, rt_1, struct_funrefs, struct_funrefs_int;
      list<Absyn.Path> funrefPaths;
      Variables outVars, inVars, funArgs, varDecls;
      list<RecordDeclaration> recordDecls;
      FunctionBody body;
      DAE.InlineType inl;
      
    /* Modelica functions External functions */
    case (DAE.FUNCTION(path = fpath,
                       functions = {DAE.FUNCTION_DEF(DAE.DAE(elementLst = dae))},
                       type_ = (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_),
                       partialPrefix = false,inlineType = inl),rt) 
      equation
        //fn_name_str = generateFunctionName(fpath);
        //fn_name_str = stringAppend("_", fn_name_str);
        //Debug.fprintl("cgtr", {"generating function ",fn_name_str,"\n"});
        //Debug.fprintln("cgtrdumpdae3", "Dumping DAE:");
        //Debug.fcall("cgtrdumpdae3", DAEUtil.dump2, DAE.DAE(dae));
        outVars = Util.listMap(DAEUtil.getOutputVars(dae), daeInOutSimVar);
        inVars = Util.listMap(DAEUtil.getInputVars(dae), daeInOutSimVar);
        funArgs = Util.listMap(args, typesSimFunctionArg);
        (recordDecls,rt_1) = elaborateRecordDeclarations(dae,{}, rt);
        
        vars = Util.listFilter(dae, isVarQ);
        varDecls = Util.listMap(vars, daeInOutSimVar);
        
        algs = Util.listFilter(dae, DAEUtil.isAlgorithm);
        body = Util.listMap(algs, elaborateStatement);
        
        //struct_strs_1 = generateResultStruct(outvars, fpath);
        //struct_strs = listAppend(struct_strs, struct_strs_1);
        /*-- MetaModelica Partial Function. sjoelund --*/
        //funrefs = Util.listSelect(invars, DAEUtil.isFunctionRefVar);
        //struct_funrefs = Util.listFlatten(Util.listMap(funrefs, generateFunctionRefReturnStruct));
        /*--                                           --*/
        /*
        retstr = generateReturnType(fpath);
        arg_strs = Util.listMap(args, generateFunctionArg);
        head_cfn = cMakeFunction(retstr, fn_name_str, struct_strs, arg_strs);
        body_cfn = generateFunctionBody(fpath, dae, restype, struct_funrefs);
        cfn = cMergeFn(head_cfn, body_cfn);
        rcw_fn = generateReadCallWrite(fn_name_str, outvars, retstr, invars);
        */
      then
        (FUNCTION(fpath,inVars,outVars,recordDecls,funArgs,varDecls,body ),rt_1);
    
    /* MetaModelica Partial Function. sjoelund */    
    /*
    case (DAE.FUNCTION(path = fpath,
                       dAElist = DAE.DAE(elementLst = dae),
                       type_ = (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_),
                       partialPrefix = true),rt) 
      then
        ({},{});
    */    
    /* Builtin functions - stefan */
    /*
    case (DAE.EXTFUNCTION(path = fpath,
                          dAElist = DAE.DAE(elementLst = orgdae),
                          type_ = (tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_)),
                          externalDecl = extdecl),rt)
      equation
        true = isBuiltinFunction(fpath);
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        DAE.EXTERNALDECL(ident = extfnname, external_ = extargs,parameters = extretarg, returnType = lang, language = ann) = extdecl;
        dae = Inst.initVarsModelicaOutput(orgdae);
        outvars = DAEUtil.getOutputVars(dae);
        invars = DAEUtil.getInputVars(dae);
        bivars = DAEUtil.getBidirVars(dae);
        (struct_strs,rt_1) = generateStructsForRecords(dae,rt);
        struct_strs_1 = generateResultStruct(outvars, fpath);
        struct_strs = listAppend(struct_strs, struct_strs_1);
        retstructtype = generateReturnType(fpath);
        retstr = generateExtFunctionName(extfnname, lang);
        extfnname_1 = generateExtFunctionName(extfnname,lang);
        arg_strs = generateExtFunctionArgs(extargs, lang);
        (includes,libs) = generateExtFunctionIncludes(ann);
        rcw_fn = generateReadCallWriteExternal(fn_name_str, outvars, retstructtype, invars, extdecl, bivars);
        ext_decl = generateExternalWrapperCall(fn_name_str, outvars, retstructtype, invars, extdecl, bivars, tp);
        cfns = {rcw_fn, ext_decl};
      then (cfns, rt_1);
    */
    /* External functions */
    /*
    case (DAE.EXTFUNCTION(path = fpath,
                          dAElist = DAE.DAE(elementLst = orgdae),
                          type_ = (tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_)),
                          externalDecl = extdecl),rt) 
      equation
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        Debug.fprintl("cgtr", {"generating external function ",fn_name_str,"\n"});
        DAE.EXTERNALDECL(ident = extfnname,external_ = extargs,parameters = extretarg,returnType = lang,language = ann) = extdecl;
        Debug.fprintln("cgtrdumpdae1", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae1", DAEUtil.dump2, DAE.DAE(orgdae));
        dae = Inst.initVarsModelicaOutput(orgdae);
        Debug.fprintln("cgtrdumpdae2", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae2", DAEUtil.dump2, DAE.DAE(dae));
        outvars = DAEUtil.getOutputVars(dae);
        invars = DAEUtil.getInputVars(dae);
        bivars = DAEUtil.getBidirVars(dae);
        (struct_strs,rt_1) = generateStructsForRecords(dae, rt);
        struct_strs_1 = generateResultStruct(outvars, fpath);
        struct_strs = listAppend(struct_strs, struct_strs_1);
        retstructtype = generateReturnType(fpath);
        retstr = generateExtReturnType(extretarg);
        extfnname_1 = generateExtFunctionName(extfnname, lang);
        extfnname_1 = Util.if_("Java" ==& lang, "", extfnname_1);
        arg_strs = generateExtFunctionArgs(extargs, lang);
        (includes,libs) = generateExtFunctionIncludes(ann);
        includes = Util.if_("Java" ==& lang, "#include \"java_interface.h\"" :: includes, includes);
        rcw_fn = generateReadCallWriteExternal(fn_name_str, outvars, retstructtype, invars, extdecl, bivars);
        ext_decl = generateExternalWrapperCall(fn_name_str, outvars, retstructtype, invars, extdecl, bivars, tp);
        func_decl = cMakeFunctionDecl(retstr, extfnname_1, struct_strs, arg_strs, includes, libs);
        cfns = {func_decl, rcw_fn, ext_decl};
      then
        (cfns,rt_1);
        
    case (DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = daelist)),rt)
      equation
        (cfns,rt_1) = generateFunctionsElist(daelist,rt);
      then
        (cfns,rt_1);
    */    
    case (comp,rt)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"SimCode.elaborateFunction failed"});
      then
        fail();
  end matchcontinue;
end elaborateFunction;


protected function isVarQ 
"function isVarQ
  Succeds if DAE.Element is a variable or constant that is not input."
  input DAE.Element inElement;
algorithm
  _:=  matchcontinue (inElement)
    local
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(componentRef = id,kind = vk,direction = vd)
      equation
        generateVarQ(vk);
        generateVarQ2(vd);
      then
        ();
  end matchcontinue;
end isVarQ;


protected function generateVarQ 
"function generateVarQ
  Helper function to isVarQ."
  input DAE.VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    case DAE.VARIABLE() then ();
    case DAE.PARAM() then ();
  end matchcontinue;
end generateVarQ;

protected function generateVarQ2 
"function generateVarQ2
  Helper function to isVarQ."
  input DAE.VarDirection inVarDirection;
algorithm
  _:=
  matchcontinue (inVarDirection)
    case DAE.OUTPUT() then ();
    case DAE.BIDIR() then ();
  end matchcontinue;
end generateVarQ2;


public function elaborateStatement 
"function elaborateStatement
  "
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


protected function daeInOutSimVar
  input DAE.Element inElement;
  output Variable outVar;
algorithm
  outVar := matchcontinue(inElement)
    local
      String name;
      Type expType;
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
        Debug.fprint("failtrace", "-SimCode.daeInOutSimVar failed\n");
      then
        fail();
  end matchcontinue;
end daeInOutSimVar;

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
        expType = typesExpType(tty);        
      then
        VARIABLE(DAE.CREF_IDENT(name, expType, {}),expType,NONE,{});
  end matchcontinue;
end typesSimFunctionArg;

protected function typesExpType  // TODO: change to Types.elabType
"function: generateType
  Generates code for a Type."
  input Types.Type inType;
  output Exp.Type outType;
algorithm
  outType:=
  matchcontinue (inType)
    local
      list<Types.Type> tys;
      list<Exp.Type> etys;
      Types.Type arrayty, ty;
      Exp.Type ety;
      list<Integer> dims;
      list<Option<Integer>> dimOpts;
      ClassInf.State cType;
      list<Types.Var> tVarLst;
      list<Exp.Var> eVarLst;
      
    case ((DAE.T_TUPLE(tupleType = tys),_))
      equation
        etys = Util.listMap(tys, typesExpType);
      then
        DAE.ET_METATUPLE(etys);
        
    //TODO: check this for the proper order of dimensions or make a custom  flattenArrayType(tys) where the arrayDim are properly transformed (now, when there is a NONE, it is just omitted ?? correct)
    case ((ty as (DAE.T_ARRAY(arrayDim = _),_)))
      equation
        (arrayty,dims) = Types.flattenArrayType(ty);
        dimOpts = Util.listMap(dims, Util.makeOption);
        ety = typesExpType(arrayty);
      then
        DAE.ET_ARRAY(ety, dimOpts);
        
    case ((DAE.T_INTEGER(varLstInt = _),_)) then DAE.ET_INT();
    case ((DAE.T_REAL(varLstReal = _),_)) then DAE.ET_REAL();
    case ((DAE.T_STRING(varLstString = _),_)) then DAE.ET_STRING();
    case ((DAE.T_BOOL(varLstBool = _),_)) then DAE.ET_BOOL();
    //what about Option<Type> complexTypeOption in DAE.T_COMPLEX ?
    case ((DAE.T_COMPLEX(complexClassType = cType as ClassInf.RECORD(name), complexVarLst = tVarLst),_))
      local String name;
      equation
        eVarLst = Util.listMap(tVarLst, typesExpVar);
      then
        DAE.ET_COMPLEX(name, eVarLst, cType);        
    case ((DAE.T_LIST(ty),_))
      equation
        ety = typesExpType(ty);
      then
        DAE.ET_LIST(ety);    
    //?? what is the difference between the T_TUPL and T_METATUPLE in context of Exp.Type ?
    case ((DAE.T_METATUPLE(tys),_)) 
      equation
        etys = Util.listMap(tys, typesExpType);
      then
        DAE.ET_METATUPLE(etys);        
    case ((DAE.T_METAOPTION(ty),_)) 
      equation
        ety = typesExpType(ty);
      then
        DAE.ET_METAOPTION(ety);
    
    //?? loss of information
    case ((DAE.T_FUNCTION(_,_,_),_)) then DAE.ET_FUNCTION_REFERENCE_FUNC;
    case ((DAE.T_UNIONTYPE(_),_)) then DAE.ET_UNIONTYPE;
    case ((DAE.T_POLYMORPHIC(_),_)) then DAE.ET_POLYMORPHIC;
    case ((DAE.T_BOXED(ty),_))
      equation
        ety = typesExpType(ty);
      then
        DAE.ET_BOXED(ety);

    case (ty)
      equation
        Debug.fprint("failtrace", "#-- SimCode.typesExpType failed\n");
      then
        fail();
  end matchcontinue;
end typesExpType;


protected function typesExpVar
  input Types.Var typesVar;
  output Exp.Var expVar;
algorithm
  expVar := matchcontinue(typesVar)
    local
      String name;
      Exp.Type expType;
      Types.Type typesType;
    case (DAE.TYPES_VAR(name = name, type_ = typesType))
      equation
        expType = typesExpType(typesType);
      then DAE.COMPLEX_VAR(name,expType);
  end matchcontinue;
end typesExpVar;

protected function typesVar
  input Types.Var inTypesVar;
  output Variable outVar;
algorithm
  outVar := matchcontinue(inTypesVar)
    local
      String name;
      Type expType;
      Types.Type typesType;
    case (DAE.TYPES_VAR(name = name, type_ = typesType))
      equation
        expType = typesExpType(typesType);
      then VARIABLE(DAE.CREF_IDENT(name, expType, {}),expType,NONE,{});
  end matchcontinue;
end typesVar;


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
      equation 
        accRecDecls = listReverse(accRecDecls); 
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
        expl = Codegen.getMatchingExpsList(expl, Codegen.matchCalls);
        (accRecDecls,rt_2) = elaborateRecordDeclarationsForMetarecords(expl, accRecDecls, rt);
        //TODO: ? what about rest ? , can be there something else after the ALGORITHM
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
      Absyn.Path path;
      list<Types.Var> varlst;
      String name, first_str, last_str, path_str;
      list<String> res,strs,rest_strs,decl_strs,rt,rt_1,rt_2,record_definition,fieldNames;
      list<RecordDeclaration> accRecDecls;
      Variables vars;
      
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(string = name), complexVarLst = varlst),SOME(path)), accRecDecls, rt)
      equation
        failure(_ = Util.listGetMember(name,rt));
        
        vars = Util.listMap(varlst, typesVar);
        accRecDecls = RECORD_DECL_FULL(name, path, vars) :: accRecDecls;        
        rt_1 = name :: rt;        
        (accRecDecls,rt_2) = elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);
      then (accRecDecls,rt_2);
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(string = name), complexVarLst = varlst),_), accRecDecls, rt)
      then (accRecDecls,rt);
    case ((_,_), accRecDecls, rt) then 
      (RECORD_DECL_FULL("#an odd record#", Absyn.IDENT("?noname?"), {}) :: accRecDecls ,rt);
  end matchcontinue;
end elaborateRecordDeclarationsForRecord;


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

// ********** START COPY FROM SIMCODEGEN MODULE **********

// Functions copied for adaption.

// Copied from SimCodegen.generateSimulationCode.
public function createSimCode
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
  output SimCode simCode;
algorithm
  simCode :=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inIntegerLstLst7,inPath8,inString9,inString10,inString11,functions)
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
      list<SimEqSystem> stateContEquations;
      list<SimEqSystem> nonStateContEquations;
      list<SimEqSystem> nonStateDiscEquations;
      list<SimEqSystem> residualEquations;
      list<SimEqSystem> initialEquations;
      list<SimEqSystem> parameterEquations;
      list<SimEqSystem> removedEquations;
      list<DAELow.ZeroCrossing> zeroCrossings;
      list<list<SimVar>> zeroCrossingsNeedSave;
      list<SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
    case (dae,dlow,ass1,ass2,m,mt,comps,class_,filename,funcfilename,fileDir,functions)
      equation
        cname = Absyn.pathString(class_);

        (blt_states, blt_no_states) = DAELow.generateStatePartition(comps, dlow, ass1, ass2, m, mt);

        (c_eventchecking,helpVarInfo1) = generateEventCheckingCode(dlow, comps, ass1, ass2, m, mt, class_);
        (helpVarInfo,dlow2) = generateHelpVarsForWhenStatements(helpVarInfo1,dlow);
        (out_str,n_o) = generateOutputFunctionCode(dlow2);
        (in_str,n_i) = generateInputFunctionCode(dlow2);
        n_h = listLength(helpVarInfo);

        residualEquations = createResidualEquations(dlow2, ass1, ass2);
        nres = listLength(residualEquations);

        //(s_code3) = generateInitialBoundParameterCode(dlow2);
        //cglobal = generateGlobalData(class_, dlow2, n_o, n_i, n_h, nres,fileDir);
        //coutput = generateComputeOutput(cname, dae, dlow2, ass1, ass2,m,mt, blt_no_states);
        //cstate = generateComputeResidualState(cname, dae, dlow2, ass1, ass2, blt_states);
        //c_ode = generateOdeCode(dlow2, blt_states, ass1, ass2, m, mt, class_);
        //s_code = generateInitialValueCode(dlow2);
        cwhen = generateWhenClauses(cname, dae, dlow2, ass1, ass2, comps);
        //czerocross = generateZeroCrossing(cname, dae, dlow2, ass1, ass2, comps, helpVarInfo);
        //(extObjIncludes,_) = generateExternalObjectIncludes(dlow2);
        //extObjInclude = Util.stringDelimitList(extObjIncludes,"\n");
        //extObjInclude = Util.stringAppendList({"extern \"C\" {\n",extObjInclude,"\n}\n"});
        // Add model info
        modelInfo = createModelInfo(class_, dlow2, n_o, n_i, n_h, nres, fileDir);
        allEquations = createEquations(true, dae, dlow2, ass1, ass2, comps);
        stateContEquations = createEquations(false, dae, dlow2, ass1, ass2, blt_states);
        (contBlocks, discBlocks) = splitOutputBlocks(dlow2, ass1, ass2, m, mt, blt_no_states);
        nonStateContEquations = createEquations(true, dae, dlow2, ass1, ass2,
                                                contBlocks);
        nonStateDiscEquations = createEquations(true, dae, dlow2, ass1, ass2,
                                                discBlocks);
        initialEquations = createInitialEquations(dlow2);
        parameterEquations = createParameterEquations(dlow2);
        removedEquations = createRemovedEquations(dlow2);
        zeroCrossings = createZeroCrossings(dlow2);
        zeroCrossingsNeedSave = createZeroCrossingsNeedSave(zeroCrossings, dae, dlow2, ass1, ass2, comps);
        whenClauses = createSimWhenClauses(dlow2);
        discreteModelVars = extractDiscreteModelVars(dlow2, mt);
        simCode = SIMCODE(modelInfo, functions, allEquations, stateContEquations,
                          nonStateContEquations, nonStateDiscEquations,
                          residualEquations, initialEquations,
                          parameterEquations, removedEquations, zeroCrossings,
                          zeroCrossingsNeedSave, helpVarInfo, whenClauses,
                          discreteModelVars);
      then
        simCode;
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of simulation using code using templates failed"});
      then
        fail();
  end matchcontinue;
end createSimCode;

public function createRemovedEquations
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

public function extractDiscreteModelVars
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

public function varNotSolvedInWhen
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

public function createSimWhenClauses
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

public function createSimWhenClausesWithEqs
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

public function findWhenEquation
  input list<DAELow.Equation> eqs;
  input Integer index;
  output Option<DAELow.WhenEquation> whenEq;
algorithm
  whenEq :=
  matchcontinue (eqs, index)
    local
      DAELow.WhenEquation eq;
      list<DAELow.Equation> restEqs;
      Integer eqindex;
    case ((DAELow.WHEN_EQUATION(eq as DAELow.WHEN_EQ(index=eqindex))) :: restEqs, index)
      equation
        true = eqindex == index;
      then SOME(eq);
    case (_ :: restEqs, index)
      equation
        whenEq = findWhenEquation(restEqs, index);
      then whenEq;
    case ({}, _)
      then NONE();
  end matchcontinue;
end findWhenEquation;

public function whenClauseToSimWhenClause
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

public function createEquations
  input Boolean genDiscrete;
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input list<list<Integer>> comps;
  output list<SimEqSystem> equations;
algorithm
  equations :=
  matchcontinue (genDiscrete, dae, dlow, ass1, ass2, comps)
    local
      list<Integer> comp;
      list<list<Integer>> restComps;
      list<DAELow.Equation> equations_2;
      SimEqSystem equation_;
      Integer index;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      DAELow.Var v;
    case (genDiscrete, dae, dlow, ass1, ass2, {})
      then {};
    /* ignore when equations: they are handled elsewhere */
    case (genDiscrete, dae, dlow, ass1, ass2, {index} :: restComps)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.WHEN_EQUATION(_),_) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        equations = createEquations(genDiscrete, dae, dlow, ass1, ass2, restComps);
      then
        equations;
    /* ignore discrete if we should not generate them */
    case (false, dae, dlow, ass1, ass2, {index} :: restComps)
      equation
        DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns) = dlow;
        (DAELow.EQUATION(_,_),v) = getEquationAndSolvedVar(index, eqns, vars, ass2);
        true = hasDiscreteVar({v});
        equations = createEquations(genDiscrete, dae, dlow, ass1, ass2, restComps);
      then
        equations;
    /* single equation */
    case (genDiscrete, dae, dlow, ass1, ass2, {index} :: restComps)
      equation
        equation_ = createEquation(dae, dlow, ass1, ass2, index);
        equations = createEquations(genDiscrete, dae, dlow, ass1, ass2, restComps);
      then
        equation_ :: equations;
    /* multiple equations that must be solved together (algebraic loop) */
    case (genDiscrete, dae, dlow, ass1, ass2, comp :: restComps)
      equation
        equation_ = createOdeSystem(genDiscrete, dlow, ass1, ass2, comp);
        equations = createEquations(genDiscrete, dae, dlow, ass1, ass2, restComps);
      then
        equation_ :: equations;
    case (_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createEquations failed"});
      then
        fail();
  end matchcontinue;
end createEquations;

public function createEquation
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input Integer eqNum;
  output SimEqSystem equation_;
algorithm
  equation_ :=
  matchcontinue (dae, dlow, ass1, ass2, eqNum)
    local
      list<Integer> restEqNums;
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
      String varname;
      String id;
      Integer indx;
      Integer e_1;
      Algorithm.Algorithm alg;
      Algorithm.Algorithm[:] algs;
      list<DAE.Statement> algStatements;
      list<DAE.Exp> inputs,outputs;
      DAELow.VariableArray vararr;
    /* single equation: non-state */
    case (dae, DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns),
          ass1, ass2, eqNum)
      equation
        (DAELow.EQUATION(e1, e2),
         v as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,
                         flowPrefix,streamPrefix))
        = getEquationAndSolvedVar(eqNum, eqns, vars, ass2);
        isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        exp_ = Exp.solve(e1, e2, varexp);
        varname = Exp.printComponentRefStr(cr);
      then
        SES_SIMPLE_ASSIGN(cr, exp_);
    /* single equation: state */
    case (dae, DAELow.DAELOW(orderedVars=vars, orderedEqs=eqns),
          ass1, ass2, eqNum)
      equation
        (DAELow.EQUATION(e1, e2),
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
    /* single equation: algorithm */
    case (dae, DAELow.DAELOW(orderedVars=DAELow.VARIABLES(varArr=vararr),orderedEqs=eqns,algorithms=algs), ass1, ass2, eqNum)
      equation
        e_1 = eqNum - 1 "Algorithms Each algorithm should only be genated once." ;
        DAELow.ALGORITHM(indx,inputs,outputs) = DAELow.equationNth(eqns, e_1);
        alg = algs[indx + 1];
        DAE.ALGORITHM_STMTS(algStatements) = alg;
      then
        SES_ALGORITHM(algStatements);
    case (_,_,_,_,_)
      then
        SES_NOT_IMPLEMENTED("none of cases in createEquation succeeded");
  end matchcontinue;
end createEquation;

public function createOdeSystem
  input Boolean genDiscrete "if true generate discrete equations";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  output SimEqSystem equation_;
algorithm
  equation_ :=
  matchcontinue (genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLst4)
    local
      String rettp,fn;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,var_lst_1,cont_var1;
      DAELow.Variables vars_1,vars,knvars,exvars;
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,daelow,subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      String s;
      Codegen.CFunction s2,s1,s0,s2_1,s3,s4,cfn;
      Integer cg_id_1,cg_id,cg_id3,cg_id1,cg_id2,cg_id4,cg_id5;
      list<CFunction> f1,extra_funcs1;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      DAELow.ExternalObjectClasses eoc;
      list<String> retrec,arg,locvars,init,locvars,stmts,cleanups,stmts_1,stmts_2;
      Integer numValues;
    /* mixed system of equations, continuous part only */
    case (false,(daelow as DAELow.DAELOW(vars,knvars,exvars,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
        // States are solved for der(x) not x.
        cont_var1 = Util.listMap(cont_var, transformXToXd);
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,eqns_1,se,ie,ae,al,ev,eoc);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,true);
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        equation_ = createOdeSystem2(false, false, cont_subsystem_dae, jac, jac_tp);
      then
        equation_;
    /* mixed system of equations, both continous and discrete eqns*/
    case (true,(dlow as DAELow.DAELOW(vars,knvars,exvars,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
        // States are solved for der(x) not x.
        cont_var1 = Util.listMap(cont_var, transformXToXd);
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,eqns_1,se,ie,ae,al,ev,eoc);
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
      then
        SES_NOT_IMPLEMENTED("mixed system not implemented");
    /* continuous system of equations */
    case (genDiscrete,(daelow as DAELow.DAELOW(vars,knvars,exvars,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,block_)
      equation
        // extract the variables and equations of the block.
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        // States are solved for der(x) not x.
        var_lst_1 = Util.listMap(var_lst, transformXToXd);
        vars_1 = DAELow.listVar(var_lst_1);
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,eqns_1,se,ie,ae,al,ev,eoc);
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,false);
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac);
        equation_ = createOdeSystem2(false, genDiscrete, subsystem_dae, jac, jac_tp);
      then
        equation_;
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createOdeSystem failed"});
      then
        fail();
  end matchcontinue;
end createOdeSystem;

public function createOdeSystem2
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input DAELow.JacobianType inJacobianType;
  output SimEqSystem equation_;
algorithm
  equation_ :=
  matchcontinue (mixedEvent,genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inJacobianType)
    local
      Codegen.CFunction s1,s2,s3,s4,s5,s;
      Integer cg_id_1,cg_id,eqn_size,unique_id,cg_id1,cg_id2,cg_id3,cg_id4,cg_id5;
      list<CFunction> f1;
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
    /* A single array equation */
    case (mixedEvent,_,dae,jac,jac_tp)
      equation
        singleArrayEquation(dae); // fails if not single array eq
        equation_ = createSingleArrayEqnCode(dae, jac);
      then
        equation_;
    /* A single algorithm section for several variables. */
    case (mixedEvent,genDiscrete,dae,jac,jac_tp)
      equation
        singleAlgorithmSection(dae);
        equation_ = createSingleAlgorithmCode(dae, jac);
      then
        equation_;
    //    /* constant jacobians. Linear system of equations (A x = b) where
    //     A and b are constants. TODO: implement symbolic gaussian elimination here. Currently uses dgesv as
    //     for next case */
    //case (mixedEvent,genDiscrete,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_CONSTANT())
    //  local list<tuple<Integer, Integer, DAELow.Equation>> jac;
    //  equation
    //    eqn_size = DAELow.equationSize(eqn);
    //    (s1,cg_id_1,f1) = generateOdeSystem2(mixedEvent,genDiscrete,d, SOME(jac), DAELow.JAC_TIME_VARYING(), cg_id) "NOTE: Not impl. yet, use time_varying..." ;
    //  then
    //    (s1,cg_id_1,f1);

    //    /* Time varying jacobian. Linear system of equations that needs to
    //    	  be solved during runtime. */
    //case (mixedEvent,_,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_TIME_VARYING())
    //  local list<tuple<Integer, Integer, DAELow.Equation>> jac;
    //  equation
    //    //print("linearSystem of equations:");
    //    //DAELow.dump(d);
    //    //print("Jacobian:");print(DAELow.dumpJacobianStr(SOME(jac)));print("\n");
    //    eqn_size = DAELow.equationSize(eqn);
    //    unique_id = tick();
    //    (s1,cg_id1) = generateOdeSystem2Declaration(mixedEvent,eqn_size, unique_id, cg_id);
    //    (s2,cg_id2) = generateOdeSystem2PopulateAb(mixedEvent,jac, v, eqn, unique_id, cg_id1);
    //    (s3,cg_id3) = generateOdeSystem2SolveCall(mixedEvent,eqn_size, unique_id, cg_id2);
    //    (s4,cg_id4) = generateOdeSystem2CollectResults(mixedEvent,v, unique_id, cg_id3);
    //    s = Codegen.cMergeFns({s1,s2,s3,s4});
    //  then
    //    (s,cg_id4,{});
    //case (mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),SOME(jac),DAELow.JAC_NONLINEAR()) /* Time varying nonlinear jacobian. Non-linear system of equations */
    //  local list<tuple<Integer, Integer, DAELow.Equation>> jac;
    //  equation

    //    eqn_lst = DAELow.equationList(eqn);
    //    var_lst = DAELow.varList(v);
    //    crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates);// get varnames and prefix $der for states.
    //    (s1,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(mixedEvent,crefs, eqn_lst,ae, cg_id);
    //  then
    //    (s1,cg_id_1,f1);
    //case (mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),NONE,DAELow.JAC_NO_ANALYTIC()) /* no analythic jacobian available. Generate non-linear system */
    //  equation
    //    eqn_lst = DAELow.equationList(eqn);
    //    var_lst = DAELow.varList(v);
    //    crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
    //    (s1,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(mixedEvent,crefs, eqn_lst, ae, cg_id);
    //  then
    //    (s1,cg_id_1,f1);
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createOdeSystem2 failed"});
      then
        SES_NOT_IMPLEMENTED("some case in createOdeSystem2 not implemented");
  end matchcontinue;
end createOdeSystem2;

public function createSingleArrayEqnCode 
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
      Codegen.CFunction s1;
      list<CFunction> f1;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
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
        (DAELow.ARRAY_EQUATION(indx,_) :: _) = DAELow.equationList(eqns);
        DAELow.MULTIDIM_EQUATION(ds,e1,e2) = ae[indx + 1];
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

public function createSingleAlgorithmCode 
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  output SimEqSystem equation_;
algorithm
  equation_ :=
  matchcontinue (inDAELow,inTplIntegerIntegerDAELowEquationLstOption)
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      Exp.Exp e1,e2;
      Exp.ComponentRef cr,origname,cr_1;
      Codegen.CFunction s1;
      list<CFunction> f1;
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
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev),jac)
      equation
        (DAELow.ALGORITHM(indx,_,algOutExpVars) :: _) = DAELow.equationList(eqns);
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
        (DAELow.ALGORITHM(indx,_,algOutExpVars) :: _) = DAELow.equationList(eqns);
        alg = al[indx + 1];
        solvedVars = Util.listMap(DAELow.varList(vars),DAELow.varCref);
        algOutVars = Util.listMap(algOutExpVars,Exp.expCref);

        // The variables solved for and the output variables of the algorithm must be the same.
        false = Util.listSetEqualOnTrue(solvedVars,algOutVars,Exp.crefEqual);
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg)});
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
public function createSingleArrayEqnCode2 
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
      Codegen.CFunction cfunc,func_1;
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

public function dlowEqToSimEqSystem
  input DAELow.Equation inEquation;
  output SimEqSystem outEquation;
algorithm
  outEquation:=
  matchcontinue (inEquation)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp_;
    case (DAELow.SOLVED_EQUATION(cr, exp_))
      then SES_SIMPLE_ASSIGN(cr, exp_);
    case (DAELow.RESIDUAL_EQUATION(exp_))
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
  initialEquations :=
  matchcontinue (dlow)
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
  parameterEquations :=
  matchcontinue (dlow)
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
  initialEquations :=
  matchcontinue (vars)
    local
      DAELow.Equation initialEquation;
      list<DAELow.Var> restVars;
      Option<DAE.VariableAttributes> attr;
      DAE.ComponentRef name;
      DAE.Exp startv;
    case ({}) then {};
    case (DAELow.VAR(values=attr, varName=name) :: restVars)
      /* also add an assignment for variables that have non-constant
         expressions, e.g. parameter values, as start.  NOTE: such start
         attributes can then not be changed in the text file, since the initial
         calc. will override those entries!  */
      equation
        startv = DAEUtil.getStartAttr(attr);
        false = Exp.isConst(startv);
        initialEquation = DAELow.SOLVED_EQUATION(name, startv);
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
    case ({}) then {};
    case (DAELow.VAR(varName=cr, bindExp=SOME(e)) :: restVars)
      equation
        false = Exp.isConst(e);
        initialEquation = DAELow.SOLVED_EQUATION(cr, e);
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
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      Codegen.CFunction s0,s2_1,s4,s3,s1,cfn3,cfn,cfn2,cfn1;
      list<String> retrec,arg,init,stmts,cleanups,stmts_1;
      list<CFunction> extra_funcs1,extra_funcs2,extra_funcs;
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
    case (dae, (dlow as DAELow.DAELOW(vars, knvars, exvars, eqns, se, ie, ae,
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

public function createModelInfo
  input Absyn.Path class_;
  input DAELow.DAELow dlow;
  input Integer numOutVars;
  input Integer numInVars;
  input Integer numHelpVars;
  input Integer numResiduals;
  input String fileDir;
  output ModelInfo modelInfo;
algorithm
  modelInfo :=
  matchcontinue (class_, dlow, numOutVars, numInVars, numHelpVars,
                 numResiduals, fileDir)
    local
      String name;
      String directory;
      VarInfo varInfo;
      SimVars vars;
    case (class_, dlow, numOutVars, numInVars, numHelpVars,
          numResiduals, fileDir)
      equation
        name = Absyn.pathString(class_);
        directory = System.trim(fileDir, "\"");
        varInfo = createVarInfo(dlow, numOutVars, numInVars, numHelpVars,
                                numResiduals);
        vars = createVars(dlow);
      then
        MODELINFO(name, directory, varInfo, vars);
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"createModelInfo failed"});
      then
        fail();
  end matchcontinue;
end createModelInfo;

public function createVarInfo
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

public function createVars
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
    case (DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        externalObjects = extvars))
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
      then
        varsOut;
  end matchcontinue;
end createVars;

public function sortSimvarsOnIndex
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

public function varIndexComparer
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

public function mergeVars
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

public function reverseVars
  input SimVars vars;
  output SimVars varsResult;
algorithm
  varsResult :=
  matchcontinue (vars)
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
    case (SIMVARS(stateVars, derivativeVars, algVars, inputVars, outputVars,
                  paramVars, stringAlgVars, stringParamVars, extObjVars))
      equation
        stateVars = listReverse(stateVars);
        derivativeVars = listReverse(derivativeVars);
        algVars = listReverse(algVars);
        inputVars = listReverse(inputVars);
        outputVars = listReverse(outputVars);
        paramVars = listReverse(paramVars);
        stringAlgVars = listReverse(stringAlgVars);
        stringParamVars = listReverse(stringParamVars);
        extObjVars = listReverse(extObjVars);
      then 
        SIMVARS(stateVars, derivativeVars, algVars, inputVars, outputVars,
                paramVars, stringAlgVars, stringParamVars, extObjVars);
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"reverseVars failed"});
      then
        fail();
  end matchcontinue;
end reverseVars;

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
      //orignameStr = Exp.printComponentRefStr(origname);
      commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
      //name = Exp.printComponentRefStr(cr);
      isFixed = DAELow.varFixed(dlowVar);
      type_ = DAELow.makeExpType(tp);
      isDiscrete = isVarDiscrete(tp, kind);
      arrayCref = getArrayCref(dlowVar);
    then
      SIMVAR(cr, origname, commentStr, indx, isFixed, type_, isDiscrete,
             arrayCref);
  end matchcontinue;
end dlowvarToSimvar;

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

public function unparseCommentOptionNoAnnotationNoQuote
  input Option<SCode.Comment> absynComment;
  output String commentStr;
algorithm
  outString :=
  matchcontinue (absynComment)
    case (SOME(SCode.COMMENT(_, SOME(commentStr)))) then commentStr;
    case (_) then "";
  end matchcontinue;
end unparseCommentOptionNoAnnotationNoQuote;

/* TODO: Is this correct? */
public function isVarAlg
  input DAELow.Var var;
  output Boolean result;
algorithm
  result := matchcontinue (var)
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
public function isVarStringAlg
  input DAELow.Var var;
  output Boolean result;
algorithm
  result := matchcontinue (var)
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
public function isVarParam
  input DAELow.Var var;
  output Boolean result;
algorithm
  result := matchcontinue (var)
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
public function isVarStringParam
  input DAELow.Var var;
  output Boolean result;
algorithm
  result := matchcontinue (var)
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

// ***** To rewrite and delete below here *****

public type HelpVarInfo = tuple<Integer, Exp.Exp, Integer>; // helpvarindex, expression, whenclause index

protected type CFunction = Codegen.CFunction;
protected constant String TAB="    ";
protected constant String stateNames="state_names" "TAB is four whitespaces" ;
protected constant String derivativeNames="derivative_names";
protected constant String algvarsNames="algvars_names";
protected constant String inputNames="input_names";
protected constant String outputNames="output_names";
protected constant String paramNames="param_names";
protected constant String stringParamNames="string_param_names";
protected constant String stringAlgNames="string_alg_names";
protected constant String stateComments="state_comments";
protected constant String derivativeComments="derivative_comments";
protected constant String algvarsComments="algvars_comments";
protected constant String inputComments="input_comments";
protected constant String outputComments="output_comments";
protected constant String paramComments="param_comments";
protected constant String stringParamComments="string_param_comments";
protected constant String stringAlgComments="string_alg_comments";
protected constant String paramInGetNameFunction="ptr";

//protected import RTOpts;
protected import Codegen;
//protected import Print;
protected import ModUtil;
protected import VarTransform;

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
      DAELow.EquationArray orderedEqs;
      DAELow.EquationArray removedEqs;
      DAELow.EquationArray initialEqs;
      DAELow.MultiDimEquation[:] arrayEqs;
      Algorithm.Algorithm[:] algorithms,algorithms2;
      list<Algorithm.Algorithm> algLst;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
    case	(helpvars,DAELow.DAELOW(orderedVars,knownVars,externalObjects,orderedEqs,
      removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses))
      equation
        (helpvars1,algLst,_) = generateHelpVarsInAlgorithms(listLength(helpvars),arrayList(algorithms));
        algorithms2 = listArray(algLst);
      then (listAppend(helpvars,helpvars1),DAELow.DAELOW(orderedVars,knownVars,externalObjects,orderedEqs,
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

protected function filterNg "function: filterNg
  This function sets the number of zero crossings to zero if events are disabled
"
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inInteger)
    local Integer ng;
    case _
      equation
        false = useZerocrossing();
      then
        0;
    case ng then ng;
  end matchcontinue;
end filterNg;

protected function generateExternalObjectDestructorCalls "generate destructor calls for external objects"
	input Integer cg_in;
  input DAELow.DAELow daelow;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
	(outCFunction,outInteger) := matchcontinue(cg_in,daelow)
	  case (cg_in,DAELow.DAELOW(externalObjects = evars, extObjClasses = eclasses))
	    local
	      DAELow.Variables evars;
	      list<DAELow.Var> evarLst;
	      DAELow.ExternalObjectClasses eclasses;
	      list<String> strs;
	    equation
	       evarLst = DAELow.varList(evars);
	       (outCFunction,cg_out) = generateExternalObjectDestructorCalls2(cg_in,evarLst,eclasses);
	    then (outCFunction,cg_out);
  end matchcontinue;
end generateExternalObjectDestructorCalls;

protected function generateExternalObjectDestructorCalls2 "
help function to generateExternalObjectDestructorCalls"
	input Integer cg_in;
  input list<DAELow.Var> varLst;
  input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varLst,eclasses)
    local	DAELow.Var v;
      list<DAELow.Var> vs;
      Codegen.CFunction cfunc,cfunc2;
    case (cg_in,{},eclasses)
    then (Codegen.cEmptyFunction,cg_in);
    case (cg_in,v::vs,eclasses) equation
      (cfunc,cg_out) = generateExternalObjectDestructorCalls2(cg_in,vs,eclasses);
      (cfunc2,cg_out) = generateExternalObjectDestructorCall(cg_out,v,eclasses);
      cfunc = Codegen.cMergeFns({cfunc2,cfunc});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectDestructorCalls2;

protected function generateExternalObjectDestructorCall "help function to generateExternalObjectDestructorCalls"
	input Integer cg_in;
	input DAELow.Var var;
	input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
	(outCFunction,cg_out) := matchcontinue (cg_in,var,eclasses)
	  case (_,_,{}) equation print("generateExternalObjectDestructorCall failed\n"); then fail();

		// found class
	  case (cg_in,DAELow.VAR(varName = name,varKind = DAELow.EXTOBJ(path1)), DAELow.EXTOBJCLASS(path=path2,destructor=destr)::_)
	    local
	      DAE.Element destr;
	      Exp.ComponentRef name;
	      Absyn.Path path1,path2;
	      Codegen.CFunction cfunc;

	    equation
	      true = ModUtil.pathEqual(path1,path2);
	      (cfunc,cg_out) = generateExternalObjectDestructorCall2(cg_in,name,destr);
	      then (cfunc,cg_out);
	  // Try next class.
	  case (cg_in,var,_::eclasses)
	    local Codegen.CFunction cfunc;
	    equation
	     (cfunc,cg_out) = generateExternalObjectDestructorCall(cg_in,var,eclasses);
	  then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectDestructorCall;

protected function generateExternalObjectDestructorCall2 "Help funciton to generateExternalObjectDestructorCall"
	input Integer cg_in;
  input Exp.ComponentRef varName;
  input DAE.Element destructor;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (cg_out,outCFunction) := matchcontinue(cg_in,varName,destructor)
    case (cg_in,varName,destructor as DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(ident=funcStr))}))
      local String vStr,funcStr,str;
        Codegen.CFunction cfunc;
      equation
        vStr = Exp.printComponentRefStr(varName);
        str = Util.stringAppendList({"    ",funcStr,"(",vStr,");"});
        cfunc = Codegen.cAddStatements(Codegen.cEmptyFunction,{str});
      then (cfunc,cg_in);

  end matchcontinue;
end generateExternalObjectDestructorCall2;

protected function generateExternalObjectConstructorCalls " generates constructor calls of all external objects"
	input Integer cg_in;
  input DAELow.DAELow daelow;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  str := matchcontinue(cg_in,daelow)
	  case (cg_in,DAELow.DAELOW(externalObjects = evars, extObjClasses = eclasses))
	    local
	      DAELow.Variables evars;
	      list<DAELow.Var> evarLst;
	      DAELow.ExternalObjectClasses eclasses;
	      list<String> strs;
	    equation
	      evarLst = DAELow.varList(evars);
	      (outCFunction,cg_out) = generateExternalObjectConstructorCalls2(cg_in,evarLst,eclasses);
	    then (outCFunction,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorCalls;

protected function generateExternalObjectConstructorCalls2 "
help function to generateExternalObjectConstructorCalls"
	input Integer cg_in;
  input list<DAELow.Var> varLst;
  input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varLst,eclasses)
    local	DAELow.Var v;
      list<DAELow.Var> vs;
      Codegen.CFunction cfunc,cfunc2;
    case (cg_in,{},eclasses)
    then (Codegen.cEmptyFunction,cg_in);
    case (cg_in,v::vs,eclasses) equation
      (cfunc,cg_out) = generateExternalObjectConstructorCalls2(cg_in,vs,eclasses);
      (cfunc2,cg_out) = generateExternalObjectConstructorCall(cg_out,v,eclasses);
      cfunc = Codegen.cMergeFns({cfunc2,cfunc});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorCalls2;

protected function generateExternalObjectConstructorAliases "Generates codes for external objects that are
aliased to other external object variables. They must be issued after the constructor call. Therefore
this function is called after all constructor calls have been generated."
	input Integer cg_in;
  input DAELow.DAELow daelow;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  str := matchcontinue(cg_in,daelow)
	  case (cg_in,DAELow.DAELOW(externalObjects = evars))
	    local
	      DAELow.Variables evars;
	      list<DAELow.Var> evarLst;
	      list<String> strs;
	    equation
	      evarLst = DAELow.varList(evars);
	      (outCFunction,cg_out) = generateExternalObjectConstructorAliases2(cg_in,evarLst);
	    then (outCFunction,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorAliases;

protected function generateExternalObjectConstructorAliases2 "
help function to generateExternalObjectConstructorAliases"
	input Integer cg_in;
  input list<DAELow.Var> varLst;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varLst)
    local	DAELow.Var v;
      list<DAELow.Var> vs;
      Codegen.CFunction cfunc,cfunc2;
    case (cg_in,{})
    then (Codegen.cEmptyFunction,cg_in);
    case (cg_in,v::vs) equation
      (cfunc,cg_out) = generateExternalObjectConstructorAliases2(cg_in,vs);
      (cfunc2,cg_out) = generateExternalObjectConstructorAlias(cg_out,v);
      cfunc = Codegen.cMergeFns({cfunc2,cfunc});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorAliases2;

protected function generateExternalObjectConstructorAlias
"Help function to generateExternalObjectConstructorAliases"
	input Integer cg_in;
  input DAELow.Var var;
  output CFunction outCFunction;
  output Integer cg_out;
  algorithm
    (outCFunction,cg_out) := matchcontinue (cg_in,var)

	  // 	external object aliased to another external object.
	  case (cg_in, DAELow.VAR(varName= name,bindExp = SOME(DAE.CREF(cr,_)),varKind = DAELow.EXTOBJ(path1)))
	    local String stmt,v_str,v_str2;
	      Codegen.CFunction cfunc;
	      Exp.ComponentRef cr,name;
	      Absyn.Path path1;
	   equation
	     v_str = Exp.printComponentRefStr(name);
	     v_str2 = Exp.printComponentRefStr(cr);
	     stmt = Util.stringAppendList({v_str," = ",v_str2,";"});
	     cfunc = Codegen.cAddStatements(Codegen.cEmptyFunction,{stmt});
	     then (cfunc,cg_in);
	       // Skip non-aliases constructors.
	  case (cg_in,_) then (Codegen.cEmptyFunction,cg_in);
    end matchcontinue;
end generateExternalObjectConstructorAlias;

protected function generateExternalObjectConstructorCall "help function to generateExternalObjectConstructorCalls"
  input Integer cg_in;
  input DAELow.Var var;
	input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
	(outCFunction,cg_out) := matchcontinue (cg_in,var,eclasses)

		// Skip aliases now, they are handled in generateExternalObjectConstructorAlias
	  case (cg_in, DAELow.VAR(bindExp = SOME(DAE.CREF(_,_)),varKind = DAELow.EXTOBJ(_)),_)
	  then (Codegen.cEmptyFunction,cg_in);

	  case (_,DAELow.VAR(varName = name),{})
	    local Exp.ComponentRef name;
	    equation
	    print("generateExternalObjectConstructorCall for var:");
	    print(Exp.printComponentRefStr(name));print(" failed\n");
	     then fail();

		// found class
	  case (cg_in,DAELow.VAR(varName = name,bindExp = SOME(e),varKind = DAELow.EXTOBJ(path1)), DAELow.EXTOBJCLASS(path=path2,constructor=constr)::_)
	    local
	      DAE.Element constr;
	      Exp.ComponentRef name;
	      Absyn.Path path1,path2;
	      Exp.Exp e;
	      Codegen.CFunction cfunc;
	    equation
	      true = ModUtil.pathEqual(path1,path2);
	      (cfunc,cg_out) = generateExternalObjectConstructorCall2(cg_in,name,constr,e);
	      then (cfunc,cg_out);
	  // Try next class.
	  case (cg_in,var,_::eclasses)
	    local
	      Codegen.CFunction cfunc;
	    equation
	    (cfunc,cg_out) = generateExternalObjectConstructorCall(cg_in,var,eclasses);
	    then (cfunc,cg_out);

  end matchcontinue;
end generateExternalObjectConstructorCall;

protected function generateExternalObjectConstructorCall2 "Help funciton to generateExternalObjectConstructorCall"
	input Integer cg_in;
  input Exp.ComponentRef varName;
  input DAE.Element constructor;
  input Exp.Exp constrCallExp;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varName,constructor,constrCallExp)
    case (cg_in,varName,constructor as 
          DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(ident=funcStr))}),DAE.CALL(expLst = args))
      local
        String vStr,funcStr,argsStr,str;
        list<Exp.Exp> args;
        list<String> vars1;
        Codegen.CFunction cfunc;
      equation
        vStr = Exp.printComponentRefStr(varName);
        /* TODO: cfn1 might contain additional code  that is needed, also 0 must be propagated to prevent
        resuing same variable name */
        (cfunc,vars1,cg_out) = Codegen.generateExpressions(args, cg_in, Codegen.extContext);
        argsStr = Util.stringDelimitList(vars1,", ");
        str = Util.stringAppendList({"    ",vStr," = ",funcStr,"(",argsStr,");"});
        cfunc = Codegen.cAddStatements(cfunc,{str});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorCall2;

protected function generateInitializeDeinitializationDataStruc 
"generates initializeDataStruc
 to allocate all the different vectors i a DATA-struc"
  input DAELow.DAELow daelow;
  output String outString "resulting C code";
  protected Codegen.CFunction extObjDestructors,extObjConstructors,extObjConstructorAliases;
  String extObjDestructors_str,extObjConstructors_str;
  String extObjDestructorsDecl_str,extObjConstructorsDecl_str,extObjConstructorAliases_str;
  Integer cg_out;
algorithm
	(extObjDestructors,cg_out) := generateExternalObjectDestructorCalls(0,daelow);
	(extObjConstructors,cg_out):= generateExternalObjectConstructorCalls(cg_out,daelow);
	(extObjConstructorAliases,cg_out):= generateExternalObjectConstructorAliases(cg_out,daelow);
	extObjDestructors_str := Codegen.cPrintStatements(extObjDestructors);
  extObjConstructors_str := Codegen.cPrintStatements(extObjConstructors);
  extObjConstructorAliases_str := Codegen.cPrintStatements(extObjConstructorAliases);
  extObjDestructorsDecl_str := Codegen.cPrintDeclarations(extObjDestructors);
  extObjConstructorsDecl_str := Codegen.cPrintDeclarations(extObjConstructors);
  // Aliases has no declarations, skip printing them
  outString:=Util.stringAppendList({"
void setLocalData(DATA* data)\n{
   localData = data;\n}\n
DATA* initializeDataStruc(DATA_FLAGS flags)\n{",
extObjDestructorsDecl_str,
extObjConstructorsDecl_str,"
  DATA* returnData = (DATA*)malloc(sizeof(DATA));

  if(!returnData) //error check
    return 0;

  memset(returnData,0,sizeof(DATA));
  returnData->nStates = NX;
  returnData->nAlgebraic = NY;
  returnData->nParameters = NP;
  returnData->nInputVars = NI;
  returnData->nOutputVars = NO;
  returnData->nZeroCrossing = NG;
  returnData->nInitialResiduals = NR;
  returnData->nHelpVars = NHELP;
  returnData->stringVariables.nParameters = NPSTR;
  returnData->stringVariables.nAlgebraic = NYSTR;\n","
  if(flags & STATES && returnData->nStates) {
    returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStates = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStates2 = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->states&&returnData->oldStates&&returnData->oldStates2);
    memset(returnData->states,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStates,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStates2,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->states = 0;
    returnData->oldStates = 0;
    returnData->oldStates2 = 0;
  }\n","
  if(flags & STATESDERIVATIVES && returnData->nStates) {
    returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStatesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStatesDerivatives2 = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->statesDerivatives&&returnData->oldStatesDerivatives&&returnData->oldStatesDerivatives2);
    memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStatesDerivatives,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStatesDerivatives2,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->statesDerivatives = 0;
    returnData->oldStatesDerivatives = 0;
    returnData->oldStatesDerivatives2 = 0;
  }\n","
  if(flags & HELPVARS && returnData->nHelpVars) {
    returnData->helpVars = (double*) malloc(sizeof(double)*returnData->nHelpVars);
    assert(returnData->helpVars);
    memset(returnData->helpVars,0,sizeof(double)*returnData->nHelpVars);
  } else {
    returnData->helpVars = 0;
  }\n","
  if(flags & ALGEBRAICS && returnData->nAlgebraic) {
    returnData->algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->oldAlgebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->oldAlgebraics2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    assert(returnData->algebraics&&returnData->oldAlgebraics&&returnData->oldAlgebraics2);
    memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->oldAlgebraics,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->oldAlgebraics2,0,sizeof(double)*returnData->nAlgebraic);
  } else {
    returnData->algebraics = 0;
    returnData->oldAlgebraics = 0;
    returnData->oldAlgebraics2 = 0;
    returnData->stringVariables.algebraics = 0;
  }\n","
  if (flags & ALGEBRAICS && returnData->stringVariables.nAlgebraic) {
    returnData->stringVariables.algebraics = (char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);
    assert(returnData->stringVariables.algebraics);
    memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);
  } else {
    returnData->stringVariables.algebraics=0;
  }\n","
  if(flags & PARAMETERS && returnData->nParameters) {
    returnData->parameters = (double*) malloc(sizeof(double)*returnData->nParameters);
    assert(returnData->parameters);
    memset(returnData->parameters,0,sizeof(double)*returnData->nParameters);
  } else {
    returnData->parameters = 0;
  }\n","
  if (flags & PARAMETERS && returnData->stringVariables.nParameters) {
  	  returnData->stringVariables.parameters = (char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);
      assert(returnData->stringVariables.parameters);
      memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);
  } else {
      returnData->stringVariables.parameters=0;
  }\n","
  if(flags & OUTPUTVARS && returnData->nOutputVars) {
    returnData->outputVars = (double*) malloc(sizeof(double)*returnData->nOutputVars);
    assert(returnData->outputVars);
    memset(returnData->outputVars,0,sizeof(double)*returnData->nOutputVars);
  } else {
    returnData->outputVars = 0;
  }\n","
  if(flags & INPUTVARS && returnData->nInputVars) {
    returnData->inputVars = (double*) malloc(sizeof(double)*returnData->nInputVars);
    assert(returnData->inputVars);
    memset(returnData->inputVars,0,sizeof(double)*returnData->nInputVars);
  } else {
    returnData->inputVars = 0;
  }\n","
  if(flags & INITIALRESIDUALS && returnData->nInitialResiduals) {
    returnData->initialResiduals = (double*) malloc(sizeof(double)*returnData->nInitialResiduals);
    assert(returnData->initialResiduals);
    memset(returnData->initialResiduals,0,sizeof(double)*returnData->nInitialResiduals);
  } else {
    returnData->initialResiduals = 0;
  }\n","
  if(flags & INITFIXED) {
    returnData->initFixed = init_fixed;
  } else {
    returnData->initFixed = 0;
  }\n","
  /*   names   */
  if(flags & MODELNAME) {
    returnData->modelName = model_name;
  } else {
    returnData->modelName = 0;
  }
  
  if(flags & STATESNAMES) {
    returnData->statesNames = state_names;
  } else {
    returnData->statesNames = 0;
  }\n","
  if(flags & STATESDERIVATIVESNAMES) {
    returnData->stateDerivativesNames = derivative_names;
  } else {
    returnData->stateDerivativesNames = 0;
  }\n","
  if(flags & ALGEBRAICSNAMES) {
    returnData->algebraicsNames = algvars_names;
  } else {
    returnData->algebraicsNames = 0;
  }\n","
  if(flags & PARAMETERSNAMES) {
    returnData->parametersNames = param_names;
  } else {
    returnData->parametersNames = 0;
  }\n","
  if(flags & INPUTNAMES) {
    returnData->inputNames = input_names;
  } else {
    returnData->inputNames = 0;
  }\n","
  if(flags & OUTPUTNAMES) {
    returnData->outputNames = output_names;
  } else {
    returnData->outputNames = 0;
  }\n","
  /*   comments  */
  if(flags & STATESCOMMENTS) {
    returnData->statesComments = state_comments;
  } else {
    returnData->statesComments = 0;
  }\n","
  if(flags & STATESDERIVATIVESCOMMENTS) {
    returnData->stateDerivativesComments = derivative_comments;
  } else {
    returnData->stateDerivativesComments = 0;
  }\n","
  if(flags & ALGEBRAICSCOMMENTS) {
    returnData->algebraicsComments = algvars_comments;
  } else {
    returnData->algebraicsComments = 0;
  }\n","
  if(flags & PARAMETERSCOMMENTS) {
    returnData->parametersComments = param_comments;
  } else {
    returnData->parametersComments = 0;
  }\n","
  if(flags & INPUTCOMMENTS) {
    returnData->inputComments = input_comments;
  } else {
    returnData->inputComments = 0;
  }\n","
  if(flags & OUTPUTCOMMENTS) {
    returnData->outputComments = output_comments;
  } else {
    returnData->outputComments = 0;
  }\n","
  if (flags & EXTERNALVARS) {
    returnData->extObjs = (void**)malloc(sizeof(void*)*NEXT);
    if (!returnData->extObjs) {
      printf(\"error allocating external objects\\n\");
      exit(-2);
    }
    memset(returnData->extObjs,0,sizeof(void*)*NEXT);
    setLocalData(returnData); /* must be set since used by constructors*/\n",
  extObjConstructors_str,
  extObjConstructorAliases_str,"  }
  return returnData;
}\n","
void deInitializeDataStruc(DATA* data, DATA_FLAGS flags)
{
  if(!data)
    return;

  if(flags & STATES && data->states) {
    free(data->states);
    data->states = 0;
  }\n","
  if(flags & STATESDERIVATIVES && data->statesDerivatives) {
    free(data->statesDerivatives);
    data->statesDerivatives = 0;
  }\n","
  if(flags & ALGEBRAICS && data->algebraics) {
    free(data->algebraics);
    data->algebraics = 0;
  }\n","
  if(flags & PARAMETERS && data->parameters) {
    free(data->parameters);
    data->parameters = 0;
  }\n","
  if(flags & OUTPUTVARS && data->inputVars) {
    free(data->inputVars);
    data->inputVars = 0;
  }\n","
  if(flags & INPUTVARS && data->outputVars) {
    free(data->outputVars);
    data->outputVars = 0;
  }
  
  if(flags & INITIALRESIDUALS && data->initialResiduals){
    free(data->initialResiduals);
    data->initialResiduals = 0;
  }
  if (flags & EXTERNALVARS && data->extObjs) {\n",extObjDestructors_str,
  "    free(data->extObjs);\n    data->extObjs = 0;
  }
}\n"});
end generateInitializeDeinitializationDataStruc;

protected function generateAttrVector 
"author: PA
  Generates a vector, attr[nx+ny+np] where attributes  of variables are stored
  It is collected for states, variables and parameters.
  The information is encoded as:
  1 - Real
  2 - String
  4 - Integer
  8 - Boolean
  16 - discrete time variable"
  input DAELow.DAELow daelow;
  input Integer nx "number of states";
  input Integer ny "number of alg. vars";
  input Integer np "number of parameters";
  output String c_code "resulting C code";
algorithm
  outString:=
  matchcontinue (daelow,nx,ny,np)
    local
      Integer arr_size,nx,ny,np;
      String[:] str_arr,str_arr1,str_arr2;
      list<String> str_lst;
      String str,res;
      DAELow.DAELow dae;
    case (dae,nx,ny,np)
      equation
        arr_size = Util.listReduce({nx,ny,np}, int_add);
        str_arr = fill("0", arr_size);
        str_arr1 = generateAttrVectorType(dae, str_arr, nx, ny, np);
        str_arr2 = generateAttrVectorDiscrete(dae, str_arr1, nx, ny, np);
        str_lst = arrayList(str_arr1);
        str = Util.stringDelimitListAndSeparate(str_lst, ", ", "\n", 3);
        res = Util.stringAppendList({"char var_attr[NX+NY+NP]={",str,"};\n"});
      then
        res;
    case (dae,nx,ny,np)
      equation
        print("SimCodegen.generateAttrVector failed\n");
      then
        fail();
  end matchcontinue;
end generateAttrVector;

protected function generateAttrVectorType 
"author: PA
  Helper function to generateAttrVector. Generates the value for the type of v,
  see generateAttrVector."
  input DAELow.DAELow inDAELow1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELow1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      list<DAELow.Var> v_lst,kv_lst;
      String[:] str_arr1,str_arr2,str_arr;
      DAELow.Variables v,kv;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = v,knownVars = kv),str_arr,nx,ny,np) /* nx ny np */
      equation
        v_lst = DAELow.varList(v);
        kv_lst = DAELow.varList(kv);
        str_arr1 = generateAttrVectorType2(v_lst, str_arr, nx, ny, np);
        str_arr2 = generateAttrVectorType2(kv_lst, str_arr1, nx, ny, np);
      then
        str_arr1;
  end matchcontinue;
end generateAttrVectorType;

protected function generateAttrVectorType2 
"author: PA
  Helper function to generateAttrVectorType"
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELowVarLst1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      String[:] str_arr,str_arr_1,str_arr_2;
      DAELow.Var v;
      list<DAELow.Var> vs;
      Integer nx,ny,np,indx,off,indx_1,varTypeInt;
      DAELow.VarKind kind;
      DAELow.Type varType;
      String value,name;

    case ({},str_arr,_,_,_) then str_arr;  /* nx ny np */
    case ((v :: vs),str_arr,nx,ny,np) /* skip constants */
      equation
        DAELow.CONST() = DAELow.varKind(v);
        str_arr_1 = generateAttrVectorType2(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        kind = DAELow.varKind(v);
        indx = DAELow.varIndex(v);
        (indx >= 0) = true;
        off = calcAttrOffset(kind, nx, ny, np);
        indx_1 = off + indx;
        varType = DAELow.varType(v);
        name = DAELow.varOrigName(v);
        varTypeInt = vartypeAttrInt(varType);
        value = intString(varTypeInt);
        value = Util.stringAppendList({"/*",name,":*/",value});
        str_arr_1 = arrayUpdate(str_arr, indx_1 + 1, value);
        str_arr_2 = generateAttrVectorType2(vs, str_arr_1, nx, ny, np);
      then
        str_arr_2;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        print("SimCodegen.generateAttrVectorType2 failed\n");
      then
        fail();
  end matchcontinue;
end generateAttrVectorType2;

protected function vartypeAttrInt 
"function vartypeAttrInt 
  helper function to generateAttrVectorType2
  calculates the int value of the type of a variable (1 .. 8)"
input DAELow.Type tp;
output Integer res;
algorithm
  res := matchcontinue (tp)
		  case DAELow.REAL() then 1;
	  	case DAELow.STRING() then 2;
	  	case DAELow.INT() then 4;
	  	case DAELow.BOOL() then 8;
  		case DAELow.ENUMERATION(_) then 0;
	  end matchcontinue;
end vartypeAttrInt;

protected function varDiscreteAttrInt 
"helper function to generateAttrVectorDiscrete2
 calculates the int value of the variability of a variable.
  0 - continuous time variable
 16 - discrete time variable."
input DAELow.Type tp;
input DAELow.VarKind kind;
output Integer res;
algorithm
  res := matchcontinue (tp,kind)
	  	case (DAELow.REAL(),DAELow.DISCRETE()) then 16;
	  	case (_,DAELow.DISCRETE()) then 16;
	  	case (DAELow.INT(),_) then 16;
	  	case (DAELow.BOOL(),_) then 16;
  		case (DAELow.ENUMERATION(_),_) then 16;
  		case (_,_) then 0;
	  end matchcontinue;
end varDiscreteAttrInt;

protected function generateAttrVectorDiscrete 
"author: PA
  Helper function to generateAttrVector. Generates the value for discrete flag,
  see generateAttrVector."
  input DAELow.DAELow inDAELow1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELow1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      list<DAELow.Var> v_lst,kv_lst;
      String[:] str_arr1,str_arr2,str_arr;
      DAELow.Variables v,kv;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = v,knownVars = kv),str_arr,nx,ny,np) /* nx ny np */
      equation
        v_lst = DAELow.varList(v);
        kv_lst = DAELow.varList(kv);
        str_arr1 = generateAttrVectorDiscrete2(v_lst, str_arr, nx, ny, np);
        str_arr2 = generateAttrVectorDiscrete2(kv_lst, str_arr1, nx, ny, np);

      then
        str_arr2;
  end matchcontinue;
end generateAttrVectorDiscrete;

protected function generateAttrVectorDiscrete2 
"author: PA
  Helper function to generateAttrVectorType"
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELowVarLst1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      String[:] str_arr,str_arr_1,str_arr_2;
      DAELow.Var v;
      list<DAELow.Var> vs;
      Integer nx,ny,np,indx,off,indx_1,varTypeInt;
      DAELow.VarKind kind;
      DAELow.Type varType;
      DAELow.VarKind varKind;
      String value,name,oldVal;
      
    case ({},str_arr,_,_,_) then str_arr;  /* nx ny np */
    case ((v :: vs),str_arr,nx,ny,np) /* skip constants */
      equation
        DAELow.CONST() = DAELow.varKind(v);
        str_arr_1 = generateAttrVectorType2(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        kind = DAELow.varKind(v);
        indx = DAELow.varIndex(v);
        (indx >= 0) = true;
        off = calcAttrOffset(kind, nx, ny, np);
        indx_1 = off + indx;
        varType = DAELow.varType(v);
        varKind = DAELow.varKind(v);
        name = DAELow.varOrigName(v);
        varTypeInt = varDiscreteAttrInt(varType,varKind);
        value = intString(varTypeInt);
        oldVal = str_arr[indx_1+1];
        value = Util.stringAppendList({oldVal,"+",value});
        str_arr_1 = arrayUpdate(str_arr, indx_1 + 1, value);
        str_arr_2 = generateAttrVectorDiscrete2(vs, str_arr_1, nx, ny, np);
      then
        str_arr_2;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        print("generateAttrVectorDiscrete2 failed\n");
        // debug_print("variable:", v);
      then
        fail();
  end matchcontinue;
end generateAttrVectorDiscrete2;

protected function generateFixedVector 
"function: generateFixedVector
  Generates a vector, fixed[nx+nx+ny+np] where the fixed attribute is stored
  It is collected for states, derivatives, variables and parameters."
  input DAELow.DAELow inDAELow1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow1,inInteger2,inInteger3,inInteger4)
    local
      Integer arr_size,nx,ny,np;
      String[:] str_arr,str_arr_1;
      list<String> str_lst;
      String str,res;
      DAELow.DAELow dae;
    case (dae,nx,ny,np) /* nx ny np */
      equation
        arr_size = Util.listReduce({nx,nx,ny,np}, int_add);
        str_arr = fill("1/*default*/", arr_size);
        str_arr_1 = generateFixedVector2(dae, str_arr, nx, ny, np);
        str_lst = arrayList(str_arr_1);
        str = Util.stringDelimitListAndSeparate(str_lst, ", ", "\n\t", 3);
        res = Util.stringAppendList({"static char init_fixed[NX+NX+NY+NP]={\n\t",str,"\n};\n"});
      then
        res;
    case (dae,nx,ny,np)
      equation
        print("SimCodegen.generateFixedVector failed\n");
      then
        fail();
  end matchcontinue;
end generateFixedVector;

protected function generateFixedVector2 
"function: generateFixedVector2
  author: PA
  Helper function to generate_fixed_vector"
  input DAELow.DAELow inDAELow1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELow1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      list<DAELow.Var> v_lst,kv_lst;
      String[:] str_arr_1,str_arr_2,str_arr;
      DAELow.Variables v,kv;
      DAELow.EquationArray ie;
      list<DAELow.Equation> ie_lst;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = v,knownVars = kv,initialEqs=ie),str_arr,nx,ny,np) /* nx ny np */
      equation
        v_lst = DAELow.varList(v);
        kv_lst = DAELow.varList(kv);
        ie_lst = DAELow.equationList(ie);

        /* If initial equations present and no variable or parameter has fixed = false, set states
        present in initial equations to fixed=false and issue warning. This will make "standard Modelica models"
        with initial equations work. */

        str_arr_1 = generateFixedVector3(v_lst, str_arr, nx, ny, np);
        str_arr_2 = generateFixedVector3(kv_lst, str_arr_1, nx, ny, np);
        str_arr_2 = generateFixedVectorDefault(str_arr_2,ie_lst,v_lst,kv_lst);
      then
        str_arr_2;
  end matchcontinue;
end generateFixedVector2;

protected function generateFixedVectorDefault "Help function to generateFixedVector2, sets fixed = false for all states
that are present in initial equations, iff no variables has fixed=false"
  input String[:] fixedArr;
  input list<DAELow.Equation> ieLst;
  input list<DAELow.Var> varLst;
  input list<DAELow.Var> knvarLst;
  output String[:] fixedArrOut;
algorithm
  fixedArrOut := matchcontinue(fixedArr,ieLst,varLst,knvarLst)
    local list<Boolean> fixedLst; Boolean noFalse;
      list<Exp.ComponentRef> crefs;
      String str;
      list<String> vars;
      /* No initial equations, do nothing */
    case(fixedArr,{},varLst,knvarLst) then fixedArr;

    case(fixedArr,ieLst,varLst,knvarLst) equation
      fixedLst = Util.listMap(listAppend(knvarLst,varLst),DAELow.varFixed);
      true = Util.boolAndList(fixedLst); /* No fixed = false */
      crefs = DAELow.equationsCrefs(ieLst);
      (fixedArr,vars) = generateFixedVectorDefault2(fixedArr,varLst,crefs);
      str = Util.stringDelimitList(vars,", ");
      Error.addMessage(Error.SETTING_FIXED_ATTRIBUTE,{str});
    then fixedArr;

      /* Has fixed = false, do nothing */
    case(fixedArr,ieLst,varLst,knvarLst) then fixedArr;
    end matchcontinue;
end generateFixedVectorDefault;

protected function generateFixedVectorDefault2 "Help function to generateFixedVectorDefault,
traverses all states and if state is present in crefs, set fixed=false"
  input String[:] fixedArr;
  input list<DAELow.Var> varLst;
  input list<Exp.ComponentRef> crefs;
  output String[:] fixedArrOut;
  output list<String> changedVars;
algorithm
  (fixedArrOut,changedVars) := matchcontinue(fixedArr,varLst,crefs)
    local DAELow.Var v; list<DAELow.Var> vs;
      Integer indx; Exp.ComponentRef cr; String crStr;
    case(fixedArr,v::vs,crefs) equation
      true = DAELow.isStateVar(v);
      cr = DAELow.varCref(v);
      _::_ = Util.listSelect1(crefs,cr,Exp.crefEqual);
      indx = DAELow.varIndex(v); // Should use calcFixedOffset, but kind is always state so we skip that
      fixedArr =  arrayUpdate(fixedArr, indx + 1, "0 /* changed due to init eqns */");
      (fixedArr,changedVars) = generateFixedVectorDefault2(fixedArr,vs,crefs);
      crStr = DAELow.varOrigName(v);
    then (fixedArr,crStr::changedVars);

    case(fixedArr,v::vs,crefs) equation
      (fixedArr,changedVars) = generateFixedVectorDefault2(fixedArr,vs,crefs);
    then (fixedArr,changedVars);
    case(fixedArr,{},_) then (fixedArr,{});
  end matchcontinue;
end generateFixedVectorDefault2;

protected function generateFixedVector3 
"function: generateFixedVector3
  author: PA
  Helper function to generate_fixed_vector2"
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray := matchcontinue (inDAELowVarLst1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      String[:] str_arr,str_arr_1,str_arr_2;
      DAELow.Var v;
      list<DAELow.Var> vs;
      Integer nx,ny,np,indx,off,indx_1;
      DAELow.VarKind kind;
      Boolean b;
      String value,name;
    case ({},str_arr,_,_,_) then str_arr;  /* nx ny np */
    case ((v :: vs),str_arr,nx,ny,np) /* skip constants */
      equation
        DAELow.CONST() = DAELow.varKind(v);
        str_arr_1 = generateFixedVector3(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        kind = DAELow.varKind(v);
        indx = DAELow.varIndex(v);
        (indx >= 0) = true;
        off = calcFixedOffset(kind, nx, ny, np);
        indx_1 = off + indx;
        b = DAELow.varFixed(v);
        value = Util.if_(b, "1", "0");
        name = DAELow.varOrigName(v);
        value = Util.stringAppendList({value,"/*",name,"*/"});
        str_arr_1 = arrayUpdate(str_arr, indx_1 + 1, value);
        str_arr_2 = generateFixedVector3(vs, str_arr_1, nx, ny, np);
      then
        str_arr_2;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        print("generate_fixed_vector3 failed\n");
        // debug_print("variable:", v);
      then
        fail();
  end matchcontinue;
end generateFixedVector3;

protected function calcFixedOffset "function: calcFixedOffset
  author: PA

  Calculates the offset for a fixed attribute int the fixed vector.
  The attributes are stored in this order:
  {states, derivatives, alg. vars, parameters}.
"
  input DAELow.VarKind inVarKind1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVarKind1,inInteger2,inInteger3,inInteger4)
    local Integer nx,ny,np,offset;
    case (DAELow.STATE(),_,_,_) then 0;  /* nx ny np states offset: 0 */
    case (DAELow.VARIABLE(),nx,ny,np) then nx + nx;  /* algebraic variables offset: 2nx algebraic variables offset: 2nx */
    case (DAELow.DUMMY_DER(),nx,ny,np) then nx + nx;  /* algebraic variables offset: 2nx */
    case (DAELow.DUMMY_STATE(),nx,ny,np) then nx + nx;
    case (DAELow.DISCRETE(),nx,ny,np) then nx + nx;  /* algebraic variables offset: 2nx */
    case (DAELow.PARAM(),nx,ny,np) /* parameter offset: 2nx+ny */
      equation
        offset = Util.listReduce({nx,nx,ny}, int_add);
      then
        offset;
    case (DAELow.CONST(),nx,ny,np) /* constant offset: 2nx+ny NOTE: should not happend */
      equation
        offset = Util.listReduce({nx,nx,ny}, int_add);
      then
        offset;
    case (_,_,_,_)
      equation
        print("calc_fixed_offset failed\n");
      then
        fail();
  end matchcontinue;
end calcFixedOffset;

protected function calcAttrOffset "function: calcAttrOffset
  author: PA

  Calculates the offset for variable attributes int the varAttr vector.
  The attributes are stored in this order:
  {states, alg. vars, parameters}.
"
  input DAELow.VarKind inVarKind1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVarKind1,inInteger2,inInteger3,inInteger4)
    local Integer nx,ny,np,offset;
    case (DAELow.STATE(),_,_,_) then 0;  /* nx ny np states offset: 0 */
    case (DAELow.VARIABLE(),nx,ny,np) then nx ;  /* algebraic variables offset: nx algebraic variables offset: 2nx */
    case (DAELow.DUMMY_DER(),nx,ny,np) then nx ;  /* algebraic variables offset: nx */
    case (DAELow.DUMMY_STATE(),nx,ny,np) then nx;
    case (DAELow.DISCRETE(),nx,ny,np) then nx;  /* algebraic variables offset: nx */
    case (DAELow.PARAM(),nx,ny,np) then nx+ny; /* parameter offset: nx+ny */
    case (DAELow.CONST(),nx,ny,np) then nx+ny; /* parameter offset: nx+ny */
    case (DAELow.CONST(),nx,ny,np) then nx+ny; /* constant offset: nx+ny NOTE: should not happend */
    case (_,_,_,_)
      equation
        print("calc_fixed_offset failed\n");
      then
        fail();
  end matchcontinue;
end calcAttrOffset;

protected function generateGlobalBufs 
"function: generateGlobalBufs
  author: PA"
  output String res;
algorithm
  res := Util.stringAppendList({"static DATA* localData = 0;\n", "#define time localData->timeValue\n"});
end generateGlobalBufs;

protected function generateMacros 
"function generateMacros
 generates the macros that are used in the code
 author: x02lucpo"
  output String retString;
algorithm
  retString := Util.stringAppendList({
          "#define DIVISION(a,b,c) ((b != 0) ? a / b : a / division_error(b,c))\n","\n","\n","int encounteredDivisionByZero = 0;\n",
          "double division_error(double b,const char* division_str)\n","{\n","  if(!encounteredDivisionByZero){\n",
          "    fprintf(stderr,\"ERROR: Division by zero in partial equation: %s.\\n\",division_str);\n",
          "    encounteredDivisionByZero = 1;\n","   }\n","   return b;\n",
          "}"});
end generateMacros;

protected function generateCDeclForStringArray 
"function generateCDeclForStringArray
 author x02lucpo
 generates a static C-array with char <name>{<number>} 
 or only a char depending it the int parameters is > 0"
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inString2,inInteger3)
    local
      String res,array_name,number_of_strings_str,array_str;
      Integer number_of_strings;
    case (array_name,_,number_of_strings)
      equation
        (number_of_strings == 0) = true;
        res = Util.stringAppendList({"char* ",array_name,"[1] = {\"\"};\n"});
      then
        res;
    case (array_name,array_str,number_of_strings)
      equation
        number_of_strings_str = intString(number_of_strings);
        res = Util.stringAppendList({"char* ",array_name,"[",number_of_strings_str,"]={",array_str,"};\n"});
      then
        res;
  end matchcontinue;
end generateCDeclForStringArray;

protected function generateGetnameFunctionIf
  input Exp.ComponentRef cr;
  input DAELow.Type tp;
  input Integer index;
  input String c_array_name;
  output String ret_str;
  String cr_str,index_str;
algorithm
  ret_str := matchcontinue(cr,tp,index,c_array_name)
  	// Strings require an extra cast.
    case (cr,DAELow.STRING(),index,c_array_name)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        index_str = intString(index);
        ret_str = Util.stringAppendList({"  if( (double*)(&",cr_str,") == ",paramInGetNameFunction,
            " ) return ",c_array_name,"[",index_str,"];\n"});
      then ret_str;
    case (cr,tp,index,c_array_name)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        index_str = intString(index);
        ret_str = Util.stringAppendList(
          {"  if( &",cr_str," == ",paramInGetNameFunction,
            " ) return ",c_array_name,"[",index_str,"];\n"});
      then ret_str;
	end matchcontinue;
end generateGetnameFunctionIf;

protected function generateGetnameFunctionIfForDerivatives
  input Exp.ComponentRef cr;
  input Integer index;
  input String c_array_name;
  output String ret_str;
  String cr_str,index_str;
algorithm
  cr_str := Exp.printComponentRefStr(cr);
  index_str := intString(index);
  ret_str := Util.stringAppendList(
          {"  if( &",DAELow.derivativeNamePrefix,cr_str," == ",
          paramInGetNameFunction," ) return ",c_array_name,"[",index_str,"];\n"});
end generateGetnameFunctionIfForDerivatives;

protected function generateNameDependentOnType 
"function: generateAlgebraicNameDependentOnType
  generates the name of the algebraic variable depending on type"
  input String baseName;
  input DAELow.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (baseName,inType)
    local
      String str;
      list<String> l;
      String baseArrayName;
    case (baseArrayName,DAELow.INT())
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
    case (baseArrayName,DAELow.REAL() )
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
    case (baseArrayName,DAELow.BOOL())
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
    case (baseArrayName,DAELow.STRING())
    equation
       str = Util.stringAppendList({"stringVariables",".",baseArrayName});
    then
       str;
    case (baseArrayName,DAELow.ENUMERATION(stringLst = l))
      equation
       str = Util.stringAppendList({baseArrayName,""});
      then
       str;
    case (baseArrayName,DAELow.EXT_OBJECT(_) )
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
  end matchcontinue;
end generateNameDependentOnType;

protected function generateArrayDefine 
"function: generateArrayDefine
  Generates a define for an array variable.
  For an array s, each scalar value is given a define, e.g.
  #define s[1,3] y[17], etc. But to also be able to treat the whole array
  as a value this function generates a define to point to the first element
  of the array, e.g. #define s &y[15]."
  input Exp.ComponentRef inComponentRef;
  input DAE.InstDims inInstDims;
  input Integer inInteger;
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inInstDims,inInteger,inString)
    local
      Exp.ComponentRef cr_1,cr;
      String cr_name,cr_name_1,indx_str,res,array;
      Integer indx;
    case (cr,(_ :: _),indx,array) /* vector name for cref with all indices 1 */
      equation
        true = Exp.crefIsFirstArrayElt(cr);
        cr_1 = Exp.crefStripLastSubs(cr);
        cr_name = Exp.printComponentRefStr(cr_1);
        cr_name_1 = Util.modelicaStringToCStr(cr_name,true);
        indx_str = intString(indx);
        res = Util.stringAppendList({"#define ",cr_name_1," ",array,"[",indx_str,"]\n"});
      then
        res;
    case (_,_,_,_) then "";
  end matchcontinue;
end generateArrayDefine;

public function changeNameForDerivative 
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

protected function generateEmptyString 
"function: generateEmptyString
  This function adds citation chars to an empty string. 
  Non empty strings are returned as is."
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString)
    local String s;
    case ("") then "\"\"";
    case (s) then s;
  end matchcontinue;
end generateEmptyString;

protected function generateInputFunctionCode 
"function: generateInputFunctionCode
   Generates the input_function for all the variables
   that are INPUT and on top model"
  input DAELow.DAELow inDAELow;
  output String outString;
  output Integer outInteger;
algorithm
  (outString,outInteger):=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> knvars_lst;
      list<String> res1;
      String res1_1,res;
      Integer lst_lenght;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        knvars_lst = DAELow.varList(knvars);
        res1 = generateInputFunctionCode2(knvars_lst, 0);
        res1_1 = Util.listSelect(res1, Util.isNotEmptyString);
        lst_lenght = listLength(res1_1);
        res1_1 = Util.stringDelimitListNonEmptyElts(res1_1, "\n  ");
        res = Util.stringAppendList({"/*\n*/\nint input_function()\n","{\n  ",res1_1,"return 0;","\n}\n\n"});
      then
        (res,lst_lenght);
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_input_function_code failed"});
      then
        fail();
  end matchcontinue;
end generateInputFunctionCode;

protected function generateInputFunctionCode2 
"function: generateInputFunctionCode2
  Helper function to generate_input_function_code"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer int,i_1,index,i;
      String i_str,cr_str,assign_str;
      list<String> res;
      DAELow.Var var;
      Exp.ComponentRef cr,name;
      DAE.VarDirection dir;
      DAELow.Type tp;
      Option<Exp.Exp> exp,st;
      Option<Values.Value> v;
      list<Exp.Subscript> dim;
      list<Absyn.Path> classes;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest;
    case ({},int) then {};
    case (((var as DAELow.VAR(varName = cr,
                              varDirection = dir,
                              varType = tp,
                              bindExp = exp,
                              bindValue = v,
                              arryDim = dim,
                              index = index,
                              origVarName = name,
                              className = classes,
                              values = attr,
                              comment = comment,
                              flowPrefix = flowPrefix,
                              streamPrefix = streamPrefix)) :: rest),i)
      equation
        true = DAELow.isVarOnTopLevelAndInput(var);
        i_str = intString(i);
        i_1 = i + 1;
        cr_str = Exp.printComponentRefStr(cr);
        assign_str = Util.stringAppendList({cr_str," = localData->inputVars[",i_str,"];"});
        res = generateInputFunctionCode2(rest, i_1);
      then
        (assign_str :: res);
    case ((var :: rest),index)
      equation
        res = generateInputFunctionCode2(rest, index);
      then
        res;
  end matchcontinue;
end generateInputFunctionCode2;

protected function generateOutputFunctionCode 
"function: generateOutputFunctionCode
   Generates the output_function for all the variables
   that are OUTPUT and on top model."
  input DAELow.DAELow inDAELow;
  output String outString;
  output Integer outInteger;
algorithm
  (outString,outInteger):=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> knvars_lst,vars_lst,vars_lst_1;
      list<String> res1;
      String res1_1,res;
      Integer lst_lenght;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        knvars_lst = DAELow.varList(knvars);
        vars_lst = DAELow.varList(vars);
        vars_lst_1 = listAppend(knvars_lst, vars_lst);
        res1 = generateOutputFunctionCode2(vars_lst_1, 0);
        res1_1 = Util.listSelect(res1, Util.isNotEmptyString);
        lst_lenght = listLength(res1_1);
        res1_1 = Util.stringDelimitListNonEmptyElts(res1_1, "\n  ");
        res = Util.stringAppendList({"/*\n*/\nint output_function()\n","{\n  ",res1_1, "return 0;","\n}\n\n"});
      then
        (res,lst_lenght);
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_output_function_code failed"});
      then
        fail();
  end matchcontinue;
end generateOutputFunctionCode;

protected function generateOutputFunctionCode2 "function: generateOutputFunctionCode2

  Helper function to generate_output_function_code
"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer int,i_1,index,i;
      String i_str,cr_str,assign_str;
      list<String> res;
      DAELow.Var var;
      Exp.ComponentRef cr,name;
      DAE.VarDirection dir;
      DAELow.Type tp;
      Option<Exp.Exp> exp,st;
      Option<Values.Value> v;
      list<Exp.Subscript> dim;
      list<Absyn.Path> classes;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest;
    case ({},int) then {};
    case (((var as DAELow.VAR(varName = cr,
                              varDirection = dir,
                              varType = tp,
                              bindExp = exp,
                              bindValue = v,
                              arryDim = dim,
                              index = index,
                              origVarName = name,
                              className = classes,
                              values = attr,
                              comment = comment,
                              flowPrefix = flowPrefix,
                              streamPrefix = streamPrefix)) :: rest),i)
      equation
        true = DAELow.isVarOnTopLevelAndOutput(var);
        i_str = intString(i);
        i_1 = i + 1;
        cr_str = Exp.printComponentRefStr(cr);
        assign_str = Util.stringAppendList({"localData->outputVars[",i_str,"] =",cr_str,";"});
        res = generateOutputFunctionCode2(rest, i_1);
      then
        (assign_str :: res);
    case ((var :: rest),index)
      equation
        res = generateOutputFunctionCode2(rest, index);
      then
        res;
  end matchcontinue;
end generateOutputFunctionCode2;

protected function generateInitialBoundParameterCode 
"function: generateInitialBoundParameterCode:
  This function generates initial value code for bound parameters
  that depend on other parameters, eg. parameter Real n=1/m;"
  input DAELow.DAELow inDAELow;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow)
    local
      Codegen.CFunction param_func,param_assigns,param_assigns_1,cfunc;
      list<DAELow.Var> knvars_lst;
      String str;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        orderedEqs = eqns,
                        removedEqs = se,
                        initialEqs = ie,
                        arrayEqs = ae,
                        algorithms = al,
                        eventInfo = ev)) /* code */
      equation
        param_func = Codegen.cMakeFunction("int", "bound_parameters", {}, {""});
        knvars_lst = DAELow.varList(knvars);
        (param_assigns,_) = generateParameterAssignments(knvars_lst, 0);
        param_assigns = addMemoryManagement(param_assigns);
        param_assigns_1 = Codegen.cAddCleanups(param_assigns, {"return 0;"});
        cfunc = Codegen.cMergeFns({param_func,param_assigns_1});
        str = Codegen.cPrintFunctionsStr({cfunc});
      then
        str;
  end matchcontinue;
end generateInitialBoundParameterCode;

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

protected function generateInitialResidualEqn "function generateInitialResidualEqn

  Helper function to generate_initial_value_code2
  Generates code on residual form for a list of equations.
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowEquationLst,inInteger)
    local
      Integer cg_id;
      Codegen.CFunction cfunc,cfunc2,cfn;
      String var,assign;
      Exp.Exp e;
      list<DAELow.Equation> es;
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg var_id cg var_id */
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: es),cg_id)
      equation
        // if exp is a string just increase the index;
        DAE.ET_STRING() = Exp.typeof(e);
        (cfunc,var,cg_id) = Codegen.generateExpression(e, cg_id, Codegen.simContext);
        assign = Util.stringAppendList({"localData->initialResiduals[i++] = 0;//",var,";"});
        cfunc = Codegen.cAddStatements(cfunc, {assign});
        (cfunc2,cg_id) = generateInitialResidualEqn(es, cg_id);
        cfn = Codegen.cMergeFns({cfunc,cfunc2});
      then
        (cfn,cg_id);
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: es),cg_id)
      equation
        (cfunc,var,cg_id) = Codegen.generateExpression(e, cg_id, Codegen.simContext);
        assign = Util.stringAppendList({"localData->initialResiduals[i++] = ",var,";"});
        cfunc = Codegen.cAddStatements(cfunc, {assign});
        (cfunc2,cg_id) = generateInitialResidualEqn(es, cg_id);
        cfn = Codegen.cMergeFns({cfunc,cfunc2});
      then
        (cfn,cg_id);
    case ((_ :: es),cg_id)
      equation
        (cfn,cg_id) = generateInitialResidualEqn(es, cg_id);
      then
        (cfn,cg_id);
  end matchcontinue;
end generateInitialResidualEqn;

protected function generateInitialValueCode "function: generateInitialValueCode

  This function generates the code for solving the initial value problem.
  Information is gathered from the start and fixed attributes of variables
  and from initial equations.
"
  input DAELow.DAELow inDAELow;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> vars_lst,knvars_lst;
      list<DAELow.Equation> initial_eqns2;
      Codegen.CFunction start_assigns1,start_assigns2,param_assigns,init_func_1,init_func,res;
      Integer cg_id,cg_id_1,cg_id_2;
      String str;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        vars_lst = DAELow.varList(vars);
        knvars_lst = DAELow.varList(knvars);
        // not used: initial_eqns2 = generateInitialEquationsFromStart(vars_lst);
        (start_assigns1,cg_id)   = generateInitialAssignmentsFromStart(vars_lst, 0);
        (start_assigns2,cg_id_1) = generateInitialAssignmentsFromStart(knvars_lst, cg_id);
        (param_assigns,cg_id_2)  = generateParameterAssignments(knvars_lst, cg_id_1);
        init_func_1 = Codegen.cMakeFunction("int", "initial_function", {}, {""});
        init_func = Codegen.cAddCleanups(init_func_1, {"return 0;"});
        // adrpo changed the order below, before was: start_assigns, param_assigns
        // i think parameters should be set before as start assignments may depend on them.
        res = Codegen.cMergeFns({init_func, param_assigns, start_assigns1, start_assigns2});
        str = Codegen.cPrintFunctionsStr({res});
      then
        str;
    case (_)
      equation
        init_func_1 = Codegen.cMakeFunction("int", "initial_function", {}, {""});
        init_func = Codegen.cAddCleanups(init_func_1, {"return 0;"});
        str = Codegen.cPrintFunctionsStr({init_func});
      then
        str;
  end matchcontinue;
end generateInitialValueCode;

protected function generateParameterAssignments "function: generateParameterAssignments
  Generates code for the parameter settings that depends on other
  parameters (as expressions). For instance, parameter Real m=2n+1;
  Those are calculated once in the initial function.
"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer cg_id,cg_id_1,cg_id_2;
      String cr_str,e_str,stmt;
      Codegen.CFunction exp_func,func,func_1,func_2;
      Exp.ComponentRef cr;
      Exp.Exp e;
      list<DAELow.Var> vs;
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg_id cg var_id */
    case ((DAELow.VAR(varName = cr,varKind = DAELow.PARAM(),bindExp = SOME(e)) :: vs),cg_id)
      equation
        false = Exp.isConst(e);
        cr_str = Exp.printComponentRefStr(cr);
        (exp_func,e_str,cg_id_1) = Codegen.generateExpression(e, cg_id, Codegen.simContext);
        (func,cg_id_2) = generateParameterAssignments(vs, cg_id_1);
        stmt = Util.stringAppendList({cr_str," = ",e_str,";"});
        exp_func = Codegen.cAddStatements(exp_func, {stmt});
        func_2 = Codegen.cMergeFns({exp_func,func});
      then
        (func_2,cg_id_2);
    case ((_ :: vs),cg_id)
      equation
        (func,cg_id_1) = generateParameterAssignments(vs, cg_id);
      then
        (func,cg_id_1);
  end matchcontinue;
end generateParameterAssignments;

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
    case ({}) then {};
    case (((v as DAELow.VAR(varName = cr,varKind = kind,values = attr)) :: vars)) /* add equations for variables with fixed = true */
      equation
        true = DAELow.varFixed(v);
        true = DAEUtil.hasStartAttr(attr);
        startv = DAEUtil.getStartAttr(attr);
        eqns = generateInitialEquationsFromStart(vars);
      then
        (DAELow.EQUATION(DAE.CREF(cr,DAE.ET_OTHER()),startv) :: eqns);
    case ((_ :: vars))
      equation
        eqns = generateInitialEquationsFromStart(vars);
      then
        eqns;
  end matchcontinue;
end generateInitialEquationsFromStart;

protected function generateInitialAssignmentsFromStart "function: generateInitialAssignmentsFromStart

"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer cg_id,cg_id_1,cg_id_2;
      Codegen.CFunction func,exp_func,func_1,func_2;
      String cr_str,startv_str,stmt1,stmt2;
      Exp.ComponentRef cr,origname;
      DAELow.VarKind kind;
      Exp.Exp startv;
      Option<DAE.VariableAttributes> attr;
      list<DAELow.Var> vars;
      String origname_str;
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg var_id cg var_id */
    case ((DAELow.VAR(varName = cr,varKind = kind,values = attr, origVarName = origname) :: vars),cg_id) /* also add an assignment for variables that have non-constant
	    expressions, e.g. parameter values, as start.
	   NOTE: such start attributes can then not be changed in the text
	   file, since the initial calc. will override those entries!
	 */
      equation
        startv = DAEUtil.getStartAttr(attr);
        false = Exp.isConst(startv);
        (func,cg_id_1) = generateInitialAssignmentsFromStart(vars, cg_id);
        origname_str = Exp.printComponentRefStr(origname);
        cr_str = Exp.printComponentRefStr(cr);
        (exp_func,startv_str,cg_id_2) = Codegen.generateExpression(startv, cg_id_1, Codegen.simContext);
        stmt1 = Util.stringAppendList({cr_str," = ",startv_str,";"});
        stmt2 = Util.stringAppendList({"if (sim_verbose) { printf(\"Setting variable start value:%s(start=%f)\\n\", \"", origname_str, "\", ",
                startv_str,"); }"});
        func_1 = Codegen.cAddStatements(func, stmt1::{stmt2});
        func_2 = Codegen.cMergeFns({exp_func,func_1});
      then
        (func_2,cg_id_2);
    case ((_ :: vars),cg_id)
      equation
        (func,cg_id_1) = generateInitialAssignmentsFromStart(vars, cg_id);
      then
        (func,cg_id_1);
  end matchcontinue;
end generateInitialAssignmentsFromStart;

protected function generateOdeCode "function generateOdeCode
  Outputs simulation code from a DAELow.
  The state calculations are generated on explicit ode form:
  \\dot{x} := f(x,y,t)
"
  input DAELow.DAELow inDAELow1;
  input list<list<Integer>> inIntegerLstLst2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input DAELow.IncidenceMatrix inIncidenceMatrix5;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT6;
  input Absyn.Path inPath7;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow1,inIntegerLstLst2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inPath7)
    local
      String cname,ode_func_str,extra_funcs_str,res;
      list<list<Integer>> blt_states,blt_no_states,comps;
      Codegen.CFunction block_code,func_1,func;
      list<CFunction> extra_funcs;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<Integer>[:] m,mt;
      Absyn.Path class_;
    case (dlow,comps,ass1,ass2,m,mt,class_) /* components ass1 ass2 */
      equation
        cname = Absyn.pathString(class_);
        (blt_states,blt_no_states) = DAELow.generateStatePartition(comps, dlow, ass1, ass2, m, mt);
        (block_code,_,extra_funcs) = generateOdeBlocks(false,dlow,ass1, ass2, blt_states, 0);
        func_1 = Codegen.cMakeFunction("int", "functionODE", {}, {""});
        func_1 = addMemoryManagement(func_1);
        func = Codegen.cAddCleanups(func_1, {"return 0;"});
        func_1 = Codegen.cMergeFns({func,block_code});
        ode_func_str = Codegen.cPrintFunctionsStr({func_1});
        extra_funcs_str = Codegen.cPrintFunctionsStr(extra_funcs);
        res = Util.stringAppendList({extra_funcs_str,ode_func_str});
      then
        res;
    case (dlow,comps,ass1,ass2,m,mt,class_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_ode_code failed"});
      then
        fail();
  end matchcontinue;
end generateOdeCode;

protected function addMemoryManagement 
"function: addMemoryManagement
  This function adds memory management code for a function.
  It consists of two calls, get_memory_state and restore_memory_state."
  input CFunction cfunc;
  output CFunction cfunc;
algorithm
  cfunc := Codegen.cAddVariables(cfunc, {"state mem_state;"});
  cfunc := Codegen.cPrependStatements(cfunc, {"mem_state = get_memory_state();"});
  cfunc := Codegen.cAddCleanups(cfunc, {"restore_memory_state(mem_state);"});
end addMemoryManagement;

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
        DAELow.WHEN_EQUATION(whenEq) = listNth(eqnl, eqn-1);
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
      DAELow.WHEN_EQUATION(DAELow.WHEN_EQ(_,cr2,exp,_)) = DAELow.equationNth(eqs,intAbs(e)-1);
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

protected function buildWhenConditionChecks
"function:  buildWhenConditionChecks
Generates simulation code that checks whether a when condition has become true."
  input DAELow.DAELow inDAELow          "The lowered DAE";
  input list<list<Integer>> comps       "The order of the sorted equations";
  output String outString               "The generated C-code";
  output list<HelpVarInfo> helpVarList  "List of help variables that were introduced by this function.";
algorithm
  (outString,helpVarLst):=
  matchcontinue (inDAELow,comps)
    local
      list<Integer> orderOfEquations,orderOfEquations_1;
      list<DAELow.Equation> eqnl;
      Integer n;
      String res1,res2,res;
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
        (res1,helpVarInfo1) = buildWhenConditionChecks4(orderOfEquations_1, eqnl, whenClauseList, 0);
        n = listLength(helpVarInfo1);
        // Generate checks also for when clauses without equations but containing reinit statements.
        (res2,helpVarInfo2) = buildWhenConditionChecks2(whenClauseList, 0, n);
        res = stringAppend(res1, res2);
        helpVarInfo = listAppend(helpVarInfo1, helpVarInfo2);
      then
        (res,helpVarInfo);
    case (_,_)
      equation
        print("-build_when_condition_checks failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks;

protected function generateEventCheckingCode 
"function:  generateEventCheckingCode"
  input DAELow.DAELow inDAELow1;
  input list<list<Integer>> inIntegerLstLst2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input DAELow.IncidenceMatrix inIncidenceMatrix5;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT6;
  input Absyn.Path inPath7;
  output String outString "Generated event checking code";
  output list<HelpVarInfo> helpVarLst "List of introduced help variables";
algorithm
  (outString,helpVarLst):=
  matchcontinue (inDAELow1,inIntegerLstLst2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inPath7)
    local
      Boolean usezc;
      String check_code,check_code_1,res,check_code2,check_code2_1;
      list<HelpVarInfo> helpVarInfo;
      DAELow.DAELow dlow;
      list<list<Integer>> comps;
      Integer[:] ass1,ass2;
      list<Integer>[:] m,mt;
      Absyn.Path class_;
    case (dlow,comps,ass1,ass2,m,mt,class_)
      equation
        usezc = useZerocrossing();
        // The eventChecking consist of checking if the helpvariables from when equations has changed
        // and checking if discrete variables in the model has changed.
        (check_code,helpVarInfo) = buildWhenConditionChecks(dlow, comps);
        check_code2 = buildDiscreteVarChanges(dlow,comps,ass1,ass2,m,mt);
        check_code_1 = Util.if_(usezc, check_code, "");
        check_code2_1 = Util.if_(usezc,check_code2, "");
        res = Util.stringAppendList(
          {"int checkForDiscreteVarChanges()\n{\n",
          "  int needToIterate=0;\n",
          check_code_1,"  ",check_code2_1,"\n",
				  "  for (long i = 0; i < localData->nHelpVars; i++) {\n",
				  "    if (change(localData->helpVars[i])) { needToIterate=1; }\n  }\n",
          "  return needToIterate;\n","}\n"});
      then
        (res,helpVarInfo);
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_event_checking_code failed"});
      then
        fail();
  end matchcontinue;
end generateEventCheckingCode;

protected function generateOdeBlocks 
"function: generateOdeBlocks
  author: PA
  Generates the simulation code for the ode code."
	input Boolean genDiscrete "if true generate calculation of discrete variables";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4,inInteger5)
    local
      Integer cg_id,cg_id_1,cg_id_2,eqn;
      Codegen.CFunction s1,s2,res;
      list<CFunction> f1,f2,res2;
      DAELow.DAELow dae;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;
    case (genDiscrete,_,_,_,{},cg_id) then (Codegen.cEmptyFunction,cg_id,{});  /* cg var_id block code cg var_id extra functions code */
    case (genDiscrete,dae,ass1,ass2,((block_ as (_ :: (_ :: _))) :: blocks),cg_id)
      equation
        (s1,cg_id_1,f1) = generateOdeSystem(genDiscrete,dae, ass1, ass2, block_, cg_id) "For system of equations" ;
        (s2,cg_id_2,f2) = generateOdeBlocks(genDiscrete,dae, ass1, ass2, blocks, cg_id_1);
        res = Codegen.cMergeFns({s1,s2});
        res2 = listAppend(f1, f2);
      then
        (res,cg_id_2,res2);
    case (genDiscrete,dae,ass1,ass2,((block_ as {eqn}) :: blocks),cg_id)
      equation
        (s1,cg_id_1,f1) = generateOdeEquation(genDiscrete,dae,ass1, ass2, eqn, cg_id) "for single equations" ;
        (s2,cg_id_2,f2) = generateOdeBlocks(genDiscrete,dae, ass1, ass2, blocks, cg_id_1);
        res = Codegen.cMergeFns({s1,s2});
        res2 = listAppend(f1, f2);
      then
        (res,cg_id_2,res2);
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generate_ode_blocks failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeBlocks;

protected function generateOdeSystem "function: generateOdeSystem
  author: PA

  Generates code for a subsystem of equations, both linear and non-linear
  and mixed systems with both discrete and continuous variables.

  A linear system can be written as A x = b
  where A is a n by n matrix and b is a vector of size n.
  Such a system can for instance be solved by gaussian elimination or by
  using numerical methods in LAPACK.

  A non-linear system of equations is solved by the hybrd function. To solve
  the system a function that calculates the residuals of the equations must
  be given. The hybrd function also needs to calcutate the dierivatives of
  the equation system, i.e. the jacobian. Currently this is performed
  numerically, but it could also be done analytically for systems which
  have an analytic jacobian.

  A mixed system of equations contain both continuous and discrete time
  variables. Such system is solved by first guessing values on the
  discrete time variables (e.g. based on previous values). Then the
  continous time variables are solved. Finally, the discrete variables
  are checked to see if they fullfill the constraints of the system
  equations. If not, a fixed point iteration over the possible values of
   the discrete variables are made.
  Note that a mixed system can also be linear or non-linear.

  If the Boolean genDiscrete is true, mixed systems are generated with both discrete and continous
  equations, i.e. as mixed systems are solved during event iteration. If genDiscrete is false,
  only the continous part is generated (no discrete equations at all), i.e. what is necessary to
  calculate during continuous integration.
"
	input Boolean genDiscrete "if true generate discrete equations";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLst4,inInteger5)
    local
      String rettp,fn;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,var_lst_1,cont_var1;
      DAELow.Variables vars_1,vars,knvars,exvars;
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,daelow,subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      String s;
      Codegen.CFunction s2,s1,s0,s2_1,s3,s4,cfn;
      Integer cg_id_1,cg_id,cg_id3,cg_id1,cg_id2,cg_id4,cg_id5;
      list<CFunction> f1,extra_funcs1;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      DAELow.ExternalObjectClasses eoc;
      list<String> retrec,arg,locvars,init,locvars,stmts,cleanups,stmts_1,stmts_2;

      /* Mixed system of equations, continuous part only */
    case (false,(daelow as DAELow.DAELOW(vars,knvars,exvars,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_,cg_id)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
 				cont_var1 = Util.listMap(cont_var, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,eqns_1,se,ie,ae,al,ev,eoc);
        //print("subsystem dae:"); DAELow.dump(cont_subsystem_dae);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        //print("mixed system, subsystem incidence matrix:\n");
        //DAELow.dumpIncidenceMatrix(m);
        //print("mixed system, calculating jacobian....\n");
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,true) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        //print("mixed system, analyzing jacobian\n");
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        //print("mixed syste, jacobian_str\n");
        //s = DAELow.jacobianTypeStr(jac_tp);
        //print("mixed system with Jacobian type: "); print(s); print("\n");
        //s = DAELow.dumpJacobianStr(jac);
        //print("jacobian ="); print(s); print("\n");

        (s2,cg_id_1,f1) = generateOdeSystem2(false,false,cont_subsystem_dae, jac, jac_tp, cg_id);
      then
        (s2,cg_id_1,f1);

        /* Mixed system of equations, both continous and discrete eqns*/
    case (true,(dlow as DAELow.DAELOW(vars,knvars,exvars,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_,cg_id)
      local Integer numValues;
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
				cont_var1 = Util.listMap(cont_var, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,eqns_1,se,ie,ae,al,ev,eoc);
        //print("subsystem dae:"); DAELow.dump(cont_subsystem_dae);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,true) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        (s0,cg_id1,numValues) = generateMixedHeader(cont_eqn, cont_var, disc_eqn, disc_var, cg_id);
        (Codegen.CFUNCTION(rettp,fn,retrec,arg,locvars,init,stmts,cleanups),cg_id2,extra_funcs1) = generateOdeSystem2(true/*mixed system*/,true,cont_subsystem_dae, jac, jac_tp, cg_id1);
        stmts_1 = Util.listFlatten({{"{"},locvars,stmts,{"}"}}) "initialization of e.g. matrices for linsys must be done in each
	    iteration, create new scope and put them first." ;
        s2_1 = Codegen.CFUNCTION(rettp,fn,retrec,arg,{},init,stmts_1,cleanups);
        (s4,cg_id3) = generateMixedFooter(cont_eqn, cont_var, disc_eqn, disc_var, cg_id2);
        (s3,cg_id4,_) = generateMixedSystemDiscretePartCheck(disc_eqn, disc_var, cg_id3,numValues);
        (s1,cg_id5,_) = generateMixedSystemStoreDiscrete(disc_var, 0, cg_id4);
        cfn = Codegen.cMergeFns({s0,s1,s2_1,s3,s4});
      then
        (cfn,cg_id5,extra_funcs1);

        /* continuous system of equations */
    case (genDiscrete,(daelow as DAELow.DAELOW(vars,knvars,exvars,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,block_,cg_id)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2) "extract the variables and equations of the block." ;
        var_lst_1 = Util.listMap(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(var_lst_1);
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,eqns_1,se,ie,ae,al,ev,eoc) "not used" ;
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,false) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac);
        (s1,cg_id_1,f1) = generateOdeSystem2(false,genDiscrete,subsystem_dae, jac, jac_tp, cg_id) "	print \"generating subsystem :\" &
	DAELow.dump subsystem_dae &" ;
      then
        (s1,cg_id_1,f1);
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generate_ode_system failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem;

protected function generateMixedHeader "function: generateMixedHeader
  author: PA

  Generates the header code for a mixed system.
"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input list<DAELow.Equation> inDAELowEquationLst3;
  input list<DAELow.Var> inDAELowVarLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output Integer numValues;
algorithm
  (outCFunction,outInteger,numValues):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inDAELowEquationLst3,inDAELowVarLst4,inInteger5)
    local
      Integer len,cg_id_1,cg_id;
      String len_str,stmt;
      Codegen.CFunction cfn1,cfcn,cfcn_1;
      list<DAELow.Equation> cont_eqns,disc_eqns;
      list<DAELow.Var> cont_vars,disc_vars;
    case (cont_eqns,cont_vars,disc_eqns,disc_vars,cg_id) /* continous eqns continuous vars discrete eqns discrete vars cg var_id cg var_id */
      equation
        len = listLength(disc_vars);
        len_str = intString(len);
        stmt = Util.stringAppendList({"mixed_equation_system(",len_str,");"});
        (cfn1,cg_id_1,numValues) = generateMixedDiscretePossibleValues(cont_eqns, cont_vars, disc_eqns, disc_vars, cg_id);
        cfcn = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
        cfcn_1 = Codegen.cMergeFns({cfcn,cfn1});
      then
        (cfcn_1,cg_id_1,numValues);
  end matchcontinue;
end generateMixedHeader;

protected function generateMixedDiscretePossibleValues "function

"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input list<DAELow.Equation> inDAELowEquationLst3;
  input list<DAELow.Var> inDAELowVarLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output Integer numValues;
algorithm
  (outCFunction,outInteger,numValues):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inDAELowEquationLst3,inDAELowVarLst4,inInteger5)
    local
      list<Exp.Exp> rels;
      list<list<String>> values,values_1;
      list<Integer> value_dims;
      list<String> values_2,ss;
      String s,s2,disc_len_str,values_len_str,stmt1,stmt2;
      Integer disc_len,values_len,cg_id;
      Codegen.CFunction cfn_1;
      list<DAELow.Equation> cont_e,disc_e;
      list<DAELow.Var> cont_v,disc_v;
    case (cont_e,cont_v,disc_e,disc_v,cg_id) /* continous eqns continuous vars discrete eqns discrete vars cg var_id cg var_id */
      equation
        rels = mixedCollectRelations(cont_e, disc_e);
        (values,value_dims) = generateMixedDiscretePossibleValues2(rels, disc_v, cg_id);
        values_1 = generateMixedDiscreteCombinationValues(values);
        values_2 = Util.listFlatten(values_1);
        ss = Util.listMap(value_dims, int_string);
        s = Util.stringDelimitList(ss, ", ");
        s2 = Util.stringDelimitList(values_2, ", ");
        disc_len = listLength(disc_v);
        disc_len_str = intString(disc_len);
        values_len = listLength(values_2);
        values_len_str = intString(values_len);
        stmt1 = Util.stringAppendList({"double values[",values_len_str,"]={",s2,"};"});
        stmt2 = Util.stringAppendList({"int value_dims[",disc_len_str,"]={",s,"};"});
        cfn_1 = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt1,stmt2});
      then
        (cfn_1,cg_id,values_len);
    case (_,_,_,_,_)
      equation
        print("generate_mixed_discrete_possible_values failed\n");
      then
        fail();
  end matchcontinue;
end generateMixedDiscretePossibleValues;

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

protected function generateMixedFooter "function: generateMixedFooter
  author: PA

  Generates the header code for a mixed system.
"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input list<DAELow.Equation> inDAELowEquationLst3;
  input list<DAELow.Var> inDAELowVarLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inDAELowEquationLst3,inDAELowVarLst4,inInteger5)
    local
      Integer len,cg_id;
      String len_str,stmt;
      Codegen.CFunction cfcn;
      list<DAELow.Equation> cont_eqns,disc_eqns;
      list<DAELow.Var> cont_vars,disc_vars;
    case (cont_eqns,cont_vars,disc_eqns,disc_vars,cg_id) /* continous eqns continuous vars discrete eqns discrete vars cg var_id cg var_id */
      equation
        len = listLength(disc_vars);
        len_str = intString(len);
        stmt = Util.stringAppendList({"mixed_equation_system_end(",len_str,");"});
        cfcn = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (cfcn,cg_id);
  end matchcontinue;
end generateMixedFooter;

protected function generateMixedSystemStoreDiscrete "function: generateMixedSystemStoreDiscrete
  author: PA

  Stores all discrete variables in discrite_loc variable.
"
  input list<DAELow.Var> inDAELowVarLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Codegen.CFunction outCFunction;
  output Integer outInteger;
  output list<Codegen.CFunction> outCodegenCFunctionLst;
algorithm
  (outCFunction,outInteger,outCodegenCFunctionLst):=
  matchcontinue (inDAELowVarLst1,inInteger2,inInteger3)
    local
      Integer cg_id,indx_1,cg_id_1,indx;
      Codegen.CFunction cfn,cfn_1;
      list<CFunction> funcs;
      Exp.ComponentRef cr;
      String indx_str,cr_str,stmt;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ({},_,cg_id) then (Codegen.cEmptyFunction,cg_id,{});  /* indx cg var_id cg var_id */
    case ((v :: vs),indx,cg_id)
      equation
        indx_1 = indx + 1;
        (cfn,cg_id_1,funcs) = generateMixedSystemStoreDiscrete(vs, indx_1, cg_id);
        cr = DAELow.varCref(v);
        indx_str = intString(indx);
        cr_str = Exp.printComponentRefStr(cr);
        stmt = Util.stringAppendList({"discrete_loc[",indx_str,"] = ",cr_str,";"});
        cfn_1 = Codegen.cAddStatements(cfn, {stmt});
      then
        (cfn_1,cg_id_1,funcs);
    case (_,_,cg_id)
      equation
        print("generate_mixed_system_store_discrete failed\n");
      then
        fail();
  end matchcontinue;
end generateMixedSystemStoreDiscrete;

protected function generateMixedSystemDiscretePartCheck "function: generateMixedSystemDiscretePartCheck
  author: PA

  Generates check of the discrete parts.
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  input Integer numValues;
  output Codegen.CFunction outCFunction;
  output Integer outInteger;
  output list<Codegen.CFunction> outCodegenCFunctionLst;
algorithm
  (outCFunction,outInteger,outCodegenCFunctionLst):=
  matchcontinue (inDAELowEquationLst,inDAELowVarLst,inInteger,numValues)
    local
      Codegen.CFunction cfn,cfn_1;
      Integer cg_id,len;
      list<CFunction> funcs;
      String len_str,ptrs_str,stmt1,stmt2,numValuesStr;
      list<Exp.ComponentRef> crefs;
      list<String> strs,strs2;
      list<DAELow.Equation> eqn;
      list<DAELow.Var> var;
    case (eqn,var,cg_id,numValues) /* cg var_id cg var_id */
      equation
        (cfn,cg_id,funcs) = generateMixedSystemDiscretePartCheck2(eqn, var, 0, cg_id);
        len = listLength(eqn);
        len_str = intString(len);
        crefs = Util.listMap(var, DAELow.varCref);
        strs = Util.listMap(crefs, Exp.printComponentRefStr);
        strs2 = Util.listMap1r(strs, string_append, "&");
        ptrs_str = Util.stringDelimitList(strs2, ", ");
        numValuesStr = intString(numValues);
        stmt1 = Util.stringAppendList({"double *loc_ptrs[",len_str,"]={",ptrs_str,"};"});
        stmt2 = Util.stringAppendList({"check_discrete_values(",len_str,",",numValuesStr,");"});
        cfn_1 = Codegen.cAddStatements(cfn, {"{",stmt1,stmt2,"}"});
      then
        (cfn_1,cg_id,funcs);
  end matchcontinue;
end generateMixedSystemDiscretePartCheck;

protected function generateMixedSystemDiscretePartCheck2
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  output Codegen.CFunction outCFunction;
  output Integer outInteger;
  output list<Codegen.CFunction> outCodegenCFunctionLst;
algorithm
  (outCFunction,outInteger,outCodegenCFunctionLst):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inInteger3,inInteger4)
    local
      Integer cg_id,indx_1,cg_id_1,cg_id_2,indx;
      Codegen.CFunction cfn,exp_func,exp_func_1,cfn_1;
      list<CFunction> funcs;
      Exp.ComponentRef cr;
      Exp.Exp varexp,expr,e1,e2;
      String var,indx_str,cr_str,stmt,stmt2;
      list<DAELow.Equation> eqns;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ({},_,_,cg_id) then (Codegen.cEmptyFunction,cg_id,{});  /* index cg var_id cg var_id */
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: eqns),(v :: vs),indx,cg_id)
      equation
        indx_1 = indx + 1;
        (cfn,cg_id_1,funcs) = generateMixedSystemDiscretePartCheck2(eqns, vs, indx_1, cg_id);
        cr = DAELow.varCref(v);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_2) = Codegen.generateExpression(expr, cg_id_1, Codegen.simContext);
        indx_str = intString(indx);
        cr_str = Exp.printComponentRefStr(cr);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        stmt2 = Util.stringAppendList({"discrete_loc2[",indx_str,"] = ",cr_str,";"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt,stmt2});
        cfn_1 = Codegen.cMergeFns({exp_func_1,cfn});
      then
        (cfn_1,cg_id_2,funcs);
    case (_,_,_,cg_id)
      equation
        print("generate_mixed_system_discrete_part_check2 failed\n");
      then
        fail();
  end matchcontinue;
end generateMixedSystemDiscretePartCheck2;

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
    case (v,(eqn as DAELow.EQUATION(DAE.CREF(cr,_),e2))::_) equation
      cr1=DAELow.varCref(v);
      true = Exp.crefEqual(cr1,cr);
    then eqn;
    case(v,(eqn as DAELow.EQUATION(e2,DAE.CREF(cr,_)))::_) equation
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

protected function hasDiscreteVar "function: hasDiscreteVar
  author: PA

  Helper function to is_mixed_system. Returns true if var list contains
  discrete time variable.
"
  input list<DAELow.Var> inDAELowVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELowVarLst)
    local
      Exp.ComponentRef cr;
      Boolean res;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.DISCRETE()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varType = DAELow.INT()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varType = DAELow.BOOL()) :: _)) then true;
    case ((v :: vs))
      equation
        res = hasDiscreteVar(vs);
      then
        res;
    case ({}) then false;
  end matchcontinue;
end hasDiscreteVar;

protected function hasContinousVar "function: hasContinousVar
  author: PA

  Helper function to is_mixed_system. Returns true if var list contains
  discrete time variable.
"
  input list<DAELow.Var> inDAELowVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELowVarLst)
    local
      Exp.ComponentRef cr;
      Boolean res;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.VARIABLE()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.STATE()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.DUMMY_DER()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.DUMMY_STATE()) :: _)) then true;
    case ((v :: vs))
      equation
        res = hasContinousVar(vs);
      then
        res;
    case ({}) then false;
  end matchcontinue;
end hasContinousVar;

protected function generateOdeSystem2 "function: generateOdeSystem2
  author: PA

  Generates the actual simulation code for the system of equation, once
  its jacobian and type has been given.
"
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input DAELow.JacobianType inJacobianType;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (mixedEvent,genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inJacobianType,inInteger)
    local
      Codegen.CFunction s1,s2,s3,s4,s5,s;
      Integer cg_id_1,cg_id,eqn_size,unique_id,cg_id1,cg_id2,cg_id3,cg_id4,cg_id5;
      list<CFunction> f1;
      DAELow.DAELow dae,d;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      DAELow.Variables v,kv;
      DAELow.EquationArray eqn;
      list<DAELow.Equation> eqn_lst;
      list<DAELow.Var> var_lst;
      list<Exp.ComponentRef> crefs;
      DAELow.MultiDimEquation[:] ae;
      Boolean genDiscrete;

      /* A single array equation */
    case (mixedEvent,_,dae,jac,jac_tp,cg_id)
      equation
        singleArrayEquation(dae);
        (s1,cg_id_1,f1) = generateSingleArrayEqnCode(dae, jac, cg_id);
      then
        (s1,cg_id_1,f1);

        /* A single algorithm section for several variables. */
    case (mixedEvent,genDiscrete,dae,jac,jac_tp,cg_id)
      equation
        singleAlgorithmSection(dae);
        (s1,cg_id_1,f1) = generateSingleAlgorithmCode(genDiscrete, dae, jac, cg_id);
      then
        (s1,cg_id_1,f1);

        /* constant jacobians. Linear system of equations (A x = b) where
         A and b are constants. TODO: implement symbolic gaussian elimination here. Currently uses dgesv as
         for next case */
    case (mixedEvent,genDiscrete,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_CONSTANT(),cg_id)
      local list<tuple<Integer, Integer, DAELow.Equation>> jac;
      equation
        eqn_size = DAELow.equationSize(eqn);
        (s1,cg_id_1,f1) = generateOdeSystem2(mixedEvent,genDiscrete,d, SOME(jac), DAELow.JAC_TIME_VARYING(), cg_id) "NOTE: Not impl. yet, use time_varying..." ;
      then
        (s1,cg_id_1,f1);

	/* Time varying jacobian. Linear system of equations that needs to
		  be solved during runtime. */
    case (mixedEvent,_,(d as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_TIME_VARYING(),cg_id)
      local list<tuple<Integer, Integer, DAELow.Equation>> jac;
      equation
        //print("linearSystem of equations:");
        //DAELow.dump(d);
        //print("Jacobian:");print(DAELow.dumpJacobianStr(SOME(jac)));print("\n");
        eqn_size = DAELow.equationSize(eqn);
        unique_id = tick();
        (s1,cg_id1) = generateOdeSystem2Declaration(mixedEvent,eqn_size, unique_id, cg_id);
        (s2,cg_id2) = generateOdeSystem2PopulateAb(mixedEvent,jac, v, eqn, unique_id, cg_id1);
        (s3,cg_id3) = generateOdeSystem2SolveCall(mixedEvent,eqn_size, unique_id, cg_id2);
        (s4,cg_id4) = generateOdeSystem2CollectResults(mixedEvent,v, unique_id, cg_id3);
        s = Codegen.cMergeFns({s1,s2,s3,s4});
      then
        (s,cg_id4,{});
    case (mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),SOME(jac),DAELow.JAC_NONLINEAR(),cg_id) /* Time varying nonlinear jacobian. Non-linear system of equations */
      local list<tuple<Integer, Integer, DAELow.Equation>> jac;
      equation

        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates);// get varnames and prefix $der for states.
        (s1,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(mixedEvent,crefs, eqn_lst,ae, cg_id);
      then
        (s1,cg_id_1,f1);
    case (mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),NONE,DAELow.JAC_NO_ANALYTIC(),cg_id) /* no analythic jacobian available. Generate non-linear system */
      equation
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
        (s1,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(mixedEvent,crefs, eqn_lst, ae, cg_id);
      then
        (s1,cg_id_1,f1);
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generate_ode_system2 failed \n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2;

protected function generateSingleAlgorithmCode "function: generateSingleAlgorithmCode
  author: PA

  Generates code for a system consisting of a  single algorithm.
"
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inInteger)
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      Exp.Exp e1,e2;
      Exp.ComponentRef cr,origname,cr_1;
      Codegen.CFunction s1;
      list<CFunction> f1;
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
      Boolean genDiscrete;
    case (genDiscrete, DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev),jac,cg_id) /* eqn code cg var_id extra functions */
      equation
        (DAELow.ALGORITHM(indx,_,algOutExpVars) :: _) = DAELow.equationList(eqns);
        alg = al[indx + 1];
        solvedVars = Util.listMap(DAELow.varList(vars),DAELow.varCref);
        algOutVars = Util.listMap(algOutExpVars,Exp.expCref);
        // The variables solved for and the output variables of the algorithm must be the same.
        true = Util.listSetEqualOnTrue(solvedVars,algOutVars,Exp.crefEqual);
        (s1,cg_id_1) = Codegen.generateAlgorithm(DAE.ALGORITHM(alg), cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
      then (s1,cg_id_1,{});

        /* Error message, inverse algorithms not supported yet */
 	 case (genDiscrete,DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev),jac,cg_id)
      equation
        (DAELow.ALGORITHM(indx,_,algOutExpVars) :: _) = DAELow.equationList(eqns);
        alg = al[indx + 1];
        solvedVars = Util.listMap(DAELow.varList(vars),DAELow.varCref);
        algOutVars = Util.listMap(algOutExpVars,Exp.expCref);

        // The variables solved for and the output variables of the algorithm must be the same.
        false = Util.listSetEqualOnTrue(solvedVars,algOutVars,Exp.crefEqual);
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg)});
        message = Util.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,
          ". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,
          {message});
      then fail();

    case (_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {
          "array equations currently only supported on form v = functioncall(...)"});
      then
        fail();
  end matchcontinue;
end generateSingleAlgorithmCode;

protected function generateSingleArrayEqnCode 
"function: generateSingleArrayEqnCode
  author: PA
  Generates code for a system consisting of a  single array equation."
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inInteger)
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      Exp.Exp e1,e2;
      Exp.ComponentRef cr,origname,cr_1;
      Codegen.CFunction s1;
      list<CFunction> f1;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
    case (DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        orderedEqs = eqns,
                        removedEqs = se,
                        initialEqs = ie,
                        arrayEqs = ae,
                        algorithms = al,
                        eventInfo = ev),jac,cg_id) /* eqn code cg var_id extra functions */
      local String cr_1_str;
      equation
        (DAELow.ARRAY_EQUATION(indx,_) :: _) = DAELow.equationList(eqns);
        DAELow.MULTIDIM_EQUATION(ds,e1,e2) = ae[indx + 1];
        ((DAELow.VAR(cr,_,_,_,_,_,_,_,origname,_,_,_,_,_) :: _)) = DAELow.varList(vars);
        // We need to strip subs from origname since they are removed in cr.
        cr_1 = Exp.crefStripLastSubs(origname);
        // Since we use origname we need to replace '.' with '$P' manually.
        cr_1_str = Util.modelicaStringToCStr(Exp.printComponentRefStr(cr_1),true); // stringAppend("$",Util.modelicaStringToCStr(Exp.printComponentRefStr(cr_1),true));
        cr_1 = DAE.CREF_IDENT(cr_1_str,DAE.ET_OTHER(),{});
        (e1,e2) = solveTrivialArrayEquation(cr_1,e1,e2);
        (s1,cg_id_1,f1) = generateSingleArrayEqnCode2(cr_1, cr_1, e1, e2, cg_id);
      then
        (s1,cg_id_1,f1);
        
    case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"array equations currently only supported on form v = functioncall(...)"});
      then
        fail();
  end matchcontinue;
end generateSingleArrayEqnCode;

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

protected function generateSingleArrayEqnCode2 
"function generateSingleArrayEqnCode2
  author: PA
  Helper function to generateSingleArrayEqnCode.
  Currenlty solves only solved equation on form v = foo(...)"
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
  input Exp.Exp inExp3;
  input Exp.Exp inExp4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inComponentRef1,inComponentRef2,inExp3,inExp4,inInteger5)
    local
      String s1,s2,stmt,s3,s4,s;
      Codegen.CFunction cfunc,func_1;
      Integer cg_id_1,cg_id;
      Exp.ComponentRef cr,eltcr,cr2;
      Exp.Exp e1,e2;
    case (cr,eltcr,(e1 as DAE.CREF(componentRef = cr2)),e2,cg_id) /* origname firsteltname lhs rhs cg var_id cg var_id */
      equation
        true = Exp.crefEqual(cr, cr2);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e2, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s2,", &",s1,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,(e2 as DAE.CREF(componentRef = cr2)),cg_id)
      equation
        true = Exp.crefEqual(cr, cr2);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s1,", &",s2,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,e2,cg_id) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e2);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s1,", &",s2,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,e2,cg_id) /* e1 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e2, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s2,", &",s1,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,e2,_)
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s3 = Exp.printComponentRefStr(cr);
        s4 = Exp.printComponentRefStr(eltcr);
        s = Util.stringAppendList({"generate_single_array_eqn_code2(",s3,", ",s4,", ",s1,", ",s2,") failed\n"});
        print(s);
      then
        fail();
  end matchcontinue;
end generateSingleArrayEqnCode2;

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

protected function generateOdeSystem2NonlinearResiduals "function: generateOdeSystem2NonlinearResiduals
  author: PA

  Generates residual statements for nonlinear equation systems.
"
	input Boolean mixedEvent "true if inside mixed system event code";
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input list<DAELow.Equation> inDAELowEquationLst;
  input DAELow.MultiDimEquation[:] multiDimEqnLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (mixedEvent,inExpComponentRefLst,inDAELowEquationLst,multiDimEqnLst,inInteger)
    local
      VarTransform.VariableReplacements repl;
      Codegen.CFunction s1,res_func,func,f2,f3,f4,f1,f5,res;
      Integer cg_id1,id,eqn_size,cg_id2,cg_id3,cg_id4,cg_id;
      String str_id,size_str,func_name,start_stmt,end_stmt;
      list<Exp.ComponentRef> crs;
      list<DAELow.Equation> eqns;
      DAELow.MultiDimEquation[:] aeqns;
    case (mixedEvent,crs,eqns,aeqns,cg_id) /* cg var_id solve code cg var_id extra functions: residual func */
      equation
        repl = makeResidualReplacements(crs);
        (s1,cg_id1) = generateOdeSystem2NonlinearResiduals2(eqns, aeqns, 0, repl, cg_id);
        id = tick();
        str_id = intString(id);
        eqn_size = listLength(eqns);
        size_str = intString(eqn_size);
        func_name = stringAppend("residualFunc", str_id);
        res_func = Codegen.cMakeFunction("void", func_name, {},
          {"int *n","double* xloc","double* res","int* iflag"});
        func = Codegen.cMergeFns({res_func,s1});
        func = addMemoryManagement(func);
        (f2,cg_id2) = generateOdeSystem2NonlinearSetvector(crs, 0, cg_id1);
        (f3,cg_id3) = generateOdeSystem2NonlinearCall(mixedEvent,str_id, cg_id2);
        (f4,cg_id4) = generateOdeSystem2NonlinearStoreResults(crs, 0, cg_id3);
        start_stmt = Util.stringAppendList({"start_nonlinear_system(",size_str,");"});
        end_stmt = "end_nonlinear_system();";
        f1 = Codegen.cAddStatements(Codegen.cEmptyFunction, {start_stmt});
        f5 = Codegen.cAddStatements(Codegen.cEmptyFunction, {end_stmt});
        res = Codegen.cMergeFns({f1,f2,f3,f4,f5});
      then
        (res,cg_id4,{func});
    case (_,_,_,_,_)
      equation
        print("generate_ode_system2_nonlinear_residuals failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2NonlinearResiduals;

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

protected function generateOdeSystem2NonlinearSetvector "function: generateOdeSystem2NonlinearSetvector
  author: PA

  Generates code for setting the values for the x vector when solving
  nonlinear equation systems.
"
  input list<Exp.ComponentRef> inExpComponentRefLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inExpComponentRefLst1,inInteger2,inInteger3)
    local
      Integer cg_id,indx_1,cg_id_1,indx;
      String cr_str,indx_str,stmt,stmt2;
      Codegen.CFunction func,func_1;
      Exp.ComponentRef cr;
      list<Exp.ComponentRef> crs;
    case ({},_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* index iterator cg var_id cg var_id */
    case ((cr :: crs),indx,cg_id)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (func,cg_id_1) = generateOdeSystem2NonlinearSetvector(crs, indx_1, cg_id);
        stmt = Util.stringAppendList({"nls_x[",indx_str,"] = extraPolate(",cr_str,");"});
        stmt2 = Util.stringAppendList({"nls_xold[",indx_str,"] = old(&",cr_str,");"});
        func_1 = Codegen.cAddStatements(func, {stmt,stmt2});
      then
        (func_1,cg_id_1);

    case(_,_,_) equation
      print("generateOdeSystem2NonlinearSetvector failed\n");
      then fail();
  end matchcontinue;
end generateOdeSystem2NonlinearSetvector;

protected function generateOdeSystem2NonlinearCall "function: generateOdeSystem2NonlinearCall
  author: PA

  Generates the call to the nonlinear equation solver.
"
  input Boolean mixedEvent "true if inside mixed system event code";
  input String inString;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (mixedEvent,outCFunction,outInteger):=
  matchcontinue (mixedEvent,inString,inInteger)
    local
      String stmt,func_id;
      Codegen.CFunction func;
      Integer cg_id;
      // Not mixed system event code
    case (false,func_id,cg_id) /* residual func id cg var_id cg var_id */
      equation
        stmt = Util.stringAppendList(
          {"solve_nonlinear_system(residualFunc",func_id,", ",func_id,");"});
        func = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (func,cg_id);

        // Mixed system event code.
    case (true,func_id,cg_id) /* residual func id cg var_id cg var_id */
      equation
         stmt = Util.stringAppendList(
          {"solve_nonlinear_system_mixed(residualFunc",func_id,", ",func_id,");"});
        func = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (func,cg_id);
  end matchcontinue;
end generateOdeSystem2NonlinearCall;

protected function generateOdeSystem2NonlinearStoreResults "function: generateOdeSystem2NonlinearStoreResults
  author: PA

  Generates the storing of the results of the solution to a nonlinear equation
  system.
"
  input list<Exp.ComponentRef> inExpComponentRefLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inExpComponentRefLst1,inInteger2,inInteger3)
    local
      Integer cg_id,indx_1,cg_id_1,indx;
      String cr_str,indx_str,stmt;
      Codegen.CFunction func,func_1;
      Exp.ComponentRef cr;
      list<Exp.ComponentRef> crs;
    case ({},_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* indx cg var_id cg var_id */
    case ((cr :: crs),indx,cg_id)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (func,cg_id_1) = generateOdeSystem2NonlinearStoreResults(crs, indx_1, cg_id);
        stmt = Util.stringAppendList({cr_str," = nls_x[",indx_str,"];"});
        func_1 = Codegen.cAddStatements(func, {stmt});
      then
        (func_1,cg_id_1);
    case (_,_,_) equation
      print("-generateOdeSystem2NonlinearStoreResults failed\n");
      then fail();
  end matchcontinue;
end generateOdeSystem2NonlinearStoreResults;

protected function generateOdeSystem2NonlinearResiduals2 "function: generateOdeSystem2NonlinearResiduals2
  author: PA

  Helper function to generate_ode_system2_nonlinear_residuals
"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input DAELow.MultiDimEquation[:] arrayEqnLst;
  input Integer inInteger2;
  input VarTransform.VariableReplacements inVariableReplacements3;
  input Integer inInteger4;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowEquationLst1,arrayEqnLst,inInteger2,inVariableReplacements3,inInteger4)
    local
      Integer cg_id,cg_id_1,indx_1,cg_id_2,indx,aindx;
      Exp.Type tp;
      Exp.Exp res_exp,res_exp_1,res_exp_2,e1,e2,e;
      Codegen.CFunction exp_func,cfunc,exp_func_1,cfunc_1,cfunc_2;
      String var,indx_str,stmt;
      list<DAELow.Equation> rest,rest2;
      DAELow.MultiDimEquation[:] aeqns;
      VarTransform.VariableReplacements repl;
    case ({},_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* index iterator cg var_id cg var_id */
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),aeqns,indx,repl,cg_id)
      equation
        tp = Exp.typeof(e1);
        res_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        res_exp_1 = Exp.simplify(res_exp);
        res_exp_2 = VarTransform.replaceExp(res_exp_1, repl, SOME(skipPreOperator));
        (exp_func,var,cg_id_1) = Codegen.generateExpression(res_exp_2, cg_id, Codegen.simContext);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (cfunc,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest, aeqns,indx_1, repl, cg_id_1);
        stmt = Util.stringAppendList({TAB,"res[",indx_str,"] = ",var,";"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: rest),aeqns,indx,repl,cg_id)
      equation
        res_exp_1 = Exp.simplify(e);
        res_exp_2 = VarTransform.replaceExp(res_exp_1, repl, SOME(skipPreOperator));
        (exp_func,var,cg_id_1) = Codegen.generateExpression(res_exp_2, cg_id, Codegen.simContext);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (cfunc,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest, aeqns,indx_1, repl, cg_id_1);
        stmt = Util.stringAppendList({TAB,"res[",indx_str,"] = ",var,";"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);

        /* An array equation */
    case (rest as DAELow.ARRAY_EQUATION(aindx,_) :: _,aeqns,indx,repl,cg_id)
      equation
        (cfunc_1,cg_id_1,rest2,indx_1) = generateOdeSystem2NonlinearResidualsArrayEqn(aindx,rest,aeqns,indx,repl,cg_id);
        (cfunc_2,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest2, aeqns,indx_1, repl, cg_id_1);
        cfunc = Codegen.cMergeFns({cfunc_1,cfunc_2});
      then (cfunc,cg_id_2);
  end matchcontinue;
end generateOdeSystem2NonlinearResiduals2;

protected function generateOdeSystem2NonlinearResidualsArrayEqn
" Generates residual calculations for an array equation

An array equation has several nodes in the equation list. Traverse the list and remove
all with the same index."

  input Integer arrayIndex "the current array index";
  input list<DAELow.Equation> allEquations;
  input DAELow.MultiDimEquation[:] arrayEquations;
	input Integer residualIndex "index in residual vector";
	input VarTransform.VariableReplacements repl;
	input Integer cg_id;
  output CFunction outCFunction;
  output Integer outCg_id;
  output list<DAELow.Equation> updatedAllEquations;
  output Integer nextResidualIndex;

algorithm
  (outCFunction,outCg_id,updatedAllEquations,nextResidualIndex)
  	:= matchcontinue(arrayIndex,allEquations,arrayEquations,residualIndex,repl,cg_id)
  	local list<Integer> ds; Exp.Exp e1,e2,e1_1,e2_1;
  	  case (arrayIndex,allEquations,arrayEquations,residualIndex,repl,cg_id)
  	    equation
  	        updatedAllEquations = removeArrayEquationIndex(allEquations,arrayIndex);
  	         DAELow.MULTIDIM_EQUATION(ds,e1,e2) = arrayEquations[arrayIndex + 1];
  	         e1_1 = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
  	         e2_1 = VarTransform.replaceExp(e2, repl, SOME(skipPreOperator));
  	         (outCFunction,outCg_id) = generateOdeSystem2NonlinearResidualsArrayEqn2(residualIndex,e1_1,e2_1,cg_id);
  	         nextResidualIndex = residualIndex + Util.listReduce(ds,intMul);
  	      then (outCFunction,outCg_id,updatedAllEquations,nextResidualIndex);
  end matchcontinue;
end generateOdeSystem2NonlinearResidualsArrayEqn;

protected function generateOdeSystem2NonlinearResidualsArrayEqn2 "
Generates the residual calculation for an array equation.
For example v = foo(...)
generates code (on pseudo form): res[index] = v - foo(...);

This assumes that all variables of the array equation are part of the residual and follows in the
same order in the residual.
"
	input Integer indx;
  input Exp.Exp leftExp;
  input Exp.Exp rightExp;
  input Integer cg_in;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out):=
  matchcontinue (indx,leftExp,rightExp,cg_in)
    local
      String s1,s2,stmt,s3,s4,s,indxStr;
      Codegen.CFunction cfunc,cfunc1,cfunc2,cfunc3;
      Integer cg_id_1,cg_id,cg_id_2;
      Exp.ComponentRef cr,eltcr,cr2;
      Exp.Exp e1,e2;
    case (indx,e1 ,e2,cg_id)
      equation
        (cfunc1,s1,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
				(cfunc2,s2,cg_id_2) = Codegen.generateExpression(e2, cg_id_1, Codegen.simContext);
        cfunc = Codegen.cMergeFns({cfunc1,cfunc2});
        indxStr = intString(indx);
        stmt = Util.stringAppendList({"sub_real_array_data_mem(&",s1,", &",s2,", &res[",indxStr,"]);"});
        cfunc3 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (cfunc3,cg_id_2);
  end matchcontinue;
end generateOdeSystem2NonlinearResidualsArrayEqn2;


protected function removeArrayEquationIndex "removes all array equations with index equal to arrayIndex"
  input list<DAELow.Equation> eqns;
  input Integer arrayIndex;
  output list<DAELow.Equation> outEqns;
algorithm
  outEqns := matchcontinue(eqns,arrayIndex)
    local Integer index;
      DAELow.Equation e;
      list<DAELow.Equation> rest,res;
    case ({},_) then {};
    case (DAELow.ARRAY_EQUATION(index,_)::rest,arrayIndex) equation
      equality(index = arrayIndex);
      then removeArrayEquationIndex(rest,arrayIndex);
    case (e::rest,arrayIndex) equation
      res = removeArrayEquationIndex(rest,arrayIndex);
    then e::res;
  end matchcontinue;
end removeArrayEquationIndex;

protected function removeAlgorithmIndex "removes all algorithm 'equation':s with index equal to algIndex"
  input list<DAELow.Equation> eqns;
  input Integer algIndex;
  output list<DAELow.Equation> outEqns;
algorithm
  outEqns := matchcontinue(eqns,algIndex)
    local Integer index;
      DAELow.Equation e;
      list<DAELow.Equation> rest,res;
    case ({},_) then {};
    case (DAELow.ALGORITHM(index,_,_)::rest,algIndex) equation
      equality(index = algIndex);
      then removeAlgorithmIndex(rest,algIndex);
    case (e::rest,algIndex) equation
      res = removeAlgorithmIndex(rest,algIndex);
    then e::res;
  end matchcontinue;
end removeAlgorithmIndex;

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

protected function generateOdeSystem2Declaration "function: generateOdeSystem2Declaration
  author: PA

  Generates code for the declaration of A and b when
  solving linear systems of equations.
  inputs: (size: int, unique_id: int)
  outputs: (fcn : CFunction)
"
	input Boolean mixedEvent;
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inInteger1,inInteger2,inInteger3)
    local
      String size_str,id_str,stmt1,stmt2;
      Codegen.CFunction res;
      Integer size,unique_id,cg_id;
    case (mixedEvent,size,unique_id,cg_id) /* size unique_id cg var_id cg var_id */
      equation
        size_str = intString(size);
        id_str = intString(unique_id);
        stmt1 = Util.stringAppendList({"declare_matrix(A",id_str,",",size_str,",",size_str,");"});
        stmt2 = Util.stringAppendList({"declare_vector(b",id_str,",",size_str,");"});
        res = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt1,stmt2});
      then
        (res,cg_id);
    case (mixedEvent,size,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2Declaration failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2Declaration;

protected function generateOdeSystem2Cleanup "
  Generates code for the cleanups (delete) of A and b when
  solving linear systems of equations.
  inputs: (size: int, unique_id: int)
  outputs: (fcn : CFunction)
"
	input Boolean mixedEvent;
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inInteger1,inInteger2,inInteger3)
    local
      String size_str,id_str,stmt1,stmt2;
      Codegen.CFunction res;
      Integer size,unique_id,cg_id;
    case (mixedEvent,size,unique_id,cg_id) /* size unique_id cg var_id cg var_id */
      equation
        size_str = intString(size);
        id_str = intString(unique_id);
        stmt1 = Util.stringAppendList({"free_matrix(A",id_str,");"});
        stmt2 = Util.stringAppendList({"free_vector(b",id_str,");"});
        res = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt1,stmt2});
      then
        (res,cg_id);
    case (mixedEvent,size,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2Cleanup failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2Cleanup;

protected function generateOdeSystem2PopulateAb "function: generateOdeSystem2PopulateAb
  author: PA

  Generates code for the population of A and b when
  solving linear system of equations.
  inputs: ( jac : (int  int  DAELow.Equation) list,
            vars: DAELow.Variables,
  	      eqns: DAELow.EquationArray
 	      unique_id : int)
  outputs: cfn : CFunction
"
	input Boolean mixedEvent;
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5)
    local
      Codegen.CFunction s1,s2,res;
      Integer cg_id1,cg_id2,unique_id,cg_id;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
    case (mixedEvent,jac,vars,eqns,unique_id,cg_id) /* unique_id cg var_id cg var_id */
      equation
        (s1,cg_id1) = generateOdeSystem2PopulateA(jac, vars, eqns, unique_id, cg_id);
        (s2,cg_id2) = generateOdeSystem2PopulateB(jac, vars, eqns, unique_id, cg_id1);
        res = Codegen.cMergeFns({s1,s2});
      then
        (res,cg_id2);
    case (mixedEvent,jac,vars,eqns,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateAb failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateAb;

protected function generateOdeSystem2PopulateA "function: generateOdeSystem2PopulateA
  author: PA

  Generates code for the population of A
  solving linear system of equations.
  inputs ( jac : (int  int  DAELow.Equation) list,
            vars: DAELow.Variables,
  	      eqns: DAELow.EquationArray
 	      unique_id : int
 	      cg_var_id : int)
  outputs: (cfn : CFunction
 	      cg_var_id : int)
"
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5)
    local
      Integer n_rows,cg_id,unique_id;
      Codegen.CFunction res;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
    case (jac,vars,eqns,unique_id,cg_id)
      equation
        n_rows = DAELow.equationSize(eqns);
        (res,cg_id) = generateOdeSystem2PopulateA2(jac, vars, eqns, n_rows, unique_id, cg_id);
      then
        (res,cg_id);
    case (jac,vars,eqns,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateA failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateA;

protected function generateOdeSystem2PopulateA2 "function: generateOdeSystem2PopulateA2
  author: PA

  Helper function to generate_ode_system2_populate_A
"
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5,inInteger6)
    local
      Integer unique_id,cg_id,r_1,c_1,cg_id_1,cg_id_2,r,c,n_rows;
      String rs,rc,n_rows_str,id_str,var,stmt;
      Codegen.CFunction cfunc1,cfunc,cfunc1_1,cfunc_1;
      Exp.Exp exp;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqn;
    case ({},_,_,_,unique_id,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* n rows unique_id cg var_id cg var_id */
    case (((r,c,DAELow.RESIDUAL_EQUATION(exp = exp)) :: jac),vars,eqn,n_rows,unique_id,cg_id)
      equation
        r_1 = r - 1;
        c_1 = c - 1;
        rs = intString(r_1);
        rc = intString(c_1);
        n_rows_str = intString(n_rows);
        id_str = intString(unique_id);
        (cfunc1,var,cg_id_1) = Codegen.generateExpression(exp, cg_id, Codegen.simContext);
        (cfunc,cg_id_2) = generateOdeSystem2PopulateA(jac, vars, eqn, unique_id, cg_id_1);
        stmt = Util.stringAppendList(
          {"set_matrix_elt(A",id_str,",",rs,", ",rc,", ",n_rows_str,
          ", ",var,");"});
        cfunc1_1 = Codegen.cAddStatements(cfunc1, {stmt});
        cfunc_1 = Codegen.cMergeFns({cfunc1_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateA2 failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateA2;

protected function generateOdeSystem2PopulateB "function: generateOdeSystem2PopulateB
  author: PA

  Generates code for the population of b
  solving linear system of equations.
"
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5)
    local
      list<DAELow.Equation> eqn_lst;
      Codegen.CFunction res;
      Integer cg_id_1,unique_id,cg_id;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
    case (jac,vars,eqns,unique_id,cg_id) /* unique_id cg var_id cg var_id */
      equation
        eqn_lst = DAELow.equationList(eqns);
        (res,cg_id_1) = generateOdeSystem2PopulateB2(eqn_lst, vars, 0, unique_id, cg_id);
      then
        (res,cg_id_1);
    case (jac,vars,eqns,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateB2 failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateB;

protected function generateOdeSystem2PopulateB2 "function: generateOdeSystem2PopulateB2
  author: PA
  Helper function to generate_ode_system2_populate_b
"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowEquationLst1,inVariables2,inInteger3,inInteger4,inInteger5)
    local
      Integer cg_id,cg_id_1,index_1,cg_id_2,index,unique_id;
      Exp.Type tp;
      Exp.Exp new_exp,rhs_exp,rhs_exp_1,rhs_exp_2,e1,e2,res_exp;
      Codegen.CFunction exp_func,cfunc,exp_func_1,cfunc_1;
      String var,index_str,id_str,stmt;
      list<DAELow.Equation> rest;
      DAELow.Variables v;
    case ({},_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* index iterator unique_id cg var_id cg var_id */
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),v,index,unique_id,cg_id)
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = DAELow.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = DAE.UNARY(DAE.UMINUS(tp),rhs_exp);
        rhs_exp_2 = Exp.simplify(rhs_exp_1);
        (exp_func,var,cg_id_1) = Codegen.generateExpression(rhs_exp_2, cg_id, Codegen.simContext);
        index_str = intString(index);
        id_str = intString(unique_id);
        index_1 = index + 1;
        (cfunc,cg_id_2) = generateOdeSystem2PopulateB2(rest, v, index_1, unique_id, cg_id_1);
        stmt = Util.stringAppendList({"set_vector_elt(b",id_str,",",index_str,", ",var,");"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case ((DAELow.RESIDUAL_EQUATION(exp = res_exp) :: rest),v,index,unique_id,cg_id)
      equation
        rhs_exp = DAELow.getEqnsysRhsExp(res_exp, v);
        rhs_exp_1 = Exp.simplify(rhs_exp);
        (exp_func,var,cg_id_1) = Codegen.generateExpression(rhs_exp_1, cg_id, Codegen.simContext);
        index_str = intString(index);
        id_str = intString(unique_id);
        index_1 = index + 1;
        (cfunc,cg_id_2) = generateOdeSystem2PopulateB2(rest, v, index_1, unique_id, cg_id_1);
        stmt = Util.stringAppendList({"set_vector_elt(b",id_str,",",index_str,", ",var,");"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),v,index,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateB2 failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateB2;

protected function generateOdeSystem2SolveCall "function: generateOdeSystem2SolveCall
  author: PA

  Generates code for the call, including setup, for solving
  a linear system of equations.
"
	input Boolean mixedEvent;
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inInteger1,inInteger2,inInteger3)
    local
      String size_str,id_str,stmt,mixed_str;
      Codegen.CFunction cfunc;
      Integer eqn_size,unique_id,cg_id;
    case (mixedEvent,eqn_size,unique_id,cg_id) /* size of system unique_id cg var_id cg var_id */
      equation
        size_str = intString(eqn_size);
        id_str = intString(unique_id);
        mixed_str = Util.if_(mixedEvent,"_mixed","");
        stmt = Util.stringAppendList(
          {"solve_linear_equation_system",mixed_str,"(A",id_str,",b",id_str,",",
          size_str,",",id_str,");"});
        cfunc = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (cfunc,cg_id);
  end matchcontinue;
end generateOdeSystem2SolveCall;

protected function generateOdeSystem2CollectResults "function: generateOdeSystem2CollectResults
  author: PA

  Generates the code for storing the result of solving
  a linear system of equations into the affected variables .
"
	input Boolean mixedEvent;
  input DAELow.Variables inVariables1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inVariables1,inInteger2,inInteger3)
    local
      list<DAELow.Var> var_lst,var_lst_1;
      list<Exp.ComponentRef> crefs;
      list<String> strs;
      Codegen.CFunction res;
      DAELow.Variables vars;
      Integer unique_id,cg_id;
    case (mixedEvent,vars,unique_id,cg_id) /* unique_id cg var_id cg var_id */
      equation
        var_lst = DAELow.varList(vars);
        var_lst_1 = listReverse(var_lst);
        crefs = Util.listMap(var_lst, DAELow.varCref);
        strs = Util.listMap(crefs, Exp.printComponentRefStr);
        res = generateOdeSystem2CollectResults2(strs, 0, unique_id);
      then
        (res,cg_id);
    case (mixedEvent,vars,unique_id,cg_id)
      equation
        Debug.fprint("failtrace",
          "generateOdeSystem2CollectResults failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2CollectResults;

protected function generateOdeSystem2CollectResults2 "function: generateOdeSystem2CollectResults2
  author: PA

  Helper function to generate_ode_system2_collect_results
"
  input list<String> inStringLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
algorithm
  outCFunction:=
  matchcontinue (inStringLst1,inInteger2,inInteger3)
    local
      Integer index_1,index,unique_id;
      Codegen.CFunction cfunc,cfunc_1;
      String index_str,id_str,stmt,str;
      list<String> strs;
    case ({},_,_) then Codegen.cEmptyFunction;  /* indx inique_id */
    case ((str :: strs),index,unique_id)
      equation
        index_1 = index + 1;
        cfunc = generateOdeSystem2CollectResults2(strs, index_1, unique_id);
        index_str = intString(index);
        id_str = intString(unique_id);
        stmt = Util.stringAppendList({str," = get_vector_elt(b",id_str,",",index_str,");"});
        cfunc_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        cfunc_1;
  end matchcontinue;
end generateOdeSystem2CollectResults2;

protected function transformXToXd "function transformXToXd
  author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)
"
  input DAELow.Var inVar;
  output DAELow.Var outVar;
algorithm
  outVar:=
  matchcontinue (inVar)
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
      
    case (DAELow.VAR(varName = cr,
                     varKind = DAELow.STATE(),
                     varDirection = dir,
                     varType = tp,
                     bindExp = exp,
                     bindValue = v,
                     arryDim = dim,
                     index = index,
                     origVarName = name,
                     className = classes,
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
        DAELow.VAR(DAE.CREF_IDENT(res,DAE.ET_REAL(),{}),DAELow.STATE(),dir,tp,exp,v,dim,index,cr,classes,attr,comment,flowPrefix,streamPrefix);
        
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
        Debug.fprintln("failtrace", "SimCodegen.getEquationAndSolvedVar failed at index: " +& intString(e));
      then
        fail();        
  end matchcontinue;
end getEquationAndSolvedVar;

protected function isNonState "function: isNonState
  failes if the given variable kind is state
"
  input DAELow.VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    case (DAELow.VARIABLE()) then ();
    case (DAELow.DUMMY_DER()) then ();
    case (DAELow.DUMMY_STATE()) then ();
    case (DAELow.DISCRETE()) then ();
  end matchcontinue;
end isNonState;

protected function generateOdeEquation "function: generateOdeEquation
  author: PA

   Generates code for a single equation for the ode code generation, see
  genrerate_ode_code.
"
	input Boolean genDiscrete "if true generate discrete equations";
  input DAELow.DAELow inDAELow1;
 input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inInteger4,inInteger5)
    local
      Exp.Exp e1,e2,varexp,expr;
      DAELow.Var v;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
      Integer e,cg_id,cg_id_1,indx;
      Exp.ComponentRef cr,origname,cr_1;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Codegen.CFunction exp_func,res,cfunc;
      String var,cr_str,stmt,indxs,name,c_name,id,s1,s2,s;
      DAELow.Equation eqn;
      DAELow.MultiDimEquation[:] ae;
      list<CFunction> f1;
      Algorithm.Algorithm alg;
      
    /*discrete equations not considered if event-code is produced */
    case (false,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        true = useZerocrossing();
        (DAELow.EQUATION(e1,e2),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
        true = hasDiscreteVar({v});
      then
        (Codegen.cEmptyFunction,cg_id,{});
        
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        (DAELow.EQUATION(e1,e2),(v as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = 
        getEquationAndSolvedVar(e, eqns, vars, ass2) "Solving for non-states" ;
        isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_1) = 
        Codegen.generateExpression(expr, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
        cr_str = Exp.printComponentRefStr(cr);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        res = Codegen.cAddStatements(exp_func, {stmt});
      then
        (res,cg_id_1,{});
        
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        (DAELow.EQUATION(e1,e2),DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))
        = getEquationAndSolvedVar(e, eqns, vars, ass2) "Solving the state s means solving for der(s)" ;
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr);
        // c_name = Util.modelicaStringToCStr(name,true);
        // id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        id = Util.stringAppendList({DAELow.derivativeNamePrefix, name});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_1) = 
        Codegen.generateExpression(expr, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
        cr_str = Exp.printComponentRefStr(cr_1);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        res = Codegen.cAddStatements(exp_func, {stmt});
      then
        (res,cg_id_1,{});

    /* state nonlinear */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns,arrayEqs = ae),ass1,ass2,e,cg_id)
      equation
        ((eqn as DAELow.EQUATION(e1,e2)),DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) = 
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        c_name = name; // Util.modelicaStringToCStr(name,true);
        id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        (res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr_1}, {eqn},ae, cg_id);
      then
        (res,cg_id_1,f1);

    /* non-state non-linear */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns,arrayEqs = ae),ass1,ass2,e,cg_id)
      equation
        ((eqn as DAELow.EQUATION(e1,e2)),DAELow.VAR(cr,kind,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) = 
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        isNonState(kind);
        indxs = intString(indx);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        (res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr}, {eqn},ae, cg_id);
      then
        (res,cg_id_1,f1);

    /* When equations ignored */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        (DAELow.WHEN_EQUATION(_),_) = getEquationAndSolvedVar(e, eqns, vars, ass2);
      then
        (Codegen.cEmptyFunction,cg_id,{});

    /* Algorithm for single variable. */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars, orderedEqs = eqns,algorithms=alg),ass1,ass2,e,cg_id)
      local
        Integer indx;
        list<Exp.Exp> algInputs,algOutputs;
        DAELow.Var v;
        Exp.ComponentRef varOutput;
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
				// The output variable of the algorithm must be the variable solved for, otherwise we need to
				// solve an inverse problem of an algorithm section.
        true = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        (cfunc,cg_id_1) = 
        Codegen.generateAlgorithm(DAE.ALGORITHM(alg), cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
      then (cfunc,cg_id_1,{});

    /* inverse Algorithm for single variable . */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars, orderedEqs = eqns,algorithms=alg),ass1,ass2,e,cg_id)
      local
        Integer indx;
        list<Exp.Exp> algInputs,algOutputs;
        DAELow.Var v;
        Exp.ComponentRef varOutput;
        String algStr,message;
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
				// We need to solve an inverse problem of an algorithm section.
        false = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg)});
        message = Util.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();

    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-SimCodegen.generateOdeEquation failed\n");
        (eqn,DAELow.VAR(varName=cr,index=indx,
                        origVarName=origname,
                        values=dae_var_attr,
                        comment=comment,
                        flowPrefix=flowPrefix,
                        streamPrefix=streamPrefix)) = getEquationAndSolvedVar(e, eqns, vars, ass2);
        s1 = DAELow.equationStr(eqn);
        s2 = Exp.printComponentRefStr(cr);
        s = Util.stringAppendList({"trying to solve ",s2," from eqn: ",s1,"\n"});
        Debug.fprint("failtrace", s);
      then
        fail();
        
  end matchcontinue;
end generateOdeEquation;

public function generateFunctions 
"function generateFunctions
  Finds the called functions in daelow and generates code for them from 
  the given DAE. Hence, the functions must exist in the DAE.Element list."
  input SCode.Program inProgram;
  input DAE.DAElist inDAElist;
  input DAELow.DAELow inDAELow;
  input Absyn.Path inPath;
  input String inString;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inProgram,inDAElist,inDAELow,inPath,inString)
    local
      list<Absyn.Path> funcpaths, fnrefs, fnpaths, fns;
      list<String> debugpathstrs,libs1,libs2,includes;
      String debugpathstr,debugstr,filename;
      list<DAE.Element> funcelems,elements;
      list<SCode.Class> p;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Absyn.Path path;
    case (p,(dae as DAE.DAE(elementLst = elements)),dlow,path,filename) /* Needed to instantiate functions libs */
      equation
        funcpaths = getCalledFunctions(dae, dlow);
        //fnrefs = getReferencedFunctions(dae, dlow); // For function arguments - stefan
        //fnpaths = listAppend(funcpaths, fnrefs);
        //fns = removeDuplicatePaths(fnpaths);
        Debug.fprint("info", "Found called functions: ") "debug" ;
        debugpathstrs = Util.listMap(funcpaths, Absyn.pathString) "debug" ;
        debugpathstr = Util.stringDelimitList(debugpathstrs, ", ") "debug" ;
        Debug.fprintln("info", debugpathstr) "debug" ;
        funcelems = generateFunctions2(p, funcpaths);
        debugstr = Print.getString();
        Print.clearBuf();
        Debug.fprintln("info", "Generating functions, call Codegen.\n") "debug" ;
				(_,libs1) = generateExternalObjectIncludes(dlow);
        libs2 = Codegen.generateFunctions(DAE.DAE(funcelems),{});
        Print.writeBuf(filename);
      then
        Util.listUnion(libs1,libs2);
    case (_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Code generation of Modelica functions failed. "});
      then
        fail();
  end matchcontinue;
end generateFunctions;

protected function generateExternalObjectIncludes 
"Generates the library paths for external objects"
	input DAELow.DAELow daelow;
  output list<String> includes;
	output list<String> libs;
algorithm
  (includes,libs) := matchcontinue (daelow)
    case DAELow.DAELOW(extObjClasses = extObjs)
    local list<list<String>> libsL,includesL;
      DAELow.ExternalObjectClasses extObjs;
      equation
        (includesL,libsL) = Util.listMap_2(extObjs,generateExternalObjectInclude);
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
  (includes,libs) := matchcontinue(extObjCls)
    case (DAELow.EXTOBJCLASS(constructor=DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl=DAE.EXTERNALDECL(language=ann1))}),
      											destructor=DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl=DAE.EXTERNALDECL(language=ann2))})))
      local Option<Absyn.Annotation> ann1,ann2;
        list<String> includes1,libs1,includes2,libs2;
      equation
        (includes1,libs1) = Codegen.generateExtFunctionIncludes(ann1);
        (includes2,libs2) = Codegen.generateExtFunctionIncludes(ann2);
        includes = Util.listListUnion({includes1,includes2});
        libs = Util.listListUnion({libs1,libs2});
      then (includes,libs);
  end matchcontinue;
end generateExternalObjectInclude;

public function generateFunctions2 
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
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<DAE.Element> elts,res;
      list<SCode.Class> p;
      Absyn.Path path;
      DAE.ExternalDecl extdecl;
      DAE.InlineType inl;
      Boolean partialPrefix;
      String s;
      
    case (_,{},allpaths) then {};  /* iterated over complete list */
      
    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InstanceHierarchy.emptyInstanceHierarchy, p, path);
        DAE.DAE(elementLst = {DAE.FUNCTION(functions = 
          DAE.FUNCTION_DEF(dae)::_,type_ = t,partialPrefix = partialPrefix,inlineType=inl)}) = fdae;
        patched_dae = DAE.DAE({DAE.FUNCTION(path,{DAE.FUNCTION_DEF(dae)},t,partialPrefix,inl)});
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.FUNCTION(path,{DAE.FUNCTION_DEF(dae)},t,partialPrefix,inl)});
      then
        res;
        
    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InstanceHierarchy.emptyInstanceHierarchy, p, path);
        DAE.DAE(elementLst = {DAE.FUNCTION(functions=
          DAE.FUNCTION_EXT(dae,extdecl)::_,type_ = t,partialPrefix = partialPrefix,inlineType=inl)}) = fdae;
        patched_dae = DAE.DAE({DAE.FUNCTION(path,{DAE.FUNCTION_EXT(dae,extdecl)},t,partialPrefix,inl)});
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.FUNCTION(path,{DAE.FUNCTION_EXT(dae,extdecl)},t,partialPrefix,inl)});
      then
        res;
        
    case (_,(path :: paths),_)
      equation
        s = Absyn.pathString(path);
        s = "SimCodegen.generateFunctions3 failed: " +& s +& "\n";
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

public function generateInitData 
"function generateInitData
  This function generates initial values for the 
  simulation by investigating values of variables."
  input DAELow.DAELow inDAELow1;
  input Absyn.Path inPath2;
  input String inString3;
  input String inString4;
  input Real inReal5;
  input Real inReal6;
  input Real inReal7;
  input Real inTolerance;
  input String method;
  input String options;
algorithm
  _ := matchcontinue (inDAELow1,inPath2,inString3,inString4,inReal5,inReal6,inReal7,inTolerance,method,options)
    local
      Real delta_time,step,start,stop,intervals,tolerance;
      String start_str,stop_str,step_str,tolerance_str,nx_str,ny_str,np_str,init_str,str,exe,filename;
      String ny_str,np_str,npstring_str,nystring_str;
      Integer nx,ny,np,npstring,nystring;
      DAELow.DAELow dlow;
      Absyn.Path class_;
      
    case (dlow,class_,exe,filename,start,stop,intervals,tolerance,method,_) /* classname executable file name filename start time stop time intervals */
      equation
        delta_time = stop -. start;
        step = delta_time/.intervals;
        start_str = realString(start);
        stop_str = realString(stop);
        step_str = realString(step);
        tolerance_str = realString(tolerance);
        (nx,ny,np,_,_,nystring,npstring) = DAELow.calculateSizes(dlow);
        nx_str = intString(nx);
        ny_str = intString(ny);
        np_str = intString(np);
        npstring_str = intString(npstring);
        nystring_str = intString(nystring);
        init_str = generateInitData2(dlow, nx, ny, np, nystring, npstring);
        str = Util.stringAppendList({
          start_str," // start value\n",
          stop_str," // stop value\n",
          step_str," // step value\n",
          tolerance_str, " // tolerance\n",
          "\"",method,"\" // method\n",
          nx_str," // n states\n",
          ny_str," // n alg vars\n",
          np_str," //n parameters\n",
          npstring_str," // n string-parameters\n",
          nystring_str," // n string variables\n",
          init_str});
        System.writeFile(filename, str);
      then
        ();
        
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        print("-SimCodegen.generateInitData failed\n");
      then
        fail();
        
  end matchcontinue;
end generateInitData;

protected function generateInitData2 
"function: generateInitData2
  Helper function to generateInitData
  Generates init data for states, variables and parameters.
  nx - number of states.
  ny - number of alg. vars.
  np - number of parameters."
  input DAELow.DAELow inDAELow1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer ny_string;
  input Integer np_string;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow1,inInteger2,inInteger3,inInteger4,ny_string,np_string)
    local
      list<DAELow.Var> var_lst,knvar_lst;
      String[:] nxarr,nxdarr,nyarr,nparr,nxarr1,nxdarr1,nyarr1,nparr1,nxarr2,nxdarr2,nyarr2,nparr2,nxarr3,nxdarr3,nyarr3,nparr3;
      String[:] nystrarr,npstrarr;
      list<String> nx_lst,nxd_lst,ny_lst,np_lst,whole_lst,nystr_lst,npstr_lst;
      String res;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray initeqn;
      Algorithm.Algorithm[:] alg;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,initialEqs = initeqn,algorithms = alg),nx,ny,np,ny_string,np_string)
      equation
        var_lst = DAELow.varList(vars);
        knvar_lst = DAELow.varList(knvars);
        nxarr = fill("", nx);
        nxdarr = fill("0.0", nx);
        nyarr = fill("", ny);
        nparr = fill("", np);
        nystrarr = fill("\"\"",ny_string);
        npstrarr = fill("\"\"",np_string);
        (nxarr1,nxdarr1,nyarr1,nparr1,nystrarr,npstrarr) = generateInitData3(var_lst, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
        (nxarr2,nxdarr2,nyarr2,nparr2,nystrarr,npstrarr) = generateInitData3(knvar_lst, nxarr1, nxdarr1, nyarr1, nparr1,nystrarr,npstrarr);
        (nxarr3,nxdarr3,nyarr3,nparr3,nystrarr,npstrarr) = generateInitData4(knvar_lst, nxarr2, nxdarr2, nyarr2, nparr2,nystrarr,npstrarr);
        nx_lst = arrayList(nxarr3);
        nxd_lst = arrayList(nxdarr3);
        ny_lst = arrayList(nyarr3);
        np_lst = arrayList(nparr3);
        nystr_lst = arrayList(nystrarr);
        npstr_lst = arrayList(npstrarr);
        whole_lst = Util.listFlatten({nx_lst,nxd_lst,ny_lst,np_lst,nystr_lst,npstr_lst});
        res = Util.stringDelimitListNonEmptyElts(whole_lst, "\n");
      then
        res;
  end matchcontinue;
end generateInitData2;

protected function printExpStrOpt 
"function: printExpStrOpt
  Helper function to generate_init_data2
  Prints expression value that is opional for initial values.
  If NONE is passed. The default value 0.0 is returned."
  input Option<Exp.Exp> inExpExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpOption)
    local
      String str;
      Exp.Exp e;
    case NONE then "0.0";
    case SOME(e)
      equation
        str = Exp.printExpStr(e);
      then
        str;
  end matchcontinue;
end printExpStrOpt;

protected function generateInitData3 
"function: generateInitData3
  This function is a help function to generateInitData2
  It Traverses Var lists and adds initial values to the specific
  string array depending on the type of the variable.
  For instance, state variables write their start value to the
  x array at given index."
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input String[:] inStringArray4;
  input String[:] inStringArray5;
  input String[:] inStringArray6;
  input String[:] inStringArray7;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output String[:] outStringArray3;
  output String[:] outStringArray4;
  output String[:] outStringArray5;
  output String[:] outStringArray6;
algorithm
  (outStringArray1,outStringArray2,outStringArray3,outStringArray4,outStringArray5,outStringArray6):=
  matchcontinue (inDAELowVarLst1,inStringArray2,inStringArray3,inStringArray4,inStringArray5,inStringArray6,inStringArray7)
    local
      String[:] nxarr,nxdarr,nyarr,nparr,nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr;
      String v,origname_str,str;
      Exp.ComponentRef cr,origname;
      Option<Exp.Exp> start;
      Integer indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest;
      Exp.Exp e;
      
    /* state strings derivative strings alg. var strings param. strings updated state strings updated derivative 
       strings updated alg. var strings updated param. strings */      
    case ({},nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) then (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
    /* Strings handled separately */
    case ((DAELow.VAR(varName = cr,
                      varKind = DAELow.VARIABLE(),
                      varType = DAELow.STRING(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e));
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nystrarr = arrayUpdate(nystrarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
    case ((DAELow.VAR(varName = cr,
                      varKind = DAELow.VARIABLE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
    case ((DAELow.VAR(varName = cr,
                      varKind = DAELow.DISCRETE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
    case ((DAELow.VAR(varKind = DAELow.STATE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "State variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nxarr = arrayUpdate(nxarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((DAELow.VAR(varKind = DAELow.DUMMY_DER(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "dummy derivatives => algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
    case ((DAELow.VAR(varKind = DAELow.DUMMY_STATE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "Dummy states => algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
    case ((_ :: rest),nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr);
        
  end matchcontinue;
end generateInitData3;

public function printExpOptStrIfConst 
"function: printExpOptStrIfConst
  Helper function to generateInitData3."
  input Option<Exp.Exp> inExpExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpOption)
    local
      String res;
      Exp.Exp e;
    case (SOME(e))
      equation
        true = Exp.isConst(e);
        res = printExpStrOpt(SOME(e));
      then
        res;
    case (_)
      equation
        res = printExpStrOpt(NONE);
      then
        "0.0";
  end matchcontinue;
end printExpOptStrIfConst;

protected function generateInitData4 
"function: generateInitData4
  Helper function to generateInitData2
  Traverses parameters."
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input String[:] inStringArray4;
  input String[:] inStringArray5;
  input String[:] inStringArray6;
  input String[:] inStringArray7;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output String[:] outStringArray3;
  output String[:] outStringArray4;
  output String[:] outStringArray5;
  output String[:] outStringArray6;
algorithm
  (outStringArray1,outStringArray2,outStringArray3,outStringArray4,outStringArray5,outStringArray6):=
  matchcontinue (inDAELowVarLst1,inStringArray2,inStringArray3,inStringArray4,inStringArray5,inStringArray6,inStringArray7)
    local
      String[:] nxarr,nxdarr,nyarr,nparr,nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr;
      String v,origname_str,str;
      Values.Value value;
      Integer indx;
      Exp.ComponentRef origname;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest,vs;
      Option<Exp.Exp> start;
      Exp.Exp e;
      
    case ({},nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) then (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
      
		/* String-Parameters handled separately*/
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      varType = DAELow.STRING(),
                      bindValue = SOME(value),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        v = ValuesUtil.valString(value);
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        npstrarr = arrayUpdate(npstrarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
		/* Parameters */
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      bindValue = SOME(value),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        v = ValuesUtil.valString(value);
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nparr = arrayUpdate(nparr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    /* String - Parameters without value binding. Investigate if it has start value */
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      bindValue = NONE,
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e))  ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        npstrarr = arrayUpdate(npstrarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    /* Parameters without value binding. Investigate if it has start value */
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      bindValue = NONE,
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e))  ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nparr = arrayUpdate(nparr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);
        
    case ((_ :: vs),nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr) = generateInitData4(vs, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr) 
        "Skip alg. vars that are removed
	       TODO! In future we should compare eliminated variables
	       intial values to their aliases to detect inconsistent
	       initial values." ;
      then
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr);
  end matchcontinue;
end generateInitData4;

protected function dumpWhenClausesStr 
"function: dumpWhenClausesStr
  Prints when clauses to a string."
  input list<DAELow.WhenClause> inDAELowWhenClauseLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELowWhenClauseLst)
    local
      String str,str2,res;
      DAELow.WhenClause c;
      list<DAELow.WhenClause> xs;
    case {} then "";
    case (c :: xs)
      equation
        str = dumpWhenClauseStr(c);
        str2 = dumpWhenClausesStr(xs);
        res = stringAppend(str, str2);
      then
        res;
  end matchcontinue;
end dumpWhenClausesStr;

protected function dumpWhenClauseStr 
"function: dumpWhenClauseStr
  Prints a when clause to a string."
  input DAELow.WhenClause inWhenClause;
  output String outString;
algorithm
  outString:=
  matchcontinue (inWhenClause)
    local
      String str1,res;
      Exp.Exp exp;
    case DAELow.WHEN_CLAUSE(condition = exp)
      equation
        str1 = Exp.printExpStr(exp);
        res = Util.stringAppendList({"when ",str1,"\n"});
      then
        res;
  end matchcontinue;
end dumpWhenClauseStr;

protected function generateZeroCrossing 
"function: generateZeroCrossing
  Generates code for handling zerocrossings as well as the
  zero crossing function given to the solver"
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input list<list<Integer>> inIntegerLstLst6;
  input list<HelpVarInfo> helpVarLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,inIntegerLstLst6,helpVarLst)
    local
      Codegen.CFunction func_zc,func_handle_zc,cfunc,cfunc0_1,cfunc0,cfunc_1,cfunc_2,func_zc0,func_handle_zc0,func_handle_zc0_1;
      Codegen.CFunction func_handle_zc0_2,func_handle_zc0_3,func_zc0_1,func_zc_1,func_handle_zc_1,cfuncHelpvars;
      Integer cg_id1,cg_id2,cg_id;
      list<CFunction> extra_funcs1,extra_funcs2,extra_funcs;
      String extra_funcs_str,helpvarUpdateStr,func_str,res,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      list<DAELow.ZeroCrossing> zc;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      list<HelpVarInfo> helpVarInfo;
      
    case (cname,dae,(dlow as DAELow.DAELOW(eventInfo = DAELow.EVENT_INFO(zeroCrossingLst = zc))),ass1,ass2,blocks,helpVarInfo)
      equation
        (cfunc,cg_id,extra_funcs2) = generateOdeBlocks(true,dlow, ass1, ass2, blocks, 0);
        (func_zc,cg_id1,func_handle_zc,cg_id2,extra_funcs1) = generateZeroCrossing2(zc, 0, dae, dlow, ass1, ass2, blocks, helpVarInfo, 0, 0); // testing here
        (cfuncHelpvars,cg_id) = generateHelpVarAssignments(helpVarInfo,cg_id);
        extra_funcs = listAppend(extra_funcs1, extra_funcs2);
        extra_funcs_str = Codegen.cPrintFunctionsStr(extra_funcs);
        cfunc0_1 = Codegen.cMakeFunction("int", "function_updateDependents", {}, {""});
        cfunc0_1 = addMemoryManagement(cfunc0_1);
        cfunc0_1 = Codegen.cAddInits(cfunc0_1, {"inUpdate=initial()?0:1;"});
        cfunc0 = Codegen.cAddCleanups(cfunc0_1, {"inUpdate=0;","return 0;"});
        cfunc_2 = Codegen.cMergeFns({cfunc0,cfunc,cfuncHelpvars});

        func_zc0 = Codegen.cMakeFunction("int", "function_zeroCrossing", {},
          {"long *neqm","double *t","double *x","long *ng",
          "double *gout","double *rpar","long* ipar"});
        func_zc0 = Codegen.cAddVariables(func_zc0,{"double timeBackup;"});
        func_zc0 = Codegen.cAddStatements(func_zc0,{"timeBackup = localData->timeValue;",
                                                    "localData->timeValue = *t;"
                                                    ,"functionODE();"
                                                    ,"functionDAE_output();"
                                                    });


        func_handle_zc0 = Codegen.cMakeFunction("int", "handleZeroCrossing", {}, {"long index"});
        func_handle_zc0_1 = Codegen.cPrependStatements(func_handle_zc0, {"switch(index) {"});
        func_handle_zc0_2 = Codegen.cAddCleanups(func_handle_zc0_1, {"default: break;","}"});
        func_handle_zc0_2 = addMemoryManagement(func_handle_zc0_2);
        func_zc0 = addMemoryManagement(func_zc0);
        func_handle_zc0_3 = Codegen.cAddCleanups(func_handle_zc0_2, {"return 0;"});

        func_zc0_1 = Codegen.cAddCleanups(func_zc0, {"localData->timeValue = timeBackup;", "return 0;"});
        func_zc_1 = Codegen.cMergeFns({func_zc0_1,func_zc});
        func_handle_zc_1 = Codegen.cMergeFns({func_handle_zc0_3,func_handle_zc});
        func_str = Codegen.cPrintFunctionsStr({func_zc_1,func_handle_zc_1,cfunc_2});
        res = Util.stringAppendList({extra_funcs_str,func_str});
      then
        res;
        
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_zero_crossing failed"});
      then
        fail();
        
  end matchcontinue;
end generateZeroCrossing;

protected function generateZeroCrossing2 
"function: generateZeroCrossing2
  Helper function to generateZeroCrossing"
  input list<DAELow.ZeroCrossing> inDAELowZeroCrossingLst1;
  input Integer inInteger2;
  input DAE.DAElist inDAElist3;
  input DAELow.DAELow inDAELow4;
  input Integer[:] inIntegerArray5;
  input Integer[:] inIntegerArray6;
  input list<list<Integer>> inIntegerLstLst7;
  input list<HelpVarInfo> helpVarLst;  // not used her anymore
  input Integer inInteger9;
  input Integer inInteger10;
  output CFunction outCFunction1;
  output Integer outInteger2;
  output CFunction outCFunction3;
  output Integer outInteger4;
  output list<CFunction> outCFunctionLst5;
algorithm
  (outCFunction1,outInteger2,outCFunction3,outInteger4,outCFunctionLst5):=
  matchcontinue (inDAELowZeroCrossingLst1,inInteger2,inDAElist3,inDAELow4,inIntegerArray5,inIntegerArray6,inIntegerLstLst7,helpVarLst,inInteger9,inInteger10)
    local
      Integer cg_id1,cg_id2,index_1,cg_id1_1,cg_id2_1,cg_id2_2,index;
      String zc_str,index_str,stmt1,rettp,fn,case_stmt,help_var_str,res;
      Codegen.CFunction cfunc1,cfunc2,cfunc2_1,cfunc2_2,cfunc1_1;
      list<CFunction> extra_funcs1,extra_funcs2,extra_funcs;
      list<HelpVarInfo> usedHelpVars,helpVarInfo;
      list<String> retrec,arg,init,stmts,vars,cleanups,stmts_1,stmts_2;
      DAELow.ZeroCrossing zc;
      list<Integer> eql;
      list<DAELow.ZeroCrossing> xs;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      list<String> saveStmts;
      
    case ({},_,_,_,_,_,_,_,cg_id1,cg_id2) then (Codegen.cEmptyFunction,cg_id1,Codegen.cEmptyFunction,cg_id2,{});  /* cg_var_id2 */
      
    case (_,_,_,_,_,_,_,_,cg_id1,cg_id2)
      equation
        false = useZerocrossing();
      then
        (Codegen.cEmptyFunction,cg_id1,Codegen.cEmptyFunction,cg_id2,{});
        
    case (((zc as DAELow.ZERO_CROSSING(occurEquLst = eql)) :: xs),index,dae,dlow,ass1,ass2,blocks,helpVarInfo,cg_id1,cg_id2)
      equation
        zc_str = dumpZeroCrossingStr(zc);
        index_str = intString(index);
        index_1 = index + 1;
        (cfunc1,cg_id1_1,cfunc2,cg_id2_1,extra_funcs1) = 
        
        generateZeroCrossing2(xs, index_1, dae, dlow, ass1, ass2, blocks, helpVarInfo, cg_id1, cg_id2);
        stmt1 = Util.stringAppendList({"ZEROCROSSING(",index_str,",",zc_str,");"});
        
        (Codegen.CFUNCTION(rettp,fn,retrec,arg,vars,init,stmts,cleanups),saveStmts,cg_id2_2,extra_funcs2) = 
        buildZeroCrossingEqns(dae, dlow, ass1, ass2, eql, blocks, cg_id2_1);
        case_stmt = Util.stringAppendList({"case ",index_str,":"});
        stmts = listAppend(saveStmts,stmts); // save statements before all equations
        //stmts_1 = (case_stmt :: stmts);
        stmts_1 = case_stmt :: saveStmts; // new design: only save in case section, rest is done in updateDependents
        
        stmts_2 = listAppend(stmts_1, {"  break;\n"});
        cfunc2_1 = Codegen.CFUNCTION(rettp,fn,retrec,arg,vars,init,stmts_2,cleanups);
        cfunc2_2 = Codegen.cMergeFns({cfunc2_1,cfunc2});
        cfunc1_1 = Codegen.cPrependStatements(cfunc1, {stmt1});
        extra_funcs = listAppend(extra_funcs1, extra_funcs2);
      then
        (cfunc1_1,cg_id1_1,cfunc2_2,cg_id2_2,extra_funcs);
        
    case (((zc as DAELow.ZERO_CROSSING(occurEquLst = eql)) :: xs),index,dae,dlow,ass1,ass2,blocks,helpVarInfo,cg_id1,cg_id2)
      equation
        zc_str = dumpZeroCrossingStr(zc);
        res = Util.stringAppendList({"generating zero crossing :",zc_str,"\n"});
        Error.addMessage(Error.INTERNAL_ERROR, {res});
      then
        fail();
        
  end matchcontinue;
end generateZeroCrossing2;

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

protected function dumpZeroCrossingStr 
"function: dumpZeroCrossingStr
  author:
  Dumps a ZeroCrossing to a sting. Useful for debugging."
  input DAELow.ZeroCrossing inZeroCrossing;
  output String outString;
algorithm
  outString:=
  matchcontinue (inZeroCrossing)
    local
      String e1_str,e2_str,op_str,zc_str,e_str;
      Exp.Exp e1,e2,start,interval,e;
      Exp.Operator op;
      
    case (DAELow.ZERO_CROSSING(relation_ = DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)))
      equation
        e1_str = printExpCppStr(e1);
        e2_str = printExpCppStr(e2);
        op_str = printZeroCrossingOpStr(op);
        zc_str = Util.stringAppendList({op_str,"(",e1_str,",",e2_str,")"});
      then
        zc_str;
        
    case (DAELow.ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"),expLst = {start,interval})))
      equation
        e1_str = printExpCppStr(start);
        e2_str = printExpCppStr(interval);
        zc_str = Util.stringAppendList({"Sample(*t,",e1_str,",",e2_str,")"});
      then
        zc_str;
        
    case (DAELow.ZERO_CROSSING(relation_ = e))
      equation
        e_str = printExpCppStr(e);
        zc_str = Util.stringAppendList({"/*Unknown zero crossing: ",e_str," */"});
      then
        zc_str;
        
  end matchcontinue;
end dumpZeroCrossingStr;

protected function generateHelpVarAssignments
  input list<HelpVarInfo> helpVarLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (helpVarLst,inInteger)
    local
      Integer cg_id,cg_id_1;
      String ind_str, assign,var;
      CFunction cfunc,cfunc1,cfunc2,cfn;
      Integer helpVarIndex;
      list<HelpVarInfo> rest;
      Exp.Exp e;
      
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg_id cg var_id */
      
    case (((helpVarIndex,e,_) :: rest),cg_id)
      equation
        ind_str = intString(helpVarIndex);
        (cfunc,var,cg_id) = Codegen.generateExpression(e, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(true),Codegen.NORMAL(),Codegen.NO_LOOP));
        assign = Util.stringAppendList({"localData->helpVars[",ind_str,"] = ",var,";"});
        cfunc1 = Codegen.cAddStatements(cfunc, {assign});
        (cfunc2,cg_id_1) = generateHelpVarAssignments(rest, cg_id);
        cfn = Codegen.cMergeFns({cfunc1,cfunc2});
      then
        (cfn,cg_id_1);
        
  end matchcontinue;
end generateHelpVarAssignments;

protected function printZeroCrossingOpStr
  input Exp.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.LESS(ty = _)) then "Less";
    case (DAE.GREATER(ty = _)) then "Greater";
    case (DAE.LESSEQ(ty = _)) then "LessEq";
    case (DAE.GREATEREQ(ty = _)) then "GreaterEq";
  end matchcontinue;
end printZeroCrossingOpStr;

protected function generateWhenClauses 
"function: generateWhenClauses
  Generate code for when clauses."
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input list<list<Integer>> inIntegerLstLst6;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,inIntegerLstLst6)
    local
      Codegen.CFunction when_fcn,when_fcn0,when_fcn_1,when_fcn_2,when_fcn3,when_fcn4;
      String res,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      list<DAELow.WhenClause> wc;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      
    case (cname,dae,(dlow as DAELow.DAELOW(eventInfo = DAELow.EVENT_INFO(whenClauseLst = wc))),ass1,ass2,blocks) /* assignments1 assignments2 blocks */
      equation
        (when_fcn,_) = generateWhenClauses2(wc, 0, dae, dlow, ass1, ass2, blocks, 0);
        when_fcn0 = Codegen.cMakeFunction("int", "function_when", {}, {"int i"});
        when_fcn_1 = Codegen.cMergeFns({when_fcn0,when_fcn});
        when_fcn_2 = Codegen.cPrependStatements(when_fcn_1, {"switch(i) {"});
        when_fcn3 = Codegen.cAddStatements(when_fcn_2, {"default: break;","}"});
        when_fcn3 = addMemoryManagement(when_fcn3);
        when_fcn4 = Codegen.cAddCleanups(when_fcn3, {"return 0;"});
        res = Codegen.cPrintFunctionsStr({when_fcn4});
      then
        res;
        
    case (_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generateWhenClauses failed"});
      then
        fail();
        
  end matchcontinue;
end generateWhenClauses;

protected function generateWhenClauses2
  input list<DAELow.WhenClause> inDAELowWhenClauseLst1;
  input Integer inInteger2;
  input DAE.DAElist inDAElist3;
  input DAELow.DAELow inDAELow4;
  input Integer[:] inIntegerArray5;
  input Integer[:] inIntegerArray6;
  input list<list<Integer>> inIntegerLstLst7;
  input Integer inInteger8;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowWhenClauseLst1,inInteger2,inDAElist3,inDAELow4,inIntegerArray5,inIntegerArray6,inIntegerLstLst7,inInteger8)
    local
      Integer cg_id,cg_id_1,index_1,cg_id_2,index;
      String wc_str,save_cond_str,reinit_str_1,index_str,when_str,case_stmt;
      list<Exp.ComponentRef> cond_cref_list;
      list<String> cond_cref_str_list,reinit_str;
      Codegen.CFunction when_fcn,when_fcn_1,when_fcn_2,when_fcn2,when_fcn_3;
      DAELow.WhenClause wc;
      Exp.Exp cond;
      list<DAELow.ReinitStatement> reinit;
      list<DAELow.WhenClause> xs;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      
    case ({},_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* assignments1 assignments2 blocks cg var_id cg var_id */
      
    case (((wc as DAELow.WHEN_CLAUSE(condition = cond,reinitStmtLst = reinit)) :: xs),index,dae,dlow,ass1,ass2,blocks,cg_id)
      equation
        wc_str = dumpWhenClauseStr(wc);
        cond_cref_list = Exp.getCrefFromExp(cond);
        cond_cref_str_list = Util.listMap(cond_cref_list, Exp.printComponentRefStr);
        save_cond_str = Util.stringDelimitList(cond_cref_str_list, ");\n    save(");
        save_cond_str = Util.stringAppendList({"    save(",save_cond_str,");\n"});
        reinit_str = Util.listMap(reinit, buildReinitStr);
        reinit_str_1 = Util.stringAppendList(reinit_str);
        index_str = intString(index);
        (when_fcn,cg_id_1) = buildWhenBlocks(dae, dlow, ass1, ass2, blocks, index, cg_id);
        when_str = Codegen.cPrintStatements(when_fcn);
        case_stmt = Util.stringAppendList({" case ",index_str,": //",wc_str});
        when_fcn_1 = Codegen.cPrependStatements(when_fcn, {case_stmt});
        when_fcn_2 = Codegen.cAddStatements(when_fcn_1, {reinit_str_1,"  break;\n"});
        index_1 = index + 1;
        (when_fcn2,cg_id_2) = generateWhenClauses2(xs, index_1, dae, dlow, ass1, ass2, blocks, cg_id_1);
        when_fcn_3 = Codegen.cMergeFns({when_fcn_2,when_fcn2});
      then
        (when_fcn_3,cg_id_2);
                
  end matchcontinue;
end generateWhenClauses2;

protected function buildReinitStr
  input DAELow.ReinitStatement inReinitStatement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inReinitStatement)
    local
      String cr_str,exp_str,eqn_str;
      Exp.ComponentRef cr;
      Exp.Exp exp;
    case (DAELow.REINIT(stateVar = cr,value = exp))
      equation
        cr_str = Exp.printComponentRefStr(cr);
        exp_str = printExpCppStr(exp);
        eqn_str = Util.stringAppendList({"    ",cr_str," = ",exp_str,";"});
      then
        eqn_str;
  end matchcontinue;
end buildReinitStr;

protected function buildWhenBlocks 
"function: buildWhenBlocks
  Helper function to buildWhenClauses."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<list<Integer>> inIntegerLstLst5;
  input Integer inInteger6;
  input Integer inInteger7;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLstLst5,inInteger6,inInteger7)
    local
      Integer cg_id,cg_id_1,cg_id_2,eqn,index;
      Codegen.CFunction cfn1,cfn2,cfn;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;
      
    case (_,_,_,_,{},_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg var_id cg var_id */
      
    case (dae,dlow,ass1,ass2,((block_ as {eqn}) :: blocks),index,cg_id)
      equation
        (cfn1,cg_id_1) = buildWhenEquation(dae, dlow, ass1, ass2, eqn, index, cg_id);
        (cfn2,cg_id_2) = buildWhenBlocks(dae, dlow, ass1, ass2, blocks, index, cg_id_1);
        cfn = Codegen.cMergeFns({cfn1,cfn2});
      then
        (cfn,cg_id_2);
        
    case (_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);
  end matchcontinue;
end buildWhenBlocks;


protected function buildZeroCrossingEqns 
"function: buildZeroCrossingEqns2
  author: haklu
  Helper function to generateZeroCrossing2. 
  Iterates and generates code for each equation in a zero crossing."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<Integer> inIntegerLst5;
  input list<list<Integer>> inIntegerLstLst6;
  input Integer inInteger7;
  output CFunction outCFunction;
  output list<String> saveStmts " list of 'save(..);' statements";
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLst5,inIntegerLstLst6,inInteger7)
    local
      Integer cg_id,eqn_1,v,cg_id1,cg_id2,cg_id3,cg_id4,cg_id5,cg_id6,eqn,cg_id_1,cg_id_2,numValues;
      list<Integer> block_,rest;
      Exp.ComponentRef cr;
      String cr_str,save_stmt,rettp,fn,stmt;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,cont_var1;
      DAELow.Variables vars, vars_1,knvars,exvars;
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      Codegen.CFunction s0,s2_1,s4,s3,s1,cfn3,cfn,cfn2,cfn1;
      list<String> retrec,arg,init,stmts,cleanups,stmts_1;
      list<CFunction> extra_funcs1,extra_funcs2,extra_funcs;
      DAE.DAElist dae;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      DAELow.ExternalObjectClasses eoc;
      
    case (_,_,_,_,{},_,cg_id) then (Codegen.cEmptyFunction,{},cg_id,{});  /* ass1 ass2 eqns blocks cg var_id cg var_id */

    /* Zero crossing for mixed system */      
    case (dae,(dlow as DAELow.DAELOW(vars,knvars,exvars,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,(eqn :: rest),blocks,cg_id) 
      equation
        true = isPartOfMixedSystem(dlow, eqn, blocks, ass2);
        block_ = getZcMixedSystem(dlow, eqn, blocks, ass2);
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (DAELow.VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,_)) = DAELow.getVarAt(vars, v);
        cr_str = Exp.printComponentRefStr(cr);
        save_stmt = Util.stringAppendList({"  save(",cr_str,");"});
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        eqn_lst = Util.listMap(eqn_lst,replaceEqnGreaterWithGreaterEq); 
        //temporary fix to make events occur. Remove once mixed systems are solved analythically
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
				cont_var1 = Util.listMap(cont_var, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,eqns_1,se,ie,ae,al,ev,eoc);
        /*
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        (s0,cg_id1,numValues) = generateMixedHeader(cont_eqn, cont_var, disc_eqn, disc_var, cg_id);
        (Codegen.CFUNCTION(rettp,fn,retrec,arg,vars,init,stmts,cleanups),cg_id2,extra_funcs1) = generateOdeSystem2(true,true,cont_subsystem_dae, jac, jac_tp, cg_id1);
        stmts_1 = Util.listFlatten({{"{"},vars,stmts,{"}"}}) 
        "initialization of e.g. matrices for linsys must be done in each iteration, create new scope and put them first." ;
        s2_1 = Codegen.CFUNCTION(rettp,fn,retrec,arg,{},init,stmts_1,cleanups);
        (s4,cg_id3) = generateMixedFooter(cont_eqn, cont_var, disc_eqn, disc_var, cg_id2);
        (s3,cg_id4,_) = generateMixedSystemDiscretePartCheck(disc_eqn, disc_var, cg_id3,numValues);
        (s1,cg_id5,_) = generateMixedSystemStoreDiscrete(disc_var, 0, cg_id4);
        */
        cg_id5 = cg_id;
        (cfn3,saveStmts,cg_id6,extra_funcs2) = buildZeroCrossingEqns(dae, dlow, ass1, ass2, rest, blocks, cg_id5);
        cfn = Codegen.cMergeFns({cfn3});
        extra_funcs = listAppend(/*extra_funcs1*/{}, extra_funcs2);
      then
        (cfn,save_stmt::saveStmts,cg_id6,extra_funcs);
        
    /* Zero crossing for single equation */
    case (dae,(dlow as DAELow.DAELOW(orderedVars = vars)),ass1,ass2,(eqn :: rest),blocks,cg_id) 
      local DAELow.Variables vars;
      equation
        // (cfn2,cg_id_1) = buildEquation(dae, dlow, ass1, ass2, eqn, cg_id);
        cfn2 = Codegen.cEmptyFunction;
        cg_id_1 = cg_id;
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (DAELow.VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,_)) = DAELow.getVarAt(vars, v);
        cr_str = Exp.printComponentRefStr(cr);
        (cfn3,saveStmts,cg_id_2,extra_funcs) = buildZeroCrossingEqns(dae, dlow, ass1, ass2, rest, blocks, cg_id_1);
        stmt = Util.stringAppendList({"  save(",cr_str,");"});
       cfn = Codegen.cMergeFns({cfn2,cfn3});
      then
        (cfn,stmt::saveStmts,cg_id_2,extra_funcs);
        
    case (_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,{},cg_id,{});
  end matchcontinue;
end buildZeroCrossingEqns;

protected function replaceEqnGreaterWithGreaterEq 
"function replaceEqnGreaterWithGreaterEq
 Temporary fix to get mixed system to work in
 e.g. Modelica.Mechanics.Rotational.Interfaces.FrictionBase"
  input DAELow.Equation eqn;
  output DAELow.Equation res;
algorithm
  res := matchcontinue(eqn)
    local
      Exp.Exp e1,e2;
      DAELow.Equation e;
      Exp.ComponentRef cr1;
    case(DAELow.EQUATION(e1,e2)) 
      equation
        ((e1,_)) = Exp.traverseExp(e1,replaceExpGTWithGE,true);
        ((e2,_)) = Exp.traverseExp(e2,replaceExpGTWithGE,true);
      then DAELow.EQUATION(e1,e2);
        
    case(DAELow.SOLVED_EQUATION(cr1,e2)) 
      equation
        ((e2,_)) = Exp.traverseExp(e2,replaceExpGTWithGE,true);
      then DAELow.SOLVED_EQUATION(cr1,e2);
        
    case(DAELow.RESIDUAL_EQUATION(e1)) 
      equation
        ((e1,_)) = Exp.traverseExp(e1,replaceExpGTWithGE,true);
      then DAELow.RESIDUAL_EQUATION(e1);
        
    case(e) then e;
  end matchcontinue;
end replaceEqnGreaterWithGreaterEq;

protected function replaceExpGTWithGE 
"traversal function to replace > with >="
  input tuple<Exp.Exp,Boolean> inExp;
  output tuple<Exp.Exp,Boolean> outExp;
algorithm
  outExp := matchcontinue(inExp)
  local Exp.Type tp;
    Exp.Exp e1,e2;
    Boolean dummyArg;
    case((DAE.RELATION(e1,DAE.LESS(tp),e2),dummyArg)) then ((DAE.RELATION(e1,DAE.LESSEQ(tp),e2),dummyArg));
    case((DAE.RELATION(e1,DAE.GREATER(tp),e2),dummyArg)) then ((DAE.RELATION(e1,DAE.GREATEREQ(tp),e2),dummyArg));
    case((e1,dummyArg)) then ((e1,dummyArg));
  end matchcontinue;
end replaceExpGTWithGE;

protected function dumpMixedSystem 
"function: dumpMixedSystem
  dumps a mixed system of equations on stdout."
  input list<DAELow.Equation> c_e;
  input list<DAELow.Var> c_v;
  input list<DAELow.Equation> d_e;
  input list<DAELow.Var> d_v;
algorithm
  print("Mixed system\n");
  print("============\n");
  print("  continous eqns:\n");
  DAELow.dumpEqns(c_e);
  print("  continous vars:\n");
  DAELow.dumpVars(c_v);
  print("  discrete eqns:\n");
  DAELow.dumpEqns(d_e);
  print("  discret vars:\n");
  DAELow.dumpVars(d_v);
  print("\n");
end dumpMixedSystem;

protected function buildWhenEquation 
"function: buildWhenEquation
  Helper function to buildWhenBlocks."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inInteger7)
    local
      Integer e_1,wc_ind,v,v_1,cg_id_1,e,index,cg_id;
      Exp.ComponentRef cr,origname;
      Exp.Exp expr;
      DAELow.Var va;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String assignedVar,origname_str,save_stmt;
      Codegen.CFunction cfn;
      DAE.DAElist dae;
      DAELow.VariableArray vararr;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
      
    /* assignments1 assignments2 equation no. cg var_id cg var_id */
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,index,cg_id) 
      equation
        e_1 = e - 1;
        DAELow.WHEN_EQUATION(DAELow.WHEN_EQ(wc_ind,cr,expr,_)) = DAELow.equationNth(eqns, e_1); //TODO: elsewhen
        (index == wc_ind) = true;
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        ((va as DAELow.VAR(varName=cr,
                           varKind=kind,
                           origVarName=origname,
                           values=dae_var_attr,
                           comment=comment,
                           flowPrefix=flowPrefix,
                           streamPrefix=streamPrefix))) = DAELow.vararrayNth(vararr, v_1);
        assignedVar = Exp.printComponentRefStr(cr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, expr, origname_str, cg_id);
        save_stmt = Util.stringAppendList({"save(",assignedVar,");\n"});
        cfn = Codegen.cPrependStatements(cfn, {save_stmt});
      then
        (cfn,cg_id_1);
    case (_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);
  end matchcontinue;
end buildWhenEquation;

protected function generateComputeResidualState 
"function: generateComputeResidualState
  This function generates the code for the calculation of the
  state variables on residual form. Called from generateSimulationCode."
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input list<list<Integer>> inIntegerLstLst6;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,inIntegerLstLst6)
    local
      Codegen.CFunction cfn1,cfn2,cfn;
      String res,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
    case (cname,dae,dlow,ass1,ass2,blocks) /* assignments1 assignments2 blocks */
      equation
        cfn1 = Codegen.cMakeFunction("int", "functionDAE_res", {},
          {"double *t","double *x","double *xd","double *delta",
          "long int *ires","double *rpar","long int* ipar"}) "build_residual_blocks(dae,dlow,ass1,ass2,blocks,0) => (cfn2,_) &" ;
        cfn2 = Codegen.cAddVariables(cfn1, {"int i;",
                                            "double temp_xd[NX];",
                                             "double* statesBackup;",
                                             "double* statesDerivativesBackup;",
                                             "double timeBackup;"
                                            });
        cfn = Codegen.cAddStatements(cfn2,
          {
            //"assert(localData);",
            "statesBackup = localData->states;",
            "statesDerivativesBackup = localData->statesDerivatives;",
            "timeBackup = localData->timeValue;",
            "localData->states = x;",
            "for (i=0; i<localData->nStates; i++) temp_xd[i]=localData->statesDerivatives[i];",
            "",
            "localData->statesDerivatives = temp_xd;",
            "localData->timeValue = *t;",
            "",
            "functionODE();",
            "/* get the difference between the temp_xd(=localData->statesDerivatives) and xd(=statesDerivativesBackup) */",
            "for (i=0; i < localData->nStates; i++) delta[i]=localData->statesDerivatives[i]-statesDerivativesBackup[i];",
            "",
            "localData->states = statesBackup;",
            "localData->statesDerivatives = statesDerivativesBackup;",
            "localData->timeValue = timeBackup;",
            "if (modelErrorCode) {",
            "  if (ires) *ires = -1;",
  					"  modelErrorCode =0;",
  					"}",
            "return 0;"});
            res = Codegen.cPrintFunctionsStr({cfn});
          then
            res;
            
    case (cname,dae,dlow,ass1,ass2,blocks)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_compute_residual_state"});
      then
        fail();
  end matchcontinue;
end generateComputeResidualState;

protected function generateComputeOutput 
"function: generateComputeOutput
  This function generates the code for the 
  calculation of the output variables and for asserts."
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrixT mT;
  input list<list<Integer>> inIntegerLstLst6;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,m,mT,inIntegerLstLst6)
    local
      Codegen.CFunction cfunc_1,cfunc,cfunc1,cfunc2,body,cfunc_2,assertBody;
      list<CFunction> extra_funcs,extra_funcs1,extra_funcs2;
      list<String> stmts2;
      String coutput,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks,blocks1,blocks2;
      Integer cg_id;
    case (cname,dae,dlow,ass1,ass2,m,mT,blocks)
      equation
        (blocks1,blocks2) = splitOutputBlocks(dlow,ass1,ass2,m,mT,blocks);
        
        /* Create output function + asserts */
        cfunc_1 = Codegen.cMakeFunction("int", "functionDAE_output", {}, {""});
        cfunc_1 = addMemoryManagement(cfunc_1);
        cfunc1 = Codegen.cAddCleanups(cfunc_1, {"return 0;"});
        (body,cg_id,extra_funcs1) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks1, 0);
        (assertBody,cg_id) = generateAlgorithmAsserts(dlow,cg_id);
        stmts2 = generateComputeRemovedEqns(dlow);
        cfunc_1 = Codegen.cMergeFns({cfunc1,body,assertBody});
        cfunc_1 = Codegen.cAddStatements(cfunc_1, stmts2);

        /* Create output2 function for discrete vars.*/
        cfunc_2 = Codegen.cMakeFunction("int", "functionDAE_output2", {}, {""});
        cfunc_2 = addMemoryManagement(cfunc_2);
        cfunc2 = Codegen.cAddCleanups(cfunc_2, {"return 0;"});
        (body,cg_id,extra_funcs2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks2, 0);
        stmts2 = generateComputeRemovedEqns(dlow);
        cfunc_2 = Codegen.cMergeFns({cfunc2,body});
        cfunc_2 = Codegen.cAddStatements(cfunc_2, stmts2);

        extra_funcs = listAppend(extra_funcs1,extra_funcs2);
        coutput = Codegen.cPrintFunctionsStr((listAppend(extra_funcs,{cfunc_1,cfunc_2})));
      then
        coutput;
        
    case (_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_compute_output failed"});
      then
        fail();
  end matchcontinue;
end generateComputeOutput;

protected function splitOutputBlocks 
"function splitOutputBlocks
  Help function to generateComputeOutput, splits the output blocks into two 
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
"Help function to splitOutputBlocks"
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

protected function generateAlgorithmAsserts 
"Generates assert statements from equations and algorithms into computeOutput function
 equation asserts are transformed to algorithm asserts, so this function goes through all 
 algorithms and generate code for the asserts it finds (which are not part of 'complex' algorithm"
  input DAELow.DAELow dlow;
  input Integer cg_id;
  output Codegen.CFunction cfunc;
  output Integer outCg_id;
algorithm
	(cfunc,outCg_id) := matchcontinue(dlow,cg_id)
	  local Algorithm.Algorithm[:] algs;
	  case(DAELow.DAELOW(algorithms = algs),cg_id) 
	    equation
	      (cfunc,cg_id) = generateAlgorithmAsserts2(arrayList(algs),cg_id);
	    then (cfunc,cg_id);
  end matchcontinue;
end generateAlgorithmAsserts;

protected function generateAlgorithmAsserts2 
"Help function to generateAlgorithmAsserts"
  input list<Algorithm.Algorithm> algs;
  input Integer cg_id;
  output Codegen.CFunction cfunc;
  output Integer outCg_id;
algorithm
  (cfunc,outCg_id) := matchcontinue(algs,cg_id)
    local Codegen.CFunction cfunc1,cfunc2; Algorithm.Algorithm a;
      
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);
      
    case((a as DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond =_)}))::algs,cg_id) 
      equation
        (cfunc1,cg_id) = Codegen.generateAlgorithm(DAE.ALGORITHM(a),cg_id,Codegen.simContext);
        (cfunc2,cg_id) = generateAlgorithmAsserts2(algs,cg_id);
        cfunc = Codegen.cMergeFns({cfunc1,cfunc2});
      then (cfunc,cg_id);
        
    case(_::algs,cg_id) 
      equation
        (cfunc,cg_id) = generateAlgorithmAsserts2(algs,cg_id);
      then (cfunc,cg_id);
        
  end matchcontinue;
end generateAlgorithmAsserts2;


protected function generateComputeRemovedEqns 
"function: generateComputeRemovedEqns
  author: PA
  Generates compute code for the removed equations"
  input DAELow.DAELow inDAELow;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Equation> eqn_lst;
      list<String> res;
      DAELow.EquationArray reqns;
    case (DAELow.DAELOW(removedEqs = reqns))
      equation
        eqn_lst = DAELow.equationList(reqns);
        res = generateComputeRemovedEqns2(eqn_lst);
      then
        res;
  end matchcontinue;
end generateComputeRemovedEqns;

protected function 
generateComputeRemovedEqns2 
"function: generateComputeRemovedEqns2
  Helper function to generateComputedRemoveEqns"
  input list<DAELow.Equation> inDAELowEquationLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELowEquationLst)
    local
      list<String> res;
      String cr_str,exp_str,s1;
      Exp.ComponentRef cr;
      Exp.Exp exp;
      list<DAELow.Equation> rest;
    case ({}) then {};
    case ((DAELow.SOLVED_EQUATION(componentRef = cr,exp = exp) :: rest))
      equation
        res = generateComputeRemovedEqns2(rest);
        cr_str = Exp.printComponentRefStr(cr);
        exp_str = printExpCppStr(exp);
        s1 = Util.stringAppendList({cr_str," = ",exp_str,";"});
      then
        (s1 :: res);
  end matchcontinue;
end generateComputeRemovedEqns2;

protected function buildSolvedBlocks 
"function: buildSolvedBlocks
  This function generates code for blocks on solved form, i.e.
  \\dot{x} = f(x,y,t)
  It is used for the generation of the output function. If event code
  is generated, it does not include discrete equations in the output code."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<list<Integer>> inIntegerLstLst5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLstLst5,inInteger6)
    local
      Integer cg_id,cg_id_1,cg_id_2,eqn;
      Codegen.CFunction cfn1,cfn2,cfn,fcn1,fcn2,fcn;
      list<CFunction> f2,f1,f;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;
      
    /* assignments1 assignments2 list of blocks cg var_id cg var_id */
    case (_,_,_,_,{},cg_id) then (Codegen.cEmptyFunction,cg_id,{});
        
    case (dae,dlow,ass1,ass2,((block_ as {eqn}) :: blocks),cg_id)
      equation
        true = useZerocrossing() "for single equations" ;
        (cfn1,cg_id_1) = buildNonDiscreteEquation(dae, dlow, ass1, ass2, eqn, cg_id);
        (cfn2,cg_id_2,f2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks, cg_id_1);
        cfn = Codegen.cMergeFns({cfn1,cfn2});
      then
        (cfn,cg_id_2,f2);
        
    case (dae,dlow,ass1,ass2,((block_ as {eqn}) :: blocks),cg_id)
      equation
        false = useZerocrossing() "for single equations" ;
        (cfn1,cg_id_1) = buildEquation(dae, dlow, ass1, ass2, eqn, cg_id);
        (cfn2,cg_id_2,f2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks, cg_id_1);
        cfn = Codegen.cMergeFns({cfn1,cfn2});
      then
        (cfn,cg_id_2,f2);
        
    case (dae,dlow,ass1,ass2,(block_ :: blocks),cg_id)
      equation
        (fcn1,cg_id_1,f1) = generateOdeSystem(false,dlow, ass1, ass2, block_, cg_id) "for blocks" ;
        (fcn2,cg_id_2,f2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks, cg_id_1);
        fcn = Codegen.cMergeFns({fcn1,fcn2});
        f = listAppend(f1, f2);
      then
        (fcn,cg_id_2,f);
        
    case (_,_,_,_,_,_)
      equation
        print("-SimCodegen.buildSolvedBlocks failed\n");
      then
        fail();
  end matchcontinue;
end buildSolvedBlocks;

protected function buildBlock 
"function: buildBlock
  This function returns the code string for solving a block 
  of variables in the dae, i.e. a set of coupled equations.
  It is used both for state variables and algebraic variables."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<Integer> inIntegerLst5;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLst5)
    local
      Integer e_1,indx,e;
      list<Exp.Exp> inputs,outputs;
      Algorithm.Algorithm alg;
      list<String> stmt_strs;
      String res;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      Integer[:] ass1,as2,ass2;
      list<Integer> block_;
      
    /* assignments1 assignments2 block of equations */
    case (dae,(dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),ass1,as2,(block_ as (e :: _))) 
      equation
        true = allSameAlgorithm(dlow, block_);
        e_1 = e - 1;
        DAELow.ALGORITHM(indx,inputs,outputs) = DAELow.equationNth(eqns, e_1);
        alg = alg[indx + 1];
        (Codegen.CFUNCTION(_,_,_,_,_,_,stmt_strs,_),_) = Codegen.generateAlgorithm(DAE.ALGORITHM(alg), 1, Codegen.simContext);
        res = Util.stringDelimitList(stmt_strs, "\n");
      then
        res;
        
    case (dae,dlow,ass1,ass2,block_)
      equation
        print("#Solving of equation systems not implemented yet.\n");
      then
        fail();
  end matchcontinue;
end buildBlock;

protected function allSameAlgorithm 
"function: allSameAlgorithm
  Checks that a block consists only of one algorithm in different -nodes-"
  input DAELow.DAELow inDAELow;
  input list<Integer> inIntegerLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELow,inIntegerLst)
    local
      Integer e_1,indx,e;
      Boolean res;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      Algorithm.Algorithm[:] alg;
      list<Integer> block_;
    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),(block_ as (e :: _))) /* blocks */
      equation
        e_1 = e - 1 "extract index of first algorithm and check that entire block has that index." ;
        DAELow.ALGORITHM(indx,_,_) = DAELow.equationNth(eqns, e_1);
        res = allSameAlgorithm2(dlow, block_, indx);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end allSameAlgorithm;

protected function allSameAlgorithm2 
"function: allSameAlgorithm2
  Helper function to all_same_algorithm. Checks all equations in the 
  block and returns true if they all are algorithms with the same index."
  input DAELow.DAELow inDAELow;
  input list<Integer> inIntegerLst;
  input Integer inInteger;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELow,inIntegerLst,inInteger)
    local
      Integer e_1,indx2,e,indx;
      Boolean b1;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      Algorithm.Algorithm[:] alg;
      list<Integer> es;
    case (_,{},_) then true;  /* block alg. index */
    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),(e :: es),indx)
      equation
        e_1 = e - 1;
        DAELow.ALGORITHM(indx2,_,_) = DAELow.equationNth(eqns, e_1);
        (indx == indx2) = true;
        b1 = allSameAlgorithm2(dlow, es, indx);
      then
        b1;
    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),(e :: es),indx)
      equation
        e_1 = e - 1;
        DAELow.ALGORITHM(indx2,_,_) = DAELow.equationNth(eqns, e_1);
        (indx == indx2) = false;
      then
        false;
    case (_,_,_) then false;
  end matchcontinue;
end allSameAlgorithm2;

protected function buildNonDiscreteEquation 
"function: buildNonDiscreteEquation
  Builds code for non_discrete equations only.
  Used in build_solved_blocks."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6)
    local
      Integer e_1,v_1,e,cg_id,cg_id_1,eqn;
      DAELow.Var v;
      DAELow.VariableArray vararr;
      Integer[:] ass2,ass1;
      Codegen.CFunction cfunc;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      list<Integer> zcEqns;

    // Discrete equations that exists in ZeroCrossings are skipped.
    case (_,dlow as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr)),_,ass2,e,cg_id) /* cg var_id cg var_id */
      equation
        e_1 = e - 1;
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        (v) = DAELow.vararrayNth(vararr, v_1);
        true = hasDiscreteVar({v});
        zcEqns = DAELow.zeroCrossingsEquations(dlow);
        true = listMember(e,zcEqns);
      then
        (Codegen.cEmptyFunction,cg_id);
        
    case (dae,dlow,ass1,ass2,eqn,cg_id)
      equation
        (cfunc,cg_id_1) = buildEquation(dae, dlow, ass1, ass2, eqn, cg_id);
      then
        (cfunc,cg_id_1);
  end matchcontinue;
end buildNonDiscreteEquation;

protected function buildEquation 
"function buildEquation
  This returns the code string for a specific equation in the dae.
  It is used both for state variables and regular variables."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6)
    local
      Integer e_1,v,v_1,cg_id_1,e,cg_id,indx;
      Exp.Exp e1,e2,varexp,expr,simplify_exp,new_varexp;
      DAELow.Var va;
      Exp.ComponentRef cr,origname;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String origname_str;
      Codegen.CFunction cfn;
      DAE.DAElist dae;
      DAELow.VariableArray vararr;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
      list<Exp.Exp> inputs,outputs;
      Algorithm.Algorithm alg;
      Algorithm.Algorithm[:] algs;
      
    /* assignments1 assignments2 equation no cg var_id cg var_id */
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id) 
      equation
        e_1 = e - 1 "Solving for non-states" ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        ((va as DAELow.VAR(varName=cr,varKind=kind,
                           origVarName=origname,
                           values=dae_var_attr,
                           comment=comment,
                           flowPrefix=flowPrefix,
                           streamPrefix=streamPrefix))) = DAELow.vararrayNth(vararr, v_1);
        true = DAELow.isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        simplify_exp = Exp.simplify(expr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);
        
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        e_1 = e - 1 "Solving the state s means solving for der(s)" ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v == variable no solved in this equation" ;
        DAELow.VAR(varName=cr,varKind=kind,
                   origVarName=origname,
                   values=dae_var_attr,
                   index=indx,
                   comment=comment,
                   flowPrefix=flowPrefix,
                   streamPrefix=streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        new_varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, new_varexp);
        simplify_exp = Exp.simplify(expr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);
        
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local
        String s1,s2;
      equation
        e_1 = e - 1 "probably, solved failed in rule above. This means that we have a non-linear equation." ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v==variable no solved in this equation" ;
        DAELow.VAR(varName=cr,varKind=kind,
                   origVarName=origname,
                   values=dae_var_attr,
                   comment=comment,
                   flowPrefix=flowPrefix,
                   streamPrefix=streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        print("nonlinear equation not implemented yet\n");
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        print(Util.stringAppendList({s1," = ", s2, "\n\n"}));
      then
        fail();
        
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns,algorithms = algs),ass1,ass2,e,cg_id)
      equation
        e_1 = e - 1 "Algorithms Each algorithm should only be genated once." ;
        DAELow.ALGORITHM(indx,inputs,outputs) = DAELow.equationNth(eqns, e_1);
        alg = algs[indx + 1];
        (cfn,cg_id_1) = Codegen.generateAlgorithm(DAE.ALGORITHM(alg), cg_id, Codegen.simContext);
      then
        (cfn,cg_id_1);
        
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-SimCodegen.buildEquation failed\n");
      then
        fail();
  end matchcontinue;
end buildEquation;

protected function buildResidualBlocks 
"function: buildResidualBlocks
  This function generates code for blocks on residual form, i.e.
  g(\\dot{x},x,y,t) = 0"
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<list<Integer>> inIntegerLstLst5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLstLst5,inInteger6)
    case (_,_,_,_,_,_) /* ass1 ass2 blocks cg var_iter cg var_iter */
      equation
        print("-SimCodegen.buildResidualBlocks failed\n");
      then
        fail();
  end matchcontinue;
end buildResidualBlocks;

protected function buildResidualEquation 
"function buildResidualEquation
  This function generates code on residual form for one equation.
  It is used both for state variables and algebraic variables."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6)
    local
      Integer e_1,v_1,e,cg_id,cg_id_1,indx;
      DAELow.Var v,va;
      DAELow.VariableArray vararr;
      Integer[:] ass2,ass1;
      Exp.Exp e1,e2,varexp,expr,simplify_exp,exp;
      Exp.ComponentRef cr,origname,new_cr;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String origname_str,indx_str,cr_str;
      Codegen.CFunction cfn;
      DAE.DAElist dae;
      DAELow.EquationArray eqns;
      
    /* assignments1 assignments2 equation no. cg var_id cg var_id */
    case (_,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr)),_,ass2,e,cg_id)
      equation
        e_1 = e - 1 "Do not output equations for discrete variables here" ;
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        (v) = DAELow.vararrayNth(vararr, v_1);
        true = hasDiscreteVar({v});
      then
        (Codegen.cEmptyFunction,cg_id);
        
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local Integer v;
      equation
        e_1 = e - 1 "Solving for non-states" ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        ((va as DAELow.VAR(varName=cr,
                           varKind=kind,
                           origVarName=origname,
                           values=dae_var_attr,
                           comment=comment,
                           flowPrefix=flowPrefix,
                           streamPrefix=streamPrefix))) = DAELow.vararrayNth(vararr, v_1);
        true = DAELow.isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL()) "print \"Solving for non-states\\n\" &" ;
        expr = Exp.solve(e1, e2, varexp);
        simplify_exp = Exp.simplify(expr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);
        
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local Integer v;
      equation
        e_1 = e - 1 "Solving the state s, caluate residual form." ;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        DAELow.VAR(varName=cr,varKind=kind,
                   index=indx,
                   origVarName=origname,
                   values=dae_var_attr,
                   comment=comment,
                   flowPrefix=flowPrefix,
                   streamPrefix=streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        indx_str = intString(indx);
        exp = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        simplify_exp = Exp.simplify(exp);
        cr_str = Util.stringAppendList({"delta[",indx_str,"]"}) "Use array named \'delta\' for residuals" ;
        new_cr = DAE.CREF_IDENT(cr_str,DAE.ET_REAL(),{});
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, new_cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);
        
    case (_,DAELow.DAELOW(orderedEqs = eqns),_,_,e,cg_id)
      local DAELow.WhenEquation e;
      equation
        e_1 = e - 1 "when-equations are not part of the residual equations" ;
        DAELow.WHEN_EQUATION(e) = DAELow.equationNth(eqns, e_1);
      then
        (Codegen.cEmptyFunction,cg_id);
        
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local Integer v;
      equation
        e_1 = e - 1;
        DAELow.EQUATION(e1,e2) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v==variable no solved in this equation" ;
        DAELow.VAR(varName=cr,
                   origVarName=origname,
                   values=dae_var_attr,
                   comment=comment,
                   flowPrefix=flowPrefix,
                   streamPrefix=streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        print("nonlinear equation not implemented yet\n");
      then
        fail();
        
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-build_residual_equation failed\n");
      then
        fail();
  end matchcontinue;
end buildResidualEquation;

protected function buildAssignment 
"function buildAssignment
  This function takes a ComponentRef(cr) and an expression(exp)
  and makes a C++ assignment: cr = exp;"
  input DAE.DAElist inDAElist;
  input Exp.ComponentRef inComponentRef;
  input Exp.Exp inExp;
  input String inString;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist,inComponentRef,inExp,inString,inInteger)
    local
      String cr_str,var,stmt,origname;
      Codegen.CFunction cfn;
      Integer cg_id_1,cg_id;
      DAE.DAElist dae;
      list<DAE.Element> elements;
      Exp.ComponentRef cr;
      Exp.Exp exp;
      Absyn.Path path;
      list<Exp.Exp> args;
      Boolean tuple_,builtin;
    case ((dae as DAE.DAE(elementLst = elements)),cr,(exp as DAE.CALL(path = path,expLst = args,tuple_ = (tuple_ as false),builtin = builtin)),origname,cg_id) /* varname expression orig. name cg var_id cg var_id */
      equation
        cr_str = Exp.printComponentRefStr(cr);
        (cfn,var,cg_id_1) = Codegen.generateExpression(exp, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        cfn = Codegen.cAddStatements(cfn, {stmt});
      then
        (cfn,cg_id_1);
    case (dae,cr,(exp as DAE.CALL(path = path,expLst = args,tuple_ = (tuple_ as true),builtin = builtin)),origname,cg_id)
      equation
        print("-simcodegen: build_assignment: Tuple return values from functions not implemented\n");
      then
        fail();
    case (dae,cr,exp,origname,cg_id)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        (cfn,var,cg_id_1) = Codegen.generateExpression(exp, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        cfn = Codegen.cAddStatements(cfn, {stmt});
      then
        (cfn,cg_id_1);
    case (dae,cr,exp,origname,cg_id)
      equation
        print("-build_assignment failed\n");
      then
        fail();
  end matchcontinue;
end buildAssignment;

public function printExpCppStr "function: printExpCppStr

  This function prints a complete expression on a C/C++ format.
"
  input Exp.Exp e;
  output String s;
algorithm
  s := printExp2Str(e, 0);
end printExpCppStr;

protected function lbinopSymbol "function: lbinopSymbol

  Helper function to print_exp2_str
"
  input Exp.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.AND()) then " && ";
    case (DAE.OR()) then " || ";
  end matchcontinue;
end lbinopSymbol;

protected function lunaryopSymbol 
"function: lunaryopSymbol
  Helper function to print_exp2_str"
  input Exp.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.NOT()) then " !";
  end matchcontinue;
end lunaryopSymbol;

protected function relopSymbol 
"function: relopSymbol
  Helper function to print_exp2_str"
  input Exp.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.LESS(ty = _)) then " < ";
    case (DAE.LESSEQ(ty = _)) then " <= ";
    case (DAE.GREATER(ty = _)) then " > ";
    case (DAE.GREATEREQ(ty = _)) then " >= ";
    case (DAE.EQUAL(ty = _)) then " == ";
    case (DAE.NEQUAL(ty = _)) then " != ";
  end matchcontinue;
end relopSymbol;

public function defineStringToModelicaString 
"function defineStringToModelicaString
  removes the $... from the string and replace the DAELow.derivative_name_prefix to \"der\"
  removes the \"\"\" and replaces with \"\"\" (in case of nestled divisions)
  author x02lucpo"
  input String part_eqn;
  output String part_eqn_1;
  String part_eqn0,part_eqn1,part_eqn2,part_eqn3,part_eqn4,part_eqn_1;
algorithm
  part_eqn0 := Util.cStrToModelicaString(part_eqn);
  part_eqn1 := System.stringReplace(part_eqn0, "\"", "") "replace \"\"\" with \"\"" ;
  part_eqn2 := System.stringReplace(part_eqn1, DAELow.derivativeNamePrefix, "der") "replace derivative prefix with der" ;
  part_eqn3 := System.stringReplace(part_eqn2, "$$", "##") "replace $$ with ##. this is to be able to replace $ with \"\" there are som variables that have the name $$dummy" ;
  part_eqn4 := System.stringReplace(part_eqn3, "$", "");
  part_eqn_1 := System.stringReplace(part_eqn4, "##", "$") "replace back ## with $." ;
end defineStringToModelicaString;

protected function generateDivisionMacro 
"function generateDivisionMacro
  this generates a division macro of the form:
  \"DIVISION(1.0,a$P$bc,\"1.0/a.bc\")\"
  author x02lucpo"
  input String s1;
  input String s2;
  output String res;
  String part_eqn,part_eqn_1;
algorithm
  part_eqn := Util.stringAppendList({s1,"/",s2});
  part_eqn_1 := defineStringToModelicaString(part_eqn) "print \"befor: \" & print part_eqn & print \"\\n\" &" ;
  res := Util.stringAppendList({"DIVISION(",s1,",",s2,",\"",part_eqn_1,"\")"}) "print \"after: \" & print part_eqn\' & print \"\\n\" &" ;
end generateDivisionMacro;

protected function printExp2Str 
"function: printExp2Str
  Helper function to printExpStr"
  input Exp.Exp inExp;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp,inInteger)
    local
      String s,s_1,s_2,res,sym,s1,s2,s3,s4,s_3,res_1,ifstr,thenstr,elsestr,s_4,slast,argstr,fs,s5,s_5,res2,crstr,dimstr,str,expstr,iterstr,id;
      Integer x,pri2_1,pri2,pri3,pri1,ival;
      Real two_1,two,rval;
      Exp.ComponentRef c;
      Exp.Exp e1,e2,e21,e22,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Exp.Operator op;
      Exp.Type ty,ty2,REAL;
      list<Exp.Exp> args,es,sub;
      Boolean builtin;
      Absyn.Path fcn;
      list<Exp.ComponentRef> cref_list;
      
    case (DAE.END(),_)
      equation
        print("# equation contain undefined symbols");
      then
        fail();

    case (DAE.ICONST(integer = x),_)
      equation
        s = intString(x);
      then
        s;

    case (DAE.RCONST(real = x),_)
      local Real x;
      equation
        s = realString(x);
      then
        s;

    case (DAE.SCONST(string = s),_)
      equation
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
      then
        s_2;

    case (DAE.BCONST(bool = false),_) then "false";

    case (DAE.BCONST(bool = true),_) then "true";

    case (DAE.CREF(componentRef = c),_)
      equation
        res = Exp.printComponentRefStr(c);
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = ty)),exp2 = (e2 as DAE.BINARY(exp1 = e21,operator = DAE.SUB(ty = ty2),exp2 = e22))),pri1)
      equation
        sym = Exp.binopSymbol(op);
        pri2_1 = Exp.binopPriority(op);
        pri2 = pri2_1 + 1;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2) "binary minus have higher priority than itself" ;
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.POW(ty = _)),exp2 = DAE.ICONST(integer = 2)),pri1)
      equation
        pri2 = Exp.binopPriority(op) "x^2 => xx" ;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s4 = Exp.printRightparStr(pri1, pri2);
        res = Util.stringAppendList({s1,s2,"*",s2,s4});
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.POW(ty = _)),exp2 = DAE.RCONST(real = two)),pri1)
      equation
        two_1 = intReal(2) "x^2 => xx" ;
        (two ==. two) = true;
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s4 = Exp.printRightparStr(pri1, pri2);
        res = Util.stringAppendList({s1, s2, " * ", s2, s4});
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.POW(ty = _)),exp2 = e2),pri1)
      equation
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend("pow(", s);
        s_2 = stringAppend(s_1, ", ");
        s_3 = stringAppend(s_2, s3);
        res = stringAppend(s_3, ")");
        res_1 = stringAppend(res, s4);
      then
        res_1;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.DIV(ty = _)),exp2 = e2),pri1)
      equation
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        res_1 = generateDivisionMacro(s2, s3) "	 string_append (\"DIVISION(\", s2) => s & string_append(s1,s) => s\' & string_append(s\',\",\") => s\'\' & string_append(s\'\',s3) => s\'\'\' & string_append(s\'\'\',\")\") => res & 	 string_append (res, s4) => res\'" ;
      then
        res_1;

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = Exp.binopSymbol(op);
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.UNARY(operator = op,exp = e),pri1)
      equation
        sym = Exp.unaryopSymbol(op);
        pri2 = Exp.unaryopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, sym);
        s_1 = stringAppend(s, s2);
        s_2 = stringAppend(s_1, s3);
      then
        s_2;

    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = lbinopSymbol(op);
        pri2 = Exp.lbinopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.LUNARY(operator = op,exp = e),pri1)
      equation
        sym = lunaryopSymbol(op);
        pri2 = Exp.lunaryopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, sym);
        s_1 = stringAppend(s, s2);
        s_2 = stringAppend(s_1, s3);
      then
        s_2;

    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = relopSymbol(op);
        pri2 = Exp.relopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f),_)
      local Exp.Exp c;
      equation
        ifstr = printExp2Str(c, 0);
        thenstr = printExp2Str(t, 0);
        elsestr = printExp2Str(f, 0);
        s = stringAppend("(( ", ifstr);
        s_1 = stringAppend(s, " ) ? ( ");
        s_2 = stringAppend(s_1, thenstr);
        s_3 = stringAppend(s_2, " ) : ( ");
        s_4 = stringAppend(s_3, elsestr);
        slast = stringAppend(s_4, " )) ");
      then
        slast;

    case (DAE.CALL(path = Absyn.IDENT(name = "abs"),expLst = args,builtin = (builtin as true)),_) /* abs using the fabs libc function */
      equation
        argstr = Exp.printListStr(args, printExpCppStr, ",");
        s = Util.stringAppendList({"fabs(",argstr,")"});
      then
        s;

    case (DAE.CALL(path = fcn,expLst = args,builtin = (builtin as true)),_)
      equation
        fs = ModUtil.pathStringReplaceDot(fcn, "_");
        argstr = Exp.printListStr(args, printExpCppStr, ",");
        s = Util.stringAppendList({fs,"(",argstr,")"});
      then
        s;

    case (DAE.CALL(path = fcn,expLst = args,builtin = (builtin as false)),_) /* user defined Modelica functions, incl. external starts with an
	   underscore, to distringuish betweeen the lib function for external
	   functions and the wrapper function. */
      equation
        fs = ModUtil.pathStringReplaceDot(fcn, "_");
        argstr = Exp.printListStr(args, printExpCppStr, ",");
        s = Util.stringAppendList({"_",fs,"(",argstr,").",fs,"_rettype_1"});
      then
        s;

    case (DAE.ARRAY(array = es),_)
      equation
        s = Exp.printListStr(es, printExpCppStr, ",");
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;

    case (DAE.TUPLE(PR = es),_)
      equation
        s = Exp.printListStr(es, printExpCppStr, ",");
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case (DAE.MATRIX(scalar = es),_)
      local list<list<tuple<Exp.Exp, Boolean>>> es;
      equation
        s = Exp.printListStr(es, Exp.printRowStr, "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
      then
        s_2;

    case (DAE.RANGE(exp = start,expOption = NONE,range = stop),pri1)
      equation
        pri2 = 41;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(start, pri3);
        s3 = printExp2Str(stop, pri3);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, ":");
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop),pri1)
      equation
        pri2 = 41;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(start, pri3);
        s3 = printExp2Str(step, pri3);
        s4 = printExp2Str(stop, pri3);
        s5 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, ":");
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, ":");
        s_4 = stringAppend(s_3, s4);
        s_5 = stringAppend(s_4, s5);
      then
        s_5;

    case (DAE.CAST(ty = REAL,exp = DAE.ICONST(integer = ival)),_)
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
      then
        res;

    case (DAE.CAST(ty = REAL,exp = DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = DAE.ICONST(integer = ival))),_)
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        res2 = stringAppend("-", res);
      then
        res2;

    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e),_)
      equation
        false = RTOpts.modelicaOutput();
        s = printExpCppStr(e);
        s_1 = stringAppend("(double)(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e),_)
      equation
        true = RTOpts.modelicaOutput();
        s = printExpCppStr(e);
      then
        s;

    case (DAE.ASUB(exp = e,sub = {e1}),pri1)
      equation
        pri2 = 51;
        cref_list = Exp.getCrefFromExp(e);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = Exp.printRightparStr(pri1, pri2);
        s4 = printExp2Str(e1, pri1);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, s3);
        s_2 = stringAppend(s_1, "[");
        s_3 = stringAppend(s_2, s4);
        s_4 = stringAppend(s_3, "]");
      then
        s_4;

    case (DAE.SIZE(exp = cr,sz = SOME(dim)),_)
      equation
        crstr = printExpCppStr(cr);
        dimstr = printExpCppStr(dim);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;

    case (DAE.SIZE(exp = cr,sz = NONE),_)
      equation
        crstr = printExpCppStr(cr);
        str = Util.stringAppendList({"size(",crstr,")"});
      then
        str;

    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),_)
      equation
        fs = Absyn.pathString(fcn);
        expstr = printExpCppStr(exp);
        iterstr = printExpCppStr(iterexp);
        str = Util.stringAppendList({"<reduction>",fs,"(",expstr," for ",id," in ",iterstr,")"});
      then
        str;

    case (_,_) then "#UNKNOWN EXPRESSION# ----eee ";
  end matchcontinue;
end printExp2Str;

public function crefModelicaStr "function: crefModelicaStr

  Converts Exp.ComponentRef, i.e. variables, to Modelica friendly variables.
  This means that dots are converted to underscore, etc.
"
  input Exp.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef)
    local
      String res_1,res_2,res_3,s,ns,ss;
      Exp.ComponentRef n;
    case (DAE.CREF_IDENT(ident = s))
      equation
        res_1 = Util.stringReplaceChar(s, ".", "_");
        res_2 = Util.stringReplaceChar(res_1, "[", "_");
        res_3 = Util.stringReplaceChar(res_2, "]", "_") "& Util.string_append_list({\"_\",res,\"_\"}) => res\'" ;
      then
        res_3;
    case (DAE.CREF_QUAL(ident = s,componentRef = n))
      equation
        ns = crefModelicaStr(n);
        ss = stringAppend(s, ns) "	string_append(s,\"_\") => s1 & s1" ;
      then
        ss;
  end matchcontinue;
end crefModelicaStr;

// For compiling function references - stefan
protected function getReferencedFunctions
"function getReferencedFunctions
	Goes through the DAELow structure, finds all function
	references and returns them in a list. Removes duplicates."
	input DAE.DAElist dae;
	input DAELow.DAELow dlow;
	output list<Absyn.Path> res;
	list<DAE.Exp> explist, fnrefs;
	list<Absyn.ComponentRef> crefs;
	list<Absyn.Path> referencedFuncs;
algorithm
  explist := DAELow.getAllExps(dlow);
  fnrefs := Codegen.getMatchingExpsList(explist, Codegen.matchFnRefs);
  crefs := Util.listMap(fnrefs, getCrefFromExp);
  referencedFuncs := Util.listMap(crefs, Absyn.crefToPath);
  res := removeDuplicatePaths(referencedFuncs);
end getReferencedFunctions;

// For compiling function references - stefan
protected function getCrefFromExp
"function getCrefFromExp
  Assume input Exp is CREF, return the ComponentRef
  fail otherwise"
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
        print("SimCodegen.getCrefFromExp failed: input was not of DAE.CREF type");
      then 
        fail();
  end matchcontinue;
end getCrefFromExp;

public function getCalledFunctions 
"function: getCalledFunctions
  Goes through the DAELow structure, finds all function 
  calls and returns them in a list. Removes duplicates."
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  output list<Absyn.Path> res;
  list<Exp.Exp> explist,fcallexps,fcallexps_1,fcallexps_2;
  list<Absyn.Path> calledfuncs;
algorithm
  explist := DAELow.getAllExps(dlow);
  fcallexps := Codegen.getMatchingExpsList(explist, Codegen.matchCalls);
  fcallexps_1 := Util.listSelect(fcallexps, isNotBuiltinCall);
  fcallexps_2 := Codegen.getMatchingExpsList(explist, Codegen.matchFnRefs);
  calledfuncs := Util.listMap(listAppend(fcallexps_1,fcallexps_2), getCallPath);
  res := removeDuplicatePaths(calledfuncs);
end getCalledFunctions;

public function getCalledFunctionsInFunctions 
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

public function getCalledFunctionsInFunction 
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
        fcallexps = Codegen.getMatchingExpsList(explist, Codegen.matchCalls);
        fcallexps_1 = Util.listSelect(fcallexps, isNotBuiltinCall);
        calledfuncs = Util.listMap(fcallexps_1, getCallPath);
        
        /*-- MetaModelica Partial Function. sjoelund --*/
        
        // stefan - get all arguments of constant T_FUNCTION type and add to list
        fnrefs = Codegen.getMatchingExpsList(explist, Codegen.matchFnRefs);
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
        Debug.fprint("failtrace", "SimCodegen.getCalledFunctionsInFunction failed\n");
      then fail();
  end matchcontinue;
end getCalledFunctionsInFunction;

protected function isNotBuiltinCall 
"function: isNotBuiltinCall
  return true if the given DAE.CALL is a call but not 
  to a builtin function. checks the builtin flag in DAE.CALL"
  input Exp.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Boolean res,builtin;
      Exp.Exp e;
    case DAE.CALL(builtin = builtin)
      equation
        res = boolNot(builtin);
      then
        res;
    case e then false;
  end matchcontinue;
end isNotBuiltinCall;

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

public function getFunctionRefVarPath 
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
    case DAE.FUNCTION(functions = {DAE.FUNCTION_DEF(DAE.DAE(out))}) then out;
    case DAE.FUNCTION(functions = {DAE.FUNCTION_EXT(body=DAE.DAE(out))}) then out;
  end matchcontinue;
end getFunctionElementsList;

protected function removeDuplicatePaths 
"function: removeDuplicatePaths
  Removed duplicate Paths in a list of Path."
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
"function: removePathFromList
  Helper function to removeDuplicatePaths."
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

protected function useZerocrossing
  output Boolean res_1;
  Boolean res,res_1;
algorithm
  res := RTOpts.debugFlag("noevents");
  res_1 := boolNot(res);
end useZerocrossing;

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
        print("-SimCodegen.generateEquationOrder failed\n");
      then
        fail();
  end matchcontinue;
end generateEquationOrder;

// ********** END COPY FROM SIMCODEGEN MODULE **********

end SimCode;
