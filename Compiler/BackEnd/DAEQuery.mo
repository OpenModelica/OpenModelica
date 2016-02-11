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

encapsulated package DAEQuery
" file:        DAEQuery.mo
  package:     DAEQuery
  description: DAEQuery contains functionality for query of Incidence Matrix."


// public imports
public import BackendDAE;
public import SCode;

// protected imports
protected import Absyn;
protected import Algorithm;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import DAE;
protected import DAEDump;
protected import Expression;
protected import ExpressionDump;
protected import List;
protected import System;

protected constant String matlabStringDelim = "'";

public function writeIncidenceMatrix
  input BackendDAE.BackendDAE dlow;
  input String fileNamePrefix;
  input String flatModelicaStr;
  output String fileName;
algorithm
  fileName := match(dlow, fileNamePrefix, flatModelicaStr)
    local
      String file, strIMatrix, strVariables, flatStr, strEquations;
      array<list<String>> m;

    case (_, _, flatStr)
      equation
        file = stringAppend(fileNamePrefix, "_imatrix.m");
        m = incidenceMatrix(dlow);
        strIMatrix = getIncidenceMatrix(m);
        strVariables = getVariables(dlow);
        strEquations = getEquations(dlow);
        strIMatrix = stringAppendList({strIMatrix, "\n", strVariables, "\n\n\n", strEquations, "\n\n\n", flatStr});
        System.writeFile(file, strIMatrix);
      then
        file;
  end match;
end writeIncidenceMatrix;

public function getEquations
" @author adrpo
  This function returns the equations"
  input BackendDAE.BackendDAE inBackendDAE;
  output String strEqs;
protected
  BackendDAE.Shared shared;
  BackendDAE.EqSystem syst;
  list<String> ls1;
algorithm
    BackendDAE.DAE({syst}, shared) := inBackendDAE;
    ls1 := List.map(BackendEquation.equationList(syst.orderedEqs), equationStr);
    strEqs := "EqStr = {" + stringDelimitList(ls1, ",") + "};";
end getEquations;

public function equationStr
"Helper function to getEqustions."
  input BackendDAE.Equation inEquation;
  output String outString;
algorithm
  outString := match (inEquation)
    local
      String s1,s2,s3,res;
      DAE.Exp e1,e2,e,condition;
      DAE.ComponentRef cr;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({"'", s1," = ",s2, ";'"});
      then
        res;

    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({"'", s1," = ",s2, ";'"});
      then
        res;

    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2))
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({"'", s1," = ",s2, ";'"});
      then
        res;

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({"'",s1," = ",s2,";'"});
      then
        res;

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_STMTS(condition=condition,whenStmtLst={BackendDAE.ASSIGN(left = cr,right = e2)})))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ExpressionDump.printExpStr(condition);
        res = stringAppendList({"'when ", s3, " then " , s1," = ",s2,"; end when;'"});
      then
        res;

    case (BackendDAE.RESIDUAL_EQUATION(exp = e))
      equation
        s1 = ExpressionDump.printExpStr(e);
        res = stringAppendList({"'", s1,"= 0", ";'"});
      then
        res;

    case (BackendDAE.ALGORITHM())
      equation
        res = stringAppendList({"Algorithm\n"});
      then
        res;
  end match;
end equationStr;

protected function getIncidenceMatrix "gets the incidence matrix as a string"
  input array<list<String>> m;
  output String strIMatrix;
protected
  Integer mlen;
  String mlen_str;
  list<list<String>> m_1;
  String mstr;
algorithm
  mlen := arrayLength(m);
  mlen_str := intString(mlen);
  m_1 := arrayList(m);
  mstr := getIncidenceMatrix2(m_1,1);
  strIMatrix := stringAppendList({"% Incidence Matrix\n",
    "% ====================================\n", "% number of rows: ", mlen_str, "\n",
    "IM={", mstr, "};"});
end getIncidenceMatrix;

protected function getIncidenceMatrix2 "author: adrpo
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
    case ((row :: {}),_)
      equation
        str1 = getIncidenceRow(row);
        str = stringAppendList({"{", str1, "}"});
      then
        str;
    case ((row :: rows),_)
      equation
        str1 = getIncidenceRow(row);
        str2 = getIncidenceMatrix2(rows,rowIndex+1);
        str = stringAppendList({"{", str1, "},",  str2});
      then
        str;
  end matchcontinue;
end getIncidenceMatrix2;

protected function getIncidenceRow "author: adrpo
  Helper function to getIncidenceMatrix2.
"
  input list<String> inStringLst;
  output String strRow;
algorithm
  strRow :=
  matchcontinue (inStringLst)
    local
      String s,  s2, x;
      list<String> xs;
    case ({}) then "";
    case ((x :: {})) then x;
    case ((x :: xs))
      equation
        s2 = getIncidenceRow(xs);
        s = stringAppendList({x, ",", s2});
      then
        s;
  end matchcontinue;
end getIncidenceRow;

public function getVariables "This function returns the variables
"
  input BackendDAE.BackendDAE inBackendDAE;
  output String strVars;
algorithm
  strVars:=
  match (inBackendDAE)
    local
      list<BackendDAE.Var> vars;
      String s;
      BackendDAE.Variables vars1;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars1)::{}))
      equation
        vars = BackendVariable.varList(vars1);
        s = dumpVars(vars);
        s = "VL = {" + s + "};";
      then
        s;
  end match;
end getVariables;

public function dumpVars "Helper function to dump.
"
  input list<BackendDAE.Var> vars;
  output String strVars;
algorithm
  strVars := dumpVars2(vars, 1);
end dumpVars;

protected function dumpVars2 "Helper function to dump_vars.
"
  input list<BackendDAE.Var> inVarLst;
  input Integer inInteger;
  output String strVars;
algorithm
  strVars :=
  matchcontinue (inVarLst,inInteger)
    local
      String varnostr,dirstr,str,str1,str2;
      Integer varno_1,varno;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> e;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      list<BackendDAE.Var> xs;
      BackendDAE.Type var_type;
      DAE.ElementSource source;

    case ({},_) then "";
    case (((BackendDAE.VAR(varName = cr)) :: {}),_)
      equation
        str1 = ComponentReference.printComponentRefStr(cr);
        /*
        paths_lst = List.map(paths, Absyn.pathString);
        path_str = stringDelimitList(paths_lst, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print("= ");
        s = ExpressionDump.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx);
        str = DAEDump.dumpTypeStr(var_type);print( " type: "); print(str);

        print(" indx = ");
        print(indx_str);
        varno_1 = varno + 1;
        print("fixed:");print(boolString(varFixed(v)));
        print("\n");
        */
        str = stringAppendList({"'", str1, "'"});
      then
        str;

      case (((BackendDAE.VAR(varName = cr)) :: xs),varno)
      equation
        str1 = ComponentReference.printComponentRefStr(cr);
        /*
        paths_lst = List.map(paths, Absyn.pathString);
        path_str = stringDelimitList(paths_lst, ", ");
        comment_str = Dump.unparseCommentOption(comment);
        print("= ");
        s = ExpressionDump.printExpStr(e);
        print(s);
        print(" ");
        print(path_str);
        indx_str = intString(indx);
        str = DAEDump.dumpTypeStr(var_type);print( " type: "); print(str);

        print(" indx = ");
        print(indx_str);

        print("fixed:");print(boolString(varFixed(v)));
        print("\n");
        */
        varno_1 = varno + 1;
        str2 = dumpVars2(xs, varno_1);
        str = stringAppendList({"'", str1, "',", str2});
      then
        str;
  end matchcontinue;
end dumpVars2;

public function incidenceMatrix
"author: PA
  Calculates the incidence matrix, i.e. which
  variables are present in each equation."
  input BackendDAE.BackendDAE inBackendDAE;
  output array<list<String>> outIncidenceMatrix;
algorithm
  outIncidenceMatrix:=
  matchcontinue (inBackendDAE)
    local
      list<BackendDAE.Equation> eqnsl;
      list<list<String>> lstlst;
      array<list<String>> arr;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
    case (BackendDAE.DAE(eqs=BackendDAE.EQSYSTEM(orderedVars = vars,orderedEqs = eqns)::{}))
      equation
        eqnsl = BackendEquation.equationList(eqns);
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

protected function incidenceMatrix2 "author: PA

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

protected function incidenceRow "author: PA
  Helper function to incidence_matrix. Calculates the indidence row
  in the matrix for one equation."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Equation inEquation;
  output list<String> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inVariables,inEquation)
    local
      list<String> lst1,lst2,res,res_1;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      list<list<String>> lstres;
      DAE.Algorithm alg;

    // equation
    case (vars,BackendDAE.EQUATION(exp = e1,scalar = e2))
      equation
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;

    // array equation
    case (vars,BackendDAE.ARRAY_EQUATION(left=e1,right=e2))
      equation
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;

    // complex equation
    case (vars,BackendDAE.COMPLEX_EQUATION(left=e1,right=e2))
      equation
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;

    // solved equation
    case (vars,BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e))
      equation
        lst1 = incidenceRowExp(Expression.crefExp(cr), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;

    // solved equation
    case (vars,BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e))
      equation
        lst1 = incidenceRowExp(Expression.crefExp(cr), vars);
        lst2 = incidenceRowExp(e, vars);
        res = listAppend(lst1, lst2);
      then
        res;

    // residual equation
    case (vars,BackendDAE.RESIDUAL_EQUATION(exp = e))
      equation
        res = incidenceRowExp(e, vars);
      then
        res;

    // when equation
    case (vars,BackendDAE.WHEN_EQUATION(whenEquation = we))
      equation
        (cr,e2) = BackendEquation.getWhenEquationExpr(we);
        e1 = Expression.crefExp(cr);
        lst1 = incidenceRowExp(e1, vars);
        lst2 = incidenceRowExp(e2, vars);
        res = listAppend(lst1, lst2);
      then
        res;

   // ALGORITHM For now assume that algorithm will be solvable for correct
   // variables. I.e. find all variables in algorithm and add to lst.
   // If algorithm later on needs to be inverted, i.e. solved for
   // different variables than calculated, a non linear solver or
   // analysis of algorithm itself needs to be implemented.
    case (vars,BackendDAE.ALGORITHM(alg=alg))
      equation
        expl = Algorithm.getAllExps(alg);
        lstres = List.map1(expl, incidenceRowExp, vars);
        res_1 = List.flatten(lstres);
      then
        res_1;

    case (_,_)
      equation
        print("- DAEQuery.incidenceRow failed\n");
      then
        fail();
  end matchcontinue;
end incidenceRow;

// protected function incidenceRowStmts "author: PA
//   Helper function to incidenceRow, investigates statements for
//   variables, returning variable indexes."
//   input list<DAE.Statement> inAlgorithmStatementLst;
//   input BackendDAE.Variables inVariables;
//   output list<String> outStringLst;
// algorithm
//   outStringLst := matchcontinue (inAlgorithmStatementLst,inVariables)
//     local
//       list<String> lst1,lst2,lst3,res,lst3_1;
//       DAE.Type tp;
//       DAE.ComponentRef cr;
//       DAE.Exp e, e1;
//       list<DAE.Statement> rest,stmts;
//       BackendDAE.Variables vars;
//       list<DAE.Exp> expl;
//       DAE.Else else_;
//       list<list<String>> lstlst;
//
//     case ({},_) then {};
//
//     case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e1,exp = e) :: rest),vars)
//       equation
//         lst1 = incidenceRowStmts(rest, vars);
//         lst2 = incidenceRowExp(e, vars);
//         lst3 = incidenceRowExp(e1, vars);
//         res = List.flatten({lst1,lst2,lst3});
//       then
//         res;
//
//     case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl,exp = e) :: rest),vars)
//       equation
//         lst1 = incidenceRowStmts(rest, vars);
//         lst2 = incidenceRowExp(e, vars);
//         lstlst = List.map1(expl, incidenceRowExp, vars);
//         lst3_1 = List.flatten(lstlst);
//         res = List.flatten({lst1,lst2,lst3_1});
//       then
//         res;
//
//     case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr,exp = e) :: rest),vars)
//       equation
//         lst1 = incidenceRowStmts(rest, vars);
//         lst2 = incidenceRowExp(e, vars);
//         lst3 = incidenceRowExp(Expression.crefExp(cr), vars);
//         res = List.flatten({lst1,lst2,lst3});
//       then
//         res;
//
//     case ((DAE.STMT_IF(exp = e,statementLst = stmts,else_ = else_) :: rest),vars)
//       equation
//         print("- DAEQuery.incidenceRowStmts on IF not implemented\n");
//       then
//         {};
//
//     case ((DAE.STMT_FOR(type_ = _) :: rest),vars)
//       equation
//         print("- DAEQuery.incidenceRowStmts on FOR not implemented\n");
//       then
//         {};
//
//     case ((DAE.STMT_PARFOR(type_ = _) :: rest),vars)
//       equation
//         print("- DAEQuery.incidenceRowStmts on PARFOR not implemented\n");
//       then
//         {};
//
//     case ((DAE.STMT_WHILE(exp = _) :: rest),vars)
//       equation
//         print("- DAEQuery.incidenceRowStmts on WHILE not implemented\n");
//       then
//         {};
//
//     case ((DAE.STMT_WHEN(exp = e) :: rest),vars)
//       equation
//         print("- DAEQuery.incidenceRowStmts on WHEN not implemented\n");
//       then
//         {};
//
//     case ((DAE.STMT_ASSERT(cond = _) :: rest),vars)
//       equation
//         print("- DAEQuery.incidenceRowStmts on ASSERT not implemented\n");
//       then
//         {};
//   end matchcontinue;
// end incidenceRowStmts;

protected function incidenceRowExp "author: PA
  Helper function to incidenceRow, investigates expressions for
  variables, returning variable indexes."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inExp,inVariables)
    local
      list<Integer> p,p_1;
      list<String> pStr,s1,s2,s3;
      String s, ss, ss1, ss2, ss3, opStr, sb;
      list<list<String>> lst;
      DAE.ComponentRef cr,cref1;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2,e,e3,ee1,ee2;
      list<DAE.Exp> expl;
      DAE.Operator op1;
      list<list<DAE.Exp>> explTpl;
      DAE.ReductionIterators iters;

    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),p) =
        BackendVariable.getVar(cr, vars) "If variable x is a state, der(x) is a variable in incidence matrix,
                                 x is inserted as negative value, since it is needed by debugging and index
                                 reduction using dummy derivatives";
        p_1 = List.map1r(p, intSub, 0);
        pStr = List.map(p_1, intString);
      then
        pStr;

    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE()) :: _),p) = BackendVariable.getVar(cr, vars);
        pStr = List.map(p, intString);
      then
        pStr;

    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE()) :: _),p) = BackendVariable.getVar(cr, vars);
        pStr = List.map(p, intString);
      then
        pStr;

    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER()) :: _),p) = BackendVariable.getVar(cr, vars);
        pStr = List.map(p, intString);
      then
        pStr;

    case (DAE.CREF(componentRef = cr),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE()) :: _),p) = BackendVariable.getVar(cr, vars);
        pStr = List.map(p, intString);
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

    case (DAE.IFEXP(expCond = e1 as DAE.RELATION(operator = op1, exp2 =ee2),expThen = e2,expElse = e3),vars) /* if expressions. */
      equation
        opStr = ExpressionDump.relopSymbol(op1);
        s = printExpStr(ee2);
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        // build the string now
        ss = stringAppendList({"{'if', ",s,",'", opStr, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
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
        ss = stringAppendList({"{'if', ","'", sb, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
*/

    // If expression with logic sentence.
    case (DAE.IFEXP(expCond = e1 as DAE.LBINARY(),expThen = e2,expElse = e3),vars) /* if expressions. */
      equation
        _ = printExpStr(e1);
        //opStr = ExpressionDump.relopSymbol(op1);
        //s = printExpStr(ee2);
        sb = stringAppendList({"'true',","'=='"});
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        // build the string now
        ss = stringAppendList({"{'if', ",sb,",", "{",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;
    // if-expressions with a variable (Bool)
    case (DAE.IFEXP(expCond = e1 as DAE.CREF(), expThen = e2, expElse = e3),vars) /* if expressions. */
      equation
        //sb = printExpStr(e1);

        sb = stringAppendList({"'true',","'=='"});
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = stringAppendList({"{'if', ", sb, " {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;

    // if-expressions with any other alternative than what we handled until now
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),vars) /* if expressions. */
      equation
        sb = printExpStr(e1);
        s1 = incidenceRowExp(e1, vars);
        ss1 = getIncidenceRow(s1);
        s2 = incidenceRowExp(e2, vars);
        ss2 = getIncidenceRow(s2);
        s3 = incidenceRowExp(e3, vars);
        ss3 = getIncidenceRow(s3);
        ss = stringAppendList({"{'if', ","'", sb, "' {",ss1,"}",",{", ss2, "},", ss3, "}"});
        pStr = {ss};
      then
        pStr;

    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        ((BackendDAE.VAR(varKind = BackendDAE.STATE()) :: _),p) = BackendVariable.getVar(cr, vars);
        pStr = List.map(p, intString);
      then
        pStr;

    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (_,p) = BackendVariable.getVar(cr, vars);
        _ = List.map(p, intString);
      then
        {};

    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {DAE.CREF(componentRef = cr)}),vars) /* pre(v) is considered a known variable */ //IS IT????
      equation
        (_,p) = BackendVariable.getVar(cr, vars);
        pStr = List.map(p, intString);
        //ss = printExpStr(cr, vars);
        //pStr = ss;
      then
        pStr;

    case (DAE.CALL(path = Absyn.IDENT(name = "previous"),expLst = {DAE.CREF(componentRef = cr)}),vars) /* previous(v) is considered a known variable*/
      equation
        (_,p) = BackendVariable.getVar(cr, vars);
        pStr = List.map(p, intString);
        //ss = printExpStr(cr, vars);
        //pStr = ss;
      then
        pStr;

    case (DAE.CALL(expLst = expl),vars)
      equation
        lst = List.map1(expl, incidenceRowExp, vars);
        pStr = List.flatten(lst);
      then
        pStr;

    case (DAE.ARRAY(array = expl),vars)
      equation
        lst = List.map1(expl, incidenceRowExp, vars);
        pStr = List.flatten(lst);
      then
        pStr;

    case (DAE.MATRIX(matrix = explTpl),vars)
      equation
        pStr = incidenceRowMatrixExp(explTpl, vars);
      then
        pStr;

    case (DAE.TUPLE(),_)
      equation
        print("- DAEQuery.incidence_row_exp TUPLE not impl. yet.");
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

    case (DAE.REDUCTION(expr = e1,iterators = iters),vars)
      equation
        s1 = incidenceRowExp(e1, vars);
        lst = List.map1(iters, incidenceRowIter, vars);
        pStr = List.flatten(s1::lst);
      then
        pStr;
    case (_,_) then {};
  end matchcontinue;
end incidenceRowExp;

protected function incidenceRowIter
  input DAE.ReductionIterator iter;
  input BackendDAE.Variables vars;
  output list<String> strs;
algorithm
  strs := match (iter,vars)
    local
      DAE.Exp e1,e2;
      list<String> s1,s2;
    case (DAE.REDUCTIONITER(guardExp = SOME(e1), exp = e2),_)
      equation
        s1 = incidenceRowExp(e1, vars);
        s2 = incidenceRowExp(e2, vars);
      then listAppend(s1,s2);
    case (DAE.REDUCTIONITER(exp = e1),_)
      then incidenceRowExp(e1, vars);
  end match;
end incidenceRowIter;

protected function incidenceRowMatrixExp "author: PA
  Traverses matrix expressions for building incidence matrix."
  input list<list<DAE.Exp>> inTplExpExpBooleanLstLst;
  input BackendDAE.Variables inVariables;
  output list<String> outStringLst;
algorithm
  outStringLst := match (inTplExpExpBooleanLstLst,inVariables)
    local
      list<DAE.Exp> expl_1;
      list<list<String>> res1;
      list<list<DAE.Exp>> es;
      list<String> pStr, res1_1, res2;
      BackendDAE.Variables vars;
    case ({},_) then {};
    case ((expl_1 :: es),vars)
      equation
        res1 = List.map1(expl_1, incidenceRowExp, vars);
        res2 = incidenceRowMatrixExp(es, vars);
        res1_1 = List.flatten(res1);
        pStr = listAppend(res1_1, res2);
      then
        pStr;
  end match;
end incidenceRowMatrixExp;

protected function printExpStr
  input DAE.Exp e;
  output String s;
algorithm
  s := ExpressionDump.printExp2Str(e, "'", NONE(),NONE());
end printExpStr;

annotation(__OpenModelica_Interface="backend");
end DAEQuery;
