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
protected import Inst;
protected import Interactive;
protected import Dependency;
protected import RTOpts;
protected import Debug;
protected import Socket;
protected import Print;
protected import Corba;
protected import System;
protected import Util;
protected import ErrorExt;
protected import Error;
protected import CevalScript;
protected import Env;
protected import Settings;
protected import InnerOuter;
protected import DAEDump;

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

protected function translateFile
"function: translateFile
  This function invokes the translator on a source file.  The
  argument should be a list with a single file name."
  input list<String> inStringLst;
algorithm
  _:=
  matchcontinue (inStringLst)
    local
      Absyn.Program p;
      list<SCode.Class> p_1;
      DAE.DAElist d_2,d_1,d;
      String s,str,f,res;
      list<String> lst;
      Absyn.Path cname;
      Boolean silent,notsilent;
      Interactive.InteractiveStmts stmts;
      Interactive.InteractiveSymbolTable newst;
      /* Version requested using --version*/
    case (_) // try first to see if we had a version request among flags.
      equation
        versionRequest();
        print(Settings.getVersionNr());
      then ();

    case {f} /* A Modelica file .mo */
      local String s;
        AbsynDep.Depends dep;
      equation
        Debug.fcall("execstat",print, "*** Main -> entering at time: " +& realString(clock()) +& "\n" );
        isModelicaFile(f);
        p = Parser.parse(f);
        // show parse errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());

        Debug.fprint("dump", "\n--------------- Parsed program ---------------\n");
        Debug.fcall("dumpgraphviz", DumpGraphviz.dump, p);
        Debug.fcall("dump", Dump.dump, p);
        s = Debug.fcallret0("dump", Print.getString, "");
        Debug.fcall("dump",print,s);
        p = transformFlatProgram(p,f);
        p = Dependency.getTotalProgramLastClass(p);

        Debug.fprint("info", "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---elaborating\n");
        p_1 = SCodeUtil.translateAbsyn2SCode(p);
        Debug.fprint("info", "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---instantiating\n");
        //print(" Inst.Instantiate " +& realString(clock()) +&"\n");
        Debug.fcall("execstat",print, "*** Main -> To instantiate at time: " +& realString(clock()) +& "\n" );
        (_,_,d_1,_) = Inst.instantiate(Env.emptyCache(),InstanceHierarchy.emptyInstanceHierarchy,p_1);
        Debug.fcall("execstat",print, "*** Main -> done instantiation at time: " +& realString(clock()) +& "\n" );
        //print(" Inst.Instantiate " +& realString(clock()) +&" DONE\n");
        Debug.fprint("beforefixmodout", "Explicit part:\n");
        Debug.fcall("beforefixmodout", DAEDump.dumpDebug, d_1);
        d = fixModelicaOutput(d_1);
        Print.clearBuf();
        Debug.fprint("info", "---dumping\n");
        Debug.fcall("execstat",print, "*** Main -> dumping dae: " +& realString(clock()) +& "\n" );
        s = Debug.fcallret1("flatmodelica", DAEDump.dumpStr, d, "");
        Debug.fcall("execstat",print, "*** Main -> done dumping dae: " +& realString(clock()) +& "\n" );
        Debug.fcall("flatmodelica", Print.printBuf, s);
        Debug.fcall("execstat",print, "*** Main -> dumping dae2 : " +& realString(clock()) +& "\n" );
        s = Debug.fcallret1("none", DAEDump.dumpStr, d, "");
        Debug.fcall("execstat",print, "*** Main -> done dumping dae2 : " +& realString(clock()) +& "\n" );
        Debug.fcall("none", Print.printBuf, s);
        Debug.fcall("daedump", DAEDump.dump, d);
        Debug.fcall("daedump2", DAEDump.dump2, d);
        Debug.fcall("daedumpdebug", DAEDump.dumpDebug, d);
        Debug.fcall("daedumpgraphv", DAEDump.dumpGraphviz, d);
        cname = Absyn.lastClassname(p);
        str = Print.getString();
        silent = RTOpts.silent();
        notsilent = boolNot(silent);
        Debug.bcall(notsilent, print, str);
        Debug.fcall("execstat",print, "*** Main -> To optimizedae at time: " +& realString(clock()) +& "\n" );
      then
        ();
    case {f}
      local Integer r;
      equation
        r = System.regularFileExists(f);
        (r > 0) = true;  //could not found file
        print("File does not exist: "); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
      then
        fail();
    case {f}
      local Integer r;
      equation
        r = System.regularFileExists(f);
        (r == 0) = true;  //found file but could not process
        print("Error processing file: "); print(f); print("\n");
        // show errors if there are any
        showErrors(Print.getErrorString(), ErrorExt.printMessagesStr());
      then
        fail();
    case (_ :: (_ :: _))
      equation
        Print.printErrorBuf("# Too many arguments\n");
      then
        fail();
    case {}
      equation
        print("not enough arguments given to omc!\n");
        printUsage();
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

function printUsage
algorithm
  print("OpenModelica Frontend Compiler version: "); print(Settings.getVersionNr()); print("\n");
  print("http://www.ida.liu.se/labs/pelab/modelica/OpenModelica.html\n");
  print("Please check the System Guide for full information about flags.\n");
  print("Usage: omc [-runtimeOptions +omcOptions] Model.mo\n");
  print("* runtimeOptions: call omc -help for seeing runtime options\n");
  print("* omcOptions:\n");
  print("\t++v|+version               will print the version and exit\n");
  print("\t+q                         run in quiet mode, output nothing\n");
  print("\t+showErrorMessages         show error messages while they happen; default to no. \n");
  print("\t+d=flags                   set debug flags: \n");
  print("\t+d=failtrace               print what function fail\n");
  print("\t+d=parsedump               dump the parsing tree\n");
  print("\t+d=parseonly               will only parse the givn file and exit\n");
  print("* Examples:\n");
  print("\tomc Model.mo         will produce flattened Model on standard output\n");
  print("\t*.mo (Modelica files) \n");
end printUsage;

public function main
"function: main
  This is the main function that the MetaModelica Compiler (MMC) runtime system calls to
  start the translation."
  input list<String> inStringLst;
algorithm
  _ := matchcontinue (inStringLst)
    local
      String ver_str,errstr;
      list<String> args_1,args;
      Boolean ismode,icmode,imode,imode_1;
      String s,str;
      Interactive.InteractiveSymbolTable symbolTable;
    case args as _::_
      equation
        args_1 = RTOpts.args(args);
        // non of the interactive mode was set, flatten the file
        translateFile(args_1);
      then
        ();
    case args as _::_
      local Absyn.Program prg;
      equation
        failure(_ = RTOpts.args(args));
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

