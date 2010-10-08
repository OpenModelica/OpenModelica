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

package Debug
" file:	 Debug.mo
  package:      Debug
  description: debug printing

  RCS: $Id$

  Printing routines for debug output of strings. Also flag controlled
  printing. When flag controlled printing functions are called, printing is
  done only if the given flag is among the flags given in the runtime
  arguments, to +d-flag, i.e. if +d=inst,lookup is given in the command line,
  only calls containing these flags will actually print something, e.g.:
  fprint(\"inst\", \"Starting instantiation...\"). See runtime/rtopts.c for
  implementation of flag checking."

protected import RTOpts;
protected import Print;
protected import Util;

public function print
"function: print
  author: PR
  This function is used for debug printing."
  input String s;
algorithm
  fprint("olddebug", s);
end print;

public function trace
"function: print
  author: adrpo
  used for debug printing."
  input String s;
algorithm
  Print.printErrorBuf(s);
end trace;

public function traceln
"function: traceln
  author: adrpo
  printing with newline."
  input String str;
algorithm
  Print.printErrorBuf(str);
  Print.printErrorBuf("\n");
end traceln;

public function fprint
"function: fprint
  author: LS
  Flag controlled debugging"
  input String inString1;
  input String inString2;
algorithm
  _ := matchcontinue (inString1,inString2)
    local String flag,str;
    case (flag,str)
      equation
        true = RTOpts.debugFlag(flag);
        Print.printErrorBuf(str);
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end fprint;

public function fprintln
"function: fprintln
  Flag controlled debugging, printing with newline."
  input String inString1;
  input String inString2;
algorithm
  _ := matchcontinue (inString1,inString2)
    local String flag,str;
    case (flag,str)
      equation
        true = RTOpts.debugFlag(flag);
        Print.printErrorBuf(str);
        Print.printErrorBuf("\n");
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end fprintln;

public function fprintl
"function: fprintl
  flag controlled debugging, printing of string list."
  input String inString;
  input list<String> inStringLst;
algorithm
  _ := matchcontinue (inString,inStringLst)
    local
      String str,flag;
      list<String> strlist;
    case (flag,strlist)
      equation
        true = RTOpts.debugFlag(flag);
        str = Util.stringAppendList(strlist);
        Print.printErrorBuf(str);
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end fprintl;

public function fcall2
"function: fcall2
  Flag controlled calling of the given function (2nd arg)"
  input String inString;
  input FuncTypeTypeATypeB func;
  input Type_a inTypeA;
  input Type_b inTypeB;
  partial function FuncTypeTypeATypeB
    input Type_a inTypeA;
    input Type_b inTypeB;
  end FuncTypeTypeATypeB;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  _ := matchcontinue (inString,func,inTypeA,inTypeB)
    local
      Type_a arg1;
      Type_b arg2;
      String flag;
    case (flag,func,arg1,arg2)
      equation
        true = RTOpts.debugFlag(flag);
        func(arg1,arg2);
      then
        ();
    case (_,_,_,_) then ();
  end matchcontinue;
end fcall2;

public function fcall
"function: fcall
  Flag controlled calling of the given function (2nd arg)"
  input String inString;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := matchcontinue (inString,inFuncTypeTypeATo,inTypeA)
    local
      String flag;
      FuncTypeType_aTo func;
      Type_a str;
    case (flag,func,str)
      equation
        true = RTOpts.debugFlag(flag);
        func(str);
      then
        ();
    case (_,_,_) then ();
  end matchcontinue;
end fcall;

public function fcall0
"function: fcall0
  Flag controlled calling of given function  (2nd arg)"
  input String inString;
  input FuncTypeTo inFuncTypeTo;
  partial function FuncTypeTo
  end FuncTypeTo;
algorithm
  _ := matchcontinue (inString,inFuncTypeTo)
    local
      String flag;
      FuncTypeTo func;
    case (flag,func)
      equation
        true = RTOpts.debugFlag(flag);
        func();
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end fcall0;

public function fcallret0
"function: fcallret0
  Flag controlled calling of given function (2nd arg).
  The passed function gets 0 arguments.
  The last parameter is returned if the given flag is not set."
  input String inString;
  input FuncTypeToType_b inFuncTypeTypeB;
  input Type_b inTypeB;
  output Type_b outTypeB;
  partial function FuncTypeToType_b
    output Type_b outTypeB;
  end FuncTypeToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeB := matchcontinue (inString,inFuncTypeTypeB,inTypeB)
    local
      Type_b res,def;
      String flag;
      FuncTypeToType_b func;
    case (flag,func,def)
      equation
        true = RTOpts.debugFlag(flag);
        res = func();
      then
        res;
    case (_,_,def) then def;
  end matchcontinue;
end fcallret0;

public function fcallret1
"function: fcallret1
  Flag controlled calling of given function (2nd arg).
  The passed function gets 1 arguments.
  The last parameter is returned if the given flag is not set."
  input String inString;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  input Type_a inTypeA;
  input Type_b inTypeB;
  output Type_b outTypeB;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeB := matchcontinue (inString,inFuncTypeTypeAToTypeB,inTypeA,inTypeB)
    local
      Type_b res,def;
      String flag;
      FuncTypeType_aToType_b func;
      Type_a arg;
    case (flag,func,arg,def)
      equation
        true = RTOpts.debugFlag(flag);
        res = func(arg);
      then
        res;
    case (_,_,_,def) then def;
  end matchcontinue;
end fcallret1;

public function fcallret2
"function: fcallret2
  Flag controlled calling of given function (2nd arg).
  The passed function gets 2 arguments.
  The last parameter is returned if the given flag is not set."
  input String flag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c default;
  output Type_c res;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  res := matchcontinue (flag,func,arg1,arg2,default)
    case (flag,func,arg1,arg2,_)
      equation
        true = RTOpts.debugFlag(flag);
        res = func(arg1,arg2);
      then
        res;
    case (_,_,_,_,default) then default;
  end matchcontinue;
end fcallret2;

public function bcallret1
"function: bcallret1
  Boolean-controlled calling of given function (2nd arg).
  The passed function gets 1 arguments.
  The last parameter is returned if the boolean is false."
  input Boolean inBool;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  input Type_a inTypeA;
  input Type_b inTypeB;
  output Type_b outTypeB;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeB := matchcontinue (inBool,inFuncTypeTypeAToTypeB,inTypeA,inTypeB)
    local
      Type_b res,def;
      String flag;
      FuncTypeType_aToType_b func;
      Type_a arg;
    case (true,func,arg,def)
      equation
        res = func(arg);
      then
        res;
    case (false,_,_,def) then def;
  end matchcontinue;
end bcallret1;

public function bcall
"function: bcall
  bool controlled calling of function."
  input Boolean inBoolean;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := matchcontinue (inBoolean,inFuncTypeTypeATo,inTypeA)
    local
      FuncTypeType_aTo func;
      Type_a str;
    case (true,func,str)
      equation
        func(str);
      then
        ();
    case (false,_,_) then ();
  end matchcontinue;
end bcall;

public function bcall2
"function: bcall2
  bool controlled calling of function."
  input Boolean inBoolean;
  input FuncTypeType_aType_bTo inFuncTypeTypeATypeBTo;
  input Type_a inTypeA;
  input Type_b inTypeB;
  partial function FuncTypeType_aType_bTo
    input Type_a inTypeA;
    input Type_b inTypeB;
  end FuncTypeType_aType_bTo;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  _ := matchcontinue (inBoolean,inFuncTypeTypeATypeBTo,inTypeA,inTypeB)
    local
      FuncTypeType_aType_bTo func;
      Type_a a;
      Type_b b;
    case (true,func,a,b)
      equation
        func(a, b);
      then
        ();
    case (false,_,_,_) then ();
  end matchcontinue;
end bcall2;

public function notfcall
"function: notfcall
  Call the given function (2nd arg)
  if the flag given in 1st arg is
  NOT set"
  input String inString;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := matchcontinue (inString,inFuncTypeTypeATo,inTypeA)
    local
      String flag;
      FuncTypeType_aTo func;
      Type_a str;
    case (flag,func,str)
      equation
        false = RTOpts.debugFlag(flag);
        func(str);
      then
        ();
    case (_,_,_) then ();
  end matchcontinue;
end notfcall;

public function fprintList
"function: fprintList
  If flag is set, print the elements in
  the list, using the passed function."
  input String inString1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aTo inFuncTypeTypeATo3;
  input String inString4;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _ := matchcontinue (inString1,inTypeALst2,inFuncTypeTypeATo3,inString4)
    local
      String flag,sep;
      list<Type_a> lst;
      FuncTypeType_aTo func;
    case (flag,lst,func,sep)
      equation
        true = RTOpts.debugFlag(flag);
        printList(lst, func, sep);
      then
        ();
    case (_,_,_,_) then ();
  end matchcontinue;
end fprintList;

protected function printList
"function: fprintList
  If flag is set, print the elements in
  the list, using the passed function."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _ := matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      String sep;
    case ({},_,_) then ();
    case ({h},r,_)
      equation
        r(h);
      then
        ();
    case ((h :: t),r,sep)
      equation
        r(h);
        Print.printErrorBuf(sep);
        printList(t, r, sep);
      then
        ();
  end matchcontinue;
end printList;


end Debug;

