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
public import BackendDAE;
public import DAE;
public import HpcOmScheduler;

public
type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
type ExtDestructor = tuple<String, DAE.ComponentRef>;
type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;
type JacobianColumn = tuple<list<SimEqSystem>, list<SimVar>, String>;     // column equations, column vars, column length
type JacobianMatrix = tuple<list<JacobianColumn>,                         // column
                            list<SimVar>,                                 // seed vars
                            String,                                       // matrix name
                            tuple<list<tuple<DAE.ComponentRef,list<DAE.ComponentRef>>>,tuple<list<SimVar>,list<SimVar>>>,    // sparse pattern
                            list<list<DAE.ComponentRef>>,                 // colored cols
                            Integer>;                                     // max color used


public constant list<DAE.Exp> listExpLength1 = {DAE.ICONST(0)} "For CodegenC.tpl";
public constant list<Variable> boxedRecordOutVars = VARIABLE(DAE.CREF_IDENT("",DAE.T_COMPLEX_DEFAULT_RECORD,{}),DAE.T_COMPLEX_DEFAULT_RECORD,NONE(),{},DAE.NON_PARALLEL())::{} "For CodegenC.tpl";

uniontype SimCode
  "Root data structure containing information required for templates to
  generate simulation code for a Modelica model."
  record SIMCODE
    ModelInfo modelInfo;
    list<DAE.Exp> literals "shared literals";
    list<RecordDeclaration> recordDecls;
    list<String> externalFunctionIncludes;
    list<SimEqSystem> allEquations;
    list<list<SimEqSystem>> odeEquations;
    list<list<SimEqSystem>> algebraicEquations;
    list<SimEqSystem> residualEquations;
    Boolean useSymbolicInitialization "true if a system to solve the initial problem symbolically is generated, otherwise false";
    Boolean useHomotopy "true if homotopy(...) is used during initialization";
    list<SimEqSystem> initialEquations;
    list<SimEqSystem> startValueEquations;
    list<SimEqSystem> nominalValueEquations;
    list<SimEqSystem> minValueEquations;
    list<SimEqSystem> maxValueEquations;
    list<SimEqSystem> parameterEquations;
    list<SimEqSystem> inlineEquations;
    list<SimEqSystem> removedEquations;
    list<SimEqSystem> algorithmAndEquationAsserts;
    list<SimEqSystem> equationsForZeroCrossings;
    list<SimEqSystem> jacobianEquations;
    //list<DAE.Statement> algorithmAndEquationAsserts;
    list<StateSet> stateSets;
    list<DAE.Constraint> constraints;
    list<DAE.ClassAttributes> classAttributes;
    list<BackendDAE.ZeroCrossing> zeroCrossings;
    list<BackendDAE.ZeroCrossing> relations;
    list<BackendDAE.TimeEvent> timeEvents;
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
    Option<HpcOmScheduler.ScheduleSimCode> hpcOmSchedule;
    Option<BackendMapping> backendMapping;
  end SIMCODE;
end SimCode;

public
uniontype BackendMapping
  record BACKENDMAPPING
    BackendDAE.IncidenceMatrix m;
    BackendDAE.IncidenceMatrixT mT;
    list<tuple<Integer,list<Integer>>> eqMapping; //indx:order <simEq,{backendEq}>
    list<tuple<Integer,Integer>> varMapping;  //<simVar,backendVar>
  end BACKENDMAPPING;
  record NO_MAPPING
  end NO_MAPPING;
end BackendMapping;

uniontype DelayedExpression
  "Delayed expressions type"
  record DELAYED_EXPRESSIONS
    list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
    Integer maxDelayedIndex;
  end DELAYED_EXPRESSIONS;
end DelayedExpression;

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

uniontype ModelInfo "Container for metadata about a Modelica model."
  record MODELINFO
    Absyn.Path name;
    String description;
    String directory;
    VarInfo varInfo;
    SimVars vars;
    list<Function> functions;
    list<String> labels;
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

uniontype VarInfo "Number of variables of various types in a Modelica model."
  record VARINFO
    Integer numZeroCrossings;
    Integer numTimeEvents;
    Integer numRelations;
    Integer numMathEventFunctions;
    Integer numStateVars;
    Integer numInlineVars;
    Integer numAlgVars;
    Integer numDiscreteReal;
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
    Integer numInitialEquations;
    Integer numInitialAlgorithms;
    Integer numInitialResiduals "numInitialEquations + numInitialAlgorithms";
    Integer numExternalObjects;
    Integer numStringAlgVars;
    Integer numStringParamVars;
    Integer numStringAliasVars;
    Integer numEquations;
    Integer numLinearSystems;
    Integer numNonLinearSystems;
    Integer numMixedSystems;
    Integer numStateSets;
    Integer numOptimizeConstraints;
  end VARINFO;
end VarInfo;

uniontype SimVars "Container for metadata about variables in a Modelica model."
  record SIMVARS
    list<SimVar> stateVars;
    list<SimVar> derivativeVars;
    list<SimVar> inlineVars;
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
    list<SimVar> jacobianVars;
    list<SimVar> realOptimizeConstraintsVars;
  end SIMVARS;
end SimVars;

public constant SimVars emptySimVars = SIMVARS({}, {}, {}, {}, {}, {}, {}, {},
  {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},{});

uniontype SimVar "Information about a variable in a Modelica model."
  record SIMVAR
    DAE.ComponentRef name;
    BackendDAE.VarKind varKind;
    String comment;
    String unit;
    String displayUnit;
    Integer index;
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
    AliasVariable aliasvar;
    DAE.ElementSource source;
    Causality causality;
    Option<Integer> variable_index;
    list<String> numArrayElement;
    Boolean isValueChangeable;
    Boolean isProtected;
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

// TODO: I believe some of these fields can be removed. Check to see what is
//       used in templates.
uniontype Function
  "Represents a Modelica or MetaModelica function."
  record FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<Statement> body;
    Absyn.Info info;
  end FUNCTION;

  record PARALLEL_FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<Statement> body;
    Absyn.Info info;
  end PARALLEL_FUNCTION;

  record KERNEL_FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<Statement> body;
    Absyn.Info info;
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
    Absyn.Info info;
    Boolean dynamicLoad;
  end EXTERNAL_FUNCTION;

  record RECORD_CONSTRUCTOR
    Absyn.Path name;
    list<Variable> funArgs;
    list<Variable> locals;
    Absyn.Info info;
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
  end VARIABLE;

  record FUNCTION_PTR
    String name;
    list<DAE.Type> tys;
    list<Variable> args;
  end FUNCTION_PTR;
end Variable;

// TODO: Replace Statement with just list<DAE.Statement>?
uniontype Statement
  record ALGORITHM
    list<DAE.Statement> statementLst; // in functions
  end ALGORITHM;
end Statement;

uniontype SimEqSystem
  "Represents a single equation or a system of equations that must be solved together."
  record SES_RESIDUAL
    Integer index;
    DAE.Exp exp;
    DAE.ElementSource source;
  end SES_RESIDUAL;

  record SES_SIMPLE_ASSIGN
    Integer index;
    DAE.ComponentRef cref;
    DAE.Exp exp;
    DAE.ElementSource source;
  end SES_SIMPLE_ASSIGN;

  record SES_ARRAY_CALL_ASSIGN
    Integer index;
    DAE.ComponentRef componentRef;
    DAE.Exp exp;
    DAE.ElementSource source;
  end SES_ARRAY_CALL_ASSIGN;

  record SES_IFEQUATION
    Integer index;
    list<tuple<DAE.Exp,list<SimEqSystem>>> ifbranches;
    list<SimEqSystem> elsebranch;
    DAE.ElementSource source;
  end SES_IFEQUATION;

  record SES_ALGORITHM
    Integer index;
    list<DAE.Statement> statements;
  end SES_ALGORITHM;

  record SES_LINEAR
    Integer index;
    Boolean partOfMixed;
    list<SimVar> vars;
    list<DAE.Exp> beqs;
    list<tuple<Integer, Integer, SimEqSystem>> simJac;
    Integer indexLinearSystem;
  end SES_LINEAR;

  record SES_NONLINEAR
    Integer index;
    list<SimEqSystem> eqs;
    list<DAE.ComponentRef> crefs;
    Integer indexNonLinearSystem;
    Option<JacobianMatrix> jacobianMatrix;
    Boolean linearTearing;
  end SES_NONLINEAR;

  record SES_MIXED
    Integer index;
    SimEqSystem cont;
    list<SimVar> discVars;
    list<SimEqSystem> discEqs;
    Integer indexMixedSystem;
  end SES_MIXED;

  record SES_WHEN
    Integer index;
    list<DAE.ComponentRef> conditions "list of boolean variables as conditions";
    Boolean initialCall "true, if top-level branch with initial()";
    DAE.ComponentRef left;
    DAE.Exp right;
    Option<SimEqSystem> elseWhen;
    DAE.ElementSource source;
  end SES_WHEN;
end SimEqSystem;

uniontype StateSet
  record SES_STATESET
    Integer index;
    Integer nCandidates;
    Integer nStates;
    list<DAE.ComponentRef> states;
    list<DAE.ComponentRef> statescandidates;
    DAE.ComponentRef crA;
    JacobianMatrix jacobianMatrix;
  end SES_STATESET;
end StateSet;

uniontype SimWhenClause
  record SIM_WHEN_CLAUSE
    list<DAE.ComponentRef> conditionVars "is no longer needed";
    list<DAE.ComponentRef> conditions "list of boolean variables as conditions";
    Boolean initialCall "true, if top-level branch with initial()";
    list<BackendDAE.WhenOperator> reinits;
    Option<BackendDAE.WhenEquation> whenEq;
  end SIM_WHEN_CLAUSE;
end SimWhenClause;

uniontype ExtObjInfo
  record EXTOBJINFO
    list<SimVar> vars;
    list<ExtAlias> aliases;
  end EXTOBJINFO;
end ExtObjInfo;

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
    String platform;
    String compileDir;
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
   end JACOBIAN_CONTEXT;

  record OTHER_CONTEXT
  end OTHER_CONTEXT;

  record INLINE_CONTEXT
  end INLINE_CONTEXT;

  record PARALLEL_FUNCTION_CONTEXT
  end PARALLEL_FUNCTION_CONTEXT;

  record ZEROCROSSINGS_CONTEXT
  end ZEROCROSSINGS_CONTEXT;

  record OPTIMIZATION_CONTEXT
  end OPTIMIZATION_CONTEXT;
end Context;

public constant Context contextSimulationNonDiscrete  = SIMULATION_CONTEXT(false);
public constant Context contextSimulationDiscrete     = SIMULATION_CONTEXT(true);
public constant Context contextInlineSolver           = INLINE_CONTEXT();
public constant Context contextFunction               = FUNCTION_CONTEXT();
public constant Context contextJacobian               = JACOBIAN_CONTEXT();
public constant Context contextAlgloopJacobian        = ALGLOOP_CONTEXT(false,true);
public constant Context contextAlgloopInitialisation  = ALGLOOP_CONTEXT(true,false);
public constant Context contextAlgloop                = ALGLOOP_CONTEXT(false,false);
public constant Context contextOther                  = OTHER_CONTEXT();
public constant Context contextParallelFunction       = PARALLEL_FUNCTION_CONTEXT();
public constant Context contextZeroCross              = ZEROCROSSINGS_CONTEXT();
public constant Context contextOptimization           = OPTIMIZATION_CONTEXT();

/****** HashTable ComponentRef -> SimCode.SimVar ******/
/* a workaround to enable "cross public import" */

/* HashTable instance specific code */
public
type Key = DAE.ComponentRef;
type Value = SimVar;
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
end SimCode;
