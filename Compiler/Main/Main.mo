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

encapsulated package Main
" file:        Main.mo
  package:     Main
  description: Modelica main program

  RCS: $Id$

  This is the main program in the Modelica specification.
  It either translates a file given as a command line argument
  or starts a server loop communicating through CORBA or sockets
  (The Win32 implementation only implements CORBA)"

protected import Absyn;
protected import BackendDAE;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import CevalScript;
protected import ClassLoader;
protected import Config;
protected import Corba;
protected import DAE;
protected import DAEDump;
protected import DAEUtil;
//protected import Database;
protected import Debug;
protected import Dump;
protected import DumpGraphviz;
protected import Env;
protected import Error;
protected import ErrorExt;
protected import Flags;
protected import Global;
protected import GlobalScript;
protected import Interactive;
protected import List;
protected import Parser;
protected import Print;
protected import Settings;
protected import SimCode;
protected import SimCodeMain;
protected import Socket;
protected import System;
protected import TplMain;
protected import Util;

protected function serverLoop
"This function is the main loop of the server listening
  to a port which recieves modelica expressions."
  input Boolean continue;
  input Integer inInteger;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable := match (continue,inInteger,inInteractiveSymbolTable)
    local
      Boolean b;
      String str,replystr;
      GlobalScript.SymbolTable newsymb,ressymb,isymb;
      Integer shandle;
    case (false,_,isymb) then isymb;
    case (_,-1,isymb) then fail();
    case (_,shandle,isymb)
      equation
        str = Socket.handlerequest(shandle);
        Debug.fprint(Flags.INTERACTIVE_DUMP, "------- Recieved Data from client -----\n");
        Debug.fprint(Flags.INTERACTIVE_DUMP, str);
        Debug.fprint(Flags.INTERACTIVE_DUMP, "------- End recieved Data-----\n");
        Print.clearBuf();
        (b,replystr,newsymb) = handleCommand(str, isymb) "Print.clearErrorBuf &" ;
        replystr = Util.if_(b, replystr, "quit requested, shutting server down\n");
        Socket.sendreply(shandle, replystr);
        Debug.bcall1(not b, Socket.close, shandle);
        Debug.bcall0(not b, Socket.cleanup);
      then serverLoop(b, shandle, newsymb);
  end match;
end serverLoop;

protected function makeDebugResult
  input Flags.DebugFlag inFlag;
  input String res;
  output String res_1;
algorithm
  res_1 := matchcontinue (inFlag,res)
    local
      String debugstr,res_with_debug,flagstr;
    case (Flags.DEBUG_FLAG(name = flagstr),_)
      equation
        true = Flags.isSet(inFlag);
        debugstr = Print.getString();
        res_with_debug = stringAppendList({res,"\n---DEBUG(",flagstr,")---\n",debugstr,"\n---/DEBUG(",flagstr,")---\n"});
      then res_with_debug;
    case (_,_) then res;
  end matchcontinue;
end makeDebugResult;

protected function parseCommand
  "Helper function to handleCommand. First tries to parse the given command as a
   list of statements, and if that fails tries to parse it as a collection of
   classes. Returns either GlobalScript.Statements or Absyn.Program based on
   which parser succeeds, or neither if a parser error occured."
  input String inCommand;
  output Option<GlobalScript.Statements> outStatements;
  output Option<Absyn.Program> outProgram;
algorithm
  (outStatements, outProgram) := matchcontinue(inCommand)
    local
      GlobalScript.Statements stmts;
      Absyn.Program prog;
      String str;

    case (_)
      equation
        ErrorExt.setCheckpoint("parsestring");
        stmts = Parser.parsestringexp(inCommand, "<interactive>");
        ErrorExt.delCheckpoint("parsestring");
      then
        (SOME(stmts), NONE());

    case (_)
      equation
        ErrorExt.rollBack("parsestring");
        prog = Parser.parsestring(inCommand, "<interactive>");
      then
        (NONE(), SOME(prog));

    else (NONE(), NONE());

  end matchcontinue;
end parseCommand;

protected function handleCommand
  "This function handles the commands in form of strings send to the server.
   If the command is quit, the function returns false, otherwise it sends the
   string to the parse function and returns true."
  input String inCommand;
  input GlobalScript.SymbolTable inSymbolTable;
  output Boolean outContinue;
  output String outResult;
  output GlobalScript.SymbolTable outSymbolTable;
protected
algorithm
  (outContinue, outResult, outSymbolTable) :=
  matchcontinue(inCommand, inSymbolTable)
    local
      Option<GlobalScript.Statements> stmts;
      Option<Absyn.Program> prog;
      GlobalScript.SymbolTable st;
      String result;

    case (_, _)
      equation
        true = Util.strncmp("quit()", inCommand, 6);
      then
        (false, "Ok\n", inSymbolTable);

    else
      equation
        Debug.fcall0(Flags.DUMP, Print.clearBuf);
        Debug.fcall0(Flags.DUMP_GRAPHVIZ, Print.clearBuf);
        (stmts, prog) = parseCommand(inCommand);
        (result, st) =
          handleCommand2(stmts, prog, inCommand, inSymbolTable);
        result = makeDebugResult(Flags.DUMP, result);
        result = makeDebugResult(Flags.DUMP_GRAPHVIZ, result);
      then
        (true, result, st);

  end matchcontinue;
end handleCommand;

protected function handleCommand2
  input Option<GlobalScript.Statements> inStatements;
  input Option<Absyn.Program> inProgram;
  input String inCommand;
  input GlobalScript.SymbolTable inSymbolTable;
  output String outResult;
  output GlobalScript.SymbolTable outSymbolTable;
algorithm
  (outResult, outSymbolTable) :=
  matchcontinue(inStatements, inProgram, inCommand, inSymbolTable)
    local
      GlobalScript.Statements stmts;
      Absyn.Program prog, prog2, ast;
      String result;
      GlobalScript.SymbolTable st;
      list<GlobalScript.Variable> vars;

    // Interactively evaluate an algorithm statement or expression.
    case (SOME(stmts), NONE(), _, _)
      equation
        (result, st) = Interactive.evaluate(stmts, inSymbolTable, false);
      then (result, st);

    // Add a class or function to the interactive symbol table.
    case (NONE(), SOME(prog), _, GlobalScript.SYMBOLTABLE(ast = ast, lstVarVal = vars))
      equation
        prog2 = Interactive.addScope(prog, vars);
        prog2 = Interactive.updateProgram(prog2, ast);
        Debug.fprint(Flags.DUMP, "\n--------------- Parsed program ---------------\n");
        Debug.fcall(Flags.DUMP_GRAPHVIZ, DumpGraphviz.dump, prog2);
        Debug.fcall(Flags.DUMP, Dump.dump, prog2);
        result = makeClassDefResult(prog) "Return vector of toplevel classnames.";
        st = Interactive.setSymbolTableAST(inSymbolTable, prog2);
      then (result, st);

    // A parser error occured in parseCommand, display the error message. This
    // is handled here instead of in parseCommand, since parseCommand does not
    // return a result string.
    case (NONE(), NONE(), _, _)
      equation
        Print.printBuf("Error occurred building AST\n");
        result = Print.getString();
        result = stringAppend(result, "Syntax Error\n");
        result = stringAppend(result, Error.printMessagesStr(false));
      then (result, inSymbolTable);

    // A non-parser error occured, display the error message.
    case (_, _, _, _)
      equation
        true = Util.isSome(inStatements) or Util.isSome(inProgram);
        result = Error.printMessagesStr(false);
      then (result, inSymbolTable);

    else
      equation
        true = Util.isSome(inStatements) or Util.isSome(inProgram);
        Error.addMessage(Error.STACK_OVERFLOW, {inCommand});
      then ("", inSymbolTable);

  end matchcontinue;
end handleCommand2;

protected function makeClassDefResult
"creates a list of classes of the program to be returned from evaluate"
  input Absyn.Program p;
  output String res;
algorithm
  res := match(p)
    local
      list<Absyn.Path> names;
      Absyn.Path scope;
      list<Absyn.Class> cls;

    case(Absyn.PROGRAM(classes=cls,within_=Absyn.WITHIN(scope)))
      equation
        names = List.map(cls,Absyn.className);
        names = List.map1(names,Absyn.joinPaths,scope);
        res = "{" +& stringDelimitList(List.map(names,Absyn.pathString),",") +& "}\n";
      then res;

    case(Absyn.PROGRAM(classes=cls,within_=Absyn.TOP()))
      equation
        names = List.map(cls,Absyn.className);
        res = "{" +& stringDelimitList(List.map(names,Absyn.pathString),",") +& "}\n";
      then res;

  end match;
end makeClassDefResult;

protected function isModelicaFile
"Succeeds if filename ends with .mo or .mof"
  input String inString;
algorithm
  _ := matchcontinue (inString)
    local
      list<String> lst;
      String last,filename;

    case (filename)
      equation
        lst = System.strtok(filename, ".");
        last :: _ = listReverse(lst);
        true = stringEq(last, "mo");
      then
        ();

    case (filename)
      equation
        lst = System.strtok(filename, ".");
        last :: _ = listReverse(lst);
        true = stringEq(last, "mof");
      then
        ();

  end matchcontinue;
end isModelicaFile;

protected function isFlatModelicaFile
"Succeeds if filename ends with .mof"
  input String filename;
protected
  list<String> lst;
  String last;
algorithm
  lst := System.strtok(filename, ".");
  last :: _ := listReverse(lst);
  true := stringEq(last, "mof");
end isFlatModelicaFile;

protected function isModelicaScriptFile
"Succeeds if filname end with .mos"
  input String filename;
protected
  list<String> lst;
  String last;
algorithm
  true := System.regularFileExists(filename);
  lst := System.strtok(filename, ".");
  last :: _ := listReverse(lst);
  true := stringEq(last, "mos");
end isModelicaScriptFile;

protected function isCodegenTemplateFile
"Succeeds if filname end with .tpl"
  input String filename;
protected
  list<String> lst;
  String last;
algorithm
  lst := System.strtok(filename, ".");
  last :: _ := listReverse(lst);
  true := stringEq(last, "tpl");
end isCodegenTemplateFile;

protected function showErrors
  input String errorString;
  input String errorMessages;
algorithm
  _ := matchcontinue(errorString, errorMessages)
    case("", "") then ();
    case(_, "")
      equation
        print(errorString); print("\n");
      then ();
    case("", _)
      equation
        print(errorMessages); print("\n");
      then ();
    case(_, _)
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
 input GlobalScript.SymbolTable inSymTab;
 output GlobalScript.SymbolTable outSymTab;
algorithm
 outSymTab := matchcontinue(inLibs, inSymTab)
   local
     String lib, mp, f;
     list<String> rest;
     Absyn.Program pnew, p;
     list<GlobalScript.InstantiatedClass> ic;
     list<GlobalScript.Variable> iv;
     list<GlobalScript.CompiledCFunction> cf;
     list<GlobalScript.LoadedFile> lf;
     GlobalScript.SymbolTable st, newst;
     Absyn.Path path;

   // no libs or end, return!
   case ({}, st) then st;

   // A .mo-file.
   case (f :: rest, st as GlobalScript.SYMBOLTABLE(p, _, ic, iv, cf, lf))
     equation
       isModelicaFile(f);
       pnew = Parser.parse(f,"UTF-8");
       pnew = Interactive.updateProgram(pnew, p);
       newst = GlobalScript.SYMBOLTABLE(pnew, NONE(), ic, iv, cf, lf);
       newst = loadLibs(rest, newst);
     then
      newst;

   // some libs present
   case (lib::rest, st as GlobalScript.SYMBOLTABLE(p,_,ic,iv,cf,lf))
     equation
       path = parsePathFromString(lib);
       mp = Settings.getModelicaPath(Config.getRunningTestsuite());
       pnew = ClassLoader.loadClass(path, {"default"}, mp, NONE());
       pnew = Interactive.updateProgram(pnew, p);
       newst = GlobalScript.SYMBOLTABLE(pnew,NONE(),ic,iv,cf,lf);
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
"This function invokes the translator on a source file.  The argument should be
  a list with a single file name, with the rest of the list being an optional
  list of libraries and .mo-files if the file is a .mo-file"
  input list<String> inStringLst;
algorithm
  _ := matchcontinue (inStringLst)
    local
      Absyn.Program p, pLibs;
      DAE.DAElist d;
      String s,str,f;
      list<String>  libs;
      Absyn.Path cname;
      Boolean silent,notsilent;
      GlobalScript.Statements stmts;
      GlobalScript.SymbolTable newst, st;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcs;
      list<Absyn.Class> cls;

    // A .mo-file, followed by an optional list of extra .mo-files and libraries.
    // The last class in the first file will be instantiated.
    case (f :: libs)
      equation
        //print("Class to instantiate: " +& Config.classToInstantiate() +& "\n");
        System.realtimeTick(GlobalScript.RT_CLOCK_EXECSTAT_MAIN);
        Debug.execStat("Enter Main",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);
        // Check that it's a .mo-file.
        isModelicaFile(f);
        // Parse the first file.
        (p as Absyn.PROGRAM(classes = cls)) = Parser.parse(f,"UTF-8");
        // Parse libraries and extra mo-files that might have been given at the command line.
        GlobalScript.SYMBOLTABLE(ast = pLibs) = loadLibs(libs, GlobalScript.emptySymboltable);
        // Show any errors that occured during parsing.
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));

        // Merge our program with the possible libs and models from extra .mo-files.
        p = Interactive.updateProgram(pLibs, p);

        Debug.fprint(Flags.DUMP, "\n--------------- Parsed program ---------------\n");
        Debug.fcall(Flags.DUMP_GRAPHVIZ, DumpGraphviz.dump, p);
        Debug.fcall(Flags.DUMP, Dump.dump, p);
        s = Debug.fcallret0(Flags.DUMP, Print.getString, "");
        Debug.fcall(Flags.DUMP,print,s);

        p = transformFlatProgram(p,f);

        Debug.execStat("Parsed file",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);

        // Instantiate the program.
        (cache, env, d, cname) = instantiate(p);

        d = Debug.bcallret3(Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP),DAEUtil.transformationsBeforeBackend,cache,env,d,d);

        funcs = Env.getFunctionTree(cache);

        Print.clearBuf();
        Debug.execStat("Transformations before Dump",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);
        s = DAEDump.dumpStr(d, funcs);
        Debug.execStat("DAEDump done",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);
        Print.printBuf(s);
        Debug.fcall(Flags.DAE_DUMP_GRAPHV, DAEDump.dumpGraphviz, d);
        Debug.execStat("Misc Dump",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);

        // Do any transformations required before going into code generation, e.g. if-equations to expressions.
        d = Debug.bcallret3(boolNot(Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP)),DAEUtil.transformationsBeforeBackend,cache,env,d,d);

        str = Print.getString();
        silent = Config.silent();
        notsilent = boolNot(silent);
        Debug.bcall(notsilent, print, str);
        Debug.execStat("Transformations before backend",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);

        // Run the backend.
        optimizeDae(cache, env, d, p, cname);
        // Show any errors or warnings if there are any!
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
      then ();

    /* Modelica script file .mos */
    case (f::libs)
      equation
        isModelicaScriptFile(f);
        // loading possible libraries given at the command line
        st = loadLibs(libs, GlobalScript.emptySymboltable);

        //System.startTimer();
        //print("\nParseExp");
        // parse our algorithm given in the script
        stmts = Parser.parseexp(f);
        //System.stopTimer();
        //print("\nParseExp: " +& realString(System.getTimerIntervalTime()));

        // are there any errors?
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
        // evaluate statements and print the result to stdout directly
        newst = Interactive.evaluateToStdOut(stmts, st, true);
      then
        ();
    case {f} /* A template file .tpl (in the Susan language)*/
      equation
        isCodegenTemplateFile(f);
        TplMain.main(f);
      then
        ();

    // deal with problems
    case (f::_)
      equation
        false = System.regularFileExists(f);
        print(System.gettext("File does not exist: ")); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
      then
        fail();

    case (f::_)
      equation
        true = System.regularFileExists(f);
        print("Error processing file: "); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
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
    case(_,_) equation
      isFlatModelicaFile(filename);
      outP = Interactive.transformFlatProgram(p);
      then outP;
    case (_,_) then p;
  end matchcontinue;
end transformFlatProgram;

protected function instantiate
  "Translates the Absyn.Program to SCode and instantiates either a given class
   specified by the +i flag on the command line, or the last class in the
   program if no class was specified."
  input Absyn.Program program;
  output Env.Cache cache;
  output Env.Env env;
  output DAE.DAElist dae;
  output Absyn.Path cname;
algorithm
  (cache, env, dae, cname) := matchcontinue(program)
    local
      Env.Cache c;
      Env.Env e;
      DAE.DAElist d;
      Absyn.Path class_path;
      String class_to_instantiate;
      GlobalScript.SymbolTable st;
    case (_)
      equation
        // If no class was explicitly specified, instantiate the last class in
        // the program.
        class_to_instantiate = Config.classToInstantiate();
        true = stringEq(class_to_instantiate,"");
        class_path = Absyn.lastClassname(program);
        st = Interactive.setSymbolTableAST(GlobalScript.emptySymboltable,program);
        (c, e, d, _) = CevalScript.runFrontEnd(Env.emptyCache(),Env.emptyEnv,class_path,st,true);
      then
        (c, e, d, class_path);

    case (_)
      equation
        // If a class to instantiate was given on the command line, instantiate
        // that class.
        class_to_instantiate = Config.classToInstantiate();
        false = stringEq(class_to_instantiate,"");
        class_path = Absyn.stringPath(class_to_instantiate);
        st = Interactive.setSymbolTableAST(GlobalScript.emptySymboltable,program);
        (c, e, d, _) = CevalScript.runFrontEnd(Env.emptyCache(),Env.emptyEnv,class_path,st,true);
      then
        (c, e, d, class_path);
  end matchcontinue;
end instantiate;

protected function optimizeDae
"Run the backend. Used for both parallization and for normal execution."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input DAE.DAElist dae;
  input Absyn.Program ap;
  input Absyn.Path inPath5;
algorithm
  _:=
  matchcontinue (inCache,inEnv,dae,ap,inPath5)
    local
      BackendDAE.BackendDAE dlow,dlow_1;
      Absyn.Path classname;
      Env.Cache cache;
      Env.Env env;
      String description,filenameprefix;

    case (cache,env,_,_,classname)
      equation
        true = Config.simulationCg();
        filenameprefix = Absyn.pathString(classname);
        description = DAEUtil.daeDescription(dae);
        dlow = BackendDAECreate.lower(dae,cache,env,BackendDAE.EXTRA_INFO(description,filenameprefix));
        dlow_1 = BackendDAEUtil.getSolvedSystem(dlow,NONE(),NONE(),NONE(),NONE());
        //modpar(dlow_1);
        Debug.execStat("Lowering Done",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);
        simcodegen(dlow_1,classname,ap,dae);
      then
        ();
    else
      equation
        false = Config.simulationCg() "so main can print error messages" ;
      then ();
  end matchcontinue;
end optimizeDae;

// protected function modpar "The automatic paralellzation module."
//   input BackendDAE.BackendDAE inBackendDAE;
// algorithm
//   _ := matchcontinue inBackendDAE
//     local
//       Integer n,nx,ny,np;
//       BackendDAE.BackendDAE dae;
//       Real l,b,t1,t2,t;
//       String timestr,nps;
//       BackendDAE.StrongComponents comps;
//     case _
//       equation
//         true = 0==Config.noProc() or Flags.isSet(Flags.OPENMP) "If modpar not enabled, nproc = 0, return" ;
//       then
//         ();
//     case (dae as BackendDAE.DAE(eqs={BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))}))
//       equation
//         TaskGraph.buildTaskgraph(dae, comps);
//         TaskGraphExt.dumpGraph("model.viz");
//         l = Config.latency();
//         b = Config.bandwidth();
//         t1 = clock();
//         TaskGraphExt.mergeTasks(l, b);
//         t2 = clock();
//         t = t2 -. t1;
//         timestr = realString(t);
//         print("task merging took ");
//         print(timestr);
//         print(" seconds\n");
//         TaskGraphExt.dumpMergedGraph("merged_model.viz");
//         n = Config.noProc();
//         TaskGraphExt.schedule(n);
//         (nx,ny,np,_,_,_,_,_,_,_,_,_) = BackendDAEUtil.calculateSizes(dae);
//         nps = intString(np);
//         print("=======\nnp =");
//         print(nps);
//         print("=======\n");
//         TaskGraphExt.generateCode(nx, ny, np);
//         print("done\n");
//       then
//         ();
//     else
//       equation
//         Debug.fprint(Flags.FAILTRACE, "-modpar failed\n");
//       then
//         fail();
//   end matchcontinue;
// end modpar;

protected function simcodegen "
  Genereates simulation code using the SimCode module"
  input BackendDAE.BackendDAE inBackendDAE5;
  input Absyn.Path inPath;
  input Absyn.Program inProgram3;
  input DAE.DAElist inDAElist4;
algorithm
  _:=
  matchcontinue (inBackendDAE5,inPath,inProgram3,inDAElist4)
    local
      BackendDAE.BackendDAE dlow;
      String cname_str;
      Absyn.Path classname;
      Absyn.Program ap;
      DAE.DAElist dae;
      SimCode.SimulationSettings simSettings;

    case (dlow,classname,ap,dae) /* classname ass1 ass2 blocks */
      equation
        true = Config.simulationCg();
        false = Config.acceptParModelicaGrammar();
        Print.clearErrorBuf();
        Print.clearBuf();
        cname_str = Absyn.pathString(classname);
        simSettings = SimCodeMain.createSimulationSettings(0.0, 1.0, 500, 1e-6,"dassl","","mat",".*",false,"");
        _ = System.realtimeTock(GlobalScript.RT_CLOCK_BACKEND); // Is this necessary?
        (_,_,_,_,_) = SimCodeMain.generateModelCode(dlow,ap,dae,classname,cname_str,SOME(simSettings),Absyn.FUNCTIONARGS({},{}));
        Debug.execStat("Codegen Done",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);
      then
        ();

     // If accepting parModelica create a slightly different default settings.
     // Temporary solution for now since Intel OpenCL dll calls hang.
     // So use simple Models and call the needed functions.
     case (dlow,classname,ap,dae) /* classname ass1 ass2 blocks */
      equation
        true = Config.simulationCg();
        true = Config.acceptParModelicaGrammar();
        Print.clearErrorBuf();
        Print.clearBuf();
        cname_str = Absyn.pathString(classname);
        simSettings = SimCodeMain.createSimulationSettings(0.0, 1.0, 1, 1e-6,"dassl","","plt",".*",false,"");
        _ = System.realtimeTock(GlobalScript.RT_CLOCK_BACKEND); // Is this necessary?
        (_,_,_,_,_) = SimCodeMain.generateModelCode(dlow,ap,dae,classname,cname_str,SOME(simSettings),Absyn.FUNCTIONARGS({},{}));
        Debug.execStat("Codegen Done",GlobalScript.RT_CLOCK_EXECSTAT_MAIN);
      then
        ();

    /* If not generating simulation code: Succeed so no error messages are printed */
    else
      equation
        false = Config.simulationCg();
      then
        ();
  end matchcontinue;
end simcodegen;

protected function interactivemode
"Initiate the interactive mode using socket communication."
  input GlobalScript.SymbolTable symbolTable;
algorithm
  print("Opening a socket on port " +& intString(29500) +& "\n");
  _ := serverLoop(true, Socket.waitforconnect(29500), symbolTable);
end interactivemode;

protected function interactivemodeCorba
"Initiate the interactive mode using corba communication."
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
algorithm
  _:=
  matchcontinue inInteractiveSymbolTable
   local
     GlobalScript.SymbolTable symbolTable;
    case symbolTable
      equation
        Corba.initialize();
        _ = serverLoopCorba(symbolTable);
      then
        ();
    case symbolTable
      equation
        failure(Corba.initialize());
        Print.printBuf("Failed to initialize Corba! Is another OMC already running?\n");
        Print.printBuf("Exiting!\n");
      then
        ();
  end matchcontinue;
end interactivemodeCorba;


protected function serverLoopCorba
"This function is the main loop of the server for a CORBA impl."
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable := match (inInteractiveSymbolTable)
    local
      Boolean b;
      String str,replystr;
      GlobalScript.SymbolTable newsymb,ressymb,isymb;
    case (isymb)
      equation
        str = Corba.waitForCommand();
        Print.clearBuf();
        (b,replystr,newsymb) = handleCommand(str, isymb);
        Corba.sendreply(Util.if_(b,replystr,"quit requested, shutting server down\n"));
        Debug.bcall0(not b,Corba.close);
        ressymb = Debug.bcallret1(b,serverLoopCorba,newsymb,isymb);
      then ressymb;
  end match;
end serverLoopCorba;

protected function readSettings
" author: x02lucpo
 Checks if 'settings.mos' exist and uses handleCommand with runScript(...) to execute it.
 Checks if '-s <file>.mos' has been
 returns GlobalScript.SymbolTable which is used in the rest of the loop"
  input list<String> inStringLst;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable:=
  matchcontinue (inStringLst)
    local
      list<String> args;
      String str;
      GlobalScript.SymbolTable outSymbolTable;
    case (args)
      equation
        outSymbolTable = GlobalScript.emptySymboltable;
         "" = Util.flagValue("-s",args);
//         this is out-commented because automatically reading settings.mos
//         can make a system bad
//         outSymbolTable = readSettingsFile("settings.mos", GlobalScript.emptySymboltable);
      then
       outSymbolTable;
    case (args)
      equation
        str = Util.flagValue("-s",args);
        str = System.trim(str," \"");
        outSymbolTable = readSettingsFile(str, GlobalScript.emptySymboltable);
      then
       outSymbolTable;
  end matchcontinue;
end readSettings;


protected function readSettingsFile
 input String filePath;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
 outInteractiveSymbolTable :=
  matchcontinue (filePath,inInteractiveSymbolTable)
    local
      String file;
      GlobalScript.SymbolTable inSymbolTable, outSymbolTable;
      String str;
    case (file,inSymbolTable)
      equation
        true = System.regularFileExists(file);
        str = stringAppendList({"runScript(\"",file,"\")"});
        (_,_,outSymbolTable) = handleCommand(str,inSymbolTable);
      then
        outSymbolTable;
    case (file,inSymbolTable)
      equation
        false = System.regularFileExists(file);
      then
        inSymbolTable;
    case (_,inSymbolTable)
      equation
        print("-readSettingsFile another error\n");
      then
        inSymbolTable;
  end matchcontinue;
end readSettingsFile;


public function setWindowsPaths
"@author: adrpo
 set the windows paths for MinGW.
 do some checks on where needed things are present.
 BIG WARNING: if MinGW gcc version from OMDev or OpenModelica/MinGW
              changes you will need to change here!"
  input String inOMHome;
algorithm
  _ := matchcontinue(inOMHome)
    local
      String oldPath,newPath,omHome,omdevPath;

    // check if we have OMDEV set
    case (omHome)
      equation
        _ = System.setEnv("OPENMODELICAHOME",omHome,true);
        omdevPath = Util.makeValueOrDefault(System.readEnv,"OMDEV","");
        // we have something!
        false = stringEq(omdevPath, "");
        // do we have bin?
        true = System.directoryExists(omdevPath +& "\\tools\\mingw\\bin");
        // do we have the correct libexec stuff?
        true = System.directoryExists(omdevPath +& "\\tools\\mingw\\libexec\\gcc\\mingw32\\4.4.0");
        oldPath = System.readEnv("PATH");
        newPath = stringAppendList({omHome,"\\bin;",
                                    omHome,"\\lib;",
                                    omdevPath,"\\tools\\mingw\\bin;",
                                    omdevPath,"\\tools\\mingw\\libexec\\gcc\\mingw32\\4.4.0\\;",
                                    oldPath});
        _ = System.setEnv("PATH",newPath,true);
      then
        ();

    case (omHome)
      equation
        _ = System.setEnv("OPENMODELICAHOME",omHome,true);
        oldPath = System.readEnv("PATH");
        // do we have bin?
        true = System.directoryExists(omHome +& "\\mingw\\bin");
        // do we have the correct libexec stuff?
        true = System.directoryExists(omHome +& "\\mingw\\libexec\\gcc\\mingw32\\4.4.0");
        newPath = stringAppendList({omHome,"\\bin;",
                                    omHome,"\\lib;",
                                    omHome,"\\mingw\\bin;",
                                    omHome,"\\mingw\\libexec\\gcc\\mingw32\\4.4.0\\;",
                                    oldPath});
        _ = System.setEnv("PATH",newPath,true);
      then
        ();

    // do not display anything if +d=disableWindowsPathCheckWarning
    case (omHome)
      equation
        true = Flags.isSet(Flags.DISABLE_WINDOWS_PATH_CHECK_WARNING);
      then
        ();

    else
      equation
        print("We could not find any of:\n");
        print("\t$OPENMODELICAHOME/MinGW/bin and $OPENMODELICAHOME/MinGW/libexec/gcc/mingw32/4.4.0\n");
        print("\t$OMDEV/tools/MinGW/bin and $OMDEV/tools/MinGW/libexec/gcc/mingw32/4.4.0\n");
      then
        ();

  end matchcontinue;
end setWindowsPaths;

protected function setDefaultCC "Reads the enviornment variable CC to change the default CC"
algorithm
  _ := matchcontinue ()
    case ()
      equation
        System.setCCompiler(System.readEnv("CC"));
      then ();
    else ();
  end matchcontinue;
end setDefaultCC;

public function main
"This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> args;
protected
  list<String> args_1;
algorithm
  _ := matchcontinue args
    case _
      equation
        // call GC_init() the first thing we do!
        System.initGarbageCollector();
        Global.initialize();
        System.realtimeTick(GlobalScript.RT_CLOCK_SIMULATE_TOTAL);
        args_1 = Flags.new(args);
        System.gettextInit(Util.if_(Config.getRunningTestsuite(),"C",Flags.getConfigString(Flags.LOCALE_FLAG)));
        setDefaultCC();
        main2(args_1);
      then ();
    else
      equation
        ErrorExt.clearMessages();
        failure(_ = Flags.new(args));
        print(ErrorExt.printMessagesStr(false)); print("\n");
      then fail();
  end matchcontinue;
end main;

protected function main2
"This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> args;
algorithm
  _ := matchcontinue (args)
    local
      String errstr;
      String omhome;
      GlobalScript.SymbolTable symbolTable;

    // Version requested using --version
    case _ // try first to see if we had a version request among flags.
      equation
        true = Config.versionRequest();
        print(Settings.getVersionNr());
        print("\n");
      then ();

    // Setup mingw path only once
    // adrpo: NEVER MOVE THIS CASE FROM HERE OR PUT ANY OTHER CASES BEFORE IT
    //        without asking Adrian.Pop@liu.se
    case _
      equation
        true = "Windows_NT" ==& System.os();
        omhome = Settings.getInstallationDirectoryPath();
        setWindowsPaths(omhome);

        // setup an file database (for in-memory use :memory: as name)
        //Database.open(0, "omc.db");
        //_ = Database.query(0, "create table if not exists Inst(id string not null, value real not null)");
        //_ = Database.query(0, "begin transaction;");
      then
        fail();

    case _
      equation
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        true = Flags.isSet(Flags.INTERACTIVE);
        false = Flags.isSet(Flags.INTERACTIVE_CORBA);
        _ = Settings.getInstallationDirectoryPath();
        symbolTable = readSettings(args);
        interactivemode(symbolTable);
      then ();

    case _
      equation
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        false = Flags.isSet(Flags.INTERACTIVE);
        true = Flags.isSet(Flags.INTERACTIVE_CORBA);
        _ = Settings.getInstallationDirectoryPath();
        symbolTable = readSettings(args);
        interactivemodeCorba(symbolTable);
      then ();

    case _::_
      equation
        false = Flags.isSet(Flags.INTERACTIVE);
        false = Flags.isSet(Flags.INTERACTIVE_CORBA);
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        _ = Settings.getInstallationDirectoryPath();

        // debug_show_depth(2);

        // reset the timer used to calculate
        // cummulative time of some functions
        // search for System.startTimer/System.stopTimer/System.getTimerIntervalTimer
        // System.resetTimer();

        //setGlobalRoot(Global.crefIndex,  ComponentReference.createEmptyCrefMemory());
        //Env.globalCache = fill(Env.emptyCache,1);
        symbolTable = readSettings(args);
        // non of the interactive mode was set, flatten the file
        translateFile(args);
        /*
        errstr = Print.getErrorString();
        Debug.fcall(Flags.ERRORBUF, print, errstr);
        */
        //print("Total time for timer: " +& realString(System.getTimerCummulatedTime()) +& "\n");
        //dbResult = Database.query(0, "end transaction;");
        //dbResult = Database.query(0, "select * from Inst");
      then
        ();

    case _
      equation
        true = System.userIsRoot();
        print(System.gettext("You are trying to run OpenModelica as root.\n"));
        print("This is a very bad idea. Why you ask?\n");
        print("* The socket interface does not authenticate the user.\n");
        print("* OpenModelica allows execution of arbitrary commands.\n");
        print("The good news is there is no reason to run OpenModelica as root.\n");
      then fail();

    case {}
      equation
        false = System.userIsRoot();
        print(Debug.bcallret0(not Config.helpRequest() /* Already printed help */, Flags.printUsage, ""));
      then ();

    case _
      equation
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        _ = Settings.getInstallationDirectoryPath();
        print("# Error encountered! Exiting...\n");
        print("# Please check the error message and the flags.\n");
        errstr = Print.getErrorString();
        Print.printBuf("\n\n----\n\nError buffer:\n\n");
        print(errstr);
        print(ErrorExt.printMessagesStr(false)); print("\n");
      then
        fail();

    case _
      equation
        true = not System.userIsRoot() or Config.getRunningTestsuite();
        failure(_ = Settings.getInstallationDirectoryPath());
        print("Error: OPENMODELICAHOME was not set.\n");
        print("  Read the documentation for instructions on how to set it properly.\n");
        print("  Most OpenModelica release distributions have scripts that set OPENMODELICAHOME for you.\n\n");

        // Functions used by external code that needs to be included for linking
      then fail();
  end matchcontinue;
end main2;

end Main;

