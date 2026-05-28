/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ValuesDump
" file:        ValuesDump.mo
  package:     ValuesDump
  description: Evaluated expression values


  The package Values contains utility functions for handling evaluated
  expression values."

import Absyn;
import Values;
protected
import AbsynUtil;
import Dump;
import Error;
import Flags;
import List;
import Print;
import System;

public function valString "This function returns a textual representation of a value."
  input Values.Value inValue;
  output String outString;
protected
  Integer handle;
algorithm
  handle := Print.saveAndClearBuf();
  valString2(inValue);
  outString := Print.getString();
  Print.restoreBuf(handle);
end valString;

public function valString2 "This function returns a textual representation of a value.
  Uses an external buffer to store intermediate results."
  input Values.Value inValue;
algorithm
  () := matchcontinue inValue
    local
      String s, recordName, tyStr, scope, name;
      Integer n;
      Real x;
      list<Values.Value> xs,vs;
      Values.Value r;
      Absyn.CodeNode c;
      Absyn.Path p, recordPath;
      list<String> ids;
      Absyn.ComponentRef cr;
      Absyn.Path path;

    case Values.INTEGER(integer = n)
      algorithm
        s := intString(n);
        Print.printBuf(s);
      then
        ();
    case Values.REAL(real = x)
      algorithm
        s := realString(x);
        Print.printBuf(s);
      then
        ();
    case Values.STRING(string = s)
      algorithm
        Print.printBuf("\"");
        Print.printBuf(System.escapedString(s, false));
        Print.printBuf("\"");
      then
        ();
    case Values.BOOL(boolean = false)
      algorithm
        Print.printBuf("false");
      then
        ();
    case Values.BOOL(boolean = true)
      algorithm
        Print.printBuf("true");
      then
        ();
    case Values.ENUM_LITERAL(name = p)
      algorithm
        s := AbsynUtil.pathString(p);
        Print.printBuf(s);
      then
        ();
    case Values.ARRAY(valueLst = vs)
      algorithm
        Print.printBuf("{");
        valListString(vs);
        Print.printBuf("}");
      then
        ();
    case Values.TUPLE(valueLst = {})
      then ();
    case Values.TUPLE(valueLst = vs)
      algorithm
        Print.printBuf("(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();
    case Values.META_TUPLE(valueLst = {})
      then ();
    case Values.META_TUPLE(valueLst = vs)
      algorithm
        Print.printBuf("(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();

    case Values.RECORD(record_ = Absyn.IDENT("SimulationResult"), orderd = xs, comp = ids)
      algorithm
        Print.printBuf("record SimulationResult\n");
        (xs,ids) := filterSimulationResults(Flags.isSet(Flags.SHORT_OUTPUT),xs,ids,{},{});
        valRecordString(xs,ids);
        Print.printBuf("end SimulationResult;");
      then
        ();

    case Values.RECORD(record_ = recordPath, orderd = xs, comp = ids)
      algorithm
        recordName := AbsynUtil.pathStringNoQual(recordPath);

        Print.printBuf("record " + recordName + "\n");
        valRecordString(xs,ids);
        Print.printBuf("end " + recordName + ";");
      then
        ();

    case Values.OPTION(SOME(r))
      algorithm
        Print.printBuf("SOME(");
        valString2(r);
        Print.printBuf(")");
      then
        ();
    case Values.OPTION(NONE())
      algorithm
        Print.printBuf("NONE()");
      then
        ();

    case Values.META_BOX(r)
      algorithm
        Print.printBuf("#(");
        valString2(r);
        Print.printBuf(")");
      then
        ();

    case Values.CODE(A = Absyn.C_TYPENAME(path))
      algorithm
        Print.printBuf(AbsynUtil.pathString(path));
      then
        ();

    case Values.CODE(A = Absyn.C_VARIABLENAME(cr))
      algorithm
        Print.printBuf(Dump.printComponentRefStr(cr));
      then
        ();

    case Values.CODE(A = c)
      algorithm
        Print.printBuf("$Code(");
        Print.printBuf(Dump.printCodeStr(c));
        Print.printBuf(")");
      then
        ();

    // MetaModelica list
    case Values.LIST(valueLst = vs)
      algorithm
        Print.printBuf("{");
        valListString(vs);
        Print.printBuf("}");
      then
        ();

    // MetaModelica array
    case Values.META_ARRAY(valueLst = vs)
      algorithm
        Print.printBuf("meta_array(");
        valListString(vs);
        Print.printBuf(")");
      then
        ();

    /* Until is it no able to get from an string Enumeration the C-Enumeration use the index value */
    /* Example: This is yet not possible Enum.e1 \\ PEnum   ->  1 \\ PEnum  with enum Enum(e1,e2), Enum PEnum; */
    case Values.ENUM_LITERAL(index = n, name=p)
      algorithm
        s := intString(n) + " /* ENUM: " + AbsynUtil.pathString(p) + " */";
        Print.printBuf(s);
      then
        ();

    case Values.NORETCALL()
      then ();

    case Values.META_FAIL()
      algorithm
        Print.printBuf("fail()");
      then ();

    case Values.EMPTY(scope = scope, name = name, tyStr = tyStr)
      algorithm
        Print.printBuf("/* <EMPTY(scope: " + scope + ", name: " + name + ", ty: " + tyStr + ")> */");
      then ();

    else
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {"ValuesDump.valString2 failed"});
      then
        fail();
  end matchcontinue;
end valString2;

protected function filterSimulationResults
  input Boolean filter;
  input list<Values.Value> inValues;
  input list<String> inIds;
  input list<Values.Value> valacc;
  input list<String> idacc;
  output list<Values.Value> outValues;
  output list<String> outIds;
algorithm
  (outValues,outIds) := match (filter, inValues, inIds)
    local
      Values.Value v;
      list<Values.Value> vrest;
      String id,str;
      list<String> idrest;
    case (_, {}, {}) then (listReverse(valacc),listReverse(idacc));
    case (true, v::vrest, (id as "messages")::idrest)
      algorithm
        (outValues,outIds) := filterSimulationResults(filter,vrest,idrest,v::valacc,id::idacc);
      then (outValues,outIds);
    case (true, Values.STRING(str)::vrest, (id as "resultFile")::idrest)
      algorithm
        str := System.basename(str);
        (outValues,outIds) := filterSimulationResults(filter,vrest,idrest,Values.STRING(str)::valacc,id::idacc);
      then (outValues,outIds);
    case (true, _::vrest, _::idrest)
      algorithm
        (outValues,outIds) := filterSimulationResults(filter,vrest,idrest,valacc,idacc);
      then (outValues,outIds);
    case (false, _, _) then (inValues,inIds);
  end match;
end filterSimulationResults;

protected function valRecordString
"This function returns a textual representation of a record,
 separating each value with a comma."
  input list<Values.Value> inValues;
  input list<String> inIds;
algorithm
  () := matchcontinue (inValues,inIds)
    local
      String id;
      Values.Value x;
      list<Values.Value> xs;
      list<String> ids;

    case ({},{}) then ();

    case (x :: (xs as (_ :: _)),id :: (ids as (_ :: _)))
      algorithm
        Print.printBuf("    ");
        Print.printBuf(id);
        Print.printBuf(" = ");
        valString2(x);
        Print.printBuf(",\n");
        valRecordString(xs,ids);
      then
        ();

    case (x :: {},id :: {})
      algorithm
        Print.printBuf("    ");
        Print.printBuf(id);
        Print.printBuf(" = ");
        valString2(x);
        Print.printBuf("\n");
      then
        ();

    case (xs,ids)
      algorithm
        print("ValuesUtil.valRecordString failed:\nids: "+ stringDelimitList(ids, ", ") +
        "\nvals: " + stringDelimitList(List.map(xs, valString), ", ") + "\n");
      then
        fail();

  end matchcontinue;
end valRecordString;

protected function valListString "
  This function returns a textual representation of a list of
  values, separating each value with a comma.
"
  input list<Values.Value> inValueLst;
algorithm
  () := match inValueLst
    local
      Values.Value v;
      list<Values.Value> vs;
    case {} then ();
    case {v}
      algorithm
        valString2(v);
      then
        ();
    case v :: vs
      algorithm
        valString2(v);
        Print.printBuf(", ");
        valListString(vs);
      then
        ();
  end match;
end valListString;

public function printVal "This function prints a value."
  input Values.Value v;
protected
  String s;
algorithm
  s := valString(v);
  Print.printBuf(s);
end printVal;

public function printValStr "
more correct naming then valString"
  input Values.Value v;
  output String s;
algorithm
  s := valString(v);
end printValStr;


public function unparseValues "Prints a list of Value to a string."
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString := match inValueLst
    local
      String s1,s2,s3,str;
      Values.Value v;
      list<Values.Value> vallst;
    case v :: vallst
      algorithm
        s1 := unparseDescription({v});
        s2 := unparseValueNumbers({v});
        s3 := unparseValues(vallst);
        str := stringAppendList({s1,s2,"\n",s3});
      then
        str;
    case {} then "";
  end match;
end unparseValues;

protected function unparseValueNumbers "Helper function to unparse_values.
  Prints all the numbers of the values."
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString := match inValueLst
    local
      String s1,s2,res,istr,sval;
      list<Values.Value> lst,xs;
      Integer i;
      Real r;
    case Values.TUPLE(valueLst = lst) :: xs
      algorithm
        s1 := unparseValueNumbers(lst);
        s2 := unparseValueNumbers(xs);
        res := stringAppend(s1, s2);
      then
        res;
    case Values.META_TUPLE(valueLst = lst) :: xs
      algorithm
        s1 := unparseValueNumbers(lst);
        s2 := unparseValueNumbers(xs);
        res := stringAppend(s1, s2);
      then
        res;
    case Values.ARRAY(valueLst = lst) :: xs
      algorithm
        s1 := unparseValueNumbers(lst);
        s2 := unparseValueNumbers(xs);
        res := stringAppend(s1, s2);
      then
        res;
    case Values.INTEGER(integer = i) :: xs
      algorithm
        s1 := unparseValueNumbers(xs);
        istr := intString(i);
        s2 := stringAppend(istr, " ");
        res := stringAppend(s2, s1);
      then
        res;
    case Values.REAL(real = r) :: xs
      algorithm
        s1 := unparseValueNumbers(xs);
        istr := realString(r);
        s2 := stringAppend(istr, " ");
        res := stringAppend(s2, s1);
      then
        res;
    case Values.STRING(string = sval) :: xs
      algorithm
        s1 := unparseValueNumbers(xs);
        s2 := stringAppend(sval, " ");
        res := stringAppend(s2, s1);
      then
        res;
    case {} then "";
  end match;
end unparseValueNumbers;


protected function unparseDescription "
  Helper function to unparse_values. Creates a description string
  for the type of the value.
"
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString:=
  match inValueLst
    local
      String s1,str,slenstr,sval,s2,s4;
      list<Values.Value> xs,vallst;
      Integer slen;
    case Values.INTEGER() :: xs
      algorithm
        s1 := unparseDescription(xs);
        str := stringAppend("# i!\n", s1);
      then
        str;
    case Values.REAL() :: xs
      algorithm
        s1 := unparseDescription(xs);
        str := stringAppend("# r!\n", s1);
      then
        str;
    case Values.STRING(string = sval) :: xs
      algorithm
        s1 := unparseDescription(xs);
        slen := stringLength(sval);
        slenstr := intString(slen);
        str := stringAppendList({"# s! 1 ",slenstr,"\n",s1});
      then
        str;
    case Values.ARRAY(valueLst = vallst) :: xs
      algorithm
        s1 := unparseDescription(xs);
        s2 := unparseArrayDescription(vallst);
        s4 := stringAppend(s2, s1);
        str := stringAppend(s4, " \n");
      then
        str;
    case {} then "";
  end match;
end unparseDescription;

protected function unparseArrayDescription "
  Helper function to unparse_description.
"
  input list<Values.Value> lst;
  output String str;
protected
  String pt,s1,s2,s3,s4,s5,s6;
  Integer i1;
algorithm
  pt := unparsePrimType(lst);
  s1 := stringAppend("# ", pt);
  s2 := stringAppend(s1, "[");
  i1 := unparseNumDims(lst,0);
  s3 := intString(i1);
  s4 := stringAppend(s2, s3);
  s5 := stringAppend(s4, " ");
  s6 := unparseDimSizes(lst);
  str := stringAppend(s5, s6);
end unparseArrayDescription;

protected function unparsePrimType "
  Helper function to unparse_array_description.
"
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString:=
  match inValueLst
    local
      String res;
      list<Values.Value> elts;
    case Values.ARRAY(valueLst = elts) :: _
      algorithm
        res := unparsePrimType(elts);
      then
        res;
    case Values.INTEGER() :: _ then "i";
    case Values.REAL() :: _ then "r";
    case Values.STRING() :: _ then "s";
    case Values.BOOL() :: _ then "b";
    case {} then "{}";
    else "error";
  end match;
end unparsePrimType;

protected function unparseNumDims "
  Helper function to unparse_array_description.
"
  input list<Values.Value> inValueLst;
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger:=
  match inValueLst
    local
      list<Values.Value> vals;
    case Values.ARRAY(valueLst = vals) :: _
      then
        unparseNumDims(vals, inInteger + 1);
    else inInteger + 1;
  end match;
end unparseNumDims;

protected function unparseDimSizes "
  Helper function to unparse_array_description.
"
  input list<Values.Value> inValueLst;
  output String outString;
algorithm
  outString:=
  matchcontinue inValueLst
    local
      Integer i1,len;
      String s1,s2,s3,res;
      list<Values.Value> lst,vals;
    case lst as (Values.ARRAY(valueLst = vals) :: _)
      algorithm
        i1 := listLength(lst);
        s1 := intString(i1);
        s2 := stringAppend(s1, " ");
        s3 := unparseDimSizes(vals);
        res := stringAppend(s2, s3);
      then
        res;
    case lst
      algorithm
        len := listLength(lst);
        res := intString(len);
      then
        res;
  end matchcontinue;
end unparseDimSizes;

annotation(__OpenModelica_Interface="frontend_dump");
end ValuesDump;
