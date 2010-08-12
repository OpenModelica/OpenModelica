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

package DAELow
" file:	       DAELow.mo
  package:     DAELow
  description: DAELow a lower form of DAE including sparse matrises for
               BLT decomposition, etc.

  RCS: $Id$

  This module is a lowered form of a DAE including equations
  and simple equations in
  two separate lists. The variables are split into known variables
  parameters and constants, and unknown variables,
  states and algebraic variables.
  The module includes the BLT sorting algorithm which sorts the
  equations into blocks, and the index reduction algorithm using
  dummy derivatives for solving higher index problems.
  It also includes the tarjan algorithm to detect strong components
  in the BLT sorting."

public import Absyn;
public import DAE;
public import SCode;
public import Values;
public import VarTransform;

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
    VarTransform.VariableReplacements aliasVars "Hash table with alias variables and their replacements"; // added asodja 2010-03-03
    EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
    EquationArray removedEqs "removedEqs ; Removed equations a=b" ;
    EquationArray initialEqs "initialEqs ; Initial equations" ;
    MultiDimEquation[:] arrayEqs "arrayEqs ; Array equations" ;
    DAE.Algorithm[:] algorithms "algorithms ; Algorithms" ;
    EventInfo eventInfo "eventInfo" ;
    ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
  end DAELOW;

end DAELow;

type ExternalObjectClasses = list<ExternalObjectClass> "classes of external objects stored in list";

uniontype ExternalObjectClass "class of external objects"
  record EXTOBJCLASS
    Absyn.Path path "className of external object";
    DAE.Element constructor "constructor is an EXTFUNCTION";
    DAE.Element destructor "destructor is an EXTFUNCTION";
    DAE.ElementSource source "origin of equation";
  end EXTOBJCLASS;
end ExternalObjectClass;

public
uniontype Variables "- Variables"
  record VARIABLES
    list<CrefIndex>[:] crefIdxLstArr "crefIdxLstArr ; HashTB, cref->indx" ;
    list<StringIndex>[:] strIdxLstArr "strIdxLstArr ; HashTB, cref->indx for old names" ;
    VariableArray varArr "varArr ; Array of variables" ;
    Integer bucketSize "bucketSize ; bucket size" ;
    Integer numberOfVars "numberOfVars ; no. of vars" ;
  end VARIABLES;

end Variables;

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
    Option<Var>[:] varOptArr "varOptArr" ;
  end VARIABLE_ARRAY;

end VariableArray;

public
uniontype EquationArray "- Equation Array"
  record EQUATION_ARRAY
    Integer numberOfElement "numberOfElement ; no. elements" ;
    Integer arrSize "arrSize ; array size" ;
    Option<Equation>[:] equOptArr "equOptArr" ;
  end EQUATION_ARRAY;

end EquationArray;

public
uniontype Assignments "Assignments of variables to equations and vice versa are implemented by a
   expandable array to amortize addition of array elements more efficient
  - Assignments"
  record ASSIGNMENTS
    Integer actualSize "actualSize ; actual size" ;
    Integer allocatedSize "allocatedSize ; allocated size >= actual size" ;
    Integer[:] arrOfIndices "arrOfIndices ; array of indices" ;
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
type IncidenceMatrix = list<Integer>[:];

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

protected import Algorithm;
protected import BackendVarTransform;
protected import Ceval;
protected import ClassInf;
protected import DAEEXT;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Env;
protected import Error;
protected import Exp;
protected import OptManager;
protected import RTOpts;
protected import System;
protected import Util;
protected import DAEDump;
protected import IOStream;
protected import Inline;
protected import ValuesUtil;

protected constant BinTree emptyBintree=TREENODE(NONE,NONE,NONE) " Empty binary tree " ;

public function dumpDAELowEqnList
  input list<Equation> inDAELowEqnList;
  input String header;
  input Boolean printExpTree;
algorithm
   print(header);
   dumpDAELowEqnList2(inDAELowEqnList,printExpTree);
   print("===================\n");
end dumpDAELowEqnList;

protected function dumpDAELowEqnList2
  input list<Equation> inDAELowEqnList;
  input Boolean printExpTree;
algorithm
  _ := matchcontinue (inDAELowEqnList,printExpTree)
    local
      DAE.Exp e1_1,e2_1,e1,e2,e_1,e;
      String str;
      list<String> strList;
      list<Equation> res;
      list<DAE.Exp> expList,expList2;
      Integer i;
      DAE.ElementSource source "the element source";

     case ({},_) then ();
     case (EQUATION(e1,e2,source)::res,printExpTree) /* header */
      equation
        dumpDAELowEqnList2(res,printExpTree);
        print("EQUATION: ");
        str = Exp.printExpStr(e1);
        print(str);
        print("\n");
        str = Exp.dumpExpStr(e1,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
     case (COMPLEX_EQUATION(i,e1,e2,source)::res,printExpTree) /* header */
      equation
        dumpDAELowEqnList2(res,printExpTree);
        print("COMPLEX_EQUATION: ");
        str = Exp.printExpStr(e1);
        print(str);
        print("\n");
        str = Exp.dumpExpStr(e1,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (SOLVED_EQUATION(_,e,source)::res,printExpTree)
      equation
        dumpDAELowEqnList2(res,printExpTree);
        print("SOLVED_EQUATION: ");
        str = Exp.printExpStr(e);
        print(str);
        print("\n");
        str = Exp.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (RESIDUAL_EQUATION(e,source)::res,printExpTree)
      equation
        dumpDAELowEqnList2(res,printExpTree);
        print("RESIDUAL_EQUATION: ");
        str = Exp.printExpStr(e);
        print(str);
        print("\n");
        str = Exp.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
    case (ARRAY_EQUATION(_,expList,source)::res,printExpTree)
      equation
        dumpDAELowEqnList2(res,printExpTree);
        print("ARRAY_EQUATION: ");
        strList = Util.listMap(expList,Exp.printExpStr);
        str = Util.stringDelimitList(strList," | ");
        print(str);
        print("\n");
      then
        ();
     case (ALGORITHM(_,expList,expList2,source)::res,printExpTree)
      equation
        dumpDAELowEqnList2(res,printExpTree);
        print("ALGORITHM: ");
        strList = Util.listMap(expList,Exp.printExpStr);
        str = Util.stringDelimitList(strList," | ");
        print(str);
        print("\n");
        strList = Util.listMap(expList2,Exp.printExpStr);
        str = Util.stringDelimitList(strList," | ");
        print(str);
        print("\n");
      then
        ();
     case (WHEN_EQUATION(WHEN_EQ(_,_,e,_/*TODO handle elsewhe also*/),source)::res,printExpTree)
      equation
        dumpDAELowEqnList2(res,printExpTree);
        print("WHEN_EQUATION: ");
        str = Exp.printExpStr(e);
        print(str);
        print("\n");
        str = Exp.dumpExpStr(e,0);
        str = Util.if_(printExpTree,str,"");
        print(str);
        print("\n");
      then
        ();
     case (_::res,printExpTree)
      equation
      then ();
  end matchcontinue;
end dumpDAELowEqnList2;

protected function hasNoStates
"@author: adrpo
 this function tells if there are NO states in the binary tree"
  input BinTree states;
  output Boolean out;
algorithm
  out := matchcontinue (states)
    // if the tree is empty then there are no states
    case (TREENODE(NONE,NONE,NONE)) then true;
    case (_) then false;
  end matchcontinue;
end hasNoStates;

public function lower
"function: lower
  This function translates a DAE, which is the result from instantiating a
  class, into a more precise form, called DAELow defined in this module.
  The DAELow representation splits the DAE into equations and variables
  and further divides variables into known and unknown variables and the
  equations into simple and nonsimple equations.
  The variables are inserted into a hash table. This gives a lookup cost of
  O(1) for finding a variable. The equations are put in an expandable
  array. Where adding a new equation can be done in O(1) time if space
  is available.
  inputs:  daeList: DAE.DAElist, simplify: bool)
  outputs: DAELow"
  input DAE.DAElist lst;
  input Boolean addDummyDerivativeIfNeeded;
  input Boolean simplify;
//  input Boolean removeTrivEqs "temporal input, for legacy purposes; doesn't add trivial equations to removed equations";
  output DAELow outDAELow;
algorithm
  outDAELow := matchcontinue(lst, addDummyDerivativeIfNeeded, simplify)
    local
      BinTree s;
      Variables vars,knvars,vars_1,extVars;
      VarTransform.VariableReplacements aliasVars "hash table with alias vars' replacements (a=b or a=-b)";
      list<Equation> eqns,reqns,ieqns,algeqns,multidimeqns,imultidimeqns,eqns_1;
      list<MultiDimEquation> aeqns,aeqns1,iaeqns;
      list<DAE.Algorithm> algs;
      list<WhenClause> whenclauses,whenclauses_1;
      list<ZeroCrossing> zero_crossings;
      EquationArray eqnarr,reqnarr,ieqnarr;
      MultiDimEquation[:] arr_md_eqns;
      DAE.Algorithm[:] algarr;
      ExternalObjectClasses extObjCls;
      Boolean daeContainsNoStates, shouldAddDummyDerivative;
      EventInfo einfo;
      DAE.FunctionTree funcs;

    case(lst, addDummyDerivativeIfNeeded, true) // simplify by default
      equation
        lst = processDelayExpressions(lst);
        s = states(lst, emptyBintree);
        vars = emptyVars();
        knvars = emptyVars();
        extVars = emptyVars();
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses,extObjCls,s) = lower2(lst, s, vars, knvars, extVars, {});

        daeContainsNoStates = hasNoStates(s); // check if the DAE has states
        // adrpo: add the dummy derivative state ONLY IF the DAE contains
        //        no states AND ONLY if addDummyDerivative is set to true!
        shouldAddDummyDerivative =  boolAnd(addDummyDerivativeIfNeeded, daeContainsNoStates);
        (vars,eqns) = addDummyState(vars, eqns, shouldAddDummyDerivative);

        whenclauses_1 = listReverse(whenclauses);
        algeqns = lowerAlgorithms(vars, algs);
        (multidimeqns,imultidimeqns) = lowerMultidimeqns(vars, aeqns, iaeqns);
        eqns = listAppend(algeqns, eqns);
        eqns = listAppend(multidimeqns, eqns);
        ieqns = listAppend(imultidimeqns, ieqns);
        aeqns = listAppend(aeqns,iaeqns);
        (vars,knvars,eqns,reqns,ieqns,aeqns1,aliasVars) = removeSimpleEquations(vars, knvars, eqns, reqns, ieqns, aeqns, s);
        vars_1 = detectImplicitDiscrete(vars, eqns);
        eqns_1 = sortEqn(eqns);
        (eqns_1,ieqns,aeqns1,algs,vars_1) = expandDerOperator(vars_1,eqns_1,ieqns,aeqns1,algs,DAEUtil.daeFunctionTree(lst));
        (zero_crossings) = findZeroCrossings(vars_1,knvars,eqns_1,aeqns1,whenclauses_1,algs);
        eqnarr = listEquation(eqns_1);
        reqnarr = listEquation(reqns);
        ieqnarr = listEquation(ieqns);
        arr_md_eqns = listArray(aeqns1);
        algarr = listArray(algs);
        funcs = DAEUtil.daeFunctionTree(lst);
        einfo = Inline.inlineEventInfo(EVENT_INFO(whenclauses_1,zero_crossings),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls);

    case(lst, addDummyDerivativeIfNeeded, false) // do not simplify
      equation
        lst = processDelayExpressions(lst);
        s = states(lst, emptyBintree);
        vars = emptyVars();
        knvars = emptyVars();
        extVars = emptyVars();
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses,extObjCls,s) = lower2(lst, s, vars, knvars, extVars, {});

        daeContainsNoStates = hasNoStates(s); // check if the DAE has states
        // adrpo: add the dummy derivative state ONLY IF the DAE contains
        //        no states AND ONLY if addDummyDerivative is set to true!
        shouldAddDummyDerivative =  boolAnd(addDummyDerivativeIfNeeded, daeContainsNoStates);
        (vars,eqns) = addDummyState(vars, eqns, shouldAddDummyDerivative);

        whenclauses_1 = listReverse(whenclauses);
        algeqns = lowerAlgorithms(vars, algs);
       (multidimeqns,imultidimeqns) = lowerMultidimeqns(vars, aeqns, iaeqns);
        eqns = listAppend(algeqns, eqns);
        eqns = listAppend(multidimeqns, eqns);
        ieqns = listAppend(imultidimeqns, ieqns);
        // no simplify (vars,knvars,eqns,reqns,ieqns,aeqns1) = removeSimpleEquations(vars, knvars, eqns, reqns, ieqns, aeqns, s);
        aliasVars = VarTransform.emptyReplacements();
        vars_1 = detectImplicitDiscrete(vars, eqns);
        eqns_1 = sortEqn(eqns);
        // no simplify (eqns_1,ieqns,aeqns1,algs,vars_1) = expandDerOperator(vars_1,eqns_1,ieqns,aeqns1,algs);
        (zero_crossings) = findZeroCrossings(vars_1,knvars,eqns_1,aeqns,whenclauses_1,algs);
        eqnarr = listEquation(eqns_1);
        reqnarr = listEquation(reqns);
        ieqnarr = listEquation(ieqns);
        arr_md_eqns = listArray(aeqns);
        algarr = listArray(algs);
        funcs = DAEUtil.daeFunctionTree(lst);
        einfo = Inline.inlineEventInfo(EVENT_INFO(whenclauses_1,zero_crossings),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));        
      then DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls);
  end matchcontinue;
end lower;

protected function expandDerOperator
"function expandDerOperator
  expands der(expr) using Derive.differentiteExpTime.
  This can not be done in Static, since we need all time-
  dependent variables, which is only available in DAELow."
  input Variables vars;
  input list<Equation> eqns;
  input list<Equation> ieqns;
  input list<MultiDimEquation> aeqns;
  input list<DAE.Algorithm> algs;
  input DAE.FunctionTree functions;

  output list<Equation> outEqns;
  output list<Equation> outIeqns;
  output list<MultiDimEquation> outAeqns;
  output list<DAE.Algorithm> outAlgs;
  output Variables outVars;
algorithm
  (outEqns, outIeqns,outAeqns,outAlgs,outVars) :=
  matchcontinue(vars,eqns,ieqns,aeqns,algs,functions)
    case(vars,eqns,ieqns,aeqns,algs,functions) equation
      (eqns,(vars,_)) = expandDerOperatorEqns(eqns,(vars,functions));
      (ieqns,(vars,_)) = expandDerOperatorEqns(ieqns,(vars,functions));
      (aeqns,(vars,_)) = expandDerOperatorArrEqns(aeqns,(vars,functions));
      (algs,(vars,_)) = expandDerOperatorAlgs(algs,(vars,functions));
    then(eqns,ieqns,aeqns,algs,vars);
  end matchcontinue;
end expandDerOperator;

protected function expandDerOperatorEqns
"Help function to expandDerOperator"
  input list<Equation> eqns;
  input tuple<Variables,DAE.FunctionTree> vars;
  output list<Equation> outEqns;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqns,outVars) := matchcontinue(eqns,vars)
  local Equation e;
    case({},vars) then ({},vars);
    case(e::eqns,vars) equation
      (e,vars) = expandDerOperatorEqn(e,vars);
      (eqns,vars)  = expandDerOperatorEqns(eqns,vars);
    then (e::eqns,vars);
    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorEqns failed\n");
      then fail();
    end matchcontinue;
end expandDerOperatorEqns;

protected function expandDerOperatorEqn
"Help function to expandDerOperator, handles Equations"
  input Equation eqn;
  input tuple<Variables,DAE.FunctionTree> vars;
  output Equation outEqn;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqn,outVars) := matchcontinue(eqn,vars)
    local
      DAE.Exp e1,e2; list<DAE.Exp> expl; Integer i;
      DAE.ComponentRef cr; WhenEquation wheneq;
      DAE.ElementSource source "the element source";

    case(EQUATION(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (EQUATION(e1,e2,source),vars);
    case(COMPLEX_EQUATION(i,e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (COMPLEX_EQUATION(i,e1,e2,source),vars);
    case  (ARRAY_EQUATION(i,expl,source),vars)
    then (ARRAY_EQUATION(i,expl,source),vars);
    case (SOLVED_EQUATION(cr,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (SOLVED_EQUATION(cr,e1,source),vars);
    case(RESIDUAL_EQUATION(e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (RESIDUAL_EQUATION(e1,source),vars);
    case (eqn as ALGORITHM(index = _),vars) then (eqn,vars);
    case (WHEN_EQUATION(wheneq,source),vars) equation
      (wheneq,vars) = expandDerOperatorWhenEqn(wheneq,vars);
    then (WHEN_EQUATION(wheneq,source),vars);
    case (eqn ,vars) equation
			true = RTOpts.debugFlag("failtrace");
      Debug.fprint("failtrace", "- DAELow.expandDerOperatorEqn, eqn =");
      Debug.fprint("failtrace", equationStr(eqn));
      Debug.fprint("failtrace", " failed\n");
    then fail();
  end matchcontinue;
end expandDerOperatorEqn;

protected function expandDerOperatorWhenEqn
"Helper function to expandDerOperatorWhenEqn"
  input WhenEquation wheneq;
  input tuple<Variables,DAE.FunctionTree> vars;
  output WhenEquation outWheneq;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outWheneq, outVars) := matchcontinue(wheneq,vars)
    local DAE.ComponentRef cr; DAE.Exp e1; Integer indx; WhenEquation elsewheneq;
    case(WHEN_EQ(indx,cr,e1,SOME(elsewheneq)),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (elsewheneq,vars) = expandDerOperatorWhenEqn(elsewheneq,vars);
    then (WHEN_EQ(indx,cr,e1,SOME(elsewheneq)),vars);

    case(WHEN_EQ(indx,cr,e1,NONE),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (WHEN_EQ(indx,cr,e1,NONE),vars);
  end matchcontinue;
end expandDerOperatorWhenEqn;

protected function expandDerOperatorAlgs
"Help function to expandDerOperator"
  input list<DAE.Algorithm> algs;
  input tuple<Variables,DAE.FunctionTree> vars;
  output list<DAE.Algorithm> outAlgs;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outAlgs,outVars) := matchcontinue(algs,vars)
  local DAE.Algorithm a;
    case({},vars) then ({},vars);
    case(a::algs,vars) equation
      (a,vars) = expandDerOperatorAlg(a,vars);
      (algs,vars)  = expandDerOperatorAlgs(algs,vars);
    then (a::algs,vars);

    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorAlgs failed\n");
      then fail();

  end matchcontinue;
end expandDerOperatorAlgs;

protected function expandDerOperatorAlg
"Help function to to expandDerOperator, handles Algorithms"
  input DAE.Algorithm alg;
  input tuple<Variables,DAE.FunctionTree> vars;
  output DAE.Algorithm outAlg;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outAlg,outVars) := matchcontinue(alg,vars)
  local list<Algorithm.Statement> stmts;
    case(DAE.ALGORITHM_STMTS(stmts),vars) equation
      (stmts,vars)  = expandDerOperatorStmts(stmts,vars);
    then (DAE.ALGORITHM_STMTS(stmts),vars);
  end matchcontinue;
end expandDerOperatorAlg;

protected function expandDerOperatorStmts
"Help function to expandDerOperatorAlg"
  input list<Algorithm.Statement> stmts;
  input tuple<Variables,DAE.FunctionTree> vars;
  output list<Algorithm.Statement> outStmts;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outStmts,outVars) := matchcontinue(stmts,vars)
  local Algorithm.Statement s;
    case({},vars) then ({},vars);
    case(s::stmts,vars) equation
      (s,vars) = expandDerOperatorStmt(s,vars);
      (stmts,vars)  = expandDerOperatorStmts(stmts,vars);
      then (s::stmts,vars);
  end matchcontinue;
end expandDerOperatorStmts;

protected function expandDerOperatorStmt
"Help function to expandDerOperatorAlg."
  input Algorithm.Statement stmt;
  input tuple<Variables,DAE.FunctionTree> vars;
  output Algorithm.Statement outStmt;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outStmt,outVars) := matchcontinue(stmt,vars)
    local DAE.ExpType tp; DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      Algorithm.Ident id; Boolean b;
      list<Algorithm.Statement> stmts;
      list<Integer> hv;
      Algorithm.Statement stmt;
      DAE.Exp e1,e2;
      Algorithm.Else elseB;
      DAE.ElementSource source;

    case(DAE.STMT_ASSIGN(tp,e2,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_ASSIGN(tp,e2,e1,source),vars);

    case(DAE.STMT_TUPLE_ASSIGN(tp,expl,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (expl,vars) = expandDerExps(expl,vars);
    then (DAE.STMT_TUPLE_ASSIGN(tp,expl,e1,source),vars);

    case(DAE.STMT_ASSIGN_ARR(tp,cr,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_ASSIGN_ARR(tp,cr,e1,source),vars);

    case(DAE.STMT_IF(e1,stmts,elseB,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (elseB,vars) = expandDerOperatorElseBranch(elseB,vars);
    then (DAE.STMT_IF(e1,stmts,elseB,source),vars);

    case(DAE.STMT_FOR(tp,b,id,e1,stmts,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_FOR(tp,b,id,e1,stmts,source),vars);

    case(DAE.STMT_WHILE(e1,stmts,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHILE(e1,stmts,source),vars);

    case(DAE.STMT_WHEN(e1,stmts,SOME(stmt),hv,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (stmt,vars) = expandDerOperatorStmt(stmt,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHEN(e1,stmts,SOME(stmt),hv,source),vars);

    case(DAE.STMT_WHEN(e1,stmts,NONE,hv,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHEN(e1,stmts,NONE,hv,source),vars);

    case(DAE.STMT_ASSERT(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_ASSERT(e1,e2,source),vars);

    case(DAE.STMT_TERMINATE(e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_TERMINATE(e1,source),vars);

    case(DAE.STMT_REINIT(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e1,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_REINIT(e1,e2,source),vars);

    case(stmt,vars)      then (stmt,vars);

  end matchcontinue;
end  expandDerOperatorStmt;

protected function expandDerOperatorElseBranch
"Help function to expandDerOperatorStmt, for else branches in if statements"
  input Algorithm.Else elseB;
  input tuple<Variables,DAE.FunctionTree> vars;
  output Algorithm.Else outElseB;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outElseB,outVars) := matchcontinue(elseB,vars)
    local DAE.Exp e1;
      list<Algorithm.Statement> stmts;
      Algorithm.Else elseB;

    case(DAE.NOELSE(),vars) then (DAE.NOELSE(),vars);

    case(DAE.ELSEIF(e1,stmts,elseB),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (elseB,vars) = expandDerOperatorElseBranch(elseB,vars);
    then (DAE.ELSEIF(e1,stmts,elseB),vars);
  end matchcontinue;
end expandDerOperatorElseBranch;

protected function expandDerOperatorArrEqns
"Help function to expandDerOperator"
  input list<MultiDimEquation> eqns;
  input tuple<Variables,DAE.FunctionTree> vars;
  output list<MultiDimEquation> outEqns;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqns,outVars) := matchcontinue(eqns,vars)
  local MultiDimEquation e;
    case({},vars) then ({},vars);
    case(e::eqns,vars) equation
      (e,vars) = expandDerOperatorArrEqn(e,vars);
      (eqns,vars)  = expandDerOperatorArrEqns(eqns,vars);
    then (e::eqns,vars);

    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorArrEqns failed\n");
    then fail();
  end matchcontinue;
end expandDerOperatorArrEqns;

protected function expandDerOperatorArrEqn
"Help function to to expandDerOperator, handles Array equations"
  input MultiDimEquation arrEqn;
  input tuple<Variables,DAE.FunctionTree> vars;
  output MultiDimEquation outArrEqn;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outArrEqn,outVars) := matchcontinue(arrEqn,vars)
    local
      list<Integer> dims; DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";

    case(MULTIDIM_EQUATION(dims,e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (MULTIDIM_EQUATION(dims,e1,e2,source),vars);
  end matchcontinue;
end expandDerOperatorArrEqn;

protected function expandDerExps
"Help function to e.g. expandDerOperatorEqn"
  input list<DAE.Exp> expl;
  input tuple<Variables,DAE.FunctionTree> vars;
  output list<DAE.Exp> outExpl;
  output tuple<Variables,DAE.FunctionTree> outVars;
algorithm
  (outExpl,outVars) := matchcontinue(expl,vars)
    local DAE.Exp e;
    case({},vars) then ({},vars);
    case(e::expl,vars) equation
      ((e,vars)) = expandDerExp((e,vars));
      (expl,vars) = expandDerExps(expl,vars);
    then (e::expl,vars);
  end matchcontinue;
end expandDerExps;

protected function expandDerExp
"Help function to e.g. expandDerOperatorEqn"
  input tuple<DAE.Exp,tuple<Variables,DAE.FunctionTree>> tpl;
  output tuple<DAE.Exp,tuple<Variables,DAE.FunctionTree>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local DAE.Exp inExp;
      Variables vars;
      DAE.FunctionTree funcs;
      DAE.Exp e1;
      list<DAE.ComponentRef> newStates;
    case((DAE.CALL(Absyn.IDENT(name = "der"),{e1},tuple_ = false,builtin = true),(vars,funcs))) equation
      e1 = Derive.differentiateExpTime(e1,(vars,funcs));
      e1 = Exp.simplify(e1);
      (newStates,_) = bintreeToList(statesExp(e1,emptyBintree));
      vars = updateStatesVars(vars,newStates);
    then ((e1,(vars,funcs)));
    case((e1,(vars,funcs))) then ((e1,(vars,funcs)));
  end matchcontinue;
end expandDerExp;

protected function updateStatesVars
"Help function to expandDerExp"
  input Variables vars;
  input list<DAE.ComponentRef> newStates;
  output Variables outVars;
algorithm
  outVars := matchcontinue(vars,newStates)
    local
      DAE.ComponentRef cr1;
      VarKind kind;
      DAE.VarDirection dir;
      Type vartype;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dims;
      Value ind;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ComponentRef cr;

    case(vars,{}) then vars;
    case(vars,cr::newStates)
      equation
        ((VAR(cr1,kind,dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars);
        vars = addVar(VAR(cr1,STATE(),dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix), vars);
        vars = updateStatesVars(vars,newStates);
      then vars;
    case(vars,cr::newStates)
      equation
        print("Internal error, variable ");print(Exp.printComponentRefStr(cr));print("not found in variables.\n");
        vars = updateStatesVars(vars,newStates);
      then vars;
  end matchcontinue;
end updateStatesVars;

protected function addDummyState
"function: addDummyState
  In order for the solver to work correctly at least one state variable
  must exist in the equation system. This function therefore adds a
  dummy state variable and an equation for that variable.
  inputs:  (vars: Variables, eqns: Equation list, bool)
  outputs: (Variables, Equation list)"
  input Variables inVariables;
  input list<Equation> inEquationLst;
  input Boolean inBoolean;
  output Variables outVariables;
  output list<Equation> outEquationLst;
algorithm
  (outVariables,outEquationLst):=
  matchcontinue (inVariables,inEquationLst,inBoolean)
    local
      Variables v,vars_1,vars;
      list<Equation> e,eqns;
    case (v,e,false) then (v,e);
    case (vars,eqns,true) /* TODO::The dummy variable must be fixed */
      equation
        vars_1 = addVar(VAR(DAE.CREF_IDENT("$dummy",DAE.ET_REAL(),{}), STATE(),DAE.BIDIR(),REAL(),NONE,NONE,{},-1,
                            DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,SOME(DAE.BCONST(true)),NONE,NONE,NONE,NONE,NONE)),
                            NONE,DAE.NON_CONNECTOR(),DAE.NON_STREAM()), vars);
      then
        /*
         * Add equation der(dummy) = sin(time*6628.318530717). This so the solver has something to solve
         * if the model does not contain states. To prevent the solver from taking larger and larger steps
         * (which would happen if der(dymmy) = 0) when using automatic, we have a osciallating derivative.
        (vars_1,(EQUATION(
          DAE.CALL(Absyn.IDENT("der"),
          {DAE.CREF(DAE.CREF_IDENT("$dummy",{}),DAE.ET_REAL())},false,true,DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{DAE.BINARY(
          	DAE.CREF(DAE.CREF_IDENT("time",{}),DAE.ET_REAL()),
          	DAE.MUL(DAE.ET_REAL()),
          	DAE.RCONST(628.318530717))},false,true,DAE.ET_REAL()))  :: eqns)); */
        /*
         *
         * adrpo: after a bit of talk with Francesco Casella & Peter Aronsson we will add der($dummy) = 0;
         */
        (vars_1,(EQUATION(DAE.CALL(Absyn.IDENT("der"),
                          {DAE.CREF(DAE.CREF_IDENT("$dummy",DAE.ET_REAL(),{}),DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()),
                          DAE.RCONST(0.0), DAE.emptyElementSource)  :: eqns));

  end matchcontinue;
end addDummyState;

public function zeroCrossingsEquations
"Returns a list of all equations (by their index) that contain a zero crossing
 Used e.g. to find out which discrete equations are not part of a zero crossing"
  input DAELow dae;
  output list<Integer> eqns;
algorithm
  eqns := matchcontinue(dae)
    case (DAELOW(eventInfo=EVENT_INFO(zeroCrossingLst = zcLst),orderedEqs=eqnArr)) local
      list<ZeroCrossing> zcLst;
      list<list<Integer>> zcEqns;
      list<Integer> wcEqns;
      EquationArray eqnArr;
      equation
        zcEqns = Util.listMap(zcLst,zeroCrossingEquations);
        wcEqns = whenEquationsIndices(eqnArr);
        eqns = Util.listListUnion(listAppend(zcEqns,{wcEqns}));
      then eqns;
  end matchcontinue;
end zeroCrossingsEquations;

protected function whenEquationsIndices "Returns all equation-indices that contain a when clause"
  input EquationArray eqns;
  output list<Integer> res;
algorithm
   res := matchcontinue(eqns)
     case(eqns) equation
       	res=whenEquationsIndices2(1,equationSize(eqns),eqns);
       then res;
   end matchcontinue;
end whenEquationsIndices;

protected function whenEquationsIndices2
"Help function"
  input Integer i;
  input Integer size;
  input EquationArray eqns;
  output list<Integer> eqnLst;
algorithm
  eqnLst := matchcontinue(i,size,eqns)
    case(i,size,eqns) equation
      true = (i > size );
    then {};
    case(i,size,eqns)
      equation
        WHEN_EQUATION(whenEquation = _) = equationNth(eqns,i-1);
        eqnLst = whenEquationsIndices2(i+1,size,eqns);
    then i::eqnLst;
    case(i,size,eqns)
      equation
        eqnLst=whenEquationsIndices2(i+1,size,eqns);
      then eqnLst;
  end matchcontinue;
end whenEquationsIndices2;

protected function zeroCrossingEquations
"Returns the list of equations (indices) from a ZeroCrossing"
  input ZeroCrossing zc;
  output list<Integer> lst;
algorithm
  lst := matchcontinue(zc)
    case(ZERO_CROSSING(_,lst,_)) then lst;
  end matchcontinue;
end zeroCrossingEquations;

protected function dumpZcStr
"function: dumpZcStr
  Dumps a zerocrossing into a string, for debugging purposes."
  input ZeroCrossing inZeroCrossing;
  output String outString;
algorithm
  outString:=
  matchcontinue (inZeroCrossing)
    local
      list<String> eq_s_list,wc_s_list;
      String eq_s,wc_s,str,str2;
      DAE.Exp e;
      list<Value> eq,wc;
    case ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)
      equation
        eq_s_list = Util.listMap(eq, int_string);
        eq_s = Util.stringDelimitList(eq_s_list, ",");
        wc_s_list = Util.listMap(wc, int_string);
        wc_s = Util.stringDelimitList(wc_s_list, ",");
        str = Exp.printExpStr(e);
        str2 = Util.stringAppendList({str," in equations [",eq_s,"] and when conditions [",wc_s,"]\n"});
      then
        str2;
  end matchcontinue;
end dumpZcStr;

protected function mergeZeroCrossings
"function: mergeZeroCrossings
  Takes a list of zero crossings and if more than one have identical
  function expressions they are merged into one zerocrossing.
  In the resulting list all zerocrossing have uniq function expressions."
  input list<ZeroCrossing> inZeroCrossingLst;
  output list<ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst:=
  matchcontinue (inZeroCrossingLst)
    local
      ZeroCrossing zc,same_1;
      list<ZeroCrossing> samezc,diff,diff_1,xs;
    case {} then {};
    case {zc} then {zc};
    case (zc :: xs)
      equation
        samezc = Util.listSelect1(xs, zc, sameZeroCrossing);
        diff = Util.listSelect1(xs, zc, differentZeroCrossing);
        diff_1 = mergeZeroCrossings(diff);
        same_1 = Util.listFold(samezc, mergeZeroCrossing, zc);
      then
        (same_1 :: diff_1);
  end matchcontinue;
end mergeZeroCrossings;

protected function mergeZeroCrossing "function: mergeZeroCrossing

  Merges two zero crossings into one by makeing the union of the lists of
  equaions and when clauses they appear in.
"
  input ZeroCrossing inZeroCrossing1;
  input ZeroCrossing inZeroCrossing2;
  output ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing:=
  matchcontinue (inZeroCrossing1,inZeroCrossing2)
    local
      list<Value> eq,zc,eq1,wc1,eq2,wc2;
      DAE.Exp e1,e2;
    case (ZERO_CROSSING(relation_ = e1,occurEquLst = eq1,occurWhenLst = wc1),ZERO_CROSSING(relation_ = e2,occurEquLst = eq2,occurWhenLst = wc2))
      equation
        eq = Util.listUnion(eq1, eq2);
        zc = Util.listUnion(wc1, wc2);
      then
        ZERO_CROSSING(e1,eq,zc);
  end matchcontinue;
end mergeZeroCrossing;

protected function sameZeroCrossing "function: sameZeroCrossing

  Returns true if both zero crossings have the same function expression
"
  input ZeroCrossing inZeroCrossing1;
  input ZeroCrossing inZeroCrossing2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inZeroCrossing1,inZeroCrossing2)
    local
      Boolean res;
      DAE.Exp e1,e2;
    case (ZERO_CROSSING(relation_ = e1),ZERO_CROSSING(relation_ = e2))
      equation
        res = Exp.expEqual(e1, e2);
      then
        res;
  end matchcontinue;
end sameZeroCrossing;

protected function differentZeroCrossing "function: differentZeroCrossing

  Return true if the realation expressions differ.
"
  input ZeroCrossing zc1;
  input ZeroCrossing zc2;
  output Boolean res_1;
  Boolean res,res_1;
algorithm
  res := sameZeroCrossing(zc1, zc2);
  res_1 := boolNot(res);
end differentZeroCrossing;

protected function findZeroCrossings "function: findZeroCrossings

  This function finds all zerocrossings in the list of equations and
  the list of when clauses. Used in lower2.
"
  input Variables vars;
  input Variables knvars;
  input list<Equation> eq;
  input list<MultiDimEquation> multiDimEqs;
  input list<WhenClause> wc;
  input list<DAE.Algorithm> algs;
  output list<ZeroCrossing> res_1;
  list<ZeroCrossing> res,res_1;
algorithm
  res := findZeroCrossings2(vars, knvars,eq,multiDimEqs,1, wc, 1, algs);
  res_1 := mergeZeroCrossings(res);
end findZeroCrossings;

protected function findZeroCrossings2 "function: findZeroCrossings2

  Helper function to find_zero_crossing.
"
  input Variables inVariables1;
  input Variables knvars;
  input list<Equation> inEquationLst2;
  input list<MultiDimEquation> inMultiDimEqs;
  input Integer inInteger3;
  input list<WhenClause> inWhenClauseLst4;
  input Integer inInteger5;
  input list<DAE.Algorithm> algs;

  output list<ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst:=
  matchcontinue (inVariables1,knvars,inEquationLst2,inMultiDimEqs,inInteger3,inWhenClauseLst4,inInteger5,algs)
    local
      Variables v;
      list<DAE.Exp> rellst1,rellst2,rel;
      list<ZeroCrossing> zc1,zc2,zc3,zc4,res,res1,res2;
      list<MultiDimEquation> mdeqs;
      Value eq_count_1,eq_count,wc_count_1,wc_count;
      Equation e;
      DAE.Exp e1,e2;
      list<Equation> xs,el;
      WhenClause wc;
      Integer ind;
      DAE.ElementSource source "the element source";

    case (v,knvars,{},_,_,{},_,_) then {};
    case (v,knvars,((e as EQUATION(exp = e1,scalar = e2)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        rellst2 = findZeroCrossings3(e2, v,knvars);
        zc2 = makeZeroCrossings(rellst2, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        zc4 = listAppend(zc1, zc2);
        res = listAppend(zc3, zc4);
      then
        res;
    case (v,knvars,((e as COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        rellst2 = findZeroCrossings3(e2, v,knvars);
        zc2 = makeZeroCrossings(rellst2, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        zc4 = listAppend(zc1, zc2);
        res = listAppend(zc3, zc4);
      then
        res;
    case (v,knvars,((e as ARRAY_EQUATION(index = ind)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        // Find the correct multidim equation from the index
        MULTIDIM_EQUATION(left=e1,right=e2,source=source) = listNth(mdeqs,ind);
        e = EQUATION(e1,e2,source);
        res = findZeroCrossings2(v,knvars,e::xs,mdeqs,eq_count,{},0,algs);
      then
        res;
    case (v,knvars,((e as SOLVED_EQUATION(exp = e1)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,knvars,((e as RESIDUAL_EQUATION(exp = e1)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1,v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,knvars,((e as ALGORITHM(index = ind)) :: xs),mdeqs,eq_count,{},_,algs)
      local
        list<Algorithm.Statement> stmts;
      equation
        eq_count_1 = eq_count + 1;
        zc1 = findZeroCrossings2(v,knvars,xs,mdeqs,eq_count_1,{},0,algs);
        DAE.ALGORITHM_STMTS(stmts) = listNth(algs,ind);
        rel = Algorithm.getAllExpsStmts(stmts);
        rellst1 = Util.listFlatten(Util.listMap2(rel,findZeroCrossings3,v,knvars));
        zc2 = makeZeroCrossings(rellst1, {eq_count}, {});
        res = listAppend(zc2, zc1);
      then
        res;
    case (v,knvars,(e :: xs),mdeqs,eq_count,{},_,algs)
      equation
        eq_count_1 = eq_count + 1;
        (res) = findZeroCrossings2(v,knvars, xs,mdeqs,eq_count_1, {}, 0,algs);
      then
        res;
    case (v,knvars,el,mdeqs,eq_count,((wc as WHEN_CLAUSE(condition = e)) :: xs),wc_count,algs)
      local
        DAE.Exp e;
        list<WhenClause> xs;
      equation
        wc_count_1 = wc_count + 1;
        (res1) = findZeroCrossings2(v, knvars,el,mdeqs,eq_count, xs, wc_count_1,algs);
        rel = findZeroCrossings3(e, v,knvars);
        res2 = makeZeroCrossings(rel, {}, {wc_count});
        res = listAppend(res1, res2);
      then
        res;
  end matchcontinue;
end findZeroCrossings2;

protected function collectZeroCrossings "function: collectZeroCrossings

  Collects zero crossings
"
  input tuple<DAE.Exp, tuple<list<DAE.Exp>, tuple<Variables,Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, tuple<list<DAE.Exp>, tuple<Variables,Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e,e1,e2,e_1;
      Variables vars,knvars;
      list<DAE.Exp> zeroCrossings,zeroCrossings_1,zeroCrossings_2,zeroCrossings_3,el;
      DAE.Operator op;
      DAE.ExpType tp;
      Boolean scalar;
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))),(zeroCrossings,(vars,knvars)))) then ((e,({},(vars,knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))),(zeroCrossings,(vars,knvars)))) then ((e,((e :: zeroCrossings),(vars,knvars))));

    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,(vars,knvars)))) /* function with discrete expressions generate no zerocrossing */
      equation
        true = isDiscreteExp(e1, vars,knvars);
        true = isDiscreteExp(e2, vars,knvars);
      then
        ((e,(zeroCrossings,(vars,knvars))));
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,(vars,knvars))))
      equation
      then ((e,((e :: zeroCrossings),(vars,knvars))));  /* All other functions generate zerocrossing. */
    case (((e as DAE.ARRAY(array = {})),(zeroCrossings,(vars,knvars))))
      equation
      then ((e,(zeroCrossings,(vars,knvars))));
    case ((e1 as DAE.ARRAY(ty = tp,scalar = scalar,array = (e :: el)),(zeroCrossings,(vars,knvars))))
      equation
        ((_,(zeroCrossings_1,(vars,knvars)))) = Exp.traverseExp(e, collectZeroCrossings, (zeroCrossings,(vars,knvars)));
        ((e_1,(zeroCrossings_2,(vars,knvars)))) = collectZeroCrossings((DAE.ARRAY(tp,scalar,el),(zeroCrossings,(vars,knvars))));
        zeroCrossings_3 = listAppend(zeroCrossings_1, zeroCrossings_2);
      then
        ((e1,(zeroCrossings_3,(vars,knvars))));
    case ((e,(zeroCrossings,(vars,knvars))))
      equation
      then ((e,(zeroCrossings,(vars,knvars))));
  end matchcontinue;
end collectZeroCrossings;

public function isVarDiscrete " returns true if variable is discrete"
input Var var;
output Boolean res;
algorithm
  res := matchcontinue(var)
    case(VAR(varKind=kind)) local VarKind kind;
      then isKindDiscrete(kind);
  end matchcontinue;
end isVarDiscrete;


protected function isKindDiscrete "function: isKindDiscrete

  Returns true if VarKind is discrete.
"
  input VarKind inVarKind;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarKind)
    case (DISCRETE()) then true;
    case (PARAM()) then true;
    case (CONST()) then true;
    case (_) then false;
  end matchcontinue;
end isKindDiscrete;

protected function isDiscreteExp "function: isDiscreteExp
 Returns true if expression is a discrete expression."
  input DAE.Exp inExp;
  input Variables inVariables;
  input Variables knvars;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp,inVariables,knvars)
    local
      Variables vars;
      DAE.ComponentRef cr;
      VarKind kind;
      Boolean res,b1,b2,b3;
      DAE.Exp e1,e2,e,e3;
      DAE.Operator op;
      list<Boolean> blst;
      list<DAE.Exp> expl,expl_2;
      DAE.ExpType tp;
      list<tuple<DAE.Exp, Boolean>> expl_1;

    case (DAE.ICONST(integer = _),vars,knvars) then true;
    case (DAE.RCONST(real = _),vars,knvars) then true;
    case (DAE.SCONST(string = _),vars,knvars) then true;
    case (DAE.BCONST(bool = _),vars,knvars) then true;
    case (DAE.CREF(componentRef = cr),vars,knvars)
      equation
        ((VAR(varKind = kind) :: _),_) = getVar(cr, vars);
        res = isKindDiscrete(kind);
      then
        res;
        /* builtin variable time is not discrete */
    case (DAE.CREF(componentRef = DAE.CREF_IDENT("time",_,_)),vars,knvars)
      then false;

        /* Known variables that are input are continous */
    case (DAE.CREF(componentRef = cr),vars,knvars)
      local Var v;
      equation
        failure((_,_) = getVar(cr, vars));
        (v::_,_) = getVar(cr,knvars);
        true = isInput(v);
      then
        false;

        /* parameters & constants */
    case (DAE.CREF(componentRef = cr),vars,knvars)
      equation
        failure((_,_) = getVar(cr, vars));
        ((VAR(varKind = kind) :: _),_) = getVar(cr, knvars);
        res = isKindDiscrete(kind);
      then
        res;
        /* enumerations */
    case (DAE.CREF(DAE.CREF_IDENT(_, DAE.ET_ENUMERATION(_,_,_,_), _),_),vars,knvars) then true;

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.UNARY(operator = op,exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.LUNARY(operator = op,exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),vars,knvars) then true;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        b3 = isDiscreteExp(e3, vars,knvars);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (DAE.CALL(path = Absyn.IDENT(name = "pre")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "edge")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "change")),vars,knvars) then true;

    case (DAE.CALL(path = Absyn.IDENT(name = "ceil")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "floor")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "div")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "mod")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "rem")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "abs")),vars,knvars) then true;
    case (DAE.CALL(path = Absyn.IDENT(name = "sign")),vars,knvars) then true;

    case (DAE.CALL(path = Absyn.IDENT(name = "noEvent")),vars,knvars) then false;

    case (DAE.CALL(expLst = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.ARRAY(ty = tp,array = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.MATRIX(ty = tp,scalar = expl),vars,knvars)
      local list<list<tuple<DAE.Exp, Boolean>>> expl;
      equation
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        blst = Util.listMap2(expl_2, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        b3 = isDiscreteExp(e3, vars,knvars);
        res = Util.boolAndList({b1,b2,b3});
      then
        res;
    case (DAE.RANGE(ty = tp,exp = e1,expOption = NONE,range = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars,knvars)
      equation
        blst = Util.listMap2(expl, isDiscreteExp, vars,knvars);
        res = Util.boolAndList(blst);
      then
        res;
    case (DAE.CAST(ty = tp,exp = e1),vars,knvars)
      equation
        res = isDiscreteExp(e1, vars,knvars);
      then
        res;
    case (DAE.ASUB(exp = e),vars,knvars)
      equation
        res = isDiscreteExp(e, vars,knvars);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = SOME(e2)),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = NONE),vars,knvars)
      equation
        res = isDiscreteExp(e1, vars,knvars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars,knvars)
      equation
        b1 = isDiscreteExp(e1, vars,knvars);
        b2 = isDiscreteExp(e2, vars,knvars);
        res = boolAnd(b1, b2);
      then
        res;
    case (_,vars,knvars) then false;
  end matchcontinue;
end isDiscreteExp;

public function isDiscreteEquation
  input Equation eqn;
  input Variables vars;
  input Variables knvars;
  output Boolean b;
algorithm
  b := matchcontinue(eqn,vars,knvars)
  local DAE.Exp e1,e2; DAE.ComponentRef cr; list<DAE.Exp> expl;
    case(EQUATION(exp = e1,scalar = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(e1,vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    case(COMPLEX_EQUATION(lhs = e1,rhs = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(e1,vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    case(ARRAY_EQUATION(crefOrDerCref = expl),vars,knvars) equation
      b = Util.boolAndList(Util.listMap2(expl,isDiscreteExp,vars,knvars));
    then b;
    case(SOLVED_EQUATION(componentRef = cr,exp = e2),vars,knvars) equation
      b = boolAnd(isDiscreteExp(DAE.CREF(cr,DAE.ET_OTHER()),vars,knvars), isDiscreteExp(e2,vars,knvars));
    then b;
    case(RESIDUAL_EQUATION(exp = e1),vars,knvars) equation
      b = isDiscreteExp(e1,vars,knvars);
    then b;
    case(ALGORITHM(in_ = expl),vars,knvars) equation
      b = Util.boolAndList(Util.listMap2(expl,isDiscreteExp,vars,knvars));
    then b;
    case(WHEN_EQUATION(whenEquation = _),vars,knvars) then true;
  end matchcontinue;
end isDiscreteEquation;

protected function findZeroCrossings3
"function: findZeroCrossings3
  Helper function to findZeroCrossing."
  input DAE.Exp e;
  input Variables vars;
  input Variables knvars;
  output list<DAE.Exp> zeroCrossings;
algorithm
  ((_,(zeroCrossings,_))) := Exp.traverseExp(e, collectZeroCrossings, ({},(vars,knvars)));
end findZeroCrossings3;

protected function makeZeroCrossing
"function: makeZeroCrossing
  Constructs a ZeroCrossing from an expression and lists of equation indices
  and when clause indices."
  input DAE.Exp inExp1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := matchcontinue (inExp1,inIntegerLst2,inIntegerLst3)
    local
      DAE.Exp e;
      list<Value> eq_ind,wc_ind;
    case (e,eq_ind,wc_ind) then ZERO_CROSSING(e,eq_ind,wc_ind);
  end matchcontinue;
end makeZeroCrossing;

protected function makeZeroCrossings
"function: makeZeroCrossings
  Constructs a list of ZeroCrossings from a list expressions
  and lists of equation indices and when clause indices.
  Each Zerocrossing gets the same lists of indicies."
  input list<DAE.Exp> inExpExpLst1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output list<ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst := matchcontinue (inExpExpLst1,inIntegerLst2,inIntegerLst3)
    local
      ZeroCrossing res;
      list<ZeroCrossing> resx;
      DAE.Exp e;
      list<DAE.Exp> xs;
      list<Value> eq_ind,wc_ind;
    case ({},_,_) then {};
    case ((e :: xs),eq_ind,wc_ind)
      equation
        res = makeZeroCrossing(e, eq_ind, wc_ind);
        resx = makeZeroCrossings(xs, eq_ind, wc_ind);
      then
        (res :: resx);
  end matchcontinue;
end makeZeroCrossings;

protected function detectImplicitDiscrete
"function: detectImplicitDiscrete
  This function updates the variable kind to discrete
  for variables set in when equations."
  input Variables inVariables;
  input list<Equation> inEquationLst;
  output Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables,inEquationLst)
    local
      Variables v,v_1,v_2;
      DAE.ComponentRef cr,orig;
      DAE.VarDirection dir;
      Type vartype;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dims;
      Value ind;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Equation> xs;
    case (v,{}) then v;
    case (v,(WHEN_EQUATION(whenEquation = WHEN_EQ(left = cr)) :: xs))
      equation
        ((VAR(cr,_,dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, v);
        v_1 = addVar(VAR(cr,DISCRETE(),dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix), v);
        v_2 = detectImplicitDiscrete(v_1, xs);
      then
        v_2;
        /* TODO: should also check when-algorithms */
    case (v,(_ :: xs))
      equation
        v_1 = detectImplicitDiscrete(v, xs);
      then
        v_1;
  end matchcontinue;
end detectImplicitDiscrete;

protected function sortEqn
"function: sortEqn
  This function sorts the equation. It puts first the algebraic eqns
  and last the differentiated eqns"
  input list<Equation> inEquationLst;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationLst)
    local list<Equation> algEqns,diffEqns,res,eqns,resArrayEqns;
    case (eqns)
      equation
        (algEqns,diffEqns,resArrayEqns) = extractAlgebraicAndDifferentialEqn(eqns);
        res = Util.listFlatten({algEqns, diffEqns,resArrayEqns});
      then
        res;
    case (eqns)
      equation
        print("sort_eqn failed \n");
      then
        fail();
  end matchcontinue;
end sortEqn;

protected function extractAlgebraicAndDifferentialEqn
"function: extractAlgebraicAndDifferentialEqn

  Splits the equation list into two lists. One that only contain differential
  equations and one that only contain algebraic equations."
  input list<Equation> inEquationLst;
  output list<Equation> outEquationLst1;
  output list<Equation> outEquationLst2;
  output list<Equation> outEquationLst3;
algorithm
  (outEquationLst1,outEquationLst2):=
  matchcontinue (inEquationLst)
    local
      list<Equation> resAlgEqn,resDiffEqn,rest,resArrayEqns;
      Equation eqn,alg;
      DAE.Exp exp1,exp2;
      list<Boolean> bool_lst;
      Value indx;
      list<DAE.Exp> expl;
    case ({}) then ({},{},{});  /* algebraic equations differential equations */
    case (((eqn as EQUATION(exp = exp1,scalar = exp2)) :: rest)) /* scalar equation */
      equation
        true = isAlgebraic(exp1);
        true = isAlgebraic(exp2);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        ((eqn :: resAlgEqn),resDiffEqn,resArrayEqns);
    case (((eqn as COMPLEX_EQUATION(lhs = exp1,rhs = exp2)) :: rest)) /* complex equation */
      equation
        true = isAlgebraic(exp1);
        true = isAlgebraic(exp2);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        ((eqn :: resAlgEqn),resDiffEqn,resArrayEqns);
    case (((eqn as ARRAY_EQUATION(index = indx,crefOrDerCref = expl)) :: rest)) /* array equation */
      equation
        bool_lst = Util.listMap(expl, isAlgebraic);
        true = Util.boolAndList(bool_lst);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,resDiffEqn,(eqn :: resArrayEqns));
    case (((eqn as EQUATION(exp = exp1,scalar = exp2)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case (((eqn as COMPLEX_EQUATION(lhs = exp1,rhs = exp2)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case (((eqn as ARRAY_EQUATION(index = _)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case ((alg :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest) "Put algorithms in algebraic equations" ;
      then
        ((alg :: resAlgEqn),resDiffEqn,resArrayEqns);
  end matchcontinue;
end extractAlgebraicAndDifferentialEqn;

public function generateStatePartition "function:generateStatePartition

  This function traverses the equations to find out which blocks needs to
  be solved by the numerical solver (Dynamic Section) and which blocks only
  needs to be solved for output to file ( Accepted Section).
  This is done by traversing the graph of strong components, where
  equations/variable pairs correspond to nodes of the graph. The edges of
  this graph are the dependencies between blocks or components.
  The traversal is made in the backward direction of this graph.
  The result is a split of the blocks into two lists.
  inputs: (blocks: int list list,
             daeLow: DAELow,
             assignments1: int vector,
             assignments2: int vector,
             incidenceMatrix: IncidenceMatrix,
             incidenceMatrixT: IncidenceMatrixT)
  outputs: (dynamicBlocks: int list list, outputBlocks: int list list)
"
  input list<list<Integer>> inIntegerLstLst1;
  input DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input IncidenceMatrix inIncidenceMatrix5;
  input IncidenceMatrixT inIncidenceMatrixT6;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst1,inDAELow2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6)
    local
      Value size;
      Value[:] arr,arr_1;
      list<list<Value>> blt_states,blt_no_states,blt;
      DAELow dae;
      Variables v,kv;
      EquationArray e,se,ie;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      Value[:] ass1,ass2;
      list<Value>[:] m,mt;
    case (blt,(dae as DAELOW(orderedVars = v,knownVars = kv,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al)),ass1,ass2,m,mt)
      equation
        size = array_length(ass1) "equation_size(e) => size &" ;
        arr = fill(0, size);
        arr_1 = markStateEquations(dae, arr, m, mt, ass1, ass2);
        (blt_states,blt_no_states) = splitBlocks(blt, arr);
      then
        (blt_states,blt_no_states);
    case (_,_,_,_,_,_)
      equation
        print("-generate_state_partition failed\n");
      then
        fail();
  end matchcontinue;
end generateStatePartition;

protected function splitBlocks "function: splitBlocks

  Split the blocks into two parts, one dynamic and one output, depedning
  on if an equation in the block is marked or not.
  inputs:  (blocks: int list list, marks: int array)
  outputs: (dynamic: int list list, output: int list list)
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst,inIntegerArray)
    local
      list<list<Value>> states,output_,blocks;
      list<Value> block_;
      Value[:] arr;
    case ({},_) then ({},{});
    case ((block_ :: blocks),arr)
      equation
        true = blockIsDynamic(block_, arr) "block is dynamic, belong in dynamic section" ;
        (states,output_) = splitBlocks(blocks, arr);
      then
        ((block_ :: states),output_);
    case ((block_ :: blocks),arr)
      equation
        (states,output_) = splitBlocks(blocks, arr) "block is not dynamic, belong in output section" ;
      then
        (states,(block_ :: output_));
  end matchcontinue;
end splitBlocks;

protected function blockIsDynamic "function blockIsDynamic

  Return true if the block contains a variable that is marked
"
  input list<Integer> inIntegerLst;
  input Integer[:] inIntegerArray;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inIntegerLst,inIntegerArray)
    local
      Value x_1,x,mark_value;
      Boolean res;
      list<Value> xs;
      Value[:] arr;
    case ({},_) then false;
    case ((x :: xs),arr)
      equation
        x_1 = x - 1;
        0 = arr[x_1 + 1];
        res = blockIsDynamic(xs, arr);
      then
        res;
    case ((x :: xs),arr)
      equation
        x_1 = x - 1;
        mark_value = arr[x_1 + 1];
        (mark_value <> 0) = true;
      then
        true;
  end matchcontinue;
end blockIsDynamic;

protected function markStateEquations "function: markStateEquations

  This function goes through all equations and marks the ones that
  calculates a state, or is needed in order to calculate a state,
  with a non-zero value in the array passed as argument.
  This is done by traversing the directed graph of nodes where
  a node is an equation/solved variable and following the edges in the
  backward direction.
  inputs: (daeLow: DAELow,
             marks: int array,
	  incidenceMatrix: IncidenceMatrix,
	  incidenceMatrixT: IncidenceMatrixT,
	  assignments1: int vector,
	  assignments2: int vector)
  outputs: marks: int array
"
  input DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input IncidenceMatrix inIncidenceMatrix3;
  input IncidenceMatrixT inIncidenceMatrixT4;
  input Integer[:] inIntegerArray5;
  input Integer[:] inIntegerArray6;
  output Integer[:] outIntegerArray;
algorithm
  outIntegerArray:=
  matchcontinue (inDAELow1,inIntegerArray2,inIncidenceMatrix3,inIncidenceMatrixT4,inIntegerArray5,inIntegerArray6)
    local
      list<Var> v_lst,statevar_lst;
      DAELow dae;
      Value[:] arr_1,arr;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
      Variables v,kn;
      EquationArray e,se,ie;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] alg;
    case ((dae as DAELOW(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = alg)),arr,m,mt,a1,a2)
      equation
        v_lst = varList(v);
        statevar_lst = Util.listSelect(v_lst, isStateVar);
        ((dae,arr_1,m,mt,a1,a2)) = Util.listFold(statevar_lst, markStateEquation, (dae,arr,m,mt,a1,a2));
      then
        arr_1;
    case (_,_,_,_,_,_)
      equation
        print("-mark_state_equations failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquations;

protected function markStateEquation
"function: markStateEquation
  This function is a helper function to mark_state_equations
  It performs marking for one equation and its transitive closure by
  following edges in backward direction.
  inputs and outputs are tuples so we can use Util.list_fold"
  input Var inVar;
  input tuple<DAELow, Integer[:], IncidenceMatrix, IncidenceMatrixT, Integer[:], Integer[:]> inTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<DAELow, Integer[:], IncidenceMatrix, IncidenceMatrixT, Integer[:], Integer[:]> outTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inVar,inTplDAELowIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      list<Value> v_indxs,v_indxs_1,eqns;
      Value[:] arr_1,arr;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
      DAE.ComponentRef cr;
      DAELow dae;
      Variables vars;
      String s,str;
      Value v_indx,v_indx_1;
    case (VAR(varName = cr),((dae as DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,v_indxs) = getVar(cr, vars);
        v_indxs_1 = Util.listMap1(v_indxs, int_sub, 1);
        eqns = Util.listMap1r(v_indxs_1, arrayNth, a1);
        ((arr_1,m,mt,a1,a2)) = markStateEquation2(eqns, (arr,m,mt,a1,a2));
      then
        ((dae,arr_1,m,mt,a1,a2));
    case (VAR(varName = cr),((dae as DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        failure((_,_) = getVar(cr, vars));
        print("mark_state_equation var ");
        s = Exp.printComponentRefStr(cr);
        print(s);
        print("not found\n");
      then
        fail();
    case (VAR(varName = cr),((dae as DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation
        (_,{v_indx}) = getVar(cr, vars);
        v_indx_1 = v_indx - 1;
        failure(eqn = a1[v_indx_1 + 1]);
        print("mark_state_equation index =");
        str = intString(v_indx);
        print(str);
        print(", failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquation;

protected function markStateEquation2
"function: markStateEquation2
  Helper function to mark_state_equation
  Does the job by looking at variable indexes and incidencematrices.
  inputs: (eqns: int list,
             marks: (int array  IncidenceMatrix  IncidenceMatrixT  int vector  int vector))
  outputs: ((marks: int array  IncidenceMatrix  IncidenceMatrixT
	      int vector  int vector))"
  input list<Integer> inIntegerLst;
  input tuple<Integer[:], IncidenceMatrix, IncidenceMatrixT, Integer[:], Integer[:]> inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<Integer[:], IncidenceMatrix, IncidenceMatrixT, Integer[:], Integer[:]> outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inIntegerLst,inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      Value[:] marks,marks_1,marks_2,marks_3;
      list<Value>[:] m,mt,m_1,mt_1;
      Value[:] a1,a2,a1_1,a2_1;
      Value eqn_1,eqn,mark_value,len;
      list<Value> inv_reachable,inv_reachable_1,eqns;
      list<list<Value>> inv_reachable_2;
      String eqnstr,lens,ms;
    case ({},(marks,m,mt,a1,a2)) then ((marks,m,mt,a1,a2));
    case ((eqn :: eqns),(marks,m,mt,a1,a2))
      equation
        eqn_1 = eqn - 1 "Mark an unmarked node/equation" ;
        0 = marks[eqn_1 + 1];
        marks_1 = arrayUpdate(marks, eqn_1 + 1, 1);
        inv_reachable = invReachableNodes(eqn, m, mt, a1, a2);
        inv_reachable_1 = removeNegative(inv_reachable);
        inv_reachable_2 = Util.listMap(inv_reachable_1, Util.listCreate);
        ((marks_2,m,mt,a1,a2)) = Util.listFold(inv_reachable_2, markStateEquation2, (marks_1,m,mt,a1,a2));
        ((marks_3,m_1,mt_1,a1_1,a2_1)) = markStateEquation2(eqns, (marks_2,m,mt,a1,a2));
      then
        ((marks_3,m_1,mt_1,a1_1,a2_1));
    case ((eqn :: eqns),(marks,m,mt,a1,a2))
      equation
        eqn_1 = eqn - 1 "Node allready marked." ;
        mark_value = marks[eqn_1 + 1];
        (mark_value <> 0) = true;
        ((marks_1,m_1,mt_1,a1_1,a2_1)) = markStateEquation2(eqns, (marks,m,mt,a1,a2));
      then
        ((marks_1,m_1,mt_1,a1_1,a2_1));
    case ((eqn :: _),(marks,m,mt,a1,a2))
      equation
        print("mark_state_equation2 failed, eqn:");
        eqnstr = intString(eqn);
        print(eqnstr);
        print("array length =");
        len = arrayLength(marks);
        lens = intString(len);
        print(lens);
        print("\n");
        eqn_1 = eqn - 1;
        mark_value = marks[eqn_1 + 1];
        ms = intString(mark_value);
        print("mark_value:");
        print(ms);
        print("\n");
      then
        fail();
  end matchcontinue;
end markStateEquation2;

protected function invReachableNodes "function: invReachableNodes

  Similar to reachable_nodes, but follows edges in backward direction
  I.e. what equations/variables needs to be solved to solve this one.
"
  input Integer inInteger1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5)
    local
      Value eqn_1,e,eqn;
      list<Value> var_lst,var_lst_1,lst;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
      String eqn_str;
    case (e,m,mt,a1,a2)
      equation
        eqn_1 = e - 1;
        var_lst = m[eqn_1 + 1];
        var_lst_1 = removeNegative(var_lst);
        lst = invReachableNodes2(var_lst_1, a1);
      then
        lst;
    case (eqn,_,_,_,_)
      equation
        print("-inv_reachable_nodes failed, eqn:");
        eqn_str = intString(eqn);
        print(eqn_str);
        print("\n");
      then
        fail();
  end matchcontinue;
end invReachableNodes;

protected function invReachableNodes2 "function: invReachableNodes2

  Helper function to inv_reachable_nodes
  inputs:  (variables: int list, assignments1: int vector)
  outputs: int list
"
  input list<Integer> inIntegerLst;
  input Integer[:] inIntegerArray;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIntegerLst,inIntegerArray)
    local
      list<Value> eqns,vs;
      Value v_1,eqn,v;
      Value[:] a1;
    case ({},_) then {};
    case ((v :: vs),a1)
      equation
        eqns = invReachableNodes2(vs, a1);
        v_1 = v - 1;
        eqn = a1[v_1 + 1] "Which equation is variable solved in?" ;
      then
        (eqn :: eqns);
    case (_,_)
      equation
        print("-inv_reachable_nodes2 failed\n");
      then
        fail();
  end matchcontinue;
end invReachableNodes2;

public function isStateVar
"function: isStateVar
  Returns true for state variables, false otherwise."
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flowPrefix;
    case (VAR(varKind = STATE())) then true;
    case (_) then false;
  end matchcontinue;
end isStateVar;

public function isDummyStateVar
"function isDummyStateVar
  Returns true for dummy state variables, false otherwise."
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (VAR(varKind = DUMMY_STATE())) then true;
    case (_) then false;
  end matchcontinue;
end isDummyStateVar;

public function isNonState
"function: isNonState
  this equation checks if the the varkind is state of variable
  used both in build_equation and generate_compute_state"
  input VarKind inVarKind;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarKind)
    case (VARIABLE()) then true;
    case (PARAM()) then true;
    case (DUMMY_DER()) then true;
    case (DUMMY_STATE()) then true;
    case (DISCRETE()) then true;
    case (STATE_DER()) then true;
    case (_) then false;
  end matchcontinue;
end isNonState;

public function isDiscrete
"function: isDiscrete
  This equation checks if the the varkind is discrete,
  used both in build_equation and generate_compute_state"
  input VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    case (DISCRETE()) then ();
  end matchcontinue;
end isDiscrete;

public function dump
"function: dump
  This function dumps the DAELow representaton to stdout."
  input DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inDAELow)
    local
      list<Var> vars,knvars,extvars;
      Value varlen,eqnlen;
      String varlen_str,eqnlen_str,s;
      list<Equation> eqnsl,reqnsl,ieqnsl;
      list<String> ss;
      list<MultiDimEquation> ae_lst;
      Variables vars1,vars2,vars3;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      EquationArray eqns,reqns,ieqns;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] algs;
      list<ZeroCrossing> zc;
      ExternalObjectClasses extObjCls;
    case (DAELOW(vars1,vars2,vars3,av,eqns,reqns,ieqns,ae,algs,EVENT_INFO(zeroCrossingLst = zc),extObjCls))
      equation
        print("Variables (");
        vars = varList(vars1);
        varlen = listLength(vars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=========\n");
        dumpVars(vars);
        print("\n");
        print("Known Variables (constants) (");
        knvars = varList(vars2);
        varlen = listLength(knvars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpVars(knvars);
        print("External Objects (");
        extvars = varList(vars3);
        varlen = listLength(extvars);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
				dumpVars(extvars);

        print("Classes of External Objects (");
        varlen = listLength(extObjCls);
        varlen_str = intString(varlen);
        print(varlen_str);
        print(")\n");
        print("=============================\n");
        dumpExtObjCls(extObjCls);
        print("\nEquations (");
        eqnsl = equationList(eqns);
        eqnlen = listLength(eqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(eqnsl);
        print("Simple Equations (");
        reqnsl = equationList(reqns);
        eqnlen = listLength(reqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(reqnsl);
        print("Initial Equations (");
        ieqnsl = equationList(ieqns);
        eqnlen = listLength(ieqnsl);
        eqnlen_str = intString(eqnlen);
        print(eqnlen_str);
        print(")\n");
        print("=========\n");
        dumpEqns(ieqnsl);
        print("Zero Crossings :\n");
        print("===============\n");
        ss = Util.listMap(zc, dumpZcStr);
        s = Util.stringDelimitList(ss, ",\n");
        print(s);
        print("\n");
        print("Array Equations :\n");
        print("===============\n");
        ae_lst = arrayList(ae);
        dumpArrayEqns(ae_lst,0);

        print("Algorithms:\n");
        print("===============\n");
				dumpAlgorithms(arrayList(algs));
      then
        ();
  end matchcontinue;
end dump;

protected function dumpAlgorithms "Help function to dump, prints algorithms to stdout"
  input list<DAE.Algorithm> algs;
algorithm
  _ := matchcontinue(algs)
    local 
      list<Algorithm.Statement> stmts;
      IOStream.IOStream myStream;
      
    case({}) then ();
    case(DAE.ALGORITHM_STMTS(stmts)::algs) 
      equation
        myStream = IOStream.create("", IOStream.LIST()); 
        myStream = DAEDump.dumpAlgorithmStream(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),DAE.emptyElementSource), myStream);
        IOStream.print(myStream, IOStream.stdOutput);
        dumpAlgorithms(algs);
    then ();
  end matchcontinue;
end dumpAlgorithms;


public function varList
"function: varList
  Takes Variables and returns a list of \'Var\', useful for e.g. dumping."
  input Variables inVariables;
  output list<Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariables)
    local
      list<Var> varlst;
      VariableArray vararr;
    case (VARIABLES(varArr = vararr))
      equation
        varlst = vararrayList(vararr);
      then
        varlst;
  end matchcontinue;
end varList;

public function listVar
"function: listVar
  author: PA
  Takes Var list and creates a Variables structure, see also var_list."
  input list<Var> inVarLst;
  output Variables outVariables;
algorithm
  outVariables:=
  matchcontinue (inVarLst)
    local
      Variables res,vars,vars_1;
      Var v;
      list<Var> vs;
    case ({})
      equation
        res = emptyVars();
      then
        res;
    case ((v :: vs))
      equation
        vars = listVar(vs);
        vars_1 = addVar(v, vars);
      then
        vars_1;
  end matchcontinue;
end listVar;

public function varCref
"function: varCref
  author: PA
  extracts the ComponentRef of a variable."
  input Var inVar;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
    case (VAR(varName = cr,flowPrefix = flowPrefix)) then cr;
  end matchcontinue;
end varCref;

public function varType "function: varType
  author: PA

  extracts the type of a variable.
"
  input Var inVar;
  output Type outType;
algorithm
  outType:=
  matchcontinue (inVar)
    local Type tp;
    case (VAR(varType = tp)) then tp;
  end matchcontinue;
end varType;

public function varKind "function: varKind
  author: PA

  extracts the kind of a variable.
"
  input Var inVar;
  output VarKind outVarKind;
algorithm
  outVarKind:=
  matchcontinue (inVar)
    local VarKind kind;
    case (VAR(varKind = kind)) then kind;
  end matchcontinue;
end varKind;

public function varIndex "function: varIndex
  author: PA

  extracts the index in the implementation vector of a Var
"
  input Var inVar;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVar)
    local Value i;
    case (VAR(index = i)) then i;
  end matchcontinue;
end varIndex;

public function varNominal "function: varNominal
  author: PA

  Extacts the nominal attribute of a variable. If the variable has no
  nominal value, the function fails.
"
  input Var inVar;
  output Real outReal;
algorithm
  outReal := matchcontinue (inVar)
    local
      Real nominal;
    case (VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,SOME(DAE.RCONST(nominal)),_,_,_,_)))) then nominal;
  end matchcontinue;
end varNominal;

public function setVarFixed
"function: setVarFixed
  author: PA
  Sets the fixed attribute of a variable."
  input Var inVar;
  input Boolean inBoolean;
  output Var outVar;
algorithm
  outVar := matchcontinue (inVar,inBoolean)
    local
      DAE.ComponentRef a;
      VarKind b;
      DAE.VarDirection c;
      Type d;
      Option<DAE.Exp> e,h;
      Option<Values.Value> f;
      list<DAE.Subscript> g;
      Value i;
      list<Absyn.Path> k;
      DAE.ElementSource source "the element source";
      Option<DAE.Exp> l,m,n;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> o;
      Option<DAE.Exp> p,q;
      Option<DAE.StateSelect> r;
      Option<SCode.Comment> s;
      DAE.Flow t;
      DAE.Stream streamPrefix;
      Boolean fixed;
      Option<DAE.StateSelect> stateSelectOption;
      Option<DAE.Exp> equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,_,q,r,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
    then VAR(a,b,c,d,e,f,g,i,source,
             SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,SOME(DAE.BCONST(fixed)),q,r,equationBound,isProtected,finalPrefix)),
             s,t,streamPrefix);

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_INT(l,o,n,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(l,o,n,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_BOOL(l,m,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(l,m,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = d,
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = SOME(DAE.VAR_ATTR_ENUMERATION(l,o,n,_,equationBound,isProtected,finalPrefix)),
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        VAR(a,b,c,d,e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(l,o,n,SOME(DAE.BCONST(fixed)),equationBound,isProtected,finalPrefix)),
            s,t,streamPrefix);

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = REAL(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE,
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        VAR(a,b,c,REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,SOME(DAE.BCONST(fixed)),NONE,NONE,NONE,NONE,NONE)),
            s,t,streamPrefix);

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = INT(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE,
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        VAR(a,b,c,REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_INT(NONE,(NONE,NONE),NONE,SOME(DAE.BCONST(fixed)),NONE,NONE,NONE)),
            s,t,streamPrefix);

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = BOOL(),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE,
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        VAR(a,b,c,REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_BOOL(NONE,NONE,SOME(DAE.BCONST(fixed)),NONE,NONE,NONE)),
            s,t,streamPrefix);

    case (VAR(varName = a,
              varKind = b,
              varDirection = c,
              varType = ENUMERATION(_),
              bindExp = e,
              bindValue = f,
              arryDim = g,
              index = i,
              source = source,
              values = NONE,
              comment = s,
              flowPrefix = t,
              streamPrefix = streamPrefix),fixed)
      then
        VAR(a,b,c,REAL(),e,f,g,i,source,
            SOME(DAE.VAR_ATTR_ENUMERATION(NONE,(NONE,NONE),NONE,SOME(DAE.BCONST(fixed)),NONE,NONE,NONE)),
            s,t,streamPrefix);
  end matchcontinue;
end setVarFixed;

public function varFixed
"function: varFixed
  author: PA
  Extacts the fixed attribute of a variable.
  The default fixed value is used if not found. Default is true for parameters
  (and constants) and false for variables."
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      Boolean fixed;
      Var v;
    case (v as VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,SOME(DAE.BCONST(fixed)),_,_,_,_,_)))) then fixed;
    case (VAR(values = SOME(DAE.VAR_ATTR_INT(_,_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (VAR(values = SOME(DAE.VAR_ATTR_BOOL(_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (VAR(values = SOME(DAE.VAR_ATTR_ENUMERATION(_,_,_,SOME(DAE.BCONST(fixed)),_,_,_)))) then fixed;
    case (v) /* param is fixed */
      equation
        PARAM() = varKind(v);
      then
        true;
    case (v) /* states are by default fixed. */
      equation
        STATE() = varKind(v);
      then
        true;
    case (_) then false;  /* rest defaults to false*/
  end matchcontinue;
end varFixed;

public function varStartValue
"function varStartValue
  author: PA
  Returns the DAE.StartValue of a variable."
  input Var v;
  output DAE.Exp sv;
algorithm
  sv := matchcontinue(v)
    local
      Option<DAE.VariableAttributes> attr;
    case (VAR(values = attr))
      equation
        sv=DAEUtil.getStartAttr(attr);
      then sv;
   end matchcontinue;
end varStartValue;

public function varStateSelect
"function varStateSelect
  author: PA
  Extacts the state select attribute of a variable. If no stateselect explicilty set, return
  StateSelect.default"
  input Var inVar;
  output DAE.StateSelect outStateSelect;
algorithm
  outStateSelect:=
  matchcontinue (inVar)
    local
      DAE.StateSelect stateselect;
      Var v;
    case (VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(stateselect),_,_,_)))) then stateselect;
    case (_) then DAE.DEFAULT();
  end matchcontinue;
end varStateSelect;

public function vararrayList
"function: vararrayList
  Transforms a VariableArray to a Var list"
  input VariableArray inVariableArray;
  output list<Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariableArray)
    local
      Option<Var>[:] arr;
      Var elt;
      Value lastpos,n,size;
      list<Var> lst;
    case (VARIABLE_ARRAY(numberOfElements = 0,varOptArr = arr)) then {};
    case (VARIABLE_ARRAY(numberOfElements = 1,varOptArr = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr))
      equation
        lastpos = n - 1;
        lst = vararrayList2(arr, 0, lastpos);
      then
        lst;
  end matchcontinue;
end vararrayList;

protected function vararrayList2
"function: vararrayList2
  Helper function to vararrayList"
  input Option<Var>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      Var v;
      Option<Var>[:] arr;
      Value pos,lastpos,pos_1;
      list<Var> res;
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(v) = arr[pos + 1];
      then
        {v};
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(v) = arr[pos + 1];
        res = vararrayList2(arr, pos_1, lastpos);
      then
        (v :: res);
  end matchcontinue;
end vararrayList2;

public function dumpJacobianStr
"function: dumpJacobianStr
  Dumps the sparse jacobian.
  Uses the variables to determine size of Jacobian matrix."
  input Option<list<tuple<Integer, Integer, Equation>>> inTplIntegerIntegerEquationLstOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inTplIntegerIntegerEquationLstOption)
    local
      list<String> res;
      String res_1;
      list<tuple<Value, Value, Equation>> eqns;
    case (SOME(eqns))
      equation
        res = dumpJacobianStr2(eqns);
        res_1 = Util.stringDelimitList(res, ", ");
      then
        res_1;
    case (NONE) then "No analytic jacobian available\n";
  end matchcontinue;
end dumpJacobianStr;

protected function dumpJacobianStr2
"function: dumpJacobianStr2
  Helper function to dumpJacobianStr"
  input list<tuple<Integer, Integer, Equation>> inTplIntegerIntegerEquationLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inTplIntegerIntegerEquationLst)
    local
      String estr,rowstr,colstr,str;
      list<String> strs;
      Value row,col;
      DAE.Exp e;
      list<tuple<Value, Value, Equation>> eqns;
    case ({}) then {};
    case (((row,col,RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        estr = Exp.printExpStr(e);
        rowstr = intString(row);
        colstr = intString(col);
        str = Util.stringAppendList({"{",rowstr,",",colstr,"}:",estr});
        strs = dumpJacobianStr2(eqns);
      then
        (str :: strs);
  end matchcontinue;
end dumpJacobianStr2;

protected function dumpArrayEqns
"function: dumpArrayEqns
  helper function to dump"
  input list<MultiDimEquation> inMultiDimEquationLst;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inMultiDimEquationLst,inInteger)
    local
      String s1,s2,s,is;
      DAE.Exp e1,e2;
      list<MultiDimEquation> es;
    case ({},_) then ();
    case ((MULTIDIM_EQUATION(left = e1,right = e2) :: es),inInteger)
      equation
        is = intString(inInteger);
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s = Util.stringAppendList({is," : ",s1," = ",s2,"\n"});
        print(s);
        dumpArrayEqns(es,inInteger + 1);
      then
        ();
  end matchcontinue;
end dumpArrayEqns;

public function dumpEqns
"function: dumpEqns
  Helper function to dump."
  input list<Equation> eqns;
algorithm
  dumpEqns2(eqns, 1);
end dumpEqns;

protected function dumpEqns2
"function: dumpEqns2
  Helper function to dump_eqns"
  input list<Equation> inEquationLst;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inEquationLst,inInteger)
    local
      String es,is;
      Value index_1,index;
      Equation eqn;
      list<Equation> eqns;
    case ({},_) then ();
    case ((eqn :: eqns),index)
      equation
        es = equationStr(eqn);
        is = intString(index);
        print(is);
        print(" : ");
        print(es);
        print("\n");
        index_1 = index + 1;
        dumpEqns2(eqns, index_1);
      then
        ();
  end matchcontinue;
end dumpEqns2;

protected function whenEquationStr
"function: whenEquationStr
  Helper function to equationStr"
  input WhenEquation inWhenEqn;
  output String outString;
algorithm
  outString := matchcontinue (inWhenEqn)
    local
      String s1,s2,res,indx_str,is,var_str,intsStr,outsStr;
      DAE.Exp e1,e2,e;
      Value indx,i;
      list<DAE.Exp> expl,inps,outs;
      DAE.ComponentRef cr;
      WhenEquation weqn;
    case (WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = SOME(weqn)))
      equation
        s1 = whenEquationStr(weqn);
        s2 = Exp.printExpStr(e2);
        is = intString(i);
        res = Util.stringAppendList({" ; ",s2," elsewhen clause no: ",is /*, "\n" */, s1});
      then
        res;
    case (WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = NONE()))
      equation
        s2 = Exp.printExpStr(e2);
        is = intString(i);
        res = Util.stringAppendList({" ; ",s2," elsewhen clause no: ",is /*, "\n" */});
      then
        res;
  end matchcontinue;
end whenEquationStr;

public function equationStr
"function: equationStr
  Helper function to e.g. dump."
  input Equation inEquation;
  output String outString;
algorithm
  outString := matchcontinue (inEquation)
    local
      String s1,s2,s3,res,indx_str,is,var_str,intsStr,outsStr;
      DAE.Exp e1,e2,e;
      Value indx,i;
      list<DAE.Exp> expl,inps,outs;
      DAE.ComponentRef cr;
      WhenEquation weqn;
    case (EQUATION(exp = e1,scalar = e2))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({s1," = ",s2});
      then
        res;
    case (COMPLEX_EQUATION(lhs = e1,rhs = e2))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({s1," = ",s2});
      then
        res;
    case (ARRAY_EQUATION(index = indx,crefOrDerCref = expl))
      equation
        indx_str = intString(indx);
        var_str=Util.stringDelimitList(Util.listMap(expl,Exp.printExpStr),", ");
        res = Util.stringAppendList({"Array eqn no: ",indx_str," for variables: ",var_str /*,"\n"*/});
      then
        res;
    case (SOLVED_EQUATION(componentRef = cr,exp = e2))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({s1," := ",s2});
      then
        res;
        
    case (WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = SOME(weqn))))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        is = intString(i);
        s3 = whenEquationStr(weqn);
        res = Util.stringAppendList({s1," := ",s2," when clause no: ",is /*, "\n" */, s3});
      then
        res;
    case (WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e2)))
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        is = intString(i);
        res = Util.stringAppendList({s1," := ",s2," when clause no: ",is /*, "\n" */});
      then
        res;
    case (RESIDUAL_EQUATION(exp = e))
      equation
        s1 = Exp.printExpStr(e);
        res = Util.stringAppendList({s1,"= 0"});
      then
        res;
    case (ALGORITHM(index = i, in_ = inps, out = outs))
      equation
        is = intString(i);
        intsStr = Util.stringDelimitList(Util.listMap(inps, Exp.printExpStr), ", ");
        outsStr = Util.stringDelimitList(Util.listMap(outs, Exp.printExpStr), ", ");        
        res = Util.stringAppendList({"Algorithm no: ", is, " for inputs: (", 
                                      intsStr, ") => outputs: (", 
                                      outsStr, ")" /*,"\n"*/});
      then
        res;
  end matchcontinue;
end equationStr;

protected function removeSimpleEquations
"function: removeSimpleEquations
  This function moves simple equations on the form a=b from equations 2nd
  in DAELow to simple equations 3rd in DAELow to speed up assignment alg.
  inputs:  (vars: Variables,
              knownVars: Variables,
              eqns: Equation list,
              simpleEqns: Equation list,
	      initEqns : Equatoin list,
              binTree: BinTree)
  outputs: (Variables, Variables, Equation list, Equation list
 	      Equation list)"
  input Variables inVariables1;
  input Variables inVariables2;
  input list<Equation> inEquationLst3;
  input list<Equation> inEquationLst4;
  input list<Equation> inEquationLst5;
  input list<MultiDimEquation> inArrayEquationLst;
  input BinTree inBinTree6;
  output Variables outVariables1;
  output Variables outVariables2;
  output list<Equation> outEquationLst3;
  output list<Equation> outEquationLst4;
  output list<Equation> outEquationLst5;
  output list<MultiDimEquation> outArrayEquationLst;
  output VarTransform.VariableReplacements aliasVars; // hash tables of alias-variables' replacement (a = b or a = -b)
algorithm
  (outVariables1,outVariables2,outEquationLst3,outEquationLst4,outEquationLst5,outArrayEquationLst):=
  matchcontinue (inVariables1,inVariables2,inEquationLst3,inEquationLst4,inEquationLst5,inArrayEquationLst,inBinTree6)
    local
      VarTransform.VariableReplacements repl,replc,replc_1,vartransf,vartransf1, aliasVarsRepl;
      list<Equation> eqns_1,seqns,eqns_2,seqns_1,ieqns_1,eqns_3,seqns_2,ieqns_2,seqns_3,eqns,reqns,ieqns;
      list<MultiDimEquation> arreqns,arreqns1,arreqns2;
      BinTree movedvars_1,states;
      Variables vars_1,knvars_1,vars,knvars;
      list<DAE.Exp> crlst,elst;
    case (vars,knvars,eqns,reqns,ieqns,arreqns,states)
      equation
        repl = VarTransform.emptyReplacements();
        replc = VarTransform.emptyReplacements();
        aliasVarsRepl = VarTransform.emptyReplacements();
        (eqns_1,seqns,movedvars_1,vartransf,aliasVarsRepl,_,replc_1) = removeSimpleEquations2(eqns, vars, knvars, emptyBintree, states, repl, aliasVarsRepl,{},replc);
        vartransf1 = VarTransform.addMultiDimReplacements(vartransf);
        Debug.fcall("dumprepl", VarTransform.dumpReplacements, vartransf1);
        Debug.fcall("dumpreplc", VarTransform.dumpReplacements, replc_1);
        eqns_2 = BackendVarTransform.replaceEquations(eqns_1, replc_1);
        seqns_1 = BackendVarTransform.replaceEquations(seqns, replc_1);
        ieqns_1 = BackendVarTransform.replaceEquations(ieqns, replc_1);
        arreqns1 = BackendVarTransform.replaceMultiDimEquations(arreqns, replc_1);
        eqns_3 = BackendVarTransform.replaceEquations(eqns_2, vartransf1);
        seqns_2 = BackendVarTransform.replaceEquations(seqns_1, vartransf1);
        ieqns_2 = BackendVarTransform.replaceEquations(ieqns_1, vartransf1);
        arreqns2 = BackendVarTransform.replaceMultiDimEquations(arreqns1, vartransf1);
        (vars_1,knvars_1) = moveVariables(vars, knvars, movedvars_1);
        seqns_3 = listAppend(seqns_2, reqns) "& print_vars_statistics(vars\',knvars\')" ;
      then
        (vars_1,knvars_1,eqns_3,seqns_3,ieqns_2,arreqns2, aliasVarsRepl);
    case (_,_,_,_,_,_,_)
      equation
        print("-remove_simple_equations failed\n");
      then
        fail();
  end matchcontinue;
end removeSimpleEquations;

protected function removeSimpleEquations2
"Traverses all equations and puts those that are simple in
 a separate list. It builds a set of varable replacements that
 are later used to replace these variable substitutions in the
 equations that are left."
  input list<Equation> eqns;
  input Variables vars;
  input Variables knvars;
  input BinTree mvars;
  input BinTree states;
  input VarTransform.VariableReplacements repl;
  input VarTransform.VariableReplacements inAliasVarRepl "replacement of alias variables (a=b or a=-b)";
  input list<DAE.ComponentRef> inExtendLst;
  input VarTransform.VariableReplacements replc;
  output list<Equation> outEqns;
  output list<Equation> outSimpleEqns;
  output BinTree outMvars;
  output VarTransform.VariableReplacements outRepl;
  output VarTransform.VariableReplacements outAliasVarRepl "replacement of alias variables (a=b or a=-b)";
  output list<DAE.ComponentRef> outExtendLst;
  output VarTransform.VariableReplacements outReplc;
algorithm
  (outEqns,outSimpleEqns,outMvars,outRepl,outAliasVarRepl,outExtendLst,outReplc) := matchcontinue (eqns,vars,knvars,mvars,states,repl,aliasRepl,inExtendLst,replc)
    local
      Variables vars,knvars;
      BinTree mvars,states,mvars_1,mvars_2;
      VarTransform.VariableReplacements repl,repl_1,repl_2,replc_1,replc_2;
      VarTransform.VariableReplacements aliasRepl, aliasRepl_1, aliasRepl_2;
      DAE.ComponentRef cr1,cr2;
      list<Equation> eqns_1,seqns_1,eqns;
      Equation e;
      DAE.ExpType t;
      DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";
      list<DAE.ComponentRef> extlst,extlst1;
      
    case ({},vars,knvars,mvars,states,repl,aliasRepl,extlst,replc) then ({},{},mvars,repl,aliasRepl,extlst,replc);

    case (e::eqns,vars,knvars,mvars,states,repl,aliasRepl,inExtendLst,replc) equation
      {e} = BackendVarTransform.replaceEquations({e},repl);
      {e} = BackendVarTransform.replaceEquations({e},replc);
      (e1 as DAE.CREF(cr1,t),e2,source) = simpleEquation(e,false);
      failure(_ = treeGet(states, cr1)) "cr1 not state";
      isVariable(cr1, vars, knvars) "cr1 not constant";
      false = isTopLevelInputOrOutput(cr1,vars,knvars);
      (extlst,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,e2,t); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      aliasRepl_1 = VarTransform.addReplacementIfNot(Exp.isConst(e2), aliasRepl, cr1, e2);
      mvars_1 = treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2,aliasRepl_2,extlst1,replc_2) = removeSimpleEquations2(eqns, vars, knvars, mvars_1, states, repl_1, aliasRepl_1,extlst,replc_1);
    then
      (eqns_1,(SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars_2,repl_2,aliasRepl_2,extlst1,replc_2);

      // Swapped args
    case (e::eqns,vars,knvars,mvars,states,repl,aliasRepl,inExtendLst,replc) equation
      {e} = BackendVarTransform.replaceEquations({e},replc);
      {EQUATION(e1,e2,source)} = BackendVarTransform.replaceEquations({e},repl);
      (e1 as DAE.CREF(cr1,t),e2,source) = simpleEquation(EQUATION(e2,e1,source),true);
      failure(_ = treeGet(states, cr1)) "cr1 not state";
      isVariable(cr1, vars, knvars) "cr1 not constant";
      false = isTopLevelInputOrOutput(cr1,vars,knvars);
      (extlst,replc_1) = removeSimpleEquations3(inExtendLst,replc,cr1,e2,t); 
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      aliasRepl_1 = VarTransform.addReplacementIfNot(Exp.isConst(e2), aliasRepl, cr1, e2);
      mvars_1 = treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2, aliasRepl_2,extlst1,replc_2) = removeSimpleEquations2(eqns, vars, knvars, mvars_1, states, repl_1, aliasRepl_1,extlst,replc_1);
    then
      (eqns_1,(SOLVED_EQUATION(cr1,e2,source) :: seqns_1),mvars_2,repl_2,aliasRepl_2,extlst1,replc_2);

      // try next equation.
    case ((e :: eqns),vars,knvars,mvars,states,repl,aliasRepl,extlst,replc)
      local Equation eq1,eq2;
      equation
        {eq1} = BackendVarTransform.replaceEquations({e},repl);
        {eq2} = BackendVarTransform.replaceEquations({eq1},replc);
        //print("not removed simple ");print(equationStr(e));print("\n     -> ");print(equationStr(eq1));
        //print("\n\n");
        (eqns_1,seqns_1,mvars_1,repl_1,aliasRepl_1,extlst1,replc_1) = removeSimpleEquations2(eqns, vars, knvars, mvars, states, repl, aliasRepl,extlst,replc) "Not a simple variable, check rest" ;
      then
        ((e :: eqns_1),seqns_1,mvars_1,repl_1,aliasRepl_1,extlst1,replc_1);
  end matchcontinue;
end removeSimpleEquations2;

protected function removeSimpleEquations3"
Author: Frenkel TUD 2010-07 function removeSimpleEquations3
  helper for removeSimpleEquations2
  if a element of a cref from typ array has to be replaced
  the array have to extend"
  input list<DAE.ComponentRef> increflst;
  input VarTransform.VariableReplacements inrepl;
  input DAE.ComponentRef cr;
  input DAE.Exp e;
  input DAE.ExpType t;
  output list<DAE.ComponentRef> outcreflst;
  output VarTransform.VariableReplacements outrepl;
algorithm
  (outrepl,outcreflst) := matchcontinue (increflst,inrepl,cr,e,t)
    local
      list<DAE.ComponentRef> crlst;
      VarTransform.VariableReplacements repl,repl_1;
      DAE.Exp e1;
      DAE.ComponentRef sc;
      DAE.ExpType ty;
     case (crlst,repl,cr,e,t)
      equation
        // is Array
        (_::_) = Exp.crefLastSubs(cr);
        // check if e is not array
        false = Exp.isArray(e);
        // stripLastIdent
        sc = Exp.crefStripLastSubs(cr);
        ty = Exp.crefLastType(cr);
        // check List
        failure(_ = Util.listFindWithCompareFunc(crlst,sc,Exp.crefEqual,false));
        // extend cr
        (e1,_) = extendArrExp(DAE.CREF(sc,ty),NONE());
        // add
        repl_1 = VarTransform.addReplacement(repl, sc, e1);
      then
        (sc::crlst,repl_1);
    case (crlst,repl,_,_,_) then (crlst,repl);
  end matchcontinue;
end removeSimpleEquations3;

public function countSimpleEquations
"Counts the number of trivial/simple equations
 e.g on form a=b, a=-b or a=constant"
  input EquationArray eqns;
  output Integer numEqns;
protected Integer elimLevel;
algorithm
 elimLevel := RTOpts.eliminationLevel();
 RTOpts.setEliminationLevel(2) "Full elimination";
 numEqns := countSimpleEquations2(equationList(eqns),0);
 RTOpts.setEliminationLevel(elimLevel);
end countSimpleEquations;

protected function countSimpleEquations2
	input list<Equation> eqns;
	input Integer partialSum "to enable tail-recursion";
	output Integer numEqns;
algorithm
  numEqns := matchcontinue(eqns,partialSum)
  local Equation e;
    case({},partialSum) then partialSum;

    case (e::eqns,partialSum) equation
        (_,_,_) = simpleEquation(e,false);
        partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);

      // Swaped args in simpleEquation
    case (e::eqns,partialSum) equation
      (_,_,_) = simpleEquation(e,true);
      partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);

      //Not simple eqn.
    case (e::eqns,partialSum)
    then countSimpleEquations2(eqns,partialSum);
  end matchcontinue;
end countSimpleEquations2;

protected function simpleEquation
"Returns the two sides of an equation as expressions if it is a
 simple equation. Simple equations are
 a+b=0, a-b=0, a=constant, a=-b, etc.
 The first expression returned, e1, is always a CREF.
 If the equation is not simple, this function will fail."
  input Equation eqn;
  input Boolean swap "if true swap args.";
  output DAE.Exp e1;
  output DAE.Exp e2;
  output DAE.ElementSource source "the element source";
algorithm
  (e1,e2,source) := matchcontinue (eqn,swap)
      local
        DAE.Exp e;
        DAE.ExpType t;
        DAE.ElementSource src "the element source";
      // a = b;
      case (EQUATION(e1 as DAE.CREF(componentRef = _),e2 as  DAE.CREF(componentRef = _),src),swap)
        equation
					true = RTOpts.eliminationLevel() > 0;
					true = RTOpts.eliminationLevel() <> 3;
        then (e1,e2,src);
        // a-b = 0
    case (EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);
    case (EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);        
    	// a-b = 0 swap
    case (EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);
    case (EQUATION(DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);        
        // 0 = a-b
    case (EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);
    case (EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2,src);
        // 0 = a-b  swap
    case (EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);
    case (EQUATION(e,DAE.BINARY(e1 as  DAE.CREF(_,_),DAE.SUB_ARR(_),e2 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1,src);
        // a + b = 0
     case (EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
     case (EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
        // a + b = 0 swap
     case (EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Exp.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
     case (EQUATION(DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),e,src),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Exp.isZero(e);
     then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
      // 0 = a+b
    case (EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // 0 = a+b swap
    case (EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (EQUATION(e,DAE.BINARY(e1 as DAE.CREF(_,_),DAE.ADD_ARR(t),e2 as DAE.CREF(_,_)),src),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
     // a = -b
    case (EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (EQUATION(e1 as DAE.CREF(_,_),e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
      // -a = b => a = -b
    case (EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS(t),e2),src);
    case (EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e2 as DAE.CREF(_,_),src),swap)
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e2),src);
      // -b - a = 0 => a = -b
    case (EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
    case (EQUATION(DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
      // -b - a = 0 => a = -b swap
    case (EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (EQUATION(DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),e,src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
        // 0 = -b - a => a = -b
    case (EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
    case (EQUATION(e,DAE.BINARY(e2 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2,src);
        // 0 = -b - a => a = -b swap
    case (EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS(t),e2 as DAE.CREF(_,_)),DAE.SUB(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS(t),e1),src);
    case (EQUATION(e,DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(t),e2 as DAE.CREF(_,_)),DAE.SUB_ARR(_),e1 as DAE.CREF(_,_)),src),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,DAE.UNARY(DAE.UMINUS_ARR(t),e1),src);
        // -a = -b
    case (EQUATION(DAE.UNARY(DAE.UMINUS(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);
    case (EQUATION(DAE.UNARY(DAE.UMINUS_ARR(_),e1 as DAE.CREF(_,_)),DAE.UNARY(DAE.UMINUS_ARR(_),e2 as DAE.CREF(_,_)),src),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2,src);        
        // a = constant
    case (EQUATION(e1 as DAE.CREF(_,_),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,e,src);

        // -a = constant
    case (EQUATION(DAE.UNARY(DAE.UMINUS(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS(t),e),src);
    case (EQUATION(DAE.UNARY(DAE.UMINUS_ARR(t),e1 as DAE.CREF(_,_)),e,src),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,DAE.UNARY(DAE.UMINUS_ARR(t),e),src);
  end matchcontinue;
end simpleEquation;

protected function isTopLevelInputOrOutput
"function isTopLevelInputOrOutput
  author: LP

  This function checks if the provided cr is from a var that is on top model
  and is an input or an output, and returns true for such variables.
  It also returns true for input/output connector variables, i.e. variables
  instantiated from a  connector class, that are instantiated on the top level.
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1.
  Note: The function needs the known variables to search for input variables
  on the top level.
  inputs:  (cref: DAE.ComponentRef,
              vars: Variables, /* Variables */
              knownVars: Variables /* Known Variables */)
  outputs: bool"
  input DAE.ComponentRef inComponentRef1;
  input Variables inVariables2;
  input Variables inVariables3;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      Variables vars,knvars;
    case (cr,vars,_)
      equation
        ((VAR(varName = DAE.CREF_IDENT(ident = _), varDirection = DAE.OUTPUT()) :: _),_) = getVar(cr, vars);
      then
        true;
    case (cr,vars,knvars)
      equation
        ((VAR(varDirection = DAE.INPUT()) :: _),_) = getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
      then
        true;
    case (_,_,_) then false;
  end matchcontinue;
end isTopLevelInputOrOutput;

public function isVarOnTopLevelAndOutput
"function isVarOnTopLevelAndOutput
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = OUTPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (VAR(varName = cr,varDirection = dir,flowPrefix = flowPrefix))
      equation
        topLevelOutput(cr, dir, flowPrefix);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndOutput;

public function isVarOnTopLevelAndInput
"function isVarOnTopLevelAndInput
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = INPUT
  The check for top-model is done by spliting the name at \'.\' and
  check if the list-length is 1"
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (VAR(varName = cr,varDirection = dir,flowPrefix = flowPrefix))
      equation
        topLevelInput(cr, dir, flowPrefix);
      then
        true;
    case (_) then false;
  end matchcontinue;
end isVarOnTopLevelAndInput;

protected function typeofEquation
"function: typeofEquation
  Returns the DAE.ExpType of an equation"
  input Equation inEquation;
  output DAE.ExpType outType;
algorithm
  outType:=
  matchcontinue (inEquation)
    local
      DAE.ExpType t;
      DAE.Exp e;
    case (EQUATION(exp = e))
      equation
        t = Exp.typeof(e);
      then
        t;
    case (COMPLEX_EQUATION(lhs = e))
      equation
        t = Exp.typeof(e);
      then
        t;
    case (SOLVED_EQUATION(exp = e))
      equation
        t = Exp.typeof(e);
      then
        t;
    case (WHEN_EQUATION(whenEquation = WHEN_EQ(right = e)))
      equation
        t = Exp.typeof(e);
      then
        t;
  end matchcontinue;
end typeofEquation;

protected function moveVariables
"function: moveVariables
  This function takes the two variable lists of a dae (states+alg) and
  known vars and moves a set of variables from the first to the second set.
  This function is needed to manage this in complexity O(n) by only
  traversing the set once for all variables.
  inputs:  (algAndState: Variables, /* alg+state */
              known: Variables,       /* known */
              binTree: BinTree)       /* vars to move from first7 to second */
  outputs:  (Variables,	      /* updated alg+state vars */
               Variables)             /* updated known vars */
"
  input Variables inVariables1;
  input Variables inVariables2;
  input BinTree inBinTree3;
  output Variables outVariables1;
  output Variables outVariables2;
algorithm
  (outVariables1,outVariables2):=
  matchcontinue (inVariables1,inVariables2,inBinTree3)
    local
      list<Var> lst1,lst2,lst1_1,lst2_1;
      Variables v1,v2,vars,knvars,vars1,vars2;
      BinTree mvars;
    case (vars1,vars2,mvars)
      equation
        lst1 = varList(vars1);
        lst2 = varList(vars2);
        (lst1_1,lst2_1) = moveVariables2(lst1, lst2, mvars);
        v1 = emptyVars();
        v2 = emptyVars();
        vars = addVars(lst1_1, v1);
        knvars = addVars(lst2_1, v2);
      then
        (vars,knvars);
  end matchcontinue;
end moveVariables;

protected function moveVariables2
"function: moveVariables2
  helper function to move_variables.
  inputs:  (Var list,	/* alg+state vars as list */
              Var list,	/* known vars as list */
              BinTree)	/* move-variables as BinTree */
  outputs: (Var list,	/* updated alg+state vars as list */
              Var list)	/* update known vars as list */"
  input list<Var> inVarLst1;
  input list<Var> inVarLst2;
  input BinTree inBinTree3;
  output list<Var> outVarLst1;
  output list<Var> outVarLst2;
algorithm
  (outVarLst1,outVarLst2):=
  matchcontinue (inVarLst1,inVarLst2,inBinTree3)
    local
      list<Var> knvars,vs_1,knvars_1,vs;
      Var v;
      DAE.ComponentRef cr;
      BinTree mvars;
    case ({},knvars,_) then ({},knvars);
    case (((v as VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        _ = treeGet(mvars, cr) "alg var moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        (vs_1,(v :: knvars_1));
    case (((v as VAR(varName = cr)) :: vs),knvars,mvars)
      equation
        failure(_ = treeGet(mvars, cr)) "alg var not moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        ((v :: vs_1),knvars_1);
  end matchcontinue;
end moveVariables2;

protected function isVariable
"function: isVariable

  This function takes a DAE.ComponentRef and two Variables. It searches
  the two sets of variables and succeed if the variable is STATE or
  VARIABLE. Otherwise it fails.
  Note: An array variable is currently assumed that each scalar element has
  the same type.
  inputs:  (DAE.ComponentRef,
              Variables, /* vars */
              Variables) /* known vars */
  outputs: ()"
  input DAE.ComponentRef inComponentRef1;
  input Variables inVariables2;
  input Variables inVariables3;
algorithm
  _:=
  matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.ComponentRef cr;
      Variables vars,knvars;
    case (cr,vars,_)
      equation
        ((VAR(varKind = VARIABLE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((VAR(varKind = STATE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((VAR(varKind = DUMMY_STATE()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation
        ((VAR(varKind = DUMMY_DER()) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((VAR(varKind = VARIABLE()) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((VAR(varKind = DUMMY_STATE()) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation
        ((VAR(varKind = DUMMY_DER()) :: _),_) = getVar(cr, knvars);
      then
        ();
  end matchcontinue;
end isVariable;

protected function removeVariableNamed
"function: removeVariableNamed
  Removes a varaible from the Variables set given a ComponentRef name.
  The removed variable is returned, such that is can be used elsewhere."
  input Variables inVariables;
  input DAE.ComponentRef inComponentRef;
  output Variables outVariables;
  output Var outVar;
algorithm
  (outVariables,outVar):=
  matchcontinue (inVariables,inComponentRef)
    local
      String str;
      Variables vars,vars_1;
      DAE.ComponentRef cr;
      list<Var> vs;
      list<Key> crefs;
      Var var;
    case (vars,cr)
      equation
        failure((_,_) = getVar(cr, vars));
        print("-remove_variable_named failed. variable ");
        str = Exp.printComponentRefStr(cr);
        print(str);
        print(" not found.\n");
      then
        fail();
    case (vars,cr)
      equation
        (vs,_) = getVar(cr, vars);
        crefs = Util.listMap(vs, varCref);
        vars_1 = Util.listFold(crefs, deleteVar, vars);
        var = Util.listFirst(vs) "NOTE: returns first var even if array variable" ;
      then
        (vars_1,var);
    case (_,_)
      equation
        print("-remove_variable_named failed\n");
      then
        fail();
  end matchcontinue;
end removeVariableNamed;

protected function dumpExtObjCls "dump classes of external objects"
  input ExternalObjectClasses cls;
algorithm
  _ := matchcontinue(cls)
    local
      ExternalObjectClasses xs;
      DAE.Element constr,destr;
      Absyn.Path path;
      list<Absyn.Path> paths;
      list<String> paths_lst;
      DAE.ElementSource source "the element source";
      String path_str;

    case {} then ();

    case EXTOBJCLASS(path,constr,destr,source)::xs
      equation
        print("class ");
        print(Absyn.pathString(path));
        print("\n  extends ExternalObject");
        print(DAEDump.dumpFunctionStr(constr));
        print("\n");
        print(DAEDump.dumpFunctionStr(destr));
        print("\n origin: ");
        paths = DAEUtil.getElementSourceTypes(source);
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        print(path_str +& "\n");
        print("end ");print(Absyn.pathString(path));
      then ();
  end matchcontinue;
end dumpExtObjCls;

public function dumpVars
"function: dumpVars
  Helper function to dump."
  input list<Var> vars;
algorithm
  dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2
"function: dumpVars2
  Helper function to dumpVars."
  input list<Var> inVarLst;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str;
      list<String> paths_lst,path_strs;
      Value varno_1,indx,varno;
      Var v;
      DAE.ComponentRef cr;
      VarKind kind;
      DAE.VarDirection dir;
      DAE.Exp e;
      list<Absyn.Path> paths;
      DAE.ElementSource source "the origin of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Var> xs;
      Type var_type;
      DAE.InstDims arrayDim;

    case ({},_) then ();

    case (((v as VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = var_type,
                     arryDim = arrayDim,
                     bindExp = SOME(e),
                     index = indx,
                     source = source,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAEDump.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = Exp.printComponentRefStr(cr);
        print(str);
        print(":");
        dumpKind(kind);
        paths = DAEUtil.getElementSourceTypes(source);
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        comment_str = DAEDump.dumpCommentOptionStr(comment);
        print("= ");
        s = Exp.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx) "print \"  \" & print comment_str & print \" former: \" & print old_name &" ;
        str = dumpTypeStr(var_type);print( " type: "); print(str);
        print(Exp.printComponentRef2Str("", arrayDim));
        print(" indx = ");
        print(indx_str);
        varno_1 = varno + 1;
        print(" fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        dumpVars2(xs, varno_1) "DAEDump.dump_variable_attributes(dae_var_attr) &" ;
      then
        ();

    case (((v as VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = var_type,
                     arryDim = arrayDim,
                     bindExp = NONE,
                     index = indx,
                     source = source,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAEDump.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = Exp.printComponentRefStr(cr);
        paths = DAEUtil.getElementSourceTypes(source);
        path_strs = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(path_strs, ", ");
        comment_str = DAEDump.dumpCommentOptionStr(comment);
        print(str);
        print(":");
        dumpKind(kind);
        print(" ");
        print(path_str);
        indx_str = intString(indx) "print \" former: \" & print old_name &" ;
        str = dumpTypeStr(var_type);print( " type: "); print(str);
        print(Exp.printComponentRef2Str("", arrayDim));
        print(" indx = ");
        print(indx_str);
        print(" fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1);
      then
        ();

    case (v :: xs,varno)
      equation
        varnostr = intString(varno);
        print(varnostr);
        print(": UNKNOWN VAR!");
        print("\n");
        debug_print("variable",v);
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1);
      then ();

  end matchcontinue;
end dumpVars2;

public function dumpKind
"function: dumpKind
  Helper function to dump."
  input VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    local Absyn.Path path;
    case VARIABLE()    equation print("VARIABLE");    then ();
    case STATE()       equation print("STATE");       then ();
    case STATE_DER()   equation print("STATE_DER");   then ();
    case DUMMY_DER()   equation print("DUMMY_DER");   then ();
    case DUMMY_STATE() equation print("DUMMY_STATE"); then ();
    case DISCRETE()    equation print("DISCRETE");    then ();
    case PARAM()       equation print("PARAM");       then ();
    case CONST()       equation print("CONST");       then ();
    case EXTOBJ(path)  equation print("EXTOBJ: ");print(Absyn.pathString(path)); then ();
  end matchcontinue;
end dumpKind;

public function states
"function: states
  Returns a BinTree of all states in the DAE.
  This function is used by the lower function."
  input DAE.DAElist inDAElist;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inDAElist,inBinTree)
    local
      BinTree bt;
      DAE.Exp e1,e2;
      list<DAE.Element> xs;
      DAE.DAElist dae;
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;

    case (DAE.DAE(elementLst = {}),bt) then bt;

    case (DAE.DAE(DAE.EQUATION(exp = e1,scalar = e2) :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(xs,funcs), bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DAE(DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(xs,funcs), bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DAE(DAE.INITIALEQUATION(exp1 = e1, exp2 = e2) :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(xs,funcs), bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DAE(DAE.DEFINE(componentRef = _, exp = e2) :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(xs,funcs), bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DAE(DAE.INITIALDEFINE(componentRef = _, exp = e2) :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(xs,funcs), bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DAE(DAE.ARRAY_EQUATION(exp = e1,array = e2) :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(xs,funcs), bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

		case (DAE.DAE(DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2) :: xs, funcs), bt)
			equation
				bt = states(DAE.DAE(xs, funcs), bt);
				bt = statesExp(e1, bt);
				bt = statesExp(e2, bt);
			then
				bt;

    case (DAE.DAE(DAE.COMP(dAElist = daeElts) :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(daeElts,funcs), bt);
        bt = states(DAE.DAE(xs,funcs), bt);
      then
        bt;

    case (DAE.DAE(_ :: xs,funcs),bt)
      equation
        bt = states(DAE.DAE(xs,funcs), bt);
      then
        bt;
  end matchcontinue;
end states;

protected function statesDaelow
"function: statesDaelow
  author: PA
  Returns a BinTree of all states in the DAELow
  This function is used in matching algorithm."
  input DAELow inDAELow;
  output BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inDAELow)
    local
      list<Var> v_lst;
      BinTree bt;
      Variables v,kn;
      EquationArray e,re,ia;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      EventInfo ev;
    case (DAELOW(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = re,initialEqs = ia,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        v_lst = varList(v);
        bt = statesDaelow2(v_lst, emptyBintree);
      then
        bt;
  end matchcontinue;
end statesDaelow;

protected function statesDaelow2
"function: statesDaelow2
  author: PA
  Helper function to statesDaelow."
  input list<Var> inVarLst;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inVarLst,inBinTree)
    local
      BinTree bt;
      DAE.ComponentRef cr;
      Var v;
      list<Var> vs;

    case ({},bt) then bt;

    case ((v :: vs),bt)
      equation
        STATE() = varKind(v);
        cr = varCref(v);
        bt = treeAdd(bt, cr, 0);
        bt = statesDaelow2(vs, bt);
      then
        bt;
/*  is not realy a state
    case ((v :: vs),bt)
      equation
        DUMMY_STATE() = varKind(v);
        cr = varCref(v);
        bt = treeAdd(bt, cr, 0);
        bt = statesDaelow2(vs, bt);
      then
        bt;
*/
    case ((v :: vs),bt)
      equation
        bt = statesDaelow2(vs, bt);
      then
        bt;
  end matchcontinue;
end statesDaelow2;

protected function statesExp
"function: statesExp
  Helper function to states."
  input DAE.Exp inExp;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inExp,inBinTree)
    local
      BinTree bt;
      DAE.Exp e1,e2,e,e3;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Exp> expl;
      list<list<tuple<DAE.Exp, Boolean>>> m;

    case (DAE.BINARY(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.UNARY(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.LUNARY(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
        bt = statesExp(e3, bt);
      then
        bt;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),bt)
      equation
        //cr_1 = Exp.stringifyComponentRef(cr) "value irrelevant, give zero" ;
        bt = treeAdd(bt, cr, 0);
      then
        bt;
    case (DAE.CALL(expLst = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.ARRAY(array = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.MATRIX(scalar = m),bt)
      equation
        bt = statesExpMatrix(m, bt);
      then
        bt;
    case (DAE.TUPLE(PR = expl),bt)
      equation
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (DAE.CAST(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.ASUB(exp = e),bt)
      equation
        bt = statesExp(e, bt);
      then
        bt;
    case (DAE.REDUCTION(expr = e1,range = e2),bt)
      equation
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (_,bt) then bt;
  end matchcontinue;
end statesExp;

protected function statesExpMatrix
"function: statesExpMatrix
  author: PA
  Helper function to statesExp. Deals with matrix exp list."
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm
  outBinTree := matchcontinue (inTplExpExpBooleanLstLst,inBinTree)
    local
      list<list<DAE.Exp>> expl_1;
      list<DAE.Exp> expl_2;
      BinTree bt;
      list<list<tuple<DAE.Exp, Boolean>>> expl;

    case (expl,bt)
      equation
        expl_1 = Util.listListMap(expl, Util.tuple21);
        expl_2 = Util.listFlatten(expl_1);
        bt = Util.listFold(expl_2, statesExp, bt);
      then
        bt;
    case (_,_)
      equation
        Debug.fprint("failtrace", "-states_exp_matrix failed\n");
      then
        fail();
  end matchcontinue;
end statesExpMatrix;

protected function lowerWhenEqn
"function lowerWhenEqn
  This function lowers a when clause. The condition expresion is put in the
  WhenClause list and the equations inside are put in the equation list.
  For each equation in the clause a new entry in the WhenClause list is generated
  and one extra for all the reinit statements.
  inputs:  (DAE.Element, int /* when-clause index */, WhenClause list)
  outputs: (Equation list, Variables, int /* when-clause index */, WhenClause list)"
  input DAE.Element inElement;
  input Integer inWhenClauseIndex;
  input list<WhenClause> inWhenClauseLst;
  output list<Equation> outEquationLst;
  output Variables outVariables;
  output Integer outWhenClauseIndex;
  output list<WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst,outVariables,outwhenClauseIndex,outWhenClauseLst):=
  matchcontinue (inElement,inWhenClauseIndex,inWhenClauseLst)
    local
      Variables vars;
      Variables elseVars;
      list<Equation> res, res1;
      list<Equation> trueEqnLst, elseEqnLst;
      list<ReinitStatement> reinit;
      Integer equation_count,reinit_count,extra,tot_count,i_1,i,nextWhenIndex;
      Boolean hasReinit;
      list<WhenClause> whenClauseList1,whenClauseList2,whenClauseList3,whenClauseList4,whenList,elseClauseList;
      DAE.Exp cond;
      list<DAE.Element> eqnl;
      DAE.Element elsePart;

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = NONE),i,whenList)
      equation
        vars = emptyVars();
        (res,reinit) = lowerWhenEqn2(eqnl, i);
        equation_count = listLength(res);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        i_1 = i + tot_count;
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        whenClauseList4 = listAppend(whenClauseList3, whenList);
      then
        (res,vars,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = SOME(elsePart)),i,whenList)
      equation
        vars = emptyVars();
        (elseEqnLst,_,nextWhenIndex,elseClauseList) = lowerWhenEqn(elsePart,i,whenList);
        (trueEqnLst,reinit) = lowerWhenEqn2(eqnl, nextWhenIndex);
        equation_count = listLength(trueEqnLst);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        (res1,i_1,whenClauseList4) = mergeClauses(trueEqnLst,elseEqnLst,whenClauseList3,
          elseClauseList,nextWhenIndex + tot_count);
      then
        (res1,vars,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond),_,_)
      equation
        print("- DAELow.lowerWhenEqn: Error in lowerWhenEqn.\n");
      then fail();
  end matchcontinue;
end lowerWhenEqn;

protected function mergeClauses
"function mergeClauses
   merges the true part end the elsewhen part of a set of when equations.
   For each equation in trueEqnList, find an equation in elseEqnList solving
   the same variable and put it in the else elseWhenPart of the first equation."
  input list<Equation> trueEqnList "List of equations in the true part of the when clause.";
  input list<Equation> elseEqnList "List of equations in the elsewhen part of the when clause.";
  input list<WhenClause> trueClauses "List of when clauses from the true part.";
  input list<WhenClause> elseClauses "List of when clauses from the elsewhen part.";
  input Integer nextWhenClauseIndex  "Next available when clause index.";
  output list<Equation> outEquationLst;
  output Integer outWhenClauseIndex;
  output list<WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst,outWhenClauseIndex,outWhenClauseLst) :=
  matchcontinue (trueEqnList, elseEqnList, trueClauses, elseClauses, nextWhenClauseIndex)
    local
      DAE.ComponentRef cr;
      DAE.Exp rightSide;
      Integer ind;
      Equation res;
      list<Equation> trueEqns;
      list<Equation> elseEqns;
      list<WhenClause> trueCls;
      list<WhenClause> elseCls;
      Integer nextInd;
      list<Equation> resRest;
      Integer outNextIndex;
      list<WhenClause> outClauseList;
      WhenEquation foundEquation;
      list<Equation> elseEqnsRest;
      DAE.ElementSource source "the element source";

    case (WHEN_EQUATION(WHEN_EQ(index = ind,left = cr,right=rightSide),source)::trueEqns, elseEqns,trueCls,elseCls,nextInd)
      equation
        (foundEquation, elseEqnsRest) = getWhenEquationFromVariable(cr,elseEqns);
        res = WHEN_EQUATION(WHEN_EQ(ind,cr,rightSide,SOME(foundEquation)),source);
        (resRest, outNextIndex, outClauseList) = mergeClauses(trueEqns,elseEqnsRest,trueCls, elseCls,nextInd);
      then (res::resRest, outNextIndex, outClauseList);

    case ({},{},trueCls,elseCls,nextInd) then ({},nextInd,listAppend(trueCls,elseCls));

  end matchcontinue;
end mergeClauses;

protected function getWhenEquationFromVariable
"Finds the when equation solving the variable given by inCr among equations in inEquations
 the found equation is then taken out of the list."
  input DAE.ComponentRef inCr;
  input list<Equation> inEquations;
  output WhenEquation outEquation;
  output list<Equation> outEquations;
algorithm
  (outEquation, outEquations) := matchcontinue(inCr,inEquations)
    local
      DAE.ComponentRef cr1,cr2;
      WhenEquation eq;
      Equation eq2;
      list<Equation> rest, rest2;

    case (cr1,WHEN_EQUATION(eq as WHEN_EQ(left=cr2),_)::rest)
      equation
        true = Exp.crefEqual(cr1,cr2);
      then (eq, rest);

    case (cr1,(eq2 as WHEN_EQUATION(WHEN_EQ(left=cr2),_))::rest)
      equation
        false = Exp.crefEqual(cr1,cr2);
        (eq,rest2) = getWhenEquationFromVariable(cr1,rest);
      then (eq, eq2::rest2);

    case (_,{})
      equation
        Error.addMessage(Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, {});
      then
        fail();
  end matchcontinue;
end getWhenEquationFromVariable;

protected function makeWhenClauses
"function: makeWhenClauses
  Constructs a list of identical WhenClause elements
  Arg1: Number of elements to construct
  Arg2: condition expression of the when clause
  outputs: (WhenClause list)"
  input Integer n           "Number of copies to make.";
  input DAE.Exp inCondition "the condition expression";
  input list<ReinitStatement> inReinitStatementLst;
  output list<WhenClause> outWhenClauseLst;
algorithm
  outWhenClauseLst:=
  matchcontinue (n,inCondition,inReinitStatementLst)
    local
      Value i_1,i;
      list<WhenClause> res;
      DAE.Exp cond;
      list<ReinitStatement> reinit;

    case (0,_,_) then {};
    case (i,cond,reinit)
      equation
        i_1 = i - 1;
        res = makeWhenClauses(i_1, cond, reinit);
      then
        (WHEN_CLAUSE(cond,reinit,NONE) :: res);
  end matchcontinue;
end makeWhenClauses;

protected function lowerWhenEqn2
"function lowerWhenEqn2
  Helper function to lowerWhenEqn. Lowers the equations inside a when clause"
  input list<DAE.Element> inDAEElementLst "The List of equations inside a when clause";
  input Integer inWhenClauseIndex;
  output list<Equation> outEquationLst;
  output list<ReinitStatement> outReinitStatementLst;
algorithm
  (outEquationLst,outReinitStatementLst):=
  matchcontinue (inDAEElementLst,inWhenClauseIndex)
    local
      Value i;
      list<Equation> eqnl;
      list<ReinitStatement> reinit;
      DAE.Exp e_2,cre,e;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Element> xs;
      DAE.ElementSource source "the element source";

    case ({},_) then ({},{});
    case ((DAE.EQUATION(exp = (cre as DAE.CREF(componentRef = cr)),scalar = e, source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((WHEN_EQUATION(WHEN_EQ(i,cr,e,NONE),source) :: eqnl),reinit);

    case ((DAE.COMPLEX_EQUATION(lhs = (cre as DAE.CREF(componentRef = cr)),rhs = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((WHEN_EQUATION(WHEN_EQ(i,cr,e,NONE),source) :: eqnl),reinit);

    case ((DAE.REINIT(componentRef = cr,exp = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i);
      then
        (eqnl,(REINIT(cr,e,source) :: reinit));

    case ((DAE.TERMINATE(message = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i);
        e_2 = Exp.stringifyCrefs(Exp.simplify(e));
      then
        ((WHEN_EQUATION(WHEN_EQ(i,DAE.CREF_IDENT("_", DAE.ET_OTHER(), {}),e_2,NONE),source) :: eqnl),reinit);
  end matchcontinue;
end lowerWhenEqn2;
        
protected function isStateOrAlgvar
  "@author adrpo
   check if this variable is a state or algebraic"
  input DAE.Element e;
  output Boolean out;
algorithm
  out := matchcontinue(e)
    case (DAE.VAR(kind = DAE.VARIABLE())) then true;
    case (DAE.VAR(kind = DAE.DISCRETE())) then true;
    case (_) then false;
  end matchcontinue;
end isStateOrAlgvar;

protected function lower2
"function: lower2
  Helper function to lower.
  inputs:  (DAE.DAElist,BinTree /* states */,Variables,Variables,Variables,WhenClause list)
  outputs: (Variables,Variables,Variables,Equation list,Equation list,Equation list,MultiDimEquation list,DAE.Algorithm list,WhenClause list)"
  input DAE.DAElist inDAElist;
  input BinTree inStatesBinTree;
  input Variables inVariables;
  input Variables inKnownVariables;
  input Variables inExternalVariables;
  input list<WhenClause> inWhenClauseLst;
  output Variables outVariables;
  output Variables outKnownVariables;
  output Variables outExternalVariables;
  output list<Equation> outEquationLst3;
  output list<Equation> outEquationLst4;
  output list<Equation> outEquationLst5;
  output list<MultiDimEquation> outMultiDimEquationLst6;
  output list<MultiDimEquation> outMultiDimEquationLst7;
  output list<DAE.Algorithm> outAlgorithmAlgorithmLst8;
  output list<WhenClause> outWhenClauseLst9;
  output ExternalObjectClasses outExtObjClasses;
  output BinTree outStatesBinTree;
algorithm
  (outVariables,outKnownVariables,outExternalVariables,outEquationLst3,outEquationLst4,outEquationLst5,
   outMultiDimEquationLst6,outMultiDimEquationLst7,outAlgorithmAlgorithmLst8,outWhenClauseLst9,outExtObjClasses,outStatesBinTree):=
   matchcontinue (inDAElist,inStatesBinTree,inVariables,inKnownVariables,inExternalVariables,inWhenClauseLst)
    local
      Variables v1,v2,v3,vars,knvars,extVars,extVars1,extVars2,vars_1,knvars_1,vars1,vars2,knvars1,knvars2,kv;
      list<WhenClause> whenclauses,whenclauses_1,whenclauses_2;
      list<Equation> eqns,reqns,ieqns,eqns1,eqns2,reqns1,ieqns1,reqns2,ieqns2,re,ie,eqsComplex;
      list<MultiDimEquation> aeqns,aeqns1,aeqns2,ae,iaeqns,iaeqns1,iaeqns2,iae;
      list<DAE.Algorithm> algs,algs1,algs2,al;
      ExternalObjectClasses extObjCls,extObjCls1,extObjCls2;
      ExternalObjectClass extObjCl;
      Var v_1,v_2;
      DAE.Element v,e;
      list<DAE.Element> xs;
      BinTree states;
      Equation e_1, e_2;
      DAE.Exp e1,e2,c;
      list<Value> ds;
      Value count,count_1;
      DAE.Algorithm a,a1,a2;
      DAE.DAElist dae;
      DAE.ExpType ty;
      DAE.ComponentRef cr;
      Absyn.InnerOuter io;
      DAE.ElementSource source "the element source";
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;

    case (DAE.DAE(elementLst = {}),states,v1,v2,v3,whenclauses)
      then
        (v1,v2,v3,{},{},{},{},{},{},whenclauses,{},states);

    // adrpo: should we ignore OUTER vars?!
    //case (DAE.DAE(elementLst = ((v as DAE.VAR(innerOuter=io)) :: xs)),states,vars,knvars,extVars,whenclauses)
    //  equation
    //    DAEUtil.isOuterVar(v);
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) =
    //    lower2(DAE.DAE(xs), states, vars, knvars, extVars, whenclauses);
    //  then
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);

    // External object variables
    case (DAE.DAE((v as DAE.VAR(componentRef = _)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        v_1 = lowerExtObjVar(v);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        extVars2 = addVar(v_2, extVars);
      then
        (vars,knvars,extVars2,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    // class for External object
    case (DAE.DAE((v as DAE.EXTOBJECTCLASS(path,constr,destr,source)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local
        Absyn.Path path;
        DAE.Element constr,destr;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        {extObjCl} = Inline.inlineExtObjClasses({EXTOBJCLASS(path,constr,destr,source)},(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,
        extObjCl::extObjCls,states);

    // variables: states and algebraic variables with binding equation!
    case (DAE.DAE((v as DAE.VAR(componentRef = cr, source = source)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        // adrpo 2009-09-07 - according to MathCore
        // add the binding as an equation and remove the binding from variable!
        true = isStateOrAlgvar(v);
        (v_1,SOME(e1),states) = lowerVar(v, states);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        e2 = Inline.inlineExp(e1,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        vars_1 = addVar(v_2, vars);
      then
        (vars_1,knvars,extVars,EQUATION(DAE.CREF(cr, DAE.ET_OTHER()), e2, source)::eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    // variables: states and algebraic variables with NO binding equation!
    case (DAE.DAE((v as DAE.VAR(componentRef = cr, source = source)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        // adrpo 2009-09-07 - according to MathCore
        // add the binding as an equation and remove the binding from variable!
        true = isStateOrAlgvar(v);
        (v_1,NONE(),states) = lowerVar(v, states);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        vars_1 = addVar(v_2, vars);
      then
        (vars_1,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    // Known variables: parameters and constants
    case (DAE.DAE((v as DAE.VAR(componentRef = _)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        v_1 = lowerKnownVar(v) "in previous rule, lower_var failed." ;
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        knvars_1 = addVar(v_2, knvars);
      then
        (vars,knvars_1,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    /* tuple equations are rewritten to algorihm tuple assign. */
    case (DAE.DAE((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        a = lowerTupleEquation(e);
        a1 = Inline.inlineAlgorithm(a,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        a2 = extendAlgorithm(a1,SOME(funcs));
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        	= lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,a2::algs,whenclauses_1,extObjCls,states);

		/* tuple-tuple assignments are split into one equation for each tuple
		 * element, i.e. (i1, i2) = (4, 6) => i1 = 4; i2 = 6; */
		case (DAE.DAE(DAE.EQUATION(DAE.TUPLE(targets), DAE.TUPLE(sources), source = eq_source) :: xs, funcs),
				states,vars,knvars,extVars,whenclauses)
			local
				list<DAE.Exp> targets;
				list<DAE.Exp> sources;
				DAE.ElementSource eq_source;
			equation
				(vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
					= lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
				eqns2 = lowerTupleAssignment(targets, sources, eq_source, funcs);
				eqns = listAppend(eqns2, eqns);
			then
				(vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    /* scalar equations */
    case (DAE.DAE((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,(e_2 :: eqns),reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    /* effort variable equality equations */
    case (DAE.DAE((e as DAE.EQUEQUATION(cr1 = _)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,(e_2 :: eqns),reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    /* a solved equation */
    case (DAE.DAE((e as DAE.DEFINE(componentRef = _)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,e_2 :: eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    // complex equations!!
    case (DAE.DAE((e as DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        (eqsComplex,aeqns1) = lowerComplexEqn(e, funcs);
        eqns = listAppend(eqsComplex, eqns);
        aeqns2 = listAppend(aeqns, aeqns1);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns2,iaeqns,algs,whenclauses_1,extObjCls,states);

    // complex initial equations!!
    case (DAE.DAE((e as DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        (eqsComplex,iaeqns1) = lowerComplexEqn(e, funcs);
        ieqns = listAppend(eqsComplex, ieqns);
        iaeqns2 = listAppend(iaeqns, iaeqns1);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns2,algs,whenclauses_1,extObjCls,states);

    /* array equations */
    case (DAE.DAE((e as DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local 
        DAE.Exp e_11,e_21;
        list<DAE.Exp> ea1,ea2;
        list<tuple<DAE.Exp,DAE.Exp>> ealst;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        MULTIDIM_EQUATION(left=e_11 as DAE.ARRAY(scalar=true,array=ea1),
                          right=e_21 as DAE.ARRAY(scalar=true,array=ea2),source=source)
          = lowerArrEqn(e,funcs);
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,generateEQUATION,source);
        eqns = listAppend(re, eqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    case (DAE.DAE((e as DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local 
        MultiDimEquation e_1;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        e_1 = lowerArrEqn(e,funcs);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,(e_1 :: aeqns),iaeqns,algs,whenclauses_1,extObjCls,states);
        
		/* initial array equations */
    case (DAE.DAE((e as DAE.INITIAL_ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local 
        DAE.Exp e_11,e_21;
        list<DAE.Exp> ea1,ea2;
        list<tuple<DAE.Exp,DAE.Exp>> ealst;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        MULTIDIM_EQUATION(left=e_11 as DAE.ARRAY(scalar=true,array=ea1),
                          right=e_21 as DAE.ARRAY(scalar=true,array=ea2),source=source)
          = lowerArrEqn(e,funcs);
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,generateEQUATION,source);
        ieqns = listAppend(re, ieqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);		
		case (DAE.DAE((e as DAE.INITIAL_ARRAY_EQUATION(dimension = ds, exp = e1, array = e2)) :: xs, funcs), 
				states, vars, knvars, extVars, whenclauses)
			local 
				MultiDimEquation e_1;
			equation
				(vars, knvars, extVars, eqns, reqns, ieqns, aeqns,iaeqns, algs, whenclauses_1, extObjCls,states)
				= lower2(DAE.DAE(xs, funcs), states, vars, knvars, extVars, whenclauses);
				e_1 = lowerArrEqn(e,funcs);
			then
				(vars, knvars, extVars, eqns, reqns, ieqns, aeqns,(e_1 :: iaeqns), algs, whenclauses_1, extObjCls,states);

    /* When equations */
//    case (DAE.DAE((e as DAE.WHEN_EQUATION(condition = c,equations = eqns,elsewhen_ = NONE)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
    case (DAE.DAE((e as DAE.WHEN_EQUATION(condition = c,equations = eqns)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local list<Option<Equation>> opteqlst;
      equation
        (vars1,knvars,extVars,eqns1,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        count = listLength(whenclauses_1);
        (eqns2,vars2,count_1,whenclauses_2) = lowerWhenEqn(e, count, whenclauses_1);
        vars = mergeVars(vars1, vars2);
        opteqlst = Util.listMap(eqns2,Util.makeOption);
        opteqlst = Util.listMap1(opteqlst,Inline.inlineEqOpt,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        eqns2 = Util.listMap(opteqlst,Util.getOption);
        eqns = listAppend(eqns1, eqns2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_2,extObjCls,states);

    /* initial equations*/
    case (DAE.DAE((e as DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,eqns,reqns,(e_2 :: ieqns),aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    /* Algorithm */
    case (DAE.DAE(DAE.ALGORITHM(algorithm_ = a) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
       a1 = Inline.inlineAlgorithm(a,(NONE(),SOME(funcs),{DAE.NORM_INLINE()})); 
       a2 = extendAlgorithm(a1,SOME(funcs));
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,(a2 :: algs),whenclauses_1,extObjCls,states);

    /* flat class / COMP */
    case (DAE.DAE(DAE.COMP(dAElist = daeElts) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        (vars1,knvars1,extVars1,eqns1,reqns1,ieqns1,aeqns1,iaeqns1,algs1,whenclauses_1,extObjCls1,states) = lower2(DAE.DAE(daeElts,funcs), states, vars, knvars, extVars, whenclauses);
        (vars2,knvars2,extVars2,eqns2,reqns2,ieqns2,aeqns2,iaeqns2,algs2,whenclauses_2,extObjCls2,states) = lower2(DAE.DAE(xs,funcs), states, vars1, knvars1, extVars1, whenclauses_1);
        vars = vars2; // vars = mergeVars(vars1, vars2);
        knvars = knvars2; // knvars = mergeVars(knvars1, knvars2);
        extVars = extVars2; // extVars = mergeVars(extVars1,extVars2);
        eqns = listAppend(eqns1, eqns2);
        ieqns = listAppend(ieqns1, ieqns2);
        reqns = listAppend(reqns1, reqns2);
        aeqns = listAppend(aeqns1, aeqns2);
        iaeqns = listAppend(iaeqns1, iaeqns2);
        algs = listAppend(algs1, algs2);
        extObjCls = listAppend(extObjCls1,extObjCls2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_2,extObjCls,states);

    /* If equation */
    case (DAE.DAE(elementLst = ((e as DAE.IF_EQUATION(condition1 = _)) :: xs)),states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite equations using if-expressions: ",str);
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"if-equations",str});
      then
        fail();

    /* Initial if equation */
    case (DAE.DAE(elementLst = ((e as DAE.INITIAL_IF_EQUATION(condition1 = _)) :: xs)),states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite equations using if-expressions: ",str);
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"if-equations",str});
      then
        fail();

    /* assert in equation section is converted to ALGORITHM */
    case (DAE.DAE(DAE.ASSERT(cond,msg,source) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local
        Variables v;
        list<Equation> e;
        DAE.Exp cond,msg;

      equation
        checkAssertCondition(cond,msg);
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(DAE.DAE(xs,funcs), states,vars,knvars,extVars,whenclauses);
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,source)}),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (v,kv,extVars,e,re,ie,ae,iae,a::al,whenclauses_1,extObjCls,states);

    /* terminate in equation section is converted to ALGORITHM */
    case (DAE.DAE(DAE.TERMINATE(message = msg, source = source) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local
        Variables v;
        list<Equation> e;
        DAE.Exp cond,msg;
      equation
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(DAE.DAE(xs,funcs), states, vars,knvars,extVars, whenclauses) ;
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg,source)}),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (v,kv,extVars,e,re,ie,ae,iae,a::al,whenclauses_1,extObjCls,states);

    case (DAE.DAE(DAE.INITIALALGORITHM(algorithm_ = _) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local
        Variables v;
        list<Equation> e;
      equation
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"initial algorithm","rewrite initial algorithms to initial equations"});
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
      then
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states);
   
    // constrain is not a standard Modelica function, but used in old libraries such as the old Multibody library.
    // The OpenModelica backend does not support constrain, but the frontend does (Mathcore needs it for their backend).
    // To get a meaningful error message when constrain is used we catch it here, instead of silently failing. 
    // User-defined functions should have fully qualified names here, so Absyn.IDENT should only match the builtin constrain function.        
    case (DAE.DAE(DAE.NORETCALL(functionName = Absyn.IDENT(name = "constrain")) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      equation
        Error.addMessage(Error.NO_MATCHING_FUNCTION_FOUND_NO_CANDIDATE, {"constrain"});
      then
        fail();
        
    case (DAE.DAE(DAE.NORETCALL(functionName = func_name, functionArgs = args, source = source) :: xs,funcs),states,vars,knvars,extVars,whenclauses)
      local
        Absyn.Path func_name;
        list<DAE.Exp> args;
        DAE.Statement s;
      equation
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(DAE.DAE(xs,funcs), states, vars, knvars, extVars, whenclauses);
        s = DAE.STMT_NORETCALL(DAE.CALL(func_name, args, false, false, DAE.ET_NORETCALL(), DAE.NORM_INLINE()),source);
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({s}),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,a :: al,whenclauses_1,extObjCls,states);
        
    case (DAE.DAE(elementLst = (ddl :: xs)),_,vars,knvars,extVars,_)
      local DAE.Element ddl; String s3;
      equation
        // show only on failtrace!
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- DAELow.lower2 failed on: " +& DAEDump.dumpElementsStr({ddl}));
      then
        fail();
  end matchcontinue;
end lower2;

protected function checkAssertCondition "Succeds if condition of assert is not constant false"
  input DAE.Exp cond;
  input DAE.Exp message;
algorithm
  _ := matchcontinue(cond,message)
    case(_, _)
      equation
        // Don't check assertions when checking models
        true = OptManager.getOption("checkModel");
      then ();
    case(cond,message) equation
      false = Exp.isConstFalse(cond);
      then ();
    case(cond,message)
      local String messageStr;
      equation
        true = Exp.isConstFalse(cond);
        messageStr = Exp.printExpStr(message);
        Error.addMessage(Error.ASSERT_CONSTANT_FALSE_ERROR,{messageStr});
      then fail();
  end matchcontinue;
end checkAssertCondition;

protected function lowerTupleAssignment
	"Used by lower2 to split a tuple-tuple assignment into one equation for each
	tuple-element"
	input list<DAE.Exp> target_expl;
	input list<DAE.Exp> source_expl;
	input DAE.ElementSource eq_source;
	input DAE.FunctionTree funcs;
	output list<Equation> eqns;
algorithm
	eqns := matchcontinue(target_expl, source_expl, eq_source,funcs)
		local
			DAE.Exp target, source;
			list<DAE.Exp> rest_targets, rest_sources;
			DAE.Element e;
			Equation eq,eq1;
			list<Equation> new_eqns;
		case ({}, {}, _, funcs) then {};
		case (target :: rest_targets, source :: rest_sources, _, funcs)
			equation
				new_eqns = lowerTupleAssignment(rest_targets, rest_sources, eq_source, funcs);
				e = DAE.EQUATION(target, source, eq_source);
				eq = lowerEqn(e);
				SOME(eq1) = Inline.inlineEqOpt(SOME(eq),(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
			then eq :: new_eqns;
	end matchcontinue;
end lowerTupleAssignment;


protected function lowerTupleEquation
"Lowers a tuple equation, e.g. (a,b) = foo(x,y)
 by transforming it to an algorithm (TUPLE_ASSIGN), e.g. (a,b) := foo(x,y);
 author: PA"
	input DAE.Element eqn;
	output DAE.Algorithm alg;
algorithm
  alg := matchcontinue(eqn)
    local
      DAE.ElementSource source;
      DAE.Exp e1,e2;
      list<DAE.Exp> expl;
      /* Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c) */
    case(DAE.EQUATION(DAE.TUPLE(expl),e2 as DAE.CALL(path =_),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,e2,source)});

    case(DAE.EQUATION(e2 as DAE.CALL(path =_),DAE.TUPLE(expl),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,e2,source)});
  end matchcontinue;
end lowerTupleEquation;

protected function lowerMultidimeqns
"function: lowerMultidimeqns
  author: PA

  Lowers MultiDimEquations by creating ARRAY_EQUATION nodes that points
  to the array equation, stored in a MultiDimEquation array.
  each MultiDimEquation has as many ARRAY_EQUATION nodes as it has array
  elements. This to ensure correct sorting using BLT.
  inputs:  (Variables, /* vars */
              MultiDimEquation list)
  outputs: Equation list"
  input Variables vars;
  input list<MultiDimEquation> algs;
  input list<MultiDimEquation> ialgs;
  output list<Equation> eqns;
  output list<Equation> ieqns;
protected
  Integer indx;  
algorithm
  (eqns,indx) := lowerMultidimeqns2(vars, algs, 0);
  (ieqns,_) := lowerMultidimeqns2(vars, ialgs, indx);
end lowerMultidimeqns;

protected function lowerMultidimeqns2
"function: lowerMultidimeqns2
  Helper function to lower_multidimeqns. To handle indexes in Equation nodes
  for multidimensional equations to indentify the corresponding
  MultiDimEquation
  inputs:  (Variables, /* vars */
              MultiDimEquation list,
              int /* index */)
  outputs: (Equation list,
	    int) /* updated index */"
  input Variables inVariables;
  input list<MultiDimEquation> inMultiDimEquationLst;
  input Integer inInteger;
  output list<Equation> outEquationLst;
  output Integer outInteger;
algorithm
  (outEquationLst,outInteger) := matchcontinue (inVariables,inMultiDimEquationLst,inInteger)
    local
      Variables vars;
      Value aindx;
      list<Equation> eqns,eqns2,res;
      MultiDimEquation a;
      list<MultiDimEquation> algs;
      DAE.Exp e1,e2;
      list<DAE.Exp> a1,a2,a1_1,an;
      list<tuple<DAE.Exp,DAE.Exp>> ealst;
      list<list<tuple<DAE.Exp, Boolean>>> al1,al2;
      list<tuple<DAE.Exp, Boolean>> ebl1,ebl2;
      DAE.ElementSource source;      
    case (vars,{},aindx) then ({},aindx);
    case (vars,((a as MULTIDIM_EQUATION(left=DAE.ARRAY(array=a1),right=DAE.ARRAY(array=a2),source=source)) :: algs),aindx)
      equation
        ealst = Util.listThreadTuple(a1,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
    case (vars,((a as MULTIDIM_EQUATION(left=DAE.UNARY(exp=DAE.ARRAY(array=a1)),right=DAE.ARRAY(array=a2),source=source)) :: algs),aindx)
      equation
        an = Util.listMap(a1,Exp.negate);
        ealst = Util.listThreadTuple(an,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as MULTIDIM_EQUATION(left=DAE.ARRAY(array=a1),right=DAE.UNARY(exp=DAE.ARRAY(array=a2)),source=source)) :: algs),aindx)
      equation
        an = Util.listMap(a2,Exp.negate);
        ealst = Util.listThreadTuple(a1,an);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
    case (vars,((a as MULTIDIM_EQUATION(left=DAE.MATRIX(scalar=al1),right=DAE.MATRIX(scalar=al2),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);
        ealst = Util.listThreadTuple(a1,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);  
    case (vars,((a as MULTIDIM_EQUATION(left=DAE.UNARY(exp=DAE.MATRIX(scalar=al1)),right=DAE.MATRIX(scalar=al2),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);        
        an = Util.listMap(a1,Exp.negate);
        ealst = Util.listThreadTuple(an,a2);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as MULTIDIM_EQUATION(left=DAE.MATRIX(scalar=al1),right=DAE.UNARY(exp=DAE.MATRIX(scalar=al2)),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);        
        an = Util.listMap(a2,Exp.negate);
        ealst = Util.listThreadTuple(a1,an);
        eqns = Util.listMap1(ealst,generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as MULTIDIM_EQUATION(left=e1,right=e2,source=source)) :: algs),aindx)
      equation
        eqns = lowerMultidimeqn(vars, a, aindx);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
  end matchcontinue;
end lowerMultidimeqns2;

protected function lowerMultidimeqn
"function: lowerMultidimeqn
  Lowers a MultiDimEquation by creating an equation for each array
  index, such that BLT can be run correctly.
  inputs:  (Variables, /* vars */
              MultiDimEquation,
              int) /* indx */
  outputs:  Equation list"
  input Variables inVariables;
  input MultiDimEquation inMultiDimEquation;
  input Integer inInteger;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inVariables,inMultiDimEquation,inInteger)
    local
      list<DAE.Exp> expl1,expl2,expl;
      Value numnodes,aindx;
      list<Equation> lst;
      Variables vars;
      list<Value> ds;
      DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";

    case (vars,MULTIDIM_EQUATION(dimSize = ds,left = e1,right = e2,source = source),aindx)
      equation
        expl1 = statesAndVarsExp(e1, vars);
        expl2 = statesAndVarsExp(e2, vars);
        expl = listAppend(expl1, expl2);
        numnodes = Util.listReduce(ds, int_mul);
        lst = lowerMultidimeqn2(expl, numnodes, aindx, source);
      then
        lst;
  end matchcontinue;
end lowerMultidimeqn;

protected function lowerMultidimeqn2
"function: lower_multidimeqns2
  Helper function to lower_multidimeqns
  Creates numnodes Equation nodes so BLT can be run correctly.
  inputs:  (DAE.Exp list, int /* numnodes */, int /* indx */)
  outputs: Equation list ="
  input list<DAE.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input DAE.ElementSource source "the element source";
  output list<Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inExpExpLst1,inInteger2,inInteger3,source)
    local
      list<DAE.Exp> expl;
      Value numnodes_1,numnodes,indx;
      list<Equation> res;
    case (expl,0,_,_) then {};
    case (expl,numnodes,indx,source)
      equation
        numnodes_1 = numnodes - 1;
        res = lowerMultidimeqn2(expl, numnodes_1, indx, source);
      then
        (ARRAY_EQUATION(indx,expl,source) :: res);
  end matchcontinue;
end lowerMultidimeqn2;

protected function lowerAlgorithms
"function: lowerAlgorithms
  This function lowers algorithm sections by generating a list
  of ALGORITHMS nodes for the BLT sorting, which are put in
  the equation list.
  An algorithm that calculates n variables will get n  ALGORITHM nodes
  such that the BLT sorting can be done correctly.
  inputs:  (Variables /* vars */, DAE.Algorithm list)
  outputs: Equation list"
  input Variables vars;
  input list<DAE.Algorithm> algs;
  output list<Equation> eqns;
algorithm
  (eqns,_) := lowerAlgorithms2(vars, algs, 0);
end lowerAlgorithms;

protected function lowerAlgorithms2
"function: lowerAlgorithms2
  Helper function to lowerAlgorithms. To handle indexes in Equation nodes
  for algorithms to indentify the corresponding algorithm.
  inputs:  (Variables /* vars */, DAE.Algorithm list, int /* algindex*/ )
  outputs: (Equation list, int /* updated algindex */ ) ="
  input Variables inVariables;
  input list<DAE.Algorithm> inAlgorithmAlgorithmLst;
  input Integer inInteger;
  output list<Equation> outEquationLst;
  output Integer outInteger;
algorithm
  (outEquationLst,outInteger) := matchcontinue (inVariables,inAlgorithmAlgorithmLst,inInteger)
    local
      Variables vars;
      Value aindx;
      list<Equation> eqns,eqns2,res;
      DAE.Algorithm a;
      list<DAE.Algorithm> algs;
    case (vars,{},aindx) then ({},aindx);
    case (vars,(a :: algs),aindx)
      equation
        eqns = lowerAlgorithm(vars, a, aindx);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerAlgorithms2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
  end matchcontinue;
end lowerAlgorithms2;

protected function lowerAlgorithm
"function: lowerAlgorithm
  Lowers a single algorithm. Creates n ALGORITHM nodes for blt sorting.
  inputs:  (Variables, /* vars */
              DAE.Algorithm,
              int /* algindx */)
  outputs: Equation list"
  input Variables vars;
  input DAE.Algorithm a;
  input Integer aindx;
  output list<Equation> lst;
  list<DAE.Exp> inputs,outputs;
  Value numnodes;
algorithm
  (inputs,outputs) := lowerAlgorithmInputsOutputs(vars, a);
  numnodes := listLength(outputs);
  lst := lowerAlgorithm2(inputs, outputs, numnodes, aindx);
end lowerAlgorithm;

protected function lowerAlgorithm2
"function: lowerAlgorithm2
  Helper function to lower_algorithm
  inputs:  (DAE.Exp list /* inputs   */,
              DAE.Exp list /* outputs  */,
              int          /* numnodes */,
              int          /* aindx    */)
  outputs:  (Equation list)"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inExpExpLst1,inExpExpLst2,inInteger3,inInteger4)
    local
      Value numnodes_1,numnodes,aindx;
      list<Equation> res;
      list<DAE.Exp> inputs,outputs;
    case (_,_,0,_) then {};
    case (inputs,outputs,numnodes,aindx)
      equation
        numnodes_1 = numnodes - 1;
        res = lowerAlgorithm2(inputs, outputs, numnodes_1, aindx);
      then
        (ALGORITHM(aindx,inputs,outputs,DAE.emptyElementSource) :: res);
  end matchcontinue;
end lowerAlgorithm2;

public function lowerAlgorithmInputsOutputs
"function: lowerAlgorithmInputsOutputs
  This function finds the inputs and the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm."
  input Variables inVariables;
  input DAE.Algorithm inAlgorithm;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2) := matchcontinue (inVariables,inAlgorithm)
    local
      list<DAE.Exp> inputs1,outputs1,inputs2,outputs2,inputs,outputs;
      Variables vars;
      Algorithm.Statement s;
      list<Algorithm.Statement> ss;
    case (_,DAE.ALGORITHM_STMTS(statementLst = {})) then ({},{});
    case (vars,DAE.ALGORITHM_STMTS(statementLst = (s :: ss)))
      equation
        (inputs1,outputs1) = lowerStatementInputsOutputs(vars, s);
        (inputs2,outputs2) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(ss));
        inputs = Util.listUnionOnTrue(inputs1, inputs2, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then
        (inputs,outputs);
  end matchcontinue;
end lowerAlgorithmInputsOutputs;

protected function lowerStatementInputsOutputs
"function: lowerStatementInputsOutputs
  Helper relatoin to lowerAlgorithmInputsOutputs
  Investigates single statements. Returns DAE.Exp list
  instead of DAE.ComponentRef list because derivatives must
  be handled as well.
  inputs:  (Variables, /* vars */
              Algorithm.Statement)
  outputs: (DAE.Exp list, /* inputs, CREF or der(CREF)  */
              DAE.Exp list  /* outputs, CREF or der(CREF) */)"
  input Variables inVariables;
  input Algorithm.Statement inStatement;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2) := matchcontinue (inVariables,inStatement)
    local
      list<DAE.Exp> inputs;
      list<DAE.Exp> inputs1;
      list<DAE.Exp> inputs2;
      list<DAE.Exp> outputs;
      list<DAE.Exp> outputs1;
      list<DAE.Exp> outputs2;
      Variables vars;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<Algorithm.Statement> statements;
      Algorithm.Statement stmt;
      list<DAE.Exp> expl;
      list<Algorithm.Statement> stmts;
      Algorithm.Else elsebranch;
      list<DAE.Exp> inputs,inputs1,inputs2,inputs3,outputs,outputs1,outputs2;
      list<DAE.ComponentRef> crefs;
      DAE.Exp exp1;
      list<Option<Integer>> ad;
      list<list<DAE.Subscript>> subslst,subslst1;
			// a := expr;
    case (vars,DAE.STMT_ASSIGN(type_ = tp,exp1 = exp1,exp = e))
      equation
        inputs = statesAndVarsExp(e, vars);
      then
        (inputs,{exp1});
    case (vars,DAE.STMT_WHEN(exp = e,statementLst = statements,elseWhen = NONE))
      equation
        (inputs,outputs) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(statements));
        inputs2 = list_append(statesAndVarsExp(e, vars),inputs);
      then
        (inputs2,outputs);
    case (vars,DAE.STMT_WHEN(exp = e,statementLst = statements,elseWhen = SOME(stmt)))
      equation
				(inputs1, outputs1) = lowerStatementInputsOutputs(vars,stmt);
        (inputs,outputs) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(statements));
        inputs2 = list_append(statesAndVarsExp(e, vars),inputs);
        outputs2 = list_append(outputs, outputs1);
      then
        (inputs2,outputs2);
			// (a,b,c) := foo(...)
    case (vars,DAE.STMT_TUPLE_ASSIGN(type_ = tp, expExpLst = expl, exp = e))
      equation
        inputs = statesAndVarsExp(e,vars);
        crefs = Util.listFlatten(Util.listMap(expl,Exp.getCrefFromExp));
        outputs =  Util.listMap1(crefs,Exp.makeCrefExp,DAE.ET_OTHER());
      then
        (inputs,outputs);

    // v := expr   where v is array.
    case (vars,DAE.STMT_ASSIGN_ARR(type_ = DAE.ET_ARRAY(ty=tp,arrayDimensions=ad), componentRef = cr, exp = e))
      equation
        inputs = statesAndVarsExp(e,vars);  
        subslst = arrayDimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crefs = Util.listMap1r(subslst1,Exp.subscriptCref,cr);
        expl = Util.listMap1(crefs,Exp.makeCrefExp,tp);             
      then (inputs,expl);

    case(vars,DAE.STMT_IF(exp = e, statementLst = stmts, else_ = elsebranch))
      equation
        (inputs1,outputs1) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
        (inputs2,outputs2) = lowerElseAlgorithmInputsOutputs(vars,elsebranch);
        inputs3 = statesAndVarsExp(e,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2,inputs3}, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then (inputs,outputs);

    case(vars,DAE.STMT_ASSERT(cond = e1,msg=e2))
      local DAE.Exp e1,e2;
      equation
        inputs1 = statesAndVarsExp(e1,vars);
        inputs2 = statesAndVarsExp(e1,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2}, Exp.expEqual);
     then (inputs,{});

    case(vars, DAE.STMT_FOR(ident = iteratorName, exp = e, statementLst = stmts))
      local
        DAE.Ident iteratorName;
        DAE.Exp iteratorExp;
        list<DAE.Exp> arrayVars, nonArrayVars;
        list<list<DAE.Exp>> arrayElements;
        list<DAE.Exp> flattenedElements;
      equation
        (inputs1,outputs1) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(stmts));
        inputs2 = statesAndVarsExp(e, vars);
        // Split the output variables into variables that depend on the loop
        // variable and variables that don't.
        iteratorExp = DAE.CREF(DAE.CREF_IDENT(iteratorName, DAE.ET_INT(), {}), DAE.ET_INT());
        (arrayVars, nonArrayVars) = Util.listSplitOnTrue1(outputs1, isLoopDependent, iteratorExp);
        arrayVars = Util.listMap(arrayVars, devectorizeArrayVar);
        // Explode array variables into their array elements.
        // I.e. var[i] => var[1], var[2], var[3] etc.
        arrayElements = Util.listMap3(arrayVars, explodeArrayVars, iteratorExp, e, vars);
        flattenedElements = Util.listFlatten(arrayElements);
        inputs = Util.listUnion(inputs1, inputs2);
        outputs = Util.listUnion(nonArrayVars, flattenedElements);
      then (inputs, outputs);
			  
		case(vars, DAE.STMT_WHILE(exp = e, statementLst = stmts))
			equation
				(inputs1,outputs) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(stmts));
				inputs2 = statesAndVarsExp(e, vars);
				inputs = Util.listUnion(inputs1, inputs2);
			then (inputs, outputs);
			  
		case(vars, DAE.STMT_NORETCALL(exp = e))
		  equation
		    inputs = statesAndVarsExp(e, vars);
		  then
		    (inputs, {});
  end matchcontinue;
end lowerStatementInputsOutputs;

protected function lowerElseAlgorithmInputsOutputs
"Helper function to lowerStatementInputsOutputs"
  input Variables vars;
  input Algorithm.Else elseBranch;
  output list<DAE.Exp> inputs;
  output list<DAE.Exp> outputs;
algorithm
  (inputs,outputs) := matchcontinue (vars,elseBranch)
    local
      list<Algorithm.Statement> stmts;
      list<DAE.Exp> inputs1,inputs2,inputs3,outputs1,outputs2;
      DAE.Exp e;

    case(vars,DAE.NOELSE()) then ({},{});

    case(vars,DAE.ELSEIF(e,stmts,elseBranch))
      equation
        (inputs1, outputs1) = lowerElseAlgorithmInputsOutputs(vars,elseBranch);
        (inputs2, outputs2) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
        inputs3 = statesAndVarsExp(e,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2, inputs3}, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then (inputs,outputs);

    case(vars,DAE.ELSE(stmts))
      equation
        (inputs, outputs) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
      then (inputs,outputs);
  end matchcontinue;
end lowerElseAlgorithmInputsOutputs;

protected function statesAndVarsExp
"function: statesAndVarsExp
  This function investigates an expression and returns as subexpressions
  that are variable names or derivatives of state names or states
  inputs:  (DAE.Exp, Variables /* vars */)
  outputs: DAE.Exp list"
  input DAE.Exp inExp;
  input Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst := matchcontinue (inExp,inVariables)
    local
      DAE.Exp e,e1,e2,e3;
      DAE.ComponentRef cr;
      DAE.ExpType tp;
      Variables vars;
      list<DAE.Exp> s1,s2,res,s3,expl;
      DAE.Flow flowPrefix;
      list<Value> p;
      list<list<DAE.Exp>> lst;
      list<list<tuple<DAE.Exp, Boolean>>> mexp;
      list<DAE.ExpVar> varLst;
    /* Special Case for Records */
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),vars)
      equation
        DAE.ET_COMPLEX(varLst=varLst) = Exp.crefLastType(cr);
        expl = Util.listMap1(varLst,generateCrefsExpFromType,e);
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;  
    /* Special Case for unextended arrays */
    case ((e as DAE.CREF(componentRef = cr,ty = DAE.ET_ARRAY(arrayDimensions=_))),vars)
      equation
        (e1,_) = extendArrExp(e,NONE());
        res = statesAndVarsExp(e1, vars);
      then
        res; 
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),vars)
      equation
        (_,_) = getVar(cr, vars);
      then
        {e};
    case (DAE.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    case (DAE.UNARY(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    case (DAE.LUNARY(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        s3 = statesAndVarsExp(e3, vars);
        res = Util.listListUnionOnTrue({s1,s2,s3}, Exp.expEqual);
      then
        res;
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})),vars)
      equation
        ((VAR(varKind = STATE()) :: _),_) = getVar(cr, vars);
      then
        {e};
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (_,p) = getVar(cr, vars);
      then
        {};
    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.PARTEVALFUNCTION(expList = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.MATRIX(scalar = mexp),vars)
      equation
        res = statesAndVarsMatrixExp(mexp, vars);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars)
      equation
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (DAE.CAST(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.ASUB(exp = e),vars)
      equation
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars)
      equation
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    // ignore constants!
    case (DAE.ICONST(_),_) then {};
    case (DAE.RCONST(_),_) then {};
    case (DAE.BCONST(_),_) then {};
    case (DAE.SCONST(_),_) then {};
    // deal with possible failure
    case (e,vars)
      equation
        // adrpo: TODO! FIXME! this function fails for some of the expressions: cr.cr.cr[{1,2,3}] for example.
        // Debug.fprintln("daelow", "- DAELow.statesAndVarsExp failed to extract states or vars from expression: " +& Exp.dumpExpStr(e,0));
      then {};
  end matchcontinue;
end statesAndVarsExp;

protected function statesAndVarsMatrixExp
"function: statesAndVarsMatrixExp"
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> expl_1,ms_1,res;
      list<list<DAE.Exp>> lst;
      list<tuple<DAE.Exp, Boolean>> expl;
      list<list<tuple<DAE.Exp, Boolean>>> ms;
      Variables vars;
    case ({},_) then {};
    case ((expl :: ms),vars)
      equation
        expl_1 = Util.listMap(expl, Util.tuple21);
        lst = Util.listMap1(expl_1, statesAndVarsExp, vars);
        ms_1 = statesAndVarsMatrixExp(ms, vars);
        res = Util.listListUnionOnTrue((ms_1 :: lst), Exp.expEqual);
      then
        res;
  end matchcontinue;
end statesAndVarsMatrixExp;

protected function isLoopDependent
  "Checks if an expression is a variable that depends on a loop iterator,
  ie. for i loop
        V[i] = ...  // V depends on i
      end for;
  Used by lowerStatementInputsOutputs in STMT_FOR case."
  input DAE.Exp varExp;
  input DAE.Exp iteratorExp;
  output Boolean isDependent;
algorithm
  isDependent := matchcontinue(varExp, iteratorExp)
    local
      list<DAE.Exp> subscript_exprs;
      list<DAE.Subscript> subscripts;
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef = cr), _)
      equation
        subscripts = Exp.crefSubs(cr);
        subscript_exprs = Util.listMap(subscripts, Exp.subscriptExp);
        true = isLoopDependentHelper(subscript_exprs, iteratorExp);
      then true;
    case (DAE.ASUB(sub = subscript_exprs), _)
      equation
        true = isLoopDependentHelper(subscript_exprs, iteratorExp);
      then true;
    case (_,_)
      then false;
  end matchcontinue;
end isLoopDependent;

protected function isLoopDependentHelper
  "Helper for isLoopDependent.
  Checks if a list of subscripts contains a certain iterator expression."
  input list<DAE.Exp> subscripts;
  input DAE.Exp iteratorExp;
  output Boolean isDependent;
algorithm
  isDependent := matchcontinue(subscripts, iteratorExp)
    local
      DAE.Exp subscript;
      list<DAE.Exp> rest;
    case ({}, _) then false;
    case (subscript :: rest, _)
      equation
        true = Exp.expContains(subscript, iteratorExp);
      then true;
    case (subscript :: rest, _)
      equation
        true = isLoopDependentHelper(rest, iteratorExp);
      then true;
    case (_, _) then false;
  end matchcontinue;
end isLoopDependentHelper;

public function devectorizeArrayVar
  input DAE.Exp arrayVar;
  output DAE.Exp newArrayVar;
algorithm
  newArrayVar := matchcontinue(arrayVar)
    local 
      DAE.ComponentRef cr;
      DAE.ExpType ty;
      list<DAE.Exp> subs;
    case (DAE.ASUB(exp = DAE.ARRAY(array = (DAE.CREF(componentRef = cr, ty = ty) :: _)), sub = subs))
      equation
        cr = Exp.crefStripLastSubs(cr);
      then
        DAE.ASUB(DAE.CREF(cr, ty), subs);
    case (DAE.ASUB(exp = DAE.MATRIX(scalar = (((DAE.CREF(componentRef = cr, ty = ty), _) :: _) :: _)), sub = subs))
      equation
        cr = Exp.crefStripLastSubs(cr);
      then
        DAE.ASUB(DAE.CREF(cr, ty), subs);
    case (_) then arrayVar;
  end matchcontinue;
end devectorizeArrayVar;

protected function explodeArrayVars
  "Explodes an array variable into its elements. Takes a variable that is a CREF
  or ASUB, the name of the iterator variable and a range expression that the
  iterator iterates over."
  input DAE.Exp arrayVar;
  input DAE.Exp iteratorExp;
  input DAE.Exp rangeExpr;
  input Variables vars;
  output list<DAE.Exp> arrayElements;
algorithm
  arrayElements := matchcontinue(arrayVar, iteratorExp, rangeExpr, vars)
    local
      list<DAE.Exp> subs;
      list<DAE.Exp> clonedElements, newElements;
      list<DAE.Exp> indices;
      DAE.ComponentRef cref;
      list<Var> arrayElements;
      list<DAE.ComponentRef> varCrefs;
      list<DAE.Exp> varExprs;

    case (DAE.CREF(componentRef = _), _, _, _)
      equation
        indices = rangeIntExprs(rangeExpr);
        clonedElements = Util.listFill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;
        
    case (DAE.ASUB(exp = DAE.CREF(componentRef = _)), _, _, _)
      equation
        // If the range is constant, then we can use it to generate only those
        // array elements that are actually used.
        indices = rangeIntExprs(rangeExpr);
        clonedElements = Util.listFill(arrayVar, listLength(indices));
        newElements = generateArrayElements(clonedElements, indices, iteratorExp);
      then newElements;
        
    case (DAE.CREF(componentRef = cref), _, _, _)
      equation
        (arrayElements, _) = getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, varCref);
        varExprs = Util.listMap(varCrefs, Exp.crefExp);
      then varExprs;

    case (DAE.ASUB(exp = DAE.CREF(componentRef = cref)), _, _, _)
      equation
        // If the range is not constant, then we just extract all array elements
        // of the array.
        (arrayElements, _) = getVar(cref, vars);
        varCrefs = Util.listMap(arrayElements, varCref);
        varExprs = Util.listMap(varCrefs, Exp.crefExp);
      then varExprs;
      
    case (DAE.ASUB(exp = e), _, _, _)
      local DAE.Exp e;
      equation
        varExprs = Exp.flattenArrayExpToList(e);
      then
        varExprs;
  end matchcontinue;
end explodeArrayVars;

protected function rangeIntExprs
  "Tries to convert a range to a list of integer expressions. Returns a list of
  integer expressions if possible, or fails. Used by explodeArrayVars."
  input DAE.Exp range;
  output list<DAE.Exp> integers;
algorithm
  integers := matchcontinue(range)
    local
      list<DAE.Exp> arrayElements;
    case (DAE.ARRAY(array = arrayElements))
      then arrayElements;
    case (DAE.RANGE(exp = DAE.ICONST(integer = start), range = DAE.ICONST(integer = stop), expOption = NONE))
      local
        Integer start, stop;
        list<Values.Value> vals;
      equation
        vals = Ceval.cevalRange(start, 1, stop);
        arrayElements = Util.listMap(vals, ValuesUtil.valueExp);
      then
        arrayElements;  
    case (_) then fail();
  end matchcontinue;
end rangeIntExprs;

protected function generateArrayElements
  "Takes a list of identical CREF or ASUB expressions, a list of ICONST indices
  and a loop iterator expression, and recursively replaces the loop iterator
  with a constant index. Ex:
    generateArrayElements(cref[i,j], {1,2,3}, j) =>
      {cref[i,1], cref[i,2], cref[i,3]}"
  input list<DAE.Exp> clones;
  input list<DAE.Exp> indices;
  input DAE.Exp iteratorExp;
  output list<DAE.Exp> newElements;
algorithm
  newElements := matchcontinue(clones, indices, iteratorExp)
    local
      DAE.Exp clone, newElement, newElement2, index;
      list<DAE.Exp> restClones, restIndices, elements;
    case ({}, {}, _) then {};
    case (clone :: restClones, index :: restIndices, _)
      equation
        (newElement, _) = Exp.replaceExp(clone, iteratorExp, index);
        newElement2 = simplifySubscripts(newElement);
        elements = generateArrayElements(restClones, restIndices, iteratorExp);
      then (newElement2 :: elements);
  end matchcontinue;
end generateArrayElements;

protected function simplifySubscripts
  "Tries to simplify the subscripts of a CREF or ASUB. If an ASUB only contains
  constant subscripts, such as cref[1,4], then it also needs to be converted to
  a CREF."
  input DAE.Exp asub;
  output DAE.Exp maybeCref;
algorithm
  maybeCref := matchcontinue(asub)
    local
      DAE.Ident varIdent;
      DAE.ExpType arrayType, varType;
      list<DAE.Exp> subExprs, subExprsSimplified;
      list<DAE.Subscript> subscripts;
      DAE.Exp newCref;

    // A CREF => just simplify the subscripts.
    case (DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, subscripts), varType))
      equation
        subscripts = Util.listMap(subscripts, simplifySubscript);
      then DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, subscripts), varType);
        
    // An ASUB => convert to CREF if only constant subscripts.
    case (DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, _), varType), subExprs))
      equation
        {} = Util.listSelect(subExprs, Exp.isNotConst);
        // If a subscript is not a single constant value it needs to be
        // simplified, e.g. cref[3+4] => cref[7], otherwise some subscripts
        // might be counted twice, such as cref[3+4] and cref[2+5], even though
        // they reference the same element.
        subExprsSimplified = Util.listMap(subExprs, Exp.simplify);
        subscripts = Util.listMap(subExprsSimplified, Exp.makeIndexSubscript);
      then DAE.CREF(DAE.CREF_IDENT(varIdent, arrayType, subscripts), varType);
    case (_) then asub;
  end matchcontinue;
end simplifySubscripts;

protected function simplifySubscript
  input DAE.Subscript sub;
  output DAE.Subscript simplifiedSub;
algorithm
  simplifiedSub := matchcontinue(sub)
    case (DAE.INDEX(exp = e))
      local
        DAE.Exp e;
      equation
        e = Exp.simplify(e);
      then DAE.INDEX(e);
    case (_) then sub;
  end matchcontinue;
end simplifySubscript;

protected function lowerEqn
"function: lowerEqn
  Helper function to lower2.
  Transforms a DAE.Element to Equation."
  input DAE.Element inElement;
  output Equation outEquation;
algorithm
  outEquation :=  matchcontinue (inElement)
    local DAE.Exp e1,e2;
          DAE.ComponentRef cr1,cr2;
          DAE.ElementSource source "the element source";

    case (DAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        EQUATION(e1,e2,source);

    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source))
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        EQUATION(e1,e2,source);

    case (DAE.EQUEQUATION(cr1 = cr1, cr2 = cr2,source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(DAE.CREF(cr2, DAE.ET_OTHER()));
      then
        EQUATION(e1,e2,source);

    case (DAE.DEFINE(componentRef = cr1, exp = e1, source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(e1);
      then
        EQUATION(e1,e2,source);

    case (DAE.INITIALDEFINE(componentRef = cr1, exp = e1, source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(e1);
      then
        EQUATION(e1,e2,source);
  end matchcontinue;
end lowerEqn;

protected function lowerArrEqn
"function: lowerArrEqn
  Helper function to lower2.
  Transform a DAE.Element to MultiDimEquation."
  input DAE.Element inElement;
  input DAE.FunctionTree funcs;
  output MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue (inElement,funcs)
    local
			DAE.Exp e1,e2,e1_1,e2_1,e1_2,e2_2,e1_3,e2_3;
      list<Value> ds;
      DAE.ElementSource source;

    case (DAE.ARRAY_EQUATION(dimension = ds, exp = e1, array = e2, source = source),funcs)
      equation
        e1_1 = Inline.inlineExp(e1,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        (e1_2,_) = extendArrExp(e1_1,SOME(funcs));
        (e2_2,_) = extendArrExp(e2_1,SOME(funcs));
        e1_3 = Exp.simplify(e1_2);
        e2_3 = Exp.simplify(e2_2);
      then
        MULTIDIM_EQUATION(ds,e1_3,e2_3,source);

		case (DAE.INITIAL_ARRAY_EQUATION(dimension = ds, exp = e1, array = e2, source = source),funcs)
			equation
        e1_1 = Inline.inlineExp(e1,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        (e1_2,_) = extendArrExp(e1_1,SOME(funcs));
        (e2_2,_) = extendArrExp(e2_1,SOME(funcs));
        e1_3 = Exp.simplify(e1_2);
        e2_3 = Exp.simplify(e2_2);
      then
        MULTIDIM_EQUATION(ds,e1_3,e2_3,source);
  end matchcontinue;
end lowerArrEqn;

protected function extendAlgorithm "
Author: Frenkel TUD 2010-07"
  input DAE.Algorithm inAlg;
  input Option<DAE.FunctionTree> funcs;  
  output DAE.Algorithm outAlg;
algorithm 
  outAlg := matchcontinue(inAlg,funcs)
    local list<DAE.Statement> statementLst;
    case(DAE.ALGORITHM_STMTS(statementLst=statementLst),funcs)
      equation
        (statementLst,_) = DAEUtil.traverseDAEEquationsStmts(statementLst, extendArrExp, funcs);
      then
        DAE.ALGORITHM_STMTS(statementLst);
    case(inAlg,funcs) then inAlg;        
  end matchcontinue;
end extendAlgorithm;

protected function extendArrExp "
Author: Frenkel TUD 2010-07"
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> outfuncs;  
algorithm 
  (outExp,outfuncs) := matchcontinue(inExp,infuncs)
    local DAE.Exp e;
    case(inExp,infuncs)
      equation
        ((e,outfuncs)) = Exp.traverseExp(inExp, traversingextendArrExp, infuncs);
      then
        (e,outfuncs);
    case(inExp,infuncs) then (inExp,infuncs);        
  end matchcontinue;
end extendArrExp;

protected function traversingextendArrExp "
Author: Frenkel TUD 2010-07."
  input tuple<DAE.Exp, Option<DAE.FunctionTree> > inExp;
  output tuple<DAE.Exp, Option<DAE.FunctionTree> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    Option<DAE.FunctionTree> funcs;
    DAE.ComponentRef cr;
    list<DAE.ComponentRef> crlst;
    DAE.ExpType t,ty;
    list<Option<Integer>> ad;
    Integer i,j;
    list<list<DAE.Subscript>> subslst,subslst1;
    list<DAE.Exp> expl;
    DAE.Exp e,e_new;
    list<DAE.ExpVar> varLst;
    Absyn.Path name;
    tuple<DAE.Exp, Option<DAE.FunctionTree> > restpl;  
    list<list<tuple<DAE.Exp, Boolean>>> scalar;
  // CASE for Matrix    
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad as {SOME(i),SOME(j)})), funcs) )
    equation
        subslst = arrayDimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,Exp.subscriptCref,cr);
        expl = Util.listMap1(crlst,Exp.makeCrefExp,ty);
        scalar = makeMatrix(expl,j,j,{});
        e_new = DAE.MATRIX(t,i,scalar);
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);   
  case( (DAE.CREF(componentRef=cr,ty= t as DAE.ET_ARRAY(ty=ty,arrayDimensions=ad)), funcs) )
    equation
        subslst = arrayDimensionsToRange(ad);
        subslst1 = rangesToSubscripts(subslst);
        crlst = Util.listMap1r(subslst1,Exp.subscriptCref,cr);
        expl = Util.listMap1(crlst,Exp.makeCrefExp,ty);
        e_new = DAE.ARRAY(t,true,expl);
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);          
  case( (e as DAE.CREF(componentRef=cr,ty= t as DAE.ET_COMPLEX(name=name,varLst=varLst)), funcs) )
    equation
        expl = Util.listMap1(varLst,generateCrefsExpFromType,e);
        e_new = DAE.CALL(name,expl,false,false,t,DAE.NO_INLINE());
        restpl = Exp.traverseExp(e_new, traversingextendArrExp, funcs);
    then
      (restpl);
  case(inExp) then inExp;
end matchcontinue;
end traversingextendArrExp;

protected function makeMatrix
  input list<DAE.Exp> expl;
  input Integer r;
  input Integer n;
  input list<tuple<DAE.Exp, Boolean>> incol;
  output list<list<tuple<DAE.Exp, Boolean>>> scalar;
algorithm
  scalar := matchcontinue (expl, r, n, incol)
    local 
      DAE.Exp e;
      list<DAE.Exp> rest;
      list<list<tuple<DAE.Exp, Boolean>>> res;
      list<tuple<DAE.Exp, Boolean>> col;
      Exp.Type tp;
      Boolean builtin;      
  case({},r,n,incol)
    equation
      col = listReverse(incol);
    then {col};  
  case(e::rest,r,n,incol)
    equation
      true = intEq(r,0);
      col = listReverse(incol);
      res = makeMatrix(e::rest,n,n,{});
    then      
      (col::res);
  case(e::rest,r,n,incol)
    equation
      tp = Exp.typeof(e);
      builtin = Exp.typeBuiltin(tp);
      res = makeMatrix(rest,r-1,n,(e,builtin)::incol);
    then      
      res;
  end matchcontinue;
end makeMatrix;
  
public function collateAlgorithm "
Author: Frenkel TUD 2010-07"
  input DAE.Algorithm inAlg;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Algorithm outAlg;
algorithm 
  outAlg := matchcontinue(inAlg,infuncs)
    local list<DAE.Statement> statementLst;
    case(DAE.ALGORITHM_STMTS(statementLst=statementLst),infuncs)
      equation
        (statementLst,_) = DAEUtil.traverseDAEEquationsStmts(statementLst, collateArrExp, infuncs);
      then
        DAE.ALGORITHM_STMTS(statementLst);
    case(inAlg,infuncs) then inAlg;        
  end matchcontinue;
end collateAlgorithm;

public function collateArrExp "
Author: Frenkel TUD 2010-07"
  input DAE.Exp inExp;
  input Option<DAE.FunctionTree> infuncs;  
  output DAE.Exp outExp;
  output Option<DAE.FunctionTree> outfuncs;  
algorithm 
  (outExp,outfuncs) := matchcontinue(inExp,infuncs)
    local DAE.Exp e;
    case(inExp,infuncs)
      equation
        ((e,outfuncs)) = Exp.traverseExp(inExp, traversingcollateArrExp, infuncs);
      then
        (e,outfuncs);
    case(inExp,infuncs) then (inExp,infuncs);        
  end matchcontinue;
end collateArrExp;  
  
protected function traversingcollateArrExp "
Author: Frenkel TUD 2010-07."
  input tuple<DAE.Exp, Option<DAE.FunctionTree> > inExp;
  output tuple<DAE.Exp, Option<DAE.FunctionTree> > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    Option<DAE.FunctionTree> funcs;
    DAE.ComponentRef cr;
    DAE.ExpType ty;
    Integer i;
    DAE.Exp e,e1,e1_1,e1_2;
    Boolean b;
    case ((e as DAE.MATRIX(ty=ty,integer=i,scalar=(((e1 as DAE.CREF(componentRef = cr)),_)::_)::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));
    case ((e as DAE.MATRIX(ty=ty,integer=i,scalar=(((e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr))),_)::_)::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));        
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.CREF(componentRef = cr))::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));  
    case ((e as DAE.ARRAY(ty=ty,scalar=b,array=(e1 as DAE.UNARY(exp = DAE.CREF(componentRef = cr)))::_),funcs))
      equation
        e1_1 = Exp.expStripLastSubs(e1);
        (e1_2,_) = extendArrExp(e1_1,funcs);
        true = Exp.expEqual(e,e1_2);
      then     
        ((e1_1,funcs));               
  case(inExp) then inExp;
end matchcontinue;
end traversingcollateArrExp;  
  
protected function lowerComplexEqn
"function: lowerComplexEqn
  Helper function to lower2.
  Transform a DAE.Element to ComplexEquation."
  input DAE.Element inElement;
  input DAE.FunctionTree funcs;
  output list<Equation> outComplexEquations;
  output list<MultiDimEquation> outMultiDimEquations;  
algorithm
  (outComplexEquations,outMultiDimEquations) := matchcontinue (inElement, funcs)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      DAE.ExpType ty;
      list<DAE.ExpVar> varLst;
      Integer i;
      list<Equation> complexEqs;
      list<MultiDimEquation> arreqns;
      DAE.ElementSource source "the element source";

    // normal first try to inline function calls and extend the equations
    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        // inline 
        e1_1 = Inline.inlineExp(e1,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        // extend      
        ((complexEqs,arreqns)) = extendRecordEqns(COMPLEX_EQUATION(-1,e1_1,e2_1,source),funcs);
      then
        (complexEqs,arreqns);
    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        // create as many equations as the dimension of the record
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        complexEqs = Util.listFill(COMPLEX_EQUATION(-1,e1,e2,source), i);
      then
        (complexEqs,{});
    // initial first try to inline function calls and extend the equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        // inline 
        e1_1 = Inline.inlineExp(e1,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(NONE(),SOME(funcs),{DAE.NORM_INLINE()}));
        // extend      
        ((complexEqs,arreqns)) = extendRecordEqns(COMPLEX_EQUATION(-1,e1_1,e2_1,source),funcs);
      then
        (complexEqs,arreqns);
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        // create as many equations as the dimension of the record
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        complexEqs = Util.listFill(COMPLEX_EQUATION(-1,e1,e2,source), i);
      then
        (complexEqs,{});
    case (_,_)
      equation
        print("- DAELow.lowerComplexEqn failed!\n");
      then ({},{});
  end matchcontinue;
end lowerComplexEqn;

protected function lowerVar
"function: lowerVar
  Transforms a DAE variable to DAELOW variable.
  Includes changing the ComponentRef name to a simpler form
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\",{2}) )
  inputs: (DAE.Element, BinTree /* states */)
  outputs: Var"
  input DAE.Element inElement;
  input BinTree inBinTree;
  output Var outVar;
  output Option<DAE.Exp> outBinding;
  output BinTree outBinTree;
algorithm
  (outVar,outBinding,outBinTree) := matchcontinue (inElement,inBinTree)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      BinTree states;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment),states)
      equation
        (kind_1,states) = lowerVarkind(kind, t, name, dir, flowPrefix, streamPrefix, states, dae_var_attr);
        tp = lowerType(t);
      then
        (VAR(name,kind_1,dir,tp,NONE,NONE,dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix), bind, states);
  end matchcontinue;
end lowerVar;

protected function lowerKnownVar
"function: lowerKnownVar
  Helper function to lower2"
  input DAE.Element inElement;
  output Var outVar;
algorithm
  outVar := matchcontinue (inElement)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment))
      equation
        kind_1 = lowerKnownVarkind(kind, name, dir, flowPrefix);
        tp = lowerType(t);
      then
        VAR(name,kind_1,dir,tp,bind,NONE,dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);

    case (_)
      equation
        print("-DAELow.lowerKnownVar failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVar;

protected function lowerExtObjVar
" Helper function to lower2
  Fails for all variables except external object instances."
  input DAE.Element inElement;
  output Var outVar;
algorithm
  outVar:=
  matchcontinue (inElement)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment))
      equation
        kind_1 = lowerExtObjVarkind(t);
        tp = lowerType(t);
      then
        VAR(name,kind_1,dir,tp,bind,NONE,dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end lowerExtObjVar;

protected function lowerVarkind
"function: lowerVarkind
  Helper function to lowerVar.
  inputs: (DAE.VarKind,
           Type,
           DAE.ComponentRef,
           DAE.VarDirection, /* input/output/bidir */
           DAE.Flow,
           DAE.Stream,
           BinTree /* states */)
  outputs  VarKind
  NOTE: Fails for not states that are not algebraic
        variables, e.g. parameters and constants"
  input DAE.VarKind inVarKind;
  input DAE.Type inType;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  input DAE.Stream inStream;
  input BinTree inBinTree;
  input option<DAE.VariableAttributes> daeAttr;
  output VarKind outVarKind;
  output BinTree outBinTree;
algorithm
  (outVarKind,outBinTree) := matchcontinue (inVarKind,inType,inComponentRef,inVarDirection,inFlow,inStream,inBinTree,daeAttr)
    local
      DAE.ComponentRef v,cr;
      BinTree states;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    // States appear differentiated among equations
    case (DAE.VARIABLE(),_,v,_,_,_,states,daeAttr)
      equation
        _ = treeGet(states, v);
      then
        (STATE(),states);
    // Or states have StateSelect.always
    case (DAE.VARIABLE(),_,v,_,_,_,states,SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(DAE.ALWAYS()),_,_,_)))
      equation
      states = treeAdd(states, v, 0);  
    then (STATE(),states);

    case (DAE.VARIABLE(),(DAE.T_BOOL(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (DISCRETE(),states);

    case (DAE.DISCRETE(),(DAE.T_BOOL(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (DISCRETE(),states);

    case (DAE.VARIABLE(),(DAE.T_INTEGER(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (DISCRETE(),states);

    case (DAE.DISCRETE(),(DAE.T_INTEGER(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (DISCRETE(),states);

    case (DAE.VARIABLE(),_,cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (VARIABLE(),states);

    case (DAE.DISCRETE(),_,cr,dir,flowPrefix,_,states,_)
      equation
        failure(topLevelInput(cr, dir, flowPrefix));
      then
        (DISCRETE(),states);
  end matchcontinue;
end lowerVarkind;

protected function topLevelInput
"function: topLevelInput
  author: PA
  Succeds if variable is input declared at the top level of the model,
  or if it is an input in a connector instance at top level."
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm
  _ := matchcontinue (inComponentRef,inVarDirection,inFlow)
    local
      DAE.ComponentRef cr;
      String name;
    case ((cr as DAE.CREF_IDENT(ident = name)),DAE.INPUT(),_)
      equation
        {_} = Util.stringSplitAtChar(name, ".") "top level ident, no dots" ;
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.INPUT(),DAE.NON_FLOW()) /* Connector input variables at top level for crefs that are stringified */
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    case (DAE.CREF_IDENT(ident = name),DAE.INPUT(),DAE.FLOW())
      equation
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    /* For crefs that are not yet stringified, e.g. lower_known_var */
    case (DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _)),DAE.INPUT(),DAE.FLOW()) then ();
    case ((cr as DAE.CREF_QUAL(ident = name,componentRef = DAE.CREF_IDENT(ident = _))),DAE.INPUT(),DAE.NON_FLOW()) then ();
  end matchcontinue;
end topLevelInput;

protected function topLevelOutput
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm
  _ := matchcontinue(inComponentRef, inVarDirection, inFlow)
    case (_, DAE.OUTPUT(), _) then ();
  end matchcontinue;
end topLevelOutput;  

protected function lowerKnownVarkind
"function: lowerKnownVarkind
  Helper function to lowerKnownVar.
  NOTE: Fails for everything but parameters and constants and top level inputs"
  input DAE.VarKind inVarKind;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  output VarKind outVarKind;
algorithm
  outVarKind := matchcontinue (inVarKind,inComponentRef,inVarDirection,inFlow)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (DAE.PARAM(),_,_,_) then PARAM();
    case (DAE.CONST(),_,_,_) then CONST();
    case (DAE.VARIABLE(),cr,dir,flowPrefix)
      equation
        topLevelInput(cr, dir, flowPrefix);
      then
        VARIABLE();
    // adrpo: topLevelInput might fail!
    // case (DAE.VARIABLE(),cr,dir,flowPrefix)
    //  then
    //    VARIABLE();
    case (_,_,_,_)
      equation
        print("lower_known_varkind failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVarkind;

protected function lowerExtObjVarkind
" Helper function to lowerExtObjVar.
  NOTE: Fails for everything but External objects"
  input DAE.Type inType;
  output VarKind outVarKind;
algorithm
  outVarKind:=
  matchcontinue (inType)
    local Absyn.Path path;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_)) then EXTOBJ(path);
  end matchcontinue;
end lowerExtObjVarkind;

public function incidenceMatrix
"function: incidenceMatrix
  author: PA
  Calculates the incidence matrix, i.e. which variables are present
  in each equation."
  input DAELow inDAELow;
  output IncidenceMatrix outIncidenceMatrix;
algorithm
  outIncidenceMatrix := matchcontinue (inDAELow)
    local
      list<Equation> eqnsl;
      list<list<Value>> lstlst;
      list<Value>[:] arr;
      Variables vars;
      EquationArray eqns;
      list<WhenClause> wc;
    case (DAELOW(orderedVars = vars,orderedEqs = eqns, eventInfo = EVENT_INFO(whenClauseLst = wc)))
      equation
        eqnsl = equationList(eqns);
        lstlst = incidenceMatrix2(vars, eqnsl, wc);
        arr = listArray(lstlst);
      then
        arr;
    case (_)
      equation
        print("incidence_matrix failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrix;

protected function incidenceMatrix2
"function: incidenceMatrix2
  author: PA

  Helper function to incidenceMatrix
  Calculates the incidence matrix as a list of list of integers"
  input Variables inVariables;
  input list<Equation> inEquationLst;
  input list<WhenClause> inWhenClause;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inVariables,inEquationLst,inWhenClause)
    local
      list<list<Value>> lst;
      list<Value> row;
      Variables vars;
      Equation e;
      list<Equation> eqns;
      list<WhenClause> wc;
    case (_,{},_) then {};
    case (vars,(e :: eqns),wc)
      equation
        lst = incidenceMatrix2(vars, eqns, wc);
        row = incidenceRow(vars, e, wc);
      then
        (row :: lst);
    case (_,_,_)
      equation
        print("incidence_matrix2 failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrix2;

protected function incidenceRow
"function: incidenceRow
  author: PA
  Helper function to incidenceMatrix. Calculates the indidence row
  in the matrix for one equation."
  input Variables inVariables;
  input Equation inEquation;
  input list<WhenClause> inWhenClause;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVariables,inEquation,inWhenClause)
    local
      list<Value> lst1,lst2,res,res_1;
      Variables vars;
      DAE.Exp e1,e2,e;
      list<list<Value>> lst3;
      list<DAE.Exp> expl,inputs,outputs;
      DAE.ComponentRef cr;
      WhenEquation we;
      Value indx;
      list<WhenClause> wc;
      Integer wc_index;
    case (vars,EQUATION(exp = e1,scalar = e2),_)
      equation
        lst1 = incidenceRowExp(e1, vars) "EQUATION" ;
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,COMPLEX_EQUATION(lhs = e1,rhs = e2),_)
      equation
        lst1 = incidenceRowExp(e1, vars) "COMPLEX_EQUATION" ;
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,ARRAY_EQUATION(crefOrDerCref = expl),_) /* ARRAY_EQUATION */
      equation
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst3);
      then
        res;
    case (vars,SOLVED_EQUATION(componentRef = cr,exp = e),_) /* SOLVED_EQUATION */
      equation
        lst1 = incidenceRowExp(DAE.CREF(cr,DAE.ET_REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,RESIDUAL_EQUATION(exp = e),_) /* RESIDUAL_EQUATION */
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (vars,WHEN_EQUATION(whenEquation = we as WHEN_EQ(index=wc_index)),wc) /* WHEN_EQUATION */
      equation
        (cr,e2) = getWhenEquationExpr(we);
        e1 = DAE.CREF(cr,DAE.ET_OTHER());
        expl = getWhenCondition(wc,wc_index);
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        lst1 = Util.listFlatten(lst3);
        lst2 = incidenceRowExp(e1, vars);
        res = listAppend(lst1, lst2);
        lst1 = incidenceRowExp(e2, vars);
        res = listAppend(res, lst1);
      then
        res;
    case (vars,ALGORITHM(index = indx,in_ = inputs,out = outputs),_)
      /* ALGORITHM For now assume that algorithm will be solvable for correct
	       variables. I.e. find all variables in algorithm and add to lst.
	       If algorithm later on needs to be inverted, i.e. solved for
	       different variables than calculated, a non linear solver or
	       analysis of algorithm itself needs to be implemented.
	    */
      local list<list<Value>> lst1,lst2,res;
      equation
        lst1 = Util.listMap1(inputs, incidenceRowExp, vars);
        lst2 = Util.listMap1(outputs, incidenceRowExp, vars);
        res = listAppend(lst1, lst2);
        res_1 = Util.listFlatten(res);
      then
        res_1;
    case (vars,_,_)
      equation
        print("-incidence_row failed\n");
      then
        fail();
  end matchcontinue;
end incidenceRow;

protected function incidenceRowStmts
"function: incidenceRowStmts
  author: PA
  Helper function to incidenceRow, investigates statements for
  variables, returning variable indexes."
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inAlgorithmStatementLst,inVariables)
    local
      list<Value> lst1,lst2,lst3,res,lst3_1;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      DAE.Exp e,e1;
      list<Algorithm.Statement> rest,stmts;
      Variables vars;
      list<DAE.Exp> expl;
      Algorithm.Else else_;

    case ({},_) then {};
    case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e1,exp = e) :: rest),vars)
      equation
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = incidenceRowExp(e1, vars);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl,exp = e) :: rest),vars)
      local list<list<Value>> lst3;
      equation
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        lst3_1 = Util.listFlatten(lst3);
        res = Util.listFlatten({lst1,lst2,lst3_1});
      then
        res;
    case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr,exp = e) :: rest),vars)
      equation
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = incidenceRowExp(DAE.CREF(cr,DAE.ET_OTHER()), vars);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case ((DAE.STMT_IF(exp = e,statementLst = stmts,else_ = else_) :: rest),vars)
      equation
        print("incidence_row_stmts on IF not implemented\n");
      then
        {};
    case ((DAE.STMT_FOR(type_ = _) :: rest),vars)
      equation
        print("incidence_row_stmts on FOR not implemented\n");
      then
        {};
    case ((DAE.STMT_WHILE(exp = _) :: rest),vars)
      equation
        print("incidence_row_stmts on WHILE not implemented\n");
      then
        {};
    case ((DAE.STMT_WHEN(exp = e) :: rest),vars)
      equation
        print("incidence_row_stmts on WHEN not implemented\n");
      then
        {};
    case ((DAE.STMT_ASSERT(cond = _) :: rest),vars)
      equation
        print("incidence_row_stmts on ASSERT not implemented\n");
      then
        {};
  end matchcontinue;
end incidenceRowStmts;

protected function incidenceRowExp
"function: incidenceRowExp
  author: PA

  Helper function to incidenceRow, investigates expressions for
  variables, returning variable indexes."
  input DAE.Exp inExp;
  input Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inExp,inVariables)
    local
      list<Value> p,p_1,s1,s2,res,s3,lst_1;
      DAE.ComponentRef cr;
      Variables vars;
      DAE.Exp e1,e2,e,e3;
      list<list<Value>> lst;
      list<DAE.Exp> expl;
      list<Var> varslst;

    case (DAE.CREF(componentRef = cr),vars)
      equation
        (varslst,p) = getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,true);
      then
        p_1;
    case (DAE.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.UNARY(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.LUNARY(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars) /* if expressions. */
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        s3 = incidenceRowExp(e3, vars);
        res = Util.listFlatten({s1,s2,s3});
      then
        res;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (varslst,p) = getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,false);
      then
        p_1;        
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        cr = DAE.CREF_QUAL("$DER", DAE.ET_REAL(), {}, cr);
        (varslst,p) = getVar(cr, vars);
        p_1 = incidenceRowExp1(varslst,p,false);
      then
        p_1;
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF(componentRef = cr)}),vars) then {};  /* pre(v) is considered a known variable */
    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst);
      then
        res;
    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        lst_1 = Util.listFlatten(lst);
      then
        lst_1;
    case (DAE.MATRIX(scalar = expl),vars)
      local list<list<tuple<DAE.Exp, Boolean>>> expl;
      equation
        res = incidenceRowMatrixExp(expl, vars);
      then
        res;
    case (DAE.TUPLE(PR = expl),vars)
      equation
				lst = Util.listMap1(expl, incidenceRowExp, vars);
				lst_1 = Util.listFlatten(lst);
        //print("incidence_row_exp TUPLE not impl. yet.");
      then
				lst_1;
    case (DAE.CAST(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.ASUB(exp = e),vars)
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (DAE.REDUCTION(expr = e1,range = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (_,_) then {};
  end matchcontinue;
end incidenceRowExp;

protected function incidenceRowExp1
  input list<Var> inVarLst;
  input list<Integer> inIntegerLst;
  input Boolean notinder;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVarLst,inIntegerLst,notinder)
    local
       list<Var> rest;
       Var v;
       list<Integer> irest,res;
       Integer i,i1;  
       Boolean b;
    case ({},{},_) then {};   
    /*If variable x is a state, der(x) is a variable in incidence matrix,
	       x is inserted as negative value, since it is needed by debugging and
	       index reduction using dummy derivatives */ 
    case (VAR(varKind = STATE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
        i1 = Util.if_(b,-i,i);
      then (i1::res);
    case (VAR(varKind = STATE_DER()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);        
    case (VAR(varKind = VARIABLE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (VAR(varKind = DISCRETE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (VAR(varKind = DUMMY_DER()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);
    case (VAR(varKind = DUMMY_STATE()) :: rest,i::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b); 
      then (i::res);                
    case (_ :: rest,_::irest,b)
      equation
        res = incidenceRowExp1(rest,irest,b);  
      then res;
  end matchcontinue;      
end incidenceRowExp1;

protected function incidenceRowMatrixExp
"function: incidenceRowMatrixExp
  author: PA
  Traverses matrix expressions for building incidence matrix."
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> expl_1;
      list<list<Value>> res1;
      list<Value> res2,res1_1,res;
      list<tuple<DAE.Exp, Boolean>> expl;
      list<list<tuple<DAE.Exp, Boolean>>> es;
      Variables vars;
    case ({},_) then {};
    case ((expl :: es),vars)
      equation
        expl_1 = Util.listMap(expl, Util.tuple21);
        res1 = Util.listMap1(expl_1, incidenceRowExp, vars);
        res2 = incidenceRowMatrixExp(es, vars);
        res1_1 = Util.listFlatten(res1);
        res = listAppend(res1_1, res2);
      then
        res;
  end matchcontinue;
end incidenceRowMatrixExp;

public function emptyVars
"function: emptyVars
  author: PA
  Returns a Variable datastructure that is empty.
  Using the bucketsize 10000 and array size 1000."
  output Variables outVariables;
  list<CrefIndex>[:] arr;
  list<StringIndex>[:] arr2;
  list<Option<Var>> lst;
  Option<Var>[:] emptyarr;
algorithm
  arr := fill({}, 10);
  arr2 := fill({}, 10);
  lst := Util.listFill(NONE, 10);
  emptyarr := listArray(lst);
  outVariables := VARIABLES(arr,arr2,VARIABLE_ARRAY(0,10,emptyarr),10,0);
end emptyVars;

protected function mergeVars
"function: mergeVars
  author: PA
  Takes two sets of Variables and merges them. The variables of the
  first argument takes precedence over the second set, i.e. if a
  variable name exists in both sets, the variable definition from
  the first set is used."
  input Variables inVariables1;
  input Variables inVariables2;
  output Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables1,inVariables2)
    local
      list<Var> varlst;
      Variables vars1_1,vars1,vars2;
    case (vars1,vars2)
      equation
        varlst = varList(vars2);
        vars1_1 = Util.listFold(varlst, addVar, vars1);
      then
        vars1_1;
    case (_,_)
      equation
        print("-merge_vars failed\n");
      then
        fail();
  end matchcontinue;
end mergeVars;

public function addVar
"function: addVar
  author: PA
  Add a variable to Variables.
  If the variable already exists, the function updates the variable."
  input Var inVar;
  input Variables inVariables;
  output Variables outVariables;
algorithm
  outVariables := matchcontinue (inVar,inVariables)
    local
      Value hval,indx,newpos,n_1,hvalold,indxold,bsize,n,indx_1;
      VariableArray varr_1,varr;
      list<CrefIndex> indexes;
      list<CrefIndex>[:] hashvec_1,hashvec;
      String name_str;
      list<StringIndex> indexexold;
      list<StringIndex>[:] oldhashvec_1,oldhashvec;
      Var v,newv;
      DAE.ComponentRef cr,name;
      DAE.Flow flowPrefix;
      Variables vars;
    /* adrpo: ignore records!
    case ((v as VAR(varName = cr,origVarName = name,flowPrefix = flowPrefix, varType = DAE.COMPLEX(_,_))),
          (vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
    then
      vars;
    */
    case ((v as VAR(varName = cr,flowPrefix = flowPrefix)),(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        failure((_,_) = getVar(cr, vars)) "adding when not existing previously" ;
        hval = hashComponentRef(cr);
        indx = intMod(hval, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
        name_str = Exp.printComponentRefStr(cr);
        hvalold = hashString(name_str);
        indxold = intMod(hvalold, bsize);
        indexexold = oldhashvec[indxold + 1];
        oldhashvec_1 = arrayUpdate(oldhashvec, indxold + 1,
          (STRINGINDEX(name_str,newpos) :: indexexold));
      then
        VARIABLES(hashvec_1,oldhashvec_1,varr_1,bsize,n_1);

    case ((newv as VAR(varName = cr,flowPrefix = flowPrefix)),(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        (_,{indx}) = getVar(cr, vars) "adding when already present => Updating value" ;
        indx_1 = indx - 1;
        varr_1 = vararraySetnth(varr, indx_1, newv);
      then
        VARIABLES(hashvec,oldhashvec,varr_1,bsize,n);

    case (_,_)
      equation
        print("-add_var failed\n");
      then
        fail();
  end matchcontinue;
end addVar;

public function vararrayLength
"function: vararrayLength
  author: PA
  Returns the number of variable in the VariableArray"
  input VariableArray inVariableArray;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inVariableArray)
    local Value n;
    case (VARIABLE_ARRAY(numberOfElements = n)) then n;
  end matchcontinue;
end vararrayLength;

public function vararrayAdd
"function: vararrayAdd
  author: PA
  Adds a variable last to the VariableArray, increasing array size
  if no space left by factor 1.4"
  input VariableArray inVariableArray;
  input Var inVar;
  output VariableArray outVariableArray;
algorithm
  outVariableArray := matchcontinue (inVariableArray,inVar)
    local
      Value n_1,n,size,expandsize,expandsize_1,newsize;
      Option<Var>[:] arr_1,arr,arr_2;
      Var v;
      Real rsize,rexpandsize;
    case (VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),v)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(v));
      then
        VARIABLE_ARRAY(n_1,size,arr_1);
    case (VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),v)
      equation
        (n < size) = false "Do NOT have splace to add array elt. Expand with factor 1.4" ;
        rsize = intReal(size);
        rexpandsize = rsize*. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE);
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(v));
      then
        VARIABLE_ARRAY(n_1,newsize,arr_2);
    case (_,_)
      equation
        print("-vararray_add failed\n");
      then
        fail();
  end matchcontinue;
end vararrayAdd;

public function vararraySetnth
"function: vararraySetnth
  author: PA
  Set the n:th variable in the VariableArray to v.
 inputs:  (VariableArray, int /* n */, Var /* v */)
 outputs: VariableArray ="
  input VariableArray inVariableArray;
  input Integer inInteger;
  input Var inVar;
  output VariableArray outVariableArray;
algorithm
  outVariableArray := matchcontinue (inVariableArray,inInteger,inVar)
    local
      Option<Var>[:] arr_1,arr;
      Value n,size,pos;
      Var v;

    case (VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr),pos,v)
      equation
        (pos < size) = true;
        arr_1 = arrayUpdate(arr, pos + 1, SOME(v));
      then
        VARIABLE_ARRAY(n,size,arr_1);

    case (_,_,_)
      equation
        print("-vararray_setnth failed\n");
      then
        fail();
  end matchcontinue;
end vararraySetnth;

public function vararrayNth
"function: vararrayNth
 author: PA
 Retrieve the n:th Var from VariableArray, index from 0..n-1.
 inputs:  (VariableArray, int /* n */)
 outputs: Var"
  input VariableArray inVariableArray;
  input Integer inInteger;
  output Var outVar;
algorithm
  outVar := matchcontinue (inVariableArray,inInteger)
    local
      Var v;
      Value n,pos,len;
      Option<Var>[:] arr;
      String ps,lens,ns;
    case (VARIABLE_ARRAY(numberOfElements = n,varOptArr = arr),pos)
      equation
        (pos < n) = true;
        SOME(v) = arr[pos + 1];
      then
        v;
    case (VARIABLE_ARRAY(numberOfElements = n,varOptArr = arr),pos)
      equation
        (pos < n) = true;
        NONE = arr[pos + 1];
        print("vararray_nth has NONE!!!\n");
      then
        fail();
  end matchcontinue;
end vararrayNth;

protected function replaceVar
"function: replaceVar
  author: PA
  Takes a list<Var> and a Var and replaces the
  var with the same ComponentRef in Var list with Var"
  input list<Var> inVarLst;
  input Var inVar;
  output list<Var> outVarLst;
algorithm
  outVarLst := matchcontinue (inVarLst,inVar)
    local
      DAE.ComponentRef cr1,cr2;
      DAE.Flow flow1,flow2,flowPrefix;
      list<Var> vs,vs_1;
      Var v,repl;

    case ({},_) then {};
    case ((VAR(varName = cr1,flowPrefix = flow1) :: vs),(v as VAR(varName = cr2,flowPrefix = flow2)))
      equation
        true = Exp.crefEqual(cr1, cr2);
      then
        (v :: vs);
    case ((v :: vs),(repl as VAR(varName = cr2,flowPrefix = flowPrefix)))
      equation
        vs_1 = replaceVar(vs, repl);
      then
        (v :: vs_1);
  end matchcontinue;
end replaceVar;

protected function hashComponentRef
"function: hashComponentRef
  author: PA
  Calculates a hash value for DAE.ComponentRef"
  input DAE.ComponentRef cr;
  output Integer res;
  String crstr;
algorithm
  crstr := Exp.printComponentRefStr(cr);
  res := hashString(crstr);
end hashComponentRef;

protected function hashString
"function: hashString
  author: PA
  Calculates a hash value of a string"
  input String str;
  output Integer res;
algorithm
  res := System.hash(str);
end hashString;

protected function hashChars
"function: hashChars
  author: PA
  Calculates a hash value for a list of chars"
  input list<String> inStringLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inStringLst)
    local
      Value c2,c1;
      String c;
      list<String> cs;
    case ({}) then 0;
    case ((c :: cs))
      equation
        c2 = string_char_int(c);
        c1 = hashChars(cs);
      then
        c1 + c2;
  end matchcontinue;
end hashChars;

public function getVarAt
"function: getVarAt
  author: PA
  Return variable at a given position, enumerated from 1..n"
  input Variables inVariables;
  input Integer inInteger;
  output Var outVar;
algorithm
  outVar := matchcontinue (inVariables,inInteger)
    local
      Value pos,n;
      Var v;
      VariableArray vararr;
    case (VARIABLES(varArr = vararr),n)
      equation
        pos = n - 1;
        v = vararrayNth(vararr, pos);
      then
        v;
    case (VARIABLES(varArr = vararr),n)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "DAELow.getVarAt failed to get the variable at index:" +& intString(n));
      then
        fail();
  end matchcontinue;
end getVarAt;

public function getVar
"function: getVar
  author: PA
  Return a variable(s) and its index(es) in the vector.
  The indexes is enumerated from 1..n
  Normally a variable has only one index, but in case of an array variable
  it may have several indexes and several scalar variables,
  therefore a list of variables and a list of  indexes is returned.
  inputs:  (DAE.ComponentRef, Variables)
  outputs: (Var list, int list /* indexes */)"
  input DAE.ComponentRef inComponentRef;
  input Variables inVariables;
  output list<Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inComponentRef,inVariables)
    local
      Var v;
      Value indx;
      DAE.ComponentRef cr;
      Variables vars;
      list<Value> indxs;
      list<Var> vLst;

    case (cr,vars)
      equation
        (v,indx) = getVar2(cr, vars) "if scalar found, return it" ;
      then
        ({v},{indx});
    case (cr,vars) /* check if array */
      equation
        (vLst,indxs) = getArrayVar(cr, vars);
      then
        (vLst,indxs);
    /* failure
    case (cr,vars)
      equation
        Debug.fprintln("daelow", "- DAELow.getVar failed on component reference: " +& Exp.printComponentRefStr(cr));
      then
        fail();
    */
  end matchcontinue;
end getVar;

protected function getVar2
"function: getVar2
  author: PA
  Helper function to getVar, checks one scalar variable"
  input DAE.ComponentRef inComponentRef;
  input Variables inVariables;
  output Var outVar;
  output Integer outInteger;
algorithm
  (outVar,outInteger) := matchcontinue (inComponentRef,inVariables)
    local
      Value hval,hashindx,indx,indx_1,bsize,n;
      list<CrefIndex> indexes;
      Var v;
      DAE.ComponentRef cr3, cr2,cr;
      DAE.Flow flowPrefix;
      list<CrefIndex>[:] hashvec;
      list<StringIndex>[:] oldhashvec;
      VariableArray varr;
      String str;
    case (cr,VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        cr3 = Exp.convertEnumCref(cr);
        hval = hashComponentRef(cr3);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr3, indexes);
        ((v as VAR(varName = cr2, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = Exp.crefEqual(cr3, cr2);
        indx_1 = indx + 1;
      then
        (v,indx_1);
  end matchcontinue;
end getVar2;

protected function getArrayVar
"function: getArrayVar
  author: PA
  Helper function to get_var, checks one array variable.
  I.e. get_array_var(v,<vars>) will for an array v{3} return
  { v{1},v{2},v{3} }"
  input DAE.ComponentRef inComponentRef;
  input Variables inVariables;
  output list<Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inComponentRef,inVariables)
    local
      DAE.ComponentRef cr_1,cr2,cr;
      Value hval,hashindx,indx,bsize,n;
      list<CrefIndex> indexes;
      Var v;
      list<DAE.Subscript> instdims;
      DAE.Flow flowPrefix;
      list<Var> vs;
      list<Value> indxs;
      Variables vars;
      list<CrefIndex>[:] hashvec;
      list<StringIndex>[:] oldhashvec;
      VariableArray varr;
    case (cr,(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation
        cr_1 = Exp.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1))}) "one dimensional arrays" ;
        hval = hashComponentRef(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as VAR(varName = cr2, arryDim = instdims, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = Exp.crefEqual(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
    case (cr,(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))) /* two dimensional arrays */
      equation
        cr_1 = Exp.subscriptCref(cr, {DAE.INDEX(DAE.ICONST(1)),DAE.INDEX(DAE.ICONST(1))});
        hval = hashComponentRef(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as VAR(varName = cr2, arryDim = instdims, flowPrefix = flowPrefix))) = vararrayNth(varr, indx);
        true = Exp.crefEqual(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
  end matchcontinue;
end getArrayVar;

protected function getArrayVar2
"function: getArrayVar2
  author: PA
  Helper function to getArrayVar.
  Note: Only implemented for arrays of dimension 1 and 2.
  inputs:  (DAE.InstDims, /* array_inst_dims */
              DAE.ComponentRef, /* array_var_name */
              Variables)
  outputs: (Var list /* arrays scalar vars */,
              int list /* arrays scalar indxs */)"
  input DAE.InstDims inInstDims;
  input DAE.ComponentRef inComponentRef;
  input Variables inVariables;
  output list<Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm
  (outVarLst,outIntegerLst) := matchcontinue (inInstDims,inComponentRef,inVariables)
    local
      list<Value> indx_lst,indxs_1,indx_lst1,indx_lst2;
      list<list<Value>> indx_lstlst,indxs,indx_lstlst1,indx_lstlst2;
      list<list<DAE.Subscript>> subscripts_lstlst,subscripts_lstlst1,subscripts_lstlst2,subscripts;
      list<Key> scalar_crs;
      list<list<Var>> vs;
      list<Var> vs_1;
      Value i1,i2;
      DAE.ComponentRef arr_cr;
      Variables vars;
    case ({DAE.INDEX(exp = DAE.ICONST(integer = i1))},arr_cr,vars)
      equation
        indx_lst = Util.listIntRange(i1);
        indx_lstlst = Util.listMap(indx_lst, Util.listCreate);
        subscripts_lstlst = Util.listMap(indx_lstlst, Exp.intSubscripts);
        scalar_crs = Util.listMap1r(subscripts_lstlst, Exp.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
    case ({DAE.INDEX(exp = DAE.ICONST(integer = i1)),DAE.INDEX(exp = DAE.ICONST(integer = i2))},arr_cr,vars)
      equation
        indx_lst1 = Util.listIntRange(i1);
        indx_lstlst1 = Util.listMap(indx_lst1, Util.listCreate);
        subscripts_lstlst1 = Util.listMap(indx_lstlst1, Exp.intSubscripts);
        indx_lst2 = Util.listIntRange(i2);
        indx_lstlst2 = Util.listMap(indx_lst2, Util.listCreate);
        subscripts_lstlst2 = Util.listMap(indx_lstlst2, Exp.intSubscripts);
        subscripts = subscript2dCombinations(subscripts_lstlst1, subscripts_lstlst2) "make all possbible combinations to get all 2d indexes" ;
        scalar_crs = Util.listMap1r(subscripts, Exp.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
    // adrpo: cr can be of form cr.cr.cr[2].cr[3] which means that it has type dimension [2,3] but we only need to walk [3]
    case ({_,DAE.INDEX(exp = DAE.ICONST(integer = i1))},arr_cr,vars)
      equation
        // see if cr contains ANY array dimensions. if it doesn't this case is not valid!
        true = Exp.crefHaveSubs(arr_cr);
        indx_lst = Util.listIntRange(i1);
        indx_lstlst = Util.listMap(indx_lst, Util.listCreate);
        subscripts_lstlst = Util.listMap(indx_lstlst, Exp.intSubscripts);
        scalar_crs = Util.listMap1r(subscripts_lstlst, Exp.subscriptCref, arr_cr);
        (vs,indxs) = Util.listMap12(scalar_crs, getVar, vars);
        vs_1 = Util.listFlatten(vs);
        indxs_1 = Util.listFlatten(indxs);
      then
        (vs_1,indxs_1);
  end matchcontinue;
end getArrayVar2;

protected function subscript2dCombinations
"function: susbscript_2d_combinations
  This function takes two lists of list of subscripts and combines them in
  all possible combinations. This is used when finding all indexes of a 2d
  array.
  For instance, subscript2dCombinations({{a},{b},{c}},{{x},{y},{z}})
  => {{a,x},{a,y},{a,z},{b,x},{b,y},{b,z},{c,x},{c,y},{c,z}}
  inputs:  (DAE.Subscript list list /* dim1 subs */,
              DAE.Subscript list list /* dim2 subs */)
  outputs: (DAE.Subscript list list)"
  input list<list<DAE.Subscript>> inExpSubscriptLstLst1;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst2;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := matchcontinue (inExpSubscriptLstLst1,inExpSubscriptLstLst2)
    local
      list<list<DAE.Subscript>> lst1,lst2,res,ss,ss2;
      list<DAE.Subscript> s1;
    case ({},_) then {};
    case ((s1 :: ss),ss2)
      equation
        lst1 = subscript2dCombinations2(s1, ss2);
        lst2 = subscript2dCombinations(ss, ss2);
        res = listAppend(lst1, lst2);
      then
        res;
  end matchcontinue;
end subscript2dCombinations;

protected function subscript2dCombinations2
  input list<DAE.Subscript> inExpSubscriptLst;
  input list<list<DAE.Subscript>> inExpSubscriptLstLst;
  output list<list<DAE.Subscript>> outExpSubscriptLstLst;
algorithm
  outExpSubscriptLstLst := matchcontinue (inExpSubscriptLst,inExpSubscriptLstLst)
    local
      list<list<DAE.Subscript>> lst1,ss2;
      list<DAE.Subscript> elt1,ss,s2;
    case (_,{}) then {};
    case (ss,(s2 :: ss2))
      equation
        lst1 = subscript2dCombinations2(ss, ss2);
        elt1 = listAppend(ss, s2);
      then
        (elt1 :: lst1);
  end matchcontinue;
end subscript2dCombinations2;

public function existsVar
"function: existsVar
  author: PA
  Return true if a variable exists in the vector"
  input DAE.ComponentRef inComponentRef;
  input Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inComponentRef,inVariables)
    local
      Value hval,hashindx,indx,bsize,n;
      list<CrefIndex> indexes;
      Var v;
      DAE.ComponentRef cr2,cr;
      list<CrefIndex>[:] hashvec;
      list<StringIndex>[:] oldhashvec;
      VariableArray varr;
      String str;
    case (cr,VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = hashComponentRef(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        ((v as VAR(varName = cr2))) = vararrayNth(varr, indx);
        true = Exp.crefEqual(cr, cr2);
      then
        true;
    case (cr,VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = hashComponentRef(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        failure((_) = vararrayNth(varr, indx));
        print("could not found variable, cr:");
        str = Exp.printComponentRefStr(cr);
        print(str);
        print("\n");
      then
        false;
    case (_,_) then false;
  end matchcontinue;
end existsVar;

public function getVarUsingName
"function: getVarUsingName
  author: lucian
  Return a variable and its index in the vector.
  The index is enumerated from 1..n"
  input String inString;
  input Variables inVariables;
  output Var outVar;
  output Integer outInteger;
algorithm
  (outVar,outInteger) := matchcontinue (inString,inVariables)
    local
      Value hval,hashindx,indx,indx_1,bsize,n;
      list<StringIndex> indexes;
      Var v;
      DAE.ComponentRef cr2,name;
      DAE.Flow flowPrefix;
      String name_str,cr;
      list<CrefIndex>[:] hashvec;
      list<StringIndex>[:] oldhashvec;
      VariableArray varr;
    case (cr,VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        hval = hashString(cr);
        hashindx = intMod(hval, bsize);
        indexes = oldhashvec[hashindx + 1];
        indx = getVarUsingName2(cr, indexes);
        ((v as VAR(varName = cr2))) = vararrayNth(varr, indx);
        name_str = Exp.printComponentRefStr(cr2);
        true = stringEqual(name_str, cr);
        indx_1 = indx + 1;
      then
        (v,indx_1);
  end matchcontinue;
end getVarUsingName;

public function setVarKind
"function setVarKind
  author: PA
  Sets the VarKind of a variable"
  input Var inVar;
  input VarKind inVarKind;
  output Var outVar;
algorithm
  outVar := matchcontinue (inVar,inVarKind)
    local
      DAE.ComponentRef cr;
      VarKind kind,new_kind;
      DAE.VarDirection dir;
      Type tp;
      Option<DAE.Exp> bind,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      Value i;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case (VAR(varName = cr,
              varKind = kind,
              varDirection = dir,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              index = i,
              source = source,
              values = attr,
              comment = comment,
              flowPrefix = flowPrefix,
              streamPrefix = streamPrefix),new_kind)
    then VAR(cr,new_kind,dir,tp,bind,v,dim,i,source,attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end setVarKind;

protected function getVar3
"function: getVar3
  author: PA
  Helper function to getVar"
  input DAE.ComponentRef inComponentRef;
  input list<CrefIndex> inCrefIndexLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inComponentRef,inCrefIndexLst)
    local
      DAE.ComponentRef cr,cr2;
      Value v,res;
      list<CrefIndex> vs;
    case (cr,{})
      equation
        //Debug.fprint("failtrace", "-DAELow.getVar3 failed on:" +& Exp.printComponentRefStr(cr) +& "\n");
      then
        fail();
    case (cr,(CREFINDEX(cref = cr2,index = v) :: _))
      equation
        true = Exp.crefEqual(cr, cr2);
      then
        v;
    case (cr,(v :: vs))
      local CrefIndex v;
      equation
        res = getVar3(cr, vs);
      then
        res;
  end matchcontinue;
end getVar3;

protected function getVarUsingName2
"function: getVarUsingName2
  author: PA
  Helper function to getVarUsingName"
  input String inString;
  input list<StringIndex> inStringIndexLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inString,inStringIndexLst)
    local
      String cr,cr2;
      Value v,res;
      list<StringIndex> vs;
    case (cr,(STRINGINDEX(str = cr2,index = v) :: _))
      equation
        true = stringEqual(cr, cr2);
      then
        v;
    case (cr,(v :: vs))
      local StringIndex v;
      equation
        res = getVarUsingName2(cr, vs);
      then
        res;
  end matchcontinue;
end getVarUsingName2;

protected function deleteVar
"function: deleteVar
  author: PA
  Deletes a variable from Variables. This is an expensive operation
  since we need to create a new binary tree with new indexes as well
  as a new compacted vector of variables."
  input DAE.ComponentRef inComponentRef;
  input Variables inVariables;
  output Variables outVariables;
algorithm
  outVariables := matchcontinue (inComponentRef,inVariables)
    local
      list<Var> varlst,varlst_1;
      Variables newvars,newvars_1;
      DAE.ComponentRef cr;
      list<CrefIndex>[:] hashvec;
      list<StringIndex>[:] oldhashvec;
      VariableArray varr;
      Value bsize,n;
    case (cr,VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation
        varlst = vararrayList(varr);
        varlst_1 = deleteVar2(cr, varlst);
        newvars = emptyVars();
        newvars_1 = addVars(varlst_1, newvars);
      then
        newvars_1;
  end matchcontinue;
end deleteVar;

protected function deleteVar2
"function: deleteVar2
  author: PA
  Helper function to deleteVar.
  Deletes the var named DAE.ComponentRef from the Variables list."
  input DAE.ComponentRef inComponentRef;
  input list<Var> inVarLst;
  output list<Var> outVarLst;
algorithm
  outVarLst := matchcontinue (inComponentRef,inVarLst)
    local
      DAE.ComponentRef cr1,cr2;
      list<Var> vs,vs_1;
      Var v;
    case (_,{}) then {};
    case (cr1,(VAR(varName = cr2) :: vs))
      equation
        true = Exp.crefEqual(cr1, cr2);
      then
        vs;
    case (cr1,(v :: vs))
      equation
        vs_1 = deleteVar2(cr1, vs);
      then
        (v :: vs_1);
  end matchcontinue;
end deleteVar2;

public function transposeMatrix
"function: transposeMatrix
  author: PA
  Calculates the transpose of the incidence matrix,
  i.e. which equations each variable is present in."
  input IncidenceMatrix m;
  output IncidenceMatrixT mt;
  list<list<Value>> mlst,mtlst;
algorithm
  mlst := arrayList(m);
  mtlst := transposeMatrix2(mlst);
  mt := listArray(mtlst);
end transposeMatrix;

protected function transposeMatrix2
"function: transposeMatrix2
  author: PA
  Helper function to transposeMatrix"
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst := matchcontinue (inIntegerLstLst)
    local
      Value neq;
      list<list<Value>> mt,m;
    case (m)
      equation
        neq = listLength(m);
        mt = transposeMatrix3(m, neq, 0, {});
      then
        mt;
    case (_)
      equation
        print("#transpose_matrix2 failed\n");
      then
        fail();
  end matchcontinue;
end transposeMatrix2;

protected function transposeMatrix3
"function: transposeMatrix3
  author: PA
  Helper function to transposeMatrix2"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input list<list<Integer>> inIntegerLstLst4;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst := matchcontinue (inIntegerLstLst1,inInteger2,inInteger3,inIntegerLstLst4)
    local
      Value neq_1,eqno_1,neq,eqno;
      list<list<Value>> mt_1,m,mt;
      list<Value> row;
    case (_,0,_,_) then {};
    case (m,neq,eqno,mt)
      equation
        neq_1 = neq - 1;
        eqno_1 = eqno + 1;
        mt_1 = transposeMatrix3(m, neq_1, eqno_1, mt);
        row = transposeRow(m, eqno_1, 1);
      then
        (row :: mt_1);
  end matchcontinue;
end transposeMatrix3;

public function absIncidenceMatrix
"function absIncidenceMatrix
  author: PA
  Applies absolute value to all entries in the incidence matrix.
  This can be used when e.g. der(x) and x are considered the same variable."
  input IncidenceMatrix m;
  output IncidenceMatrix res;
  list<list<Value>> lst,lst_1;
algorithm
  lst := arrayList(m);
  lst_1 := Util.listListMap(lst, int_abs);
  res := listArray(lst_1);
end absIncidenceMatrix;

public function varsIncidenceMatrix
"function: varsIncidenceMatrix
  author: PA
  Return all variable indices in the incidence
  matrix, i.e. all elements of the matrix."
  input IncidenceMatrix m;
  output list<Integer> res;
  list<list<Value>> mlst;
algorithm
  mlst := arrayList(m);
  res := Util.listFlatten(mlst);
end varsIncidenceMatrix;

protected function transposeRow
"function: transposeRow
  author: PA
  Helper function to transposeMatrix2.
  Input: IncidenceMatrix (eqn => var)
  Input: row number (variable)
  Input: iterator (start with one)
  inputs:  (int list list, int /* row */,int /* iter */)
  outputs:  int list"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inIntegerLstLst1,inInteger2,inInteger3)
    local
      Value eqn_1,varno,eqn,varno_1,eqnneg;
      list<Value> res,m;
      list<list<Value>> ms;
    case ({},_,_) then {};
    case ((m :: ms),varno,eqn)
      equation
        true = listMember(varno, m);
        eqn_1 = eqn + 1;
        res = transposeRow(ms, varno, eqn_1);
      then
        (eqn :: res);
    case ((m :: ms),varno,eqn)
      equation
        varno_1 = 0 - varno "Negative index present, state variable. list_member(varno,m) => false &" ;
        true = listMember(varno_1, m);
        eqnneg = 0 - eqn;
        eqn_1 = eqn + 1;
        res = transposeRow(ms, varno, eqn_1);
      then
        (eqnneg :: res);
    case ((m :: ms),varno,eqn)
      equation
        eqn_1 = eqn + 1 "not present at all" ;
        res = transposeRow(ms, varno, eqn_1);
      then
        res;
    case (_,_,_)
      equation
        print("-transpose_row failed\n");
      then
        fail();
  end matchcontinue;
end transposeRow;

public function dumpIncidenceMatrix
"function: dumpIncidenceMatrix
  author: PA
  Prints the incidence matrix on stdout."
  input IncidenceMatrix m;
  Value mlen;
  String mlen_str;
  list<list<Value>> m_1;
algorithm
  print("Incidence Matrix (row == equation)\n");
  print("====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
end dumpIncidenceMatrix;

public function dumpIncidenceMatrixT
"function: dumpIncidenceMatrixT
  author: PA
  Prints the transposed incidence matrix on stdout."
  input IncidenceMatrix m;
  Value mlen;
  String mlen_str;
  list<list<Value>> m_1;
algorithm
  print("Transpose Incidence Matrix (row == var)\n");
  print("=====================================\n");
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  print("number of rows: ");
  print(mlen_str);
  print("\n");
  m_1 := arrayList(m);
  dumpIncidenceMatrix2(m_1,1);
end dumpIncidenceMatrixT;

protected function dumpIncidenceMatrix2
"function: dumpIncidenceMatrix2
  author: PA
  Helper function to dumpIncidenceMatrix (+T)."
  input list<list<Integer>> inIntegerLstLst;
  input Integer rowIndex;
algorithm
  _ := matchcontinue (inIntegerLstLst,rowIndex)
    local
      list<Value> row;
      list<list<Value>> rows;
    case ({},_) then ();
    case ((row :: rows),rowIndex)
      equation
        print(intString(rowIndex));print(":");
        dumpIncidenceRow(row);
        dumpIncidenceMatrix2(rows,rowIndex+1);
      then
        ();
  end matchcontinue;
end dumpIncidenceMatrix2;

protected function dumpIncidenceRow
"function: dumpIncidenceRow
  author: PA
  Helper function to dumpIncidenceMatrix2."
  input list<Integer> inIntegerLst;
algorithm
  _ := matchcontinue (inIntegerLst)
    local
      String s;
      Value x;
      list<Value> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case ((x :: xs))
      equation
        s = intString(x);
        print(s);
        print(" ");
        dumpIncidenceRow(xs);
      then
        ();
  end matchcontinue;
end dumpIncidenceRow;

public function dumpMatching
"function: dumpMatching
  author: PA
  prints the matching information on stdout."
  input Integer[:] v;
  Value len;
  String len_str;
algorithm
  print("Matching\n");
  print("========\n");
  len := array_length(v);
  len_str := intString(len);
  print(len_str);
  print(" variables and equations\n");
  dumpMatching2(v, 0);
end dumpMatching;

protected function dumpMatching2
"function: dumpMatching2
  author: PA
  Helper function to dumpMatching."
  input Integer[:] inIntegerArray;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inIntegerArray,inInteger)
    local
      Value len,i_1,eqn,i;
      String s,s2;
      Value[:] v;
    case (v,i)
      equation
        len = array_length(v);
        i_1 = i + 1;
        (len == i_1) = true;
        s = intString(i_1);
        eqn = v[i + 1];
        s2 = intString(eqn);
        print("var ");
        print(s);
        print(" is solved in eqn ");
        print(s2);
        print("\n");
      then
        ();
    case (v,i)
      equation
        len = array_length(v);
        i_1 = i + 1;
        (len == i_1) = false;
        s = intString(i_1);
        eqn = v[i + 1];
        s2 = intString(eqn);
        print("var ");
        print(s);
        print(" is solved in eqn ");
        print(s2);
        print("\n");
        dumpMatching2(v, i_1);
      then
        ();
  end matchcontinue;
end dumpMatching2;

public function matchingAlgorithm
"function: matchingAlgorithm
  author: PA
  This function performs the matching algorithm, which is the first
  part of sorting the equations into BLT (Block Lower Triangular) form.
  The matching algorithm finds a variable that is solved in each equation.
  But to also find out which equations forms a block of equations, the
  the second algorithm of the BLT sorting: strong components
  algorithm is run.
  This function returns the updated DAE in case of index reduction has
  added equations and variables, and the incidence matrix. The variable
  assignments is returned as a vector of variable indices, as well as its
  inverse, i.e. which equation a variable is solved in as a vector of
  equation indices.
  MatchingOptions contain options given to the algorithm.
    - if index reduction should be used or not.
    - if the equation system is allowed to be under constrained or not
      which is used when generating code for initial equations.

  inputs:  (DAELow,IncidenceMatrix, IncidenceMatrixT, MatchingOptions)
  outputs: (int vector /* vector of equation indices */ ,
              int vector /* vector of variable indices */,
              DAELow,IncidenceMatrix, IncidenceMatrixT)"
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  input MatchingOptions inMatchingOptions;
  input DAE.FunctionTree inFunctions;
  output Integer[:] outIntegerArray1;
  output Integer[:] outIntegerArray2;
  output DAELow outDAELow3;
  output IncidenceMatrix outIncidenceMatrix4;
  output IncidenceMatrixT outIncidenceMatrixT5;
algorithm
  (outIntegerArray1,outIntegerArray2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5) :=
  matchcontinue (inDAELow,inIncidenceMatrix,inIncidenceMatrixT,inMatchingOptions,inFunctions)
    local
      Value nvars,neqns,memsize;
      String ns,ne;
      Assignments assign1,assign2,ass1,ass2;
      DAELow dae,dae_1,dae_2;
      Variables v,kv,v_1,kv_1,vars,exv;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      EquationArray e,re,ie,e_1,re_1,ie_1,eqns;
      MultiDimEquation[:] ae,ae1;
      DAE.Algorithm[:] al;
      EventInfo ev,einfo;
      list<Value>[:] m,mt,m_1,mt_1;
      BinTree s;
      list<Equation> e_lst,re_lst,ie_lst,e_lst_1,re_lst_1,ie_lst_1;
      list<MultiDimEquation> ae_lst,ae_lst1;
      Value[:] vec1,vec2;
      MatchingOptions match_opts;
      ExternalObjectClasses eoc;
      BinTree s;
      list<WhenClause> whenclauses;
      list<ZeroCrossing> zero_crossings;
      list<DAE.Algorithm> algs;

    case ((dae as DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,REMOVE_SIMPLE_EQN())),inFunctions)
      equation
        DAEEXT.clearDifferentiated();
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,(dae as DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc)),m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts,inFunctions,{},{});
				/* NOTE: Here it could be possible to run removeSimpleEquations again, since algebraic equations
				could potentially be removed after a index reduction has been done. However, removing equations here
				also require that e.g. zero crossings, array equations, etc. must be recalculated. */       
        s = statesDaelow(dae);
        e_lst = equationList(e);
        re_lst = equationList(re);
        ie_lst = equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,av) = removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, s); 
         EVENT_INFO(whenClauseLst=whenclauses) = ev;
        (zero_crossings) = findZeroCrossings(v,kv,e_lst,ae_lst,whenclauses,algs);
        e = listEquation(e_lst);
        re = listEquation(re_lst);
        ie = listEquation(ie_lst);
        ae = listArray(ae_lst);    
        einfo = EVENT_INFO(whenclauses,zero_crossings); 
        dae_1 = DAELOW(v,kv,exv,av,e,re,ie,ae,al,einfo,eoc);   
        m_1 = incidenceMatrix(dae_1) "Rerun matching to get updated assignments and incidence matrices
                                    TODO: instead of rerunning: find out which equations are removed
	                                  and remove those from assignments and incidence matrix." ;
        mt_1 = transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mt_1);
        memsize = nvars + nvars;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae_2,m,mt,_,_) = matchingAlgorithm2(dae_1, m_1, mt_1, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae_2,m,mt);

    case ((dae as DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,KEEP_SIMPLE_EQN())),inFunctions)
      equation
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae,m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae,m,mt);
  end matchcontinue;
end matchingAlgorithm;

protected function checkMatching
"function: checkMatching
  author: PA

  Checks that the matching is correct, i.e. that the number of variables
  is the same as the number of equations. If not, the function fails and
  prints an error message.
  If matching options indicate that underconstrained systems are ok, no
  check is performed."
  input DAELow inDAELow;
  input MatchingOptions inMatchingOptions;
algorithm
  _ := matchcontinue (inDAELow,inMatchingOptions)
    local
      Value esize,vars_size;
      EquationArray eqns;
      String esize_str,vsize_str;
    case (_,(_,ALLOW_UNDERCONSTRAINED(),_)) then ();
    case (DAELOW(orderedVars = VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = equationSize(eqns);
        (esize == vars_size) = true;
      then
        ();
    case (DAELOW(orderedVars = VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = equationSize(eqns);
        (esize < vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.UNDERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (DAELOW(orderedVars = VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = equationSize(eqns);
        (esize > vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.OVERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (_,_)
      equation
        Debug.fprint("failtrace", "- DAELow.checkMatching failed\n");
      then
        fail();
  end matchcontinue;
end checkMatching;

protected function assignmentsVector
"function: assignmentsVector
  author: PA
  Converts Assignments to vector of int elements"
  input Assignments inAssignments;
  output Integer[:] outIntegerArray;
algorithm
  outIntegerArray := matchcontinue (inAssignments)
    local
      Value[:] newarr,newarr_1,arr;
      Value[:] vec;
      Value size;
    case (ASSIGNMENTS(actualSize = size,arrOfIndices = arr))
      equation
        newarr = fill(0, size);
        newarr_1 = Util.arrayNCopy(arr, newarr, size);
        vec = array_copy(newarr_1);
      then
        vec;
    case (_)
      equation
        print("- DAELow.assignmentsVector failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsVector;

protected function assignmentsCreate
"function: assignmentsCreate
  author: PA
  Creates an assignment array of n elements, filled with value v
  inputs:  (int /* size */, int /* memsize */, int)
  outputs: => Assignments"
  input Integer n;
  input Integer memsize;
  input Integer v;
  output Assignments outAssignments;
  list<Value> lst;
  Value[:] arr;
algorithm
  lst := Util.listFill(0, memsize);
  arr := listArray(lst) "	array_create(memsize,v) => arr &" ;
  outAssignments := ASSIGNMENTS(n,memsize,arr);
end assignmentsCreate;

protected function assignmentsSetnth
"function: assignmentsSetnth
  author: PA
  Sets the n:nt assignment Value.
  inputs:  (Assignments, int /* n */, int /* value */)
  outputs:  Assignments"
  input Assignments inAssignments1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments1,inInteger2,inInteger3)
    local
      Value[:] arr;
      Value s,ms,n,v;
    case (ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),n,v)
      equation
        arr = arrayUpdate(arr, n + 1, v);
      then
        ASSIGNMENTS(s,ms,arr);
    case (_,_,_)
      equation
        print("-assignments_setnth failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsSetnth;

protected function assignmentsExpand
"function: assignmentsExpand
  author: PA
  Expands the assignments array with n values, initialized with zero.
  inputs:  (Assignments, int /* n */)
  outputs:  Assignments"
  input Assignments inAssignments;
  input Integer inInteger;
  output Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      Assignments ass,ass_1,ass_2;
      Value n_1,n;
    case (ass,0) then ass;
    case (ass,n)
      equation
        true = n > 0;
        ass_1 = assignmentsAdd(ass, 0);
        n_1 = n - 1;
        ass_2 = assignmentsExpand(ass_1, n_1);
      then
        ass_2;
    case (ass,_)
      equation
        print("DAELow.assignmentsExpand: n should not be negative!");
      then
        fail();
  end matchcontinue;
end assignmentsExpand;

protected function assignmentsAdd
"function: assignmentsAdd
  author: PA
  Adds a value to the end of the assignments array. If memsize = actual size
  this means copying the whole array, expanding it size to fit the value
  Expansion is made by a factor 1.4. Otherwise, the element is inserted taking O(1) in
  insertion cost.
  inputs:  (Assignments, int /* value */)
  outputs:  Assignments"
  input Assignments inAssignments;
  input Integer inInteger;
  output Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      Real msr,msr_1;
      Value ms_1,s_1,ms_2,s,ms,v;
      Value[:] arr_1,arr_2,arr;

    case (ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        (s == ms) = true "Out of bounds, increase and copy." ;
        msr = intReal(ms);
        msr_1 = msr *. 0.4;
        ms_1 = realInt(msr_1);
        s_1 = s + 1;
        ms_2 = ms_1 + ms;
        arr_1 = Util.arrayExpand(ms_1, arr, 0);
        arr_2 = arrayUpdate(arr_1, s + 1, v);
      then
        ASSIGNMENTS(s_1,ms_2,arr_2);

    case (ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        arr_1 = arrayUpdate(arr, s + 1, v) "space available, increase size and insert element." ;
        s_1 = s + 1;
      then
        ASSIGNMENTS(s_1,ms,arr_1);

    case (ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        print("-assignments_add failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsAdd;

protected function matchingAlgorithm2
"function: matchingAlgorithm2
  author: PA
  This is the outer loop of the matching algorithm
  The find_path algorithm is called for each equation/variable.
  inputs:  (DAELow,IncidenceMatrix, IncidenceMatrixT
             ,int /* number of vars */
             ,int /* number of eqns */
             ,int /* current var */
             ,Assignments  /* assignments, array of eqn indices */
             ,Assignments /* assignments, array of var indices */
             ,MatchingOptions) /* options for matching alg. */
  outputs: (Assignments, /* assignments, array of equation indices */
              Assignments, /* assignments, list of variable indices */
              DAELow, IncidenceMatrix, IncidenceMatrixT)"
  input DAELow inDAELow1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Assignments inAssignments7;
  input Assignments inAssignments8;
  input MatchingOptions inMatchingOptions9;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output Assignments outAssignments1;
  output Assignments outAssignments2;
  output DAELow outDAELow3;
  output IncidenceMatrix outIncidenceMatrix4;
  output IncidenceMatrixT outIncidenceMatrixT5;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outAssignments1,outAssignments2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inAssignments7,inAssignments8,inMatchingOptions9,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      Assignments ass1_1,ass2_1,ass1,ass2,ass1_2,ass2_2;
      DAELow dae;
      list<Value>[:] m,mt;
      Value nv,nf,i,i_1,nv_1,nkv,nf_1,nvd;
      MatchingOptions match_opts;
      EquationArray eqns;
      EquationConstraints eq_cons;
      EquationReduction r_simple;
      list<Value> eqn_lst,var_lst;
      String eqn_str,var_str;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1,derivedAlgs2;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1,derivedMultiEqn2;      

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,derivedAlgs,derivedMultiEqn)
      equation
        (nv == i) = true;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,dae,m,mt,derivedAlgs,derivedMultiEqn);

    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        i_1 = i + 1;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1) = matchingAlgorithm2(dae, m, mt, nv, nf, i_1, ass1_1, ass2_1, match_opts, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,ass1,ass2,(INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        ((dae as DAELOW(VARIABLES(_,_,_,_,nv_1),VARIABLES(_,_,_,_,nkv),_,_,eqns,_,_,_,_,_,_)),m,mt,derivedAlgs1,derivedMultiEqn1) = reduceIndexDummyDer(dae, m, mt, nv, nf, i, inFunctions,derivedAlgs,derivedMultiEqn) 
        "path_found failed, Try index reduction using dummy derivatives.
	       When a constraint exist between states and index reduction is needed
	       the dummy derivative will select one of the states as a dummy state
	       (and the derivative of that state as a dummy derivative).
	       For instance, u1=u2 is a constraint between states. Choose u1 as dummy state
	       and der(u1) as dummy derivative, named der_u1. The differentiated function
	       then becomes: der_u1 = der(u2).
	       In the dummy derivative method this equation is added and the original equation
	       u1=u2 is kept. This is not the case for the original pantilides algorithm, where
	       the original equation is removed from the system." ;
        nf_1 = equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
	                                 be necessary to restart the matching, according to Bernard Bachmann. Instead one
	                                 could continue the matching as usual. This was tested (2004-11-22) and it does not
	                                 work to continue without restarting.
	                                 For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
	                                 not restarting.
	                                 2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
	                                 of the system in order to work. SO: Matching is not needed to be restarted from
	                                 scratch." ;
        nvd = nv_1 - nv;
        ass1_1 = assignmentsExpand(ass1, nvd);
        ass2_1 = assignmentsExpand(ass2, nvd);
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2) = matchingAlgorithm2(dae, m, mt, nv_1, nf_1, i, ass1_1, ass2_1, (INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs1,derivedMultiEqn1);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2);

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,_,_)
      equation
        eqn_lst = DAEEXT.getMarkedEqns() "When index reduction also fails, the model is structurally singular." ;
        var_lst = DAEEXT.getMarkedVariables();
        eqn_str = dumpMarkedEqns(dae, eqn_lst);
        var_str = dumpMarkedVars(dae, var_lst);
        Error.addMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str});
        //print("structurally singular. IM:");
        //dumpIncidenceMatrix(m);
        //print("daelow:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end matchingAlgorithm2;

protected function dumpMarkedEqns
"function: dumpMarkedEqns
  author: PA
  Dumps only the equations given as list of indexes to a string."
  input DAELow inDAELow;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString := matchcontinue (inDAELow,inIntegerLst)
    local
      String s1,s2,res;
      Value e_1,e;
      Equation eqn;
      DAELow dae;
      EquationArray eqns;
      list<Value> es;
    case (_,{}) then "";
    case ((dae as DAELOW(orderedEqs = eqns)),(e :: es))
      equation
        s1 = dumpMarkedEqns(dae, es);
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);
        s2 = equationStr(eqn);
        res = Util.stringAppendList({s2,";\n",s1});
      then
        res;
  end matchcontinue;
end dumpMarkedEqns;

protected function dumpMarkedVars
"function: dumpMarkedVars
  author: PA
  Dumps only the variable names given as list of indexes to a string."
  input DAELow inDAELow;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow,inIntegerLst)
    local
      String s1,s2,res,s3;
      Value v_1,v;
      DAE.ComponentRef cr;
      DAELow dae;
      Variables vars;
      list<Value> vs;
    case (_,{}) then "";
    case ((dae as DAELOW(orderedVars = vars)),(v :: vs))
      equation
        s1 = dumpMarkedVars(dae, vs);
        VAR(varName = cr) = getVarAt(vars, v);
        s2 = Exp.printComponentRefStr(cr);
        s3 = intString(v);
        res = Util.stringAppendList({s2,"(",s3,"), ",s1});
      then
        res;
  end matchcontinue;
end dumpMarkedVars;

protected function reduceIndexDummyDer
"function: reduceIndexDummyDer
  author: PA
  When matching fails, this function is called to try to
  reduce the index by differentiating the marked equations and
  replacing one of the variable with a dummy derivative, i.e. making
  it algebraic.
  The new DAELow is returned along with an updated incidence matrix.

  inputs: (DAELow, IncidenceMatrix, IncidenceMatrixT,
             int /* number of vars */, int /* number of eqns */, int /* i */)
  outputs: (DAELow, IncidenceMatrix, IncidenceMatrixT)"
  input DAELow inDAELow1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output DAELow outDAELow;
  output IncidenceMatrix outIncidenceMatrix;
  output IncidenceMatrixT outIncidenceMatrixT;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      list<Value> eqns,diff_eqns,eqns_1,stateindx,deqns,reqns,changedeqns;
      list<Key> states;
      DAELow dae;
      list<Value>[:] m,mt;
      Value nv,nf,stateno,i;
      DAE.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;      

    case (dae,m,mt,nv,nf,i,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        eqns = DAEEXT.getMarkedEqns();
        // print("marked equations:");print(Util.stringDelimitList(Util.listMap(eqns,intString),","));
        // print("\n");
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        // print("differentiating equations:");print(Util.stringDelimitList(Util.listMap(eqns_1,intString),","));
        // print("\n");

				// Collect the states in the equations that are singular, i.e. composing a constraint between states.
				// Note that states are collected from -all- marked equations, not only the differentiated ones.
        (states,stateindx) = statesInEqns(eqns, dae, m, mt) "" ;
        (dae,m,mt,nv,nf,deqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(dae, m, mt, nv, nf, eqns_1,inFunctions,derivedAlgs,derivedMultiEqn);
        (state,stateno) = selectDummyState(states, stateindx, dae, m, mt);
        //  print("Selected ");print(Exp.printComponentRefStr(state));print(" as dummy state\n");
        //  print(" From candidates:");print(Util.stringDelimitList(Util.listMap(states,Exp.printComponentRefStr),", "));print("\n");
        dae = propagateDummyFixedAttribute(dae, eqns_1, state, stateno);
        (dummy_der,dae) = newDummyVar(state, dae)  ;
        // print("Chosen dummy: ");print(Exp.printComponentRefStr(dummy_der));print("\n");
        reqns = eqnsForVarWithStates(mt, stateno);
        changedeqns = Util.listUnionOnTrue(deqns, reqns, int_eq);
        (dae,m,mt) = replaceDummyDer(state, dummy_der, dae, m, mt, changedeqns)
        "We need to change variables in the differentiated equations and in the equations having the dummy derivative" ;
        dae = makeAlgebraic(dae, state);
        (m,mt) = updateIncidenceMatrix(dae, m, mt, changedeqns);
        // print("new DAE:");
        // dump(dae);
        // print("new IM:");
        // dumpIncidenceMatrix(m);
      then
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,_,_,_)
      equation
        eqns = DAEEXT.getMarkedEqns();
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        es = Util.listMap(eqns_1, int_string);
        es_1 = Util.stringDelimitList(es, ", ");
        print("eqns =");print(es_1);print("\n");
        ({},_) = statesInEqns(eqns_1, dae, m, mt);
        print("no states found in equations:");
        printEquations(eqns_1, dae);
        print("differentiated equations:");
        printEquations(diff_eqns,dae);
        print("Variables :");print(Util.stringDelimitList(Util.listMap(DAEEXT.getMarkedVariables(),intString),", "));
        print("\n");
      then
        fail();

    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-reduce_index_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end reduceIndexDummyDer;

protected function propagateDummyFixedAttribute
"function: propagateDummyFixedAttribute
  author: PA
  This function takes a list of equations that are differentiated
  and the chosen dummy state.
  The fixed attribute of the selected dummy state is propagated to
  the other state. This must be done since the dummy state becomes
  an algebraic state which has fixed = false by default.
  For example consider the equations:
  s1 = b;
  b=2c;
  c = s2;
  if s2 is selected as dummy derivative and s2 has an initial equation
  i.e. fixed should be false for the state s2 (which is set by the user),
  this fixed value has to be propagated to s1 when s2 becomes a dummy
  state."
  input DAELow inDAELow;
  input list<Integer> inIntegerLst;
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  output DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow,inIntegerLst,inComponentRef,inInteger)
    local
      list<Value> eqns_1,eqns;
      list<Equation> eqns_lst;
      list<Key> crefs;
      DAE.ComponentRef state,dummy;
      Var v,v_1,v_2;
      Value indx,indx_1,dummy_no;
      Boolean dummy_fixed;
      Variables vars_1,vars,kv,ev;
      VarTransform.VariableReplacements av "alias-variables' hashtable";      
      DAELow dae;
      EquationArray e,se,ie;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      EventInfo ei;
      ExternalObjectClasses eoc;

   /* eqns dummy state */
    case ((dae as DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, equationNth, e);
        crefs = equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, Exp.crefEqual);
        state = findState(vars, crefs);
        ({v},{indx}) = getVar(dummy, vars);
        (dummy_fixed as false) = varFixed(v);
        ({v_1},{indx_1}) = getVar(state, vars);
        v_2 = setVarFixed(v_1, dummy_fixed);
        vars_1 = addVar(v_2, vars);
      then
        DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,ei,eoc);

    // Never propagate fixed=true
    case ((dae as DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, equationNth, e);
        crefs = equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, Exp.crefEqual);
        state = findState(vars, crefs);
        ({v},{indx}) = getVar(dummy, vars);
       true = varFixed(v);
      then dae;

    case (dae,_,_,_)
      equation
        Debug.fprint("failtrace", "propagate_dummy_initial_equations failed\n");
      then
        dae;

  end matchcontinue;
end propagateDummyFixedAttribute;

protected function findState
"function: findState
  author: PA
  Returns the first state from a list of component references."
  input Variables inVariables;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVariables,inExpComponentRefLst)
    local
      Var v;
      Variables vars;
      DAE.ComponentRef cr;
      list<Key> crs;

    case (vars,(cr :: crs))
      equation
        ((v :: _),_) = getVar(cr, vars);
        STATE() = varKind(v);
      then
        cr;

    case (vars,(cr :: crs))
      equation
        cr = findState(vars, crs);
      then
        cr;

  end matchcontinue;
end findState;

public function equationsCrefs
"function: equationsCrefs
  author: PA
  From a list of equations return all
  occuring variables/component references."
  input list<Equation> inEquationLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inEquationLst)
    local
      list<Key> crs1,crs2,crs3,crs,crs2_1,crs3_1;
      DAE.Exp e1,e2,e;
      list<Equation> es;
      DAE.ComponentRef cr;
      Value indx;
      list<DAE.Exp> expl,expl1,expl2;
      WhenEquation weq;
      DAE.ElementSource source "the element source";

    case ({}) then {};

    case ((EQUATION(exp = e1,scalar = e2) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e1);
        crs3 = Exp.getCrefFromExp(e2);
        crs = Util.listFlatten({crs1,crs2,crs3});
      then
        crs;

    case ((RESIDUAL_EQUATION(exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        crs;

    case ((SOLVED_EQUATION(componentRef = cr,exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        (cr :: crs);

    case ((ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: es))
      local list<list<DAE.ComponentRef>> crs2;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl, Exp.getCrefFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs = listAppend(crs1, crs2_1);
      then
        crs;

    case ((ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es))
      local list<list<DAE.ComponentRef>> crs2,crs3;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl1, Exp.getCrefFromExp);
        crs3 = Util.listMap(expl2, Exp.getCrefFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs3_1 = Util.listFlatten(crs3);
        crs = Util.listFlatten({crs1,crs2_1,crs3_1});
      then
        crs;

    case ((WHEN_EQUATION(whenEquation =
           WHEN_EQ(index = indx,left = cr,right = e,elsewhenPart=SOME(weq)),source = source) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e);
        crs3 = equationsCrefs({WHEN_EQUATION(weq,source)});
        crs = listAppend(crs1, listAppend(crs2, crs3));
      then
        (cr :: crs);
  end matchcontinue;
end equationsCrefs;

protected function updateIncidenceMatrix
"function: updateIncidenceMatrix
  author: PA
  Takes a daelow and the incidence matrix and its transposed
  represenation and a list of  equation indexes that needs to be updated.
  First the IncidenceMatrix is updated, i.e. the mapping from equations
  to variables. Then, by collecting all variables in the list of equations
  to update, a list of changed variables are retrieved. This is used to
  update the IncidenceMatrixT (transpose) mapping from variables to
  equations. The function returns an updated incidence matrix.
  inputs:  (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, IncidenceMatrixT)"
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  input list<Integer> inIntegerLst;
  output IncidenceMatrix outIncidenceMatrix;
  output IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inDAELow,inIncidenceMatrix,inIncidenceMatrixT,inIntegerLst)
    local
      list<Value>[:] m_1,mt_1,m,mt;
      list<list<Value>> changedvars;
      list<Value> changedvars_1,eqns;
      DAELow dae;

    case (dae,m,mt,eqns)
      equation
        (m_1,changedvars) = updateIncidenceMatrix2(dae, m, eqns);
        changedvars_1 = Util.listFlatten(changedvars);
        mt_1 = updateTransposedMatrix(changedvars_1, m_1, mt);
      then
        (m_1,mt_1);

    case (dae,m,mt,eqns)
      equation
        print("- DAELow.updateIncidenceMatrix failed\n");
      then
        fail();
  end matchcontinue;
end updateIncidenceMatrix;

protected function updateIncidenceMatrix2
"function: updateIncidenceMatrix2
  author: PA
  Helper function to updateIncidenceMatrix
  inputs:  (DAELow,
            IncidenceMatrix,
            int list /* list of equations to update */)
  outputs: (IncidenceMatrix, int list list /* changed vars */)"
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input list<Integer> inIntegerLst;
  output IncidenceMatrix outIncidenceMatrix;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outIncidenceMatrix,outIntegerLstLst):=
  matchcontinue (inDAELow,inIncidenceMatrix,inIntegerLst)
    local
      DAELow dae;
      list<Value>[:] m,m_1,m_2;
      Value e_1,e;
      Equation eqn;
      list<Value> row,changedvars1,eqns;
      list<list<Value>> changedvars2;
      Variables vars,knvars;
      EquationArray daeeqns,daeseqns;
      list<WhenClause> wc;

    case (dae,m,{}) then (m,{{}});

    case ((dae as DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = daeeqns,removedEqs = daeseqns,eventInfo = EVENT_INFO(whenClauseLst = wc))),m,(e :: eqns))
      equation
        e_1 = e - 1;
        eqn = equationNth(daeeqns, e_1);
        row = incidenceRow(vars, eqn,wc);
        m_1 = Util.arrayReplaceAtWithFill(row, e_1 + 1, m, {});
        changedvars1 = varsInEqn(m_1, e);
        (m_2,changedvars2) = updateIncidenceMatrix2(dae, m_1, eqns);
      then
        (m_2,(changedvars1 :: changedvars2));

    case (_,_,_)
      equation
        print("-update_incididence_matrix2 failed\n");
      then
        fail();

  end matchcontinue;
end updateIncidenceMatrix2;

protected function updateTransposedMatrix
"function: updateTransposedMatrix
  author: PA
  Takes a list of variables and the transposed
  IncidenceMatrix, and updates the variable rows.
  inputs:  (int list /* var list */,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs:  IncidenceMatrixT"
  input list<Integer> inIntegerLst;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output IncidenceMatrixT outIncidenceMatrixT;
algorithm
  outIncidenceMatrixT:=
  matchcontinue (inIntegerLst,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<Value>[:] m,mt,mt_1,mt_2;
      list<list<Value>> mlst;
      list<Value> row_1,vars;
      Value v_1,v;
    case ({},m,mt) then mt;
    case ((v :: vars),m,mt)
      equation
        mlst = arrayList(m);
        row_1 = transposeRow(mlst, v, 1);
        v_1 = v - 1;
        mt_1 = Util.arrayReplaceAtWithFill(row_1, v_1 + 1, mt, {});
        mt_2 = updateTransposedMatrix(vars, m, mt_1);
      then
        mt_2;
    case (_,_,_)
      equation
        print("DAELow.updateTransposedMatrix failed\n");
      then
        fail();
  end matchcontinue;
end updateTransposedMatrix;

public function makeAllStatesAlgebraic
"function: makeAllStatesAlgebraic
  author: PA
  This function makes all states of a DAELow algebraic.
  Is used when solving an initial value problem, since
  states are just an algebraic variable in that case."
  input DAELow inDAELow;
  output DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<Var> var_lst,var_lst_1;
      Variables vars_1,vars,knvar,evar;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      EquationArray eqns,reqns,ieqns;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      EventInfo ev;
      ExternalObjectClasses eoc;
    case (DAELOW(vars,knvar,evar,av,eqns,reqns,ieqns,ae,al,ev,eoc))
      equation
        var_lst = varList(vars);
        var_lst_1 = makeAllStatesAlgebraic2(var_lst);
        vars_1 = listVar(var_lst_1);
      then
        DAELOW(vars_1,knvar,evar,av,eqns,reqns,ieqns,ae,al,ev,eoc);
  end matchcontinue;
end makeAllStatesAlgebraic;

protected function makeAllStatesAlgebraic2
"function: makeAllStatesAlgebraic2
  author: PA
  Helper function to makeAllStatesAlgebraic"
  input list<Var> inVarLst;
  output list<Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<Var> vs_1,vs;
      DAE.ComponentRef cr;
      DAE.VarDirection d;
      Type t;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      Value idx;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Var v;

    case ({}) then {};

    case ((VAR(varName = cr,
               varKind = STATE(),
               varDirection = d,
               varType = t,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               index = idx,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (VAR(cr,VARIABLE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: vs_1);

    case ((v :: vs))
      equation
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (v :: vs_1);
  end matchcontinue;
end makeAllStatesAlgebraic2;

protected function makeAlgebraic
"function: makeAlgebraic
  author: PA
  Make the variable a dummy derivative, i.e.
  change varkind from STATE to DUMMY_STATE.
  inputs:  (DAELow, DAE.ComponentRef /* state */)
  outputs: (DAELow) = "
  input DAELow inDAELow;
  input DAE.ComponentRef inComponentRef;
  output DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow,inComponentRef)
    local
      DAE.ComponentRef cr;
      VarKind kind;
      DAE.VarDirection d;
      Type t;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      Value idx;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Value> indx;
      Variables vars_1,vars,kv,ev;
      VarTransform.VariableReplacements av "alias variables' hashtale";
      EquationArray e,se,ie;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      EventInfo wc;
      ExternalObjectClasses eoc;
      DAELow daelow, daelow_1;

    case (DAELOW(vars,kv,ev,av,e,se,ie,ae,al,wc,eoc),cr)
      equation
        ((VAR(cr,kind,d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),indx) = getVar(cr, vars);
        vars_1 = addVar(VAR(cr,DUMMY_STATE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix), vars);        
      then
        DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,wc,eoc);

    case (_,_)
      equation
        print("DAELow.makeAlgebraic failed\n");
      then
        fail();

  end matchcontinue;
end makeAlgebraic;

protected function replaceDummyDer
"function: replaceDummyDer
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with the variable dummy der.
  inputs:   (DAE.ComponentRef, /* state */
             DAE.ComponentRef, /* dummy der name */
             DAELow,
             IncidenceMatrix,
             IncidenceMatrixT,
             int list /* equations */)
  outputs:  (DAELow,
             IncidenceMatrix,
             IncidenceMatrixT)"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input DAELow inDAELow3;
  input IncidenceMatrix inIncidenceMatrix4;
  input IncidenceMatrixT inIncidenceMatrixT5;
  input list<Integer> inIntegerLst6;
  output DAELow outDAELow;
  output IncidenceMatrix outIncidenceMatrix;
  output IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inComponentRef1,inComponentRef2,inDAELow3,inIncidenceMatrix4,inIncidenceMatrixT5,inIntegerLst6)
    local
      DAE.ComponentRef state,dummy,dummyder;
      DAELow dae;
      list<Value>[:] m,mt;
      Value e_1,e;
      Equation eqn,eqn_1;
      Variables v_1,v,kv,ev;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      EquationArray eqns_1,eqns,seqns,ie,ie1;
      MultiDimEquation[:] ae,ae1,ae2,ae3;
      DAE.Algorithm[:] al,al1,al2,al3;
      EventInfo wc;
      list<Value> rest;
      ExternalObjectClasses eoc;
      list<Equation> ieLst1,ieLst;

    case (state,dummy,dae,m,mt,{}) then (dae,m,mt);

    case (state,dummyder,DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc),m,mt,(e :: rest))
      equation
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);
        ieLst = equationList(ie);
        (eqn_1,al1,ae1) = replaceDummyDer2(state, dummyder, eqn, al, ae);
        (ieLst1,al2,ae2) = replaceDummyDerEqns(ieLst,state,dummyder, al1,ae1);
        ie1 = listEquation(ieLst1);
        (eqn_1,v_1,al3,ae3) = replaceDummyDerOthers(eqn_1, v,al2,ae2);
        eqns_1 = equationSetnth(eqns, e_1, eqn_1)
         "incidence_row(v\'\',eqn\') => row\' &
	        Util.list_replaceat(row\',e\',m) => m\' &
	        transpose_matrix(m\') => mt\' &" ;
        (dae,m,mt) = replaceDummyDer(state, dummyder, DAELOW(v_1,kv,ev,av,eqns_1,seqns,ie1,ae3,al3,wc,eoc), m, mt, rest);
      then
        (dae,m,mt);

    case (_,_,_,_,_,_)
      equation
        print("-replace_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end replaceDummyDer;

protected function replaceDummyDer2
"function: replaceDummyDer2
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with dummyDer variable in equation"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input Equation inEquation3;
  input DAE.Algorithm[:] inAlgs;
  input MultiDimEquation[:] inMultiDimEquationArray;
  output Equation outEquation;
  output DAE.Algorithm[:] outAlgs;
  output MultiDimEquation[:] outMultiDimEquationArray;
algorithm
  (outEquation,outAlgs,outMultiDimEquationArray) := matchcontinue (inComponentRef1,inComponentRef2,inEquation3,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp dercall,e1_1,e2_1,e1,e2;
      DAE.ComponentRef st,dummyder,cr;
      Value ds,indx,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      Equation res;
      WhenEquation elsepartRes;
      WhenEquation elsepart;
      DAE.ElementSource source,source1;
      DAE.Algorithm[:] algs;
      MultiDimEquation[:] ae,ae1;
      list<Integer> dimSize;
    case (st,dummyder,EQUATION(exp = e1,scalar = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Exp.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (EQUATION(e1_1,e2_1,source),inAlgs,ae);
    case (st,dummyder,ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (expl1,_) = Exp.replaceListExp(expl, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        i = ds+1;
        MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Exp.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));    
        ae1 = arrayUpdate(ae,i,MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (ARRAY_EQUATION(ds,expl1,source),inAlgs,ae1);  /* array equation */
    case (st,dummyder,ALGORITHM(index = indx,in_ = in_,out = out,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (in_1,_) = Exp.replaceListExp(in_, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));        
        (out1,_) = Exp.replaceListExp(out, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));  
        algs = replaceDummyDerAlgs(indx,inAlgs,dercall, DAE.CREF(dummyder,DAE.ET_REAL()));     
      then (ALGORITHM(indx,in_1,out1,source),algs,ae);  /* Algorithms */
    case (st,dummyder,WHEN_EQUATION(whenEquation =
          WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=NONE),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        res = WHEN_EQUATION(WHEN_EQ(i,cr,e1_1,NONE),source);
      then
        (res,inAlgs,ae);

    case (st,dummyder,WHEN_EQUATION(whenEquation =
          WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (WHEN_EQUATION(elsepartRes,source),algs,ae1) = replaceDummyDer2(st,dummyder, WHEN_EQUATION(elsepart,source),inAlgs,ae);
        res = WHEN_EQUATION(WHEN_EQ(i,cr,e1_1,SOME(elsepartRes)),source);
      then
        (res,algs,ae1);
    case (st,dummyder,COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Exp.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Exp.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (COMPLEX_EQUATION(i,e1_1,e2_1,source),inAlgs,ae);
     case (_,_,_,_,_)
      equation
        print("-DAELow.replaceDummyDer2 failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDer2;

protected function replaceDummyDerAlgs
  input Integer inIndex;
  input DAE.Algorithm[:] inAlgs;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output DAE.Algorithm[:] outAlgs;  
algorithm
  outAlgs:=
  matchcontinue (inIndex,inAlgs,inExp2,inExp3)
    local  
      DAE.Algorithm[:] algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
  case (inIndex,inAlgs,inExp2,inExp3)
    equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        statementLst1 = replaceDummyDerAlgs1(statementLst,inExp2,inExp3); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));   
    then
      algs;
  end matchcontinue;      
end replaceDummyDerAlgs;

protected function replaceDummyDerAlgs1
  input list<DAE.Statement> inStatementLst;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output list<DAE.Statement> outStatementLst;  
algorithm
  outStatementLst:=
  matchcontinue (inStatementLst,inExp2,inExp3)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      DAE.ElementSource source;
  case ({},_,_) then {};
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Exp.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN(t,e1,e_1,source)::st);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (elst1,_) = Exp.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (DAE.CREF(componentRef = cr1),_) = Exp.replaceExp(DAE.CREF(cr,DAE.ET_REAL()),inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inExp2,inExp3)
    equation
       (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
       stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
       else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
       st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        {s1} = replaceDummyDerAlgs1({s},inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Exp.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSERT(e1,e_1,source)::st);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TERMINATE(e1,source)::st);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Exp.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_REINIT(e1,e_1,source)::st);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_NORETCALL(e1,source)::st);
  case (DAE.STMT_RETURN(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_RETURN(source)::st);
  case (DAE.STMT_BREAK(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_BREAK(source)::st);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TRY(stlst1,source)::st);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_CATCH(stlst1,source)::st);
  case (DAE.STMT_THROW(source=source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_THROW(source)::st);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_GOTO(labelName,source)::st);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_LABEL(labelName,source)::st);
  case (DAE.STMT_MATCHCASES(caseStmt=elst,source=source)::rest,inExp2,inExp3)
    equation
        (elst1,_) = Exp.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_MATCHCASES(elst1,source)::st);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs1;

protected function replaceDummyDerAlgs2
  input DAE.Else inElse;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output DAE.Else outElse;  
algorithm
  outElse:=
  matchcontinue (inElse,inExp2,inExp3)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
  case (DAE.NOELSE(),_,_) then DAE.NOELSE();
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inExp2,inExp3)
    equation
        (e1,_) = Exp.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
    then
      DAE.ELSEIF(e1,stlst1,else_1);
  case (DAE.ELSE(statementLst=stlst),inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
    then
      DAE.ELSE(stlst1);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs2;

protected function replaceDummyDerEqns
"function replaceDummyDerEqns
  author: PA
  Helper function to reduceIndexDummy<der
  replaces der(state) with dummy_der variable in list of equations."
  input list<Equation> eqns;
  input DAE.ComponentRef st;
  input DAE.ComponentRef dummyder;
  input DAE.Algorithm[:] inAlgs;
  input MultiDimEquation[:] inMultiDimEquationArray;
  output list<Equation> outEqns;
  output DAE.Algorithm[:] outAlgs;
  output MultiDimEquation[:] outMultiDimEquationArray;
algorithm
  (outEqns,outAlgs,outMultiDimEquationArray):=
  matchcontinue (eqns,st,dummyder,inAlgs,inMultiDimEquationArray)
    local
      DAE.ComponentRef st,dummyder;
      list<Equation> eqns1,eqns;
      Equation e,e1;
      DAE.Algorithm[:] algs,algs1;
      MultiDimEquation[:] ae,ae1,ae2;
    case ({},st,dummyder,inAlgs,ae) then ({},inAlgs,ae);
    case (e::eqns,st,dummyder,inAlgs,ae)
      equation
         (e1,algs,ae1) = replaceDummyDer2(st,dummyder,e,inAlgs,ae);
         (eqns1,algs1,ae2) = replaceDummyDerEqns(eqns,st,dummyder,algs,ae1);
      then
        (e1::eqns1,algs1,ae2);
  end matchcontinue;
end replaceDummyDerEqns;

protected function replaceDummyDerOthers
"function: replaceDummyDerOthers
  author: PA
  Helper function to reduceIndexDummyDer.
  This function replaces
  1. der(der_s)  with der2_s (Where der_s is a dummy state)
  2. der(der(v)) with der2_v (where v is a state)
  3. der(v)  for alg. var v with der_v
  in the Equation given as arguments. To do this it needs the Variables
  also passed as argument to the function to e.g. determine if a variable
  is a dummy variable, etc."
  input Equation inEquation;
  input Variables inVariables;
  input DAE.Algorithm[:] inAlgs;
  input MultiDimEquation[:] inMultiDimEquationArray;  
  output Equation outEquation;
  output Variables outVariables;
  output DAE.Algorithm[:] outAlgs;
  output MultiDimEquation[:] outMultiDimEquationArray;
algorithm
  (outEquation,outVariables,outAlgs,outMultiDimEquationArray):=
  matchcontinue (inEquation,inVariables,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp e1_1,e2_1,e1,e2;
      Variables vars_1,vars_2,vars_3,vars;
      Value ds,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      DAE.ComponentRef cr;
      WhenEquation elsePartRes;
      WhenEquation elsePart;
      DAE.ElementSource source,source1;
      Integer indx;
      DAE.Algorithm[:] al;
      MultiDimEquation[:] ae,ae1;
      list<Integer> dimSize;

    case (EQUATION(exp = e1,scalar = e2,source = source),vars,inAlgs,ae)
      equation
        ((e1_1,vars_1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (EQUATION(e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),vars,inAlgs,ae) 
      equation
        (expl1,vars_1) = replaceDummyDerOthersExpLst(expl,vars);
        i = ds+1;
        MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        ((e1_1,vars_2)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars_1);
        ((e2_1,vars_3)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars_2);       
        ae1 = arrayUpdate(ae,i,MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (ARRAY_EQUATION(ds,expl1,source),vars_3,inAlgs,ae1);  /* array equation */

    case (WHEN_EQUATION(whenEquation =
            WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=NONE),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars);
      then
        (WHEN_EQUATION(WHEN_EQ(i,cr,e2_1,NONE),source),vars_1,inAlgs,ae);

    case (WHEN_EQUATION(whenEquation =
            WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=SOME(elsePart)),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars);
        (WHEN_EQUATION(elsePartRes,source), vars_2,al,ae1) = replaceDummyDerOthers(WHEN_EQUATION(elsePart,source),vars_1,inAlgs,ae);
      then
        (WHEN_EQUATION(WHEN_EQ(i,cr,e2_1,SOME(elsePartRes)),source),vars_2,al,ae1);

    case (ALGORITHM(index = indx,in_ = in_,out = out,source = source),vars,inAlgs,ae)
      equation
        (in_1,vars_1) = replaceDummyDerOthersExpLst(in_, vars);
        (out1,vars_2) = replaceDummyDerOthersExpLst(out, vars_1);
        (vars_2,al) = replaceDummyDerOthersAlgs(indx,vars_1,inAlgs);     
      then (ALGORITHM(indx,in_1,out1,source),vars_2,al,ae);

   case (COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),vars,inAlgs,ae)      
      equation
        ((e1_1,vars_1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Exp.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (COMPLEX_EQUATION(i,e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (_,_,_,_)
      equation
        print("-DAELow.replaceDummyDerOthers failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDerOthers;

protected function replaceDummyDerOthersAlgs
  input Integer inIndex;
  input Variables inVariables;
  input DAE.Algorithm[:] inAlgs;
  output Variables outVariables;
  output DAE.Algorithm[:] outAlgs;
algorithm
  (outVariables,outAlgs):=
  matchcontinue (inIndex,inVariables,inAlgs)
    local
      DAE.Algorithm[:] algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
      Variables vars;
      case(inIndex,inVariables,inAlgs)
        equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        (statementLst1,vars) = replaceDummyDerOthersAlgs1(statementLst,inVariables); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));           
      then
       (vars,algs); 
  end matchcontinue;        
end replaceDummyDerOthersAlgs;

protected function replaceDummyDerOthersAlgs1
  input list<DAE.Statement> inStatementLst;  
  input Variables inVariables;
  output list<DAE.Statement> outStatementLst;  
  output Variables outVariables;
algorithm
  (outStatementLst,outVariables) :=
  matchcontinue (inStatementLst,inVariables)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      Variables vars,vars1,vars2,vars3;
      DAE.ElementSource source;
  case ({},inVariables) then ({},inVariables);
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN(t,e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (elst1,vars1) = replaceDummyDerOthersExpLst(elst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st,vars2);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((DAE.CREF(componentRef = cr1),vars1)) = Exp.traverseExp(DAE.CREF(cr,DAE.ET_REAL()),replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st,vars2);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inVariables)
    equation
       ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
       (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
       (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
       (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st,vars3);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inVariables)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        ({s1},vars2) = replaceDummyDerOthersAlgs1({s},vars1);
        (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st,vars3);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st,vars2);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSERT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TERMINATE(e1,source)::st,vars1);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Exp.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_REINIT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_NORETCALL(e1,source)::st,vars1);
  case (DAE.STMT_RETURN(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_RETURN(source)::st,vars);
  case (DAE.STMT_BREAK(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_BREAK(source)::st,vars);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TRY(stlst1,source)::st,vars1);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_CATCH(stlst1,source)::st,vars1);
  case (DAE.STMT_THROW(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_THROW(source)::st,vars);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_GOTO(labelName,source)::st,vars);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_LABEL(labelName,source)::st,vars);
  case (DAE.STMT_MATCHCASES(caseStmt=elst,source=source)::rest,inVariables)
    equation
        (elst1,vars) = replaceDummyDerOthersExpLst(elst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_MATCHCASES(elst1,source)::st,vars1);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs1;

protected function replaceDummyDerOthersAlgs2
  input DAE.Else inElse;  
  input Variables inVariables;
  output DAE.Else outElse; 
  output Variables outVariables; 
algorithm
  (outElse,outVariables):=
  matchcontinue (inElse,inVariables)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
      Variables vars,vars1,vars2;
  case (DAE.NOELSE(),inVariables) then (DAE.NOELSE(),inVariables);
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inVariables)
    equation
        ((e1,vars)) = Exp.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
    then
      (DAE.ELSEIF(e1,stlst1,else_1),vars2);
  case (DAE.ELSE(statementLst=stlst),inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
    then
      (DAE.ELSE(stlst1),vars);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs2;

protected function replaceDummyDerOthersExpLst
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input list<DAE.Exp> inExpLst;
  input Variables inVariables;
  output list<DAE.Exp> outExpLst;
  output Variables outVariables;
algorithm
  (outExpLst,outVariables) := matchcontinue (inExpLst,inVariables)
  local 
    list<DAE.Exp> rest,elst;
    DAE.Exp e,e1;
    Variables vars,vars1,vars2;
    case ({},vars) then ({},vars); 
    case (e::rest,vars)
      equation
        ((e1,vars1)) = Exp.traverseExp(e,replaceDummyDerOthersExp,vars);
        (elst,vars2) = replaceDummyDerOthersExpLst(rest,vars1);
      then
       (e1::elst,vars2); 
  end matchcontinue;       
end replaceDummyDerOthersExpLst;

protected function replaceDummyDerOthersExp
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input tuple<DAE.Exp,Variables> inExp;
  output tuple<DAE.Exp,Variables> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      Variables vars,vars_1;
      DAE.VarDirection a;
      Type b;
      Option<DAE.Exp> c;
      Option<Values.Value> d;
      Value g;
      DAE.ComponentRef dummyder,dummyder_1,cr;
      DAE.ElementSource source "the source of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),vars))
      local list<DAE.Subscript> e;
      equation
        ((VAR(_,STATE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        dummyder = crefPrefixDer(cr);
        dummyder = crefPrefixDer(dummyder);
        vars_1 = addVar(VAR(dummyder, DUMMY_DER(), a, b, NONE, NONE, e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((VAR(_,DUMMY_DER(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars) "der(der_s)) der_s is dummy var => der_der_s" ;
        dummyder = crefPrefixDer(cr);
        vars_1 = addVar(VAR(dummyder, DUMMY_DER(), a, b, NONE, NONE, e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((VAR(_,VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(cr, vars) "der(v) v is alg var => der_v" ;
        dummyder = crefPrefixDer(cr);
        vars_1 = addVar(VAR(dummyder, DUMMY_DER(), a, b, NONE, NONE, e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((e,vars)) then ((e,vars));

  end matchcontinue;
end replaceDummyDerOthersExp;

public function varEqual
"function: varEqual
  author: PA
  Returns true if two Vars are equal."
  input Var inVar1;
  input Var inVar2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar1,inVar2)
    local
      Boolean res;
      DAE.ComponentRef cr1,cr2;
    case (VAR(varName = cr1),VAR(varName = cr2))
      equation
        res = Exp.crefEqual(cr1, cr2) "A Var is identified by its component reference" ;
      then
        res;
  end matchcontinue;
end varEqual;

public function equationEqual "Returns true if two equations are equal"
  input Equation e1;
  input Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    local
      DAE.Exp e11,e12,e21,e22,exp1,exp2;
      Integer i1,i2;
      DAE.ComponentRef cr1,cr2;
    case (EQUATION(exp = e11,scalar = e12),
          EQUATION(exp = e21, scalar = e22))
      equation
        res = boolAnd(Exp.expEqual(e11,e21),Exp.expEqual(e12,e22));
      then res;

    case(ARRAY_EQUATION(index = i1),
         ARRAY_EQUATION(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case(SOLVED_EQUATION(componentRef = cr1,exp = exp1),
         SOLVED_EQUATION(componentRef = cr2,exp = exp2))
      equation
        res = boolAnd(Exp.crefEqual(cr1,cr2),Exp.expEqual(exp1,exp2));
      then res;

    case(RESIDUAL_EQUATION(exp = exp1),
         RESIDUAL_EQUATION(exp = exp2))
      equation
        res = Exp.expEqual(exp1,exp2);
      then res;

    case(ALGORITHM(index = i1),
         ALGORITHM(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case (WHEN_EQUATION(whenEquation = WHEN_EQ(index = i1)),
          WHEN_EQUATION(whenEquation = WHEN_EQ(index = i2)))
      equation
        res = intEq(i1,i2);
      then res;

    case(_,_) then false;

  end matchcontinue;
end equationEqual;

protected function newDummyVar
"function: newDummyVar
  author: PA
  This function creates a new variable named
  der+<varname> and adds it to the dae."
  input DAE.ComponentRef inComponentRef;
  input DAELow inDAELow;
  output DAE.ComponentRef outComponentRef;
  output DAELow outDAELow;
algorithm
  (outComponentRef,outDAELow):=
  matchcontinue (inComponentRef,inDAELow)
    local
      VarKind kind;
      DAE.VarDirection dir;
      Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      Value idx;
      DAE.ComponentRef name,dummyvar_cr,var;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Variables vars_1,vars,kv,ev;
      VarTransform.VariableReplacements av "alias-variables' hashtable";      
      EquationArray eqns,seqns,ie;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      EventInfo wc;
      ExternalObjectClasses eoc;
      Var dummyvar;

    case (var,DAELOW(vars, kv, ev, av, eqns, seqns, ie, ae, al, wc,eoc))
      equation
        ((VAR(name,kind,dir,tp,bind,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = getVar(var, vars);
        dummyvar_cr = crefPrefixDer(var);
        dummyvar = VAR(dummyvar_cr,DUMMY_DER(),dir,tp,NONE,NONE,dim,0,source,dae_var_attr,comment,flowPrefix,streamPrefix);
        /* Dummy variables are algebraic variables, hence fixed = false */
        dummyvar = setVarFixed(dummyvar,false);
        vars_1 = addVar(dummyvar, vars);
      then
        (dummyvar_cr,DAELOW(vars_1,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc));

    case (_,_)
      equation
        print("-DAELow.newDummyVar failed!\n");
      then
        fail();
  end matchcontinue;
end newDummyVar;

protected function selectDummyState
"function: selectDummyState
  author: PA
  This function is the heuristic to select among the states which one
  will be transformed into  an algebraic variable, a so called dummy state
 (dummy derivative). It should in the future consider initial values, etc.
  inputs:  (DAE.ComponentRef list, /* variable names */
            int list, /* variable numbers */
            DAELow,
            IncidenceMatrix,
            IncidenceMatrixT)
  outputs: (DAE.ComponentRef, int)"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef;
  output Integer outInteger;
algorithm
  (outComponentRef,outInteger):=
  matchcontinue (varCrefs,varIndices,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef s;
      Value sn;
      Variables vars;
      IncidenceMatrix m;
      IncidenceMatrixT mt;
      EquationArray eqns;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;

    case (varCrefs,varIndices,DAELOW(orderedVars=vars,orderedEqs = eqns),m,mt)
      equation
        prioTuples = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
        //print("priorities:");print(Util.stringDelimitList(Util.listMap(prioTuples,printPrioTuplesStr),","));print("\n");
        (s,sn) = selectMinPrio(prioTuples);
      then (s,sn);

    case ({},_,dae,_,_)
      local DAELow dae;
      equation
        print("Error, no state to select\nDAE:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end selectDummyState;

protected function printPrioTuplesStr
"Debug function for printing the priorities of state selection to a string"
  input tuple<DAE.ComponentRef,Integer,Real> prioTuples;
  output String str;
algorithm
  str := matchcontinue(prioTuples)
    case((cr,_,prio))
      local DAE.ComponentRef cr; Real prio; String s1,s2;
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = realString(prio);
        str = Util.stringAppendList({"(",s1,", ",s2,")"});
      then str;
  end matchcontinue;
end printPrioTuplesStr;

protected function selectMinPrio
"Selects the state with lowest priority. This will become a dummy state"
  input list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
  output DAE.ComponentRef s;
  output Integer sn;
algorithm
  (s,sn) := matchcontinue(tuples)
    case(tuples)
      equation
        ((s,sn,_)) = Util.listReduce(tuples,ssPrioTupleMin);
      then (s,sn);
  end matchcontinue;
end selectMinPrio;

protected function ssPrioTupleMin
"Select the minimum tuple of two tuples"
  input tuple<DAE.ComponentRef,Integer,Real> tuple1;
  input tuple<DAE.ComponentRef,Integer,Real> tuple2;
  output tuple<DAE.ComponentRef,Integer,Real> tuple3;
algorithm
  tuple3 := matchcontinue(tuple1,tuple2)
    local DAE.ComponentRef cr1,cr2;
      Integer ns1,ns2;
      Real rs1,rs2;
    case((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs1 <. rs2);
      then ((cr1,ns1,rs1));

    case ((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs2 <. rs1);
      then ((cr2,ns2,rs2));

    //exactly equal, choose first one.
    case ((cr1,ns1,rs1),(cr2,ns2,rs2)) then ((cr1,ns1,rs1));

  end matchcontinue;
end ssPrioTupleMin;

protected function calculateVarPriorities
"Calculates state selection priorities"
	input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input Variables vars;
  input EquationArray eqns;
  input IncidenceMatrix m;
  input IncidenceMatrixT mt;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := matchcontinue(varCrefs,varIndices,vars,eqns,m,mt)
  local DAE.ComponentRef varCref;
    Integer varIndx;
    Var v;
    Real prio,prio1,prio2;
    list<tuple<DAE.ComponentRef,Integer,Real>> prios;
    case({},{},_,_,_,_) then {};
    case (varCref::varCrefs,varIndx::varIndices,vars,eqns,m,mt) equation
      prios = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
      (v::_,_) = getVar(varCref,vars);
      prio1 = varStateSelectPrio(v);
      prio2 = varStateSelectHeuristicPrio(v,vars,eqns,m,mt);
      prio = prio1 +. prio2;
    then ((varCref,varIndx,prio)::prios);
  end matchcontinue;
end calculateVarPriorities;

protected function varStateSelectHeuristicPrio
"function varStateSelectHeuristicPrio
  author: PA
  A heuristic for selecting states when no stateSelect information is available.
  This heuristic is based on.
  1. If a state variable s has an equation on the form s = expr(s1,s2,...,sn) where s1..sn are states
     it should be a candiate for dummy state. Like for instance phi_rel = J1.phi-J2.phi will make phi_rel
     a candidate for dummy state whereas J1.phi and J2.phi would be candidates for states.

  2. If a state variable komponent_x.s has been selected as a dummy state then komponent_x.s2 could also
     be a dummy_state. Rationale: This will increase probability that all states belong to the same component
     which is more likely what a user expects.

  3. A priority based on the number of selectable states with the same name.
     For example if the state candidates are: m1.s, m1.v, m2.s, m2.v sd.s_rel (Two translational masses and a springdamper)
     then sd.s_rel should have lower priority than the others."
  input Var v;
  input Variables vars;
  input EquationArray eqns;
  input IncidenceMatrix m;
  input IncidenceMatrixT mt;
  output Real prio;
protected
  list<Integer> vEqns;
  DAE.ComponentRef vCr;
  Integer vindx;
  Real prio1,prio2,prio3;
algorithm
  (_,vindx::_) := getVar(varCref(v),vars); // Variable index not stored in var itself => lookup required
  vEqns := eqnsForVarWithStates(mt,vindx);
  vCr := varCref(v);
  prio1 := varStateSelectHeuristicPrio1(vCr,vEqns,vars,eqns);
  prio2 := varStateSelectHeuristicPrio2(vCr,vars);
  prio3 := varStateSelectHeuristicPrio3(vCr,vars);
  prio:= prio1 +. prio2 +. prio3;
end varStateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio3
"function varStateSelectHeuristicPrio3
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input Variables vars;
  output Real prio;
algorithm
	prio := matchcontinue(cr,vars)
	  local list<Var> varLst,sameIdentVarLst; Real c,prio;
	  case(cr,vars)
	    equation
	      varLst = varList(vars);
	      sameIdentVarLst = Util.listSelect1(varLst,cr,varHasSameLastIdent);
	      c = intReal(listLength(sameIdentVarLst));
	      prio = c *. 0.01;
	    then prio;
  end matchcontinue;
end varStateSelectHeuristicPrio3;

protected function varHasSameLastIdent
"function varHasSameLastIdent
  Helper funciton to varStateSelectHeuristicPrio3.
  Returns true if the variable has the same name (the last identifier)
  as the variable name given as second argument."
  input Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(VAR(varName=cr2 ),cr )
      equation
        id1 = Exp.crefLastIdent(cr);
        id2 = Exp.crefLastIdent(cr2);
        true = stringEqual(id1, id2);
      then true;
    case(_,_) then false;
  end matchcontinue;
end varHasSameLastIdent;


protected function varStateSelectHeuristicPrio2
"function varStateSelectHeuristicPrio2
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars)
    local
      list<Var> varLst,sameCompVarLst;
    case(cr,vars)
      equation
        varLst = varList(vars);
        sameCompVarLst = Util.listSelect1(varLst,cr,varInSameComponent);
        _::_ = Util.listSelect(sameCompVarLst,isDummyStateVar);
      then -1.0;
    case(cr,vars) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varInSameComponent
"function varInSameComponent
  Helper funciton to varStateSelectHeuristicPrio2.
  Returns true if the variable is defined in the same sub
  component as the variable name given as second argument."
  input Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(VAR(varName=cr2 ),cr )
      equation
        true = Exp.crefEqual(Exp.crefStripLastIdent(cr2),Exp.crefStripLastIdent(cr));
      then true;
    case(_,_) then false;
  end matchcontinue;
end varInSameComponent;

protected function varStateSelectHeuristicPrio1
"function varStateSelectHeuristicPrio1
  author:  PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input list<Integer> eqnLst;
  input Variables vars;
  input EquationArray eqns;
  output Real prio;
algorithm
  prio := matchcontinue(cr,eqnLst,vars,eqns)
    local Integer e; Equation eqn;
    case(cr,{},_,_) then 0.0;
    case(cr,e::eqnLst,vars,eqns)
      equation
        eqn = equationNth(eqns,e-1);
        true = isStateConstraintEquation(cr,eqn,vars);
      then -1.0;
    case(cr,_::eqnLst,vars,eqns) then varStateSelectHeuristicPrio1(cr,eqnLst,vars,eqns);
 end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function isStateConstraintEquation
"function isStateConstraintEquation
  author: PA
  Help function to varStateSelectHeuristicPrio2
  Returns true if an equation is on the form cr = expr(s1,s2...sn) for states cr, s1,s2..,sn"
  input DAE.ComponentRef cr;
  input	Equation eqn;
  input Variables vars;
  output Boolean res;
algorithm
  res := matchcontinue(cr,eqn,vars)
    local
      DAE.ComponentRef cr2;
      list<DAE.ComponentRef> crs;
      list<list<Var>> crVars;
      list<Boolean> blst;
      DAE.Exp e2;

    // s = expr(s1,..,sn)  where s1 .. sn are states
    case(cr,EQUATION(exp = DAE.CREF(cr2,_), scalar = e2),vars)
      equation
        true = Exp.crefEqual(cr,cr2);
        _::_::_ = Exp.terms(e2);
        crs = Exp.getCrefFromExp(e2);
        (crVars,_) = Util.listMap12(crs,getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,EQUATION(exp = e2, scalar = DAE.CREF(cr2,_)),vars)
      equation
        true = Exp.crefEqual(cr,cr2);
        _::_::_ = Exp.terms(e2);
        crs = Exp.getCrefFromExp(e2);
        (crVars,_) = Util.listMap12(crs,getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,eqn,vars) then false;
  end matchcontinue;
end isStateConstraintEquation;

protected function varStateSelectPrio
"function varStateSelectPrio
  Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
	input Var v;
	output Real prio;
	protected
	DAE.StateSelect ss;
algorithm
  ss := varStateSelect(v);
  prio := varStateSelectPrio2(ss);
end varStateSelectPrio;

protected function varStateSelectPrio2
"helper function to varStateSelectPrio"
	input DAE.StateSelect ss;
	output Real prio;
algorithm
	ss := matchcontinue(ss)
	  case (DAE.NEVER()) then -10.0;
	  case (DAE.AVOID()) then 0.0;
	  case (DAE.DEFAULT()) then 10.0;
	  case (DAE.PREFER()) then 50.0;
	  case (DAE.ALWAYS()) then 100.0;
	end matchcontinue;
end varStateSelectPrio2;

protected function calculateDummyStatePriorities
"function: calculateDummyStatePriority
  Calculates a priority for dummy state candidates.
  The state with lowest priority number is selected as a dummy variable.
  Heuristic parameters:
   1. States that has an initial condition is given pentalty 10.
   2. Equation s1= p  s2 with states s1 and s2 gives penalty 1 for state s1.
  The heuristic parameters are summed to get the priority number."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input list<Integer> inIntegerLst;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output list<tuple<DAE.ComponentRef, Integer, Integer>> outTplExpComponentRefIntegerIntegerLst;
algorithm
  outTplExpComponentRefIntegerIntegerLst:=
  matchcontinue (inExpComponentRefLst,inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      Value indx,prio;
      list<tuple<Key, Value, Value>> res;
      list<Key> crs;
      list<Value> indxs;
      DAELow dae;
      list<Value>[:] m,mt;
    case ({},{},_,_,_) then {};
    case ((cr :: crs),(indx :: indxs),dae,m,mt)
      equation
        (cr,indx,prio) = calculateDummyStatePriority(cr, indx, dae, m, mt);
        res = calculateDummyStatePriorities(crs, indxs, dae, m, mt);
      then
        ((cr,indx,prio) :: res);
  end matchcontinue;
end calculateDummyStatePriorities;

protected function calculateDummyStatePriority
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef1;
  output Integer outInteger2;
  output Integer outInteger3;
algorithm
  (outComponentRef1,outInteger2,outInteger3):=
  matchcontinue (inComponentRef,inInteger,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      Value indx;
      DAELow dae;
      list<Value>[:] m,mt;
    case (cr,indx,dae,m,mt) then (cr,indx,0);
  end matchcontinue;
end calculateDummyStatePriority;

protected function statesInEqns
"function: statesInEqns
  author: PA
  Helper function to reduce_index_dummy_der.
  Returns all states in the equations given as equation index list.
  inputs:  (int list /* eqns */,
              DAELow,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs: (DAE.ComponentRef list, /* name for each state */
              int list)  /* number for each state */"
  input list<Integer> inIntegerLst;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<Key> res1,res11,res1_1;
      list<Value> res2,vars2,res22,res2_1,rest;
      Value e_1,e;
      Equation eqn;
      list<Var> varlst;
      Variables vars;
      EquationArray eqns;
      list<Value>[:] m,mt;
      DAELow daelow;
    case ({},_,_,_) then ({},{});
    case ((e :: rest),daelow as DAELOW(orderedVars = vars,orderedEqs = eqns),m,mt)
      equation
        (res1,res2) = statesInEqns(rest, daelow, m, mt);
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);
        vars2 = statesInEqn(eqn, vars);
        varlst = varList(vars);
        (res11,res22) = statesInVars(varlst, vars2);
        res1_1 = listAppend(res11, res1);
        res2_1 = listAppend(res22, res2);
      then
        (res1_1,res2_1);
    case (_,_,_,_)
      equation
        print("-DAELow.statesInEqns failed\n");
      then
        fail();
  end matchcontinue;
end statesInEqns;

protected function statesInVars "function: statesInVars
  author: PA

  Helper function to states_in_eqns

  inputs:  (Var list, int list)
  outputs: (DAE.ComponentRef list, /* names of the states */
              int list /* number for each state */)
"
  input list<Var> inVarLst;
  input list<Integer> inIntegerLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inVarLst,inIntegerLst)
    local
      list<Var> vars;
      Value v_1,v;
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
      list<Key> res1;
      list<Value> res2,rest;
    case (vars,{}) then ({},{});
    case (vars,(v :: rest))
      equation
        v_1 = v - 1;
        VAR(varName = cr, flowPrefix = flowPrefix) = listNth(vars, v_1);
        (res1,res2) = statesInVars(vars, rest);
      then
        ((cr :: res1),(v :: res2));
    case (vars,(v :: rest))
      equation
        (res1,res2) = statesInVars(vars, rest);
      then
        (res1,res2);
  end matchcontinue;
end statesInVars;

protected function differentiateEqns
"function: differentiateEqns
  author: PA
  This function takes a dae, its incidence matrices and the number of
  equations an variables and a list of equation indices to
  differentiate. This is used in the index reduction algorithm
  using dummy derivatives, when all marked equations are differentiated.
  The function updates the dae, the incidence matrix and returns
  a list of indices of the differentiated equations, they are added last in
  the dae.
  inputs:  (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list) /* equations */
  outputs: (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
	          int, /* number of eqns */
	          int list /* differentiated equations */)"
  input DAELow inDAELow1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output DAELow outDAELow1;
  output IncidenceMatrix outIncidenceMatrix2;
  output IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
  output list<Integer> outIntegerLst6;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
algorithm
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5,outIntegerLst6,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      DAELow dae;
      list<Value>[:] m,mt;
      Value nv,nf,e_1,leneqns,e;
      Equation eqn,eqn_1;
      String str;
      EquationArray eqns_1,eqns,seqns,ie;
      list<Value> reqns,es;
      Variables v,kv,ev;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      MultiDimEquation[:] ae,ae1;
      DAE.Algorithm[:] al,al1;
      EventInfo wc;
      ExternalObjectClasses eoc;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
    case (dae,m,mt,nv,nf,{},_,inDerivedAlgs,inDerivedMultiEqn) then (dae,m,mt,nv,nf,{},inDerivedAlgs,inDerivedMultiEqn);
    case ((dae as DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,true) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "	print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        eqns_1 = equationAdd(eqns, eqn_1);
        leneqns = equationSize(eqns_1);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(DAELOW(v,kv,ev,av,eqns_1,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(leneqns :: (e :: reqns)),derivedAlgs1,derivedMultiEqn1);
    case ((dae as DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,false) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "	print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        leneqns = equationSize(eqns);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(DAELOW(v,kv,ev,av,eqns,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(e :: reqns),derivedAlgs1,derivedMultiEqn1);        
    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-differentiate_eqns failed\n");
      then
        fail();
  end matchcontinue;
end differentiateEqns;

public function equationAdd "function: equationAdd
  author: PA

  Adds an equation to an EquationArray.
"
  input EquationArray inEquationArray;
  input Equation inEquation;
  output EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquationArray,inEquation)
    local
      Value n_1,n,size,expandsize,expandsize_1,newsize;
      Option<Equation>[:] arr_1,arr,arr_2;
      Equation e;
      Real rsize,rexpandsize;
    case (EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(e));
      then
        EQUATION_ARRAY(n_1,size,arr_1);
    case (EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e) /* Do NOT Have space to add array elt. Expand array 1.4 times */
      equation
        (n < size) = false;
        rsize = intReal(size);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr, NONE);
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(e));
      then
        EQUATION_ARRAY(n_1,newsize,arr_2);
    case (EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e)
      equation
        print("-equation_add failed\n");
      then
        fail();
  end matchcontinue;
end equationAdd;

public function equationList "function: equationList
  author: PA

  Transform the expandable Equation array to a list of Equations.
"
  input EquationArray inEquationArray;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationArray)
    local
      Option<Equation>[:] arr;
      Equation elt;
      Value lastpos,n,size;
      list<Equation> lst;
    case (EQUATION_ARRAY(numberOfElement = 0,equOptArr = arr)) then {};
    case (EQUATION_ARRAY(numberOfElement = 1,equOptArr = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr))
      equation
        lastpos = n - 1;
        lst = equationList2(arr, 0, lastpos);
      then
        lst;
    case (_)
      equation
        print("equation_list failed\n");
      then
        fail();
  end matchcontinue;
end equationList;

public function listEquation "function: listEquation
  author: PA

  Transform the a list of Equations into an expandable Equation array.
"
  input list<Equation> lst;
  output EquationArray outEquationArray;
  Value len,size;
  Real rlen,rlen_1;
  Option<Equation>[:] optarr,eqnarr,newarr;
  list<Option<Equation>> eqn_optlst;
algorithm
  len := listLength(lst);
  rlen := intReal(len);
  rlen_1 := rlen *. 1.4;
  size := realInt(rlen_1);
  optarr := fill(NONE, size);
  eqn_optlst := Util.listMap(lst, Util.makeOption);
  eqnarr := listArray(eqn_optlst);
  newarr := Util.arrayCopy(eqnarr, optarr);
  outEquationArray := EQUATION_ARRAY(len,size,newarr);
end listEquation;

protected function equationList2 "function: equationList2
  author: PA

  Helper function to equation_list

  inputs:  (Equation option array, int /* pos */, int /* lastpos */)
  outputs: Equation list

"
  input Option<Equation>[:] inEquationOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationOptionArray1,inInteger2,inInteger3)
    local
      Equation e;
      Option<Equation>[:] arr;
      Value pos,lastpos,pos_1;
      list<Equation> res;
    case (arr,pos,lastpos)
      equation
        (pos == lastpos) = true;
        SOME(e) = arr[pos + 1];
      then
        {e};
    case (arr,pos,lastpos)
      equation
        pos_1 = pos + 1;
        SOME(e) = arr[pos + 1];
        res = equationList2(arr, pos_1, lastpos);
      then
        (e :: res);
  end matchcontinue;
end equationList2;

public function systemSize "returns the size of the dae system"
input DAELow dae;
output Integer n;
algorithm
  n := matchcontinue(dae)
  local EquationArray eqns;
    case(DAELOW(orderedEqs = eqns))
      equation
        n = equationSize(eqns);
      then n;

  end matchcontinue;
end systemSize;

public function equationSize "function: equationSize
  author: PA

  Returns the number of equations in an EquationArray, which
  corresponds to the number of equations in a system.
  NOTE: Array equations and algorithms are represented several times
  in the array so the number of elements of the array corresponds to
  the equation system size.
"
  input EquationArray inEquationArray;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inEquationArray)
    local Value n;
    case (EQUATION_ARRAY(numberOfElement = n)) then n;
  end matchcontinue;
end equationSize;

public function varsSize "function: varsSize
  author: PA

  Returns the number of variables
"
  input Variables inVariables;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVariables)
    local Value n;
    case (VARIABLES(numberOfVars = n)) then n;
  end matchcontinue;
end varsSize;

public function equationNth "function: equationNth
  author: PA

  Return the n:th equation from the expandable equation array
  indexed from 0..1.

  inputs:  (EquationArray, int /* n */)
  outputs:  Equation

"
  input EquationArray inEquationArray;
  input Integer inInteger;
  output Equation outEquation;
algorithm
  outEquation:=
  matchcontinue (inEquationArray,inInteger)
    local
      Equation e;
      Value n,pos;
      Option<Equation>[:] arr;
    case (EQUATION_ARRAY(numberOfElement = n,equOptArr = arr),pos)
      equation
        (pos < n) = true;
        SOME(e) = arr[pos + 1];
      then
        e;
    case (_,_)
      equation
        print("equation_nth failed\n");
      then
        fail();
  end matchcontinue;
end equationNth;

public function equationSetnth "function: equationSetnth
  author: PA

  Sets the nth array element of an EquationArray.
"
  input EquationArray inEquationArray;
  input Integer inInteger;
  input Equation inEquation;
  output EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquationArray,inInteger,inEquation)
    local
      Option<Equation>[:] arr_1,arr;
      Value n,size,pos;
      Equation eqn;
    case (EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),pos,eqn)
      equation
        arr_1 = arrayUpdate(arr, pos + 1, SOME(eqn));
      then
        EQUATION_ARRAY(n,size,arr_1);
  end matchcontinue;
end equationSetnth;

protected function addMarkedVars "function: addMarkedVars
  author: PA

  This function is part of the matching algorithm.

  inputs:  (DAELow,
              IncidenceMatrix,
              IncidenceMatrixT,
              int, /* number of vars */
              int, /* number of eqns */
              int list /* marked vars */)
  outputs: (DAELow,
              IncidenceMatrix,
              IncidenceMatrixT,
              int, /* number of vars */
              int  /* number of eqns */)
"
  input DAELow inDAELow1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  output DAELow outDAELow1;
  output IncidenceMatrix outIncidenceMatrix2;
  output IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
algorithm
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6)
    local
      DAELow dae;
      list<Value>[:] m,mt,nt;
      Value nv,nf,nv_1,v;
      list<Value> vs;
    case (dae,m,mt,nv,nf,{}) then (dae,m,mt,nv,nf);
    case (dae,m,nt,nv,nf,(v :: vs))
      equation
        nv_1 = nv + 1 "TODO remove variable from dae and m,mt and add der{variable} instead" ;
        DAEEXT.setV(v, nv_1);
        (dae,m,mt,nv,nf) = addMarkedVars(dae, m, nt, nv_1, nf, vs);
      then
        (dae,m,mt,nv,nf);
  end matchcontinue;
end addMarkedVars;

protected function pathFound "function: pathFound
  author: PA

  This function is part of the matching algorithm.
  It tries to find a matching for the equation index given as
  third argument, i.

  inputs:  (IncidenceMatrix, IncidenceMatrixT, int /* equation */,
               Assignments, Assignments)
  outputs: (Assignments, Assignments)
"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input Assignments inAssignments4;
  input Assignments inAssignments5;
  output Assignments outAssignments1;
  output Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      Assignments ass1_1,ass2_1,ass1,ass2;
      list<Value>[:] m,mt;
      Value i;
    case (m,mt,i,ass1,ass2)
      equation
        DAEEXT.eMark(i) "Side effect" ;
        (ass1_1,ass2_1) = assignOneInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (m,mt,i,ass1,ass2)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end pathFound;

protected function assignOneInEqn "function: assignOneInEqn
  author: PA

  Helper function to path_found.
"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input Assignments inAssignments4;
  input Assignments inAssignments5;
  output Assignments outAssignments1;
  output Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<Value> vars;
      Assignments ass1_1,ass2_1,ass1,ass2;
      list<Value>[:] m,mt;
      Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = varsInEqn(m, i);
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vars, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignOneInEqn;

protected function statesInEqn "function: statesInEqn
  author: PA
  Helper function to states_in_eqns
"
  input Equation eqn;
  input Variables vars;
  output list<Integer> res;
  Variables vars_1;
algorithm
  vars_1 := statesAsAlgebraicVars(vars);
  res := incidenceRow(vars_1, eqn,{});
end statesInEqn;

protected function statesAsAlgebraicVars "function: statesAsAlgebraicVars
  author: PA

  Return the subset of variables consisting of all states, but changed
  varkind to variable.
"
  input Variables vars;
  output Variables v1_1;
  list<Var> varlst,varlst_1;
  Variables v1,v1_1;
algorithm
  varlst := varList(vars) "Creates a new set of Variables from a Var list" ;
  varlst_1 := statesAsAlgebraicVars2(varlst);
  v1 := emptyVars();
  v1_1 := addVars(varlst_1, v1);
end statesAsAlgebraicVars;

protected function statesAsAlgebraicVars2 "function: statesAsAlgebraicVars2
  author: PA

  helper function to states_as_algebraic_vars
"
  input list<Var> inVarLst;
  output list<Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<Var> res,vs;
      DAE.ComponentRef cr;
      DAE.VarDirection a;
      Type b;
      Option<DAE.Exp> c,f;
      Option<Values.Value> d;
      list<DAE.Subscript> e;
      Value g;
      list<Absyn.Path> i;
      DAE.ElementSource source "the element source";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case {} then {};
    case ((VAR(varName = cr,
               varKind = STATE(),
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "states treated as algebraic variables" ;
      then
        (VAR(cr,VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((VAR(varName = cr,
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "other variables treated as known" ;
      then
        (VAR(cr,CONST(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((_ :: vs))
      equation
        res = statesAsAlgebraicVars2(vs);
      then
        res;
  end matchcontinue;
end statesAsAlgebraicVars2;

public function varsInEqn
"function: varsInEqn
  author: PA
  This function returns all variable indices as a list for
  a given equation, given as an equation index. (1...n)
  Negative indexes are removed.
  See also: eqnsForVar and eqnsForVarWithStates
  inputs:  (IncidenceMatrix, int /* equation */)
  outputs:  int list /* variables */"
  input IncidenceMatrix inIncidenceMatrix;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIncidenceMatrix,inInteger)
    local
      Value n_1,n,indx;
      list<Value> res,res_1;
      list<Value>[:] m;
      String s;
    case (m,n)
      equation
        n_1 = n - 1;
        res = m[n_1 + 1];
        res_1 = removeNegative(res);
      then
        res_1;
    case (_,indx)
      equation
        print("vars_in_eqn failed, indx=");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end varsInEqn;

protected function removeNegative
"function: removeNegative
  author: PA
  Removes all negative integers."
  input list<Integer> lst;
  output list<Integer> lst_1;
algorithm
  lst_1 := Util.listSelect(lst, Util.intPositive);
end removeNegative;

protected function eqnsForVar
"function: eqnsForVar
  author: PA
  This function returns all equations as a list of
  equation indices given a variable as a variable index.
  See also: eqnsForVarWithStates and varsInEqn
  inputs:  (IncidenceMatrixT, int /* variable */)
  outputs:  int list /* equations */"
  input IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIncidenceMatrixT,inInteger)
    local
      Value n_1,n,indx;
      list<Value> res,res_1;
      list<Value>[:] mt;
      String s;
    case (mt,n)
      equation
        n_1 = n - 1;
        res = mt[n_1 + 1];
        res_1 = removeNegative(res);
      then
        res_1;
    case (_,indx)
      equation
        print("eqnsForVar failed, indx=");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end eqnsForVar;

protected function eqnsForVarWithStates
"function: eqnsForVarWithStates
  author: PA
  This function returns all equations as a list of equation indices
  given a variable as a variable index, including the equations containing
  the state variable but not its derivative. This must be used to update
  equations when a state is changed to algebraic variable in index reduction
  using dummy derivatives.
  These equation indices are represented with negative index, thus all
  indices are mapped trough int_abs (absolute value).
  inputs:  (IncidenceMatrixT, int /* variable */)
  outputs:  int list /* equations */"
  input IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIncidenceMatrixT,inInteger)
    local
      Value n_1,n,indx;
      list<Value> res,res_1;
      list<Value>[:] mt;
      String s;
    case (mt,n)
      equation
        n_1 = n - 1;
        res = mt[n_1 + 1];
        res_1 = Util.listMap(res, int_abs);
      then
        res_1;
    case (_,indx)
      equation
        print("eqnsForVarWithStates failed, indx=");
        s = intString(indx);
        print(s);
        print("\n");
      then
        fail();
  end matchcontinue;
end eqnsForVarWithStates;

protected function assignFirstUnassigned
"function: assignFirstUnassigned
  author: PA
  This function assigns the first unassign variable to the equation
  given as first argument. It is part of the matching algorithm.
  inputs:  (int /* equation */,
            int list /* variables */,
            Assignments /* ass1 */,
            Assignments /* ass2 */)
  outputs: (Assignments,  /* ass1 */
            Assignments)  /* ass2 */"
  input Integer inInteger1;
  input list<Integer> inIntegerLst2;
  input Assignments inAssignments3;
  input Assignments inAssignments4;
  output Assignments outAssignments1;
  output Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inIntegerLst2,inAssignments3,inAssignments4)
    local
      Assignments ass1_1,ass2_1,ass1,ass2;
      Value i,v;
      list<Value> vs;
    case (i,(v :: vs),ass1,ass2)
      equation
        0 = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = assign(v, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (i,(v :: vs),ass1,ass2)
      equation
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignFirstUnassigned;

protected function getAssigned
"function: getAssigned
  author: PA
  returns the assigned equation for a variable.
  inputs:  (int		/* variable */,
            Assignments,	/* ass1 */
            Assignments)	/* ass2 */
  outputs:  int /* equation */"
  input Integer inInteger1;
  input Assignments inAssignments2;
  input Assignments inAssignments3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inInteger1,inAssignments2,inAssignments3)
    local
      Value v;
      Value[:] m;
    case (v,ASSIGNMENTS(arrOfIndices = m),_) then m[v];
  end matchcontinue;
end getAssigned;

protected function assign
"function: assign
  author: PA
  Assign a variable to an equation, updating both assignment lists.
  inputs: (int, /* variable */
           int, /* equation */
           Assignments, /* ass1 */
           Assignments) /* ass2 */
  outputs: (Assignments,	/* updated ass1 */
            Assignments)	/* updated ass2 */"
  input Integer inInteger1;
  input Integer inInteger2;
  input Assignments inAssignments3;
  input Assignments inAssignments4;
  output Assignments outAssignments1;
  output Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inInteger2,inAssignments3,inAssignments4)
    local
      Value v_1,e_1,v,e;
      Assignments ass1_1,ass2_1,ass1,ass2;
    case (v,e,ass1,ass2)
      equation
        v_1 = v - 1 "print \"assign \" & int_string v => vs & int_string e => es & print vs & print \" to eqn \" & print es & print \"\\n\" &" ;
        e_1 = e - 1;
        ass1_1 = assignmentsSetnth(ass1, v_1, e);
        ass2_1 = assignmentsSetnth(ass2, e_1, v);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assign;

protected function forallUnmarkedVarsInEqn
"function: forallUnmarkedVarsInEqn
  author: PA
  This function is part of the matching algorithm.
  It loops over all umarked variables in an equation.
  inputs:  (IncidenceMatrix,
            IncidenceMatrixT,
            int,
            Assignments /* ass1 */,
            Assignments /* ass2 */)
  outputs: (Assignments, Assignments)"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input Assignments inAssignments4;
  input Assignments inAssignments5;
  output Assignments outAssignments1;
  output Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<Value> vars,vars_1;
      Assignments ass1_1,ass2_1,ass1,ass2;
      list<Value>[:] m,mt;
      Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = varsInEqn(m, i);
        vars_1 = Util.listFilter(vars, isNotVMarked);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vars_1, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqn;

protected function isNotVMarked
"function: isNotVMarked
  author: PA
  This function succeds for variables that are not marked."
  input Integer i;
algorithm
  false := DAEEXT.getVMark(i);
end isNotVMarked;

protected function forallUnmarkedVarsInEqnBody
"function: forallUnmarkedVarsInEqnBody
  author: PA
  This function is part of the matching algorithm.
  It is the body of the loop over all unmarked variables.
  inputs:  (IncidenceMatrix, IncidenceMatrixT,
            int,
            int list /* var list */
            Assignments
            Assignments)
  outputs: (Assignments, Assignments)"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input list<Integer> inIntegerLst4;
  input Assignments inAssignments5;
  input Assignments inAssignments6;
  output Assignments outAssignments1;
  output Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inIntegerLst4,inAssignments5,inAssignments6)
    local
      Value assarg,i,v;
      Assignments ass1_1,ass2_1,ass1_2,ass2_2,ass1,ass2;
      list<Value>[:] m,mt;
      list<Value> vars,vs;
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        assarg = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = pathFound(m, mt, assarg, ass1, ass2);
        (ass1_2,ass2_2) = assign(v, i, ass1_1, ass2_1);
      then
        (ass1_2,ass2_2);
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqnBody;

public function dumpComponentsGraphStr
"Dumps the assignment graph used to determine strong
 components to format suitable for Mathematica"
  input Integer n;
  input IncidenceMatrix m;
  input IncidenceMatrixT mT;
  input Integer[:] ass1;
  input Integer[:] ass2;
  output String res;
algorithm
  res := matchcontinue(n,m,mT,ass1,ass2)
    case(n,m,mT,ass1,ass2)
      local list<String> lst;
      equation
      	lst = dumpComponentsGraphStr2(1,n,m,mT,ass1,ass2);
      	res = Util.stringDelimitList(lst,",");
      	res = Util.stringAppendList({"{",res,"}"});
      then res;
  end matchcontinue;
end dumpComponentsGraphStr;

protected function dumpComponentsGraphStr2 "help function"
  input Integer i;
  input Integer n;
  input IncidenceMatrix m;
  input IncidenceMatrixT mT;
  input Integer[:] ass1;
  input Integer[:] ass2;
  output list<String> lst;
algorithm
  lst := matchcontinue(i,n,m,mT,ass1,ass2)
    case(i,n,m,mT,ass1,ass2) equation
      true = (i > n);
      then {};
    case(i,n,m,mT,ass1,ass2)
      local
        list<list<Integer>> llst;
        list<Integer> eqns;
        list<String> strLst,slst;
        String str;
      equation
        eqns = reachableNodes(i, m, mT, ass1, ass2);
        llst = Util.listMap(eqns,Util.listCreate);
        llst = Util.listMap1(llst,Util.listCons,i);
        slst = Util.listMap(llst,intListStr);
        str = Util.stringDelimitList(slst,",");
        str = Util.stringAppendList({"{",str,"}"});
        strLst = dumpComponentsGraphStr2(i+1,n,m,mT,ass1,ass2);
      then str::strLst;
  end matchcontinue;
end dumpComponentsGraphStr2;

protected function intListStr "Takes a list of Integers and produces a string  on form: \"{1,2,3}\" "
  input list<Integer> lst;
  output String res;
algorithm
  res := Util.stringDelimitList(Util.listMap(lst,intString),",");
  res := Util.stringAppendList({"{",res,"}"});
end intListStr;

public function strongComponents "function: strongComponents
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4)
    local
      Value n,i;
      list<Value> stack;
      list<list<Value>> comps;
      list<Value>[:] m,mt;
      Value[:] ass1,ass2;
    case (m,mt,ass1,ass2)
      equation
        n = arrayLength(m);
        DAEEXT.initLowLink(n);
        DAEEXT.initNumber(n);
        (i,stack,comps) = strongConnectMain(m, mt, ass1, ass2, n, 0, 1, {}, {});
      then
        comps;
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "strong_components failed\n");
        Error.addMessage(Error.INTERNAL_ERROR,
          {"sorting equations(strong components failed)"});
      then
        fail();
  end matchcontinue;
end strongComponents;

protected function strongConnectMain "function: strongConnectMain
  author: PA

  Helper function to strong_components

  inputs:  (IncidenceMatrix,
              IncidenceMatrixT,
              int vector, /* Assignment */
              int vector, /* Assignment */
              int, /* n - number of equations */
              int, /* i */
              int, /* w */
              int list, /* stack */
              int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      list<Value>[:] m,mt;
      Value[:] a1,a2;
      Value n,i,w,w_1,num;
      list<Value> stack,stack_1,stack_2;
      list<list<Value>> comp,comps;
    case (m,mt,a1,a2,n,i,w,stack,comp)
      equation
        (w > n) = true;
      then
        (i,stack,comp);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      local list<list<Integer>> comps2;

      equation
        0 = DAEEXT.getNumber(w);
        (i,stack_1,comps) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        w_1 = w + 1;
        (i,stack_2,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack_1, comps);
      then
        (i,stack_2,comps);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      equation
        num = DAEEXT.getNumber(w);
        (num == 0) = false;
        w_1 = w + 1;
        (i,stack_1,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack, comps);
      then
        (i,stack_1,comps);
  end matchcontinue;
end strongConnectMain;

protected function strongConnect "function: strongConnect
  author: PA

  Helper function to strong_connect_main

  inputs:  (IncidenceMatrix, IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */ )
"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<list<Integer>> inIntegerLstLst8;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLstLst8)
    local
      Value i_1,i,v;
      list<Value> stack_1,eqns,stack_2,stack_3,comp,stack;
      list<list<Value>> comps_1,comps_2,comps;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
    case (m,mt,a1,a2,i,v,stack,comps)
      equation
        i_1 = i + 1;
        DAEEXT.setNumber(v, i_1)  ;
        DAEEXT.setLowLink(v, i_1);
        stack_1 = (v :: stack);
        eqns = reachableNodes(v, m, mt, a1, a2);
        (i_1,stack_2,comps_1) = iterateReachableNodes(eqns, m, mt, a1, a2, i_1, v, stack_1, comps);
        (i_1,stack_3,comp) = checkRoot(m, mt, a1, a2, i_1, v, stack_2);
        comps_2 = consIfNonempty(comp, comps_1);
      then
        (i_1,stack_3,comps_2);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-strong_connect failed\n");
      then
        fail();
  end matchcontinue;
end strongConnect;

protected function consIfNonempty "function: consIfNonempty
  author: PA

  Small helper function to avoid empty sublists.
  Consider moving to Util?
"
  input list<Integer> inIntegerLst;
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIntegerLst,inIntegerLstLst)
    local
      list<list<Value>> lst;
      list<Value> e;
    case ({},lst) then lst;
    case (e,lst) then (e :: lst);
  end matchcontinue;
end consIfNonempty;

protected function reachableNodes "function: reachableNodes
  author: PA

  Helper function to strong_connect.
  Returns a list of reachable nodes (equations), corresponding
  to those equations that uses the solved variable of this equation.
  The edges of the graph that identifies strong components/blocks are
  dependencies between blocks. A directed edge e = (n1,n2) means
  that n1 solves for a variable (e.g. \'a\') that is used in the equation
  of n2, i.e. the equation of n1 must be solved before the equation of n2.
"
  input Integer inInteger1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5)
    local
      Value eqn_1,var,var_1,pos,eqn;
      list<Value> reachable,reachable_1,reachable_2;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
      String eqnstr;
    case (eqn,m,mt,a1,a2)
      equation
        eqn_1 = eqn - 1;
        var = a2[eqn_1 + 1];
        var_1 = var - 1;
        reachable = mt[var_1 + 1] "Got the variable that is solved in the equation" ;
        reachable_1 = removeNegative(reachable) "in which other equations is this variable present ?" ;
        pos = Util.listPosition(eqn, reachable_1) ".. except this one" ;
        reachable_2 = listDelete(reachable_1, pos);
      then
        reachable_2;
    case (eqn,_,_,_,_)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-reachable_nodes failed, eqn: ");
        eqnstr = intString(eqn);
        Debug.fprint("failtrace", eqnstr);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end reachableNodes;

protected function iterateReachableNodes "function: iterateReachableNodes
  author: PA

  Helper function to strong_connect.

  inputs:  (int list, IncidenceMatrix, IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input list<Integer> inIntegerLst1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIntegerLst1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      Value i,lv,lw,minv,w,v,nw,nv,lowlinkv;
      list<Value> stack,ws;
      list<list<Value>> comps_1,comps_2,comps;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        0 = DAEEXT.getNumber(w);
        (i,stack,comps_1) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        lv = DAEEXT.getLowLink(v);
        lw = DAEEXT.getLowLink(w);
        minv = intMin(lv, lw);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_2) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps_1);
      then
        (i,stack,comps_2);
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        nw = DAEEXT.getNumber(w);
        nv = DAEEXT.getNumber(v);
        (nw < nv) = true;
        true = listMember(w, stack);
        lowlinkv = DAEEXT.getLowLink(v);
        minv = intMin(nw, lowlinkv);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);

    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);
    case ({},m,mt,a1,a2,i,v,stack,comps) then (i,stack,comps);
  end matchcontinue;
end iterateReachableNodes;

protected function dumpList "function: dumpList
  author: PA

  Helper function to dump.
"
  input list<Integer> l;
  input String str;
  list<String> s;
  String sl;
algorithm
  s := Util.listMap(l, int_string);
  sl := Util.stringDelimitList(s, ", ");
  print(str);
  print(sl);
  print("\n");
end dumpList;

protected function checkRoot "function: checkRoot
  author: PA

  Helper function to strong_connect.

  inputs:  (IncidenceMatrix, IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7)
    local
      Value lv,nv,i,v;
      list<Value> stack_1,comps,stack;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
    case (m,mt,a1,a2,i,v,stack)
      equation
        lv = DAEEXT.getLowLink(v);
        nv = DAEEXT.getNumber(v);
        (lv == nv) = true;
        (i,stack_1,comps) = checkStack(m, mt, a1, a2, i, v, stack, {});
      then
        (i,stack_1,comps);
    case (m,mt,a1,a2,i,v,stack) then (i,stack,{});
  end matchcontinue;
end checkRoot;

protected function checkStack "function: checkStack
  author: PA

  Helper function to check_root.

  inputs:  (IncidenceMatrix, IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list /* component list */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input IncidenceMatrix inIncidenceMatrix1;
  input IncidenceMatrixT inIncidenceMatrixT2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<Integer> inIntegerLst8;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLst8)
    local
      Value topn,vn,i,v,top;
      list<Value> stack_1,comp_1,rest,comp,stack;
      list<Value>[:] m,mt;
      Value[:] a1,a2;
    case (m,mt,a1,a2,i,v,(top :: rest),comp)
      equation
        topn = DAEEXT.getNumber(top);
        vn = DAEEXT.getNumber(v);
        (topn >= vn) = true;
        (i,stack_1,comp_1) = checkStack(m, mt, a1, a2, i, v, rest, comp);
      then
        (i,stack_1,(top :: comp_1));
    case (m,mt,a1,a2,i,v,stack,comp) then (i,stack,comp);
  end matchcontinue;
end checkStack;

public function dumpComponents "function: dumpComponents
  author: PA

  Prints the blocks of the BLT sorting on stdout.
"
  input list<list<Integer>> l;
algorithm
  print("Blocks\n");
  print("=======\n");
  dumpComponents2(l, 1);
end dumpComponents;

protected function dumpComponents2 "function: dumpComponents2
  author: PA

  Helper function to dump_components.
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inIntegerLstLst,inInteger)
    local
      Value ni,i_1,i;
      list<String> ls;
      String s;
      list<Value> l;
      list<list<Value>> lst;
    case ({},_) then ();
    case ((l :: lst),i)
      equation
        ni = DAEEXT.getLowLink(i);
        print("{");
        ls = Util.listMap(l, int_string);
        s = Util.stringDelimitList(ls, ", ");
        print(s);
        print("}\n");
        i_1 = i + 1;
        dumpComponents2(lst, i_1);
      then
        ();
  end matchcontinue;
end dumpComponents2;

public function translateDae "function: translateDae
  author: PA

  Translates the dae so variables are indexed into different arrays:
  - xd for derivatives
  - x for states
  - dummy_der for dummy derivatives
  - dummy for dummy states
  - y for algebraic variables
  - p for parameters
"
  input DAELow inDAELow;
  input Option<String> dummy;
  output DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow,dummy)
    local
      list<Var> varlst,knvarlst,extvarlst;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      list<WhenClause> wc;
      list<ZeroCrossing> zc;
      Variables vars, knvars, extVars;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      EquationArray eqns,seqns,ieqns;
      DAELow trans_dae;
      ExternalObjectClasses extObjCls;
    case (DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,EVENT_INFO(whenClauseLst = wc,zeroCrossingLst = zc),extObjCls),_)
      equation
        varlst = varList(vars);
        knvarlst = varList(knvars);
        extvarlst = varList(extVars);
        varlst = listReverse(varlst);
        knvarlst = listReverse(knvarlst);
        extvarlst = listReverse(extvarlst);
        (varlst,knvarlst,extvarlst) = calculateIndexes(varlst, knvarlst,extvarlst);
        vars = addVars(varlst, vars);
        knvars = addVars(knvarlst, knvars);
        extVars = addVars(extvarlst, extVars);
        trans_dae = DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,
          EVENT_INFO(wc,zc),extObjCls);
        Debug.fcall("dumpindxdae", dump, trans_dae);
      then
        trans_dae;
  end matchcontinue;
end translateDae;

public function addVars "function: addVars
  author: PA

  Adds a list of \'Var\' to \'Variables\'
"
  input list<Var> varlst;
  input Variables vars;
  output Variables vars_1;
  Variables vars_1;
algorithm
  vars_1 := Util.listFold(varlst, addVar, vars);
end addVars;

public function analyzeJacobian "function: analyzeJacobian
  author: PA

  Analyze the jacobian to find out if the jacobian of system of equations
  can be solved at compiletime or runtime or if it is a nonlinear system
  of equations.
"
  input DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, Equation>>> inTplIntegerIntegerEquationLstOption;
  output JacobianType outJacobianType;
algorithm
  outJacobianType:=
  matchcontinue (inDAELow,inTplIntegerIntegerEquationLstOption)
    local
      DAELow daelow;
      list<tuple<Value, Value, Equation>> jac;
    case (daelow,SOME(jac))
      equation
        true = jacobianConstant(jac);
        true = rhsConstant(daelow);
      then
        JAC_CONSTANT();
    case (daelow,SOME(jac))
      equation
        true = jacobianNonlinear(daelow, jac);
      then
        JAC_NONLINEAR();
    case (daelow,SOME(jac)) then JAC_TIME_VARYING();
    case (daelow,NONE) then JAC_NO_ANALYTIC();
  end matchcontinue;
end analyzeJacobian;

protected function rhsConstant "function: rhsConstant
  author: PA

  Determines if the right hand sides of an equation system,
  represented as a DAELow, is constant.
"
  input DAELow inDAELow;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELow)
    local
      list<Equation> eqn_lst;
      Boolean res;
      DAELow dae;
      Variables vars,knvars;
      EquationArray eqns;
    case ((dae as DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns)))
      equation
        eqn_lst = equationList(eqns);
        res = rhsConstant2(eqn_lst, dae);
      then
        res;
  end matchcontinue;
end rhsConstant;

public function getEqnsysRhsExp "function: getEqnsysRhsExp
  author: PA

  Retrieve the right hand side expression of an equation
  in an equation system, given a set of variables.

  inputs:  (DAE.Exp, Variables /* variables of the eqn sys. */)
  outputs:  DAE.Exp =
"
  input DAE.Exp inExp;
  input Variables inVariables;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inVariables)
    local
      list<DAE.Exp> term_lst,rhs_lst,rhs_lst2;
      DAE.Exp new_exp,res,exp;
      Variables vars;
    case (exp,vars)
      equation
        term_lst = Exp.allTerms(exp);
        rhs_lst = Util.listSelect1(term_lst, vars, freeFromAnyVar);
        /* A term can contain if-expressions that has branches that are on rhs and other branches that
        are on lhs*/
        rhs_lst2 = ifBranchesFreeFromVar(term_lst,vars);
        new_exp = Exp.makeSum(listAppend(rhs_lst,rhs_lst2));
        res = Exp.simplify(new_exp);
      then
        res;
    case (_,_)
      equation
        Debug.fprint("failtrace", "-get_eqnsys_rhs_exp failed\n");
      then
        fail();
  end matchcontinue;
end getEqnsysRhsExp;

public function ifBranchesFreeFromVar "Retrieves if-branches free from any of the variables passed as argument.

This is done by replacing the variables with zero."
  input list<DAE.Exp> expl;
  input Variables vars;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := matchcontinue(expl,vars)
    local DAE.Exp cond,t,f,e1,e2;
      VarTransform.VariableReplacements repl;
      DAE.Operator op;
      Absyn.Path path;
      list<DAE.Exp> expl2;
      Boolean tpl ;
      Boolean b;
      DAE.InlineType i;
      DAE.ExpType ty;
    case({},vars) then {};
    case(DAE.IFEXP(cond,t,f)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      t = ifBranchesFreeFromVar2(t,repl);
      f = ifBranchesFreeFromVar2(f,repl);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.IFEXP(cond,t,f)::expl);
    case(DAE.BINARY(e1,op,e2)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      {e1} = ifBranchesFreeFromVar({e1},vars);
      {e2} = ifBranchesFreeFromVar({e2},vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.BINARY(e1,op,e2)::expl);

    case(DAE.UNARY(op,e1)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      {e1} = ifBranchesFreeFromVar({e1},vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.UNARY(op,e1)::expl);

    case(DAE.CALL(path,expl2,tpl,b,ty,i)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      (expl2 as _::_) = ifBranchesFreeFromVar(expl2,vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.CALL(path,expl2,tpl,b,ty,i)::expl);

  case(_::expl,vars) equation
      expl = ifBranchesFreeFromVar(expl,vars);
  then expl;
  end matchcontinue;
end ifBranchesFreeFromVar;

protected function ifBranchesFreeFromVar2 "Help function to ifBranchesFreeFromVar,
replaces variables in if branches (not conditions) recursively (to include elseifs)"
  input DAE.Exp ifBranch;
  input VarTransform.VariableReplacements repl;
  output DAE.Exp outIfBranch;
algorithm
  outIfBranch := matchcontinue(ifBranch,repl)
  local DAE.Exp cond,t,f,e;
    case(DAE.IFEXP(cond,t,f),repl) equation
      t = ifBranchesFreeFromVar2(t,repl);
      f = ifBranchesFreeFromVar2(f,repl);
    then DAE.IFEXP(cond,t,f);
    case(e,repl) equation
      e = VarTransform.replaceExp(e,repl,NONE);
    then e;
  end matchcontinue;
end ifBranchesFreeFromVar2;

protected function makeZeroReplacements "Help function to ifBranchesFreeFromVar, creates replacement rules
v -> 0, for all variables"
  input Variables vars;
  output VarTransform.VariableReplacements repl;
  protected list<Var> varLst;
algorithm
  varLst := varList(vars);
  repl := Util.listFold(varLst,makeZeroReplacement,VarTransform.emptyReplacements());
end makeZeroReplacements;

protected function makeZeroReplacement "helper function to makeZeroReplacements.
Creates replacement Var-> 0"
  input Var var;
  input VarTransform.VariableReplacements repl;
  output VarTransform.VariableReplacements outRepl;
  protected
  DAE.ComponentRef cr;
algorithm
  cr :=  varCref(var);
  outRepl := VarTransform.addReplacement(repl,cr,DAE.RCONST(0.0));
end makeZeroReplacement;

public function getEquationBlock "function: getEquationBlock
  author: PA

  Returns the block the equation belongs to.
"
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger,inIntegerLstLst)
    local
      Value e;
      list<Value> block_,res;
      list<list<Value>> blocks;
    case (e,(block_ :: blocks))
      equation
        true = listMember(e, block_);
      then
        block_;
    case (e,(block_ :: blocks))
      equation
        res = getEquationBlock(e, blocks);
      then
        res;
  end matchcontinue;
end getEquationBlock;

protected function rhsConstant2 "function: rhsConstant2
  author: PA
  Helper function to rhsConstant, traverses equation list."
  input list<Equation> inEquationLst;
  input DAELow inDAELow;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inEquationLst,inDAELow)
    local
      DAE.ExpType tp;
      DAE.Exp new_exp,rhs_exp,e1,e2,e;
      Boolean res;
      list<Equation> rest;
      DAELow dae;
      Variables vars;
      Value indx_1,indx;
      list<Value> ds;
      list<DAE.Exp> expl;
      MultiDimEquation[:] arreqn;

    case ({},_) then true;
    // check rhs for for EQUATION nodes.
    case ((EQUATION(exp = e1,scalar = e2) :: rest),(dae as DAELOW(orderedVars = vars)))
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        true = Exp.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;
    // check rhs for for ARRAY_EQUATION nodes. check rhs for for RESIDUAL_EQUATION nodes.
    case ((ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: rest),(dae as DAELOW(orderedVars = vars,arrayEqs = arreqn)))
      equation
        indx_1 = indx - 1;
        MULTIDIM_EQUATION(ds,e1,e2,_) = arreqn[indx + 1];
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        true = Exp.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;

    case ((RESIDUAL_EQUATION(exp = e) :: rest),(dae as DAELOW(orderedVars = vars))) /* check rhs for for RESIDUAL_EQUATION nodes. */
      equation
        rhs_exp = getEqnsysRhsExp(e, vars);
        true = Exp.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end rhsConstant2;

protected function freeFromAnyVar "function: freeFromAnyVar
  author: PA
  Helper function to rhsConstant2
  returns true if expression does not contain
  anyof the variables passed as argument."
  input DAE.Exp inExp;
  input Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp,inVariables)
    local
      DAE.Exp e;
      list<Key> crefs;
      list<Boolean> b_lst;
      Boolean res,res_1;
      Variables vars;

    case (e,_)
      equation
        {} = Exp.getCrefFromExp(e) "Special case for expressions with no variables" ;
      then
        true;
    case (e,vars)
      equation
        crefs = Exp.getCrefFromExp(e);
        b_lst = Util.listMap1(crefs, existsVar, vars);
        res = Util.boolOrList(b_lst);
        res_1 = boolNot(res);
      then
        res_1;
    case (_,_) then true;
  end matchcontinue;
end freeFromAnyVar;

public function jacobianTypeStr "function: jacobianTypeStr
  author: PA
  Returns the jacobian type as a string, used for debugging."
  input JacobianType inJacobianType;
  output String outString;
algorithm
  outString := matchcontinue (inJacobianType)
    case JAC_CONSTANT() then "Jacobian Constant";
    case JAC_TIME_VARYING() then "Jacobian Time varying";
    case JAC_NONLINEAR() then "Jacobian Nonlinear";
    case JAC_NO_ANALYTIC() then "No analythic jacobian";
  end matchcontinue;
end jacobianTypeStr;

protected function jacobianConstant "function: jacobianConstant
  author: PA
  Checks if jacobian is constant, i.e. all expressions in each equation are constant."
  input list<tuple<Integer, Integer, Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTplIntegerIntegerEquationLst)
    local
      DAE.Exp e1,e2,e;
      list<tuple<Value, Value, Equation>> eqns;
    case ({}) then true;
    case (((_,_,EQUATION(exp = e1,scalar = e2)) :: eqns)) /* TODO: Algorithms and ArrayEquations */
      equation
        true = Exp.isConst(e1);
        true = Exp.isConst(e2);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        true = Exp.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,SOLVED_EQUATION(exp = e)) :: eqns))
      equation
        true = Exp.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (_) then false;
  end matchcontinue;
end jacobianConstant;

protected function jacobianNonlinear "function: jacobianNonlinear
  author: PA
  Check if jacobian indicates a nonlinear system.
  TODO: Algorithms and Array equations"
  input DAELow inDAELow;
  input list<tuple<Integer, Integer, Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inTplIntegerIntegerEquationLst)
    local
      DAELow daelow;
      DAE.Exp e1,e2,e;
      list<tuple<Value, Value, Equation>> xs;

    case (daelow,((_,_,EQUATION(exp = e1,scalar = e2)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e1);
        false = jacobianNonlinearExp(daelow, e2);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (daelow,((_,_,RESIDUAL_EQUATION(exp = e)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (_,{}) then false;
    case (_,_) then true;
  end matchcontinue;
end jacobianNonlinear;

protected function jacobianNonlinearExp "function: jacobianNonlinearExp
  author: PA
  Checks wheter the jacobian indicates a nonlinear system.
  This is true if the jacobian contains any of the variables
  that is solved for."
  input DAELow inDAELow;
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inExp)
    local
      list<Key> crefs;
      Boolean res;
      Variables vars;
      DAE.Exp e;
    case (DAELOW(orderedVars = vars),e)
      equation
        crefs = Exp.getCrefFromExp(e);
        res = containAnyVar(crefs, vars);
      then
        res;
  end matchcontinue;
end jacobianNonlinearExp;

protected function containAnyVar "function: containAnyVar
  author: PA
  Returns true if any of the variables given
  as ComponentRef list is among the Variables."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExpComponentRefLst,inVariables)
    local
      DAE.ComponentRef cr;
      list<Key> crefs;
      Variables vars;
      Boolean res;
    case ({},_) then false;
    case ((cr :: crefs),vars)
      equation
        (_,_) = getVar(cr, vars);
      then
        true;
    case ((_ :: crefs),vars)
      equation
        res = containAnyVar(crefs, vars);
      then
        res;
  end matchcontinue;
end containAnyVar;

public function calculateJacobian "function: calculateJacobian
  This function takes an array of equations and the variables of the equation
  and calculates the jacobian of the equations."
  input Variables inVariables;
  input EquationArray inEquationArray;
  input MultiDimEquation[:] inMultiDimEquationArray;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inVariables,inEquationArray,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,differentiateIfExp)
    local
      list<Equation> eqn_lst,eqn_lst_1;
      list<tuple<Value, Value, Equation>> jac;
      Variables vars;
      EquationArray eqns;
      MultiDimEquation[:] ae;
      list<Value>[:] m,mt;
    case (vars,eqns,ae,m,mt,differentiateIfExp)
      equation
        eqn_lst = equationList(eqns);
        eqn_lst_1 = Util.listMap(eqn_lst, equationToResidualForm);
        SOME(jac) = calculateJacobianRows(eqn_lst_1, vars, ae, m, mt,differentiateIfExp);
      then
        SOME(jac);
    case (_,_,_,_,_,_) then NONE;  /* no analythic jacobian available */
  end matchcontinue;
end calculateJacobian;

protected function calculateJacobianRows "function: calculateJacobianRows
  author: PA
  This function takes a list of Equations and a set of variables and
  calculates the jacobian expression for each variable over each equations,
  returned in a sparse matrix representation.
  For example, the equation on index e1: 3ax+5yz+ zz  given the
  variables {x,y,z} on index x1,y1,z1 gives
  {(e1,x1,3a), (e1,y1,5z), (e1,z1,5y+2z)}"
  input list<Equation> eqns;
  input Variables vars;
  input MultiDimEquation[:] ae;
  input IncidenceMatrix m;
  input IncidenceMatrixT mt;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, Equation>>> res;
algorithm
  (res,_) := calculateJacobianRows2(eqns, vars, ae, m, mt, 1,differentiateIfExp, {});
end calculateJacobianRows;

protected function calculateJacobianRows2 "function: calculateJacobianRows2
  author: PA

  Helper function to calculate_jacobian_rows
"
  input list<Equation> inEquationLst;
  input Variables inVariables;
  input MultiDimEquation[:] inMultiDimEquationArray;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  matchcontinue (inEquationLst,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      Value eqn_indx_1,eqn_indx;
      list<tuple<Value, Value, Equation>> l1,l2,res;
      Equation eqn;
      list<Equation> eqns;
      Variables vars;
      MultiDimEquation[:] ae;
      list<Value>[:] m,mt;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1,entrylst2; 
    case ({},_,_,_,_,_,_,inEntrylst) then (SOME({}),inEntrylst);
    case ((eqn :: eqns),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        eqn_indx_1 = eqn_indx + 1;
        (SOME(l1),entrylst1) = calculateJacobianRows2(eqns, vars, ae, m, mt, eqn_indx_1,differentiateIfExp,inEntrylst);
        (SOME(l2),entrylst2) = calculateJacobianRow(eqn, vars, ae, m, mt, eqn_indx,differentiateIfExp,entrylst1);
        res = listAppend(l1, l2);
      then
        (SOME(res),entrylst2);
  end matchcontinue;
end calculateJacobianRows2;

protected function calculateJacobianRow "function: calculateJacobianRow
  author: PA

  Calculates the jacobian for one equation. See calculate_jacobian_rows.

  inputs:  (Equation,
              Variables,
              MultiDimEquation array,
              IncidenceMatrix,
              IncidenceMatrixT,
              int /* eqn index */)
  outputs: ((int  int  Equation) list option)
"
  input Equation inEquation;
  input Variables inVariables;
  input MultiDimEquation[:] inMultiDimEquationArray;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  matchcontinue (inEquation,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      list<Value> var_indxs,var_indxs_1,ds;
      list<Option<Integer>> ad;
      list<tuple<Value, Value, Equation>> eqns;
      DAE.Exp e,e1,e2,new_exp;
      Variables vars;
      MultiDimEquation[:] ae;
      list<Value>[:] m,mt;
      Value eqn_indx,indx;
      list<DAE.Exp> in_,out,expl;
      Exp.Type t;
      list<DAE.Subscript> subs;   
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1;   
    // residual equations
    case (RESIDUAL_EQUATION(exp = e),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        var_indxs = varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: ascending index" ;
        SOME(eqns) = calculateJacobianRow2(e, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),inEntrylst);
    // algorithms give no jacobian
    case (ALGORITHM(index = indx,in_ = in_,out = out),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst) then (NONE,inEntrylst);
    // array equations
    case (ARRAY_EQUATION(index = indx,crefOrDerCref = expl),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        MULTIDIM_EQUATION(ds,e1,e2,_) = ae[indx + 1];
        t = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(t),e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = getArrayEquationSub(indx,ad,inEntrylst);
        new_exp = Exp.applyExpSubscripts(new_exp,subs); 
        var_indxs = varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: acsending index" ;
        SOME(eqns) = calculateJacobianRow2(new_exp, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),entrylst1);
  end matchcontinue;
end calculateJacobianRow;

public function getArrayEquationSub"function: getArrayEquationSub
  author: Frenkel TUD
  helper for calculateJacobianRow and SimCode.dlowEqToExp"
  input Integer Index;
  input list<Option<Integer>> inAD;
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inList;
  output list<DAE.Subscript> outSubs;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outList;
algorithm
  (outSubs,outList) := 
  matchcontinue (Index,inAD,inList)
    local
      Integer i,ie;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs,subs1;
      list<list<DAE.Subscript>> subslst,subslst1;
      list<tuple<Integer,list<list<DAE.Subscript>>>> rest,entrylst;
      tuple<Integer,list<list<DAE.Subscript>>> entry;
    // new entry  
    case (i,ad,{})
      equation
        subslst = arrayDimensionsToRange(ad);
        (subs::subslst1) = rangesToSubscripts(subslst);
      then
        (subs,{(i,subslst1)});
    // found last entry
    case (i,ad,(entry as (ie,{subs}))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,rest);         
    // found entry
    case (i,ad,(entry as (ie,subs::subslst))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,(ie,subslst)::rest); 
    // next entry  
    case (i,ad,(entry as (ie,subslst))::rest)
      equation
        false = intEq(i,ie);
        (subs1,entrylst) = getArrayEquationSub(i,ad,rest);
      then   
        (subs1,entry::entrylst); 
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.getArrayEquationSub failed");
      then
        fail();          
  end matchcontinue;      
end getArrayEquationSub;

protected function makeResidualEqn "function: makeResidualEqn
  author: PA
  Transforms an expression into a residual equation"
  input DAE.Exp inExp;
  output Equation outEquation;
algorithm
  outEquation := matchcontinue (inExp)
    local DAE.Exp e;
    case (e) then RESIDUAL_EQUATION(e,DAE.emptyElementSource);
  end matchcontinue;
end makeResidualEqn;

protected function calculateJacobianRow2 "function: calculateJacobianRow2
  author: PA
  Helper function to calculateJacobianRow
  Differentiates expression for each variable cref.
  inputs: (DAE.Exp,
             Variables,
             int, /* equation index */
             int list) /* var indexes */
  outputs: ((int int Equation) list option)"
  input DAE.Exp inExp;
  input Variables inVariables;
  input Integer inInteger;
  input list<Integer> inIntegerLst;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption := matchcontinue (inExp,inVariables,inInteger,inIntegerLst,differentiateIfExp)
    local
      DAE.Exp e,e_1,e_2;
      Var v;
      DAE.ComponentRef cr;
      list<tuple<Value, Value, Equation>> es;
      Variables vars;
      Value eqn_indx,vindx;
      list<Value> vindxs;

    case (e,_,_,{},_) then SOME({});
    case (e,vars,eqn_indx,(vindx :: vindxs),differentiateIfExp)
      equation
        v = getVarAt(vars, vindx);
        cr = varCref(v);
        e_1 = Derive.differentiateExp(e, cr, differentiateIfExp);
        e_2 = Exp.simplify(e_1);
        SOME(es) = calculateJacobianRow2(e, vars, eqn_indx, vindxs, differentiateIfExp);
      then
        SOME(((eqn_indx,vindx,RESIDUAL_EQUATION(e_2,DAE.emptyElementSource)) :: es));
  end matchcontinue;
end calculateJacobianRow2;

public function residualExp "function: residualExp
  author: PA
  This function extracts the residual expression from a residual equation"
  input Equation inEquation;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inEquation)
    local DAE.Exp e;
    case (RESIDUAL_EQUATION(exp = e)) then e;
  end matchcontinue;
end residualExp;

public function toResidualForm "function: toResidualForm
  author: PA
  This function transforms a daelow to residualform on the equations."
  input DAELow inDAELow;
  output DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow)
    local
      list<Equation> eqn_lst,eqn_lst2;
      EquationArray eqns2,eqns,seqns,ieqns;
      Variables vars,knvars,extVars;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] ialg;
      EventInfo wc;
      ExternalObjectClasses extobjcls;

    case (DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,ialg,wc,extobjcls))
      equation
        eqn_lst = equationList(eqns);
        eqn_lst2 = Util.listMap(eqn_lst, equationToResidualForm);
        eqns2 = listEquation(eqn_lst2);
      then
        DAELOW(vars,knvars,extVars,av,eqns2,seqns,ieqns,ae,ialg,wc,extobjcls);
  end matchcontinue;
end toResidualForm;

public function equationToResidualForm "function: equationToResidualForm
  author: PA
  This function transforms an equation to its residual form.
  For instance, a=b is transformed to a-b=0"
  input Equation inEquation;
  output Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation)
    local
      DAE.Exp e,e1,e2,exp;
      DAE.ComponentRef cr;
      DAE.ExpType tp;
      DAE.ElementSource source "origin of the element";
      DAE.Operator op;
      Boolean b;

    case (EQUATION(exp = e1,scalar = e2,source = source))
      equation
         //Exp.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        tp = Exp.typeof(e2);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));
        e = Exp.simplify(DAE.BINARY(e1,op,e2));
      then
        RESIDUAL_EQUATION(e,source);
    case (SOLVED_EQUATION(componentRef = cr,exp = exp,source = source))
      equation
         //Exp.dumpExpWithTitle("equationToResidualForm 2\n",exp);
        tp = Exp.typeof(exp);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));        
        e = Exp.simplify(DAE.BINARY(DAE.CREF(cr,tp),op,exp));
      then
        RESIDUAL_EQUATION(e,source);
    case ((e as RESIDUAL_EQUATION(exp = _,source = source)))
      local Equation e;
      then
        e;
    case ((e as ALGORITHM(index = _)))
      local Equation e;
      then
        e;
    case ((e as ARRAY_EQUATION(index = _)))
      local Equation e;
      then
        e;
    case ((e as WHEN_EQUATION(whenEquation = _)))
      local Equation e;
      then
        e;
    case (e)
      local Equation e;
      equation
        Debug.fprintln("failtrace", "- DAELow.equationToResidualForm failed");
      then
        fail();
  end matchcontinue;
end equationToResidualForm;

public function calculateSizes "function: calculateSizes
  author: PA

  Calculates the number of state variables, nx,
  the number of algebraic variables, ny
  and the number of parameters/constants, np.

  inputs:  DAELow
  outputs: (int, /* nx */
              int, /* ny */
              int, /* np */
              int  /* ng */
               int) next
"
  input DAELow inDAELow;
  output Integer outnx "number of states";
  output Integer outny "number of alg. vars";
  output Integer outnp "number of parameters";
  output Integer outng " number of zerocrossings";
  output Integer outng_sample " number of zerocrossings that are samples";
  output Integer outnext " number of external objects";

//nx cannot be strings
  output Integer outny_string "number of alg.vars which are strings";
  output Integer outnp_string  "number of parameters which are strings";
algorithm
  (outnx,outny,outnp,outng,outnext):=
  matchcontinue (inDAELow)
    local
      list<Var> varlst,knvarlst,extvarlst;
      Value np,ng,nsam,nx,ny,nx_1,ny_1,next,ny_string,np_string,ny_1_string;
      String np_str;
      Variables vars,knvars,extvars;
      list<WhenClause> wc;
      list<ZeroCrossing> zc;
    case (DAELOW(orderedVars = vars,knownVars = knvars, externalObjects = extvars,
                 eventInfo = EVENT_INFO(whenClauseLst = wc,
                                        zeroCrossingLst = zc)))
      equation
        varlst = varList(vars) "input variables are put in the known var list,
	  but they should be counted by the ny counter." ;
	  	  extvarlst = varList(extvars);
	  	  next = listLength(extvarlst);
        knvarlst = varList(knvars);
        (np,np_string) = calculateParamSizes(knvarlst);
        np_str = intString(np);
        (ng,nsam) = calculateNumberZeroCrossings(zc,0,0);
        (nx,ny,ny_string) = calculateVarSizes(varlst, 0, 0,0);
        (nx_1,ny_1,ny_1_string) = calculateVarSizes(knvarlst, nx, ny,ny_string);
      then
        (nx_1,ny_1,np,ng,nsam,next,ny_1_string,np_string);
  end matchcontinue;
end calculateSizes;

protected function calculateNumberZeroCrossings
  input list<ZeroCrossing> zcLst;
  input Integer zc_index;
  input Integer sample_index;
  output Integer zc;
  output Integer sample;
algorithm
  (outCFn) := matchcontinue (zcLst,zc_index,sample_index)
    local
      list<ZeroCrossing> xs;
    case ({},zc_index,sample_index) then (zc_index,sample_index);

    case (ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"))) :: xs,zc_index,sample_index)
      equation
        sample_index = sample_index + 1;
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (ZERO_CROSSING(relation_ = DAE.RELATION(operator = _), occurEquLst = _) :: xs,zc_index,sample_index)
      equation
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (_,_,_)
      equation
        print("- DAELow.calculateNumberZeroCrossings failed\n");
      then
        fail();

  end matchcontinue;
end calculateNumberZeroCrossings;

protected function calculateParamSizes "function: calculateParamSizes
  author: PA

  Helper function to calculate_sizes
"
  input list<Var> inVarLst;
  output Integer outInteger;
  output Integer outInteger2;
algorithm
  (outInteger,outInteger2):=
  matchcontinue (inVarLst)
    local
      Value s1,s2;
      Var var;
      list<Var> vs;
    case ({}) then (0,0);
    case ((var :: vs))
      equation
        (s1,s2) = calculateParamSizes(vs);
        true = isStringParam(var);
      then
        (s1,s2 + 1);
    case ((var :: vs))
      equation
        (s1,s2) = calculateParamSizes(vs);
        true = isParam(var);
      then
        (s1 + 1,s2);
    case ((_ :: vs))
      equation
        (s1,s2) = calculateParamSizes(vs);
      then
        (s1,s2);
    case (_)
      equation
        print("- DAELow.calculateParamSizes failed\n");
      then
        fail();        
  end matchcontinue;
end calculateParamSizes;

protected function calculateVarSizes "function: calculateVarSizes
  author: PA

  Helper function to calculate_sizes
"
  input list<Var> inVarLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;

  output Integer outInteger1;
  output Integer outInteger2;
  output Integer outInteger3;

algorithm
  (outInteger1,outInteger2,outInteger3):=
  matchcontinue (inVarLst1,inInteger2,inInteger3,inInteger4)
    local
      Value nx,ny,ny_1,nx_2,ny_2,nx_1,nx_string,ny_string,ny_1_string,ny_2_string;
      DAE.Flow flowPrefix;
      list<Var> vs;
    case ({},nx,ny,ny_string) then (nx,ny,ny_string);
    case ((VAR(varKind = VARIABLE(),varType=STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny, ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
    case ((VAR(varKind = VARIABLE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny_1,ny_string);
      then
        (nx_2,ny_2,ny_2_string);


     case ((VAR(varKind = DISCRETE(),varType=STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny,ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
     case ((VAR(varKind = DISCRETE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny_1,ny_string);
      then
        (nx_2,ny_2,ny_2_string);

    case ((VAR(varKind = STATE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string)
      equation
        nx_1 = nx + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx_1, ny,ny_string);
      then
        (nx_2,ny_2,ny_2_string);

    case ((VAR(varKind = DUMMY_STATE(),varType=STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string) /* A dummy state is an algebraic variable */
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny,ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
    case ((VAR(varKind = DUMMY_STATE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string) /* A dummy state is an algebraic variable */
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny_1,ny_string);
      then
        (nx_2,ny_2,ny_2_string);

    case ((VAR(varKind = DUMMY_DER(),varType=STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny,ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
    case ((VAR(varKind = DUMMY_DER(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny_1,ny_string);
      then
        (nx_2,ny_2,ny_2_string);

    case ((_ :: vs),nx,ny,ny_string)
      equation
        (nx_1,ny_1,ny_1_string) = calculateVarSizes(vs, nx, ny,ny_string);
      then
        (nx_1,ny_1,ny_1_string);


    case (_,_,_,_)
      equation
        print("- DAELow.calculateVarSizes failed\n");
      then
        fail();
  end matchcontinue;
end calculateVarSizes;

public function calculateValues "function: calculateValues
  author: PA

  This function calculates the values from the parameter binding expressions.
"
  input DAELow inDAELow;
  output DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<Var> knvarlst;
      Variables knvars,vars,extVars;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      EquationArray eqns,seqns,ie;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] al;
      EventInfo wc;
      ExternalObjectClasses extObjCls;
    case (DAELOW(orderedVars = vars,knownVars = knvars,externalObjects=extVars,aliasVars = av, orderedEqs = eqns,
      removedEqs = seqns,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = wc,extObjClasses=extObjCls))
      equation
        knvarlst = varList(knvars);
        knvarlst = Util.listMap1(knvarlst, calculateValue, knvars);
        knvars = listVar(knvarlst);
      then
        DAELOW(vars,knvars,extVars,av,eqns,seqns,ie,ae,al,wc,extObjCls);
  end matchcontinue;
end calculateValues;

protected function calculateValue
	input Var inVar;
	input Variables vars;
	output Var outVar;
algorithm
	outVar := matchcontinue(inVar, vars)
		local
			DAE.ComponentRef cr;
			VarKind vk;
			DAE.VarDirection vd;
			Type ty;
			DAE.Exp e, e2;
			DAE.InstDims dims;
			Integer idx;
			DAE.ElementSource src;
			Option<DAE.VariableAttributes> va;
			Option<SCode.Comment> c;
			DAE.Flow fp;
			DAE.Stream sp;
			Values.Value v;
		case (VAR(varName = cr, varKind = vk, varDirection = vd, varType = ty,
					bindExp = SOME(e), arryDim = dims, index = idx, source = src, 
					values = va, comment = c, flowPrefix = fp, streamPrefix = sp), _)
			equation
				((e2, _)) = Exp.traverseExp(e, replaceCrefsWithValues, vars);
				(_, v, _) = Ceval.ceval(Env.emptyCache(), Env.emptyEnv, e2, false, NONE,
						NONE, Ceval.MSG());
			then
				VAR(cr, vk, vd, ty, SOME(e), SOME(v), dims, idx, src, va, c, fp, sp);
		case (_, _) then inVar;
	end matchcontinue;
end calculateValue;

protected function replaceCrefsWithValues
	input tuple<DAE.Exp, Variables> inTuple;
	output tuple<DAE.Exp, Variables> outTuple;
algorithm
	outTuple := matchcontinue(inTuple)
		local
			DAE.Exp e;
			Variables vars;
			DAE.ComponentRef cr;
		case ((DAE.CREF(cr, _), vars))
		  equation
		     ({VAR(bindExp = SOME(e))}, _) = getVar(cr, vars);
		     ((e, _)) = Exp.traverseExp(e, replaceCrefsWithValues, vars);
		  then
		    ((e, vars));
		case (_) then inTuple;
	end matchcontinue;
end replaceCrefsWithValues;
	
protected function statesEqns "function: statesEqns
  author: PA

  Takes a list of equations and an (empty) BinTree and
  fills the tree with the state variables present in the equations
"
  input list<Equation> inEquationLst;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inEquationLst,inBinTree)
    local
      BinTree bt;
      DAE.Exp e1,e2;
      list<Equation> es;
      Value ds,indx;
      list<DAE.Exp> expl,expl1,expl2;
    case ({},bt) then bt;
    case ((EQUATION(exp = e1,scalar = e2) :: es),bt)
      equation
        bt = statesEqns(es, bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case ((ARRAY_EQUATION(index = ds,crefOrDerCref = expl) :: es),bt)
      equation
        bt = statesEqns(es, bt);
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case ((ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es),bt)
      equation
        bt = Util.listFold(expl1, statesExp, bt);
        bt = Util.listFold(expl2, statesExp, bt);
        bt = statesEqns(es, bt);
      then
        bt;
    case ((WHEN_EQUATION(whenEquation = _) :: es),bt)
      equation
        bt = statesEqns(es, bt);
      then
        bt;
    case (_,_)
      equation
        print("-states_eqns failed\n");
      then
        fail();
  end matchcontinue;
end statesEqns;

protected function getIndex "function: getIndex
  author: PA

  Helper function to derivative_replacements
"
  input DAE.ComponentRef inComponentRef;
  input list<Var> inVarLst;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inComponentRef,inVarLst)
    local
      DAE.ComponentRef cr1,cr2;
      Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      list<Var> vs;
    case (cr1,(VAR(varName = cr2,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: _))
      equation
        true = Exp.crefEqual(cr1, cr2);
      then
        indx;
    case (cr1,(_ :: vs))
      equation
        indx = getIndex(cr1, vs);
      then
        indx;
  end matchcontinue;
end getIndex;

protected function calculateIndexes "function: calculateIndexes
  author: PA modified by Frenkel TUD

  Helper function to translate_dae. Calculates the indexes for each variable
  in one of the arrays. x, xd, y and extobjs.
  To ensure that arrays(matrix,vector) are in a continuous memory block
  the indexes from vars, knvars and extvars has to be calculate at the same time.
  To seperate them after that they are stored in a list with
  the information about the type(vars=0,knvars=1,extvars=2) and the place at the
  original list.
"
  input list<Var> inVarLst1;
  input list<Var> inVarLst2;
  input list<Var> inVarLst3;

  output list<Var> outVarLst1;
  output list<Var> outVarLst2;
  output list<Var> outVarLst3;
algorithm
  (outVarLst1,outVarLst2,outVarLst3):=
  matchcontinue (inVarLst1,inVarLst2,inVarLst3)
    local
      list<Var> vars_2,knvars_2,extvars_2,extvars,vars,knvars;
      list< tuple<Var,Integer> > vars_1,knvars_1,extvars_1;
      list< tuple<Var,Integer,Integer> > vars_map,knvars_map,extvars_map,all_map,all_map1,noScalar_map,noScalar_map1,scalar_map,all_map2,mergedvar_map,sort_map,sort_map1;
      Value x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType;
    case (vars,knvars,extvars)
      equation
        // store vars,knvars,extvars in the list
        vars_map = fillListConst(vars,0,0);
        knvars_map = fillListConst(knvars,1,0);
        extvars_map = fillListConst(extvars,2,0);
        // connect the lists
        all_map = listAppend(vars_map,knvars_map);
        all_map1 = listAppend(all_map,extvars_map);
        // seperate scalars and non scalars
        (noScalar_map,scalar_map) = getNoScalarVars(all_map1);

        noScalar_map1 = getAllElements(noScalar_map);
        sort_map = sortNoScalarList(noScalar_map1);
        //print("\nsort_map:\n");
        //dumpSortMap(sort_map);
        // connect scalars and sortet non scalars
        mergedvar_map = listAppend(scalar_map,sort_map);
        // calculate indexes
        (all_map2,x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(mergedvar_map, 0, 0, 0, 0, 0,0,0,0,0,0,0);
        // seperate vars,knvars,extvas
        vars_1 = getListConst(all_map2,0);
        knvars_1 = getListConst(all_map2,1);
        extvars_1 =  getListConst(all_map2,2);
        // arrange lists in original order
        vars_2 = sortList(vars_1,0);
        knvars_2 = sortList(knvars_1,0);
        extvars_2 =  sortList(extvars_1,0);
      then
        (vars_2,knvars_2,extvars_2);
    case (_,_,_)
      equation
        print("-calculate_indexes failed\n");
      then
        fail();
  end matchcontinue;
end calculateIndexes;
/*
protected function dumpSortMap
  input list< tuple<Var,Integer,Integer> > inTypeALst;
algorithm
  _ :=
  matchcontinue (inTypeALst)
    local
      list<tuple<Var,Integer,Integer>> rest;
      Var item;
      Integer a,b;
    case ((item,a,b)::{})
      equation
        print(intString(a));
        print(";");
        print(intString(b));
        print(";");
        dumpVars({item});
      then
        ();      
    case ((item,a,b)::rest)
      equation
        print(intString(a));
        print(";");
        print(intString(b));
        print(";");
        dumpVars({item});
        dumpSortMap(rest);
      then
        ();
  end matchcontinue;
end dumpSortMap;  
*/
protected function fillListConst
"function: fillListConst
author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list, a type value an a start place and store all elements
  of the list in a list of tuples (element,type,place)"
  input list<Type_a> inTypeALst;
  input Integer inType;
  input Integer inPlace;
  output list< tuple<Type_a,Integer,Integer> > outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outlist :=
  matchcontinue (inTypeALst,inType,inPlace)
    local
      list<Type_a> rest;
      Type_a item;
      Integer value,place;
      list< tuple<Type_a,Integer,Integer> > out_lst,val_lst;
    case ({},value,place) then {};
    case (item::rest,value,place)
      equation
        /* recursive */
        val_lst = fillListConst(rest,value,place+1);
        /* fill  */
        out_lst = listAppend({(item,value,place)},val_lst);
      then
        out_lst;
  end matchcontinue;
end fillListConst;

protected function getListConst
"function: getListConst
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,type,place) and a type value
  and pitch on all elements with the same type value.
  The output is a list of tuples (element,place)."
  input list< tuple<Type_a,Integer,Integer> > inTypeALst;
  input Integer inValue;
  output list<tuple<Type_a,Integer>> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst :=
  matchcontinue (inTypeALst,inValue)
    local
      list<tuple<Type_a,Integer,Integer>> rest;
      Type_a item;
      Integer value, itemvalue,place;
      list<tuple<Type_a,Integer>> out_lst,val_lst,val_lst1;
    case ({},value) then {};
    case ((item,itemvalue,place)::rest,value)
      equation
        /* recursive */
        val_lst = getListConst(rest,value);
        /* fill  */
        val_lst1 = Util.if_(itemvalue == value,{(item,place)},{});
        out_lst = listAppend(val_lst1,val_lst);
      then
        out_lst;
  end matchcontinue;
end getListConst;

protected function sortList
"function: sortList
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,place)and generate a
  list of elements with the order given by the place value."
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> itemlst,rest;
      Type_a item,outitem;
      Integer place,itemplace;
      list<Type_a> out_lst,val_lst;
    case ({},place) then {};
    case (itemlst,place)
      equation
        /* get item */
        (outitem,rest) = sortList1(itemlst,place);
        /* recursive */
        val_lst = sortList(rest,place+1);
        /* append  */
        out_lst = listAppend({outitem},val_lst);
      then
        out_lst;
  end matchcontinue;
end sortList;

protected function sortList1
"function: sortList1
  author: Frenkel TUD
  Helper function for sortList"
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output Type_a outType;
  output list< tuple<Type_a,Integer> > outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  (outType,outTypeALst) :=
  matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> rest,out_itemlst;
      Type_a item;
      Integer place,itemplace;
      Type_a out_item;
    case ({},_)
      equation
        print("-sortList1 failed\n");
      then
        fail();
    case ((item,itemplace)::rest,place)
      equation
        /* compare */
        (place == itemplace) = true;
        /* ok */
        then
          (item,rest);
    case ((item,itemplace)::rest,place)
      equation
        /* recursive */
        (out_item,out_itemlst) = sortList1(rest,place);
      then
        (out_item,(item,itemplace)::out_itemlst);
  end matchcontinue;
end sortList1;

protected function getNoScalarVars
"function: getNoScalarVars
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a List of variables and seperate them
  in two lists. One for scalars and one for non scalars"
  input list< tuple<Var,Integer,Integer> > inlist;
  output list< tuple<Var,Integer,Integer> > outnoScalarlist;
  output list< tuple<Var,Integer,Integer> > outScalarlist;
algorithm
  (outnoScalarlist,outScalarlist) :=
  matchcontinue (inlist)
    local
      list< tuple<Var,Integer,Integer> > noScalarlst,scalarlst,rest,noScalarlst1,scalarlst1,noScalarlst2,scalarlst2;
      Var var,var1;
      Integer typ,place;
    case {} then ({},{});
    case ((var,typ,place) :: rest)
      equation
        /* recursive */
        (noScalarlst,scalarlst) = getNoScalarVars(rest);
        /* check  */
        (noScalarlst1,scalarlst1) = checkVarisNoScalar(var,typ,place);
        noScalarlst2 = listAppend(noScalarlst1,noScalarlst);
        scalarlst2 = listAppend(scalarlst1,scalarlst);
      then
        (noScalarlst2,scalarlst2);
    case (_)
      equation
        print("getNoScalarVars fails\n");
      then
        fail();
  end matchcontinue;
end getNoScalarVars;

protected function checkVarisNoScalar
"function: checkVarisNoScalar
  author: Frenkel TUD
  Helper function for getNoScalarVars.
  Take a variable and push them in a list
  for scalars ore non scalars"
  input Var invar;
  input Integer inTyp;
  input Integer inPlace;
  output list< tuple<Var,Integer,Integer> > outlist;
  output list< tuple<Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1) :=
  matchcontinue (invar,inTyp,inPlace)
    local
      DAE.InstDims dimlist;
      Var var;
      Integer typ,place;
    case (var as (VAR(arryDim = {})),typ,place) then ({},{(var,typ,place)});
    case (var as (VAR(arryDim = dimlist)),typ,place) then ({(var,typ,place)},{});
  end matchcontinue;
end checkVarisNoScalar;

protected function getAllElements
"function: getAllElements
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorte list"
  input list<tuple<Var,Integer,Integer> > inlist;
  output list<tuple<Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  matchcontinue (inlist)
    local
      list<tuple<Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,out_lst;
      Var var,var1;
      Boolean ins;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        (var_lst,var_lst1) = getAllElements1((var,typ,place),rest);
        var_lst2 = getAllElements(var_lst1);
        out_lst = listAppend(var_lst,var_lst2);
      then
        out_lst;
  end matchcontinue;
end getAllElements;

protected function getAllElements1
"function: getAllElements1
  author: Frenkel TUD
  Helper function for getAllElements."
  input tuple<Var,Integer,Integer>  invar;
  input list<tuple<Var,Integer,Integer> > inlist;
  output list<tuple<Var,Integer,Integer> > outlist;
  output list<tuple<Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1):=
  matchcontinue (var1,inlist)
    local
      list<tuple<Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,var_lst3,out_lst;
			DAE.ComponentRef varName1, varName2,c2,c1;
      Var var1,var2;
      Boolean ins;
      Integer typ1,typ2,place1,place2;
    case ((var1,typ1,place1),{}) then ({(var1,typ1,place1)},{});
		case ((var1 as VAR(varName = varName1), typ1, place1), (var2 as VAR(varName = varName2), typ2, place2) :: rest)
			equation
				(var_lst, var_lst1) = getAllElements1((var1, typ1, place1), rest);
        c1 = Exp.crefStripLastSubs(varName1);
        c2 = Exp.crefStripLastSubs(varName2);				
				ins = Exp.crefEqualNoStringCompare(c1, c2); 
				var_lst2 = listAppendTyp(ins, (var2, typ2, place2), var_lst);
				var_lst3 = listAppendTyp(boolNot(ins), (var2, typ2, place2), var_lst1);
			then
				(var_lst2, var_lst3);
  end matchcontinue;
end getAllElements1;

protected function sortNoScalarList
"function: sortNoScalarList
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input list<tuple<Var,Integer,Integer> > inlist;
  output list<tuple<Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  matchcontinue (inlist)
    local
      list<tuple<Var,Integer,Integer>> rest,var_lst,var_lst1,out_lst;
      Var var,var1;
      Boolean ins;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        var_lst = sortNoScalarList(rest);
        (var_lst1,ins) = sortNoScalarList1((var,typ,place),var_lst);
        out_lst = listAppendTyp(boolNot(ins),(var,typ,place),var_lst1);
      then
        out_lst;
  end matchcontinue;
end sortNoScalarList;

protected function listAppendTyp
"function: listAppendTyp
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input Boolean append;
  input Type_a  invar;
  input list<Type_a > inlist;
  output list<Type_a > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  (outlist):=
  matchcontinue (append,invar,inlist)
    local
      list<Type_a > var_lst;
      Type_a var;
    case (false,_,var_lst) then var_lst;
    case (true,var,var_lst)
      local
       list<Type_a > out_lst;
      equation
        out_lst = listAppend({var},var_lst);
      then
        out_lst;
  end matchcontinue;
end listAppendTyp;

protected function sortNoScalarList1
"function: sortNoScalarList1
  author: Frenkel TUD
  Helper function for sortNoScalarList"
  input tuple<Var,Integer,Integer>  invar;
  input list<tuple<Var,Integer,Integer> > inlist;
  output list<tuple<Var,Integer,Integer> > outlist;
  output Boolean insert;
algorithm
  (outlist,insert):=
  matchcontinue (invar,inlist)
    local
      list<tuple<Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2;
      Var var,var1;
      Boolean ins,ins1,ins2;
      Integer typ,typ1,place,place1;
    case (_,{}) then ({},false);
    case ((var,typ,place),(var1,typ1,place1)::rest)
      equation
        (var_lst,ins) = sortNoScalarList1((var,typ,place),rest);
        (var_lst1,ins1) = sortNoScalarList2(ins,(var,typ,place),(var1,typ1,place1),var_lst);
      then
        (var_lst1,ins1);
  end matchcontinue;
end sortNoScalarList1;

protected function sortNoScalarList2
"function: sortNoScalarList2
  author: Frenkel TUD
  Helper function for sortNoScalarList
  Takes a list of unsortet noScalarVars
  and returns a sorte list"
  input Boolean ininsert;
  input tuple<Var,Integer,Integer>  invar;
  input tuple<Var,Integer,Integer>  invar1;
  input list< tuple<Var,Integer,Integer> > inlist;
  output list< tuple<Var,Integer,Integer> > outlist;
  output Boolean outinsert;
algorithm
  (outlist,outinsert):=
  matchcontinue (ininsert,invar,invar1,inlist)
    local
      list< tuple<Var,Integer,Integer> > var_lst,var_lst1,var_lst2,out_lst;
      Var var,var1;
      Integer typ,typ1,place,place1;
      Boolean ins;
    case (false,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        ins = comparingNonScalars(var,var1);
        var_lst1 = Util.if_(ins,{(var1,typ1,place1),(var,typ,place)},{(var1,typ1,place1)});
        var_lst2 = listAppend(var_lst1,var_lst);
      then
        (var_lst2,ins);
    case (true,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        var_lst1 = listAppend({(var1,typ1,place1)},var_lst);
      then
        (var_lst1,true);
  end matchcontinue;
end sortNoScalarList2;

protected function comparingNonScalars
"function: comparingNonScalars
  author: Frenkel TUD
  Helper function for sortNoScalarList2
  Takes two NonScalars an returns
  it in right order
  Example1:  A[2,2],A[1,1] -> {A[1,1],A[2,2]}
  Example2:  A[2,2],B[1,1] -> {A[2,2],B[1,1]}"
  input Var invar1;
  input Var invar2;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (invar1,invar2)
    local
      DAE.Ident origName1,origName2;
      DAE.ComponentRef varName1, varName2,c1,c2;
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      Boolean out_val;
    case (VAR(varName = varName1,arryDim = arryDim),VAR(varName = varName2,arryDim = arryDim1))
      equation
        c1 = Exp.crefStripLastSubs(varName1);
        c2 = Exp.crefStripLastSubs(varName2);
        true = Exp.crefEqualNoStringCompare(c1, c2); 
        subscriptLst = Exp.crefLastSubs(varName1);
        subscriptLst1 = Exp.crefLastSubs(varName2);
        out_val = comparingNonScalars1(subscriptLst,subscriptLst1,arryDim,arryDim1);
      then
        out_val;        
    case (_,_) then false;
  end matchcontinue;
end comparingNonScalars;

protected function comparingNonScalars1
"function: comparingNonScalars1
  author: Frenkel TUD
  Helper function for comparingNonScalars.
  Check if a element of a non scalar has his place
  before or after another element in a one
  dimensional array."
  input list<DAE.Subscript> inlist;
  input list<DAE.Subscript> inlist1;
  input list<DAE.Subscript> inarryDim;
  input list<DAE.Subscript> inarryDim1;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (inlist, inlist1, inarryDim, inarryDim1)
    local
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      list<Integer> dim_lst,dim_lst1,dim_lst_1,dim_lst1_1;
      list<Integer> index,index1;
      Integer val1,val2;
    case (subscriptLst,subscriptLst1,arryDim,arryDim1)
      equation
        dim_lst = getArrayDim(arryDim);
        dim_lst1 = getArrayDim(arryDim1);
        index = getArrayDim(subscriptLst);
        index1 = getArrayDim(subscriptLst1);
        dim_lst_1 = Util.listStripFirst(dim_lst);
        dim_lst1_1 = Util.listStripFirst(dim_lst1);
        val1 = calcPlace(index,dim_lst_1);
        val2 = calcPlace(index1,dim_lst1_1);
        (val1 > val2) = true;
      then
       true;
    case (_,_,_,_) then false;
  end matchcontinue;
end comparingNonScalars1;

protected function calcPlace
"function: calcPlace
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Calculate based on the dimensions and the
  indexes the place of the element in a one
  dimensional array."
  input list<Integer> inindex;
  input list<Integer> dimlist;
  output Integer value;
algorithm
  value:=
  matchcontinue (inindex,dimlist)
    local
      list<Integer> index_lst,dim_lst;
      Integer value,value1,index,dim;
    case ({},{}) then 0;
    case (index::{},_) then index;
    case (index::index_lst,dim::dim_lst)
      equation
        value = calcPlace(index_lst,dim_lst);
        value1 = value + (index*dim);
      then
        value1;
     case (_,_)
      equation
        print("-calcPlace failed\n");
      then
        fail();
  end matchcontinue;
end calcPlace;

protected function getArrayDim
"function: getArrayDim
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Return the dimension of an array in a list."
  input list<DAE.Subscript> inarryDim;
  output list<Integer> dimlist;
algorithm
  dimlist:=
  matchcontinue (inarryDim)
    local
      list<DAE.Subscript> arryDim_lst,rest;
      DAE.Subscript arryDim;
      list<Integer> dim_lst,dim_lst1;
      Integer dim;
    case {} then {};
    case ((arryDim as DAE.INDEX(DAE.ICONST(dim)))::rest)
      equation
        dim_lst = getArrayDim(rest);
        dim_lst1 = listAppend({dim},dim_lst);
      then
        dim_lst1;       
  end matchcontinue;
end getArrayDim;

protected function calculateIndexes2
"function: calculateIndexes2
  author: PA
  Helper function to calculateIndexes"
  input list< tuple<Var,Integer,Integer> > inVarLst1;
  input Integer inInteger2; //X
  input Integer inInteger3; //xd
  input Integer inInteger4; //y
  input Integer inInteger5; //p
  input Integer inInteger6; //dummy
  input Integer inInteger7; //ext

  input Integer inInteger8; //X_str
  input Integer inInteger9; //xd_str
  input Integer inInteger10; //y_str
  input Integer inInteger11; //p_str
  input Integer inInteger12; //dummy_str

  output list<tuple<Var,Integer,Integer> > outVarLst1;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
  output Integer outInteger5;
  output Integer outInteger6;
  output Integer outInteger7;

  output Integer outInteger8; //x_str
  output Integer outInteger9; //xd_str
  output Integer outInteger10; //y_str
  output Integer outInteger11; //p_str
  output Integer outInteger12; //dummy_str
algorithm
  (outVarLst1,outInteger2,outInteger3,outInteger4,outInteger5,outInteger6,outInteger7):=
  matchcontinue (inVarLst1,inInteger2,inInteger3,inInteger4,inInteger5,inInteger6,inInteger7,inInteger8,inInteger9,inInteger10,inInteger11,inInteger12)
    local
      Value x,xd,y,p,dummy,y_1,x1,xd1,y1,p1,dummy1,x_1,p_1,ext,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType,y_1_strType,x_1_strType,p_1_strType;
      Value x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1;
      list< tuple<Var,Integer,Integer> > vars_1,vs;
      DAE.ComponentRef cr,name;
      DAE.VarDirection d;
      Type tp;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Integer typ,place;
    
    case ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      then ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = VARIABLE(),
               varDirection = d,
               varType = tp as STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,VARIABLE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = VARIABLE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,VARIABLE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = STATE(),
               varDirection = d,
               varType = tp as STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        x_1_strType = x_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_1_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,STATE(),d,tp,b,value,dim,x_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        x_1 = x + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x_1, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,STATE(),d,tp,b,value,dim,x,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = DUMMY_DER(),
               varDirection = d,
               varType = tp as STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,DUMMY_DER(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = DUMMY_DER(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,DUMMY_DER(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = DUMMY_STATE(),
               varDirection = d,
               varType = tp as STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,DUMMY_STATE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = DUMMY_STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,DUMMY_STATE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = DISCRETE(),
               varDirection = d,
               varType = tp as STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,DISCRETE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = DISCRETE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,DISCRETE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = PARAM(),
               varDirection = d,
               varType = tp as STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        p_1_strType = p_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_1_strType,dummy_strType);
      then
        (((VAR(cr,PARAM(),d,tp,b,value,dim,p_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = PARAM(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        p_1 = p + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p_1, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,PARAM(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = CONST(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
         //IS THIS A BUG??
         // THE INDEX FOR const IS SET TO p (=last parameter index)
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,CONST(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((VAR(varName = cr,
               varKind = EXTOBJ(path),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      local Absyn.Path path;
      equation
        ext_1 = ext+1;
        (vars_1,x1,xd1,y1,p1,dummy,ext_1,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((VAR(cr,EXTOBJ(path),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
  end matchcontinue;
end calculateIndexes2;

protected function printEquations "function: printEquations
  author: PA
  Helper function to dump"
  input list<Integer> inIntegerLst;
  input DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inIntegerLst,inDAELow)
    local
      Value n;
      list<Value> rest;
      DAELow dae;
    case ({},_) then ();
    case ((n :: rest),dae)
      equation
        printEquations(rest, dae);
        printEquationNo(n, dae);
      then
        ();
  end matchcontinue;
end printEquations;

protected function printEquationNo "function: printEquationNo
  author: PA

  Helper function to print_equations
"
  input Integer inInteger;
  input DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inInteger,inDAELow)
    local
      Value eqno_1,eqno;
      Equation eq;
      EquationArray eqns;
    case (eqno,DAELOW(orderedEqs = eqns))
      equation
        eqno_1 = eqno - 1;
        eq = equationNth(eqns, eqno_1);
        printEquation(eq);
      then
        ();
  end matchcontinue;
end printEquationNo;

public function printEquation "function: printEquation
  author: PA

  Helper function to print_equations
"
  input Equation inEquation;
algorithm
  _:=
  matchcontinue (inEquation)
    local
      String s1,s2,res;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      WhenEquation w;
    case (EQUATION(exp = e1,scalar = e2))
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({s1," = ",s2,"\n"});
        print(res);
      then
        ();
    case (WHEN_EQUATION(whenEquation = w))
      equation
        (cr,e2) = getWhenEquationExpr(w);
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({s1," =  ",s2,"\n"});
        print(res);
      then
        ();
  end matchcontinue;
end printEquation;

protected function treeGet "function: treeGet
  author: PA

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.
"
  input BinTree bt;
  input Key key;
  output Value v;
  String keystr;
algorithm
  keystr := Exp.printComponentRefStr(key);
  v := treeGet2(bt, keystr);
end treeGet;

protected function treeGet2 "function: treeGet2
  author: PA

  Helper function to tree_get
"
  input BinTree inBinTree;
  input String inString;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inBinTree,inString)
    local
      String rkeystr,keystr;
      DAE.ComponentRef rkey;
      Value rval,cmpval,res;
      Option<BinTree> left,right;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),keystr)
      equation
        rkeystr = Exp.printComponentRefStr(rkey);
        0 = System.strcmp(rkeystr, keystr);
      then
        rval;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = SOME(right)),keystr)
      local BinTree right;
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "Search to the right" ;
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        res = treeGet2(right, keystr);
      then
        res;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = SOME(left),rightSubTree = right),keystr)
      local BinTree left;
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "Search to the left" ;
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        res = treeGet2(left, keystr);
      then
        res;
  end matchcontinue;
end treeGet2;

protected function treeAdd "function: treeAdd
  author: PA

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int. Therefore we need to compare two strings
  to get a unique ordering.
"
  input BinTree inBinTree;
  input Key inKey;
  input Value inValue;
  output BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inBinTree,inKey,inValue)
    local
      DAE.ComponentRef key,rkey;
      Value value,rval,cmpval;
      String rkeystr,keystr;
      Option<BinTree> left,right;
      BinTree t_1,t,right_1,left_1;
    case (TREENODE(value = NONE,leftSubTree = NONE,rightSubTree = NONE),key,value)
      local DAE.ComponentRef nkey;
      equation
        nkey = Exp.convertEnumCref(key);
      then TREENODE(SOME(TREEVALUE(nkey,value)),NONE,NONE);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),key,value)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "Replace this node" ;
        keystr = Exp.printComponentRefStr(Exp.convertEnumCref(key));
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE(SOME(TREEVALUE(rkey,value)),left,right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key,value)
      equation
        keystr = Exp.printComponentRefStr(Exp.convertEnumCref(key)) "Insert to right subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(t_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as NONE)),key,value)
      equation
        keystr = Exp.printComponentRefStr(Exp.convertEnumCref(key)) "Insert to right node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(right_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(Exp.convertEnumCref(key)) "Insert to left subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(t_1),right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = (left as NONE),rightSubTree = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(Exp.convertEnumCref(key)) "Insert to left node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        left_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(left_1),right);
    case (_,_,_)
      equation
        print("tree_add failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd;

protected function treeDelete "function: treeDelete
  author: PA

  This function deletes an entry from the BinTree.
"
  input BinTree inBinTree;
  input Key inKey;
  output BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inBinTree,inKey)
    local
      BinTree bt,right_1,right,t_1,t;
      DAE.ComponentRef key,rkey;
      String rkeystr,keystr;
      TreeValue rightmost;
      Option<BinTree> optright_1,left,lleft,lright,topt_1;
      Value rval,cmpval;
      Option<TreeValue> leftval;
    case ((bt as TREENODE(value = NONE,leftSubTree = NONE,rightSubTree = NONE)),key) then bt;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = SOME(right)),key)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "delete this node, when existing right node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
        (rightmost,right_1) = treeDeleteRightmostValue(right);
        optright_1 = treePruneEmptyNodes(right_1);
      then
        TREENODE(SOME(rightmost),left,optright_1);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = SOME(TREENODE(leftval,lleft,lright)),rightSubTree = NONE),key)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "delete this node, when no right node, but left node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE(leftval,lleft,lright);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = NONE,rightSubTree = NONE),key)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "delete this node, when no left or right node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE(NONE,NONE,NONE);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key)
      local Option<BinTree> right;
      equation
        keystr = Exp.printComponentRefStr(key) "delete in right subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeDelete(t, key);
        topt_1 = treePruneEmptyNodes(t_1);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,topt_1);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key)
      local Option<BinTree> right;
      equation
        keystr = Exp.printComponentRefStr(key) "delete in left subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeDelete(t, key);
        topt_1 = treePruneEmptyNodes(t_1);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),topt_1,right);
    case (_,_)
      equation
        print("tree_delete failed\n");
      then
        fail();
  end matchcontinue;
end treeDelete;

protected function treeDeleteRightmostValue "function: treeDeleteRightmostValue
  author: PA

  This function takes a BinTree and deletes the rightmost value of the tree.
  Tt returns this value and the updated BinTree. This function is used in
  the binary tree deletion function \'tree_delete\'.

  inputs:  (BinTree)
  outputs: (TreeValue, /* deleted value */
              BinTree    /* updated bintree */)
"
  input BinTree inBinTree;
  output TreeValue outTreeValue;
  output BinTree outBinTree;
algorithm
  (outTreeValue,outBinTree):=
  matchcontinue (inBinTree)
    local
      TreeValue treevalue,value;
      BinTree left,right_1,right,bt;
      Option<BinTree> rightopt_1;
      Option<TreeValue> treeval;
    case (TREENODE(value = SOME(treevalue),leftSubTree = NONE,rightSubTree = NONE)) then (treevalue,TREENODE(NONE,NONE,NONE));
    case (TREENODE(value = SOME(treevalue),leftSubTree = SOME(left),rightSubTree = NONE)) then (treevalue,left);
    case (TREENODE(value = treeval,leftSubTree = left,rightSubTree = SOME(right)))
      local Option<BinTree> left;
      equation
        (value,right_1) = treeDeleteRightmostValue(right);
        rightopt_1 = treePruneEmptyNodes(right_1);
      then
        (value,TREENODE(treeval,left,rightopt_1));
    case (TREENODE(value = SOME(treeval),leftSubTree = NONE,rightSubTree = SOME(right)))
      local TreeValue treeval;
      equation
        failure((_,_) = treeDeleteRightmostValue(right));
        print("right value was empty , left NONE\n");
      then
        (treeval,TREENODE(NONE,NONE,NONE));
    case (bt)
      equation
        print("-tree_delete_rightmost_value failed\n");
      then
        fail();
  end matchcontinue;
end treeDeleteRightmostValue;

protected function treePruneEmptyNodes "function: tree_prune_emtpy_nodes
  author: PA

  This function is a helper function to tree_delete
  It is used to delete empty nodes of the BinTree representation, that might be introduced
  when deleting nodes.
"
  input BinTree inBinTree;
  output Option<BinTree> outBinTreeOption;
algorithm
  outBinTreeOption:=
  matchcontinue (inBinTree)
    local BinTree bt;
    case TREENODE(value = NONE,leftSubTree = NONE,rightSubTree = NONE) then NONE;
    case bt then SOME(bt);
  end matchcontinue;
end treePruneEmptyNodes;

protected function bintreeToList "function: bintreeToList
  author: PA

  This function takes a BinTree and transform it into a list
  representation, i.e. two lists of keys and values
"
  input BinTree inBinTree;
  output list<Key> outKeyLst;
  output list<Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTree)
    local
      list<Key> klst;
      list<Value> vlst;
      BinTree bt;
    case (bt)
      equation
        (klst,vlst) = bintreeToList2(bt, {}, {});
      then
        (klst,vlst);
    case (_)
      equation
        print("-bintree_to_list failed\n");
      then
        fail();
  end matchcontinue;
end bintreeToList;

protected function bintreeToList2 "function: bintreeToList2
  author: PA

  helper function to bintree_to_list
"
  input BinTree inBinTree;
  input list<Key> inKeyLst;
  input list<Value> inValueLst;
  output list<Key> outKeyLst;
  output list<Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTree,inKeyLst,inValueLst)
    local
      list<Key> klst;
      list<Value> vlst;
      DAE.ComponentRef key;
      Value value;
      Option<BinTree> left,right;
    case (TREENODE(value = NONE,leftSubTree = NONE,rightSubTree = NONE),klst,vlst) then (klst,vlst);
    case (TREENODE(value = SOME(TREEVALUE(key,value)),leftSubTree = left,rightSubTree = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(right, klst, vlst);
      then
        ((key :: klst),(value :: vlst));
    case (TREENODE(value = NONE,leftSubTree = left,rightSubTree = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
        (klst,vlst) = bintreeToListOpt(left, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToList2;

protected function bintreeToListOpt "function: bintreeToListOpt
  author: PA

  helper function to bintree_to_list
"
  input Option<BinTree> inBinTreeOption;
  input list<Key> inKeyLst;
  input list<Value> inValueLst;
  output list<Key> outKeyLst;
  output list<Value> outValueLst;
algorithm
  (outKeyLst,outValueLst):=
  matchcontinue (inBinTreeOption,inKeyLst,inValueLst)
    local
      list<Key> klst;
      list<Value> vlst;
      BinTree bt;
    case (NONE,klst,vlst) then (klst,vlst);
    case (SOME(bt),klst,vlst)
      equation
        (klst,vlst) = bintreeToList2(bt, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToListOpt;

protected function printVarsStatistics "function: printVarsStatistics
  author: PA

  Prints statistics on variables, currently depth of BinTree, etc.
"
  input Variables inVariables1;
  input Variables inVariables2;
algorithm
  _:=
  matchcontinue (inVariables1,inVariables2)
    local
      String lenstr,bstr;
      VariableArray v1,v2;
      Value bsize1,n1,bsize2,n2;
    case (VARIABLES(varArr = v1,bucketSize = bsize1,numberOfVars = n1),VARIABLES(varArr = v2,bucketSize = bsize2,numberOfVars = n2))
      equation
        print("Variable Statistics\n");
        print("===================\n");
        print("Number of variables: ");
        lenstr = intString(n1);
        print(lenstr);
        print("\n");
        print("Bucket size for variables: ");
        bstr = intString(bsize1);
        print(bstr);
        print("\n");
        print("Number of known variables: ");
        lenstr = intString(n2);
        print(lenstr);
        print("\n");
        print("Bucket size for known variables: ");
        bstr = intString(bsize1);
        print(bstr);
        print("\n");
      then
        ();
  end matchcontinue;
end printVarsStatistics;

protected function bintreeDepth "function: bintreeDepth
  author: PA

  This function calculates the depth of the Binary Tree given
  as input. It can be used for debugging purposes to investigate
  how balanced binary trees are.
"
  input BinTree inBinTree;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inBinTree)
    local
      Value ld,rd,res;
      BinTree left,right;
    case (TREENODE(leftSubTree = NONE,rightSubTree = NONE)) then 1;
    case (TREENODE(leftSubTree = SOME(left),rightSubTree = SOME(right)))
      equation
        ld = bintreeDepth(left);
        rd = bintreeDepth(right);
        res = intMax(ld, rd);
      then
        res + 1;
    case (TREENODE(leftSubTree = SOME(left),rightSubTree = NONE))
      equation
        ld = bintreeDepth(left);
      then
        ld;
    case (TREENODE(leftSubTree = NONE,rightSubTree = SOME(right)))
      equation
        rd = bintreeDepth(right);
      then
        rd;
  end matchcontinue;
end bintreeDepth;

protected function isAlgebraic "function: isAlgebraic
  author: PA

  This function returns true if an expression is purely algebraic, i.e. not
  containing any derivatives
  Otherwise it returns false.
"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      Value x,ival;
      String s,id;
      DAE.ComponentRef c;
      DAE.Exp e1,e2,e21,e22,e,t,f,stop,start,step,cr,dim,exp,iterexp;
      DAE.Operator op;
      DAE.ExpType ty,ty2,REAL;
      list<DAE.Exp> args,es,sub;
      Absyn.Path fcn;
    case (DAE.END()) then true;
    case (DAE.ICONST(integer = x)) then true;
    case (DAE.RCONST(real = x))
      local Real x;
      then
        true;
    case (DAE.SCONST(string = s)) then true;
    case (DAE.BCONST(bool = false)) then true;
    case (DAE.BCONST(bool = true)) then true;
    case (DAE.CREF(componentRef = c)) then true;
    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = ty)),exp2 = (e2 as DAE.BINARY(exp1 = e21,operator = DAE.SUB(ty = ty2),exp2 = e22))))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.UNARY(operator = op,exp = e))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.LUNARY(operator = op,exp = e))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f))
      local DAE.Exp c;
      equation
        true = isAlgebraic(c);
        true = isAlgebraic(t);
        true = isAlgebraic(f);
      then
        true;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = args)) then false;
    case (DAE.CALL(path = fcn,expLst = args)) then true;
    case (DAE.ARRAY(array = es)) then true;
    case (DAE.TUPLE(PR = es)) then true;
    case (DAE.MATRIX(scalar = es))
      local list<list<tuple<DAE.Exp, Boolean>>> es;
      then
        true;
    case (DAE.RANGE(exp = start,expOption = NONE,range = stop))
      equation
        true = isAlgebraic(start);
        true = isAlgebraic(stop);
      then
        true;
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop))
      equation
        true = isAlgebraic(start);
        true = isAlgebraic(step);
        true = isAlgebraic(stop);
      then
        true;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e)) then true;
    case (DAE.ASUB(exp = e,sub = sub))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.SIZE(exp = cr)) then true;
    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp)) then true;
    case (_) then true;
  end matchcontinue;
end isAlgebraic;

public function isVarKnown "function: isVarKnown
  author: PA

  Returns true if the the variable is present in the variable list.
  This is done by traversing the list, searching for a matching variable
  name.
"
  input list<Var> inVarLst;
  input DAE.ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVarLst,inComponentRef)
    local
      DAE.ComponentRef var_name,cr;
      Var variable;
      Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Var> rest;
      Boolean res;
    case ({},var_name) then false;
    case (((variable as VAR(varName = cr,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix)) :: rest),var_name)
      equation
        true = Exp.crefEqual(cr, var_name);
      then
        true;
    case (((variable as VAR(varName = cr,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix,streamPrefix = streamPrefix)) :: rest),var_name)
      equation
        res = isVarKnown(rest, var_name);
      then
        res;
  end matchcontinue;
end isVarKnown;

public function getAllExps "function: getAllExps
  author: PA

  This function goes through the DAELow structure and finds all the
  expressions and returns them in a list
"
  input DAELow inDAELow;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inDAELow)
    local
      list<DAE.Exp> exps1,exps2,exps3,exps4,exps5,exps6,exps;
      list<DAE.Algorithm> alglst;
      list<list<DAE.Exp>> explist6,explist;
      Variables vars1,vars2;
      EquationArray eqns,reqns,ieqns;
      MultiDimEquation[:] ae;
      DAE.Algorithm[:] algs;
    case (DAELOW(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,initialEqs = ieqns,arrayEqs = ae,algorithms = algs))
      equation
        exps1 = getAllExpsVars(vars1);
        exps2 = getAllExpsVars(vars2);
        exps3 = getAllExpsEqns(eqns);
        exps4 = getAllExpsEqns(reqns);
        exps5 = getAllExpsEqns(ieqns);
        exps6 = getAllExpsArrayEqns(ae);
        alglst = arrayList(algs);
        explist6 = Util.listMap(alglst, Algorithm.getAllExps);
        explist = listAppend({exps1,exps2,exps3,exps4,exps5,exps6}, explist6);
        exps = Util.listFlatten(explist);
      then
        exps;
  end matchcontinue;
end getAllExps;

protected function getAllExpsArrayEqns "function: getAllExpsArrayEqns
  author: PA

  Returns all expressions in array equations
"
  input MultiDimEquation[:] arr;
  output list<DAE.Exp> res;
  list<MultiDimEquation> lst;
  list<list<DAE.Exp>> llst;
algorithm
  lst := arrayList(arr);
  llst := Util.listMap(lst, getAllExpsArrayEqn);
  res := Util.listFlatten(llst);
end getAllExpsArrayEqns;

protected function getAllExpsArrayEqn "function: getAllExpsArrayEqn
  author: PA

  Helper function to get_all_exps_array_eqns
"
  input MultiDimEquation inMultiDimEquation;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inMultiDimEquation)
    local DAE.Exp e1,e2;
    case (MULTIDIM_EQUATION(left = e1,right = e2)) then {e1,e2};
  end matchcontinue;
end getAllExpsArrayEqn;

protected function getAllExpsVars "function: getAllExpsVars
  author: PA

  Helper to get_all_exps. Goes through the Variables type
"
  input Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inVariables)
    local
      list<Var> vars;
      list<DAE.Exp> exps;
      list<CrefIndex>[:] crefindex;
      list<StringIndex>[:] oldcrefindex;
      VariableArray vararray;
      Value bsize,nvars;
    case VARIABLES(crefIdxLstArr = crefindex,strIdxLstArr = oldcrefindex,varArr = vararray,bucketSize = bsize,numberOfVars = nvars)
      equation
        vars = vararrayList(vararray) "We can ignore crefs, they don\'t contain real expressions" ;
        exps = Util.listMap(vars, getAllExpsVar);
        exps = Util.listFlatten(exps);
      then
        exps;
  end matchcontinue;
end getAllExpsVars;

protected function getAllExpsVar "function: getAllExpsVar
  author: PA
  Helper to get_all_exps_vars. Get all exps from a  Var.
  DAE.ET_OTHER is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  input Var inVar;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inVar)
    local
      list<DAE.Exp> e1,e2,e3,exps;
      DAE.ComponentRef cref;
      Option<DAE.Exp> bndexp;
      list<DAE.Subscript> instdims;
    case VAR(varName = cref,
             bindExp = bndexp,
             arryDim = instdims
             )
      equation
        e1 = Util.optionToList(bndexp);
        e3 = Util.listMap(instdims, getAllExpsSubscript);
        e3 = Util.listFlatten(e3);
        exps = Util.listFlatten({e1,e3,{DAE.CREF(cref,DAE.ET_OTHER())}});
      then
        exps;
  end matchcontinue;
end getAllExpsVar;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  author: PA
  Get all exps from a Subscript"
  input DAE.Subscript inSubscript;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inSubscript)
    local DAE.Exp e;
    case DAE.WHOLEDIM() then {};
    case DAE.SLICE(exp = e) then {e};
    case DAE.INDEX(exp = e) then {e};
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsEqns "function: getAllExpsEqns
  author: PA

  Helper to get_all_exps. Goes through the EquationArray type
"
  input EquationArray inEquationArray;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inEquationArray)
    local
      list<Equation> eqns;
      list<DAE.Exp> exps;
      EquationArray eqnarray;
    case ((eqnarray as EQUATION_ARRAY(numberOfElement = _)))
      equation
        eqns = equationList(eqnarray);
        exps = Util.listMap(eqns, getAllExpsEqn);
        exps = Util.listFlatten(exps);
      then
        exps;
  end matchcontinue;
end getAllExpsEqns;

protected function getAllExpsEqn "function: getAllExpsEqn
  author: PA
  Helper to get_all_exps_eqns. Get all exps from an Equation."
  input Equation inEquation;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst :=  matchcontinue (inEquation)
    local
      DAE.Exp e1,e2,e;
      list<DAE.Exp> expl,exps;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      Value ind;
      WhenEquation elsePart;
      DAE.ElementSource source;

    case EQUATION(exp = e1,scalar = e2) then {e1,e2};
    case ARRAY_EQUATION(crefOrDerCref = expl) then expl;
    case SOLVED_EQUATION(componentRef = cr,exp = e)
      equation
        tp = Exp.typeof(e);
      then
        {DAE.CREF(cr,tp),e};
    case WHEN_EQUATION(whenEquation = WHEN_EQ(left = cr,right = e,elsewhenPart=NONE))
      equation
        tp = Exp.typeof(e);
      then
        {DAE.CREF(cr,tp),e};
    case WHEN_EQUATION(whenEquation = WHEN_EQ(_,cr,e,SOME(elsePart)),source = source)
      equation
        tp = Exp.typeof(e);
        expl = getAllExpsEqn(WHEN_EQUATION(elsePart,source));
        exps = listAppend({DAE.CREF(cr,tp),e},expl);
      then
        exps;
    case ALGORITHM(index = ind,in_ = e1,out = e2)
      local list<DAE.Exp> e1,e2;
      equation
        exps = listAppend(e1, e2);
      then
        exps;
  end matchcontinue;
end getAllExpsEqn;

public function isParam
"function: isParam
  Return true if variable is a parameter."
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case VAR(varKind = PARAM()) then true;
    case (_) then false;
  end matchcontinue;
end isParam;

public function isStringParam
"function: isStringParam
  Return true if variable is a parameter."
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (VAR(varKind = PARAM(),varType = STRING())) then true;
    case (_) then false;
  end matchcontinue;
end isStringParam;

public function isExtObj
"function: isExtObj
  Return true if variable is an external object."
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (VAR(varKind = EXTOBJ(_))) then true;
    case (_) then false;
  end matchcontinue;
end isExtObj;

public function isRealParam
"function: isParam
  Return true if variable is a parameter of real-type"
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inVar)
    case (VAR(varKind = PARAM(),varType = REAL())) then true;
    case (_) then false;
  end matchcontinue;
end isRealParam;

public function isNonRealParam
"function: isNonRealParam
  Return true if variable is NOT a parameter of real-type"
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := not isRealParam(inVar);
end isNonRealParam;

public function isOutput
"function: isOutput
  Return true if variable is declared as output. Note that the output
  attribute sticks with a variable even if it is originating from a sub
  component, which is not the case for Dymola."
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (VAR(varDirection = DAE.OUTPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isOutput;

public function isInput
"function: isInput
  Returns true if variable is declared as input.
  See also is_ouput above"
  input Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    case (VAR(varDirection = DAE.INPUT())) then true;
    case (_) then false;
  end matchcontinue;
end isInput;

public function getWhenEquationExpr
"function: getWhenEquationExpr
  Get the left and right hand parts from an equation appearing in a when clause"
  input WhenEquation inWhenEquation;
  output DAE.ComponentRef outComponentRef;
  output DAE.Exp outExp;
algorithm
  (outComponentRef,outExp):=
  matchcontinue (inWhenEquation)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
    case (WHEN_EQ(left = cr,right = e)) then (cr,e);
  end matchcontinue;
end getWhenEquationExpr;

public function getWhenCondition
"function: getWhenCodition
  Get expression's of condition by when equation"
  input list<WhenClause> inWhenClause;
  input Integer inIndex;
  output list<DAE.Exp> outExp;
algorithm
  conditionList := matchcontinue (inWhenClause, inIndex)
    local
      list<WhenClause> wc;
      Integer ind;
      list<DAE.Exp> condlst;
      DAE.Exp e;
    case (wc, ind)
      equation
        WHEN_CLAUSE(condition=DAE.ARRAY(_,_,condlst)) = listNth(wc, ind);
      then condlst;
    case (wc, ind)
      equation
        WHEN_CLAUSE(condition=e) = listNth(wc, ind);
      then {e};
  end matchcontinue;
end getWhenCondition;

public function getZeroCrossingIndicesFromWhenClause "function: getZeroCrossingIndicesFromWhenClause
  Returns a list of indices of zerocrossings that a given when clause is dependent on.
"
  input DAELow inDAELow;
  input Integer inInteger;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inDAELow,inInteger)
    local
      list<Value> res;
      list<ZeroCrossing> zcLst;
      Value when_index;
    case (DAELOW(eventInfo = EVENT_INFO(zeroCrossingLst = zcLst)),when_index)
      equation
        res = getZeroCrossingIndicesFromWhenClause2(zcLst, 0, when_index);
      then
        res;
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause;

protected function getZeroCrossingIndicesFromWhenClause2 "function: getZeroCrossingIndicesFromWhenClause2
  helper function to get_zero_crossing_indices_from_when_clause
"
  input list<ZeroCrossing> inZeroCrossingLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inZeroCrossingLst1,inInteger2,inInteger3)
    local
      Value count_1,count,when_index;
      list<Value> resx,whenClauseList;
      list<ZeroCrossing> rest;
    case ({},_,_) then {};
    case ((ZERO_CROSSING(occurWhenLst = whenClauseList) :: rest),count,when_index)
      equation
        _ = Util.listGetMember(when_index, whenClauseList);
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        (count :: resx);
    case ((ZERO_CROSSING(occurWhenLst = whenClauseList) :: rest),count,when_index)
      equation
        failure(_ = Util.listGetMember(when_index, whenClauseList));
        count_1 = count + 1;
        resx = getZeroCrossingIndicesFromWhenClause2(rest, count_1, when_index);
      then
        resx;
    case (_,_,_)
      equation
        print("-get_zero_crossing_indices_from_when_clause2 failed\n");
      then
        fail();
  end matchcontinue;
end getZeroCrossingIndicesFromWhenClause2;

public function daeVars
  input DAELow inDAELow;
  output Variables vars;
algorithm
  vars := matchcontinue (inDAELow)
    local Variables vars1,vars2;
    case (DAELOW(orderedVars = vars1, knownVars = vars2))
      then vars1;
  end matchcontinue;
end daeVars;

public function daeKnVars
  input DAELow inDAELow;
  output Variables vars;
algorithm
  vars := matchcontinue (inDAELow)
    local Variables vars1,vars2;
    case (DAELOW(orderedVars = vars1, knownVars = vars2))
      then vars2;
  end matchcontinue;
end daeKnVars;

public function makeExpType
"Transforms a Type to DAE.ExpType
"
  input  Type inType;
  output DAE.ExpType outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
    case REAL() then DAE.ET_REAL();
    case INT() then DAE.ET_INT();
    case BOOL() then DAE.ET_BOOL();
    case STRING() then DAE.ET_STRING();
    case ENUMERATION(strLst) then DAE.ET_ENUMERATION(NONE(),Absyn.IDENT(""),strLst,{});
    case EXT_OBJECT(_) then DAE.ET_OTHER();
  end matchcontinue;
end makeExpType;

protected function generateDaeType
"Transforms a Type to DAE.Type
"
  input  Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
      Absyn.Path path;
    case REAL() then DAE.T_REAL_DEFAULT;
    case INT() then DAE.T_INTEGER_DEFAULT;
    case BOOL() then DAE.T_BOOL_DEFAULT;
    case STRING() then DAE.T_STRING_DEFAULT;
    case ENUMERATION(strLst) then ((DAE.T_ENUMERATION(NONE,Absyn.IDENT(""),strLst,{}),NONE));
    case EXT_OBJECT(path) then ((DAE.T_COMPLEX(ClassInf.EXTERNAL_OBJ(path),{},NONE,NONE),NONE));
  end matchcontinue;
end generateDaeType;

protected function lowerType
"Transforms a DAE.Type to Type
"
  input  DAE.Type inType;
  output Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
      Absyn.Path path;
    case ((DAE.T_REAL(_),_)) then REAL();
    case ((DAE.T_INTEGER(_),_)) then INT();
    case ((DAE.T_BOOL(_),_)) then BOOL();
    case ((DAE.T_STRING(_),_)) then STRING();
    case ((DAE.T_ENUMERATION(names = strLst),_)) then ENUMERATION(strLst);
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_)) then EXT_OBJECT(path);
  end matchcontinue;
end lowerType;

public function dumpTypeStr
" Dump Type to a string.
"
  input Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      String s1,s2,str;
      list<String> l;
      Absyn.Path path;
    case INT() then "Integer ";
    case REAL() then "Real ";
    case BOOL() then "Boolean ";
    case STRING() then "String ";

    case ENUMERATION(stringLst = l)
      equation
        s1 = Util.stringDelimitList(l, ", ");
        s2 = stringAppend("enumeration(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case EXT_OBJECT(_) then "ExternalObject ";
  end matchcontinue;
end dumpTypeStr;

public function tearingSystem
" function: tearingSystem
  autor: Frenkel TUD
  Pervormes tearing method on a system.
  This is just a funktion to check the flack tearing.
  All other will be done at tearingSystem1."
  input DAELow inDlow;
  input IncidenceMatrix inM;
  input IncidenceMatrixT inMT;
  input Integer[:] inV1;
  input Integer[:] inV2;
  input list<list<Integer>> inComps;
  output DAELow outDlow;
  output IncidenceMatrix outM;
  output IncidenceMatrixT outMT;
  output Integer[:] outV1;
  output Integer[:] outV2;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
algorithm
  (outDlow,outM,outMT,outV1,outV2,outComps,outResEqn,outTearVar):=
  matchcontinue (inDlow,inM,inMT,inV1,inV2,inComps)
    local
      DAELow dlow,dlow_1,dlow1;
      IncidenceMatrix m,m_1;
      IncidenceMatrixT mT,mT_1;
      Integer[:] v1,v2,v1_1,v2_1;
      list<list<Integer>> comps,comps_1;
      list<list<Integer>> r,t;
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "Tearing\n==========\n");
        // get residual eqn and tearing var for each block
        // copy dlow
        dlow1 = copyDaeLowforTearing(dlow);
        (r,t,_,dlow_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
        Debug.fcall("tearingdump", dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", dump, dlow_1);
        Debug.fcall("tearingdump", dumpMatching, v1_1);
        Debug.fcall("tearingdump", dumpComponents, comps_1);
        Debug.fcall("tearingdump", print, "==========\n");
        Debug.fcall2("tearingdump", dumpTearing, r,t);
        Debug.fcall("tearingdump", print, "==========\n");
      then
        (dlow_1,m_1,mT_1,v1_1,v2_1,comps_1,r,t);
    case (dlow,m,mT,v1,v2,comps)
      equation
        Debug.fcall("tearingdump", print, "No Tearing\n==========\n");
      then
        (dlow,m,mT,v1,v2,comps,{},{});
  end matchcontinue;
end tearingSystem;

public function dumpTearing
" function: dumpTearing
  autor: Frenkel TUD
  Dump tearing vars and residual equations."
  input list<list<Integer>> inResEqn;
  input list<list<Integer>> inTearVar;
algorithm
  _:=
  matchcontinue (inResEqn,inTearVar)
    local
      list<Integer> tearingvars,residualeqns;
      list<list<Integer>> r,t;
      list<String> str_r,str_t;
      String str_r_f,str_r_1,str_t_f,str_t_1,str,sr,st;
    case (residualeqns::r,tearingvars::t)
      equation
        str_r = Util.listMap(residualeqns, intString);
        str_r_f = Util.stringDelimitList(str_r, ", ");
        str_r_1 = stringAppend(str_r_f, "\n");
        sr = stringAppend("ResidualEqns: ",str_r_1);
        str_t = Util.listMap(tearingvars, intString);
        str_t_f = Util.stringDelimitList(str_t, ", ");
        str_t_1 = stringAppend(str_t_f, "\n");
        st = stringAppend("TearingVars: ",str_t_1);
        str = stringAppend(sr, st);
        print(str);
        print("\n");
        dumpTearing(r,t);
      then
        ();
  end matchcontinue;
end dumpTearing;

protected function copyDaeLowforTearing
" function: copyDaeLowforTearing
  autor: Frenkel TUD
  Copy the dae to avoid changes in
  vectors."
  input DAELow inDlow;
  output DAELow outDlow;
algorithm
  outDlow:=
  matchcontinue (inDlow)
    local
      Variables ordvars,knvars,exobj,ordvars1;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      EquationArray eqns,remeqns,inieqns,eqns1;
      MultiDimEquation[:] arreqns;
      DAE.Algorithm[:] algorithms;
      EventInfo einfo;
      ExternalObjectClasses eoc;
      Value n,size,n1,size1;
      Option<Equation>[:] arr_1,arr;
      list<CrefIndex>[:] crefIdxLstArr,crefIdxLstArr1;
      list<StringIndex>[:] strIdxLstArr,strIdxLstArr1;
      VariableArray varArr;
      Integer bucketSize;
      Integer numberOfVars;
      Option<Var>[:] varOptArr,varOptArr1;
    case (DAELOW(ordvars,knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc))
      equation
        VARIABLES(crefIdxLstArr,strIdxLstArr,varArr,bucketSize,numberOfVars) = ordvars;
        VARIABLE_ARRAY(n1,size1,varOptArr) = varArr;
        crefIdxLstArr1 = fill({}, size1);
        crefIdxLstArr1 = Util.arrayCopy(crefIdxLstArr, crefIdxLstArr1);
        strIdxLstArr1 = fill({}, size1);
        strIdxLstArr1 = Util.arrayCopy(strIdxLstArr, strIdxLstArr1);
        varOptArr1 = fill(NONE, size1);
        varOptArr1 = Util.arrayCopy(varOptArr, varOptArr1);
        ordvars1 = VARIABLES(crefIdxLstArr1,strIdxLstArr1,VARIABLE_ARRAY(n1,size1,varOptArr1),bucketSize,numberOfVars);
        EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr) = eqns;
        arr_1 = fill(NONE, size);
        arr_1 = Util.arrayCopy(arr, arr_1);
        eqns1 = EQUATION_ARRAY(n,size,arr_1);
      then
        DAELOW(ordvars1,knvars,exobj,av,eqns1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
  end matchcontinue;
end copyDaeLowforTearing;

protected function tearingSystem1
" function: tearingSystem1
  autor: Frenkel TUD
  Main loop. Check all Comps and start tearing if
  strong connected components there"
  input DAELow inDlow;
  input DAELow inDlow1;
  input IncidenceMatrix inM;
  input IncidenceMatrixT inMT;
  input Integer[:] inV1;
  input Integer[:] inV2;
  input list<list<Integer>> inComps;
  output list<list<Integer>> outResEqn;
  output list<list<Integer>> outTearVar;
  output DAELow outDlow;
  output DAELow outDlow1;
  output IncidenceMatrix outM;
  output IncidenceMatrixT outMT;
  output Integer[:] outV1;
  output Integer[:] outV2;
  output list<list<Integer>> outComps;
algorithm
  (outResEqn,outTearVar,outDlow,outDlow1,outM,outMT,outV1,outV2,outComps):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps)
    local
      DAELow dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      IncidenceMatrix m,m_1,m_2,m_3,m_4;
      IncidenceMatrixT mT,mT_1,mT_2,mT_3,mT_4;
      Integer[:] v1,v2,v1_1,v2_1,v1_2,v2_2,v1_3,v2_3;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,tearingeqns,l2,l2_1;
      list<list<Integer>> r,t;
      Integer ll;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{})
      then
        ({},{},dlow,dlow1,m,mT,v1,v2,{});
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // get all interesting vars
        (tvars,crlst) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},{},{},{},crlst);
        // clean v1,v2,m,mT
        v2_2 = fill(0, ll);
        v2_2 = Util.arrayNCopy(v2_1, v2_2,ll);
        v1_2 = fill(0, ll);
        v1_2 = Util.arrayNCopy(v1_1, v1_2,ll);
        m_3 = incidenceMatrix(dlow1_1);
        mT_3 = transposeMatrix(m_3);
        (v1_3,v2_3) = correctAssignments(v1_2,v2_2,residualeqns,tearingvars);
        // next Block
        (r,t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comps_1) = tearingSystem1(dlow_1,dlow1_1,m_3,mT_3,v1_2,v2_2,comps);
      then
        (residualeqns::r,tearingvars::t,dlow_2,dlow1_2,m_4,mT_4,v1_3,v2_3,comp_1::comps_1);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps)
      equation
        // block ?
        ll = listLength(comp);
        false = ll > 1;
        // next Block
        (r,t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps_1) = tearingSystem1(dlow,dlow1,m,mT,v1,v2,comps);
      then
        ({0}::r,{0}::t,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp::comps_1);
  end matchcontinue;
end tearingSystem1;

protected function correctAssignments
" function: correctAssignments
  Correct the assignments"
  input Value[:] inV1;
  input Value[:] inV2;
  input list<Integer> inRLst;
  input list<Integer> inTLst;
  output Value[:] outV1;
  output Value[:] outV2;
algorithm
  (outV1,outV2):=
  matchcontinue (inV1,inV2,inRLst,inTLst)
    local
      Value[:] v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<Value> comp;
      list<Integer> rlst,tlst;
      Integer r,t;
    case (v1,v2,{},{}) then (v1,v2);
    case (v1,v2,r::rlst,t::tlst)
      equation
         v1_1 = arrayUpdate(v1,t,r);
         v2_1 = arrayUpdate(v2,r,t);
         (v1_2,v2_2) = correctAssignments(v1_1,v2_1,rlst,tlst);
      then
        (v1_2,v2_2);
  end matchcontinue;
end correctAssignments;

protected function getTearingVars
" function: getTearingVars
  Substracts all interesting vars for tearing"
  input IncidenceMatrix inM;
  input Value[:] inV1;
  input Value[:] inV2;
  input list<Value> inComp;
  input DAELow inDlow;
  output list<Value> outVarLst;
  output list<DAE.ComponentRef> outCrLst;
algorithm
  (outVarLst,outCrLst):=
  matchcontinue (inM,inV1,inV2,inComp,inDlow)
    local
      IncidenceMatrix m;
      Value[:] v1,v2;
      Value c,v;
      list<Value> comp,varlst;
      DAELow dlow;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      Variables ordvars;
      VariableArray varr;
    case (m,v1,v2,{},dlow) then ({},{});
    case (m,v1,v2,c::comp,dlow as DAELOW(orderedVars = ordvars as VARIABLES(varArr=varr)))
      equation
        v = v2[c];
        VAR(varName = cr) = vararrayNth(varr, v-1);
        (varlst,crlst) = getTearingVars(m,v1,v2,comp,dlow);
      then
        (v::varlst,cr::crlst);
  end matchcontinue;
end getTearingVars;

protected function tearingSystem2
" function: tearingSystem2
  Residualequation loop. This function
  select a residual equation.
  The equation with most connections to
  variables will be selected."
  input DAELow inDlow;
  input DAELow inDlow1;
  input IncidenceMatrix inM;
  input IncidenceMatrixT inMT;
  input Integer[:] inV1;
  input Integer[:] inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output DAELow outDlow;
  output DAELow outDlow1;
  output IncidenceMatrix outM;
  output IncidenceMatrixT outMT;
  output Integer[:] outV1;
  output Integer[:] outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      DAELow dlow,dlow_1,dlow1,dlow1_1;
      IncidenceMatrix m,m_1;
      IncidenceMatrixT mT,mT_1;
      Integer[:] v1,v2,v1_1,v2_1;
      list<Integer> tvars,vars,vars_1,comp,comp_1,exclude;
      String str,str1;
      Integer residualeqn;
      list<Integer> tearingvars,residualeqns,tearingvars_1,residualeqns_1,tearingeqns,tearingeqns_1;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        str = intString(residualeqn);
        str1 = stringAppend("ResidualEqn: ", str);
        Debug.fcall("tearingdump", print, str1);
         // get from mT variable with most equations
        vars = m[residualeqn];
        vars_1 = Util.listSelect1(vars,tvars,Util.listContains);
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars_1,{},residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
        // only succeed if tearing need less equations than system size is
//        true = listLength(tearingvars_1) < systemsize;
    then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        true = residualeqn > 0;
        // try next equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,residualeqn::exclude,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow,dlow1,m,mT,v1,v2,comp,tvars,exclude,residualeqns,tearingvars,tearingeqns,_)
      equation
        // get from eqn equation with most variables
        (residualeqn,_) = getMaxfromListList(m,comp,tvars,0,0,exclude);
        false = residualeqn > 0;
        Debug.fcall("tearingdump", print, "Select Residual Equation failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem2;

protected function tearingSystem3
" function: tearingSystem3
  TearingVar loop. This function select
  a tearing variable. The variable with
  most connections to equations will be
  selected."
  input DAELow inDlow;
  input DAELow inDlow1;
  input IncidenceMatrix inM;
  input IncidenceMatrixT inMT;
  input Integer[:] inV1;
  input Integer[:] inV2;
  input list<Integer> inComp;
  input list<Integer> inTVars;
  input list<Integer> inExclude;
  input Integer inResEqn;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output DAELow outDlow;
  output DAELow outDlow1;
  output IncidenceMatrix outM;
  output IncidenceMatrixT outMT;
  output Integer[:] outV1;
  output Integer[:] outV2;
  output list<Integer> outComp;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComp,inTVars,inExclude,inResEqn,inResEqns,inTearVars,inTearEqns,inCrlst)
    local
      DAELow dlow,dlow_1,dlow_2,dlow_3,dlow1,dlow1_1,dlow1,dlow1_1,dlow1_2,dlowc,dlowc1;
      IncidenceMatrix m,m_1,m_2,m_3;
      IncidenceMatrixT mT,mT_1,mT_2,mT_3;
      Integer[:] v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1,lstm,lstmp,onecomp,morecomps;
      list<Integer> vars,comp,comp_1,comp_2,r,t,exclude,b,cmops_flat,onecomp_flat,othereqns,resteareqns;
      String str,str1,str2;
      Integer tearingvar,residualeqn,compcount,tearingeqnid;
      list<Integer> residualeqns,residualeqns_1,tearingvars,tearingvars_1,tearingeqns,tearingeqns_1,tearingeqns_2;
      DAE.ComponentRef cr,crt;
      list<DAE.ComponentRef> crlst;
      DAE.Ident ident,ident_t;
      VariableArray varr;
      Value nvars,neqns,memsize;
      Variables ordvars,vars_1,knvars,exobj,ordvars1;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      Assignments assign1,assign2,assign1_1,assign2_1,ass1,ass2;
      EquationArray eqns, eqns_1, eqns_2,removedEqs,remeqns,inieqns,eqns1,eqns1_1,eqns1_2;
      MultiDimEquation[:] arreqns;
      DAE.Algorithm[:] algorithms;
      EventInfo einfo;
      ExternalObjectClasses eoc;
      DAE.Exp eqn,eqn_1,scalar,scalar_1;
      DAE.ElementSource source;
      DAE.ExpType identType;
      list<DAE.Subscript> subscriptLst;
      Integer replace,replace1;
    case (dlow,dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        true = tearingvar > 0;
        str = intString(tearingvar);
        str1 = stringAppend("\nTearingVar: ", str);
        str2 = stringAppend(str1,"\n");
        Debug.fcall("tearingdump", print, str2);
        // copy dlow
        dlowc = copyDaeLowforTearing(dlow);
        DAELOW(ordvars as VARIABLES(varArr=varr),knvars,exobj,av,eqns,remeqns,inieqns,arreqns,algorithms,einfo,eoc) = dlowc;
        dlowc1 = copyDaeLowforTearing(dlow1);
        DAELOW(orderedVars = ordvars1,orderedEqs = eqns1) = dlowc1;
        // add Tearing Var
        VAR(varName = cr as DAE.CREF_IDENT(ident = ident, identType = identType, subscriptLst = subscriptLst )) = vararrayNth(varr, tearingvar-1);
        ident_t = stringAppend("tearingresidual_",ident);
        crt = DAE.CREF_IDENT(ident_t,identType,subscriptLst);
         vars_1 = addVar(VAR(crt, VARIABLE(),DAE.BIDIR(),REAL(),NONE,NONE,{},-1,DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,SOME(DAE.BCONST(true)),NONE,NONE,NONE,NONE,NONE)),
                            NONE,DAE.NON_CONNECTOR(),DAE.NON_STREAM()), ordvars);
        // replace in residual equation orgvar with Tearing Var
        EQUATION(eqn,scalar,source) = equationNth(eqns,residualeqn-1);
//        (eqn_1,replace) =  Exp.replaceExp(eqn,DAE.CREF(cr,DAE.ET_REAL()),DAE.CREF(crt,DAE.ET_REAL()));
//        (scalar_1,replace1) =  Exp.replaceExp(scalar,DAE.CREF(cr,DAE.ET_REAL()),DAE.CREF(crt,DAE.ET_REAL()));
//        true = replace + replace1 > 0;
        // Add Residual eqn
        eqns_1 = equationSetnth(eqns,residualeqn-1,EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),DAE.CREF(crt,DAE.ET_REAL()),source));
        eqns1_1 = equationSetnth(eqns1,residualeqn-1,EQUATION(DAE.BINARY(eqn,DAE.SUB(DAE.ET_REAL()),scalar),DAE.RCONST(0.0),source));
        // add equation to calc org var
        eqns_2 = equationAdd(eqns_1,EQUATION(DAE.CALL(Absyn.IDENT("tearing"),
                          {},false,true,DAE.ET_REAL(),DAE.NO_INLINE()),
                          DAE.CREF(cr,DAE.ET_REAL()), DAE.emptyElementSource));
        tearingeqnid = equationSize(eqns_2);
        dlow_1 = DAELOW(vars_1,knvars,exobj,av,eqns_2,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        dlow1_1 = DAELOW(ordvars1,knvars,exobj,av,eqns1_1,remeqns,inieqns,arreqns,algorithms,einfo,eoc);
        // try causalisation
        m_1 = incidenceMatrix(dlow_1);
        mT_1 = transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mT_1);
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        // try matching
        checkMatching(dlow_1, (NO_INDEX_REDUCTION(), EXACT(), KEEP_SIMPLE_EQN()));
        Debug.fcall("tearingdump", dumpIncidenceMatrix, m_1);
        Debug.fcall("tearingdump", dumpIncidenceMatrixT, mT_1);
        Debug.fcall("tearingdump", dump, dlow_1);
        (ass1,ass2,dlow_2,m_2,mT_2,_,_) = matchingAlgorithm2(dlow_1, m_1, mT_1, nvars, neqns, 1, assign1, assign2, (NO_INDEX_REDUCTION(), EXACT(), KEEP_SIMPLE_EQN()),DAEUtil.avlTreeNew(),{},{});
        v1_1 = assignmentsVector(ass1);
        v2_1 = assignmentsVector(ass2);
        (comps) = strongComponents(m_2, mT_2, v1_1, v2_1);
        Debug.fcall("tearingdump", dumpMatching, v1_1);
        Debug.fcall("tearingdump", dumpComponents, comps);
        // check strongComponents and split it into two lists: len(comp)==1 and len(comp)>1
        (morecomps,onecomp) = splitComps(comps);
        // try to solve the equations
        onecomp_flat = Util.listFlatten(onecomp);
        // remove residual equations and tearing eqns
        resteareqns = listAppend(tearingeqnid::tearingeqns,residualeqn::residualeqns);
        othereqns = Util.listSelect1(onecomp_flat,resteareqns,Util.listNotContains);
        eqns1_2 = solveEquations(eqns1_1,othereqns,v2_1,vars_1,crlst);
         // if we have not make alle equations causal select next residual equation
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comps_1,compcount) = tearingSystem4(dlow_2,dlow1_1,m_2,mT_2,v1_1,v2_1,comps,residualeqn::residualeqns,tearingvar::tearingvars,tearingeqnid::tearingeqns,comp,0,crlst);
        // check
        true = ((listLength(residualeqns_1) > listLength(residualeqns)) and
                (listLength(tearingvars_1) > listLength(tearingvars)) ) or (compcount == 0);
        // get specifig comps
        cmops_flat = Util.listFlatten(comps_1);
        comp_2 = Util.listSelect1(cmops_flat,comp,Util.listContains);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_3,dlow1_2,m_3,mT_3,v1_2,v2_2,comp_2);
    case (dlow as DAELOW(orderedVars = VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        true = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        // try next TearingVar
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem3(dlow,dlow1,m,mT,v1,v2,comp,vars,tearingvar::exclude,residualeqn,residualeqns,tearingvars,tearingeqns,crlst);
      then
        (residualeqns_1,tearingvars_1,tearingeqns_1,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1);
    case (dlow as DAELOW(orderedVars = VARIABLES(varArr=varr)),dlow1,m,mT,v1,v2,comp,vars,exclude,residualeqn,residualeqns,tearingvars,tearingeqns,_)
      equation
        (tearingvar,_) = getMaxfromListList(mT,vars,comp,0,0,exclude);
        // check if tearing var is found
        false = tearingvar > 0;
        // clear errors
        Error.clearMessages();
        Debug.fcall("tearingdump", print, "Select Tearing Var failed\n");
      then
        fail();
  end matchcontinue;
end tearingSystem3;

protected function tearingSystem4
" function: tearingSystem4
  autor: Frenkel TUD
  Internal Main loop for additional
  tearing vars and residual eqns."
  input DAELow inDlow;
  input DAELow inDlow1;
  input IncidenceMatrix inM;
  input IncidenceMatrixT inMT;
  input Integer[:] inV1;
  input Integer[:] inV2;
  input list<list<Integer>> inComps;
  input list<Integer> inResEqns;
  input list<Integer> inTearVars;
  input list<Integer> inTearEqns;
  input list<Integer> inComp;
  input Integer inCompCount;
  input list<DAE.ComponentRef> inCrlst;
  output list<Integer> outResEqns;
  output list<Integer> outTearVars;
  output list<Integer> outTearEqns;
  output DAELow outDlow;
  output DAELow outDlow1;
  output IncidenceMatrix outM;
  output IncidenceMatrixT outMT;
  output Integer[:] outV1;
  output Integer[:] outV2;
  output list<list<Integer>> outComp;
  output Integer outCompCount;
algorithm
  (outResEqns,outTearVars,outTearEqns,outDlow,outDlow1,outM,outMT,outV1,outV2,outComp,outCompCount):=
  matchcontinue (inDlow,inDlow1,inM,inMT,inV1,inV2,inComps,inResEqns,inTearVars,inTearEqns,inComp,inCompCount,inCrlst)
    local
      DAELow dlow,dlow_1,dlow_2,dlow1,dlow1_1,dlow1_2;
      IncidenceMatrix m,m_1,m_2;
      IncidenceMatrixT mT,mT_1,mT_2;
      Integer[:] v1,v2,v1_1,v2_1,v1_2,v2_2;
      list<list<Integer>> comps,comps_1;
      list<Integer> tvars,comp,comp_1,tearingvars,residualeqns,ccomp,r,t,r_1,t_1,te,te_1,tearingeqns;
      Integer ll,compcount,compcount_1,compcount_2;
      list<Boolean> checklst;
      list<DAE.ComponentRef> crlst;
    case (dlow,dlow1,m,mT,v1,v2,{},r,t,te,ccomp,compcount,crlst)
      then
        (r,t,te,dlow,dlow1,m,mT,v1,v2,{},compcount);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // get all interesting vars
        (tvars,_) = getTearingVars(m,v1,v2,comp,dlow);
        // try tearing
        (residualeqns,tearingvars,tearingeqns,dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comp_1) = tearingSystem2(dlow,dlow1,m,mT,v1,v2,comp,tvars,{},r,t,te,crlst);
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow_1,dlow1_1,m_1,mT_1,v1_1,v2_1,comps,residualeqns,tearingvars,tearingeqns,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_2,m_2,mT_2,v1_2,v2_2,comp_1::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // block ?
        ll = listLength(comp);
        true = ll > 1;
        // check block
        checklst = Util.listMap1(comp,Util.listContains,ccomp);
        true = Util.listContains(true,checklst);
        // this is a block
        compcount_1 = compcount + 1;
        // next Block
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_2) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount_1,crlst);
      then
        (r_1,t_1,tearingeqns,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_2);
    case (dlow,dlow1,m,mT,v1,v2,comp::comps,r,t,te,ccomp,compcount,crlst)
      equation
        // next Block
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comps_1,compcount_1) = tearingSystem4(dlow,dlow1,m,mT,v1,v2,comps,r,t,te,ccomp,compcount,crlst);
      then
        (r_1,t_1,te_1,dlow_2,dlow1_1,m_2,mT_2,v1_2,v2_2,comp::comps_1,compcount_1);
  end matchcontinue;
end tearingSystem4;

protected function getMaxfromListList
" function: getMaxfromArrayList
  helper for tearingSystem2 and tearingSystem3
  This function select the equation/variable
  with most connections to variables/equations.
  If more than once is there the first will
  be selected."
  input IncidenceMatrixT inM;
  input list<Value> inLst;
  input list<Value> inComp;
  input Value inMax;
  input Value inEqn;
  input list<Value> inExclude;
  output Value outEqn;
  output Value outMax;
algorithm
  (outEqn,outMax):=
  matchcontinue (inM,inLst,inComp,inMax,inEqn,inExclude)
    local
      IncidenceMatrixT m;
      list<Value> rest,eqn,eqn_1,eqn_2,eqn_3,comp,exclude;
      Value v,v1,v2,max,max_1,en,en_1,en_2;
    case (m,{},comp,max,en,exclude) then (en,max);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_1,max_1) = getMaxfromListList(m,rest,comp,max,en,exclude);
        true = v > 0;
        false = Util.listContains(v,exclude);
        eqn = m[v];
        // remove negative
        eqn_1 = removeNegative(eqn);
        // select entries
        eqn_2 = Util.listSelect1(eqn_1,comp,Util.listContains);
        // remove multiple entries
        eqn_3 = removeMultiple(eqn_2);
        v1 = listLength(eqn_3);
        v2 = intMax(v1,max_1);
        en_2 = Util.if_(v1>max_1,v,en_1);
      then
        (en_2,v2);
    case (m,v::rest,comp,max,en,exclude)
      equation
        (en_2,v2) = getMaxfromListList(m,rest,comp,max,en,exclude);
      then
        (en_2,v2);
  end matchcontinue;
end getMaxfromListList;

protected function removeMultiple
" function: removeMultiple
  remove mulitple entries from the list"
  input list<Value> inLst;
  output list<Value> outLst;
algorithm
  outLst:=
  matchcontinue (inLst)
    local
      list<Value> rest,lst;
      Value v;
    case ({}) then {};
    case (v::{})
      then
        {v};
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        false = Util.listContains(v,lst);
      then
        (v::lst);
    case (v::rest)
      equation
        lst = removeMultiple(rest);
        true = Util.listContains(v,lst);
      then
        lst;
  end matchcontinue;
end removeMultiple;

protected function splitComps
" function: splitComps
  splits the comp in two list
  1: len(comp) == 1
  2: len(comp) > 1"
  input list<list<Integer>> inComps;
  output list<list<Integer>> outComps;
  output list<list<Integer>> outComps1;
algorithm
  (outComps,outComps1):=
  matchcontinue (inComps)
    local
      list<list<Integer>> rest,comps,comps1;
      list<Integer> comp;
      Integer v;
    case ({}) then ({},{});
    case ({v}::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comps,{v}::comps1);
    case (comp::rest)
      equation
        (comps,comps1) = splitComps(rest);
      then
        (comp::comps,comps1);
  end matchcontinue;
end splitComps;

protected function solveEquations
" function: solveEquations
  try to solve the equations"
  input EquationArray inEqnArray;
  input list<Integer> inEqns;
  input Integer[:] inAssigments;
  input Variables inVars;
  input list<DAE.ComponentRef> inCrlst;
  output EquationArray outEqnArray;
algorithm
  outEqnArray:=
  matchcontinue (inEqnArray,inEqns,inAssigments,inVars,inCrlst)
    local
      EquationArray eqns,eqns_1,eqns_2;
      list<Integer> rest;
      Integer e,e_1,v,v_1;
      Integer[:] ass;
      Variables vars;
      DAE.Exp e1,e2,varexp,expr;
      list<DAE.Exp> divexplst,constexplst,nonconstexplst,tfixedexplst,tnofixedexplst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<list<DAE.ComponentRef>> crlstlst;
      DAE.ElementSource source;
      VariableArray varr;
      list<Boolean> blst,blst_1;
      list<list<Boolean>> blstlst;
      list<String> s;
    case (eqns,{},ass,vars,crlst) then eqns;
    case (eqns,e::rest,ass,vars as VARIABLES(varArr=varr),crlst)
      equation
        e_1 = e - 1;
        EQUATION(e1,e2,source) = equationNth(eqns, e_1);
        v = ass[e_1 + 1];
        v_1 = v - 1;
        VAR(varName=cr) = vararrayNth(varr, v_1);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        divexplst = Exp.extractDivExpFromExp(expr);
        (constexplst,nonconstexplst) = Util.listSplitOnTrue(divexplst,Exp.isConst);
        // check constexplst if equal 0
        blst = Util.listMap(constexplst, Exp.isZero);
        false = Util.boolOrList(blst);
        // check nonconstexplst if tearing variables or variables which will be
        // changed during solving process inside
        crlstlst = Util.listMap(nonconstexplst,Exp.extractCrefsFromExp);
        // add explst with variables which will not be changed during solving prozess
        blstlst = Util.listListMap2(crlstlst,Util.listContainsWithCompareFunc,crlst,Exp.crefEqual);
        blst_1 = Util.listMap(blstlst,Util.boolOrList);
        (tnofixedexplst,tfixedexplst) = listSplitOnTrue(nonconstexplst,blst_1);
        true = listLength(tnofixedexplst) < 1;
/*        print("\ntfixedexplst DivExpLst:\n");
        s = Util.listMap(tfixedexplst, Exp.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
        print("\ntnofixedexplst DivExpLst:\n");
        s = Util.listMap(tnofixedexplst, Exp.printExpStr);
        Util.listMap0(s,print);
        print("\n===============================\n");
*/        eqns_1 = equationSetnth(eqns,e_1,EQUATION(expr,varexp,source));
        eqns_2 = solveEquations(eqns_1,rest,ass,vars,crlst);
      then
        eqns_2;
  end matchcontinue;
end solveEquations;

public function listSplitOnTrue "Splits a list into two sublists depending on second list of bools"
  input list<Type_a> lst;
  input list<Boolean> blst;
  output list<Type_a> tlst;
  output list<Type_a> flst;
  replaceable type Type_a subtypeof Any;
algorithm
  (tlst,flst) := matchcontinue(lst,blst)
  local Type_a l;
    case({},{}) then ({},{});
    case(l::lst,true::blst) equation
      (tlst,flst) = listSplitOnTrue(lst,blst);
    then (l::tlst,flst);
    case(l::lst,false::blst) equation
      (tlst,flst) = listSplitOnTrue(lst,blst);
    then (tlst,l::flst);
  end matchcontinue;
end listSplitOnTrue;

protected function transformDelayExpression
"Insert a unique index into the arguments of a delay() expression.
Repeat delay as maxDelay if not present."
  input tuple<DAE.Exp, Integer> inTuple;
  output tuple<DAE.Exp, Integer> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e, e1, e2, e3;
      Integer i;
      list<DAE.Exp> l;
      Boolean t, b;
      DAE.ExpType ty;
      DAE.InlineType it;
    case ((DAE.CALL(Absyn.IDENT("delay"), {e1, e2}, t, b, ty, it), i))
      then ((DAE.CALL(Absyn.IDENT("delay"), {DAE.ICONST(i), e1, e2, e2}, t, b, ty, it), i + 1));
    case ((DAE.CALL(Absyn.IDENT("delay"), {e1, e2, e3}, t, b, ty, it), i))
      then ((DAE.CALL(Absyn.IDENT("delay"), {DAE.ICONST(i), e1, e2, e3}, t, b, ty, it), i + 1));
    case ((e, i)) then ((e, i));
  end matchcontinue;
end transformDelayExpression;

protected function transformDelayExpressions
"Helper for processDelayExpressions()"
  input DAE.Exp inExp;
  input Integer inInteger;
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  ((outExp, outInteger)) := Exp.traverseExp(inExp, transformDelayExpression, inInteger);
end transformDelayExpressions;

public function processDelayExpressions
"Assign each call to delay() with a unique id argument"
  input DAE.DAElist inDAE;
  output DAE.DAElist outDAE;
algorithm
  outDAE := matchcontinue(inDAE)
    local
      DAE.DAElist dae, dae2;
    case (dae)
      equation
        (dae2,_) = DAEUtil.traverseDAE(dae, transformDelayExpressions, 0);
      then
        dae2;
  end matchcontinue;
end processDelayExpressions;

protected function collectDelayExpressions
"Put expression into a list if it is a call to delay().
Useable as a function parameter for Exp.traverseExp."
  input tuple<DAE.Exp, list<DAE.Exp>> inTuple;
  output tuple<DAE.Exp, list<DAE.Exp>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      list<DAE.Exp> l;
    case ((e as DAE.CALL(path = Absyn.IDENT("delay")), l))
      then ((e, e :: l));
    case ((e, l)) then ((e, l));
  end matchcontinue;
end collectDelayExpressions;

public function findDelaySubExpressions
"Return all subexpressions of inExp that are calls to delay()"
  input DAE.Exp inExp;
  output list<DAE.Exp> outExps;
algorithm
  ((_, outExps)) := Exp.traverseExp(inExp, collectDelayExpressions, {});
end findDelaySubExpressions;

public function addDivExpErrorMsgtoExp "
Author: Frenkel TUD 2010-02, Adds the error msg to Exp.Div.
"
input DAE.Exp inExp;
input tuple<DAELow,DivZeroExpReplace> inDlowMode;
output DAE.Exp outExp;
output list<DAE.Exp> outDivLst;
algorithm 
  (outExps,outDivLst) := matchcontinue(inExp,inDlowMode)
  case(inExp,inDlowMode as (dlow,dzer))
    local 
      DAE.Exp exp; 
      DAELow dlow;
      DivZeroExpReplace dzer;
      list<DAE.Exp> divlst;
    equation
      ((exp,(_,_,divlst))) = Exp.traverseExp(inExp, traversingDivExpFinder, (dlow,dzer,{}));
      then
        (exp,divlst);
  end matchcontinue;
end addDivExpErrorMsgtoExp;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02"
  input tuple<DAE.Exp, tuple<DAELow,DivZeroExpReplace,list<DAE.Exp>> > inExp;
  output tuple<DAE.Exp, tuple<DAELow,DivZeroExpReplace,list<DAE.Exp>> > outExp;
algorithm
outExp := matchcontinue(inExp)
  local
    DAELow dlow;
    DivZeroExpReplace dzer;
    list<DAE.Exp> divLst;
    tuple<DAELow,DivZeroExpReplace,list<DAE.Exp>> dlowmode;
    DAE.Exp e,e1,e2;
    Exp.Type ty;
    String se;
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2), dlowmode as (dlow,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(dlow,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (dlow,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2), dlowmode as (dlow,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(dlow,dzer));
    then ((e, (dlow,dzer,DAE.CALL(Absyn.IDENT("DIVISION"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
/*
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARR(ty),exp2 = e2), dlowmode as (dlow,_)))
    then ((e, dlowmode ));
*/    
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), dlowmode as (dlow,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(dlow,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (dlow,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), dlowmode as (dlow,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(dlow,dzer));
    then ((e, (dlow,dzer,DAE.CALL(Absyn.IDENT("DIVISION"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), dlowmode as (dlow,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(dlow,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (dlow,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), dlowmode as (dlow,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(dlow,dzer));
    then ((e, (dlow,dzer,DAE.CALL(Absyn.IDENT("DIVISION"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
  case(inExp) then (inExp);
end matchcontinue;
end traversingDivExpFinder;

protected function traversingDivExpFinder1 "
Author: Frenkel TUD 2010-02 
  helper for traversingDivExpFinder"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input tuple<DAELow,DivZeroExpReplace> inMode;
  output String outString;
  output Boolean outBool;
algorithm
  (outString,outBool) := matchcontinue(inExp1,inExp2,inMode)
  local
    DAELow dlow;
    tuple<DAELow,DivZeroExpReplace> dlowmode;
    DAE.Exp e,e2;
    String se;
    list<DAE.ComponentRef> crlst;
    Variables orderedVars,knownVars,vars;
    list<Var> varlst,varlst1,varlst2;
    list<Boolean> boollst;
    Boolean bres;
  case( e , e2, dlowmode as (dlow as DAELOW(orderedVars=orderedVars,knownVars=knownVars),ALL()) )
    equation
      crlst = Exp.extractCrefsFromExp(e2);
      varlst = varList(orderedVars);
      varlst1 = varList(knownVars);
      varlst2 = listAppend(varlst,varlst1);  
      vars = listVar(varlst2);          
      /* generade modelica strings */
      e = removeDivExpErrorMsgfromExp(e,dlow);
      e2 = removeDivExpErrorMsgfromExp(e2,dlow);
      se = generadeDivExpErrorMsg(e,e2,vars,crlst);
    then (se,false);    
  case( e , e2, dlowmode as (dlow as DAELOW(orderedVars=orderedVars,knownVars=knownVars),ONLY_VARIABLES()) )
    equation
      /* check if expression contains variables */
      crlst = Exp.extractCrefsFromExp(e2);
      varlst = varList(orderedVars);
      varlst1 = varList(knownVars);
      varlst2 = listAppend(varlst,varlst1);
      vars = listVar(varlst2);
      boollst = Util.listMap1r(crlst,isVarKnown,varlst);
      bres = Util.boolOrList(boollst);
      /* generade modelica strings */
      e = removeDivExpErrorMsgfromExp(e,dlow);
      e2 = removeDivExpErrorMsgfromExp(e2,dlow);
      se = generadeDivExpErrorMsg(e,e2,vars,crlst);
    then (se,bres);
end matchcontinue;
end traversingDivExpFinder1;

protected  function generadeDivExpErrorCrefRepl "
Author: Frenkel TUD 2010-02. generadeDivExpErrorCrefRepl
"
input list<DAE.ComponentRef> inCrs;
input Variables inVars;
output list<DAE.Exp> outCrs;
output list<DAE.Exp> outOrigCrs;
algorithm 
  (outCrs,outOrigCrs) := matchcontinue(inCrs,inVars)
    local 
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> crefs1,corefs;
      DAE.ComponentRef c,co;
      Variables variables;
    case(c::{},variables)
      equation
        ((VAR(varName=co):: _),_) = getVar(c,variables);
      then
        ({DAE.CREF(c,DAE.ET_OTHER())},{DAE.CREF(co,DAE.ET_OTHER())});
    case(c::{},variables)
      then
        ({DAE.CREF(c,DAE.ET_OTHER())},{DAE.CREF(c,DAE.ET_OTHER())});
    case(c::crefs,variables)
      equation
        ((VAR(varName=co):: _),_) = getVar(c,variables);
        (crefs1,corefs) = generadeDivExpErrorCrefRepl(crefs,variables);
      then
        (DAE.CREF(c,DAE.ET_OTHER())::crefs1,DAE.CREF(co,DAE.ET_OTHER())::corefs);
    case(c::crefs,variables)
      equation
        (crefs1,corefs) = generadeDivExpErrorCrefRepl(crefs,variables);
      then
        (crefs1,corefs);
  end matchcontinue;
end generadeDivExpErrorCrefRepl;

protected  function generadeDivExpErrorMsg "
Author: Frenkel TUD 2010-02. varOrigCref
"
input DAE.Exp inExp;
input DAE.Exp inDivisor;
input Variables inVars;
input list<DAE.ComponentRef> inCrs;
output String outString;
protected String se,se2,s,s1;
protected list<DAE.Exp> crs,cors;
protected DAE.Exp e1,e2;
protected Integer i;
algorithm
  (crs,cors) := generadeDivExpErrorCrefRepl(inCrs,inVars);
  (e1,i) := Exp.replaceExpList(inExp,crs,cors);
  (e2,i) := Exp.replaceExpList(inDivisor,crs,cors);
  se := Exp.printExpStr(e1);
  se2 := Exp.printExpStr(e2);
  s := stringAppend(se," because ");
  s1 := stringAppend(s,se2);
  outString := stringAppend(s1," == 0");
end generadeDivExpErrorMsg;

protected  function removeDivExpErrorMsgfromExp "
Author: Frenkel TUD 2010-02, Removes the error msg from Exp.Div.
"
input DAE.Exp inExp;
input DAELow inDlow;
output DAE.Exp outExp;
algorithm outExps := matchcontinue(inExp,inDlow)
  case(inExp,inDlow)
    local DAE.Exp exp;
    equation
      ((exp,_)) = Exp.traverseExp(inExp, traversingDivExpFinder2, inDlow);
      then
        exp;
  end matchcontinue;
end removeDivExpErrorMsgfromExp;

protected function traversingDivExpFinder2 "
Author: Frenkel TUD 2010-02"
  input tuple<DAE.Exp, DAELow > inExp;
  output tuple<DAE.Exp, DAELow > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    DAELow dlow;
    DAE.Exp e,e1,e2;
    Exp.Type ty;
    Absyn.Path path;
    list<DAE.Exp> expLst;
    Boolean tuple_;
    Boolean builtin;
    DAE.ExpType ty;
    DAE.InlineType inlineType;    
  case( (e as DAE.CALL(path = Absyn.IDENT("DIVISION"), expLst = {e1,e2,DAE.SCONST(_)}, tuple_ = false,builtin = true,ty = ty,inlineType = DAE.NO_INLINE()), dlow ))
    then ((DAE.BINARY(e1, DAE.DIV(ty),e2), dlow ));
  case( (e as DAE.CALL(path = Absyn.IDENT("DIVISION_ARRAY_SCALAR"),expLst = {e1,e2,DAE.SCONST(_)}, tuple_ = false,builtin = true,ty =ty,inlineType = DAE.NO_INLINE()), dlow ))
    then ((DAE.BINARY(e1,DAE.DIV_ARRAY_SCALAR(ty),e2), dlow ));
  case( (e as DAE.CALL(path = Absyn.IDENT("DIVISION_SCALAR_ARRAY"),expLst = {e1,e2,DAE.SCONST(_)}, tuple_ = false,builtin = true,ty =ty,inlineType = DAE.NO_INLINE()), dlow ))
    then ((DAE.BINARY(e1,DAE.DIV_SCALAR_ARRAY(ty),e2), dlow ));
  case(inExp) then inExp;
end matchcontinue;
end traversingDivExpFinder2;

protected function extendRecordEqns "
Author: Frenkel TUD 2010-05"
  input Equation inEqn;
  input DAE.FunctionTree inFuncs;
  output tuple<list<Equation>,list<MultiDimEquation>> outTuplEqnLst;
algorithm 
  outTuplEqnLst := matchcontinue(inEqn,inFuncs)
  local
    DAE.FunctionTree funcs;
    Equation eqn;
    DAE.ComponentRef cr1,cr2;
    DAE.Exp e1,e2;
    list<DAE.Exp> e1lst,e2lst;
    list<DAE.ExpVar> varLst;
    Integer i;
    list<tuple<list<Equation>,list<MultiDimEquation>>> compmultilistlst,compmultilistlst1;
    list<list<MultiDimEquation>> multiEqsLst,multiEqsLst1;
    list<list<Equation>> complexEqsLst,complexEqsLst1;
    list<MultiDimEquation> multiEqs,multiEqs1,multiEqs2;  
    list<Equation> complexEqs,complexEqs1;  
    DAE.ElementSource source;  
    Absyn.Path path,fname;
    list<DAE.Exp> expLst;
    list<tuple<DAE.Exp,DAE.Exp>> exptpllst;
  // a=b
  case (COMPLEX_EQUATION(index=i,lhs = e1 as DAE.CREF(componentRef=cr1), rhs = e2  as DAE.CREF(componentRef=cr2),source = source),funcs)
    equation
      // create as many equations as the dimension of the record
      DAE.ET_COMPLEX(varLst=varLst) = Exp.crefLastType(cr1);
      e1lst = Util.listMap1(varLst,generateCrefsExpFromType,e1);
      e2lst = Util.listMap1(varLst,generateCrefsExpFromType,e2);
      exptpllst = Util.listThreadTuple(e1lst,e2lst);
      compmultilistlst = Util.listMap2(exptpllst,generateextendedRecordEqn,source,funcs);
      complexEqsLst = Util.listMap(compmultilistlst,Util.tuple21);
      multiEqsLst = Util.listMap(compmultilistlst,Util.tuple22);
      complexEqs = Util.listFlatten(complexEqsLst);
      multiEqs = Util.listFlatten(multiEqsLst);
      // nested Records
      compmultilistlst1 = Util.listMap1(complexEqs,extendRecordEqns,funcs);
      complexEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple21);
      multiEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple22);
      complexEqs1 = Util.listFlatten(complexEqsLst1);
      multiEqs1 = Util.listFlatten(multiEqsLst1);
      multiEqs2 = listAppend(multiEqs,multiEqs1);
    then
      ((complexEqs1,multiEqs2)); 
  // a=Record()
  case (COMPLEX_EQUATION(index=i,lhs = e1 as DAE.CREF(componentRef=cr1), rhs = e2  as DAE.CALL(path=path,expLst=expLst),source = source),funcs)
    equation
      DAE.RECORD_CONSTRUCTOR(path=fname) = DAEUtil.avlTreeGet(funcs,path);
      // create as many equations as the dimension of the record
      DAE.ET_COMPLEX(varLst=varLst) = Exp.crefLastType(cr1);
      e1lst = Util.listMap1(varLst,generateCrefsExpFromType,e1);
      exptpllst = Util.listThreadTuple(e1lst,expLst);
      compmultilistlst = Util.listMap2(exptpllst,generateextendedRecordEqn,source,funcs);
      complexEqsLst = Util.listMap(compmultilistlst,Util.tuple21);
      multiEqsLst = Util.listMap(compmultilistlst,Util.tuple22);
      complexEqs = Util.listFlatten(complexEqsLst);
      multiEqs = Util.listFlatten(multiEqsLst);
      // nested Records
      compmultilistlst1 = Util.listMap1(complexEqs,extendRecordEqns,funcs);
      complexEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple21);
      multiEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple22);
      complexEqs1 = Util.listFlatten(complexEqsLst1);
      multiEqs1 = Util.listFlatten(multiEqsLst1);
      multiEqs2 = listAppend(multiEqs,multiEqs1);
    then
      ((complexEqs1,multiEqs2)); 
  case(eqn,_) then (({eqn},{}));      
end matchcontinue;
end extendRecordEqns;

protected function generateCrefsExpFromType "
Author: Frenkel TUD 2010-05"
  input DAE.ExpVar inVar;
  input DAE.Exp inExp;
  output DAE.Exp outCrefExp;
algorithm outCrefExp := matchcontinue(inVar,inExp)
  local
    String name;
    DAE.ExpType tp;
    DAE.ComponentRef cr,cr1;
    DAE.Exp e;
  case (DAE.COMPLEX_VAR(name=name,tp=tp),DAE.CREF(componentRef=cr))
  equation
    cr1 = Exp.extendCref(cr,tp,name,{});
		e = DAE.CREF(cr1, tp);
  then
    e;
 end matchcontinue;
end generateCrefsExpFromType;

protected function generateextendedRecordEqn "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inExp;
  input DAE.ElementSource Source;
  input DAE.FunctionTree inFuncs;
  output tuple<list<Equation>,list<MultiDimEquation>> outTuplEqnLst;
algorithm 
  outTuplEqnLst := matchcontinue(inExp,Source,inFuncs)
  local
    DAE.Exp e1,e2,e1_1,e2_1,e2_2;
    list<DAE.Exp> e1lst, e2lst;
    DAE.ElementSource source;
    DAE.ComponentRef cr1,cr2;
    list<DAE.ComponentRef> crlst1,crlst2;
    Equation eqn;
    list<Equation> eqnlst;
    list<tuple<DAE.Exp,DAE.Exp>> exptplst;
    list<list<DAE.Subscript>> subslst,subslst1;
    Exp.Type tp;
    list<Option<Integer>> ad;
    list<list<Integer>> dss;
    list<Integer> ds;
  // array types to array equations  
  case ((e1 as DAE.CREF(componentRef=cr1,ty=DAE.ET_ARRAY(arrayDimensions=ad)),e2),source,inFuncs)
  equation 
    (e1_1,_) = extendArrExp(e1,SOME(inFuncs));
    (e2_1,_) = extendArrExp(e2,SOME(inFuncs));
    e2_2 = Exp.simplify(e2_1);
    dss = Util.listMap(ad,Util.genericOption);
    ds = Util.listFlatten(dss);
  then
    (({},{MULTIDIM_EQUATION(ds,e1_1,e2_2,source)}));
  // other types  
  case ((e1 as DAE.CREF(componentRef=cr1),e2),source,inFuncs)
  equation 
    tp = Exp.typeof(e1);
    false = DAEUtil.expTypeComplex(tp);
    (e1_1,_) = extendArrExp(e1,SOME(inFuncs));
    (e2_1,_) = extendArrExp(e2,SOME(inFuncs));
    e2_2 = Exp.simplify(e2_1);
    eqn = generateEQUATION((e1_1,e2_2),source);
  then
    (({eqn},{}));    
  // complex type
  case ((e1,e2),source,inFuncs)
  equation 
    tp = Exp.typeof(e1);
    true = DAEUtil.expTypeComplex(tp);
  then
    (({COMPLEX_EQUATION(-1,e1,e2,source)},{}));    
 end matchcontinue;
end generateextendedRecordEqn;

public function arrayDimensionsToRange "
Author: Frenkel TUD 2010-05"
  input list<Option<Integer>> dims;
  output list<list<DAE.Subscript>> outRangelist;
algorithm
  outRangelist := matchcontinue(dims)
  local 
    Integer i;
    list<list<DAE.Subscript>> rangelist;
    list<Integer> range;
    list<DAE.Subscript> subs;
    case({}) then {};
    case(NONE::dims) equation
      rangelist = arrayDimensionsToRange(dims);
    then {}::rangelist;
    case(SOME(i)::dims) equation
      range = Util.listIntRange(i);
      subs = rangesToSubscript(range);
      rangelist = arrayDimensionsToRange(dims);
    then subs::rangelist;
  end matchcontinue;
end arrayDimensionsToRange;

protected function rangesToSubscript "
Author: Frenkel TUD 2010-05"
  input list<Integer> inRange;
  output list<DAE.Subscript> outSubs;
algorithm
  outSubs := matchcontinue(inRange)
  local 
    Integer i;
    list<Integer> res;
    list<DAE.Subscript> range;
    case({}) then {};
    case(i::res) 
      equation
        range = rangesToSubscript(res);
      then DAE.INDEX(DAE.ICONST(i))::range;
  end matchcontinue;
end rangesToSubscript;

public function rangesToSubscripts "
Author: Frenkel TUD 2010-05"
  input list<list<DAE.Subscript>> inRangelist;
  output list<list<DAE.Subscript>> outSubslst;
algorithm
  outSubslst := matchcontinue(inRangelist)
  local 
    list<list<DAE.Subscript>> rangelist,rangelist1;
    list<list<list<DAE.Subscript>>> rangelistlst;
    list<DAE.Subscript> range;
    case({}) then {};
    case(range::{})
      equation
        rangelist = Util.listMap(range,Util.listCreate); 
      then rangelist;
    case(range::rangelist)
      equation
      rangelist = rangesToSubscripts(rangelist);
      rangelistlst = Util.listMap1(range,rangesToSubscripts1,rangelist);
      rangelist1 = Util.listFlatten(rangelistlst);
    then rangelist1;
  end matchcontinue;
end rangesToSubscripts;

protected function rangesToSubscripts1 "
Author: Frenkel TUD 2010-05"
  input DAE.Subscript inSub;
  input list<list<DAE.Subscript>> inRangelist;
  output list<list<DAE.Subscript>> outSubslst;
algorithm
  outSubslst := matchcontinue(inSub,inRangelist)
  local 
    list<list<DAE.Subscript>> rangelist,rangelist1;
    DAE.Subscript sub;
    case(sub,rangelist)
      equation
      rangelist1 = Util.listMap1r(rangelist,Util.listAddElementFirst,sub);
    then rangelist1;
  end matchcontinue;
end rangesToSubscripts1;

public function generateEQUATION "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inTpl;
  input DAE.ElementSource Source;
  output Equation outEqn;
algorithm outEqn := matchcontinue(inTpl,Source)
  local
    DAE.Exp e1,e2;
    DAE.ElementSource source;
  case ((e1,e2),source) then EQUATION(e1,e2,source);
 end matchcontinue;
end generateEQUATION;

public function crefPrefixDer
  "Appends $DER to a cref, so a => $DER.a"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := DAE.CREF_QUAL("$DER", DAE.ET_REAL(), {}, inCref);
end crefPrefixDer;

public function makeDerCref
  "Appends $DER to a cref and constructs a DAE.CREF from the resulting cref."
  input DAE.ComponentRef inCref;
  output DAE.Exp outCref;
algorithm
  outCref := DAE.CREF(DAE.CREF_QUAL("$DER", DAE.ET_REAL(), {}, inCref),
      DAE.ET_REAL());
end makeDerCref;

public function equationSource "Retrieve the source from a DAELow equation"
  input Equation eq;
  output DAE.ElementSource source;
algorithm
  source := matchcontinue eq
    case EQUATION(source=source) then source;
    case ARRAY_EQUATION(source=source) then source;
    case SOLVED_EQUATION(source=source) then source;
    case RESIDUAL_EQUATION(source=source) then source;
    case WHEN_EQUATION(source=source) then source;
    case ALGORITHM(source=source) then source;
    case COMPLEX_EQUATION(source=source) then source;
  end matchcontinue;
end equationSource;

public function equationInfo "Retrieve the line number information from a DAELow equation"
  input Equation eq;
  output Absyn.Info info;
algorithm
  info := DAEUtil.getElementSourceFileInfo(equationSource(eq));
end equationInfo;

end DAELow;
