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

package DAEQuery
" file:	       DAEQuery.mo
  package:     DAEQuery
  description: DAEQuery contains functionality for query of Incidence Matrix.

  RCS: $Id$"

public
import BackendDAE;
import ComponentReference;
import DAELow;
import SCode;

protected
import BackendDAEUtil;
import System;
import Util;
import Exp;
import Absyn;
import DAE;
import Algorithm;
import RTOpts;
import DAEDump;

protected constant String matlabStringDelim = "'";

public function writeIncidenceMatrix
  input BackendDAE.DAELow dlow;
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
        strIMatrix = System.stringAppendList({strIMatrix, "\n", strVariables, "\n\n\n", strEquations, "\n\n\n", flatStr});
        System.writeFile(file, strIMatrix);
      then
        file;
  end matchcontinue;
end writeIncidenceMatrix;

public function getEquations
"function: getEquations
 @author adrpo
  This function returns the equations"
  input BackendDAE.DAELow inDAELow;
  output String strEqs;
algorithm
  strEqs:=
  matchcontinue (inDAELow)
    local
      String s,s1;
      list<String> ls1;
      list<BackendDAE.Equation> eqnsl;
      list<String> ss;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.WhenClause> wcLst;
    case (BackendDAE.DAELOW(orderedEqs = eqns, eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wcLst)))
      equation
        eqnsl = BackendDAEUtil.equationList(eqns);
        ls1 = Util.listMap1(eqnsl, equationStr, wcLst);
        s1 = Util.stringDelimitList(ls1, ",");
        s = "EqStr = {" +& s1 +& "};";
      then
        s;
  end matchcontinue;
end getEquations;

public function equationStr
"function: equationStr
  Helper function to getEqustions."
  input BackendDAE.Equation inEquation;
  input list<BackendDAE.WhenClause> wcLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inEquation, wcLst)
    local
      String s1,s2,s3,res,indx_str,is,var_str;
      DAE.Exp e1,e2,e,condition;
      BackendDAE.Value indx,i;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2), _)
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        res = System.stringAppendList({"'", s1," = ",s2, ";'"});
      then
        res;
    case (BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl), _)
      equation
        indx_str = intString(indx);
        var_str=Util.stringDelimitList(Util.listMap(expl,Exp.printExpStr),", ");
        res = System.stringAppendList({"Array eqn no: ",indx_str," for variables: ",var_str,"\n"});
      then
        res;
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2), _)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        res = System.stringAppendList({"'",s1," = ",s2,";'"});
      then
        res;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i,left = cr,right = e2)), wcLst)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = Exp.printExpStr(e2);
        BackendDAE.WHEN_CLAUSE(condition, _, _) = listNth(wcLst,i);
        s3 = Exp.printExpStr(condition);
        res = System.stringAppendList({"'when ", s3, " then " , s1," = ",s2,"; end when;'"});
      then
        res;
    case (BackendDAE.RESIDUAL_EQUATION(exp = e),_)
      equation
        s1 = Exp.printExpStr(e);
        res = System.stringAppendList({"'", s1,"= 0", ";'"});
      then
        res;
    case (BackendDAE.ALGORITHM(index = i),_)
      equation
        is = intString(i);
        res = System.stringAppendList({"Algorithm no: ",is,"\n"});
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
  strIMatrix := System.stringAppendList({"% Incidence Matrix\n",
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
        str = System.stringAppendList({"{", str1, "}"});
      then
        str;
    case ((row :: rows),rowIndex)
      equation
        str1 = getIncidenceRow(row);
        str2 = getIncidenceMatrix2(rows,rowIndex+1);
        str = System.stringAppendList({"{", str1, "},",  str2});
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
        s = System.stringAppendList({x, ",", s2});
      then
        s;
  end matchcontinue;
end getIncidenceRow;

public function getVariables "function: getVariables
  This function returns the variables
"
  input BackendDAE.DAELow inDAELow;
  output String strVars;
algorithm
  strVars:=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> vars;
      String s;
      BackendDAE.Variables vars1;
    case (BackendDAE.DAELOW(orderedVars = vars1))
      equation
        vars = varList(vars1);
        s = dumpVars(vars);
        s = "VL = {" +& s +& "};";
      then
        s;
  end matchcontinue;
end getVariables;

public function varList "function: varList
  Takes Variables and returns a list of \'BackendDAE.Var\', useful for e.g. dumping.
"
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariables)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.VariableArray vararr;
    case (BackendDAE.VARIABLES(varArr = vararr))
      equation
        varlst = BackendDAEUtil.vararrayList(vararr);
      then
        varlst;
  end matchcontinue;
end varList;


public function vararrayList "function: vararrayList

  Transforms a VariableArray to a BackendDAE.Var list
"
  input BackendDAE.VariableArray inVariableArray;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVariableArray)
    local
      Option<BackendDAE.Var>[:] arr;
      BackendDAE.Var elt;
      Integer lastpos,n,size;
      list<BackendDAE.Var> lst;
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 0,varOptArr = arr)) then {};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = 1,varOptArr = arr))
      equation
        SOME(elt) = arr[0 + 1];
      then
        {elt};
    case (BackendDAE.VARIABLE_ARRAY(numberOfElements = n,arrSize = size,varOptArr = arr))
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
  input Option<BackendDAE.Var>[:] inVarOptionArray1;
  input Integer inInteger2;
  input Integer inInteger3;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarOptionArray1,inInteger2,inInteger3)
    local
      BackendDAE.Var v;
      Option<BackendDAE.Var>[:] arr;
      Integer pos,lastpos,pos_1;
      list<BackendDAE.Var> res;
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
  input list<BackendDAE.Var> vars;
  output String strVars;
algorithm
  strVars := dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2 "function: dumpVars2
  Helper function to dump_vars.
"
  input list<BackendDAE.Var> inVarLst;
  input Integer inInteger;
  output String strVars;
algorithm
  strVars :=
  matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,path_str,comment_str,s,indx_str,str1,str2;
      list<String> paths_lst,path_strs;
      Integer varno_1,indx,varno;
      BackendDAE.Var v;
      DAE.ComponentRef cr,old_name;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Var> xs;
      BackendDAE.Type var_type;
      DAE.ElementSource source "the origin of the element";

    case ({},_) then "";
    case (((v as BackendDAE.VAR(varName = cr,
                            varKind = kind,
                            varDirection = dir,
                            varType = var_type,
                            bindExp = e,
                            index = indx,
                            source = source,
                            values = dae_var_attr,
                            comment = comment,
                            flowPrefix = flowPrefix,
                            streamPrefix = streamPrefix)) :: {}),varno)
      equation
        varnostr = intString(varno);
        dirstr = DAEDump.dumpDirectionStr(dir);
        str1 = ComponentReference.printComponentRefStr(cr);
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
        str = DAEDump.dumpTypeStr(var_type);print( " type: "); print(str);

        print(" indx = ");
        print(indx_str);
        varno_1 = varno + 1;
        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        */
        str = System.stringAppendList({"'", str1, "'"});
      then
        str;

      case (((v as BackendDAE.VAR(varName = cr,
                              varKind = kind,
                              varDirection = dir,
                              varType = var_type,
                              bindExp = e,
                              index = indx,
                              source = source,
                              values = dae_var_attr,
                              comment = comment,
                              flowPrefix = flowPrefix,
                              streamPrefix = streamPrefix)) :: xs),varno)
      equation
        varnostr = intString(varno);
        dirstr = DAEDump.dumpDirectionStr(dir);
        str1 = ComponentReference.printComponentRefStr(cr);
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
        str = DAEDump.dumpTypeStr(var_type);print( " type: "); print(str);

        print(" indx = ");
        print(indx_str);

        print("fixed:");print(Util.boolString(varFixed(v)));
        print("\n");
        */
        varno_1 = varno + 1;
        str2 = dumpVars2(xs, varno_1);
        str = System.stringAppendList({"'", str1, "',", str2});
      then
        str;
  end matchcontinue;
end dumpVars2;

public function incidenceMatrix
"function: incidenceMatrix
  author: PA
  Calculates the incidence matrix, i.e. which
  variables are present in each equation."
  input BackendDAE.DAELow inDAELow;
  output list<String>[:] outIncidenceMatrix;
algorithm
  outIncidenceMatrix:=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Equation> eqnsl;
      list<list<String>> lstlst;
      list<String>[:] arr;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
    case (BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns))
      equation
        eqnsl = BackendDAEUtil.equationList(eqns);
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
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Equation> inEquationLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inVariables,inEquationLst)
    local
      list<list<String>> lst;
      list<String> row;
      BackendDAE.Variables vars;
      BackendDAE.Equation e;
      list<BackendDAE.Equation> eqns;
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
  input BackendDAE.Variables inVariables;
  input BackendDAE.Equation inEquation;
  output list<String> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inVariables,inEquation)
    local
      list<String> lst1,lst2,res,res_1;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e;
      list<list<String>> lst3;
      list<DAE.Exp> expl,inputs,outputs;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      BackendDAE.Value indx;
    case (vars,BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        lst1 = incidenceRowExp(e1, vars) "EQUATION" ;
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl)) /* ARRAY_EQUATION */
      equation
        lst3 = Util.listMap1(expl, incidenceRowExp, vars);
        res = Util.listFlatten(lst3);
      then
        res;
    case (vars,BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e)) /* SOLVED_EQUATION */
      equation
        lst1 = incidenceRowExp(DAE.CREF(cr,DAE.ET_REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e)) /* SOLVED_EQUATION */
      equation
        lst1 = incidenceRowExp(DAE.CREF(cr,DAE.ET_REAL()), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,BackendDAE.RESIDUAL_EQUATION(exp = e)) /* RESIDUAL_EQUATION */
      equation
        res = incidenceRowExp(e, vars);
      then
        res;
    case (vars,BackendDAE.WHEN_EQUATION(whenEquation = we)) /* WHEN_EQUATION */
      equation
        (cr,e2) = DAELow.getWhenEquationExpr(we);
        e1 = DAE.CREF(cr,DAE.ET_OTHER());
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;
    case (vars,BackendDAE.ALGORITHM(index = indx,in_ = inputs,out = outputs)) /* ALGORITHM For now assume that algorithm will be solvable for correct
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
  input BackendDAE.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inAlgorithmStatementLst,inVariables)
    local
      list<String> lst1,lst2,lst3,res,lst3_1;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      DAE.Exp e, e1;
      list<Algorithm.Statement> rest,stmts;
      BackendDAE.Variables vars;
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
      local list<list<String>> lst3;
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

protected function incidenceRowExp "function: incidenceRowExp
  author: PA

  Helper function to incidence_row, investigates expressions for
  variables, returning variable indexes.
"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inExp,inVariables)
    local
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Value> p,p_1;
      list<String> pStr,s1,s2,res,s3,lst_1;
      String s;
      list<list<String>> lst;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e,e3;
      list<DAE.Exp> expl;
    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),p) =
        DAELow.getVar(cr, vars) "If variable x is a state, der(x) is a variable in incidence matrix,
	                               x is inserted as negative value, since it is needed by debugging and index
	                               reduction using dummy derivatives" ;
        p_1 = Util.listMap1r(p, int_sub, 0);
        pStr = Util.listMap(p_1, intString);
      then
        pStr;
    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE()) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (DAE.BINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        pStr = listAppend(s1, s2);
      then
        pStr;
    case (DAE.UNARY(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        pStr = listAppend(s1, s2);
      then
        pStr;
    case (DAE.LUNARY(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
        pStr = listAppend(s1, s2);
      then
        pStr;
    case (DAE.IFEXP(expCond = e1 as DAE.RELATION(exp1 = ee1, operator = op1, exp2 =ee2),expThen = e2,expElse = e3),vars) /* if expressions. */
      local String ss, ss1, ss2, ss3, opStr;
        DAE.Exp ee1,ee2;
        DAE.Operator op1;
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
        ss = System.stringAppendList({"{'if', ",s,",'", opStr, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
    // if-expressions with a variable
//    case (DAE.IFEXP(expCond = e1 as DAE.CREF(componentRef = cref1),expThen = e2,expElse = e3),vars) /* if expressions. */
/*      local String ss,sb;
        String ss, ss1, ss2, ss3;
        DAE.ComponentRef cref1;
      equation
        sb = printExpStr(e1);
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = System.stringAppendList({"{'if', ","'", sb, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
*/

    // If expression with logic sentence.
    case (DAE.IFEXP(expCond = e1 as DAE.LBINARY(exp1 = ee1, operator = op1, exp2 =ee2),expThen = e2,expElse = e3),vars) /* if expressions. */
      local String ss, ss1, ss2, ss3, opStr, sb;
        DAE.Exp ee1,ee2;
        DAE.Operator op1;
      equation
        opStr = printExpStr(e1);
        //opStr = Exp.relopSymbol(op1);
        //s = printExpStr(ee2);
        sb = System.stringAppendList({"'true',","'=='"});
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        // build the string now
        ss = System.stringAppendList({"{'if', ",sb,",", "{",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
    // if-expressions with a variable (Bool)
    case (DAE.IFEXP(expCond = e1 as DAE.CREF(componentRef = cref1), expThen = e2, expElse = e3),vars) /* if expressions. */
      local String ss,sb;
        String ss, ss1, ss2, ss3;
        DAE.ComponentRef cref1;
      equation
        //sb = printExpStr(e1);

        sb = System.stringAppendList({"'true',","'=='"});
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = System.stringAppendList({"{'if', ", sb, " {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;

    // if-expressions with any other alternative than what we handled until now
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars) /* if expressions. */
      local String ss,sb;
        String ss, ss1, ss2, ss3;
        DAE.ComponentRef cref1;
      equation
        sb = printExpStr(e1);
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = System.stringAppendList({"{'if', ","'", sb, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        pStr;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (_,p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
      then
        {};
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF(componentRef = cr)}),vars) /* pre(v) is considered a known variable */ //IS IT????
      local String ss;
      equation
        (_,p) = DAELow.getVar(cr, vars);
        pStr = Util.listMap(p, intString);
        //ss = printExpStr(cr, vars);
        //pStr = ss;
      then
        pStr;
    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        pStr = Util.listFlatten(lst);
      then
        pStr;
    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = Util.listMap1(expl, incidenceRowExp, vars);
        pStr = Util.listFlatten(lst);
      then
        pStr;
    case (DAE.MATRIX(scalar = expl),vars)
      local list<list<tuple<DAE.Exp, Boolean>>> expl;
      equation
        pStr = incidenceRowMatrixExp(expl, vars);
      then
        pStr;
    case (DAE.TUPLE(PR = expl),vars)
      equation
        print("incidence_row_exp TUPLE not impl. yet.");
      then
        {};
    case (DAE.CAST(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (DAE.ASUB(exp = e),vars)
      equation
        pStr = incidenceRowExp(e, vars);
      then
        pStr;
    case (DAE.REDUCTION(expr = e1,range = e2),vars)
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
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst;
  input BackendDAE.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inTplExpExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> expl_1;
      list<list<String>> res1;
      list<tuple<DAE.Exp, Boolean>> expl;
      list<list<tuple<DAE.Exp, Boolean>>> es;
      list<String> pStr, res1_1, res2;
      BackendDAE.Variables vars;
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

protected function printExpStr
  input DAE.Exp e;
  output String s;
algorithm
  s := Exp.printExp2Str(e, "'", NONE(),NONE());
end printExpStr;

end DAEQuery;
