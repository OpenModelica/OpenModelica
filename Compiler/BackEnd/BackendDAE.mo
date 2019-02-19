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

encapsulated package BackendDAE
" file:        BackendDAE.mo
  package:     BackendDAE
  description: BackendDAE contains the data-types used by the back end.
"

import Absyn;
import AvlSetPath;
import DAE;
import DoubleEndedList;
import ExpandableArray;
import FCore;
import HashTable3;
import HashTableCG;
import MMath;
import SCode;
import ZeroCrossings;

public
type Type = .DAE.Type
"Once we are in BackendDAE, the Type can be only basic types or enumeration.
 We cannot do this in DAE because functions may contain many more types.
 adrpo: yes we can, we just simplify the DAE.Type, see Types.simplifyType";

public
uniontype BackendDAE "THE LOWERED DAE consist of variables and equations. The variables are split into
  two lists, one for unknown variables states and algebraic and one for known variables
  constants and parameters.
  The equations are also split into two lists, one with simple equations, a=b, a-b=0, etc., that
  are removed from  the set of equations to speed up calculations."
  record DAE
    EqSystems eqs;
    Shared shared;
  end DAE;
end BackendDAE;

public
type EqSystems = list<EqSystem>;

public
uniontype EqSystem "An independent system of equations (and their corresponding variables)"
  record EQSYSTEM
    Variables orderedVars                   "ordered Variables, only states and alg. vars";
    EquationArray orderedEqs                "ordered Equations";
    Option<IncidenceMatrix> m;
    Option<IncidenceMatrixT> mT;
    Matching matching;
    StateSets stateSets                    "the state sets of the system";
    BaseClockPartitionKind partitionKind;
    EquationArray removedEqs               "these are equations that cannot solve for a variable.
                                            e.g. assertions, external function calls, algorithm sections without effect";
  end EQSYSTEM;
end EqSystem;

public uniontype SubClock
  record SUBCLOCK
    MMath.Rational factor;
    MMath.Rational shift;
    Option<String> solver;
  end SUBCLOCK;
  record INFERED_SUBCLOCK
  end INFERED_SUBCLOCK;
end SubClock;

public constant SubClock DEFAULT_SUBCLOCK = SUBCLOCK(MMath.RAT1, MMath.RAT0, NONE());

public
uniontype BaseClockPartitionKind
  record UNKNOWN_PARTITION end UNKNOWN_PARTITION;
  record CLOCKED_PARTITION
    Integer subPartIdx;
  end CLOCKED_PARTITION;
  record CONTINUOUS_TIME_PARTITION end CONTINUOUS_TIME_PARTITION;
  record UNSPECIFIED_PARTITION "treated as CONTINUOUS_TIME_PARTITION" end UNSPECIFIED_PARTITION;
end BaseClockPartitionKind;



public
uniontype Shared "Data shared for all equation-systems"
  record SHARED
    Variables globalKnownVars               "variables only depending on parameters and constants [TODO: move stuff (like inputs) to localKnownVars]";
    Variables localKnownVars                "variables only depending on locally constant variables in the simulation step, i.e. states, input variables";
    Variables externalObjects               "External object variables";
    Variables aliasVars                     "Data originating from removed simple equations needed to build
                                             variables' lookup table (in C output).
                                             In that way, double buffering of variables in pre()-buffer, extrapolation
                                             buffer and results caching, etc., is avoided, but in C-code output all the
                                             data about variables' names, comments, units, etc. is preserved as well as
                                             pointer to their values (trajectories).";
    EquationArray initialEqs                "Initial equations";
    EquationArray removedEqs                "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect";
    list< .DAE.Constraint> constraints     "constraints (Optimica extension)";
    list< .DAE.ClassAttributes> classAttrs "class attributes (Optimica extension)";
    FCore.Cache cache;
    FCore.Graph graph;
    .DAE.FunctionTree functionTree          "functions for Backend";
    EventInfo eventInfo                     "eventInfo";
    ExternalObjectClasses extObjClasses     "classes of external objects, contains constructor & destructor";
    BackendDAEType backendDAEType           "indicate for what the BackendDAE is used";
    SymbolicJacobians symjacs               "Symbolic Jacobians";
    ExtraInfo info "contains extra info that we send around like the model name";
    PartitionsInfo partitionsInfo;
    BackendDAEModeData daeModeData "DAEMode Data";
    Option<DataReconciliationData> dataReconciliationData;
  end SHARED;
end Shared;

uniontype InlineData
  record INLINE_DATA
    EqSystems inlineSystems;
    Variables knownVariables;
  end INLINE_DATA;
end InlineData;

uniontype BasePartition
  record BASE_PARTITION
    .DAE.ClockKind clock;
    Integer nSubClocks;
  end BASE_PARTITION;
end BasePartition;

uniontype SubPartition
  record SUB_PARTITION
    SubClock clock;
    Boolean holdEvents;
    list<.DAE.ComponentRef> prevVars;
  end SUB_PARTITION;
end SubPartition;

uniontype PartitionsInfo
  record PARTITIONS_INFO
    array<BasePartition> basePartitions;
    array<SubPartition> subPartitions;
  end PARTITIONS_INFO;
end PartitionsInfo;

uniontype ExtraInfo "extra information that we should send around with the DAE"
  record EXTRA_INFO "extra information that we should send around with the DAE"
    String description "the model description string";
    String fileNamePrefix "the model name to be used in the dumps";
  end EXTRA_INFO;
end ExtraInfo;

public
uniontype BackendDAEType "BackendDAEType to indicate different types of BackendDAEs.
  For example for simulation, initialization, Jacobian, algebraic loops etc."
  record SIMULATION      "Type for the normal BackendDAE.DAE for simulation" end SIMULATION;
  record JACOBIAN        "Type for Jacobian BackendDAE.DAE"                  end JACOBIAN;
  record ALGEQSYSTEM     "Type for algebraic loop BackendDAE.DAE"            end ALGEQSYSTEM;
  record ARRAYSYSTEM     "Type for multi dim equation arrays BackendDAE.DAE" end ARRAYSYSTEM;
  record PARAMETERSYSTEM "Type for parameter system BackendDAE.DAE"          end PARAMETERSYSTEM;
  record INITIALSYSTEM   "Type for initial system BackendDAE.DAE"            end INITIALSYSTEM;
  record INLINESYSTEM    "Type for inline system BackendDAE.DAE"             end INLINESYSTEM;
  record DAEMODESYSTEM   "Type for DAEmode system BackendDAE.DAE"            end DAEMODESYSTEM;
end BackendDAEType;

uniontype DataReconciliationData
  record DATA_RECON
    Jacobian symbolicJacobian "SET_S w.r.t ...";
    Variables setcVars "setc solved vars";
    // ... maybe more DATA for the code generation
  end DATA_RECON;
end DataReconciliationData;

//
//  variables and equations definition
//

public
uniontype Variables
  record VARIABLES
    array<list<CrefIndex>> crefIndices "HashTB, cref->indx";
    VariableArray varArr "Array of variables";
    Integer bucketSize "bucket size";
    Integer numberOfVars "no. of vars";
  end VARIABLES;
end Variables;

public
uniontype CrefIndex "Component Reference Index"
  record CREFINDEX
    .DAE.ComponentRef cref;
    Integer index;
  end CREFINDEX;
end CrefIndex;

public
uniontype VariableArray "array of Equations are expandable, to amortize the cost of adding
  equations in a more efficient manner"
  record VARIABLE_ARRAY
    Integer numberOfElements "no. elements";
    array<Option<Var>> varOptArr;
  end VARIABLE_ARRAY;
end VariableArray;

public
type EquationArray = ExpandableArray<Equation>;

public
uniontype Var "variables"
  record VAR
    .DAE.ComponentRef varName "variable name";
    VarKind varKind "kind of variable";
    .DAE.VarDirection varDirection "input, output or bidirectional";
    .DAE.VarParallelism varParallelism "parallelism of the variable. parglobal, parlocal or non-parallel";
    Type varType "built-in type or enumeration";
    Option<.DAE.Exp> bindExp "Binding expression e.g. for parameters";
    Option<.DAE.Exp> tplExp "Variable is part of a tuple. Needed for the globalKnownVars and localKnownVars";
    .DAE.InstDims arryDim "array dimensions of non-expanded var";
    .DAE.ElementSource source "origin of variable";
    Option<.DAE.VariableAttributes> values "values on built-in attributes";
    Option<TearingSelect> tearingSelectOption "value for TearingSelect";
    .DAE.Exp hideResult "expression from the hideResult annotation";
    Option<SCode.Comment> comment "this contains the comment and annotation from Absyn";
    .DAE.ConnectorType connectorType "flow, stream, unspecified or not connector.";
    .DAE.VarInnerOuter innerOuter "inner, outer, inner outer or unspecified";
    Boolean unreplaceable "indicates if it is allowed to replace this variable";
  end VAR;
end Var;

public
uniontype VarKind "variable kind"
  record VARIABLE end VARIABLE;
  record STATE
    Integer index "how often this states was differentiated";
    Option< .DAE.ComponentRef> derName "the name of the derivative";
  end STATE;
  record STATE_DER end STATE_DER;
  record DUMMY_DER end DUMMY_DER;
  record DUMMY_STATE end DUMMY_STATE;
  record CLOCKED_STATE
    .DAE.ComponentRef previousName "the name of the previous variable";
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
    .DAE.ComponentRef replaceExp;
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

public uniontype TearingSelect
  record NEVER end NEVER;
  record AVOID end AVOID;
  record DEFAULT end DEFAULT;
  record PREFER end PREFER;
  record ALWAYS end ALWAYS;
end TearingSelect;

public constant String WHENCLK_PRREFIX = "$whenclk";
public uniontype EquationKind "equation kind"
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

public uniontype EvaluationStages "evaluation stages"
  record EVALUATION_STAGES
    Boolean dynamicEval;
    Boolean algebraicEval;
    Boolean zerocrossEval;
    Boolean discreteEval;
  end EVALUATION_STAGES;
end EvaluationStages;

public constant EvaluationStages defaultEvalStages = EVALUATION_STAGES(false,false,false,false);

public uniontype EquationAttributes
  record EQUATION_ATTRIBUTES
    Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
    EquationKind kind;
    EvaluationStages evalStages;
  end EQUATION_ATTRIBUTES;
end EquationAttributes;

public constant EquationAttributes EQ_ATTR_DEFAULT_DYNAMIC = EQUATION_ATTRIBUTES(false, DYNAMIC_EQUATION(),defaultEvalStages);
public constant EquationAttributes EQ_ATTR_DEFAULT_BINDING = EQUATION_ATTRIBUTES(false, BINDING_EQUATION(),defaultEvalStages);
public constant EquationAttributes EQ_ATTR_DEFAULT_INITIAL = EQUATION_ATTRIBUTES(false, INITIAL_EQUATION(),defaultEvalStages);
public constant EquationAttributes EQ_ATTR_DEFAULT_DISCRETE = EQUATION_ATTRIBUTES(false, DISCRETE_EQUATION(),defaultEvalStages);
public constant EquationAttributes EQ_ATTR_DEFAULT_AUX = EQUATION_ATTRIBUTES(false, AUX_EQUATION(),defaultEvalStages);
public constant EquationAttributes EQ_ATTR_DEFAULT_UNKNOWN = EQUATION_ATTRIBUTES(false, UNKNOWN_EQUATION_KIND(),defaultEvalStages);

public
uniontype Equation
  record EQUATION
    .DAE.Exp exp;
    .DAE.Exp scalar;
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end EQUATION;

  record ARRAY_EQUATION
    list<Integer> dimSize "dimension sizes";
    .DAE.Exp left "lhs";
    .DAE.Exp right "rhs";
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end ARRAY_EQUATION;

  record SOLVED_EQUATION
    .DAE.ComponentRef componentRef;
    .DAE.Exp exp;
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end SOLVED_EQUATION;

  record RESIDUAL_EQUATION
    .DAE.Exp exp "not present from FrontEnd";
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end RESIDUAL_EQUATION;

  record ALGORITHM
    Integer size "size of equation";
    .DAE.Algorithm alg;
    .DAE.ElementSource source "origin of algorithm";
    .DAE.Expand expand "this algorithm was translated from an equation. we should not expand array crefs!";
    EquationAttributes attr;
  end ALGORITHM;

  record WHEN_EQUATION
    Integer size "size of equation";
    WhenEquation whenEquation;
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end WHEN_EQUATION;

  record COMPLEX_EQUATION "complex equations: recordX = function call(x, y, ..);"
     Integer size "size of equation";
    .DAE.Exp left "lhs";
    .DAE.Exp right "rhs";
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end COMPLEX_EQUATION;

  record IF_EQUATION "an if-equation"
    list< .DAE.Exp> conditions "Condition";
    list<list<Equation>> eqnstrue "Equations of true branch";
    list<Equation> eqnsfalse "Equations of false branch";
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end IF_EQUATION;

  record FOR_EQUATION "a for-equation"
    .DAE.Exp iter "the iterator variable";
    .DAE.Exp start "start of iteration";
    .DAE.Exp stop "end of iteration";
    Equation body "iterated equation";
    .DAE.ElementSource source "origin of equation";
    EquationAttributes attr;
  end FOR_EQUATION;

  record DUMMY_EQUATION
  end DUMMY_EQUATION;
end Equation;

public
uniontype WhenEquation
  record WHEN_STMTS "equation when condition then cr = exp, reinit(...), terminate(...) or assert(...)"
    .DAE.Exp condition                "the when-condition" ;
    list<WhenOperator> whenStmtLst;
    Option<WhenEquation> elsewhenPart "elsewhen equation with the same cref on the left hand side.";
  end WHEN_STMTS;
end WhenEquation;

public
uniontype WhenOperator
  record ASSIGN " left_cr = right_exp"
    .DAE.Exp left     "left hand side of equation";
    .DAE.Exp right             "right hand side of equation";
    .DAE.ElementSource source  "origin of equation";
  end ASSIGN;

  record REINIT "Reinit Statement"
    .DAE.ComponentRef stateVar "State variable to reinit";
    .DAE.Exp value             "Value after reinit";
    .DAE.ElementSource source  "origin of equation";
  end REINIT;

  record ASSERT
    .DAE.Exp condition;
    .DAE.Exp message;
    .DAE.Exp level;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end ASSERT;

  record TERMINATE "The Modelica built-in terminate(msg)"
    .DAE.Exp message;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end TERMINATE;

  record NORETCALL "call with no return value, i.e. no equation.
    Typically side effect call of external function but also
    Connections.* i.e. Connections.root(...) functions."
    .DAE.Exp exp;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end NORETCALL;
end WhenOperator;

public
type ExternalObjectClasses = list<ExternalObjectClass>
"classes of external objects stored in list";

public
uniontype ExternalObjectClass "class of external objects"
  record EXTOBJCLASS
    Absyn.Path path "className of external object";
    .DAE.ElementSource source "origin of equation";
  end EXTOBJCLASS;
end ExternalObjectClass;

//
//  Matching, strong components and StateSets
//

public
uniontype Matching
  record NO_MATCHING "matching has not yet been performed" end NO_MATCHING;
  record MATCHING "not yet used"
    array<Integer> ass1 "ass[varindx]=eqnindx";
    array<Integer> ass2 "ass[eqnindx]=varindx";
    StrongComponents comps;
  end MATCHING;
end Matching;

public
uniontype IndexReduction
  record INDEX_REDUCTION "Use index reduction during matching" end INDEX_REDUCTION;
  record NO_INDEX_REDUCTION "do not use index reduction during matching" end NO_INDEX_REDUCTION;
end IndexReduction;

public
uniontype EquationConstraints
  record ALLOW_UNDERCONSTRAINED "for e.g. initial eqns.
                  where not all variables
                  have a solution" end ALLOW_UNDERCONSTRAINED;

  record EXACT "exact as many equations
                   as variables" end EXACT;
end EquationConstraints;

public
type MatchingOptions = tuple<IndexReduction, EquationConstraints>;

public
type StructurallySingularSystemHandlerArg = tuple<StateOrder,ConstraintEquations,array<list<Integer>>,array<Integer>,Integer>
"StateOrder,ConstraintEqns,Eqn->EqnsIndxes,EqnIndex->Eqns,NrOfEqnsbeforeIndexReduction";

public
type ConstraintEquations = array<list<Equation>>;

public
uniontype StateOrder
  record STATEORDER
    HashTableCG.HashTable hashTable "x -> dx";
    HashTable3.HashTable invHashTable "dx -> {x,y,z}";
  end STATEORDER;
  record NOSTATEORDER "Index reduction disabled; don't need big hashtables"
  end NOSTATEORDER;
end StateOrder;

public
type StrongComponents = list<StrongComponent> "Order of the equations the have to be solved";

public
uniontype StrongComponent
  record SINGLEEQUATION
    Integer eqn;
    Integer var;
  end SINGLEEQUATION;

  record EQUATIONSYSTEM
    list<Integer> eqns;
    list<Integer> vars "be careful with states, this are solved for der(x)";
    Jacobian jac;
    JacobianType jacType;
    Boolean mixedSystem "true for system that discrete dependencies to the iteration variables";
  end EQUATIONSYSTEM;

  record SINGLEARRAY
    Integer eqn;
    list<Integer> vars "be careful with states, this are solved for der(x)";
  end SINGLEARRAY;

  record SINGLEALGORITHM
    Integer eqn;
    list<Integer> vars "be careful with states, this are solved for der(x)";
  end SINGLEALGORITHM;

  record SINGLECOMPLEXEQUATION
    Integer eqn;
    list<Integer> vars "be careful with states, this are solved for der(x)";
  end SINGLECOMPLEXEQUATION;

  record SINGLEWHENEQUATION
    Integer eqn;
    list<Integer> vars "be careful with states, this are solved for der(x)";
  end SINGLEWHENEQUATION;

  record SINGLEIFEQUATION
    Integer eqn;
    list<Integer> vars "be careful with states, this are solved for der(x)";
  end SINGLEIFEQUATION;

  record TORNSYSTEM
    TearingSet strictTearingSet;
    Option<TearingSet> casualTearingSet;
    Boolean linear;
    Boolean mixedSystem "true for system that discrete dependencies to the iteration variables";
  end TORNSYSTEM;
end StrongComponent;

public
uniontype TearingSet
  record TEARINGSET
    list<Integer> tearingvars;
    list<Integer> residualequations;
    InnerEquations innerEquations "list of matched equations and variables; these will be solved explicitly in the given order";
    Jacobian jac;
  end TEARINGSET;
end TearingSet;

type InnerEquations = list<InnerEquation>;

public
uniontype InnerEquation
  record INNEREQUATION
    Integer eqn;
    list<Integer> vars;
  end INNEREQUATION;

  record INNEREQUATIONCONSTRAINTS
    Integer eqn;
    list<Integer> vars;
    Constraints cons;
  end INNEREQUATIONCONSTRAINTS;
end InnerEquation;


public
type StateSets = list<StateSet> "List of StateSets";

public
uniontype StateSet
  record STATESET
    Integer rang; // how many states are needed?
    list< .DAE.ComponentRef> state;
    .DAE.ComponentRef crA "set.x=A*states";
    list< Var> varA; //the jacobian matrix entries
    list< Var> statescandidates; //all state candidates
    list< Var> ovars; //other variables to solve the eqns
    list< Equation> eqns; //the constraint equations
    list< Equation> oeqns; //other equations to solve the eqns
    .DAE.ComponentRef crJ; // the jac vector
    list< Var> varJ;
    Jacobian jacobian;
  end STATESET;
end StateSet;

//
// event info and stuff
//

public
uniontype EventInfo
  record EVENT_INFO
    list<TimeEvent> timeEvents         "stores all information related to time events";
    ZeroCrossingSet zeroCrossings "list of zero crossing conditions";
    DoubleEndedList<ZeroCrossing> relations    "list of zero crossing function as before";
    ZeroCrossingSet samples       "[deprecated] list of sample as before, only used by cpp runtime (TODO: REMOVE ME)";
    Integer numberMathEvents           "stores the number of math function that trigger events e.g. floor, ceil, integer, ...";
  end EVENT_INFO;
end EventInfo;

uniontype ZeroCrossingSet
  record ZERO_CROSSING_SET
    DoubleEndedList<ZeroCrossing> zc;
    array<ZeroCrossings.Tree> tree;
  end ZERO_CROSSING_SET;
end ZeroCrossingSet;

public
uniontype ZeroCrossing
  record ZERO_CROSSING
    .DAE.Exp relation_         "function";
    list<Integer> occurEquLst  "list of equations where the function occurs";
  end ZERO_CROSSING;
end ZeroCrossing;

public
uniontype TimeEvent
  record SIMPLE_TIME_EVENT "e.g. time > 0.5"
  end SIMPLE_TIME_EVENT;

  record SAMPLE_TIME_EVENT "e.g. sample(1, 1)"
    Integer index "unique sample index";
    .DAE.Exp startExp;
    .DAE.Exp intervalExp;
  end SAMPLE_TIME_EVENT;
end TimeEvent;

//
// AdjacencyMatrixes
//
public
type IncidenceMatrixElementEntry = Integer;
type IncidenceMatrixElement = list<IncidenceMatrixElementEntry>;
type IncidenceMatrix = array<IncidenceMatrixElement> "array<list<Integer>>";
type IncidenceMatrixT = IncidenceMatrix
"a list of equation indices (1..n), one for each variable. Equations that -only-
 contain the state variable and not the derivative have a negative index.";

public
type AdjacencyMatrix = IncidenceMatrix;
type AdjacencyMatrixT = IncidenceMatrixT;

public
type AdjacencyMatrixElementEnhancedEntry = tuple<Integer,Solvability,Constraints>;
type AdjacencyMatrixElementEnhanced = list<AdjacencyMatrixElementEnhancedEntry>;
type AdjacencyMatrixEnhanced = array<AdjacencyMatrixElementEnhanced>;
type AdjacencyMatrixTEnhanced = AdjacencyMatrixEnhanced;

public
uniontype Solvability
  record SOLVABILITY_SOLVED "Equation is already solved for the variable" end SOLVABILITY_SOLVED;
  record SOLVABILITY_CONSTONE "Coefficient is equal 1 or -1" end SOLVABILITY_CONSTONE;
  record SOLVABILITY_CONST "Coefficient is constant"
    Boolean b "false if the constant is almost zero (<1e-6)";
  end SOLVABILITY_CONST;
  record SOLVABILITY_PARAMETER "Coefficient contains parameters"
    Boolean b "false if the partial derivative is zero";
  end SOLVABILITY_PARAMETER;
  record SOLVABILITY_LINEAR "Coefficient contains variables, is time varying"
    Boolean b "false if the partial derivative is zero";
  end SOLVABILITY_LINEAR;
  record SOLVABILITY_NONLINEAR "The variable occurs non-linear in the equation." end SOLVABILITY_NONLINEAR;
  record SOLVABILITY_UNSOLVABLE "The variable occurs in the equation, but it is not possible to solve
                     the equation for it." end SOLVABILITY_UNSOLVABLE;
  record SOLVABILITY_SOLVABLE "It is possible to solve the equation for the variable, it is not considered
                     how the variable occurs in the equation." end SOLVABILITY_SOLVABLE;
end Solvability;

public
type Constraints = list<.DAE.Constraint> "Constraints on the solvability of the (casual) tearing set; needed for proper Dynamic Tearing";

public
uniontype IndexType
  record ABSOLUTE "incidence matrix with absolute indexes" end ABSOLUTE;
  record NORMAL "incidence matrix with positive/negative indexes" end NORMAL;
  record SOLVABLE "incidence matrix with only solvable entries, for example {a,b,c}[d] then d is skipped" end SOLVABLE;
  record BASECLOCK_IDX "incidence matrix for base-clock partitioning" end BASECLOCK_IDX;
  record SUBCLOCK_IDX "incidence matrix for sub-clock partitioning" end SUBCLOCK_IDX;
  record SPARSE "incidence matrix as normal, but add for inputs also a value" end SPARSE;
end IndexType;

//
// Jacobian stuff
//

public
uniontype JacobianType
  record JAC_CONSTANT "If Jacobian has only constant values, for system
               of equations this means that it can be solved statically." end JAC_CONSTANT;

  record JAC_LINEAR "If Jacobian has time varying parts, like parameters or
                  algebraic variables" end JAC_LINEAR;

  record JAC_NONLINEAR "If Jacobian contains variables that are solved for,
              means that a non-linear system of equations needs to be
              solved" end JAC_NONLINEAR;
  record JAC_GENERIC "GENERIC_JACOBIAN Jacobian available" end JAC_GENERIC;

  record JAC_NO_ANALYTIC "No analytic Jacobian available" end JAC_NO_ANALYTIC;
end JacobianType;

public constant Integer SymbolicJacobianAIndex = 1;
public constant Integer SymbolicJacobianBIndex = 2;
public constant Integer SymbolicJacobianCIndex = 3;
public constant Integer SymbolicJacobianDIndex = 4;

public constant String derivativeNamePrefix = "$DERAlias";
public constant String partialDerivativeNamePrefix = "$pDER";
public constant String functionDerivativeNamePrefix = "$funDER";
public constant String outputAliasPrefix = "$outputAlias_";

public constant String optimizationMayerTermName = "$OMC$objectMayerTerm";
public constant String optimizationLagrangeTermName = "$OMC$objectLagrangeTerm";
public constant String symSolverDT = "__OMC_DT";
public constant String homotopyLambda = "__HOM_LAMBDA";

type FullJacobian = Option<list<tuple<Integer, Integer, Equation>>>;

public
uniontype Jacobian
  record FULL_JACOBIAN
    FullJacobian jacobian;
  end FULL_JACOBIAN;

  record GENERIC_JACOBIAN
    Option<SymbolicJacobian> jacobian;
    SparsePattern sparsePattern;
    SparseColoring coloring;
  end GENERIC_JACOBIAN;

  record EMPTY_JACOBIAN end EMPTY_JACOBIAN;
end Jacobian;

public
type SymbolicJacobians = list<tuple<Option<SymbolicJacobian>, SparsePattern, SparseColoring>>;

public
type SymbolicJacobian = tuple<BackendDAE,               // symbolic equation system
                              String,                   // Matrix name
                              list<Var>,                // diff vars (independent vars)
                              list<Var>,                // diffed vars (residual vars)
                              list<Var>                 // all diffed vars (residual vars + dependent vars)
                              >;

public
type SparsePattern = tuple<list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>>, // column-wise sparse pattern
                           list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>>, // row-wise sparse pattern
                           tuple<list< .DAE.ComponentRef>,                            // diff vars
                                 list< .DAE.ComponentRef>>,                           // diffed vars
                           Integer>;                                                  // nonZeroElements

public
constant SparsePattern emptySparsePattern = ({},{},({},{}),0);

public
type SparseColoring = list<list< .DAE.ComponentRef>>;   // colouring


public
uniontype DifferentiateInputData
  record DIFFINPUTDATA
    Option<Variables> independenentVars;          // Independent variables
    Option<Variables> dependenentVars;            // Dependent variables
    Option<Variables> knownVars;                  // known variables (e.g. parameter, constants, ...)
    Option<Variables> allVars;                    // all variables
    list< Var> controlVars;                       // variables to save control vars of for algorithm
    list< .DAE.ComponentRef> diffCrefs;           // all crefs to differentiate, needed for generic gradient
    Option<String> matrixName;                    // name to create temporary vars, needed for generic gradient
    AvlSetPath.Tree diffedFunctions;              // current functions, to prevent recursive differentiation
  end DIFFINPUTDATA;
end DifferentiateInputData;

public constant DifferentiateInputData emptyInputData = DIFFINPUTDATA(NONE(),NONE(),NONE(),NONE(),{},{},NONE(),AvlSetPath.EMPTY());

public
type DifferentiateInputArguments = tuple< .DAE.ComponentRef, DifferentiateInputData, DifferentiationType, .DAE.FunctionTree>;

public
uniontype DifferentiationType "Define the behaviour of differentiation method for (e.g. index reduction, ...)"
  record DIFFERENTIATION_TIME "Used for index reduction differentiation w.r.t. time (e.g. create dummy derivative variables)"
  end DIFFERENTIATION_TIME;

  record SIMPLE_DIFFERENTIATION "Used to solve expression for a cref or by the older Jacobian generation, differentiation w.r.t. a given cref"
  end SIMPLE_DIFFERENTIATION;

  record DIFFERENTIATION_FUNCTION "Used to differentiate a function call w.r.t. a given cref, which need to expand the input arguments
                                  by differentiate arguments."
  end DIFFERENTIATION_FUNCTION;

  record DIFF_FULL_JACOBIAN "Used to generate a full Jacobian matrix"
  end DIFF_FULL_JACOBIAN;

  record GENERIC_GRADIENT "Used to generate a generic gradient for generation the Jacobian matrix while the runtime."
  end GENERIC_GRADIENT;
end DifferentiationType;

public uniontype CompInfo"types to count operations for the components"
  record COUNTER // single equation
   StrongComponent comp;
   Integer numAdds;
   Integer numMul;
   Integer numDiv;
   Integer numTrig;
   Integer numRelations;
   Integer numLog; // logical operations
   Integer numOth; // pow,...
   Integer funcCalls;
  end COUNTER;

  record SYSTEM//linear system of equations
   StrongComponent comp;
   CompInfo allOperations;
   Integer size;
   Real density;
  end SYSTEM;

  record TORN_ANALYSE//torn system of equations
   StrongComponent comp;
   CompInfo tornEqs;
   CompInfo otherEqs;
   Integer tornSize;
  end TORN_ANALYSE;

  record NO_COMP // assert...
   Integer numAdds;
   Integer numMul;
   Integer numDiv;
   Integer numTrig;
   Integer numRelations;
   Integer numLog; // logical operations
   Integer numOth; // pow,...
   Integer funcCalls;
  end NO_COMP;

end CompInfo;

public
uniontype BackendDAEModeData
  record BDAE_MODE_DATA
    list<Var> stateVars;
    list<Var> algStateVars;

    Integer numResVars;

    Option<Variables> modelVars;
  end BDAE_MODE_DATA;
end BackendDAEModeData;
constant BackendDAEModeData emptyDAEModeData = BDAE_MODE_DATA({},{},0,NONE());

annotation(__OpenModelica_Interface="backend");
end BackendDAE;
