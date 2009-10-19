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

package Patternm
" file:	       Patternm.mo
  package:     Patternm
  description: Patternmatching

  RCS: $Id$

  This module contains the patternmatch algorithm for the MetaModelica
  matchcontinue expression."

public import Absyn;
public import DFA;
public import Env;
public import SCode;
public import Debug;
public import Dump;

protected import Lookup;
protected import Util;

//Some type simplifications
type RenamedPat = DFA.RenamedPat;
type RenamedPatVec = DFA.RenamedPatVec;
type RenamedPatList = list<DFA.RenamedPat>;
type RenamedPatMatrix = DFA.RenamedPatMatrix;
type RenamedPatMatrix2 = DFA.RenamedPatMatrix2;
type RightHandVector = DFA.RightHandVector;
type RightHandList = DFA.RightHandList;
type RightHandSide = DFA.RightHandSide;
type IndexVector = DFA.IndexVector;
type AsList = list<Absyn.EquationItem>;
type AsArray = AsList[:];
type ArcName = Absyn.Ident;

protected function ASTtoMatrixForm "function: ASTtoMatrixForm
	author: KS
 	Transforms the Abstract Syntax Tree of a matchcontinue expression into matrix form.
 	The patterns in each case-branch ends up in a matrix and all the right-hand sides
 	ends up in a list/vector. The match algorithm uses these data structures when
 	generating the DFA. A right-hand side is simply the code occuring after
	the case keyword: local Integer i; ... equation ... then 3*3;
"
  input Absyn.Exp matchCont; // The matchcontinue expression
  input Env.Cache cache; // The renameMain function will need these two
  input Env.Env env; // when transforming named arguments in a function call into positional once
  output Env.Cache outCache;
  output list<Absyn.Exp> outVarList; // The input variables (in exp form), matchcontinue (var1,var2,var3,...)
  output list<Absyn.ElementItem> outDeclList; // The local declarations, matchcontinue (...) local Integer i; Real r; ... case() ...
  output RightHandList rhVec; // The righthand side vector
  output RightHandList rhLight; // This one is used in the pattern matching. It is a simplified version of rhVec.
  output RenamedPatMatrix pMat; // The matrix with renamed patterns (renaming means adding a path variable to each pattern)
  output Option<RightHandSide> outElseRhSide; // An optional else case
algorithm
  (outCache,outVarList,outDeclList,rhVec,rhLight,pMat,outElseRhSide) :=
  matchcontinue (matchCont,cache,env)
    case (localMatchCont as (Absyn.MATCHEXP(_,varList2,declList,localCases,_)),localCache,localEnv)
      local
        Absyn.Exp localMatchCont;
        RightHandList rhsList,rhsListLight; // RhsListLight is a simplified version of rhsList
        list<Absyn.Exp> patList,varList;
        Absyn.Exp varList2; // The input variables to the matchcontinue expression
        RenamedPatMatrix patMat;
        list<Absyn.ElementItem> declList; // The local variable declarations at the begining of the matchc. exp
        Integer varListLength;
        Option<RightHandSide> elseRhSide; // Used to store the optional else-case of the match. exp
        AsArray asBindings; // Array used for the as constructs, case (var as 3,...)
        list<Absyn.Case> localCases;
        Env.Cache localCache;
        Env.Env localEnv;
      equation
        // Extract from matchcontinue Abstract Syntax Tree
        (localCache,rhsList,rhsListLight,patList,elseRhSide) = extractFromMatchAST(localCases,{},{},{},1,localCache,localEnv);
        varList = extractListFromTuple(varList2,0);
        varListLength = listLength(varList);

        false = (varListLength == 0); // If there are no input variables, the function will fail

        // Create pattern matrix. The as-bindings (  ... case (var1 as 3) ...)
        // are first collected in the fillMatrix function and then
        // assignments of these variables are added to the RightHandSide list
        patMat = fill({},varListLength);
        asBindings = fill({},listLength(rhsList));
        (localCache,patMat,asBindings,_) =
        fillMatrix(1,asBindings,varList,patList,patMat,localCache,localEnv,(1,{}));
        rhsList = addAsBindings(rhsList,arrayList(asBindings));	 // Add the as-bindings (assignments)
                                                                 // to the right hand-sides.

      then (localCache,varList,declList,rhsList,rhsListLight,patMat,elseRhSide);
    case (exp,_,_) local Absyn.Exp exp; String expStr;
      equation
        expStr = Dump.printExpStr(exp);
        Debug.fprintln("matchcase", "- Patternm.ASTtoMatrixForm failed, non-matching patterns in matchcase or zero input variables: " +& expStr);
      then fail();
  end matchcontinue;
end ASTtoMatrixForm;


protected function extractListFromTuple "function: extractListFromTuple
	author: KS
 Given an Absyn.Exp, this function will extract the list of expressions if the
 expression is a tuple, otherwise a list of length one is created"
  input Absyn.Exp inExp;
  input Integer numOfExps;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (inExp,numOfExps)
    case(Absyn.TUPLE(l),1)
      local
        list<Absyn.Exp> l;
      equation
      then {Absyn.TUPLE(l)};
    case(Absyn.TUPLE(l),_)
      local
        list<Absyn.Exp> l;
      equation
      then l;
    case(exp,_)
      local
        Absyn.Exp exp;
      equation
      then {exp};
  end matchcontinue;
end extractListFromTuple;


protected function addAsBindings "function: addAsBindings
	author: KS
	This function will add all the collected as-bindings to a list of
	right-hand sides. A right-hand side is simply the code occuring after
	the case keyword: local Integar i; ... equation ... then 3*3;
	As-binding example:
	v := matchcontinue (inInteger)
  	   case (v2 as 4) local Integer v2; equation ... then 2;
  	   ...
	end matchcontinue;
	A new assignment, v2 = pathVariable, will be added to the equation
	section. Note that each pattern has a corresponding path variable.
"
  input RightHandList rhList;
  input list<AsList> asBinds;
  output RightHandList outRhs;
algorithm
  outRhs :=
  matchcontinue (rhList,asBinds)
    case ({},{}) equation then {};
    case (first1 :: rest1,first2 :: rest2)
      local
        RightHandSide first1;
        RightHandList rest1,rhsList;
        AsList first2;
        list<AsList> rest2;
      equation
        first1 = addAsBindingsHelper(first1,first2);
        rhsList = addAsBindings(rest1,rest2);
        rhsList = listAppend({first1},rhsList);
      then rhsList;
    case (_, _)
      equation
        Debug.fprintln("matchcase", "- Patternm.addAsBindings failed");
      then fail();
  end matchcontinue;
end addAsBindings;

protected function addAsBindingsHelper "function: addAsBindingsHelper
	author: KS
	Helper function to addAsBindings"
  input RightHandSide rhSide;
  input AsList asList;
  output RightHandSide rhSideOut;
algorithm
  rhSideOut :=
  matchcontinue (rhSide,asList)
    case (localRhSide,{})
      local
        RightHandSide localRhSide;
      equation
      then localRhSide;
    case (DFA.RIGHTHANDSIDE(localDecls,eqs,result,cNumber),localAsList)
      local
        list<Absyn.ElementItem> localDecls;
        list<Absyn.EquationItem> eqs;
        Absyn.Exp result;
        RightHandSide rhS;
        AsList localAsList;
        Integer cNumber;
      equation
        eqs = listAppend(localAsList,eqs);
        rhS = DFA.RIGHTHANDSIDE(localDecls,eqs,result,cNumber);
      then rhS;
  end matchcontinue;
end addAsBindingsHelper;


protected function extractFromMatchAST "function: extractFromMatchAST
	author: KS
	Extract righthand sides, patterns and optional else-case from matchcontinue
	AST.
"
  input list<Absyn.Case> matchCases;
  input RightHandList rhListIn;
  input RightHandList rhListLightIn;
  input list<Absyn.Exp> patListIn; // All the patterns are collected in a list.
  input Integer caseNumber;  // This variable keeps track of which case-clause we are working with
  input Env.Cache cache;
  input Env.Env env;
  output Env.Cache outCache;
  output RightHandList rhListOut;
  output RightHandList rhListLightOut;
  output list<Absyn.Exp> patListOut; // All the patterns are collected in a list.
  output Option<RightHandSide> elseRhSide; // A matchcontinue expression may contain an else-case
algorithm
  (outCache,rhListOut,rhListLightOut,patListOut,elseRhSide) :=
  matchcontinue (matchCases,rhListIn,rhListLightIn,patListIn,caseNumber,cache,env)
    local
      list<Absyn.Case> rest;
      Absyn.Exp localPat,localRes;
      list<Absyn.ElementItem> localDecl;
      list<Absyn.EquationItem> localEq;
      Env.Cache localCache,var1;
      Env.Env localEnv;

      // var1,var2,var3,var4,var5 are temp variables
      list<Absyn.Exp> localPatListIn,var4;
      RightHandList localRhListIn,localRhLightList,var2,var3;
      Option<RightHandSide> var5;
      Integer localCaseNum;
    case ({},localRhListIn,localRhLightList,localPatListIn,_,localCache,_) equation then (localCache,localRhListIn,localRhLightList,localPatListIn,NONE());
    case (Absyn.CASE(localPat,localDecl,localEq,localRes,_) :: rest,
      localRhListIn,localRhLightList,localPatListIn,localCaseNum,localCache,localEnv)
      equation
        localPatListIn = listAppend(localPatListIn,{localPat});
        localRhListIn = listAppend(localRhListIn,{DFA.RIGHTHANDSIDE(localDecl,localEq,localRes,localCaseNum)});
        localRhLightList = listAppend(localRhLightList,{DFA.RIGHTHANDLIGHT(localCaseNum)});
        localCaseNum = localCaseNum + 1;
        (var1,var2,var3,var4,var5) = extractFromMatchAST(rest,localRhListIn,localRhLightList,localPatListIn,localCaseNum,localCache,localEnv);
      then (var1,var2,var3,var4,var5);
    case (Absyn.ELSE(localDecl,localEq,localRes,_) :: {},localRhListIn,localRhLightList,localPatListIn,_,localCache,localEnv)
      then (localCache,localRhListIn,localRhLightList,localPatListIn,SOME(DFA.RIGHTHANDSIDE(localDecl,localEq,localRes,0)));
    case (cas :: _,_,_,_,_,_,_)
      local Absyn.Case cas; String casStr;
      equation
        casStr = Dump.printCaseStr(cas);
        Debug.fprintln("matchcase", "- Patternm.extractFromMatchAST failed: " +& casStr);
      then fail();
  end matchcontinue;
end extractFromMatchAST;


protected function fillMatrix "function: fillMatrix
	author: KS
	Fill the matrix with renamed patterns (patterns of the form path=pattern, where
	path is a path-variable and pattern is a renamed expression)
"
  input Integer rowNum;
  input AsArray inAsBindings; // List/vector used for the as-construct in Absyn.Exp
  input list<Absyn.Exp> varList; // The matchcontinue input variable list
  input list<Absyn.Exp> patList; // The unrenamed patterns, no path variable added yet
  input RenamedPatMatrix patMat; // The matrix containg the renamed patterns
  input Env.Cache cache;
  input Env.Env env;
  input tuple<Integer,list<tuple<Absyn.Ident,Integer>>> inConstTagEnv;
  output Env.Cache outCache;
  output RenamedPatMatrix outPatMat;
  output AsArray outAsBindings;
  output tuple<Integer,list<tuple<Absyn.Ident,Integer>>> outConstTagEnv;
algorithm
  (outCache,outPatMat,outAsBindings,outConstTagEnv) :=
  matchcontinue (rowNum,inAsBindings,varList,patList,patMat,cache,env,inConstTagEnv)
    local
      RenamedPatMatrix localPatMat;
      Absyn.Exp first2;
      list<Absyn.Exp> first,rest,localVarList;
      AsArray localAsBindings;
      Integer localRowNum;
      tuple<Integer,list<tuple<Absyn.Ident,Integer>>> localConstTagEnv;
    case (_,localAsBindings,_,{},localPatMat,localCache,_,localConstTagEnv)
      local
        Env.Cache localCache;
      equation
      then (localCache,localPatMat,localAsBindings,localConstTagEnv);
    case (localRowNum,localAsBindings,localVarList,first2 :: rest,
        localPatMat,localCache,localEnv,localConstTagEnv)
      local
        AsList asBinds;
        Integer len1,len2;
        //Temp variables
        RenamedPatMatrix temp2;
        AsArray temp4;

        Env.Env localEnv;
        Env.Cache localCache;
        Integer i;
      equation
        i = listLength(localVarList);
        first = extractListFromTuple(first2,i);

        // Add a row to the matrix, rename each pattern as well
        (localCache,localPatMat,asBinds,localConstTagEnv) = addRow({},localVarList,1,first,
          localPatMat,localCache,localEnv,localConstTagEnv);

        len1 = listLength(first);
        len2 = listLength(localVarList);
        true = (len1 == len2); // The number of input variables, matchcontinue (var1,var2,...), must be
                               // the same as the number of patterns in each case

        // Store As-construct bindings for this row
        localAsBindings = arrayUpdate(localAsBindings, localRowNum, asBinds);

        // Add the rest of the rows to the matrix
        (localCache,temp2,temp4,localConstTagEnv) =
        fillMatrix(localRowNum+1,localAsBindings,localVarList,rest,localPatMat,
          localCache,localEnv,localConstTagEnv);
      then (localCache,temp2,temp4,localConstTagEnv);
    case (_,_,_,e :: _,_,_,_,_)  local Absyn.Exp e; String str;
      equation
        str = Dump.printExpStr(e);
        Debug.fprintln("matchcase", "- fillMatrix failed: " +& str);
      then fail();
  end matchcontinue;
end fillMatrix;

protected function addRow "function: addRow
	author: KS
 	Adds a row to the matrix.
 	This is done by adding one element at a time to the matrix row
"
  input AsList asBindings; // Used to store AS construct bindings
  input list<Absyn.Exp> varList; // Input variable list
  input Integer pivot; // Position in the row
  input list<Absyn.Exp> pats; // The patterns to be stored in the row
  input RenamedPatMatrix patMat;
  input Env.Cache cache;
  input Env.Env env;
  input tuple<Integer,list<tuple<Absyn.Ident,Integer>>> inConstTagEnv;
  output Env.Cache outCache;
  output RenamedPatMatrix outPatMat;
  output AsList outAsBinds;
  output tuple<Integer,list<tuple<Absyn.Ident,Integer>>> outConstTagEnv;
algorithm
  (outCache,outPatMat,outAsBinds,outConstTagEnv) :=
  matchcontinue (asBindings,varList,pivot,pats,patMat,cache,env,inConstTagEnv)
    local
      Integer localPivot;
      Absyn.Exp firstPat;
      list<Absyn.Exp> restPat,restVar;
      RenamedPatMatrix localPatMat;
      Absyn.Ident firstVar;
      list<tuple<Absyn.Ident,Absyn.Ident>> localVars;
      Integer localRowNum;
      AsList localAsBindings;
      Env.Cache localCache;
      Env.Env localEnv;
      tuple<Integer,list<tuple<Absyn.Ident,Integer>>> localConstTagEnv;
    case (localAsBindings,_,_,{},localPatMat,localCache,_,localConstTagEnv)
      equation
      then (localCache,localPatMat,localAsBindings,localConstTagEnv);
    case(localAsBindings,Absyn.CREF(cRef) :: restVar,localPivot,firstPat :: restPat,
        localPatMat,localCache,localEnv,localConstTagEnv)
      local
        RenamedPat pat;
        list<Absyn.Ident> localPathVars2;
        AsList asBinds;
        String str;
        Absyn.ComponentRef cRef;

        //Temp variables
        RenamedPatMatrix temp2;
        AsList temp4;
        RenamedPatList temp5;
      equation
        str = "";
        firstVar = Absyn.pathString(Absyn.crefToPath(cRef));

        //Rename a pattern, that is, transform it into path=pattern form
        (localCache,pat,asBinds,localConstTagEnv) =
        renameMain(firstPat,stringAppend(str,firstVar),{},localCache,localEnv,localConstTagEnv);
        localAsBindings = listAppend(localAsBindings,asBinds);

         // Store the new element in matrix
        temp5 = listAppend(localPatMat[localPivot],{pat});
        localPatMat = arrayUpdate(localPatMat, localPivot, temp5);

        //Add the rest of the elements for this row
        (localCache,temp2,temp4,localConstTagEnv) = addRow(localAsBindings,restVar,localPivot+1,restPat,
        localPatMat,localCache,localEnv,localConstTagEnv);
      then (localCache,temp2,temp4,localConstTagEnv);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln("matchcase", "- Patternm.addRow failed");
      then fail();
  end matchcontinue;
end addRow;


protected function renameMain "function: renameMain
 	author: KS
 	Input is an Absyn.Exp (corresponding to a pattern) and a root variable.
 	The function transforms the pattern into path=pattern form (DFA.RenamedPat).
 	As a side effect we also collect the As-bindings.
"
  input Absyn.Exp pat;
  input Absyn.Ident rootVar;
  input AsList inAsBinds;
  input Env.Cache cache;
  input Env.Env env;
  input tuple<Integer,list<tuple<Absyn.Ident,Integer>>> inConstTagEnv;
  output Env.Cache outCache;
  output RenamedPat renamedPat;
  output AsList outAsBinds; // New as-bindings are added in the as-pattern case
  output tuple<Integer,list<tuple<Absyn.Ident,Integer>>> outConstTagEnv;
algorithm
  (outCache,renamedPat,outAsBinds,outConstTagEnv) :=
  matchcontinue (pat,rootVar,inAsBinds,cache,env,inConstTagEnv)
    local
      Absyn.Exp localPat;
      Absyn.Ident localVar,localVar2;
      list<tuple<Absyn.Ident,Absyn.Ident>> localVars;
      AsList localAsBinds,localAsBinds2;
      Env.Cache localCache;
      Env.Env localEnv;
      tuple<Integer,list<tuple<Absyn.Ident,Integer>>> localConstTagEnv;
      // INTEGER EXPRESSION
    case (Absyn.INTEGER(val),localVar,localAsBinds,localCache,_,localConstTagEnv)
      local
        Integer val;
        RenamedPat tempPat;
      equation
        tempPat = DFA.RP_INTEGER(localVar,val);
      then (localCache,tempPat,localAsBinds,localConstTagEnv);
        // REAL EXPRESSION
    case (Absyn.REAL(val),localVar,localAsBinds,localCache,_,localConstTagEnv)
      local
        Real val;
        RenamedPat tempPat;
      equation
        tempPat = DFA.RP_REAL(localVar,val);
      then (localCache,tempPat,localAsBinds,localConstTagEnv);
        // BOOLEAN EXPRESSION
    case (Absyn.BOOL(val),localVar,localAsBinds,localCache,_,localConstTagEnv)
      local
        Boolean val;
        RenamedPat tempPat;
      equation
        tempPat = DFA.RP_BOOL(localVar,val);
      then (localCache,tempPat,localAsBinds,localConstTagEnv);
        // WILDCARD EXPRESSION
    case (Absyn.CREF(Absyn.WILD()),localVar,localAsBinds,localCache,_,localConstTagEnv)
      local
        RenamedPat tempPat;
      equation
        tempPat = DFA.RP_WILDCARD(localVar);
      then (localCache,tempPat,localAsBinds,localConstTagEnv);
        // STRING EXPRESSION
    case (Absyn.STRING(val),localVar,localAsBinds,localCache,_,localConstTagEnv)
      local
        String val;
        RenamedPat pat;
      equation
        pat = DFA.RP_STRING(localVar,val);
      then (localCache,pat,localAsBinds,localConstTagEnv);
        // AS BINDINGS
        // An as-binding is collected as an equation assignment. This assigment will later be
        // added to the correspond righthand side.
    case (Absyn.AS(var,expr),localVar,localAsBinds,localCache,localEnv,localConstTagEnv)
      local
        Absyn.Exp expr,lhs,rhs;
        Absyn.Ident var;

        // Temp variables
        RenamedPat temp1;
        AsList temp3;
      equation
        lhs = Absyn.CREF(Absyn.CREF_IDENT(var,{}));
        rhs = Absyn.CREF(Absyn.CREF_IDENT(localVar,{}));
        localAsBinds2 = {Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(lhs,rhs),NONE())};
        localAsBinds = listAppend(localAsBinds,localAsBinds2);

        (localCache,temp1,temp3,localConstTagEnv) = renameMain(expr,localVar,localAsBinds,localCache,localEnv,localConstTagEnv);
      then (localCache,temp1,temp3,localConstTagEnv);

        // NONE EXPRESSION
    case (Absyn.CREF(Absyn.CREF_IDENT("NONE",_)),localVar,localAsBinds,localCache,localEnv,localConstTagEnv)
    then (localCache,DFA.RP_NONE(localVar),localAsBinds,localConstTagEnv);

        // COMPONENT REFERENCE EXPRESSION
        // Will be interpretated as: case (var AS _)
        // This expression is transformed into a wildcard but we store the variable
        // reference as well as an AS-binding.
    case (Absyn.CREF(cr),localVar,localAsBinds,localCache,_,localConstTagEnv)
      local
        Absyn.Ident var;
        RenamedPat pat;
        Absyn.ComponentRef cr;
        Absyn.Exp rhs;
      equation
        rhs = Absyn.CREF(Absyn.CREF_IDENT(localVar,{}));
        localAsBinds2 = {Absyn.EQUATIONITEM(Absyn.EQ_EQUALS(Absyn.CREF(cr),rhs),NONE())};
        localAsBinds = listAppend(localAsBinds,localAsBinds2);

        pat = DFA.RP_WILDCARD(localVar);
      then (localCache,pat,localAsBinds,localConstTagEnv);

        // TUPLE EXPRESSION
        // This is a builtin functioncall, all the function arguments are renamed
    case (Absyn.TUPLE(funcArgs),localVar,localAsBinds,localCache,localEnv,localConstTagEnv)
      local
        list<Absyn.Exp> funcArgs;
        RenamedPatList renamedPatList;
        RenamedPat pat,first2,second2;
        AsList localAsBinds2;
        Integer constTag;
      equation
        (constTag,localConstTagEnv) = getUniqueConstTag(Absyn.IDENT("TUPLE"),localConstTagEnv);
        localVar2 = stringAppend(localVar,"_");
        localVar2 = stringAppend(localVar2,intString(constTag));

        (localCache,renamedPatList,localAsBinds2,localConstTagEnv) = renamePatList(funcArgs
          ,localVar2,1,{},{},localCache,localEnv,localConstTagEnv);

        pat = DFA.RP_TUPLE(localVar,renamedPatList);

      then (localCache,pat,listAppend(localAsBinds,localAsBinds2),localConstTagEnv);

        // CONS EXPRESSION
        // This is a builtin functioncall, all the function arguments are renamed
    case (Absyn.CONS(first,second),localVar,localAsBinds,localCache,localEnv,localConstTagEnv)
      local
        Absyn.Exp first,second;
        RenamedPatList renamedPatList;
        RenamedPat pat,first2,second2;
        AsList localAsBinds2;
        Integer constTag;
      equation
        (constTag,localConstTagEnv) = getUniqueConstTag(Absyn.IDENT("CONS"),localConstTagEnv);
        localVar2 = stringAppend(localVar,"_");
        localVar2 = stringAppend(localVar2,intString(constTag));

        (localCache,renamedPatList,localAsBinds2,localConstTagEnv) = renamePatList({first,second}
          ,localVar2,1,{},{},localCache,localEnv,localConstTagEnv);
        first2 = Util.listFirst(renamedPatList);
        second2 = Util.listFirst(Util.listRest(renamedPatList));

        pat = DFA.RP_CONS(localVar,first2,second2);

      then (localCache,pat,listAppend(localAsBinds,localAsBinds2),localConstTagEnv);

        // NONE EXPRESSION
    case (Absyn.CALL(Absyn.CREF_IDENT("NONE",_),Absyn.FUNCTIONARGS({},{})),localVar,
        localAsBinds,localCache,localEnv,localConstTagEnv)
         then (localCache,DFA.RP_NONE(localVar),localAsBinds,localConstTagEnv);

      // SOME EXPRESSION
    case (Absyn.CALL(Absyn.CREF_IDENT("SOME",_),Absyn.FUNCTIONARGS(first :: _,{})),localVar,
        localAsBinds,localCache,localEnv,localConstTagEnv)
      local
        Absyn.Exp first;
        RenamedPatList renamedPatList;
        RenamedPat pat,first2;
        AsList localAsBinds2;
        Integer constTag;
      equation
        (constTag,localConstTagEnv) = getUniqueConstTag(Absyn.IDENT("SOME"),localConstTagEnv);
        localVar2 = stringAppend(localVar,"_");
        localVar2 = stringAppend(localVar2,intString(constTag));

        (localCache,renamedPatList,localAsBinds2,localConstTagEnv) = renamePatList({first}
          ,localVar2,1,{},{},localCache,localEnv,localConstTagEnv);
        first2 = Util.listFirst(renamedPatList);

        pat = DFA.RP_SOME(localVar,first2);

      then (localCache,pat,listAppend(localAsBinds,localAsBinds2),localConstTagEnv);

        // CALL EXPRESSION - translates pos/named args into only pos ones
    case (Absyn.CALL(compRef,Absyn.FUNCTIONARGS(funcArgs,namedArgList)),
        localVar,localAsBinds,localCache,localEnv,localConstTagEnv)
      local
        Absyn.ComponentRef compRef;
        list<Absyn.Exp> funcArgs;
        list<Absyn.NamedArg> namedArgList;
        RenamedPatList renamedPatList;
        RenamedPat pat;
        AsList localAsBinds2;
        Absyn.Path recName;
        SCode.Class sClass;
        Absyn.Path pathName;
        list<Absyn.Ident> fieldNameList, fieldNamesPos, fieldNamesNamed;
        list<Absyn.Exp> funcArgs, funcArgsNamedFixed;
        Integer constTag, numPosArgs;
      equation
        recName = Absyn.crefToPath(compRef);

        (constTag,localConstTagEnv) = getUniqueConstTag(recName,localConstTagEnv);
        localVar2 = stringAppend(localVar,"_");
        localVar2 = stringAppend(localVar2,intString(constTag));

        // Fetch the names of the fields
        (localCache,sClass,_) = Lookup.lookupClass(localCache,localEnv,recName,true);
        (fieldNameList,_) = DFA.extractFieldNamesAndTypes(sClass);
        
        numPosArgs = listLength(funcArgs);
        (_,fieldNamesNamed) = Util.listSplit(fieldNameList, numPosArgs);

        //Sorting of named arguments
        funcArgsNamedFixed = generatePositionalArgs(fieldNamesNamed,namedArgList,{});
        funcArgs = listAppend(funcArgs,funcArgsNamedFixed);

        (localCache,renamedPatList,localAsBinds2,localConstTagEnv) = renamePatList(funcArgs
          ,localVar2,1,{},{},localCache,localEnv,localConstTagEnv);
        pat = DFA.RP_CALL(localVar,compRef,renamedPatList);

      then (localCache,pat,listAppend(localAsBinds,localAsBinds2),localConstTagEnv);
        // EMPTY LIST EXPRESSION
    case (Absyn.ARRAY({}),localVar,localAsBinds,localCache,_,localConstTagEnv)
      local
        RenamedPat pat;
      equation
        pat = DFA.RP_EMPTYLIST(localVar);
      then (localCache,pat,localAsBinds,localConstTagEnv);
    case (Absyn.ARRAY(expList),localVar,localAsBinds,localCache,localEnv,localConstTagEnv)
      local
        list<Absyn.Exp> expList;
        RenamedPat pat;
        Absyn.Exp exp;
      equation
        exp = createConsFromList(expList);
        (localCache,pat,localAsBinds,localConstTagEnv) =
        renameMain(exp,localVar,localAsBinds,localCache,localEnv,localConstTagEnv);
      then (localCache,pat,localAsBinds,localConstTagEnv);
    case (e,_,_,_,_,_)  local Absyn.Exp e; String str;
      equation
        str = Dump.printExpStr(e);
        Debug.fprintln("matchcase", "- Patternm.renameMain failed, invalid pattern " +& str);
      then fail();
  end matchcontinue;
end renameMain;

protected function createConsFromList "function:
A function that takes a list of expressions and creates nested cons-cells
"
  input list<Absyn.Exp> inList;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (inList)
    local
      Absyn.Exp firstElem;
      list<Absyn.Exp> restElem;
    case (firstElem :: {})
    then Absyn.CONS(firstElem,Absyn.ARRAY({}));
    case (firstElem :: restElem)
      local
        Absyn.Exp localExp;
      equation
        localExp = createConsFromList(restElem);
        localExp = Absyn.CONS(firstElem,localExp);
      then localExp;
  end matchcontinue;
end createConsFromList;


protected function renamePatList "function: renamePatList
	author: KS
 	Rename the subpatterns in a constructor call one after another.
	Input is a list of patterns to remain.
	 The pivot integer is used for naming purposes.
"
  input list<Absyn.Exp> patList;
  input Absyn.Ident var;
  input Integer pivot;
  input list<RenamedPat> accRenamedPatList;
  input AsList asBindings;
  input Env.Cache cache;
  input Env.Env env;
  input tuple<Integer,list<tuple<Absyn.Ident,Integer>>> inConstTagEnv;
  output Env.Cache outCache;
  output list<RenamedPat> renamedPatList;
  output AsList outAsBindings;
  output tuple<Integer,list<tuple<Absyn.Ident,Integer>>> outConstTagEnv;
algorithm
  (outCache,renamedPatList,outAsBindings,outConstTagEnv) :=
  matchcontinue (patList,var,pivot,accRenamedPatList,asBindings,cache,env,inConstTagEnv)
    local
      list<RenamedPat> localAccRenamedPatList;
      AsList localAsBindings;
      Env.Cache localCache;
      Env.Env localEnv;
      tuple<Integer,list<tuple<Absyn.Ident,Integer>>> localConstTagEnv;
    case ({},_,_,localAccRenamedPatList,localAsBindings,localCache,_,localConstTagEnv)
      equation then (localCache,localAccRenamedPatList,localAsBindings,localConstTagEnv);
    case (first :: rest,localVar,localPivot,localAccRenamedPatList,localAsBindings,
      localCache,localEnv,localConstTagEnv)
      local
        Absyn.Exp first;
        list<Absyn.Exp> rest;
        Absyn.Ident localVar;
        Integer localPivot;
        RenamedPat localRenamedPat;
        AsList localAsBindings2;
        RenamedPatList temp1;
        list<Absyn.Exp> pathVars;
        AsList temp3;
        Absyn.Ident str;
        String tempStr;
      equation
        tempStr = stringAppend("__",intString(localPivot));
        //Rename first pattern
        (localCache,localRenamedPat,localAsBindings2,localConstTagEnv) =
        renameMain(first,stringAppend(localVar,tempStr),{},localCache,localEnv,localConstTagEnv);

      	str = stringAppend(localVar,tempStr);

      	localAccRenamedPatList = listAppend(localAccRenamedPatList,localRenamedPat :: {});
      	(localCache,temp1,temp3,localConstTagEnv) = renamePatList(rest,localVar,localPivot+1,
        	localAccRenamedPatList,
        	listAppend(localAsBindings,localAsBindings2),localCache,localEnv,localConstTagEnv);
      	then (localCache,temp1,temp3,localConstTagEnv);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprintln("matchcase", "- Patternm.renamePatList failed");
      then fail();
  end matchcontinue;
end renamePatList;

//-----------------------------------------------------------------------

public function matchMain "function: matchMain
	author: KS
 	The main function for the patternmatch algorithm.
 	Calls the ASTtoMatrixForm function for the generation of the pattern
	matrix. Then calls matchFuncHelper for the generation of the DFA
"
  input Absyn.Exp matchCont;
  input list<Absyn.Exp> resultVarList; // This is a list of lhs component refs, (var1,var2,...) = matchcontinue (...) ...
  input Env.Cache cache;
  input Env.Env env;
  output Env.Cache outCache;
  output Absyn.Exp outExpr; // The final valueblock with nested if-else-elseif statements
algorithm
  (outCache,outExpr) :=
  matchcontinue (matchCont,resultVarList,cache,env)
    case (localMatchCont,localResultVarList,localCache,localEnv)
      local
        RightHandList rhList,rhList2; // Light version and normal version
        RenamedPatMatrix patMat;
        list<Absyn.ElementItem> declList;
        list<list<Absyn.ElementItem>> caseLocalDeclList;
        list<Absyn.Exp> localResultVarList,inputVarList;
        list<Absyn.Case> cases;
        Option<RightHandSide> elseRhSide;
        Integer stampTemp,context;
        DFA.State dfaState;
        DFA.Dfa dfaRec;
        Absyn.Exp localMatchCont,expr;
        RenamedPatMatrix2 patMat2;
        Env.Cache localCache;
        Env.Env localEnv;
        Integer nCases;
        Boolean lightVs;
      equation
        // Get the pattern matrix, etc.
        (localCache,inputVarList,declList,rhList2,rhList,patMat,elseRhSide) = ASTtoMatrixForm(localMatchCont,localCache,localEnv);
        Absyn.MATCHEXP(cases=cases) = localMatchCont;
        caseLocalDeclList = Util.listMap(cases, getCaseDecls);
        patMat2 = arrayList(patMat);

        // A small fix.
        patMat2 = DFA.matrixFix(patMat2);

        // -------------------
        // ---Type Checking---
        // -------------------
        // Two sorts of type checkings are performed:
        // - The type of the input variables are looked up
        //   and matched against the patterns in each case clause
        // - The type of the return variables are looked up
        //   and matched against the return expression of each case clause
        // Check to make sure that the number of patterns in each case-clause
        // equals the number of input variables is done in the function fillMatrix
        // -------------
        //typeCheck1(localCache,localEnv,patMat2,inputVarList);
        //typeCheck2(localCache,localEnv,rhList2,localResultVarList);
        // -------------

        // Start the pattern matching
        // The rhList version is a "light" version of the rightHandSides so that
        // we do not have to carry around a lot of extra code in the pattern match algorithm
        patMat2 = Util.listlistTranspose(patMat2);
        (localCache, expr) = DFA.matchContinueToSwitch(patMat2,caseLocalDeclList,inputVarList,declList,localResultVarList,rhList2,localCache,localEnv);
      then (localCache, expr);
    /*
    
    case (localMatchCont,localResultVarList,localCache,localEnv)
      local
        RightHandList rhList,rhList2; // Light version and normal version
        RenamedPatMatrix patMat;
        list<Absyn.ElementItem> declList;
        list<Absyn.Exp> localResultVarList,inputVarList;
        Option<RightHandSide> elseRhSide;
        Integer stampTemp,context;
        DFA.State dfaState;
        DFA.Dfa dfaRec;
        Absyn.Exp localMatchCont,expr;
        RenamedPatMatrix2 patMat2;
        Env.Cache localCache;
        Env.Env localEnv;
        Integer nCases;
        Boolean lightVs;
      equation
        // Get the pattern matrix, etc.
        (localCache,inputVarList,declList,rhList2,rhList,patMat,elseRhSide) =
        ASTtoMatrixForm(localMatchCont,localCache,localEnv);
        patMat2 = arrayList(patMat);

        // A small fix.
        patMat2 = DFA.matrixFix(patMat2);

        // -------------------
        // ---Type Checking---
        // -------------------
        // Two sorts of type checkings are performed:
        // - The type of the input variables are looked up
        //   and matched against the patterns in each case clause
        // - The type of the return variables are looked up
        //   and matched against the return expression of each case clause
        // Check to make sure that the number of patterns in each case-clause
        // equals the number of input variables is done in the function fillMatrix
        // -------------
        //typeCheck1(localCache,localEnv,patMat2,inputVarList);
        //typeCheck2(localCache,localEnv,rhList2,localResultVarList);
        // -------------

        // Start the pattern matching
        // The rhList version is a "light" version of the rightHandSides so that
        // we do not have to carry around a lot of extra code in the pattern match algorithm
        (dfaState,stampTemp,_) = matchFuncHelper(patMat2,rhList,DFA.STATE({}),1,{});
        //print("Done with the matching");
        nCases = listLength(rhList);
        dfaRec = DFA.DFArec(declList,{},NONE(),dfaState,stampTemp,nCases);

        // Light version or not ---------------------
        // In a light version state labels will not be generated.
        // Light versions are generated when there is only one case-clause
        // which is the case for instance when we have rhs pattern matching
        // such as (_,var1,5) = func(...);
        lightVs = Util.if_((nCases == 1),true,false);
        //-------------------------------------------

        // Transform the DFA into a valueblock with nested if-elseif-else statements.
        (localCache,expr) =
        DFA.fromDFAtoIfNodes(dfaRec,inputVarList,localResultVarList,localCache,localEnv,rhList2,lightVs);
      then (localCache,expr);
    */
    case (exp,_,_,_)
      local
        Absyn.Exp exp;
        String str;
      equation
        str = Dump.printExpStr(exp);
        str = "- Patternm.matchMain failed: " +& str;
        Debug.fprintln("matchcase", str);
      then fail();
  end matchcontinue;
end matchMain;

/*
 The match algorithm:
 We can have tree types of patterns: wildcards, constructors and constants (may also sometimes be viewed
 as constructors with zero arguments).

 Case 1:
 All of the top-most patterns consists of wildcards. The leftmost wildcard is used to create an arc.
 Match is invoked on a new state with what is left of the upper row. An else arc is created, Match
 is invoked on a new state with the rest of the matrix with the upper-row removed.

 Case 2:
 The top-most column consists of wildcards and constants. Select the left-most column with a constant
 at the uppermost position.
 If this is the only column in the matrix do the following:
 		Create a new arc with the constant and a new final state. Create an else branch and a new state and
 		invoke match on this new state with what is left of the column. We have to do it this way because we
 		do not won't to loose any right-hand sides (since fail-continue may be implemented).
 Otherwise: Create an arc and state for each constant and constructor in the same way as case 3. For all
 		the wildcards we create a new arc and state.

 Case 3:
 There exists a column whose top-most pattern is a constructor. Select the left-most column containing
 a constructor. We will create a new arc for each constructor c in this column. So for each constructor c:
 Select the rows that match c (wildcards included). Extract the subpatterns, create a new
 arc and state and invoke match on what is left on the matrix appended with the extracted subpatterns.

 If this is the only column in the matrix do the following:
 		Create an else arc and a new arc. Invoke match on the matrix consisting of the wildcards and constants.

 Otherwise: create an arc and state for each constant as well, in the same way as for the constructors.
 		Create a new arc and state for all the wildcards.
*/


protected function matchFuncHelper "function: matchFuncHelper
	author: KS
 	This function is called recursively. It picks out a column and starts the pattern matching.
 	See above.
"
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input DFA.State currentState;
  input Integer stampCounter; // Each state will be given a stamp
  input list<DFA.SimpleState> savedStates; // For optimization
  output DFA.State outState;
  output Integer outStampCounter;
  output list<DFA.SimpleState> outSavedStates;
algorithm
  (outState,outStampCounter,outSavedStates) :=
  matchcontinue (patMat,rhList,currentState,stampCounter,savedStates)
    local
      list<DFA.SimpleState> localSavedStates,oldSavedStates;
      list<Integer> cNumbers;
    case ({},{},_,localCnt,localSavedStates) // Empty pattern matrix
      local
        Integer localCnt;
      equation
        //print("MatchFuncHelper: Two empty lists\n");
      then (DFA.DUMMIESTATE(),localCnt-1,localSavedStates); // The dummie states will simply be discarded
                                           // when if-statements are created.
    case ({{}},{},_,localCnt,localSavedStates) // Empty pattern matrix
      local
        Integer localCnt;
      equation
        //print("MatchFuncHelper: Two empty lists\n");
      then (DFA.DUMMIESTATE(),localCnt-1,localSavedStates);

        // FINAL STATE
    case ({},localRhList,_,localCnt,localSavedStates) // Empty pattern matrix but one
      // element in the righthand side list.
      // This means that we should create a final state.
      local
        RightHandSide rhSide;
        Integer localCnt;
        RightHandList localRhList;
        Integer n;
        DFA.SimpleState simpleState;
      equation
        rhSide = Util.listFirst(localRhList);

        //--Optimization
        n = Util.listFirst(DFA.getRightHandSideNumbers({rhSide},{}));
        simpleState = DFA.SIMPLESTATE(localCnt,{},n,NONE());
        localSavedStates = DFA.addNewSimpleState(localSavedStates,localCnt,simpleState);
        //----------

      then (DFA.STATE(localCnt,0,{},SOME(rhSide)),localCnt,localSavedStates);

        // CASE 1 - ALL WILDCARDS at the top-most matrix row -----------------------
    case (localPatMat,localRhList,localState,localCnt,localSavedStates)
      local
        RenamedPatMatrix2 localPatMat,tempMat;
        RightHandList localRhList;
        DFA.State localState,newState;
        Integer localCnt,oldCnt;
        RenamedPatList firstPatRow;
        list<RightHandSide> v1,v2;
        RenamedPat pat;
        Absyn.Ident arcName;
      equation
        firstPatRow = DFA.firstRow(localPatMat,{});
        true = allWildcards(firstPatRow); // Check to see if all are wildcards, note that variables are
                                          // classified as wildcards as well
        //---Optimization, save these values in case we need to discard the state we are working with.
        oldCnt = localCnt;
        oldSavedStates = localSavedStates;
        //---------------------

        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());

        // Start with first column (and the first row). But since the row only contains wildcards,
        // we can go straight to the final state (thus we send in an empty matrix).
        v1 = Util.listCreate(Util.listFirst(localRhList));
        (newState,localCnt,localSavedStates) = matchFuncHelper({},v1,newState,localCnt,localSavedStates);

        //Add a wildcard arc
        pat = Util.listFirst(firstPatRow);
        arcName = "Wildcard";
        cNumbers = DFA.getRightHandSideNumbers(v1,{});
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat),cNumbers);

        tempMat = DFA.removeFirstRow(localPatMat,{});

        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());

        // Match the rest of the matrix with first row removed
        v2 = Util.listRest(localRhList);
        (newState,localCnt,localSavedStates) = matchFuncHelper(tempMat
          ,v2,newState,localCnt,localSavedStates);

        // Add an else arc for the result of the matching of the
        // rest of the matrix with the first row removed
        arcName = "else";
        //cNumbers = DFA.getRightHandSideNumbers(v2,{});
        localState = DFA.addNewArc(localState,arcName,newState,NONE(),{});

        //---Optimization
        (localState,localCnt,localSavedStates) = doOptimization(oldSavedStates,localSavedStates,localState,oldCnt,localCnt);
        //---------------------------

      then (localState,localCnt,localSavedStates);
        //CASE 3 --- THERE EXIST AT LEAST ONE CONSTRUCTOR at the top-most row of the matrix --------------
    case (localPatMat,localRhList,localState,localCnt,localSavedStates)
      local
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState;
        Integer localCnt,oldCnt,i;
      equation
        // check to see if there exist a constructor
        true = existConstructor(DFA.firstRow(localPatMat,{}));

        // Dispatch to a separate function
        (localState,localCnt,localSavedStates) = matchCase3(localPatMat,localRhList,localState,localCnt,localSavedStates);
        //i = listLength(localSavedStates);
        //i = DFA.printDFASimple(listArray(localSavedStates),i);
      then (localState,localCnt,localSavedStates);

        // CASE 2 - NO CONSTRUCTORS BUT NOT ALL WILDCARDS	at the top-most row of the matrix
    case (localPatMat,localRhList,localState,localCnt,localSavedStates)
      local
        RenamedPatList tempPatL;
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState,newState;
        Integer localCnt,oldCnt;
        RenamedPat pat;
        ArcName arcName;
        list<RightHandSide> v1,v2;
      equation
        true = (listLength(localPatMat) == 1); //ONLY ONE COLUMN IN THE MATRIX
        // THE TOP ELEMENT MUST BE A CONSTANT

        //---Optimization, save these values in case we need to discard the state we are working with
        oldCnt = localCnt;
        oldSavedStates = localSavedStates;
        //---------------------

        // Match first element
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        v1 = Util.listCreate(Util.listFirst(localRhList));
        (newState,localCnt,localSavedStates) = matchFuncHelper({},v1
          ,newState,localCnt,localSavedStates);

        pat = Util.listFirst(Util.listFirst(localPatMat));
        // Add new arc with first element
        arcName = getConstantName(pat);
        cNumbers = DFA.getRightHandSideNumbers(v1,{});
        localState = DFA.addNewArc(localState,arcName
          ,newState,SOME(pat),cNumbers);

        // Match the rest of the column
        tempPatL = Util.listFirst(localPatMat);
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        v2 = Util.listRest(localRhList);
        (newState,localCnt,localSavedStates) = matchFuncHelper(Util.listCreate(Util.listRest(tempPatL)),
          v2,newState,localCnt,localSavedStates);

        // Add a new arc with rest of column
        arcName= "else";
        //cNumbers = DFA.getRightHandSideNumbers(v2,{});
        localState = DFA.addNewArc(localState,arcName,newState,NONE(),{});

         //---Optimization
        (localState,localCnt,localSavedStates) = doOptimization(oldSavedStates,localSavedStates,localState,oldCnt,localCnt);
        //---------------------------

      then (localState,localCnt,localSavedStates);

        // CASE 2 - NO CONSTRUCTORS BUT NOT ALL WILDCARDS	at the top-most row of the matrix
    case (localPatMat,localRhList,localState,localCnt,localSavedStates)
      local
        Integer ind,localCnt,oldCnt;
        RenamedPatList firstR;
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState;
        RenamedPat pat;
      equation
        //---Optimization, save these values in case we need to discard the state we are working with
        oldCnt = localCnt;
        oldSavedStates = localSavedStates;
        //---------------------

        firstR = DFA.firstRow(localPatMat,{});
        ind = findFirstConstant(firstR,1); // Find the left-most column containing a constant
        // Add an arc for each constant
        (localState,localCnt,localSavedStates) = addNewArcForEachC(localState,
          ind,localPatMat,localRhList,localCnt,localSavedStates);

        // Add one arc for all the wildcards
        (localState,localCnt,localSavedStates) = addNewArcForWildcards(localState,
          ind,localPatMat,localRhList,localCnt,localSavedStates);

        //---Optimization
        (localState,localCnt,localSavedStates) = doOptimization(oldSavedStates,localSavedStates,localState,oldCnt,localCnt);
        //---------------------------

      then (localState,localCnt,localSavedStates);
    case (_, _, _, _, _)
      equation
        Debug.fprintln("matchcase", "- Patternm.matchFuncHelper failed");
      then fail();
  end matchcontinue;
end matchFuncHelper;


protected function matchCase3 "function: matchCase3
	author: KS
	Case 3, there exist at least one constructor in the top-most row. Helper function
	to matchFuncHelper.
"
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input DFA.State currentState;
  input Integer stampCounter;
  input list<DFA.SimpleState> savedStates;
  output DFA.State finalState;
  output Integer outStamp;
  output list<DFA.SimpleState> outSavedStates;
algorithm
  (finalState,outStamp,outSavedStates) :=
  matchcontinue (patMat,rhList,currentState,stampCounter,savedStates)
    local
      list<DFA.SimpleState> localSavedStates,oldSavedStates;
    case (localPatMat,localRhList,localState,localCnt,localSavedStates)
      local
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState,newState;
        Integer localCnt,ind,oldCnt,oldCnt2;
        list<tuple<Absyn.Ident,Boolean>> listOfConstructors;
        IndexVector indVec;
        RenamedPatList tempList;
        RenamedPat pat;
        ArcName arcName;
        list<DFA.SimpleState> oldSavedStates2;
      equation
        true = (listLength(localPatMat) == 1); // One column in the matrix
        // Get the names of the constructors in the column
        //---Optimization, save these values in case we need to discard the state we are working with
        oldCnt = localCnt;
        oldSavedStates = localSavedStates;
        //---------------------

        tempList = Util.listFirst(localPatMat);
        listOfConstructors = findConstructors(tempList,{});

        // Get the indices of the consts and wildcards
        indVec = findConstAndWildcards(tempList,{},1);

        // Add a new arc for each constructor
        (localState,localCnt,localSavedStates) = addNewArcForEachCHelper(listOfConstructors,localState,
          1,localPatMat,localRhList,localCnt,localSavedStates);

        //---Optimization2, save these values in case we need to discard the state we are working with
        oldCnt2 = localCnt + 1;
        oldSavedStates2 = localSavedStates;
        //---------------------
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());

        // Add a new arc for the constants and wildcards
        (newState,localCnt,localSavedStates) = createUnionState(indVec,tempList,
          localRhList,localCnt,newState,true,localSavedStates);

        //---Optimization
        (newState,localCnt,localSavedStates) = doOptimization(oldSavedStates2,localSavedStates,newState,oldCnt2,localCnt);
        //---------------------------

        arcName= "else";
        localState = DFA.addNewArc(localState,arcName,newState,NONE(),{});

        //---Optimization
        (localState,localCnt,localSavedStates) = doOptimization(oldSavedStates,localSavedStates,localState,oldCnt,localCnt);
        //---------------------------

      then (localState,localCnt,localSavedStates);
        // MORE THAN ONE COLUMN IN THE MATRIX
    case (localPatMat,localRhList,localState,localCnt,localSavedStates)
      local
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        DFA.State localState;
        Integer localCnt,ind,oldCnt;
        RenamedPat pat;
        RenamedPatList patList;
      equation
        //---Optimization, save these values in case we need to discard the state we are working with
        oldCnt = localCnt;
        oldSavedStates = localSavedStates;
        //---------------------

        patList = DFA.firstRow(localPatMat,{});

        // Find the left-most column containing a constructor
        ind = findFirstConstructor(patList,1);

        // Add a new arc for each constant and constructor
        (localState,localCnt,localSavedStates) = addNewArcForEachC(localState,ind,localPatMat,localRhList,localCnt,localSavedStates);

        // Add a new arc for all the wildcards (combined)
        (localState,localCnt,localSavedStates) = addNewArcForWildcards(localState,ind,localPatMat,localRhList,localCnt,localSavedStates);

        //---Optimization
        (localState,localCnt,localSavedStates) = doOptimization(oldSavedStates,localSavedStates,localState,oldCnt,localCnt);
        //---------------------------
      then (localState,localCnt,localSavedStates);
  end matchcontinue;
end matchCase3;

protected function findConstAndWildcards "function: findConstAndWildcards
	author: KS
	Get the indices of all the const and wildcards from a pattern list.
"
  input RenamedPatList inList;
  input IndexVector accList;
  input Integer pivot;
  output IndexVector outVec;
algorithm
  outVec :=
  matchcontinue (inList,accList,localPivot)
    local
      DFA.IndexVector localAccList;
      Integer localPivot;
    case ({},localAccList,localPivot) equation then localAccList;
    case (first :: rest,localAccList,localPivot)
      local
        RenamedPat first;
        RenamedPatList rest;
        IndexVector localAcclist;
        Integer localPivot;
      equation
        true = (wildcardOrNot(first) or constantOrNot(first));
        localAccList = listAppend(localAccList,{localPivot});
      then findConstAndWildcards(rest,localAccList,localPivot+1);
    case (_ :: rest,localAccList,localPivot)
      local
        RenamedPatList rest;
        IndexVector localAcclist;
        Integer localPivot;
      equation
      then findConstAndWildcards(rest,localAccList,localPivot+1);
  end matchcontinue;
end findConstAndWildcards;

protected function findFirstConstant "function: findFirstConstant
	author: KS
	Find the index number of the first column containing a constant.
"
  input RenamedPatList patList;
  input Integer ind;
  output Integer outInd;
algorithm
  patList :=
  matchcontinue (patList,ind)
    local
      Integer localInd;
      RenamedPat first;
      RenamedPatList rest;
    case (first :: rest,localInd)
      equation
        true = constantOrNot(first);
      then localInd;
    case (_ :: rest,localInd) equation then findFirstConstant(rest,localInd+1);
  end matchcontinue;
end findFirstConstant;


protected function findFirstConstructor "function: findFirstConstructor
	author: KS
	Find the index number of the first column containing a constructor.
"
  input RenamedPatList patList;
  input Integer ind;
  output Integer outInd;
algorithm
  patList :=
  matchcontinue (patList,ind)
    local
      RenamedPat first;
      RenamedPatList rest;
      Integer localInd;
    case (first :: rest,localInd)
      equation
        true = constructorOrNot(first);
      then localInd;
    case (_ :: rest,localInd) equation then findFirstConstructor(rest,localInd+1);
  end matchcontinue;
end findFirstConstructor;


protected function createUnionState "function: createUnionState
	author: KS
	This functions takes a list of patterns, an index vector with indices
	to wildcard and constant patterns in the list of patterns and
	then creates a new state with arcs for these patterns. This function
	is used in for instance the following case:
	v := matchcontinue(x)
	  case (_) then A1;
  	case (1) then A2;
  	case (_) then A3;
		case (1) then A4;
		case (3) then A5;
		...
		end matchcontinue;
	Even though we have for instance two wildcards in the above example, we can not
	merge these two into one arc since we need to keep both righ-hand sides A1 and A3.
"
  input IndexVector indVec;
  input RenamedPatList patList;
  input RightHandList rhList;
  input Integer stampCnt;
  input DFA.State state;
  input Boolean firstTime;
  input list<DFA.SimpleState> inSavedStates;
  output DFA.State outState;
  output Integer outStamp;
  output list<DFA.SimpleState> outSavedStates;
algorithm
  (outstate,outStamp,outSavedStates) :=
  matchcontinue (indVec,patList,rhList,stampCnt,state,firstTime,inSavedStates)
    local
      list<DFA.SimpleState> localSavedStates;
    case ({},_,_,localCnt,_,true,localSavedStates)
      local
        Integer localCnt;
      equation
      then (DFA.DUMMIESTATE(),localCnt-1,localSavedStates);
    case ({},_,_,localCnt,localState,_,localSavedStates)
      local
        Integer localCnt;
        DFA.State localState;
      equation
      then (localState,localCnt,localSavedStates);

        // Wildcard
    case (first :: rest,localPatList,localRhList,localCnt,localState,_,localSavedStates)
      local
        RenamedPat pat;
        RightHandSide rhSide;
        Integer first,localCnt;
        IndexVector rest;
        RenamedPatList localPatList;
        RightHandList localRhList;
        DFA.State localState,newState;
        list<Integer> cNumbers;
      equation
        pat = arrayGet(listArray(localPatList),first);
        true = wildcardOrNot(pat);
        rhSide = arrayGet(listArray(localRhList),first);
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        (newState,localCnt,localSavedStates) = matchFuncHelper({},{rhSide},newState,localCnt,localSavedStates);

        cNumbers = DFA.getRightHandSideNumbers({rhSide},{});
        localState = DFA.addNewArc(localState,"Wildcard",newState,SOME(pat),cNumbers);
        (localState,localCnt,localSavedStates) =
        createUnionState(rest,localPatList,localRhList,localCnt,localState,false,localSavedStates);
      then (localState,localCnt,localSavedStates);

        // Constant
    case (first :: rest,localPatList,localRhList,localCnt,localState,_,localSavedStates)
      local
        RenamedPat pat;
        RightHandSide rhSide;
        Integer first,localCnt;
        IndexVector rest;
        RenamedPatList localPatList;
        RightHandList localRhList;
        DFA.State localState,newState;
        ArcName arcName;
        list<Integer> cNumbers;
      equation
        pat = arrayGet(listArray(localPatList),first);
        rhSide = arrayGet(listArray(localRhList),first);
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        (newState,localCnt,localSavedStates) = matchFuncHelper({},{rhSide},newState,localCnt,localSavedStates);

        arcName = getConstantName(pat);
        cNumbers = DFA.getRightHandSideNumbers({rhSide},{});
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat),cNumbers);
        (localState,localCnt,localSavedStates) =
        createUnionState(rest,localPatList,localRhList,localCnt,localState,false,localSavedStates);
      then (localState,localCnt,localSavedStates);
  end matchcontinue;
end createUnionState;


protected function findConstructors "function: findConstructors
	author: KS
	This function finds the constructors in a renamed pattern list.
	The boolean tells wheter it is a constructor (true) or constant (false).
	The functions addNewArcForEachC and addNewArcForEachCHelper makes use of
	this boolean.
"
  input RenamedPatList patList;
  input list<tuple<Absyn.Ident,Boolean>> accList;
  output list<tuple<Absyn.Ident,Boolean>> outList;
algorithm
  outList :=
  matchcontinue (patList,accList)
    local
      list<tuple<Absyn.Ident,Boolean>> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
      local
        Absyn.Ident constructorName;
        RenamedPatList rest;
        RenamedPat first;
        list<tuple<Absyn.Ident,Boolean>> temp;
      equation
        true = (constructorOrNot(first));
        constructorName = getConstructorName(first);
        temp = {(constructorName,true)};
        false = listMember(Util.listFirst(temp),localAccList);
      then findConstructors(rest,listAppend(localAccList,temp));
    case (_ :: rest,localAccList)
      local
        RenamedPatList rest;
      equation
      then findConstructors(rest,localAccList);
  end matchcontinue;
end findConstructors;

protected function getConstructorName "function: getConstrucorName
	author: KS
"
  input RenamedPat constPat;
  output Absyn.Ident name;
algorithm
  name :=
  matchcontinue (constPat)
    case DFA.RP_CONS(_,_,_) equation then "CONS";
    case DFA.RP_TUPLE(_,_) equation then "TUPLE";
    case DFA.RP_SOME(_,_) equation then "SOME";
    case DFA.RP_CALL(_,cref,_)
    local
      Absyn.Ident val;
      Absyn.ComponentRef cref;
      equation
       val = Absyn.pathString(Absyn.crefToPath(cref));
      then val;
  end matchcontinue;
end getConstructorName;

protected function getConstantName "function: getConstantName
	author: KS
"
  input RenamedPat constPat;
  output Absyn.Ident name;
algorithm
  name :=
  matchcontinue (constPat)
    case DFA.RP_INTEGER(_,val)
    local Integer val;
      equation then intString(val);
    case DFA.RP_REAL(_,val)
    local Real val;
      equation then realString(val);
    case DFA.RP_BOOL(_,val)
    local Boolean val;
      String str;
      equation
        str = DFA.boolString(val);
      then str;
    case DFA.RP_STRING(_,val)
    local
      String val;
      equation then val;
    case DFA.RP_EMPTYLIST(_) then "EmptyList";
    case DFA.RP_NONE(_) then "NONE";
  end matchcontinue;
end getConstantName;


protected function addNewArcForWildcards "function: addNewArcForWildcards
	author: KS
 	Used in the case there is more than one column in the matrix.
 	This functions adds one wildcard arc to a new state.
	 Function used in the following case:
 	var := matchcontinue (x,y)
      case (2,...)
      case (3,...)
      case (_,...)
	A new arc is added for all the wildcards in a column.
	(the pattern matrix must have more than one column).
"
  input DFA.State state;
  input Integer ind;
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input Integer stampCnt;
  input list<DFA.SimpleState> savedStates;
  output DFA.State finalState;
  output Integer outCnt;
  output list<DFA.SimpleState> outSavedStates;
algorithm
  (finalState,outCnt,outSavedStates) :=
  matchcontinue (state,ind,patMat,rhList,stampCnt,savedStates)
    local
      list<DFA.SimpleState> localSavedStates;
    case (localState,localInd,localPatMat,localRhList,localCnt,localSavedStates)
      local
        IndexVector indVec;
        DFA.State localState,newState;
        Integer localInd,localCnt;
        RenamedPatMatrix2 localPatMat,matTemp;
        RightHandList localRhList;
        RenamedPatList listTemp;
        Absyn.Ident var;
        ArcName arcName;
      equation
        listTemp = arrayGet(listArray(localPatMat),localInd);
        indVec = findMatches("Wildcard",listTemp,{},1);

        //NO WILDCARDS
        false = (listLength(indVec) == 0);

        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());
        matTemp = arrayList(DFA.patternsFromOtherCol(listArray(localPatMat),indVec,localInd));

        (newState,localCnt,localSavedStates) = matchFuncHelper(matTemp,
          selectRightHandSides(indVec,listArray(localRhList),{}),newState,localCnt,localSavedStates);

        var = DFA.extractPathVar(arrayGet(listArray(listTemp),Util.listFirst(indVec)));
        arcName = "Wildcard";
        localState = DFA.addNewArc(localState,arcName,newState,SOME(DFA.RP_WILDCARD(var)),{});
      then (localState,localCnt,localSavedStates);
    case (localState,_,_,_,localCnt,localSavedStates)
      local
        DFA.State localState;
        Integer localCnt;
      equation
      then (localState,localCnt,localSavedStates);
  end matchcontinue;
end addNewArcForWildcards;


protected function addNewArcForEachC "function: addNewArcForEachC
	author: KS
 	Adds a new arc for each constant and constructor
 	Assumes that the matrix has more than one column
"
  input DFA.State state;
  input Integer ind;
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input Integer cnt;
  input list<DFA.SimpleState> savedStates;
  output DFA.State finalState;
  output Integer outCnt;
  output list<DFA.SimpleState> outSavedStates;
algorithm
  (finalState,outCnt,outSavedStates) :=
  matchcontinue (state,ind,patMat,rhList,cnt,savedStates)
    case (localState,localInd,localPatMat,localRhList,localCnt,localSavedStates)
      local
        DFA.State localState;
        Integer localInd,localCnt;
        RenamedPatMatrix2 localPatMat;
        RightHandList localRhList;
        list<tuple<Absyn.Ident,Boolean>> listOfC; // The boolean tells wether it is a constant or constructor
        RenamedPatList listTemp;
        list<DFA.SimpleState> localSavedStates;
      equation
        listTemp = arrayGet(listArray(localPatMat),localInd);
        listOfC = getNamesOfCs(listTemp,{});

        (localState,localCnt,localSavedStates) = addNewArcForEachCHelper(listOfC,localState,localInd,
          localPatMat,localRhList,localCnt,localSavedStates);
      then (localState,localCnt,localSavedStates);
  end matchcontinue;
end addNewArcForEachC;


protected function getNamesOfCs "function: getNamesOfCs
	author: KS
	Retrieve the names of all constants and constructs in a matrix column.
 	Each name is stored with a boolean indicating wheter it is constructor or not.
"
  input RenamedPatList patList;
  input list<tuple<Absyn.Ident,Boolean>> accList;
  output list<tuple<Absyn.Ident,Boolean>> outList;
algorithm
  outList :=
  matchcontinue (patList,accList)
    local
      list<tuple<Absyn.Ident,Boolean>> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
      local
        RenamedPat first;
        RenamedPatList rest;
        list<tuple<Absyn.Ident,Boolean>> temp;
      equation
        true = constructorOrNot(first);
        temp = Util.listCreate((getConstructorName(first),true));
        false = listMember(Util.listFirst(temp),localAccList);
      then getNamesOfCs(rest,listAppend(localAccList,temp));
    case (first :: rest,localAccList)
      local
        RenamedPat first;
        RenamedPatList rest;
        list<tuple<Absyn.Ident,Boolean>> temp;
      equation
        true = constantOrNot(first);
        temp = Util.listCreate((getConstantName(first),false));
        false = listMember(Util.listFirst(temp),localAccList);
      then getNamesOfCs(rest,listAppend(localAccList,temp));
    case (_ :: rest,localAccList) local
      RenamedPatList rest;
      equation
      then getNamesOfCs(rest,localAccList);
  end matchcontinue;
end getNamesOfCs;


protected function addNewArcForEachCHelper "function: addNewArcForEachCHelper
	author: KS
	Add a new arc for each constructor or constant given a list with names of these.
	Example:
	matchcontinue (var)
		case ({})
		case (2 :: {})
		case (3 :: {})
		case (_)
  The first pattern is a constant (empty list) and then we have two constructors (cons).
	The input listOfC should have length 2: {EMPTYLIST,CONS}.
	We start with the EMPTYLIST identifer and then search the column (given by input variable ind)
	for all the patterns containing an empty list (case 1 and case 4). Then we
	do the same with the CONS identifer (case 2,3 and 4 matches).
	For a constant we create a new arc and then call matchFucnHelper on extracted
	patterns from all other columns in the matrix.
	For a constructor we have to extract subpatterns from the constructor call as well.
"
  input list<tuple<Absyn.Ident,Boolean>> listOfC;
  input DFA.State state;
  input Integer ind;
  input RenamedPatMatrix2 patMat;
  input RightHandList rhList;
  input Integer stampCnt;
  input list<DFA.SimpleState> savedStates;
  output DFA.State finalState;
  output Integer outCnt;
  output list<DFA.SimpleState> outSavedStates;
algorithm
  (finalState,outCnt,outSavedStates) :=
  matchcontinue (listOfC,state,ind,patMat,rhList,stampCnt,savedStates)
    local
      list<tuple<Absyn.Ident,Boolean>> rest;
      DFA.State localState,newState;
      Integer localInd,localCnt;
      RenamedPatMatrix2 localPatMat;
      RightHandList localRhList;
      list<DFA.SimpleState> localSavedStates;
    case ({},localState,_,_,_,localCnt,localSavedStates)
      equation then (localState,localCnt,localSavedStates);

      // CONSTANT
    case ((first,false) :: rest,localState,localInd,localPatMat,localRhList,localCnt,localSavedStates) //Constant
      local
        Absyn.Ident first;
        Boolean second;
        IndexVector indVec;
        RenamedPatList tempList;
        RenamedPatMatrix2 tempMat;
        DFA.State newState;
        RenamedPat pat;
        Integer ind;
        ArcName arcName;
        RightHandList tempRhList;
        list<Integer> cNumbers;
      equation
        tempList = arrayGet(listArray(localPatMat),localInd);

        indVec = findMatches(first,tempList,{},1); // Find all the matching patterns

        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());

        tempMat = arrayList(DFA.patternsFromOtherCol(listArray(localPatMat),indVec,localInd));

        // Match the rest of the matrix
        tempRhList = selectRightHandSides(indVec,listArray(localRhList),{});
        (newState,localCnt,localSavedStates) =
        matchFuncHelper(tempMat,tempRhList,newState,localCnt,localSavedStates);

        // Add a new arc for the constant
        pat = getPatternFromPatList(tempList,indVec);
        arcName = first;
        cNumbers = DFA.getRightHandSideNumbers(tempRhList,{});
        //print("ArcName, "); print(arcName); print(", pat name:"); print(getConstantName(pat));
        //print("\n");
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat),cNumbers);

        // Add more arcs for the other constants/constructors in the column
        (localState,localCnt,localSavedStates) = addNewArcForEachCHelper(rest,
          localState,localInd,localPatMat,localRhList,localCnt,localSavedStates);
      then (localState,localCnt,localSavedStates);

        // CONSTRUCTOR
    case ((first,second) :: rest,localState,localInd,localPatMat,localRhList,localCnt,localSavedStates)
      local
        Absyn.Ident first;
        Boolean second;
        Integer ind;
        IndexVector indVec;
        RenamedPatMatrix2 extractedPats,mat;
        RenamedPatMatrix extractedPats2;
        list<Absyn.Ident> varList;
        RenamedPatList patList;
        Absyn.Ident constructorName;
        list<tuple<Absyn.Ident,Boolean>> rest;
        RightHandList newRhL;
        RenamedPat pat;
        ArcName arcName;
        list<Integer> cNumbers;
      equation
        patList = arrayGet(listArray(localPatMat),localInd);
        constructorName = first;
        indVec = findMatches(constructorName,patList,{},1);

        varList = extractPathVariables(indVec,listArray(patList));

        //Extract the new matrix from the constructor calls
        extractedPats2 = fill({},listLength(varList));
        extractedPats = arrayList(extractSubpatterns(varList,indVec,patList,extractedPats2));

        mat = arrayList(DFA.patternsFromOtherCol(listArray(localPatMat),
          indVec,localInd));

        mat = DFA.appendMatrices(mat,extractedPats);

        newRhL = selectRightHandSides(indVec,listArray(localRhList),{});
        localCnt = localCnt + 1;
        newState = DFA.STATE(localCnt,0,{},NONE());

        // Match the matrix with the subpatterns (from the constructor call)
        // appended to the rest of the matrix
        (newState,localCnt,localSavedStates) = matchFuncHelper(mat,newRhL,newState,localCnt,localSavedStates);

        pat = getPatternFromPatList(patList,indVec);
        pat = simplifyPattern(pat,varList);
        arcName = constructorName;
        cNumbers = DFA.getRightHandSideNumbers(newRhL,{});
        //print("ArcName, "); print(arcName); print(", pat name:"); print(getConstructorName(pat));
        //print("\n");
        localState = DFA.addNewArc(localState,arcName,newState,SOME(pat),cNumbers);
        (localState,localCnt,localSavedStates) = addNewArcForEachCHelper(rest,localState,localInd,
          localPatMat,localRhList,localCnt,localSavedStates);
      then (localState,localCnt,localSavedStates);
  end matchcontinue;
end addNewArcForEachCHelper;


protected function simplifyPattern "function: simplifyPattern
	author: KS
	This function takes a constructor pattern and transforms all the
	subpatterns into wildcards. Only the path variables are left, we
	need these names later on.
"
  input RenamedPat pat;
  input list<Absyn.Ident> varList;
  output RenamedPat outPat;
algorithm
  outPat :=
  matchcontinue (pat,varList)
    local
      list<Absyn.Ident> localVarList;
    case (DFA.RP_CONS(pathVar,_,_),localVarList)
      local
        RenamedPat consPat,first,second;
        Absyn.Ident pathVar;
        RenamedPatList wcList;
      equation
        wcList = generateWildcardList(localVarList,{});
        second = Util.listFirst(Util.listRest(wcList));
        first = Util.listFirst(wcList);
        consPat = DFA.RP_CONS(pathVar,first,second);
      then consPat;
    case (DFA.RP_TUPLE(pathVar,_),localVarList)
      local
        RenamedPat tuplePat;
        Absyn.Ident pathVar;
        RenamedPatList wcList;
      equation
        wcList = generateWildcardList(localVarList,{});
        tuplePat = DFA.RP_TUPLE(pathVar,wcList);
      then tuplePat;
    case (DFA.RP_SOME(pathVar,_),localVarList)
      local
        RenamedPat somePat;
        Absyn.Ident pathVar;
        RenamedPatList wcList;
        RenamedPat wc;
      equation
        wcList = generateWildcardList(localVarList,{});
        wc = Util.listFirst(wcList);
        somePat = DFA.RP_SOME(pathVar,wc);
      then somePat;
    case (DFA.RP_CALL(pathVar,callName,_),localVarList)
      local
        Absyn.Ident pathVar;
        Absyn.ComponentRef callName;
        RenamedPat callPat;
        RenamedPatList wcList;
      equation
        wcList = generateWildcardList(localVarList,{});
        callPat = DFA.RP_CALL(pathVar,callName,wcList);
      then callPat;
  end matchcontinue;
end simplifyPattern;

protected function generateWildcardList "function: generateWildcardList
	author: KS
	Helper function to simplifyPattern
"
  input list<Absyn.Ident> varList;
  input RenamedPatList patList;
  output RenamedPatList outPatList;
algorithm
  outPatList :=
  matchcontinue (varList,patList)
    local
      RenamedPatList localPatList;
    case ({},localPatList) equation then localPatList;
    case (first :: rest,localPatList)
      local
        Absyn.Ident first;
        list<Absyn.Ident> rest;
      equation
        localPatList = listAppend(localPatList,{DFA.RP_WILDCARD(first)});
      then generateWildcardList(rest,localPatList);
  end matchcontinue;
end generateWildcardList;


protected function extractPathVariables "function: extractPathVariables
	author: KS
	Find the first construct given an IndexVector and extract the path variables.
"
  input IndexVector indList;
  input RenamedPatVec renamedPatVec;
  output list<Absyn.Ident> outPathVars;
algorithm
  outPathVars :=
  matchcontinue (indList,renamedPatVec)
    local
      Integer first;
      IndexVector rest;
      RenamedPatVec localRenamedPatVec;
    case ({},_) equation then {};
    case (first :: rest,localRenamedPatVec)
      equation
        true = wildcardOrNot(arrayGet(localRenamedPatVec,first));
      then extractPathVariables(rest,localRenamedPatVec);
    case (first :: _,localRenamedPatVec)
      local
        list<Absyn.Ident> varList;
      equation
        varList = getPathVarsFromConstruct(arrayGet(localRenamedPatVec,first));
      then varList;
  end matchcontinue;
end extractPathVariables;


protected function getPathVarsFromConstruct "function: getPathVarsFromConstruct
	author: KS
	Given a construct, extract a list of the path variables.
"
  input RenamedPat pat;
  output list<Absyn.Ident> outVarList;
algorithm
  outVarList :=
  matchcontinue (pat)
    case (DFA.RP_TUPLE(pathVar,l))
    local
      Absyn.Ident pathVar;
      list<Absyn.Ident> tempList;
      DFA.RenamedPatList l;
      equation
        tempList = getPathVarsFromConstructHelper(l,{});
      then tempList;
    case (DFA.RP_SOME(pathVar,rp))
    local
      Absyn.Ident pathVar;
      list<Absyn.Ident> tempList;
      DFA.RenamedPat rp;
      equation
        tempList = getPathVarsFromConstructHelper({rp},{});
      then tempList;
    case (DFA.RP_CONS(pathVar,p1,p2))
    local
      Absyn.Ident pathVar;
      list<Absyn.Ident> tempList;
      DFA.RenamedPatList l;
      DFA.RenamedPat p1,p2;
      equation
        l = listAppend({p1},{p2});
        tempList = getPathVarsFromConstructHelper(l,{});
      then tempList;
    case (DFA.RP_CALL(pathVar,_,l))
    local
      Absyn.Ident pathVar;
      list<Absyn.Ident> tempList;
      DFA.RenamedPatList l;
      equation
        tempList = getPathVarsFromConstructHelper(l,{});
      then tempList;
  end matchcontinue;
end getPathVarsFromConstruct;

protected function getPathVarsFromConstructHelper "function: getPathVarsFromConstructHelper"
  input DFA.RenamedPatList inList;
  input list<Absyn.Ident> accList;
  output list<Absyn.Ident> outList;
algorithm
  outList :=
  matchcontinue (inList,accList)
    local
      list<Absyn.Ident> localAccList;
      DFA.RenamedPatList restPats;
      Absyn.Ident v;
    case ({},localAccList) then localAccList;
    case (p :: restPats,localAccList)
      local
        DFA.RenamedPat p;
      equation
        v = DFA.extractPathVar(p);
        localAccList = listAppend(localAccList,{v});
        localAccList = getPathVarsFromConstructHelper(restPats,localAccList);
      then localAccList;
  end matchcontinue;
end getPathVarsFromConstructHelper;

protected function extractSubpatterns "function: extractSubpatterns
	author: KS
 	Extract all the subpatterns from a constructor or a wildcard.
 	For a wildcard, n wildcards are produced (where n is the number of arguments to the constructor).
  All the extracted subpatterns ends up in a matrix.
  Example:
  The following column (pattern list), (path) variable list {x__1,x__2}
  and an index vector {1,2,3} ...
  	 (pathVar1 = _)
  	 (pathVar2 = (2 :: {}))
  	 (pathVar3 = (4 :: (3 :: {})))
  ... will result in the following matrix:
  [RP_WILDCARD(x__1)  RP_WILDCARD(x__2)                                        ]
  [RP_INTEGER(x__1,2) RP_EMPTYLIST(x__2)                                       ]
  [RP_INTEGER(x__1,4) RP_CONS(x__2,RP_INTEGER(x__2__1,3),RP_EMPTYLIST(x__2__2) ]
"
  input list<Absyn.Ident> varList;
  input DFA.IndexVector indVec;
  input RenamedPatList patList;
  input RenamedPatMatrix accMat;
  output RenamedPatMatrix outMat;
algorithm
  outMat :=
  matchcontinue (varList,indVec,patList,localAccMat)
    local
      RenamedPatList localPatList;
      DFA.RenamedPatMatrix localAccMat;
    case (_,{},localPatList,localAccMat) equation then localAccMat;
    case (localVarList,first :: rest,localPatList,localAccMat)
      local
        list<Absyn.Ident> localVarList;
        Integer first;
        IndexVector rest;
        RenamedPatList tempPatList;
        RenamedPat pat;
      equation
        pat = arrayGet(listArray(localPatList),first);
        true = wildcardOrNot(pat);
        tempPatList = generateWildcards(localVarList);
        localAccMat = addNewPatRow(localAccMat,tempPatList,1);

        localAccMat = extractSubpatterns(localVarList,rest,localPatList,localAccMat);
      then localAccMat;
    case (localVarList,first :: rest,localPatList,localAccMat)
      local
        list<Absyn.Ident> localVarList;
        Integer first;
        IndexVector rest;
        RenamedPatList tempPatList;
        RenamedPatList tempPatList;
      equation
        tempPatList = extractFuncArgs(arrayGet(listArray(localPatList),first));
        localAccMat = addNewPatRow(localAccMat,tempPatList,1);
        localAccMat = extractSubpatterns(localVarList,rest,localPatList,localAccMat);
      then localAccMat;
  end matchcontinue;
end extractSubpatterns;

protected function generateWildcards "function: generateWildcards
	author: KS
	Given a list of identifers, this function will generate a list of
	wildcard patterns with corresponding identifer (path variable)
"
  input list<Absyn.Ident> varList;
  output RenamedPatList outList;
algorithm
  outList :=
  matchcontinue (varList)
    case ({}) equation then {};
    case (first :: rest)
      local
        Absyn.Ident first;
        list<Absyn.Ident> rest;
        RenamedPat pat;
        RenamedPatList l;
      equation
        pat = DFA.RP_WILDCARD(first);
        l = generateWildcards(rest);
      then pat :: l;
  end matchcontinue;
end generateWildcards;

protected function extractFuncArgs "function: extractFuncArgs
	author: KS
	This function is used by extractSubPatterns
"
  input RenamedPat inPat;
  output RenamedPatList outList;
algorithm
  outList :=
  matchcontinue (inPat)
    case (DFA.RP_CALL(_,_,l))
      local
        RenamedPatList l;
      equation
      then l;
    case (DFA.RP_TUPLE(_,l))
      local
        RenamedPatList l;
      equation
      then l;
    case (DFA.RP_SOME(_,first))
      local
        RenamedPat first;
        RenamedPatList l;
      equation
        l = {first};
      then l;
    case (DFA.RP_CONS(_,first,second))
      local
        RenamedPat first,second;
        RenamedPatList l;
      equation
        l = {first,second};
      then l;
  end matchcontinue;
end extractFuncArgs;


protected function addNewPatRow "function: addNewPatRow
	author: KS
	Adds a new row to a matrix.
"
  input RenamedPatMatrix patMat;
  input RenamedPatList patList;
  input Integer pivot;
  output RenamedPatMatrix outPatMat;
algorithm
  outPatMat :=
  matchcontinue (patMat,patList,pivot)
    local
      RenamedPatMatrix localPatMat;
    case (localPatMat,{},_) equation then localPatMat;
    case (localPatMat,first :: rest,localPivot)
      local
        Integer localPivot;
        RenamedPat first;
        RenamedPatList rest,tempList;
      equation
        tempList = localPatMat[localPivot];
        tempList = listAppend(tempList,{first});
        localPatMat = arrayUpdate(localPatMat, localPivot, tempList);
      then addNewPatRow(localPatMat,rest,localPivot+1);
  end matchcontinue;
end addNewPatRow;

protected function findMatches "function: findMatches
	author: KS
	This function takes an identifer and matches this identifer against
	all the patterns in a pattern list. It stores the index of the matched
	pattern in a list of integers"
  input Absyn.Ident matchObj;
  input RenamedPatList patList;
  input list<Integer> accIndList;
  input Integer pivot;
  output list<Integer> indList;
algorithm
  indList :=
  matchcontinue (matchObj,patList,accIndList,pivot)
    local
      RenamedPat first;
      RenamedPatList rest;
      Integer localPivot;
      list<Integer> localAccIndList;
      Absyn.Ident localMatchObj,constName;
    case (_,{},localAccIndList,_) equation then localAccIndList;
    case (localMatchObj,first :: rest,localAccIndList,localPivot)
      equation
        true = wildcardOrNot(first);
      then findMatches(localMatchObj,rest,listAppend(localAccIndList,{localPivot}),localPivot+1);
    case (localMatchObj,first :: rest,localAccIndList,localPivot)
      equation
        true = constantOrNot(first);
        constName = getConstantName(first);
        true = stringEqual(constName,localMatchObj);
      then findMatches(localMatchObj,rest,listAppend(localAccIndList,{localPivot}),localPivot+1);
    case (localMatchObj,first :: rest,localAccIndList,localPivot)
      local
        Absyn.Ident constructorName;
      equation
        true = constructorOrNot(first);
        constructorName = getConstructorName(first);
        true = stringEqual(constructorName,localMatchObj);
      then findMatches(localMatchObj,rest,listAppend(localAccIndList,{localPivot}),localPivot+1);
    case (localMatchObj,_ :: rest,localAccIndList,localPivot)
    then findMatches(localMatchObj,rest,localAccIndList,localPivot+1);
  end matchcontinue;
end findMatches;


protected function generatePositionalArgs "function: generatePositionalArgs
	author: KS
	This function is used in the following cases:
	v := matchcontinue (x)
  	  case REC(a=1,b=2)
   	 ...
	The named arguments a=1 and b=2 must be sorted and transformed into
	positional arguments (a,b is not necessarely the correct order).
"
  input list<Absyn.Ident> fieldNameList;
  input list<Absyn.NamedArg> namedArgList;
  input list<Absyn.Exp> accList;
  output list<Absyn.Exp> outList;
algorithm
  outList :=
  matchcontinue (fieldNameList,namedArgList,accList)
    local
      list<Absyn.Exp> localAccList;
    case ({},_,localAccList) then localAccList;
    case (firstFieldName :: restFieldNames,localNamedArgList,localAccList)
      local
        list<Absyn.Ident> restFieldNames;
        Absyn.Ident firstFieldName;
        list<Absyn.Exp> expL;
        list<Absyn.NamedArg> localNamedArgList;
      equation
        expL = Util.listCreate(findFieldExpInList(firstFieldName,localNamedArgList));
        localAccList = listAppend(localAccList,expL);
        localAccList = generatePositionalArgs(restFieldNames,localNamedArgList,localAccList);
      then localAccList;
  end matchcontinue;
end generatePositionalArgs;

protected function findFieldExpInList "function: findFieldExpInList
	author: KS
	Helper function to generatePositionalArgs
"
  input Absyn.Ident firstFieldName;
  input list<Absyn.NamedArg> namedArgList;
  output Absyn.Exp outExp;
algorithm
  outExp :=
  matchcontinue (firstFieldName,namedArgList)
    local
      Absyn.Exp e;
      Absyn.Ident localFieldName,aName;
      list<Absyn.NamedArg> restNamedArgList;
    case (_,{}) then Absyn.CREF(Absyn.WILD());
    case (localFieldName,Absyn.NAMEDARG(aName,e) :: _)
      equation
        true = stringEqual(localFieldName,aName);
      then e;
    case (localFieldName,_ :: restNamedArgList)
      equation
        e = findFieldExpInList(localFieldName,restNamedArgList);
      then e;
  end matchcontinue;
end findFieldExpInList;

//-----------------------------------------------------
// Helper functions

protected function allWildcards "function: allWildcards
	author: KS
"
  input RenamedPatList lPat;
  output Boolean val;
algorithm
  val := Util.boolAndList(Util.listMap(lPat,wildcardOrNot));
end allWildcards;


protected function allConst "function: allConst
	author: KS
	Decides wheter a list of Renamed Patterns only contains constant patterns
"
  input RenamedPatList lPat;
  output Boolean val;
algorithm
  val := Util.boolAndList(Util.listMap(lPat,constantOrNot));
end allConst;


protected function existConstructor "function: existConstructor
	author: KS
	Decides wheter a list of Renamed Patterns contains a constructor
"
  input RenamedPatList lPat;
  output Boolean val;
algorithm
  val := Util.boolOrList(Util.listMap(lPat,constructorOrNot));
end existConstructor;


protected function wildcardOrNot "function: wildcardOrNot
	author: KS
	Decides wheter a Renamed Patterns is a wildcard or not
"
  input RenamedPat pat;
  output Boolean val;
algorithm
  val :=
  matchcontinue (pat)
    case (DFA.RP_WILDCARD(_))
      equation
      then true;
    case (_)
      equation
      then false;
  end matchcontinue;
end wildcardOrNot;


protected function constantOrNot "function: constantOrNot
	author: KS
	Decides wheter a Renamed Patterns is a constant or not
"
  input RenamedPat pat;
  output Boolean val;
algorithm
  val :=
  matchcontinue (pat)
    case (DFA.RP_INTEGER(_,_))
      equation
      then true;
    case (DFA.RP_STRING(_,_))
      equation
      then true;
    case (DFA.RP_BOOL(_,_))
      equation
      then true;
    case (DFA.RP_REAL(_,_))
      equation
      then true;
    case (DFA.RP_EMPTYLIST(_)) then true;
    case (DFA.RP_NONE(_)) then true;
    case (DFA.RP_CREF(_,_))
      equation
      then true;
    case (_)
      equation
      then false;
  end matchcontinue;
end constantOrNot;


protected function constructorOrNot "function: constructorOrNot
	author:KS
	Decides wheter a Renamed Patterns is a constructor or not
"
  input RenamedPat pat;
  output Boolean val;
algorithm
  val :=
  matchcontinue (pat)
    case (DFA.RP_CONS(_,_,_)) then true;
    case (DFA.RP_TUPLE(_,_)) then true;
    case (DFA.RP_SOME(_,_)) then true;
    case (DFA.RP_CALL(_,_,_)) then true;
    case (_) then false;
  end matchcontinue;
end constructorOrNot;

protected function printList "function: printList
	author: KS
"
  input list<Boolean> boolList;
algorithm
  _ :=
  matchcontinue (boolList)
    case ({}) equation then ();
    case (first :: rest)
      local
        Boolean first;
        list<Boolean> rest;
      equation
        true = first;
        print("true");
        printList(rest);
      then ();
    case (first :: rest)
      local
        Boolean first;
        list<Boolean> rest;
      equation
        print("false");
        printList(rest);
      then ();
  end matchcontinue;
end printList;


protected function printCList "function: printCList
	author:KS
"
  input list<tuple<Absyn.Ident,Boolean>> cList;
algorithm
  _ :=
  matchcontinue (cList)
    case ({}) then ();
    case ((first,_) :: rest)
      local
        Absyn.Ident first;
        list<tuple<Absyn.Ident,Boolean>> rest;
      equation
        print(first);
        printCList(rest);
      then ();
  end matchcontinue;
end printCList;

protected function getPatternFromPatList "function: getPatternFromPatList"
  input RenamedPatList inList;
  input IndexVector inInd;
  output DFA.RenamedPat outPat;
algorithm
  outPat :=
  matchcontinue (inList,inInd)
    case (_,{}) then DFA.RP_WILDCARD("error");
    case (localList,localInd :: restInd)
      local
        RenamedPatList localList;
        Integer localInd;
        IndexVector restInd;
        RenamedPatVec tempVec;
        DFA.RenamedPat pat;
      equation
        tempVec = listArray(localList);
        pat = tempVec[localInd];
        false = wildcardOrNot(pat);
      then pat;
    case (localList,_ :: restInd)
      local
        IndexVector restInd;
        RenamedPatList localList;
        DFA.RenamedPat pat;
      equation
        pat = getPatternFromPatList(localList,restInd);
      then pat;
  end matchcontinue;
end getPatternFromPatList;


protected function selectRightHandSides "function: selectRightHandSides
	author:KS
	Picks out all the elements from a right hand vector given an index vector.
"
  input IndexVector indVec;
  input RightHandVector rhVec;
  input RightHandList accRhList;
  output RightHandList outRhList;
algorithm
  outRhList :=
  matchcontinue (indVec,rhVec,accRhList)
    local
      DFA.RightHandList localAccRhList;
    case ({},_,localAccRhList) equation then localAccRhList;
    case (first :: rest,localRhVec,localAccRhList)
      local
        Integer first;
        IndexVector rest;
        RightHandVector localRhVec;
        RightHandList tempRhSideL;
        RightHandSide tempRhs;
      equation
        tempRhs = arrayGet(localRhVec,first);
        tempRhSideL = {tempRhs};
        localAccRhList = listAppend(localAccRhList,tempRhSideL);
      then selectRightHandSides(rest,localRhVec,localAccRhList);
  end matchcontinue;
end selectRightHandSides;


// The following two functions are used to assign a unique tag
// to a Constructor name. The tags of constructors that have already
// been assigned are kept in an environment.
protected function findConstTag "function: findConstTag"
  input String constName;
  input list<tuple<Absyn.Ident,Integer>> inList;
  output Integer outTag;
algorithm
  outTag :=
  matchcontinue (constName,inList)
    local
      String id;
      list<tuple<Absyn.Ident,Integer>> restList;
    case (_,{}) then 0;
    case (id,(firstName,firstNum) :: restList)
      local
        Absyn.Ident firstName;
        Integer firstNum;
      equation
        true = stringEqual(id,firstName);
      then firstNum;
    case (id,_ :: restList)
      local
        Integer tag;
      equation
        tag = findConstTag(id,restList);
      then tag;
    end matchcontinue;
end findConstTag;

protected function getUniqueConstTag "function: getUniqueConstTag"
  input Absyn.Path constName;
  input tuple<Integer,list<tuple<Absyn.Ident,Integer>>> inEnv;
  output Integer outTag;
  output tuple<Integer,list<tuple<Absyn.Ident,Integer>>> outEnv;
algorithm
  (outTag,outEnv) :=
  matchcontinue (constName,inEnv)
    local
      Absyn.Path localName;
      Integer i;
      list<tuple<Absyn.Ident,Integer>> tagList;
      String s;
    case (localName,env as (i,tagList))
      local
        tuple<Integer,list<tuple<Absyn.Ident,Integer>>> env;
        Integer tagNum;
      equation
        s = Absyn.pathString(localName);
        // Returns 0 if not found
        tagNum = findConstTag(s,tagList);
        false = (tagNum == 0);
      then (tagNum,env);
        // Constructor not found
    case (localName,(i,tagList))
      local
        tuple<Integer,list<tuple<Absyn.Ident,Integer>>> newEnv;
      equation
        s = Absyn.pathString(localName);
        tagList = listAppend(tagList,{(s,i)});
        newEnv = (i+1,tagList);
      then (i,newEnv);
  end matchcontinue;
end getUniqueConstTag;

protected function doOptimization "function: doOptimization"
  input list<DFA.SimpleState> oldSavedStates;
  input list<DFA.SimpleState> newSavedStates;
  input DFA.State state;
  input Integer oldCnt;
  input Integer newCnt;
  output DFA.State outState;
  output Integer outCnt;
  output list<DFA.SimpleState> outSavedStates;
algorithm
  (outState,outCnt,outSavedStates) :=
  matchcontinue (oldSavedStates,newSavedStates,state,oldCnt,newCnt)

     // If an equal state already exists, goto to that state
   case (localOldSavedStates,_,localState,localOldCnt,_)
      local
        Integer stateNumber,localOldCnt;
        list<DFA.SimpleState> localOldSavedStates;
        DFA.State localState;
      equation
        stateNumber = findEqualState(listArray(localOldSavedStates),localState,1);
        false = (stateNumber == 0);

        // We discard localState as well as localNewSavedStates
        localState = DFA.GOTOSTATE(localOldCnt,stateNumber);

      then (localState,localOldCnt,localOldSavedStates);

    case (_,localNewSavedStates,localState,localOldCnt,localNewCnt)
      local
        DFA.SimpleState simpleState;
        list<DFA.SimpleState> localNewSavedStates;
        Integer localNewCnt,localOldCnt;
        DFA.State localState;
      equation
        simpleState = DFA.simplifyState(localState);
        localNewSavedStates = DFA.addNewSimpleState(localNewSavedStates,localOldCnt,simpleState);
      then (localState,localNewCnt,localNewSavedStates);
    case (_,_,_,_,_)
      equation
        Debug.fprintln("matchcase", "- Patternm.doOptimization failed");
      then fail();
  end matchcontinue;
end doOptimization;



// Go through all the old states and see if any-one matches the one
// created.
protected function findEqualState "function: findEqualState"
  input DFA.SimpleStateArray savedStates; // All states
  input DFA.State state;
  input Integer statePivot;
  output Integer outStampNr;
algorithm
  outStampNr :=
  matchcontinue (savedStates,state,statePivot)
    local
      DFA.SimpleStateArray localSavedStates;
      Integer localPivot;
    case (localSavedStates,_,localPivot)
      local
      equation
        true = (arrayLength(localSavedStates) < localPivot);
      then 0; // No match
    case (localSavedStates,localState,localPivot)
      local
        DFA.SimpleState simpleState;
        DFA.State localState;
        Integer n;
      equation
        simpleState = localSavedStates[localPivot];
        n = matchStates(localSavedStates,localState,simpleState);
        false = (n == 0);
      then localPivot;
    case (localSavedStates,localState,localPivot)
      local
        DFA.State localState;
        Integer n;
      equation
        localPivot = localPivot + 1;
        n = findEqualState(localSavedStates,localState,localPivot);
      then n;
  end matchcontinue;
end findEqualState;

protected function matchStates "function: matchStates
Two states are equal if they test the same input arg
and all the arcs are equal (see below).
"
  input DFA.SimpleStateArray savedStates;
  input DFA.State normalState;
  input DFA.SimpleState simpleState;
  output Integer stampNr;
algorithm
  stampNr :=
  matchcontinue (savedStates,normalState,simpleState)
    local
      DFA.SimpleStateArray localSavedStates;

      // Dummie State
    case (_,_,DFA.SIMPLEDUMMIE()) then 0;

      // Final state
    case (localSavedStates,DFA.STATE(_,_,_,SOME(DFA.RIGHTHANDLIGHT(cNum1))),
        DFA.SIMPLESTATE(_,_,cNum2,_))
      local
        Integer cNum1,cNum2;
      equation
        true = (cNum1 == cNum2);
      then 1;

    case (localSavedStates,DFA.STATE(_,_,arcs1 as (DFA.ARC(_,_,SOME(p),_) :: _),_),
        DFA.SIMPLESTATE(_,arcs2,_,SOME(stateVar)))
      local
        DFA.RenamedPat p;
        Absyn.Ident stateVar,stateVar2;
        list<DFA.Arc> arcs1;
        list<tuple<DFA.ArcName,DFA.Stamp>> arcs2;
        Integer n;
      equation
        stateVar2 = DFA.extractPathVar(p);
        true = stringEqual(stateVar,stateVar2);
        n = matchArcs(localSavedStates,arcs1,arcs2);
      then n;

    case (_,_,_)
    then 0;
    end matchcontinue;
end matchStates;

protected function matchArcs "function: matchArcs
Two arcs are equal if they have same pattern and they go to equal
states.
"
  input DFA.SimpleStateArray savedStates; // All saved states
  input list<DFA.Arc> arcs1;
  input list<tuple<DFA.ArcName,DFA.Stamp>> arcs2;
  output Integer outStamp;
algorithm
  outStamp :=
  matchcontinue (savedStates,arcs1,arcs2)
    case (_,DFA.ARC(DFA.DUMMIESTATE(),_,_,_) :: _,{}) then 1;
    case (_,{},{}) then 1;
    case (_,{},_) then 0;
    case (_,_,{}) then 0;
    case (localSavedStates,DFA.ARC(DFA.GOTOSTATE(_,nextState1),patName1,_,_) :: rest1,
      (patName2,nextState2) :: rest2)
      local
        DFA.SimpleStateArray localSavedStates;
        DFA.Stamp nextState1,nextState2;
        DFA.ArcName patName1,patName2;
        list<DFA.Arc> rest1;
        list<tuple<DFA.ArcName,DFA.Stamp>> rest2;
        Integer n;
      equation
        true = stringEqual(patName1,patName2);
        true = (nextState1 == nextState2);
        n = matchArcs(localSavedStates,rest1,rest2);
      then n;
    case (localSavedStates,DFA.ARC(state1,patName1,_,_) :: rest1,
      (patName2,nextState) :: rest2)
      local
        DFA.State state1;
        DFA.SimpleState state2;
        DFA.ArcName patName1,patName2;
        list<DFA.Arc> rest1;
        list<tuple<DFA.ArcName,DFA.Stamp>> rest2;
        DFA.SimpleStateArray localSavedStates;
        DFA.Stamp nextState;
        Integer n;
      equation
        true = stringEqual(patName1,patName2);
        state2 = localSavedStates[nextState];
        n = matchStates(localSavedStates,state1,state2);
        false = (n == 0);
        n = matchArcs(localSavedStates,rest1,rest2);
      then n;
    case (_,_,_) then 0;
  end matchcontinue;
end matchArcs;
//----------------

//--------------------//
// Some Type Checking //
//--------------------//

/*protected function typeCheck1 "function: typeCheck1"
  input Env.Cache cache;
  input Env.Env env;
  input RenamedPatMatrix2 patMat;
  input list<Absyn.Exp> expList;
  output Boolean bool;
algorithm
  bool :=
  matchcontinue (cache,env,patMat,expList)
    case (localCache,localEnv,localPatMat,localExpList)
      local
        RenamedPatList patList;
        RenamedPatMatrix2 localPatMat;
        Env.Cache localCache;
        Env.Env localEnv;
        list<Absyn.Exp> localExpList; Boolean b;
      equation
        patList = getVarTypes(localExpList,{});
        b = patternCheck(localPatMat,patList);
      then b;
  end matchcontinue;
end typeCheck1;

protected function getVarTypes "function: getVarTypes"
  input Env.Cache cache;
  input Env.Env env;
  input list<Absyn.Exp> expList;
  input RenamedPatList inList;
  output Env.Cache outCache;
  output RenamedPatList outList;
algorithm
  (outCache,outList) :=
  matchcontinue (cache,env,expList,inList)
    local
      RenamedPatList localAccList;
    case (localCache,_,{},localAccList) then (localCache,localAccList);
    case (localCache,localEnv,Absyn.CREF(Absyn.CREF_IDENT(id,{})) :: restExp,localAccList)
      local
        Absyn.Ident id; list<Absyn.Exp> restExp;
        Types.Type t; RenamedPat rp;
        Env.Cache localCache; Env.Env localEnv;
      equation
        (_,t,_)=
        Lookup.lookupVar(localCache,localEnv,Exp.CREF_IDENT(id,{}));
        rp = fromTypeToRenamedPat(t);
        localAccList = listAppend(localAccList,{rp});
        (localCache,localAccList) = getVarTypes(restExp,localAccList);
      then (localCache,localAccList);
  end matchcontinue;
end getVarTypes;

protected function fromTypeToRenamedPat "function: fromTypeToRenamedPat"
  input Types.Type t;
  output RenamedPat rp;
algorithm
  rp :=
  matchcontinue (t)
    case ((Types.T_INTEGER(_),_))
    then DFA.RP_INTEGER("a",1);

    case ((Types.T_STRING(_),_))
    then DFA.RP_STRING("a","a");

    case ((Types.T_BOOL(_),_))
    then DFA.RP_BOOL("a",true);

    case ((Types.T_LIST(_),_))
    then DFA.RP_CONS("a",DFA.RP_WILDCARD("a"),DFA.RP_WILDCARD("a"));
  end matchcontinue;
end fromTypeToRenamedPat;

public function patternCheck "function: patternCheck"
  input RenamedPatMatrix2 mat;
  input RenamedPatList lst;
  output Boolean b;
algorithm
  b :=
  matchcontinue (mat,lst)
    case ({},l) then true;
    case ({{}},l) then true;
    case (firstRow :: restRows,l)
      local
        RenamedPatMatrix2 restRows;
        RenamedPatList firstRow;
        RenamedPat pat;
        Boolean b2;
      equation
        pat = Util.listFirst(firstRow);
        b2 = patternCheck2(pat,firstRow);
        true = b2;
        b2 = patternCheck(restRows);
      then b2;
    case (_,_) then fail();
  end matchcontinue;
end patternCheck;

public function patternCheck2 "function: patterCheck2"
  input RenamedPat pat;
  input RenamedPatList pList;
  output Boolean outB;
algorithm
  outB :=
  matchcontinue (pat,pList)
    case (_,{}) then true;
    case (p,firstP :: restP)
      local
      equation
        true = twoPatternMatch(p,firstP);
        b = patternCheck2(firstP,restP);
      then b;
    case (_,_) then fail();
  end matchcontinue;
end patternCheck2;

public function twoPatternMatch "function: twoPatternMatch"
  input RenamedPat pat1;
  input RenamedPat pat2;
  output Boolean outB;
algorithm
  outB :=
  matchcontinue (pat1,pat2)
    case (DFA.RP_WILDCARD(_),_) then true;
    case (_,DFA.RP_WILDCARD(_)) then true;
    case (DFA.RP_EMPTYLIST(_),DFA.RP_EMPTYLIST(_)) then true;
    case (DFA.RP_INTEGER(_),DFA.RP_INTEGER(_)) then true;
    case (DFA.RP_REAL(_),DFA.RP_REAL(_)) then true;
    case (DFA.RP_BOOL(_),DFA.RP_BOOL(_)) then true;
    case (DFA.RP_STRING(_),DFA.RP_STRING(_)) then true;
    case (DFA.RP_CALL(_,_,_),DFA.RP_CALL(_,_,_)) then true;
    case (DFA.RP_CREF(_,_),DFA.RP_CREF(_,_)) then true;
    case (DFA.RP_TUPLE(_,_),DFA.RP_TUPLE(_,_)) then true;
    case (DFA.RP_CONS(_,_,_),DFA.RP_CONS(_,_,_)) then true;
    case (p1,p2)
      local  RenamedPat p1; RenamedPat p2;
      equation
        Debug.fprint("failtrace", "- twoPatternMatch failed, non-matching patterns\n");
        print("Non matching patterns");
        DFA.printPattern(p1); print(",");
        DFA.printPattern(p2); print("\n");
      then fail();
  end matchcontinue;
end twoPatternMatch; */
//------------------

protected function getCaseDecls
  input Absyn.Case cas;
  output list<Absyn.ElementItem> els;
algorithm
  els := matchcontinue (cas)
    local list<Absyn.ElementItem> els;
    case Absyn.CASE(localDecls = els) then els;
    case Absyn.ELSE(localDecls = els) then els;
  end matchcontinue;
end getCaseDecls;

end Patternm;
