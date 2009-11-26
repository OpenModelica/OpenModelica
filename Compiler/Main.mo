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

package Main
" file:        Main.mo
  package:     Main
  description: Modelica main program

  RCS: $Id$

  This is the main program in the Modelica specification.
  It either translates a file given as a command line argument
  or starts a server loop communicating through CORBA or sockets
  (The Win32 implementation only implements CORBA)"

protected import Absyn;
protected import AbsynDep;
protected import Parser;
protected import Dump;
protected import DumpGraphviz;
protected import SCode;
protected import SCodeUtil;
protected import DAE;
protected import DAEUtil;
protected import DAELow;
protected import Inst;
protected import Interactive;
protected import RTOpts;
protected import Debug;
protected import Socket;
protected import Print;
protected import Corba;
protected import System;
protected import Util;
protected import TaskGraph;
protected import TaskGraphExt;
protected import SimCodegen;
protected import ErrorExt;
protected import Error;
protected import CevalScript;
protected import Env;
protected import Settings;
protected import InstanceHierarchy;
protected import ClassLoader;
protected import Inline;

protected function serverLoop
"function: serverLoop
  This function is the main loop of the server listening
  to a port which recieves modelica expressions."
  input Integer inInteger;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inInteger,inInteractiveSymbolTable)
    local
      String str,replystr;
      Interactive.InteractiveSymbolTable newsymb,ressymb,isymb;
      Integer shandle;
    case (shandle,isymb)
      equation 
        str = Socket.handlerequest(shandle);
        Debug.fprint("interactivedump", "------- Recieved Data from client -----\n");
        Debug.fprint("interactivedump", str);
        Debug.fprint("interactivedump", "------- End recieved Data-----\n");
        Print.clearBuf();
        (true,replystr,newsymb) = handleCommand(str, isymb) "Print.clearErrorBuf &" ;
        Socket.sendreply(shandle, replystr);
        ressymb = serverLoop(shandle, newsymb);
      then
        ressymb;
    case (shandle,isymb)
      equation 
        str = Socket.handlerequest(shandle) "2004-11-27 - adrpo added this part to make the loop deterministic" ;
        Debug.fprint("interactivedump", "------- Recieved Data from client -----\n");
        Debug.fprint("interactivedump", str);
        Debug.fprint("interactivedump", "------- End recieved Data-----\n");
        Print.clearBuf() "Print.clearErrorBuf &" ;
        (false,replystr,newsymb) = handleCommand(str, isymb);
        Print.printBuf("Exiting\n") "2004-11-27 - adrpo added part ends here" ;
        Socket.sendreply(shandle, "quit requested, shutting server down\n");
        Socket.close(shandle);
        Socket.cleanup();
      then
        isymb;
  end matchcontinue;
end serverLoop;

protected function checkClassdef
  input String inString;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inString)
    local
      list<String> clst,clst_1;
      String str_1,str;
      Boolean res;
    case (str) /* Need to check for a whitespace after as well to get the keyword,
	e.g typeOf function would be taken as a type definition otherwise */ 
      equation 
        true = Util.strncmp(" ", str, 1);
        clst = string_list_string_char(str);
        clst_1 = listDelete(clst, 0);
        str_1 = string_char_list_string(clst_1);
        res = checkClassdef(str_1);
      then
        res;
    case str /* Need to check for a whitespace after as well to get the keyword,
	e.g typeOf function would be taken as a type definition otherwise */ 
      equation 
        false = Util.strncmp("end ", str, 4);
        false = Util.strncmp("type ", str, 5);
        false = Util.strncmp("class ", str, 6);
        false = Util.strncmp("model ", str, 6);
        false = Util.strncmp("block ", str, 6);
        false = Util.strncmp("within ", str, 7);
        false = Util.strncmp("record ", str, 7);
        false = Util.strncmp("package ", str, 8);
        false = Util.strncmp("partial ", str, 8);
        false = Util.strncmp("function ", str, 9);
        false = Util.strncmp("connector ", str, 10);
        false = Util.strncmp("encapsulated ", str, 12);
      then
        false;
    case _ then true; 
  end matchcontinue;
end checkClassdef;

protected function makeDebugResult
  input String flagstr;
  input String res;
  output String res_1;
  String debugstr,res_with_debug,res_1;
  Boolean dumpflag;
algorithm 
  debugstr := Print.getString();
  res_with_debug := Util.stringAppendList(
          {res,"\n---DEBUG(",flagstr,")---\n",debugstr,"\n---/DEBUG(",
          flagstr,")---\n"});
  dumpflag := RTOpts.debugFlag(flagstr);
  res_1 := Util.if_(dumpflag, res_with_debug, res);
end makeDebugResult;

protected function handleCommand
"function handleCommand
  This function handles the commands in form of strings send to the server
  If the command is quit, the function returns false, otherwise it sends
  the string to the parse function and returns true."
  input String inString;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  output Boolean outBoolean;
  output String outString;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outBoolean,outString,outInteractiveSymbolTable):=
  matchcontinue (inString,inInteractiveSymbolTable)
    local
      String str,msg,res_1,res,evalstr,expmsg,debugstr;
      Interactive.InteractiveSymbolTable isymb,newisymb;
      Absyn.Program p,p_1,newprog,iprog;
      AbsynDep.Depends aDep;
      list<Interactive.InteractiveVariable> vars_1,vars;
      list<Interactive.CompiledCFunction> cf_1,cf,cf_2;
      list<SCode.Class> a;
      list<Interactive.InstantiatedClass> b;
      Interactive.InteractiveStmts exp;
      list<Interactive.LoadedFile> lf;
    case (str,isymb)
      equation 
        true = Util.strncmp("quit()", str, 6);
      then
        (false,"Ok\n",isymb);
    /* Add a class or function to the interactive symbol table.
	   * If it is a function, type check it.
	   */
    case (str,
    (isymb as Interactive.SYMBOLTABLE(
      ast = iprog,depends=aDep,explodedAst = a,instClsLst = b,
      lstVarVal = vars,compiledFunctions = cf,
      loadedFiles = lf)))
      equation 
        //debug_print("Command: typeCheck", str);
        Debug.fcall0("dump", Print.clearBuf);
        Debug.fcall0("dumpgraphviz", Print.clearBuf);
        Debug.fprint("dump", "\nTrying to parse class definition...\n");
        (p,msg) = Parser.parsestring(str);
        equality(msg = "Ok") "Always succeeds, check msg for errors" ;
        Interactive.typeCheckFunction(p, isymb) "fails here if the string is not \"Ok\"" ;
        p_1 = Interactive.addScope(p, vars);
        vars_1 = Interactive.updateScope(p, vars);
        newprog = Interactive.updateProgram(p_1, iprog);
        // not needed. the functions will be remove by examining
        // build times and files!
        cf_1 = cf; // cf_1 = Interactive.removeCompiledFunctions(p, cf);
        Debug.fprint("dump", "\n--------------- Parsed program ---------------\n");
        Debug.fcall("dumpgraphviz", DumpGraphviz.dump, newprog);
        Debug.fcall("dump", Dump.dump, newprog);
        res_1 = makeClassDefResult(p_1) "return vector of toplevel classnames";
        res_1 = makeDebugResult("dump", res_1);
        res = makeDebugResult("dumpgraphviz", res_1);
      then
        (true,res,Interactive.SYMBOLTABLE(newprog,aDep,a,b,vars_1,cf_1,lf));
    case (str,isymb) /* Interactively evaluate an algorithm statement or expression */ 
      equation 
        //debug_print("Command: don't typeCheck", str);      
        Debug.fcall0("dump", Print.clearBuf);
        Debug.fcall0("dumpgraphviz", Print.clearBuf);
        Debug.fprint("dump", 
          "\nNot a class definition, trying expresion parser\n");
        (exp,msg) = Parser.parsestringexp(str);
        equality(msg = "Ok") "always succeeds, check msg for errors" ;
        (evalstr,newisymb) = Interactive.evaluate(exp, isymb, false);
        Debug.fprint("dump", "\n--------------- Parsed expression ---------------\n");
        Debug.fcall("dump", Dump.dumpIstmt, exp);
        res_1 = makeDebugResult("dump", evalstr);
        res = makeDebugResult("dumpgraphviz", res_1);
      then
        (true,res,newisymb);
    case (str,isymb)
      local Interactive.InteractiveStmts p;
      equation 
        //debug_print("Command: fail", str);      
        Debug.fcall0("failtrace", Print.clearBuf);
        (p,msg) = Parser.parsestring(str);
        (p,expmsg) = Parser.parsestringexp(str);
        failure(equality(msg = "Ok"));
        failure(equality(expmsg = "Ok"));
        Debug.fprint("failtrace", 
          "\nBoth parser and expression parser failed: \n");
        Debug.fprintl("failtrace", {"parser: \n",msg,"\n"});
        Debug.fprintl("failtrace", {"expparser: \n",expmsg,"\n"});
        res = makeDebugResult("failtrace", msg);
      then
        (true,res,isymb);
    case (_,isymb)
      equation 
        Print.printBuf("Error occured building AST\n");
        debugstr = Print.getString();
        str = stringAppend(debugstr, "Syntax Error\n");
      then
        (true,str,isymb);
  end matchcontinue;
end handleCommand;

protected function makeClassDefResult "creates a list of classes of the program to be returned from evaluate"
input Absyn.Program p;
output String res;
algorithm
  res := matchcontinue(p)
  local list<Absyn.Path> names;
    Absyn.Within w;
    Absyn.Path scope;
    list<Absyn.Class> cls;
    case(Absyn.PROGRAM(classes=cls,within_=Absyn.WITHIN(scope))) equation
      names = Util.listMap(cls,Absyn.className);
      names = Util.listMap1(names,Absyn.joinPaths,scope);
      res = "{" +& Util.stringDelimitList(Util.listMap(names,Absyn.pathString),",") +& "}";
    then res;
    case(Absyn.PROGRAM(classes=cls,within_=Absyn.TOP())) equation
      names = Util.listMap(cls,Absyn.className);
      res = "{" +& Util.stringDelimitList(Util.listMap(names,Absyn.pathString),",") +& "}";
    then res;      
  end matchcontinue;
end makeClassDefResult;

protected function isModelicaFile 
"function: isModelicaFile 
  Succeeds if filename ends with .mo or .mof"
  input String inString;
algorithm 
  _:=
  matchcontinue (inString)
    local
      list<String> lst;
      String last,filename;
    case (filename)
      equation 
        lst = System.strtok(filename, ".");
        (last :: _) = listReverse(lst);
        equality(last = "mo");
      then
        ();
    case (filename)
      equation 
        lst = System.strtok(filename, ".");
        (last :: _) = listReverse(lst);
        equality(last = "mof");
      then
        ();
  end matchcontinue;
end isModelicaFile;

protected function isFlatModelicaFile
"function: isFlatModelicaFile
  Succeeds if filename ends with .mof"
  input String filename;
  list<String> lst;
  String last;
algorithm 
  lst := System.strtok(filename, ".");
  (last :: _) := listReverse(lst);
  equality(last := "mof");
end isFlatModelicaFile;

protected function isModelicaScriptFile
"function: isModelicaScriptFile
  Succeeds if filname end with .mos"
  input String filename;
  list<String> lst;
  String last;
algorithm 
  lst := System.strtok(filename, ".");
  (last :: _) := listReverse(lst);
  equality(last := "mos");
end isModelicaScriptFile;

protected function versionRequest
algorithm
  _:= matchcontinue() 
    case () equation
      true = RTOpts.versionRequest();
    then ();
  end matchcontinue;
end versionRequest;

protected function showErrors
  input String errorString;
  input String errorMessages;
algorithm
  _ := matchcontinue(errorString, errorMessages)
    case("", "") then ();
    case(errorString, "")
      equation
        print(errorString); print("\n");
      then ();
    case("", errorMessages)
      equation
        print(errorMessages); print("\n");
      then ();
    case(errorString, errorMessages)
      equation
        print(errorString); print("\n");
        print(errorMessages); print("\n");
      then ();
 end matchcontinue;
end showErrors;

protected function createPathFromStringList
 input list<String> inStringLst; 
 output Absyn.Path path;
algorithm
 path := matchcontinue(inStringLst)
   local
     String strID;
     list<String> rest;
     Absyn.Path p, pDepth;
   
   // we cannot have an empty list!
   case ({}) then fail(); 
     
   // last element in the list
   case ({strID}) then Absyn.IDENT(strID);
     
   // we have some more elements          
   case (strID::rest)
     equation
       pDepth = createPathFromStringList(rest);
       p = Absyn.QUALIFIED(strID, pDepth);
     then
       p;
  end matchcontinue;
end createPathFromStringList;

protected function parsePathFromString
 input String inString; 
 output Absyn.Path path;
algorithm
 path := matchcontinue(inString)
   local
     String str;
     list<String> strLst;
     Absyn.Path p;
     
   case (str)
     equation
        strLst = Util.stringSplitAtChar(str, ".");
        p = createPathFromStringList(strLst);
     then p;
               
   case (str)
     equation
       failure(strLst = Util.stringSplitAtChar(str, "."));
       // no "." present in the string, say is a path!
     then
       Absyn.IDENT(str);
  end matchcontinue;
end parsePathFromString;

protected function loadLibs
 input list<String> inLibs;
 input Interactive.InteractiveSymbolTable inSymTab;
 output Interactive.InteractiveSymbolTable outSymTab;
algorithm
 outSymTab := matchcontinue(inLibs, inSymTab)
   local
     String lib, mp;
     list<String> rest;
     Absyn.Program pnew, p, p_1;
     list<Interactive.InstantiatedClass> ic;
     list<Interactive.InteractiveVariable> iv;
     list<Interactive.CompiledCFunction> cf;
     list<SCode.Class> sp;
     list<Interactive.LoadedFile> lf;
     AbsynDep.Depends aDep;
     Interactive.InteractiveSymbolTable st, newst;
     Absyn.Path path;
          
   // no libs or end, return!
   case ({}, st) then st; 
   // some libs present
   case (lib::rest, st as Interactive.SYMBOLTABLE(p,aDep,sp,ic,iv,cf,lf))
     equation
       path = parsePathFromString(lib);
       mp = Settings.getModelicaPath();
       pnew = ClassLoader.loadClass(path, mp);
       pnew = Interactive.updateProgram(pnew, p);
       newst = Interactive.SYMBOLTABLE(pnew,aDep,sp,ic,iv,cf,lf);
       newst = loadLibs(rest, newst); // load the remaining
     then
       newst;
   // problem with the libs, ignore!
   case (lib::rest, st)
     equation
       Print.printErrorBuf("Failed to load library: " +& lib +& " ... ignoring!\n");
       newst = loadLibs(rest, st); // load the remaining
     then
       newst;
  end matchcontinue;
end loadLibs;

protected function translateFile 
"function: translateFile
  This function invokes the translator on a source file.  The
  argument should be a list with a single file name."
  input list<String> inStringLst;
algorithm 
  _:=
  matchcontinue (inStringLst)
    local
      Absyn.Program p, pLibs;
      list<SCode.Class> scode;
      DAE.DAElist d_2,d_1,d;
      String s,str,f,res;
      list<String> lst, libs;
      Absyn.Path cname;
      Boolean silent,notsilent;
      Interactive.InteractiveStmts stmts;
      Interactive.InteractiveSymbolTable newst, st;
      Env.Cache cache;
      Env.Env env;
      
      /* Version requested using --version*/
    case (_) // try first to see if we had a version request among flags.
      equation
        versionRequest();
        print(Settings.getVersionNr());
      then ();
        
    case (f::{}) /* A Modelica file .mo  */ 
      local 
        String s, lastClassName;
        Absyn.Path lastClassPath;
        AbsynDep.Depends dep;
        list<Absyn.Class> cls;
      equation
        Debug.fcall("execstat",print, "*** Main -> entering at time: " +& realString(clock()) +& "\n" );
        isModelicaFile(f);        
        // parse our file!
        p = Parser.parse(f);
        // show parse errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
        
        Debug.fprint("dump", "\n--------------- Parsed program ---------------\n");
        Debug.fcall("dumpgraphviz", DumpGraphviz.dump, p);
        Debug.fcall("dump", Dump.dump, p);
        s = Print.getString();
        Debug.fcall("dump",print,s);
        
        p = transformFlatProgram(p,f);
        p = Interactive.getTotalProgramLastClass(p);        
        
        Debug.fprint("info", "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---elaborating\n");
        scode = SCodeUtil.translateAbsyn2SCode(p);
        Debug.fprint("info", "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---instantiating\n");
        //print(" Inst.Instantiate " +& realString(clock()) +&"\n");
        Debug.fcall("execstat",print, "*** Main -> To instantiate at time: " +& realString(clock()) +& "\n" );
        (cache,_,d_1,_) = Inst.instantiate(Env.emptyCache(),
                                            InstanceHierarchy.emptyInstanceHierarchy,
                                            scode);
        Debug.fcall("execstat",print, "*** Main -> done instantiation at time: " +& realString(clock()) +& "\n" );
        //print(" Inst.Instantiate " +& realString(clock()) +&" DONE\n");
        Debug.fprint("beforefixmodout", "Explicit part:\n");
        Debug.fcall("beforefixmodout", DAEUtil.dumpDebug, d_1);
        d = fixModelicaOutput(d_1);
        Print.clearBuf();
        Debug.fprint("info", "---dumping\n");
        Debug.fcall("execstat",print, "*** Main -> dumping dae: " +& realString(clock()) +& "\n" );
        s = Debug.fcallret("flatmodelica", DAEUtil.dumpStr, d, "");
        Debug.fcall("execstat",print, "*** Main -> done dumping dae: " +& realString(clock()) +& "\n" );
        Debug.fcall("flatmodelica", Print.printBuf, s);
        Debug.fcall("execstat",print, "*** Main -> dumping dae2 : " +& realString(clock()) +& "\n" );
        s = Debug.fcallret("none", DAEUtil.dumpStr, d, "");
        Debug.fcall("execstat",print, "*** Main -> done dumping dae2 : " +& realString(clock()) +& "\n" );        
        Debug.fcall("none", Print.printBuf, s);
        Debug.fcall("daedump", DAEUtil.dump, d);
        Debug.fcall("daedump2", DAEUtil.dump2, d);
        Debug.fcall("daedumpdebug", DAEUtil.dumpDebug, d);
        Debug.fcall("daedumpgraphv", DAEUtil.dumpGraphviz, d);
        // transform if equations to if expression before going into code generation
        d = DAEUtil.transformIfEqToExpr(d);
        cname = Absyn.lastClassname(p);
        str = Print.getString();
        silent = RTOpts.silent();
        notsilent = boolNot(silent);
        Debug.bcall(notsilent, print, str);
        Debug.fcall("execstat",print, "*** Main -> To optimizedae at time: " +& realString(clock()) +& "\n" );
        optimizeDae(cache, Env.emptyEnv, scode, p, d, d, cname);
      then
        ();        
       
    case (f::(libs as _::_)) /* A Modelica file .mo possibly followed by a list of libraries to load! */ 
      local 
        String s, lastClassName;
        Absyn.Path lastClassPath;
        AbsynDep.Depends dep;
        list<Absyn.Class> cls;
      equation
        Debug.fcall("execstat",print, "*** Main -> entering at time: " +& realString(clock()) +& "\n" );
        isModelicaFile(f);        
        // loading possible libraries given at the command line
        Interactive.SYMBOLTABLE(ast = pLibs) = loadLibs(libs, Interactive.emptySymboltable);
        // parse our file!
        (p as Absyn.PROGRAM(cls, _, _)) = Parser.parse(f);
        // show parse errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());

        // get the name of the last class in the program
        Absyn.CLASS(name=lastClassName) = Util.listLast(cls);
        lastClassPath = Absyn.IDENT(lastClassName);

        p = Interactive.updateProgram(p, pLibs); // merge our program with possible libs

        Debug.fprint("dump", "\n--------------- Parsed program ---------------\n");
        Debug.fcall("dumpgraphviz", DumpGraphviz.dump, p);
        Debug.fcall("dump", Dump.dump, p);
        s = Print.getString();
        Debug.fcall("dump",print,s);
        p = transformFlatProgram(p,f);
                
        p = Interactive.getTotalProgram(lastClassPath, p);        
        
        Debug.fprint("info", "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---elaborating\n");
        scode = SCodeUtil.translateAbsyn2SCode(p);
        Debug.fprint("info", "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---instantiating\n");
        //print(" Inst.Instantiate " +& realString(clock()) +&"\n");
        Debug.fcall("execstat",print, "*** Main -> To instantiate at time: " +& realString(clock()) +& "\n" );
        (cache,env,_,d_1) = Inst.instantiateClass(Env.emptyCache(),
                                            InstanceHierarchy.emptyInstanceHierarchy,
                                            scode,
                                            lastClassPath);
        Debug.fcall("execstat",print, "*** Main -> done instantiation at time: " +& realString(clock()) +& "\n" );
        //print(" Inst.Instantiate " +& realString(clock()) +&" DONE\n");
        Debug.fprint("beforefixmodout", "Explicit part:\n");
        Debug.fcall("beforefixmodout", DAEUtil.dumpDebug, d_1);
        d = fixModelicaOutput(d_1);
        Print.clearBuf();
        Debug.fprint("info", "---dumping\n");
        Debug.fcall("execstat",print, "*** Main -> dumping dae: " +& realString(clock()) +& "\n" );
        s = Debug.fcallret("flatmodelica", DAEUtil.dumpStr, d, "");
        Debug.fcall("execstat",print, "*** Main -> done dumping dae: " +& realString(clock()) +& "\n" );
        Debug.fcall("flatmodelica", Print.printBuf, s);
        Debug.fcall("execstat",print, "*** Main -> dumping dae2 : " +& realString(clock()) +& "\n" );
        s = Debug.fcallret("none", DAEUtil.dumpStr, d, "");
        Debug.fcall("execstat",print, "*** Main -> done dumping dae2 : " +& realString(clock()) +& "\n" );        
        Debug.fcall("none", Print.printBuf, s);
        Debug.fcall("daedump", DAEUtil.dump, d);
        Debug.fcall("daedump2", DAEUtil.dump2, d);
        Debug.fcall("daedumpdebug", DAEUtil.dumpDebug, d);
        Debug.fcall("daedumpgraphv", DAEUtil.dumpGraphviz, d);
        // transform if equations to if expression before going into code generation
        d = DAEUtil.transformIfEqToExpr(d);
        cname = Absyn.lastClassname(p);
        str = Print.getString();
        silent = RTOpts.silent();
        notsilent = boolNot(silent);
        Debug.bcall(notsilent, print, str);
        Debug.fcall("execstat",print, "*** Main -> To optimizedae at time: " +& realString(clock()) +& "\n" );
        optimizeDae(cache, env, scode, p, d, d, cname);
      then
        ();
        
    /* Modelica script file .mos */
    case (f::libs)  
      equation 
        isModelicaScriptFile(f);
        // loading possible libraries given at the command line
        st = loadLibs(libs, Interactive.emptySymboltable);
        // parse our algorithm given in the script        
        stmts = Parser.parseexp(f);
        // are there any errors?
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
        (res,newst) = Interactive.evaluate(stmts, st, true);
        print(res);
      then
        ();
        
    // deal with problems 
    case (f::_)
      local Integer r;
      equation
        r = System.regularFileExists(f);
        (r > 0) = true;  //could not find file
        print("File does not exist: "); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
      then
        fail();
        
    case (f::_)
      local Integer r;
      equation
        r = System.regularFileExists(f);
        (r == 0) = true;  //found file but could not process
        print("Error processing file: "); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
      then
        fail();
  end matchcontinue;
end translateFile;

protected function transformFlatProgram
"Transforms the variables in equations to have the same format as for variables,
i.e. a.b[3].c[2] becomes CREF_IDENT(\"a.b[3].c\",[INDEX(ICONST(2))])"
input Absyn.Program p;
input String filename;
output Absyn.Program outP;
algorithm
  outP := matchcontinue(p,filename)
    case(p,filename) equation
      isFlatModelicaFile(filename);
      outP = Interactive.transformFlatProgram(p);
      then outP;
    case(p,filename) then p;
  end matchcontinue;
end transformFlatProgram;

protected function runBackendQ
"function: runBackendQ
  Determine if backend, i.e. BLT etc. should be run.
  It should be run if either \"blt\" flag is set or if
  parallelization is enabled by giving flag -n=<no proc.>"
  output Boolean res_1;
  Boolean bltflag,sim_cg,par,res,res_1;
  Integer n;
algorithm 
  bltflag := RTOpts.debugFlag("blt");
  sim_cg := RTOpts.simulationCg();
  n := RTOpts.noProc();
  par := (n > 0);
  res := boolOr(bltflag, par);
  res_1 := boolOr(res, sim_cg);
end runBackendQ;

protected function optimizeDae
"function: optimizeDae
  Run the backend. Used for both parallization and for normal execution."
  input Env.Cache inCache;
  input Env.Env inEnv;  
  input SCode.Program inProgram1;
  input Absyn.Program inProgram2;
  input DAE.DAElist inDAElist3;
  input DAE.DAElist inDAElist4;
  input Absyn.Path inPath5;
algorithm 
  _:=
  matchcontinue (inCache,inEnv,inProgram1,inProgram2,inDAElist3,inDAElist4,inPath5)
    local
      DAELow.DAELow dlow,dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] v1,v2;
      list<list<Integer>> comps;
      list<SCode.Class> p;
      Absyn.Program ap;
      DAE.DAElist dae,daeimpl;
      Absyn.Path classname;
      Env.Cache cache;
      Env.Env env;
    case (cache,env,p,ap,dae,daeimpl,classname)
      local String str;
      equation 
        true = runBackendQ();
        Debug.fcall("execstat",print, "*** Main -> To lower dae at time: " +& realString(clock()) +& "\n" );
        dlow = DAELow.lower(dae, /* add dummy state if needed */ true, /* simplify */ true);        
        Debug.fcall("dumpdaelow", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("execstat",print, "*** Main -> To run matching at time: " +& realString(clock()) +& "\n" );
        (v1,v2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, (DAELow.INDEX_REDUCTION(), DAELow.EXACT(), DAELow.REMOVE_SIMPLE_EQN()));
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("bltdump", DAELow.dump, dlow_1);
        Debug.fcall("bltdump", DAELow.dumpMatching, v1);
        (comps) = DAELow.strongComponents(m, mT, v1, v2);
        /**
         * TODO: Activate this when we call it from a command like +d=... 
         * 
         * 
         * str = Absyn.pathString(classname);
         * str = DAELow.unparseStr(dlow, comps, v1, v2, false,str);
         * //Debug.fcall("flat", DAELow.unparseStr,dlow, comps, v1, v2, true);
        **/
        // Debug.fcall("eqnsizedump",DAELow.dumpComponentSizes,comps);
        Debug.fcall("bltdump", DAELow.dumpComponents, comps);
				str = DAELow.dumpComponentsGraphStr(DAELow.systemSize(dlow_1),m,mT,v1,v2);
				Debug.fcall("dumpcompgraph",print,str);
        modpar(dlow_1, v1, v2, comps);
        Debug.fcall("execstat",print, "*** Main -> To simcodegen at time: " +& realString(clock()) +& "\n" );
        simcodegen(cache,env,classname, p, ap, daeimpl, dlow_1, v1, v2, m, mT, comps);
      then
        ();
    case (_,_,_,_,_,_,_)
      equation 
        true = runBackendQ() "so main can print error messages" ;
      then
        fail();
    case (_,_,_,_,_,_,_) /* If not running backend. */ 
      equation 
        false = runBackendQ();
      then
        ();
  end matchcontinue;
end optimizeDae;

protected function modpar
"function: modpar
  The automatic paralellzation module."
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
algorithm 
  _:=
  matchcontinue (inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4)
    local
      Integer n,nx,ny,np;
      DAELow.DAELow indexed_dae,indexed_dae_1,dae;
      Real l,b,t1,t2,time;
      String timestr,nps;
      Integer[:] ass1,ass2;
      list<list<Integer>> comps;
    case (_,_,_,_)
      equation 
        n = RTOpts.noProc() "If modpar not enabled, nproc = 0, return" ;
        (n == 0) = true;
      then
        ();
    case (dae,ass1,ass2,comps)
      equation 
        indexed_dae = DAELow.translateDae(dae,NONE);
        indexed_dae_1 = DAELow.calculateValues(indexed_dae);
        TaskGraph.buildTaskgraph(indexed_dae_1, ass1, ass2, comps);
        TaskGraphExt.dumpGraph("model.viz");
        l = RTOpts.latency();
        b = RTOpts.bandwidth();
        t1 = clock();
        TaskGraphExt.mergeTasks(l, b);
        t2 = clock();
        time = t2 -. t1;
        timestr = realString(time);
        print("task merging took ");
        print(timestr);
        print(" seconds\n");
        TaskGraphExt.dumpMergedGraph("merged_model.viz");
        n = RTOpts.noProc();
        TaskGraphExt.schedule(n);
        (nx,ny,np,_,_,_,_) = DAELow.calculateSizes(indexed_dae_1);
        nps = intString(np);
        print("=======\nnp =");
        print(nps);
        print("=======\n");
        TaskGraphExt.generateCode(nx, ny, np);
        print("done\n");
      then
        ();
    case (_,_,_,_)
      equation 
        Debug.fprint("failtrace", "-modpar failed\n");
      then
        fail();
  end matchcontinue;
end modpar;

protected function simcodegen
"function simcodegen
  Genereates simulation code using the SimCodegen module"
  input Env.Cache inCache;
  input Env.Env inEnv;
  input Absyn.Path inPath1;
  input SCode.Program inProgram2;
  input Absyn.Program inProgram3;
  input DAE.DAElist inDAElist4;
  input DAELow.DAELow inDAELow5;
  input Integer[:] inIntegerArray6;
  input Integer[:] inIntegerArray7;
  input DAELow.IncidenceMatrix inIncidenceMatrix8;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT9;
  input list<list<Integer>> inIntegerLstLst10;
algorithm 
  _:=
  matchcontinue (inCache,inEnv,inPath1,inProgram2,inProgram3,inDAElist4,inDAELow5,inIntegerArray6,inIntegerArray7,inIncidenceMatrix8,inIncidenceMatrixT9,inIntegerLstLst10)
    local
      DAELow.DAELow indexed_dlow,indexed_dlow_1,dlow;
      String cname_str,filename,funcfilename,init_filename,makefilename,file_dir;
      Absyn.ComponentRef a_cref;
      list<String> libs;
      Absyn.Path classname;
      list<SCode.Class> p;
      Absyn.Program ap;
      DAE.DAElist dae;
      Integer[:] ass1,ass2;
      list<Integer>[:] m,mt;
      list<list<Integer>> comps;
      Env.Cache cache;
      Env.Env env;
      list<DAE.Element> funcelems;
    case (cache,env,classname,p,ap,dae,dlow,ass1,ass2,m,mt,comps) /* classname ass1 ass2 blocks */ 
      equation 
        Debug.fcall("execstat",print, "*** Main -> entering simcodgen: " +& realString(clock()) +& "\n" );
        true = RTOpts.simulationCg();
        Print.clearErrorBuf();
        Print.clearBuf();
        Debug.fcall("execstat",print, "*** Main -> simcodgen -> translateDae: " +& realString(clock()) +& "\n" );
        indexed_dlow = DAELow.translateDae(dlow,NONE);
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        Debug.fcall("dumpindxdae", DAELow.dump, indexed_dlow_1);       
        cname_str = Absyn.pathString(classname);
        filename = Util.stringAppendList({cname_str,".cpp"});
        funcfilename = Util.stringAppendList({cname_str,"_functions.cpp"});
        init_filename = Util.stringAppendList({cname_str,"_init.txt"});
        makefilename = Util.stringAppendList({cname_str,".makefile"});
        a_cref = Absyn.pathToCref(classname);
        file_dir = CevalScript.getFileDir(a_cref, ap);
        Debug.fcall("execstat",print, "*** Main -> simcodgen -> generateFunctions: " +& realString(clock()) +& "\n" );
        (cache,libs,funcelems,indexed_dlow_1,dae) = SimCodegen.generateFunctions(cache, env, p, dae, indexed_dlow_1, classname, funcfilename);
        indexed_dlow_1 = Inline.inlineCalls(funcelems,indexed_dlow_1);
        SimCodegen.generateSimulationCode(dae, indexed_dlow_1, ass1, ass2, m, mt, comps, classname, filename, funcfilename,file_dir);
        SimCodegen.generateInitData(indexed_dlow_1, classname, cname_str, init_filename, 0.0, 1.0, 500.0,1e-6,"dassl","");
        SimCodegen.generateMakefile(makefilename, cname_str, libs, file_dir);
      then
        ();
    case (_,_,_,_,_,_,_,_,_,_,_,_) /* If something above failed. fail so Main can print errors */ 
      equation 
        true = RTOpts.simulationCg();
      then
        fail();
    case (_,_,_,_,_,_,_,_,_,_,_,_) /* If not generating simulation code */ 
      equation 
        false = RTOpts.simulationCg();
      then
        ();
  end matchcontinue;
end simcodegen;

protected function runModparQ
"function: runModparQ
  Returns true if parallelization should be run."
  output Boolean res;
  Integer n;
algorithm 
  n := RTOpts.noProc();
  res := (n > 0);
end runModparQ;

protected function fixModelicaOutput
"function: fixModelicaOutput
  Transform the dae, replacing dots with underscore in variables and
  equations."
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inDAElist)
    local
      list<DAE.Element> dae_1,dae;
      DAE.DAElist d;
    case DAE.DAE(elementLst = dae)
      equation 
        true = RTOpts.modelicaOutput();
        dae_1 = Inst.initVarsModelicaOutput(dae);
      then
        DAE.DAE(dae_1);
    case ((d as DAE.DAE(elementLst = dae)))
      equation 
        false = RTOpts.modelicaOutput();
      then
        d;
  end matchcontinue;
end fixModelicaOutput;

protected function interactivemode
"function: interactivemode
  Initiate the interactive mode using socket communication."
  input list<String> inStringLst;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
algorithm 
  _:=
  matchcontinue (inStringLst,inInteractiveSymbolTable)
    local Integer shandle;
     Interactive.InteractiveSymbolTable symbolTable;
    case (_,symbolTable)
      equation 
        shandle = Socket.waitforconnect(29500);
        _ = serverLoop(shandle, symbolTable);
      then
        ();
  end matchcontinue;
end interactivemode;

protected function interactivemodeCorba
"function: interactivemodeCorba
  Initiate the interactive mode using corba communication."
  input list<String> inStringLst;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
algorithm 
  _:=
  matchcontinue (inStringLst,inInteractiveSymbolTable)
   local 
     Interactive.InteractiveSymbolTable symbolTable;
    case (_,symbolTable)
      equation 
        Corba.initialize();
        _ = serverLoopCorba(symbolTable);
      then
        ();
    case (_,symbolTable)
      equation 
        failure(Corba.initialize());
        Print.printBuf("Failed to initialize Corba! Is another OMC already running?\n");
        Print.printBuf("Exiting!\n");        
      then
        ();
  end matchcontinue;
end interactivemodeCorba;


protected function serverLoopCorba
"function: serverLoopCorba
  This function is the main loop of the server for a CORBA impl."
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inInteractiveSymbolTable)
    local
      String str,replystr;
      Interactive.InteractiveSymbolTable newsymb,ressymb,isymb;
    case (isymb)
      equation 
        str = Corba.waitForCommand();
        Print.clearBuf();
        (true,replystr,newsymb) = handleCommand(str, isymb);
        Corba.sendreply(replystr);
        ressymb = serverLoopCorba(newsymb);
      then
        ressymb;
    case (isymb)
      equation 
        str = Corba.waitForCommand() "start - 2005-06-12 - adrpo added this part to make the loop deterministic" ;
        Print.clearBuf();
        (false,replystr,newsymb) = handleCommand(str, isymb);
        Print.printBuf("Exiting\n") "end - 2005-06-12 -" ;
        Corba.sendreply("quit requested, shutting server down\n");
        Corba.close();
      then
        isymb;
  end matchcontinue;
end serverLoopCorba;


protected function readSettings
"function: readSettings
 author: x02lucpo
 Checks if 'settings.mos' exist and uses handleCommand with runScript(...) to execute it.
 Checks if '-s <file>.mos' has been
 returns Interactive.InteractiveSymbolTable which is used in the rest of the loop"
  input list<String> inStringLst;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable:=
  matchcontinue (inStringLst)
    local
      list<String> args;
      String str;
      Interactive.InteractiveSymbolTable outSymbolTable;
    case (args)
      equation
        outSymbolTable = Interactive.emptySymboltable;
         "" = Util.flagValue("-s",args);
//         this is out-commented because automatically reading settings.mos
//         can make a system bad
//         outSymbolTable = readSettingsFile("settings.mos", Interactive.emptySymboltable);
      then
       outSymbolTable;
    case (args)
      equation
        str = Util.flagValue("-s",args);
        str = System.trim(str," \"");
        outSymbolTable = readSettingsFile(str, Interactive.emptySymboltable);
      then
       outSymbolTable;
  end matchcontinue;
end readSettings;


protected function readSettingsFile
 input String filePath;
  input Interactive.InteractiveSymbolTable inInteractiveSymbolTable;
  output Interactive.InteractiveSymbolTable outInteractiveSymbolTable;
algorithm
 outInteractiveSymbolTable :=
  matchcontinue (filePath,inInteractiveSymbolTable)
    local
      String file;
      Interactive.InteractiveSymbolTable inSymbolTable, outSymbolTable;
      String str;
    case (file,inSymbolTable)
      equation
        0 = System.regularFileExists(file);
        str = Util.stringAppendList({"runScript(\"",file,"\")"});
        (_,_,outSymbolTable) = handleCommand(str,inSymbolTable);
      then
        outSymbolTable;
    case (file,inSymbolTable)
       local Integer rest;
      equation
        rest = System.regularFileExists(file);
        (rest > 0) = true;  //could not found file
      then
        inSymbolTable;
    case (_,inSymbolTable)
      equation
        print("-readSettingsFile another error\n");
      then
        inSymbolTable;
  end matchcontinue;
end readSettingsFile;

function printUsage
algorithm
  print("OpenModelica Compiler version: "); print(Settings.getVersionNr()); print("\n");
  print("http://www.OpenModelica.org\n");
  print("Please check the System Guide for full information about flags.\n");
  print("Usage: omc [-runtimeOptions +omcOptions] (Model.mo | Model.mof | Script.mos) [Libraries] \n");
  print("* Libraries: Fully qualified names of libraries to load before processing Model or Script.\n");
  print("*            The libraries should be separated by spaces: Lib1 Lib2 ... LibN.\n");
  print("* runtimeOptions: call omc -help for seeing runtime options\n");
  print("* omcOptions:\n");
  print("\t++v|+version               will print the version and exit\n");
  print("\t+s Model.mo                will generate code for Model:\n");
  print("\t                           Model.cpp           the model C++ code\n");
  print("\t                           Model_functions.cpp the model functions C++ code\n");
  print("\t                           Model.makefile      the makefile to compile the model.\n");
  print("\t                           Model_init.txt      the initial values for parameters\n");
  print("\t+d=interactive             will start omc as a server listening on the socket interface\n");
  print("\t+d=interactiveCorba        will start omc as a server listening on the Corba interface\n");
  print("\t+c=corbaName               works togheter with +d=interactiveCorba;\n");
  print("\t                           will start omc with a different Corba session name; \n");
  print("\t                           this way multiple omc compilers can be started\n");
  print("\t+s                         generate simulation code\n");
  print("\t+annotationVersion=1.x     what annotation version should we use\n");
  print("\t                           accept 1.x or 2.x (default) or 3.x\n"); 
  print("\t+noSimplify                do not simplify expressions (default is to simplify)\n");
  print("\t+q                         run in quiet mode, output nothing\n");
  print("\t+g=MetaModelica            accept MetaModelica grammar and semantics\n");
  print("\t+showErrorMessages         show error messages while they happen; default to no. \n");  
  print("\t+d=flags                   set debug flags: \n");  
  print("\t+d=bltdump                 dump the blt form\n");
  print("\t+d=failtrace               prints a lot of error messages; use if your model fails; see also below.\n");
  print("\t+d=parsedump               dump the parsing tree\n");
  print("\t+d=parseonly               will only parse the given file and exit\n");    
  print("\t+d=dynload                 display debug information about dynamic loading of compiled functions\n");
  print("\t+d=nogen                   do not use the dynamic loading.\n");
  print("\t+d=usedep                  use dependency analysis to speed up the compilation. [experimental].\n");
  print("\t                           default is to not use the dependency analysis.\n");
  print("\t+d=noevalfunc              do not use the function interpreter, uses dynamic loading instead.\n");
  print("\t                           default is to use the function interpreter.\n"); 
  print("* Examples:\n");
  print("\tomc Model.mo               will produce flattened Model on standard output\n");  
  print("\tomc Model.mof              will produce flattened Model on standard output\n");
  print("\tomc Script.mos             will run the commands from Script.mos\n");
  print("\tomc Model.mo Modelica      will first load the Modelica library and then produce \n");
  print("\t                           flattened Model on standard output\n");  
  print("\t*.mo (Modelica files) \n");
  print("\t*.mof (Flat Modelica files) \n");
  print("\t*.mos (Modelica Script files) \n");
end printUsage;

public function main 
"function: main
  This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> inStringLst;
algorithm 
  _:= matchcontinue (inStringLst)
    local
      String ver_str,errstr;
      list<String> args_1,args;
      Boolean ismode,icmode,imode,imode_1;
      String s,str;
      Interactive.InteractiveSymbolTable symbolTable;
    case args as _::_
      equation 
        args_1 = RTOpts.args(args);
        
        // we need this as we get the arguments in reverse from RTOpts.args 
        args_1 = listReverse(args_1); 
        
        //Env.globalCache = fill(Env.emptyCache,1);
        symbolTable = readSettings(args);
        ismode = RTOpts.debugFlag("interactive");
        icmode = RTOpts.debugFlag("interactiveCorba");
        imode = boolOr(ismode, icmode);
        imode_1 = boolNot(imode);
        // see if the interactive Socket mode is active
        Debug.bcall2(ismode, interactivemode, args_1,symbolTable);
        // see if the interactive Corba mode is active
        Debug.bcall2(icmode, interactivemodeCorba, args_1,symbolTable);
        // non of the interactive mode was set, flatten the file
        Debug.bcall(imode_1, translateFile, args_1);
        /*
        errstr = Print.getErrorString();
        Debug.fcall("errorbuf", print, errstr);
        */
      then
        ();
    case args as _::_
      equation
        failure(args_1 = RTOpts.args(args));
        printUsage();
      then ();
    case {}
      equation
        printUsage();
      then ();        
    case _
      equation 
        print("# Error encountered! Exiting...\n");
        print("# Please check the error message and the flags.\n");
        errstr = Print.getErrorString();
        Print.printBuf("\n\n----\n\nError buffer:\n\n");
        print(errstr);
        print(ErrorExt.printMessagesStr()); print("\n");
      then
        fail();
  end matchcontinue;
end main;
end Main;

