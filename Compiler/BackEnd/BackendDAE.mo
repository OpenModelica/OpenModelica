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

encapsulated package BackendDAE
" file:        BackendDAE.mo
  package:     BackendDAE
  description: BackendDAE contains the datatypes used by the backend.

  RCS: $Id$
"

public import Absyn;
public import DAE;
public import Env;
public import SCode;
public import Values;
public import HashTable3;
public import HashTableCG;

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
type EqSystems = list<EqSystem>
"NOTE: BackEnd does not yet support lists with different size than 1 everywhere (anywhere)";

public
uniontype EqSystem "An independent system of equations (and their corresponding variables)"
  record EQSYSTEM
    Variables orderedVars "ordered Variables, only states and alg. vars" ;
    EquationArray orderedEqs "ordered Equations" ;
    Option<IncidenceMatrix> m;
    Option<IncidenceMatrixT> mT;
    Matching matching;
    StateSets stateSets "the statesets of the system";
  end EQSYSTEM;
end EqSystem;

public
uniontype Shared "Data shared for all equation-systems"
  record SHARED
    Variables knownVars                     "Known variables, i.e. constants and parameters" ;
    Variables externalObjects               "External object variables";
    Variables aliasVars                     "Data originating from removed simple equations needed to build
                                             variables' lookup table (in C output).

                                             In that way, double buffering of variables in pre()-buffer, extrapolation
                                             buffer and results caching, etc., is avoided, but in C-code output all the
                                             data about variables' names, comments, units, etc. is preserved as well as
                                             pinter to their values (trajectories).";
    EquationArray initialEqs                "Initial equations" ;
    EquationArray removedEqs                "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    list< .DAE.Constraint> constraints     "constraints (Optimica extension)";
    list< .DAE.ClassAttributes> classAttrs "class attributes (Optimica extension)";
    Env.Cache cache;
    Env.Env env;
    .DAE.FunctionTree functionTree          "functions for Backend";
    EventInfo eventInfo                     "eventInfo" ;
    ExternalObjectClasses extObjClasses     "classes of external objects, contains constructor & destructor";
    BackendDAEType backendDAEType           "indicate for what the BackendDAE is used";
    SymbolicJacobians symjacs               "Symbolic Jacobians";
    ExtraInfo info "contains extra info that we send around like the model name";
  end SHARED;
end Shared;

uniontype ExtraInfo "extra information that we should send arround with the DAE"
  record EXTRA_INFO "extra information that we should send arround with the DAE"
    String fileNamePrefix "the model name to be used in the dumps";
  end EXTRA_INFO;
end ExtraInfo;

public
uniontype BackendDAEType "BackendDAEType to indicate different types of BackendDAEs.
  For example for simulation, initialization, jacobian, algebraic loops etc."
  record SIMULATION      "Type for the normal BackendDAE.DAE for simulation" end SIMULATION;
  record JACOBIAN        "Type for jacobian BackendDAE.DAE"                  end JACOBIAN;
  record ALGEQSYSTEM     "Type for algebraic loop BackendDAE.DAE"            end ALGEQSYSTEM;
  record ARRAYSYSTEM     "Type for multidim equation arrays BackendDAE.DAE"  end ARRAYSYSTEM;
  record PARAMETERSYSTEM "Type for parameter system BackendDAE.DAE"          end PARAMETERSYSTEM;
  record INITIALSYSTEM   "Type for initial system BackendDAE.DAE"            end INITIALSYSTEM;
end BackendDAEType;

//
//  variables and equations definition
// 

public
uniontype Variables
  record VARIABLES
    array<list<CrefIndex>> crefIdxLstArr "HashTB, cref->indx";
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
    Integer numberOfElements "no. elements" ;
    Integer arrSize "array size" ;
    array<Option<Var>> varOptArr;
  end VARIABLE_ARRAY;
end VariableArray;

public
uniontype EquationArray
  record EQUATION_ARRAY
    Integer size "size of the Equations in scalar form";
    Integer numberOfElement "no. elements" ;
    Integer arrSize "array size" ;
    array<Option<Equation>> equOptArr;
  end EQUATION_ARRAY;
end EquationArray;

public
uniontype Var "variables"
  record VAR
    .DAE.ComponentRef varName "variable name" ;
    VarKind varKind "Kind of variable" ;
    .DAE.VarDirection varDirection "input, output or bidirectional" ;
    .DAE.VarParallelism varParallelism "parallelism of the variable. parglobal, parlocal or non-parallel";
    Type varType "builtin type or enumeration" ;
    Option< .DAE.Exp> bindExp "Binding expression e.g. for parameters" ;
    Option<Values.Value> bindValue "binding value for parameters" ;
    .DAE.InstDims arryDim "array dimensions on nonexpanded var" ;
    .DAE.ElementSource source "origin of variable" ;
    Option< .DAE.VariableAttributes> values "values on builtin attributes" ;
    Option<SCode.Comment> comment "this contains the comment and annotation from Absyn" ;
    .DAE.ConnectorType connectorType "flow, stream, unspecified or not connector.";
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
  record DISCRETE end DISCRETE;
  record PARAM end PARAM;
  record CONST end CONST;
  record EXTOBJ Absyn.Path fullClassName; end EXTOBJ;
  record JAC_VAR end JAC_VAR;
  record JAC_DIFF_VAR end JAC_DIFF_VAR;
  record OPT_CONSTR end OPT_CONSTR;
end VarKind;

public
uniontype Equation
  record EQUATION
    .DAE.Exp exp;
    .DAE.Exp scalar;
    .DAE.ElementSource source "origin of equation";
    Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
  end EQUATION;

  record ARRAY_EQUATION
    list<Integer> dimSize "dimension sizes" ;
    .DAE.Exp left "lhs" ;
    .DAE.Exp right "rhs" ;
    .DAE.ElementSource source "the element source";
    Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
  end ARRAY_EQUATION;

  record SOLVED_EQUATION
    .DAE.ComponentRef componentRef;
    .DAE.Exp exp;
    .DAE.ElementSource source "origin of equation";
    Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
  end SOLVED_EQUATION;

  record RESIDUAL_EQUATION
    .DAE.Exp exp "not present from FrontEnd" ;
    .DAE.ElementSource source "origin of equation";
     Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
  end RESIDUAL_EQUATION;

  record ALGORITHM
    Integer size "size of equation" ;
    .DAE.Algorithm alg;
    .DAE.ElementSource source "origin of algorithm";
    .DAE.Expand expand "this algorithm was translated from an equation. we should not expand array crefs!";
  end ALGORITHM;

  record WHEN_EQUATION
    Integer size "size of equation";
    WhenEquation whenEquation;
    .DAE.ElementSource source "origin of equation";
  end WHEN_EQUATION;

  record COMPLEX_EQUATION "complex equations: recordX = function call(x, y, ..);"
     Integer size "size of equation" ;
    .DAE.Exp left "lhs" ;
    .DAE.Exp right "rhs" ;
    .DAE.ElementSource source "the element source";
     Boolean differentiated "true if the equation was differentiated, and should not differentiated again to avoid equal equations";
  end COMPLEX_EQUATION;

  record IF_EQUATION "an if-equation"
    list< .DAE.Exp> conditions "Condition";
    list<list<Equation>> eqnstrue "Equations of true branch";
    list<Equation> eqnsfalse "Equations of false branch";
    .DAE.ElementSource source "origin of equation";
  end IF_EQUATION;
end Equation;

public
uniontype WhenEquation
  record WHEN_EQ "equation when condition then left = right; [elsewhenPart] end when;"
    .DAE.Exp condition                "the when-condition" ;
    .DAE.ComponentRef left            "left hand side of equation" ;
    .DAE.Exp right                    "right hand side of equation" ;
    Option<WhenEquation> elsewhenPart "elsewhen equation with the same cref on the left hand side.";
  end WHEN_EQ;
end WhenEquation;

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
type ConstraintEquations = list<tuple<Integer,list<Equation>>>;

public
uniontype StateOrder
  record STATEORDER
    HashTableCG.HashTable hashTable "x -> dx";
    HashTable3.HashTable invHashTable "dx -> {x,y,z}";
  end STATEORDER;
end StateOrder;

public
type StrongComponents = list<StrongComponent> "Order of the equations the have to be solved" ;

public
uniontype StrongComponent
  record SINGLEEQUATION
    Integer eqn;
    Integer var;
  end SINGLEEQUATION;

  record EQUATIONSYSTEM
    list<Integer> eqns;
    list<Integer> vars "be carefule with states, this are solved for der(x)";
    Option<list<tuple<Integer, Integer, Equation>>> jac;
    JacobianType jacType;
  end EQUATIONSYSTEM;

  record MIXEDEQUATIONSYSTEM
    StrongComponent condSystem;
    list<Integer> disc_eqns;
    list<Integer> disc_vars;
  end MIXEDEQUATIONSYSTEM;

  record SINGLEARRAY
    Integer eqn;
    list<Integer> vars "be carefule with states, this are solved for der(x)";
  end SINGLEARRAY;

  record SINGLEALGORITHM
    Integer eqn;
    list<Integer> vars "be carefule with states, this are solved for der(x)";
  end SINGLEALGORITHM;

  record SINGLECOMPLEXEQUATION
    Integer eqn;
    list<Integer> vars "be carefule with states, this are solved for der(x)";
  end SINGLECOMPLEXEQUATION;

  record SINGLEWHENEQUATION
    Integer eqn;
    list<Integer> vars "be carefule with states, this are solved for der(x)";
  end SINGLEWHENEQUATION;

  record SINGLEIFEQUATION
    Integer eqn;
    list<Integer> vars "be carefule with states, this are solved for der(x)";
  end SINGLEIFEQUATION;

  record TORNSYSTEM
    list<Integer> tearingvars;
    list<Integer> residualequations;
    list<tuple<Integer,list<Integer>>> otherEqnVarTpl "list of tuples of indexes for Equation and Variable solved in the equation, in the order they have to be solved";
    Boolean linear;
  end TORNSYSTEM;
end StrongComponent;

public
type StateSets = list<StateSet> "List of StateSets";

public
uniontype StateSet
  record STATESET
    Integer rang;
    list< .DAE.ComponentRef> state;
    .DAE.ComponentRef crA "set.x=A*states";
    list< Var> varA;
    list< Var> statescandidates;
    list< Var> ovars;
    list< Equation> eqns;
    list< Equation> oeqns;
    .DAE.ComponentRef crJ;
    list< Var> varJ;
  end STATESET;
end StateSet;

//
// event info and stuff
//

public
uniontype EventInfo
  record EVENT_INFO
    list<TimeEvent> timeEvents         "stores all information regarding time events" ;
    list<WhenClause> whenClauseLst     "list of when clauses. The WhenEquation datatype refer to this list by position" ;
    list<ZeroCrossing> zeroCrossingLst "list of zero crossing coditions";
    // TODO: sampleLst and relationsLst could be removed if cpp runtime is prepared to handle zero crossing conditions
    list<ZeroCrossing> sampleLst       "list of sample as before, used by cpp runtime";
    list<ZeroCrossing> relationsLst    "list of zero crossing function as before, used by cpp runtime";
    Integer relationsNumber            "stores the number of relation in all zero-crossings";
    Integer numberMathEvents           "stores the number of math function that trigger events e.g. floor, ceil, integer, ...";
  end EVENT_INFO;
end EventInfo;

public
uniontype WhenOperator
  record REINIT "Reinit Statement"
    .DAE.ComponentRef stateVar "State variable to reinit" ;
    .DAE.Exp value             "Value after reinit" ;
    .DAE.ElementSource source  "origin of equation";
  end REINIT;

  record ASSERT
    .DAE.Exp condition;
    .DAE.Exp message;
    .DAE.Exp level;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end ASSERT;

  record TERMINATE "The Modelica builtin terminate(msg)"
    .DAE.Exp message;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end TERMINATE;

  record NORETCALL "call with no return value, i.e. no equation.
    Typically sideeffect call of external function but also
    Connections.* i.e. Connections.root(...) functions."
    Absyn.Path functionName;
    list< .DAE.Exp> functionArgs;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end NORETCALL;
end WhenOperator;

public
uniontype WhenClause
  record WHEN_CLAUSE
    .DAE.Exp condition               "the when-condition" ;
    list<WhenOperator> reinitStmtLst "list of reinit statements associated to the when clause." ;
    Option<Integer> elseClause       "index of elsewhen clause" ;

    // HL only needs to know if it is an elsewhen the equations take care of which clauses are related.

    // The equations associated to the clause are linked to this when clause by the index in the
    // when clause list where this when clause is stored.
  end WHEN_CLAUSE;
end WhenClause;

public
uniontype ZeroCrossing
  record ZERO_CROSSING
    .DAE.Exp relation_         "function" ;
    list<Integer> occurEquLst  "list of equations where the function occurs" ;
    list<Integer> occurWhenLst "list of when clauses where the function occurs" ;
  end ZERO_CROSSING;
end ZeroCrossing;

public
uniontype TimeEvent
  record SIMPLE_TIME_EVENT "e.g. time > 0.5"
  end SIMPLE_TIME_EVENT;
  
  record COMPLEX_TIME_EVENT "e.g. sin(time) > 0.1"
  end COMPLEX_TIME_EVENT;
  
  record SAMPLE_TIME_EVENT "e.g. sample(1, 1)"
    Integer index "unique sample index" ;
    .DAE.Exp startExp;
    .DAE.Exp intervalExp;
  end SAMPLE_TIME_EVENT;
end TimeEvent;

//
// AdjacencyMatrixes
//

public
type IncidenceMatrixElementEntry = Integer;

public
type IncidenceMatrixElement = list<IncidenceMatrixElementEntry>;

public
type IncidenceMatrix = array<IncidenceMatrixElement>;

public
type IncidenceMatrixT = IncidenceMatrix
"a list of equation indices (1..n), one for each variable. Equations that -only-
 contain the state variable and not the derivative have a negative index.";

public
type AdjacencyMatrixElementEnhancedEntry = tuple<Integer,Solvability>;

public
type AdjacencyMatrixElementEnhanced = list<AdjacencyMatrixElementEnhancedEntry>;

public
type AdjacencyMatrixEnhanced = array<AdjacencyMatrixElementEnhanced>;

public
type AdjacencyMatrixTEnhanced = AdjacencyMatrixEnhanced;

public
uniontype Solvability
  record SOLVABILITY_SOLVED "Equation is already solved for the variable" end SOLVABILITY_SOLVED;
  record SOLVABILITY_CONSTONE "Coefficient is equal 1 or -1" end SOLVABILITY_CONSTONE;
  record SOLVABILITY_CONST "Coefficient is constant" end SOLVABILITY_CONST;
  record SOLVABILITY_PARAMETER "Coefficient contains parameters"
    Boolean b "false if the partial derivative is zero";
  end SOLVABILITY_PARAMETER;
  record SOLVABILITY_TIMEVARYING "Coefficient contains variables, is time varying"
    Boolean b "false if the partial derivative is zero";
  end SOLVABILITY_TIMEVARYING;
  record SOLVABILITY_NONLINEAR "The variable occurse nonlinear in the equation." end SOLVABILITY_NONLINEAR;
  record SOLVABILITY_UNSOLVABLE "The variable occurse in the equation, but it is not posible to solve
                     the equation for it." end SOLVABILITY_UNSOLVABLE;
end Solvability;

public
uniontype IndexType
  record ABSOLUTE "produce incidence matrix with absolute indexes"          end ABSOLUTE;
  record NORMAL   "produce incidence matrix with positive/negative indexes" end NORMAL;
  record SOLVABLE "procude incidence matrix with only solvable entries, for example {a,b,c}[d] then d is skipped" end SOLVABLE;
  record SPARSE   "produce incidence matrix as normal, but add for Inputs also a value" end SPARSE;
end IndexType;

//
// Jacobian stuff
//

public
uniontype JacobianType
  record JAC_CONSTANT "If jacobian has only constant values, for system
               of equations this means that it can be solved statically." end JAC_CONSTANT;

  record JAC_TIME_VARYING "If jacobian has time varying parts, like parameters or
                  algebraic variables" end JAC_TIME_VARYING;

  record JAC_NONLINEAR "If jacobian contains variables that are solved for,
              means that a nonlinear system of equations needs to be
              solved" end JAC_NONLINEAR;

  record JAC_NO_ANALYTIC "No analytic jacobian available" end JAC_NO_ANALYTIC;
end JacobianType;

public constant Integer SymbolicJacobianAIndex = 1;
public constant Integer SymbolicJacobianBIndex = 2;
public constant Integer SymbolicJacobianCIndex = 3;
public constant Integer SymbolicJacobianDIndex = 4;
public constant Integer SymbolicJacobianGIndex = 5;

public constant String partialDerivativeNamePrefix = "$pDER";
public constant String functionDerivativeNamePrefix = "$funDER";

public
type SymbolicJacobians = list<tuple<Option<SymbolicJacobian>, SparsePattern, SparseColoring>>;

public
type SymbolicJacobian = tuple<BackendDAE,               // symbolic equation system
                              String,                   // Matrix name
                              list<Var>,                // diff vars
                              list<Var>,                // result diffed equation
                              list<Var>                 // all diffed equation
                              >;

public
type SparsePattern = tuple<list<tuple< .DAE.ComponentRef, list< .DAE.ComponentRef>>>, // column-wise sparse pattern
                           tuple<list< .DAE.ComponentRef>,                            // diff vars
                                 list< .DAE.ComponentRef>>>;                          // diffed vars

public
type SparseColoring = list<list< .DAE.ComponentRef>>;   // coloring


public 
uniontype DifferentiateInputData
  record DIFFINPUTDATA
    Option<Variables> independenentVars;          // Independent variables
    Option<Variables> dependenentVars;            // Dependent variables
    Option<Variables> knownVars;                  // known variables (e.g. parameter, constants, ...)  
    Option<Variables> allVars;                    // all variables
    Option<list< Var>> controlVars;               // variables to save control vars of for algorithm  
    Option<list< .DAE.ComponentRef>> diffCrefs;   // all crefs to differentiate, needed for generic gradient
    Option<String> matrixName;                    // name to create tempory vars, needed for generic gradient
  end DIFFINPUTDATA;
end DifferentiateInputData;

public constant DifferentiateInputData noInputData = DIFFINPUTDATA(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE());

public
type DifferentiateInputArguments = tuple< .DAE.ComponentRef, DifferentiateInputData, DiffentiationType, .DAE.FunctionTree>;

public
uniontype DiffentiationType "Define the behavoir of differentation method for (e.g. index reduction, ...)"
  record DIFFERENTATION_TIME "Used for index reduction differentation w.r.t. time (e.g. create dummy derivative variables)"
  end DIFFERENTATION_TIME;

  record SIMPLE_DIFFERENTAION "Used to solve expression for a cref or by the older jacobian generation, differation w.r.t. a given cref"
  end SIMPLE_DIFFERENTAION;

  record DIFFERENTAION_FUNCTION "Used to differentiate a function call w.r.t. a given cref, which need to expand the input arguments 
                                  by differentiate arguments."
  end DIFFERENTAION_FUNCTION;
  
  record FULL_JACOBIAN "Used to generate a full jacobian matrix"
  end FULL_JACOBIAN;

  record GENERIC_GRADIENT "Used to generate a generic gradient for generation the jacobian matrix while the runtime."
  end GENERIC_GRADIENT;
end DiffentiationType;

end BackendDAE;
