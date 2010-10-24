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

package BackendDAE
" file:	       BackendDAE.mo
  package:     BackendDAE
  description: BackendDAE contains the datatypes used by the backend.

  RCS: $Id: DAELow.mo 6540 2010-10-22 21:07:52Z sjoelund.se $
"

public import Absyn;
public import DAE;
public import SCode;
public import Values;
public import Builtin;
public import HashTable2;

public constant String derivativeNamePrefix="$DER";
public constant String partialDerivativeNamePrefix="$pDER";

public uniontype Type "
Once we are in DAELow, the Type can be only basic types or enumeration.
We cannot do this in DAE because functions may contain many more types."
  record REAL end REAL;
  record INT end INT;
  record BOOL end BOOL;
  record STRING end STRING;

  record ENUMERATION
    list<String> stringLst;
  end ENUMERATION;

  record EXT_OBJECT
    Absyn.Path fullClassName;
  end EXT_OBJECT;
end Type;

public
uniontype VarKind "- Variabile kind"
  record VARIABLE end VARIABLE;
  record STATE end STATE;
  record STATE_DER end STATE_DER;
  record DUMMY_DER end DUMMY_DER;
  record DUMMY_STATE end DUMMY_STATE;
  record DISCRETE end DISCRETE;
  record PARAM end PARAM;
  record CONST end CONST;
  record EXTOBJ Absyn.Path fullClassName; end EXTOBJ;
end VarKind;

public
uniontype Var "- Variables"
  record VAR
    DAE.ComponentRef varName "varName ; variable name" ;
    VarKind varKind "varKind ; Kind of variable" ;
    DAE.VarDirection varDirection "varDirection ; input, output or bidirectional" ;
    Type varType "varType ; builtin type or enumeration" ;
    Option<DAE.Exp> bindExp "bindExp ; Binding expression e.g. for parameters" ;
    Option<Values.Value> bindValue "bindValue ; binding value for parameters" ;
    DAE.InstDims arryDim "arryDim ; array dimensions on nonexpanded var" ;
    Integer index "index ; index in impl. vector" ;
    DAE.ElementSource source "origin of variable" ;
    Option<DAE.VariableAttributes> values "values ; values on builtin attributes" ;
    Option<SCode.Comment> comment "comment ; this contains the comment and annotation from Absyn" ;
    DAE.Flow flowPrefix "flow ; if the variable is a flow" ;
    DAE.Stream streamPrefix "stream ; if the variable is a stream variable. Modelica 3.1 specs" ;
  end VAR;
end Var;

public
uniontype Equation "- Equation"
  record EQUATION
    DAE.Exp exp;
    DAE.Exp scalar "scalar" ;
    DAE.ElementSource source "origin of equation";
  end EQUATION;

  record ARRAY_EQUATION
    Integer index "index ; index in arrayequations 0..n-1" ;
    list<DAE.Exp> crefOrDerCref "crefOrDerCref ; CREF or der(CREF)" ;
    DAE.ElementSource source "origin of equation";
  end ARRAY_EQUATION;

  record SOLVED_EQUATION
    DAE.ComponentRef componentRef "componentRef" ;
    DAE.Exp exp "exp" ;
    DAE.ElementSource source "origin of equation";
  end SOLVED_EQUATION;

  record RESIDUAL_EQUATION
    DAE.Exp exp "exp ; not present from front end" ;
    DAE.ElementSource source "origin of equation";
  end RESIDUAL_EQUATION;

  record ALGORITHM
    Integer index      "Index in algorithms, 0..n-1" ;
    list<DAE.Exp> in_  "Inputs CREF or der(CREF)" ;
    list<DAE.Exp> out  "Outputs CREF or der(CREF)" ;
    DAE.ElementSource source "origin of algorithm";
  end ALGORITHM;

  record WHEN_EQUATION
    WhenEquation whenEquation "whenEquation" ;
    DAE.ElementSource source "origin of equation";
  end WHEN_EQUATION;

  record COMPLEX_EQUATION "complex equations: recordX = function call(x, y, ..);"
    Integer index "Index in algorithm clauses";
    DAE.Exp lhs "left ; lhs";
    DAE.Exp rhs "right ; rhs";
    DAE.ElementSource source "origin of equation";
  end COMPLEX_EQUATION;

end Equation;

public
uniontype WhenEquation "- When Equation"
  record WHEN_EQ
    Integer index         "Index in when clauses" ;
    DAE.ComponentRef left "Left hand side of equation" ;
    DAE.Exp right         "Right hand side of equation" ;
    Option<WhenEquation> elsewhenPart "elsewhen equation with the same cref on the left hand side.";
  end WHEN_EQ;

end WhenEquation;

public
uniontype ReinitStatement "- Reinit Statement"
  record REINIT
    DAE.ComponentRef stateVar "State variable to reinit" ;
    DAE.Exp value             "Value after reinit" ;
    DAE.ElementSource source "origin of equation";
  end REINIT;

  record EMPTY_REINIT
  end EMPTY_REINIT;
end ReinitStatement;

public
uniontype WhenClause "- When Clause"
  record WHEN_CLAUSE
    DAE.Exp condition                   "The when-condition" ;
    list<ReinitStatement> reinitStmtLst "List of reinit statements associated to the when clause." ;
    Option<Integer> elseClause          "index of elsewhen clause" ;

  // HL only needs to know if it is an elsewhen the equations take care of which clauses are related.

    // The equations associated to the clause are linked to this when clause by the index in the
    // when clause list where this when clause is stored.
  end WHEN_CLAUSE;

end WhenClause;

public
uniontype ZeroCrossing "- Zero Crossing"
  record ZERO_CROSSING
    DAE.Exp relation_          "function" ;
    list<Integer> occurEquLst  "List of equations where the function occurs" ;
    list<Integer> occurWhenLst "List of when clauses where the function occurs" ;
  end ZERO_CROSSING;

end ZeroCrossing;

public
uniontype EventInfo "- EventInfo"
  record EVENT_INFO
    list<WhenClause> whenClauseLst     "List of when clauses. The WhenEquation datatype refer to this list by position" ;
    list<ZeroCrossing> zeroCrossingLst "zeroCrossingLst" ;
  end EVENT_INFO;

end EventInfo;

public
uniontype DAELow "THE LOWERED DAE consist of variables and equations. The variables are split into
  two lists, one for unknown variables states and algebraic and one for known variables
  constants and parameters.
  The equations are also split into two lists, one with simple equations, a=b, a-b=0, etc., that
   are removed from  the set of equations to speed up calculations.

  - DAELow"
  record DAELOW
    Variables orderedVars "orderedVars ; ordered Variables, only states and alg. vars" ;
    Variables knownVars "knownVars ; Known variables, i.e. constants and parameters" ;
    Variables externalObjects "External object variables";
    AliasVariables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
    EquationArray removedEqs "removedEqs ; Removed equations a=b" ;
    EquationArray initialEqs "initialEqs ; Initial equations" ;
    array<MultiDimEquation> arrayEqs "arrayEqs ; Array equations" ;
    array<DAE.Algorithm> algorithms "algorithms ; Algorithms" ;
    EventInfo eventInfo "eventInfo" ;
    ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
  end DAELOW;

end DAELow;

type ExternalObjectClasses = list<ExternalObjectClass> "classes of external objects stored in list";

uniontype ExternalObjectClass "class of external objects"
  record EXTOBJCLASS
    Absyn.Path path "className of external object";
    DAE.Function constructor "constructor is an EXTFUNCTION";
    DAE.Function destructor "destructor is an EXTFUNCTION";
    DAE.ElementSource source "origin of equation";
  end EXTOBJCLASS;
end ExternalObjectClass;

public
uniontype Variables "- Variables"
  record VARIABLES
    array<list<CrefIndex>> crefIdxLstArr "crefIdxLstArr ; HashTB, cref->indx" ;
    array<list<StringIndex>> strIdxLstArr "strIdxLstArr ; HashTB, cref->indx for old names" ;
    VariableArray varArr "varArr ; Array of variables" ;
    Integer bucketSize "bucketSize ; bucket size" ;
    Integer numberOfVars "numberOfVars ; no. of vars" ;
  end VARIABLES;

end Variables;

public
uniontype AliasVariables "
Data originating from removed simple equations needed to build 
variables' lookup table (in C output).

In that way, double buffering of variables in pre()-buffer, extrapolation 
buffer and results caching, etc., is avoided, but in C-code output all the 
data about variables' names, comments, units, etc. is preserved as well as 
pinter to their values (trajectories).
"
  record ALIASVARS
    HashTable2.HashTable varMappings "replacements from trivial equations of kind a=b or a=-b";
    Variables aliasVars              "hash table with (removed) variables metadata";
  end ALIASVARS;
end AliasVariables;

public
uniontype MultiDimEquation "- Multi Dimensional Equation"
  record MULTIDIM_EQUATION
    list<Integer> dimSize "dimSize ; dimension sizes" ;
    DAE.Exp left "left ; lhs" ;
    DAE.Exp right "right ; rhs" ;
    DAE.ElementSource source "the element source";
  end MULTIDIM_EQUATION;
end MultiDimEquation;

public
uniontype CrefIndex "- Component Reference Index"
  record CREFINDEX
    DAE.ComponentRef cref "cref" ;
    Integer index "index" ;
  end CREFINDEX;

end CrefIndex;

public
uniontype StringIndex "- String Index"
  record STRINGINDEX
    String str "str" ;
    Integer index "index" ;
  end STRINGINDEX;

end StringIndex;

public
uniontype VariableArray "array of Equations are expandable, to amortize the cost of adding
   equations in a more efficient manner

  - Variable Array"
  record VARIABLE_ARRAY
    Integer numberOfElements "numberOfElements ; no. elements" ;
    Integer arrSize "arrSize ; array size" ;
    array<Option<Var>> varOptArr "varOptArr" ;
  end VARIABLE_ARRAY;

end VariableArray;

public
uniontype EquationArray "- Equation Array"
  record EQUATION_ARRAY
    Integer numberOfElement "numberOfElement ; no. elements" ;
    Integer arrSize "arrSize ; array size" ;
    array<Option<Equation>> equOptArr "equOptArr" ;
  end EQUATION_ARRAY;

end EquationArray;

public
uniontype Assignments "Assignments of variables to equations and vice versa are implemented by a
   expandable array to amortize addition of array elements more efficient
  - Assignments"
  record ASSIGNMENTS
    Integer actualSize "actualSize ; actual size" ;
    Integer allocatedSize "allocatedSize ; allocated size >= actual size" ;
    array<Integer> arrOfIndices "arrOfIndices ; array of indices" ;
  end ASSIGNMENTS;

end Assignments;

public
uniontype BinTree "Generic Binary tree implementation
  - Binary Tree"
  record TREENODE
    Option<TreeValue> value "value ; Value" ;
    Option<BinTree> leftSubTree "leftSubTree ; left subtree" ;
    Option<BinTree> rightSubTree "rightSubTree ; right subtree" ;
  end TREENODE;

end BinTree;

public
uniontype TreeValue "Each node in the binary tree can have a value associated with it.
  - Tree Value"
  record TREEVALUE
    Key key "Key" ;
    Value value "Value" ;
  end TREEVALUE;

end TreeValue;

public
type Key = DAE.ComponentRef "A key is a Component Reference
    - Key" ;

public
type Value = Integer "- Value" ;

public
type IncidenceMatrix = array<list<Integer>>;

public
type IncidenceMatrixT = IncidenceMatrix "IncidenceMatrixT : a list of equation indexes (1..n),
     one for each variable. Equations that -only-
     contain the state variable and not the derivative
     has a negative index.
- Incidence Matrix T" ;

public
uniontype JacobianType "- Jacobian Type"
  record JAC_CONSTANT "If jacobian has only constant values, for system
			         of equations this means that it can be solved statically." end JAC_CONSTANT;

  record JAC_TIME_VARYING "If jacobian has time varying parts, like parameters or
				          algebraic variables" end JAC_TIME_VARYING;

  record JAC_NONLINEAR "If jacobian contains variables that are solved for,
				      means that a nonlinear system of equations needs to be
				      solved" end JAC_NONLINEAR;

  record JAC_NO_ANALYTIC "No analytic jacobian available" end JAC_NO_ANALYTIC;

end JacobianType;

public
uniontype IndexReduction "- Index Reduction"
  record INDEX_REDUCTION "Use index reduction during matching" end INDEX_REDUCTION;

  record NO_INDEX_REDUCTION "do not use index reduction during matching" end NO_INDEX_REDUCTION;

end IndexReduction;

public
uniontype EquationConstraints "- Equation Constraints"
  record ALLOW_UNDERCONSTRAINED "for e.g. initial eqns.
						      where not all variables
						      have a solution" end ALLOW_UNDERCONSTRAINED;

  record EXACT "exact as many equations
						       as variables" end EXACT;

end EquationConstraints;

public
uniontype EquationReduction
  record REMOVE_SIMPLE_EQN end REMOVE_SIMPLE_EQN;

  record KEEP_SIMPLE_EQN "removes simple equation after index reduction does not remove simple equations after index reduction" end KEEP_SIMPLE_EQN;

end EquationReduction;

public
type MatchingOptions = tuple<IndexReduction, EquationConstraints, EquationReduction> "- Matching Options" ;

public
uniontype DivZeroExpReplace "- Should the division operator replaced by a operator with check of the denominator"
  record ALL  " check all expressions" end ALL;
  record ONLY_VARIABLES  " for expressions with variable variables(no parameters)" end ONLY_VARIABLES;
end DivZeroExpReplace;

public constant BinTree emptyBintree=TREENODE(NONE(),NONE(),NONE()) " Empty binary tree " ;

end BackendDAE;
