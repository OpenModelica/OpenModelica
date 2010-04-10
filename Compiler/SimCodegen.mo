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

package SimCodegen
" file:	       SimCodegen.mo
  package:     SimCodegen
  description: Generate Simulation code for connecting to solver.
  This can be done in two different ways.
  1. Generation of simulation code on residual form. This will generate
  code on the form g(\\dot{x},x,y,t)=0.
  2. Generation of simulation code on solved form. This will generate
  code on ode form. \\dot{x} = f(x,y,t). This means that \"function\" f will
  contain code for solving states from equations, some of them might be
  system of equations, linear or non-linear.

  RCS: $Id$

  Outputs: the simulation code in C/C++ to a given filename.
  Input: DAELow
  Uses: DAELow, Absyn, Exp "

public import DAE;
public import DAELow;
public import Absyn;
public import SCode;
public import Env;

public type HelpVarInfo = tuple<Integer, DAE.Exp, Integer>; // helpvarindex, expression, whenclause index

protected type EnumerationLst = list<tuple<String,list<String>>>; // List of Enumerations

protected type CFunction = Codegen.CFunction;
protected constant String TAB="    ";
protected constant String stateNames="state_names" "TAB is four whitespaces" ;
protected constant String derivativeNames="derivative_names";
protected constant String algvarsNames="algvars_names";
protected constant String inputNames="input_names";
protected constant String outputNames="output_names";
protected constant String paramNames="param_names";
protected constant String stringParamNames="string_param_names";
protected constant String stringAlgNames="string_alg_names";
protected constant String stateComments="state_comments";
protected constant String derivativeComments="derivative_comments";
protected constant String algvarsComments="algvars_comments";
protected constant String inputComments="input_comments";
protected constant String outputComments="output_comments";
protected constant String paramComments="param_comments";
protected constant String stringParamComments="string_param_comments";
protected constant String stringAlgComments="string_alg_comments";
protected constant String paramInGetNameFunction="ptr";

protected import Algorithm;
protected import CevalScript;
protected import Codegen;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Exp;
protected import Inline;
protected import Inst;
protected import InnerOuter;
protected import Lookup;
protected import ModUtil;
protected import RTOpts;
protected import PartFn;
protected import Print;
protected import Settings;
protected import System;
protected import Util;
protected import Values;
protected import ValuesUtil;
protected import VarTransform;

public function generateMakefile
"function: generateMakefile
  This function generates a makefile for the simulation code.
  It uses:
   - OPENMODELICAHOME/include as a reference to includes and
   - OPENMODELICAHOME/lib as a reference to library files"
  input String inMakefileName;
  input String inFilenamePrefix;
  input list<String> inLibs;
  input String inFileDir;
algorithm
  _:=
  matchcontinue (inMakefileName,inFilenamePrefix,inLibs,inFileDir)
    local
      String cpp_file,libs_1,omhome_1,omhome,str,filename,cname,file_dir,MakefileHeader;
      list<String> libs;
    case (filename,cname,libs,"") /* filename classname libs directory for mo-file */
      equation
        MakefileHeader = CevalScript.generateMakefileHeader();
        cpp_file = Util.stringAppendList({cname,".cpp"});
        libs = Util.listUnion(libs, libs); // un-double the libs
        libs_1 = Util.stringDelimitList(libs, " ");
        omhome_1 = Settings.getInstallationDirectoryPath();
        omhome = System.trim(omhome_1, "\"");
        str = Util.stringAppendList({MakefileHeader,
          "\n.PHONY: ",cname,"\n",
          cname,": ",cpp_file,"\n","\t $(CXX)",
          " $(CFLAGS)",
          " -I.",
          " -o ",cname,"$(EXEEXT) ",
          cpp_file,
          " ",libs_1,
          " -lsim",
          " $(LDFLAGS)",
          " -lf2c",
          " ${SENDDATALIBS} ",
          "\n"});
        System.writeFile(filename, str);
      then
        ();
    case (filename,cname,libs,file_dir)
      equation
        MakefileHeader = CevalScript.generateMakefileHeader();
        cpp_file = Util.stringAppendList({cname,".cpp"});
        libs = Util.listUnion(libs, libs); // un-double the libs
        libs_1 = Util.stringDelimitList(libs, " ");
        omhome_1 = Settings.getInstallationDirectoryPath();
        omhome = System.trim(omhome_1, "\"");
        str = Util.stringAppendList(
          {MakefileHeader,
          "\n.PHONY: ",cname,"\n",
          cname,": ",cpp_file,"\n","\t $(CXX)",
          " $(CFLAGS)",
          " -I.",
          " -I\"",file_dir,"\"",
          " -o ",cname,"$(EXEEXT) ",cpp_file,
          " -L\"",file_dir,"\"",
          " -lsim",
          " $(LDFLAGS)",
          " -lf2c",
          " ${SENDDATALIBS} ",
          libs_1,
          "\n"});
        System.writeFile(filename, str);
      then
        ();
  end matchcontinue;
end generateMakefile;

public function generateSimulationCode "function: generateSimulationCode
  Outputs simulation code from a DAELow suitable for connection to DASSL.
  The state calculations are generated on residual form, i.e.
  g(\\dot{x},x,y,t) = 0.
  and on explicit ode form, \\dot{x}=f(x,y,t)
"
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input DAELow.IncidenceMatrix inIncidenceMatrix5;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT6;
  input list<list<Integer>> inIntegerLstLst7;
  input Absyn.Path inPath8;
  input String inString9;
  input String inString10;
  input String inString11;
algorithm
  _:=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inIntegerLstLst7,inPath8,inString9,inString10,inString11)
    local
      String cname,out_str,in_str,c_eventchecking,s_code2,s_code3,cglobal,coutput,cstate,c_ode,s_code,cwhen,
      	czerocross,res,filename,funcfilename,fileDir,updatedepend,storedelayed;
      String extObjInclude; list<String> extObjIncludes;
      list<list<Integer>> blt_states,blt_no_states,comps;
      Integer n_o,n_i,n_h,nres;
      list<HelpVarInfo> helpVarInfo,helpVarInfo1;
      DAE.DAElist dae;
      DAELow.DAELow dlow,dlow2;
      Integer[:] ass1,ass2;
      list<Integer>[:] m,mt;
      Absyn.Path class_;

    case (dae,dlow,ass1,ass2,m,mt,comps,class_,filename,funcfilename,fileDir)
      equation
        cname = Absyn.pathString(class_);
        (blt_states,blt_no_states) = DAELow.generateStatePartition(comps, dlow, ass1, ass2, m, mt);
				Debug.fcall("bltdump",print," state blocks (dynamic section):");
				Debug.fcall("bltdump",DAELow.dumpComponents,blt_states);
				Debug.fcall("bltdump",print," algebraic blocks (accepted section):");
				Debug.fcall("bltdump",DAELow.dumpComponents,blt_no_states);

        (c_eventchecking,helpVarInfo1) = generateEventCheckingCode(dlow, comps, ass1, ass2, m, mt, class_);
        (helpVarInfo,dlow2) = generateHelpVarsForWhenStatements(helpVarInfo1,dlow);
        (out_str,n_o) = generateOutputFunctionCode(dlow2);
        (in_str,n_i) = generateInputFunctionCode(dlow2);
        n_h = listLength(helpVarInfo);
        (s_code2,nres) = generateInitialValueCode2(dlow2,ass1,ass2);
        (s_code3) = generateInitialBoundParameterCode(dlow2);
        cglobal = generateGlobalData(class_, dlow2, n_o, n_i, n_h, nres,fileDir); // CHANGED!!!
        coutput = generateComputeOutput(cname, dae, dlow2, ass1, ass2,m,mt, blt_no_states);
        cstate = generateComputeResidualState(cname, dae, dlow2, ass1, ass2, blt_states);
        c_ode = generateOdeCode(dae, dlow2, blt_states, ass1, ass2, m, mt, class_);
        s_code = generateInitialValueCode(dlow2);
        cwhen = generateWhenClauses(cname, dae, dlow2, ass1, ass2, comps);
        czerocross = generateZeroCrossing(cname, dae, dlow2, ass1, ass2, comps, helpVarInfo);
        updatedepend = generateUpdateDepended(dae, dlow2, ass1, ass2, comps, helpVarInfo,m,mt);
        storedelayed = generateStoreDelayed(dlow2);
        (extObjIncludes,_) = generateExternalObjectIncludes(dlow2);
        extObjInclude = Util.stringDelimitList(extObjIncludes,"\n");
        extObjInclude = Util.stringAppendList({"extern \"C\" {\n",extObjInclude,"\n}\n"});
        res = Util.stringAppendList({
            "// Simulation code for ",cname," generated by the OpenModelica Compiler.\n",
            "#include \"modelica.h\"\n",
            "#include \"assert.h\"\n",
            "#include \"string.h\"\n",
            "#include \"simulation_runtime.h\"\n\n",
            "#if defined(_MSC_VER) && !defined(_SIMULATION_RUNTIME_H)\n",
            "  #define DLLExport   __declspec( dllexport ) \n",
            "#else \n",
            "  #define DLLExport /* nothing */\n",
            "#endif \n\n",
            "#include \"",funcfilename,"\"\n\n",
            extObjInclude,cglobal,coutput,in_str,out_str,
            cstate,czerocross,updatedepend,storedelayed,cwhen,c_ode,s_code,s_code2,
            s_code3,c_eventchecking});
        System.writeFile(filename, res);
      then
        ();
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Generation of simulation code  failed"});
      then
        fail();
  end matchcontinue;
end generateSimulationCode;

protected function generateHelpVarsForWhenStatements
	input list<HelpVarInfo> inHelpVarInfo;
	input DAELow.DAELow inDAELow;
	output list<HelpVarInfo> outHelpVarInfo;
	output DAELow.DAELow outDAELow;
algorithm
  (outHelpVarInfo,outDAELow) :=
  matchcontinue (inHelpVarInfo,inDAELow)
    local
      list<HelpVarInfo> helpvars, helpvars1;
      DAELow.Variables orderedVars;
      DAELow.Variables knownVars;
      DAELow.Variables externalObjects;
      VarTransform.VariableReplacements aliasVars "alias-variables' hashtable";      
      DAELow.EquationArray orderedEqs;
      DAELow.EquationArray removedEqs;
      DAELow.EquationArray initialEqs;
      DAELow.MultiDimEquation[:] arrayEqs;
      Algorithm.Algorithm[:] algorithms,algorithms2;
      list<Algorithm.Algorithm> algLst;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
    case	(helpvars,DAELow.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,
      removedEqs,initialEqs,arrayEqs,algorithms,eventInfo,extObjClasses))
      equation
        (helpvars1,algLst,_) = generateHelpVarsInAlgorithms(listLength(helpvars),arrayList(algorithms));
        algorithms2 = listArray(algLst);
      then (listAppend(helpvars,helpvars1),DAELow.DAELOW(orderedVars,knownVars,externalObjects,aliasVars,orderedEqs,
        removedEqs,initialEqs,arrayEqs,algorithms2,eventInfo,extObjClasses));
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsForWhenStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsForWhenStatements;

protected function generateHelpVarsInAlgorithms
  input Integer nextInd "Index of next help variable";
  input list<Algorithm.Algorithm> inAlgLst;
  output list<HelpVarInfo> outHelpVars;
  output list<Algorithm.Algorithm> outAlgLst;
  output Integer n2;
algorithm
  (outHelpVars,outAlgLst,n2) := matchcontinue(nextInd,inAlgLst)
    local
      Integer nextInd,nextInd2,nextInd3;
      list<Algorithm.Statement> stmts, stmts2;
      list<Algorithm.Algorithm> rest,rest2;
      list<HelpVarInfo> helpvars1,helpvars2,helpvars;
    case (nextInd, {}) then ({},{},nextInd);
    case (nextInd, (DAE.ALGORITHM_STMTS(stmts))::rest)
      equation
        (helpvars1,rest2,nextInd2) = generateHelpVarsInAlgorithms(nextInd,rest);
        (helpvars2,stmts2,nextInd3) = generateHelpVarsInStatements(nextInd2,stmts);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,DAE.ALGORITHM_STMTS(stmts2)::rest2,nextInd3);
    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsInAlgorithms failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInAlgorithms;

protected function generateHelpVarsInStatements
  input Integer n "Index of next help variable";
  input list<Algorithm.Statement> inStmtLst;
  output list<HelpVarInfo> outHelpVars;
  output list<Algorithm.Statement> outStmtLst;
  output Integer n1;
algorithm
  (outHelpVars,outStmtLst,n1) := matchcontinue(n,inStmtLst)
    local
      list<Algorithm.Statement> rest, rest1;
      Integer nextInd, nextInd1, nextInd2;
	    Algorithm.Statement statement,statement1;
	    list<HelpVarInfo> helpvars,helpvars1,helpvars2;

    case (nextInd, {}) then ({},{},nextInd);

    case (nextInd, statement::rest)
      equation
        (helpvars1,rest1,nextInd1) = generateHelpVarsInStatements(nextInd,rest);
        (helpvars2,statement1,nextInd2) = generateHelpVarsInStatement(nextInd1,statement);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,statement1::rest1,nextInd2);

    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsInStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInStatements;

protected function generateHelpVarsInStatement
  input Integer n "Index of next help variable";
  input Algorithm.Statement inStmt;
  output list<HelpVarInfo> outHelpVars;
  output Algorithm.Statement outStmt;
  output Integer n1;
algorithm
  (outHelpVars,outStmt,n1) := matchcontinue(n,inStmt)
    local
      list<Algorithm.Statement> rest, rest1;
      Integer nextInd, nextInd1, nextInd2;
      list<Integer> helpVarIndices, helpVarIndices1;
      DAE.Exp condition;
      list<DAE.Exp> el, el1;
	    list<Algorithm.Statement> statementLst;
	    Algorithm.Statement statement;
  	  Algorithm.Statement elseWhen;
	    list<HelpVarInfo> helpvars,helpvars1,helpvars2;
      String newIdent;
      String nextIndStr;
      DAE.ExpType ty;
      Boolean scalar;
      list<Integer> helpVarIndices1,helpVarIndices;
    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,NONE,_))
      equation
				(helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
				helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
				helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
      then (helpvars1,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,NONE,helpVarIndices),nextInd1);

    case (nextInd, DAE.STMT_WHEN(condition,statementLst,NONE,_))
      then ({(nextInd,condition,-1)},DAE.STMT_WHEN(condition, statementLst,NONE,{nextInd}),nextInd+1);

    case (nextInd, DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el),statementLst,SOME(elseWhen),_))
      equation
				(helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd,el);
				helpVarIndices1 = Util.listIntRange(nextInd1-nextInd);
				helpVarIndices = Util.listMap1(helpVarIndices1,intAdd,nextInd-1);
        (helpvars2,statement,nextInd2) = generateHelpVarsInStatement(nextInd1,elseWhen);
        helpvars = listAppend(helpvars1,helpvars2);
      then (helpvars,DAE.STMT_WHEN(DAE.ARRAY(ty,scalar,el1), statementLst,SOME(statement),helpVarIndices),nextInd1);

    case (nextInd, DAE.STMT_WHEN(condition,statementLst,SOME(elseWhen),_))
      equation
        (helpvars1,statement,nextInd1) = generateHelpVarsInStatement(nextInd+1,elseWhen);
      then ((nextInd,condition,-1)::helpvars1,
        DAE.STMT_WHEN(condition, statementLst,SOME(statement),{nextInd}),nextInd1);

    case (nextInd, statement) then ({},statement,nextInd);

    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsInStatements failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInStatement;

protected function generateHelpVarsInArrayCondition
  input Integer n "Index of next help variable";
  input list<DAE.Exp> inExp;
  output list<HelpVarInfo> outHelpVars;
  output list<DAE.Exp> outExp;
  output Integer n1;
algorithm
  (outHelpVars,outExp,n2) := matchcontinue(n,inExp)
    local
      list<DAE.Exp> rest, el, el1;
      Integer nextInd, nextInd1;
      DAE.Exp condition;
	    list<HelpVarInfo> helpvars1;
      String newIdent;
      String nextIndStr;

    case (nextInd, {}) then ({},{},nextInd);

    case (nextInd, condition::rest)
      equation
				(helpvars1,el1,nextInd1) = generateHelpVarsInArrayCondition(nextInd+1,rest);
      then ((nextInd,condition,-1)::helpvars1,condition::el1,nextInd1);

    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"generateHelpVarsInArrayCondition failed"});
      then
        fail();
  end matchcontinue;
end generateHelpVarsInArrayCondition;

protected function filterNg "function: filterNg
  This function sets the number of zero crossings to zero if events are disabled
"
  input Integer inInteger;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inInteger)
    local Integer ng;
    case _
      equation
        false = useZerocrossing();
      then
        0;
    case ng then ng;
  end matchcontinue;
end filterNg;

protected function generateGlobalData
"
  This function generates the C-code for the global data: arrays for states,
  derivatives and algebraic variables, etc.
  arg1
  arg2
  arg3 an int which shows the number of output variables on top level
  arg4 an int which shows the number of input variables on top level
  arg5 an int which shows the number of help variables
  arg5 integer - number of residuals in initialization function.
  arg6 String - the directory where the model is saved
"
  input Absyn.Path class_               "Path to the instatiated model";
  input DAELow.DAELow loweredDAE			  "The lowered DAE";
  input Integer numberOfOutputVariables "The number of output variables on top level";
  input Integer numberOfInputVariables  "The number of input variables on top level";
  input Integer numberOfHelpVariables   "The number of help variables";
  input Integer numberOfResidulas       "Number of residuals in initialization function";
  input String fileDir "The directory where the model is saved";
  output String outString;
algorithm
  outString:=
  matchcontinue (class_,loweredDAE,numberOfOutputVariables,numberOfInputVariables,numberOfHelpVariables,numberOfResidulas,fileDir)
    local
      Integer nx,ny,np,ng,ng_1,no,ni,nh,nres,next,ny_string,np_string;
      String initDeinitDataStructFunction,class_str,nx_str,ny_str,np_str,ng_str,no_str,ni_str,nh_str;
      String nres_str,c_code2_str,c_code3_str,c_code_str,macros_str,global_bufs,str1,str,next_str;
      String nystring_str, npstring_str;
      list<String> c_code;
      Absyn.Path class_;
      DAELow.DAELow dlow;
      String trimmedFileDir;
    case (class_,dlow,no,ni,nh,nres,fileDir)
      equation
        (nx,ny,np,ng,next,ny_string,np_string) = DAELow.calculateSizes(dlow);
        //DAELow.dump(dlow);

        ng_1 = filterNg(ng);
        class_str = Absyn.pathString(class_);
        nx_str = intString(nx);
        ny_str = intString(ny);
        np_str = intString(np);
        ng_str = intString(ng_1);
        no_str = intString(no);
        ni_str = intString(ni);
        nh_str = intString(nh);
        nres_str = intString(nres);
        next_str = intString(next);
        nystring_str = intString(ny_string);
        npstring_str = intString(np_string);
        c_code = generateVarNamesAndComments(dlow, nx, ny, ni, no, np,next,ny_string,np_string);
        initDeinitDataStructFunction = generateInitializeDeinitializationDataStruc(dlow);
        (c_code2_str) = generateFixedVector(dlow, nx, ny, np);
        (c_code3_str) = generateAttrVector(dlow, nx, ny, np);
        c_code_str = Util.stringDelimitList(c_code, "\n");
        macros_str = generateMacros();
        global_bufs = generateGlobalBufs();
        // take of the quotes "
        trimmedFileDir = System.trim(fileDir, "\"");
        // and transform it to a C string: \ replaced by \\
        // trimmedFileDir = System.stringReplace(trimmedFileDir, "\\", "\\\\");
        str1 = Util.stringAppendList(
          {"\n","#define NHELP ",nh_str,"\n","#define NG ",ng_str,"//number of zero crossing",
          "\n","#define NX ",nx_str,"\n","#define NY ",ny_str,"\n","#define NP ",
          np_str," // number of parameters\n","#define NO ",no_str,
          " // number of outputvar on topmodel\n","#define NI ",ni_str," // number of inputvar on topmodel\n",
          "#define NR ",nres_str," // number of residuals for initialialization function\n",
          "#define NEXT ", next_str," // number of external objects\n",
          "#define MAXORD 5\n",
          "#define NYSTR ",nystring_str, " // number of alg. string variables\n",
          "#define NPSTR ",npstring_str, " // number of alg. string variables\n",
          "\n",
           global_bufs,
           "extern \"C\" { /* adrpo: this is needed for Visual C++ compilation to work! */\n",
           "  char *model_name=\"",class_str,"\";\n",
           "  char *model_dir=\"",trimmedFileDir,"\";\n",
           "}\n",
           c_code_str,c_code2_str,"\n",c_code3_str,"\n"});
        str = Util.stringAppendList({str1,macros_str,"\n",initDeinitDataStructFunction,"\n"})
        "this is done here and not in the above Util.string_append_list VC7.1 cannot compile too
         complicated c-programs this is removed for now
         \"typedef struct equation {\\n\", \"  char equation;\\n\", \"  char fileName;\\n\", \"
         int   lineNumber;\\n\", \"} equation;\\n\"," ;
      then
        str;
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_global_data failed"});
      then
        fail();
  end matchcontinue;
end generateGlobalData;

protected function generateExternalObjectDestructorCalls "generate destructor calls for external objects"
	input Integer cg_in;
  input DAELow.DAELow daelow;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
	(outCFunction,outInteger) := matchcontinue(cg_in,daelow)
	  case (cg_in,DAELow.DAELOW(externalObjects = evars, extObjClasses = eclasses))
	    local
	      DAELow.Variables evars;
	      list<DAELow.Var> evarLst;
	      DAELow.ExternalObjectClasses eclasses;
	      list<String> strs;
	    equation
	       evarLst = DAELow.varList(evars);
	       (outCFunction,cg_out) = generateExternalObjectDestructorCalls2(cg_in,evarLst,eclasses);
	    then (outCFunction,cg_out);
  end matchcontinue;
end generateExternalObjectDestructorCalls;

protected function generateExternalObjectDestructorCalls2 "
help function to generateExternalObjectDestructorCalls"
	input Integer cg_in;
  input list<DAELow.Var> varLst;
  input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varLst,eclasses)
    local	DAELow.Var v;
      list<DAELow.Var> vs;
      Codegen.CFunction cfunc,cfunc2;
    case (cg_in,{},eclasses)
    then (Codegen.cEmptyFunction,cg_in);
    case (cg_in,v::vs,eclasses) equation
      (cfunc,cg_out) = generateExternalObjectDestructorCalls2(cg_in,vs,eclasses);
      (cfunc2,cg_out) = generateExternalObjectDestructorCall(cg_out,v,eclasses);
      cfunc = Codegen.cMergeFns({cfunc2,cfunc});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectDestructorCalls2;

protected function generateExternalObjectDestructorCall "help function to generateExternalObjectDestructorCalls"
	input Integer cg_in;
	input DAELow.Var var;
	input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
	(outCFunction,cg_out) := matchcontinue (cg_in,var,eclasses)
	  case (_,_,{}) equation print("generateExternalObjectDestructorCall failed\n"); then fail();

		// found class
	  case (cg_in,DAELow.VAR(varName = name,varKind = DAELow.EXTOBJ(path1)), DAELow.EXTOBJCLASS(path=path2,destructor=destr)::_)
	    local
	      DAE.Element destr;
	      DAE.ComponentRef name;
	      Absyn.Path path1,path2;
	      Codegen.CFunction cfunc;

	    equation
	      true = ModUtil.pathEqual(path1,path2);
	      (cfunc,cg_out) = generateExternalObjectDestructorCall2(cg_in,name,destr);
	      then (cfunc,cg_out);
	  // Try next class.
	  case (cg_in,var,_::eclasses)
	    local Codegen.CFunction cfunc;
	    equation
	     (cfunc,cg_out) = generateExternalObjectDestructorCall(cg_in,var,eclasses);
	  then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectDestructorCall;

protected function generateExternalObjectDestructorCall2 "Help funciton to generateExternalObjectDestructorCall"
	input Integer cg_in;
  input DAE.ComponentRef varName;
  input DAE.Element destructor;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (cg_out,outCFunction) := matchcontinue(cg_in,varName,destructor)
    case (cg_in,varName,destructor as DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(ident=funcStr))}))
      local String vStr,funcStr,str;
        Codegen.CFunction cfunc;
      equation
        vStr = Exp.printComponentRefStr(varName);
        str = Util.stringAppendList({"    ",funcStr,"(",vStr,");"});
        cfunc = Codegen.cAddStatements(Codegen.cEmptyFunction,{str});
      then (cfunc,cg_in);

  end matchcontinue;
end generateExternalObjectDestructorCall2;

protected function generateExternalObjectConstructorCalls " generates constructor calls of all external objects"
	input Integer cg_in;
  input DAELow.DAELow daelow;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  str := matchcontinue(cg_in,daelow)
	  case (cg_in,DAELow.DAELOW(externalObjects = evars, extObjClasses = eclasses))
	    local
	      DAELow.Variables evars;
	      list<DAELow.Var> evarLst;
	      DAELow.ExternalObjectClasses eclasses;
	      list<String> strs;
	    equation
	      evarLst = DAELow.varList(evars);
	      (outCFunction,cg_out) = generateExternalObjectConstructorCalls2(cg_in,evarLst,eclasses);
	    then (outCFunction,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorCalls;

protected function generateExternalObjectConstructorCalls2 "
help function to generateExternalObjectConstructorCalls"
	input Integer cg_in;
  input list<DAELow.Var> varLst;
  input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varLst,eclasses)
    local	DAELow.Var v;
      list<DAELow.Var> vs;
      Codegen.CFunction cfunc,cfunc2;
    case (cg_in,{},eclasses)
    then (Codegen.cEmptyFunction,cg_in);
    case (cg_in,v::vs,eclasses) equation
      (cfunc,cg_out) = generateExternalObjectConstructorCalls2(cg_in,vs,eclasses);
      (cfunc2,cg_out) = generateExternalObjectConstructorCall(cg_out,v,eclasses);
      cfunc = Codegen.cMergeFns({cfunc2,cfunc});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorCalls2;

protected function generateExternalObjectConstructorAliases "Generates codes for external objects that are
aliased to other external object variables. They must be issued after the constructor call. Therefore
this function is called after all constructor calls have been generated."
	input Integer cg_in;
  input DAELow.DAELow daelow;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  str := matchcontinue(cg_in,daelow)
	  case (cg_in,DAELow.DAELOW(externalObjects = evars))
	    local
	      DAELow.Variables evars;
	      list<DAELow.Var> evarLst;
	      list<String> strs;
	    equation
	      evarLst = DAELow.varList(evars);
	      (outCFunction,cg_out) = generateExternalObjectConstructorAliases2(cg_in,evarLst);
	    then (outCFunction,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorAliases;

protected function generateExternalObjectConstructorAliases2 "
help function to generateExternalObjectConstructorAliases"
	input Integer cg_in;
  input list<DAELow.Var> varLst;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varLst)
    local	DAELow.Var v;
      list<DAELow.Var> vs;
      Codegen.CFunction cfunc,cfunc2;
    case (cg_in,{})
    then (Codegen.cEmptyFunction,cg_in);
    case (cg_in,v::vs) equation
      (cfunc,cg_out) = generateExternalObjectConstructorAliases2(cg_in,vs);
      (cfunc2,cg_out) = generateExternalObjectConstructorAlias(cg_out,v);
      cfunc = Codegen.cMergeFns({cfunc2,cfunc});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorAliases2;

protected function generateExternalObjectConstructorAlias
"Help function to generateExternalObjectConstructorAliases"
	input Integer cg_in;
  input DAELow.Var var;
  output CFunction outCFunction;
  output Integer cg_out;
  algorithm
    (outCFunction,cg_out) := matchcontinue (cg_in,var)

	  // 	external object aliased to another external object.
	  case (cg_in, DAELow.VAR(varName= name,bindExp = SOME(DAE.CREF(cr,_)),varKind = DAELow.EXTOBJ(path1)))
	    local String stmt,v_str,v_str2;
	      Codegen.CFunction cfunc;
	      DAE.ComponentRef cr,name;
	      Absyn.Path path1;
	   equation
	     v_str = Exp.printComponentRefStr(name);
	     v_str2 = Exp.printComponentRefStr(cr);
	     stmt = Util.stringAppendList({v_str," = ",v_str2,";"});
	     cfunc = Codegen.cAddStatements(Codegen.cEmptyFunction,{stmt});
	     then (cfunc,cg_in);
	       // Skip non-aliases constructors.
	  case (cg_in,_) then (Codegen.cEmptyFunction,cg_in);
    end matchcontinue;
end generateExternalObjectConstructorAlias;

protected function generateExternalObjectConstructorCall "help function to generateExternalObjectConstructorCalls"
  input Integer cg_in;
  input DAELow.Var var;
	input DAELow.ExternalObjectClasses eclasses;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
	(outCFunction,cg_out) := matchcontinue (cg_in,var,eclasses)

		// Skip aliases now, they are handled in generateExternalObjectConstructorAlias
	  case (cg_in, DAELow.VAR(bindExp = SOME(DAE.CREF(_,_)),varKind = DAELow.EXTOBJ(_)),_)
	  then (Codegen.cEmptyFunction,cg_in);

	  case (_,DAELow.VAR(varName = name),{})
	    local DAE.ComponentRef name;
	    equation
	    print("generateExternalObjectConstructorCall for var:");
	    print(Exp.printComponentRefStr(name));print(" failed\n");
	     then fail();

		// found class
	  case (cg_in,DAELow.VAR(varName = name,bindExp = SOME(e),varKind = DAELow.EXTOBJ(path1)), DAELow.EXTOBJCLASS(path=path2,constructor=constr)::_)
	    local
	      DAE.Element constr;
	      DAE.ComponentRef name;
	      Absyn.Path path1,path2;
	      DAE.Exp e;
	      Codegen.CFunction cfunc;
	    equation
	      true = ModUtil.pathEqual(path1,path2);
	      (cfunc,cg_out) = generateExternalObjectConstructorCall2(cg_in,name,constr,e);
	      then (cfunc,cg_out);
	  // Try next class.
	  case (cg_in,var,_::eclasses)
	    local
	      Codegen.CFunction cfunc;
	    equation
	    (cfunc,cg_out) = generateExternalObjectConstructorCall(cg_in,var,eclasses);
	    then (cfunc,cg_out);

  end matchcontinue;
end generateExternalObjectConstructorCall;

protected function generateExternalObjectConstructorCall2 "Help funciton to generateExternalObjectConstructorCall"
	input Integer cg_in;
  input DAE.ComponentRef varName;
  input DAE.Element constructor;
  input DAE.Exp constrCallExp;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out) := matchcontinue(cg_in,varName,constructor,constrCallExp)
    case (cg_in,varName,constructor as
          DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(ident=funcStr))}),DAE.CALL(expLst = args))
      local
        String vStr,funcStr,argsStr,str;
        list<DAE.Exp> args;
        list<String> vars1;
        Codegen.CFunction cfunc;
      equation
        vStr = Exp.printComponentRefStr(varName);
        /* TODO: cfn1 might contain additional code  that is needed, also 0 must be propagated to prevent
        resuing same variable name */
        (cfunc,vars1,cg_out) = Codegen.generateExpressions(args, cg_in, Codegen.extContext);
        argsStr = Util.stringDelimitList(vars1,", ");
        str = Util.stringAppendList({"    ",vStr," = ",funcStr,"(",argsStr,");"});
        cfunc = Codegen.cAddStatements(cfunc,{str});
      then (cfunc,cg_out);
  end matchcontinue;
end generateExternalObjectConstructorCall2;

protected function generateInitializeDeinitializationDataStruc
"generates initializeDataStruc
 to allocate all the different vectors i a DATA-struc"
  input DAELow.DAELow daelow;
  output String outString "resulting C code";
  protected Codegen.CFunction extObjDestructors,extObjConstructors,extObjConstructorAliases;
  String extObjDestructors_str,extObjConstructors_str;
  String extObjDestructorsDecl_str,extObjConstructorsDecl_str,extObjConstructorAliases_str;
  Integer cg_out;
algorithm
	(extObjDestructors,cg_out) := generateExternalObjectDestructorCalls(0,daelow);
	(extObjConstructors,cg_out):= generateExternalObjectConstructorCalls(cg_out,daelow);
	(extObjConstructorAliases,cg_out):= generateExternalObjectConstructorAliases(cg_out,daelow);
	extObjDestructors_str := Codegen.cPrintStatements(extObjDestructors);
  extObjConstructors_str := Codegen.cPrintStatements(extObjConstructors);
  extObjConstructorAliases_str := Codegen.cPrintStatements(extObjConstructorAliases);
  extObjDestructorsDecl_str := Codegen.cPrintDeclarations(extObjDestructors);
  extObjConstructorsDecl_str := Codegen.cPrintDeclarations(extObjConstructors);
  // Aliases has no declarations, skip printing them
  outString:=Util.stringAppendList({"
void setLocalData(DATA* data)\n{
   localData = data;\n}\n
DATA* initializeDataStruc(DATA_FLAGS flags)\n{",
extObjDestructorsDecl_str,
extObjConstructorsDecl_str,"
  DATA* returnData = (DATA*)malloc(sizeof(DATA));

  if(!returnData) //error check
    return 0;

  memset(returnData,0,sizeof(DATA));
  returnData->nStates = NX;
  returnData->nAlgebraic = NY;
  returnData->nParameters = NP;
  returnData->nInputVars = NI;
  returnData->nOutputVars = NO;
  returnData->nZeroCrossing = NG;
  returnData->nInitialResiduals = NR;
  returnData->nHelpVars = NHELP;
  returnData->stringVariables.nParameters = NPSTR;
  returnData->stringVariables.nAlgebraic = NYSTR;\n","
  if(flags & STATES && returnData->nStates) {
    returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStates = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStates2 = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->states&&returnData->oldStates&&returnData->oldStates2);
    memset(returnData->states,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStates,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStates2,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->states = 0;
    returnData->oldStates = 0;
    returnData->oldStates2 = 0;
  }\n","
  if(flags & STATESDERIVATIVES && returnData->nStates) {
    returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStatesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->oldStatesDerivatives2 = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->statesDerivatives&&returnData->oldStatesDerivatives&&returnData->oldStatesDerivatives2);
    memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStatesDerivatives,0,sizeof(double)*returnData->nStates);
    memset(returnData->oldStatesDerivatives2,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->statesDerivatives = 0;
    returnData->oldStatesDerivatives = 0;
    returnData->oldStatesDerivatives2 = 0;
  }\n","
  if(flags & HELPVARS && returnData->nHelpVars) {
    returnData->helpVars = (double*) malloc(sizeof(double)*returnData->nHelpVars);
    assert(returnData->helpVars);
    memset(returnData->helpVars,0,sizeof(double)*returnData->nHelpVars);
  } else {
    returnData->helpVars = 0;
  }\n","
  if(flags & ALGEBRAICS && returnData->nAlgebraic) {
    returnData->algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->oldAlgebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->oldAlgebraics2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    assert(returnData->algebraics&&returnData->oldAlgebraics&&returnData->oldAlgebraics2);
    memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->oldAlgebraics,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->oldAlgebraics2,0,sizeof(double)*returnData->nAlgebraic);
  } else {
    returnData->algebraics = 0;
    returnData->oldAlgebraics = 0;
    returnData->oldAlgebraics2 = 0;
    returnData->stringVariables.algebraics = 0;
  }\n","
  if (flags & ALGEBRAICS && returnData->stringVariables.nAlgebraic) {
    returnData->stringVariables.algebraics = (char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);
    assert(returnData->stringVariables.algebraics);
    memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);
  } else {
    returnData->stringVariables.algebraics=0;
  }\n","
  if(flags & PARAMETERS && returnData->nParameters) {
    returnData->parameters = (double*) malloc(sizeof(double)*returnData->nParameters);
    assert(returnData->parameters);
    memset(returnData->parameters,0,sizeof(double)*returnData->nParameters);
  } else {
    returnData->parameters = 0;
  }\n","
  if (flags & PARAMETERS && returnData->stringVariables.nParameters) {
  	  returnData->stringVariables.parameters = (char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);
      assert(returnData->stringVariables.parameters);
      memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);
  } else {
      returnData->stringVariables.parameters=0;
  }\n","
  if(flags & OUTPUTVARS && returnData->nOutputVars) {
    returnData->outputVars = (double*) malloc(sizeof(double)*returnData->nOutputVars);
    assert(returnData->outputVars);
    memset(returnData->outputVars,0,sizeof(double)*returnData->nOutputVars);
  } else {
    returnData->outputVars = 0;
  }\n","
  if(flags & INPUTVARS && returnData->nInputVars) {
    returnData->inputVars = (double*) malloc(sizeof(double)*returnData->nInputVars);
    assert(returnData->inputVars);
    memset(returnData->inputVars,0,sizeof(double)*returnData->nInputVars);
  } else {
    returnData->inputVars = 0;
  }\n","
  if(flags & INITIALRESIDUALS && returnData->nInitialResiduals) {
    returnData->initialResiduals = (double*) malloc(sizeof(double)*returnData->nInitialResiduals);
    assert(returnData->initialResiduals);
    memset(returnData->initialResiduals,0,sizeof(double)*returnData->nInitialResiduals);
  } else {
    returnData->initialResiduals = 0;
  }\n","
  if(flags & INITFIXED) {
    returnData->initFixed = init_fixed;
  } else {
    returnData->initFixed = 0;
  }\n","
  /*   names   */
  if(flags & MODELNAME) {
    returnData->modelName = model_name;
  } else {
    returnData->modelName = 0;
  }

  if(flags & STATESNAMES) {
    returnData->statesNames = state_names;
  } else {
    returnData->statesNames = 0;
  }\n","
  if(flags & STATESDERIVATIVESNAMES) {
    returnData->stateDerivativesNames = derivative_names;
  } else {
    returnData->stateDerivativesNames = 0;
  }\n","
  if(flags & ALGEBRAICSNAMES) {
    returnData->algebraicsNames = algvars_names;
  } else {
    returnData->algebraicsNames = 0;
  }\n","
  if(flags & PARAMETERSNAMES) {
    returnData->parametersNames = param_names;
  } else {
    returnData->parametersNames = 0;
  }\n","
  if(flags & INPUTNAMES) {
    returnData->inputNames = input_names;
  } else {
    returnData->inputNames = 0;
  }\n","
  if(flags & OUTPUTNAMES) {
    returnData->outputNames = output_names;
  } else {
    returnData->outputNames = 0;
  }\n","
  /*   comments  */
  if(flags & STATESCOMMENTS) {
    returnData->statesComments = state_comments;
  } else {
    returnData->statesComments = 0;
  }\n","
  if(flags & STATESDERIVATIVESCOMMENTS) {
    returnData->stateDerivativesComments = derivative_comments;
  } else {
    returnData->stateDerivativesComments = 0;
  }\n","
  if(flags & ALGEBRAICSCOMMENTS) {
    returnData->algebraicsComments = algvars_comments;
  } else {
    returnData->algebraicsComments = 0;
  }\n","
  if(flags & PARAMETERSCOMMENTS) {
    returnData->parametersComments = param_comments;
  } else {
    returnData->parametersComments = 0;
  }\n","
  if(flags & INPUTCOMMENTS) {
    returnData->inputComments = input_comments;
  } else {
    returnData->inputComments = 0;
  }\n","
  if(flags & OUTPUTCOMMENTS) {
    returnData->outputComments = output_comments;
  } else {
    returnData->outputComments = 0;
  }\n","
  if (flags & EXTERNALVARS) {
    returnData->extObjs = (void**)malloc(sizeof(void*)*NEXT);
    if (!returnData->extObjs) {
      printf(\"error allocating external objects\\n\");
      exit(-2);
    }
    memset(returnData->extObjs,0,sizeof(void*)*NEXT);
    setLocalData(returnData); /* must be set since used by constructors*/\n",
  extObjConstructors_str,
  extObjConstructorAliases_str,"  }
  return returnData;
}\n","
void deInitializeDataStruc(DATA* data, DATA_FLAGS flags)
{
  if(!data)
    return;

  if(flags & STATES && data->states) {
    free(data->states);
    data->states = 0;
  }\n","
  if(flags & STATESDERIVATIVES && data->statesDerivatives) {
    free(data->statesDerivatives);
    data->statesDerivatives = 0;
  }\n","
  if(flags & ALGEBRAICS && data->algebraics) {
    free(data->algebraics);
    data->algebraics = 0;
  }\n","
  if(flags & PARAMETERS && data->parameters) {
    free(data->parameters);
    data->parameters = 0;
  }\n","
  if(flags & OUTPUTVARS && data->inputVars) {
    free(data->inputVars);
    data->inputVars = 0;
  }\n","
  if(flags & INPUTVARS && data->outputVars) {
    free(data->outputVars);
    data->outputVars = 0;
  }

  if(flags & INITIALRESIDUALS && data->initialResiduals){
    free(data->initialResiduals);
    data->initialResiduals = 0;
  }
  if (flags & EXTERNALVARS && data->extObjs) {\n",extObjDestructors_str,
  "    free(data->extObjs);\n    data->extObjs = 0;
  }
}\n"});
end generateInitializeDeinitializationDataStruc;

protected function generateAttrVector
"author: PA
  Generates a vector, attr[nx+ny+np] where attributes  of variables are stored
  It is collected for states, variables and parameters.
  The information is encoded as:
  1 - Real
  2 - String
  4 - Integer
  8 - Boolean
  16 - discrete time variable"
  input DAELow.DAELow daelow;
  input Integer nx "number of states";
  input Integer ny "number of alg. vars";
  input Integer np "number of parameters";
  output String c_code "resulting C code";
algorithm
  outString:=
  matchcontinue (daelow,nx,ny,np)
    local
      Integer arr_size,nx,ny,np;
      String[:] str_arr,str_arr1,str_arr2;
      list<String> str_lst;
      String str,res;
      DAELow.DAELow dae;
    case (dae,nx,ny,np)
      equation
        arr_size = Util.listReduce({nx,ny,np}, int_add);
        str_arr = fill("0", arr_size);
        str_arr1 = generateAttrVectorType(dae, str_arr, nx, ny, np);
        str_arr2 = generateAttrVectorDiscrete(dae, str_arr1, nx, ny, np);
        str_lst = arrayList(str_arr1);
        str = Util.stringDelimitListAndSeparate(str_lst, ", ", "\n", 3);
        res = Util.stringAppendList({"char var_attr[NX+NY+NP]={",str,"};\n"});
      then
        res;
    case (dae,nx,ny,np)
      equation
        print("SimCodegen.generateAttrVector failed\n");
      then
        fail();
  end matchcontinue;
end generateAttrVector;

protected function generateAttrVectorType
"author: PA
  Helper function to generateAttrVector. Generates the value for the type of v,
  see generateAttrVector."
  input DAELow.DAELow inDAELow1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELow1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      list<DAELow.Var> v_lst,kv_lst;
      String[:] str_arr1,str_arr2,str_arr;
      DAELow.Variables v,kv;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = v,knownVars = kv),str_arr,nx,ny,np) /* nx ny np */
      equation
        v_lst = DAELow.varList(v);
        kv_lst = DAELow.varList(kv);
        str_arr1 = generateAttrVectorType2(v_lst, str_arr, nx, ny, np);
        str_arr2 = generateAttrVectorType2(kv_lst, str_arr1, nx, ny, np);
      then
        str_arr1;
  end matchcontinue;
end generateAttrVectorType;

protected function generateAttrVectorType2
"author: PA
  Helper function to generateAttrVectorType"
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELowVarLst1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      String[:] str_arr,str_arr_1,str_arr_2;
      DAELow.Var v;
      list<DAELow.Var> vs;
      Integer nx,ny,np,indx,off,indx_1,varTypeInt;
      DAELow.VarKind kind;
      DAELow.Type varType;
      String value,name;
    case ({},str_arr,_,_,_) then str_arr;  /* nx ny np */
    case ((v :: vs),str_arr,nx,ny,np) /* skip constants */
      equation
        DAELow.CONST() = DAELow.varKind(v);
        str_arr_1 = generateAttrVectorType2(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np) /* skip strings */
      equation
        DAELow.STRING() = DAELow.varType(v);
        str_arr_1 = generateAttrVectorType2(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        kind = DAELow.varKind(v);
        indx = DAELow.varIndex(v);
        (indx >= 0) = true;
        off = calcAttrOffset(kind, nx, ny, np);
        indx_1 = off + indx;
        varType = DAELow.varType(v);
        name = DAELow.varOrigName(v);
        varTypeInt = vartypeAttrInt(varType);
        value = intString(varTypeInt);
        value = Util.stringAppendList({"/*",name,":*/",value});
        str_arr_1 = arrayUpdate(str_arr, indx_1 + 1, value);
        str_arr_2 = generateAttrVectorType2(vs, str_arr_1, nx, ny, np);
      then
        str_arr_2;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        print("SimCodegen.generateAttrVectorType2 failed\n");
      then
        fail();
  end matchcontinue;
end generateAttrVectorType2;

protected function vartypeAttrInt
"function vartypeAttrInt
  helper function to generateAttrVectorType2
  calculates the int value of the type of a variable (1 .. 8)"
input DAELow.Type tp;
output Integer res;
algorithm
  res := matchcontinue (tp)
		  case DAELow.REAL() then 1;
	  	case DAELow.STRING() then 2;
	  	case DAELow.INT() then 4;
	  	case DAELow.BOOL() then 8;
  		case DAELow.ENUMERATION(_) then 4;
	  end matchcontinue;
end vartypeAttrInt;

protected function varDiscreteAttrInt
"helper function to generateAttrVectorDiscrete2
 calculates the int value of the variability of a variable.
  0 - continuous time variable
 16 - discrete time variable."
input DAELow.Type tp;
input DAELow.VarKind kind;
output Integer res;
algorithm
  res := matchcontinue (tp,kind)
	  	case (DAELow.REAL(),DAELow.DISCRETE()) then 16;
	  	case (_,DAELow.DISCRETE()) then 16;
	  	case (DAELow.INT(),_) then 16;
	  	case (DAELow.BOOL(),_) then 16;
  		case (DAELow.ENUMERATION(_),_) then 16;
  		case (_,_) then 0;
	  end matchcontinue;
end varDiscreteAttrInt;

protected function generateAttrVectorDiscrete
"author: PA
  Helper function to generateAttrVector. Generates the value for discrete flag,
  see generateAttrVector."
  input DAELow.DAELow inDAELow1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELow1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      list<DAELow.Var> v_lst,kv_lst;
      String[:] str_arr1,str_arr2,str_arr;
      DAELow.Variables v,kv;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = v,knownVars = kv),str_arr,nx,ny,np) /* nx ny np */
      equation
        v_lst = DAELow.varList(v);
        kv_lst = DAELow.varList(kv);
        str_arr1 = generateAttrVectorDiscrete2(v_lst, str_arr, nx, ny, np);
        str_arr2 = generateAttrVectorDiscrete2(kv_lst, str_arr1, nx, ny, np);

      then
        str_arr2;
  end matchcontinue;
end generateAttrVectorDiscrete;

protected function generateAttrVectorDiscrete2
"author: PA
  Helper function to generateAttrVectorType"
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELowVarLst1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      String[:] str_arr,str_arr_1,str_arr_2;
      DAELow.Var v;
      list<DAELow.Var> vs;
      Integer nx,ny,np,indx,off,indx_1,varTypeInt;
      DAELow.VarKind kind;
      DAELow.Type varType;
      DAELow.VarKind varKind;
      String value,name,oldVal;
    case ({},str_arr,_,_,_) then str_arr;  /* nx ny np */
    case ((v :: vs),str_arr,nx,ny,np) /* skip constants */
      equation
        DAELow.CONST() = DAELow.varKind(v);
        str_arr_1 = generateAttrVectorType2(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np) /* skip strings */
      equation
        DAELow.STRING() = DAELow.varType(v);
        str_arr_1 = generateAttrVectorType2(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        kind = DAELow.varKind(v);
        indx = DAELow.varIndex(v);
        (indx >= 0) = true;
        off = calcAttrOffset(kind, nx, ny, np);
        indx_1 = off + indx;
        varType = DAELow.varType(v);
        varKind = DAELow.varKind(v);
        name = DAELow.varOrigName(v);
        varTypeInt = varDiscreteAttrInt(varType,varKind);
        value = intString(varTypeInt);
        oldVal = str_arr[indx_1+1];
        value = Util.stringAppendList({oldVal,"+",value});
        str_arr_1 = arrayUpdate(str_arr, indx_1 + 1, value);
        str_arr_2 = generateAttrVectorDiscrete2(vs, str_arr_1, nx, ny, np);
      then
        str_arr_2;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        print("generateAttrVectorDiscrete2 failed\n");
        // debug_print("variable:", v);
      then
        fail();
  end matchcontinue;
end generateAttrVectorDiscrete2;

protected function generateFixedVector
"function: generateFixedVector
  Generates a vector, fixed[nx+nx+ny+np] where the fixed attribute is stored
  It is collected for states, derivatives, variables and parameters."
  input DAELow.DAELow inDAELow1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow1,inInteger2,inInteger3,inInteger4)
    local
      Integer arr_size,nx,ny,np;
      String[:] str_arr,str_arr_1;
      list<String> str_lst;
      String str,res;
      DAELow.DAELow dae;
    case (dae,nx,ny,np) /* nx ny np */
      equation
        arr_size = Util.listReduce({nx,nx,ny,np}, int_add);
        str_arr = fill("1/*default*/", arr_size);
        str_arr_1 = generateFixedVector2(dae, str_arr, nx, ny, np);
        str_lst = arrayList(str_arr_1);
        str = Util.stringDelimitListAndSeparate(str_lst, ", ", "\n\t", 3);
        res = Util.stringAppendList({"static char init_fixed[NX+NX+NY+NP]={\n\t",str,"\n};\n"});
      then
        res;
    case (dae,nx,ny,np)
      equation
        print("SimCodegen.generateFixedVector failed\n");
      then
        fail();
  end matchcontinue;
end generateFixedVector;

protected function generateFixedVector2
"function: generateFixedVector2
  author: PA
  Helper function to generate_fixed_vector"
  input DAELow.DAELow inDAELow1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray:=
  matchcontinue (inDAELow1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      list<DAELow.Var> v_lst,kv_lst;
      String[:] str_arr_1,str_arr_2,str_arr;
      DAELow.Variables v,kv;
      DAELow.EquationArray ie;
      list<DAELow.Equation> ie_lst;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = v,knownVars = kv,initialEqs=ie),str_arr,nx,ny,np) /* nx ny np */
      equation
        v_lst = DAELow.varList(v);
        kv_lst = DAELow.varList(kv);
        ie_lst = DAELow.equationList(ie);

        /* If initial equations present and no variable or parameter has fixed = false, set states
        present in initial equations to fixed=false and issue warning. This will make "standard Modelica models"
        with initial equations work. */

        str_arr_1 = generateFixedVector3(v_lst, str_arr, nx, ny, np);
        str_arr_2 = generateFixedVector3(kv_lst, str_arr_1, nx, ny, np);
        str_arr_2 = generateFixedVectorDefault(str_arr_2,ie_lst,v_lst,kv_lst);
      then
        str_arr_2;
  end matchcontinue;
end generateFixedVector2;

protected function generateFixedVectorDefault "Help function to generateFixedVector2, sets fixed = false for all states
that are present in initial equations, iff no variables has fixed=false"
  input String[:] fixedArr;
  input list<DAELow.Equation> ieLst;
  input list<DAELow.Var> varLst;
  input list<DAELow.Var> knvarLst;
  output String[:] fixedArrOut;
algorithm
  fixedArrOut := matchcontinue(fixedArr,ieLst,varLst,knvarLst)
    local list<Boolean> fixedLst; Boolean noFalse;
      list<DAE.ComponentRef> crefs;
      String str;
      list<String> vars;
      /* No initial equations, do nothing */
    case(fixedArr,{},varLst,knvarLst) then fixedArr;

    case(fixedArr,ieLst,varLst,knvarLst) equation
      fixedLst = Util.listMap(listAppend(knvarLst,varLst),DAELow.varFixed);
      true = Util.boolAndList(fixedLst); /* No fixed = false */
      crefs = DAELow.equationsCrefs(ieLst);
      (fixedArr,vars) = generateFixedVectorDefault2(fixedArr,varLst,crefs);
      str = Util.stringDelimitList(vars,", ");
      Error.addMessage(Error.SETTING_FIXED_ATTRIBUTE,{str});
    then fixedArr;

      /* Has fixed = false, do nothing */
    case(fixedArr,ieLst,varLst,knvarLst) then fixedArr;
    end matchcontinue;
end generateFixedVectorDefault;

protected function generateFixedVectorDefault2 "Help function to generateFixedVectorDefault,
traverses all states and if state is present in crefs, set fixed=false"
  input String[:] fixedArr;
  input list<DAELow.Var> varLst;
  input list<DAE.ComponentRef> crefs;
  output String[:] fixedArrOut;
  output list<String> changedVars;
algorithm
  (fixedArrOut,changedVars) := matchcontinue(fixedArr,varLst,crefs)
    local DAELow.Var v; list<DAELow.Var> vs;
      Integer indx; DAE.ComponentRef cr; String crStr;
    case(fixedArr,v::vs,crefs) equation
      true = DAELow.isStateVar(v);
      cr = DAELow.varCref(v);
      _::_ = Util.listSelect1(crefs,cr,Exp.crefEqual);
      indx = DAELow.varIndex(v); // Should use calcFixedOffset, but kind is always state so we skip that
      fixedArr =  arrayUpdate(fixedArr, indx + 1, "0 /* changed due to init eqns */");
      (fixedArr,changedVars) = generateFixedVectorDefault2(fixedArr,vs,crefs);
      crStr = DAELow.varOrigName(v);
    then (fixedArr,crStr::changedVars);

    case(fixedArr,v::vs,crefs) equation
      (fixedArr,changedVars) = generateFixedVectorDefault2(fixedArr,vs,crefs);
    then (fixedArr,changedVars);
    case(fixedArr,{},_) then (fixedArr,{});
  end matchcontinue;
end generateFixedVectorDefault2;

protected function generateFixedVector3
"function: generateFixedVector3
  author: PA
  Helper function to generate_fixed_vector2"
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output String[:] outStringArray;
algorithm
  outStringArray := matchcontinue (inDAELowVarLst1,inStringArray2,inInteger3,inInteger4,inInteger5)
    local
      String[:] str_arr,str_arr_1,str_arr_2;
      DAELow.Var v;
      list<DAELow.Var> vs;
      Integer nx,ny,np,indx,off,indx_1;
      DAELow.VarKind kind;
      Boolean b;
      String value,name;
    case ({},str_arr,_,_,_) then str_arr;  /* nx ny np */
    case ((v :: vs),str_arr,nx,ny,np) /* skip constants */
      equation
        DAELow.CONST() = DAELow.varKind(v);
        str_arr_1 = generateFixedVector3(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np) /* skip strings */
      equation
        DAELow.STRING() = DAELow.varType(v);
        str_arr_1 = generateFixedVector3(vs, str_arr, nx, ny, np);
      then
        str_arr_1;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        kind = DAELow.varKind(v);
        indx = DAELow.varIndex(v);
        (indx >= 0) = true;
        off = calcFixedOffset(kind, nx, ny, np);
        indx_1 = off + indx;
        b = DAELow.varFixed(v);
        value = Util.if_(b, "1", "0");
        name = DAELow.varOrigName(v);
        value = Util.stringAppendList({value,"/*",name,"*/"});
        str_arr_1 = arrayUpdate(str_arr, indx_1 + 1, value);
        str_arr_2 = generateFixedVector3(vs, str_arr_1, nx, ny, np);
      then
        str_arr_2;
    case ((v :: vs),str_arr,nx,ny,np)
      equation
        print("generate_fixed_vector3 failed\n");
        // debug_print("variable:", v);
      then
        fail();
  end matchcontinue;
end generateFixedVector3;

protected function calcFixedOffset "function: calcFixedOffset
  author: PA

  Calculates the offset for a fixed attribute int the fixed vector.
  The attributes are stored in this order:
  {states, derivatives, alg. vars, parameters}.
"
  input DAELow.VarKind inVarKind1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVarKind1,inInteger2,inInteger3,inInteger4)
    local Integer nx,ny,np,offset;
    case (DAELow.STATE(),_,_,_) then 0;  /* nx ny np states offset: 0 */
    case (DAELow.VARIABLE(),nx,ny,np) then nx + nx;  /* algebraic variables offset: 2nx algebraic variables offset: 2nx */
    case (DAELow.DUMMY_DER(),nx,ny,np) then nx + nx;  /* algebraic variables offset: 2nx */
    case (DAELow.DUMMY_STATE(),nx,ny,np) then nx + nx;
    case (DAELow.DISCRETE(),nx,ny,np) then nx + nx;  /* algebraic variables offset: 2nx */
    case (DAELow.PARAM(),nx,ny,np) /* parameter offset: 2nx+ny */
      equation
        offset = Util.listReduce({nx,nx,ny}, int_add);
      then
        offset;
    case (DAELow.CONST(),nx,ny,np) /* constant offset: 2nx+ny NOTE: should not happend */
      equation
        offset = Util.listReduce({nx,nx,ny}, int_add);
      then
        offset;
    case (_,_,_,_)
      equation
        print("calc_fixed_offset failed\n");
      then
        fail();
  end matchcontinue;
end calcFixedOffset;

protected function calcAttrOffset "function: calcAttrOffset
  author: PA

  Calculates the offset for variable attributes int the varAttr vector.
  The attributes are stored in this order:
  {states, alg. vars, parameters}.
"
  input DAELow.VarKind inVarKind1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inVarKind1,inInteger2,inInteger3,inInteger4)
    local Integer nx,ny,np,offset;
    case (DAELow.STATE(),_,_,_) then 0;  /* nx ny np states offset: 0 */
    case (DAELow.VARIABLE(),nx,ny,np) then nx ;  /* algebraic variables offset: nx algebraic variables offset: 2nx */
    case (DAELow.DUMMY_DER(),nx,ny,np) then nx ;  /* algebraic variables offset: nx */
    case (DAELow.DUMMY_STATE(),nx,ny,np) then nx;
    case (DAELow.DISCRETE(),nx,ny,np) then nx;  /* algebraic variables offset: nx */
    case (DAELow.PARAM(),nx,ny,np) then nx+ny; /* parameter offset: nx+ny */
    case (DAELow.CONST(),nx,ny,np) then nx+ny; /* parameter offset: nx+ny */
    case (DAELow.CONST(),nx,ny,np) then nx+ny; /* constant offset: nx+ny NOTE: should not happend */
    case (_,_,_,_)
      equation
        print("calc_fixed_offset failed\n");
      then
        fail();
  end matchcontinue;
end calcAttrOffset;

protected function generateGlobalBufs
"function: generateGlobalBufs
  author: PA"
  output String res;
algorithm
  res := Util.stringAppendList({"static DATA* localData = 0;\n", "#define time localData->timeValue\n"});
end generateGlobalBufs;

protected function generateMacros
"function generateMacros
 generates the macros that are used in the code
 author: x02lucpo"
  output String retString;
algorithm
  retString := Util.stringAppendList({
          "#define DIVISION(a,b,c) ((b != 0) ? a / b : a / division_error(b,c))\n","\n","\n","int encounteredDivisionByZero = 0;\n",
          "double division_error(double b,const char* division_str)\n","{\n","  if(!encounteredDivisionByZero){\n",
          "    fprintf(stderr,\"ERROR: Division by zero in partial equation: %s.\\n\",division_str);\n",
          "    encounteredDivisionByZero = 1;\n","   }\n","   return b;\n",
          "}"});
end generateMacros;

protected function generateVarNamesAndComments
"function: generateVarNamesAndComments
  Generates an array of the original variable names."
  input DAELow.DAELow inDAELow1;
  input Integer inInteger2 "nx";
  input Integer inInteger3 "ny";
  input Integer inInteger4 "ni" ;
  input Integer inInteger5 "no - number outputs";
  input Integer inInteger6 "ni - number of inputs";
  input Integer inInteger7 "next - number of external objects";
  input Integer inInteger8 "num_stralg - number of string variables";
  input Integer inInteger9 "num_strparam - number of string parameters";
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELow1,inInteger2,inInteger3,inInteger4,inInteger5,inInteger6,inInteger7,inInteger8,inInteger9)
    local
      list<DAELow.Var> var_lst,knvar_lst,extvar_lst;
      String[:] state_arr,derivative_arr,algvar_arr,param_arr,state_comment_arr,derivative_comment_arr,algvar_comment_arr,param_comment_arr,strparam_arr,strparam_comment_arr,stralg_arr,stralg_comment_arr;
      Integer num_state_2,num_derivative_2,num_algvars_2,num_input_2,num_output_2,num_param_2;
      Integer num_var_names,num_var_names_1,nx,ny,ni,no,np,nys,nps,next,num_stralg,num_strparam;
      list<String> input_arr,input_comment_arr,output_arr,output_comment_arr,get_name_function_ifs,var_defines,var_defines_1,state_str_1,derivative_str_1,algvars_str_1,param_str_1,state_comment_str_1,derivative_comment_str_1,algvars_comment_str_1,param_comment_str_1;
      list<String> stralg_str_1,strparam_str_1,stralg_comment_str_1,strparam_comment_str_1;
      String get_name_function_ifs_1,state_str_2,derivative_str_2,algvars_str_2,input_str_2,output_str_2,param_str_2,state_comment_str_2,derivative_comment_str_2,algvars_comment_str_2,input_comment_str_2,output_comment_str_2,param_comment_str_2,var_names,var_names_1,state_str_3,der_str_3,algvar_str_3,inputvar_str_3,outputvar_str_3,paramvar_str_3,res,state_comment_lst_1,der_comment_lst_1,algvar_comment_lst_1,inputvar_comment_lst_1,outputvar_comment_lst_1,paramvar_comment_lst_1,res2,get_name_function,var_defines_str;
      String strparam_comment_str_2,stralg_comment_str_2,stralg_str_2,strparam_str_2,stralg_str_3,strparam_str_3;
      String strparam_comment_lst_1,stralg_comment_lst_1;
      DAELow.Variables vars,knvars,extvars;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,externalObjects = extvars),
      nx,ny,ni,no,np,next,nys,nps)
      equation
        var_lst = DAELow.varList(vars);
        knvar_lst = DAELow.varList(knvars);
        extvar_lst = DAELow.varList(extvars);
        state_arr = fill("\"state  ERROR\"", nx);
        derivative_arr = fill("\"derivative ERROR\"", nx);
        algvar_arr = fill("\"algvar ERROR\"", ny);
        param_arr = fill("\"param ERROR\"", np);
        //input_arr = array_create(ni,\"\") => input_arr  	array_create(no,\"\") => output_arr &" ;
        state_comment_arr = fill("\" ERROR\"", nx);
        derivative_comment_arr = fill("\" ERROR\"", nx);
        algvar_comment_arr = fill("\" ERROR\"", ny);
        param_comment_arr = fill("\" ERROR\"", np);
        stralg_arr = fill("\" stringalg ERROR\"", nys);
        stralg_comment_arr = fill("\" ERROR\"", nys);
        strparam_arr = fill("\" stringparam ERROR\"", nps);
        strparam_comment_arr = fill("\" ERROR\"", nps);

        /* Variable list*/
        (state_arr,state_comment_arr,num_state_2,derivative_arr,derivative_comment_arr,
          num_derivative_2,algvar_arr,algvar_comment_arr,num_algvars_2,input_arr,input_comment_arr,
          num_input_2,output_arr,output_comment_arr,num_output_2,param_arr,param_comment_arr,
          num_param_2,stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
          get_name_function_ifs,var_defines)
            = generateVarNamesAndComments2(var_lst, state_arr, state_comment_arr, 0, derivative_arr,
          		derivative_comment_arr, 0, algvar_arr, algvar_comment_arr, 0, {}, {}, 0, {}, {}, 0,
         		 param_arr, param_comment_arr, 0,
         		 stralg_arr,stralg_comment_arr,0,strparam_arr,strparam_comment_arr,0,
         		 {}, {})  ;

      /* Known variable list*/
        (state_arr,state_comment_arr,num_state_2,derivative_arr,derivative_comment_arr,
        	num_derivative_2,algvar_arr,algvar_comment_arr,num_algvars_2,input_arr,input_comment_arr,
        	num_input_2,output_arr,output_comment_arr,num_output_2,param_arr,param_comment_arr,
        	num_param_2,
        	stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
        	get_name_function_ifs_1,var_defines_1)
        = generateVarNamesAndComments2(knvar_lst, state_arr, state_comment_arr, num_state_2,
          derivative_arr, derivative_comment_arr, num_derivative_2, algvar_arr,
          algvar_comment_arr, num_algvars_2, input_arr, input_comment_arr, num_input_2,
          output_arr, output_comment_arr, num_output_2, param_arr, param_comment_arr,
          num_param_2,
          stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
          get_name_function_ifs, var_defines) ;

         /* External object list*/
          (state_arr,state_comment_arr,num_state_2,derivative_arr,derivative_comment_arr,
        	num_derivative_2,algvar_arr,algvar_comment_arr,num_algvars_2,input_arr,input_comment_arr,
        	num_input_2,output_arr,output_comment_arr,num_output_2,param_arr,param_comment_arr,
        	num_param_2,
        	stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
        	get_name_function_ifs_1,var_defines_1)
        = generateVarNamesAndComments2(extvar_lst, state_arr, state_comment_arr, num_state_2,
          derivative_arr, derivative_comment_arr, num_derivative_2, algvar_arr,
          algvar_comment_arr, num_algvars_2, input_arr, input_comment_arr, num_input_2,
          output_arr, output_comment_arr, num_output_2, param_arr, param_comment_arr,
          num_param_2,
          stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
          get_name_function_ifs_1, var_defines_1);
        num_state_2 = nx " TODO: CHECK THE RETURN TO BE THE SAME INSTEAD OF SETTING WITH let " ;
        num_derivative_2 = nx;
        num_algvars_2 = ny;
        num_output_2 = no;
        num_input_2 = ni;
        num_param_2 = np;
        num_stralg = nys;
        num_strparam = nps;

				// Generate array of variable names

        state_str_1 = arrayList(state_arr);
        derivative_str_1 = arrayList(derivative_arr);
        algvars_str_1 = arrayList(algvar_arr);
        param_str_1 = arrayList(param_arr) ;
				stralg_str_1 = arrayList(stralg_arr);
				strparam_str_1 = arrayList(strparam_arr);

        state_str_2 = Util.stringDelimitList(state_str_1, ", ");
        derivative_str_2 = Util.stringDelimitList(derivative_str_1, ", ");
        algvars_str_2 = Util.stringDelimitList(algvars_str_1, ", ");
        input_str_2 = Util.stringDelimitList(input_arr, ", ");
        output_str_2 = Util.stringDelimitList(output_arr, ", ");
        param_str_2 = Util.stringDelimitList(param_str_1, ", ");
        stralg_str_2 = Util.stringDelimitList(stralg_str_1, ", ");
        strparam_str_2 = Util.stringDelimitList(strparam_str_1, ", ");

        state_str_3 = generateCDeclForStringArray(stateNames, state_str_2, num_state_2);
        der_str_3 = generateCDeclForStringArray(derivativeNames, derivative_str_2, num_derivative_2);
        algvar_str_3 = generateCDeclForStringArray(algvarsNames, algvars_str_2, num_algvars_2);
        inputvar_str_3 = generateCDeclForStringArray(inputNames, input_str_2, num_input_2);
        outputvar_str_3 = generateCDeclForStringArray(outputNames, output_str_2, num_output_2);
        paramvar_str_3 = generateCDeclForStringArray(paramNames, param_str_2, num_param_2);
        stralg_str_3 = generateCDeclForStringArray(stringAlgNames, stralg_str_2, num_stralg);
        strparam_str_3 = generateCDeclForStringArray(stringParamNames, strparam_str_2, num_strparam);

        res = Util.stringAppendList(
          {state_str_3,der_str_3,algvar_str_3,inputvar_str_3,
          outputvar_str_3,paramvar_str_3,stralg_str_3,strparam_str_3});


				// Generate array of comment strings

        state_comment_str_1 = arrayList(state_comment_arr);
        derivative_comment_str_1 = arrayList(derivative_comment_arr);
        algvars_comment_str_1 = arrayList(algvar_comment_arr);
        param_comment_str_1 = arrayList(param_comment_arr) ;
				stralg_comment_str_1 = arrayList(stralg_comment_arr);
				strparam_comment_str_1 = arrayList(strparam_comment_arr);

        state_comment_str_2 = Util.stringDelimitList(state_comment_str_1, ", ");
        derivative_comment_str_2 = Util.stringDelimitList(derivative_comment_str_1, ", ");
        algvars_comment_str_2 = Util.stringDelimitList(algvars_comment_str_1, ", ");
        input_comment_str_2 = Util.stringDelimitList(input_comment_arr, ", ");
        output_comment_str_2 = Util.stringDelimitList(output_comment_arr, ", ");
        param_comment_str_2 = Util.stringDelimitList(param_comment_str_1, ", ");
        strparam_comment_str_2 = Util.stringDelimitList(strparam_comment_str_1, ", ");
        stralg_comment_str_2 = Util.stringDelimitList(stralg_comment_str_1, ", ");

  			state_comment_lst_1 = generateCDeclForStringArray(stateComments, state_comment_str_2, num_state_2);
        der_comment_lst_1 = generateCDeclForStringArray(derivativeComments, derivative_comment_str_2,
          num_derivative_2);
        algvar_comment_lst_1 = generateCDeclForStringArray(algvarsComments, algvars_comment_str_2, num_algvars_2);
        inputvar_comment_lst_1 = generateCDeclForStringArray(inputComments, input_comment_str_2, num_input_2);
        outputvar_comment_lst_1 = generateCDeclForStringArray(outputComments, output_comment_str_2, num_output_2);
        paramvar_comment_lst_1 = generateCDeclForStringArray(paramComments, param_comment_str_2, num_param_2);
        strparam_comment_lst_1 = generateCDeclForStringArray(stringParamComments, strparam_comment_str_2, num_strparam);
        stralg_comment_lst_1 = generateCDeclForStringArray(stringAlgComments, stralg_comment_str_2, num_stralg);

				res2 = Util.stringAppendList(
          {state_comment_lst_1,der_comment_lst_1,algvar_comment_lst_1,
          inputvar_comment_lst_1,outputvar_comment_lst_1,paramvar_comment_lst_1,strparam_comment_lst_1,stralg_comment_lst_1});

      	// generate #defines for each variable

        get_name_function_ifs_1 = Util.stringAppendList(get_name_function_ifs_1) "generate getName function" ;
        get_name_function = Util.stringAppendList(
          {"char* getName( double* ",paramInGetNameFunction,")\n",
          "{\n",get_name_function_ifs_1,"  return \"\";\n}\n\n"});
        var_defines_str = Util.stringAppendList(var_defines_1);
      then
        {res,res2,/*var_names_1,"char** varnames=&varnamesbuf[0];\n",*/
          var_defines_str,get_name_function};
  end matchcontinue;
end generateVarNamesAndComments;

protected function generateCDeclForStringArray
"function generateCDeclForStringArray
 author x02lucpo
 generates a static C-array with char <name>{<number>}
 or only a char depending it the int parameters is > 0"
  input String inString1;
  input String inString2;
  input Integer inInteger3;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inString2,inInteger3)
    local
      String res,array_name,number_of_strings_str,array_str;
      Integer number_of_strings;
    case (array_name,_,number_of_strings)
      equation
        (number_of_strings == 0) = true;
        res = Util.stringAppendList({"char* ",array_name,"[1] = {\"\"};\n"});
      then
        res;
    case (array_name,array_str,number_of_strings)
      equation
        number_of_strings_str = intString(number_of_strings);
        res = Util.stringAppendList({"char* ",array_name,"[",number_of_strings_str,"]={",array_str,"};\n"});
      then
        res;
  end matchcontinue;
end generateCDeclForStringArray;

protected function generateVarNamesAndComments2
"function: generateVarNamesAndComments2
  Helper function to generate_var_names_and_comments2"
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input Integer inInteger4;
  input String[:] inStringArray5;
  input String[:] inStringArray6;
  input Integer inInteger7;
  input String[:] inStringArray8;
  input String[:] inStringArray9;
  input Integer inInteger10;
  input list<String> inStringLst11;
  input list<String> inStringLst12;
  input Integer inInteger13;
  input list<String> inStringLst14;
  input list<String> inStringLst15;
  input Integer inInteger16;
  input String[:] inStringArray17;
  input String[:] inStringArray18;
  input Integer inInteger19;
  input String[:] inStrAlgArr;
  input String[:] inStrAlgArrCmt;
  input Integer inNumStrAlg;
  input String[:] inStrParamArr;
  input String[:] inStrParamArrCmt;
  input Integer inNumStrParam;

  input list<String> inStringLst20;
  input list<String> inStringLst21;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output Integer outInteger3;
  output String[:] outStringArray4;
  output String[:] outStringArray5;
  output Integer outInteger6;
  output String[:] outStringArray7;
  output String[:] outStringArray8;
  output Integer outInteger9;
  output list<String> outStringLst10;
  output list<String> outStringLst11;
  output Integer outInteger12;
  output list<String> outStringLst13;
  output list<String> outStringLst14;
  output Integer outInteger15;
  output String[:] outStringArray16;
  output String[:] outStringArray17;
  output Integer outInteger18;
  output String[:] outStrAlgArr;
  output  String[:] outStrAlgArrCmt;
  output Integer outNumStrAlg;
  output String[:] outStrParamArr;
  output String[:] outStrParamArrCmt;
  output Integer outNumStrParam;
  output list<String> outStringLst19;
  output list<String> outStringLst20;
algorithm
  (outStringArray1,outStringArray2,outInteger3,outStringArray4,outStringArray5,outInteger6,outStringArray7,outStringArray8,outInteger9,outStringLst10,outStringLst11,outInteger12,outStringLst13,outStringLst14,outInteger15,outStringArray16,outStringArray17,outInteger18,
  outStrAlgArr,outStrAlgArrCmt,outNumStrAlg,outStrParamArr,outStrParamArrCmt,outNumStrParam,outStringLst19,outStringLst20):=
  matchcontinue (inDAELowVarLst1,inStringArray2,inStringArray3,inInteger4,inStringArray5,inStringArray6,inInteger7,inStringArray8,inStringArray9,inInteger10,inStringLst11,inStringLst12,inInteger13,inStringLst14,inStringLst15,inInteger16,inStringArray17,inStringArray18,inInteger19,
      outStrAlgArr,outStrAlgArrCmt,outNumStrAlg,outStrParamArr,outStrParamArrCmt,outNumStrParam,inStringLst20,inStringLst21)
    local
      String[:] state_str,stateComments,derivative_str,derivativeComments,algvars_str,algvarsComments,param_str,paramComments,state_str_1,state_comments_1,derivative_str_1,derivative_comments_1,algvars_str_1,algvars_comments_1,param_str_1,param_comments_1,state_str_2,state_comments_2,derivative_str_2,derivative_comments_2,algvars_str_2,algvars_comments_2,param_str_2,param_comments_2;
			String[:] stralg_comment_arr,stralg_arr,strparam_comment_arr,strparam_arr;
      Integer num_state,num_derivative,num_algvars,num_input,num_output,num_param,num_state_1,num_derivative_1,num_algvars_1,num_input_1,num_output_1,num_param_1,num_state_2,num_derivative_2,num_algvars_2,num_input_2,num_output_2,num_param_2,indx;
      list<String> input_str,inputComments,output_str,outputComments,get_name_function_ifs,var_defines,input_str_1,input_comments_1,output_str_1,output_comments_1,get_name_function_ifs_1,var_defines_1,get_name_function_ifs1,var_defines1,get_name_function_ifs2,var_defines2,input_str_2,input_comments_2,get_name_function_ifs3,var_defines3,output_str_2,output_comments_2,get_name_function_ifs4,var_defines4,get_name_function_ifs5,var_defines5, var_defines6;
      DAELow.Var var;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> value;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> vs;
      Integer num_stralg,num_strparam;
    case ({},state_str,stateComments,num_state,derivative_str,derivativeComments,num_derivative,
      algvars_str,algvarsComments,num_algvars,input_str,inputComments,num_input,output_str,
      outputComments,num_output,param_str,paramComments,num_param,
      stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
      get_name_function_ifs,var_defines)
       then
         (state_str,stateComments,num_state,derivative_str,derivativeComments,num_derivative,
             algvars_str,algvarsComments,num_algvars,input_str,inputComments,num_input,output_str,
             outputComments,num_output,param_str,paramComments,num_param,
             stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
             get_name_function_ifs,var_defines);

    case (((var as DAELow.VAR(cr,kind,dir,_, _,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) :: vs),
      	state_str,stateComments,num_state,derivative_str,derivativeComments,num_derivative,algvars_str,
      	algvarsComments,num_algvars,input_str,inputComments,num_input,output_str,outputComments,
      	num_output,param_str,paramComments,num_param,
      	stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
        get_name_function_ifs,var_defines)
      equation
        /* Recursive call*/
        (state_str_1,state_comments_1,num_state_1,derivative_str_1,derivative_comments_1,num_derivative_1,
        algvars_str_1,algvars_comments_1,num_algvars_1,input_str_1,input_comments_1,num_input_1,output_str_1,
        output_comments_1,num_output_1,param_str_1,param_comments_1,num_param_1,
        stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
        get_name_function_ifs_1, var_defines_1)
        = generateVarNamesAndComments2(vs, state_str, stateComments, num_state, derivative_str,
          derivativeComments, num_derivative, algvars_str, algvarsComments, num_algvars,
          input_str, inputComments, num_input, output_str, outputComments, num_output,
          param_str, paramComments, num_param, stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,
          strparam_comment_arr,num_strparam,get_name_function_ifs, var_defines) ;

        /* States and derivatives*/
        (state_str_2,state_comments_2,derivative_str_2,derivative_comments_2,num_state_2,
        get_name_function_ifs1,var_defines1)
        = generateVarNamesAndCommentsStatesAndDerivat(var, state_str_1, state_comments_1, derivative_str_1,
          derivative_comments_1, num_state_1, get_name_function_ifs_1, var_defines_1) "generate STATE names generate DERIVATIVES names because the same combination of var_kind and direction" ;
        num_derivative_2 = num_state_2;

        /* Algebraic variables*/
        (algvars_str_2,algvars_comments_2,num_algvars_2,stralg_arr,stralg_comment_arr,num_stralg,get_name_function_ifs2,var_defines2)
        	= generateVarNamesAndCommentsAlgvars(var, algvars_str_1, algvars_comments_1, num_algvars_1,
        	stralg_arr,stralg_comment_arr,num_stralg,
         	 get_name_function_ifs1, var_defines1) "generate ALGVARS names" ;

         	 /* INPUT variables*/
        (input_str_2,input_comments_2,num_input_2,get_name_function_ifs3,var_defines3)
        	= generateVarNamesAndCommentsInputs(var, input_str_1, input_comments_1, num_input_1,
         	 get_name_function_ifs2, var_defines2) "generate INPUTS names" ;

         	 /* Output variables*/
        (output_str_2,output_comments_2,num_output_2,get_name_function_ifs4,var_defines4)
        	= generateVarNamesAndCommentsOutputs(var, output_str_1, output_comments_1, num_output_1,
          get_name_function_ifs3, var_defines3) "generate OUTPUT names" ;

        /* Parameters */
        (param_str_2,param_comments_2,num_param_2,
          strparam_arr,strparam_comment_arr,num_strparam,
          get_name_function_ifs5,var_defines5)
        	= generateVarNamesAndCommentsParams(var, param_str_1, param_comments_1, num_param_1,
						strparam_arr,strparam_comment_arr,num_strparam, get_name_function_ifs4, var_defines4);

        /* External Objects*/
        (_,_,_,_,var_defines6)
        	= generateVarNamesAndCommentsExtObjs(var, param_str_2, param_comments_2, num_param_2,
          get_name_function_ifs5, var_defines5) "generate PARAM names" ;
      then
        (state_str_2,state_comments_2,num_state_2,derivative_str_2,derivative_comments_2,
        num_derivative_2,algvars_str_2,algvars_comments_2,num_algvars_2,input_str_2,input_comments_2,
        num_input_2,output_str_2,output_comments_2,num_output_2,param_str_2,param_comments_2,num_param_2,
        stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,
        get_name_function_ifs5,var_defines6);

    case ((_ :: vs),state_str,stateComments,num_state,derivative_str,derivativeComments,num_derivative,algvars_str,algvarsComments,num_algvars,input_str,inputComments,num_input,output_str,outputComments,num_output,param_str,paramComments,num_param,stralg_arr,stralg_comment_arr,num_stralg,strparam_arr,strparam_comment_arr,num_strparam,get_name_function_ifs_1,var_defines)
      equation
        print("generate_var_names_and_comments2 failed \n");
      then
        fail();
  end matchcontinue;
end generateVarNamesAndComments2;

protected function generateGetnameFunctionIf
  input DAE.ComponentRef cr;
  input DAELow.Type tp;
  input Integer index;
  input String c_array_name;
  output String ret_str;
  String cr_str,index_str;
algorithm
  ret_str := matchcontinue(cr,tp,index,c_array_name)
  	// Strings require an extra cast.
    case (cr,DAELow.STRING(),index,c_array_name)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        index_str = intString(index);
        ret_str = Util.stringAppendList({"  if( (double*)(&",cr_str,") == ",paramInGetNameFunction,
            " ) return ",c_array_name,"[",index_str,"];\n"});
      then ret_str;
    case (cr,tp,index,c_array_name)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        index_str = intString(index);
        ret_str = Util.stringAppendList(
          {"  if( &",cr_str," == ",paramInGetNameFunction,
            " ) return ",c_array_name,"[",index_str,"];\n"});
      then ret_str;
	end matchcontinue;
end generateGetnameFunctionIf;

protected function generateGetnameFunctionIfForDerivatives
  input DAE.ComponentRef cr;
  input Integer index;
  input String c_array_name;
  output String ret_str;
  String cr_str,index_str;
algorithm
  cr_str := Exp.printComponentRefStr(cr);
  index_str := intString(index);
  ret_str := Util.stringAppendList(
          {"  if( &",DAELow.derivativeNamePrefix,cr_str," == ",
          paramInGetNameFunction," ) return ",c_array_name,"[",index_str,"];\n"});
end generateGetnameFunctionIfForDerivatives;

protected function generateVarNamesAndCommentsInputs
"function generateVarNamesAndCommentsInputs
  Checks and generates a comment and input for a input variable
  author x02lucpo"
  input DAELow.Var inVar1;
  input list<String> inStringLst2;
  input list<String> inStringLst3;
  input Integer inInteger4;
  input list<String> inStringLst5;
  input list<String> inStringLst6;
  output list<String> outStringLst1;
  output list<String> outStringLst2;
  output Integer outInteger3;
  output list<String> outStringLst4;
  output list<String> outStringLst5;
algorithm
  (outStringLst1,outStringLst2,outInteger3,outStringLst4,outStringLst5):=
  matchcontinue (inVar1,inStringLst2,inStringLst3,inInteger4,inStringLst5,inStringLst6)
    local
      String origname_str,name_1,comment,comment_1,if_str;
      Integer n_vars_1,indx,n_vars;
      DAELow.Var var;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> value;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<String> name_arr,comment_arr,get_name_function_ifs,var_defines;
      DAELow.Type tp;
    case ((var as DAELow.VAR(varName = cr,
                             varKind = kind,
                             varDirection = dir,
                             index = indx,
                             origVarName = origname,
                             values = dae_var_attr,
                             comment = comment,
                             flowPrefix = flowPrefix,
                             streamPrefix =  streamPrefix,
                             varType = tp)),name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines)
      /* the variable to checked the old number of variables generated
         get_name_function_ifs\' #define a$Pb x{1} name of the from \"a\"
         comment of the from \"a afhalk\" number of generated strings
         #define a$Pb x{1} */
      equation
        true = DAELow.isVarOnTopLevelAndInput(var);
        origname_str = Exp.printComponentRefStr(origname);
        name_1 = Util.stringAppendList({"\"",origname_str,"\""});
        comment = DAEUtil.dumpCommentOptionStr(comment);
        n_vars_1 = n_vars + 1;
        comment_1 = generateEmptyString(comment);
        if_str = generateGetnameFunctionIf(cr,tp, n_vars, inputNames) "no defines because the outputvars is a subset of algvars" ;
      then
        ((name_1 :: name_arr),(comment_1 :: comment_arr),n_vars_1,(if_str :: get_name_function_ifs),var_defines);

    case ((var as DAELow.VAR(varName = cr,
                             varKind = kind,
                             varDirection = dir,
                             index = indx,
                             origVarName = origname,
                             values = dae_var_attr,
                             comment = comment,
                             flowPrefix = flowPrefix,
                             streamPrefix = streamPrefix)),name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines)
      local Option<SCode.Comment> comment;
      then
        (name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines);
  end matchcontinue;
end generateVarNamesAndCommentsInputs;

protected function generateVarNamesAndCommentsOutputs
"function generateVarNamesAndCommentsOutputs
  Checks and generates a comment and input for a output variable
  author x02lucpo"
  input DAELow.Var inVar1;
  input list<String> inStringLst2;
  input list<String> inStringLst3;
  input Integer inInteger4;
  input list<String> inStringLst5;
  input list<String> inStringLst6;
  output list<String> outStringLst1;
  output list<String> outStringLst2;
  output Integer outInteger3;
  output list<String> outStringLst4;
  output list<String> outStringLst5;
algorithm
  (outStringLst1,outStringLst2,outInteger3,outStringLst4,outStringLst5):=
  matchcontinue (inVar1,inStringLst2,inStringLst3,inInteger4,inStringLst5,inStringLst6)
    local
      String origname_str,name_1,comment,comment_1,if_str;
      Integer n_vars_1,indx,n_vars;
      DAELow.Var var;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> value;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<String> name_arr,comment_arr,get_name_function_ifs,var_defines;
      DAELow.Type tp;

    case ((var as DAELow.VAR(varName = cr,
                             varKind = kind,
                             varDirection = dir,
                             index = indx,
                             origVarName = origname,
                             values = dae_var_attr,
                             comment = comment,
                             varType=tp,
                             flowPrefix = flowPrefix,
                             streamPrefix = streamPrefix)),name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines) /* the variable to checked the old number of variables generated name of the from \"a\" comment of the from \"a afhalk\" number of generated strings */
      equation
        true = DAELow.isVarOnTopLevelAndOutput(var);
        origname_str = Exp.printComponentRefStr(origname);
        name_1 = Util.stringAppendList({"\"",origname_str,"\""});
        comment = DAEUtil.dumpCommentOptionStr(comment);
        n_vars_1 = n_vars + 1;
        comment_1 = generateEmptyString(comment);
        if_str = generateGetnameFunctionIf(cr, tp,n_vars, outputNames) "no defines because the outputvars is a subset of algvars" ;
      then
        ((name_1 :: name_arr),(comment_1 :: comment_arr),n_vars_1,(if_str :: get_name_function_ifs),var_defines);

    case (DAELow.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     index = indx,
                     origVarName = origname,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix),name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines)
      local Option<SCode.Comment> comment;
      then
        (name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines);
  end matchcontinue;
end generateVarNamesAndCommentsOutputs;

protected function generateVarNamesAndCommentsAlgvars
"function generateVarNamesAndCommentsAlgvars
  author: x02lucpo
  Checks and generates a comment and input for a algvar variable"
  input DAELow.Var inVar1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input Integer inInteger4;
  input String[:] inAlgStrArr;
  input String[:] inAlgStrArrCmt;
  input Integer inNumAlgStr;
  input list<String> inStringLst5;
  input list<String> inStringLst6;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output Integer outInteger3;
  output String[:] outAlgStrArr;
  output String[:] outAlgStrArrCmt;
  output Integer outNumAlgStr;
  output list<String> outStringLst4;
  output list<String> outStringLst5;
algorithm
  (outStringArray1,outStringArray2,outInteger3,outAlgStrArr,outAlgStrArrCmt,outNumAlgStr,outStringLst4,outStringLst5):=
  matchcontinue (inVar1,inStringArray2,inStringArray3,inInteger4,inAlgStrArr,inAlgStrArrCmt,inNumAlgStr,inStringLst5,inStringLst6)
    local
      list<DAELow.VarKind> kind_lst;
      String origname_str,name_1,comment,comment_1,if_str,is,name,define_str,array_define;
      Integer n_vars_1,indx,n_vars;
      String[:] name_arr_1,comment_arr_1,name_arr,comment_arr,stralg_arr,stralg_comment_arr;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      list<DAE.Subscript> inst_dims;
      Option<DAE.Exp> value;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<String> get_name_function_ifs,var_defines;
      DAELow.Type typeVar;
      Integer num_stralg;
    /* String variables*/
    case (DAELow.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = typeVar as DAELow.STRING(),
                     arryDim = inst_dims,
                     index = indx,
                     origVarName = origname,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix),name_arr,comment_arr,n_vars,stralg_arr,stralg_comment_arr,num_stralg,get_name_function_ifs,var_defines)
      equation
        kind_lst = {DAELow.VARIABLE(),DAELow.DISCRETE(),DAELow.DUMMY_DER(),DAELow.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
        origname_str = Exp.printComponentRefStr(origname) "if this fails then the var is not added to list" ;
        name_1 = Util.stringAppendList({"\"",origname_str,"\""});
        comment = DAEUtil.dumpCommentOptionStr(comment);
        num_stralg = num_stralg + 1;
        comment_1 = generateEmptyString(comment);
        stralg_arr = arrayUpdate(stralg_arr, indx + 1, name_1);
        stralg_comment_arr = arrayUpdate(stralg_comment_arr, indx + 1, comment_1);
        if_str = generateGetnameFunctionIf(cr, typeVar,indx, stringAlgNames);
        is = intString(indx);
        name = Exp.printComponentRefStr(cr);
        define_str = generateNameDependentOnType("algebraics",typeVar);
        define_str = Util.stringAppendList({"#define ",name," localData->",define_str,"[",is,"]","\n"});
        array_define = generateArrayDefine(origname, inst_dims, indx, "localData->algebraics");
        define_str = stringAppend(define_str, array_define);
      then
        (name_arr,comment_arr,n_vars,stralg_arr,stralg_comment_arr,num_stralg,(if_str :: get_name_function_ifs),(define_str :: var_defines));

      /* Non-string variables*/
    case (DAELow.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     varType = typeVar,
                     arryDim = inst_dims,
                     index = indx,
                     origVarName = origname,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix),name_arr,comment_arr,n_vars,stralg_arr,stralg_comment_arr,num_stralg,get_name_function_ifs,var_defines)
      equation
        kind_lst = {DAELow.VARIABLE(),DAELow.DISCRETE(),DAELow.DUMMY_DER(),DAELow.DUMMY_STATE()};
        _ = Util.listGetMember(kind, kind_lst);
        origname_str = Exp.printComponentRefStr(origname) "if this fails then the var is not added to list" ;
        name_1 = Util.stringAppendList({"\"",origname_str,"\""});
        comment = DAEUtil.dumpCommentOptionStr(comment);
        n_vars_1 = n_vars + 1;
        comment_1 = generateEmptyString(comment);
        name_arr_1 = arrayUpdate(name_arr, indx + 1, name_1);
        comment_arr_1 = arrayUpdate(comment_arr, indx + 1, comment_1);
        if_str = generateGetnameFunctionIf(cr, typeVar,indx, algvarsNames);
        is = intString(indx);
        name = Exp.printComponentRefStr(cr);

        define_str = generateNameDependentOnType("algebraics",typeVar);

        define_str = Util.stringAppendList({"#define ",name," localData->",define_str,"[",is,"]","\n"});
        array_define = generateArrayDefine(origname, inst_dims, indx, "localData->algebraics");
        define_str = stringAppend(define_str, array_define);
      then
        (name_arr_1,comment_arr_1,n_vars_1,stralg_arr,stralg_comment_arr,num_stralg,(if_str :: get_name_function_ifs),(define_str :: var_defines));

    case (DAELow.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     index = indx,
                     origVarName = origname,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix),name_arr,comment_arr,n_vars,stralg_arr,stralg_comment_arr,num_stralg,get_name_function_ifs,var_defines)
      local Option<SCode.Comment> comment;
      then
        (name_arr,comment_arr,n_vars,stralg_arr,stralg_comment_arr,num_stralg,get_name_function_ifs,var_defines);
  end matchcontinue;
end generateVarNamesAndCommentsAlgvars;

protected function generateNameDependentOnType
"function: generateAlgebraicNameDependentOnType
  generates the name of the algebraic variable depending on type"
  input String baseName;
  input DAELow.Type inType;
  output String outString;
algorithm
  outString:=
  matchcontinue (baseName,inType)
    local
      String str;
      list<String> l;
      String baseArrayName;
    case (baseArrayName,DAELow.INT())
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
    case (baseArrayName,DAELow.REAL() )
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
    case (baseArrayName,DAELow.BOOL())
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
    case (baseArrayName,DAELow.STRING())
    equation
       str = Util.stringAppendList({"stringVariables",".",baseArrayName});
    then
       str;
//    case (baseArrayName,DAE.ENUM())
//    equation
//       str = Util.stringAppendList({baseArrayName,""});
//    then
//       str;
    case (baseArrayName,DAELow.ENUMERATION(stringLst = l))
      equation
//       print("generateNameDependentOnType - Enumeration not implemented yet\n");
       str = Util.stringAppendList({baseArrayName,""});
      then
//       fail();
       str;
    case (baseArrayName,DAELow.EXT_OBJECT(_) )
    equation
       str = Util.stringAppendList({baseArrayName,""});
    then
       str;
  end matchcontinue;
end generateNameDependentOnType;


protected function generateVarNamesAndCommentsParams "function generateVarNamesAndCommentsParams
  Checks and generates a comment and input for a param variable
  author x02lucpo
"
  input DAELow.Var inVar1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input Integer inInteger4;
  input String[:] inParamStrArr;
  input String[:] inParamStrArrCmt;
  input Integer inParamAlgStr;
  input list<String> inStringLst5;
  input list<String> inStringLst6;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output Integer outInteger3;
  output String[:] outParamStrArr;
  output String[:] outParamStrArrCmt;
  output Integer outParamAlgStr;
  output list<String> outStringLst4;
  output list<String> outStringLst5;
algorithm
  (outStringArray1,outStringArray2,outInteger3,outParamStrArr,outParamStrArrCmt,outParamAlgStr,outStringLst4,outStringLst5):=
  matchcontinue (inVar1,inStringArray2,inStringArray3,inInteger4,inParamStrArr,inParamStrArrCmt,inParamAlgStr,inStringLst5,inStringLst6)
    local
      String origname_str,name_1,comment,comment_1,if_str,is,name,define_str,array_define;
      Integer n_vars_1,indx,n_vars,num_strparam;
      String[:] name_arr_1,comment_arr_1,name_arr,comment_arr,strparam_arr,strparam_comment_arr;
      DAELow.Var var;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      list<DAE.Subscript> inst_dims;
      Option<DAE.Exp> value;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<String> get_name_function_ifs,var_defines;
      DAELow.Type typeVar;

      /* String parameters */
    case ((var as DAELow.VAR(varName = cr,
                             varKind = kind,
                             varDirection = dir,
                             varType = typeVar as DAELow.STRING(),
                             arryDim = inst_dims,
                             index = indx,
                             origVarName = origname,
                             values = dae_var_attr,
                             comment = comment,
                             flowPrefix = flowPrefix,
                             streamPrefix = streamPrefix)),
          name_arr,comment_arr,n_vars,strparam_arr,strparam_comment_arr,num_strparam,get_name_function_ifs,var_defines)
      equation
        true = DAELow.isParam(var);
        origname_str = Exp.printComponentRefStr(origname);
        name_1 = Util.stringAppendList({"\"",origname_str,"\""});
        comment = DAEUtil.dumpCommentOptionStr(comment);
        num_strparam = num_strparam + 1;
        comment_1 = generateEmptyString(comment);
        strparam_arr = arrayUpdate(strparam_arr, indx + 1, name_1);
        strparam_comment_arr = arrayUpdate(strparam_comment_arr, indx + 1, comment_1);
        if_str = generateGetnameFunctionIf(cr, typeVar, indx, stringParamNames);
        is = intString(indx);
        name = Exp.printComponentRefStr(cr);

        define_str = generateNameDependentOnType("parameters",typeVar);

        define_str = Util.stringAppendList({"#define ",name," localData->",define_str,"[",is,"]","\n"});
        array_define = generateArrayDefine(origname, inst_dims, indx, "localData->parameters");
        define_str = stringAppend(define_str, array_define);
      then
        (name_arr,comment_arr,n_vars,strparam_arr,strparam_comment_arr,num_strparam,(if_str :: get_name_function_ifs),(define_str :: var_defines));

			/* Non-string parameters */
    case ((var as DAELow.VAR(varName = cr,
                             varKind = kind,
                             varDirection = dir,
                             varType = typeVar,
                             arryDim = inst_dims,
                             index = indx,
                             origVarName = origname,
                             values = dae_var_attr,
                             comment = comment,
                             flowPrefix = flowPrefix,
                             streamPrefix = streamPrefix)),
          name_arr,comment_arr,n_vars,strparam_arr,strparam_comment_arr,num_strparam,get_name_function_ifs,var_defines)
      equation
        true = DAELow.isParam(var);
        origname_str = Exp.printComponentRefStr(origname);
        name_1 = Util.stringAppendList({"\"",origname_str,"\""});
        comment = DAEUtil.dumpCommentOptionStr(comment);
        n_vars_1 = n_vars + 1;
        comment_1 = generateEmptyString(comment);
        name_arr_1 = arrayUpdate(name_arr, indx + 1, name_1);
        comment_arr_1 = arrayUpdate(comment_arr, indx + 1, comment_1);
        if_str = generateGetnameFunctionIf(cr, typeVar, indx, paramNames);
        is = intString(indx);
        name = Exp.printComponentRefStr(cr);

        define_str = generateNameDependentOnType("parameters",typeVar);

        define_str = Util.stringAppendList({"#define ",name," localData->",define_str,"[",is,"]","\n"});
        array_define = generateArrayDefine(origname, inst_dims, indx, "localData->parameters");
        define_str = stringAppend(define_str, array_define);
      then
        (name_arr_1,comment_arr_1,n_vars_1,strparam_arr,strparam_comment_arr,num_strparam,(if_str :: get_name_function_ifs),(define_str :: var_defines));

    case (var,name_arr,comment_arr,n_vars,strparam_arr,strparam_comment_arr,num_strparam,get_name_function_ifs,var_defines)
    then (name_arr,comment_arr,n_vars,strparam_arr,strparam_comment_arr,num_strparam,get_name_function_ifs,var_defines);

  end matchcontinue;
end generateVarNamesAndCommentsParams;

protected function generateVarNamesAndCommentsExtObjs "
  Checks and generates a comment and input for a external object variable
"
  input DAELow.Var inVar1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input Integer inInteger4;
  input list<String> inStringLst5;
  input list<String> inStringLst6;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output Integer outInteger3;
  output list<String> outStringLst4;
  output list<String> outStringLst5;
algorithm
  (outStringArray1,outStringArray2,outInteger3,outStringLst4,outStringLst5):=
  matchcontinue (inVar1,inStringArray2,inStringArray3,inInteger4,inStringLst5,inStringLst6)
    local
      String origname_str,name_1,comment,comment_1,if_str,is,name,define_str,array_define;
      Integer n_vars_1,indx,n_vars;
      String[:] name_arr_1,comment_arr_1,name_arr,comment_arr;
      DAELow.Var var;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      list<DAE.Subscript> inst_dims;
      Option<DAE.Exp> value;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<String> get_name_function_ifs,var_defines;

    /*
     * the variable to checked the old number of variables generated name of the
     * from \"a\" comment of the from \"a afhalk\" number of generated strings
     */
    case ((var as DAELow.VAR(varName = cr,
                             varKind = kind,
                             varDirection = dir,
                             arryDim = inst_dims,
                             index = indx,
                             origVarName = origname,
                             values = dae_var_attr,
                             comment = comment,
                             flowPrefix = flowPrefix,
                             streamPrefix = streamPrefix)),name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines)
      local Option<SCode.Comment> comment;
      equation
        true = DAELow.isExtObj(var);
        is = intString(indx);
        name = Exp.printComponentRefStr(cr);
        define_str = Util.stringAppendList({"#define ",name," localData->extObjs[",is,"]","\n"});
      then
        (name_arr,comment_arr,n_vars, get_name_function_ifs,(define_str :: var_defines));

    case (var,name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines)
    then (name_arr,comment_arr,n_vars,get_name_function_ifs,var_defines);
  end matchcontinue;
end generateVarNamesAndCommentsExtObjs;

protected function generateVarNamesAndCommentsStatesAndDerivat
"function generateVarNamesAndCommentsStatesAndDerivatives
  author: x02lucpo
  Checks and generates a comment and input for a state and derivative variable"
  input DAELow.Var inVar1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input String[:] inStringArray4;
  input String[:] inStringArray5;
  input Integer inInteger6;
  input list<String> inStringLst7;
  input list<String> inStringLst8;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output String[:] outStringArray3;
  output String[:] outStringArray4;
  output Integer outInteger5;
  output list<String> outStringLst6;
  output list<String> outStringLst7;
algorithm
  (outStringArray1,outStringArray2,outStringArray3,outStringArray4,outInteger5,outStringLst6,outStringLst7):=
  matchcontinue (inVar1,inStringArray2,inStringArray3,inStringArray4,inStringArray5,inInteger6,inStringLst7,inStringLst8)
    local
      String origname_str,name_1,der_origname_1,der_name_1,comment,comment_1,if_str,if_str_1,is,name,define_str,define_str_der,array_define;
      Integer n_vars_1,indx,n_vars;
      String[:] name_arr_1,name_arr_der_1,comment_arr_1,comment_arr_der_1,name_arr,comment_arr,name_arr_der,comment_arr_der;
      list<String> get_name_function_ifs_1,get_name_function_ifs_2,get_name_function_ifs,var_defines;
      DAELow.Var var;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.VarDirection dir;
      list<DAE.Subscript> inst_dims;
      Option<DAE.Exp> value;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAELow.Type tp;

    /* the variable to checked name of the from \"a\" comment of the from \"a afhalk\" name of the
       from \"der(a)\" comment of the from \"a afhalk\" the old number of variables generated name
       of the form \"a\" comment of the from \"a afhalk\" name of the form \"der(a)\" comment of the
       from \"a afhalk\" number of generated strings */
    case ((var as DAELow.VAR(varName = cr,
                             varKind = kind,
                             varDirection = dir,
                             arryDim = inst_dims,
                             index = indx,
                             origVarName = origname,
                             values = dae_var_attr,
                             comment = comment,
                             varType=tp,
                             flowPrefix = flowPrefix,
                             streamPrefix = streamPrefix)),
          name_arr,comment_arr,name_arr_der,comment_arr_der,n_vars,get_name_function_ifs,var_defines)
      equation
        true = DAELow.isStateVar(var);
        origname_str = Exp.printComponentRefStr(origname);
        name_1 = Util.stringAppendList({"\"",origname_str,"\""});
        der_origname_1 = changeNameForDerivative(origname_str);
        der_name_1 = Util.stringAppendList({"\"",der_origname_1,"\""});
        comment = DAEUtil.dumpCommentOptionStr(comment);
        n_vars_1 = n_vars + 1;
        comment_1 = generateEmptyString(comment);
        name_arr_1 = arrayUpdate(name_arr, indx + 1, name_1);
        name_arr_der_1 = arrayUpdate(name_arr_der, indx + 1, der_name_1);
        comment_arr_1 = arrayUpdate(comment_arr, indx + 1, comment_1);
        comment_arr_der_1 = arrayUpdate(comment_arr_der, indx + 1, comment_1);
        if_str = generateGetnameFunctionIf(cr, tp, indx, stateNames);
        if_str_1 = generateGetnameFunctionIfForDerivatives(cr, indx, derivativeNames);
        get_name_function_ifs_1 = (if_str :: get_name_function_ifs);
        get_name_function_ifs_2 = (if_str_1 :: get_name_function_ifs_1);
        is = intString(indx);
        name = Exp.printComponentRefStr(cr);
           //no need for checking if the variable is string because a state is _ALLWAYS_ a real
        define_str = Util.stringAppendList({"#define ",name," localData->states[",is,"]","\n"});
        define_str_der = Util.stringAppendList(
          {"#define ",DAELow.derivativeNamePrefix,name," localData->statesDerivatives[",is,"]",
          "\n"});
        array_define = generateArrayDefine(origname, inst_dims, indx, "localData->states");
        define_str = stringAppend(define_str, array_define);
      then
        (name_arr_1,comment_arr_1,name_arr_der_1,comment_arr_der_1,n_vars_1,get_name_function_ifs_2,(define_str :: (define_str_der :: var_defines)));

    case (DAELow.VAR(varName = cr,
                     varKind = kind,
                     varDirection = dir,
                     index = indx,
                     origVarName = origname,
                     values = dae_var_attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix),
          name_arr,comment_arr,name_arr_der,comment_arr_der,n_vars,get_name_function_ifs,var_defines)
      local Option<SCode.Comment> comment;
      then
        (name_arr,comment_arr,name_arr_der,comment_arr_der,n_vars,get_name_function_ifs,var_defines);
  end matchcontinue;
end generateVarNamesAndCommentsStatesAndDerivat;

protected function generateArrayDefine
"function: generateArrayDefine
  Generates a define for an array variable.
  For an array s, each scalar value is given a define, e.g.
  #define s[1,3] y[17], etc. But to also be able to treat the whole array
  as a value this function generates a define to point to the first element
  of the array, e.g. #define s &y[15]."
  input DAE.ComponentRef inComponentRef;
  input DAE.InstDims inInstDims;
  input Integer inInteger;
  input String inString;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef,inInstDims,inInteger,inString)
    local
      DAE.ComponentRef cr_1,cr;
      String cr_name,cr_name_1,indx_str,res,array;
      Integer indx;
    case (cr,(_ :: _),indx,array) /* vector name for cref with all indices 1 */
      equation
        true = Exp.crefIsFirstArrayElt(cr);
        cr_1 = Exp.crefStripLastSubs(cr);
        cr_name = Exp.printComponentRefStr(cr_1);
        cr_name_1 = Util.modelicaStringToCStr(cr_name,true);
        indx_str = intString(indx);
        res = Util.stringAppendList({"#define ",cr_name_1," ",array,"[",indx_str,"]\n"});
      then
        res;
    case (_,_,_,_) then "";
  end matchcontinue;
end generateArrayDefine;

public function changeNameForDerivative
"function changeNameForDerivative
  author: x02lucpo
  helper function to generateVarNamesAndComments.
  Changes a string from \"a.b.c\" to \"a.b.der(c)\""
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString)
    local
      String var_name,der_var_name_1,origname,prefix,ret_str,origname_1;
      list<String> origname_lst,origname_lst_1;
    case (origname_1) /* print \"change_name_for_derivative FAILED\" */
      then "der("+& origname_1 +& ")";
/*
    case (origname) // catch the variable names a
      equation
        {var_name} = Util.stringSplitAtChar(origname, ".");
        der_var_name_1 = Util.stringAppendList({"der(",var_name,")"});
      then
        der_var_name_1;
    case (origname)
      equation
        origname_lst = Util.stringSplitAtChar(origname, ".");
        var_name = Util.listLast(origname_lst);
        origname_lst_1 = Util.listStripLast(origname_lst);
        der_var_name_1 = Util.stringAppendList({"der(",var_name,")"});
        prefix = Util.stringDelimitList(origname_lst_1, ".");
        ret_str = Util.stringAppendList({prefix,".",der_var_name_1});
      then
        ret_str;
    case (origname_1) // print \"change_name_for_derivative FAILED\"
      then origname_1;
*/
  end matchcontinue;
end changeNameForDerivative;

protected function generateEmptyString
"function: generateEmptyString
  This function adds citation chars to an empty string.
  Non empty strings are returned as is."
  input String inString;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString)
    local String s;
    case ("") then "\"\"";
    case (s) then s;
  end matchcontinue;
end generateEmptyString;

protected function generateInputFunctionCode
"function: generateInputFunctionCode
   Generates the input_function for all the variables
   that are INPUT and on top model"
  input DAELow.DAELow inDAELow;
  output String outString;
  output Integer outInteger;
algorithm
  (outString,outInteger):=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> knvars_lst;
      list<String> res1;
      String res1_1,res;
      Integer lst_lenght;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        knvars_lst = DAELow.varList(knvars);
        res1 = generateInputFunctionCode2(knvars_lst, 0);
        res1_1 = Util.listSelect(res1, Util.isNotEmptyString);
        lst_lenght = listLength(res1_1);
        res1_1 = Util.stringDelimitListNonEmptyElts(res1_1, "\n  ");
        res = Util.stringAppendList({"/*\n*/\nint input_function()\n","{\n  ",res1_1,"return 0;","\n}\n\n"});
      then
        (res,lst_lenght);
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_input_function_code failed"});
      then
        fail();
  end matchcontinue;
end generateInputFunctionCode;

protected function generateInputFunctionCode2
"function: generateInputFunctionCode2
  Helper function to generateInputFunctionCode"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer int,i_1,index,i;
      String i_str,cr_str,assign_str;
      list<String> res;
      DAELow.Var var;
      DAE.ComponentRef cr,name;
      DAE.VarDirection dir;
      DAELow.Type tp;
      Option<DAE.Exp> exp,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      list<Absyn.Path> classes;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest;
      DAE.ElementSource source "the origin of the element";

    case ({},int) then {};
    case (((var as DAELow.VAR(varName = cr,
                              varDirection = dir,
                              varType = tp,
                              bindExp = exp,
                              bindValue = v,
                              arryDim = dim,
                              index = index,
                              origVarName = name,
                              source = source,
                              values = attr,
                              comment = comment,
                              flowPrefix = flowPrefix,
                              streamPrefix = streamPrefix)) :: rest),i)
      equation
        true = DAELow.isVarOnTopLevelAndInput(var);
        i_str = intString(i);
        i_1 = i + 1;
        cr_str = Exp.printComponentRefStr(cr);
        assign_str = Util.stringAppendList({cr_str," = localData->inputVars[",i_str,"];"});
        res = generateInputFunctionCode2(rest, i_1);
      then
        (assign_str :: res);
    case ((var :: rest),index)
      equation
        res = generateInputFunctionCode2(rest, index);
      then
        res;
  end matchcontinue;
end generateInputFunctionCode2;

protected function generateOutputFunctionCode
"function: generateOutputFunctionCode
   Generates the output_function for all the variables
   that are OUTPUT and on top model."
  input DAELow.DAELow inDAELow;
  output String outString;
  output Integer outInteger;
algorithm
  (outString,outInteger):=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> knvars_lst,vars_lst,vars_lst_1;
      list<String> res1;
      String res1_1,res;
      Integer lst_lenght;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        knvars_lst = DAELow.varList(knvars);
        vars_lst = DAELow.varList(vars);
        vars_lst_1 = listAppend(knvars_lst, vars_lst);
        res1 = generateOutputFunctionCode2(vars_lst_1, 0);
        res1_1 = Util.listSelect(res1, Util.isNotEmptyString);
        lst_lenght = listLength(res1_1);
        res1_1 = Util.stringDelimitListNonEmptyElts(res1_1, "\n  ");
        res = Util.stringAppendList({"/*\n*/\nint output_function()\n","{\n  ",res1_1, "return 0;","\n}\n\n"});
      then
        (res,lst_lenght);
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_output_function_code failed"});
      then
        fail();
  end matchcontinue;
end generateOutputFunctionCode;

protected function generateOutputFunctionCode2 "function: generateOutputFunctionCode2
  Helper function to generateOutputFunctionCode"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output list<String> outStringLst;
algorithm
  outStringLst := matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer int,i_1,index,i;
      String i_str,cr_str,assign_str;
      list<String> res;
      DAELow.Var var;
      DAE.ComponentRef cr,name;
      DAE.VarDirection dir;
      DAELow.Type tp;
      Option<DAE.Exp> exp,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      list<Absyn.Path> classes;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest;
      DAE.ElementSource source "the origin of the element";

    case ({},int) then {};
    case (((var as DAELow.VAR(varName = cr,
                              varDirection = dir,
                              varType = tp,
                              bindExp = exp,
                              bindValue = v,
                              arryDim = dim,
                              index = index,
                              origVarName = name,
                              source = source,
                              values = attr,
                              comment = comment,
                              flowPrefix = flowPrefix,
                              streamPrefix = streamPrefix)) :: rest),i)
      equation
        true = DAELow.isVarOnTopLevelAndOutput(var);
        i_str = intString(i);
        i_1 = i + 1;
        cr_str = Exp.printComponentRefStr(cr);
        assign_str = Util.stringAppendList({"localData->outputVars[",i_str,"] =",cr_str,";"});
        res = generateOutputFunctionCode2(rest, i_1);
      then
        (assign_str :: res);
    case ((var :: rest),index)
      equation
        res = generateOutputFunctionCode2(rest, index);
      then
        res;
  end matchcontinue;
end generateOutputFunctionCode2;

protected function generateInitialBoundParameterCode
"function: generateInitialBoundParameterCode:
  This function generates initial value code for bound parameters
  that depend on other parameters, eg. parameter Real n=1/m;"
  input DAELow.DAELow inDAELow;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow)
    local
      Codegen.CFunction param_func,param_assigns,param_assigns_1,cfunc;
      list<DAELow.Var> knvars_lst;
      String str;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        orderedEqs = eqns,
                        removedEqs = se,
                        initialEqs = ie,
                        arrayEqs = ae,
                        algorithms = al,
                        eventInfo = ev)) /* code */
      equation
        param_func = Codegen.cMakeFunction("int", "bound_parameters", {}, {""});
        knvars_lst = DAELow.varList(knvars);
        (param_assigns,_) = generateParameterAssignments(knvars_lst, 0);
        param_assigns = addMemoryManagement(param_assigns);
        param_assigns_1 = Codegen.cAddCleanups(param_assigns, {"return 0;"});
        cfunc = Codegen.cMergeFns({param_func,param_assigns_1});
        str = Codegen.cPrintFunctionsStr({cfunc});
      then
        str;
  end matchcontinue;
end generateInitialBoundParameterCode;

protected function generateInitialValueCode2
"function: generateInitialValueCode2
  This function generates initial value code according to the new
  approach. It will be a replacement for generateInitialValueCode
  once it is stable."
  input DAELow.DAELow inDAELow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  output String outString;
  output Integer outInteger;
algorithm
  (outString,outInteger):=
  matchcontinue (inDAELow,ass1,ass2)
    local
      Codegen.CFunction init_func_1,f1,f2,f3,f4,cfunc;
      list<DAELow.Var> vars_lst,knvars_lst;
      list<DAELow.Equation> eqns_lst,se_lst,ie_lst,ie2_lst;
      Integer n1,n2,n3,n4,n,cg_id;
      String n_str,str;
      DAELow.DAELow dae;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case ((dae as DAELow.DAELOW(orderedVars = vars,
                                knownVars = knvars,
                                orderedEqs = eqns,
                                removedEqs = se,
                                initialEqs = ie,
                                arrayEqs = ae,
                                algorithms = al,
                                eventInfo = ev)),ass1,ass2) /* code n res */
      equation
        init_func_1 = Codegen.cMakeFunction("int", "initial_residual", {}, {});
        vars_lst = DAELow.varList(vars);
        knvars_lst = DAELow.varList(knvars);
        eqns_lst = DAELow.equationList(eqns);
        se_lst = DAELow.equationList(se);
        ie_lst = DAELow.equationList(ie);
        ie2_lst = generateInitialEquationsFromStart(vars_lst) "equations from start values with fixed = true" ;
        eqns_lst = selectContinuousEquations(eqns_lst,1,ass2,dae); // Select only non-discrete equations
        n1 = listLength(eqns_lst) "calculate total size" ;
        n2 = listLength(se_lst);
        n3 = listLength(ie_lst);
        n4 = listLength(ie2_lst);
        n = Util.listReduce({n1,n2,n3,n4}, int_add);
        n_str = intString(n);
        eqns_lst = Util.listMap(eqns_lst, DAELow.equationToResidualForm) "equations to residual form" ;
        se_lst = Util.listMap(se_lst, DAELow.equationToResidualForm);
        ie_lst = Util.listMap(ie_lst, DAELow.equationToResidualForm);
        ie2_lst = Util.listMap(ie2_lst, DAELow.equationToResidualForm);
        (f1,cg_id) = generateInitialResidualEqn(eqns_lst, 0) "Generate statements for residual elements" ;
        (f2,cg_id) = generateInitialResidualEqn(se_lst, cg_id);
        (f3,cg_id) = generateInitialResidualEqn(ie_lst, cg_id);
        (f4,cg_id) = generateInitialResidualEqn(ie2_lst, cg_id);
        cfunc = Codegen.cMergeFns({init_func_1,f1,f2,f3,f4}) "merge all parts toghether" ;
        cfunc = Codegen.cAddVariables(cfunc, {"int i=0;"});
        cfunc = addMemoryManagement(cfunc);
        cfunc = Codegen.cAddCleanups(cfunc, {"return 0;"});
        str = Codegen.cPrintFunctionsStr({cfunc});
      then
        (str,n);
    case (_,_,_) then ("/* generate_initial_value_code2 failed */",0);
  end matchcontinue;
end generateInitialValueCode2;

protected function selectContinuousEquations
"function selectContinuousEquations
  Returns only the equations that are solved for a continous variable."
  input list<DAELow.Equation> eqnLst;
  input Integer eqnIndx; // iterator, starts at 1..n
	input Integer[:] ass2;
	input DAELow.DAELow daelow;
	output list<DAELow.Equation> outEqnLst;
algorithm
  outEqnLst := matchcontinue(eqnLst,eqnIndx,ass2,daelow)
    local
      DAELow.VariableArray vararr;
      DAELow.Var var;
      Integer v,v_1;
      Boolean b;
      DAELow.Equation e;
    case({},eqnIndx,ass2,daelow) then {};
    case(e::eqnLst,eqnIndx,ass2,daelow as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr)))
     equation
       v = ass2[eqnIndx];
       v_1 = v - 1;
       (var) = DAELow.vararrayNth(vararr, v_1);
       b = hasDiscreteVar({var});
       eqnLst = selectContinuousEquations(eqnLst,eqnIndx+1,ass2,daelow);
       eqnLst = Util.if_(b,eqnLst,e::eqnLst);
     then eqnLst;
  end matchcontinue;
end selectContinuousEquations;

protected function generateInitialResidualEqn "function generateInitialResidualEqn

  Helper function to generate_initial_value_code2
  Generates code on residual form for a list of equations.
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowEquationLst,inInteger)
    local
      Integer cg_id;
      Codegen.CFunction cfunc,cfunc2,cfn;
      String var,assign;
      DAE.Exp e;
      list<DAELow.Equation> es;
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg var_id cg var_id */
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: es),cg_id)
      equation
        // if exp is a string just increase the index;
        DAE.ET_STRING() = Exp.typeof(e);
        (cfunc,var,cg_id) = Codegen.generateExpression(e, cg_id, Codegen.simContext);
        assign = Util.stringAppendList({"localData->initialResiduals[i++] = 0;//",var,";"});
        cfunc = Codegen.cAddStatements(cfunc, {assign});
        (cfunc2,cg_id) = generateInitialResidualEqn(es, cg_id);
        cfn = Codegen.cMergeFns({cfunc,cfunc2});
      then
        (cfn,cg_id);
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: es),cg_id)
      equation
        (cfunc,var,cg_id) = Codegen.generateExpression(e, cg_id, Codegen.simContext);
        assign = Util.stringAppendList({"localData->initialResiduals[i++] = ",var,";"});
        cfunc = Codegen.cAddStatements(cfunc, {assign});
        (cfunc2,cg_id) = generateInitialResidualEqn(es, cg_id);
        cfn = Codegen.cMergeFns({cfunc,cfunc2});
      then
        (cfn,cg_id);
    case ((_ :: es),cg_id)
      equation
        (cfn,cg_id) = generateInitialResidualEqn(es, cg_id);
      then
        (cfn,cg_id);
  end matchcontinue;
end generateInitialResidualEqn;

protected function generateInitialValueCode "function: generateInitialValueCode

  This function generates the code for solving the initial value problem.
  Information is gathered from the start and fixed attributes of variables
  and from initial equations.
"
  input DAELow.DAELow inDAELow;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Var> vars_lst,knvars_lst;
      list<DAELow.Equation> initial_eqns2;
      Codegen.CFunction start_assigns1,start_assigns2,param_assigns,init_func_1,init_func,res;
      Integer cg_id,cg_id_1,cg_id_2;
      String str;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev))
      equation
        vars_lst = DAELow.varList(vars);
        knvars_lst = DAELow.varList(knvars);
        // not used: initial_eqns2 = generateInitialEquationsFromStart(vars_lst);
        (start_assigns1,cg_id)   = generateInitialAssignmentsFromStart(vars_lst, 0);
        (start_assigns2,cg_id_1) = generateInitialAssignmentsFromStart(knvars_lst, cg_id);
        (param_assigns,cg_id_2)  = generateParameterAssignments(knvars_lst, cg_id_1);
        init_func_1 = Codegen.cMakeFunction("int", "initial_function", {}, {""});
        init_func = Codegen.cAddCleanups(init_func_1, {"return 0;"});
        // adrpo changed the order below, before was: start_assigns, param_assigns
        // i think parameters should be set before as start assignments may depend on them.
        res = Codegen.cMergeFns({init_func, param_assigns, start_assigns1, start_assigns2});
        str = Codegen.cPrintFunctionsStr({res});
      then
        str;
    case (_)
      equation
        init_func_1 = Codegen.cMakeFunction("int", "initial_function", {}, {""});
        init_func = Codegen.cAddCleanups(init_func_1, {"return 0;"});
        str = Codegen.cPrintFunctionsStr({init_func});
      then
        str;
  end matchcontinue;
end generateInitialValueCode;

protected function generateParameterAssignments "function: generateParameterAssignments
  Generates code for the parameter settings that depends on other
  parameters (as expressions). For instance, parameter Real m=2n+1;
  Those are calculated once in the initial function.
"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer cg_id,cg_id_1,cg_id_2;
      String cr_str,e_str,stmt;
      Codegen.CFunction exp_func,func,func_1,func_2;
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAELow.Var> vs;
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg_id cg var_id */
    case ((DAELow.VAR(varName = cr,varKind = DAELow.PARAM(),bindExp = SOME(e)) :: vs),cg_id)
      equation
        false = Exp.isConst(e);
        cr_str = Exp.printComponentRefStr(cr);
        (exp_func,e_str,cg_id_1) = Codegen.generateExpression(e, cg_id, Codegen.simContext);
        (func,cg_id_2) = generateParameterAssignments(vs, cg_id_1);
        stmt = Util.stringAppendList({cr_str," = ",e_str,";"});
        exp_func = Codegen.cAddStatements(exp_func, {stmt});
        func_2 = Codegen.cMergeFns({exp_func,func});
      then
        (func_2,cg_id_2);
    case ((_ :: vs),cg_id)
      equation
        (func,cg_id_1) = generateParameterAssignments(vs, cg_id);
      then
        (func,cg_id_1);
  end matchcontinue;
end generateParameterAssignments;

protected function generateInitialEquationsFromStart "function: generateInitialEquationsFromStart

  This function generates equations from the expressions in the start
  attributes of variables. Only variables with a start value and
  fixed set to true is converted by this function. Fixed set to false
  means an initial guess, and is not considered here.
"
  input list<DAELow.Var> inDAELowVarLst;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowVarLst)
    local
      list<DAELow.Equation> eqns;
      DAELow.Var v;
      DAE.ComponentRef cr;
      DAELow.VarKind kind;
      DAE.Exp startv;
      Option<DAE.VariableAttributes> attr;
      list<DAELow.Var> vars;
      DAE.ElementSource source "the origin of the element";

    case ({}) then {};
    case (((v as DAELow.VAR(varName = cr,varKind = kind,values = attr,source = source)) :: vars)) /* add equations for variables with fixed = true */
      equation
        true = DAELow.varFixed(v);
        true = DAEUtil.hasStartAttr(attr);
        startv = DAEUtil.getStartAttr(attr);
        eqns = generateInitialEquationsFromStart(vars);
      then
        (DAELow.EQUATION(DAE.CREF(cr,DAE.ET_OTHER()),startv,source) :: eqns);
    case ((_ :: vars))
      equation
        eqns = generateInitialEquationsFromStart(vars);
      then
        eqns;
  end matchcontinue;
end generateInitialEquationsFromStart;

protected function generateInitialAssignmentsFromStart "function: generateInitialAssignmentsFromStart"
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger) := matchcontinue (inDAELowVarLst,inInteger)
    local
      Integer cg_id,cg_id_1,cg_id_2;
      Codegen.CFunction func,exp_func,func_1,func_2;
      String cr_str,startv_str,stmt1,stmt2;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      DAE.Exp startv;
      Option<DAE.VariableAttributes> attr;
      list<DAELow.Var> vars;
      String origname_str;
    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg var_id cg var_id */
    case ((DAELow.VAR(varName = cr,varKind = kind,values = attr, origVarName = origname) :: vars),cg_id) /* also add an assignment for variables that have non-constant
	    expressions, e.g. parameter values, as start.
	   NOTE: such start attributes can then not be changed in the text
	   file, since the initial calc. will override those entries!
	 */
      equation
        startv = DAEUtil.getStartAttr(attr);
        false = Exp.isConst(startv);
        (func,cg_id_1) = generateInitialAssignmentsFromStart(vars, cg_id);
        origname_str = Exp.printComponentRefStr(origname);
        cr_str = Exp.printComponentRefStr(cr);
        (exp_func,startv_str,cg_id_2) = Codegen.generateExpression(startv, cg_id_1, Codegen.simContext);
        stmt1 = Util.stringAppendList({cr_str," = ",startv_str,";"});
        stmt2 = Util.stringAppendList({"if (sim_verbose) { printf(\"Setting variable start value:%s(start=%f)\\n\", \"", origname_str, "\", ",
                startv_str,"); }"});
        func_1 = Codegen.cAddStatements(func, stmt1::{stmt2});
        func_2 = Codegen.cMergeFns({exp_func,func_1});
      then
        (func_2,cg_id_2);
    case ((_ :: vars),cg_id)
      equation
        (func,cg_id_1) = generateInitialAssignmentsFromStart(vars, cg_id);
      then
        (func,cg_id_1);
  end matchcontinue;
end generateInitialAssignmentsFromStart;

protected function generateOdeCode "function generateOdeCode
  Outputs simulation code from a DAELow.
  The state calculations are generated on explicit ode form:
  \\dot{x} := f(x,y,t)
"
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow1;
  input list<list<Integer>> inIntegerLstLst2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input DAELow.IncidenceMatrix inIncidenceMatrix5;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT6;
  input Absyn.Path inPath7;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAElist1,inDAELow1,inIntegerLstLst2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inPath7)
    local
      input DAE.DAElist dae;
      String cname,ode_func_str,extra_funcs_str,res;
      list<list<Integer>> blt_states,blt_no_states,comps;
      Codegen.CFunction block_code,func_1,func;
      list<CFunction> extra_funcs;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<Integer>[:] m,mt;
      Absyn.Path class_;
    case (dae,dlow,comps,ass1,ass2,m,mt,class_) /* components ass1 ass2 */
      equation
        cname = Absyn.pathString(class_);
        (blt_states,blt_no_states) = DAELow.generateStatePartition(comps, dlow, ass1, ass2, m, mt);
        (block_code,_,extra_funcs) = generateOdeBlocks(dae,false,dlow,ass1, ass2, blt_states, 0);
        func_1 = Codegen.cMakeFunction("int", "functionODE", {}, {""});
        func_1 = addMemoryManagement(func_1);
        func = Codegen.cAddCleanups(func_1, {"return 0;"});
        func_1 = Codegen.cMergeFns({func,block_code});
        ode_func_str = Codegen.cPrintFunctionsStr({func_1});
        extra_funcs_str = Codegen.cPrintFunctionsStr(extra_funcs);
        res = Util.stringAppendList({extra_funcs_str,ode_func_str});
      then
        res;
    case (dae,dlow,comps,ass1,ass2,m,mt,class_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_ode_code failed"});
      then
        fail();
  end matchcontinue;
end generateOdeCode;

protected function addMemoryManagement
"function: addMemoryManagement
  This function adds memory management code for a function.
  It consists of two calls, get_memory_state and restore_memory_state."
  input CFunction cfunc;
  output CFunction cfunc;
algorithm
  cfunc := Codegen.cAddVariables(cfunc, {"state mem_state;"});
  cfunc := Codegen.cPrependStatements(cfunc, {"mem_state = get_memory_state();"});
  cfunc := Codegen.cAddCleanups(cfunc, {"restore_memory_state(mem_state);"});
end addMemoryManagement;

protected function buildWhenConditionChecks3
" Helper function to build_when_condition_checks.
  Generates code for checking one equation of one when clause.
"
  input list<DAE.Exp> whenConditions   "List of expressions from \"when {exp1, exp2, ...}\" ";
  input Integer whenClauseIndex        "When clause index";
  input Integer nextHelpIndex          "Next available help variable index";
  input Boolean isElseWhen					   "Whether this lase is an elsewhen or not";
  output String outString              "Generated c-code";
  output list<HelpVarInfo> helpVarLst;
algorithm
  (outString,helpVarLst):=
  matchcontinue (whenConditions,whenClauseIndex,nextHelpIndex,isElseWhen)
    local
      String i_str,helpVarIndexStr,res,resx,res_1;
      HelpVarInfo helpInfo;
      Integer helpVarIndex_1,i,helpVarIndex;
      list<HelpVarInfo> helpVarInfoList;
      DAE.Exp e;
      list<DAE.Exp> el;
    case ({},_,_,_) then ("",{});
    case ((e :: el),i,helpVarIndex, false)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        helpInfo = (helpVarIndex,e,i);
        res = Util.stringAppendList(
          {"  if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
          " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,false);
        res_1 = stringAppend(res, resx);
      then
        (res_1,(helpInfo :: helpVarInfoList));
    case ((e :: el),i,helpVarIndex, true)
      equation
        i_str = intString(i);
        helpVarIndexStr = intString(helpVarIndex);
        helpInfo = (helpVarIndex,e,i);
        res = Util.stringAppendList(
          {"  else if (edge(localData->helpVars[",helpVarIndexStr,"])) AddEvent(",i_str,
          " + localData->nZeroCrossing);\n"});
        helpVarIndex_1 = helpVarIndex + 1;
        (resx,helpVarInfoList) = buildWhenConditionChecks3(el, i, helpVarIndex_1,false);
        res_1 = stringAppend(res, resx);
      then
        (res_1,(helpInfo :: helpVarInfoList));
    case (_,_,_,_)
      equation
        print("-build_when_condition_checks3 failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks3;

protected function buildWhenConditionChecks2
" This function outputs checks for all when clauses that do not have equations but reinit statements.
"
  input list<DAELow.WhenClause> inDAELowWhenClauseLst1 "List of when clauses";
  input Integer whenClauseIndex "index of the first when clause in inDAELowWhenClauseLst1";
  input Integer nextHelpVarIndex;
  output String outString;
  output list<HelpVarInfo> helpVarLst;
algorithm
  (outString,helpVarLst):=
  matchcontinue (inDAELowWhenClauseLst1,whenClauseIndex,nextHelpVarIndex)
    local
      Integer i_1,i,nextHelpIndex,numberOfNewHelpVars,nextHelpIndex_1;
      String res,res2,res1;
      list<HelpVarInfo> helpVarInfoList,helpVarInfoList2,helpVarInfoList1;
      DAELow.WhenClause wc;
      list<DAELow.WhenClause> xs;
      list<DAE.Exp> el;
      DAE.Exp e;
    case ({},_,_) then ("",{});
    case (((wc as DAELow.WHEN_CLAUSE(reinitStmtLst = {})) :: xs),i,nextHelpIndex) /* skip if there are no reinit statements */
      equation
        i_1 = i + 1;
        (res,helpVarInfoList) = buildWhenConditionChecks2(xs, i_1, nextHelpIndex);
      then
        (res,helpVarInfoList);
    case (((wc as DAELow.WHEN_CLAUSE(condition = DAE.ARRAY(array = el))) :: xs),i,nextHelpIndex)
      equation
        i_1 = i + 1;
        (res2,helpVarInfoList2) = buildWhenConditionChecks2(xs, i_1, nextHelpIndex);
        numberOfNewHelpVars = listLength(helpVarInfoList2);
        nextHelpIndex_1 = nextHelpIndex + numberOfNewHelpVars;
        (res1,helpVarInfoList1) = buildWhenConditionChecks3(el, i, nextHelpIndex_1,false);
        res = stringAppend(res1, res2);
        helpVarInfoList = listAppend(helpVarInfoList1, helpVarInfoList2);
      then
        (res,helpVarInfoList);
    case (((wc as DAELow.WHEN_CLAUSE(condition = e)) :: xs),i,nextHelpIndex)
      equation
        i_1 = i + 1;
        (res2,helpVarInfoList2) = buildWhenConditionChecks2(xs, i_1, nextHelpIndex);
        numberOfNewHelpVars = listLength(helpVarInfoList2);
        nextHelpIndex_1 = nextHelpIndex + numberOfNewHelpVars;
        (res1,helpVarInfoList1) = buildWhenConditionChecks3({e}, i, nextHelpIndex_1,false);
        res = stringAppend(res1, res2);
        helpVarInfoList = listAppend(helpVarInfoList1, helpVarInfoList2);
      then
        (res,helpVarInfoList);
    case (_,_,_)
      equation
        print("-build_when_condition_checks2 failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks2;

protected function buildWhenConditionChecks4
" Helper function to build_when_condition_checks
  This function generates checks for each when clause, sorted according to the order in which
  the equations inside them are sorted. The function buildWhenConditionChecks2 takes care
  of all the when clauses that does not contain equations (only reinit).
"
  input list<Integer> orderOfEquations                "The sorting order of the equations.";
  input list<DAELow.Equation> inDAELowEquationLst     "List of equations.";
  input list<DAELow.WhenClause> inDAELowWhenClauseLst "List of when clauses.";
  input Integer nextHelpVarIndex                      "index of the next generated help variable.";
  output String outString                             "Generated event checking code";
  output list<HelpVarInfo> helpVarLst									"List of help variables introduced in this function.";
algorithm
  (outString,helpVarLst):=
  matchcontinue (orderOfEquations,inDAELowEquationLst,inDAELowWhenClauseLst,nextHelpVarIndex)
    local
      Integer eqn,nextHelpIndex;
      String res2,res1,res;
      list<HelpVarInfo> helpVarInfoList2,helpVarInfoList1,helpVarInfoList;
      list<Integer> rest;
      list<DAELow.Equation> eqnl;
      list<DAELow.WhenClause> whenClauseList;
      DAELow.WhenEquation whenEq;

    case ({},_,_,_) then ("",{});

		/* equation is a WHEN_EQUATION */
    case ((eqn :: rest),eqnl,whenClauseList,nextHelpIndex)
      equation
        DAELow.WHEN_EQUATION(whenEquation=whenEq) = listNth(eqnl, eqn-1);
        (res2, helpVarInfoList2) = buildWhenConditionChecks4(rest, eqnl, whenClauseList, nextHelpIndex);
        (res1, helpVarInfoList1) = buildWhenConditionCheckForEquation(SOME(whenEq), whenClauseList, false,
                                       nextHelpIndex + listLength(helpVarInfoList2));
        res = stringAppend(res1, res2);
        helpVarInfoList = listAppend(helpVarInfoList1, helpVarInfoList2);
      then
        (res,helpVarInfoList);

    case ((_ :: rest),eqnl,whenClauseList,nextHelpIndex)
      equation
        (res,helpVarInfoList) = buildWhenConditionChecks4(rest, eqnl, whenClauseList, nextHelpIndex);
      then
        (res,helpVarInfoList);
    case (_,_,_,_)
      equation
        print("-build_when_condition_checks4 failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks4;

protected function buildWhenConditionCheckForEquation "
	Generates eventchecking code given a when equation.
"
  input Option<DAELow.WhenEquation> whenEq            "The equation to check for";
  input list<DAELow.WhenClause> inDAELowWhenClauseLst "List of when clauses.";
  input Boolean isElseWhen                            "Whether the equation is inside an elsewhen or not.";
  input Integer nextHelpIndex                         "Next avalable help variable index.";
  output String outString                             "Generated event checking code";
  output list<HelpVarInfo> helpVarLst									"List of help variables introduced in this function.";
algorithm
  (outString, helpVarLst) :=
  matchcontinue (whenEq,inDAELowWhenClauseLst,isElseWhen, nextHelpIndex)
    local
      Boolean isElseWhen;
      Integer nextHelpInd, ind;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      String res1,res2,res;
      Option<DAELow.WhenEquation> elsePart;
      list<DAE.Exp> conditionList;
      list<HelpVarInfo> helpVars1,helpVars2, helpVars;
      list<DAELow.WhenClause> whenClauseList;
    case (SOME(DAELow.WHEN_EQ(ind,cr,exp,elsePart)),whenClauseList,isElseWhen,nextHelpInd)
      equation
        conditionList = getConditionList(whenClauseList, ind);
        (res1,helpVars1) = buildWhenConditionChecks3(conditionList, ind, nextHelpInd,isElseWhen);
        (res2,helpVars2) = buildWhenConditionCheckForEquation(elsePart, whenClauseList, true,
          nextHelpInd + listLength(helpVars1));
        res = stringAppend(res1,res2);
        helpVars = listAppend(helpVars1,helpVars2);
      then
        (res,helpVars);
    case (NONE,_,_,_)
      then ("",{});
  end matchcontinue;
end buildWhenConditionCheckForEquation;

protected function getConditionList "
"

  input list<DAELow.WhenClause> whenClauseList;
  input Integer index;
  output list<DAE.Exp> conditionList;
algorithm
  conditionList := matchcontinue (whenClauseList, index)
    local
      list<DAELow.WhenClause> whenClauseList;
      Integer ind;
      list<DAE.Exp> conditionList;
      DAE.Exp e;

    case (whenClauseList, ind)
      equation
        DAELow.WHEN_CLAUSE(condition=DAE.ARRAY(_,_,conditionList)) = listNth(whenClauseList, ind);
      then conditionList;
    case (whenClauseList, ind)
      equation
        DAELow.WHEN_CLAUSE(condition=e) = listNth(whenClauseList, ind);
      then {e};
  end matchcontinue;
end getConditionList;

protected function addMissingEquations "function: addMissingEquations
  Helper function to build_when_condition_checks
  Given an integer and a list of integers completes the list with missing
  integers upto the given integer.
"
  input Integer inInteger;
  input list<Integer> inIntegerLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger,inIntegerLst)
    local
      list<Integer> lst,lst_1,lst_2;
      Integer n_1,n;
    case (0,lst) then lst;
    case (n,lst)
      equation
        n_1 = n - 1;
        lst_1 = addMissingEquations(n_1, lst);
        _ = Util.listGetMember(n, lst);
      then
        lst_1;
    case (n,lst) /* missing equations must be added in correct order,
	 required in building whenConditionChecks4 */
      equation
        n_1 = n - 1;
        lst_1 = addMissingEquations(n_1, lst);
        lst_2 = listAppend(lst_1, {n});
      then
        lst_2;
  end matchcontinue;
end addMissingEquations;


protected function buildDiscreteVarChanges "
For all discrete variables in the model, generate code that checks if they have changed and if so generate code
that add events to the event queue: if (change(<discretevar>)) { AddEvent(c1);...;AddEvent(cn)}

"
  input DAELow.DAELow daelow;
  input list<list<Integer>> comps;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrixT mT;
  output String outString;
algorithm
  outString := matchcontinue(daelow,comps,ass1,ass2,m,mT)
    local String s1,s2;
      list<Integer> b;
      list<list<Integer>> blocks;
      DAELow.Variables v;
      list<DAELow.Var> vLst;
    case (daelow as DAELow.DAELOW(orderedVars = v),blocks,ass1,ass2,m,mT)
      equation
      vLst = DAELow.varList(v);
      vLst = Util.listSelect(vLst,DAELow.isVarDiscrete); // select all discrete vars.
			outString = Util.stringDelimitList(Util.listMap2(vLst, buildDiscreteVarChangesVar,daelow,mT),"\n  ");
    then outString;
    case(_,_,_,_,_,_) equation
      print("buildDiscreteVarChanges failed\n");
      then fail();
  end matchcontinue;
end buildDiscreteVarChanges;

protected function buildDiscreteVarChangesVar "help function to buildDiscreteVarChanges"
  input DAELow.Var var;
  input DAELow.DAELow daelow;
  input DAELow.IncidenceMatrixT mT;
  output String outString;
algorithm
  outString := matchcontinue(var,daelow,mT)
  local list<String> strLst;
    DAE.ComponentRef cr;
    Integer varIndx;
    list<Integer> eqns;
    case(var as DAELow.VAR(varName=cr,index=varIndx), daelow,mT) equation

      eqns = mT[varIndx+1]; // eqns continaing var
      true = crefNotInWhenEquation(cr,daelow,eqns);
      outString = buildDiscreteVarChangesAddEvent(0,cr);

  		/*strLst = Util.listMap2(eqns,buildDiscreteVarChangesVar2,cr,daelow);
  		outString = Util.stringDelimitList(strLst,"\n");*/

    then outString;

    case(_,_,_) then "";
  end matchcontinue;
end buildDiscreteVarChangesVar;

protected function crefNotInWhenEquation "Returns true if cref is not solved in any of the equations
given as indices which is a when_equation"
  input DAE.ComponentRef cr;
  input DAELow.DAELow daelow;
  input list<Integer> eqns;
  output Boolean res;
algorithm
  res := matchcontinue(cr,daelow,eqns)
  local
    DAELow.EquationArray eqs;
    Integer e;
    DAE.ComponentRef cr2;
    DAE.Exp exp;
    Boolean b1,b2;
    case(cr,daelow,{}) then true;
    case(cr,daelow as DAELow.DAELOW(orderedEqs=eqs),e::eqns) equation
      DAELow.WHEN_EQUATION(whenEquation=DAELow.WHEN_EQ(_,cr2,exp,_)) = DAELow.equationNth(eqs,intAbs(e)-1);
      //We can asume the same component refs are solved in any else-branch.
      b1 = Exp.crefEqual(cr,cr2);
     b2 = Exp.expContains(exp,DAE.CREF(cr,DAE.ET_OTHER()));
     true = boolOr(b1,b2);
    then false;
    case(cr,daelow,_::eqns) equation
      res = crefNotInWhenEquation(cr,daelow,eqns);
    then res;
  end matchcontinue;
end crefNotInWhenEquation;


protected function buildDiscreteVarChangesVar2
"Help relation to buildDiscreteVarChangesVar
 For an equation e  (not a when equation) containing a discrete variable v, if e contains a
 ZeroCrossing(i) generate 'if change(v) needToIterate=1;)'"
  input Integer eqn;
  input DAE.ComponentRef cr;
  input DAELow.DAELow daelow;
  output String outString;
algorithm
  outString := matchcontinue(eqn,cr,daelow)
  local DAELow.EquationArray eqns;
    DAELow.Equation e;
    list<DAELow.ZeroCrossing> zcLst;
    String crStr;
    list<String> strLst;
    list<Integer> zcIndxLst;

    case(eqn,cr,daelow as DAELow.DAELOW(eventInfo=DAELow.EVENT_INFO(zeroCrossingLst = zcLst)))
     equation
     		zcIndxLst = zeroCrossingsContainIndex(eqn,0,zcLst);
				strLst = Util.listMap1(zcIndxLst,buildDiscreteVarChangesAddEvent,cr);
				outString = Util.stringDelimitList(strLst,"\n");
     then outString;
    case(_,_,_) equation
      print("buildDiscreteVarChangesVar2 failed\n");
      then fail();
  end matchcontinue;
end buildDiscreteVarChangesVar2;

protected function zeroCrossingsContainIndex "Returns the zero crossing indices that contains equation
given by input index."
  input Integer eqn "equation index";
  input Integer i "iterator for zc starts at 0 to n-1 zero crossings";
  input	list<DAELow.ZeroCrossing> zcLst;
  output list<Integer> eqns;
algorithm
  eqns := matchcontinue(eqn,i,zcLst)
    local list<Integer> eqnLst;
    case (_,_,{}) then {};
    case(eqn,i,DAELow.ZERO_CROSSING(occurEquLst=eqnLst)::zcLst) equation
      true = listMember(eqn,eqnLst);
      eqns = zeroCrossingsContainIndex(eqn,i+1,zcLst);
    then  i::eqns;
    case(eqn,i,_::zcLst) equation
      eqns = zeroCrossingsContainIndex(eqn,i+1,zcLst);
    then  eqns;
  end matchcontinue;
end zeroCrossingsContainIndex;

protected function buildDiscreteVarChangesAddEvent
"help function to buildDiscreteVarChangesVar2
 Generates 'if (change(v)) needToIterate=1 for and index i and variable v"
  input Integer indx;
  input DAE.ComponentRef cr;
  output String str;
protected
	String crStr,indxStr;
algorithm
	crStr := Exp.printComponentRefStr(cr);
	indxStr := intString(indx);
	str := Util.stringAppendList({"if (change(",crStr,")) { needToIterate=1; }"});
end buildDiscreteVarChangesAddEvent;

protected function buildWhenConditionChecks
"function:  buildWhenConditionChecks
Generates simulation code that checks whether a when condition has become true."
  input DAELow.DAELow inDAELow          "The lowered DAE";
  input list<list<Integer>> comps       "The order of the sorted equations";
  output String outString               "The generated C-code";
  output list<HelpVarInfo> helpVarList  "List of help variables that were introduced by this function.";
algorithm
  (outString,helpVarLst):=
  matchcontinue (inDAELow,comps)
    local
      list<Integer> orderOfEquations,orderOfEquations_1;
      list<DAELow.Equation> eqnl;
      Integer n;
      String res1,res2,res;
      list<HelpVarInfo> helpVarInfo1,helpVarInfo2,helpVarInfo;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      list<DAELow.WhenClause> whenClauseList;
      list<list<Integer>> blocks;
    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,eventInfo = DAELow.EVENT_INFO(whenClauseLst = whenClauseList))),blocks)
      equation
        orderOfEquations = generateEquationOrder(blocks);
        eqnl = DAELow.equationList(eqns);
        n = listLength(eqnl);
        orderOfEquations_1 = addMissingEquations(n, orderOfEquations);
        // First generate checks for all when equations, in the order of the sorted equations.
        (res1,helpVarInfo1) = buildWhenConditionChecks4(orderOfEquations_1, eqnl, whenClauseList, 0);
        n = listLength(helpVarInfo1);
        // Generate checks also for when clauses without equations but containing reinit statements.
        (res2,helpVarInfo2) = buildWhenConditionChecks2(whenClauseList, 0, n);
        res = stringAppend(res1, res2);
        helpVarInfo = listAppend(helpVarInfo1, helpVarInfo2);
      then
        (res,helpVarInfo);
    case (_,_)
      equation
        print("-build_when_condition_checks failed.\n");
      then
        fail();
  end matchcontinue;
end buildWhenConditionChecks;

protected function generateEventCheckingCode
"function:  generateEventCheckingCode"
  input DAELow.DAELow inDAELow1;
  input list<list<Integer>> inIntegerLstLst2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input DAELow.IncidenceMatrix inIncidenceMatrix5;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT6;
  input Absyn.Path inPath7;
  output String outString "Generated event checking code";
  output list<HelpVarInfo> helpVarLst "List of introduced help variables";
algorithm
  (outString,helpVarLst):=
  matchcontinue (inDAELow1,inIntegerLstLst2,inIntegerArray3,inIntegerArray4,inIncidenceMatrix5,inIncidenceMatrixT6,inPath7)
    local
      Boolean usezc;
      String check_code,check_code_1,res,check_code2,check_code2_1;
      list<HelpVarInfo> helpVarInfo;
      DAELow.DAELow dlow;
      list<list<Integer>> comps;
      Integer[:] ass1,ass2;
      list<Integer>[:] m,mt;
      Absyn.Path class_;
    case (dlow,comps,ass1,ass2,m,mt,class_)
      equation
        usezc = useZerocrossing();
        // The eventChecking consist of checking if the helpvariables from when equations has changed
        // and checking if discrete variables in the model has changed.
        (check_code,helpVarInfo) = buildWhenConditionChecks(dlow, comps);
        check_code2 = buildDiscreteVarChanges(dlow,comps,ass1,ass2,m,mt);
        check_code_1 = Util.if_(usezc, check_code, "");
        check_code2_1 = Util.if_(usezc,check_code2, "");
        res = Util.stringAppendList(
          {"int checkForDiscreteVarChanges()\n{\n",
          "  int needToIterate=0;\n",
          check_code_1,"  ",check_code2_1,"\n",
				  "  for (long i = 0; i < localData->nHelpVars; i++) {\n",
				  "    if (change(localData->helpVars[i])) { needToIterate=1; }\n  }\n",
          "  return needToIterate;\n","}\n"});
      then
        (res,helpVarInfo);
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_event_checking_code failed"});
      then
        fail();
  end matchcontinue;
end generateEventCheckingCode;

protected function generateOdeBlocks
"function: generateOdeBlocks
  author: PA
  Generates the simulation code for the ode code."
  input DAE.DAElist inDAElist1;
	input Boolean genDiscrete "if true generate calculation of discrete variables";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4,inInteger5)
    local
      input DAE.DAElist daelist;
      Integer cg_id,cg_id_1,cg_id_2,eqn;
      Codegen.CFunction s1,s2,res;
      list<CFunction> f1,f2,res2;
      DAELow.DAELow dae;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;
    case (daelist,genDiscrete,_,_,_,{},cg_id) then (Codegen.cEmptyFunction,cg_id,{});  /* cg var_id block code cg var_id extra functions code */
    case (daelist,genDiscrete,dae,ass1,ass2,((block_ as (_ :: (_ :: _))) :: blocks),cg_id)
      equation
        (s1,cg_id_1,f1) = generateOdeSystem(daelist,genDiscrete,dae, ass1, ass2, block_, cg_id) "For system of equations" ;
        (s2,cg_id_2,f2) = generateOdeBlocks(daelist,genDiscrete,dae, ass1, ass2, blocks, cg_id_1);
        res = Codegen.cMergeFns({s1,s2});
        res2 = listAppend(f1, f2);
      then
        (res,cg_id_2,res2);
    case (daelist,genDiscrete,dae,ass1,ass2,((block_ as {eqn}) :: blocks),cg_id)
      equation
        (s1,cg_id_1,f1) = generateOdeEquation(genDiscrete,dae,ass1, ass2, eqn, cg_id) "for single equations" ;
        (s2,cg_id_2,f2) = generateOdeBlocks(daelist,genDiscrete,dae, ass1, ass2, blocks, cg_id_1);
        res = Codegen.cMergeFns({s1,s2});
        res2 = listAppend(f1, f2);
      then
        (res,cg_id_2,res2);
    case (_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generate_ode_blocks failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeBlocks;

protected function generateOdeBlocks_new
"function: generateOdeBlocks
  author: PA
  Generates the simulation code for the ode code."
  input DAE.DAElist inDAElist1;
	input Boolean genDiscrete "if true generate calculation of discrete variables";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<list<Integer>> inIntegerLstLst4;
  input Integer inInteger5;
  input list<HelpVarInfo> helpvarinfo;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLstLst4,inInteger5,helpvarinfo)
    local
      input DAE.DAElist daelist;
      Integer cg_id,cg_id_1,cg_id_2,eqn;
      Codegen.CFunction s1,s2,res;
      list<CFunction> f1,f2,res2;
      DAELow.DAELow dae;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;
      list<HelpVarInfo> helpvarinfo1;
    case (daelist,genDiscrete,_,_,_,{},cg_id,_) then (Codegen.cEmptyFunction,cg_id,{});  /* cg var_id block code cg var_id extra functions code */
    case (daelist,genDiscrete,dae,ass1,ass2,((block_ as (_ :: (_ :: _))) :: blocks),cg_id,helpvarinfo1)
      equation
        (s1,cg_id_1,f1) = generateOdeSystem(daelist,genDiscrete,dae, ass1, ass2, block_, cg_id) "For system of equations" ;
        (s2,cg_id_2,f2) = generateOdeBlocks_new(daelist,genDiscrete,dae, ass1, ass2, blocks, cg_id_1,helpvarinfo1);
        res = Codegen.cMergeFns({s1,s2});
        res2 = listAppend(f1, f2);
      then
        (res,cg_id_2,res2);
    case (daelist,genDiscrete,dae,ass1,ass2,((block_ as {eqn}) :: blocks),cg_id,helpvarinfo1)
      equation
        (s1,cg_id_1,f1) = generateOdeEquation_new(genDiscrete,dae, ass1, ass2, eqn, cg_id,helpvarinfo1) "for single equations" ;
        (s2,cg_id_2,f2) = generateOdeBlocks_new(daelist,genDiscrete,dae, ass1, ass2, blocks, cg_id_1,helpvarinfo1);
        res = Codegen.cMergeFns({s1,s2});
        res2 = listAppend(f1, f2);
      then
        (res,cg_id_2,res2);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generate_ode_blocks failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeBlocks_new;

protected function generateOdeSystem "function: generateOdeSystem
  author: PA

  Generates code for a subsystem of equations, both linear and non-linear
  and mixed systems with both discrete and continuous variables.

  A linear system can be written as A x = b
  where A is a n by n matrix and b is a vector of size n.
  Such a system can for instance be solved by gaussian elimination or by
  using numerical methods in LAPACK.

  A non-linear system of equations is solved by the hybrd function. To solve
  the system a function that calculates the residuals of the equations must
  be given. The hybrd function also needs to calcutate the dierivatives of
  the equation system, i.e. the jacobian. Currently this is performed
  numerically, but it could also be done analytically for systems which
  have an analytic jacobian.

  A mixed system of equations contain both continuous and discrete time
  variables. Such system is solved by first guessing values on the
  discrete time variables (e.g. based on previous values). Then the
  continous time variables are solved. Finally, the discrete variables
  are checked to see if they fullfill the constraints of the system
  equations. If not, a fixed point iteration over the possible values of
   the discrete variables are made.
  Note that a mixed system can also be linear or non-linear.

  If the Boolean genDiscrete is true, mixed systems are generated with both discrete and continous
  equations, i.e. as mixed systems are solved during event iteration. If genDiscrete is false,
  only the continous part is generated (no discrete equations at all), i.e. what is necessary to
  calculate during continuous integration.
"
  input DAE.DAElist inDAElist1;
	input Boolean genDiscrete "if true generate discrete equations";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inIntegerLst4,inInteger5)
    local
      DAE.DAElist dae;
      String rettp,fn;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,var_lst_1,cont_var1;
      DAELow.Variables vars_1,vars,knvars,exvars;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,daelow,subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      String s;
      Codegen.CFunction s2,s1,s0,s2_1,s3,s4,cfn;
      Integer cg_id_1,cg_id,cg_id3,cg_id1,cg_id2,cg_id4,cg_id5;
      list<CFunction> f1,extra_funcs1;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      DAELow.ExternalObjectClasses eoc;
      list<String> retrec,arg,locvars,init,locvars,stmts,cleanups,stmts_1,stmts_2;

      /* Mixed system of equations, continuous part only */
    case (dae,false,(daelow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_,cg_id)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
 				cont_var1 = Util.listMap(cont_var, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc);
        //print("subsystem dae:"); DAELow.dump(cont_subsystem_dae);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        //print("mixed system, subsystem incidence matrix:\n");
        //DAELow.dumpIncidenceMatrix(m);
        //print("mixed system, calculating jacobian....\n");
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,true) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        //print("mixed system, analyzing jacobian\n");
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        //print("mixed syste, jacobian_str\n");
        //s = DAELow.jacobianTypeStr(jac_tp);
        //print("mixed system with Jacobian type: "); print(s); print("\n");
        //s = DAELow.dumpJacobianStr(jac);
        //print("jacobian ="); print(s); print("\n");

        (s2,cg_id_1,f1) = generateOdeSystem2(dae,false,false,cont_subsystem_dae, jac, jac_tp, cg_id);
      then
        (s2,cg_id_1,f1);

        /* Mixed system of equations, both continous and discrete eqns*/
    case (dae,true,(dlow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al, ev,eoc)),ass1,ass2,block_,cg_id)
      local Integer numValues;
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
				cont_var1 = Util.listMap(cont_var, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc);
        //print("subsystem dae:"); DAELow.dump(cont_subsystem_dae);
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,true) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        (s0,cg_id1,numValues) = generateMixedHeader(cont_eqn, cont_var, disc_eqn, disc_var, cg_id);
        (Codegen.CFUNCTION(rettp,fn,retrec,arg,locvars,init,stmts,cleanups),cg_id2,extra_funcs1) = generateOdeSystem2(dae,true/*mixed system*/,true,cont_subsystem_dae, jac, jac_tp, cg_id1);
        stmts_1 = Util.listFlatten({{"{"},locvars,stmts,{"}"}}) "initialization of e.g. matrices for linsys must be done in each
	    iteration, create new scope and put them first." ;
        s2_1 = Codegen.CFUNCTION(rettp,fn,retrec,arg,{},init,stmts_1,cleanups);
        (s4,cg_id3) = generateMixedFooter(cont_eqn, cont_var, disc_eqn, disc_var, cg_id2);
        (s3,cg_id4,_) = generateMixedSystemDiscretePartCheck(disc_eqn, disc_var, cg_id3,numValues);
        (s1,cg_id5,_) = generateMixedSystemStoreDiscrete(disc_var, 0, cg_id4);
        cfn = Codegen.cMergeFns({s0,s1,s2_1,s3,s4});
      then
        (cfn,cg_id5,extra_funcs1);

        /* continuous system of equations try tearing algorithm*/
    case (dae,genDiscrete,(daelow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,block_,cg_id)
      local
        DAELow.DAELow subsystem_dae_1,subsystem_dae_2;
        Integer[:] v1,v2,v1_1,v2_1;
        DAELow.IncidenceMatrix m_2,m_3;
        DAELow.IncidenceMatrixT mT_2,mT_3;
        list<list<Integer>> comps,comps_1;
        list<Integer> comps_flat;
        list<list<Integer>> r,t;
        list<Integer> rf,tf;
      equation
        // check tearing
        true = RTOpts.debugFlag("tearing");
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2) "extract the variables and equations of the block." ;
        var_lst_1 = Util.listMap(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(var_lst_1);
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc) "not used" ;
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        (v1,v2,subsystem_dae_1,m_2,mT_2) = DAELow.matchingAlgorithm(subsystem_dae, m_1, mt_1, (DAELow.NO_INDEX_REDUCTION(), DAELow.EXACT(), DAELow.KEEP_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m_2, mT_2, v1,v2);
        (subsystem_dae_2,m_3,mT_3,v1_1,v2_1,comps_1,r,t) = DAELow.tearingSystem(subsystem_dae_1,m_2,mT_2,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_3, mT_3,false) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac);
        (s1,cg_id_1,f1) = generateTearingSystem(dae,v1_1,v2_1,comps_flat,rf,tf,false,genDiscrete,subsystem_dae_2, jac, jac_tp, cg_id);
      then
        (s1,cg_id_1,f1);

        /* continuous system of equations */
    case (dae,genDiscrete,(daelow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,block_,cg_id)
      equation
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2) "extract the variables and equations of the block." ;
        var_lst_1 = Util.listMap(var_lst, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(var_lst_1);
        eqns_1 = DAELow.listEquation(eqn_lst);
        subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc) "not used" ;
        m = DAELow.incidenceMatrix(subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1,false) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(subsystem_dae, jac);
        (s1,cg_id_1,f1) = generateOdeSystem2(dae,false,genDiscrete,subsystem_dae, jac, jac_tp, cg_id) "	print \"generating subsystem :\" &
	DAELow.dump subsystem_dae &" ;
      then
        (s1,cg_id_1,f1);
    case (_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generate_ode_system failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem;

protected function generateMixedHeader "function: generateMixedHeader
  author: PA

  Generates the header code for a mixed system.
"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input list<DAELow.Equation> inDAELowEquationLst3;
  input list<DAELow.Var> inDAELowVarLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output Integer numValues;
algorithm
  (outCFunction,outInteger,numValues):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inDAELowEquationLst3,inDAELowVarLst4,inInteger5)
    local
      Integer len,cg_id_1,cg_id;
      String len_str,stmt;
      Codegen.CFunction cfn1,cfcn,cfcn_1;
      list<DAELow.Equation> cont_eqns,disc_eqns;
      list<DAELow.Var> cont_vars,disc_vars;
    case (cont_eqns,cont_vars,disc_eqns,disc_vars,cg_id) /* continous eqns continuous vars discrete eqns discrete vars cg var_id cg var_id */
      equation
        len = listLength(disc_vars);
        len_str = intString(len);
        stmt = Util.stringAppendList({"mixed_equation_system(",len_str,");"});
        (cfn1,cg_id_1,numValues) = generateMixedDiscretePossibleValues(cont_eqns, cont_vars, disc_eqns, disc_vars, cg_id);
        cfcn = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
        cfcn_1 = Codegen.cMergeFns({cfcn,cfn1});
      then
        (cfcn_1,cg_id_1,numValues);
  end matchcontinue;
end generateMixedHeader;

protected function generateMixedDiscretePossibleValues "function

"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input list<DAELow.Equation> inDAELowEquationLst3;
  input list<DAELow.Var> inDAELowVarLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output Integer numValues;
algorithm
  (outCFunction,outInteger,numValues):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inDAELowEquationLst3,inDAELowVarLst4,inInteger5)
    local
      list<DAE.Exp> rels;
      list<list<String>> values,values_1;
      list<Integer> value_dims;
      list<String> values_2,ss;
      String s,s2,disc_len_str,values_len_str,stmt1,stmt2;
      Integer disc_len,values_len,cg_id;
      Codegen.CFunction cfn_1;
      list<DAELow.Equation> cont_e,disc_e;
      list<DAELow.Var> cont_v,disc_v;
    case (cont_e,cont_v,disc_e,disc_v,cg_id) /* continous eqns continuous vars discrete eqns discrete vars cg var_id cg var_id */
      equation
        rels = mixedCollectRelations(cont_e, disc_e);
        (values,value_dims) = generateMixedDiscretePossibleValues2(rels, disc_v, cg_id);
        values_1 = generateMixedDiscreteCombinationValues(values);
        values_2 = Util.listFlatten(values_1);
        ss = Util.listMap(value_dims, int_string);
        s = Util.stringDelimitList(ss, ", ");
        s2 = Util.stringDelimitList(values_2, ", ");
        disc_len = listLength(disc_v);
        disc_len_str = intString(disc_len);
        values_len = listLength(values_2);
        values_len_str = intString(values_len);
        stmt1 = Util.stringAppendList({"double values[",values_len_str,"]={",s2,"};"});
        stmt2 = Util.stringAppendList({"int value_dims[",disc_len_str,"]={",s,"};"});
        cfn_1 = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt1,stmt2});
      then
        (cfn_1,cg_id,values_len);
    case (_,_,_,_,_)
      equation
        print("generate_mixed_discrete_possible_values failed\n");
      then
        fail();
  end matchcontinue;
end generateMixedDiscretePossibleValues;

protected function mixedCollectRelations "function: mixedCollectRelations
  author: PA


"
  input list<DAELow.Equation> c_eqn;
  input list<DAELow.Equation> d_eqn;
  output list<DAE.Exp> res;
  list<DAE.Exp> l1,l2;
algorithm
  l1 := mixedCollectRelations2(c_eqn);
  l2 := mixedCollectRelations2(d_eqn);
  res := listAppend(l1, l2);
end mixedCollectRelations;

protected function mixedCollectRelations2 "function: mixedCollectRelations2
  author: PA

  Helper function to mixed_collect_functions.
"
  input list<DAELow.Equation> inDAELowEquationLst;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inDAELowEquationLst)
    local
      list<DAE.Exp> l1,l2,l3,res;
      DAE.Exp e1,e2;
      list<DAELow.Equation> es;
      DAE.ComponentRef cr;
    case ({}) then {};
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: es))
      equation
        l1 = Exp.getRelations(e1);
        l2 = Exp.getRelations(e2);
        l3 = mixedCollectRelations2(es);
        res = Util.listFlatten({l1,l2,l3});
      then
        res;
    case ((DAELow.SOLVED_EQUATION(componentRef = cr,exp = e1) :: es))
      equation
        l1 = Exp.getRelations(e1);
        l2 = mixedCollectRelations2(es);
        res = listAppend(l1, l2);
      then
        res;
    case (_) then {};
  end matchcontinue;
end mixedCollectRelations2;

protected function generateMixedDiscreteCombinationValues "function generateMixedDiscreteCombinationValues
  author: PA

  Generates all combinations of the values given as argument
"
  input list<list<String>> inStringLstLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inStringLstLst)
    local
      list<String> value;
      list<list<String>> values_1,values;
    case ({value}) then {value};  /* values */
    case (values)
      equation
        values_1 = generateMixedDiscreteCombinationValues1(values) "&
	Util.list_strip_last(values\') => values\'\'" ;
      then
        values_1;
  end matchcontinue;
end generateMixedDiscreteCombinationValues;

protected function generateMixedDiscreteCombinationValues1
  input list<list<String>> inStringLstLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inStringLstLst)
    local
      list<list<String>> value_1,values_1,values_2,values;
      list<String> value;
    case ({value}) /* values */
      equation
        value_1 = Util.listMap(value, Util.listCreate);
      then
        value_1;
    case ((value :: values))
      equation
        values_1 = generateMixedDiscreteCombinationValues1(values);
        values_2 = generateMixedDiscreteCombinationValues2(value, values_1);
      then
        values_2;
  end matchcontinue;
end generateMixedDiscreteCombinationValues1;

protected function generateMixedDiscreteCombinationValues2 "function generateMixedDiscreteCombinationValues2
  author: PA

  Helper function to generate_mixed_discrete_combination_values.
  Insert a list of values producing all combinations with given list of list
  of values.
"
  input list<String> inStringLst;
  input list<list<String>> inStringLstLst;
  output list<list<String>> outStringLstLst;
algorithm
  outStringLstLst:=
  matchcontinue (inStringLst,inStringLstLst)
    local
      list<list<String>> lst,lst_1,lst2,res;
      String s;
      list<String> ss;
    case ({},lst) then {};
    case ((s :: ss),lst) /* rule	Util.list_list_map_1(lst,Util.list_make_2,s) => lst1 &
	Util.list_flatten(lst1) => lst1\' &
	generate_mixed_discrete_combination_values2(ss,lst) => lst2 &
	list_append(lst1\',lst2) => res
	---------------------------------
	generate_mixed_discrete_combination_values2(s::ss,lst) => res */
      equation
        lst_1 = Util.listMap1(lst, Util.listCons, s);
        lst2 = generateMixedDiscreteCombinationValues2(ss, lst);
        res = listAppend(lst_1, lst2);
      then
        res;
  end matchcontinue;
end generateMixedDiscreteCombinationValues2;

protected function generateMixedDiscretePossibleValues2 "function: generateMixedDiscretePossibleValues2

  Helper function to generate_mixed_discrete_possible_values.
"
  input list<DAE.Exp> inExpExpLst;
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  output list<list<String>> outStringLstLst;
  output list<Integer> outIntegerLst;
algorithm
  (outStringLstLst,outIntegerLst):=
  matchcontinue (inExpExpLst,inDAELowVarLst,inInteger)
    local
      Integer cg_id;
      list<list<String>> values;
      list<Integer> dims;
      list<DAE.Exp> rels;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case (_,{},cg_id) then ({},{});  /* discrete vars cg var_id values value dimension */
    case (rels,(v :: vs),cg_id) /* booleans, generate true (1.0) and false (0.0) */
      equation
        DAELow.BOOL() = DAELow.varType(v);
        (values,dims) = generateMixedDiscretePossibleValues2(rels, vs, cg_id);
      then
        (({"1.0","0.0"} :: values),(2 :: dims));
    case (rels,(v :: vs),_)
      equation
        DAELow.INT() = DAELow.varType(v);
        Error.addMessage(Error.INTERNAL_ERROR,
          {
          "Mixed system of equations with dicrete variables of type Integer not supported. Try to rewrite using Boolean variables."});
      then
        fail();
  end matchcontinue;
end generateMixedDiscretePossibleValues2;

protected function generateMixedFooter "function: generateMixedFooter
  author: PA

  Generates the header code for a mixed system.
"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input list<DAELow.Equation> inDAELowEquationLst3;
  input list<DAELow.Var> inDAELowVarLst4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inDAELowEquationLst3,inDAELowVarLst4,inInteger5)
    local
      Integer len,cg_id;
      String len_str,stmt;
      Codegen.CFunction cfcn;
      list<DAELow.Equation> cont_eqns,disc_eqns;
      list<DAELow.Var> cont_vars,disc_vars;
    case (cont_eqns,cont_vars,disc_eqns,disc_vars,cg_id) /* continous eqns continuous vars discrete eqns discrete vars cg var_id cg var_id */
      equation
        len = listLength(disc_vars);
        len_str = intString(len);
        stmt = Util.stringAppendList({"mixed_equation_system_end(",len_str,");"});
        cfcn = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (cfcn,cg_id);
  end matchcontinue;
end generateMixedFooter;

protected function generateMixedSystemStoreDiscrete "function: generateMixedSystemStoreDiscrete
  author: PA

  Stores all discrete variables in discrite_loc variable.
"
  input list<DAELow.Var> inDAELowVarLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output Codegen.CFunction outCFunction;
  output Integer outInteger;
  output list<Codegen.CFunction> outCodegenCFunctionLst;
algorithm
  (outCFunction,outInteger,outCodegenCFunctionLst):=
  matchcontinue (inDAELowVarLst1,inInteger2,inInteger3)
    local
      Integer cg_id,indx_1,cg_id_1,indx;
      Codegen.CFunction cfn,cfn_1;
      list<CFunction> funcs;
      DAE.ComponentRef cr;
      String indx_str,cr_str,stmt;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ({},_,cg_id) then (Codegen.cEmptyFunction,cg_id,{});  /* indx cg var_id cg var_id */
    case ((v :: vs),indx,cg_id)
      equation
        indx_1 = indx + 1;
        (cfn,cg_id_1,funcs) = generateMixedSystemStoreDiscrete(vs, indx_1, cg_id);
        cr = DAELow.varCref(v);
        indx_str = intString(indx);
        cr_str = Exp.printComponentRefStr(cr);
        stmt = Util.stringAppendList({"discrete_loc[",indx_str,"] = ",cr_str,";"});
        cfn_1 = Codegen.cAddStatements(cfn, {stmt});
      then
        (cfn_1,cg_id_1,funcs);
    case (_,_,cg_id)
      equation
        print("generate_mixed_system_store_discrete failed\n");
      then
        fail();
  end matchcontinue;
end generateMixedSystemStoreDiscrete;

protected function generateMixedSystemDiscretePartCheck "function: generateMixedSystemDiscretePartCheck
  author: PA

  Generates check of the discrete parts.
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input list<DAELow.Var> inDAELowVarLst;
  input Integer inInteger;
  input Integer numValues;
  output Codegen.CFunction outCFunction;
  output Integer outInteger;
  output list<Codegen.CFunction> outCodegenCFunctionLst;
algorithm
  (outCFunction,outInteger,outCodegenCFunctionLst):=
  matchcontinue (inDAELowEquationLst,inDAELowVarLst,inInteger,numValues)
    local
      Codegen.CFunction cfn,cfn_1;
      Integer cg_id,len;
      list<CFunction> funcs;
      String len_str,ptrs_str,stmt1,stmt2,numValuesStr;
      list<DAE.ComponentRef> crefs;
      list<String> strs,strs2;
      list<DAELow.Equation> eqn;
      list<DAELow.Var> var;
    case (eqn,var,cg_id,numValues) /* cg var_id cg var_id */
      equation
        (cfn,cg_id,funcs) = generateMixedSystemDiscretePartCheck2(eqn, var, 0, cg_id);
        len = listLength(eqn);
        len_str = intString(len);
        crefs = Util.listMap(var, DAELow.varCref);
        strs = Util.listMap(crefs, Exp.printComponentRefStr);
        strs2 = Util.listMap1r(strs, string_append, "&");
        ptrs_str = Util.stringDelimitList(strs2, ", ");
        numValuesStr = intString(numValues);
        stmt1 = Util.stringAppendList({"double *loc_ptrs[",len_str,"]={",ptrs_str,"};"});
        stmt2 = Util.stringAppendList({"check_discrete_values(",len_str,",",numValuesStr,");"});
        cfn_1 = Codegen.cAddStatements(cfn, {"{",stmt1,stmt2,"}"});
      then
        (cfn_1,cg_id,funcs);
  end matchcontinue;
end generateMixedSystemDiscretePartCheck;

protected function generateMixedSystemDiscretePartCheck2
  input list<DAELow.Equation> inDAELowEquationLst1;
  input list<DAELow.Var> inDAELowVarLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  output Codegen.CFunction outCFunction;
  output Integer outInteger;
  output list<Codegen.CFunction> outCodegenCFunctionLst;
algorithm
  (outCFunction,outInteger,outCodegenCFunctionLst):=
  matchcontinue (inDAELowEquationLst1,inDAELowVarLst2,inInteger3,inInteger4)
    local
      Integer cg_id,indx_1,cg_id_1,cg_id_2,indx;
      Codegen.CFunction cfn,exp_func,exp_func_1,cfn_1;
      list<CFunction> funcs;
      DAE.ComponentRef cr;
      DAE.Exp varexp,expr,e1,e2;
      String var,indx_str,cr_str,stmt,stmt2;
      list<DAELow.Equation> eqns;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ({},_,_,cg_id) then (Codegen.cEmptyFunction,cg_id,{});  /* index cg var_id cg var_id */
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: eqns),(v :: vs),indx,cg_id)
      equation
        indx_1 = indx + 1;
        (cfn,cg_id_1,funcs) = generateMixedSystemDiscretePartCheck2(eqns, vs, indx_1, cg_id);
        cr = DAELow.varCref(v);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_2) = Codegen.generateExpression(expr, cg_id_1, Codegen.simContext);
        indx_str = intString(indx);
        cr_str = Exp.printComponentRefStr(cr);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        stmt2 = Util.stringAppendList({"discrete_loc2[",indx_str,"] = ",cr_str,";"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt,stmt2});
        cfn_1 = Codegen.cMergeFns({exp_func_1,cfn});
      then
        (cfn_1,cg_id_2,funcs);
    case (_,_,_,cg_id)
      equation
        print("generate_mixed_system_discrete_part_check2 failed\n");
      then
        fail();
  end matchcontinue;
end generateMixedSystemDiscretePartCheck2;

protected function splitMixedEquations "function: splitMixedEquations
  author: PA

  Splits the equation of a mixed equation system into its continuous and
  discrete parts.

  Even though the matching algorithm might say that a discrete variable is solved in a specific equation
  (when part of a mixed system) this is not always correct. It might be impossible to solve the discrete
  variable from that equation, for instance solving v from equation x = v < 0; This happens for e.g. the Gear model.
  Instead, to split the equations and variables the following scheme is used:

  1. Split the variables into continuous and discrete.
  2. For each discrete variable v, select among the equations where it is present
   for an equation v = expr. (This could be done
   by looking at incidence matrix but for now we look through all equations. This is sufficiently
   efficient for small systems of mixed equations < 100)
  3. The equations not selected in step 2 are continuous equations.
"
  input list<DAELow.Equation> eqnLst;
  input list<DAELow.Var> varLst;
  output list<DAELow.Equation> contEqnLst;
  output list<DAELow.Var> contVarLst;
  output list<DAELow.Equation> discEqnLst;
  output list<DAELow.Var> discVarLst;
algorithm
  (contEqnLst,contVarLst,discEqnLst,discVarLst):=
  matchcontinue (eqnLst,varLst)
      case (eqnLst,varLst) equation
        discVarLst = Util.listSelect(varLst,DAELow.isVarDiscrete);
        contVarLst = Util.listSetDifferenceOnTrue(varLst,discVarLst,DAELow.varEqual);
			  discEqnLst = Util.listMap1(discVarLst,findDiscreteEquation,eqnLst);
			  contEqnLst = Util.listSetDifferenceOnTrue(eqnLst,discEqnLst,DAELow.equationEqual);
			  then (contEqnLst,contVarLst,discEqnLst,discVarLst);
  end matchcontinue;
end splitMixedEquations;

protected function findDiscreteEquation "help function to splitMixedEquations, finds the discrete equation
on the form v = expr for solving variable v"
  input DAELow.Var v;
  input list<DAELow.Equation> eqnLst;
  output DAELow.Equation eqn;
algorithm
  eqn := matchcontinue(v,eqnLst)
    local DAE.ComponentRef cr1,cr;
      DAE.Exp e2;
    case (v,(eqn as DAELow.EQUATION(DAE.CREF(cr,_),e2,_))::_) equation
      cr1=DAELow.varCref(v);
      true = Exp.crefEqual(cr1,cr);
    then eqn;
    case(v,(eqn as DAELow.EQUATION(e2,DAE.CREF(cr,_),_))::_) equation
      cr1=DAELow.varCref(v);
      true = Exp.crefEqual(cr1,cr);
    then eqn;
    case(v,_::eqnLst) equation
      eqn = findDiscreteEquation(v,eqnLst);
    then eqn;
    case(v,_) equation
      print("findDiscreteEquation failed, searching for ");
      print(Exp.printComponentRefStr(DAELow.varCref(v)));
      print("\n");
    then fail();
  end matchcontinue;
end findDiscreteEquation;


protected function isMixedSystem "function: isMixedSystem
  author: PA

  Returns true if the list of variables is an equation system contains
  both discrete and continuous variables.
"
  input list<DAELow.Var> inDAELowVarLst;
  input list<DAELow.Equation> inEqns;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELowVarLst,inEqns)
    local list<DAELow.Var> vs;
      list<DAELow.Equation> eqns;
				/* A single algorithm section (consists of several eqns) is not mixed system */
      case (vs,eqns) equation
        singleAlgorithmSection2(eqns);
      then false;
    case (vs,eqns)
      equation
        true = hasDiscreteVar(vs);
        true = hasContinousVar(vs);
      then
        true;
    case (_,_) then false;
  end matchcontinue;
end isMixedSystem;

protected function hasDiscreteVar "
  Helper function to is_mixed_system. Returns true if var list contains
  discrete time variable.
"
  input list<DAELow.Var> inDAELowVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELowVarLst)
    local
      DAE.ComponentRef cr;
      Boolean res;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.DISCRETE()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varType = DAELow.INT()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varType = DAELow.BOOL()) :: _)) then true;
    case ((v :: vs))
      equation
        res = hasDiscreteVar(vs);
      then
        res;
    case ({}) then false;
  end matchcontinue;
end hasDiscreteVar;

protected function hasContinousVar "function: hasContinousVar
  author: PA

  Helper function to is_mixed_system. Returns true if var list contains
  discrete time variable.
"
  input list<DAELow.Var> inDAELowVarLst;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELowVarLst)
    local
      DAE.ComponentRef cr;
      Boolean res;
      DAELow.Var v;
      list<DAELow.Var> vs;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.VARIABLE()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.STATE()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.DUMMY_DER()) :: _)) then true;
    case ((DAELow.VAR(varName = cr,varKind = DAELow.DUMMY_STATE()) :: _)) then true;
    case ((v :: vs))
      equation
        res = hasContinousVar(vs);
      then
        res;
    case ({}) then false;
  end matchcontinue;
end hasContinousVar;

protected function generateOdeSystem2 "function: generateOdeSystem2
  author: PA

  Generates the actual simulation code for the system of equation, once
  its jacobian and type has been given.
"
  input DAE.DAElist inDAElist1;
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input DAELow.JacobianType inJacobianType;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,mixedEvent,genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inJacobianType,inInteger)
    local
      DAE.DAElist daelist;
      Codegen.CFunction s1,s2,s3,s4,s5,s;
      Integer cg_id_1,cg_id,eqn_size,unique_id,cg_id1,cg_id2,cg_id3,cg_id4,cg_id5;
      list<CFunction> f1;
      DAELow.DAELow dae;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      DAELow.Variables v,kv;
      DAELow.EquationArray eqn;
      list<DAELow.Equation> eqn_lst;
      list<DAELow.Var> var_lst;
      list<DAE.ComponentRef> crefs;
      DAELow.MultiDimEquation[:] ae;
      Boolean genDiscrete;
      list<Integer>[:] m,m_1,mt_1;
      /* A single array equation */
    case (daelist,mixedEvent,_,dae,jac,jac_tp,cg_id)
      equation
        singleArrayEquation(dae);
        (s1,cg_id_1,f1) = generateSingleArrayEqnCode(dae, jac, cg_id);
      then
        (s1,cg_id_1,f1);

        /* A single algorithm section for several variables. */
    case (daelist,mixedEvent,genDiscrete,dae,jac,jac_tp,cg_id)
      equation
        singleAlgorithmSection(dae);
        (s1,cg_id_1,f1) = generateSingleAlgorithmCode(genDiscrete, dae, jac, cg_id);
      then
        (s1,cg_id_1,f1);

        /* constant jacobians. Linear system of equations (A x = b) where
         A and b are constants. TODO: implement symbolic gaussian elimination here. Currently uses dgesv as
         for next case */
    case (daelist,mixedEvent,genDiscrete,(dae as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_CONSTANT(),cg_id)
      local list<tuple<Integer, Integer, DAELow.Equation>> jac;
      equation
        eqn_size = DAELow.equationSize(eqn);
        (s1,cg_id_1,f1) = generateOdeSystem2(daelist,mixedEvent,genDiscrete,dae, SOME(jac), DAELow.JAC_TIME_VARYING(), cg_id) "NOTE: Not impl. yet, use time_varying..." ;
      then
        (s1,cg_id_1,f1);

        /* Relaxation */
    case (daelist,mixedEvent,genDiscrete,(dae as DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_TIME_VARYING(),cg_id)
      local
        list<tuple<Integer, Integer, DAELow.Equation>> jac;
        DAELow.DAELow subsystem_dae_1,subsystem_dae_2;
        Integer[:] v1,v2,v1_1,v2_1;
        DAELow.IncidenceMatrix m_2,m_3;
        DAELow.IncidenceMatrixT mT_2,mT_3;
        list<list<Integer>> comps,comps_1;
        list<Integer> comps_flat;
        list<list<Integer>> r,t;
        list<Integer> rf,tf;        
      equation
        // check Relaxation
        true = RTOpts.debugFlag("relaxation");
        m = DAELow.incidenceMatrix(dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        (v1,v2,subsystem_dae_1,m_2,mT_2) = DAELow.matchingAlgorithm(dae, m_1, mt_1, (DAELow.NO_INDEX_REDUCTION(), DAELow.EXACT(), DAELow.KEEP_SIMPLE_EQN()));
        (comps) = DAELow.strongComponents(m_2, mT_2, v1,v2);
        (subsystem_dae_2,m_3,mT_3,v1_1,v2_1,comps_1,r,t) = DAELow.tearingSystem(subsystem_dae_1,m_2,mT_2,v1,v2,comps);
        true = listLength(r) > 0;
        true = listLength(t) > 0;
        comps_flat = Util.listFlatten(comps_1);
        rf = Util.listFlatten(r);
        tf = Util.listFlatten(t);        
        (s1,cg_id_1,f1) = generateRelaxationSystem(daelist,m_3,mT_3,v1_1,v2_1,comps_flat,rf,tf,subsystem_dae_2, cg_id);
      then
        (s1,cg_id_1,f1);

	/* Time varying jacobian. Linear system of equations that needs to
		  be solved during runtime. */
    case (daelist,mixedEvent,_,(DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn)),SOME(jac),DAELow.JAC_TIME_VARYING(),cg_id)
      local list<tuple<Integer, Integer, DAELow.Equation>> jac;
      equation
        //print("linearSystem of equations:");
        //DAELow.dump(d);
        //print("Jacobian:");print(DAELow.dumpJacobianStr(SOME(jac)));print("\n");
        eqn_size = DAELow.equationSize(eqn);
        unique_id = tick();
        (s1,cg_id1) = generateOdeSystem2Declaration(mixedEvent,eqn_size, unique_id, cg_id);
        (s2,cg_id2) = generateOdeSystem2PopulateAb(mixedEvent,jac, v, eqn, unique_id, cg_id1);
        (s3,cg_id3) = generateOdeSystem2SolveCall(mixedEvent,eqn_size, unique_id, cg_id2);
        (s4,cg_id4) = generateOdeSystem2CollectResults(mixedEvent,v, unique_id, cg_id3);
        s = Codegen.cMergeFns({s1,s2,s3,s4});
      then
        (s,cg_id4,{});
    case (daelist,mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),SOME(jac),DAELow.JAC_NONLINEAR(),cg_id) /* Time varying nonlinear jacobian. Non-linear system of equations */
      local list<tuple<Integer, Integer, DAELow.Equation>> jac;
      equation

        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates);// get varnames and prefix $der for states.
        (s1,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(mixedEvent,crefs, eqn_lst,ae, cg_id);
      then
        (s1,cg_id_1,f1);
    case (daelist,mixedEvent,_,DAELow.DAELOW(orderedVars = v,knownVars = kv,orderedEqs = eqn,arrayEqs=ae),NONE,DAELow.JAC_NO_ANALYTIC(),cg_id) /* no analythic jacobian available. Generate non-linear system */
      equation
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
        (s1,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(mixedEvent,crefs, eqn_lst, ae, cg_id);
      then
        (s1,cg_id_1,f1);
    case (_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generate_ode_system2 failed \n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2;

protected function generateRelaxationSystem "function: generateRelaxationSystem
  author: Frenkel TUD

  Generates the actual simulation code for the relaxed system of equation
"
  input DAE.DAElist inDAElist1;
  input DAELow.IncidenceMatrix inM;
  input DAELow.IncidenceMatrixT inMT;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input list<Integer> inIntegerLst5;
  input list<Integer> inIntegerLst6;
  input DAELow.DAELow inDAELow;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,inM,inMT,inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,inDAELow,inInteger)
    local
      DAE.DAElist daelist;
      Integer[:] ass1,ass2;
      list<Integer> block_,block_1,block_2,r,t;
      list<CFunction> cflst;
      Codegen.CFunction feqn;
      Integer cg_id,cg_id1,size;
      DAELow.DAELow daelow,daelow1;
      list<tuple<Integer, Integer, DAELow.Equation>> jac,jacA;
      DAELow.JacobianType jac_tp;
      DAELow.Variables v,kv,exv;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      DAELow.EquationArray eqn,eqn1,reeqn,ineq;
      list<DAELow.Equation> eqn_lst,eqn_lst1,eqn_lst2,reqns,solved;
      list<DAELow.Var> var_lst;
      list<DAE.ComponentRef> crefs,X;
      DAELow.MultiDimEquation[:] ae;
      Boolean genDiscrete;
      list<list<Integer>> eqnlstlst;
      VarTransform.VariableReplacements repl;
      DAE.Algorithm[:] algorithms;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
      DAELow.IncidenceMatrix m;
      DAELow.IncidenceMatrixT mT;
      list<DAE.Exp> exp_lst,B,A_lst,Af;
      list<list<DAE.Exp>> A,An;
    case (daelist,m,mT,ass1,ass2,block_,r,t,
          daelow as DAELow.DAELOW(orderedVars=v,knownVars=kv,externalObjects=exv,aliasVars=av,orderedEqs=eqn,removedEqs=reeqn,initialEqs=ineq,arrayEqs=ae,algorithms=algorithms,eventInfo=eventInfo,extObjClasses=extObjClasses),cg_id) 
      equation
        // get equations and variables
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        size = listLength(eqn_lst);
        // generate A
        A_lst = Util.listFill(DAE.RCONST(0.0),size);
        An = Util.listFill(A_lst,size);
        SOME(jac) = DAELow.calculateJacobian(v, eqn, ae, m, mT,false);
        // sort A
        jacA = Util.listMap2(jac,sortRelaxationSystemA,block_,ass1);
        A = generateRelaxationSystemA(jacA,An);
        // generate B
        exp_lst = generateRelaxationSystemB(eqn_lst,v);
        // sort b
        B = sortRelaxationSystemB(exp_lst,block_);
        // get names from variables
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
        // sort X
        X = sortRelaxationSystemX(crefs,block_,ass2);
        // gauss ellemination        
        solved = solveRelaxationSystem(A,X,B);
        // select equations
        block_1 = Util.listSelect1(block_,r,Util.listNotContains); 
        block_2 = listAppend(r,block_1);
        eqnlstlst = Util.listMap(block_2,Util.listCreate);
        eqn_lst1 = sortSolvedRelaxationSystem(solved,solved,block_);
        // replace r in org eqn list
        reqns = Util.listMap1r(r,listNth1,eqn_lst1);
        eqn_lst2 = sortSolvedRelaxationSystem(reqns,eqn_lst,r);
        eqn1 = DAELow.listEquation(eqn_lst2);
        daelow1=DAELow.DAELOW(v,kv,exv,av,eqn1,reeqn,ineq,ae,algorithms,eventInfo,extObjClasses);
        // generade code for equations
        (feqn,cg_id1,cflst) = buildSolvedBlocks(daelist,daelow1,ass1,ass2,eqnlstlst,cg_id);        
      then
        (feqn,cg_id1,cflst);
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generateRelaxationSystem failed \n");
      then
        fail();
  end matchcontinue;
end generateRelaxationSystem;

protected function generateRelaxationSystemB "function: generateRelaxationSystemB
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAELow.Equation> inDAELowEquationLst;
  input DAELow.Variables inVariables2;
  output list<DAE.Exp> outDAELowEquationLst;
algorithm
  outDAELowEquationLst:=
  matchcontinue (inDAELowEquationLst,inVariables2)
    local
      DAE.ExpType tp;
      DAE.Exp new_exp,rhs_exp,rhs_exp_1,rhs_exp_2,e1,e2,res_exp;
      list<DAELow.Equation> rest;
      list<DAE.Exp> rest1;
      DAELow.Variables v;
    case ({},_) then {};  
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),v)
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = DAELow.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = DAE.UNARY(DAE.UMINUS(tp),rhs_exp);
        rhs_exp_2 = Exp.simplify(rhs_exp_1);
        rest1 = generateRelaxationSystemB(rest,v);
      then
        rhs_exp_2::rest1;
    case ((DAELow.RESIDUAL_EQUATION(exp = res_exp) :: rest),v)
      equation
        rhs_exp = DAELow.getEqnsysRhsExp(res_exp, v);
        rhs_exp_1 = Exp.simplify(rhs_exp);
        rest1 = generateRelaxationSystemB(rest,v);
      then
        rhs_exp_1::rest1;
    case (_,_)
      equation
        Debug.fprint("failtrace", "generateRelaxationSystemB failed\n");
      then
        fail();
  end matchcontinue;
end generateRelaxationSystemB;

protected function listNth1 "function: listNth1
  author: Frenkel TUD
  Same as listNth but starts at 1
"
  input list<Type_a>  inALst;
  input Integer  inInteger;
  replaceable type Type_a subtypeof Any;
  output Type_a outA;
algorithm
  outA:= listNth(inALst,inInteger-1);
end listNth1;

protected function sortRelaxationSystemB "function: sortRelaxationSystemB
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAE.Exp>  inExpLst;
  input list<Integer> inIntegerLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inIntegerLst)
    local
      DAE.Exp e;
      list<DAE.Exp> elst,elst1;
      list<Integer> rest;
      Integer i;
    case (elst,{}) then {};  
    case (elst,i::rest)
      equation
        e = listNth(elst,i-1);
        elst1 = sortRelaxationSystemB(elst,rest);
      then
        e::elst1;
  end matchcontinue;
end sortRelaxationSystemB;

protected function sortSolvedRelaxationSystem "function: sortSolvedRelaxationSystem
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAELow.Equation>  inExpLst;
  input list<DAELow.Equation>  inExpLst1;
  input list<Integer> inIntegerLst;
  output list<DAELow.Equation> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inExpLst1,inIntegerLst)
    local
      DAELow.Equation e;
      list<DAELow.Equation> elst,elst1,res,res1;
      list<Integer> rest;
      Integer i;
    case (elst,elst1,{}) then elst1;  
    case (e::elst,elst1,i::rest)
      equation
        res = Util.listReplaceAt(e,i-1,elst1); 
        res1 = sortSolvedRelaxationSystem(elst,res,rest);
      then
        res1;
  end matchcontinue;
end sortSolvedRelaxationSystem;

protected function sortRelaxationSystemA "function: sortRelaxationSystemA
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input tuple<Integer, Integer, DAELow.Equation>  inJacElem;
  input list<Integer> inIntegerLst;
  input Integer[:] inIntegerArr;
  output tuple<Integer, Integer, DAELow.Equation> outJacElem;
algorithm
  outJacElem:=
  matchcontinue (inJacElem,inIntegerLst,inIntegerArr)
    local
      Integer z,z1,s,s1,e;
      DAELow.Equation eqn;
      list<Integer> comp;
      Integer[:] v1;
    case ( ((z,s,eqn)) ,comp,v1)
      equation
        z1 = Util.listPosition(z,comp);
        e = v1[s];
        s1 = Util.listPosition(e,comp);
      then
        ((z1,s1,eqn));
  end matchcontinue;
end sortRelaxationSystemA;

protected function generateRelaxationSystemA "function: generateRelaxationSystemA
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<tuple<Integer, Integer, DAELow.Equation>>  inJac;
  input list<list<DAE.Exp>> inA;
  output list<list<DAE.Exp>> outA;
algorithm
  outA:=
  matchcontinue (inJac,inA)
    local
      list<tuple<Integer, Integer, DAELow.Equation>> rest;
      list<list<DAE.Exp>> a,a1,a2;
      list<DAE.Exp> row,row1;
      DAE.Exp e,e1,e2;
      Integer z,s;
      DAELow.Equation eqn;
      DAE.ExpType tp;
    case ( {} ,a) then a;
    case ( ((z,s,DAELow.EQUATION(exp = e1,scalar = e2))::rest) ,a)
      equation
         tp = Exp.typeof(e1);
         e = DAE.BINARY(e1,DAE.SUB(tp),e2);
         row = listNth(a,z);
         row1 = Util.listReplaceAt(e,s,row); 
         a1 = Util.listReplaceAt(row1,z,a); 
         a2 = generateRelaxationSystemA(rest,a1);       
      then
        a2;      
    case ( ((z,s,DAELow.RESIDUAL_EQUATION(exp = e))::rest) ,a)
      equation
         row = listNth(a,z);
         row1 = Util.listReplaceAt(e,s,row); 
         a1 = Util.listReplaceAt(row1,z,a);        
         a2 = generateRelaxationSystemA(rest,a1);       
      then
        a2;
    case (((z,s,eqn)::rest),_)
      equation
        Debug.fprint("failtrace", "generateRelaxationSystemA failed\n");
        true = RTOpts.debugFlag("failtrace");
        DAELow.dumpEqns({eqn});
      then
        fail();        
    case (_,_)
      equation
        Debug.fprint("failtrace", "generateRelaxationSystemA failed\n");
      then
        fail();        
  end matchcontinue;
end generateRelaxationSystemA;

protected function sortRelaxationSystemX "function: sortRelaxationSystemB
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<DAE.ComponentRef>  inExpLst;
  input list<Integer> inIntegerLst;
  input Integer[:] inIntegerArr;
  output list<DAE.ComponentRef> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inExpLst,inIntegerLst,inIntegerArr)
    local
      DAE.ComponentRef c;
      list<DAE.ComponentRef> elst,elst1;
      list<Integer> rest;
      Integer i,e;
      Integer[:] v2;
    case (elst,{},_) then {};  
    case (elst,i::rest,v2)
      equation
        e = v2[i];
        c = listNth(elst,e-1);    
        elst1 = sortRelaxationSystemX(elst,rest,v2);
      then
        c::elst1;
  end matchcontinue;
end sortRelaxationSystemX;

protected function solveRelaxationSystem "function: solveRelaxationSystem
  author: Frenkel TUD
  Helper function to generateRelaxationSystem
"
  input list<list<DAE.Exp>> inA;
  input list<DAE.ComponentRef>  inX;
  input list<DAE.Exp> inB;
  output list<DAELow.Equation> outEqnLst;
algorithm
  outEqnLst:=
  matchcontinue (inA,inX,inB)
    local
      list<DAE.Exp> row,b,b1;
      list<DAE.ComponentRef> x;
      list<DAELow.Equation> s;
      DAE.ComponentRef c;
      list<list<DAE.Exp>> resta,a1,a2;
      DAE.Exp a_0,b_0,e,e1;
      DAE.ExpType tp;
      DAELow.Equation eqn;
    case ((a_0::{})::{},c::{},b_0::{})
      equation
        // solution
        tp = Exp.typeof(a_0);
        e = DAE.BINARY(b_0,DAE.DIV(tp),a_0);
        e1 = Exp.simplify(e);
      then
        {DAELow.EQUATION(DAE.CREF(c,tp),e1,DAE.emptyElementSource)};      
    case ((a_0::row)::resta,c::x,b_0::b)
      equation
        (a1,b1) = solveRelaxationSystem1(a_0,row,resta,b_0,b);
        eqn = solveRelaxationSystem3((a_0::row)::resta,b_0::b,c::x);
        // next
        s = solveRelaxationSystem(a1,x,b1);
      then
        eqn::s;
  end matchcontinue;
end solveRelaxationSystem;

protected function solveRelaxationSystem1 "function: solveRelaxationSystem1
  author: Frenkel TUD
  Helper function to solveRelaxationSystem
"
  input DAE.Exp  inA_0;
  input list<DAE.Exp>  inRow;
  input list<list<DAE.Exp>> inA;
  input DAE.Exp  inB_0;
  input list<DAE.Exp> inB;
  output list<list<DAE.Exp>> outA;
  output list<DAE.Exp> outB;
algorithm
  (outA,outB):=
  matchcontinue (inA_0,inRow,inA,inB_0,inB)
    local
      list<list<DAE.Exp>> resta,a;
      list<DAE.Exp> row_0,row,row1,line,b,bn;
      DAE.Exp a_0,a_i,b_0,b_i,b1,b2;
      DAE.ExpType tp;
    case (a_0,row_0,(a_i::row)::{},b_0,b_i::{})
      equation
        // arow
        row1 = solveRelaxationSystem2(a_0,a_i,row_0,row);
        // b
        tp = Exp.typeof(b_i);
        b1 = DAE.BINARY(b_i,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(b_0,DAE.DIV(tp),a_0))); 
        b2 = Exp.simplify(b1);
      then
        ({row1},{b2});      
    case (a_0,row_0,(a_i::row)::resta,b_0,b_i::b)
      equation
        // arow
        row1 = solveRelaxationSystem2(a_0,a_i,row_0,row);
        // b
        tp = Exp.typeof(b_i);
        b1 = DAE.BINARY(b_i,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(b_0,DAE.DIV(tp),a_0))); 
        b2 = Exp.simplify(b1);
        // next 
        (a,bn) = solveRelaxationSystem1(a_0,row_0,resta,b_0,b);
      then
        (row1::a,b2::bn);
  end matchcontinue;
end solveRelaxationSystem1;

protected function solveRelaxationSystem2 "function: solveRelaxationSystem2
  author: Frenkel TUD
  Helper function to solveRelaxationSystem1
"
  input DAE.Exp  inA_0;
  input DAE.Exp  inA_i;
  input list<DAE.Exp> inARow_0;
  input list<DAE.Exp> inARow;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (inA_0,inA_i,inARow_0,inARow)
    local
      list<DAE.Exp> rest,row_0,a;
      DAE.Exp a_0,a_j,a_i,e,e1,e2;
      DAE.ExpType tp;
    case (a_0,a_i,a_j::{},e::{})
      equation
        tp = Exp.typeof(e);
        e1 = DAE.BINARY(e,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(a_j,DAE.DIV(tp),a_0)));   
        e2 = Exp.simplify(e1);     
      then
        {e2};      
    case (a_0,a_i,a_j::row_0,e::rest)
      equation
        tp = Exp.typeof(e);
        e1 = DAE.BINARY(e,DAE.SUB(tp),DAE.BINARY(a_i,DAE.MUL(tp),DAE.BINARY(a_j,DAE.DIV(tp),a_0))); 
        e2 = Exp.simplify(e1);       
        // next
        a = solveRelaxationSystem2(a_0,a_i,row_0,rest);
      then
        e2::a;
  end matchcontinue;
end solveRelaxationSystem2;

protected function solveRelaxationSystem3 "function: solveRelaxationSystem3
  author: Frenkel TUD
  Helper function to solveRelaxationSystem
"
  input list<list<DAE.Exp>> inA;
  input list<DAE.Exp> inB;
  input list<DAE.ComponentRef> inX;
  output DAELow.Equation outEqn;
algorithm
  outEqn:=
  matchcontinue (inA,inB,inX)
    local
      list<list<DAE.Exp>> resta;
      list<DAE.Exp> restb,row;
      DAE.Exp a_0,b_0,e,e1;
      list<DAE.ComponentRef> x;
      DAE.ComponentRef c;
      DAE.ExpType tp;
    case ((a_0::row)::resta,b_0::restb,c::x)
      equation
        e = solveRelaxationSystem4(row,x);
        tp = Exp.typeof(e);
        e = DAE.BINARY(DAE.BINARY(b_0,DAE.SUB(tp),e),DAE.DIV(tp),a_0);
        e1 = Exp.simplify(e);
      then
        DAELow.EQUATION(DAE.CREF(c,tp),e1,DAE.emptyElementSource);        
  end matchcontinue;
end solveRelaxationSystem3;

protected function solveRelaxationSystem4 "function: solveRelaxationSystem4
  author: Frenkel TUD
  Helper function to solveRelaxationSystem3
"
  input list<DAE.Exp> inRow;
  input list<DAE.ComponentRef> inX;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inRow,inX)
    local
      list<DAE.Exp> rest;
      DAE.Exp b,e,e1,e2;
      list<DAE.ComponentRef> x;
      DAE.ComponentRef c;
      DAE.ExpType tp;
     case (e::{},c::{})
      equation
        tp = Exp.typeof(e);
      then
        DAE.BINARY(e,DAE.MUL(tp),DAE.CREF(c,DAE.ET_OTHER));     
    case (e::rest,c::x)
      equation
        tp = Exp.typeof(e);
        e1 = DAE.BINARY(e,DAE.MUL(tp),DAE.CREF(c,DAE.ET_OTHER));
        e2 = solveRelaxationSystem4(rest,x);
      then
        DAE.BINARY(e1,DAE.ADD(tp),e2);        
  end matchcontinue;
end solveRelaxationSystem4;

protected function generateTearingSystem "function: generateTearingSystem
  author: Frenkel TUD

  Generates the actual simulation code for the teared system of equation
"
  input DAE.DAElist inDAElist1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input list<Integer> inIntegerLst4;
  input list<Integer> inIntegerLst5;
  input list<Integer> inIntegerLst6;
  input Boolean mixedEvent "true if generating the mixed system event code";
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input DAELow.JacobianType inJacobianType;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,inIntegerArray2,inIntegerArray3,inIntegerLst4,inIntegerLst5,inIntegerLst6,mixedEvent,genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inJacobianType,inInteger)
    local
      DAE.DAElist dae;
      Integer[:] ass1,ass2;
      list<Integer> block_,block_1,r,t;
      Codegen.CFunction s1,s2;
      Codegen.CFunction res_func,func,f2,f3,f4,f1,f5,res,feqn;
      Integer cg_id,eqn_size,cg_id1,cg_id2,cg_id3,cg_id4,id;
      DAELow.DAELow daelow,daelow1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      DAELow.Variables v,kv,exv;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      DAELow.EquationArray eqn,eqn1,reeqn,ineq;
      list<DAELow.Equation> eqn_lst,eqn_lst1,eqn_lst2,reqns;
      list<DAELow.Var> var_lst;
      list<DAE.ComponentRef> crefs,crefs1,tcrs;
      DAELow.MultiDimEquation[:] ae;
      Boolean genDiscrete;
      list<list<Integer>> eqnlstlst;
      String str_id,size_str,func_name,start_stmt,end_stmt;
      VarTransform.VariableReplacements repl;
      DAE.Algorithm[:] algorithms;
      DAELow.EventInfo eventInfo;
      DAELow.ExternalObjectClasses extObjClasses;
    case (dae,ass1,ass2,block_,r,t,mixedEvent,_,
          daelow as DAELow.DAELOW(orderedVars=v,knownVars=kv,externalObjects=exv,aliasVars=av,orderedEqs=eqn,removedEqs=reeqn,initialEqs=ineq,arrayEqs=ae,algorithms=algorithms,eventInfo=eventInfo,extObjClasses=extObjClasses),jac,jac_tp,cg_id) /* no analythic jacobian available. Generate non-linear system */
      equation
        // get equations and variables
        eqn_lst = DAELow.equationList(eqn);
        var_lst = DAELow.varList(v);
        // get names from variables
        crefs = Util.listMap(var_lst, DAELow.varCrefPrefixStates); // get varnames and prefix $der for states.
        // get Tearingvar from crs
        // to use listNth cref and eqn_lst have to start at 1 and not at 0 -> right shift
        crefs1 = Util.listAddElementFirst(DAE.CREF_IDENT("shift",DAE.ET_REAL(),{}),crefs);
        eqn_lst1 = Util.listAddElementFirst(DAELow.EQUATION(DAE.RCONST(0.0),DAE.RCONST(0.0),DAE.SOURCE({},{},{},{})),eqn_lst);
        tcrs = Util.listMap1r(t,listNth,crefs1);
        repl = makeResidualReplacements(tcrs);
        // get residual eqns and other eqns
        reqns = Util.listMap1r(r,listNth,eqn_lst1);
        // remove residual equation from list of other equtions
        block_1 = Util.listSelect1(block_,r,Util.listNotContains);
        eqnlstlst = Util.listMap(block_1,Util.listCreate);
        // replace tearing variables in other equations with x_loc[..]
        eqn_lst2 = generateTearingSystem1(eqn_lst,repl);
        eqn1 = DAELow.listEquation(eqn_lst2);
        daelow1=DAELow.DAELOW(v,kv,exv,av,eqn1,reeqn,ineq,ae,algorithms,eventInfo,extObjClasses);
        // generade code for other equations
        (feqn,cg_id2,_) = buildSolvedBlocks(dae,daelow1,ass1,ass2,eqnlstlst,cg_id);
        // generade code for nonlinear solver for tearing system
        (s1,cg_id1) = generateOdeSystem2NonlinearResiduals2(reqns, ae, 0, repl, cg_id2);
        s2 = Codegen.cMergeFns({feqn,s1});
        id = tick();
        str_id = intString(id);
        eqn_size = listLength(reqns);
        size_str = intString(eqn_size);
        func_name = stringAppend("residualFunc", str_id);
        res_func = Codegen.cMakeFunction("void", func_name, {},
          {"int *n","double* xloc","double* res","int* iflag"});
        func = Codegen.cMergeFns({res_func,s2});
        func = addMemoryManagement(func);
        (f2,cg_id2) = generateOdeSystem2NonlinearSetvector(tcrs, 0, cg_id1);
        (f3,cg_id3) = generateOdeSystem2NonlinearCall(mixedEvent,str_id, cg_id2);
        (f4,cg_id4) = generateOdeSystem2NonlinearStoreResults(tcrs, 0, cg_id3);
        start_stmt = Util.stringAppendList({"start_nonlinear_system(",size_str,");"});
        end_stmt = "end_nonlinear_system();";
        f1 = Codegen.cAddStatements(Codegen.cEmptyFunction, {start_stmt});
        f5 = Codegen.cAddStatements(Codegen.cEmptyFunction, {end_stmt});
        res = Codegen.cMergeFns({f1,f2,f3,f4,f5});
      then
        (res,cg_id4,{func});
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-generateTearingSystem failed \n");
      then
        fail();
  end matchcontinue;
end generateTearingSystem;

protected function generateTearingSystem1
 "function: generateTearingSystem1
  author: Frenkel TUD
  Helper function to generateTearingSystem1"
  input list<DAELow.Equation> inDAELowEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst := matchcontinue (inDAELowEquationLst,inVariableReplacements)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      list<DAELow.Equation> rest,rest2;
      DAELow.MultiDimEquation[:] aeqns;
      VarTransform.VariableReplacements repl;
      DAE.ElementSource source;
    case ({},_) then {};
    case ((DAELow.EQUATION(exp = e1,scalar = e2,source = source) :: rest),repl)
      equation
        rest2 = generateTearingSystem1(rest,repl);
        e1_1 = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
        e2_1 = VarTransform.replaceExp(e2, repl, SOME(skipPreOperator));
      then
        DAELow.EQUATION(e1_1,e2_1,source) :: rest2;
    case ((DAELow.RESIDUAL_EQUATION(exp = e1,source = source) :: rest),repl)
      equation
        rest2 = generateTearingSystem1(rest,repl);
        e1_1 = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
      then
        DAELow.RESIDUAL_EQUATION(e1_1,source) :: rest2;
  end matchcontinue;
end generateTearingSystem1;

protected function generateSingleAlgorithmCode "function: generateSingleAlgorithmCode
  author: PA
  Generates code for a system consisting of a  single algorithm."
  input Boolean genDiscrete;
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (genDiscrete,inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inInteger)
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr,origname,cr_1;
      Codegen.CFunction s1;
      list<CFunction> f1;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      Algorithm.Algorithm alg;
      DAELow.EventInfo ev;
      list<DAE.ComponentRef> solvedVars,algOutVars;
      list<DAE.Exp> algOutExpVars;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      String message,algStr;
      Boolean genDiscrete;
      DAE.ElementSource source "the origin of the element";

    case (genDiscrete, DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev),jac,cg_id) /* eqn code cg var_id extra functions */
      equation
        (DAELow.ALGORITHM(indx,_,algOutExpVars,source) :: _) = DAELow.equationList(eqns);
        alg = al[indx + 1];
        solvedVars = Util.listMap(DAELow.varList(vars),DAELow.varCref);
        algOutVars = Util.listMap(algOutExpVars,Exp.expCref);
        // The variables solved for and the output variables of the algorithm must be the same.
        true = Util.listSetEqualOnTrue(solvedVars,algOutVars,Exp.crefEqual);
        (s1,cg_id_1) = Codegen.generateAlgorithm(DAE.ALGORITHM(alg,source), cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
      then (s1,cg_id_1,{});

        /* Error message, inverse algorithms not supported yet */
 	 case (genDiscrete,DAELow.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = ev),jac,cg_id)
      equation
        (DAELow.ALGORITHM(indx,_,algOutExpVars,source) :: _) = DAELow.equationList(eqns);
        alg = al[indx + 1];
        solvedVars = Util.listMap(DAELow.varList(vars),DAELow.varCref);
        algOutVars = Util.listMap(algOutExpVars,Exp.expCref);

        // The variables solved for and the output variables of the algorithm must be the same.
        false = Util.listSetEqualOnTrue(solvedVars,algOutVars,Exp.crefEqual);
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = Util.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();

    case (_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"array equations currently only supported on form v = functioncall(...)"});
      then
        fail();
  end matchcontinue;
end generateSingleAlgorithmCode;

protected function generateSingleArrayEqnCode
"function: generateSingleArrayEqnCode
  author: PA
  Generates code for a system consisting of a  single array equation."
  input DAELow.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, DAELow.Equation>>> inTplIntegerIntegerDAELowEquationLstOption;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAELow,inTplIntegerIntegerDAELowEquationLstOption,inInteger)
    local
      Integer indx,cg_id_1,cg_id;
      list<Integer> ds;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr,origname,cr_1;
      Codegen.CFunction s1;
      list<CFunction> f1;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray eqns,se,ie;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
    case (DAELow.DAELOW(orderedVars = vars,
                        knownVars = knvars,
                        orderedEqs = eqns,
                        removedEqs = se,
                        initialEqs = ie,
                        arrayEqs = ae,
                        algorithms = al,
                        eventInfo = ev),jac,cg_id) /* eqn code cg var_id extra functions */
      local String cr_1_str;
      equation
        (DAELow.ARRAY_EQUATION(index=indx) :: _) = DAELow.equationList(eqns);
        DAELow.MULTIDIM_EQUATION(ds,e1,e2,_) = ae[indx + 1];
        ((DAELow.VAR(cr,_,_,_,_,_,_,_,origname,_,_,_,_,_) :: _)) = DAELow.varList(vars);
        // We need to strip subs from origname since they are removed in cr.
        cr_1 = Exp.crefStripLastSubs(origname);
        // Since we use origname we need to replace '.' with '$P' manually.
        cr_1_str = Util.modelicaStringToCStr(Exp.printComponentRefStr(cr_1),true); // stringAppend("$",Util.modelicaStringToCStr(Exp.printComponentRefStr(cr_1),true));
        cr_1 = DAE.CREF_IDENT(cr_1_str,DAE.ET_OTHER(),{});
        (e1,e2) = solveTrivialArrayEquation(cr_1,e1,e2);
        (s1,cg_id_1,f1) = generateSingleArrayEqnCode2(cr_1, cr_1, e1, e2, cg_id);
      then
        (s1,cg_id_1,f1);

    case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"array equations currently only supported on form v = functioncall(...)"});
      then
        fail();
  end matchcontinue;
end generateSingleArrayEqnCode;

protected function solveTrivialArrayEquation
"Solves some trivial array equations, like v+v2=foo(...), w.r.t. v is v=foo(...)-v2"
	input DAE.ComponentRef v;
	input DAE.Exp e1;
	input DAE.Exp e2;
	output DAE.Exp outE1;
	output DAE.Exp outE2;
algorithm
  (outE1,outE2) := matchcontinue(v,e1,e2)
    local
      DAE.Exp e12,e22,vTerm,res,rhs;
      list<DAE.Exp> terms;
      DAE.ExpType tp;

    // Solve simple linear equations.
    case(v,e1,e2)
      equation
        tp = Exp.typeof(e1);
        res = Exp.simplify(DAE.BINARY(e1,DAE.SUB_ARR(tp),e2));
        //print("simplified to :");print(Exp.printExpStr(res));print("\n");
        (vTerm as DAE.CREF(_,_),rhs) = Exp.getTermsContainingX(res,DAE.CREF(v,DAE.ET_OTHER()));
        //print("solved array equation to :");print(Exp.printExpStr(e1));print("=");
        //print(Exp.printExpStr(e2));print("\n");
      then (vTerm,rhs);

    // not succeded to solve, return unsolved equation., catched later.
    case(v,e1,e2) then (e1,e2);
  end matchcontinue;
end solveTrivialArrayEquation;

protected function generateSingleArrayEqnCode2
"function generateSingleArrayEqnCode2
  author: PA
  Helper function to generateSingleArrayEqnCode.
  Currenlty solves only solved equation on form v = foo(...)"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input DAE.Exp inExp3;
  input DAE.Exp inExp4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inComponentRef1,inComponentRef2,inExp3,inExp4,inInteger5)
    local
      String s1,s2,stmt,s3,s4,s;
      Codegen.CFunction cfunc,func_1;
      Integer cg_id_1,cg_id;
      DAE.ComponentRef cr,eltcr,cr2;
      DAE.Exp e1,e2;
    case (cr,eltcr,(e1 as DAE.CREF(componentRef = cr2)),e2,cg_id) /* origname firsteltname lhs rhs cg var_id cg var_id */
      equation
        true = Exp.crefEqual(cr, cr2);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e2, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s2,", &",s1,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,(e2 as DAE.CREF(componentRef = cr2)),cg_id)
      equation
        true = Exp.crefEqual(cr, cr2);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s1,", &",s2,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,e2,cg_id) /* e2 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e2);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s1,", &",s2,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,e2,cg_id) /* e1 is array of crefs, {v{1},v{2},...v{n}} */
      equation
        cr2 = getVectorizedCrefFromExp(e1);
        s1 = Exp.printComponentRefStr(eltcr);
        (cfunc,s2,cg_id_1) = Codegen.generateExpression(e2, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({"copy_real_array_data_mem(&",s2,", &",s1,");"});
        func_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (func_1,cg_id_1,{});
    case (cr,eltcr,e1,e2,_)
      equation
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        s3 = Exp.printComponentRefStr(cr);
        s4 = Exp.printComponentRefStr(eltcr);
        s = Util.stringAppendList({"generate_single_array_eqn_code2(",s3,", ",s4,", ",s1,", ",s2,") failed\n"});
        print(s);
      then
        fail();
  end matchcontinue;
end generateSingleArrayEqnCode2;

protected function getVectorizedCrefFromExp
"function: getVectorizedCrefFromExp
  author: PA
  Returns the component ref v if expression is on form
   {v{1},v{2},...v{n}}  for some n.
  TODO: implement for 2D as well."
  input DAE.Exp inExp;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inExp)
    local
      list<DAE.ComponentRef> crefs,crefs_1;
      DAE.ComponentRef cr;
      list<String> strs;
      String s;
      list<DAE.Exp> expl;
      list<list<tuple<DAE.Exp, Boolean>>> column;
    case (DAE.ARRAY(array = expl))
      equation
        ((crefs as (cr :: _))) = Util.listMap(expl, Exp.expCref); //Get all CRefs from exp1.
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubsStringified); //Strip last subscripts
        strs = Util.listMap(crefs_1, Exp.printComponentRefStr); //convert crefs to strings
        s = Util.stringDelimitList(strs, ","); //convert to comma-separated form
        _ = Util.listReduce(crefs_1, Exp.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
    case (DAE.MATRIX(scalar = column))
      equation
        ((crefs as (cr :: _))) = Util.listMap(column, getVectorizedCrefFromExpMatrix);
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubsStringified);
        strs = Util.listMap(crefs_1, Exp.printComponentRefStr);
        s = Util.stringDelimitList(strs, ",");
        _ = Util.listReduce(crefs_1, Exp.crefEqualReturn);
      then
        cr;
  end matchcontinue;
end getVectorizedCrefFromExp;

protected function getVectorizedCrefFromExpMatrix
"function: getVectorizedCrefFromExpMatrix
  author: KN
  Helper function for the 2D part of getVectorizedCrefFromExp
  Returns the component ref v if list of expressions is on form
   {v{1},v{2},...v{n}}  for some n."
  input list<tuple<DAE.Exp, Boolean>> column; //One column in a matrix.
  output DAE.ComponentRef outComponentRef; //The expanded column
algorithm
  outComponentRef:=
  matchcontinue (column)
    local
      list<tuple<DAE.Exp, Boolean>> col;
      list<DAE.ComponentRef> crefs,crefs_1;
      DAE.ComponentRef cr;
      list<String> strs;
      String s;
      list<DAE.Exp> expl;
    case (col)
      equation
        ((crefs as (cr :: _))) = Util.listMap(col, Exp.expCrefTuple); //Get all CRefs from the list of tuples.
        crefs_1 = Util.listMap(crefs, Exp.crefStripLastSubsStringified); //Strip last subscripts
        strs = Util.listMap(crefs_1, Exp.printComponentRefStr); //convert crefs to strings
        s = Util.stringDelimitList(strs, ","); //convert to comma-separated form
        _ = Util.listReduce(crefs_1, Exp.crefEqualReturn); //Check if elements are equal, remove one
      then
        cr;
		case (_)
		  equation
      then
        fail();
  end matchcontinue;
end getVectorizedCrefFromExpMatrix;

protected function singleAlgorithmSection
"function: singleAlgorithmSection
  author: PA
  Checks if a dae (subsystem) consists of a single algorithm section."
  input DAELow.DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Equation> eqn_lst;
      DAELow.Variables vars;
      DAELow.EquationArray eqnarr;
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqnarr))
      equation
        eqn_lst = DAELow.equationList(eqnarr);
        singleAlgorithmSection2(eqn_lst);
      then
        ();
  end matchcontinue;
end singleAlgorithmSection;

protected function singleAlgorithmSection2
  input list<DAELow.Equation> inDAELowEquationLst;
algorithm
  _:=
  matchcontinue (inDAELowEquationLst)
    local list<DAELow.Equation> res;
    case ({}) then ();
    case ((DAELow.ALGORITHM(index = _) :: res))
      equation
        singleAlgorithmSection2(res);
      then
        ();
  end matchcontinue;
end singleAlgorithmSection2;

protected function singleArrayEquation
"function: singleArrayEquation
  author: PA
  Checks if a dae (subsystem) consists of a single array equation."
  input DAELow.DAELow inDAELow;
algorithm
  _:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Equation> eqn_lst;
      DAELow.Variables vars;
      DAELow.EquationArray eqnarr;
    case (DAELow.DAELOW(orderedVars = vars,orderedEqs = eqnarr))
      equation
        eqn_lst = DAELow.equationList(eqnarr);
        singleArrayEquation2(eqn_lst);
      then
        ();
  end matchcontinue;
end singleArrayEquation;

protected function singleArrayEquation2
  input list<DAELow.Equation> inDAELowEquationLst;
algorithm
  _:=
  matchcontinue (inDAELowEquationLst)
    local list<DAELow.Equation> res;
    case ({}) then ();
    case ((DAELow.ARRAY_EQUATION(index = _) :: res))
      equation
        singleArrayEquation2(res);
      then
        ();
  end matchcontinue;
end singleArrayEquation2;

protected function generateOdeSystem2NonlinearResiduals "function: generateOdeSystem2NonlinearResiduals
  author: PA

  Generates residual statements for nonlinear equation systems.
"
	input Boolean mixedEvent "true if inside mixed system event code";
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input list<DAELow.Equation> inDAELowEquationLst;
  input DAELow.MultiDimEquation[:] multiDimEqnLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (mixedEvent,inExpComponentRefLst,inDAELowEquationLst,multiDimEqnLst,inInteger)
    local
      VarTransform.VariableReplacements repl;
      Codegen.CFunction s1,res_func,func,f2,f3,f4,f1,f5,res;
      Integer cg_id1,id,eqn_size,cg_id2,cg_id3,cg_id4,cg_id;
      String str_id,size_str,func_name,start_stmt,end_stmt;
      list<DAE.ComponentRef> crs;
      list<DAELow.Equation> eqns;
      DAELow.MultiDimEquation[:] aeqns;
    case (mixedEvent,crs,eqns,aeqns,cg_id) /* cg var_id solve code cg var_id extra functions: residual func */
      equation
        repl = makeResidualReplacements(crs);
        (s1,cg_id1) = generateOdeSystem2NonlinearResiduals2(eqns, aeqns, 0, repl, cg_id);
        id = tick();
        str_id = intString(id);
        eqn_size = listLength(eqns);
        size_str = intString(eqn_size);
        func_name = stringAppend("residualFunc", str_id);
        res_func = Codegen.cMakeFunction("void", func_name, {},
          {"int *n","double* xloc","double* res","int* iflag"});
        func = Codegen.cMergeFns({res_func,s1});
        func = addMemoryManagement(func);
        (f2,cg_id2) = generateOdeSystem2NonlinearSetvector(crs, 0, cg_id1);
        (f3,cg_id3) = generateOdeSystem2NonlinearCall(mixedEvent,str_id, cg_id2);
        (f4,cg_id4) = generateOdeSystem2NonlinearStoreResults(crs, 0, cg_id3);
        start_stmt = Util.stringAppendList({"start_nonlinear_system(",size_str,");"});
        end_stmt = "end_nonlinear_system();";
        f1 = Codegen.cAddStatements(Codegen.cEmptyFunction, {start_stmt});
        f5 = Codegen.cAddStatements(Codegen.cEmptyFunction, {end_stmt});
        res = Codegen.cMergeFns({f1,f2,f3,f4,f5});
      then
        (res,cg_id4,{func});
    case (_,_,_,_,_)
      equation
        print("generate_ode_system2_nonlinear_residuals failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2NonlinearResiduals;

protected function makeResidualReplacements "function: makeResidualReplacements
  author: PA

  This function makes replacement rules for variables occuring in a
  nonlinear equation system. They should be replaced by xloc{index}, i.e.
  an unique index in a xloc vector.
"
  input list<DAE.ComponentRef> crefs;
  output VarTransform.VariableReplacements repl_1;
  VarTransform.VariableReplacements repl,repl_1;
algorithm
  repl := VarTransform.emptyReplacements();
  repl_1 := makeResidualReplacements2(repl, crefs, 0);
end makeResidualReplacements;

protected function makeResidualReplacements2 "function makeResidualReplacements2
  author: PA

  Helper function to make_residual_replacements
"
  input VarTransform.VariableReplacements inVariableReplacements;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input Integer inInteger;
  output VarTransform.VariableReplacements outVariableReplacements;
algorithm
  outVariableReplacements:=
  matchcontinue (inVariableReplacements,inExpComponentRefLst,inInteger)
    local
      VarTransform.VariableReplacements repl,repl_1,repl_2;
      String pstr,str;
      Integer pos_1,pos;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;
    case (repl,{},_) then repl;
    case (repl,(cr :: crs),pos)
      equation
        pstr = intString(pos);
        str = Util.stringAppendList({"xloc[",pstr,"]"});
        repl_1 = VarTransform.addReplacement(repl, cr, DAE.CREF(DAE.CREF_IDENT(str,DAE.ET_REAL(),{}),DAE.ET_REAL()));
        pos_1 = pos + 1;
        repl_2 = makeResidualReplacements2(repl_1, crs, pos_1);
      then
        repl_2;
  end matchcontinue;
end makeResidualReplacements2;

protected function generateOdeSystem2NonlinearSetvector "function: generateOdeSystem2NonlinearSetvector
  author: PA

  Generates code for setting the values for the x vector when solving
  nonlinear equation systems.
"
  input list<DAE.ComponentRef> inExpComponentRefLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inExpComponentRefLst1,inInteger2,inInteger3)
    local
      Integer cg_id,indx_1,cg_id_1,indx;
      String cr_str,indx_str,stmt,stmt2;
      Codegen.CFunction func,func_1;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;
    case ({},_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* index iterator cg var_id cg var_id */
    case ((cr :: crs),indx,cg_id)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (func,cg_id_1) = generateOdeSystem2NonlinearSetvector(crs, indx_1, cg_id);
        stmt = Util.stringAppendList({"nls_x[",indx_str,"] = extraPolate(",cr_str,");"});
        stmt2 = Util.stringAppendList({"nls_xold[",indx_str,"] = old(&",cr_str,");"});
        func_1 = Codegen.cAddStatements(func, {stmt,stmt2});
      then
        (func_1,cg_id_1);

    case(_,_,_) equation
      print("generateOdeSystem2NonlinearSetvector failed\n");
      then fail();
  end matchcontinue;
end generateOdeSystem2NonlinearSetvector;

protected function generateOdeSystem2NonlinearCall "function: generateOdeSystem2NonlinearCall
  author: PA

  Generates the call to the nonlinear equation solver.
"
  input Boolean mixedEvent "true if inside mixed system event code";
  input String inString;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (mixedEvent,outCFunction,outInteger):=
  matchcontinue (mixedEvent,inString,inInteger)
    local
      String stmt,func_id;
      Codegen.CFunction func;
      Integer cg_id;
      // Not mixed system event code
    case (false,func_id,cg_id) /* residual func id cg var_id cg var_id */
      equation
        stmt = Util.stringAppendList(
          {"solve_nonlinear_system(residualFunc",func_id,", ",func_id,");"});
        func = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (func,cg_id);

        // Mixed system event code.
    case (true,func_id,cg_id) /* residual func id cg var_id cg var_id */
      equation
         stmt = Util.stringAppendList(
          {"solve_nonlinear_system_mixed(residualFunc",func_id,", ",func_id,");"});
        func = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (func,cg_id);
  end matchcontinue;
end generateOdeSystem2NonlinearCall;

protected function generateOdeSystem2NonlinearStoreResults "function: generateOdeSystem2NonlinearStoreResults
  author: PA

  Generates the storing of the results of the solution to a nonlinear equation
  system.
"
  input list<DAE.ComponentRef> inExpComponentRefLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inExpComponentRefLst1,inInteger2,inInteger3)
    local
      Integer cg_id,indx_1,cg_id_1,indx;
      String cr_str,indx_str,stmt;
      Codegen.CFunction func,func_1;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;
    case ({},_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* indx cg var_id cg var_id */
    case ((cr :: crs),indx,cg_id)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (func,cg_id_1) = generateOdeSystem2NonlinearStoreResults(crs, indx_1, cg_id);
        stmt = Util.stringAppendList({cr_str," = nls_x[",indx_str,"];"});
        func_1 = Codegen.cAddStatements(func, {stmt});
      then
        (func_1,cg_id_1);
    case (_,_,_) equation
      print("-generateOdeSystem2NonlinearStoreResults failed\n");
      then fail();
  end matchcontinue;
end generateOdeSystem2NonlinearStoreResults;

protected function generateOdeSystem2NonlinearResiduals2 "function: generateOdeSystem2NonlinearResiduals2
  author: PA
  Helper function to generateOdeSystem2NonlinearResiduals"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input DAELow.MultiDimEquation[:] arrayEqnLst;
  input Integer inInteger2;
  input VarTransform.VariableReplacements inVariableReplacements3;
  input Integer inInteger4;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger) := matchcontinue (inDAELowEquationLst1,arrayEqnLst,inInteger2,inVariableReplacements3,inInteger4)
    local
      Integer cg_id,cg_id_1,indx_1,cg_id_2,indx,aindx;
      DAE.ExpType tp;
      DAE.Exp res_exp,res_exp_1,res_exp_2,e1,e2,e;
      Codegen.CFunction exp_func,cfunc,exp_func_1,cfunc_1,cfunc_2;
      String var,indx_str,stmt;
      list<DAELow.Equation> rest,rest2;
      DAELow.MultiDimEquation[:] aeqns;
      VarTransform.VariableReplacements repl;
    case ({},_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* index iterator cg var_id cg var_id */
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),aeqns,indx,repl,cg_id)
      equation
        tp = Exp.typeof(e1);
        res_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        res_exp_1 = Exp.simplify(res_exp);
        res_exp_2 = VarTransform.replaceExp(res_exp_1, repl, SOME(skipPreOperator));
        (exp_func,var,cg_id_1) = Codegen.generateExpression(res_exp_2, cg_id, Codegen.simContext);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (cfunc,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest, aeqns,indx_1, repl, cg_id_1);
        stmt = Util.stringAppendList({TAB,"res[",indx_str,"] = ",var,";"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case ((DAELow.RESIDUAL_EQUATION(exp = e) :: rest),aeqns,indx,repl,cg_id)
      equation
        res_exp_1 = Exp.simplify(e);
        res_exp_2 = VarTransform.replaceExp(res_exp_1, repl, SOME(skipPreOperator));
        (exp_func,var,cg_id_1) = Codegen.generateExpression(res_exp_2, cg_id, Codegen.simContext);
        indx_str = intString(indx);
        indx_1 = indx + 1;
        (cfunc,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest, aeqns,indx_1, repl, cg_id_1);
        stmt = Util.stringAppendList({TAB,"res[",indx_str,"] = ",var,";"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);

        /* An array equation */
    case (rest as DAELow.ARRAY_EQUATION(index=aindx) :: _,aeqns,indx,repl,cg_id)
      equation
        (cfunc_1,cg_id_1,rest2,indx_1) = generateOdeSystem2NonlinearResidualsArrayEqn(aindx,rest,aeqns,indx,repl,cg_id);
        (cfunc_2,cg_id_2) = generateOdeSystem2NonlinearResiduals2(rest2, aeqns,indx_1, repl, cg_id_1);
        cfunc = Codegen.cMergeFns({cfunc_1,cfunc_2});
      then (cfunc,cg_id_2);
  end matchcontinue;
end generateOdeSystem2NonlinearResiduals2;

protected function generateOdeSystem2NonlinearResidualsArrayEqn
" Generates residual calculations for an array equation

An array equation has several nodes in the equation list. Traverse the list and remove
all with the same index."

  input Integer arrayIndex "the current array index";
  input list<DAELow.Equation> allEquations;
  input DAELow.MultiDimEquation[:] arrayEquations;
	input Integer residualIndex "index in residual vector";
	input VarTransform.VariableReplacements repl;
	input Integer cg_id;
  output CFunction outCFunction;
  output Integer outCg_id;
  output list<DAELow.Equation> updatedAllEquations;
  output Integer nextResidualIndex;

algorithm
  (outCFunction,outCg_id,updatedAllEquations,nextResidualIndex)
  	:= matchcontinue(arrayIndex,allEquations,arrayEquations,residualIndex,repl,cg_id)
  	local list<Integer> ds; DAE.Exp e1,e2,e1_1,e2_1;
  	  case (arrayIndex,allEquations,arrayEquations,residualIndex,repl,cg_id)
  	    equation
  	        updatedAllEquations = removeArrayEquationIndex(allEquations,arrayIndex);
  	         DAELow.MULTIDIM_EQUATION(ds,e1,e2,_) = arrayEquations[arrayIndex + 1];
  	         e1_1 = VarTransform.replaceExp(e1, repl, SOME(skipPreOperator));
  	         e2_1 = VarTransform.replaceExp(e2, repl, SOME(skipPreOperator));
  	         (outCFunction,outCg_id) = generateOdeSystem2NonlinearResidualsArrayEqn2(residualIndex,e1_1,e2_1,cg_id);
  	         nextResidualIndex = residualIndex + Util.listReduce(ds,intMul);
  	      then (outCFunction,outCg_id,updatedAllEquations,nextResidualIndex);
  end matchcontinue;
end generateOdeSystem2NonlinearResidualsArrayEqn;

protected function generateOdeSystem2NonlinearResidualsArrayEqn2 "
Generates the residual calculation for an array equation.
For example v = foo(...)
generates code (on pseudo form): res[index] = v - foo(...);
This assumes that all variables of the array equation are part of the residual and follows in the
same order in the residual."
	input Integer indx;
  input DAE.Exp leftExp;
  input DAE.Exp rightExp;
  input Integer cg_in;
  output CFunction outCFunction;
  output Integer cg_out;
algorithm
  (outCFunction,cg_out):=
  matchcontinue (indx,leftExp,rightExp,cg_in)
    local
      String s1,s2,stmt,s3,s4,s,indxStr;
      Codegen.CFunction cfunc,cfunc1,cfunc2,cfunc3;
      Integer cg_id_1,cg_id,cg_id_2;
      DAE.ComponentRef cr,eltcr,cr2;
      DAE.Exp e1,e2;
    case (indx,e1 ,e2,cg_id)
      equation
        (cfunc1,s1,cg_id_1) = Codegen.generateExpression(e1, cg_id, Codegen.simContext);
				(cfunc2,s2,cg_id_2) = Codegen.generateExpression(e2, cg_id_1, Codegen.simContext);
        cfunc = Codegen.cMergeFns({cfunc1,cfunc2});
        indxStr = intString(indx);
        stmt = Util.stringAppendList({"sub_real_array_data_mem(&",s1,", &",s2,", &res[",indxStr,"]);"});
        cfunc3 = Codegen.cAddStatements(cfunc, {stmt});
      then
        (cfunc3,cg_id_2);
  end matchcontinue;
end generateOdeSystem2NonlinearResidualsArrayEqn2;


protected function removeArrayEquationIndex "removes all array equations with index equal to arrayIndex"
  input list<DAELow.Equation> eqns;
  input Integer arrayIndex;
  output list<DAELow.Equation> outEqns;
algorithm
  outEqns := matchcontinue(eqns,arrayIndex)
    local Integer index;
      DAELow.Equation e;
      list<DAELow.Equation> rest,res;
    case ({},_) then {};
    case (DAELow.ARRAY_EQUATION(index=index)::rest,arrayIndex) equation
      equality(index = arrayIndex);
      then removeArrayEquationIndex(rest,arrayIndex);
    case (e::rest,arrayIndex) equation
      res = removeArrayEquationIndex(rest,arrayIndex);
    then e::res;
  end matchcontinue;
end removeArrayEquationIndex;

protected function removeAlgorithmIndex "removes all algorithm 'equation':s with index equal to algIndex"
  input list<DAELow.Equation> eqns;
  input Integer algIndex;
  output list<DAELow.Equation> outEqns;
algorithm
  outEqns := matchcontinue(eqns,algIndex)
    local Integer index;
      DAELow.Equation e;
      list<DAELow.Equation> rest,res;
    case ({},_) then {};
    case (DAELow.ALGORITHM(index=index)::rest,algIndex) equation
      equality(index = algIndex);
      then removeAlgorithmIndex(rest,algIndex);
    case (e::rest,algIndex) equation
      res = removeAlgorithmIndex(rest,algIndex);
    then e::res;
  end matchcontinue;
end removeAlgorithmIndex;

protected function skipPreOperator "function: skipPreOperator
  Condition function, used in generate_ode_system2_nonlinear_residuals2.
  The variable in the pre operator should not be replaced in residual
  functions. This function is passed to replace_exp to ensure this."
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"))) then false;
    case (_) then true;
  end matchcontinue;
end skipPreOperator;

protected function generateOdeSystem2Declaration "function: generateOdeSystem2Declaration
  author: PA
  Generates code for the declaration of A and b when
  solving linear systems of equations.
  inputs: (size: int, unique_id: int)
  outputs: (fcn : CFunction)"
	input Boolean mixedEvent;
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inInteger1,inInteger2,inInteger3)
    local
      String size_str,id_str,stmt1,stmt2;
      Codegen.CFunction res;
      Integer size,unique_id,cg_id;
    case (mixedEvent,size,unique_id,cg_id) /* size unique_id cg var_id cg var_id */
      equation
        size_str = intString(size);
        id_str = intString(unique_id);
        stmt1 = Util.stringAppendList({"declare_matrix(A",id_str,",",size_str,",",size_str,");"});
        stmt2 = Util.stringAppendList({"declare_vector(b",id_str,",",size_str,");"});
        res = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt1,stmt2});
      then
        (res,cg_id);
    case (mixedEvent,size,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2Declaration failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2Declaration;

protected function generateOdeSystem2Cleanup "
  Generates code for the cleanups (delete) of A and b when
  solving linear systems of equations.
  inputs: (size: int, unique_id: int)
  outputs: (fcn : CFunction)
"
	input Boolean mixedEvent;
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inInteger1,inInteger2,inInteger3)
    local
      String size_str,id_str,stmt1,stmt2;
      Codegen.CFunction res;
      Integer size,unique_id,cg_id;
    case (mixedEvent,size,unique_id,cg_id) /* size unique_id cg var_id cg var_id */
      equation
        size_str = intString(size);
        id_str = intString(unique_id);
        stmt1 = Util.stringAppendList({"free_matrix(A",id_str,");"});
        stmt2 = Util.stringAppendList({"free_vector(b",id_str,");"});
        res = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt1,stmt2});
      then
        (res,cg_id);
    case (mixedEvent,size,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2Cleanup failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2Cleanup;

protected function generateOdeSystem2PopulateAb "function: generateOdeSystem2PopulateAb
  author: PA

  Generates code for the population of A and b when
  solving linear system of equations.
  inputs: ( jac : (int  int  DAELow.Equation) list,
            vars: DAELow.Variables,
  	      eqns: DAELow.EquationArray
 	      unique_id : int)
  outputs: cfn : CFunction
"
	input Boolean mixedEvent;
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5)
    local
      Codegen.CFunction s1,s2,res;
      Integer cg_id1,cg_id2,unique_id,cg_id;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
    case (mixedEvent,jac,vars,eqns,unique_id,cg_id) /* unique_id cg var_id cg var_id */
      equation
        (s1,cg_id1) = generateOdeSystem2PopulateA(jac, vars, eqns, unique_id, cg_id);
        (s2,cg_id2) = generateOdeSystem2PopulateB(jac, vars, eqns, unique_id, cg_id1);
        res = Codegen.cMergeFns({s1,s2});
      then
        (res,cg_id2);
    case (mixedEvent,jac,vars,eqns,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateAb failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateAb;

protected function generateOdeSystem2PopulateA "function: generateOdeSystem2PopulateA
  author: PA

  Generates code for the population of A
  solving linear system of equations.
  inputs ( jac : (int  int  DAELow.Equation) list,
            vars: DAELow.Variables,
  	      eqns: DAELow.EquationArray
 	      unique_id : int
 	      cg_var_id : int)
  outputs: (cfn : CFunction
 	      cg_var_id : int)
"
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5)
    local
      Integer n_rows,cg_id,unique_id;
      Codegen.CFunction res;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
    case (jac,vars,eqns,unique_id,cg_id)
      equation
        n_rows = DAELow.equationSize(eqns);
        (res,cg_id) = generateOdeSystem2PopulateA2(jac, vars, eqns, n_rows, unique_id, cg_id);
      then
        (res,cg_id);
    case (jac,vars,eqns,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateA failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateA;

protected function generateOdeSystem2PopulateA2 "function: generateOdeSystem2PopulateA2
  author: PA

  Helper function to generate_ode_system2_populate_A
"
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5,inInteger6)
    local
      Integer unique_id,cg_id,r_1,c_1,cg_id_1,cg_id_2,r,c,n_rows;
      String rs,rc,n_rows_str,id_str,var,stmt;
      Codegen.CFunction cfunc1,cfunc,cfunc1_1,cfunc_1;
      DAE.Exp exp;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqn;
    case ({},_,_,_,unique_id,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* n rows unique_id cg var_id cg var_id */
    case (((r,c,DAELow.RESIDUAL_EQUATION(exp = exp)) :: jac),vars,eqn,n_rows,unique_id,cg_id)
      equation
        r_1 = r - 1;
        c_1 = c - 1;
        rs = intString(r_1);
        rc = intString(c_1);
        n_rows_str = intString(n_rows);
        id_str = intString(unique_id);
        (cfunc1,var,cg_id_1) = Codegen.generateExpression(exp, cg_id, Codegen.simContext);
        (cfunc,cg_id_2) = generateOdeSystem2PopulateA(jac, vars, eqn, unique_id, cg_id_1);
        stmt = Util.stringAppendList(
          {"set_matrix_elt(A",id_str,",",rs,", ",rc,", ",n_rows_str,
          ", ",var,");"});
        cfunc1_1 = Codegen.cAddStatements(cfunc1, {stmt});
        cfunc_1 = Codegen.cMergeFns({cfunc1_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateA2 failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateA2;

protected function generateOdeSystem2PopulateB "function: generateOdeSystem2PopulateB
  author: PA

  Generates code for the population of b
  solving linear system of equations.
"
  input list<tuple<Integer, Integer, DAELow.Equation>> inTplIntegerIntegerDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input DAELow.EquationArray inEquationArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inTplIntegerIntegerDAELowEquationLst1,inVariables2,inEquationArray3,inInteger4,inInteger5)
    local
      list<DAELow.Equation> eqn_lst;
      Codegen.CFunction res;
      Integer cg_id_1,unique_id,cg_id;
      list<tuple<Integer, Integer, DAELow.Equation>> jac;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
    case (jac,vars,eqns,unique_id,cg_id) /* unique_id cg var_id cg var_id */
      equation
        eqn_lst = DAELow.equationList(eqns);
        (res,cg_id_1) = generateOdeSystem2PopulateB2(eqn_lst, vars, 0, unique_id, cg_id);
      then
        (res,cg_id_1);
    case (jac,vars,eqns,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateB2 failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateB;

protected function generateOdeSystem2PopulateB2 "function: generateOdeSystem2PopulateB2
  author: PA
  Helper function to generate_ode_system2_populate_b
"
  input list<DAELow.Equation> inDAELowEquationLst1;
  input DAELow.Variables inVariables2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowEquationLst1,inVariables2,inInteger3,inInteger4,inInteger5)
    local
      Integer cg_id,cg_id_1,index_1,cg_id_2,index,unique_id;
      DAE.ExpType tp;
      DAE.Exp new_exp,rhs_exp,rhs_exp_1,rhs_exp_2,e1,e2,res_exp;
      Codegen.CFunction exp_func,cfunc,exp_func_1,cfunc_1;
      String var,index_str,id_str,stmt;
      list<DAELow.Equation> rest;
      DAELow.Variables v;
    case ({},_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* index iterator unique_id cg var_id cg var_id */
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),v,index,unique_id,cg_id)
      equation
        tp = Exp.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = DAELow.getEqnsysRhsExp(new_exp, v);
        rhs_exp_1 = DAE.UNARY(DAE.UMINUS(tp),rhs_exp);
        rhs_exp_2 = Exp.simplify(rhs_exp_1);
        (exp_func,var,cg_id_1) = Codegen.generateExpression(rhs_exp_2, cg_id, Codegen.simContext);
        index_str = intString(index);
        id_str = intString(unique_id);
        index_1 = index + 1;
        (cfunc,cg_id_2) = generateOdeSystem2PopulateB2(rest, v, index_1, unique_id, cg_id_1);
        stmt = Util.stringAppendList({"set_vector_elt(b",id_str,",",index_str,", ",var,");"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case ((DAELow.RESIDUAL_EQUATION(exp = res_exp) :: rest),v,index,unique_id,cg_id)
      equation
        rhs_exp = DAELow.getEqnsysRhsExp(res_exp, v);
        rhs_exp_1 = Exp.simplify(rhs_exp);
        (exp_func,var,cg_id_1) = Codegen.generateExpression(rhs_exp_1, cg_id, Codegen.simContext);
        index_str = intString(index);
        id_str = intString(unique_id);
        index_1 = index + 1;
        (cfunc,cg_id_2) = generateOdeSystem2PopulateB2(rest, v, index_1, unique_id, cg_id_1);
        stmt = Util.stringAppendList({"set_vector_elt(b",id_str,",",index_str,", ",var,");"});
        exp_func_1 = Codegen.cAddStatements(exp_func, {stmt});
        cfunc_1 = Codegen.cMergeFns({exp_func_1,cfunc});
      then
        (cfunc_1,cg_id_2);
    case ((DAELow.EQUATION(exp = e1,scalar = e2) :: rest),v,index,unique_id,cg_id)
      equation
        Debug.fprint("failtrace", "generateOdeSystem2PopulateB2 failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2PopulateB2;

protected function generateOdeSystem2SolveCall "function: generateOdeSystem2SolveCall
  author: PA

  Generates code for the call, including setup, for solving
  a linear system of equations.
"
	input Boolean mixedEvent;
  input Integer inInteger1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inInteger1,inInteger2,inInteger3)
    local
      String size_str,id_str,stmt,mixed_str;
      Codegen.CFunction cfunc;
      Integer eqn_size,unique_id,cg_id;
    case (mixedEvent,eqn_size,unique_id,cg_id) /* size of system unique_id cg var_id cg var_id */
      equation
        size_str = intString(eqn_size);
        id_str = intString(unique_id);
        mixed_str = Util.if_(mixedEvent,"_mixed","");
        stmt = Util.stringAppendList(
          {"solve_linear_equation_system",mixed_str,"(A",id_str,",b",id_str,",",
          size_str,",",id_str,");"});
        cfunc = Codegen.cAddStatements(Codegen.cEmptyFunction, {stmt});
      then
        (cfunc,cg_id);
  end matchcontinue;
end generateOdeSystem2SolveCall;

protected function generateOdeSystem2CollectResults "function: generateOdeSystem2CollectResults
  author: PA

  Generates the code for storing the result of solving
  a linear system of equations into the affected variables .
"
	input Boolean mixedEvent;
  input DAELow.Variables inVariables1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (mixedEvent,inVariables1,inInteger2,inInteger3)
    local
      list<DAELow.Var> var_lst,var_lst_1;
      list<DAE.ComponentRef> crefs;
      list<String> strs;
      Codegen.CFunction res;
      DAELow.Variables vars;
      Integer unique_id,cg_id;
    case (mixedEvent,vars,unique_id,cg_id) /* unique_id cg var_id cg var_id */
      equation
        var_lst = DAELow.varList(vars);
        var_lst_1 = listReverse(var_lst);
        crefs = Util.listMap(var_lst, DAELow.varCref);
        strs = Util.listMap(crefs, Exp.printComponentRefStr);
        res = generateOdeSystem2CollectResults2(strs, 0, unique_id);
      then
        (res,cg_id);
    case (mixedEvent,vars,unique_id,cg_id)
      equation
        Debug.fprint("failtrace",
          "generateOdeSystem2CollectResults failed\n");
      then
        fail();
  end matchcontinue;
end generateOdeSystem2CollectResults;

protected function generateOdeSystem2CollectResults2 "function: generateOdeSystem2CollectResults2
  author: PA
  Helper function to generateOdeSystem2CollectResults"
  input list<String> inStringLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  output CFunction outCFunction;
algorithm
  outCFunction := matchcontinue (inStringLst1,inInteger2,inInteger3)
    local
      Integer index_1,index,unique_id;
      Codegen.CFunction cfunc,cfunc_1;
      String index_str,id_str,stmt,str;
      list<String> strs;
    case ({},_,_) then Codegen.cEmptyFunction;  /* indx inique_id */
    case ((str :: strs),index,unique_id)
      equation
        index_1 = index + 1;
        cfunc = generateOdeSystem2CollectResults2(strs, index_1, unique_id);
        index_str = intString(index);
        id_str = intString(unique_id);
        stmt = Util.stringAppendList({str," = get_vector_elt(b",id_str,",",index_str,");"});
        cfunc_1 = Codegen.cAddStatements(cfunc, {stmt});
      then
        cfunc_1;
  end matchcontinue;
end generateOdeSystem2CollectResults2;

protected function transformXToXd "function transformXToXd
  author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)"
  input DAELow.Var inVar;
  output DAELow.Var outVar;
algorithm
  outVar:=
  matchcontinue (inVar)
    local
      String index_str,name,c_name,res;
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAELow.Type tp;
      Option<DAE.Exp> exp,st;
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      Integer index;
      list<Absyn.Path> classes;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "the origin of the element";

    case (DAELow.VAR(varName = cr,
                     varKind = DAELow.STATE(),
                     varDirection = dir,
                     varType = tp,
                     bindExp = exp,
                     bindValue = v,
                     arryDim = dim,
                     index = index,
                     origVarName = name,
                     source = source,
                     values = attr,
                     comment = comment,
                     flowPrefix = flowPrefix,
                     streamPrefix = streamPrefix))
      equation
        index_str = intString(index);
        name = Exp.printComponentRefStr(cr);
        c_name = name; // adrpo: 2009-09-07 this doubles $!! c_name = Util.modelicaStringToCStr(name,true);
        res = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name}) "	Util.string_append_list({\"xd{\",index_str, \"}\"}) => res" ;
      then
        DAELow.VAR(DAE.CREF_IDENT(res,DAE.ET_REAL(),{}),DAELow.STATE_DER(),dir,tp,exp,v,dim,index,cr,source,attr,comment,flowPrefix,streamPrefix);

    case (v)
      local DAELow.Var v;
      then
        v;
  end matchcontinue;
end transformXToXd;

protected function getEquationAndSolvedVar
"function: getEquationAndSolvedVar
  author: PA
  Retrieves the equation and the variable solved in that equation
  given an equation number and the variable assignments2"
  input Integer inInteger;
  input DAELow.EquationArray inEquationArray;
  input DAELow.Variables inVariables;
  input Integer[:] inIntegerArray;
  output DAELow.Equation outEquation;
  output DAELow.Var outVar;
algorithm
  (outEquation,outVar):=
  matchcontinue (inInteger,inEquationArray,inVariables,inIntegerArray)
    local
      Integer e_1,v,e;
      DAELow.Equation eqn;
      DAELow.Var var;
      DAELow.EquationArray eqns;
      DAELow.Variables vars;
      Integer[:] ass2;
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
        e_1 = e - 1;
        eqn = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        var = DAELow.getVarAt(vars, v);
      then
        (eqn,var);
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "SimCodegen.getEquationAndSolvedVar failed at index: " +& intString(e));
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar;

protected function isNonState "function: isNonState
  failes if the given variable kind is state
"
  input DAELow.VarKind inVarKind;
algorithm
  _:=
  matchcontinue (inVarKind)
    case (DAELow.VARIABLE()) then ();
    case (DAELow.DUMMY_DER()) then ();
    case (DAELow.DUMMY_STATE()) then ();
    case (DAELow.DISCRETE()) then ();
  end matchcontinue;
end isNonState;

protected function generateOdeEquation "function: generateOdeEquation
  author: PA

   Generates code for a single equation for the ode code generation, see
  genrerate_ode_code.
"
	input Boolean genDiscrete "if true generate discrete equations";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inInteger4,inInteger5)
    local
      DAE.Exp e1,e2,varexp,expr;
      DAELow.Var v;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
      Integer e,cg_id,cg_id_1,indx;
      DAE.ComponentRef cr,origname,cr_1;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Codegen.CFunction exp_func,res,cfunc;
      String var,cr_str,stmt,indxs,name,c_name,id,s1,s2,s;
      DAELow.Equation eqn;
      DAELow.MultiDimEquation[:] ae;
      list<CFunction> f1;
      Algorithm.Algorithm alg;
      DAE.ElementSource source "the origin of the element";

    /*discrete equations not considered if event-code is produced */
    case (false,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        true = useZerocrossing();
        (DAELow.EQUATION(e1,e2,_),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
        true = hasDiscreteVar({v});
      then
        (Codegen.cEmptyFunction,cg_id,{});

    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        (DAELow.EQUATION(e1,e2,_),(v as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) =
        getEquationAndSolvedVar(e, eqns, vars, ass2) "Solving for non-states" ;
        isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_1) =
        Codegen.generateExpression(expr, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
        cr_str = Exp.printComponentRefStr(cr);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        res = Codegen.cAddStatements(exp_func, {stmt});
      then
        (res,cg_id_1,{});

    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        (DAELow.EQUATION(e1,e2,_),DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))
        = getEquationAndSolvedVar(e, eqns, vars, ass2) "Solving the state s means solving for der(s)" ;
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr);
        // c_name = Util.modelicaStringToCStr(name,true);
        // id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        id = Util.stringAppendList({DAELow.derivativeNamePrefix, name});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_1) =
        Codegen.generateExpression(expr, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
        cr_str = Exp.printComponentRefStr(cr_1);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        res = Codegen.cAddStatements(exp_func, {stmt});
      then
        (res,cg_id_1,{});

    /* state nonlinear */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns,arrayEqs = ae),ass1,ass2,e,cg_id)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        c_name = name; // Util.modelicaStringToCStr(name,true);
        id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        (res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr_1}, {eqn},ae, cg_id);
      then
        (res,cg_id_1,f1);

    /* non-state non-linear */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns,arrayEqs = ae),ass1,ass2,e,cg_id)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(cr,kind,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        isNonState(kind);
        indxs = intString(indx);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        (res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr}, {eqn},ae, cg_id);
      then
        (res,cg_id_1,f1);

    /* When equations ignored */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        (DAELow.WHEN_EQUATION(_,_),_) = getEquationAndSolvedVar(e, eqns, vars, ass2);
      then
        (Codegen.cEmptyFunction,cg_id,{});

    /* Algorithm for single variable. */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars, orderedEqs = eqns,algorithms=alg),ass1,ass2,e,cg_id)
      local
        Integer indx;
        list<DAE.Exp> algInputs,algOutputs;
        DAELow.Var v;
        DAE.ComponentRef varOutput;
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
				// The output variable of the algorithm must be the variable solved for, otherwise we need to
				// solve an inverse problem of an algorithm section.
        true = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        (cfunc,cg_id_1) =
        Codegen.generateAlgorithm(DAE.ALGORITHM(alg,source), cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
      then (cfunc,cg_id_1,{});

    /* inverse Algorithm for single variable . */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars, orderedEqs = eqns,algorithms=alg),ass1,ass2,e,cg_id)
      local
        Integer indx;
        list<DAE.Exp> algInputs,algOutputs;
        DAELow.Var v;
        DAE.ComponentRef varOutput;
        String algStr,message;
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
				// We need to solve an inverse problem of an algorithm section.
        false = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = Util.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();

    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
				true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-SimCodegen.generateOdeEquation failed\n");
        (eqn,DAELow.VAR(cr,_,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) = getEquationAndSolvedVar(e, eqns, vars, ass2);
        s1 = DAELow.equationStr(eqn);
        s2 = Exp.printComponentRefStr(cr);
        s = Util.stringAppendList({"trying to solve ",s2," from eqn: ",s1,"\n"});
        Debug.fprint("failtrace", s);
      then
        fail();

  end matchcontinue;
end generateOdeEquation;

protected function generateOdeEquation_new "function: generateOdeEquation
  author: PA

   Generates code for a single equation for the ode code generation, see
  genrerate_ode_code.
"
	input Boolean genDiscrete "if true generate discrete equations";
  input DAELow.DAELow inDAELow1;
  input Integer[:] inIntegerArray2;
  input Integer[:] inIntegerArray3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<HelpVarInfo> inhelpvarinfo;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (genDiscrete,inDAELow1,inIntegerArray2,inIntegerArray3,inInteger4,inInteger5,inhelpvarinfo)
    local
      DAE.Exp e1,e2,varexp,expr,cond;
      DAELow.Var v;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
      Integer e,cg_id,cg_id_1,indx;
      DAE.ComponentRef cr,origname,cr_1;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Codegen.CFunction exp_func,res,cfunc;
      String var,cr_str,stmt,indxs,name,c_name,id,s1,s2,s;
      DAELow.Equation eqn;
      DAELow.MultiDimEquation[:] ae;
      list<CFunction> f1;
      Algorithm.Algorithm alg;
      list<HelpVarInfo> helpvarinfo1;
      list<DAELow.WhenClause> wc;
      DAE.ElementSource source "the origin of the element";

    /*discrete equations not considered if event-code is produced */
    case (false,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id,_)
      equation
        true = useZerocrossing();
        (DAELow.EQUATION(e1,e2,_),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
        true = hasDiscreteVar({v});
      then
        (Codegen.cEmptyFunction,cg_id,{});

    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id,_)
      equation
        (DAELow.EQUATION(e1,e2,_),(v as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) =
        getEquationAndSolvedVar(e, eqns, vars, ass2) "Solving for non-states" ;
        isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_1) =
        Codegen.generateExpression(expr, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
        cr_str = Exp.printComponentRefStr(cr);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        res = Codegen.cAddStatements(exp_func, {stmt});
      then
        (res,cg_id_1,{});

    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id,_)
      equation
        (DAELow.EQUATION(e1,e2,_),DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))
        = getEquationAndSolvedVar(e, eqns, vars, ass2) "Solving the state s means solving for der(s)" ;
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr);
        // c_name = Util.modelicaStringToCStr(name,true);
        // id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        id = Util.stringAppendList({DAELow.derivativeNamePrefix, name});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        (exp_func,var,cg_id_1) =
        Codegen.generateExpression(expr, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
        cr_str = Exp.printComponentRefStr(cr_1);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        res = Codegen.cAddStatements(exp_func, {stmt});
      then
        (res,cg_id_1,{});

    /* state nonlinear */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns,arrayEqs = ae),ass1,ass2,e,cg_id,_)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(cr,DAELow.STATE(),_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        indxs = intString(indx);
        name = Exp.printComponentRefStr(cr) "	Util.string_append_list({\"xd{\",indxs,\"}\"}) => id &" ;
        c_name = name; // Util.modelicaStringToCStr(name,true);
        id = Util.stringAppendList({DAELow.derivativeNamePrefix,c_name});
        cr_1 = DAE.CREF_IDENT(id,DAE.ET_REAL(),{});
        varexp = DAE.CREF(cr_1,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        (res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr_1}, {eqn},ae, cg_id);
      then
        (res,cg_id_1,f1);

    /* non-state non-linear */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns,arrayEqs = ae),ass1,ass2,e,cg_id,_)
      equation
        ((eqn as DAELow.EQUATION(e1,e2,_)),DAELow.VAR(cr,kind,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);
        isNonState(kind);
        indxs = intString(indx);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        (res,cg_id_1,f1) = generateOdeSystem2NonlinearResiduals(false,{cr}, {eqn},ae, cg_id);
      then
        (res,cg_id_1,f1);

    /*	When Equations  */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns,eventInfo = DAELow.EVENT_INFO(whenClauseLst = wc)),ass1,ass2,e,cg_id,helpvarinfo1)
      equation
        (eqn as DAELow.WHEN_EQUATION(_,_),DAELow.VAR(cr,kind,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) =
        getEquationAndSolvedVar(e, eqns, vars, ass2);

        (exp_func,cg_id_1) =
        generateWhenEquation(cg_id,eqn,wc, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP),helpvarinfo1);
      then
        (exp_func,cg_id_1,{});

    /* Algorithm for single variable. */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars, orderedEqs = eqns,algorithms=alg),ass1,ass2,e,cg_id,_)
      local
        Integer indx;
        list<DAE.Exp> algInputs,algOutputs;
        DAELow.Var v;
        DAE.ComponentRef varOutput;
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
				// The output variable of the algorithm must be the variable solved for, otherwise we need to
				// solve an inverse problem of an algorithm section.
        true = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        (cfunc,cg_id_1) =
        Codegen.generateAlgorithm(DAE.ALGORITHM(alg,source), cg_id, Codegen.CONTEXT(Codegen.SIMULATION(genDiscrete),Codegen.NORMAL(),Codegen.NO_LOOP));
      then (cfunc,cg_id_1,{});

    /* inverse Algorithm for single variable . */
    case (genDiscrete,DAELow.DAELOW(orderedVars = vars, orderedEqs = eqns,algorithms=alg),ass1,ass2,e,cg_id,_)
      local
        Integer indx;
        list<DAE.Exp> algInputs,algOutputs;
        DAELow.Var v;
        DAE.ComponentRef varOutput;
        String algStr,message;
      equation
        (DAELow.ALGORITHM(indx,algInputs,DAE.CREF(varOutput,_)::_,source),v) = getEquationAndSolvedVar(e, eqns, vars, ass2);
				// We need to solve an inverse problem of an algorithm section.
        false = Exp.crefEqual(DAELow.varCref(v),varOutput);
        alg = alg[indx + 1];
        algStr =	DAEUtil.dumpAlgorithmsStr({DAE.ALGORITHM(alg,source)});
        message = Util.stringAppendList({"Inverse Algorithm needs to be solved for in ",algStr,". This is not implemented yet.\n"});
        Error.addMessage(Error.INTERNAL_ERROR,{message});
      then fail();

    case (genDiscrete,DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns),ass1,ass2,e,cg_id,_)
      equation
        Debug.fprint("failtrace", "-SimCodegen.generateOdeEquation failed\n");
        (eqn,DAELow.VAR(cr,_,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix)) = getEquationAndSolvedVar(e, eqns, vars, ass2);
        s1 = DAELow.equationStr(eqn);
        s2 = Exp.printComponentRefStr(cr);
        s = Util.stringAppendList({"trying to solve ",s2," from eqn: ",s1,"\n"});
        Debug.fprint("failtrace", s);
      then
        fail();

  end matchcontinue;
end generateOdeEquation_new;


public function generateFunctions
"function generateFunctions
  Finds the called functions in daelow and generates code for them from
  the given DAE. Hence, the functions must exist in the DAE.Element list."
  input Env.Cache inCache;
  input Env.Env inEnv;
  input SCode.Program inProgram;
  input DAE.DAElist inDAElist;
  input DAELow.DAELow inDAELow;
  input Absyn.Path inPath;
  input String inString;
  output Env.Cache outCache;
  output list<String> outStringLst;
  output list<DAE.Element> outDAEElementList;
  output DAELow.DAELow outDAELow;
  output DAE.DAElist outDAE;
algorithm
  (outCache,outStringLst):=
  matchcontinue (inCache,inEnv,inProgram,inDAElist,inDAELow,inPath,inString)
    local
      list<Absyn.Path> funcpaths, fnrefs, fnpaths, fns, uniontypePaths;
      list<String> debugpathstrs,libs1,libs2,includes;
      String debugpathstr,debugstr,filename;
      list<DAE.Element> funcelems,funcelems_1,elements;
      list<SCode.Class> p;
      list<DAE.Type> metarecordTypes;
      Env.Cache cache;
      Env.Env env;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Absyn.Path path;
      DAE.FunctionTree funcs;

    case (cache,env,p,(dae as DAE.DAE(elements,funcs)),dlow,path,filename) /* Needed to instantiate functions libs */
      equation
        funcpaths = getCalledFunctions(dae, dlow);
        funcelems = generateFunctions2(p, funcpaths);
        funcelems_1 = PartFn.createPartEvalFunctions(funcelems);
        (dae,funcelems_1) = PartFn.partEvalDAE(dae,funcelems_1);
        (funcelems_1,dlow) = PartFn.partEvalDAELow(funcelems_1,dlow);
        funcelems_1 = Util.listUnion(funcelems_1,funcelems_1);
        funcelems_1 = Inline.inlineCallsInFunctions(funcelems_1);
        Print.clearBuf();
        Debug.fprintln("info", "Generating functions, call Codegen.\n") "debug" ;
				(_,libs1) = generateExternalObjectIncludes(dlow);
        uniontypePaths = Codegen.getUniontypePaths(funcelems_1);
        (cache,metarecordTypes) = Lookup.lookupMetarecordsRecursive(cache, env, uniontypePaths, {});
        libs2 = Codegen.generateFunctions(DAE.DAE(funcelems_1,funcs),metarecordTypes);
        Print.writeBuf(filename);
      then
        (cache,Util.listUnion(libs1,libs2),funcelems_1,dlow,dae);
    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Code generation of Modelica functions failed. "});
      then
        fail();
  end matchcontinue;
end generateFunctions;

protected function generateExternalObjectIncludes
"Generates the library paths for external objects"
	input DAELow.DAELow daelow;
  output list<String> includes;
	output list<String> libs;
algorithm
  (includes,libs) := matchcontinue (daelow)
    case DAELow.DAELOW(extObjClasses = extObjs)
    local list<list<String>> libsL,includesL;
      DAELow.ExternalObjectClasses extObjs;
      equation
        (includesL,libsL) = Util.listMap_2(extObjs,generateExternalObjectInclude);
        includes = Util.listListUnion(includesL);
        libs = Util.listListUnion(libsL);
      then (includes,libs);
  end matchcontinue;
end generateExternalObjectIncludes;

protected function generateExternalObjectInclude
"Helper function to generateExteralObjectInclude"
  input DAELow.ExternalObjectClass extObjCls;
  output list<String> includes;
  output list<String> libs;
algorithm
  (includes,libs) := matchcontinue(extObjCls)
    case (DAELow.EXTOBJCLASS(constructor=DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl=DAE.EXTERNALDECL(language=ann1))}),
      											destructor=DAE.FUNCTION(functions={DAE.FUNCTION_EXT(externalDecl=DAE.EXTERNALDECL(language=ann2))})))
      local Option<Absyn.Annotation> ann1,ann2;
        list<String> includes1,libs1,includes2,libs2;
      equation
        (includes1,libs1) = Codegen.generateExtFunctionIncludes(ann1);
        (includes2,libs2) = Codegen.generateExtFunctionIncludes(ann2);
        includes = Util.listListUnion({includes1,includes2});
        libs = Util.listListUnion({libs1,libs2});
      then (includes,libs);
  end matchcontinue;
end generateExternalObjectInclude;

public function generateFunctions2
"function: generateFunctions2
  author: PA
  Helper function to generateFunctions."
  input SCode.Program p;
  input list<Absyn.Path> paths;
  output list<DAE.Element> dae;
algorithm
  dae := generateFunctions3(p, paths, paths);
end generateFunctions2;

protected function generateFunctions3
"function: generateFunctions3
  Helper function to generateFunctions2"
  input SCode.Program inProgram1;
  input list<Absyn.Path> inAbsynPathLst2;
  input list<Absyn.Path> inAbsynPathLst3;
  output list<DAE.Element> outDAEElementLst;
algorithm
  outDAEElementLst:=
  matchcontinue (inProgram1,inAbsynPathLst2,inAbsynPathLst3)
    local
      list<Absyn.Path> allpaths,subfuncs,allpaths_1,paths_1,paths;
      DAE.DAElist fdae,dae,patched_dae;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<DAE.Element> elts,res;
      list<SCode.Class> p;
      Absyn.Path path;
      DAE.ExternalDecl extdecl;
      DAE.InlineType inl;
      Boolean partialPrefix;
      String s;
      DAE.ElementSource source "the origin of the element";
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;

    case (_,{},allpaths) then {};  /* iterated over complete list */

    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InnerOuter.emptyInstHierarchy, p, path);
        DAE.DAE({DAE.FUNCTION(functions =
          DAE.FUNCTION_DEF(daeElts)::_,type_ = t,partialPrefix = partialPrefix,inlineType=inl,source = source)},funcs) = fdae;
        patched_dae = DAE.DAE({DAE.FUNCTION(path,{DAE.FUNCTION_DEF(daeElts)},t,partialPrefix,inl,source)},funcs);
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.FUNCTION(path,{DAE.FUNCTION_DEF(daeElts)},t,partialPrefix,inl,source)});
      then
        res;

    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InnerOuter.emptyInstHierarchy, p, path);
        DAE.DAE({DAE.FUNCTION(functions=
          DAE.FUNCTION_EXT(daeElts,extdecl)::_,type_ = t,partialPrefix = partialPrefix,inlineType=inl,source = source)},funcs) = fdae;
        patched_dae = DAE.DAE({DAE.FUNCTION(path,{DAE.FUNCTION_EXT(daeElts,extdecl)},t,partialPrefix,inl,source)},funcs);
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.FUNCTION(path,{DAE.FUNCTION_EXT(daeElts,extdecl)},t,partialPrefix,inl,source)});
      then
        res;

    case (p,(path :: paths),allpaths)
      equation
        (_,_,_,fdae) = Inst.instantiateFunctionImplicit(Env.emptyCache(), InnerOuter.emptyInstHierarchy, p, path);
        DAE.DAE({DAE.RECORD_CONSTRUCTOR(type_ = t,source = source)},funcs) = fdae;
        patched_dae = DAE.DAE({DAE.RECORD_CONSTRUCTOR(path,t,source)},funcs);
        subfuncs = getCalledFunctionsInFunction(path, {}, patched_dae);
        (allpaths_1,paths_1) = appendNonpresentPaths(subfuncs, allpaths, paths);
        elts = generateFunctions3(p, paths_1, allpaths_1);
        res = listAppend(elts, {DAE.RECORD_CONSTRUCTOR(path,t,source)});
      then
        res;

    case (_,(path :: paths),_)
      equation
        s = Absyn.pathString(path);
        s = "SimCodegen.generateFunctions3 failed: " +& s +& "\n";
        print(s);
      then
        fail();
  end matchcontinue;
end generateFunctions3;

protected function appendNonpresentPaths
"function: appendNonpresentPaths
  Appends the paths in first argument to the two path lists given as second
  and third argument, given that the path is not present in the second path list."
  input list<Absyn.Path> inAbsynPathLst1;
  input list<Absyn.Path> inAbsynPathLst2;
  input list<Absyn.Path> inAbsynPathLst3;
  output list<Absyn.Path> outAbsynPathLst1;
  output list<Absyn.Path> outAbsynPathLst2;
algorithm
  (outAbsynPathLst1,outAbsynPathLst2):=
  matchcontinue (inAbsynPathLst1,inAbsynPathLst2,inAbsynPathLst3)
    local
      list<Absyn.Path> allpaths,iterpaths,paths,allpaths_1,iterpaths_1,allpaths_2,iterpaths_2;
      Absyn.Path path;

    case ({},allpaths,iterpaths) then (allpaths,iterpaths);  /* paths to append all paths iterated paths updated all paths update iterated paths */

    case ((path :: paths),allpaths,iterpaths)
      equation
        _ = Util.listGetMemberOnTrue(path, allpaths, ModUtil.pathEqual);
        (allpaths,iterpaths) = appendNonpresentPaths(paths, allpaths, iterpaths);
      then
        (allpaths,iterpaths);

    case ((path :: paths),allpaths,iterpaths)
      equation
        failure(_ = Util.listGetMemberOnTrue(path, allpaths, ModUtil.pathEqual));
        allpaths_1 = listAppend(allpaths, {path});
        iterpaths_1 = listAppend(iterpaths, {path});
        (allpaths_2,iterpaths_2) = appendNonpresentPaths(paths, allpaths_1, iterpaths_1);
      then
        (allpaths_2,iterpaths_2);
  end matchcontinue;
end appendNonpresentPaths;

public function generateInitData
"function generateInitData
  This function generates initial values for the generateExpression
  simulation by investigating values of variables."
  input DAELow.DAELow inDAELow1;
  input Absyn.Path inPath2;
  input String inString3;
  input String inString4;
  input Real inReal5;
  input Real inReal6;
  input Real inReal7;
  input Real inTolerance;
  input String method;
  input String options;
algorithm
  _ := matchcontinue (inDAELow1,inPath2,inString3,inString4,inReal5,inReal6,inReal7,inTolerance,method,options)
    local
      Real delta_time,step,start,stop,intervals,tolerance;
      String start_str,stop_str,step_str,tolerance_str,nx_str,ny_str,np_str,init_str,str,exe,filename;
      String ny_str,np_str,npstring_str,nystring_str;
      Integer nx,ny,np,npstring,nystring;
      DAELow.DAELow dlow;
      Absyn.Path class_;

    case (dlow,class_,exe,filename,start,stop,intervals,tolerance,method,_) /* classname executable file name filename start time stop time intervals */
      equation
        delta_time = stop -. start;
        step = delta_time/.intervals;
        start_str = realString(start);
        stop_str = realString(stop);
        step_str = realString(step);
        tolerance_str = realString(tolerance);
        (nx,ny,np,_,_,nystring,npstring) = DAELow.calculateSizes(dlow);
        nx_str = intString(nx);
        ny_str = intString(ny);
        np_str = intString(np);
        npstring_str = intString(npstring);
        nystring_str = intString(nystring);
        init_str = generateInitData2(dlow, nx, ny, np, nystring, npstring);
        str = Util.stringAppendList({
          start_str," // start value\n",
          stop_str," // stop value\n",
          step_str," // step value\n",
          tolerance_str, " // tolerance\n",
          "\"",method,"\" // method\n",
          nx_str," // n states\n",
          ny_str," // n alg vars\n",
          np_str," //n parameters\n",
          npstring_str," // n string-parameters\n",
          nystring_str," // n string variables\n",
          init_str});
        System.writeFile(filename, str);
      then
        ();

    case (_,_,_,_,_,_,_,_,_,_)
      equation
        print("-SimCodegen.generateInitData failed\n");
      then
        fail();

  end matchcontinue;
end generateInitData;

protected function generateInitData2
"function: generateInitData2
  Helper function to generateInitData
  Generates init data for states, variables and parameters.
  nx - number of states.
  ny - number of alg. vars.
  np - number of parameters."
  input DAELow.DAELow inDAELow1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer ny_string;
  input Integer np_string;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELow1,inInteger2,inInteger3,inInteger4,ny_string,np_string)
    local
      list<DAELow.Var> var_lst,knvar_lst;
      String[:] nxarr,nxdarr,nyarr,nparr,nxarr1,nxdarr1,nyarr1,nparr1,nxarr2,nxdarr2,nyarr2,nparr2,nxarr3,nxdarr3,nyarr3,nparr3;
      String[:] nystrarr,npstrarr;
      list<String> nx_lst,nxd_lst,ny_lst,np_lst,whole_lst,nystr_lst,npstr_lst;
      String res;
      DAELow.Variables vars,knvars;
      DAELow.EquationArray initeqn;
      Algorithm.Algorithm[:] alg;
      Integer nx,ny,np;
    case (DAELow.DAELOW(orderedVars = vars,knownVars = knvars,initialEqs = initeqn,algorithms = alg),nx,ny,np,ny_string,np_string)
      equation
        var_lst = DAELow.varList(vars);
        knvar_lst = DAELow.varList(knvars);
        nxarr = fill("", nx);
        nxdarr = fill("0.0", nx);
        nyarr = fill("", ny);
        nparr = fill("", np);
        nystrarr = fill("\"\"",ny_string);
        npstrarr = fill("\"\"",np_string);
        (nxarr1,nxdarr1,nyarr1,nparr1,nystrarr,npstrarr) = generateInitData3(var_lst, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
        (nxarr2,nxdarr2,nyarr2,nparr2,nystrarr,npstrarr) = generateInitData3(knvar_lst, nxarr1, nxdarr1, nyarr1, nparr1,nystrarr,npstrarr);
        (nxarr3,nxdarr3,nyarr3,nparr3,nystrarr,npstrarr) = generateInitData4(knvar_lst, nxarr2, nxdarr2, nyarr2, nparr2,nystrarr,npstrarr);
        nx_lst = arrayList(nxarr3);
        nxd_lst = arrayList(nxdarr3);
        ny_lst = arrayList(nyarr3);
        np_lst = arrayList(nparr3);
        nystr_lst = arrayList(nystrarr);
        npstr_lst = arrayList(npstrarr);
        whole_lst = Util.listFlatten({nx_lst,nxd_lst,ny_lst,np_lst,nystr_lst,npstr_lst});
        res = Util.stringDelimitListNonEmptyElts(whole_lst, "\n");
      then
        res;
  end matchcontinue;
end generateInitData2;

protected function printExpStrOpt
"function: printExpStrOpt
  Helper function to generate_init_data2
  Prints expression value that is opional for initial values.
  If NONE is passed. The default value 0.0 is returned."
  input Option<DAE.Exp> inExpExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpOption)
    local
      String str;
      DAE.Exp e;
    case NONE then "0.0";
    case SOME(e)
      equation
        str = Exp.printExpStr(e);
      then
        str;
  end matchcontinue;
end printExpStrOpt;

protected function generateInitData3
"function: generateInitData3
  This function is a help function to generateInitData2
  It Traverses Var lists and adds initial values to the specific
  string array depending on the type of the variable.
  For instance, state variables write their start value to the
  x array at given index."
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input String[:] inStringArray4;
  input String[:] inStringArray5;
  input String[:] inStringArray6;
  input String[:] inStringArray7;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output String[:] outStringArray3;
  output String[:] outStringArray4;
  output String[:] outStringArray5;
  output String[:] outStringArray6;
algorithm
  (outStringArray1,outStringArray2,outStringArray3,outStringArray4,outStringArray5,outStringArray6):=
  matchcontinue (inDAELowVarLst1,inStringArray2,inStringArray3,inStringArray4,inStringArray5,inStringArray6,inStringArray7)
    local
      String[:] nxarr,nxdarr,nyarr,nparr,nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr;
      String v,origname_str,str;
      DAE.ComponentRef cr,origname;
      Option<DAE.Exp> start;
      Integer indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest;
      DAE.Exp e;

    /* state strings derivative strings alg. var strings param. strings updated state strings updated derivative
       strings updated alg. var strings updated param. strings */
    case ({},nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) then (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    /* Strings handled separately */
    case ((DAELow.VAR(varName = cr,
                      varKind = DAELow.VARIABLE(),
                      varType = DAELow.STRING(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e));
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nystrarr = arrayUpdate(nystrarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((DAELow.VAR(varName = cr,
                      varKind = DAELow.VARIABLE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((DAELow.VAR(varName = cr,
                      varKind = DAELow.DISCRETE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((DAELow.VAR(varKind = DAELow.STATE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "State variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nxarr = arrayUpdate(nxarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((DAELow.VAR(varKind = DAELow.DUMMY_DER(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "dummy derivatives => algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((DAELow.VAR(varKind = DAELow.DUMMY_STATE(),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e)) "Dummy states => algebraic variables" ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nyarr = arrayUpdate(nyarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((_ :: rest),nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr) = generateInitData3(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr);

  end matchcontinue;
end generateInitData3;

public function printExpOptStrIfConst
"function: printExpOptStrIfConst
  Helper function to generateInitData3."
  input Option<DAE.Exp> inExpExpOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExpExpOption)
    local
      String res;
      DAE.Exp e;
    case (SOME(e))
      equation
        true = Exp.isConst(e);
        res = printExpStrOpt(SOME(e));
      then
        res;
    case (_)
      equation
        res = printExpStrOpt(NONE);
      then
        "0.0";
  end matchcontinue;
end printExpOptStrIfConst;

protected function generateInitData4
"function: generateInitData4
  Helper function to generateInitData2
  Traverses parameters."
  input list<DAELow.Var> inDAELowVarLst1;
  input String[:] inStringArray2;
  input String[:] inStringArray3;
  input String[:] inStringArray4;
  input String[:] inStringArray5;
  input String[:] inStringArray6;
  input String[:] inStringArray7;
  output String[:] outStringArray1;
  output String[:] outStringArray2;
  output String[:] outStringArray3;
  output String[:] outStringArray4;
  output String[:] outStringArray5;
  output String[:] outStringArray6;
algorithm
  (outStringArray1,outStringArray2,outStringArray3,outStringArray4,outStringArray5,outStringArray6):=
  matchcontinue (inDAELowVarLst1,inStringArray2,inStringArray3,inStringArray4,inStringArray5,inStringArray6,inStringArray7)
    local
      String[:] nxarr,nxdarr,nyarr,nparr,nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr;
      String v,origname_str,str;
      Values.Value value;
      Integer indx;
      DAE.ComponentRef origname;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAELow.Var> rest,vs;
      Option<DAE.Exp> start;
      DAE.Exp e;

    case ({},nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) then (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

		/* String-Parameters handled separately*/
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      varType = DAELow.STRING(),
                      bindValue = SOME(value),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        v = ValuesUtil.valString(value);
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        npstrarr = arrayUpdate(npstrarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

		/* Parameters */
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      bindValue = SOME(value),
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        v = ValuesUtil.valString(value);
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nparr = arrayUpdate(nparr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    /* String - Parameters without value binding. Investigate if it has start value */
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      bindValue = NONE,
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e))  ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        npstrarr = arrayUpdate(npstrarr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    /* Parameters without value binding. Investigate if it has start value */
    case ((DAELow.VAR(varKind = DAELow.PARAM(),
                      bindValue = NONE,
                      index = indx,
                      origVarName = origname,
                      values = dae_var_attr,
                      comment = comment,
                      flowPrefix = flowPrefix,
                      streamPrefix = streamPrefix) :: rest),
          nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        e = DAEUtil.getStartAttr(dae_var_attr);
        v = printExpOptStrIfConst(SOME(e))  ;
        origname_str = Exp.printComponentRefStr(origname);
        str = Util.stringAppendList({v," // ",origname_str});
        nparr = arrayUpdate(nparr, indx + 1, str);
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr) = generateInitData4(rest, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr);
      then
        (nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr);

    case ((_ :: vs),nxarr,nxdarr,nyarr,nparr,nystrarr,npstrarr)
      equation
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr) = generateInitData4(vs, nxarr, nxdarr, nyarr, nparr,nystrarr,npstrarr)
        "Skip alg. vars that are removed
	       TODO! In future we should compare eliminated variables
	       intial values to their aliases to detect inconsistent
	       initial values." ;
      then
        (nxarr_1,nxdarr_1,nyarr_1,nparr_1,nystrarr,npstrarr);
  end matchcontinue;
end generateInitData4;

protected function dumpWhenClausesStr
"function: dumpWhenClausesStr
  Prints when clauses to a string."
  input list<DAELow.WhenClause> inDAELowWhenClauseLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inDAELowWhenClauseLst)
    local
      String str,str2,res;
      DAELow.WhenClause c;
      list<DAELow.WhenClause> xs;
    case {} then "";
    case (c :: xs)
      equation
        str = dumpWhenClauseStr(c);
        str2 = dumpWhenClausesStr(xs);
        res = stringAppend(str, str2);
      then
        res;
  end matchcontinue;
end dumpWhenClausesStr;

protected function dumpWhenClauseStr
"function: dumpWhenClauseStr
  Prints a when clause to a string."
  input DAELow.WhenClause inWhenClause;
  output String outString;
algorithm
  outString:=
  matchcontinue (inWhenClause)
    local
      String str1,res;
      DAE.Exp exp;
    case DAELow.WHEN_CLAUSE(condition = exp)
      equation
        str1 = Exp.printExpStr(exp);
        res = Util.stringAppendList({"when ",str1,"\n"});
      then
        res;
  end matchcontinue;
end dumpWhenClauseStr;

protected function generateZeroCrossing
"function: generateZeroCrossing
  Generates code for handling zerocrossings as well as the
  zero crossing function given to the solver"
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input list<list<Integer>> inIntegerLstLst6;
  input list<HelpVarInfo> helpVarLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,inIntegerLstLst6,helpVarLst)
    local
      Codegen.CFunction func_zc,func_handle_zc,cfunc,cfunc0_1,cfunc0,cfunc_1,cfunc_2,func_zc0,func_handle_zc0,func_handle_zc0_1;
      Codegen.CFunction func_handle_zc0_2,func_handle_zc0_3,func_zc0_1,func_zc_1,func_handle_zc_1,cfuncHelpvars;
      Integer cg_id1,cg_id2,cg_id;
      list<CFunction> extra_funcs1,extra_funcs2,extra_funcs;
      String extra_funcs_str,helpvarUpdateStr,func_str,res,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      list<DAELow.ZeroCrossing> zc;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      list<HelpVarInfo> helpVarInfo;

    case (cname,dae,(dlow as DAELow.DAELOW(eventInfo = DAELow.EVENT_INFO(zeroCrossingLst = zc))),ass1,ass2,blocks,helpVarInfo)
      equation
        (cfunc,cg_id,extra_funcs2) = generateOdeBlocks(dae,true,dlow, ass1, ass2, blocks, 0);
        (func_zc,cg_id1,func_handle_zc,cg_id2,extra_funcs1) = generateZeroCrossing2(zc, 0, dae, dlow, ass1, ass2, blocks, helpVarInfo, 0, 0); // testing here
        (cfuncHelpvars,cg_id) = generateHelpVarAssignments(helpVarInfo,cg_id);
        extra_funcs = listAppend(extra_funcs1, extra_funcs2);
        extra_funcs_str = Codegen.cPrintFunctionsStr(extra_funcs);
        cfunc0_1 = Codegen.cMakeFunction("int", "function_updateDependents", {}, {""});
        cfunc0_1 = addMemoryManagement(cfunc0_1);
        cfunc0_1 = Codegen.cAddInits(cfunc0_1, {"inUpdate=initial()?0:1;"});
        cfunc0 = Codegen.cAddCleanups(cfunc0_1, {"inUpdate=0;","return 0;"});
        cfunc_2 = Codegen.cMergeFns({cfunc0,cfunc,cfuncHelpvars});

        func_zc0 = Codegen.cMakeFunction("int", "function_zeroCrossing", {},
          {"fortran_integer *neqm","double *t","double *x","fortran_integer *ng",
          "double *gout","double *rpar","fortran_integer* ipar"});
        func_zc0 = Codegen.cAddVariables(func_zc0,{"double timeBackup;"});
        func_zc0 = Codegen.cAddStatements(func_zc0,{"timeBackup = localData->timeValue;",
                                                    "localData->timeValue = *t;"
                                                    ,"functionODE();"
                                                    ,"functionDAE_output();"
                                                    });


        func_handle_zc0 = Codegen.cMakeFunction("int", "handleZeroCrossing", {}, {"long index"});
        func_handle_zc0_1 = Codegen.cPrependStatements(func_handle_zc0, {"switch(index) {"});
        func_handle_zc0_2 = Codegen.cAddCleanups(func_handle_zc0_1, {"default: break;","}"});
        func_handle_zc0_2 = addMemoryManagement(func_handle_zc0_2);
        func_zc0 = addMemoryManagement(func_zc0);
        func_handle_zc0_3 = Codegen.cAddCleanups(func_handle_zc0_2, {"return 0;"});

        func_zc0_1 = Codegen.cAddCleanups(func_zc0, {"localData->timeValue = timeBackup;", "return 0;"});
        func_zc_1 = Codegen.cMergeFns({func_zc0_1,func_zc});
        func_handle_zc_1 = Codegen.cMergeFns({func_handle_zc0_3,func_handle_zc});

        func_str = Codegen.cPrintFunctionsStr({func_zc_1,func_handle_zc_1,cfunc_2});
        res = Util.stringAppendList({extra_funcs_str,func_str});
      then
        res;

    case (_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_zero_crossing failed"});
      then
        fail();

  end matchcontinue;
end generateZeroCrossing;

protected function generateZeroCrossing2
"function: generateZeroCrossing2
  Helper function to generateZeroCrossing"
  input list<DAELow.ZeroCrossing> inDAELowZeroCrossingLst1;
  input Integer inInteger2;
  input DAE.DAElist inDAElist3;
  input DAELow.DAELow inDAELow4;
  input Integer[:] inIntegerArray5;
  input Integer[:] inIntegerArray6;
  input list<list<Integer>> inIntegerLstLst7;
  input list<HelpVarInfo> helpVarLst;  // not used her anymore
  input Integer inInteger9;
  input Integer inInteger10;
  output CFunction outCFunction1;
  output Integer outInteger2;
  output CFunction outCFunction3;
  output Integer outInteger4;
  output list<CFunction> outCFunctionLst5;
algorithm
  (outCFunction1,outInteger2,outCFunction3,outInteger4,outCFunctionLst5):=
  matchcontinue (inDAELowZeroCrossingLst1,inInteger2,inDAElist3,inDAELow4,inIntegerArray5,inIntegerArray6,inIntegerLstLst7,helpVarLst,inInteger9,inInteger10)
    local
      Integer cg_id1,cg_id2,index_1,cg_id1_1,cg_id2_1,cg_id2_2,index;
      String zc_str,index_str,stmt1,rettp,fn,case_stmt,help_var_str,res;
      Codegen.CFunction cfunc1,cfunc2,cfunc2_1,cfunc2_2,cfunc1_1;
      list<CFunction> extra_funcs1,extra_funcs2,extra_funcs;
      list<HelpVarInfo> usedHelpVars,helpVarInfo;
      list<String> retrec,arg,init,stmts,vars,cleanups,stmts_1,stmts_2;
      DAELow.ZeroCrossing zc;
      list<Integer> eql;
      list<DAELow.ZeroCrossing> xs;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      list<String> saveStmts;

    case ({},_,_,_,_,_,_,_,cg_id1,cg_id2) then (Codegen.cEmptyFunction,cg_id1,Codegen.cEmptyFunction,cg_id2,{});  /* cg_var_id2 */

    case (_,_,_,_,_,_,_,_,cg_id1,cg_id2)
      equation
        false = useZerocrossing();
      then
        (Codegen.cEmptyFunction,cg_id1,Codegen.cEmptyFunction,cg_id2,{});

    case (((zc as DAELow.ZERO_CROSSING(occurEquLst = eql)) :: xs),index,dae,dlow,ass1,ass2,blocks,helpVarInfo,cg_id1,cg_id2)
      equation
        zc_str = dumpZeroCrossingStr(zc);
        index_str = intString(index);
        index_1 = index + 1;
        (cfunc1,cg_id1_1,cfunc2,cg_id2_1,extra_funcs1) =

        generateZeroCrossing2(xs, index_1, dae, dlow, ass1, ass2, blocks, helpVarInfo, cg_id1, cg_id2);
        stmt1 = Util.stringAppendList({"ZEROCROSSING(",index_str,",",zc_str,");"});

        (Codegen.CFUNCTION(rettp,fn,retrec,arg,vars,init,stmts,cleanups),saveStmts,cg_id2_2,extra_funcs2) =
        buildZeroCrossingEqns(dae, dlow, ass1, ass2, eql, blocks, cg_id2_1);
        case_stmt = Util.stringAppendList({"case ",index_str,":"});
        stmts = listAppend(saveStmts,stmts); // save statements before all equations
        //stmts_1 = (case_stmt :: stmts);
        stmts_1 = case_stmt :: saveStmts; // new design: only save in case section, rest is done in updateDependents

        stmts_2 = listAppend(stmts_1, {"  break;\n"});
        cfunc2_1 = Codegen.CFUNCTION(rettp,fn,retrec,arg,vars,init,stmts_2,cleanups);
        cfunc2_2 = Codegen.cMergeFns({cfunc2_1,cfunc2});
        cfunc1_1 = Codegen.cPrependStatements(cfunc1, {stmt1});
        extra_funcs = listAppend(extra_funcs1, extra_funcs2);
      then
        (cfunc1_1,cg_id1_1,cfunc2_2,cg_id2_2,extra_funcs);

    case (((zc as DAELow.ZERO_CROSSING(occurEquLst = eql)) :: xs),index,dae,dlow,ass1,ass2,blocks,helpVarInfo,cg_id1,cg_id2)
      equation
        zc_str = dumpZeroCrossingStr(zc);
        res = Util.stringAppendList({"generating zero crossing :",zc_str,"\n"});
        Error.addMessage(Error.INTERNAL_ERROR, {res});
      then
        fail();

  end matchcontinue;
end generateZeroCrossing2;

protected function generateUpdateDepended
  input DAE.DAElist inDAElist;
  input DAELow.DAELow inDAELow;
  input Integer[:] inIntegerArray1;
  input Integer[:] inIntegerArray2;
  input list<list<Integer>> inIntegerLstLst;
  input list<HelpVarInfo> helpVarLst;
  input DAELow.IncidenceMatrix inIncidenceMatrix;
  input DAELow.IncidenceMatrixT inIncidenceMatrixT;
  output String outString;
algorithm
  outString :=
  matchcontinue (inDAElist,inDAELow,inIntegerArray1,inIntegerArray2,inIntegerLstLst,helpVarLst,inIncidenceMatrix,inIncidenceMatrixT)
    local
      Codegen.CFunction cfunc,cfunc_reinit,func_uD,cfunc_uD_0, func_zc,func_handle_zc,func_ozc;
      Integer cg_id,cg_id2,cg_id3;
      list<CFunction> extra_funcs,extra_funcs1;
      String func_str,res,func_str1,func_str2;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      list<HelpVarInfo> helpVarInfo;
      list<DAELow.ZeroCrossing> zc;
      list<Integer>[:] m,mt;
      Boolean usezc;
      String res,check_code2,check_code2_1;
    case (dae,(dlow as DAELow.DAELOW(eventInfo = DAELow.EVENT_INFO(zeroCrossingLst = zc))),ass1,ass2,blocks,helpVarInfo,m,mt)
      equation
        (cfunc,cg_id,extra_funcs) = generateOdeBlocks_new(dae, true,dlow, ass1, ass2, blocks, 0,helpVarInfo);
        (func_zc,cg_id2,func_handle_zc,cg_id3,extra_funcs1) = generateZeroCrossing2(zc, 0, dae, dlow, ass1, ass2, blocks, helpVarInfo, cg_id, cg_id); // testing here
        (cfunc_reinit, cg_id) = generateReinitStatmt(cg_id2, dlow, helpVarInfo );

        cfunc_uD_0 = Codegen.cMakeFunction("int", "function_updateDepend", {}, {""});
        cfunc_uD_0 = addMemoryManagement(cfunc_uD_0);
        cfunc_uD_0 = Codegen.cAddInits(cfunc_uD_0, {"inUpdate=initial()?0:1;"});
        cfunc_uD_0 = Codegen.cAddCleanups(cfunc_uD_0, {"inUpdate=0;","return 0;"});
        func_uD = Codegen.cMergeFns({cfunc_uD_0,cfunc,cfunc_reinit});

        func_ozc = Codegen.cMakeFunction("int", "function_onlyZeroCrossings", {}, {"double *gout,double *t"});
        func_ozc = addMemoryManagement(func_ozc);
        func_ozc = Codegen.cMergeFns({func_ozc,func_zc});
        func_ozc = Codegen.cAddCleanups(func_ozc, {"return 0;"});

        usezc = useZerocrossing();
        // The eventChecking consist of checking if discrete variables in the model has changed.
        check_code2 = buildDiscreteVarChanges(dlow,blocks,ass1,ass2,m,mt);
        check_code2_1 = Util.if_(usezc,check_code2, "");
        res = Util.stringAppendList(
          {"int checkForDiscreteChanges()\n{\n",
          "  int needToIterate=0;\n",
          check_code2_1,"\n",
          "  return needToIterate;\n","}\n"});

        func_str = Codegen.cPrintFunctionsStr({func_uD,func_ozc});
        func_str1 = Codegen.cPrintFunctionsStr(extra_funcs);
        func_str2 = Codegen.cPrintFunctionsStr(extra_funcs1);
        res = Util.stringAppendList({func_str1,func_str,func_str2,res});
      then
        res;

    case (_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_update_depended failed"});
      then
        fail();

  end matchcontinue;
end generateUpdateDepended;

protected function generateStoreDelayed2
  input list<DAE.Exp> exps;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction, outInteger) := matchcontinue(exps, inInteger)
    local
      Integer i;
      String exp_str;
      DAE.Exp e, id, delay, delayMax;
      list<DAE.Exp> xs;
      String st, st_e;
      CFunction fn1, fn2;
    case ({}, i) then (Codegen.cEmptyFunction, i);
    case (DAE.CALL(path = Absyn.IDENT("delay"), expLst = {id, e, delay, delayMax}) :: xs, i)
      equation
        (fn1, st_e, i) = Codegen.generateExpression(DAE.CALL(Absyn.IDENT("storeDelayedExpression"),
          {id, e}, false, true, DAE.ET_NORETCALL(), DAE.NORM_INLINE()), i, Codegen.simContext);
        st = Util.stringAppendList({st_e, ";"});
        fn1 = Codegen.cAddStatements(fn1, {st});
        (fn2, i) = generateStoreDelayed2(xs, i);
        fn2 = Codegen.cMergeFns({fn1, fn2});
      then
        (fn2, i);
    case (_, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generateStoreDelayed2 failed"});
      then
        fail();
  end matchcontinue;
end generateStoreDelayed2;

protected function generateStoreDelayed
"Generate a function for storing values of delayed expressions."
  input DAELow.DAELow inDAE;
  output String outString;
algorithm
  outString := matchcontinue(inDAE)
    local
      DAELow.DAELow dae;
      list<DAE.Exp> exps;
      list<list<DAE.Exp>> subexps;
      Codegen.CFunction cfunc, contents;
      Codegen.Context ctx;
      String result;
    case (dae)
      equation
        exps = DAELow.getAllExps(dae);
        subexps = Util.listMap(exps, DAELow.findDelaySubExpressions);
        exps = Util.listFlatten(subexps);
        cfunc = Codegen.cMakeFunction("int", "function_storeDelayed", {}, {""});
        cfunc = addMemoryManagement(cfunc);
        (contents, _) = generateStoreDelayed2(exps, 0);
        cfunc = Codegen.cMergeFns({cfunc, contents});
        cfunc = Codegen.cAddCleanups(cfunc, {"return 0;"});
        result = Codegen.cPrintFunctionsStr({cfunc});
      then
        result;
  end matchcontinue;
end generateStoreDelayed;

protected function isPartOfMixedSystem
"function: isPartOfMixedSystem
  Helper function to generateZeroCrossing2, returns true if any equation
  in the equation list of a zero-crossing is part of a mixed system."
  input DAELow.DAELow inDAELow;
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELow,inInteger,inIntegerLstLst,inIntegerArray)
    local
      list<Integer> block_;
      list<DAELow.Equation> eqn_lst;
      list<DAELow.Var> var_lst;
      Boolean res;
      DAELow.DAELow dae;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer e;
      list<list<Integer>> blocks;
      Integer[:] ass2;
    case ((dae as DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns)),e,blocks,ass2) /* equation blocks ass2 */
      equation
        block_ = DAELow.getEquationBlock(e, blocks);
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        res = isMixedSystem(var_lst,eqn_lst);
      then
        res;
    case (_,_,_,_) then false;
  end matchcontinue;
end isPartOfMixedSystem;

protected function getZcMixedSystem
"function: getZcMixedSystem
  Helper function to generateZeroCrossing2,
  returns true if any equation in the equation list
  of a zero-crossing is part of a mixed system."
  input DAELow.DAELow inDAELow;
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inDAELow,inInteger,inIntegerLstLst,inIntegerArray)
    local
      list<Integer> block_;
      list<DAELow.Equation> eqn_lst;
      list<DAELow.Var> var_lst;
      DAELow.DAELow dae;
      DAELow.Variables vars;
      DAELow.EquationArray eqns;
      Integer e;
      list<list<Integer>> blocks;
      Integer[:] ass2;
    case ((dae as DAELow.DAELOW(orderedVars = vars,orderedEqs = eqns)),e,blocks,ass2) /* equation blocks ass2 */
      equation
        block_ = DAELow.getEquationBlock(e, blocks);
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
      then
        block_;
  end matchcontinue;
end getZcMixedSystem;

protected function dumpZeroCrossingStr
"function: dumpZeroCrossingStr
  author:
  Dumps a ZeroCrossing to a sting. Useful for debugging."
  input DAELow.ZeroCrossing inZeroCrossing;
  output String outString;
algorithm
  outString:=
  matchcontinue (inZeroCrossing)
    local
      String e1_str,e2_str,op_str,zc_str,e_str;
      DAE.Exp e1,e2,start,interval,e;
      DAE.Operator op;

    case (DAELow.ZERO_CROSSING(relation_ = DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)))
      equation
        e1_str = printExpCppStr(e1);
        e2_str = printExpCppStr(e2);
        op_str = printZeroCrossingOpStr(op);
        zc_str = Util.stringAppendList({op_str,"(",e1_str,",",e2_str,")"});
      then
        zc_str;

    case (DAELow.ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"),expLst = {start,interval})))
      equation
        e1_str = printExpCppStr(start);
        e2_str = printExpCppStr(interval);
        zc_str = Util.stringAppendList({"Sample(*t,",e1_str,",",e2_str,")"});
      then
        zc_str;

    case (DAELow.ZERO_CROSSING(relation_ = e))
      equation
        e_str = printExpCppStr(e);
        zc_str = Util.stringAppendList({"/*Unknown zero crossing: ",e_str," */"});
      then
        zc_str;

  end matchcontinue;
end dumpZeroCrossingStr;

protected function generateHelpVarAssignments
  input list<HelpVarInfo> helpVarLst;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (helpVarLst,inInteger)
    local
      Integer cg_id,cg_id_1;
      String ind_str, assign,var;
      CFunction cfunc,cfunc1,cfunc2,cfn;
      Integer helpVarIndex;
      list<HelpVarInfo> rest;
      DAE.Exp e;

    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg_id cg var_id */

    case (((helpVarIndex,e,_) :: rest),cg_id)
      equation
        ind_str = intString(helpVarIndex);
        (cfunc,var,cg_id) = Codegen.generateExpression(e, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(true),Codegen.NORMAL(),Codegen.NO_LOOP));
        assign = Util.stringAppendList({"localData->helpVars[",ind_str,"] = ",var,";"});
        cfunc1 = Codegen.cAddStatements(cfunc, {assign});
        (cfunc2,cg_id_1) = generateHelpVarAssignments(rest, cg_id);
        cfn = Codegen.cMergeFns({cfunc1,cfunc2});
      then
        (cfn,cg_id_1);

  end matchcontinue;
end generateHelpVarAssignments;

protected function printZeroCrossingOpStr
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.LESS(ty = _)) then "Less";
    case (DAE.GREATER(ty = _)) then "Greater";
    case (DAE.LESSEQ(ty = _)) then "LessEq";
    case (DAE.GREATEREQ(ty = _)) then "GreaterEq";
  end matchcontinue;
end printZeroCrossingOpStr;

protected function generateWhenClauses
"function: generateWhenClauses
  Generate code for when clauses."
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input list<list<Integer>> inIntegerLstLst6;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,inIntegerLstLst6)
    local
      Codegen.CFunction when_fcn,when_fcn0,when_fcn_1,when_fcn_2,when_fcn3,when_fcn4;
      String res,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      list<DAELow.WhenClause> wc;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;

    case (cname,dae,(dlow as DAELow.DAELOW(eventInfo = DAELow.EVENT_INFO(whenClauseLst = wc))),ass1,ass2,blocks) /* assignments1 assignments2 blocks */
      equation
        (when_fcn,_) = generateWhenClauses2(wc, 0, dae, dlow, ass1, ass2, blocks, 0);
        when_fcn0 = Codegen.cMakeFunction("int", "function_when", {}, {"int i"});
        when_fcn_1 = Codegen.cMergeFns({when_fcn0,when_fcn});
        when_fcn_2 = Codegen.cPrependStatements(when_fcn_1, {"switch(i) {"});
        when_fcn3 = Codegen.cAddStatements(when_fcn_2, {"default: break;","}"});
        when_fcn3 = addMemoryManagement(when_fcn3);
        when_fcn4 = Codegen.cAddCleanups(when_fcn3, {"return 0;"});
        res = Codegen.cPrintFunctionsStr({when_fcn4});
      then
        res;

    case (_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generateWhenClauses failed"});
      then
        fail();

  end matchcontinue;
end generateWhenClauses;

protected function generateWhenClauses2
  input list<DAELow.WhenClause> inDAELowWhenClauseLst1;
  input Integer inInteger2;
  input DAE.DAElist inDAElist3;
  input DAELow.DAELow inDAELow4;
  input Integer[:] inIntegerArray5;
  input Integer[:] inIntegerArray6;
  input list<list<Integer>> inIntegerLstLst7;
  input Integer inInteger8;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAELowWhenClauseLst1,inInteger2,inDAElist3,inDAELow4,inIntegerArray5,inIntegerArray6,inIntegerLstLst7,inInteger8)
    local
      Integer cg_id,cg_id_1,index_1,cg_id_2,index;
      String wc_str,save_cond_str,reinit_str_1,index_str,when_str,case_stmt;
      list<DAE.ComponentRef> cond_cref_list;
      list<String> cond_cref_str_list,reinit_str;
      Codegen.CFunction when_fcn,when_fcn_1,when_fcn_2,when_fcn2,when_fcn_3;
      DAELow.WhenClause wc;
      DAE.Exp cond;
      list<DAELow.ReinitStatement> reinit;
      list<DAELow.WhenClause> xs;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;

    case ({},_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* assignments1 assignments2 blocks cg var_id cg var_id */

    case (((wc as DAELow.WHEN_CLAUSE(condition = cond,reinitStmtLst = reinit)) :: xs),index,dae,dlow,ass1,ass2,blocks,cg_id)
      equation
        wc_str = dumpWhenClauseStr(wc);
        cond_cref_list = Exp.getCrefFromExp(cond);
        cond_cref_str_list = Util.listMap(cond_cref_list, Exp.printComponentRefStr);
        save_cond_str = Util.stringDelimitList(cond_cref_str_list, ");\n    save(");
        save_cond_str = Util.stringAppendList({"    save(",save_cond_str,");\n"});
        reinit_str = Util.listMap(reinit, buildReinitStr);
        reinit_str_1 = Util.stringAppendList(reinit_str);
        index_str = intString(index);
        (when_fcn,cg_id_1) = buildWhenBlocks(dae, dlow, ass1, ass2, blocks, index, cg_id);
        when_str = Codegen.cPrintStatements(when_fcn);
        case_stmt = Util.stringAppendList({" case ",index_str,": //",wc_str});
        when_fcn_1 = Codegen.cPrependStatements(when_fcn, {case_stmt});
        when_fcn_2 = Codegen.cAddStatements(when_fcn_1, {reinit_str_1,"  break;\n"});
        index_1 = index + 1;
        (when_fcn2,cg_id_2) = generateWhenClauses2(xs, index_1, dae, dlow, ass1, ass2, blocks, cg_id_1);
        when_fcn_3 = Codegen.cMergeFns({when_fcn_2,when_fcn2});
      then
        (when_fcn_3,cg_id_2);

  end matchcontinue;
end generateWhenClauses2;

protected function generateWhenEquation
	input Integer intmpIdx;
	input DAELow.Equation eqn;
	input list<DAELow.WhenClause> inWhenClause;
  input Codegen.Context inContext;
  input list<HelpVarInfo> varhelpinfo;
  output Codegen.CFunction outCFunction;
  output Integer outtmpIdx;
algorithm
  (outCFunction,outtmpIdx) := matchcontinue (intmpIdx,eqn,inWhenClause,inContext,varhelpinfo)
    local
      Codegen.Context context;
      Integer tnr, tnr2,tnr3,tnr4,hlpnr,hlpnr1,cidx;
      DAE.Exp ex1,ex2;
      list<DAE.Exp> expl;
      DAE.ComponentRef cpr;
      String cr_str;
      String ifExprStr,ifExprStr2,ifExprStr3,ifExprStr4,ifExprStr5;
      String out;
      String var,var1,var2,helpvar;
      list<HelpVarInfo> varhelpinfo1;
      Codegen.CFunction cfn, cfn2,cfn3,cfn4,cfn5;
      list<DAELow.WhenClause> wc;

    case (tnr,(DAELow.WHEN_EQUATION(whenEquation=DAELow.WHEN_EQ(left = cpr, right = ex2, index = cidx ))),wc,context,varhelpinfo1)
      equation
        expl = getConditionList(wc,cidx);
        (cfn,tnr2,helpvar) = generateHelpVarAssignTempHelp(varhelpinfo1,tnr,expl);
        (cfn3,var1,tnr3) = Codegen.generateExpression(ex2,tnr2,context);
        cr_str = Exp.printComponentRefStr(cpr);
        ifExprStr = Util.stringAppendList({"if (",helpvar,") {"});
        ifExprStr2 = Util.stringAppendList({cr_str,"=",var1,";"});
        ifExprStr3 = "}else{";
        ifExprStr4 = Util.stringAppendList({cr_str,"= pre(",cr_str,");"});
        ifExprStr5 = "}";
        cfn2 = Codegen.cAddStatements(cfn, {ifExprStr});
        cfn4 = Codegen.cMergeFns({cfn2, cfn3});
        cfn = Codegen.cAddStatements(cfn4,{ifExprStr2,ifExprStr3,ifExprStr4,ifExprStr5});
      then (cfn,tnr3);
    case(tnr,_,_,_,_) then (Codegen.cEmptyFunction,tnr);
  end matchcontinue;
end generateWhenEquation;

protected function generateHelpVarAssignTemp
  input list<HelpVarInfo> helpVarLst;
  input Integer inInteger;
  input DAE.Exp inVar;
  output CFunction outCFunction;
  output Integer outInteger;
  output String HelpVar;
algorithm
  (outCFunction,outInteger,HelpVar):=
  matchcontinue (helpVarLst,inInteger,inVar)
    local
      Integer cg_id;
      String helpvar;
      CFunction cfunc;
      Integer helpVarIndex;
      list<HelpVarInfo> helpinfolist;
      DAE.Exp e;
      list<DAE.Exp> elst;
    case ({},cg_id,_) then (Codegen.cEmptyFunction,cg_id,"");  // cg_id cg var_id
    case (helpinfolist,cg_id,DAE.ARRAY(array = elst))
      equation
        (cfunc,cg_id,helpvar) = generateHelpVarAssignTempHelp(helpinfolist, cg_id, elst);
      then
        (cfunc,cg_id,helpvar);
    case (helpinfolist,cg_id,e)
      equation
        (cfunc,cg_id,helpvar) = generateHelpVarAssignTempHelp(helpinfolist, cg_id, {e});
      then
        (cfunc,cg_id,helpvar);
  end matchcontinue;
end generateHelpVarAssignTemp;

protected function generateHelpVarAssignTempHelp
  input list<HelpVarInfo> helpVarLst;
  input Integer inInteger;
  input list<DAE.Exp> inVar;
  output CFunction outCFunction;
  output Integer outInteger;
  output String HelpVar;
algorithm
  (outCFunction,outInteger,HelpVar):=
  matchcontinue (helpVarLst,inInteger,inVar)
    local
      Integer cg_id,cg_id_1,cg_id_2;
      CFunction cfunc,cfunc1,cfunc2;
      list<HelpVarInfo> helpinfo;
      String helpvar1,helpvar2,helpvar;
      DAE.Exp e;
      list<DAE.Exp> rest_e;
    case ({},cg_id,{}) then (Codegen.cEmptyFunction,cg_id,"");  /* cg_id cg var_id */
    case (helpinfo,cg_id,e::rest_e)
      equation
        (cfunc1,cg_id_1,helpvar1) = generateHelpVarAssignTempHelp(helpinfo, cg_id, rest_e);
        (cfunc2,cg_id_2,helpvar2) = generateHelpVarAssignTempHelp2(helpinfo, cg_id_1, e);
        cfunc = Codegen.cMergeFns({cfunc1,cfunc2});
        helpvar = Util.stringAppendList({helpvar1," || ",helpvar2});
      then
        (cfunc,cg_id_2,helpvar);
    case (helpinfo,cg_id,e::{})
      equation
        (cfunc,cg_id_1,helpvar) = generateHelpVarAssignTempHelp2(helpinfo, cg_id, e);
      then
        (cfunc,cg_id_1,helpvar);
  end matchcontinue;
end generateHelpVarAssignTempHelp;

protected function generateHelpVarAssignTempHelp2
  input list<HelpVarInfo> helpVarLst;
  input Integer inInteger;
  input DAE.Exp inVar;
  output CFunction outCFunction;
  output Integer outInteger;
  output String HelpVar;
algorithm
  (outCFunction,outInteger,HelpVar):=
  matchcontinue (helpVarLst,inInteger,inVar)
    local
      Integer cg_id,cg_id_1;
      String ind_str, assign,var,helpvar;
      CFunction cfunc,cfunc1;
      Integer helpVarIndex;
      list<HelpVarInfo> helpinfolist;
      DAE.Exp e,e1;
      list<DAE.Exp> elst,rest_e;

    case ({},cg_id,_) then (Codegen.cEmptyFunction,cg_id,"");  /* cg_id cg var_id */
    case (((helpVarIndex,e,_) :: helpinfolist),cg_id,e1)
      equation
        true = Exp.expEqual(e1, e);
        ind_str = intString(helpVarIndex);
        (cfunc1,var,cg_id_1) = Codegen.generateExpression(e, cg_id, Codegen.CONTEXT(Codegen.SIMULATION(true),Codegen.NORMAL(),Codegen.NO_LOOP));
        helpvar = Util.stringAppendList({"edge(localData->helpVars[",ind_str,"])"});
        assign = Util.stringAppendList({"localData->helpVars[",ind_str,"] = ",var,";"});
        cfunc = Codegen.cAddStatements(cfunc1, {assign});
      then
        (cfunc,cg_id_1,helpvar);
    case (((helpVarIndex,e,_) :: helpinfolist),cg_id,e1)
      equation
        false = Exp.expEqual(e1, e);
        (cfunc,cg_id_1,helpvar) = generateHelpVarAssignTempHelp2(helpinfolist, cg_id,e1);
      then
        (cfunc,cg_id_1,helpvar);
  end matchcontinue;
end generateHelpVarAssignTempHelp2;

protected function generateReinitStatmt
  input Integer inInteger;
  input DAELow.DAELow inDAELow;
  input list<HelpVarInfo> inHelpVarInfo;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inInteger,inDAELow,inHelpVarInfo)
    local
      Integer cg_id,cg_id_1;
      Codegen.CFunction cfn;
      list<HelpVarInfo> helpvarinfo;
      list<DAELow.WhenClause> wc;
    case (cg_id,DAELow.DAELOW(eventInfo = DAELow.EVENT_INFO(whenClauseLst = wc)),helpvarinfo)
      equation
        (cfn,cg_id_1) = generateReinitStatmtHelp(cg_id,wc,helpvarinfo, Codegen.cEmptyFunction );
      then
        (cfn,cg_id_1);
  end matchcontinue;
end generateReinitStatmt;

protected function generateReinitStatmtHelp
  input Integer inInteger;
  input list<DAELow.WhenClause> inDAELow;
  input list<HelpVarInfo> inHelpVarInfo;
  input CFunction inCFunction;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inInteger,inDAELow,inHelpVarInfo,inCFunction)
    local
      Integer cg_id,cg_id_1;
      list<String> reinit_str;
      String ifExprStr, ifExprStr2, ifExprStr3, helpvar, reinit_str_1;
      Codegen.CFunction cfn,cfn1,cfn2,cfn3;
      DAE.Exp cond;
      list<DAELow.ReinitStatement> reinit;
      list<HelpVarInfo> helpvarinfo;
      list<DAELow.WhenClause> xs;
   case (cg_id,(DAELow.WHEN_CLAUSE(condition = cond,reinitStmtLst = {}) :: xs),helpvarinfo,cfn)
      equation
        //false = Util.isListNotEmpty(reinit);
        (cfn,cg_id_1) = generateReinitStatmtHelp(cg_id,xs,helpvarinfo,cfn);
      then
        (cfn,cg_id_1);
    case (cg_id,(DAELow.WHEN_CLAUSE(condition = cond,reinitStmtLst = reinit) :: xs),helpvarinfo,cfn)
      equation
        (cfn1,cg_id_1,helpvar) = generateHelpVarAssignTemp(helpvarinfo,cg_id,cond);
        ifExprStr = Util.stringAppendList({"if (",helpvar,") {"});
        reinit_str = Util.listMap(reinit, buildReinitStr);
        reinit_str_1 = Util.stringAppendList(reinit_str);
        ifExprStr2 = "}else{";
        ifExprStr3 = "}";
        cfn2 = Codegen.cAddStatements(cfn1, {ifExprStr,reinit_str_1,ifExprStr2,ifExprStr3});
        cfn3 = Codegen.cMergeFns({cfn,cfn2});
        (cfn,cg_id) = generateReinitStatmtHelp(cg_id_1,xs,helpvarinfo,cfn3);
      then
        (cfn,cg_id);
    case(cg_id,{},_,cfn) then (cfn,cg_id);
  end matchcontinue;
end generateReinitStatmtHelp;

protected function buildReinitStr
  input DAELow.ReinitStatement inReinitStatement;
  output String outString;
algorithm
  outString:=
  matchcontinue (inReinitStatement)
    local
      String cr_str,exp_str,eqn_str;
      DAE.ComponentRef cr;
      DAE.Exp exp;
    case (DAELow.REINIT(stateVar = cr,value = exp))
      equation
        cr_str = Exp.printComponentRefStr(cr);
        exp_str = printExpCppStr(exp);
        eqn_str = Util.stringAppendList({"    ",cr_str," = ",exp_str,";\n"});
      then
        eqn_str;
  end matchcontinue;
end buildReinitStr;

protected function buildWhenBlocks
"function: buildWhenBlocks
  Helper function to buildWhenClauses."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<list<Integer>> inIntegerLstLst5;
  input Integer inInteger6;
  input Integer inInteger7;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLstLst5,inInteger6,inInteger7)
    local
      Integer cg_id,cg_id_1,cg_id_2,eqn,index;
      Codegen.CFunction cfn1,cfn2,cfn;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;

    case (_,_,_,_,{},_,cg_id) then (Codegen.cEmptyFunction,cg_id);  /* cg var_id cg var_id */

    case (dae,dlow,ass1,ass2,((block_ as {eqn}) :: blocks),index,cg_id)
      equation
        (cfn1,cg_id_1) = buildWhenEquation(dae, dlow, ass1, ass2, eqn, index, cg_id);
        (cfn2,cg_id_2) = buildWhenBlocks(dae, dlow, ass1, ass2, blocks, index, cg_id_1);
        cfn = Codegen.cMergeFns({cfn1,cfn2});
      then
        (cfn,cg_id_2);
    case (dae,dlow,ass1,ass2,(block_  :: blocks),index,cg_id)
      equation
        //(cfn1,cg_id_1) = buildWhenEquation(dae, dlow, ass1, ass2, eqn, index, cg_id);
        (cfn,cg_id_1) = buildWhenBlocks(dae, dlow, ass1, ass2, blocks, index, cg_id);
      then
        (cfn,cg_id_1);
    case (_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);
  end matchcontinue;
end buildWhenBlocks;


protected function buildZeroCrossingEqns
"function: buildZeroCrossingEqns2
  author: haklu
  Helper function to generateZeroCrossing2.
  Iterates and generates code for each equation in a zero crossing."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<Integer> inIntegerLst5;
  input list<list<Integer>> inIntegerLstLst6;
  input Integer inInteger7;
  output CFunction outCFunction;
  output list<String> saveStmts " list of 'save(..);' statements";
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLst5,inIntegerLstLst6,inInteger7)
    local
      Integer cg_id,eqn_1,v,cg_id1,cg_id2,cg_id3,cg_id4,cg_id5,cg_id6,eqn,cg_id_1,cg_id_2,numValues;
      list<Integer> block_,rest;
      DAE.ComponentRef cr;
      String cr_str,save_stmt,rettp,fn,stmt;
      list<DAELow.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<DAELow.Var> var_lst,cont_var,disc_var,cont_var1;
      DAELow.Variables vars, vars_1,knvars,exvars;
      VarTransform.VariableReplacements av "alias-variables' hashtable";
      DAELow.EquationArray eqns_1,eqns,se,ie;
      DAELow.DAELow cont_subsystem_dae,dlow;
      list<Integer>[:] m,m_1,mt_1;
      Option<list<tuple<Integer, Integer, DAELow.Equation>>> jac;
      DAELow.JacobianType jac_tp;
      Codegen.CFunction s0,s2_1,s4,s3,s1,cfn3,cfn,cfn2,cfn1;
      list<String> retrec,arg,init,stmts,cleanups,stmts_1;
      list<CFunction> extra_funcs1,extra_funcs2,extra_funcs;
      DAE.DAElist dae;
      DAELow.MultiDimEquation[:] ae;
      Algorithm.Algorithm[:] al;
      DAELow.EventInfo ev;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
      DAELow.ExternalObjectClasses eoc;

    case (_,_,_,_,{},_,cg_id) then (Codegen.cEmptyFunction,{},cg_id,{});  /* ass1 ass2 eqns blocks cg var_id cg var_id */

    /* Zero crossing for mixed system */      
    case (dae,(dlow as DAELow.DAELOW(vars,knvars,exvars,av,eqns,se,ie,ae,al,ev,eoc)),ass1,ass2,(eqn :: rest),blocks,cg_id) 
      equation
        true = isPartOfMixedSystem(dlow, eqn, blocks, ass2);
        block_ = getZcMixedSystem(dlow, eqn, blocks, ass2);
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (DAELow.VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,_)) = DAELow.getVarAt(vars, v);
        cr_str = Exp.printComponentRefStr(cr);
        save_stmt = Util.stringAppendList({"  save(",cr_str,");"});
        (eqn_lst,var_lst) = Util.listMap32(block_, getEquationAndSolvedVar, eqns, vars, ass2);
        true = isMixedSystem(var_lst,eqn_lst);
        eqn_lst = Util.listMap(eqn_lst,replaceEqnGreaterWithGreaterEq);
        //temporary fix to make events occur. Remove once mixed systems are solved analythically
        (cont_eqn,cont_var,disc_eqn,disc_var) = splitMixedEquations(eqn_lst, var_lst);
				cont_var1 = Util.listMap(cont_var, transformXToXd); // States are solved for der(x) not x.
        vars_1 = DAELow.listVar(cont_var1);
        eqns_1 = DAELow.listEquation(cont_eqn);
        cont_subsystem_dae = DAELow.DAELOW(vars_1,knvars,exvars,av,eqns_1,se,ie,ae,al,ev,eoc);
        /*
        m = DAELow.incidenceMatrix(cont_subsystem_dae);
        m_1 = DAELow.absIncidenceMatrix(m);
        mt_1 = DAELow.transposeMatrix(m_1);
        jac = DAELow.calculateJacobian(vars_1, eqns_1, ae, m_1, mt_1) "calculate jacobian. If constant, linear system of equations. Otherwise nonlinear" ;
        jac_tp = DAELow.analyzeJacobian(cont_subsystem_dae, jac);
        (s0,cg_id1,numValues) = generateMixedHeader(cont_eqn, cont_var, disc_eqn, disc_var, cg_id);
        (Codegen.CFUNCTION(rettp,fn,retrec,arg,vars,init,stmts,cleanups),cg_id2,extra_funcs1) = generateOdeSystem2(true,true,cont_subsystem_dae, jac, jac_tp, cg_id1);
        stmts_1 = Util.listFlatten({{"{"},vars,stmts,{"}"}})
        "initialization of e.g. matrices for linsys must be done in each iteration, create new scope and put them first." ;
        s2_1 = Codegen.CFUNCTION(rettp,fn,retrec,arg,{},init,stmts_1,cleanups);
        (s4,cg_id3) = generateMixedFooter(cont_eqn, cont_var, disc_eqn, disc_var, cg_id2);
        (s3,cg_id4,_) = generateMixedSystemDiscretePartCheck(disc_eqn, disc_var, cg_id3,numValues);
        (s1,cg_id5,_) = generateMixedSystemStoreDiscrete(disc_var, 0, cg_id4);
        */
        cg_id5 = cg_id;
        (cfn3,saveStmts,cg_id6,extra_funcs2) = buildZeroCrossingEqns(dae, dlow, ass1, ass2, rest, blocks, cg_id5);
        cfn = Codegen.cMergeFns({cfn3});
        extra_funcs = listAppend(/*extra_funcs1*/{}, extra_funcs2);
      then
        (cfn,save_stmt::saveStmts,cg_id6,extra_funcs);

    /* Zero crossing for single equation */
    case (dae,(dlow as DAELow.DAELOW(orderedVars = vars)),ass1,ass2,(eqn :: rest),blocks,cg_id)
      local DAELow.Variables vars;
      equation
        // (cfn2,cg_id_1) = buildEquation(dae, dlow, ass1, ass2, eqn, cg_id);
        cfn2 = Codegen.cEmptyFunction;
        cg_id_1 = cg_id;
        eqn_1 = eqn - 1;
        v = ass2[eqn_1 + 1];
        (DAELow.VAR(cr,_,_,_,_,_,_,_,_,_,_,_,_,_)) = DAELow.getVarAt(vars, v);
        cr_str = Exp.printComponentRefStr(cr);
        (cfn3,saveStmts,cg_id_2,extra_funcs) = buildZeroCrossingEqns(dae, dlow, ass1, ass2, rest, blocks, cg_id_1);
        stmt = Util.stringAppendList({"  save(",cr_str,");"});
       cfn = Codegen.cMergeFns({cfn2,cfn3});
      then
        (cfn,stmt::saveStmts,cg_id_2,extra_funcs);

    case (_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,{},cg_id,{});
  end matchcontinue;
end buildZeroCrossingEqns;

protected function replaceEqnGreaterWithGreaterEq
"function replaceEqnGreaterWithGreaterEq
 Temporary fix to get mixed system to work in
 e.g. Modelica.Mechanics.Rotational.Interfaces.FrictionBase"
  input DAELow.Equation eqn;
  output DAELow.Equation res;
algorithm
  res := matchcontinue(eqn)
    local
      DAE.Exp e1,e2;
      DAELow.Equation e;
      DAE.ComponentRef cr1;
      DAE.ElementSource source "the origin of the element";

    case(DAELow.EQUATION(e1,e2,source))
      equation
        ((e1,_)) = Exp.traverseExp(e1,replaceExpGTWithGE,true);
        ((e2,_)) = Exp.traverseExp(e2,replaceExpGTWithGE,true);
      then DAELow.EQUATION(e1,e2,source);

    case(DAELow.SOLVED_EQUATION(cr1,e2,source))
      equation
        ((e2,_)) = Exp.traverseExp(e2,replaceExpGTWithGE,true);
      then DAELow.SOLVED_EQUATION(cr1,e2,source);

    case(DAELow.RESIDUAL_EQUATION(e1,source))
      equation
        ((e1,_)) = Exp.traverseExp(e1,replaceExpGTWithGE,true);
      then DAELow.RESIDUAL_EQUATION(e1,source);

    case(e) then e;
  end matchcontinue;
end replaceEqnGreaterWithGreaterEq;

protected function replaceExpGTWithGE
"traversal function to replace > with >="
  input tuple<DAE.Exp,Boolean> inExp;
  output tuple<DAE.Exp,Boolean> outExp;
algorithm
  outExp := matchcontinue(inExp)
  local DAE.ExpType tp;
    DAE.Exp e1,e2;
    Boolean dummyArg;
    case((DAE.RELATION(e1,DAE.LESS(tp),e2),dummyArg)) then ((DAE.RELATION(e1,DAE.LESSEQ(tp),e2),dummyArg));
    case((DAE.RELATION(e1,DAE.GREATER(tp),e2),dummyArg)) then ((DAE.RELATION(e1,DAE.GREATEREQ(tp),e2),dummyArg));
    case((e1,dummyArg)) then ((e1,dummyArg));
  end matchcontinue;
end replaceExpGTWithGE;

protected function dumpMixedSystem
"function: dumpMixedSystem
  dumps a mixed system of equations on stdout."
  input list<DAELow.Equation> c_e;
  input list<DAELow.Var> c_v;
  input list<DAELow.Equation> d_e;
  input list<DAELow.Var> d_v;
algorithm
  print("Mixed system\n");
  print("============\n");
  print("  continous eqns:\n");
  DAELow.dumpEqns(c_e);
  print("  continous vars:\n");
  DAELow.dumpVars(c_v);
  print("  discrete eqns:\n");
  DAELow.dumpEqns(d_e);
  print("  discret vars:\n");
  DAELow.dumpVars(d_v);
  print("\n");
end dumpMixedSystem;

protected function buildWhenEquation
"function: buildWhenEquation
  Helper function to buildWhenBlocks."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger) := matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inInteger7)
    local
      Integer e_1,wc_ind,v,v_1,cg_id_1,e,index,cg_id;
      DAE.ComponentRef cr,origname;
      DAE.Exp expr,cond;
      DAELow.Var va;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String assignedVar,origname_str,save_stmt;
      Codegen.CFunction cfn;
      DAE.DAElist dae;
      DAELow.VariableArray vararr;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
      DAELow.WhenEquation weqn;
    /* assignments1 assignments2 equation no. cg var_id cg var_id */
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,index,cg_id)
      equation
        e_1 = e - 1;
        DAELow.WHEN_EQUATION(whenEquation = weqn) = DAELow.equationNth(eqns, e_1); //TODO: elsewhen
        DAELow.WHEN_EQ(wc_ind,cr,expr,_) = buildWhenEquation1(weqn,index);
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        ((va as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = DAELow.vararrayNth(vararr, v_1);
        assignedVar = Exp.printComponentRefStr(cr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, expr, origname_str, cg_id);
        save_stmt = Util.stringAppendList({"save(",assignedVar,");\n"});
        cfn = Codegen.cPrependStatements(cfn, {save_stmt});
      then
        (cfn,cg_id_1);
     
    case (_,_,_,_,_,_,cg_id) then (Codegen.cEmptyFunction,cg_id);
  end matchcontinue;
end buildWhenEquation;

protected function buildWhenEquation1
"function: buildWhenEquation1
  Helper function to buildWhenEquation."
  input DAELow.WhenEquation inWEqn;
  input Integer inInteger;
  output DAELow.WhenEquation outWEqn;
algorithm
  outWEqn := matchcontinue (inWEqn,inInteger)
    local
      Integer wc_ind,index;
      DAELow.WhenEquation weqn,we,we1;
               
    case(weqn as DAELow.WHEN_EQ(index = wc_ind,elsewhenPart = NONE()),index)
      equation
        (index == wc_ind) = true;
      then
        weqn;  
    case(weqn as DAELow.WHEN_EQ(index = wc_ind,elsewhenPart = SOME(we)),index)
      equation
        (index == wc_ind) = true;
      then
        weqn;              
    case(weqn as DAELow.WHEN_EQ(index = wc_ind,elsewhenPart = SOME(we)),index)
      equation
        we1 = buildWhenEquation1(we,index);
      then
        we1;              
  end matchcontinue;
end buildWhenEquation1;

protected function generateComputeResidualState
"function: generateComputeResidualState
  This function generates the code for the calculation of the
  state variables on residual form. Called from generateSimulationCode."
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input list<list<Integer>> inIntegerLstLst6;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,inIntegerLstLst6)
    local
      Codegen.CFunction cfn1,cfn2,cfn;
      String res,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks;
    case (cname,dae,dlow,ass1,ass2,blocks) /* assignments1 assignments2 blocks */
      equation
        cfn1 = Codegen.cMakeFunction("int", "functionDAE_res", {},
          {"double *t","double *x","double *xd","double *delta",
          "fortran_integer *ires","double *rpar","fortran_integer* ipar"}) "build_residual_blocks(dae,dlow,ass1,ass2,blocks,0) => (cfn2,_) &" ;
        cfn2 = Codegen.cAddVariables(cfn1, {"int i;",
                                            "double temp_xd[NX];",
                                             "double* statesBackup;",
                                             "double* statesDerivativesBackup;",
                                             "double timeBackup;"
                                            });
        cfn = Codegen.cAddStatements(cfn2,
          {
            //"assert(localData);",
            "statesBackup = localData->states;",
            "statesDerivativesBackup = localData->statesDerivatives;",
            "timeBackup = localData->timeValue;",
            "localData->states = x;",
            "for (i=0; i<localData->nStates; i++) temp_xd[i]=localData->statesDerivatives[i];",
            "",
            "localData->statesDerivatives = temp_xd;",
            "localData->timeValue = *t;",
            "",
            "functionODE();",
            "/* get the difference between the temp_xd(=localData->statesDerivatives) and xd(=statesDerivativesBackup) */",
            "for (i=0; i < localData->nStates; i++) delta[i]=localData->statesDerivatives[i]-statesDerivativesBackup[i];",
            "",
            "localData->states = statesBackup;",
            "localData->statesDerivatives = statesDerivativesBackup;",
            "localData->timeValue = timeBackup;",
            "if (modelErrorCode) {",
            "  if (ires) *ires = -1;",
  					"  modelErrorCode =0;",
  					"}",
            "return 0;"});
            res = Codegen.cPrintFunctionsStr({cfn});
          then
            res;

    case (cname,dae,dlow,ass1,ass2,blocks)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_compute_residual_state"});
      then
        fail();
  end matchcontinue;
end generateComputeResidualState;

protected function generateComputeOutput
"function: generateComputeOutput
  This function generates the code for the
  calculation of the output variables and for asserts."
  input String inString1;
  input DAE.DAElist inDAElist2;
  input DAELow.DAELow inDAELow3;
  input Integer[:] inIntegerArray4;
  input Integer[:] inIntegerArray5;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrixT mT;
  input list<list<Integer>> inIntegerLstLst6;
  output String outString;
algorithm
  outString:=
  matchcontinue (inString1,inDAElist2,inDAELow3,inIntegerArray4,inIntegerArray5,m,mT,inIntegerLstLst6)
    local
      Codegen.CFunction cfunc_1,cfunc,cfunc1,cfunc2,body,cfunc_2,assertBody;
      list<CFunction> extra_funcs,extra_funcs1,extra_funcs2;
      list<String> stmts2;
      String coutput,cname;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<list<Integer>> blocks,blocks1,blocks2;
      Integer cg_id;
    case (cname,dae,dlow,ass1,ass2,m,mT,blocks)
      equation
        (blocks1,blocks2) = splitOutputBlocks(dlow,ass1,ass2,m,mT,blocks);

        /* Create output function + asserts */
        cfunc_1 = Codegen.cMakeFunction("int", "functionDAE_output", {}, {""});
        cfunc_1 = addMemoryManagement(cfunc_1);
        cfunc1 = Codegen.cAddCleanups(cfunc_1, {"return 0;"});
        (body,cg_id,extra_funcs1) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks1, 0);
        (assertBody,cg_id) = generateAlgorithmAsserts(dlow,cg_id);
        stmts2 = generateComputeRemovedEqns(dlow);
        cfunc_1 = Codegen.cMergeFns({cfunc1,body,assertBody});
        cfunc_1 = Codegen.cAddStatements(cfunc_1, stmts2);

        /* Create output2 function for discrete vars.*/
        cfunc_2 = Codegen.cMakeFunction("int", "functionDAE_output2", {}, {""});
        cfunc_2 = addMemoryManagement(cfunc_2);
        cfunc2 = Codegen.cAddCleanups(cfunc_2, {"return 0;"});
        (body,cg_id,extra_funcs2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks2, 0);
        stmts2 = generateComputeRemovedEqns(dlow);
        cfunc_2 = Codegen.cMergeFns({cfunc2,body});
        cfunc_2 = Codegen.cAddStatements(cfunc_2, stmts2);

        extra_funcs = listAppend(extra_funcs1,extra_funcs2);
        coutput = Codegen.cPrintFunctionsStr((listAppend(extra_funcs,{cfunc_1,cfunc_2})));
      then
        coutput;

    case (_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"generate_compute_output failed"});
      then
        fail();
  end matchcontinue;
end generateComputeOutput;

protected function splitOutputBlocks
"function splitOutputBlocks
  Help function to generateComputeOutput, splits the output blocks into two
  parts, one for continous output variables and one for discrete output values.
  This must be done to ensure that discrete variables are calculated before and
  after a discrete event."
  input DAELow.DAELow dlow;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrix mT;
  input list<list<Integer>> blocks;
  output list<list<Integer>> contBlocks;
  output list<list<Integer>> discBlocks;
algorithm
  (contBlocks,discBlocks) := matchcontinue(dlow,ass1,ass2,m,mT,blocks)
    local DAELow.Variables vars,vars2,knvars;
      list<DAELow.Var> varLst, varLstDiscrete;
      DAELow.EquationArray eqns;
    case (dlow as DAELow.DAELOW(orderedVars=vars,knownVars = knvars,orderedEqs=eqns),ass1,ass2,m,mT,blocks) equation
      varLst = DAELow.varList(vars);
      varLstDiscrete = Util.listSelect(varLst,DAELow.isVarDiscrete);
      vars2 = DAELow.listVar(varLstDiscrete);
      (contBlocks,discBlocks,_) = splitOutputBlocks2(vars2,vars,knvars,eqns,ass1,ass2,m,mT,blocks);
    then (contBlocks,discBlocks);
  end matchcontinue;
end splitOutputBlocks;

protected function splitOutputBlocks2
"Help function to splitOutputBlocks"
  input DAELow.Variables discVars;
  input DAELow.Variables vars;
  input DAELow.Variables knvars;
  input DAELow.EquationArray eqns;
  input Integer[:] ass1;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrix m;
  input DAELow.IncidenceMatrix mT;
  input list<list<Integer>> blocks;
  output list<list<Integer>> contBlocks;
  output list<list<Integer>> discBlocks;
  output DAELow.Variables discVars;
algorithm
  (contBlocks,discBlocks,discVars) := matchcontinue(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blocks)
    local list<Integer> blck;

    /* discrete block */
    case(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blck::blocks)
      equation
        discVars = blockSolvesDiscrete(discVars,vars,knvars,eqns,blck,ass2,mT);
        (contBlocks,discBlocks,discVars) = splitOutputBlocks2(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blocks);
      then (contBlocks,blck::discBlocks,discVars);

    /* continous block */
    case(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blck::blocks)
      equation
        (contBlocks,discBlocks,discVars) = splitOutputBlocks2(discVars,vars,knvars,eqns,ass1,ass2,m,mT,blocks);
      then (blck::contBlocks,discBlocks,discVars);

    case(discVars,vars,knvars,eqns,ass1,ass2,m,mT,{}) then ({},{},discVars);
  end matchcontinue;
end splitOutputBlocks2;

protected function blockSolvesDiscrete
"Help function to splitOutputBlocks
 succeds if the block solves for any discrete variable."
  input DAELow.Variables discVars;
  input DAELow.Variables vars;
  input DAELow.Variables knvars;
  input DAELow.EquationArray eqns;
  input list<Integer> blck;
  input Integer[:] ass2;
  input DAELow.IncidenceMatrixT mT;
  output DAELow.Variables outDiscVars;
algorithm
  outDiscVars := matchcontinue(discVars,vars,knvars,eqns,blck,ass2,mT)
    local list<DAELow.Equation> eqn_lst; list<DAELow.Var> var_lst;
      /* Solves a discrete variable, typically in when-clause */
    case(discVars,vars,knvars,eqns,blck,ass2,mT)
      equation
        (eqn_lst,var_lst) = Util.listMap32(blck, getEquationAndSolvedVar, eqns, vars, ass2);
        _::_ = Util.listSelect(var_lst,DAELow.isVarDiscrete);
        discVars = DAELow.addVars(var_lst,discVars);
      then discVars;

      /* Equation has variablity discrete time */
    case(discVars,vars,knvars,eqns,blck,ass2,mT) equation
      (eqn_lst,var_lst) = Util.listMap32(blck, getEquationAndSolvedVar, eqns, discVars, ass2);
      var_lst = Util.listMap1(var_lst,DAELow.setVarKind,DAELow.DISCRETE());
      discVars = DAELow.addVars(var_lst,discVars);
      _::_ = Util.listSelect2(eqn_lst,discVars,knvars,DAELow.isDiscreteEquation);
      discVars = DAELow.addVars(var_lst,discVars);
      then discVars;
  end matchcontinue;
end blockSolvesDiscrete;

protected function generateAlgorithmAsserts
"Generates assert statements from equations and algorithms into computeOutput function
 equation asserts are transformed to algorithm asserts, so this function goes through all
 algorithms and generate code for the asserts it finds (which are not part of 'complex' algorithm"
  input DAELow.DAELow dlow;
  input Integer cg_id;
  output Codegen.CFunction cfunc;
  output Integer outCg_id;
algorithm
	(cfunc,outCg_id) := matchcontinue(dlow,cg_id)
	  local Algorithm.Algorithm[:] algs;
	  case(DAELow.DAELOW(algorithms = algs),cg_id)
	    equation
	      (cfunc,cg_id) = generateAlgorithmAsserts2(arrayList(algs),cg_id);
	    then (cfunc,cg_id);
  end matchcontinue;
end generateAlgorithmAsserts;

protected function generateAlgorithmAsserts2
"Help function to generateAlgorithmAsserts"
  input list<Algorithm.Algorithm> algs;
  input Integer cg_id;
  output Codegen.CFunction cfunc;
  output Integer outCg_id;
algorithm
  (cfunc,outCg_id) := matchcontinue(algs,cg_id)
    local Codegen.CFunction cfunc1,cfunc2; Algorithm.Algorithm a;

    case ({},cg_id) then (Codegen.cEmptyFunction,cg_id);

    case((a as DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond =_)}))::algs,cg_id)
      equation
        (cfunc1,cg_id) = Codegen.generateAlgorithm(DAE.ALGORITHM(a,DAE.emptyElementSource),cg_id,Codegen.simContext);
        (cfunc2,cg_id) = generateAlgorithmAsserts2(algs,cg_id);
        cfunc = Codegen.cMergeFns({cfunc1,cfunc2});
      then (cfunc,cg_id);

    case(_::algs,cg_id)
      equation
        (cfunc,cg_id) = generateAlgorithmAsserts2(algs,cg_id);
      then (cfunc,cg_id);

  end matchcontinue;
end generateAlgorithmAsserts2;


protected function generateComputeRemovedEqns
"function: generateComputeRemovedEqns
  author: PA
  Generates compute code for the removed equations"
  input DAELow.DAELow inDAELow;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELow)
    local
      list<DAELow.Equation> eqn_lst;
      list<String> res;
      DAELow.EquationArray reqns;
    case (DAELow.DAELOW(removedEqs = reqns))
      equation
        eqn_lst = DAELow.equationList(reqns);
        res = generateComputeRemovedEqns2(eqn_lst);
      then
        res;
  end matchcontinue;
end generateComputeRemovedEqns;

protected function
generateComputeRemovedEqns2
"function: generateComputeRemovedEqns2
  Helper function to generateComputedRemoveEqns"
  input list<DAELow.Equation> inDAELowEquationLst;
  output list<String> outStringLst;
algorithm
  outStringLst:=
  matchcontinue (inDAELowEquationLst)
    local
      list<String> res;
      String cr_str,exp_str,s1;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      list<DAELow.Equation> rest;
    case ({}) then {};
    case ((DAELow.SOLVED_EQUATION(componentRef = cr,exp = exp) :: rest))
      equation
        res = generateComputeRemovedEqns2(rest);
        cr_str = Exp.printComponentRefStr(cr);
        exp_str = printExpCppStr(exp);
        s1 = Util.stringAppendList({cr_str," = ",exp_str,";"});
      then
        (s1 :: res);
  end matchcontinue;
end generateComputeRemovedEqns2;

protected function buildSolvedBlocks
"function: buildSolvedBlocks
  This function generates code for blocks on solved form, i.e.
  \\dot{x} = f(x,y,t)
  It is used for the generation of the output function. If event code
  is generated, it does not include discrete equations in the output code."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<list<Integer>> inIntegerLstLst5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
  output list<CFunction> outCFunctionLst;
algorithm
  (outCFunction,outInteger,outCFunctionLst):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLstLst5,inInteger6)
    local
      Integer cg_id,cg_id_1,cg_id_2,eqn;
      Codegen.CFunction cfn1,cfn2,cfn,fcn1,fcn2,fcn;
      list<CFunction> f2,f1,f;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      Integer[:] ass1,ass2;
      list<Integer> block_;
      list<list<Integer>> blocks;

    /* assignments1 assignments2 list of blocks cg var_id cg var_id */
    case (_,_,_,_,{},cg_id) then (Codegen.cEmptyFunction,cg_id,{});

    case (dae,dlow,ass1,ass2,((block_ as {eqn}) :: blocks),cg_id)
      equation
        true = useZerocrossing() "for single equations" ;
        (cfn1,cg_id_1) = buildNonDiscreteEquation(dae, dlow, ass1, ass2, eqn, cg_id);
        (cfn2,cg_id_2,f2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks, cg_id_1);
        cfn = Codegen.cMergeFns({cfn1,cfn2});
      then
        (cfn,cg_id_2,f2);

    case (dae,dlow,ass1,ass2,((block_ as {eqn}) :: blocks),cg_id)
      equation
        false = useZerocrossing() "for single equations" ;
        (cfn1,cg_id_1) = buildEquation(dae, dlow, ass1, ass2, eqn, cg_id);
        (cfn2,cg_id_2,f2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks, cg_id_1);
        cfn = Codegen.cMergeFns({cfn1,cfn2});
      then
        (cfn,cg_id_2,f2);

    case (dae,dlow,ass1,ass2,(block_ :: blocks),cg_id)
      equation
        (fcn1,cg_id_1,f1) = generateOdeSystem(dae,false,dlow, ass1, ass2, block_, cg_id) "for blocks" ;
        (fcn2,cg_id_2,f2) = buildSolvedBlocks(dae, dlow, ass1, ass2, blocks, cg_id_1);
        fcn = Codegen.cMergeFns({fcn1,fcn2});
        f = listAppend(f1, f2);
      then
        (fcn,cg_id_2,f);

    case (_,_,_,_,_,_)
      equation
        print("-SimCodegen.buildSolvedBlocks failed\n");
      then
        fail();
  end matchcontinue;
end buildSolvedBlocks;

protected function buildBlock
"function: buildBlock
  This function returns the code string for solving a block
  of variables in the dae, i.e. a set of coupled equations.
  It is used both for state variables and algebraic variables."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<Integer> inIntegerLst5;
  output String outString;
algorithm
  outString := matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLst5)
    local
      Integer e_1,indx,e;
      list<DAE.Exp> inputs,outputs;
      Algorithm.Algorithm alg;
      list<String> stmt_strs;
      String res;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      Integer[:] ass1,as2,ass2;
      list<Integer> block_;
      DAE.ElementSource source "the origin of the element";

    /* assignments1 assignments2 block of equations */
    case (dae,(dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),ass1,as2,(block_ as (e :: _)))
      equation
        true = allSameAlgorithm(dlow, block_);
        e_1 = e - 1;
        DAELow.ALGORITHM(indx,inputs,outputs,source) = DAELow.equationNth(eqns, e_1);
        alg = alg[indx + 1];
        (Codegen.CFUNCTION(_,_,_,_,_,_,stmt_strs,_),_) = Codegen.generateAlgorithm(DAE.ALGORITHM(alg,source), 1, Codegen.simContext);
        res = Util.stringDelimitList(stmt_strs, "\n");
      then
        res;

    case (dae,dlow,ass1,ass2,block_)
      equation
        print("#Solving of equation systems not implemented yet.\n");
      then
        fail();
  end matchcontinue;
end buildBlock;

protected function allSameAlgorithm
"function: allSameAlgorithm
  Checks that a block consists only of one algorithm in different -nodes-"
  input DAELow.DAELow inDAELow;
  input list<Integer> inIntegerLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inIntegerLst)
    local
      Integer e_1,indx,e;
      Boolean res;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      Algorithm.Algorithm[:] alg;
      list<Integer> block_;
    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),(block_ as (e :: _))) /* blocks */
      equation
        e_1 = e - 1 "extract index of first algorithm and check that entire block has that index." ;
        DAELow.ALGORITHM(indx,_,_,_) = DAELow.equationNth(eqns, e_1);
        res = allSameAlgorithm2(dlow, block_, indx);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end allSameAlgorithm;

protected function allSameAlgorithm2
"function: allSameAlgorithm2
  Helper function to all_same_algorithm. Checks all equations in the
  block and returns true if they all are algorithms with the same index."
  input DAELow.DAELow inDAELow;
  input list<Integer> inIntegerLst;
  input Integer inInteger;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inIntegerLst,inInteger)
    local
      Integer e_1,indx2,e,indx;
      Boolean b1;
      DAELow.DAELow dlow;
      DAELow.EquationArray eqns;
      Algorithm.Algorithm[:] alg;
      list<Integer> es;
      DAE.ElementSource source "the origin of the element";

    case (_,{},_) then true;  /* block alg. index */

    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),(e :: es),indx)
      equation
        e_1 = e - 1;
        DAELow.ALGORITHM(indx2,_,_,_) = DAELow.equationNth(eqns, e_1);
        (indx == indx2) = true;
        b1 = allSameAlgorithm2(dlow, es, indx);
      then
        b1;

    case ((dlow as DAELow.DAELOW(orderedEqs = eqns,algorithms = alg)),(e :: es),indx)
      equation
        e_1 = e - 1;
        DAELow.ALGORITHM(indx2,_,_,_) = DAELow.equationNth(eqns, e_1);
        (indx == indx2) = false;
      then
        false;

    case (_,_,_) then false;
  end matchcontinue;
end allSameAlgorithm2;

protected function buildNonDiscreteEquation
"function: buildNonDiscreteEquation
  Builds code for non_discrete equations only.
  Used in build_solved_blocks."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6)
    local
      Integer e_1,v_1,e,cg_id,cg_id_1,eqn;
      DAELow.Var v;
      DAELow.VariableArray vararr;
      Integer[:] ass2,ass1;
      Codegen.CFunction cfunc;
      DAE.DAElist dae;
      DAELow.DAELow dlow;
      list<Integer> zcEqns;

    // Discrete equations that exists in ZeroCrossings are skipped.
    case (_,dlow as DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr)),_,ass2,e,cg_id) /* cg var_id cg var_id */
      equation
        e_1 = e - 1;
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        (v) = DAELow.vararrayNth(vararr, v_1);
        true = hasDiscreteVar({v});
        zcEqns = DAELow.zeroCrossingsEquations(dlow);
        true = listMember(e,zcEqns);
      then
        (Codegen.cEmptyFunction,cg_id);

    case (dae,dlow,ass1,ass2,eqn,cg_id)
      equation
        (cfunc,cg_id_1) = buildEquation(dae, dlow, ass1, ass2, eqn, cg_id);
      then
        (cfunc,cg_id_1);
  end matchcontinue;
end buildNonDiscreteEquation;

protected function buildEquation
"function buildEquation
  This returns the code string for a specific equation in the dae.
  It is used both for state variables and regular variables."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger) := matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6)
    local
      Integer e_1,v,v_1,cg_id_1,e,cg_id,indx;
      DAE.Exp e1,e2,varexp,expr,simplify_exp,new_varexp;
      DAELow.Var va;
      DAE.ComponentRef cr,origname;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String origname_str;
      Codegen.CFunction cfn;
      DAE.DAElist dae;
      DAELow.VariableArray vararr;
      DAELow.EquationArray eqns;
      Integer[:] ass1,ass2;
      list<DAE.Exp> inputs,outputs;
      Algorithm.Algorithm alg;
      Algorithm.Algorithm[:] algs;
      DAE.ElementSource source "the origin of the element";

    /* assignments1 assignments2 equation no cg var_id cg var_id */
    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        e_1 = e - 1 "Solving for non-states" ;
        DAELow.EQUATION(e1,e2,_) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        ((va as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = DAELow.vararrayNth(vararr, v_1);
        true = DAELow.isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, varexp);
        simplify_exp = Exp.simplify(expr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);

    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      equation
        e_1 = e - 1 "Solving the state s means solving for der(s)" ;
        DAELow.EQUATION(e1,e2,_) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v == variable no solved in this equation" ;
        DAELow.VAR(cr,kind,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        new_varexp = DAE.CREF(cr,DAE.ET_REAL());
        expr = Exp.solve(e1, e2, new_varexp);
        simplify_exp = Exp.simplify(expr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);

    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local
        String s1,s2;
      equation
        e_1 = e - 1 "probably, solved failed in rule above. This means that we have a non-linear equation." ;
        DAELow.EQUATION(e1,e2,_) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v==variable no solved in this equation" ;
        DAELow.VAR(cr,_,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        print("nonlinear equation not implemented yet\n");
        s1 = Exp.printExpStr(e1);
        s2 = Exp.printExpStr(e2);
        print(Util.stringAppendList({s1," = ", s2, "\n\n"}));
      then
        fail();

    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns,algorithms = algs),ass1,ass2,e,cg_id)
      equation
        e_1 = e - 1 "Algorithms Each algorithm should only be genated once." ;
        DAELow.ALGORITHM(indx,inputs,outputs,source) = DAELow.equationNth(eqns, e_1);
        alg = algs[indx + 1];
        (cfn,cg_id_1) = Codegen.generateAlgorithm(DAE.ALGORITHM(alg,source), cg_id, Codegen.simContext);
      then
        (cfn,cg_id_1);

    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- SimCodegen.buildEquation failed\n");
      then
        fail();
  end matchcontinue;
end buildEquation;

protected function buildResidualBlocks
"function: buildResidualBlocks
  This function generates code for blocks on residual form, i.e.
  g(\\dot{x},x,y,t) = 0"
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input list<list<Integer>> inIntegerLstLst5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger):=
  matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inIntegerLstLst5,inInteger6)
    case (_,_,_,_,_,_) /* ass1 ass2 blocks cg var_iter cg var_iter */
      equation
        print("-SimCodegen.buildResidualBlocks failed\n");
      then
        fail();
  end matchcontinue;
end buildResidualBlocks;

protected function buildResidualEquation
"function buildResidualEquation
  This function generates code on residual form for one equation.
  It is used both for state variables and algebraic variables."
  input DAE.DAElist inDAElist1;
  input DAELow.DAELow inDAELow2;
  input Integer[:] inIntegerArray3;
  input Integer[:] inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger) := matchcontinue (inDAElist1,inDAELow2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6)
    local
      Integer e_1,v_1,e,cg_id,cg_id_1,indx;
      DAELow.Var v,va;
      DAELow.VariableArray vararr;
      Integer[:] ass2,ass1;
      DAE.Exp e1,e2,varexp,expr,simplify_exp,exp;
      DAE.ComponentRef cr,origname,new_cr;
      DAELow.VarKind kind;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      String origname_str,indx_str,cr_str;
      Codegen.CFunction cfn;
      DAE.DAElist dae;
      DAELow.EquationArray eqns;

    /* assignments1 assignments2 equation no. cg var_id cg var_id */
    case (_,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr)),_,ass2,e,cg_id)
      equation
        e_1 = e - 1 "Do not output equations for discrete variables here" ;
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        (v) = DAELow.vararrayNth(vararr, v_1);
        true = hasDiscreteVar({v});
      then
        (Codegen.cEmptyFunction,cg_id);

    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local Integer v;
      equation
        e_1 = e - 1 "Solving for non-states" ;
        DAELow.EQUATION(e1,e2,_) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        ((va as DAELow.VAR(cr,kind,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix))) = DAELow.vararrayNth(vararr, v_1);
        true = DAELow.isNonState(kind);
        varexp = DAE.CREF(cr,DAE.ET_REAL()) "print \"Solving for non-states\\n\" &" ;
        expr = Exp.solve(e1, e2, varexp);
        simplify_exp = Exp.simplify(expr);
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);

    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local Integer v;
      equation
        e_1 = e - 1 "Solving the state s, caluate residual form." ;
        DAELow.EQUATION(e1,e2,_) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1;
        DAELow.VAR(cr,kind,_,_,_,_,_,indx,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        indx_str = intString(indx);
        exp = DAE.BINARY(e1,DAE.SUB(DAE.ET_REAL()),e2);
        simplify_exp = Exp.simplify(exp);
        cr_str = Util.stringAppendList({"delta[",indx_str,"]"}) "Use array named \'delta\' for residuals" ;
        new_cr = DAE.CREF_IDENT(cr_str,DAE.ET_REAL(),{});
        origname_str = Exp.printComponentRefStr(origname);
        (cfn,cg_id_1) = buildAssignment(dae, new_cr, simplify_exp, origname_str, cg_id);
      then
        (cfn,cg_id_1);

    case (_,DAELow.DAELOW(orderedEqs = eqns),_,_,e,cg_id)
      local DAELow.WhenEquation e;
      equation
        e_1 = e - 1 "when-equations are not part of the residual equations" ;
        DAELow.WHEN_EQUATION(e,_) = DAELow.equationNth(eqns, e_1);
      then
        (Codegen.cEmptyFunction,cg_id);

    case (dae,DAELow.DAELOW(orderedVars = DAELow.VARIABLES(varArr = vararr),orderedEqs = eqns),ass1,ass2,e,cg_id)
      local Integer v;
      equation
        e_1 = e - 1;
        DAELow.EQUATION(e1,e2,_) = DAELow.equationNth(eqns, e_1);
        v = ass2[e_1 + 1];
        v_1 = v - 1 "v==variable no solved in this equation" ;
        DAELow.VAR(cr,_,_,_,_,_,_,_,origname,_,dae_var_attr,comment,flowPrefix,streamPrefix) = DAELow.vararrayNth(vararr, v_1);
        varexp = DAE.CREF(cr,DAE.ET_REAL());
        failure(_ = Exp.solve(e1, e2, varexp));
        print("nonlinear equation not implemented yet\n");
      then
        fail();

    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- SimCodegen.buildResidualEquation failed\n");
      then
        fail();
  end matchcontinue;
end buildResidualEquation;

protected function buildAssignment
"function buildAssignment
  This function takes a ComponentRef(cr) and an expression(exp)
  and makes a C++ assignment: cr = exp;"
  input DAE.DAElist inDAElist;
  input DAE.ComponentRef inComponentRef;
  input DAE.Exp inExp;
  input String inString;
  input Integer inInteger;
  output CFunction outCFunction;
  output Integer outInteger;
algorithm
  (outCFunction,outInteger) := matchcontinue (inDAElist,inComponentRef,inExp,inString,inInteger)
    local
      String cr_str,var,stmt,origname;
      Codegen.CFunction cfn;
      Integer cg_id_1,cg_id;
      DAE.DAElist dae;
      list<DAE.Element> elements;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      Absyn.Path path;
      list<DAE.Exp> args;
      Boolean tuple_,builtin;
    case ((dae as DAE.DAE(elementLst = elements)),cr,(exp as DAE.CALL(path = path,expLst = args,tuple_ = (tuple_ as false),builtin = builtin)),origname,cg_id) /* varname expression orig. name cg var_id cg var_id */
      equation
        cr_str = Exp.printComponentRefStr(cr);
        (cfn,var,cg_id_1) = Codegen.generateExpression(exp, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        cfn = Codegen.cAddStatements(cfn, {stmt});
      then
        (cfn,cg_id_1);
    case (dae,cr,(exp as DAE.CALL(path = path,expLst = args,tuple_ = (tuple_ as true),builtin = builtin)),origname,cg_id)
      equation
        print("-simcodegen: build_assignment: Tuple return values from functions not implemented\n");
      then
        fail();
    case (dae,cr,exp,origname,cg_id)
      equation
        cr_str = Exp.printComponentRefStr(cr);
        (cfn,var,cg_id_1) = Codegen.generateExpression(exp, cg_id, Codegen.simContext);
        stmt = Util.stringAppendList({cr_str," = ",var,";"});
        cfn = Codegen.cAddStatements(cfn, {stmt});
      then
        (cfn,cg_id_1);
    case (dae,cr,exp,origname,cg_id)
      equation
        print("-build_assignment failed\n");
      then
        fail();
  end matchcontinue;
end buildAssignment;

public function printExpCppStr "function: printExpCppStr

  This function prints a complete expression on a C/C++ format.
"
  input DAE.Exp e;
  output String s;
algorithm
  s := printExp2Str(e, 0);
end printExpCppStr;

protected function lbinopSymbol "function: lbinopSymbol

  Helper function to print_exp2_str
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.AND()) then " && ";
    case (DAE.OR()) then " || ";
  end matchcontinue;
end lbinopSymbol;

protected function lunaryopSymbol "function: lunaryopSymbol

  Helper function to print_exp2_str
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.NOT()) then " !";
  end matchcontinue;
end lunaryopSymbol;

protected function relopSymbol "function: relopSymbol

  Helper function to print_exp2_str
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  matchcontinue (inOperator)
    case (DAE.LESS(ty = _)) then " < ";
    case (DAE.LESSEQ(ty = _)) then " <= ";
    case (DAE.GREATER(ty = _)) then " > ";
    case (DAE.GREATEREQ(ty = _)) then " >= ";
    case (DAE.EQUAL(ty = _)) then " == ";
    case (DAE.NEQUAL(ty = _)) then " != ";
  end matchcontinue;
end relopSymbol;

public function defineStringToModelicaString
"function defineStringToModelicaString
  removes the $... from the string and replace the DAELow.derivative_name_prefix to \"der\"
  removes the \"\"\" and replaces with \"\"\" (in case of nestled divisions)
  author x02lucpo"
  input String part_eqn;
  output String part_eqn_1;
  String part_eqn0,part_eqn1,part_eqn2,part_eqn3,part_eqn4,part_eqn_1;
algorithm
  part_eqn0 := Util.cStrToModelicaString(part_eqn);
  part_eqn1 := System.stringReplace(part_eqn0, "\"", "") "replace \"\"\" with \"\"" ;
  part_eqn2 := System.stringReplace(part_eqn1, DAELow.derivativeNamePrefix, "der") "replace derivative prefix with der" ;
  part_eqn3 := System.stringReplace(part_eqn2, "$$", "##") "replace $$ with ##. this is to be able to replace $ with \"\" there are som variables that have the name $$dummy" ;
  part_eqn4 := System.stringReplace(part_eqn3, "$", "");
  part_eqn_1 := System.stringReplace(part_eqn4, "##", "$") "replace back ## with $." ;
end defineStringToModelicaString;

protected function generateDivisionMacro
"function generateDivisionMacro
  this generates a division macro of the form:
  \"DIVISION(1.0,a$P$bc,\"1.0/a.bc\")\"
  author x02lucpo"
  input String s1;
  input String s2;
  output String res;
  String part_eqn,part_eqn_1;
algorithm
  part_eqn := Util.stringAppendList({s1,"/",s2});
  part_eqn_1 := defineStringToModelicaString(part_eqn) "print \"befor: \" & print part_eqn & print \"\\n\" &" ;
  res := Util.stringAppendList({"DIVISION(",s1,",",s2,",\"",part_eqn_1,"\")"}) "print \"after: \" & print part_eqn\' & print \"\\n\" &" ;
end generateDivisionMacro;

protected function printExp2Str
"function: printExp2Str
  Helper function to printExpStr"
  input DAE.Exp inExp;
  input Integer inInteger;
  output String outString;
algorithm
  outString:=
  matchcontinue (inExp,inInteger)
    local
      String s,s_1,s_2,res,sym,s1,s2,s3,s4,s_3,res_1,ifstr,thenstr,elsestr,s_4,slast,argstr,fs,s5,s_5,res2,crstr,dimstr,str,expstr,iterstr,id;
      Integer x,pri2_1,pri2,pri3,pri1,ival;
      Real two_1,two,rval;
      DAE.ComponentRef c;
      DAE.Exp e1,e2,e21,e22,e,t,f,start,stop,step,cr,dim,exp,iterexp;
      DAE.Operator op;
      DAE.ExpType ty,ty2,REAL;
      list<DAE.Exp> args,es,sub;
      Boolean builtin;
      Absyn.Path fcn;
      list<DAE.ComponentRef> cref_list;

    case (DAE.END(),_)
      equation
        print("# equation contain undefined symbols");
      then
        fail();

    case (DAE.ICONST(integer = x),_)
      equation
        s = intString(x);
      then
        s;

    case (DAE.RCONST(real = x),_)
      local Real x;
      equation
        s = realString(x);
      then
        s;

    case (DAE.SCONST(string = s),_)
      equation
        s = Util.escapeModelicaStringToCString(s);
        s_1 = stringAppend("\"", s);
        s_2 = stringAppend(s_1, "\"");
      then
        s_2;

    case (DAE.BCONST(bool = false),_) then "false";

    case (DAE.BCONST(bool = true),_) then "true";

    case (DAE.CREF(DAE.CREF_IDENT(_,DAE.ET_ENUMERATION(SOME(idx),_,_,_),_),_),_)
      local Integer idx;
        then intString(idx);
    case (DAE.CREF(DAE.CREF_QUAL(_,ty as DAE.ET_ENUMERATION(_,_,_,_),_,c),_),pri1)
      equation
        res = printExp2Str(DAE.CREF(c, ty),pri1);
      then
        res;
    case (DAE.CREF(DAE.CREF_QUAL(_,ty as DAE.ET_COMPLEX(_,_,_),_,c),_),pri1)
      equation
        res = printExp2Str(DAE.CREF(c, ty),pri1);
      then
        res;

    case (DAE.CREF(componentRef = c),_)
      equation
        res = Exp.printComponentRefStr(c);
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = ty)),exp2 = (e2 as DAE.BINARY(exp1 = e21,operator = DAE.SUB(ty = ty2),exp2 = e22))),pri1)
      equation
        sym = Exp.binopSymbol(op);
        pri2_1 = Exp.binopPriority(op);
        pri2 = pri2_1 + 1;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2) "binary minus have higher priority than itself" ;
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.POW(ty = _)),exp2 = DAE.ICONST(integer = 2)),pri1)
      equation
        pri2 = Exp.binopPriority(op) "x^2 => xx" ;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s4 = Exp.printRightparStr(pri1, pri2);
        res = Util.stringAppendList({s1,s2,"*",s2,s4});
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.POW(ty = _)),exp2 = DAE.RCONST(real = two)),pri1)
      equation
        two_1 = intReal(2) "x^2 => xx" ;
        (two ==. two) = true;
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s4 = Exp.printRightparStr(pri1, pri2);
        res = Util.stringAppendList({s1, s2, " * ", s2, s4});
      then
        res;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.POW(ty = _)),exp2 = e2),pri1)
      equation
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend("pow(", s);
        s_2 = stringAppend(s_1, ", ");
        s_3 = stringAppend(s_2, s3);
        res = stringAppend(s_3, ")");
        res_1 = stringAppend(res, s4);
      then
        res_1;

    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.DIV(ty = _)),exp2 = e2),pri1)
      equation
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        res_1 = generateDivisionMacro(s2, s3) "	 string_append (\"DIVISION(\", s2) => s & string_append(s1,s) => s\' & string_append(s\',\",\") => s\'\' & string_append(s\'\',s3) => s\'\'\' & string_append(s\'\'\',\")\") => res & 	 string_append (res, s4) => res\'" ;
      then
        res_1;

    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = Exp.binopSymbol(op);
        pri2 = Exp.binopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.UNARY(operator = op,exp = e),pri1)
      equation
        sym = Exp.unaryopSymbol(op);
        pri2 = Exp.unaryopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, sym);
        s_1 = stringAppend(s, s2);
        s_2 = stringAppend(s_1, s3);
      then
        s_2;

    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = lbinopSymbol(op);
        pri2 = Exp.lbinopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.LUNARY(operator = op,exp = e),pri1)
      equation
        sym = lunaryopSymbol(op);
        pri2 = Exp.lunaryopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, sym);
        s_1 = stringAppend(s, s2);
        s_2 = stringAppend(s_1, s3);
      then
        s_2;

    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),pri1)
      equation
        sym = relopSymbol(op);
        pri2 = Exp.relopPriority(op);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e1, pri3);
        s3 = printExp2Str(e2, pri2);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, sym);
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f),_)
      local DAE.Exp c;
      equation
        ifstr = printExp2Str(c, 0);
        thenstr = printExp2Str(t, 0);
        elsestr = printExp2Str(f, 0);
        s = stringAppend("(( ", ifstr);
        s_1 = stringAppend(s, " ) ? ( ");
        s_2 = stringAppend(s_1, thenstr);
        s_3 = stringAppend(s_2, " ) : ( ");
        s_4 = stringAppend(s_3, elsestr);
        slast = stringAppend(s_4, " )) ");
      then
        slast;

    case (DAE.CALL(path = Absyn.IDENT(name = "abs"),expLst = args,builtin = (builtin as true)),_) /* abs using the fabs libc function */
      equation
        argstr = Exp.printListStr(args, printExpCppStr, ",");
        s = Util.stringAppendList({"fabs(",argstr,")"});
      then
        s;

    case (DAE.CALL(path = fcn,expLst = args,builtin = (builtin as true)),_)
      equation
        fs = ModUtil.pathStringReplaceDot(fcn, "_");
        argstr = Exp.printListStr(args, printExpCppStr, ",");
        s = Util.stringAppendList({fs,"(",argstr,")"});
      then
        s;

    case (DAE.CALL(path = fcn,expLst = args,builtin = (builtin as false)),_) /* user defined Modelica functions, incl. external starts with an
	   underscore, to distringuish betweeen the lib function for external
	   functions and the wrapper function. */
      equation
        fs = ModUtil.pathStringReplaceDot(fcn, "_");
        argstr = Exp.printListStr(args, printExpCppStr, ",");
        s = Util.stringAppendList({"_",fs,"(",argstr,").",fs,"_rettype_1"});
      then
        s;

    case (DAE.ARRAY(array = es),_)
      equation
        s = Exp.printListStr(es, printExpCppStr, ",");
        s_1 = stringAppend("{", s);
        s_2 = stringAppend(s_1, "}");
      then
        s_2;

    case (DAE.TUPLE(PR = es),_)
      equation
        s = Exp.printListStr(es, printExpCppStr, ",");
        s_1 = stringAppend("(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case (DAE.MATRIX(scalar = es),_)
      local list<list<tuple<DAE.Exp, Boolean>>> es;
      equation
        s = Exp.printListStr(es, Exp.printRowStr, "},{");
        s_1 = stringAppend("{{", s);
        s_2 = stringAppend(s_1, "}}");
      then
        s_2;

    case (DAE.RANGE(exp = start,expOption = NONE,range = stop),pri1)
      equation
        pri2 = 41;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(start, pri3);
        s3 = printExp2Str(stop, pri3);
        s4 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, ":");
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, s4);
      then
        s_3;

    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop),pri1)
      equation
        pri2 = 41;
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(start, pri3);
        s3 = printExp2Str(step, pri3);
        s4 = printExp2Str(stop, pri3);
        s5 = Exp.printRightparStr(pri1, pri2);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, ":");
        s_2 = stringAppend(s_1, s3);
        s_3 = stringAppend(s_2, ":");
        s_4 = stringAppend(s_3, s4);
        s_5 = stringAppend(s_4, s5);
      then
        s_5;

    case (DAE.CAST(ty = REAL,exp = DAE.ICONST(integer = ival)),_)
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
      then
        res;

    case (DAE.CAST(ty = REAL,exp = DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = DAE.ICONST(integer = ival))),_)
      equation
        false = RTOpts.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        res2 = stringAppend("-", res);
      then
        res2;

    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e),_)
      equation
        false = RTOpts.modelicaOutput();
        s = printExpCppStr(e);
        s_1 = stringAppend("(double)(", s);
        s_2 = stringAppend(s_1, ")");
      then
        s_2;

    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e),_)
      equation
        true = RTOpts.modelicaOutput();
        s = printExpCppStr(e);
      then
        s;

    case (DAE.ASUB(exp = e,sub = {e1}),pri1)
      equation
        pri2 = 51;
        cref_list = Exp.getCrefFromExp(e);
        (s1,pri3) = Exp.printLeftparStr(pri1, pri2);
        s2 = printExp2Str(e, pri3);
        s3 = Exp.printRightparStr(pri1, pri2);
        s4 = printExp2Str(e1, pri1);
        s = stringAppend(s1, s2);
        s_1 = stringAppend(s, s3);
        s_2 = stringAppend(s_1, "[");
        s_3 = stringAppend(s_2, s4);
        s_4 = stringAppend(s_3, "]");
      then
        s_4;

    case (DAE.SIZE(exp = cr,sz = SOME(dim)),_)
      equation
        crstr = printExpCppStr(cr);
        dimstr = printExpCppStr(dim);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;

    case (DAE.SIZE(exp = cr,sz = NONE),_)
      equation
        crstr = printExpCppStr(cr);
        str = Util.stringAppendList({"size(",crstr,")"});
      then
        str;

    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp),_)
      equation
        fs = Absyn.pathString(fcn);
        expstr = printExpCppStr(exp);
        iterstr = printExpCppStr(iterexp);
        str = Util.stringAppendList({"<reduction>",fs,"(",expstr," for ",id," in ",iterstr,")"});
      then
        str;

    case (_,_) then "#UNKNOWN EXPRESSION# ----eee ";
  end matchcontinue;
end printExp2Str;

public function crefModelicaStr "function: crefModelicaStr
  Converts DAE.ComponentRef, i.e. variables, to Modelica friendly variables.
  This means that dots are converted to underscore, etc."
  input DAE.ComponentRef inComponentRef;
  output String outString;
algorithm
  outString := matchcontinue (inComponentRef)
    local
      String res_1,res_2,res_3,s,ns,ss;
      DAE.ComponentRef n;
    case (DAE.CREF_IDENT(ident = s))
      equation
        res_1 = Util.stringReplaceChar(s, ".", "_");
        res_2 = Util.stringReplaceChar(res_1, "[", "_");
        res_3 = Util.stringReplaceChar(res_2, "]", "_") "& Util.string_append_list({\"_\",res,\"_\"}) => res\'" ;
      then
        res_3;
    case (DAE.CREF_QUAL(ident = s,componentRef = n))
      equation
        ns = crefModelicaStr(n);
        ss = stringAppend(s, ns) "	string_append(s,\"_\") => s1 & s1" ;
      then
        ss;
  end matchcontinue;
end crefModelicaStr;

// For compiling function references - stefan
protected function getReferencedFunctions
"function getReferencedFunctions
	Goes through the DAELow structure, finds all function
	references and returns them in a list. Removes duplicates."
	input DAE.DAElist dae;
	input DAELow.DAELow dlow;
	output list<Absyn.Path> res;
	list<DAE.Exp> explist, fnrefs;
	list<Absyn.ComponentRef> crefs;
	list<Absyn.Path> referencedFuncs;
algorithm
  explist := DAELow.getAllExps(dlow);
  fnrefs := Codegen.getMatchingExpsList(explist, Codegen.matchFnRefs);
  crefs := Util.listMap(fnrefs, getCrefFromExp);
  referencedFuncs := Util.listMap(crefs, Absyn.crefToPath);
  res := removeDuplicatePaths(referencedFuncs);
end getReferencedFunctions;

// For compiling function references - stefan
protected function getCrefFromExp
"function getCrefFromExp
  Assume input Exp is CREF, return the ComponentRef
  fail otherwise"
  input DAE.Exp e;
  output Absyn.ComponentRef c;
algorithm
  c :=
  matchcontinue(e)
    local
      DAE.ComponentRef crefe;
      Absyn.ComponentRef crefa;
    case(DAE.CREF(componentRef = crefe))
      equation
        crefa = Exp.unelabCref(crefe);
      then
        crefa;
    case(e)
      equation
        print("SimCodegen.getCrefFromExp failed: input was not of DAE.CREF type");
      then
        fail();
  end matchcontinue;
end getCrefFromExp;

public function getCalledFunctions
"function: getCalledFunctions
  Goes through the DAELow structure, finds all function
  calls and returns them in a list. Removes duplicates."
  input DAE.DAElist dae;
  input DAELow.DAELow dlow;
  output list<Absyn.Path> res;
  list<DAE.Exp> explist,fcallexps,fcallexps_1,fcallexps_2;
  list<Absyn.Path> calledfuncs;
algorithm
  explist := DAELow.getAllExps(dlow);
  fcallexps := Codegen.getMatchingExpsList(explist, Codegen.matchCalls);
  fcallexps_1 := Util.listSelect(fcallexps, isNotBuiltinCall);
  fcallexps_2 := Codegen.getMatchingExpsList(explist, Codegen.matchFnRefs);
  calledfuncs := Util.listMap(listAppend(fcallexps_1,fcallexps_2), getCallPath);
  res := removeDuplicatePaths(calledfuncs);
end getCalledFunctions;

public function getCalledFunctionsInFunctions
"function: getCalledFunctionsInFunctions
  Goes through the given DAE, finds the given functions and collects
  the names of the functions called from within those functions"
  input list<Absyn.Path> paths;
  input list<Absyn.Path> accumulated;
  input DAE.DAElist dae;
  output list<Absyn.Path> res;
  list<list<Absyn.Path>> pathslist;
algorithm
  res := matchcontinue(paths,accumulated,dae)
    local
      list<Absyn.Path> res,acc,rest;
      Absyn.Path path;
    case ({},accumulated,dae) then accumulated;
    case (path::rest,accumulated,dae)
      equation
        acc = getCalledFunctionsInFunction(path, accumulated, dae);
        res = getCalledFunctionsInFunctions(rest, acc, dae);
      then res;
  end matchcontinue;
end getCalledFunctionsInFunctions;

public function getCalledFunctionsInFunction
"function: getCalledFunctionsInFunction
  Goes through the given DAE, finds the given function and collects
  the names of the functions called from within those functions"
  input Absyn.Path inPath;
  input list<Absyn.Path> accumulated;
  input DAE.DAElist inDAElist;
  output list<Absyn.Path> outAbsynPathLst;
algorithm
  outAbsynPathLst:=
  matchcontinue (inPath,accumulated,inDAElist)
    local
      String pathstr,debugpathstr;
      Absyn.Path path;
      list<DAE.Element> elements,funcelems;
      list<DAE.Exp> explist,fcallexps,fcallexps_1,fcallexps_2,fnrefs;
      list<Absyn.ComponentRef> crefs;
      list<Absyn.Path> calledfuncs,res1,res2,res,acc;
      list<String> debugpathstrs;
      DAE.DAElist dae;

    case (path,acc,DAE.DAE(elementLst = elements)) /* Don\'t fail here, ceval will generate the function later */
      equation
        {} = DAEUtil.getNamedFunction(path, elements);
        pathstr = Absyn.pathString(path);
        //Error.addMessage(Error.LOOKUP_ERROR, {pathstr,"global scope"});
				Debug.fprintln("failtrace", "SimCodegen.getCalledFunctionsInFunction: Class "
					+& pathstr +& " not found in global scope.");
      then
        path::acc;

    case (path,acc,(dae as DAE.DAE(elementLst = elements)))
      local
        list<DAE.Element> varlist;
        list<list<DAE.Element>> varlistlist;
        list<Absyn.Path> varfuncs, fnpaths, fns, referencedFuncs, reffuncs;
      equation
        false = listMember(path,acc);
        funcelems = DAEUtil.getNamedFunction(path, elements);
        explist = DAEUtil.getAllExps(funcelems);
        fcallexps = Codegen.getMatchingExpsList(explist, Codegen.matchCalls);
        fcallexps_1 = Util.listSelect(fcallexps, isNotBuiltinCall);
        calledfuncs = Util.listMap(fcallexps_1, getCallPath);

        /*-- MetaModelica Partial Function. sjoelund --*/

        // stefan - get all arguments of constant T_FUNCTION type and add to list
        fnrefs = Codegen.getMatchingExpsList(explist, Codegen.matchFnRefs);
        crefs = Util.listMap(fnrefs, getCrefFromExp);
        reffuncs = Util.listMap(crefs, Absyn.crefToPath);
        //fns = removeDuplicatePaths(fnpaths);
        calledfuncs = listAppend(reffuncs, calledfuncs);
        calledfuncs = removeDuplicatePaths(calledfuncs);

        varlistlist = Util.listMap(funcelems, getFunctionElementsList);
        varlist = Util.listFlatten(varlistlist);
        varlist = Util.listSelect(varlist, DAEUtil.isFunctionRefVar);
        varfuncs = Util.listMap(varlist, getFunctionRefVarPath);
        calledfuncs = Util.listSetDifference(calledfuncs, varfuncs) "Filter out function reference calls";
        /*--                                           --*/
        res = getCalledFunctionsInFunctions(calledfuncs, path::acc, dae);

        Debug.fprint("info", "Found variable function refs to ignore: ") "debug" ;
        debugpathstrs = Util.listMap(varfuncs, Absyn.pathString) "debug" ;
        debugpathstr = Util.stringDelimitList(debugpathstrs, ", ") "debug" ;
        Debug.fprintln("info", debugpathstr) "debug" ;
        Debug.fprint("info", "Found called functions: ") "debug" ;
        debugpathstrs = Util.listMap(res, Absyn.pathString) "debug" ;
        debugpathstr = Util.stringDelimitList(debugpathstrs, ", ") "debug" ;
        Debug.fprintln("info", debugpathstr) "debug" ;
      then
        res;

    case (path,acc,_)
      equation
        true = listMember(path,acc);
      then acc;

    case(_,_,_)
      equation
        Debug.fprint("failtrace", "SimCodegen.getCalledFunctionsInFunction failed\n");
      then fail();
  end matchcontinue;
end getCalledFunctionsInFunction;

protected function isNotBuiltinCall
"function: isNotBuiltinCall
  return true if the given DAE.CALL is a call but not
  to a builtin function. checks the builtin flag in DAE.CALL"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp)
    case DAE.CALL(builtin = true) then false;
    case DAE.CALL(builtin = false) then true;
    case _ then false;
  end matchcontinue;
end isNotBuiltinCall;

protected function getCallPath
"function: getCallPath
  Retrive the function name from a CALL expression."
  input DAE.Exp inExp;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inExp)
    local
      Absyn.Path path;
      DAE.ComponentRef cref;
    case DAE.CALL(path = path) then path;
    case DAE.CREF(componentRef = cref)
      equation
        path = Exp.crefToPath(cref);
      then
        path;
  end matchcontinue;
end getCallPath;

public function getFunctionRefVarPath
"function: getFunctionRefVarFunctionPath
  Retrive the function name from a function variable."
  input DAE.Element inElem;
  output Absyn.Path outPath;
algorithm
  outPath:=
  matchcontinue (inElem)
    local Absyn.Path path;
    case DAE.VAR(ty = ((DAE.T_FUNCTION(_,_,_)),SOME(path))) then path;
  end matchcontinue;
end getFunctionRefVarPath;

protected function getFunctionElementsList
"function: getFunctionElementsList
  Retrives the dAEList of function (or external function)"
  input DAE.Element inElem;
  output list<DAE.Element> out;
algorithm
  outPath:=
  matchcontinue (inElem)
    local Absyn.Path path;
    case DAE.FUNCTION(functions = {DAE.FUNCTION_DEF(body = out)}) then out;
    case DAE.FUNCTION(functions = {DAE.FUNCTION_EXT(body = out)}) then out;
    case DAE.RECORD_CONSTRUCTOR(path = _) then {};
  end matchcontinue;
end getFunctionElementsList;

protected function removeDuplicatePaths
"function: removeDuplicatePaths
  Removed duplicate Paths in a list of Path."
  input list<Absyn.Path> inAbsynPathLst;
  output list<Absyn.Path> outAbsynPathLst;
algorithm
  outAbsynPathLst:=
  matchcontinue (inAbsynPathLst)
    local
      list<Absyn.Path> restwithoutfirst,recresult,rest;
      Absyn.Path first;
    case {} then {};
    case (first :: rest)
      equation
        restwithoutfirst = removePathFromList(rest, first);
        recresult = removeDuplicatePaths(restwithoutfirst);
      then
        (first :: recresult);
  end matchcontinue;
end removeDuplicatePaths;

protected function removePathFromList
"function: removePathFromList
  Helper function to removeDuplicatePaths."
  input list<Absyn.Path> inAbsynPathLst;
  input Absyn.Path inPath;
  output list<Absyn.Path> outAbsynPathLst;
algorithm
  outAbsynPathLst:=
  matchcontinue (inAbsynPathLst,inPath)
    local
      list<Absyn.Path> res,rest;
      Absyn.Path first,path;
    case ({},_) then {};
    case ((first :: rest),path)
      equation
        true = ModUtil.pathEqual(first, path);
        res = removePathFromList(rest, path);
      then
        res;
    case ((first :: rest),path)
      equation
        false = ModUtil.pathEqual(first, path);
        res = removePathFromList(rest, path);
      then
        (first :: res);
  end matchcontinue;
end removePathFromList;

protected function useZerocrossing
  output Boolean res_1;
  Boolean res,res_1;
algorithm
  res := RTOpts.debugFlag("noevents");
  res_1 := boolNot(res);
end useZerocrossing;

protected function generateEquationOrder
  input list<list<Integer>> inIntegerLstLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inIntegerLstLst)
    local
      list<Integer> res,block_;
      list<list<Integer>> blocks;
      Integer eqn;
    case ({}) then {};
    case (((block_ as (_ :: (_ :: _))) :: blocks))
      equation
        res = generateEquationOrder(blocks) "For system of equations skip these" ;
      then
        res;
    case (((block_ as {eqn}) :: blocks))
      equation
        res = generateEquationOrder(blocks) "for single equations" ;
      then
        (eqn :: res);
    case (_)
      equation
        print("-SimCodegen.generateEquationOrder failed\n");
      then
        fail();
  end matchcontinue;
end generateEquationOrder;

end SimCodegen;

