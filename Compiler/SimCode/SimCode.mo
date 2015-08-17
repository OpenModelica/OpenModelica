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

  RCS: $Id: SimCode.mo 25853 2015-04-30 14:04:02Z vwaurich $

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
public import HashTableCrILst;
public import HashTableCrIListArray;
public import HpcOmSimCode;
public import SimCodeVar;
public import SCode;

public
type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
type ExtDestructor = tuple<String, DAE.ComponentRef>;
type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;
type JacobianColumn = tuple<list<SimEqSystem>, list<SimCodeVar.SimVar>, String>;     // column equations, column vars, column length
type JacobianMatrix = tuple<list<JacobianColumn>,                         // column
                            list<SimCodeVar.SimVar>,                      // seed vars
                            String,                                       // matrix name
                            tuple<list< tuple<Integer, list<Integer>>>,list< tuple<Integer, list<Integer>>>>,    // sparse pattern
                            list<list<Integer>>,                          // colored cols
                            Integer,                                      // max color used
                            Integer>;                                     // jacobian index


public constant list<DAE.Exp> listExpLength1 = {DAE.ICONST(0)} "For CodegenC.tpl";
public constant list<Variable> boxedRecordOutVars = VARIABLE(DAE.CREF_IDENT("",DAE.T_COMPLEX_DEFAULT_RECORD,{}),DAE.T_COMPLEX_DEFAULT_RECORD,NONE(),{},DAE.NON_PARALLEL(),DAE.VARIABLE())::{} "For CodegenC.tpl";

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
    list<ClockedPartition> clockedPartitions;
    Boolean useHomotopy "true if homotopy(...) is used during initialization";
    list<SimEqSystem> initialEquations;
    list<SimEqSystem> removedInitialEquations;
    list<SimEqSystem> startValueEquations;
    list<SimEqSystem> nominalValueEquations;
    list<SimEqSystem> minValueEquations;
    list<SimEqSystem> maxValueEquations;
    list<SimEqSystem> parameterEquations;
    list<SimEqSystem> removedEquations;
    list<SimEqSystem> algorithmAndEquationAsserts;
    list<SimEqSystem> equationsForZeroCrossings;
    list<SimEqSystem> jacobianEquations;
    //list<DAE.Statement> algorithmAndEquationAsserts;
    list<StateSet> stateSets;
    list<DAE.Constraint> constraints;
    list<DAE.ClassAttributes> classAttributes;
    list<BackendDAE.ZeroCrossing> zeroCrossings;
    list<BackendDAE.ZeroCrossing> relations "only used by c runtime";
    list<BackendDAE.TimeEvent> timeEvents "only used by c runtime yet";
    list<DAE.ComponentRef> discreteModelVars;
    ExtObjInfo extObjInfo;
    MakefileParams makefileParams;
    DelayedExpression delayedExps;
    list<JacobianMatrix> jacobianMatrixes;
    Option<SimulationSettings> simulationSettingsOpt;
    String fileNamePrefix;
    HpcOmSimCode.HpcOmData hpcomData;
    //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
    //if the variable is not part of an array (if it is a scalar value), then the array has size 1
    HashTableCrIListArray.HashTable varToArrayIndexMapping;
    //*** a protected section *** not exported to SimCodeTV
    HashTableCrILst.HashTable varToIndexMapping;
    HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
    Option<BackendMapping> backendMapping;
    //FMI 2.0 data for model structure
    Option<FmiModelStructure> modelStructure;
  end SIMCODE;
end SimCode;

public uniontype ClockedPartition
  record CLOCKED_PARTITION
    DAE.ClockKind baseClock;
    list<SubPartition> subPartitions;
  end CLOCKED_PARTITION;
end ClockedPartition;

public uniontype SubPartition
  record SUBPARTITION
    list<SimEqSystem> equations;
    list<SimEqSystem> removedEquations;
    BackendDAE.SubClock subClock;
    Boolean holdEvents;
  end SUBPARTITION;
end SubPartition;

public
uniontype BackendMapping
  record BACKENDMAPPING
    BackendDAE.IncidenceMatrix m;
    BackendDAE.IncidenceMatrixT mT;
    list<tuple<Integer,list<Integer>>> eqMapping; //indx:order <simEq,{backendEq}>
    list<tuple<Integer,Integer>> varMapping;  //<simVar,backendVar>
    array<Integer> eqMatch;  //indx:eq entry:var
    array<Integer> varMatch;  //indx:var entry:eq
    array<list<Integer>> eqTree;  // arrayIndx:eq list:required eqs
    array<list<SimCodeVar.SimVar>> simVarMapping; //indx: backendVar-idx entry: simVar-obj
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
    SimCodeVar.SimVars vars;
    list<Function> functions;
    list<String> labels;
    //Files files "all the files from SourceInfo and DAE.ELementSource";
    Integer maxDer "the highest derivative in the model";
    Integer nClocks;
    Integer nSubClocks;
  end MODELINFO;
end ModelInfo;

type Files = list<FileInfo>;

uniontype FileInfo
  "contains all the .mo files present in all SourceInfo and DAE.ElementSource.info
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
    Integer numExternalObjects;
    Integer numStringAlgVars;
    Integer numStringParamVars;
    Integer numStringAliasVars;
    Integer numEquations;
    Integer numLinearSystems;
    Integer numNonLinearSystems;
    Integer numMixedSystems;
    Integer numStateSets;
    Integer numJacobians;
    Integer numOptimizeConstraints;
    Integer numOptimizeFinalConstraints;
  end VARINFO;
end VarInfo;

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
    SCode.Visibility visibility;
    SourceInfo info;
  end FUNCTION;

  record PARALLEL_FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<Statement> body;
    SourceInfo info;
  end PARALLEL_FUNCTION;

  record KERNEL_FUNCTION
    Absyn.Path name;
    list<Variable> outVars;
    list<Variable> functionArguments;
    list<Variable> variableDeclarations;
    list<Statement> body;
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
    DAE.VarKind kind;
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
    DAE.VarKind kind;
  end VARIABLE;

  record FUNCTION_PTR
    String name;
    list<DAE.Type> tys;
    list<Variable> args;
    Option<DAE.Exp> defaultValue "default value";
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
    DAE.Exp lhs;
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

  record SES_INVERSE_ALGORITHM
    "this should only occur inside SES_NONLINEAR"
    Integer index;
    list<DAE.Statement> statements;
    list<DAE.ComponentRef> knownOutputCrefs "this is a subset of output crefs of the original algorithm, which are already known";
  end SES_INVERSE_ALGORITHM;

  record SES_LINEAR
    LinearSystem lSystem;
    Option<LinearSystem> alternativeTearing;
  end SES_LINEAR;

  record SES_NONLINEAR
    NonlinearSystem nlSystem;
    Option<NonlinearSystem> alternativeTearing;
  end SES_NONLINEAR;

  record SES_MIXED
    Integer index;
    SimEqSystem cont;
    list<SimCodeVar.SimVar> discVars;
    list<SimEqSystem> discEqs;
    Integer indexMixedSystem;
  end SES_MIXED;

  record SES_WHEN
    Integer index;
    list<DAE.ComponentRef> conditions "list of boolean variables as conditions";
    Boolean initialCall "true, if top-level branch with initial()";
    list<BackendDAE.WhenOperator> whenStmtLst;
    Option<SimEqSystem> elseWhen;
    DAE.ElementSource source;
  end SES_WHEN;

  record SES_FOR_LOOP
    Integer index;
    DAE.Exp iter;
    DAE.Exp startIt;
    DAE.Exp endIt;
    DAE.ComponentRef cref;//lhs
    DAE.Exp exp;//rhs
    DAE.ElementSource source;
  end SES_FOR_LOOP;

end SimEqSystem;

public
uniontype LinearSystem
  record LINEARSYSTEM
    Integer index;
    Boolean partOfMixed;
    list<SimCodeVar.SimVar> vars;
    list<DAE.Exp> beqs;
    list<tuple<Integer, Integer, SimEqSystem>> simJac;
    /* solver linear tearing system */
    list<SimEqSystem> residual;
    Option<JacobianMatrix> jacobianMatrix;
    list<DAE.ElementSource> sources;
    Integer indexLinearSystem;
  end LINEARSYSTEM;
end LinearSystem;

public
uniontype NonlinearSystem
  record NONLINEARSYSTEM
    Integer index;
    list<SimEqSystem> eqs;
    list<DAE.ComponentRef> crefs;
    Integer indexNonLinearSystem;
    Option<JacobianMatrix> jacobianMatrix;
    Boolean linearTearing;
    Boolean homotopySupport;
    Boolean mixedSystem;
  end NONLINEARSYSTEM;
end NonlinearSystem;

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

uniontype ExtObjInfo
  record EXTOBJINFO
    list<SimCodeVar.SimVar> vars;
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
    list<String> libPaths;
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

  record PARALLEL_FUNCTION_CONTEXT
  end PARALLEL_FUNCTION_CONTEXT;

  record ZEROCROSSINGS_CONTEXT
  end ZEROCROSSINGS_CONTEXT;

  record OPTIMIZATION_CONTEXT
  end OPTIMIZATION_CONTEXT;

  record FMI_CONTEXT
  end FMI_CONTEXT;
end Context;

public constant Context contextSimulationNonDiscrete  = SIMULATION_CONTEXT(false);
public constant Context contextSimulationDiscrete     = SIMULATION_CONTEXT(true);
public constant Context contextFunction               = FUNCTION_CONTEXT();
public constant Context contextJacobian               = JACOBIAN_CONTEXT();
public constant Context contextAlgloopJacobian        = ALGLOOP_CONTEXT(false,true);
public constant Context contextAlgloopInitialisation  = ALGLOOP_CONTEXT(true,false);
public constant Context contextAlgloop                = ALGLOOP_CONTEXT(false,false);
public constant Context contextOther                  = OTHER_CONTEXT();
public constant Context contextParallelFunction       = PARALLEL_FUNCTION_CONTEXT();
public constant Context contextZeroCross              = ZEROCROSSINGS_CONTEXT();
public constant Context contextOptimization           = OPTIMIZATION_CONTEXT();
public constant Context contextFMI                    = FMI_CONTEXT();

/****** HashTable ComponentRef -> SimCodeVar.SimVar ******/
/* a workaround to enable "cross public import" */

/* HashTable instance specific code */
public
type Key = DAE.ComponentRef;
type Value = SimCodeVar.SimVar;
/* end of HashTable instance specific code */

/* Generic hashtable code below!! */
public
uniontype HashTableCrefToSimVar
  record HASHTABLE
    array<list<tuple<Key,Integer>>> hashTable " hashtable to translate Key to array indx";
    ValueArray valueArr "Array of values";
    Integer bucketSize "bucket size";
    Integer numberOfEntries "number of entries in hashtable";
  end HASHTABLE;
end HashTableCrefToSimVar;

uniontype ValueArray "array of values are expandable, to amortize the cost of adding elements in a more
efficient manner"
  record VALUE_ARRAY
    Integer numberOfElements "number of elements in hashtable";
    Integer arrSize "size of crefArray";
    array<Option<tuple<Key,Value>>> valueArray "array of values";
  end VALUE_ARRAY;
end ValueArray;

/* FMI 2.0 Export */
public uniontype FmiUnknown
  record FMIUNKNOWN
    Integer index;
    list<Integer> dependencies;
    list<String> dependenciesKind;
  end FMIUNKNOWN;
end FmiUnknown;

public uniontype FmiOutputs
  record FMIOUTPUTS
    list<FmiUnknown> fmiUnknownsList;
  end FMIOUTPUTS;
end FmiOutputs;

public uniontype FmiDerivatives
  record FMIDERIVATIVES
    list<FmiUnknown> fmiUnknownsList;
  end FMIDERIVATIVES;
end FmiDerivatives;

public uniontype FmiInitialUnknowns
  record FMIINITIALUNKNOWNS
    list<FmiUnknown> fmiUnknownsList;
  end FMIINITIALUNKNOWNS;
end FmiInitialUnknowns;

public uniontype FmiModelStructure
  record FMIMODELSTRUCTURE
    FmiOutputs fmiOutputs;
    FmiDerivatives fmiDerivatives;
    FmiInitialUnknowns fmiInitialUnknowns;
  end FMIMODELSTRUCTURE;
end FmiModelStructure;

annotation(__OpenModelica_Interface="backend");
end SimCode;
