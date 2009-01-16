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

package DAEQuery
" file:	       DAEQuery.mo
  package:     DAEQuery
  description: DAEQuery contains functionality for query of Incidence Matrix.

  RCS: $Id$"

public
import DAELow;

protected
import System;
import Util;
import Exp;
import Absyn;
import DAE;
import Algorithm;
import RTOpts;

public function writeIncidenceMatrix
  input DAELow.DAELow dlow;
  input String fileNamePrefix;
  input String flatModelicaStr;
  output String fileName;
algorithm
  fileName := matchcontinue(dlow, fileNamePrefix, flatModelicaStr)
    local
      String file, strIMatrix, strVariables, flatStr, strEquations;
      list<String>[:] m;
    case (dlow, fileNamePrefix, flatStr)
      equation
        file = stringAppend(fileNamePrefix, "_imatrix.m");
        m = incidenceMatrix(dlow);
        strIMatrix = getIncidenceMatrix(m);
        strVariables = getVariables(dlow);
        strEquations = getEquations(dlow);
        strIMatrix = Util.stringAppendList({strIMatrix, "\n", strVariables, "\n\n\n", strEquations, "\n\n\n", flatStr});
        System.writeFile(file, strIMatrix);
      then
        file;
  end matchcontinue;
end writeIncidenceMatrix;

public function getEquations
"function: getEquations
 @author adrpo
  This function returns the equations"
  input DAELow.DAELow inDAELow;
  output String strEqs;
algorithm
  strEqs:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> vars,knvars,extvars;
      Integer varlen,eqnlen;
      String varlen_str,eqnlen_str,s,s1,s2,s3;
      list<String> ls1,ls2,ls3;
      list<DAELow.Equation> eqnsl,reqnsl,ieqnsl;
      list<String> ss;
      list<DAELow.MultiDimEquation> ae_lst;
      DAELow.Variables vars1,vars2,vars3;
      DAELow.EquationArray eqns,reqns,ieqns;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] algs;
      list<DAELow.ZeroCrossing> zc;
      DAELow.ExternalObjectClasses extObjCls;
      list<DAELow.WhenClause> wcLst;
    case (DAELow.DAELOW(vars1,vars2,vars3,eqns,reqns,ieqns,ae,algs,DAELow.EVENT_INFO(whenClauseLst = wcLst),extObjCls))
      equation
        eqnsl = DAELow.equationList(eqns);
        ls1 = Util.listMap1(eqnsl, equationStr, wcLst);  s1 = Util.stringDelimitList(ls1, ",");
        s = "EqStr = {" +& s1 +& "};";
      then
        s;
  end matchcontinue;
end getEquations;

public function equationStr
"function: equationStr
  Helper function to getEqustions."
  input DAELow.Equation inEquation;
  input list<DAELow.WhenClause> wcLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inEquation, wcLst)
    local
      String s1,s2,s3,res,indx_str,is,var_str;
      Exp.Exp e1,e2,e,condition;
      DAELow.Value indx,i;
      list<Exp.Exp> expl;
      Exp.ComponentRef cr;
    case (DAELow.EQUATION(exp = e1,scalar = e2), _)
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({"'", s1," = ",s2, ";'"});
      then
        res;
    case (DAELow.ARRAY_EQUATION(index = indx,crefOrDerCref = expl), _)
      equation
        indx_str = intString(indx);
        var_str=Util.stringDelimitList(Util.listMap(expl,Exp.printExpStr),", ");
        res = Util.stringAppendList({"Array eqn no: ",indx_str," for variables: ",var_str,"\n"});
      then
        res;
    case (DAELow.SOLVED_EQUATION(componentRef = cr,exp = e2), _)
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        res = Util.stringAppendList({"'",s1," = ",s2,";'"});
      then
        res;
    case (DAELow.WHEN_EQUATION(whenEquation = DAELow.WHEN_EQ(index = i,left = cr,right = e2)), wcLst)
      equation
        s1 = Exp.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        DAELow.WHEN_CLAUSE(condition, _, _) = listNth(wcLst,i);
        s3 = Exp.printExpStr(condition);
        res = Util.stringAppendList({"'when ", s3, " then " , s1," = ",s2,"; end when;'"});
      then
        res;
    case (DAELow.RESIDUAL_EQUATION(exp = e),_)
      equation
        s1 = Exp.printExpStr(e);
        res = Util.stringAppendList({"'", s1,"= 0", ";'"});
      then
        res;
    case (DAELow.ALGORITHM(index = i),_)
      equation
        is = intString(i);
        res = Util.stringAppendList({"Algorithm no: ",is,"\n"});
      then
        res;
  end matchcontinue;
end equationStr;

protected function getIncidenceMatrix "function: getIncidenceMatrix
  gets the incidence matrix as a string
"
  input list<String>[:] m;
  output String strIMatrix;
  Integer mlen;
  String mlen_str;
  list<list<String>> m_1;
  String mstr;
algorithm
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  m_1 := arrayList(m);
  mstr := getIncidenceMatrix2(m_1,1);
  strIMatrix := Util.stringAppendList({"% Incidence Matrix\n",
    "% ====================================\n", "% number of rows: ", mlen_str, "\n",
    "IM={", mstr, "};"});
end getIncidenceMatrix;

protected function getIncidenceMatrix2 "function: getIncidenceMatrix2
  author: adrpo
  Helper function to getIncidenceMatrix (+_t).
"
  input list<list<String>> inStringLstLst;
  input Integer rowIndex;
  output String strIMatrix;
algorithm
  strIMatrix :=
  matchcontinue (inStringLstLst,rowIndex)
    local
      list<String> row;
      list<list<String>> rows;
      String str, str1, str2;
    case ({},_) then "";
    case ((row :: {}),rowIndex)
      equation
        str1 = getIncidenceRow(row);
        str = Util.stringAppendList({"[", str1, "]"});
      then
        str;
    case ((row :: rows),rowIndex)
      equation
        str1 = getIncidenceRow(row);
        str2 = getIncidenceMatrix2(rows,rowIndex+1);
        str = Util.stringAppendList({"[", str1, "],",  str2});
      then
        str;
  end matchcontinue;
end getIncidenceMatrix2;

protected function getIncidenceRow "function: getIncidenceRow
  author: adrpo
  Helper function to getIncidenceMatrix2.
"
  input list<String> inStringLst;
  output String strRow;
algorithm
  strRow :=
  matchcontinue (inStringLst)
    local
      String s, s1, s2, x;
      list<String> xs;
    case ({}) then "";
    case ((x :: {})) then x;
    case ((x :: xs))
      equation
        s2 = getIncidenceRow(xs);
        s = Util.stringAppendList({x, ",", s2});
      then
        s;
  end matchcontinue;
end getIncidenceRow;

public function getVariables "function: getVariables
  This function returns the variables
"
  input DAELow.DAELow inDAELow;
  output String strVars;
algorithm
  strVars:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> vars,knvars,extvars;
      Integer varlen,eqnlen;
      String varlen_str,eqnlen_str,s;
      list<DAELow.Equation> eqnsl,reqnsl,ieqnsl;
      list<String> ss;
      list<DAELow.MultiDimEquation> ae_lst;
      DAELow.Variables vars1,vars2,vars3;
      DAELow.EquationArray eqns,reqns,ieqns;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] algs;
      list<DAELow.ZeroCrossing> zc;
      DAELow.ExternalObjectClasses extObjCls;
    case (DAELow.DAELOW(vars1,vars2,vars3,eqns,reqns,ieqns,ae,algs,DAELow.EVENT_INFO(zeroCrossingLst = zc),extObjCls))
      equation
        vars = varList(vars1);
        s = dumpVars(vars);
        s = "VL = {" +& s +& "};";
      then
        s;
  end matchcontinue;
end getVariables;

public function varList "function: varList
  Takes Variables and returns a list of \'DAELow.Var\', useful for e.g. dumping.
"
  input DAELow.Variables inVariables;
  output list<DAELow.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariables)
    local
      list<DAELow.Var> varlst;
      DAELow.VariableArray vararr;
    case (DAELow.VARIABLES(varArr = vararr))
      equation
        varlst = DAELow.vararrayList(vararr);
      then
        varlst;
  end matchcontinue;
end varList;


public function vararrayList "function: vararrayList

  Transforms a VariableArray to a DAELow.Var list
"
  input DAELow.VariableArray inVariableArray;
  output list<DAELow.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariableArray)
    local
      Option<DAELow.Var>[:] arr;
      DAELow.Var elt;
      Integer lastpos,n,size;
      list<DAELow.Var> lst;
    case (DAELow.VARIABLE_ARRAY(numberOfElements = 0,varOptArr = arr)) then {};
    case (DAELow.VARIABLE_ARRAY(numberOfElements = 1,varOptArr = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (DAELow.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr))
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
  input Option<DAELow.Var>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<DAELow.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      DAELow.Var v;
      Option<DAELow.Var>[:] arr;
      Integer pos,lastpos,pos_1;
      list<DAELow.Var> res;
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

public function dumpVars "function: dumpVars
  Helper function to dump.
"
  input list<DAELow.Var> vars;
  output String strVars;
algorithm
  strVars := dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2 "function: dumpVars2
  Helper function to dump_vars.
"
  input list<DAELow.Var> inVarLst;
  input Integer inInteger;
  output String strVars;
algorithm
  strVars :=
  matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str,str1,str2;
      list<String> paths_lst,path_strs;
      Integer varno_1,indx,varno;
      DAELow.Var v;
      Exp.ComponentRef cr,old_name;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Option<Exp.Exp> e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> xs;
      DAE.Type var_type;
      
    case ({},_) then "";
    case (((v as DAELow.VAR(varName = cr,
                            varKind = kind,
                            varDirection = dir,
                            varType = var_type,
                            bindExp = e,
                            index = indx,
                            origVarName = old_name,
                            className = paths,
                            values = dae_var_attr,
                            comment = comment,
                            flowPrefix = flowPrefix,
                            streamPrefix = streamPrefix)) :: {}),varno)
      equation
        varnostr = intString(varno);
        dirstr = DAE.dumpDirectionStr(dir);
        str1 = Exp.printComponentRefStr(cr);
        /*
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print("= ");
        s = Exp.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx);
        str = DAE.dumpTypeStr(var_type);print( " type: "); print(str);

        print(" indx = ");
        print(indx_str);
        varno_1 = varno + 1;
        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        */
        str = Util.stringAppendList({"'", str1, "'"});
      then
        str;
        
      case (((v as DAELow.VAR(varName = cr,
                              varKind = kind,
                              varDirection = dir,
                              varType = var_type,
                              bindExp = e,
                              index = indx,
                              origVarName = old_name,
                              className = paths,
                              values = dae_var_attr,
                              comment = comment,
                              flowPrefix = flowPrefix,
                              streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        dirstr = DAE.dumpDirectionStr(dir);
        str1 = Exp.printComponentRefStr(cr);
        /*
        paths_lst = Util.listMap(paths, Absyn.pathString);
        path_str = Util.stringDelimitList(paths_lst, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print("= ");
        s = Exp.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx);
        str = DAE.dumpTypeStr(var_type);print( " type: "); print(str);

        print(" indx = ");
        print(indx_str);

        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        */
        varno_1 = varno + 1;
        str2 = dumpVars2(xs, varno_1);
        str = Util.stringAppendList({"'", str1, "',", str2});
      then
        str;
  end matchcontinue;
end dumpVars2;

public function incidenceMatrix 
"function: incidenceMatrix
  author: PA
  Calculates the incidence matrix, i.e. which 
  variables are present in each equation."
  input DAELow.DAELow inDAELow;
  output list<String>[:] outIncidenceMatrix;
algorithm
  outIncidenceMatrix:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Equation> eqnsl;
      list<list<String>> lstlst;
      list<String>[:] arr;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns))
      equation
        eqnsl = DAELow.equationList(eqns);
        lstlst = incidenceMatrix2(vars, eqnsl);
        arr = listArray(lstlst);
      then
        arr;
    case (_)
      equation
        print("DAEQuery.incidenceMatrix failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatrix;

protected function incidenceMatrix2 "function: incidenceMatrix2
  author: PA

  Helper function to incidence_matrix
  Calculates the incidence matrix as a list of list of integers
"
  input DAELow.Variables inVariables;
  input list<DAELow.Equation> inEquationLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inVariables,inEquationLst)
    local
      list<list<String>> lst;
      list<String> row;
      DAELow.Variables vars;
      DAELow.Equation e;
      list<DAELow.Equation> eqns;
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
  input DAELow.Variables inVariables;
  input DAELow.Equation inEquation;
  output list<String> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inVariables,inEquation)
    local
      list<String> lst1,lst2,res,res_1;
      DAELow.Variables vars;
      Exp.Exp e1,e2,e;
      list<list<String>> lst3;
      list<Exp.Exp> expl,inputs,outputs;
      Exp.ComponentRef cr;
      DAELow.WhenEquation we;
      DAELow.Value indx;
    case (vars,DAELow.EQUATION(exp = e1,scalar = e2))
      equation
        lst1 = incidenceRowExp(e1, vars) "EQUATION" ;
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,DAELow.ARRAY_EQUATION(crefOrDerCref = expl)) /* ARRAY_EQUATION */
      equation
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst3);
      then
        res;
    case (vars,DAELow.SOLVED_EQUATION(componentRef = cr,exp = e)) /* SOLVED_EQUATION */
      equation
        lst1 = incidenceRowExp(Exp.CREF(cr,Exp.REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,DAELow.SOLVED_EQUATION(componentRef = cr,exp = e)) /* SOLVED_EQUATION */
      equation
        lst1 = incidenceRowExp(Exp.CREF(cr,Exp.REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,DAELow.RESIDUAL_EQUATION(exp = e)) /* RESIDUAL_EQUATION */
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (vars,DAELow.WHEN_EQUATION(whenEquation = we)) /* WHEN_EQUATION */
      equation
        (cr,e2) = DAELow.getWhenEquationExpr(we);
        e1 = Exp.CREF(cr,Exp.OTHER());
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,DAELow.ALGORITHM(index = indx,in_ = inputs,out = outputs)) /* ALGORITHM For now assume that algorithm will be solvable for correct
	  variables. I.e. find all variables in algorithm and add to lst.
	  If algorithm later on needs to be inverted, i.e. solved for
	  different variables than calculated, a non linear solver or
	  analysis of algorithm itself needs to be implemented.
	 */
      local list<list<String>> lst1,lst2,res;
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
  input DAELow.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAlgorithmStatementLst,inVariables)
    local
      list<String> lst1,lst2,lst3,res,lst3_1;
      Exp.Type tp;
      Exp.ComponentRef cr;
      Exp.Exp e, e1;
      list<Algorithm.Statement> rest,stmts;
      DAELow.Variables vars;
      list<Exp.Exp> expl;
      Algorithm.Else else_;
    case ({},_) then {};
    case ((Algorithm.ASSIGN(type_ = tp,exp1 = e1,exp = e) :: rest),vars)
      equation
        lst1 = incidenceRowStmts(rest, vars);
        lst2 = incidenceRowExp(e, vars);
        lst3 = incidenceRowExp(e1, vars);
        res = Util.listFlatten({lst1,lst2,lst3});
      then
        res;
    case ((Algorithm.TUPLE_ASSIGN(type_ = tp,expExpLst = expl,exp = e) :: rest),vars)
      local list<list<String>> lst3;
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
  input DAELow.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inExp,inVariables)
    local
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Value> p,p_1;
      list<String> pStr,s1,s2,res,s3,lst_1;
      String s;
      list<list<String>> lst;
      Exp.ComponentRef cr;
      DAELow.Variables vars;
      Exp.Exp e1,e2,e,e3;
      list<Exp.Exp> expl;
    case (Exp.CREF(componentRef = cr),vars)
      equation
        ((DAELow.VAR(_,DAELow.STATE(),_,_,_,_,_,_,_,_,_,_,flowPrefix,streamPrefix) :: _),p) = 
        DAELow.getVar(cr, vars) "If variable x is a state, der(x) is a variable in incidence matrix,
	                               x is inserted as negative value, since it is needed by debugging and index
	                               reduction using dummy derivatives" ;
        p_1 = Util.listMap1r(p, int_sub, 0);
        pStr = Util.listMap(p_1, intString);
      then
        pStr;
    case (Exp.CREF(componentRef = cr),vars)
      equation
        ((DAELow.VAR(_,DAELow.VARIABLE(),_,_,_,_,_,_,_,_,_,_,flowPrefix,streamPrefix) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (Exp.CREF(componentRef = cr),vars)
      equation
        ((DAELow.VAR(_,DAELow.DISCRETE(),_,_,_,_,_,_,_,_,_,_,flowPrefix,streamPrefix) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (Exp.CREF(componentRef = cr),vars)
      equation
        ((DAELow.VAR(_,DAELow.DUMMY_DER(),_,_,_,_,_,_,_,_,_,_,flowPrefix,streamPrefix) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (Exp.CREF(componentRef = cr),vars)
      equation
        ((DAELow.VAR(_,DAELow.DUMMY_STATE(),_,_,_,_,_,_,_,_,_,_,flowPrefix,streamPrefix) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (Exp.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        pStr = listAppend(s1, s2);
      then
        pStr;
    case (Exp.UNARY(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (Exp.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        pStr = listAppend(s1, s2);
      then
        pStr;
    case (Exp.LUNARY(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (Exp.RELATION(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        pStr = listAppend(s1, s2);
      then
        pStr;
    case (Exp.IFEXP(expCond = e1 as Exp.RELATION(exp1 = ee1, operator = op1, exp2 =ee2),expThen = e2,expElse = e3),vars) /* if expressions. */
      local String ss, ss1, ss2, ss3, opStr;
        Exp.Exp ee1,ee2;
        Exp.Operator op1;
      equation
        opStr = Exp.relopSymbol(op1);
        s = printExpStr(ee2);
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        // build the string now
        ss = Util.stringAppendList({"{'if', ",s,",'", opStr, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
    // if-expressions with a variable
//    case (Exp.IFEXP(expCond = e1 as Exp.CREF(componentRef = cref1),expThen = e2,expElse = e3),vars) /* if expressions. */
/*      local String ss,sb;
        String ss, ss1, ss2, ss3;
        Exp.ComponentRef cref1;
      equation
        sb = printExpStr(e1);
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = Util.stringAppendList({"{'if', ","'", sb, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
*/

    // If expression with logic sentence.
    case (Exp.IFEXP(expCond = e1 as Exp.LBINARY(exp1 = ee1, operator = op1, exp2 =ee2),expThen = e2,expElse = e3),vars) /* if expressions. */
      local String ss, ss1, ss2, ss3, opStr, sb;
        Exp.Exp ee1,ee2;
        Exp.Operator op1;
      equation
        opStr = printExpStr(e1);
        //opStr = Exp.relopSymbol(op1);
        //s = printExpStr(ee2);
        sb = Util.stringAppendList({"'true',","'=='"});
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        // build the string now
        ss = Util.stringAppendList({"{'if', ",sb,",", "{",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
    // if-expressions with a variable (Bool)
    case (Exp.IFEXP(expCond = e1 as Exp.CREF(componentRef = cref1), expThen = e2, expElse = e3),vars) /* if expressions. */
      local String ss,sb;
        String ss, ss1, ss2, ss3;
        Exp.ComponentRef cref1;
      equation
        //sb = printExpStr(e1);

        sb = Util.stringAppendList({"'true',","'=='"});
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = Util.stringAppendList({"{'if', ", sb, " {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;

    // if-expressions with any other alternative than what we handled until now
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars) /* if expressions. */
      local String ss,sb;
        String ss, ss1, ss2, ss3;
        Exp.ComponentRef cref1;
      equation
        sb = printExpStr(e1);
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = Util.stringAppendList({"{'if', ","'", sb, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),vars)
      equation
        ((DAELow.VAR(_,DAELow.STATE(),_,_,_,_,_,_,_,_,_,_,flowPrefix,streamPrefix) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (Exp.CALL(path = Absyn.IDENT(name = "der"),expLst = {Exp.CREF(componentRef = cr)}),vars)
      equation
        (_,p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        {};
    case (Exp.CALL(path = Absyn.IDENT(name = "pre"),expLst = {Exp.CREF(componentRef = cr)}),vars) /* pre(v) is considered a known variable */ //IS IT????
      local String ss;
      equation
        (_,p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
        //ss = printExpStr(cr, vars);
        //pStr = ss;
      then
        pStr;
    case (Exp.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        pStr = Util.listFlatten(lst);
      then
        pStr;
    case (Exp.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        pStr = Util.listFlatten(lst);
      then
        pStr;
    case (Exp.MATRIX(scalar = expl),vars)
      local list<list<tuple<Exp.Exp, Boolean>>> expl;
      equation
        pStr = incidenceRowMatrixExp(expl, vars);
      then
        pStr;
    case (Exp.TUPLE(PR = expl),vars)
      equation
        print("incidence_row_exp TUPLE not impl. yet.");
      then
        {};
    case (Exp.CAST(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (Exp.ASUB(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (Exp.REDUCTION(expr = e1,range = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        pStr = listAppend(s1, s2);
      then
        pStr;
    case (_,_) then {};
  end matchcontinue;
end incidenceRowExp;

protected function incidenceRowMatrixExp "function: incidenceRowMatrixExp
  author: PA

  Traverses matrix expressions for building incidence matrix.
"
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input DAELow.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<Exp.Exp> expl_1;
      list<list<String>> res1;
      list<tuple<Exp.Exp, Boolean>> expl;
      list<list<tuple<Exp.Exp, Boolean>>> es;
      list<String> pStr, res1_1, res2;
      DAELow.Variables vars;
    case ({},_) then {};
    case ((expl :: es),vars)
      equation
        expl_1 = Util.listMap(expl, Util.tuple21);
        res1 = Util.listMap1(expl_1, incidenceRowExp, vars);
        res2 = incidenceRowMatrixExp(es, vars);
        res1_1 = Util.listFlatten(res1);
        pStr = listAppend(res1_1, res2);
      then
        pStr;
  end matchcontinue;
end incidenceRowMatrixExp;

protected function printExpStr "function: printExpStr
  This function prints a complete expression."
  input Exp.Exp e;
  output String s;
algorithm
  s := printExp2Str(e);
end printExpStr;

protected function printExp2Str
"function: printExp2Str
  Helper function to print_exp_str."
  input Exp.Exp inExp;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp)
    local
      Exp.Ident s,s_1,s_2,sym,s1,s2,s3,s4,s_3,ifstr,thenstr,elsestr,res,fs,argstr,s5,s_4,s_5,res2,str,crstr,dimstr,expstr,iterstr,id;
      Exp.Ident s1_1,s2_1,s1_2,s2_2,cs,ts,fs,cs_1,ts_1,fs_1,s3_1;
      Integer x,pri2_1,pri2,pri3,pri1,ival,i,pe1,p1,p2,pc,pt,pf,p,pstop,pstart,pstep;
      Real rval;
      Exp.ComponentRef c;
      Exp.Type t,ty,ty2,tp;
      Exp.Exp e1,e2,e21,e22,e,f,start,stop,step,cr,dim,exp,iterexp,cond,tb,fb;
      Exp.Operator op;
      Absyn.Path fcn;
      list<Exp.Exp> args,es;
    case (Exp.END()) then "end";
    case (Exp.ICONST(integer = x))
      equation
        s = intString(x);
      then
        s;
    case (Exp.RCONST(real = x))
      local Real x;
      equation
        s = realString(x);
      then
        s;
    case (Exp.SCONST(string = s))
      equation
        s_1 = stringAppend("\'", s);//changed, Matlab can't read "
        s_2 = stringAppend(s_1, "\'");
      then
        s_2;
    case (Exp.BCONST(bool = false)) then "false";
    case (Exp.BCONST(bool = true)) then "true";
    case (Exp.CREF(componentRef = c,ty = t))
      equation
        s = Exp.printComponentRefStr(c);
      then
        s;
    case (e as Exp.BINARY(e1,op,e2))
      equation
        sym = Exp.binopSymbol(op);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        p = Exp.expPriority(e);
        p1 = Exp.expPriority(e1);
        p2 = Exp.expPriority(e2);
        s1_1 = Exp.parenthesize(s1, p1, p, false);
        s2_1 = Exp.parenthesize(s2, p2, p, true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
     case ((e as Exp.UNARY(op,e1)))
      equation
        sym = Exp.unaryopSymbol(op);
        s = printExpStr(e1);
        p = Exp.expPriority(e);
        p1 = Exp.expPriority(e1);
        s_1 = Exp.parenthesize(s, p1, p,false);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;
   case ((e as Exp.LBINARY(e1,op,e2)))
      equation
        sym = Exp.lbinopSymbol(op);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        p = Exp.expPriority(e);
        p1 = Exp.expPriority(e1);
        p2 = Exp.expPriority(e2);
        s1_1 = Exp.parenthesize(s1, p1, p, false);
        s2_1 = Exp.parenthesize(s2, p2, p, true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
   case ((e as Exp.LUNARY(op,e1)))
      equation
        sym = Exp.lunaryopSymbol(op);
        s = printExpStr(e1);
        p = Exp.expPriority(e);
        p1 = Exp.expPriority(e1);
        s_1 = Exp.parenthesize(s, p1, p, false);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;
   case ((e as Exp.RELATION(e1,op,e2)))
      equation
        sym = Exp.relopSymbol(op);
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        p = Exp.expPriority(e);
        p1 = Exp.expPriority(e1);
        p2 = Exp.expPriority(e2);
        s1_1 = Exp.parenthesize(s1, p1, p, false);
        s2_1 = Exp.parenthesize(s2, p1, p, true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;
    case ((e as Exp.IFEXP(cond,tb,fb)))
      equation
        cs = printExpStr(cond);
        ts = printExpStr(tb);
        fs = printExpStr(fb);
        p = Exp.expPriority(e);
        pc = Exp.expPriority(cond);
        pt = Exp.expPriority(tb);
        pf = Exp.expPriority(fb);
        cs_1 = Exp.parenthesize(cs, pc, p, false);
        ts_1 = Exp.parenthesize(ts, pt, p, false);
        fs_1 = Exp.parenthesize(fs, pf, p, false);
        str = Util.stringAppendList({"if ",cs_1," then ",ts_1," else ",fs_1});
      then
        str;
    case (Exp.CALL(path = fcn,expLst = args))
      equation
        fs = Absyn.pathString(fcn);
        argstr = Exp.printListStr(args, printExpStr, ",");
        s = stringAppend(fs, "(");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case (Exp.ARRAY(array = es,ty=tp))
      local Exp.Type tp; String s3;
      equation
        s3 = Exp.typeString(tp);
        s = Exp.printListStr(es, printExpStr, ",");
        s_2 = Util.stringAppendList({"{",s,"}"});
      then
        s_2;
    case (Exp.TUPLE(PR = es))
      equation
        s = Exp.printListStr(es, printExpStr, ",");
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;
    case (Exp.MATRIX(scalar = es,ty=tp))
      local list<list<tuple<Exp.Exp, Boolean>>> es;
        Exp.Type tp; String s3;
      equation
        s3 = Exp.typeString(tp);
        s = Exp.printListStr(es, Exp.printRowStr, "},{");
        s_2 = Util.stringAppendList({"{{",s,"}}"});
      then
        s_2;
    case (e as Exp.RANGE(_,start,NONE,stop))
      equation
        s1 = printExpStr(start);
        s3 = printExpStr(stop);
        p = Exp.expPriority(e);
        pstart = Exp.expPriority(start);
        pstop = Exp.expPriority(stop);
        s1_1 = Exp.parenthesize(s1, pstart, p, false);
        s3_1 = Exp.parenthesize(s3, pstop, p, false);
        s = Util.stringAppendList({s1_1,":",s3_1});
      then
        s;
    case ((e as Exp.RANGE(_,start,SOME(step),stop)))
      equation
        s1 = printExpStr(start);
        s2 = printExpStr(step);
        s3 = printExpStr(stop);
        p = Exp.expPriority(e);
        pstart = Exp.expPriority(start);
        pstop = Exp.expPriority(stop);
        pstep = Exp.expPriority(step);
        s1_1 = Exp.parenthesize(s1, pstart, p, false);
        s3_1 = Exp.parenthesize(s3, pstop, p, false);
        s2_1 = Exp.parenthesize(s2, pstep, p, false);
        s = Util.stringAppendList({s1_1,":",s2_1,":",s3_1});
      then
        s;
    case (Exp.CAST(ty = Exp.REAL(),exp = Exp.ICONST(integer = ival)))
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
      then
        res;
    case (Exp.CAST(ty = Exp.REAL(),exp = Exp.UNARY(operator = Exp.UMINUS(ty = _),exp = Exp.ICONST(integer = ival))))
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        res2 = stringAppend("-", res);
      then
        res2;
    case (Exp.CAST(ty = Exp.REAL(),exp = e))
      equation
        false = RTOpts.modelicaOutput();
        s = printExpStr(e);
        s_2 = Util.stringAppendList({"Real(",s,")"});
      then
        s_2;
    case (Exp.CAST(ty = Exp.REAL(),exp = e))
      equation
        true = RTOpts.modelicaOutput();
        s = printExpStr(e);
      then
        s;
    case (Exp.CAST(ty = tp,exp = e))
      equation
        str = Exp.typeString(tp);
        s = printExpStr(e);
        res = Util.stringAppendList({"CAST(",str,", ",s,")"});
      then
        res;
    case (e as Exp.ASUB(exp = e1,sub = {e2}))
      equation
        p = Exp.expPriority(e);
        pe1 = Exp.expPriority(e1);
        s1 = printExp2Str(e1);
        s1_1 = Exp.parenthesize(s1, pe1, p, false);
        s4 = printExp2Str(e2);
        s_4 = Util.stringAppendList({s1_1,"[",s4,"]"});
      then
        s_4;
    case (Exp.SIZE(exp = cr,sz = SOME(dim)))
      equation
        crstr = printExpStr(cr);
        dimstr = printExpStr(dim);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;
    case (Exp.SIZE(exp = cr,sz = NONE))
      equation
        crstr = printExpStr(cr);
        str = Util.stringAppendList({"size(",crstr,")"});
      then
        str;
    case (Exp.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp))
      equation
        fs = Absyn.pathString(fcn);
        expstr = printExpStr(exp);
        iterstr = printExpStr(iterexp);
        str = Util.stringAppendList({"<reduction>",fs,"(",expstr," for ",id," in ",iterstr,")"});
      then
        str;

      // MetaModelica list
    case (Exp.LIST(_,es))
      local list<Exp.Exp> es;
      equation
        s = Exp.printListStr(es, printExpStr, ",");
        s_1 = stringAppend("list(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

        // MetaModelica list cons
    case (Exp.CONS(_,e1,e2))
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        s_2 = Util.stringAppendList({"cons(",s1,",",s2,")"});
      then
        s_2;

    case (_) then "#UNKNOWN EXPRESSION# ----eee ";
  end matchcontinue;
end printExp2Str;

end DAEQuery;
