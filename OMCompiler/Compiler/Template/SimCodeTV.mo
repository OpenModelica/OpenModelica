interface package SimCodeTV

package builtin

  function listReverse
    replaceable type TypeVar subtypeof Any;
    input list<TypeVar> lst;
    output list<TypeVar> result;
  end listReverse;

  function listEmpty
    replaceable type TypeVar subtypeof Any;
    input list<TypeVar> lst;
    output Boolean b;
  end listEmpty;

  function listLength "Return the length of the list"
    replaceable type TypeVar subtypeof Any;
    input list<TypeVar> lst;
    output Integer result;
  end listLength;

  function listGet
    replaceable type TypeVar subtypeof Any;
    input list<TypeVar> lst;
    input Integer ix;
    output TypeVar result;
  end listGet;

  function intAdd
    input Integer a;
    input Integer b;
    output Integer c;
  end intAdd;

  function intNeg
    input Integer a;
    output Integer b;
  end intNeg;

  function boolAnd
    input Boolean b1;
    input Boolean b2;
    output Boolean b;
  end boolAnd;

  function boolOr
    input Boolean a;
    input Boolean b;
    output Boolean c;
  end boolOr;

  function boolNot
    input Boolean b;
    output Boolean nb;
  end boolNot;

  function intMax
    input Integer a;
    input Integer b;
    output Integer c;
  end intMax;

  function intSub
    input Integer a;
    input Integer b;
    output Integer c;
  end intSub;

  function intMul
    input Integer a;
    input Integer b;
    output Integer c;
  end intMul;

  function intDiv
    input Integer a;
    input Integer b;
    output Integer c;
  end intDiv;

  function intMod
    input Integer a;
    input Integer b;
    output Integer c;
  end intMod;

  function intEq
    input Integer a;
    input Integer b;
    output Boolean c;
  end intEq;

  function realEq
    input Real a;
    input Real b;
    output Boolean c;
  end realEq;

  function realAlmostEq
    input Real a;
    input Real b;
    input Real absTol;
    output Boolean c;
  end realAlmostEq;

  function intNe
    input Integer a;
    input Integer b;
    output Boolean c;
  end intNe;

  function intGt
    input Integer i1;
    input Integer i2;
    output Boolean b;
  end intGt;

  function intLt
    input Integer i1;
    input Integer i2;
    output Boolean b;
  end intLt;

  function intReal
    input Integer i;
    output Real r;
  end intReal;

  function realInt
    input Real r;
    output Integer i;
  end realInt;

  function arrayList
    replaceable type TypeVar subtypeof Any;
    input array<TypeVar> arr;
    output list<TypeVar> lst;
  end arrayList;

  function arrayGet
    replaceable type TypeVar subtypeof Any;
    input array<TypeVar> arr;
    input Integer index;
    output TypeVar value;
  end arrayGet;

  function arrayLength
    replaceable type TypeVar subtypeof Any;
    input array<TypeVar> arr;
    output Integer length;
  end arrayLength;

  function stringEq
    input String s1;
    input String s2;
    output Boolean b;
  end stringEq;

  function stringInt
    input String s1;
    output Integer i;
  end stringInt;

  function listAppend
    replaceable type TypeVar subtypeof Any;
    input list<TypeVar> lst;
    input list<TypeVar> lst1;
    output list<TypeVar> result;
  end listAppend;

  function realMul
    input Real x;
    input Real y;
    output Real z;
  end realMul;

  function realDiv
    input Real x;
    input Real y;
    output Real z;
  end realDiv;

  function stringLength
    input String str;
    output Integer length;
  end stringLength;

  function stringGet
    input String str;
    input Integer index;
    output Integer ch;
  end stringGet;

  function listHead
    replaceable type TypeVar subtypeof Any;
    input list<TypeVar> lst;
    output TypeVar head;
  end listHead;

  function stringHashDjb2Mod
    input String str;
    input Integer mod;
    output Integer hash;
  end stringHashDjb2Mod;

  uniontype SourceInfo "The Info attribute provides location information for elements and classes."
    record SOURCEINFO
      String fileName;
      Boolean isReadOnly;
      Integer lineNumberStart;
      Integer columnNumberStart;
      Integer lineNumberEnd;
      Integer columnNumberEnd;
      Real lastModification;
    end SOURCEINFO;
  end SourceInfo;

end builtin;

package SimCodeVar
  uniontype SimVars
    record SIMVARS
      list<SimVar> stateVars;
      list<SimVar> derivativeVars;
      list<SimVar> algVars;
      list<SimVar> discreteAlgVars;
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
      list<SimVar> realOptimizeFinalConstraintsVars;
      list<SimVar> mixedArrayVars;
      list<SimVar> residualVars;
      list<SimVar> algebraicDAEVars;
      list<SimVar> sensitivityVars;
      list<SimVar> dataReconSetcVars;
      list<SimVar> dataReconinputVars;
    end SIMVARS;
  end SimVars;

  uniontype SimVar
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
      Option<DAE.ComponentRef> arrayCref;
      AliasVariable aliasvar;
      DAE.ElementSource source;
      Option<Causality> causality;
      Option<Integer> variable_index "valueReference";
      Option<Integer> fmi_index "index of variable in modelDescription.xml";
      list<String> numArrayElement;
      Boolean isValueChangeable;
      Boolean isProtected;
      Boolean hideResult;
      Option<String> matrixName;
      Option<Variability> variability "FMI-2.0 variabilty attribute";
      Option<Initial> initial_ "FMI-2.0 initial attribute";
      Option<DAE.ComponentRef> exportVar "variables will only be exported to the modelDescription.xml if this attribute is SOME(cref)";
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
    record OUTPUT end OUTPUT;
    record INPUT end INPUT;
    // cases for FMI-2.0 exports Causality attribute
    record LOCAL
    "replacement for INTERNAL(), as we handle PARAMETER and CALCULATED_PARAMETER, the default causality should be defined as LOCAL according to FMI 2.0 Specification"
    end LOCAL;
    record PARAMETER end PARAMETER;
    record CALCULATED_PARAMETER end CALCULATED_PARAMETER;
  end Causality;

  // for setting initial attribute of variable for FMI-2.0 export
  uniontype Initial
    record NONE_INITIAL end NONE_INITIAL;
    record EXACT end EXACT;
    record APPROX end APPROX;
    record CALCULATED end CALCULATED;
  end Initial;

  // for setting Variability attribute for FMI-2.0 export
  uniontype Variability
    record CONSTANT end CONSTANT;
    record FIXED end FIXED;
    record TUNABLE end TUNABLE;
    record DISCRETE end DISCRETE;
    record CONTINUOUS end CONTINUOUS;
  end Variability;
end SimCodeVar;

package HashTableCrefSimVar

  type Key = DAE.ComponentRef;
  type Value = SimCodeVar.SimVar;

  type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
  type HashTable = tuple<
    array<list<tuple<Key,Integer>>>,
    tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
    Integer,
    HashTableCrefFunctionsType
  >;

  function FuncHashCref
    input Key cr;
    input Integer mod;
    output Integer res;
  end FuncHashCref;

  function FuncCrefEqual
    input Key cr1;
    input Key cr2;
    output Boolean res;
  end FuncCrefEqual;

  function FuncCrefStr
    input Key cr;
    output String res;
  end FuncCrefStr;

  function FuncExpStr
    input Value exp;
    output String res;
  end FuncExpStr;
end HashTableCrefSimVar;

package SimCode

  type ExtConstructor = tuple<DAE.ComponentRef, String, list<DAE.Exp>>;
  type ExtDestructor = tuple<String, DAE.ComponentRef>;
  type ExtAlias = tuple<DAE.ComponentRef, DAE.ComponentRef>;

  type SparsityPattern = list<tuple<Integer, list<Integer>>>;

  uniontype JacobianColumn
    record JAC_COLUMN
      list<SimEqSystem> columnEqns;
      list<SimCodeVar.SimVar> columnVars;
      Integer numberOfResultVars;
      list<SimEqSystem> constantEqns;
    end JAC_COLUMN;
  end JacobianColumn;

  uniontype JacobianMatrix
    record JAC_MATRIX
      list<JacobianColumn> columns;
      list<SimCodeVar.SimVar> seedVars;
      String matrixName;
      SparsityPattern sparsity;
      SparsityPattern sparsityT;
      list<list<Integer>> coloredCols;
      Integer maxColorCols;
      Integer jacobianIndex;
      Integer partitionIndex;
      Option<HashTableCrefSimVar.HashTable> crefsHT;
    end JAC_MATRIX;
  end JacobianMatrix;

  uniontype SimCode
    record SIMCODE
      ModelInfo modelInfo;
      list<DAE.Exp> literals;
      list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimEqSystem> localKnownVars;
      list<SimEqSystem> allEquations;
      list<list<SimEqSystem>> odeEquations;
      list<list<SimEqSystem>> algebraicEquations;
      list<ClockedPartition> clockedPartitions;
      Boolean useSymbolicInitialization;         // true if a system to solve the initial problem symbolically is generated, otherwise false
      Boolean useHomotopy;                       // true if homotopy(...) is used during initialization
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
      list<BackendDAE.ZeroCrossing> relations;
      list<BackendDAE.TimeEvent> timeEvents;
      list<DAE.ComponentRef> discreteModelVars;
      ExtObjInfo extObjInfo;
      SimCodeFunction.MakefileParams makefileParams;
      DelayedExpression delayedExps;
      list<JacobianMatrix> jacobianMatrixes;
      Option<SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      String fullPathPrefix; // Used for FMI where code is not generated in the same directory
      String fmuTargetName;
      HpcOmSimCode.HpcOmData hpcomData;
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      Option<FmiModelStructure> modelStructure;
      Option<FmiSimulationFlags> fmiSimulationFlags;
      PartitionData partitionData;
      Option<DaeModeData> daeModeData;
      list<SimEqSystem> inlineEquations;
      Option<OMSIData> omsiData;
    end SIMCODE;
  end SimCode;

  uniontype PartitionData
    record PARTITIONDATA
      Integer numPartitions;
      list<list<Integer>> partitions; // which equations are assigned to the partitions
      list<list<Integer>> activatorsForPartitions; // which activators can activate each partition
      list<Integer> stateToActivators; // which states belong to which activator
    end PARTITIONDATA;
  end PartitionData;

  uniontype ClockedPartition
    record CLOCKED_PARTITION
      DAE.ClockKind baseClock;
      list<SubPartition> subPartitions;
    end CLOCKED_PARTITION;
  end ClockedPartition;

  uniontype SubPartition
    record SUBPARTITION
      list<tuple<SimCodeVar.SimVar, Boolean>> vars;
      list<SimEqSystem> equations;
      list<SimEqSystem> removedEquations;
      BackendDAE.SubClock subClock;
      Boolean holdEvents;
    end SUBPARTITION;
  end SubPartition;

  uniontype DelayedExpression
    record DELAYED_EXPRESSIONS
      list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
      Integer maxDelayedIndex;
    end DELAYED_EXPRESSIONS;
  end DelayedExpression;

  uniontype SimulationSettings
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

  uniontype ExtObjInfo
    record EXTOBJINFO
      list<SimCodeVar.SimVar> vars;
      list<ExtAlias> aliases;
    end EXTOBJINFO;
  end ExtObjInfo;

  uniontype OMSIData
    record OMSI_DATA
      OMSIFunction initialization;
      OMSIFunction simulation;
    end OMSI_DATA;
  end OMSIData;

  uniontype OMSIFunction
    record OMSI_FUNCTION
      list<SimEqSystem> equations;
      list<SimCodeVar.SimVar> inputVars;
      list<SimCodeVar.SimVar> outputVars;
      list<SimCodeVar.SimVar> innerVars;
      Integer nAllVars;
      SimCodeFunction.Context context;
      Integer nAlgebraicSystems;
    end OMSI_FUNCTION;
  end OMSIFunction;

  uniontype SimEqSystem
    record SES_RESIDUAL
      Integer index;
      DAE.Exp exp;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;
    end SES_RESIDUAL;

    record SES_SIMPLE_ASSIGN
      Integer index;
      DAE.ComponentRef cref;
      DAE.Exp exp;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;
    end SES_SIMPLE_ASSIGN;

    record SES_SIMPLE_ASSIGN_CONSTRAINTS
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
      list<DAE.ComponentRef> conditions;    // list of boolean variables as conditions
      Boolean initialCall;                  // true, if top-level branch with initial()
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
      Integer aliasOf;
    end SES_ALIAS;

    record SES_ALGEBRAIC_SYSTEM
      Integer index;
      Integer algSysIndex;
      Integer dim_n;
      Boolean partOfMixed;
      Boolean tornSystem;
      Boolean linearSystem;
      OMSIFunction residual;
      Option<DerivativeMatrix> matrix;
      list<Integer> zeroCrossingConditions;
      list<DAE.ElementSource> sources;
      BackendDAE.EquationAttributes eqAttr;
    end SES_ALGEBRAIC_SYSTEM;
  end SimEqSystem;

  uniontype DerivativeMatrix
    "represents directional derivatives with sparsity and coloring"
    record DERIVATIVE_MATRIX
      list<OMSIFunction> columns;         // column(s) equations and variables
                                          // inputVars:  seedVars
                                          // innerVars:  inner column vars
                                          // outputVars: result vars of the column

      String matrixName;                  // unique matrix name
      SparsityPattern sparsity;
      SparsityPattern sparsityT;
      list<list<Integer>> coloredCols;
      Integer maxColorCols;
    end DERIVATIVE_MATRIX;
  end DerivativeMatrix;

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
      Integer nUnknowns;
      Boolean partOfJac "if TRUE then this system is part of a jacobian matrix";
    end LINEARSYSTEM;
  end LinearSystem;

  uniontype NonlinearSystem
    record NONLINEARSYSTEM
      Integer index;
      list<SimEqSystem> eqs;
      list<DAE.ComponentRef> crefs;
      Integer indexNonLinearSystem;
      Integer nUnknowns;
      Option<JacobianMatrix> jacobianMatrix;
      Boolean homotopySupport;
      Boolean mixedSystem;
      Boolean tornSystem;
      Option<Integer> clockIndex;
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

  uniontype ModelInfo
    record MODELINFO
      Absyn.Path name;
      String description;
      String directory;
      VarInfo varInfo;
      SimCodeVar.SimVars vars;
      list<SimCodeFunction.Function> functions;
      list<String> labels;
      list<Absyn.Class> sortedClasses;
      Integer nClocks;
      Integer nSubClocks;
      list<SimEqSystem> linearSystems;
      list<SimEqSystem> nonLinearSystems;
      list<UnitDefinition> unitDefinitions "export unitDefintion in modelDescription.xml";
    end MODELINFO;
  end ModelInfo;

  uniontype UnitDefinition "unitDefinitions for fmi modelDescription.xml"
    record UNITDEFINITION
      String name;
      BaseUnit baseUnit;
      //TODO DisplayUnit
    end UNITDEFINITION;
  end UnitDefinition;

  uniontype BaseUnit
    record BASEUNIT
      Integer mol "exponent";
      Integer cd  "exponent";
      Integer m   "exponent";
      Integer s   "exponent";
      Integer A   "exponent";
      Integer K   "exponent";
      Integer kg  "exponent";
      Real factor "prefix";
      Real offset "offset";
    end BASEUNIT;

    record NOBASEUNIT "no baseunit definition available"
    end NOBASEUNIT;
  end BaseUnit;

  uniontype VarInfo
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
      Integer numDataReconVars;
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
      list<SimCodeVar.SimVar> residualVars;  // variable used to calculate residuals of a DAE form, they are real
      list<SimCodeVar.SimVar> algebraicVars;  // algebraic variable used to calculate residuals of a DAE form, they are real
      list<SimCodeVar.SimVar> auxiliaryVars;  // auxiliary variable used to calculate residuals of a DAE form, they are real
    end DAEMODEDATA;
  end DaeModeData;

  uniontype FmiUnknown
    record FMIUNKNOWN
      Integer index;
      list<Integer> dependencies;
      list<String> dependenciesKind;
    end FMIUNKNOWN;
  end FmiUnknown;

  uniontype FmiOutputs
    record FMIOUTPUTS
      list<FmiUnknown> fmiUnknownsList;
    end FMIOUTPUTS;
  end FmiOutputs;

  uniontype FmiDerivatives
    record FMIDERIVATIVES
      list<FmiUnknown> fmiUnknownsList;
    end FMIDERIVATIVES;
  end FmiDerivatives;

  uniontype FmiDiscreteStates
    record FMIDISCRETESTATES
      list<FmiUnknown> fmiUnknownsList;
    end FMIDISCRETESTATES;
  end FmiDiscreteStates;

  uniontype FmiInitialUnknowns
    record FMIINITIALUNKNOWNS
      list<FmiUnknown> fmiUnknownsList;
    end FMIINITIALUNKNOWNS;
  end FmiInitialUnknowns;

  uniontype FmiModelStructure
    record FMIMODELSTRUCTURE
      FmiOutputs fmiOutputs;
      FmiDerivatives fmiDerivatives;
      Option<JacobianMatrix> continuousPartialDerivatives;
      FmiDiscreteStates fmiDiscreteStates;
      FmiInitialUnknowns fmiInitialUnknowns;
    end FMIMODELSTRUCTURE;
  end FmiModelStructure;

  uniontype FmiSimulationFlags
    record FMI_SIMULATION_FLAGS
      list<tuple<String,String>> nameValueTuples;
    end FMI_SIMULATION_FLAGS;

    record FMI_SIMULATION_FLAGS_FILE
      String path;
    end FMI_SIMULATION_FLAGS_FILE;
  end FmiSimulationFlags;

end SimCode;

package SimCodeFunction

  uniontype FunctionCode
    record FUNCTIONCODE
      String name;
      Option<Function> mainFunction;
      list<Function> functions;
      list<DAE.Exp> literals;
      list<String> externalFunctionIncludes;
      MakefileParams makefileParams;
      list<RecordDeclaration> extraRecordDecls;
    end FUNCTIONCODE;
  end FunctionCode;

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
      String runtimelibs;
      list<String> includes;
      list<String> libs;
      list<String> libPaths;
      String platform;
      String compileDir;
    end MAKEFILE_PARAMS;
  end MakefileParams;

  uniontype Variable
    record VARIABLE
      DAE.ComponentRef name;
      DAE.Type ty;
      Option<DAE.Exp> value;
      list<DAE.Dimension> instDims;
      DAE.VarParallelism parallelism;
      DAE.VarKind kind;
      Boolean bind_from_outside;
    end VARIABLE;

    record FUNCTION_PTR
      String name;
      list<DAE.Type> tys;
      list<Variable> args;
      Option<DAE.Exp> defaultValue;
    end FUNCTION_PTR;
  end Variable;

  uniontype Function
    record FUNCTION
      Absyn.Path name;
      list<Variable> outVars;
      list<Variable> functionArguments;
      list<Variable> variableDeclarations;
      list<DAE.Statement> body;
      SCode.Visibility visibility;
      builtin.SourceInfo info;
    end FUNCTION;
    record PARALLEL_FUNCTION
      Absyn.Path name;
      list<Variable> outVars;
      list<Variable> functionArguments;
      list<Variable> variableDeclarations;
      list<DAE.Statement> body;
      builtin.SourceInfo info;
    end PARALLEL_FUNCTION;
    record KERNEL_FUNCTION
      Absyn.Path name;
      list<Variable> outVars;
      list<Variable> functionArguments;
      list<Variable> variableDeclarations;
      list<DAE.Statement> body;
      builtin.SourceInfo info;
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
      list<String> includes;
      list<String> libs;
      String language;
      builtin.SourceInfo info;
      SCode.Visibility visibility;
      Boolean dynamicLoad;
    end EXTERNAL_FUNCTION;
    record RECORD_CONSTRUCTOR
      Absyn.Path name;
      list<Variable> funArgs;
      list<Variable> locals;
      builtin.SourceInfo info;
      SCode.Visibility visibility;
      DAE.VarKind kind;
    end RECORD_CONSTRUCTOR;
  end Function;

  uniontype RecordDeclaration
    record RECORD_DECL_FULL
      String name;
      Option<String> aliasName;
      Absyn.Path defPath;
      list<Variable> variables;
    end RECORD_DECL_FULL;
    record RECORD_DECL_ADD_CONSTRCTOR
      String ctor_name;
      String name;
      list<Variable> variables;
    end RECORD_DECL_ADD_CONSTRCTOR;
    record RECORD_DECL_DEF
      Absyn.Path path;
      list<String> fieldNames;
    end RECORD_DECL_DEF;
  end RecordDeclaration;

  uniontype SimExtArg
    record SIMEXTARG
      DAE.ComponentRef cref;
      Boolean isInput;
      Integer outputIndex;
      Boolean isArray;
      Boolean hasBinding;
      DAE.Type type_;
    end SIMEXTARG;
    record SIMEXTARGEXP
      DAE.Exp exp;
      DAE.Type type_;
    end SIMEXTARGEXP;
    record SIMEXTARGSIZE
      DAE.ComponentRef cref;
      Boolean isInput;
      Integer outputIndex;
      DAE.Type type_;
      DAE.Exp exp;
    end SIMEXTARGSIZE;
    record SIMNOEXTARG end SIMNOEXTARG;
  end SimExtArg;

  uniontype Context
    record SIMULATION_CONTEXT
      Boolean genDiscrete;
    end SIMULATION_CONTEXT;
    record FUNCTION_CONTEXT
      String cref_prefix;
      Boolean is_parallel;
    end FUNCTION_CONTEXT;
    record JACOBIAN_CONTEXT
      Option<HashTableCrefSimVar.HashTable> jacHT;
    end JACOBIAN_CONTEXT;
    record ALGLOOP_CONTEXT
      Boolean genInitialisation;
      Boolean genJacobian;
    end ALGLOOP_CONTEXT;
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
      Option<HashTableCrefSimVar.HashTable> hashTable;
    end OMSI_CONTEXT;
  end Context;

  constant Context contextSimulationNonDiscrete;
  constant Context contextSimulationDiscrete;
  constant Context contextFunction;
  constant Context contextOther;
  constant Context contextAlgloopJacobian;
  constant Context contextAlgloop;
  constant Context contextJacobian;
  constant Context contextAlgloopInitialisation;
  constant Context contextParallelFunction;
  constant Context contextZeroCross;
  constant Context contextOptimization;
  constant Context contextFMI;
  constant Context contextDAEmode;
  constant Context contextOMSI;
  constant list<DAE.Exp> listExpLength1;
  constant list<SimCodeFunction.Variable> boxedRecordOutVars;
end SimCodeFunction;

package SimCodeUtil

  function absoluteClockIdxForBaseClock
    input Integer baseClockIdx;
    input list<SimCode.ClockedPartition> allBaseClockPartitions;
    output Integer absBaseClockIdx;
  end absoluteClockIdxForBaseClock;

  function getClockedPartitions
    input SimCode.SimCode simcode;
    output list<SimCode.ClockedPartition> clockedPartitions;
  end getClockedPartitions;

  function functionInfo
    input SimCodeFunction.Function fn;
    output builtin.SourceInfo info;
  end functionInfo;

  function countDynamicExternalFunctions
    input list<SimCodeFunction.Function> inFncLst;
    output Integer outDynLoadFuncs;
  end countDynamicExternalFunctions;

  function eqInfo
    input SimCode.SimEqSystem eq;
    output builtin.SourceInfo info;
  end eqInfo;

  function dimsToAllIndexes
    input DAE.Dimensions inDims;
    output list<list<Integer>> outIndexes;
  end dimsToAllIndexes;

  function sortEqSystems
    input list<SimCode.SimEqSystem> eqs;
    output list<SimCode.SimEqSystem> outEqs;
  end sortEqSystems;

  function getEnumerationTypes
    input SimCodeVar.SimVars inVars;
    output list<SimCodeVar.SimVar> outVars;
  end getEnumerationTypes;

  function getFMIModelStructure
    input SimCode.SimCode simCode;
    input list<SimCode.JacobianMatrix> jacobianMatrixes;
    output SimCode.FmiModelStructure outFmiModelStructure;
  end getFMIModelStructure;

  function getStateSimVarIndexFromIndex
    input list<SimCodeVar.SimVar> inStateVars;
    input Integer inIndex;
    output Integer outVariableIndex;
  end getStateSimVarIndexFromIndex;

  function getScalarElements
    input SimCodeVar.SimVar var;
    output list<SimCodeVar.SimVar> elts;
  end getScalarElements;

  function getVariableIndex
    input SimCodeVar.SimVar inVar;
    output Integer outVariableIndex;
  end getVariableIndex;

  function getVariableFMIIndex
    input SimCodeVar.SimVar inVar;
    output Integer outIndex;
  end getVariableFMIIndex;

  function getMaxSimEqSystemIndex
    input SimCode.SimCode simCode;
    output Integer idxOut;
  end getMaxSimEqSystemIndex;

  function translateSparsePatterSimVarInts
    input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> sparsePattern;
    input SimCode.SimCode simCode;
    output list<tuple<Integer, list<Integer>>> outSparsePattern;
  end translateSparsePatterSimVarInts;

  function translateColorsSimVarInts
    input list<list<DAE.ComponentRef>> inColors;
    input SimCode.SimCode simCode;
    output list<list<Integer>> outColors;
  end translateColorsSimVarInts;

  function getDaeEqsNotPartOfOdeSystem
    input SimCode.SimCode iSimCode;
    output list<SimCode.SimEqSystem> oEqs;
  end getDaeEqsNotPartOfOdeSystem;

  function getValueReference
    input SimCodeVar.SimVar inSimVar;
    input SimCode.SimCode inSimCode;
    input Boolean inElimNegAliases;
    output String outValueReference;
  end getValueReference;

  function getLocalValueReference
    input SimCodeVar.SimVar inSimVar;
    input SimCode.SimCode inSimCode;
    input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
    input Boolean inElimNegAliases;
    output String outValueReference;
  end getLocalValueReference;

  function getVarIndexListByMapping
    input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
    input DAE.ComponentRef iVarName;
    input Boolean iColumnMajor;
    input String iIndexForUndefinedReferences;
    output list<String> oVarIndexList;
  end getVarIndexListByMapping;

  function getVarIndexByMapping
    input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
    input DAE.ComponentRef iVarName;
    input Boolean iColumnMajor;
    input String iIndexForUndefinedReferences;
    output String oVarIndex;
  end getVarIndexByMapping;

  function providesDirectionalDerivative
    input SimCode.SimCode inSimCode;
    output Boolean b;
  end providesDirectionalDerivative;

  function isVarIndexListConsecutive
    input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
    input DAE.ComponentRef iVarName;
    output Boolean oIsConsecutive;
  end isVarIndexListConsecutive;

  function getSubPartitions
    input list<SimCode.ClockedPartition> inPartitions;
    output list<SimCode.SubPartition> outSubPartitions;
  end getSubPartitions;

  function getClockedEquations
    input list<SimCode.SubPartition> inSubPartitions;
    output list<SimCode.SimEqSystem> outEqs;
  end getClockedEquations;

  function getClockIndex
    input SimCodeVar.SimVar simVar;
    input SimCode.SimCode simCode;
    output Option<Integer> clockIndex;
  end getClockIndex;

  function computeDependencies
    input list<SimCode.SimEqSystem> eqs;
    input DAE.ComponentRef cref;
    output list<SimCode.SimEqSystem> deps;
  end computeDependencies;

  function getSimEqSystemsByIndexLst
    input list<Integer> idcs;
    input list<SimCode.SimEqSystem> allSes;
    output list<SimCode.SimEqSystem> sesOut;
  end getSimEqSystemsByIndexLst;

  function getInputIndex
    input SimCodeVar.SimVar var;
    output Integer inputIndex;
  end getInputIndex;

  function resetFunctionIndex
  end resetFunctionIndex;

  function addFunctionIndex
    input String prefix;
    input String suffix;
    output String newName;
  end addFunctionIndex;

  function nVariablesReal
    input SimCode.VarInfo varInfo;
    output Integer n;
  end nVariablesReal;

  function getSimCode
    output SimCode.SimCode code;
  end getSimCode;

  function cref2simvar
    input DAE.ComponentRef cref;
    input SimCode.SimCode simCode;
    output SimCodeVar.SimVar outSimVar;
  end cref2simvar;

  function simVarFromHT
    input DAE.ComponentRef inCref;
    input HashTableCrefSimVar.HashTable crefToSimVarHT;
    output SimCodeVar.SimVar outSimVar;
  end simVarFromHT;

  function createJacContext
    input Option<HashTableCrefSimVar.HashTable> jacHT;
    output SimCodeFunction.Context outContext;
  end createJacContext;

  function localCref2SimVar
    input DAE.ComponentRef inCref;
    input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
    output SimCodeVar.SimVar outSimVar;
  end localCref2SimVar;

  function localCref2Index
    input DAE.ComponentRef inCref;
    input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
    output String outIndex;
  end localCref2Index;

  function isModelTooBigForCSharpInOneFile
    input SimCode.SimCode simCode;
    output Boolean outIsTooBig;
  end isModelTooBigForCSharpInOneFile;

  function codegenExpSanityCheck
    input DAE.Exp inExp;
    input SimCodeFunction.Context context;
    output DAE.Exp outExp;
  end codegenExpSanityCheck;

  function selectScalarLiteralAssignments
    input list<SimCode.SimEqSystem> inEqs;
    output list<SimCode.SimEqSystem> eqs;
  end selectScalarLiteralAssignments;

  function filterScalarLiteralAssignments
    input list<SimCode.SimEqSystem> inEqs;
    output list<SimCode.SimEqSystem> eqs;
  end filterScalarLiteralAssignments;

  function sortSimpleAssignmentBasedOnLhs
    input list<SimCode.SimEqSystem> inEqs;
    output list<SimCode.SimEqSystem> eqs;
  end sortSimpleAssignmentBasedOnLhs;

  function sortCrefBasedOnSimCodeIndex
    input list<DAE.ComponentRef> inCrefs;
    input SimCode.SimCode simCode;
    output list<DAE.ComponentRef> crs;
  end sortCrefBasedOnSimCodeIndex;

  function getNumContinuousEquations
    input list<SimCode.SimEqSystem> eqs;
    input Integer numStates;
    output Integer n;
  end getNumContinuousEquations;

  function lookupVR
    input DAE.ComponentRef cr;
    input SimCode.SimCode simCode;
    output Integer vr;
  end lookupVR;

end SimCodeUtil;

package SimCodeFunctionUtil
  function varName
    input SimCodeVar.SimVar var;
    output DAE.ComponentRef cr;
  end varName;

  function isParallelFunctionContext
    input SimCodeFunction.Context context;
    output Boolean s;
  end isParallelFunctionContext;

  function createDAEString
    input String inString;
    output DAE.Exp outExp;
  end createDAEString;

  function crefSubIsScalar
    input DAE.ComponentRef cref;
    output Boolean isScalar;
  end crefSubIsScalar;

  function crefNoSub
    input DAE.ComponentRef cref;
    output Boolean noSub;
  end crefNoSub;

  function crefIsScalar
    input DAE.ComponentRef cref;
    input SimCodeFunction.Context context;
    output Boolean isScalar;
  end crefIsScalar;

  function isProtected
    input SimCodeVar.SimVar simVar;
    output Boolean isProtected;
  end isProtected;

  function protectedVars
    input list<SimCodeVar.SimVar> InSimVars;
    output list<SimCodeVar.SimVar> OutSimVars;
  end protectedVars;

  function makeCrefRecordExp
    input DAE.ComponentRef inCRefRecord;
    input DAE.Var inVar;
    output DAE.Exp outExp;
  end makeCrefRecordExp;

  function splitRecordAssignmentToMemberAssignments
    input DAE.ComponentRef lhs_cref;
    input DAE.Type lhs_type;
    input String rhs_cref_str;
    output list<DAE.Statement> outAssigns;
  end splitRecordAssignmentToMemberAssignments;

  function derComponentRef
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef derCref;
  end derComponentRef;

  function hackArrayReverseToCref
    input DAE.Exp inExp;
    input SimCodeFunction.Context context;
    output DAE.Exp outExp;
  end hackArrayReverseToCref;

  function hackGetFirstExternalFunctionLib
    input list<String> libs;
    output String outFirstLib;
  end hackGetFirstExternalFunctionLib;

  function hackMatrixReverseToCref
    input DAE.Exp inExp;
    input SimCodeFunction.Context context;
    output DAE.Exp outExp;
  end hackMatrixReverseToCref;

  function createArray
    input Integer size;
    output DAE.Exp outArray;
  end createArray;

  function createAssertforSqrt
    input DAE.Exp inExp;
    output DAE.Exp outExp;
  end createAssertforSqrt;

  function elementVars
    input list<DAE.Element> ld;
    output list<SimCodeFunction.Variable> vars;
  end elementVars;

  function isBoxedFunction
    input SimCodeFunction.Function fn;
    output Boolean b;
  end isBoxedFunction;

  function funcHasParallelInOutArrays
    input SimCodeFunction.Function fn;
    output Boolean b;
  end funcHasParallelInOutArrays;

  function incrementInt
    input Integer inInt;
    input Integer increment;
    output Integer outInt;
  end incrementInt;

  function decrementInt
    input Integer inInt;
    input Integer decrement;
    output Integer outInt;
  end decrementInt;

  function buildCrefExpFromAsub
    input DAE.Exp cref;
    input list<DAE.Exp> subs;
    output DAE.Exp cRefOut;
  end buildCrefExpFromAsub;

  function codegenResetTryThrowIndex
  end codegenResetTryThrowIndex;

  function codegenPushTryThrowIndex
    input Integer i;
  end codegenPushTryThrowIndex;

  function codegenPopTryThrowIndex
  end codegenPopTryThrowIndex;

  function codegenPeekTryThrowIndex
    output Integer i;
  end codegenPeekTryThrowIndex;

  function twodigit
    input Integer i;
    output String s;
  end twodigit;

  function generateSubPalceholders
    input DAE.ComponentRef cr;
    output String outdef;
  end generateSubPalceholders;

  function getCurrentCrefPrefix
    input SimCodeFunction.Context context;
    output String cref_pref;
  end getCurrentCrefPrefix;

  function appendCurrentCrefPrefix
    input SimCodeFunction.Context context;
    input String cref_pref;
    output SimCodeFunction.Context out_context;
  end appendCurrentCrefPrefix;

end SimCodeFunctionUtil;

package BackendDAE

  uniontype VarKind "variabile kind"
    record VARIABLE end VARIABLE;
    record STATE
      Integer index;
      Option<DAE.ComponentRef> derName;
    end STATE;
    record STATE_DER end STATE_DER;
    record DUMMY_DER end DUMMY_DER;
    record DUMMY_STATE end DUMMY_STATE;
    record CLOCKED_STATE
      DAE.ComponentRef previousName "the name of the previous variable";
      Boolean isStartFixed "is fixed at first clock tick";
    end CLOCKED_STATE;
    record DISCRETE end DISCRETE;
    record PARAM end PARAM;
    record CONST end CONST;
    record EXTOBJ Absyn.Path fullClassName; end EXTOBJ;
    record JAC_VAR end JAC_VAR;
    record JAC_DIFF_VAR end JAC_DIFF_VAR;
    record SEED_VAR end SEED_VAR;
    record OPT_CONSTR end OPT_CONSTR;
    record OPT_FCONSTR end OPT_FCONSTR;
    record OPT_INPUT_WITH_DER end OPT_INPUT_WITH_DER;
    record OPT_INPUT_DER end OPT_INPUT_DER;
    record OPT_TGRID end OPT_TGRID;
    record OPT_LOOP_INPUT
      DAE.ComponentRef replaceExp;
    end OPT_LOOP_INPUT;
    record ALG_STATE        "algebraic state used by inline solver"
    end ALG_STATE;
    record ALG_STATE_OLD    "algebraic state old value used by inline solver"
    end ALG_STATE_OLD;
    record DAE_RESIDUAL_VAR "variable kind used for DAEmode"
    end DAE_RESIDUAL_VAR;
    record DAE_AUX_VAR      "auxiliary variable used for DAEmode"
    end DAE_AUX_VAR;
    record LOOP_ITERATION   "used in SIMCODE, iteration variables in algebraic loops"
    end LOOP_ITERATION;
    record LOOP_SOLVED      "used in SIMCODE, inner variables of a torn algebraic loop"
    end LOOP_SOLVED;
  end VarKind;

  uniontype SubClock
    record SUBCLOCK
      MMath.Rational factor;
      MMath.Rational shift;
      Option<String> solver;
    end SUBCLOCK;
  end SubClock;

  uniontype ZeroCrossing
    record ZERO_CROSSING
      DAE.Exp relation_;
      list<Integer> occurEquLst;
      list<Integer> occurWhenLst;
    end ZERO_CROSSING;
  end ZeroCrossing;

  uniontype TimeEvent
    record SIMPLE_TIME_EVENT "e.g. time > 0.5"
    end SIMPLE_TIME_EVENT;

    record COMPLEX_TIME_EVENT "e.g. sin(time) > 0"
    end COMPLEX_TIME_EVENT;

    record SAMPLE_TIME_EVENT "e.g. sample(1, 1)"
      Integer index "unique sample index" ;
      DAE.Exp startExp;
      DAE.Exp intervalExp;
    end SAMPLE_TIME_EVENT;
  end TimeEvent;

  uniontype WhenOperator "- Reinit Statement"
    record ASSIGN " left_cr = right_exp"
      DAE.Exp left     "left hand side of equation";
      DAE.Exp right             "right hand side of equation";
      DAE.ElementSource source  "origin of equation";
    end ASSIGN;

    record REINIT
      DAE.ComponentRef stateVar "State variable to reinit" ;
      DAE.Exp value             "Value after reinit" ;
      DAE.ElementSource source "origin of equation";
    end REINIT;

    record ASSERT
      DAE.Exp condition;
      DAE.Exp message;
      DAE.Exp level;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end ASSERT;

    record TERMINATE " The Modelica builtin terminate(msg)"
      DAE.Exp message;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end TERMINATE;

    record NORETCALL "call with no return value, i.e. no equation.
      Typically sideeffect call of external function but also
      Connections.* i.e. Connections.root(...) functions."
      DAE.Exp exp;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    end NORETCALL;
  end WhenOperator;

  uniontype WhenEquation
    record WHEN_EQ
      Integer index;
      DAE.ComponentRef left;
      DAE.Exp right;
      Option<WhenEquation> elsewhenPart;
    end WHEN_EQ;
    record WHEN_STMTS "equation when condition then reinit(...), terminate(...) or assert(...)"
      DAE.Exp condition                "the when-condition" ;
      list<WhenOperator> whenStmtLst;
      Option<WhenEquation> elsewhenPart "elsewhen equation with the same cref on the left hand side.";
    end WHEN_STMTS;
  end WhenEquation;

  constant String optimizationMayerTermName;
  constant String optimizationLagrangeTermName;
  constant String symSolverDT;

  type Constraints = list<DAE.Constraint> "Constraints on the solvability of the (casual) tearing set; needed for proper Dynamic Tearing";

  uniontype EquationKind "equation kind"
    record BINDING_EQUATION
    end BINDING_EQUATION;
    record DYNAMIC_EQUATION
    end DYNAMIC_EQUATION;
    record INITIAL_EQUATION
    end INITIAL_EQUATION;
    record CLOCKED_EQUATION
      Integer clk;
    end CLOCKED_EQUATION;
    record DISCRETE_EQUATION
    end DISCRETE_EQUATION;
    record AUX_EQUATION
    end AUX_EQUATION;
    record UNKNOWN_EQUATION_KIND
    end UNKNOWN_EQUATION_KIND;
  end EquationKind;

  uniontype EvaluationStages "evaluation stages"
    record EVALUATION_STAGES
      Boolean dynamicEval;
      Boolean algebraicEval;
      Boolean zerocrossEval;
      Boolean discreteEval;
    end EVALUATION_STAGES;
  end EvaluationStages;

  uniontype EquationAttributes
    record EQUATION_ATTRIBUTES
      Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
      EquationKind kind;
      EvaluationStages evalStages;
    end EQUATION_ATTRIBUTES;
  end EquationAttributes;
end BackendDAE;

package System
  function substring
    input String inString;
    input Integer start;
    input Integer stop;
    output String outString;
  end substring;

  function stringFind
    input String str;
    input String searchStr;
    output Integer outInteger;
  end stringFind;

  function stringReplace
    input String str;
    input String source;
    input String target;
    output String res;
  end stringReplace;

  function makeC89Identifier
    input String str;
    output String res;
  end makeC89Identifier;

  function tmpTick
    output Integer tickNo;
  end tmpTick;

  function tmpTickReset
    input Integer start;
  end tmpTickReset;

  function tmpTickIndex
    input Integer index;
    output Integer tickNo;
  end tmpTickIndex;

  function tmpTickIndexReserve
    input Integer index;
    input Integer reserve;
    output Integer tickNo;
  end tmpTickIndexReserve;

  function tmpTickResetIndex
    input Integer start;
    input Integer index;
  end tmpTickResetIndex;

  function tmpTickSetIndex
    input Integer start;
    input Integer index;
  end tmpTickSetIndex;

  function tmpTickMaximum
    input Integer index;
    output Integer maxIndex;
  end tmpTickMaximum;

  function getCurrentTimeStr
    output String timeStr;
  end getCurrentTimeStr;

  function getUUIDStr
    output String uuidStr;
  end getUUIDStr;

  function unescapedStringLength "Return the length of a C string literal"
    input String s;
    output Integer result;
  end unescapedStringLength;

  function escapedString
    input String unescapedString;
    input Boolean unescapeNewline;
    output String escapedString;
  end escapedString;

  function unquoteIdentifier
    input String str;
    output String outStr;
  end unquoteIdentifier;

  function dirname
    input String str;
    output String outStr;
  end dirname;

  function os
    output String str;
  end os;

  function strtok
    input String s1;
    input String s2;
    output list<String> tokens;
  end strtok;

  function covertTextFileToCLiteral
    input String textFile;
    input String outFile;
    input String target;
    output Boolean success;
  end covertTextFileToCLiteral;

end System;

package Autoconf
  constant String triple;
end Autoconf;

package Tpl
  function redirectToFile
    input Text inText;
    input String inFileName;
    output Text outText;
  end redirectToFile;

  function closeFile
    input Text inText;
    output Text outText;
  end closeFile;

  function textFile
    input Text inText;
    input String inFileName;
  end textFile;

  function textFileConvertLines
    input Text inText;
    input String inFileName;
  end textFileConvertLines;

  //we do not import Error.addSourceMessage() directly
  //because of list creation in Susan is not possible (yet by design)
  function addSourceTemplateError
    "Wraps call to Error.addSourceMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
    input String inErrMsg;
    input builtin.SourceInfo inInfo;
  end addSourceTemplateError;

  //for completeness; although the addSourceTemplateError() above is preferable
  function addTemplateError
  "Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
    input String inErrMsg;
  end addTemplateError;
end Tpl;


package Absyn

  type Ident = String;

  uniontype Class
    record CLASS
      Ident name;
      builtin.SourceInfo info;
    end CLASS;
  end Class;

  uniontype Path
    record QUALIFIED
      Ident name;
      Path path;
    end QUALIFIED;
    record IDENT
      String name;
    end IDENT;
    record FULLYQUALIFIED
      Path path;
    end FULLYQUALIFIED;
  end Path;

  uniontype Within "Within Clauses"
    record WITHIN "the within clause"
      Path path "the path for within";
    end WITHIN;

    record TOP end TOP;

  end Within;

  uniontype ReductionIterType
    record COMBINE
    end COMBINE;
    record THREAD
    end THREAD;
  end ReductionIterType;

end Absyn;

package AbsynUtil

  function pathString
    input Absyn.Path path;
    input String delimiter;
    input Boolean usefq;
    output String outString;
  end pathString;

  function pathLastIdent
    input Absyn.Path inPath;
    output String str;
  end pathLastIdent;

  constant builtin.SourceInfo dummyInfo;
end AbsynUtil;

package MMath
  uniontype Rational
    record RATIONAL
      Integer nom;
      Integer denom;
    end RATIONAL;
  end Rational;
end MMath;

package DAE

  type Ident = String;

  uniontype VarKind
    record VARIABLE "variable" end VARIABLE;
    record DISCRETE "discrete" end DISCRETE;
    record PARAM "parameter"   end PARAM;
    record CONST "constant"    end CONST;

    // back-end dae variable kinds
    record STATE end STATE;
    record STATE_DER end STATE_DER;
    record DUMMY_DER end DUMMY_DER;
    record DUMMY_STATE end DUMMY_STATE;
    record EXTOBJ Absyn.Path fullClassName; end EXTOBJ;
  end VarKind;

  uniontype ClockKind
    record INFERRED_CLOCK
    end INFERRED_CLOCK;

    record INTEGER_CLOCK
      Exp intervalCounter;
      Exp resolution;
    end INTEGER_CLOCK;

    record REAL_CLOCK
      Exp interval;
    end REAL_CLOCK;

    record BOOLEAN_CLOCK
      Exp condition;
      Exp startInterval;
    end BOOLEAN_CLOCK;

    record SOLVER_CLOCK
      Exp c;
      Exp solverMethod;
    end SOLVER_CLOCK;
  end ClockKind;

  uniontype Exp
    record ICONST
      Integer integer;
    end ICONST;
    record RCONST
      Real real;
    end RCONST;
    record SCONST
      String string;
    end SCONST;
    record BCONST
      Boolean bool;
    end BCONST;
    record CLKCONST
      Absyn.ClockKind clk;
    end CLKCONST;
    record ENUM_LITERAL
      Absyn.Path name;
      Integer index;
    end ENUM_LITERAL;
    record CREF
      ComponentRef componentRef;
      Type ty;
    end CREF;
    record BINARY
      Exp exp1;
      Operator operator;
      Exp exp2;
    end BINARY;
    record UNARY
      Operator operator;
      Exp exp;
    end UNARY;
    record LBINARY
      Exp exp1;
      Operator operator;
      Exp exp2;
    end LBINARY;
    record LUNARY
      Operator operator;
      Exp exp;
    end LUNARY;
    record RELATION
      Exp exp1;
      Operator operator;
      Exp exp2;
      Integer index;
      Option<tuple<DAE.Exp,Integer,Integer>> optionExpisASUB;
    end RELATION;
    record IFEXP
      Exp expCond;
      Exp expThen;
      Exp expElse;
    end IFEXP;
    record CALL
      Absyn.Path path;
      list<Exp> expLst;
      CallAttributes attr;
    end CALL;
    record RECORD
      Absyn.Path path;
      list<Exp> exps;
      list<String> comp;
      Type ty;
    end RECORD;
    record PARTEVALFUNCTION
      Absyn.Path path;
      list<Exp> expList;
      Type ty;
      Type origType;
    end PARTEVALFUNCTION;
    record ARRAY
      Type ty;
      Boolean scalar;
      list<Exp> array;
    end ARRAY;
    record MATRIX
      Type ty;
      Integer integer;
      list<list<Exp>> matrix;
    end MATRIX;
    record RANGE
      Type ty;
      Exp start;
      Option<Exp> step;
      Exp stop;
    end RANGE;
    record TUPLE
      list<Exp> PR;
    end TUPLE;
    record CAST
      Type ty;
      Exp exp;
    end CAST;
    record ASUB
      Exp exp;
      list<Exp> sub;
    end ASUB;
    record TSUB
      Exp exp;
      Integer ix;
      Type ty;
    end TSUB;
    record RSUB
      Exp exp;
      Integer ix;
      String fieldName;
      Type ty;
    end RSUB;
    record SIZE
      Exp exp;
      Option<Exp> sz;
    end SIZE;
    record CODE
      Absyn.CodeNode code;
      Type ty;
    end CODE;
    record REDUCTION
      ReductionInfo reductionInfo;
      Exp expr;
      ReductionIterators iterators;
    end REDUCTION;
    record LIST
      list<Exp> valList;
    end LIST;
    record CONS
      Exp car;
      Exp cdr;
    end CONS;
    record META_TUPLE
      list<Exp> listExp;
    end META_TUPLE;
    record META_OPTION
      Option<Exp> exp;
    end META_OPTION;
    record METARECORDCALL
      Absyn.Path path;
      list<Exp> args;
      list<String> fieldNames;
      Integer index;
    end METARECORDCALL;
    record MATCHEXPRESSION
      DAE.MatchType matchType;
      list<Exp> inputs;
      list<list<String>> aliases;
      list<Element> localDecls;
      list<MatchCase> cases;
      Type et;
    end MATCHEXPRESSION;
    record BOX
      Exp exp;
    end BOX;
    record UNBOX
      Exp exp;
      Type ty;
    end UNBOX;
    record SHARED_LITERAL
      Integer index;
      Exp exp;
    end SHARED_LITERAL;
    record PATTERN
      Pattern pattern;
    end PATTERN;
  end Exp;

  uniontype CallAttributes
    record CALL_ATTR
      Type ty "The type of the return value, if several return values this is undefined";
      Boolean tuple_ "tuple" ;
      Boolean builtin "builtin Function call" ;
      Boolean isFunctionPointerCall;
      InlineType inlineType;
      TailCall tailCall "Input variables of the function if the call is tail-recursive";
    end CALL_ATTR;
  end CallAttributes;

  uniontype ReductionIterator
    record REDUCTIONITER
      String id;
      Exp exp;
      Option<Exp> guardExp;
      Type ty;
    end REDUCTIONITER;
  end ReductionIterator;

  type ReductionIterators = list<ReductionIterator>;

  uniontype ReductionInfo
    record REDUCTIONINFO "A separate uniontype containing the information not required by traverseExp, etc"
      Absyn.Path path "array, sum,..";
      Absyn.ReductionIterType iterType;
      Type exprType;
      Option<Values.Value> defaultValue "if there is no default value, the reduction is not defined for 0-length arrays/lists";
      String foldName;
      String resultName;
      Option<Exp> foldExp "For example, max(ident,$res) or ident+$res; array() does not use this feature; DO NOT TRAVERSE THIS EXPRESSION!";
    end REDUCTIONINFO;
  end ReductionInfo;

  uniontype MatchCase
    record CASE
      list<Pattern> patterns "ELSE is handled by not doing pattern-matching";
      Option<Exp> patternGuard;
      list<Element> localDecls;
      list<Statement> body;
      Option<Exp> result;
      builtin.SourceInfo resultInfo;
      Integer jump;
    end CASE;
  end MatchCase;

  uniontype Pattern "Patterns deconstruct expressions"
    record PAT_WILD "_"
    end PAT_WILD;
    record PAT_CONSTANT "compare to this constant value using equality"
      Option<Type> ty "so we can unbox if needed";
      Exp exp;
    end PAT_CONSTANT;
    record PAT_AS "id as pat"
      String id;
      Option<Type> ty;
      Pattern pat;
    end PAT_AS;
    record PAT_AS_FUNC_PTR "id as pat"
      String id;
      Pattern pat;
    end PAT_AS_FUNC_PTR;
    record PAT_META_TUPLE "(pat1,...,patn)"
      list<Pattern> patterns;
    end PAT_META_TUPLE;
    record PAT_CALL_TUPLE "(pat1,...,patn)"
      list<Pattern> patterns;
    end PAT_CALL_TUPLE;
    record PAT_CONS "head::tail"
      Pattern head;
      Pattern tail;
    end PAT_CONS;
    record PAT_CALL "RECORD(pat1,...,patn); all patterns are positional"
      Absyn.Path name;
      Integer index;
      list<Pattern> patterns;
      Boolean knownSingleton;
    end PAT_CALL;
    record PAT_CALL_NAMED "RECORD(pat1,...,patn); all patterns are named"
      Absyn.Path name;
      list<tuple<Pattern,String,Type>> patterns;
    end PAT_CALL_NAMED;
    record PAT_SOME "SOME(pat)"
      Pattern pat;
    end PAT_SOME;
  end Pattern;

  uniontype ComponentRef
    record CREF_QUAL
      Ident ident;
      Type identType;
      list<Subscript> subscriptLst;
      ComponentRef componentRef;
    end CREF_QUAL;
    record CREF_IDENT
      Ident ident;
      Type identType;
      list<Subscript> subscriptLst;
    end CREF_IDENT;
    record CREF_ITER "An iterator index; used in local scopes in for-loops and reductions"
      Ident ident;
      Integer index;
      Type identType "type of the identifier, without considering the subscripts";
      list<Subscript> subscriptLst;
    end CREF_ITER;
    record OPTIMICA_ATTR_INST_CREF
      ComponentRef componentRef;
      String instant;
    end OPTIMICA_ATTR_INST_CREF;
    record WILD end WILD;
  end ComponentRef;

  uniontype VarParallelism
    record PARGLOBAL     "Global variables for CUDA and OpenCL"     end PARGLOBAL;
    record PARLOCAL      "Shared for CUDA and local for OpenCL"     end PARLOCAL;
    record NON_PARALLEL  "Non parallel/Normal variables"            end NON_PARALLEL;
  end VarParallelism;

  uniontype Operator
    record ADD
      Type ty;
    end ADD;
    record SUB
      Type ty;
    end SUB;
    record MUL
      Type ty;
    end MUL;
    record DIV
      Type ty;
    end DIV;
    record POW
      Type ty;
    end POW;
    record UMINUS
      Type ty;
    end UMINUS;
    record UMINUS_ARR
      Type ty;
    end UMINUS_ARR;
    record ADD_ARR
      Type ty;
    end ADD_ARR;
    record SUB_ARR
      Type ty;
    end SUB_ARR;
    record MUL_ARR
      Type ty;
    end MUL_ARR;
    record DIV_ARR
      Type ty;
    end DIV_ARR;
    record MUL_ARRAY_SCALAR
      Type ty;
    end MUL_ARRAY_SCALAR;
    record ADD_ARRAY_SCALAR
      Type ty;
    end ADD_ARRAY_SCALAR;
    record SUB_SCALAR_ARRAY
      Type ty;
    end SUB_SCALAR_ARRAY;
    record MUL_SCALAR_PRODUCT
      Type ty;
    end MUL_SCALAR_PRODUCT;
    record MUL_MATRIX_PRODUCT
      Type ty;
    end MUL_MATRIX_PRODUCT;
    record DIV_ARRAY_SCALAR
      Type ty;
    end DIV_ARRAY_SCALAR;
    record DIV_SCALAR_ARRAY
      Type ty;
    end DIV_SCALAR_ARRAY;
    record POW_ARRAY_SCALAR
      Type ty;
    end POW_ARRAY_SCALAR;
    record POW_SCALAR_ARRAY
      Type ty;
    end POW_SCALAR_ARRAY;
    record POW_ARR
      Type ty;
    end POW_ARR;
    record POW_ARR2
      Type ty;
    end POW_ARR2;
    record AND
      Type ty;
    end AND;
    record OR
      Type ty;
    end OR;
    record NOT
      Type ty;
    end NOT;
    record LESS
      Type ty;
    end LESS;
    record LESSEQ
      Type ty;
    end LESSEQ;
    record GREATER
      Type ty;
    end GREATER;
    record GREATEREQ
      Type ty;
    end GREATEREQ;
    record EQUAL
      Type ty;
    end EQUAL;
    record NEQUAL
      Type ty;
    end NEQUAL;
    record USERDEFINED
      Absyn.Path fqName;
    end USERDEFINED;
  end Operator;

  uniontype Statement
    record STMT_ASSIGN
      Type type_;
      Exp exp1;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN;
    record STMT_ASSIGN_ARR
      Type type_;
      Exp lhs;
      Exp exp;
      ElementSource source;
    end STMT_ASSIGN_ARR;
    record STMT_TUPLE_ASSIGN
      Type type_;
      list<Exp> expExpLst;
      Exp exp;
      ElementSource source;
    end STMT_TUPLE_ASSIGN;
    record STMT_IF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
      ElementSource source;
    end STMT_IF;
    record STMT_FOR
      Type type_;
      Boolean iterIsArray;
      Ident iter;
      Exp range;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_FOR;
    record STMT_PARFOR
      Type type_;
      Boolean iterIsArray;
      Ident iter;
      Exp range;
      list<Statement> statementLst;
      list<tuple<DAE.ComponentRef,builtin.SourceInfo>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      ElementSource source;
    end STMT_PARFOR;
    record STMT_WHILE
      Exp exp;
      list<Statement> statementLst;
      ElementSource source;
    end STMT_WHILE;
    record STMT_WHEN
      Exp exp;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;
      list<Statement> statementLst;
      Option<Statement> elseWhen;
      ElementSource source;
    end STMT_WHEN;
    record STMT_TERMINATE
      Exp msg;
      ElementSource source;
    end STMT_TERMINATE;
    record STMT_ASSERT
      Exp cond;
      Exp msg;
      Exp level;
      ElementSource source;
    end STMT_ASSERT;
    record STMT_REINIT
      Exp var;
      Exp value;
      ElementSource source;
    end STMT_REINIT;
    record STMT_RETURN
      ElementSource source;
    end STMT_RETURN;
    record STMT_BREAK
      ElementSource source;
    end STMT_BREAK;
    record STMT_CONTINUE
      ElementSource source;
    end STMT_CONTINUE;
    record STMT_FAILURE
      list<Statement> body;
      ElementSource source;
    end STMT_FAILURE;
    record STMT_NORETCALL
      Exp exp;
      ElementSource source;
    end STMT_NORETCALL;
  end Statement;

  uniontype Else
    record NOELSE end NOELSE;
    record ELSEIF
      Exp exp;
      list<Statement> statementLst;
      Else else_;
    end ELSEIF;
    record ELSE
      list<Statement> statementLst;
    end ELSE;
  end Else;

  uniontype Var
    record TYPES_VAR
      Ident name;
      Attributes attributes;
      Type ty;
      Binding binding;
      Boolean bind_from_outside;
    end TYPES_VAR;
  end Var;

  uniontype Binding
    record UNBOUND end UNBOUND;

    record EQBOUND
      Exp exp;
      Option<Values.Value> evaluatedExp;
      Const constant_;
      BindingSource source;
    end EQBOUND;

    record VALBOUND
      Values.Value valBound;
      BindingSource source;
    end VALBOUND;
  end Binding;

  uniontype Type "models the different front-end and back-end types"

    record T_INTEGER
      list<Var> varLst;
    end T_INTEGER;

    record T_REAL
      list<Var> varLst;
    end T_REAL;

    record T_STRING
      list<Var> varLst;
    end T_STRING;

    record T_BOOL
      list<Var> varLst;
    end T_BOOL;

    record T_ENUMERATION "If the list of names is empty, this is the super-enumeration that is the super-class of all enumerations"
      Option<Integer> index "the enumeration value index, SOME for element, NONE() for type" ;
      Absyn.Path path "enumeration path" ;
      list<String> names "names" ;
      list<Var> literalVarLst;
      list<Var> attributeLst;
    end T_ENUMERATION;

    record T_ARRAY
      "an array can be represented in two equivalent ways:
         1. T_ARRAY(non_array_type, {dim1, dim2, dim3}) =
         2. T_ARRAY(T_ARRAY(T_ARRAY(non_array_type, {dim1}), {dim2}), {dim3})
         In general Inst generates 1 and all the others generates 2"
      Type ty "Type";
      Dimensions dims "dims";
    end T_ARRAY;

    record T_NORETCALL "For functions not returning any values."
    end T_NORETCALL;

    record T_UNKNOWN "Used when type is not yet determined"
    end T_UNKNOWN;

    record T_COMPLEX
      ClassInf.State complexClassType "The type of. a class" ;
      list<Var> varLst "The variables of a complex type" ;
      EqualityConstraint equalityConstraint;
    end T_COMPLEX;

    record T_SUBTYPE_BASIC
      ClassInf.State complexClassType "The type of. a class" ;
      list<Var> varLst "complexVarLst; The variables of a complex type! Should be empty, kept here to verify!";
      Type complexType "complexType; A complex type can be a subtype of another (primitive) type (through extends)";
      EqualityConstraint equalityConstraint;
    end T_SUBTYPE_BASIC;

    record T_FUNCTION
      list<FuncArg> funcArg;
      Type funcResultType "Only single-result" ;
      FunctionAttributes functionAttributes;
      Absyn.Path path;
    end T_FUNCTION;

    record T_FUNCTION_REFERENCE_VAR "MetaModelica Function Reference that is a variable"
      Type functionType "the type of the function";
    end T_FUNCTION_REFERENCE_VAR;

    record T_FUNCTION_REFERENCE_FUNC "MetaModelica Function Reference that is a direct reference to a function"
      Boolean builtin;
      Type functionType "type of the non-boxptr function";
    end T_FUNCTION_REFERENCE_FUNC;

    record T_TUPLE
      list<Type> types "For functions returning multiple values.";
      Option<list<String>> names "For tuples elements that have names (function outputs)";
    end T_TUPLE;

    record T_CODE
      CodeType ty;
    end T_CODE;

    record T_ANYTYPE
      Option<ClassInf.State> anyClassType "anyClassType - used for generic types. When class state present the type is assumed to be a complex type which has that restriction.";
    end T_ANYTYPE;

    // MetaModelica extensions
    record T_METALIST "MetaModelica list type"
      Type ty "listType";
    end T_METALIST;

    record T_METATUPLE "MetaModelica tuple type"
      list<Type> types;
    end T_METATUPLE;

    record T_METAOPTION "MetaModelica option type"
      Type ty;
    end T_METAOPTION;

    record T_METAUNIONTYPE "MetaModelica Uniontype, added by simbj"
      list<Absyn.Path> paths;
      Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
    end T_METAUNIONTYPE;

    record T_METARECORD "MetaModelica Record, used by Uniontypes. added by simbj"
      Absyn.Path path;
      Absyn.Path utPath "the path to its uniontype; this is what we match the type against";
      // If the metarecord constructor was added to the FunctionTree, this would
      // not be needed. They are used to create the datatype in the runtime...
      Integer index; //The index in the uniontype
      list<Var> fields;
      Boolean knownSingleton "The runtime system (dynload), does not know if the value is a singleton. But optimizations are safe if this is true.";
    end T_METARECORD;

    record T_METAARRAY
      Type ty;
    end T_METAARRAY;

    record T_METABOXED "Used for MetaModelica generic types"
      Type ty;
    end T_METABOXED;

    record T_METAPOLYMORPHIC
      String name;
    end T_METAPOLYMORPHIC;

    record T_METATYPE "this type contains all the meta types"
      Type ty;
    end T_METATYPE;

  end Type;

  type Dimensions = list<Dimension> "a list of dimensions";

  uniontype Dimension
    record DIM_INTEGER
      Integer integer;
    end DIM_INTEGER;

    record DIM_BOOLEAN
    end DIM_BOOLEAN;

    record DIM_ENUM
      Absyn.Path enumTypeName;
      list<String> literals;
      Integer size;
    end DIM_ENUM;

    record DIM_EXP
      Exp exp;
    end DIM_EXP;

    record DIM_UNKNOWN
    end DIM_UNKNOWN;
  end Dimension;

  uniontype CodeType
    record C_EXPRESSION
    end C_EXPRESSION;

    record C_TYPENAME
    end C_TYPENAME;

    record C_VARIABLENAME
    end C_VARIABLENAME;

    record C_VARIABLENAMES "Array of VariableName"
    end C_VARIABLENAMES;
  end CodeType;

  uniontype FunctionAttributes
    record FUNCTION_ATTRIBUTES
      Boolean isFunctionPointer;
    end FUNCTION_ATTRIBUTES;
  end FunctionAttributes;

  uniontype FuncArg
    record FUNCARG
      String name;
      Type ty;
      Const const;
      VarParallelism par;
      Option<Exp> defaultBinding;
    end FUNCARG;
  end FuncArg;

  uniontype Subscript
    record WHOLEDIM end WHOLEDIM;
    record WHOLE_NONEXP end WHOLE_NONEXP;
    record SLICE
      Exp exp;
    end SLICE;
    record INDEX
      Exp exp;
    end INDEX;
  end Subscript;

  uniontype MatchType
  record MATCHCONTINUE end MATCHCONTINUE;
  record TRY_STACKOVERFLOW end TRY_STACKOVERFLOW;
    record MATCH
      Option<tuple<Integer,Type,Integer>> switch;
    end MATCH;
  end MatchType;

  uniontype ElementSource
    record SOURCE
      builtin.SourceInfo info;
      list<Absyn.Within> partOfLst;
      ComponentPrefix instance;
      list<tuple<ComponentRef, ComponentRef>> connectEquationOptLst;
      list<Absyn.Path> typeLst;
      list<SymbolicOperation> operations;
    end SOURCE;
  end ElementSource;

  uniontype SymbolicOperation
    record FLATTEN "From one equation/statement to a list of DAE elements (in case it is expanded)"
      SCode.EEquation scode;
      Option<Element> dae;
    end FLATTEN;
    record SIMPLIFY
      EquationExp before;
      EquationExp after;
    end SIMPLIFY;
    record SUBSTITUTION
      list<Exp> substitutions;
      Exp source;
    end SUBSTITUTION;
    record OP_INLINE
      EquationExp before;
      EquationExp after;
    end OP_INLINE;
    record OP_SCALARIZE "x = {1,2}, [1] => x[1] = {1}"
      EquationExp before;
      Integer index;
      EquationExp after;
    end OP_SCALARIZE;
    record OP_DIFFERENTIATE
      ComponentRef cr;
      Exp before;
      Exp after;
    end OP_DIFFERENTIATE;

    record SOLVE
      ComponentRef cr;
      Exp exp1;
      Exp exp2;
      Exp res;
      list<Exp> assertConds;
    end SOLVE;
    record SOLVED
      ComponentRef cr;
      Exp exp;
    end SOLVED;
    record LINEAR_SOLVED
      list<ComponentRef> vars;
      list<list<Real>> jac;
      list<Real> rhs;
      list<Real> result;
    end LINEAR_SOLVED;
    record NEW_DUMMY_DER
      ComponentRef chosen;
      list<ComponentRef> candidates;
    end NEW_DUMMY_DER;
    record OP_RESIDUAL
      Exp e1;
      Exp e2;
      Exp e;
    end OP_RESIDUAL;
  end SymbolicOperation;

  uniontype EquationExp
    record PARTIAL_EQUATION
      Exp exp;
    end PARTIAL_EQUATION;
    record RESIDUAL_EXP
      Exp exp;
    end RESIDUAL_EXP;
    record EQUALITY_EXPS
      Exp lhs;
      Exp rhs;
    end EQUALITY_EXPS;
  end EquationExp;

  uniontype TailCall
    record NO_TAIL
    end NO_TAIL;
    record TAIL
      list<String> vars;
    end TAIL;
  end TailCall;


  uniontype FunctionParallelism
    record FP_NON_PARALLEL   "a normal function i.e non_parallel"    end FP_NON_PARALLEL;
    record FP_PARALLEL_FUNCTION "an OpenCL/CUDA parallel/device function" end FP_PARALLEL_FUNCTION;
    record FP_KERNEL_FUNCTION "an OpenCL/CUDA kernel function" end FP_KERNEL_FUNCTION;
  end FunctionParallelism;

  uniontype Constraint "The `Constraints\' type corresponds to a whole Constraint section.
  It is simply a list of expressions."
    record CONSTRAINT_EXPS
      list<Exp> constraintLst;
    end CONSTRAINT_EXPS;

    record CONSTRAINT_DT "Constraints needed for proper Dynamic Tearing"
      Exp constraint;
      Boolean localCon "local or global constraint; local constraints depend on variables that are computed within the algebraic loop itself";
    end CONSTRAINT_DT;
  end Constraint;

  uniontype ClassAttributes "currently for Optimica extension: these are the objectives of optimization class"
  record OPTIMIZATION_ATTRS
    Option<Exp> objetiveE;
    Option<Exp> objectiveIntegrandE;
    Option<Exp> startTimeE;
    Option<Exp> finalTimeE;
  end OPTIMIZATION_ATTRS;
end ClassAttributes;

  uniontype ComponentPrefix
  "Prefix for component name, e.g. a.b[2].c.
   NOTE: Component prefixes are stored in inverse order c.b[2].a!"
    record PRE
      String prefix "prefix name" ;
      list<DAE.Dimension> dimensions "dimensions" ;
      list<DAE.Subscript> subscripts "subscripts" ;
      ComponentPrefix next "next prefix" ;
      ClassInf.State ci_state "to be able to at least partially fill in type information properly for DAE.VAR";
      SourceInfo info;
    end PRE;

    record NOCOMPPRE end NOCOMPPRE;
  end ComponentPrefix;

end DAE;


package ClassInf

  uniontype State
    record UNKNOWN
      String string;
    end UNKNOWN;
    record MODEL
      String string;
    end MODEL;
    record RECORD
        Absyn.Path path;
    end RECORD;
    record BLOCK
      String string;
    end BLOCK;
    record CONNECTOR
      String string;
      Boolean isExpandable;
    end CONNECTOR;
    record TYPE
      String string;
    end TYPE;
    record PACKAGE
      String string;
    end PACKAGE;
    record FUNCTION
      String string;
    end FUNCTION;
    record ENUMERATION
      String string;
    end ENUMERATION;
    record HAS_EQUATIONS
      String string;
    end HAS_EQUATIONS;
    record IS_NEW
      String string;
    end IS_NEW;
    record TYPE_INTEGER
      String string;
    end TYPE_INTEGER;
    record TYPE_REAL
      String string;
    end TYPE_REAL;
    record TYPE_STRING
      String string;
    end TYPE_STRING;
    record TYPE_BOOL
      String string;
    end TYPE_BOOL;
    record TYPE_ENUM
      String string;
    end TYPE_ENUM;
    record EXTERNAL_OBJ
      Absyn.Path path;
    end EXTERNAL_OBJ;
  end State;

  function getStateName
    input State inState;
    output Absyn.Path outPath;
  end getStateName;

end ClassInf;

package SCode

type Ident = Absyn.Ident "Some definitions are borrowed from `Absyn\'";

type Path = Absyn.Path;

type Subscript = Absyn.Subscript;

uniontype Restriction
  record R_CLASS end R_CLASS;
  record R_OPTIMIZATION end R_OPTIMIZATION;
  record R_MODEL end R_MODEL;
  record R_RECORD
    Boolean isOperator;
  end R_RECORD;
  record R_BLOCK end R_BLOCK;
  record R_CONNECTOR "a connector"
    Boolean isExpandable "is expandable?";
  end R_CONNECTOR;
  record R_OPERATOR "an operator definition"
    Boolean isFunction "is this operator a function?";
  end R_OPERATOR;
  record R_TYPE end R_TYPE;
  record R_PACKAGE end R_PACKAGE;
  record R_FUNCTION end R_FUNCTION;
  record R_EXT_FUNCTION "Added c.t. Absyn" end R_EXT_FUNCTION;
  record R_ENUMERATION end R_ENUMERATION;

  // predefined internal types
  record R_PREDEFINED_INTEGER     "predefined IntegerType" end R_PREDEFINED_INTEGER;
  record R_PREDEFINED_REAL        "predefined RealType"    end R_PREDEFINED_REAL;
  record R_PREDEFINED_STRING      "predefined StringType"  end R_PREDEFINED_STRING;
  record R_PREDEFINED_BOOLEAN     "predefined BooleanType" end R_PREDEFINED_BOOLEAN;
  record R_PREDEFINED_ENUMERATION "predefined EnumType"    end R_PREDEFINED_ENUMERATION;

  // MetaModelica extensions
  record R_METARECORD "Metamodelica extension"
    Absyn.Path name; //Name of the uniontype
    Integer index; //Index in the uniontype
    Boolean moved;
  end R_METARECORD; /* added by x07simbj */

  record R_UNIONTYPE "Metamodelica extension"
  end R_UNIONTYPE; /* added by simbj */
end Restriction;

uniontype Mod "- Modifications"

  record MOD
    Final finalPrefix "final prefix";
    Each  eachPrefix "each prefix";
    list<SubMod> subModLst;
    Option<tuple<Absyn.Exp,Boolean>> binding "The binding expression of a modification
    has an expression and a Boolean delayElaboration which is true if elaboration(type checking)
    should be delayed. This can for instance be used when having A a(x = a.y) where a.y can not be
    type checked -before- a is instantiated, which is the current design in instantiation process.";
  end MOD;

  record REDECL
    Final         finalPrefix "final prefix";
    Each          eachPrefix "each prefix";
    list<Element> elementLst  "elements";
  end REDECL;

  record NOMOD end NOMOD;

end Mod;

uniontype SubMod "Modifications are represented in an more structured way than in
    the `Absyn\' module.  Modifications using qualified names
    (such as in `x.y =  z\') are normalized (to `x(y = z)\')."
  record NAMEMOD
    Ident ident;
    Mod A "A named component" ;
  end NAMEMOD;
end SubMod;

type Program = list<Element> "- Programs
As in the AST, a program is simply a list of class definitions.";

uniontype Enum "Enum, which is a name in an enumeration and an optional Comment."
  record ENUM
    Ident           literal;
    Option<Comment> comment;
  end ENUM;
end Enum;

uniontype ClassDef
"The major difference between these types and their Absyn
 counterparts is that the PARTS constructor contains separate
 lists for elements, equations and algorithms.

 SCode.PARTS contains elements of a class definition. For instance,
    model A
      extends B;
      C c;
    end A;
 Here PARTS contains two elements ('extends B' and 'C c')
 SCode.DERIVED is used for short class definitions, i.e:
  class A = B(modifiers);
 SCode.CLASS_EXTENDS is used for extended class definition, i.e:
  class extends A (modifier)
    new elements;
  end A;"

  record PARTS "a class made of parts"
    list<Element>              elementLst          "the list of elements";
    list<Equation>             normalEquationLst   "the list of equations";
    list<Equation>             initialEquationLst  "the list of initial equations";
    list<AlgorithmSection>     normalAlgorithmLst  "the list of algorithms";
    list<AlgorithmSection>     initialAlgorithmLst "the list of initial algorithms";
    Option<Absyn.ExternalDecl> externalDecl        "used by external functions";
    list<Annotation>           annotationLst       "the list of annotations found in between class elements, equations and algorithms";
    Option<Comment>            comment             "the class comment";
  end PARTS;

  record CLASS_EXTENDS "an extended class definition plus the additional parts"
    Ident                      baseClassName       "the name of the base class we have to extend";
    Mod                        modifications       "the modifications that need to be applied to the base class";
    ClassDef                   composition         "the new composition";
  end CLASS_EXTENDS;

  record DERIVED "a derived class"
    Absyn.TypeSpec typeSpec "typeSpec: type specification" ;
    Mod modifications       "the modifications";
    Attributes attributes   "the element attributes";
    Option<Comment> comment "the translated comment from the Absyn";
  end DERIVED;

  record ENUMERATION "an enumeration"
    list<Enum> enumLst      "if the list is empty it means :, the supertype of all enumerations";
    Option<Comment> comment "the translated comment from the Absyn";
  end ENUMERATION;

  record OVERLOAD "an overloaded function"
    list<Absyn.Path> pathLst "the path lists";
    Option<Comment> comment  "the translated comment from the Absyn";
  end OVERLOAD;

  record PDER "the partial derivative"
    Absyn.Path  functionPath     "function name" ;
    list<Ident> derivedVariables "derived variables" ;
    Option<Comment> comment      "the Absyn comment";
  end PDER;

end ClassDef;

uniontype Comment

  record COMMENT
    Option<Annotation> annotation_;
    Option<String> comment;
  end COMMENT;

  record CLASS_COMMENT
    list<Annotation> annotations;
    Option<Comment> comment;
  end CLASS_COMMENT;
end Comment;

uniontype Annotation

  record ANNOTATION
    Mod modification;
  end ANNOTATION;

end Annotation;

uniontype Equation "- Equations"
  record EQUATION "an equation"
    EEquation eEquation "an equation";
  end EQUATION;

end Equation;

uniontype EEquation
"These represent equations and are almost identical to their Absyn versions.
 In EQ_IF the elseif branches are represented as normal else branches with
 a single if statement in them."
  record EQ_IF
    list<Absyn.Exp> condition "conditional" ;
    list<list<EEquation>> thenBranch "the true (then) branch" ;
    list<EEquation>       elseBranch "the false (else) branch" ;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_IF;

  record EQ_EQUALS "the equality equation"
    Absyn.Exp expLeft  "the expression on the left side of the operator";
    Absyn.Exp expRight "the expression on the right side of the operator";
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_EQUALS;

  record EQ_PDE "PDE or boundary condition"
    Absyn.Exp expLeft  "the expression on the left side of the operator";
    Absyn.Exp expRight "the expression on the right side of the operator";
    ComponentRef domain;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_PDE;

  record EQ_CONNECT "the connect equation"
    Absyn.ComponentRef crefLeft  "the connector/component reference on the left side";
    Absyn.ComponentRef crefRight "the connector/component reference on the right side";
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_CONNECT;

  record EQ_FOR "the for equation"
    Ident           index        "the index name";
    Absyn.Exp       range        "the range of the index";
    list<EEquation> eEquationLst "the equation list";
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_FOR;

  record EQ_WHEN "the when equation"
    Absyn.Exp        condition "the when condition";
    list<EEquation>  eEquationLst "the equation list";
    list<tuple<Absyn.Exp, list<EEquation>>> tplAbsynExpEEquationLstLst "the elsewhen expression and equation list";
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_WHEN;

  record EQ_ASSERT "the assert equation"
    Absyn.Exp condition "the assert condition";
    Absyn.Exp message   "the assert message";
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_ASSERT;

  record EQ_TERMINATE "the terminate equation"
    Absyn.Exp message "the terminate message";
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_TERMINATE;

  record EQ_REINIT "a reinit equation"
    Absyn.ComponentRef cref      "the variable to initialize";
    Absyn.Exp          expReinit "the new value" ;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_REINIT;

  record EQ_NORETCALL "function calls without return value"
    Absyn.ComponentRef functionName "the function nanme";
    Absyn.FunctionArgs functionArgs "the function arguments";
    Option<Comment> comment;
    builtin.SourceInfo info;
  end EQ_NORETCALL;

end EEquation;

uniontype AlgorithmSection "- Algorithms
  The Absyn module uses the terminology from the
  grammar, where algorithm means an algorithmic
  statement. But here, an Algorithm means a whole
  algorithm section."
  record ALGORITHM "the algorithm section"
    list<Statement> statements "the algorithm statements" ;
  end ALGORITHM;

end AlgorithmSection;

uniontype Statement "The Statement type describes one algorithm statement in an algorithm section."
  record ALG_ASSIGN
    Absyn.Exp assignComponent "assignComponent" ;
    Absyn.Exp value "value" ;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_ASSIGN;

  record ALG_IF
    Absyn.Exp boolExpr;
    list<Statement> trueBranch;
    list<tuple<Absyn.Exp, list<Statement>>> elseIfBranch;
    list<Statement> elseBranch;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_IF;

  record ALG_FOR
    Absyn.ForIterators iterators;
    list<Statement> forBody "forBody" ;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_FOR;

  record ALG_WHILE
    Absyn.Exp boolExpr "boolExpr" ;
    list<Statement> whileBody "whileBody" ;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_WHILE;

  record ALG_WHEN_A
    list<tuple<Absyn.Exp, list<Statement>>> branches;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_WHEN_A;

  record ALG_NORETCALL
    Absyn.ComponentRef functionCall "functionCall" ;
    Absyn.FunctionArgs functionArgs "functionArgs; general fcalls without return value" ;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_NORETCALL;

  record ALG_RETURN
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_RETURN;

  record ALG_BREAK
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_BREAK;

  // Part of MetaModelica extension. KS
  record ALG_TRY
    list<Statement> tryBody;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_TRY;

  record ALG_CATCH
    list<Statement> catchBody;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_CATCH;

  record ALG_THROW
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_THROW;

  record ALG_FAILURE
    list<Statement> stmts;
    Option<Comment> comment;
    builtin.SourceInfo info;
  end ALG_FAILURE;
  //-------------------------------

end Statement;

// common prefixes to elements
uniontype Visibility "the visibility prefix"
  record PUBLIC    "a public element"    end PUBLIC;
  record PROTECTED "a protected element" end PROTECTED;
end Visibility;

uniontype Redeclare "the redeclare prefix"
  record REDECLARE     "a redeclare prefix"     end REDECLARE;
  record NOT_REDECLARE "a non redeclare prefix" end NOT_REDECLARE;
end Redeclare;

uniontype Replaceable "the replaceable prefix"
  record REPLACEABLE "a replaceable prefix containing an optional constraint"
    Option<Absyn.ConstrainClass> cc  "the constraint class";
  end REPLACEABLE;
  record NOT_REPLACEABLE "a non replaceable prefix" end NOT_REPLACEABLE;
end Replaceable;

uniontype Final "the final prefix"
  record FINAL    "a final prefix"      end FINAL;
  record NOT_FINAL "a non final prefix" end NOT_FINAL;
end Final;

uniontype Each "the each prefix"
  record EACH     "a each prefix"     end EACH;
  record NOT_EACH "a non each prefix" end NOT_EACH;
end Each;

uniontype Encapsulated "the encapsulated prefix"
  record ENCAPSULATED     "a encapsulated prefix"     end ENCAPSULATED;
  record NOT_ENCAPSULATED "a non encapsulated prefix" end NOT_ENCAPSULATED;
end Encapsulated;

uniontype Partial "the partial prefix"
  record PARTIAL     "a partial prefix"     end PARTIAL;
  record NOT_PARTIAL "a non partial prefix" end NOT_PARTIAL;
end Partial;

uniontype ConnectorType
  record POTENTIAL end POTENTIAL;
  record FLOW end FLOW;
  record STREAM end STREAM;
end ConnectorType;

uniontype Prefixes "the common class or component prefixes"
  record PREFIXES "the common class or component prefixes"
    Visibility       visibility           "the protected/public prefix";
    Redeclare        redeclarePrefix      "redeclare prefix";
    Final            finalPrefix          "final prefix, be it at the element or top level";
    Absyn.InnerOuter innerOuter           "the inner/outer/innerouter prefix";
    Replaceable      replaceablePrefix    "replaceable prefix";
  end PREFIXES;
end Prefixes;

uniontype Element "- Elements
  There are four types of elements in a declaration, represented by the constructors:
  IMPORT     (for import clauses)
  EXTENDS    (for extends clauses),
  CLASS      (for top/local class definitions)
  COMPONENT  (for local variables)
  DEFINEUNIT (for units)"

  record IMPORT "an import element"
    Absyn.Import imp                 "the import definition";
    Visibility   visibility          "the protected/public prefix";
    builtin.SourceInfo   info                "the import information";
  end IMPORT;

  record EXTENDS "the extends element"
    Path baseClassPath               "the extends path";
    Visibility visibility            "the protected/public prefix";
    Mod modifications                "the modifications applied to the base class";
    Option<Annotation> ann           "the extends annotation";
    builtin.SourceInfo info                  "the extends info";
  end EXTENDS;

  record CLASS "a class definition"
    Ident   name                     "the name of the class";
    Prefixes prefixes                "the common class or component prefixes";
    Encapsulated encapsulatedPrefix  "the encapsulated prefix";
    Partial partialPrefix            "the partial prefix";
    Restriction restriction          "the restriction of the class";
    ClassDef classDef                "the class specification";
    builtin.SourceInfo info                  "the class information";
  end CLASS;

  record COMPONENT "a component"
    Ident name                      "the component name";
    Prefixes prefixes               "the common class or component prefixes";
    Attributes attributes           "the component attributes";
    Absyn.TypeSpec typeSpec         "the type specification";
    Mod modifications               "the modifications to be applied to the component";
    Option<Comment> comment         "this if for extraction of comments and annotations from Absyn";
    Option<Absyn.Exp> condition     "the conditional declaration of a component";
    builtin.SourceInfo info                 "this is for line and column numbers, also file name.";
  end COMPONENT;

  record DEFINEUNIT "a unit defintion has a name and the two optional parameters exp, and weight"
    Ident name;
    Visibility visibility            "the protected/public prefix";
    Option<String> exp               "the unit expression";
    Option<Real> weight              "the weight";
  end DEFINEUNIT;

end Element;

uniontype Attributes "- Attributes"
  record ATTR "the attributes of the component"
    Absyn.ArrayDim arrayDims "the array dimensions of the component";
    ConnectorType connectorType;
    Variability variability " the variability: parameter, discrete, variable, constant" ;
    Absyn.Direction direction "the direction: input, output or bidirectional" ;
  end ATTR;
end Attributes;

uniontype Variability "the variability of a component"
  record VAR      "a variable"          end VAR;
  record DISCRETE "a discrete variable" end DISCRETE;
  record PARAM    "a parameter"         end PARAM;
  record CONST    "a constant"          end CONST;
end Variability;

uniontype Initial "the initial attribute of an algorithm or equation
 Intial is used as argument to instantiation-function for
 specifying if equations or algorithms are initial or not."
  record INITIAL     "an initial equation or algorithm" end INITIAL;
  record NON_INITIAL "a normal equation or algorithm"   end NON_INITIAL;
end Initial;

end SCode;

package SCodeDump
  constant SCodeDumpOptions defaultOptions;
end SCodeDump;

package Util

  uniontype DateTime
    record DATETIME
      Integer sec;
      Integer min;
      Integer hour;
      Integer mday;
      Integer mon;
      Integer year;
    end DATETIME;
  end DateTime;

  function stringReplaceChar
    input String inString1;
    input String inString2;
    input String inString3;
    output String outString;
  end stringReplaceChar;

  function escapeModelicaStringToCString
    input String modelicaString;
    output String cString;
  end escapeModelicaStringToCString;

  function escapeModelicaStringToXmlString
    input String modelicaString;
    output String xmlString;
  end escapeModelicaStringToXmlString;

  function getCurrentDateTime
    output DateTime dt;
  end getCurrentDateTime;

  function intProduct
    input list<Integer> lst;
    output Integer i;
  end intProduct;

   function mulStringDelimit2Int
    input String lst;
    input String delim;
    output Integer i;
  end mulStringDelimit2Int;

  function endsWith
    input String str;
    input String suffix;
    output Boolean b;
  end endsWith;

  function isCIdentifier
    input String str;
    output Boolean b;
  end isCIdentifier;

  function isSome
    replaceable type Type_a subtypeof Any;
    input Option<Type_a> inOption;
    output Boolean out;
  end isSome;

  function getOption
    replaceable type Type_a subtypeof Any;
    input Option<Type_a> inOption;
    output Type_a out;
  end getOption;

  function stringBool
  input String inString;
  output Boolean outBoolean;
  end stringBool;

end Util;

package List
  function fill
    input Type_a inTypeA;
    input Integer inInteger;
    output list<Type_a> outTypeALst;
    replaceable type Type_a subtypeof Any;
  end fill;

  function intRange
    input Integer inStop;
    output list<Integer> outRange;
  end intRange;

  function intRange3
    input Integer inStart;
    input Integer inStep;
    input Integer inStop;
    output list<Integer> outRange;
  end intRange3;

  function flatten
    input list<list<ElementType>> inList;
    output list<ElementType> outList;
    replaceable type ElementType subtypeof Any;
  end flatten;

  function lengthListElements
    input list<list<Type_a>> inListList;
    output Integer outLength;
    replaceable type Type_a subtypeof Any;
  end lengthListElements;

  function union
    input list<Type_a> inTypeALst1;
    input list<Type_a> inTypeALst2;
    output list<Type_a> outTypeALst;
    replaceable type Type_a subtypeof Any;
  end union;

  function lastN
    input list<Type_a> inTypeALst1;
     input Integer inN;
    output list<Type_a> outTypeALst;
    replaceable type Type_a subtypeof Any;
  end lastN;

  function threadTuple
    replaceable type Type_b subtypeof Any;
    input list<Type_a> inTypeALst;
    input list<Type_b> inTypeBLst;
    output list<tuple<Type_a, Type_b>> outTplTypeATypeBLst;
    replaceable type Type_a subtypeof Any;
  end threadTuple;

  function position
    replaceable type Type_a subtypeof Any;
    input Type_a inElement;
    input list<Type_a> inList;
    output Integer outPosition;
  end position;

  function splitEqualParts
    replaceable type Type_a subtypeof Any;
    input list<Type_a> inList;
    input Integer inParts;
    output list<list<Type_a>> outParts;
  end splitEqualParts;

  function rest
    replaceable type Type_a subtypeof Any;
    input list<Type_a> inList;
    output list<Type_a> outParts;
  end rest;

  function restOrEmpty
    replaceable type Type_a subtypeof Any;
    input list<Type_a> inList;
    output list<Type_a> outParts;
  end restOrEmpty;

  function setDifference
    replaceable type ElementType subtypeof Any;
    input list<ElementType> inList1;
    input list<ElementType> inList2;
    output list<ElementType> outDifference;
  end setDifference;

  function partition
    replaceable type ElementType subtypeof Any;
    input list<ElementType> inList;
    input Integer inPartitionLength;
    output list<list<ElementType>> outPartitions;
  end partition;

  function balancedPartition
    replaceable type ElementType subtypeof Any;
    input list<ElementType> inList;
    input Integer inPartitionLength;
    output list<list<ElementType>> outPartitions;
  end balancedPartition;

  function unzipSecond
    replaceable type Type_b subtypeof Any;
    input list<tuple<Type_a, Type_b>> inTplTypeATypeBLst;
    output list<Type_b> outTypeALst;
    replaceable type Type_a subtypeof Any;
  end unzipSecond;

  function last
    replaceable type ElementType subtypeof Any;
    input list<ElementType> inList;
    output ElementType val;
  end last;

  function partition
    replaceable type T subtypeof Any;
    input list<T> inList;
    input Integer inPartitionLength;
    output list<list<T>> outPartitions;
  end partition;
end List;

package ComponentReference

  function crefAppendedSubs
    input DAE.ComponentRef cref;
    output String s;
  end crefAppendedSubs;

  function makeUntypedCrefIdent
    input String ident;
    output DAE.ComponentRef outCrefIdent;
  end makeUntypedCrefIdent;

  function crefDims
    input DAE.ComponentRef cref;
    output list<DAE.Dimension> dims;
  end crefDims;

  function crefStripLastSubs
    input DAE.ComponentRef inComponentRef;
    output DAE.ComponentRef outComponentRef;
  end crefStripLastSubs;

  function crefStripSubs
    input DAE.ComponentRef inComponentRef;
    output DAE.ComponentRef outComponentRef;
  end crefStripSubs;

  function crefSubs
    input DAE.ComponentRef cref;
    output list<DAE.Subscript> subs;
  end crefSubs;

  function crefTypeFull
    input DAE.ComponentRef inRef;
    output DAE.Type res;
  end crefTypeFull;

  function crefLastType
    input DAE.ComponentRef inRef;
    output DAE.Type res;
  end crefLastType;

  function crefTypeConsiderSubs
    input DAE.ComponentRef cr;
    output DAE.Type res;
  end crefTypeConsiderSubs;

  function appendStringCref
    input String str;
    input DAE.ComponentRef cr;
    output DAE.ComponentRef ocr;
  end appendStringCref;

  function appendStringFirstIdent
    input String inString;
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef outCref;
  end appendStringFirstIdent;

  function expandArrayCref
    input DAE.ComponentRef inCr;
    input DAE.Dimensions dims;
    output list<DAE.ComponentRef> outCrefs;
  end expandArrayCref;

  function expandCref
    input DAE.ComponentRef inCref;
    input Boolean expandRecord;
    output list<DAE.ComponentRef> outCref;
  end expandCref;

  function crefHasScalarSubscripts
    input DAE.ComponentRef cr;
    output Boolean hasScalarSubs;
  end crefHasScalarSubscripts;

  function crefIsScalarWithAllConstSubs
    input DAE.ComponentRef inCref;
    output Boolean isScalar;
  end crefIsScalarWithAllConstSubs;

  function crefIsScalarWithVariableSubs
    input DAE.ComponentRef inCref;
    output Boolean isScalar;
  end crefIsScalarWithVariableSubs;

  function crefArrayGetFirstCref
    input DAE.ComponentRef inComponentRef;
    output DAE.ComponentRef outComponentRef;
  end crefArrayGetFirstCref;

  function crefPrefixPrevious
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef outCref;
  end crefPrefixPrevious;

  function crefPrefixPre
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef outCref;
  end crefPrefixPre;

  function crefPrefixDer
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef outCref;
  end crefPrefixDer;

  function crefPrefixPre
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef outCref;
  end crefPrefixPre;

  function makeUntypedCrefIdent
    input DAE.Ident ident;
    output DAE.ComponentRef outCrefIdent;
  end makeUntypedCrefIdent;

  function crefToPathIgnoreSubs
    input DAE.ComponentRef inComponentRef;
    output Absyn.Path outPath;
  end crefToPathIgnoreSubs;

  function crefPrefixStart
    input DAE.ComponentRef inCref;
    output DAE.ComponentRef outCref;
  end crefPrefixStart;

  function isStartCref
    input DAE.ComponentRef cr;
    output Boolean b;
  end isStartCref;

  function popCref
    input DAE.ComponentRef inCR;
    output DAE.ComponentRef outCR;
  end popCref;

  function crefRemovePrePrefix
    input DAE.ComponentRef inCR;
    output DAE.ComponentRef outCR;
  end crefRemovePrePrefix;

  function createDifferentiatedCrefName
    input DAE.ComponentRef inCref;
    input DAE.ComponentRef inX;
    input String inMatrixName;
    output DAE.ComponentRef outCref;
  end createDifferentiatedCrefName;
end ComponentReference;

package Expression

  function crefExp
    input DAE.ComponentRef cr;
    output DAE.Exp cref;
  end crefExp;

  function expCref
    input DAE.Exp inExp;
    output DAE.ComponentRef outComponentRef;
  end expCref;

  function isConst
   input DAE.Exp inExp;
   output Boolean outBoolean;
  end isConst;

  function subscriptConstants
    "returns true if all subscripts are known (i.e no cref) constant values (no slice or wholedim "
    input list<DAE.Subscript> inSubs;
    output Boolean areConstant;
  end subscriptConstants;

  function typeof
    input DAE.Exp inExp;
    output DAE.Type outType;
  end typeof;

  function isAtomic
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end isAtomic;

  function isHalf
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end isHalf;

  function isRealType
    input DAE.Type inType;
    output Boolean b;
  end isRealType;

  function realExpIntLit
    input DAE.Exp exp;
    output Option<Integer> oi;
  end realExpIntLit;

  function flattenArrayExpToList
    input DAE.Exp e;
    output list<DAE.Exp> expLst;
  end flattenArrayExpToList;

  function isArrayType
    input DAE.Type e;
    output Boolean b;
  end isArrayType;

  function isRecordType
    input DAE.Type e;
    output Boolean b;
  end isRecordType;

  function expHasCrefName "Returns a true if the exp contains a cref that starts with the given name"
    input DAE.Exp inExp;
    input String name;
    output Boolean hasCref;
  end expHasCrefName;

  function anyExpHasCrefName "Returns a true if the exp contains a cref that starts with the given name"
    input list<DAE.Exp> inExps;
    input String name;
    output Boolean hasCref;
  end anyExpHasCrefName;

  function isPositiveOrZero
    input DAE.Exp inExp;
    output Boolean outBoolean;
  end isPositiveOrZero;

  function extractUniqueCrefsFromExp
    input DAE.Exp inExp;
    output list<DAE.ComponentRef> ocrefs;
  end extractUniqueCrefsFromExp;

  function extractUniqueCrefsFromExpDerPreStart
    input DAE.Exp inExp;
    output list<DAE.ComponentRef> ocrefs;
  end extractUniqueCrefsFromExpDerPreStart;

  function extractUniqueCrefsFromStatmentS
    input list<DAE.Statement> inStmts;
    output tuple<list<DAE.ComponentRef>,list<DAE.ComponentRef>> ocrefs;
  end extractUniqueCrefsFromStatmentS;

  function isCrefListWithEqualIdents
    input list<DAE.Exp> iExpressions;
    output Boolean oCrefWithEqualIdents;
  end isCrefListWithEqualIdents;

  function dimensionsList
    input DAE.Dimensions inDims;
    output list<Integer> outValues;
  end dimensionsList;

  function expDimensionsList
    input list<DAE.Exp> inDims;
    output list<Integer> outValues;
  end expDimensionsList;


  function isMetaArray
    input DAE.Exp inExp;
    output Boolean outB;
  end isMetaArray;

  function getClockInterval
    input DAE.ClockKind inClk;
    output DAE.Exp outIntvl;
  end getClockInterval;

  function consToListIgnoreSharedLiteral
    input DAE.Exp e1;
    output DAE.Exp ee;
  end consToListIgnoreSharedLiteral;

  function dimensionSizeExpHandleUnkown
  "Converts (extracts) a dimension to an expression.
  This function will change unknown dims to DAE.ICONST(-1).
  we use it to handle unknown dims in code generation. unknown dims
  are okay if the variable is a function input (it's just holds the slot
  and will not be generated). Otherwise it's an error
  since it shouldn't have reached there."
    input DAE.Dimension dim;
    output DAE.Exp exp;
  end dimensionSizeExpHandleUnkown;

  function hasUnknownDims
    input list<DAE.Dimension> dims;
    output Boolean hasUnkown;
  end hasUnknownDims;

end Expression;

package ExpressionDump
  function binopSymbol
    input DAE.Operator inOperator;
    output String outString;
  end binopSymbol;

  function printExpStr
    input DAE.Exp exp;
    output String outString;
  end printExpStr;
end ExpressionDump;

package Config
  function acceptMetaModelicaGrammar
    output Boolean outBoolean;
  end acceptMetaModelicaGrammar;

  function acceptParModelicaGrammar
    output Boolean outBoolean;
  end acceptParModelicaGrammar;

  function acceptOptimicaGrammar
    output Boolean outBoolean;
  end acceptOptimicaGrammar;

  function noProc
    output Integer n;
  end noProc;

  function getDefaultOpenCLDevice
  "Returns the id for the default OpenCL device to be used."
    output Integer defdevid;
  end getDefaultOpenCLDevice;

  function simCodeTarget
    output String target;
  end simCodeTarget;

  function simulationCodeTarget
  "@author: adrpo
   returns: 'gcc' or 'msvc'
   usage: omc [+target=gcc|msvc], default to 'gcc'."
    output String outCodeTarget;
  end simulationCodeTarget;

  function profileHtml
    output Boolean outBoolean;
  end profileHtml;

  function profileSome
    output Boolean outBoolean;
  end profileSome;

  function profileAll
    output Boolean outBoolean;
  end profileAll;

  function profileFunctions
    output Boolean outBoolean;
  end profileFunctions;

  function typeinfo
    output Boolean flag;
  end typeinfo;

  function globalHomotopy
    output Boolean outBoolean;
  end globalHomotopy;

  function adaptiveHomotopy
    output Boolean outBoolean;
  end adaptiveHomotopy;
end Config;

package Testsuite
  function isRunning
    output Boolean runningTestsuite;
  end isRunning;

  function friendly
    input String in;
    output String out;
  end friendly;
end Testsuite;

package Flags
  uniontype DebugFlag end DebugFlag;
  uniontype ConfigFlag end ConfigFlag;

  constant DebugFlag HPCOM;
  constant DebugFlag HPCOM_MEMORY_OPT;
  constant DebugFlag GEN_DEBUG_SYMBOLS;
  constant DebugFlag WRITE_TO_BUFFER;
  constant DebugFlag MODEL_INFO_JSON;
  constant DebugFlag USEMPI;
  constant DebugFlag RUNTIME_STATIC_LINKING;
  constant DebugFlag HARDCODED_START_VALUES;
  constant DebugFlag OMC_RECORD_ALLOC_WORDS;
  constant DebugFlag OMC_RELOCATABLE_FUNCTIONS;
  constant DebugFlag NF_SCALARIZE;
  constant ConfigFlag PARMODAUTO;
  constant ConfigFlag NUM_PROC;
  constant ConfigFlag HPCOM_CODE;
  constant ConfigFlag PROFILING_LEVEL;
  constant ConfigFlag CPP_FLAGS;
  constant ConfigFlag MATRIX_FORMAT;
  constant ConfigFlag SYM_SOLVER;
  constant DebugFlag FMU_EXPERIMENTAL;
  constant DebugFlag MULTIRATE_PARTITION;
  constant ConfigFlag DAE_MODE;
  constant ConfigFlag EQUATIONS_PER_FILE;
  constant ConfigFlag GENERATE_SYMBOLIC_JACOBIAN;
  constant ConfigFlag HOMOTOPY_APPROACH;
  constant ConfigFlag GENERATE_LABELED_SIMCODE;
  constant ConfigFlag REDUCE_TERMS;
  constant ConfigFlag LABELED_REDUCTION;
  constant ConfigFlag LOAD_MSL_MODEL;
  constant ConfigFlag Load_PACKAGE_FILE;
  constant ConfigFlag SINGLE_INSTANCE_AGLSOLVER;
  constant ConfigFlag LINEARIZATION_DUMP_LANGUAGE;
  constant ConfigFlag USE_ZEROMQ_IN_SIM;
  constant ConfigFlag ZEROMQ_PUB_PORT;
  constant ConfigFlag ZEROMQ_SUB_PORT;
  constant ConfigFlag ZEROMQ_JOB_ID;
  constant ConfigFlag ZEROMQ_SERVER_ID;
  constant ConfigFlag ZEROMQ_CLIENT_ID;
  constant ConfigFlag FMI_FILTER;

  function isSet
    input DebugFlag inFlag;
    output Boolean outValue;
  end isSet;

  function getConfigBool
    input ConfigFlag inFlag;
    output Boolean outValue;
  end getConfigBool;

  function getConfigInt
    input ConfigFlag inFlag;
    output Integer outValue;
  end getConfigInt;

  function getConfigString
    input ConfigFlag inFlag;
    output String outValue;
  end getConfigString;

  function getConfigEnum
    input ConfigFlag inFlag;
    output Integer outValue;
  end getConfigEnum;

  function getConfigStringList
    input ConfigFlag inFlag;
    output list<String> outValue;
  end getConfigStringList;

end Flags;
package FlagsUtil
  function set
    input Flags.DebugFlag inFlag;
    input Boolean inValue;
    output Boolean outOldValue;
  end set;

  function configuredWithClang
    output Boolean yes;
  end configuredWithClang;
end FlagsUtil;
package Settings
  function getVersionNr
    output String outString;
  end getVersionNr;
end Settings;

package Patternm
  function getValueCtor
    input Integer ix;
    output Integer ctor;
  end getValueCtor;
  function sortPatternsByComplexity
    input list<DAE.Pattern> inPatterns;
    output list<tuple<DAE.Pattern,Integer>> outPatterns;
  end sortPatternsByComplexity;
end Patternm;

package Error
  function infoStr
    input builtin.SourceInfo info;
    output String str;
  end infoStr;
end Error;

package Values
end Values;

package ValuesUtil
  function valueExp
    input Values.Value inValue;
    output DAE.Exp outExp;
  end valueExp;
end ValuesUtil;

package DAEDump

  function ppStmtStr
    input DAE.Statement stmt;
    input Integer inInteger;
    output String outString;
  end ppStmtStr;

end DAEDump;

package Algorithm
  function getStatementSource
    input DAE.Statement stmt;
    output DAE.ElementSource source;
  end getStatementSource;
end Algorithm;

package ElementSource
  function getElementSourceFileInfo
    input DAE.ElementSource source;
    output builtin.SourceInfo info;
  end getElementSourceFileInfo;
end ElementSource;

package DAEUtil

  function statementsContainReturn
    input list<DAE.Statement> stmts;
    output Boolean b;
  end statementsContainReturn;

  function statementsContainTryBlock
    input list<DAE.Statement> stmts;
    output Boolean b;
  end statementsContainTryBlock;

end DAEUtil;

package Types
  function arrayElementType
    input DAE.Type inType;
    output DAE.Type outType;
  end arrayElementType;
  function getDimensionSizes
    input DAE.Type inType;
    output list<Integer> outIntegerLst;
  end getDimensionSizes;
  function unparseType
    input DAE.Type inType;
    output String str;
  end unparseType;
  function dimensionsKnown
    input DAE.Type inType;
    output Boolean outRes;
  end dimensionsKnown;
  function findVarIndex
    input String id;
    input list<DAE.Var> vars;
    output Integer index;
  end findVarIndex;
 function liftTypeWithDims
    input DAE.Type inType;
    input list<DAE.Dimension> inDimensionLst;
    output DAE.Type outType;
  end liftTypeWithDims;
 function unliftArray
    input DAE.Type inType;
    output DAE.Type outType;
  end unliftArray;
  function lookupIndexInMetaRecord
    input list<DAE.Var> vars;
    input String name;
    output Integer index;
  end lookupIndexInMetaRecord;
  function isArrayWithUnknownDimension
    input DAE.Type ty;
    output Boolean b;
  end isArrayWithUnknownDimension;
  function getMetaRecordFields
    input DAE.Type ty;
    output list<DAE.Var> fields;
  end getMetaRecordFields;
  function unboxedType
    input DAE.Type boxedType;
    output DAE.Type ty;
  end unboxedType;
end Types;

package HashTableCrIListArray
  type Key = DAE.ComponentRef;
  type Value = tuple<list<Integer>, array<Integer>>;

  type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
  type HashTable = tuple<
    array<list<tuple<Key,Integer>>>,
    tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
    Integer,
    Integer,
    HashTableCrefFunctionsType
  >;

  function FuncHashCref
    input Key cr;
    input Integer mod;
    output Integer res;
  end FuncHashCref;

  function FuncCrefEqual
    input Key cr1;
    input Key cr2;
    output Boolean res;
  end FuncCrefEqual;

  function FuncCrefStr
    input Key cr;
    output String res;
  end FuncCrefStr;

  function FuncExpStr
    input Value exp;
    output String res;
  end FuncExpStr;
end HashTableCrIListArray;

end SimCodeTV;
