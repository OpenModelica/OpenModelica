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

encapsulated package DAEDump
" file:        DAEDump.mo
  package:     DAEDump
  description: DAEDump output


  This module implements functions to print the DAE AST."

// public imports
public import DAE;
public import Graphviz;
public import IOStream;
public import SCode;

// protected imports
protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import ElementSource;
protected import Error;
protected import Print;
protected import Util;
protected import Expression;
protected import ExpressionDump;
protected import Absyn;
protected import Dump;
protected import ValuesUtil;
protected import Values;
protected import Types;
protected import ClassInf;
protected import SCodeDump;
protected import List;
protected import Flags;
protected import DAEDumpTpl;
protected import Tpl;
protected import System;


public uniontype splitElements
  record SPLIT_ELEMENTS
    list<DAE.Element> v;
    list<DAE.Element> ie;
    list<DAE.Element> ia;
    list<DAE.Element> e;
    list<DAE.Element> a;
    list<DAE.Element> co;
    list<DAE.Element> o;
    list<DAE.Element> ca;
    list<compWithSplitElements> sm;
  end SPLIT_ELEMENTS;
end splitElements;

public uniontype compWithSplitElements
  record COMP_WITH_SPLIT
    String name;
    splitElements spltElems;
    Option<SCode.Comment> comment;
  end COMP_WITH_SPLIT;
end compWithSplitElements;

public uniontype functionList
  record FUNCTION_LIST
    list<DAE.Function> funcs;
  end FUNCTION_LIST;
end functionList;

public function dump "This function prints the DAE in the standard output format to the Print buffer.
  For printing to the stdout use print(dumpStr(dae)) instead."
  input DAE.DAElist dae;
  input DAE.FunctionTree functionTree;
algorithm
  _ := match (dae,functionTree)
    local
      list<DAE.Element> daelist;

    case (DAE.DAE(daelist),_)
      equation
        List.map_0(sortFunctions(DAEUtil.getFunctionList(functionTree)),dumpFunction);
        List.map_0(daelist, dumpExtObjectClass);
        List.map_0(daelist, dumpCompElement);
      then
        ();
  end match;
end dump;

public function dumpFunctionNamesStr "return all function names in a string  (comma separated)"
  input DAE.FunctionTree funcs;
  output String str;
algorithm
  str := stringDelimitList(List.map(sortFunctions(DAEUtil.getFunctionList(funcs)),functionNameStr),",");
end dumpFunctionNamesStr;

public function functionNameStr
"return the name of a function, if element is not function return  empty string"
  input DAE.Function inElement;
  output String res;
algorithm
  res := matchcontinue (inElement)
    local
      Absyn.Path fpath;

     case DAE.FUNCTION(path = fpath)
       equation
         res = Absyn.pathStringNoQual(fpath);
       then res;
     case DAE.RECORD_CONSTRUCTOR(path = fpath)
       equation
         res = Absyn.pathStringNoQual(fpath);
       then res;
     else "";
  end matchcontinue;
end functionNameStr;

protected function sortFunctions "sorts the functions and record constructors in alphabetical order"
  input list<DAE.Function> funcs;
  output list<DAE.Function> sortedFuncs;
algorithm
  sortedFuncs := List.sort(funcs,funcGreaterThan);
end sortFunctions;

protected function funcGreaterThan "sorting function for two DAE.Element that are functions or record constuctors"
  input DAE.Function func1;
  input DAE.Function func2;
  output Boolean res;
algorithm
  res := matchcontinue(func1,func2)
    case(_,_) equation
      res = stringCompare(functionNameStr(func1),functionNameStr(func2)) > 0;
    then res;
    else true;
  end matchcontinue;
end funcGreaterThan;

public function dumpOperatorString "
Author bz  printOperator
Dump operator to a string."
  input DAE.Operator op;
  output String str;
algorithm
  str := match(op)
    local
      Absyn.Path p;
      DAE.Type ty;
    case(DAE.ADD()) then " ADD ";
    case(DAE.SUB()) then " SUB ";
    case(DAE.MUL()) then " MUL ";
    case(DAE.DIV()) then " DIV ";
    case(DAE.POW()) then " POW ";
    case(DAE.UMINUS()) then " UMINUS ";
    case(DAE.UMINUS_ARR()) then " UMINUS_ARR ";
    case(DAE.ADD_ARR()) then " ADD_ARR ";
    case(DAE.SUB_ARR()) then " SUB_ARR ";
    case(DAE.MUL_ARR()) then " MUL_ARR ";
    case(DAE.DIV_ARR()) then " DIV_ARR ";
    case(DAE.MUL_ARRAY_SCALAR()) then " MUL_ARRAY_SCALAR ";
    case(DAE.ADD_ARRAY_SCALAR()) then " ADD_ARRAY_SCALAR ";
    case(DAE.SUB_SCALAR_ARRAY()) then " SUB_SCALAR_ARRAY ";
    case(DAE.MUL_SCALAR_PRODUCT()) then " MUL_SCALAR_PRODUCT ";
    case(DAE.MUL_MATRIX_PRODUCT()) then " MUL_MATRIX_PRODUCT ";
    case(DAE.DIV_ARRAY_SCALAR()) then " DIV_ARRAY_SCALAR ";
    case(DAE.DIV_SCALAR_ARRAY()) then " DIV_SCALAR_ARRAY ";
    case(DAE.POW_ARRAY_SCALAR()) then " POW_ARRAY_SCALAR ";
    case(DAE.POW_SCALAR_ARRAY()) then " POW_SCALAR_ARRAY ";
    case(DAE.POW_ARR()) then " POW_ARR ";
    case(DAE.POW_ARR2()) then " POW_ARR2 ";
    case(DAE.OR(_)) then " OR ";
    case(DAE.AND(_)) then " AND ";
    case(DAE.NOT(_)) then " NOT ";
    case(DAE.LESSEQ()) then " LESSEQ ";
    case(DAE.GREATER()) then " GREATER ";
    case(DAE.GREATEREQ()) then " GREATEREQ ";
    case(DAE.LESS()) then " LESS ";
    case(DAE.EQUAL()) then " EQUAL ";
    case(DAE.NEQUAL()) then " NEQUAL ";
    case(DAE.USERDEFINED(p)) then " Userdefined:" + Absyn.pathString(p) + " ";
    else " --UNDEFINED-- ";
  end match;
end dumpOperatorString;

public function dumpOperatorSymbol "
Author bz  printOperator
Dump operator to a string."
  input DAE.Operator op;
  output String str;
algorithm
  str := match(op)
    local
      Absyn.Path p;
    case(DAE.ADD(_)) then " + ";
    case(DAE.SUB(_)) then " - ";
    case(DAE.MUL(_)) then " .* ";
    case(DAE.DIV(_)) then " / ";
    case(DAE.POW(_)) then " ^ ";
    case(DAE.UMINUS(_)) then " - ";
    case(DAE.UMINUS_ARR(_)) then " - ";
    case(DAE.ADD_ARR(_)) then " + ";
    case(DAE.SUB_ARR(_)) then " - ";
    case(DAE.MUL_ARR(_)) then " .* ";
    case(DAE.DIV_ARR(_)) then " ./ ";
    case(DAE.MUL_ARRAY_SCALAR(_)) then " * ";
    case(DAE.ADD_ARRAY_SCALAR(_)) then " .+ ";
    case(DAE.SUB_SCALAR_ARRAY(_)) then " .- ";
    case(DAE.MUL_SCALAR_PRODUCT(_)) then " * ";
    case(DAE.MUL_MATRIX_PRODUCT(_)) then " * ";
    case(DAE.DIV_ARRAY_SCALAR(_)) then " / ";
    case(DAE.DIV_SCALAR_ARRAY(_)) then " ./ ";
    case(DAE.POW_ARRAY_SCALAR(_)) then " .^ ";
    case(DAE.POW_SCALAR_ARRAY(_)) then " .^ ";
    case(DAE.POW_ARR(_)) then " ^ ";
    case(DAE.POW_ARR2(_)) then " .^ ";
    case(DAE.OR(_)) then " or ";
    case(DAE.AND(_)) then " and ";
    case(DAE.NOT(_)) then " not ";
    case(DAE.LESSEQ(_)) then " <= ";
    case(DAE.GREATER(_)) then " > ";
    case(DAE.GREATEREQ(_)) then " >= ";
    case(DAE.LESS(_)) then " < ";
    case(DAE.EQUAL(_)) then " == ";
    case(DAE.NEQUAL(_)) then " <> ";
    case(DAE.USERDEFINED(p)) then " Userdefined:" + Absyn.pathString(p) + " ";
    else " --UNDEFINED-- ";
  end match;
end dumpOperatorSymbol;

protected function dumpStartValue "Dumps the StartValue for a variable."
  input DAE.StartValue inStartValue;
algorithm
  _ := matchcontinue (inStartValue)
    local
      DAE.Exp e;
    case (SOME(e))
      equation
        Print.printBuf("(start=");
        ExpressionDump.printExp(e);
        Print.printBuf(")");
      then
        ();
    else ();
  end matchcontinue;
end dumpStartValue;

public function dumpStartValueStr "Dumps the start value for a variable to a string."
  input DAE.StartValue inStartValue;
  output String outString;
algorithm
  outString := matchcontinue (inStartValue)
    local
      String s,res;
      DAE.Exp e;
    case (SOME(e))
      equation
        s = ExpressionDump.printExpStr(e);
        res = stringAppendList({"(start=",s,")"});
      then
        res;
    else "";
  end matchcontinue;
end dumpStartValueStr;

public function dumpExtDeclStr "Dumps the external declaration to a string."
  input DAE.ExternalDecl inExternalDecl;
  output String outString;
algorithm
  outString := match (inExternalDecl)
    local
      String extargsstr,rettystr,str,id,lang;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg retty;
    case DAE.EXTERNALDECL(name = id,args = extargs,returnArg = retty,language = lang)
      equation
        extargsstr = Dump.getStringList(extargs, dumpExtArgStr, ", ");
        rettystr = dumpExtArgStr(retty);
        rettystr = if stringEq(rettystr, "") then rettystr else (rettystr + " = ");
        str = stringAppendList({"external \"", lang, "\" ", rettystr, id,"(",extargsstr,");"});
      then
        str;
  end match;
end dumpExtDeclStr;

public function dumpExtArgStr "Helper function to dumpExtDeclStr"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm
  outString := match (inExtArg)
    local
      String crstr,str,dimstr;
      DAE.ComponentRef cr;
      SCode.ConnectorType ct;
      SCode.Variability var;
      Absyn.Direction dir;
      DAE.Type ty;
      DAE.Exp exp,dim;
      DAE.Attributes attr;

    case DAE.NOEXTARG() then "";
    case DAE.EXTARG(componentRef = cr,attributes = DAE.ATTR())
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
      then
        crstr;
    case DAE.EXTARGEXP(exp = exp)
      equation
        crstr = ExpressionDump.printExpStr(exp);
      then
        crstr;
    case DAE.EXTARGSIZE(componentRef = cr,exp = dim)
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        dimstr = ExpressionDump.printExpStr(dim);
        str = stringAppendList({"size(",crstr,", ",dimstr,")"});
      then
        str;
  end match;
end dumpExtArgStr;

protected function dumpCompElement "Dumps Component elements."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      String n;
      list<DAE.Element> l;
      Option<SCode.Comment> c;
    case DAE.COMP(ident = n,dAElist = l, comment = c)
      equation
        Print.printBuf("class ");
        Print.printBuf(n);
        dumpCommentOption(c);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    else ();  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */
  end matchcontinue;
end dumpCompElement;

public function dumpElements "Dump elements."
  input list<DAE.Element> l;
algorithm
  dumpVars(l, false);
  List.map_0(l, dumpExtObjectClass);
  Print.printBuf("initial equation\n");
  List.map_0(l, dumpInitialEquation);
  Print.printBuf("equation\n");
  List.map_0(l, dumpEquation);
  List.map_0(l, dumpInitialAlgorithm);
  List.map_0(l, dumpAlgorithm);
  List.map_0(l, dumpCompElement);
end dumpElements;

public function dumpFunctionElements "Dump function elements."
  input list<DAE.Element> l;
algorithm
  dumpVars(l, true);
  List.map_0(l, dumpAlgorithm);
end dumpFunctionElements;

protected function dumpVars "Dump variables to Print buffer."
  input list<DAE.Element> lst;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
protected
  String str;
  IOStream.IOStream myStream;
algorithm
  myStream := IOStream.create("", IOStream.LIST());
  myStream := dumpVarsStream(lst, printTypeDimension, myStream);
  str := IOStream.string(myStream);
  Print.printBuf(str);
end dumpVars;

protected function dumpKind "Dump VarKind."
  input DAE.VarKind inVarKind;
algorithm
  _ := match (inVarKind)
    case DAE.CONST()
      equation
        Print.printBuf(" constant  ");
      then
        ();
    case DAE.PARAM()
      equation
        Print.printBuf(" parameter ");
      then
        ();
    case DAE.DISCRETE()
      equation
        Print.printBuf(" discrete  ");
      then
        ();
    case DAE.VARIABLE()
      equation
        Print.printBuf("           ");
      then
        ();
  end match;
end dumpKind;

public function dumpKindStr "Dump VarKind to a string."
  input DAE.VarKind inVarKind;
  output String outString;
algorithm
  outString := match (inVarKind)
    case DAE.CONST() then "constant ";
    case DAE.PARAM() then "parameter ";
    case DAE.DISCRETE() then "discrete ";
    case DAE.VARIABLE() then "";
  end match;
end dumpKindStr;

protected function dumpDirection "Dump VarDirection."
  input DAE.VarDirection inVarDirection;
algorithm
  _ := match (inVarDirection)
    case DAE.INPUT()
      equation
        Print.printBuf(" input  ");
      then
        ();
    case DAE.OUTPUT()
      equation
        Print.printBuf(" output ");
      then
        ();
    case DAE.BIDIR()
      equation
        Print.printBuf("        ");
      then
        ();
  end match;
end dumpDirection;

protected function dumpParallelism "Dump VarParallelism."
  input DAE.VarParallelism inVarParallelism;
algorithm
  _ := match (inVarParallelism)
    case DAE.NON_PARALLEL()
      equation
        Print.printBuf("        ");
      then
        ();
    case DAE.PARGLOBAL()
      equation
        Print.printBuf(" parglobal ");
      then
        ();
    case DAE.PARLOCAL()
      equation
        Print.printBuf(" parlocal ");
      then
        ();
  end match;
end dumpParallelism;

public function dumpDirectionStr "Dump VarDirection to a string"
  input DAE.VarDirection inVarDirection;
  output String outString;
algorithm
  outString := match (inVarDirection)
    case DAE.INPUT() then "input ";
    case DAE.OUTPUT() then "output ";
    case DAE.BIDIR() then "";
  end match;
end dumpDirectionStr;

protected function dumpStateSelectStr "Dump StateSelect to a string."
  input DAE.StateSelect inStateSelect;
  output String outString;
algorithm
  outString := match (inStateSelect)
    case DAE.NEVER() then "StateSelect.never";
    case DAE.AVOID() then "StateSelect.avoid";
    case DAE.PREFER() then "StateSelect.prefer";
    case DAE.ALWAYS() then "StateSelect.always";
    case DAE.DEFAULT() then "StateSelect.default";
  end match;
end dumpStateSelectStr;

protected function dumpUncertaintyStr
"
  Author: Daniel Hedberg 2011-01

  Dump Uncertainty to a string.
"
  input DAE.Uncertainty uncertainty;
  output String out;
algorithm
  out := match (uncertainty)
    case DAE.GIVEN() then "Uncertainty.given";
    case DAE.SOUGHT() then "Uncertainty.sought";
    case DAE.REFINE() then "Uncertainty.refine";
  end match;
end dumpUncertaintyStr;

protected function dumpDistributionStr
"
  Author: Peter Aronsson 2012

  Dump Distribution to a string.
"
  input DAE.Distribution distribution;
  output String out;
algorithm
  out := match (distribution)
    local
      DAE.Exp name;
      DAE.Exp params;
      DAE.Exp paramNames;
      String name_str,params_str, paramNames_str;

    case DAE.DISTRIBUTION(name = name, params = params,paramNames=paramNames) equation
      name_str = ExpressionDump.printExpStr(name);
      params_str = ExpressionDump.printExpStr(params);
      paramNames_str = ExpressionDump.printExpStr(paramNames);
      then
      "Distribution(name = " + name_str + ", params = " + params_str + ", paramNames= " + paramNames_str + ")";
  end match;
end dumpDistributionStr;

public function dumpVariableAttributes "Dump VariableAttributes option."
  input Option<DAE.VariableAttributes> attr;
protected
  String res;
algorithm
  res := dumpVariableAttributesStr(attr);
  Print.printBuf(res);
end dumpVariableAttributes;

public function dumpVariableAttributesStr "Dump VariableAttributes option to a string."
  input Option<DAE.VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm
  outString := matchcontinue (inVariableAttributesOption)
    local
      String quantity,unit_str,displayUnit_str,stateSel_str,min_str,max_str,nominal_str,initial_str,fixed_str,uncertainty_str,dist_str,res_1,res1,res,startOriginStr;
      Boolean is_empty;
      Option<DAE.Exp> quant,unit,displayUnit,min,max,initialExp,nominal,fixed,startOrigin;
      Option<DAE.StateSelect> stateSel;
      Option<DAE.Uncertainty> uncertainty;
      Option<DAE.Distribution> dist;

    case (SOME(DAE.VAR_ATTR_REAL(quant,unit,displayUnit,min,max,initialExp,fixed,nominal,stateSel,uncertainty,dist,_,_,_,startOrigin)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        unit_str = Dump.getOptionWithConcatStr(unit, ExpressionDump.printExpStr, "unit = ");
        displayUnit_str = Dump.getOptionWithConcatStr(displayUnit, ExpressionDump.printExpStr, "displayUnit = ");
        stateSel_str = Dump.getOptionWithConcatStr(stateSel, dumpStateSelectStr , "stateSelect = ");
        min_str = Dump.getOptionWithConcatStr(min, ExpressionDump.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, ExpressionDump.printExpStr, "max = ");
        nominal_str = Dump.getOptionWithConcatStr(nominal, ExpressionDump.printExpStr, "nominal = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");
        uncertainty_str = Dump.getOptionWithConcatStr(uncertainty, dumpUncertaintyStr, "uncertainty = ");
        dist_str = Dump.getOptionWithConcatStr(dist, dumpDistributionStr , "distribution = ");

        startOriginStr = getStartOrigin(startOrigin);

        res_1 = Util.stringDelimitListNonEmptyElts(
          {quantity,unit_str,displayUnit_str,min_str,max_str,
          initial_str,fixed_str,nominal_str,stateSel_str,uncertainty_str,dist_str,startOriginStr}, ", ");
        is_empty = Util.isEmptyString(res_1);
        res = if is_empty then "" else stringAppendList({"(",res_1,")"});
      then
        res;

    case (SOME(DAE.VAR_ATTR_INT(quant,min,max,initialExp,fixed,uncertainty,dist,_,_,_,startOrigin)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, ExpressionDump.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, ExpressionDump.printExpStr, "max = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");
        uncertainty_str = Dump.getOptionWithConcatStr(uncertainty, dumpUncertaintyStr, "uncertainty = ");
        dist_str = Dump.getOptionWithConcatStr(dist, dumpDistributionStr , "distribution = ");

        startOriginStr = getStartOrigin(startOrigin);

        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,initial_str,fixed_str,uncertainty_str,dist_str,startOriginStr}, ", ");
        is_empty = Util.isEmptyString(res_1);
        res = if is_empty then "" else stringAppendList({"(",res_1,")"});
      then
        res;

    case (SOME(DAE.VAR_ATTR_BOOL(quant,initialExp,fixed,_,_,_,startOrigin)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");

        startOriginStr = getStartOrigin(startOrigin);

        res_1 = Util.stringDelimitListNonEmptyElts({quantity,initial_str,fixed_str,startOriginStr}, ", ");
        is_empty = Util.isEmptyString(res_1);
        res = if is_empty then "" else stringAppendList({"(",res_1,")"});
      then
        res;

    case (SOME(DAE.VAR_ATTR_STRING(quant,initialExp,_,_,_,startOrigin)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");

        startOriginStr = getStartOrigin(startOrigin);

        res_1 = Util.stringDelimitListNonEmptyElts({quantity,initial_str,startOriginStr}, ", ");
        is_empty = Util.isEmptyString(res_1);
        res = if is_empty then "" else stringAppendList({"(",res_1,")"});
      then
        res;

    case (SOME(DAE.VAR_ATTR_ENUMERATION(quant,min,max,initialExp,fixed,_,_,_,startOrigin)))
      equation
        quantity = Dump.getOptionWithConcatStr(quant, ExpressionDump.printExpStr, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, ExpressionDump.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, ExpressionDump.printExpStr, "max = ");
        initial_str = Dump.getOptionWithConcatStr(initialExp, ExpressionDump.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, ExpressionDump.printExpStr, "fixed = ");

        startOriginStr = getStartOrigin(startOrigin);

        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,initial_str,fixed_str,startOriginStr}, ", ");
        is_empty = Util.isEmptyString(res_1);
        res = if is_empty then "" else stringAppendList({"(",res_1,")"});
      then
        res;

    case (NONE()) then "";

    else "(unknown VariableAttributes)";
  end matchcontinue;
end dumpVariableAttributesStr;

protected function getStartOrigin
  input Option<DAE.Exp> inStartOrigin;
  output String outStartOrigin;
algorithm
  outStartOrigin := match(inStartOrigin)
    local
      String str;

    case (NONE()) then "";

    case (_)
      equation
        if (Flags.isSet(Flags.SHOW_START_ORIGIN))
        then
          str = Dump.getOptionWithConcatStr(inStartOrigin, ExpressionDump.printExpStr , "startOrigin = ");
        else
          str = "";
        end if;
      then
        str;

  end match;
end getStartOrigin;

protected function dumpVarVisibilityStr "Prints 'protected' to a string for protected variables"
  input DAE.VarVisibility prot;
  output String str;
algorithm
  str := match(prot)
    case DAE.PUBLIC() then "";
    case DAE.PROTECTED() then "protected ";
  end match;
end dumpVarVisibilityStr;

public function dumpVarParallelismStr "Dump VarParallelism to a string"
  input DAE.VarParallelism inVarParallelism;
  output String outString;
algorithm
  outString := match (inVarParallelism)
    case DAE.NON_PARALLEL() then "";
    case DAE.PARGLOBAL() then "parglobal ";
    case DAE.PARLOCAL() then "parlocal ";
  end match;
end dumpVarParallelismStr;

protected function dumpCommentStr
  "Dumps a comment to a string."
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := match(inComment)
    local
      String cmt;

    case SOME(SCode.COMMENT(comment = SOME(cmt)))
      equation
        cmt = System.escapedString(cmt,false);
      then stringAppendList({" \"", cmt, "\""});

    else "";

  end match;
end dumpCommentStr;

protected function dumpClassAnnotationStr
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := dumpAnnotationStr(inComment, "  ", ";\n");
end dumpClassAnnotationStr;

protected function dumpCompAnnotationStr
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := dumpAnnotationStr(inComment, " ", "");
end dumpCompAnnotationStr;

protected function dumpAnnotationStr
  input Option<SCode.Comment> inComment;
  input String inPrefix;
  input String inSuffix;
  output String outString;
algorithm
  outString := matchcontinue(inComment, inPrefix, inSuffix)
    local
      String ann;
      SCode.Mod ann_mod;

    case (SOME(SCode.COMMENT(annotation_ = SOME(SCode.ANNOTATION(ann_mod)))), _, _)
      equation
        true = Config.showAnnotations();
        ann = inPrefix + "annotation" + SCodeDump.printModStr(ann_mod,SCodeDump.defaultOptions) + inSuffix;
      then
        ann;

    else "";

  end matchcontinue;
end dumpAnnotationStr;

public function dumpCommentAnnotationStr
  input Option<SCode.Comment> inComment;
  output String outString;
algorithm
  outString := match(inComment)
    case NONE() then "";
    else dumpCommentStr(inComment) + dumpCompAnnotationStr(inComment);
  end match;
end dumpCommentAnnotationStr;

protected function dumpCommentOption "Dump Comment option."
  input Option<SCode.Comment> comment;
protected
  String str;
algorithm
  str := dumpCommentAnnotationStr(comment);
  Print.printBuf(str);
end dumpCommentOption;

protected function dumpEquation "Dump equation."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c,cr1,cr2;
      Absyn.Path functionName;
      list<DAE.Exp> functionArgs;
      DAE.ElementSource src;
      String sourceStr;

    case (DAE.EQUATION(exp = e1, scalar = e2, source = src))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        sourceStr = getSourceInformationStr(src);
        Print.printBuf(sourceStr);
        Print.printBuf(";\n");
      then
        ();

      case (DAE.EQUEQUATION(cr1=cr1, cr2=cr2, source = src))
      equation
        Print.printBuf("  ");
        ComponentReference.printComponentRef(cr1);
        Print.printBuf(" = ");
        ComponentReference.printComponentRef(cr2);
        sourceStr = getSourceInformationStr(src);
        Print.printBuf(sourceStr);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.ARRAY_EQUATION(exp = e1, array= e2, source = src))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        sourceStr = getSourceInformationStr(src);
        Print.printBuf(sourceStr);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs= e2, source = src))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        sourceStr = getSourceInformationStr(src);
        Print.printBuf(sourceStr);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.DEFINE(componentRef = c, exp = e, source = src))
      equation
        Print.printBuf("  ");
        ComponentReference.printComponentRef(c);
        Print.printBuf(" ::= ");
        ExpressionDump.printExp(e);
        sourceStr = getSourceInformationStr(src);
        Print.printBuf(sourceStr);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.ASSERT(condition=e1, message=e2, source = src))
      equation
        Print.printBuf("assert(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(") ");
        sourceStr = getSourceInformationStr(src);
        Print.printBuf(sourceStr);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.NORETCALL(exp = e1, source = src))
      equation
        ExpressionDump.printExp(e1);
        sourceStr = getSourceInformationStr(src);
        Print.printBuf(sourceStr);
        Print.printBuf(";\n");
      then
        ();

    case _
      equation
         Print.printBuf("/* FIXME: UNHANDLED_EQUATION in DAEDump.dumpEquation */;\n");
      then
        ();

  end matchcontinue;
end dumpEquation;

protected function dumpInitialEquation "Dump initial equation."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c;
      list<DAE.Element> xs1,xs2;
      list<list<DAE.Element>> trueBranches;
      list<DAE.Exp> conds;
      String  s;
      IOStream.IOStream str;

    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.INITIALDEFINE(componentRef = c,exp = e))
      equation
        Print.printBuf("  ");
        ComponentReference.printComponentRef(c);
        Print.printBuf(" ::= ");
        ExpressionDump.printExp(e);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2))
      equation
        Print.printBuf("  ");
        ExpressionDump.printExp(e1);
        Print.printBuf(" = ");
        ExpressionDump.printExp(e2);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.INITIAL_IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::trueBranches),equations3 = xs2))
      equation
        Print.printBuf("  if ");
        ExpressionDump.printExp(e);
        Print.printBuf(" then\n");
        List.map_0(xs1,dumpInitialEquation);
        str = dumpIfEquationsStream(conds, trueBranches, IOStream.emptyStreamOfTypeList);
        s = IOStream.string(str);
        Print.printBuf(s);
        Print.printBuf("  else\n");
        List.map_0(xs2,dumpInitialEquation);
        Print.printBuf("end if;\n");
      then
        ();

    case (DAE.INITIAL_NORETCALL(exp = e1))
      equation
        ExpressionDump.printExp(e1);
        Print.printBuf(";\n");
      then
        ();

    else ();
  end matchcontinue;
end dumpInitialEquation;

public function dumpEquationStr "Dump equation to a string."
  input DAE.Element inElement;
  output String outString;
algorithm
  outString := matchcontinue (inElement)
    local
      String s1,s2,s3,s4,s5,str,sourceStr;
      DAE.Exp e1,e2,e;
      DAE.ComponentRef c,cr1,cr2;
      list<DAE.Exp> es;
      Absyn.Path path;
      DAE.ElementSource src;
      list<SCode.Comment> cmt;

    case (DAE.EQUATION(exp = e1,scalar = e2,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = stringAppendList({"  ", s1, " = ", s2, sourceStr, ";\n"});
      then
        str;

     case (DAE.EQUEQUATION(cr1=cr1,cr2=cr2,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ComponentReference.printComponentRefStr(cr1);
        s2 = ComponentReference.printComponentRefStr(cr2);
        str = stringAppendList({"  ", s1, " = ", s2, sourceStr, ";\n"});
      then
        str;

    case(DAE.ARRAY_EQUATION(exp=e1,array=e2,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = "  " + s1 + " = " + s2 + sourceStr + ";\n";
      then
        str;

    case(DAE.COMPLEX_EQUATION(lhs=e1,rhs=e2,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = "  " + s1 + " = " + s2 + sourceStr + ";\n";
      then
        str;

    case (DAE.DEFINE(componentRef = c,exp = e,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ComponentReference.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(" ::= ", s2);
        s4 = ExpressionDump.printExpStr(e);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, sourceStr + ";\n");
      then
        str;

    case (DAE.ASSERT(condition=e1,message = e2,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = stringAppendList({"  assert(",s1, ",",s2,") ", sourceStr, ";\n"});
      then
        str;

    case (DAE.TERMINATE(message=e1,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ExpressionDump.printExpStr(e1);
        str = stringAppendList({"  terminate(",s1,") ", sourceStr, ";\n"});
      then
        str;

    case (DAE.NORETCALL(exp=e1,source = src))
      equation
        cmt = ElementSource.getCommentsFromSource(src);
        sourceStr = cmtListToString(cmt);
        s1 = ExpressionDump.printExpStr(e1);
        str = stringAppendList({"  ", s1, sourceStr, ";\n"});
      then
        str;
    // adrpo: TODO! FIXME! should we say UNKNOWN equation here? we don't handle all cases!
    else "#UNKNOWN_EQUATION#";
  end matchcontinue;
end dumpEquationStr;

public function dumpAlgorithm "Dump algorithm."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local list<DAE.Statement> stmts;
    case DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts))
      equation
        Print.printBuf("algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    else ();
  end matchcontinue;
end dumpAlgorithm;

protected function dumpInitialAlgorithm "Dump initial algorithm."
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local list<DAE.Statement> stmts;
    case DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts))
      equation
        Print.printBuf("initial algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    else ();
  end matchcontinue;
end dumpInitialAlgorithm;

protected function dumpExtObjectClass
"Dump External Object class"
  input DAE.Element inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      String fstr;
      Absyn.Path fpath;
    case DAE.EXTOBJECTCLASS(path = fpath)
      equation
        Print.printBuf("class ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n extends ExternalObject;\n");
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n");
      then
        ();
    else ();
  end matchcontinue;
end dumpExtObjectClass;

public function derivativeCondStr "
  Author BZ
  Function for printing conditions"
  input DAE.derivativeCond dc;
  output String str;
algorithm
  str := match(dc)
    local DAE.Exp e;

    case(DAE.NO_DERIVATIVE(e))
      equation
        str  = "noDerivative(" + ExpressionDump.printExpStr(e) + ")";
      then
        str;

    case(DAE.ZERO_DERIVATIVE()) then "zeroDerivative";
  end match;
end derivativeCondStr;

protected function dumpFunction
"Dump function"
  input DAE.Function inElement;
algorithm
  _ := matchcontinue (inElement)
    local
      String fstr, inlineTypeStr, ext_decl_str, parallelism_str, impureStr, typeStr;
      Absyn.Path fpath;
      list<DAE.Element> daeElts;
      DAE.Type t;
      DAE.InlineType inlineType;
      Option<SCode.Comment> c;
      DAE.ExternalDecl ext_decl;
      Boolean isImpure;

    case DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_DEF(body = daeElts)::_),
                      type_ = t,isImpure = isImpure,comment = c)
      equation
        typeStr = Types.printTypeStr(t);
        Print.printBuf(typeStr);
        parallelism_str = dumpParallelismStr(t);
        Print.printBuf(parallelism_str);
        impureStr = if isImpure then "impure " else "";
        Print.printBuf(impureStr);
        Print.printBuf("function ");
        fstr = Absyn.pathStringNoQual(fpath);
        Print.printBuf(fstr);
        inlineTypeStr = dumpInlineTypeStr(inlineType);
        Print.printBuf(inlineTypeStr);
        Print.printBuf(dumpCommentStr(c));
        Print.printBuf("\n");
        dumpFunctionElements(daeElts);
        Print.printBuf(dumpClassAnnotationStr(c));
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();

    case DAE.FUNCTION(functions = (DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(language="builtin"))::_))
      then
        ();

    case DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_EXT(body = daeElts, externalDecl = ext_decl)::_),
                      isImpure = isImpure, comment = c)
      equation
        impureStr = if isImpure then "impure " else "";
        Print.printBuf(impureStr);
        Print.printBuf("function ");
        fstr = Absyn.pathStringNoQual(fpath);
        Print.printBuf(fstr);
        inlineTypeStr = dumpInlineTypeStr(inlineType);
        Print.printBuf(inlineTypeStr);
        Print.printBuf(dumpCommentStr(c));
        Print.printBuf("\n");
        dumpFunctionElements(daeElts);
        ext_decl_str = dumpExtDeclStr(ext_decl);
        Print.printBuf("\n  " + ext_decl_str + "\n");
        Print.printBuf(dumpClassAnnotationStr(c));
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();

    case DAE.RECORD_CONSTRUCTOR(path = fpath,type_=t)
      equation
        false = Flags.isSet(Flags.DISABLE_RECORD_CONSTRUCTOR_OUTPUT);
        Print.printBuf("function ");
        fstr = Absyn.pathStringNoQual(fpath);
        Print.printBuf(fstr);
        Print.printBuf(" \"Automatically generated record constructor for "+fstr+"\"\n");
        Print.printBuf(printRecordConstructorInputsStr(t));
        Print.printBuf("  output "+Absyn.pathLastIdent(fpath)+ " res;\n");
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();

    else ();
  end matchcontinue;
end dumpFunction;

protected function dumpParallelismStr
  input DAE.Type inType;
  output String outString;
algorithm
  outString := match(inType)
    case (DAE.T_FUNCTION(_, _, DAE.FUNCTION_ATTRIBUTES(functionParallelism=DAE.FP_NON_PARALLEL()), _)) then "";
    case (DAE.T_FUNCTION(_, _, DAE.FUNCTION_ATTRIBUTES(functionParallelism=DAE.FP_PARALLEL_FUNCTION()), _)) then "parallel ";
    case (DAE.T_FUNCTION(_, _, DAE.FUNCTION_ATTRIBUTES(functionParallelism=DAE.FP_KERNEL_FUNCTION()), _)) then "kernel ";
    else "#dumpParallelismStr failed#";
end match;
end dumpParallelismStr;

public function dumpInlineTypeStr
  input DAE.InlineType inlineType;
  output String str;
algorithm
  str := match(inlineType)
    case(DAE.NO_INLINE()) then "\"Inline never\"";
    case(DAE.AFTER_INDEX_RED_INLINE()) then " \"Inline after index reduction\"";
    case(DAE.NORM_INLINE()) then " \"Inline before index reduction\"";
    case(DAE.DEFAULT_INLINE()) then "\"Inline if necessary\"";
    else "\"unknown\"";
  end match;
end dumpInlineTypeStr;

protected function printRecordConstructorInputsStr
  "Helper function to dumpFunction. Prints the inputs of a record constructor."
  input DAE.Type itp;
  output String str;
algorithm
  str := match(itp)
    local
      list<String> var_strl;
      list<DAE.Var> vars;
      DAE.Type tp;

    case DAE.T_COMPLEX(varLst = vars)
      equation
        var_strl = List.map(vars, printRecordConstructorInputStr);
      then
        stringAppendList(var_strl);

    case DAE.T_FUNCTION(funcResultType = tp) then printRecordConstructorInputsStr(tp);

  end match;
end printRecordConstructorInputsStr;

protected function printRecordConstructorInputStr
  input DAE.Var inVar;
  output String outString;
protected
  String name, attr_str, binding_str, ty_str, ty_vars_str;
  DAE.Attributes attr;
  DAE.Type ty;
  DAE.Binding binding;
algorithm
  DAE.TYPES_VAR(name = name, attributes = attr, ty = ty, binding = binding) := inVar;
  attr_str := printRecordConstructorInputAttrStr(attr);
  binding_str := printRecordConstructorBinding(binding);
  (ty_str, ty_vars_str) := printTypeStr(ty);
  outString := stringAppendList({"  ", attr_str, ty_str, " ", name, ty_vars_str, binding_str, ";\n"});
end printRecordConstructorInputStr;

protected function printRecordConstructorInputAttrStr
  input DAE.Attributes inAttributes;
  output String outString;
algorithm
  outString := match(inAttributes)
    // protected vars are not input!, see Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case DAE.ATTR(visibility = SCode.PROTECTED()) then "protected ";
    // constants are not input! see Modelica Spec 3.2, Section 12.6, Record Constructor Functions, page 140
    case DAE.ATTR(variability = SCode.CONST()) then "constant ";
    else "input ";
  end match;
end printRecordConstructorInputAttrStr;

protected function printRecordConstructorBinding "prints the binding of a record constructor input"
  input DAE.Binding binding;
  output String str;
algorithm
  str := match(binding)
    local DAE.Exp e; Values.Value v;
    case(DAE.UNBOUND()) then "";
    case(DAE.EQBOUND(exp=e, source=DAE.BINDING_FROM_DEFAULT_VALUE())) equation
      str = " = "+ExpressionDump.printExpStr(e);
    then str;
    case(DAE.VALBOUND(valBound=v, source=DAE.BINDING_FROM_DEFAULT_VALUE())) equation
      str = " = " + ValuesUtil.valString(v);
    then str;
  end match;
end printRecordConstructorBinding;

protected function ppStatement
"Prettyprint an algorithm statement"
  input DAE.Statement alg;
algorithm
  ppStmt(alg, 2);
end ppStatement;

public function ppStatementStr
"Prettyprint an algorithm statement to a string."
  input DAE.Statement alg;
  output String str;
algorithm
  str := ppStmtStr(alg, 2);
end ppStatementStr;

protected function ppStmt
"Helper function to ppStatement."
  input DAE.Statement inStatement;
  input Integer inInteger;
algorithm
  _ := matchcontinue (inStatement,inInteger)
    local
      DAE.ComponentRef c;
      DAE.Exp e,cond,msg,e1,e2;
      Integer i,i_1,index;
      String s1,s2,s3,str,id,name;
      list<String> es;
      list<DAE.Exp> expl;
      list<DAE.Statement> then_,stmts;
      DAE.Statement stmt;
      DAE.Type ty;
      DAE.Else else_;
      DAE.ElementSource source;

    case (DAE.STMT_ASSIGN(exp1 = e2,exp = e,source = source),i)
      equation
        indent(i);
        ExpressionDump.printExp(e2);
        Print.printBuf(" := ");
        ExpressionDump.printExp(e);
        if Config.typeinfo() then
          Print.printBuf(" /* " + Error.infoStr(ElementSource.getElementSourceFileInfo(source)) + " */");
        end if;
        Print.printBuf(";\n");
      then
        ();

    case (DAE.STMT_ASSIGN_ARR(lhs = e2,exp = e),i)
      equation
        indent(i);
        ExpressionDump.printExp(e2);
        Print.printBuf(" := ");
        ExpressionDump.printExp(e);
        Print.printBuf(";\n");
      then
        ();

    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e);
        es = List.map(expl, ExpressionDump.printExpStr);
        s3 = stringDelimitList(es, ", ");
        str = stringAppendList({s1,"(",s3,") := ",s2,";\n"});
        Print.printBuf(str);
      then
        ();

    case (DAE.STMT_IF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        indent(i);
        Print.printBuf("if ");
        ExpressionDump.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
        indent(i);
        Print.printBuf("end if;\n");
      then
        ();

    case (DAE.STMT_FOR(iter = id,index = index,range = e,statementLst = stmts),i)
      equation
        indent(i);
        Print.printBuf("for ");
        Print.printBuf(id);
        if index <> -1 then
          Print.printBuf(" /* iter index " + intString(index) + " */");
        end if;
        Print.printBuf(" in ");
        ExpressionDump.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end for;\n");
      then
        ();

    case (DAE.STMT_PARFOR(iter = id,index=index,range = e,statementLst = stmts),i)
      equation
        indent(i);
        Print.printBuf("parfor ");
        Print.printBuf(id);
        if index <> -1 then
          Print.printBuf(" /* iter index " + intString(index) + " */");
        end if;
        Print.printBuf(" in ");
        ExpressionDump.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end parfor;\n");
      then
        ();

    case (DAE.STMT_WHILE(exp = e,statementLst = stmts),i)
      equation
        indent(i);
        Print.printBuf("while ");
        ExpressionDump.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end while;\n");
      then
        ();

    case (DAE.STMT_NORETCALL(exp = e1),i)
      equation
        indent(i);
        ExpressionDump.printExp(e1);
        Print.printBuf(";\n");
      then
        ();

    case (stmt as DAE.STMT_WHEN(),i)
      equation
        indent(i);
        Print.printBuf(ppWhenStmtStr(stmt,1));
      then
        ();

    case (DAE.STMT_ASSERT(cond = cond,msg = msg),i)
      equation
        indent(i);
        Print.printBuf("assert(");
        ExpressionDump.printExp(cond);
        Print.printBuf(", ");
        ExpressionDump.printExp(msg);
        Print.printBuf(");\n");
      then
        ();

    case (DAE.STMT_RETURN(),i)
      equation
        indent(i);
        Print.printBuf("return;\n");
      then
        ();

    case (DAE.STMT_BREAK(),i)
      equation
        indent(i);
        Print.printBuf("break;\n");
      then
        ();

    case (DAE.STMT_REINIT(var = e1, value = e2),i)
      equation
        indent(i);
        Print.printBuf("reinit(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(");\n");
      then
        ();

    case (DAE.STMT_FAILURE(body = stmts),i)
      equation
        indent(i);
        Print.printBuf("begin failure\n");
        ppStmtList(stmts, i+2);
        Print.printBuf("end try;\n");
      then
        ();

    case (DAE.STMT_ARRAY_INIT(name = name, ty = ty),i)
      equation
        indent(i);
        Print.printBuf("/* ");
        Print.printBuf(name);
        Print.printBuf(" := array_alloc(");
        Print.printBuf(Types.unparseType(ty));
        Print.printBuf(") */;\n");
      then
        ();

    case (_,i)
      equation
        indent(i);
        Print.printBuf("**ALGORITHM**;\n");
      then
        ();
  end matchcontinue;
end ppStmt;


protected function ppWhenStmtStr
  input DAE.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm
  outString := match (inStatement,inInteger)
    local
      String s3,s4,s5,s6,str,s7,s8,s9,s10;
      DAE.Exp e;
      Integer i,i_1;
      list<DAE.Statement> stmts;
      DAE.Statement stmt;
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=NONE()),i)
      equation
        s3 = stringAppend("when ",ExpressionDump.printExpStr(e));
        s5 = stringAppend(s3, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end when;\n");
      then
        str;
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=SOME(stmt)),i)
      equation
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend("when ", s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppWhenStmtStr(stmt,i);
        s9 = stringAppend(indentStr(i),"else");
        s10= stringAppend(s7,s9);
        str = stringAppend(s10, s8);
      then
        str;
   end match;
end ppWhenStmtStr;

public function ppStmtStr
  "Helper function to ppStatementStr"
  input DAE.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm
  outString := matchcontinue (inStatement,inInteger)
    local
      String s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str,e1_str,e2_str;
      DAE.ComponentRef c;
      DAE.Exp e,cond,msg,e1,e2;
      Integer i,i_1,index;
      list<String> es;
      list<DAE.Exp> expl;
      list<DAE.Statement> then_,stmts;
      DAE.Statement stmt;
      DAE.Else else_;
      DAE.ElementSource source;

    case (DAE.STMT_ASSIGN(exp1 = e2,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ExpressionDump.printExpStr(e);
        str = stringAppendList({s1,s2," := ",s3,";\n"});
      then
        str;

    case (DAE.STMT_ASSIGN_ARR(lhs=e2,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ExpressionDump.printExpStr(e);
        str = stringAppendList({s1,s2," := ",s3,";\n"});
      then
        str;

    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e);
        es = List.map(expl, ExpressionDump.printExpStr);
        s3 = stringDelimitList(es, ", ");
        str = stringAppendList({s1,"(",s3,") := ",s2,";\n"});
      then
        str;

    case (DAE.STMT_IF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "if ");
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end if;\n");
      then
        str;

    case (DAE.STMT_FOR(iter = id,index = index,range = e,statementLst = stmts),i)
      equation
        s1 = indentStr(i);
        s2 = if index == -1 then "" else ("/* iter index " + intString(index) + " */");
        s3 = ExpressionDump.printExpStr(e);
        i_1 = i + 2;
        s4 = ppStmtListStr(stmts, i_1);
        s5 = indentStr(i);
        str = stringAppendList({s1,"for ",id,s2," in ",s3," loop\n",s4,s5,"end for;\n"});
      then
        str;

    case (DAE.STMT_PARFOR(iter = id,index = index,range = e,statementLst = stmts),i)
      equation
        s1 = indentStr(i);
        s2 = if index == -1 then "" else ("/* iter index " + intString(index) + " */");
        s3 = ExpressionDump.printExpStr(e);
        i_1 = i + 2;
        s4 = ppStmtListStr(stmts, i_1);
        s5 = indentStr(i);
        str = stringAppendList({s1,"parfor ",id,s2," in ",s3," loop\n",s4,s5,"end for;\n"});
      then
        str;

    case (DAE.STMT_WHILE(exp = e,statementLst = stmts),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "while ");
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " loop\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end while;\n");
      then
        str;

    case (stmt as DAE.STMT_WHEN(),i)
      equation
        s1 = indentStr(i);
        s2 = ppWhenStmtStr(stmt,i);
        str = stringAppend(s1,s2);
      then
        str;

    case (DAE.STMT_ASSERT(cond = cond,msg = msg),i)
      equation
        s1 = indentStr(i);
        cond_str = ExpressionDump.printExpStr(cond);
        msg_str = ExpressionDump.printExpStr(msg);
        str = stringAppendList({s1,"assert(",cond_str,", ",msg_str,");\n"});
      then
        str;

    case (DAE.STMT_TERMINATE(msg = msg),i)
      equation
        s1 = indentStr(i);
        msg_str = ExpressionDump.printExpStr(msg);
        str = stringAppendList({s1,"terminate(",msg_str,");\n"});
      then
        str;

    case (DAE.STMT_NORETCALL(exp = e),i)
      equation
        s1 = indentStr(i);
        s2 = ExpressionDump.printExpStr(e);
        str = stringAppendList({s1,s2,";\n"});
      then
        str;

    case (DAE.STMT_RETURN(),i)
      equation
        s1 = indentStr(i);
        str = stringAppend(s1, "return;\n");
      then
        str;

    case (DAE.STMT_BREAK(),i)
      equation
        s1 = indentStr(i);
        str = stringAppend(s1, "break;\n");
      then
        str;

    case (DAE.STMT_REINIT(var = e1, value = e2),i)
      equation
        s1 = indentStr(i);
        e1_str = ExpressionDump.printExpStr(e1);
        e2_str = ExpressionDump.printExpStr(e2);
        str = stringAppendList({s1,"reinit(",e1_str,", ",e2_str,");\n"});
      then str;

    case (DAE.STMT_FAILURE(body=stmts),i)
      equation
        s1 = indentStr(i);
        s2 = ppStmtListStr(stmts, i+2);
        str = stringAppendList({s1,"failure(\n",s2,s1,");\n"});
      then str;

    case (DAE.STMT_ARRAY_INIT(name=s2),i)
      equation
        s1 = indentStr(i);
        str = stringAppendList({s1,"arrayInit(\n",s2,s1,");\n"});
      then str;

    case (_,i)
      equation
        s1 = indentStr(i);
        str = stringAppend(s1, "**ALGORITHM COULD NOT BE GENERATED(DAE.mo)**;\n");
      then
        str;
  end matchcontinue;
end ppStmtStr;

protected function ppStmtList "
  Helper function to pp_stmt
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
algorithm
  _:=
  match (inAlgorithmStatementLst,inInteger)
    local
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      Integer i;
    case ({},_) then ();
    case ((stmt :: stmts),i)
      equation
        ppStmt(stmt, i);
        ppStmtList(stmts, i);
      then
        ();
  end match;
end ppStmtList;

protected function ppStmtListStr "
  Helper function to pp_stmt_str
"
  input list<DAE.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  match (inAlgorithmStatementLst,inInteger)
    local
      String s1,s2,str;
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      Integer i;
    case ({},_) then "";
    case ((stmt :: stmts),i)
      equation
        s1 = ppStmtStr(stmt, i);
        s2 = ppStmtListStr(stmts, i);
        str = stringAppend(s1, s2);
      then
        str;
  end match;
end ppStmtListStr;

protected function ppElse "
  Helper function to pp_stmt
"
  input DAE.Else inElse;
  input Integer inInteger;
algorithm
  _:=
  match (inElse,inInteger)
    local
      Integer i_1,i;
      DAE.Exp e;
      list<DAE.Statement> then_,stmts;
      DAE.Else else_;
    case (DAE.NOELSE(),_) then ();
    case (DAE.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        indent(i);
        Print.printBuf("elseif ");
        ExpressionDump.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
      then
        ();
    case (DAE.ELSE(statementLst = stmts),i)
      equation
        indent(i);
        Print.printBuf("else\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
      then
        ();
  end match;
end ppElse;

protected function ppElseStr "
  Helper function to ppElseStr
"
  input DAE.Else inElse;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  match (inElse,inInteger)
    local
      String s1,s2,s3,s4,s5,s6,s7,s8,str;
      Integer i_1,i;
      DAE.Exp e;
      list<DAE.Statement> then_,stmts;
      DAE.Else else_;
    case (DAE.NOELSE(),_) then "";
    case (DAE.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "elseif ");
        s3 = ExpressionDump.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        str = stringAppend(s7, s8);
      then
        str;
    case (DAE.ELSE(statementLst = stmts),i)
      equation
        s1 = indentStr(i);
        s2 = stringAppend(s1, "else\n");
        i_1 = i + 2;
        s3 = ppStmtListStr(stmts, i_1);
        str = stringAppend(s2, s3);
      then
        str;
  end match;
end ppElseStr;

protected function indent "
  Print an indentation, given an indent level.
"
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (inInteger)
    local Integer i_1,i;
    case 0 then ();
    case i
      equation
        Print.printBuf(" ");
        i_1 = i - 1;
        indent(i_1);
      then
        ();
  end matchcontinue;
end indent;

protected function indentStr "
  Print an indentation to a string, given an indent level.
"
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inInteger)
    local
      Integer i_1,i;
      String s1,str;
    case 0 then "";
    case i
      equation
        i_1 = i - 1;
        s1 = indentStr(i_1);
        str = stringAppend(" ", s1);
      then
        str;
  end matchcontinue;
end indentStr;

public function dumpDebug "

 Dump the data structures in a
 paranthesised way

"
  input DAE.DAElist inDAElist;
algorithm
  _:=
  match (inDAElist)
    local list<DAE.Element> elist;
    case DAE.DAE(elementLst = elist)
      equation
        Print.printBuf("DAE(");
        dumpDebugElist(elist);
        Print.printBuf(")");
      then
        ();
  end match;
end dumpDebug;

protected function dumpDebugElist "
  Helper function to dump_debug.
"
  input list<DAE.Element> inElementLst;
algorithm
  _:=
  match (inElementLst)
    local
      DAE.Element first;
      list<DAE.Element> rest;
    case {} then ();
    case (first :: rest)
      equation
        dumpDebugElement(first);
        Print.printBuf("\n");
        dumpDebugElist(rest);
      then
        ();
  end match;
end dumpDebugElist;

public function dumpDebugDAE ""
  input DAE.DAElist dae;
  output String str;
algorithm
  str := match (dae)
    local
      list<DAE.Element> elems;
    case(DAE.DAE(elementLst=elems))
      equation
        Print.clearBuf();
        dumpDebugElist(elems);
        str = Print.getString();
      then
        str;
  end match;
end dumpDebugDAE;

public function dumpDebugElement "
  Dump element using parenthesis.
"
  input DAE.Element inElement;
algorithm
  _:=
  matchcontinue (inElement)
    local
      String comment_str,tmp_str,n;
      DAE.ComponentRef cr,cr1,cr2;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Exp e,exp,e1,e2;
      list<DAE.Element> l;
    case DAE.VAR(componentRef = cr,
             kind = vk,
             binding = NONE(),
             variableAttributesOption = dae_var_attr,
             comment = comment)
      equation
        Print.printBuf("VAR(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        comment_str = dumpCommentAnnotationStr(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DAE.VAR(componentRef = cr,
             kind = vk,
             binding = SOME(e),
             variableAttributesOption = dae_var_attr,
             comment = comment)
      equation
        Print.printBuf("VAR(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        Print.printBuf(", binding: ");
        ExpressionDump.printExp(e);
        comment_str = dumpCommentAnnotationStr(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DAE.DEFINE(componentRef = cr,exp = exp)
      equation
        Print.printBuf("DEFINE(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        ExpressionDump.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIALDEFINE(componentRef = cr,exp = exp)
      equation
        Print.printBuf("INITIALDEFINE(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(", ");
        ExpressionDump.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case DAE.EQUATION(exp = e1,scalar = e2)
      equation
        Print.printBuf("EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();

     case DAE.EQUEQUATION(cr1=cr1,cr2=cr2)
      equation
        Print.printBuf("EQUATION(");
        ComponentReference.printComponentRef(cr1);
        Print.printBuf(",");
        ComponentReference.printComponentRef(cr2);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation
        Print.printBuf("INITIALEQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.ALGORITHM()
      equation
        Print.printBuf("ALGORITHM()");
      then
        ();
    case DAE.INITIALALGORITHM()
      equation
        Print.printBuf("INITIALALGORITHM()");
      then
        ();
    case DAE.COMP(ident = n,dAElist = l)
      equation
        Print.printBuf("COMP(");
        Print.printBuf(n);
        Print.printBuf(",");
        dumpDebugElist(l);
        Print.printBuf(")");
      then
        ();
    case DAE.ARRAY_EQUATION(exp = e1,array = e2)
      equation
        Print.printBuf("ARRAY_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIAL_ARRAY_EQUATION(exp = e1,array = e2)
      equation
        Print.printBuf("INITIAL_ARRAY_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2)
      equation
        Print.printBuf("COMPLEX_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2)
      equation
        Print.printBuf("INITIAL_COMPLEX_EQUATION(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.IF_EQUATION()
      equation
        Print.printBuf("IF_EQUATION()");
      then
        ();
    case DAE.INITIAL_IF_EQUATION()
      equation
        Print.printBuf("INITIAL_IF_EQUATION()");
      then
        ();
    case DAE.WHEN_EQUATION()
      equation
        Print.printBuf("WHEN_EQUATION()");
      then
        ();
    case DAE.EXTOBJECTCLASS()
      equation
        Print.printBuf("EXTOBJECTCLASS()");
      then
        ();
    case DAE.ASSERT(condition = e1,message = e2)
      equation
        Print.printBuf("ASSERT(");
        ExpressionDump.printExp(e1);
        Print.printBuf(",");
        ExpressionDump.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case DAE.TERMINATE(message = e1)
      equation
        Print.printBuf("TERMINATE(");
        ExpressionDump.printExp(e1);
        Print.printBuf(")");
      then
        ();
    case DAE.REINIT()
      equation
        Print.printBuf("REINIT()");
      then
        ();
    case DAE.NORETCALL()
      equation
        Print.printBuf("NORETCALL()");
      then
        ();
    case DAE.SM_COMP(componentRef = cr,dAElist = l)
      equation
        Print.printBuf("SM_COMP(");
        ComponentReference.printComponentRef(cr);
        Print.printBuf(",");
        dumpDebugElist(l);
        Print.printBuf(")");
      then
        ();
    case DAE.FLAT_SM(ident = n,dAElist = l)
      equation
        Print.printBuf("FLAT_SM(");
        Print.printBuf(n);
        Print.printBuf(",");
        dumpDebugElist(l);
        Print.printBuf(")");
      then
        ();
    case _
      equation
        Print.printBuf("UNKNOWN ");
      then
        ();
  end matchcontinue;
end dumpDebugElement;

public function dumpFlow "
Author BZ 2008-07, dump flow properties to string."
  input DAE.ConnectorType var;
  output String flowString;
algorithm
  flowString := match(var)
    case DAE.FLOW() then "flow";
    case DAE.POTENTIAL() then "effort";
    case DAE.NON_CONNECTOR() then "non_connector";
  end match;
end dumpFlow;

public function dumpConnectorType
  input DAE.ConnectorType inConnectorType;
  output String outString;
algorithm
  outString := match(inConnectorType)
    case DAE.FLOW() then "flow";
    case DAE.STREAM() then "stream";
    else "";
  end match;
end dumpConnectorType;

public function dumpGraphviz "
 Graphviz functions to visualize
 the dae
"
  input DAE.DAElist dae;
protected
  Graphviz.Node r;
algorithm
  r := buildGraphviz(dae);
  Graphviz.dump(r);
end dumpGraphviz;

protected function buildGraphviz "
  Builds the graphviz node from a dae list.
"
  input DAE.DAElist inDAElist;
  output Graphviz.Node outNode;
algorithm
  outNode:=
  match (inDAElist)
    local
      list<DAE.Element> vars,nonvars,els;
      list<Graphviz.Node> nonvarnodes,varnodes,nodelist;
    case DAE.DAE(elementLst = els)
      equation
        vars = DAEUtil.getMatchingElements(els, DAEUtil.isVar);
        nonvars = DAEUtil.getMatchingElements(els, DAEUtil.isNotVar);
        nonvarnodes = buildGrList(nonvars);
        varnodes = buildGrVars(vars);
        nodelist = listAppend(nonvarnodes, varnodes);
      then
        Graphviz.NODE("DAE",{},nodelist);
  end match;
end buildGraphviz;

protected function buildGrList "Helper function to build_graphviz.
"
  input list<DAE.Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm
  outGraphvizNodeLst:=
  match (inElementLst)
    local
      Graphviz.Node node;
      list<Graphviz.Node> nodelist;
      DAE.Element el;
      list<DAE.Element> rest;
    case {} then {};
    case (el :: rest)
      equation
        node = buildGrElement(el);
        nodelist = buildGrList(rest);
      then
        (node :: nodelist);
  end match;
end buildGrList;

protected function buildGrVars "Helper function to build_graphviz.
"
  input list<DAE.Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm
  outGraphvizNodeLst := matchcontinue (inElementLst)
    local
      list<String> strlist;
      list<DAE.Element> vars;
    case {} then {};
    case vars
      equation
        (strlist,_) = buildGrStrlist(vars, buildGrVarStr, 10);
      then
        {Graphviz.LNODE("VARS",strlist,{Graphviz.box},{})};
  end matchcontinue;
end buildGrVars;

public function buildGrStrlist "Helper function to build_graphviz.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input Integer inInteger;
  output list<String> outStringLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  (outStringLst,outTypeALst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inInteger)
    local
      list<Type_a> ignored,rest;
      FuncTypeType_aToString printer;
      Integer count,count_1;
      list<String> strlist;
      String str;
      Type_a var;
    case ({},_,_) then ({},{});
    case (ignored,_,count)
      equation
        (count <= 0) = true;
      then
        ({"..."},ignored);
    case ((var :: rest),printer,count)
      equation
        (count > 0) = true;
        count_1 = count - 1;
        (strlist,ignored) = buildGrStrlist(rest, printer, count_1);
        str = printer(var);
      then
        ((str :: strlist),ignored);
  end matchcontinue;
end buildGrStrlist;

protected function buildGrVarStr "Helper function to build_graphviz.
"
  input DAE.Element inElement;
  output String outString;
algorithm
  outString:=
  match (inElement)
    local
      String str,expstr,str_1,str_2;
      DAE.ComponentRef cr;
      DAE.Exp exp;
    case DAE.VAR(componentRef = cr,binding = NONE())
      equation
        str = ComponentReference.printComponentRefStr(cr);
      then
        str;
    case DAE.VAR(componentRef = cr,binding = SOME(exp))
      equation
        str = ComponentReference.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        str_1 = stringAppend(str, " = ");
        str_2 = stringAppend(str_1, expstr);
      then
        str_2;
  end match;
end buildGrVarStr;

protected function printExpStrSpecial "
  Prints an expression to a string suitable for graphviz.
"
  input DAE.Exp inExp;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp)
    local
      String s_1,s_2,s,str;
      DAE.Exp exp;
    case DAE.SCONST(string = s)
      equation
        s_1 = stringAppend("\\\"", s);
        s_2 = stringAppend(s_1, "\\\"");
      then
        s_2;
    case exp
      equation
        str = ExpressionDump.printExpStr(exp);
      then
        str;
  end matchcontinue;
end printExpStrSpecial;

protected function buildGrElement "
  Builds a Graphviz.Node from an element.
"
  input DAE.Element inElement;
  output Graphviz.Node outNode;
algorithm
  outNode := match (inElement)
    local
      String crstr,vkstr,expstr,expstr_1,e1str,e2str,n;
      DAE.ComponentRef cr,cr1,cr2;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Exp exp,e1,e2;
      list<Graphviz.Node> nodes;
      list<DAE.Element> elts;
    case DAE.VAR(componentRef = cr,kind = vk,binding = NONE())
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr},{},{});
    case DAE.VAR(componentRef = cr,kind = vk,binding = SOME(exp))
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr,expstr_1},{},{});
    case DAE.DEFINE(componentRef = cr,exp = exp)
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("DEFINE",{crstr,expstr_1},{},{});
    case DAE.EQUATION(exp = e1,scalar = e2)
      equation
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("EQUATION",{e1str,"=",e2str},{},{});
    case DAE.EQUEQUATION(cr1=cr1,cr2=cr2)
      equation
        e1str = printExpStrSpecial(Expression.crefExp(cr1));
        e2str = printExpStrSpecial(Expression.crefExp(cr2));
      then
        Graphviz.LNODE("EQUEQUATION",{e1str,"=",e2str},{},{});
    case DAE.ALGORITHM() then Graphviz.NODE("ALGORITHM",{},{});
    case DAE.INITIALDEFINE(componentRef = cr,exp = exp)
      equation
        crstr = ComponentReference.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("INITIALDEFINE",{crstr,expstr_1},{},{});
    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("INITIALEQUATION",{e1str,"=",e2str},{},{});
    case DAE.INITIALALGORITHM() then Graphviz.NODE("INITIALALGORITHM",{},{});
    case DAE.COMP(ident = n,dAElist = elts)
      equation
        nodes = buildGrList(elts);
      then
        Graphviz.LNODE("COMP",{n},{},nodes);
  end match;
end buildGrElement;

protected function unparseType "wrapper function for Types.unparseType, so records and enumerations can be output properly"
  input DAE.Type tp;
  output String str;
algorithm
  str := matchcontinue(tp)
    local
      String name, dim_str;
      Absyn.Path path;
      DAE.Type bc_tp, ty;
      list<DAE.Dimension> dims;

    case DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), source = {path})
      equation
        name = Absyn.pathStringNoQual(path);
      then
        name;

    case DAE.T_ARRAY(ty = ty)
      equation
        DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), source = {path}) =
          Types.arrayElementType(ty);
        dims = Types.getDimensions(tp);
        name = Absyn.pathStringNoQual(path);
        dim_str = List.toString(dims, ExpressionDump.dimensionString, "", "[",
            ", ", "]", false);
      then
        name + dim_str;

    case DAE.T_SUBTYPE_BASIC(complexType = ty as DAE.T_SUBTYPE_BASIC())
      then unparseType(ty);

    case DAE.T_SUBTYPE_BASIC(complexType = bc_tp) then Types.unparseType(bc_tp);
    else Types.unparseType(tp);
  end matchcontinue;
end unparseType;

public function unparseDimensions
"prints dimensions to a string"
  input DAE.InstDims dims;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
  output String dimsStr;
algorithm
  dimsStr := matchcontinue(dims, printTypeDimension)
    local
      String str;

    // false gives nothing
    case (_, false) then "";

    // nothing gives nothing
    case ({}, true) then "";
    // dims give something
    case (_, true)
     equation
       str = "[" + stringDelimitList(List.map(dims, ExpressionDump.dimensionString), ", ") + "]";
     then
       str;
  end matchcontinue;
end unparseDimensions;

public function dumpStr "This function prints the DAE to a string."
  input DAE.DAElist inDAElist;
  input DAE.FunctionTree functionTree;
  output String outString;
protected
  list<DAE.Element> daelist;
  functionList funList;
  list<compWithSplitElements> fixedDae;
algorithm
  DAE.DAE(elementLst = daelist) := inDAElist;
  funList := dumpFunctionList(functionTree);
  fixedDae := List.map(daelist, dumpDAEList);
  outString := Tpl.tplString2(DAEDumpTpl.dumpDAE, fixedDae, funList);
end dumpStr;

public function dumpElementsStr "This function prints the DAE to a string."
  input list<DAE.Element> els;
  output String outString;
algorithm
  outString := match (els)
    local
      IOStream.IOStream myStream;
      String str;

    case _
      equation
        myStream = IOStream.create("dae", IOStream.LIST());
        myStream = dumpElementsStream(els, myStream);
        str = IOStream.string(myStream);
      then
        str;
  end match;
end dumpElementsStr;

public function dumpAlgorithmsStr "This function prints the algorithms to a string."
  input list<DAE.Element> algs;
  output String outString;
algorithm
  outString := match (algs)
    local
      IOStream.IOStream myStream;
      String str;

    case _
      equation
        myStream = IOStream.create("algs", IOStream.LIST());
        myStream = dumpAlgorithmsStream(algs, myStream);
        str = IOStream.string(myStream);
      then
        str;
  end match;
end dumpAlgorithmsStr;


public function dumpConstraintsStr "This function prints the constraints to a string."
  input list<DAE.Element> constrs;
  output String outString;
algorithm
  outString := match (constrs)
    local
      IOStream.IOStream myStream;
      String str;

    case _
      equation
        myStream = IOStream.create("constrs", IOStream.LIST());
        myStream = dumpConstraintStream(constrs, myStream);
        str = IOStream.string(myStream);
      then
        str;
  end match;
end dumpConstraintsStr;

/************ IOStream based implementation ***************/
/************ IOStream based implementation ***************/
/************ IOStream based implementation ***************/
/************ IOStream based implementation ***************/

public function dumpStream "This function prints the DAE to a stream."
  input DAE.DAElist dae;
  input DAE.FunctionTree functionTree;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match (dae,functionTree,inStream)
    local
      list<DAE.Element> daelist;
      list<DAE.Function> funcs;
      IOStream.IOStream str;

    case (DAE.DAE(daelist), _, str)
      equation
        funcs = DAEUtil.getFunctionList(functionTree);
        funcs = sortFunctions(funcs);
        str = List.fold(funcs, dumpFunctionStream, str);
        str = IOStream.appendList(str, List.map(daelist, dumpExtObjClassStr));
        str = List.fold(daelist, dumpCompElementStream, str);
      then
        str;
  end match;
end dumpStream;

public function dumpDAEList " returns split  DAE elements(Mainly important for template based DAE unparser) :
   variables, initial equations, initial algorithms,
   equations, algorithms, constraints and external objects"
  input DAE.Element inElement;
  output compWithSplitElements outCompWSplElem;
algorithm
  (outCompWSplElem) := match (inElement)
    local
      String n;
      list<DAE.Element> l;
      Option<SCode.Comment> c;

      list<DAE.Element> v;
      list<DAE.Element> ie;
      list<DAE.Element> ia;
      list<DAE.Element> e;
      list<DAE.Element> a;
      list<DAE.Element> co;
      list<DAE.Element> o;
      list<DAE.Element> ca;
      list<compWithSplitElements> sm;
      splitElements loc_splelem;

      compWithSplitElements compWSplElem;


    case (DAE.COMP(ident = n,dAElist = l,comment = c))
      equation
       (v,ie,ia,e,a,ca,co,o,sm) = DAEUtil.splitElements(l);
        loc_splelem = SPLIT_ELEMENTS(v,ie,ia,e,a,ca,co,o,sm);
        compWSplElem = COMP_WITH_SPLIT(n, loc_splelem, c);
      then
        (compWSplElem);

  end match;
end dumpDAEList;

public function dumpFunctionList " returns sorted functions and record constructors in alphabetical order
  (mainly important for template based DAE unparser)."
  input DAE.FunctionTree functionTree;
  output functionList funList;
algorithm
  (funList) := match (functionTree)
    local
      list<DAE.Function> funcs;

    case _
      equation
        funcs = DAEUtil.getFunctionList(functionTree);
        funcs = List.filter2OnTrue(funcs, isVisibleFunction,
          Flags.isSet(Flags.DISABLE_RECORD_CONSTRUCTOR_OUTPUT),
          Flags.isSet(Flags.INLINE_FUNCTIONS));
        funcs = sortFunctions(funcs);
        funList = FUNCTION_LIST(funcs);
      then
        (funList);

  end match;
end dumpFunctionList;

protected function isVisibleFunction
  "Returns true if the given function should be visible in the flattened output."
  input DAE.Function inFunc;
  input Boolean inHideRecordCons "Hides record constructors if true.";
  input Boolean inInliningEnabled "Hides early inlined functions if true.";
  output Boolean outIsVisible;
algorithm
  outIsVisible := match(inFunc, inHideRecordCons, inInliningEnabled)
    local
      Option<SCode.Comment> cmt;

    // Hide functions with 'external "builtin"'.
    case (DAE.FUNCTION(functions = DAE.FUNCTION_EXT(externalDecl =
        DAE.EXTERNALDECL(language = "builtin")) :: _), _, _) then false;
    // Hide functions in package OpenModelica.
    case (DAE.FUNCTION(path = Absyn.FULLYQUALIFIED(
        Absyn.QUALIFIED(name = "OpenModelica"))), _, _) then false;
    // Hide functions which should always be inlined.
    case (DAE.FUNCTION(inlineType = DAE.BUILTIN_EARLY_INLINE()), _, _) then false;
    // Hide functions which should be inlined unless inlining is disabled.
    case (DAE.FUNCTION(inlineType = DAE.EARLY_INLINE()), _, true) then false;
    // Hide functions with annotation __OpenModelica_builtin = true.
    case (DAE.FUNCTION(comment = cmt), _, _)
      then not SCode.optCommentHasBooleanNamedAnnotation(cmt, "__OpenModelica_builtin");
    // Hide record constructors if requested.
    case (DAE.RECORD_CONSTRUCTOR(), true, _) then false;
    else true;
  end match;
end isVisibleFunction;

protected function dumpCompElementStream "Dumps components to a stream."
  input DAE.Element inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      String n;
      list<DAE.Element> l;
      Option<SCode.Comment> c;
      IOStream.IOStream str;

    case (DAE.COMP(ident = n,dAElist = l,comment = c), str)
      equation
        str = IOStream.append(str, "class ");
        str = IOStream.append(str, n);
        str = IOStream.append(str, dumpCommentStr(c));
        str = IOStream.append(str, "\n");
        str = dumpElementsStream(l, str);
        str = IOStream.append(str, dumpClassAnnotationStr(c));
        str = IOStream.append(str, "end ");
        str = IOStream.append(str, n);
        str = IOStream.append(str, ";\n");
      then
        str;

    case (_, str) then str;  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */
  end matchcontinue;
end dumpCompElementStream;

public function dumpElementsStream "Dump elements to a stream"
  input list<DAE.Element> l;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match(l, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Element> v,o,ie,ia,e,a,ca,co;
      list<compWithSplitElements> sm;

    case (_, str)
     equation
       // classify DAE
       (v,ie,ia,e,a,_,co,_,sm) = DAEUtil.splitElements(l);

       // dump components with split elements (e.g., state machines)
       str = dumpCompWithSplitElementsStream(sm, str);

       // dump variables
       str = dumpVarsStream(v, false, str);

       str = IOStream.append(str, if listEmpty(ie) then "" else "initial equation\n");
       str = dumpInitialEquationsStream(ie, str);

       str = dumpInitialAlgorithmsStream(ia, str);

       str = IOStream.append(str, if listEmpty(e) then "" else "equation\n");
       str = dumpEquationsStream(e, str);

       str = dumpAlgorithmsStream(a, str);

       str = IOStream.append(str, if listEmpty(co) then "" else "constraint\n");
       str = dumpConstraintStream(co, str);
     then
       str;
  end match;
end dumpElementsStream;

public function dumpCompWithSplitElementsStream "Dump components with split elements (e.g., state machines) to a stream."
  input list<compWithSplitElements> inCompLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match (inCompLst, inStream)
    local
      String name;
      splitElements spltElems;
      Option<SCode.Comment> comment;
      String cstr;
      IOStream.IOStream str;
      list<compWithSplitElements> xs;
      list<DAE.Element> v,o,ie,ia,e,a,ca,co;
      list<compWithSplitElements> sm;

    case ({}, str) then str;

    case (COMP_WITH_SPLIT(name=name, spltElems=spltElems, comment=comment) :: xs, str)
      algorithm
        try
          SOME(SCode.COMMENT(comment=SOME(cstr))) := comment;
          cstr := " \"" + cstr + "\"";
        else
          cstr := "";
        end try;
        SPLIT_ELEMENTS(v,ie,ia,e,a,co,_,_,sm) := spltElems;

        str := IOStream.append(str, name + cstr + "\n");

        str := dumpCompWithSplitElementsStream(sm, str);
        str := dumpVarsStream(v, false, str);
        str := IOStream.append(str, if listEmpty(ie) then "" else "initial equation\n");
        str := dumpInitialEquationsStream(ie, str);
        str := dumpInitialAlgorithmsStream(ia, str);
        str := IOStream.append(str, if listEmpty(e) then "" else "equation\n");
        str := dumpEquationsStream(e, str);
        str := dumpAlgorithmsStream(a, str);
        str := IOStream.append(str, if listEmpty(co) then "" else "constraint\n");
        str := dumpConstraintStream(co, str);

        str := IOStream.append(str, "end " + name + cstr + ";\n");
        str := dumpCompWithSplitElementsStream(xs, str);
      then
        str;
  end match;
end dumpCompWithSplitElementsStream;

public function dumpAlgorithmsStream "Dump algorithms to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;
      list<DAE.Element> xs;

    case ({}, str) then str;

    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)) :: xs, str)
      equation
        str = IOStream.append(str, "algorithm\n");
        str = IOStream.appendList(str, List.map(stmts, ppStatementStr));
        str = dumpAlgorithmsStream(xs, str);
      then
        str;

    case (_ :: xs, str)
      equation
        str = dumpAlgorithmsStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpAlgorithmsStream;

protected function dumpInitialAlgorithmsStream "Dump initialalgorithms to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;
      list<DAE.Element> xs;

    case ({}, str) then str;

    case (DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)) :: xs, str)
      equation
        str = IOStream.append(str, "initial algorithm\n");
        str = IOStream.appendList(str, List.map(stmts, ppStatementStr));
        str = dumpInitialAlgorithmsStream(xs, str);
      then
        str;

    case (_ :: xs, str)
      equation
        str = dumpInitialAlgorithmsStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpInitialAlgorithmsStream;

protected function dumpEquationsStream "Dump equations to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match (inElementLst, inStream)
    local
      String s1,s2,s3,s,sourceStr;
      DAE.Exp e1,e2,e3,e;
      list<DAE.Exp> conds,expl;
      list<DAE.Element> xs,xs1,xs2;
      list<list<DAE.Element>> tb;
      DAE.ComponentRef c,cr,cr1,cr2;
      IOStream.IOStream str;
      DAE.Element el;
      Absyn.Path path;
      DAE.Dimensions dims;
      DAE.ElementSource src;

    case ({}, str) then str;

    case ((DAE.EQUATION(exp = e1, scalar = e2, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, sourceStr, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.EQUEQUATION(cr1=cr1, cr2=cr2, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        str = IOStream.append(str, "  " +
          ComponentReference.printComponentRefStr(cr1) +
          " = " +
          ComponentReference.printComponentRefStr(cr2) +
          sourceStr +
          ";\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.ARRAY_EQUATION(dimension = dims, exp = e1, array = e2, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = if Config.typeinfo() then Types.printDimensionsStr(dims) else "";
        s3 = if Config.typeinfo() then " /* array equation [" + s3 + "] */" else "";
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, s3, sourceStr, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.COMPLEX_EQUATION(lhs = e1, rhs= e2, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, sourceStr, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.DEFINE(componentRef = c, exp = e, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ComponentReference.printComponentRefStr(c);
        s2 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, sourceStr, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.ASSERT(condition=e1, message = e2, level = DAE.ENUM_LITERAL(index=1), source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  assert(",s1,",",s2,")", sourceStr, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.ASSERT(condition=e1, message = e2, level = e3, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ExpressionDump.printExpStr(e3);
        str = IOStream.appendList(str, {"  assert(",s1,",",s2,",",s3,")",sourceStr,";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case (DAE.TERMINATE(message=e1, source = src) :: xs, str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ExpressionDump.printExpStr(e1);
        str = IOStream.appendList(str, {"  terminate(",s1,")", sourceStr, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.IF_EQUATION(condition1 = {},equations2 = {},equations3 = {}) :: _), str)
      then
        str;

    case ((DAE.IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::tb),equations3 = {}, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        str = IOStream.append(str, "  if ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = dumpIfEquationsStream(conds, tb, str);
        str = IOStream.append(str, "  end if");
        str = IOStream.append(str, sourceStr + ";\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::tb),equations3 = xs2, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        str = IOStream.append(str, "  if ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = dumpIfEquationsStream(conds, tb, str);
        str = IOStream.append(str, "  else\n");
        str = dumpEquationsStream(xs2, str);
        str = IOStream.append(str, "  end if" + sourceStr + ";\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.WHEN_EQUATION(condition = e,equations = xs1,elsewhen_ = SOME(el), source = src) :: xs), str)
      equation
        _ = getSourceInformationStr(src);
        str = IOStream.append(str, "when ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = IOStream.append(str, " else");
        str = dumpEquationsStream((el :: xs), str);
      then
        str;

    case ((DAE.WHEN_EQUATION(condition = e,equations = xs1,elsewhen_ = NONE(), source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        str = IOStream.append(str, "  when ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpEquationsStream(xs1, str);
        str = IOStream.append(str, "  end when" + sourceStr + ";\n");
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.REINIT(componentRef = cr, exp = e, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s = ComponentReference.printComponentRefStr(cr);
        s1 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  reinit(",s,",",s1,")",sourceStr,";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((DAE.NORETCALL(exp=e, source = src) :: xs), str)
      equation
        sourceStr = getSourceInformationStr(src);
        s1 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  ",s1, sourceStr, ";\n"});
        str = dumpEquationsStream(xs, str);
      then
        str;

    case ((_ :: xs), str)
      equation
        str = IOStream.append(str, "  /* unhandled equation in DAEDump.dumpEquationsStream FIXME! */\n");
        str = dumpEquationsStream(xs, str);
      then
        str;
  end match;
end dumpEquationsStream;

protected function dumpIfEquationsStream ""
  input list<DAE.Exp> iconds;
  input list<list<DAE.Element>> itbs;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match(iconds,itbs,inStream)
    local
      DAE.Exp c;
      list<DAE.Element> tb;
      IOStream.IOStream str;
      list<DAE.Exp> conds;
      list<list<DAE.Element>> tbs;

  case({},{},str) then str;

  case(c::conds, tb::tbs, str)
    equation
      str = IOStream.append(str, "  elseif ");
      str = IOStream.append(str, ExpressionDump.printExpStr(c));
      str = IOStream.append(str, " then\n");
      str = dumpEquationsStream(tb, str);
      str = dumpIfEquationsStream(conds,tbs, str);
    then
      str;
  end match;
end dumpIfEquationsStream;

protected function dumpInitialEquationsStream "Dump initial equations to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      String s1,s2;
      DAE.Exp e1,e2,e;
      list<DAE.Element> xs,xs1,xs2;
      list<list<DAE.Element>> trueBranches;
      DAE.ComponentRef c;
      IOStream.IOStream str;
      list<DAE.Exp> conds;

    case ({}, str) then str;

    case ((DAE.INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIAL_ARRAY_EQUATION(exp = e1, array = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIALDEFINE(componentRef = c,exp = e) :: xs), str)
      equation
        s1 = ComponentReference.printComponentRefStr(c);
        s2 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  ", s1, " = ", s2, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIAL_IF_EQUATION(condition1 = (e::conds),equations2 = (xs1::trueBranches),equations3 = xs2) :: xs), str)
      equation
        str = IOStream.append(str, "  if ");
        str = IOStream.append(str, ExpressionDump.printExpStr(e));
        str = IOStream.append(str, " then\n");
        str = dumpInitialEquationsStream(xs1, str);
        str = dumpIfEquationsStream(conds, trueBranches, str);
        str = IOStream.append(str, "  else\n");
        str = dumpInitialEquationsStream(xs2, str);
        str = IOStream.append(str, "  end if;\n");
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((DAE.INITIAL_NORETCALL(exp=e) :: xs), str)
      equation
        s1 = ExpressionDump.printExpStr(e);
        str = IOStream.appendList(str, {"  ",s1, ";\n"});
        str = dumpInitialEquationsStream(xs, str);
      then
        str;

    case ((_ :: xs), str)
      equation
        str = dumpInitialEquationsStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpInitialEquationsStream;

public function dumpConstraintStream "Dump constraints to a stream."
  input list<DAE.Element> inElementLst;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElementLst, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Exp> exps;
      list<DAE.Element> xs;

    case ({}, str) then str;

    case (DAE.CONSTRAINT(constraints = DAE.CONSTRAINT_EXPS(constraintLst = exps)) :: xs, str)
      equation
        // initial indenttion.
        str = IOStream.append(str, "  ");

        str = IOStream.append(str, stringDelimitList(List.map(exps, ExpressionDump.printExpStr),";\n  " ));
        //add the delimiter to the last element too. also if there is just 1 element in the 'exps' list.
        str = IOStream.append(str, ";\n");
        str = dumpConstraintStream(xs, str);
      then
        str;

    case (_ :: xs, str)
      equation
        str = dumpConstraintStream(xs, str);
      then
        str;
  end matchcontinue;
end dumpConstraintStream;

public function dumpDAEElementsStr "
Author BZ
print a DAE.DAEList to a string"
  input DAE.DAElist d;
  output String str;
algorithm
  str := match(d)
    local
      list<DAE.Element> l;
      IOStream.IOStream myStream;

    case(DAE.DAE(elementLst=l))
      equation
        myStream = IOStream.create("", IOStream.LIST());
        myStream = dumpElementsStream(l, myStream);
        str = IOStream.string(myStream);
      then str;
  end match;
end dumpDAEElementsStr;

public function dumpVarsStream "Dump variables to a string."
  input list<DAE.Element> inElementLst;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := match (inElementLst, printTypeDimension, inStream)
    local
      IOStream.IOStream str;
      DAE.Element first;
      list<DAE.Element> rest;
    // handle nothingness
    case ({},_,_) then inStream;
    // the usual case
    case (first :: rest, _, str)
      equation
        str = dumpVarStream(first, printTypeDimension, str);
        str = dumpVarsStream(rest, printTypeDimension, str);
      then
        str;
  end match;
end dumpVarsStream;

public function daeTypeStr
  input DAE.Type inType;
  output String outTypeStr;
protected
  String s1,s2;
algorithm
  (s1,s2) := printTypeStr(inType);
  outTypeStr := s1 + " " + s2;
end daeTypeStr;

public function printTypeStr
  input DAE.Type inType;
  output String outTypeStr;
  output String outTypeAttrStr;
protected
  DAE.Type ty;
  list<DAE.Var> ty_vars;
algorithm
  (ty, ty_vars) := Types.stripTypeVars(inType);
  outTypeStr := unparseType(ty);
  outTypeAttrStr := List.toString(ty_vars, Types.unparseVarAttr, "", "(", ", ", ")", false);
end printTypeStr;

public function dumpCallAttr
"dumps the DAE.CallAttributes"
  input DAE.CallAttributes ca;
protected
  Boolean tpl,bi,impure_;
  DAE.InlineType iType;
  DAE.Type ty;
  DAE.TailCall tailCall;
  String s1,s2;
algorithm
  DAE.CALL_ATTR(ty=ty,tuple_=tpl,builtin=bi,isImpure=impure_,inlineType=iType,tailCall=tailCall) := ca;
  print("Call attributes: \n----------------------\n");
  (s1,s2) := printTypeStr(ty);
  print("DAE-type: "+s1+"\n");
  print("DAE-type attributes :"+s2+"\n");
  print("tuple_: "+boolString(tpl)+" builtin: "+boolString(bi)+" impure: "+boolString(impure_)+"\n\n");
end dumpCallAttr;

protected function dumpVarBindingStr
  input Option<DAE.Exp> inBinding;
  output String outString;
algorithm
  outString := match(inBinding)
    local
      DAE.Exp exp;
      String bind_str;

    case SOME(exp)
      equation
        bind_str = ExpressionDump.printExpStr(exp);
      then
        " = " + bind_str;

    else "";
  end match;
end dumpVarBindingStr;

protected function dumpVarStream
  "Dump var to a stream."
  input DAE.Element inElement;
  input Boolean printTypeDimension "use true here when printing components in functions as these are not vectorized! Otherwise, use false";
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue(inElement, printTypeDimension, inStream)
    local
      String final_str, kind_str, dir_str, ty_str, ty_vars_str, dim_str, name_str;
      String vis_str, par_str, cmt_str, attr_str, binding_str;
      DAE.ComponentRef id;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.VarVisibility vis;
      DAE.Type ty;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> cmt;
      Option<DAE.Exp> binding;
      DAE.InstDims dims;
      IOStream.IOStream str;
      list<DAE.Var> ty_vars;

    case (DAE.VAR(componentRef = id,
                  kind = kind,
                  direction = dir,
                  parallelism = prl,
                  protection = vis,
                  ty = ty,
                  dims = dims,
                  binding = binding,
                  variableAttributesOption = attr,
                  comment = cmt), _, str)
      equation
        final_str = if DAEUtil.getFinalAttr(attr) then "final " else "";
        kind_str = dumpKindStr(kind);
        dir_str = dumpDirectionStr(dir);
        (ty_str, ty_vars_str) = printTypeStr(ty);
        dim_str = unparseDimensions(dims, printTypeDimension);
        name_str = ComponentReference.printComponentRefStr(id);
        vis_str = dumpVarVisibilityStr(vis);
        par_str = dumpVarParallelismStr(prl);
        cmt_str = dumpCommentAnnotationStr(cmt);
        attr_str = dumpVariableAttributesStr(attr);
        binding_str = dumpVarBindingStr(binding);
        str = IOStream.appendList(str, {"  ", vis_str, final_str, par_str,
            kind_str, dir_str, ty_str, dim_str, " ", name_str, ty_vars_str,
            attr_str, binding_str, cmt_str, ";\n"});
      then
        str;

    else inStream;

  end matchcontinue;
end dumpVarStream;

public function dumpAlgorithmStream
"Dump algorithm to a stream"
  input DAE.Element inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;

    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)), str)
      equation
        str = IOStream.append(str, "algorithm\n");
        str = List.fold(stmts, ppStatementStream, str);
      then
        str;
    case (_,str) then str;
  end matchcontinue;
end dumpAlgorithmStream;

public function dumpInitialAlgorithmStream
"Dump algorithm to a stream"
  input DAE.Element inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      IOStream.IOStream str;
      list<DAE.Statement> stmts;

    case (DAE.INITIALALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)), str)
      equation
        str = IOStream.append(str, "initial algorithm\n");
        str = List.fold(stmts, ppStatementStream, str);
      then
        str;
    case (_,str) then str;
  end matchcontinue;
end dumpInitialAlgorithmStream;

public function ppStatementStream
"Prettyprint an algorithm statement to a string."
  input DAE.Statement alg;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
protected
  String tmp;
  Integer hnd;
algorithm
  hnd := Print.saveAndClearBuf();
  ppStatement(alg);
  outStream := IOStream.append(inStream, Print.getString());
  Print.restoreBuf(hnd);
end ppStatementStream;

public function dumpFunctionTree
  input DAE.FunctionTree inFunctionTree;
  input String inHeading;
algorithm
  print("\n" + inHeading + "\n========================================\n");
  for fnc in sortFunctions(DAEUtil.getFunctionList(inFunctionTree)) loop
    print(dumpFunctionStr(fnc));
  end for;
end dumpFunctionTree;

public function dumpFunctionStr "Dump function to a string."
  input DAE.Function inElement;
  output String outString;
algorithm
  outString := matchcontinue (inElement)
    local
      String s;
      Integer hnd;

    case _
      equation
        hnd = Print.saveAndClearBuf();
        dumpFunction(inElement);
        s = Print.getString();
        Print.restoreBuf(hnd);
      then
        s;

    else "";
  end matchcontinue;
end dumpFunctionStr;

protected function dumpExtObjClassStr
"Dump external object class to a string."
  input DAE.Element inElement;
  output String outString;
algorithm
  outString := matchcontinue (inElement)
    local
      String s;
      Integer hnd;

    case DAE.EXTOBJECTCLASS()
      equation
        hnd = Print.saveAndClearBuf();
        dumpExtObjectClass(inElement);
        s = Print.getString();
        Print.restoreBuf(hnd);
      then
        s;

    else "";
  end matchcontinue;
end dumpExtObjClassStr;

protected function dumpFunctionStream
"Dump function to a stream"
  input DAE.Function inElement;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := matchcontinue (inElement, inStream)
    local
      String fstr, ext_decl_str, impureStr, ann_str;
      Absyn.Path fpath;
      list<DAE.Element> daeElts;
      DAE.Type t;
      DAE.Type tp;
      DAE.InlineType inlineType;
      IOStream.IOStream str;
      Option<SCode.Comment> c;
      DAE.ExternalDecl ext_decl;
      Boolean isImpure;

    case (DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_DEF(body = daeElts)::_),
                       type_ = t, isImpure = isImpure, comment = c), str)
      equation
        str = IOStream.append(str, dumpParallelismStr(t));
        fstr = Absyn.pathStringNoQual(fpath);
        impureStr = if isImpure then "impure " else "";
        str = IOStream.append(str, impureStr);
        str = IOStream.append(str, "function ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, dumpInlineTypeStr(inlineType));
        str = IOStream.append(str, dumpCommentStr(c));
        str = IOStream.append(str, "\n");
        str = dumpFunctionElementsStream(daeElts, str);
        str = IOStream.append(str, dumpClassAnnotationStr(c));
        str = IOStream.append(str, "end ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, ";\n\n");
      then
        str;

      case (DAE.FUNCTION(functions=(DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(language="builtin"))::_)), str)
      then
        str;

      case (DAE.FUNCTION(path = fpath,inlineType=inlineType,functions = (DAE.FUNCTION_EXT(body = daeElts, externalDecl = ext_decl)::_),
                         isImpure = isImpure, comment = c), str)
      equation
        fstr = Absyn.pathStringNoQual(fpath);
        impureStr = if isImpure then "impure " else "";
        str = IOStream.append(str, impureStr);
        str = IOStream.append(str, "function ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, dumpInlineTypeStr(inlineType));
        str = IOStream.append(str, dumpCommentStr(c));
        str = IOStream.append(str, "\n");
        str = dumpFunctionElementsStream(daeElts, str);
        ext_decl_str = dumpExtDeclStr(ext_decl);
        ann_str = dumpClassAnnotationStr(c);
        str = IOStream.appendList(str, {"\n  ", ext_decl_str, "\n", ann_str, "end ", fstr, ";\n\n"});
      then
        str;

    case (DAE.RECORD_CONSTRUCTOR(path = fpath,type_=tp), str)
      equation
        false = Flags.isSet(Flags.DISABLE_RECORD_CONSTRUCTOR_OUTPUT);
        fstr = Absyn.pathStringNoQual(fpath);
        str = IOStream.append(str, "function ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, " \"Automatically generated record constructor for " + fstr + "\"\n");
        str = IOStream.append(str, printRecordConstructorInputsStr(tp));
        str = IOStream.append(str, "  output "+Absyn.pathLastIdent(fpath) + " res;\n");
        str = IOStream.append(str, "end ");
        str = IOStream.append(str, fstr);
        str = IOStream.append(str, ";\n\n");
      then
        str;

    case (_, str) then str;
  end matchcontinue;
end dumpFunctionStream;

public function dumpFunctionElementsStream "Dump function elements to a stream."
  input list<DAE.Element> l;
  input IOStream.IOStream inStream;
  output IOStream.IOStream outStream;
algorithm
  outStream := dumpVarsStream(l, true, inStream);
  outStream := List.fold(l, dumpAlgorithmStream, outStream);
end dumpFunctionElementsStream;

public function unparseVarKind
  input DAE.VarKind inVarKind;
  output String outString;
algorithm
  outString := match(inVarKind)
    case DAE.VARIABLE() then "";
    case DAE.PARAM() then "parameter";
    case DAE.CONST() then "const";
    case DAE.DISCRETE() then "discrete";
  end match;
end unparseVarKind;

public function unparseVarDirection
  input DAE.VarDirection inVarDirection;
  output String outString;
algorithm
  outString := match(inVarDirection)
    case DAE.BIDIR() then "";
    case DAE.INPUT() then "input";
    case DAE.OUTPUT() then "output";
  end match;
end unparseVarDirection;

public function getSourceInformationStr
"@author: adrpo
 display the source information as string"
  input DAE.ElementSource inSource;
  output String outStr;
algorithm
  outStr := matchcontinue(inSource)
    local
      SourceInfo i;
      list<Absyn.Within> po;
      list<Option<DAE.ComponentRef>> iol;
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> ceol;
      list<Absyn.Path> tl;
      list<DAE.SymbolicOperation> op;
      list<SCode.Comment> cmt;
      String str;

    case (_)
      equation
        false = Flags.isSet(Flags.SHOW_EQUATION_SOURCE);
      then
        "";

    case (DAE.SOURCE(_, po, _, ceol, _, _, cmt))
      equation
        str = cmtListToString(cmt);
        str = str + " /* models: {" + stringDelimitList(List.map(po, withinString), ", ") + "}" +
                     " connects: {" + stringDelimitList(connectsStr(ceol), ", ") + "} */";
      then
        str;
  end matchcontinue;
end getSourceInformationStr;

protected function connectsStr
  input list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> inLst;
  output list<String> outStr;
algorithm
  outStr := matchcontinue(inLst)
    local
      list<Option<tuple<DAE.ComponentRef, DAE.ComponentRef>>> rest;
      list<String> slst;
      String str;
      DAE.ComponentRef c1, c2;

    case ({}) then {};

    case ({NONE()}) then {};

    case ({SOME((c1,c2))})
      equation
        str = ComponentReference.printComponentRefStr(c1) + "," +
              ComponentReference.printComponentRefStr(c2);
        str =  "connect(" + str + ")";
      then
        {str};

    case (SOME((c1,c2))::rest)
      equation
        str = ComponentReference.printComponentRefStr(c1) + "," +
              ComponentReference.printComponentRefStr(c2);
        str =  "connect(" + str + ")";
        slst = connectsStr(rest);
      then
        str::slst;

    case (NONE()::rest)
      equation
        slst = connectsStr(rest);
      then
        slst;

  end matchcontinue;
end connectsStr;

protected function withinString
  input Absyn.Within w;
  output String str;
algorithm
  str := match (w)
    local
      Absyn.Path p1;
    case (Absyn.TOP()) then "TOP";
    case (Absyn.WITHIN(p1)) then Absyn.pathString(p1);
  end match;
end withinString;

public function cmtListToString
  input list<SCode.Comment> inCmtLst;
  output String outStr;
algorithm
  outStr := matchcontinue(inCmtLst)
    local
      SCode.Comment c;
      list<SCode.Comment> rest;
      String str;

    case ({}) then "";

    case ({c})
      equation
        str = dumpCommentAnnotationStr(SOME(c));
      then
        str;

    case (c::rest)
      equation
        str = dumpCommentAnnotationStr(SOME(c));
        str = str + " " + cmtListToString(rest);
      then
        str;

    else "";

  end matchcontinue;
end cmtListToString;

annotation(__OpenModelica_Interface="frontend");
end DAEDump;
