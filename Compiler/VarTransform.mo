/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package VarTransform
" file:	       VarTransform.mo
  package:     VarTransform
  description: VarTransform contains a Binary Tree representation of variable replacements.

  RCS: $Id$

  This module contain a Binary tree representation of variable replacements
  along with some functions for performing replacements of variables in equations"

public import Exp;
public import DAELow;
public import DAE;

public
uniontype VariableReplacements "
VariableReplacements consists of a mapping between variables and expressions, the first binary tree of this type.
To eliminate a variable from an equation system a replacement rule varname->expression is added to this
datatype.
To be able to update these replacement rules incrementally a backward lookup mechanism is also required.
For instance, having a rule a->b and adding a rule b->c requires to find the first rule a->b and update it to
a->c. This is what the second binary tree is used for.
   "
  record REPLACEMENTS
    BinTree src "src -> dst, used for replacing. src is variable, dst is expression" ;
    BinTree2 binTree2 "dst -> list of sources. dst is a variable, sources are variables.";
  end REPLACEMENTS;

end VariableReplacements;

public
uniontype BinTree
  record TREENODE
    Option<TreeValue> value "Value" ;
    Option<BinTree> left "left subtree" ;
    Option<BinTree> right "right subtree" ;
  end TREENODE;

end BinTree;

public
uniontype BinTree2
  record TREENODE2
    Option<TreeValue2> value "Value" ;
    Option<BinTree2> left "left subtree" ;
    Option<BinTree2> right "right subtree" ;
  end TREENODE2;

end BinTree2;

public
uniontype TreeValue "Each node in the binary tree can have a value associated with it."
  record TREEVALUE
    Key key "Key" ;
    Value value "Value" ;
  end TREEVALUE;

end TreeValue;

public
uniontype TreeValue2
  record TREEVALUE2
    Key key "Key" ;
    Value2 value "Value" ;
  end TREEVALUE2;

end TreeValue2;

public
type Key = Exp.ComponentRef "Key" ;

public
type Value = Exp.Exp;

public
type Value2 = list<Exp.ComponentRef>;

protected import System;
protected import Util;
protected import Algorithm;
protected import Debug;
protected import Absyn;
protected import Types;

public function applyReplacementsDAE "Apply a set of replacement rules on a DAE "
	input list<DAE.Element> inDae;
	input VariableReplacements repl;
	output list<DAE.Element> outDae;
algorithm
  outDae := matchcontinue(inDae,repl)
    local
      Exp.ComponentRef cr,cr2;
      list<DAE.Element> dae,dae2,elist,elist2,elist22,elist1,elist11;
      DAE.Element elt,elt2,elt22,elt1,elt11;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.Type tp;
      Exp.Exp bindExp,bindExp2,e,e2,e22,e1,e11;
      DAE.InstDims dims;
      DAE.StartValue start;
      DAE.Flow fl;
      DAE.Stream st;
      list<Absyn.Path> clsLst;
      Option<DAE.VariableAttributes> attr;
      Option<Absyn.Comment> cmt;
      Absyn.InnerOuter io;
      Types.Type ftp;
      list<Integer> idims;
      DAE.ExternalDecl extDecl;
      DAE.Ident id;
      Absyn.Path path;
      list<Algorithm.Statement> stmts,stmts2;
      DAE.VarProtection prot;

      // if no replacements, return dae, no need to traverse.
    case(dae,REPLACEMENTS(TREENODE(NONE,NONE,NONE),TREENODE2(NONE,NONE,NONE))) then dae;

    case({},repl) then {};

    case(DAE.VAR(cr,kind,dir,prot,tp,SOME(bindExp),dims,fl,st,clsLst,attr,cmt,io,ftp)::dae,repl)
      equation
        (bindExp2) = replaceExp(bindExp, repl, NONE);
  			dae2 = applyReplacementsDAE(dae,repl);
        attr = applyReplacementsVarAttr(attr,repl);
      then DAE.VAR(cr,kind,dir,prot,tp,SOME(bindExp),dims,fl,st,clsLst,attr,cmt,io,ftp)::dae2;

    case(DAE.VAR(cr,kind,dir,prot,tp,NONE,dims,fl,st,clsLst,attr,cmt,io,ftp)::dae,repl)
      equation
        dae2 = applyReplacementsDAE(dae,repl);
        attr = applyReplacementsVarAttr(attr,repl);
      then DAE.VAR(cr,kind,dir,prot,tp,NONE,dims,fl,st,clsLst,attr,cmt,io,ftp)::dae2;

    case(DAE.DEFINE(cr,e)::dae,repl)
      equation
        (e2) = replaceExp(e, repl, NONE);
        (Exp.CREF(cr2,_)) = replaceExp(Exp.CREF(cr,Exp.REAL()), repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.DEFINE(cr2,e2)::dae2;

    case(DAE.INITIALDEFINE(cr,e)::dae,repl)
      equation
        (e2) = replaceExp(e, repl, NONE);
        (Exp.CREF(cr2,_)) = replaceExp(Exp.CREF(cr,Exp.REAL()), repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.INITIALDEFINE(cr2,e2)::dae2;

    case(DAE.EQUATION(e1,e2)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        (e22) = replaceExp(e2, repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.EQUATION(e11,e22)::dae2;
        
    case(DAE.ARRAY_EQUATION(idims,e1,e2)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        (e22) = replaceExp(e2, repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.ARRAY_EQUATION(idims,e11,e22)::dae2;

    case(DAE.WHEN_EQUATION(e1,elist,SOME(elt))::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        {elt2}= applyReplacementsDAE({elt},repl);
        elist2 = applyReplacementsDAE(elist,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.WHEN_EQUATION(e11,elist2,SOME(elt2))::dae2;

    case(DAE.WHEN_EQUATION(e1,elist,NONE)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        elist2 = applyReplacementsDAE(elist,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.WHEN_EQUATION(e11,elist2,NONE)::dae2;

    case(DAE.IF_EQUATION(e1,elist1,elist2)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        elist11 = applyReplacementsDAE(elist1,repl);
        elist22 = applyReplacementsDAE(elist2,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.IF_EQUATION(e11,elist11,elist22)::dae2;

    case(DAE.INITIAL_IF_EQUATION(e1,elist1,elist2)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        elist11 = applyReplacementsDAE(elist1,repl);
        elist22 = applyReplacementsDAE(elist2,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.INITIAL_IF_EQUATION(e11,elist11,elist22)::dae2;

    case(DAE.INITIALEQUATION(e1,e2)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        (e22) = replaceExp(e2, repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.INITIALEQUATION(e11,e22)::dae2;

     case(DAE.ALGORITHM(Algorithm.ALGORITHM(stmts))::dae,repl)
      equation
        stmts2 = replaceEquationsStmts(stmts,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.ALGORITHM(Algorithm.ALGORITHM(stmts2))::dae2;

     case(DAE.INITIALALGORITHM(Algorithm.ALGORITHM(stmts))::dae,repl)
      equation
        stmts2 = replaceEquationsStmts(stmts,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.INITIALALGORITHM(Algorithm.ALGORITHM(stmts2))::dae2;

     case(DAE.COMP(id,DAE.DAE(elist))::dae,repl)
      equation
        elist2 = applyReplacementsDAE(elist,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.COMP(id,DAE.DAE(elist))::dae2;

     case(DAE.FUNCTION(path,DAE.DAE(elist),ftp)::dae,repl)
      equation
        elist2 = applyReplacementsDAE(elist,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.FUNCTION(path,DAE.DAE(elist2),ftp)::dae2;

     case(DAE.EXTFUNCTION(path,DAE.DAE(elist),ftp,extDecl)::dae,repl)
      equation
        elist2 = applyReplacementsDAE(elist,repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.EXTFUNCTION(path,DAE.DAE(elist2),ftp,extDecl)::dae2;

     case(DAE.EXTOBJECTCLASS(path,elt1,elt2)::dae,repl)
      equation
        {elt11,elt22} =  applyReplacementsDAE({elt1,elt2},repl);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.EXTOBJECTCLASS(path,elt1,elt2)::dae2;

     case(DAE.ASSERT(e1,e2)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        (e22) = replaceExp(e2, repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.ASSERT(e11,e22)::dae2;

     case(DAE.TERMINATE(e1)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.TERMINATE(e11)::dae2;

     case(DAE.REINIT(cr,e1)::dae,repl)
      equation
        (e11) = replaceExp(e1, repl, NONE);
        (Exp.CREF(cr2,_)) = replaceExp(Exp.CREF(cr,Exp.REAL()), repl, NONE);
        dae2 = applyReplacementsDAE(dae,repl);
      then DAE.REINIT(cr2,e11)::dae2;
        
  end matchcontinue;
end applyReplacementsDAE;

protected function applyReplacementsVarAttr 
"Help function to applyReplacementsDAE"
  input Option<DAE.VariableAttributes> attr;
  input VariableReplacements repl;
  output Option<DAE.VariableAttributes> outAttr;
algorithm
  outAttr := matchcontinue(attr,repl)
    local Option<Exp.Exp> quantity,unit,displayUnit,min,max,initial_,fixed,nominal; Option<DAE.StateSelect> stateSelect;
      
    case(SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect)),repl) 
      equation
        (quantity) = replaceExpOpt(quantity,repl,NONE);
        (unit) = replaceExpOpt(unit,repl,NONE);
        (displayUnit) = replaceExpOpt(displayUnit,repl,NONE);
        (min) = replaceExpOpt(min,repl,NONE);
        (max) = replaceExpOpt(max,repl,NONE);
        (initial_) = replaceExpOpt(initial_,repl,NONE);
        (fixed) = replaceExpOpt(fixed,repl,NONE);
        (nominal) = replaceExpOpt(nominal,repl,NONE);
      then SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,(min,max),initial_,fixed,nominal,stateSelect));

    case(SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed)),repl) 
      equation
        (quantity) = replaceExpOpt(quantity,repl,NONE);
        (min) = replaceExpOpt(min,repl,NONE);
        (max) = replaceExpOpt(max,repl,NONE);
        (initial_) = replaceExpOpt(initial_,repl,NONE);
        (fixed) = replaceExpOpt(fixed,repl,NONE);
      then SOME(DAE.VAR_ATTR_INT(quantity,(min,max),initial_,fixed));

    case(SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed)),repl) 
      equation
        (quantity) = replaceExpOpt(quantity,repl,NONE);
        (initial_) = replaceExpOpt(initial_,repl,NONE);
        (fixed) = replaceExpOpt(fixed,repl,NONE);
      then SOME(DAE.VAR_ATTR_BOOL(quantity,initial_,fixed));

    case(SOME(DAE.VAR_ATTR_STRING(quantity,initial_)),repl) 
      equation
        (quantity) = replaceExpOpt(quantity,repl,NONE);
        (initial_) = replaceExpOpt(initial_,repl,NONE);
      then SOME(DAE.VAR_ATTR_STRING(quantity,initial_));

      case (NONE(),repl) then NONE();
  end matchcontinue;
end  applyReplacementsVarAttr;

public function applyReplacements "function: applyReplacements

  This function takes a VariableReplacements and two component references.
  It applies the replacements to each component reference.
"
  input VariableReplacements inVariableReplacements1;
  input Exp.ComponentRef inComponentRef2;
  input Exp.ComponentRef inComponentRef3;
  output Exp.ComponentRef outComponentRef1;
  output Exp.ComponentRef outComponentRef2;
algorithm
  (outComponentRef1,outComponentRef2):=
  matchcontinue (inVariableReplacements1,inComponentRef2,inComponentRef3)
    local
      Exp.ComponentRef cr1_1,cr2_1,cr1,cr2;
      VariableReplacements repl;
    case (repl,cr1,cr2)
      equation
        (Exp.CREF(cr1_1,_)) = replaceExp(Exp.CREF(cr1,Exp.REAL()), repl, NONE);
        (Exp.CREF(cr2_1,_)) = replaceExp(Exp.CREF(cr2,Exp.REAL()), repl, NONE);
      then
        (cr1_1,cr2_1);
  end matchcontinue;
end applyReplacements;

public function applyReplacementsExp "

Similar to applyReplacements but for expressions instead of component references.
"
  input VariableReplacements repl;
  input Exp.Exp inExp1;
  input Exp.Exp inExp2;
  output Exp.Exp outExp1;
  output Exp.Exp outExp2;
algorithm
  (outExp1,outExp2):=
  matchcontinue (repl,inExp1,inExp2)
    local
      Exp.Exp e1,e2;
      VariableReplacements repl;
    case (repl,e1,e2)
      equation
        (e1) = replaceExp(e1, repl, NONE);
        (e2) = replaceExp(e2, repl, NONE);
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        (e1,e2);
  end matchcontinue;
end applyReplacementsExp;

public function emptyReplacements "function: emptyReplacements

  Returns an empty set of replacement rules
"
  output VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  matchcontinue ()
    case () then REPLACEMENTS(TREENODE(NONE,NONE,NONE),TREENODE2(NONE,NONE,NONE));
  end matchcontinue;
end emptyReplacements;

public function replaceEquations "function: replaceEquations

  This function takes a list of equations ana a set of variable replacements
  and applies the replacements on all equations.
  The function returns the updated list of equations
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input VariableReplacements inVariableReplacements;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowEquationLst,inVariableReplacements)
    local
      Exp.Exp e1_1,e2_1,e1_2,e2_2,e1,e2,e_1,e_2,e;
      list<DAELow.Equation> es_1,es;
      VariableReplacements repl;
      DAELow.Equation a;
      Exp.ComponentRef cr;
      Integer indx;
      list<Exp.Exp> expl,expl1,expl2;
      DAELow.WhenEquation whenEqn,whenEqn1;
    case ({},_) then {};
    case ((DAELow.ARRAY_EQUATION(indx,expl)::es),repl)
      equation
        expl1 = Util.listMap2(expl,replaceExp,repl,NONE);
        expl2 = Util.listMap(expl1,Exp.simplify);
        es_1 = replaceEquations(es,repl);
      then
         (DAELow.ARRAY_EQUATION(indx,expl2)::es_1);
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: es),repl)
      equation
        e1_1 = replaceExp(e1, repl, NONE);
        e2_1 = replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.EQUATION(e1_2,e2_2) :: es_1);
    case (((a as DAELow.ALGORITHM(index = _)) :: es),repl)
      equation
        es_1 = replaceEquations(es, repl);
      then
        (a :: es_1);
    case ((DAELow.SOLVED_EQUATION(componentRef = cr,exp = e) :: es),repl)
      equation
        e_1 = replaceExp(e, repl, NONE);
        e_2 = Exp.simplify(e_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.SOLVED_EQUATION(cr,e_2) :: es_1);
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: es),repl)
      equation
        e_1 = replaceExp(e, repl, NONE);
        e_2 = Exp.simplify(e_1);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.RESIDUAL_EQUATION(e_2) :: es_1);

    case ((DAELow.WHEN_EQUATION(whenEqn) :: es),repl)
      equation
				whenEqn1 = replaceWhenEquation(whenEqn,repl);
        es_1 = replaceEquations(es, repl);
      then
        (DAELow.WHEN_EQUATION(whenEqn1) :: es_1);

    case ((a :: es),repl)
      equation
        es_1 = replaceEquations(es, repl);
      then
        (a :: es_1);
  end matchcontinue;
end replaceEquations;

protected function replaceWhenEquation "Replaces variables in a when equation"
	input DAELow.WhenEquation whenEqn;
  input VariableReplacements repl;
  output DAELow.WhenEquation outWhenEqn;
algorithm
  outWhenEqn := matchcontinue(whenEqn,repl)
  local Integer i;
    Exp.ComponentRef cr,cr1;
    Exp.Exp e,e1,e2;
    Exp.Type tp;
    DAELow.WhenEquation elsePart,elsePart2;

    case (DAELow.WHEN_EQ(i,cr,e,NONE),repl) equation
        e1 = replaceExp(e, repl, NONE);
        e2 = Exp.simplify(e1);
        Exp.CREF(cr1,_) = replaceExp(Exp.CREF(cr,Exp.OTHER()),repl,NONE);
    then DAELow.WHEN_EQ(i,cr1,e2,NONE);

			// Replacements makes cr negative, a = -b
	  case (DAELow.WHEN_EQ(i,cr,e,NONE),repl) equation
        Exp.UNARY(Exp.UMINUS(tp),Exp.CREF(cr1,_)) = replaceExp(Exp.CREF(cr,Exp.OTHER()),repl,NONE);
        e1 = replaceExp(e, repl, NONE);
        e2 = Exp.simplify(Exp.UNARY(Exp.UMINUS(tp),e1));
    then DAELow.WHEN_EQ(i,cr1,e2,NONE);

    case (DAELow.WHEN_EQ(i,cr,e,SOME(elsePart)),repl) equation
        elsePart2 = replaceWhenEquation(elsePart,repl);
        e1 = replaceExp(e, repl, NONE);
        e2 = Exp.simplify(e1);
        Exp.CREF(cr1,_) = replaceExp(Exp.CREF(cr,Exp.OTHER()),repl,NONE);
    then DAELow.WHEN_EQ(i,cr1,e2,SOME(elsePart2));

			// Replacements makes cr negative, a = -b
	  case (DAELow.WHEN_EQ(i,cr,e,SOME(elsePart)),repl) equation
        elsePart2 = replaceWhenEquation(elsePart,repl);
        Exp.UNARY(Exp.UMINUS(tp),Exp.CREF(cr1,_)) = replaceExp(Exp.CREF(cr,Exp.OTHER()),repl,NONE);
        e1 = replaceExp(e, repl, NONE);
        e2 = Exp.simplify(Exp.UNARY(Exp.UMINUS(tp),e1));
    then DAELow.WHEN_EQ(i,cr1,e2,SOME(elsePart2));

  end matchcontinue;
end replaceWhenEquation;


public function replaceMultiDimEquations "function: replaceMultiDimEquations

  This function takes a list of equations ana a set of variable replacements
  and applies the replacements on all array equations.
  The function returns the updated list of array equations
"
  input list<DAELow.MultiDimEquation> inDAELowEquationLst;
  input VariableReplacements inVariableReplacements;
  output list<DAELow.MultiDimEquation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowEquationLst,inVariableReplacements)
    local
      Exp.Exp e1_1,e2_1,e1,e2,e_1,e,e1_2,e2_2;
      list<DAELow.MultiDimEquation> es_1,es;
      VariableReplacements repl;
      DAELow.Equation a;
      Exp.ComponentRef cr;
      list<Integer> dims;
    case ({},_) then {};
    case ((DAELow.MULTIDIM_EQUATION(left = e1,right = e2,dimSize = dims) :: es),repl)
      equation
        e1_1 = replaceExp(e1, repl, NONE);
        e2_1 = replaceExp(e2, repl, NONE);
        e1_2 = Exp.simplify(e1_1);
        e2_2 = Exp.simplify(e2_1);
        es_1 = replaceMultiDimEquations(es, repl);
      then
        (DAELow.MULTIDIM_EQUATION(dims,e1_2,e2_2) :: es_1);
  end matchcontinue;
end replaceMultiDimEquations;

protected function replaceEquationsStmts "function: replaceEquationsStmts

  Helper function to replace_equations
"
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input VariableReplacements inVariableReplacements;
  output list<Algorithm.Statement> outAlgorithmStatementLst;
algorithm
  outAlgorithmStatementLst:=
  matchcontinue (inAlgorithmStatementLst,inVariableReplacements)
    local
      Exp.Exp e_1,e;
      Exp.ComponentRef cr_1,cr;
      list<Algorithm.Statement> xs_1,xs;
      Exp.Type tp;
      VariableReplacements repl;
      Algorithm.Statement x;
    case ({},_) then {};
    case ((Algorithm.ASSIGN(type_ = tp,componentRef = cr,exp = e) :: xs),repl)
      equation
        e_1 = replaceExp(e, repl, NONE);
        Exp.CREF(cr_1,_) = replaceExp(Exp.CREF(cr,Exp.OTHER()), repl, NONE);
        xs_1 = replaceEquationsStmts(xs, repl);
      then
        (Algorithm.ASSIGN(tp,cr_1,e_1) :: xs_1);
    case ((x :: xs),repl)
      equation
        print("Warning, not implemented in replace_equations_stmts\n");
        xs_1 = replaceEquationsStmts(xs, repl);
      then
        (x :: xs_1);
  end matchcontinue;
end replaceEquationsStmts;

public function dumpReplacements "function: dumpReplacements

  Prints the variable replacements on form var1 -> var2
"
  input VariableReplacements inVariableReplacements;
algorithm
  _:=
  matchcontinue (inVariableReplacements)
    local
      list<Exp.Exp> srcs,dsts;
      list<String> srcstrs,dststrs,dststrs_1,strs;
      String str,len_str;
      Integer len;
      BinTree bt;
    case (REPLACEMENTS(src = bt))
      equation
        (srcs,dsts) = bintreeToExplist(bt);
        srcstrs = Util.listMap(srcs, Exp.printExpStr);
        dststrs = Util.listMap(dsts, Exp.printExpStr);
        dststrs_1 = Util.listMap1(dststrs, string_append, "\n");
        strs = Util.listThread(srcstrs, dststrs_1);
        str = Util.stringDelimitList(strs, " -> ");
        print("Replacements: (");
        len = listLength(srcs);
        len_str = intString(len);
        print(len_str);
        print(")\n");
        print("=============\n");
        print(str);
        print("\n");
      then
        ();
  end matchcontinue;
end dumpReplacements;

public function replacementSources "Returns all sources of the replacement rules"
  input VariableReplacements repl;
  output list<Exp.ComponentRef> sources;
algorithm
  sources := matchcontinue(repl)
  local list<Exp.Exp> srcs;
    BinTree bt;
    case (REPLACEMENTS(bt,_))
      equation
          (srcs,_) = bintreeToExplist(bt);
          sources = Util.listMap(srcs,Exp.expCref);
      then  sources;
  end matchcontinue;
end replacementSources;

public function replacementTargets "Returns all targets of the replacement rules"
  input VariableReplacements repl;
  output list<Exp.ComponentRef> sources;
algorithm
  sources := matchcontinue(repl)
  local
    list<Exp.Exp> targets;
    list<Exp.ComponentRef> targets2;
    BinTree bt;
    case (REPLACEMENTS(bt,_))
      equation
          (_,targets) = bintreeToExplist(bt);
          targets2 = Util.listFlatten(Util.listMap(targets,Exp.getCrefFromExp));
      then  targets2;
  end matchcontinue;
end replacementTargets;

public function addReplacement "function: addReplacement

  Adds a replacement rule to the set of replacement rules given as argument.
  If a replacement rule a->b already exists and we add a new rule b->c then
  the rule a->b is updated to a->c. This is done using the make_transitive
  function.
"
  input VariableReplacements repl;
  input Exp.ComponentRef inSrc;
  input Exp.Exp inDst;
  output VariableReplacements outRepl;
algorithm
  outRepl:=
  matchcontinue (repl,inSrc,inDst)
    local
      Exp.ComponentRef src,src_1,dst_1;
      Exp.Exp dst,dst_1,olddst;
      VariableReplacements repl;
      BinTree bt,bt_1;
      BinTree2 invbt,invbt_1;
      String s1,s2,s3,s4,s;
    case ((repl as REPLACEMENTS(src = bt,binTree2 = invbt)),src,dst) /* source dest */
      equation
        olddst = treeGet(bt, src) "if rule a->b exists, fail" ;
      then
        fail();
    case ((repl as REPLACEMENTS(src = bt,binTree2 = invbt)),src,dst)
      equation
        (REPLACEMENTS(bt,invbt),src_1,dst_1) = makeTransitive(repl, src, dst);
        s1 = Exp.printComponentRefStr(src);
        s2 = Exp.printExpStr(dst);
        s3 = Exp.printComponentRefStr(src_1);
        s4 = Exp.printExpStr(dst_1);
        s = Util.stringAppendList(
          {"add_replacement(",s1,", ",s2,") -> add_replacement(",s3,
          ", ",s4,")\n"});
          //print(s);
        Debug.fprint("addrepl", s);
        bt_1 = treeAdd(bt, src_1, dst_1);
        invbt_1 = addReplacementInv(invbt, src_1, dst_1);
      then
        REPLACEMENTS(bt_1,invbt_1);
    case (_,_,_)
      equation
        print("-add_replacement failed\n");
      then
        fail();
  end matchcontinue;
end addReplacement;

protected function addReplacementNoTransitive "Similar to addReplacement but
does not make transitive replacement rules.
"
  input VariableReplacements repl;
  input Exp.ComponentRef inSrc;
  input Exp.Exp inDst;
  output VariableReplacements outRepl;
algorithm
  outRepl:=
  matchcontinue (repl,inSrc,inDst)
    local
      Exp.ComponentRef src,src_1,dst_1;
      Exp.Exp dst,dst_1,olddst;
      VariableReplacements repl;
      BinTree bt,bt_1;
      BinTree2 invbt,invbt_1;
      String s1,s2,s3,s4,s;
    case ((repl as REPLACEMENTS(src = bt,binTree2 = invbt)),src,dst) /* source dest */
      equation
        olddst = treeGet(bt, src) "if rule a->b exists, fail" ;
      then
        fail();
    case ((repl as REPLACEMENTS(src = bt,binTree2 = invbt)),src,dst)
      equation
        bt_1 = treeAdd(bt, src, dst);
        invbt_1 = addReplacementInv(invbt, src, dst);
      then
        REPLACEMENTS(bt_1,invbt_1);
    case (_,_,_)
      equation
        print("-add_replacement failed\n");
      then
        fail();
  end matchcontinue;
end addReplacementNoTransitive;

protected function addReplacementInv "function: addReplacementInv

  Helper function to addReplacement
  Adds the inverse rule of a replacement to the second binary tree
  of VariableReplacements.
"
  input BinTree2 bt;
  input Exp.ComponentRef src;
  input Exp.Exp dst;
  output BinTree2 outBt;
algorithm
  outBt:=
  matchcontinue (bt,src,dst)
    local
      BinTree2 invbt_1,invbt;
      Exp.ComponentRef src;
      Exp.Exp dst;
      list<Exp.ComponentRef> dests;
    case (invbt,src,dst) equation
      dests = Exp.getCrefFromExp(dst);
      invbt_1 = Util.listFold_2(dests,addReplacementInv2,invbt,src);
      then
        invbt_1;
  end matchcontinue;
end addReplacementInv;

protected function addReplacementInv2 "function: addReplacementInv2

  Helper function to addReplacementInv
  Adds the inverse rule for one of the variables of a replacement to the second binary tree
  of VariableReplacements.
  Since a replacement is on the form var -> expression of vars(v1,v2,...,vn) the inverse binary tree
  contains rules for v1 -> var, v2 -> var, ...., vn -> var so that any of the variables of the expression
  will update the rule.
"
  input BinTree2 bt;
  input Exp.ComponentRef src;
  input Exp.ComponentRef dst;
  output BinTree2 outBt;
algorithm
  outBt:=
  matchcontinue (bt,src,dst)
    local
      BinTree2 invbt_1,invbt;
      Exp.ComponentRef src;
      Exp.ComponentRef dst;
      list<Exp.ComponentRef> srcs;
    case (invbt,src,dst)
      equation
        failure(_ = treeGet2(invbt, dst)) "No previous elt for dst -> src" ;
        invbt_1 = treeAdd2(invbt, dst, {src});
      then
        invbt_1;
    case (invbt,src,dst)
      equation
        srcs = treeGet2(invbt, dst) "previous elt for dst -> src, append.." ;
        invbt_1 = treeAdd2(invbt, dst, (src :: srcs));
      then
        invbt_1;
  end matchcontinue;
end addReplacementInv2;

protected function makeTransitive "function: makeTransitive

  This function takes a set of replacement rules and a new replacement rule
  in the form of two ComponentRef:s and makes sure the new replacement rule
  is replaced with the transitive value.
  For example, if we have the rule a->b and a new rule c->a it is changed to c->b.
  Also, if we have a rule a->b and a new rule b->c then the -old- rule a->b is changed
  to a->c.
  For arbitrary expressions: if we have a rule ax-> expr(b1,..,bn) and a new rule c->expr(a1,ax,..,an)
  it is changed to c-> expr(a1,expr(b1,...,bn),..,an).
  And similary for a rule ax -> expr(b1,bx,..,bn) and a new rule bx->expr(c1,..,cn) then old rule is changed to
  ax -> expr(b1,expr(c1,..,cn),..,bn).
"
  input VariableReplacements repl;
  input Exp.ComponentRef src;
  input Exp.Exp dst;
  output VariableReplacements outRepl;
  output Exp.ComponentRef outSrc;
  output Exp.Exp outDst;
algorithm
  (outRepl,outSrc,outDst):=
  matchcontinue (repl,src,dst)
    local
      VariableReplacements repl_1,repl_2,repl;
      Exp.ComponentRef src_1,src_2;
      Exp.Exp dst_1,dst_2,dst_3;
    case (repl,src,dst)
      equation
        (repl_1,src_1,dst_1) = makeTransitive1(repl, src, dst);
        (repl_2,src_2,dst_2) = makeTransitive2(repl_1, src_1, dst_1);
        dst_3 = Exp.simplify(dst_2) "to remove e.g. --a";
      then
        (repl_2,src_2,dst_3);
  end matchcontinue;
end makeTransitive;

protected function makeTransitive1 "function: makeTransitive1

  helper function to makeTransitive
"
  input VariableReplacements repl;
  input Exp.ComponentRef src;
  input Exp.Exp dst;
  output VariableReplacements outRepl;
  output Exp.ComponentRef outSrc;
  output Exp.Exp outDst;
algorithm
  (outRepl,outSrc,outDst):=
  matchcontinue (repl,src,dst)
    local
      list<Exp.ComponentRef> lst;
      VariableReplacements repl_1,repl,singleRepl;
      BinTree bt;
      BinTree2 invbt;
      Exp.Exp dst_1;
      // old rule a->expr(b1,..,bn) must be updated to a->expr(c_exp,...,bn) when new rule b1->c_exp
      // is introduced
    case ((repl as REPLACEMENTS(src = bt,binTree2 = invbt)),src,dst)
      equation
        lst = treeGet2(invbt, src);
        singleRepl = addReplacementNoTransitive(emptyReplacements(),src,dst);
        repl_1 = makeTransitive12(lst,repl,singleRepl);
      then
        (repl_1,src,dst);
    case (repl,src,dst) then (repl,src,dst);
  end matchcontinue;
end makeTransitive1;

protected function makeTransitive12 "Helper function to makeTransitive1
For each old rule a->expr(b1,..,bn) update dest by applying the new rule passed as argument
in singleRepl."
  input list<Exp.ComponentRef> lst;
  input VariableReplacements repl;
  input VariableReplacements singleRepl "contain one replacement rule: the rule to be added";
  output VariableReplacements outRepl;
algorithm
  outRepl := matchcontinue(lst,repl,singleRepl)
    local
      Exp.Exp crDst;
      Exp.ComponentRef cr;
      list<Exp.ComponentRef> crs;
      VariableReplacements repl1,repl2;
      BinTree bt;
      BinTree2 invbt;
    case({},repl,_) then repl;
    case(cr::crs,repl as REPLACEMENTS(src = bt,binTree2 = invbt),singleRepl) equation
      crDst = treeGet(bt,cr);
      crDst = replaceExp(crDst,singleRepl,NONE);
      repl1=addReplacementNoTransitive(repl,cr,crDst) "add updated old rule";
      repl2 = makeTransitive12(crs,repl1,singleRepl);
    then repl2;
  end matchcontinue;
end makeTransitive12;

protected function makeTransitive2 "function: makeTransitive2

  Helper function to makeTransitive
"
  input VariableReplacements repl;
  input Exp.ComponentRef src;
  input Exp.Exp dst;
  output VariableReplacements outRepl;
  output Exp.ComponentRef outSrc;
  output Exp.Exp outDst;
algorithm
  (outRepl,outSrc,outDst):=
  matchcontinue (repl,src,dst)
    local
      Exp.ComponentRef src,src_1;
      Exp.Exp newdst,dst_1,dst;
      VariableReplacements repl_1,repl;
      BinTree bt;
      BinTree2 invbt;
      // for rule a->b1+..+bn, replace all b1 to bn's in the expression;
    case ((repl as REPLACEMENTS(src = bt,binTree2 = invbt)),src,dst)
      equation
        (dst_1) = replaceExp(dst,repl,NONE);
      then
        (repl,src,dst_1);
        // replaceExp failed, keep old rule.
    case (repl,src,dst) then (repl,src,dst);  /* dst has no own replacement, return */
  end matchcontinue;
end makeTransitive2;

protected function addReplacements "function: addReplacements

  Adding of several replacements at once with common destination.
  Uses add_replacement
"
  input VariableReplacements repl;
  input list<Exp.ComponentRef> srcs;
  input Exp.Exp dst;
  output VariableReplacements outRepl;
algorithm
  outRepl:=
  matchcontinue (repl,srcs,dst)
    local
      VariableReplacements repl,repl_1,repl_2;
      Exp.ComponentRef src;
      list<Exp.ComponentRef> srcs;
    case (repl,{},_) then repl;
    case (repl,(src :: srcs),dst)
      equation
        repl_1 = addReplacement(repl, src, dst);
        repl_2 = addReplacements(repl_1, srcs, dst);
      then
        repl_2;
    case (_,_,_)
      equation
        print("add_replacements failed\n");
      then
        fail();
  end matchcontinue;
end addReplacements;

public function getReplacement "function: getReplacement

  Retrives a replacement variable given a set of replacement rules and a
  source variable.
"
  input VariableReplacements inVariableReplacements;
  input Exp.ComponentRef inComponentRef;
  output Exp.Exp outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVariableReplacements,inComponentRef)
    local
      Exp.ComponentRef src;
      Exp.Exp dst;
      BinTree bt;
      BinTree2 invbt;
    case (REPLACEMENTS(src = bt,binTree2 = invbt),src)
      equation
        dst = treeGet(bt, src);
      then
        dst;
  end matchcontinue;
end getReplacement;


protected function replaceExpOpt "Similar to replaceExp but takes Option<Exp> instead of Exp"
 input Option<Exp.Exp> inExp;
  input VariableReplacements repl;
  input Option<FuncTypeExp_ExpToBoolean> funcOpt;
  output Option<Exp.Exp> outExp;
  partial function FuncTypeExp_ExpToBoolean
    input Exp.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outExp := matchcontinue (inExp,repl,funcOpt)
  local Exp.Exp e;
    case(NONE(),_,_) then NONE();
    case(SOME(e),repl,funcOpt) equation
      e = replaceExp(e,repl,funcOpt);
    then SOME(e);
  end matchcontinue;
end replaceExpOpt;

public function replaceExp "function: replaceExp

  Takes a set of replacement rules and an expression and a function
  giving a boolean value for an expression.
  The function replaces all variables in the expression using
  the replacement rules, if the boolean value is true children of the
  expression is visited (including the expression itself). If it is false,
  no replacemet is performed.
"
  input Exp.Exp inExp;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  output Exp.Exp outExp;
  partial function FuncTypeExp_ExpToBoolean
    input Exp.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outExp:=
  matchcontinue (inExp,inVariableReplacements,inFuncTypeExpExpToBooleanOption)
    local
      Exp.ComponentRef cr_1,cr;
      Exp.Exp e,e1_1,e2_1,e1,e2,e3_1,e3,r_1,r;
      Exp.Type t,tp;
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
      Exp.Operator op;
      list<Exp.Exp> expl_1,expl;
      Absyn.Path path,p;
      Boolean c;
      Integer b,i;
      Absyn.CodeNode a;
      String id;
    case ((e as Exp.CREF(componentRef = cr,ty = t)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1 = getReplacement(repl, cr);
      then
        e1;
    case ((e as Exp.BINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        Exp.BINARY(e1_1,op,e2_1);
    case ((e as Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        Exp.LBINARY(e1_1,op,e2_1);
    case ((e as Exp.UNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        Exp.UNARY(op,e1_1);
    case ((e as Exp.LUNARY(operator = op,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        Exp.LUNARY(op,e1_1);
    case (Exp.RELATION(exp1 = e1,operator = op,exp2 = e2),repl,cond)
      equation
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        Exp.RELATION(e1_1,op,e2_1);
    case ((e as Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
        e3_1 = replaceExp(e3, repl, cond);
      then
        Exp.IFEXP(e1_1,e2_1,e3_1);
    case ((e as Exp.CALL(path = path,expLst = expl,tuple_ = t,builtin = c,ty=tp)),repl,cond)
      local Boolean t; Exp.Type tp;
      equation
        true = replaceExpCond(cond, e);
        expl_1 = Util.listMap2(expl, replaceExp, repl, cond);
      then
        Exp.CALL(path,expl_1,t,c,tp);
    case ((e as Exp.ARRAY(ty = tp,scalar = c,array = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        expl_1 = Util.listMap2(expl, replaceExp, repl, cond);
      then
        Exp.ARRAY(tp,c,expl_1);
    case ((e as Exp.MATRIX(ty = t,integer = b,scalar = expl)),repl,cond)
      local list<list<tuple<Exp.Exp, Boolean>>> expl_1,expl;
      equation
        true = replaceExpCond(cond, e);
        expl_1 = replaceExpMatrix(expl, repl, cond);
      then
        Exp.MATRIX(t,b,expl_1);
    case ((e as Exp.RANGE(ty = tp,exp = e1,expOption = NONE,range = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        Exp.RANGE(tp,e1_1,NONE,e2_1);
    case ((e as Exp.RANGE(ty = tp,exp = e1,expOption = SOME(e3),range = e2)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
        e3_1 = replaceExp(e3, repl, cond);
      then
        Exp.RANGE(tp,e1_1,SOME(e3_1),e2_1);
    case ((e as Exp.TUPLE(PR = expl)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        expl_1 = Util.listMap2(expl, replaceExp, repl, cond);
      then
        Exp.TUPLE(expl_1);
    case ((e as Exp.CAST(ty = tp,exp = e1)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        Exp.CAST(tp,e1_1);
    case ((e as Exp.ASUB(exp = e1,sub = i)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        Exp.ASUB(e1_1,i);
    case ((e as Exp.SIZE(exp = e1,sz = NONE)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
      then
        Exp.SIZE(e1_1,NONE);
    case ((e as Exp.SIZE(exp = e1,sz = SOME(e2))),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        e2_1 = replaceExp(e2, repl, cond);
      then
        Exp.SIZE(e1_1,SOME(e2_1));
    case (Exp.CODE(code = a,ty = b),repl,cond)
      local Exp.Type b;
      equation
        print("replace_exp on CODE not impl.\n");
      then
        Exp.CODE(a,b);
    case ((e as Exp.REDUCTION(path = p,expr = e1,ident = id,range = r)),repl,cond)
      equation
        true = replaceExpCond(cond, e);
        e1_1 = replaceExp(e1, repl, cond);
        r_1 = replaceExp(r, repl, cond);
      then
        Exp.REDUCTION(p,e1_1,id,r_1);
    case (e,repl,cond) then e;
  end matchcontinue;
end replaceExp;

protected function replaceExpCond "function replaceExpCond(cond,e) => true &

  Helper function to replace_exp. Evaluates a condition function if
  SOME otherwise returns true.
"
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  input Exp.Exp inExp;
  output Boolean outBoolean;
  partial function FuncTypeExp_ExpToBoolean
    input Exp.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outBoolean:=
  matchcontinue (inFuncTypeExpExpToBooleanOption,inExp)
    local
      Boolean res;
      FuncTypeExp_ExpToBoolean cond;
      Exp.Exp e;
    case (SOME(cond),e) /* cond e */
      equation
        res = cond(e);
      then
        res;
    case (NONE,_) then true;
  end matchcontinue;
end replaceExpCond;

protected function replaceExpMatrix "function: replaceExpMatrix
  author: PA

  Helper function to replace_exp, traverses Matrix expression list.
"
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  output list<list<tuple<Exp.Exp, Boolean>>> outTplExpExpBooleanLstLst;
  partial function FuncTypeExp_ExpToBoolean
    input Exp.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outTplExpExpBooleanLstLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariableReplacements,inFuncTypeExpExpToBooleanOption)
    local
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
      list<tuple<Exp.Exp, Boolean>> e_1,e;
      list<list<tuple<Exp.Exp, Boolean>>> es_1,es;
    case ({},repl,cond) then {};
    case ((e :: es),repl,cond)
      equation
        (e_1) = replaceExpMatrix2(e, repl, cond);
        (es_1) = replaceExpMatrix(es, repl, cond);
      then
        (e_1 :: es_1);
  end matchcontinue;
end replaceExpMatrix;

protected function replaceExpMatrix2 "function: replaceExpMatrix2
  author: PA

  Helper function to replace_exp_matrix
"
  input list<tuple<Exp.Exp, Boolean>> inTplExpExpBooleanLst;
  input VariableReplacements inVariableReplacements;
  input Option<FuncTypeExp_ExpToBoolean> inFuncTypeExpExpToBooleanOption;
  output list<tuple<Exp.Exp, Boolean>> outTplExpExpBooleanLst;
  partial function FuncTypeExp_ExpToBoolean
    input Exp.Exp inExp;
    output Boolean outBoolean;
  end FuncTypeExp_ExpToBoolean;
algorithm
  outTplExpExpBooleanLst:=
  matchcontinue (inTplExpExpBooleanLst,inVariableReplacements,inFuncTypeExpExpToBooleanOption)
    local
      list<tuple<Exp.Exp, Boolean>> es_1,es;
      Exp.Exp e_1,e;
      Boolean b;
      VariableReplacements repl;
      Option<FuncTypeExp_ExpToBoolean> cond;
    case ({},_,_) then {};
    case (((e,b) :: es),repl,cond)
      equation
        (es_1) = replaceExpMatrix2(es, repl, cond);
        (e_1) = replaceExp(e, repl, cond);
      then
        ((e_1,b) :: es_1);
  end matchcontinue;
end replaceExpMatrix2;

protected function bintreeToExplist "function: bintree_to_list

  This function takes a BinTree and transform it into a list
  representation, i.e. two lists of keys and values
"
  input BinTree inBinTree;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inBinTree)
    local
      list<Exp.Exp> klst,vlst;
      BinTree bt;
    case (bt)
      equation
        (klst,vlst) = bintreeToExplist2(bt, {}, {});
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToExplist;

protected function bintreeToExplist2 "function: bintree_to_list2

  helper function to bintree_to_list
"
  input BinTree inBinTree1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inBinTree1,inExpExpLst2,inExpExpLst3)
    local
      list<Exp.Exp> klst,vlst;
      Exp.ComponentRef key;
      Exp.Exp value;
      Option<BinTree> left,right;
    case (TREENODE(value = NONE,left = NONE,right = NONE),klst,vlst) then (klst,vlst);
    case (TREENODE(value = SOME(TREEVALUE(key,value)),left = left,right = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
        (klst,vlst) = bintreeToExplistOpt(right, klst, vlst);
      then
        ((Exp.CREF(key,Exp.REAL()) :: klst),(value :: vlst));
    case (TREENODE(value = NONE,left = left,right = right),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
        (klst,vlst) = bintreeToExplistOpt(left, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToExplist2;

protected function bintreeToExplistOpt "function: bintree_to_list_opt

  helper function to bintree_to_list
"
  input Option<BinTree> inBinTreeOption1;
  input list<Exp.Exp> inExpExpLst2;
  input list<Exp.Exp> inExpExpLst3;
  output list<Exp.Exp> outExpExpLst1;
  output list<Exp.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2):=
  matchcontinue (inBinTreeOption1,inExpExpLst2,inExpExpLst3)
    local
      list<Exp.Exp> klst,vlst;
      BinTree bt;
    case (NONE,klst,vlst) then (klst,vlst);
    case (SOME(bt),klst,vlst)
      equation
        (klst,vlst) = bintreeToExplist2(bt, klst, vlst);
      then
        (klst,vlst);
  end matchcontinue;
end bintreeToExplistOpt;

protected function treeGet "function: treeGet

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need to
  compare two strings to get a unique ordering.
"
  input BinTree inBinTree;
  input Key inKey;
  output Value outValue;
algorithm
  outValue:=
  matchcontinue (inBinTree,inKey)
    local
      String rkeystr,keystr;
      Exp.ComponentRef rkey,key;
      Exp.Exp rval,res;
      Option<BinTree> left,right;
      Integer cmpval;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = right),key)
      equation
        rkeystr = Exp.printComponentRefStr(rkey);
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        rval;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = SOME(right)),key)
      local BinTree right;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the right" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        res = treeGet(right, key);
      then
        res;
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = SOME(left),right = right),key)
      local BinTree left;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the left" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        res = treeGet(left, key);
      then
        res;
  end matchcontinue;
end treeGet;

protected function treeAdd "function: treeAdd

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int.
  Therefore we need to compare two strings to get a unique ordering.
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
      Exp.Exp value,rval;
      String rkeystr,keystr;
      Option<BinTree> left,right;
      Integer cmpval;
      BinTree t_1,t,right_1,left_1;
    case (TREENODE(value = NONE,left = NONE,right = NONE),key,value) then TREENODE(SOME(TREEVALUE(key,value)),NONE,NONE);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = right),key,value)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "Replace this node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE(SOME(TREEVALUE(rkey,value)),left,right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = (right as SOME(t))),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(t_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = left,right = (right as NONE)),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd(TREENODE(NONE,NONE,NONE), key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),left,SOME(right_1));
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = (left as SOME(t)),right = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to left subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd(t, key, value);
      then
        TREENODE(SOME(TREEVALUE(rkey,rval)),SOME(t_1),right);
    case (TREENODE(value = SOME(TREEVALUE(rkey,rval)),left = (left as NONE),right = right),key,value)
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

protected function treeGet2 "function: treeGet2

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string can not be uniquely mapped to an int. Therefore we need
  to compare two strings to get a unique ordering.
"
  input BinTree2 inBinTree2;
  input Key inKey;
  output Value2 outValue2;
algorithm
  outValue2:=
  matchcontinue (inBinTree2,inKey)
    local
      String rkeystr,keystr;
      Exp.ComponentRef rkey,key;
      list<Exp.ComponentRef> rval,res;
      Option<BinTree2> left,right;
      Integer cmpval;
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = right),key)
      equation
        rkeystr = Exp.printComponentRefStr(rkey);
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        rval;
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = SOME(right)),key)
      local BinTree2 right;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the right" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        res = treeGet2(right, key);
      then
        res;
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = SOME(left),right = right),key)
      local BinTree2 left;
      equation
        keystr = Exp.printComponentRefStr(key) "Search to the left" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        res = treeGet2(left, key);
      then
        res;
  end matchcontinue;
end treeGet2;

protected function treeAdd2 "function: treeAdd2

  Copied from generic implementation. Changed that no hashfunction is passed
  since a string (ComponentRef) can not be uniquely mapped to an int.
  Therefore we need to compare two strings to get a unique ordering.
"
  input BinTree2 inBinTree2;
  input Key inKey;
  input Value2 inValue2;
  output BinTree2 outBinTree2;
algorithm
  outBinTree2:=
  matchcontinue (inBinTree2,inKey,inValue2)
    local
      Exp.ComponentRef key,rkey;
      list<Exp.ComponentRef> value,rval;
      String rkeystr,keystr;
      Option<BinTree2> left,right;
      Integer cmpval;
      BinTree2 t_1,t,right_1,left_1;
    case (TREENODE2(value = NONE,left = NONE,right = NONE),key,value) then TREENODE2(SOME(TREEVALUE2(key,value)),NONE,NONE);
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = right),key,value)
      equation
        rkeystr = Exp.printComponentRefStr(rkey) "Replace this node" ;
        keystr = Exp.printComponentRefStr(key);
        0 = System.strcmp(rkeystr, keystr);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,value)),left,right);
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = (right as SOME(t))),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        t_1 = treeAdd2(t, key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),left,SOME(t_1));
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = left,right = (right as NONE)),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to right node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = true;
        right_1 = treeAdd2(TREENODE2(NONE,NONE,NONE), key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),left,SOME(right_1));
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = (left as SOME(t)),right = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to left subtree" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        t_1 = treeAdd2(t, key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),SOME(t_1),right);
    case (TREENODE2(value = SOME(TREEVALUE2(rkey,rval)),left = (left as NONE),right = right),key,value)
      equation
        keystr = Exp.printComponentRefStr(key) "Insert to left node" ;
        rkeystr = Exp.printComponentRefStr(rkey);
        cmpval = System.strcmp(rkeystr, keystr);
        (cmpval > 0) = false;
        left_1 = treeAdd2(TREENODE2(NONE,NONE,NONE), key, value);
      then
        TREENODE2(SOME(TREEVALUE2(rkey,rval)),SOME(left_1),right);
    case (_,_,_)
      equation
        print("tree_add2 failed\n");
      then
        fail();
  end matchcontinue;
end treeAdd2;
end VarTransform;

