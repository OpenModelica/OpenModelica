package Main "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
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

  
  file:        Main.rml
  module:      Main
  description: Modelica main program
 
  RCS: $Id$
 
  This is the main program in the Modelica specification. 
  It either tranlates a file given as a command line argument
  or starts a server loop communicating through CORBA or sockets
  (The Win32 implementation only implements CORBA)
"

protected import OpenModelica.Compiler.Absyn;

protected import OpenModelica.Compiler.Parser;

protected import OpenModelica.Compiler.Dump;

protected import OpenModelica.Compiler.DumpGraphviz;

protected import OpenModelica.Compiler.SCode;

protected import OpenModelica.Compiler.DAE;

protected import OpenModelica.Compiler.DAELow;

protected import OpenModelica.Compiler.Inst;

protected import OpenModelica.Compiler.Interactive;

protected import OpenModelica.Compiler.RTOpts;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.Socket;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.Corba;

protected import OpenModelica.Compiler.System;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.TaskGraph;

protected import OpenModelica.Compiler.TaskGraphExt;

protected import OpenModelica.Compiler.SimCodegen;

protected import OpenModelica.Compiler.ErrorExt;

protected import OpenModelica.Compiler.Error;

protected import OpenModelica.Compiler.Types;

protected import OpenModelica.Compiler.Ceval;

protected function serverLoop "adrpo -- not used
with \"ModUtil.rml\"
with \"Codegen.rml\"

  function: serverLoop
 
  This function is the main loop of the server listening to a port
  which recieves modelica expressions,  
"
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
        Debug.fprint("interactivedump", 
          "------- Recieved Data from client -----\n");
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
        Debug.fprint("interactivedump", 
          "------- Recieved Data from client -----\n");
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

protected function handleCommand "function handleCommand
 
  This function handles the commands in form of strings send to the server
  If the command is quit, the function returns false, otherwise it sends 
  the string to the parse function and returns true.
"
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
      list<Interactive.InteractiveVariable> vars_1,vars;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf_1,cf;
      list<SCode.Class> a;
      list<Interactive.InstantiatedClass> b;
      Interactive.InteractiveStmts exp;
    case (str,isymb)
      equation 
        true = Util.strncmp("quit()", str, 6);
      then
        (false,"Ok\n",isymb);
    case (str,(isymb as Interactive.SYMBOLTABLE(ast = iprog,explodedAst = a,instClsLst = b,lstVarVal = vars,compiledFunctions = cf))) /* Add a class or function to the interactive symbol table.
	   If it is a function, type check it. */ 
      equation 
        Debug.fcall0("dump", Print.clearBuf);
        Debug.fcall0("dumpgraphviz", Print.clearBuf);
        Debug.fprint("dump", "\nTrying to parse class definition...\n");
        (p,msg) = Parser.parsestring(str);
        equality(msg = "Ok") "Always succeeds, check msg for errors" ;
        Interactive.typeCheckFunction(p, isymb) "fails here if the string is not \"Ok\"" ;
        p_1 = Interactive.addScope(p, vars);
        vars_1 = Interactive.updateScope(p, vars);
        newprog = Interactive.updateProgram(p_1, iprog);
        cf_1 = Interactive.removeCompiledFunctions(p, cf);
        Debug.fprint("dump", 
          "\n--------------- Parsed program ---------------\n");
        Debug.fcall("dumpgraphviz", DumpGraphviz.dump, newprog);
        Debug.fcall("dump", Dump.dump, newprog);
        res_1 = makeDebugResult("dump", "Ok");
        res = makeDebugResult("dumpgraphviz", res_1);
      then
        (true,res,Interactive.SYMBOLTABLE(newprog,a,b,vars_1,cf_1));
    case (str,isymb) /* Interactively evaluate an algorithm statement or expression */ 
      equation 
        Debug.fcall0("dump", Print.clearBuf);
        Debug.fcall0("dumpgraphviz", Print.clearBuf);
        Debug.fprint("dump", 
          "\nNot a class definition, trying expresion parser\n");
        (exp,msg) = Parser.parsestringexp(str);
        equality(msg = "Ok") "always succeeds, check msg for errors" ;
        (evalstr,newisymb) = Interactive.evaluate(exp, isymb, false);
        Debug.fprint("dump", 
          "\n--------------- Parsed expression ---------------\n");
        Debug.fcall("dump", Dump.dumpIstmt, exp);
        res_1 = makeDebugResult("dump", evalstr);
        res = makeDebugResult("dumpgraphviz", res_1);
      then
        (true,res,newisymb);
    case (str,isymb)
      local Interactive.InteractiveStmts p;
      equation 
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

protected function isModelicaFile "function: isModelicaFile
 
  Succeeds if filename ends with .mo or .mof
"
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

protected function isFlatModelicaFile "function: isFlatModelicaFile
 
  Succeeds if filename ends with .mof
"
  input String filename;
  list<String> lst;
  String last;
algorithm 
  lst := System.strtok(filename, ".");
  (last :: _) := listReverse(lst);
  equality(last := "mof");
end isFlatModelicaFile;

protected function isModelicaScriptFile "function: isModelicaScriptFile
 
  Succeeds if filname end with .mos
"
  input String filename;
  list<String> lst;
  String last;
algorithm 
  lst := System.strtok(filename, ".");
  (last :: _) := listReverse(lst);
  equality(last := "mos");
end isModelicaScriptFile;

protected function transformIfFlat "function: transformIfFlat
  Checks is a modelica file is a flat modelica file
  and if so, translates all variables on the form a.b.c to a_b_c
"
  input String inString;
  input DAE.DAElist inDAElist;
  output DAE.DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inString,inDAElist)
    local
      DAE.DAElist d,dae;
      String f;
    case (f,dae)
      equation 
        isFlatModelicaFile(f);
        d = DAE.toModelicaForm(dae);
      then
        d;
    case (_,d) then d; 
  end matchcontinue;
end transformIfFlat;

protected function translateFile "function: translateFile
 
  This function invokes the translator on a source file.  The
  argument should be a list with a single file name.
"
  input list<String> inStringLst;
algorithm 
  _:=
  matchcontinue (inStringLst)
    local
      Absyn.Program p;
      list<SCode.Class> p_1;
      DAE.DAElist d_2,d_1,d;
      String s,str,f,res;
      Absyn.Path cname;
      Boolean silent,notsilent;
      Interactive.InteractiveStmts stmts;
      Interactive.InteractiveSymbolTable newst;
    case {f} /* A Modelica file .mo */ 
      equation 
        isModelicaFile(f);
        p = Parser.parse(f);
        Debug.fprint("dump", 
          "\n--------------- Parsed program ---------------\n");
        Debug.fcall("dumpgraphviz", DumpGraphviz.dump, p);
        Debug.fcall("dump", Dump.dump, p);
        Debug.fprint("info", 
          "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---elaborating\n");
        p_1 = SCode.elaborate(p);
        Debug.fprint("info", 
          "\n------------------------------------------------------------ \n");
        Debug.fprint("info", "---instantiating\n");
        d_2 = Inst.instantiate(p_1);
        d_1 = DAE.transformIfEqToExpr(d_2);
        Debug.fprint("beforefixmodout", "Explicit part:\n");
        Debug.fcall("beforefixmodout", DAE.dumpDebug, d_1) "	& Inst.instantiate_implicit(pfunc\') => dimpl\'
	& Debug.fprint (\"beforefixmodout\", \"Implicit part:\\n\")
	& Debug.fcall (\"beforefixmodout\", DAE.dump_debug, dimpl\')
" ;
        d = fixModelicaOutput(d_1) "	& fix_modelica_output (dimpl\') => dimpl
" ;
        Print.clearBuf();
        Debug.fprint("info", "---dumping\n");
        s = Debug.fcallret("flatmodelica", DAE.dumpStr, d, "");
        Debug.fcall("flatmodelica", Print.printBuf, s) "
	& Debug.fprint (\"flatmodelica\", \"Implicit:\\n\")
	& Debug.fcall (\"flatmodelica\", DAE.dump, dimpl)
" ;
        s = Debug.fcallret("none", DAE.dumpStr, d, "");
        Debug.fcall("none", Print.printBuf, s);
        Debug.fcall("daedump", DAE.dump, d);
        Debug.fcall("daedump2", DAE.dump2, d);
        Debug.fcall("daedumpdebug", DAE.dumpDebug, d);
        Debug.fcall("daedumpgraphv", DAE.dumpGraphviz, d);
        cname = Absyn.lastClassname(p);
        str = Print.getString();
        silent = RTOpts.silent();
        notsilent = boolNot(silent);
        Debug.bcall(notsilent, print, str);
        optimizeDae(p_1, p, d, d, cname);
      then
        ();
    case {f} /* Modelica script file .mos */ 
      equation 
        isModelicaScriptFile(f);
        stmts = Parser.parseexp(f);
        (res,newst) = Interactive.evaluate(stmts, Interactive.emptySymboltable, true);
        print(res);
      then
        ();
    case {f}
      equation 
        str = ErrorExt.printMessagesStr();
        print(str);
      then
        fail();
    case (_ :: (_ :: _))
      equation 
        Print.printErrorBuf("# Too many arguments\n");
      then
        fail();
    case {}
      equation 
        Print.printBuf("Usage: omc <options> filename \n");
        Print.printBuf("omc accepts .mo (Modelica files) \n");
        Print.printBuf("            .mof (Flat Modelica files) \n");
        Print.printBuf("            .mos (Modelica Script files) \n");
        Print.printBuf("Options:\n========");
        Print.printBuf("+s    Generate simulation code\n");
        Print.printBuf("+q    Run in quiet mode, ouput nothing\n");
        Print.printBuf("+d=flags, set flags: \n");
        Print.printBuf("    blt               apply blt transformation\n");
        Print.printBuf("    interactive       run in interactive mode\n");
        Print.printBuf(
          "    interactiveCorba  run in interactive mode using Corba\n");
        Print.printBuf("    ..., see DEBUG.TXT for further flags\n");
      then
        fail();
  end matchcontinue;
end translateFile;

protected function runBackendQ "function: runt_backend_q
 
  Determine if backend, i.e. BLT etc. should be run.
  It should be run if either \"blt\" flag is set or if 
  parallelization is enabled by giving flag -n=<no proc.>
"
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

protected function optimizeDae "function: optimizeDae
  
  Run the backend. Used for both parallization and for normal execution.
"
  input SCode.Program inProgram1;
  input Absyn.Program inProgram2;
  input DAE.DAElist inDAElist3;
  input DAE.DAElist inDAElist4;
  input Absyn.Path inPath5;
algorithm 
  _:=
  matchcontinue (inProgram1,inProgram2,inDAElist3,inDAElist4,inPath5)
    local
      DAELow.DAELow dlow,dlow_1;
      list<Integer>[:] m,mT;
      Integer[:] v1,v2;
      list<list<Integer>> comps;
      list<SCode.Class> p;
      Absyn.Program ap;
      DAE.DAElist dae,daeimpl;
      Absyn.Path classname;
    case (p,ap,dae,daeimpl,classname)
      equation 
        true = runBackendQ();
        dlow = DAELow.lower(dae, true) "add dummy state" ;
        Debug.fcall("dumpdaelow", DAELow.dump, dlow);
        m = DAELow.incidenceMatrix(dlow);
        mT = DAELow.transposeMatrix(m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        (v1,v2,dlow_1,m,mT) = DAELow.matchingAlgorithm(dlow, m, mT, 
          (DAELow.INDEX_REDUCTION(),DAELow.EXACT(),
          DAELow.REMOVE_SIMPLE_EQN()));
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrix, m);
        Debug.fcall("bltdump", DAELow.dumpIncidenceMatrixT, mT);
        Debug.fcall("bltdump", DAELow.dump, dlow_1);
        Debug.fcall("bltdump", DAELow.dumpMatching, v1);
        (comps) = DAELow.strongComponents(m, mT, v1, v2);
        Debug.fcall("bltdump", DAELow.dumpComponents, comps);
        modpar(dlow_1, v1, v2, comps);
        simcodegen(classname, p, ap, daeimpl, dlow_1, v1, v2, m, mT, comps);
      then
        ();
    case (_,_,_,_,_)
      equation 
        true = runBackendQ() "so main can print error messages" ;
      then
        fail();
    case (_,_,_,_,_) /* If not running backend. */ 
      equation 
        false = runBackendQ();
      then
        ();
  end matchcontinue;
end optimizeDae;

protected function modpar "function: modpar
 
  The automatic paralellzation module.
"
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
        print("translating dae.\n") "Otherwise, build task graph print \"old dae:\" & DAELow.dump dae &" ;
        indexed_dae = DAELow.translateDae(dae);
        indexed_dae_1 = DAELow.calculateValues(indexed_dae);
        print("building task graph\n") "	print \"new dae:\" & DAELow.dump indexed_dae\' &" ;
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
        (nx,ny,np,_) = DAELow.calculateSizes(indexed_dae_1);
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

protected function simcodegen "function simcodegen
 
  Genereates simulation code using the SimCodegen module
"
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
  matchcontinue (inPath1,inProgram2,inProgram3,inDAElist4,inDAELow5,inIntegerArray6,inIntegerArray7,inIncidenceMatrix8,inIncidenceMatrixT9,inIntegerLstLst10)
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
    case (classname,p,ap,dae,dlow,ass1,ass2,m,mt,comps) /* classname ass1 ass2 blocks */ 
      equation 
        true = RTOpts.simulationCg();
        Print.clearErrorBuf();
        Print.clearBuf();
        indexed_dlow = DAELow.translateDae(dlow);
        indexed_dlow_1 = DAELow.calculateValues(indexed_dlow);
        cname_str = Absyn.pathString(classname);
        filename = Util.stringAppendList({cname_str,".cpp"});
        funcfilename = Util.stringAppendList({cname_str,"_functions.cpp"});
        init_filename = Util.stringAppendList({cname_str,"_init.txt"});
        makefilename = Util.stringAppendList({cname_str,".makefile"});
        a_cref = Absyn.pathToCref(classname);
        file_dir = Ceval.getFileDir(a_cref, ap);
        libs = SimCodegen.generateFunctions(p, dae, indexed_dlow_1, classname, funcfilename);
        SimCodegen.generateSimulationCode(dae, indexed_dlow_1, ass1, ass2, m, mt, comps, classname, 
          filename, funcfilename);
        SimCodegen.generateInitData(indexed_dlow_1, classname, cname_str, init_filename, 0.0, 
          1.0, 500.0);
        SimCodegen.generateMakefile(makefilename, cname_str, libs, file_dir);
      then
        ();
    case (_,_,_,_,_,_,_,_,_,_) /* If something above failed. fail so Main can print errors */ 
      equation 
        true = RTOpts.simulationCg();
      then
        fail();
    case (_,_,_,_,_,_,_,_,_,_) /* If not generating simulation code */ 
      equation 
        false = RTOpts.simulationCg();
      then
        ();
  end matchcontinue;
end simcodegen;

protected function runModparQ "function: runModparQ
 
  Returns true if parallelization should be run.
"
  output Boolean res;
  Integer n;
algorithm 
  n := RTOpts.noProc();
  res := (n > 0);
end runModparQ;

protected function fixModelicaOutput "function: fixModelicaOutput
 
  Transform the dae, replacing dots with underscore in variables and 
  equations.
"
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

protected function interactivemode "function: interactivemode
 
  Initiate the interactive mode using socket communication.
"
  input list<String> inStringLst;
algorithm 
  _:=
  matchcontinue (inStringLst)
    local Integer shandle;
    case _
      equation 
        shandle = Socket.waitforconnect(29500);
        _ = serverLoop(shandle, Interactive.emptySymboltable);
      then
        ();
  end matchcontinue;
end interactivemode;

protected function interactivemodeCorba "function: interactivemodeCorba
 
  Initiate the interactive mode using corba communication.
"
  input list<String> inStringLst;
algorithm 
  _:=
  matchcontinue (inStringLst)
    case _
      equation 
        Corba.initialize();
        _ = serverLoopCorba(Interactive.emptySymboltable);
      then
        ();
  end matchcontinue;
end interactivemodeCorba;

protected function serverLoopCorba "function: serverLoopCorba
 
  This function is the main loop of the server for a CORBA impl.
"
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

public function main "function: main
 
  This is the main function that the RML runtime system calls to
  start the translation.
"
  input list<String> inStringLst;
algorithm 
  _:=
  matchcontinue (inStringLst)
    local
      list<String> args_1,args;
      Boolean ismode,icmode,imode,imode_1;
      String s,str;
    case args
      equation 
        args_1 = RTOpts.args(args);
        ismode = RTOpts.debugFlag("interactive");
        icmode = RTOpts.debugFlag("interactiveCorba");
        imode = boolOr(ismode, icmode);
        imode_1 = boolNot(imode);
        Debug.bcall(ismode, interactivemode, args_1);
        Debug.bcall(icmode, interactivemodeCorba, args_1);
        Debug.bcall(imode_1, translateFile, args_1);
        s = Print.getErrorString();
        Debug.fcall("failtrace", print, s);
      then
        ();
    case _
      equation 
        str = Print.getErrorString() "If main fails, retrieve error messages and print to std out." ;
        print(str);
      then
        fail();
  end matchcontinue;
end main;
end Main;

