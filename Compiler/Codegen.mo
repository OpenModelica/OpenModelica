package Codegen "
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

  
  file:	 Codegen.mo
  module:      Codegen
  description: Generate C code from DAE (Flat Modelica) for Modelica 
  functions. This code is compiled and linked to the simulation code or when
  functions are called from the interactive environment.
 
  Input: DAE
  Output: -   (generated code through Print module)
  Uses: Print Inst ModUtil Util
 
 
  RCS: $Id$
 

  -------------------------------------------------------------------------"

public import DAE;
public import Print;
public import Exp;
public import Absyn;

public 
type Ident = String;

public 
type ReturnType = String;

public 
type FunctionName = String;

public 
type ArgumentDeclaration = String;

public 
type VariableDeclaration = String;

public 
type InitStatement = String;

public 
type Statement = String;

public 
type CleanupStatement = String;

public 
type ReturnTypeStruct = list<String>;

public 
type Include = String;

public 
type Lib = String;

public 
uniontype CFunction
  record CFUNCTION
    ReturnType returnType;
    FunctionName functionName;
    ReturnTypeStruct returnTypeStruct;
    list<ArgumentDeclaration> argumentDeclarationLst;
    list<VariableDeclaration> variableDeclarationLst;
    list<InitStatement> initStatementLst;
    list<Statement> statementLst;
    list<CleanupStatement> cleanupStatementLst;
  end CFUNCTION;

  record CEXTFUNCTION
    ReturnType returnType;
    FunctionName functionName;
    ReturnTypeStruct returnTypeStruct;
    list<ArgumentDeclaration> argumentDeclarationLst;
    list<Include> includeLst;
    list<Lib> libLst;
  end CEXTFUNCTION;

end CFunction;

public uniontype Context
	record CONTEXT
	  	CodeContext codeContext "The context code is generated in, either simulation or function";
	  	ExpContext expContext "The context expressions are generated in, either normal or external calls";
	  	LoopContext loopContext = LoopContext.NO_LOOP "The chain of loops containing the generated statement";
	end CONTEXT;
	end Context;

public 
uniontype CodeContext "Which context is the code generated in."
  record SIMULATION "when generating simulation code" end SIMULATION;

  record FUNCTION "when generating function code" end FUNCTION;

end CodeContext;

public
uniontype ExpContext 
  record NORMAL "Normal expression generation" end NORMAL;
  record EXP_EXTERNAL "for expressions in external calls" end EXP_EXTERNAL;
end ExpContext;

public
uniontype LoopContext
  record NO_LOOP end NO_LOOP;
  record IN_FOR_LOOP LoopContext parent; end IN_FOR_LOOP;
  record IN_WHILE_LOOP LoopContext parent; end IN_WHILE_LOOP;
end LoopContext;

protected import Debug;
protected import Algorithm;
protected import ClassInf;
protected import ModUtil;
protected import Types;
protected import Util;
protected import Inst;
protected import Interactive;
protected import System;
protected import Error;

public constant CFunction cEmptyFunction=CFUNCTION("","",{},{},{},{},{},{}) " empty function ";

public constant Context
   funContext = CONTEXT(FUNCTION(),NORMAL(),NO_LOOP()),
   simContext = CONTEXT(SIMULATION(),NORMAL(),NO_LOOP()),
   extContext = CONTEXT(SIMULATION(),EXP_EXTERNAL(),NO_LOOP());

public function cMakeFunction "function: cMakeFunction
 
  Helper function to generate_function. Creates a C-function from a 
  ReturnType, FunctionName, ReturnTypeStruct and a list of 
  ArgumentDeclaration\'s
"
  input ReturnType inReturnType;
  input FunctionName inFunctionName;
  input ReturnTypeStruct inReturnTypeStruct;
  input list<ArgumentDeclaration> inArgumentDeclarationLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inReturnType,inFunctionName,inReturnTypeStruct,inArgumentDeclarationLst)
    local
      Lib rt,fn;
      list<Lib> rts,ads;
    case (rt,fn,rts,ads) then CFUNCTION(rt,fn,rts,ads,{},{},{},{}); 
  end matchcontinue;
end cMakeFunction;

protected function cMakeFunctionDecl "function: cMakeFunctionDecl
 
  Helper function to generate_function. Generates a C function declaration.
  I.e. without body of the function.
"
  input ReturnType inReturnType;
  input FunctionName inFunctionName;
  input ReturnTypeStruct inReturnTypeStruct;
  input list<ArgumentDeclaration> inArgumentDeclarationLst;
  input list<Include> inIncludeLst;
  input list<Lib> inLibLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inReturnType,inFunctionName,inReturnTypeStruct,inArgumentDeclarationLst,inIncludeLst,inLibLst)
    local
      Lib rt,fn;
      list<Lib> rts,ads,incl,libs;
    case (rt,fn,rts,ads,incl,libs) then CEXTFUNCTION(rt,fn,rts,ads,incl,libs); 
  end matchcontinue;
end cMakeFunctionDecl;

public function cAddVariables "function: cAddVariables
  
  Add local variable declarations  to a CFunction.
"
  input CFunction inCFunction;
  input list<VariableDeclaration> inVariableDeclarationLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunction,inVariableDeclarationLst)
    local
      list<Lib> vd_1,rts,ads,vd,is,st,cl,nvd;
      Lib rt,fn;
    case (CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ads,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl),nvd)
      equation 
        vd_1 = listAppend(vd, nvd);
      then
        CFUNCTION(rt,fn,rts,ads,vd_1,is,st,cl);
  end matchcontinue;
end cAddVariables;

public function cAddInits "function: cAddInits
  
  Add initialization statements to a CFunction. They will be ommitted before
  the actual code of the function but after the local variable declarations.
"
  input CFunction inCFunction;
  input list<InitStatement> inInitStatementLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunction,inInitStatementLst)
    local
      list<Lib> is_1,rts,ads,vd,is,st,cl,nis;
      Lib rt,fn;
    case (CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ads,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl),nis)
      equation 
        is_1 = listAppend(is, nis);
      then
        CFUNCTION(rt,fn,rts,ads,vd,is_1,st,cl);
  end matchcontinue;
end cAddInits;

public function cPrependStatements "function: c_add_statements
  
  Prepends statements to a CFunction.
"
  input CFunction inCFunction;
  input list<Statement> inStatementLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunction,inStatementLst)
    local
      list<Lib> st_1,rts,ads,vd,is,st,cl,nst;
      Lib rt,fn;
    case (CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ads,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl),nst)
      equation 
        st_1 = listAppend(nst, st);
      then
        CFUNCTION(rt,fn,rts,ads,vd,is,st_1,cl);
  end matchcontinue;
end cPrependStatements;

public function cAddStatements "function: cAddStatements
  
  Adds statements to a CFunction.
"
  input CFunction inCFunction;
  input list<Statement> inStatementLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunction,inStatementLst)
    local
      list<Lib> st_1,rts,ads,vd,is,st,cl,nst;
      Lib rt,fn;
    case (CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ads,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl),nst)
      equation 
        st_1 = listAppend(st, nst);
      then
        CFUNCTION(rt,fn,rts,ads,vd,is,st_1,cl);
  end matchcontinue;
end cAddStatements;

public function cAddCleanups "function: cAddCleanups
  
  Add \"cleanup\" statements to a CFunction. They will be ommited last, before
  the return statement of the function.
"
  input CFunction inCFunction;
  input list<CleanupStatement> inCleanupStatementLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunction,inCleanupStatementLst)
    local
      list<Lib> cl_1,rts,ads,vd,is,st,cl,ncl;
      Lib rt,fn;
    case (CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ads,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl),ncl)
      equation 
        cl_1 = listAppend(cl, ncl);
      then
        CFUNCTION(rt,fn,rts,ads,vd,is,st,cl_1);
  end matchcontinue;
end cAddCleanups;

public function cMergeFns "function: cMergeFns
 
  Takes a list of functions and merges them together.
  The function name, returntype and argument lists are taken from the 
  first CFunction in the list.
"
  input list<CFunction> inCFunctionLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunctionLst)
    local
      CFunction cfn2,cfn,cfn1;
      list<CFunction> r;
    case {} then cEmptyFunction; 
    case (cfn1 :: r)
      equation 
        cfn2 = cMergeFns(r);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
  end matchcontinue;
end cMergeFns;

protected function cMergeFn "function: cMergeFn
 
  Merges two functions into one. The function name, returntype and 
  argument lists are taken from the first CFunction.
"
  input CFunction inCFunction1;
  input CFunction inCFunction2;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunction1,inCFunction2)
    local
      list<Lib> vd,is,st,cl,rts,ad,vd1,is1,st1,cl1,vd2,is2,st2,cl2;
      Lib rt,fn;
    case (CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ad,variableDeclarationLst = vd1,initStatementLst = is1,statementLst = st1,cleanupStatementLst = cl1),CFUNCTION(variableDeclarationLst = vd2,initStatementLst = is2,statementLst = st2,cleanupStatementLst = cl2))
      equation 
        vd = listAppend(vd1, vd2);
        is = listAppend(is1, is2);
        st = listAppend(st1, st2);
        cl = listAppend(cl1, cl2);
      then
        CFUNCTION(rt,fn,rts,ad,vd,is,st,cl);
  end matchcontinue;
end cMergeFn;

protected function cMoveStatementsToInits "function: cMoveStatementsToInits
 
  Moves all statements of the body to initialization statements.
"
  input CFunction inCFunction;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inCFunction)
    local
      list<Lib> is_1,rts,ad,vd,is,st,cl;
      Lib rt,fn;
    case CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ad,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl)
      equation 
        is_1 = listAppend(is, st);
      then
        CFUNCTION(rt,fn,rts,ad,vd,is_1,{},cl);
  end matchcontinue;
end cMoveStatementsToInits;

public function cPrintFunctionsStr "function: cPrintFunctionsStr 
 
  Prints CFunction list to a string
"
  input list<CFunction> fs;
  output String res;
  Lib s;
algorithm 
  s := Print.getString();
  Print.clearBuf();
  cPrintFunctions(fs);
  res := Print.getString();
  Print.clearBuf();
  Print.printBuf(s);
end cPrintFunctionsStr;

protected function cPrintFunctions "function: cPrintFunctions
 
  Prints CFunction list to Print buffer.
"
  input list<CFunction> inCFunctionLst;
algorithm 
  _:=
  matchcontinue (inCFunctionLst)
    local
      CFunction f;
      list<CFunction> r;
    case {} then (); 
    case (f :: r)
      equation 
        cPrintFunction(f);
        cPrintFunctions(r);
      then
        ();
  end matchcontinue;
end cPrintFunctions;

public function cPrintDeclarations " 
Prints only the local variable declarations of a function to a string"
input CFunction inCFunction;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inCFunction)
    local
      Integer i5;
      Lib str,res,rt,fn;
      list<Lib> rts,ad,vd,is,st,cl;
    case CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ad,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl)
      equation 
        (i5,str) = cPrintIndentedListStr(vd, 2);
        res = stringAppend(str, "\n");
      then
        res;
  end matchcontinue;
end cPrintDeclarations;


public function cPrintStatements "function: cPrintStatements
 
  Only prints the statements of a function to a string
"
  input CFunction inCFunction;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inCFunction)
    local
      Integer i5;
      Lib str,res,rt,fn;
      list<Lib> rts,ad,vd,is,st,cl;
    case CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ad,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl)
      equation 
        (i5,str) = cPrintIndentedListStr(st, 2);
        res = stringAppend(str, "\n");
      then
        res;
  end matchcontinue;
end cPrintStatements;

protected function cPrintFunction "function: cPrintFunction
 
  Prints a CFunction to Print buffer.
"
  input CFunction inCFunction;
algorithm 
  _:=
  matchcontinue (inCFunction)
    local
      Lib args_str,stmt_str,rt,fn;
      Integer i0,i2,i3,i4,i5,i6,i7;
      list<Lib> rts,ad,vd,is,st,cl,ads;
    case CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ad,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl)
      equation 
        args_str = Util.stringDelimitList(ad, ", ");
        stmt_str = Util.stringAppendList({rt," ",fn,"(",args_str,")\n{"});
        i0 = 0;
        i2 = cPrintIndented(stmt_str, i0) "	c_print_indented_list (rts,i0) => i1 & Print.printBuf \"\\n\" &" ;
        Print.printBuf("\n");
        i3 = cPrintIndentedList(vd, i2);
        Print.printBuf("\n");
        i4 = cPrintIndentedList(is, i3);
        Print.printBuf("\n");
        i5 = cPrintIndentedList(st, i4);
        Print.printBuf("\n");
        i6 = cPrintIndentedList(cl, i5);
        Print.printBuf("\n");
        i7 = cPrintIndented("}", i6);
        Print.printBuf("\n");
      then
        ();
    case CEXTFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ads)
      equation 
        args_str = Util.stringDelimitList(ads, ", ");
        stmt_str = Util.stringAppendList({"extern ",rt," ",fn,"(",args_str,");\n"});
        i0 = 0;
        i2 = cPrintIndented(stmt_str, i0) "	c_print_indented_list (rts,i0) => i1 & Print.printBuf \"\\n\" &" ;
        Print.printBuf("\n");
      then
        ();
    case _
      equation 
        Debug.fprint("failtrace", "# c_print_function_failed\n");
      then
        ();
  end matchcontinue;
end cPrintFunction;

protected function cPrintFunctionIncludes "function: cPrintFunctionIncludes
 
  Prints the function declaration, i.e. the header information
  of a CFunction list to the Print buffer.
"
  input list<CFunction> inCFunctionLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inCFunctionLst)
    local
      list<Lib> libs1,libs2,libs;
      CFunction f;
      list<CFunction> r;
    case {} then {};  /* libs */ 
    case (f :: r)
      equation 
        libs1 = cPrintFunctionInclude(f);
        libs2 = cPrintFunctionIncludes(r);
        libs = listAppend(libs1, libs2);
      then
        libs;
  end matchcontinue;
end cPrintFunctionIncludes;

protected function cPrintFunctionInclude "function: cPrintFunctionIncludes
 
  Prints the includes for a function.
"
  input CFunction inCFunction;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inCFunction)
    local
      Lib str;
      list<Lib> includes,libs;
    case (CEXTFUNCTION(includeLst = includes,libLst = libs)) /* libs */ 
      equation 
        Print.printBuf("#ifdef __cplusplus\n");
        Print.printBuf("extern \"C\" {\n");
        Print.printBuf("#endif\n");
        str = Util.stringDelimitList(includes, "\n");
        Print.printBuf(str);
        Print.printBuf("\n");
        Print.printBuf("#ifdef __cplusplus\n");
        Print.printBuf("}\n");
        Print.printBuf("#endif\n");
      then
        libs;
    case (_) then {}; 
  end matchcontinue;
end cPrintFunctionInclude;

protected function cPrintFunctionHeaders "function: cPrintFunctionHeaders
 
  Prints the function declaration, i.e. the header information
  of a CFunction list to the Print buffer.
"
  input list<CFunction> inCFunctionLst;
algorithm 
  _:=
  matchcontinue (inCFunctionLst)
    local
      CFunction f;
      list<CFunction> r;
    case {} then (); 
    case (f :: r)
      equation 
        cPrintFunctionHeader(f);
        cPrintFunctionHeaders(r);
      then
        ();
  end matchcontinue;
end cPrintFunctionHeaders;

protected function cPrintFunctionHeader "function: cPrintFunctionHeaders
 
  Prints the function declaration, i.e. the header information
  of a CFunction to the Print buffer.
"
  input CFunction inCFunction;
algorithm 
  _:=
  matchcontinue (inCFunction)
    local
      Lib args_str,stmt_str,rt,fn;
      Integer i0,i1,i2;
      list<Lib> rts,ad,vd,is,st,cl,ads;
    case CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ad,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl)
      equation 
        args_str = Util.stringDelimitList(ad, ", ");
        stmt_str = Util.stringAppendList({rt," ",fn,"(",args_str,");"});
        i0 = 0;
        i1 = cPrintIndentedList(rts, i0);
        Print.printBuf("\n");
        i2 = cPrintIndented(stmt_str, i1);
        Print.printBuf("\n");
      then
        ();
    case CEXTFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ads)
      equation 
        args_str = Util.stringDelimitList(ads, ", ");
        stmt_str = Util.stringAppendList({"extern ",rt," ",fn,"(",args_str,");\n"});
        i0 = 0;
        i1 = cPrintIndentedList(rts, i0);
        Print.printBuf("\n");
        i2 = cPrintIndented(stmt_str, i1);
        Print.printBuf("\n");
      then
        ();
    case _
      equation 
        Debug.fprint("failtrace", "# c_print_function_header failed\n");
      then
        ();
  end matchcontinue;
end cPrintFunctionHeader;

protected function cPrintIndentedList "function: cPrintIndentedList
 
  Helper function. prints a list of strings indented with a number
  of indentation levels.
"
  input list<String> inStringLst;
  input Integer inInteger;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inStringLst,inInteger)
    local
      Integer i,i_1,i_2;
      Lib f;
      list<Lib> r;
    case ({},i) then i;  /* indentation level updated indentation level */ 
    case ((f :: r),i)
      equation 
        i_1 = cPrintIndented(f, i);
        Print.printBuf("\n");
        i_2 = cPrintIndentedList(r, i_1);
      then
        i_2;
  end matchcontinue;
end cPrintIndentedList;

protected function cPrintIndented "function: cPrintIndented
 
  Prints a string adding an indentation level. If the string
  contains C-code that opens or closes a  indentation level, 
  the indentation level is updated accordingly.
"
  input String str;
  input Integer i;
  output Integer i_1;
  list<Lib> strl;
  Integer i_1,it;
algorithm 
  strl := string_list_string_char(str);
  i_1 := cNextLevel(strl, i);
  it := cThisLevel(strl, i);
  cPrintIndent(it);
  Print.printBuf(str);
end cPrintIndented;

protected function cPrintIndentedListStr "function: cPrintIndentedListStr
 
  Helper function. 
"
  input list<String> inStringLst;
  input Integer inInteger;
  output Integer outInteger;
  output String outString;
algorithm 
  (outInteger,outString):=
  matchcontinue (inStringLst,inInteger)
    local
      Integer i,i_1,i_2;
      Lib s1,s2,res,f;
      list<Lib> r;
    case ({},i) then (i,"");  /* indentation level updated indentation level */ 
    case ((f :: r),i)
      equation 
        (i_1,s1) = cPrintIndentedStr(f, i);
        (i_2,s2) = cPrintIndentedListStr(r, i_1);
        res = Util.stringAppendList({s1,"\n",s2});
      then
        (i_2,res);
  end matchcontinue;
end cPrintIndentedListStr;

protected function cPrintIndentedStr "function: cPrintIndentedStr
 
  See c_print_indented
"
  input String inString;
  input Integer inInteger;
  output Integer outInteger;
  output String outString;
algorithm 
  (outInteger,outString):=
  matchcontinue (inString,inInteger)
    local
      list<Lib> strl;
      Integer i_1,it,i;
      Lib it_str,res,str;
    case (str,i)
      equation 
        strl = string_list_string_char(str);
        i_1 = cNextLevel(strl, i);
        it = cThisLevel(strl, i);
        it_str = cPrintIndentStr(it);
        res = stringAppend(it_str, str);
      then
        (i_1,res);
  end matchcontinue;
end cPrintIndentedStr;

protected function cNextLevel "function cNextLevel
 
  Helper function to c_print_indented. 
"
  input list<String> inStringLst;
  input Integer inInteger;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inStringLst,inInteger)
    local
      Integer i,i_1,i_2;
      Lib f;
      list<Lib> r;
    case ({},i) then i; 
    case ((f :: r),i) /* { */ 
      equation 
        "{" = string_char_list_string({f});
        i_1 = i + 2;
        i_2 = cNextLevel(r, i_1);
      then
        i_2;
    case ((f :: r),i) /* } */ 
      equation 
        "}" = string_char_list_string({f});
        i_1 = i - 2;
        i_2 = cNextLevel(r, i_1);
      then
        i_2;
    case ((_ :: r),i)
      equation 
        i_1 = cNextLevel(r, i);
      then
        i_1;
  end matchcontinue;
end cNextLevel;

protected function cThisLevel "function c_next_level
 
  Helper function to c_print_indented.
"
  input list<String> inStringLst;
  input Integer inInteger;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inStringLst,inInteger)
    local
      Lib f;
      Integer i;
    case ((f :: _),_)
      equation 
        "#" = string_char_list_string({f});
      then
        0;
    case ((f :: _),i)
      equation 
        "}" = string_char_list_string({f});
      then
        i - 2;
    case (_,i) then i; 
  end matchcontinue;
end cThisLevel;

protected function cPrintIndent "function cPrintIndent
 
  Helper function to c_print_indented. 
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
        cPrintIndent(i_1);
      then
        ();
  end matchcontinue;
end cPrintIndent;

protected function cPrintIndentStr "function cPrintIndentStr
 
  Helper function to c_print_indented_str. 
"
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger)
    local
      list<Lib> lst;
      Lib res;
      Integer i;
    case 0 then ""; 
    case i
      equation 
        lst = Util.listFill(" ", i);
        res = Util.stringAppendList(lst);
      then
        res;
  end matchcontinue;
end cPrintIndentStr;

public function generateFunctions "function: generateFunctions
 
  Generates code for all functions in a DAE and prints on
  Print buffer. A list of libs for the external functions is returned.
"
  input DAE.DAElist inDAElist;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inDAElist)
    local
      list<Lib> libs;
      DAE.DAElist dae;
      list<DAE.Element> elist;
    case ((dae as DAE.DAE(elementLst = elist))) /* libs */ 
      local String s;
      equation 
         Print.printBuf("#ifdef __cplusplus\n");
        Print.printBuf("extern \"C\" {\n");
        Print.printBuf("#endif\n");
        libs = generateFunctionHeaders(dae);
        generateFunctionBodies(dae);
        Print.printBuf("\n");
        Print.printBuf("#ifdef __cplusplus\n");
        Print.printBuf("}\n");
        Print.printBuf("#endif\n");
     
      then
        libs;
    case _
      equation 
        Debug.fprint("failtrace", "# generate_functions failed\n");
      then
        fail();
  end matchcontinue;
end generateFunctions;

public function generateFunctionBodies "function: generateFunctionBodies
 
  Generates the function bodies of a DAE list.
"
  input DAE.DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local
      list<CFunction> cfns;
      list<DAE.Element> elist;
    case DAE.DAE(elementLst = elist)
      equation 
        Debug.fprintln("cgtr", "generate_function_bodies");
        cfns = generateFunctionsElist(elist);
        Print.printBuf("\n/* body part */\n");
        cPrintFunctions(cfns);
        Print.printBuf("\n");
      then
        ();
    case _
      equation 
        Debug.fprint("failtrace", "# generate_function_bodies failed\n");
      then
        fail();
  end matchcontinue;
end generateFunctionBodies;

public function generateFunctionHeaders "function: generateFunctionHeaders
 
  Generates the headers of the functions in a DAE list.
"
  input DAE.DAElist inDAElist;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inDAElist)
    local
      list<CFunction> cfns;
      list<Lib> libs;
      list<DAE.Element> elist;
    case DAE.DAE(elementLst = elist)
      equation 
        Debug.fprintln("cgtr", "generate_function_headers");
        cfns = generateFunctionsElist(elist);
        Print.printBuf("/* header part */\n");
        Print.printBuf("#include \"modelica.h\"\n");
        libs = cPrintFunctionIncludes(cfns) ;
        cPrintFunctionHeaders(cfns);
        Print.printBuf("\n");
      then
        libs;
    case _
      equation 
        Debug.fprint("failtrace", "# generate_function_headers failed\n");
      then
        fail();
  end matchcontinue;
end generateFunctionHeaders;

protected function generateFunctionsElist "function: generateFunctionsElist
 
  Helper function. Generates code from the Elements of a DAE.
"
  input list<DAE.Element> els;
  output list<CFunction> cfns;
  list<DAE.Element> fns;
algorithm 
  Debug.fprintln("cgtr", "generate_functions_elist");
  Debug.fprintln("cgtrdumpdae", "Dumping DAE:");
  Debug.fcall("cgtrdumpdae", DAE.dump2, DAE.DAE(els));
  fns := Util.listFilter(els, DAE.isFunction);
  cfns := generateFunctionsElist2(fns);
end generateFunctionsElist;

protected function generateFunctionsElist2 "function: generateFunctionsElist2
  
  Helper function to generate_functions_elist.
"
  input list<DAE.Element> inDAEElementLst;
  output list<CFunction> outCFunctionLst;
algorithm 
  outCFunctionLst:=
  matchcontinue (inDAEElementLst)
    local
      list<CFunction> cfns1,cfns2,cfns;
      DAE.Element f;
      list<DAE.Element> rest;
    case {}
      equation 
        Debug.fprintln("cgtr", "generate_functions_elist2");
      then
        {};
    case (f :: rest)
      equation 
        Debug.fprintln("cgtr", "generate_functions_elist2");
        cfns1 = generateFunction(f);
        cfns2 = generateFunctionsElist2(rest);
        cfns = listAppend(cfns1, cfns2);
      then
        cfns;
  end matchcontinue;
end generateFunctionsElist2;

protected function generateFunction "function: generateFunction
 
  Generates code for a DAE.FUNCTION. This results in two CFunctions, 
   one declaration and one definition. There are two rules of this function, 
  one for normal Modelica functions and one for external Modelica functions.
"
  input DAE.Element inElement;
  output list<CFunction> outCFunctionLst;
algorithm 
  outCFunctionLst:=
  matchcontinue (inElement)
    local
      Lib fn_name_str,retstr,extfnname,lang,retstructtype,extfnname_1,n;
      list<DAE.Element> outvars,invars,dae,bivars,orgdae,daelist;
      list<Lib> struct_strs,arg_strs,includes,libs;
      CFunction head_cfn,body_cfn,cfn,rcw_fn,func_decl,ext_decl;
      Absyn.Path fpath;
      list<tuple<Lib, tuple<Types.TType, Option<Absyn.Path>>>> args;
      tuple<Types.TType, Option<Absyn.Path>> restype,tp;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extretarg;
      Option<Absyn.Annotation> ann;
      DAE.ExternalDecl extdecl;
      list<CFunction> cfns;
      DAE.Element comp;
    case DAE.FUNCTION(path = fpath,dAElist = DAE.DAE(elementLst = dae),type_ = (Types.T_FUNCTION(funcArg = args,funcResultType = restype),_)) /* Modelica functions External functions */ 
      equation 
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        Debug.fprintl("cgtr", {"generating function ",fn_name_str,"\n"});
        Debug.fprintln("cgtrdumpdae3", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae3", DAE.dump2, DAE.DAE(dae));
        outvars = DAE.getOutputVars(dae);
        invars = DAE.getInputVars(dae);
        struct_strs = generateResultStruct(outvars, fpath);
        retstr = generateReturnType(fpath);
        arg_strs = Util.listMap(args, generateFunctionArg);
        head_cfn = cMakeFunction(retstr, fn_name_str, struct_strs, arg_strs);
        body_cfn = generateFunctionBody(fpath, dae, restype);
        cfn = cMergeFn(head_cfn, body_cfn);
        rcw_fn = generateReadCallWrite(fn_name_str, outvars, retstr, invars);
      then
        {cfn,rcw_fn};
    case DAE.EXTFUNCTION(path = fpath,dAElist = DAE.DAE(elementLst = orgdae),type_ = (tp as (Types.T_FUNCTION(funcArg = args,funcResultType = restype),_)),externalDecl = extdecl) /* External functions */ 
      equation 
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        Debug.fprintl("cgtr", {"generating external function ",fn_name_str,"\n"});
        DAE.EXTERNALDECL(ident = extfnname,external_ = extargs,parameters = extretarg,returnType = lang,language = ann) = extdecl;
        Debug.fprintln("cgtrdumpdae1", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae1", DAE.dump2, DAE.DAE(orgdae));
        dae = Inst.initVarsModelicaOutput(orgdae);
        Debug.fprintln("cgtrdumpdae2", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae2", DAE.dump2, DAE.DAE(dae));
        outvars = DAE.getOutputVars(dae);
        invars = DAE.getInputVars(dae);
        bivars = DAE.getBidirVars(dae);
        struct_strs = generateResultStruct(outvars, fpath);
        retstructtype = generateReturnType(fpath);
        retstr = generateExtReturnType(extretarg);
        extfnname_1 = generateExtFunctionName(extfnname, lang);
        arg_strs = generateExtFunctionArgs(extargs, lang);
        (includes,libs) = generateExtFunctionIncludes(ann);
        func_decl = cMakeFunctionDecl(retstr, extfnname_1, struct_strs, arg_strs, includes, libs);
        rcw_fn = generateReadCallWriteExternal(fn_name_str, outvars, retstructtype, invars, extdecl, 
          bivars);
        ext_decl = generateExternalWrapperCall(fn_name_str, outvars, retstructtype, invars, extdecl, 
          bivars, tp);
      then
        {func_decl,rcw_fn,ext_decl};
    case DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = daelist))
      equation 
        cfns = generateFunctionsElist(daelist);
      then
        cfns;
    case comp
      equation 
        Debug.fprint("failtrace", "-generate_function failed\n");
      then
        fail();
  end matchcontinue;
end generateFunction;

public function generateExtFunctionIncludes "function: generateExtFunctionIncludes
 
  Collects the includes and libs for an external function by
  investigating the annotation of an external function.
"
  input Option<Absyn.Annotation> inAbsynAnnotationOption;
  output list<String> outStringLst1;
  output list<String> outStringLst2;
algorithm 
  (outStringLst1,outStringLst2):=
  matchcontinue (inAbsynAnnotationOption)
    local
      list<Lib> libs,includes;
      list<Absyn.ElementArg> eltarg;
    case (SOME(Absyn.ANNOTATION(eltarg)))
      equation 
        libs = generateExtFunctionIncludesLibstr(eltarg);
        includes = generateExtFunctionIncludesIncludestr(eltarg);
      then
        (includes,libs);
    case (NONE) then ({},{}); 
  end matchcontinue;
end generateExtFunctionIncludes;

protected function generateExtFunctionIncludesLibstr
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      Lib lib;
      list<Absyn.ElementArg> eltarg;
    case (eltarg)
      equation 
        Absyn.CLASSMOD(_,SOME(Absyn.STRING(lib))) = Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Library",{})) "System.stringReplace(lib,\"\\\"\",\"\"\") => lib\'" ;
      then
        {lib};
    case (_) then {}; 
  end matchcontinue;
end generateExtFunctionIncludesLibstr;

protected function generateExtFunctionIncludesIncludestr
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      Lib inc,inc_1;
      list<Absyn.ElementArg> eltarg;
    case (eltarg)
      equation 
        Absyn.CLASSMOD(_,SOME(Absyn.STRING(inc))) = Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Include",{}));
        inc_1 = System.stringReplace(inc, "\\\"", "\"");
      then
        {inc_1};
    case (eltarg) then {}; 
  end matchcontinue;
end generateExtFunctionIncludesIncludestr;

protected function generateExtFunctionName "function: generateExtFunctionName
 
  Generates the function name for external functions. 
  Fortran functions have the underscore \'_\' suffix.
"
  input String inString1;
  input String inString2;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString1,inString2)
    local Lib name,name_1,ext_lang;
    case (name,"C") then name; 
    case (name,"FORTRAN 77")
      equation 
        name_1 = stringAppend(name, "_");
      then
        name_1;
    case (_,ext_lang)
      equation 
        Error.addMessage(Error.UNKNOWN_EXTERNAL_LANGUAGE, {ext_lang});
      then
        fail();
  end matchcontinue;
end generateExtFunctionName;

protected function generateResultStruct "function generate_results_struct
 
  All Modelica functions translates to a C function returning all 
  Modelica ouput parameters in a struct. This function generates that struct.
"
  input list<DAE.Element> outvars;
  input Absyn.Path fpath;
  output list<String> strs;
  Lib ptname,first_row,last_row;
  list<Lib> var_strs,var_names,defs,var_strs_1;
algorithm 
  ptname := generateReturnType(fpath);
  (var_strs,var_names) := generateReturnDecls(outvars,1);
  defs := generateReturnDefs(ptname, var_names, 1);
  var_strs_1 := indentStrings(var_strs);
  first_row := Util.stringAppendList({"typedef struct ",ptname,"_s"});
  last_row := Util.stringAppendList({"} ",ptname,";"});
  strs := Util.listFlatten({defs,{first_row,"{"},var_strs_1,{last_row}});
end generateResultStruct;

protected function generateReturnDefs "function: generateReturnDefs
 
  Helper function to generate_result_struct. Creates defines used
  in the declaration of the return struct.
"
  input String inString;
  input list<String> inStringLst;
  input Integer inInteger;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inString,inStringLst,inInteger)
    local
      Lib i_str,f_1,tn,f;
      Integer i_1,i;
      list<Lib> r_1,r;
    case (_,{},_) then {}; 
    case (tn,(f :: r),i)
      equation 
        i_str = intString(i);
        f_1 = Util.stringAppendList({"#define ",tn,"_",i_str," ",f});
        i_1 = i + 1;
        r_1 = generateReturnDefs(tn, r, i_1);
      then
        (f_1 :: r_1);
  end matchcontinue;
end generateReturnDefs;

protected function generateReturnDecls "function: generateReturnDecls
  
  Helper function to generate_result_struct. Generates the variable names of the result structure.
"
  input list<DAE.Element> inDAEElementLst;
  input Integer i;
  output list<String> outStringLst1;
  output list<String> outStringLst2;
algorithm 
  (outStringLst1,outStringLst2):=
  matchcontinue (inDAEElementLst,i)
    local
      list<Lib> rs,rd;
      DAE.Element first;
      list<DAE.Element> rest;
      Lib fs,fd;
    case ({},i) then ({},{}); 
    case (first :: rest,i)
      equation 
        ("",_) = generateReturnDecl(first,i);
        (rs,rd) = generateReturnDecls(rest,i);
      then
        (rs,rd);
    case (first :: rest,i)
      equation 
        (fs,fd) = generateReturnDecl(first,i);
        (rs,rd) = generateReturnDecls(rest,i+1);
      then
        ((fs :: rs),(fd :: rd));
  end matchcontinue;
end generateReturnDecls;

protected function tmpprintinit "function: tmpprintinit
 
  Helper function to generate_return_decl.
"
  input Option<Exp.Exp> inExpExpOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExpExpOption)
    local
      Lib str,str1;
      Exp.Exp e;
    case NONE then ""; 
    case SOME(e)
      equation 
        str = Exp.printExpStr(e);
        str1 = Util.stringAppendList({" /* ",str," */"});
      then
        str1;
  end matchcontinue;
end tmpprintinit;

protected function generateReturnDecl "function: generateReturnDecl
 
  Helper function to generate_return_decls
"
  input DAE.Element inElement;
  input Integer i;
  output String outString1;
  output String outString2;
algorithm 
  (outString1,outString2):=
  matchcontinue (inElement,i)
    local
      Boolean is_a;
      Lib typ_str,id_str,dims_str,decl_str_1,expstr,decl_str,iStr;
      list<Lib> dim_strs;
      DAE.Element var;
      Exp.ComponentRef id;
      DAE.Type typ;
      Option<Exp.Exp> initopt,start;
      list<Exp.Subscript> inst_dims;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case ((var as DAE.VAR(componentRef = id,varible = DAE.VARIABLE(),variable = DAE.OUTPUT(),input_ = typ,one = initopt,binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),i)
      equation 
        is_a = isArray(var);
        typ_str = daeTypeStr(typ, is_a);
        iStr = intString(i);
        id_str = Util.stringAppendList({"targ",iStr});
        dim_strs = Util.listMap(inst_dims, dimString);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        decl_str_1 = Util.stringAppendList({typ_str," ",id_str,";"," /* [",dims_str,"] */"});
        expstr = tmpprintinit(initopt);
        decl_str = stringAppend(decl_str_1, expstr);
      then
        (decl_str,id_str);
    case (_,_) then ("",""); 
  end matchcontinue;
end generateReturnDecl;

protected function isArray "function: isArray
  
  Returns true if variable is part of an array.
"
  input DAE.Element inElement;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inElement)
    local
      DAE.Element el;
      Exp.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      Option<Exp.Exp> st;
      DAE.Flow fl;
      list<Absyn.Path> cl;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case ((el as DAE.VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,binding = {},dimension = st,value = fl,flow_ = cl,variableAttributesOption = dae_var_attr,absynCommentOption = comment))) /* 
  axiom	is_array DAE.VAR(cr,vk,vd,ty,_,{},st,fl,cl) => false
  axiom	is_array DAE.VAR(cr,vk,vd,ty,_,_::_,st,fl,cl) => true
 */ 
      equation 
        Debug.fcall("isarrdb", DAE.dump2, DAE.DAE({el}));
      then
        false;
    case ((el as DAE.VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,binding = (_ :: _),dimension = st,value = fl,flow_ = cl,variableAttributesOption = dae_var_attr,absynCommentOption = comment)))
      equation 
        Debug.fcall("isarrdb", DAE.dump2, DAE.DAE({el}));
      then
        true;
    case el
      equation 
        Debug.fprint("failtrace", "-is_array failed\n");
      then
        fail();
  end matchcontinue;
end isArray;

protected function daeExpType "function: daeExpType
  
  Translates a DAE.Type to an Exp.Type.
"
  input DAE.Type inType;
  output Exp.Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    case DAE.INT() then Exp.INT(); 
    case DAE.REAL() then Exp.REAL(); 
    case DAE.STRING() then Exp.STRING(); 
    case DAE.BOOL() then Exp.BOOL(); 
    case DAE.ENUM() then Exp.ENUM(); 
    case _ then Exp.OTHER(); 
  end matchcontinue;
end daeExpType;

protected function daeTypeStr "function: daeTypeStr
  
  Convert a DAE.Type to a string. The boolean indicates whether the type
  is an array or not.
"
  input DAE.Type t;
  input Boolean a;
  output String str;
  Exp.Type t_1;
algorithm 
  t_1 := daeExpType(t);
  str := expTypeStr(t_1, a);
end daeTypeStr;

protected function expShortTypeStr "function: expShortTypeStr
 
  Translates and Exp.Type to a string, using a \"short\" typename.
"
  input Exp.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      Lib res;
      Exp.Type t;
    case Exp.INT() then "integer"; 
    case Exp.REAL() then "real"; 
    case Exp.STRING() then "string"; 
    case Exp.BOOL() then "boolean"; 
    case Exp.OTHER() then "complex"; // Only use is currently for external objects. Perhaps in future also records.
    case Exp.ENUM() then "ENUM_NOT_IMPLEMENTED"; 
    case Exp.T_ARRAY(ty = t)
      equation 
        res = expShortTypeStr(t);
      then
        res;
  end matchcontinue;
end expShortTypeStr;

protected function expTypeStr "function: exp_short_type_str
 
  Translates and Exp.Type to a string. The second argument is true
  if an array type of the given type should be generated. 
"
  input Exp.Type inType;
  input Boolean inBoolean;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType,inBoolean)
    local
      Lib tstr,str;
      Exp.Type t;
    case (t,false) /* array */ 
      equation 
        tstr = expShortTypeStr(t);
        str = stringAppend("modelica_", tstr);
      then
        str;
    case (t,true)
      equation 
        tstr = expShortTypeStr(t);
        str = stringAppend(tstr, "_array");
      then
        str;
  end matchcontinue;
end expTypeStr;

protected function generateType "function: generateType
 
  Generates code for a Type.
"
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      Lib ty_str;
      list<tuple<Types.TType, Option<Absyn.Path>>> tys;
      tuple<Types.TType, Option<Absyn.Path>> arrayty,ty;
      list<Integer> dims;
    case ((Types.T_TUPLE(tupleType = tys),_))
      equation 
        Debug.fprintln("cgtr", "generate_type");
        ty_str = generateTupleType(tys);
      then
        ty_str;
    case ((tys as (Types.T_ARRAY(arrayDim = _),_)))
      local tuple<Types.TType, Option<Absyn.Path>> tys;
      equation 
        Debug.fprintln("cgtr", "generate_type");
        (arrayty,dims) = Types.flattenArrayType(tys);
        ty_str = generateArrayType(arrayty, dims);
      then
        ty_str;
    case ((Types.T_INTEGER(varLstInt = _),_)) then "modelica_integer"; 
    case ((Types.T_REAL(varLstReal = _),_)) then "modelica_real"; 
    case ((Types.T_STRING(varLstString = _),_)) then "modelica_string"; 
    case ((Types.T_BOOL(varLstBool = _),_)) then "modelica_boolean"; 
    case ty
      equation 
        Debug.fprint("failtrace", "#-- generate_type failed\n");
      then
        fail();
  end matchcontinue;
end generateType;

protected function generateTypeExternal "function: generateTypeExternal
  
  Generates Code for an external type.
"
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      Lib str;
      Types.ArrayDim dim;
      tuple<Types.TType, Option<Absyn.Path>> ty;
    case ((Types.T_INTEGER(varLstInt = _),_)) then "int"; 
    case ((Types.T_REAL(varLstReal = _),_)) then "double"; 
    case ((Types.T_STRING(varLstString = _),_)) then "const char*"; 
    case ((Types.T_BOOL(varLstBool = _),_)) then "int"; 
    case ((Types.T_ARRAY(arrayDim = dim,arrayType = ty),_))
      equation 
        str = generateTypeExternal(ty);
      then
        str;

        // External objects are stored in void pointer
    case ((Types.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),_)) then "void *";
    case ty
      equation 
        Debug.fprint("failtrace", "#-- generate_type_external failed\n");
      then
        fail();
  end matchcontinue;
end generateTypeExternal;

protected function generateTypeInternalNamepart "function: generateTypeInternalNamepart
  
  Generates code for a Type only returning the typename of the basic types.
"
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    case ((Types.T_INTEGER(varLstInt = _),_)) then "integer"; 
    case ((Types.T_REAL(varLstReal = _),_)) then "real"; 
    case ((Types.T_STRING(varLstString = _),_)) then "string"; 
    case ((Types.T_BOOL(varLstBool = _),_)) then "boolean"; 
    case ((Types.T_ENUM(),_)) then "T_ENUM_NOT_IMPLEMENTED"; 
  end matchcontinue;
end generateTypeInternalNamepart;

protected function generateReturnType "function: generateReturnType
 
  Generates the return type name of a function given the function name.
"
  input Absyn.Path fpath;
  output String res;
  Lib fstr;
algorithm 
  fstr := generateFunctionName(fpath);
  res := stringAppend(fstr, "_rettype");
end generateReturnType;

protected function generateArrayType "function: generateArrayType
 
  Generates code for the array type given a  basic type and a list 
  of dimensions.
"
  input Types.Type ty;
  input list<Integer> dims;
  output String str;
algorithm 
  str := arrayTypeString(ty);
end generateArrayType;

protected function generateArrayReturnType "function: generate_array_type
 
  Generates code for an array type  as return type given a  basic 
  type and a list of dimensions.
"
  input Types.Type ty;
  input list<Integer> dims;
  output String ty_str;
algorithm 
  ty_str := arrayTypeString(ty);
end generateArrayReturnType;

protected function generateTupleType "function: generateTupleType
 
  Generate code for a tuple type.
"
  input list<Types.Type> inTypesTypeLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inTypesTypeLst)
    local
      Lib str,str_1,str_2,str_3;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      list<tuple<Types.TType, Option<Absyn.Path>>> tys;
    case {ty}
      equation 
        Debug.fprintln("cgtr", "generate_tuple_type_1");
        str = generateSimpleType(ty);
      then
        str;
    case ((ty :: tys))
      equation 
        Debug.fprintln("cgtr", "generate_tuple_type_2");
        str = generateSimpleType(ty);
        str_1 = generateTupleType(tys);
        str_2 = stringAppend(str, str_1);
        str_3 = stringAppend("struct ", str_2);
      then
        str_3;
  end matchcontinue;
end generateTupleType;

protected function generateSimpleType "function: generateSimpleType
  
  Helper function to generate_tuple_type. Generates code for a non-tuple
  type as element of a tuple.
"
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      Lib n_1,n_2,n,t_str;
      tuple<Types.TType, Option<Absyn.Path>> t_1,t,ty;
    case ((Types.T_INTEGER(varLstInt = _),_)) then "modelica_integer"; 
    case ((Types.T_REAL(varLstReal = _),_)) then "modelica_real"; 
    case ((Types.T_STRING(varLstString = _),_)) then "modelica_string"; 
    case ((Types.T_BOOL(varLstBool = _),_)) then "modelica_boolean"; 
    case ((Types.T_COMPLEX(complexClassType = ClassInf.RECORD(string = n)),_))
      equation 
        n_1 = stringAppend("const ", n);
        n_2 = stringAppend(n_1, "&");
      then
        n_2;
    case ((Types.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),_))
      then
        "void *";
    case ((t as (Types.T_ARRAY(arrayDim = _),_)))
      equation 
        t_1 = Types.arrayElementType(t);
        t_str = arrayTypeString(t_1);
      then
        t_str;
    case ty
      equation 
        Debug.fprint("failtrace", "#--generate_simple_type failed\n");
      then
        fail();
  end matchcontinue;
end generateSimpleType;

protected function arrayTypeString "function: arrayTypeString
 
  Returns the type string of an array of the basic type passed as 
  argument.
"
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    case ((Types.T_INTEGER(varLstInt = _),_)) then "integer_array"; 
    case ((Types.T_REAL(varLstReal = _),_)) then "real_array"; 
    case ((Types.T_STRING(varLstString = _),_)) then "string_array"; 
    case ((Types.T_BOOL(varLstBool = _),_)) then "boolean_array"; 
  end matchcontinue;
end arrayTypeString;

protected function generateFunctionName "function: generateFunctionName
 
  Generates the name of a function by replacing dots with underscores.
"
  input Absyn.Path fpath;
  output String fstr;
algorithm 
  fstr := ModUtil.pathString2(fpath, "_");
end generateFunctionName;

protected function generateExtFunctionArgs "function: generateExtFunctionArgs
  
  Generates Code for external function arguments.
  input string is language, e.g. \"C\" or \"FORTRAN 77\" 
"
  input list<DAE.ExtArg> inDAEExtArgLst;
  input String inString;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inDAEExtArgLst,inString)
    local
      list<Lib> arg_strs;
      list<DAE.ExtArg> extargs;
      Lib lang;
    case (extargs,"C")
      equation 
        arg_strs = Util.listMap(extargs, generateExtFunctionArg);
      then
        arg_strs;
    case (extargs,"FORTRAN 77")
      equation 
        arg_strs = Util.listMap(extargs, generateExtFunctionArgF77);
      then
        arg_strs;
    case (_,lang)
      equation 
        Debug.fprint("failtrace", "-generate_ext_function_args failed");
      then
        fail();
  end matchcontinue;
end generateExtFunctionArgs;

protected function generateFunctionArg "function: generateFunctionArgs
 
  Generates code from a function argument.
"
  input Types.FuncArg inFuncArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inFuncArg)
    local
      Lib str,str_1,str_2,name;
      tuple<Types.TType, Option<Absyn.Path>> ty;
    case ((name,ty))
      equation 
        str = generateTupleType({ty});
        str_1 = stringAppend(str, " ");
        str_2 = stringAppend(str_1, name);
      then
        str_2;
  end matchcontinue;
end generateFunctionArg;

protected function generateExtArgType "function: generateExtArgType
 
  Helper function to generate_ext_function_arg.
  Generates code for the type of an external function argument.
"
  input Types.Attributes inAttributes;
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAttributes,inType)
    local
      Lib str,resstr,tystr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
    case (Types.ATTR(direction = Absyn.INPUT()),ty)
      equation 
        false = Types.isArray(ty);
        str = generateTypeExternal(ty);
      then
        str;
    case (Types.ATTR(direction = Absyn.INPUT()),ty)
      equation 
        true = Types.isArray(ty);
        str = generateTypeExternal(ty);
        resstr = Util.stringAppendList({"const ",str," *"});
      then
        resstr;
    case (Types.ATTR(direction = Absyn.OUTPUT()),ty)
      equation 
        tystr = generateTypeExternal(ty);
        str = stringAppend(tystr, "*");
      then
        str;
    case (Types.ATTR(direction = Absyn.BIDIR()),ty)
      equation 
        tystr = generateTypeExternal(ty);
        str = stringAppend(tystr, "*");
      then
        str;
    case (_,ty)
      equation 
        str = generateTypeExternal(ty);
      then
        str;
    case (_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_arg_type failed\n");
      then
        fail();
  end matchcontinue;
end generateExtArgType;

protected function generateExtFunctionArg "function: generateExtFunctionArg
 
  Generates Code for the arguments of an external function.
"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      Lib tystr,name,res,e_str;
      Exp.ComponentRef cref,cr;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Exp.Exp exp;
    case DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation 
        tystr = generateExtArgType(attr, ty);
        (name,_) = compRefCstr(cref);
        res = Util.stringAppendList({tystr," ",name});
      then
        res;
    case DAE.EXTARGEXP(exp = exp,type_ = ty)
      equation 
        res = generateTypeExternal(ty);
      then
        res;
    case DAE.EXTARGSIZE(componentRef = cr,exp = exp)
      equation 
        (name,_) = compRefCstr(cr);
        e_str = Exp.printExpStr(exp);
        res = Util.stringAppendList({"size_t ",name,"_",e_str});
      then
        res;
    case (_)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_function_arg failed\n");
      then
        fail();
  end matchcontinue;
end generateExtFunctionArg;

protected function generateExtArgTypeF77 "function: generateExtArgTypeF77
 
  Helper function to generate_ext_function_arg.
  Generates code for the type of an external function argument on fortran.
  format.
"
  input Types.Attributes inAttributes;
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAttributes,inType)
    local
      Lib str,resstr,tystr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Types.Attributes attr;
    case (Types.ATTR(direction = Absyn.INPUT()),ty)
      equation 
        str = generateTypeExternal(ty);
        resstr = Util.stringAppendList({"const ",str," *"});
      then
        resstr;
    case (Types.ATTR(direction = Absyn.OUTPUT()),ty)
      equation 
        tystr = generateTypeExternal(ty);
        str = stringAppend(tystr, "*");
      then
        str;
    case ((attr as Types.ATTR(direction = Absyn.BIDIR())),ty)
      equation 
        str = generateExtArgType(attr, ty);
      then
        str;
    case ((attr as Types.ATTR(direction = Absyn.BIDIR())),ty)
      equation 
        str = generateExtArgType(attr, ty);
      then
        str;
    case (attr,ty)
      equation 
        str = generateExtArgType(attr, ty);
      then
        str;
    case (_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_arg_type_f77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtArgTypeF77;

protected function generateExtFunctionArgF77 "function: generateExtFunctionArgF77
 
  Generates Code for the arguments of an external function on fortran. 
  format.
"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      Lib tystr,name,res;
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      DAE.ExtArg arg;
    case DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation 
        tystr = generateExtArgTypeF77(attr, ty);
        (name,_) = compRefCstr(cref);
        res = Util.stringAppendList({tystr," ",name});
      then
        res;
    case ((arg as DAE.EXTARGEXP(exp = _)))
      equation 
        res = generateExtFunctionArg(arg);
      then
        res;
    case DAE.EXTARGSIZE(componentRef = _) then "int const *"; 
    case (_)
      equation 
        Debug.fprint("failtrace", "-generate_ext_function_arg_f77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtFunctionArgF77;

protected function generateExtReturnType "function: generateExtReturnType
 
  Generates code for the return type of an external function.
"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      Lib res;
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
    case DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation 
        res = generateTypeExternal(ty);
      then
        res;
    case DAE.NOEXTARG() then "void"; 
    case _
      equation 
        Debug.fprint("failtrace", "-generate_ext_return_type failed\n");
      then
        fail();
  end matchcontinue;
end generateExtReturnType;

protected function generateExtReturnTypeF77 "function: generate_ext_return_type
 
  Generates code for the return type of an external function.
"
  input DAE.ExtArg arg;
  output String str;
algorithm 
  str := generateExtReturnType(arg);
end generateExtReturnTypeF77;

protected function generateFunctionBody "function: generateFunctionBody
 
  Generates code for the body of a Modelica function.
"
  input Absyn.Path fpath;
  input list<DAE.Element> dae;
  input Types.Type restype;
  output CFunction cfn;
  Integer tnr,tnr_ret_1,tnr_ret,tnr_mem,tnr_var,tnr_alg,tnr_res;
  Lib ret_type_str,ret_decl,ret_var,ret_stmt,mem_decl,mem_var,mem_stmt1,mem_stmt2;
  list<DAE.Element> outvars;
  CFunction out_fn,mem_fn_1,mem_fn,var_fn,alg_fn,res_var_fn,cfn_1,cfn_2,cfn_3;
algorithm 
  Debug.fprintln("cgtr", "generate_function_body");
  tnr := 1;
  ret_type_str := generateReturnType(fpath);
  (ret_decl,ret_var,tnr_ret_1) := generateTempDecl(ret_type_str, tnr);
  ret_stmt := Util.stringAppendList({"return ",ret_var,";"});
  outvars := DAE.getOutputVars(dae);
  (out_fn,tnr_ret) := generateAllocOutvars(outvars, ret_decl, ret_var, 1,tnr_ret_1, funContext);
  (mem_decl,mem_var,tnr_mem) := generateTempDecl("state", tnr_ret);
  mem_stmt1 := Util.stringAppendList({mem_var," = get_memory_state();"});
  mem_stmt2 := Util.stringAppendList({"restore_memory_state(",mem_var,");"});
  mem_fn_1 := cAddVariables(out_fn, {mem_decl});
  mem_fn := cAddInits(mem_fn_1, {mem_stmt1});
  (var_fn,tnr_var) := generateVars(dae, isVarQ, tnr_mem, funContext);
  (alg_fn,tnr_alg) := generateAlgorithms(dae, tnr_var, funContext);
  (res_var_fn,tnr_res) := generateResultVars(dae, ret_var, 1,tnr_alg, funContext);
  cfn_1 := cMergeFn(mem_fn, var_fn);
  cfn_2 := cMergeFn(cfn_1, alg_fn);
  cfn_2 := cAddStatements(cfn_2, {"", "_return:"});
  cfn_3 := cMergeFn(cfn_2, res_var_fn);
  cfn := cAddCleanups(cfn_3, {mem_stmt2,ret_stmt});
end generateFunctionBody;

protected function generateAllocOutvars "function: generateAllocOutvars
 
  Generates code for the allocation of output parameters of the function.
"
  input list<DAE.Element> inDAEElementLst1;
  input String inString2;
  input String inString3;
  input Integer i "nth tuple elt";
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst1,inString2,inString3,i,inInteger4,inContext5)
    local
      Lib rv,rd;
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn,cfn1,cfn2;
      DAE.Element var;
      Exp.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type t;
      Option<Exp.Exp> e,start;
      list<Exp.Subscript> id;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<DAE.Element> r;
    case ({},"",rv,i,tnr,context) then (cEmptyFunction,tnr); 
    case ({},rd,rv,i,tnr,context)
      equation 
        cfn = cAddVariables(cEmptyFunction, {rd});
      then
        (cfn,tnr);
    case (((var as DAE.VAR(componentRef = cr,varible = vk,variable = vd,input_ = t,one = e,binding = id,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)) :: r),rd,rv,i,tnr,context)
      equation 
        (cfn1,tnr1) = generateAllocOutvar(var, rv, i,tnr, context);
        (cfn2,tnr2) = generateAllocOutvars(r, rd, rv, i+1,tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
    case ((_ :: r),rd,rv,i,tnr,context)
      equation 
        (cfn2,tnr2) = generateAllocOutvars(r, rd, rv, i,tnr, context);
      then
        (cfn2,tnr2);
  end matchcontinue;
end generateAllocOutvars;

protected function generateAllocOutvar "function: generateAllocOutvar
 
  Helper function to generate_alloc_outvars.
"
  input DAE.Element inElement;
  input String inString;
  input Integer i "nth tuple elt";
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElement,inString,i,inInteger,inContext)
    local
      Boolean is_a,emptypre;
      Lib typ_str,cref_str1,cref_str2,cref_str,ndims_str,dims_str,alloc_str,prefix;
      CFunction cfn1,cfn1_1,cfn_1,cfn;
      list<Lib> dim_strs;
      Integer tnr1,ndims,tnr;
      DAE.Element var;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      Option<Exp.Exp> e,start;
      list<Exp.Subscript> inst_dims;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Context context;
      String iStr;
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = e,binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),prefix,i,tnr,context)
      equation 
        is_a = isArray(var);
        iStr = intString(i);
        typ_str = daeTypeStr(typ, is_a);
        (cref_str1,_) = compRefCstr(id);
        cref_str2 = Util.stringAppendList({prefix,".","targ",iStr});
        emptypre = Util.isEmptyString(prefix);
        cref_str = Util.if_(emptypre, cref_str1, cref_str2);
        (cfn1,dim_strs,tnr1) = generateSizeSubscripts(cref_str, inst_dims, tnr, context);
        cfn1_1 = cMoveStatementsToInits(cfn1);
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        alloc_str = Util.stringAppendList(
          {"alloc_",typ_str,"(&",cref_str,", ",ndims_str,", ",
          dims_str,");"});
        cfn_1 = cAddInits(cfn1_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_1, cfn1_1);
      then
        (cfn,tnr1);
    case (e,_,_,tnr,context)
      local DAE.Element e;
      equation 
        failure(DAE.isVar(e));
      then
        (cEmptyFunction,tnr);
  end matchcontinue;
end generateAllocOutvar;

protected function generateAllocOutvarsExt "function: generate_alloc_outvar_ext
 
  Helper function to generate_alloc_outvars, for external functions.
"
  input list<DAE.Element> inDAEElementLst;
  input String inString;
  input Integer i "nth tuple elt";
  input Integer inInteger;
  input DAE.ExternalDecl inExternalDecl;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inString,i,inInteger,inExternalDecl)
    local
      Lib rv;
      Integer tnr,tnr1,tnr2;
      DAE.ExternalDecl extdecl;
      CFunction cfn1,cfn2,cfn;
      DAE.Element var;
      Exp.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type t;
      Option<Exp.Exp> e,start;
      list<Exp.Subscript> id;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<DAE.Element> r;
    case ({},rv,i,tnr,extdecl) then (cEmptyFunction,tnr); 
    case (((var as DAE.VAR(componentRef = cr,varible = vk,variable = vd,input_ = t,one = e,binding = id,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)) :: r),rv,i,tnr,extdecl)
      equation 
        DAE.EXTERNALDECL(returnType = "C") = extdecl;
        (cfn1,tnr1) = generateAllocOutvar(var, rv, i,tnr, funContext);
        (cfn2,tnr2) = generateAllocOutvarsExt(r, rv,i+1,tnr1, extdecl);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
    case (((var as DAE.VAR(componentRef = cr,varible = vk,variable = vd,input_ = t,one = e,binding = id,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)) :: r),rv,i,tnr,extdecl)
      equation 
        DAE.EXTERNALDECL(returnType = "FORTRAN 77") = extdecl;
        (cfn1,tnr1) = generateAllocOutvarF77(var, rv,i,tnr);
        (cfn2,tnr2) = generateAllocOutvarsExt(r, rv, i+1,tnr1, extdecl);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
    case ((_ :: r),rv,i,tnr,extdecl)
      equation 
        (cfn2,tnr2) = generateAllocOutvarsExt(r, rv, i, tnr, extdecl);
      then
        (cfn2,tnr2);
  end matchcontinue;
end generateAllocOutvarsExt;

protected function generateAllocOutvarF77 "function: generateAllocOutvarF77
 
  Helper function to generate_alloc_outvars, for fortran code.
"
  input DAE.Element inElement;
  input String inString;
  input Integer i "nth tuple elt";
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElement,inString,i,inInteger)
    local
      Boolean is_a,emptypre;
      Lib typ_str,cref_str1,cref_str2,cref_str,ndims_str,dims_str,alloc_str,prefix,iStr;
      CFunction cfn1,cfn1_1,cfn_1,cfn;
      list<Lib> dim_strs;
      Integer tnr1,ndims,tnr;
      DAE.Element var;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      Option<Exp.Exp> e,start;
      list<Exp.Subscript> inst_dims;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = e,binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),prefix,i,tnr)
      equation 
        is_a = isArray(var);
        typ_str = daeTypeStr(typ, is_a);
        emptypre = stringEqual(prefix, "");
        (cref_str1,_) = compRefCstr(id);
				iStr = intString(i);        
        cref_str2 = Util.stringAppendList({prefix,".","targ",iStr});
        cref_str = Util.if_(emptypre, cref_str1, cref_str2);
        (cfn1,dim_strs,tnr1) = generateSizeSubscripts(cref_str, inst_dims, tnr, funContext);
        cfn1_1 = cMoveStatementsToInits(cfn1);
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        alloc_str = Util.stringAppendList(
          {"alloc_",typ_str,"(&",cref_str,", ",ndims_str,", ",
          dims_str,");"});
        cfn_1 = cAddInits(cfn1_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_1, cfn1_1);
      then
        (cfn,tnr1);
    case (e,_,_,tnr)
      local DAE.Element e;
      equation 
        failure(DAE.isVar(e));
      then
        (cEmptyFunction,tnr);
  end matchcontinue;
end generateAllocOutvarF77;

protected function generateSizeSubscripts "function: generateSizeSubscripts
 
  Generates code for calculating the subscripts of a variable.
"
  input String inString;
  input list<Exp.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output list<String> outStringLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outStringLst,outInteger):=
  matchcontinue (inString,inExpSubscriptLst,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      Lib var1,id;
      list<Lib> vars2;
      Exp.Exp e;
      list<Exp.Subscript> r,subs;
    case (_,{},tnr,context) then (cEmptyFunction,{},tnr); 
    case (id,(Exp.INDEX(exp = e) :: r),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e, tnr, context);
        (cfn2,vars2,tnr2) = generateSizeSubscripts(id, r, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,(var1 :: vars2),tnr2);
    case (id,subs,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_size_subscripts failed\n");
      then
        fail();
  end matchcontinue;
end generateSizeSubscripts;

protected function generateAllocArrayF77 "function: generateAllocArrayF77
 
  Generates code for allocating an array in fortran.
"
  input String inString;
  input Types.Type inType;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inString,inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> elty,ty;
      list<Integer> dims;
      list<Exp.Subscript> dimsubs;
      Integer tnr,tnr1,ndims;
      CFunction cfn1,cfn1_1,cfn;
      list<Lib> dim_strs;
      Lib typ_str,ndims_str,dims_str,alloc_str,crefstr;
    case (crefstr,ty)
      equation 
        true = Types.isArray(ty);
        (elty,dims) = Types.flattenArrayType(ty);
        dimsubs = Exp.intSubscripts(dims);
        tnr = tick();
        (cfn1,dim_strs,tnr1) = generateSizeSubscripts(crefstr, dimsubs, tnr, funContext);
        cfn1_1 = cMoveStatementsToInits(cfn1);
        typ_str = generateType(ty);
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        alloc_str = Util.stringAppendList(
          {"alloc_",typ_str,"(&",crefstr,", ",ndims_str,", ",dims_str,
          ");"});
        cfn = cAddInits(cfn1_1, {alloc_str});
      then
        cfn;
    case (_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_alloc_array_f77 failed\n");
      then
        fail();
  end matchcontinue;
end generateAllocArrayF77;

protected function generateAlgorithms "function: generateAlgorithms
 
  Generates code for all algorithms in the DAE.Element list
"
  input list<DAE.Element> inDAEElementLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inInteger,inContext)
    local
      list<DAE.Element> algs,els;
      CFunction cfn;
      Integer tnr_1,tnr;
      Context context;
    case (els,tnr,context)
      equation 
        algs = Util.listFilter(els, DAE.isAlgorithm);
        (cfn,tnr_1) = generateAlgorithms2(algs, tnr, context);
      then
        (cfn,tnr_1);
  end matchcontinue;
end generateAlgorithms;

protected function generateAlgorithms2 "function: generateAlgorithms2
 
  Helper function to generate_algorithms
"
  input list<DAE.Element> inDAEElementLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      DAE.Element first;
      list<DAE.Element> rest;
    case ({},tnr,context) then (cEmptyFunction,tnr); 
    case ((first :: rest),tnr,context)
      equation 
        (cfn1,tnr1) = generateAlgorithm(first, tnr, context);
        (cfn2,tnr2) = generateAlgorithms2(rest, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
  end matchcontinue;
end generateAlgorithms2;

public function generateAlgorithm "function: generateAlgorithm
 
  Generates C-code for an DAE.Element that is ALGORTIHM
  The tab indent number is passed as argument.
"
  input DAE.Element inElement;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElement,inInteger,inContext)
    local
      CFunction cfn;
      Integer tnr_1,tnr;
      list<Algorithm.Statement> stmts;
      Context context;
    case (DAE.ALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts)),tnr,context)
      equation 
        (cfn,tnr_1) = generateAlgorithmStatements(stmts, tnr, context);
      then
        (cfn,tnr_1);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_algorithm failed\n");
      then
        fail();
  end matchcontinue;
end generateAlgorithm;

protected function generateAlgorithmStatements "function: generateAlgorithmStatements
 
  Generates code for a list of Algorithm.Statement.
"
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inAlgorithmStatementLst,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      Algorithm.Statement f;
      list<Algorithm.Statement> r;
    case ({},tnr,context) then (cEmptyFunction,tnr); 
    case ((f :: r),tnr,context)
      equation 
        (cfn1,tnr1) = generateAlgorithmStatement(f, tnr, context);
        (cfn2,tnr2) = generateAlgorithmStatements(r, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
  end matchcontinue;
end generateAlgorithmStatements;

protected function generateAlgorithmStatement "function : generateAlgorithmStatement
 
   returns:
   CFunction | Code
  int       | next temporary number 
"
  input Algorithm.Statement inStatement;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inStatement,inInteger,inContext)
    local
      CFunction cfn1,cfn2,cfn_1,cfn,cfn2_1,cfn1_1,cfn3,cfn4,cfn3_1,cfn3_2,cfn4_1;
      Lib var1,var2,stmt,cref_str,type_str,if_begin,sdecl,svar,dvar,ident_type_str,short_type,rdecl1,rvar1,rdecl2,rvar2,rdecl3,rvar3,e1var,e2var,e3var,r_stmt,for_begin,def_beg1,mem_begin,mem_end,for_end,def_end1,i,tdecl,tvar,idecl,ivar,array_type_str,evar,stmt_array,stmt_scalar,crit_stmt;
      Integer tnr1,tnr2,tnr,tnr3,tnr_1,tnr2_2,tnr2_3,tnr4,tnr_2;
      Exp.Type typ,t;
      Exp.ComponentRef cref;
      Exp.Exp exp,e,e1,e2;
      Context context;
      list<Exp.Subscript> subs;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Else else_;
      Boolean a;
    case (Algorithm.ASSIGN(type_ = typ,componentRef = cref,exp = exp),tnr,context)
      equation 
        Debug.fprintln("cgas", "generate_algorithm_statement");
        (cfn1,var1,tnr1) = generateExpression(exp, tnr, context);
        (cfn2,var2,tnr2) = generateScalarLhsCref(typ, cref, tnr1, context);
        stmt = Util.stringAppendList({var2," = ",var1,";"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tnr2);
    case (Algorithm.ASSIGN_ARR(type_ = typ,componentRef = cref,exp = exp),tnr,context)
      local 
        Boolean sim;
        String memStr;
      equation 
        (cref_str,{}) = compRefCstr(cref);
        sim = isSimulationContext(context);
        memStr = Util.if_(sim,"_mem","");
        (cfn1,var1,tnr1) = generateExpression(exp, tnr, context);
        type_str = expTypeStr(typ, true);
        stmt = Util.stringAppendList({"copy_",type_str,"_data",memStr,"(&",var1,", &",cref_str,");"});
        cfn2 = cAddStatements(cfn1, {stmt});
      then
        (cfn2,tnr1);
    case (Algorithm.ASSIGN_ARR(type_ = typ,componentRef = cref,exp = exp),tnr,context)
      equation 
        (cref_str,(subs as (_ :: _))) = compRefCstr(cref);
        (cfn1,var1,tnr1) = generateExpression(exp, tnr, context);
        (cfn2,var2,tnr2) = generateIndexSpec(subs, tnr1, context);
        type_str = expTypeStr(typ, true);
        stmt = Util.stringAppendList(
          {"indexed_assign_",type_str,"(&",var1,", &",cref_str,", &",
          var2,");"});
        cfn2_1 = cAddStatements(cfn2, {stmt});
        cfn = cMergeFn(cfn1, cfn2_1);
      then
        (cfn,tnr2);
    case (Algorithm.IF(exp = e,statementLst = then_,else_ = else_),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e, tnr, context);
        if_begin = Util.stringAppendList({"if (",var1,") {"});
        cfn1_1 = cAddStatements(cfn1, {if_begin});
        (cfn2,tnr2) = generateAlgorithmStatements(then_, tnr1, context);
        cfn2_1 = cAddStatements(cfn2, {"}"});
        (cfn3,tnr3) = generateElse(else_, tnr2, context);
        cfn = cMergeFns({cfn1_1,cfn2_1,cfn3});
      then
        (cfn,tnr3);
    case (Algorithm.FOR(type_ = t,boolean = a,ident = i,exp = e,statementLst = stmts),tnr,
                        context as CONTEXT(codeContext,expContext,loopContext))
      local CodeContext codeContext;
            ExpContext expContext;
            LoopContext loopContext;
      equation 
        true = Exp.isRange(e);
        (sdecl,svar,tnr_1) = generateTempDecl("state", tnr);
        (_,dvar,tnr1) = generateTempDecl("", tnr_1);
        ident_type_str = expTypeStr(t, a);
        short_type = expShortTypeStr(t);
        (rdecl1,rvar1,tnr2_2) = generateTempDecl(ident_type_str, tnr1);
        (rdecl2,rvar2,tnr2_3) = generateTempDecl(ident_type_str, tnr2_2);
        (rdecl3,rvar3,tnr2) = generateTempDecl(ident_type_str, tnr2_3);
        (cfn3,e1var,e2var,e3var,tnr3) = generateRangeExpressions(e, tnr2, context);
        r_stmt = Util.stringAppendList(
          {rvar1," = ",e1var,"; ",rvar2," = ",e2var,"; ",rvar3," = ",
          e3var,";"});
        for_begin = Util.stringAppendList(
          {"for (",i," = ",rvar1,"; ","in_range_",short_type,"(",i,
          ", ",rvar1,", ",rvar3,"); ",i," += ",rvar2,") {"});
        def_beg1 = Util.stringAppendList({"{\n  ",ident_type_str," ",i,";\n"});
        mem_begin = Util.stringAppendList({svar," = get_memory_state();"});
        (cfn4,tnr4) = generateAlgorithmStatements(stmts, tnr3,
           CONTEXT(codeContext,expContext,IN_FOR_LOOP(loopContext)));
        mem_end = Util.stringAppendList({"restore_memory_state(",svar,");"});
        for_end = "}";
        def_end1 = "} /* end for*/\n";
        cfn3_1 = cAddVariables(cfn3, {sdecl,rdecl1,rdecl2,rdecl3});
        cfn3_2 = cAddStatements(cfn3_1, {r_stmt,def_beg1,for_begin,mem_begin});
        cfn4_1 = cAddStatements(cfn4, {mem_end,for_end,def_end1});
        cfn = cMergeFns({cfn3_2,cfn4_1});
      then
        (cfn,tnr4);
    case (Algorithm.FOR(type_ = t,boolean = a,ident = i,exp = e,statementLst = stmts),tnr,
                        context as CONTEXT(codeContext,expContext,loopContext))
      local CodeContext codeContext;
            ExpContext expContext;
            LoopContext loopContext;
      equation 
        (sdecl,svar,tnr_1) = generateTempDecl("state", tnr);
        (_,dvar,tnr_2) = generateTempDecl("", tnr_1);
        (tdecl,tvar,tnr1) = generateTempDecl("int", tnr_2);
        ident_type_str = expTypeStr(t, a);
        (idecl,ivar,tnr2) = generateTempDecl(ident_type_str, tnr1);
        array_type_str = expTypeStr(t, true);
        (cfn3,evar,tnr3) = generateExpression(e, tnr2, context);
        for_begin = Util.stringAppendList(
          {"for (",tvar," = 1; ",tvar," <= size_of_dimension_",
          array_type_str,"(",evar,", 1); ","++",tvar,") {"});
        def_beg1 = Util.stringAppendList({"{\n  ",ident_type_str," ",i,";\n"});
        mem_begin = Util.stringAppendList({svar," = get_memory_state();"});
        stmt_array = Util.stringAppendList(
          {"simple_index_alloc_",ident_type_str,"1(&",evar,", ",tvar,
          ", &",ivar,"));"});
        stmt_scalar = Util.stringAppendList(
          {i," = *(",array_type_str,"_element_addr1(&",evar,", 1, ",
          tvar,"));"});
        stmt = Util.if_(a, stmt_array, stmt_scalar) "Use fast implementation for 1 dim" ;
        (cfn4,tnr4) = generateAlgorithmStatements(stmts, tnr3,
           CONTEXT(codeContext,expContext,IN_FOR_LOOP(loopContext)));
        mem_end = Util.stringAppendList({"restore_memory_state(",svar,");"});
        for_end = "}";
        def_end1 = "} /* end for*/\n";
        cfn3_1 = cAddVariables(cfn3, {sdecl,tdecl,idecl});
        cfn3_2 = cAddStatements(cfn3_1, {def_beg1,for_begin,mem_begin,stmt});
        cfn4_1 = cAddStatements(cfn4, {mem_end,for_end,def_end1});
        cfn = cMergeFns({cfn3_2,cfn4_1});
      then
        (cfn,tnr4);
    case (Algorithm.WHILE(exp = e,statementLst = stmts),tnr,
                        context as CONTEXT(codeContext,expContext,loopContext))
      local CodeContext codeContext;
            ExpContext expContext;
            LoopContext loopContext;
      equation 
        cfn1 = cAddStatements(cEmptyFunction, {"while (1) {"});
        (cfn2,var2,tnr2) = generateExpression(e, tnr, context);
        crit_stmt = Util.stringAppendList({"if (!",var2,") break;"});
        cfn2_1 = cAddStatements(cfn2, {crit_stmt});
        (cfn3,tnr3) = generateAlgorithmStatements(stmts, tnr2,
           CONTEXT(codeContext,expContext,IN_WHILE_LOOP(loopContext)));
        cfn3_1 = cAddStatements(cfn3, {"}"});
        cfn = cMergeFns({cfn1,cfn2_1,cfn3_1});
      then
        (cfn,tnr3);
    case (Algorithm.WHEN(exp = _),_,_)
      equation 
        Debug.fprint("failtrace", "# when statement not implemented\n");
      then
        fail();
    case (Algorithm.TUPLE_ASSIGN(t,expl,e as Exp.CALL(path=_)),tnr,context)
      local Context context;
        list<Exp.Exp> args,expl; Absyn.Path fn;
        list<String> lhsVars,vars1;
        String tupleVar;
      equation 
        (cfn1,tupleVar,tnr1) = generateExpression(e, tnr, context);
				(cfn,tnr1) = generateTupleLhsAssignment(expl,tupleVar,1,tnr1,context);
				cfn = cMergeFn(cfn1,cfn);
      then
        (cfn,tnr1);
        
    case (Algorithm.ASSERT(exp1 = e1,exp2 = e2),tnr,CONTEXT(codeContext,_,loopContext))
      local CodeContext codeContext;
            LoopContext loopContext;
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, CONTEXT(codeContext,EXP_EXTERNAL(),loopContext));
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, CONTEXT(codeContext,EXP_EXTERNAL(),loopContext));
        stmt = Util.stringAppendList({"MODELICA_ASSERT(",var1,", ",var2,");"});
        cfn2_1 = cAddStatements(cfn2, {stmt});
        cfn = cMergeFns({cfn1,cfn2_1});
      then
        (cfn,tnr2);
    case (Algorithm.RETURN(),tnr,_)
      local Lib retStmt;
      equation 
        cfn = cAddStatements(cEmptyFunction, {"goto _return;"});
      then
        (cfn,tnr);
    case (Algorithm.BREAK(),tnr,CONTEXT(_,_,NO_LOOP()))
      equation 
        Error.addMessage(Error.BREAK_OUT_OF_LOOP, {});
      then
        (cEmptyFunction,tnr);
    case (Algorithm.BREAK(),tnr,_)
      equation 
        cfn = cAddStatements(cEmptyFunction, {"break;"});
      then
        (cfn,tnr);
    case (stmt,_,_)
      local Algorithm.Statement stmt;
      equation 
        Debug.fprint("failtrace", "# generate_algorithm_statement failed\n");
      then
        fail();
  end matchcontinue;
end generateAlgorithmStatement;

protected function generateTupleLhsAssignment "Generates the assignment of output args in a tuple call
 given a variable containing the tuple represented as a struct.
author: PA
"
  input list<Exp.Exp> expl;
  input String tupleVar;
  input Integer i "nth tuple elt";
  input Integer tnr;
  input Context context;
  output CFunction cfn;
  output Integer outTnr;
algorithm
  (cfn,outTnr) := matchcontinue(expl,tupleVar,i,tnr,context) 
  local Exp.ComponentRef cr;
    String res1,stmt,iStr;
    CFunction cfn2;
    Exp.Ident id;
    Exp.Type tp;
    list<tuple<Exp.Type,Exp.Ident>> vars;
    case({},tupleVar,i,tnr,context) then (cEmptyFunction,tnr);
    case(Exp.CREF(cr,tp)::expl,tupleVar,i,tnr,context) equation
      (cfn,res1,tnr) = generateScalarLhsCref(tp,cr,tnr,context);
      iStr = intString(i);
      stmt = Util.stringAppendList({res1," = ",tupleVar,".","targ",iStr,";"});
      cfn = cAddStatements(cfn, {stmt});
      (cfn2,tnr) = generateTupleLhsAssignment(expl,tupleVar,i+1,tnr,context);
      cfn = cMergeFn(cfn,cfn2);
    then (cfn,tnr);  
  end matchcontinue;
end generateTupleLhsAssignment;

protected function isSimulationContext "Returns true is context is Simulation."
  input Context context;
  output Boolean res;
algorithm
  res := matchcontinue(context)
    case(CONTEXT(SIMULATION(),_,_)) then true;
    case(_) then false;
  end matchcontinue;
end isSimulationContext;

protected function generateRangeExpressions "function: generateRangeExpressions
  
  Generates code for a range expression.
"
  input Exp.Exp inExp;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction1;
  output String outString2;
  output String outString3;
  output String outString4;
  output Integer outInteger5;
algorithm 
  (outCFunction1,outString2,outString3,outString4,outInteger5):=
  matchcontinue (inExp,inInteger,inContext)
    local
      CFunction cfn1,cfn3,cfn,cfn2;
      Lib var1,var2,var3;
      Integer tnr1,tnr3,tnr,tnr2;
      Exp.Type t;
      Exp.Exp e1,e3,e2;
      Context context;
    case (Exp.RANGE(ty = t,exp = e1,expOption = NONE,range = e3),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        var2 = "(1)";
        (cfn3,var3,tnr3) = generateExpression(e3, tnr1, context);
        cfn = cMergeFn(cfn1, cfn3);
      then
        (cfn,var1,var2,var3,tnr3);
    case (Exp.RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (cfn3,var3,tnr3) = generateExpression(e3, tnr2, context);
        cfn = cMergeFns({cfn1,cfn2,cfn3});
      then
        (cfn,var1,var2,var3,tnr3);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_range_expressions failed\n");
      then
        fail();
  end matchcontinue;
end generateRangeExpressions;

protected function generateElse "function: generateElse
  
  Generates code for an Else branch.
"
  input Algorithm.Else inElse;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElse,inInteger,inContext)
    local
      Integer tnr,tnr2,tnr3,tnr4;
      CFunction cfn1,cfn2,cfn2_1,cfn3,cfn3_1,cfn4,cfn4_1,cfn;
      Lib var2,if_begin;
      Exp.Exp e;
      list<Algorithm.Statement> stmts;
      Algorithm.Else else_;
      Context context;
    case (Algorithm.NOELSE(),tnr,_) then (cEmptyFunction,tnr); 
    case (Algorithm.ELSEIF(exp = e,statementLst = stmts,else_ = else_),tnr,context)
      equation 
        cfn1 = cAddStatements(cEmptyFunction, {"else {"});
        (cfn2,var2,tnr2) = generateExpression(e, tnr, context);
        if_begin = Util.stringAppendList({"if (",var2,") {"});
        cfn2_1 = cAddStatements(cfn2, {if_begin});
        (cfn3,tnr3) = generateAlgorithmStatements(stmts, tnr2, context);
        cfn3_1 = cAddStatements(cfn3, {"}"});
        (cfn4,tnr4) = generateElse(else_, tnr3, context);
        cfn4_1 = cAddStatements(cfn4, {"}"});
        cfn = cMergeFns({cfn1,cfn2_1,cfn3_1,cfn4_1});
      then
        (cfn,tnr4);
    case (Algorithm.ELSE(statementLst = stmts),tnr,context)
      equation 
        cfn1 = cAddStatements(cEmptyFunction, {"else {"});
        (cfn2,tnr2) = generateAlgorithmStatements(stmts, tnr, context);
        cfn2_1 = cAddStatements(cfn2, {"}"});
        cfn = cMergeFn(cfn1, cfn2_1);
      then
        (cfn,tnr);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "-generate_else failed\n");
      then
        fail();
  end matchcontinue;
end generateElse;

protected function generateVars "function: generateVars
 
  Generates code for variables, given a list of elements and a function
  over the elements. Code is only generated for elements for which the 
  function succeeds.
"
  input list<DAE.Element> inDAEElementLst;
  input FuncTypeDAE_ElementTo inFuncTypeDAEElementTo;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
  partial function FuncTypeDAE_ElementTo
    input DAE.Element inElement;
  end FuncTypeDAE_ElementTo;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inFuncTypeDAEElementTo,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      CFunction cfn1,cfn2,cfn;
      DAE.Element first;
      list<DAE.Element> rest;
      FuncTypeDAE_ElementTo verify;
      Context context;
    case ({},_,tnr,_) then (cEmptyFunction,tnr); 
    case ((first :: rest),verify,tnr,context)
      equation 
        verify(first);
        (cfn1,tnr1) = generateVar(first, tnr, context);
        (cfn2,tnr2) = generateVars(rest, verify, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
    case ((first :: rest),verify,tnr,context)
      equation 
        failure(verify(first));
        (cfn,tnr2) = generateVars(rest, verify, tnr, context);
      then
        (cfn,tnr2);
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_vars failed\n");
      then
        fail();
  end matchcontinue;
end generateVars;

protected function generateVarDecls "function: generateVarDecls
 
  Generates declaration code for variables given a DAE.Element list 
  and a function over elements. Code is only generated for Elements for 
  which the function succeeds.
"
  input list<DAE.Element> inDAEElementLst;
  input FuncTypeDAE_ElementTo inFuncTypeDAEElementTo;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
  partial function FuncTypeDAE_ElementTo
    input DAE.Element inElement;
  end FuncTypeDAE_ElementTo;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inFuncTypeDAEElementTo,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      CFunction cfn1,cfn2,cfn;
      DAE.Element first;
      list<DAE.Element> rest;
      FuncTypeDAE_ElementTo verify;
      Context context;
    case ({},_,tnr,_) then (cEmptyFunction,tnr); 
    case ((first :: rest),verify,tnr,context)
      equation 
        verify(first);
        (cfn1,tnr1) = generateVarDecl(first, tnr, context);
        (cfn2,tnr2) = generateVarDecls(rest, verify, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
    case ((first :: rest),verify,tnr,context)
      equation 
        failure(verify(first));
        (cfn,tnr2) = generateVarDecls(rest, verify, tnr, context);
      then
        (cfn,tnr2);
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_var_decls failed\n");
      then
        fail();
  end matchcontinue;
end generateVarDecls;

protected function generateVarInits "function: generateVarInits
 
  Generates initialization code for variables given a DAE.Element list 
  and a function over elements. Code is only generated for Elements for 
  which the function succeeds.
"
  input list<DAE.Element> inDAEElementLst;
  input FuncTypeDAE_ElementTo inFuncTypeDAEElementTo;
  input Integer i "nth tuple only used if output variable";
  input Integer inInteger;
  input String inString;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
  partial function FuncTypeDAE_ElementTo
    input DAE.Element inElement;
  end FuncTypeDAE_ElementTo;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inFuncTypeDAEElementTo,i,inInteger,inString,inContext)
    local
      Integer tnr,tnr1,tnr2;
      CFunction cfn1,cfn2,cfn;
      DAE.Element first;
      list<DAE.Element> rest;
      FuncTypeDAE_ElementTo verify;
      Lib pre;
      Context context;
    case ({},_,_,tnr,_,_) then (cEmptyFunction,tnr);  /* elements verifying function variable prefix */ 
    case ((first :: rest),verify,i,tnr,pre,context)
      equation 
        verify(first);
        (cfn1,tnr1) = generateVarInit(first, i, tnr, pre, context);
        (cfn2,tnr2) = generateVarInits(rest, verify, i+1, tnr1, pre, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
    case ((first :: rest),verify,i,tnr,pre,context)
      equation 
        failure(verify(first));
        (cfn,tnr2) = generateVarInits(rest, verify, i, tnr, pre, context);
      then
        (cfn,tnr2);
    case (_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_var_inits failed\n");
      then
        fail();
  end matchcontinue;
end generateVarInits;

protected function generateVar "function: generateVar
 
  Generates code for a variable.
"
  input DAE.Element inElement;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElement,inInteger,inContext)
    local
      Boolean is_a;
      Lib typ_str,cref_str,dimvars_str,dims_str,dim_comment,dim_comment_1,ndims_str,decl_str,alloc_str,init_stmt;
      CFunction cfn1_1,cfn1,cfn_1,cfn_2,cfn;
      list<Lib> vars1,dim_strs;
      Integer tnr1,ndims,tnr;
      DAE.Element var;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      list<Exp.Subscript> inst_dims;
      Option<Exp.Exp> start;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Context context;
      Exp.Exp e;
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = NONE,binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),tnr,context) /* variables without binding */ 
      equation 
        is_a = isArray(var);
        typ_str = daeTypeStr(typ, is_a);
        (cref_str,_) = compRefCstr(id);
        (cfn1_1,vars1,tnr1) = generateSizeSubscripts(cref_str, inst_dims, tnr, context);
        cfn1 = cMoveStatementsToInits(cfn1_1);
        dimvars_str = Util.stringDelimitList(vars1, ", ");
        dim_strs = Util.listMap(inst_dims, dimString);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        dim_comment = Util.stringAppendList({" /* [",dims_str,"] */"});
        dim_comment_1 = Util.if_(is_a, dim_comment, "");
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        decl_str = Util.stringAppendList({typ_str," ",cref_str,";",dim_comment_1});
        alloc_str = Util.stringAppendList(
          {"alloc_",typ_str,"(&",cref_str,", ",ndims_str,", ",
          dimvars_str,");"});
        cfn_1 = cAddVariables(cfn1, {decl_str});
        cfn_2 = cAddInits(cfn_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_2, cfn_1);
      then
        (cfn,tnr1);
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = SOME(e),binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),tnr,context) /* variables with binding */ 
      equation 
        is_a = isArray(var);
        typ_str = daeTypeStr(typ, is_a);
        (cref_str,_) = compRefCstr(id);
        (cfn1_1,vars1,tnr1) = generateSizeSubscripts(cref_str, inst_dims, tnr, context);
        cfn1 = cMoveStatementsToInits(cfn1_1);
        dimvars_str = Util.stringDelimitList(vars1, ", ");
        dim_strs = Util.listMap(inst_dims, dimString);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        dim_comment = Util.stringAppendList({" /* [",dims_str,"] */"});
        dim_comment_1 = Util.if_(is_a, dim_comment, "");
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        decl_str = Util.stringAppendList({typ_str," ",cref_str,";",dim_comment_1});
        alloc_str = Util.stringAppendList(
          {"alloc_",typ_str,"(&",cref_str,", ",ndims_str,", ",
          dimvars_str,");"});
        cfn_1 = cAddVariables(cfn1, {decl_str});
        cfn_2 = cAddInits(cfn_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_2, cfn_1);
        Print.printBuf("# default value not implemented yet: ");
        Exp.printExp(e);
        Print.printBuf("\n");
      then
        (cfn,tnr1);
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = SOME(e),binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),tnr,context)
      local Lib var;
      equation 
        is_a = isArray(var);
        typ_str = daeTypeStr(typ, is_a);
        (cref_str,_) = compRefCstr(id);
        decl_str = Util.stringAppendList({typ_str," ",cref_str,";"});
        (cfn,var,tnr1) = generateExpression(e, tnr, context);
        cfn_1 = cAddVariables(cfn, {decl_str});
        init_stmt = Util.stringAppendList({cref_str," = ",var,";"});
        cfn_2 = cAddInits(cfn_1, {init_stmt});
        Print.printBuf("# default value not implemented yet: ");
        Exp.printExp(e);
        Print.printBuf("\n");
      then
        (cfn_2,tnr1);
    case (e,_,_)
      local DAE.Element e;
      equation 
        Debug.fprint("failtrace", "-generate_var failed\n");
      then
        fail();
  end matchcontinue;
end generateVar;

protected function generateVarDecl "function: generateVarDecl
 
  Generates code for a variable declaration.
"
  input DAE.Element inElement;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElement,inInteger,inContext)
    local
      Boolean is_a;
      Lib typ_str,cref_str,dims_str,dim_comment,dim_comment_1,ndims_str,decl_str;
      list<Lib> dim_strs;
      Integer ndims,tnr,tnr1;
      CFunction cfn;
      DAE.Element var;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      list<Exp.Subscript> inst_dims;
      Option<Exp.Exp> start;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Context context;
      Exp.Exp e;
      Types.Type tp;
      Absyn.InnerOuter io;
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = NONE,binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),tnr,context)
      equation 
        is_a = isArray(var);
        typ_str = daeTypeStr(typ, is_a);
        (cref_str,_) = compRefCstr(id);
        dim_strs = Util.listMap(inst_dims, dimString);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        dim_comment = Util.stringAppendList({" /* [",dims_str,"] */"});
        dim_comment_1 = Util.if_(is_a, dim_comment, "");
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        decl_str = Util.stringAppendList({typ_str," ",cref_str,";",dim_comment_1});
        cfn = cAddVariables(cEmptyFunction, {decl_str});
      then
        (cfn,tnr);
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = SOME(e),binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment,innerOuter=io,fullType=tp)),tnr,context)
      equation 
        (cfn,tnr1) = generateVarDecl(
          DAE.VAR(id,vk,vd,typ,NONE,inst_dims,start,flow_,class_,
          dae_var_attr,comment,io,tp), tnr, context);
      then
        (cfn,tnr1);
    case (e,_,_)
      local DAE.Element e;
      equation 
        Debug.fprint("failtrace", "# generate_var_decl failed\n");
      then
        fail();
  end matchcontinue;
end generateVarDecl;

protected function generateVarInit "function: generateVarInit
 
  Generates code for the initialization of a variable.
"
  input DAE.Element inElement;
  input Integer i "nth tuple elt, only used for output vars";
  input Integer inInteger;
  input String inString;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElement,i,inInteger,inString,inContext)
    local
      DAE.Element var;
      Exp.ComponentRef id,id_1,idstr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      list<Exp.Subscript> inst_dims;
      Option<Exp.Exp> start;
      DAE.Flow flow_;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Integer tnr,tnr1;
      Lib pre;
      Context context;
      Boolean is_a,emptyprep;
      Exp.Type exptype;
      Algorithm.Statement scalarassign,arrayassign,assign;
      CFunction cfn;
      Exp.Exp e;
      String iStr,id_1_str;
      /* No binding */ 
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = NONE,binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),i,tnr,pre,context) 
      then (cEmptyFunction,tnr);  

      /* Has binding */     
    case ((var as DAE.VAR(componentRef = id,varible = vk,variable = vd,input_ = typ,one = SOME(e),binding = inst_dims,dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)),i,tnr,pre,context) 
      equation 
        is_a = isArray(var);
        // pre can be "" or "out", the later for output variables.
        emptyprep = stringEqual(pre, "");
        iStr = intString(i);
        id_1_str = Util.stringAppendList({"out.","targ",iStr});
        idstr = Util.if_(emptyprep, id, Exp.CREF_IDENT(id_1_str,{}));
        exptype = daeExpType(typ);
        scalarassign = Algorithm.ASSIGN(exptype,idstr,e);
        arrayassign = Algorithm.ASSIGN_ARR(exptype,idstr,e);
        assign = Util.if_(is_a, arrayassign, scalarassign);
        (cfn,tnr1) = generateAlgorithmStatement(assign, tnr, context);
      then
        (cfn,tnr1);
    case (e,_,_,_,_)
      local DAE.Element e;
      equation 
        Debug.fprint("failtrace", "# generate_var_init failed\n");
      then
        fail();
  end matchcontinue;
end generateVarInit;

protected function dimString "function: dimString
 
  Returns a Exp.subscript as a string.
"
  input Exp.Subscript inSubscript;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inSubscript)
    local
      Lib str;
      Integer i;
      Exp.Subscript e;
    case Exp.INDEX(exp = Exp.ICONST(integer = i))
      equation 
        str = intString(i);
      then
        str;
    case e
      equation 
        str = Exp.printSubscriptStr(e);
      then
        ":";
    case (_)
      equation 
        print("dim_string failed\n");
      then
        fail();
  end matchcontinue;
end dimString;

protected function isVarQ "function: isVarQ
 
  Succeds if DAE.Element is a variable or constant that is not input.
"
  input DAE.Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(componentRef = id,varible = vk,variable = vd)
      equation 
        generateVarQ(vk);
        generateVarQ2(vd);
      then
        ();
  end matchcontinue;
end isVarQ;

protected function generateVarQ "function: generateVarQ
 
  Helper function to is_var_q.
"
  input DAE.VarKind inVarKind;
algorithm 
  _:=
  matchcontinue (inVarKind)
    case DAE.VARIABLE() then ();  /* axiom	generate_var_q DAE.PARAM */ 
    case DAE.CONST() then (); 
  end matchcontinue;
end generateVarQ;

protected function generateVarQ2 "function: generateVarQ2
 
  Helper function to is_var_q.
"
  input DAE.VarDirection inVarDirection;
algorithm 
  _:=
  matchcontinue (inVarDirection)
    case DAE.OUTPUT() then (); 
    case DAE.BIDIR() then (); 
  end matchcontinue;
end generateVarQ2;

protected function generateResultVars "function: generaet_result_vars
 
  Generates code for output variables.
"
  input list<DAE.Element> inDAEElementLst;
  input String inString;
  input Integer i;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inString,i,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      DAE.Element first;
      list<DAE.Element> rest;
      Lib varname;
    case ({},_,_,tnr,context) then (cEmptyFunction,tnr); 
    case ((first :: rest),varname,i,tnr,context)
      equation 
        (cfn1,tnr1) = generateResultVar(first, varname, i,tnr, context);
        (cfn2,tnr2) = generateResultVars(rest, varname, i+1,tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
    case ((_ :: rest),varname,i,tnr,context)
      equation 
        (cfn,tnr1) = generateResultVars(rest, varname, i,tnr, context);
      then
        (cfn,tnr1);        
  end matchcontinue;
end generateResultVars;

protected function generateResultVar "function: generateResultVar
 
  Helper function to generate_result_vars.
"
  input DAE.Element inElement;
  input String inString;
  input Integer i;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inElement,inString,i,inInteger,inContext)
    local
      Lib cref_str1,cref_str2,stmt,varname,typ_str;
      CFunction cfn;
      DAE.Element var;
      Exp.ComponentRef id;
      DAE.Type typ;
      Integer tnr;
      Context context;
      /* varname non-arrays */ 
    case ((var as DAE.VAR(componentRef = id,varible = DAE.VARIABLE(),variable = DAE.OUTPUT(),input_ = typ)),varname,i,tnr,context) 
      equation 
        false = isArray(var);
        cref_str1 = stringAppend("targ",intString(i));
        (cref_str2,_) = compRefCstr(id);
        stmt = Util.stringAppendList({varname,".",cref_str1," = ",cref_str2,";"});
        cfn = cAddCleanups(cEmptyFunction, {stmt});
      then
        (cfn,tnr);
        /* arrays */ 
    case ((var as DAE.VAR(componentRef = id,varible = DAE.VARIABLE(),variable = DAE.OUTPUT(),input_ = typ)),varname,i,tnr,context) 
      equation 
        true = isArray(var);
        typ_str = daeTypeStr(typ, true);
        (cref_str1,_) = compRefCstr(id);
        cref_str2 = stringAppend("targ",intString(i));
        stmt = Util.stringAppendList(
          {"copy_",typ_str,"_data(&",cref_str1,", &",varname,".",
          cref_str2,");"});
        cfn = cAddCleanups(cEmptyFunction, {stmt});
      then
        (cfn,tnr);
  end matchcontinue;
end generateResultVar;

public function generateExpressions "function: generateExpressions
 
  Generates code for a list of expressions.
"
  input list<Exp.Exp> inExpExpLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output list<String> outStringLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outStringLst,outInteger):=
  matchcontinue (inExpExpLst,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      Lib var1;
      list<Lib> vars2;
      Exp.Exp f;
      list<Exp.Exp> r;
    case ({},tnr,context) then (cEmptyFunction,{},tnr); 
    case ((f :: r),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(f, tnr, context);
        (cfn2,vars2,tnr2) = generateExpressions(r, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,(var1 :: vars2),tnr2);
  end matchcontinue;
end generateExpressions;

public function generateExpression "function: generateExpression
 
  Generates code for an expression.
  returns
   CFunction | the generated code
   string    | expression result variable name, or c expression
   int       | next temporary number 
"
  input Exp.Exp inExp;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inExp,inInteger,inContext)
    local
      Lib istr,rstr,sstr,s,var,var1,decl,tvar,b_stmt,if_begin,var2,var3,ret_type,fn_name,tdecl,args_str,underscore,stmt,var_not_bi,typestr,nvars_str,array_type_str,short_type_str,scalar,scalar_ref,scalar_delimit,type_string,var_1,msg;
      Integer i,tnr,tnr_1,tnr1,tnr1_1,tnr2,tnr3,nvars,maxn,tnr4;
      Context context;
      Real r;
      Boolean b,builtin,a;
      CFunction cfn,cfn1,cfn1_2,cfn1_1,cfn2,cfn2_1,cfn3,cfn3_1,cfn4,cfn_1;
      Exp.ComponentRef cref,cr;
      Exp.Type t,ty;
      Exp.Exp e1,e2,e,then_,else_,crexp,dim,e3;
      Exp.Operator op;
      Absyn.Path fn;
      list<Exp.Exp> args,elist;
      list<Lib> vars1;
      list<list<tuple<Exp.Exp, Boolean>>> ell;
    case (Exp.ICONST(integer = i),tnr,context)
      equation 
        istr = intString(i);
      then
        (cEmptyFunction,istr,tnr);
    case (Exp.RCONST(real = r),tnr,context)
      equation 
        rstr = realString(r);
      then
        (cEmptyFunction,rstr,tnr);
	  //Strings are stored as char*, therefor return data member of modelica_string struct.
    case (Exp.SCONST(string = s),tnr,context)
      local String stmt,tvar_data; CFunction cfn;
      equation 
        (decl,tvar,tnr1_1) = generateTempDecl("modelica_string", tnr);
        stmt = Util.stringAppendList({"init_modelica_string(&",tvar,",\"",s,"\");"});
        cfn = cAddStatements(cEmptyFunction, {stmt});
        cfn = cAddVariables(cfn, {decl});
      then
        (cfn,tvar,tnr1_1);
    case (Exp.BCONST(bool = b),tnr,context)
      equation 
        var = Util.if_(b, "(1)", "(0)");
      then
        (cEmptyFunction,var,tnr);
    case (Exp.CREF(componentRef = cref,ty = t),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateRhsCref(cref, t, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.BINARY(exp1 = e1,operator = op,exp2 = e2),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateBinary(e1, op, e2, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.UNARY(operator = op,exp = e),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateUnary(op, e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateLbinary(e1, op, e2, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.LUNARY(operator = op,exp = e),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateLunary(op, e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.RELATION(exp1 = e1,operator = op,exp2 = e2),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateRelation(e1, op, e2, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.IFEXP(expCond = e,expThen = then_,expElse = else_),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e, tnr, context);
        (decl,tvar,tnr1_1) = generateTempDecl("modelica_boolean", tnr1);
        b_stmt = Util.stringAppendList({tvar," = ",var1,";"});
        if_begin = Util.stringAppendList({"if (",tvar,") {"});
        cfn1_2 = cAddStatements(cfn1, {b_stmt,if_begin});
        cfn1_1 = cAddVariables(cfn1_2, {decl});
        (cfn2,var2,tnr2) = generateExpression(then_, tnr1_1, context);
        cfn2_1 = cAddStatements(cfn2, {"}","else {"});
        (cfn3,var3,tnr3) = generateExpression(else_, tnr2, context);
        cfn3_1 = cAddStatements(cfn3, {"}"});
        cfn = cMergeFns({cfn1_1,cfn2_1,cfn3_1});
        var = Util.stringAppendList({"((",tvar,")?",var2,":",var3,")"});
      then
        (cfn,var,tnr3);
        
        /* some buitlin functions that are e.g. overloaded */ 
    case ((e as Exp.CALL(path = fn,expLst = args,tuple_ = false,builtin = builtin)),tnr,context) 
      equation 
        (cfn,var,tnr2) = generateBuiltinFunction(e, tnr, context);
      then
        (cfn,var,tnr2);

        /* non-tuple calls */ 
    case (Exp.CALL(path = fn,expLst = args,tuple_ = false,builtin = builtin),tnr,context) 
      equation 
        (cfn1,vars1,tnr1) = generateExpressions(args, tnr, context);
        ret_type = generateReturnType(fn);
        fn_name = generateFunctionName(fn);
        (tdecl,tvar,tnr2) = generateTempDecl(ret_type, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        args_str = Util.stringDelimitList(vars1, ", ");
        underscore = Util.if_(builtin, "", "_");
        stmt = Util.stringAppendList({tvar," = ",underscore,fn_name,"(",args_str,");"}) "builtin fcns no underscore" ;
        cfn = cAddStatements(cfn2, {stmt});
        var_not_bi = Util.stringAppendList({tvar,".",ret_type,"_1"});
        var = Util.if_(builtin, tvar, var_not_bi);
      then
        (cfn,var,tnr2);
        
        /* tuple calls */
    case (Exp.CALL(path = fn,expLst = args,tuple_ = true,builtin = builtin),tnr,context)  
      equation 
        (cfn1,vars1,tnr1) = generateExpressions(args, tnr, context);
        ret_type = generateReturnType(fn);
        fn_name = generateFunctionName(fn);
        (tdecl,tvar,tnr2) = generateTempDecl(ret_type, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        args_str = Util.stringDelimitList(vars1, ", ");
        stmt = Util.stringAppendList({tvar," = _",fn_name,"(",args_str,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
        
    case (Exp.SIZE(exp = (crexp as Exp.CREF(componentRef = cr,ty = ty)),sz = SOME(dim)),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(crexp, tnr, context);
        (tdecl,tvar,tnr2) = generateTempDecl("size_t", tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        typestr = expTypeStr(ty, true);
        (cfn3,var2,tnr3) = generateExpression(dim, tnr2, context);
        stmt = Util.stringAppendList(
          {tvar," = size_of_dimension_",typestr,"(",var1,",",var2,");"});
        cfn4 = cMergeFn(cfn2, cfn3);
        cfn = cAddStatements(cfn4, {stmt});
      then
        (cfn,tvar,tnr2);
        
    case (Exp.SIZE(exp = cr,sz = NONE),tnr,context)
      local Exp.Exp cr;
      equation 
        Debug.fprint("failtrace", 
          "#-- Codegen.generate_expression: size(X) not implemented");
      then
        fail();
    case (e as Exp.ARRAY(ty = t,scalar = a,array = elist),tnr,context)
      local Exp.Exp e;
      equation 
        (cfn1,vars1,tnr1) = generateExpressions(elist, tnr, context);
        nvars = listLength(vars1);
        nvars_str = intString(nvars);
        array_type_str = expTypeStr(t, true);
        short_type_str = expShortTypeStr(t);
        (tdecl,tvar,tnr2) = generateTempDecl(array_type_str, tnr1);
        scalar = Util.if_(a, "scalar_", "");
        scalar_ref = Util.if_(a, "", "&");
        scalar_delimit = stringAppend(", ", scalar_ref);
        args_str = Util.stringDelimitList(vars1, scalar_delimit);
        stmt = Util.stringAppendList(
          {"array_alloc_",scalar,array_type_str,"(&",tvar,", ",
          nvars_str,", ",scalar_ref,args_str,");"});
        cfn_1 = cAddVariables(cfn1, {tdecl});
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tvar,tnr2);
    case (e as Exp.MATRIX(ty = t,integer = maxn,scalar = ell),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateMatrix(t, maxn, ell, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.RANGE(ty = t,exp = e1,expOption = NONE,range = e2),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        type_string = expTypeStr(t, true);
        (tdecl,tvar,tnr3) = generateTempDecl(type_string, tnr2);
        stmt = Util.stringAppendList(
          {"range_alloc_",type_string,"(",var1,", ",var2,", 1, &",
          tvar,");"});
        cfn1_1 = cAddVariables(cfn1, {tdecl});
        cfn2_1 = cAddStatements(cfn2, {stmt});
        cfn = cMergeFns({cfn1_1,cfn2_1});
      then
        (cfn,tvar,tnr3);
    case (Exp.RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3),tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (cfn3,var3,tnr3) = generateExpression(e3, tnr1, context);
        type_string = expTypeStr(t, true);
        (tdecl,tvar,tnr4) = generateTempDecl(type_string, tnr3);
        stmt = Util.stringAppendList(
          {"range_alloc_",type_string,"(",var1,", ",var3,", ",var2,
          ", &",tvar,");"});
        cfn1_1 = cAddVariables(cfn1, {tdecl});
        cfn2_1 = cAddStatements(cfn2, {stmt});
        cfn = cMergeFns({cfn1_1,cfn2_1});
      then
        (cfn,tvar,tnr4);
    case (Exp.TUPLE(PR = _),_,_)
      equation 
        Debug.fprint("failtrace", 
          "# Codegen.generate_expression: tuple not implemented\n");
      then
        fail();
    case (Exp.CAST(ty = Exp.INT(),exp = e),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"((modelica_int)",var,")"});
      then
        (cfn,var_1,tnr_1);
    case (Exp.CAST(ty = Exp.REAL(),exp = e),tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"((modelica_real)",var,")"});
      then
        (cfn,var_1,tnr_1);
    case (Exp.ASUB(exp = _),_,_)
      equation 
        Debug.fprint("failtrace", 
          "# Codegen.generate_expression: asub not implemented\n");
      then
        fail();
    case (e,_,_)
      equation 
        Debug.fprintln("failtrace", "# generate_expression failed");
        s = Exp.printExpStr(e);
        Debug.fprintln("failtrace", s);
        Debug.fprintln("failtrace", "");
        msg = Util.stringAppendList({"code  generation of expression ",s," failed"});
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end matchcontinue;
end generateExpression;

protected function generateBuiltinFunction "function: generateBuiltinFunction
  author: PA
 
  Generates code for some specific builtin functions.
"
  input Exp.Exp inExp;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inExp,inInteger,inContext)
    local
      Exp.Type tp;
      Lib tp_str,tp_str2,var1,fn_name,tdecl,tvar,stmt,var2;
      CFunction cfn1,cfn2,cfn;
      Integer tnr1,tnr2,tnr,tnr3;
      Exp.Exp arg,s1,s2;
      Context context;
    case (Exp.CALL(path = Absyn.IDENT(name = "max"),expLst = {arg},tuple_ = false,builtin = true),tnr,context) /* max(v), v is vector */ 
      equation 
        tp = Exp.typeof(arg);
        tp_str = expTypeStr(tp, true);
        tp_str2 = expTypeStr(tp, false);
        (cfn1,var1,tnr1) = generateExpression(arg, tnr, context);
        fn_name = stringAppend("max_", tp_str);
        (tdecl,tvar,tnr2) = generateTempDecl(tp_str2, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({tvar," = ",fn_name,"(&",var1,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
    case (Exp.CALL(path = Absyn.IDENT(name = "max"),expLst = {s1,s2},tuple_ = false,builtin = true),tnr,context) /* max (a,b) a, b scalars */ 
      equation 
        tp = Exp.typeof(s1);
        tp_str = expTypeStr(tp, false);
        (cfn1,var1,tnr1) = generateExpression(s1, tnr, context);
        (cfn1,var2,tnr2) = generateExpression(s2, tnr1, context);
        (tdecl,tvar,tnr3) = generateTempDecl(tp_str, tnr2);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({tvar," = max(",var1,",",var2,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr3);
    case (Exp.CALL(path = Absyn.IDENT(name = "abs"),expLst = {s1},tuple_ = false,builtin = true),tnr,context)
      equation 
        tp = Exp.typeof(s1);
        tp_str = expTypeStr(tp, false);
        (cfn1,var1,tnr1) = generateExpression(s1, tnr, context);
        (tdecl,tvar,tnr2) = generateTempDecl(tp_str, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({tvar," = fabs(",var1,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
            
    case (Exp.CALL(path = Absyn.IDENT(name = "sum"),expLst = {s1},tuple_ = false,builtin = true),tnr,context)
      local String arr_tp_str;
      equation 
        tp = Exp.typeof(s1);
        tp_str = expTypeStr(tp, false);
        arr_tp_str = expTypeStr(tp, true);
        (cfn1,var1,tnr1) = generateExpression(s1, tnr, context);
        (tdecl,tvar,tnr2) = generateTempDecl(tp_str, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({tvar," = sum_",arr_tp_str,"(&",var1,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
        
     case (Exp.CALL(path = Absyn.IDENT(name = "promote"),expLst = {A,n},tuple_ = false,builtin = true),tnr,context)
       local 
         Exp.Exp A,n;
         String arr_tp_str;
       equation 
         tp = Exp.typeof(A);
        tp_str = expTypeStr(tp, false);
        arr_tp_str = expTypeStr(tp, true);
        (cfn1,var1,tnr1) = generateExpression(A, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(n, tnr1, context);
        (tdecl,tvar,tnr2) = generateTempDecl(arr_tp_str, tnr1);
        cfn1 = cMergeFns({cfn1,cfn2});
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({"promote_alloc_",arr_tp_str,"(&",var1,",",var2,",&",tvar,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
        
     case (Exp.CALL(path = Absyn.IDENT(name = "transpose"),expLst = {A},tuple_ = false,builtin = true),tnr,context)
       local 
         Exp.Exp A;
         String arr_tp_str;
       equation 
        tp = Exp.typeof(A);
        tp_str = expTypeStr(tp, false);
        arr_tp_str = expTypeStr(tp, true);
        (cfn1,var1,tnr1) = generateExpression(A, tnr, context);
        (tdecl,tvar,tnr2) = generateTempDecl(arr_tp_str, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({"transpose_alloc_",arr_tp_str,"(&",var1,",&",tvar,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
        
  end matchcontinue;
end generateBuiltinFunction;

protected function generateUnary "function: generateUnary
  
  Helper function to generate_expression.
"
  input Exp.Operator inOperator;
  input Exp.Exp inExp;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inOperator,inExp,inInteger,inContext)
    local
      CFunction cfn;
      Lib var,var_1,s;
      Integer tnr_1,tnr;
      Exp.Exp e;
      Context context;
      Exp.Type tp;
    case (Exp.UPLUS(ty = Exp.REAL()),e,tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.UPLUS(ty = Exp.INT()),e,tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.UMINUS(ty = Exp.REAL()),e,tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"(-",var,")"});
      then
        (cfn,var_1,tnr_1);
    case (Exp.UMINUS(ty = Exp.INT()),e,tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"(-",var,")"});
      then
        (cfn,var_1,tnr_1);
    case (Exp.UMINUS(ty = Exp.OTHER()),e,tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"(-",var,")"});
      then
        (cfn,var_1,tnr_1);
    case (Exp.UPLUS_ARR(ty = Exp.REAL()),e,tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.UPLUS_ARR(ty = Exp.INT()),e,tnr,context)
      equation 
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (Exp.UMINUS_ARR(ty = _),_,_,_)
      equation 
        Debug.fprint("failtrace", "# unary minus for arrays not implemented\n");
      then
        fail();
    case (Exp.UMINUS(ty = tp),_,_,_)
      equation 
        Debug.fprint("failtrace", "-generate_unary failed\n");
        s = Exp.typeString(tp);
        Debug.fprint("failtrace", " tp = ");
        Debug.fprint("failtrace", s);
        Debug.fprint("failtrace", "\n");
      then
        fail();
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "-generate_unary failed\n");
      then
        fail();
  end matchcontinue;
end generateUnary;

protected function generateBinary "function:  generateBinary
 
  Helper function to generate_expression.
  returns:
  CFunction | the generated code
  string    | expression result 
  int       | next temporary number 
"
  input Exp.Exp inExp1;
  input Exp.Operator inOperator2;
  input Exp.Exp inExp3;
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inExp1,inOperator2,inExp3,inInteger4,inContext5)
    local
      CFunction cfn1,cfn2,cfn,cfn_1,cfn_2;
      Lib var1,var2,var,decl,stmt;
      Integer tnr1,tnr2,tnr,tnr3;
      Exp.Exp e1,e2;
      Context context;
    case (e1,Exp.ADD(ty = _),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," + ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.SUB(ty = _),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," - ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.MUL(ty = _),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," * ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.DIV(ty = _),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," / ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.POW(ty = _),e2,tnr,context) /* POW uses the math lib function with the same name. */ 
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"pow((modelica_real)",var1,", (modelica_real)",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (_,Exp.UMINUS(ty = _),_,_,_)
      equation 
        Debug.fprint("failtrace", 
          "# Unary minus in binary expression (internal error)");
      then
        fail();
    case (_,Exp.UPLUS(ty = _),_,_,_)
      equation 
        Debug.fprint("failtrace", 
          "# Unary plus in binary expression (internal error)");
      then
        fail();
    case (e1,Exp.ADD_ARR(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("real_array", tnr2);
        stmt = Util.stringAppendList({"add_alloc_real_array(&",var1,", &",var2,", &",var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.ADD_ARR(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("integer_array", tnr2);
        stmt = Util.stringAppendList(
          {"add_alloc_integer_array(&",var1,", &",var2,", &",var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.SUB_ARR(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("real_array", tnr2);
        stmt = Util.stringAppendList({"sub_alloc_real_array(&",var1,", &",var2,", &",var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.SUB_ARR(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("integer_array", tnr2);
        stmt = Util.stringAppendList(
          {"sub_alloc_integer_array(&",var1,", &",var2,", &",var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.MUL_SCALAR_ARRAY(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("real_array", tnr2);
        stmt = Util.stringAppendList(
          {"mul_alloc_scalar_real_array(",var1,", &",var2,", &",var,
          ");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.MUL_SCALAR_ARRAY(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("integer_array", tnr2);
        stmt = Util.stringAppendList(
          {"mul_alloc_scalar_integer_array(",var1,", &",var2,", &",
          var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.MUL_ARRAY_SCALAR(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("real_array", tnr2);
        stmt = Util.stringAppendList(
          {"mul_alloc_real_array_scalar(&",var1,", ",var2,", &",var,
          ");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.MUL_ARRAY_SCALAR(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("integer_array", tnr2);
        stmt = Util.stringAppendList(
          {"mul_alloc_integer_array_scalar(&",var1,", ",var2,", &",
          var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.MUL_SCALAR_PRODUCT(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"mul_real_scalar_product(&",var1,", &",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.MUL_SCALAR_PRODUCT(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"mul_integer_scalar_product(&",var1,", &",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.MUL_MATRIX_PRODUCT(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("real_array", tnr2);
        stmt = Util.stringAppendList(
          {"mul_alloc_real_matrix_product_smart(&",var1,", &",var2,
          ", &",var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.MUL_MATRIX_PRODUCT(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("integer_array", tnr2);
        stmt = Util.stringAppendList(
          {"mul_alloc_integer_matrix_product_smart(&",var1,", &",var2,
          ", &",var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.DIV_ARRAY_SCALAR(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("real_array", tnr2);
        stmt = Util.stringAppendList(
          {"div_alloc_real_array_scalar(&",var1,", ",var2,", &",var,
          ");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (e1,Exp.DIV_ARRAY_SCALAR(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (decl,var,tnr3) = generateTempDecl("integer_array", tnr2);
        stmt = Util.stringAppendList(
          {"div_alloc_integer_array_scalar(&",var1,", ",var2,", &",
          var,");"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn_2 = cAddVariables(cfn_1, {decl});
        cfn = cAddStatements(cfn_2, {stmt});
      then
        (cfn,var,tnr3);
    case (_,Exp.DIV_ARRAY_SCALAR(ty = _),_,_,_)
      equation 
        Debug.fprint("failtrace", "# div_array_scalar FAILING BECAUSE IT SUX\n");
      then
        fail();
    case (_,Exp.POW_ARR(ty = _),_,_,_)
      equation 
        Debug.fprint("failtrace", "# pow_array not implemented\n");
      then
        fail();
    case (_,Exp.DIV_ARRAY_SCALAR(ty = _),_,_,_)
      equation 
        Debug.fprint("failtrace", "# div_array_scalar not implemented\n");
      then
        fail();
    case (_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_binary failed\n");
      then
        fail();
  end matchcontinue;
end generateBinary;

protected function generateTempDecl "function: generateTempDecl
  
  Generates code for the declaration of a temporary variable.
"
  input String inString;
  input Integer inInteger;
  output String outString1;
  output String outString2;
  output Integer outInteger3;
algorithm 
  (outString1,outString2,outInteger3):=
  matchcontinue (inString,inInteger)
    local
      Lib tnr_str,tmp_name,t_1,t;
      Integer tnr_1,tnr;
    case (t,tnr)
      equation 
        tnr_str = intString(tnr);
        tnr_1 = tnr + 1;
        tmp_name = stringAppend("tmp", tnr_str);
        t_1 = Util.stringAppendList({t," ",tmp_name,";"});
      then
        (t_1,tmp_name,tnr_1);
  end matchcontinue;
end generateTempDecl;

protected function generateScalarLhsCref "function: generateScalarLhsCref
 
  Helper function to generate_algorithm_statement.
"
  input Exp.Type inType;
  input Exp.ComponentRef inComponentRef;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inType,inComponentRef,inInteger,inContext)
    local
      Lib cref_str,var,ndims_str,idxs_str,type_str,cref1,id;
      Exp.Type t;
      Exp.ComponentRef cref;
      Integer tnr,tnr_1,tnr1,ndims;
      Context context;
      list<Exp.Subscript> subs,idx;
      CFunction cfn,cfn1;
      list<Lib> idxs1;
    case (t,cref,tnr,context)
      equation 
        (cref_str,{}) = compRefCstr(cref);
      then
        (cEmptyFunction,cref_str,tnr);
    case (t,cref,tnr,context)
      equation 
        (cref_str,subs) = compRefCstr(cref);
        (cfn,var,tnr_1) = generateScalarRhsCref(cref_str, t, subs, tnr, context);
      then
        (cfn,var,tnr_1);

        /* two special cases rules for 1 and 2 dimensions for faster code (no vararg) */ 
    case (t,Exp.CREF_IDENT(ident = id,subscriptLst = idx),tnr,context) 
      equation 
        Debug.fprintln("gcge", "generating cref ccode");
        (cfn1,idxs1,tnr1) = generateIndices(idx, tnr, context);
        1 = listLength(idxs1);
        ndims_str = intString(1) "ndims == 1" ;
        idxs_str = Util.stringDelimitList(idxs1, ", ");
        type_str = expTypeStr(t, true);
        cref1 = Util.stringAppendList(
          {"(*",type_str,"_element_addr1(&",id,", ",ndims_str,", ",
          idxs_str,"))"});
      then
        (cfn1,cref1,tnr1);
    case (t,Exp.CREF_IDENT(ident = id,subscriptLst = idx),tnr,context)
      equation 
        Debug.fprintln("gcge", "generating cref ccode");
        (cfn1,idxs1,tnr1) = generateIndices(idx, tnr, context);
        2 = listLength(idxs1);
        ndims_str = intString(2) "ndims == 2" ;
        idxs_str = Util.stringDelimitList(idxs1, ", ");
        type_str = expTypeStr(t, true);
        cref1 = Util.stringAppendList(
          {"(*",type_str,"_element_addr2(&",id,", ",ndims_str,", ",
          idxs_str,"))"});
      then
        (cfn1,cref1,tnr1);
    case (t,Exp.CREF_IDENT(ident = id,subscriptLst = idx),tnr,context)
      equation 
        Debug.fprintln("gcge", "generating cref ccode");
        (cfn1,idxs1,tnr1) = generateIndices(idx, tnr, context);
        ndims = listLength(idxs1);
        ndims_str = intString(ndims);
        idxs_str = Util.stringDelimitList(idxs1, ", ");
        type_str = expTypeStr(t, true);
        cref1 = Util.stringAppendList(
          {"(*",type_str,"_element_addr(&",id,", ",ndims_str,", ",
          idxs_str,"))"});
      then
        (cfn1,cref1,tnr1);
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_scalar_lhs_cref failed\n");
      then
        fail();
  end matchcontinue;
end generateScalarLhsCref;

protected function generateRhsCref "function: generateRhsCref
 
  Helper function to generate_expression. Generates code 
  for a component reference. It can either be a scalar valued component 
  reference or an array valued component reference. In the later case,
  special code that constructs the runtime object of the array must 
  be generated.
"
  input Exp.ComponentRef inComponentRef;
  input Exp.Type inType;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inComponentRef,inType,inInteger,inContext)
    local
      Lib e_tp_str,e_sh_tp_str,vdecl,vstr,ndims_str,dims_str,cref_str,stmt,var;
      Integer tnr1,ndims,tnr,tnr_1;
      list<Lib> dims_strs;
      CFunction cfunc,cfn;
      Exp.ComponentRef cref;
      Exp.Type t,crt;
      list<Option<Integer>> dims;
      Context context;
      list<Exp.Subscript> subs;
    case (cref,Exp.T_ARRAY(ty = t,arrayDimensions = dims),tnr,CONTEXT(SIMULATION(),_,_)) /* For context simulation array variables must be boxed 
	    into a real_array object since they are represented only
	    in a double array. */ 
      equation 
        e_tp_str = expTypeStr(t, true);
        e_sh_tp_str = expShortTypeStr(t);
        (vdecl,vstr,tnr1) = generateTempDecl(e_tp_str, tnr);
        ndims = listLength(dims);
        ndims_str = intString(ndims);
        // Assumes that all dimensions are known, i.e. no NONE in dims.
        dims_strs = Util.listMap(Util.listMap1(dims,Util.applyOption, int_string),Util.stringOption);
        dims_str = Util.stringDelimitListNonEmptyElts(dims_strs, ", ");
        (cref_str,_) = compRefCstr(cref);
        stmt = Util.stringAppendList(
          {e_sh_tp_str,"_array_create(&",vstr,", ","&",cref_str,", ",
          ndims_str,", ",dims_str,");"});
        cfunc = cAddStatements(cEmptyFunction, {stmt});
        cfunc = cAddInits(cfunc, {vdecl});
      then
        (cfunc,vstr,tnr1);
                
    case (cref,crt,tnr,context)
      equation 
        (cref_str,{}) = compRefCstr(cref);
      then
        (cEmptyFunction,cref_str,tnr);
    case (cref,crt,tnr,context)
      equation 
        (cref_str,subs) = compRefCstr(cref);
        true = subsToScalar(subs);
        (cfn,var,tnr_1) = generateScalarRhsCref(cref_str, crt, subs, tnr, context);
      then
        (cfn,var,tnr_1);
    case (cref,crt,tnr,context) /* array expressions */ 
      equation 
        (cref_str,subs) = compRefCstr(cref);
        false = subsToScalar(subs);
        (cfn,var,tnr_1) = generateArrayRhsCref(cref_str, crt, subs, tnr, context);
      then
        (cfn,var,tnr_1);
  end matchcontinue;
end generateRhsCref;

protected function subsToScalar "function: subsToScalar
 
  Returns true if subscript results applied to variable or expression 
  results in scalar expression.
"
  input list<Exp.Subscript> inExpSubscriptLst;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inExpSubscriptLst)
    local
      Boolean b;
      list<Exp.Subscript> r;
    case {} then true; 
    case (Exp.SLICE(exp = _) :: _) then false; 
    case (Exp.WHOLEDIM() :: _) then false; 
    case (Exp.INDEX(exp = _) :: r)
      equation 
        b = subsToScalar(r);
      then
        b;
  end matchcontinue;
end subsToScalar;

protected function generateScalarRhsCref "function: generateScalarRhsCref
 
  Helper function to generate_algorithm_statement.
"
  input String inString;
  input Exp.Type inType;
  input list<Exp.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inString,inType,inExpSubscriptLst,inInteger,inContext)
    local
      CFunction cfn1;
      list<Lib> idxs1;
      Integer tnr1,tnr,ndims;
      Lib ndims_str,idxs_str,array_type_str,cref1,cref_str;
      Exp.Type crt;
      list<Exp.Subscript> subs;
      Context context;
    case (cref_str,crt,subs,tnr,context) /* Two special rules for faster code when ndims == 1 or 2 */ 
      equation 
        (cfn1,idxs1,tnr1) = generateIndices(subs, tnr, context);
        1 = listLength(idxs1);
        ndims_str = intString(1) "ndims == 1" ;
        idxs_str = Util.stringDelimitList(idxs1, ", ");
        array_type_str = expTypeStr(crt, true);
        cref1 = Util.stringAppendList(
          {"(*",array_type_str,"_element_addr1(&",cref_str,", ",
          ndims_str,", ",idxs_str,"))"});
      then
        (cfn1,cref1,tnr1);
    case (cref_str,crt,subs,tnr,context)
      equation 
        (cfn1,idxs1,tnr1) = generateIndices(subs, tnr, context);
        2 = listLength(idxs1);
        ndims_str = intString(2) "ndims == 2" ;
        idxs_str = Util.stringDelimitList(idxs1, ", ");
        array_type_str = expTypeStr(crt, true);
        cref1 = Util.stringAppendList(
          {"(*",array_type_str,"_element_addr2(&",cref_str,", ",
          ndims_str,", ",idxs_str,"))"});
      then
        (cfn1,cref1,tnr1);
    case (cref_str,crt,subs,tnr,context)
      equation 
        (cfn1,idxs1,tnr1) = generateIndices(subs, tnr, context);
        ndims = listLength(idxs1);
        ndims_str = intString(ndims);
        idxs_str = Util.stringDelimitList(idxs1, ", ");
        array_type_str = expTypeStr(crt, true);
        cref1 = Util.stringAppendList(
          {"(*",array_type_str,"_element_addr(&",cref_str,", ",
          ndims_str,", ",idxs_str,"))"});
      then
        (cfn1,cref1,tnr1);
    case (cref_str,crt,subs,tnr,context)
      equation 
        Debug.fprint("failtrace", "-generate_scalar_rhs_cref failed\n");
      then
        fail();
  end matchcontinue;
end generateScalarRhsCref;

protected function generateArrayRhsCref "function: generateArrayRhsCref
 
  Helper function to generate_rhs_cref.
"
  input String inString;
  input Exp.Type inType;
  input list<Exp.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inString,inType,inExpSubscriptLst,inInteger,inContext)
    local
      CFunction cfn1,cfn_1,cfn;
      Lib spec1,array_type_str,decl,temp,stmt,cref_str;
      Integer tnr1,tnr2,tnr;
      Exp.Type crt;
      list<Exp.Subscript> subs;
      Context context;
    case (cref_str,crt,subs,tnr,context)
      equation 
        (cfn1,spec1,tnr1) = generateIndexSpec(subs, tnr, context);
        array_type_str = expTypeStr(crt, true);
        (decl,temp,tnr2) = generateTempDecl(array_type_str, tnr1);
        stmt = Util.stringAppendList(
          {"index_alloc_",array_type_str,"(&",cref_str,", &",spec1,
          ", &",temp,");"});
        cfn_1 = cAddVariables(cfn1, {decl});
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,temp,tnr2);
  end matchcontinue;
end generateArrayRhsCref;

protected function generateIndexSpec "function: generateIndexSpec
 
  Helper function to generate_algorithm_statement.
"
  input list<Exp.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inExpSubscriptLst,inInteger,inContext)
    local
      CFunction cfn1,cfn_1,cfn;
      list<Lib> idxs1,idxsizes,idxs_1,idxTypes;
      Integer tnr1,tnr2,nridx,tnr;
      Lib decl,spec,nridx_str,idxs_str,stmt;
      list<Exp.Subscript> subs;
      Context context;
    case (subs,tnr,context)
      equation 
        (cfn1,idxs1,idxsizes,idxTypes,tnr1) = generateIndicesArray(subs, tnr, context);
        (decl,spec,tnr2) = generateTempDecl("index_spec_t", tnr1);
        nridx = listLength(idxs1);
        nridx_str = intString(nridx);
        idxs_1 = Util.listThread3(idxsizes, idxs1,idxTypes);
        idxs_str = Util.stringDelimitList(idxs_1, ", ");
        stmt = Util.stringAppendList(
          {"create_index_spec(&",spec,", ",nridx_str,", ",idxs_str,
          ");"});
        cfn_1 = cAddVariables(cfn1, {decl});
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,spec,tnr2);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_index_spec failed\n");
      then
        fail();
  end matchcontinue;
end generateIndexSpec;

protected function generateIndicesArray "
  Helper function to generateIndicesArray
"
  input list<Exp.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction1;
  output list<String> outStringLst2;
  output list<String> outStringLst3;
  output list<String> outStringLst4;
  output Integer outInteger4;
algorithm 
  (outCFunction1,outStringLst2,outStringLst3,outSTringLst4,outInteger4):=
  matchcontinue (inExpSubscriptLst,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      Lib idx1,idxsize1,indxType;
      list<Lib> idxs2,idxsizes2,idxs,idxsizes,indxTypeLst1,indxTypeLst2;
      Exp.Subscript f;
      list<Exp.Subscript> r;
    case ({},tnr,context) then (cEmptyFunction,{},{},{},tnr); 
    case ((f :: r),tnr,context)
      equation 
        (cfn1,idx1,idxsize1,indxType,tnr1) = generateIndexArray(f, tnr, context);
        (cfn2,idxs2,idxsizes2,indxTypeLst1,tnr2) = generateIndicesArray(r, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
        idxs = (idx1 :: idxs2);
        idxsizes = (idxsize1 :: idxsizes2);
        indxTypeLst2 = indxType::indxTypeLst1;
      then
        (cfn,idxs,idxsizes,indxTypeLst2,tnr2);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_indices_array failed\n");
      then
        fail();
  end matchcontinue;
end generateIndicesArray;

protected function generateIndices "function: generateIndices
 
  
"
  input list<Exp.Subscript> inExpSubscriptLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output list<String> outStringLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outStringLst,outInteger):=
  matchcontinue (inExpSubscriptLst,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      Lib idx1;
      list<Lib> idxs2,idxs;
      Exp.Subscript f;
      list<Exp.Subscript> r;
    case ({},tnr,context) then (cEmptyFunction,{},tnr); 
    case ((f :: r),tnr,context)
      equation 
        (cfn1,idx1,tnr1) = generateIndex(f, tnr, context);
        (cfn2,idxs2,tnr2) = generateIndices(r, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
        idxs = (idx1 :: idxs2);
      then
        (cfn,idxs,tnr2);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_indices failed\n");
      then
        fail();
  end matchcontinue;
end generateIndices;

protected function generateIndexArray "
  Helper function to generateIndicesArray
"
  input Exp.Subscript inSubscript;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction1;
  output String outString2;
  output String outString3;
  output String outString4;
  output Integer outInteger4;
algorithm 
  (outCFunction1,outString2,outString3,outString4,outInteger4):=
  matchcontinue (inSubscript,inInteger,inContext)
    local
      CFunction cfn,cfn_1,cfn_2;
      Lib var1,idx,idxsize,decl,tvar,stmt;
      Integer tnr1,tnr,tnr2;
      Exp.Exp e;
      Context context;
      // Scalar index
    case (Exp.INDEX(exp = e),tnr,context)
      equation 
        (cfn,var1,tnr1) = generateExpression(e, tnr, context);
        idx = Util.stringAppendList({"make_index_array(1, ",var1,")"});
        idxsize = "(1)";
      then
        (cfn,idx,idxsize,"'S'",tnr1);
        // Whole dimension, ':'
    case (Exp.WHOLEDIM(),tnr,context)
      equation 
        idx = "(0)";
        idxsize = "(1)";
      then
        (cEmptyFunction,idx,idxsize,"'W'",tnr);
        
        // Slice, e.g A[{1,3,5}]
    case (Exp.SLICE(exp = e),tnr,context)
      equation 
        (cfn,var1,tnr1) = generateExpression(e, tnr, context);
        (decl,tvar,tnr2) = generateTempDecl("modelica_integer", tnr1);
        stmt = Util.stringAppendList({tvar,"=size_of_dimension_integer_array(",var1,",1);"});
        cfn_1 = cAddStatements(cfn, {stmt});
        cfn_2 = cAddVariables(cfn_1, {decl});
        idx = Util.stringAppendList({"integer_array_make_index_array(&",var1,")"});
        idxsize = tvar;
      then
        (cfn_2,idx,idxsize,"'A'",tnr2);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_index_array failed\n");
      then
        fail();
  end matchcontinue;
end generateIndexArray;

protected function generateIndex "function: generateIndex
 
  Helper function to generate_index_array.
"
  input Exp.Subscript inSubscript;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inSubscript,inInteger,inContext)
    local
      CFunction cfn;
      Lib var1;
      Integer tnr1,tnr;
      Exp.Exp e;
      Context context;
    case (Exp.INDEX(exp = e),tnr,context)
      equation 
        (cfn,var1,tnr1) = generateExpression(e, tnr, context);
      then
        (cfn,var1,tnr1);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_index failed\n");
      then
        fail();
  end matchcontinue;
end generateIndex;

protected function indentStrings "function: indentStrings
 
  Adds a two space indentation to each string in a string list.
"
  input list<String> inStringLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inStringLst)
    local
      Lib f_1,f;
      list<Lib> r_1,r;
    case {} then {}; 
    case (f :: r)
      equation 
        f_1 = stringAppend("  ", f);
        r_1 = indentStrings(r);
      then
        (f_1 :: r_1);
  end matchcontinue;
end indentStrings;

protected function compRefCstr "function: compRefCstr
 
  Returns the ComponentRef as a string and the complete Subscript list of
  the ComponentRef.
"
  input Exp.ComponentRef inComponentRef;
  output String outString;
  output list<Exp.Subscript> outExpSubscriptLst;
algorithm 
  (outString,outExpSubscriptLst):=
  matchcontinue (inComponentRef)
    local
      Lib id,cref_str,cref_str_1;
      list<Exp.Subscript> subs,cref_subs,subs_1;
      Exp.ComponentRef cref;
    case Exp.CREF_IDENT(ident = id,subscriptLst = subs) then (id,subs); 
    case Exp.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref)
      equation 
        (cref_str,cref_subs) = compRefCstr(cref);
        cref_str_1 = Util.stringAppendList({id,"__",cref_str});
        subs_1 = Util.listFlatten({subs,cref_subs});
      then
        (cref_str_1,subs_1);
  end matchcontinue;
end compRefCstr;

protected function generateLbinary "function: generateLbinary
  
  Generates code for logical binary expressions.
  returns:
  CFunction | the generated code
  string    | expression result 
  int       | next temporary number 
"
  input Exp.Exp inExp1;
  input Exp.Operator inOperator2;
  input Exp.Exp inExp3;
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inExp1,inOperator2,inExp3,inInteger4,inContext5)
    local
      CFunction cfn1,cfn2,cfn;
      Lib var1,var2,var;
      Integer tnr1,tnr2,tnr;
      Exp.Exp e1,e2;
      Context context;
    case (e1,Exp.AND(),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," && ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.OR(),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," || ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_lbinary failed\n");
      then
        fail();
  end matchcontinue;
end generateLbinary;

protected function generateLunary "function: generateLunary
  
  Generates code for logical unary expressions.
  returns:
  CFunction | the generated code
  string    | expression result 
  int       | next temporary number 
"
  input Exp.Operator inOperator;
  input Exp.Exp inExp;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inOperator,inExp,inInteger,inContext)
    local
      CFunction cfn1;
      Lib var1,var;
      Integer tnr1,tnr;
      Exp.Exp e;
      Context context;
    case (Exp.NOT(),e,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e, tnr, context);
        var = Util.stringAppendList({"(!",var1,")"});
      then
        (cfn1,var,tnr1);
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_lbinary failed\n");
      then
        fail();
  end matchcontinue;
end generateLunary;

protected function generateRelation "function: generateRelation
  
  Generates code for function expressions.
  returns:
  CFunction | the generated code
  string    | expression result 
  int       | next temporary number 
"
  input Exp.Exp inExp1;
  input Exp.Operator inOperator2;
  input Exp.Exp inExp3;
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inExp1,inOperator2,inExp3,inInteger4,inContext5)
    local
      CFunction cfn1,cfn2,cfn;
      Lib var1,var2,var;
      Integer tnr1,tnr2,tnr;
      Exp.Exp e1,e2;
      Context context;
    case (e1,Exp.LESS(ty = Exp.BOOL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(!",var1," && ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.LESS(ty = Exp.STRING()),e2,tnr,context)
      equation 
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,Exp.LESS(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," < ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.LESS(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," < ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.GREATER(ty = Exp.BOOL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," && !",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.GREATER(ty = Exp.STRING()),e2,tnr,context)
      equation 
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,Exp.GREATER(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," > ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.GREATER(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," > ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.LESSEQ(ty = Exp.BOOL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(!",var1," || ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.LESSEQ(ty = Exp.STRING()),e2,tnr,context)
      equation 
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,Exp.LESSEQ(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," <= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.LESSEQ(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," <= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.GREATEREQ(ty = Exp.BOOL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," || !",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.GREATEREQ(ty = Exp.STRING()),e2,tnr,context)
      equation 
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,Exp.GREATEREQ(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," >= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.GREATEREQ(ty = Exp.REAL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," >= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.EQUAL(ty = Exp.BOOL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"((!",var1," && !",var2,") || (",var1," && ",var2,"))"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.EQUAL(ty = Exp.STRING()),e2,tnr,context)
      equation 
        Print.printBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,Exp.EQUAL(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," == ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.EQUAL(ty = Exp.REAL()),e2,tnr,context)
      equation 
        Print.printErrorBuf("# Reals can't be compared with ==\n");
      then
        fail();
    case (e1,Exp.NEQUAL(ty = Exp.BOOL()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"((!",var1," && ",var2,") || (",var1," && !",var2,"))"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.NEQUAL(ty = Exp.STRING()),e2,tnr,context)
      equation 
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,Exp.NEQUAL(ty = Exp.INT()),e2,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," != ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,Exp.NEQUAL(ty = Exp.REAL()),e2,tnr,context)
      equation 
        Debug.fprint("failtrace", "# Reals can't be compared with <>\n");
      then
        fail();
    case (_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "# generate_relation failed\n");
      then
        fail();
  end matchcontinue;
end generateRelation;

protected function generateMatrix "function: generateMatrix
 
  Generates code for matrix expressions.
"
  input Exp.Type inType1;
  input Integer inInteger2;
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst3;
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inType1,inInteger2,inTplExpExpBooleanLstLst3,inInteger4,inContext5)
    local
      CFunction cfn1,cfn2,cfn_1,cfn_2,cfn;
      list<list<Lib>> vars1;
      Integer tnr1,tnr2,n,tnr3,maxn,tnr;
      list<Lib> vars2;
      Lib array_type_str,args_str,n_str,tdecl,tvar,stmt;
      Exp.Type typ;
      list<list<tuple<Exp.Exp, Boolean>>> exps;
      Context context;
    case (typ,maxn,exps,tnr,context)
      equation 
        (cfn1,vars1,tnr1) = generateMatrixExpressions(typ, exps, maxn, tnr, context);
        (cfn2,vars2,tnr2) = concatenateMatrixRows(typ, vars1, tnr1, context);
        array_type_str = expTypeStr(typ, true);
        args_str = Util.stringDelimitList(vars2, ", &");
        n = listLength(vars2);
        n_str = intString(n);
        (tdecl,tvar,tnr3) = generateTempDecl(array_type_str, tnr2);
        stmt = Util.stringAppendList(
          {"cat_alloc_",array_type_str,"(1, &",tvar,", ",n_str,", &",
          args_str,");"});
        cfn_1 = cAddVariables(cfn2, {tdecl});
        cfn_2 = cAddStatements(cfn_1, {stmt});
        cfn = cMergeFn(cfn1, cfn_2) "
	 Generate code for every expression and
	 promote it to maxn dimensions
	 for every row create cat(2,rowvar1,....)
	 for every column create cat(1,row1,....)
	" ;
      then
        (cfn,tvar,tnr3);
  end matchcontinue;
end generateMatrix;

protected function concatenateMatrixRows "function: contatenate_matrix_rows
 
  Helper function to generate_matrix.
"
  input Exp.Type inType;
  input list<list<String>> inStringLstLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output list<String> outStringLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outStringLst,outInteger):=
  matchcontinue (inType,inStringLstLst,inInteger,inContext)
    local
      Integer tnr,tnr1,tnr2;
      Context context;
      CFunction cfn1,cfn2,cfn;
      Lib var1;
      list<Lib> vars2,f;
      Exp.Type typ;
      list<list<Lib>> r;
    case (_,{},tnr,context) then (cEmptyFunction,{},tnr); 
    case (typ,(f :: r),tnr,context)
      equation 
        (cfn1,var1,tnr1) = concatenateMatrixRow(typ, f, tnr, context);
        (cfn2,vars2,tnr2) = concatenateMatrixRows(typ, r, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,(var1 :: vars2),tnr2);
  end matchcontinue;
end concatenateMatrixRows;

protected function concatenateMatrixRow "function: contatenate_matrix_row
 
  Helper function to concatenateMatrixRows
"
  input Exp.Type inType;
  input list<String> inStringLst;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inType,inStringLst,inInteger,inContext)
    local
      Lib array_type_str,args_str,n_str,tdecl,tvar,stmt;
      Integer n,tnr1,tnr;
      CFunction cfn_1,cfn;
      Exp.Type typ;
      list<Lib> vars;
      Context context;
    case (typ,vars,tnr,context)
      equation 
        array_type_str = expTypeStr(typ, true);
        args_str = Util.stringDelimitList(vars, ", &");
        n = listLength(vars);
        n_str = intString(n);
        (tdecl,tvar,tnr1) = generateTempDecl(array_type_str, tnr);
        stmt = Util.stringAppendList(
          {"cat_alloc_",array_type_str,"(2, &",tvar,", ",n_str,", &",
          args_str,");"});
        cfn_1 = cAddVariables(cEmptyFunction, {tdecl});
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tvar,tnr1);
  end matchcontinue;
end concatenateMatrixRow;

protected function generateMatrixExpressions "function: generateMatrixExpressions
 
  Helper function to generate_matrix.
"
  input Exp.Type inType1;
  input list<list<tuple<Exp.Exp, Boolean>>> inTplExpExpBooleanLstLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output list<list<String>> outStringLstLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outStringLstLst,outInteger):=
  matchcontinue (inType1,inTplExpExpBooleanLstLst2,inInteger3,inInteger4,inContext5)
    local
      Integer tnr,tnr1,tnr2,maxn;
      Context context;
      CFunction cfn1,cfn2,cfn;
      list<Lib> vars1;
      list<list<Lib>> vars2;
      Exp.Type typ;
      list<tuple<Exp.Exp, Boolean>> fr;
      list<list<tuple<Exp.Exp, Boolean>>> rr;
    case (_,{},_,tnr,context) then (cEmptyFunction,{},tnr); 
    case (typ,(fr :: rr),maxn,tnr,context)
      equation 
        (cfn1,vars1,tnr1) = generateMatrixExprRow(typ, fr, maxn, tnr, context);
        (cfn2,vars2,tnr2) = generateMatrixExpressions(typ, rr, maxn, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,(vars1 :: vars2),tnr2);
  end matchcontinue;
end generateMatrixExpressions;

protected function generateMatrixExprRow "function: generateMatrixExprRow
 
  Helper function to generate_matrix_expressions.
"
  input Exp.Type inType1;
  input list<tuple<Exp.Exp, Boolean>> inTplExpExpBooleanLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output list<String> outStringLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outStringLst,outInteger):=
  matchcontinue (inType1,inTplExpExpBooleanLst2,inInteger3,inInteger4,inContext5)
    local
      Integer tnr,tnr1,tnr2,maxn;
      Context context;
      CFunction cfn1,cfn2,cfn;
      Lib var1;
      list<Lib> vars2;
      Exp.Type t;
      tuple<Exp.Exp, Boolean> f;
      list<tuple<Exp.Exp, Boolean>> r;
    case (_,{},_,tnr,context) then (cEmptyFunction,{},tnr); 
    case (t,(f :: r),maxn,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateMatrixExpression(t, f, maxn, tnr, context);
        (cfn2,vars2,tnr2) = generateMatrixExprRow(t, r, maxn, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,(var1 :: vars2),tnr2);
  end matchcontinue;
end generateMatrixExprRow;

protected function generateMatrixExpression "function: generateMatrixExpression.
 
  Helper function to generate_matrix_expressions.
"
  input Exp.Type inType1;
  input tuple<Exp.Exp, Boolean> inTplExpExpBoolean2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Context inContext5;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm 
  (outCFunction,outString,outInteger):=
  matchcontinue (inType1,inTplExpExpBoolean2,inInteger3,inInteger4,inContext5)
    local
      CFunction cfn1,cfn_1,cfn;
      Lib var1,array_type_str,maxn_str,tdecl,tvar,scalar,sc_ref,stmt;
      Integer tnr1,tnr2,maxn,tnr;
      Exp.Type t;
      Exp.Exp e;
      Boolean b;
      Context context;
    case (t,(e,b),maxn,tnr,context)
      equation 
        (cfn1,var1,tnr1) = generateExpression(e, tnr, context);     
        array_type_str = expTypeStr(t, true);
        maxn_str = intString(maxn);
        (tdecl,tvar,tnr2) = generateTempDecl(array_type_str, tnr1);
        scalar = Util.if_(b, "scalar_", "");
        sc_ref = Util.if_(b, "", "&");
        stmt = Util.stringAppendList(
          {"promote_",scalar,array_type_str,"(",sc_ref,var1,", 2, &",
          tvar,");"});
        cfn_1 = cAddVariables(cfn1, {tdecl});
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tvar,tnr2);
        
  end matchcontinue;
end generateMatrixExpression;

protected function generateReadCallWrite "function  generateReadCallWrite
  
  Generates code for reading input parameters from file, executing function
  and writing result to file.
"
  input String fnname;
  input list<DAE.Element> outvars;
  input String retstr;
  input list<DAE.Element> invars;
  output CFunction cfn;
  Lib rcw_fnname,out_decl,in_args,fn_call;
  CFunction cfn1,cfn1_1,cfn31,cfn32,cfn3,cfn3_1,cfn4,cfn4_1,cfn5,cfn5_1;
  Integer tnr21,tnr2;
  list<Lib> in_names;
algorithm 
  Debug.fprintln("cgtr", "generate_read_call_write");
  rcw_fnname := stringAppend(fnname, "_read_call_write");
  cfn1 := cMakeFunction("int", rcw_fnname, {}, 
          {"char const* in_filename","char const* out_filename"});
  out_decl := Util.stringAppendList({retstr," out;"});
  cfn1_1 := cAddInits(cfn1, {"PRE_VARIABLES",out_decl});
  (cfn31,tnr21) := generateVarDecls(invars, isRcwInput, 1, funContext) "generate_vars(outvars,is_rcw_output,1) => (cfn2,tnr1) &" ;
  (cfn32,tnr2) := generateVarInits(invars, isRcwInput, 1,tnr21, "", funContext);
  cfn3 := cMergeFns({cfn31,cfn32});
  cfn3_1 := cAddInits(cfn3, {"PRE_OPEN_INFILE"});
  in_names := invarNames(invars);
  in_args := Util.stringDelimitList(in_names, ", ");
  cfn4 := generateRead(invars);
  fn_call := Util.stringAppendList({"out = ",fnname,"(",in_args,");"});
  cfn4_1 := cAddStatements(cfn4, {"PRE_READ_DONE",fn_call,"PRE_OPEN_OUTFILE"});
  cfn5 := generateWriteOutvars(outvars,1);
  cfn5_1 := cAddStatements(cfn5, {"PRE_WRITE_DONE","return 0;"});
  cfn := cMergeFns({cfn1_1,cfn3_1,cfn4_1,cfn5_1});
end generateReadCallWrite;

protected function generateExternalWrapperCall "function: generateExternalWrapperCall
 
  This function generates the wrapper function for external functions
  when used in e.g. simulation code.
"
  input String inString1;
  input list<DAE.Element> inDAEElementLst2;
  input String inString3;
  input list<DAE.Element> inDAEElementLst4;
  input DAE.ExternalDecl inExternalDecl5;
  input list<DAE.Element> inDAEElementLst6;
  input Types.Type inType7;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inString1,inDAEElementLst2,inString3,inDAEElementLst4,inExternalDecl5,inDAEElementLst6,inType7)
    local
      Integer tnr,tnr_invars1,tnr_invars,tnr_bivars1,tnr_bivars,tnr_extcall;
      list<Lib> arg_strs;
      CFunction cfn1,cfn1_1,cfn31,cfn32,cfn33,cfn34,cfn3,extcall,cfn_1,cfn;
      Lib out_decl,fnname,retstr,extfnname,lang;
      list<DAE.Element> vars_1,vars,outvars,invars,bivars;
      DAE.ExternalDecl extdecl;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extretarg;
      Option<Absyn.Annotation> ann;
      list<tuple<Lib, tuple<Types.TType, Option<Absyn.Path>>>> args;
      tuple<Types.TType, Option<Absyn.Path>> restype;
    case (fnname,outvars,retstr,invars,(extdecl as DAE.EXTERNALDECL(ident = extfnname,external_ = extargs,parameters = extretarg,returnType = lang,language = ann)),bivars,(Types.T_FUNCTION(funcArg = args,funcResultType = restype),_)) /* function name output variables return type input variables external declaration bidirectional vars function type */ 
      equation 
        tnr = 1;
        arg_strs = Util.listMap(args, generateFunctionArg);
        cfn1 = cMakeFunction(retstr, fnname, {}, arg_strs);
        out_decl = Util.stringAppendList({retstr," out;"});
        cfn1_1 = cAddVariables(cfn1, {out_decl});
        (cfn31,tnr_invars1) = generateVarDecls(invars, isRcwInput, tnr, funContext);
        (cfn32,tnr_invars) = generateVarInits(invars, isRcwInput, 1,tnr_invars1, "", funContext);
        (cfn33,tnr_bivars1) = generateVarDecls(bivars, isRcwBidir, tnr_invars, funContext);
        (cfn34,tnr_bivars) = generateVarInits(bivars, isRcwBidir, 1,tnr_bivars1, "", funContext);
        cfn3 = cMergeFns({cfn1_1,cfn31,cfn32,cfn33,cfn34});
        vars_1 = listAppend(invars, outvars);
        vars = listAppend(vars_1, bivars);
        (extcall,tnr_extcall) = generateExtCall(vars, extdecl, tnr_bivars);
        cfn_1 = cMergeFns({cfn1_1,extcall});
        cfn = cAddCleanups(cfn_1, {"return out;"});
      then
        cfn;
    case (_,_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_external_wrapper_call failed\n");
      then
        fail();
  end matchcontinue;
end generateExternalWrapperCall;

protected function generateReadCallWriteExternal "function: generateReadCallWriteExternal
 
  Generates code for reading input parameters from file, executing function
  and writing result to file fo external functions.
"
  input String inString1;
  input list<DAE.Element> inDAEElementLst2;
  input String inString3;
  input list<DAE.Element> inDAEElementLst4;
  input DAE.ExternalDecl inExternalDecl5;
  input list<DAE.Element> inDAEElementLst6;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inString1,inDAEElementLst2,inString3,inDAEElementLst4,inExternalDecl5,inDAEElementLst6)
    local
      Integer tnr,tnr_ret,tnr_bialloc_1,tnr_bialloc,tnr_mem,tnr_invars1,tnr_invars,tnr_bivars1,tnr_bivars,tnr_extcall;
      Lib rcw_fnname,out_decl,mem_decl,mem_var,get_mem_stmt,rest_mem_stmt,fnname,retstr;
      CFunction cfn1,cfn1_1,allocstmts_1,allocstmts,biallocstmts,cfnoutinit,cfnoutbialloc,mem_fn_1,mem_fn_2,mem_fn,cfn31,cfn32,cfn33,cfn34,cfn3,cfn3_1,readinvars,readdone,extcall,cfn4_1,cfn5,cfn5_1,cfn_1,cfn;
      list<DAE.Element> vars_1,vars,outvars,invars,bivars;
      DAE.ExternalDecl extdecl;
    case (fnname,outvars,retstr,invars,extdecl,bivars) /* function name output variables return type input variables external declaration bidirectional vars */ 
      equation 
        Debug.fprintln("cgtr", "generate_read_call_write_external");
        tnr = 1;
        rcw_fnname = stringAppend(fnname, "_read_call_write");
        cfn1 = cMakeFunction("int", rcw_fnname, {}, 
          {"char const* in_filename","char const* out_filename"});
        out_decl = Util.stringAppendList({retstr," out;"});
        cfn1_1 = cAddInits(cfn1, {"PRE_VARIABLES"});
        (allocstmts_1,tnr_ret) = generateAllocOutvarsExt(outvars, "out", 1,tnr, extdecl) "generate_vars(outvars,is_rcw_output,1) => (cfn2,tnr1) &" ;
        allocstmts = cAddVariables(allocstmts_1, {out_decl});
        (biallocstmts,tnr_bialloc_1) = generateAllocOutvarsExt(bivars, "", 1,tnr_ret, extdecl);
        (cfnoutinit,tnr_bialloc) = generateVarInits(outvars, isRcwOutput, 1,tnr_bialloc_1, "out", funContext);
        cfnoutbialloc = cMergeFns({allocstmts,biallocstmts,cfnoutinit});
        (mem_decl,mem_var,tnr_mem) = generateTempDecl("state", tnr_bialloc);
        get_mem_stmt = Util.stringAppendList({mem_var," = get_memory_state();"});
        rest_mem_stmt = Util.stringAppendList({"restore_memory_state(",mem_var,");"});
        mem_fn_1 = cAddVariables(cEmptyFunction, {mem_decl});
        mem_fn_2 = cAddInits(mem_fn_1, {get_mem_stmt});
        mem_fn = cMergeFns({mem_fn_2,cfnoutbialloc});
        (cfn31,tnr_invars1) = generateVarDecls(invars, isRcwInput, tnr_mem, funContext);
        (cfn32,tnr_invars) = generateVarInits(invars, isRcwInput, 1,tnr_invars1, "", funContext);
        (cfn33,tnr_bivars1) = generateVarDecls(bivars, isRcwBidir, tnr_invars, funContext);
        (cfn34,tnr_bivars) = generateVarInits(bivars, isRcwBidir, 1,tnr_bivars1, "", funContext);
        cfn3 = cMergeFns({cfn31,cfn32,cfn33,cfn34});
        cfn3_1 = cAddInits(cfn3, {"PRE_OPEN_INFILE"});
        readinvars = generateRead(invars);
        readdone = cAddInits(readinvars, {"PRE_READ_DONE"});
        vars_1 = listAppend(invars, outvars);
        vars = listAppend(vars_1, bivars);
        (extcall,tnr_extcall) = generateExtCall(vars, extdecl, tnr_bivars);
        cfn4_1 = cAddStatements(extcall, {"PRE_OPEN_OUTFILE"});
        cfn5 = generateWriteOutvars(outvars,1);
        cfn5_1 = cAddStatements(cfn5, {"PRE_WRITE_DONE"});
        cfn_1 = cMergeFns({cfn1_1,cfn3_1,readdone,mem_fn,cfn4_1,cfn5_1});
        cfn = cAddCleanups(cfn_1, {rest_mem_stmt,"return 0;"});
      then
        cfn;
    case (_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", 
          "#-- generate_read_call_write_external failed\n");
      then
        fail();
  end matchcontinue;
end generateReadCallWriteExternal;

protected function generateExtCall "function: generateExtCall
 
  Helper function to generate_read_call_write_external. Generates the actual
  call to the external function.
"
  input list<DAE.Element> inDAEElementLst;
  input DAE.ExternalDecl inExternalDecl;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,inExternalDecl,inInteger)
    local
      Lib extdeclstr,n,lang;
      CFunction argdecls,fcall,argcopies,extcall;
      list<DAE.ExtArg> arglist_1,outbiarglist,arglist;
      Integer tnr_1,tnr_2,tnr;
      list<DAE.Element> vars;
      DAE.ExternalDecl extdecl;
      DAE.ExtArg retarg;
      Option<Absyn.Annotation> ann;
    case (vars,(extdecl as DAE.EXTERNALDECL(ident = n,external_ = arglist,parameters = retarg,returnType = lang,language = ann)),tnr)
      equation 
        Debug.fcall("cgtrdumpdaeextcall", DAE.dump2, DAE.DAE(vars));
        extdeclstr = DAE.dumpExtDeclStr(extdecl);
        Debug.fprintln("cgtrdumpdaeextcall", extdeclstr);
        (argdecls,arglist_1,tnr_1) = generateExtcallVardecls(vars, arglist, retarg, lang, 1,tnr);
        fcall = generateExtCallFcall(n, arglist_1, retarg, lang);
        outbiarglist = Util.listFilter(arglist_1, isExtargOutputOrBidir);
        (argcopies,tnr_2) = generateExtcallVarcopy(outbiarglist, retarg, lang, 1,tnr_1);
        extcall = cMergeFns({argdecls,fcall,argcopies});
      then
        (extcall,tnr_2);
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_call failed\n");
      then
        fail();
  end matchcontinue;
end generateExtCall;

protected function generateExtcallVardecls "function: generateExtcallVardecls
 
  Helper function to generate_ext_call.
"
  input list<DAE.Element> inDAEElementLst;
  input list<DAE.ExtArg> inDAEExtArgLst;
  input DAE.ExtArg inExtArg;
  input String inString;
  input Integer i "nth tuple elt, only used for output vars";
  input Integer inInteger;
  output CFunction outCFunction;
  output list<DAE.ExtArg> outDAEExtArgLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outDAEExtArgLst,outInteger):=
  matchcontinue (inDAEElementLst,inDAEExtArgLst,inExtArg,inString,i,inInteger)
    local
      CFunction decls,copydecls,res;
      list<DAE.Element> vars;
      list<DAE.ExtArg> args,args_1;
      DAE.ExtArg retarg;
      Integer tnr,tnr_1,tnr_2;
    case (vars,args,retarg,"C",i,tnr)
      equation 
        (decls) = generateExtcallVardecls2(args, retarg,i);
      then
        (decls,args,tnr);
    case (vars,args,retarg,"FORTRAN 77",i,tnr)
      equation 
        (copydecls,tnr_1) = generateExtcallCopydeclsF77(vars, i, tnr);
        (decls,args_1,tnr_2) = generateExtcallVardecls2F77(args, retarg, i, tnr_1);
        res = cMergeFn(copydecls, decls);
      then
        (res,args_1,tnr_2);
    case (_,_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generateExtcallVardecls2 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVardecls;

protected function generateExtcallCopydeclsF77 "function: generateExtcallCopydeclsF77
 
  Helper function to generate_extcall_vardecls
"
  input list<DAE.Element> inDAEElementLst;
  input Integer i "nth tuple elt, only used for outputs";
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEElementLst,i,inInteger)
    local
      Integer tnr,tnr_1,tnr_3;
      Exp.ComponentRef cref,cref_1;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      Option<Exp.Exp> value,start;
      list<Exp.Subscript> dims,dims_1;
      DAE.Element extvar,var;
      CFunction fn,restfn,resfn;
      list<DAE.Element> rest;
      Types.Type tp;
      Boolean b_isOutput;
      Integer i1;
      
    case ({},i,tnr) then (cEmptyFunction,tnr); 
    case ((var :: rest),i,tnr)
      equation 
        DAE.VAR(componentRef = cref,varible = vk,variable = vd,input_ = ty,one = value,binding = dims,dimension = start,fullType=tp) = var;
        true = isArray(var);
        b_isOutput = isOutput(var);
        i1 = Util.if_(b_isOutput,i+1,i);
        cref_1 = varNameExternalCref(cref);
        dims_1 = listReverse(dims);
        extvar = DAE.VAR(cref_1,vk,vd,ty,value,dims_1,NONE,DAE.NON_FLOW(),{},NONE,
          NONE,Absyn.UNSPECIFIED(),tp);
        (fn,tnr_1) = generateVarDecl(extvar, tnr, funContext);
        (restfn,tnr_3) = generateExtcallCopydeclsF77(rest, i1,tnr_1);
        resfn = cMergeFn(fn, restfn);
      then
        (resfn,tnr_3);
    case ((var :: rest),i,tnr)
      equation 
        Debug.fprint("cgtr", "#--Ignoring: ");
        Debug.fcall("cgtr", DAE.dump2, DAE.DAE({var}));
        Debug.fprintln("cgtr", "");
        (fn,tnr_1) = generateExtcallCopydeclsF77(rest,i, tnr);
      then
        (fn,tnr_1);
  end matchcontinue;
end generateExtcallCopydeclsF77;

protected function generateExtcallVardecls2 "function: generateExtcallVardecls2
 
  Helper function to generate_extcall_vardecls
"
  input list<DAE.ExtArg> inDAEExtArgLst;
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt, only used for outputs";
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inDAEExtArgLst,inExtArg,i)
    local
      CFunction retdecl,decl,decls,res;
      DAE.ExtArg retarg,var;
      list<DAE.ExtArg> rest;
      Boolean isOutput;
      Integer i1;
    case ({},DAE.NOEXTARG(),i) then cEmptyFunction; 
    case ({},retarg,i)
      equation 
        retdecl = generateExtcallVardecl(retarg,i);
      then
        retdecl;
    case ((var :: rest),retarg,i)
      equation 
        decl = generateExtcallVardecl(var,i);
        isOutput = isOutputExtArg(var);
        i1 = Util.if_(isOutput,i+1,i);
        decls = generateExtcallVardecls2(rest, retarg, i1);
        res = cMergeFn(decl, decls);
      then
        res;
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_extcall_vardecls2 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVardecls2;

protected function generateVardeclFunc "function: generateVardeclFunc
 
  Helper function to generate_extcall_vardecl.
"
  input String inString1;
  input String inString2;
  input Option<String> inStringOption3;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inString1,inString2,inStringOption3)
    local
      Lib str,str3,tystr,name,expr;
      CFunction f1,res;
    case (tystr,name,SOME(expr))
      equation 
        str = Util.stringAppendList({tystr," ",name,";"});
        f1 = cAddVariables(cEmptyFunction, {str});
        str3 = Util.stringAppendList({name," = (",tystr,")",expr,";"});
        res = cAddStatements(f1, {str3});
      then
        res;
    case (tystr,name,NONE)
      equation 
        str = Util.stringAppendList({tystr," ",name,";"});
        res = cAddVariables(cEmptyFunction, {str});
      then
        res;
  end matchcontinue;
end generateVardeclFunc;

protected function generateExtcallVardecl "function: generateExtcallVardecl
 
  Helper function to generate_extcall_vardecls.
"
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt, only used for outputs";
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inExtArg,i)
    local
      Exp.ComponentRef cref,cr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Lib tystr,name,orgname;
      CFunction res;
      DAE.ExtArg arg;
      Types.Attributes attr;
      Exp.Exp exp;

      /* INPUT NON-ARRAY */ 
    case (arg,i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = Types.ATTR(direction = Absyn.INPUT()),type_ = ty) = arg;
        false = Types.isArray(ty);
        false = Types.isString(ty);
        tystr = generateTypeExternal(ty);
        name = varNameExternal(cref);
        (orgname,_) = compRefCstr(cref);
        res = generateVardeclFunc(tystr, name, SOME(orgname));
      then
        res;
        /* INPUT NON-ARRAY STRING do nothing INPUT ARRAY */ 
    case (arg,i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = Types.ATTR(direction = Absyn.INPUT()),type_ = ty) = arg;
        true = Types.isArray(ty);
      then
        cEmptyFunction;
        
        /* OUTPUT NON-ARRAY */ 
    case (arg, i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = Types.ATTR(direction = Absyn.OUTPUT()),type_ = ty) = arg;
        false = Types.isArray(ty);
        tystr = generateTypeExternal(ty);
        name = varNameExternal(cref);
        res = generateVardeclFunc(tystr, name, NONE);
      then
        res;

        /* OUTPUT ARRAY */ 
    case (arg, i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = Types.ATTR(direction = Absyn.OUTPUT()),type_ = ty) = arg;
        true = Types.isArray(ty);
      then
        cEmptyFunction;
    case (DAE.EXTARG(componentRef = cr,attributes = attr,type_ = ty),i) then cEmptyFunction;       
    case (DAE.EXTARGEXP(exp = exp,type_ = ty),i) then cEmptyFunction; 
    case (DAE.EXTARGSIZE(componentRef = _),i) then cEmptyFunction;  /* SIZE */ 
    case (_,i)
      equation 
        Debug.fprint("failtrace", "#-- generate_extcall_vardecl failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVardecl;

protected function generateExtcallVardecls2F77 "function: generateExtcallVardecls2F77
 
  Helper function to generate_extcall_vardecls
"
  input list<DAE.ExtArg> inDAEExtArgLst;
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt, only for outputs";
  input Integer inInteger;
  output CFunction outCFunction;
  output list<DAE.ExtArg> outDAEExtArgLst;
  output Integer outInteger;
algorithm 
  (outCFunction,outDAEExtArgLst,i,outInteger):=
  matchcontinue (inDAEExtArgLst,inExtArg,inInteger)
    local
      Integer tnr,tnr_1,tnr_2,i2;
      CFunction retdecl,decl,decls,res;
      DAE.ExtArg retarg,var_1,var;
      list<DAE.ExtArg> varr,rest;
    case ({},DAE.NOEXTARG(),i,tnr) then (cEmptyFunction,{},tnr); 
    case ({},retarg,i,tnr)
      equation 
        (retdecl,_,tnr_1) = generateExtcallVardeclF77(retarg, i,tnr);
      then
        (retdecl,{},tnr_1);
    case ((var :: rest),retarg,i,tnr)
      equation 
        (decl,var_1,tnr_1) = generateExtcallVardeclF77(var, i,tnr);
        i2 = Util.if_(isOutputExtArg(var),i+1,i);
        (decls,varr,tnr_2) = generateExtcallVardecls2F77(rest, retarg, i2, tnr_1);
        res = cMergeFn(decl, decls);
      then
        (res,(var_1 :: varr),tnr_2);
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_extcall_vardecls2_f77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVardecls2F77;

protected function generateCToF77Converter "function: generateCToF77Converter
  
"
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> elty,ty;
      Lib eltystr,str;
    case ((ty as (Types.T_ARRAY(arrayDim = _),_)))
      equation 
        elty = Types.arrayElementType(ty);
        eltystr = generateTypeInternalNamepart(elty);
        str = Util.stringAppendList({"convert_alloc_",eltystr,"_array_to_f77"});
      then
        str;
    case ty
      equation 
        Debug.fprint("failtrace", "#-- generate_c_to_f77_converter failed\n");
      then
        fail();
  end matchcontinue;
end generateCToF77Converter;

protected function generateF77ToCConverter "function: generate_c_to_f77_converter
 
"
  input Types.Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      tuple<Types.TType, Option<Absyn.Path>> elty,ty;
      Lib eltystr,str;
    case ((ty as (Types.T_ARRAY(arrayDim = _),_)))
      equation 
        elty = Types.arrayElementType(ty);
        eltystr = generateTypeInternalNamepart(elty);
        str = Util.stringAppendList({"convert_alloc_",eltystr,"_array_from_f77"});
      then
        str;
    case _
      equation 
        Debug.fprint("failtrace", "#-- generate_f77_to_c_converter failed\n");
      then
        fail();
  end matchcontinue;
end generateF77ToCConverter;

protected function isOutputOrBidir "function: isOutputOrBidir
 
  Returns true if attributes indicates an output or bidirectional variable.
"
  input Types.Attributes attr;
  output Boolean res;
  Boolean outvar,bivar;
algorithm 
  outvar := Types.isOutputAttr(attr);
  bivar := Types.isBidirAttr(attr);
  res := boolOr(outvar, bivar);
end isOutputOrBidir;

protected function generateExtcallVardeclF77 "function: generateExtcallVardeclF77
 
"
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt, only for outputs";
  input Integer inInteger;
  output CFunction outCFunction;
  output DAE.ExtArg outExtArg;
  output Integer outInteger;
algorithm 
  (outCFunction,outExtArg,outInteger):=
  matchcontinue (inExtArg,i,inInteger)
    local
      Exp.ComponentRef cref,cr,tmpcref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      CFunction res,decl;
      DAE.ExtArg arg,extarg,newarg;
      Integer tnr,tnr_1;
      Lib tystr,name,orgname,converter,initstr,tmpname_1,tnrstr,tmpstr,callstr,declstr;
      Exp.Exp exp,dim;
      String iStr;

      /* INPUT NON-ARRAY */ 
    case (arg,i,tnr) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        Debug.fprintln("cgtr", "generate_extcall_vardecl_f77_1");
        true = Types.isInputAttr(attr);
        false = Types.isArray(ty);
        res = generateExtcallVardecl(arg,i);
      then
        (res,arg,tnr);

        /* INPUT ARRAY */         
    case (extarg,i,tnr) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = extarg;
        Debug.fprintln("cgtr", "generate_extcall_vardecl_f77_2");
        true = Types.isInputAttr(attr);
        true = Types.isArray(ty);
        tystr = generateType(ty);
        name = varNameExternal(cref);
        (orgname,_) = compRefCstr(cref);
        converter = generateCToF77Converter(ty);
        initstr = Util.stringAppendList({converter,"(&",orgname,", &",name,");"});
        res = cAddStatements(cEmptyFunction, {initstr});
      then
        (res,extarg,tnr);

        /* OUTPUT NON-ARRAY */         
    case (arg,i,tnr) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        Debug.fprintln("cgtr", "generate_extcall_vardecl_f77_3");
        true = Types.isOutputAttr(attr);
        false = Types.isArray(ty);
        res = generateExtcallVardecl(arg,i);
      then
        (res,arg,tnr);

        /* OUTPUT ARRAY */ 
    case (extarg,i,tnr)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = extarg;
        Debug.fprintln("cgtr", "generate_extcall_vardecl_f77_4");
        true = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        tystr = generateType(ty);
        name = varNameExternal(cref);
        iStr = stringAppend("targ",intString(i));
        converter = generateCToF77Converter(ty);
        initstr = Util.stringAppendList({converter,"(&out.",iStr,", &",name,");"});
        res = cAddStatements(cEmptyFunction, {initstr});
      then
        (res,extarg,tnr);

        /* INPUT/OUTPUT ARRAY */         
    case (arg,i,tnr) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isArray(ty);
        Debug.fprintln("cgtr", "generate_extcall_vardecl_f77_41");
        tystr = generateType(ty);
        name = varNameExternal(cref);
        (orgname,_) = compRefCstr(cref);
         iStr = stringAppend("targ",intString(i));
        converter = generateCToF77Converter(ty);
        initstr = Util.stringAppendList({converter,"(&",orgname,", &",name,");"});
        res = cAddStatements(cEmptyFunction, {initstr});
      then
        (res,arg,tnr);

        /* INPUT/OUTPUT NON-ARRAY */         
    case (arg,i,tnr) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        false = Types.isArray(ty);
        Debug.fprintln("cgtr", "generate_extcall_vardecl_f77_41");
        res = generateExtcallVardecl(arg,i);
      then
        (res,arg,tnr);
        
    case (arg,i,tnr)
      equation 
        DAE.EXTARGEXP(exp = exp,type_ = ty) = arg;
        res = generateExtcallVardecl(arg,i);
      then
        (res,arg,tnr);

        /* SIZE */         
    case (arg,i,tnr) 
      equation 
        DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim) = arg;
        Debug.fprintln("cgtr", "generate_extcall_vardecl_f77_5");
        tmpname_1 = varNameArray(cr, attr,i);
        tnrstr = intString(tnr);
        tnr_1 = tnr + 1;
        tmpstr = Util.stringAppendList({tmpname_1,"_size_",tnrstr});
        tmpcref = Exp.CREF_IDENT(tmpstr,{});
        callstr = generateExtArraySizeCall(arg);
        declstr = Util.stringAppendList({"int ",tmpstr,";"});
        decl = cAddVariables(cEmptyFunction, {declstr});
        callstr = Util.stringAppendList({tmpstr," = ",callstr,";"});
        res = cAddStatements(decl, {callstr});
        newarg = DAE.EXTARGSIZE(tmpcref,attr,ty,dim);
      then
        (res,newarg,tnr_1);
    case (arg,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_extcall_vardecl_f77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVardeclF77;

protected function generateExtCallFcall "function: generateExtCallFcall
  
"
  input Ident inIdent;
  input list<DAE.ExtArg> inDAEExtArgLst;
  input DAE.ExtArg inExtArg;
  input String inString;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inIdent,inDAEExtArgLst,inExtArg,inString)
    local
      Lib fcall2,str,fnname,lang,crstr;
      CFunction res;
      list<DAE.ExtArg> args;
      Exp.ComponentRef cr;
      tuple<Types.TType, Option<Absyn.Path>> ty;

      /* language call without return value */ 
    case (fnname,args,DAE.NOEXTARG(),lang) 
      equation 
        fcall2 = generateExtCallFcall2(fnname, args, lang);
        str = stringAppend(fcall2, ";");
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
      
        /* return value assignment, shouldn\'t happen for arrays */ 
    case (fnname,args,DAE.EXTARG(componentRef = cr,type_ = ty),lang) 
      equation 
        false = Types.isArray(ty);
        fcall2 = generateExtCallFcall2(fnname, args, lang);
        crstr = varNameExternal(cr);
        str = Util.stringAppendList({crstr," = ",fcall2,";"});
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_call_fcall failed\n");
      then
        fail();
  end matchcontinue;
end generateExtCallFcall;

protected function generateExtCallFcall2 "function: generateExtCallFcall2
 
  Helper function to generate_ext_call_fcall
"
  input Ident inIdent;
  input list<DAE.ExtArg> inDAEExtArgLst;
  input String inString;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inIdent,inDAEExtArgLst,inString)
    local
      list<Lib> strlist;
      Lib str,res,n;
      list<DAE.ExtArg> args;
    case (n,args,"C")
      equation 
        strlist = generateExtCallFcallArgs(args,1);
        str = Util.stringDelimitList(strlist, ", ");
        res = Util.stringAppendList({n,"(",str,")"});
      then
        res;
    case (n,args,"FORTRAN 77")
      equation 
        strlist = generateExtCallFcallArgsF77(args,1);
        str = Util.stringDelimitList(strlist, ", ");
        res = Util.stringAppendList({n,"_(",str,")"});
      then
        res;
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_call_fcall2 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtCallFcall2;

protected function generateExtCallFcallArgs "helper function to generateExtCallFcall2"
  input list<DAE.ExtArg> args;
  input Integer i "nth tuple elt, only used for outputs";
  output list<String> strLst;
algorithm
  strLst := matchcontinue(args,i)
  local String str; Integer i1; DAE.ExtArg a; Boolean b;
    case({},i) then {};
    case(a::args,i) equation
      b = isOutputExtArg(a);
      str = generateExtCallFcallArg(a,i);
      i1 = Util.if_(b,i+1,i);
      strLst = generateExtCallFcallArgs(args,i1);
    then str::strLst;    
  end matchcontinue;
end generateExtCallFcallArgs;

protected function generateExtCallFcallArgsF77 "helper function to generateExtCallFcall2"
  input list<DAE.ExtArg> args;
  input Integer i "nth tuple elt, only used for outputs";
  output list<String> strLst;
algorithm
  strLst := matchcontinue(args,i)
  local String str; Integer i1; DAE.ExtArg a; Boolean b;
    case({},i) then {};
    case(a::args,i) equation
      b= isOutputExtArg(a);
      str = generateExtCallFcallArgF77(a,i);
      i1 = Util.if_(b,i+1,i);
      strLst = generateExtCallFcallArgsF77(args,i1);
    then str::strLst;    
  end matchcontinue;
end generateExtCallFcallArgsF77;

protected function generateExtCallFcallArg "function: generateExtCallFcallArg
 
  LS: is_array AND is_string
"
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt, used in outputs";
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg,i)
    local
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Lib res,name,str;
      DAE.ExtArg arg;
      Exp.Exp exp;

      /* INPUT NON-ARRAY NON-STRING */ 
    case (arg,i) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isInputAttr(attr);
        false = Types.isArray(ty);
        false = Types.isString(ty);
        res = varNameExternal(cref);
      then
        res;
        
        /* OUTPUT NON-ARRAY */ 
    case (arg,i) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        false = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        name = varNameExternal(cref);
        res = stringAppend("&", name);
      then
        res;

        /* INPUT/OUTPUT ARRAY */ 
    case (arg,i) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isArray(ty);
        name = varNameArray(cref, attr,i);
        res = stringAppend(name, ".data");
      then
        res;

        /* INPUT/OUTPUT STRING */
		case (arg,i)
		  equation 
		    DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
		    true = Types.isString(ty);
		    (res,_) = compRefCstr(cref);
		  then
		    res;

		    /* INPUT/OUTPUT NON-ARRAY */ 
    case (arg,i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        false = Types.isArray(ty);
        (name,_) = compRefCstr(cref);
        res = stringAppend("&", name);
      then
        res;

    case (arg,i)
      equation 
        DAE.EXTARGEXP(exp = exp,type_ = ty) = arg;
        (_,res,_) = generateExpression(exp, 1, funContext);
      then
        res;

        /* SIZE */ 
    case ((arg as DAE.EXTARGSIZE(componentRef = _)),i) 
      equation 
        str = generateArraySizeCall(arg);
      then
        str;

    case (arg,i)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_call_fcall_arg failed\n");
      then
        fail();
  end matchcontinue;
end generateExtCallFcallArg;

protected function isOutputExtArg "Returns true if external arg is an output argument"
   input DAE.ExtArg extArg;
   output Boolean isOutput;
 algorithm
   isOutput := matchcontinue(extArg)
   local Types.Attributes attr;
     case(DAE.EXTARG(attributes = attr)) equation
        isOutput = Types.isOutputAttr(attr);
      then isOutput;
     case(_) then false;
   end matchcontinue;
end isOutputExtArg;

protected function generateExtCallFcallArgF77 "function: generateExtCallFcallArgF77
 
"
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt, only for outputs";
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg,i)
    local
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Lib name,res;
      DAE.ExtArg arg;
      Exp.Exp exp,dim;

      /* INPUT NON-ARRAY */ 
    case (arg,i) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isInputAttr(attr);
        false = Types.isArray(ty);
        name = varNameExternal(cref);
        res = stringAppend("&", name);
      then
        res;

        /* OUTPUT NON-ARRAY */ 
    case(arg,i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isOutputAttr(attr);
        false = Types.isArray(ty);
        name = varNameExternal(cref);
        res = stringAppend("&", name);
      then
        res;
        
        /* INPUT ARRAY */ 
    case (arg,i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isInputAttr(attr);
        true = Types.isArray(ty);
        name = varNameExternal(cref);
        res = stringAppend(name, ".data");
      then
        res;

        /* OUTPUT ARRAY */ 
    case (arg ,i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isOutputAttr(attr);
        true = Types.isArray(ty);
        name = varNameExternal(cref);
        res = stringAppend(name, ".data");
      then
        res;

        /* INPUT/OUTPUT ARRAY */ 
    case (arg,i)
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isArray(ty);
        name = varNameExternal(cref);
        res = stringAppend(name, ".data");
      then
        res;

        /* INPUT/OUTPUT NON-ARRAY */         
    case (arg,i) 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        false = Types.isArray(ty);
        (name,_) = compRefCstr(cref);
        res = stringAppend("&", name);
      then
        res;

    case (arg,i)
      equation 
        DAE.EXTARGEXP(exp = exp,type_ = ty) = arg;
        res = generateExtCallFcallArg(arg,i);
      then
        res;

        /* SIZE */ 
    case (DAE.EXTARGSIZE(componentRef = cref,attributes = attr,type_ = ty,exp = dim), i)
      equation 
        (name,_) = compRefCstr(cref);
        res = stringAppend("&", name);
      then
        res;

    case (arg,i)
      equation 
        Debug.fprint("failtrace", "#-- generate_ext_call_fcall_arg_f77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtCallFcallArgF77;

protected function generateArraySizeCall "function: generateArraySizeCall
 
"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      Lib crstr,dimstr,str;
      Exp.ComponentRef cr;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Exp.Exp dim;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation 
        ((Types.T_INTEGER(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/        
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_integer_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation 
        ((Types.T_REAL(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_real_array(",crstr,", ",dimstr,")"});
      then
        str;
    case _
      equation 
        Debug.fprint("failtrace", 
          "#-- generate_array_size_call failed\n#-- Not a DAE.EXTARGSIZE?\n");
      then
        fail();
  end matchcontinue;
end generateArraySizeCall;

protected function generateExtArraySizeCall "function: generateExtArraySizeCall
 
"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      Lib crstr,dimstr,str;
      Exp.ComponentRef cr;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Exp.Exp dim;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation 
        ((Types.T_INTEGER(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_integer_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation 
        ((Types.T_REAL(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_real_array(",crstr,", ",dimstr,")"});
      then
        str;
    case _
      equation 
        Debug.fprint("failtrace", 
          "#-- generate_array_size_call failed\n#-- Not a DAE.EXTARGSIZE?\n");
      then
        fail();
  end matchcontinue;
end generateExtArraySizeCall;

protected function isExtargOutput "function:  isExtargOutput
 
  Succeeds if variable is external argument and output.
"
  input DAE.ExtArg inExtArg;
algorithm 
  _:=
  matchcontinue (inExtArg)
    case DAE.EXTARG(attributes = Types.ATTR(direction = Absyn.OUTPUT())) then (); 
  end matchcontinue;
end isExtargOutput;

protected function isExtargBidir "function:  is_extarg_output
 
  Succeeds if variable is external argument and bidirectional.
"
  input DAE.ExtArg inExtArg;
algorithm 
  _:=
  matchcontinue (inExtArg)
    case DAE.EXTARG(attributes = Types.ATTR(direction = Absyn.BIDIR())) then (); 
  end matchcontinue;
end isExtargBidir;

protected function isExtargOutputOrBidir "function:  isExtargOutputOrBidir
 
  Succeeds if variable is external argument and output or bidirectional.
"
  input DAE.ExtArg inExtArg;
algorithm 
  _:=
  matchcontinue (inExtArg)
    local DAE.ExtArg arg;
    case arg
      equation 
        isExtargOutput(arg);
      then
        ();
    case arg
      equation 
        isExtargBidir(arg);
      then
        ();
  end matchcontinue;
end isExtargOutputOrBidir;

protected function generateExtcallVarcopy "function: generateExtcallVarcopy
 
"
  input list<DAE.ExtArg> inDAEExtArgLst;
  input DAE.ExtArg inExtArg;
  input String inString;
  input Integer i "nth tuple elt";
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm 
  (outCFunction,outInteger):=
  matchcontinue (inDAEExtArgLst,inExtArg,inString,i,inInteger)
    local
      Integer tnr,tnr_1;
      CFunction retcopy,vc,vcr,res;
      DAE.ExtArg retarg,var;
      Lib lang;
      list<DAE.ExtArg> rest;
    case ({},DAE.NOEXTARG(),_,_,tnr) then (cEmptyFunction,tnr);  /* language */ 
    case ({},retarg,lang,i,tnr)
      equation 
        isExtargOutput(retarg);
        retcopy = generateExtcallVarcopySingle(retarg,i);
      then
        (retcopy,tnr);
    case ({},retarg,lang,i,tnr)
      equation 
        failure(isExtargOutput(retarg));
      then
        (cEmptyFunction,tnr);
        /* extarg list is already filtered and contains only outputs */ 
    case ((var :: rest),retarg,(lang as "C"),i, tnr) 
      equation 
        vc = generateExtcallVarcopySingle(var,i);
        (vcr,tnr_1) = generateExtcallVarcopy(rest, retarg, lang, i+1,tnr);
        res = cMergeFn(vc, vcr);
      then
        (res,tnr_1);
    case ((var :: rest),retarg,(lang as "FORTRAN 77"),i,tnr)
      equation 
        vc = generateExtcallVarcopySingleF77(var,i);
        (vcr,tnr_1) = generateExtcallVarcopy(rest, retarg, lang, i,tnr);
        res = cMergeFn(vc, vcr);
      then
        (res,tnr_1);
    case (_,_,_,_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_extcall_varcopy failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVarcopy;

protected function generateExtcallVarcopySingle "function: generateExtcallVarcopySingle
 
  Helper function to generate_extcall_varcopy
"
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt";
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inExtArg,i)
    local
      Lib name,orgname,typcast,str,iStr;
      CFunction res;
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;      
    case (DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty),i)
      equation 
        false = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        name = varNameExternal(cref);
				iStr = intString(i);	
        typcast = generateType(ty);
        str = Util.stringAppendList({"out.","targ",iStr," = (",typcast,")",name,";"});
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
    case (DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty),i)
      equation 
        true = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
      then
        cEmptyFunction;
    case( DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty),_) then cEmptyFunction; 
    case (_,_)
      equation 
        Debug.fprint("failtrace", "#-- generate_extcall_varcopy_single failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVarcopySingle;

protected function generateExtcallVarcopySingleF77 "function: generateExtcallVarcopySingleF77
 
  Helper function to generate_extcall_varcopy
"
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt";
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inExtArg,i)
    local
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Lib name,orgname,converter,str,typcast,tystr;
      CFunction res;
      DAE.ExtArg extarg;
      String iStr;
    case (extarg,i) /* INPUT ARRAY */ 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = extarg;
        true = Types.isArray(ty);
        true = Types.isInputAttr(attr);
        name = varNameExternal(cref);
        (orgname,_) = compRefCstr(cref);
        converter = generateF77ToCConverter(ty);
        str = Util.stringAppendList({converter,"(&",name,", &",orgname,");"});
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
    case (DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty),i) /* OUTPUT NON-ARRAY */ 
      equation 
        false = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        name = varNameExternal(cref);
				iStr = intString(i);
        typcast = generateType(ty);
        str = Util.stringAppendList({"out.","targ",iStr," = (",typcast,")",name,";"});
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
    case (extarg,i) /* OUTPUT ARRAY */ 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = extarg;
        true = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        tystr = generateType(ty);
        name = varNameExternal(cref);
       	iStr = intString(i);
        converter = generateF77ToCConverter(ty);
        str = Util.stringAppendList({converter,"(&",name,", &out.","targ",iStr,");"});
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
    case (extarg,i) /* BIDIR ARRAY */ 
      equation 
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = extarg;
        true = Types.isArray(ty);
        true = Types.isBidirAttr(attr);
        tystr = generateType(ty);
        name = varNameExternal(cref);
        (orgname,_) = compRefCstr(cref);
        converter = generateF77ToCConverter(ty);
        str = Util.stringAppendList({converter,"(&",name,", &",orgname,");"});
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
    case (DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty),_) then cEmptyFunction; 
    case (_,_)
      equation 
        Debug.fprint("failtrace", 
          "#-- generate_extcall_varcopy_single_f77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtcallVarcopySingleF77;

protected function invarNames "function: invarNames
 
  Returns a string list of all input parameter names.
"
  input list<DAE.Element> inDAEElementLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inDAEElementLst)
    local
      Lib cref_str;
      list<Lib> r_1,cfn;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.Type t;
      list<DAE.Element> r;
    case {} then {}; 
    case (DAE.VAR(componentRef = id,varible = vk,variable = DAE.INPUT(),input_ = t) :: r)
      equation 
        (cref_str,_) = compRefCstr(id);
        r_1 = invarNames(r);
      then
        (cref_str :: r_1);
    case (_ :: r)
      equation 
        cfn = invarNames(r);
      then
        cfn;
  end matchcontinue;
end invarNames;

protected function varNameExternal "function: varNameExternal
 
  Returns the variable name of a variable used in an external function.
"
  input Exp.ComponentRef cref;
  output String str;
  Exp.ComponentRef cref_1;
algorithm 
  cref_1 := varNameExternalCref(cref);
  (str,_) := compRefCstr(cref_1);
end varNameExternal;

protected function varNameExternalCref "function: varNameExternalCref
 
  Helper function to var_name_external.
"
  input Exp.ComponentRef cref;
  output Exp.ComponentRef cref_1;
  Exp.ComponentRef cref_1;
algorithm 
  cref_1 := suffixCref(cref, "_ext");
end varNameExternalCref;

protected function suffixCref "function: suffixCref
 
  Prepends a string, suffix, to a ComponentRef.
"
  input Exp.ComponentRef inComponentRef;
  input String inString;
  output Exp.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef,inString)
    local
      Lib id_1,id,str;
      list<Exp.Subscript> subs;
      Exp.ComponentRef cref_1,cref;
    case (Exp.CREF_IDENT(ident = id,subscriptLst = subs),str)
      equation 
        id_1 = stringAppend(id, str);
      then
        Exp.CREF_IDENT(id_1,subs);
    case (Exp.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref),str)
      equation 
        cref_1 = suffixCref(cref, str);
      then
        Exp.CREF_QUAL(id,subs,cref_1);
  end matchcontinue;
end suffixCref;

protected function varNameArray "function: varNameArray
 
  
"
  input Exp.ComponentRef inComponentRef;
  input Types.Attributes inAttributes;
  input Integer i "nth tuple elt, only used for output vars";
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inAttributes,i)
    local
      Lib str,cref_str,iStr;
      Exp.ComponentRef cref;
      Types.Attributes attr;
    case (cref,attr,i) /* INPUT */ 
      equation 
        (str,_) = compRefCstr(cref);
        true = Types.isInputAttr(attr);
      then
        str;
    case (cref,attr,i) /* OUTPUT */ 
      equation 
				iStr = stringAppend("targ",intString(i));
        true = Types.isOutputAttr(attr);
        str = stringAppend("out.", iStr);
      then
        str;
    case (cref,attr,_) /* BIDIRECTIONAL */ 
      equation 
        (str,_) = compRefCstr(cref);
      then
        str;
  end matchcontinue;
end varNameArray;

protected function varArgNamesExternal "function: varArgNamesExternal
 
"
  input list<DAE.Element> inDAEElementLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inDAEElementLst)
    local
      Lib cref_str,cref_str2;
      list<Lib> r_1,cfn;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.Type t;
      list<DAE.Element> r;
    case {} then {}; 
    case (DAE.VAR(componentRef = id,varible = vk,variable = DAE.INPUT(),input_ = t) :: r)
      equation 
        cref_str = varNameExternal(id);
        r_1 = varArgNamesExternal(r);
      then
        (cref_str :: r_1);
    case (DAE.VAR(componentRef = id,varible = vk,variable = DAE.OUTPUT(),input_ = t) :: r)
      equation 
        cref_str = varNameExternal(id);
        cref_str2 = stringAppend("&", cref_str);
        r_1 = varArgNamesExternal(r);
      then
        (cref_str2 :: r_1);
    case (_ :: r)
      equation 
        cfn = varArgNamesExternal(r);
      then
        cfn;
  end matchcontinue;
end varArgNamesExternal;

protected function generateRead "function: generateRead
 
"
  input list<DAE.Element> inDAEElementLst;
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inDAEElementLst)
    local
      Lib cref_str,type_string,stmt;
      CFunction cfn1,cfn2,cfn;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.Type t;
      list<DAE.Element> r;
    case {} then cEmptyFunction; 
    case (DAE.VAR(componentRef = id,varible = vk,variable = DAE.INPUT(),input_ = t,binding = {}) :: r)
      equation 
        (cref_str,_) = compRefCstr(id);
        type_string = daeTypeStr(t, false);
        stmt = Util.stringAppendList(
          {"if(read_",type_string,"(in_file, &",cref_str,
          ")) return 1;"});
        cfn1 = cAddInits(cEmptyFunction, {stmt});
        cfn2 = generateRead(r);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
    case (DAE.VAR(componentRef = id,varible = vk,variable = DAE.INPUT(),input_ = t,binding = (_ :: _)) :: r)
      equation 
        (cref_str,_) = compRefCstr(id);
        type_string = daeTypeStr(t, true);
        stmt = Util.stringAppendList(
          {"if(read_",type_string,"(in_file, &",cref_str,
          ")) return 1;"});
        cfn1 = cAddInits(cEmptyFunction, {stmt});
        cfn2 = generateRead(r);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
    case (_ :: r)
      equation 
        cfn = generateRead(r);
      then
        cfn;
  end matchcontinue;
end generateRead;

protected function generateWriteOutvars "function: generateWriteOutvars
 
 generates code for writing output variables in return struct to file.
"
  input list<DAE.Element> inDAEElementLst;
  input Integer i "nth tuple elt";
  output CFunction outCFunction;
algorithm 
  outCFunction:=
  matchcontinue (inDAEElementLst,i)
    local
      Lib cref_str,type_string,stmt;
      CFunction cfn1,cfn2,cfn;
      Exp.ComponentRef id;
      DAE.VarKind vk;
      DAE.Type t;
      list<DAE.Element> r;
      String iStr;
    case ({},_) then cEmptyFunction; 
    case (DAE.VAR(componentRef = id,varible = vk,variable = DAE.OUTPUT(),input_ = t,binding = {}) :: r,i)
      equation 
        iStr = intString(i);
        type_string = daeTypeStr(t, false);
        stmt = Util.stringAppendList({"write_",type_string,"(out_file, &out.","targ",iStr,");"});
        cfn1 = cAddStatements(cEmptyFunction, {stmt});
        cfn2 = generateWriteOutvars(r,i+1);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
    case (DAE.VAR(componentRef = id,varible = vk,variable = DAE.OUTPUT(),input_ = t,binding = (_ :: _)) :: r,i)
      equation 
        iStr = intString(i);
        type_string = daeTypeStr(t, true);
        stmt = Util.stringAppendList({"write_",type_string,"(out_file, &out.","targ",iStr,");"});
        cfn1 = cAddStatements(cEmptyFunction, {stmt});
        cfn2 = generateWriteOutvars(r,i+1);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
    case (_ :: r,i)
      equation 
        cfn = generateWriteOutvars(r,i);
      then
        cfn;
  end matchcontinue;
end generateWriteOutvars;

protected function isOutput "Returns true if variable is output"
  input DAE.Element e;
  output Boolean isOutput;
algorithm
  isOutput := matchcontinue(e)
    case(e) equation
      DAE.isOutputVar(e);
    then true;
    case(_) then false;
  end matchcontinue;
end isOutput;

protected function isRcwOutput "function: isRcwOutput
 
"
  input DAE.Element e;
algorithm 
  DAE.isVar(e);
  DAE.isOutputVar(e);
end isRcwOutput;

protected function isRcwInput "function: isRcwInput
 
"
  input DAE.Element e;
algorithm 
  DAE.isVar(e);
  DAE.isInputVar(e);
end isRcwInput;

protected function isRcwBidir "function: isRcwBidir
 
"
  input DAE.Element e;
algorithm 
  DAE.isVar(e);
  DAE.isBidirVar(e);
end isRcwBidir;
end Codegen;




