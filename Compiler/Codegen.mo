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

package Codegen
" file:	 Codegen.mo
  package:      Codegen
  description: Generate C code from DAE (Flat Modelica) for Modelica
  functions. This code is compiled and linked to the simulation code or when
  functions are called from the interactive environment.

  Input: DAE
  Output: -   (generated code through Print module)
  Uses: Print Inst ModUtil Util


  RCS: $Id$

  -------------------------------------------------------------------------"
 
public import Absyn;
public import DAE;
public import MetaUtil;
public import Print;
public import RTOpts;
public import SCode;

public 
type Ident = String;
type ReturnType = String;
type FunctionName = String;
type ArgumentDeclaration = String;
type VariableDeclaration = String;
type InitStatement = String;
type Statement = String;
type CleanupStatement = String;
type ReturnTypeStruct = list<String>;
type Include = String;
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
  record SIMULATION "when generating simulation code"
    Boolean genDiscrete;
  end SIMULATION;
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
protected import Exp;
protected import ModUtil;
protected import Util;
protected import Inst;
protected import Interactive;
protected import System;
protected import Error;
protected import Types;
protected import DAEUtil;

public constant CFunction cEmptyFunction=CFUNCTION("","",{},{},{},{},{},{}) " empty function ";

public constant Context
   funContext = CONTEXT(FUNCTION(),NORMAL(),NO_LOOP()),
   simContext = CONTEXT(SIMULATION(true),NORMAL(),NO_LOOP()),
   extContext = CONTEXT(SIMULATION(true),EXP_EXTERNAL(),NO_LOOP());

public function cMakeFunction 
"function: cMakeFunction
  Helper function to generate_function. Creates a C-function from a
  ReturnType, FunctionName, ReturnTypeStruct and a list of ArgumentDeclarations"
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

protected function cMakeFunctionDecl 
"function: cMakeFunctionDecl
  Helper function to generate_function. Generates a C function declaration.
  I.e. without body of the function."
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

public function cAddVariables 
"function: cAddVariables
  Add local variable declarations  to a CFunction."
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

public function cAddInits 
"function: cAddInits
  Add initialization statements to a CFunction. They will be ommitted before
  the actual code of the function but after the local variable declarations."
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

public function cPrependStatements 
"function: cPrependStatements
  Prepends statements to a CFunction."
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

public function cAddStatements 
"function: cAddStatements
  Adds statements to a CFunction."
  input CFunction inCFunction;
  input list<Statement> inStatementLst;
  output CFunction outCFunction;
algorithm
  outCFunction:=
  matchcontinue (inCFunction,inStatementLst)
    local
      list<Lib> st_1,rts,ads,vd,is,st,cl,nst;
      Lib rt,fn;
    case (CFUNCTION(returnType = rt,
                    functionName = fn,
                    returnTypeStruct = rts,
                    argumentDeclarationLst = ads,
                    variableDeclarationLst = vd,
                    initStatementLst = is,
                    statementLst = st,
                    cleanupStatementLst = cl),nst)
      equation
        st_1 = listAppend(st, nst);
      then
        CFUNCTION(rt,fn,rts,ads,vd,is,st_1,cl);
  end matchcontinue;
end cAddStatements;

public function cAddCleanups 
"function: cAddCleanups
  Add \"cleanup\" statements to a CFunction. 
  They will be ommited last, before
  the return statement of the function."
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

public function cMergeFns 
"function: cMergeFns
  Takes a list of functions and merges them together.
  The function name, returntype and argument lists are taken from the
  first CFunction in the list."
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

protected function cMergeFn 
"function: cMergeFn
  Merges two functions into one. The function name, returntype and
  argument lists are taken from the first CFunction."
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

protected function cMoveStatementsToInits 
"function: cMoveStatementsToInits
  Moves all statements of the body to initialization statements."
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

public function cPrintFunctionsStr 
"function: cPrintFunctionsStr
  Prints CFunction list to a string"
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

protected function cPrintFunctions 
"function: cPrintFunctions
  Prints CFunction list to Print buffer."
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
    case CFUNCTION(returnType = rt,
                   functionName = fn,
                   returnTypeStruct = rts,
                   argumentDeclarationLst = ad,
                   variableDeclarationLst = vd,
                   initStatementLst = is,
                   statementLst = st,
                   cleanupStatementLst = cl)
      equation
        (i5,str) = cPrintIndentedListStr(vd, 2);
        res = addNewlineIfNotEmpty(str);
      then
        res;
  end matchcontinue;
end cPrintDeclarations;

protected function addNewlineIfNotEmpty
  input  String inStr;
  output String outStr;
algorithm
  outStr := matchcontinue (inStr)
    local String sTrim;  
    case (inStr)
      equation
         sTrim = System.trim(inStr, " ");
         false = stringEqual(sTrim, "");
      then (inStr +& "\n");
    case (inStr) then "";
  end matchcontinue;  
end addNewlineIfNotEmpty;

public function cPrintStatements 
"function: cPrintStatements
  Only prints the statements of a function to a string"
  input CFunction inCFunction;
  output String outString;
algorithm
  outString:=
  matchcontinue (inCFunction)
    local
      Integer i5;
      Lib str,res,rt,fn;
      list<Lib> rts,ad,vd,is,st,cl;
    case CFUNCTION(returnType = rt,
                   functionName = fn,
                   returnTypeStruct = rts,
                   argumentDeclarationLst = ad,
                   variableDeclarationLst = vd,
                   initStatementLst = is,
                   statementLst = st,
                   cleanupStatementLst = cl)
      equation
        (i5,str) = cPrintIndentedListStr(st, 2);
        res = addNewlineIfNotEmpty(str);
      then
        res;
  end matchcontinue;
end cPrintStatements;

protected function cPrintFunction 
"function: cPrintFunction
  Prints a CFunction to Print buffer."
  input CFunction inCFunction;
algorithm
  _:=
  matchcontinue (inCFunction)
    local
      Lib args_str,stmt_str,rt,fn;
      Integer i0,i2,i3,i4,i5,i6,i7;
      list<Lib> rts,ad,vd,is,st,cl,ads;
      
    case CFUNCTION(returnType = rt,
                   functionName = fn,
                   returnTypeStruct = rts,
                   argumentDeclarationLst = ad,
                   variableDeclarationLst = vd,
                   initStatementLst = is,
                   statementLst = st,
                   cleanupStatementLst = cl)
      equation
        args_str = Util.stringDelimitList(ad, ", ");
        stmt_str = Util.stringAppendList({rt," ",fn,"(",args_str,")\n{"});
        i0 = 0;
        i2 = cPrintIndented(stmt_str, i0);
        Print.printBuf("\n");
        // variable declarations
        i3 = cPrintIndentedList(vd, i2);
        //Print.printBuf("\n");
        // init statements
        i4 = cPrintIndentedList(is, i3);
        //Print.printBuf("\n");
        // statements
        i5 = cPrintIndentedList(st, i4);        
        //Print.printBuf("\n");
        // cleanup statements
        i6 = cPrintIndentedList(cl, i5);
        // Print.printBuf("\n");
        i7 = cPrintIndented("}", i6);
        Print.printBuf("\n\n");
      then
        ();
        
   case CEXTFUNCTION(returnType = rt,functionName = "",returnTypeStruct = rts,argumentDeclarationLst = ads)
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
        Debug.fprint("failtrace", "# Codegen.cPrintFunction_failed\n");
      then
        ();
  end matchcontinue;
end cPrintFunction;

protected function cPrintFunctionIncludes 
"function: cPrintFunctionIncludes
  Prints the function declaration, i.e. the header 
  information of a CFunction list to the Print buffer."
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

protected function cPrintFunctionInclude 
"function: cPrintFunctionIncludes
  Prints the includes for a function."
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

protected function cPrintFunctionHeaders 
"function: cPrintFunctionHeaders
  Prints the function declaration, i.e. the header 
  information of a CFunction list to the Print buffer."
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

protected function cPrintFunctionHeader 
"function: cPrintFunctionHeaders
  Prints the function declaration, i.e. the header 
  information of a CFunction to the Print buffer."
  input CFunction inCFunction;
algorithm
  _:=
  matchcontinue (inCFunction)
    local
      Lib args_str,stmt_str,rt,fn;
      Integer i0,i1,i2;
      list<Lib> rts,ad,vd,is,st,cl,ads;
    case CFUNCTION(returnType = rt,
                   functionName = fn,
                   returnTypeStruct = rts,
                   argumentDeclarationLst = ad,
                   variableDeclarationLst = vd,
                   initStatementLst = is,
                   statementLst = st,
                   cleanupStatementLst = cl)
      equation
        args_str = Util.stringDelimitList(ad, ", ");
        stmt_str = Util.stringAppendList({"DLLExport \n", rt," ",fn,"(",args_str,");"});
        i0 = 0;
        i1 = cPrintIndentedList(rts, i0);
        Print.printBuf("\n");
        i2 = cPrintIndented(stmt_str, i1);
        Print.printBuf("\n");
      then
        ();
        
    case CEXTFUNCTION(returnType = rt,functionName = "",returnTypeStruct = rts,argumentDeclarationLst = ads)
      equation
        i0 = 0;
        i1 = cPrintIndentedList(rts, i0);
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
        Debug.fprint("failtrace", "# Codegen.cPrintFunctionHeader failed\n");
      then
        ();
  end matchcontinue;
end cPrintFunctionHeader;

protected function cPrintIndentedList 
"function: cPrintIndentedList
  Helper function. prints a list of strings 
  indented with a number of indentation levels."
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

protected function cPrintIndented 
"function: cPrintIndented
  Prints a string adding an indentation level. If the string
  contains C-code that opens or closes a  indentation level,
  the indentation level is updated accordingly."
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

protected function cPrintIndentedListStr 
"function: cPrintIndentedListStr
  Helper function."
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
        s1 = addNewlineIfNotEmpty(s1);
        res = Util.stringAppendList({s1, s2});
      then
        (i_2,res);
  end matchcontinue;
end cPrintIndentedListStr;

protected function cPrintIndentedStr 
"function: cPrintIndentedStr
  See cPrintIndented"
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

protected function cNextLevel 
"function cNextLevel
  Helper function to cPrintIndented."
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

protected function cThisLevel 
"function cNextLevel
  Helper function to cPrintIndented."
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

protected function cPrintIndent 
"function cPrintIndent
  Helper function to cPrintIndented."
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

protected function cPrintIndentStr 
"function cPrintIndentStr
  Helper function to cPrintIndentedStr."
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

public function generateFunctions 
"function: generateFunctions
  Generates code for all functions in a DAE and prints on Print buffer. 
  A list of libs for the external functions is returned."
  input DAE.DAElist inDAElist;
  input list<DAE.Type> metarecordTypes;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAElist,metarecordTypes)
    local
      list<Lib> libs;
      DAE.DAElist dae;
      list<DAE.Element> elist;
      list<String> rt;
      
    case ((dae as DAE.DAE(elementLst = elist)),metarecordTypes) /* libs */
      local String s;
      equation
        Print.printBuf("#ifdef __cplusplus\n");
        Print.printBuf("extern \"C\" {\n");
        Print.printBuf("#endif\n");
        (libs,rt) = generateFunctionHeaders(dae);
        generateRecordDeclarationsPrintList(metarecordTypes,rt);
        generateFunctionBodies(dae);
        Print.printBuf("\n");
        Print.printBuf("#ifdef __cplusplus\n");
        Print.printBuf("}\n");
        Print.printBuf("#endif\n");
      then
        libs;
        
    case (_,_)
      equation
        Debug.fprint("failtrace", "# Codegen.generateFunctions failed\n");
      then
        fail();
  end matchcontinue;
end generateFunctions;

public function generateFunctionBodies 
"function: generateFunctionBodies
  Generates the function bodies of a DAE list."
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
        (cfns as (_::_),_) = generateFunctionsElist(elist,{});
        Print.printBuf("\n/* Body */\n");
        cPrintFunctions(cfns);
        Print.printBuf("/* End Body */\n");
      then
        ();
    case DAE.DAE(elementLst = elist)
      equation
        Debug.fprintln("cgtr", "generate_function_bodies (nothing)");
        ({},_) = generateFunctionsElist(elist,{});
      then
        ();
    case _
      equation
        Debug.fprint("failtrace", "# Codegen.generateFunctionBodies failed\n");
      then
        fail();
  end matchcontinue;
end generateFunctionBodies;

public function generateFunctionHeaders 
"function: generateFunctionHeaders
  Generates the headers of the functions in a DAE list."
  input DAE.DAElist inDAElist;
  output list<String> outStringLst;
  output list<String> outRecordLst;
algorithm
  (outStringLst,outRecordLst) :=
  matchcontinue (inDAElist)
    local
      list<CFunction> cfns;
      list<Lib> libs, funcRef;
      list<DAE.Element> elist;
      
    case (DAE.DAE(elementLst = elist))
      equation
        Debug.fprintln("cgtr", "generate_function_headers");
        (cfns as (_::_),outRecordLst) = generateFunctionsElist(elist, {});
        Print.printBuf("/* header part */\n");
        libs = cPrintFunctionIncludes(cfns) ;
        cPrintFunctionHeaders(cfns);
        Print.printBuf("/* End of header part */\n");
      then
        (libs,outRecordLst);
        
    case (DAE.DAE(elementLst = elist))
      equation
        Debug.fprintln("cgtr", "generate_function_headers (function reference)");
        ({},funcRef) = generateFunctionsElist(elist, {});
        _ = cPrintIndentedList(funcRef, 0);
      then
        ({},funcRef);
    
    case _
      equation
        Debug.fprint("failtrace", "# Codegen.generateFunctionHeaders failed\n");
      then
        fail();
  end matchcontinue;
end generateFunctionHeaders;

protected function generateFunctionsElist 
"function: generateFunctionsElist
  Helper function. Generates code from the Elements of a DAE."
  input list<DAE.Element> els;
  input list<String> rt;
  output list<CFunction> cfns;
  output list<String> rt_1;
  list<DAE.Element> fns;
algorithm
  Debug.fprintln("cgtr", "generate_functions_elist");
  Debug.fprintln("cgtrdumpdae", "Dumping DAE:");
  Debug.fcall("cgtrdumpdae", DAEUtil.dump2, DAE.DAE(els));
  fns := Util.listFilter(els, DAEUtil.isFunction);
  (cfns,rt_1) := generateFunctionsElist2(fns,rt);
end generateFunctionsElist;

protected function generateFunctionsElist2 
"function: generateFunctionsElist2
  Helper function to generateFunctionsElist."
  input list<DAE.Element> inDAEElementLst;
  input list<String> inRecordTypes;
  output list<CFunction> outCFunctionLst;
  output list<String> outRecordTypes;
algorithm
  (outCFunctionLst,outRecordTypes):=
  matchcontinue (inDAEElementLst,inRecordTypes)
    local
      list<CFunction> cfns1,cfns2,cfns;
      list<String> rt, rt_1, rt_2;
      DAE.Element f;
      list<DAE.Element> rest;
      
    case ({},rt)
      equation
        Debug.fprintln("cgtr", "Codegen.generateFunctionsElist2");
      then
        ({},rt);
        
    case ((f :: rest),rt)
      equation
        Debug.fprintln("cgtr", "Codegen.generateFunctionsElist2");
        (cfns1,rt_1) = generateFunction(f, rt);
        (cfns2,rt_2) = generateFunctionsElist2(rest, rt_1);
        cfns = listAppend(cfns1, cfns2);
      then
        (cfns, rt_2);
  end matchcontinue;
end generateFunctionsElist2;

protected function generateFunction 
"function: generateFunction
  Generates code for a DAE.FUNCTION. This results in two CFunctions,
  one declaration and one definition. There are two rules of this function,
  one for normal Modelica functions and one for external Modelica functions."
  input DAE.Element inElement;
  input list<String> inRecordTypes;
  output list<CFunction> outCFunctionLst;
  output list<String> outRecordTypes;
algorithm
  (outCFunctionLst,outRecordTypes):=
  matchcontinue (inElement,inRecordTypes)
    local
      Lib fn_name_str,fn_name_str_1,retstr,extfnname,lang,retstructtype,extfnname_1,n,str;
      list<DAE.Element> outvars,invars,dae,bivars,orgdae,daelist,funrefs;
      list<Lib> struct_strs,arg_strs,includes,libs,struct_strs_1,funrefStrs;
      CFunction head_cfn,body_cfn,cfn,rcw_fn,func_decl,ext_decl;
      Absyn.Path fpath;
      list<tuple<Lib, DAE.Type>> args;
      DAE.Type restype,tp;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extretarg;
      Option<Absyn.Annotation> ann;
      DAE.ExternalDecl extdecl;
      list<CFunction> cfns,wrapper_body;
      DAE.Element comp;
      list<String> rt, rt_1, struct_funrefs, struct_funrefs_int;
      list<Absyn.Path> funrefPaths;
      
    /* Modelica functions External functions */
    case (DAE.FUNCTION(path = fpath,
                       dAElist = DAE.DAE(elementLst = dae),
                       type_ = tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_),
                       partialPrefix = false),rt) 
      equation
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        Debug.fprintl("cgtr", {"generating function ",fn_name_str,"\n"});
        Debug.fprintln("cgtrdumpdae3", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae3", DAEUtil.dump2, DAE.DAE(dae));
        outvars = DAEUtil.getOutputVars(dae);
        invars = DAEUtil.getInputVars(dae);
        (struct_strs,rt_1) = generateStructsForRecords(dae, rt);
        struct_strs_1 = generateResultStruct(outvars, fpath);
        struct_strs = listAppend(struct_strs, struct_strs_1);
        /*-- MetaModelica Partial Function. sjoelund --*/
        funrefs = Util.listSelect(invars, DAEUtil.isFunctionRefVar);
        struct_funrefs = Util.listFlatten(Util.listMap(funrefs, generateFunctionRefReturnStruct));
        /*--                                           --*/
        retstr = generateReturnType(fpath);
        arg_strs = Util.listMap(args, generateFunctionArg);
        head_cfn = cMakeFunction(retstr, fn_name_str, struct_strs, arg_strs);
        body_cfn = generateFunctionBody(fpath, dae, restype, struct_funrefs);
        wrapper_body = generateFunctionReferenceWrapperBody(fpath, tp);
        cfn = cMergeFn(head_cfn, body_cfn);
        rcw_fn = generateReadCallWrite(fn_name_str, outvars, retstr, invars);
      then
        (cfn::rcw_fn::wrapper_body,rt_1);
    
      /* Modelica Record Constructor. We would like to use this as a C macro, but this is not possible. */
    case (DAE.RECORD_CONSTRUCTOR(path = fpath, type_ = tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)),_)),_)),rt)
      local
        String name, defhead, head, foot, body, decl1, decl2, assign_res, ret_var, record_var, record_var_dot, return_stmt;
        DAE.ExpType expType;
        list<String> arg_names, arg_tmp1, arg_tmp2, arg_assignments;
        Integer tnr;
      equation
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        retstr = generateReturnType(fpath);
        tnr = 1;
        (decl1,ret_var,tnr) = generateTempDecl(retstr, tnr);
        (decl2,record_var,tnr) = generateTempDecl("struct " +& name, tnr);
        (struct_strs,rt_1) = generateRecordDeclarations(restype, rt);

        expType = Types.elabType(restype);
        defhead = "#define " +& retstr +& "_1 targ1";
        head = "typedef struct " +& retstr +& "_s {";
        body = "struct " +& name +& " targ1;";
        foot = "} "+&retstr+&";";
        struct_strs = listAppend(struct_strs, {defhead, head, body, foot});
        arg_names = Util.listMap(args, Util.tuple21);
        arg_tmp1 = Util.listMap1(arg_names, stringAppend, " = ");
        arg_tmp2 = Util.listMap1(arg_names, stringAppend, ";");
        arg_tmp1 = Util.listThreadMap(arg_tmp1, arg_tmp2, stringAppend);
        record_var_dot = record_var +& ".";
        arg_assignments = Util.listMap1r(arg_tmp1, stringAppend, record_var_dot);
        assign_res = ret_var +& ".targ1 = " +& record_var +& ";";
        return_stmt = "return "+&ret_var+&";";
        
        arg_strs = Util.listMap(args, generateFunctionArg);
        head_cfn = cMakeFunction(retstr, fn_name_str, struct_strs, arg_strs);
        body_cfn = cEmptyFunction;
        body_cfn = cAddVariables(body_cfn, {decl1,decl2});
        body_cfn = cAddStatements(body_cfn, arg_assignments);
        body_cfn = cAddCleanups(body_cfn, {assign_res,return_stmt});
        wrapper_body = generateFunctionReferenceWrapperBody(fpath, tp);
        cfn = cMergeFn(head_cfn, body_cfn);
      then
        (cfn::wrapper_body,rt_1);
    
    /* MetaModelica Partial Function. sjoelund */    
    case (DAE.FUNCTION(path = fpath,
                       dAElist = DAE.DAE(elementLst = dae),
                       type_ = (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_),
                       partialPrefix = true),rt) 
      then
        ({},{});
        
    /* Builtin functions - stefan */
    case (DAE.EXTFUNCTION(path = fpath,
                          dAElist = DAE.DAE(elementLst = orgdae),
                          type_ = (tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_)),
                          externalDecl = extdecl),rt)
      equation
        true = isBuiltinFunction(fpath);
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        DAE.EXTERNALDECL(ident = extfnname, external_ = extargs,parameters = extretarg, returnType = lang, language = ann) = extdecl;
        dae = Inst.initVarsModelicaOutput(orgdae);
        outvars = DAEUtil.getOutputVars(dae);
        invars = DAEUtil.getInputVars(dae);
        bivars = DAEUtil.getBidirVars(dae);
        (struct_strs,rt_1) = generateStructsForRecords(dae,rt);
        struct_strs_1 = generateResultStruct(outvars, fpath);
        struct_strs = listAppend(struct_strs, struct_strs_1);
        retstructtype = generateReturnType(fpath);
        retstr = generateExtFunctionName(extfnname, lang);
        extfnname_1 = generateExtFunctionName(extfnname,lang);
        arg_strs = generateExtFunctionArgs(extargs, lang);
        (includes,libs) = generateExtFunctionIncludes(ann);
        rcw_fn = generateReadCallWriteExternal(fn_name_str, outvars, retstructtype, invars, extdecl, bivars);
        ext_decl = generateExternalWrapperCall(fn_name_str, outvars, retstructtype, invars, extdecl, bivars, tp);
        cfns = {rcw_fn, ext_decl};
      then (cfns, rt_1);
    
    /* External functions */
    case (DAE.EXTFUNCTION(path = fpath,
                          dAElist = DAE.DAE(elementLst = orgdae),
                          type_ = (tp as (DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_)),
                          externalDecl = extdecl),rt) 
      equation
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = stringAppend("_", fn_name_str);
        Debug.fprintl("cgtr", {"generating external function ",fn_name_str,"\n"});
        DAE.EXTERNALDECL(ident = extfnname,external_ = extargs,parameters = extretarg,returnType = lang,language = ann) = extdecl;
        Debug.fprintln("cgtrdumpdae1", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae1", DAEUtil.dump2, DAE.DAE(orgdae));
        dae = Inst.initVarsModelicaOutput(orgdae);
        Debug.fprintln("cgtrdumpdae2", "Dumping DAE:");
        Debug.fcall("cgtrdumpdae2", DAEUtil.dump2, DAE.DAE(dae));
        outvars = DAEUtil.getOutputVars(dae);
        invars = DAEUtil.getInputVars(dae);
        bivars = DAEUtil.getBidirVars(dae);
        (struct_strs,rt_1) = generateStructsForRecords(dae, rt);
        struct_strs_1 = generateResultStruct(outvars, fpath);
        struct_strs = listAppend(struct_strs, struct_strs_1);
        retstructtype = generateReturnType(fpath);
        retstr = generateExtReturnType(extretarg);
        extfnname_1 = generateExtFunctionName(extfnname, lang);
        extfnname_1 = Util.if_("Java" ==& lang, "", extfnname_1);
        arg_strs = generateExtFunctionArgs(extargs, lang);
        (includes,libs) = generateExtFunctionIncludes(ann);
        includes = Util.if_("Java" ==& lang, "#include \"java_interface.h\"" :: includes, includes);
        rcw_fn = generateReadCallWriteExternal(fn_name_str, outvars, retstructtype, invars, extdecl, bivars);
        ext_decl = generateExternalWrapperCall(fn_name_str, outvars, retstructtype, invars, extdecl, bivars, tp);
        func_decl = cMakeFunctionDecl(retstr, extfnname_1, struct_strs, arg_strs, includes, libs);
        wrapper_body = generateFunctionReferenceWrapperBody(fpath, tp);
        cfns = func_decl :: rcw_fn :: ext_decl :: wrapper_body;
      then
        (cfns,rt_1);
        
    case (DAE.COMP(ident = n,dAElist = DAE.DAE(elementLst = daelist)),rt)
      equation
        (cfns,rt_1) = generateFunctionsElist(daelist,rt);
      then
        (cfns,rt_1);
        
    case (comp,rt)
      equation
        Debug.fprint("failtrace", "-Codegen.generateFunction failed\n");
      then
        fail();
  end matchcontinue;
end generateFunction;

// builtins - stefan
protected function isBuiltinFunction
"function: isBuiltinFunction
  takes an Absyn.path and returns true if the name matches a modelica builtin function"
  input Absyn.Path path;
  output Boolean b;
  list<String> builtins = { "delay","smooth","size","ndims","zeros","ones","fill","max","min","transpose","array","sum","product","pre","initial","terminal","floor","ceil","abs","sqrt","div","integer","mod","rem","diagonal","differentiate","simplify","noEvent","edge","sign","der","sample","change","cat","identity","vector","scalar","cross","String","skew","constrain" };
  
algorithm
  out := matchcontinue(path)
    local
      String fname;
    case(Absyn.IDENT(name = fname))
      equation
        true = listMember(fname,builtins);
      then true;
    case(_) then false;
  end matchcontinue;
end isBuiltinFunction;

protected function generateFunctionRefReturnStruct
  input DAE.Element var;
  output list<String> out;
algorithm
  out := matchcontinue(var)
    local
      list<DAE.Type> tys;
      Ident fn_name,fn_name_full,str;
      Absyn.Path path,fullPath;
      DAE.Type ty;
      list<DAE.FuncArg> args;
    case (DAE.VAR(ty = (DAE.T_FUNCTION(args, (DAE.T_TUPLE(tys),_)),SOME(path))))
      equation
        fn_name = generateReturnType(path);
        str = generateFunctionRefFnPtr(args, path);
        out = generateFunctionRefReturnStruct1(tys,fn_name);
      then listAppend(out,{str});
      // Function reference with no output -  stefan
    case (DAE.VAR(ty = (DAE.T_FUNCTION(args, (DAE.T_NORETCALL(),_)),SOME(path))))
      local String tmpstr;
      equation
        fn_name = generateReturnType(path);
        str = generateFunctionRefFnPtr(args, path);
        tmpstr = "typedef void " +& fn_name +& ";";
        out = {tmpstr};
      then listAppend(out,{str});
    case (DAE.VAR(ty = (DAE.T_FUNCTION(args, ty),SOME(path))))
      equation
        fn_name = generateReturnType(path);
        str = generateFunctionRefFnPtr(args, path);
        out = generateFunctionRefReturnStruct1({ty},fn_name);
      then listAppend(out,{str});
  end matchcontinue;
end generateFunctionRefReturnStruct;

protected function generateFunctionRefFnPtr
  input list<DAE.FuncArg> args;
  input Absyn.Path path;
  output String str;
protected
  list<DAE.Type> fargTypes;
  list<String> fargStrList;
  String fargStr, fn_ret, fn_name;
algorithm
  fargTypes := Util.listMap(args,Util.tuple22);
  fargStrList := Util.listMap(fargTypes,generateSimpleType);
  fargStr := Util.stringDelimitList(fargStrList, ",");
  fn_ret := generateReturnType(path);
  fn_name := generateFunctionName(path);
  str := Util.stringAppendList({fn_ret,"(*_",fn_name,")(",fargStr,") = (",fn_ret,"(*)(",fargStr,"))",fn_name,";"});
end generateFunctionRefFnPtr;

protected function generateFunctionRefReturnStruct1
  input list<DAE.Type> tys;
  input Ident fn_name;
  output list<String> out;
algorithm
  out := matchcontinue(tys,fn_name)
    local
      list<DAE.Type> tys;
      Absyn.Path path;
      list<String> outTypedef,outAliasing,defs,fields;
      String structHead, structTail;
      
    case (tys,fn_name)
      equation
        structHead = "typedef struct "+&fn_name+&"_s";
        structTail = "} "+&fn_name+&";";
        (defs,fields) = generateFunctionRefReturnStructFields(fn_name, 1, tys);
        outTypedef = listAppend(defs, listAppend(structHead::"{"::fields,{structTail}));
      then outTypedef;
  end matchcontinue;
end generateFunctionRefReturnStruct1;

protected function generateFunctionRefReturnStructFields
  input Ident fn_name;
  input Integer i;
  input list<DAE.Type> tys;
  output list<String> defs;
  output list<String> fields;
algorithm
  (defs,fields) := matchcontinue(fn_name,i,tys)
    local
      list<DAE.Type> rest;
      DAE.Type ty;
      String defineTarg, defineField,istr;
      list<String> defs, fields;
    case (_,_,{}) then ({},{});
    case (fn_name, i, ty::rest)
      equation
        defineTarg = "#define "+&fn_name+&"_"+&intString(i)+&" targ"+&intString(i);
        istr = intString(i);
        defineField = generateSimpleType(ty) +& " targ"+&istr+&";";
        (defs,fields) = generateFunctionRefReturnStructFields(fn_name, i+1, rest);
      then
        (defineTarg::defs,defineField::fields);
  end matchcontinue;
end generateFunctionRefReturnStructFields;

public function generateExtFunctionIncludes 
"function: generateExtFunctionIncludes
  Collects the includes and libs for an external function 
  by investigating the annotation of an external function."
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
        Absyn.CLASSMOD(_,SOME(Absyn.STRING(lib))) = 
        Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("Library",{})) "System.stringReplace(lib,\"\\\"\",\"\"\") => lib\'" ;
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

protected function generateExtFunctionName 
"function: generateExtFunctionName
  Generates the function name for external functions.
  Fortran functions have the underscore \'_\' suffix."
  input String inString1;
  input String inString2;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inString2)
    local Lib name,name_1,ext_lang;
    case (name,"C") then name;
    case (_,"Java") then "WARNING_EXT_JAVA_DOES_NOT_USE_C_FUNCTIONS";
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

protected function generateVarDeclaration 
"function generateVarDeclaration
  Helper function to generateVarListDeclarations."
   input DAE.Var inVar;
   output String outStr;
algorithm
  outStr :=
  matchcontinue (inVar)
    local
      DAE.Ident name;
      DAE.Type t;
      String type_str, decl_str;
    case DAE.TYPES_VAR(name = name, type_ = t)
      equation
        type_str = generateSimpleType(t);
        decl_str = Util.stringAppendList({type_str," ",name,";"});
      then
        decl_str;
    case DAE.TYPES_VAR(name = name)
      equation
        decl_str = Util.stringAppendList({"/* ",name," is an odd member. */"});
      then decl_str;
    case (_)
      then "/* Codegen.generateVarDeclaration failed. */";
  end matchcontinue;
end generateVarDeclaration;

protected function generateRecordDeclarations 
"function generateRecordDeclarations
  Helper function to generateStructsForRecords."
  input DAE.Type inRecordType;
  input list<String> inReturnTypes;
  output list<String> outStrs;
  output list<String> outReturnTypes;
algorithm
  outStrs :=
  matchcontinue (inRecordType,inReturnTypes)
    local
      Absyn.Path path;
      list<DAE.Var> varlst;
      String name, first_str, last_str, path_str;
      list<String> res,strs,rest_strs,decl_strs,rt,rt_1,rt_2,record_definition,fieldNames;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(string = name), complexVarLst = varlst),SOME(path)),rt)
      equation
        failure(_ = Util.listGetMember(name,rt));
        
        first_str = Util.stringAppendList({"struct ",name," {"});
        decl_strs = Util.listMap(varlst, generateVarDeclaration);
        last_str = "};";
        
        rt_1 = name :: rt;
        fieldNames = Util.listMap(varlst, generateVarName);
        record_definition = generateRecordDefinition(path,fieldNames);
        strs = Util.listFlatten({{first_str},decl_strs,{last_str},record_definition});
        
        (rest_strs,rt_2) = generateNestedRecordDeclarations(varlst, rt_1);
        res = listAppend(rest_strs,strs);
      then (res,rt_2);
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(string = name), complexVarLst = varlst),_),rt)
      then ({},rt);
    case ((DAE.T_METARECORD(fields = varlst), SOME(path)),rt)
      equation
        name = ModUtil.pathStringReplaceDot(path, "_");
        failure(_ = Util.listGetMember(name,rt));
        fieldNames = Util.listMap(varlst, generateVarName);
        rt_1 = name::rt;
        strs = generateRecordDefinition(path,fieldNames);
        (rest_strs,rt_2) = generateNestedRecordDeclarations(varlst, rt_1);
        strs = listAppend(rest_strs,strs);
      then (strs,rt_2);
    case ((DAE.T_METARECORD(_, _), SOME(path)),rt) then ({},rt);
    case ((_,_),rt) then ({ "/* An odd record this. */" },rt);
  end matchcontinue;
end generateRecordDeclarations;

protected function generateRecordDeclarationsPrintList 
  input list<DAE.Type> inRecordType;
  input list<String> inReturnTypes;
algorithm
  _ :=
  matchcontinue (inRecordType,inReturnTypes)
    local
      list<String> res,restRes,rt,rt_1,rt_2;
      list<DAE.Type> rest;
      DAE.Type ty;
    case ({},rt) then (); 
    case (ty::rest,rt)
      equation
        (res,rt_1) = generateRecordDeclarations(ty,rt);
        _ = cPrintIndentedList(res,0);
        generateRecordDeclarationsPrintList(rest,rt_1);
      then ();
  end matchcontinue;
end generateRecordDeclarationsPrintList;

protected function generateRecordDefinition "Used by uniontypes as well as records"
  input Absyn.Path path;
  input list<String> fieldNames;
  output list<String> outStrs;
algorithm
  outStrs :=
  matchcontinue (name,fieldNames)
    local
      String name, name2, name_str, pre_str, first_str, path_str, last_str, fieldNamesStr;
      list<String> strs,rt,rt_1,rt_2,fieldNames;
    case (path,fieldNames)
      equation
        name_str = Absyn.pathString(path);
        name = ModUtil.pathStringReplaceDot(path, "_");
        
        fieldNamesStr = Util.stringDelimitList(fieldNames, "\",\"");
        fieldNamesStr = "{\""+&fieldNamesStr+&"\"}";
        fieldNamesStr = Util.if_(listLength(fieldNames) > 0, fieldNamesStr, "{}");
        
        pre_str = "const char* " +&  name +& "__desc__fields[] = " +& fieldNamesStr +& ";";
        first_str = "struct record_description " +&  name +& "__desc = {";
        path_str =  "  \"" +& name +& "\", /* package_record__X */";
        name_str =  "  \"" +& name_str +& "\", /* package.record_X */";
        fieldNamesStr = "  " +& name +& "__desc__fields";
        last_str = "};";
        
        strs = {pre_str,first_str,path_str,name_str,fieldNamesStr,last_str};
        
      then strs;
  end matchcontinue;
end generateRecordDefinition;

protected function generateNestedRecordDeclarations 
"function generateNestedRecordDeclarations
  Helper function to generateRecordDeclarations."
  input list<DAE.Var> inRecordTypes;
  input list<String> inReturnTypes;
  output list<String> outStrs;
  output list<String> outReturnTypes;
algorithm
  outStrs :=
  matchcontinue (inRecordTypes,inReturnTypes)
    local
      DAE.Type ty;
      list<DAE.Var> rest;
      list<String> res,strs,strs_rest,rt,rt_1,rt_2;
    case ({},rt)
      then ({},rt);
    case (DAE.TYPES_VAR(type_ = (ty as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_)))::rest,rt)
      equation
        (strs,rt_1) = generateRecordDeclarations(ty,rt);
        (strs_rest,rt_2) = generateNestedRecordDeclarations(rest,rt_1);
        res = listAppend(strs, strs_rest);
      then (strs,rt_2);
    case (_::rest,rt)
      equation
        (strs,rt_1) = generateNestedRecordDeclarations(rest,rt);
      then (strs,rt_1);
  end matchcontinue;
end generateNestedRecordDeclarations;

protected function generateStructsForRecords 
"function generateStructsForRecords
  Translate all records used by varlist to structs."
  input list<DAE.Element> inVars;
  input list<String> inReturnTypes;
  output list<String> outStrs;
  output list<String> outReturnTypes;
algorithm
  (outStrs,outReturnTypes) :=
  matchcontinue (inVars,inReturnTypes)
    local
      DAE.Element var;
      list<DAE.Element> rest;
      Absyn.Path path;
      String name;
      DAE.Type ft;
      list<String> strs, rest_strs, rt, rt_1, rt_2;
    case ({},rt) then ({},rt);
    case (((var as DAE.VAR(ty = ft as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_))) :: rest),rt)
      equation
        (strs,rt_1) = generateRecordDeclarations(ft,rt);
        (rest_strs,rt_2) = generateStructsForRecords(rest,rt_1);
        strs = listAppend(strs, rest_strs);
      then
        (strs,rt_2);
    case ((_ :: rest),rt)
      equation
        (strs,rt_1) = generateStructsForRecords(rest,rt);
      then
        (strs,rt_1);
  end matchcontinue;
end generateStructsForRecords;

protected function generateResultStruct 
"function generate_results_struct
  All Modelica functions translates to a C function returning all Modelica 
  ouput parameters in a struct. This function generates that struct."
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

protected function generateReturnDefs 
"function: generateReturnDefs
  Helper function to generateResultStruct. 
  Creates defines used in the declaration of the return struct."
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

protected function generateReturnDecls 
"function: generateReturnDecls
  Helper function to generateResultStruct. 
  Generates the variable names of the result structure."
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

protected function tmpPrintInit 
"function: tmpPrintInit
  Helper function to generateReturnDecl."
  input Option<DAE.Exp> inExpExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpOption)
    local
      Lib str,str1;
      DAE.Exp e;
    case NONE then "";
    case SOME(e)
      equation
        str = Exp.printExpStr(e);
        str1 = Util.stringAppendList({" /* ",str," */"});
      then
        str1;
  end matchcontinue;
end tmpPrintInit;

protected function generateReturnDecl 
"function: generateReturnDecl
  Helper function to generateReturnDecls"
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
      DAE.ComponentRef id;
      DAE.Type typ;
      Option<DAE.Exp> initopt;
      list<DAE.Subscript> inst_dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
    case ((var as DAE.VAR(componentRef = id,
                          kind = DAE.VARIABLE(),
                          direction = DAE.OUTPUT(),
                          ty = typ,
                          binding = initopt,
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix=streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),i)
      equation
        is_a = isArray(var);
        typ_str = generateType(typ, is_a);
        iStr = intString(i);
        id_str = Util.stringAppendList({"targ",iStr});
        dim_strs = Util.listMap(inst_dims, dimString);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        decl_str_1 = Util.stringAppendList({typ_str," ",id_str,";"," /* [",dims_str,"] */"});
        expstr = tmpPrintInit(initopt);
        decl_str = stringAppend(decl_str_1, expstr);
      then
        (decl_str,id_str);
    case (_,_) then ("","");
  end matchcontinue;
end generateReturnDecl;

protected function isArray 
"function: isArray
  Returns true if variable is part of an array."
  input DAE.Element inElement;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inElement)
    local
      DAE.Element el;
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      Option<DAE.Exp> st;
      DAE.Flow fl;
      DAE.Stream st;
      list<Absyn.Path> cl;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
    case ((el as DAE.VAR(componentRef = cr,
                         kind = vk,
                         direction = vd,
                         dims = {},
                         flowPrefix = fl,
                         streamPrefix = st,
                         pathLst = cl,
                         variableAttributesOption = dae_var_attr,
                         absynCommentOption = comment)))

      equation
        Debug.fcall("isarrdb", DAEUtil.dump2, DAE.DAE({el}));
      then
        false;
        
    case ((el as DAE.VAR(componentRef = cr,
                         kind = vk,
                         direction = vd,
                         dims = (_ :: _),
                         flowPrefix = fl,
                         streamPrefix = st, 
                         pathLst = cl,
                         variableAttributesOption = dae_var_attr,
                         absynCommentOption = comment)))
      equation
        Debug.fcall("isarrdb", DAEUtil.dump2, DAE.DAE({el}));
      then
        true;
        
    case el
      equation
        Debug.fprint("failtrace", "- Codegen.isArray failed\n");
      then
        fail();
  end matchcontinue;
end isArray;

protected function expShortTypeStr 
"function: expShortTypeStr
  Translates and DAE.ExpType to a string, using a \"short\" typename."
  input DAE.ExpType inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      Lib res;
      DAE.ExpType t;
    case DAE.ET_INT() then "integer";
    case DAE.ET_REAL() then "real";
    case DAE.ET_STRING() then "string";
    case DAE.ET_BOOL() then "boolean";
    case DAE.ET_OTHER() then "complex"; // Only use is currently for external objects. Perhaps in future also records.
    case DAE.ET_ENUMERATION(_,_,_,_) then "enumeration";
//    case Exp.ENUM() then "ENUM_NOT_IMPLEMENTED";
    case DAE.ET_FUNCTION_REFERENCE_VAR() then "fnptr";
    case DAE.ET_FUNCTION_REFERENCE_FUNC() then "fnptr";
    case DAE.ET_ARRAY(ty = t)
      equation
        res = expShortTypeStr(t);
      then
        res;
    case DAE.ET_COMPLEX(name = name)
      local String name;
      equation
        res = stringAppend("struct ", name);
      then
        res;
    
    case (DAE.ET_LIST(_)) then "metatype";
    case (DAE.ET_METATUPLE(_)) then "metatype";
    case (DAE.ET_METAOPTION(_)) then "metatype";
    case (DAE.ET_UNIONTYPE()) then "metatype";
    case (DAE.ET_POLYMORPHIC()) then "metatype";
    case (DAE.ET_META_ARRAY(_)) then "metatype";
    case (DAE.ET_BOXED(_)) then "metatype";
      
    case t
      equation
        Debug.fprintln("failtrace", "- Codegen.expShortTypeStr failed: " +& Exp.typeString(t));
      then fail();

  end matchcontinue;
end expShortTypeStr;

protected function expTypeStr 
"function: expShortTypeStr
  Translates and DAE.ExpType to a string. The second argument is 
  true if an array type of the given type should be generated."
  input DAE.ExpType inType;
  input Boolean inBoolean;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType,inBoolean)
    local
      Lib tstr,str;
      DAE.ExpType t;

    case ((t as DAE.ET_COMPLEX(_,_,_)),_)
      equation
        str = expShortTypeStr(t);
      then
        str;

    // ---
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

protected function generateType 
"Generates code for a Type. If it is an array of the type, or the boolean
flag is set, its array type is produced instead.
"
  input DAE.Type inType;
  input Boolean isArray;
  output String outString;
algorithm
  outString := matchcontinue (inType,isArray)
    local
      Lib ty_str;
      list<DAE.Type> tys;
      DAE.Type arrayty,ty;
      list<Integer> dims;
      
    case ((DAE.T_TUPLE(tupleType = tys),_),false)
      equation
        ty_str = generateTupleType(tys);
      then
        ty_str;
    
    case (ty,false) then generateSimpleType(ty);
        
    case (ty,true) then generateSimpleType((DAE.T_ARRAY(DAE.DIM(NONE),ty),NONE));

  end matchcontinue;
end generateType;

protected function generateTypeExternal 
"function: generateTypeExternal
  Generates Code for an external type."
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      Lib str;
      DAE.ArrayDim dim;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
    case ((DAE.T_INTEGER(varLstInt = _),_)) then "int";
    case ((DAE.T_REAL(varLstReal = _),_)) then "double";
    case ((DAE.T_STRING(varLstString = _),_)) then "const char*";
    case ((DAE.T_BOOL(varLstBool = _),_)) then "int";
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)),_))
      local String name;
      equation
        str = stringAppend("struct ", name);
      then
        str;

    // MetaModelica Types
    case ty
      equation
        true = Types.isBoxedType(ty);
      then "void*";
    
    case ((DAE.T_ARRAY(arrayDim = dim,arrayType = ty),_))
      equation
        str = generateTypeExternal(ty);
      then
        str;

    // External objects are stored in void pointer
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),_)) then "void *";
    case ty
      equation
        Debug.fprint("failtrace", "#-- Codegen.generateTypeExternal failed\n");
      then
        fail();
  end matchcontinue;
end generateTypeExternal;

protected function generateTypeInternalNamepart 
"function: generateTypeInternalNamepart
  Generates code for a Type only returning the typename of the basic types."
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    case ((DAE.T_INTEGER(varLstInt = _),_)) then "integer";
    case ((DAE.T_REAL(varLstReal = _),_)) then "real";
    case ((DAE.T_STRING(varLstString = _),_)) then "string";
    case ((DAE.T_BOOL(varLstBool = _),_)) then "boolean";
//    case ((DAE.T_ENUM(),_)) then "T_ENUM_NOT_IMPLEMENTED";
  end matchcontinue;
end generateTypeInternalNamepart;

protected function generateReturnType 
"function: generateReturnType
  Generates the return type name of a function given the function name."
  input Absyn.Path fpath;
  output String res;
  Lib fstr;
algorithm
  fstr := generateFunctionName(fpath);
  res := stringAppend(fstr, "_rettype");
end generateReturnType;

protected function generateTupleType
"function: generateTupleType
  Generate code for a tuple type."
  input list<DAE.Type> inTypesTypeLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inTypesTypeLst)
    local
      Lib str,str_1,str_2,str_3;
      DAE.Type ty;
      list<DAE.Type> tys;
    case {ty}
      equation
        str = generateSimpleType(ty);
      then
        str;
    case (ty :: tys)
      equation
        str = generateSimpleType(ty);
        str_1 = generateTupleType(tys);
        str_2 = stringAppend(str, str_1);
        str_3 = stringAppend("struct ", str_2);
      then
        str_3;
  end matchcontinue;
end generateTupleType;

protected function generateSimpleType 
"function: generateSimpleType
  Helper function to generateTupleType. 
  Generates code for a non-tuple type as element of a tuple."
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      String t_str,name;
      DAE.Type t_1,t,ty;
    
    case ((DAE.T_INTEGER(varLstInt = _),_)) then "modelica_integer";
    case ((DAE.T_REAL(varLstReal = _),_)) then "modelica_real";
    case ((DAE.T_STRING(varLstString = _),_)) then "modelica_string";
    case ((DAE.T_BOOL(varLstBool = _),_)) then "modelica_boolean";
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)),_))
      equation
        t_str = stringAppend("struct ", name);
      then
        t_str;
        
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_)),_)) then "modelica_complex";
    case ((DAE.T_COMPLEX(ClassInf.TYPE(_),{},SOME(ty),_),_)) then generateSimpleType(ty);

    case ((DAE.T_FUNCTION(_,_),_)) then "modelica_fnptr";
      // Any MetaModelica type
    case ty
      equation
        true = Types.isBoxedType(ty);
      then "modelica_metatype";
            
    case ((t as (DAE.T_ARRAY(arrayDim = _),_)))
      equation
        t_1 = Types.arrayElementType(t);
        t_str = arrayTypeString(t_1);
      then
        t_str;

    case (ty)
      equation
				true = RTOpts.debugFlag("failtrace");
        t_str = Types.unparseType(ty);
        Debug.fprint("failtrace", "#--Codegen.generateSimpleType failed: " +& t_str +& "\n");
      then
        fail();
  end matchcontinue;
end generateSimpleType;

protected function arrayTypeString 
"function: arrayTypeString
  Returns the type string of an array 
  of the basic type passed as argument."
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    case ((DAE.T_INTEGER(varLstInt = _),_)) then "integer_array";
    case ((DAE.T_REAL(varLstReal = _),_)) then "real_array";
    case ((DAE.T_STRING(varLstString = _),_)) then "string_array";
    case ((DAE.T_BOOL(varLstBool = _),_)) then "boolean_array";
  end matchcontinue;
end arrayTypeString;

protected function generateFunctionName 
"function: generateFunctionName
  Generates the name of a function by replacing dots with underscores."
  input Absyn.Path fpath;
  output String fstr;
algorithm
  fstr := ModUtil.pathStringReplaceDot(fpath, "_");
end generateFunctionName;

protected function generateExtFunctionArgs 
"function: generateExtFunctionArgs
  Generates Code for external function arguments.
  input string is language, e.g. \"C\" or \"FORTRAN 77\""
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
    case (extargs,"Java")
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
        Debug.fprint("failtrace", "-Codegen.generateExtFunctionArgs failed");
      then
        fail();
  end matchcontinue;
end generateExtFunctionArgs;

protected function generateFunctionArg 
"function: generateFunctionArgs
  Generates code from a function argument."
  input DAE.FuncArg inFuncArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inFuncArg)
    local
      Lib str,str_1,str_2,name,fargStr,resStr;
      DAE.Type ty;
    case ((name,ty))
      equation
        str = generateTupleType({ty});
        str_1 = stringAppend(str, " ");
        str_2 = stringAppend(str_1, name);
      then
        str_2;
  end matchcontinue;
end generateFunctionArg;

protected function generateExtArgType 
"function: generateExtArgType
  Helper function to generateExtFunctionArg.
  Generates code for the type of an external function argument."
  input DAE.Attributes inAttributes;
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAttributes,inType)
    local
      Lib str,resstr,tystr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      
    case (DAE.ATTR(direction = Absyn.INPUT()),ty)
      equation
        false = Types.isArray(ty);
        str = generateTypeExternal(ty);
      then
        str;
        
    case (DAE.ATTR(direction = Absyn.INPUT()),ty)
      equation
        true = Types.isArray(ty);
        ((DAE.T_STRING(_),_)) = Types.arrayElementType(ty);
        str = generateTypeExternal(ty);
        resstr = Util.stringAppendList({str," const *"});
      then
        resstr;
        
    case (DAE.ATTR(direction = Absyn.INPUT()),ty)
      equation
        true = Types.isArray(ty);
        str = generateTypeExternal(ty);
        resstr = Util.stringAppendList({"const ",str," *"});
      then
        resstr;
        
    case (DAE.ATTR(direction = Absyn.OUTPUT()),ty)
      equation
        tystr = generateTypeExternal(ty);
        str = stringAppend(tystr, "*");
      then
        str;
        
    case (DAE.ATTR(direction = Absyn.BIDIR()),ty)
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
        Debug.fprint("failtrace", "#-- Codegen.generateExtArgType failed\n");
      then
        fail();
        
  end matchcontinue;
end generateExtArgType;

protected function generateExtFunctionArg 
"function: generateExtFunctionArg
  Generates Code for the arguments of an external function."
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExtArg)
    local
      Lib tystr,name,res,e_str;
      DAE.ComponentRef cref,cr;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Exp exp;
      
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
        Debug.fprint("failtrace", "#-- Codegen.generateExtFunctionArg failed\n");
      then
        fail();
        
  end matchcontinue;
end generateExtFunctionArg;

protected function generateExtArgTypeF77 
"function: generateExtArgTypeF77
  Helper function to generateExtFunctionArg.
  Generates code for the type of an external function argument in Fortran format."
  input DAE.Attributes inAttributes;
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAttributes,inType)
    local
      Lib str,resstr,tystr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Attributes attr;

    case (DAE.ATTR(direction = Absyn.INPUT()),ty)
      equation
        str = generateTypeExternal(ty);
        resstr = Util.stringAppendList({"const ",str," *"});
      then
        resstr;

    case (DAE.ATTR(direction = Absyn.OUTPUT()),ty)
      equation
        tystr = generateTypeExternal(ty);
        str = stringAppend(tystr, "*");
      then
        str;

    case ((attr as DAE.ATTR(direction = Absyn.BIDIR())),ty)
      equation
        str = generateExtArgType(attr, ty);
      then
        str;

    case ((attr as DAE.ATTR(direction = Absyn.BIDIR())),ty)
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
        Debug.fprint("failtrace", "#-- Codegen.generateExtArgTypeF77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtArgTypeF77;

protected function generateExtFunctionArgF77 
"function: generateExtFunctionArgF77
  Generates Code for the arguments of an external function in Fortran format."
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExtArg)
    local
      Lib tystr,name,res;
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
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
        Debug.fprint("failtrace", "-Codegen.generateExtFunctionArgF77 failed\n");
      then
        fail();
  end matchcontinue;
end generateExtFunctionArgF77;

protected function generateExtReturnType 
"function: generateExtReturnType
  Generates code for the return type of an external function."
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExtArg)
    local
      Lib res;
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      
    case DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation
        res = generateTypeExternal(ty);
      then
        res;
        
    case DAE.NOEXTARG() then "void";
      
    case _
      equation
        Debug.fprint("failtrace", "-Codegen.generateExtReturnType failed\n");
      then
        fail();
  end matchcontinue;
end generateExtReturnType;

protected function generateExtReturnTypeF77 
"function generateExtReturnTypeF77
  Generates code for the return type of an external function."
  input DAE.ExtArg arg;
  output String str;
algorithm
  str := generateExtReturnType(arg);
end generateExtReturnTypeF77;

protected function generateFunctionBody 
"function: generateFunctionBody
  Generates code for the body of a Modelica function."
  input Absyn.Path fpath;
  input list<DAE.Element> dae;
  input DAE.Type restype;
  input list<VariableDeclaration> functionRefTypedefs;
  output CFunction cfn;
  Integer tnr,tnr_ret_1,tnr_ret,tnr_mem,tnr_var,tnr_alg,tnr_res;
  Lib ret_type_str,ret_decl,ret_var,ret_stmt,mem_decl,mem_var,mem_stmt1,mem_stmt2;
  list<DAE.Element> outvars;
  CFunction out_fn,mem_fn_2,mem_fn_1,mem_fn,var_fn,alg_fn,res_var_fn,cfn_1,cfn_2,cfn_3;
algorithm
  Debug.fprintln("cgtr", "generate_function_body");
  tnr := 1;
  ret_type_str := generateReturnType(fpath);
  (ret_decl,ret_var,tnr_ret_1) := generateTempDecl(ret_type_str, tnr);
  ret_stmt := Util.stringAppendList({"return ",ret_var,";"});
  outvars := DAEUtil.getOutputVars(dae);
  (out_fn,tnr_ret) := generateAllocOutvars(outvars, ret_decl, ret_var, 1,tnr_ret_1, funContext);
  (mem_decl,mem_var,tnr_mem) := generateTempDecl("state", tnr_ret);
  mem_stmt1 := Util.stringAppendList({mem_var," = get_memory_state();"});
  mem_stmt2 := Util.stringAppendList({"restore_memory_state(",mem_var,");"});
  mem_fn_2 := cAddVariables(out_fn, functionRefTypedefs) "MetaModelica Partial Function. sjoelund";
  mem_fn_1 := cAddVariables(mem_fn_2, {mem_decl});
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

protected function generateFunctionReferenceWrapperBody 
  input Absyn.Path fpath;
  input DAE.Type inType;
  output list<CFunction> outCfns;
algorithm
  outCfns := matchcontinue (fpath,inType)
    local
      CFunction cfn, callCfn, convertCfn;
      Integer tnr;
      String fn_name_str, ret_stmt, ret_type_str, ret_type_str_box, ret_decl, ret_decl_box, ret_var, ret_var_box, callVar, tmp, mem_var, mem_decl, mem_stmt1, mem_stmt2;
      DAE.Type ty1,ty2,retType1,retType2;
      list<String> funcArgNames, funcArgTypeNames, funcArgVars, stringList, recordFields, recordFieldsBox, structStrs;
      list<DAE.Type> funcArgTypes1, funcArgTypes2, retTypeList1, retTypeList2;
      list<DAE.Exp> funcArgExps1, funcArgExps2, funcArgExps3, funcArgExps4, funcArgExps5;
      list<DAE.FuncArg> funcArgs1, funcArgs2;
      list<Integer> intList;
      DAE.Exp callExp;
      list<Algorithm.Statement> stmtList;
      Boolean isTuple;
      DAE.ComponentRef resCref;
      Integer i;
      // Only generate these functions if we use MetaModelica grammar
    /*case (fpath,ty1)
      equation
        false = RTOpts.debugFlag("fnptr") or RTOpts.acceptMetaModelicaGrammar();
      then {};*/
    case (fpath,ty1)
      equation
        failure(_ = Types.makeFunctionPolymorphicReference(ty1));
      then {};
    case (fpath,ty1)
      equation
        (DAE.T_FUNCTION(funcArgs1,retType1),_) = ty1;
        (ty2 as (DAE.T_FUNCTION(funcArgs2,retType2),_)) = Types.makeFunctionPolymorphicReference(ty1);
        tnr = 1;
        ret_type_str = generateReturnType(fpath);
        ret_type_str_box = ret_type_str +& "boxed";
        (ret_decl_box,ret_var_box,tnr) = generateTempDecl(ret_type_str_box, tnr);
        ret_stmt = Util.stringAppendList({"return ",ret_var_box,";"});
        fn_name_str = generateFunctionName(fpath);
        fn_name_str = "boxptr_" +& fn_name_str;
        funcArgNames = Util.listMap(funcArgs2, Util.tuple21);
        funcArgTypes2 = Util.listMap(funcArgs2, Util.tuple22);
        funcArgTypes1 = Util.listMap(funcArgs1, Util.tuple22);
        funcArgTypeNames = Util.listMap(funcArgTypes2, generateSimpleType);
        funcArgTypeNames = Util.listMap1(funcArgTypeNames, stringAppend, " ");
        funcArgVars = Util.listThreadMap(funcArgTypeNames, funcArgNames, stringAppend);
        funcArgExps1 = Util.listMap(funcArgNames, makeCrefExpFromString);
        // Unbox input args so we can call the regular function
        (funcArgExps2,_,_) = Types.matchTypeTuple(funcArgExps1, funcArgTypes2, funcArgTypes1, {}, Types.matchTypeRegular, true);
        isTuple = Types.isTuple(retType1);
        // Call the regular function
        (callCfn,callVar,tnr) = generateExpression(DAE.CALL(fpath,funcArgExps2,isTuple,false,DAE.ET_OTHER,false),tnr,funContext);
        resCref = DAE.CREF_IDENT(callVar,DAE.ET_OTHER,{});
        // Fix crefs for regular struct
        retTypeList1 = Types.resTypeToListTypes(retType1);
        i = listLength(retTypeList1);
        intList = Util.if_(i > 0, Util.listIntRange(i), {});
        stringList = Util.listMap(intList, intString);
        tmp = callVar +& "." +& ret_type_str +& "_";
        recordFields = Util.listMap1r(stringList,stringAppend,tmp);
        recordFields = Util.if_(isTuple or i == 0, recordFields, {callVar}); // Tuple calls return tmpX; regular calls return tmpX.X_rettype_1
        // Fix crefs for boxed struct
        retTypeList2 = Types.resTypeToListTypes(retType2);
        tmp = ret_var_box +& "." +& ret_type_str_box +& "_";
        recordFieldsBox = Util.listMap1r(stringList,stringAppend,tmp);
        
        // recordBoxedFields = Util.listMap1r(stringList,stringAppend,ret_type_str_box +& "_");
        funcArgExps3 = Util.listMap(recordFields, makeCrefExpFromString);
        // Convert unboxed result of regular function to boxed types
        (funcArgExps4,_,_) = Types.matchTypeTuple(funcArgExps3, retTypeList1, retTypeList2, {}, Types.matchTypeRegular, true);
        // Create assignments
        funcArgExps5 = Util.listMap(recordFieldsBox, makeCrefExpFromString);
        stmtList = Util.listThreadMap(funcArgExps5,funcArgExps4,makeAssignmentNoCheck);        
        // Assign boxed result
        (convertCfn,tnr) = generateAlgorithmStatements(stmtList,tnr,funContext);
        
        structStrs = generateFunctionRefReturnStruct1(retTypeList2, ret_type_str_box);
        cfn = cMakeFunction(ret_type_str_box, fn_name_str, structStrs, funcArgVars);
        cfn = cAddVariables(cfn, {ret_decl_box});
        
        (mem_decl,mem_var,tnr) = generateTempDecl("state", tnr);
        mem_stmt1 = Util.stringAppendList({mem_var," = get_memory_state();"});
        mem_stmt2 = Util.stringAppendList({"restore_memory_state(",mem_var,");"});
        
        cfn = cAddVariables(cfn, {mem_decl});
        cfn = cAddInits(cfn, {mem_stmt1});
        cfn = cMergeFns({cfn,callCfn,convertCfn});
        cfn = cAddCleanups(cfn, {mem_stmt2,ret_stmt});
      then {cfn};
    case (_,_)
      equation
        Debug.fprintln("failtrace", "- Codegen.generateFunctionReferenceWrapperBody failed");
      then fail();
  end matchcontinue;
end generateFunctionReferenceWrapperBody;

protected function makeAssignmentNoCheck
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output Algorithm.Statement stmt;
algorithm
  stmt := DAE.STMT_ASSIGN(DAE.ET_OTHER,lhs,rhs);
end makeAssignmentNoCheck;

protected function generateAllocOutvars 
"function: generateAllocOutvars
  Generates code for the allocation of output parameters of the function."
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
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      Option<DAE.Exp> e;
      list<DAE.Subscript> id;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> r;
      
    case ({},"",rv,i,tnr,context) then (cEmptyFunction,tnr);
      
    case ({},rd,rv,i,tnr,context)
      equation
        cfn = cAddVariables(cEmptyFunction, {rd});
      then
        (cfn,tnr);
        
    case (((var as DAE.VAR(componentRef = cr,
                           kind = vk,
                           direction = vd,
                           binding = e,
                           dims = id,
                           flowPrefix = flowPrefix,
                           streamPrefix = streamPrefix,
                           pathLst = class_,
                           variableAttributesOption = dae_var_attr,
                           absynCommentOption = comment)) :: r),rd,rv,i,tnr,context)
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

protected function generateAllocOutvar 
"function: generateAllocOutvar
  Helper function to generateAllocOutvars."
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
      DAE.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      Option<DAE.Exp> e;
      list<DAE.Subscript> inst_dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Context context;
      String iStr;
      
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = e,
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),prefix,i,tnr,context)
      equation
        is_a = isArray(var);
        iStr = intString(i);
        typ_str = generateType(typ,is_a);
        (cref_str1,_) = compRefCstr(id);
        cref_str2 = Util.stringAppendList({prefix,".","targ",iStr});
        emptypre = Util.isEmptyString(prefix);
        cref_str = Util.if_(emptypre, cref_str1, cref_str2);
        (cfn1,dim_strs,tnr1) = generateSizeSubscripts(cref_str, inst_dims, tnr, context);
        cfn1_1 = cMoveStatementsToInits(cfn1);
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        alloc_str = Util.stringAppendList({"alloc_", typ_str, "(&", cref_str, ", ", ndims_str, ", ", dims_str,");"});
        cfn_1 = cAddInits(cfn1_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_1, cfn1_1);
      then
        (cfn,tnr1);
        
    case (e,_,_,tnr,context)
      local DAE.Element e;
      equation
        failure(DAEUtil.isVar(e));
      then
        (cEmptyFunction,tnr);
        
  end matchcontinue;
end generateAllocOutvar;

protected function generateAllocOutvarsExt 
"function: generateAllocOutvarExt
  Helper function to generateAllocOutvars, for external functions."
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
      Lib rv,rett;
      Integer tnr,tnr1,tnr2;
      DAE.ExternalDecl extdecl;
      CFunction cfn1,cfn2,cfn;
      DAE.Element var;
      DAE.ComponentRef cr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      Option<DAE.Exp> e;
      list<DAE.Subscript> id;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      list<DAE.Element> r;
      
    case ({},rv,i,tnr,extdecl) then (cEmptyFunction,tnr);
      
    case (((var as DAE.VAR(componentRef = cr,
                           kind = vk,
                           direction = vd,
                           binding = e,
                           dims = id,
                           flowPrefix = flowPrefix,
                           streamPrefix = streamPrefix,
                           pathLst = class_,
                           variableAttributesOption = dae_var_attr,
                           absynCommentOption = comment)) :: r),rv,i,tnr,extdecl)
      equation
        DAE.EXTERNALDECL(returnType = rett) = extdecl;
        true = (rett ==& "C" or rett ==& "Java");
        (cfn1,tnr1) = generateAllocOutvar(var, rv, i,tnr, funContext);
        (cfn2,tnr2) = generateAllocOutvarsExt(r, rv,i+1,tnr1, extdecl);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,tnr2);
        
    case (((var as DAE.VAR(componentRef = cr,
                           kind = vk,
                           direction = vd,
                           binding = e,
                           dims = id,
                           flowPrefix = flowPrefix,
                           streamPrefix = streamPrefix,
                           pathLst = class_,
                           variableAttributesOption = dae_var_attr,
                           absynCommentOption = comment)) :: r),rv,i,tnr,extdecl)
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

protected function generateAllocOutvarF77 
"function generateAllocOutvarF77
  Helper function to generateAllocOutvars, for Fortran code."
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
      DAE.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      Option<DAE.Exp> e;
      list<DAE.Subscript> inst_dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = e,
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),prefix,i,tnr)
      equation
        is_a = isArray(var);
        typ_str = generateType(typ,is_a);
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
        alloc_str = Util.stringAppendList({"alloc_",typ_str,"(&",cref_str,", ",ndims_str,", ",dims_str,");"});
        cfn_1 = cAddInits(cfn1_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_1, cfn1_1);
      then
        (cfn,tnr1);
        
    case (e,_,_,tnr)
      local DAE.Element e;
      equation
        failure(DAEUtil.isVar(e));
      then
        (cEmptyFunction,tnr);
        
  end matchcontinue;
end generateAllocOutvarF77;

protected function generateSizeSubscripts 
"function: generateSizeSubscripts
  Generates code for calculating the subscripts of a variable."
  input String inString;
  input list<DAE.Subscript> inExpSubscriptLst;
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
      DAE.Exp e;
      list<DAE.Subscript> r,subs;
      
    case (_,{},tnr,context) then (cEmptyFunction,{},tnr);
      
    case (id,(DAE.INDEX(exp = e) :: r),tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e, tnr, context);
        (cfn2,vars2,tnr2) = generateSizeSubscripts(id, r, tnr1, context);
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,(var1 :: vars2),tnr2);
        
    case (id,subs,_,_)
      equation
        Debug.fprint("failtrace", "# Codegen.generateSizeSubscripts failed\n");
      then
        fail();
  end matchcontinue;
end generateSizeSubscripts;

protected function generateAllocArrayF77 
"function: generateAllocArrayF77
  Generates code for allocating an array in Fortran."
  input String inCref;
  input DAE.Type inType;
  output CFunction outCFunction;
algorithm
  outCFunction:=
  matchcontinue (inCref,inType)
    local
      DAE.Type elty,ty;
      list<Integer> dims;
      list<DAE.Subscript> dimsubs;
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
        typ_str = generateSimpleType(ty);
        ndims = listLength(dim_strs);
        ndims_str = intString(ndims);
        dims_str = Util.stringDelimitList(dim_strs, ", ");
        alloc_str = Util.stringAppendList({"alloc_",typ_str,"(&",crefstr,", ",ndims_str,", ",dims_str,");"});
        cfn = cAddInits(cfn1_1, {alloc_str});
      then
        cfn;
    case (_,_)
      equation
        Debug.fprint("failtrace", "#-- Codegen.generateAllocArrayF77 failed\n");
      then
        fail();
  end matchcontinue;
end generateAllocArrayF77;

protected function generateAlgorithms 
"function: generateAlgorithms
  Generates code for all algorithms in the DAE.Element list."
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
        algs = Util.listFilter(els, DAEUtil.isAlgorithm);
        (cfn,tnr_1) = generateAlgorithms2(algs, tnr, context);
      then
        (cfn,tnr_1);
  end matchcontinue;
end generateAlgorithms;

protected function generateAlgorithms2 
"function: generateAlgorithms2
  Helper function to generateAlgorithms"
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

public function generateAlgorithm 
"function generateAlgorithm
  Generates C-code for an DAE.Element that is ALGORITHM.
  The tab indent number is passed as argument."
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
      
    case (DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)),tnr,context)
      equation
        (cfn,tnr_1) = generateAlgorithmStatements(stmts, tnr, context);
      then
        (cfn,tnr_1);
        
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "# Codegen.generateAlgorithm failed\n");
      then
        fail();
  end matchcontinue;
end generateAlgorithm;

protected function generateAlgorithmStatements 
"function: generateAlgorithmStatements
  Generates code for a list of Algorithm.Statement."
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

protected function generateAlgorithmWhenStatement 
"function generateAlgorithmWhenStatement
	Generates code for algorithm when-statements.
	The condition expression is exchanged with help variables
	and code for updateing the help variable is generated prior
	to the if expression."
  input Algorithm.Statement whenStatement;
  input Integer nextTemp;
  input Context inContext;
  output CFunction block1;
  output CFunction block2;
  output Integer outNextTemp;
algorithm
  (block1, block2, outNextTemp) :=
  matchcontinue (whenStatement,nextTemp,inContext)
    local
      CFunction cfn, cfn1, cfn2, cfn3, cfn4, cfn5, elseBlock1, elseBlock2;
      DAE.Exp e, e1;
      list<DAE.Exp> el;
      list<Algorithm.Statement> stmts;
      Algorithm.Statement algStmt;
      Integer tnr, tnr1, tnr2, tnr3, tnr4;
      Lib crit_stmt, var1, var2;
      list<Lib> vars;
      Context context;
			list<Integer> helpVarIndices;
			Integer helpInd;
			
    case (DAE.STMT_WHEN(exp = e as DAE.ARRAY(array = el),statementLst = stmts, elseWhen=SOME(algStmt),helpVarIndices=helpVarIndices), tnr, context)
      equation
        // First generate code for updating the help variables in helpVarIndices
        // and the condition expression substitute the condition expression with a call to
        // edge(localData->helpVars[i])
        (cfn2, vars, tnr2) = generateWhenConditionExpressions(helpVarIndices,el,tnr,context);
				var1 = Util.stringDelimitList(vars," || ");
        crit_stmt = Util.stringAppendList({"if (",var1,") {"});
        cfn3 = cAddStatements(cEmptyFunction, {crit_stmt});
        (cfn4,tnr3) = generateAlgorithmStatements(stmts, tnr2, context);
        cfn5 = cAddStatements(cfn4, {"} else"});
        (elseBlock1, elseBlock2, tnr4) = generateAlgorithmWhenStatement(algStmt,tnr3,context);
        cfn4 = cMergeFns({cfn3, cfn5, elseBlock2});
        cfn  = cMergeFns({cfn2, elseBlock1});
      then (cfn,cfn4,tnr4);
        
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=SOME(algStmt), helpVarIndices=helpInd::_), tnr, context)
      equation
        (cfn2,var2,tnr2) = generateWhenConditionExpression(helpInd, e, tnr, context);
        crit_stmt = Util.stringAppendList({"if (",var2,") {"});
        cfn3 = cAddStatements(cEmptyFunction, {crit_stmt});
        (cfn4,tnr3) = generateAlgorithmStatements(stmts, tnr2, context);
        cfn5 = cAddStatements(cfn4, {"} else"});
        (elseBlock1, elseBlock2, tnr4) = generateAlgorithmWhenStatement(algStmt,tnr3,context);
        cfn4 = cMergeFns({cfn3, cfn5, elseBlock2});
        cfn  = cMergeFns({cfn2, elseBlock1});
      then (cfn,cfn4,tnr4);
        
    case (DAE.STMT_WHEN(exp = e as DAE.ARRAY(array = el),statementLst = stmts, elseWhen=NONE,helpVarIndices=helpVarIndices), tnr, context)
      equation
        (cfn2, vars, tnr2) = generateWhenConditionExpressions(helpVarIndices,el,tnr,context);
				var1 = Util.stringDelimitList(vars," || ");
        crit_stmt = Util.stringAppendList({"if (",var1,") {"});
        cfn3 = cAddStatements(cEmptyFunction, {crit_stmt});
        (cfn4,tnr3) = generateAlgorithmStatements(stmts, tnr2, context);
        cfn5 = cAddStatements(cfn4, {"}"});
        cfn4 = cMergeFns({cfn3, cfn5});
      then (cfn2,cfn4,tnr3);
        
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts, elseWhen=NONE,helpVarIndices=helpInd::_), tnr, context)
      equation
        (cfn2,var2,tnr2) = generateWhenConditionExpression(helpInd, e, tnr, context);
        crit_stmt = Util.stringAppendList({"if (",var2,") {"});
        cfn3 = cAddStatements(cEmptyFunction, {crit_stmt});
        (cfn4,tnr3) = generateAlgorithmStatements(stmts, tnr2, context);
        cfn5 = cAddStatements(cfn4, {"}"});
        cfn4 = cMergeFns({cfn3, cfn5});
      then (cfn2,cfn4,tnr3);

  end matchcontinue;
end generateAlgorithmWhenStatement;

protected function buildCrefFromAsub
  input DAE.ComponentRef cref;
  input list<DAE.Exp> subs;
  output DAE.ComponentRef cRefOut;
algorithm
  cRefOut := matchcontinue(cref, subs)
    local 
      DAE.Exp sub; 
      list<DAE.Exp> rest; 
      DAE.ComponentRef crNew;
      list<DAE.Subscript> indexes;
    case (cref, {}) then cref;
    case (cref, subs)
      equation
        indexes = Util.listMap(subs, Exp.makeIndexSubscript);
        crNew = Exp.subscriptCref(cref, indexes); 
      then
        crNew;
  end matchcontinue; 
end buildCrefFromAsub;

protected function generateAlgorithmStatement 
"function : generateAlgorithmStatement
   returns: CFunction | Code 
            int       | next temporary number"
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
      Lib var1,var2,stmt,cref_str,type_str,if_begin,sdecl,svar,dvar,ident_type_str,short_type,
          rdecl1,rvar1,rdecl2,rvar2,rdecl3,rvar3,e1var,e2var,e3var,r_stmt,for_begin,def_beg1,
          mem_begin,mem_end,for_end,def_end1,i,tdecl,tvar,idecl,ivar,array_type_str,evar,stmt_array,stmt_scalar,crit_stmt;
      Integer tnr1,tnr2,tnr,tnr3,tnr_1,tnr2_2,tnr2_3,tnr4,tnr_2;
      DAE.ExpType typ,t;
      DAE.ComponentRef cref;
      DAE.Exp exp,e,e1,e2;
      Context context;
      list<DAE.Subscript> subs;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Else else_;
      Algorithm.Statement algStmt;
      Absyn.Path path;
      list<DAE.Exp> args;
      Boolean a;
      CodeContext codeContext;
      ExpContext expContext;
      LoopContext loopContext;

    // Part of ValueBlock and MetaModelica implementation, special treatment of _ := VB case
    case (DAE.STMT_ASSIGN(_,DAE.CREF(DAE.WILD(),_),exp),tnr,context)
      equation
        (cfn,_,tnr1) = generateExpression(exp, tnr, context);
     then (cfn,tnr1);

    case (DAE.STMT_ASSIGN(type_ = typ,exp1 = DAE.CREF(cref,_),exp = exp),tnr,context)
      equation
        Debug.fprintln("cgas", "generate_algorithm_statement");
        (cfn1,var1,tnr1) = generateExpression(exp, tnr, context);
        (cfn2,var2,tnr2) = generateScalarLhsCref(typ, cref, tnr1, context);
        stmt = Util.stringAppendList({var2," = ",var1,";"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tnr2);
    
    /* adrpo: handle ASUB on LHS */ 
    /*case (DAE.STMT_ASSIGN(type_ = typ,exp1 = asub as DAE.ASUB(exp = DAE.CREF(cref,t), sub=subs),exp = exp),tnr,context)
      local 
        list<DAE.Exp> subs; DAE.Exp asub; DAE.ComponentRef crefBuild;
      equation
        Debug.fprintln("cgas", "generate_algorithm_statement");
        (cfn1,var1,tnr1) = generateExpression(exp, tnr, context);
        crefBuild = buildCrefFromAsub(cref,subs);
        (cfn2,var2,tnr2) = generateScalarLhsCref(typ, crefBuild, tnr1, context);
        stmt = Util.stringAppendList({var2," = ",var1,";"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tnr2);        */

    case (DAE.STMT_ASSIGN(type_ = typ,exp1 = e1,exp = exp),tnr,context)
      equation
        Debug.fprintln("cgas", "generate_algorithm_statement");
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);        
        (cfn2,var2,tnr2) = generateExpression(exp, tnr1, context);
        stmt = Util.stringAppendList({var1," = ",var2,";"});
        cfn_1 = cMergeFn(cfn1, cfn2);
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tnr2);
        
    case (DAE.STMT_ASSIGN_ARR(type_ = typ,componentRef = cref,exp = exp),tnr,context)
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
        
    case (DAE.STMT_ASSIGN_ARR(type_ = typ,componentRef = cref,exp = exp),tnr,context)
      equation
        (cref_str,(subs as (_ :: _))) = compRefCstr(cref);
        (cfn1,var1,tnr1) = generateExpression(exp, tnr, context);
        (cfn2,var2,tnr2) = generateIndexSpec(subs, tnr1, context);
        type_str = expTypeStr(typ, true);
        stmt = Util.stringAppendList({"indexed_assign_",type_str,"(&",var1,", &",cref_str,", &", var2,");"});
        cfn2_1 = cAddStatements(cfn2, {stmt});
        cfn = cMergeFn(cfn1, cfn2_1);
      then
        (cfn,tnr2);
        
    case (DAE.STMT_IF(exp = e,statementLst = then_,else_ = else_),tnr,context)
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
        
    case (DAE.STMT_FOR(type_ = t,boolean = a,ident = i,exp = e,statementLst = stmts),tnr,
                        context as CONTEXT(codeContext,expContext,loopContext))
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
        r_stmt = Util.stringAppendList({rvar1," = ",e1var,"; ",rvar2," = ",e2var,"; ",rvar3," = ",e3var,";"});
        for_begin = Util.stringAppendList({"for (",i," = ",rvar1,"; ","in_range_",short_type,"(",i,", ",rvar1,", ",rvar3,"); ",i," += ",rvar2,") {"});
        def_beg1 = Util.stringAppendList({"{\n  ",ident_type_str," ",i,";\n"});
        mem_begin = Util.stringAppendList({svar," = get_memory_state();"});
        (cfn4,tnr4) = generateAlgorithmStatements(stmts, tnr3,CONTEXT(codeContext,expContext,IN_FOR_LOOP(loopContext)));
        mem_end = Util.stringAppendList({"restore_memory_state(",svar,");"});
        for_end = "}";
        def_end1 = "} /* end for*/\n";
        cfn3_1 = cAddVariables(cfn3, {sdecl,rdecl1,rdecl2,rdecl3});
        cfn3_2 = cAddStatements(cfn3_1, {r_stmt,def_beg1,for_begin,mem_begin});
        cfn4_1 = cAddStatements(cfn4, {mem_end,for_end,def_end1});
        cfn = cMergeFns({cfn3_2,cfn4_1});
      then
        (cfn,tnr4);
        
    case (DAE.STMT_FOR(type_ = t,boolean = a,ident = i,exp = e,statementLst = stmts),tnr,
                        context as CONTEXT(codeContext,expContext,loopContext))
      equation
        (sdecl,svar,tnr_1) = generateTempDecl("state", tnr);
        (_,dvar,tnr_2) = generateTempDecl("", tnr_1);
        (tdecl,tvar,tnr1) = generateTempDecl("int", tnr_2);
        ident_type_str = expTypeStr(t, a);
        (idecl,ivar,tnr2) = generateTempDecl(ident_type_str, tnr1);
        array_type_str = expTypeStr(t, true);
        (cfn3,evar,tnr3) = generateExpression(e, tnr2, context);
        for_begin = Util.stringAppendList({"for (",tvar," = 1; ",tvar," <= size_of_dimension_",array_type_str,"(",evar,", 1); ","++",tvar,") {"});
        def_beg1 = Util.stringAppendList({"{\n  ",ident_type_str," ",i,";\n"});
        mem_begin = Util.stringAppendList({svar," = get_memory_state();"});
        stmt_array = Util.stringAppendList({"simple_index_alloc_",ident_type_str,"1(&",evar,", ",tvar,", &",ivar,"));"});
        stmt_scalar = Util.stringAppendList({i," = *(",array_type_str,"_element_addr1(&",evar,", 1, ",tvar,"));"});
        stmt = Util.if_(a, stmt_array, stmt_scalar) "Use fast implementation for 1 dim" ;
        (cfn4,tnr4) = generateAlgorithmStatements(stmts, tnr3,CONTEXT(codeContext,expContext,IN_FOR_LOOP(loopContext)));
        mem_end = Util.stringAppendList({"restore_memory_state(",svar,");"});
        for_end = "}";
        def_end1 = "} /* end for*/\n";
        cfn3_1 = cAddVariables(cfn3, {sdecl,tdecl,idecl});
        cfn3_2 = cAddStatements(cfn3_1, {def_beg1,for_begin,mem_begin,stmt});
        cfn4_1 = cAddStatements(cfn4, {mem_end,for_end,def_end1});
        cfn = cMergeFns({cfn3_2,cfn4_1});
      then
        (cfn,tnr4);
        
    case (DAE.STMT_WHILE(exp = e,statementLst = stmts),tnr,
                        context as CONTEXT(codeContext,expContext,loopContext))
      equation
        cfn1 = cAddStatements(cEmptyFunction, {"while (1) {"});
        (cfn2,var2,tnr2) = generateExpression(e, tnr, context);
        crit_stmt = Util.stringAppendList({"if (!",var2,") break;"});
        cfn2_1 = cAddStatements(cfn2, {crit_stmt});
        (cfn3,tnr3) = generateAlgorithmStatements(stmts, tnr2, CONTEXT(codeContext,expContext,IN_WHILE_LOOP(loopContext)));
        cfn3_1 = cAddStatements(cfn3, {"}"});
        cfn = cMergeFns({cfn1,cfn2_1,cfn3_1});
      then
        (cfn,tnr3);
        
    case (algStmt as DAE.STMT_WHEN(exp = _),tnr,context as CONTEXT(SIMULATION(true),_,_))
      equation
        (cfn1,cfn2,tnr1) = generateAlgorithmWhenStatement(algStmt,tnr,context);
        cfn = cMergeFns({cfn1,cfn2});
      then
        (cfn,tnr1);
        
    case (algStmt as DAE.STMT_WHEN(exp = _),tnr,CONTEXT(SIMULATION(false),_,_))
    then (cEmptyFunction,tnr);

    case (DAE.STMT_TUPLE_ASSIGN(t,expl,e as DAE.CALL(path=_)),tnr,context)
      local Context context;
        list<DAE.Exp> args,expl; Absyn.Path fn;
        list<String> lhsVars,vars1;
        String tupleVar;
      equation
        (cfn1,tupleVar,tnr1) = generateExpression(e, tnr, context);
				(cfn,tnr2) = generateTupleLhsAssignment(expl,tupleVar,1,tnr1,context);
				cfn = cMergeFn(cfn1,cfn);
      then
        (cfn,tnr2);

    case (DAE.STMT_ASSERT(cond = e1,msg = e2),tnr,CONTEXT(codeContext,_,loopContext))
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
        
    case (DAE.STMT_RETURN(),tnr,_)
      local Lib retStmt;
      equation
        cfn = cAddStatements(cEmptyFunction, {"goto _return;"});
      then
        (cfn,tnr);
        
    case (DAE.STMT_BREAK(),tnr,CONTEXT(_,_,NO_LOOP()))
      equation
        Error.addMessage(Error.BREAK_OUT_OF_LOOP, {});
      then
        fail(); // We need to force a failure if we are going to see that error message !
        
    case (DAE.STMT_BREAK(),tnr,_)
      equation
        cfn = cAddStatements(cEmptyFunction, {"break;"});
      then
        (cfn,tnr);

    // Part of MetaModelica Extension. KS
    //--------------------------------
    case (DAE.STMT_TRY(stmts),tnr,context)
      equation
        cfn1 = cAddStatements(cEmptyFunction, {"try {"}); // try
        (cfn2,tnr2) = generateAlgorithmStatements(stmts, tnr,
           context);
        cfn2_1 = cAddStatements(cfn2, {"}"});
        cfn = cMergeFns({cfn1,cfn2_1});
      then
        (cfn,tnr2);

    case (DAE.STMT_CATCH(stmts),tnr,context)
      equation
        cfn1 = cAddStatements(cEmptyFunction, {"catch(int i) {"}); //catch(int i)
        (cfn2,tnr2) = generateAlgorithmStatements(stmts, tnr,
          context);
        cfn2_1 = cAddStatements(cfn2, {"}"});
        cfn = cMergeFns({cfn1,cfn2_1});
      then
        (cfn,tnr);

    case (DAE.STMT_THROW(),tnr,context)
      equation
        cfn = cAddStatements(cEmptyFunction, {"throw 1;"});
      then (cfn,tnr);

    case (DAE.STMT_GOTO(s),tnr,context)
      local
        String s,s2;
      equation
        s2 = stringAppend("goto ",s);
        s2 = stringAppend(s2,";");
        cfn = cAddStatements(cEmptyFunction, {s2});
      then (cfn,tnr);

    case (DAE.STMT_LABEL(s),tnr,context)
      local
        String s,s2;
      equation
        s2 = stringAppend(s,":");
        cfn = cAddStatements(cEmptyFunction, {s2});
      then (cfn,tnr);
        
    // Calling a function with no output - stefan
    case (DAE.STMT_NORETCALL(exp),tnr,context)
      equation
        (cfn,_,tnr) = generateExpression(exp,tnr,context);
      then (cfn, tnr);
        
	  case (DAE.STMT_MATCHCASES(exps), tnr, CONTEXT(codeContext,expContext,loopContext)) // matchcontinue helper
      local
        list<Integer> il;
        list<DAE.Exp> exps;
        list<CFunction> cfnList, labelFnList;
        list<String> caseStmt;
        list<list<String>> caseStmtLst;
        CFunction breakFn, cfn_for_switch;
        Integer listLen;
        String tmp_decl_loop_ix, tmp_name_loop_ix, tmp_decl_done, tmp_name_done, tmp_assign_done, tmp_assign_not_done, switch_exp, for_exp, try_exp, catch_exp, check_done_exp, listLenStr;
      equation
        (tmp_decl_loop_ix, tmp_name_loop_ix, tnr) = generateTempDecl("modelica_integer", tnr);
        (tmp_decl_done, tmp_name_done, tnr) = generateTempDecl("modelica_integer", tnr);
        tmp_decl_loop_ix = tmp_decl_loop_ix +& " /* loop index */";
        tmp_decl_done = tmp_decl_done +& " /* switch done? */";
        (cfnList,tnr) = generateExpressionsToList(exps, tnr, CONTEXT(codeContext,expContext,IN_FOR_LOOP(loopContext)));
        listLen = listLength(exps);
        listLenStr = intString(listLen);
        il = Util.listIntRange2(0, listLen-1);
	      caseStmt = Util.listMap(il, intString);
	      caseStmt = Util.listMap1(caseStmt, stringAppend, ": {");
	      caseStmt = Util.listMap1r(caseStmt, stringAppend, "case ");
	      caseStmtLst = Util.listMap(caseStmt, Util.listCreate);
	      labelFnList = Util.listMap1r(caseStmtLst, cAddStatements, cEmptyFunction);
	      cfnList = Util.listThreadMap(labelFnList, cfnList, cMergeFn);
	      tmp_assign_done = tmp_name_done +& " = 1;";
	      tmp_assign_not_done = tmp_name_done +& " = 0;";
	      breakFn = cAddStatements(cEmptyFunction, {tmp_assign_done, "break;"});
	      cfnList = Util.listMap1(cfnList, cMergeFn, breakFn);
	      cfnList = Util.listMap1(cfnList, cAddStatements, {"};"});
	      cfn = cMergeFns(cfnList);
	      for_exp = Util.stringAppendList({"for (",tmp_name_loop_ix,"=0; 0==",tmp_name_done," && ",tmp_name_loop_ix,"<",listLenStr,";",tmp_name_loop_ix,"++) {"});
	      try_exp = Util.stringAppendList({"try {"});
	      switch_exp = Util.stringAppendList({"switch (", tmp_name_loop_ix, ") {"});
	      catch_exp = Util.stringAppendList({"} catch (int i) {"});
	      check_done_exp = Util.stringAppendList({"if (0 == ",tmp_name_done,") throw 1; /* Didn't end in a valid state */"});
	      cfn_for_switch = cAddStatements(cEmptyFunction, {for_exp, try_exp, switch_exp});
	      cfn = cMergeFn(cfn_for_switch, cfn);
	      cfn = cAddStatements(cfn, {"} /* end matchcontinue switch */", catch_exp, "}", "} /* end matchcontinue for */", check_done_exp});
	      cfn = cAddInits(cfn, {tmp_assign_not_done});
	      cfn = cAddVariables(cfn, {tmp_decl_loop_ix, tmp_decl_done});
      then (cfn, tnr);
        
    //-------------------------------
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "# Codegen.generateAlgorithmStatement failed\n");        
      then
        fail();
  end matchcontinue;
end generateAlgorithmStatement;

protected function generateTupleLhsAssignment 
"function generateTupleLhsAssignment
  author: PA
  Generates the assignment of output args in a tuple call
  given a variable containing the tuple represented as a struct."
  input list<DAE.Exp> expl;
  input String tupleVar;
  input Integer i "nth tuple elt";
  input Integer tnr;
  input Context context;
  output CFunction cfn;
  output Integer outTnr;
algorithm
  (cfn,outTnr) := matchcontinue(expl,tupleVar,i,tnr,context)
  local DAE.ComponentRef cr;
    String res1,stmt,iStr;
    CFunction cfn2;
    DAE.Ident id;
    DAE.ExpType tp;
    list<tuple<DAE.ExpType,DAE.Ident>> vars;
    case({},tupleVar,i,tnr,context) then (cEmptyFunction,tnr);
    case(DAE.CREF(cr,tp)::expl,tupleVar,i,tnr,context) equation
      (cfn,res1,tnr) = generateScalarLhsCref(tp,cr,tnr,context);
      iStr = intString(i);
      stmt = Util.stringAppendList({res1," = ",tupleVar,".","targ",iStr,";"});
      cfn = cAddStatements(cfn, {stmt});
      (cfn2,tnr) = generateTupleLhsAssignment(expl,tupleVar,i+1,tnr,context);
      cfn = cMergeFn(cfn,cfn2);
    then (cfn,tnr);
  end matchcontinue;
end generateTupleLhsAssignment;

protected function isSimulationContext 
"Returns true is context is Simulation."
  input Context context;
  output Boolean res;
algorithm
  res := matchcontinue(context)
    case(CONTEXT(SIMULATION(_),_,_)) then true;
    case(_) then false;
  end matchcontinue;
end isSimulationContext;

protected function generateRangeExpressions 
"function: generateRangeExpressions
  Generates code for a range expression."
  input DAE.Exp inExp;
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
      DAE.ExpType t;
      DAE.Exp e1,e3,e2;
      Context context;
    case (DAE.RANGE(ty = t,exp = e1,expOption = NONE,range = e3),tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        var2 = "(1)";
        (cfn3,var3,tnr3) = generateExpression(e3, tnr1, context);
        cfn = cMergeFn(cfn1, cfn3);
      then
        (cfn,var1,var2,var3,tnr3);
    case (DAE.RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3),tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (cfn3,var3,tnr3) = generateExpression(e3, tnr2, context);
        cfn = cMergeFns({cfn1,cfn2,cfn3});
      then
        (cfn,var1,var2,var3,tnr3);
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "# Codegen.generateRangeExpressions failed\n");
      then
        fail();
  end matchcontinue;
end generateRangeExpressions;

protected function generateElse 
"function generateElse
  Generates code for an Else branch."
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
      DAE.Exp e;
      list<Algorithm.Statement> stmts;
      Algorithm.Else else_;
      Context context;
    case (DAE.NOELSE(),tnr,_) then (cEmptyFunction,tnr);
    case (DAE.ELSEIF(exp = e,statementLst = stmts,else_ = else_),tnr,context)
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
    case (DAE.ELSE(statementLst = stmts),tnr,context)
      equation
        cfn1 = cAddStatements(cEmptyFunction, {"else {"});
        (cfn2,tnr2) = generateAlgorithmStatements(stmts, tnr, context);
        cfn2_1 = cAddStatements(cfn2, {"}"});
        cfn = cMergeFn(cfn1, cfn2_1);
      then
        (cfn,tnr2);
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-Codegen.generateElse failed\n");
      then
        fail();
  end matchcontinue;
end generateElse;

protected function generateVars 
"function: generateVars
  Generates code for variables, given a list of elements and a function
  over the elements. Code is only generated for elements for which the
  function succeeds."
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
        Debug.fprint("failtrace", "# Codegen.generateVars failed\n");
      then
        fail();
  end matchcontinue;
end generateVars;

protected function generateVarDecls 
"function: generateVarDecls
  Generates declaration code for variables given a DAE.Element list
  and a function over elements. Code is only generated for Elements for
  which the function succeeds."
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
        Debug.fprint("failtrace", "# Codegen.generateVarDecls failed\n");
      then
        fail();
  end matchcontinue;
end generateVarDecls;

protected function generateVarInits 
"function: generateVarInits
  Generates initialization code for variables given a DAE.Element list
  and a function over elements. Code is only generated for Elements for
  which the function succeeds."
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
        Debug.fprint("failtrace", "# Codegen.generateVarInits failed\n");
      then
        fail();
  end matchcontinue;
end generateVarInits;

protected function generateVar 
"function: generateVar
  Generates code for a variable."
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
      Lib typ_str,cref_str,dimvars_str,dims_str,dim_comment,dim_comment_1,ndims_str,decl_str,alloc_str,init_stmt,var_str;
      CFunction cfn1_1,cfn1,cfn_1,cfn_2,cfn,cfn2;
      list<Lib> vars1,dim_strs;
      Integer tnr1,ndims,tnr;
      DAE.Element var;
      DAE.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      list<DAE.Subscript> inst_dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Context context;
      DAE.Exp e;
      DAE.ExpType etp;

    /* variables without binding */
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = NONE,
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),tnr,context)
      equation
        is_a = isArray(var);
        typ_str = generateType(typ,is_a);
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
        alloc_str = Util.stringAppendList({"alloc_",typ_str,"(&",cref_str,", ",ndims_str,", ",dimvars_str,");"});
        cfn_1 = cAddVariables(cfn1, {decl_str});
        cfn_2 = cAddInits(cfn_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_2, cfn_1);
      then
        (cfn,tnr1);

    /* variables with binding */
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = SOME(e),
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),tnr,context)
      equation
        is_a = isArray(var);
        typ_str = generateType(typ,is_a);
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
        alloc_str = Util.stringAppendList({"alloc_",typ_str,"(&",cref_str,", ",ndims_str,", ",dimvars_str,");"});
        cfn_1 = cAddVariables(cfn1, {decl_str});
        cfn_2 = cAddInits(cfn_1, {alloc_str});
        cfn = Util.if_(is_a, cfn_2, cfn_1);
        etp = Exp.typeof(e);
        (cfn2,tnr1) = generateAlgorithmStatement(DAE.STMT_ASSIGN(etp,DAE.CREF(id,etp),e),tnr1,context);
        cfn = cMergeFn(cfn,cfn2);
      then
        (cfn,tnr1);
    
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = SOME(e),
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),tnr,context)
      equation
        is_a = isArray(var);
        typ_str = generateType(typ,is_a);
        (cref_str,_) = compRefCstr(id);
        decl_str = Util.stringAppendList({typ_str," ",cref_str,";"});
        (cfn,var_str,tnr1) = generateExpression(e, tnr, context);
        cfn_1 = cAddVariables(cfn, {decl_str});
        init_stmt = Util.stringAppendList({cref_str," = ",var_str,";"});
        cfn_2 = cAddInits(cfn_1, {init_stmt});
        Print.printBuf("# default value not implemented yet: ");
        Exp.printExp(e);
        Print.printBuf("\n");
      then
        (cfn_2,tnr1);
        
    case (e,_,_)
      local DAE.Element e;
      equation
        Debug.fprint("failtrace", "- Codegen.generateVar failed\n");
      then
        fail();
  end matchcontinue;
end generateVar;

protected function generateVarDecl 
"function generateVarDecl
  Generates code for a variable declaration."
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
      DAE.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      list<DAE.Subscript> inst_dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Context context;
      DAE.Exp e;
      DAE.Type tp;
      Absyn.InnerOuter io;
      DAE.VarProtection prot;
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = NONE,
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),tnr,context)
      equation
        is_a = isArray(var);
        typ_str = generateType(typ,is_a);
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
        
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          protection=prot,
                          ty = typ,
                          binding = SOME(e),
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment,
                          innerOuter=io)),tnr,context)
      equation
        (cfn,tnr1) = generateVarDecl(DAE.VAR(id,vk,vd,prot,typ,NONE,inst_dims,flowPrefix,streamPrefix,class_,dae_var_attr,comment,io), tnr, context);
      then
        (cfn,tnr1);
        
    case (e,_,_)
      local DAE.Element e;
      equation
        Debug.fprint("failtrace", "# Codegen.generateVarDecl failed\n");
      then
        fail();
  end matchcontinue;
end generateVarDecl;

protected function generateVarInit 
"function generateVarInit
  Generates code for the initialization of a variable."
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
      DAE.ComponentRef id,id_1,idstr;
      DAE.Exp expstr;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type typ;
      list<DAE.Subscript> inst_dims;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<Absyn.Path> class_;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      Integer tnr,tnr1;
      Lib pre;
      Context context;
      Boolean is_a,emptyprep;
      DAE.ExpType exptype;
      Algorithm.Statement scalarassign,arrayassign,assign;
      CFunction cfn;
      DAE.Exp e;
      String iStr,id_1_str;
      
    /* No binding */
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = NONE,
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),i,tnr,pre,context)
      then (cEmptyFunction,tnr);

    /* Has binding */
    case ((var as DAE.VAR(componentRef = id,
                          kind = vk,
                          direction = vd,
                          ty = typ,
                          binding = SOME(e),
                          dims = inst_dims,
                          flowPrefix = flowPrefix,
                          streamPrefix = streamPrefix,
                          pathLst = class_,
                          variableAttributesOption = dae_var_attr,
                          absynCommentOption = comment)),i,tnr,pre,context)
      equation
        is_a = isArray(var);
        // pre can be "" or "out", the later for output variables.
        emptyprep = stringEqual(pre, "");
        iStr = intString(i);
        id_1_str = Util.stringAppendList({"out.","targ",iStr});
        expstr = Util.if_(emptyprep, 
                         DAE.CREF(id, DAE.ET_OTHER()), 
                         DAE.CREF(DAE.CREF_IDENT(id_1_str,DAE.ET_OTHER(),{}),DAE.ET_OTHER()));
        idstr = Util.if_(emptyprep, 
                         id, 
                         DAE.CREF_IDENT(id_1_str,DAE.ET_OTHER(),{}));
        exptype = Types.elabType(typ);
        scalarassign = DAE.STMT_ASSIGN(exptype,expstr,e);
        arrayassign = DAE.STMT_ASSIGN_ARR(exptype,idstr,e);
        assign = Util.if_(is_a, arrayassign, scalarassign);
        (cfn,tnr1) = generateAlgorithmStatement(assign, tnr, context);
      then
        (cfn,tnr1);
        
    case (e,_,_,_,_)
      local DAE.Element e;
      equation
        Debug.fprint("failtrace", "# Codegen.generateVarInit failed\n");
      then
        fail();
  end matchcontinue;
end generateVarInit;

protected function dimString 
"function dimString
  Returns a DAE.Subscript as a string."
  input DAE.Subscript inSubscript;
  output String outString;
algorithm
  outString:=
  matchcontinue (inSubscript)
    local
      Lib str;
      Integer i;
      DAE.Subscript e;
    case DAE.INDEX(exp = DAE.ICONST(integer = i))
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
        print("Codegen.dimString failed\n");
      then
        fail();
  end matchcontinue;
end dimString;

protected function isVarQ 
"function isVarQ
  Succeds if DAE.Element is a variable or constant that is not input."
  input DAE.Element inElement;
algorithm
  _:=  matchcontinue (inElement)
    local
      DAE.ComponentRef id;
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(componentRef = id,kind = vk,direction = vd)
      equation
        generateVarQ(vk);
        generateVarQ2(vd);
      then
        ();
  end matchcontinue;
end isVarQ;

protected function generateVarQ 
"function generateVarQ
  Helper function to isVarQ."
  input DAE.VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    case DAE.VARIABLE() then ();
    case DAE.PARAM() then ();
  end matchcontinue;
end generateVarQ;

protected function generateVarQ2 
"function generateVarQ2
  Helper function to isVarQ."
  input DAE.VarDirection inVarDirection;
algorithm
  _:=
  matchcontinue (inVarDirection)
    case DAE.OUTPUT() then ();
    case DAE.BIDIR() then ();
  end matchcontinue;
end generateVarQ2;

protected function generateResultVars 
"function generateResultVars
  Generates code for output variables."
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

protected function generateResultVar 
"function generateResultVar
  Helper function to generateResultVars."
  input DAE.Element inElement;
  input String inString;
  input Integer i;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger) := matchcontinue (inElement,inString,i,inInteger,inContext)
    local
      Lib cref_str1,cref_str2,stmt,varname,typ_str;
      CFunction cfn;
      DAE.Element var;
      DAE.ComponentRef id;
      DAE.Type typ;
      Integer tnr;
      Context context;
      
    /* varname non-arrays */
    case ((var as DAE.VAR(componentRef = id,kind = DAE.VARIABLE(),direction = DAE.OUTPUT(),ty = typ)),varname,i,tnr,context)
      equation
        false = isArray(var);
        cref_str1 = stringAppend("targ",intString(i));
        (cref_str2,_) = compRefCstr(id);
        stmt = Util.stringAppendList({varname,".",cref_str1," = ",cref_str2,";"});
        cfn = cAddCleanups(cEmptyFunction, {stmt});
      then
        (cfn,tnr);
        
    /* arrays */
    case ((var as DAE.VAR(componentRef = id,kind = DAE.VARIABLE(),direction = DAE.OUTPUT(),ty = typ)),varname,i,tnr,context)
      equation
        true = isArray(var);
        typ_str = generateType(typ,true);
        (cref_str1,_) = compRefCstr(id);
        cref_str2 = stringAppend("targ",intString(i));
        stmt = Util.stringAppendList({"copy_",typ_str,"_data(&",cref_str1,", &",varname,".",cref_str2,");"});
        cfn = cAddCleanups(cEmptyFunction, {stmt});
      then
        (cfn,tnr);
        
  end matchcontinue;
end generateResultVar;

protected function generateWhenConditionExpressions
	input list<Integer> helpVarIndices;
	input list<DAE.Exp> exprLst;
	input Integer tempNr;
  input Context inContext;
  output CFunction outCFunction;
  output list<String> outStringLst;
  output Integer outInteger;
algorithm
  (outCFunction,outStringLst,outInteger):=
  matchcontinue (helpVarIndices,exprLst,tempNr,inContext)
    local
      Context context;
      Integer ind;
      list<Integer> indRest;
      Integer tnr, tnr2, tnr3;
      DAE.Exp e;
      list<DAE.Exp> eRest;
      String var;
      list<String> vars;
			CFunction cfn,cfn1,cfn2;
    case ({},{},tnr,context) then (cEmptyFunction, {}, tnr);

    case (ind::indRest,e::eRest,tnr,context)
      equation
        (cfn1,var,tnr2) = generateWhenConditionExpression(ind,e,tnr,context);
        (cfn2,vars,tnr3) = generateWhenConditionExpressions(indRest,eRest,tnr2,context);
				cfn = cMergeFn(cfn1,cfn2);
      then (cfn, var::vars, tnr3);
  end matchcontinue;
end generateWhenConditionExpressions;

protected function generateWhenConditionExpression
	input Integer helpVarIndex;
	input DAE.Exp expr;
	input Integer tempNr;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm
  (outCFunction,outString,outInteger):=
  matchcontinue (helpVarIndex,expr,tempNr,inContext)
    local
      Context context;
      Integer ind;
      Integer tnr, tnr2;
      DAE.Exp e;
      String edgeExprStr;
      String helpUpdateStr;
      String var;
      String indStr;
      CFunction cfn, cfn2;
    case (ind,e,tnr,context)
      equation
        (cfn,var,tnr2) = generateExpression(e,tnr,context);
        indStr = intString(ind);
        helpUpdateStr = Util.stringAppendList({"localData->helpVars[",indStr,"] = ", var, ";"});
        edgeExprStr = Util.stringAppendList({"edge(localData->helpVars[",indStr,"])"});
        cfn2 = cAddStatements(cfn, {helpUpdateStr});
      then (cfn2, edgeExprStr, tnr2);
  end matchcontinue;
end generateWhenConditionExpression;

public function generateExpressions 
"function: generateExpressions
  Generates code for a list of expressions."
  input list<DAE.Exp> inExpExpLst;
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
      DAE.Exp f;
      list<DAE.Exp> r;
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

public function generateExpressionsToList "As generateExpression outputs a list<CFunction>"
  input list<DAE.Exp> inExps;
  input Integer inInteger;
  input Context inContext;
  output list<CFunction> outCFunction;
  output Integer outTnr;
algorithm
  (outCFunction,_,_) := matchcontinue (inExps, inInteger, inContext)
    local
      DAE.Exp inExp;
      list<DAE.Exp> rest;
      CFunction cfn;
      list<CFunction> cfns;
    case ({}, inInteger, _) then ({},inInteger);
    case (inExp :: rest, inInteger, inContext)
      equation
        (cfn, _, inInteger) = generateExpression(inExp, inInteger, inContext);
        (cfns, inInteger) = generateExpressionsToList(rest, inInteger, inContext);
      then (cfn :: cfns, inInteger);
  end matchcontinue;
end generateExpressionsToList;

public function generateExpression "function: generateExpression

  Generates code for an expression.
  returns
   CFunction | the generated code
   string    | expression result variable name, or c expression
   int       | next temporary number
"
  input DAE.Exp inExp;
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
      Lib tvar1, tvar2, tvar3, decl1, decl2, decl3, decl4;
      Lib assign_str;
      Integer i,j,tnr,tnr_1,tnr1,tnr1_1,tnr2,tnr3,nvars,maxn,tnr4,tnr5,tnr6;
      Context context;
      Real r;
      Boolean b,builtin,a;
      CFunction cfn,cfn1,cfn1_2,cfn1_1,cfn2,cfn2_1,cfn3,cfn3_1,cfn4,cfn_1,cfn5;
      DAE.ComponentRef cref,cr;
      DAE.ExpType t,ty;
      DAE.Exp e1,e2,e,then_,else_,crexp,dim,e3;
      DAE.Operator op;
      Absyn.Path fn;
      list<DAE.Exp> args,elist;
      list<Lib> vars1;
      list<list<tuple<DAE.Exp, Boolean>>> ell;
    case (DAE.ICONST(integer = i),tnr,context)
      equation
        istr = intString(i);
      then
        (cEmptyFunction,istr,tnr);
    case (DAE.RCONST(real = r),tnr,context)
      equation
        rstr = realString(r);
      then
        (cEmptyFunction,rstr,tnr);
	  //Strings are stored as char*, therefor return data member of modelica_string struct.
    case (DAE.SCONST(string = s),tnr,context)
      local String stmt,tvar_data; CFunction cfn;
      equation
        (decl,tvar,tnr1_1) = generateTempDecl("modelica_string", tnr);
        s = Util.escapeModelicaStringToCString(s);
        stmt = Util.stringAppendList({"init_modelica_string(&",tvar,",\"",s,"\");"});
        cfn = cAddStatements(cEmptyFunction, {stmt});
        cfn = cAddVariables(cfn, {decl});
      then
        (cfn,tvar,tnr1_1);
    case (DAE.BCONST(bool = b),tnr,context)
      equation
        var = Util.if_(b, "(1)", "(0)");
      then
        (cEmptyFunction,var,tnr);
		case (DAE.CREF(cref, t as DAE.ET_ARRAY(_,_)), tnr, context)
			equation
				(cfn, var, tnr_1) = generateRhsCref(cref, t, tnr, context);
			then
				(cfn, var, tnr_1);
    case (DAE.CREF(componentRef = cref,ty = t),tnr,context)
      equation
        (cfn,var,tnr_1) = generateRhsCref(cref, t, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),tnr,context)
      equation
        (cfn,var,tnr_1) = generateBinary(e1, op, e2, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.UNARY(operator = op,exp = e),tnr,context)
      equation
        (cfn,var,tnr_1) = generateUnary(op, e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),tnr,context)
      equation
        (cfn,var,tnr_1) = generateLbinary(e1, op, e2, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.LUNARY(operator = op,exp = e),tnr,context)
      equation
        (cfn,var,tnr_1) = generateLunary(op, e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),tnr,context as CONTEXT(codeContext=SIMULATION(true)))
      local
        String op_str;
      equation
        true = isRealTypedRelation(op);
        op_str = relOpStr(op);
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        cfn3 = cMergeFns({cfn1,cfn2});
        (decl1,var,tnr3) = generateTempDecl("modelica_boolean", tnr2);
				assign_str = Util.stringAppendList({op_str,"(",var,",",var1,",",var2,");"});
				cfn4 = cAddStatements(cfn3,{assign_str});
				cfn5 = cAddVariables(cfn4,{decl1});
      then
        (cfn5,var,tnr3);
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),tnr,context)
      equation
        (cfn,var,tnr_1) = generateRelation(e1, op, e2, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.IFEXP(expCond = e,expThen = then_,expElse = else_),tnr,context)
      equation
        (cfn1,var1,tnr) = generateExpression(e, tnr, context);
        (decl,tvar1,tnr) = generateTempDecl("modelica_boolean", tnr);
        b_stmt = Util.stringAppendList({tvar1," = ",var1,";"});
        t = Exp.typeof(then_); // The IFEXP has the same type for both then_ and else_
        type_string = expTypeStr(t,Exp.isArrayType(t));
        (tdecl,tvar2,tnr) = generateTempDecl(type_string, tnr);
        if_begin = Util.stringAppendList({"if (",tvar1,") {"});
        cfn1_2 = cAddStatements(cfn1, {b_stmt,if_begin});
        cfn1_1 = cAddVariables(cfn1_2, {decl,tdecl});
        (cfn2,var2,tnr) = generateExpression(then_, tnr, context);
        stmt = tvar2 +& " = " +& var2 +& ";";
        cfn2_1 = cAddStatements(cfn2, {stmt,"}","else {"});
        (cfn3,var3,tnr) = generateExpression(else_, tnr, context);
        stmt = tvar2 +& " = " +& var3 +& ";";
        cfn3_1 = cAddStatements(cfn3, {stmt,"}"});
        cfn = cMergeFns({cfn1_1,cfn2_1,cfn3_1});
      then
        (cfn,tvar2,tnr);
        
        /* some buitlin functions that are e.g. overloaded */
    case ((e as DAE.CALL(path = fn,expLst = args,tuple_ = false,builtin = true)),tnr,context)
      equation
        (cfn,var,tnr2) = generateBuiltinFunction(e, tnr, context);
      then
        (cfn,var,tnr2);

        /* no-ret calls */
    case (DAE.CALL(path = fn,expLst = args,tuple_ = false,builtin = builtin,ty=DAE.ET_NORETCALL),tnr,context)
      equation
        (cfn1,vars1,tnr1) = generateExpressions(args, tnr, context);
        ret_type = generateReturnType(fn);
        fn_name = generateFunctionName(fn);
        args_str = Util.stringDelimitList(vars1, ", ");
        underscore = Util.if_(builtin, "", "_");
        stmt = Util.stringAppendList({underscore,fn_name,"(",args_str,");"}) "builtin fcns no underscore" ;
        cfn = cAddStatements(cfn1, {stmt});
      then
        (cfn,"/* NORETCALL */",tnr1);

        /* non-tuple calls */
    case (DAE.CALL(path = fn,expLst = args,tuple_ = false,builtin = builtin),tnr,context)
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
    case (DAE.CALL(path = fn,expLst = args,tuple_ = true,builtin = builtin),tnr,context)
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

    case (DAE.SIZE(exp = (crexp as DAE.CREF(componentRef = cr,ty = ty)),sz = SOME(dim)),tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(crexp, tnr, context);
        (tdecl,tvar,tnr2) = generateTempDecl("size_t", tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        typestr = expTypeStr(ty, true);
        (cfn3,var2,tnr3) = generateExpression(dim, tnr2, context);
        stmt = Util.stringAppendList({tvar," = size_of_dimension_",typestr,"(",var1,",",var2,");"});
        cfn4 = cMergeFn(cfn2, cfn3);
        cfn = cAddStatements(cfn4, {stmt});
      then
        (cfn,tvar,tnr2);

    case (DAE.SIZE(exp = cr,sz = NONE),tnr,context)
      local DAE.Exp cr;
      equation
        Debug.fprint("failtrace", "#-- Codegen.generate_expression: size(X) not implemented");
      then
        fail();
        /* Special case for empty arrays, create null pointer*/
   case (e as DAE.ARRAY(ty = t,scalar = a,array = {}),tnr,context)
      local DAE.Exp e;
      equation
        array_type_str = expTypeStr(t, true);
        short_type_str = expShortTypeStr(t);
        (tdecl,tvar,tnr1) = generateTempDecl(array_type_str, tnr);
        scalar = Util.if_(a, "scalar_", "");
        scalar_ref = Util.if_(a, "", "&");
        scalar_delimit = stringAppend(", ", scalar_ref);
        stmt = Util.stringAppendList({"array_alloc_",scalar,array_type_str,"(&",tvar,", 0, ",scalar_ref,",0);"});
        cfn_1 = cAddVariables(cEmptyFunction, {tdecl});
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tvar,tnr1);
        /* array */
    case (e as DAE.ARRAY(ty = t,scalar = a,array = elist),tnr,context)
      local DAE.Exp e;
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
        stmt = Util.stringAppendList({"array_alloc_",scalar,array_type_str,"(&",tvar,", ",nvars_str,", ",scalar_ref,args_str,");"});
        cfn_1 = cAddVariables(cfn1, {tdecl});
        cfn = cAddStatements(cfn_1, {stmt});
      then
        (cfn,tvar,tnr2);
    /* matrix */
    case (e as DAE.MATRIX(ty = t,integer = maxn,scalar = ell),tnr,context)
      equation
        (cfn,var,tnr_1) = generateMatrix(t, maxn, ell, tnr, context);
      then
        (cfn,var,tnr_1);
    /* range with no expression */
    case (DAE.RANGE(ty = t,exp = e1,expOption = NONE,range = e2),tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        type_string = expTypeStr(t, true);
        (tdecl,tvar,tnr3) = generateTempDecl(type_string, tnr2);
        stmt = Util.stringAppendList({"range_alloc_",type_string,"(",var1,", ",var2,", 1, &", tvar,");"});
        cfn1_1 = cAddVariables(cfn1, {tdecl});
        cfn2_1 = cAddStatements(cfn2, {stmt});
        cfn = cMergeFns({cfn1_1,cfn2_1});
      then
        (cfn,tvar,tnr3);
    /* range with expression */
    case (DAE.RANGE(ty = t,exp = e1,expOption = SOME(e2),range = e3),tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        (cfn3,var3,tnr3) = generateExpression(e3, tnr1, context);
        type_string = expTypeStr(t, true);
        (tdecl,tvar,tnr4) = generateTempDecl(type_string, tnr3);
        stmt = Util.stringAppendList({"range_alloc_",type_string,"(",var1,", ",var3,", ",var2,", &",tvar,");"});
        cfn1_1 = cAddVariables(cfn1, {tdecl});
        cfn2_1 = cAddStatements(cfn2, {stmt});
        cfn = cMergeFns({cfn1_1,cfn2_1});
      then
        (cfn,tvar,tnr4);
    /* tuple */
    case (DAE.TUPLE(PR = _),_,_)
      equation
        Debug.fprint("failtrace",
          "# Codegen.generateExpression: tuple not implemented\n");
      then
        fail();
    /* cast to int */
    case (DAE.CAST(ty = DAE.ET_INT(),exp = e),tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"((modelica_int)",var,")"});
      then
        (cfn,var_1,tnr_1);
    /* cast to float */
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e),tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"((modelica_real)",var,")"});
      then
        (cfn,var_1,tnr_1);
    /* cast to array */
    case (DAE.CAST(ty = DAE.ET_ARRAY(t,_),exp = e),tnr,context)
      local
        String to,from;
      equation
        array_type_str = expTypeStr(t, true);
        (tdecl,tvar,tnr) = generateTempDecl(array_type_str, tnr);
        (cfn,var,tnr) = generateExpression(e, tnr, context);
        ty = Exp.typeof(e);
        to = expShortTypeStr(t);
        from = expShortTypeStr(ty);
        stmt = Util.stringAppendList({"cast_",from,"_array_to_", to, "(&", var, ",&", tvar, ");"});
        cfn = cAddVariables(cfn, {tdecl});
        cfn = cAddStatements(cfn, {stmt});
      then
        (cfn,tvar,tnr);
    /* valueblock */
    case (DAE.VALUEBLOCK(ty,localDecls = ld,body = b,
      		result = res),tnr,context)
      local
        list<DAE.Element> ld;
    		list<DAE.Statement> b;
        DAE.Exp res;
      equation
        (cfn,tnr_1) = generateVars(ld, isVarQ, tnr, funContext);
        (cfn1,tnr2) = generateAlgorithmStatements(b, tnr_1, context);
        (cfn1_2,var,tnr3) = generateExpression(res, tnr2, context);
        cfn1_2 = cMergeFns({cfn,cfn1,cfn1_2});
        cfn1_2 = cMoveDeclsAndInitsToStatements(cfn1_2);
        //-----
        (cfn1_2,tnr4,var) = addValueblockRetVar(ty,cfn1_2,tnr3,var,context);
        //-----
        cfn1_2 = cAddBlockAroundStatements(cfn1_2);
      then (cfn1_2,var,tnr4);

    /* handle the easy case */
    /* range[x] */
    case (DAE.ASUB(exp = e as DAE.RANGE(ty = t), sub={idx}),tnr,context)
      local 
        String mem_decl, mem_var, get_mem_stmt, rest_mem_stmt, tShort;
        Integer tnr_mem;
        CFunction mem_fn;
        DAE.Exp idx;
      equation
        (mem_decl,mem_var,tnr_mem) = generateTempDecl("state", tnr);
        get_mem_stmt = Util.stringAppendList({mem_var," = get_memory_state();"});
        rest_mem_stmt = Util.stringAppendList({"restore_memory_state(",mem_var,");"});
        (cfn1,var1,tnr1) = generateExpression(e, tnr_mem, context);
        type_string = expTypeStr(t, false);
        tShort = expShortTypeStr(t);
        (tdecl,tvar2,tnr2) = generateTempDecl(type_string, tnr1);
        (cfn2,var2,tnr2) = generateExpression(idx, tnr2, context);
        stmt = Util.stringAppendList({tvar2, " = ", tShort, "_get(&", var1, ", ", var2, ");"});
        cfn1 = cMergeFn(cfn1, cfn2);
        cfn = cAddVariables(cfn1, {mem_decl,tdecl});
        cfn = cPrependStatements(cfn, {get_mem_stmt});
        cfn = cAddStatements(cfn, {stmt, rest_mem_stmt});
      then
        (cfn,tvar2,tnr2);
     
    /* handle the 4D indexing  */
    case (DAE.ASUB(DAE.ASUB(DAE.ASUB(DAE.ASUB(e, {DAE.ICONST(i)}), {DAE.ICONST(j)}), {DAE.ICONST(k)}), {DAE.ICONST(l)}),tnr,context)
      local 
        String mem_decl, mem_var, get_mem_stmt, rest_mem_stmt, tShort, jstr, kstr, lstr;
        Integer tnr_mem, k, l;
        CFunction mem_fn;
      equation
        (mem_decl,mem_var,tnr_mem) = generateTempDecl("state", tnr);
        get_mem_stmt = Util.stringAppendList({mem_var," = get_memory_state();"});
        rest_mem_stmt = Util.stringAppendList({"restore_memory_state(",mem_var,");"});
        (cfn1,var1,tnr1) = generateExpression(e, tnr_mem, context);
        t = Exp.typeof(e);
        type_string = expTypeStr(t, false);
        tShort = expShortTypeStr(t);
        (tdecl,tvar2,tnr2) = generateTempDecl(type_string, tnr1);
        istr = intString(i-1); // indexing is from 0 in C
        jstr = intString(j-1); // indexing is from 0 in C
        kstr = intString(k-1); // indexing is from 0 in C
        lstr = intString(l-1); // indexing is from 0 in C
        stmt = Util.stringAppendList({tvar2, " = ", tShort, "_get_4D(&", var1, ", ", istr, ", ", jstr, ", ", kstr, ", ", lstr, ");"});
        cfn = cAddVariables(cfn1, {mem_decl,tdecl});
        cfn = cPrependStatements(cfn, {get_mem_stmt});
        cfn = cAddStatements(cfn, {stmt, rest_mem_stmt});
      then
        (cfn,tvar2,tnr2);

    /* handle the 3D indexing  */
    case (DAE.ASUB(DAE.ASUB(DAE.ASUB(e, {DAE.ICONST(i)}), {DAE.ICONST(j)}), {DAE.ICONST(k)}),tnr,context)
      local 
        String mem_decl, mem_var, get_mem_stmt, rest_mem_stmt, tShort, jstr, kstr, lstr;
        Integer tnr_mem, k, l;
        CFunction mem_fn;
      equation
        (mem_decl,mem_var,tnr_mem) = generateTempDecl("state", tnr);
        get_mem_stmt = Util.stringAppendList({mem_var," = get_memory_state();"});
        rest_mem_stmt = Util.stringAppendList({"restore_memory_state(",mem_var,");"});
        (cfn1,var1,tnr1) = generateExpression(e, tnr_mem, context);
        t = Exp.typeof(e);
        type_string = expTypeStr(t, false);
        tShort = expShortTypeStr(t);
        (tdecl,tvar2,tnr2) = generateTempDecl(type_string, tnr1);
        istr = intString(i-1); // indexing is from 0 in C
        jstr = intString(j-1); // indexing is from 0 in C
        kstr = intString(k-1); // indexing is from 0 in C
        stmt = Util.stringAppendList({tvar2, " = ", tShort, "_get_3D(&", var1, ", ", istr, ", ", jstr, ", ", kstr, ");"});
        cfn = cAddVariables(cfn1, {mem_decl,tdecl});
        cfn = cPrependStatements(cfn, {get_mem_stmt});
        cfn = cAddStatements(cfn, {stmt, rest_mem_stmt});
      then
        (cfn,tvar2,tnr2);

    /* handle the 2D indexing  */
    case (DAE.ASUB(exp = DAE.ASUB(e, sub={DAE.ICONST(i)}), sub={DAE.ICONST(j)}),tnr,context)
      local 
        String mem_decl, mem_var, get_mem_stmt, rest_mem_stmt, tShort, jstr;
        Integer tnr_mem;
        CFunction mem_fn;
      equation
        (mem_decl,mem_var,tnr_mem) = generateTempDecl("state", tnr);
        get_mem_stmt = Util.stringAppendList({mem_var," = get_memory_state();"});
        rest_mem_stmt = Util.stringAppendList({"restore_memory_state(",mem_var,");"});
        (cfn1,var1,tnr1) = generateExpression(e, tnr_mem, context);
        t = Exp.typeof(e);
        type_string = expTypeStr(t, false);
        tShort = expShortTypeStr(t);
        (tdecl,tvar2,tnr2) = generateTempDecl(type_string, tnr1);
        istr = intString(i-1); // indexing is from 0 in C
        jstr = intString(j-1); // indexing is from 0 in C
        stmt = Util.stringAppendList({tvar2, " = ", tShort, "_get_2D(&", var1, ", ", istr, ", ", jstr, ");"});
        cfn = cAddVariables(cfn1, {mem_decl,tdecl});
        cfn = cPrependStatements(cfn, {get_mem_stmt});
        cfn = cAddStatements(cfn, {stmt, rest_mem_stmt});
      then
        (cfn,tvar2,tnr2);

    /* handle the indexing assuming expression e is an array */
    case (DAE.ASUB(exp = e, sub={DAE.ICONST(i)}),tnr,context)
      local 
        String mem_decl, mem_var, get_mem_stmt, rest_mem_stmt, tShort;
        Integer tnr_mem;
        CFunction mem_fn;
      equation
        (mem_decl,mem_var,tnr_mem) = generateTempDecl("state", tnr);
        get_mem_stmt = Util.stringAppendList({mem_var," = get_memory_state();"});
        rest_mem_stmt = Util.stringAppendList({"restore_memory_state(",mem_var,");"});
        (cfn1,var1,tnr1) = generateExpression(e, tnr_mem, context);
        t = Exp.typeof(e);
        type_string = expTypeStr(t, false);
        tShort = expShortTypeStr(t);
        (tdecl,tvar2,tnr2) = generateTempDecl(type_string, tnr1);
        istr = intString(i-1); // indexing is from 0 in C
        stmt = Util.stringAppendList({tvar2, " = ", tShort, "_get(&", var1, ", ", istr, ");"});
        cfn = cAddVariables(cfn1, {mem_decl,tdecl});
        cfn = cPrependStatements(cfn, {get_mem_stmt});
        cfn = cAddStatements(cfn, {stmt, rest_mem_stmt});
      then
        (cfn,tvar2,tnr2);

    // cref[x, y] - try to transform it into a cref 
    case (DAE.ASUB(exp = e as DAE.CREF(cref,t), sub=subs),tnr,
			context as CONTEXT(SIMULATION(_), _, _))
			local
				list<DAE.Exp> subs;
				list<DAE.Subscript> indices;
				DAE.ComponentRef cref, crefBuild;
				String arrayName;
			equation
				crefBuild = buildCrefFromAsub(cref, subs);
				(cfn, var, tnr2) = generateRhsCref(crefBuild, t, tnr, context);
				indices = Util.listMap(subs, Exp.makeIndexSubscript);
				(_, var2, tnr3) = generateScalarRhsCref(var, t, indices, tnr2, context);
			then
				(cfn, var2, tnr3);
			
    // cref[x, y] - try to transform it into a cref 
    case (DAE.ASUB(exp = e as DAE.CREF(cref,t), sub=subs),tnr,context)
      local 
        list<DAE.Exp> subs;
        DAE.ComponentRef cref, crefBuild;
      equation
        crefBuild = buildCrefFromAsub(cref, subs);
        (cfn,var,tnr2) = generateRhsCref(crefBuild, t, tnr, context);
      then
				(cfn,var,tnr2);

    case (DAE.ASUB(exp = _),tnr,context)
      equation
        Debug.fprint("failtrace", "# Codegen.generate_expression: asub not implemented: " +& Exp.printExp2Str(inExp) +& "\n");
      then
        fail();     

     //---------------------------------------------
     // MetaModelica extension
     //---------------------------------------------
    case (DAE.CONS(_,e1,e2),tnr,context)
      equation
        (cfn1,var1,tnr_1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr_1, context);
        (decl,tvar,tnr1_1) = generateTempDecl("modelica_metatype", tnr2);
        var1 = MetaUtil.createConstantCExp(e1,var1);
        stmt = Util.stringAppendList({tvar," = mmc_mk_cons(",var1,", ",var2,");"});
        cfn2 = cAddVariables(cfn2,{decl});
        cfn2 = cAddStatements(cfn2, {stmt});
        cfn1_2 = cMergeFns({cfn1,cfn2});
      then
        (cfn1_2,tvar,tnr1_1);

    case (DAE.LIST(_,elist),tnr,context)
      equation
        (cfn1,vars1,tnr1) = generateExpressions(elist, tnr, context);
        (decl,tvar,tnr1_1) = generateTempDecl("modelica_metatype", tnr1);
        s = MetaUtil.listToConsCell(vars1,elist);
        stmt = Util.stringAppendList({tvar," = ",s,";"});
        cfn1_1 = cAddVariables(cfn1,{decl});
        cfn1_2 = cAddStatements(cfn1_1, {stmt});
      then
        (cfn1_2,tvar,tnr1_1);

    case (DAE.META_TUPLE(elist),tnr,context)
      local
        list<String> strs;
        Integer len;
      equation
        (cfn1,vars1,tnr1) = generateExpressions(elist, tnr, context);
        (decl,tvar,tnr1_1) = generateTempDecl("modelica_metatype", tnr1);
        len = listLength(vars1);
        
        strs = Util.listThreadMap(elist, vars1, MetaUtil.createConstantCExp);
        strs = "0" :: strs;
        s = Util.stringDelimitList(strs, ",");
        s = MetaUtil.mmc_mk_box(len, s);
        stmt = Util.stringAppendList({tvar," = ",s,";"});
        cfn1_1 = cAddVariables(cfn1,{decl});
        cfn1_2 = cAddStatements(cfn1_1, {stmt});
      then
        (cfn1_2,tvar,tnr1_1);

    case (DAE.META_OPTION(NONE()),tnr,context)
      equation
        var1 = "mmc_mk_none()";
      then
        (cEmptyFunction,var1,tnr);

    case (DAE.META_OPTION(SOME(e1)),tnr,context)
      equation
        (cfn1,var1,tnr_1) = generateExpression(e1,tnr,context);
        var1 = MetaUtil.createConstantCExp(e1,var1);
        var1 = "mmc_mk_some(" +& var1 +& ")";        
      then
        (cfn1,var1,tnr_1);
     //---------------------------------------------

        /*	
  				Generate C-Code for: <metarecord>(<args>)
  	 		*/
    case (DAE.METARECORDCALL(path = fn, args = elist,fieldNames = fieldNames, index = index),tnr,context) //MetaModelica extension, Uniontypes, added by simbj
      local
        Absyn.Path fn;
        Integer index;
        list<DAE.ExpType> etypeList;
        list<String> fieldNames;
        String fnStr;
      equation
        (cfn1,vars1,tnr1) = generateExpressions(elist, tnr, context); //Generate the expressions for the arguments
        etypeList = Util.listMap(elist, Exp.typeof);
        (decl,tvar,tnr1_1) = generateTempDecl("modelica_metatype", tnr1);
        fnStr = Absyn.pathString(fn);
        s = MetaUtil.listToBoxes(vars1,etypeList,index,fnStr); /*
        																										Generates the mk_box(<size>,<index>,<data>::<data>);
        																								*/
        cfn1_1 = cAddVariables(cfn1,{decl}); //Add to variable list to be declared in function header
        ret_type = generateReturnType(fn); //Generate the name of the returntype (<functionname>_rettype)
        fn_name = generateFunctionName(fn);
        
        args_str = Util.stringDelimitList(vars1, ", ");
        stmt = Util.stringAppendList({tvar," = ", s , ";"});
        cfn = cAddStatements(cfn1_1, {stmt});
        
      then
        (cfn,tvar,tnr1_1); 

    case (e,_,_)
      equation
        Debug.fprintln("failtrace", "# generateExpression failed");
        s = Exp.printExpStr(e);
        Debug.fprintln("failtrace", s);
        Debug.fprintln("failtrace", "");
        msg = Util.stringAppendList({"code  generation of expression ",s," failed"});
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end matchcontinue;
end generateExpression;

protected function cAddBlockAroundStatements "function: cAddBlockAroundStatements
 author: KS
 Used by generateExpression - Valueblock
"
  input CFunction inCFunction;
  output CFunction outCFunction;
algorithm
  outCFunction:=
  matchcontinue (inCFunction)
    local
      list<Lib> rts,ad,vd,is,st,cl;
      Lib rt,fn;
    case CFUNCTION(returnType = rt,functionName = fn,returnTypeStruct = rts,argumentDeclarationLst = ad,variableDeclarationLst = vd,initStatementLst = is,statementLst = st,cleanupStatementLst = cl)
      equation
        st = listAppend({"{"},st);
        st = listAppend(st,{"}"});
      then
        CFUNCTION(rt,fn,rts,ad,vd,is,st,cl);
  end matchcontinue;

end cAddBlockAroundStatements;

protected function addValueblockRetVar "function: addValueblockRetVar
 author: KS
 Used by generateExpression - Valueblock. Adds a return variable (and return
 assignment) to the valueblock code.
"
  input DAE.ExpType inType;
  input CFunction inFunc;
  input Integer inTnr;
  input String inResVar;
  input Context context;
  output CFunction outFunc;
  output Integer outTnr;
  output String outVar;
algorithm
  (outFunc,outTnr,outVar) :=
  matchcontinue (inType,inFunc,inTnr,inResVar,context)
    case (DAE.ET_ARRAY(t,SOME(arrayDim) :: {}),localFunc,localTnr,localResVar,con)
      local
        String type_string,tdecl,tvar,localResVar,memStr,stmt,stmt2,tempStr;
        DAE.ExpType t;
        CFunction localFunc,cfn;
        Integer localTnr,arrayDim,tnr2;
        Boolean sim;
        Context con;
      equation  // ONLY 1 DIMENSIONAL ARRAYS SUPPORTED AS OF NOW
        // Create temp array var
        type_string = expTypeStr(t,true);
        (tdecl,tvar,tnr2) = generateTempDecl(type_string, localTnr);
        cfn = cAddVariables(localFunc, {tdecl});

        // Allocate temp array var
        tempStr = intString(arrayDim);
        stmt = Util.stringAppendList({"alloc_",type_string,"(&",tvar,",1,",tempStr,");"});
        cfn = cAddInits(cfn,{stmt});

        // Create the result var assignment
        sim = isSimulationContext(con);
        memStr = Util.if_(sim,"_mem","");
        stmt2 = Util.stringAppendList({"copy_",type_string,"_data",memStr,"(&",localResVar,", &",tvar,");"});
        cfn = cAddStatements(cfn, {stmt2});
      then (cfn,tnr2,tvar);
    case (DAE.ET_ARRAY(_,SOME(_) :: _),_,_,_,_)
      local
      equation
        Debug.fprintln("failtrace", "# Codegen.addValueblockRetVar failed, N-dim arrays not supported");
      then fail();
    case (localType,localFunc,localTnr,localResVar,_)
      local
        String type_string,tdecl,tvar,localResVar;
        DAE.ExpType localType;
        CFunction localFunc,cfn;
        Integer localTnr,tnr2;
        String stmt;
      equation
        type_string = expTypeStr(localType,false);
        (tdecl,tvar,tnr2) = generateTempDecl(type_string, localTnr);
        cfn = cAddVariables(localFunc, {tdecl});

        stmt = Util.stringAppendList({tvar," = ",localResVar,";"});
        cfn = cAddStatements(cfn,{stmt});
      then (cfn,tnr2,tvar);
  end matchcontinue;
end addValueblockRetVar;

protected function cMoveDeclsAndInitsToStatements "function: cMoveStatementsToInits

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
        st = listAppend(is,st);
        st = listAppend(vd,st);
      then
        CFUNCTION(rt,fn,rts,ad,{},{},st,cl);
  end matchcontinue;
end cMoveDeclsAndInitsToStatements;


protected function generateBuiltinFunction "function: generateBuiltinFunction
  author: PA

  Generates code for some specific builtin functions.
"
  input DAE.Exp inExp;
  input Integer inInteger;
  input Context inContext;
  output CFunction outCFunction;
  output String outString;
  output Integer outInteger;
algorithm
  (outCFunction,outString,outInteger):=
  matchcontinue (inExp,inInteger,inContext)
    local
      DAE.ExpType tp;
      Lib tp_str,tp_str2,var1,fn_name,tdecl,tvar,stmt,var2;
      CFunction cfn1,cfn2,cfn3,cfn4,cfn;
      Integer tnr1,tnr2,tnr,tnr3;
      DAE.Exp arg,s1,s2;
      Context context;
      String arr_tp_str;
      
      /* pre(var) must make sure that var is not cast to e.g modelica_integer, since pre expects double& */
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = {arg as DAE.CREF(cr,_)},tuple_ = false,builtin = true),tnr,context) /* max(v), v is vector */
      local String cref_str; DAE.ComponentRef cr; Boolean needCast; String castStr;
      equation
        tp = Exp.typeof(arg);
        tp_str = expTypeStr(tp, false);
        (cref_str,{}) = compRefCstr(cr);
        (tdecl,tvar,tnr1) = generateTempDecl(tp_str, tnr);
        cfn1 = cAddVariables(cEmptyFunction, {tdecl});
        needCast = stringEqual(tp_str,"modelica_integer");
        castStr = Util.if_(needCast,"(modelica_integer)","");
        stmt = Util.stringAppendList({tvar," = ",castStr,"pre(",cref_str,");"});
        cfn = cAddStatements(cfn1, {stmt});
      then
        (cfn,tvar,tnr1);
        
        /* max */
    case (DAE.CALL(path = Absyn.IDENT(name = "max"),expLst = {arg},tuple_ = false,builtin = true),tnr,context) /* max(v), v is vector */
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
    case (DAE.CALL(path = Absyn.IDENT(name = "max"),expLst = {s1,s2},tuple_ = false,builtin = true),tnr,context) /* max (a,b) a, b scalars */
      equation
        tp = Exp.typeof(s1);
        tp_str = expTypeStr(tp, false);
        (cfn1,var1,tnr1) = generateExpression(s1, tnr, context);
        (cfn1,var2,tnr2) = generateExpression(s2, tnr1, context);
        (tdecl,tvar,tnr3) = generateTempDecl(tp_str, tnr2);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({tvar," = max(((modelica_real)(",var1,")),((modelica_real)(",var2,")));"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr3);
        /* min */
    case (DAE.CALL(path = Absyn.IDENT(name = "min"),expLst = {arg},tuple_ = false,builtin = true),tnr,context) /* min(v), v is vector */
      equation
        tp = Exp.typeof(arg);
        tp_str = expTypeStr(tp, true);
        tp_str2 = expTypeStr(tp, false);
        (cfn1,var1,tnr1) = generateExpression(arg, tnr, context);
        fn_name = stringAppend("min_", tp_str);
        (tdecl,tvar,tnr2) = generateTempDecl(tp_str2, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({tvar," = ",fn_name,"(&",var1,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
    case (DAE.CALL(path = Absyn.IDENT(name = "min"),expLst = {s1,s2},tuple_ = false,builtin = true),tnr,context) /* min (a,b) a, b scalars */
      equation
        tp = Exp.typeof(s1);
        tp_str = expTypeStr(tp, false);
        (cfn1,var1,tnr1) = generateExpression(s1, tnr, context);
        (cfn1,var2,tnr2) = generateExpression(s2, tnr1, context);
        (tdecl,tvar,tnr3) = generateTempDecl(tp_str, tnr2);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({tvar," = min(((modelica_real)(",var1,")),((modelica_real)(",var2,")));"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr3);
    case (DAE.CALL(path = Absyn.IDENT(name = "abs"),expLst = {s1},tuple_ = false,builtin = true),tnr,context)
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
        
    case (DAE.CALL(path = Absyn.IDENT(name = "sum"),expLst = {s1},tuple_ = false,builtin = true),tnr,context)
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
        
    case (DAE.CALL(path = Absyn.IDENT(name = "promote"),expLst = {A,n},tuple_ = false,builtin = true),tnr,context)
      local
        DAE.Exp A,n;
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
        
    case (DAE.CALL(path = Absyn.IDENT(name = "transpose"),expLst = {A},tuple_ = false,builtin = true),tnr,context)
      local
        DAE.Exp A;
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
        
    case (DAE.CALL(path = Absyn.IDENT(name = "identity"),expLst = {A},tuple_ = false,builtin = true),tnr,context)
      local
        DAE.Exp A;
      equation
        tp = Exp.typeof(A);
        arr_tp_str = expTypeStr(tp, true);
        (cfn1,var1,tnr1) = generateExpression(A, tnr, context);
        (tdecl,tvar,tnr2) = generateTempDecl(arr_tp_str, tnr1);
        cfn2 = cAddVariables(cfn1, {tdecl});
        stmt = Util.stringAppendList({"identity_alloc_",arr_tp_str,"(",var1,",&",tvar,");"});
        cfn = cAddStatements(cfn2, {stmt});
      then
        (cfn,tvar,tnr2);
        
    case (DAE.CALL(path = Absyn.IDENT(name = "cross"),expLst = {A,B},tuple_ = false,builtin = true),tnr,context)
      local
        DAE.Exp A,B;
      equation
        tp = Exp.typeof(A);
        arr_tp_str = expTypeStr(tp, true);
        (cfn1,var1,tnr) = generateExpression(A, tnr, context);
        (cfn2,var2,tnr) = generateExpression(B, tnr, context);
        (tdecl,tvar,tnr) = generateTempDecl(arr_tp_str, tnr);
        cfn3 = cMergeFn(cfn1,cfn2);
        cfn4 = cAddVariables(cfn3, {tdecl});
        stmt = Util.stringAppendList({"cross_alloc_",arr_tp_str,"(&",var1,",&",var2,",&",tvar,");"});
        cfn = cAddStatements(cfn4, {stmt});
      then
        (cfn,tvar,tnr);
    case (DAE.CALL(path = Absyn.IDENT(name = "String"),expLst = {s,minlen,leftjust,signdig},tuple_ = false,builtin = true),tnr,context) /* max(v), v is vector */
      local String cref_str; DAE.Exp s,minlen,leftjust,signdig; Boolean needCast; String var3,var4,var5,var6,var7,edecl,evar;
        CFunction cfn3,cfn4; Boolean isenum; list<Lib> tedcllst;
      equation
        tp = Exp.typeof(s);
        tp_str = expTypeStr(tp, false);
        (tdecl,tvar,tnr1) = generateTempDecl("modelica_string", tnr);
        (cfn1,var1,tnr1) = generateExpression(s, tnr1, context);
        (cfn2,var2,tnr1) = generateExpression(minlen, tnr1, context);
        (cfn3,var3,tnr1) = generateExpression(leftjust, tnr1, context);
        (cfn4,var4,tnr1) = generateExpression(signdig, tnr1, context);
        (var5,isenum) = Exp.printEnumLiteralArray(tp);
        (edecl,evar,tnr1) = generateTempDeclWithAssignment("modelica_string", tnr1,"[]",var5);
        var6 = Util.stringAppendList({var1,",",evar});
        var7 = Util.if_(isenum, var6, var1);
        tedcllst = Util.if_(isenum, {tdecl,edecl}, {tdecl});
        cfn = cAddVariables(cEmptyFunction, tedcllst);
        stmt = Util.stringAppendList({tp_str,"_to_modelica_string(&",tvar,",",var7,",",var2,",",var3,",",var4,");"});
        cfn = cAddStatements(cfn, {stmt});
        cfn = cMergeFns({cfn1,cfn2,cfn3,cfn4,cfn});
      then
        (cfn,tvar,tnr1);
        
    case (DAE.CALL(path = Absyn.IDENT(name = "mmc_get_field"),expLst = {s1,DAE.ICONST(i)},tuple_ = false,builtin = true),tnr,context)
      local Integer i;
      equation
        (cfn1,var1,tnr1) = generateExpression(s1, tnr, context);
        (tdecl,tvar,tnr2) = generateTempDecl("modelica_metatype", tnr1);
        cfn = cAddVariables(cEmptyFunction, {tdecl});
        var2=intString(i);
        stmt = Util.stringAppendList({tvar," = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(",var1,"),",var2,"));"});
        cfn = cAddStatements(cfn, {stmt});
        cfn = cMergeFns({cfn1,cfn});
      then
        (cfn,tvar,tnr2);
        
        // Unboxing a record is done as a sequence of unboxing operations. This
        // code cannot be easily generated by C macros, so we generate the
        // statements manually. /sjoelund 2009-11-04
    case (DAE.CALL(path = Absyn.IDENT(name = "mmc_unbox_record"),expLst = {s1},tuple_ = false,builtin = true, ty = tp),tnr,context)
      local
        DAE.Type t;
        list<DAE.Var> v;
        list<DAE.Type> tys1,tys2;
        String baseStr,name,tmp;
        Integer i;
        list<Integer> intList;
        list<String> stringList, fetchStrs, tmpDecls, tmpRefs, tmpAssignments, conversionStmts, recordFields;
        list<DAE.Exp> tmpExps, recordFieldExps;
        list<Algorithm.Statement> stmtList;
        CFunction cfnConversion;
      equation
        (cfn1,var1,tnr) = generateExpression(s1, tnr, context);
        t = Types.expTypetoTypesType(tp);
        (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name), complexVarLst = v),_) = t;
        tys1 = Util.listMap(v, Types.getVarType);
        tys2 = Util.listMap(tys1, Types.boxIfUnboxedType);
        i = listLength(tys1);
        intList = Util.if_(i == 0, {}, Util.listIntRange2(2,i+1));
        stringList = Util.listMap(intList, intString);
        // Unbox every field
        (tmpDecls,tmpRefs,tnr) = generateTempDeclList("modelica_metatype",tnr,listLength(intList));
        baseStr = " = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(" +& var1 +& "),";
        fetchStrs = Util.listMap1r(stringList, stringAppend, baseStr);
        fetchStrs = Util.listMap1(fetchStrs, stringAppend, ")));");
        tmpAssignments = Util.listThreadMap(tmpRefs,fetchStrs,stringAppend);
        tmpExps = Util.listMap(tmpRefs, makeCrefExpFromString);
        (tmpExps,_,_) = Types.matchTypeTuple(tmpExps,tys2,tys1,{},Types.matchTypeRegular,true);
        // Generate assignments to regular record
        (tdecl,tvar,tnr) = generateTempDecl(generateSimpleType(t), tnr);
        tmp = tvar +& ".";
        stringList = Util.listMap(v, Types.getVarName);
        recordFields = Util.listMap1r(stringList,stringAppend,tmp);
        recordFieldExps = Util.listMap(recordFields, makeCrefExpFromString);
        stmtList = Util.listThreadMap(recordFieldExps,tmpExps,makeAssignmentNoCheck);
        (cfnConversion,tnr) = generateAlgorithmStatements(stmtList,tnr,funContext);
        // Generate the CFunction
        cfn = cEmptyFunction;
        cfn = cAddVariables(cfn, tmpDecls);
        cfn = cAddVariables(cfn, {tdecl});
        tmp = "/* Start unboxing record " +& name +& " */";
        cfn = cAddStatements(cfn, {tmp});
        cfn = cAddStatements(cfn, tmpAssignments);
        cfn = cMergeFns({cfn1,cfn,cfnConversion});
        tmp = "/* Finished unboxing record " +& name +& " */";
        cfn = cAddStatements(cfn, {tmp});
      then
        (cfn,tvar,tnr);
        
    case (DAE.CALL(path = Absyn.IDENT(name = "mmc_unbox_record"),expLst = {s1},tuple_ = false,builtin = true, ty = tp),tnr,context)
      equation
        tvar = "/* mmc_unbox_record failed: " +& Exp.typeString(tp) +& "*/";
      then
        (cEmptyFunction,tvar,tnr);

        //----
  end matchcontinue;
end generateBuiltinFunction;

protected function generateUnary "function: generateUnary

  Helper function to generate_expression.
"
  input DAE.Operator inOperator;
  input DAE.Exp inExp;
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
      DAE.Exp e;
      Context context;
      DAE.ExpType tp;
    case (DAE.UPLUS(ty = DAE.ET_REAL()),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.UPLUS(ty = DAE.ET_INT()),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.UMINUS(ty = DAE.ET_REAL()),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"(-",var,")"});        
      then
        (cfn,var_1,tnr_1);
    case (DAE.UMINUS(ty = DAE.ET_INT()),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"(-",var,")"});
      then
        (cfn,var_1,tnr_1);
    case (DAE.UMINUS(ty = DAE.ET_OTHER()),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"(-(",var,"))"});
      then
        (cfn,var_1,tnr_1);
    case (DAE.UMINUS(ty = tp),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
        var_1 = Util.stringAppendList({"(-(",var,"))"});
        //Debug.fprintln("codegen", "UMINUS("  +& Exp.typeString(tp) +& ")");
        //Debug.fprintln("codegen", "Variable" +& var);
      then
        (cfn,var_1,tnr_1);        
    case (DAE.UPLUS_ARR(ty = DAE.ET_REAL()),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.UPLUS_ARR(ty = DAE.ET_INT()),e,tnr,context)
      equation
        (cfn,var,tnr_1) = generateExpression(e, tnr, context);
      then
        (cfn,var,tnr_1);
    case (DAE.UMINUS_ARR(ty = _),_,_,_)
      equation
        Debug.fprint("failtrace", "# unary minus for arrays not implemented\n");
      then
        fail();
    case (DAE.UMINUS(ty = tp),_,_,_)
      equation
				true = RTOpts.debugFlag("failtrace");
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
  input DAE.Exp inExp1;
  input DAE.Operator inOperator2;
  input DAE.Exp inExp3;
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
      DAE.Exp e1,e2;
      Context context;

      /* str + str */
    case (e1,DAE.ADD(ty = DAE.ET_STRING()),e2,tnr,context)
      local String tdecl,tvar,stmt;
      equation
        (tdecl,tvar,tnr) = generateTempDecl("modelica_string", tnr);
        (cfn1,var1,tnr) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr) = generateExpression(e2, tnr, context);
        stmt = Util.stringAppendList({"cat_modelica_string(&",tvar,",&",var1,",&",var2,");"});
        cfn = cAddVariables(cEmptyFunction,{tdecl});
        cfn = cAddStatements(cfn,{stmt});
        cfn = cMergeFns({cfn1, cfn2,cfn});
      then
        (cfn,tvar,tnr);

      /* value + value */
    case (e1,DAE.ADD(ty = _),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," + ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.SUB(ty = _),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," - ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.MUL(ty = _),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," * ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.DIV(ty = _),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," / ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.POW(ty = _),e2,tnr,context) /* POW uses the math lib function with the same name. */
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"pow((modelica_real)",var1,", (modelica_real)",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (_,DAE.UMINUS(ty = _),_,_,_)
      equation
        Debug.fprint("failtrace",
          "# Unary minus in binary expression (internal error)");
      then
        fail();
    case (_,DAE.UPLUS(ty = _),_,_,_)
      equation
        Debug.fprint("failtrace",
          "# Unary plus in binary expression (internal error)");
      then
        fail();
    case (e1,DAE.ADD_ARR(ty = DAE.ET_ARRAY(DAE.ET_REAL(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.ADD_ARR(ty = DAE.ET_ARRAY(DAE.ET_INT(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.SUB_ARR(ty = DAE.ET_ARRAY(DAE.ET_REAL(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.SUB_ARR(ty = DAE.ET_ARRAY(DAE.ET_INT(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.MUL_SCALAR_ARRAY(ty = DAE.ET_ARRAY(DAE.ET_REAL(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.MUL_SCALAR_ARRAY(ty = DAE.ET_ARRAY(DAE.ET_INT(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.MUL_ARRAY_SCALAR(ty = DAE.ET_ARRAY(DAE.ET_REAL(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.MUL_ARRAY_SCALAR(ty = DAE.ET_ARRAY(DAE.ET_INT(), {NONE})),e2,tnr,context)
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
    case (e1,DAE.MUL_SCALAR_PRODUCT(ty = DAE.ET_REAL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"mul_real_scalar_product(&",var1,", &",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.MUL_SCALAR_PRODUCT(ty = DAE.ET_INT()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"mul_integer_scalar_product(&",var1,", &",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.MUL_MATRIX_PRODUCT(ty = DAE.ET_REAL()),e2,tnr,context)
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
    case (e1,DAE.MUL_MATRIX_PRODUCT(ty = DAE.ET_INT()),e2,tnr,context)
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
    case (e1,DAE.DIV_ARRAY_SCALAR(ty = DAE.ET_ARRAY(DAE.ET_REAL(),_)),e2,tnr,context)
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
		case (e1,DAE.DIV_ARRAY_SCALAR(ty = DAE.ET_ARRAY(DAE.ET_INT(),_)),e2,tnr,context)
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
    case (_,DAE.DIV_ARRAY_SCALAR(ty = _),_,_,_)
      equation
        Debug.fprint("failtrace", "# div_array_scalar FAILING BECAUSE IT SUX\n");
      then
        fail();
    case (_,DAE.POW_ARR(ty = _),_,_,_)
      equation
        Debug.fprint("failtrace", "# pow_array not implemented\n");
      then
        fail();
    case (_,DAE.DIV_ARRAY_SCALAR(ty = _),_,_,_)
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

protected function generateTempDecl 
"function: generateTempDecl
  Generates code for the declaration of a temporary variable."
  input String inStringType;
  input Integer inInteger;
  output String outStringDecl;
  output String outStringRef;
  output Integer outInteger3;
algorithm
  (outStringDecl,outStringRef,outInteger3):=
  matchcontinue (inStringType,inInteger)
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

protected function generateTempDeclWithAssignment 
"function: generateTempDecl
  Generates code for the declaration of a temporary variable."
  input String inStringType;
  input Integer inInteger;
  input String inStringType1;
  input String inStringAssignment;
  output String outStringDecl;
  output String outStringRef;
  output Integer outInteger3;
algorithm
  (outStringDecl,outStringRef,outInteger3):=
  matchcontinue (inStringType,inInteger,inStringType1,inStringAssignment)
    local
      Lib tnr_str,tmp_name,t_1,t,a,t_2;
      Integer tnr_1,tnr;
    case (t,tnr,t_2,a)
      equation
        tnr_str = intString(tnr);
        tnr_1 = tnr + 1;
        tmp_name = stringAppend("tmp", tnr_str);
        t_1 = Util.stringAppendList({t," ",tmp_name,t_2,"=",a,";"});
      then
        (t_1,tmp_name,tnr_1);
  end matchcontinue;
end generateTempDeclWithAssignment;

protected function generateTempDeclList 
"function: generateTempDeclList
  Generates code for the declaration of temporary variables."
  input String inString;
  input Integer inInteger;
  input Integer numberOfDecls;
  output list<String> outStringDecls;
  output list<String> outStringRefs;
  output Integer outInteger;
algorithm
  (outStringDecls,outStringRefs,outInteger):=
  matchcontinue (inString,inInteger,numberOfDecls)
    local
      list<String> decls,refs;
      String decl,ref,t;
      Integer tnr,i;
    case (_,tnr,0) then ({},{},tnr); 
    case (t,tnr,i)
      equation
        (decl,ref,tnr) = generateTempDecl(t,tnr);
        (decls,refs,tnr) = generateTempDeclList(t,tnr,i-1);
      then
        (decl::decls,ref::refs,tnr);
  end matchcontinue;
end generateTempDeclList;

protected function generateScalarLhsCref 
"function: generateScalarLhsCref
  Helper function to generateAlgorithmStatement."
  input DAE.ExpType inType;
  input DAE.ComponentRef inComponentRef;
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
      DAE.ExpType t;
      DAE.ComponentRef cref;
      Integer tnr,tnr_1,tnr1,ndims;
      Context context;
      list<DAE.Subscript> subs,idx;
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
    case (t,DAE.CREF_IDENT(ident = id,subscriptLst = idx),tnr,context)
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
    case (t,DAE.CREF_IDENT(ident = id,subscriptLst = idx),tnr,context)
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
    case (t,DAE.CREF_IDENT(ident = id,subscriptLst = idx),tnr,context)
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
  input DAE.ComponentRef inComponentRef;
  input DAE.ExpType inType;
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
      DAE.ComponentRef cref;
      DAE.ExpType t,crt;
      list<Option<Integer>> dims;
      Context context;
      list<DAE.Subscript> subs;
      /* For context simulation array variables must be boxed
	    into a real_array object since they are represented only
	    in a double array. */
		case (cref,DAE.ET_ARRAY(ty = t,arrayDimensions = dims),tnr,context as CONTEXT(SIMULATION(_),_,_))
      equation
        e_tp_str = expTypeStr(t, true);
        e_sh_tp_str = expShortTypeStr(t);
        (vdecl,vstr,tnr1) = generateTempDecl(e_tp_str, tnr);
        ndims = listLength(dims);
        ndims_str = intString(ndims);
        // Assumes that all dimensions are known, i.e. no NONE in dims.
        dims_strs = Util.listMap(Util.listMap1(dims,Util.applyOption, int_string),Util.stringOption);
        dims_str = Util.stringDelimitListNonEmptyElts(dims_strs, ", ");
        (cref_str, _) = compRefCstr(cref);
        stmt = Util.stringAppendList(
          {e_sh_tp_str,"_array_create(&",vstr,", ","&",cref_str,", ",
          ndims_str,", ",dims_str,");"});
        cfunc = cAddStatements(cEmptyFunction, {stmt});
        cfunc = cAddInits(cfunc, {vdecl});
      then
        (cfunc,vstr,tnr1);

        /* Cast integers to doubles in simulation context */
    case (cref,DAE.ET_INT(),tnr,context)
      equation
        (cref_str,{}) = compRefCstr(cref);
        cref_str = stringAppend("(modelica_integer)",cref_str);
      then
        (cEmptyFunction,cref_str,tnr);

        /* function pointer variable reference - stefan */
    case (cref,DAE.ET_FUNCTION_REFERENCE_VAR(),tnr,context)
        local String fn_name; Absyn.Path path;
      equation
        path = Exp.crefToPath(cref);
        fn_name = generateFunctionName(path);
        fn_name = Util.stringReplaceChar(fn_name,".","_");
      then
        (cEmptyFunction,fn_name,tnr);
    
       /* function pointer direct reference - sjoelund */
    case (cref,DAE.ET_FUNCTION_REFERENCE_FUNC(),tnr,context)
        local String fn_name; Absyn.Path path;
      equation
        path = Exp.crefToPath(cref);
        fn_name = generateFunctionName(path);
        fn_name = Util.stringReplaceChar(fn_name,".","_");
        cref_str = stringAppend("(modelica_fnptr)boxptr_",fn_name);
      then
        (cEmptyFunction,cref_str,tnr);

    case (cref,DAE.ET_ENUMERATION(_,_,_,_),tnr,context)
      local Integer idx;
      equation
        idx = Exp.getEnumIndexfromCref(cref);
        cref_str = intString(idx);
      then (cEmptyFunction,cref_str,tnr);        
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
  input list<DAE.Subscript> inExpSubscriptLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExpSubscriptLst)
    local
      Boolean b;
      list<DAE.Subscript> r;
    case {} then true;
    case (DAE.SLICE(exp = _) :: _) then false;
    case (DAE.WHOLEDIM() :: _) then false;
    case (DAE.INDEX(exp = _) :: r)
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
  input DAE.ExpType inType;
  input list<DAE.Subscript> inExpSubscriptLst;
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
      DAE.ExpType crt;
      list<DAE.Subscript> subs;
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
  input DAE.ExpType inType;
  input list<DAE.Subscript> inExpSubscriptLst;
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
      DAE.ExpType crt;
      list<DAE.Subscript> subs;
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
  input list<DAE.Subscript> inExpSubscriptLst;
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
      list<DAE.Subscript> subs;
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
  input list<DAE.Subscript> inExpSubscriptLst;
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
      DAE.Subscript f;
      list<DAE.Subscript> r;
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
  input list<DAE.Subscript> inExpSubscriptLst;
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
      DAE.Subscript f;
      list<DAE.Subscript> r;
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
  input DAE.Subscript inSubscript;
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
      DAE.Exp e;
      Context context;
      // Scalar index
    case (DAE.INDEX(exp = e),tnr,context)
      equation
        (cfn,var1,tnr1) = generateExpression(e, tnr, context);
        idx = Util.stringAppendList({"make_index_array(1, ",var1,")"});
        idxsize = "(1)";
      then
        (cfn,idx,idxsize,"'S'",tnr1);
        // Whole dimension, ':'
    case (DAE.WHOLEDIM(),tnr,context)
      equation
        idx = "(0)";
        idxsize = "(1)";
      then
        (cEmptyFunction,idx,idxsize,"'W'",tnr);

        // Slice, e.g A[{1,3,5}]
    case (DAE.SLICE(exp = e),tnr,context)
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
  input DAE.Subscript inSubscript;
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
      DAE.Exp e;
      Context context;
    case (DAE.INDEX(exp = e),tnr,context)
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
  input DAE.ComponentRef inComponentRef;
  output String outString;
  output list<DAE.Subscript> outExpSubscriptLst;
algorithm
  (outString,outExpSubscriptLst):=
  matchcontinue (inComponentRef)
    local
      Lib id,cref_str,cref_str_1;
      list<DAE.Subscript> subs,cref_subs,subs_1;
      DAE.ComponentRef cref;
    case cref 
      local Integer idx; 
      equation
        idx = Exp.getEnumIndexfromCref(cref);
        // no dots
        cref_str_1 = intString(idx);
        then
          (cref_str_1,{});      
    case DAE.CREF_IDENT(ident = id,subscriptLst = subs) then (id,subs);
    case DAE.CREF_QUAL(ident = id,subscriptLst = subs,componentRef = cref)
      equation
        (cref_str,cref_subs) = compRefCstr(cref);
        cref_str_1 = Util.stringAppendList({id,".",cref_str});
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
  input DAE.Exp inExp1;
  input DAE.Operator inOperator2;
  input DAE.Exp inExp3;
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
      DAE.Exp e1,e2;
      Context context;
    case (e1,DAE.AND(),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," && ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.OR(),e2,tnr,context)
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
  input DAE.Operator inOperator;
  input DAE.Exp inExp;
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
      DAE.Exp e;
      Context context;
    case (DAE.NOT(),e,tnr,context)
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

protected function relOpStr
  input DAE.Operator op;
  output String opStr;
algorithm
	isReal := matchcontinue (op)
	  case (DAE.LESS(ty = _)) then "RELATIONLESS";
	  case (DAE.LESSEQ(ty = _)) then "RELATIONLESSEQ";
	  case (DAE.GREATER(ty = _)) then "RELATIONGREATER";
	  case (DAE.GREATEREQ(ty = _)) then "RELATIONGREATEREQ";
	  case (_) then fail();
  end matchcontinue;
end relOpStr;

protected function isRealTypedRelation
  input DAE.Operator op;
  output Boolean isReal;
algorithm
	isReal := matchcontinue (op)
	  case (DAE.LESS(ty = DAE.ET_REAL())) then true;
	  case (DAE.LESSEQ(ty = DAE.ET_REAL())) then true;
	  case (DAE.GREATER(ty = DAE.ET_REAL())) then true;
	  case (DAE.GREATEREQ(ty = DAE.ET_REAL())) then true;
	  case (_) then false;
  end matchcontinue;
end isRealTypedRelation;

protected function generateRelation "function: generateRelation

  Generates code for function expressions.
  returns:
  CFunction | the generated code
  string    | expression result
  int       | next temporary number
"
  input DAE.Exp inExp1;
  input DAE.Operator inOperator2;
  input DAE.Exp inExp3;
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
      DAE.Exp e1,e2;
      Context context;
    case (e1,DAE.LESS(ty = DAE.ET_BOOL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(!",var1," && ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.LESS(ty = DAE.ET_STRING()),e2,tnr,context)
      equation
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,DAE.LESS(ty = DAE.ET_INT()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," < ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.LESS(ty = DAE.ET_REAL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," < ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.LESS(ty = DAE.ET_ENUMERATION(_,_,_,_)),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," < ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);        
    case (e1,DAE.GREATER(ty = DAE.ET_BOOL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," && !",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.GREATER(ty = DAE.ET_STRING()),e2,tnr,context)
      equation
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,DAE.GREATER(ty = DAE.ET_INT()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," > ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.GREATER(ty = DAE.ET_REAL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," > ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.GREATER(ty = DAE.ET_ENUMERATION(_,_,_,_)),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," > ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);        
    case (e1,DAE.LESSEQ(ty = DAE.ET_BOOL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(!",var1," || ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.LESSEQ(ty = DAE.ET_STRING()),e2,tnr,context)
      equation
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,DAE.LESSEQ(ty = DAE.ET_INT()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," <= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.LESSEQ(ty = DAE.ET_REAL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," <= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.LESSEQ(ty = DAE.ET_ENUMERATION(_,_,_,_)),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," <= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);        
    case (e1,DAE.GREATEREQ(ty = DAE.ET_BOOL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," || !",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.GREATEREQ(ty = DAE.ET_STRING()),e2,tnr,context)
      equation
        Print.printErrorBuf("# string comparison not supported\n");
      then
        fail();
    case (e1,DAE.GREATEREQ(ty = DAE.ET_INT()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," >= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.GREATEREQ(ty = DAE.ET_REAL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," >= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.GREATEREQ(ty = DAE.ET_ENUMERATION(_,_,_,_)),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," >= ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);        
    case (e1,DAE.EQUAL(ty = DAE.ET_BOOL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"((!",var1," && !",var2,") || (",var1," && ",var2,"))"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.EQUAL(ty = DAE.ET_STRING()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(!strcmp(",var1,",",var2,"))"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.EQUAL(ty = DAE.ET_INT()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," == ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.EQUAL(ty = DAE.ET_REAL()),e2,tnr,context as CONTEXT(codeContext = FUNCTION))
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," == ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr);
    case (e1,DAE.EQUAL(ty = DAE.ET_REAL()),e2,tnr,context)
      equation
        Print.printErrorBuf("# Reals can't be compared with ==\n");
      then
        fail();
    case (e1,DAE.EQUAL(ty = DAE.ET_BOXED(_)),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"mmc_boxes_equal(",var1,",",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.EQUAL(ty = DAE.ET_ENUMERATION(_,_,_,_)),e2,tnr,context)
//    case (e1,DAE.EQUAL(ty = Exp.ENUM()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," == ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);         
    case (e1,DAE.NEQUAL(ty = DAE.ET_BOOL()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"((!",var1," && ",var2,") || (",var1," && !",var2,"))"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.NEQUAL(ty = DAE.ET_STRING()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(strcmp(",var1,",",var2,"))"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.NEQUAL(ty = DAE.ET_INT()),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," != ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.NEQUAL(ty = DAE.ET_REAL()),e2,tnr,context as CONTEXT(codeContext = FUNCTION))
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," != ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr);
    case (e1,DAE.NEQUAL(ty = DAE.ET_REAL()),e2,tnr,context)
      equation
        Debug.fprint("failtrace", "# Reals can't be compared with <>\n");
      then
        fail();
    case (e1,DAE.NEQUAL(ty = DAE.ET_BOXED(_)),e2,tnr,context)
      equation
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"!mmc_boxes_equal(",var1,",",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr2);
    case (e1,DAE.NEQUAL(ty = DAE.ET_ENUMERATION(_,_,_,_)),e2,tnr,context)
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        (cfn1,var1,tnr1) = generateExpression(e1, tnr, context);
        (cfn2,var2,tnr2) = generateExpression(e2, tnr1, context);
        var = Util.stringAppendList({"(",var1," != ",var2,")"});
        cfn = cMergeFn(cfn1, cfn2);
      then
        (cfn,var,tnr);        
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "# generate_relation failed\n");
      then
        fail();
  end matchcontinue;
end generateRelation;

protected function generateMatrix 
"function: generateMatrix
  Generates code for matrix expressions."
  input DAE.ExpType inType1;
  input Integer inInteger2;
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst3;
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
      DAE.ExpType typ;
      list<list<tuple<DAE.Exp, Boolean>>> exps;
      Context context;
      /* Special case for empty array { {} } */
    case (typ,maxn,{{}},tnr,context) equation
        array_type_str = expTypeStr(typ, true);
        (tdecl,tvar,tnr1) = generateTempDecl(array_type_str, tnr);
        /* Create dimensional array Real[0,1]; */
        stmt = Util.stringAppendList({"alloc_",array_type_str,"(&",tvar,",2,0,1);"});
        cfn_1 = cAddVariables(cEmptyFunction, {tdecl});
        cfn_2 = cAddStatements(cfn_1, {stmt});
    then (cfn_2,tvar,tnr1);
      /* Special case from emtpy array: {} */
   case (typ,maxn,{},tnr,context) equation
        array_type_str = expTypeStr(typ, true);
        (tdecl,tvar,tnr1) = generateTempDecl(array_type_str, tnr);
        stmt = Util.stringAppendList({"alloc_",array_type_str,"(&",tvar,",2,0,1);"});
        cfn_1 = cAddVariables(cEmptyFunction, {tdecl});
        cfn_2 = cAddStatements(cfn_1, {stmt});
   then (cfn_2,tvar,tnr1);

    case (typ,maxn,exps,tnr,context)
      equation
        (cfn1,vars1,tnr1) = generateMatrixExpressions(typ, exps, maxn, tnr, context);
        (cfn2,vars2,tnr2) = concatenateMatrixRows(typ, vars1, tnr1, context);
        array_type_str = expTypeStr(typ, true);
        args_str = Util.stringDelimitList(vars2, ", &");
        n = listLength(vars2);
        n_str = intString(n);
        (tdecl,tvar,tnr3) = generateTempDecl(array_type_str, tnr2);
        stmt = Util.stringAppendList({"cat_alloc_",array_type_str,"(1, &",tvar,", ",n_str,", &",args_str,");"});
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
  input DAE.ExpType inType;
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
      DAE.ExpType typ;
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
  input DAE.ExpType inType;
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
      DAE.ExpType typ;
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
  input DAE.ExpType inType1;
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpExpBooleanLstLst2;
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
      DAE.ExpType typ;
      list<tuple<DAE.Exp, Boolean>> fr;
      list<list<tuple<DAE.Exp, Boolean>>> rr;
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
  input DAE.ExpType inType1;
  input list<tuple<DAE.Exp, Boolean>> inTplExpExpBooleanLst2;
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
      DAE.ExpType t;
      tuple<DAE.Exp, Boolean> f;
      list<tuple<DAE.Exp, Boolean>> r;
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
  input DAE.ExpType inType1;
  input tuple<DAE.Exp, Boolean> inTplExpExpBoolean2;
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
      DAE.ExpType t;
      DAE.Exp e;
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
  Lib out_decl,in_args,fn_call;
  CFunction cfn1,cfn1_1,cfn31,cfn32,cfn3,cfn3_1,cfn4,cfn4_1,cfn5,cfn5_1;
  Integer tnr21,tnr2;
  list<Lib> in_names;
algorithm
  cfn1 := cMakeFunction("int", "in" +& fnname, {},
    {"type_description * inArgs","type_description * outVar"});
  Debug.fprintln("cgtr", "generate_read_call_write");
  out_decl := Util.stringAppendList({retstr," out;"});
  cfn1_1 := cAddInits(cfn1, {out_decl});
  (cfn3,tnr21) := generateVarDecls(invars, isRcwInput, 1, funContext);
  in_names := invarNames(invars);
  in_args := Util.stringDelimitList(in_names, ", ");
  cfn4 := generateRead(invars);
  fn_call := Util.stringAppendList({"out = ",fnname,"(",in_args,");"});
  cfn4_1 := cAddStatements(cfn4, {fn_call});
  cfn5 := generateWriteOutvars(outvars,1);
  cfn5_1 := cAddStatements(cfn5, {"return 0;"});
  cfn := cMergeFns({cfn1_1,cfn3,cfn4_1,cfn5_1});
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
  input DAE.Type inType7;
  output CFunction outCFunction;
algorithm
  outCFunction:=
  matchcontinue (inString1,inDAEElementLst2,inString3,inDAEElementLst4,inExternalDecl5,inDAEElementLst6,inType7)
    local
      Integer tnr,tnr_invars1,tnr_invars,tnr_bivars1,tnr_bivars,tnr_extcall,tnr_ret;
      list<Lib> arg_strs;
      CFunction cfn1,cfn31,cfn32,cfn33,cfn34,cfn3,extcall,cfn_1,cfn,allocstmts_1,allocstmts;
      Lib out_decl,fnname,retstr,extfnname,lang;
      list<DAE.Element> vars_1,vars,outvars,invars,bivars;
      DAE.ExternalDecl extdecl;
      list<DAE.ExtArg> extargs;
      DAE.ExtArg extretarg;
      Option<Absyn.Annotation> ann;
      list<tuple<Lib, tuple<DAE.TType, Option<Absyn.Path>>>> args;
      tuple<DAE.TType, Option<Absyn.Path>> restype;
    case (fnname,outvars,retstr,invars,(extdecl as DAE.EXTERNALDECL(ident = extfnname,external_ = extargs,parameters = extretarg,returnType = lang,language = ann)),bivars,(DAE.T_FUNCTION(funcArg = args,funcResultType = restype),_)) /* function name output variables return type input variables external declaration bidirectional vars function type */
      equation
        tnr = 1;
        arg_strs = Util.listMap(args, generateFunctionArg);
        cfn1 = cMakeFunction(retstr, fnname, {}, arg_strs);
        out_decl = Util.stringAppendList({retstr," out;"});
        (allocstmts_1,tnr_ret) = generateAllocOutvarsExt(outvars, "out", 1,tnr, extdecl);
        allocstmts = cAddVariables(allocstmts_1, {out_decl});
        (cfn31,tnr_invars1) = generateVarDecls(invars, isRcwInput, tnr_ret, funContext);
        (cfn32,tnr_invars) = generateVarInits(invars, isRcwInput, 1,tnr_invars1, "", funContext);
        (cfn33,tnr_bivars1) = generateVarDecls(bivars, isRcwBidir, tnr_invars, funContext);
        (cfn34,tnr_bivars) = generateVarInits(bivars, isRcwBidir, 1,tnr_bivars1, "", funContext);
        cfn3 = cMergeFns({allocstmts,cfn31,cfn32,cfn33,cfn34});
        vars_1 = listAppend(invars, outvars);
        vars = listAppend(vars_1, bivars);
        (extcall,tnr_extcall) = generateExtCall(vars, extdecl, tnr_bivars);
        cfn_1 = cMergeFns({cfn1,allocstmts,extcall});
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
      Lib out_decl,mem_decl,mem_var,get_mem_stmt,rest_mem_stmt,fnname,retstr;
      CFunction cfn1,cfn1_1,allocstmts_1,allocstmts,biallocstmts,cfnoutinit,cfnoutbialloc,mem_fn_1,mem_fn_2,mem_fn,cfn31,cfn32,cfn33,cfn34,cfn3,cfn3_1,readinvars,readdone,extcall,cfn4_1,cfn5,cfn5_1,cfn_1,cfn;
      list<DAE.Element> vars_1,vars,outvars,invars,bivars;
      DAE.ExternalDecl extdecl;
    case (fnname,outvars,retstr,invars,extdecl,bivars) /* function name output variables return type input variables external declaration bidirectional vars */
      equation
        Debug.fprintln("cgtr", "generate_read_call_write_external");
        tnr = 1;
        cfn1 = cMakeFunction("int", "in" +& fnname, {},
          {"type_description * inArgs","type_description * outVar"});
        out_decl = Util.stringAppendList({retstr," out;"});
        cfn1_1 = cAddInits(cfn1,{});
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
        cfn3_1 = cAddInits(cfn3, {});
        readinvars = generateRead(invars);
        readdone = cAddInits(readinvars, {});
        vars_1 = listAppend(invars, outvars);
        vars = listAppend(vars_1, bivars);
        (extcall,tnr_extcall) = generateExtCall(vars, extdecl, tnr_bivars);
        cfn4_1 = cAddStatements(extcall,{});
        cfn5 = generateWriteOutvars(outvars,1);
        cfn_1 = cMergeFns({cfn1_1,cfn3_1,readdone,mem_fn,cfn4_1,cfn5});
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
      Lib extdeclstr,n,lang,lang2;
      CFunction argdecls,fcall,argcopies,extcall;
      list<DAE.ExtArg> arglist_1,outbiarglist,arglist;
      Integer tnr_1,tnr_2,tnr;
      list<DAE.Element> vars;
      DAE.ExternalDecl extdecl;
      DAE.ExtArg retarg;
      Option<Absyn.Annotation> ann;
    case (vars,(extdecl as DAE.EXTERNALDECL(ident = n,external_ = arglist,parameters = retarg,returnType = lang,language = ann)),tnr)
      equation
        Debug.fcall("cgtrdumpdaeextcall", DAEUtil.dump2, DAE.DAE(vars));
        extdeclstr = DAEUtil.dumpExtDeclStr(extdecl);
        Debug.fprintln("cgtrdumpdaeextcall", extdeclstr);
        (argdecls,arglist_1,tnr_1) = generateExtcallVardecls(vars, arglist, retarg, lang, 1,tnr);
        lang2 = getJavaCallMappingFromAnn(lang, ann);
        fcall = generateExtCallFcall(n, arglist_1, retarg, lang2);
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
    case (vars,args,retarg,"Java",i,tnr) "Same as C"
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
      DAE.ComponentRef cref,cref_1;
      DAE.VarKind vk;
      DAE.VarDirection vd;
      DAE.Type ty;
      Option<DAE.Exp> value;
      list<DAE.Subscript> dims,dims_1;
      DAE.Element extvar,var;
      CFunction fn,restfn,resfn;
      list<DAE.Element> rest;
      Boolean b_isOutput;
      Integer i1;
      DAE.VarProtection prot;
    case ({},i,tnr) then (cEmptyFunction,tnr);
    case ((var :: rest),i,tnr)
      equation
        DAE.VAR(componentRef = cref,kind = vk,direction = vd,protection=prot,ty = ty,binding = value,dims = dims) = var;
        true = isArray(var);
        b_isOutput = isOutput(var);
        i1 = Util.if_(b_isOutput,i+1,i);
        cref_1 = varNameExternalCref(cref);
        dims_1 = listReverse(dims);
        extvar = DAE.VAR(cref_1,vk,vd,prot,ty,value,dims_1,DAE.NON_FLOW(),DAE.NON_STREAM(),{},NONE,NONE,Absyn.UNSPECIFIED());
        (fn,tnr_1) = generateVarDecl(extvar, tnr, funContext);
        (restfn,tnr_3) = generateExtcallCopydeclsF77(rest, i1,tnr_1);
        resfn = cMergeFn(fn, restfn);
      then
        (resfn,tnr_3);
    case ((var :: rest),i,tnr)
      equation
        Debug.fprint("cgtr", "#--Ignoring: ");
        Debug.fcall("cgtr", DAEUtil.dump2, DAE.DAE({var}));
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
      DAE.ComponentRef cref,cr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      Lib tystr,name,orgname;
      CFunction res;
      DAE.ExtArg arg;
      DAE.Attributes attr;
      DAE.Exp exp;

      /* INPUT NON-ARRAY */
    case (arg,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = DAE.ATTR(direction = Absyn.INPUT()),type_ = ty) = arg;
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
        DAE.EXTARG(componentRef = cref,attributes = DAE.ATTR(direction = Absyn.INPUT()),type_ = ty) = arg;
        true = Types.isArray(ty);
      then
        cEmptyFunction;

        /* OUTPUT NON-ARRAY */
    case (arg, i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = DAE.ATTR(direction = Absyn.OUTPUT()),type_ = ty) = arg;
        false = Types.isArray(ty);
        tystr = generateTypeExternal(ty);
        name = varNameExternal(cref);
        res = generateVardeclFunc(tystr, name, NONE);
      then
        res;

        /* OUTPUT ARRAY */
    case (arg, i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = DAE.ATTR(direction = Absyn.OUTPUT()),type_ = ty) = arg;
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
  matchcontinue (inDAEExtArgLst,inExtArg,i,inInteger)
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
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> elty,ty;
      Lib eltystr,str;
    case ((ty as (DAE.T_ARRAY(arrayDim = _),_)))
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
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inType)
    local
      tuple<DAE.TType, Option<Absyn.Path>> elty,ty;
      Lib eltystr,str;
    case ((ty as (DAE.T_ARRAY(arrayDim = _),_)))
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
  input DAE.Attributes attr;
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
      DAE.ComponentRef cref,cr,tmpcref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      CFunction res,decl;
      DAE.ExtArg arg,extarg,newarg;
      Integer tnr,tnr_1;
      Lib tystr,name,orgname,converter,initstr,tmpname_1,tnrstr,tmpstr,callstr,declstr;
      DAE.Exp exp,dim;
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
        tystr = generateSimpleType(ty);
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
        tystr = generateSimpleType(ty);
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
        tystr = generateSimpleType(ty);
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
        tmpname_1 = varNameArray(cr, attr, i);
        tnrstr = intString(tnr);
        tnr_1 = tnr + 1;
        tmpstr = Util.stringAppendList({tmpname_1,"_size_",tnrstr});
        tmpcref = DAE.CREF_IDENT(tmpstr,DAE.ET_OTHER(),{});
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
      Lib fcall2,str,chk_str,className,cls_str,fnname,lang,crstr,argsstr,fnstr,sig,jniCallFunc;
      list<String> argslist,preCall,postCall,varNames,assignRes,varNamesRes,assignResSimple,varNamesResSimple;
      CFunction res;
      list<DAE.ExtArg> args;
      DAE.ComponentRef cr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      Boolean simpleJavaCallMapping;
      
      /* Java call without return value */
    case (fnname,args,inExtArg as DAE.NOEXTARG(),lang)
      equation
        simpleJavaCallMapping = getJavaCallMapping(lang);
        (className,fnname) = generateJavaClassAndMethod(fnname);
        chk_str = "CHECK_FOR_JAVA_EXCEPTION(__env);";
        
        argslist = generateExtCallFcallArgsJava(args,1);
        argslist = Util.listMap1(argslist, stringAppend, "_java");
        argslist = Util.listMap1r(argslist, stringAppend, ", ");
        argsstr = Util.stringAppendList(argslist);
        
        jniCallFunc = "CallStaticVoidMethod";
        str = Util.stringAppendList({"(*__env)->",jniCallFunc,"(__env, __cls, __mid",argsstr,");"});
        
        cls_str = "__cls = (*__env)->FindClass(__env, \""+&className+&"\");";
        sig = generateJavaSignature(args,inExtArg,simpleJavaCallMapping);
        fnstr = "__mid = (*__env)->GetStaticMethodID(__env, __cls, \""+&fnname+&"\",\""+&sig+&"\");";
        
        (preCall,postCall,varNames) = generateExtCallFcallJava(args,simpleJavaCallMapping);        
        res = cAddStatements(cEmptyFunction, {"__env = getJavaEnv();"});
        res = cAddStatements(res, preCall);
        res = cAddStatements(res, {cls_str, chk_str, fnstr, chk_str});
        res = cAddStatements(res, {str, chk_str});
        res = cAddStatements(res, postCall);
        
        res = cAddVariables(res,{"JNIEnv* __env = NULL;", "jclass __cls = NULL;", "jmethodID __mid = NULL;"});
        res = cAddVariables(res,varNames);
      then
        res;
        
        /* Java call with return value assignment */
    case (fnname,args,(inExtArg as DAE.EXTARG(componentRef = cr, type_ = ty)),lang)
      equation
        simpleJavaCallMapping = getJavaCallMapping(lang);
        (className,fnname) = generateJavaClassAndMethod(fnname);
        chk_str = "CHECK_FOR_JAVA_EXCEPTION(__env);";
        false = Types.isArray(ty);
        
        argslist = generateExtCallFcallArgsJava(args,1);
        argslist = Util.listMap1(argslist, stringAppend, "_java");
        argslist = Util.listMap1r(argslist, stringAppend, ", ");
        argsstr = Util.stringAppendList(argslist);
        
        crstr = generateExtCallFcallArgJava(inExtArg,1);
        (_,assignRes,varNamesRes) = javaExtNewAndClean(crstr,"/* Can't assign arrays... */",ty,true);
        (_,assignResSimple,varNamesResSimple) = javaExtSimpleNewAndClean(crstr,ty,true);
        assignRes = Util.if_(simpleJavaCallMapping, assignResSimple, assignRes);
        varNamesRes = Util.if_(simpleJavaCallMapping, varNamesResSimple, varNamesRes);
        
        crstr = crstr +& "_java";
        jniCallFunc = getJniCallFunc(ty, simpleJavaCallMapping);
        str = Util.stringAppendList({crstr," = (*__env)->",jniCallFunc,"(__env, __cls, __mid",argsstr,");"}); 
        
        cls_str = "__cls = (*__env)->FindClass(__env, \""+&className+&"\");";
        sig = generateJavaSignature(args,inExtArg,simpleJavaCallMapping);
        fnstr = "__mid = (*__env)->GetStaticMethodID(__env, __cls, \""+&fnname+&"\",\""+&sig+&"\");";
        
        (preCall,postCall,varNames) = generateExtCallFcallJava(args,simpleJavaCallMapping);
        res = cAddStatements(cEmptyFunction, {"__env = getJavaEnv();"});
        res = cAddStatements(res, preCall);
        res = cAddStatements(res, {cls_str, chk_str, fnstr, chk_str});
        res = cAddStatements(res, {str, chk_str});
        res = cAddStatements(res, assignRes);
        res = cAddStatements(res, postCall);
        
        res = cAddVariables(res,{"JNIEnv* __env = NULL;", "jclass __cls = NULL;", "jmethodID __mid = NULL;"});
        res = cAddVariables(res,varNames);
        res = cAddVariables(res,varNamesRes);
      then
        res;

      /* language call without return value */
    case (fnname,args,DAE.NOEXTARG(),lang)
      equation
        failure(_ = getJavaCallMapping(lang));
        fcall2 = generateExtCallFcall2(fnname, args, lang);
        str = stringAppend(fcall2, ";");
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;

        /* return value assignment, shouldn\'t happen for arrays */
    case (fnname,args,DAE.EXTARG(componentRef = cr,type_ = ty),lang)
      equation
        failure(_ = getJavaCallMapping(lang));
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
    case (_,_,inString)
      equation
        Debug.fprintl("failtrace", {"#-- generate_ext_call_fcall2 failed: ",inString,"\n"});
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
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      Lib res,name,str;
      DAE.ExtArg arg;
      DAE.Exp exp;

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
        res = generateArrayDataCall(name, ty);
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
   local DAE.Attributes attr;
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
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      Lib name,res;
      DAE.ExtArg arg;
      DAE.Exp exp,dim;

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
        res = generateArrayDataCall(name, ty);
      then
        res;

        /* OUTPUT ARRAY */
    case (arg ,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isOutputAttr(attr);
        true = Types.isArray(ty);
        name = varNameExternal(cref);
        res = generateArrayDataCall(name, ty);
      then
        res;

        /* INPUT/OUTPUT ARRAY */
    case (arg,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isArray(ty);
        name = varNameExternal(cref);
        res = generateArrayDataCall(name, ty);
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

protected function generateArrayDataCall "function: generateArrayDataCall

"
  input String inName;
  input DAE.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (inName, inType)
    local
      String name, str;
      DAE.Type ty;
    case (name, ty)
      equation
        ((DAE.T_INTEGER(_),_)) = Types.arrayElementType(ty);
        str = Util.stringAppendList({"data_of_integer_array(&(",name,"))"});
      then
        str;
    case (name, ty)
      equation
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(ty);
        str = Util.stringAppendList({"data_of_real_array(&(",name,"))"});
      then
        str;
    case (name, ty)
      equation
        ((DAE.T_BOOL(_),_)) = Types.arrayElementType(ty);
        str = Util.stringAppendList({"data_of_boolean_array(&(",name,"))"});
      then
        str;
    case (name, ty)
      equation
        ((DAE.T_STRING(_),_)) = Types.arrayElementType(ty);
        str = Util.stringAppendList({"data_of_string_array(&(",name,"))"});
      then
        str;
    case (_, _)
      equation
        Debug.fprint("failtrace",
          "#-- generate_array_data_call failed\n");
      then
        fail();
  end matchcontinue;
end generateArrayDataCall;

protected function generateArraySizeCall "function: generateArraySizeCall

"
  input DAE.ExtArg inExtArg;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExtArg)
    local
      Lib crstr,dimstr,str;
      DAE.ComponentRef cr;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Exp dim;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_INTEGER(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_integer_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_real_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_BOOL(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_boolean_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_STRING(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_string_array(",crstr,", ",dimstr,")"});
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
      DAE.ComponentRef cr;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      DAE.Exp dim;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_INTEGER(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_integer_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_real_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_BOOL(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_boolean_array(",crstr,", ",dimstr,")"});
      then
        str;
    case DAE.EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation
        ((DAE.T_STRING(_),_)) = Types.arrayElementType(ty);
        /* 1 is dummy since can not be output*/
        crstr = varNameArray(cr, attr,1);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size_of_dimension_string_array(",crstr,", ",dimstr,")"});
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
    case DAE.EXTARG(attributes = DAE.ATTR(direction = Absyn.OUTPUT())) then ();
  end matchcontinue;
end isExtargOutput;

protected function isExtargBidir "function:  is_extarg_output

  Succeeds if variable is external argument and bidirectional.
"
  input DAE.ExtArg inExtArg;
algorithm
  _:=
  matchcontinue (inExtArg)
    case DAE.EXTARG(attributes = DAE.ATTR(direction = Absyn.BIDIR())) then ();
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
    case ((var :: rest),retarg,(lang as "Java"),i, tnr) "Same as C"
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
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      DAE.Type ty;
    case (DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty),i)
      equation
        false = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        name = varNameExternal(cref);
        iStr = intString(i);
        typcast = generateSimpleType(ty);
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
    case(DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty),_) then cEmptyFunction;
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
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      DAE.Type ty;
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
        typcast = generateSimpleType(ty);
        str = Util.stringAppendList({"out.","targ",iStr," = (",typcast,")",name,";"});
        res = cAddStatements(cEmptyFunction, {str});
      then
        res;
    case (extarg,i) /* OUTPUT ARRAY */
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = extarg;
        true = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        tystr = generateSimpleType(ty);
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
        tystr = generateSimpleType(ty);
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
      DAE.ComponentRef id;
      DAE.VarKind vk;
      list<DAE.Element> r;
    case {} then {};
    case (DAE.VAR(componentRef = id,kind = vk,direction = DAE.INPUT()) :: r)
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
  input DAE.ComponentRef cref;
  output String str;
  DAE.ComponentRef cref_1;
algorithm
  cref_1 := varNameExternalCref(cref);
  (str,_) := compRefCstr(cref_1);
end varNameExternal;

protected function varNameExternalCref "function: varNameExternalCref

  Helper function to var_name_external.
"
  input DAE.ComponentRef cref;
  output DAE.ComponentRef cref_1;
  DAE.ComponentRef cref_1;
algorithm
  cref_1 := suffixCref(cref, "_ext");
end varNameExternalCref;

protected function suffixCref "function: suffixCref

  Prepends a string, suffix, to a ComponentRef.
"
  input DAE.ComponentRef inComponentRef;
  input String inString;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inComponentRef,inString)
    local
      Lib id_1,id,str;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cref_1,cref;
      DAE.ExpType ty;
    case (DAE.CREF_IDENT(ident = id,identType = ty,subscriptLst = subs),str)
      equation
        id_1 = stringAppend(id, str);
      then
        DAE.CREF_IDENT(id_1,ty,subs);
    case (DAE.CREF_QUAL(ident = id,identType = ty,subscriptLst = subs,componentRef = cref),str)
      equation
        cref_1 = suffixCref(cref, str);
      then
        DAE.CREF_QUAL(id,ty,subs,cref_1);
  end matchcontinue;
end suffixCref;

protected function varNameArray "function: varNameArray


"
  input DAE.ComponentRef inComponentRef;
  input DAE.Attributes inAttributes;
  input Integer i "nth tuple elt, only used for output vars";
  output String outString;
algorithm
  outString:=
  matchcontinue (inComponentRef,inAttributes,i)
    local
      Lib str,cref_str,iStr;
      DAE.ComponentRef cref;
      DAE.Attributes attr;
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
      DAE.ComponentRef id;
      DAE.VarKind vk;
      list<DAE.Element> r;
    case {} then {};
    case (DAE.VAR(componentRef = id,kind = vk,direction = DAE.INPUT()) :: r)
      equation
        cref_str = varNameExternal(id);
        r_1 = varArgNamesExternal(r);
      then
        (cref_str :: r_1);
    case (DAE.VAR(componentRef = id,kind = vk,direction = DAE.OUTPUT()) :: r)
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

protected function makeRecordRef "function: makeRecordRef

"
  input String inArg;
  input String inRecord;
  output String outRef;
algorithm
  outRef := Util.stringAppendList({"&(",inRecord,".",inArg,")"});
end makeRecordRef;

protected function generateVarName "function: generateVarName

"
  input DAE.Var inVar;
  output String outName;
algorithm
  outName :=
  matchcontinue (inVar)
    local
      DAE.Ident name;
    case DAE.TYPES_VAR(name = name)
      then name;
    case (_)
      then "NULL";
  end matchcontinue;
end generateVarName;

protected function generateRecordVarNames "function: generateRecordVarNames

"
  input DAE.Var inVar;
  output list<String> outNames;
algorithm
  outNames :=
  matchcontinue (inVar)
    local
      DAE.Ident name;
      list<DAE.Var> varlst;
      list<String> nameList;
      list<list<String>> namesList;
    case DAE.TYPES_VAR(name = name, type_ = (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = varlst),_))
      equation
        namesList = Util.listMap(varlst, generateRecordVarNames);
        nameList = Util.listFlatten(namesList);
        name = name +& ".";
        nameList = Util.listMap1r(nameList, stringAppend, name);
      then nameList;
    case DAE.TYPES_VAR(name = name)
      then {name};
    case (_)
      equation
        Debug.fprintln("failtrace", "- Codegen.generateRecordVarNames failed");
      then {};
  end matchcontinue;
end generateRecordVarNames;

protected function generateRecordMembers "function: generateRecordMembers

"
  input DAE.Type inRecordType;
  output list<String> outMembers;
algorithm
  outMembers :=
  matchcontinue (inRecordType)
    local
      list<DAE.Var> varlst;
      list<String> names;
      list<list<String>> nameList;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = varlst),_))
      equation
        nameList = Util.listMap(varlst, generateRecordVarNames);
        names = Util.listFlatten(nameList);
      then
        names;
    case (_) then {};
  end matchcontinue;
end generateRecordMembers;

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
      DAE.ComponentRef id;
      DAE.VarKind vk;
      DAE.Type t;
      list<DAE.Element> r;
      DAE.Element var;
      Boolean is_a;
    case {} then cEmptyFunction;
    case (DAE.VAR(componentRef = id,
                  kind = vk,
                  direction = DAE.INPUT(),
                  ty = t as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_),
                  dims = {}) :: r)
      local
        list<String> args;
        String arg_str;
      equation
        (cref_str,_) = compRefCstr(id);
        args = generateRecordMembers(t);
        args = Util.listMap1(args,makeRecordRef,cref_str);
        args = Util.listMap1r(args,stringAppend,",");
        arg_str = Util.stringAppendList(args);
        stmt = Util.stringAppendList(
          {"if(read_modelica_record(&inArgs",arg_str,")) return 1;"});
        cfn1 = cAddInits(cEmptyFunction, {stmt});
        cfn2 = generateRead(r);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
    case ((var as DAE.VAR(componentRef = id,
                  kind = vk,
                  direction = DAE.INPUT(),
                  ty = t)) :: r)
      equation
        is_a = isArray(var);
        type_string = generateType(t,is_a);
        (cref_str,_) = compRefCstr(id);
        stmt = Util.stringAppendList(
          {"if(read_",type_string,"(&inArgs, &",cref_str,")) return 1;"});
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

protected function generateRWType "function: generateRWType

"
  input DAE.Type inType;
  output String outType;
algorithm
  outType :=
  matchcontinue (inType)
    local
      DAE.Type t;
      String ret;
    case ((DAE.T_INTEGER(_), _)) then "TYPE_DESC_INT";
    case ((DAE.T_REAL(_), _)) then "TYPE_DESC_REAL";
    case ((DAE.T_STRING(_), _)) then "TYPE_DESC_STRING";
    case ((DAE.T_BOOL(_), _)) then "TYPE_DESC_BOOL";
    case ((DAE.T_ARRAY(arrayType = t as (DAE.T_ARRAY(_,_),_)), _))
      equation
        ret = generateRWType(t);
      then
        ret;
    case ((DAE.T_ARRAY(arrayType = t), _))
      equation
        ret = generateRWType(t);
        ret = stringAppend(ret, "_ARRAY");
      then
        ret;
    case ((DAE.T_TUPLE(_), _)) then "TYPE_DESC_TUPLE";
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)), _)) then "TYPE_DESC_RECORD";
    case t
      equation
        true = Types.isBoxedType(t);
      then "TYPE_DESC_MMC";
    case (_) then "TYPE_DESC_COMPLEX";
  end matchcontinue;
end generateRWType;

protected function generateVarType "function: generateVarType

"
  input DAE.Var inVar;
  output String outType;
algorithm
  outType :=
  matchcontinue (inVar)
    local
      DAE.Type t;
      String ret;
    case (DAE.TYPES_VAR(type_ = t))
      equation
        ret = generateRWType(t);
      then
        ret;
    case (_) then "TYPE_DESC_NONE";
  end matchcontinue;
end generateVarType;

protected function generateOutVar "function: generateOutVar

"
  input DAE.Var inVar;
  input String inRecordBase;
  output String outArgs;
algorithm
  outArgs := matchcontinue (inVar, inRecordBase)
    local
      DAE.Type ty;
      String name, path_str, base_str, stmt, type_arg, arg_str, ref_arg;
      list<DAE.Var> complexVarLst;
      list<String> args;
      /* Records can be nested and require recursively constructing the type_description */
    case (DAE.TYPES_VAR(name = name, type_ = ty as (DAE.T_COMPLEX(complexVarLst = complexVarLst, complexClassType = ClassInf.RECORD(_)),_)),inRecordBase)
      equation
        type_arg = generateVarType(inVar);
        base_str = inRecordBase +& "." +& name;
        (path_str,args) = generateOutRecordMembers(ty,base_str);
        args = listAppend(args, {"TYPE_DESC_NONE"});
        arg_str = Util.stringDelimitList(args,",");

        stmt = Util.stringAppendList({"&",path_str,"__desc, ",arg_str});
        outArgs = Util.stringDelimitList({type_arg,stmt}, ", ");
      then
        outArgs;
        /* Not records */
    case (DAE.TYPES_VAR(name = name, type_ = ty),inRecordBase)
      equation
        type_arg = generateVarType(inVar);
        ref_arg = makeRecordRef(name,inRecordBase);
        outArgs = Util.stringDelimitList({type_arg,ref_arg}, ",");
      then
        outArgs;
  end matchcontinue;
end generateOutVar;

protected function generateOutRecordMembers "function: generateOutRecordMembers

"
  input DAE.Type inRecordType;
  input String inRecordBase;
  output String outRecordType;
  output list<String> outMembers;
algorithm
  (outRecordType,outMembers) :=
  matchcontinue (inRecordType,inRecordBase)
    local
      list<DAE.Var> varlst;
      list<String> args;
      String base_str, path_str;
      Absyn.Path path;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = varlst), SOME(path)),base_str)
      equation
        args = Util.listMap1(varlst, generateOutVar, base_str);
        path_str = ModUtil.pathStringReplaceDot(path, "_");
        // path_str = Util.stringAppendList({"\"",path_str,"\""});
      then
        (path_str, args);
    case ((_,_),_)
      equation
        Debug.fprintln("failtrace", "- Codegen.generateOutRecordMembers failed");
      then fail();
    /*
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_), complexVarLst = varlst), _),base_str)
      equation
        args = Util.listMap1(varlst, generateOutVar, base_str);
      then
        ("NULL", args);
    case ((_,_),_)
      then ("", {});
    */
  end matchcontinue;
end generateOutRecordMembers;

protected function generateWriteOutvars "
 generates code for writing output variables in return struct to file.
"
  input list<DAE.Element> inDAEElementLst;
  input Integer i "nth tuple elt";
  output CFunction outCFunction;
algorithm
  outCFunction:=
  matchcontinue (inDAEElementLst,i)
    local
      String cref_str,type_string,stmt,iStr;
      CFunction cfn1,cfn2,cfn;
      DAE.ComponentRef id;
      DAE.VarKind vk;
      DAE.Type t;
      list<DAE.Element> r;
      DAE.Element var;
      Boolean is_a;
    case ({},1) /* NORETCALL function */
      equation
        cfn = cAddStatements(cEmptyFunction, {"write_noretcall(outVar);"});
      then cfn;
    case ({},_) then cEmptyFunction;
    case (DAE.VAR(componentRef = id,
                  kind = vk,
                  direction = DAE.OUTPUT(),
                  ty = t as (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_),
                  dims = {}) :: r,i)
      local
        list<String> args;
        String arg_str, base_str, path_str;
      equation
        iStr = intString(i);
        base_str = stringAppend("out.targ",iStr);

        (path_str,args) = generateOutRecordMembers(t,base_str);
        args = listAppend(args, {"TYPE_DESC_NONE"});
        arg_str = Util.stringDelimitList(args,",");

        stmt = Util.stringAppendList({"write_modelica_record(outVar, &",
                                      path_str,"__desc, ",arg_str,");"});
        cfn1 = cAddStatements(cEmptyFunction, {stmt});
        cfn2 = generateWriteOutvars(r,i+1);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
    case ((var as DAE.VAR(componentRef = id,
                  kind = vk,
                  direction = DAE.OUTPUT(),
                  ty = t)) :: r,i)
      equation
        iStr = intString(i);
        is_a = isArray(var);
        type_string = generateType(t,is_a);
        stmt = Util.stringAppendList({"write_",type_string,"(outVar, &out.","targ",iStr,");"});
        cfn1 = cAddStatements(cEmptyFunction, {stmt});
        cfn2 = generateWriteOutvars(r,i+1);
        cfn = cMergeFn(cfn1, cfn2);
      then
        cfn;
    case (el :: r,i)
      local
        DAE.Element el;
      equation
        failure(DAEUtil.isVar(el));
        cfn = generateWriteOutvars(r,i);
      then
        cfn;
    case (_,_)
      equation
        Debug.fprintln("failtrace", "- Codegen.generateWriteOutvars failed");
      then fail();
  end matchcontinue;
end generateWriteOutvars;

protected function isOutput "Returns true if variable is output"
  input DAE.Element e;
  output Boolean isOutput;
algorithm
  isOutput := matchcontinue(e)
    case(e) equation
      DAEUtil.isOutputVar(e);
    then true;
    case(_) then false;
  end matchcontinue;
end isOutput;

protected function isRcwOutput "function: isRcwOutput

"
  input DAE.Element e;
algorithm
  DAEUtil.isVar(e);
  DAEUtil.isOutputVar(e);
end isRcwOutput;

protected function isRcwInput "function: isRcwInput

"
  input DAE.Element e;
algorithm
  DAEUtil.isVar(e);
  DAEUtil.isInputVar(e);
end isRcwInput;

protected function isRcwBidir "function: isRcwBidir

"
  input DAE.Element e;
algorithm
  DAEUtil.isVar(e);
  DAEUtil.isBidirVar(e);
end isRcwBidir;

protected function generateJavaSignature
"function: generateJavaSignature
  Generates a Java call signature from the function arguments."
  input list<DAE.ExtArg> args;
  input DAE.ExtArg retArg;
  input Boolean isSimpleJavaMapping;
  output String signature;
protected
  list<String> argsSig;
  String retSig;
  String argSig;
algorithm
  retSig := Util.if_(isSimpleJavaMapping, argToSimpleJavaSigType(retArg), argToJavaSigType(retArg));
  argsSig := Util.if_(isSimpleJavaMapping, Util.listMap(args, argToSimpleJavaSigType), Util.listMap(args, argToJavaSigType));
  argSig := Util.stringAppendList(argsSig);
  signature := "(" +& argSig +& ")" +& retSig;
end generateJavaSignature;

protected function argToJavaSigType
"function: argToJavaSigType
  Translates a single function argument to the corresponding Java call signature type."
  input DAE.ExtArg arg;
  output String sig;
algorithm
  sig := matchcontinue arg
    case DAE.NOEXTARG() then "V"; /* Void return */
    case DAE.EXTARG(type_ = (DAE.T_INTEGER(_),_)) then "Lorg/openmodelica/ModelicaInteger;";
    case DAE.EXTARG(type_ = (DAE.T_REAL(_),_)) then "Lorg/openmodelica/ModelicaReal;";
    case DAE.EXTARG(type_ = (DAE.T_BOOL(_),_)) then "Lorg/openmodelica/ModelicaBoolean;";
    case DAE.EXTARG(type_ = (DAE.T_STRING(_),_)) then "Lorg/openmodelica/ModelicaString;";
    case DAE.EXTARG(type_ = (DAE.T_ARRAY(_,_),_)) then "Lorg/openmodelica/ModelicaArray;";
    case DAE.EXTARG(type_ = (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)),_)) then "Lorg/openmodelica/ModelicaRecord;";
    case DAE.EXTARG(type_ = (DAE.T_UNIONTYPE(_),_)) then "Lorg/openmodelica/IModelicaRecord;";
    case DAE.EXTARG(type_ = (DAE.T_METATUPLE(_),_)) then "Lorg/openmodelica/ModelicaTuple;";
    case DAE.EXTARG(type_ = (DAE.T_LIST(_),_)) then "Lorg/openmodelica/ModelicaArray;";
    case DAE.EXTARG(type_ = (DAE.T_METAOPTION(_),_)) then "Lorg/openmodelica/ModelicaOption;";
    case _
      equation
        print("Warning: Codegen.argToJavaSigType: Unknown type - defaulting to ModelicaObject\n");
      then "Lorg/openmodelica/ModelicaObject;";
  end matchcontinue;
end argToJavaSigType;

protected function argToSimpleJavaSigType
"function: argToSimpleJavaSigType
  Translates a single function argument to the corresponding Java call signature type."
  input DAE.ExtArg arg;
  output String sig;
algorithm
  sig := matchcontinue arg
    case DAE.NOEXTARG() then "V"; /* Void return */
    case DAE.EXTARG(type_ = (DAE.T_INTEGER(_),_)) then "I";
    case DAE.EXTARG(type_ = (DAE.T_REAL(_),_)) then "D";
    case DAE.EXTARG(type_ = (DAE.T_BOOL(_),_)) then "Z";
    case DAE.EXTARG(type_ = (DAE.T_STRING(_),_)) then "Ljava/lang/String;";
    case _ then "Lnot/a/simple/type;";
  end matchcontinue;
end argToSimpleJavaSigType;

protected function generateExtCallFcallArgJava
  input DAE.ExtArg inExtArg;
  input Integer i "nth tuple elt, used in outputs";
  output String outString;
algorithm
  outString:=
  matchcontinue (inExtArg,i)
    local
      DAE.ComponentRef cref;
      DAE.Attributes attr;
      tuple<DAE.TType, Option<Absyn.Path>> ty;
      Lib res,name,str;
      DAE.ExtArg arg;
      DAE.Exp exp;

      /* INPUT NON-ARRAY NON-STRING */
    case (arg,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isInputAttr(attr);
        false = Types.isArray(ty);
        false = Types.isString(ty);
        res = varNameExternal(cref);
        res = Util.stringReplaceChar(res, ".", "_");
      then
        res;

        /* OUTPUT NON-ARRAY */
    case (arg,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        false = Types.isArray(ty);
        true = Types.isOutputAttr(attr);
        res = varNameExternal(cref);
        res = Util.stringReplaceChar(res, ".", "_");
      then
        res;

        /* INPUT/OUTPUT ARRAY */
    case (arg,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isArray(ty);
        res = varNameArray(cref, attr,i);
        res = Util.stringReplaceChar(res, ".", "_");
      then
        res;

        /* INPUT/OUTPUT STRING */
    case (arg,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        true = Types.isString(ty);
        (res,_) = compRefCstr(cref);
        res = Util.stringReplaceChar(res, ".", "_");
      then
        res;

        /* INPUT/OUTPUT NON-ARRAY */
    case (arg,i)
      equation
        DAE.EXTARG(componentRef = cref,attributes = attr,type_ = ty) = arg;
        false = Types.isArray(ty);
        (res,_) = compRefCstr(cref);
        res = Util.stringReplaceChar(res, ".", "_");
      then
        res;

    case (arg,i)
      equation
        DAE.EXTARGEXP(exp = exp,type_ = ty) = arg;
        (_,res,_) = generateExpression(exp, 1, funContext);
      then
        res;

    case (arg,i)
      equation
        Debug.fprint("failtrace", "#-- generate_ext_call_fcall_arg failed\n");
      then
        fail();
  end matchcontinue;
end generateExtCallFcallArgJava;

protected function generateExtCallFcallArgsJava
  input list<DAE.ExtArg> args;
  input Integer i "nth tuple elt, only used for outputs";
  output list<String> strLst;
algorithm
  strLst := matchcontinue(args,i)
  local String str; Integer i1; DAE.ExtArg a; Boolean b;
    case({},i) then {};
    case(a::args,i) equation
      b = isOutputExtArg(a);
      str = generateExtCallFcallArgJava(a,i);
      i1 = Util.if_(b,i+1,i);
      strLst = generateExtCallFcallArgsJava(args,i1);
    then str::strLst;
  end matchcontinue;
end generateExtCallFcallArgsJava;

protected function generateExtCallFcallJava
  input list<DAE.ExtArg> inDAEExtArgLst;
  input Boolean isSimpleJavaMapping;
  output list<String> outPreCall;
  output list<String> outPostCall;
  output list<String> varNames;
algorithm
  (outPreCall,outPostCall) := matchcontinue (inDAEExtArgLst,isSimpleJavaMapping)
    local
      list<DAE.ExtArg> args;
      list<String> initArgs;
      list<String> cleanupArgs;
    case (args,isSimpleJavaMapping)
      equation
        (initArgs,cleanupArgs,varNames) = generateExtCallFcallJava2(args,1,isSimpleJavaMapping);
      then
        (initArgs, "(*__env)->DeleteLocalRef(__env, __cls);" :: cleanupArgs,
         varNames);
  end matchcontinue;
end generateExtCallFcallJava;

protected function generateExtCallFcallJava2
  input list<DAE.ExtArg> inDAEExtArgLst;
  input Integer i;
  input Boolean isSimpleJavaMapping;
  output list<String> initArgs;
  output list<String> cleanupArgs;
  output list<String> varNames;
algorithm
  (initArgs,cleanupArgs,varNames) := matchcontinue (inDAEExtArgLst,i,isSimpleJavaMapping)
    local
      list<DAE.ExtArg> rest;
      list<String> initArgs, cleanupArgs, argDecl, argClean, varNames, argVarNames;
      DAE.Attributes attr;
      DAE.ExtArg arg;
      DAE.Type ty;
      DAE.ComponentRef cr;
      Integer i1;
      Boolean b;
      String name, nameArr;
    case ({},_,_) then ({},{},{});
    case ((arg as DAE.EXTARG(componentRef = cr, type_ = ty, attributes = attr)) :: rest, i, false) equation
      b = isOutputExtArg(arg);
      i1 = Util.if_(b,i+1,i);
      (initArgs,cleanupArgs,varNames) = generateExtCallFcallJava2(rest,i1,isSimpleJavaMapping);
      name = generateExtCallFcallArgJava(arg,i);
      nameArr = varNameArray(cr, attr, i);
      (argDecl,argClean,argVarNames) = javaExtNewAndClean(name,nameArr,ty,b);
    then (listAppend(argDecl, initArgs), listAppend(argClean, cleanupArgs), listAppend(varNames, argVarNames));
    case ((arg as DAE.EXTARG(componentRef = cr, type_ = ty, attributes = attr)) :: rest, i, true) equation
      false = isOutputExtArg(arg);
      (initArgs,cleanupArgs,varNames) = generateExtCallFcallJava2(rest,i+1,isSimpleJavaMapping);
      name = generateExtCallFcallArgJava(arg,i);
      (argDecl,argClean,argVarNames) = javaExtSimpleNewAndClean(name,ty,false);
    then (listAppend(argDecl, initArgs), listAppend(argClean, cleanupArgs), listAppend(varNames, argVarNames));
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- generateExtCallFcallJava2 failed");
      then fail();    
  end matchcontinue;
end generateExtCallFcallJava2;

protected function javaExtRecordFields
  input String cref;
  input String nameJava;
  input Boolean isOut;
  input list<DAE.Var> varLst;
  output list<String> init;
  output list<String> clean;
  output list<String> varNames;
algorithm
  (init,clean,varNames) := matchcontinue(cref, nameJava, isOut, varLst)
  local
    DAE.Var var;
    list<DAE.Var> rest;
    list<String> init, clean, varNames;
    list<String> initField, cleanField, cleanField2, varNamesField;
    String name, nameJavaRes, nameJavaMap, addToMap, readBack;
    DAE.Type type_;
  case (_, _, _, {}) then ({},{},{});
  case (cref, nameJava, isOut, DAE.TYPES_VAR(protected_ = true)::rest) equation
    (init,clean,varNames) = javaExtRecordFields(cref, nameJava, isOut, rest);
  then (init,clean,varNames);
  case (cref, nameJava, isOut, DAE.TYPES_VAR(name = name, type_ = type_)::rest) equation
    (init,clean,varNames) = javaExtRecordFields(cref, nameJava, isOut, rest);
    nameJavaMap = nameJava +& "_temp_map";
    cref = cref +& "." +& name;
    (initField,cleanField,varNamesField) = javaExtNewAndClean(cref, cref, type_, false);
    nameJavaRes = Util.listFirst(varNamesField);
    nameJavaRes = System.stringReplace(nameJavaRes, "jobject ", "");
    nameJavaRes = Util.stringReplaceChar(nameJavaRes, ";", "");
    addToMap = Util.stringAppendList({"AddObjectToJavaMap(__env, ", nameJavaMap, ", \"", name, "\", ", nameJavaRes, ");"});
    (_,cleanField2,_) = javaExtNewAndClean(cref, cref, type_, true);
    readBack = Util.stringAppendList({nameJavaRes, " = GetObjectFromJavaMap(__env, ", nameJava, ", \"", name, "\");"});
    initField = listAppend(initField, addToMap::cleanField);
    clean = Util.if_(isOut, listAppend(readBack::cleanField2, clean), clean);
  then (listAppend(initField,init),clean,listAppend(varNamesField,varNames));
  case (_,_,_,_) equation
    Debug.fprint("failtrace", "javaExtRecordFields failed");
  then fail();
  end matchcontinue;
end javaExtRecordFields;

protected function javaExtNewAndClean
  input String name;
  input String nameArr;
  input DAE.Type ty;
  input Boolean isOut;
  output list<String> init;
  output list<String> clean;
  output list<String> varNames;
algorithm
  (init,clean) := matchcontinue(name,nameArr,ty,isOut)
  local
    Integer ndim;
    list<DAE.Var> varLst;
    list<String> dimRange, clean, initList, sizeCalls, initField, cleanField, varNamesField;
    String ndimStr, dimRangeMult, dimRangeArgs, checkEx, init, name, nameIn, arrayAcc, nameJava;
    String readBack, cleanUp, arrayCons, dataCall, sizeCall, makeMulDim, makeArray, flattenArray;
    String recordName, nameJavaMap, mapInit, mapClean, pathStr, structInit;
    DAE.ComponentRef cr;
    DAE.Type arrayty,ty;
    Absyn.Path path_;
    
    case (name,nameArr,((DAE.T_INTEGER(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      nameIn = Util.if_(isOut, "0", name); // Out variables are not initialized...
      init = Util.stringAppendList({nameJava, " = NewJavaInteger(__env, ", nameIn, ");"});
      readBack = Util.stringAppendList({name, " = GetJavaInteger(__env, ", nameJava,");"});
      cleanUp  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
      clean = Util.if_(isOut, {readBack,cleanUp}, {cleanUp});
      nameJava = Util.stringAppendList({"jobject ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,nameArr,((DAE.T_REAL(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      nameIn = Util.if_(isOut, "0", name); // Out variables are not initialized...
      init = Util.stringAppendList({nameJava, " = NewJavaDouble(__env, ", nameIn, ");"});
      readBack = Util.stringAppendList({name, " = GetJavaDouble(__env, ", nameJava,");"});
      cleanUp  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
      clean = Util.if_(isOut, {readBack,cleanUp}, {cleanUp});
      nameJava = Util.stringAppendList({"jobject ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,nameArr,((DAE.T_STRING(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      nameIn = Util.if_(isOut, "NULL", name); // Out variables are not initialized...
      init = Util.stringAppendList({nameJava, " = NewJavaString(__env, ", nameIn, ");"});
      readBack = Util.stringAppendList({name, " = GetJavaString(__env, ", nameJava,");"});
      cleanUp  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
      clean = Util.if_(isOut, {readBack,cleanUp}, {cleanUp});
      nameJava = Util.stringAppendList({"jobject ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,nameArr,((DAE.T_BOOL(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      nameIn = Util.if_(isOut, "JNI_FALSE", name); // Out variables are not initialized...
      init = Util.stringAppendList({nameJava, " = NewJavaBoolean(__env, ", nameIn, ");"});
      readBack = Util.stringAppendList({name, " = GetJavaBoolean(__env, ", nameJava,");"});
      cleanUp  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
      clean = Util.if_(isOut, {readBack,cleanUp}, {cleanUp});
      nameJava = Util.stringAppendList({"jobject ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,nameArr,((DAE.T_UNIONTYPE(_),_)),isOut) equation
      /* The other MetaModelica types should probably use the same function */
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      nameIn = Util.if_(isOut, "mmc_mk_box1(2, NULL)", name); // Out variables are not initialized...
      init = Util.stringAppendList({nameJava, " = mmc_to_jobject(__env, ", nameIn, ");"});
      readBack = Util.stringAppendList({name, " = jobject_to_mmc(__env, ", nameJava,");"});
      cleanUp  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
      clean = Util.if_(isOut, {readBack,cleanUp}, {cleanUp});
      nameJava = Util.stringAppendList({"jobject ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,nameArr,ty as ((DAE.T_ARRAY(_,_),_)), isOut) equation
       (arrayty,_) = Types.flattenArrayType(ty);
       ndim = Types.ndims(ty);
       
       name = nameArr;
       nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
       checkEx = "CHECK_FOR_JAVA_EXCEPTION(__env);";
       dataCall = generateArrayDataCall(name, ty);
       sizeCalls = listReverse(generateArraySizeCallJava(name, ty, ndim));
       dimRangeMult = Util.stringDelimitList(sizeCalls,"*");
       dimRangeArgs = Util.stringDelimitList(sizeCalls,",");
       
       arrayCons = generateJavaArrayConstructor(arrayty);
       makeArray = Util.stringAppendList({nameJava, " = ", arrayCons,"(__env, ", dataCall,",",dimRangeMult,");"});
       ndimStr = intString(ndim);
       makeMulDim = Util.stringAppendList({"MakeJavaMultiDimArray(__env, ", nameJava, ", ", ndimStr, ",", dimRangeArgs,");"});
       initList = {makeArray,checkEx,makeMulDim,checkEx};
       
       arrayAcc = generateJavaArrayAccessor(arrayty);
       flattenArray = Util.stringAppendList({"FlattenJavaMultiDimArray(__env, ", nameJava,");"});
       readBack = Util.stringAppendList({arrayAcc, "(__env, ", nameJava, ",", dataCall,",",dimRangeMult, ");"});
       cleanUp = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
       clean = Util.if_(isOut, {flattenArray,readBack,cleanUp}, {cleanUp});
       nameJava = Util.stringAppendList({"jobject ",nameJava,";"});
    then (initList,clean,{nameJava});
    case (name,nameArr,((DAE.T_COMPLEX(complexVarLst = varLst, complexClassType = ClassInf.RECORD(_)),SOME(path_))), isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      nameJavaMap = Util.stringReplaceChar(name, ".", "_") +& "_java_temp_map";
      
      (initField,cleanField,varNamesField) = javaExtRecordFields(name, nameJava, isOut, varLst);
      
      structInit = "memset(&" +& name +& ", '\\0', sizeof("+&name+&")); /* Initialize struct */";
      mapInit = Util.stringAppendList({nameJavaMap, " = NewJavaMap(__env);"});
      mapClean  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJavaMap, ");"});
      pathStr = Absyn.pathString(path_);
      init = Util.stringAppendList({nameJava, " = NewJavaRecord(__env,\"", pathStr, "\",-1,",nameJavaMap,");"});
      initList = listAppend(mapInit::initField, init::mapClean::{});
      initList = Util.if_(isOut, structInit::initList, initList);
      
      cleanUp  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
      
      nameJavaMap = Util.stringAppendList({"jobject ",nameJavaMap,";"});
      nameJava = Util.stringAppendList({"jobject ",nameJava,";"});
    then (initList,listAppend(cleanField,cleanUp::{}),nameJava::nameJavaMap::varNamesField);
    case (_,_,_,_) equation
      Debug.fprint("failtrace", "#-- javaExtNewAndClean failed\n");
    then fail();
  end matchcontinue;
end javaExtNewAndClean;

protected function javaExtSimpleNewAndClean
  input String name;
  input DAE.Type ty;
  input Boolean isOut;
  output list<String> init;
  output list<String> clean;
  output list<String> varNames;
algorithm
  (init,clean) := matchcontinue(name,ty,isOut)
  local
    Integer ndim;
    list<DAE.Var> varLst;
    list<String> dimRange, clean, initList, sizeCalls, initField, cleanField, varNamesField;
    String ndimStr, dimRangeMult, dimRangeArgs, checkEx, init, name, nameIn, arrayAcc, nameJava;
    String readBack, cleanUp, arrayCons, dataCall, sizeCall, makeMulDim, makeArray, flattenArray;
    String recordName, nameJavaMap, mapInit, mapClean, pathStr, structInit;
    DAE.ComponentRef cr;
    DAE.Type arrayty,ty;
    Absyn.Path path_;
    
    case (name,((DAE.T_INTEGER(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      init = Util.stringAppendList({nameJava, " = ", name, ";"});
      readBack = Util.stringAppendList({name, " = ", nameJava,";"});
      clean = Util.if_(isOut, {readBack}, {});
      nameJava = Util.stringAppendList({"jint ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,((DAE.T_REAL(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      init = Util.stringAppendList({nameJava, " = ", name, ";"});
      readBack = Util.stringAppendList({name, " = ", nameJava,";"});
      clean = Util.if_(isOut, {readBack}, {});
      nameJava = Util.stringAppendList({"jdouble ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,((DAE.T_BOOL(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      init = Util.stringAppendList({nameJava, " = (", name, " != 0 ? JNI_TRUE : JNI_FALSE);"});
      readBack = Util.stringAppendList({name, " = ", nameJava,";"});
      clean = Util.if_(isOut, {readBack}, {});
      nameJava = Util.stringAppendList({"jboolean ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (name,((DAE.T_STRING(_),_)),isOut) equation
      nameJava = Util.stringReplaceChar(name, ".", "_") +& "_java";
      init = Util.stringAppendList({nameJava, " = (*__env)->NewStringUTF(__env,",name,");"});
      readBack = Util.stringAppendList({name, " = copyJstring(__env, ", nameJava,");"});
      cleanUp  = Util.stringAppendList({"(*__env)->DeleteLocalRef(__env, ", nameJava, ");"});
      clean = Util.if_(isOut, {readBack,cleanUp}, {cleanUp});
      nameJava = Util.stringAppendList({"jstring ",nameJava,";"});
    then ({init},clean,{nameJava});
    case (_,_,_) equation
    then ({"NOT_SIMPLE_TYPE"},{"NOT_SIMPLE_TYPE"},{"NOT_SIMPLE_TYPE"});
  end matchcontinue;
end javaExtSimpleNewAndClean;

protected function generateJavaArrayConstructor
  input DAE.Type ty;
  output String out;
algorithm
  out := matchcontinue(ty)
    case ((DAE.T_INTEGER(_),_)) equation
    then "NewFlatJavaIntegerArray";
    case ((DAE.T_REAL(_),_)) equation
    then "NewFlatJavaDoubleArray";
    case ((DAE.T_STRING(_),_)) equation
    then "NewFlatJavaStringArray";
    case ((DAE.T_BOOL(_),_)) equation
    then "NewFlatJavaBooleanArray";
    case (_) equation
      Debug.fprint("failtrace", "#-- generateJavaArrayConstructor failed\n");
    then fail();
  end matchcontinue;
end generateJavaArrayConstructor;

protected function generateJavaArrayAccessor
  input DAE.Type ty;
  output String out;
algorithm
  out := matchcontinue(ty)
    case ((DAE.T_INTEGER(_),_)) equation
    then "GetFlatJavaIntegerArray";
    case ((DAE.T_REAL(_),_)) equation
    then "GetFlatJavaDoubleArray";
    case ((DAE.T_STRING(_),_)) equation
    then "GetFlatJavaStringArray";
    case ((DAE.T_BOOL(_),_)) equation
    then "GetFlatJavaBooleanArray";
    case (_) equation
      Debug.fprint("failtrace", "#-- generateJavaArrayAccessor failed\n");
    then fail();
  end matchcontinue;
end generateJavaArrayAccessor;

protected function generateArraySizeCallJava
  input String inName;
  input DAE.Type inType;
  input Integer lastDim;
  output list<String> out;
algorithm
  out :=
  matchcontinue (inName, inType, lastDim)
    local
      String name, str, thisDimStr;
      list<String> res;
      DAE.Type ty;
    case (_,_,0)
      then {};
    case (name, ty, lastDim)
      equation
        ((DAE.T_INTEGER(_),_)) = Types.arrayElementType(ty);
        thisDimStr = intString(lastDim);
        str = Util.stringAppendList({"size_of_dimension_integer_array(",name,",",thisDimStr,")"});
        res = generateArraySizeCallJava(name, ty, lastDim-1);
      then
        str :: res;
    case (name, ty, lastDim)
      equation
        ((DAE.T_REAL(_),_)) = Types.arrayElementType(ty);
        thisDimStr = intString(lastDim);
        str = Util.stringAppendList({"size_of_dimension_real_array(",name,",",thisDimStr,")"});
        res = generateArraySizeCallJava(name, ty, lastDim-1);
      then
        str :: res;
    case (name, ty, lastDim)
      equation
        ((DAE.T_BOOL(_),_)) = Types.arrayElementType(ty);
        thisDimStr = intString(lastDim);
        str = Util.stringAppendList({"size_of_dimension_boolean_array(",name,",",thisDimStr,")"});
        res = generateArraySizeCallJava(name, ty, lastDim-1);
      then
        str :: res;
    case (name, ty, lastDim)
      equation
        ((DAE.T_STRING(_),_)) = Types.arrayElementType(ty);
        thisDimStr = intString(lastDim);
        str = Util.stringAppendList({"size_of_dimension_string_array(",name,",",thisDimStr,")"});
        res = generateArraySizeCallJava(name, ty, lastDim-1);
      then
        str :: res;
    case (_, _, _)
      equation
        Debug.fprint("failtrace",
          "#-- generateArraySizeCallJava failed\n");
      then
        fail();
  end matchcontinue;
end generateArraySizeCallJava;

protected function generateJavaClassAndMethod "
function: generateJavaClassAndMethod
\"'package.class.method'\" -> (\"package/class\",\"method\")
"
  input String s;
  output String className;
  output String methodName;
  String tmp;
  list<String> parts;
algorithm
  tmp := Util.stringReplaceChar(s, "'", "");
  tmp := Util.stringReplaceChar(tmp, ".", "/");
  parts := Util.stringSplitAtChar(tmp, "/");
  methodName := Util.listLast(parts);
  parts := Util.listStripLast(parts);
  className := Util.stringDelimitList(parts, "/");
end generateJavaClassAndMethod;

protected function getJavaCallMapping "
function: getJavaCallMapping
String->Boolean. Checks if it is a simple call mapping JavaSimple
or a normal one Java. Fails if it is anything else.
"
  input String lang;
  output Boolean isSimpleJavaCall;
algorithm
  isSimpleJavaCall := matchcontinue(lang)
    case "Java" then false;
    case "JavaSimple" then true;
  end matchcontinue;
end getJavaCallMapping;

protected function getJavaCallMappingFromAnn
  input String lang;
  input Option<Absyn.Annotation> ann;
  output String res;
algorithm
  res := matchcontinue (lang,ann)
    local
      list<Absyn.ElementArg> eltarg;
      Boolean isSimpleJavaCallMapping;
    case ("Java",SOME(Absyn.ANNOTATION(eltarg)))
      equation
        getJavaCallMappingFromEltArg(eltarg);
      then "JavaSimple";
    case (lang,_) then lang;
  end matchcontinue;
end getJavaCallMappingFromAnn;

protected function getJavaCallMappingFromEltArg
  input list<Absyn.ElementArg> inAbsynElementArgLst;
algorithm
  res := matchcontinue (inAbsynElementArgLst)
    local
      list<Absyn.ElementArg> eltarg;
    case (eltarg)
      equation
        Absyn.CLASSMOD(_,SOME(Absyn.STRING("simple"))) = 
        Interactive.getModificationValue(eltarg, Absyn.CREF_IDENT("JavaMapping",{}));
      then ();
  end matchcontinue;
end getJavaCallMappingFromEltArg;

protected function getJniCallFunc
  input DAE.Type ty;
  input Boolean isJavaSimpleCallMethod;
  output String res;
algorithm
  res := matchcontinue (ty, isJavaSimpleCallMethod)
    case (_, false) then "CallStaticObjectMethod";
    case ((DAE.T_INTEGER(_),_), _) then "CallStaticIntMethod";
    case ((DAE.T_REAL(_),_), _) then "CallStaticDoubleMethod";
    case ((DAE.T_BOOL(_),_), _) then "CallStaticBooleanMethod";
    case (_, _) then "CallStaticObjectMethod";
  end matchcontinue;
end getJniCallFunc;

public function matchFnRefs
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local DAE.Exp e; DAE.ExpType t;
    case((e as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC()))) then {e};
    case(DAE.PARTEVALFUNCTION(ty = DAE.ET_FUNCTION_REFERENCE_VAR(),path=p,expList=expLst))
      local
        DAE.ComponentRef cref; Absyn.Path p; list<DAE.Exp> expLst,expLst_1;
      equation
        cref = Exp.pathToCref(p);
        e = Exp.makeCrefExp(cref,DAE.ET_FUNCTION_REFERENCE_VAR());
        expLst_1 = getMatchingExpsList(expLst,matchFnRefs);
      then
        e :: expLst_1;
    case(DAE.CALL(expLst = expLst))
      local
        list<DAE.Exp> expLst,expLst_1;
      equation
        expLst_1 = getMatchingExpsList(expLst,matchFnRefs);
      then
        expLst_1;
  end matchcontinue;
end matchFnRefs;

public function matchCalls
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local list<DAE.Exp> args, exps; DAE.Exp e;
    case (e as DAE.CALL(expLst = args))
      equation 
        exps = getMatchingExpsList(args,matchCalls);
      then
        e::exps;
  end matchcontinue;
end matchCalls;

public function matchMetarecordCalls
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local list<DAE.Exp> args, exps; DAE.Exp e;
    case (e as DAE.METARECORDCALL(args = args))
      equation 
        exps = getMatchingExpsList(args,matchMetarecordCalls);
      then
        e::exps;
  end matchcontinue;
end matchMetarecordCalls;

public function matchValueblock
"Used together with getMatchingExps"
  input DAE.Exp inExpr;
  output list<DAE.Exp> outExprLst;
algorithm
  outExprLst := matchcontinue (inExpr)
    local
      list<DAE.Exp> res, exps, exps2;
      DAE.Exp e,resE;
      list<DAE.Element> ld;
      list<DAE.Statement> body;
    case e as DAE.VALUEBLOCK(localDecls = ld,body = body,result = resE)
      equation
        exps = DAEUtil.getAllExps(ld);
        exps2 = Algorithm.getAllExpsStmts(body);
        exps = listAppend(exps,exps2);
        res = getMatchingExpsList(resE::exps,matchValueblock);
      then e::res;
  end matchcontinue;
end matchValueblock;

public function getMatchingExpsList
  input list<DAE.Exp> inExps;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
  list<list<DAE.Exp>> explists;
algorithm 
  explists := Util.listMap1(inExps, getMatchingExps, inFn);
  outExpLst := Util.listFlatten(explists);
end getMatchingExpsList;

public function getMatchingExps
"function: getMatchingExps
  Return all exps that match the given function.
  Inner exps may be returned separately but not 
  extracted from the exp they are in, e.g. 
    CALL(foo, {CALL(bar)}) will return
    {CALL(foo, {CALL(bar)}), CALL(bar,{})}
Implementation note: DAE.Exp contains VALUEBLOCKS,
  which can't be processed in Exp due to circular dependencies with DAE.
  In the future, this function should be moved to Exp."
  input DAE.Exp inExp;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExpr;
    output list<DAE.Exp> outExprLst;
  end MatchFn;
algorithm 
  outExpLst:=
  matchcontinue (inExp,inFn)
    local
      list<DAE.Exp> exps,exps2,args,a,b,res,elts,elst,elist;
      DAE.Exp e,e1,e2,e3;
      Absyn.Path path;
      Boolean tuple_,builtin;
      list<tuple<DAE.Exp, Boolean>> flatexplst;
      list<list<tuple<DAE.Exp, Boolean>>> explst;
      Option<DAE.Exp> optexp;
      MatchFn fn;
    
    // First we check if the function matches
    case (e, fn)
      equation
        res = fn(e);
      then res;
    
    // Else: Traverse all Exps
    case ((e as DAE.CALL(path = path,expLst = args,tuple_ = tuple_,builtin = builtin)),fn)
      equation 
        exps = getMatchingExpsList(args,fn);
      then
        exps;
    case (DAE.PARTEVALFUNCTION(expList = args),fn)
      equation
        res = getMatchingExpsList(args,fn);
      then
        res;
    case (DAE.BINARY(exp1 = e1,exp2 = e2),fn) /* Binary */ 
      equation 
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.UNARY(exp = e),fn) /* Unary */ 
      equation 
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.LBINARY(exp1 = e1,exp2 = e2),fn) /* LBinary */ 
      equation 
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.LUNARY(exp = e),fn) /* LUnary */ 
      equation 
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.RELATION(exp1 = e1,exp2 = e2),fn) /* Relation */ 
      equation 
        a = getMatchingExps(e1,fn);
        b = getMatchingExps(e2,fn);
        res = listAppend(a, b);
      then
        res;
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),fn)
      equation 
        res = getMatchingExpsList({e1,e2,e3},fn);
      then
        res;
    case (DAE.ARRAY(array = elts),fn) /* Array */ 
      equation 
        res = getMatchingExpsList(elts,fn);
      then
        res;
    case (DAE.MATRIX(scalar = explst),fn) /* Matrix */ 
      equation 
        flatexplst = Util.listFlatten(explst);
        elst = Util.listMap(flatexplst, Util.tuple21);
        res = getMatchingExpsList(elst,fn);
      then
        res;
    case (DAE.RANGE(exp = e1,expOption = optexp,range = e2),fn) /* Range */ 
      local list<DAE.Exp> e3;
      equation 
        e3 = Util.optionToList(optexp);
        elist = listAppend({e1,e2}, e3);
        res = getMatchingExpsList(elist,fn);
      then
        res;
    case (DAE.TUPLE(PR = exps),fn) /* Tuple */ 
      equation 
        res = getMatchingExpsList(exps,fn);
      then
        res;
    case (DAE.CAST(exp = e),fn)
      equation 
        res = getMatchingExps(e,fn);
      then
        res;
    case (DAE.SIZE(exp = e1,sz = e2),fn) /* Size */ 
      local Option<DAE.Exp> e2;
      equation 
        a = Util.optionToList(e2);
        elist = e1 :: a;
        res = getMatchingExpsList(elist,fn);
      then
        res;

        /* MetaModelica list */
    case (DAE.CONS(_,e1,e2),fn)
      equation
        elist = {e1,e2};
        res = getMatchingExpsList(elist,fn);
      then res;

    case  (DAE.LIST(_,elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;
    
    case (e as DAE.METARECORDCALL(args = elist),fn)
      equation
        res = getMatchingExpsList(elist,fn);
      then res;

    case (DAE.META_TUPLE(elist), fn)
      equation
        res = getMatchingExpsList(elist, fn);
      then res;

   case (DAE.META_OPTION(SOME(e1)), fn)
      equation
        res = getMatchingExps(e1, fn);
      then res;

    case(DAE.ASUB(exp = e1),fn)
      equation
        res = getMatchingExps(e1,fn);
        then
          res;
    
    case(DAE.CREF(_,_),_) then {};
    
    case (DAE.VALUEBLOCK(localDecls = ld,body = body,result = e),fn)
      local
    		list<DAE.Element> ld;
    		list<DAE.Statement> body;
      equation
        exps = DAEUtil.getAllExps(ld);
        exps2 = Algorithm.getAllExpsStmts(body);
        exps = listAppend(exps,exps2);
        res = getMatchingExpsList(e::exps,fn);
      then res;
        
    case (DAE.ICONST(_),_) then {};
    case (DAE.RCONST(_),_) then {};
    case (DAE.BCONST(_),_) then {};
    case (DAE.SCONST(_),_) then {};
    case (DAE.CODE(_,_),_) then {};
    case (DAE.END(),_) then {};
    case (DAE.META_OPTION(NONE),_) then {};
        
    case (e,_)
      equation
        Debug.fprintln("failtrace", "- Codegen.getMatchingExps failed: " +& Exp.printExpStr(e));
      then fail();
        
  end matchcontinue;
end getMatchingExps;

public function getUniontypePaths
"Traverses DAE elements to find all Uniontypes, and return the paths
of all of their records"
  input list<DAE.Element> elements;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue elements
    local
      list<Absyn.Path> paths1;
      list<Absyn.Path> paths2;
      list<DAE.Exp> exps;
      list<DAE.Element> els;
    case elements
      equation
        true = RTOpts.acceptMetaModelicaGrammar();
        paths1 = getUniontypePaths2(elements);
        exps = DAEUtil.getAllExps(elements);
        exps = getMatchingExpsList(exps, matchValueblock);
        els = getDAEDeclsFromValueblocks(exps);
        paths2 = getUniontypePaths2(els);
        outPaths = listAppend(paths1, paths2);
        outPaths = Util.listUnion(outPaths, outPaths); // Remove duplicates
      then outPaths;
    case _
      equation
        false = RTOpts.acceptMetaModelicaGrammar();
      then {};
    case _
      equation
        Debug.fprintln("failtrace", "- Codegen.getMetarecordPaths failed");
      then fail();
  end matchcontinue;
end getUniontypePaths;

protected function getUniontypePaths2
  input list<DAE.Element> elements;
  output list<Absyn.Path> outPaths;
algorithm
  outPaths := matchcontinue elements
    local
      list<Absyn.Path> paths,paths1,paths2;
      list<list<Absyn.Path>> listPaths;
      list<DAE.Element> els,rest;
      list<DAE.Type> tys;
      DAE.Type ft;
    case {} then {};
    case DAE.FUNCTION(dAElist = DAE.DAE(els))::rest
      equation
        paths1 = getUniontypePaths2(els);
        paths2 = getUniontypePaths2(rest);
        paths = listAppend(paths1,paths2);
      then paths;
    case DAE.VAR(ty = ft)::rest
      equation
        tys = Types.getAllInnerTypesOfType(ft, Types.uniontypeFilter);
        listPaths = Util.listMap(tys, Types.getUniontypePaths);
        paths1 = getUniontypePaths2(rest);
        listPaths = paths1::listPaths;
        paths = Util.listFlatten(listPaths);
      then paths;
    case _::rest then getUniontypePaths2(rest);
  end matchcontinue;
end getUniontypePaths2;

protected function getDAEDeclsFromValueblocks
  input list<DAE.Exp> exps;
  output list<DAE.Element> outEls;
algorithm
  outEls := matchcontinue (exps)
    local
      list<DAE.Exp> rest;
      list<DAE.Element> els1,els2;
    case {} then {};
    case DAE.VALUEBLOCK(localDecls = els1)::rest
      equation
        els2 = getDAEDeclsFromValueblocks(rest);
      then listAppend(els1,els2);
    case _::rest then getDAEDeclsFromValueblocks(rest);
  end matchcontinue;
end getDAEDeclsFromValueblocks;

protected function makeCrefExpFromString
  input String str;
  output DAE.Exp exp;
protected
  Absyn.Path path;
  DAE.ComponentRef cref;
algorithm
  path := Absyn.makeIdentPathFromString(str);
  cref := Exp.pathToCref(path);
  exp  := Exp.makeCrefExp(cref, DAE.ET_OTHER);
end makeCrefExpFromString;

end Codegen;
