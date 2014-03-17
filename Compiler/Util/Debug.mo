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

encapsulated package Debug
" file:        Debug.mo
  package:     Debug
  description: Debug printing

  RCS: $Id$

  Printing routines for debug output of strings. Also flag controlled
  printing. When flag controlled printing functions are called, printing is
  done only if the given flag is among the flags given in the runtime
  arguments, to +d-flag, i.e. if +d=inst,lookup is given in the command line,
  only calls containing these flags will actually print something, e.g.:
  fprint(\"inst\", \"Starting instantiation...\"). See runtime/rtopts.c for
  implementation of flag checking."

public import Flags;
// protected imports
protected import Print;
protected import System;

public function trace
"author: adrpo
  used for debug printing."
  input String s;
algorithm
  Print.printErrorBuf(s);
end trace;

public function traceln
"author: adrpo
  printing with newline."
  input String str;
algorithm
  Print.printErrorBuf(str);
  Print.printErrorBuf("\n");
end traceln;

public function fprint
"author: LS
  Flag controlled debugging"
  input Flags.DebugFlag flag;
  input String str;
  // annotation(__OpenModelica_EarlyInline=true);
algorithm
  bprint(Flags.isSet(flag),str);
end fprint;

public function bprint
"author: LS
  Boolean controlled debugging"
  input Boolean cond;
  input String str;
  // annotation(__OpenModelica_EarlyInline=true);
algorithm
  _ := match (cond,str)
    case (true,_)
      equation
        Print.printErrorBuf(str);
      then ();
    else ();
  end match;
end bprint;

public function bprintln
"author: LS
  Boolean controlled debugging"
  input Boolean cond;
  input String str;
  // annotation(__OpenModelica_EarlyInline=true);
algorithm
  _ := match (cond,str)
    case (true,_)
      equation
        Print.printErrorBuf(str);
        Print.printErrorBuf("\n");
      then ();
    else ();
  end match;
end bprintln;

public function fprintln
"Flag controlled debugging, printing with newline."
  input Flags.DebugFlag flag;
  input String str;
  // annotation(__OpenModelica_EarlyInline=true);
algorithm
  bprintln(Flags.isSet(flag),str);
end fprintln;

public function fprintl
"flag controlled debugging, printing of string list."
  input Flags.DebugFlag inFlag;
  input list<String> inStringLst;
  // annotation(__OpenModelica_EarlyInline=true);
algorithm
  _ := matchcontinue (inFlag,inStringLst)
    local
      String str;
      list<String> strlist;
    case (_,strlist)
      equation
        true = Flags.isSet(inFlag);
        str = stringAppendList(strlist);
        Print.printErrorBuf(str);
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end fprintl;

public function fcall2
"Flag controlled calling of the given function (2nd arg)"
  input Flags.DebugFlag inFlag;
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
  _ := matchcontinue (inFlag,func,inTypeA,inTypeB)
    local
      Type_a arg1;
      Type_b arg2;

    case (_,_,arg1,arg2)
      equation
        true = Flags.isSet(inFlag);
        func(arg1,arg2);
      then
        ();
    case (_,_,_,_) then ();
  end matchcontinue;
end fcall2;

public function fcall
"Flag controlled calling of the given function (2nd arg)"
  input Flags.DebugFlag inFlag;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := matchcontinue (inFlag,inFuncTypeTypeATo,inTypeA)
    local
      FuncTypeType_aTo func;
      Type_a str;
    case (_,func,str)
      equation
        true = Flags.isSet(inFlag);
        func(str);
      then
        ();
    case (_,_,_) then ();
  end matchcontinue;
end fcall;

public function fcall0
"Flag controlled calling of given function  (2nd arg)"
  input Flags.DebugFlag inFlag;
  input FuncTypeTo inFuncTypeTo;
  partial function FuncTypeTo
  end FuncTypeTo;
algorithm
  _ := matchcontinue (inFlag,inFuncTypeTo)
    local
      FuncTypeTo func;
    case (_,func)
      equation
        true = Flags.isSet(inFlag);
        func();
      then
        ();
    case (_,_) then ();
  end matchcontinue;
end fcall0;

public function fcallret0
"Flag controlled calling of given function (2nd arg).
  The passed function gets 0 arguments.
  The last parameter is returned if the given flag is not set."
  input Flags.DebugFlag inFlag;
  input FuncTypeToType_b inFuncTypeTypeB;
  input Type_b inTypeB;
  output Type_b outTypeB;
  partial function FuncTypeToType_b
    output Type_b outTypeB;
  end FuncTypeToType_b;
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeB := matchcontinue (inFlag,inFuncTypeTypeB,inTypeB)
    local
      Type_b res,def;
      FuncTypeToType_b func;
    case (_,func,def)
      equation
        true = Flags.isSet(inFlag);
        res = func();
      then
        res;
    case (_,_,def) then def;
  end matchcontinue;
end fcallret0;

public function fcallret1
"Flag controlled calling of given function (2nd arg).
  The passed function gets 1 arguments.
  The last parameter is returned if the given flag is not set."
  input Flags.DebugFlag inFlag;
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
  outTypeB := matchcontinue (inFlag,inFuncTypeTypeAToTypeB,inTypeA,inTypeB)
    local
      Type_b res,def;
      FuncTypeType_aToType_b func;
      Type_a arg;
    case (_,func,arg,def)
      equation
        true = Flags.isSet(inFlag);
        res = func(arg);
      then
        res;
    case (_,_,_,def) then def;
  end matchcontinue;
end fcallret1;

public function fcallret2
"Flag controlled calling of given function (2nd arg).
  The passed function gets 2 arguments.
  The last parameter is returned if the given flag is not set."
  input Flags.DebugFlag inFlag;
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
  res := matchcontinue (inFlag,func,arg1,arg2,default)
    case (_,_,_,_,_)
      equation
        true = Flags.isSet(inFlag);
        res = func(arg1,arg2);
      then
        res;
    case (_,_,_,_,_) then default;
  end matchcontinue;
end fcallret2;

public function fcallret3
"Flag controlled calling of given function (3nd arg).
  The passed function gets 3 arguments.
  The last parameter is returned if the given flag is not set."
  input Flags.DebugFlag inFlag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c arg3;
  input Type_d default;
  output Type_d res;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  res := matchcontinue (inFlag,func,arg1,arg2,arg3,default)
    case (_,_,_,_,_,_)
      equation
        true = Flags.isSet(inFlag);
        res = func(arg1,arg2,arg3);
      then res;
    else default;
  end matchcontinue;
end fcallret3;

public function bcallret0
"Boolean-controlled calling of given function (2nd arg).
  The passed function gets 0 arguments.
  The last parameter is returned if the boolean is false."
  input Boolean flag;
  input FuncTypeType_aToType_b func;
  input Type_b default;
  output Type_b res;
  partial function FuncTypeType_aToType_b
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
  replaceable type Type_b subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  res := match (flag,func,default)
    case (true,_,_)
      equation
        res = func();
      then res;
    else default;
  end match;
end bcallret0;

public function bcallret1
"Boolean-controlled calling of given function (2nd arg).
  The passed function gets 1 arguments.
  The last parameter is returned if the boolean is false."
  input Boolean flag;
  input FuncTypeType_aToType_b func;
  input Type_a arg;
  input Type_b default;
  output Type_b res;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
  end FuncTypeType_aToType_b;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  res := match (flag,func,arg,default)
    case (true,_,_,_)
      equation
        res = func(arg);
      then res;
    else default;
  end match;
end bcallret1;

public function bcallret1_2
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 1 arguments.
  The last two parameters are returned if the given flag is not set."
  input Boolean flag;
  input FuncA_BC func;
  input Type_a arg1;
  input Type_b default1;
  input Type_c default2;
  output Type_b res1;
  output Type_c res2;
  partial function FuncA_BC
    input Type_a inTypeA;
    output Type_b outTypeD;
    output Type_c outTypeE;
  end FuncA_BC;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  // Apparently cannot inline stuff with function pointers... annotation(__OpenModelica_EarlyInline = true);
algorithm
  (res1,res2) := match (flag,func,arg1,default1,default2)
    case (true,_,_,_,_)
      equation
        (res1,res2) = func(arg1);
      then (res1,res2);
    else (default1,default2);
  end match;
end bcallret1_2;

public function bcallret2
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 2 arguments.
  The last parameter is returned if the given flag is not set."
  input Boolean flag;
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
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  res := match (flag,func,arg1,arg2,default)
    case (true,_,_,_,_)
      equation
        res = func(arg1,arg2);
      then res;
    else default;
  end match;
end bcallret2;

public function bcallret2_2
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 2 arguments.
  The last two parameters are returned if the given flag is not set."
  input Boolean flag;
  input FuncAB_CD func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c default1;
  input Type_d default2;
  output Type_c res1;
  output Type_d res2;
  partial function FuncAB_CD
    input Type_a inTypeA;
    input Type_b inTypeB;
    output Type_c outTypeC;
    output Type_d outTypeD;
  end FuncAB_CD;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  // Apparently cannot inline stuff with function pointers... annotation(__OpenModelica_EarlyInline = true);
algorithm
  (res1,res2) := match (flag,func,arg1,arg2,default1,default2)
    case (true,_,_,_,_,_)
      equation
        (res1,res2) = func(arg1,arg2);
      then (res1,res2);
    else (default1,default2);
  end match;
end bcallret2_2;

public function bcallret3
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 3 arguments.
  The last parameter is returned if the given flag is not set."
  input Boolean flag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c arg3;
  input Type_d default;
  output Type_d res;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  res := match (flag,func,arg1,arg2,arg3,default)
    case (true,_,_,_,_,_)
      equation
        res = func(arg1,arg2,arg3);
      then res;
    else default;
  end match;
end bcallret3;

public function bcallret4
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 4 arguments.
  The last parameter is returned if the given flag is not set."
  input Boolean flag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c arg3;
  input Type_d arg4;
  input Type_e default;
  output Type_e res;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d d;
    output Type_e e;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  res := match (flag,func,arg1,arg2,arg3,arg4,default)
    case (true,_,_,_,_,_,_)
      equation
        res = func(arg1,arg2,arg3,arg4);
      then res;
    else default;
  end match;
end bcallret4;

public function bcallret5
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 5 arguments.
  The last parameter is returned if the given flag is not set."
  input Boolean flag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c arg3;
  input Type_d arg4;
  input Type_e arg5;
  input Type_g default;
  output Type_g res;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    output Type_g g;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_g subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  res := match (flag,func,arg1,arg2,arg3,arg4,arg5,default)
    case (true,_,_,_,_,_,_,_)
      equation
        res = func(arg1,arg2,arg3,arg4,arg5);
      then res;
    else default;
  end match;
end bcallret5;

public function bcallret6
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 6 arguments.
  The last parameter is returned if the given flag is not set."
  input Boolean flag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c arg3;
  input Type_d arg4;
  input Type_e arg5;
  input Type_f arg6;
  input Type_g default;
  output Type_g res;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
    input Type_e inTypeE;
    input Type_f f;
    output Type_g g;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  replaceable type Type_f subtypeof Any;
  replaceable type Type_g subtypeof Any;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  res := match (flag,func,arg1,arg2,arg3,arg4,arg5,arg6,default)
    case (true,_,_,_,_,_,_,_,_)
      equation
        res = func(arg1,arg2,arg3,arg4,arg5,arg6);
      then res;
    else default;
  end match;
end bcallret6;

public function bcallret3_2
"Boolean controlled calling of given function (2nd arg).
  The passed function gets 3 arguments.
  The last two parameters are returned if the given flag is not set."
  input Boolean flag;
  input FuncAB_C func;
  input Type_a arg1;
  input Type_b arg2;
  input Type_c arg3;
  input Type_d default1;
  input Type_e default2;
  output Type_d res1;
  output Type_e res2;
  partial function FuncAB_C
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    output Type_d outTypeD;
    output Type_e outTypeE;
  end FuncAB_C;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
  // Apparently cannot inline stuff with function pointers... annotation(__OpenModelica_EarlyInline = true);
algorithm
  (res1,res2) := match (flag,func,arg1,arg2,arg3,default1,default2)
    case (true,_,_,_,_,_,_)
      equation
        (res1,res2) = func(arg1,arg2,arg3);
      then (res1,res2);
    else (default1,default2);
  end match;
end bcallret3_2;

public function bcall
"bool controlled calling of function."
  input Boolean inBoolean;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := match (inBoolean,inFuncTypeTypeATo,inTypeA)
    local
      FuncTypeType_aTo func;
      Type_a str;
    case (true,func,str)
      equation
        func(str);
      then
        ();
    case (false,_,_) then ();
  end match;
end bcall;

public function bcall0
"bool controlled calling of function."
  input Boolean inBoolean;
  input Func func;
  partial function Func end Func;
algorithm
  _ := match (inBoolean,func)
    case (true,_)
      equation
        func();
      then ();
    case (false,_) then ();
  end match;
end bcall0;

public function bcall1
"bool controlled calling of function."
  input Boolean inBoolean;
  input FuncTypeType_aType_bTo func;
  input Type_a inTypeA;
  partial function FuncTypeType_aType_bTo
    input Type_a inTypeA;
  end FuncTypeType_aType_bTo;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := match (inBoolean,func,inTypeA)
    case (true,_,_)
      equation
        func(inTypeA);
      then
        ();
    case (false,_,_) then ();
  end match;
end bcall1;

public function bcall2
"bool controlled calling of function."
  input Boolean inBoolean;
  input FuncTypeType_aType_bTo func;
  input Type_a inTypeA;
  input Type_b inTypeB;
  partial function FuncTypeType_aType_bTo
    input Type_a inTypeA;
    input Type_b inTypeB;
  end FuncTypeType_aType_bTo;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  _ := match (inBoolean,func,inTypeA,inTypeB)
    case (true,_,_,_)
      equation
        func(inTypeA, inTypeB);
      then
        ();
    case (false,_,_,_) then ();
  end match;
end bcall2;

public function bcall3
"bool controlled calling of function."
  input Boolean inBoolean;
  input FuncTypeType_aType_bType_cTo fn;
  input Type_a inTypeA;
  input Type_b inTypeB;
  input Type_c inTypeC;
  partial function FuncTypeType_aType_bType_cTo
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
  end FuncTypeType_aType_bType_cTo;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  _ := match (inBoolean,fn,inTypeA,inTypeB,inTypeC)
    case (true,_,_,_,_)
      equation
        fn(inTypeA, inTypeB, inTypeC);
      then
        ();
    case (false,_,_,_,_) then ();
  end match;
end bcall3;

public function bcall4
"bool controlled calling of function."
  input Boolean inBoolean;
  input FuncTypeType_aType_bType_cType_dTo fn;
  input Type_a inTypeA;
  input Type_b inTypeB;
  input Type_c inTypeC;
  input Type_d inTypeD;
  partial function FuncTypeType_aType_bType_cType_dTo
    input Type_a inTypeA;
    input Type_b inTypeB;
    input Type_c inTypeC;
    input Type_d inTypeD;
  end FuncTypeType_aType_bType_cType_dTo;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
algorithm
  _ := match (inBoolean,fn,inTypeA,inTypeB,inTypeC,inTypeD)
    case (true,_,_,_,_,_)
      equation
        fn(inTypeA, inTypeB, inTypeC, inTypeD);
      then
        ();
    case (false,_,_,_,_,_) then ();
  end match;
end bcall4;

public function notfcall
"Call the given function (2nd arg)
  if the flag given in 1st arg is
  NOT set"
  input Flags.DebugFlag inFlag;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm
  _ := matchcontinue (inFlag,inFuncTypeTypeATo,inTypeA)
    local
      FuncTypeType_aTo func;
      Type_a str;
    case (_,func,str)
      equation
        false = Flags.isSet(inFlag);
        func(str);
      then
        ();
    case (_,_,_) then ();
  end matchcontinue;
end notfcall;

public function fprintList
"If flag is set, print the elements in
  the list, using the passed function."
  input Flags.DebugFlag inFlag;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aTo inFuncTypeTypeATo3;
  input String inString4;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _ := matchcontinue (inFlag,inTypeALst2,inFuncTypeTypeATo3,inString4)
    local
      String sep;
      list<Type_a> lst;
      FuncTypeType_aTo func;
    case (_,lst,func,sep)
      equation
        true = Flags.isSet(inFlag);
        printList(lst, func, sep);
      then
        ();
    case (_,_,_,_) then ();
  end matchcontinue;
end fprintList;

protected function printList
"If flag is set, print the elements in
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

public function execStat
  "Prints an execution stat on the format:
  *** %name% -> time: %time%, memory %memory%
  Where you provide name, and time is the time since the last call using this
  index (the clock is reset after each call). The memory is the total memory
  consumed by the compiler at this point in time.
  "
  input String name;
  input Integer clockIndex;
algorithm
  execStat2(Flags.isSet(Flags.EXEC_STAT),name,clockIndex);
end execStat;

protected function execStat2
  input Boolean cond;
  input String name;
  input Integer clockIndex;
algorithm
  _ := match (cond,name,clockIndex)
    local
      Real t;
      Integer used,allocated;
    case (false,_,_) then ();
    case (_,_,_)
      equation
        t = System.realtimeTock(clockIndex);
        (used,allocated) = System.getGCStatus();
        print("*** ");
        print(name);
        print(" -> time: ");
        print(realString(t));
        print(", memory: ");
        print(bytesToRealMBString(used));
        print("/");
        print(bytesToRealMBString(allocated));
        print(" MB (");
        print(realString(realMul(100.0,realDiv(intReal(used),intReal(allocated)))));
        print("%)\n");
        System.realtimeTick(clockIndex);
      then ();
  end match;
end execStat2;

protected function bytesToRealMBString
  input Integer bytes;
  output String str;
algorithm
  str := realString(realDiv(intReal(bytes),realMul(1024.0,1024.0)));
end bytesToRealMBString;

end Debug;

