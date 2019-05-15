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


  The entry points to this module are the translateModel function and the
  translateFunctions function.

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
import Absyn;
import AvlTreeCRToInt;
import BackendDAE;
import DAE;
import HashTable;
import HashTableCrILst;
import HashTableCrIListArray;
import HashTableCrefSimVar;
import HpcOmSimCode;
import SimCodeFunction;
import SimCodeVar;

type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
type ExtDestructor = tuple<String, DAE.ComponentRef>;
type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;

type SparsityPattern = list< tuple<Integer, list<Integer>> >;

uniontype JacobianColumn
  record JAC_COLUMN
    list<SimEqSystem> columnEqns;       // column equations equals in size to column vars
    list<SimCodeVar.SimVar> columnVars; // all column vars, none results vars index -1, the other corresponding to rows index
    Integer numberOfResultVars;         // corresponds to the number of rows
  end JAC_COLUMN;
end JacobianColumn;

uniontype JacobianMatrix
  record JAC_MATRIX
    list<JacobianColumn> columns;       // columns equations and variables
    list<SimCodeVar.SimVar> seedVars;   // corresponds to the number of columns
    String matrixName;                  // unique matrix name
    SparsityPattern sparsity;
    SparsityPattern sparsityT;
    list<list<Integer>> coloredCols;
    Integer maxColorCols;
    Integer jacobianIndex;
    Integer partitionIndex;
    Option<HashTableCrefSimVar.HashTable> crefsHT; // all jacobian variables
  end JAC_MATRIX;
end JacobianMatrix;

constant JacobianMatrix emptyJacobian = JAC_MATRIX({}, {}, "", {}, {}, {}, 0, -1, 0, NONE());

constant PartitionData emptyPartitionData = PARTITIONDATA(-1,{},{},{});


uniontype SimCode
  "Root data structure containing information required for templates to
  generate simulation code for a Modelica model."
  record SIMCODE
    ModelInfo modelInfo;
    list<DAE.Exp> literals "shared literals";
    list<SimCodeFunction.RecordDeclaration> recordDecls;
    list<String> externalFunctionIncludes;
    list<SimEqSystem> localKnownVars "state and input dependent variables, that are not inserted into any partion";
    list<SimEqSystem> allEquations;
    list<list<SimEqSystem>> odeEquations;
    list<list<SimEqSystem>> algebraicEquations;
    list<ClockedPartition> clockedPartitions;
    list<SimEqSystem> initialEquations;
    list<SimEqSystem> initialEquations_lambda0;
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
    SimCodeFunction.MakefileParams makefileParams;
    DelayedExpression delayedExps;
    list<JacobianMatrix> jacobianMatrixes;
    Option<SimulationSettings> simulationSettingsOpt;
    String fileNamePrefix, fullPathPrefix "Used in FMI where files are generated in a special directory";
    String fmuTargetName;
    HpcOmSimCode.HpcOmData hpcomData;
    AvlTreeCRToInt.Tree valueReferences "Used in FMI";
    //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
    //if the variable is not part of an array (if it is a scalar value), then the array has size 1
    HashTableCrIListArray.HashTable varToArrayIndexMapping;
    //*** a protected section *** not exported to SimCodeTV
    HashTableCrILst.HashTable varToIndexMapping;
    HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
    HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
    Option<BackendMapping> backendMapping;
    //FMI 2.0 data for model structure
    Option<FmiModelStructure> modelStructure;
    PartitionData partitionData;
    Option<DaeModeData> daeModeData;
    list<SimEqSystem> inlineEquations;
    Option<OMSIData> omsiData "used for OMSI to generate equations code";
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
    list<tuple<SimCodeVar.SimVar, Boolean /*previous*/>> vars;
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

public uniontype PartitionData
  record PARTITIONDATA
    Integer numPartitions;
    list<list<Integer>> partitions; // which equations are assigned to the partitions
    list<list<Integer>> activatorsForPartitions; // which activators can activate each partition
    list<Integer> stateToActivators; // which states belong to which activator, important if various states are gathered in one partition/activator
  end PARTITIONDATA;
end PartitionData;

uniontype DelayedExpression
  "Delayed expressions type"
  record DELAYED_EXPRESSIONS
    list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
    Integer maxDelayedIndex;
  end DELAYED_EXPRESSIONS;
end DelayedExpression;

uniontype ModelInfo "Container for metadata about a Modelica model."
  record MODELINFO
    Absyn.Path name;
    String description;
    String directory;
    VarInfo varInfo;
    SimCodeVar.SimVars vars;
    list<SimCodeFunction.Function> functions;
    list<String> labels;
    list<String> resourcePaths "Paths of all resources used by the model. Used in FMI2 to package resources in the FMU.";
    list<Absyn.Class> sortedClasses;
    //Files files "all the files from SourceInfo and DAE.ElementSource";
    Integer nClocks;
    Integer nSubClocks;
    Boolean hasLargeLinearEquationSystems; // True if model has large linear eq. systems that are crucial for performance.
    list<SimEqSystem> linearSystems;
    list<SimEqSystem> nonLinearSystems;
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
    Integer numSensitivityParameters;
    Integer numSetcVars;
  end VARINFO;
end VarInfo;

uniontype DaeModeConfig
  record ALL_EQUATIONS end ALL_EQUATIONS;
  record DYNAMIC_EQUATIONS end DYNAMIC_EQUATIONS;
end DaeModeConfig;

uniontype DaeModeData
  "contains data that belongs to the dae mode"
  record DAEMODEDATA
    list<list<SimEqSystem>> daeEquations "daeModel residuals equations";
    Option<JacobianMatrix> sparsityPattern "contains the sparsity pattern for the daeMode";
    list<SimCodeVar.SimVar> residualVars "variable used to calculate residuals of a DAE form, they are real";
    list<SimCodeVar.SimVar> algebraicVars;
    list<SimCodeVar.SimVar> auxiliaryVars;
    DaeModeConfig modeCreated; // indicates the mode in which
  end DAEMODEDATA;
end DaeModeData;

uniontype OMSIData
  "contains data for code generation for OMSI"
  record OMSI_DATA
    OMSIFunction initialization "contains equations and variables for initialization problem";
    OMSIFunction simulation "contains equations and variables for simulation problem";
  end OMSI_DATA;
end OMSIData;

uniontype OMSIFunction
  "contains equations and variables for initialization or simulation problem"
  record OMSI_FUNCTION
    list<SimEqSystem>       equations   "causalized list of single equations and systems of equations";
    list<SimCodeVar.SimVar> inputVars   "list of simcode variables determining input variables for equation(s)";
    list<SimCodeVar.SimVar> outputVars  "list of simcode variables determining output variables for equation(s)";
    list<SimCodeVar.SimVar> innerVars   "list of simcode variables determining inner variables for equation(s), e.g $DER(x)";
    Integer nAllVars                    "number of input, inner and output vars";
    SimCodeFunction.Context context     "contains crefToSimVar hash table for lookup function in templates";
    Integer nAlgebraicSystems           "number of linear and non-linear algebraic systems in OMSI_FUNCTION.equations";
  end OMSI_FUNCTION;
end OMSIFunction;

public constant
OMSIFunction emptyOMSIFunction = OMSI_FUNCTION(equations = {},
                                               inputVars = {},
                                               outputVars = {},
                                               innerVars = {},
                                               nAllVars = 0,
                                               context = SimCodeFunction.contextOMSI,
                                               nAlgebraicSystems = 0);


uniontype SimEqSystem
  "Represents a single equation or a system of equations that must be solved together."
  record SES_RESIDUAL
    Integer index;
    DAE.Exp exp;
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;
  end SES_RESIDUAL;

  record SES_SIMPLE_ASSIGN
    Integer index;
    DAE.ComponentRef cref "left hand side of equation";
    DAE.Exp exp;
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;
  end SES_SIMPLE_ASSIGN;

  record SES_SIMPLE_ASSIGN_CONSTRAINTS
    "Solved inner equation of (casual) tearing set (Dynamic Tearing) with constraints on the solvability"
    Integer index;
    DAE.ComponentRef cref;
    DAE.Exp exp;
    DAE.ElementSource source;
    BackendDAE.Constraints cons;
    BackendDAE.EquationAttributes eqAttr;
  end SES_SIMPLE_ASSIGN_CONSTRAINTS;

  record SES_ARRAY_CALL_ASSIGN
    Integer index;
    DAE.Exp lhs;
    DAE.Exp exp;
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;
  end SES_ARRAY_CALL_ASSIGN;

  record SES_IFEQUATION
    Integer index;
    list<tuple<DAE.Exp,list<SimEqSystem>>> ifbranches;
    list<SimEqSystem> elsebranch;
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;
  end SES_IFEQUATION;

  record SES_ALGORITHM
    Integer index;
    list<DAE.Statement> statements;
    BackendDAE.EquationAttributes eqAttr;
  end SES_ALGORITHM;

  record SES_INVERSE_ALGORITHM
    Integer index;
    list<DAE.Statement> statements;
    list<DAE.ComponentRef> knownOutputCrefs "this is a subset of output crefs of the original algorithm, which are already known";
    Boolean insideNonLinearSystem;
    BackendDAE.EquationAttributes eqAttr;
  end SES_INVERSE_ALGORITHM;

  record SES_LINEAR
    LinearSystem lSystem;
    Option<LinearSystem> alternativeTearing;
    BackendDAE.EquationAttributes eqAttr;
  end SES_LINEAR;

  record SES_NONLINEAR
    NonlinearSystem nlSystem;
    Option<NonlinearSystem> alternativeTearing;
    BackendDAE.EquationAttributes eqAttr;
  end SES_NONLINEAR;

  record SES_MIXED
    Integer index;
    SimEqSystem cont;
    list<SimCodeVar.SimVar> discVars;
    list<SimEqSystem> discEqs;
    Integer indexMixedSystem;
    BackendDAE.EquationAttributes eqAttr;
  end SES_MIXED;

  record SES_WHEN
    Integer index;
    list<DAE.ComponentRef> conditions "list of boolean variables as conditions";
    Boolean initialCall "true, if top-level branch with initial()";
    list<BackendDAE.WhenOperator> whenStmtLst;
    Option<SimEqSystem> elseWhen;
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;
  end SES_WHEN;

  record SES_FOR_LOOP
    Integer index;
    DAE.Exp iter;
    DAE.Exp startIt;
    DAE.Exp endIt;
    DAE.ComponentRef cref;//lhs
    DAE.Exp exp;//rhs
    DAE.ElementSource source;
    BackendDAE.EquationAttributes eqAttr;
  end SES_FOR_LOOP;

  record SES_ALIAS
    Integer index;
    Integer aliasOf;
  end SES_ALIAS;

  record SES_ALGEBRAIC_SYSTEM
    Integer index "equation index";
    Integer algSysIndex "index of algebraic system";

    Integer dim_n "dimension of algebraic loop (after tearing)";

    Boolean partOfMixed;
    Boolean tornSystem;
    Boolean linearSystem;

    // residual.inputVars = dependentVars
    // residual.innerVars = otherTearingVars
    // residual.outputVars = iterationsVars
    OMSIFunction residual; // linear: A*x-b = res
                           // non-linear: f(x) = res

    Option<DerivativeMatrix> matrix;  // linear => A
                                      // non-linear => f'(x)

    list<Integer> zeroCrossingConditions;

    list<DAE.ElementSource> sources;
    BackendDAE.EquationAttributes eqAttr;
  end SES_ALGEBRAIC_SYSTEM;

end SimEqSystem;


public
uniontype DerivativeMatrix
  "represents directional derivatives with sparsity and coloring"
  record DERIVATIVE_MATRIX
    list<OMSIFunction> columns;         // column(s) equations and variables
                                        // inputVars:  seedVars
                                        // innerVars:  inner column vars
                                        // outputVars: result vars of the column

    String matrixName "unique matrix name";
    SparsityPattern sparsity;
    SparsityPattern sparsityT;
    list<list<Integer>> coloredCols;
    Integer maxColorCols;
  end DERIVATIVE_MATRIX;
end DerivativeMatrix;

public
uniontype LinearSystem
  record LINEARSYSTEM
    Integer index;
    Boolean partOfMixed;
    Boolean tornSystem;
    list<SimCodeVar.SimVar> vars;
    list<DAE.Exp> beqs;
    list<tuple<Integer, Integer, SimEqSystem>> simJac;
    /* solver linear tearing system */
    list<SimEqSystem> residual;
    Option<JacobianMatrix> jacobianMatrix;
    list<DAE.ElementSource> sources;
    Integer indexLinearSystem;
    Integer nUnknowns "Number of variables that are solved in this system. Needed because 'crefs' only contains the iteration variables.";
    Boolean partOfJac "if TRUE then this system is part of a jacobian matrix";
  end LINEARSYSTEM;
end LinearSystem;

public
uniontype NonlinearSystem
  record NONLINEARSYSTEM
    Integer index;
    list<SimEqSystem> eqs;
    list<DAE.ComponentRef> crefs;
    Integer indexNonLinearSystem;
    Integer nUnknowns "Number of variables that are solved in this system. Needed because 'crefs' only contains the iteration variables.";
    Option<JacobianMatrix> jacobianMatrix;
    Boolean homotopySupport;
    Boolean mixedSystem;
    Boolean tornSystem;
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

/****** HashTable ComponentRef -> SimCodeVar.SimVar ******/

type Key = HashTableCrefSimVar.Key;
type Value = HashTableCrefSimVar.Value;
type HashTableCrefToSimVar = HashTableCrefSimVar.HashTable;

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

public uniontype FmiDiscreteStates
  record FMIDISCRETESTATES
    list<FmiUnknown> fmiUnknownsList;
  end FMIDISCRETESTATES;
end FmiDiscreteStates;

public uniontype FmiInitialUnknowns
  record FMIINITIALUNKNOWNS
    list<FmiUnknown> fmiUnknownsList;
  end FMIINITIALUNKNOWNS;
end FmiInitialUnknowns;

public uniontype FmiModelStructure
  record FMIMODELSTRUCTURE
    FmiOutputs fmiOutputs;
    FmiDerivatives fmiDerivatives;
    Option<JacobianMatrix> continuousPartialDerivatives;
    FmiDiscreteStates fmiDiscreteStates;
    FmiInitialUnknowns fmiInitialUnknowns;
  end FMIMODELSTRUCTURE;
end FmiModelStructure;

annotation(__OpenModelica_Interface="backend");
end SimCode;
