package DAELow "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 DAELow.mo
  module:      DAELow
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
  in the BLT sorting.
"

public import DAE;
public import Exp;
public import Values;
public import Absyn;
public import Algorithm;

public 
uniontype VarKind "- Variabile kind"
  record VARIABLE end VARIABLE;

  record STATE end STATE;

  record DUMMY_DER end DUMMY_DER;

  record DUMMY_STATE end DUMMY_STATE;

  record DISCRETE end DISCRETE;

  record PARAM end PARAM;

  record CONST end CONST;
    
  record EXTOBJ 
    Absyn.Path fullClassName;
  end EXTOBJ;

end VarKind;

public 
uniontype Var "- Variables"
  record VAR
    Exp.ComponentRef varName "varName ; variable name" ;
    VarKind varKind "varKind ; Kind of variable" ;
    DAE.VarDirection varDirection "varDirection ; input, output or bidirectional" ;
    DAE.Type varType "varType ; builtin type or enumeration" ;
    Option<Exp.Exp> bindExp "bindExp ; Binding expression e.g. for parameters" ;
    Option<Values.Value> bindValue "bindValue ; binding value for parameters" ;
    DAE.InstDims arryDim "arryDim ; array dimensions on nonexpanded var" ;
    DAE.StartValue startValue "startValue ; value of start attribute" ;
    Integer index "index ; index in impl. vector" ;
    Exp.ComponentRef origVarName "origVarName ; original variable name" ;
    list<Absyn.Path> className "className ; classname variable belongs to" ;
    Option<DAE.VariableAttributes> values "values ; values on builtin attributes" ;
    Option<Absyn.Comment> comment "comment ; this contains the comment and annotation from Absyn" ;
    DAE.Flow flow_ "flow ; if the var is a flow" ;
  end VAR;

end Var;

public 
uniontype Equation "- Equation"
  record EQUATION
    Exp.Exp exp;
    Exp.Exp scalar "scalar" ;
  end EQUATION;

  record ARRAY_EQUATION
    Integer index "index ; index in arrayequations 0..n-1" ;
    list<Exp.Exp> crefOrDerCref "crefOrDerCref ; CREF or der(CREF)" ;
  end ARRAY_EQUATION;

  record SOLVED_EQUATION
    Exp.ComponentRef componentRef "componentRef" ;
    Exp.Exp exp "exp" ;
  end SOLVED_EQUATION;

  record RESIDUAL_EQUATION
    Exp.Exp exp "exp ; not present from front end" ;
  end RESIDUAL_EQUATION;

  record ALGORITHM
    Integer index      "Index in algorithms, 0..n-1" ;
    list<Exp.Exp> in_  "Inputs CREF or der(CREF)" ;
    list<Exp.Exp> out  "Outputs CREF or der(CREF)" ;
  end ALGORITHM;

  record WHEN_EQUATION
    WhenEquation whenEquation "whenEquation" ;
  end WHEN_EQUATION;

end Equation;

public 
uniontype WhenEquation "- When Equation"
  record WHEN_EQ
    Integer index         "Index in when clauses" ;
    Exp.ComponentRef left "Left hand side of equation" ;
    Exp.Exp right         "Right hand side of equation" ;
    Option<WhenEquation> elsewhenPart "elsewhen equation with the same cref on the left hand side.";
  end WHEN_EQ;

end WhenEquation;

public 
uniontype ReinitStatement "- Reinit Statement"
  record REINIT
    Exp.ComponentRef stateVar "State variable to reinit" ;
    Exp.Exp value             "Value after reinit" ;
  end REINIT;
  record EMPTY_REINIT
  end EMPTY_REINIT;
end ReinitStatement;

public 
uniontype WhenClause "- When Clause"
  record WHEN_CLAUSE
    Exp.Exp condition                   "The when-condition" ;
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
    Exp.Exp relation_          "function" ;
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
    EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
    EquationArray removedEqs "removedEqs ; Removed equations a=b" ;
    EquationArray initialEqs "initialEqs ; Initial equations" ;
    MultiDimEquation[:] arrayEqs "arrayEqs ; Array equations" ;
    Algorithm.Algorithm[:] algorithms "algorithms ; Algorithms" ;
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
    Exp.Exp left "left ; lhs" ;
    Exp.Exp right "right ; rhs" ;
  end MULTIDIM_EQUATION;

end MultiDimEquation;

public 
uniontype CrefIndex "- Component Reference Index"
  record CREFINDEX
    Exp.ComponentRef cref "cref" ;
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
type Key = Exp.ComponentRef "A key is a Component Reference
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

protected import Util;
protected import RTOpts;
protected import DAEEXT;
protected import Print;
protected import Derive;
protected import Debug;
protected import Env;
protected import Builtin;
protected import Ceval;
protected import Types;
protected import SCode;
protected import Dump;
protected import System;
protected import VarTransform;
protected import Error;
protected import SimCodegen;


protected constant BinTree emptyBintree=TREENODE(NONE,NONE,NONE) " Empty binary tree " ;

public constant String derivativeNamePrefix="$derivative";







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
  _ :=
   matchcontinue (inDAELowEqnList,printExpTree)
    local
      Exp.Exp e1_1,e2_1,e1,e2,e_1,e;
      String str;
      list<String> strList;
      list<Equation> res;
      list<Exp.Exp> expList,expList2;
     case ({},_) then (); 
     case (EQUATION(e1,e2)::res,printExpTree) /* header */ 
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
    case (SOLVED_EQUATION(_,e)::res,printExpTree)
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
    case (RESIDUAL_EQUATION(e)::res,printExpTree)
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
    case (ARRAY_EQUATION(_,expList)::res,printExpTree)
      equation 
        dumpDAELowEqnList2(res,printExpTree);
        print("ARRAY_EQUATION: ");
        strList = Util.listMap(expList,Exp.printExpStr);
        str = Util.stringDelimitList(strList," | ");
        print(str);
        print("\n");
      then
        ();
     case (ALGORITHM(_,expList,expList2)::res,printExpTree)
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
     case (WHEN_EQUATION(WHEN_EQ(_,_,e,_/*TODO handle elsewhe also*/))::res,printExpTree)
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

public function lower "function: lower
 
  This function translates a DAE, which is the result from instantiating a 
  class, into a more precise form, called DAELow defined in this module.
  The DAELow representation splits the DAE into equations and variables
  and further divides variables into known and unknown variables and the 
  equations into simple and nonsimple equations.
  The variables are inserted into a hash table. This gives a lookup cost of 
  O(1) for finding a variable. The equations are put in an expandable
  array. Where adding a new equation can be done in O(1) time if space 
  is available.
  inputs:  daeList: DAE.DAElist, add_dummy_state: bool) 
  outputs: DAELow
"
  input DAE.DAElist lst;
  input Boolean add_dummy;
  output DAELow outDAELow;
  BinTree s;
  Variables vars,knvars,vars_1,extVars;
  list<Equation> eqns,reqns,ieqns,algeqns,multidimeqns,eqns_1;
  list<MultiDimEquation> aeqns,aeqns1;
  list<Algorithm.Algorithm> algs;
  list<WhenClause> whenclauses,whenclauses_1;
  list<ZeroCrossing> zero_crossings;
  EquationArray eqnarr,reqnarr,ieqnarr;
  MultiDimEquation[:] arr_md_eqns;
  Algorithm.Algorithm[:] algarr;
  ExternalObjectClasses extObjCls;
algorithm 
  s := states(lst, emptyBintree);
  (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses,extObjCls) := lower2(lst, s, {});
  (vars,eqns) := addDummyState(vars, eqns, add_dummy);
  whenclauses_1 := listReverse(whenclauses);
  algeqns := lowerAlgorithms(vars, algs);
  multidimeqns := lowerMultidimeqns(vars, aeqns);
  eqns := listAppend(algeqns, eqns);
  eqns := listAppend(multidimeqns, eqns);
  (vars,knvars,eqns,reqns,ieqns,aeqns1) := removeSimpleEquations(vars, knvars, eqns, reqns, ieqns, aeqns, s);
  vars_1 := detectImplicitDiscrete(vars, eqns);
  eqns_1 := sortEqn(eqns);
  (zero_crossings) := findZeroCrossings(vars_1, eqns_1, whenclauses_1,algs);
  eqnarr := listEquation(eqns_1);
  reqnarr := listEquation(reqns);
  ieqnarr := listEquation(ieqns);
  arr_md_eqns := listArray(aeqns1);
  algarr := listArray(algs);
  outDAELow := DAELOW(vars_1,knvars,extVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,
          EVENT_INFO(whenclauses_1,zero_crossings),extObjCls);
end lower;

protected function addDummyState "function: addDummyState
 
  In order for the solver to work correctly at least one state variable
  must exist in the equation system. This function therefore adds a 
  dummy state variable and an equation for that variable.
  inputs:  (vars: Variables, eqns: Equation list, bool)
  outputs: (Variables, Equation list)
"
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
        vars_1 = addVar(
          VAR(Exp.CREF_IDENT("$dummy",{}),STATE(),DAE.BIDIR(),DAE.REAL(),
          NONE,NONE,{},NONE,-1,Exp.CREF_IDENT("$dummy",{}),{},
          SOME(
          DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,SOME(true),NONE,NONE)),NONE,DAE.NON_CONNECTOR()), vars);
      then  
        /* Add equation der(dummy) = sin(time*6628.318530717). This so the solver has something to solve 
        if the model does not contain states. To prevent the solver from taking larger and larger steps
        (which would happen if der(dymmy) = 0) when using automatic, we have a osciallating derivative.
        */
        (vars_1,(EQUATION(
          Exp.CALL(Absyn.IDENT("der"),
          {Exp.CREF(Exp.CREF_IDENT("$dummy",{}),Exp.REAL())},false,true,Exp.REAL()),
          Exp.CALL(Absyn.IDENT("sin"),{Exp.BINARY(
          	Exp.CREF(Exp.CREF_IDENT("time",{}),Exp.REAL()),
          	Exp.MUL(Exp.REAL()),
          	Exp.RCONST(628.318530717))},false,true,Exp.REAL()))  :: eqns));
          	
  end matchcontinue;
end addDummyState;

public function zeroCrossingsEquations "Returns a list of all equations (by their index) that contain a zero crossing
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

protected function whenEquationsIndices2 "Help function"
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
        WHEN_EQUATION(_) = equationNth(eqns,i-1);
        eqnLst = whenEquationsIndices2(i+1,size,eqns);
    then i::eqnLst;
    case(i,size,eqns)
      equation
        eqnLst=whenEquationsIndices2(i+1,size,eqns);
      then eqnLst;
  end matchcontinue;
end whenEquationsIndices2;

protected function zeroCrossingEquations "Returns the list of equations (indices) from a ZeroCrossing"
  input ZeroCrossing zc;
  output list<Integer> lst;
algorithm
  lst := matchcontinue(zc)
    case(ZERO_CROSSING(_,lst,_)) then lst;
  end matchcontinue;
end zeroCrossingEquations;

protected function dumpZcStr "function: dumpZcStr
 
  Dumps a zerocrossing into a string, for debugging purposes.
"
  input ZeroCrossing inZeroCrossing;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inZeroCrossing)
    local
      list<String> eq_s_list,wc_s_list;
      String eq_s,wc_s,str,str2;
      Exp.Exp e;
      list<Value> eq,wc;
    case ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)
      equation 
        eq_s_list = Util.listMap(eq, int_string);
        eq_s = Util.stringDelimitList(eq_s_list, ",");
        wc_s_list = Util.listMap(wc, int_string);
        wc_s = Util.stringDelimitList(wc_s_list, ",");
        str = Exp.printExpStr(e);
        str2 = Util.stringAppendList(
          {str," in equations [",eq_s,"] and when conditions [",wc_s,
          "]\n"});
      then
        str2;
  end matchcontinue;
end dumpZcStr;

protected function mergeZeroCrossings "function: mergeZeroCrossings
 
  Takes a list of zero crossings and if more than one have identical
  function expressions they are merged into one zerocrossing.
  In the resulting list all zerocrossing have uniq function expressions.
"
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
      Exp.Exp e1,e2;
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
      Exp.Exp e1,e2;
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
  input list<Equation> eq;
  input list<WhenClause> wc;
  input list<Algorithm.Algorithm> algs;
  output list<ZeroCrossing> res_1;
  list<ZeroCrossing> res,res_1;
algorithm 
  res := findZeroCrossings2(vars, eq, 1, wc, 1, algs);
  res_1 := mergeZeroCrossings(res);
end findZeroCrossings;

protected function findZeroCrossings2 "function: findZeroCrossings2
 
  Helper function to find_zero_crossing.
"
  input Variables inVariables1;
  input list<Equation> inEquationLst2;
  input Integer inInteger3;
  input list<WhenClause> inWhenClauseLst4;
  input Integer inInteger5;
  input list<Algorithm.Algorithm> algs;
  
  output list<ZeroCrossing> outZeroCrossingLst;
algorithm 
  outZeroCrossingLst:=
  matchcontinue (inVariables1,inEquationLst2,inInteger3,inWhenClauseLst4,inInteger5,algs)
    local
      Variables v;
      list<Exp.Exp> rellst1,rellst2,rel;
      list<ZeroCrossing> zc1,zc2,zc3,zc4,res,res1,res2;
      Value eq_count_1,eq_count,wc_count_1,wc_count;
      Equation e;
      Exp.Exp e1,e2;
      list<Equation> xs,el;
      WhenClause wc;
      Integer ind;
    case (v,{},_,{},_,_) then {}; 
    case (v,((e as EQUATION(exp = e1,scalar = e2)) :: xs),eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        rellst2 = findZeroCrossings3(e2, v);
        zc2 = makeZeroCrossings(rellst2, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, xs, eq_count_1, {}, 0,algs);
        zc4 = listAppend(zc1, zc2);
        res = listAppend(zc3, zc4);
      then
        res;
    case (v,((e as SOLVED_EQUATION(exp = e1)) :: xs),eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, xs, eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,((e as RESIDUAL_EQUATION(exp = e1)) :: xs),eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, xs, eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,((e as ALGORITHM(index = ind)) :: xs),eq_count,{},_,algs)
      local
        list<Algorithm.Statement> stmts;
      equation
        eq_count_1 = eq_count + 1;
        zc1 = findZeroCrossings2(v, xs, eq_count_1, {}, 0,algs);
        Algorithm.ALGORITHM(stmts) = listNth(algs,ind);
        rel = Algorithm.getAllExpsStmts(stmts);
        rellst1 = Util.listFlatten(Util.listMap1(rel,findZeroCrossings3, v));
        zc2 = makeZeroCrossings(rellst1, {eq_count}, {});
        res = listAppend(zc2, zc1);
      then
        res;
    case (v,(e :: xs),eq_count,{},_,algs)
      equation 
        eq_count_1 = eq_count + 1;
        (res) = findZeroCrossings2(v, xs, eq_count_1, {}, 0,algs);
      then
        res;
    case (v,el,eq_count,((wc as WHEN_CLAUSE(condition = e)) :: xs),wc_count,algs)
      local
        Exp.Exp e;
        list<WhenClause> xs;
      equation 
        wc_count_1 = wc_count + 1;
        (res1) = findZeroCrossings2(v, el, eq_count, xs, wc_count_1,algs);
        rel = findZeroCrossings3(e, v);
        res2 = makeZeroCrossings(rel, {}, {wc_count});
        res = listAppend(res1, res2);
      then
        res;
  end matchcontinue;
end findZeroCrossings2;

protected function collectZeroCrossings "function: collectZeroCrossings
 
  Collects zero crossings 
"
  input tuple<Exp.Exp, tuple<list<Exp.Exp>, Variables>> inTplExpExpTplExpExpLstVariables;
  output tuple<Exp.Exp, tuple<list<Exp.Exp>, Variables>> outTplExpExpTplExpExpLstVariables;
algorithm 
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      Exp.Exp e,e1,e2,e_1;
      Variables vars;
      list<Exp.Exp> zeroCrossings,zeroCrossings_1,zeroCrossings_2,zeroCrossings_3,el;
      Exp.Operator op;
      Exp.Type tp;
      Boolean scalar;
    case (((e as Exp.CALL(path = Absyn.IDENT(name = "noEvent"))),(zeroCrossings,vars))) then ((e,({},vars))); 
    case (((e as Exp.CALL(path = Absyn.IDENT(name = "sample"))),(zeroCrossings,vars))) then ((e,((e :: zeroCrossings),vars))); 
      
    case (((e as Exp.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,vars))) /* function with discrete expressions generate no zerocrossing */ 
      equation 
        true = isDiscreteExp(e1, vars);
        true = isDiscreteExp(e2, vars);
      then
        ((e,(zeroCrossings,vars)));
    case (((e as Exp.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,vars))) 
      equation
      then ((e,((e :: zeroCrossings),vars)));  /* All other functions generate zerocrossing. */ 
    case (((e as Exp.ARRAY(array = {})),(zeroCrossings,vars))) 
      equation
      then ((e,(zeroCrossings,vars))); 
    case ((e1 as Exp.ARRAY(ty = tp,scalar = scalar,array = (e :: el)),(zeroCrossings,vars)))
      equation 
        ((_,(zeroCrossings_1,vars))) = Exp.traverseExp(e, collectZeroCrossings, (zeroCrossings,vars));
        ((e_1,(zeroCrossings_2,vars))) = collectZeroCrossings((Exp.ARRAY(tp,scalar,el),(zeroCrossings,vars)));
        zeroCrossings_3 = listAppend(zeroCrossings_1, zeroCrossings_2);
      then
        ((e1,(zeroCrossings_3,vars)));
    case ((e,(zeroCrossings,vars))) 
      equation
      then ((e,(zeroCrossings,vars))); 
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
 
 Returns true if expression is a discrete expression.
"
  input Exp.Exp inExp;
  input Variables inVariables;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp,inVariables)
    local
      Variables vars;
      Exp.ComponentRef cr,orig;
      VarKind kind;
      DAE.VarDirection dir;
      DAE.Type vartype;
      Option<Exp.Exp> bind,start;
      Option<Values.Value> value;
      list<Exp.Subscript> dims;
      Value ind;
      list<Absyn.Path> clname;
      Option<DAE.VariableAttributes> attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      Boolean res,b1,b2,b3;
      Exp.Exp e1,e2,e,e3;
      Exp.Operator op;
      list<Boolean> blst;
      list<Exp.Exp> expl,expl_2;
      Exp.Type tp;
      list<tuple<Exp.Exp, Boolean>> expl_1;
    case (Exp.ICONST(integer = _),vars) then true; 
    case (Exp.RCONST(real = _),vars) then true; 
    case (Exp.SCONST(string = _),vars) then true; 
    case (Exp.BCONST(bool = _),vars) then true; 
    case (Exp.CREF(componentRef = cr),vars)
      equation 
        ((VAR(cr,kind,dir,vartype,bind,value,dims,start,ind,orig,clname,attr,comment,flow_) :: _),_) = getVar(cr, vars);
        res = isKindDiscrete(kind);
      then
        res;
    case (Exp.BINARY(exp1 = e1,operator = op,exp2 = e2),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        res = boolOr(b1, b2);
      then
        res;
    case (Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        res = boolOr(b1, b2);
      then
        res;
    case (Exp.UNARY(operator = op,exp = e),vars)
      equation 
        res = isDiscreteExp(e, vars);
      then
        res;
    case (Exp.LUNARY(operator = op,exp = e),vars)
      equation 
        res = isDiscreteExp(e, vars);
      then
        res;
    case (Exp.RELATION(exp1 = e1,operator = op,exp2 = e2),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        res = boolOr(b1, b2);
      then
        res;
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        b3 = isDiscreteExp(e3, vars);
        res = Util.boolOrList({b1,b2,b3});
      then
        res;
    case (Exp.CALL(path = Absyn.IDENT(name = "pre")),vars) then true; 
    case (Exp.CALL(expLst = expl),vars)
      equation 
        blst = Util.listMap1(expl, isDiscreteExp, vars);
        res = Util.boolOrList(blst);
      then
        res;
    case (Exp.ARRAY(ty = tp,array = expl),vars)
      equation 
        blst = Util.listMap1(expl, isDiscreteExp, vars);
        res = Util.boolOrList(blst);
      then
        res;
    case (Exp.MATRIX(ty = tp,scalar = expl),vars)
      local list<list<tuple<Exp.Exp, Boolean>>> expl;
      equation 
        expl_1 = Util.listFlatten(expl);
        expl_2 = Util.listMap(expl_1, Util.tuple21);
        blst = Util.listMap1(expl_2, isDiscreteExp, vars);
        res = Util.boolOrList(blst);
      then
        res;
    case (Exp.RANGE(ty = tp,exp = e1,expOption = SOME(e2),range = e3),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        b3 = isDiscreteExp(e3, vars);
        res = Util.boolOrList({b1,b2,b3});
      then
        res;
    case (Exp.RANGE(ty = tp,exp = e1,expOption = NONE,range = e2),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        res = boolOr(b1, b2);
      then
        res;
    case (Exp.TUPLE(PR = expl),vars)
      equation 
        blst = Util.listMap1(expl, isDiscreteExp, vars);
        res = Util.boolOrList(blst);
      then
        res;
    case (Exp.CAST(ty = tp,exp = e1),vars)
      equation 
        res = isDiscreteExp(e1, vars);
      then
        res;
    case (Exp.ASUB(exp = e),vars)
      equation 
        res = isDiscreteExp(e, vars);
      then
        res;
    case (Exp.SIZE(exp = e1,sz = SOME(e2)),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        res = boolOr(b1, b2);
      then
        res;
    case (Exp.SIZE(exp = e1,sz = NONE),vars)
      equation 
        res = isDiscreteExp(e1, vars);
      then
        res;
    case (Exp.REDUCTION(expr = e1,range = e2),vars)
      equation 
        b1 = isDiscreteExp(e1, vars);
        b2 = isDiscreteExp(e2, vars);
        res = boolOr(b1, b2);
      then
        res;
    case (_,vars) then false; 
  end matchcontinue;
end isDiscreteExp;

protected function findZeroCrossings3 "function: findZeroCrossings3
 
  Helper function to find_zero_crossing.
"
  input Exp.Exp e;
  input Variables vars;
  output list<Exp.Exp> zeroCrossings;
algorithm 
  ((_,(zeroCrossings,_))) := Exp.traverseExp(e, collectZeroCrossings, ({},vars));
end findZeroCrossings3;

protected function makeZeroCrossing "function: makeZeroCrossing
 
  Constructs a ZeroCrossing from an expression and lists of equation indices
  and when clause indices.
"
  input Exp.Exp inExp1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output ZeroCrossing outZeroCrossing;
algorithm 
  outZeroCrossing:=
  matchcontinue (inExp1,inIntegerLst2,inIntegerLst3)
    local
      Exp.Exp e;
      list<Value> eq_ind,wc_ind;
    case (e,eq_ind,wc_ind) then ZERO_CROSSING(e,eq_ind,wc_ind); 
  end matchcontinue;
end makeZeroCrossing;

protected function makeZeroCrossings "function: makeZeroCrossings
 
  Constructs a list of ZeroCrossings from a list expressions and lists of 
  equation indices and when clause indices.
  Each Zerocrossing gets the same lists of indicies.
"
  input list<Exp.Exp> inExpExpLst1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output list<ZeroCrossing> outZeroCrossingLst;
algorithm 
  outZeroCrossingLst:=
  matchcontinue (inExpExpLst1,inIntegerLst2,inIntegerLst3)
    local
      ZeroCrossing res;
      list<ZeroCrossing> resx;
      Exp.Exp e;
      list<Exp.Exp> xs;
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

protected function detectImplicitDiscrete "function: detectImplicitDiscrete
 
  This function updates the variable kind to discrete for variables set 
  in when equations.
"
  input Variables inVariables;
  input list<Equation> inEquationLst;
  output Variables outVariables;
algorithm 
  outVariables:=
  matchcontinue (inVariables,inEquationLst)
    local
      Variables v,v_1,v_2;
      Exp.ComponentRef cr,orig;
      DAE.VarDirection dir;
      DAE.Type vartype;
      Option<Exp.Exp> bind,start;
      Option<Values.Value> value;
      list<Exp.Subscript> dims;
      Value ind;
      list<Absyn.Path> clname;
      Option<DAE.VariableAttributes> attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Equation> xs;
    case (v,{}) then v; 
    case (v,(WHEN_EQUATION(whenEquation = WHEN_EQ(left = cr)) :: xs))
      equation 
        ((VAR(cr,_,dir,vartype,bind,value,dims,start,ind,orig,clname,attr,comment,flow_) :: _),_) = getVar(cr, v);
        v_1 = addVar(
          VAR(cr,DISCRETE(),dir,vartype,bind,value,dims,start,ind,orig,
          clname,attr,comment,flow_), v);
        v_2 = detectImplicitDiscrete(v_1, xs);
      then
        v_2;
    case (v,(_ :: xs))
      equation 
        v_1 = detectImplicitDiscrete(v, xs);
      then
        v_1;
  end matchcontinue;
end detectImplicitDiscrete;

protected function sortEqn "function: sortEqn 
 
  This function sorts the equation. It puts first the algebraic eqns
  and last the differentiated eqns
 
"
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

protected function extractAlgebraicAndDifferentialEqn "function: extractAlgebraicAndDifferentialEqn
 
  Splits the equation list into two lists. One that only contain differential
  equations and one that only contain algebraic equations.
"
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
      Exp.Exp exp1,exp2;
      list<Boolean> bool_lst;
      Value indx;
      list<Exp.Exp> expl;
    case ({}) then ({},{},{});  /* algebraic equations differential equations */ 
    case (((eqn as EQUATION(exp = exp1,scalar = exp2)) :: rest)) /* scalar equation */ 
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
      Algorithm.Algorithm[:] al;
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
      Algorithm.Algorithm[:] alg;
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

protected function markStateEquation "function: markStateEquation
 
  This function is a helper function to mark_state_equations
  It performs marking for one equation and its transitive closure by 
  following edges in backward direction.
  inputs and outputs are tuples so we can use Util.list_fold 
"
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
      Exp.ComponentRef cr;
      DAE.Flow flow_;
      DAELow dae;
      Variables vars;
      String s,str;
      Value v_indx,v_indx_1;
    case (VAR(varName = cr,flow_ = flow_),((dae as DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation 
        (_,v_indxs) = getVar(cr, vars);
        v_indxs_1 = Util.listMap1(v_indxs, int_sub, 1);
        eqns = Util.listMap1r(v_indxs_1, arrayNth, a1);
        ((arr_1,m,mt,a1,a2)) = markStateEquation2(eqns, (arr,m,mt,a1,a2));
      then
        ((dae,arr_1,m,mt,a1,a2));
    case (VAR(varName = cr,flow_ = flow_),((dae as DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
      equation 
        failure((_,_) = getVar(cr, vars));
        print("mark_state_equation var ");
        s = Exp.printComponentRefStr(cr);
        print(s);
        print("not found\n");
      then
        fail();
    case (VAR(varName = cr,flow_ = flow_),((dae as DAELOW(orderedVars = vars)),arr,m,mt,a1,a2))
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

protected function markStateEquation2 "function: markStateEquation2
 
  Helper function to mark_state_equation
  Does the job by looking at variable indexes and incidencematrices.
  inputs: (eqns: int list, 
             marks: (int array  IncidenceMatrix  IncidenceMatrixT  int vector  int vector)) 
  outputs: ((marks: int array  IncidenceMatrix  IncidenceMatrixT 
	      int vector  int vector))
"
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

public function isStateVar "function: isStateVar
 
  Returns true for state variables, false otherwise.
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varKind = STATE(),flow_ = flow_)) then true; 
    case (_) then false; 
  end matchcontinue;
end isStateVar;

public function isDummyStateVar "
 
  Returns true for dummy state variables, false otherwise.
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varKind = DUMMY_STATE(),flow_ = flow_)) then true; 
    case (_) then false; 
  end matchcontinue;
end isDummyStateVar;

public function isNonState "function: isNonState 
 
  this equation checks if the the varkind is state of variable
  used both in build_equation and generate_compute_state
"
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
    case (_) then false; 
  end matchcontinue;
end isNonState;

public function isDiscrete "function: isDiscrete
 
  This equation checks if the the varkind is discrete,
  used both in build_equation and generate_compute_state
"
  input VarKind inVarKind;
algorithm 
  _:=
  matchcontinue (inVarKind)
    case (DISCRETE()) then (); 
  end matchcontinue;
end isDiscrete;

public function dump "function: dump
 
  This function dumps the DAELow representaton to stdout.
"
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
      EquationArray eqns,reqns,ieqns;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] algs;
      list<ZeroCrossing> zc;
      ExternalObjectClasses extObjCls;
    case (DAELOW(vars1,vars2,vars3,eqns,reqns,ieqns,ae,algs,EVENT_INFO(zeroCrossingLst = zc),extObjCls))
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
        dumpArrayEqns(ae_lst);
        
        print("Algorithms:\n");
        print("===============\n");
				dumpAlgorithms(arrayList(algs));
      then
        ();
  end matchcontinue;
end dump;

protected function dumpAlgorithms "Help function to dump, prints algorithms to stdout"
  input list<Algorithm.Algorithm> algs;
algorithm
  _ := matchcontinue(algs)
    local list<Algorithm.Statement> stmts;
    case({}) then ();
    case(Algorithm.ALGORITHM(stmts)::algs) equation
      print(DAE.dumpAlgorithmStr(DAE.ALGORITHM(Algorithm.ALGORITHM(stmts))));
      dumpAlgorithms(algs);
    then ();
  end matchcontinue;
end dumpAlgorithms;


public function varList "function: varList
 
  Takes Variables and returns a list of \'Var\', useful for e.g. dumping.
"
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

public function listVar "function: listVar
  author: PA
 
  Takes Var list and creates a Variables structure, see also var_list.
"
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

public function varCref "function: varCref
  author: PA
 
  extracts the ComponentRef of a variable.
"
  input Var inVar;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inVar)
    local
      Exp.ComponentRef cr;
      DAE.Flow flow_;
    case (VAR(varName = cr,flow_ = flow_)) then cr; 
  end matchcontinue;
end varCref;

public function varOrigCref "
  author: PA
 
  extracts the original ComponentRef name of a variable.
"
  input Var inVar;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inVar)
    local
      Exp.ComponentRef cr;
      DAE.Flow flow_;
    case (VAR(origVarName = cr)) then cr; 
  end matchcontinue;
end varOrigCref;

public function varCrefPrefixStates "
  author: PA
  extracts the ComponentRef of a variable and prefixes the variable name with derivativeNamePrefix if the variable
  is a state (and it does not alreaday have the prefix). This function can be used e.g. when extracting the solved variables of a subsystem of equations."

  input Var inVar;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inVar)
    local
      Exp.ComponentRef cr,cr2;
      DAE.Flow flow_;
      Exp.Ident name;
      list<Exp.Subscript> subs;
    case (VAR(varName = Exp.CREF_IDENT(name,subs),varKind=STATE())) 
      equation
        failure(0=System.strncmp(derivativeNamePrefix,name,stringLength(derivativeNamePrefix)));
        name = stringAppend(derivativeNamePrefix,name);
      then Exp.CREF_IDENT(name,subs);
    case (VAR(varName = Exp.CREF_QUAL(name,subs,cr2),varKind=STATE())) 
      equation
       failure(0=System.strncmp(derivativeNamePrefix,name,stringLength(derivativeNamePrefix)));
        name = stringAppend(derivativeNamePrefix,name);
      then Exp.CREF_QUAL(name,subs,cr2);
	
		// For non-states, return name        
    case (VAR(varName = cr)) then cr; 
      
  end matchcontinue;
end varCrefPrefixStates;


public function varType "function: varType
  author: PA
 
  extracts the type of a variable.
"
  input Var inVar;
  output DAE.Type outType;
algorithm 
  outType:=
  matchcontinue (inVar)
    local DAE.Type tp;
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

public function varOrigName "function: varOrigName
  author: PA
 
  extracts the original name of a variable.
"
  input Var inVar;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVar)
    local
      String str;
      Exp.ComponentRef s;
    case (VAR(origVarName = s))
      equation 
        str = Exp.printComponentRefStr(s);
      then
        str;
  end matchcontinue;
end varOrigName;

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
  outReal:=
  matchcontinue (inVar)
    local
      Real nominal;
      DAE.Flow flow_;
    case (VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,SOME(nominal),_)),flow_ = flow_)) then nominal; 
  end matchcontinue;
end varNominal;

public function setVarFixed "function: setVarFixed
  author: PA
 
  Sets the fixed attribute of a variable. 
"
  input Var inVar;
  input Boolean inBoolean;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVar,inBoolean)
    local
      Exp.ComponentRef a,j;
      VarKind b;
      DAE.VarDirection c;
      DAE.Type d;
      Option<Exp.Exp> e,h;
      Option<Values.Value> f;
      list<Exp.Subscript> g;
      Value i;
      list<Absyn.Path> k;
      Option<String> l,m,n;
      tuple<Option<Real>, Option<Real>> o;
      Option<Real> p,q;
      Option<DAE.StateSelect> r;
      Option<Absyn.Comment> s;
      DAE.Flow t;
      Boolean fixed;
    case (VAR(varName = a,varKind = b,varDirection = c,varType = d,bindExp = e,bindValue = f,arryDim = g,startValue = h,index = i,origVarName = j,className = k,values = SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,_,q,r)),comment = s,flow_ = t),fixed) then VAR(a,b,c,d,e,f,g,h,i,j,k,
          SOME(DAE.VAR_ATTR_REAL(l,m,n,o,p,SOME(fixed),q,r)),s,t); 
    case (VAR(varName = a,varKind = b,varDirection = c,varType = d,bindExp = e,bindValue = f,arryDim = g,startValue = h,index = i,origVarName = j,className = k,values = SOME(DAE.VAR_ATTR_INT(l,m,n,_)),comment = o,flow_ = p),fixed)
      local
        tuple<Option<Value>, Option<Value>> m;
        Option<Value> n;
        Option<Absyn.Comment> o;
        DAE.Flow p;
      then
        VAR(a,b,c,d,e,f,g,h,i,j,k,
          SOME(DAE.VAR_ATTR_INT(l,m,n,SOME(fixed))),o,p);
    case (VAR(varName = a,varKind = b,varDirection = c,varType = d,bindExp = e,bindValue = f,arryDim = g,startValue = h,index = i,origVarName = j,className = k,values = SOME(DAE.VAR_ATTR_BOOL(l,m,_)),comment = n,flow_ = o),fixed)
      local
        Option<Boolean> m;
        Option<Absyn.Comment> n;
        DAE.Flow o;
      then
        VAR(a,b,c,d,e,f,g,h,i,j,k,
          SOME(DAE.VAR_ATTR_BOOL(l,m,SOME(fixed))),n,o);
    case (VAR(varName = a,varKind = b,varDirection = c,varType = d,bindExp = e,bindValue = f,arryDim = g,startValue = h,index = i,origVarName = j,className = k,values = SOME(DAE.VAR_ATTR_ENUMERATION(l,m,n,_)),comment = o,flow_ = p),fixed)
      local
        tuple<Option<Exp.Exp>, Option<Exp.Exp>> m;
        Option<Exp.Exp> n;
        Option<Absyn.Comment> o;
        DAE.Flow p;
      then
        VAR(a,b,c,d,e,f,g,h,i,j,k,
          SOME(DAE.VAR_ATTR_ENUMERATION(l,m,n,SOME(fixed))),o,p);
    case (VAR(varName = a,varKind = b,varDirection = c,varType = DAE.REAL(),bindExp = f,bindValue = g,arryDim = h,startValue = i,index = j,origVarName = k,className = l,values = NONE,comment = m,flow_ = n),fixed)
      local
        Option<Exp.Exp> f,i;
        Option<Values.Value> g;
        list<Exp.Subscript> h;
        Value j;
        Exp.ComponentRef k;
        list<Absyn.Path> l;
        Option<Absyn.Comment> m;
        DAE.Flow n;
      then
        VAR(a,b,c,DAE.REAL(),f,g,h,i,j,k,l,
          SOME(
          DAE.VAR_ATTR_REAL(NONE,NONE,NONE,(NONE,NONE),NONE,SOME(fixed),NONE,NONE)),m,n);
    case (VAR(varName = a,varKind = b,varDirection = c,varType = DAE.INT(),bindExp = f,bindValue = g,arryDim = h,startValue = i,index = j,origVarName = k,className = l,values = NONE,comment = m,flow_ = n),fixed)
      local
        Option<Exp.Exp> f,i;
        Option<Values.Value> g;
        list<Exp.Subscript> h;
        Value j;
        Exp.ComponentRef k;
        list<Absyn.Path> l;
        Option<Absyn.Comment> m;
        DAE.Flow n;
      then
        VAR(a,b,c,DAE.REAL(),f,g,h,i,j,k,l,
          SOME(DAE.VAR_ATTR_INT(NONE,(NONE,NONE),NONE,SOME(fixed))),m,n);
    case (VAR(varName = a,varKind = b,varDirection = c,varType = DAE.BOOL(),bindExp = f,bindValue = g,arryDim = h,startValue = i,index = j,origVarName = k,className = l,values = NONE,comment = m,flow_ = n),fixed)
      local
        Option<Exp.Exp> f,i;
        Option<Values.Value> g;
        list<Exp.Subscript> h;
        Value j;
        Exp.ComponentRef k;
        list<Absyn.Path> l;
        Option<Absyn.Comment> m;
        DAE.Flow n;
      then
        VAR(a,b,c,DAE.REAL(),f,g,h,i,j,k,l,
          SOME(DAE.VAR_ATTR_BOOL(NONE,NONE,SOME(fixed))),m,n);
    case (VAR(varName = a,varKind = b,varDirection = c,varType = DAE.ENUM(),bindExp = f,bindValue = g,arryDim = h,startValue = i,index = j,origVarName = k,className = l,values = NONE,comment = m,flow_ = n),fixed)
      local
        Option<Exp.Exp> f,i;
        Option<Values.Value> g;
        list<Exp.Subscript> h;
        Value j;
        Exp.ComponentRef k;
        list<Absyn.Path> l;
        Option<Absyn.Comment> m;
        DAE.Flow n;
      then
        VAR(a,b,c,DAE.REAL(),f,g,h,i,j,k,l,
          SOME(DAE.VAR_ATTR_ENUMERATION(NONE,(NONE,NONE),NONE,SOME(fixed))),m,n);
  end matchcontinue;
end setVarFixed;

public function varFixed "function: varFixed
  author: PA
 
  Extacts the fixed attribute of a variable. 
  The default fixed value is used if not found. Default is true for parameters
  (and constants) and false for variables.
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local
      Boolean fixed;
      Var v;
    case (v as VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,SOME(fixed),_,_)))) then fixed; 
    case (VAR(values = SOME(DAE.VAR_ATTR_INT(_,_,_,SOME(fixed))))) then fixed; 
    case (VAR(values = SOME(DAE.VAR_ATTR_BOOL(_,_,SOME(fixed))))) then fixed; 
    case (VAR(values = SOME(DAE.VAR_ATTR_ENUMERATION(_,_,_,SOME(fixed))))) then fixed; 
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

public function varStartValue "
  author: PA
  
  Returns the DAE.StartValue of a variable.
  "
  input Var v;
  output DAE.StartValue sv;
algorithm
   sv := matchcontinue(v)
     case (VAR(startValue = sv)) then sv;
   end matchcontinue;
end varStartValue;

public function varStateSelect "
  author: PA
 
  Extacts the state select attribute of a variable. If no stateselect explicilty set, return 
  StateSelect.default 
 
"
  input Var inVar;
  output DAE.StateSelect outStateSelect;
algorithm 
  outStateSelect:=
  matchcontinue (inVar)
    local
      DAE.StateSelect stateselect;
      Var v;
    case (VAR(values = SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(stateselect))))) 
    then stateselect; 
      case (_) then DAE.DEFAULT();
  end matchcontinue;
end varStateSelect;

public function vararrayList "function: vararrayList
 
  Transforms a VariableArray to a Var list
"
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

protected function vararrayList2 "function: vararrayList2
 
  Helper function to vararray_list
"
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

public function dumpJacobianStr "function: dumpJacobianStr
 
  Dumps the sparse jacobian.
  Uses the variables to determine size of Jacobian matrix.
"
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

protected function dumpJacobianStr2 "function: dumpJacobianStr2
 
  Helper function to dump_jacobian_str
"
  input list<tuple<Integer, Integer, Equation>> inTplIntegerIntegerEquationLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inTplIntegerIntegerEquationLst)
    local
      String estr,rowstr,colstr,str;
      list<String> strs;
      Value row,col;
      Exp.Exp e;
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

protected function dumpArrayEqns "function: dumpArrayEqns
 
  helper function to dump
"
  input list<MultiDimEquation> inMultiDimEquationLst;
algorithm 
  _:=
  matchcontinue (inMultiDimEquationLst)
    local
      String s1,s2,s;
      Exp.Exp e1,e2;
      list<MultiDimEquation> es;
    case ({}) then (); 
    case ((MULTIDIM_EQUATION(left = e1,right = e2) :: es))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s = Util.stringAppendList({s1," = ",s2,"\n"});
        print(s);
        dumpArrayEqns(es);
      then
        ();
  end matchcontinue;
end dumpArrayEqns;

public function dumpEqns "function: dumpEqns
 
  Helper function to dump.
"
  input list<Equation> eqns;
algorithm 
  dumpEqns2(eqns, 1);
end dumpEqns;

protected function dumpEqns2 "function: dumpEqns2
 
  Helper function to dump_eqns
"
  input list<Equation> inEquationLst;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inEquationLst,inInteger)
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

public function equationStr "function: equationStr
 
  Helper function to e.g. dump.
"
  input Equation inEquation;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEquation)
    local
      String s1,s2,res,indx_str,is,var_str;
      Exp.Exp e1,e2,e;
      Value indx,i;
      list<Exp.Exp> expl;
      Exp.ComponentRef cr;
    case (EQUATION(exp = e1,scalar = e2))
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
        res = Util.stringAppendList({"Array eqn no: ",indx_str,"for variables:",var_str,"\n"});
      then
        res;
    case (SOLVED_EQUATION(componentRef = cr,exp = e2))
      equation 
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({s1," := ",s2});
      then
        res;
    case (WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e2)))
      equation 
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        is = intString(i);
        res = Util.stringAppendList({s1," := ",s2,"when clause no:",is,"\n"});
      then
        res;
    case (RESIDUAL_EQUATION(exp = e))
      equation 
        s1 = Exp.printExpStr(e);
        res = Util.stringAppendList({s1,"= 0"});
      then
        res;
    case (ALGORITHM(index = i))
      equation 
        is = intString(i);
        res = Util.stringAppendList({"Algorithm no: ",is,"\n"});
      then
        res;
  end matchcontinue;
end equationStr;

protected function removeSimpleEquations "function: removeSimpleEquations
 
  This function moves simple equations on the form a=b from equations 2nd 
  in DAELow to simple equations 3rd in DAELow to speed up assignment alg.
  inputs:  (vars: Variables,
              knownVars: Variables,
              eqns: Equation list,
              simpleEqns: Equation list,
	      initEqns : Equatoin list,
              binTree: BinTree) 
  outputs: (Variables, Variables, Equation list, Equation list
 	      Equation list)
"
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
algorithm 
  (outVariables1,outVariables2,outEquationLst3,outEquationLst4,outEquationLst5,outArrayEquationLst):=
  matchcontinue (inVariables1,inVariables2,inEquationLst3,inEquationLst4,inEquationLst5,inArrayEquationLst,inBinTree6)
    local
      VarTransform.VariableReplacements repl,vartransf;
      list<Equation> eqns_1,seqns,eqns_2,seqns_1,ieqns_1,eqns_3,seqns_2,ieqns_2,seqns_3,eqns,reqns,ieqns;
      list<MultiDimEquation> arreqns,arreqns1,arreqns2;
      BinTree movedvars_1,states;
      Variables vars_1,knvars_1,vars,knvars;
    case (vars,knvars,eqns,reqns,ieqns,arreqns,states)
      equation 
        repl = VarTransform.emptyReplacements();
        (eqns_1,seqns,movedvars_1,vartransf) = removeSimpleEquations2(eqns, vars, knvars, emptyBintree, states, repl);
        Debug.fcall("dumprepl", VarTransform.dumpReplacements, vartransf);
        eqns_2 = VarTransform.replaceEquations(eqns_1, vartransf);
        seqns_1 = VarTransform.replaceEquations(seqns, vartransf);
        ieqns_1 = VarTransform.replaceEquations(ieqns, vartransf);
        arreqns1 = VarTransform.replaceMultiDimEquations(arreqns, vartransf);
        (vars_1,knvars_1) = moveVariables(vars, knvars, movedvars_1);
        eqns_3 = renameDerivatives(eqns_2);
        seqns_2 = renameDerivatives(seqns_1);
        ieqns_2 = renameDerivatives(ieqns_1);
        arreqns2 = renameMultiDimDerivatives(arreqns1);
        seqns_3 = listAppend(seqns_2, reqns) "& print_vars_statistics(vars\',knvars\')" ;
      then
        (vars_1,knvars_1,eqns_3,seqns_3,ieqns_2,arreqns2);
    case (_,_,_,_,_,_,_)
      equation 
        print("-remove_simple_equations failed\n");
      then
        fail();
  end matchcontinue;
end removeSimpleEquations;

protected function renameDerivatives "function: renameDerivatives
  author: PA
 
  Renames $DER$x to der(x) for all equations given as argument.
 
"
  input list<Equation> inEquationLst;
  output list<Equation> outEquationLst;
algorithm 
  outEquationLst:=
  matchcontinue (inEquationLst)
    local
      Exp.Exp e1_1,e2_1,e1,e2;
      list<Equation> es_1,es;
      Exp.ComponentRef cr1;
      Equation e;
    case ({}) then {}; 
    case ((EQUATION(exp = e1,scalar = e2) :: es))
      equation 
        ((e1_1,_)) = Exp.traverseExp(e1, renameDerivativesExp, "$DER$");
        ((e2_1,_)) = Exp.traverseExp(e2, renameDerivativesExp, "$DER$");
        es_1 = renameDerivatives(es);
      then
        (EQUATION(e1_1,e2_1) :: es_1);
    case ((SOLVED_EQUATION(componentRef = cr1,exp = e1) :: es))
      equation 
        ((e1_1,_)) = Exp.traverseExp(e1, renameDerivativesExp, "$DER$");
        es_1 = renameDerivatives(es);
      then
        (SOLVED_EQUATION(cr1,e1_1) :: es_1);
    case ((e :: es))
      equation 
        es_1 = renameDerivatives(es);
      then
        (e :: es_1);
  end matchcontinue;
end renameDerivatives;

protected function renameMultiDimDerivatives "function: renameMultiDimDerivatives
  author: PA
 
  Renames $DER$x to der(x) for all array equations given as argument.
 
"
  input list<MultiDimEquation> inEquationLst;
  output list<MultiDimEquation> outEquationLst;
algorithm 
  outEquationLst:=
  matchcontinue (inEquationLst)
    local
      Exp.Exp e1_1,e2_1,e1,e2;
      list<MultiDimEquation> es_1,es;
      Exp.ComponentRef cr1;
      Equation e;
      list<Integer> dims;
    case ({}) then {}; 
    case ((MULTIDIM_EQUATION(left= e1,right= e2,dimSize=dims) :: es))
      equation 
        ((e1_1,_)) = Exp.traverseExp(e1, renameDerivativesExp, "$DER$");
        ((e2_1,_)) = Exp.traverseExp(e2, renameDerivativesExp, "$DER$");
        es_1 = renameMultiDimDerivatives(es);
      then
        (MULTIDIM_EQUATION(dims,e1_1,e2_1) :: es_1);
  end matchcontinue;
end renameMultiDimDerivatives;


protected function renameDerivativesExp "function renameDerivativesExp
  
  Renames \"$derivative$x\" to der(x)
"
  input tuple<Exp.Exp, String> inTplExpExpString;
  output tuple<Exp.Exp, String> outTplExpExpString;
algorithm 
  outTplExpExpString:=
  matchcontinue (inTplExpExpString)
    local
      Value slen;
      String id_1,id,str;
      list<Exp.Subscript> s;
      Exp.Type tp;
      Exp.Exp e;
    case ((Exp.CREF(componentRef = Exp.CREF_IDENT(ident = id,subscriptLst = s),ty = tp),str))
      equation 
        slen = stringLength(str);
        true = Util.strncmp(str, id, slen);
        id_1 = System.stringReplace(id, str, "");
      then
        ((
          Exp.CALL(Absyn.IDENT("der"),{Exp.CREF(Exp.CREF_IDENT(id_1,s),tp)},
          false,true,Exp.REAL()),str));
    case ((e,str)) then ((e,str)); 
  end matchcontinue;
end renameDerivativesExp;

protected function renameDerivatives2 "function: renameDerivatives2
  author: PA
 
  Renames der(x) to $DER$x for all equations given as argument.
 
"
  input list<Equation> inEquationLst;
  output list<Equation> outEquationLst;
algorithm 
  outEquationLst:=
  matchcontinue (inEquationLst)
    local
      Exp.Exp e1_1,e2_1,e1,e2;
      list<Equation> es_1,es;
      Exp.ComponentRef cr1;
      Equation e;
    case ({}) then {}; 
    case ((EQUATION(exp = e1,scalar = e2) :: es))
      equation 
        ((e1_1,_)) = Exp.traverseExp(e1, renameDerivativesExp2, "$DER$");
        ((e2_1,_)) = Exp.traverseExp(e2, renameDerivativesExp2, "$DER$");
        es_1 = renameDerivatives2(es);
      then
        (EQUATION(e1_1,e2_1) :: es_1);
    case ((SOLVED_EQUATION(componentRef = cr1,exp = e1) :: es))
      equation 
        ((e1_1,_)) = Exp.traverseExp(e1, renameDerivativesExp2, "$DER$");
        es_1 = renameDerivatives2(es);
      then
        (SOLVED_EQUATION(cr1,e1_1) :: es_1);
    case ((e :: es))
      equation 
        es_1 = renameDerivatives2(es);
      then
        (e :: es_1);
  end matchcontinue;
end renameDerivatives2;

protected function renameDerivativesExp2 "function rename_derivatives_exp
  
  Renames  der(x) to \"$DER$x\"
"
  input tuple<Exp.Exp, String> inTplExpExpString;
  output tuple<Exp.Exp, String> outTplExpExpString;
algorithm 
  outTplExpExpString:=
  matchcontinue (inTplExpExpString)
    local
      String id,id_1,str;
      Exp.ComponentRef cr_1,cr;
      Exp.Type tp;
      Exp.Exp e;
    case ((Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr,ty = tp)},tuple_ = false,builtin = true),str))
      equation 
        id = Exp.printComponentRefStr(cr);
        id_1 = stringAppend(str, id);
        cr_1 = Exp.CREF_IDENT(id_1,{});
      then
        ((Exp.CREF(cr_1,tp),str));
    case ((e,str)) then ((e,str)); 
  end matchcontinue;
end renameDerivativesExp2;


protected function removeSimpleEquations2 "Traverses all equations and puts those that are simple in 
a separate list. It builds a set of varable replacements that are later used to replace these variable
substitutions in the equations that are left."
  input list<Equation> eqns;
  input Variables vars;
  input Variables knvars;
  input BinTree mvars;
  input BinTree states;
  input VarTransform.VariableReplacements repl;
  output list<Equation> outEqns;
  output list<Equation> outSimpleEqns;
  output BinTree outMvars;
  output VarTransform.VariableReplacements outRepl;
algorithm 
  (outEqns,outSimpleEqns,outMvars,outRepl):=
  matchcontinue (eqns,vars,knvars,mvars,states,repl)
    local
      Variables vars,knvars;
      BinTree mvars,states,mvars_1,mvars_2;
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      Exp.ComponentRef cr1,cr2;
      list<Equation> eqns_1,seqns_1,eqns;
      Equation e;
      Exp.Type t;
      Exp.Exp e1,e2;
    case ({},vars,knvars,mvars,states,repl) then ({},{},mvars,repl); 
      
    case (e::eqns,vars,knvars,mvars,states,repl) equation
      {e} = VarTransform.replaceEquations({e},repl);
      (e1 as Exp.CREF(cr1,_),e2) = simpleEquation(e,false);
      failure(_ = treeGet(states, cr1)) "cr1 not state";
      isVariable(cr1, vars, knvars) "cr1 not constant";
      false = isTopLevelInputOrOutput(cr1,vars,knvars);
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      mvars_1 = treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2) = removeSimpleEquations2(eqns, vars, knvars, mvars_1, states, repl_1);
    then
      (eqns_1,(SOLVED_EQUATION(cr1,e2) :: seqns_1),mvars_2,repl_2);
      
      // Swapped args
    case (e::eqns,vars,knvars,mvars,states,repl) equation
      {EQUATION(e1,e2)} = VarTransform.replaceEquations({e},repl);
      (e1 as Exp.CREF(cr1,_),e2) = simpleEquation(EQUATION(e2,e1),true);
      failure(_ = treeGet(states, cr1)) "cr1 not state";
      isVariable(cr1, vars, knvars) "cr1 not constant";
      repl_1 = VarTransform.addReplacement(repl, cr1, e2);
      false = isTopLevelInputOrOutput(cr1,vars,knvars);
      mvars_1 = treeAdd(mvars, cr1, 0);
      (eqns_1,seqns_1,mvars_2,repl_2) = removeSimpleEquations2(eqns, vars, knvars, mvars_1, states, repl_1);
    then
      (eqns_1,(SOLVED_EQUATION(cr1,e2) :: seqns_1),mvars_2,repl_2);
      
      // try next equation.
    case ((e :: eqns),vars,knvars,mvars,states,repl)
      local Equation eq1;
      equation 
        {eq1} = VarTransform.replaceEquations({e},repl);
        //print("not removed simple ");print(equationStr(e));print("\n     -> ");print(equationStr(eq1));
        //print("\n\n");
        (eqns_1,seqns_1,mvars_1,repl_1) = removeSimpleEquations2(eqns, vars, knvars, mvars, states, repl) "Not a simple variable, check rest" ;
      then
        ((e :: eqns_1),seqns_1,mvars_1,repl_1);
  end matchcontinue;
end removeSimpleEquations2;

public function countSimpleEquations "Counts the number of trivial/simple equations
e.g on form a=b, a=-b or a=constant
"
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
        (_,_) = simpleEquation(e,false);
        partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);

      // Swaped args in simpleEquation
    case (e::eqns,partialSum) equation
      (_,_) = simpleEquation(e,true);
      partialSum = partialSum +1;
    then countSimpleEquations2(eqns,partialSum);  

      //Not simple eqn.
    case (e::eqns,partialSum)
    then countSimpleEquations2(eqns,partialSum);
  end matchcontinue;
end countSimpleEquations2;

public function simpleEquation "Returns the two sides of an equation as expressions if it is a 
simple equation. Simple equations are
a+b=0, a-b=0, a=constant, a=-b, etc.
The first expression returned, e1, is always a CREF.

If the equation is not simple, this function will fail.
 "

  input Equation eqn; 
  input Boolean swap "if true swap args.";
  output Exp.Exp e1;
  output Exp.Exp e2;
algorithm 
  (e1,e2):=
  matchcontinue (eqn,swap)
      local 
        Exp.Exp e;
        Exp.Type t;
      // a = b;
      case (EQUATION(e1 as Exp.CREF(componentRef = _),e2 as  Exp.CREF(componentRef = _)),swap) 
        equation 
					true = RTOpts.eliminationLevel() > 0;
					true = RTOpts.eliminationLevel() <> 3;
        then (e1,e2); 
        // a-b = 0
    case (EQUATION(Exp.BINARY(e1 as  Exp.CREF(_,_),Exp.SUB(_),e2 as Exp.CREF(_,_)),e),false)
      equation 
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2);
    	// a-b = 0 swap
    case (EQUATION(Exp.BINARY(e1 as  Exp.CREF(_,_),Exp.SUB(_),e2 as Exp.CREF(_,_)),e),true)
      equation 
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1);
        // 0 = a-b  
    case (EQUATION(e,Exp.BINARY(e1 as  Exp.CREF(_,_),Exp.SUB(_),e2 as Exp.CREF(_,_))),false)
      equation 
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e1,e2);

        // 0 = a-b  swap
    case (EQUATION(e,Exp.BINARY(e1 as  Exp.CREF(_,_),Exp.SUB(_),e2 as Exp.CREF(_,_))),false)
      equation 
        true = RTOpts.eliminationLevel() > 0;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then
        (e2,e1);
       
        // a + b = 0
     case (EQUATION(Exp.BINARY(e1 as Exp.CREF(_,_),Exp.ADD(t),e2 as Exp.CREF(_,_)),e),false) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;       
      true = Exp.isZero(e);
      then (e1,Exp.UNARY(Exp.UMINUS(t),e2));
   
           // a + b = 0 swap
     case (EQUATION(Exp.BINARY(e1 as Exp.CREF(_,_),Exp.ADD(t),e2 as Exp.CREF(_,_)),e),true) equation
       true = RTOpts.eliminationLevel() > 1;
       true = RTOpts.eliminationLevel() <> 3;
       true = Exp.isZero(e);
     then (e2,Exp.UNARY(Exp.UMINUS(t),e1));
        
      // 0 = a+b
    case (EQUATION(e,Exp.BINARY(e1 as Exp.CREF(_,_),Exp.ADD(t),e2 as Exp.CREF(_,_))),false) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e1,Exp.UNARY(Exp.UMINUS(t),e2)); 
     
      // 0 = a+b swap
    case (EQUATION(e,Exp.BINARY(e1 as Exp.CREF(_,_),Exp.ADD(t),e2 as Exp.CREF(_,_))),true) equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
      true = Exp.isZero(e);
      then (e2,Exp.UNARY(Exp.UMINUS(t),e1)); 
        
     // a = -b
    case (EQUATION(e1 as Exp.CREF(_,_),e2 as Exp.UNARY(Exp.UMINUS(_),Exp.CREF(_,_))),swap) 
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2);
        
      // -a = b => a = -b
    case (EQUATION(Exp.UNARY(Exp.UMINUS(t),e1 as Exp.CREF(_,_)),e2 as Exp.CREF(_,_)),swap) 
      equation
      true = RTOpts.eliminationLevel() > 1;
      true = RTOpts.eliminationLevel() <> 3;
    then (e1,Exp.UNARY(Exp.UMINUS(t),e2));
        
      // -b - a = 0 => a = -b
    case (EQUATION(Exp.BINARY(e2 as Exp.UNARY(Exp.UMINUS(_),Exp.CREF(_,_)),Exp.SUB(_),e1 as Exp.CREF(_,_)),e),false) 
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2);   
        
          // -b - a = 0 => a = -b swap
    case (EQUATION(Exp.BINARY(Exp.UNARY(Exp.UMINUS(t),e2 as Exp.CREF(_,_)),Exp.SUB(_),e1 as Exp.CREF(_,_)),e),true) 
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,Exp.UNARY(Exp.UMINUS(t),e1)); 

        // 0 = -b - a => a = -b
    case (EQUATION(e,Exp.BINARY(e2 as Exp.UNARY(Exp.UMINUS(_),Exp.CREF(_,_)),Exp.SUB(_),e1 as Exp.CREF(_,_))),false)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e1,e2);   
        
        // 0 = -b - a => a = -b swap
    case (EQUATION(e,Exp.BINARY(Exp.UNARY(Exp.UMINUS(t),e2 as Exp.CREF(_,_)),Exp.SUB(_),e1 as Exp.CREF(_,_))),true)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
        true = Exp.isZero(e);
      then (e2,Exp.UNARY(Exp.UMINUS(t),e1));   
        
        // -a = -b
    case (EQUATION(Exp.UNARY(Exp.UMINUS(_),e1 as Exp.CREF(_,_)),Exp.UNARY(Exp.UMINUS(_),e2 as Exp.CREF(_,_))),swap)
      equation
        true = RTOpts.eliminationLevel() > 1;
        true = RTOpts.eliminationLevel() <> 3;
      then (e1,e2);
        // a = constant
    case (EQUATION(e1 as Exp.CREF(_,_),e),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,e);
        
        // -a = constant
    case (EQUATION(Exp.UNARY(Exp.UMINUS(t),e1 as Exp.CREF(_,_)),e),swap) equation
      true = RTOpts.eliminationLevel() > 1;
      true = Exp.isConst(e);
      then (e1,Exp.UNARY(Exp.UMINUS(t),e));        
  end matchcontinue;
end simpleEquation;

protected function isTopLevelInputOrOutput "function isTopLevelInputOrOutput
  author: LP
 
  This function checks if the provided cr is from a var that is on top model
  and is an input or an output, and returns true for such variables.
  It also returns true for input/output connector variables, i.e. variables 
  instantiated from a  connector class, that are instantiated on the top level.
  The check for top-model is done by spliting the old name at \'.\' and 
  check if the list-lenght is 1.
  Note: The function needs the known variables to search for input variables 
  on the top level.
  inputs:  (cref: Exp.ComponentRef, 
              vars: Variables, /* Variables */
              knownVars: Variables /* Known Variables */) 
  outputs: bool
"
  input Exp.ComponentRef inComponentRef1;
  input Variables inVariables2;
  input Variables inVariables3;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      Exp.ComponentRef cr;
      VarKind kind;
      DAE.Flow flow_;
      Variables vars,knvars;
    case (cr,vars,_)
      equation 
        ((VAR(cr,kind,DAE.OUTPUT(),_,_,_,_,_,_,Exp.CREF_IDENT(_,_),_,_,_,flow_) :: _),_) = getVar(cr, vars);
      then
        true;
    case (cr,vars,knvars)
      equation 
        ((VAR(cr,kind,DAE.INPUT(),_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, knvars) "input variables stored in known variables are input on top level" ;
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
end isTopLevelInputOrOutput;

public function isVarOnTopLevelAndOutput "function isVarOnTopLevelAndOutput
 
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = OUTPUT
  The check for top-model is done by spliting the old name at \'.\' and 
  check if the list-lenght is 1
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local
      Exp.ComponentRef cr,old_name;
      VarKind kind;
      DAE.VarDirection dir;
      DAE.Flow flow_;
    case (VAR(varName = cr,varKind = kind,varDirection = dir,origVarName = old_name,flow_ = flow_))
      equation 
        topLevelOutput(cr, dir, flow_);
      then
        true;
    case (_) then false; 
  end matchcontinue;
end isVarOnTopLevelAndOutput;

public function isVarOnTopLevelAndInput "function isVarOnTopLevelAndInput
 
  this function checks if the provided cr is from a var that is on top model
  and has the DAE.VarDirection = INPUT
  The check for top-model is done by spliting the old name at \'.\' and 
  check if the list-lenght is 1
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local
      Exp.ComponentRef cr,old_name;
      VarKind kind;
      DAE.VarDirection dir;
      DAE.Flow flow_;
    case (VAR(varName = cr,varKind = kind,varDirection = dir,origVarName = old_name,flow_ = flow_))
      equation 
        topLevelInput(old_name, dir, flow_);
      then
        true;
    case (_) then false; 
  end matchcontinue;
end isVarOnTopLevelAndInput;

protected function typeofEquation "function: typeofEquation
 
  Returns the Exp.Type of an equation
"
  input Equation inEquation;
  output Exp.Type outType;
algorithm 
  outType:=
  matchcontinue (inEquation)
    local
      Exp.Type t;
      Exp.Exp e;
    case (EQUATION(exp = e))
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

protected function moveVariables "function: moveVariables
 
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

protected function moveVariables2 "function: moveVariables2
 
  helper function to move_variables.
  inputs:  (Var list,	/* alg+state vars as list */
              Var list,	/* known vars as list */
              BinTree)	/* move-variables as BinTree */
  outputs: (Var list,	/* updated alg+state vars as list */
              Var list)	/* update known vars as list */
"
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
      Exp.ComponentRef cr;
      DAE.Flow flow_;
      BinTree mvars;
    case ({},knvars,_) then ({},knvars); 
    case (((v as VAR(varName = cr,flow_ = flow_)) :: vs),knvars,mvars)
      equation 
        _ = treeGet(mvars, cr) "alg var moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        (vs_1,(v :: knvars_1));
    case (((v as VAR(varName = cr,flow_ = flow_)) :: vs),knvars,mvars)
      equation 
        failure(_ = treeGet(mvars, cr)) "alg var not moved to known vars" ;
        (vs_1,knvars_1) = moveVariables2(vs, knvars, mvars);
      then
        ((v :: vs_1),knvars_1);
  end matchcontinue;
end moveVariables2;

protected function isVariable "function: isVariable
 
  This function takes a Exp.ComponentRef and two Variables. It searches
  the two sets of variables and succeed if the variable is STATE or 
  VARIABLE. Otherwise it fails.
  Note: An array variable is currently assumed that each scalar element has
  the same type.
  inputs:  (Exp.ComponentRef, 
              Variables, /* vars */
              Variables) /* known vars */
  outputs: ()
"
  input Exp.ComponentRef inComponentRef1;
  input Variables inVariables2;
  input Variables inVariables3;
algorithm 
  _:=
  matchcontinue (inComponentRef1,inVariables2,inVariables3)
    local
      DAE.Flow flow_;
      Exp.ComponentRef cr;
      Variables vars,knvars;
    case (cr,vars,_)
      equation 
        ((VAR(_,VARIABLE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation 
        ((VAR(_,STATE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation 
        ((VAR(_,DUMMY_STATE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,vars,_)
      equation 
        ((VAR(_,DUMMY_DER(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, vars);
      then
        ();
    case (cr,_,knvars)
      equation 
        ((VAR(_,VARIABLE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation 
        ((VAR(_,DUMMY_STATE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, knvars);
      then
        ();
    case (cr,_,knvars)
      equation 
        ((VAR(_,DUMMY_DER(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, knvars);
      then
        ();
  end matchcontinue;
end isVariable;

protected function removeVariableNamed "function: removeVariableNamed
 
  Removes a varaible from the \'Variables\' set given a ComponentRef name.
  The removed variable is returned, such that is can be used elsewhere.
"
  input Variables inVariables;
  input Exp.ComponentRef inComponentRef;
  output Variables outVariables;
  output Var outVar;
algorithm 
  (outVariables,outVar):=
  matchcontinue (inVariables,inComponentRef)
    local
      String str;
      Variables vars,vars_1;
      Exp.ComponentRef cr;
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

protected function dumpExtObjCls " dump classes of external objects"
input ExternalObjectClasses cls;
algorithm
  _ := matchcontinue(cls)
    case {} then ();
      
    case EXTOBJCLASS(path,constr,destr)::xs 
      local ExternalObjectClasses xs;
        DAE.Element constr,destr;
        Absyn.Path path;
        equation
          print("class ");
          print(Absyn.pathString(path));
          print("\n  extends ExternalObject");
          print(DAE.dumpFunctionStr(constr));
          print("\n");
          print(DAE.dumpFunctionStr(destr));
          print("end ");print(Absyn.pathString(path));          
        then ();
  end matchcontinue;
end dumpExtObjCls;

public function dumpVars "function: dumpVars
 
  Helper function to dump.
"
  input list<Var> vars;
algorithm 
  dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2 "function: dumpVars2
 
  Helper function to dump_vars.
"
  input list<Var> inVarLst;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str;
      list<String> paths_lst,path_strs;
      Value varno_1,indx,varno;
      Var v;
      Exp.ComponentRef cr,old_name;
      VarKind kind;
      DAE.VarDirection dir;
      Exp.Exp e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      DAE.StartValue start;
      list<Var> xs;
      DAE.Type var_type;
    case ({},_) then (); 
    case (((v as VAR(varName = cr,varKind = kind,varDirection = dir,varType = var_type,bindExp = SOME(e),index = indx,origVarName = old_name,className = paths,values = dae_var_attr,comment = comment,flow_ = flow_,startValue=start)) :: xs),varno)
      equation 
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAE.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = Exp.printComponentRefStr(cr);
        print(str);
        print(":");
        dumpKind(kind);
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print("= ");
        s = Exp.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx) "print \"  \" & print comment_str &
        
        print \" former: \" & print old_name &" ;
        
           str = DAE.dumpTypeStr(var_type);print( " type: "); print(str); 
        
        print(" indx = ");
        print(indx_str);
        varno_1 = varno + 1;
        //print(" start:");print(Dump.getOptionStr(start,Exp.printExpStr));
        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        dumpVars2(xs, varno_1) "DAE.dump_variable_attributes(dae_var_attr) &" ;
      then
        ();
    case (((v as VAR(varName = cr,varKind = kind,varDirection = dir,varType = var_type,bindExp = NONE,index = indx,origVarName = old_name,className = paths,values = dae_var_attr,comment = comment,flow_ = flow_,startValue=start)) :: xs),varno)
      equation 
        varnostr = intString(varno);
        print(varnostr);
        print(": ");
        dirstr = DAE.dumpDirectionStr(dir);
        print(dirstr);
        print(" ");
        str = Exp.printComponentRefStr(cr);
        path_strs = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(path_strs, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print(str);
        print(":");
        dumpKind(kind);
        print(" ");
        print(path_str);
        indx_str = intString(indx) "print \" former: \" & print old_name &" ;

        
        str = DAE.dumpTypeStr(var_type);print( " type: "); print(str); 
        

        print(" indx = ");
        print(indx_str);
        //print(" start:");print(Dump.getOptionStr(start,Exp.printExpStr));
        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n")  ;
        varno_1 = varno + 1;
        dumpVars2(xs, varno_1);
      then
        ();
  end matchcontinue;
end dumpVars2;

protected function dumpKind "function: dumpKind
 
  Helper function to dump.
"
  input VarKind inVarKind;
algorithm 
  _:=
  matchcontinue (inVarKind)
    case VARIABLE()
      equation 
        print("VARIABLE");
      then
        ();
    case STATE()
      equation 
        print("STATE");
      then
        ();
    case DUMMY_DER()
      equation 
        print("DUMMY_DER");
      then
        ();
    case DUMMY_STATE()
      equation 
        print("DUMMY_STATE");
      then
        ();
    case DISCRETE()
      equation 
        print("DISCRETE");
      then
        ();
    case PARAM()
      equation 
        print("PARAM");
      then
        ();
    case CONST()
      equation 
        print("CONST");
      then
        ();
    case EXTOBJ(path)
      local Absyn.Path path;
      equation
        print("EXTOBJ: ");print(Absyn.pathString(path));
      then ();
          
  end matchcontinue;
end dumpKind;

public function states "function: states
 
  Returns a BinTree of all states in the DAE.
  This function is used by the lower function.
"
  input DAE.DAElist inDAElist;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm 
  outBinTree:=
  matchcontinue (inDAElist,inBinTree)
    local
      BinTree bt;
      Exp.Exp e1,e2;
      list<DAE.Element> xs;
      DAE.DAElist dae;
    case (DAE.DAE(elementLst = {}),bt) then bt; 
    case (DAE.DAE(elementLst = (DAE.EQUATION(exp = e1,scalar = e2) :: xs)),bt)
      equation 
        bt = states(DAE.DAE(xs), bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.DAE(elementLst = (DAE.INITIALEQUATION(e1,e2) :: xs)),bt)
      equation 
        bt = states(DAE.DAE(xs), bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;

    case (DAE.DAE(elementLst = (DAE.DEFINE(_,e2) :: xs)),bt)
      equation 
        bt = states(DAE.DAE(xs), bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.DAE(elementLst = (DAE.INITIALDEFINE(_,e2) :: xs)),bt)
      equation 
        bt = states(DAE.DAE(xs), bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.DAE(elementLst = (DAE.ARRAY_EQUATION(exp = e1,array = e2) :: xs)),bt)
      equation 
        bt = states(DAE.DAE(xs), bt);
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (DAE.DAE(elementLst = (DAE.COMP(dAElist = dae) :: xs)),bt)
      equation 
        bt = states(dae, bt);
        bt = states(DAE.DAE(xs), bt);
      then
        bt;
    case (DAE.DAE(elementLst = (_ :: xs)),bt)
      equation 
        bt = states(DAE.DAE(xs), bt);
      then
        bt;
  end matchcontinue;
end states;

protected function statesDaelow "function: statesDaelow
  author: PA
 
  Returns a BinTree of all states in the DAELow
  This function is used in matching algorithm.
"
  input DAELow inDAELow;
  output BinTree outBinTree;
algorithm 
  outBinTree:=
  matchcontinue (inDAELow)
    local
      list<Var> v_lst;
      BinTree bt;
      Variables v,kn;
      EquationArray e,re,ia;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo ev;
    case (DAELOW(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = re,initialEqs = ia,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation 
        v_lst = varList(v);
        bt = statesDaelow2(v_lst, emptyBintree);
      then
        bt;
  end matchcontinue;
end statesDaelow;

protected function statesDaelow2 "function: statesDaelow2
  author: PA
 
  Helper function to states_daelow.
"
  input list<Var> inVarLst;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm 
  outBinTree:=
  matchcontinue (inVarLst,inBinTree)
    local
      BinTree bt;
      Exp.ComponentRef cr;
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
    case ((v :: vs),bt)
      equation 
        DUMMY_STATE() = varKind(v);
        cr = varCref(v);
        bt = treeAdd(bt, cr, 0);
        bt = statesDaelow2(vs, bt);
      then
        bt;
    case ((v :: vs),bt)
      equation 
        bt = statesDaelow2(vs, bt);
      then
        bt;
  end matchcontinue;
end statesDaelow2;

protected function statesExp "function: statesExp
 
  Helper function to states.
"
  input Exp.Exp inExp;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm 
  outBinTree:=
  matchcontinue (inExp,inBinTree)
    local
      BinTree bt;
      Exp.Exp e1,e2,e,e3;
      Exp.ComponentRef cr_1,cr;
      list<Exp.Exp> expl;
      list<list<tuple<Exp.Exp, Boolean>>> m;
    case (Exp.BINARY(exp1 = e1,exp2 = e2),bt)
      equation 
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (Exp.UNARY(exp = e),bt)
      equation 
        bt = statesExp(e, bt);
      then
        bt;
    case (Exp.LBINARY(exp1 = e1,exp2 = e2),bt)
      equation 
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (Exp.LUNARY(exp = e),bt)
      equation 
        bt = statesExp(e, bt);
      then
        bt;
    case (Exp.RELATION(exp1 = e1,exp2 = e2),bt)
      equation 
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),bt)
      equation 
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
        bt = statesExp(e3, bt);
      then
        bt;
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),bt)
      equation 
        cr_1 = Exp.stringifyComponentRef(cr) "value irrelevant, give zero" ;
        bt = treeAdd(bt, cr_1, 0);
      then
        bt;
    case (Exp.CALL(expLst = expl),bt)
      equation 
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (Exp.ARRAY(array = expl),bt)
      equation 
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (Exp.MATRIX(scalar = m),bt)
      equation 
        bt = statesExpMatrix(m, bt);
      then
        bt;
    case (Exp.TUPLE(PR = expl),bt)
      equation 
        bt = Util.listFold(expl, statesExp, bt);
      then
        bt;
    case (Exp.CAST(exp = e),bt)
      equation 
        bt = statesExp(e, bt);
      then
        bt;
    case (Exp.ASUB(exp = e),bt)
      equation 
        bt = statesExp(e, bt);
      then
        bt;
    case (Exp.REDUCTION(expr = e1,range = e2),bt)
      equation 
        bt = statesExp(e1, bt);
        bt = statesExp(e2, bt);
      then
        bt;
    case (_,bt) then bt; 
  end matchcontinue;
end statesExp;

protected function statesExpMatrix "function: statesExpMatrix
  author: PA
  
  Helper function to states_exp. Deals with matrix exp list.
"
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BinTree inBinTree;
  output BinTree outBinTree;
algorithm 
  outBinTree:=
  matchcontinue (inTplExpExpBooleanLstLst,inBinTree)
    local
      list<list<Exp.Exp>> expl_1;
      list<Exp.Exp> expl_2;
      BinTree bt;
      list<list<tuple<Exp.Exp, Boolean>>> expl;
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

protected function lowerWhenEqn "
  This function lowers a when clause. The condition expresion is put in the 
  WhenClause list and the equations inside are put in the equation list.
  For each equation in the clause a new entry in the WhenClause list is generated
  and one extra for all the reinit statements.
  inputs:  (DAE.Element, int /* when-clause index */, WhenClause list)  
  outputs: (Equation list, Variables, int /* when-clause index */, WhenClause list)
"
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
      Exp.Exp cond;
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
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        tot_count = equation_count + extra;
        (res1,i_1,whenClauseList3) = mergeClauses(trueEqnLst,elseEqnLst,whenClauseList2,
          elseClauseList,nextWhenIndex + tot_count);
      then
        (res1,vars,i_1,whenClauseList3);
    case (DAE.WHEN_EQUATION(condition = cond),_,_)
      equation
        print("fel i lowerWhenEqn");
      then fail();  
  end matchcontinue;
end lowerWhenEqn;

protected function mergeClauses "
merges the true part end the elsewhen part of a set of when equations.
For each equation in trueEqnList, find an equation in elseEqnList solving the same variable
and put it in the else elseWhenPart of the first equation.
"
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
      Exp.ComponentRef cr;
      Exp.Exp rightSide;
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
    case (WHEN_EQUATION(WHEN_EQ(index = ind,left = cr,right=rightSide))::trueEqns, elseEqns,trueCls,elseCls,nextInd)
      equation
        (foundEquation, elseEqnsRest) = getWhenEquationFromVariable(cr,elseEqns);
        res = WHEN_EQUATION(WHEN_EQ(ind,cr,rightSide,SOME(foundEquation)));
        (resRest, outNextIndex, outClauseList) = mergeClauses(trueEqns,elseEqnsRest,trueCls, elseCls,nextInd);
      then (res::resRest, outNextIndex, outClauseList);
    case ({},{},trueCls,elseCls,nextInd)
    then ({},nextInd,listAppend(trueCls,elseCls));
        
  end matchcontinue;
end mergeClauses;

protected function getWhenEquationFromVariable
"Finds the when equation solving the variable given by inCr among equations in inEquations
 the found equation is then taken out of the list."
  input Exp.ComponentRef inCr;
  input list<Equation> inEquations;
  output WhenEquation outEquation;
  output list<Equation> outEquations;
algorithm
  (outEquation, outEquations) := matchcontinue(inCr,inEquations)
    local
      Exp.ComponentRef cr1,cr2;
      WhenEquation eq;
      Equation eq2;
      list<Equation> rest, rest2;
    case (cr1,WHEN_EQUATION(eq as WHEN_EQ(left=cr2))::rest)
      equation
        true = Exp.crefEqual(cr1,cr2);
      then (eq, rest);
    case (cr1,(eq2 as WHEN_EQUATION(WHEN_EQ(left=cr2)))::rest)
      equation
        false = Exp.crefEqual(cr1,cr2);
        (eq,rest2) = getWhenEquationFromVariable(cr1,rest);
      then (eq, eq2::rest2);
    case (_,{}) 
      equation
        Error.addMessage(Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, 
          {});
      then
        fail();
        
  end matchcontinue;
end getWhenEquationFromVariable;

protected function makeWhenClauses "function: makeWhenClauses
  Constructs a list of identical WhenClause elements
  Arg1: Number of elements to construct
  Arg2: condition expression of the when clause
  outputs: (WhenClause list)
"
  input Integer n           "Number of copies to make.";
  input Exp.Exp inCondition "the condition expression";
  input list<ReinitStatement> inReinitStatementLst;
  output list<WhenClause> outWhenClauseLst;
algorithm 
  outWhenClauseLst:=
  matchcontinue (n,inCondition,inReinitStatementLst)
    local
      Value i_1,i;
      list<WhenClause> res;
      Exp.Exp cond;
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

protected function lowerWhenEqn2 "
  Helper function to lower_when_eqn. Lowers the equations inside a when clause
"
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
      Exp.Exp e_2,cre,e;
      Exp.ComponentRef cr_1,cr;
      list<DAE.Element> xs;
    case ({},_) then ({},{}); 
    case ((DAE.EQUATION(exp = (cre as Exp.CREF(componentRef = cr)),scalar = e) :: xs),i)
      equation 
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
        e_2 = Exp.stringifyCrefs(Exp.simplify(e));
        cr_1 = Exp.stringifyComponentRef(cr);
      then
        ((WHEN_EQUATION(WHEN_EQ(i,cr_1,e_2,NONE)) :: eqnl),reinit);
    case ((DAE.REINIT(componentRef = cr,exp = e) :: xs),i)
      equation 
        (eqnl,reinit) = lowerWhenEqn2(xs, i);
        e_2 = Exp.stringifyCrefs(Exp.simplify(e));
        cr_1 = Exp.stringifyComponentRef(cr);
      then
        (eqnl,(REINIT(cr_1,e_2) :: reinit));
  end matchcontinue;
end lowerWhenEqn2;

protected function lower2 "function: lower2
 
  Helper function to lower.
  inputs:  (DAE.DAElist, 
              BinTree /* states */, 
              WhenClause list) 
  outputs: (Variables,
              Variables,
              Equation list,
              Equation list,
              Equation list,
              MultiDimEquation list,
              Algorithm.Algorithm list,
              WhenClause list)
"
  input DAE.DAElist inDAElist;
  input BinTree inBinTree;
  input list<WhenClause> inWhenClauseLst;
  output Variables outVariables1;
  output Variables outVariables2;
  output Variables outVariables3;
  output list<Equation> outEquationLst3;
  output list<Equation> outEquationLst4;
  output list<Equation> outEquationLst5;
  output list<MultiDimEquation> outMultiDimEquationLst6;
  output list<Algorithm.Algorithm> outAlgorithmAlgorithmLst7;
  output list<WhenClause> outWhenClauseLst8;
  output ExternalObjectClasses outExtObjClasses;
algorithm 
  (outVariables1,outVariables2,outVariables3,outEquationLst3,outEquationLst4,outEquationLst5,outMultiDimEquationLst6,outAlgorithmAlgorithmLst7,outWhenClauseLst8,outExtObjClasses):=
  matchcontinue (inDAElist,inBinTree,inWhenClauseLst)
    local
      Variables v1,v2,v3,vars,knvars,extVars,extVars1,extVars2,vars_1,knvars_1,vars1,vars2,knvars1,knvars2,kv;
      list<WhenClause> whenclauses,whenclauses_1,whenclauses_2;
      list<Equation> eqns,reqns,ieqns,eqns1,eqns2,reqns1,ieqns1,reqns2,ieqns2,re,ie;
      list<MultiDimEquation> aeqns,aeqns1,aeqns2,ae;
      list<Algorithm.Algorithm> algs,algs1,algs2,al;
      ExternalObjectClasses extObjCls,extObjCls1,extObjCls2;
      Var v_1;
      DAE.Element v,e;
      list<DAE.Element> xs;
      BinTree states;
      Equation e_1;
      Exp.Exp e1,e2,c;
      list<Value> ds;
      Value count,count_1;
      Algorithm.Algorithm a;
      DAE.DAElist dae;
    case (DAE.DAE(elementLst = {}),_,whenclauses)
      equation 
        v1 = emptyVars();
        v2 = emptyVars();
        v3 = emptyVars();
      then
        (v1,v2,v3,{},{},{},{},{},whenclauses,{});
        
        // External object variables
    case (DAE.DAE(elementLst = ((v as DAE.VAR(componentRef = _)) :: xs)),states,whenclauses)
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
        v_1 = lowerExtObjVar(v);
        extVars2 = addVar(v_1, extVars);
      then
        (vars,knvars,extVars2,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);
        
        // class for External object
    case (DAE.DAE(elementLst = ((v as DAE.EXTOBJECTCLASS(path,constr,destr)) :: xs)),states,whenclauses)
      local 
        Absyn.Path path; 
        DAE.Element constr,destr;
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,
        EXTOBJCLASS(path,constr,destr)::extObjCls);
        
        // variables: states and algebraic variables.
    case (DAE.DAE(elementLst = ((v as DAE.VAR(componentRef = _)) :: xs)),states,whenclauses)
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
        v_1 = lowerVar(v, states);
        vars_1 = addVar(v_1, vars);
      then
        (vars_1,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);
        
        // Known variables: parameters and constants    
    case (DAE.DAE(elementLst = ((v as DAE.VAR(componentRef = _)) :: xs)),states,whenclauses)
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
        v_1 = lowerKnownVar(v) "in previous rule, lower_var failed." ;
        knvars_1 = addVar(v_1, knvars);
      then
        (vars,knvars_1,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);

      /* tuple equations are rewritten to algorihm tuple assign. */ 
    case (DAE.DAE(elementLst = ((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs)),states,whenclauses) 
      equation 
        a = lowerTupleEquation(e);
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        	= lower2(DAE.DAE(xs), states, whenclauses);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,a::algs,whenclauses_1,extObjCls);

        /* scalar equations */ 
    case (DAE.DAE(elementLst = ((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs)),states,whenclauses) 
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
        e_1 = lowerEqn(e);
      then
        (vars,knvars,extVars,(e_1 :: eqns),reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);

        /* array equations */ 
    case (DAE.DAE(elementLst = ((e as DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs)),states,whenclauses) 
      local MultiDimEquation e_1;
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
        e_1 = lowerArrEqn(e);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,(e_1 :: aeqns),algs,whenclauses_1,extObjCls);

        /* When equations */        
    case (DAE.DAE(elementLst = ((e as DAE.WHEN_EQUATION(condition = c,equations = eqns,elsewhen_ = NONE)) :: xs)),states,whenclauses)
      equation 
        (vars1,knvars,extVars,eqns1,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
        count = listLength(whenclauses_1);
        (eqns2,vars2,count_1,whenclauses_2) = lowerWhenEqn(e, count, whenclauses_1);
        vars = mergeVars(vars1, vars2);
        eqns = listAppend(eqns1, eqns2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_2,extObjCls);
        
        /* initial equations*/
    case (DAE.DAE(elementLst = ((e as DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)) :: xs)),states,whenclauses)
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
        e_1 = lowerEqn(e);
      then
        (vars,knvars,extVars,eqns,reqns,(e_1 :: ieqns),aeqns,algs,whenclauses_1,extObjCls);
        
        /* Algorithm */
    case (DAE.DAE(elementLst = (DAE.ALGORITHM(algorithm_ = a) :: xs)),states,whenclauses)
      equation 
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) 
        = lower2(DAE.DAE(xs), states, whenclauses);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,(a :: algs),whenclauses_1,extObjCls);
        
        /* flat class / COMP */
    case (DAE.DAE(elementLst = (DAE.COMP(dAElist = dae) :: xs)),states,whenclauses)
      equation 
        (vars1,knvars1,extVars1,eqns1,reqns1,ieqns1,aeqns1,algs1,whenclauses_1,extObjCls1) = lower2(dae, states, whenclauses);
        (vars2,knvars2,extVars2,eqns2,reqns2,ieqns2,aeqns2,algs2,whenclauses_2,extObjCls2) = lower2(DAE.DAE(xs), states, whenclauses_1);
        vars = mergeVars(vars1, vars2);
        extVars = mergeVars(extVars1,extVars2);
        eqns = listAppend(eqns1, eqns2);
        ieqns = listAppend(ieqns1, ieqns2);
        reqns = listAppend(reqns1, reqns2);
        aeqns = listAppend(aeqns1, aeqns2);
        knvars = mergeVars(knvars1, knvars2);
        algs = listAppend(algs1, algs2);
        extObjCls = listAppend(extObjCls1,extObjCls2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_2,extObjCls);
        
        /* If equation */
    case (DAE.DAE(elementLst = (DAE.IF_EQUATION(condition1 = _) :: xs)),states,whenclauses)
      equation 
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, 
          {"if-equations","rewrite equations using if-expressions"});
      then
        fail();
        /* Initial if equation */
    case (DAE.DAE(elementLst = (DAE.INITIAL_IF_EQUATION(condition1 = _) :: xs)),states,whenclauses)
      equation 
        Error.addMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, 
          {"if-equations","rewrite equations using if-expressions"});
      then
        fail();
        
        /* assert in equation section is converted to ALGORITHM */
    case (DAE.DAE(elementLst = (DAE.ASSERT(cond,msg) :: xs)),states,whenclauses)
      local
        Variables v;
        list<Equation> e;
        Exp.Exp cond,msg;
        
      equation 
        (v,kv,extVars,e,re,ie,ae,al,whenclauses_1,extObjCls) = lower2(DAE.DAE(xs), states, whenclauses) "Print.print_error_buf \"#Warning, Asserts are not supported/checked for.\\n\" &" ;
      then
        (v,kv,extVars,e,re,ie,ae,Algorithm.ALGORITHM({Algorithm.ASSERT(cond,msg)})::al,whenclauses_1,extObjCls);
  
       /* terminate in equation section is converted to ALGORITHM */
    case (DAE.DAE(elementLst = (DAE.ASSERT(cond,msg) :: xs)),states,whenclauses)
      local
        Variables v;
        list<Equation> e;
        Exp.Exp cond,msg;
        
      equation 
        (v,kv,extVars,e,re,ie,ae,al,whenclauses_1,extObjCls) = lower2(DAE.DAE(xs), states, whenclauses) ;
      then
        (v,kv,extVars,e,re,ie,ae,Algorithm.ALGORITHM({Algorithm.ASSERT(cond,msg)})::al,whenclauses_1,extObjCls);    
        
    case (DAE.DAE(elementLst = (_ :: xs)),states,whenclauses)
      local
        Variables v;
        list<Equation> e;
      equation 
        (v,kv,extVars,e,re,ie,ae,al,whenclauses_1,extObjCls) = lower2(DAE.DAE(xs), states, whenclauses);
      then
        (v,kv,extVars,e,re,ie,ae,al,whenclauses_1,extObjCls);
    case (_,_,_)
      equation 
        print("-lower2 failed\n");
      then
        fail();
  end matchcontinue;
end lower2;

protected function lowerTupleEquation "Lowers a tuple equation, e.g. (a,b) = foo(x,y)
by transforming it to an algorithm (TUPLE_ASSIGN), e.g. (a,b) := foo(x,y);

author: PA
"
	input DAE.Element eqn;
	output Algorithm.Algorithm alg;
algorithm
  alg := matchcontinue(eqn)
    local Exp.Exp e1,e2;
      list<Exp.Exp> expl;
      /* Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c) */
    case(DAE.EQUATION(Exp.TUPLE(expl),e2 as Exp.CALL(path =_))) 
    then Algorithm.ALGORITHM({Algorithm.TUPLE_ASSIGN(Exp.OTHER(),expl,e2)});
      
    case(DAE.EQUATION(e2 as Exp.CALL(path =_),Exp.TUPLE(expl))) 
    then Algorithm.ALGORITHM({Algorithm.TUPLE_ASSIGN(Exp.OTHER(),expl,e2)});
  end matchcontinue;  
end lowerTupleEquation;

protected function lowerMultidimeqns "function: lowerMultidimeqns
  author: PA
  
  Lowers MultiDimEquations by creating ARRAY_EQUATION nodes that points
  to the array equation, stored in a MultiDimEquation array.
  each MultiDimEquation has as many ARRAY_EQUATION nodes as it has array
  elements. This to ensure correct sorting using BLT.
  inputs:  (Variables, /* vars */
              MultiDimEquation list)
  outputs: Equation list
"
  input Variables vars;
  input list<MultiDimEquation> algs;
  output list<Equation> eqns;
algorithm 
  (eqns,_) := lowerMultidimeqns2(vars, algs, 0);
end lowerMultidimeqns;

protected function lowerMultidimeqns2 "function: lowerMultidimeqns2
 
  Helper function to lower_multidimeqns. To handle indexes in Equation nodes
  for multidimensional equations to indentify the corresponding 
  MultiDimEquation
  inputs:  (Variables, /* vars */
              MultiDimEquation list, 
              int /* index */) 
  outputs: (Equation list,
	    int) /* updated index */
"
  input Variables inVariables;
  input list<MultiDimEquation> inMultiDimEquationLst;
  input Integer inInteger;
  output list<Equation> outEquationLst;
  output Integer outInteger;
algorithm 
  (outEquationLst,outInteger):=
  matchcontinue (inVariables,inMultiDimEquationLst,inInteger)
    local
      Variables vars;
      Value aindx;
      list<Equation> eqns,eqns2,res;
      MultiDimEquation a;
      list<MultiDimEquation> algs;
    case (vars,{},aindx) then ({},aindx); 
    case (vars,(a :: algs),aindx)
      equation 
        eqns = lowerMultidimeqn(vars, a, aindx);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
  end matchcontinue;
end lowerMultidimeqns2;

protected function lowerMultidimeqn "function: lowerMultidimeqn
 
  Lowers a MultiDimEquation by creating an equation for each array
  index, such that BLT can be run correctly.
  inputs:  (Variables, /* vars */
              MultiDimEquation,
              int) /* indx */
  outputs:  Equation list 
"
  input Variables inVariables;
  input MultiDimEquation inMultiDimEquation;
  input Integer inInteger;
  output list<Equation> outEquationLst;
algorithm 
  outEquationLst:=
  matchcontinue (inVariables,inMultiDimEquation,inInteger)
    local
      list<Exp.Exp> expl1,expl2,expl;
      Value numnodes,aindx;
      list<Equation> lst;
      Variables vars;
      list<Value> ds;
      Exp.Exp e1,e2;
    case (vars,MULTIDIM_EQUATION(dimSize = ds,left = e1,right = e2),aindx)
      equation 
        expl1 = statesAndVarsExp(e1, vars);
        expl2 = statesAndVarsExp(e2, vars);
        expl = listAppend(expl1, expl2);
        numnodes = Util.listReduce(ds, int_mul);
        lst = lowerMultidimeqn2(expl, numnodes, aindx);
      then
        lst;
  end matchcontinue;
end lowerMultidimeqn;

protected function lowerMultidimeqn2 "function: lower_multidimeqns2
  
  Helper function to lower_multidimeqns
  Creates numnodes Equation nodes so BLT can be run correctly.
  inputs:  (Exp.Exp list, int /* numnodes */, int /* indx */)
  outputs: Equation list = 
"
  input list<Exp.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Equation> outEquationLst;
algorithm 
  outEquationLst:=
  matchcontinue (inExpExpLst1,inInteger2,inInteger3)
    local
      list<Exp.Exp> expl;
      Value numnodes_1,numnodes,indx;
      list<Equation> res;
    case (expl,0,_) then {}; 
    case (expl,numnodes,indx)
      equation 
        numnodes_1 = numnodes - 1;
        res = lowerMultidimeqn2(expl, numnodes_1, indx);
      then
        (ARRAY_EQUATION(indx,expl) :: res);
  end matchcontinue;
end lowerMultidimeqn2;

protected function lowerAlgorithms "function: lowerAlgorithms
 
  This function lowers algorithm sections by generating a list
  of ALGORITHMS nodes for the BLT sorting, which are put in 
  the equation list.
  An algorithm that calculates n variables will get n  ALGORITHM nodes
  such that the BLT sorting can be done correctly.
  inputs:  (Variables /* vars */, Algorithm.Algorithm list)
  outputs: Equation list 
"
  input Variables vars;
  input list<Algorithm.Algorithm> algs;
  output list<Equation> eqns;
algorithm 
  (eqns,_) := lowerAlgorithms2(vars, algs, 0);
end lowerAlgorithms;

protected function lowerAlgorithms2 "function: lowerAlgorithms2
 
  Helper function to lower_algorithms. To handle indexes in Equation nodes
  for algorithms to indentify the corresponding algorithm.
  inputs:  (Variables /* vars */, Algorithm.Algorithm list, int /* algindex*/ ) 
  outputs: (Equation list, int /* updated algindex */ ) =
"
  input Variables inVariables;
  input list<Algorithm.Algorithm> inAlgorithmAlgorithmLst;
  input Integer inInteger;
  output list<Equation> outEquationLst;
  output Integer outInteger;
algorithm 
  (outEquationLst,outInteger):=
  matchcontinue (inVariables,inAlgorithmAlgorithmLst,inInteger)
    local
      Variables vars;
      Value aindx;
      list<Equation> eqns,eqns2,res;
      Algorithm.Algorithm a;
      list<Algorithm.Algorithm> algs;
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

protected function lowerAlgorithm "function: lowerAlgorithm
 
  Lowers a single algorithm. Creates n ALGORITHM nodes for blt sorting.
  inputs:  (Variables, /* vars */
              Algorithm.Algorithm, 
              int /* algindx */)
  outputs: Equation list
"
  input Variables vars;
  input Algorithm.Algorithm a;
  input Integer aindx;
  output list<Equation> lst;
  list<Exp.Exp> inputs,outputs;
  Value numnodes;
algorithm 
  (inputs,outputs) := lowerAlgorithmInputsOutputs(vars, a);
  numnodes := listLength(outputs);
  lst := lowerAlgorithm2(inputs, outputs, numnodes, aindx);
end lowerAlgorithm;

protected function lowerAlgorithm2 "function: lowerAlgorithm2
 
  Helper function to lower_algorithm
  inputs:  (Exp.Exp list /* inputs   */,
              Exp.Exp list /* outputs  */,
              int          /* numnodes */, 
              int          /* aindx    */)
  outputs:  (Equation list) 
"
  input list<Exp.Exp> inExpExpLst1;
  input list<Exp.Exp> inExpExpLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  output list<Equation> outEquationLst;
algorithm 
  outEquationLst:=
  matchcontinue (inExpExpLst1,inExpExpLst2,inInteger3,inInteger4)
    local
      Value numnodes_1,numnodes,aindx;
      list<Equation> res;
      list<Exp.Exp> inputs,outputs;
    case (_,_,0,_) then {}; 
    case (inputs,outputs,numnodes,aindx)
      equation 
        numnodes_1 = numnodes - 1;
        res = lowerAlgorithm2(inputs, outputs, numnodes_1, aindx);
      then
        (ALGORITHM(aindx,inputs,outputs) :: res);
  end matchcontinue;
end lowerAlgorithm2;

protected function lowerAlgorithmInputsOutputs "function: lowerAlgorithmInputsOutputs
 
  This function finds the inputs and the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any 
  statement in the algorithm and an output is a variables belonging to the 
  variables that are assigned a value in the algorithm.
"
  input Variables inVariables;
  input Algorithm.Algorithm inAlgorithm;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inVariables,inAlgorithm)
    local
      list<Exp.Exp> inputs1,outputs1,inputs2,outputs2,inputs,outputs;
      Variables vars;
      Algorithm.Statement s;
      list<Algorithm.Statement> ss;
    case (_,Algorithm.ALGORITHM(statementLst = {})) then ({},{}); 
    case (vars,Algorithm.ALGORITHM(statementLst = (s :: ss)))
      equation 
        (inputs1,outputs1) = lowerStatementInputsOutputs(vars, s);
        (inputs2,outputs2) = lowerAlgorithmInputsOutputs(vars, Algorithm.ALGORITHM(ss));
        inputs = Util.listUnionOnTrue(inputs1, inputs2, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then
        (inputs,outputs);
  end matchcontinue;
end lowerAlgorithmInputsOutputs;

protected function lowerStatementInputsOutputs "function: lowerStatementInputsOutputs
 
  Helper relatoin to lower_algorithm_inputs_outputs
  Investigates single statements. Returns Exp.Exp list
  instead of Exp.ComponentRef list because derivatives must
  be handled as well.
  inputs:  (Variables, /* vars */
              Algorithm.Statement)
  outputs: (Exp.Exp list, /* inputs, CREF or der(CREF)  */
              Exp.Exp list  /* outputs, CREF or der(CREF) */) 
"
  input Variables inVariables;
  input Algorithm.Statement inStatement;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inVariables,inStatement)
    local
      list<Exp.Exp> inputs;
      list<Exp.Exp> inputs1;
      list<Exp.Exp> inputs2;
      list<Exp.Exp> outputs;
      list<Exp.Exp> outputs1;
      list<Exp.Exp> outputs2;
      Variables vars;
      Exp.Type tp;
      Exp.ComponentRef cr;
      Exp.Exp e;
      list<Algorithm.Statement> statements;
      Algorithm.Statement stmt;
      list<Exp.Exp> expl;
      list<Algorithm.Statement> stmts;
      Algorithm.Else elsebranch;
      list<Exp.Exp> inputs,inputs1,inputs2,inputs3,outputs,outputs1,outputs2;
      list<Exp.ComponentRef> crefs;
			// a := expr;
    case (vars,Algorithm.ASSIGN(type_ = tp,componentRef = cr,exp = e))
      equation 
        inputs = statesAndVarsExp(e, vars);
      then
        (inputs,{Exp.CREF(cr,tp)});
    case (vars,Algorithm.WHEN(exp = e,statementLst = statements,elseWhen = NONE))
      equation 
        (inputs,outputs) = lowerAlgorithmInputsOutputs(vars,Algorithm.ALGORITHM(statements));
        inputs2 = list_append(statesAndVarsExp(e, vars),inputs);
      then
        (inputs2,outputs);
    case (vars,Algorithm.WHEN(exp = e,statementLst = statements,elseWhen = SOME(stmt)))
      equation 
				(inputs1, outputs1) = lowerStatementInputsOutputs(vars,stmt);
        (inputs,outputs) = lowerAlgorithmInputsOutputs(vars,Algorithm.ALGORITHM(statements));
        inputs2 = list_append(statesAndVarsExp(e, vars),inputs);
        outputs2 = list_append(outputs, outputs1);
      then
        (inputs2,outputs2);
			// (a,b,c) := foo(...)
    case (vars,Algorithm.TUPLE_ASSIGN(tp,expl,e))
      equation 
        inputs = statesAndVarsExp(e,vars);
        crefs = Util.listFlatten(Util.listMap(expl,Exp.getCrefFromExp));
        outputs =  Util.listMap1(crefs,Exp.makeCrefExp,Exp.OTHER());
      then
        (inputs,outputs);
        // v := expr   where v is array.
    case (vars,Algorithm.ASSIGN_ARR(tp,cr,e)) 
      equation
        inputs = statesAndVarsExp(e,vars);
      then (inputs,{Exp.CREF(cr,tp)});
        
    case(vars,Algorithm.IF(e,stmts,elsebranch))
      equation
        (inputs1,outputs1) = lowerAlgorithmInputsOutputs(vars,Algorithm.ALGORITHM(stmts));
        (inputs2,outputs2) = lowerElseAlgorithmInputsOutputs(vars,elsebranch);
        inputs3 = statesAndVarsExp(e,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2,inputs3}, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);    
      then (inputs,outputs);          

    case(vars,Algorithm.ASSERT(cond = e1,msg=e2))
      local Exp.Exp e1,e2;
      equation
        inputs1 = statesAndVarsExp(e1,vars);
        inputs2 = statesAndVarsExp(e1,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2}, Exp.expEqual);
     then (inputs,{});  

			// Features not yet supported.
    case(vars,Algorithm.FOR(type_=_))
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"For statements in algorithms not supported yet. Suggested workaround: place for statement in a Modelica function"});
     then fail();
    case(vars,Algorithm.WHILE(exp=_))
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"While statements in algorithms not supported yet. Suggested workaround: place while statement in a Modelica function"});
     then fail();  
  end matchcontinue;
end lowerStatementInputsOutputs;

protected function lowerElseAlgorithmInputsOutputs "Helper function to lowerStatementInputsOutputs"
  input Variables vars;
  input Algorithm.Else elseBranch;
  output list<Exp.Exp> inputs;
  output list<Exp.Exp> outputs;
algorithm 
  (inputs,outputs):=
  matchcontinue (vars,elseBranch)	
      local 
        list<Algorithm.Statement> stmts;
        list<Exp.Exp> inputs1,inputs2,inputs3,outputs1,outputs2;
        Exp.Exp e;
    case(vars,Algorithm.NOELSE()) then ({},{});
    
    case(vars,Algorithm.ELSEIF(e,stmts,elseBranch))
       equation  
      (inputs1, outputs1) = lowerElseAlgorithmInputsOutputs(vars,elseBranch);
      (inputs2, outputs2) = lowerAlgorithmInputsOutputs(vars,Algorithm.ALGORITHM(stmts));
      inputs3 = statesAndVarsExp(e,vars);
      inputs = Util.listListUnionOnTrue({inputs1, inputs2, inputs3}, Exp.expEqual);
      outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
    then (inputs,outputs);
    
      case(vars,Algorithm.ELSE(stmts)) 
        equation
          (inputs, outputs) = lowerAlgorithmInputsOutputs(vars,Algorithm.ALGORITHM(stmts));
        then (inputs,outputs);
  end matchcontinue;
end lowerElseAlgorithmInputsOutputs;
      
protected function statesAndVarsExp "function: statesAndVarsExp
 
  This function investigates an expression and returns as subexpressions
  that are variable names or derivatives of state names or states
  inputs:  (Exp.Exp, Variables /* vars */)
  outputs: Exp.Exp list
"
  input Exp.Exp inExp;
  input Variables inVariables;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExp,inVariables)
    local
      Exp.Exp e,e1,e2,e3;
      Exp.ComponentRef cr;
      Exp.Type tp;
      Variables vars;
      list<Exp.Exp> s1,s2,res,s3,expl;
      DAE.Flow flow_;
      list<Value> p;
      list<list<Exp.Exp>> lst;
      list<list<tuple<Exp.Exp, Boolean>>> mexp;
    case ((e as Exp.CREF(componentRef = cr,ty = tp)),vars)
      equation 
        (_,_) = getVar(cr, vars);
      then
        {e};
    case (Exp.BINARY(exp1 = e1,exp2 = e2),vars)
      equation 
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    case (Exp.UNARY(exp = e),vars)
      equation 
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (Exp.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation 
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    case (Exp.LUNARY(exp = e),vars)
      equation 
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (Exp.RELATION(exp1 = e1,exp2 = e2),vars)
      equation 
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars)
      equation 
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        s3 = statesAndVarsExp(e3, vars);
        res = Util.listListUnionOnTrue({s1,s2,s3}, Exp.expEqual);
      then
        res;
    case ((e as Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)})),vars)
      equation 
        ((VAR(_,STATE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),_) = getVar(cr, vars);
      then
        {e};
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),vars)
      equation 
        (_,p) = getVar(cr, vars);
      then
        {};
    case (Exp.CALL(expLst = expl),vars)
      equation 
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (Exp.ARRAY(array = expl),vars)
      equation 
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (Exp.MATRIX(scalar = mexp),vars)
      equation 
        res = statesAndVarsMatrixExp(mexp, vars);
      then
        res;
    case (Exp.TUPLE(PR = expl),vars)
      equation 
        lst = Util.listMap1(expl, statesAndVarsExp, vars);
        res = Util.listListUnionOnTrue(lst, Exp.expEqual);
      then
        res;
    case (Exp.CAST(exp = e),vars)
      equation 
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (Exp.ASUB(exp = e),vars)
      equation 
        res = statesAndVarsExp(e, vars);
      then
        res;
    case (Exp.REDUCTION(expr = e1,range = e2),vars)
      equation 
        s1 = statesAndVarsExp(e1, vars);
        s2 = statesAndVarsExp(e2, vars);
        res = Util.listUnionOnTrue(s1, s2, Exp.expEqual);
      then
        res;
    case (_,_) then {}; 
  end matchcontinue;
end statesAndVarsExp;

protected function statesAndVarsMatrixExp "function: statesAndVarsMatrixExp
 
"
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input Variables inVariables;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<Exp.Exp> expl_1,ms_1,res;
      list<list<Exp.Exp>> lst;
      list<tuple<Exp.Exp, Boolean>> expl;
      list<list<tuple<Exp.Exp, Boolean>>> ms;
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

protected function lowerEqn "function: lowerEqn
 
  Helper function to lower2.
  Transforma a DAE.Element to Equation.
"
  input DAE.Element inElement;
  output Equation outEquation;
algorithm 
  outEquation:=
  matchcontinue (inElement)
    local Exp.Exp e1_1,e2_1,e1_2,e2_2,e1,e2;
    case (DAE.EQUATION(exp = e1,scalar = e2))
      equation 
        e1_1 = Exp.simplify(e1);
        e2_1 = Exp.simplify(e2);
        e1_2 = Exp.stringifyCrefs(e1_1);
        e2_2 = Exp.stringifyCrefs(e2_1);
      then
        EQUATION(e1_2,e2_2);
    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2))
      equation 
        e1_1 = Exp.simplify(e1);
        e2_1 = Exp.simplify(e2);
        e1_2 = Exp.stringifyCrefs(e1_1);
        e2_2 = Exp.stringifyCrefs(e2_1);
      then
        EQUATION(e1_2,e2_2);
  end matchcontinue;
end lowerEqn;

protected function lowerArrEqn "function: lowerArrEqn
 
  Helper function to lower2.
  Transforma a DAE.Element to MultiDimEquation.
"
  input DAE.Element inElement;
  output MultiDimEquation outMultiDimEquation;
algorithm 
  outMultiDimEquation:=
  matchcontinue (inElement)
    local
      Exp.Exp e1_1,e2_1,e1_2,e2_2,e1,e2;
      list<Value> ds;
    case (DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2))
      equation 
        e1_1 = Exp.simplify(e1);
        e2_1 = Exp.simplify(e2);
        e1_2 = Exp.stringifyCrefs(e1_1);
        e2_2 = Exp.stringifyCrefs(e2_1);
      then
        MULTIDIM_EQUATION(ds,e1_2,e2_2);
  end matchcontinue;
end lowerArrEqn;

protected function lowerVar "function: lowerVar
 
  Transforms a DAE variable to DAELOW variable.
  Includes changing the ComponentRef name to a simpler form 
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\",{2}) )
  inputs: (DAE.Element, BinTree /* states */) 
  outputs: Var
"
  input DAE.Element inElement;
  input BinTree inBinTree;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inElement,inBinTree)
    local
      list<Exp.Subscript> subs,dims;
      Exp.ComponentRef name_1,newname,name;
      String origname;
      VarKind kind_1;
      Option<Exp.Exp> bind_1,start_1,bind,start;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      BinTree states;
    case (DAE.VAR(componentRef = name,varible = kind,variable = dir,input_ = tp,one = bind,
      binding = dims,dimension = start,value = flow_,flow_ = class_,
      variableAttributesOption = dae_var_attr,absynCommentOption = comment),states)  
      equation 
        subs = Exp.crefLastSubs(name);
        name_1 = Exp.crefStripLastSubs(name);
        origname = Exp.printComponentRefStr(name_1);
        newname = Exp.CREF_IDENT(origname,subs);
        kind_1 = lowerVarkind(kind, tp, newname, dir, flow_, states,dae_var_attr);
        bind_1 = lowerBinding(bind);
        start_1 = lowerBinding(start);
      then
        VAR(newname,kind_1,dir,tp,bind_1,NONE,dims,start_1,-1,name,
          class_,dae_var_attr,comment,flow_);
  end matchcontinue;
end lowerVar;

protected function lowerBinding "function: lowerBinding
 
  Helper function to lower_var
"
  input Option<Exp.Exp> inExpExpOption;
  output Option<Exp.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inExpExpOption)
    local Exp.Exp e_1,e;
    case NONE then NONE; 
    case (SOME(e))
      equation 
        e_1 = Exp.stringifyCrefs(e);
      then
        SOME(e);
  end matchcontinue;
end lowerBinding;

protected function lowerKnownVar "function: lowerKnownVar
 
  Helper function to lower2
"
  input DAE.Element inElement;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inElement)
    local
      list<Exp.Subscript> subs,dims;
      Exp.ComponentRef name_1,newname,name;
      String origname;
      VarKind kind_1;
      Option<Exp.Exp> bind_1,start_1,bind,start;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case (DAE.VAR(componentRef = name,varible = kind,variable = dir,input_ = tp,one = bind,binding = dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment))
      equation 
        subs = Exp.crefLastSubs(name);
        name_1 = Exp.crefStripLastSubs(name);
        origname = Exp.printComponentRefStr(name_1);
        newname = Exp.CREF_IDENT(origname,subs);
        kind_1 = lowerKnownVarkind(kind, name, dir, flow_);
        bind_1 = lowerBinding(bind);
        start_1 = lowerBinding(start);
      then
        VAR(newname,kind_1,dir,tp,bind_1,NONE,dims,start_1,-1,name,
          class_,dae_var_attr,comment,flow_);
    case (_)
      equation 
        print("-lower_known_var failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVar;

protected function lowerExtObjVar " Helper function to lower2

Fails for all variables except external object instances.

"
  input DAE.Element inElement;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inElement)
    local
      list<Exp.Subscript> subs,dims;
      Exp.ComponentRef name_1,newname,name;
      String origname;
      VarKind kind_1;
      Option<Exp.Exp> bind_1,start_1,bind,start;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case (DAE.VAR(componentRef = name,varible = kind,variable = dir,input_ = tp,one = bind,binding = dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment))
      equation 
        subs = Exp.crefLastSubs(name);
        name_1 = Exp.crefStripLastSubs(name);
        origname = Exp.printComponentRefStr(name_1);
        newname = Exp.CREF_IDENT(origname,subs);
        kind_1 = lowerExtObjVarkind(tp);
        bind_1 = lowerBinding(bind);
        start_1 = lowerBinding(start);
      then
        VAR(newname,kind_1,dir,tp,bind_1,NONE,dims,start_1,-1,name,
          class_,dae_var_attr,comment,flow_);
  end matchcontinue;
end lowerExtObjVar;

protected function lowerVarkind "function: lowerVarkind
 
  Helper function to lower_var.
  inputs: (DAE.VarKind, 
             DAE.Type, 
             Exp.ComponentRef, 
             DAE.VarDirection, /* input/output/bidir */
             DAE.Flow,
             BinTree /* states */) 
  outputs VarKind 
  NOTE: Fails for not states that are not algebraic variables, e.g.
          parameters and constants
"
  input DAE.VarKind inVarKind;
  input DAE.Type inType;
  input Exp.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  input BinTree inBinTree;
  input option<DAE.VariableAttributes> daeAttr;
  output VarKind outVarKind;
algorithm 
  outVarKind:=
  matchcontinue (inVarKind,inType,inComponentRef,inVarDirection,inFlow,inBinTree,daeAttr)
    local
      Exp.ComponentRef v,cr;
      BinTree states;
      DAE.VarDirection dir;
      DAE.Flow flow_;
      // States appear differentiated among equations
    case (DAE.VARIABLE(),_,v,_,_,states,daeAttr)
      equation 
        _ = treeGet(states, v);
      then
        STATE();
       // Or states have StateSelect.always 
    case (DAE.VARIABLE(),_,v,_,_,states,SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(DAE.ALWAYS()))))
    then STATE();
        
    case (DAE.VARIABLE(),DAE.BOOL(),cr,dir,flow_,_,_)
      equation 
        failure(topLevelInput(cr, dir, flow_));
      then
        DISCRETE();
    case (DAE.DISCRETE(),DAE.BOOL(),cr,dir,flow_,_,_)
      equation 
        failure(topLevelInput(cr, dir, flow_));
      then
        DISCRETE();
    case (DAE.VARIABLE(),DAE.INT(),cr,dir,flow_,_,_)
      equation 
        failure(topLevelInput(cr, dir, flow_));
      then
        DISCRETE();
    case (DAE.DISCRETE(),DAE.INT(),cr,dir,flow_,_,_)
      equation 
        failure(topLevelInput(cr, dir, flow_));
      then
        DISCRETE();
    case (DAE.VARIABLE(),_,cr,dir,flow_,_,_)
      equation 
        failure(topLevelInput(cr, dir, flow_));
      then
        VARIABLE();
    case (DAE.DISCRETE(),_,cr,dir,flow_,_,_)
      equation 
        failure(topLevelInput(cr, dir, flow_));
      then
        DISCRETE();
  end matchcontinue;
end lowerVarkind;

protected function topLevelInput "function: topLevelInput 
  author: PA
 
  Succeds if variable is input declared at the top level of the model, 
  or if it is an input in a connector instance at top level.
"
  input Exp.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm 
  _:=
  matchcontinue (inComponentRef,inVarDirection,inFlow)
    local
      Exp.ComponentRef cr;
      String name;
    case ((cr as Exp.CREF_IDENT(ident = name)),DAE.INPUT(),_)
      equation 
        {_} = Util.stringSplitAtChar(name, ".") "top level ident, no dots" ;
      then
        ();
    case (Exp.CREF_IDENT(ident = name),DAE.INPUT(),DAE.NON_FLOW()) /* Connector input variables at top level for crefs that are stringified */ 
      equation 
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    case (Exp.CREF_IDENT(ident = name),DAE.INPUT(),DAE.FLOW())
      equation 
        {_,_} = Util.stringSplitAtChar(name, ".");
      then
        ();
    case (Exp.CREF_QUAL(ident = name,componentRef = Exp.CREF_IDENT(ident = _)),DAE.INPUT(),DAE.FLOW()) then ();  /* For crefs that are not yet stringified, e.g. lower_known_var */ 
    case ((cr as Exp.CREF_QUAL(ident = name,componentRef = Exp.CREF_IDENT(ident = _))),DAE.INPUT(),DAE.NON_FLOW()) then (); 
  end matchcontinue;
end topLevelInput;

protected function topLevelOutput "function: topLevelOutput 
  author: PA
 
  Succeds if variable is output declared at the top level of the model, 
  or if it is an output in a connector instance at top level.
"
  input Exp.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
algorithm 
  _:=
  matchcontinue (inComponentRef,inVarDirection,inFlow)
    local
      list<String> cr_str_lst;
      Exp.ComponentRef cr;
      String name;
      Value len;
    case ((cr as Exp.CREF_IDENT(ident = name)),DAE.OUTPUT(),_)
      equation 
        cr_str_lst = Util.stringSplitAtChar(name, ".") "top level ident, no dots" ;
        1 = listLength(cr_str_lst);
      then
        ();
    case (Exp.CREF_IDENT(ident = name),DAE.OUTPUT(),DAE.NON_FLOW()) /* Connector output variables at top level for crefs that are stringified */ 
      equation 
        cr_str_lst = Util.stringSplitAtChar(name, ".");
        len = listLength(cr_str_lst);
        (len == 2) = true;
      then
        ();
    case (Exp.CREF_IDENT(ident = name),DAE.OUTPUT(),DAE.FLOW())
      equation 
        cr_str_lst = Util.stringSplitAtChar(name, ".");
        len = listLength(cr_str_lst);
        (len == 2) = true;
      then
        ();
    case (Exp.CREF_QUAL(ident = name,componentRef = Exp.CREF_IDENT(ident = _)),DAE.OUTPUT(),DAE.FLOW()) then ();  /* For crefs that are not yet stringified, e.g. lower_known_var */ 
    case (Exp.CREF_QUAL(ident = name,componentRef = Exp.CREF_IDENT(ident = _)),DAE.OUTPUT(),DAE.NON_FLOW()) then (); 
  end matchcontinue;
end topLevelOutput;

protected function lowerKnownVarkind "function: lowerKnownVarkind
 
  Helper function to lower_known_var.
  NOTE: Fails for everything but parameters and constants and top level inputs
"
  input DAE.VarKind inVarKind;
  input Exp.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  output VarKind outVarKind;
algorithm 
  outVarKind:=
  matchcontinue (inVarKind,inComponentRef,inVarDirection,inFlow)
    local
      Exp.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flow_;
    case (DAE.PARAM(),_,_,_) then PARAM(); 
    case (DAE.CONST(),_,_,_) then CONST(); 
    case (DAE.VARIABLE(),cr,dir,flow_)
      equation 
        topLevelInput(cr, dir, flow_);
      then
        VARIABLE();
    case (_,_,_,_)
      equation 
        print("lower_known_varkind failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVarkind;

protected function lowerExtObjVarkind "  Helper function to lowerExtObjVar.
  NOTE: Fails for everything but External objects
"
  input DAE.Type inType;
  output VarKind outVarKind;
algorithm 
  outVarKind:=
  matchcontinue (inType)
    local Absyn.Path path;
    case (DAE.EXT_OBJECT(path)) then EXTOBJ(path); 
  end matchcontinue;
end lowerExtObjVarkind;

public function incidenceMatrix "function: incidenceMatrix
  author: PA
 
  Calculates the incidence matrix, i.e. which variables are present
  in each equation.
"
  input DAELow inDAELow;
  output IncidenceMatrix outIncidenceMatrix;
algorithm 
  outIncidenceMatrix:=
  matchcontinue (inDAELow)
    local
      list<Equation> eqnsl;
      list<list<Value>> lstlst;
      list<Value>[:] arr;
      Variables vars;
      EquationArray eqns;
    case (DAELOW(orderedVars = vars,orderedEqs = eqns))
      equation 
        eqnsl = equationList(eqns);
        lstlst = incidenceMatrix2(vars, eqnsl);
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

protected function incidenceMatrix2 "function: incidenceMatrix2
  author: PA
 
  Helper function to incidence_matrix
  Calculates the incidence matrix as a list of list of integers
"
  input Variables inVariables;
  input list<Equation> inEquationLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm 
  outIntegerLstLst:=
  matchcontinue (inVariables,inEquationLst)
    local
      list<list<Value>> lst;
      list<Value> row;
      Variables vars;
      Equation e;
      list<Equation> eqns;
    case (_,{}) then {}; 
    case (vars,(e :: eqns))
      equation 
        lst = incidenceMatrix2(vars, eqns);
        row = incidenceRow(vars, e);
      then
        (row :: lst);
    case (_,_)
      equation 
        print("incidence_matrix2 failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrix2;

protected function incidenceRow "function: incidenceRow
  author: PA
 
  Helper function to incidence_matrix. Calculates the indidence row
  in the matrix for one equation.
"
  input Variables inVariables;
  input Equation inEquation;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (inVariables,inEquation)
    local
      list<Value> lst1,lst2,res,res_1;
      Variables vars;
      Exp.Exp e1,e2,e;
      list<list<Value>> lst3;
      list<Exp.Exp> expl,inputs,outputs;
      Exp.ComponentRef cr;
      WhenEquation we;
      Value indx;
    case (vars,EQUATION(exp = e1,scalar = e2))
      equation 
        lst1 = incidenceRowExp(e1, vars) "EQUATION" ;
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,ARRAY_EQUATION(crefOrDerCref = expl)) /* ARRAY_EQUATION */ 
      equation 
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst3);
      then
        res;
    case (vars,SOLVED_EQUATION(componentRef = cr,exp = e)) /* SOLVED_EQUATION */ 
      equation 
        lst1 = incidenceRowExp(Exp.CREF(cr,Exp.REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,SOLVED_EQUATION(componentRef = cr,exp = e)) /* SOLVED_EQUATION */ 
      equation 
        lst1 = incidenceRowExp(Exp.CREF(cr,Exp.REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,RESIDUAL_EQUATION(exp = e)) /* RESIDUAL_EQUATION */ 
      equation 
        res = incidenceRowExp(e, vars);
      then
        res;
    case (vars,WHEN_EQUATION(whenEquation = we)) /* WHEN_EQUATION */ 
      equation 
        (cr,e2) = getWhenEquationExpr(we);
        e1 = Exp.CREF(cr,Exp.OTHER());
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,ALGORITHM(index = indx,in_ = inputs,out = outputs)) /* ALGORITHM For now assume that algorithm will be solvable for correct
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
    case (vars,_)
      equation 
        print("-incidence_row failed\n");
      then
        fail();
  end matchcontinue;
end incidenceRow;

protected function incidenceRowStmts "function: incidenceRowStmts
  author: PA
 
  Helper function to incidence_row, investigates statements for
  variables, returning variable indexes.
"
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (inAlgorithmStatementLst,inVariables)
    local
      list<Value> lst1,lst2,lst3,res,lst3_1;
      Exp.Type tp;
      Exp.ComponentRef cr;
      Exp.Exp e;
      list<Algorithm.Statement> rest,stmts;
      Variables vars;
      list<Exp.Exp> expl;
      Algorithm.Else else_;
    case ({},_) then {}; 
    case ((Algorithm.ASSIGN(type_ = tp,componentRef = cr,exp = e) :: rest),vars)
      equation 
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = incidenceRowExp(Exp.CREF(cr,Exp.OTHER()), vars);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case ((Algorithm.TUPLE_ASSIGN(type_ = tp,expExpLst = expl,exp = e) :: rest),vars)
      local list<list<Value>> lst3;
      equation 
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        lst3_1 = Util.listFlatten(lst3);
        res = Util.listFlatten({lst1,lst2,lst3_1});
      then
        res;
    case ((Algorithm.ASSIGN_ARR(type_ = tp,componentRef = cr,exp = e) :: rest),vars)
      equation 
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = incidenceRowExp(Exp.CREF(cr,Exp.OTHER()), vars);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case ((Algorithm.IF(exp = e,statementLst = stmts,else_ = else_) :: rest),vars)
      equation 
        print("incidence_row_stmts on IF not implemented\n");
      then
        {};
    case ((Algorithm.FOR(type_ = _) :: rest),vars)
      equation 
        print("incidence_row_stmts on FOR not implemented\n");
      then
        {};
    case ((Algorithm.WHILE(exp = _) :: rest),vars)
      equation 
        print("incidence_row_stmts on WHILE not implemented\n");
      then
        {};
    case ((Algorithm.WHEN(exp = e) :: rest),vars)
      equation 
        print("incidence_row_stmts on WHEN not implemented\n");
      then
        {};
    case ((Algorithm.ASSERT(cond = _) :: rest),vars)
      equation 
        print("incidence_row_stmts on ASSERT not implemented\n");
      then
        {};
  end matchcontinue;
end incidenceRowStmts;

protected function incidenceRowExp "function: incidenceRowExp
  author: PA
 
  Helper function to incidence_row, investigates expressions for
  variables, returning variable indexes.
"
  input Exp.Exp inExp;
  input Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (inExp,inVariables)
    local
      DAE.Flow flow_;
      list<Value> p,p_1,s1,s2,res,s3,lst_1;
      Exp.ComponentRef cr;
      Variables vars;
      Exp.Exp e1,e2,e,e3;
      list<list<Value>> lst;
      list<Exp.Exp> expl;
    case (Exp.CREF(componentRef = cr),vars)
      equation 
        ((VAR(_,STATE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),p) = getVar(cr, vars) "If variable x is a state, der(x) is a variable in incidence matrix,
	 x is inserted as negative value, since it is needed by debugging and index
	 reduction using dummy derivatives" ;
        p_1 = Util.listMap1r(p, int_sub, 0);
      then
        p_1;
    case (Exp.CREF(componentRef = cr),vars)
      equation 
        ((VAR(_,VARIABLE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),p) = getVar(cr, vars);
      then
        p;
    case (Exp.CREF(componentRef = cr),vars)
      equation 
        ((VAR(_,DISCRETE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),p) = getVar(cr, vars);
      then
        p;
    case (Exp.CREF(componentRef = cr),vars)
      equation 
        ((VAR(_,DUMMY_DER(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),p) = getVar(cr, vars);
      then
        p;
    case (Exp.CREF(componentRef = cr),vars)
      equation 
        ((VAR(_,DUMMY_STATE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),p) = getVar(cr, vars);
      then
        p;
    case (Exp.BINARY(exp1 = e1,exp2 = e2),vars)
      equation 
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (Exp.UNARY(exp = e),vars)
      equation 
        res = incidenceRowExp(e, vars);
      then
        res;
    case (Exp.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation 
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (Exp.LUNARY(exp = e),vars)
      equation 
        res = incidenceRowExp(e, vars);
      then
        res;
    case (Exp.RELATION(exp1 = e1,exp2 = e2),vars)
      equation 
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars) /* if expressions. */ 
      equation 
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        s3 = incidenceRowExp(e3, vars);
        res = Util.listFlatten({s1,s2,s3});
      then
        res;
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),vars)
      equation 
        ((VAR(_,STATE(),_,_,_,_,_,_,_,_,_,_,_,flow_) :: _),p) = getVar(cr, vars);
      then
        p;
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),vars)
      equation 
        (_,p) = getVar(cr, vars);
      then
        {};
    case (Exp.CALL(path = Absyn.IDENT(name = "pre"),expLst = {Exp.CREF(componentRef = cr)}),vars) then {};  /* pre(v) is considered a known variable */ 
    case (Exp.CALL(expLst = expl),vars)
      equation 
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst);
      then
        res;
    case (Exp.ARRAY(array = expl),vars)
      equation 
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        lst_1 = Util.listFlatten(lst);
      then
        lst_1;
    case (Exp.MATRIX(scalar = expl),vars)
      local list<list<tuple<Exp.Exp, Boolean>>> expl;
      equation 
        res = incidenceRowMatrixExp(expl, vars);
      then
        res;
    case (Exp.TUPLE(PR = expl),vars)
      equation 
        print("incidence_row_exp TUPLE not impl. yet.");
      then
        {};
    case (Exp.CAST(exp = e),vars)
      equation 
        res = incidenceRowExp(e, vars);
      then
        res;
    case (Exp.ASUB(exp = e),vars)
      equation 
        res = incidenceRowExp(e, vars);
      then
        res;
    case (Exp.REDUCTION(expr = e1,range = e2),vars)
      equation 
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        res = listAppend(s1, s2);
      then
        res;
    case (_,_) then {}; 
  end matchcontinue;
end incidenceRowExp;

protected function incidenceRowMatrixExp "function: incidenceRowMatrixExp
  author: PA
 
  Traverses matrix expressions for building incidence matrix.
"
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<Exp.Exp> expl_1;
      list<list<Value>> res1;
      list<Value> res2,res1_1,res;
      list<tuple<Exp.Exp, Boolean>> expl;
      list<list<tuple<Exp.Exp, Boolean>>> es;
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

public function emptyVars "function: emptyVars
  author: PA
 
  Returns a Variable datastructure that is empty.
  Using the bucketsize 10000 and array size 1000.
"
  output Variables outVariables;
  list<CrefIndex>[:] arr;
  list<StringIndex>[:] arr2;
  list<Option<Var>> lst;
  Option<Var>[:] emptyarr;
algorithm 
  arr := fill({}, 10000);
  arr2 := fill({}, 10000);
  lst := Util.listFill(NONE, 1000);
  emptyarr := listArray(lst);
  outVariables := VARIABLES(arr,arr2,VARIABLE_ARRAY(0,1000,emptyarr),10000,0);
end emptyVars;

protected function mergeVars "function: mergeVars
  author: PA
 
  Takes two sets of Variables and merges them. The variables of the 
  first argument takes precedence over the second set, i.e. if a 
  variable name exists in both sets, the variable definition from 
  the first set is used.
"
  input Variables inVariables1;
  input Variables inVariables2;
  output Variables outVariables;
algorithm 
  outVariables:=
  matchcontinue (inVariables1,inVariables2)
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

public function addVar "function: addVar
  author: PA
 
  Add a variable to Variables.
  If the variable allready exists, the function updates the variable.
"
  input Var inVar;
  input Variables inVariables;
  output Variables outVariables;
algorithm 
  outVariables:=
  matchcontinue (inVar,inVariables)
    local
      Value hval,indx,newpos,n_1,hvalold,indxold,bsize,n,indx_1;
      VariableArray varr_1,varr;
      list<CrefIndex> indexes;
      list<CrefIndex>[:] hashvec_1,hashvec;
      String name_str;
      list<StringIndex> indexexold;
      list<StringIndex>[:] oldhashvec_1,oldhashvec;
      Var v,newv;
      Exp.ComponentRef cr,name;
      DAE.Flow flow_;
      Variables vars;
    case ((v as VAR(varName = cr,origVarName = name,flow_ = flow_)),(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation 
        failure((_,_) = getVar(cr, vars)) "adding when not existing previously" ;
        hval = hashComponentRef(cr);
        indx = intMod(hval, bsize);
        newpos = vararrayLength(varr);
        varr_1 = vararrayAdd(varr, v);
        indexes = hashvec[indx + 1];
        hashvec_1 = arrayUpdate(hashvec, indx + 1, (CREFINDEX(cr,newpos) :: indexes));
        n_1 = vararrayLength(varr_1);
        name_str = Exp.printComponentRefStr(name);
        hvalold = hashString(name_str);
        indxold = intMod(hvalold, bsize);
        indexexold = oldhashvec[indxold + 1];
        name_str = Exp.printComponentRefStr(name);
        oldhashvec_1 = arrayUpdate(oldhashvec, indxold + 1, 
          (STRINGINDEX(name_str,newpos) :: indexexold));
      then
        VARIABLES(hashvec_1,oldhashvec_1,varr_1,bsize,n_1);
    case ((newv as VAR(varName = cr,origVarName = name,flow_ = flow_)),(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation 
        (_,{indx}) = getVar(cr, vars) "adding when allready present => Updating value" ;
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

public function vararrayLength "function: vararrayLength
  author: PA
 
  Returns the number of variable in the VariableArray
"
  input VariableArray inVariableArray;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inVariableArray)
    local Value n;
    case (VARIABLE_ARRAY(numberOfElements = n)) then n; 
  end matchcontinue;
end vararrayLength;

public function vararrayAdd "function: vararrayAdd
  author: PA
 
  Adds a variable last to the VariableArray, increasing array size
  if no space left by factor 1.4
"
  input VariableArray inVariableArray;
  input Var inVar;
  output VariableArray outVariableArray;
algorithm 
  outVariableArray:=
  matchcontinue (inVariableArray,inVar)
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
        rexpandsize = rsize*.0.4;
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

public function vararraySetnth "function: vararraySetnth
  author: PA
 
  Set the n:th variable in the VariableArray to v.
 inputs:  (VariableArray, int /* n */, Var /* v */)
 outputs: VariableArray =
"
  input VariableArray inVariableArray;
  input Integer inInteger;
  input Var inVar;
  output VariableArray outVariableArray;
algorithm 
  outVariableArray:=
  matchcontinue (inVariableArray,inInteger,inVar)
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

public function vararrayNth "function: vararrayNth
  author: PA
 
  Retrieve the n:th Var from VariableArray, index from 0..n-1.
 inputs:  (VariableArray, int /* n */) 
 outputs: Var
"
  input VariableArray inVariableArray;
  input Integer inInteger;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVariableArray,inInteger)
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
    case ((arr as VARIABLE_ARRAY(numberOfElements = n)),pos)
      local VariableArray arr;
      equation 
        print("-vararray_nth , pos : ");
        ps = intString(pos);
        print(ps);
        print("\n  array_length:");
        len = vararrayLength(arr);
        lens = intString(len);
        print(lens);
        print("\n");
        ns = intString(n);
        print("n :");
        print(ns);
        print("\n");
      then
        fail();
  end matchcontinue;
end vararrayNth;

protected function replaceVar "function: replaceVar
  author: PA
 
  Takes a \'Var\' list and a \'Var\' and replaces the var with the 
  same ComponentRef in Var list with Var
"
  input list<Var> inVarLst;
  input Var inVar;
  output list<Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVarLst,inVar)
    local
      Exp.ComponentRef cr1,cr2;
      DAE.Flow flow1,flow2,flow_;
      list<Var> vs,vs_1;
      Var v,repl;
    case ({},_) then {}; 
    case ((VAR(varName = cr1,flow_ = flow1) :: vs),(v as VAR(varName = cr2,flow_ = flow2)))
      equation 
        true = Exp.crefEqual(cr1, cr2);
      then
        (v :: vs);
    case ((v :: vs),(repl as VAR(varName = cr2,flow_ = flow_)))
      equation 
        vs_1 = replaceVar(vs, repl);
      then
        (v :: vs_1);
  end matchcontinue;
end replaceVar;

protected function hashComponentRef "function: hashComponentRef
  author: PA
 
  Calculates a hash value for Exp.ComponentRef
"
  input Exp.ComponentRef cr;
  output Integer res;
  String crstr;
algorithm 
  crstr := Exp.printComponentRefStr(cr);
  res := hashString(crstr);
end hashComponentRef;

protected function hashString "function: hashString
  author: PA
 
  Calculates a hash value of a string
"
  input String str;
  output Integer res;
algorithm 
  res := System.hash(str) "string_list(str) => charlst &
	hash_chars(charlst) => res" ;
end hashString;

protected function hashChars "function: hashChars
  author: PA
 
  Calculates a hash value for a list of chars
"
  input list<String> inStringLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inStringLst)
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

public function getVarAt "function: getVarAt
  author: PA
 
  Return variable at a given position, enumerated from 1..n
"
  input Variables inVariables;
  input Integer inInteger;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVariables,inInteger)
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
  end matchcontinue;
end getVarAt;

public function getVar "function: getVar
  author: PA
 
  Return a variable(s) and its index(es) in the vector.
  The indexes is enumerated from 1..n 
  Normally a variable has only one index, but in case of an array variable
  it may have several indexes and several scalar variables,
  therefore a list of variables and a list of  indexes is returned.
  inputs:  (Exp.ComponentRef, Variables) 
  outputs: (Var list, int list /* indexes */)
"
  input Exp.ComponentRef inComponentRef;
  input Variables inVariables;
  output list<Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm 
  (outVarLst,outIntegerLst):=
  matchcontinue (inComponentRef,inVariables)
    local
      Var v;
      Value indx;
      Exp.ComponentRef cr;
      Variables vars;
      list<Value> indxs;
    case (cr,vars)
      equation 
        (v,indx) = getVar2(cr, vars) "if scalar found, return it" ;
      then
        ({v},{indx});
    case (cr,vars) /* check if array */ 
      local list<Var> v;
      equation 
        (v,indxs) = getArrayVar(cr, vars);
      then
        (v,indxs);
  end matchcontinue;
end getVar;

protected function getVar2 "function: getVar2 
  author: PA
 
  Helper function to get_var, checks one scalar variable
"
  input Exp.ComponentRef inComponentRef;
  input Variables inVariables;
  output Var outVar;
  output Integer outInteger;
algorithm 
  (outVar,outInteger):=
  matchcontinue (inComponentRef,inVariables)
    local
      Value hval,hashindx,indx,indx_1,bsize,n;
      list<CrefIndex> indexes;
      Var v;
      Exp.ComponentRef cr2,cr;
      DAE.Flow flow_;
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
        ((v as VAR(cr2,_,_,_,_,_,_,_,_,_,_,_,_,flow_))) = vararrayNth(varr, indx);
        true = Exp.crefEqual(cr, cr2);
        indx_1 = indx + 1;
      then
        (v,indx_1);
    case (cr,VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation 
        hval = hashComponentRef(cr);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr, indexes);
        failure((_) = vararrayNth(varr, indx));
        print("get var failed because vararray_nth failed, cr:");
        str = Exp.printComponentRefStr(cr);
        print(str);
        print("\n");
      then
        fail();
  end matchcontinue;
end getVar2;

protected function getArrayVar "function: getArrayVar
  author: PA
 
  Helper function to get_var, checks one array variable.
  I.e. get_array_var(v,<vars>) will for an array v{3} return
  { v{1},v{2},v{3} }
"
  input Exp.ComponentRef inComponentRef;
  input Variables inVariables;
  output list<Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm 
  (outVarLst,outIntegerLst):=
  matchcontinue (inComponentRef,inVariables)
    local
      Exp.ComponentRef cr_1,cr2,cr;
      Value hval,hashindx,indx,bsize,n;
      list<CrefIndex> indexes;
      Var v;
      list<Exp.Subscript> instdims;
      DAE.Flow flow_;
      list<Var> vs;
      list<Value> indxs;
      Variables vars;
      list<CrefIndex>[:] hashvec;
      list<StringIndex>[:] oldhashvec;
      VariableArray varr;
    case (cr,(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n)))
      equation 
        cr_1 = Exp.subscriptCref(cr, {Exp.INDEX(Exp.ICONST(1))}) "one dimensional arrays" ;
        hval = hashComponentRef(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as VAR(cr2,_,_,_,_,_,instdims,_,_,_,_,_,_,flow_))) = vararrayNth(varr, indx);
        true = Exp.crefEqual(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
    case (cr,(vars as VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))) /* two dimensional arrays */ 
      equation 
        cr_1 = Exp.subscriptCref(cr, {Exp.INDEX(Exp.ICONST(1)),Exp.INDEX(Exp.ICONST(1))});
        hval = hashComponentRef(cr_1);
        hashindx = intMod(hval, bsize);
        indexes = hashvec[hashindx + 1];
        indx = getVar3(cr_1, indexes);
        ((v as VAR(cr2,_,_,_,_,_,instdims,_,_,_,_,_,_,flow_))) = vararrayNth(varr, indx);
        true = Exp.crefEqual(cr_1, cr2);
        (vs,indxs) = getArrayVar2(instdims, cr, vars);
      then
        (vs,indxs);
  end matchcontinue;
end getArrayVar;

protected function getArrayVar2 "function: getArrayVar2
  author: PA
 
  Helper function to get_array_var.
  Note: Only implemented for arrays of dimension 1 and 2.
  inputs:  (DAE.InstDims, /* array_inst_dims */
              Exp.ComponentRef, /* array_var_name */
              Variables) 
  outputs: (Var list /* arrays scalar vars */,
              int list /* arrays scalar indxs */)
"
  input DAE.InstDims inInstDims;
  input Exp.ComponentRef inComponentRef;
  input Variables inVariables;
  output list<Var> outVarLst;
  output list<Integer> outIntegerLst;
algorithm 
  (outVarLst,outIntegerLst):=
  matchcontinue (inInstDims,inComponentRef,inVariables)
    local
      list<Value> indx_lst,indxs_1,indx_lst1,indx_lst2;
      list<list<Value>> indx_lstlst,indxs,indx_lstlst1,indx_lstlst2;
      list<list<Exp.Subscript>> subscripts_lstlst,subscripts_lstlst1,subscripts_lstlst2,subscripts;
      list<Key> scalar_crs;
      list<list<Var>> vs;
      list<Var> vs_1;
      Value i1,i2;
      Exp.ComponentRef arr_cr;
      Variables vars;
    case ({Exp.INDEX(exp = Exp.ICONST(integer = i1))},arr_cr,vars)
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
    case ({Exp.INDEX(exp = Exp.ICONST(integer = i1)),Exp.INDEX(exp = Exp.ICONST(integer = i2))},arr_cr,vars)
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
  end matchcontinue;
end getArrayVar2;

protected function subscript2dCombinations "function: susbscript_2d_combinations
 
  This function takes two lists of list of subscripts and combines them in 
  all possible combinations. This is used when finding all indexes of a 2d
  array.
  For instance, subscript2dCombinations({{a},{b},{c}},{{x},{y},{z}})
  => {{a,x},{a,y},{a,z},{b,x},{b,y},{b,z},{c,x},{c,y},{c,z}}
  inputs:  (Exp.Subscript list list /* dim1 subs */,
              Exp.Subscript list list /* dim2 subs */)
  outputs: (Exp.Subscript list list) 
"
  input list<list<Exp.Subscript>> inExpSubscriptLstLst1;
  input list<list<Exp.Subscript>> inExpSubscriptLstLst2;
  output list<list<Exp.Subscript>> outExpSubscriptLstLst;
algorithm 
  outExpSubscriptLstLst:=
  matchcontinue (inExpSubscriptLstLst1,inExpSubscriptLstLst2)
    local
      list<list<Exp.Subscript>> lst1,lst2,res,ss,ss2;
      list<Exp.Subscript> s1;
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
  input list<Exp.Subscript> inExpSubscriptLst;
  input list<list<Exp.Subscript>> inExpSubscriptLstLst;
  output list<list<Exp.Subscript>> outExpSubscriptLstLst;
algorithm 
  outExpSubscriptLstLst:=
  matchcontinue (inExpSubscriptLst,inExpSubscriptLstLst)
    local
      list<list<Exp.Subscript>> lst1,ss2;
      list<Exp.Subscript> elt1,ss,s2;
    case (_,{}) then {}; 
    case (ss,(s2 :: ss2))
      equation 
        lst1 = subscript2dCombinations2(ss, ss2);
        elt1 = listAppend(ss, s2);
      then
        (elt1 :: lst1);
  end matchcontinue;
end subscript2dCombinations2;

public function existsVar "function: existsVar
  author: PA
 
  Return true if a variable exists in th vector
"
  input Exp.ComponentRef inComponentRef;
  input Variables inVariables;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inVariables)
    local
      Value hval,hashindx,indx,bsize,n;
      list<CrefIndex> indexes;
      Var v;
      Exp.ComponentRef cr2,cr;
      DAE.Flow flow_;
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
        ((v as VAR(cr2,_,_,_,_,_,_,_,_,_,_,_,_,flow_))) = vararrayNth(varr, indx);
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

public function getVarUsingName "function: getVarUsingName
  author: lucian
 
  Return a variable and its index in the vector.
  The index is enumerated from 1..n 
"
  input String inString;
  input Variables inVariables;
  output Var outVar;
  output Integer outInteger;
algorithm 
  (outVar,outInteger):=
  matchcontinue (inString,inVariables)
    local
      Value hval,hashindx,indx,indx_1,bsize,n;
      list<StringIndex> indexes;
      Var v;
      Exp.ComponentRef cr2,name;
      DAE.Flow flow_;
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
        ((v as VAR(cr2,_,_,_,_,_,_,_,_,name,_,_,_,flow_))) = vararrayNth(varr, indx);
        name_str = Exp.printComponentRefStr(name);
        equality(name_str = cr);
        indx_1 = indx + 1;
      then
        (v,indx_1);
    case (cr,VARIABLES(crefIdxLstArr = hashvec,strIdxLstArr = oldhashvec,varArr = varr,bucketSize = bsize,numberOfVars = n))
      equation 
        hval = hashString(cr);
        hashindx = intMod(hval, bsize);
        indexes = oldhashvec[hashindx + 1];
        indx = getVarUsingName2(cr, indexes);
        failure((_) = vararrayNth(varr, indx));
        print(
          "get var using name failed because vararray_nth failed, name:");
        print(cr);
        print("\n");
      then
        fail();
  end matchcontinue;
end getVarUsingName;

public function setVarKind "function setVarKind
  author: PA
 
  Sets the VarKind of a variable
"
  input Var inVar;
  input VarKind inVarKind;
  output Var outVar;
algorithm 
  outVar:=
  matchcontinue (inVar,inVarKind)
    local
      Exp.ComponentRef cr,origname;
      VarKind kind,new_kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      Option<Exp.Exp> bind,st;
      Option<Values.Value> v;
      list<Exp.Subscript> dim;
      Value i;
      list<Absyn.Path> classes;
      Option<DAE.VariableAttributes> attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
    case (VAR(varName = cr,varKind = kind,varDirection = dir,varType = tp,bindExp = bind,bindValue = v,arryDim = dim,startValue = st,index = i,origVarName = origname,className = classes,values = attr,comment = comment,flow_ = flow_),new_kind) then VAR(cr,new_kind,dir,tp,bind,v,dim,st,i,origname,classes,attr,
          comment,flow_); 
  end matchcontinue;
end setVarKind;

protected function getVar3 "function: getVar3
  author: PA
 
  Helper function to get_var
"
  input Exp.ComponentRef inComponentRef;
  input list<CrefIndex> inCrefIndexLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inComponentRef,inCrefIndexLst)
    local
      Exp.ComponentRef cr,cr2;
      Value v,res;
      list<CrefIndex> vs;
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

protected function getVarUsingName2 "function: getVarUsingName2
  author: PA
 
  Helper function to get_var_using_name
"
  input String inString;
  input list<StringIndex> inStringIndexLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inString,inStringIndexLst)
    local
      String cr,cr2;
      Value v,res;
      list<StringIndex> vs;
    case (cr,(STRINGINDEX(str = cr2,index = v) :: _))
      equation 
        equality(cr = cr2);
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

protected function deleteVar "function: deleteVar
  author: PA
 
  Deletes a variable from \'Variables\'. This is an expensive operation 
  since we need to create a new binary tree with new indexes as well 
  as a new compacted vector of variables.
"
  input Exp.ComponentRef inComponentRef;
  input Variables inVariables;
  output Variables outVariables;
algorithm 
  outVariables:=
  matchcontinue (inComponentRef,inVariables)
    local
      list<Var> varlst,varlst_1;
      Variables newvars,newvars_1;
      Exp.ComponentRef cr;
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

protected function deleteVar2 "function: deleteVar2
  author: PA
 
  Helper function to delete_var.
  Deletes the var named \'Exp.ComponentRef\' from the \'Var\' list.
"
  input Exp.ComponentRef inComponentRef;
  input list<Var> inVarLst;
  output list<Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inComponentRef,inVarLst)
    local
      Exp.ComponentRef cr1,cr2;
      DAE.Flow flow_;
      list<Var> vs,vs_1;
      Var v;
    case (_,{}) then {}; 
    case (cr1,(VAR(varName = cr2,flow_ = flow_) :: vs))
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

public function transposeMatrix "function: transposeMatrix
  author: PA
 
  Calculates the transpose of the incidence matrix, i.e. which equations 
  each variable is present in.
"
  input IncidenceMatrix m;
  output IncidenceMatrixT mt;
  list<list<Value>> mlst,mtlst;
algorithm 
  mlst := arrayList(m);
  mtlst := transposeMatrix2(mlst);
  mt := listArray(mtlst);
end transposeMatrix;

protected function transposeMatrix2 "function: transposeMatrix2
  author: PA
 
  Helper function to transpose_matrix
"
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm 
  outIntegerLstLst:=
  matchcontinue (inIntegerLstLst)
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

protected function transposeMatrix3 "function: transposeMatrix3
  author: PA
 
  Helper function to transpose_matrix2
"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input list<list<Integer>> inIntegerLstLst4;
  output list<list<Integer>> outIntegerLstLst;
algorithm 
  outIntegerLstLst:=
  matchcontinue (inIntegerLstLst1,inInteger2,inInteger3,inIntegerLstLst4)
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

public function absIncidenceMatrix "function absIncidenceMatrix
  author: PA
  
  Applies absolute value to all entries in the incidence matrix.
  This can be used when e.g. der(x) and x are considered the same variable.
"
  input IncidenceMatrix m;
  output IncidenceMatrix res;
  list<list<Value>> lst,lst_1;
algorithm 
  lst := arrayList(m);
  lst_1 := Util.listListMap(lst, int_abs);
  res := listArray(lst_1);
end absIncidenceMatrix;

public function varsIncidenceMatrix "function: varsIncidenceMatrix
  author: PA
  Return all variable indices in the incidence matrix, i.e.
  all elements of the matrix.
"
  input IncidenceMatrix m;
  output list<Integer> res;
  list<list<Value>> mlst;
algorithm 
  mlst := arrayList(m);
  res := Util.listFlatten(mlst);
end varsIncidenceMatrix;

protected function transposeRow "function: transposeRow
  author: PA
 
  Helper function to transpose_matrix2.
  Input: IncidenceMatrix (eqn => var)
  Input: row number (variable)
  Input: iterator (start with one)
 
  inputs:  (int list list, int /* row */,int /* iter */)
  outputs:  int list
"
  input list<list<Integer>> inIntegerLstLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<Integer> outIntegerLst;
algorithm 
  outIntegerLst:=
  matchcontinue (inIntegerLstLst1,inInteger2,inInteger3)
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

public function dumpIncidenceMatrix "function: dumpIncidenceMatrix
  author: PA
 
  Prints the incidence matrix on stdout.
"
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

public function dumpIncidenceMatrixT "function: dumpIncidenceMatrixT
  author: PA
 
  Prints the transposed incidence matrix on stdout.
"
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

protected function dumpIncidenceMatrix2 "function: dumpIncidenceMatrix2
  author: PA
 
  Helper function to dump_incidence_matrix (+_t).
"
  input list<list<Integer>> inIntegerLstLst;
  input Integer rowIndex;
algorithm 
  _:=
  matchcontinue (inIntegerLstLst,rowIndex)
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

protected function dumpIncidenceRow "function: dumpIncidenceRow
  author: PA
 
  Helper function to dump_incidence_matrix2.
"
  input list<Integer> inIntegerLst;
algorithm 
  _:=
  matchcontinue (inIntegerLst)
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

public function dumpMatching "function: dumpMatching
  author: PA
 
  prints the matching information on stdout.
"
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

protected function dumpMatching2 "function: dumpMatching2
  author: PA
 
  Helper function to dump_matching.
"
  input Integer[:] inIntegerArray;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inIntegerArray,inInteger)
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

public function matchingAlgorithm "function: matchingAlgorithm
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
              DAELow,IncidenceMatrix, IncidenceMatrixT) 
"
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  input MatchingOptions inMatchingOptions;
  output Integer[:] outIntegerArray1;
  output Integer[:] outIntegerArray2;
  output DAELow outDAELow3;
  output IncidenceMatrix outIncidenceMatrix4;
  output IncidenceMatrixT outIncidenceMatrixT5;
algorithm 
  (outIntegerArray1,outIntegerArray2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5):=
  matchcontinue (inDAELow,inIncidenceMatrix,inIncidenceMatrixT,inMatchingOptions)
    local
      Value nvars,neqns,memsize;
      String ns,ne;
      Assignments assign1,assign2,ass1,ass2;
      DAELow dae,dae_1,dae_2;
      Variables v,kv,v_1,kv_1,vars,exv;
      EquationArray e,re,ie,e_1,re_1,ie_1,eqns;
      MultiDimEquation[:] ae,ae1;
      Algorithm.Algorithm[:] al;
      EventInfo ev;
      list<Value>[:] m,mt,m_1,mt_1;
      BinTree s;
      list<Equation> e_lst,re_lst,ie_lst,e_lst_1,re_lst_1,ie_lst_1;
      list<MultiDimEquation> ae_lst,ae_lst1;
      Value[:] vec1,vec2;
      MatchingOptions match_opts;
      ExternalObjectClasses eoc;
    case ((dae as DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,REMOVE_SIMPLE_EQN())))
      equation 
        DAEEXT.clearDifferentiated();
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once.
	  Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,(dae as DAELOW(v,kv,exv,e,re,ie,ae,al,ev,eoc)),m,mt) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts);
				/* NOTE: Here it could be possible to run removeSimpleEquations again, since algebraic equations
				could potentially be removed after a index reduction has been done. However, removing equations here
				also require that e.g. zero crossings, array equations, etc. must be recalculated. */
        m_1 = incidenceMatrix(dae) "Rerun matching to get updated assignments and incidence matrices TODO: instead of rerunning: find out which equations are removed
	  and remove those from assignments and incidence matrix.
	" ;
        mt_1 = transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mt_1);
        memsize = nvars + nvars;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae_2,m,mt) = matchingAlgorithm2(dae, m_1, mt_1, nvars, neqns, 1, assign1, assign2, 
          match_opts);
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae_2,m,mt);
    case ((dae as DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,KEEP_SIMPLE_EQN())))
      equation 
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once.
	  Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae,m,mt) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts);
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae,m,mt);
  end matchcontinue;
end matchingAlgorithm;

protected function checkMatching "function: checkMatching
  author: PA
 
  Checks that the matching is correct, i.e. that the number of variables
  is the same as the number of equations. If not, the function fails and
  prints an error message.
  If matching options indicate that underconstrained systems are ok, no 
  check is performed.
"
  input DAELow inDAELow;
  input MatchingOptions inMatchingOptions;
algorithm 
  _:=
  matchcontinue (inDAELow,inMatchingOptions)
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
        Error.addMessage(Error.UNDERDET_EQN_SYSTEM, {vsize_str,esize_str});
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
        Error.addMessage(Error.OVERDET_EQN_SYSTEM, {vsize_str,esize_str});
      then
        fail();
    case (_,_)
      equation 
        Debug.fprint("failtrace", "-check_matching failed\n");
      then
        fail();
  end matchcontinue;
end checkMatching;

protected function assignmentsVector "function: assignmentsVector
  author: PA
 
  Converts Assignments to vector of int elements
"
  input Assignments inAssignments;
  output Integer[:] outIntegerArray;
algorithm 
  outIntegerArray:=
  matchcontinue (inAssignments)
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
        print("-assignments_vector failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsVector;

protected function assignmentsCreate "function: assignmentsCreate
  author: PA
 
  Creates an assignment array of n elements, filled with value v
 
  inputs:  (int /* size */, int /* memsize */, int) 	  
  outputs: => Assignments
"
  input Integer n;
  input Integer memsize;
  input Integer v;
  output Assignments outAssignments;
  list<Value> lst;
  Value[:] arr;
algorithm 
  lst := Util.listFill(0, memsize);
  arr := listArray(lst) "	array_create(memsize,v) => arr &
	" ;
  outAssignments := ASSIGNMENTS(n,memsize,arr);
end assignmentsCreate;

protected function assignmentsSetnth "function: assignmentsSetnth
  author: PA
 
  Sets the n:nt assignment value to \'value\'.
  
  inputs:  (Assignments, int /* n */, int /* value */) 
  outputs:  Assignments
"
  input Assignments inAssignments1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Assignments outAssignments;
algorithm 
  outAssignments:=
  matchcontinue (inAssignments1,inInteger2,inInteger3)
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

protected function assignmentsExpand "function: assignmentsExpand
  author: PA
 
  Expands the assignments array with n values, initialized with zero.
 
  inputs:  (Assignments, int /* n */) 
  outputs:  Assignments
"
  input Assignments inAssignments;
  input Integer inInteger;
  output Assignments outAssignments;
algorithm 
  outAssignments:=
  matchcontinue (inAssignments,inInteger)
    local
      Assignments ass,ass_1,ass_2;
      Value n_1,n;
    case (ass,0) then ass; 
    case (ass,n)
      equation 
        ass_1 = assignmentsAdd(ass, 0);
        n_1 = n - 1;
        ass_2 = assignmentsExpand(ass_1, n_1);
      then
        ass_2;
  end matchcontinue;
end assignmentsExpand;

protected function assignmentsAdd "function: assignmentsAdd
  author: PA
 
  Adds a value to the end of the assignments array. If memsize = actual size
  this means copying the whole array, expanding it size to fit the value 
  Expansion is made by a factor 1.4. Otherwise, the element is inserted taking O(1) in 
  insertion cost.
 
  inputs:  (Assignments, int /* value */) 
  outputs:  Assignments
"
  input Assignments inAssignments;
  input Integer inInteger;
  output Assignments outAssignments;
algorithm 
  outAssignments:=
  matchcontinue (inAssignments,inInteger)
    local
      Real msr,msr_1;
      Value ms_1,s_1,ms_2,s,ms,v;
      Value[:] arr_1,arr_2,arr;
    case (ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation 
        (s == ms) = true "Out of bounds, increase and copy." ;
        msr = intReal(ms);
        msr_1 = msr*.0.4;
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

protected function matchingAlgorithm2 "function: matchingAlgorithm2
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
              DAELow, IncidenceMatrix, IncidenceMatrixT)
"
  input DAELow inDAELow1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Assignments inAssignments7;
  input Assignments inAssignments8;
  input MatchingOptions inMatchingOptions9;
  output Assignments outAssignments1;
  output Assignments outAssignments2;
  output DAELow outDAELow3;
  output IncidenceMatrix outIncidenceMatrix4;
  output IncidenceMatrixT outIncidenceMatrixT5;
algorithm 
  (outAssignments1,outAssignments2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inAssignments7,inAssignments8,inMatchingOptions9)
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
    case (dae,m,mt,nv,nf,i,ass1,ass2,_)
      equation 
        (nv == i) = true;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
         /* eMark(i)=vMark(i)=false exit loop */ 
      then
        (ass1_1,ass2_1,dae,m,mt);
    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts)
      equation 
        i_1 = i + 1;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,dae,m,mt) = matchingAlgorithm2(dae, m, mt, nv, nf, i_1, ass1_1, ass2_1, match_opts);
      then
        (ass1_2,ass2_2,dae,m,mt);
    case (dae,m,mt,nv,nf,i,ass1,ass2,(INDEX_REDUCTION(),eq_cons,r_simple))
      equation 
        ((dae as DAELOW(VARIABLES(_,_,_,_,nv_1),VARIABLES(_,_,_,_,nkv),_,eqns,_,_,_,_,_,_)),m,mt) = reduceIndexDummyDer(dae, m, mt, nv, nf, i) "path_found failed, Try index reduction using dummy derivatives.
	 When a constraint exist between states and index reduction is needed
	 the dummy derivative will select one of the states as a dummy state
	 (and the derivative of that state as a dummy derivative).
	 For instance, u1=u2 is a constraint between states. Choose u1 as dummy state
	 and der(u1) as dummy derivative, named der_u1. The differentiated function 
	 then becomes: der_u1 = der(u2).
	 In the dummy derivative method this equation is added and the original equation
	 u1=u2 is kept. This is not the case for the original pantilides algorithm, where
	 the original equation is removed from the system.
	" ;
        nf_1 = equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
	   be necessary to restart the matching, according to Bernard Bachmann. Instead one 
	   could continue the matching as usual. This was tested (2004-11-22) and it does not 
	   work to continue without restarting.
	   For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
	   not restarting.
	   2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
	   of the system in order to work. SO: Matching is not needed to be restarted from 
	   scratch.
	" ;
        nvd = nv_1 - nv;
        ass1_1 = assignmentsExpand(ass1, nvd);
        ass2_1 = assignmentsExpand(ass2, nvd);
        (ass1_2,ass2_2,dae,m,mt) = matchingAlgorithm2(dae, m, mt, nv_1, nf_1, i, ass1_1, ass2_1, 
          (INDEX_REDUCTION(),eq_cons,r_simple));
      then
        (ass1_2,ass2_2,dae,m,mt);
    case (dae,m,mt,nv,nf,i,ass1,ass2,_)
      equation 
        eqn_lst = DAEEXT.getMarkedEqns() "When index reduction also fails, the model is structurally 
	 singular." ;
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

protected function dumpMarkedEqns "function: dumpMarkedEqns
  author: PA
  
  Dumps only the equations given as list of indexes to a string.
"
  input DAELow inDAELow;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inDAELow,inIntegerLst)
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

protected function dumpMarkedVars "function: dumpMarkedVars
  author: PA
  
  Dumps only the variable names given as list of indexes to a string.
"
  input DAELow inDAELow;
  input list<Integer> inIntegerLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inDAELow,inIntegerLst)
    local
      String s1,s2,res,s3;
      Value v_1,v;
      Exp.ComponentRef cr;
      DAELow dae;
      Variables vars;
      list<Value> vs;
    case (_,{}) then ""; 
    case ((dae as DAELOW(orderedVars = vars)),(v :: vs))
      equation 
        s1 = dumpMarkedVars(dae, vs);
        VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,_) = getVarAt(vars, v);
        s2 = Exp.printComponentRefStr(cr);
        s3 = intString(v);
        res = Util.stringAppendList({s2,"(",s3,"), ",s1});
      then
        res;
  end matchcontinue;
end dumpMarkedVars;

protected function reduceIndexDummyDer "function: reduceIndexDummyDer
  author: PA
 
  When matching fails, this function is called to try to 
  reduce the index by differentiating the marked equations and
  replacing one of the variable with a dummy derivative, i.e. making 
  it algebraic.
  The new DAELow is returned along with an updated incidence matrix.
  
  inputs: (DAELow, IncidenceMatrix, IncidenceMatrixT,
             int /* number of vars */, int /* number of eqns */, int /* i */)
  outputs: (DAELow, IncidenceMatrix, IncidenceMatrixT)
"
  input DAELow inDAELow1;
  input IncidenceMatrix inIncidenceMatrix2;
  input IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  output DAELow outDAELow;
  output IncidenceMatrix outIncidenceMatrix;
  output IncidenceMatrixT outIncidenceMatrixT;
algorithm 
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6)
    local
      list<Value> eqns,diff_eqns,eqns_1,stateindx,deqns,reqns,changedeqns;
      list<Key> states;
      DAELow dae;
      list<Value>[:] m,mt;
      Value nv,nf,stateno,i;
      Exp.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
    case (dae,m,mt,nv,nf,i)
      equation 
        eqns = DAEEXT.getMarkedEqns();
        //print("marked equations:");print(Util.stringDelimitList(Util.listMap(eqns,intString),","));
        //print("\n");
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        //print("differentiating equations:");print(Util.stringDelimitList(Util.listMap(eqns_1,intString),","));
        //print("\n");
				
				// Collect the states in the equations that are singular, i.e. composing a constraint between states.
				// Note that states are collected from -all- marked equations, not only the differentiated ones.
        (states,stateindx) = statesInEqns(eqns, dae, m, mt) "" ;
        (dae,m,mt,nv,nf,deqns) = differentiateEqns(dae, m, mt, nv, nf, eqns_1);
        (state,stateno) = selectDummyState(states, stateindx, dae, m, mt);
        //print("Selected ");print(Exp.printComponentRefStr(state));print(" as dummy state\n");
       //print(" From candidates:");print(Util.stringDelimitList(Util.listMap(states,Exp.printComponentRefStr),", "));print("\n");
        dae = propagateDummyFixedAttribute(dae, eqns_1, state, stateno);
        (dummy_der,dae) = newDummyVar(state, dae)  ;
        //print("Chosen dummy: ");print(Exp.printComponentRefStr(dummy_der));print("\n");
        reqns = eqnsForVarWithStates(mt, stateno);
        changedeqns = Util.listUnionOnTrue(deqns, reqns, int_eq);
        (dae,m,mt) = replaceDummyDer(state, dummy_der, dae, m, mt, changedeqns) "We need to change variables in the differentiated equations and in the 
	  equations having the dummy derivative" ;
        dae = makeAlgebraic(dae, state);
        (m,mt) = updateIncidenceMatrix(dae, m, mt, changedeqns);
        //print("new DAE:");
        //dump(dae);
        //print("new IM:");
        //dumpIncidenceMatrix(m);
      then
        (dae,m,mt);
    case (dae,m,mt,nv,nf,i)
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
    case (_,_,_,_,_,_)
      equation 
        print("-reduce_index_dummy_der failed\n");
      then
        fail();
  end matchcontinue;
end reduceIndexDummyDer;

protected function propagateDummyFixedAttribute "function: propagateDummyFixedAttribute
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
  state.
"
  input DAELow inDAELow;
  input list<Integer> inIntegerLst;
  input Exp.ComponentRef inComponentRef;
  input Integer inInteger;
  output DAELow outDAELow;
algorithm 
  outDAELow:=
  matchcontinue (inDAELow,inIntegerLst,inComponentRef,inInteger)
    local
      list<Value> eqns_1,eqns;
      list<Equation> eqns_lst;
      list<Key> crefs;
      Exp.ComponentRef state,dummy;
      Var v,v_1,v_2;
      Value indx,indx_1,dummy_no;
      Boolean dummy_fixed;
      Variables vars_1,vars,kv,ev;
      DAELow dae;
      EquationArray e,se,ie;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo ei;
      ExternalObjectClasses eoc;
   /* eqns dummy state */ 
    case ((dae as DAELOW(vars,kv,ev,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no) 
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
        DAELOW(vars_1,kv,ev,e,se,ie,ae,al,ei,eoc);
      // Never propagate fixed=true
      case ((dae as DAELOW(vars,kv,ev,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no) 
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

protected function findState "function: findState
  author: PA
 
  Returns the first state from a list of component references.
"
  input Variables inVariables;
  input list<Exp.ComponentRef> inExpComponentRefLst;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inVariables,inExpComponentRefLst)
    local
      Var v;
      Variables vars;
      Exp.ComponentRef cr;
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

protected function equationsCrefs "function: equationsCrefs
  author: PA
 
  From a list of equations return all occuring variables/component 
  references.
"
  input list<Equation> inEquationLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inEquationLst)
    local
      list<Key> crs1,crs2,crs3,crs,crs2_1,crs3_1;
      Exp.Exp e1,e2,e;
      list<Equation> es;
      Exp.ComponentRef cr;
      Value indx;
      list<Exp.Exp> expl,expl1,expl2;
      WhenEquation weq;
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
      local list<list<Exp.ComponentRef>> crs2;
      equation 
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl, Exp.getCrefFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs = listAppend(crs1, crs2_1);
      then
        crs;
    case ((ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es))
      local list<list<Exp.ComponentRef>> crs2,crs3;
      equation 
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl1, Exp.getCrefFromExp);
        crs3 = Util.listMap(expl2, Exp.getCrefFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs3_1 = Util.listFlatten(crs3);
        crs = Util.listFlatten({crs1,crs2_1,crs3_1});
      then
        crs;
    case ((WHEN_EQUATION(whenEquation = WHEN_EQ(index = indx,left = cr,right = e,elsewhenPart=SOME(weq))) :: es))
      equation 
        crs1 = equationsCrefs(es);
        crs2 = Exp.getCrefFromExp(e);
        crs3 = equationsCrefs({WHEN_EQUATION(weq)});
        crs = listAppend(crs1, listAppend(crs2, crs3));
      then
        (cr :: crs);
  end matchcontinue;
end equationsCrefs;

protected function updateIncidenceMatrix "function: updateIncidenceMatrix
  author: PA
 
  Takes a daelow and the incidence matrix and its transposed represenation
  and a list of  equation indexes that needs to be updated.
  First the IncidenceMatrix is updated, i.e. the mapping from equations
  to variables. Then, by collecting all variables in the list of equations
  to update, a list of changed variables are retrieved. This is used to 
  update the IncidenceMatrixT (transpose) mapping from variables to 
  equations. The function returns an updated incidence matrix.
 
  inputs:  (DAELow,
              IncidenceMatrix, 
              IncidenceMatrixT,
              int list /* list of equations to update */)
  outputs: (IncidenceMatrix, IncidenceMatrixT) 
"
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
        print("update_incidence_matrix failed\n");
      then
        fail();
  end matchcontinue;
end updateIncidenceMatrix;

protected function updateIncidenceMatrix2 "function: updateIncidenceMatrix2
  author: PA
  
  Helper function to update_incidence_matrix
  
  inputs:  (DAELow,
              IncidenceMatrix,
              int list /* list of equations to update */)
  outputs: (IncidenceMatrix, int list list /* changed vars */)
"
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
    case (dae,m,{}) then (m,{{}}); 
    case ((dae as DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = daeeqns,removedEqs = daeseqns)),m,(e :: eqns))
      equation 
        e_1 = e - 1;
        eqn = equationNth(daeeqns, e_1);
        row = incidenceRow(vars, eqn);
        m_1 = Util.arrayReplaceAtWithFill(row, e_1, m, {});
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

protected function updateTransposedMatrix "function: updateTransposedMatrix
  author: PA
 
  Takes a list of variables and the transposed IncidenceMatrix, and 
  updates the variable rows.
 
  inputs:  (int list /* var list */, 
              IncidenceMatrix,
              IncidenceMatrixT) 
  outputs:  IncidenceMatrixT 
"
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
        mt_1 = Util.arrayReplaceAtWithFill(row_1, v_1, mt, {});
        mt_2 = updateTransposedMatrix(vars, m, mt_1);
      then
        mt_2;
    case (_,_,_)
      equation 
        print("-update_transposed_matrix failed\n");
      then
        fail();
  end matchcontinue;
end updateTransposedMatrix;

public function makeAllStatesAlgebraic "function: makeAllStatesAlgebraic
  author: PA
 
  This function makes all states of a DAELow algebraic.
  Is used when solving an initial value problem, since states are just
  an algebraic variable in that case.
"
  input DAELow inDAELow;
  output DAELow outDAELow;
algorithm 
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<Var> var_lst,var_lst_1;
      Variables vars_1,vars,knvar,evar;
      EquationArray eqns,reqns,ieqns;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo ev;
      ExternalObjectClasses eoc;
    case (DAELOW(vars,knvar,evar,eqns,reqns,ieqns,ae,al,ev,eoc))
      equation 
        var_lst = varList(vars);
        var_lst_1 = makeAllStatesAlgebraic2(var_lst);
        vars_1 = listVar(var_lst_1);
      then
        DAELOW(vars_1,knvar,evar,eqns,reqns,ieqns,ae,al,ev,eoc);
  end matchcontinue;
end makeAllStatesAlgebraic;

protected function makeAllStatesAlgebraic2 "function: makeAllStatesAlgebraic2
  author: PA
 
  Helper function to make_all_states_algebraic
"
  input list<Var> inVarLst;
  output list<Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<Var> vs_1,vs;
      Exp.ComponentRef cr,name;
      DAE.VarDirection d;
      DAE.Type t;
      Option<Exp.Exp> b,start;
      Option<Values.Value> value;
      list<Exp.Subscript> dim;
      Value idx;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      Var v;
    case ({}) then {}; 
    case ((VAR(varName = cr,varKind = STATE(),varDirection = d,varType = t,bindExp = b,bindValue = value,arryDim = dim,startValue = start,index = idx,origVarName = name,className = class_,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs))
      equation 
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (VAR(cr,VARIABLE(),d,t,b,value,dim,start,idx,name,class_,
          dae_var_attr,comment,flow_) :: vs_1);
    case ((v :: vs))
      equation 
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (v :: vs_1);
  end matchcontinue;
end makeAllStatesAlgebraic2;

protected function makeAlgebraic "function: makeAlgebraic
  author: PA
  Make the variable a dummy derivative, i.e. change varkind from STATE 
  to DUMMY_STATE.
  
  inputs:  (DAELow, Exp.ComponentRef /* state */)
  outputs: (DAELow) =
 
"
  input DAELow inDAELow;
  input Exp.ComponentRef inComponentRef;
  output DAELow outDAELow;
algorithm 
  outDAELow:=
  matchcontinue (inDAELow,inComponentRef)
    local
      Exp.ComponentRef cr,name;
      VarKind kind;
      DAE.VarDirection d;
      DAE.Type t;
      Option<Exp.Exp> b,start;
      Option<Values.Value> value;
      list<Exp.Subscript> dim;
      Value idx;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Value> indx;
      Variables vars_1,vars,kv,ev;
      EquationArray e,se,ie;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo wc;
      ExternalObjectClasses eoc;
    case (DAELOW(vars,kv,ev,e,se,ie,ae,al,wc,eoc),cr)
      equation 
        ((VAR(cr,kind,d,t,b,value,dim,start,idx,name,class_,dae_var_attr,comment,flow_) :: _),indx) = getVar(cr, vars);
        vars_1 = addVar(
          VAR(cr,DUMMY_STATE(),d,t,b,value,dim,start,idx,name,class_,
          dae_var_attr,comment,flow_), vars);
      then
        DAELOW(vars_1,kv,ev,e,se,ie,ae,al,wc,eoc);
    case (_,_)
      equation 
        print("-make_algebraic failed\n");
      then
        fail();
  end matchcontinue;
end makeAlgebraic;

protected function replaceDummyDer "function: replaceDummyDer
  author: PA
 
  Helper function to reduce_index_dummy_der
  replaces der(state) with the variable dummy der.
 
  inputs:   (Exp.ComponentRef, /* state */
               Exp.ComponentRef, /* dummy der name */
               DAELow, 
               IncidenceMatrix, 
               IncidenceMatrixT,
               int list /* equations */)
  outputs:  (DAELow, 
               IncidenceMatrix, 
               IncidenceMatrixT)
 
"
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
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
      Exp.ComponentRef state,dummy,dummyder;
      DAELow dae;
      list<Value>[:] m,mt;
      Value e_1,e;
      Equation eqn,eqn_1;
      Variables v_1,v,kv,ev;
      EquationArray eqns_1,eqns,seqns,ie,ie1;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo wc;
      list<Value> rest;
      ExternalObjectClasses eoc;
      list<Equation> ieLst1,ieLst;
    case (state,dummy,dae,m,mt,{}) then (dae,m,mt); 
    case (state,dummyder,DAELOW(v,kv,ev,eqns,seqns,ie,ae,al,wc,eoc),m,mt,(e :: rest))
      equation 
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);
        ieLst = equationList(ie);
        eqn_1 = replaceDummyDer2(state, dummyder, eqn);
        ieLst1 = replaceDummyDerEqns(ieLst,state,dummyder);
        ie1 = listEquation(ieLst1);
        (eqn_1,v_1) = replaceDummyDerOthers(eqn_1, v);
        eqns_1 = equationSetnth(eqns, e_1, eqn_1) "incidence_row(v\'\',eqn\') => row\' &
	 Util.list_replaceat(row\',e\',m) => m\' &
	 transpose_matrix(m\') => mt\' &" ;
        (dae,m,mt) = replaceDummyDer(state, dummyder, DAELOW(v_1,kv,ev,eqns_1,seqns,ie1,ae,al,wc,eoc), 
          m, mt, rest);
      then
        (dae,m,mt);
    case (_,_,_,_,_,_)
      equation 
        print("-replace_dummy_der failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDer;

protected function replaceDummyDer2 "function: replaceDummyDer2
  author: PA
 
  Helper function to reduce_index_dummy_der
  replaces der(state) with dummy_der variable in equation 
"
  input Exp.ComponentRef inComponentRef1;
  input Exp.ComponentRef inComponentRef2;
  input Equation inEquation3;
  output Equation outEquation;
algorithm 
  outEquation:=
  matchcontinue (inComponentRef1,inComponentRef2,inEquation3)
    local
      Exp.Exp dercall,e1_1,e2_1,e1,e2;
      Exp.ComponentRef st,dummyder,cr;
      Value ds,indx,i;
      list<Exp.Exp> expl,in_,out;
      Equation res;
      WhenEquation elsepartRes;
      WhenEquation elsepart;
    case (st,dummyder,EQUATION(exp = e1,scalar = e2))
      equation 
        dercall = Exp.CALL(Absyn.IDENT("der"),{Exp.CREF(st,Exp.REAL())},false,true,Exp.REAL()) "scalar equation" ;
        (e1_1,_) = Exp.replaceExp(e1, dercall, Exp.CREF(dummyder,Exp.REAL()));
        (e2_1,_) = Exp.replaceExp(e2, dercall, Exp.CREF(dummyder,Exp.REAL()));
      then
        EQUATION(e1_1,e2_1);
    case (st,dummyder,ARRAY_EQUATION(index = ds,crefOrDerCref = expl)) /* TODO: We need to go through MultiDimEquation array here.. */  then ARRAY_EQUATION(ds,expl);  /* array equation */ 
    case (st,dummyder,ALGORITHM(index = indx,in_ = in_,out = out)) /* TODO: We need to go through Algorithm.Algorithm here.. */  then ALGORITHM(indx,in_,out);  /* Algorithms */ 
    case (st,dummyder,WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=NONE)))
      equation 
        dercall = Exp.CALL(Absyn.IDENT("der"),{Exp.CREF(st,Exp.REAL())},false,true,Exp.REAL());
        (e1_1,_) = Exp.replaceExp(e1, dercall, Exp.CREF(dummyder,Exp.REAL()));
        res = WHEN_EQUATION(WHEN_EQ(i,cr,e1_1,NONE));
      then
        res;
    case (st,dummyder,WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=SOME(elsepart))))
      equation 
        dercall = Exp.CALL(Absyn.IDENT("der"),{Exp.CREF(st,Exp.REAL())},false,true,Exp.REAL());
        (e1_1,_) = Exp.replaceExp(e1, dercall, Exp.CREF(dummyder,Exp.REAL()));
        WHEN_EQUATION(elsepartRes) = replaceDummyDer2(st,dummyder, WHEN_EQUATION(elsepart));
        res = WHEN_EQUATION(WHEN_EQ(i,cr,e1_1,SOME(elsepartRes)));
      then
        res;
    case (_,_,_)
      equation 
        print("-replace_dummy_der2 failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDer2;

protected function replaceDummyDerEqns "
  author: PA
 
  Helper function to reduceIndexDummy<der
  replaces der(state) with dummy_der variable in list of equations.
"
  input list<Equation> eqns;
  input Exp.ComponentRef st;
  input Exp.ComponentRef dummyder;
  output list<Equation> outEqns;
algorithm 
  outEqns:=
  matchcontinue (eqns,st,dummyder)
    local
      Exp.ComponentRef st,dummyder;
      list<Equation> eqns1,eqns;
      Equation e,e1;
    case ({},st,dummyder) then {};
    case (e::eqns,st,dummyder) 
      equation 
         e1 = replaceDummyDer2(st,dummyder,e);
         eqns1 = replaceDummyDerEqns(eqns,st,dummyder);
      then
        e1::eqns1;
  end matchcontinue;
end replaceDummyDerEqns;

protected function replaceDummyDerOthers "function: replaceDummyDerOthers
  author: PA
 
  Helper function to reduce_index_dummy_der.
  This function replaces
  1. der(der_s)  with der2_s (Where der_s is a dummy state)
  2. der(der(v)) with der2_v (where v is a state)
  3. der(v)  for alg. var v with der_v 
  in the \'Equation\' given as arguments. To do this it needs the \'Variables\' 
  also passed as argument to the function to e.g. determine if a variable
  is a dummy variable, etc.
"
  input Equation inEquation;
  input Variables inVariables;
  output Equation outEquation;
  output Variables outVariables;
algorithm 
  (outEquation,outVariables):=
  matchcontinue (inEquation,inVariables)
    local
      Exp.Exp e1_1,e2_1,e1,e2;
      Variables vars_1,vars_2,vars;
      Value ds,i;
      list<Exp.Exp> expl;
      Exp.ComponentRef cr;
      WhenEquation elsePartRes;
      WhenEquation elsePart;
    case (EQUATION(exp = e1,scalar = e2),vars)
      equation 
        (e1_1,vars_1) = replaceDummyDerOthersExp(e1, vars) "scalar equation" ;
        (e2_1,vars_2) = replaceDummyDerOthersExp(e2, vars_1);
      then
        (EQUATION(e1_1,e2_1),vars_2);
    case (ARRAY_EQUATION(index = ds,crefOrDerCref = expl),vars) /* TODO */  then (ARRAY_EQUATION(ds,expl),vars);  /* array equation */ 
    case (WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=NONE)),vars)
      equation 
        (e2_1,vars_1) = replaceDummyDerOthersExp(e2, vars);
      then
        (WHEN_EQUATION(WHEN_EQ(i,cr,e2_1,NONE)),vars_1);
    case (WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=SOME(elsePart))),vars)
      equation 
        (e2_1,vars_1) = replaceDummyDerOthersExp(e2, vars);
        (WHEN_EQUATION(elsePartRes), vars_2) = replaceDummyDerOthers(WHEN_EQUATION(elsePart),vars_1);
      then
        (WHEN_EQUATION(WHEN_EQ(i,cr,e2_1,SOME(elsePartRes))),vars_2);
    case (_,_)
      equation 
        print("-replace_dummy_der_others failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDerOthers;

protected function replaceDummyDerOthersExp "function: replaceDummyDerOthersExp
  author: PA
 
  Helper function for replace_dummy_der_others
"
  input Exp.Exp inExp;
  input Variables inVariables;
  output Exp.Exp outExp;
  output Variables outVariables;
algorithm 
  (outExp,outVariables):=
  matchcontinue (inExp,inVariables)
    local
      Exp.Exp e,e1_1,e2_1,e1,e2,e3_1,e3;
      Variables vars,vars1,vars2,vars3,vars_1;
      Exp.Operator op;
      DAE.VarDirection a;
      DAE.Type b;
      Option<Exp.Exp> c,f;
      Option<Values.Value> d;
      Value g;
      Exp.ComponentRef h,dummyder,dummyder_1,cr;
      list<Absyn.Path> i;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
    case ((e as Exp.ICONST(integer = _)),vars) then (e,vars); 
    case ((e as Exp.RCONST(real = _)),vars) then (e,vars); 
    case ((e as Exp.SCONST(string = _)),vars) then (e,vars); 
    case ((e as Exp.BCONST(bool = _)),vars) then (e,vars); 
    case ((e as Exp.CREF(componentRef = _)),vars) then (e,vars); 
    case (Exp.BINARY(exp1 = e1,operator = op,exp2 = e2),vars)
      equation 
        (e1_1,vars1) = replaceDummyDerOthersExp(e1, vars);
        (e2_1,vars2) = replaceDummyDerOthersExp(e2, vars1);
      then
        (Exp.BINARY(e1_1,op,e2_1),vars2);
    case (Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2),vars)
      equation 
        (e1_1,vars1) = replaceDummyDerOthersExp(e1, vars);
        (e2_1,vars2) = replaceDummyDerOthersExp(e2, vars1);
      then
        (Exp.LBINARY(e1_1,op,e2_1),vars2);
    case (Exp.UNARY(operator = op,exp = e1),vars)
      equation 
        (e1_1,vars1) = replaceDummyDerOthersExp(e1, vars);
      then
        (Exp.UNARY(op,e1_1),vars1);
    case (Exp.LUNARY(operator = op,exp = e1),vars)
      equation 
        (e1_1,vars1) = replaceDummyDerOthersExp(e1, vars);
      then
        (Exp.LUNARY(op,e1_1),vars1);
    case (Exp.RELATION(exp1 = e1,operator = op,exp2 = e2),vars)
      equation 
        (e1_1,vars1) = replaceDummyDerOthersExp(e1, vars);
        (e2_1,vars2) = replaceDummyDerOthersExp(e2, vars1);
      then
        (Exp.RELATION(e1_1,op,e2_1),vars2);
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars)
      equation 
        (e1_1,vars1) = replaceDummyDerOthersExp(e1, vars);
        (e2_1,vars2) = replaceDummyDerOthersExp(e2, vars1);
        (e3_1,vars3) = replaceDummyDerOthersExp(e3, vars2);
      then
        (Exp.IFEXP(e1_1,e2_1,e3_1),vars3);
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)})}),vars)
      local list<Exp.Subscript> e;
      equation 
        ((VAR(_,STATE(),a,b,c,d,e,f,g,h,i,dae_var_attr,comment,flow_) :: _),_) = getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        dummyder = createDummyVar(cr);
        dummyder_1 = createDummyVar(dummyder);
        vars_1 = addVar(
          VAR(dummyder_1,DUMMY_DER(),a,b,NONE,NONE,e,NONE,0,dummyder_1,i,
          dae_var_attr,comment,flow_), vars);
      then
        (Exp.CREF(dummyder_1,Exp.REAL()),vars_1);
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),vars)
      local list<Exp.Subscript> e;
      equation 
        ((VAR(_,DUMMY_DER(),a,b,c,d,e,f,g,h,i,dae_var_attr,comment,flow_) :: _),_) = getVar(cr, vars) "der(der_s)) der_s is dummy var => der_der_s" ;
        dummyder = createDummyVar(cr);
        vars_1 = addVar(
          VAR(dummyder,DUMMY_DER(),a,b,NONE,NONE,e,NONE,0,dummyder,i,
          dae_var_attr,comment,flow_), vars);
      then
        (Exp.CREF(dummyder,Exp.REAL()),vars_1);
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),vars)
      local list<Exp.Subscript> e;
      equation 
        ((VAR(_,VARIABLE(),a,b,c,d,e,f,g,h,i,dae_var_attr,comment,flow_) :: _),_) = getVar(cr, vars) "der(v) v is alg var => der_v" ;
        dummyder = createDummyVar(cr);
        vars_1 = addVar(
          VAR(dummyder,DUMMY_DER(),a,b,NONE,NONE,e,NONE,0,dummyder,i,
          dae_var_attr,comment,flow_), vars);
      then
        (Exp.CREF(dummyder,Exp.REAL()),vars_1);
    case (e,vars) then (e,vars); 
  end matchcontinue;
end replaceDummyDerOthersExp;

public function varEqual "function: varEqual
  author: PA
  
  Returns true if two Var\'s are equal.
"
  input Var inVar1;
  input Var inVar2;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar1,inVar2)
    local
      Boolean res;
      Exp.ComponentRef cr1,cr2;
      DAE.Flow flow1,flow2;
    case (VAR(varName = cr1,flow_ = flow1),VAR(varName = cr2,flow_ = flow2))
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
      Exp.Exp e11,e12,e21,e22,exp1,exp2;
      Integer i1,i2;
      Exp.ComponentRef cr1,cr2;
    case (EQUATION(e11,e12),EQUATION(e21,e22)) equation
      res = boolAnd(Exp.expEqual(e11,e21),Exp.expEqual(e12,e22));
    then res;
    case(ARRAY_EQUATION(i1,_),ARRAY_EQUATION(i2,_)) equation
      res = intEq(i1,i2);
    then res;
    case(SOLVED_EQUATION(cr1,exp1),SOLVED_EQUATION(cr2,exp2)) equation
      res = boolAnd(Exp.crefEqual(cr1,cr2),Exp.expEqual(exp1,exp2));
    then res;
    case(RESIDUAL_EQUATION(exp1),RESIDUAL_EQUATION(exp2)) equation
      res = Exp.expEqual(exp1,exp2);
    then res;
    case(ALGORITHM(i1,_,_),ALGORITHM(i2,_,_)) equation
      res = intEq(i1,i2);
    then res;
    case (WHEN_EQUATION(WHEN_EQ(i1,_,_,_)),WHEN_EQUATION(WHEN_EQ(i2,_,_,_))) equation
      res = intEq(i1,i2);
    then res;
    case(_,_) then false;
  end matchcontinue;
end equationEqual;

protected function newDummyVar "function: newDummyVar
  author: PA
 
  This function creates a new variable named \"der_\"+<varname> and 
  adds it to the dae.
"
  input Exp.ComponentRef inComponentRef;
  input DAELow inDAELow;
  output Exp.ComponentRef outComponentRef;
  output DAELow outDAELow;
algorithm 
  (outComponentRef,outDAELow):=
  matchcontinue (inComponentRef,inDAELow)
    local
      VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      Option<Exp.Exp> bind,start;
      Option<Values.Value> value;
      list<Exp.Subscript> dim;
      Value idx;
      Exp.ComponentRef name,dummyvar_cr,var;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      Variables vars_1,vars,kv,ev;
      EquationArray eqns,seqns,ie;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo wc;
      ExternalObjectClasses eoc;
      Var dummyvar;
    case (var,DAELOW(vars, kv, ev, eqns, seqns, ie, ae, al, wc,eoc))
      equation 
        ((VAR(_,kind,dir,tp,bind,value,dim,start,idx,name,class_,dae_var_attr,comment,flow_) :: _),_) = getVar(var, vars);
        dummyvar_cr = createDummyVar(var);
        dummyvar = VAR(dummyvar_cr,DUMMY_DER(),dir,tp,NONE,NONE,dim,NONE,0,dummyvar_cr,
          class_,dae_var_attr,comment,flow_);
            /* Dummy variables are algebraic variables, hence fixed = false */
        dummyvar = setVarFixed(dummyvar,false);    
        vars_1 = addVar(dummyvar, vars);
      then
        (dummyvar_cr,DAELOW(vars_1,kv,ev,eqns,seqns,ie,ae,al,wc,eoc));
    case (_,_)
      equation 
        print("-new_dummy_var failed\n");
      then
        fail();
  end matchcontinue;
end newDummyVar;

protected function createDummyVar "function: createDummyVar
  author: PA
 
  Creates a new variable name by adding \"der()\" around the last ident.
  Helper function to new_dummy_var.
"
  input Exp.ComponentRef inComponentRef;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef)
    local
      String ret_str,origname,id;
      list<Exp.Subscript> subs;
      Exp.ComponentRef cr_1,cr;
    case (cr) equation
        ret_str = SimCodegen.changeNameForDerivative(Exp.printComponentRefStr(cr));
    then Exp.CREF_IDENT(ret_str,{});
      
    case (Exp.CREF_IDENT(ident = origname,subscriptLst = subs))
      equation 
        ret_str = SimCodegen.changeNameForDerivative(origname);
      then
        Exp.CREF_IDENT(ret_str,subs);
    case (Exp.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cr))
      equation 
        cr_1 = createDummyVar(cr);
      then
        Exp.CREF_QUAL(id,subs,cr_1);
  end matchcontinue;
end createDummyVar;

protected function selectDummyState "function: selectDummyState
  author: PA
 
  This function is the heuristic to select among the states which one
  will be transformed into  an algebraic variable, a so called dummy state
 (dummy derivative). It should in the future consider initial values, etc.
 
  inputs:  (Exp.ComponentRef list, /* variable names */
              int list, /* variable numbers */
              DAELow, 
              IncidenceMatrix,
              IncidenceMatrixT) 
  outputs: (Exp.ComponentRef, int)
"
  input list<Exp.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output Exp.ComponentRef outComponentRef;
  output Integer outInteger;
algorithm 
  (outComponentRef,outInteger):=
  matchcontinue (varCrefs,varIndices,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      Exp.ComponentRef s;
      Value sn;
      Variables vars;
      IncidenceMatrix m;
      IncidenceMatrixT mt;
      EquationArray eqns;
      list<tuple<Exp.ComponentRef,Integer,Real>> prioTuples;
    case (varCrefs,varIndices,DAELOW(orderedVars=vars,orderedEqs = eqns),m,mt) equation
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

protected function printPrioTuplesStr "Debug function for printing the priorities of state selection to a string"
  input tuple<Exp.ComponentRef,Integer,Real> prioTuples;
  output String str;
  algorithm
    str := matchcontinue(prioTuples)
    case((cr,_,prio)) 
        local Exp.ComponentRef cr;
          Real prio; String s1,s2;
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = realString(prio);
        str = Util.stringAppendList({"(",s1,", ",s2,")"});
      then str;
  end matchcontinue;
end printPrioTuplesStr;
				
protected function selectMinPrio "Selects the state with lowest priority. This will become a dummy state"
  input list<tuple<Exp.ComponentRef,Integer,Real>> tuples;
  output Exp.ComponentRef s;
  output Integer sn;
algorithm
  (s,sn) := matchcontinue(tuples)
    case(tuples) equation
      ((s,sn,_)) = Util.listReduce(tuples,ssPrioTupleMin);
      then (s,sn);
  end matchcontinue;
end selectMinPrio;

protected function ssPrioTupleMin "Select the minimum tuple of two tuples"
  input tuple<Exp.ComponentRef,Integer,Real> tuple1;
  input tuple<Exp.ComponentRef,Integer,Real> tuple2;
  output tuple<Exp.ComponentRef,Integer,Real> tuple3;
algorithm
  tuple3 := matchcontinue(tuple1,tuple2)
    local Exp.ComponentRef cr1,cr2;
      Integer ns1,ns2;
      Real rs1,rs2;      
    case((cr1,ns1,rs1),(cr2,ns2,rs2)) equation
      true = (rs1 <. rs2);
    then ((cr1,ns1,rs1));
      
    case ((cr1,ns1,rs1),(cr2,ns2,rs2)) equation
      true = (rs2 <. rs1);
    then ((cr2,ns2,rs2));
      //exactly equal, choose first one.
      
    case ((cr1,ns1,rs1),(cr2,ns2,rs2)) then ((cr1,ns1,rs1));
  end matchcontinue;
end ssPrioTupleMin;

protected function calculateVarPriorities "Calculates state selection priorities"
	input list<Exp.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input Variables vars;
  input EquationArray eqns; 
  input IncidenceMatrix m;
  input IncidenceMatrixT mt;
  output list<tuple<Exp.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := matchcontinue(varCrefs,varIndices,vars,eqns,m,mt)
  local Exp.ComponentRef varCref;
    Integer varIndx;
    Var v;
    Real prio,prio1,prio2;
    list<tuple<Exp.ComponentRef,Integer,Real>> prios;
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

protected function varStateSelectHeuristicPrio "A heuristic for selecting states when no stateSelect information is available.
author: PA

This heuristic is based on.
1. If a state variable s has an equation on the form s = expr(s1,s2,...,sn) where s1..sn are states 
   it should be a candiate for dummy state. Like for instance phi_rel = J1.phi-J2.phi will make phi_rel 
   a candidate for dummy state whereas J1.phi and J2.phi would be candidates for states.

2. If a state variable komponent_x.s has been selected as a dummy state then komponent_x.s2 could also 
   be a dummy_state. Rationale: This will increase probability that all states belong to the same component
   which is more likely what a user expects.
   
3. A priority based on the number of selectable states with the same name. 
For example
  if the state candidates are: m1.s, m1.v, m2.s, m2.v sd.s_rel (Two translational masses and a springdamper)
  then sd.s_rel should have lower priority than the others.
"
  input Var v;
  input Variables vars;
  input EquationArray eqns;
  input IncidenceMatrix m;
  input IncidenceMatrixT mt;
  output Real prio;
protected 
  list<Integer> vEqns;
  Exp.ComponentRef vCr,origVCr;
  
  Integer vindx;
  Real prio1,prio2,prio3;
algorithm
  (_,vindx::_) := getVar(varCref(v),vars); // Variable index not stored in var itself => lookup required
  vEqns := eqnsForVarWithStates(mt,vindx);
  vCr := varCref(v); 
  origVCr := varOrigCref(v);
  prio1 := varStateSelectHeuristicPrio1(vCr,vEqns,vars,eqns);
  prio2 := varStateSelectHeuristicPrio2(origVCr,vars);
  prio3 := varStateSelectHeuristicPrio3(origVCr,vars);
  prio:= prio1 +. prio2 +. prio3;
end varStateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio3 "Helper function to varStateSelectHeuristicPrio
author: PA
"
  input Exp.ComponentRef cr;
  input Variables vars;
  output Real prio;
algorithm
	prio := matchcontinue(cr,vars)
	     local list<Var> varLst,sameIdentVarLst; Real c,prio;
	  case(cr,vars) equation
	    varLst = varList(vars);
      sameIdentVarLst = Util.listSelect1(varLst,cr,varHasSameLastIdent);
	    c = intReal(listLength(sameIdentVarLst));
	    prio = c *. 0.01;
	    then prio;
	  end matchcontinue;
end varStateSelectHeuristicPrio3;    

protected function varHasSameLastIdent " Helper funciton to varStateSelectHeuristicPrio3.

Returns true if the variable has the same name (the last identifier)
as the variable name given as second argument.
"
input Var v;
input Exp.ComponentRef cr;
output Boolean b;
algorithm
  b := matchcontinue(v,cr)
  local Exp.ComponentRef cr2;
    Exp.Ident id1,id2;
    case(VAR(origVarName=cr2 ),cr ) equation
      id1 = Exp.crefLastIdent(cr);
      id2 = Exp.crefLastIdent(cr2);
			equality(id1 = id2);
	    then true;
    case(_,_) then false;
  end matchcontinue;
end varHasSameLastIdent;


protected function varStateSelectHeuristicPrio2 "Helper function to varStateSelectHeuristicPrio
author: PA
"
  input Exp.ComponentRef cr;
  input Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars) 
    local 
      list<Var> varLst,sameCompVarLst;
    case(cr,vars) equation
      varLst = varList(vars);
      sameCompVarLst = Util.listSelect1(varLst,cr,varInSameComponent);
      _::_ = Util.listSelect(sameCompVarLst,isDummyStateVar);
      then -1.0;
    case(cr,vars) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varInSameComponent " Helper funciton to varStateSelectHeuristicPrio2.

Returns true if the variable is defined in the same sub component
as the variable name given as second argument.
"
input Var v;
input Exp.ComponentRef cr;
output Boolean b;
algorithm
  b := matchcontinue(v,cr)
  local Exp.ComponentRef cr2;
    Exp.Ident id1,id2;
    case(VAR(origVarName=cr2 ),cr ) equation
			true = Exp.crefEqual(Exp.crefStripLastIdent(cr2),Exp.crefStripLastIdent(cr));
	    then true;
    case(_,_) then false;
  end matchcontinue;
end varInSameComponent;
  
protected function varStateSelectHeuristicPrio1 "Helper function to varStateSelectHeuristicPrio
author:  PA
 
"
input Exp.ComponentRef cr;
input list<Integer> eqnLst;
input Variables vars;
input EquationArray eqns;
output Real prio;
algorithm
 prio := matchcontinue(cr,eqnLst,vars,eqns)
 local Integer e; Equation eqn;
   case(cr,{},_,_) then 0.0;
   case(cr,e::eqnLst,vars,eqns) equation
     eqn = equationNth(eqns,e-1);
     true = isStateConstraintEquation(cr,eqn,vars);
     then -1.0;
   case(cr,_::eqnLst,vars,eqns) then varStateSelectHeuristicPrio1(cr,eqnLst,vars,eqns);
 end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function isStateConstraintEquation "Help function to varStateSelectHeuristicPrio2
author: PA

Returns true if an equation is on the form cr = expr(s1,s2...sn) for states cr, s1,s2..,sn
"
  input Exp.ComponentRef cr;
  input	Equation eqn;
  input Variables vars;
  output Boolean res;
algorithm
  res := matchcontinue(cr,eqn,vars)
  local Exp.ComponentRef cr2;
    list<Exp.ComponentRef> crs;
    list<list<Var>> crVars;
    list<Boolean> blst;
    Exp.Exp e2;

			// s = expr(s1,..,sn)  where s1 .. sn are states
    case(cr,EQUATION(Exp.CREF(cr2,_),e2),vars) equation
      true = Exp.crefEqual(cr,cr2);
      _::_::_ = Exp.terms(e2);
      crs = Exp.getCrefFromExp(e2);
      (crVars,_) = Util.listMap12(crs,getVar,vars);
      blst = Util.listMap(Util.listFlatten(crVars),isStateVar);
      res = Util.boolAndList(blst);
     then res;
       
    case(cr,EQUATION(e2,Exp.CREF(cr2,_)),vars) equation
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

protected function varStateSelectPrio "helper function to calculateVarPriorities.
Calculates a priority contribution bases on the stateSelect attribute.
"
	input Var v;
	output Real prio;
	protected
	DAE.StateSelect ss;
algorithm
  ss := varStateSelect(v);
  prio := varStateSelectPrio2(ss);
end varStateSelectPrio;

protected function varStateSelectPrio2 "helper function to varStateSelectPrio"
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



protected function calculateDummyStatePriorities "function: calculate_dummy_state_priority
 
  Calculates a priority for dummy state candidates.
  The state with lowest priority number is selected as a dummy
  variable.
 
  Heuristic parameters:
  1. States that has an initial condition is given pentalty 10.
  2. Equation s1= p  s2 with states s1 and s2 gives penalty 1 for state s1.
  
  The heuristic parameters are summed to get the priority number.
"
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input list<Integer> inIntegerLst;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output list<tuple<Exp.ComponentRef, Integer, Integer>> outTplExpComponentRefIntegerIntegerLst;
algorithm 
  outTplExpComponentRefIntegerIntegerLst:=
  matchcontinue (inExpComponentRefLst,inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      Exp.ComponentRef cr;
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
  input Exp.ComponentRef inComponentRef;
  input Integer inInteger;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output Exp.ComponentRef outComponentRef1;
  output Integer outInteger2;
  output Integer outInteger3;
algorithm 
  (outComponentRef1,outInteger2,outInteger3):=
  matchcontinue (inComponentRef,inInteger,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      Exp.ComponentRef cr;
      Value indx;
      DAELow dae;
      list<Value>[:] m,mt;
    case (cr,indx,dae,m,mt) then (cr,indx,0); 
  end matchcontinue;
end calculateDummyStatePriority;

protected function statesInEqns "function: statesInEqns
  author: PA
 
  Helper function to reduce_index_dummy_der.
  Returns all states in the equations given as equation index list.
 
  inputs:  (int list /* eqns */,
              DAELow, 
              IncidenceMatrix,
              IncidenceMatrixT) 
  outputs: (Exp.ComponentRef list, /* name for each state */
              int list)  /* number for each state */
"
  input list<Integer> inIntegerLst;
  input DAELow inDAELow;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output list<Exp.ComponentRef> outExpComponentRefLst;
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
      Variables vars,kv,ev;
      EquationArray eqns,seqns,ie;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo wc;
      list<Value>[:] m,mt;
      ExternalObjectClasses eoc;
    case ({},_,_,_) then ({},{}); 
    case ((e :: rest),DAELOW(vars,kv,ev,eqns,seqns,ie,ae,al,wc,eoc),m,mt)
      equation 
        (res1,res2) = statesInEqns(rest, DAELOW(vars,kv,ev,eqns,seqns,ie,ae,al,wc,eoc), m, mt);
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
        print("-states_in_eqns failed\n");
      then
        fail();
  end matchcontinue;
end statesInEqns;

protected function statesInVars "function: statesInVars
  author: PA
 
  Helper function to states_in_eqns
 
  inputs:  (Var list, int list)
  outputs: (Exp.ComponentRef list, /* names of the states */
              int list /* number for each state */)
"
  input list<Var> inVarLst;
  input list<Integer> inIntegerLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm 
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inVarLst,inIntegerLst)
    local
      list<Var> vars;
      Value v_1,v;
      Exp.ComponentRef cr;
      DAE.Flow flow_;
      list<Key> res1;
      list<Value> res2,rest;
    case (vars,{}) then ({},{}); 
    case (vars,(v :: rest))
      equation 
        v_1 = v - 1;
        VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,flow_) = listNth(vars, v_1);
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

protected function differentiateEqns "function: differentiateEqns
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
	      int list /* differentiated equations */)
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
  output list<Integer> outIntegerLst6;
algorithm 
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5,outIntegerLst6):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6)
    local
      DAELow dae;
      list<Value>[:] m,mt;
      Value nv,nf,e_1,leneqns,e;
      Equation eqn,eqn_1;
      String str;
      EquationArray eqns_1,eqns,seqns,ie;
      list<Value> reqns,es;
      Variables v,kv,ev;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo wc;
      ExternalObjectClasses eoc;
    case (dae,m,mt,nv,nf,{}) then (dae,m,mt,nv,nf,{}); 
    case ((dae as DAELOW(v,kv,ev,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es))
      equation 
        e_1 = e - 1;
        eqn = equationNth(eqns, e_1);
   
        eqn_1 = Derive.differentiateEquationTime(eqn, v);
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
        (dae,m,mt,nv,nf,reqns) = differentiateEqns(DAELOW(v,kv,ev,eqns_1,seqns,ie,ae,al,wc,eoc), m, mt, nv, nf, es);
      then
        (dae,m,mt,nv,nf,(leneqns :: (e :: reqns)));
    case (_,_,_,_,_,_)
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
        rexpandsize = rsize*.0.4;
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
  rlen_1 := rlen*.1.4;
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
  res := incidenceRow(vars_1, eqn);
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
      Exp.ComponentRef cr,h;
      DAE.VarDirection a;
      DAE.Type b;
      Option<Exp.Exp> c,f;
      Option<Values.Value> d;
      list<Exp.Subscript> e;
      Value g;
      list<Absyn.Path> i;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
    case {} then {}; 
    case ((VAR(varName = cr,varKind = STATE(),varDirection = a,varType = b,bindExp = c,bindValue = d,arryDim = e,startValue = f,index = g,origVarName = h,className = i,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs))
      equation 
        res = statesAsAlgebraicVars2(vs) "states treated as algebraic variables" ;
      then
        (VAR(cr,VARIABLE(),a,b,c,d,e,f,g,h,i,dae_var_attr,comment,flow_) :: res);
    case ((VAR(varName = cr,varDirection = a,varType = b,bindExp = c,bindValue = d,arryDim = e,startValue = f,index = g,origVarName = h,className = i,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs))
      equation 
        res = statesAsAlgebraicVars2(vs) "other variables treated as known" ;
      then
        (VAR(cr,CONST(),a,b,c,d,e,f,g,h,i,dae_var_attr,comment,flow_) :: res);
    case ((_ :: vs))
      equation 
        res = statesAsAlgebraicVars2(vs);
      then
        res;
  end matchcontinue;
end statesAsAlgebraicVars2;

public function varsInEqn "function: varsInEqn
  author: PA
 
  This function returns all variable indices as a list for a given
  equation, given as an equation index. (1...n)
  Negative indexes are removed.
 
  See also: eqnsForVar and eqnsForVarWithStates
  inputs:  (IncidenceMatrix, int /* equation */) 
  outputs:  int list /* variables */
"
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

protected function removeNegative "function: removeNegative
  author: PA
 
  Removes all negative integers.
"
  input list<Integer> lst;
  output list<Integer> lst_1;
  list<Value> lst_1;
algorithm 
  lst_1 := Util.listSelect(lst, Util.intPositive);
end removeNegative;

protected function eqnsForVar "function: eqnsForVar
  author: PA
 
  This function returns all equations as a list of equation indices
  given a variable as a variable index.
  See also: eqnsForVarWithStates and varsInEqn
 
  inputs:  (IncidenceMatrixT, int /* variable */) 
  outputs:  int list /* equations */
"
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

protected function eqnsForVarWithStates "function: eqnsForVarWithStates
  author: PA
 
  This function returns all equations as a list of equation indices
  given a variable as a variable index, including the equations containing 
  the state variable but not its derivative. This must be used to update 
  equations when a state is changed to algebraic variable in index reduction 
  using dummy derivatives.
  These equation indices are represented with negative index, thus all 
  indices are mapped trough int_abs (absolute value).
 
  inputs:  (IncidenceMatrixT, int /* variable */) 
  outputs:  int list /* equations */ 
"
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

protected function assignFirstUnassigned "function: assignFirstUnassigned
  author: PA
 
  This function assigns the first unassign variable to the equation
  given as first argument. It is part of the matching algorithm.
 
  inputs:  (int /* equation */,
              int list /* variables */, 
              Assignments /* ass1 */, 
              Assignments /* ass2 */) 
  outputs: (Assignments,  /* ass1 */
              Assignments)  /* ass2 */
"
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

protected function getAssigned "function: getAssigned
  author: PA
 
  returns the assigned equation for a variable.
 
  inputs:  (int		/* variable */, 
              Assignments,	/* ass1 */ 
              Assignments)	/* ass2 */ 
  outputs:  int /* equation */
"
  input Integer inInteger1;
  input Assignments inAssignments2;
  input Assignments inAssignments3;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inInteger1,inAssignments2,inAssignments3)
    local
      Value v_1,v;
      Value[:] m;
    case (v,ASSIGNMENTS(arrOfIndices = m),_)
      equation 
        v_1 = v - 1;
      then
        m[v_1 + 1];
  end matchcontinue;
end getAssigned;

protected function assign "function: assign
  author: PA
 
  Assign a variable to an equation, updating both assignment lists.
 
  inputs: (int, /* variable */
             int, /* equation */
             Assignments, /* ass1 */
             Assignments) /* ass2 */
  outputs: (Assignments,	/* updated ass1 */
              Assignments)	/* updated ass2 */ 
"
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
        v_1 = v - 1 "print \"assign \" & int_string v => vs &
	int_string e => es & print vs & print \" to eqn \" &
	print es & print \"\\n\" &" ;
        e_1 = e - 1;
        ass1_1 = assignmentsSetnth(ass1, v_1, e);
        ass2_1 = assignmentsSetnth(ass2, e_1, v);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assign;

protected function forallUnmarkedVarsInEqn "function: forallUnmarkedVarsInEqn
  author: PA
 
  This function is part of the matching algorithm. It loops over all umarked
  variables in an equation.
 
  inputs:  (IncidenceMatrix, 
              IncidenceMatrixT, 
              int, 
              Assignments /* ass1 */, 
              Assignments /* ass2 */) 
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

protected function isNotVMarked "function: isNotVMarked
  author: PA
 
  This function succeds for variables that are not marked.
"
  input Integer i;
algorithm 
  false := DAEEXT.getVMark(i);
end isNotVMarked;

protected function forallUnmarkedVarsInEqnBody "function: forallUnmarkedVarsInEqnBody
  author: PA
 
  This function is part of the matching algorithm.
  It is the body of the loop over all unmarked variables.
 
  inputs:  (IncidenceMatrix, IncidenceMatrixT,
              int,
              int list /* var list */
              Assignments 
              Assignments)  
  outputs: (Assignments, Assignments) 
"
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

public function dumpComponentsGraphStr " Dumps the assignment graph used to determine strong components to
format suitable for Mathematica"
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
  
  This is done by creating defines for each variable. For instance, #define a$pointb$pointc xd[3]
  All dots and subscripts in variable names are replaced by $point, etc.
   The equations are updated with the new variable names.
"
  input DAELow inDAELow;
  output DAELow outDAELow;
algorithm 
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<Var> varlst,knvarlst,extvarlst, varlst_1,knvarlst_1,extvarlst_1,extvarlst_2,extvarlst_3;
      list<Var> totvars,varlst_2,knvarlst_2,varlst_3,knvarlst_3;
      list<Equation> eqnsl,seqnsl,ieqnsl,eqnsl_1,seqnsl_1,ieqnsl_1,eqnsl_2,seqnsl_2,ieqnsl_2;
      list<Exp.Exp> s,t,s1,t1;
      MultiDimEquation[:] ae_1,ae_2,ae;
      Algorithm.Algorithm[:] al_1,al_2,al;
      list<WhenClause> wc_1,wc_2,wc;
      list<ZeroCrossing> zc_1,zc_2,zc;
      Variables vars_1,knvars_1,vars_2,knvars_2,vars,knvars,extVars,extvars_1,extvars_2;
      EquationArray eqns_1,seqns_1,ieqns_1,eqns,seqns,ieqns;
      DAELow trans_dae;
      ExternalObjectClasses extObjCls;
    case (DAELOW(vars,knvars,extVars, eqns,seqns,ieqns,ae,al,
      	EVENT_INFO(whenClauseLst = wc,zeroCrossingLst = zc),extObjCls))
      equation 
        varlst = varList(vars);
        knvarlst = varList(knvars);
        extvarlst = varList(extVars);
        varlst = listReverse(varlst);
        knvarlst = listReverse(knvarlst);
        extvarlst = listReverse(extvarlst);
        (varlst_1,knvarlst_1,extvarlst_1) = calculateIndexes(varlst, knvarlst,extvarlst);
        totvars = Util.listFlatten({varlst_1, knvarlst_1,extvarlst_1});
        eqnsl = equationList(eqns);
        seqnsl = equationList(seqns);
        ieqnsl = equationList(ieqns);
        (s,t) = variableReplacements(totvars, eqnsl);
        (eqnsl_1,seqnsl_1,ieqnsl_1,ae_1,al_1,wc_1,zc_1,varlst_2,knvarlst_2,extvarlst_2) 
        	= translateDaeReplace(s, t, eqnsl, seqnsl, ieqnsl, ae, al, wc, zc, varlst_1, 
          knvarlst_1,extvarlst_1, "%");
        (s1,t1) = variableReplacementsNoDollar(varlst_2, knvarlst_2,extvarlst_2) "remove dollar sign" ;
        (eqnsl_2,seqnsl_2,ieqnsl_2,ae_2,al_2,wc_2,zc_2,varlst_3,knvarlst_3,extvarlst_3) 
        	= translateDaeReplace(s1, t1, eqnsl_1, seqnsl_1, ieqnsl_1, ae_1, al_1, wc_1, 
          zc_1, varlst_2, knvarlst_2,extvarlst_2, "");
        vars_1 = emptyVars();
        knvars_1 = emptyVars();
        extvars_1 = emptyVars();
        varlst_3 = listReverse(varlst_3);
        knvarlst_3 = listReverse(knvarlst_3);
        extvarlst_3 = listReverse(extvarlst_3);
        vars_2 = addVars(varlst_3, vars_1);
        knvars_2 = addVars(knvarlst_3, knvars_1);
        extvars_2 = addVars(extvarlst_3, extvars_1);
        eqns_1 = listEquation(eqnsl_2);
        seqns_1 = listEquation(seqnsl_2);
        ieqns_1 = listEquation(ieqnsl_2);
        trans_dae = DAELOW(vars_2,knvars_2,extvars_2,eqns_1,seqns_1,ieqns_1,ae_2,al_2,
          EVENT_INFO(wc_2,zc_2),extObjCls);
        Debug.fcall("dumpindxdae", dump, trans_dae);
      then
        trans_dae;
  end matchcontinue;
end translateDae;

protected function translateDaeReplace "function: translateDaeReplace
  author: PA
 
  Helper function to translate_dae, replaces all expressions in various parts
  of the daelow,
  given a set of transformation rules.
  
  inputs:  (Exp.Exp list, /* sources */
              Exp.Exp list, /* targets */
              Equation list, /* eqns */
              Equation list, /* reqns */
              Equation list, /* ieqns */
              MultiDimEquation array, /* arreqns */
              Algorithm.Algorithm array, /*algs */
              WhenClause list, /* wc */
              ZeroCrossing list, /* zc */
              Var list, /* vars */
              Var list, /* knvars */
              string) /* variable prefix, \"$\" or \"\" */
  outputs: (Equation list, /* eqns */
              Equation list, /* reqns */
              Equation list, /* ieqns */
              MultiDimEquation array, /* arreqns */
              Algorithm.Algorithm array, /*algs */
              WhenClause list,
              ZeroCrossing list,
              Var list,
              Var list)
"
  input list<Exp.Exp> inExpExpLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Equation> inEquationLst3;
  input list<Equation> inEquationLst4;
  input list<Equation> inEquationLst5;
  input MultiDimEquation[:] inMultiDimEquationArray6;
  input Algorithm.Algorithm[:] inAlgorithmAlgorithmArray7;
  input list<WhenClause> inWhenClauseLst8;
  input list<ZeroCrossing> inZeroCrossingLst9;
  input list<Var> inVarLst10;
  input list<Var> inVarLst11;
	 input list<Var> inVarLst12;
  input String inString12;
  output list<Equation> outEquationLst1;
  output list<Equation> outEquationLst2;
  output list<Equation> outEquationLst3;
  output MultiDimEquation[:] outMultiDimEquationArray4;
  output Algorithm.Algorithm[:] outAlgorithmAlgorithmArray5;
  output list<WhenClause> outWhenClauseLst6;
  output list<ZeroCrossing> outZeroCrossingLst7;
  output list<Var> outVarLst8;
  output list<Var> outVarLst9;
    output list<Var> outVarLst10;
algorithm 
  (outEquationLst1,outEquationLst2,outEquationLst3,outMultiDimEquationArray4,outAlgorithmAlgorithmArray5,outWhenClauseLst6,outZeroCrossingLst7,outVarLst8,outVarLst9,outVarLst10):=
  matchcontinue (inExpExpLst1,inExpExpLst2,inEquationLst3,inEquationLst4,inEquationLst5,inMultiDimEquationArray6,inAlgorithmAlgorithmArray7,inWhenClauseLst8,inZeroCrossingLst9,inVarLst10,inVarLst11,inVarLst12,inString12)
    local
      list<Equation> eqnsl_1,seqnsl_1,ieqnsl_1,eqnsl,seqnsl,ieqnsl;
      MultiDimEquation[:] ae_1,ae;
      Algorithm.Algorithm[:] al_1,al;
      list<WhenClause> wc_1,wc;
      list<ZeroCrossing> zc_1,zc;
      list<Var> varlst_1,knvarlst_1,varlst,knvarlst,extvarlst,extvarlst_1;
      list<Exp.Exp> s,t;
      String var_prefix;
    case (s,t,eqnsl,seqnsl,ieqnsl,ae,al,wc,zc,varlst,knvarlst,extvarlst,var_prefix)
      equation 
        eqnsl_1 = replaceVariables(eqnsl, s, t);
        seqnsl_1 = replaceVariables(seqnsl, s, t);
        ieqnsl_1 = replaceVariables(ieqnsl, s, t);
        ae_1 = replaceVariablesInMultidimarr(ae, s, t);
        al_1 = replaceVariablesInAlg(al, s, t);
        wc_1 = replaceVariablesInWhenClauses(wc, s, t);
        zc_1 = replaceVariablesInZeroCrossings(zc, s, t);
        varlst_1 = transformVariables(varlst, s, t, var_prefix);
        knvarlst_1 = transformVariables(knvarlst, s, t, var_prefix);
        extvarlst_1 = transformVariables(extvarlst, s, t, var_prefix);
      then
        (eqnsl_1,seqnsl_1,ieqnsl_1,ae_1,al_1,wc_1,zc_1,varlst_1,knvarlst_1,extvarlst_1);
  end matchcontinue;
end translateDaeReplace;

protected function replaceVariablesInWhenClauses "function: replaceVariablesInWhenClauses
 
  Replace variables present in all the expressions in when clauses.
 
  inputs:  (WhenClause list, 
              Exp.Exp list, /* source list */ 
              Exp.Exp list) /* target list */
  outputs: WhenClause list 
"
  input list<WhenClause> inWhenClauseLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<WhenClause> outWhenClauseLst;
algorithm 
  outWhenClauseLst:=
  matchcontinue (inWhenClauseLst1,inExpExpLst2,inExpExpLst3)
    local
      WhenClause wc_1,wc;
      list<WhenClause> wcx_1,wcx;
      list<Exp.Exp> s,t;
    case ({},_,_) then {}; 
    case ((wc :: wcx),s,t)
      equation 
        wc_1 = replaceVariablesInWhenClause(wc, s, t);
        wcx_1 = replaceVariablesInWhenClauses(wcx, s, t);
      then
        (wc_1 :: wcx_1);
  end matchcontinue;
end replaceVariablesInWhenClauses;

protected function replaceVariablesInWhenClause "function: replaceVariablesInWhenClause
 
  Helper function to replace_variables_in_when_clauses.
 
  inputs:  (WhenClause, 
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs:  WhenClause =
"
  input WhenClause inWhenClause1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output WhenClause outWhenClause;
algorithm 
  outWhenClause:=
  matchcontinue (inWhenClause1,inExpExpLst2,inExpExpLst3)
    local
      Exp.Exp e_1,e;
      list<ReinitStatement> reinit_1,reinit;
      list<Exp.Exp> s,t;
      Option<Integer> elseClause_;
    case (WHEN_CLAUSE(condition = e,reinitStmtLst = reinit,elseClause=elseClause_),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
        reinit_1 = Util.listMap2(reinit, replaceVariableInReinit, s, t);
      then
        WHEN_CLAUSE(e_1,reinit_1,elseClause_);
  end matchcontinue;
end replaceVariablesInWhenClause;

protected function replaceVariableInReinit "function: replaceVariableInReinit
  Replaces varaiables in reinit statements.
 
  inputs:  (ReinitStatement,
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs: (ReinitStatement)
"
  input ReinitStatement inReinitStatement1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output ReinitStatement outReinitStatement;
algorithm 
  outReinitStatement:=
  matchcontinue (inReinitStatement1,inExpExpLst2,inExpExpLst3)
    local
      Exp.Exp e_1,e;
      Exp.ComponentRef cr_1,cr;
      list<Exp.Exp> s,t;
    case (REINIT(stateVar = cr,value = e),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
        (Exp.CREF(cr_1,_),_) = Exp.replaceExpList(Exp.CREF(cr,Exp.OTHER()), s, t);
      then
        REINIT(cr_1,e_1);
  end matchcontinue;
end replaceVariableInReinit;

protected function replaceVariablesInZeroCrossings "function: replaceVariablesInZeroCrossings
  Replaces variables in zero crossing releations
 
  inputs:  (ZeroCrossing list, 
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs: ZeroCrossing list
"
  input list<ZeroCrossing> inZeroCrossingLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<ZeroCrossing> outZeroCrossingLst;
algorithm 
  outZeroCrossingLst:=
  matchcontinue (inZeroCrossingLst1,inExpExpLst2,inExpExpLst3)
    local
      ZeroCrossing zc_1,zc;
      list<ZeroCrossing> zcx_1,zcx;
      list<Exp.Exp> s,t;
    case ({},_,_) then {}; 
    case ((zc :: zcx),s,t)
      equation 
        zc_1 = replaceVariablesInZeroCrossing(zc, s, t);
        zcx_1 = replaceVariablesInZeroCrossings(zcx, s, t);
      then
        (zc_1 :: zcx_1);
  end matchcontinue;
end replaceVariablesInZeroCrossings;

protected function replaceVariablesInZeroCrossing "function: replaceVariablesInZeroCrossing
  Replaces variables in a zero crossing releation
 
  inputs:  (ZeroCrossing, 
              Exp.Exp list, /* source list */ 
              Exp.Exp list) /* target list */
  outputs:  ZeroCrossing =
"
  input ZeroCrossing inZeroCrossing1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output ZeroCrossing outZeroCrossing;
algorithm 
  outZeroCrossing:=
  matchcontinue (inZeroCrossing1,inExpExpLst2,inExpExpLst3)
    local
      Exp.Exp e_1,e;
      list<Value> eql,wcl;
      list<Exp.Exp> s,t;
    case (ZERO_CROSSING(relation_ = e,occurEquLst = eql,occurWhenLst = wcl),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
      then
        ZERO_CROSSING(e_1,eql,wcl);
  end matchcontinue;
end replaceVariablesInZeroCrossing;

protected function replaceVariablesInMultidimarr "function: replaceVariablesInMultidimarr
  author: PA
 
  This function repalces variables in multidimensional array equations.
  See also replace_variables.
  
  inputs:  (MultiDimEquation array,
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs: MultiDimEquation array
"
  input MultiDimEquation[:] arr;
  input list<Exp.Exp> s;
  input list<Exp.Exp> t;
  output MultiDimEquation[:] arr_1;
  list<MultiDimEquation> lst,lst_1;
  MultiDimEquation[:] arr_1;
algorithm 
  lst := arrayList(arr);
  lst_1 := replaceVariablesInMultidimarr2(lst, s, t);
  arr_1 := listArray(lst_1);
end replaceVariablesInMultidimarr;

protected function replaceVariablesInMultidimarr2 "function: replaceVariablesInMultidimarr2
  author: PA
 
  Helper function to replace_variables_in_multidimarr
 
  inputs:  (MultiDimEquation list,
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs:  MultiDimEquation list 
"
  input list<MultiDimEquation> inMultiDimEquationLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<MultiDimEquation> outMultiDimEquationLst;
algorithm 
  outMultiDimEquationLst:=
  matchcontinue (inMultiDimEquationLst1,inExpExpLst2,inExpExpLst3)
    local
      Exp.Exp e1_1,e2_1,e1,e2;
      list<MultiDimEquation> es_1,es;
      list<Value> ds;
      list<Exp.Exp> s,t;
    case ({},_,_) then {}; 
    case ((MULTIDIM_EQUATION(dimSize = ds,left = e1,right = e2) :: es),s,t)
      equation 
        (e1_1,_) = Exp.replaceExpList(e1, s, t);
        (e2_1,_) = Exp.replaceExpList(e2, s, t);
        es_1 = replaceVariablesInMultidimarr2(es, s, t);
      then
        (MULTIDIM_EQUATION(ds,e1_1,e2_1) :: es_1);
  end matchcontinue;
end replaceVariablesInMultidimarr2;

protected function replaceVariablesInAlg "function: replaceVariablesInAlg
  author: PA
 
  This function replaces variabless in algorithms.
  See also replace_variables.
 
  inputs:  (Algorithm.Algorithm array, 
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs: (Algorithm.Algorithm array) 
"
  input Algorithm.Algorithm[:] inAlgorithmAlgorithmArray1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output Algorithm.Algorithm[:] outAlgorithmAlgorithmArray;
algorithm 
  outAlgorithmAlgorithmArray:=
  matchcontinue (inAlgorithmAlgorithmArray1,inExpExpLst2,inExpExpLst3)
    local
      list<Algorithm.Algorithm> alglst,alglst_1;
      Algorithm.Algorithm[:] algarr_1,algarr;
      list<Exp.Exp> s,t;
    case (algarr,s,t)
      equation 
        alglst = arrayList(algarr);
        alglst_1 = replaceVariablesInAlg2(alglst, s, t);
        algarr_1 = listArray(alglst_1);
      then
        algarr_1;
    case (_,_,_)
      equation 
        print("-replace_variables_in_alg failed\n");
      then
        fail();
  end matchcontinue;
end replaceVariablesInAlg;

protected function replaceVariablesInAlg2 "function: replaceVariablesInAlg2
  author: PA
 
  Helper function to replace_variables_in_alg.
 
  inputs:  (Algorithm.Algorithm list, 
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs:  Algorithm.Algorithm list 
"
  input list<Algorithm.Algorithm> inAlgorithmAlgorithmLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<Algorithm.Algorithm> outAlgorithmAlgorithmLst;
algorithm 
  outAlgorithmAlgorithmLst:=
  matchcontinue (inAlgorithmAlgorithmLst1,inExpExpLst2,inExpExpLst3)
    local
      list<Algorithm.Algorithm> algs_1,algs;
      list<Algorithm.Statement> stmts_1,stmts;
      list<Exp.Exp> s,t;
    case ({},_,_) then {}; 
    case ((Algorithm.ALGORITHM(statementLst = stmts) :: algs),s,t)
      equation 
        algs_1 = replaceVariablesInAlg2(algs, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        (Algorithm.ALGORITHM(stmts_1) :: algs_1);
  end matchcontinue;
end replaceVariablesInAlg2;

protected function replaceVariablesInStmts "function: replaceVariablesInStmts
  author: PA
 
  Helper function to replace_variables_in_alg2
  Traverses a list of statements.
  inputs:  (Algorithm.Statement list, 
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */
  outputs:  Algorithm.Statement list 
"
  input list<Algorithm.Statement> inAlgorithmStatementLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<Algorithm.Statement> outAlgorithmStatementLst;
algorithm 
  outAlgorithmStatementLst:=
  matchcontinue (inAlgorithmStatementLst1,inExpExpLst2,inExpExpLst3)
    local
      Algorithm.Statement stmt_1,stmt;
      list<Algorithm.Statement> stmts_1,stmts;
      list<Exp.Exp> s,t;
    case ({},_,_) then {}; 
    case ((stmt :: stmts),s,t)
      equation 
        stmt_1 = replaceVariablesInStmt(stmt, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        (stmt_1 :: stmts_1);
  end matchcontinue;
end replaceVariablesInStmts;

protected function replaceVariablesInStmt "function: replaceVariablesInStmt
  author: PA
 
  Helper function to replace_variables_in_stmts
  Investigates a single statement.
  
  inputs:  (Algorithm.Statement,
              Exp.Exp list, /* source list */
              Exp.Exp list) /* target list */				   
  outputs:  Algorithm.Statement 
"
  input Algorithm.Statement inStatement1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output Algorithm.Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inStatement1,inExpExpLst2,inExpExpLst3)
    local
      Exp.Exp e_1,e,exp_1,exp,e1_1,e2_1,e1,e2;
      Exp.ComponentRef cr_1,cr;
      Exp.Type tp;
      list<Exp.Exp> s,t,expl_1,expl;
      list<Value> cnt;
      list<Algorithm.Statement> stmts_1,stmts;
      Algorithm.Else else_branch_1,else_branch;
      Boolean b;
      String id;
      Algorithm.Statement a, stmt1, stmt;
      list<Integer> helpVarLst;
    case (Algorithm.ASSIGN(type_ = tp,componentRef = cr,exp = e),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
        (Exp.CREF(cr_1,_),_) = Exp.replaceExpList(Exp.CREF(cr,Exp.OTHER()), s, t);
      then
        Algorithm.ASSIGN(tp,cr_1,e_1);
    case (Algorithm.TUPLE_ASSIGN(type_ = tp,expExpLst = expl,exp = exp),s,t)
      equation 
        expl_1 = Util.listMap22(expl, Exp.replaceExpList, s, t);
        (expl_1,cnt) = Util.splitTuple2List(expl_1);
        (exp_1,_) = Exp.replaceExpList(exp, s, t);
      then
        Algorithm.TUPLE_ASSIGN(tp,expl_1,exp_1);
    case (Algorithm.ASSIGN_ARR(type_ = tp,componentRef = cr,exp = e),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
      then
        Algorithm.ASSIGN_ARR(tp,cr,e);
    case (Algorithm.IF(exp = e,statementLst = stmts,else_ = else_branch),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
        else_branch_1 = replaceVariablesInElseBranch(else_branch, s, t);
      then
        Algorithm.IF(e_1,stmts_1,else_branch_1);
    case (Algorithm.FOR(type_ = tp,boolean = b,ident = id,exp = e,statementLst = stmts),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        Algorithm.FOR(tp,b,id,e_1,stmts_1);
    case (Algorithm.WHILE(exp = e,statementLst = stmts),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        Algorithm.WHILE(e_1,stmts_1);
    case (Algorithm.WHEN(exp = e,statementLst = stmts,elseWhen = NONE,helpVarIndices=helpVarLst),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        Algorithm.WHEN(e_1,stmts_1,NONE,helpVarLst);
    case (Algorithm.WHEN(exp = e,statementLst = stmts,elseWhen = SOME(stmt),helpVarIndices=helpVarLst),s,t)
      equation 
        stmt1 = replaceVariablesInStmt(stmt,s,t);
        (e_1,_) = Exp.replaceExpList(e, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        Algorithm.WHEN(e_1,stmts_1,SOME(stmt1),helpVarLst);
    case (Algorithm.ASSERT(cond = e1,msg = e2),s,t)
      equation 
        (e1_1,_) = Exp.replaceExpList(e1, s, t);
        (e2_1,_) = Exp.replaceExpList(e2, s, t);
      then
        Algorithm.ASSERT(e1_1,e2_1);
    case (a,_,_)
      equation 
        print("Warning, fallthrough in replace_variables_in_stmts\n");
      then
        a;
  end matchcontinue;
end replaceVariablesInStmt;

protected function replaceVariablesInElseBranch "function: replaceVariablesInElseBranch
  author: PA
 
  Helper function to replace_varibels_in_stmt
  Investigates the else branch of if statements.
 
  inputs: (Algorithm.Else,
             Exp.Exp list, /* source list */
             Exp.Exp list) /* target list */
  outputs: Algorithm.Else 
"
  input Algorithm.Else inElse1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output Algorithm.Else outElse;
algorithm 
  outElse:=
  matchcontinue (inElse1,inExpExpLst2,inExpExpLst3)
    local
      Algorithm.Else else_branch_1,else_branch;
      Exp.Exp e_1,e;
      list<Algorithm.Statement> stmts_1,stmts;
      list<Exp.Exp> s,t;
    case (Algorithm.NOELSE(),_,_) then Algorithm.NOELSE(); 
    case (Algorithm.ELSEIF(exp = e,statementLst = stmts,else_ = else_branch),s,t)
      equation 
        else_branch_1 = replaceVariablesInElseBranch(else_branch, s, t);
        (e_1,_) = Exp.replaceExpList(e, s, t);
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        Algorithm.ELSEIF(e_1,stmts_1,else_branch_1);
    case (Algorithm.ELSE(statementLst = stmts),s,t)
      equation 
        stmts_1 = replaceVariablesInStmts(stmts, s, t);
      then
        Algorithm.ELSE(stmts_1);
  end matchcontinue;
end replaceVariablesInElseBranch;

protected function addVars "function: addVars
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
  
  inputs:  (Exp.Exp, Variables /* variables of the eqn sys. */)
  outputs:  Exp.Exp =
"
  input Exp.Exp inExp;
  input Variables inVariables;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp,inVariables)
    local
      list<Exp.Exp> term_lst,rhs_lst;
      Exp.Exp new_exp,res,exp;
      Variables vars;
    case (exp,vars)
      equation 
        term_lst = Exp.allTerms(exp);
        rhs_lst = Util.listSelect1(term_lst, vars, freeFromAnyVar);
        new_exp = Exp.makeSum(rhs_lst);
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
 
  Helper function to rhs_constant, traverses equation list.
"
  input list<Equation> inEquationLst;
  input DAELow inDAELow;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inEquationLst,inDAELow)
    local
      Exp.Type tp;
      Exp.Exp new_exp,rhs_exp,e1,e2,e;
      Boolean res;
      list<Equation> rest;
      DAELow dae;
      Variables vars;
      Value indx_1,indx;
      list<Value> ds;
      list<Exp.Exp> expl;
      MultiDimEquation[:] arreqn;
    case ({},_) then true; 
    case ((EQUATION(exp = e1,scalar = e2) :: rest),(dae as DAELOW(orderedVars = vars))) /* check rhs for for EQUATION nodes. */ 
      equation 
        tp = Exp.typeof(e1);
        new_exp = Exp.BINARY(e1,Exp.SUB(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        true = Exp.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;
    case ((ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: rest),(dae as DAELOW(orderedVars = vars,arrayEqs = arreqn))) /* check rhs for for ARRAY_EQUATION nodes. check rhs for for RESIDUAL_EQUATION nodes. */ 
      equation 
        indx_1 = indx - 1;
        MULTIDIM_EQUATION(ds,e1,e2) = arreqn[indx + 1];
        tp = Exp.typeof(e1);
        new_exp = Exp.BINARY(e1,Exp.SUB(tp),e2) "NOTE: illegal to use SUB for arrays, but we only need to 
	  check if constant or not, expr not saved.." ;
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
 
  Helper function to rhs_constant2
  returns true if expression does not contain any of the variables
  passed as argument.
"
  input Exp.Exp inExp;
  input Variables inVariables;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp,inVariables)
    local
      Exp.Exp e;
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
  
  Returns the jacobian type as a string, used for debugging.
"
  input JacobianType inJacobianType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inJacobianType)
    case JAC_CONSTANT() then "Jacobian Constant"; 
    case JAC_TIME_VARYING() then "Jacobian Time varying"; 
    case JAC_NONLINEAR() then "Jacobian Nonlinear"; 
    case JAC_NO_ANALYTIC() then "No analythic jacobian";
  end matchcontinue;
end jacobianTypeStr;

protected function jacobianConstant "function: jacobianConstant
  author: PA
 
  Checks if jacobian is constant, i.e. all expressions in each equation are constant.
"
  input list<tuple<Integer, Integer, Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inTplIntegerIntegerEquationLst)
    local
      Exp.Exp e1,e2,e;
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
  TODO: Algorithms and Array equations
"
  input DAELow inDAELow;
  input list<tuple<Integer, Integer, Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inDAELow,inTplIntegerIntegerEquationLst)
    local
      DAELow daelow;
      Exp.Exp e1,e2,e;
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
  This is true if the jacobian contains any of the variables that is solved
  for.
"
  input DAELow inDAELow;
  input Exp.Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inDAELow,inExp)
    local
      list<Key> crefs;
      Boolean res;
      Variables vars;
      Exp.Exp e;
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
 
  Returns true if any of the variables given as ComponentRef list is among 
  the Variables.
"
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input Variables inVariables;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExpComponentRefLst,inVariables)
    local
      Exp.ComponentRef cr;
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
  and calculates the jacobian of the equations.
"
  input Variables inVariables;
  input EquationArray inEquationArray;
  input MultiDimEquation[:] inMultiDimEquationArray;
  input IncidenceMatrix inIncidenceMatrix;
  input IncidenceMatrixT inIncidenceMatrixT;
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm 
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inVariables,inEquationArray,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<Equation> eqn_lst,eqn_lst_1;
      list<tuple<Value, Value, Equation>> jac,jac_1;
      Variables vars;
      EquationArray eqns;
      MultiDimEquation[:] ae;
      list<Value>[:] m,mt;
    case (vars,eqns,ae,m,mt)
      equation 
        eqn_lst = equationList(eqns);
        eqn_lst_1 = Util.listMap(eqn_lst, equationToResidualForm);
        SOME(jac) = calculateJacobianRows(eqn_lst_1, vars, ae, m, mt);
        jac_1 = listReverse(jac);
      then
        SOME(jac_1);
    case (_,_,_,_,_) then NONE;  /* no analythic jacobian available */ 
  end matchcontinue;
end calculateJacobian;

protected function calculateJacobianRows "function: calculateJacobianRows
  author: PA
 
  This function takes a list of Equations and a set of variables and 
  calculates the jacobian expression for each variable over each equations,
  returned in a sparse matrix representation. 
  For example, the equation on index e1: 3ax+5yz+ zz  given the 
  variables {x,y,z} on index x1,y1,z1 gives
  {(e1,x1,3a), (e1,y1,5z), (e1,z1,5y+2z)}
"
  input list<Equation> eqns;
  input Variables vars;
  input MultiDimEquation[:] ae;
  input IncidenceMatrix m;
  input IncidenceMatrixT mt;
  output Option<list<tuple<Integer, Integer, Equation>>> res;
algorithm 
  res := calculateJacobianRows2(eqns, vars, ae, m, mt, 1);
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
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm 
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inEquationLst,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger)
    local
      Value eqn_indx_1,eqn_indx;
      list<tuple<Value, Value, Equation>> l1,l2,res;
      Equation eqn;
      list<Equation> eqns;
      Variables vars;
      MultiDimEquation[:] ae;
      list<Value>[:] m,mt;
    case ({},_,_,_,_,_) then SOME({}); 
    case ((eqn :: eqns),vars,ae,m,mt,eqn_indx)
      equation 
        eqn_indx_1 = eqn_indx + 1;
        SOME(l1) = calculateJacobianRows2(eqns, vars, ae, m, mt, eqn_indx_1);
        SOME(l2) = calculateJacobianRow(eqn, vars, ae, m, mt, eqn_indx);
        res = listAppend(l1, l2);
      then
        SOME(res);
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
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm 
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inEquation,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger)
    local
      list<Value> var_indxs,var_indxs_1,var_indxs_2,ds;
      list<tuple<Value, Value, Equation>> eqns;
      Exp.Exp e,e1,e2,new_exp;
      Variables vars;
      MultiDimEquation[:] ae;
      list<Value>[:] m,mt;
      Value eqn_indx,indx;
      list<Exp.Exp> in_,out,expl;
    case (RESIDUAL_EQUATION(exp = e),vars,ae,m,mt,eqn_indx)
      equation 
        var_indxs = varsInEqn(m, eqn_indx) "residual equations" ;
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: acsending index" ;
        var_indxs_2 = listReverse(var_indxs_1);
        SOME(eqns) = calculateJacobianRow2(e, vars, eqn_indx, var_indxs_2);
      then
        SOME(eqns);
    case (ALGORITHM(index = indx,in_ = in_,out = out),vars,ae,m,mt,eqn_indx) then NONE;  /* algorithms give no jacobian */ 
    case (ARRAY_EQUATION(index = indx,crefOrDerCref = expl),vars,ae,m,mt,eqn_indx) /* array equations */ 
      equation 
        MULTIDIM_EQUATION(ds,e1,e2) = ae[indx + 1];
        new_exp = Exp.BINARY(e1,Exp.SUB(Exp.REAL()),e2);
        var_indxs = varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: acsending index" ;
        var_indxs_2 = listReverse(var_indxs_1);
        SOME(eqns) = calculateJacobianRow2(new_exp, vars, eqn_indx, var_indxs_2);
      then
        SOME(eqns);
  end matchcontinue;
end calculateJacobianRow;

protected function makeResidualEqn "function: makeResidualEqn
  author: PA
 
  Transforms an expression into a residual equation
"
  input Exp.Exp inExp;
  output Equation outEquation;
algorithm 
  outEquation:=
  matchcontinue (inExp)
    local Exp.Exp e;
    case (e) then RESIDUAL_EQUATION(e); 
  end matchcontinue;
end makeResidualEqn;

protected function calculateJacobianRow2 "function: calculateJacobianRow2
  author: PA
 
  Helper function to calculate_jacobian_row
  Differentiates expression for each variable cref.
 
  inputs: (Exp.Exp, 
             Variables,
             int, /* equation index */
             int list) /* var indexes */
  outputs: ((int int Equation) list option)
"
  input Exp.Exp inExp;
  input Variables inVariables;
  input Integer inInteger;
  input list<Integer> inIntegerLst;
  output Option<list<tuple<Integer, Integer, Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm 
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inExp,inVariables,inInteger,inIntegerLst)
    local
      Exp.Exp e,e_1,e_2;
      Var v;
      Exp.ComponentRef cr;
      list<tuple<Value, Value, Equation>> es;
      Variables vars;
      Value eqn_indx,vindx;
      list<Value> vindxs;
    case (e,_,_,{}) then SOME({}); 
    case (e,vars,eqn_indx,(vindx :: vindxs))
      equation 
        v = getVarAt(vars, vindx);
        cr = varCref(v);
        e_1 = Derive.differentiateExp(e, cr);
        e_2 = Exp.simplify(e_1);
        SOME(es) = calculateJacobianRow2(e, vars, eqn_indx, vindxs);
      then
        SOME(((eqn_indx,vindx,RESIDUAL_EQUATION(e_2)) :: es));
  end matchcontinue;
end calculateJacobianRow2;

public function residualExp "function: residualExp
  author: PA
 
  This function extracts the residual expression from a residual equation
"
  input Equation inEquation;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inEquation)
    local Exp.Exp e;
    case (RESIDUAL_EQUATION(exp = e)) then e; 
  end matchcontinue;
end residualExp;

public function toResidualForm "function: toResidualForm
  author: PA
 
  This function transforms a daelow to residualform on the equations.
"
  input DAELow inDAELow;
  output DAELow outDAELow;
algorithm 
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<Equation> eqn_lst,eqn_lst2;
      EquationArray eqns2,eqns,seqns,ieqns;
      Variables vars,knvars,extVars;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] ialg;
      EventInfo wc;
      ExternalObjectClasses extobjcls;
    case (DAELOW(vars,knvars,extVars,eqns,seqns,ieqns,ae,ialg,wc,extobjcls))
      equation 
        eqn_lst = equationList(eqns);
        eqn_lst2 = Util.listMap(eqn_lst, equationToResidualForm);
        eqns2 = listEquation(eqn_lst2);
      then
        DAELOW(vars,knvars,extVars,eqns2,seqns,ieqns,ae,ialg,wc,extobjcls);
  end matchcontinue;
end toResidualForm;

public function equationToResidualForm "function: equationToResidualForm
  author: PA
 
  This function transforms an equation to its residual form.
  For instance, a=b is transformed to a-b=0 
"
  input Equation inEquation;
  output Equation outEquation;
algorithm 
  outEquation:=
  matchcontinue (inEquation)
    local
      Exp.Exp e,e1,e2,exp;
      Exp.ComponentRef cr;
      Exp.Type tp;
    case (EQUATION(exp = e1,scalar = e2))
      equation 
         //Exp.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        tp = Exp.typeof(e2);
        e = Exp.simplify(Exp.BINARY(e1,Exp.SUB(tp),e2));
      then
        RESIDUAL_EQUATION(e);
    case (SOLVED_EQUATION(componentRef = cr,exp = exp))
      equation 
         //Exp.dumpExpWithTitle("equationToResidualForm 2\n",exp);
        tp = Exp.typeof(exp);
        e = Exp.simplify(Exp.BINARY(Exp.CREF(cr,tp),Exp.SUB(tp),exp));
      then
        RESIDUAL_EQUATION(e);
    case ((e as RESIDUAL_EQUATION(exp = _)))
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
        Debug.fprint("failtrace", "equation_to_residual_form failed\n");
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
  output Integer outnext " number of external objects";
  
//nx cannot be strings
  output Integer outny_string "number of alg.vars which are strings";
  output Integer outnp_string  "number of parameters which are strings";
algorithm 
  (outnx,outny,outnp,outng,outnext):=
  matchcontinue (inDAELow)
    local
      list<Var> varlst,knvarlst,extvarlst;
      Value np,ng,nx,ny,nx_1,ny_1,next,ny_string,np_string,ny_1_string;
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
        ng = listLength(zc);
        (nx,ny,ny_string) = calculateVarSizes(varlst, 0, 0,0);
        (nx_1,ny_1,ny_1_string) = calculateVarSizes(knvarlst, nx, ny,ny_string);
      then
        (nx_1,ny_1,np,ng,next,ny_1_string,np_string);
  end matchcontinue;
end calculateSizes;

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
      DAE.Flow flow_;
      list<Var> vs;
    case ({},nx,ny,ny_string) then (nx,ny,ny_string); 
    case ((VAR(varKind = VARIABLE(),varType= DAE.STRING(),flow_ = flow_) :: vs),nx,ny,ny_string)
      equation 
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny, ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
    case ((VAR(varKind = VARIABLE(),flow_ = flow_) :: vs),nx,ny,ny_string)
      equation 
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny_1,ny_string);
      then
        (nx_2,ny_2,ny_2_string);


     case ((VAR(varKind = DISCRETE(),varType= DAE.STRING(),flow_ = flow_) :: vs),nx,ny,ny_string)
      equation 
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny,ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
     case ((VAR(varKind = DISCRETE(),flow_ = flow_) :: vs),nx,ny,ny_string)
      equation 
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny_1,ny_string);
      then
        (nx_2,ny_2,ny_2_string);

    case ((VAR(varKind = STATE(),flow_ = flow_) :: vs),nx,ny,ny_string)
      equation 
        nx_1 = nx + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx_1, ny,ny_string);
      then
        (nx_2,ny_2,ny_2_string);

    case ((VAR(varKind = DUMMY_STATE(),varType= DAE.STRING(),flow_ = flow_) :: vs),nx,ny,ny_string) /* A dummy state is an algebraic variable */ 
      equation 
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny,ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
    case ((VAR(varKind = DUMMY_STATE(),flow_ = flow_) :: vs),nx,ny,ny_string) /* A dummy state is an algebraic variable */ 
      equation 
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny_1,ny_string);
      then
        (nx_2,ny_2,ny_2_string);

    case ((VAR(varKind = DUMMY_DER(),varType= DAE.STRING(),flow_ = flow_) :: vs),nx,ny,ny_string)
      equation 
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string) = calculateVarSizes(vs, nx, ny,ny_1_string);
      then
        (nx_2,ny_2,ny_2_string);
    case ((VAR(varKind = DUMMY_DER(),flow_ = flow_) :: vs),nx,ny,ny_string)
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
        print("-calculate_var_sizes failed\n");
      then
        fail();
  end matchcontinue;
end calculateVarSizes;

protected function replaceVariables "function: replaceVariables
  author: PA
 
  Transforms the equations (incl. algorithms and array eqns), 
  given two lists with source and target expressions
 
  inputs:  (Equation list, /* equations   */
              Exp.Exp list,  /* source list */
              Exp.Exp list)  /* target list */
  outputs: Equation list =
"
  input list<Equation> inEquationLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<Equation> outEquationLst;
algorithm 
  outEquationLst:=
  matchcontinue (inEquationLst1,inExpExpLst2,inExpExpLst3)
    local
      Exp.Exp e1_1,e2_1,e1,e2;
      list<Equation> es_1,es;
      list<Exp.Exp> s,t,inputs,outputs,expl;
      Exp.ComponentRef cr_1,cr;
      Value i,indx;
      WhenEquation elsePartRes;
      WhenEquation elsePart;
    case ({},_,_) then {}; 
    case ((EQUATION(exp = e1,scalar = e2) :: es),s,t)
      equation 
        (e1_1,_) = Exp.replaceExpList(e1, s, t);
        (e2_1,_) = Exp.replaceExpList(e2, s, t);
        es_1 = replaceVariables(es, s, t);
      then
        (EQUATION(e1_1,e2_1) :: es_1);
    case ((SOLVED_EQUATION(componentRef = cr,exp = e1) :: es),s,t)
      equation 
        (Exp.CREF(cr_1,_),_) = Exp.replaceExpList(Exp.CREF(cr,Exp.OTHER()), s, t);
        (e1_1,_) = Exp.replaceExpList(e1, s, t);
        es_1 = replaceVariables(es, s, t);
      then
        (SOLVED_EQUATION(cr_1,e1_1) :: es_1);
    case ((WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = NONE)) :: es),s,t)
      equation 
        e1 = Exp.CREF(cr,Exp.OTHER());
        ((e1_1 as Exp.CREF(cr_1,_)),_) = Exp.replaceExpList(e1, s, t);
        (e2_1,_) = Exp.replaceExpList(e2, s, t);
        es_1 = replaceVariables(es, s, t);
      then
        (WHEN_EQUATION(WHEN_EQ(i,cr_1,e2_1,NONE)) :: es_1);

    case ((WHEN_EQUATION(whenEquation = WHEN_EQ(index = i,left = cr,right = e2, elsewhenPart = SOME(elsePart))) :: es),s,t)
      equation 
        WHEN_EQUATION(elsePartRes) = Util.listFirst(replaceVariables({WHEN_EQUATION(elsePart)},s,t));
        e1 = Exp.CREF(cr,Exp.OTHER());
        ((e1_1 as Exp.CREF(cr_1,_)),_) = Exp.replaceExpList(e1, s, t);
        (e2_1,_) = Exp.replaceExpList(e2, s, t);
        es_1 = replaceVariables(es, s, t);
      then
        (WHEN_EQUATION(WHEN_EQ(i,cr_1,e2_1,SOME(elsePartRes))) :: es_1);
        
        /* algorithms are replaced also in translateDaeReplace */         
    case ((ALGORITHM(index = indx,in_ = inputs,out = outputs) :: es),s,t) 
      equation 
        inputs = Util.listMap(Util.listMap22(inputs,Exp.replaceExpList,s,t),Util.tuple21);          
        outputs = Util.listMap(Util.listMap22(outputs,Exp.replaceExpList,s,t),Util.tuple21);
        es_1 = replaceVariables(es, s, t);
      then
        (ALGORITHM(indx,inputs,outputs) :: es_1);
        
        /* array eqns are also replaced in translateDaeReplace */ 
    case ((ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: es),s,t) 
      equation 
        expl = Util.listMap(Util.listMap22(expl,Exp.replaceExpList,s,t),Util.tuple21);
        es_1 = replaceVariables(es, s, t);
      then
        (ARRAY_EQUATION(indx,expl) :: es_1);
    case (_,_,_)
      equation 
        print("-replaceVariables failed\n");
      then
        fail();
  end matchcontinue;
end replaceVariables;

public function calculateValues "function: calculateValues
  author: PA
 
  This function calculates the values from the parameter binding expressions.
  This is performed by building an environment and adding all the parameters
  and constants to it and then calling ceval to retreive the constant values
  of each parameter or constant.
  NOTE: This depends on the DAELow having the indexed forms of component
  references, since the environment requires simple names for each variable.
 
"
  input DAELow inDAELow;
  output DAELow outDAELow;
algorithm 
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<Env.Frame> env,env_1;
      list<Var> knvarlst,knvarlst_1;
      Variables knvars,knvars_1,vars,extVars;
      EquationArray eqns,seqns,ie;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      EventInfo wc;
      ExternalObjectClasses extObjCls;
    case (DAELOW(orderedVars = vars,knownVars = knvars,externalObjects=extVars,orderedEqs = eqns,
      removedEqs = seqns,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = wc,extObjClasses=extObjCls))
      equation 
        (_,env) = Builtin.initialEnv(Env.emptyCache);
        knvarlst = varList(knvars);
        env_1 = addVariablesToEnv(knvarlst, env);
        knvarlst_1 = updateVariables(knvarlst, env_1);
        knvars = emptyVars();
        knvars_1 = addVars(knvarlst_1, knvars);
      then
        DAELOW(vars,knvars_1,extVars,eqns,seqns,ie,ae,al,wc,extObjCls);
  end matchcontinue;
end calculateValues;

protected function addVariablesToEnv "function: addVariablesToEnv
  author: PA
 
  Helper function to calculate_values
"
  input list<Var> inVarLst;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inVarLst,inEnv)
    local
      list<Env.Frame> env,env_1,env_2;
      tuple<Types.TType, Option<Absyn.Path>> t_1;
      String crn;
      VarKind a;
      DAE.VarDirection b;
      DAE.Type t;
      Exp.Exp e;
      list<Exp.Subscript> d;
      Option<Exp.Exp> f;
      Value g;
      Exp.ComponentRef h,cr;
      list<Absyn.Path> i;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Var> rest;
    case ({},env) then env; 
    case ((VAR(varName = Exp.CREF_IDENT(ident = crn),varKind = a,varDirection = b,varType = t,bindExp = SOME(e),arryDim = d,startValue = f,index = g,origVarName = h,className = i,values = dae_var_attr,comment = comment,flow_ = flow_) :: rest),env)
      equation 
        t_1 = DAE.generateDaeType(t) "Some of the attributes added to env here does not matter, defaults are used" ;
        env_1 = Env.extendFrameV(env, 
          Types.VAR(crn,
          Types.ATTR(false,SCode.RW(),SCode.CONST(),Absyn.BIDIR()),false,t_1,Types.EQBOUND(e,NONE,Types.C_CONST())), NONE, Env.VAR_UNTYPED(), {});
        env_2 = addVariablesToEnv(rest, env_1);
      then
        env_2;
    case ((VAR(varName = Exp.CREF_IDENT(ident = crn),varKind = a,varDirection = b,varType = t,bindExp = NONE,arryDim = d,startValue = f,index = g,origVarName = h,className = i,values = dae_var_attr,comment = comment,flow_ = flow_) :: rest),env)
      equation 
        t_1 = DAE.generateDaeType(t) "Some of the attributes added to env here does not matter, defaults are used" ;
        env_1 = Env.extendFrameV(env, 
          Types.VAR(crn,
          Types.ATTR(false,SCode.RW(),SCode.CONST(),Absyn.BIDIR()),false,t_1,Types.UNBOUND()), NONE, Env.VAR_UNTYPED(), {});
        env_2 = addVariablesToEnv(rest, env_1);
      then
        env_2;
    case ((VAR(varName = (cr as Exp.CREF_QUAL(ident = _)),flow_ = flow_) :: rest),env)
      equation 
        Print.printBuf("Warning, skipping a variable qualified:");
        Exp.printComponentRef(cr);
        env_1 = addVariablesToEnv(rest, env);
      then
        env_1;
    case ((_ :: rest),env)
      equation 
        Print.printBuf("Warning, skipping a variable :");
        env_1 = addVariablesToEnv(rest, env);
      then
        env_1;
  end matchcontinue;
end addVariablesToEnv;

protected function updateVariables "function: updateVariables
  author: PA
 
  Helper function to calculate_values
"
  input list<Var> inVarLst;
  input Env.Env inEnv;
  output list<Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVarLst,inEnv)
    local
      list<Var> rest_1,rest;
      Values.Value v;
      Exp.ComponentRef cr,h;
      VarKind a;
      DAE.VarDirection b;
      DAE.Type c;
      Exp.Exp e;
      list<Exp.Subscript> d;
      Option<Exp.Exp> f;
      Value g;
      list<Absyn.Path> i;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Env.Frame> env;
    case ({},_) then {}; 
    case ((VAR(varName = cr,varKind = a,varDirection = b,varType = c,bindExp = SOME(e),arryDim = d,startValue = f,index = g,origVarName = h,className = i,values = dae_var_attr,comment = comment,flow_ = flow_) :: rest),env)
      equation 
        rest_1 = updateVariables(rest, env);
        (_,v,_) = Ceval.ceval(Env.emptyCache,env, e, false, NONE, NONE, Ceval.MSG());
      then
        (VAR(cr,a,b,c,SOME(e),SOME(v),d,f,g,h,i,dae_var_attr,comment,
          flow_) :: rest_1);
    case ((VAR(varName = cr,varKind = a,varDirection = b,varType = c,bindExp = SOME(e),bindValue = v,arryDim = d,startValue = f,index = g,origVarName = h,className = i,values = dae_var_attr,comment = comment,flow_ = flow_) :: rest),env)
      local Option<Values.Value> v;
      equation 
        rest_1 = updateVariables(rest, env);
        failure((_,_,_) = Ceval.ceval(Env.emptyCache,env, e, false, NONE, NONE, Ceval.NO_MSG()));
        Print.printBuf("Warning, ceval failed for parameter: ");
        Exp.printComponentRef(cr);
        Print.printBuf("\n");
      then
        (VAR(cr,a,b,c,SOME(e),v,d,f,g,h,i,dae_var_attr,comment,flow_) :: rest_1);
    case ((VAR(varName = cr,varKind = a,varDirection = b,varType = c,bindExp = NONE,bindValue = v,arryDim = d,startValue = f,index = g,origVarName = h,className = i,values = dae_var_attr,comment = comment,flow_ = flow_) :: rest),env)
      local Option<Values.Value> v;
      equation 
        rest_1 = updateVariables(rest, env);
      then
        (VAR(cr,a,b,c,NONE,v,d,f,g,h,i,dae_var_attr,comment,flow_) :: rest_1);
  end matchcontinue;
end updateVariables;

protected function variableReplacements "function: variableReplacements
  author: PA
 
  Returns a two list of replacement expressions for variable transformations.
  For instance, replacing state s with %x[3] and der(s) with %xd[3],
  NOTE: The derivative expressions must be first, so they are replaced first
  i.e der(s) is replaced before s is replaced which gives a wrong 
  variable like der(%x[5])
"
  input list<Var> inVarLst;
  input list<Equation> inEquationLst;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inVarLst,inEquationLst)
    local
      BinTree bt;
      list<Key> states;
      list<Exp.Exp> s1,t1,s2,t2,s3,t3,s,t;
      list<String> ss;
      String str;
      list<Var> vars;
      list<Equation> eqns;
    case (vars,eqns)
      equation 
        bt = statesEqns(eqns, emptyBintree);
        (states,_) = bintreeToList(bt);
        (s1,t1) = derivativeReplacements(states);
        (s2,t2) = algVariableReplacements(vars);
        (s3,t3) = algVariableArrayReplacements(vars);
        s = Util.listFlatten({s1,s2,s3});
        t = Util.listFlatten({t1,t2,t3});
      then
        (s,t);
    case (vars,eqns)
      equation 
        print("-variableReplacements failed\n");
      then
        fail();
  end matchcontinue;
end variableReplacements;

protected function variableReplacementsNoDollar "function: variableReplacementsNoDollar
  author: PA
 
  When all variables have been replaced to a indexed variable starting
  with a dollar sig, \'%\', it can again be translated to remove the sign.
  This function builds replacement rules for removing the sign.
"
  input list<Var> inVarLst1;
  input list<Var> inVarLst2;
  input list<Var> inVarLst3;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inVarLst1,inVarLst2,inVarLst3)
    local
      list<Exp.Exp> s1,t1,s2,t2,s,t,s3,t3;
      list<Var> vars,knvars,extvars;
    case (vars,knvars,extvars)
      equation 
        (s1,t1) = variableReplacementsRemoveDollar(vars);
        (s2,t2) = variableReplacementsRemoveDollar(knvars);
        (s3,t3) = variableReplacementsRemoveDollar(extvars);
        s = Util.listFlatten({s1,s2,s3});
        t = Util.listFlatten({t1,t2,t3});
      then
        (s,t);
    case (vars,knvars,extvars)
      equation 
        print("-variableReplacementsNoDollar failed\n");
      then
        fail();
  end matchcontinue;
end variableReplacementsNoDollar;

protected function variableReplacementsRemoveDollar "function: variableReplacementsRemoveDollar
  author: PA
 
  Removes the prefixed dollar sign on each variable, returning a list 
  of replacements rules.
"
  input list<Var> inVarLst;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inVarLst)
    local
      list<Exp.Exp> s,t;
      list<String> rest;
      String name,xd_t,xd_s,str,str_1;
      Exp.ComponentRef cr;
      list<Var> vs;
      Exp.Type etp;
      DAE.Type tp;
    case ({}) then ({},{}); 
    case ((VAR(varName = (cr as Exp.CREF_IDENT(ident = str,subscriptLst = {})),varType=tp,varKind = STATE()) :: vs)) /* Special case for states, add %xd{indx} too . */ 
      equation 
        (s,t) = variableReplacementsRemoveDollar(vs);
        etp = makeExpType(tp);        
        ("%" :: rest) = string_list_string_char(str) "print str & print \"<++++++++++++\\n\" & #\"x\"::" ;
        name = string_char_list_string(rest);
        xd_t = stringAppend(derivativeNamePrefix, name) "print name & print \"<++++++++++++\\n\" & 	string_append(\"x\",str\') => str\'\' &" ;
        xd_s = stringAppend("%derivative", name);
      then
        ((Exp.CREF(cr,etp) :: (Exp.CREF(Exp.CREF_IDENT(xd_s,{}),etp) :: s)),(Exp.CREF(Exp.CREF_IDENT(name,{}),etp) :: (Exp.CREF(Exp.CREF_IDENT(xd_t,{}),etp) :: t)));
        
    case ((VAR(varName = (cr as Exp.CREF_IDENT(ident = str,subscriptLst = {})),varType=tp) :: vs))
      equation 
        (s,t) = variableReplacementsRemoveDollar(vs);
        etp = makeExpType(tp);
        ("%" :: rest) = string_list_string_char(str);
        str_1 = string_char_list_string(rest) "first character dollar sign." ;
      then
        ((Exp.CREF(cr,etp) :: s),(Exp.CREF(Exp.CREF_IDENT(str_1,{}),etp) :: t));
    case ((VAR(varName = (cr as Exp.CREF_IDENT(ident = str,subscriptLst = {}))) :: vs))
      equation 
        failure(("%" :: _) = string_list_string_char(str));
        print("Error, variable not prefixed with dollar sign.\n");
      then
        fail();
    case (_)
      equation 
        print("-variableReplacementsRemoveDollar failed\n");
      then
        fail();
  end matchcontinue;
end variableReplacementsRemoveDollar;

protected function makeExpType "Transforms a DAE.Type to Exp.Type"
  input DAE.Type inType;
  output Exp.Type expType;
algorithm
  expType := matchcontinue(inType)
    case(DAE.REAL()) then Exp.REAL();
    case(DAE.INT()) then Exp.INT();
    case(DAE.BOOL()) then Exp.BOOL();
    case(DAE.STRING()) then Exp.STRING();
    case(DAE.ENUM()) then Exp.ENUM();
    case(DAE.ENUMERATION(_)) then Exp.OTHER();
    case(DAE.EXT_OBJECT(_)) then Exp.OTHER();
  end matchcontinue;
end makeExpType;


protected function algVariableReplacements "function: algVariableReplacements
  author: PA
 
  Build replacement \"rules\" for the variables, eg. states, 
  algebraic variables, parameters, etc.
  Note: the new variable must be an identifier not valid in Modelica, 
  otherwise name collisions may occur.
"
  input list<Var> inVarLst;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inVarLst)
    local
      list<Exp.Exp> s1,t1;
      String indxs,name,c_name,newid;
      Exp.ComponentRef cr;
      Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Var> vs;
      Exp.Type etp;
      DAE.Type tp;
    case ({}) then ({},{}); 
    case ((VAR(varName = cr,varType=tp,index = indx,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs))
      equation 
        (s1,t1) = algVariableReplacements(vs);
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr);
        c_name = Util.modelicaStringToCStr(name);
        newid = Util.stringAppendList({"%$",c_name});
        etp = makeExpType(tp);
      then
        ((Exp.CREF(cr,etp) :: s1),(Exp.CREF(Exp.CREF_IDENT(newid,{}),etp) :: t1));
    case (_)
      equation 
        print("-alg_variable_replacements failed\n");
      then
        fail();
  end matchcontinue;
end algVariableReplacements;

protected function algVariableArrayReplacements "function: algVariableArrayReplacements
  author: PA
 
  Build replacement \"rules\" for a complete array variable,
  E.g. Real x{3} should also have a replacement \'x\' -> \'$x\', apart
  from the x{1} -> $x{1}, etc, generated by alg_variable_replacements.
  Note: the new variable must be an identifier not valid in Modelica, 
  otherwise name collisions may occur.
"
  input list<Var> inVarLst;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inVarLst)
    local
      list<Exp.Exp> s1,t1;
      Exp.ComponentRef cr_1,cr;
      String indxs,name,c_name,newid;
      list<Option<Integer>> int_dims;
      list<Exp.Subscript> instdims;
      Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Var> vs;
      DAE.Type tp;
      Exp.Type etp;
    case ({}) then ({},{}); 
    case ((VAR(varName = cr,varType = tp,arryDim = (instdims as (_ :: _)),index = indx,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs))
      equation 
        true = Exp.crefIsFirstArrayElt(cr);
        cr_1 = Exp.crefStripLastSubs(cr);
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr_1);
        c_name = Util.modelicaStringToCStr(name);
        int_dims = Util.listMap(Exp.subscriptsInt(instdims),Util.makeOption);
        newid = Util.stringAppendList({"$",c_name});
        etp = makeExpType(tp);
        (s1,t1) = algVariableArrayReplacements(vs);
      then
        ((Exp.CREF(cr_1,etp) :: s1),(Exp.CREF(Exp.CREF_IDENT(newid,{}),Exp.T_ARRAY(etp,int_dims)) :: t1));
    case ((_ :: vs))
      equation 
        (s1,t1) = algVariableArrayReplacements(vs);
      then
        (s1,t1);
    case (_)
      equation 
        print("-alg_variable_array_replacements failed\n");
      then
        fail();
  end matchcontinue;
end algVariableArrayReplacements;

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
      Exp.Exp e1,e2;
      list<Equation> es;
      Value ds,indx;
      list<Exp.Exp> expl,expl1,expl2;
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

protected function derivativeReplacements "function: derivativeReplacements
  author: PA
 
  Helper function for variable_replacements 
"
  input list<Exp.ComponentRef> inExpComponentRefLst;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm 
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inExpComponentRefLst)
    local
      list<Exp.Exp> s1,t1;
      Value indx;
      String indxs,name,c_name,newid;
      Exp.ComponentRef s;
      list<Key> ss;
      list<Var> vars;
    case ({}) then ({},{}); 
    case ((s :: ss))
      equation 
        (s1,t1) = derivativeReplacements(ss);
        name = Exp.printComponentRefStr(s);
        c_name = Util.modelicaStringToCStr(name);
        newid = Util.stringAppendList({derivativeNamePrefix,"$",c_name})  ;
        // Derivatives are always or REAL type
      then
        ((Exp.CALL(Absyn.IDENT("der"),{Exp.CREF(s,Exp.REAL())},false,true,Exp.REAL()) :: s1),(Exp.CREF(Exp.CREF_IDENT(newid,{}),Exp.REAL()) :: t1));
    case (_)
      equation 
        print("-derivative_replacements failed\n");
      then
        fail();
  end matchcontinue;
end derivativeReplacements;

protected function getIndex "function: getIndex
  author: PA
 
  Helper function to derivative_replacements 
"
  input Exp.ComponentRef inComponentRef;
  input list<Var> inVarLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inComponentRef,inVarLst)
    local
      Exp.ComponentRef cr1,cr2;
      Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Var> vs;
    case (cr1,(VAR(varName = cr2,index = indx,values = dae_var_attr,comment = comment,flow_ = flow_) :: _))
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
  author: PA
 
  Helper function to translate_dae. Calculates the indexes for each variable
  in one of the arrays. x, xd, y and extobjs.
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
      list<Var> vars_1,knvars_1,extvars_1,extvars,vars,knvars;
      Value x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType;
    case (vars,knvars,extvars)
      equation 
        (vars_1,x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(vars, 0, 0, 0, 0, 0,0,0,0,0,0,0);
        (knvars_1,_,_,_,_,_,_,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(knvars, x, xd, y, p, dummy,0,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
        (extvars_1,_,_,_,_,_,_,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(extvars, x, xd, y, p, dummy,0,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (vars_1,knvars_1,extvars_1);
    case (_,_,_)
      equation 
        print("-calculate_indexes failed\n");
      then
        fail();
  end matchcontinue;
end calculateIndexes;

protected function transformVariables "function: transformVariables
  author: PA
 
  Helper function to translate_dae
 
  
  inputs:  (Var list, 
              Exp.Exp list, 
              Exp.Exp list,
              string /* varible prefix, \"$\" or \"\" */)
  outputs: (Var list) 
"
  input list<Var> inVarLst1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  input String inString4;
  output list<Var> outVarLst;
algorithm 
  outVarLst:=
  matchcontinue (inVarLst1,inExpExpLst2,inExpExpLst3,inString4)
    local
      list<Var> vs_1,vs;
      String cr_str,var_prefix,name_str;
      Exp.ComponentRef cr_1,cr,name;
      Exp.Exp e_1,e;
      Option<Exp.Exp> start_1,start;
      VarKind kind;
      DAE.VarDirection a;
      DAE.Type b;
      Option<Values.Value> c;
      list<Exp.Subscript> d;
      Value i;
      list<Absyn.Path> j;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Exp.Exp> s,t;
    case ({},_,_,_) then {};  /* varible prefix, \"%\" or \"\" */ 
    case ((VAR(varName = cr,varKind = kind,varDirection = a,varType = b,bindExp = SOME(e),bindValue = c,arryDim = d,startValue = start,index = i,className = j,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),s,t,(var_prefix as "%")) /* When percent sign, save original name */ 
      equation 
        vs_1 = transformVariables(vs, s, t, var_prefix);
        cr_str = Exp.printComponentRefStr(cr);
        cr_1 = transformVariable(cr_str, i, kind, var_prefix);
        (e_1,_) = Exp.replaceExpList(e, s, t);
        start_1 = transformStartValue(start, s, t);
      then
        (VAR(cr_1,kind,a,b,SOME(e_1),c,d,start_1,i,cr,j,dae_var_attr,
          comment,flow_) :: vs_1);
    case ((VAR(varName = cr,varKind = kind,varDirection = a,varType = b,bindExp = SOME(e),bindValue = c,arryDim = d,startValue = start,index = i,origVarName = name,className = j,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),s,t,(var_prefix as "")) /* when empty prefix, use old original name When dollar sign, save original name */ 
      equation 
        vs_1 = transformVariables(vs, s, t, var_prefix);
        name_str = Exp.printComponentRefStr(name);
        cr_1 = transformVariable(name_str, i, kind, var_prefix);
        (e_1,_) = Exp.replaceExpList(e, s, t);
        start_1 = transformStartValue(start, s, t);
      then
        (VAR(cr_1,kind,a,b,SOME(e_1),c,d,start_1,i,name,j,dae_var_attr,
          comment,flow_) :: vs_1);
    case ((VAR(varName = cr,varKind = kind,varDirection = a,varType = b,bindExp = NONE,bindValue = c,arryDim = d,startValue = start,index = i,className = j,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),s,t,(var_prefix as "%")) /* When dollar sign, save original name */ 
      equation 
        vs_1 = transformVariables(vs, s, t, var_prefix);
        cr_str = Exp.printComponentRefStr(cr);
        cr_1 = transformVariable(cr_str, i, kind, var_prefix);
        start_1 = transformStartValue(start, s, t);
      then
        (VAR(cr_1,kind,a,b,NONE,c,d,start_1,i,cr,j,dae_var_attr,comment,
          flow_) :: vs_1);
    case ((VAR(varName = cr,varKind = kind,varDirection = a,varType = b,bindExp = NONE,bindValue = c,arryDim = d,startValue = start,index = i,origVarName = name,className = j,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),s,t,(var_prefix as "")) /* when empty prefix, use old original name */ 
      equation 
        vs_1 = transformVariables(vs, s, t, var_prefix);
        name_str = Exp.printComponentRefStr(name);
        cr_1 = transformVariable(name_str, i, kind, var_prefix);
        start_1 = transformStartValue(start, s, t);
      then
        (VAR(cr_1,kind,a,b,NONE,c,d,start_1,i,name,j,dae_var_attr,
          comment,flow_) :: vs_1);
  end matchcontinue;
end transformVariables;

protected function transformStartValue "function: transformStartValue
  author: PA
 
  Helper function to transform_variables
"
  input DAE.StartValue inStartValue1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output DAE.StartValue outStartValue;
algorithm 
  outStartValue:=
  matchcontinue (inStartValue1,inExpExpLst2,inExpExpLst3)
    local
      Exp.Exp e_1,e;
      list<Exp.Exp> s,t;
    case (SOME(e),s,t)
      equation 
        (e_1,_) = Exp.replaceExpList(e, s, t);
      then
        SOME(e_1);
    case (NONE,_,_) then NONE; 
  end matchcontinue;
end transformStartValue;

protected function transformVariable "function: transformVariable
  author: PA
 
  Helper function to transform_variables
 
  inputs:  (int, 
              VarKind, 
              string /* varible prefix, \"$\" or \"\" */)
  outputs: Exp.ComponentRef
"
  input String inString1;
  input Integer inInteger2;
  input VarKind inVarKind3;
  input String inString4;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inString1,inInteger2,inVarKind3,inString4)
    local
      String id_1,id,name,var_prefix;
      Value i;
    case (name,i,_,var_prefix) /* varible prefix, \"%\" or \"\" rule	int_string(i) => is & 	Util.string_append_list({var_prefix,\"y{\",is,\"}\"}) => id 	------------------- 	transform_variable(i, VARIABLE,var_prefix) => Exp.CREF_IDENT(id,{}) rule	int_string(i) => is & 	Util.string_append_list({var_prefix,\"x{\",is,\"}\"}) => id 	------------------- 	transform_variable(i, STATE,var_prefix) => Exp.CREF_IDENT(id,{}) rule	int_string(i) => is & 	Util.string_append_list({var_prefix,\"y{\",is,\"}\"}) => id 	------------------- 	transform_variable(i, DUMMY_DER,var_prefix) => Exp.CREF_IDENT(id,{}) rule	int_string(i) => is & 	Util.string_append_list({var_prefix,\"y{\",is,\"}\"}) => id 	------------------- 	transform_variable(i, DUMMY_STATE,var_prefix) => Exp.CREF_IDENT(id,{}) rule	int_string(i) => is & 	Util.string_append_list({var_prefix,\"y{\",is,\"}\"}) => id 	------------------- 	transform_variable(i, DISCRETE,var_prefix) => Exp.CREF_IDENT(id,{}) rule	int_string(i) => is & 	Util.string_append_list({var_prefix,\"p{\",is,\"}\"}) => id 	------------------- 	transform_variable(i, PARAM,var_prefix) => Exp.CREF_IDENT(id,{}) rule	int_string(i) => is & 	Util.string_append_list({var_prefix,\"p{\",is,\"}\"}) => id 	------------------- 	transform_variable(i, CONST,var_prefix) => Exp.CREF_IDENT(id,{}) */ 
      equation 
        id_1 = Util.modelicaStringToCStr(name);
        id = Util.stringAppendList({var_prefix,"$",id_1});
      then
        Exp.CREF_IDENT(id,{});
  end matchcontinue;
end transformVariable;

protected function calculateIndexes2 "function: calculateIndexes2
  author: PA
 
  Helper function to calculate_indexes
"
  input list<Var> inVarLst1;
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


  output list<Var> outVarLst1;
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
      list<Var> vars_1,vs;
      Exp.ComponentRef cr,name;
      DAE.VarDirection d;
      DAE.Type tp;
      Option<Exp.Exp> b,start;
      Option<Values.Value> value;
      list<Exp.Subscript> dim;
      list<Absyn.Path> cl;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
    case ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) then ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType); 

    case ((VAR(varName = cr,varKind = VARIABLE(),varDirection = d,varType = DAE.STRING(),bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);

      then
        ((VAR(cr,VARIABLE(),d,DAE.STRING(),b,value,dim,start,y_strType,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
    case ((VAR(varName = cr,varKind = VARIABLE(),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,VARIABLE(),d,tp,b,value,dim,start,y,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case ((VAR(varName = cr,varKind = STATE(),varDirection = d,varType = DAE.STRING(),bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        x_1_strType = x_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_1_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,STATE(),d,DAE.STRING(),b,value,dim,start,x_strType,name,cl,dae_var_attr,
          comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
    case ((VAR(varName = cr,varKind = STATE(),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        x_1 = x + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x_1, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,STATE(),d,tp,b,value,dim,start,x,name,cl,dae_var_attr,
          comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case ((VAR(varName = cr,varKind = DUMMY_DER(),varDirection = d,varType = DAE.STRING(),bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1_strType = y_strType + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,DUMMY_DER(),d,DAE.STRING(),b,value,dim,start,y_strType,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
    case ((VAR(varName = cr,varKind = DUMMY_DER(),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1 = y + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,DUMMY_DER(),d,tp,b,value,dim,start,y,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case ((VAR(varName = cr,varKind = DUMMY_STATE(),varDirection = d,varType = DAE.STRING(),bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1_strType = y_strType + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,DUMMY_STATE(),d,DAE.STRING(),b,value,dim,start,y_strType,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
    case ((VAR(varName = cr,varKind = DUMMY_STATE(),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1 = y + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,DUMMY_STATE(),d,tp,b,value,dim,start,y,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case ((VAR(varName = cr,varKind = DISCRETE(),varDirection = d,varType = DAE.STRING(),bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,DISCRETE(),d,DAE.STRING(),b,value,dim,start,y_strType,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
    case ((VAR(varName = cr,varKind = DISCRETE(),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,DISCRETE(),d,tp,b,value,dim,start,y,name,cl,
          dae_var_attr,comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case ((VAR(varName = cr,varKind = PARAM(),varDirection = d,varType = DAE.STRING(),bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        p_1_strType = p_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_1_strType,dummy_strType);
      then
        ((VAR(cr,PARAM(),d,DAE.STRING(),b,value,dim,start,p_strType,name,cl,dae_var_attr,
          comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
    case ((VAR(varName = cr,varKind = PARAM(),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 
        p_1 = p + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p_1, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,PARAM(),d,tp,b,value,dim,start,p,name,cl,dae_var_attr,
          comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case ((VAR(varName = cr,varKind = CONST(),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation 

         //IS THIS A BUG??
         // THE INDEX FOR const IS SET TO p (=last parameter index)
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,CONST(),d,tp,b,value,dim,start,p,name,cl,dae_var_attr,
          comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case ((VAR(varName = cr,varKind = EXTOBJ(path),varDirection = d,varType = tp,bindExp = b,bindValue = value,arryDim = dim,startValue = start,origVarName = name,className = cl,values = dae_var_attr,comment = comment,flow_ = flow_) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      local Absyn.Path path;
      equation 
	ext_1 = ext+1;	
        (vars_1,x1,xd1,y1,p1,dummy,ext_1,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) = calculateIndexes2(vs, x, xd, y, p, dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        ((VAR(cr,EXTOBJ(path),d,tp,b,value,dim,start,p,name,cl,dae_var_attr,
          comment,flow_) :: vars_1),x1,xd1,y1,p1,dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
  end matchcontinue;
end calculateIndexes2;

protected function printEquations "function: printEquations
  author: PA
 
  Helper function to dump
"
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

protected function printEquation "function: printEquation
  author: PA
 
  Helper function to print_equations
"
  input Equation inEquation;
algorithm 
  _:=
  matchcontinue (inEquation)
    local
      String s1,s2,res;
      Exp.Exp e1,e2;
      Exp.ComponentRef cr;
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
      Exp.ComponentRef rkey;
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
      Exp.ComponentRef key,rkey;
      Value value,rval,cmpval;
      String rkeystr,keystr;
      Option<BinTree> left,right;
      BinTree t_1,t,right_1,left_1;
    case (TREENODE(value = NONE,leftSubTree = NONE,rightSubTree = NONE),key,value) then TREENODE(SOME(TREEVALUE(key,value)),NONE,NONE); 
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = right),key,value)
      equation 
        rkeystr = Exp.printComponentRefStr(rkey) "Replace this node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE(SOME(TREEVALUE(rkey,value)),left,right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as SOME(t))),key,value)
      equation 
        keystr = Exp.printComponentRefStr(key) "Insert to right subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(t_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = left,rightSubTree = (right as NONE)),key,value)
      equation 
        keystr = Exp.printComponentRefStr(key) "Insert to right node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(right_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = (left as SOME(t)),rightSubTree = right),key,value)
      equation 
        keystr = Exp.printComponentRefStr(key) "Insert to left subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(t_1),right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),leftSubTree = (left as NONE),rightSubTree = right),key,value)
      equation 
        keystr = Exp.printComponentRefStr(key) "Insert to left node" ;
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
      Exp.ComponentRef key,rkey;
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
      Exp.ComponentRef key;
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
  input Exp.Exp inExp;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExp)
    local
      Value x,ival,i;
      String s,id;
      Exp.ComponentRef c;
      Exp.Exp e1,e2,e21,e22,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      Exp.Operator op;
      Exp.Type ty,ty2,REAL;
      list<Exp.Exp> args,es;
      Absyn.Path fcn;
    case (Exp.END()) then true; 
    case (Exp.ICONST(integer = x)) then true; 
    case (Exp.RCONST(real = x))
      local Real x;
      then
        true;
    case (Exp.SCONST(string = s)) then true; 
    case (Exp.BCONST(bool = false)) then true; 
    case (Exp.BCONST(bool = true)) then true; 
    case (Exp.CREF(componentRef = c)) then true; 
    case (Exp.BINARY(exp1 = e1,operator = (op as Exp.SUB(ty = ty)),exp2 = (e2 as Exp.BINARY(exp1 = e21,operator = Exp.SUB(ty = ty2),exp2 = e22))))
      equation 
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (Exp.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (Exp.UNARY(operator = op,exp = e))
      equation 
        true = isAlgebraic(e);
      then
        true;
    case (Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (Exp.LUNARY(operator = op,exp = e))
      equation 
        true = isAlgebraic(e);
      then
        true;
    case (Exp.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (Exp.IFEXP(expCond = c,expThen = t,expElse = f))
      local Exp.Exp c;
      equation 
        true = isAlgebraic(c);
        true = isAlgebraic(t);
        true = isAlgebraic(f);
      then
        true;
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = args)) then false; 
    case (Exp.CALL(path = fcn,expLst = args)) then true; 
    case (Exp.ARRAY(array = es)) then true; 
    case (Exp.TUPLE(PR = es)) then true; 
    case (Exp.MATRIX(scalar = es))
      local list<list<tuple<Exp.Exp, Boolean>>> es;
      then
        true;
    case (Exp.RANGE(exp = start,expOption = NONE,range = stop))
      equation 
        true = isAlgebraic(start);
        true = isAlgebraic(stop);
      then
        true;
    case (Exp.RANGE(exp = start,expOption = SOME(step),range = stop))
      equation 
        true = isAlgebraic(start);
        true = isAlgebraic(step);
        true = isAlgebraic(stop);
      then
        true;
    case (Exp.CAST(ty = REAL,exp = Exp.ICONST(integer = ival))) then true; 
    case (Exp.CAST(ty = REAL,exp = Exp.UNARY(operator = Exp.UMINUS(ty = _),exp = Exp.ICONST(integer = ival)))) then true; 
    case (Exp.CAST(ty = Exp.REAL(),exp = e)) then true; 
    case (Exp.CAST(ty = Exp.REAL(),exp = e)) then true; 
    case (Exp.ASUB(exp = e,sub = i))
      equation 
        true = isAlgebraic(e);
      then
        true;
    case (Exp.SIZE(exp = cr,sz = SOME(dim))) then true; 
    case (Exp.SIZE(exp = cr,sz = NONE)) then true; 
    case (Exp.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp)) then true; 
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
  input Exp.ComponentRef inComponentRef;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVarLst,inComponentRef)
    local
      Exp.ComponentRef var_name,cr,origname;
      Var variable;
      Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
      list<Var> rest;
      Boolean res;
    case ({},var_name) then false; 
    case (((variable as VAR(varName = cr,index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flow_ = flow_)) :: rest),var_name)
      equation 
        true = Exp.crefEqual(cr, var_name);
      then
        true;
    case (((variable as VAR(varName = cr,index = indx,origVarName = origname,values = dae_var_attr,comment = comment,flow_ = flow_)) :: rest),var_name)
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
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inDAELow)
    local
      list<Exp.Exp> exps1,exps2,exps3,exps4,exps5,exps6,exps;
      list<Algorithm.Algorithm> alglst;
      list<list<Exp.Exp>> explist6,explist;
      Variables vars1,vars2;
      EquationArray eqns,reqns,ieqns;
      MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] algs;
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
  output list<Exp.Exp> res;
  list<MultiDimEquation> lst;
  list<list<Exp.Exp>> llst;
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
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inMultiDimEquation)
    local Exp.Exp e1,e2;
    case (MULTIDIM_EQUATION(left = e1,right = e2)) then {e1,e2}; 
  end matchcontinue;
end getAllExpsArrayEqn;

protected function getAllExpsVars "function: getAllExpsVars
  author: PA
  
  Helper to get_all_exps. Goes through the Variables type
"
  input Variables inVariables;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inVariables)
    local
      list<Var> vars;
      list<Exp.Exp> exps;
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
  Exp.OTHER is used as type for componentref. Not important here.
  We only use the exp list for finding function calls
"
  input Var inVar;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inVar)
    local
      list<Exp.Exp> e1,e2,e3,exps;
      Exp.ComponentRef cref,orgname;
      VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      Option<Exp.Exp> bndexp,startvalexp;
      Option<Values.Value> bndval;
      list<Exp.Subscript> instdims;
      Value ind;
      list<Absyn.Path> clsnames;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flow_;
    case VAR(varName = cref,varKind = vk,varDirection = vd,varType = ty,bindExp = bndexp,bindValue = bndval,arryDim = instdims,startValue = startvalexp,index = ind,origVarName = orgname,className = clsnames,values = dae_var_attr,comment = comment,flow_ = flow_)
      equation 
        e1 = Util.optionToList(bndexp);
        e2 = Util.optionToList(startvalexp);
        e3 = Util.listMap(instdims, getAllExpsSubscript);
        e3 = Util.listFlatten(e3);
        exps = Util.listFlatten({e1,e2,e3,{Exp.CREF(cref,Exp.OTHER())}});
      then
        exps;
  end matchcontinue;
end getAllExpsVar;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  author: PA
  
  Get all exps from a Subscript 
"
  input Exp.Subscript inSubscript;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inSubscript)
    local Exp.Exp e;
    case Exp.WHOLEDIM() then {}; 
    case Exp.SLICE(exp = e) then {e}; 
    case Exp.INDEX(exp = e) then {e}; 
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsEqns "function: getAllExpsEqns
  author: PA
  
  Helper to get_all_exps. Goes through the EquationArray type
"
  input EquationArray inEquationArray;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inEquationArray)
    local
      list<Equation> eqns;
      list<Exp.Exp> exps;
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
  
  Helper to get_all_exps_eqns. Get all exps from an Equation.
"
  input Equation inEquation;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inEquation)
    local
      Exp.Exp e1,e2,e;
      list<Exp.Exp> expl,exps;
      Exp.Type tp;
      Exp.ComponentRef cr;
      Value ind;
    WhenEquation elsePart;
      
    case EQUATION(exp = e1,scalar = e2) then {e1,e2}; 
    case ARRAY_EQUATION(crefOrDerCref = expl) then expl; 
    case SOLVED_EQUATION(componentRef = cr,exp = e)
      equation 
        tp = Exp.typeof(e);
      then
        {Exp.CREF(cr,tp),e};
    case WHEN_EQUATION(whenEquation = WHEN_EQ(left = cr,right = e,elsewhenPart=NONE))
      equation 
        tp = Exp.typeof(e);
      then
        {Exp.CREF(cr,tp),e};
    case WHEN_EQUATION(whenEquation = WHEN_EQ(_,cr,e,SOME(elsePart)))
      equation 
        tp = Exp.typeof(e);
        expl = getAllExpsEqn(WHEN_EQUATION(elsePart));
        exps = listAppend({Exp.CREF(cr,tp),e},expl);
      then
        exps;
    case ALGORITHM(index = ind,in_ = e1,out = e2)
      local list<Exp.Exp> e1,e2;
      equation 
        exps = listAppend(e1, e2);
      then
        exps;
  end matchcontinue;
end getAllExpsEqn;

public function isParam "function: isParam
 
  Return true if variable is a parameter.
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varKind = PARAM(),flow_ = flow_)) then true; 
    case (_) then false; 
  end matchcontinue;
end isParam;

public function isStringParam "function: isStringParam
 
  Return true if variable is a parameter.
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varKind = PARAM(),flow_ = flow_,varType = DAE.STRING())) then true; 
    case (_) then false; 
  end matchcontinue;
end isStringParam;

public function isExtObj "function: isExtObj
 
  Return true if variable is an external object.
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varKind = EXTOBJ(_),flow_ = flow_)) then true; 
    case (_) then false; 
  end matchcontinue;
end isExtObj;

public function isRealParam "function: isParam
 
  Return true if variable is a parameter of real-type
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varKind = PARAM(),flow_ = flow_,varType = DAE.REAL())) then true; 
    case (_) then false; 
  end matchcontinue;
end isRealParam;

public function isNonRealParam "function: isParam
 
  Return true if variable is a parameter of real-type
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varKind = PARAM(),flow_ = flow_,varType = DAE.REAL())) then false; 
    case (VAR(varKind = PARAM(),flow_ = flow_)) then true; 
    case (_) then false; 
  end matchcontinue;
end isNonRealParam;

public function isOutput "function: isOutput
 
  Return true if variable is declared as output. Note that the output
  attribute sticks with a variable even if it is originating from a sub
  component, which is not the case for Dymola.
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varDirection = DAE.OUTPUT(),flow_ = flow_)) then true; 
    case (_) then false; 
  end matchcontinue;
end isOutput;

public function isInput "function: isInput
 
  Returns true if variable is declared as input.
  See also is_ouput above
"
  input Var inVar;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inVar)
    local DAE.Flow flow_;
    case (VAR(varDirection = DAE.INPUT(),flow_ = flow_)) then true; 
    case (_) then false; 
  end matchcontinue;
end isInput;

public function getWhenEquationExpr "function: getWhenEquationExpr
 
  Get the left and right hand parts from an equation appearing in a when clause
"
  input WhenEquation inWhenEquation;
  output Exp.ComponentRef outComponentRef;
  output Exp.Exp outExp;
algorithm 
  (outComponentRef,outExp):=
  matchcontinue (inWhenEquation)
    local
      Exp.ComponentRef cr;
      Exp.Exp e;
    case (WHEN_EQ(left = cr,right = e)) then (cr,e); 
  end matchcontinue;
end getWhenEquationExpr;

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

end DAELow;

