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


  This is the main program in the Modelica specification.
  It either translates a file given as a command line argument
  or starts a server loop communicating through CORBA or sockets
  (The Win32 implementation only implements CORBA)"

protected
import Absyn;
import Autoconf;
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
import ExecStat.{execStat,execStatReset};
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
import Socket;
import StackOverflow;
import SymbolTable;
import System;
import TplMain;
import Util;
import ZeroMQ;

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
  output Boolean outContinue;
  output String outResult;
protected
  Option<GlobalScript.Statements> stmts;
  Option<Absyn.Program> prog;
algorithm
  Print.clearBuf();

  if Util.strncmp("quit()", inCommand, 6) then
    outContinue := false;
    outResult := "Ok\n";
  else
    outContinue := true;

    (stmts, prog) := parseCommand(inCommand);
    outResult := handleCommand2(stmts, prog, inCommand);
    outResult := makeDebugResult(Flags.DUMP, outResult);
    outResult := makeDebugResult(Flags.DUMP_GRAPHVIZ, outResult);
  end if;
end handleCommand;

protected function handleCommand2
  input Option<GlobalScript.Statements> inStatements;
  input Option<Absyn.Program> inProgram;
  input String inCommand;
  output String outResult;
algorithm
  outResult := matchcontinue(inStatements, inProgram)
    local
      GlobalScript.Statements stmts;
      Absyn.Program prog, prog2, ast;
      String result;
      list<GlobalScript.Variable> vars;
      SymbolTable table;

    // Interactively evaluate an algorithm statement or expression.
    case (SOME(stmts), NONE())
      equation
        result = Interactive.evaluate(stmts, false);
      then result;

    // Add a class or function to the interactive symbol table.
    case (NONE(), SOME(prog))
      equation
        table = SymbolTable.get();
        ast = table.ast;
        vars = table.vars;
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
        SymbolTable.setAbsyn(prog2);
      then result;

    // A parser error occured in parseCommand, display the error message. This
    // is handled here instead of in parseCommand, since parseCommand does not
    // return a result string.
    case (NONE(), NONE())
      equation
        Print.printBuf("Error occurred building AST\n");
        result = Print.getString();
        result = stringAppend(result, "Syntax Error\n");
        result = stringAppend(result, Error.printMessagesStr(false));
      then result;

    // A non-parser error occured, display the error message.
    case (_, _)
      equation
        true = Util.isSome(inStatements) or Util.isSome(inProgram);
        result = Error.printMessagesStr(false);
      then result;

    else
      equation
        true = Util.isSome(inStatements) or Util.isSome(inProgram);
        Error.addMessage(Error.STACK_OVERFLOW, {inCommand});
      then "";

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
protected
  Boolean is_modelica_file;
algorithm
  is_modelica_file := isModelicaFile(inLib);
  _ := matchcontinue(is_modelica_file)
    local
      String lib, mp;
      list<String> rest;
      Absyn.Program pnew, p;
      Absyn.Path path;

    // A .mo-file.
    case true
      equation
        pnew = Parser.parse(inLib, "UTF-8");
        p = SymbolTable.getAbsyn();
        pnew = Interactive.mergeProgram(pnew, p);
        SymbolTable.setAbsyn(pnew);
      then ();

    // some libs present
    case false
      equation
        path = Absyn.stringPath(inLib);
        mp = Settings.getModelicaPath(Config.getRunningTestsuite());
        p = SymbolTable.getAbsyn();
        (pnew, true) = CevalScript.loadModel({(path, {"default"}, false)}, mp, p, true, true, true, false);
        SymbolTable.setAbsyn(pnew);
      then ();

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
      FCore.Cache cache;
      FCore.Graph env;
      DAE.FunctionTree funcs;
      list<Absyn.Class> cls;

    // A .mo-file, followed by an optional list of extra .mo-files and libraries.
    // The last class in the first file will be instantiated.
    case (libs)
      algorithm
        //print("Class to instantiate: " + Config.classToInstantiate() + "\n");
        isEmptyOrFirstIsModelicaFile(libs);
        execStatReset();
        // Parse libraries and extra mo-files that might have been given at the command line.
        for lib in libs loop
          loadLib(lib);
        end for;
        // Show any errors that occured during parsing.
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));

        if Flags.isSet(Flags.DUMP) then
          Debug.trace("\n--------------- Parsed program ---------------\n");
          Dump.dump(SymbolTable.getAbsyn());
          print(Print.getString());
        end if;
        if Flags.isSet(Flags.DUMP_GRAPHVIZ) then
          DumpGraphviz.dump(SymbolTable.getAbsyn());
        end if;

        execStat("Parsed file");

        // Instantiate the program.
        (cache, env, d, cname) := instantiate();
        p := SymbolTable.getAbsyn();

        d := if Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP) then DAEUtil.transformationsBeforeBackend(cache,env,d) else d;

        funcs := FCore.getFunctionTree(cache);

        Print.clearBuf();
        execStat("Transformations before Dump");
        s := if Config.silent() then "" else DAEDump.dumpStr(d, funcs);
        execStat("DAEDump done");
        Print.printBuf(s);
        if Flags.isSet(Flags.DAE_DUMP_GRAPHV) then
          DAEDump.dumpGraphviz(d);
        end if;
        execStat("Misc Dump");

        // Do any transformations required before going into code generation, e.g. if-equations to expressions.
        d := if boolNot(Flags.isSet(Flags.TRANSFORMS_BEFORE_DUMP)) then DAEUtil.transformationsBeforeBackend(cache,env,d) else  d;

        if not Config.silent() then
          print(Print.getString());
        end if;
        execStat("Transformations before backend");

        // Run the backend.
        optimizeDae(cache, env, d, p, cname);
        // Show any errors or warnings if there are any!
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
      then ();

    /* Modelica script file .mos */
    case (f::libs)
      algorithm
        isModelicaScriptFile(f);
        // loading possible libraries given at the command line
        for lib in libs loop
          loadLib(lib);
        end for;

        //System.startTimer();
        //print("\nParseExp");
        // parse our algorithm given in the script
        stmts := Parser.parseexp(f);
        //System.stopTimer();
        //print("\nParseExp: " + realString(System.getTimerIntervalTime()));

        // are there any errors?
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr(false));
        // evaluate statements and print the result to stdout directly
        Interactive.evaluateToStdOut(stmts, true);
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
  output FCore.Cache cache;
  output FCore.Graph env;
  output DAE.DAElist dae;
  output Absyn.Path cname;
protected
  String cls;
algorithm
  cls := Config.classToInstantiate();
  // If no class was explicitly specified, instantiate the last class in the
  // program. Otherwise, instantiate the given class name.
  cname := if stringEmpty(cls) then Absyn.lastClassname(SymbolTable.getAbsyn()) else Absyn.stringPath(cls);
  (cache, env, SOME(dae)) := CevalScriptBackend.runFrontEnd(FCore.emptyCache(), FGraph.empty(), cname, true);
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
  Option<BackendDAE.BackendDAE> initDAE_lambda0;
  Option<BackendDAE.InlineData> inlineData;
  list<BackendDAE.Equation> removedInitialEquationLst;
algorithm
  if Config.simulationCg() then
    info := BackendDAE.EXTRA_INFO(DAEUtil.daeDescription(dae), Absyn.pathString(inClassName));
    dlow := BackendDAECreate.lower(dae, inCache, inEnv, info);
    (dlow, initDAE, initDAE_lambda0, inlineData, removedInitialEquationLst) := BackendDAEUtil.getSolvedSystem(dlow, "");
    simcodegen(dlow, initDAE, initDAE_lambda0, inlineData, removedInitialEquationLst, inClassName, ap);
  end if;
end optimizeDae;

protected function simcodegen "
  Genereates simulation code using the SimCode module"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Option<BackendDAE.BackendDAE> inInitDAE_lambda0;
  input Option<BackendDAE.InlineData> inInlineData;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
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
    SimCodeMain.generateModelCode(inBackendDAE, inInitDAE, inInitDAE_lambda0, inInlineData, inRemovedInitialEquationLst, inProgram, inClassName, cname, SOME(sim_settings), Absyn.FUNCTIONARGS({}, {}));

    execStat("Codegen Done");
  end if;
end simcodegen;

protected function interactivemode
"Initiate the interactive mode using socket communication."
protected
  Integer shandle;
  Boolean b;
  String str,replystr;
algorithm
  shandle := Socket.waitforconnect(29500);
  if shandle == -1 then
    fail();
  end if;
  while true loop
    str := Socket.handlerequest(shandle);
    if Flags.isSet(Flags.INTERACTIVE_DUMP) then
      Debug.trace("------- Recieved Data from client -----\n");
      Debug.trace(str);
      Debug.trace("------- End recieved Data-----\n");
    end if;
    (b,replystr) := handleCommand(str) "Print.clearErrorBuf &" ;
    replystr := if b then replystr else "quit requested, shutting server down\n";
    Socket.sendreply(shandle, replystr);
    if not b then
      Socket.close(shandle);
      Socket.cleanup();
      break;
    end if;
  end while;
end interactivemode;

protected function interactivemodeCorba
"Initiate the interactive mode using corba communication."
algorithm
  try
    Corba.initialize();
    serverLoopCorba();
  else
    Print.printBuf("Failed to initialize Corba! Is another OMC already running?\n");
    Print.printBuf("Exiting!\n");
  end try;
end interactivemodeCorba;

protected function interactivemodeZMQ
"Initiate the interactive mode using ZMQ communication."
protected
  Option<Integer> zmqSocket;
  Boolean b;
  String str,replystr,suffix;
algorithm
  suffix := Flags.getConfigString(Flags.ZEROMQ_FILE_SUFFIX);
  zmqSocket := ZeroMQ.initialize(if suffix=="" then "" else ("."+suffix));
  false := valueEq(SOME(0), zmqSocket);
  while true loop
    str := ZeroMQ.handleRequest(zmqSocket);
    if Flags.isSet(Flags.INTERACTIVE_DUMP) then
      Debug.trace("------- Recieved Data from client -----\n");
      Debug.trace(str);
      Debug.trace("------- End recieved Data-----\n");
    end if;
    (b,replystr) := handleCommand(str);
    replystr := if b then replystr else "quit requested, shutting server down\n";
    ZeroMQ.sendReply(zmqSocket, replystr);
    if not b then
      ZeroMQ.close(zmqSocket);
      break;
    end if;
  end while;
end interactivemodeZMQ;

protected function serverLoopCorba
"This function is the main loop of the server for a CORBA impl."
protected
  String str, reply_str;
  Boolean cont;
algorithm
  cont := true;
  while true loop
    str := Corba.waitForCommand();
    (cont, reply_str) := handleCommand(str);
    if cont then
      Corba.sendreply(reply_str);
    else
      break;
    end if;
  end while;
  Corba.sendreply("quit requested, shutting server down\n");
  Corba.close();
end serverLoopCorba;

public function readSettings
  " author: x02lucpo
   Checks if 'settings.mos' exist and uses handleCommand with runScript(...) to execute it.
   Checks if '-s <file>.mos' has been"
  input list<String> inArguments;
protected
  String settings_file;
algorithm
  settings_file := Util.flagValue("-s", inArguments);

  if settings_file <> "" then
    settings_file := System.trim(settings_file, " \"");
    readSettingsFile(settings_file);
  end if;
end readSettings;


protected function readSettingsFile
  input String filePath;
protected
  String command;
algorithm
  if System.regularFileExists(filePath) then
    command := "runScript(\"" + filePath + "\")";
    (_, _) := handleCommand(command);
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
  _ := match(inOMHome)
    local
      String oldPath, newPath, omHome, omdevPath, mingwDir, binDir, libBinDir, msysBinDir;
      Boolean hasBinDir, hasLibBinDir;

    // check if we have OMDEV set
    case (omHome)
      equation
        System.setEnv("OPENMODELICAHOME",omHome,true);
        omdevPath = Util.makeValueOrDefault(System.readEnv,"OMDEV","");
        mingwDir = System.openModelicaPlatform();
        // if we don't have something in OMDEV use OMHOME
        if stringEq(omdevPath, "") then
          omdevPath = omHome;
        end if;
        msysBinDir = omdevPath + "\\tools\\msys\\usr\\bin";
        binDir = omdevPath + "\\tools\\msys\\" + mingwDir + "\\bin";
        libBinDir = omdevPath + "\\tools\\msys\\" + mingwDir + "\\lib\\gcc\\" + System.gccDumpMachine() + "\\" + System.gccVersion();
        // do we have bin and lib bin?
        hasBinDir = System.directoryExists(binDir);
        hasLibBinDir = System.directoryExists(libBinDir);
        if hasBinDir and hasLibBinDir
        then
          oldPath = System.readEnv("PATH");
          newPath = stringAppendList({omHome, "\\bin;", omHome, "\\lib;", binDir + ";", libBinDir + ";", msysBinDir + ";"});
          newPath = System.stringReplace(newPath, "/", "\\") + oldPath;
          // print("Path set: " + newPath + "\n");
          System.setEnv("PATH",newPath,true);
        else
          // do not display anything if -d=disableWindowsPathCheckWarning
          if not Flags.isSet(Flags.DISABLE_WINDOWS_PATH_CHECK_WARNING) then
            print("We could not find some needed MINGW paths in $OPENMODELICAHOME or $OMDEV. Searched for paths:\n");
            print("\t" + binDir + (if hasBinDir then " [found] " else " [not found] ") + "\n");
            print("\t" + libBinDir + (if hasLibBinDir then " [found] " else " [not found] ") + "\n");
          end if;
        end if;
      then ();
  end match;
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
    GC.setForceUnmapOnGcollect(if Autoconf.os == "Windows_NT" then true else false);
  else
    GC.expandHeap(if Autoconf.os == "Windows_NT"
                      then 1024*1024*150
                      else 1024*1024*300);
  end if;
  Global.initialize();
  ErrorExt.registerModelicaFormatError();
  ErrorExt.initAssertionFunctions();
  System.realtimeTick(ClockIndexes.RT_CLOCK_SIMULATE_TOTAL);
  args_1 := Flags.new(args);
  System.gettextInit(if Config.getRunningTestsuite() then "C" else Flags.getConfigString(Flags.LOCALE_FLAG));
  setDefaultCC();
  SymbolTable.reset();
end init;

public function main
  "This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
   start the translation."
  input list<String> args;
protected
  list<String> args_1;
  GC.ProfStats stats;
  Integer seconds;
algorithm
  execStatReset();
  try
  try
    args_1 := init(args);
    if Flags.isSet(Flags.GC_PROF) then
      print(GC.profStatsStr(GC.getProfStats(), head="GC stats after initialization:") + "\n");
    end if;
    seconds := Flags.getConfigInt(Flags.ALARM);
    if seconds > 0 then
      System.alarm(seconds);
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
protected
  String interactiveMode;
algorithm
  // Version requested using --version.
  if Config.versionRequest() then
    print(Settings.getVersionNr() + "\n");
    return;
  end if;

  // Don't allow running omc as root due to security risks.
  interactiveMode := Flags.getConfigString(Flags.INTERACTIVE);
  if System.userIsRoot() and (Flags.isSet(Flags.INTERACTIVE_TCP) or Flags.isSet(Flags.INTERACTIVE_CORBA)
     or interactiveMode == "corba" or interactiveMode == "tcp" or interactiveMode == "zmq") then
    Error.addMessage(Error.ROOT_USER_INTERACTIVE, {});
    print(ErrorExt.printMessagesStr(false));
    fail();
  end if;

  // Setup mingw path only once
  // adrpo: NEVER MOVE THIS CASE FROM HERE OR PUT ANY OTHER CASES BEFORE IT
  //        without asking Adrian.Pop@liu.se
  if Autoconf.os == "Windows_NT" then
    setWindowsPaths(Settings.getInstallationDirectoryPath());
  end if;

  try
    Settings.getInstallationDirectoryPath();

    readSettings(args);
    if Flags.isSet(Flags.INTERACTIVE_TCP) then
      print("The flag -d=interactive is depreciated. Please use --interactive=tcp\n");
      interactivemode();
    elseif interactiveMode == "tcp" then
      interactivemode();
    elseif Flags.isSet(Flags.INTERACTIVE_CORBA) then
      print("The flag -d=interactiveCorba is depreciated. Please use --interactive=corba\n");
      interactivemodeCorba();
    elseif interactiveMode == "corba" then
      interactivemodeCorba();
    elseif interactiveMode == "zmq" then
      interactivemodeZMQ();
    else // No interactive flag given, try to flatten the file.
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
