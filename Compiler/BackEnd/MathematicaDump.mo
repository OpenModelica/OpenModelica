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

encapsulated package MathematicaDump

  import BackendDAE;
  import BackendDump;
  import BackendVariable;
  import ComponentReference;
  import DAE;
  import Util;
  import List;
  import Absyn;
  import System;
  import ExpressionDump;
  import IOStream;
  import DAEDump;

public function dumpMmaDAEStr "
Dumps the equations, initial equations variables and parameters on a form suitable
for reading into Mathematica"
input tuple<BackendDAE.Variables,BackendDAE.Variables,list<BackendDAE.Equation>,list<BackendDAE.Equation>> inTuple "(vars, knvars, eqsn, ieqns)";
output String res;
algorithm
  res := match(inTuple)
    local
      BackendDAE.Variables vars,knvars;
      list<BackendDAE.Equation> eqns,ieqns;
      String allVarStr,s1_1,s1_2,s1_3,s1_4,s1_5,s3,s4;
      list<String> params,inputs,states,algs,outputs,inputsStates;
    case((vars,knvars,eqns,ieqns)) equation

        (states,algs,outputs,_) = printMmaVarsStr(vars);
        (params,inputs) = printMmaParamsStr(knvars);
        //inputs = listAppend(inputs,inputsStates); This should not happen, if a input is used as a state, index reduction should be active!
        s1_1 = Util.stringDelimitListNonEmptyElts(states,",");
        //print(" states: " + s1_1 + "\n");
        s1_2 = Util.stringDelimitListNonEmptyElts(algs,",");
        //print(" algs: " + s1_2 + "\n");
        s1_3 = Util.stringDelimitListNonEmptyElts(outputs,",");
        //print(" outputs: " + s1_3 + "\n");
        s1_4 = Util.stringDelimitListNonEmptyElts(inputs,",");
        //print(" inputs: " + s1_4 + "\n");
        s1_5 = Util.stringDelimitListNonEmptyElts(params,",");
        //print(" params: " + s1_5 + "\n");
        allVarStr = "{{" + s1_1 + "},{" + s1_2 + "},{" + s1_3 + "},{" + s1_4 + "},{" + s1_5 + "}}";
        //print(" vars: " + allVarStr + "\n");

        s3 = printMmaEqnsStr(eqns,(vars,knvars));
        s4 = printMmaEqnsStr(ieqns,(vars,knvars));
        res = stringAppendList({"{",allVarStr,",",s3,",",s4,"}"});
        //print(" Eqns-1-: " + s3 + "\n");
        //print(" Eqns-2-: " + s4 + "\n");
    then res;
  end match;
end dumpMmaDAEStr;

public function printMmaEqnsStr "print equations on a form suitable for Mathematica to a string."
  input list<BackendDAE.Equation> inEqns;
  input tuple<BackendDAE.Variables,BackendDAE.Variables> inTuple;
  output String res;
algorithm
  res := match(inEqns,inTuple)
    local
      String s1;
      list<BackendDAE.Equation> eqns;
    case (eqns,_) equation
      s1 = Util.stringDelimitListNonEmptyElts(List.map1(eqns,printMmaEqnStr,inTuple),",");
      res = stringAppendList({"{",s1,"}"});
    then res;
  end match;
end printMmaEqnsStr;

public function printMmaEqnStr "help function to printMmaEqnsStr"
  input BackendDAE.Equation eqn;
  input tuple<BackendDAE.Variables,BackendDAE.Variables> inTuple "required to find array eqns and algorithms";
  output String str;
algorithm
  str := match(eqn,inTuple)
  local DAE.Exp e1,e2;
    DAE.ComponentRef cr;
    BackendDAE.Variables vars,knvars;
    String s1,s2;
    DAE.Algorithm alg;
    BackendDAE.WhenEquation whenEq;

    case(BackendDAE.EQUATION(exp=e1,scalar=e2),(vars,knvars)) equation
      s1 = printExpMmaStr(e1,vars,knvars);
      s2 = printExpMmaStr(e2,vars,knvars);
      str = stringAppendList({s1,"==",s2});
      then str;
    case(BackendDAE.SOLVED_EQUATION(componentRef=cr,exp=e2),(vars,knvars)) equation
      s1 = printComponentRefMmaStr(cr,vars,knvars);
      s2 = printExpMmaStr(e2,vars,knvars);
      str = stringAppendList({s1,"==",s2});
      then str;
    case(BackendDAE.ARRAY_EQUATION(left=e1,right=e2),(vars,knvars)) equation
      s1 = printExpMmaStr(e1,vars,knvars);
      s2 = printExpMmaStr(e2,vars,knvars);
      str = stringAppendList({s1,"==",s2});
      then str;
    case(BackendDAE.RESIDUAL_EQUATION(exp = e1),(vars,knvars)) equation
      s1 = printExpMmaStr(e1,vars,knvars);
      str = stringAppendList({s1,"== 0"});
    then str;

    case (BackendDAE.ALGORITHM(alg=alg),(_,_)) equation
      str = "Missing[\"Algorithm\",\""+escapeMmaString(dumpSingleAlgorithmStr(alg))+"\"]";
    then str;
    case (BackendDAE.WHEN_EQUATION(whenEquation = whenEq),(_,_)) equation
      str = "Missing[\"When\",\""+escapeMmaString(BackendDump.whenEquationString(whenEq, true))+"\"]";
    then str;
    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2),(vars,knvars))
      equation
      s1 = printExpMmaStr(e1,vars,knvars);
      s2 = printExpMmaStr(e2,vars,knvars);
      str = stringAppendList({s1,"==",s2});
      then str;
  end match;
end printMmaEqnStr;


/* Printing of equations and variables on Mathematica format*/

public function printExpMmaStr "Prints an expression on format suitable for Mathematica to a string"
  input DAE.Exp e;
  input BackendDAE.Variables vars "Required since variables should be translated from a to a[t]";
  input BackendDAE.Variables knvars "inputs and outputs should also have [t] suffixed";
  output String s;
algorithm
  s := printExp2MmaStr(e,vars,knvars);
end printExpMmaStr;

protected function printExp2MmaStr "Helper function to printExpMmaStr"
  input DAE.Exp inExp;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp,vars,knvars)
    local
      String s,s_1,s1_1,s_2,s2_1,sym,s2,s3,s3_1,s4,s_3,ifstr,thenstr,elsestr,res,fs,argstr,s_4,s_5,res2,str,crstr,dimstr,expstr,iterstr,id;
      Integer p,p1,p2,ival,i,pstart,pstop,pe1;
      DAE.ComponentRef cr;
      DAE.Type tp;
      DAE.Exp e1,e2,e,f,start,stop,step,dim,exp,iterexp,c,t;
      DAE.Operator op;
      Absyn.Path fcn,path;
      list<DAE.Exp> args,es;
      Real x,x2;
      String fname,s1;
      String s_11;
      list<list<DAE.Exp>> matrix;
      list<DAE.Exp> ae1,expLst;
      DAE.CallAttributes call_attr;


    //case (DAE.END(),_,_) then "-1"; // Part[exp,-1] Returns last element in Mathematica.
    case (DAE.ICONST(integer = i),_,_) equation
      s = intString(i);
    then s;
    case (DAE.RCONST(real = x),_,_)  equation
      x2 = intReal(realInt(x));
      true = realEq(x2,x);
      s = intString(realInt(x));
    then s;

    case (DAE.RCONST(real = x),_,_)
      equation
        s = realString(x);
        s = stringAppendList({"ToExpression[StringReplace[\"",s,"\",\"e\"->\"*1.0*10^\"]]"});
      then
        s;
    case (DAE.SCONST(string = s),_,_)
      equation
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
      then
        s_2;
    case (DAE.BCONST(bool = false),_,_) then "False";
    case (DAE.BCONST(bool = true),_,_) then "True";

    case (DAE.CREF(componentRef = cr),_,_) equation
        s = printComponentRefMmaStr(cr,vars,knvars);
    then s;

    case (e as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),_,_)
      equation
        sym = ExpressionDump.binopSymbol(op);
        s1 = printExp2MmaStr(e1,vars,knvars);
        s2 = printExp2MmaStr(e2,vars,knvars);
        p = ExpressionDump.expPriority(e);
        p1 = ExpressionDump.expPriority(e1);
        p2 = ExpressionDump.expPriority(e2);
        s1_1 = ExpressionDump.parenthesize(s1, p1, p,false);
        s2_1 = ExpressionDump.parenthesize(s2, p2, p,true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;

    case (e as DAE.UNARY(operator = op,exp = e1),_,_)
      equation
        sym = ExpressionDump.unaryopSymbol(op);
        s = printExp2MmaStr(e1, vars,knvars);
        p = ExpressionDump.expPriority(e);
        p1 = ExpressionDump.expPriority(e1);
        s_1 = ExpressionDump.parenthesize(s, p1, p,true);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;

    case (e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),_,_)
      equation
        sym = lbinopSymbolMma(op);
        s1 = printExp2MmaStr(e1, vars,knvars);
        s2 = printExp2MmaStr(e2, vars,knvars);
        p = ExpressionDump.expPriority(e);
        p1 = ExpressionDump.expPriority(e1);
        p2 = ExpressionDump.expPriority(e2);
        s1_1 = ExpressionDump.parenthesize(s1, p1, p,false);
        s2_1 = ExpressionDump.parenthesize(s2, p2, p,true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;

    case (e as DAE.LUNARY(operator = op,exp = e1),_,_)
      equation
        sym = lunaryopSymbolMma(op);
        s = printExp2MmaStr(e1, vars,knvars);
        p = ExpressionDump.expPriority(e);
        p1 = ExpressionDump.expPriority(e1);
        s_1 = ExpressionDump.parenthesize(s, p1, p,true);
        s_2 = stringAppend(sym, s_1);
      then
        s_2;

    case (e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),_,_)
      equation
        sym = relopSymbolMma(op);
        s1 = printExp2MmaStr(e1,vars,knvars);
        s2 = printExp2MmaStr(e2,vars,knvars);
        p = ExpressionDump.expPriority(e);
        p1 = ExpressionDump.expPriority(e1);
        _ = ExpressionDump.expPriority(e2);
        s1_1 = ExpressionDump.parenthesize(s1, p1, p,false);
        s2_1 = ExpressionDump.parenthesize(s2, p1, p,true);
        s = stringAppend(s1_1, sym);
        s_1 = stringAppend(s, s2_1);
      then
        s_1;

    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f),_,_)

      equation
        ifstr = printExp2MmaStr(c,vars,knvars);
        thenstr = printExp2MmaStr(t,vars,knvars);
        elsestr = printExp2MmaStr(f,vars,knvars);
        res = stringAppendList({"If[ ",ifstr,", ",thenstr," ,",elsestr,"]"});
      then
        res;
    case (DAE.CALL(path = Absyn.IDENT("der"),expLst = {e}),_,_)
      equation
        s_1 =printExpMmaStr(e,vars,knvars);
        s_2 = stringAppendList({"D[",s_1,",\\[FormalT]]"});
      then s_2;

    // Math functions in Modelica.Math checked against builtin functions
    case(DAE.CALL(Absyn.QUALIFIED("Modelica",Absyn.QUALIFIED("Math",path)),expLst,call_attr),_,_) equation
      s = printExp2MmaStr(DAE.CALL(path,expLst,call_attr),vars,knvars);
    then s;
    case(DAE.CALL(Absyn.FULLYQUALIFIED(Absyn.QUALIFIED("Modelica",Absyn.QUALIFIED("Math",path))),expLst,call_attr),_,_) equation
      s = printExp2MmaStr(DAE.CALL(path,expLst,call_attr),vars,knvars);
    then s;

    case (DAE.CALL(path = Absyn.IDENT(fname),expLst = expLst),_,_)
      equation
        s1 = printBuiltinMmaFunc(fname);
        s_1 = stringDelimitList(List.map2(expLst,printExpMmaStr,vars,knvars),",");
        s_2 = stringAppendList({s1,"[",s_1,"]"});
      then s_2;

        /* Special case for atan2 */
    case (DAE.CALL(path = Absyn.IDENT("atan2"),expLst = {e1,e2}),_,_)

      equation
        s_1 =printExpMmaStr(e1,vars,knvars);
        s_11 =printExpMmaStr(e2,vars,knvars);
        s_2 = stringAppendList({"ArcTan[",s_1,",",s_11,"]"});
      then s_2;

    /* Special case for log10 */
    case (DAE.CALL(path = Absyn.IDENT("log10"),expLst = {e1}),_,_)
      equation
        s_1 =printExpMmaStr(e1,vars,knvars);
        s_2 = stringAppendList({"Log[",s_1,",10]"});
      then s_2;
    case (DAE.CALL(path = fcn,expLst = args),_,_)
      equation
        fs = Absyn.pathString(fcn);
        fs = translateKnownMmaFuncs(fs); // can fail
        argstr = stringDelimitList(List.map2(args, printExpMmaStr,vars,knvars),",");
        s = stringAppend(fs, "[");
        s_1 = stringAppend(s, argstr);
        s_2 = stringAppend(s_1, "]");
      then
        s_2;

    case (DAE.CALL(path = fcn,expLst = args),_,_)
      equation
        fs = Absyn.pathString(fcn);
        argstr = stringDelimitList(List.map2(args, printExpMmaStr,vars,knvars),",");
        s_2 = "FunctionCall[\""+ fs +"\"]["+argstr+"]";
      then
        s_2;

    case (DAE.ARRAY(array = es),_,_)
      equation
        s = stringDelimitList(List.map2(es, printExpMmaStr,vars,knvars),",");
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;
    case (DAE.TUPLE(PR = es),_,_)
      equation
        s = stringDelimitList(List.map2(es, printExpMmaStr,vars,knvars),",");
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;
    case (DAE.MATRIX(matrix = matrix),_,_)
      equation
        s = stringDelimitList(List.map2(matrix, printRowMmaStr,vars,knvars), "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
      then
        s_2;
    case (e as DAE.RANGE(start = start,step = NONE(),stop = stop),_,_)
      equation
        s1 = printExp2MmaStr(start, vars,knvars);
        s3 = printExp2MmaStr(stop, vars,knvars);
        p = ExpressionDump.expPriority(e);
        pstart = ExpressionDump.expPriority(start);
        pstop = ExpressionDump.expPriority(stop);
        s1_1 = ExpressionDump.parenthesize(s1, pstart, p,false);
        s3_1 = ExpressionDump.parenthesize(s3, pstop, p,false);
        s_3 = stringAppendList({"Range[",s1_1,",",s3_1,"]"}); // Range[start,stop]
      then
        s_3;

    case (DAE.RANGE(start = start,step = SOME(step),stop = stop),_,_)
      equation
        s2 = printExp2MmaStr(start, vars,knvars);
        s3 = printExp2MmaStr(step, vars,knvars);
        s4 = printExp2MmaStr(stop, vars,knvars);
        s_5 =  stringAppendList({"Range[",s2,",",s4,",",s3,"]"}); // Range[start,stop,step]
      then
        s_5;
        /* We prevent casts since we probably do not want numerical values, e.g. Sqrt[2.0] should probably be Sqrt[2] instead*/
    case (DAE.CAST(ty =  DAE.T_REAL(_,_),exp = DAE.ICONST(integer = ival)),_,_)
      equation
        res = intString(ival);
      then
        res;
        /* We prevent casts since we probably do not want numerical values, e.g. Sqrt[2.0] should probably be Sqrt[2] instead*/
    case (DAE.CAST(ty =  DAE.T_REAL(_,_),exp = DAE.UNARY(operator = DAE.UMINUS(),exp = DAE.ICONST(integer = ival))),_,_)
      equation
        res = intString(ival);
        res2 = stringAppend("-", res);
      then
        res2;
    case (DAE.CAST(ty =  DAE.T_REAL(_,_),exp = e),_,_)
      equation
        s = printExpMmaStr(e,vars,knvars);
      then
        s;
    case (e as DAE.ASUB(exp = e1,sub = ae1),_,_)

      equation
        p = ExpressionDump.expPriority(e);
        pe1 = ExpressionDump.expPriority(e1);
        s1 = printExp2MmaStr(e1,vars,knvars);
        s1_1 = ExpressionDump.parenthesize(s1, pe1, p,false);
        s4 = stringDelimitList(List.map2(ae1,printExp2MmaStr,vars,knvars),", ");
        s_4 ="Index["+ s1_1+",{" +s4 + "}]";
      then
        s_4;

    case (DAE.SIZE(exp = e,sz = SOME(dim)),_,_)
      equation
        crstr = printExpMmaStr(e,vars,knvars);
        dimstr = printExpMmaStr(dim,vars,knvars);
        str = stringAppendList({"Dimensions[",crstr,"][[",dimstr,"]]"});
      then
        str;
    case (DAE.SIZE(exp = e,sz = NONE()),_,_)
      equation
        crstr = printExpMmaStr(e,vars,knvars);
        str = stringAppendList({"Dimensions[",crstr,"]"});
      then
        str;
    case (DAE.REDUCTION(DAE.REDUCTIONINFO(path = fcn),exp,(DAE.REDUCTIONITER(id = id,exp = iterexp)::_)),_,_) //TODO: need to suport more than one iterator.
      equation
        fs = Absyn.pathString(fcn);
        expstr = printExpMmaStr(exp,vars,knvars);
        iterstr = printExpMmaStr(iterexp,vars,knvars);
        str = stringAppendList({"Table[",fs,"[",expstr,"],{",id,", ",iterstr,"}]"});
      then
        str;

    case(DAE.ENUM_LITERAL(name=path),_,_) equation
      str = Absyn.pathString(path);
      str = "Missing[\"ModelicaName\",\""+str+"\"]";
    then str;

    case (e,_,_) equation
      str = "Missing[\"UnknownExpression\",\""+ExpressionDump.printExpStr(e)+"\"]";
    then str;
  end matchcontinue;
end printExp2MmaStr;


protected function printComponentRefMmaStr "prints a ComponentRef to a string suitable for input to Mathematica"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output String res;
algorithm
  res := matchcontinue(cr,vars,knvars)
    local
      String nameStr;
      Boolean isInput,isOutput;
      BackendDAE.Var v;

    case (DAE.CREF_IDENT("time",_,_),_,_) then "\\[FormalT]";

      // Variables
    case (_,_,_) equation
      (_,_)=BackendVariable.getVar(cr,vars);
      nameStr = ComponentReference.printComponentRefStr(cr);
      // If already translated variables.
      nameStr = System.stringReplace(nameStr,"$p",".");
      nameStr = System.stringReplace(nameStr,"$lb","[");
      nameStr = System.stringReplace(nameStr,"$rb","]");
      nameStr = System.stringReplace(nameStr,"$leftParentesis","[");
      nameStr = System.stringReplace(nameStr,"$rightParentesis","]");

      nameStr = System.stringReplace(nameStr,"(","[");
      nameStr = System.stringReplace(nameStr,")","]");
      // if not translated variables
      nameStr = System.stringReplace(nameStr,"_","\\[UnderBracket]");

      nameStr = wrapInMember(nameStr);
      nameStr = addMissingForQuotedNames(nameStr);
      res = stringAppendList({nameStr,"[\\[FormalT]]"});
    then res;

        // Input or output variables
    case (_,_,_)

      equation

      (v::_,_)=BackendVariable.getVar(cr,knvars);
      isInput = BackendVariable.isInput(v);
      isOutput = BackendVariable.isOutputVar(v);
      true = boolOr(isInput,isOutput);
      nameStr = ComponentReference.printComponentRefStr(cr);

      // If already translated variables.
      nameStr = System.stringReplace(nameStr,"$p",".");
      nameStr = System.stringReplace(nameStr,"$lb","[");
      nameStr = System.stringReplace(nameStr,"$rb","]");
      nameStr = System.stringReplace(nameStr,"$leftParentesis","(");
      nameStr = System.stringReplace(nameStr,"$rightParentesis",")");
      // if not translated variables
      nameStr = System.stringReplace(nameStr,"_","\\[UnderBracket]");

      nameStr = wrapInMember(nameStr);
      nameStr = addMissingForQuotedNames(nameStr);
      res = stringAppendList({nameStr,"[\\[FormalT]]"});
    then res;

      // Parameters, etc.
    case (_,_,_) equation
      failure((_,_)=BackendVariable.getVar(cr,vars));
      nameStr = ComponentReference.printComponentRefStr(cr);
      // If already translated variables.
      nameStr = System.stringReplace(nameStr,"$p",".");
      nameStr = System.stringReplace(nameStr,"$lb","[");
      nameStr = System.stringReplace(nameStr,"$rb","]");
      nameStr = System.stringReplace(nameStr,"$leftParentesis","(");
      nameStr = System.stringReplace(nameStr,"$rightParentesis",")");
      // if not translated variables
      nameStr = System.stringReplace(nameStr,"_","\\[UnderBracket]");
      nameStr = wrapInMember(nameStr);
    then nameStr;
  end matchcontinue;
end printComponentRefMmaStr;

protected function wrapInMember "Help function to printComponentRefMmaStr, wraps Member[ ] round
dotted names and replaces '.' with ','"
  input String str;
  output String outStr;
  protected
    String s1,s2,s3;// Boolean b;
algorithm
  //b := Util.stringContainsChar(str,".");
  //b := true; // always wrap the names
  //s1 := if_(b,"Member[","");
  //s2 := if_(b,"]","");
  s3 := System.stringReplace(str,".","\\[UpPointer]");
  //outStr := stringAppendList({s1,s3,s2});
  outStr := s3;
end wrapInMember;

protected function addMissingForQuotedNames " Wraps name in Missing if quoted name, e.g. '1'"
  input String name;
  output String res;
algorithm
  res := matchcontinue(name)
    case _ equation
      false = -1 == System.stringFind(name,"'");
      res = "Missing[\"QuotedName\",\""+System.stringReplace(name,"\\","\\\\")+"\"]";
    then res;
    case _ then name;
  end matchcontinue;
end addMissingForQuotedNames;

protected function lbinopSymbolMma "Return string representation of logical binary operator on Mathematica format
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.AND(_)) then " && ";
    case (DAE.OR(_)) then " || ";
  end match;
end lbinopSymbolMma;

protected function lunaryopSymbolMma "
  Return string representation of logical unary operator for Mathematica
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.NOT(_)) then " ! ";
  end match;
end lunaryopSymbolMma;

protected function relopSymbolMma "
  Return string representation of function operator for Mathematica.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString := match (inOperator)
    case (DAE.LESS()) then " < ";
    case (DAE.LESSEQ()) then " <= ";
    case (DAE.GREATER()) then " > ";
    case (DAE.GREATEREQ()) then " >= ";
    case (DAE.EQUAL()) then " == ";
    case (DAE.NEQUAL()) then " != "; // differs from Modelica which has '<>'
  end match;
end relopSymbolMma;

protected function printBuiltinMmaFunc "Translates builtin function to corresponding Mma function"
input String modelicaFuncName;
output String mathematicaFuncName;
algorithm
  mathematicaFuncName := match(modelicaFuncName)
    case("sqrt") then "Sqrt";
    case("abs") then "Abs";
    case("sign") then "Sign";
    case("Integer") then "IntegerPart";
    case("div") then "Rational";
    case("max") then "Max";
    case("min") then "Min";
    case("mod") then "Quotient";
    case("rem") then "Mod";
    case("ceil") then "Cieling";
    case("floor") then "Floor";
    case("integer") then "IntegerPart";
    case("sin") then "Sin";
    case("cos") then "Cos";
    case("tan") then "Tan";
    case("asin") then "ArcSin";
    case("acos") then "ArcCos";
    case("atan") then "ArcTan";
    /* atan2 not possible here. */
    case("sinh") then "Sinh";
    case("cosh") then "Cosh";
    case("tanh") then "Tanh";
    case("exp") then "Exp";
    case("log") then "Log";
    /* log10 not possible here. */
  end match;
end printBuiltinMmaFunc;

protected function translateKnownMmaFuncs "Translates some internal functions to corresponding Mathematica function"
  input String func;
  output String mmaFunc;
algorithm
  mmaFunc := match(func)
    case("sin") then "Sin";
    case("Modelica.Math.sin") then "Sin";
    case("cos") then "Cos";
    case("Modelica.Math.cos") then "Cos";
    case("tan") then "Tan";
    case("Modelica.Math.tan") then "Tan";
    case("exp") then "Exp";
    case("Modelica.Math.exp") then "Exp";
  end match;
end translateKnownMmaFuncs;

protected function printRowMmaStr "Prints a list of expressions to a string on Mathematica format.
"
  input list<DAE.Exp> es;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output String s;
protected
  list<DAE.Exp> es_1;
algorithm
  s := stringDelimitList(List.map2(es, printExpMmaStr, vars,knvars),",");
end printRowMmaStr;

protected function escapeMmaString "help function to e.g printMmaEqnStr, escapes characters in strings generated to mathematica"
  input String str;
  output String res;
algorithm
  res := System.stringReplace(str,"\"","\\\"");
end escapeMmaString;


protected function dumpSingleAlgorithmStr "Help function to dump, prints algorithms to stdout"
  input DAE.Algorithm algs;
  output String outString;
algorithm
  outString := match(algs)
    local
      list<DAE.Statement> stmts;
      String str;
      IOStream.IOStream myStream;
    case(DAE.ALGORITHM_STMTS(stmts)) equation
      myStream = IOStream.create("", IOStream.LIST());
      myStream = DAEDump.dumpAlgorithmStream(DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),DAE.emptyElementSource), myStream);
      str = IOStream.string(myStream);
    then str;
  end match;
end dumpSingleAlgorithmStr;

public function printMmaVarsStr "print variables on a form suitable for Mathematica to a string.
$p,$lb, $rb, $leftParentesis, $rightParentesis removed.
$derivative<varname> replaced by D[<varname>,t]
All variables returned as Mma lists on form {{states},{algvars}, e.g. {{Iii},{abc, R1i, R2pi}}
"
input BackendDAE.Variables vars;
output list<String> states;
output list<String> algs;
output list<String> outputs;
output list<String> inputs;
algorithm
  (states,algs,outputs,inputs) := match(vars)
    local
      list<BackendDAE.Var> varLst;
    case _
      equation
        varLst = BackendVariable.varList(vars);
        varLst = listReverse(varLst); //So the order is the same as for generated c-code.
        states = List.map2(varLst,printMmaVarStr,true,vars);
        algs = List.map2(varLst,printMmaVarStr,false,vars);
        outputs = List.map(varLst,printMmaOutputStr);
        inputs = List.map(varLst,printMmaInputStr);
      then
        (states,algs,outputs,inputs);
  end match;
end printMmaVarsStr;

public function printMmaVarStr "help function to printMmaVarsStr"
  input BackendDAE.Var v;
  input Boolean selectKind "true for dumping states, false for algebraic vars";
  input BackendDAE.Variables allVars;
  output String str;
algorithm
  str := matchcontinue(v,selectKind,allVars)
  local DAE.ComponentRef name;
    String nameStr;
    case (BackendDAE.VAR(varName=DAE.CREF_IDENT("$dummy",DAE.T_UNKNOWN(_),{})),_,_) then "";
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE()),true,_)
      equation
        nameStr = printComponentRefMmaStr(name,allVars,BackendVariable.emptyVars());
      then nameStr;
    //case (BackendDAE.VAR(varName=name,varKind=BackendDAE.DYN_STATE()),true,allVars)
    // equation
    //    nameStr = printComponentRefMmaStr(name,allVars,BackendVariable.emptyVars());
    //  then nameStr;
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.VARIABLE()),false,_)
      equation
        nameStr = printComponentRefMmaStr(name,allVars,BackendVariable.emptyVars());
      then nameStr;
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.DUMMY_DER()),false,_)
      equation
        nameStr = printComponentRefMmaStr(name,allVars,BackendVariable.emptyVars());
      then nameStr;
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.DUMMY_STATE()),false,_)
      equation
        nameStr = printComponentRefMmaStr(name,allVars,BackendVariable.emptyVars());
      then nameStr;
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.DISCRETE()),false,_)
      equation
        nameStr = printComponentRefMmaStr(name,allVars,BackendVariable.emptyVars());
      then nameStr;
    case(_,_,_) then "";
  end matchcontinue;
end printMmaVarStr;

protected function printMmaOutputStr "
print variables that are top level OUTPUT's
"
  input BackendDAE.Var param;
  output String str;
algorithm
  str := matchcontinue(param)
    local
      BackendDAE.Var v;
      DAE.ComponentRef name;
      String ident;
    case(v as BackendDAE.VAR(varName=name as (DAE.CREF_IDENT(_,_,{})),varDirection = DAE.OUTPUT()))
      equation
        true=BackendVariable.isVarOnTopLevelAndOutput(v);
      str = printComponentRefMmaStr(name,BackendVariable.emptyVars(),BackendVariable.emptyVars());
      then str;
    case(_) then "";
  end matchcontinue;
end printMmaOutputStr;

protected function printMmaInputStr "
print variables that are INPUT's
"
  input BackendDAE.Var param;
  output String str;
algorithm
  str := matchcontinue(param)
    local
      DAE.ComponentRef name;
      String ident;
      BackendDAE.Var v;
    case(v as BackendDAE.VAR(varName=name as (DAE.CREF_IDENT(_,_,{})),varDirection = DAE.INPUT()))
      equation
      true=BackendVariable.isVarOnTopLevelAndInput(v);
      str = printComponentRefMmaStr(name,BackendVariable.emptyVars(),BackendVariable.emptyVars());
      then str;
    case(_) then "";
  end matchcontinue;
end printMmaInputStr;

public function printMmaParamsStr "print parameters on a form suitable for Mathematica,
$p,$lb, $rb, $leftParentesis, $rightParentesis removed.
Returns a list of rules for parameters and their values
E.g. {R1R->1.0,R2R->R1R*0.5,I3I->0.1}
"
  input BackendDAE.Variables knvars;
  output list<String> params;
  output list<String> inputs;
algorithm
  (params, inputs) := match(knvars)
    local
      list<BackendDAE.Var> varLst;
    case _ equation
      varLst = BackendVariable.varList(knvars);
      params = List.map(varLst,printMmaParamStr);
      inputs = List.map(varLst,printMmaInputStr);
     then (params, inputs);
  end match;
end printMmaParamsStr;

protected function printMmaParamStr "help function to prontMmaParamStr"
  input BackendDAE.Var param;
  output String str;
algorithm
  str := matchcontinue(param)
    local
      DAE.Exp exp;
      DAE.ComponentRef name;
      String expStr,paramStr;
      Option<DAE.VariableAttributes> val;
    case(BackendDAE.VAR(varName=name,varKind=BackendDAE.PARAM(),bindExp=SOME(exp)))
      equation
      expStr  = printExpMmaStr(exp,BackendVariable.emptyVars(),BackendVariable.emptyVars()); // parameters can not depend on variables. Thus, safe to send empty variables.
      paramStr = printComponentRefMmaStr(name,BackendVariable.emptyVars(),BackendVariable.emptyVars());
      str = stringAppendList({paramStr,"->",expStr});
      then str;
    case(BackendDAE.VAR(varName=name,varKind=BackendDAE.PARAM(),bindExp=NONE(),values=val))
      equation
      SOME(exp) = getStartAttribute(val);
      expStr  = printExpMmaStr(exp,BackendVariable.emptyVars(),BackendVariable.emptyVars()); // parameters can not depend on variables. Thus, safe to send empty variables.
      paramStr = printComponentRefMmaStr(name,BackendVariable.emptyVars(),BackendVariable.emptyVars());
      str = stringAppendList({paramStr,"->",expStr});
      then str;
    case(BackendDAE.VAR(varName=name,varKind=BackendDAE.PARAM(),bindExp=NONE(),values=val))
      equation
      NONE() = getStartAttribute(val);
      expStr  = printExpMmaStr(DAE.ICONST(0),BackendVariable.emptyVars(),BackendVariable.emptyVars()); // parameters can not depend on variables. Thus, safe to send empty variables.
      paramStr = printComponentRefMmaStr(name,BackendVariable.emptyVars(),BackendVariable.emptyVars());
      str = stringAppendList({paramStr,"->",expStr});
      then str;
    case(BackendDAE.VAR(varName=name,varKind=BackendDAE.PARAM()))
      equation
      paramStr = printComponentRefMmaStr(name,BackendVariable.emptyVars(),BackendVariable.emptyVars());
      then paramStr;
    case(_) then "";
  end matchcontinue;
end printMmaParamStr;

protected function getStartAttribute "returns the start attribute of a variable"
   input Option<DAE.VariableAttributes> inVariableAttributesOption;
   output Option<DAE.Exp> out;
algorithm
out:=matchcontinue(inVariableAttributesOption)
   local
     Option<DAE.Exp> e;
    case (SOME(DAE.VAR_ATTR_REAL(start=e)))
      then e;
    case (SOME(DAE.VAR_ATTR_INT(start=e)))
      then e;
    case (SOME(DAE.VAR_ATTR_BOOL(start=e)))
      then e;
    case (SOME(DAE.VAR_ATTR_STRING(start=e)))
      then e;
    case (_)
      then NONE();
   end matchcontinue;
end getStartAttribute;

annotation(__OpenModelica_Interface="backend");
end MathematicaDump;
