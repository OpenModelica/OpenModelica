package Debug "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:	 Debug.mo
  module:      Debug
  description: debug printing
 
  RCS: $Id$
 
  Printing routines for debug output of strings. Also flag controlled
  printing. When flag controlled printing functions are called, printing is 
  done only if the given flag is among the flags given in the runtime 
  arguments, to +d-flag, i.e. if +d=inst,lookup is given in the command line,
  only calls containing these flags will actually print something, e.g.:
  fprint(\"inst\", \"Starting instantiation...\"). See runtime/rtopts.c for
  implementation of flag checking.
 
"

protected import RTOpts;
protected import Print;
protected import Util;

public function print "function: print
  author: PR
 
  This function is used for debug printing. 
"
  input String s;
algorithm 
  fprint("olddebug", s);
end print;

public function fprint "function: fprint
  author: LS
  
  Flag controlled debugging 
"
  input String inString1;
  input String inString2;
algorithm 
  _:=
  matchcontinue (inString1,inString2)
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

public function fprintln "function: fprintln
  
  Flag controlled debugging, printing with newline.
"
  input String inString1;
  input String inString2;
algorithm 
  _:=
  matchcontinue (inString1,inString2)
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

public function fprintl "function: fprintl
 
  flag controlled debugging, printing of string list.
"
  input String inString;
  input list<String> inStringLst;
algorithm 
  _:=
  matchcontinue (inString,inStringLst)
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

public function fcall "function: fcall
  
  Flag controlled calling of the given function (2nd arg) 
"
  input String inString;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inString,inFuncTypeTypeATo,inTypeA)
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

public function fcall0 "function: fcall0
 
  Flag controlled calling of given function  (2nd arg) 
"
  input String inString;
  input FuncTypeTo inFuncTypeTo;
  partial function FuncTypeTo
  end FuncTypeTo;
algorithm 
  _:=
  matchcontinue (inString,inFuncTypeTo)
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

public function fcallret "function: fcallret
 
  Flag controlled calling of given function (2nd arg).
  The passed functions return value is returned.
"
  input String inString;
  input FuncTypeType_aToType_b inFuncTypeTypeAToTypeB;
  input Type_a inTypeA;
  input Type_b inTypeB;
  output Type_b outTypeB;
  partial function FuncTypeType_aToType_b
    input Type_a inTypeA;
    output Type_b outTypeB;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aToType_b;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm 
  outTypeB:=
  matchcontinue (inString,inFuncTypeTypeAToTypeB,inTypeA,inTypeB)
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
end fcallret;

public function bcall "function: bcall
 
  bool controlled calling of function.
"
  input Boolean inBoolean;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inBoolean,inFuncTypeTypeATo,inTypeA)
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

public function bcall2 "function: bcall2
 
  bool controlled calling of function.
"
  input Boolean inBoolean;
  input FuncTypeType_aType_bTo inFuncTypeTypeATypeBTo;
  input Type_a inTypeA;
  input Type_b inTypeB;
  partial function FuncTypeType_aType_bTo
    input Type_a inTypeA;
    input Type_b inTypeB;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncTypeType_aType_bTo;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm 
  _:=
  matchcontinue (inBoolean,inFuncTypeTypeATypeBTo,inTypeA,inTypeB)
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

public function notfcall "function: notfcall
 
  Call the given function (2nd arg) if the flag given in 1st arg is 
  NOT set 
"
  input String inString;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input Type_a inTypeA;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
    replaceable type Type_a subtypeof Any;
  end FuncTypeType_aTo;
  replaceable type Type_a subtypeof Any;
algorithm 
  _:=
  matchcontinue (inString,inFuncTypeTypeATo,inTypeA)
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

public function fprintList "function: fprintList
 
   If flag is set, print the elements in the list, using the passed
  function.
"
  input String inString1;
  input list<Type_a> inTypeALst2;
  input FuncTypeType_aTo inFuncTypeTypeATo3;
  input String inString4;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm 
  _:=
  matchcontinue (inString1,inTypeALst2,inFuncTypeTypeATo3,inString4)
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

protected function printList "function: fprintList
 
   If flag is set, print the elements in the list, using the passed
  function.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm 
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
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

