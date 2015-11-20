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

encapsulated package Main
" file:        Main.mo
  package:     Main
  description: Modelica main program

  RCS: $Id$

  This is the main program in the Modelica specification.
  It either translates a file given as a command line argument
  or starts a server loop communicating through CORBA or sockets
  (The Win32 implementation only implements CORBA)"

protected
import Absyn;
import BackendDAE;
import BackendDAECreate;
import BackendDAEUtil;
import CevalScript;
import CevalScriptBackend;
import ClockIndexes;
import Config;
import Corba;
import DAE;
import DAEDump;
import DAEUtil;
import Debug;
import Dump;
import DumpGraphviz;
import FCore;
import FGraph;
import FGraphStream;
import Error;
import ErrorExt;
import Flags;
import GC;
import Global;
import GlobalScript;
import GlobalScriptUtil;
import Interactive;
import List;
import Parser;
import Print;
import Settings;
import SimCode;
import SimCodeMain;
import SimCodeFunctionUtil;
import Socket;
import StackOverflow;
import System;
import TplMain;
import Util;

protected function serverLoop
"This function is the main loop of the server listening
  to a port which recieves modelica expressions."
  input Boolean cont;
  input Integer inInteger;
  input GlobalScript.SymbolTable inInteractiveSymbolTable;
  output GlobalScript.SymbolTable outInteractiveSymbolTable;
algorithm
  outInteractiveSymbolTable := match (cont,inInteger,inInteractiveSymbolTable)
    local
      Boolean b;
      String str,replystr;
      GlobalScript.SymbolTable newsymb,ressymb,isymb;
      Integer shandle;
    case (false,_,isymb) then isymb;
    case (_,-1,_) then fail();
    case (_,shandle,isymb)
      equation
        str = Socket.handlerequest(shandle);
        if Flags.isSet(Flags.INTERACTIVE_DUMP) then
          Debug.trace("------- Recieved Data from client -----\n");
          Debug.trace(str);
          Debug.trace("------- End recieved Data-----\n");
        end if;
        (b,replystr,newsymb) = handleCommand(str, isymb) "Print.clearErrorBuf &" ;
        replystr = if b then replystr else "quit requested, shutting server down\n";
        Socket.sendreply(shandle, replystr);
        if not b then
          Socket.close(shandle);
          Socket.cleanup();
        end if;
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
    else res;
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

public function handleCommand
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
  Print.clearBuf();

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
        (stmts, prog) = parseCommand(inCommand);
        (result, st) = handleCommand2(stmts, prog, inCommand, inSymbolTable);
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
  matchcontinue(inStatements, inProgram, inSymbolTable)
    local
      GlobalScript.Statements stmts;
      Absyn.Program prog, prog2, ast;
      String result;
      GlobalScript.SymbolTable st;
      list<GlobalScript.Variable> vars;

    // Interactively evaluate an algorithm statement or expression.
    case (SOME(stmts), NONE(), _)
      equation
        (result, st) = Interactive.evaluate(stmts, inSymbolTable, false);
      then (result, st);

    // Add a class or function to the interactive symbol table.
    case (NONE(), SOME(prog), GlobalScript.SYMBOLTABLE(ast = ast, lstVarVal = vars))
      equation
        prog2 = Interactive.addScope(prog, vars);
        prog2 = Interactive.updateProgram(prog2, ast);
        if Flags.isSet(Flags.DUMP) then
          Debug.trace("\n--------------- Parsed program ---------------\n");
          Dump.dump(prog2);
        end if;
        if Flags.isSet(Flags.DUMP_GRAPHVIZ) then
          DumpGraphviz.dump(prog2);
        end if;
        result = makeClassDefResult(prog) "Return vector of toplevel classnames.";
        st = GlobalScriptUtil.setSymbolTableAST(inSymbolTable, prog2);
      then (result, st);

    // A parser error occured in parseCommand, display the error message. This
    // is handled here instead of in parseCommand, since parseCommand does not
    // return a result string.
    case (NONE(), NONE(), _)
      equation
        Print.printBuf("Error occurred building AST\n");
        result = Print.getString();
        result = stringAppend(result, "Syntax Error\n");
        result = stringAppend(result, Error.printMessagesStr(false));
      then (result, inSymbolTable);

    // A non-parser error occured, display the error message.
    case (_, _, _)
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
        res = "{" + stringDelimitList(list(Absyn.pathString(n) for n in names),",") + "}\n";
      then res;

    case(Absyn.PROGRAM(classes=cls,within_=Absyn.TOP()))
      equation
        names = List.map(cls,Absyn.className);
        res = "{" + stringDelimitList(list(Absyn.pathString(n) for n in names),",") + "}\n";
      then res;

  end match;
end makeClassDefResult;

protected function isModelicaFile
  "Succeeds if filename ends with .mo or .mof"
  input String inFilename;
  output Boolean outIsModelicaFile;
protected
  list<String> lst;
  String file_ext;
algorithm
  lst := System.strtok(inFilename, ".");

  if listEmpty(lst) then
    outIsModelicaFile := false;
  else
    file_ext := List.last(lst);
    outIsModelicaFile := file_ext == "mo" or file_ext == "mof";
  end if;
end isModelicaFile;

protected function isEmptyOrFirstIsModelicaFile
  input list<String> libs;
algorithm
  _ := match libs
    local
      String f;
    case {} then ();
    case f::_ equation true = isModelicaFile(f); then ();
  end match;
end isEmptyOrFirstIsModelicaFile;

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
  if errorString <> "" then
    print(errorString); print("\n");
  end if;

  if errorMessages <> "" then
    print(errorMessages); print("\n");
  end if;
end showErrors;

protected function loadLib
  input String inLib;
  input GlobalScript.SymbolTable inSymTab;
  output GlobalScript.SymbolTable outSymTab;
protected
  Boolean is_modelica_file;
algorithm
  is_modelica_file := isModelicaFile(inLib);

  outSymTab := matchcontinue(is_modelica_file)
    local
      String lib, mp;
      list<String> rest;
      Absyn.Program pnew, p;
      list<GlobalScript.InstantiatedClass> ic;
      list<GlobalScript.Variable> iv;
      list<GlobalScript.CompiledCFunction> cf;
      list<GlobalScript.LoadedFile> lf;
      GlobalScript.SymbolTable st, newst;
      Absyn.Path path;

    // A .mo-file.
    case true
      equation
        pnew = Parser.parse(inLib, "UTF-8");
        p = GlobalScriptUtil.getSymbolTableAST(inSymTab);
        pnew = Interactive.updateProgram(pnew, p);
        newst = GlobalScriptUtil.setSymbolTableAST(inSymTab, pnew);
      then
       newst;

    // some libs present
    case false
      equation
        path = Absyn.stringPath(inLib);
        mp = Settings.getModelicaPath(Config.getRunningTestsuite());
        p = GlobalScriptUtil.getSymbolTableAST(inSymTab);
        (pnew, true) = CevalScript.loadModel({(path, {"default"})}, mp, p, true, true, true, false);
        newst = GlobalScriptUtil.setSymbolTableAST(inSymTab, pnew);
      then
        newst;

    // problem with the libs, ignore!
    case false
      equation
        Print.printErrorBuf("Failed to load library: " + inLib + "!\n");
      then
        fail();

    case true
      equation
        Print.printErrorBuf("Failed to parse file: " + inLib + "!\n");
      then
        fail();

  end matchcontinue;
end loadLib;

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
      FCore.Cache cache;
      FCore.Graph env;
      DAE.FunctionTree funcs;
      list<Absyn.Class> cls;

    // A .mo-file, followed by an optional list of extra .mo-files and libraries.
    // The last class in the first file will be instantiated.
    case (libs)
      equation
        //print("Class to instantiate: " + Config.classToInstantiate() + "\n");
        isEmptyOrFirstIsModelicaFile(libs);
        System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT);
        System.realtimeTick(ClockIndexes.RT_CLOCK_EXECSTAT_CUMULATIVE);
        // Parse libraries and extra mo-files that might have been given at the command line.
        GlobalScript.SYMBOLTABLE(ast = p) = List.fold(libs, loadLib, GlobalScript.emptySymboltable);
        // Show any errors that occured during parsing.
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));

        if Flags.isSet(Flags.DUMP) then
          Debug.trace("\n--------------- Parsed program ---------------\n");
          Dump.dump(p);
          print(Print.getString());
        end if;
        if Flags.isSet(Flags.DUMP_GRAPHVIZ) then
          DumpGraphviz.dump(p);
        end if;

        SimCodeFunctionUtil.execStat("Parsed file");

        // Instantiate the program.
        (cache, env, d, cname) = instantiate(p);

        d = if Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP) then DAEUtil.transformationsBeforeBackend(cache,env,d) else d;

        funcs = FCore.getFunctionTree(cache);

        Print.clearBuf();
        SimCodeFunctionUtil.execStat("Transformations before Dump");
        s = DAEDump.dumpStr(d, funcs);
        SimCodeFunctionUtil.execStat("DAEDump done");
        Print.printBuf(s);
        if Flags.isSet(Flags.DAE_DUMP_GRAPHV) then
          DAEDump.dumpGraphviz(d);
        end if;
        SimCodeFunctionUtil.execStat("Misc Dump");

        // Do any transformations required before going into code generation, e.g. if-equations to expressions.
        d = if boolNot(Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP)) then DAEUtil.transformationsBeforeBackend(cache,env,d) else  d;

        if not Config.silent() then
          print(Print.getString());
        end if;
        SimCodeFunctionUtil.execStat("Transformations before backend");

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
        st = List.fold(libs, loadLib, GlobalScript.emptySymboltable);

        //System.startTimer();
        //print("\nParseExp");
        // parse our algorithm given in the script
        stmts = Parser.parseexp(f);
        //System.stopTimer();
        //print("\nParseExp: " + realString(System.getTimerIntervalTime()));

        // are there any errors?
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
        // evaluate statements and print the result to stdout directly
        _ = Interactive.evaluateToStdOut(stmts, st, true);
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
      algorithm
        if System.regularFileExists(f) then
          print("Error processing file: ");
        else
          print(System.gettext("File does not exist: "));
        end if;

        print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
      then
        fail();

  end matchcontinue;
end translateFile;

protected function instantiate
  "Translates the Absyn.Program to SCode and instantiates either a given class
   specified by the +i flag on the command line, or the last class in the
   program if no class was specified."
  input Absyn.Program program;
  output FCore.Cache cache;
  output FCore.Graph env;
  output DAE.DAElist dae;
  output Absyn.Path cname;
protected
  String cls;
  GlobalScript.SymbolTable st;
algorithm
  cls := Config.classToInstantiate();
  // If no class was explicitly specified, instantiate the last class in the
  // program. Otherwise, instantiate the given class name.
  cname := if stringLength(cls) == 0 then Absyn.lastClassname(program) else Absyn.stringPath(cls);
  st := GlobalScriptUtil.setSymbolTableAST(GlobalScript.emptySymboltable, program);
  (cache, env, dae) := CevalScriptBackend.runFrontEnd(FCore.emptyCache(), FGraph.empty(), cname, st, true);
end instantiate;

protected function optimizeDae
"Run the backend. Used for both parallization and for normal execution."
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input DAE.DAElist dae;
  input Absyn.Program ap;
  input Absyn.Path inClassName;
protected
  BackendDAE.ExtraInfo info;
  BackendDAE.BackendDAE dlow;
  BackendDAE.BackendDAE initDAE;
  Boolean useHomotopy "true if homotopy(...) is used during initialization";
  list<BackendDAE.Equation> removedInitialEquationLst;
  list<BackendDAE.Var> primaryParameters "already sorted";
  list<BackendDAE.Var> allPrimaryParameters "already sorted";
algorithm
  if Config.simulationCg() then
    info := BackendDAE.EXTRA_INFO(DAEUtil.daeDescription(dae), Absyn.pathString(inClassName));
    dlow := BackendDAECreate.lower(dae, inCache, inEnv, info);
    (dlow, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters) := BackendDAEUtil.getSolvedSystem(dlow, "");
    simcodegen(dlow, initDAE, useHomotopy, removedInitialEquationLst, primaryParameters, allPrimaryParameters, inClassName, ap);
  end if;
end optimizeDae;

protected function simcodegen "
  Genereates simulation code using the SimCode module"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Boolean inUseHomotopy "true if homotopy(...) is used during initialization";
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input list<BackendDAE.Var> inPrimaryParameters "already sorted";
  input list<BackendDAE.Var> inAllPrimaryParameters "already sorted";
  input Absyn.Path inClassName;
  input Absyn.Program inProgram;
protected
  String cname;
  SimCode.SimulationSettings sim_settings;
  Integer intervals;
algorithm
  if Config.simulationCg() then
    Print.clearErrorBuf();
    Print.clearBuf();
    cname := Absyn.pathString(inClassName);

    // If accepting parModelica create a slightly different default settings.
    // Temporary solution for now since Intel OpenCL dll calls hang.
    sim_settings := if Config.acceptParModelicaGrammar() then
      SimCodeMain.createSimulationSettings(0.0, 1.0, 1, 1e-6, "dassl", "", "plt", ".*", "") else
      SimCodeMain.createSimulationSettings(0.0, 1.0, 500, 1e-6, "dassl", "", "mat", ".*", "");

    System.realtimeTock(ClockIndexes.RT_CLOCK_BACKEND); // Is this necessary?
    SimCodeMain.generateModelCode(inBackendDAE, inInitDAE, inUseHomotopy, inRemovedInitialEquationLst, inPrimaryParameters, inAllPrimaryParameters, inProgram, inClassName, cname, SOME(sim_settings), Absyn.FUNCTIONARGS({}, {}));

    SimCodeFunctionUtil.execStat("Codegen Done");
  end if;
end simcodegen;

protected function interactivemode
"Initiate the interactive mode using socket communication."
  input GlobalScript.SymbolTable symbolTable;
algorithm
  print("Opening a socket on port " + intString(29500) + "\n");
  serverLoop(true, Socket.waitforconnect(29500), symbolTable);
end interactivemode;

protected function interactivemodeCorba
"Initiate the interactive mode using corba communication."
  input GlobalScript.SymbolTable inArguments;
algorithm
  try
    Corba.initialize();
    serverLoopCorba(inArguments);
  else
    Print.printBuf("Failed to initialize Corba! Is another OMC already running?\n");
    Print.printBuf("Exiting!\n");
  end try;
end interactivemodeCorba;

protected function serverLoopCorba
"This function is the main loop of the server for a CORBA impl."
  input GlobalScript.SymbolTable inSettings;
  output GlobalScript.SymbolTable outSettings;
protected
  String str, reply_str;
  GlobalScript.SymbolTable settings;
  Boolean cont;
algorithm
  str := Corba.waitForCommand();
  Print.clearBuf();
  (cont, reply_str, settings) := handleCommand(str, inSettings);

  if cont then
    Corba.sendreply(reply_str);
    outSettings := serverLoopCorba(settings);
  else
    Corba.sendreply("quit requested, shutting server down\n");
    Corba.close();
    outSettings := inSettings;
  end if;
end serverLoopCorba;

public function readSettings
  " author: x02lucpo
   Checks if 'settings.mos' exist and uses handleCommand with runScript(...) to execute it.
   Checks if '-s <file>.mos' has been
   returns GlobalScript.SymbolTable which is used in the rest of the loop"
  input list<String> inArguments;
  output GlobalScript.SymbolTable outSettings;
protected
  String settings_file;
algorithm
  settings_file := Util.flagValue("-s", inArguments);

  if settings_file == "" then
    outSettings := GlobalScript.emptySymboltable;
  else
    settings_file := System.trim(settings_file, " \"");
    outSettings := readSettingsFile(settings_file, GlobalScript.emptySymboltable);
  end if;
end readSettings;


protected function readSettingsFile
  input String filePath;
  input GlobalScript.SymbolTable inSettings;
  output GlobalScript.SymbolTable outSettings;
protected
  String command;
algorithm
  if System.regularFileExists(filePath) then
    command := "runScript(\"" + filePath + "\")";
    (_, _, outSettings) := handleCommand(command, inSettings);
  else
    outSettings := inSettings;
  end if;
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
        System.setEnv("OPENMODELICAHOME",omHome,true);
        omdevPath = Util.makeValueOrDefault(System.readEnv,"OMDEV","");
        // we have something!
        false = stringEq(omdevPath, "");
        // do we have bin?
        true = System.directoryExists(omdevPath + "\\tools\\mingw\\bin");
        // do we have the correct libexec stuff?
        true = System.directoryExists(omdevPath + "\\tools\\mingw\\libexec\\gcc\\mingw32\\4.4.0");
        oldPath = System.readEnv("PATH");
        newPath = stringAppendList({omHome,"\\bin;",
                                    omHome,"\\lib;",
                                    omdevPath,"\\tools\\mingw\\bin;",
                                    omdevPath,"\\tools\\mingw\\libexec\\gcc\\mingw32\\4.4.0\\;",
                                    oldPath});
        System.setEnv("PATH",newPath,true);
      then ();

    case (omHome)
      equation
        System.setEnv("OPENMODELICAHOME",omHome,true);
        oldPath = System.readEnv("PATH");
        // do we have bin?
        true = System.directoryExists(omHome + "\\mingw\\bin");
        // do we have the correct libexec stuff?
        true = System.directoryExists(omHome + "\\mingw\\libexec\\gcc\\mingw32\\4.4.0");
        newPath = stringAppendList({omHome,"\\bin;",
                                    omHome,"\\lib;",
                                    omHome,"\\mingw\\bin;",
                                    omHome,"\\mingw\\libexec\\gcc\\mingw32\\4.4.0\\;",
                                    oldPath});
        System.setEnv("PATH",newPath,true);
      then ();

    // do not display anything if +d=disableWindowsPathCheckWarning
    case (_)
      equation
        true = Flags.isSet(Flags.DISABLE_WINDOWS_PATH_CHECK_WARNING);
      then ();

    else
      equation
        print("We could not find any of:\n");
        print("\t"+inOMHome+"/MinGW/bin and "+inOMHome+"/MinGW/libexec/gcc/mingw32/4.4.0\n");
        print("\t$OMDEV/tools/MinGW/bin and $OMDEV/tools/MinGW/libexec/gcc/mingw32/4.4.0\n");
      then ();

  end matchcontinue;
end setWindowsPaths;

protected function setDefaultCC "Reads the environment variable CC to change the default CC"
algorithm
  try
    System.setCCompiler(System.readEnv("CC"));
  else
  end try;
end setDefaultCC;

public function init
  input list<String> args;
  output list<String> args_1;
algorithm
  // set glib G_SLICE to always-malloc as is rummored to be better for Boehm GC
  System.setEnv("G_SLICE", "always-malloc", true);
  // call GC_init() the first thing we do!
  System.initGarbageCollector();
  // Experimentally found to make the testsuite pass on asap.openmodelica.org.
  // 150M for Windows, 300M for others makes the GC try to unmap less and so it crashes less.
  // Disabling unmap is another alternative that seems to work well (but could cause the memory consumption to not be released, and requires manually calling collect and unmap
  if true then
    GC.setForceUnmapOnGcollect(if System.os() == "Windows_NT" then true else false);
  else
    GC.expandHeap(if System.os() == "Windows_NT"
                      then 1024*1024*150
                      else 1024*1024*300);
  end if;
  Global.initialize();
  ErrorExt.registerModelicaFormatError();
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
  args_1 := Flags.new(args);
  System.gettextInit(if Config.getRunningTestsuite() then "C" else Flags.getConfigString(Flags.LOCALE_FLAG));
  setDefaultCC();
end init;

public function main
  "This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
   start the translation."
  input list<String> args;
protected
  list<String> args_1;
  GC.ProfStats stats;
algorithm
  try
  try
    args_1 := init(args);
    if Flags.isSet(Flags.GC_PROF) then
      print(GC.profStatsStr(GC.getProfStats(), head="GC stats after initialization:") + "\n");
    end if;
    main2(args_1);
  else
    ErrorExt.clearMessages();
    failure(_ := Flags.new(args));
    print(ErrorExt.printMessagesStr(false)); print("\n");
    fail();
  end try;
  if Flags.isSet(Flags.GC_PROF) then
    print(GC.profStatsStr(GC.getProfStats(), head="GC stats at end of program:") + "\n");
  end if;
  else
    print("Stack overflow detected and was not caught.\nSend us a bug report at https://trac.openmodelica.org/OpenModelica/newticket\n    Include the following trace:\n");
    for s in StackOverflow.readableStacktraceMessages() loop
      print(s);
      print("\n");
    end for;
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
end main;

protected function main2
  "This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
   start the translation."
  input list<String> args;
algorithm
  // Version requested using --version.
  if Config.versionRequest() then
    print(Settings.getVersionNr() + "\n");
    return;
  end if;

  // Don't allow running omc as root due to security risks.
  if System.userIsRoot() and (Flags.isSet(Flags.INTERACTIVE) or Flags.isSet(Flags.INTERACTIVE_CORBA)) then
    Error.addMessage(Error.ROOT_USER_INTERACTIVE, {});
    print(ErrorExt.printMessagesStr(false));
    fail();
  end if;

  // Setup mingw path only once
  // adrpo: NEVER MOVE THIS CASE FROM HERE OR PUT ANY OTHER CASES BEFORE IT
  //        without asking Adrian.Pop@liu.se
  if System.os() == "Windows_NT" then
    setWindowsPaths(Settings.getInstallationDirectoryPath());
  end if;

  try
    Settings.getInstallationDirectoryPath();

    if Flags.isSet(Flags.INTERACTIVE) then
      interactivemode(readSettings(args));
    elseif Flags.isSet(Flags.INTERACTIVE_CORBA) then
      interactivemodeCorba(readSettings(args));
    else // No interactive flag given, try to flatten the file.
      readSettings(args);
      FGraphStream.start();
      translateFile(args);
      FGraphStream.finish();
    end if;
  else // Something went wrong, print an appropriate error.
    // OMC called with no arguments, print usage information and quit.
    if listEmpty(args) and Config.classToInstantiate()=="" then
      if not Config.helpRequest() then
        print(Flags.printUsage());
      end if;
      return;
    end if;

    try
      Settings.getInstallationDirectoryPath();
      print("# Error encountered! Exiting...\n");
      print("# Please check the error message and the flags.\n");
      Print.printBuf("\n\n----\n\nError buffer:\n\n");
      print(Print.getErrorString());
      print(ErrorExt.printMessagesStr(false)); print("\n");
      FGraphStream.finish();
    else
      print("Error: OPENMODELICAHOME was not set.\n");
      print("  Read the documentation for instructions on how to set it properly.\n");
      print("  Most OpenModelica release distributions have scripts that set OPENMODELICAHOME for you.\n\n");
    end try;
    fail();
  end try;
end main2;

annotation(__OpenModelica_Interface="backend");
end Main;

