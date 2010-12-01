package SimCodeC

public import Tpl;

public import SimCode;
public import BackendDAE;
public import System;
public import Absyn;
public import DAE;
public import ClassInf;
public import SCode;
public import Util;
public import ComponentReference;
public import Expression;
public import RTOpts;
public import Settings;

protected function fun_14
  input Tpl.Text in_txt;
  input Option<SimCode.SimulationSettings> in_a_simulationSettingsOpt;
  input String in_a_fileNamePrefix;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simulationSettingsOpt, in_a_fileNamePrefix, in_a_simCode)
    local
      Tpl.Text txt;
      String a_fileNamePrefix;
      SimCode.SimCode a_simCode;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           NONE(),
           _,
           _ )
      then txt;

    case ( txt,
           _,
           a_fileNamePrefix,
           a_simCode )
      equation
        txt_0 = simulationInitFile(Tpl.emptyTxt, a_simCode);
        txt_1 = Tpl.writeStr(Tpl.emptyTxt, a_fileNamePrefix);
        txt_1 = Tpl.writeTok(txt_1, Tpl.ST_STRING("_init.txt"));
        Tpl.textFile(txt_0, Tpl.textString(txt_1));
      then txt;
  end matchcontinue;
end fun_14;

public function translateModel
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode)
    local
      Tpl.Text txt;
      Option<SimCode.SimulationSettings> i_simulationSettingsOpt;
      list<SimCode.RecordDeclaration> i_recordDecls;
      list<String> i_externalFunctionIncludes;
      list<SimCode.Function> i_functions;
      String i_fileNamePrefix;
      SimCode.SimCode i_simCode;
      Tpl.Text txt_9;
      Tpl.Text txt_8;
      Tpl.Text txt_7;
      Tpl.Text txt_6;
      Tpl.Text txt_5;
      Tpl.Text txt_4;
      Tpl.Text txt_3;
      Tpl.Text txt_2;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(fileNamePrefix = i_fileNamePrefix, functions = i_functions, externalFunctionIncludes = i_externalFunctionIncludes, recordDecls = i_recordDecls, simulationSettingsOpt = i_simulationSettingsOpt)) )
      equation
        txt_0 = simulationFile(Tpl.emptyTxt, i_simCode);
        txt_1 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_1 = Tpl.writeTok(txt_1, Tpl.ST_STRING(".cpp"));
        Tpl.textFile(txt_0, Tpl.textString(txt_1));
        txt_2 = simulationFunctionsHeaderFile(Tpl.emptyTxt, i_fileNamePrefix, i_functions, i_externalFunctionIncludes, i_recordDecls);
        txt_3 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_3 = Tpl.writeTok(txt_3, Tpl.ST_STRING("_functions.h"));
        Tpl.textFile(txt_2, Tpl.textString(txt_3));
        txt_4 = simulationFunctionsFile(Tpl.emptyTxt, i_fileNamePrefix, i_functions);
        txt_5 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_5 = Tpl.writeTok(txt_5, Tpl.ST_STRING("_functions.cpp"));
        Tpl.textFile(txt_4, Tpl.textString(txt_5));
        txt_6 = recordsFile(Tpl.emptyTxt, i_fileNamePrefix, i_recordDecls);
        txt_7 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_7 = Tpl.writeTok(txt_7, Tpl.ST_STRING("_records.c"));
        Tpl.textFile(txt_6, Tpl.textString(txt_7));
        txt_8 = simulationMakefile(Tpl.emptyTxt, i_simCode);
        txt_9 = Tpl.writeStr(Tpl.emptyTxt, i_fileNamePrefix);
        txt_9 = Tpl.writeTok(txt_9, Tpl.ST_STRING(".makefile"));
        Tpl.textFile(txt_8, Tpl.textString(txt_9));
        txt = fun_14(txt, i_simulationSettingsOpt, i_fileNamePrefix, i_simCode);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateModel;

public function translateFunctions
  input Tpl.Text in_txt;
  input SimCode.FunctionCode in_a_functionCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_functionCode)
    local
      Tpl.Text txt;
      SimCode.FunctionCode i_functionCode;
      list<String> i_externalFunctionIncludes;
      list<SimCode.RecordDeclaration> i_extraRecordDecls;
      list<SimCode.Function> i_functions;
      SimCode.Function i_mainFunction;
      String i_name;
      Tpl.Text txt_8;
      Tpl.Text txt_7;
      Tpl.Text txt_6;
      Tpl.Text txt_5;
      Tpl.Text txt_4;
      Tpl.Text txt_3;
      Tpl.Text txt_2;
      Tpl.Text txt_1;
      Tpl.Text l_filePrefix;

    case ( txt,
           (i_functionCode as SimCode.FUNCTIONCODE(name = i_name, mainFunction = i_mainFunction, functions = i_functions, extraRecordDecls = i_extraRecordDecls, externalFunctionIncludes = i_externalFunctionIncludes)) )
      equation
        l_filePrefix = Tpl.writeStr(Tpl.emptyTxt, i_name);
        txt_1 = functionsHeaderFile(Tpl.emptyTxt, Tpl.textString(l_filePrefix), i_mainFunction, i_functions, i_extraRecordDecls, i_externalFunctionIncludes);
        txt_2 = Tpl.writeText(Tpl.emptyTxt, l_filePrefix);
        txt_2 = Tpl.writeTok(txt_2, Tpl.ST_STRING(".h"));
        Tpl.textFile(txt_1, Tpl.textString(txt_2));
        txt_3 = functionsFile(Tpl.emptyTxt, Tpl.textString(l_filePrefix), i_mainFunction, i_functions);
        txt_4 = Tpl.writeText(Tpl.emptyTxt, l_filePrefix);
        txt_4 = Tpl.writeTok(txt_4, Tpl.ST_STRING(".c"));
        Tpl.textFile(txt_3, Tpl.textString(txt_4));
        txt_5 = recordsFile(Tpl.emptyTxt, Tpl.textString(l_filePrefix), i_extraRecordDecls);
        txt_6 = Tpl.writeText(Tpl.emptyTxt, l_filePrefix);
        txt_6 = Tpl.writeTok(txt_6, Tpl.ST_STRING("_records.c"));
        Tpl.textFile(txt_5, Tpl.textString(txt_6));
        txt_7 = functionsMakefile(Tpl.emptyTxt, i_functionCode);
        txt_8 = Tpl.writeText(Tpl.emptyTxt, l_filePrefix);
        txt_8 = Tpl.writeTok(txt_8, Tpl.ST_STRING(".makefile"));
        Tpl.textFile(txt_7, Tpl.textString(txt_8));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end translateFunctions;

public function simulationFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode)
    local
      Tpl.Text txt;
      list<SimCode.JacobianMatrix> i_JacobianMatrixes;
      list<DAE.ComponentRef> i_discreteModelVars2;
      list<SimCode.SimEqSystem> i_allEquationsPlusWhen;
      list<SimCode.SimEqSystem> i_algebraicEquations;
      list<SimCode.SimEqSystem> i_odeEquations;
      list<DAE.ComponentRef> i_discreteModelVars;
      list<SimCode.SimEqSystem> i_parameterEquations;
      list<SimCode.SimEqSystem> i_residualEquations;
      list<SimCode.SimEqSystem> i_initialEquations;
      list<SimCode.SimEqSystem> i_stateContEquations;
      list<SimCode.SimWhenClause> i_whenClauses;
      SimCode.DelayedExpression i_delayedExps;
      list<SimCode.HelpVarInfo> i_helpVarInfo;
      list<list<SimCode.SimVar>> i_zeroCrossingsNeedSave;
      list<BackendDAE.ZeroCrossing> i_zeroCrossings;
      list<SimCode.SimEqSystem> i_nonStateDiscEquations;
      list<DAE.Statement> i_algorithmAndEquationAsserts;
      list<SimCode.SimEqSystem> i_removedEquations;
      list<SimCode.SimEqSystem> i_nonStateContEquations;
      list<SimCode.SimEqSystem> i_allEquations;
      SimCode.ExtObjInfo i_extObjInfo;
      SimCode.ModelInfo i_modelInfo;
      SimCode.SimCode i_simCode;

    case ( txt,
           (i_simCode as SimCode.SIMCODE(modelInfo = i_modelInfo, extObjInfo = i_extObjInfo, allEquations = i_allEquations, nonStateContEquations = i_nonStateContEquations, removedEquations = i_removedEquations, algorithmAndEquationAsserts = i_algorithmAndEquationAsserts, nonStateDiscEquations = i_nonStateDiscEquations, zeroCrossings = i_zeroCrossings, zeroCrossingsNeedSave = i_zeroCrossingsNeedSave, helpVarInfo = i_helpVarInfo, delayedExps = i_delayedExps, whenClauses = i_whenClauses, stateContEquations = i_stateContEquations, initialEquations = i_initialEquations, residualEquations = i_residualEquations, parameterEquations = i_parameterEquations, discreteModelVars = i_discreteModelVars, odeEquations = i_odeEquations, algebraicEquations = i_algebraicEquations, allEquationsPlusWhen = i_allEquationsPlusWhen, discreteModelVars2 = i_discreteModelVars2, JacobianMatrixes = i_JacobianMatrixes)) )
      equation
        txt = simulationFileHeader(txt, i_simCode);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = globalData(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionGetName(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDivisionError(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionSetLocalData(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitializeDataStruc(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionCallExternalObjectConstructors(txt, i_extObjInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDeInitializeDataStruc(txt, i_extObjInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionExtraResiduals(txt, i_allEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDaeOutput(txt, i_nonStateContEquations, i_removedEquations, i_algorithmAndEquationAsserts);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDaeOutput2(txt, i_nonStateDiscEquations, i_removedEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInput(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionOutput(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDaeRes(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionZeroCrossing(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionHandleZeroCrossing(txt, i_zeroCrossingsNeedSave);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitSample(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionUpdateDependents(txt, i_allEquations, i_helpVarInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionStoreDelayed(txt, i_delayedExps);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionWhen(txt, i_whenClauses);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionOde(txt, i_stateContEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitial(txt, i_initialEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionInitialResidual(txt, i_residualEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionBoundParameters(txt, i_parameterEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionCheckForDiscreteVarChanges(txt, i_helpVarInfo, i_discreteModelVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionODE(txt, i_odeEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionODE_residual(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionAlgebraic(txt, i_algebraicEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionAliasEquation(txt, i_removedEquations);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionDAE(txt, i_allEquationsPlusWhen, i_whenClauses, i_helpVarInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionOnlyZeroCrossing(txt, i_zeroCrossings);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionCheckForDiscreteChanges(txt, i_discreteModelVars2);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = generateLinearMatrixes(txt, i_JacobianMatrixes);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = functionlinearmodel(txt, i_modelInfo);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationFile;

public function simulationFileHeader
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode)
    local
      Tpl.Text txt;
      String i_fileNamePrefix;
      Absyn.Path i_modelInfo_name;
      String ret_0;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(name = i_modelInfo_name), extObjInfo = SimCode.EXTOBJINFO(includes = _), fileNamePrefix = i_fileNamePrefix) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("// Simulation code for "));
        txt = dotPath(txt, i_modelInfo_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" generated by the OpenModelica Compiler "));
        ret_0 = Settings.getVersionNr();
        txt = Tpl.writeStr(txt, ret_0);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ".\n",
                                    "\n",
                                    "#include \"modelica.h\"\n",
                                    "#include \"assert.h\"\n",
                                    "#include \"string.h\"\n",
                                    "#include \"simulation_runtime.h\"\n",
                                    "\n",
                                    "#include \""
                                }, false));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_functions.h\"\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationFileHeader;

protected function lm_19
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "states");
        txt = Tpl.nextIter(txt);
        txt = lm_19(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_19(txt, rest);
      then txt;
  end matchcontinue;
end lm_19;

protected function lm_20
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "statesDerivatives");
        txt = Tpl.nextIter(txt);
        txt = lm_20(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_20(txt, rest);
      then txt;
  end matchcontinue;
end lm_20;

protected function lm_21
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_21(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_21(txt, rest);
      then txt;
  end matchcontinue;
end lm_21;

protected function lm_22
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_22(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_22(txt, rest);
      then txt;
  end matchcontinue;
end lm_22;

protected function lm_23
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "extObjs");
        txt = Tpl.nextIter(txt);
        txt = lm_23(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_23(txt, rest);
      then txt;
  end matchcontinue;
end lm_23;

protected function lm_24
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "intVariables.algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_24(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_24(txt, rest);
      then txt;
  end matchcontinue;
end lm_24;

protected function lm_25
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "intVariables.parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_25(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_25(txt, rest);
      then txt;
  end matchcontinue;
end lm_25;

protected function lm_26
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "boolVariables.algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_26(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_26(txt, rest);
      then txt;
  end matchcontinue;
end lm_26;

protected function lm_27
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "boolVariables.parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_27(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_27(txt, rest);
      then txt;
  end matchcontinue;
end lm_27;

protected function lm_28
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "stringVariables.algebraics");
        txt = Tpl.nextIter(txt);
        txt = lm_28(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_28(txt, rest);
      then txt;
  end matchcontinue;
end lm_28;

protected function lm_29
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = globalDataVarDefine(txt, i_var, "stringVariables.parameters");
        txt = Tpl.nextIter(txt);
        txt = lm_29(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_29(txt, rest);
      then txt;
  end matchcontinue;
end lm_29;

protected function lm_30
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_30(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_30(txt, rest);
      then txt;
  end matchcontinue;
end lm_30;

protected function lm_31
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_31(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_31(txt, rest);
      then txt;
  end matchcontinue;
end lm_31;

protected function lm_32
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_32(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_32(txt, rest);
      then txt;
  end matchcontinue;
end lm_32;

protected function lm_33
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_33(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_33(txt, rest);
      then txt;
  end matchcontinue;
end lm_33;

protected function lm_34
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_34(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_34(txt, rest);
      then txt;
  end matchcontinue;
end lm_34;

protected function lm_35
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_35(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_35(txt, rest);
      then txt;
  end matchcontinue;
end lm_35;

protected function lm_36
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_36(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_36(txt, rest);
      then txt;
  end matchcontinue;
end lm_36;

protected function lm_37
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isFixed;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(isFixed = i_isFixed, name = i_name) :: rest )
      equation
        txt = globalDataFixedInt(txt, i_isFixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_37(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_37(txt, rest);
      then txt;
  end matchcontinue;
end lm_37;

protected function smf_38
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_38;

protected function smf_39
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_39;

protected function smf_40
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_40;

protected function smf_41
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_41;

protected function smf_42
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_42;

protected function smf_43
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_43;

protected function smf_44
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_44;

protected function smf_45
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_45;

protected function lm_46
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_46(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_46(txt, rest);
      then txt;
  end matchcontinue;
end lm_46;

protected function lm_47
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_47(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_47(txt, rest);
      then txt;
  end matchcontinue;
end lm_47;

protected function lm_48
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_48(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_48(txt, rest);
      then txt;
  end matchcontinue;
end lm_48;

protected function lm_49
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_49(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_49(txt, rest);
      then txt;
  end matchcontinue;
end lm_49;

protected function lm_50
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_50(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_50(txt, rest);
      then txt;
  end matchcontinue;
end lm_50;

protected function lm_51
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_51(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_51(txt, rest);
      then txt;
  end matchcontinue;
end lm_51;

protected function lm_52
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_52(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_52(txt, rest);
      then txt;
  end matchcontinue;
end lm_52;

protected function lm_53
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_53(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_53(txt, rest);
      then txt;
  end matchcontinue;
end lm_53;

protected function lm_54
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Boolean i_isDiscrete;
      DAE.ExpType i_type__;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(type_ = i_type__, isDiscrete = i_isDiscrete, name = i_name) :: rest )
      equation
        txt = globalDataAttrInt(txt, i_type__);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("+"));
        txt = globalDataDiscAttrInt(txt, i_isDiscrete);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.nextIter(txt);
        txt = lm_54(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_54(txt, rest);
      then txt;
  end matchcontinue;
end lm_54;

protected function smf_55
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_55;

protected function smf_56
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_56;

protected function smf_57
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_57;

protected function smf_58
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_58;

protected function smf_59
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_59;

protected function smf_60
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_60;

protected function smf_61
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_61;

protected function smf_62
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_62;

protected function smf_63
  input Tpl.Text in_txt;
  input Tpl.Text in_it;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_it)
    local
      Tpl.Text txt;
      Tpl.Text i_it;

    case ( txt,
           i_it )
      equation
        txt = Tpl.writeText(txt, i_it);
        txt = Tpl.nextIter(txt);
      then txt;
  end matchcontinue;
end smf_63;

public function globalData
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_a_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_modelInfo)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_vars_extObjVars;
      list<SimCode.SimVar> i_vars_stringParamVars;
      list<SimCode.SimVar> i_vars_stringAlgVars;
      list<SimCode.SimVar> i_vars_boolParamVars;
      list<SimCode.SimVar> i_vars_boolAlgVars;
      list<SimCode.SimVar> i_vars_intParamVars;
      list<SimCode.SimVar> i_vars_intAlgVars;
      list<SimCode.SimVar> i_vars_paramVars;
      list<SimCode.SimVar> i_vars_outputVars;
      list<SimCode.SimVar> i_vars_inputVars;
      list<SimCode.SimVar> i_vars_algVars;
      list<SimCode.SimVar> i_vars_derivativeVars;
      list<SimCode.SimVar> i_vars_stateVars;
      String i_directory;
      Absyn.Path i_name;
      Integer i_varInfo_numBoolParams;
      Integer i_varInfo_numBoolAlgVars;
      Integer i_varInfo_numIntParams;
      Integer i_varInfo_numIntAlgVars;
      Integer i_varInfo_numStringParamVars;
      Integer i_varInfo_numStringAlgVars;
      Integer i_varInfo_numExternalObjects;
      Integer i_varInfo_numResiduals;
      Integer i_varInfo_numInVars;
      Integer i_varInfo_numOutVars;
      Integer i_varInfo_numParams;
      Integer i_varInfo_numAlgVars;
      Integer i_varInfo_numStateVars;
      Integer i_varInfo_numTimeEvents;
      Integer i_varInfo_numZeroCrossings;
      Integer i_varInfo_numHelpVars;
      Tpl.Text txt_16;
      Tpl.Text txt_15;
      Tpl.Text txt_14;
      Tpl.Text txt_13;
      Tpl.Text txt_12;
      Tpl.Text txt_11;
      Tpl.Text txt_10;
      Tpl.Text txt_9;
      Tpl.Text txt_8;
      Tpl.Text txt_7;
      Tpl.Text txt_6;
      Tpl.Text txt_5;
      Tpl.Text txt_4;
      Tpl.Text txt_3;
      Tpl.Text txt_2;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           SimCode.MODELINFO(varInfo = SimCode.VARINFO(numHelpVars = i_varInfo_numHelpVars, numZeroCrossings = i_varInfo_numZeroCrossings, numTimeEvents = i_varInfo_numTimeEvents, numStateVars = i_varInfo_numStateVars, numAlgVars = i_varInfo_numAlgVars, numParams = i_varInfo_numParams, numOutVars = i_varInfo_numOutVars, numInVars = i_varInfo_numInVars, numResiduals = i_varInfo_numResiduals, numExternalObjects = i_varInfo_numExternalObjects, numStringAlgVars = i_varInfo_numStringAlgVars, numStringParamVars = i_varInfo_numStringParamVars, numIntAlgVars = i_varInfo_numIntAlgVars, numIntParams = i_varInfo_numIntParams, numBoolAlgVars = i_varInfo_numBoolAlgVars, numBoolParams = i_varInfo_numBoolParams), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, inputVars = i_vars_inputVars, outputVars = i_vars_outputVars, paramVars = i_vars_paramVars, intAlgVars = i_vars_intAlgVars, intParamVars = i_vars_intParamVars, boolAlgVars = i_vars_boolAlgVars, boolParamVars = i_vars_boolParamVars, stringAlgVars = i_vars_stringAlgVars, stringParamVars = i_vars_stringParamVars, extObjVars = i_vars_extObjVars), name = i_name, directory = i_directory) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NHELP "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numHelpVars));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NG "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numZeroCrossings));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of zero crossings\n",
                                    "#define NG_SAM "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numTimeEvents));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of zero crossings that are samples\n",
                                    "#define NX "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStateVars));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NY "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numAlgVars));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define NP "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numParams));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of parameters\n",
                                    "#define NO "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numOutVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of outputvar on topmodel\n",
                                    "#define NI "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numInVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of inputvar on topmodel\n",
                                    "#define NR "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numResiduals));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of residuals for initialialization function\n",
                                    "#define NEXT "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numExternalObjects));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of external objects\n",
                                    "#define MAXORD 5\n",
                                    "#define NYSTR "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStringAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. string variables\n",
                                    "#define NPSTR "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStringParamVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. string variables\n",
                                    "#define NYINT "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numIntAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. int variables\n",
                                    "#define NPINT "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numIntParams));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. int variables\n",
                                    "#define NYBOOL "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numBoolAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. bool variables\n",
                                    "#define NPBOOL "
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numBoolParams));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // number of alg. bool variables\n",
                                    "\n",
                                    "static DATA* localData = 0;\n",
                                    "#define time localData->timeValue\n",
                                    "#define $P$old$Ptime localData->oldTime\n",
                                    "#define $P$current_step_size globalData->current_stepsize\n",
                                    "\n",
                                    "extern \"C\" { // adrpo: this is needed for Visual C++ compilation to work!\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char *model_name=\""));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\";\n",
                                    "const char *model_dir=\""
                                }, false));
        txt = Tpl.writeStr(txt, i_directory);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n",
                                    "// we need to access the inline define that we compiled the simulation with\n",
                                    "// from the simulation runtime.\n",
                                    "const char *_omc_force_solver=_OMC_FORCE_SOLVER;\n",
                                    "const int inline_work_states_ndims=_OMC_SOLVER_WORK_STATES_NDIMS;\n",
                                    "\n"
                                }, true));
        txt = globalDataVarNamesArray(txt, "state_names", i_vars_stateVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "derivative_names", i_vars_derivativeVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "algvars_names", i_vars_algVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "input_names", i_vars_inputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "output_names", i_vars_outputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "param_names", i_vars_paramVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "int_alg_names", i_vars_intAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "int_param_names", i_vars_intParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "bool_alg_names", i_vars_boolAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "bool_param_names", i_vars_boolParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "string_alg_names", i_vars_stringAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarNamesArray(txt, "string_param_names", i_vars_stringParamVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = globalDataVarCommentsArray(txt, "state_comments", i_vars_stateVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "derivative_comments", i_vars_derivativeVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "algvars_comments", i_vars_algVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "input_comments", i_vars_inputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "output_comments", i_vars_outputVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "param_comments", i_vars_paramVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "int_alg_comments", i_vars_intAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "int_param_comments", i_vars_intParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "bool_alg_comments", i_vars_boolAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "bool_param_comments", i_vars_boolParamVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "string_alg_comments", i_vars_stringAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = globalDataVarCommentsArray(txt, "string_param_comments", i_vars_stringParamVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_19(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_20(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_21(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_22(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_23(txt, i_vars_extObjVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_24(txt, i_vars_intAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_25(txt, i_vars_intParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_26(txt, i_vars_boolAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_27(txt, i_vars_boolParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_28(txt, i_vars_stringAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_29(txt, i_vars_stringParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "static char init_fixed[NX+NX+NY+NYINT+NYBOOL+NYSTR+NP+NPINT+NPBOOL+NPSTR] = {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt_0 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_0 = lm_30(txt_0, i_vars_stateVars);
        txt_0 = Tpl.popIter(txt_0);
        txt_1 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_1 = lm_31(txt_1, i_vars_derivativeVars);
        txt_1 = Tpl.popIter(txt_1);
        txt_2 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_32(txt_2, i_vars_algVars);
        txt_2 = Tpl.popIter(txt_2);
        txt_3 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_3 = lm_33(txt_3, i_vars_intAlgVars);
        txt_3 = Tpl.popIter(txt_3);
        txt_4 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_4 = lm_34(txt_4, i_vars_boolAlgVars);
        txt_4 = Tpl.popIter(txt_4);
        txt_5 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_5 = lm_35(txt_5, i_vars_paramVars);
        txt_5 = Tpl.popIter(txt_5);
        txt_6 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_6 = lm_36(txt_6, i_vars_intParamVars);
        txt_6 = Tpl.popIter(txt_6);
        txt_7 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_7 = lm_37(txt_7, i_vars_boolParamVars);
        txt_7 = Tpl.popIter(txt_7);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = smf_38(txt, txt_0);
        txt = smf_39(txt, txt_1);
        txt = smf_40(txt, txt_2);
        txt = smf_41(txt, txt_3);
        txt = smf_42(txt, txt_4);
        txt = smf_43(txt, txt_5);
        txt = smf_44(txt, txt_6);
        txt = smf_45(txt, txt_7);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "\n",
                                    "char var_attr[NX+NY+NYINT+NYBOOL+NYSTR+NP+NPINT+NPBOOL+NPSTR] = {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt_8 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_8 = lm_46(txt_8, i_vars_stateVars);
        txt_8 = Tpl.popIter(txt_8);
        txt_9 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_9 = lm_47(txt_9, i_vars_algVars);
        txt_9 = Tpl.popIter(txt_9);
        txt_10 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_10 = lm_48(txt_10, i_vars_intAlgVars);
        txt_10 = Tpl.popIter(txt_10);
        txt_11 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_11 = lm_49(txt_11, i_vars_boolAlgVars);
        txt_11 = Tpl.popIter(txt_11);
        txt_12 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_12 = lm_50(txt_12, i_vars_stringAlgVars);
        txt_12 = Tpl.popIter(txt_12);
        txt_13 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_13 = lm_51(txt_13, i_vars_paramVars);
        txt_13 = Tpl.popIter(txt_13);
        txt_14 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_14 = lm_52(txt_14, i_vars_intParamVars);
        txt_14 = Tpl.popIter(txt_14);
        txt_15 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_15 = lm_53(txt_15, i_vars_boolParamVars);
        txt_15 = Tpl.popIter(txt_15);
        txt_16 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_16 = lm_54(txt_16, i_vars_stringParamVars);
        txt_16 = Tpl.popIter(txt_16);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_LINE(",\n")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = smf_55(txt, txt_8);
        txt = smf_56(txt, txt_9);
        txt = smf_57(txt, txt_10);
        txt = smf_58(txt, txt_11);
        txt = smf_59(txt, txt_12);
        txt = smf_60(txt, txt_13);
        txt = smf_61(txt, txt_14);
        txt = smf_62(txt, txt_15);
        txt = smf_63(txt, txt_16);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalData;

protected function lm_65
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_65(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_65(txt, rest);
      then txt;
  end matchcontinue;
end lm_65;

protected function fun_66
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_a_items;
  input String in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_items, in_a_name)
    local
      Tpl.Text txt;
      String a_name;
      list<SimCode.SimVar> i_items;
      Integer ret_1;
      Tpl.Text l_itemsStr;

    case ( txt,
           {},
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("[1] = {\"\"};"));
      then txt;

    case ( txt,
           i_items,
           a_name )
      equation
        l_itemsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_itemsStr = lm_65(l_itemsStr, i_items);
        l_itemsStr = Tpl.popIter(l_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        ret_1 = listLength(i_items);
        txt = Tpl.writeStr(txt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.writeText(txt, l_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;
  end matchcontinue;
end fun_66;

public function globalDataVarNamesArray
  input Tpl.Text txt;
  input String a_name;
  input list<SimCode.SimVar> a_items;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_66(txt, a_items, a_name);
end globalDataVarNamesArray;

protected function lm_68
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      String i_comment;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(comment = i_comment) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeStr(txt, i_comment);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_68(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_68(txt, rest);
      then txt;
  end matchcontinue;
end lm_68;

protected function fun_69
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_a_items;
  input String in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_items, in_a_name)
    local
      Tpl.Text txt;
      String a_name;
      list<SimCode.SimVar> i_items;
      Integer ret_1;
      Tpl.Text l_itemsStr;

    case ( txt,
           {},
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("[1] = {\"\"};"));
      then txt;

    case ( txt,
           i_items,
           a_name )
      equation
        l_itemsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_itemsStr = lm_68(l_itemsStr, i_items);
        l_itemsStr = Tpl.popIter(l_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        ret_1 = listLength(i_items);
        txt = Tpl.writeStr(txt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.writeText(txt, l_itemsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("};"));
      then txt;
  end matchcontinue;
end fun_69;

public function globalDataVarCommentsArray
  input Tpl.Text txt;
  input String a_name;
  input list<SimCode.SimVar> a_items;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_69(txt, a_items, a_name);
end globalDataVarCommentsArray;

public function globalDataVarDefine
  input Tpl.Text in_txt;
  input SimCode.SimVar in_a_simVar;
  input String in_a_arrayName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simVar, in_a_arrayName)
    local
      Tpl.Text txt;
      String a_arrayName;
      DAE.ComponentRef i_name;
      Integer i_index;
      DAE.ComponentRef i_c;

    case ( txt,
           SimCode.SIMVAR(arrayCref = SOME(i_c), index = i_index, name = i_name),
           a_arrayName )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = cref(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define "
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_old["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old2"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_old2["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index),
           a_arrayName )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_old["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "]\n",
                                    "#define $P$old2"
                                }, false));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" localData->"));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_old2["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end globalDataVarDefine;

public function globalDataFixedInt
  input Tpl.Text in_txt;
  input Boolean in_a_isFixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_isFixed)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1"));
      then txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalDataFixedInt;

public function globalDataAttrInt
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("2"));
      then txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("4"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("4"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("8"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalDataAttrInt;

public function globalDataDiscAttrInt
  input Tpl.Text in_txt;
  input Boolean in_a_isDiscrete;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_isDiscrete)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("16"));
      then txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end globalDataDiscAttrInt;

protected function lm_75
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return state_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_75(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_75(txt, rest);
      then txt;
  end matchcontinue;
end lm_75;

protected function lm_76
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return derivative_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_76(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_76(txt, rest);
      then txt;
  end matchcontinue;
end lm_76;

protected function lm_77
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return algvars_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_77(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_77(txt, rest);
      then txt;
  end matchcontinue;
end lm_77;

protected function lm_78
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return param_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_78(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_78(txt, rest);
      then txt;
  end matchcontinue;
end lm_78;

protected function lm_79
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return int_alg_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_79(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_79(txt, rest);
      then txt;
  end matchcontinue;
end lm_79;

protected function lm_80
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return int_param_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_80(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_80(txt, rest);
      then txt;
  end matchcontinue;
end lm_80;

protected function lm_81
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return bool_alg_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_81(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_81(txt, rest);
      then txt;
  end matchcontinue;
end lm_81;

protected function lm_82
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer i_index;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (&"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == ptr) return bool_param_names["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_82(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_82(txt, rest);
      then txt;
  end matchcontinue;
end lm_82;

public function functionGetName
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_a_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_modelInfo)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_vars_boolParamVars;
      list<SimCode.SimVar> i_vars_boolAlgVars;
      list<SimCode.SimVar> i_vars_intParamVars;
      list<SimCode.SimVar> i_vars_intAlgVars;
      list<SimCode.SimVar> i_vars_paramVars;
      list<SimCode.SimVar> i_vars_algVars;
      list<SimCode.SimVar> i_vars_derivativeVars;
      list<SimCode.SimVar> i_vars_stateVars;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars, intAlgVars = i_vars_intAlgVars, intParamVars = i_vars_intParamVars, boolAlgVars = i_vars_boolAlgVars, boolParamVars = i_vars_boolParamVars)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "const char* getName(double* ptr)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_75(txt, i_vars_stateVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_76(txt, i_vars_derivativeVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_77(txt, i_vars_algVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_78(txt, i_vars_paramVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return \"\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n",
                                    "const char* getName(modelica_integer* ptr)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_79(txt, i_vars_intAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_80(txt, i_vars_intParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return \"\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n",
                                    "const char* getName(modelica_boolean* ptr)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_81(txt, i_vars_boolAlgVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_82(txt, i_vars_boolParamVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return \"\";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionGetName;

public function functionDivisionError
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* Commented out by Frenkel TUD because there is a new implementation of\n",
                                   "   division by zero problem. */\n",
                                   "/*\n",
                                   "#define DIVISION(a,b,c) ((b != 0) ? a / b : a / division_error(b,c))\n",
                                   "\n",
                                   "int encounteredDivisionByZero = 0;\n",
                                   "\n",
                                   "double division_error(double b, const char* division_str)\n",
                                   "{\n",
                                   "  if(!encounteredDivisionByZero) {\n",
                                   "    fprintf(stderr, \"ERROR: Division by zero in partial equation: %s.\\n\",division_str);\n",
                                   "    encounteredDivisionByZero = 1;\n",
                                   "  }\n",
                                   "  return b;\n",
                                   "}\n",
                                   "*/"
                               }, false));
end functionDivisionError;

public function functionSetLocalData
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "void setLocalData(DATA* data)\n",
                                   "{\n",
                                   "  localData = data;\n",
                                   "}"
                               }, false));
end functionSetLocalData;

public function functionInitializeDataStruc
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "DATA* initializeDataStruc(DATA_FLAGS flags)\n",
                                   "{\n",
                                   "  DATA* returnData = (DATA*)malloc(sizeof(DATA));\n",
                                   "\n",
                                   "  if(!returnData) //error check\n",
                                   "    return 0;\n",
                                   "\n",
                                   "  memset(returnData,0,sizeof(DATA));\n",
                                   "  returnData->nStates = NX;\n",
                                   "  returnData->nAlgebraic = NY;\n",
                                   "  returnData->nParameters = NP;\n",
                                   "  returnData->nInputVars = NI;\n",
                                   "  returnData->nOutputVars = NO;\n",
                                   "  returnData->nZeroCrossing = NG;\n",
                                   "  returnData->nRawSamples = NG_SAM;\n",
                                   "  returnData->nInitialResiduals = NR;\n",
                                   "  returnData->nHelpVars = NHELP;\n",
                                   "  returnData->stringVariables.nParameters = NPSTR;\n",
                                   "  returnData->stringVariables.nAlgebraic = NYSTR;\n",
                                   "  returnData->intVariables.nParameters = NPINT;\n",
                                   "  returnData->intVariables.nAlgebraic = NYINT;\n",
                                   "  returnData->boolVariables.nParameters = NPBOOL;\n",
                                   "  returnData->boolVariables.nAlgebraic = NYBOOL;\n",
                                   "\n",
                                   "  if(flags & STATES && returnData->nStates) {\n",
                                   "    returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->states_old = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->states_old2 = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    assert(returnData->states&&returnData->states_old&&returnData->states_old2);\n",
                                   "    memset(returnData->states,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->states_old,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->states_old2,0,sizeof(double)*returnData->nStates);\n",
                                   "  } else {\n",
                                   "    returnData->states = 0;\n",
                                   "    returnData->states_old = 0;\n",
                                   "    returnData->states_old2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESDERIVATIVES && returnData->nStates) {\n",
                                   "    returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->statesDerivatives_old = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    returnData->statesDerivatives_old2 = (double*) malloc(sizeof(double)*returnData->nStates);\n",
                                   "    assert(returnData->statesDerivatives&&returnData->statesDerivatives_old&&returnData->statesDerivatives_old2);\n",
                                   "    memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->statesDerivatives_old,0,sizeof(double)*returnData->nStates);\n",
                                   "    memset(returnData->statesDerivatives_old2,0,sizeof(double)*returnData->nStates);\n",
                                   "  } else {\n",
                                   "    returnData->statesDerivatives = 0;\n",
                                   "    returnData->statesDerivatives_old = 0;\n",
                                   "    returnData->statesDerivatives_old2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & HELPVARS && returnData->nHelpVars) {\n",
                                   "    returnData->helpVars = (double*) malloc(sizeof(double)*returnData->nHelpVars);\n",
                                   "    assert(returnData->helpVars);\n",
                                   "    memset(returnData->helpVars,0,sizeof(double)*returnData->nHelpVars);\n",
                                   "  } else {\n",
                                   "    returnData->helpVars = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICS && returnData->nAlgebraic) {\n",
                                   "    returnData->algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    returnData->algebraics_old = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    returnData->algebraics_old2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);\n",
                                   "    assert(returnData->algebraics&&returnData->algebraics_old&&returnData->algebraics_old2);\n",
                                   "    memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "    memset(returnData->algebraics_old,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "    memset(returnData->algebraics_old2,0,sizeof(double)*returnData->nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->algebraics = 0;\n",
                                   "    returnData->algebraics_old = 0;\n",
                                   "    returnData->algebraics_old2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & ALGEBRAICS && returnData->stringVariables.nAlgebraic) {\n",
                                   "    returnData->stringVariables.algebraics = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);\n",
                                   "    assert(returnData->stringVariables.algebraics);\n",
                                   "    memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->stringVariables.algebraics=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & ALGEBRAICS && returnData->intVariables.nAlgebraic) {\n",
                                   "    returnData->intVariables.algebraics = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    returnData->intVariables.algebraics_old = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    returnData->intVariables.algebraics_old2 = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    assert(returnData->intVariables.algebraics&&returnData->intVariables.algebraics_old&&returnData->intVariables.algebraics_old2);\n",
                                   "    memset(returnData->intVariables.algebraics,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    memset(returnData->intVariables.algebraics_old,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "    memset(returnData->intVariables.algebraics_old2,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->intVariables.algebraics=0;\n",
                                   "    returnData->intVariables.algebraics_old = 0;\n",
                                   "    returnData->intVariables.algebraics_old2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & ALGEBRAICS && returnData->boolVariables.nAlgebraic) {\n",
                                   "    returnData->boolVariables.algebraics = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    returnData->boolVariables.algebraics_old = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    returnData->boolVariables.algebraics_old2 = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    assert(returnData->boolVariables.algebraics&&returnData->boolVariables.algebraics_old&&returnData->boolVariables.algebraics_old2);\n",
                                   "    memset(returnData->boolVariables.algebraics,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    memset(returnData->boolVariables.algebraics_old,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "    memset(returnData->boolVariables.algebraics_old2,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);\n",
                                   "  } else {\n",
                                   "    returnData->boolVariables.algebraics=0;\n",
                                   "    returnData->boolVariables.algebraics_old = 0;\n",
                                   "    returnData->boolVariables.algebraics_old2 = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERS && returnData->nParameters) {\n",
                                   "    returnData->parameters = (double*) malloc(sizeof(double)*returnData->nParameters);\n",
                                   "    assert(returnData->parameters);\n",
                                   "    memset(returnData->parameters,0,sizeof(double)*returnData->nParameters);\n",
                                   "  } else {\n",
                                   "    returnData->parameters = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & PARAMETERS && returnData->stringVariables.nParameters) {\n",
                                   "      returnData->stringVariables.parameters = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);\n",
                                   "      assert(returnData->stringVariables.parameters);\n",
                                   "      memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);\n",
                                   "  } else {\n",
                                   "      returnData->stringVariables.parameters=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & PARAMETERS && returnData->intVariables.nParameters) {\n",
                                   "      returnData->intVariables.parameters = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nParameters);\n",
                                   "      assert(returnData->intVariables.parameters);\n",
                                   "      memset(returnData->intVariables.parameters,0,sizeof(modelica_integer)*returnData->intVariables.nParameters);\n",
                                   "  } else {\n",
                                   "      returnData->intVariables.parameters=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & PARAMETERS && returnData->boolVariables.nParameters) {\n",
                                   "      returnData->boolVariables.parameters = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nParameters);\n",
                                   "      assert(returnData->boolVariables.parameters);\n",
                                   "      memset(returnData->boolVariables.parameters,0,sizeof(modelica_boolean)*returnData->boolVariables.nParameters);\n",
                                   "  } else {\n",
                                   "      returnData->boolVariables.parameters=0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & OUTPUTVARS && returnData->nOutputVars) {\n",
                                   "    returnData->outputVars = (double*) malloc(sizeof(double)*returnData->nOutputVars);\n",
                                   "    assert(returnData->outputVars);\n",
                                   "    memset(returnData->outputVars,0,sizeof(double)*returnData->nOutputVars);\n",
                                   "  } else {\n",
                                   "    returnData->outputVars = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INPUTVARS && returnData->nInputVars) {\n",
                                   "    returnData->inputVars = (double*) malloc(sizeof(double)*returnData->nInputVars);\n",
                                   "    assert(returnData->inputVars);\n",
                                   "    memset(returnData->inputVars,0,sizeof(double)*returnData->nInputVars);\n",
                                   "  } else {\n",
                                   "    returnData->inputVars = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INITIALRESIDUALS && returnData->nInitialResiduals) {\n",
                                   "    returnData->initialResiduals = (double*) malloc(sizeof(double)*returnData->nInitialResiduals);\n",
                                   "    assert(returnData->initialResiduals);\n",
                                   "    memset(returnData->initialResiduals,0,sizeof(double)*returnData->nInitialResiduals);\n",
                                   "  } else {\n",
                                   "    returnData->initialResiduals = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INITFIXED) {\n",
                                   "    returnData->initFixed = init_fixed;\n",
                                   "  } else {\n",
                                   "    returnData->initFixed = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  /*   names   */\n",
                                   "  if(flags & MODELNAME) {\n",
                                   "    returnData->modelName = model_name;\n",
                                   "  } else {\n",
                                   "    returnData->modelName = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESNAMES) {\n",
                                   "    returnData->statesNames = state_names;\n",
                                   "  } else {\n",
                                   "    returnData->statesNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESDERIVATIVESNAMES) {\n",
                                   "    returnData->stateDerivativesNames = derivative_names;\n",
                                   "  } else {\n",
                                   "    returnData->stateDerivativesNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSNAMES) {\n",
                                   "    returnData->algebraicsNames = algvars_names;\n",
                                   "  } else {\n",
                                   "    returnData->algebraicsNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSNAMES) {\n",
                                   "    returnData->int_alg_names = int_alg_names;\n",
                                   "  } else {\n",
                                   "    returnData->int_alg_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSNAMES) {\n",
                                   "    returnData->bool_alg_names = bool_alg_names;\n",
                                   "  } else {\n",
                                   "    returnData->bool_alg_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSNAMES) {\n",
                                   "    returnData->parametersNames = param_names;\n",
                                   "  } else {\n",
                                   "    returnData->parametersNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSNAMES) {\n",
                                   "    returnData->int_param_names = int_param_names;\n",
                                   "  } else {\n",
                                   "    returnData->int_param_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSNAMES) {\n",
                                   "    returnData->bool_param_names = bool_param_names;\n",
                                   "  } else {\n",
                                   "    returnData->bool_param_names = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INPUTNAMES) {\n",
                                   "    returnData->inputNames = input_names;\n",
                                   "  } else {\n",
                                   "    returnData->inputNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & OUTPUTNAMES) {\n",
                                   "    returnData->outputNames = output_names;\n",
                                   "  } else {\n",
                                   "    returnData->outputNames = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  /*   comments  */\n",
                                   "  if(flags & STATESCOMMENTS) {\n",
                                   "    returnData->statesComments = state_comments;\n",
                                   "  } else {\n",
                                   "    returnData->statesComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & STATESDERIVATIVESCOMMENTS) {\n",
                                   "    returnData->stateDerivativesComments = derivative_comments;\n",
                                   "  } else {\n",
                                   "    returnData->stateDerivativesComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSCOMMENTS) {\n",
                                   "    returnData->algebraicsComments = algvars_comments;\n",
                                   "  } else {\n",
                                   "    returnData->algebraicsComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSCOMMENTS) {\n",
                                   "    returnData->int_alg_comments = int_alg_comments;\n",
                                   "  } else {\n",
                                   "    returnData->int_alg_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & ALGEBRAICSCOMMENTS) {\n",
                                   "    returnData->bool_alg_comments = bool_alg_comments;\n",
                                   "  } else {\n",
                                   "    returnData->bool_alg_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSCOMMENTS) {\n",
                                   "    returnData->parametersComments = param_comments;\n",
                                   "  } else {\n",
                                   "    returnData->parametersComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSCOMMENTS) {\n",
                                   "    returnData->int_param_comments = int_param_comments;\n",
                                   "  } else {\n",
                                   "    returnData->int_param_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & PARAMETERSCOMMENTS) {\n",
                                   "    returnData->bool_param_comments = bool_param_comments;\n",
                                   "  } else {\n",
                                   "    returnData->bool_param_comments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & INPUTCOMMENTS) {\n",
                                   "    returnData->inputComments = input_comments;\n",
                                   "  } else {\n",
                                   "    returnData->inputComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & OUTPUTCOMMENTS) {\n",
                                   "    returnData->outputComments = output_comments;\n",
                                   "  } else {\n",
                                   "    returnData->outputComments = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if(flags & RAWSAMPLES && returnData->nRawSamples) {\n",
                                   "    returnData->rawSampleExps = (sample_raw_time*) malloc(sizeof(sample_raw_time)*returnData->nRawSamples);\n",
                                   "    assert(returnData->rawSampleExps);\n",
                                   "    memset(returnData->rawSampleExps,0,sizeof(sample_raw_time)*returnData->nRawSamples);\n",
                                   "  } else {\n",
                                   "    returnData->rawSampleExps = 0;\n",
                                   "  }\n",
                                   "\n",
                                   "  if (flags & EXTERNALVARS) {\n",
                                   "    returnData->extObjs = (void**)malloc(sizeof(void*)*NEXT);\n",
                                   "    if (!returnData->extObjs) {\n",
                                   "      printf(\"error allocating external objects\\n\");\n",
                                   "      exit(-2);\n",
                                   "    }\n",
                                   "    memset(returnData->extObjs,0,sizeof(void*)*NEXT);\n",
                                   "  }\n",
                                   "  return returnData;\n",
                                   "}\n",
                                   "\n"
                               }, true));
end functionInitializeDataStruc;

protected function lm_87
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp i_arg;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_arg :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_arg, SimCode.contextOther, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_87(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_87(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_87;

protected function lm_88
  input Tpl.Text in_txt;
  input list<SimCode.ExtConstructor> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<SimCode.ExtConstructor> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      String i_fnName;
      DAE.ComponentRef i_var;
      list<DAE.Exp> i_args;
      Tpl.Text l_argsStr;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           (i_var, i_fnName, i_args) :: rest,
           a_varDecls,
           a_preExp )
      equation
        l_argsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_argsStr, a_varDecls, a_preExp) = lm_87(l_argsStr, i_args, a_varDecls, a_preExp);
        l_argsStr = Tpl.popIter(l_argsStr);
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, i_fnName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_argsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_88(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_88(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_88;

protected function lm_89
  input Tpl.Text in_txt;
  input list<SimCode.ExtAlias> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.ExtAlias> rest;
      DAE.ComponentRef i_var2;
      DAE.ComponentRef i_var1;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var1, i_var2) :: rest )
      equation
        txt = cref(txt, i_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = cref(txt, i_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_89(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_89(txt, rest);
      then txt;
  end matchcontinue;
end lm_89;

public function functionCallExternalObjectConstructors
  input Tpl.Text in_txt;
  input SimCode.ExtObjInfo in_a_extObjInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extObjInfo)
    local
      Tpl.Text txt;
      list<SimCode.ExtAlias> i_aliases;
      list<SimCode.ExtConstructor> i_constructors;
      Tpl.Text l_ctorCalls;
      Tpl.Text l_preExp;
      Tpl.Text l_varDecls;

    case ( txt,
           SimCode.EXTOBJINFO(constructors = i_constructors, aliases = i_aliases) )
      equation
        l_varDecls = Tpl.emptyTxt;
        l_preExp = Tpl.emptyTxt;
        l_ctorCalls = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_ctorCalls, l_varDecls, l_preExp) = lm_88(l_ctorCalls, i_constructors, l_varDecls, l_preExp);
        l_ctorCalls = Tpl.popIter(l_ctorCalls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "/* Has to be performed after _init.txt file has been read */\n",
                                    "void callExternalObjectConstructors(DATA* localData) {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_ctorCalls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_89(txt, i_aliases);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionCallExternalObjectConstructors;

protected function lm_91
  input Tpl.Text in_txt;
  input list<SimCode.ExtDestructor> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.ExtDestructor> rest;
      DAE.ComponentRef i_var;
      String i_fnName;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_fnName, i_var) :: rest )
      equation
        txt = Tpl.writeStr(txt, i_fnName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_91(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_91(txt, rest);
      then txt;
  end matchcontinue;
end lm_91;

public function functionDeInitializeDataStruc
  input Tpl.Text in_txt;
  input SimCode.ExtObjInfo in_a_extObjInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extObjInfo)
    local
      Tpl.Text txt;
      list<SimCode.ExtDestructor> i_destructors;

    case ( txt,
           SimCode.EXTOBJINFO(destructors = i_destructors) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "void deInitializeDataStruc(DATA* data, DATA_FLAGS flags)\n",
                                    "{\n",
                                    "  if(!data)\n",
                                    "    return;\n",
                                    "\n",
                                    "  if(flags & STATES && data->states) {\n",
                                    "    free(data->states);\n",
                                    "    data->states = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATES && data->states_old) {\n",
                                    "    free(data->states_old);\n",
                                    "    data->states_old = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATES && data->states_old2) {\n",
                                    "    free(data->states_old2);\n",
                                    "    data->states_old2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->statesDerivatives) {\n",
                                    "    free(data->statesDerivatives);\n",
                                    "    data->statesDerivatives = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->statesDerivatives_old) {\n",
                                    "    free(data->statesDerivatives_old);\n",
                                    "    data->statesDerivatives_old = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & STATESDERIVATIVES && data->statesDerivatives_old2) {\n",
                                    "    free(data->statesDerivatives_old2);\n",
                                    "    data->statesDerivatives_old2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->algebraics) {\n",
                                    "    free(data->algebraics);\n",
                                    "    data->algebraics = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->algebraics_old) {\n",
                                    "    free(data->algebraics_old);\n",
                                    "    data->algebraics_old = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & ALGEBRAICS && data->algebraics_old2) {\n",
                                    "    free(data->algebraics_old2);\n",
                                    "    data->algebraics_old2 = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & PARAMETERS && data->parameters) {\n",
                                    "    free(data->parameters);\n",
                                    "    data->parameters = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & OUTPUTVARS && data->inputVars) {\n",
                                    "    free(data->inputVars);\n",
                                    "    data->inputVars = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & INPUTVARS && data->outputVars) {\n",
                                    "    free(data->outputVars);\n",
                                    "    data->outputVars = 0;\n",
                                    "  }\n",
                                    "\n",
                                    "  if(flags & INITIALRESIDUALS && data->initialResiduals){\n",
                                    "    free(data->initialResiduals);\n",
                                    "    data->initialResiduals = 0;\n",
                                    "  }\n",
                                    "  if (flags & EXTERNALVARS && data->extObjs) {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(4));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_91(txt, i_destructors);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "free(data->extObjs);\n",
                                    "data->extObjs = 0;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "  }\n",
                                    "  if(flags & RAWSAMPLES && data->rawSampleExps) {\n",
                                    "    free(data->rawSampleExps);\n",
                                    "    data->rawSampleExps = 0;\n",
                                    "  }\n",
                                    "  if(flags & RAWSAMPLES && data->sampleTimes) {\n",
                                    "    free(data->sampleTimes);\n",
                                    "    data->sampleTimes = 0;\n",
                                    "  }\n",
                                    "}"
                                }, false));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionDeInitializeDataStruc;

protected function lm_93
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_93(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_93(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_93;

protected function lm_94
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_94(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_94(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_94;

protected function lm_95
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_95(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_95(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_95;

public function functionDaeOutput
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_nonStateContEquations;
  input list<SimCode.SimEqSystem> a_removedEquations;
  input list<DAE.Statement> a_algorithmAndEquationAsserts;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_removedPart;
  Tpl.Text l_algAndEqAssertsPart;
  Tpl.Text l_nonStateContPart;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_nonStateContPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_nonStateContPart, l_varDecls) := lm_93(l_nonStateContPart, a_nonStateContEquations, l_varDecls);
  l_nonStateContPart := Tpl.popIter(l_nonStateContPart);
  l_algAndEqAssertsPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_algAndEqAssertsPart, l_varDecls) := lm_94(l_algAndEqAssertsPart, a_algorithmAndEquationAsserts, l_varDecls);
  l_algAndEqAssertsPart := Tpl.popIter(l_algAndEqAssertsPart);
  l_removedPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_removedPart, l_varDecls) := lm_95(l_removedPart, a_removedEquations, l_varDecls);
  l_removedPart := Tpl.popIter(l_removedPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for continuous time variables */\n",
                                   "int functionDAE_output()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_nonStateContPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_algAndEqAssertsPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_removedPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionDaeOutput;

protected function lm_97
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_97(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_97(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_97;

protected function lm_98
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_98(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_98(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_98;

public function functionDaeOutput2
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_nonStateDiscEquations;
  input list<SimCode.SimEqSystem> a_removedEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_removedPart;
  Tpl.Text l_nonSateDiscPart;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_nonSateDiscPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_nonSateDiscPart, l_varDecls) := lm_97(l_nonSateDiscPart, a_nonStateDiscEquations, l_varDecls);
  l_nonSateDiscPart := Tpl.popIter(l_nonSateDiscPart);
  l_removedPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_removedPart, l_varDecls) := lm_98(l_removedPart, a_removedEquations, l_varDecls);
  l_removedPart := Tpl.popIter(l_removedPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for discrete time variables */\n",
                                   "int functionDAE_output2()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_nonSateDiscPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_removedPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionDaeOutput2;

protected function lm_100
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer x_i0;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = localData->inputVars["));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_100(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_100(txt, rest);
      then txt;
  end matchcontinue;
end lm_100;

public function functionInput
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_a_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_modelInfo)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_vars_inputVars;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(inputVars = i_vars_inputVars)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int input_function()\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_100(txt, i_vars_inputVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionInput;

protected function lm_102
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer x_i0;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->outputVars["));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_102(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_102(txt, rest);
      then txt;
  end matchcontinue;
end lm_102;

public function functionOutput
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_a_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_modelInfo)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_vars_outputVars;

    case ( txt,
           SimCode.MODELINFO(vars = SimCode.SIMVARS(outputVars = i_vars_outputVars)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int output_function()\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_102(txt, i_vars_outputVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionOutput;

public function functionDaeRes
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionDAE_res(double *t, double *x, double *xd, double *delta,\n",
                                   "                    fortran_integer *ires, double *rpar, fortran_integer *ipar)\n",
                                   "{\n",
                                   "  int i;\n",
                                   "  double temp_xd[NX];\n",
                                   "  double temp_alg[NY];\n",
                                   "  double* statesBackup;\n",
                                   "  double* statesDerivativesBackup;\n",
                                   "  double* algebraicsBackup;\n",
                                   "  double timeBackup;\n",
                                   "\n",
                                   "  statesBackup = localData->states;\n",
                                   "  statesDerivativesBackup = localData->statesDerivatives;\n",
                                   "  algebraicsBackup = localData->algebraics;\n",
                                   "  timeBackup = localData->timeValue;\n",
                                   "  localData->states = x;\n",
                                   "\n",
                                   "  localData->statesDerivatives = temp_xd;\n",
                                   "  localData->algebraics = temp_alg;\n",
                                   "  localData->timeValue = *t;\n",
                                   "\n",
                                   "  memcpy(localData->statesDerivatives, statesDerivativesBackup, localData->nStates*sizeof(double));\n",
                                   "  memcpy(localData->algebraics, algebraicsBackup, localData->nAlgebraic*sizeof(double));\n",
                                   "\n",
                                   "  functionODE();\n",
                                   "\n",
                                   "  /* get the difference between the temp_xd(=localData->statesDerivatives)\n",
                                   "     and xd(=statesDerivativesBackup) */\n",
                                   "  for (i=0; i < localData->nStates; i++) {\n",
                                   "    delta[i] = localData->statesDerivatives[i] - statesDerivativesBackup[i];\n",
                                   "  }\n",
                                   "\n",
                                   "  localData->states = statesBackup;\n",
                                   "  localData->statesDerivatives = statesDerivativesBackup;\n",
                                   "  localData->algebraics = algebraicsBackup;\n",
                                   "  localData->timeValue = timeBackup;\n",
                                   "\n",
                                   "  if (modelErrorCode) {\n",
                                   "    if (ires) {\n",
                                   "      *ires = -1;\n",
                                   "    }\n",
                                   "    modelErrorCode =0;\n",
                                   "  }\n",
                                   "\n",
                                   "  return 0;\n",
                                   "}"
                               }, false));
end functionDaeRes;

public function functionZeroCrossing
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_zeroCrossingsCode;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  (l_zeroCrossingsCode, l_varDecls) := zeroCrossingsTpl(Tpl.emptyTxt, a_zeroCrossings, l_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_zeroCrossing(fortran_integer *neqm, double *t, double *x, fortran_integer *ng,\n",
                                   "                          double *gout, double *rpar, fortran_integer* ipar)\n",
                                   "{\n",
                                   "  double timeBackup;\n",
                                   "  state mem_state;\n",
                                   "\n",
                                   "  mem_state = get_memory_state();\n",
                                   "\n",
                                   "  timeBackup = localData->timeValue;\n",
                                   "  localData->timeValue = *t;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "functionODE();\n",
                                       "functionDAE_output();\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_zeroCrossingsCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "restore_memory_state(mem_state);\n",
                                       "localData->timeValue = timeBackup;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionZeroCrossing;

protected function lm_106
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("save("));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_106(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_106(txt, rest);
      then txt;
  end matchcontinue;
end lm_106;

protected function lm_107
  input Tpl.Text in_txt;
  input list<list<SimCode.SimVar>> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<list<SimCode.SimVar>> rest;
      Integer x_i0;
      list<SimCode.SimVar> i_vars;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_vars :: rest )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(":\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_106(txt, i_vars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        txt = lm_107(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_107(txt, rest);
      then txt;
  end matchcontinue;
end lm_107;

public function functionHandleZeroCrossing
  input Tpl.Text txt;
  input list<list<SimCode.SimVar>> a_zeroCrossingsNeedSave;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* This function should only save in cases. The rest is done in\n",
                                   "   function_updateDependents. */\n",
                                   "int handleZeroCrossing(long index)\n",
                                   "{\n",
                                   "  state mem_state;\n",
                                   "\n",
                                   "  mem_state = get_memory_state();\n",
                                   "\n",
                                   "  switch(index) {\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(4));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_107(out_txt, a_zeroCrossingsNeedSave);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "default:\n",
                                       "  break;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "  }\n",
                                       "\n",
                                       "  restore_memory_state(mem_state);\n",
                                       "\n",
                                       "  return 0;\n",
                                       "}"
                                   }, false));
end functionHandleZeroCrossing;

public function functionInitSample
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_timeEventCode;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  (l_timeEventCode, l_varDecls) := timeEventsTpl(Tpl.emptyTxt, a_zeroCrossings, l_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* Initializes the raw time events of the simulation using the now\n",
                                   "   calcualted parameters. */\n",
                                   "void function_sampleInit()\n",
                                   "{\n",
                                   "  int i = 0; // Current index\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_timeEventCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitSample;

protected function lm_110
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_110(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_110(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_110;

protected function lm_111
  input Tpl.Text in_txt;
  input list<SimCode.HelpVarInfo> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.HelpVarInfo> rest;
      Tpl.Text a_varDecls;
      Integer i_hindex;
      DAE.Exp i_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           (i_hindex, i_exp, _) :: rest,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hindex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_111(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_111(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_111;

public function functionUpdateDependents
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_allEquations;
  input list<SimCode.HelpVarInfo> a_helpVarInfo;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_hvars;
  Tpl.Text l_eqs;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_eqs := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_eqs, l_varDecls) := lm_110(l_eqs, a_allEquations, l_varDecls);
  l_eqs := Tpl.popIter(l_eqs);
  l_hvars := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_hvars, l_varDecls) := lm_111(l_hvars, a_helpVarInfo, l_varDecls);
  l_hvars := Tpl.popIter(l_hvars);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_updateDependents()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "inUpdate=initial()?0:1;\n",
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_eqs);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_hvars);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "inUpdate=0;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionUpdateDependents;

protected function lm_113
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextOther, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_113(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_113(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_113;

protected function lm_114
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      DAE.ComponentRef i_cref;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(cref = i_cref) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (sim_verbose) { printf(\"Setting variable start value: %s(start=%f)\\n\", \""));
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\", "));
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("); }"));
        txt = Tpl.nextIter(txt);
        txt = lm_114(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_114(txt, rest);
      then txt;
  end matchcontinue;
end lm_114;

public function functionInitial
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_initialEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_eqPart;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_eqPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_eqPart, l_varDecls) := lm_113(l_eqPart, a_initialEquations, l_varDecls);
  l_eqPart := Tpl.popIter(l_eqPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int initial_function()\n",
                                   "{\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(out_txt, l_eqPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_114(out_txt, a_initialEquations);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitial;

protected function fun_116
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.Exp i_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.SCONST(string = _),
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->initialResiduals[i++] = 0;"));
      then (txt, a_varDecls);

    case ( txt,
           i_exp,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, SimCode.contextOther, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->initialResiduals[i++] = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);
  end matchcontinue;
end fun_116;

protected function lm_117
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           SimCode.SES_RESIDUAL(exp = i_exp) :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = fun_116(txt, i_exp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_117(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_117(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_117;

public function functionInitialResidual
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_residualEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_body;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_body := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_body, l_varDecls) := lm_117(l_body, a_residualEquations, l_varDecls);
  l_body := Tpl.popIter(l_body);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int initial_residual()\n",
                                   "{\n",
                                   "  int i = 0;\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionInitialResidual;

protected function lm_119
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq2;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           (i_eq2 as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq2, SimCode.contextOther, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_119(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_119(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_119;

protected function lm_120
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      Integer x_i0;
      DAE.Exp i_eq2_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           SimCode.SES_RESIDUAL(exp = i_eq2_exp) :: rest,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_eq2_exp, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("res["));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_120(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_120(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_120;

protected function lm_121
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Integer i_index;
      list<SimCode.SimEqSystem> i_eq_eqs;
      Tpl.Text l_body;
      Tpl.Text l_prebody;
      Tpl.Text l_varDecls;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SES_NONLINEAR(eqs = i_eq_eqs, index = i_index) :: rest )
      equation
        l_varDecls = Tpl.emptyTxt;
        l_prebody = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_prebody, l_varDecls) = lm_119(l_prebody, i_eq_eqs, l_varDecls);
        l_prebody = Tpl.popIter(l_prebody);
        l_body = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_body, l_varDecls) = lm_120(l_body, i_eq_eqs, l_varDecls);
        l_body = Tpl.popIter(l_body);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void residualFunc"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(int *n, double* xloc, double* res, int* iflag)\n",
                                    "{\n",
                                    "  state mem_state;\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("mem_state = get_memory_state();\n"));
        txt = Tpl.writeText(txt, l_prebody);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("restore_memory_state(mem_state);\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
        txt = Tpl.nextIter(txt);
        txt = lm_121(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_121(txt, rest);
      then txt;
  end matchcontinue;
end lm_121;

public function functionExtraResiduals
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_allEquations;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING_LIST({
                                                                    "\n",
                                                                    "\n"
                                                                }, true)), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_121(out_txt, a_allEquations);
  out_txt := Tpl.popIter(out_txt);
end functionExtraResiduals;

protected function lm_123
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_SIMPLE_ASSIGN(cref = _)) :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextOther, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_123(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_123(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_123;

protected function lm_124
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           (i_eq as SimCode.SES_ALGORITHM(statements = _)) :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextOther, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_124(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_124(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_124;

public function functionBoundParameters
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_parameterEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_divbody;
  Tpl.Text l_body;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_body := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_body, l_varDecls) := lm_123(l_body, a_parameterEquations, l_varDecls);
  l_body := Tpl.popIter(l_body);
  l_divbody := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_divbody, l_varDecls) := lm_124(l_divbody, a_parameterEquations, l_varDecls);
  l_divbody := Tpl.popIter(l_divbody);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int bound_parameters()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_body);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_divbody);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionBoundParameters;

protected function fun_126
  input Tpl.Text in_txt;
  input Integer in_a_windex;
  input Integer in_a_hindex;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_windex, in_a_hindex)
    local
      Tpl.Text txt;
      Integer a_hindex;
      Integer i_windex;

    case ( txt,
           -1,
           _ )
      then txt;

    case ( txt,
           i_windex,
           a_hindex )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(a_hindex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])) AddEvent("));
        txt = Tpl.writeStr(txt, intString(i_windex));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" + localData->nZeroCrossing);"));
      then txt;
  end matchcontinue;
end fun_126;

protected function lm_127
  input Tpl.Text in_txt;
  input list<SimCode.HelpVarInfo> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.HelpVarInfo> rest;
      Integer i_hindex;
      Integer i_windex;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_hindex, _, i_windex) :: rest )
      equation
        txt = fun_126(txt, i_windex, i_hindex);
        txt = Tpl.nextIter(txt);
        txt = lm_127(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_127(txt, rest);
      then txt;
  end matchcontinue;
end lm_127;

protected function lm_128
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (change("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) { needToIterate=1; }"));
        txt = Tpl.nextIter(txt);
        txt = lm_128(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_128(txt, rest);
      then txt;
  end matchcontinue;
end lm_128;

public function functionCheckForDiscreteVarChanges
  input Tpl.Text txt;
  input list<SimCode.HelpVarInfo> a_helpVarInfo;
  input list<DAE.ComponentRef> a_discreteModelVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int checkForDiscreteVarChanges()\n",
                                   "{\n",
                                   "  int needToIterate = 0;\n",
                                   "\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_127(out_txt, a_helpVarInfo);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_128(out_txt, a_discreteModelVars);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "for (long i = 0; i < localData->nHelpVars; i++) {\n",
                                       "  if (change(localData->helpVars[i])) {\n",
                                       "    needToIterate=1;\n",
                                       "  }\n",
                                       "}\n",
                                       "\n",
                                       "return needToIterate;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionCheckForDiscreteVarChanges;

protected function lm_130
  input Tpl.Text in_txt;
  input list<tuple<Integer, DAE.Exp>> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<tuple<Integer, DAE.Exp>> rest;
      Tpl.Text a_varDecls;
      Integer i_id;
      DAE.Exp i_e;
      Tpl.Text l_eRes;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           (i_id, i_e) :: rest,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_eRes, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, SimCode.contextSimulationNonDiscrete, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("storeDelayedExpression("));
        txt = Tpl.writeStr(txt, intString(i_id));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_eRes);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        (txt, a_varDecls) = lm_130(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_130(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_130;

protected function fun_131
  input Tpl.Text in_txt;
  input SimCode.DelayedExpression in_a_delayed;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_delayed, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      list<tuple<Integer, DAE.Exp>> i_delayedExps;

    case ( txt,
           SimCode.DELAYED_EXPRESSIONS(delayedExps = i_delayedExps),
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_130(txt, i_delayedExps, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_131;

protected function fun_132
  input Tpl.Text in_txt;
  input SimCode.DelayedExpression in_a_delayed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_delayed)
    local
      Tpl.Text txt;
      Integer i_maxDelayedIndex;

    case ( txt,
           SimCode.DELAYED_EXPRESSIONS(maxDelayedIndex = i_maxDelayedIndex) )
      equation
        txt = Tpl.writeStr(txt, intString(i_maxDelayedIndex));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_132;

public function functionStoreDelayed
  input Tpl.Text txt;
  input SimCode.DelayedExpression a_delayed;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_storePart;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  (l_storePart, l_varDecls) := fun_131(Tpl.emptyTxt, a_delayed, l_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("extern int const numDelayExpressionIndex = "));
  out_txt := fun_132(out_txt, a_delayed);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "int function_storeDelayed()\n",
                                       "{\n",
                                       "  state mem_state;\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_storePart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionStoreDelayed;

protected function lm_134
  input Tpl.Text in_txt;
  input list<BackendDAE.WhenOperator> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.WhenOperator> rest;
      Tpl.Text a_varDecls;
      BackendDAE.WhenOperator i_reinit;
      Tpl.Text l_body;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_reinit :: rest,
           a_varDecls )
      equation
        (l_body, a_varDecls) = functionWhenReinitStatement(Tpl.emptyTxt, i_reinit, a_varDecls);
        txt = Tpl.writeText(txt, l_body);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_134(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_134(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_134;

protected function lm_135
  input Tpl.Text in_txt;
  input list<SimCode.SimWhenClause> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimWhenClause> rest;
      Tpl.Text a_varDecls;
      Integer x_i0;
      list<BackendDAE.WhenOperator> i_reinits;
      Option<BackendDAE.WhenEquation> i_whenEq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           SimCode.SIM_WHEN_CLAUSE(whenEq = i_whenEq, reinits = i_reinits) :: rest,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(":\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        (txt, a_varDecls) = functionWhenCaseEquation(txt, i_whenEq, a_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_134(txt, i_reinits, a_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.popBlock(txt);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_135(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_135(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_135;

public function functionWhen
  input Tpl.Text txt;
  input list<SimCode.SimWhenClause> a_whenClauses;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_cases;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_cases := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_cases, l_varDecls) := lm_135(l_cases, a_whenClauses, l_varDecls);
  l_cases := Tpl.popIter(l_cases);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_when(int i)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n",
                                       "\n",
                                       "switch(i) {\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_cases);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "default:\n",
                                       "  break;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n",
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionWhen;

public function functionWhenCaseEquation
  input Tpl.Text in_txt;
  input Option<BackendDAE.WhenEquation> in_a_when;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_when, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_weq_left;
      DAE.Exp i_weq_right;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           SOME(BackendDAE.WHEN_EQ(right = i_weq_right, left = i_weq_left)),
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_weq_right, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("save("));
        txt = cref(txt, i_weq_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_weq_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end functionWhenCaseEquation;

public function functionWhenReinitStatement
  input Tpl.Text in_txt;
  input BackendDAE.WhenOperator in_a_reinit;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_reinit, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.Exp i_condition;
      DAE.Exp i_message;
      DAE.ComponentRef i_stateVar;
      DAE.Exp i_value;
      Tpl.Text l_msgVar;
      Tpl.Text l_val;
      Tpl.Text l_preExp;

    case ( txt,
           BackendDAE.REINIT(value = i_value, stateVar = i_stateVar),
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_val, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_value, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  "));
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_val);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.TERMINATE(message = i_message),
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_msgVar, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_message, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  MODELICA_TERMINATE("));
        txt = Tpl.writeText(txt, l_msgVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.ASSERT(condition = i_condition, message = i_message),
           a_varDecls )
      equation
        (txt, a_varDecls) = assertCommon(txt, i_condition, i_message, SimCode.contextSimulationDiscrete, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end functionWhenReinitStatement;

protected function lm_139
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Integer>> in_items;
  input Tpl.Text in_a_helpInits;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_helpInits;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_helpInits, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_helpInits, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<tuple<DAE.Exp, Integer>> rest;
      Tpl.Text a_helpInits;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Integer i_hidx;
      DAE.Exp i_e;
      Tpl.Text l_helpInit;

    case ( txt,
           {},
           a_helpInits,
           a_varDecls,
           a_preExp )
      then (txt, a_helpInits, a_varDecls, a_preExp);

    case ( txt,
           (i_e, i_hidx) :: rest,
           a_helpInits,
           a_varDecls,
           a_preExp )
      equation
        (l_helpInit, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, SimCode.contextSimulationDiscrete, a_preExp, a_varDecls);
        a_helpInits = Tpl.writeTok(a_helpInits, Tpl.ST_STRING("localData->helpVars["));
        a_helpInits = Tpl.writeStr(a_helpInits, intString(i_hidx));
        a_helpInits = Tpl.writeTok(a_helpInits, Tpl.ST_STRING("] = "));
        a_helpInits = Tpl.writeText(a_helpInits, l_helpInit);
        a_helpInits = Tpl.writeTok(a_helpInits, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hidx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        (txt, a_helpInits, a_varDecls, a_preExp) = lm_139(txt, rest, a_helpInits, a_varDecls, a_preExp);
      then (txt, a_helpInits, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_helpInits,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_helpInits, a_varDecls, a_preExp) = lm_139(txt, rest, a_helpInits, a_varDecls, a_preExp);
      then (txt, a_helpInits, a_varDecls, a_preExp);
  end matchcontinue;
end lm_139;

protected function fun_140
  input Tpl.Text in_txt;
  input list<BackendDAE.WhenOperator> in_a_reinits;
  input Tpl.Text in_a_ifthen;
  input Tpl.Text in_a_helpIf;
  input Tpl.Text in_a_helpInits;
  input Tpl.Text in_a_preExp;
  input Integer in_a_int;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_reinits, in_a_ifthen, in_a_helpIf, in_a_helpInits, in_a_preExp, in_a_int)
    local
      Tpl.Text txt;
      Tpl.Text a_ifthen;
      Tpl.Text a_helpIf;
      Tpl.Text a_helpInits;
      Tpl.Text a_preExp;
      Integer a_int;

    case ( txt,
           {},
           _,
           _,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           a_ifthen,
           a_helpIf,
           a_helpInits,
           a_preExp,
           a_int )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("//For whenclause index: "));
        txt = Tpl.writeStr(txt, intString(a_int));
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, a_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, a_helpInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, a_helpIf);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, a_ifthen);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_140;

public function genreinits
  input Tpl.Text in_txt;
  input SimCode.SimWhenClause in_a_whenClauses;
  input Tpl.Text in_a_varDecls;
  input Integer in_a_int;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_whenClauses, in_a_varDecls, in_a_int)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Integer a_int;
      list<BackendDAE.WhenOperator> i_reinits;
      list<tuple<DAE.Exp, Integer>> i_conditions;
      Tpl.Text l_ifthen;
      Tpl.Text l_helpIf;
      Tpl.Text l_helpInits;
      Tpl.Text l_preExp;

    case ( txt,
           SimCode.SIM_WHEN_CLAUSE(conditions = i_conditions, reinits = i_reinits),
           a_varDecls,
           a_int )
      equation
        l_preExp = Tpl.emptyTxt;
        l_helpInits = Tpl.emptyTxt;
        l_helpIf = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_helpIf, l_helpInits, a_varDecls, l_preExp) = lm_139(l_helpIf, i_conditions, l_helpInits, a_varDecls, l_preExp);
        l_helpIf = Tpl.popIter(l_helpIf);
        (l_ifthen, a_varDecls) = functionWhenReinitStatementThen(Tpl.emptyTxt, i_reinits, a_varDecls);
        txt = fun_140(txt, i_reinits, l_ifthen, l_helpIf, l_helpInits, l_preExp, a_int);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls,
           _ )
      then (txt, a_varDecls);
  end matchcontinue;
end genreinits;

protected function fun_142
  input Tpl.Text in_txt;
  input BackendDAE.WhenOperator in_a_reinit;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_reinit, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.Exp i_condition;
      DAE.Exp i_message;
      DAE.ComponentRef i_stateVar;
      DAE.Exp i_value;
      Tpl.Text l_msgVar;
      Tpl.Text l_val;
      Tpl.Text l_preExp;

    case ( txt,
           BackendDAE.REINIT(value = i_value, stateVar = i_stateVar),
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_val, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_value, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1));
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(6));
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_val);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "needToIterate=1;"
                                }, false));
        txt = Tpl.popBlock(txt);
        txt = Tpl.popBlock(txt);
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.TERMINATE(message = i_message),
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_msgVar, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_message, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(8));
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MODELICA_TERMINATE("));
        txt = Tpl.writeText(txt, l_msgVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.popBlock(txt);
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.ASSERT(condition = i_condition, message = i_message),
           a_varDecls )
      equation
        (txt, a_varDecls) = assertCommon(txt, i_condition, i_message, SimCode.contextSimulationDiscrete, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_142;

protected function lm_143
  input Tpl.Text in_txt;
  input list<BackendDAE.WhenOperator> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.WhenOperator> rest;
      Tpl.Text a_varDecls;
      BackendDAE.WhenOperator i_reinit;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_reinit :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = fun_142(txt, i_reinit, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_143(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_143(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_143;

public function functionWhenReinitStatementThen
  input Tpl.Text txt;
  input list<BackendDAE.WhenOperator> a_reinits;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_body;
algorithm
  l_body := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_body, out_a_varDecls) := lm_143(l_body, a_reinits, a_varDecls);
  l_body := Tpl.popIter(l_body);
  out_txt := Tpl.pushBlock(txt, Tpl.BT_INDENT(1));
  out_txt := Tpl.writeText(out_txt, l_body);
  out_txt := Tpl.popBlock(out_txt);
end functionWhenReinitStatementThen;

protected function fun_145
  input Tpl.Text in_txt;
  input BackendDAE.WhenOperator in_a_reinit;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_reinit, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.ComponentRef i_stateVar;
      DAE.Exp i_value;
      Tpl.Text l_val;

    case ( txt,
           BackendDAE.REINIT(value = i_value, stateVar = i_stateVar),
           a_varDecls,
           a_preExp )
      equation
        (l_val, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_value, SimCode.contextSimulationDiscrete, a_preExp, a_varDecls);
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = pre("));
        txt = cref(txt, i_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_145;

protected function lm_146
  input Tpl.Text in_txt;
  input list<BackendDAE.WhenOperator> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<BackendDAE.WhenOperator> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      BackendDAE.WhenOperator i_reinit;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_reinit :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = fun_145(txt, i_reinit, a_varDecls, a_preExp);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_146(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_146(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_146;

public function functionWhenReinitStatementElse
  input Tpl.Text txt;
  input list<BackendDAE.WhenOperator> a_reinits;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_body;
algorithm
  l_body := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_body, out_a_varDecls, out_a_preExp) := lm_146(l_body, a_reinits, a_varDecls, a_preExp);
  l_body := Tpl.popIter(l_body);
  out_txt := Tpl.pushBlock(txt, Tpl.BT_INDENT(1));
  out_txt := Tpl.writeText(out_txt, l_body);
  out_txt := Tpl.popBlock(out_txt);
end functionWhenReinitStatementElse;

protected function lm_148
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_148(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_148(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_148;

protected function lm_149
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls2;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls2;
algorithm
  (out_txt, out_a_varDecls2) :=
  matchcontinue(in_txt, in_items, in_a_varDecls2)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls2;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls2 )
      then (txt, a_varDecls2);

    case ( txt,
           i_eq :: rest,
           a_varDecls2 )
      equation
        (txt, a_varDecls2) = equation_(txt, i_eq, SimCode.contextInlineSolver, a_varDecls2);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls2) = lm_149(txt, rest, a_varDecls2);
      then (txt, a_varDecls2);

    case ( txt,
           _ :: rest,
           a_varDecls2 )
      equation
        (txt, a_varDecls2) = lm_149(txt, rest, a_varDecls2);
      then (txt, a_varDecls2);
  end matchcontinue;
end lm_149;

public function functionOde
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_stateContEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_stateContPartInline;
  Tpl.Text l_varDecls2;
  Tpl.Text l_stateContPart;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_stateContPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_stateContPart, l_varDecls) := lm_148(l_stateContPart, a_stateContEquations, l_varDecls);
  l_stateContPart := Tpl.popIter(l_stateContPart);
  l_varDecls2 := Tpl.emptyTxt;
  l_stateContPartInline := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_stateContPartInline, l_varDecls2) := lm_149(l_stateContPartInline, a_stateContEquations, l_varDecls2);
  l_stateContPartInline := Tpl.popIter(l_stateContPartInline);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionODE()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_stateContPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n",
                                       "#if defined(_OMC_ENABLE_INLINE)\n",
                                       "int functionODE_inline()\n",
                                       "{\n",
                                       "  state mem_state;\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls2);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n",
                                       "begin_inline();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_stateContPartInline);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "end_inline();\n",
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "#else\n",
                                       "int functionODE_inline()\n",
                                       "{\n",
                                       "  return 0;\n",
                                       "}\n",
                                       "#endif"
                                   }, false));
end functionOde;

protected function lm_151
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_151(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_151(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_151;

public function functionODE
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_derivativEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_odeEquations;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_odeEquations := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_odeEquations, l_varDecls) := lm_151(l_odeEquations, a_derivativEquations, l_varDecls);
  l_odeEquations := Tpl.popIter(l_odeEquations);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionODE_new()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_odeEquations);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionODE;

protected function lm_153
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_153(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_153(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_153;

public function functionAlgebraic
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_algebraicEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_algEquations;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_algEquations := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_algEquations, l_varDecls) := lm_153(l_algEquations, a_algebraicEquations, l_varDecls);
  l_algEquations := Tpl.popIter(l_algEquations);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for continuous time variables */\n",
                                   "int functionAlgebraics()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_algEquations);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionAlgebraic;

protected function lm_155
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_155(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_155(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_155;

public function functionAliasEquation
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_removedEquations;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_removedPart;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_removedPart := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_removedPart, l_varDecls) := lm_155(l_removedPart, a_removedEquations, l_varDecls);
  l_removedPart := Tpl.popIter(l_removedPart);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "/* for continuous time variables */\n",
                                   "int functionAliasEquations()\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_removedPart);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionAliasEquation;

public function functionODE_residual
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionODE_residual(double *t, double *x, double *xd, double *delta,\n",
                                   "                    fortran_integer *ires, double *rpar, fortran_integer *ipar)\n",
                                   "{\n",
                                   "  int i;\n",
                                   "  double temp_xd[NX];\n",
                                   "  double* statesBackup;\n",
                                   "  double* statesDerivativesBackup;\n",
                                   "  double timeBackup;\n",
                                   "\n",
                                   "  timeBackup = localData->timeValue;\n",
                                   "  statesBackup = localData->states;\n",
                                   "  statesDerivativesBackup = localData->statesDerivatives;\n",
                                   "\n",
                                   "  localData->timeValue = *t;\n",
                                   "  localData->states = x;\n",
                                   "  localData->statesDerivatives = temp_xd;\n",
                                   "\n",
                                   "  memcpy(localData->statesDerivatives, statesDerivativesBackup, localData->nStates*sizeof(double));\n",
                                   "\n",
                                   "  functionODE_new();\n",
                                   "\n",
                                   "  /* get the difference between the temp_xd(=localData->statesDerivatives)\n",
                                   "     and xd(=statesDerivativesBackup) */\n",
                                   "  for (i=0; i < localData->nStates; i++) {\n",
                                   "    delta[i] = localData->statesDerivatives[i] - statesDerivativesBackup[i];\n",
                                   "  }\n",
                                   "\n",
                                   "  localData->states = statesBackup;\n",
                                   "  localData->statesDerivatives = statesDerivativesBackup;\n",
                                   "  localData->timeValue = timeBackup;\n",
                                   "\n",
                                   "  if (modelErrorCode) {\n",
                                   "    if (ires) {\n",
                                   "      *ires = -1;\n",
                                   "    }\n",
                                   "    modelErrorCode =0;\n",
                                   "  }\n",
                                   "\n",
                                   "  return 0;\n",
                                   "}"
                               }, false));
end functionODE_residual;

protected function lm_158
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_158(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_158(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_158;

protected function lm_159
  input Tpl.Text in_txt;
  input list<SimCode.SimWhenClause> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimWhenClause> rest;
      Tpl.Text a_varDecls;
      Integer x_i0;
      SimCode.SimWhenClause i_when;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_when :: rest,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls) = genreinits(txt, i_when, a_varDecls, x_i0);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_159(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_159(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_159;

public function functionDAE
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_allEquationsPlusWhen;
  input list<SimCode.SimWhenClause> a_whenClauses;
  input list<SimCode.HelpVarInfo> a_helpVarInfo;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_reinit;
  Tpl.Text l_eqs;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_eqs := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_eqs, l_varDecls) := lm_158(l_eqs, a_allEquationsPlusWhen, l_varDecls);
  l_eqs := Tpl.popIter(l_eqs);
  l_reinit := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_reinit, l_varDecls) := lm_159(l_reinit, a_whenClauses, l_varDecls);
  l_reinit := Tpl.popIter(l_reinit);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int functionDAE(int &needToIterate)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "needToIterate = 0;\n",
                                       "inUpdate=initial()?0:1;\n",
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_eqs);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_reinit);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "inUpdate=0;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionDAE;

public function functionOnlyZeroCrossing
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_zeroCrossingsCode;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  (l_zeroCrossingsCode, l_varDecls) := zeroCrossingsTpl(Tpl.emptyTxt, a_zeroCrossings, l_varDecls);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int function_onlyZeroCrossings(double *gout,double *t)\n",
                                   "{\n",
                                   "  state mem_state;\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_zeroCrossingsCode);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionOnlyZeroCrossing;

protected function lm_162
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (change("));
        txt = cref(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) { needToIterate=1; }"));
        txt = Tpl.nextIter(txt);
        txt = lm_162(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_162(txt, rest);
      then txt;
  end matchcontinue;
end lm_162;

public function functionCheckForDiscreteChanges
  input Tpl.Text txt;
  input list<DAE.ComponentRef> a_discreteModelVars;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "int checkForDiscreteChanges()\n",
                                   "{\n",
                                   "  int needToIterate = 0;\n",
                                   "\n"
                               }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_162(out_txt, a_discreteModelVars);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "return needToIterate;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionCheckForDiscreteChanges;

protected function lm_164
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_eq;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_eq :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = equation_(txt, i_eq, SimCode.contextSimulationNonDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_164(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_164(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_164;

protected function lm_165
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = defvars(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_165(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_165(txt, rest);
      then txt;
  end matchcontinue;
end lm_165;

protected function lm_166
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = writejac(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_166(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_166(txt, rest);
      then txt;
  end matchcontinue;
end lm_166;

public function functionJac
  input Tpl.Text txt;
  input list<SimCode.SimEqSystem> a_JacEquations;
  input list<SimCode.SimVar> a_JacVars;
  input String a_MatrixName;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_writeJac__;
  Tpl.Text l_Vars__;
  Tpl.Text l_Equations__;
  Tpl.Text l_varDecls;
algorithm
  l_varDecls := Tpl.emptyTxt;
  l_Equations__ := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_Equations__, l_varDecls) := lm_164(l_Equations__, a_JacEquations, l_varDecls);
  l_Equations__ := Tpl.popIter(l_Equations__);
  l_Vars__ := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  l_Vars__ := lm_165(l_Vars__, a_JacVars);
  l_Vars__ := Tpl.popIter(l_Vars__);
  l_writeJac__ := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  l_writeJac__ := lm_166(l_writeJac__, a_JacVars);
  l_writeJac__ := Tpl.popIter(l_writeJac__);
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("int functionJac"));
  out_txt := Tpl.writeStr(out_txt, a_MatrixName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "(double *t, double *x, double *xd, double *jac)\n",
                                       "{\n",
                                       "    state mem_state;\n",
                                       "\n",
                                       "    double* statesBackup;\n",
                                       "    double* statesDerivativesBackup;\n",
                                       "    double timeBackup;\n",
                                       "\n",
                                       "    timeBackup = localData->timeValue;\n",
                                       "    statesBackup = localData->states;\n",
                                       "    statesDerivativesBackup = localData->statesDerivatives;\n",
                                       "    localData->timeValue = *t;\n",
                                       "    localData->states = x;\n",
                                       "    localData->statesDerivatives = xd;\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_Vars__);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "mem_state = get_memory_state();\n"
                                   }, true));
  out_txt := Tpl.writeText(out_txt, l_Equations__);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_writeJac__);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "restore_memory_state(mem_state);\n",
                                       "\n",
                                       "localData->states = statesBackup;\n",
                                       "  localData->statesDerivatives = statesDerivativesBackup;\n",
                                       "  localData->timeValue = timeBackup;\n",
                                       "\n",
                                       "return 0;\n"
                                   }, true));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n"
                                   }, true));
end functionJac;

public function defvars
  input Tpl.Text in_txt;
  input SimCode.SimVar in_a_item;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_item)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_name;

    case ( txt,
           SimCode.SIMVAR(name = i_name) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("double "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end defvars;

protected function fun_169
  input Tpl.Text in_txt;
  input Integer in_a_index;
  input DAE.ComponentRef in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_index, in_a_name)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_name;
      Integer i_index;

    case ( txt,
           -1,
           _ )
      then txt;

    case ( txt,
           i_index,
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("jac["));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;
  end matchcontinue;
end fun_169;

public function writejac
  input Tpl.Text in_txt;
  input SimCode.SimVar in_a_item;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_item)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_name;
      Integer i_index;

    case ( txt,
           SimCode.SIMVAR(name = i_name, index = i_index) )
      equation
        txt = fun_169(txt, i_index, i_name);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end writejac;

public function functionlinearmodel
  input Tpl.Text in_txt;
  input SimCode.ModelInfo in_a_modelInfo;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_modelInfo)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_vars_outputVars;
      list<SimCode.SimVar> i_vars_inputVars;
      list<SimCode.SimVar> i_vars_stateVars;
      Absyn.Path i_name;
      Integer i_varInfo_numOutVars;
      Integer i_varInfo_numInVars;
      Integer i_varInfo_numStateVars;
      Tpl.Text l_vectorY;
      Tpl.Text l_vectorU;
      Tpl.Text l_vectorX;
      Tpl.Text l_matrixD;
      Tpl.Text l_matrixC;
      Tpl.Text l_matrixB;
      Tpl.Text l_matrixA;

    case ( txt,
           SimCode.MODELINFO(varInfo = SimCode.VARINFO(numStateVars = i_varInfo_numStateVars, numInVars = i_varInfo_numInVars, numOutVars = i_varInfo_numOutVars), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, inputVars = i_vars_inputVars, outputVars = i_vars_outputVars), name = i_name) )
      equation
        l_matrixA = genMatrix(Tpl.emptyTxt, "A", i_varInfo_numStateVars, i_varInfo_numStateVars);
        l_matrixB = genMatrix(Tpl.emptyTxt, "B", i_varInfo_numStateVars, i_varInfo_numInVars);
        l_matrixC = genMatrix(Tpl.emptyTxt, "C", i_varInfo_numOutVars, i_varInfo_numStateVars);
        l_matrixD = genMatrix(Tpl.emptyTxt, "D", i_varInfo_numOutVars, i_varInfo_numInVars);
        l_vectorX = genVector(Tpl.emptyTxt, "x", i_varInfo_numStateVars, 0);
        l_vectorU = genVector(Tpl.emptyTxt, "u", i_varInfo_numInVars, 1);
        l_vectorY = genVector(Tpl.emptyTxt, "y", i_varInfo_numOutVars, 2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "int linear_model_frame(string &out, string A, string B, string C, string D, string x_startvalues, string u_startvalues)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_head(\"model linear_"));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\\n  parameter Integer n = "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStateVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; // states \\n  parameter Integer k = "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numInVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; // top-level inputs \\n  parameter Integer l = "));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numOutVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "; // top-level outputs \\n\");\n",
                                    "\n",
                                    "string def_init_states(\"  parameter Real x0["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numStateVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "] = {\");\n",
                                    "string def_init_states_end(\"};\\n\");\n",
                                    "\n",
                                    "string def_init_inputs(\"  parameter Real u0["
                                }, false));
        txt = Tpl.writeStr(txt, intString(i_varInfo_numInVars));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "] = {\");\n",
                                    "string def_init_inputs_end(\"};\\n\");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, l_vectorX);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_vectorU);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_vectorY);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_matrixA);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_matrixB);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_matrixC);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_matrixD);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "string def_Variable(\"\\n  "
                                }, false));
        txt = getVarName(txt, i_vars_stateVars, "x", i_varInfo_numStateVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  "));
        txt = getVarName(txt, i_vars_inputVars, "u", i_varInfo_numInVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("  "));
        txt = getVarName(txt, i_vars_outputVars, "y", i_varInfo_numOutVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\\n\");\n",
                                    "\n",
                                    "string def_tail(\"equation\\n  der(x) = A * x + B * u;\\n  y = C * x + D * u;\\nend linear_"
                                }, false));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\\n\");\n",
                                    "\n",
                                    "out += def_head.data();\n",
                                    "out += def_init_states.data();\n",
                                    "out += x_startvalues.data();\n",
                                    "out += def_init_states_end.data();\n",
                                    "out += def_init_inputs.data();\n",
                                    "out += u_startvalues.data();\n",
                                    "out += def_init_inputs_end.data();\n",
                                    "out += def_matrixA_start.data();\n",
                                    "out += A.data();\n",
                                    "out += def_matrixA_end.data();\n",
                                    "out += def_matrixB_start.data();\n",
                                    "out += B.data();\n",
                                    "out += def_matrixB_end.data();\n",
                                    "out += def_matrixC_start.data();\n",
                                    "out += C.data();\n",
                                    "out += def_matrixC_end.data();\n",
                                    "out += def_matrixD_start.data();\n",
                                    "out += D.data();\n",
                                    "out += def_matrixD_end.data();\n",
                                    "out += def_vectorx.data();\n",
                                    "out += def_vectoru.data();\n",
                                    "out += def_vectory.data();\n",
                                    "out += def_Variable.data();\n",
                                    "out += def_tail.data();\n",
                                    "return 0;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionlinearmodel;

protected function fun_172
  input Tpl.Text in_txt;
  input SimCode.SimVar in_a_var;
  input Tpl.Text in_a_rest;
  input Tpl.Text in_a_arrindex;
  input String in_a_arrayName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var, in_a_rest, in_a_arrindex, in_a_arrayName)
    local
      Tpl.Text txt;
      Tpl.Text a_rest;
      Tpl.Text a_arrindex;
      String a_arrayName;
      DAE.ComponentRef i_name;

    case ( txt,
           SimCode.SIMVAR(name = i_name),
           a_rest,
           a_arrindex,
           a_arrayName )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Real "));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = crefM(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, a_arrayName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeText(txt, a_arrindex);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n  "));
        txt = Tpl.writeText(txt, a_rest);
      then txt;

    case ( txt,
           _,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_172;

public function getVarName
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_a_simVars;
  input String in_a_arrayName;
  input Integer in_a_arraySize;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simVars, in_a_arrayName, in_a_arraySize)
    local
      Tpl.Text txt;
      String a_arrayName;
      Integer a_arraySize;
      SimCode.SimVar i_var;
      list<SimCode.SimVar> i_restVars;
      Integer ret_3;
      Integer ret_2;
      Tpl.Text l_arrindex;
      Tpl.Text l_rest;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           i_var :: i_restVars,
           a_arrayName,
           a_arraySize )
      equation
        l_rest = getVarName(Tpl.emptyTxt, i_restVars, a_arrayName, a_arraySize);
        ret_2 = listLength(i_restVars);
        ret_3 = SimCode.decrementInt(a_arraySize, ret_2);
        l_arrindex = Tpl.writeStr(Tpl.emptyTxt, intString(ret_3));
        txt = fun_172(txt, i_var, l_rest, l_arrindex, a_arrayName);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end getVarName;

protected function fun_174
  input Tpl.Text in_txt;
  input Integer in_a_col;
  input Integer in_a_row;
  input String in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_col, in_a_row, in_a_name)
    local
      Tpl.Text txt;
      Integer a_row;
      String a_name;
      Integer i_col;

    case ( txt,
           (i_col as 0),
           a_row,
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_matrix"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_start(\"  parameter Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(a_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = zeros("));
        txt = Tpl.writeStr(txt, intString(a_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\\n\");\n",
                                    "string def_matrix"
                                }, false));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_end(\"\");"));
      then txt;

    case ( txt,
           i_col,
           a_row,
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_matrix"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_start(\"  parameter Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(a_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "] = [\");\n",
                                    "string def_matrix"
                                }, false));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_end(\"];\\n\");"));
      then txt;
  end matchcontinue;
end fun_174;

protected function fun_175
  input Tpl.Text in_txt;
  input Integer in_a_row;
  input String in_a_name;
  input Integer in_a_col;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_row, in_a_name, in_a_col)
    local
      Tpl.Text txt;
      String a_name;
      Integer a_col;
      Integer i_row;

    case ( txt,
           (i_row as 0),
           a_name,
           a_col )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_matrix"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_start(\"  parameter Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(a_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = zeros("));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(a_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\\n\");\n",
                                    "string def_matrix"
                                }, false));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_end(\"\");"));
      then txt;

    case ( txt,
           i_row,
           a_name,
           a_col )
      equation
        txt = fun_174(txt, a_col, i_row, a_name);
      then txt;
  end matchcontinue;
end fun_175;

public function genMatrix
  input Tpl.Text txt;
  input String a_name;
  input Integer a_row;
  input Integer a_col;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_175(txt, a_row, a_name, a_col);
end genMatrix;

protected function fun_177
  input Tpl.Text in_txt;
  input Integer in_a_numIn;
  input String in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_numIn, in_a_name)
    local
      Tpl.Text txt;
      String a_name;
      Integer i_numIn;

    case ( txt,
           (i_numIn as 0),
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;

    case ( txt,
           i_numIn,
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("](start="));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0);\\n\");"));
      then txt;
  end matchcontinue;
end fun_177;

protected function fun_178
  input Tpl.Text in_txt;
  input Integer in_a_numIn;
  input String in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_numIn, in_a_name)
    local
      Tpl.Text txt;
      String a_name;
      Integer i_numIn;

    case ( txt,
           (i_numIn as 0),
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  input Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;

    case ( txt,
           i_numIn,
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  input Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("](start= "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0);\\n\");"));
      then txt;
  end matchcontinue;
end fun_178;

protected function fun_179
  input Tpl.Text in_txt;
  input Integer in_a_numIn;
  input String in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_numIn, in_a_name)
    local
      Tpl.Text txt;
      String a_name;
      Integer i_numIn;

    case ( txt,
           (i_numIn as 0),
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  output Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;

    case ( txt,
           i_numIn,
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string def_vector"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(\"  output Real "));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeStr(txt, intString(i_numIn));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];\\n\");"));
      then txt;
  end matchcontinue;
end fun_179;

protected function fun_180
  input Tpl.Text in_txt;
  input Integer in_a_flag;
  input String in_a_name;
  input Integer in_a_numIn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag, in_a_name, in_a_numIn)
    local
      Tpl.Text txt;
      String a_name;
      Integer a_numIn;

    case ( txt,
           0,
           a_name,
           a_numIn )
      equation
        txt = fun_177(txt, a_numIn, a_name);
      then txt;

    case ( txt,
           1,
           a_name,
           a_numIn )
      equation
        txt = fun_178(txt, a_numIn, a_name);
      then txt;

    case ( txt,
           2,
           a_name,
           a_numIn )
      equation
        txt = fun_179(txt, a_numIn, a_name);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_180;

public function genVector
  input Tpl.Text txt;
  input String a_name;
  input Integer a_numIn;
  input Integer a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_180(txt, a_flag, a_name, a_numIn);
end genVector;

protected function lm_182
  input Tpl.Text in_txt;
  input list<SimCode.JacobianMatrix> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.JacobianMatrix> rest;
      String i_name;
      list<SimCode.SimVar> i_vars;
      list<SimCode.SimEqSystem> i_eqs;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_eqs, i_vars, i_name) :: rest )
      equation
        txt = functionJac(txt, i_eqs, i_vars, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_182(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_182(txt, rest);
      then txt;
  end matchcontinue;
end lm_182;

public function generateLinearMatrixes
  input Tpl.Text txt;
  input list<SimCode.JacobianMatrix> a_JacobianMatrixes;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_jacMats;
algorithm
  l_jacMats := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  l_jacMats := lm_182(l_jacMats, a_JacobianMatrixes);
  l_jacMats := Tpl.popIter(l_jacMats);
  out_txt := Tpl.writeText(txt, l_jacMats);
end generateLinearMatrixes;

protected function lm_184
  input Tpl.Text in_txt;
  input list<BackendDAE.ZeroCrossing> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.ZeroCrossing> rest;
      Tpl.Text a_varDecls;
      Integer x_i0;
      DAE.Exp i_relation__;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.ZERO_CROSSING(relation_ = i_relation__) :: rest,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls) = zeroCrossingTpl(txt, x_i0, i_relation__, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_184(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_184(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_184;

public function zeroCrossingsTpl
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls) := lm_184(out_txt, a_zeroCrossings, a_varDecls);
  out_txt := Tpl.popIter(out_txt);
end zeroCrossingsTpl;

protected function fun_186
  input Tpl.Text in_txt;
  input DAE.Exp in_a_relation;
  input Integer in_a_index;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_relation, in_a_index, in_a_varDecls)
    local
      Tpl.Text txt;
      Integer a_index;
      Tpl.Text a_varDecls;
      DAE.Exp i_interval;
      DAE.Exp i_start;
      DAE.Exp i_exp2;
      DAE.Operator i_operator;
      DAE.Exp i_exp1;
      Tpl.Text l_e2;
      Tpl.Text l_op;
      Tpl.Text l_e1;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.RELATION(exp1 = i_exp1, operator = i_operator, exp2 = i_exp2),
           a_index,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_e1, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp1, SimCode.contextOther, l_preExp, a_varDecls);
        l_op = zeroCrossingOpFunc(Tpl.emptyTxt, i_operator);
        (l_e2, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp2, SimCode.contextOther, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZEROCROSSING("));
        txt = Tpl.writeStr(txt, intString(a_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_op);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then (txt, a_varDecls);

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval}),
           a_index,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_e1, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_start, SimCode.contextOther, l_preExp, a_varDecls);
        (l_e2, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_interval, SimCode.contextOther, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZEROCROSSING("));
        txt = Tpl.writeStr(txt, intString(a_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",Sample(*t,"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZERO CROSSING ERROR"));
      then (txt, a_varDecls);
  end matchcontinue;
end fun_186;

public function zeroCrossingTpl
  input Tpl.Text txt;
  input Integer a_index;
  input DAE.Exp a_relation;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) := fun_186(txt, a_relation, a_index, a_varDecls);
end zeroCrossingTpl;

protected function lm_188
  input Tpl.Text in_txt;
  input list<BackendDAE.ZeroCrossing> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<BackendDAE.ZeroCrossing> rest;
      Tpl.Text a_varDecls;
      Integer x_i0;
      DAE.Exp i_relation__;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           BackendDAE.ZERO_CROSSING(relation_ = i_relation__) :: rest,
           a_varDecls )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls) = timeEventTpl(txt, x_i0, i_relation__, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_188(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_188(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_188;

public function timeEventsTpl
  input Tpl.Text txt;
  input list<BackendDAE.ZeroCrossing> a_zeroCrossings;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varDecls) := lm_188(out_txt, a_zeroCrossings, a_varDecls);
  out_txt := Tpl.popIter(out_txt);
end timeEventsTpl;

protected function fun_190
  input Tpl.Text in_txt;
  input DAE.Exp in_a_relation;
  input Integer in_a_index;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_relation, in_a_index, in_a_varDecls)
    local
      Tpl.Text txt;
      Integer a_index;
      Tpl.Text a_varDecls;
      DAE.Exp i_interval;
      DAE.Exp i_start;
      Tpl.Text l_e2;
      Tpl.Text l_e1;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.RELATION(exp1 = _),
           a_index,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* "));
        txt = Tpl.writeStr(txt, intString(a_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" Not a time event */"));
      then (txt, a_varDecls);

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst = {i_start, i_interval}),
           a_index,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_e1, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_start, SimCode.contextOther, l_preExp, a_varDecls);
        (l_e2, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_interval, SimCode.contextOther, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->rawSampleExps[i].start = "));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "localData->rawSampleExps[i].interval = "
                                }, false));
        txt = Tpl.writeText(txt, l_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "localData->rawSampleExps[i++].zc_index = "
                                }, false));
        txt = Tpl.writeStr(txt, intString(a_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ZERO CROSSING ERROR"));
      then (txt, a_varDecls);
  end matchcontinue;
end fun_190;

public function timeEventTpl
  input Tpl.Text txt;
  input Integer a_index;
  input DAE.Exp a_relation;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) := fun_190(txt, a_relation, a_index, a_varDecls);
end timeEventTpl;

public function zeroCrossingOpFunc
  input Tpl.Text in_txt;
  input DAE.Operator in_a_op;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_op)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.LESS(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Less"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("Greater"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LessEq"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("GreaterEq"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end zeroCrossingOpFunc;

public function equation_
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      SimCode.SimEqSystem i_e;

    case ( txt,
           (i_e as SimCode.SES_SIMPLE_ASSIGN(cref = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = equationSimpleAssign(txt, i_e, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_e as SimCode.SES_ARRAY_CALL_ASSIGN(componentRef = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = equationArrayCallAssign(txt, i_e, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_e as SimCode.SES_ALGORITHM(statements = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = equationAlgorithm(txt, i_e, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_e as SimCode.SES_LINEAR(partOfMixed = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = equationLinear(txt, i_e, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_e as SimCode.SES_MIXED(cont = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = equationMixed(txt, i_e, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_e as SimCode.SES_NONLINEAR(index = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = equationNonlinear(txt, i_e, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_e as SimCode.SES_WHEN(left = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = equationWhen(txt, i_e, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED EQUATION"));
      then (txt, a_varDecls);
  end matchcontinue;
end equation_;

protected function fun_194
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_c;
  input String in_a_arr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_c, in_a_arr)
    local
      Tpl.Text txt;
      String a_arr;
      DAE.ComponentRef i_c;

    case ( txt,
           (i_c as DAE.CREF_QUAL(ident = "$DER")),
           a_arr )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "inline_integrate_array(size_of_dimension_real_array("
                                }, false));
        txt = Tpl.writeStr(txt, a_arr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",1),"));
        txt = cref(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_194;

public function inlineArray
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input String in_a_arr;
  input DAE.ComponentRef in_a_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_arr, in_a_c)
    local
      Tpl.Text txt;
      String a_arr;
      DAE.ComponentRef a_c;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           a_arr,
           a_c )
      equation
        txt = fun_194(txt, a_c, a_arr);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineArray;

protected function fun_196
  input Tpl.Text in_txt;
  input SimCode.SimVar in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           SimCode.SIMVAR(name = (i_cr as DAE.CREF_QUAL(ident = "$DER"))) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("inline_integrate("));
        txt = cref(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_196;

protected function lm_197
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      SimCode.SimVar i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = fun_196(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_197(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_197(txt, rest);
      then txt;
  end matchcontinue;
end lm_197;

protected function fun_198
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_a_simvars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simvars)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_simvars;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_simvars )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_197(txt, i_simvars);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_198;

public function inlineVars
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input list<SimCode.SimVar> in_a_simvars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_simvars)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> a_simvars;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           a_simvars )
      equation
        txt = fun_198(txt, a_simvars);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineVars;

protected function fun_200
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           (i_cr as DAE.CREF_QUAL(ident = "$DER")) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("inline_integrate("));
        txt = cref(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_200;

protected function lm_201
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef i_cr;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_cr :: rest )
      equation
        txt = fun_200(txt, i_cr);
        txt = Tpl.nextIter(txt);
        txt = lm_201(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_201(txt, rest);
      then txt;
  end matchcontinue;
end lm_201;

protected function fun_202
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_a_crefs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_crefs)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> i_crefs;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_crefs )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_201(txt, i_crefs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_202;

public function inlineCrefs
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input list<DAE.ComponentRef> in_a_crefs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_crefs)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> a_crefs;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           a_crefs )
      equation
        txt = fun_202(txt, a_crefs);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineCrefs;

protected function fun_204
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           (i_cr as DAE.CREF_QUAL(ident = "$DER")) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "inline_integrate("
                                }, false));
        txt = cref(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_204;

public function inlineCref
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_cr;

    case ( txt,
           SimCode.INLINE_CONTEXT(),
           a_cr )
      equation
        txt = fun_204(txt, a_cr);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end inlineCref;

public function equationSimpleAssign
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_cref;
      DAE.Exp i_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(exp = i_exp, cref = i_cref),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = inlineCref(txt, a_context, i_cref);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end equationSimpleAssign;

protected function fun_207
  input Tpl.Text in_txt;
  input String in_mArg;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_eqn_componentRef;
  input Tpl.Text in_a_expPart;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_context, in_a_eqn_componentRef, in_a_expPart, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      DAE.ComponentRef a_eqn_componentRef;
      Tpl.Text a_expPart;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      Tpl.Text l_tvar;

    case ( txt,
           "boolean",
           a_context,
           a_eqn_componentRef,
           a_expPart,
           a_preExp,
           a_varDecls )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "boolean_array", a_varDecls);
        txt = Tpl.writeText(txt, a_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_boolean_array_data_mem(&"));
        txt = Tpl.writeText(txt, a_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = cref(txt, a_eqn_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = inlineArray(txt, a_context, Tpl.textString(l_tvar), a_eqn_componentRef);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           "integer",
           a_context,
           a_eqn_componentRef,
           a_expPart,
           a_preExp,
           a_varDecls )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "integer_array", a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("cast_integer_array_to_real(&"));
        a_preExp = Tpl.writeText(a_preExp, a_expPart);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, a_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_integer_array_data_mem(&"));
        txt = Tpl.writeText(txt, a_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = cref(txt, a_eqn_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = inlineArray(txt, a_context, Tpl.textString(l_tvar), a_eqn_componentRef);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           "real",
           a_context,
           a_eqn_componentRef,
           a_expPart,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeText(txt, a_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_real_array_data_mem(&"));
        txt = Tpl.writeText(txt, a_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = cref(txt, a_eqn_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = inlineArray(txt, a_context, Tpl.textString(a_expPart), a_eqn_componentRef);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#error \"No runtime support for this sort of array call\""));
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_207;

public function equationArrayCallAssign
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_eqn_componentRef;
      DAE.Exp i_eqn_exp;
      DAE.Exp i_exp;
      String str_3;
      Tpl.Text txt_2;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           SimCode.SES_ARRAY_CALL_ASSIGN(exp = (i_eqn_exp as i_exp), componentRef = i_eqn_componentRef),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt_2 = expTypeFromExpShort(Tpl.emptyTxt, i_eqn_exp);
        str_3 = Tpl.textString(txt_2);
        (txt, l_preExp, a_varDecls) = fun_207(txt, str_3, a_context, i_eqn_componentRef, l_expPart, l_preExp, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end equationArrayCallAssign;

protected function lm_209
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_209(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_209(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_209;

public function equationAlgorithm
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<DAE.Statement> i_statements;

    case ( txt,
           SimCode.SES_ALGORITHM(statements = i_statements),
           a_context,
           a_varDecls )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_209(txt, i_statements, a_varDecls, a_context);
        txt = Tpl.popIter(txt);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end equationAlgorithm;

protected function fun_211
  input Tpl.Text in_txt;
  input Boolean in_a_partOfMixed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_partOfMixed)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_mixed"));
      then txt;
  end matchcontinue;
end fun_211;

protected function lm_212
  input Tpl.Text in_txt;
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> in_items;
  input Tpl.Text in_a_size;
  input Tpl.Text in_a_aname;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_size, in_a_aname, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> rest;
      Tpl.Text a_size;
      Tpl.Text a_aname;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      Integer i_col;
      Integer i_row;
      DAE.Exp i_eq_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           _,
           _,
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           (i_row, i_col, SimCode.SES_RESIDUAL(exp = i_eq_exp)) :: rest,
           a_size,
           a_aname,
           a_varDecls,
           a_context )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_eq_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("set_matrix_elt("));
        txt = Tpl.writeText(txt, a_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_row));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_col));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_212(txt, rest, a_size, a_aname, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_size,
           a_aname,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_212(txt, rest, a_size, a_aname, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_212;

protected function lm_213
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_bname;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_bname, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_bname;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      Integer x_i0;
      DAE.Exp i_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           {},
           _,
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_exp :: rest,
           a_bname,
           a_varDecls,
           a_context )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("set_vector_elt("));
        txt = Tpl.writeText(txt, a_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_213(txt, rest, a_bname, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_bname,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_213(txt, rest, a_bname, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_213;

protected function lm_214
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;
  input Tpl.Text in_a_bname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_bname)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Tpl.Text a_bname;
      Integer x_i0;
      DAE.ComponentRef i_name;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest,
           a_bname )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_vector_elt("));
        txt = Tpl.writeText(txt, a_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        txt = lm_214(txt, rest, a_bname);
      then txt;

    case ( txt,
           _ :: rest,
           a_bname )
      equation
        txt = lm_214(txt, rest, a_bname);
      then txt;
  end matchcontinue;
end lm_214;

public function equationLinear
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<DAE.Exp> i_beqs;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> i_simJac;
      Boolean i_partOfMixed;
      list<SimCode.SimVar> i_vars;
      Tpl.Text l_mixedPostfix;
      Tpl.Text l_bname;
      Tpl.Text l_aname;
      Integer ret_3;
      Tpl.Text l_size;
      Integer ret_1;
      Tpl.Text l_uid;

    case ( txt,
           SimCode.SES_LINEAR(vars = i_vars, partOfMixed = i_partOfMixed, simJac = i_simJac, beqs = i_beqs),
           a_context,
           a_varDecls )
      equation
        ret_1 = System.tmpTick();
        l_uid = Tpl.writeStr(Tpl.emptyTxt, intString(ret_1));
        ret_3 = listLength(i_vars);
        l_size = Tpl.writeStr(Tpl.emptyTxt, intString(ret_3));
        l_aname = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("A"));
        l_aname = Tpl.writeText(l_aname, l_uid);
        l_bname = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("b"));
        l_bname = Tpl.writeText(l_bname, l_uid);
        l_mixedPostfix = fun_211(Tpl.emptyTxt, i_partOfMixed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("declare_matrix("));
        txt = Tpl.writeText(txt, l_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "declare_vector("
                                }, false));
        txt = Tpl.writeText(txt, l_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_size);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_212(txt, i_simJac, l_size, l_aname, a_varDecls, a_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_213(txt, i_beqs, l_bname, a_varDecls, a_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("solve_linear_equation_system"));
        txt = Tpl.writeText(txt, l_mixedPostfix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_aname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_bname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_size);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_uid);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_214(txt, i_vars, l_bname);
        txt = Tpl.popIter(txt);
        txt = inlineVars(txt, a_context, i_vars);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end equationLinear;

protected function lm_216
  input Tpl.Text in_txt;
  input list<SimCode.SimEqSystem> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preDisc;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preDisc;
algorithm
  (out_txt, out_a_varDecls, out_a_preDisc) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preDisc, in_a_context)
    local
      Tpl.Text txt;
      list<SimCode.SimEqSystem> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preDisc;
      SimCode.Context a_context;
      Integer x_i0;
      DAE.ComponentRef i_cref;
      DAE.Exp i_exp;
      Tpl.Text l_expPart;

    case ( txt,
           {},
           a_varDecls,
           a_preDisc,
           _ )
      then (txt, a_varDecls, a_preDisc);

    case ( txt,
           SimCode.SES_SIMPLE_ASSIGN(exp = i_exp, cref = i_cref) :: rest,
           a_varDecls,
           a_preDisc,
           a_context )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        (l_expPart, a_preDisc, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, a_preDisc, a_varDecls);
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "discrete_loc2["
                                }, false));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, i_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preDisc) = lm_216(txt, rest, a_varDecls, a_preDisc, a_context);
      then (txt, a_varDecls, a_preDisc);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preDisc,
           a_context )
      equation
        (txt, a_varDecls, a_preDisc) = lm_216(txt, rest, a_varDecls, a_preDisc, a_context);
      then (txt, a_varDecls, a_preDisc);
  end matchcontinue;
end lm_216;

protected function lm_217
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<Integer> rest;
      Integer i_it;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
        txt = lm_217(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_217(txt, rest);
      then txt;
  end matchcontinue;
end lm_217;

protected function lm_218
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<Integer> rest;
      Integer i_it;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      equation
        txt = Tpl.writeStr(txt, intString(i_it));
        txt = Tpl.nextIter(txt);
        txt = lm_218(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_218(txt, rest);
      then txt;
  end matchcontinue;
end lm_218;

protected function lm_219
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      Integer x_i0;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("discrete_loc["));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_219(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_219(txt, rest);
      then txt;
  end matchcontinue;
end lm_219;

protected function lm_220
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(name = i_name) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(double*)&"));
        txt = cref(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_220(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_220(txt, rest);
      then txt;
  end matchcontinue;
end lm_220;

public function equationMixed
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<Integer> i_value__dims;
      list<SimCode.SimEqSystem> i_discEqs;
      list<Integer> i_values;
      list<SimCode.SimVar> i_discVars;
      SimCode.SimEqSystem i_cont;
      Tpl.Text l_discLoc2;
      Tpl.Text l_preDisc;
      Integer ret_4;
      Tpl.Text l_valuesLenStr;
      Integer ret_2;
      Tpl.Text l_numDiscVarsStr;
      Tpl.Text l_contEqs;

    case ( txt,
           SimCode.SES_MIXED(cont = i_cont, discVars = i_discVars, values = i_values, discEqs = i_discEqs, value_dims = i_value__dims),
           a_context,
           a_varDecls )
      equation
        (l_contEqs, a_varDecls) = equation_(Tpl.emptyTxt, i_cont, a_context, a_varDecls);
        ret_2 = listLength(i_discVars);
        l_numDiscVarsStr = Tpl.writeStr(Tpl.emptyTxt, intString(ret_2));
        ret_4 = listLength(i_values);
        l_valuesLenStr = Tpl.writeStr(Tpl.emptyTxt, intString(ret_4));
        l_preDisc = Tpl.emptyTxt;
        l_discLoc2 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_discLoc2, a_varDecls, l_preDisc) = lm_216(l_discLoc2, i_discEqs, a_varDecls, l_preDisc, a_context);
        l_discLoc2 = Tpl.popIter(l_discLoc2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mixed_equation_system("));
        txt = Tpl.writeText(txt, l_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "double values["
                                }, false));
        txt = Tpl.writeText(txt, l_valuesLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_217(txt, i_values);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "int value_dims["
                                }, false));
        txt = Tpl.writeText(txt, l_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_218(txt, i_value__dims);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("};\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_219(txt, i_discVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("{\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_contEqs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, l_preDisc);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_discLoc2);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("{\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("double *loc_ptrs["));
        txt = Tpl.writeText(txt, l_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = {"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_220(txt, i_discVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "};\n",
                                    "check_discrete_values("
                                }, false));
        txt = Tpl.writeText(txt, l_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_valuesLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "mixed_equation_system_end("
                                }, false));
        txt = Tpl.writeText(txt, l_numDiscVarsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end equationMixed;

protected function lm_222
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> rest;
      Integer x_i0;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("nls_x["));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = extraPolate("));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "nls_xold["
                                }, false));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = $P$old"));
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_222(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_222(txt, rest);
      then txt;
  end matchcontinue;
end lm_222;

protected function lm_223
  input Tpl.Text in_txt;
  input list<DAE.ComponentRef> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.ComponentRef> rest;
      Integer x_i0;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt = cref(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = nls_x["));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("];"));
        txt = Tpl.nextIter(txt);
        txt = lm_223(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_223(txt, rest);
      then txt;
  end matchcontinue;
end lm_223;

protected function fun_224
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_eq, in_a_context)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Integer i_index;
      list<DAE.ComponentRef> i_crefs;
      Integer ret_1;
      Tpl.Text l_size;

    case ( txt,
           SimCode.SES_NONLINEAR(crefs = i_crefs, index = i_index),
           a_context )
      equation
        ret_1 = listLength(i_crefs);
        l_size = Tpl.writeStr(Tpl.emptyTxt, intString(ret_1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("start_nonlinear_system("));
        txt = Tpl.writeText(txt, l_size);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_222(txt, i_crefs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("solve_nonlinear_system(residualFunc"));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_223(txt, i_crefs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("end_nonlinear_system();"));
        txt = inlineCrefs(txt, a_context, i_crefs);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_224;

public function equationNonlinear
  input Tpl.Text txt;
  input SimCode.SimEqSystem a_eq;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := fun_224(txt, a_eq, a_context);
  out_a_varDecls := a_varDecls;
end equationNonlinear;

protected function lm_226
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Integer>> in_items;
  input Tpl.Text in_a_helpInits;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_helpInits;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_helpInits, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_helpInits, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<tuple<DAE.Exp, Integer>> rest;
      Tpl.Text a_helpInits;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      Integer i_hidx;
      DAE.Exp i_e;
      Tpl.Text l_helpInit;

    case ( txt,
           {},
           a_helpInits,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_helpInits, a_varDecls, a_preExp);

    case ( txt,
           (i_e, i_hidx) :: rest,
           a_helpInits,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_helpInit, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        a_helpInits = Tpl.writeTok(a_helpInits, Tpl.ST_STRING("localData->helpVars["));
        a_helpInits = Tpl.writeStr(a_helpInits, intString(i_hidx));
        a_helpInits = Tpl.writeTok(a_helpInits, Tpl.ST_STRING("] = "));
        a_helpInits = Tpl.writeText(a_helpInits, l_helpInit);
        a_helpInits = Tpl.writeTok(a_helpInits, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_hidx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        (txt, a_helpInits, a_varDecls, a_preExp) = lm_226(txt, rest, a_helpInits, a_varDecls, a_preExp, a_context);
      then (txt, a_helpInits, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_helpInits,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_helpInits, a_varDecls, a_preExp) = lm_226(txt, rest, a_helpInits, a_varDecls, a_preExp, a_context);
      then (txt, a_helpInits, a_varDecls, a_preExp);
  end matchcontinue;
end lm_226;

public function equationWhen
  input Tpl.Text in_txt;
  input SimCode.SimEqSystem in_a_eq;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_eq, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_left;
      DAE.Exp i_right;
      list<tuple<DAE.Exp, Integer>> i_conditions;
      Tpl.Text l_exp;
      Tpl.Text l_preExp2;
      Tpl.Text l_helpIf;
      Tpl.Text l_helpInits;
      Tpl.Text l_preExp;

    case ( txt,
           SimCode.SES_WHEN(conditions = i_conditions, right = i_right, left = i_left),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        l_helpInits = Tpl.emptyTxt;
        l_helpIf = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_helpIf, l_helpInits, a_varDecls, l_preExp) = lm_226(l_helpIf, i_conditions, l_helpInits, a_varDecls, l_preExp, a_context);
        l_helpIf = Tpl.popIter(l_helpIf);
        l_preExp2 = Tpl.emptyTxt;
        (l_exp, l_preExp2, a_varDecls) = daeExp(Tpl.emptyTxt, i_right, a_context, l_preExp2, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_helpInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, l_helpIf);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_preExp2);
        txt = Tpl.softNewLine(txt);
        txt = cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("} else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = pre("));
        txt = cref(txt, i_left);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end equationWhen;

public function simulationFunctionsFile
  input Tpl.Text txt;
  input String a_filePrefix;
  input list<SimCode.Function> a_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("#include \""));
  out_txt := Tpl.writeStr(out_txt, a_filePrefix);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "_functions.h\"\n",
                                       "extern \"C\" {\n"
                                   }, true));
  out_txt := functionBodies(out_txt, a_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n"
                                   }, true));
end simulationFunctionsFile;

protected function lm_229
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.RecordDeclaration> rest;
      SimCode.RecordDeclaration i_rd;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      equation
        txt = recordDeclaration(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_229(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_229(txt, rest);
      then txt;
  end matchcontinue;
end lm_229;

public function recordsFile
  input Tpl.Text txt;
  input String a_filePrefix;
  input list<SimCode.RecordDeclaration> a_recordDecls;

  output Tpl.Text out_txt;
protected
  String ret_0;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("/* Additional record code for "));
  out_txt := Tpl.writeStr(out_txt, a_filePrefix);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" generated by the OpenModelica Compiler "));
  ret_0 := Settings.getVersionNr();
  out_txt := Tpl.writeStr(out_txt, ret_0);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ". */\n",
                                       "#include \"meta_modelica.h\"\n"
                                   }, true));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_229(out_txt, a_recordDecls);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
end recordsFile;

protected function lm_231
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.RecordDeclaration> rest;
      SimCode.RecordDeclaration i_rd;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      equation
        txt = recordDeclarationHeader(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_231(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_231(txt, rest);
      then txt;
  end matchcontinue;
end lm_231;

public function simulationFunctionsHeaderFile
  input Tpl.Text txt;
  input String a_filePrefix;
  input list<SimCode.Function> a_functions;
  input list<String> a_includes;
  input list<SimCode.RecordDeclaration> a_recordDecls;

  output Tpl.Text out_txt;
protected
  String ret_1;
  String ret_0;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("#ifndef "));
  ret_0 := System.stringReplace(a_filePrefix, ".", "_");
  out_txt := Tpl.writeStr(out_txt, ret_0);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "__H\n",
                                       "#define "
                                   }, false));
  ret_1 := System.stringReplace(a_filePrefix, ".", "_");
  out_txt := Tpl.writeStr(out_txt, ret_1);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__H\n"));
  out_txt := commonHeader(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "#include \"simulation_runtime.h\"\n",
                                       "extern \"C\" {\n"
                                   }, true));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_231(out_txt, a_recordDecls);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := externalFunctionIncludes(out_txt, a_includes);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeaders(out_txt, a_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "#endif\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
end simulationFunctionsHeaderFile;

protected function fun_233
  input Tpl.Text in_txt;
  input String in_a_modelInfo_directory;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_modelInfo_directory)
    local
      Tpl.Text txt;
      String i_modelInfo_directory;

    case ( txt,
           "" )
      then txt;

    case ( txt,
           i_modelInfo_directory )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-L\""));
        txt = Tpl.writeStr(txt, i_modelInfo_directory);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;
  end matchcontinue;
end fun_233;

protected function lm_234
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<String> rest;
      String i_lib;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_lib :: rest )
      equation
        txt = Tpl.writeStr(txt, i_lib);
        txt = Tpl.nextIter(txt);
        txt = lm_234(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_234(txt, rest);
      then txt;
  end matchcontinue;
end lm_234;

protected function fun_235
  input Tpl.Text in_txt;
  input Tpl.Text in_a_dirExtra;
  input Tpl.Text in_a_libsStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_dirExtra, in_a_libsStr)
    local
      Tpl.Text txt;
      Tpl.Text a_libsStr;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}),
           a_libsStr )
      equation
        txt = Tpl.writeText(txt, a_libsStr);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_235;

protected function fun_236
  input Tpl.Text in_txt;
  input Tpl.Text in_a_dirExtra;
  input Tpl.Text in_a_libsStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_dirExtra, in_a_libsStr)
    local
      Tpl.Text txt;
      Tpl.Text a_libsStr;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}),
           _ )
      then txt;

    case ( txt,
           _,
           a_libsStr )
      equation
        txt = Tpl.writeText(txt, a_libsStr);
      then txt;
  end matchcontinue;
end fun_236;

public function simulationMakefile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode)
    local
      Tpl.Text txt;
      String i_fileNamePrefix;
      String i_makefileParams_senddatalibs;
      String i_makefileParams_ldflags;
      String i_makefileParams_cflags;
      String i_makefileParams_omhome;
      String i_makefileParams_dllext;
      String i_makefileParams_exeext;
      String i_makefileParams_linker;
      String i_makefileParams_cxxcompiler;
      String i_makefileParams_ccompiler;
      list<String> i_makefileParams_libs;
      String i_modelInfo_directory;
      Tpl.Text l_libsPos2;
      Tpl.Text l_libsPos1;
      Tpl.Text l_libsStr;
      Tpl.Text l_dirExtra;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(directory = i_modelInfo_directory), makefileParams = SimCode.MAKEFILE_PARAMS(libs = i_makefileParams_libs, ccompiler = i_makefileParams_ccompiler, cxxcompiler = i_makefileParams_cxxcompiler, linker = i_makefileParams_linker, exeext = i_makefileParams_exeext, dllext = i_makefileParams_dllext, omhome = i_makefileParams_omhome, cflags = i_makefileParams_cflags, ldflags = i_makefileParams_ldflags, senddatalibs = i_makefileParams_senddatalibs), fileNamePrefix = i_fileNamePrefix) )
      equation
        l_dirExtra = fun_233(Tpl.emptyTxt, i_modelInfo_directory);
        l_libsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_libsStr = lm_234(l_libsStr, i_makefileParams_libs);
        l_libsStr = Tpl.popIter(l_libsStr);
        l_libsPos1 = fun_235(Tpl.emptyTxt, l_dirExtra, l_libsStr);
        l_libsPos2 = fun_236(Tpl.emptyTxt, l_dirExtra, l_libsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "# Makefile generated by OpenModelica\n",
                                    "\n",
                                    "CC="
                                }, false));
        txt = Tpl.writeStr(txt, i_makefileParams_ccompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CXX="));
        txt = Tpl.writeStr(txt, i_makefileParams_cxxcompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LINK="));
        txt = Tpl.writeStr(txt, i_makefileParams_linker);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("EXEEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_exeext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DLLEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_dllext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CFLAGS=-I\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/include/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_cflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LDFLAGS=-L\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/lib/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_ldflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("SENDDATALIBS="));
        txt = Tpl.writeStr(txt, i_makefileParams_senddatalibs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    ".PHONY: "
                                }, false));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(": "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".cpp "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_functions.cpp "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_functions.h "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("_records.c\n"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\t"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(CXX) -I. -o "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$(EXEEXT) "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".cpp "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_functions.cpp "));
        txt = Tpl.writeText(txt, l_dirExtra);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, l_libsPos1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, l_libsPos2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" -lsim -linteractive $(CFLAGS) $(SENDDATALIBS) $(LDFLAGS) -lf2c "));
        txt = Tpl.writeStr(txt, i_fileNamePrefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_records.c"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationMakefile;

public function simulationInitFile
  input Tpl.Text in_txt;
  input SimCode.SimCode in_a_simCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_simCode)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> i_vars_stringAlgVars;
      list<SimCode.SimVar> i_vars_stringParamVars;
      list<SimCode.SimVar> i_vars_boolAlgVars;
      list<SimCode.SimVar> i_vars_boolParamVars;
      list<SimCode.SimVar> i_vars_intAlgVars;
      list<SimCode.SimVar> i_vars_intParamVars;
      list<SimCode.SimVar> i_vars_paramVars;
      list<SimCode.SimVar> i_vars_algVars;
      list<SimCode.SimVar> i_vars_derivativeVars;
      list<SimCode.SimVar> i_vars_stateVars;
      Integer i_vi_numStringAlgVars;
      Integer i_vi_numStringParamVars;
      Integer i_vi_numBoolAlgVars;
      Integer i_vi_numBoolParams;
      Integer i_vi_numIntAlgVars;
      Integer i_vi_numIntParams;
      Integer i_vi_numParams;
      Integer i_vi_numAlgVars;
      Integer i_vi_numStateVars;
      String i_s_outputFormat;
      String i_s_method;
      Real i_s_tolerance;
      Real i_s_stepSize;
      Real i_s_stopTime;
      Real i_s_startTime;

    case ( txt,
           SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(varInfo = SimCode.VARINFO(numStateVars = i_vi_numStateVars, numAlgVars = i_vi_numAlgVars, numParams = i_vi_numParams, numIntParams = i_vi_numIntParams, numIntAlgVars = i_vi_numIntAlgVars, numBoolParams = i_vi_numBoolParams, numBoolAlgVars = i_vi_numBoolAlgVars, numStringParamVars = i_vi_numStringParamVars, numStringAlgVars = i_vi_numStringAlgVars), vars = SimCode.SIMVARS(stateVars = i_vars_stateVars, derivativeVars = i_vars_derivativeVars, algVars = i_vars_algVars, paramVars = i_vars_paramVars, intParamVars = i_vars_intParamVars, intAlgVars = i_vars_intAlgVars, boolParamVars = i_vars_boolParamVars, boolAlgVars = i_vars_boolAlgVars, stringParamVars = i_vars_stringParamVars, stringAlgVars = i_vars_stringAlgVars)), simulationSettingsOpt = SOME(SimCode.SIMULATION_SETTINGS(startTime = i_s_startTime, stopTime = i_s_stopTime, stepSize = i_s_stepSize, tolerance = i_s_tolerance, method = i_s_method, outputFormat = i_s_outputFormat))) )
      equation
        txt = Tpl.writeStr(txt, realString(i_s_startTime));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // start value\n"));
        txt = Tpl.writeStr(txt, realString(i_s_stopTime));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // stop value\n"));
        txt = Tpl.writeStr(txt, realString(i_s_stepSize));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // step value\n"));
        txt = Tpl.writeStr(txt, realString(i_s_tolerance));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " // tolerance\n",
                                    "\""
                                }, false));
        txt = Tpl.writeStr(txt, i_s_method);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\" // method\n",
                                    "\""
                                }, false));
        txt = Tpl.writeStr(txt, i_s_outputFormat);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("\" // outputFormat\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numStateVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n states\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n alg vars\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numParams));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" //n parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numIntParams));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n int parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numIntAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n int variables\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numBoolParams));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n bool parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numBoolAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n bool variables\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numStringParamVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n string-parameters\n"));
        txt = Tpl.writeStr(txt, intString(i_vi_numStringAlgVars));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" // n string variables\n"));
        txt = initVals(txt, i_vars_stateVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_derivativeVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_algVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_paramVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_intParamVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_intAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_boolParamVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_boolAlgVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_stringParamVars);
        txt = Tpl.softNewLine(txt);
        txt = initVals(txt, i_vars_stringAlgVars);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end simulationInitFile;

protected function fun_239
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_a_initialValue;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_initialValue)
    local
      Tpl.Text txt;
      DAE.Exp i_v;

    case ( txt,
           SOME(i_v) )
      equation
        txt = initVal(txt, i_v);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0.0 //default"));
      then txt;
  end matchcontinue;
end fun_239;

protected function lm_240
  input Tpl.Text in_txt;
  input list<SimCode.SimVar> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimVar> rest;
      DAE.ComponentRef i_name;
      Option<DAE.Exp> i_initialValue;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.SIMVAR(initialValue = i_initialValue, name = i_name) :: rest )
      equation
        txt = fun_239(txt, i_initialValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" //"));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_240(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_240(txt, rest);
      then txt;
  end matchcontinue;
end lm_240;

public function initVals
  input Tpl.Text txt;
  input list<SimCode.SimVar> a_varsLst;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_240(out_txt, a_varsLst);
  out_txt := Tpl.popIter(out_txt);
end initVals;

protected function fun_242
  input Tpl.Text in_txt;
  input Boolean in_a_bool;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_bool)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("false"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("true"));
      then txt;
  end matchcontinue;
end fun_242;

public function initVal
  input Tpl.Text in_txt;
  input DAE.Exp in_a_initialValue;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_initialValue)
    local
      Tpl.Text txt;
      Absyn.Path i_name;
      Integer i_index;
      Boolean i_bool;
      String i_string;
      Real i_real;
      Integer i_integer;
      String ret_0;

    case ( txt,
           DAE.ICONST(integer = i_integer) )
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then txt;

    case ( txt,
           DAE.RCONST(real = i_real) )
      equation
        txt = Tpl.writeStr(txt, realString(i_real));
      then txt;

    case ( txt,
           DAE.SCONST(string = i_string) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        ret_0 = Util.escapeModelicaStringToCString(i_string);
        txt = Tpl.writeStr(txt, ret_0);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
      then txt;

    case ( txt,
           DAE.BCONST(bool = i_bool) )
      equation
        txt = fun_242(txt, i_bool);
      then txt;

    case ( txt,
           DAE.ENUM_LITERAL(index = i_index, name = i_name) )
      equation
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/*ENUM:"));
        txt = dotPath(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*/"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*ERROR* initial value of unknown type"));
      then txt;
  end matchcontinue;
end initVal;

public function commonHeader
  input Tpl.Text txt;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                   "#include \"modelica.h\"\n",
                                   "#include <stdio.h>\n",
                                   "#include <stdlib.h>\n",
                                   "#include <errno.h>\n",
                                   "\n",
                                   "#if defined(_MSC_VER)\n",
                                   "  #define DLLExport   __declspec( dllexport )\n",
                                   "#else\n",
                                   "  #define DLLExport /* nothing */\n",
                                   "#endif"
                               }, false));
end commonHeader;

public function functionsFile
  input Tpl.Text txt;
  input String a_filePrefix;
  input SimCode.Function a_mainFunction;
  input list<SimCode.Function> a_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("#include \""));
  out_txt := Tpl.writeStr(out_txt, a_filePrefix);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ".h\"\n",
                                       "#include <algorithm>\n",
                                       "#define MODELICA_ASSERT(msg) { fprintf(stderr,\"Modelica Assert: %s!\\n\", msg); }\n",
                                       "#define MODELICA_TERMINATE(msg) { fprintf(stderr,\"Modelica Terminate: %s!\\n\", msg); fflush(stderr); }\n",
                                       "\n",
                                       "extern \"C\" {\n"
                                   }, true));
  out_txt := functionBody(out_txt, a_mainFunction, true);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionBodies(out_txt, a_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "}\n",
                                       "\n"
                                   }, true));
end functionsFile;

protected function lm_246
  input Tpl.Text in_txt;
  input list<SimCode.RecordDeclaration> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.RecordDeclaration> rest;
      SimCode.RecordDeclaration i_rd;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_rd :: rest )
      equation
        txt = recordDeclarationHeader(txt, i_rd);
        txt = Tpl.nextIter(txt);
        txt = lm_246(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_246(txt, rest);
      then txt;
  end matchcontinue;
end lm_246;

public function functionsHeaderFile
  input Tpl.Text txt;
  input String a_filePrefix;
  input SimCode.Function a_mainFunction;
  input list<SimCode.Function> a_functions;
  input list<SimCode.RecordDeclaration> a_extraRecordDecls;
  input list<String> a_includes;

  output Tpl.Text out_txt;
protected
  String ret_1;
  String ret_0;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("#ifndef "));
  ret_0 := System.stringReplace(a_filePrefix, ".", "_");
  out_txt := Tpl.writeStr(out_txt, ret_0);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "__H\n",
                                       "#define "
                                   }, false));
  ret_1 := System.stringReplace(a_filePrefix, ".", "_");
  out_txt := Tpl.writeStr(out_txt, ret_1);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__H\n"));
  out_txt := commonHeader(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "#ifdef __cplusplus\n",
                                       "extern \"C\" {\n",
                                       "#endif\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_246(out_txt, a_extraRecordDecls);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := externalFunctionIncludes(out_txt, a_includes);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeader(out_txt, a_mainFunction, true);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := functionHeaders(out_txt, a_functions);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\n",
                                       "#ifdef __cplusplus\n",
                                       "}\n",
                                       "#endif\n",
                                       "#endif\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_NEW_LINE());
end functionsHeaderFile;

protected function lm_248
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<String> rest;
      String i_it;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_248(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_248(txt, rest);
      then txt;
  end matchcontinue;
end lm_248;

public function functionsMakefile
  input Tpl.Text in_txt;
  input SimCode.FunctionCode in_a_fnCode;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fnCode)
    local
      Tpl.Text txt;
      String i_name;
      String i_makefileParams_senddatalibs;
      String i_makefileParams_ldflags;
      String i_makefileParams_cflags;
      String i_makefileParams_omhome;
      String i_makefileParams_dllext;
      String i_makefileParams_exeext;
      String i_makefileParams_linker;
      String i_makefileParams_cxxcompiler;
      String i_makefileParams_ccompiler;
      list<String> i_makefileParams_libs;
      Tpl.Text l_libsStr;

    case ( txt,
           SimCode.FUNCTIONCODE(makefileParams = SimCode.MAKEFILE_PARAMS(libs = i_makefileParams_libs, ccompiler = i_makefileParams_ccompiler, cxxcompiler = i_makefileParams_cxxcompiler, linker = i_makefileParams_linker, exeext = i_makefileParams_exeext, dllext = i_makefileParams_dllext, omhome = i_makefileParams_omhome, cflags = i_makefileParams_cflags, ldflags = i_makefileParams_ldflags, senddatalibs = i_makefileParams_senddatalibs), name = i_name) )
      equation
        l_libsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_libsStr = lm_248(l_libsStr, i_makefileParams_libs);
        l_libsStr = Tpl.popIter(l_libsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "# Makefile generated by OpenModelica\n",
                                    "\n",
                                    "CC="
                                }, false));
        txt = Tpl.writeStr(txt, i_makefileParams_ccompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CXX="));
        txt = Tpl.writeStr(txt, i_makefileParams_cxxcompiler);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LINK="));
        txt = Tpl.writeStr(txt, i_makefileParams_linker);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("EXEEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_exeext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DLLEXT="));
        txt = Tpl.writeStr(txt, i_makefileParams_dllext);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CFLAGS= -I\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/include/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_cflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("LDFLAGS= -L\""));
        txt = Tpl.writeStr(txt, i_makefileParams_omhome);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/lib/omc\" "));
        txt = Tpl.writeStr(txt, i_makefileParams_ldflags);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("SENDDATALIBS="));
        txt = Tpl.writeStr(txt, i_makefileParams_senddatalibs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    ".PHONY: "
                                }, false));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(": "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".c "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".h "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("_records.c\n"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\t"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(LINK) -o "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$(DLLEXT) "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".c "));
        txt = Tpl.writeText(txt, l_libsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" $(CFLAGS) $(LDFLAGS) $(SENDDATALIBS) -lm "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_records.c"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionsMakefile;

protected function fun_250
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_cr;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           a_cr )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = crefStr(txt, a_cr);
      then txt;

    case ( txt,
           _,
           a_cr )
      equation
        txt = cref(txt, a_cr);
      then txt;
  end matchcontinue;
end fun_250;

public function contextCref
  input Tpl.Text txt;
  input DAE.ComponentRef a_cr;
  input SimCode.Context a_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_250(txt, a_context, a_cr);
end contextCref;

protected function fun_252
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input Absyn.Ident in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_name)
    local
      Tpl.Text txt;
      Absyn.Ident a_name;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, a_name);
      then txt;

    case ( txt,
           _,
           a_name )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = Tpl.writeStr(txt, a_name);
      then txt;
  end matchcontinue;
end fun_252;

public function contextIteratorName
  input Tpl.Text txt;
  input Absyn.Ident a_name;
  input SimCode.Context a_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_252(txt, a_context, a_name);
end contextIteratorName;

public function cref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           (i_cr as DAE.CREF_IDENT(ident = "xloc")) )
      equation
        txt = crefStr(txt, i_cr);
      then txt;

    case ( txt,
           DAE.CREF_IDENT(ident = "time") )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("time"));
      then txt;

    case ( txt,
           i_cr )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = crefToCStr(txt, i_cr);
      then txt;
  end matchcontinue;
end cref;

public function crefToCStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_componentRef;
      list<DAE.Subscript> i_subscriptLst;
      DAE.Ident i_ident;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsToCStr(txt, i_subscriptLst);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, subscriptLst = i_subscriptLst, componentRef = i_componentRef) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsToCStr(txt, i_subscriptLst);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = crefToCStr(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end crefToCStr;

protected function lm_256
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.Subscript> rest;
      DAE.Subscript i_s;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_s :: rest )
      equation
        txt = subscriptToCStr(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_256(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_256(txt, rest);
      then txt;
  end matchcontinue;
end lm_256;

public function subscriptsToCStr
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_a_subscripts;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_subscripts)
    local
      Tpl.Text txt;
      list<DAE.Subscript> i_subscripts;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_subscripts )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$lB"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING("$c")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_256(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$rB"));
      then txt;
  end matchcontinue;
end subscriptsToCStr;

protected function fun_258
  input Tpl.Text in_txt;
  input DAE.Subscript in_a_subscript;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_subscript, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp i_exp;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           a_varDecls,
           a_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_SUBSCRIPT"));
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_258;

public function subscriptToCStr
  input Tpl.Text txt;
  input DAE.Subscript a_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_varDecls;
  Tpl.Text l_preExp;
algorithm
  l_preExp := Tpl.emptyTxt;
  l_varDecls := Tpl.emptyTxt;
  (out_txt, l_varDecls, l_preExp) := fun_258(txt, a_subscript, l_varDecls, l_preExp);
end subscriptToCStr;

public function crefStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_componentRef;
      list<DAE.Subscript> i_subscriptLst;
      DAE.Ident i_ident;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsStr(txt, i_subscriptLst);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = "$DER", componentRef = i_componentRef) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("der("));
        txt = crefStr(txt, i_componentRef);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, subscriptLst = i_subscriptLst, componentRef = i_componentRef) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsStr(txt, i_subscriptLst);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = crefStr(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end crefStr;

public function crefM
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_cr;

    case ( txt,
           (i_cr as DAE.CREF_IDENT(ident = "xloc")) )
      equation
        txt = crefStr(txt, i_cr);
      then txt;

    case ( txt,
           DAE.CREF_IDENT(ident = "time") )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("time"));
      then txt;

    case ( txt,
           i_cr )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("P"));
        txt = crefToMStr(txt, i_cr);
      then txt;
  end matchcontinue;
end crefM;

public function crefToMStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_componentRef;
      list<DAE.Subscript> i_subscriptLst;
      DAE.Ident i_ident;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident, subscriptLst = i_subscriptLst) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsToMStr(txt, i_subscriptLst);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, subscriptLst = i_subscriptLst, componentRef = i_componentRef) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = subscriptsToMStr(txt, i_subscriptLst);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("P"));
        txt = crefToMStr(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end crefToMStr;

protected function lm_263
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.Subscript> rest;
      DAE.Subscript i_s;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_s :: rest )
      equation
        txt = subscriptToMStr(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_263(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_263(txt, rest);
      then txt;
  end matchcontinue;
end lm_263;

public function subscriptsToMStr
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_a_subscripts;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_subscripts)
    local
      Tpl.Text txt;
      list<DAE.Subscript> i_subscripts;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_subscripts )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("lB"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING("c")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_263(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("rB"));
      then txt;
  end matchcontinue;
end subscriptsToMStr;

protected function fun_265
  input Tpl.Text in_txt;
  input DAE.Subscript in_a_subscript;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_subscript, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp i_exp;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextSimulationNonDiscrete, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           a_varDecls,
           a_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_SUBSCRIPT"));
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_265;

public function subscriptToMStr
  input Tpl.Text txt;
  input DAE.Subscript a_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_varDecls;
  Tpl.Text l_preExp;
algorithm
  l_preExp := Tpl.emptyTxt;
  l_varDecls := Tpl.emptyTxt;
  (out_txt, l_varDecls, l_preExp) := fun_265(txt, a_subscript, l_varDecls, l_preExp);
end subscriptToMStr;

protected function fun_267
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_cr;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           a_cr )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = arrayCrefStr(txt, a_cr);
      then txt;

    case ( txt,
           _,
           a_cr )
      equation
        txt = arrayCrefCStr(txt, a_cr);
      then txt;
  end matchcontinue;
end fun_267;

public function contextArrayCref
  input Tpl.Text txt;
  input DAE.ComponentRef a_cr;
  input SimCode.Context a_context;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_267(txt, a_context, a_cr);
end contextArrayCref;

public function arrayCrefCStr
  input Tpl.Text txt;
  input DAE.ComponentRef a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
  out_txt := arrayCrefCStr2(out_txt, a_cr);
end arrayCrefCStr;

public function arrayCrefCStr2
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_componentRef;
      DAE.Ident i_ident;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P"));
        txt = arrayCrefCStr2(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end arrayCrefCStr2;

public function arrayCrefStr
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_componentRef;
      DAE.Ident i_ident;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      equation
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = arrayCrefStr(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CREF_NOT_IDENT_OR_QUAL"));
      then txt;
  end matchcontinue;
end arrayCrefStr;

protected function lm_272
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.Subscript> rest;
      DAE.Subscript i_s;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_s :: rest )
      equation
        txt = subscriptStr(txt, i_s);
        txt = Tpl.nextIter(txt);
        txt = lm_272(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_272(txt, rest);
      then txt;
  end matchcontinue;
end lm_272;

public function subscriptsStr
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_a_subscripts;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_subscripts)
    local
      Tpl.Text txt;
      list<DAE.Subscript> i_subscripts;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_subscripts )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_272(txt, i_subscripts);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;
  end matchcontinue;
end subscriptsStr;

protected function fun_274
  input Tpl.Text in_txt;
  input DAE.Subscript in_a_subscript;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_subscript, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp i_exp;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           a_varDecls,
           a_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("WHOLEDIM"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_SUBSCRIPT"));
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_274;

public function subscriptStr
  input Tpl.Text txt;
  input DAE.Subscript a_subscript;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_varDecls;
  Tpl.Text l_preExp;
algorithm
  l_preExp := Tpl.emptyTxt;
  l_varDecls := Tpl.emptyTxt;
  (out_txt, l_varDecls, l_preExp) := fun_274(txt, a_subscript, l_varDecls, l_preExp);
end subscriptStr;

public function expCref
  input Tpl.Text in_txt;
  input DAE.Exp in_a_ecr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ecr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_arg_componentRef;
      DAE.ComponentRef i_componentRef;

    case ( txt,
           DAE.CREF(componentRef = i_componentRef) )
      equation
        txt = cref(txt, i_componentRef);
      then txt;

    case ( txt,
           DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = i_arg_componentRef)}) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P$DER"));
        txt = cref(txt, i_arg_componentRef);
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ERROR_NOT_A_CREF"));
      then txt;
  end matchcontinue;
end expCref;

public function functionName
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_componentRef;
      DAE.Ident i_ident;
      String ret_1;
      String ret_0;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident) )
      equation
        ret_0 = System.stringReplace(i_ident, "_", "__");
        txt = Tpl.writeStr(txt, ret_0);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef) )
      equation
        ret_1 = System.stringReplace(i_ident, "_", "__");
        txt = Tpl.writeStr(txt, ret_1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = functionName(txt, i_componentRef);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionName;

public function dotPath
  input Tpl.Text in_txt;
  input Absyn.Path in_a_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_path)
    local
      Tpl.Text txt;
      Absyn.Path i_path;
      Absyn.Ident i_name;

    case ( txt,
           Absyn.QUALIFIED(name = i_name, path = i_path) )
      equation
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = dotPath(txt, i_path);
      then txt;

    case ( txt,
           Absyn.IDENT(name = i_name) )
      equation
        txt = Tpl.writeStr(txt, i_name);
      then txt;

    case ( txt,
           Absyn.FULLYQUALIFIED(path = i_path) )
      equation
        txt = dotPath(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end dotPath;

public function replaceDotAndUnderscore
  input Tpl.Text in_txt;
  input String in_a_str;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_str)
    local
      Tpl.Text txt;
      String i_name;
      String ret_3;
      Tpl.Text l_str__underscores;
      String ret_1;
      Tpl.Text l_str__dots;

    case ( txt,
           i_name )
      equation
        ret_1 = System.stringReplace(i_name, ".", "_");
        l_str__dots = Tpl.writeStr(Tpl.emptyTxt, ret_1);
        ret_3 = System.stringReplace(Tpl.textString(l_str__dots), "_", "__");
        l_str__underscores = Tpl.writeStr(Tpl.emptyTxt, ret_3);
        txt = Tpl.writeText(txt, l_str__underscores);
      then txt;
  end matchcontinue;
end replaceDotAndUnderscore;

public function underscorePath
  input Tpl.Text in_txt;
  input Absyn.Path in_a_path;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_path)
    local
      Tpl.Text txt;
      Absyn.Path i_path;
      Absyn.Ident i_name;

    case ( txt,
           Absyn.QUALIFIED(name = i_name, path = i_path) )
      equation
        txt = replaceDotAndUnderscore(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = underscorePath(txt, i_path);
      then txt;

    case ( txt,
           Absyn.IDENT(name = i_name) )
      equation
        txt = replaceDotAndUnderscore(txt, i_name);
      then txt;

    case ( txt,
           Absyn.FULLYQUALIFIED(path = i_path) )
      equation
        txt = underscorePath(txt, i_path);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end underscorePath;

protected function lm_281
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<String> rest;
      String i_it;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_it :: rest )
      equation
        txt = Tpl.writeStr(txt, i_it);
        txt = Tpl.nextIter(txt);
        txt = lm_281(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_281(txt, rest);
      then txt;
  end matchcontinue;
end lm_281;

public function externalFunctionIncludes
  input Tpl.Text in_txt;
  input list<String> in_a_includes;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_includes)
    local
      Tpl.Text txt;
      list<String> i_includes;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_includes )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#ifdef __cplusplus\n",
                                    "extern \"C\" {\n",
                                    "#endif\n"
                                }, true));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_281(txt, i_includes);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#ifdef __cplusplus\n",
                                    "}\n",
                                    "#endif"
                                }, false));
      then txt;
  end matchcontinue;
end externalFunctionIncludes;

protected function lm_283
  input Tpl.Text in_txt;
  input list<SimCode.Function> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Function> rest;
      SimCode.Function i_fn;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_fn :: rest )
      equation
        txt = functionHeader(txt, i_fn, false);
        txt = Tpl.nextIter(txt);
        txt = lm_283(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_283(txt, rest);
      then txt;
  end matchcontinue;
end lm_283;

public function functionHeaders
  input Tpl.Text txt;
  input list<SimCode.Function> a_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_283(out_txt, a_functions);
  out_txt := Tpl.popIter(out_txt);
end functionHeaders;

protected function lm_285
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_name;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) :: rest )
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_285(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_285(txt, rest);
      then txt;
  end matchcontinue;
end lm_285;

protected function lm_286
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_286(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_286(txt, rest);
      then txt;
  end matchcontinue;
end lm_286;

protected function fun_287
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input list<SimCode.Variable> in_a_funArgs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_funArgs)
    local
      Tpl.Text txt;
      list<SimCode.Variable> a_funArgs;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           a_funArgs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_286(txt, a_funArgs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_287;

protected function fun_288
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_funArgsBoxedStr;
  input Tpl.Text in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_funArgsBoxedStr, in_a_fname)
    local
      Tpl.Text txt;
      Tpl.Text a_funArgsBoxedStr;
      Tpl.Text a_fname;

    case ( txt,
           false,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           a_funArgsBoxedStr,
           a_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed_s {\n",
                                    "  modelica_metatype targ1;\n",
                                    "} "
                                }, false));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettypeboxed;\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettypeboxed boxptr_"));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_funArgsBoxedStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_288;

public function functionHeader
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;
  input Boolean in_a_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn, in_a_inFunc)
    local
      Tpl.Text txt;
      Boolean a_inFunc;
      SimCode.Function i_fn;
      list<SimCode.Variable> i_funArgs;
      list<SimCode.Variable> i_outVars;
      list<SimCode.Variable> i_functionArguments;
      Absyn.Path i_name;
      Boolean ret_9;
      Tpl.Text l_boxedHeader;
      Boolean ret_7;
      Tpl.Text l_funArgsBoxedStr;
      Tpl.Text l_funArgsStr;
      Tpl.Text l_fname;
      Tpl.Text txt_3;
      Tpl.Text txt_2;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           SimCode.FUNCTION(name = i_name, functionArguments = i_functionArguments, outVars = i_outVars),
           a_inFunc )
      equation
        txt_0 = underscorePath(Tpl.emptyTxt, i_name);
        txt = functionHeaderNormal(txt, Tpl.textString(txt_0), i_functionArguments, i_outVars, a_inFunc);
        txt = Tpl.softNewLine(txt);
        txt_1 = underscorePath(Tpl.emptyTxt, i_name);
        txt = functionHeaderBoxed(txt, Tpl.textString(txt_1), i_functionArguments, i_outVars);
      then txt;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(name = i_name, funArgs = i_funArgs, outVars = i_outVars)),
           a_inFunc )
      equation
        txt_2 = underscorePath(Tpl.emptyTxt, i_name);
        txt = functionHeaderNormal(txt, Tpl.textString(txt_2), i_funArgs, i_outVars, a_inFunc);
        txt = Tpl.softNewLine(txt);
        txt_3 = underscorePath(Tpl.emptyTxt, i_name);
        txt = functionHeaderBoxed(txt, Tpl.textString(txt_3), i_funArgs, i_outVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = extFunDef(txt, i_fn);
      then txt;

    case ( txt,
           SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs),
           _ )
      equation
        l_fname = underscorePath(Tpl.emptyTxt, i_name);
        l_funArgsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_funArgsStr = lm_285(l_funArgsStr, i_funArgs);
        l_funArgsStr = Tpl.popIter(l_funArgsStr);
        ret_7 = RTOpts.acceptMetaModelicaGrammar();
        l_funArgsBoxedStr = fun_287(Tpl.emptyTxt, ret_7, i_funArgs);
        ret_9 = RTOpts.acceptMetaModelicaGrammar();
        l_boxedHeader = fun_288(Tpl.emptyTxt, ret_9, l_funArgsBoxedStr, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettype_1 targ1\n",
                                    "typedef struct "
                                }, false));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("_rettype_s {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" targ1;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_rettype;\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype _"));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_funArgsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, l_boxedHeader);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionHeader;

protected function lm_290
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_290(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_290(txt, rest);
      then txt;
  end matchcontinue;
end lm_290;

protected function lm_291
  input Tpl.Text in_txt;
  input list<String> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<String> rest;
      String i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_name :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\""));
        txt = Tpl.nextIter(txt);
        txt = lm_291(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_291(txt, rest);
      then txt;
  end matchcontinue;
end lm_291;

public function recordDeclaration
  input Tpl.Text in_txt;
  input SimCode.RecordDeclaration in_a_recDecl;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_recDecl)
    local
      Tpl.Text txt;
      list<String> i_fieldNames;
      Absyn.Path i_path;
      list<SimCode.Variable> i_variables;
      Absyn.Path i_defPath;
      Integer ret_7;
      Tpl.Text txt_6;
      Tpl.Text txt_5;
      Tpl.Text txt_4;
      Integer ret_3;
      Tpl.Text txt_2;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           SimCode.RECORD_DECL_FULL(defPath = i_defPath, variables = i_variables) )
      equation
        txt_0 = dotPath(Tpl.emptyTxt, i_defPath);
        txt_1 = underscorePath(Tpl.emptyTxt, i_defPath);
        txt_2 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_2 = lm_290(txt_2, i_variables);
        txt_2 = Tpl.popIter(txt_2);
        ret_3 = listLength(i_variables);
        txt = recordDefinition(txt, Tpl.textString(txt_0), Tpl.textString(txt_1), Tpl.textString(txt_2), ret_3);
      then txt;

    case ( txt,
           SimCode.RECORD_DECL_DEF(path = i_path, fieldNames = i_fieldNames) )
      equation
        txt_4 = dotPath(Tpl.emptyTxt, i_path);
        txt_5 = underscorePath(Tpl.emptyTxt, i_path);
        txt_6 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(",")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt_6 = lm_291(txt_6, i_fieldNames);
        txt_6 = Tpl.popIter(txt_6);
        ret_7 = listLength(i_fieldNames);
        txt = recordDefinition(txt, Tpl.textString(txt_4), Tpl.textString(txt_5), Tpl.textString(txt_6), ret_7);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end recordDeclaration;

protected function lm_293
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_var_name;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_var_name)) :: rest )
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_var_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_293(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_293(txt, rest);
      then txt;
  end matchcontinue;
end lm_293;

public function recordDeclarationHeader
  input Tpl.Text in_txt;
  input SimCode.RecordDeclaration in_a_recDecl;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_recDecl)
    local
      Tpl.Text txt;
      list<String> i_fieldNames;
      Absyn.Path i_path;
      Absyn.Path i_defPath;
      list<SimCode.Variable> i_variables;
      String i_name;
      Integer ret_5;
      Tpl.Text txt_4;
      Tpl.Text txt_3;
      Integer ret_2;
      Tpl.Text txt_1;
      Tpl.Text txt_0;

    case ( txt,
           SimCode.RECORD_DECL_FULL(name = i_name, variables = i_variables, defPath = i_defPath) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_293(txt, i_variables);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("};\n"));
        txt_0 = dotPath(Tpl.emptyTxt, i_defPath);
        txt_1 = underscorePath(Tpl.emptyTxt, i_defPath);
        ret_2 = listLength(i_variables);
        txt = recordDefinitionHeader(txt, Tpl.textString(txt_0), Tpl.textString(txt_1), ret_2);
      then txt;

    case ( txt,
           SimCode.RECORD_DECL_DEF(path = i_path, fieldNames = i_fieldNames) )
      equation
        txt_3 = dotPath(Tpl.emptyTxt, i_path);
        txt_4 = underscorePath(Tpl.emptyTxt, i_path);
        ret_5 = listLength(i_fieldNames);
        txt = recordDefinitionHeader(txt, Tpl.textString(txt_3), Tpl.textString(txt_4), ret_5);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end recordDeclarationHeader;

public function recordDefinition
  input Tpl.Text txt;
  input String a_origName;
  input String a_encName;
  input String a_fieldNames;
  input Integer a_numFields;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
  out_txt := Tpl.writeStr(out_txt, a_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "__desc_added 1\n",
                                       "const char* "
                                   }, false));
  out_txt := Tpl.writeStr(out_txt, a_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("__desc__fields["));
  out_txt := Tpl.writeStr(out_txt, intString(a_numFields));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("] = {"));
  out_txt := Tpl.writeStr(out_txt, a_fieldNames);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "};\n",
                                       "struct record_description "
                                   }, false));
  out_txt := Tpl.writeStr(out_txt, a_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__desc = {\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("\""));
  out_txt := Tpl.writeStr(out_txt, a_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       "\", /* package_record__X */\n",
                                       "\""
                                   }, false));
  out_txt := Tpl.writeStr(out_txt, a_origName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("\", /* package.record_X */\n"));
  out_txt := Tpl.writeStr(out_txt, a_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("__desc__fields\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("};"));
end recordDefinition;

public function recordDefinitionHeader
  input Tpl.Text txt;
  input String a_origName;
  input String a_encName;
  input Integer a_numFields;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("extern struct record_description "));
  out_txt := Tpl.writeStr(out_txt, a_encName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("__desc;"));
end recordDefinitionHeader;

public function functionHeaderNormal
  input Tpl.Text txt;
  input String a_fname;
  input list<SimCode.Variable> a_fargs;
  input list<SimCode.Variable> a_outVars;
  input Boolean a_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt := functionHeaderImpl(txt, a_fname, a_fargs, a_outVars, a_inFunc, false);
end functionHeaderNormal;

protected function fun_298
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input String in_a_fname;
  input list<SimCode.Variable> in_a_fargs;
  input list<SimCode.Variable> in_a_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_fname, in_a_fargs, in_a_outVars)
    local
      Tpl.Text txt;
      String a_fname;
      list<SimCode.Variable> a_fargs;
      list<SimCode.Variable> a_outVars;

    case ( txt,
           false,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           a_fname,
           a_fargs,
           a_outVars )
      equation
        txt = functionHeaderImpl(txt, a_fname, a_fargs, a_outVars, false, true);
      then txt;
  end matchcontinue;
end fun_298;

public function functionHeaderBoxed
  input Tpl.Text txt;
  input String a_fname;
  input list<SimCode.Variable> a_fargs;
  input list<SimCode.Variable> a_outVars;

  output Tpl.Text out_txt;
protected
  Boolean ret_0;
algorithm
  ret_0 := RTOpts.acceptMetaModelicaGrammar();
  out_txt := fun_298(txt, ret_0, a_fname, a_fargs, a_outVars);
end functionHeaderBoxed;

protected function lm_300
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_300(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_300(txt, rest);
      then txt;
  end matchcontinue;
end lm_300;

protected function lm_301
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_301(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_301(txt, rest);
      then txt;
  end matchcontinue;
end lm_301;

protected function fun_302
  input Tpl.Text in_txt;
  input Boolean in_a_boxed;
  input list<SimCode.Variable> in_a_fargs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_boxed, in_a_fargs)
    local
      Tpl.Text txt;
      list<SimCode.Variable> a_fargs;

    case ( txt,
           false,
           a_fargs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_300(txt, a_fargs);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           a_fargs )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_301(txt, a_fargs);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_302;

protected function fun_303
  input Tpl.Text in_txt;
  input Boolean in_a_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_boxed)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boxed"));
      then txt;
  end matchcontinue;
end fun_303;

protected function fun_304
  input Tpl.Text in_txt;
  input Boolean in_a_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_boxed)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boxptr"));
      then txt;
  end matchcontinue;
end fun_304;

protected function fun_305
  input Tpl.Text in_txt;
  input Boolean in_a_inFunc;
  input String in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_inFunc, in_a_fname)
    local
      Tpl.Text txt;
      String a_fname;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           a_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "DLLExport\n",
                                    "int in_"
                                }, false));
        txt = Tpl.writeStr(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(type_description * inArgs, type_description * outVar);"));
      then txt;
  end matchcontinue;
end fun_305;

protected function fun_306
  input Tpl.Text in_txt;
  input Boolean in_a_boxed;
  input String in_a_fname;
  input Boolean in_a_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_boxed, in_a_fname, in_a_inFunc)
    local
      Tpl.Text txt;
      String a_fname;
      Boolean a_inFunc;

    case ( txt,
           false,
           a_fname,
           a_inFunc )
      equation
        txt = fun_305(txt, a_inFunc, a_fname);
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_306;

protected function lm_307
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_boxStr;
  input String in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_boxStr, in_a_fname)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_boxStr;
      String a_fname;
      Integer x_i1;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           _ :: rest,
           a_boxStr,
           a_fname )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeStr(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, a_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.nextIter(txt);
        txt = lm_307(txt, rest, a_boxStr, a_fname);
      then txt;

    case ( txt,
           _ :: rest,
           a_boxStr,
           a_fname )
      equation
        txt = lm_307(txt, rest, a_boxStr, a_fname);
      then txt;
  end matchcontinue;
end lm_307;

protected function lm_308
  input Tpl.Text in_txt;
  input list<DAE.Dimension> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.Dimension> rest;
      DAE.Dimension i_dim;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      equation
        txt = dimension(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_308(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_308(txt, rest);
      then txt;
  end matchcontinue;
end lm_308;

protected function fun_309
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;
      list<DAE.Dimension> i_arrayDimensions;

    case ( txt,
           DAE.ET_ARRAY(arrayDimensions = i_arrayDimensions) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_308(txt, i_arrayDimensions);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("]"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_309;

protected function fun_310
  input Tpl.Text in_txt;
  input Boolean in_a_boxed;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_boxed, in_a_var)
    local
      Tpl.Text txt;
      SimCode.Variable a_var;

    case ( txt,
           false,
           a_var )
      equation
        txt = varType(txt, a_var);
      then txt;

    case ( txt,
           _,
           a_var )
      equation
        txt = varTypeBoxed(txt, a_var);
      then txt;
  end matchcontinue;
end fun_310;

protected function fun_311
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input Integer in_a_i1;
  input Boolean in_a_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var, in_a_i1, in_a_boxed)
    local
      Tpl.Text txt;
      Integer a_i1;
      Boolean a_boxed;
      String i_name_1;
      DAE.ComponentRef i_name;
      SimCode.Variable i_var;
      DAE.ExpType i_ty;
      Tpl.Text l_typeStr;
      Tpl.Text l_dimStr;

    case ( txt,
           (i_var as SimCode.VARIABLE(ty = i_ty, name = i_name)),
           a_i1,
           a_boxed )
      equation
        l_dimStr = fun_309(Tpl.emptyTxt, i_ty);
        l_typeStr = fun_310(Tpl.emptyTxt, a_boxed, i_var);
        txt = Tpl.writeText(txt, l_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(a_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; /* "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeText(txt, l_dimStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name_1),
           a_i1,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr targ"));
        txt = Tpl.writeStr(txt, intString(a_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; /* "));
        txt = Tpl.writeStr(txt, i_name_1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_311;

protected function lm_312
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Boolean in_a_boxed;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_boxed)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Boolean a_boxed;
      Integer x_i1;
      SimCode.Variable i_var;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           i_var :: rest,
           a_boxed )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        txt = fun_311(txt, i_var, x_i1, a_boxed);
        txt = Tpl.nextIter(txt);
        txt = lm_312(txt, rest, a_boxed);
      then txt;

    case ( txt,
           _ :: rest,
           a_boxed )
      equation
        txt = lm_312(txt, rest, a_boxed);
      then txt;
  end matchcontinue;
end lm_312;

protected function fun_313
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_inFnStr;
  input Boolean in_a_boxed;
  input Tpl.Text in_a_boxStr;
  input Tpl.Text in_a_fargsStr;
  input String in_a_fname;
  input Tpl.Text in_a_boxPtrStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars, in_a_inFnStr, in_a_boxed, in_a_boxStr, in_a_fargsStr, in_a_fname, in_a_boxPtrStr)
    local
      Tpl.Text txt;
      Tpl.Text a_inFnStr;
      Boolean a_boxed;
      Tpl.Text a_boxStr;
      Tpl.Text a_fargsStr;
      String a_fname;
      Tpl.Text a_boxPtrStr;
      list<SimCode.Variable> i_outVars;

    case ( txt,
           {},
           _,
           _,
           _,
           a_fargsStr,
           a_fname,
           a_boxPtrStr )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "void "
                                }, false));
        txt = Tpl.writeText(txt, a_boxPtrStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_fargsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           i_outVars,
           a_inFnStr,
           a_boxed,
           a_boxStr,
           a_fargsStr,
           a_fname,
           a_boxPtrStr )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_307(txt, i_outVars, a_boxStr, a_fname);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("typedef struct "));
        txt = Tpl.writeStr(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, a_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_s\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_312(txt, i_outVars, a_boxed);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeStr(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, a_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, a_inFnStr);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeStr(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
        txt = Tpl.writeText(txt, a_boxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, a_boxPtrStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_fargsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_313;

public function functionHeaderImpl
  input Tpl.Text txt;
  input String a_fname;
  input list<SimCode.Variable> a_fargs;
  input list<SimCode.Variable> a_outVars;
  input Boolean a_inFunc;
  input Boolean a_boxed;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_inFnStr;
  Tpl.Text l_boxPtrStr;
  Tpl.Text l_boxStr;
  Tpl.Text l_fargsStr;
algorithm
  l_fargsStr := fun_302(Tpl.emptyTxt, a_boxed, a_fargs);
  l_boxStr := fun_303(Tpl.emptyTxt, a_boxed);
  l_boxPtrStr := fun_304(Tpl.emptyTxt, a_boxed);
  l_inFnStr := fun_306(Tpl.emptyTxt, a_boxed, a_fname, a_inFunc);
  out_txt := fun_313(txt, a_outVars, l_inFnStr, a_boxed, l_boxStr, l_fargsStr, a_fname, l_boxPtrStr);
end functionHeaderImpl;

public function funArgName
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      String i_name_1;
      DAE.ComponentRef i_name;

    case ( txt,
           SimCode.VARIABLE(name = i_name) )
      equation
        txt = contextCref(txt, i_name, SimCode.contextFunction);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name_1) )
      equation
        txt = Tpl.writeStr(txt, i_name_1);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgName;

public function funArgDefinition
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      String i_name_1;
      DAE.ComponentRef i_name;
      SimCode.Variable i_var;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name)) )
      equation
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = contextCref(txt, i_name, SimCode.contextFunction);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name_1) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr "));
        txt = Tpl.writeStr(txt, i_name_1);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgDefinition;

public function funArgBoxedDefinition
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      String i_name_1;
      DAE.ComponentRef i_name;

    case ( txt,
           SimCode.VARIABLE(name = i_name) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_metatype "));
        txt = contextCref(txt, i_name, SimCode.contextFunction);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name_1) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr "));
        txt = Tpl.writeStr(txt, i_name_1);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end funArgBoxedDefinition;

public function extFunDef
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn)
    local
      Tpl.Text txt;
      SimCode.SimExtArg i_extReturn;
      list<SimCode.SimExtArg> i_extArgs;
      String i_language;
      String i_extName;
      Tpl.Text l_fargsStr;
      Tpl.Text l_fn__name;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(extName = i_extName, language = i_language, extArgs = i_extArgs, extReturn = i_extReturn) )
      equation
        l_fn__name = extFunctionName(Tpl.emptyTxt, i_extName, i_language);
        l_fargsStr = extFunDefArgs(Tpl.emptyTxt, i_extArgs, i_language);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("extern "));
        txt = extReturnType(txt, i_extReturn);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, l_fn__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_fargsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDef;

protected function fun_319
  input Tpl.Text in_txt;
  input String in_a_language;
  input String in_a_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_language, in_a_name)
    local
      Tpl.Text txt;
      String a_name;

    case ( txt,
           "C",
           a_name )
      equation
        txt = Tpl.writeStr(txt, a_name);
      then txt;

    case ( txt,
           "FORTRAN 77",
           a_name )
      equation
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNSUPPORTED_LANGUAGE"));
      then txt;
  end matchcontinue;
end fun_319;

public function extFunctionName
  input Tpl.Text txt;
  input String a_name;
  input String a_language;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_319(txt, a_language, a_name);
end extFunctionName;

protected function lm_321
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      equation
        txt = extFunDefArg(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_321(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_321(txt, rest);
      then txt;
  end matchcontinue;
end lm_321;

protected function lm_322
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      equation
        txt = extFunDefArgF77(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_322(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_322(txt, rest);
      then txt;
  end matchcontinue;
end lm_322;

protected function fun_323
  input Tpl.Text in_txt;
  input String in_a_language;
  input list<SimCode.SimExtArg> in_a_args;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_language, in_a_args)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> a_args;

    case ( txt,
           "C",
           a_args )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_321(txt, a_args);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           "FORTRAN 77",
           a_args )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_322(txt, a_args);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNSUPPORTED_LANGUAGE"));
      then txt;
  end matchcontinue;
end fun_323;

public function extFunDefArgs
  input Tpl.Text txt;
  input list<SimCode.SimExtArg> a_args;
  input String a_language;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_323(txt, a_language, a_args);
end extFunDefArgs;

public function extReturnType
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extArg)
    local
      Tpl.Text txt;
      DAE.ExpType i_type__;

    case ( txt,
           SimCode.SIMEXTARG(type_ = i_type__) )
      equation
        txt = extType(txt, i_type__);
      then txt;

    case ( txt,
           SimCode.SIMNOEXTARG() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extReturnType;

public function extType
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;
      Absyn.Path i_rname;
      DAE.ExpType i_ty;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("double"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char*"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      equation
        txt = extType(txt, i_ty);
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void *"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_rname)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_rname);
      then txt;

    case ( txt,
           DAE.ET_METATYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void*"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("OTHER_EXT_TYPE"));
      then txt;
  end matchcontinue;
end extType;

protected function fun_327
  input Tpl.Text in_txt;
  input String in_mArg;
  input DAE.ExpType in_a_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_t)
    local
      Tpl.Text txt;
      DAE.ExpType a_t;

    case ( txt,
           "const char*",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const char* const *"));
      then txt;

    case ( txt,
           _,
           a_t )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("const "));
        txt = extType(txt, a_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" *"));
      then txt;
  end matchcontinue;
end fun_327;

protected function fun_328
  input Tpl.Text in_txt;
  input Boolean in_a_ia;
  input DAE.ExpType in_a_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ia, in_a_t)
    local
      Tpl.Text txt;
      DAE.ExpType a_t;
      String str_1;
      Tpl.Text txt_0;

    case ( txt,
           false,
           a_t )
      equation
        txt = extType(txt, a_t);
      then txt;

    case ( txt,
           _,
           a_t )
      equation
        txt_0 = extType(Tpl.emptyTxt, a_t);
        str_1 = Tpl.textString(txt_0);
        txt = fun_327(txt, str_1, a_t);
      then txt;
  end matchcontinue;
end fun_328;

protected function fun_329
  input Tpl.Text in_txt;
  input Boolean in_a_ii;
  input Boolean in_a_ia;
  input DAE.ExpType in_a_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ii, in_a_ia, in_a_t)
    local
      Tpl.Text txt;
      Boolean a_ia;
      DAE.ExpType a_t;

    case ( txt,
           false,
           _,
           a_t )
      equation
        txt = extType(txt, a_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*"));
      then txt;

    case ( txt,
           _,
           a_ia,
           a_t )
      equation
        txt = fun_328(txt, a_ia, a_t);
      then txt;
  end matchcontinue;
end fun_329;

public function extFunDefArg
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extArg)
    local
      Tpl.Text txt;
      DAE.Exp i_exp;
      DAE.ExpType i_type__;
      Boolean i_ia;
      DAE.ExpType i_t;
      Boolean i_ii;
      DAE.ComponentRef i_c;
      Tpl.Text l_eStr;
      Tpl.Text l_typeStr;
      Tpl.Text l_name;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = i_ii, isArray = i_ia, type_ = i_t) )
      equation
        l_name = contextCref(Tpl.emptyTxt, i_c, SimCode.contextFunction);
        l_typeStr = fun_329(Tpl.emptyTxt, i_ii, i_ia, i_t);
        txt = Tpl.writeText(txt, l_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, l_name);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGEXP(type_ = i_type__) )
      equation
        l_typeStr = extType(Tpl.emptyTxt, i_type__);
        txt = Tpl.writeText(txt, l_typeStr);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, exp = i_exp) )
      equation
        l_name = contextCref(Tpl.emptyTxt, i_c, SimCode.contextFunction);
        l_eStr = daeExpToString(Tpl.emptyTxt, i_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size_t "));
        txt = Tpl.writeText(txt, l_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeText(txt, l_eStr);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDefArg;

public function extFunDefArgF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extArg)
    local
      Tpl.Text txt;
      SimCode.SimExtArg i_extArg;
      DAE.ExpType i_t;
      DAE.ComponentRef i_c;
      Tpl.Text l_typeStr;
      Tpl.Text l_name;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = true, type_ = i_t) )
      equation
        l_name = contextCref(Tpl.emptyTxt, i_c, SimCode.contextFunction);
        l_typeStr = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("const "));
        l_typeStr = extType(l_typeStr, i_t);
        l_typeStr = Tpl.writeTok(l_typeStr, Tpl.ST_STRING(" *"));
        txt = Tpl.writeText(txt, l_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, l_name);
      then txt;

    case ( txt,
           (i_extArg as SimCode.SIMEXTARG(cref = _)) )
      equation
        txt = extFunDefArg(txt, i_extArg);
      then txt;

    case ( txt,
           (i_extArg as SimCode.SIMEXTARGEXP(exp = _)) )
      equation
        txt = extFunDefArg(txt, i_extArg);
      then txt;

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int const *"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunDefArgF77;

public function daeExpToString
  input Tpl.Text txt;
  input DAE.Exp a_exp;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_varDecls;
  Tpl.Text l_preExp;
algorithm
  l_preExp := Tpl.emptyTxt;
  l_varDecls := Tpl.emptyTxt;
  (out_txt, l_preExp, l_varDecls) := daeExp(txt, a_exp, SimCode.contextFunction, l_preExp, l_varDecls);
end daeExpToString;

protected function lm_333
  input Tpl.Text in_txt;
  input list<SimCode.Function> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Function> rest;
      SimCode.Function i_fn;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_fn :: rest )
      equation
        txt = functionBody(txt, i_fn, false);
        txt = Tpl.nextIter(txt);
        txt = lm_333(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_333(txt, rest);
      then txt;
  end matchcontinue;
end lm_333;

public function functionBodies
  input Tpl.Text txt;
  input list<SimCode.Function> a_functions;

  output Tpl.Text out_txt;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_333(out_txt, a_functions);
  out_txt := Tpl.popIter(out_txt);
end functionBodies;

public function functionBody
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;
  input Boolean in_a_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn, in_a_inFunc)
    local
      Tpl.Text txt;
      Boolean a_inFunc;
      SimCode.Function i_fn;

    case ( txt,
           (i_fn as SimCode.FUNCTION(name = _)),
           a_inFunc )
      equation
        txt = functionBodyRegularFunction(txt, i_fn, a_inFunc);
      then txt;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(name = _)),
           a_inFunc )
      equation
        txt = functionBodyExternalFunction(txt, i_fn, a_inFunc);
      then txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = _)),
           _ )
      equation
        txt = functionBodyRecordConstructor(txt, i_fn);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionBody;

protected function fun_336
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars, in_a_fname)
    local
      Tpl.Text txt;
      Tpl.Text a_fname;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           a_fname )
      equation
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
      then txt;
  end matchcontinue;
end fun_336;

protected function fun_337
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_retType;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_outVars, in_a_varDecls, in_a_retType)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_retType;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls,
           a_retType )
      equation
        (txt, a_varDecls) = tempDecl(txt, Tpl.textString(a_retType), a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end fun_337;

protected function fun_338
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;

    case ( txt,
           false,
           a_varDecls )
      equation
        (txt, a_varDecls) = tempDecl(txt, "state", a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_338;

protected function lm_339
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_varInits;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varInits;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varInits, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varInits, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_varInits;
      Tpl.Text a_varDecls;
      Integer x_i1;
      SimCode.Variable i_var;

    case ( txt,
           {},
           a_varInits,
           a_varDecls )
      then (txt, a_varInits, a_varDecls);

    case ( txt,
           i_var :: rest,
           a_varInits,
           a_varDecls )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls, a_varInits) = varInit(txt, i_var, "", x_i1, a_varDecls, a_varInits);
        txt = Tpl.nextIter(txt);
        (txt, a_varInits, a_varDecls) = lm_339(txt, rest, a_varInits, a_varDecls);
      then (txt, a_varInits, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varInits,
           a_varDecls )
      equation
        (txt, a_varInits, a_varDecls) = lm_339(txt, rest, a_varInits, a_varDecls);
      then (txt, a_varInits, a_varDecls);
  end matchcontinue;
end lm_339;

protected function lm_340
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varInits) :=
  matchcontinue(in_txt, in_items, in_a_varInits)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_varInits;
      SimCode.Variable i_var;

    case ( txt,
           {},
           a_varInits )
      then (txt, a_varInits);

    case ( txt,
           i_var :: rest,
           a_varInits )
      equation
        (txt, a_varInits) = functionArg(txt, i_var, a_varInits);
        txt = Tpl.nextIter(txt);
        (txt, a_varInits) = lm_340(txt, rest, a_varInits);
      then (txt, a_varInits);

    case ( txt,
           _ :: rest,
           a_varInits )
      equation
        (txt, a_varInits) = lm_340(txt, rest, a_varInits);
      then (txt, a_varInits);
  end matchcontinue;
end lm_340;

protected function lm_341
  input Tpl.Text in_txt;
  input list<SimCode.Statement> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = funStatement(txt, i_stmt, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_341(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_341(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_341;

protected function lm_342
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_outVarAssign;
  input Tpl.Text in_a_outVarCopy;
  input Tpl.Text in_a_outVarInits;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_retVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_outVarAssign;
  output Tpl.Text out_a_outVarCopy;
  output Tpl.Text out_a_outVarInits;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_outVarAssign, out_a_outVarCopy, out_a_outVarInits, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_outVarAssign, in_a_outVarCopy, in_a_outVarInits, in_a_varDecls, in_a_retVar)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_outVarAssign;
      Tpl.Text a_outVarCopy;
      Tpl.Text a_outVarInits;
      Tpl.Text a_varDecls;
      Tpl.Text a_retVar;
      Integer x_i1;
      SimCode.Variable i_var;

    case ( txt,
           {},
           a_outVarAssign,
           a_outVarCopy,
           a_outVarInits,
           a_varDecls,
           _ )
      then (txt, a_outVarAssign, a_outVarCopy, a_outVarInits, a_varDecls);

    case ( txt,
           i_var :: rest,
           a_outVarAssign,
           a_outVarCopy,
           a_outVarInits,
           a_varDecls,
           a_retVar )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls, a_outVarInits, a_outVarCopy, a_outVarAssign) = varOutput(txt, i_var, Tpl.textString(a_retVar), x_i1, a_varDecls, a_outVarInits, a_outVarCopy, a_outVarAssign);
        txt = Tpl.nextIter(txt);
        (txt, a_outVarAssign, a_outVarCopy, a_outVarInits, a_varDecls) = lm_342(txt, rest, a_outVarAssign, a_outVarCopy, a_outVarInits, a_varDecls, a_retVar);
      then (txt, a_outVarAssign, a_outVarCopy, a_outVarInits, a_varDecls);

    case ( txt,
           _ :: rest,
           a_outVarAssign,
           a_outVarCopy,
           a_outVarInits,
           a_varDecls,
           a_retVar )
      equation
        (txt, a_outVarAssign, a_outVarCopy, a_outVarInits, a_varDecls) = lm_342(txt, rest, a_outVarAssign, a_outVarCopy, a_outVarInits, a_varDecls, a_retVar);
      then (txt, a_outVarAssign, a_outVarCopy, a_outVarInits, a_varDecls);
  end matchcontinue;
end lm_342;

protected function fun_343
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input SimCode.Function in_a_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_fn)
    local
      Tpl.Text txt;
      SimCode.Function a_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           a_fn )
      equation
        txt = functionBodyBoxed(txt, a_fn);
      then txt;
  end matchcontinue;
end fun_343;

protected function lm_344
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_344(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_344(txt, rest);
      then txt;
  end matchcontinue;
end lm_344;

protected function fun_345
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_memory_state();"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_345;

protected function fun_346
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_346;

protected function fun_347
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_retVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars, in_a_retVar)
    local
      Tpl.Text txt;
      Tpl.Text a_retVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           a_retVar )
      equation
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(1));
        txt = Tpl.writeText(txt, a_retVar);
        txt = Tpl.popBlock(txt);
      then txt;
  end matchcontinue;
end fun_347;

protected function lm_348
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgDefinition(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_348(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_348(txt, rest);
      then txt;
  end matchcontinue;
end lm_348;

protected function fun_349
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_retType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars, in_a_retType)
    local
      Tpl.Text txt;
      Tpl.Text a_retType;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           a_retType )
      equation
        txt = Tpl.writeText(txt, a_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" out;"));
      then txt;
  end matchcontinue;
end fun_349;

protected function lm_350
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_arg;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      equation
        txt = readInVar(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_350(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_350(txt, rest);
      then txt;
  end matchcontinue;
end lm_350;

protected function fun_351
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars)
    local
      Tpl.Text txt;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out = "));
      then txt;
  end matchcontinue;
end fun_351;

protected function lm_352
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgName(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_352(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_352(txt, rest);
      then txt;
  end matchcontinue;
end lm_352;

protected function lm_353
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Integer x_i1;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        txt = writeOutVar(txt, i_var, x_i1);
        txt = Tpl.nextIter(txt);
        txt = lm_353(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_353(txt, rest);
      then txt;
  end matchcontinue;
end lm_353;

protected function fun_354
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_outVars;

    case ( txt,
           {} )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_noretcall(outVar);"));
      then txt;

    case ( txt,
           i_outVars )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_353(txt, i_outVars);
        txt = Tpl.popIter(txt);
      then txt;
  end matchcontinue;
end fun_354;

protected function fun_355
  input Tpl.Text in_txt;
  input Boolean in_a_inFunc;
  input Tpl.Text in_a_retType;
  input list<SimCode.Variable> in_a_outVars;
  input list<SimCode.Variable> in_a_functionArguments;
  input Tpl.Text in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_inFunc, in_a_retType, in_a_outVars, in_a_functionArguments, in_a_fname)
    local
      Tpl.Text txt;
      Tpl.Text a_retType;
      list<SimCode.Variable> a_outVars;
      list<SimCode.Variable> a_functionArguments;
      Tpl.Text a_fname;

    case ( txt,
           false,
           _,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           a_retType,
           a_outVars,
           a_functionArguments,
           a_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int in_"));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(type_description * inArgs, type_description * outVar)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_348(txt, a_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_349(txt, a_outVars, a_retType);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_350(txt, a_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("MMC_TRY_TOP()\n"));
        txt = fun_351(txt, a_outVars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_352(txt, a_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "MMC_CATCH_TOP(return 1)\n"
                                }, true));
        txt = fun_354(txt, a_outVars);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;
  end matchcontinue;
end fun_355;

public function functionBodyRegularFunction
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;
  input Boolean in_a_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn, in_a_inFunc)
    local
      Tpl.Text txt;
      Boolean a_inFunc;
      SimCode.Function i_fn;
      list<SimCode.Statement> i_body;
      list<SimCode.Variable> i_functionArguments;
      list<SimCode.Variable> i_variableDeclarations;
      list<SimCode.Variable> i_outVars;
      Absyn.Path i_name;
      Boolean ret_17;
      Boolean ret_16;
      Boolean ret_15;
      Tpl.Text l_boxedFn;
      Tpl.Text l_0__1;
      Tpl.Text l_outVarAssign;
      Tpl.Text l_outVarCopy;
      Tpl.Text l_outVarInits;
      Tpl.Text l_bodyPart;
      Tpl.Text l_funArgs;
      Tpl.Text l_0__;
      Boolean ret_6;
      Tpl.Text l_stateVar;
      Tpl.Text l_retVar;
      Tpl.Text l_varInits;
      Tpl.Text l_varDecls;
      Tpl.Text l_retType;
      Tpl.Text l_fname;

    case ( txt,
           (i_fn as SimCode.FUNCTION(name = i_name, outVars = i_outVars, variableDeclarations = i_variableDeclarations, functionArguments = i_functionArguments, body = i_body)),
           a_inFunc )
      equation
        System.tmpTickReset(1);
        l_fname = underscorePath(Tpl.emptyTxt, i_name);
        l_retType = fun_336(Tpl.emptyTxt, i_outVars, l_fname);
        l_varDecls = Tpl.emptyTxt;
        l_varInits = Tpl.emptyTxt;
        (l_retVar, l_varDecls) = fun_337(Tpl.emptyTxt, i_outVars, l_varDecls, l_retType);
        ret_6 = RTOpts.acceptMetaModelicaGrammar();
        (l_stateVar, l_varDecls) = fun_338(Tpl.emptyTxt, ret_6, l_varDecls);
        l_0__ = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(1, NONE(), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_0__, l_varInits, l_varDecls) = lm_339(l_0__, i_variableDeclarations, l_varInits, l_varDecls);
        l_0__ = Tpl.popIter(l_0__);
        l_funArgs = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_funArgs, l_varInits) = lm_340(l_funArgs, i_functionArguments, l_varInits);
        l_funArgs = Tpl.popIter(l_funArgs);
        l_bodyPart = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_bodyPart, l_varDecls) = lm_341(l_bodyPart, i_body, l_varDecls);
        l_bodyPart = Tpl.popIter(l_bodyPart);
        l_outVarInits = Tpl.emptyTxt;
        l_outVarCopy = Tpl.emptyTxt;
        l_outVarAssign = Tpl.emptyTxt;
        l_0__1 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(1, SOME(Tpl.ST_STRING("")), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_0__1, l_outVarAssign, l_outVarCopy, l_outVarInits, l_varDecls) = lm_342(l_0__1, i_outVars, l_outVarAssign, l_outVarCopy, l_outVarInits, l_varDecls, l_retVar);
        l_0__1 = Tpl.popIter(l_0__1);
        ret_15 = RTOpts.acceptMetaModelicaGrammar();
        l_boxedFn = fun_343(Tpl.emptyTxt, ret_15, i_fn);
        txt = Tpl.writeText(txt, l_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_344(txt, i_functionArguments);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_funArgs);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_outVarInits);
        txt = Tpl.softNewLine(txt);
        ret_16 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_345(txt, ret_16, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_varInits);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_bodyPart);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "_return:\n"
                                }, true));
        txt = Tpl.writeText(txt, l_outVarCopy);
        txt = Tpl.softNewLine(txt);
        ret_17 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_346(txt, ret_17, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_outVarAssign);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("return"));
        txt = fun_347(txt, i_outVars, l_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = fun_355(txt, a_inFunc, l_retType, i_outVars, i_functionArguments, l_fname);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_boxedFn);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionBodyRegularFunction;

protected function fun_357
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars, in_a_fname)
    local
      Tpl.Text txt;
      Tpl.Text a_fname;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           a_fname )
      equation
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
      then txt;
  end matchcontinue;
end fun_357;

protected function fun_358
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_retType;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_outVars, in_a_varDecls, in_a_retType)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_retType;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls,
           a_retType )
      equation
        (txt, a_varDecls) = outDecl(txt, Tpl.textString(a_retType), a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end fun_358;

protected function fun_359
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;

    case ( txt,
           false,
           a_varDecls )
      equation
        (txt, a_varDecls) = tempDecl(txt, "state", a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_359;

protected function lm_360
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_outputAlloc;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_retVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_outputAlloc;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_outputAlloc, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_outputAlloc, in_a_varDecls, in_a_retVar)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_outputAlloc;
      Tpl.Text a_varDecls;
      Tpl.Text a_retVar;
      Integer x_i1;
      SimCode.Variable i_var;

    case ( txt,
           {},
           a_outputAlloc,
           a_varDecls,
           _ )
      then (txt, a_outputAlloc, a_varDecls);

    case ( txt,
           i_var :: rest,
           a_outputAlloc,
           a_varDecls,
           a_retVar )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        (txt, a_varDecls, a_outputAlloc) = varInit(txt, i_var, Tpl.textString(a_retVar), x_i1, a_varDecls, a_outputAlloc);
        txt = Tpl.nextIter(txt);
        (txt, a_outputAlloc, a_varDecls) = lm_360(txt, rest, a_outputAlloc, a_varDecls, a_retVar);
      then (txt, a_outputAlloc, a_varDecls);

    case ( txt,
           _ :: rest,
           a_outputAlloc,
           a_varDecls,
           a_retVar )
      equation
        (txt, a_outputAlloc, a_varDecls) = lm_360(txt, rest, a_outputAlloc, a_varDecls, a_retVar);
      then (txt, a_outputAlloc, a_varDecls);
  end matchcontinue;
end lm_360;

protected function fun_361
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input SimCode.Function in_a_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_fn)
    local
      Tpl.Text txt;
      SimCode.Function a_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           a_fn )
      equation
        txt = functionBodyBoxed(txt, a_fn);
      then txt;
  end matchcontinue;
end fun_361;

protected function lm_362
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_name;
      DAE.ExpType i_ty;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = contextCref(txt, i_name, SimCode.contextFunction);
        txt = Tpl.nextIter(txt);
        txt = lm_362(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_362(txt, rest);
      then txt;
  end matchcontinue;
end lm_362;

protected function fun_363
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_memory_state();"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_363;

protected function fun_364
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_364;

protected function fun_365
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_retVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outVars, in_a_retVar)
    local
      Tpl.Text txt;
      Tpl.Text a_retVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           a_retVar )
      equation
        txt = Tpl.writeText(txt, a_retVar);
      then txt;
  end matchcontinue;
end fun_365;

protected function lm_366
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_name;
      DAE.ExpType i_ty;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = contextCref(txt, i_name, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_366(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_366(txt, rest);
      then txt;
  end matchcontinue;
end lm_366;

protected function lm_367
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_arg;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_arg as SimCode.VARIABLE(name = _)) :: rest )
      equation
        txt = readInVar(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_367(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_367(txt, rest);
      then txt;
  end matchcontinue;
end lm_367;

protected function lm_368
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest )
      equation
        txt = contextCref(txt, i_name, SimCode.contextFunction);
        txt = Tpl.nextIter(txt);
        txt = lm_368(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_368(txt, rest);
      then txt;
  end matchcontinue;
end lm_368;

protected function lm_369
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Integer x_i1;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = _)) :: rest )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        txt = writeOutVar(txt, i_var, x_i1);
        txt = Tpl.nextIter(txt);
        txt = lm_369(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_369(txt, rest);
      then txt;
  end matchcontinue;
end lm_369;

protected function fun_370
  input Tpl.Text in_txt;
  input Boolean in_a_inFunc;
  input list<SimCode.Variable> in_a_outVars;
  input Tpl.Text in_a_retType;
  input list<SimCode.Variable> in_a_funArgs;
  input Tpl.Text in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_inFunc, in_a_outVars, in_a_retType, in_a_funArgs, in_a_fname)
    local
      Tpl.Text txt;
      list<SimCode.Variable> a_outVars;
      Tpl.Text a_retType;
      list<SimCode.Variable> a_funArgs;
      Tpl.Text a_fname;

    case ( txt,
           false,
           _,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           _,
           a_outVars,
           a_retType,
           a_funArgs,
           a_fname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int in_"));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "(type_description * inArgs, type_description * outVar)\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_366(txt, a_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, a_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" out;\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_367(txt, a_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out = _"));
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_368(txt, a_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_369(txt, a_outVars);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("return 0;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;
  end matchcontinue;
end fun_370;

public function functionBodyExternalFunction
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;
  input Boolean in_a_inFunc;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn, in_a_inFunc)
    local
      Tpl.Text txt;
      Boolean a_inFunc;
      list<SimCode.Variable> i_funArgs;
      SimCode.Function i_fn;
      list<SimCode.Variable> i_outVars;
      Absyn.Path i_name;
      Boolean ret_13;
      Boolean ret_12;
      Boolean ret_11;
      Tpl.Text l_boxedFn;
      Tpl.Text l_0__;
      Tpl.Text l_callPart;
      Boolean ret_7;
      Tpl.Text l_stateVar;
      Tpl.Text l_outputAlloc;
      Tpl.Text l_retVar;
      Tpl.Text l_varDecls;
      Tpl.Text l_preExp;
      Tpl.Text l_retType;
      Tpl.Text l_fname;

    case ( txt,
           (i_fn as SimCode.EXTERNAL_FUNCTION(name = i_name, outVars = i_outVars, funArgs = i_funArgs)),
           a_inFunc )
      equation
        System.tmpTickReset(1);
        l_fname = underscorePath(Tpl.emptyTxt, i_name);
        l_retType = fun_357(Tpl.emptyTxt, i_outVars, l_fname);
        l_preExp = Tpl.emptyTxt;
        l_varDecls = Tpl.emptyTxt;
        (l_retVar, l_varDecls) = fun_358(Tpl.emptyTxt, i_outVars, l_varDecls, l_retType);
        l_outputAlloc = Tpl.emptyTxt;
        ret_7 = RTOpts.acceptMetaModelicaGrammar();
        (l_stateVar, l_varDecls) = fun_359(Tpl.emptyTxt, ret_7, l_varDecls);
        (l_callPart, l_preExp, l_varDecls) = extFunCall(Tpl.emptyTxt, i_fn, l_preExp, l_varDecls);
        l_0__ = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(1, NONE(), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_0__, l_outputAlloc, l_varDecls) = lm_360(l_0__, i_outVars, l_outputAlloc, l_varDecls, l_retVar);
        l_0__ = Tpl.popIter(l_0__);
        ret_11 = RTOpts.acceptMetaModelicaGrammar();
        l_boxedFn = fun_361(Tpl.emptyTxt, ret_11, i_fn);
        txt = Tpl.writeText(txt, l_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_362(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_varDecls);
        txt = Tpl.softNewLine(txt);
        ret_12 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_363(txt, ret_12, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_outputAlloc);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_callPart);
        txt = Tpl.softNewLine(txt);
        ret_13 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_364(txt, ret_13, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("return "));
        txt = fun_365(txt, i_outVars, l_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = fun_370(txt, a_inFunc, i_outVars, l_retType, i_funArgs, l_fname);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_boxedFn);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end functionBodyExternalFunction;

protected function fun_372
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input SimCode.Function in_a_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_fn)
    local
      Tpl.Text txt;
      SimCode.Function a_fn;

    case ( txt,
           false,
           _ )
      then txt;

    case ( txt,
           _,
           a_fn )
      equation
        txt = functionBodyBoxed(txt, a_fn);
      then txt;
  end matchcontinue;
end fun_372;

protected function lm_373
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_name;
      DAE.ExpType i_ty;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) :: rest )
      equation
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = crefStr(txt, i_name);
        txt = Tpl.nextIter(txt);
        txt = lm_373(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_373(txt, rest);
      then txt;
  end matchcontinue;
end lm_373;

protected function lm_374
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_structVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_structVar)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_structVar;
      DAE.ComponentRef i_name;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest,
           a_structVar )
      equation
        txt = Tpl.writeText(txt, a_structVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = crefStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_374(txt, rest, a_structVar);
      then txt;

    case ( txt,
           _ :: rest,
           a_structVar )
      equation
        txt = lm_374(txt, rest, a_structVar);
      then txt;
  end matchcontinue;
end lm_374;

public function functionBodyRecordConstructor
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_funArgs;
      SimCode.Function i_fn;
      Absyn.Path i_name;
      Boolean ret_7;
      Tpl.Text l_boxedFn;
      Tpl.Text l_structVar;
      Tpl.Text l_structType;
      Tpl.Text l_retVar;
      Tpl.Text l_retType;
      Tpl.Text l_fname;
      Tpl.Text l_varDecls;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs)) )
      equation
        System.tmpTickReset(1);
        l_varDecls = Tpl.emptyTxt;
        l_fname = underscorePath(Tpl.emptyTxt, i_name);
        l_retType = Tpl.writeText(Tpl.emptyTxt, l_fname);
        l_retType = Tpl.writeTok(l_retType, Tpl.ST_STRING("_rettype"));
        (l_retVar, l_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_retType), l_varDecls);
        l_structType = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("struct "));
        l_structType = Tpl.writeText(l_structType, l_fname);
        (l_structVar, l_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_structType), l_varDecls);
        ret_7 = RTOpts.acceptMetaModelicaGrammar();
        l_boxedFn = fun_372(Tpl.emptyTxt, ret_7, i_fn);
        txt = Tpl.writeText(txt, l_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" _"));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_373(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_374(txt, i_funArgs, l_structVar);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ1 = "));
        txt = Tpl.writeText(txt, l_structVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "return "
                                }, false));
        txt = Tpl.writeText(txt, l_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "}\n",
                                    "\n"
                                }, true));
        txt = Tpl.writeText(txt, l_boxedFn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyRecordConstructor;

public function functionBodyBoxed
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn)
    local
      Tpl.Text txt;
      SimCode.Function i_fn;
      list<SimCode.Variable> i_funArgs;
      list<SimCode.Variable> i_outVars;
      list<SimCode.Variable> i_functionArguments;
      Absyn.Path i_name;

    case ( txt,
           SimCode.FUNCTION(name = i_name, functionArguments = i_functionArguments, outVars = i_outVars) )
      equation
        txt = functionBodyBoxedImpl(txt, i_name, i_functionArguments, i_outVars);
      then txt;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(name = i_name, funArgs = i_funArgs, outVars = i_outVars) )
      equation
        txt = functionBodyBoxedImpl(txt, i_name, i_funArgs, i_outVars);
      then txt;

    case ( txt,
           (i_fn as SimCode.RECORD_CONSTRUCTOR(name = _)) )
      equation
        txt = boxRecordConstructor(txt, i_fn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end functionBodyBoxed;

protected function fun_377
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outvars;
  input Tpl.Text in_a_fname;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outvars, in_a_fname)
    local
      Tpl.Text txt;
      Tpl.Text a_fname;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           a_fname )
      equation
        txt = Tpl.writeText(txt, a_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_rettype"));
      then txt;
  end matchcontinue;
end fun_377;

protected function fun_378
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outvars;
  input Tpl.Text in_a_retType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outvars, in_a_retType)
    local
      Tpl.Text txt;
      Tpl.Text a_retType;

    case ( txt,
           {},
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void"));
      then txt;

    case ( txt,
           _,
           a_retType )
      equation
        txt = Tpl.writeText(txt, a_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boxed"));
      then txt;
  end matchcontinue;
end fun_378;

protected function fun_379
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outvars;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_retTypeBoxed;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_outvars, in_a_varDecls, in_a_retTypeBoxed)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_retTypeBoxed;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls,
           a_retTypeBoxed )
      equation
        (txt, a_varDecls) = tempDecl(txt, Tpl.textString(a_retTypeBoxed), a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end fun_379;

protected function fun_380
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outvars;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_retType;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_outvars, in_a_varDecls, in_a_retType)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_retType;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls,
           a_retType )
      equation
        (txt, a_varDecls) = tempDecl(txt, Tpl.textString(a_retType), a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end fun_380;

protected function fun_381
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;

    case ( txt,
           false,
           a_varDecls )
      equation
        (txt, a_varDecls) = tempDecl(txt, "state", a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_381;

protected function lm_382
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_varBox;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varBox;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varBox, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varBox, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_varBox;
      Tpl.Text a_varDecls;
      SimCode.Variable i_arg;

    case ( txt,
           {},
           a_varBox,
           a_varDecls )
      then (txt, a_varBox, a_varDecls);

    case ( txt,
           i_arg :: rest,
           a_varBox,
           a_varDecls )
      equation
        (txt, a_varDecls, a_varBox) = funArgUnbox(txt, i_arg, a_varDecls, a_varBox);
        txt = Tpl.nextIter(txt);
        (txt, a_varBox, a_varDecls) = lm_382(txt, rest, a_varBox, a_varDecls);
      then (txt, a_varBox, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varBox,
           a_varDecls )
      equation
        (txt, a_varBox, a_varDecls) = lm_382(txt, rest, a_varBox, a_varDecls);
      then (txt, a_varBox, a_varDecls);
  end matchcontinue;
end lm_382;

protected function lm_383
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varUnbox;
  input Tpl.Text in_a_retTypeBoxed;
  input Tpl.Text in_a_retVar;
  input Tpl.Text in_a_retType;
  input Tpl.Text in_a_funRetVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varUnbox;
algorithm
  (out_txt, out_a_varDecls, out_a_varUnbox) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_varUnbox, in_a_retTypeBoxed, in_a_retVar, in_a_retType, in_a_funRetVar)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_varUnbox;
      Tpl.Text a_retTypeBoxed;
      Tpl.Text a_retVar;
      Tpl.Text a_retType;
      Tpl.Text a_funRetVar;
      Integer x_i1;
      DAE.ExpType i_ty;
      Tpl.Text l_arg;

    case ( txt,
           {},
           a_varDecls,
           a_varUnbox,
           _,
           _,
           _,
           _ )
      then (txt, a_varDecls, a_varUnbox);

    case ( txt,
           SimCode.VARIABLE(ty = i_ty) :: rest,
           a_varDecls,
           a_varUnbox,
           a_retTypeBoxed,
           a_retVar,
           a_retType,
           a_funRetVar )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        l_arg = Tpl.writeText(Tpl.emptyTxt, a_funRetVar);
        l_arg = Tpl.writeTok(l_arg, Tpl.ST_STRING("."));
        l_arg = Tpl.writeText(l_arg, a_retType);
        l_arg = Tpl.writeTok(l_arg, Tpl.ST_STRING("_"));
        l_arg = Tpl.writeStr(l_arg, intString(x_i1));
        txt = Tpl.writeText(txt, a_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, a_retTypeBoxed);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, a_varUnbox, a_varDecls) = funArgBox(txt, Tpl.textString(l_arg), i_ty, a_varUnbox, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_varUnbox) = lm_383(txt, rest, a_varDecls, a_varUnbox, a_retTypeBoxed, a_retVar, a_retType, a_funRetVar);
      then (txt, a_varDecls, a_varUnbox);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_varUnbox,
           a_retTypeBoxed,
           a_retVar,
           a_retType,
           a_funRetVar )
      equation
        (txt, a_varDecls, a_varUnbox) = lm_383(txt, rest, a_varDecls, a_varUnbox, a_retTypeBoxed, a_retVar, a_retType, a_funRetVar);
      then (txt, a_varDecls, a_varUnbox);
  end matchcontinue;
end lm_383;

protected function lm_384
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_384(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_384(txt, rest);
      then txt;
  end matchcontinue;
end lm_384;

protected function fun_385
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_memory_state();"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_385;

protected function fun_386
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_a_outvars;
  input Tpl.Text in_a_funRetVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outvars, in_a_funRetVar)
    local
      Tpl.Text txt;
      Tpl.Text a_funRetVar;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _,
           a_funRetVar )
      equation
        txt = Tpl.writeText(txt, a_funRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;
  end matchcontinue;
end fun_386;

protected function fun_387
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_387;

public function functionBodyBoxedImpl
  input Tpl.Text txt;
  input Absyn.Path a_name;
  input list<SimCode.Variable> a_funargs;
  input list<SimCode.Variable> a_outvars;

  output Tpl.Text out_txt;
protected
  Boolean ret_13;
  Boolean ret_12;
  Tpl.Text l_retStr;
  Tpl.Text l_args;
  Tpl.Text l_varUnbox;
  Tpl.Text l_varBox;
  Boolean ret_7;
  Tpl.Text l_stateVar;
  Tpl.Text l_funRetVar;
  Tpl.Text l_retVar;
  Tpl.Text l_varDecls;
  Tpl.Text l_retTypeBoxed;
  Tpl.Text l_retType;
  Tpl.Text l_fname;
algorithm
  System.tmpTickReset(1);
  l_fname := underscorePath(Tpl.emptyTxt, a_name);
  l_retType := fun_377(Tpl.emptyTxt, a_outvars, l_fname);
  l_retTypeBoxed := fun_378(Tpl.emptyTxt, a_outvars, l_retType);
  l_varDecls := Tpl.emptyTxt;
  (l_retVar, l_varDecls) := fun_379(Tpl.emptyTxt, a_outvars, l_varDecls, l_retTypeBoxed);
  (l_funRetVar, l_varDecls) := fun_380(Tpl.emptyTxt, a_outvars, l_varDecls, l_retType);
  ret_7 := RTOpts.acceptMetaModelicaGrammar();
  (l_stateVar, l_varDecls) := fun_381(Tpl.emptyTxt, ret_7, l_varDecls);
  l_varBox := Tpl.emptyTxt;
  l_varUnbox := Tpl.emptyTxt;
  l_args := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_args, l_varBox, l_varDecls) := lm_382(l_args, a_funargs, l_varBox, l_varDecls);
  l_args := Tpl.popIter(l_args);
  l_retStr := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_retStr, l_varDecls, l_varUnbox) := lm_383(l_retStr, a_outvars, l_varDecls, l_varUnbox, l_retTypeBoxed, l_retVar, l_retType, l_funRetVar);
  l_retStr := Tpl.popIter(l_retStr);
  out_txt := Tpl.writeText(txt, l_retTypeBoxed);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" boxptr_"));
  out_txt := Tpl.writeText(out_txt, l_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.pushIter(out_txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  out_txt := lm_384(out_txt, a_funargs);
  out_txt := Tpl.popIter(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ")\n",
                                       "{\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_varDecls);
  out_txt := Tpl.softNewLine(out_txt);
  ret_12 := RTOpts.acceptMetaModelicaGrammar();
  out_txt := fun_385(out_txt, ret_12, l_stateVar);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_varBox);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := fun_386(out_txt, a_outvars, l_funRetVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_"));
  out_txt := Tpl.writeText(out_txt, l_fname);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.writeText(out_txt, l_args);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(");\n"));
  out_txt := Tpl.writeText(out_txt, l_varUnbox);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_retStr);
  out_txt := Tpl.softNewLine(out_txt);
  ret_13 := RTOpts.acceptMetaModelicaGrammar();
  out_txt := fun_387(out_txt, ret_13, l_stateVar);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("return "));
  out_txt := Tpl.writeText(out_txt, l_retVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(";\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end functionBodyBoxedImpl;

protected function fun_389
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;

    case ( txt,
           false,
           a_varDecls )
      equation
        (txt, a_varDecls) = tempDecl(txt, "state", a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_389;

protected function lm_390
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      DAE.ComponentRef i_name;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name) :: rest )
      equation
        txt = contextCref(txt, i_name, SimCode.contextFunction);
        txt = Tpl.nextIter(txt);
        txt = lm_390(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_390(txt, rest);
      then txt;
  end matchcontinue;
end lm_390;

protected function lm_391
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_var;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_var :: rest )
      equation
        txt = funArgBoxedDefinition(txt, i_var);
        txt = Tpl.nextIter(txt);
        txt = lm_391(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_391(txt, rest);
      then txt;
  end matchcontinue;
end lm_391;

protected function fun_392
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_memory_state();"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_392;

protected function fun_393
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_393;

public function boxRecordConstructor
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_fn)
    local
      Tpl.Text txt;
      list<SimCode.Variable> i_funArgs;
      Absyn.Path i_name;
      Boolean ret_13;
      Boolean ret_12;
      Integer ret_11;
      Integer ret_10;
      Tpl.Text l_funArgCount;
      Tpl.Text l_boxRetVar;
      Tpl.Text l_funArgsStr;
      Tpl.Text l_retVar;
      Tpl.Text l_retType;
      Tpl.Text l_fname;
      Boolean ret_3;
      Tpl.Text l_stateVar;
      Tpl.Text l_preExp;
      Tpl.Text l_varDecls;

    case ( txt,
           SimCode.RECORD_CONSTRUCTOR(name = i_name, funArgs = i_funArgs) )
      equation
        System.tmpTickReset(1);
        l_varDecls = Tpl.emptyTxt;
        l_preExp = Tpl.emptyTxt;
        ret_3 = RTOpts.acceptMetaModelicaGrammar();
        (l_stateVar, l_varDecls) = fun_389(Tpl.emptyTxt, ret_3, l_varDecls);
        l_fname = underscorePath(Tpl.emptyTxt, i_name);
        l_retType = Tpl.writeText(Tpl.emptyTxt, l_fname);
        l_retType = Tpl.writeTok(l_retType, Tpl.ST_STRING("_rettypeboxed"));
        (l_retVar, l_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_retType), l_varDecls);
        l_funArgsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_funArgsStr = lm_390(l_funArgsStr, i_funArgs);
        l_funArgsStr = Tpl.popIter(l_funArgsStr);
        (l_boxRetVar, l_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", l_varDecls);
        ret_10 = listLength(i_funArgs);
        ret_11 = SimCode.incrementInt(ret_10, 1);
        l_funArgCount = Tpl.writeStr(Tpl.emptyTxt, intString(ret_11));
        txt = Tpl.writeText(txt, l_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" boxptr_"));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_391(txt, i_funArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ")\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_varDecls);
        txt = Tpl.softNewLine(txt);
        ret_12 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_392(txt, ret_12, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_boxRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = mmc_mk_box"));
        txt = Tpl.writeText(txt, l_funArgCount);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(3, &"));
        txt = Tpl.writeText(txt, l_fname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc, "));
        txt = Tpl.writeText(txt, l_funArgsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.writeText(txt, l_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, l_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1 = "));
        txt = Tpl.writeText(txt, l_boxRetVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "\n"
                                }, true));
        ret_13 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_393(txt, ret_13, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("return "));
        txt = Tpl.writeText(txt, l_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end boxRecordConstructor;

public function funArgUnbox
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varBox;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varBox;
algorithm
  (out_txt, out_a_varDecls, out_a_varBox) :=
  matchcontinue(in_txt, in_a_var, in_a_varDecls, in_a_varBox)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_varBox;
      String i_name_1;
      DAE.ExpType i_ty;
      DAE.ComponentRef i_name;
      Tpl.Text l_varName;

    case ( txt,
           SimCode.VARIABLE(name = i_name, ty = i_ty),
           a_varDecls,
           a_varBox )
      equation
        l_varName = contextCref(Tpl.emptyTxt, i_name, SimCode.contextFunction);
        (txt, a_varBox, a_varDecls) = unboxVariable(txt, Tpl.textString(l_varName), i_ty, a_varBox, a_varDecls);
      then (txt, a_varDecls, a_varBox);

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_name_1),
           a_varDecls,
           a_varBox )
      equation
        txt = Tpl.writeStr(txt, i_name_1);
      then (txt, a_varDecls, a_varBox);

    case ( txt,
           _,
           a_varDecls,
           a_varBox )
      then (txt, a_varDecls, a_varBox);
  end matchcontinue;
end funArgUnbox;

protected function fun_396
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_varType;
  input String in_a_varName;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_varType, in_a_varName, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      String a_varName;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType i_varType;
      Tpl.Text txt_3;
      Tpl.Text l_tmpVar;
      Tpl.Text l_type;
      Tpl.Text l_shortType;

    case ( txt,
           DAE.ET_METATYPE(),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeStr(txt, a_varName);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_BOXED(ty = _),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeStr(txt, a_varName);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_varType as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _))),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = unboxRecord(txt, a_varName, i_varType, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           i_varType,
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        l_shortType = mmcExpTypeShort(Tpl.emptyTxt, i_varType);
        l_type = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("mmc__unbox__"));
        l_type = Tpl.writeText(l_type, l_shortType);
        l_type = Tpl.writeTok(l_type, Tpl.ST_STRING("_rettype"));
        txt_3 = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("mmc__unbox__"));
        txt_3 = Tpl.writeText(txt_3, l_shortType);
        txt_3 = Tpl.writeTok(txt_3, Tpl.ST_STRING("_rettype"));
        (l_tmpVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_3), a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tmpVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = mmc__unbox__"));
        a_preExp = Tpl.writeText(a_preExp, l_shortType);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeStr(a_preExp, a_varName);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmpVar);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_396;

public function unboxVariable
  input Tpl.Text txt;
  input String a_varName;
  input DAE.ExpType a_varType;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) := fun_396(txt, a_varType, a_varName, a_preExp, a_varDecls);
end unboxVariable;

protected function lm_398
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_a_tmpVar;
  input String in_a_recordVar;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_tmpVar, in_a_recordVar, in_a_varDecls)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> rest;
      Tpl.Text a_tmpVar;
      String a_recordVar;
      Tpl.Text a_varDecls;
      Integer x_offset;
      String i_compname;
      DAE.ExpType i_tp;
      Tpl.Text l_unboxStr;
      Tpl.Text l_unboxBuf;
      Tpl.Text l_untagTmp;
      Tpl.Text l_varType;

    case ( txt,
           {},
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           DAE.COMPLEX_VAR(name = i_compname, tp = i_tp) :: rest,
           a_tmpVar,
           a_recordVar,
           a_varDecls )
      equation
        x_offset = Tpl.getIteri_i0(txt);
        l_varType = mmcExpTypeShort(Tpl.emptyTxt, i_tp);
        (l_untagTmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        l_unboxBuf = Tpl.emptyTxt;
        (l_unboxStr, l_unboxBuf, a_varDecls) = unboxVariable(Tpl.emptyTxt, Tpl.textString(l_untagTmp), i_tp, l_unboxBuf, a_varDecls);
        txt = Tpl.writeText(txt, l_untagTmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        txt = Tpl.writeStr(txt, a_recordVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), "));
        txt = Tpl.writeStr(txt, intString(x_offset));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(")));\n"));
        txt = Tpl.writeText(txt, l_unboxBuf);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, a_tmpVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_compname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_unboxStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_398(txt, rest, a_tmpVar, a_recordVar, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_tmpVar,
           a_recordVar,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_398(txt, rest, a_tmpVar, a_recordVar, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_398;

protected function fun_399
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;
  input String in_a_recordVar;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ty, in_a_recordVar, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      String a_recordVar;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<DAE.ExpVar> i_vars;
      Absyn.Path i_path;
      Tpl.Text txt_1;
      Tpl.Text l_tmpVar;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_path), varLst = i_vars),
           a_recordVar,
           a_preExp,
           a_varDecls )
      equation
        txt_1 = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("struct "));
        txt_1 = underscorePath(txt_1, i_path);
        (l_tmpVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_1), a_varDecls);
        a_preExp = Tpl.pushIter(a_preExp, Tpl.ITER_OPTIONS(2, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (a_preExp, a_varDecls) = lm_398(a_preExp, i_vars, l_tmpVar, a_recordVar, a_varDecls);
        a_preExp = Tpl.popIter(a_preExp);
        txt = Tpl.writeText(txt, l_tmpVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_399;

public function unboxRecord
  input Tpl.Text txt;
  input String a_recordVar;
  input DAE.ExpType a_ty;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) := fun_399(txt, a_ty, a_recordVar, a_preExp, a_varDecls);
end unboxRecord;

protected function fun_401
  input Tpl.Text in_txt;
  input Tpl.Text in_a_constructorType;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varUnbox;
  input DAE.ExpType in_a_ty;
  input String in_a_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varUnbox;
algorithm
  (out_txt, out_a_varDecls, out_a_varUnbox) :=
  matchcontinue(in_txt, in_a_constructorType, in_a_varDecls, in_a_varUnbox, in_a_ty, in_a_varName)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_varUnbox;
      DAE.ExpType a_ty;
      String a_varName;
      Tpl.Text i_constructorType;
      Tpl.Text l_tmpVar;
      Tpl.Text l_constructor;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}),
           a_varDecls,
           a_varUnbox,
           _,
           a_varName )
      equation
        txt = Tpl.writeStr(txt, a_varName);
      then (txt, a_varDecls, a_varUnbox);

    case ( txt,
           i_constructorType,
           a_varDecls,
           a_varUnbox,
           a_ty,
           a_varName )
      equation
        (l_constructor, a_varUnbox, a_varDecls) = mmcConstructor(Tpl.emptyTxt, a_ty, a_varName, a_varUnbox, a_varDecls);
        (l_tmpVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(i_constructorType), a_varDecls);
        a_varUnbox = Tpl.writeText(a_varUnbox, l_tmpVar);
        a_varUnbox = Tpl.writeTok(a_varUnbox, Tpl.ST_STRING(" = "));
        a_varUnbox = Tpl.writeText(a_varUnbox, l_constructor);
        a_varUnbox = Tpl.writeTok(a_varUnbox, Tpl.ST_STRING(";"));
        a_varUnbox = Tpl.writeTok(a_varUnbox, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmpVar);
      then (txt, a_varDecls, a_varUnbox);
  end matchcontinue;
end fun_401;

public function funArgBox
  input Tpl.Text txt;
  input String a_varName;
  input DAE.ExpType a_ty;
  input Tpl.Text a_varUnbox;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varUnbox;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_constructorType;
algorithm
  l_constructorType := mmcConstructorType(Tpl.emptyTxt, a_ty);
  (out_txt, out_a_varDecls, out_a_varUnbox) := fun_401(txt, l_constructorType, a_varDecls, a_varUnbox, a_ty, a_varName);
end funArgBox;

public function mmcConstructorType
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_acon_rettype"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_metatype"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end mmcConstructorType;

protected function lm_404
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input String in_a_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_varName)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      String a_varName;
      DAE.ExpType i_tp;
      String i_name;
      Tpl.Text l_varname;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.COMPLEX_VAR(name = i_name, tp = i_tp) :: rest,
           a_varDecls,
           a_preExp,
           a_varName )
      equation
        l_varname = Tpl.writeStr(Tpl.emptyTxt, a_varName);
        l_varname = Tpl.writeTok(l_varname, Tpl.ST_STRING("."));
        l_varname = Tpl.writeStr(l_varname, i_name);
        (txt, a_preExp, a_varDecls) = funArgBox(txt, Tpl.textString(l_varname), i_tp, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_404(txt, rest, a_varDecls, a_preExp, a_varName);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_varName )
      equation
        (txt, a_varDecls, a_preExp) = lm_404(txt, rest, a_varDecls, a_preExp, a_varName);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_404;

public function mmcConstructor
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;
  input String in_a_varName;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_type, in_a_varName, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      String a_varName;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      Absyn.Path i_path;
      list<DAE.ExpVar> i_vars;
      Tpl.Text l_varsStr;
      Integer ret_2;
      Integer ret_1;
      Tpl.Text l_varCount;

    case ( txt,
           DAE.ET_INT(),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeStr(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_BOOL(),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeStr(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon("));
        txt = Tpl.writeStr(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_STRING(),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon("));
        txt = Tpl.writeStr(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_ENUMERATION(path = _),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeStr(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_ARRAY(ty = _),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_acon("));
        txt = Tpl.writeStr(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = i_path), varLst = i_vars),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        ret_1 = listLength(i_vars);
        ret_2 = SimCode.incrementInt(ret_1, 1);
        l_varCount = Tpl.writeStr(Tpl.emptyTxt, intString(ret_2));
        l_varsStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_varsStr, a_varDecls, a_preExp) = lm_404(l_varsStr, i_vars, a_varDecls, a_preExp, a_varName);
        l_varsStr = Tpl.popIter(l_varsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box"));
        txt = Tpl.writeText(txt, l_varCount);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(3, &"));
        txt = underscorePath(txt, i_path);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc, "));
        txt = Tpl.writeText(txt, l_varsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(name = _),
           a_varName,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box("));
        txt = Tpl.writeStr(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end mmcConstructor;

public function readInVar
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_name;
      DAE.ComponentRef i_cr;
      DAE.ExpType i_ty;
      Tpl.Text txt_0;

    case ( txt,
           SimCode.VARIABLE(name = i_cr, ty = (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)))) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (read_modelica_record(&inArgs, "));
        txt_0 = contextCref(Tpl.emptyTxt, i_cr, SimCode.contextFunction);
        txt = readInVarRecordMembers(txt, i_ty, Tpl.textString(txt_0));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) return 1;"));
      then txt;

    case ( txt,
           SimCode.VARIABLE(name = i_name, ty = (i_ty as DAE.ET_STRING())) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (read_"));
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&inArgs, (char**) &"));
        txt = contextCref(txt, i_name, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) return 1;"));
      then txt;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty, name = i_name) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (read_"));
        txt = expTypeArrayIf(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&inArgs, &"));
        txt = contextCref(txt, i_name, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) return 1;"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end readInVar;

protected function fun_407
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_tp;
  input String in_a_subvar_name;
  input String in_a_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_tp, in_a_subvar_name, in_a_prefix)
    local
      Tpl.Text txt;
      String a_subvar_name;
      String a_prefix;
      DAE.ExpType i_tp;
      Tpl.Text l_newPrefix;

    case ( txt,
           (i_tp as DAE.ET_COMPLEX(name = _)),
           a_subvar_name,
           a_prefix )
      equation
        l_newPrefix = Tpl.writeStr(Tpl.emptyTxt, a_prefix);
        l_newPrefix = Tpl.writeTok(l_newPrefix, Tpl.ST_STRING("."));
        l_newPrefix = Tpl.writeStr(l_newPrefix, a_subvar_name);
        txt = readInVarRecordMembers(txt, i_tp, Tpl.textString(l_newPrefix));
      then txt;

    case ( txt,
           _,
           a_subvar_name,
           a_prefix )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&("));
        txt = Tpl.writeStr(txt, a_prefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, a_subvar_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_407;

protected function lm_408
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input String in_a_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_prefix)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> rest;
      String a_prefix;
      String i_subvar_name;
      DAE.ExpType i_tp;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           DAE.COMPLEX_VAR(tp = i_tp, name = i_subvar_name) :: rest,
           a_prefix )
      equation
        txt = fun_407(txt, i_tp, i_subvar_name, a_prefix);
        txt = Tpl.nextIter(txt);
        txt = lm_408(txt, rest, a_prefix);
      then txt;

    case ( txt,
           _ :: rest,
           a_prefix )
      equation
        txt = lm_408(txt, rest, a_prefix);
      then txt;
  end matchcontinue;
end lm_408;

public function readInVarRecordMembers
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;
  input String in_a_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type, in_a_prefix)
    local
      Tpl.Text txt;
      String a_prefix;
      list<DAE.ExpVar> i_vl;

    case ( txt,
           DAE.ET_COMPLEX(varLst = i_vl),
           a_prefix )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_408(txt, i_vl, a_prefix);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end readInVarRecordMembers;

public function writeOutVar
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input Integer in_a_index;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var, in_a_index)
    local
      Tpl.Text txt;
      Integer a_index;
      SimCode.Variable i_var;
      DAE.ExpType i_ty;

    case ( txt,
           SimCode.VARIABLE(ty = (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)))),
           a_index )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_modelica_record(outVar, "));
        txt = writeOutVarRecordMembers(txt, i_ty, a_index, "");
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = _)),
           a_index )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("write_"));
        txt = varType(txt, i_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(outVar, &out.targ"));
        txt = Tpl.writeStr(txt, intString(a_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end writeOutVar;

protected function fun_411
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_tp;
  input Integer in_a_index;
  input String in_a_subvar_name;
  input String in_a_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_tp, in_a_index, in_a_subvar_name, in_a_prefix)
    local
      Tpl.Text txt;
      Integer a_index;
      String a_subvar_name;
      String a_prefix;
      DAE.ExpType i_tp;
      Tpl.Text l_newPrefix;

    case ( txt,
           (i_tp as DAE.ET_COMPLEX(name = _)),
           a_index,
           a_subvar_name,
           a_prefix )
      equation
        l_newPrefix = Tpl.writeStr(Tpl.emptyTxt, a_prefix);
        l_newPrefix = Tpl.writeTok(l_newPrefix, Tpl.ST_STRING("."));
        l_newPrefix = Tpl.writeStr(l_newPrefix, a_subvar_name);
        txt = expTypeRW(txt, i_tp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = writeOutVarRecordMembers(txt, i_tp, a_index, Tpl.textString(l_newPrefix));
      then txt;

    case ( txt,
           i_tp,
           a_index,
           a_subvar_name,
           a_prefix )
      equation
        txt = expTypeRW(txt, i_tp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &(out.targ"));
        txt = Tpl.writeStr(txt, intString(a_index));
        txt = Tpl.writeStr(txt, a_prefix);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, a_subvar_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_411;

protected function lm_412
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Integer in_a_index;
  input String in_a_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_index, in_a_prefix)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> rest;
      Integer a_index;
      String a_prefix;
      String i_subvar_name;
      DAE.ExpType i_tp;

    case ( txt,
           {},
           _,
           _ )
      then txt;

    case ( txt,
           DAE.COMPLEX_VAR(tp = i_tp, name = i_subvar_name) :: rest,
           a_index,
           a_prefix )
      equation
        txt = fun_411(txt, i_tp, a_index, i_subvar_name, a_prefix);
        txt = Tpl.nextIter(txt);
        txt = lm_412(txt, rest, a_index, a_prefix);
      then txt;

    case ( txt,
           _ :: rest,
           a_index,
           a_prefix )
      equation
        txt = lm_412(txt, rest, a_index, a_prefix);
      then txt;
  end matchcontinue;
end lm_412;

protected function fun_413
  input Tpl.Text in_txt;
  input Tpl.Text in_a_args;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_args)
    local
      Tpl.Text txt;
      Tpl.Text i_args;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}) )
      then txt;

    case ( txt,
           i_args )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, i_args);
      then txt;
  end matchcontinue;
end fun_413;

public function writeOutVarRecordMembers
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;
  input Integer in_a_index;
  input String in_a_prefix;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type, in_a_index, in_a_prefix)
    local
      Tpl.Text txt;
      Integer a_index;
      String a_prefix;
      list<DAE.ExpVar> i_vl;
      Absyn.Path i_n;
      Tpl.Text l_args;
      Tpl.Text l_basename;

    case ( txt,
           DAE.ET_COMPLEX(varLst = i_vl, name = i_n),
           a_index,
           a_prefix )
      equation
        l_basename = underscorePath(Tpl.emptyTxt, i_n);
        l_args = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_args = lm_412(l_args, i_vl, a_index, a_prefix);
        l_args = Tpl.popIter(l_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = Tpl.writeText(txt, l_basename);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc"));
        txt = fun_413(txt, l_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", TYPE_DESC_NONE"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end writeOutVarRecordMembers;

protected function fun_415
  input Tpl.Text in_txt;
  input String in_a_outStruct;
  input DAE.ComponentRef in_a_var_name;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outStruct, in_a_var_name, in_a_var)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_var_name;
      SimCode.Variable a_var;

    case ( txt,
           "",
           a_var_name,
           a_var )
      equation
        txt = varType(txt, a_var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = contextCref(txt, a_var_name, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_415;

protected function fun_416
  input Tpl.Text in_txt;
  input String in_a_outStruct;
  input Integer in_a_i;
  input DAE.ComponentRef in_a_var_name;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outStruct, in_a_i, in_a_var_name)
    local
      Tpl.Text txt;
      Integer a_i;
      DAE.ComponentRef a_var_name;
      String i_outStruct;

    case ( txt,
           "",
           _,
           a_var_name )
      equation
        txt = contextCref(txt, a_var_name, SimCode.contextFunction);
      then txt;

    case ( txt,
           i_outStruct,
           a_i,
           _ )
      equation
        txt = Tpl.writeStr(txt, i_outStruct);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(a_i));
      then txt;
  end matchcontinue;
end fun_416;

protected function lm_417
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_varInits)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_varInits )
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_varInits )
      equation
        (txt, a_varInits, a_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, a_varInits, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_varInits) = lm_417(txt, rest, a_varDecls, a_varInits);
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_varInits )
      equation
        (txt, a_varDecls, a_varInits) = lm_417(txt, rest, a_varDecls, a_varInits);
      then (txt, a_varDecls, a_varInits);
  end matchcontinue;
end lm_417;

protected function fun_418
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_a_var_value;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;
  input DAE.ComponentRef in_a_var_name;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits) :=
  matchcontinue(in_txt, in_a_var_value, in_a_varDecls, in_a_varInits, in_a_var_name)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      DAE.ComponentRef a_var_name;
      DAE.Exp i_exp;
      Tpl.Text l_defaultValue;

    case ( txt,
           SOME(i_exp),
           a_varDecls,
           a_varInits,
           a_var_name )
      equation
        l_defaultValue = contextCref(Tpl.emptyTxt, a_var_name, SimCode.contextFunction);
        l_defaultValue = Tpl.writeTok(l_defaultValue, Tpl.ST_STRING(" = "));
        (l_defaultValue, a_varInits, a_varDecls) = daeExp(l_defaultValue, i_exp, SimCode.contextFunction, a_varInits, a_varDecls);
        l_defaultValue = Tpl.writeTok(l_defaultValue, Tpl.ST_STRING(";"));
        l_defaultValue = Tpl.writeTok(l_defaultValue, Tpl.ST_NEW_LINE());
        a_varInits = Tpl.writeText(a_varInits, l_defaultValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           _,
           a_varDecls,
           a_varInits,
           _ )
      then (txt, a_varDecls, a_varInits);
  end matchcontinue;
end fun_418;

protected function fun_419
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_a_instDims;
  input Integer in_a_i;
  input String in_a_outStruct;
  input SimCode.Variable in_a_var;
  input Tpl.Text in_a_instDimsInit;
  input Tpl.Text in_a_varName;
  input DAE.ExpType in_a_var_ty;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;
  input DAE.ComponentRef in_a_var_name;
  input Option<DAE.Exp> in_a_var_value;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits) :=
  matchcontinue(in_txt, in_a_instDims, in_a_i, in_a_outStruct, in_a_var, in_a_instDimsInit, in_a_varName, in_a_var_ty, in_a_varDecls, in_a_varInits, in_a_var_name, in_a_var_value)
    local
      Tpl.Text txt;
      Integer a_i;
      String a_outStruct;
      SimCode.Variable a_var;
      Tpl.Text a_instDimsInit;
      Tpl.Text a_varName;
      DAE.ExpType a_var_ty;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      DAE.ComponentRef a_var_name;
      Option<DAE.Exp> a_var_value;
      list<DAE.Exp> i_instDims;
      Tpl.Text l_defaultValue;
      Integer ret_0;

    case ( txt,
           {},
           _,
           _,
           _,
           _,
           _,
           _,
           a_varDecls,
           a_varInits,
           a_var_name,
           a_var_value )
      equation
        (txt, a_varDecls, a_varInits) = fun_418(txt, a_var_value, a_varDecls, a_varInits, a_var_name);
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           i_instDims,
           a_i,
           a_outStruct,
           a_var,
           a_instDimsInit,
           a_varName,
           a_var_ty,
           a_varDecls,
           a_varInits,
           _,
           _ )
      equation
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING("alloc_"));
        a_varInits = expTypeShort(a_varInits, a_var_ty);
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING("_array(&"));
        a_varInits = Tpl.writeText(a_varInits, a_varName);
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING(", "));
        ret_0 = listLength(i_instDims);
        a_varInits = Tpl.writeStr(a_varInits, intString(ret_0));
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING(", "));
        a_varInits = Tpl.writeText(a_varInits, a_instDimsInit);
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING(");"));
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_NEW_LINE());
        (l_defaultValue, a_varDecls, a_varInits) = varDefaultValue(Tpl.emptyTxt, a_var, a_outStruct, a_i, Tpl.textString(a_varName), a_varDecls, a_varInits);
        a_varInits = Tpl.writeText(a_varInits, l_defaultValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
      then (txt, a_varDecls, a_varInits);
  end matchcontinue;
end fun_419;

public function varInit
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input String in_a_outStruct;
  input Integer in_a_i;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits) :=
  matchcontinue(in_txt, in_a_var, in_a_outStruct, in_a_i, in_a_varDecls, in_a_varInits)
    local
      Tpl.Text txt;
      String a_outStruct;
      Integer a_i;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      DAE.ExpType i_var_ty;
      Option<DAE.Exp> i_var_value;
      list<DAE.Exp> i_instDims;
      DAE.ComponentRef i_var_name;
      SimCode.Variable i_var;
      Tpl.Text l_ignore;
      Tpl.Text l_instDimsInit;
      Tpl.Text l_varName;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_var_name, instDims = i_instDims, value = i_var_value, ty = i_var_ty)),
           a_outStruct,
           a_i,
           a_varDecls,
           a_varInits )
      equation
        a_varDecls = fun_415(a_varDecls, a_outStruct, i_var_name, i_var);
        l_varName = fun_416(Tpl.emptyTxt, a_outStruct, a_i, i_var_name);
        l_instDimsInit = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_instDimsInit, a_varDecls, a_varInits) = lm_417(l_instDimsInit, i_instDims, a_varDecls, a_varInits);
        l_instDimsInit = Tpl.popIter(l_instDimsInit);
        (txt, a_varDecls, a_varInits) = fun_419(txt, i_instDims, a_i, a_outStruct, i_var, l_instDimsInit, l_varName, i_var_ty, a_varDecls, a_varInits, i_var_name, i_var_value);
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           (i_var as SimCode.FUNCTION_PTR(name = _)),
           _,
           _,
           a_varDecls,
           a_varInits )
      equation
        l_ignore = Tpl.emptyTxt;
        (a_varDecls, l_ignore) = functionArg(a_varDecls, i_var, l_ignore);
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           _,
           _,
           _,
           a_varDecls,
           a_varInits )
      equation
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING("#error Unknown local variable type"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls, a_varInits);
  end matchcontinue;
end varInit;

protected function fun_421
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_a_value;
  input String in_a_lhsVarName;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;
  input Integer in_a_i;
  input String in_a_outStruct;
  input DAE.ExpType in_a_var_ty;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits) :=
  matchcontinue(in_txt, in_a_value, in_a_lhsVarName, in_a_varDecls, in_a_varInits, in_a_i, in_a_outStruct, in_a_var_ty)
    local
      Tpl.Text txt;
      String a_lhsVarName;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      Integer a_i;
      String a_outStruct;
      DAE.ExpType a_var_ty;
      DAE.Exp i_arr;
      DAE.ComponentRef i_cr;
      Tpl.Text l_arrayExp;

    case ( txt,
           SOME(DAE.CREF(componentRef = i_cr)),
           _,
           a_varDecls,
           a_varInits,
           a_i,
           a_outStruct,
           a_var_ty )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, a_var_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data(&"));
        txt = contextCref(txt, i_cr, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, a_outStruct);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(".targ"));
        txt = Tpl.writeStr(txt, intString(a_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           SOME((i_arr as DAE.ARRAY(ty = _))),
           a_lhsVarName,
           a_varDecls,
           a_varInits,
           _,
           _,
           a_var_ty )
      equation
        (l_arrayExp, a_varInits, a_varDecls) = daeExp(Tpl.emptyTxt, i_arr, SimCode.contextFunction, a_varInits, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, a_var_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data(&"));
        txt = Tpl.writeText(txt, l_arrayExp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, a_lhsVarName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           _,
           _,
           a_varDecls,
           a_varInits,
           _,
           _,
           _ )
      then (txt, a_varDecls, a_varInits);
  end matchcontinue;
end fun_421;

public function varDefaultValue
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input String in_a_outStruct;
  input Integer in_a_i;
  input String in_a_lhsVarName;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits) :=
  matchcontinue(in_txt, in_a_var, in_a_outStruct, in_a_i, in_a_lhsVarName, in_a_varDecls, in_a_varInits)
    local
      Tpl.Text txt;
      String a_outStruct;
      Integer a_i;
      String a_lhsVarName;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      DAE.ExpType i_var_ty;
      Option<DAE.Exp> i_value;

    case ( txt,
           SimCode.VARIABLE(value = i_value, ty = i_var_ty),
           a_outStruct,
           a_i,
           a_lhsVarName,
           a_varDecls,
           a_varInits )
      equation
        (txt, a_varDecls, a_varInits) = fun_421(txt, i_value, a_lhsVarName, a_varDecls, a_varInits, a_i, a_outStruct, i_var_ty);
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           _,
           _,
           _,
           _,
           a_varDecls,
           a_varInits )
      then (txt, a_varDecls, a_varInits);
  end matchcontinue;
end varDefaultValue;

protected function lm_423
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      SimCode.Variable i_arg;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      equation
        txt = mmcVarType(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_423(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_423(txt, rest);
      then txt;
  end matchcontinue;
end lm_423;

protected function lm_424
  input Tpl.Text in_txt;
  input list<DAE.ExpType> in_items;
  input Tpl.Text in_a_rettype;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items, in_a_rettype)
    local
      Tpl.Text txt;
      list<DAE.ExpType> rest;
      Tpl.Text a_rettype;
      Integer x_i1;

    case ( txt,
           {},
           _ )
      then txt;

    case ( txt,
           _ :: rest,
           a_rettype )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#define "));
        txt = Tpl.writeText(txt, a_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.nextIter(txt);
        txt = lm_424(txt, rest, a_rettype);
      then txt;

    case ( txt,
           _ :: rest,
           a_rettype )
      equation
        txt = lm_424(txt, rest, a_rettype);
      then txt;
  end matchcontinue;
end lm_424;

protected function lm_425
  input Tpl.Text in_txt;
  input list<DAE.ExpType> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.ExpType> rest;
      Integer x_i1;
      DAE.ExpType i_ty;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_ty :: rest )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = mmcExpTypeShort(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" targ"));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        txt = lm_425(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_425(txt, rest);
      then txt;
  end matchcontinue;
end lm_425;

protected function fun_426
  input Tpl.Text in_txt;
  input list<DAE.ExpType> in_a_tys;
  input Tpl.Text in_a_rettype;
  input Tpl.Text in_a_typelist;
  input String in_a_name;
  input Tpl.Text in_a_varInit;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varInit;
algorithm
  (out_txt, out_a_varInit) :=
  matchcontinue(in_txt, in_a_tys, in_a_rettype, in_a_typelist, in_a_name, in_a_varInit)
    local
      Tpl.Text txt;
      Tpl.Text a_rettype;
      Tpl.Text a_typelist;
      String a_name;
      Tpl.Text a_varInit;
      list<DAE.ExpType> i_tys;

    case ( txt,
           {},
           _,
           a_typelist,
           a_name,
           a_varInit )
      equation
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING("_"));
        a_varInit = Tpl.writeStr(a_varInit, a_name);
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING(" = (void(*)("));
        a_varInit = Tpl.writeText(a_varInit, a_typelist);
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING(")) "));
        a_varInit = Tpl.writeStr(a_varInit, a_name);
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_NEW_LINE());
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("void(*_"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")("));
        txt = Tpl.writeText(txt, a_typelist);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varInit);

    case ( txt,
           i_tys,
           a_rettype,
           a_typelist,
           a_name,
           a_varInit )
      equation
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING("_"));
        a_varInit = Tpl.writeStr(a_varInit, a_name);
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING(" = ("));
        a_varInit = Tpl.writeText(a_varInit, a_rettype);
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING("(*)("));
        a_varInit = Tpl.writeText(a_varInit, a_typelist);
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING(")) "));
        a_varInit = Tpl.writeStr(a_varInit, a_name);
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_STRING(";"));
        a_varInit = Tpl.writeTok(a_varInit, Tpl.ST_NEW_LINE());
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_424(txt, i_tys, a_rettype);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("typedef struct "));
        txt = Tpl.writeText(txt, a_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "_s\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_425(txt, i_tys);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("} "));
        txt = Tpl.writeText(txt, a_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, a_rettype);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*_"));
        txt = Tpl.writeStr(txt, a_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")("));
        txt = Tpl.writeText(txt, a_typelist);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varInit);
  end matchcontinue;
end fun_426;

public function functionArg
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input Tpl.Text in_a_varInit;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varInit;
algorithm
  (out_txt, out_a_varInit) :=
  matchcontinue(in_txt, in_a_var, in_a_varInit)
    local
      Tpl.Text txt;
      Tpl.Text a_varInit;
      list<DAE.ExpType> i_tys;
      String i_name;
      list<SimCode.Variable> i_args;
      Tpl.Text l_rettype;
      Tpl.Text l_typelist;

    case ( txt,
           SimCode.FUNCTION_PTR(args = i_args, name = i_name, tys = i_tys),
           a_varInit )
      equation
        l_typelist = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_typelist = lm_423(l_typelist, i_args);
        l_typelist = Tpl.popIter(l_typelist);
        l_rettype = Tpl.writeStr(Tpl.emptyTxt, i_name);
        l_rettype = Tpl.writeTok(l_rettype, Tpl.ST_STRING("_rettype"));
        (txt, a_varInit) = fun_426(txt, i_tys, l_rettype, l_typelist, i_name, a_varInit);
      then (txt, a_varInit);

    case ( txt,
           _,
           a_varInit )
      then (txt, a_varInit);
  end matchcontinue;
end functionArg;

protected function fun_428
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Integer in_a_ix;
  input String in_a_dest;
  input Tpl.Text in_a_varAssign;
  input DAE.ComponentRef in_a_var_name;
  input Tpl.Text in_a_varCopy;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varAssign;
  output Tpl.Text out_a_varCopy;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varAssign, out_a_varCopy, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_ix, in_a_dest, in_a_varAssign, in_a_var_name, in_a_varCopy, in_a_varDecls)
    local
      Tpl.Text txt;
      Integer a_ix;
      String a_dest;
      Tpl.Text a_varAssign;
      DAE.ComponentRef a_var_name;
      Tpl.Text a_varCopy;
      Tpl.Text a_varDecls;
      Tpl.Text l_strVar;

    case ( txt,
           false,
           a_ix,
           a_dest,
           a_varAssign,
           a_var_name,
           a_varCopy,
           a_varDecls )
      equation
        (l_strVar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_string_t", a_varDecls);
        a_varCopy = Tpl.writeText(a_varCopy, l_strVar);
        a_varCopy = Tpl.writeTok(a_varCopy, Tpl.ST_STRING(" = strdup("));
        a_varCopy = contextCref(a_varCopy, a_var_name, SimCode.contextFunction);
        a_varCopy = Tpl.writeTok(a_varCopy, Tpl.ST_STRING(");"));
        a_varCopy = Tpl.writeTok(a_varCopy, Tpl.ST_NEW_LINE());
        a_varAssign = Tpl.writeStr(a_varAssign, a_dest);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(".targ"));
        a_varAssign = Tpl.writeStr(a_varAssign, intString(a_ix));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(" = init_modelica_string("));
        a_varAssign = Tpl.writeText(a_varAssign, l_strVar);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING_LIST({
                                                    ");\n",
                                                    "free("
                                                }, false));
        a_varAssign = Tpl.writeText(a_varAssign, l_strVar);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(");"));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_NEW_LINE());
      then (txt, a_varAssign, a_varCopy, a_varDecls);

    case ( txt,
           _,
           a_ix,
           a_dest,
           a_varAssign,
           a_var_name,
           a_varCopy,
           a_varDecls )
      equation
        a_varAssign = Tpl.writeStr(a_varAssign, a_dest);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(".targ"));
        a_varAssign = Tpl.writeStr(a_varAssign, intString(a_ix));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(" = "));
        a_varAssign = contextCref(a_varAssign, a_var_name, SimCode.contextFunction);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(";"));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_NEW_LINE());
      then (txt, a_varAssign, a_varCopy, a_varDecls);
  end matchcontinue;
end fun_428;

protected function lm_429
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_varInits)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_varInits )
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_varInits )
      equation
        (txt, a_varInits, a_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, a_varInits, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_varInits) = lm_429(txt, rest, a_varDecls, a_varInits);
      then (txt, a_varDecls, a_varInits);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_varInits )
      equation
        (txt, a_varDecls, a_varInits) = lm_429(txt, rest, a_varDecls, a_varInits);
      then (txt, a_varDecls, a_varInits);
  end matchcontinue;
end lm_429;

protected function fun_430
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_a_instDims;
  input Tpl.Text in_a_instDimsInit;
  input DAE.ExpType in_a_var_ty;
  input DAE.ComponentRef in_a_var_name;
  input Integer in_a_ix;
  input String in_a_dest;
  input Tpl.Text in_a_varAssign;
  input SimCode.Variable in_a_var;
  input Tpl.Text in_a_varInits;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varAssign;
  output Tpl.Text out_a_varInits;
algorithm
  (out_txt, out_a_varAssign, out_a_varInits) :=
  matchcontinue(in_txt, in_a_instDims, in_a_instDimsInit, in_a_var_ty, in_a_var_name, in_a_ix, in_a_dest, in_a_varAssign, in_a_var, in_a_varInits)
    local
      Tpl.Text txt;
      Tpl.Text a_instDimsInit;
      DAE.ExpType a_var_ty;
      DAE.ComponentRef a_var_name;
      Integer a_ix;
      String a_dest;
      Tpl.Text a_varAssign;
      SimCode.Variable a_var;
      Tpl.Text a_varInits;
      list<DAE.Exp> i_instDims;
      Integer ret_0;

    case ( txt,
           {},
           _,
           _,
           a_var_name,
           a_ix,
           a_dest,
           a_varAssign,
           a_var,
           a_varInits )
      equation
        a_varInits = initRecordMembers(a_varInits, a_var);
        a_varAssign = Tpl.writeStr(a_varAssign, a_dest);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(".targ"));
        a_varAssign = Tpl.writeStr(a_varAssign, intString(a_ix));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(" = "));
        a_varAssign = contextCref(a_varAssign, a_var_name, SimCode.contextFunction);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(";"));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_NEW_LINE());
      then (txt, a_varAssign, a_varInits);

    case ( txt,
           i_instDims,
           a_instDimsInit,
           a_var_ty,
           a_var_name,
           a_ix,
           a_dest,
           a_varAssign,
           _,
           a_varInits )
      equation
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING("alloc_"));
        a_varInits = expTypeShort(a_varInits, a_var_ty);
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING("_array(&"));
        a_varInits = Tpl.writeStr(a_varInits, a_dest);
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING(".targ"));
        a_varInits = Tpl.writeStr(a_varInits, intString(a_ix));
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING(", "));
        ret_0 = listLength(i_instDims);
        a_varInits = Tpl.writeStr(a_varInits, intString(ret_0));
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING(", "));
        a_varInits = Tpl.writeText(a_varInits, a_instDimsInit);
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_STRING(");"));
        a_varInits = Tpl.writeTok(a_varInits, Tpl.ST_NEW_LINE());
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING("copy_"));
        a_varAssign = expTypeShort(a_varAssign, a_var_ty);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING("_array_data(&"));
        a_varAssign = contextCref(a_varAssign, a_var_name, SimCode.contextFunction);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(", &"));
        a_varAssign = Tpl.writeStr(a_varAssign, a_dest);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(".targ"));
        a_varAssign = Tpl.writeStr(a_varAssign, intString(a_ix));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(");"));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_NEW_LINE());
      then (txt, a_varAssign, a_varInits);
  end matchcontinue;
end fun_430;

public function varOutput
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input String in_a_dest;
  input Integer in_a_ix;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_varInits;
  input Tpl.Text in_a_varCopy;
  input Tpl.Text in_a_varAssign;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varInits;
  output Tpl.Text out_a_varCopy;
  output Tpl.Text out_a_varAssign;
algorithm
  (out_txt, out_a_varDecls, out_a_varInits, out_a_varCopy, out_a_varAssign) :=
  matchcontinue(in_txt, in_a_var, in_a_dest, in_a_ix, in_a_varDecls, in_a_varInits, in_a_varCopy, in_a_varAssign)
    local
      Tpl.Text txt;
      String a_dest;
      Integer a_ix;
      Tpl.Text a_varDecls;
      Tpl.Text a_varInits;
      Tpl.Text a_varCopy;
      Tpl.Text a_varAssign;
      String i_var_name_1;
      DAE.ExpType i_var_ty;
      SimCode.Variable i_var;
      list<DAE.Exp> i_instDims;
      DAE.ComponentRef i_var_name;
      Tpl.Text l_instDimsInit;
      Boolean ret_0;

    case ( txt,
           SimCode.VARIABLE(ty = DAE.ET_STRING(), name = i_var_name),
           a_dest,
           a_ix,
           a_varDecls,
           a_varInits,
           a_varCopy,
           a_varAssign )
      equation
        ret_0 = RTOpts.acceptMetaModelicaGrammar();
        (txt, a_varAssign, a_varCopy, a_varDecls) = fun_428(txt, ret_0, a_ix, a_dest, a_varAssign, i_var_name, a_varCopy, a_varDecls);
      then (txt, a_varDecls, a_varInits, a_varCopy, a_varAssign);

    case ( txt,
           (i_var as SimCode.VARIABLE(instDims = i_instDims, name = i_var_name, ty = i_var_ty)),
           a_dest,
           a_ix,
           a_varDecls,
           a_varInits,
           a_varCopy,
           a_varAssign )
      equation
        l_instDimsInit = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_instDimsInit, a_varDecls, a_varInits) = lm_429(l_instDimsInit, i_instDims, a_varDecls, a_varInits);
        l_instDimsInit = Tpl.popIter(l_instDimsInit);
        (txt, a_varAssign, a_varInits) = fun_430(txt, i_instDims, l_instDimsInit, i_var_ty, i_var_name, a_ix, a_dest, a_varAssign, i_var, a_varInits);
      then (txt, a_varDecls, a_varInits, a_varCopy, a_varAssign);

    case ( txt,
           SimCode.FUNCTION_PTR(name = i_var_name_1),
           a_dest,
           a_ix,
           a_varDecls,
           a_varInits,
           a_varCopy,
           a_varAssign )
      equation
        a_varAssign = Tpl.writeStr(a_varAssign, a_dest);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(".targ"));
        a_varAssign = Tpl.writeStr(a_varAssign, intString(a_ix));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(" = (modelica_fnptr) _"));
        a_varAssign = Tpl.writeStr(a_varAssign, i_var_name_1);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(";"));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls, a_varInits, a_varCopy, a_varAssign);

    case ( txt,
           _,
           _,
           _,
           a_varDecls,
           a_varInits,
           a_varCopy,
           a_varAssign )
      then (txt, a_varDecls, a_varInits, a_varCopy, a_varAssign);
  end matchcontinue;
end varOutput;

protected function lm_432
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_a_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varName;
algorithm
  (out_txt, out_a_varName) :=
  matchcontinue(in_txt, in_items, in_a_varName)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> rest;
      Tpl.Text a_varName;
      DAE.ExpVar i_v;

    case ( txt,
           {},
           a_varName )
      then (txt, a_varName);

    case ( txt,
           i_v :: rest,
           a_varName )
      equation
        (txt, a_varName) = recordMemberInit(txt, i_v, a_varName);
        txt = Tpl.nextIter(txt);
        (txt, a_varName) = lm_432(txt, rest, a_varName);
      then (txt, a_varName);

    case ( txt,
           _ :: rest,
           a_varName )
      equation
        (txt, a_varName) = lm_432(txt, rest, a_varName);
      then (txt, a_varName);
  end matchcontinue;
end lm_432;

public function initRecordMembers
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> i_ty_varLst;
      DAE.ComponentRef i_name;
      Tpl.Text l_varName;

    case ( txt,
           SimCode.VARIABLE(ty = DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _), varLst = i_ty_varLst), name = i_name) )
      equation
        l_varName = contextCref(Tpl.emptyTxt, i_name, SimCode.contextFunction);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, l_varName) = lm_432(txt, i_ty_varLst, l_varName);
        txt = Tpl.popIter(txt);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end initRecordMembers;

protected function lm_434
  input Tpl.Text in_txt;
  input list<DAE.Dimension> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.Dimension> rest;
      DAE.Dimension i_dim;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      equation
        txt = dimension(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_434(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_434(txt, rest);
      then txt;
  end matchcontinue;
end lm_434;

protected function fun_435
  input Tpl.Text in_txt;
  input DAE.ExpVar in_a_v;
  input Tpl.Text in_a_varName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_v, in_a_varName)
    local
      Tpl.Text txt;
      Tpl.Text a_varName;
      String i_name;
      list<DAE.Dimension> i_tp_arrayDimensions;
      DAE.ExpType i_tp;
      Integer ret_2;
      Tpl.Text l_dims;
      Tpl.Text l_arrayType;

    case ( txt,
           DAE.COMPLEX_VAR(tp = (i_tp as DAE.ET_ARRAY(arrayDimensions = i_tp_arrayDimensions)), name = i_name),
           a_varName )
      equation
        l_arrayType = expType(Tpl.emptyTxt, i_tp, true);
        l_dims = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_dims = lm_434(l_dims, i_tp_arrayDimensions);
        l_dims = Tpl.popIter(l_dims);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("alloc_"));
        txt = Tpl.writeText(txt, l_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeText(txt, a_varName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = listLength(i_tp_arrayDimensions);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_dims);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_435;

public function recordMemberInit
  input Tpl.Text txt;
  input DAE.ExpVar a_v;
  input Tpl.Text a_varName;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varName;
algorithm
  out_txt := fun_435(txt, a_v, a_varName);
  out_a_varName := a_varName;
end recordMemberInit;

public function extVarName
  input Tpl.Text txt;
  input DAE.ComponentRef a_cr;

  output Tpl.Text out_txt;
algorithm
  out_txt := contextCref(txt, a_cr, SimCode.contextFunction);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("_ext"));
end extVarName;

protected function fun_438
  input Tpl.Text in_txt;
  input String in_a_language;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Function in_a_fun;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_language, in_a_varDecls, in_a_preExp, in_a_fun)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Function a_fun;

    case ( txt,
           "C",
           a_varDecls,
           a_preExp,
           a_fun )
      equation
        (txt, a_preExp, a_varDecls) = extFunCallC(txt, a_fun, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           "FORTRAN 77",
           a_varDecls,
           a_preExp,
           a_fun )
      equation
        (txt, a_preExp, a_varDecls) = extFunCallF77(txt, a_fun, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_438;

public function extFunCall
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fun;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_fun, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      SimCode.Function i_fun;
      String i_language;

    case ( txt,
           (i_fun as SimCode.EXTERNAL_FUNCTION(language = i_language)),
           a_preExp,
           a_varDecls )
      equation
        (txt, a_varDecls, a_preExp) = fun_438(txt, i_language, a_varDecls, a_preExp, i_fun);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end extFunCall;

protected function lm_440
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_arg :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = extArg(txt, i_arg, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_440(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_440(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_440;

protected function fun_441
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extReturn)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c) )
      equation
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_441;

protected function lm_442
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      Tpl.Text a_varDecls;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_arg :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = extFunCallVardecl(txt, i_arg, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_442(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_442(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_442;

protected function fun_443
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extReturn;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_extReturn, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      SimCode.SimExtArg i_extReturn;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)),
           a_varDecls )
      equation
        (txt, a_varDecls) = extFunCallVardecl(txt, i_extReturn, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_443;

protected function lm_444
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      equation
        txt = extFunCallVarcopy(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_444(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_444(txt, rest);
      then txt;
  end matchcontinue;
end lm_444;

protected function fun_445
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extReturn)
    local
      Tpl.Text txt;
      SimCode.SimExtArg i_extReturn;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)) )
      equation
        txt = extFunCallVarcopy(txt, i_extReturn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_445;

public function extFunCallC
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fun;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_fun, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      String i_extName;
      SimCode.SimExtArg i_extReturn;
      list<SimCode.SimExtArg> i_extArgs;
      Tpl.Text l_returnAssign;
      Tpl.Text l_args;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(extArgs = i_extArgs, extReturn = i_extReturn, extName = i_extName),
           a_preExp,
           a_varDecls )
      equation
        l_args = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_args, a_varDecls, a_preExp) = lm_440(l_args, i_extArgs, a_varDecls, a_preExp);
        l_args = Tpl.popIter(l_args);
        l_returnAssign = fun_441(Tpl.emptyTxt, i_extReturn);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_442(txt, i_extArgs, a_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        (txt, a_varDecls) = fun_443(txt, i_extReturn, a_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_returnAssign);
        txt = Tpl.writeStr(txt, i_extName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_args);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_444(txt, i_extArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_445(txt, i_extReturn);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end extFunCallC;

protected function lm_447
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_arg :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = extArgF77(txt, i_arg, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_447(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_447(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_447;

protected function fun_448
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extReturn)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c) )
      equation
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_448;

protected function lm_449
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      Tpl.Text a_varDecls;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_arg :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = extFunCallVardeclF77(txt, i_arg, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_449(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_449(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_449;

protected function fun_450
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extReturn;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_extReturn, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      SimCode.SimExtArg i_extReturn;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)),
           a_varDecls )
      equation
        (txt, a_varDecls) = extFunCallVardeclF77(txt, i_extReturn, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_450;

protected function lm_451
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Variable i_arg;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_arg :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = extFunCallBiVarF77(txt, i_arg, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_451(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_451(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_451;

protected function lm_452
  input Tpl.Text in_txt;
  input list<SimCode.SimExtArg> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<SimCode.SimExtArg> rest;
      SimCode.SimExtArg i_arg;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_arg :: rest )
      equation
        txt = extFunCallVarcopyF77(txt, i_arg);
        txt = Tpl.nextIter(txt);
        txt = lm_452(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_452(txt, rest);
      then txt;
  end matchcontinue;
end lm_452;

protected function fun_453
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extReturn;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_extReturn)
    local
      Tpl.Text txt;
      SimCode.SimExtArg i_extReturn;

    case ( txt,
           (i_extReturn as SimCode.SIMEXTARG(cref = _)) )
      equation
        txt = extFunCallVarcopyF77(txt, i_extReturn);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_453;

public function extFunCallF77
  input Tpl.Text in_txt;
  input SimCode.Function in_a_fun;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_fun, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      String i_extName;
      list<SimCode.Variable> i_biVars;
      SimCode.SimExtArg i_extReturn;
      list<SimCode.SimExtArg> i_extArgs;
      Tpl.Text l_returnAssign;
      Tpl.Text l_args;

    case ( txt,
           SimCode.EXTERNAL_FUNCTION(extArgs = i_extArgs, extReturn = i_extReturn, biVars = i_biVars, extName = i_extName),
           a_preExp,
           a_varDecls )
      equation
        l_args = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_args, a_varDecls, a_preExp) = lm_447(l_args, i_extArgs, a_varDecls, a_preExp);
        l_args = Tpl.popIter(l_args);
        l_returnAssign = fun_448(Tpl.emptyTxt, i_extReturn);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_449(txt, i_extArgs, a_varDecls);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        (txt, a_varDecls) = fun_450(txt, i_extReturn, a_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls, a_preExp) = lm_451(txt, i_biVars, a_varDecls, a_preExp);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_returnAssign);
        txt = Tpl.writeStr(txt, i_extName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_("));
        txt = Tpl.writeText(txt, l_args);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_452(txt, i_extArgs);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = fun_453(txt, i_extReturn);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end extFunCallF77;

protected function fun_455
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;
  input DAE.ComponentRef in_a_c;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ty, in_a_c, in_a_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_c;
      Tpl.Text a_varDecls;
      DAE.ExpType i_ty;

    case ( txt,
           DAE.ET_STRING(),
           _,
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_ty,
           a_c,
           a_varDecls )
      equation
        a_varDecls = extType(a_varDecls, i_ty);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = contextCref(a_varDecls, a_c, SimCode.contextFunction);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING("_ext;"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
        txt = contextCref(txt, a_c, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext = ("));
        txt = extType(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = contextCref(txt, a_c, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);
  end matchcontinue;
end fun_455;

protected function fun_456
  input Tpl.Text in_txt;
  input Integer in_a_oi;
  input DAE.ComponentRef in_a_c;
  input DAE.ExpType in_a_ty;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_oi, in_a_c, in_a_ty, in_a_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_c;
      DAE.ExpType a_ty;
      Tpl.Text a_varDecls;

    case ( txt,
           0,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_c,
           a_ty,
           a_varDecls )
      equation
        a_varDecls = extType(a_varDecls, a_ty);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = extVarName(a_varDecls, a_c);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls);
  end matchcontinue;
end fun_456;

public function extFunCallVardecl
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_arg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_arg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Integer i_oi;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;

    case ( txt,
           SimCode.SIMEXTARG(isInput = true, isArray = false, type_ = i_ty, cref = i_c),
           a_varDecls )
      equation
        (txt, a_varDecls) = fun_455(txt, i_ty, i_c, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = false, type_ = i_ty, cref = i_c),
           a_varDecls )
      equation
        (txt, a_varDecls) = fun_456(txt, i_oi, i_c, i_ty, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end extFunCallVardecl;

protected function fun_458
  input Tpl.Text in_txt;
  input Boolean in_a_ia;
  input Integer in_a_oi;
  input DAE.ComponentRef in_a_c;
  input DAE.ExpType in_a_ty;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ia, in_a_oi, in_a_c, in_a_ty, in_a_varDecls)
    local
      Tpl.Text txt;
      Integer a_oi;
      DAE.ComponentRef a_c;
      DAE.ExpType a_ty;
      Tpl.Text a_varDecls;

    case ( txt,
           false,
           _,
           a_c,
           a_ty,
           a_varDecls )
      equation
        a_varDecls = extType(a_varDecls, a_ty);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = extVarName(a_varDecls, a_c);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_oi,
           a_c,
           a_ty,
           a_varDecls )
      equation
        a_varDecls = expTypeArrayIf(a_varDecls, a_ty);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = extVarName(a_varDecls, a_c);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, a_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_to_f77(&out.targ"));
        txt = Tpl.writeStr(txt, intString(a_oi));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = extVarName(txt, a_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);
  end matchcontinue;
end fun_458;

protected function fun_459
  input Tpl.Text in_txt;
  input Integer in_a_oi;
  input DAE.ComponentRef in_a_c;
  input DAE.ExpType in_a_ty;
  input Tpl.Text in_a_varDecls;
  input Boolean in_a_ia;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_oi, in_a_c, in_a_ty, in_a_varDecls, in_a_ia)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_c;
      DAE.ExpType a_ty;
      Tpl.Text a_varDecls;
      Boolean a_ia;
      Integer i_oi;

    case ( txt,
           0,
           _,
           _,
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_oi,
           a_c,
           a_ty,
           a_varDecls,
           a_ia )
      equation
        (txt, a_varDecls) = fun_458(txt, a_ia, i_oi, a_c, a_ty, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end fun_459;

public function extFunCallVardeclF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_arg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_arg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Boolean i_ia;
      Integer i_oi;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;

    case ( txt,
           SimCode.SIMEXTARG(isInput = true, isArray = true, type_ = i_ty, cref = i_c),
           a_varDecls )
      equation
        a_varDecls = expTypeArrayIf(a_varDecls, i_ty);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = extVarName(a_varDecls, i_c);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_to_f77(&"));
        txt = contextCref(txt, i_c, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = i_ia, type_ = i_ty, cref = i_c),
           a_varDecls )
      equation
        (txt, a_varDecls) = fun_459(txt, i_oi, i_c, i_ty, a_varDecls, i_ia);
      then (txt, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(type_ = i_ty, cref = i_c),
           a_varDecls )
      equation
        a_varDecls = extType(a_varDecls, i_ty);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = extVarName(a_varDecls, i_c);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end extFunCallVardeclF77;

protected function fun_461
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_a_value;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_var__name;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_value, in_a_varDecls, in_a_preExp, in_a_var__name)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Tpl.Text a_var__name;
      DAE.Exp i_v;

    case ( txt,
           SOME(i_v),
           a_varDecls,
           a_preExp,
           a_var__name )
      equation
        txt = Tpl.writeText(txt, a_var__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_v, SimCode.contextFunction, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_461;

protected function lm_462
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_preExp )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_462(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp )
      equation
        (txt, a_varDecls, a_preExp) = lm_462(txt, rest, a_varDecls, a_preExp);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_462;

protected function fun_463
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_a_instDims;
  input DAE.ComponentRef in_a_name;
  input Tpl.Text in_a_instDimsInit;
  input Tpl.Text in_a_var__name;
  input Tpl.Text in_a_preExp;
  input DAE.ExpType in_a_var_ty;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_preExp) :=
  matchcontinue(in_txt, in_a_instDims, in_a_name, in_a_instDimsInit, in_a_var__name, in_a_preExp, in_a_var_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_name;
      Tpl.Text a_instDimsInit;
      Tpl.Text a_var__name;
      Tpl.Text a_preExp;
      DAE.ExpType a_var_ty;
      list<DAE.Exp> i_instDims;
      Integer ret_1;
      Tpl.Text l_type;

    case ( txt,
           {},
           _,
           _,
           _,
           a_preExp,
           _ )
      then (txt, a_preExp);

    case ( txt,
           i_instDims,
           a_name,
           a_instDimsInit,
           a_var__name,
           a_preExp,
           a_var_ty )
      equation
        l_type = expTypeArray(Tpl.emptyTxt, a_var_ty);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, a_var__name);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        ret_1 = listLength(i_instDims);
        a_preExp = Tpl.writeStr(a_preExp, intString(ret_1));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_instDimsInit);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("convert_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_to_f77(&"));
        a_preExp = Tpl.writeText(a_preExp, a_var__name);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = extVarName(a_preExp, a_name);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
      then (txt, a_preExp);
  end matchcontinue;
end fun_463;

public function extFunCallBiVarF77
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_var, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType i_var_ty;
      list<DAE.Exp> i_instDims;
      Option<DAE.Exp> i_value;
      SimCode.Variable i_var;
      DAE.ComponentRef i_name;
      Tpl.Text l_instDimsInit;
      Tpl.Text l_defaultValue;
      Tpl.Text l_var__name;

    case ( txt,
           (i_var as SimCode.VARIABLE(name = i_name, value = i_value, instDims = i_instDims, ty = i_var_ty)),
           a_preExp,
           a_varDecls )
      equation
        l_var__name = contextCref(Tpl.emptyTxt, i_name, SimCode.contextFunction);
        a_varDecls = varType(a_varDecls, i_var);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = Tpl.writeText(a_varDecls, l_var__name);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
        a_varDecls = varType(a_varDecls, i_var);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = extVarName(a_varDecls, i_name);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
        (l_defaultValue, a_varDecls, a_preExp) = fun_461(Tpl.emptyTxt, i_value, a_varDecls, a_preExp, l_var__name);
        a_preExp = Tpl.writeText(a_preExp, l_defaultValue);
        l_instDimsInit = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_instDimsInit, a_varDecls, a_preExp) = lm_462(l_instDimsInit, i_instDims, a_varDecls, a_preExp);
        l_instDimsInit = Tpl.popIter(l_instDimsInit);
        (txt, a_preExp) = fun_463(txt, i_instDims, i_name, l_instDimsInit, l_var__name, a_preExp, i_var_ty);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end extFunCallBiVarF77;

protected function fun_465
  input Tpl.Text in_txt;
  input Integer in_a_oi;
  input DAE.ComponentRef in_a_c;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_oi, in_a_c, in_a_ty)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_c;
      DAE.ExpType a_ty;
      Integer i_oi;

    case ( txt,
           0,
           _,
           _ )
      then txt;

    case ( txt,
           i_oi,
           a_c,
           a_ty )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = ("));
        txt = expTypeModelica(txt, a_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = contextCref(txt, a_c, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext;"));
      then txt;
  end matchcontinue;
end fun_465;

public function extFunCallVarcopy
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_arg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_arg)
    local
      Tpl.Text txt;
      DAE.ComponentRef i_c;
      DAE.ExpType i_ty;
      Integer i_oi;

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = false, type_ = i_ty, cref = i_c) )
      equation
        txt = fun_465(txt, i_oi, i_c, i_ty);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunCallVarcopy;

protected function fun_467
  input Tpl.Text in_txt;
  input Boolean in_a_ai;
  input Tpl.Text in_a_ext__name;
  input DAE.ExpType in_a_ty;
  input Tpl.Text in_a_outarg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ai, in_a_ext__name, in_a_ty, in_a_outarg)
    local
      Tpl.Text txt;
      Tpl.Text a_ext__name;
      DAE.ExpType a_ty;
      Tpl.Text a_outarg;

    case ( txt,
           false,
           a_ext__name,
           a_ty,
           a_outarg )
      equation
        txt = Tpl.writeText(txt, a_outarg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = ("));
        txt = expTypeModelica(txt, a_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
        txt = Tpl.writeText(txt, a_ext__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           true,
           a_ext__name,
           a_ty,
           a_outarg )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("convert_alloc_"));
        txt = expTypeArray(txt, a_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_from_f77(&"));
        txt = Tpl.writeText(txt, a_ext__name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_outarg);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_467;

protected function fun_468
  input Tpl.Text in_txt;
  input Integer in_a_oi;
  input DAE.ExpType in_a_ty;
  input Boolean in_a_ai;
  input DAE.ComponentRef in_a_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_oi, in_a_ty, in_a_ai, in_a_c)
    local
      Tpl.Text txt;
      DAE.ExpType a_ty;
      Boolean a_ai;
      DAE.ComponentRef a_c;
      Integer i_oi;
      Tpl.Text l_ext__name;
      Tpl.Text l_outarg;

    case ( txt,
           0,
           _,
           _,
           _ )
      then txt;

    case ( txt,
           i_oi,
           a_ty,
           a_ai,
           a_c )
      equation
        l_outarg = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("out.targ"));
        l_outarg = Tpl.writeStr(l_outarg, intString(i_oi));
        l_ext__name = contextCref(Tpl.emptyTxt, a_c, SimCode.contextFunction);
        l_ext__name = Tpl.writeTok(l_ext__name, Tpl.ST_STRING("_ext"));
        txt = fun_467(txt, a_ai, l_ext__name, a_ty, l_outarg);
      then txt;
  end matchcontinue;
end fun_468;

public function extFunCallVarcopyF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_arg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_arg)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;
      Boolean i_ai;
      DAE.ComponentRef i_c;
      Integer i_oi;

    case ( txt,
           SimCode.SIMEXTARG(outputIndex = i_oi, isArray = i_ai, type_ = i_ty, cref = i_c) )
      equation
        txt = fun_468(txt, i_oi, i_ty, i_ai, i_c);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end extFunCallVarcopyF77;

protected function fun_470
  input Tpl.Text in_txt;
  input Integer in_a_oi;
  input DAE.ComponentRef in_a_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_oi, in_a_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_c;
      Integer i_oi;

    case ( txt,
           0,
           a_c )
      equation
        txt = contextCref(txt, a_c, SimCode.contextFunction);
      then txt;

    case ( txt,
           i_oi,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_oi));
      then txt;
  end matchcontinue;
end fun_470;

protected function fun_471
  input Tpl.Text in_txt;
  input Integer in_a_oi;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_oi)
    local
      Tpl.Text txt;

    case ( txt,
           0 )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;
  end matchcontinue;
end fun_471;

protected function fun_472
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_t)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_STRING() )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_472;

protected function fun_473
  input Tpl.Text in_txt;
  input Integer in_a_oi;
  input DAE.ExpType in_a_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_oi, in_a_t)
    local
      Tpl.Text txt;
      DAE.ExpType a_t;

    case ( txt,
           0,
           a_t )
      equation
        txt = fun_472(txt, a_t);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_473;

protected function fun_474
  input Tpl.Text in_txt;
  input Integer in_a_outputIndex;
  input DAE.ComponentRef in_a_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_outputIndex, in_a_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_c;
      Integer i_outputIndex;

    case ( txt,
           0,
           a_c )
      equation
        txt = contextCref(txt, a_c, SimCode.contextFunction);
      then txt;

    case ( txt,
           i_outputIndex,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("out.targ"));
        txt = Tpl.writeStr(txt, intString(i_outputIndex));
      then txt;
  end matchcontinue;
end fun_474;

public function extArg
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extArg;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_extArg, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      Integer i_outputIndex;
      DAE.ExpType i_type__;
      DAE.Exp i_exp;
      DAE.ExpType i_t;
      DAE.ComponentRef i_c;
      Integer i_oi;
      Tpl.Text l_dim;
      Tpl.Text l_typeStr;
      Tpl.Text l_suffix;
      Tpl.Text l_prefix;
      Tpl.Text l_shortTypeStr;
      Tpl.Text l_name;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, outputIndex = i_oi, isArray = true, type_ = i_t),
           a_preExp,
           a_varDecls )
      equation
        l_name = fun_470(Tpl.emptyTxt, i_oi, i_c);
        l_shortTypeStr = expTypeShort(Tpl.emptyTxt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("data_of_"));
        txt = Tpl.writeText(txt, l_shortTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&("));
        txt = Tpl.writeText(txt, l_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isInput = _, outputIndex = i_oi, type_ = i_t),
           a_preExp,
           a_varDecls )
      equation
        l_prefix = fun_471(Tpl.emptyTxt, i_oi);
        l_suffix = fun_473(Tpl.emptyTxt, i_oi, i_t);
        txt = Tpl.writeText(txt, l_prefix);
        txt = contextCref(txt, i_c, SimCode.contextFunction);
        txt = Tpl.writeText(txt, l_suffix);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARGEXP(exp = i_exp),
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, SimCode.contextFunction, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, type_ = i_type__, outputIndex = i_outputIndex, exp = i_exp),
           a_preExp,
           a_varDecls )
      equation
        l_typeStr = expTypeShort(Tpl.emptyTxt, i_type__);
        l_name = fun_474(Tpl.emptyTxt, i_outputIndex, i_c);
        (l_dim, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, SimCode.contextFunction, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size_of_dimension_"));
        txt = Tpl.writeText(txt, l_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array("));
        txt = Tpl.writeText(txt, l_name);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_dim);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end extArg;

protected function fun_476
  input Tpl.Text in_txt;
  input Integer in_a_oi;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_oi)
    local
      Tpl.Text txt;

    case ( txt,
           0 )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_476;

protected function fun_477
  input Tpl.Text in_txt;
  input Integer in_a_oi;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_oi)
    local
      Tpl.Text txt;

    case ( txt,
           0 )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ext"));
      then txt;
  end matchcontinue;
end fun_477;

public function extArgF77
  input Tpl.Text in_txt;
  input SimCode.SimExtArg in_a_extArg;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_extArg, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType i_type__;
      DAE.Exp i_exp;
      Integer i_oi;
      DAE.ComponentRef i_c;
      DAE.ExpType i_t;
      Tpl.Text l_size__call;
      Tpl.Text l_dim;
      Tpl.Text l_sizeVar;
      Tpl.Text l_sizeVarName;
      Tpl.Text txt_3;
      Tpl.Text l_tvar;
      Tpl.Text l_texp;
      Tpl.Text l_suffix;

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, isArray = true, type_ = i_t),
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("data_of_"));
        txt = expTypeShort(txt, i_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&("));
        txt = extVarName(txt, i_c);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, outputIndex = i_oi, type_ = DAE.ET_INT()),
           a_preExp,
           a_varDecls )
      equation
        l_suffix = fun_476(Tpl.emptyTxt, i_oi);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(int*) &"));
        txt = contextCref(txt, i_c, SimCode.contextFunction);
        txt = Tpl.writeText(txt, l_suffix);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARG(cref = i_c, outputIndex = i_oi, type_ = _),
           a_preExp,
           a_varDecls )
      equation
        l_suffix = fun_477(Tpl.emptyTxt, i_oi);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = contextCref(txt, i_c, SimCode.contextFunction);
        txt = Tpl.writeText(txt, l_suffix);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARGEXP(exp = i_exp),
           a_preExp,
           a_varDecls )
      equation
        (l_texp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, SimCode.contextFunction, a_preExp, a_varDecls);
        txt_3 = expTypeFromExpFlag(Tpl.emptyTxt, i_exp, 8);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_3), a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_texp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(";"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           SimCode.SIMEXTARGSIZE(cref = i_c, exp = i_exp, type_ = i_type__),
           a_preExp,
           a_varDecls )
      equation
        l_sizeVarName = tempSizeVarName(Tpl.emptyTxt, i_c, i_exp);
        (l_sizeVar, a_varDecls) = tempDecl(Tpl.emptyTxt, "int", a_varDecls);
        (l_dim, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, SimCode.contextFunction, a_preExp, a_varDecls);
        l_size__call = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("size_of_dimension_"));
        l_size__call = expTypeShort(l_size__call, i_type__);
        l_size__call = Tpl.writeTok(l_size__call, Tpl.ST_STRING("_array"));
        a_preExp = Tpl.writeText(a_preExp, l_sizeVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_size__call);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = contextCref(a_preExp, i_c, SimCode.contextFunction);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_dim);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
        txt = Tpl.writeText(txt, l_sizeVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end extArgF77;

protected function fun_479
  input Tpl.Text in_txt;
  input DAE.Exp in_a_indices;
  input DAE.ComponentRef in_a_c;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_indices, in_a_c)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_c;
      Integer i_integer;

    case ( txt,
           DAE.ICONST(integer = i_integer),
           a_c )
      equation
        txt = contextCref(txt, a_c, SimCode.contextFunction);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_size_"));
        txt = Tpl.writeStr(txt, intString(i_integer));
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("tempSizeVarName:UNHANDLED_EXPRESSION"));
      then txt;
  end matchcontinue;
end fun_479;

public function tempSizeVarName
  input Tpl.Text txt;
  input DAE.ComponentRef a_c;
  input DAE.Exp a_indices;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_479(txt, a_indices, a_c);
end tempSizeVarName;

protected function lm_481
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, SimCode.contextFunction, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_481(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_481(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_481;

public function funStatement
  input Tpl.Text in_txt;
  input SimCode.Statement in_a_stmt;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      list<DAE.Statement> i_statementLst;

    case ( txt,
           SimCode.ALGORITHM(statementLst = i_statementLst),
           a_varDecls )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_481(txt, i_statementLst, a_varDecls);
        txt = Tpl.popIter(txt);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("NOT IMPLEMENTED FUN STATEMENT"));
      then (txt, a_varDecls);
  end matchcontinue;
end funStatement;

public function algStatement
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Statement i_s;

    case ( txt,
           (i_s as DAE.STMT_ASSIGN(type_ = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtAssign(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_ASSIGN_ARR(type_ = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtAssignArr(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_TUPLE_ASSIGN(type_ = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtTupleAssign(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_ASSIGN_PATTERN(lhs = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtAssignPattern(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_IF(exp = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtIf(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_FOR(type_ = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtFor(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_WHILE(exp = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtWhile(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_ASSERT(cond = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtAssert(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_TERMINATE(msg = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtTerminate(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_WHEN(exp = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtWhen(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_BREAK(source = _),
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_FAILURE(body = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtFailure(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_TRY(tryBody = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtTry(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_CATCH(catchBody = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtCatch(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_THROW(source = _),
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MMC_THROW();"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_RETURN(source = _),
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("goto _return;"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_NORETCALL(exp = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtNoretcall(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#error NOT_IMPLEMENTED_ALG_STATEMENT"));
      then (txt, a_varDecls);
  end matchcontinue;
end algStatement;

protected function fun_484
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input DAE.Exp in_a_val;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_val, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      DAE.Exp a_val;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Exp i_idx;
      DAE.Exp i_arr;
      Tpl.Text l_val1;
      Tpl.Text l_idx1;
      Tpl.Text l_arr1;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.ASUB(exp = i_arr, sub = {i_idx}),
           a_val,
           a_varDecls,
           a_context )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_arr1, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_arr, a_context, l_preExp, a_varDecls);
        (l_idx1, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_idx, a_context, l_preExp, a_varDecls);
        (l_val1, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_val, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("arrayUpdate("));
        txt = Tpl.writeText(txt, l_arr1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_idx1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_val1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls,
           _ )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_484;

protected function fun_485
  input Tpl.Text in_txt;
  input String in_mArg;
  input DAE.Exp in_a_exp1;
  input DAE.Exp in_a_val;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;
  input DAE.Exp in_a_exp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_exp1, in_a_val, in_a_varDecls, in_a_context, in_a_exp)
    local
      Tpl.Text txt;
      DAE.Exp a_exp1;
      DAE.Exp a_val;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Exp a_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_varPart;
      Tpl.Text l_preExp;

    case ( txt,
           "metatype",
           _,
           a_val,
           a_varDecls,
           a_context,
           a_exp )
      equation
        (txt, a_varDecls) = fun_484(txt, a_exp, a_val, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_exp1,
           a_val,
           a_varDecls,
           a_context,
           _ )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_varPart, l_preExp, a_varDecls) = daeExpAsub(Tpl.emptyTxt, a_exp1, a_context, l_preExp, a_varDecls);
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_val, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_varPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);
  end matchcontinue;
end fun_485;

public function algStmtAssign
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Exp i_val;
      DAE.Exp i_exp;
      DAE.Exp i_exp1;
      DAE.Exp i_e;
      Tpl.Text l_expPart2;
      Tpl.Text l_expPart1;
      String str_4;
      Tpl.Text txt_3;
      Tpl.Text l_varPart;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = DAE.WILD()), exp = i_e),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = (i_exp1 as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_VAR())), exp = i_exp),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_varPart, l_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_exp1, a_context, l_preExp, a_varDecls);
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_varPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = (modelica_fnptr) "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = (i_exp1 as DAE.CREF(ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = _))), exp = i_exp),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_varPart, l_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_exp1, a_context, l_preExp, a_varDecls);
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_varPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = (modelica_fnptr) "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = (i_exp1 as DAE.CREF(componentRef = _)), exp = i_exp),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_varPart, l_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_exp1, a_context, l_preExp, a_varDecls);
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_varPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = (i_exp1 as DAE.ASUB(exp = _)), exp = (i_exp as i_val)),
           a_context,
           a_varDecls )
      equation
        txt_3 = expTypeFromExpShort(Tpl.emptyTxt, i_exp);
        str_4 = Tpl.textString(txt_3);
        (txt, a_varDecls) = fun_485(txt, str_4, i_exp1, i_val, a_varDecls, a_context, i_exp);
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_ASSIGN(exp1 = i_exp1, exp = i_exp),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart1, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp1, a_context, l_preExp, a_varDecls);
        (l_expPart2, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_expPart1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_expPart2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtAssign;

protected function fun_487
  input Tpl.Text in_txt;
  input Tpl.Text in_a_ispec;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;
  input Tpl.Text in_a_expPart;
  input DAE.ExpType in_a_t;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ispec, in_a_varDecls, in_a_context, in_a_cr, in_a_expPart, in_a_t, in_a_preExp)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.ComponentRef a_cr;
      Tpl.Text a_expPart;
      DAE.ExpType a_t;
      Tpl.Text a_preExp;
      Tpl.Text i_ispec;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}),
           a_varDecls,
           a_context,
           a_cr,
           a_expPart,
           a_t,
           a_preExp )
      equation
        txt = Tpl.writeText(txt, a_preExp);
        txt = Tpl.softNewLine(txt);
        txt = copyArrayData(txt, a_t, Tpl.textString(a_expPart), a_cr, a_context);
      then (txt, a_varDecls);

    case ( txt,
           i_ispec,
           a_varDecls,
           a_context,
           a_cr,
           a_expPart,
           a_t,
           a_preExp )
      equation
        txt = Tpl.writeText(txt, a_preExp);
        txt = Tpl.softNewLine(txt);
        (txt, a_varDecls) = indexedAssign(txt, a_t, Tpl.textString(a_expPart), a_cr, Tpl.textString(i_ispec), a_context, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end fun_487;

public function algStmtAssignArr
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.ExpType i_t;
      DAE.ComponentRef i_cr;
      DAE.Exp i_e;
      Tpl.Text l_ispec;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_ASSIGN_ARR(exp = i_e, componentRef = i_cr, type_ = i_t),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, l_preExp, a_varDecls);
        (l_ispec, l_preExp, a_varDecls) = indexSpecFromCref(Tpl.emptyTxt, i_cr, a_context, l_preExp, a_varDecls);
        (txt, a_varDecls) = fun_487(txt, l_ispec, a_varDecls, a_context, i_cr, l_expPart, i_t, l_preExp);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtAssignArr;

protected function fun_489
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;
  input String in_a_ispec;
  input Tpl.Text in_a_cref;
  input String in_a_exp;
  input Tpl.Text in_a_type;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_context, in_a_varDecls, in_a_ispec, in_a_cref, in_a_exp, in_a_type)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      String a_ispec;
      Tpl.Text a_cref;
      String a_exp;
      Tpl.Text a_type;
      Tpl.Text l_tmp;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           a_varDecls,
           a_ispec,
           a_cref,
           a_exp,
           a_type )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("indexed_assign_"));
        txt = Tpl.writeText(txt, a_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeStr(txt, a_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, a_ispec);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls,
           a_ispec,
           a_cref,
           a_exp,
           a_type )
      equation
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "real_array", a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("indexed_assign_"));
        txt = Tpl.writeText(txt, a_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(&"));
        txt = Tpl.writeStr(txt, a_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeStr(txt, a_ispec);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ");\n",
                                    "copy_"
                                }, false));
        txt = Tpl.writeText(txt, a_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_data_mem(&"));
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);
  end matchcontinue;
end fun_489;

public function indexedAssign
  input Tpl.Text txt;
  input DAE.ExpType a_ty;
  input String a_exp;
  input DAE.ComponentRef a_cr;
  input String a_ispec;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_cref;
  Tpl.Text l_type;
algorithm
  l_type := expTypeArray(Tpl.emptyTxt, a_ty);
  l_cref := contextArrayCref(Tpl.emptyTxt, a_cr, a_context);
  (out_txt, out_a_varDecls) := fun_489(txt, a_context, a_varDecls, a_ispec, l_cref, a_exp, l_type);
end indexedAssign;

protected function fun_491
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_cref;
  input String in_a_exp;
  input Tpl.Text in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_cref, in_a_exp, in_a_type)
    local
      Tpl.Text txt;
      Tpl.Text a_cref;
      String a_exp;
      Tpl.Text a_type;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           a_cref,
           a_exp,
           a_type )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = Tpl.writeText(txt, a_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_data(&"));
        txt = Tpl.writeStr(txt, a_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           a_cref,
           a_exp,
           a_type )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = Tpl.writeText(txt, a_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_data_mem(&"));
        txt = Tpl.writeStr(txt, a_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_cref);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_491;

public function copyArrayData
  input Tpl.Text txt;
  input DAE.ExpType a_ty;
  input String a_exp;
  input DAE.ComponentRef a_cr;
  input SimCode.Context a_context;

  output Tpl.Text out_txt;
protected
  Tpl.Text l_cref;
  Tpl.Text l_type;
algorithm
  l_type := expTypeArray(Tpl.emptyTxt, a_ty);
  l_cref := contextArrayCref(Tpl.emptyTxt, a_cr, a_context);
  out_txt := fun_491(txt, a_context, l_cref, a_exp, l_type);
end copyArrayData;

protected function lm_493
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_retStruct;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context, in_a_retStruct)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      Tpl.Text a_retStruct;
      Integer x_i1;
      DAE.Exp i_cr;
      Tpl.Text l_rhsStr;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_cr :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_retStruct )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        l_rhsStr = Tpl.writeText(Tpl.emptyTxt, a_retStruct);
        l_rhsStr = Tpl.writeTok(l_rhsStr, Tpl.ST_STRING(".targ"));
        l_rhsStr = Tpl.writeStr(l_rhsStr, intString(x_i1));
        (txt, a_preExp, a_varDecls) = writeLhsCref(txt, i_cr, Tpl.textString(l_rhsStr), a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_493(txt, rest, a_varDecls, a_preExp, a_context, a_retStruct);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_retStruct )
      equation
        (txt, a_varDecls, a_preExp) = lm_493(txt, rest, a_varDecls, a_preExp, a_context, a_retStruct);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_493;

protected function lm_494
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_prefix;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_prefix)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_prefix;
      Integer x_i1;
      DAE.Exp i_cr;
      Tpl.Text l_rhsStr;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_cr :: rest,
           a_varDecls,
           a_prefix )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        l_rhsStr = Tpl.writeText(Tpl.emptyTxt, a_prefix);
        l_rhsStr = Tpl.writeTok(l_rhsStr, Tpl.ST_STRING("_targ"));
        l_rhsStr = Tpl.writeStr(l_rhsStr, intString(x_i1));
        a_varDecls = expTypeFromExpModelica(a_varDecls, i_cr);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(" "));
        a_varDecls = Tpl.writeText(a_varDecls, l_rhsStr);
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_STRING(";"));
        a_varDecls = Tpl.writeTok(a_varDecls, Tpl.ST_NEW_LINE());
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_494(txt, rest, a_varDecls, a_prefix);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_prefix )
      equation
        (txt, a_varDecls) = lm_494(txt, rest, a_varDecls, a_prefix);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_494;

protected function lm_495
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_prefix;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context, in_a_prefix)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      Tpl.Text a_prefix;
      Integer x_i1;
      DAE.Exp i_cr;
      Tpl.Text l_rhsStr;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_cr :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_prefix )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        l_rhsStr = Tpl.writeText(Tpl.emptyTxt, a_prefix);
        l_rhsStr = Tpl.writeTok(l_rhsStr, Tpl.ST_STRING("_targ"));
        l_rhsStr = Tpl.writeStr(l_rhsStr, intString(x_i1));
        (txt, a_preExp, a_varDecls) = writeLhsCref(txt, i_cr, Tpl.textString(l_rhsStr), a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_495(txt, rest, a_varDecls, a_preExp, a_context, a_prefix);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_prefix )
      equation
        (txt, a_varDecls, a_preExp) = lm_495(txt, rest, a_varDecls, a_preExp, a_context, a_prefix);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_495;

public function algStmtTupleAssign
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<DAE.Exp> i_expExpLst;
      DAE.Exp i_exp;
      Tpl.Text l_0__;
      Integer ret_3;
      Tpl.Text l_prefix;
      Tpl.Text l_retStruct;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_TUPLE_ASSIGN(exp = (i_exp as DAE.CALL(path = _)), expExpLst = i_expExpLst),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_retStruct, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls, l_preExp) = lm_493(txt, i_expExpLst, a_varDecls, l_preExp, a_context, l_retStruct);
        txt = Tpl.popIter(txt);
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_TUPLE_ASSIGN(exp = (i_exp as DAE.MATCHEXPRESSION(matchType = _)), expExpLst = i_expExpLst),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        l_prefix = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("tmp"));
        ret_3 = System.tmpTick();
        l_prefix = Tpl.writeStr(l_prefix, intString(ret_3));
        (l_0__, l_prefix, l_preExp, a_varDecls) = daeExpMatch2(Tpl.emptyTxt, i_exp, l_prefix, a_context, l_preExp, a_varDecls);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, SOME(Tpl.ST_STRING("")), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_494(txt, i_expExpLst, a_varDecls, l_prefix);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls, l_preExp) = lm_495(txt, i_expExpLst, a_varDecls, l_preExp, a_context, l_prefix);
        txt = Tpl.popIter(txt);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("#error \"algStmtTupleAssign failed\""));
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtTupleAssign;

protected function fun_497
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_lhsStr;
  input String in_a_rhsStr;
  input DAE.ExpType in_a_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_lhsStr, in_a_rhsStr, in_a_t)
    local
      Tpl.Text txt;
      Tpl.Text a_lhsStr;
      String a_rhsStr;
      DAE.ExpType a_t;

    case ( txt,
           SimCode.SIMULATION(genDiscrete = _),
           a_lhsStr,
           a_rhsStr,
           a_t )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("copy_"));
        txt = expTypeShort(txt, a_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data_mem(&"));
        txt = Tpl.writeStr(txt, a_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           a_lhsStr,
           a_rhsStr,
           _ )
      equation
        txt = Tpl.writeText(txt, a_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, a_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;
  end matchcontinue;
end fun_497;

protected function fun_498
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_lhsStr;
  input String in_a_rhsStr;
  input DAE.ExpType in_a_t;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_context, in_a_lhsStr, in_a_rhsStr, in_a_t)
    local
      Tpl.Text txt;
      Tpl.Text a_lhsStr;
      String a_rhsStr;
      DAE.ExpType a_t;

    case ( txt,
           SimCode.SIMULATION(genDiscrete = _),
           a_lhsStr,
           a_rhsStr,
           a_t )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("usub_"));
        txt = expTypeShort(txt, a_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array(&"));
        txt = Tpl.writeStr(txt, a_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "\n",
                                    "copy_"
                                }, false));
        txt = expTypeShort(txt, a_t);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array_data_mem(&"));
        txt = Tpl.writeStr(txt, a_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           a_lhsStr,
           a_rhsStr,
           _ )
      equation
        txt = Tpl.writeText(txt, a_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = -"));
        txt = Tpl.writeStr(txt, a_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then txt;
  end matchcontinue;
end fun_498;

public function writeLhsCref
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input String in_a_rhsStr;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_rhsStr, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      String a_rhsStr;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_e;
      DAE.ExpType i_t;
      DAE.Exp i_exp;
      Tpl.Text l_lhsStr;

    case ( txt,
           (i_exp as DAE.CREF(ty = (i_t as DAE.ET_ARRAY(ty = _)))),
           a_rhsStr,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_lhsStr, a_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        txt = fun_497(txt, a_context, l_lhsStr, a_rhsStr, i_t);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.UNARY(exp = (i_e as DAE.CREF(ty = (i_t as DAE.ET_ARRAY(ty = _))))),
           a_rhsStr,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_lhsStr, a_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        txt = fun_498(txt, a_context, l_lhsStr, a_rhsStr, i_t);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_exp as DAE.CREF(componentRef = _)),
           a_rhsStr,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_lhsStr, a_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeStr(txt, a_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.UNARY(exp = (i_e as DAE.CREF(componentRef = _))),
           a_rhsStr,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_lhsStr, a_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_lhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = -"));
        txt = Tpl.writeStr(txt, a_rhsStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end writeLhsCref;

protected function lm_500
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_500(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_500(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_500;

public function algStmtIf
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Else i_else__;
      list<DAE.Statement> i_statementLst;
      DAE.Exp i_exp;
      Tpl.Text l_condExp;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_IF(exp = i_exp, statementLst = i_statementLst, else_ = i_else__),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_condExp, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, l_condExp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_500(txt, i_statementLst, a_varDecls, a_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        (txt, a_varDecls) = elseExpr(txt, i_else__, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtIf;

public function algStmtFor
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Statement i_s;

    case ( txt,
           (i_s as DAE.STMT_FOR(range = DAE.RANGE(ty = _))),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtForRange(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           (i_s as DAE.STMT_FOR(type_ = _)),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStmtForGeneric(txt, i_s, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtFor;

protected function lm_503
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_503(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_503(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_503;

public function algStmtForRange
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Ident i_iter;
      DAE.Exp i_rng;
      list<DAE.Statement> i_statementLst;
      Boolean i_iterIsArray;
      DAE.ExpType i_type__;
      Tpl.Text l_stmtStr;
      Tpl.Text l_identTypeShort;
      Tpl.Text l_identType;

    case ( txt,
           DAE.STMT_FOR(range = (i_rng as DAE.RANGE(ty = _)), type_ = i_type__, iterIsArray = i_iterIsArray, statementLst = i_statementLst, iter = i_iter),
           a_context,
           a_varDecls )
      equation
        l_identType = expType(Tpl.emptyTxt, i_type__, i_iterIsArray);
        l_identTypeShort = expTypeShort(Tpl.emptyTxt, i_type__);
        l_stmtStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_stmtStr, a_varDecls) = lm_503(l_stmtStr, i_statementLst, a_varDecls, a_context);
        l_stmtStr = Tpl.popIter(l_stmtStr);
        (txt, l_stmtStr, a_varDecls) = algStmtForRange_impl(txt, i_rng, i_iter, Tpl.textString(l_identType), Tpl.textString(l_identTypeShort), l_stmtStr, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtForRange;

protected function fun_505
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;

    case ( txt,
           false,
           a_varDecls )
      equation
        (txt, a_varDecls) = tempDecl(txt, "state", a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_505;

protected function fun_506
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_a_expOption;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_expOption, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_eo;

    case ( txt,
           SOME(i_eo),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_eo, a_context, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1)"));
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_506;

protected function fun_507
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_memory_state();"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_507;

protected function fun_508
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_508;

protected function fun_509
  input Tpl.Text in_txt;
  input DAE.Exp in_a_range;
  input Absyn.Ident in_a_iterator;
  input String in_a_type;
  input String in_a_shortType;
  input Tpl.Text in_a_body;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_range, in_a_iterator, in_a_type, in_a_shortType, in_a_body, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      Absyn.Ident a_iterator;
      String a_type;
      String a_shortType;
      Tpl.Text a_body;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Exp i_range;
      Option<DAE.Exp> i_expOption;
      DAE.Exp i_exp;
      Boolean ret_11;
      Boolean ret_10;
      Tpl.Text l_stopValue;
      Tpl.Text l_stepValue;
      Tpl.Text l_startValue;
      Tpl.Text l_preExp;
      Tpl.Text l_stopVar;
      Tpl.Text l_stepVar;
      Tpl.Text l_startVar;
      Boolean ret_2;
      Tpl.Text l_stateVar;
      Tpl.Text l_iterName;

    case ( txt,
           DAE.RANGE(exp = i_exp, expOption = i_expOption, range = i_range),
           a_iterator,
           a_type,
           a_shortType,
           a_body,
           a_context,
           a_varDecls )
      equation
        l_iterName = contextIteratorName(Tpl.emptyTxt, a_iterator, a_context);
        ret_2 = RTOpts.acceptMetaModelicaGrammar();
        (l_stateVar, a_varDecls) = fun_505(Tpl.emptyTxt, ret_2, a_varDecls);
        (l_startVar, a_varDecls) = tempDecl(Tpl.emptyTxt, a_type, a_varDecls);
        (l_stepVar, a_varDecls) = tempDecl(Tpl.emptyTxt, a_type, a_varDecls);
        (l_stopVar, a_varDecls) = tempDecl(Tpl.emptyTxt, a_type, a_varDecls);
        l_preExp = Tpl.emptyTxt;
        (l_startValue, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        (l_stepValue, a_varDecls, l_preExp) = fun_506(Tpl.emptyTxt, i_expOption, a_varDecls, l_preExp, a_context);
        (l_stopValue, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_range, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_startVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_startValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, l_stepVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_stepValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; "));
        txt = Tpl.writeText(txt, l_stopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_stopValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    ";\n",
                                    "{\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("for("));
        txt = Tpl.writeStr(txt, a_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" "));
        txt = Tpl.writeText(txt, l_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_startValue);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("; in_range_"));
        txt = Tpl.writeStr(txt, a_shortType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_startVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_stopVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("); "));
        txt = Tpl.writeText(txt, l_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" += "));
        txt = Tpl.writeText(txt, l_stepVar);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        ret_10 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_507(txt, ret_10, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, a_body);
        txt = Tpl.softNewLine(txt);
        ret_11 = RTOpts.acceptMetaModelicaGrammar();
        txt = fun_508(txt, ret_11, l_stateVar);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_509;

public function algStmtForRange_impl
  input Tpl.Text txt;
  input DAE.Exp a_range;
  input Absyn.Ident a_iterator;
  input String a_type;
  input String a_shortType;
  input Tpl.Text a_body;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_body;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) := fun_509(txt, a_range, a_iterator, a_type, a_shortType, a_body, a_context, a_varDecls);
  out_a_body := a_body;
end algStmtForRange_impl;

protected function lm_511
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_511(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_511(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_511;

public function algStmtForGeneric
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Ident i_iter;
      DAE.Exp i_range;
      list<DAE.Statement> i_statementLst;
      Boolean i_iterIsArray;
      DAE.ExpType i_type__;
      Tpl.Text l_stmtStr;
      Tpl.Text l_arrayType;
      Tpl.Text l_iterType;

    case ( txt,
           DAE.STMT_FOR(type_ = i_type__, iterIsArray = i_iterIsArray, statementLst = i_statementLst, range = i_range, iter = i_iter),
           a_context,
           a_varDecls )
      equation
        l_iterType = expType(Tpl.emptyTxt, i_type__, i_iterIsArray);
        l_arrayType = expTypeArray(Tpl.emptyTxt, i_type__);
        l_stmtStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_stmtStr, a_varDecls) = lm_511(l_stmtStr, i_statementLst, a_varDecls, a_context);
        l_stmtStr = Tpl.popIter(l_stmtStr);
        (txt, l_stmtStr, a_varDecls) = algStmtForGeneric_impl(txt, i_range, i_iter, Tpl.textString(l_iterType), Tpl.textString(l_arrayType), i_iterIsArray, l_stmtStr, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtForGeneric;

protected function fun_513
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;

    case ( txt,
           false,
           a_varDecls )
      equation
        (txt, a_varDecls) = tempDecl(txt, "state", a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_513;

protected function fun_514
  input Tpl.Text in_txt;
  input Boolean in_a_iterIsArray;
  input Tpl.Text in_a_ivar;
  input String in_a_type;
  input Tpl.Text in_a_tvar;
  input Tpl.Text in_a_evar;
  input String in_a_arrayType;
  input Tpl.Text in_a_iterName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_iterIsArray, in_a_ivar, in_a_type, in_a_tvar, in_a_evar, in_a_arrayType, in_a_iterName)
    local
      Tpl.Text txt;
      Tpl.Text a_ivar;
      String a_type;
      Tpl.Text a_tvar;
      Tpl.Text a_evar;
      String a_arrayType;
      Tpl.Text a_iterName;

    case ( txt,
           false,
           _,
           _,
           a_tvar,
           a_evar,
           a_arrayType,
           a_iterName )
      equation
        txt = Tpl.writeText(txt, a_iterName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = *("));
        txt = Tpl.writeStr(txt, a_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_element_addr1(&"));
        txt = Tpl.writeText(txt, a_evar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", 1, "));
        txt = Tpl.writeText(txt, a_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("));"));
      then txt;

    case ( txt,
           _,
           a_ivar,
           a_type,
           a_tvar,
           a_evar,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("simple_index_alloc_"));
        txt = Tpl.writeStr(txt, a_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1(&"));
        txt = Tpl.writeText(txt, a_evar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_ivar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;
  end matchcontinue;
end fun_514;

protected function fun_515
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = get_memory_state();"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_515;

protected function fun_516
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_stateVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_stateVar)
    local
      Tpl.Text txt;
      Tpl.Text a_stateVar;

    case ( txt,
           false,
           a_stateVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("restore_memory_state("));
        txt = Tpl.writeText(txt, a_stateVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_516;

public function algStmtForGeneric_impl
  input Tpl.Text txt;
  input DAE.Exp a_exp;
  input Absyn.Ident a_iterator;
  input String a_type;
  input String a_arrayType;
  input Boolean a_iterIsArray;
  input Tpl.Text a_body;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_body;
  output Tpl.Text out_a_varDecls;
protected
  Boolean ret_9;
  Boolean ret_8;
  Tpl.Text l_stmtStuff;
  Tpl.Text l_evar;
  Tpl.Text l_preExp;
  Tpl.Text l_ivar;
  Tpl.Text l_tvar;
  Boolean ret_2;
  Tpl.Text l_stateVar;
  Tpl.Text l_iterName;
algorithm
  l_iterName := contextIteratorName(Tpl.emptyTxt, a_iterator, a_context);
  ret_2 := RTOpts.acceptMetaModelicaGrammar();
  (l_stateVar, out_a_varDecls) := fun_513(Tpl.emptyTxt, ret_2, a_varDecls);
  (l_tvar, out_a_varDecls) := tempDecl(Tpl.emptyTxt, "int", out_a_varDecls);
  (l_ivar, out_a_varDecls) := tempDecl(Tpl.emptyTxt, a_type, out_a_varDecls);
  l_preExp := Tpl.emptyTxt;
  (l_evar, l_preExp, out_a_varDecls) := daeExp(Tpl.emptyTxt, a_exp, a_context, l_preExp, out_a_varDecls);
  l_stmtStuff := fun_514(Tpl.emptyTxt, a_iterIsArray, l_ivar, a_type, l_tvar, l_evar, a_arrayType, l_iterName);
  out_txt := Tpl.writeText(txt, l_preExp);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("{\n"));
  out_txt := Tpl.writeStr(out_txt, a_type);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" "));
  out_txt := Tpl.writeText(out_txt, l_iterName);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING_LIST({
                                       ";\n",
                                       "\n"
                                   }, true));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("for("));
  out_txt := Tpl.writeText(out_txt, l_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" = 1; "));
  out_txt := Tpl.writeText(out_txt, l_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(" <= size_of_dimension_"));
  out_txt := Tpl.writeStr(out_txt, a_arrayType);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("("));
  out_txt := Tpl.writeText(out_txt, l_evar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING(", 1); ++"));
  out_txt := Tpl.writeText(out_txt, l_tvar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(") {\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  ret_8 := RTOpts.acceptMetaModelicaGrammar();
  out_txt := fun_515(out_txt, ret_8, l_stateVar);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, l_stmtStuff);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeText(out_txt, a_body);
  out_txt := Tpl.softNewLine(out_txt);
  ret_9 := RTOpts.acceptMetaModelicaGrammar();
  out_txt := fun_516(out_txt, ret_9, l_stateVar);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE("}\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
  out_a_body := a_body;
end algStmtForGeneric_impl;

protected function lm_518
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_518(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_518(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_518;

public function algStmtWhile
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<DAE.Statement> i_statementLst;
      DAE.Exp i_exp;
      Tpl.Text l_var;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_WHILE(exp = i_exp, statementLst = i_statementLst),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_var, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("while (1) {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (!"));
        txt = Tpl.writeText(txt, l_var);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") break;\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_518(txt, i_statementLst, a_varDecls, a_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtWhile;

public function algStmtAssert
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Exp i_msg;
      DAE.Exp i_cond;

    case ( txt,
           DAE.STMT_ASSERT(cond = i_cond, msg = i_msg),
           a_context,
           a_varDecls )
      equation
        (txt, a_varDecls) = assertCommon(txt, i_cond, i_msg, a_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtAssert;

public function algStmtTerminate
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Exp i_msg;
      Tpl.Text l_msgVar;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_TERMINATE(msg = i_msg),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_msgVar, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_msg, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MODELICA_TERMINATE("));
        txt = Tpl.writeText(txt, l_msgVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtTerminate;

protected function lm_522
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varAssign;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varAssign;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varAssign, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varAssign, in_a_preExp, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varAssign;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Exp i_exp;
      Tpl.Text l_lhs;
      Tpl.Text txt_1;
      Tpl.Text l_decl;

    case ( txt,
           {},
           a_varAssign,
           a_preExp,
           _,
           a_varDecls )
      then (txt, a_varAssign, a_preExp, a_varDecls);

    case ( txt,
           i_exp :: rest,
           a_varAssign,
           a_preExp,
           a_context,
           a_varDecls )
      equation
        txt_1 = expTypeFromExpModelica(Tpl.emptyTxt, i_exp);
        (l_decl, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_1), a_varDecls);
        (l_lhs, a_preExp, a_varDecls) = scalarLhsCref(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        a_varAssign = Tpl.writeText(a_varAssign, l_decl);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(" = "));
        a_varAssign = Tpl.writeText(a_varAssign, l_lhs);
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_STRING(";"));
        a_varAssign = Tpl.writeTok(a_varAssign, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_lhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, l_decl);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.nextIter(txt);
        (txt, a_varAssign, a_preExp, a_varDecls) = lm_522(txt, rest, a_varAssign, a_preExp, a_context, a_varDecls);
      then (txt, a_varAssign, a_preExp, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varAssign,
           a_preExp,
           a_context,
           a_varDecls )
      equation
        (txt, a_varAssign, a_preExp, a_varDecls) = lm_522(txt, rest, a_varAssign, a_preExp, a_context, a_varDecls);
      then (txt, a_varAssign, a_preExp, a_varDecls);
  end matchcontinue;
end lm_522;

public function algStmtMatchcasesVarDeclsAndAssign
  input Tpl.Text txt;
  input list<DAE.Exp> a_expList;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;
  input Tpl.Text a_varAssign;
  input Tpl.Text a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_varAssign;
  output Tpl.Text out_a_preExp;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_varAssign, out_a_preExp, out_a_varDecls) := lm_522(out_txt, a_expList, a_varAssign, a_preExp, a_context, a_varDecls);
  out_txt := Tpl.popIter(out_txt);
end algStmtMatchcasesVarDeclsAndAssign;

protected function lm_524
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_524(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_524(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_524;

public function algStmtFailure
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<DAE.Statement> i_body;
      Tpl.Text l_stmtBody;
      Tpl.Text l_tmp;

    case ( txt,
           DAE.STMT_FAILURE(body = i_body),
           a_context,
           a_varDecls )
      equation
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_boolean", a_varDecls);
        l_stmtBody = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_stmtBody, a_varDecls) = lm_524(l_stmtBody, i_body, a_varDecls, a_context);
        l_stmtBody = Tpl.popIter(l_stmtBody);
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = 0; /* begin failure */\n",
                                    "MMC_TRY()\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_stmtBody);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(" = 1;\n"));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "MMC_CATCH()\n",
                                    "if ("
                                }, false));
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") MMC_THROW(); /* end failure */"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtFailure;

protected function lm_526
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_526(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_526(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_526;

public function algStmtTry
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<DAE.Statement> i_tryBody;
      Tpl.Text l_body;

    case ( txt,
           DAE.STMT_TRY(tryBody = i_tryBody),
           a_context,
           a_varDecls )
      equation
        l_body = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_body, a_varDecls) = lm_526(l_body, i_tryBody, a_varDecls, a_context);
        l_body = Tpl.popIter(l_body);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#error \"Using STMT_TRY: This is deprecated, and should be matched with catch anyway.\"\n",
                                    "try {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtTry;

protected function lm_528
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_528(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_528(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_528;

public function algStmtCatch
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<DAE.Statement> i_catchBody;
      Tpl.Text l_body;

    case ( txt,
           DAE.STMT_CATCH(catchBody = i_catchBody),
           a_context,
           a_varDecls )
      equation
        l_body = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_body, a_varDecls) = lm_528(l_body, i_catchBody, a_varDecls, a_context);
        l_body = Tpl.popIter(l_body);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    "#error \"Using STMT_CATCH: This is deprecated, and should be matched with catch anyway.\"\n",
                                    "catch (int i) {\n"
                                }, true));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_body);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtCatch;

public function algStmtNoretcall
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Exp i_exp;
      Tpl.Text l_expPart;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_NORETCALL(exp = i_exp),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtNoretcall;

protected function lm_531
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_531(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_531(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_531;

protected function lm_532
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<Integer> rest;
      Integer i_idx;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_idx :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_idx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        txt = lm_532(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_532(txt, rest);
      then txt;
  end matchcontinue;
end lm_532;

protected function fun_533
  input Tpl.Text in_txt;
  input DAE.Statement in_a_when;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_when, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      list<Integer> i_helpVarIndices;
      Option<DAE.Statement> i_elseWhen;
      list<DAE.Statement> i_statementLst;
      DAE.Statement i_when;
      Tpl.Text l_else;
      Tpl.Text l_statements;
      Tpl.Text l_preIf;

    case ( txt,
           (i_when as DAE.STMT_WHEN(statementLst = i_statementLst, elseWhen = i_elseWhen, helpVarIndices = i_helpVarIndices)),
           a_context,
           a_varDecls )
      equation
        (l_preIf, a_varDecls) = algStatementWhenPre(Tpl.emptyTxt, i_when, a_varDecls);
        l_statements = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_statements, a_varDecls) = lm_531(l_statements, i_statementLst, a_varDecls, a_context);
        l_statements = Tpl.popIter(l_statements);
        (l_else, a_varDecls) = algStatementWhenElse(Tpl.emptyTxt, i_elseWhen, a_varDecls);
        txt = Tpl.writeText(txt, l_preIf);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        txt = lm_532(txt, i_helpVarIndices);
        txt = Tpl.popIter(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_statements);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, l_else);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_533;

protected function fun_534
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input DAE.Statement in_a_when;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_context, in_a_when, in_a_varDecls)
    local
      Tpl.Text txt;
      DAE.Statement a_when;
      Tpl.Text a_varDecls;
      SimCode.Context i_context;

    case ( txt,
           (i_context as SimCode.SIMULATION(genDiscrete = true)),
           a_when,
           a_varDecls )
      equation
        (txt, a_varDecls) = fun_533(txt, a_when, i_context, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_534;

public function algStmtWhen
  input Tpl.Text txt;
  input DAE.Statement a_when;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) := fun_534(txt, a_context, a_when, a_varDecls);
end algStmtWhen;

protected function fun_536
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_a_elseWhen;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_elseWhen, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.Statement i_ew;

    case ( txt,
           SOME(i_ew),
           a_varDecls )
      equation
        (txt, a_varDecls) = algStatementWhenPre(txt, i_ew, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_536;

protected function fun_537
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_a_when_elseWhen;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_when_elseWhen, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.Statement i_ew;

    case ( txt,
           SOME(i_ew),
           a_varDecls )
      equation
        (txt, a_varDecls) = algStatementWhenPre(txt, i_ew, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_537;

protected function fun_538
  input Tpl.Text in_txt;
  input list<Integer> in_a_helpVarIndices;
  input DAE.Exp in_a_when_exp;
  input Tpl.Text in_a_varDecls;
  input Option<DAE.Statement> in_a_when_elseWhen;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_helpVarIndices, in_a_when_exp, in_a_varDecls, in_a_when_elseWhen)
    local
      Tpl.Text txt;
      DAE.Exp a_when_exp;
      Tpl.Text a_varDecls;
      Option<DAE.Statement> a_when_elseWhen;
      Integer i_i;
      Tpl.Text l_res;
      Tpl.Text l_preExp;
      Tpl.Text l_restPre;

    case ( txt,
           {i_i},
           a_when_exp,
           a_varDecls,
           a_when_elseWhen )
      equation
        (l_restPre, a_varDecls) = fun_537(Tpl.emptyTxt, a_when_elseWhen, a_varDecls);
        l_preExp = Tpl.emptyTxt;
        (l_res, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_when_exp, SimCode.contextSimulationDiscrete, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_i));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, l_res);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, l_restPre);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls,
           _ )
      then (txt, a_varDecls);
  end matchcontinue;
end fun_538;

public function algStatementWhenPre
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.Exp i_when_exp;
      Option<DAE.Statement> i_when_elseWhen;
      list<Integer> i_helpVarIndices;
      list<DAE.Exp> i_el;
      Option<DAE.Statement> i_elseWhen;
      Tpl.Text l_assignments;
      Tpl.Text l_preExp;
      Tpl.Text l_restPre;

    case ( txt,
           DAE.STMT_WHEN(exp = DAE.ARRAY(array = i_el), elseWhen = i_elseWhen, helpVarIndices = i_helpVarIndices),
           a_varDecls )
      equation
        (l_restPre, a_varDecls) = fun_536(Tpl.emptyTxt, i_elseWhen, a_varDecls);
        l_preExp = Tpl.emptyTxt;
        (l_assignments, l_preExp, a_varDecls) = algStatementWhenPreAssigns(Tpl.emptyTxt, i_el, i_helpVarIndices, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_assignments);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_restPre);
      then (txt, a_varDecls);

    case ( txt,
           DAE.STMT_WHEN(helpVarIndices = i_helpVarIndices, elseWhen = i_when_elseWhen, exp = i_when_exp),
           a_varDecls )
      equation
        (txt, a_varDecls) = fun_538(txt, i_helpVarIndices, i_when_exp, a_varDecls, i_when_elseWhen);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStatementWhenPre;

protected function lm_540
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, SimCode.contextSimulationDiscrete, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_540(txt, rest, a_varDecls);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls )
      equation
        (txt, a_varDecls) = lm_540(txt, rest, a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_540;

protected function lm_541
  input Tpl.Text in_txt;
  input list<Integer> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<Integer> rest;
      Integer i_idx;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_idx :: rest )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("edge(localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_idx));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
        txt = Tpl.nextIter(txt);
        txt = lm_541(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_541(txt, rest);
      then txt;
  end matchcontinue;
end lm_541;

public function algStatementWhenElse
  input Tpl.Text in_txt;
  input Option<DAE.Statement> in_a_stmt;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      list<Integer> i_when_helpVarIndices;
      Option<DAE.Statement> i_when_elseWhen;
      list<DAE.Statement> i_when_statementLst;
      Tpl.Text l_elseCondStr;
      Tpl.Text l_else;
      Tpl.Text l_statements;

    case ( txt,
           SOME(DAE.STMT_WHEN(statementLst = i_when_statementLst, elseWhen = i_when_elseWhen, helpVarIndices = i_when_helpVarIndices)),
           a_varDecls )
      equation
        l_statements = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_statements, a_varDecls) = lm_540(l_statements, i_when_statementLst, a_varDecls);
        l_statements = Tpl.popIter(l_statements);
        (l_else, a_varDecls) = algStatementWhenElse(Tpl.emptyTxt, i_when_elseWhen, a_varDecls);
        l_elseCondStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(" || ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_elseCondStr = lm_541(l_elseCondStr, i_when_helpVarIndices);
        l_elseCondStr = Tpl.popIter(l_elseCondStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("else if ("));
        txt = Tpl.writeText(txt, l_elseCondStr);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_statements);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        txt = Tpl.writeText(txt, l_else);
      then (txt, a_varDecls);

    case ( txt,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStatementWhenElse;

protected function fun_543
  input Tpl.Text in_txt;
  input list<Integer> in_a_ints;
  input DAE.Exp in_a_firstExp;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input list<DAE.Exp> in_a_restExps;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_ints, in_a_firstExp, in_a_varDecls, in_a_preExp, in_a_restExps)
    local
      Tpl.Text txt;
      DAE.Exp a_firstExp;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      list<DAE.Exp> a_restExps;
      Integer i_firstInt;
      list<Integer> i_restInts;
      Tpl.Text l_firstExpPart;
      Tpl.Text l_rest;

    case ( txt,
           i_firstInt :: i_restInts,
           a_firstExp,
           a_varDecls,
           a_preExp,
           a_restExps )
      equation
        (l_rest, a_preExp, a_varDecls) = algStatementWhenPreAssigns(Tpl.emptyTxt, a_restExps, i_restInts, a_preExp, a_varDecls);
        (l_firstExpPart, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_firstExp, SimCode.contextSimulationDiscrete, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("localData->helpVars["));
        txt = Tpl.writeStr(txt, intString(i_firstInt));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("] = "));
        txt = Tpl.writeText(txt, l_firstExpPart);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, l_rest);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           _,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_543;

public function algStatementWhenPreAssigns
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_a_exps;
  input list<Integer> in_a_ints;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exps, in_a_ints, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      list<Integer> a_ints;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_firstExp;
      list<DAE.Exp> i_restExps;

    case ( txt,
           {},
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           i_firstExp :: i_restExps,
           a_ints,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_varDecls, a_preExp) = fun_543(txt, a_ints, i_firstExp, a_varDecls, a_preExp, i_restExps);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end algStatementWhenPreAssigns;

public function indexSpecFromCref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_cr, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<DAE.Subscript> i_subs;

    case ( txt,
           DAE.CREF_IDENT(subscriptLst = (i_subs as _ :: _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCrefRhsIndexSpec(txt, i_subs, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end indexSpecFromCref;

protected function lm_546
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_546(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_546(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_546;

protected function lm_547
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDecls;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDecls;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDecls,
           _ )
      then (txt, a_varDecls);

    case ( txt,
           i_stmt :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = algStatement(txt, i_stmt, a_context, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls) = lm_547(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_context )
      equation
        (txt, a_varDecls) = lm_547(txt, rest, a_varDecls, a_context);
      then (txt, a_varDecls);
  end matchcontinue;
end lm_547;

public function elseExpr
  input Tpl.Text in_txt;
  input DAE.Else in_a_else__;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_else__, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Else i_else__;
      list<DAE.Statement> i_statementLst;
      DAE.Exp i_exp;
      Tpl.Text l_condExp;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.NOELSE(),
           _,
           a_varDecls )
      then (txt, a_varDecls);

    case ( txt,
           DAE.ELSEIF(exp = i_exp, statementLst = i_statementLst, else_ = i_else__),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        (l_condExp, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeText(txt, l_condExp);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(") {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_546(txt, i_statementLst, a_varDecls, a_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("}\n"));
        (txt, a_varDecls) = elseExpr(txt, i_else__, a_context, a_varDecls);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, a_varDecls);

    case ( txt,
           DAE.ELSE(statementLst = i_statementLst),
           a_context,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("else {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls) = lm_547(txt, i_statementLst, a_varDecls, a_context);
        txt = Tpl.popIter(txt);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end elseExpr;

protected function fun_549
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input DAE.ComponentRef in_a_ecr_componentRef;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;
  input DAE.Exp in_a_ecr;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_mArg, in_a_ecr_componentRef, in_a_varDecls, in_a_preExp, in_a_context, in_a_ecr)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_ecr_componentRef;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp a_ecr;

    case ( txt,
           false,
           _,
           a_varDecls,
           a_preExp,
           a_context,
           a_ecr )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCrefRhs(txt, a_ecr, a_context, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_ecr_componentRef,
           a_varDecls,
           a_preExp,
           a_context,
           _ )
      equation
        txt = contextCref(txt, a_ecr_componentRef, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_549;

public function scalarLhsCref
  input Tpl.Text in_txt;
  input DAE.Exp in_a_ecr;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ecr, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_ecr;
      DAE.ComponentRef i_ecr_componentRef;
      DAE.ComponentRef i_cr;
      Boolean ret_0;

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_FUNCTION_REFERENCE_VAR()),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("*((modelica_fnptr*)&_"));
        txt = crefStr(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_ecr as DAE.CREF(componentRef = (i_ecr_componentRef as DAE.CREF_IDENT(ident = _)))),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        ret_0 = SimCode.crefNoSub(i_ecr_componentRef);
        (txt, a_varDecls, a_preExp) = fun_549(txt, ret_0, i_ecr_componentRef, a_varDecls, a_preExp, a_context, i_ecr);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CREF(componentRef = (i_ecr_componentRef as DAE.CREF_QUAL(ident = _))),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        txt = contextCref(txt, i_ecr_componentRef, a_context);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ONLY_IDENT_OR_QUAL_CREF_SUPPORTED_SLHS"));
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end scalarLhsCref;

public function rhsCref
  input Tpl.Text in_txt;
  input DAE.ComponentRef in_a_cr;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_cr, in_a_ty)
    local
      Tpl.Text txt;
      DAE.ExpType a_ty;
      DAE.ComponentRef i_componentRef;
      DAE.Ident i_ident;

    case ( txt,
           DAE.CREF_IDENT(ident = i_ident),
           a_ty )
      equation
        txt = rhsCrefType(txt, a_ty);
        txt = Tpl.writeStr(txt, i_ident);
      then txt;

    case ( txt,
           DAE.CREF_QUAL(ident = i_ident, componentRef = i_componentRef),
           a_ty )
      equation
        txt = rhsCrefType(txt, a_ty);
        txt = Tpl.writeStr(txt, i_ident);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = rhsCref(txt, i_componentRef, a_ty);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("rhsCref:ERROR"));
      then txt;
  end matchcontinue;
end rhsCref;

public function rhsCrefType
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end rhsCrefType;

protected function fun_553
  input Tpl.Text in_txt;
  input Boolean in_a_bool;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_bool)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(0)"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1)"));
      then txt;
  end matchcontinue;
end fun_553;

public function daeExp
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_e;
      Integer i_index;
      Boolean i_bool;
      String i_string;
      Real i_real;
      Integer i_integer;

    case ( txt,
           DAE.ICONST(integer = i_integer),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.RCONST(real = i_real),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeStr(txt, realString(i_real));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.SCONST(string = i_string),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpSconst(txt, i_string, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.BCONST(bool = i_bool),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = fun_553(txt, i_bool);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ENUM_LITERAL(index = i_index),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeStr(txt, intString(i_index));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.CREF(componentRef = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCrefRhs(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.BINARY(exp1 = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpBinary(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.UNARY(operator = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpUnary(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.LBINARY(exp1 = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpLbinary(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.LUNARY(operator = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpLunary(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.RELATION(exp1 = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpRelation(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.IFEXP(expCond = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpIf(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.CALL(path = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCall(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.ARRAY(ty = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpArray(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.MATRIX(ty = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpMatrix(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.CAST(ty = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCast(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.ASUB(exp = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpAsub(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.SIZE(exp = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpSize(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.REDUCTION(path = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpReduction(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.LIST(ty = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpList(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.CONS(ty = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCons(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.META_TUPLE(listExp = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpMetaTuple(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.META_OPTION(exp = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpMetaOption(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.METARECORDCALL(path = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpMetarecordcall(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           (i_e as DAE.MATCHEXPRESSION(matchType = _)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpMatch(txt, i_e, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_EXP"));
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExp;

public function daeExpSconst
  input Tpl.Text txt;
  input String a_string;
  input SimCode.Context a_context;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
protected
  String ret_0;
algorithm
  out_txt := Tpl.writeTok(txt, Tpl.ST_STRING("\""));
  ret_0 := Util.escapeModelicaStringToCString(a_string);
  out_txt := Tpl.writeStr(out_txt, ret_0);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("\""));
  out_a_preExp := a_preExp;
  out_a_varDecls := a_varDecls;
end daeExpSconst;

protected function fun_556
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;
  input DAE.ExpType in_a_t;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input DAE.Exp in_a_exp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_context, in_a_cr, in_a_t, in_a_varDecls, in_a_preExp, in_a_exp)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_cr;
      DAE.ExpType a_t;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp a_exp;
      SimCode.Context i_context;

    case ( txt,
           (i_context as SimCode.FUNCTION_CONTEXT()),
           _,
           _,
           a_varDecls,
           a_preExp,
           a_exp )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCrefRhs2(txt, a_exp, i_context, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_context,
           a_cr,
           a_t,
           a_varDecls,
           a_preExp,
           _ )
      equation
        (txt, a_preExp, a_varDecls) = daeExpRecordCrefRhs(txt, a_t, a_cr, i_context, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_556;

public function daeExpCrefRhs
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_cr;
      DAE.ExpType i_t;
      DAE.Exp i_exp;

    case ( txt,
           (i_exp as DAE.CREF(componentRef = i_cr, ty = (i_t as DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _))))),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_varDecls, a_preExp) = fun_556(txt, a_context, i_cr, i_t, a_varDecls, a_preExp, i_exp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_FUNCTION_REFERENCE_FUNC(builtin = _)),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_fnptr)boxptr_"));
        txt = functionName(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CREF(componentRef = i_cr, ty = DAE.ET_FUNCTION_REFERENCE_VAR()),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_fnptr) _"));
        txt = crefStr(txt, i_cr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           i_exp,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpCrefRhs2(txt, i_exp, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpCrefRhs;

protected function lm_558
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Subscript> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.INDEX(exp = i_exp) :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_558(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_558(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_558;

protected function fun_559
  input Tpl.Text in_txt;
  input String in_mArg;
  input Tpl.Text in_a_dimsLenStr;
  input Tpl.Text in_a_arrayType;
  input Tpl.Text in_a_dimsValuesStr;
  input Tpl.Text in_a_arrName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_dimsLenStr, in_a_arrayType, in_a_dimsValuesStr, in_a_arrName)
    local
      Tpl.Text txt;
      Tpl.Text a_dimsLenStr;
      Tpl.Text a_arrayType;
      Tpl.Text a_dimsValuesStr;
      Tpl.Text a_arrName;

    case ( txt,
           "metatype_array",
           _,
           _,
           a_dimsValuesStr,
           a_arrName )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("arrayGet("));
        txt = Tpl.writeText(txt, a_arrName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, a_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           a_dimsLenStr,
           a_arrayType,
           a_dimsValuesStr,
           a_arrName )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*"));
        txt = Tpl.writeText(txt, a_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_element_addr(&"));
        txt = Tpl.writeText(txt, a_arrName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_dimsLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;
  end matchcontinue;
end fun_559;

protected function fun_560
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;
  input DAE.ExpType in_a_ty;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_preExp, in_a_varDecls, in_a_ty, in_a_context, in_a_cr)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType a_ty;
      SimCode.Context a_context;
      DAE.ComponentRef a_cr;
      String str_11;
      list<DAE.Subscript> ret_10;
      Tpl.Text l_dimsValuesStr;
      Integer ret_8;
      list<DAE.Subscript> ret_7;
      Tpl.Text l_dimsLenStr;
      DAE.ComponentRef ret_5;
      list<DAE.Subscript> ret_4;
      Tpl.Text l_spec1;
      Tpl.Text l_tmp;
      Tpl.Text l_arrayType;
      Tpl.Text l_arrName;

    case ( txt,
           false,
           a_preExp,
           a_varDecls,
           a_ty,
           a_context,
           a_cr )
      equation
        l_arrName = contextArrayCref(Tpl.emptyTxt, a_cr, a_context);
        l_arrayType = expTypeArray(Tpl.emptyTxt, a_ty);
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arrayType), a_varDecls);
        ret_4 = ComponentReference.crefSubs(a_cr);
        (l_spec1, a_preExp, a_varDecls) = daeExpCrefRhsIndexSpec(Tpl.emptyTxt, ret_4, a_context, a_preExp, a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("index_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arrayType);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_arrName);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_spec1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls,
           a_ty,
           a_context,
           a_cr )
      equation
        ret_5 = ComponentReference.crefStripLastSubs(a_cr);
        l_arrName = contextCref(Tpl.emptyTxt, ret_5, a_context);
        l_arrayType = expTypeArray(Tpl.emptyTxt, a_ty);
        ret_7 = ComponentReference.crefSubs(a_cr);
        ret_8 = listLength(ret_7);
        l_dimsLenStr = Tpl.writeStr(Tpl.emptyTxt, intString(ret_8));
        ret_10 = ComponentReference.crefSubs(a_cr);
        l_dimsValuesStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_dimsValuesStr, a_varDecls, a_preExp) = lm_558(l_dimsValuesStr, ret_10, a_varDecls, a_preExp, a_context);
        l_dimsValuesStr = Tpl.popIter(l_dimsValuesStr);
        str_11 = Tpl.textString(l_arrayType);
        txt = fun_559(txt, str_11, l_dimsLenStr, l_arrayType, l_dimsValuesStr, l_arrName);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_560;

protected function fun_561
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_561;

protected function fun_562
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;
  input DAE.ExpType in_a_ty;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_preExp, in_a_varDecls, in_a_ty, in_a_context, in_a_cr)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType a_ty;
      SimCode.Context a_context;
      DAE.ComponentRef a_cr;
      Tpl.Text l_cast;
      Boolean ret_0;

    case ( txt,
           false,
           a_preExp,
           a_varDecls,
           a_ty,
           a_context,
           a_cr )
      equation
        ret_0 = SimCode.crefSubIsScalar(a_cr);
        (txt, a_preExp, a_varDecls) = fun_560(txt, ret_0, a_preExp, a_varDecls, a_ty, a_context, a_cr);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           a_varDecls,
           a_ty,
           a_context,
           a_cr )
      equation
        l_cast = fun_561(Tpl.emptyTxt, a_ty);
        txt = Tpl.writeText(txt, l_cast);
        txt = contextCref(txt, a_cr, a_context);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_562;

protected function fun_563
  input Tpl.Text in_txt;
  input Tpl.Text in_a_box;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;
  input DAE.ExpType in_a_ty;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_box, in_a_preExp, in_a_varDecls, in_a_ty, in_a_context, in_a_cr)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType a_ty;
      SimCode.Context a_context;
      DAE.ComponentRef a_cr;
      Tpl.Text i_box;
      Boolean ret_0;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}),
           a_preExp,
           a_varDecls,
           a_ty,
           a_context,
           a_cr )
      equation
        ret_0 = SimCode.crefIsScalar(a_cr, a_context);
        (txt, a_preExp, a_varDecls) = fun_562(txt, ret_0, a_preExp, a_varDecls, a_ty, a_context, a_cr);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           i_box,
           a_preExp,
           a_varDecls,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeText(txt, i_box);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_563;

public function daeExpCrefRhs2
  input Tpl.Text in_txt;
  input DAE.Exp in_a_ecr;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ecr, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType i_ty;
      DAE.ComponentRef i_cr;
      DAE.Exp i_ecr;
      Tpl.Text l_box;

    case ( txt,
           (i_ecr as DAE.CREF(componentRef = i_cr, ty = i_ty)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_box, a_preExp, a_varDecls) = daeExpCrefRhsArrayBox(Tpl.emptyTxt, i_ecr, a_context, a_preExp, a_varDecls);
        (txt, a_preExp, a_varDecls) = fun_563(txt, l_box, a_preExp, a_varDecls, i_ty, a_context, i_cr);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpCrefRhs2;

protected function fun_565
  input Tpl.Text in_txt;
  input DAE.Subscript in_a_sub;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_sub, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_exp;
      Tpl.Text l_tmp;
      Tpl.Text l_expPart;

    case ( txt,
           DAE.INDEX(exp = i_exp),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_expPart, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(0), make_index_array(1, "));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), \'S\'"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.WHOLEDIM(),
           a_varDecls,
           a_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(1), (int*)0, \'W\'"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.SLICE(exp = i_exp),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_expPart, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_integer", a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = size_of_dimension_integer_array("));
        a_preExp = Tpl.writeText(a_preExp, l_expPart);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", 1);"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", integer_array_make_index_array(&"));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), \'A\'"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_565;

protected function lm_566
  input Tpl.Text in_txt;
  input list<DAE.Subscript> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Subscript> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Subscript i_sub;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_sub :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = fun_565(txt, i_sub, a_varDecls, a_preExp, a_context);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_566(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_566(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_566;

public function daeExpCrefRhsIndexSpec
  input Tpl.Text txt;
  input list<DAE.Subscript> a_subs;
  input SimCode.Context a_context;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_tmp;
  Tpl.Text l_idx__str;
  Integer ret_1;
  Tpl.Text l_nridx__str;
algorithm
  ret_1 := listLength(a_subs);
  l_nridx__str := Tpl.writeStr(Tpl.emptyTxt, intString(ret_1));
  l_idx__str := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_idx__str, out_a_varDecls, out_a_preExp) := lm_566(l_idx__str, a_subs, a_varDecls, a_preExp, a_context);
  l_idx__str := Tpl.popIter(l_idx__str);
  (l_tmp, out_a_varDecls) := tempDecl(Tpl.emptyTxt, "index_spec_t", out_a_varDecls);
  out_a_preExp := Tpl.writeTok(out_a_preExp, Tpl.ST_STRING("create_index_spec(&"));
  out_a_preExp := Tpl.writeText(out_a_preExp, l_tmp);
  out_a_preExp := Tpl.writeTok(out_a_preExp, Tpl.ST_STRING(", "));
  out_a_preExp := Tpl.writeText(out_a_preExp, l_nridx__str);
  out_a_preExp := Tpl.writeTok(out_a_preExp, Tpl.ST_STRING(", "));
  out_a_preExp := Tpl.writeText(out_a_preExp, l_idx__str);
  out_a_preExp := Tpl.writeTok(out_a_preExp, Tpl.ST_STRING(");"));
  out_a_preExp := Tpl.writeTok(out_a_preExp, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, l_tmp);
end daeExpCrefRhsIndexSpec;

protected function lm_568
  input Tpl.Text in_txt;
  input list<DAE.Dimension> in_items;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_items)
    local
      Tpl.Text txt;
      list<DAE.Dimension> rest;
      DAE.Dimension i_dim;

    case ( txt,
           {} )
      then txt;

    case ( txt,
           i_dim :: rest )
      equation
        txt = dimension(txt, i_dim);
        txt = Tpl.nextIter(txt);
        txt = lm_568(txt, rest);
      then txt;

    case ( txt,
           _ :: rest )
      equation
        txt = lm_568(txt, rest);
      then txt;
  end matchcontinue;
end lm_568;

protected function fun_569
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_ecr_componentRef;
  input Tpl.Text in_a_preExp;
  input list<DAE.Dimension> in_a_dims;
  input Tpl.Text in_a_varDecls;
  input DAE.ExpType in_a_aty;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_context, in_a_ecr_componentRef, in_a_preExp, in_a_dims, in_a_varDecls, in_a_aty)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_ecr_componentRef;
      Tpl.Text a_preExp;
      list<DAE.Dimension> a_dims;
      Tpl.Text a_varDecls;
      DAE.ExpType a_aty;
      Tpl.Text l_type;
      Tpl.Text l_dimsValuesStr;
      Integer ret_3;
      Tpl.Text l_dimsLenStr;
      Tpl.Text txt_1;
      Tpl.Text l_tmpArr;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           _,
           a_preExp,
           _,
           a_varDecls,
           _ )
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_ecr_componentRef,
           a_preExp,
           a_dims,
           a_varDecls,
           a_aty )
      equation
        txt_1 = expTypeArray(Tpl.emptyTxt, a_aty);
        (l_tmpArr, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_1), a_varDecls);
        ret_3 = listLength(a_dims);
        l_dimsLenStr = Tpl.writeStr(Tpl.emptyTxt, intString(ret_3));
        l_dimsValuesStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        l_dimsValuesStr = lm_568(l_dimsValuesStr, a_dims);
        l_dimsValuesStr = Tpl.popIter(l_dimsValuesStr);
        l_type = expTypeShort(Tpl.emptyTxt, a_aty);
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_array_create(&"));
        a_preExp = Tpl.writeText(a_preExp, l_tmpArr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", ((modelica_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("*)&("));
        a_preExp = arrayCrefCStr(a_preExp, a_ecr_componentRef);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(")), "));
        a_preExp = Tpl.writeText(a_preExp, l_dimsLenStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_dimsValuesStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmpArr);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_569;

public function daeExpCrefRhsArrayBox
  input Tpl.Text in_txt;
  input DAE.Exp in_a_ecr;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ecr, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ComponentRef i_ecr_componentRef;
      list<DAE.Dimension> i_dims;
      DAE.ExpType i_aty;

    case ( txt,
           DAE.CREF(ty = DAE.ET_ARRAY(ty = i_aty, arrayDimensions = i_dims), componentRef = i_ecr_componentRef),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = fun_569(txt, a_context, i_ecr_componentRef, a_preExp, i_dims, a_varDecls, i_aty);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpCrefRhsArrayBox;

protected function lm_571
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;
  input DAE.ComponentRef in_a_cr;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context, in_a_cr)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.ComponentRef a_cr;
      DAE.ExpVar i_v;
      DAE.Exp ret_0;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_v :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_cr )
      equation
        ret_0 = SimCode.makeCrefRecordExp(a_cr, i_v);
        (txt, a_preExp, a_varDecls) = daeExp(txt, ret_0, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_571(txt, rest, a_varDecls, a_preExp, a_context, a_cr);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_cr )
      equation
        (txt, a_varDecls, a_preExp) = lm_571(txt, rest, a_varDecls, a_preExp, a_context, a_cr);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_571;

public function daeExpRecordCrefRhs
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;
  input DAE.ComponentRef in_a_cr;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ty, in_a_cr, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      DAE.ComponentRef a_cr;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      Absyn.Path i_record__path;
      list<DAE.ExpVar> i_var__lst;
      Tpl.Text l_ret__var;
      Tpl.Text l_ret__type;
      Tpl.Text l_record__type__name;
      Tpl.Text l_vars;

    case ( txt,
           DAE.ET_COMPLEX(name = i_record__path, varLst = i_var__lst),
           a_cr,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_vars = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_vars, a_varDecls, a_preExp) = lm_571(l_vars, i_var__lst, a_varDecls, a_preExp, a_context, a_cr);
        l_vars = Tpl.popIter(l_vars);
        l_record__type__name = underscorePath(Tpl.emptyTxt, i_record__path);
        l_ret__type = Tpl.writeText(Tpl.emptyTxt, l_record__type__name);
        l_ret__type = Tpl.writeTok(l_ret__type, Tpl.ST_STRING("_rettype"));
        (l_ret__var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_ret__type), a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_ret__var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = _"));
        a_preExp = Tpl.writeText(a_preExp, l_record__type__name);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeText(a_preExp, l_vars);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_ret__var);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, l_ret__type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpRecordCrefRhs;

protected function fun_573
  input Tpl.Text in_txt;
  input Boolean in_mArg;
  input Tpl.Text in_a_e2;
  input Tpl.Text in_a_e1;
  input Tpl.Text in_a_tmpStr;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_e2, in_a_e1, in_a_tmpStr)
    local
      Tpl.Text txt;
      Tpl.Text a_e2;
      Tpl.Text a_e1;
      Tpl.Text a_tmpStr;

    case ( txt,
           false,
           a_e2,
           a_e1,
           a_tmpStr )
      equation
        txt = Tpl.writeText(txt, a_tmpStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = cat_modelica_string("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           a_e2,
           a_e1,
           a_tmpStr )
      equation
        txt = Tpl.writeText(txt, a_tmpStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = stringAppend("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;
  end matchcontinue;
end fun_573;

protected function fun_574
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_574;

protected function fun_575
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_575;

protected function fun_576
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_576;

protected function fun_577
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_577;

protected function fun_578
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_scalar"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_scalar"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_scalar"));
      then txt;
  end matchcontinue;
end fun_578;

protected function fun_579
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;
  end matchcontinue;
end fun_579;

protected function fun_580
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_580;

protected function fun_581
  input Tpl.Text in_txt;
  input DAE.Operator in_a_operator;
  input SimCode.Context in_a_context;
  input DAE.Exp in_a_exp;
  input Tpl.Text in_a_e2;
  input Tpl.Text in_a_e1;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_operator, in_a_context, in_a_exp, in_a_e2, in_a_e1, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      DAE.Exp a_exp;
      Tpl.Text a_e2;
      Tpl.Text a_e1;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType i_ty;
      Tpl.Text l_typeShort;
      Tpl.Text l_var;
      Tpl.Text l_type;
      Boolean ret_1;
      Tpl.Text l_tmpStr;

    case ( txt,
           DAE.ADD(ty = DAE.ET_STRING()),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        (l_tmpStr, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_string", a_varDecls);
        ret_1 = RTOpts.acceptMetaModelicaGrammar();
        a_preExp = fun_573(a_preExp, ret_1, a_e2, a_e1, l_tmpStr);
        txt = Tpl.writeText(txt, l_tmpStr);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ADD(ty = _),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" + "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.SUB(ty = _),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" - "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MUL(ty = _),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" * "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.DIV(ty = _),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" / "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.POW(ty = _),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("pow((modelica_real)"));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", (modelica_real)"));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.UMINUS(ty = _),
           a_context,
           a_exp,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_preExp, a_varDecls) = daeExpUnary(txt, a_exp, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ADD_ARR(ty = i_ty),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        l_type = fun_574(Tpl.emptyTxt, i_ty);
        (l_var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_type), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("add_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_var);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.SUB_ARR(ty = i_ty),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        l_type = fun_575(Tpl.emptyTxt, i_ty);
        (l_var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_type), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("sub_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_var);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MUL_ARR(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for MUL_ARR"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.DIV_ARR(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for DIV_ARR"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MUL_SCALAR_ARRAY(ty = i_ty),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        l_type = fun_576(Tpl.emptyTxt, i_ty);
        (l_var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_type), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("mul_alloc_scalar_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_var);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MUL_ARRAY_SCALAR(ty = i_ty),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        l_type = fun_577(Tpl.emptyTxt, i_ty);
        (l_var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_type), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("mul_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_scalar(&"));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_var);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ADD_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for ADD_SCALAR_ARRAY"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ADD_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for ADD_ARRAY_SCALAR"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.SUB_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for SUB_SCALAR_ARRAY"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.SUB_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for SUB_ARRAY_SCALAR"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MUL_SCALAR_PRODUCT(ty = i_ty),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        l_type = fun_578(Tpl.emptyTxt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mul_"));
        txt = Tpl.writeText(txt, l_type);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_product(&"));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", &"));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MUL_MATRIX_PRODUCT(ty = i_ty),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        l_typeShort = fun_579(Tpl.emptyTxt, i_ty);
        l_type = Tpl.writeText(Tpl.emptyTxt, l_typeShort);
        l_type = Tpl.writeTok(l_type, Tpl.ST_STRING("_array"));
        (l_var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_type), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("mul_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_typeShort);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_matrix_product_smart(&"));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_var);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.DIV_ARRAY_SCALAR(ty = i_ty),
           _,
           _,
           a_e2,
           a_e1,
           a_preExp,
           a_varDecls )
      equation
        l_type = fun_580(Tpl.emptyTxt, i_ty);
        (l_var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_type), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("div_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_scalar(&"));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_var);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.DIV_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for DIV_SCALAR_ARRAY"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.POW_ARRAY_SCALAR(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARRAY_SCALAR"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.POW_SCALAR_ARRAY(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_SCALAR_ARRAY"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.POW_ARR(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARR"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.POW_ARR2(ty = _),
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR for POW_ARR2"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           _,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpBinary:ERR"));
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_581;

public function daeExpBinary
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_exp;
      DAE.Operator i_operator;
      DAE.Exp i_exp2;
      DAE.Exp i_exp1;
      Tpl.Text l_e2;
      Tpl.Text l_e1;

    case ( txt,
           (i_exp as DAE.BINARY(exp1 = i_exp1, exp2 = i_exp2, operator = i_operator)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp1, a_context, a_preExp, a_varDecls);
        (l_e2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp2, a_context, a_preExp, a_varDecls);
        (txt, a_preExp, a_varDecls) = fun_581(txt, i_operator, a_context, i_exp, l_e2, l_e1, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpBinary;

protected function fun_583
  input Tpl.Text in_txt;
  input DAE.Operator in_a_operator;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_e;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_preExp) :=
  matchcontinue(in_txt, in_a_operator, in_a_preExp, in_a_e)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      Tpl.Text a_e;

    case ( txt,
           DAE.UMINUS(ty = _),
           a_preExp,
           a_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(-"));
        txt = Tpl.writeText(txt, a_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp);

    case ( txt,
           DAE.UPLUS(ty = _),
           a_preExp,
           a_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp);

    case ( txt,
           DAE.UMINUS_ARR(ty = DAE.ET_ARRAY(ty = DAE.ET_REAL())),
           a_preExp,
           a_e )
      equation
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("usub_real_array(&"));
        a_preExp = Tpl.writeText(a_preExp, a_e);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, a_e);
      then (txt, a_preExp);

    case ( txt,
           DAE.UMINUS_ARR(ty = _),
           a_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("unary minus for non-real arrays not implemented"));
      then (txt, a_preExp);

    case ( txt,
           DAE.UPLUS_ARR(ty = _),
           a_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UPLUS_ARR_NOT_IMPLEMENTED"));
      then (txt, a_preExp);

    case ( txt,
           _,
           a_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpUnary:ERR"));
      then (txt, a_preExp);
  end matchcontinue;
end fun_583;

public function daeExpUnary
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Operator i_operator;
      DAE.Exp i_exp;
      Tpl.Text l_e;

    case ( txt,
           DAE.UNARY(exp = i_exp, operator = i_operator),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_e, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        (txt, a_preExp) = fun_583(txt, i_operator, a_preExp, l_e);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpUnary;

protected function fun_585
  input Tpl.Text in_txt;
  input DAE.Operator in_a_operator;
  input Tpl.Text in_a_e2;
  input Tpl.Text in_a_e1;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_operator, in_a_e2, in_a_e1)
    local
      Tpl.Text txt;
      Tpl.Text a_e2;
      Tpl.Text a_e1;

    case ( txt,
           DAE.AND(),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.OR(),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpLbinary:ERR"));
      then txt;
  end matchcontinue;
end fun_585;

public function daeExpLbinary
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Operator i_operator;
      DAE.Exp i_exp2;
      DAE.Exp i_exp1;
      Tpl.Text l_e2;
      Tpl.Text l_e1;

    case ( txt,
           DAE.LBINARY(exp1 = i_exp1, exp2 = i_exp2, operator = i_operator),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp1, a_context, a_preExp, a_varDecls);
        (l_e2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp2, a_context, a_preExp, a_varDecls);
        txt = fun_585(txt, i_operator, l_e2, l_e1);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpLbinary;

protected function fun_587
  input Tpl.Text in_txt;
  input DAE.Operator in_a_operator;
  input Tpl.Text in_a_e;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_operator, in_a_e)
    local
      Tpl.Text txt;
      Tpl.Text a_e;

    case ( txt,
           DAE.NOT(),
           a_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, a_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_587;

public function daeExpLunary
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Operator i_operator;
      DAE.Exp i_exp;
      Tpl.Text l_e;

    case ( txt,
           DAE.LUNARY(exp = i_exp, operator = i_operator),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_e, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        txt = fun_587(txt, i_operator, l_e);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpLunary;

protected function fun_589
  input Tpl.Text in_txt;
  input DAE.Operator in_a_rel_operator;
  input Tpl.Text in_a_e2;
  input Tpl.Text in_a_e1;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_rel_operator, in_a_e2, in_a_e1)
    local
      Tpl.Text txt;
      Tpl.Text a_e2;
      Tpl.Text a_e1;

    case ( txt,
           DAE.LESS(ty = DAE.ET_BOOL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_STRING()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(strcmp("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") < 0)"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_INT()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" < "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_REAL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" < "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESS(ty = DAE.ET_ENUMERATION(path = _)),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" < "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_BOOL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_STRING()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(strcmp("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") > 0)"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_INT()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" > "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_REAL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" > "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATER(ty = DAE.ET_ENUMERATION(path = _)),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" > "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_BOOL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!"));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_STRING()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(strcmp("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") <= 0)"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_INT()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" <= "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_REAL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" <= "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = DAE.ET_ENUMERATION(path = _)),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" <= "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_BOOL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" || !"));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_STRING()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(strcmp("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") >= 0)"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_INT()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" >= "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_REAL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" >= "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = DAE.ET_ENUMERATION(path = _)),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" >= "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_BOOL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((!"));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") || ("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_STRING()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(!strcmp("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_INT()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_REAL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.EQUAL(ty = DAE.ET_ENUMERATION(path = _)),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" == "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_BOOL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((!"));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") || ("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" && !"));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_STRING()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(strcmp("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_INT()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_REAL()),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = DAE.ET_ENUMERATION(path = _)),
           a_e2,
           a_e1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, a_e2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("daeExpRelation:ERR"));
      then txt;
  end matchcontinue;
end fun_589;

protected function fun_590
  input Tpl.Text in_txt;
  input Tpl.Text in_a_simRel;
  input DAE.Operator in_a_rel_operator;
  input DAE.Exp in_a_rel_exp2;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;
  input DAE.Exp in_a_rel_exp1;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_simRel, in_a_rel_operator, in_a_rel_exp2, in_a_varDecls, in_a_preExp, in_a_context, in_a_rel_exp1)
    local
      Tpl.Text txt;
      DAE.Operator a_rel_operator;
      DAE.Exp a_rel_exp2;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp a_rel_exp1;
      Tpl.Text i_simRel;
      Tpl.Text l_e2;
      Tpl.Text l_e1;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}),
           a_rel_operator,
           a_rel_exp2,
           a_varDecls,
           a_preExp,
           a_context,
           a_rel_exp1 )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_rel_exp1, a_context, a_preExp, a_varDecls);
        (l_e2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_rel_exp2, a_context, a_preExp, a_varDecls);
        txt = fun_589(txt, a_rel_operator, l_e2, l_e1);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_simRel,
           _,
           _,
           a_varDecls,
           a_preExp,
           _,
           _ )
      equation
        txt = Tpl.writeText(txt, i_simRel);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_590;

public function daeExpRelation
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Operator i_rel_operator;
      DAE.Exp i_rel_exp2;
      DAE.Exp i_rel_exp1;
      DAE.Exp i_rel;
      Tpl.Text l_simRel;

    case ( txt,
           (i_rel as DAE.RELATION(exp1 = i_rel_exp1, exp2 = i_rel_exp2, operator = i_rel_operator)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_simRel, a_preExp, a_varDecls) = daeExpRelationSim(Tpl.emptyTxt, i_rel, a_context, a_preExp, a_varDecls);
        (txt, a_varDecls, a_preExp) = fun_590(txt, l_simRel, i_rel_operator, i_rel_exp2, a_varDecls, a_preExp, a_context, i_rel_exp1);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpRelation;

protected function fun_592
  input Tpl.Text in_txt;
  input DAE.Operator in_a_rel_operator;
  input Tpl.Text in_a_e2;
  input Tpl.Text in_a_e1;
  input Tpl.Text in_a_res;
  input Tpl.Text in_a_preExp;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_preExp) :=
  matchcontinue(in_txt, in_a_rel_operator, in_a_e2, in_a_e1, in_a_res, in_a_preExp)
    local
      Tpl.Text txt;
      Tpl.Text a_e2;
      Tpl.Text a_e1;
      Tpl.Text a_res;
      Tpl.Text a_preExp;

    case ( txt,
           DAE.LESS(ty = _),
           a_e2,
           a_e1,
           a_res,
           a_preExp )
      equation
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("RELATIONLESS("));
        a_preExp = Tpl.writeText(a_preExp, a_res);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, a_res);
      then (txt, a_preExp);

    case ( txt,
           DAE.LESSEQ(ty = _),
           a_e2,
           a_e1,
           a_res,
           a_preExp )
      equation
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("RELATIONLESSEQ("));
        a_preExp = Tpl.writeText(a_preExp, a_res);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, a_res);
      then (txt, a_preExp);

    case ( txt,
           DAE.GREATER(ty = _),
           a_e2,
           a_e1,
           a_res,
           a_preExp )
      equation
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("RELATIONGREATER("));
        a_preExp = Tpl.writeText(a_preExp, a_res);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, a_res);
      then (txt, a_preExp);

    case ( txt,
           DAE.GREATEREQ(ty = _),
           a_e2,
           a_e1,
           a_res,
           a_preExp )
      equation
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("RELATIONGREATEREQ("));
        a_preExp = Tpl.writeText(a_preExp, a_res);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, a_e2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, a_res);
      then (txt, a_preExp);

    case ( txt,
           _,
           _,
           _,
           _,
           a_preExp )
      then (txt, a_preExp);
  end matchcontinue;
end fun_592;

protected function fun_593
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input DAE.Operator in_a_rel_operator;
  input DAE.Exp in_a_rel_exp2;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input DAE.Exp in_a_rel_exp1;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_context, in_a_rel_operator, in_a_rel_exp2, in_a_varDecls, in_a_preExp, in_a_rel_exp1)
    local
      Tpl.Text txt;
      DAE.Operator a_rel_operator;
      DAE.Exp a_rel_exp2;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      DAE.Exp a_rel_exp1;
      SimCode.Context i_context;
      Tpl.Text l_res;
      Tpl.Text l_e2;
      Tpl.Text l_e1;

    case ( txt,
           (i_context as SimCode.SIMULATION(genDiscrete = _)),
           a_rel_operator,
           a_rel_exp2,
           a_varDecls,
           a_preExp,
           a_rel_exp1 )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_rel_exp1, i_context, a_preExp, a_varDecls);
        (l_e2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, a_rel_exp2, i_context, a_preExp, a_varDecls);
        (l_res, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_boolean", a_varDecls);
        (txt, a_preExp) = fun_592(txt, a_rel_operator, l_e2, l_e1, l_res, a_preExp);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           _,
           _,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_593;

public function daeExpRelationSim
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Operator i_rel_operator;
      DAE.Exp i_rel_exp2;
      DAE.Exp i_rel_exp1;

    case ( txt,
           DAE.RELATION(exp1 = i_rel_exp1, exp2 = i_rel_exp2, operator = i_rel_operator),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_varDecls, a_preExp) = fun_593(txt, a_context, i_rel_operator, i_rel_exp2, a_varDecls, a_preExp, i_rel_exp1);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpRelationSim;

public function daeExpIf
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_expElse;
      DAE.Exp i_expThen;
      DAE.Exp i_expCond;
      Tpl.Text l_eElse;
      Tpl.Text l_preExpElse;
      Tpl.Text l_eThen;
      Tpl.Text l_preExpThen;
      Tpl.Text l_resVar;
      Tpl.Text l_resVarType;
      Tpl.Text l_condVar;
      Tpl.Text l_condExp;

    case ( txt,
           DAE.IFEXP(expCond = i_expCond, expThen = i_expThen, expElse = i_expElse),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_condExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_expCond, a_context, a_preExp, a_varDecls);
        (l_condVar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_boolean", a_varDecls);
        l_resVarType = expTypeFromExpArrayIf(Tpl.emptyTxt, i_expThen);
        (l_resVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_resVarType), a_varDecls);
        l_preExpThen = Tpl.emptyTxt;
        (l_eThen, l_preExpThen, a_varDecls) = daeExp(Tpl.emptyTxt, i_expThen, a_context, l_preExpThen, a_varDecls);
        l_preExpElse = Tpl.emptyTxt;
        (l_eElse, l_preExpElse, a_varDecls) = daeExp(Tpl.emptyTxt, i_expElse, a_context, l_preExpElse, a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_condVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = (modelica_boolean)"));
        a_preExp = Tpl.writeText(a_preExp, l_condExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING_LIST({
                                              ";\n",
                                              "if ("
                                          }, false));
        a_preExp = Tpl.writeText(a_preExp, l_condVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE(") {\n"));
        a_preExp = Tpl.pushBlock(a_preExp, Tpl.BT_INDENT(2));
        a_preExp = Tpl.writeText(a_preExp, l_preExpThen);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeText(a_preExp, l_resVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = ("));
        a_preExp = Tpl.writeText(a_preExp, l_resVarType);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(")"));
        a_preExp = Tpl.writeText(a_preExp, l_eThen);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE(";\n"));
        a_preExp = Tpl.popBlock(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE("} else {\n"));
        a_preExp = Tpl.pushBlock(a_preExp, Tpl.BT_INDENT(2));
        a_preExp = Tpl.writeText(a_preExp, l_preExpElse);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeText(a_preExp, l_resVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = ("));
        a_preExp = Tpl.writeText(a_preExp, l_resVarType);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(")"));
        a_preExp = Tpl.writeText(a_preExp, l_eElse);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE(";\n"));
        a_preExp = Tpl.popBlock(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("}"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_resVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpIf;

protected function fun_596
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_INT()) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = DAE.ET_ENUMERATION(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer_array"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real_array"));
      then txt;
  end matchcontinue;
end fun_596;

protected function fun_597
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_arg_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_arg_ty)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_integer)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_597;

protected function lm_598
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_598(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_598(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_598;

protected function lm_599
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_599(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_599(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_599;

protected function fun_600
  input Tpl.Text in_txt;
  input Boolean in_a_builtin;
  input Tpl.Text in_a_retType;
  input Tpl.Text in_a_retVar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_builtin, in_a_retType, in_a_retVar)
    local
      Tpl.Text txt;
      Tpl.Text a_retType;
      Tpl.Text a_retVar;

    case ( txt,
           false,
           a_retType,
           a_retVar )
      equation
        txt = Tpl.writeText(txt, a_retVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeText(txt, a_retType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_1"));
      then txt;

    case ( txt,
           _,
           _,
           a_retVar )
      equation
        txt = Tpl.writeText(txt, a_retVar);
      then txt;
  end matchcontinue;
end fun_600;

protected function lm_601
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_601(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_601(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_601;

public function daeExpCall
  input Tpl.Text in_txt;
  input DAE.Exp in_a_call;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_call, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      Boolean i_builtin;
      Absyn.Path i_path;
      list<DAE.Exp> i_expLst;
      Integer i_i;
      DAE.Exp i_s1;
      DAE.Exp i_toBeCasted;
      Integer i_index;
      DAE.Exp i_delayMax;
      DAE.Exp i_d;
      DAE.Exp i_e;
      DAE.Exp i_signdig;
      DAE.Exp i_leftjust;
      DAE.Exp i_minlen;
      DAE.Exp i_format;
      DAE.Exp i_s;
      DAE.Exp i_v2;
      DAE.Exp i_v1;
      DAE.Exp i_n;
      DAE.Exp i_A;
      DAE.Exp i_array;
      DAE.ExpType i_arg_ty;
      DAE.ComponentRef i_arg_componentRef;
      DAE.ExpType i_ty;
      String i_string;
      DAE.Exp i_e2;
      DAE.Exp i_e1;
      Tpl.Text l_funName;
      Tpl.Text l_argStr;
      Tpl.Text l_expPart;
      Tpl.Text l_castedVar;
      Tpl.Text l_signdigExp;
      Tpl.Text l_leftjustExp;
      Tpl.Text l_minlenExp;
      Tpl.Text l_formatExp;
      Tpl.Text l_sExp;
      Tpl.Text l_typeStr;
      Tpl.Text txt_14;
      Tpl.Text txt_13;
      Tpl.Text l_tvar;
      Tpl.Text l_arr__tp__str;
      Tpl.Text l_expVar;
      Tpl.Text l_cast;
      Tpl.Text l_retVar;
      Tpl.Text l_retType;
      String ret_6;
      Tpl.Text l_var;
      Tpl.Text l_type;
      String ret_3;
      Tpl.Text l_var3;
      Tpl.Text l_var2;
      Tpl.Text l_var1;

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "DIVISION"), expLst = {i_e1, i_e2, DAE.SCONST(string = i_string)}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e2, a_context, a_preExp, a_varDecls);
        ret_3 = Util.escapeModelicaStringToCString(i_string);
        l_var3 = Tpl.writeStr(Tpl.emptyTxt, ret_3);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("DIVISION("));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",\""));
        txt = Tpl.writeText(txt, l_var3);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, ty = i_ty, path = Absyn.IDENT(name = "DIVISION_ARRAY_SCALAR"), expLst = {i_e1, i_e2, DAE.SCONST(string = i_string)}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_type = fun_596(Tpl.emptyTxt, i_ty);
        (l_var, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_type), a_varDecls);
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e2, a_context, a_preExp, a_varDecls);
        ret_6 = Util.escapeModelicaStringToCString(i_string);
        l_var3 = Tpl.writeStr(Tpl.emptyTxt, ret_6);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("division_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_type);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_scalar(&"));
        a_preExp = Tpl.writeText(a_preExp, l_var1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_var2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(",\""));
        a_preExp = Tpl.writeText(a_preExp, l_var3);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("\");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_var);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = i_arg_componentRef)}),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("$P$DER"));
        txt = cref(txt, i_arg_componentRef);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "pre"), expLst = {DAE.CREF(ty = i_arg_ty, componentRef = i_arg_componentRef)}),
           _,
           a_preExp,
           a_varDecls )
      equation
        l_retType = expTypeArrayIf(Tpl.emptyTxt, i_arg_ty);
        (l_retVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_retType), a_varDecls);
        l_cast = fun_597(Tpl.emptyTxt, i_arg_ty);
        a_preExp = Tpl.writeText(a_preExp, l_retVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_cast);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("pre("));
        a_preExp = cref(a_preExp, i_arg_componentRef);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_retVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "max"), expLst = {i_e1, i_e2}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e2, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::max("));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, ty = DAE.ET_INT(), path = Absyn.IDENT(name = "min"), expLst = {i_e1, i_e2}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e2, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::min((modelica_integer)"));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",(modelica_integer)"));
        txt = Tpl.writeText(txt, l_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, ty = DAE.ET_ENUMERATION(path = _), path = Absyn.IDENT(name = "min"), expLst = {i_e1, i_e2}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e2, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::min((modelica_integer)"));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(",(modelica_integer)"));
        txt = Tpl.writeText(txt, l_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, ty = DAE.ET_REAL(), path = Absyn.IDENT(name = "min"), expLst = {i_e1, i_e2}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e2, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::min("));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "abs"), expLst = {i_e1}, ty = DAE.ET_INT()),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("std::abs("));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "abs"), expLst = {i_e1}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fabs("));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "max"), expLst = {i_array}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_expVar, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_array, a_context, a_preExp, a_varDecls);
        l_arr__tp__str = expTypeFromExpArray(Tpl.emptyTxt, i_array);
        txt_13 = expTypeFromExpModelica(Tpl.emptyTxt, i_array);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_13), a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = max_"));
        a_preExp = Tpl.writeText(a_preExp, l_arr__tp__str);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_expVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "min"), expLst = {i_array}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_expVar, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_array, a_context, a_preExp, a_varDecls);
        l_arr__tp__str = expTypeFromExpArray(Tpl.emptyTxt, i_array);
        txt_14 = expTypeFromExpModelica(Tpl.emptyTxt, i_array);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_14), a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = min_"));
        a_preExp = Tpl.writeText(a_preExp, l_arr__tp__str);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_expVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "promote"), expLst = {i_A, i_n}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_A, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_n, a_context, a_preExp, a_varDecls);
        l_arr__tp__str = expTypeFromExpArray(Tpl.emptyTxt, i_A);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arr__tp__str), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("promote_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arr__tp__str);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_var1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_var2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "transpose"), expLst = {i_A}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_A, a_context, a_preExp, a_varDecls);
        l_arr__tp__str = expTypeFromExpArray(Tpl.emptyTxt, i_A);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arr__tp__str), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("transpose_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arr__tp__str);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_var1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "cross"), expLst = {i_v1, i_v2}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_v1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_v2, a_context, a_preExp, a_varDecls);
        l_arr__tp__str = expTypeFromExpArray(Tpl.emptyTxt, i_v1);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arr__tp__str), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("cross_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arr__tp__str);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_var1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_var2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "identity"), expLst = {i_A}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_A, a_context, a_preExp, a_varDecls);
        l_arr__tp__str = expTypeFromExpArray(Tpl.emptyTxt, i_A);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arr__tp__str), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("identity_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arr__tp__str);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeText(a_preExp, l_var1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "rem"), expLst = {i_e1, i_e2}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e1, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e2, a_context, a_preExp, a_varDecls);
        l_typeStr = expTypeFromExpShort(Tpl.emptyTxt, i_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mod_"));
        txt = Tpl.writeText(txt, l_typeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_var1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_var2);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "String"), expLst = {i_s, i_format}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_string", a_varDecls);
        (l_sExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_s, a_context, a_preExp, a_varDecls);
        (l_formatExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_format, a_context, a_preExp, a_varDecls);
        l_typeStr = expTypeFromExpModelica(Tpl.emptyTxt, i_s);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_typeStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_to_modelica_string_format("));
        a_preExp = Tpl.writeText(a_preExp, l_sExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_formatExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "String"), expLst = {i_s, i_minlen, i_leftjust}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_string", a_varDecls);
        (l_sExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_s, a_context, a_preExp, a_varDecls);
        (l_minlenExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_minlen, a_context, a_preExp, a_varDecls);
        (l_leftjustExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_leftjust, a_context, a_preExp, a_varDecls);
        l_typeStr = expTypeFromExpModelica(Tpl.emptyTxt, i_s);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_typeStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_to_modelica_string("));
        a_preExp = Tpl.writeText(a_preExp, l_sExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_minlenExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_leftjustExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "String"), expLst = {i_s, i_minlen, i_leftjust, i_signdig}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_string", a_varDecls);
        (l_sExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_s, a_context, a_preExp, a_varDecls);
        (l_minlenExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_minlen, a_context, a_preExp, a_varDecls);
        (l_leftjustExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_leftjust, a_context, a_preExp, a_varDecls);
        (l_signdigExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_signdig, a_context, a_preExp, a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = modelica_real_to_modelica_string("));
        a_preExp = Tpl.writeText(a_preExp, l_sExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_minlenExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_leftjustExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_signdigExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "delay"), expLst = {DAE.ICONST(integer = i_index), i_e, i_d, i_delayMax}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_real", a_varDecls);
        (l_var1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        (l_var2, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_d, a_context, a_preExp, a_varDecls);
        (l_var3, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_delayMax, a_context, a_preExp, a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = delayImpl("));
        a_preExp = Tpl.writeStr(a_preExp, intString(i_index));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_var1);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", time, "));
        a_preExp = Tpl.writeText(a_preExp, l_var2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_var3);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "integer"), expLst = {i_toBeCasted}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_castedVar, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_toBeCasted, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_integer)"));
        txt = Tpl.writeText(txt, l_castedVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "mmc_get_field"), expLst = {i_s1, DAE.ICONST(integer = i_i)}),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        (l_expPart, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_s1, a_context, a_preExp, a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        a_preExp = Tpl.writeText(a_preExp, l_expPart);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("), "));
        a_preExp = Tpl.writeStr(a_preExp, intString(i_i));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("));"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, builtin = true, path = Absyn.IDENT(name = "mmc_unbox_record"), expLst = {i_s1}, ty = i_ty),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_argStr, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_s1, a_context, a_preExp, a_varDecls);
        (txt, a_preExp, a_varDecls) = unboxRecord(txt, Tpl.textString(l_argStr), i_ty, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(ty = DAE.ET_NORETCALL(), expLst = i_expLst, path = i_path, builtin = i_builtin),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_argStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_argStr, a_varDecls, a_preExp) = lm_598(l_argStr, i_expLst, a_varDecls, a_preExp, a_context);
        l_argStr = Tpl.popIter(l_argStr);
        l_funName = underscorePath(Tpl.emptyTxt, i_path);
        a_preExp = daeExpCallBuiltinPrefix(a_preExp, i_builtin);
        a_preExp = Tpl.writeText(a_preExp, l_funName);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeText(a_preExp, l_argStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("/* NORETCALL */"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = false, expLst = i_expLst, path = i_path, builtin = i_builtin),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_argStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_argStr, a_varDecls, a_preExp) = lm_599(l_argStr, i_expLst, a_varDecls, a_preExp, a_context);
        l_argStr = Tpl.popIter(l_argStr);
        l_funName = underscorePath(Tpl.emptyTxt, i_path);
        l_retType = Tpl.writeText(Tpl.emptyTxt, l_funName);
        l_retType = Tpl.writeTok(l_retType, Tpl.ST_STRING("_rettype"));
        (l_retVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_retType), a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_retVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = daeExpCallBuiltinPrefix(a_preExp, i_builtin);
        a_preExp = Tpl.writeText(a_preExp, l_funName);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeText(a_preExp, l_argStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = fun_600(txt, i_builtin, l_retType, l_retVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.CALL(tuple_ = true, expLst = i_expLst, path = i_path, builtin = i_builtin),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_argStr = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_argStr, a_varDecls, a_preExp) = lm_601(l_argStr, i_expLst, a_varDecls, a_preExp, a_context);
        l_argStr = Tpl.popIter(l_argStr);
        l_funName = underscorePath(Tpl.emptyTxt, i_path);
        l_retType = Tpl.writeText(Tpl.emptyTxt, l_funName);
        l_retType = Tpl.writeTok(l_retType, Tpl.ST_STRING("_rettype"));
        (l_retVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_retType), a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_retVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = daeExpCallBuiltinPrefix(a_preExp, i_builtin);
        a_preExp = Tpl.writeText(a_preExp, l_funName);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeText(a_preExp, l_argStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_retVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpCall;

public function daeExpCallBuiltinPrefix
  input Tpl.Text in_txt;
  input Boolean in_a_builtin;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_builtin)
    local
      Tpl.Text txt;

    case ( txt,
           true )
      then txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end daeExpCallBuiltinPrefix;

protected function fun_604
  input Tpl.Text in_txt;
  input Boolean in_a_scalar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_scalar)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("scalar_"));
      then txt;
  end matchcontinue;
end fun_604;

protected function fun_605
  input Tpl.Text in_txt;
  input Boolean in_a_scalar;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_scalar)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;
  end matchcontinue;
end fun_605;

protected function fun_606
  input Tpl.Text in_txt;
  input Boolean in_a_scalar;
  input DAE.Exp in_a_e;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_scalar, in_a_e)
    local
      Tpl.Text txt;
      DAE.Exp a_e;

    case ( txt,
           false,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;

    case ( txt,
           _,
           a_e )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = expTypeFromExpModelica(txt, a_e);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;
  end matchcontinue;
end fun_606;

protected function lm_607
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;
  input Boolean in_a_scalar;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context, in_a_scalar)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      Boolean a_scalar;
      DAE.Exp i_e;
      Tpl.Text l_prefix;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_e :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_scalar )
      equation
        l_prefix = fun_606(Tpl.emptyTxt, a_scalar, i_e);
        txt = Tpl.writeText(txt, l_prefix);
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_e, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_607(txt, rest, a_varDecls, a_preExp, a_context, a_scalar);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context,
           a_scalar )
      equation
        (txt, a_varDecls, a_preExp) = lm_607(txt, rest, a_varDecls, a_preExp, a_context, a_scalar);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_607;

public function daeExpArray
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<DAE.Exp> i_array;
      Boolean i_scalar;
      DAE.ExpType i_ty;
      Integer ret_5;
      Tpl.Text l_params;
      Tpl.Text l_scalarRef;
      Tpl.Text l_scalarPrefix;
      Tpl.Text l_arrayVar;
      Tpl.Text l_arrayTypeStr;

    case ( txt,
           DAE.ARRAY(ty = i_ty, scalar = i_scalar, array = i_array),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_arrayTypeStr = expTypeArray(Tpl.emptyTxt, i_ty);
        (l_arrayVar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arrayTypeStr), a_varDecls);
        l_scalarPrefix = fun_604(Tpl.emptyTxt, i_scalar);
        l_scalarRef = fun_605(Tpl.emptyTxt, i_scalar);
        l_params = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_params, a_varDecls, a_preExp) = lm_607(l_params, i_array, a_varDecls, a_preExp, a_context, i_scalar);
        l_params = Tpl.popIter(l_params);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("array_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_scalarPrefix);
        a_preExp = Tpl.writeText(a_preExp, l_arrayTypeStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_arrayVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        ret_5 = listLength(i_array);
        a_preExp = Tpl.writeStr(a_preExp, intString(ret_5));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_params);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_arrayVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpArray;

protected function lm_609
  input Tpl.Text in_txt;
  input list<list<tuple<DAE.Exp, Boolean>>> in_items;
  input Tpl.Text in_a_vars2;
  input Tpl.Text in_a_promote;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_arrayTypeStr;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_vars2;
  output Tpl.Text out_a_promote;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_vars2, out_a_promote, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_vars2, in_a_promote, in_a_context, in_a_varDecls, in_a_arrayTypeStr)
    local
      Tpl.Text txt;
      list<list<tuple<DAE.Exp, Boolean>>> rest;
      Tpl.Text a_vars2;
      Tpl.Text a_promote;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      Tpl.Text a_arrayTypeStr;
      list<tuple<DAE.Exp, Boolean>> i_row;
      Integer ret_2;
      Tpl.Text l_vars;
      Tpl.Text l_tmp;

    case ( txt,
           {},
           a_vars2,
           a_promote,
           _,
           a_varDecls,
           _ )
      then (txt, a_vars2, a_promote, a_varDecls);

    case ( txt,
           i_row :: rest,
           a_vars2,
           a_promote,
           a_context,
           a_varDecls,
           a_arrayTypeStr )
      equation
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(a_arrayTypeStr), a_varDecls);
        (l_vars, a_promote, a_varDecls) = daeExpMatrixRow(Tpl.emptyTxt, i_row, Tpl.textString(a_arrayTypeStr), a_context, a_promote, a_varDecls);
        a_vars2 = Tpl.writeTok(a_vars2, Tpl.ST_STRING(", &"));
        a_vars2 = Tpl.writeText(a_vars2, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("cat_alloc_"));
        txt = Tpl.writeText(txt, a_arrayTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(2, &"));
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = listLength(i_row);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeText(txt, l_vars);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, a_vars2, a_promote, a_varDecls) = lm_609(txt, rest, a_vars2, a_promote, a_context, a_varDecls, a_arrayTypeStr);
      then (txt, a_vars2, a_promote, a_varDecls);

    case ( txt,
           _ :: rest,
           a_vars2,
           a_promote,
           a_context,
           a_varDecls,
           a_arrayTypeStr )
      equation
        (txt, a_vars2, a_promote, a_varDecls) = lm_609(txt, rest, a_vars2, a_promote, a_context, a_varDecls, a_arrayTypeStr);
      then (txt, a_vars2, a_promote, a_varDecls);
  end matchcontinue;
end lm_609;

public function daeExpMatrix
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<list<tuple<DAE.Exp, Boolean>>> i_m_scalar;
      DAE.ExpType i_m_ty;
      DAE.ExpType i_ty;
      Integer ret_5;
      Tpl.Text l_catAlloc;
      Tpl.Text l_promote;
      Tpl.Text l_vars2;
      Tpl.Text l_tmp;
      Tpl.Text l_arrayTypeStr;

    case ( txt,
           DAE.MATRIX(scalar = {{}}, ty = i_ty),
           _,
           a_preExp,
           a_varDecls )
      equation
        l_arrayTypeStr = expTypeArray(Tpl.emptyTxt, i_ty);
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arrayTypeStr), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arrayTypeStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", 2, 0, 1);"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MATRIX(scalar = {}, ty = i_ty),
           _,
           a_preExp,
           a_varDecls )
      equation
        l_arrayTypeStr = expTypeArray(Tpl.emptyTxt, i_ty);
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arrayTypeStr), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arrayTypeStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", 2, 0, 1);"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.MATRIX(ty = i_m_ty, scalar = i_m_scalar),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_arrayTypeStr = expTypeArray(Tpl.emptyTxt, i_m_ty);
        l_vars2 = Tpl.emptyTxt;
        l_promote = Tpl.emptyTxt;
        l_catAlloc = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_catAlloc, l_vars2, l_promote, a_varDecls) = lm_609(l_catAlloc, i_m_scalar, l_vars2, l_promote, a_context, a_varDecls, l_arrayTypeStr);
        l_catAlloc = Tpl.popIter(l_catAlloc);
        a_preExp = Tpl.writeText(a_preExp, l_promote);
        a_preExp = Tpl.writeText(a_preExp, l_catAlloc);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arrayTypeStr), a_varDecls);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("cat_alloc_"));
        a_preExp = Tpl.writeText(a_preExp, l_arrayTypeStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(1, &"));
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        ret_5 = listLength(i_m_scalar);
        a_preExp = Tpl.writeStr(a_preExp, intString(ret_5));
        a_preExp = Tpl.writeText(a_preExp, l_vars2);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpMatrix;

protected function fun_611
  input Tpl.Text in_txt;
  input Boolean in_a_b;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_b)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("scalar_"));
      then txt;
  end matchcontinue;
end fun_611;

protected function fun_612
  input Tpl.Text in_txt;
  input Boolean in_a_b;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_b)
    local
      Tpl.Text txt;

    case ( txt,
           false )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("&"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_612;

protected function lm_613
  input Tpl.Text in_txt;
  input list<tuple<DAE.Exp, Boolean>> in_items;
  input Tpl.Text in_a_varLstStr;
  input String in_a_arrayTypeStr;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varLstStr;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varLstStr, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varLstStr, in_a_arrayTypeStr, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<tuple<DAE.Exp, Boolean>> rest;
      Tpl.Text a_varLstStr;
      String a_arrayTypeStr;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_e;
      Boolean i_b;
      Tpl.Text l_tmp;
      Tpl.Text l_expVar;
      Tpl.Text l_scalarRefStr;
      Tpl.Text l_scalarStr;

    case ( txt,
           {},
           a_varLstStr,
           _,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varLstStr, a_varDecls, a_preExp);

    case ( txt,
           (i_e, i_b) :: rest,
           a_varLstStr,
           a_arrayTypeStr,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        l_scalarStr = fun_611(Tpl.emptyTxt, i_b);
        l_scalarRefStr = fun_612(Tpl.emptyTxt, i_b);
        (l_expVar, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, a_arrayTypeStr, a_varDecls);
        a_varLstStr = Tpl.writeTok(a_varLstStr, Tpl.ST_STRING(", &"));
        a_varLstStr = Tpl.writeText(a_varLstStr, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("promote_"));
        txt = Tpl.writeText(txt, l_scalarStr);
        txt = Tpl.writeStr(txt, a_arrayTypeStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, l_scalarRefStr);
        txt = Tpl.writeText(txt, l_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", 2, &"));
        txt = Tpl.writeText(txt, l_tmp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(");"));
        txt = Tpl.nextIter(txt);
        (txt, a_varLstStr, a_varDecls, a_preExp) = lm_613(txt, rest, a_varLstStr, a_arrayTypeStr, a_varDecls, a_preExp, a_context);
      then (txt, a_varLstStr, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varLstStr,
           a_arrayTypeStr,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varLstStr, a_varDecls, a_preExp) = lm_613(txt, rest, a_varLstStr, a_arrayTypeStr, a_varDecls, a_preExp, a_context);
      then (txt, a_varLstStr, a_varDecls, a_preExp);
  end matchcontinue;
end lm_613;

public function daeExpMatrixRow
  input Tpl.Text txt;
  input list<tuple<DAE.Exp, Boolean>> a_row;
  input String a_arrayTypeStr;
  input SimCode.Context a_context;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_preExp2;
  Tpl.Text l_varLstStr;
algorithm
  l_varLstStr := Tpl.emptyTxt;
  l_preExp2 := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_preExp2, l_varLstStr, out_a_varDecls, out_a_preExp) := lm_613(l_preExp2, a_row, l_varLstStr, a_arrayTypeStr, a_varDecls, a_preExp, a_context);
  l_preExp2 := Tpl.popIter(l_preExp2);
  l_preExp2 := Tpl.writeTok(l_preExp2, Tpl.ST_NEW_LINE());
  out_a_preExp := Tpl.writeText(out_a_preExp, l_preExp2);
  out_txt := Tpl.writeText(txt, l_varLstStr);
end daeExpMatrixRow;

protected function fun_615
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;
  input Tpl.Text in_a_preExp;
  input DAE.Exp in_a_exp;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_expVar;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_ty, in_a_preExp, in_a_exp, in_a_varDecls, in_a_expVar)
    local
      Tpl.Text txt;
      Tpl.Text a_preExp;
      DAE.Exp a_exp;
      Tpl.Text a_varDecls;
      Tpl.Text a_expVar;
      DAE.ExpType i_ty;
      Tpl.Text l_from;
      Tpl.Text l_to;
      Tpl.Text l_tvar;
      Tpl.Text l_arrayTypeStr;

    case ( txt,
           DAE.ET_INT(),
           a_preExp,
           _,
           a_varDecls,
           a_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_integer)"));
        txt = Tpl.writeText(txt, a_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           a_preExp,
           _,
           a_varDecls,
           a_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_real)"));
        txt = Tpl.writeText(txt, a_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_ENUMERATION(path = _),
           a_preExp,
           _,
           a_varDecls,
           a_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_integer)"));
        txt = Tpl.writeText(txt, a_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_BOOL(),
           a_preExp,
           _,
           a_varDecls,
           a_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("((modelica_boolean)"));
        txt = Tpl.writeText(txt, a_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty),
           a_preExp,
           a_exp,
           a_varDecls,
           a_expVar )
      equation
        l_arrayTypeStr = expTypeArray(Tpl.emptyTxt, i_ty);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_arrayTypeStr), a_varDecls);
        l_to = expTypeShort(Tpl.emptyTxt, i_ty);
        l_from = expTypeFromExpShort(Tpl.emptyTxt, a_exp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("cast_"));
        a_preExp = Tpl.writeText(a_preExp, l_from);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("_array_to_"));
        a_preExp = Tpl.writeText(a_preExp, l_to);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("(&"));
        a_preExp = Tpl.writeText(a_preExp, a_expVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", &"));
        a_preExp = Tpl.writeText(a_preExp, l_tvar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tvar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_preExp,
           _,
           a_varDecls,
           a_expVar )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeText(txt, a_expVar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") /* could not cast, using the variable as it is */"));
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_615;

public function daeExpCast
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType i_ty;
      DAE.Exp i_exp;
      Tpl.Text l_expVar;

    case ( txt,
           DAE.CAST(exp = i_exp, ty = i_ty),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_expVar, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        (txt, a_preExp, a_varDecls) = fun_615(txt, i_ty, a_preExp, i_exp, a_varDecls, l_expVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpCast;

protected function fun_617
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_exp, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_idx;
      DAE.Exp i_e;
      Tpl.Text l_idx1;
      Tpl.Text l_e1;

    case ( txt,
           DAE.ASUB(exp = i_e, sub = {i_idx}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        (l_idx1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_idx, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("arrayGet("));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, l_idx1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_617;

protected function fun_618
  input Tpl.Text in_txt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input list<DAE.Exp> in_a_subs;
  input DAE.ExpType in_a_ecr_ty;
  input Tpl.Text in_a_arrName;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_context, in_a_varDecls, in_a_preExp, in_a_subs, in_a_ecr_ty, in_a_arrName)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      list<DAE.Exp> a_subs;
      DAE.ExpType a_ecr_ty;
      Tpl.Text a_arrName;
      SimCode.Context i_context;

    case ( txt,
           SimCode.FUNCTION_CONTEXT(),
           a_varDecls,
           a_preExp,
           _,
           _,
           a_arrName )
      equation
        txt = Tpl.writeText(txt, a_arrName);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_context,
           a_varDecls,
           a_preExp,
           a_subs,
           a_ecr_ty,
           a_arrName )
      equation
        (txt, a_preExp, a_varDecls) = arrayScalarRhs(txt, a_ecr_ty, a_subs, Tpl.textString(a_arrName), i_context, a_preExp, a_varDecls);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_618;

protected function lm_619
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_index;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_index :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_index, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_619(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_619(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_619;

protected function fun_620
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_exp, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      list<DAE.Exp> i_indexes;
      DAE.Exp i_index;
      DAE.ExpType i_ecr_ty;
      list<DAE.Exp> i_subs;
      DAE.Exp i_ecr;
      Integer i_l;
      Integer i_k;
      Integer i_j;
      Integer i_i;
      DAE.Exp i_e;
      Tpl.Text l_expIndexes;
      Tpl.Text l_expIndex;
      Tpl.Text l_exp;
      Integer ret_23;
      Integer ret_22;
      Integer ret_21;
      Integer ret_20;
      Integer ret_19;
      Integer ret_18;
      Integer ret_17;
      Integer ret_16;
      Integer ret_15;
      Integer ret_14;
      DAE.Exp ret_13;
      Tpl.Text l_arrName;
      Integer ret_11;
      Integer ret_10;
      Integer ret_9;
      Integer ret_8;
      Integer ret_7;
      Integer ret_6;
      Integer ret_5;
      Integer ret_4;
      Integer ret_3;
      Integer ret_2;
      Tpl.Text l_typeShort;
      Tpl.Text l_e1;

    case ( txt,
           DAE.ASUB(exp = DAE.RANGE(ty = _), sub = {_}),
           a_varDecls,
           a_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ASUB_EASY_CASE"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}), sub = {DAE.ICONST(integer = i_k)}), sub = {DAE.ICONST(integer = i_l)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_4D(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_2 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_2));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_3 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_3));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_4 = SimCode.incrementInt(i_k, -1);
        txt = Tpl.writeStr(txt, intString(ret_4));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_5 = SimCode.incrementInt(i_l, -1);
        txt = Tpl.writeStr(txt, intString(ret_5));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}), sub = {DAE.ICONST(integer = i_k)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_3D(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_6 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_6));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_7 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_7));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_8 = SimCode.incrementInt(i_k, -1);
        txt = Tpl.writeStr(txt, intString(ret_8));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}), sub = {DAE.ICONST(integer = i_j)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_2D(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_9 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_9));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_10 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_10));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = i_e, sub = {DAE.ICONST(integer = i_i)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_11 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_11));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = (i_ecr as DAE.CREF(ty = i_ecr_ty)), sub = i_subs),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        ret_13 = SimCode.buildCrefExpFromAsub(i_ecr, i_subs);
        (l_arrName, a_preExp, a_varDecls) = daeExpCrefRhs(Tpl.emptyTxt, ret_13, a_context, a_preExp, a_varDecls);
        (txt, a_varDecls, a_preExp) = fun_618(txt, a_context, a_varDecls, a_preExp, i_subs, i_ecr_ty, l_arrName);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ENUM_LITERAL(index = i_i)}), sub = {DAE.ENUM_LITERAL(index = i_j)}), sub = {DAE.ENUM_LITERAL(index = i_k)}), sub = {DAE.ENUM_LITERAL(index = i_l)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_4D(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_14 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_14));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_15 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_15));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_16 = SimCode.incrementInt(i_k, -1);
        txt = Tpl.writeStr(txt, intString(ret_16));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_17 = SimCode.incrementInt(i_l, -1);
        txt = Tpl.writeStr(txt, intString(ret_17));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ENUM_LITERAL(index = i_i)}), sub = {DAE.ENUM_LITERAL(index = i_j)}), sub = {DAE.ENUM_LITERAL(index = i_k)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_3D(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_18 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_18));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_19 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_19));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_20 = SimCode.incrementInt(i_k, -1);
        txt = Tpl.writeStr(txt, intString(ret_20));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = DAE.ASUB(exp = i_e, sub = {DAE.ENUM_LITERAL(index = i_i)}), sub = {DAE.ENUM_LITERAL(index = i_j)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get_2D(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_21 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_21));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_22 = SimCode.incrementInt(i_j, -1);
        txt = Tpl.writeStr(txt, intString(ret_22));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = i_e, sub = {DAE.ENUM_LITERAL(index = i_i)}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_e1, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get(&"));
        txt = Tpl.writeText(txt, l_e1);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        ret_23 = SimCode.incrementInt(i_i, -1);
        txt = Tpl.writeStr(txt, intString(ret_23));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = i_e, sub = {i_index}),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_exp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        (l_expIndex, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_index, a_context, a_preExp, a_varDecls);
        l_typeShort = expTypeFromExpShort(Tpl.emptyTxt, i_e);
        txt = Tpl.writeText(txt, l_typeShort);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_get(&"));
        txt = Tpl.writeText(txt, l_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", (("));
        txt = Tpl.writeText(txt, l_expIndex);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") - 1))"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.ASUB(exp = i_e, sub = i_indexes),
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (l_exp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        l_expIndexes = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_expIndexes, a_varDecls, a_preExp) = lm_619(l_expIndexes, i_indexes, a_varDecls, a_preExp, a_context);
        l_expIndexes = Tpl.popIter(l_expIndexes);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("CODEGEN_COULD_NOT_HANDLE_ASUB("));
        txt = Tpl.writeText(txt, l_exp);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("["));
        txt = Tpl.writeText(txt, l_expIndexes);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("])"));
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _,
           a_varDecls,
           a_preExp,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("OTHER_ASUB"));
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_620;

protected function fun_621
  input Tpl.Text in_txt;
  input String in_mArg;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_mArg, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      DAE.Exp a_exp;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;

    case ( txt,
           "metatype",
           a_exp,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_varDecls, a_preExp) = fun_617(txt, a_exp, a_varDecls, a_preExp, a_context);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_exp,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (txt, a_varDecls, a_preExp) = fun_620(txt, a_exp, a_varDecls, a_preExp, a_context);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_621;

public function daeExpAsub
  input Tpl.Text txt;
  input DAE.Exp a_exp;
  input SimCode.Context a_context;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
protected
  String str_1;
  Tpl.Text txt_0;
algorithm
  txt_0 := expTypeFromExpShort(Tpl.emptyTxt, a_exp);
  str_1 := Tpl.textString(txt_0);
  (out_txt, out_a_preExp, out_a_varDecls) := fun_621(txt, str_1, a_exp, a_context, a_preExp, a_varDecls);
end daeExpAsub;

public function daeExpSize
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.ExpType i_exp_ty;
      DAE.Exp i_dim;
      DAE.Exp i_exp;
      Tpl.Text l_typeStr;
      Tpl.Text l_resVar;
      Tpl.Text l_dimPart;
      Tpl.Text l_expPart;

    case ( txt,
           DAE.SIZE(exp = (i_exp as DAE.CREF(ty = i_exp_ty)), sz = SOME(i_dim)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_expPart, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_exp, a_context, a_preExp, a_varDecls);
        (l_dimPart, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_dim, a_context, a_preExp, a_varDecls);
        (l_resVar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_integer", a_varDecls);
        l_typeStr = expTypeArray(Tpl.emptyTxt, i_exp_ty);
        a_preExp = Tpl.writeText(a_preExp, l_resVar);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = size_of_dimension_"));
        a_preExp = Tpl.writeText(a_preExp, l_typeStr);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("("));
        a_preExp = Tpl.writeText(a_preExp, l_expPart);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_dimPart);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_resVar);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("size(X) not implemented"));
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpSize;

protected function fun_624
  input Tpl.Text in_txt;
  input String in_mArg;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg)
    local
      Tpl.Text txt;

    case ( txt,
           "max" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_real)"));
      then txt;

    case ( txt,
           "min" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(modelica_real)"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_624;

public function daeExpReduction
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_exp;
      Absyn.Ident i_op;
      DAE.Exp i_expr;
      Tpl.Text l_body;
      String str_7;
      Tpl.Text l_cast;
      Tpl.Text l_tmpExpVar;
      Tpl.Text l_tmpExpPre;
      Tpl.Text l_res;
      Tpl.Text l_startValue;
      Tpl.Text l_accFun;
      Tpl.Text l_identType;

    case ( txt,
           (i_exp as DAE.REDUCTION(path = Absyn.IDENT(name = i_op), expr = i_expr)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_identType = expTypeFromExpModelica(Tpl.emptyTxt, i_expr);
        l_accFun = daeExpReductionFnName(Tpl.emptyTxt, i_op, Tpl.textString(l_identType));
        l_startValue = daeExpReductionStartValue(Tpl.emptyTxt, i_op, Tpl.textString(l_identType));
        (l_res, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(l_identType), a_varDecls);
        l_tmpExpPre = Tpl.emptyTxt;
        (l_tmpExpVar, l_tmpExpPre, a_varDecls) = daeExp(Tpl.emptyTxt, i_expr, a_context, l_tmpExpPre, a_varDecls);
        str_7 = Tpl.textString(l_accFun);
        l_cast = fun_624(Tpl.emptyTxt, str_7);
        l_body = Tpl.writeText(Tpl.emptyTxt, l_tmpExpPre);
        l_body = Tpl.softNewLine(l_body);
        l_body = Tpl.writeText(l_body, l_res);
        l_body = Tpl.writeTok(l_body, Tpl.ST_STRING(" = "));
        l_body = Tpl.writeText(l_body, l_accFun);
        l_body = Tpl.writeTok(l_body, Tpl.ST_STRING("("));
        l_body = Tpl.writeText(l_body, l_cast);
        l_body = Tpl.writeTok(l_body, Tpl.ST_STRING("("));
        l_body = Tpl.writeText(l_body, l_res);
        l_body = Tpl.writeTok(l_body, Tpl.ST_STRING("), "));
        l_body = Tpl.writeText(l_body, l_cast);
        l_body = Tpl.writeTok(l_body, Tpl.ST_STRING("("));
        l_body = Tpl.writeText(l_body, l_tmpExpVar);
        l_body = Tpl.writeTok(l_body, Tpl.ST_STRING("));"));
        a_preExp = Tpl.writeText(a_preExp, l_res);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_startValue);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE(";\n"));
        (a_preExp, l_body, a_varDecls) = daeExpReductionLoop(a_preExp, i_exp, l_body, a_context, a_varDecls);
        txt = Tpl.writeText(txt, l_res);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpReduction;

public function daeExpReductionLoop
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input Tpl.Text in_a_body;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_body;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_body, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_body, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_body;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Ident i_ident;
      DAE.Exp i_range;
      DAE.Exp i_expr;
      DAE.ExpType i_range_ty;
      Tpl.Text l_arrayType;
      Tpl.Text l_identTypeShort;
      Tpl.Text l_identType;

    case ( txt,
           DAE.REDUCTION(range = (i_range as DAE.RANGE(ty = i_range_ty)), expr = i_expr, ident = i_ident),
           a_body,
           a_context,
           a_varDecls )
      equation
        l_identType = expTypeModelica(Tpl.emptyTxt, i_range_ty);
        l_identTypeShort = expTypeFromExpShort(Tpl.emptyTxt, i_expr);
        (txt, a_body, a_varDecls) = algStmtForRange_impl(txt, i_range, i_ident, Tpl.textString(l_identType), Tpl.textString(l_identTypeShort), a_body, a_context, a_varDecls);
      then (txt, a_body, a_varDecls);

    case ( txt,
           DAE.REDUCTION(range = i_range, expr = i_expr, ident = i_ident),
           a_body,
           a_context,
           a_varDecls )
      equation
        l_identType = expTypeFromExpModelica(Tpl.emptyTxt, i_expr);
        l_arrayType = expTypeFromExpArray(Tpl.emptyTxt, i_expr);
        (txt, a_body, a_varDecls) = algStmtForGeneric_impl(txt, i_range, i_ident, Tpl.textString(l_identType), Tpl.textString(l_arrayType), false, a_body, a_context, a_varDecls);
      then (txt, a_body, a_varDecls);

    case ( txt,
           _,
           a_body,
           _,
           a_varDecls )
      then (txt, a_body, a_varDecls);
  end matchcontinue;
end daeExpReductionLoop;

protected function fun_627
  input Tpl.Text in_txt;
  input String in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("intAdd"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("realAdd"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_627;

protected function fun_628
  input Tpl.Text in_txt;
  input String in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("intMul"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("realMul"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_628;

public function daeExpReductionFnName
  input Tpl.Text in_txt;
  input String in_a_reduction__op;
  input String in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_reduction__op, in_a_type)
    local
      Tpl.Text txt;
      String a_type;
      String i_reduction__op;

    case ( txt,
           "sum",
           a_type )
      equation
        txt = fun_627(txt, a_type);
      then txt;

    case ( txt,
           "product",
           a_type )
      equation
        txt = fun_628(txt, a_type);
      then txt;

    case ( txt,
           i_reduction__op,
           _ )
      equation
        txt = Tpl.writeStr(txt, i_reduction__op);
      then txt;
  end matchcontinue;
end daeExpReductionFnName;

protected function fun_630
  input Tpl.Text in_txt;
  input String in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1073741823"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1.e60"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_630;

protected function fun_631
  input Tpl.Text in_txt;
  input String in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           "modelica_integer" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-1073741823"));
      then txt;

    case ( txt,
           "modelica_real" )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("-1.e60"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_TYPE"));
      then txt;
  end matchcontinue;
end fun_631;

public function daeExpReductionStartValue
  input Tpl.Text in_txt;
  input String in_a_reduction__op;
  input String in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_reduction__op, in_a_type)
    local
      Tpl.Text txt;
      String a_type;

    case ( txt,
           "min",
           a_type )
      equation
        txt = fun_630(txt, a_type);
      then txt;

    case ( txt,
           "max",
           a_type )
      equation
        txt = fun_631(txt, a_type);
      then txt;

    case ( txt,
           "sum",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("0"));
      then txt;

    case ( txt,
           "product",
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("1"));
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_REDUCTION"));
      then txt;
  end matchcontinue;
end daeExpReductionStartValue;

protected function fun_633
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_et;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_et, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      DAE.ExpType i_et;
      Tpl.Text txt_0;

    case ( txt,
           DAE.ET_NORETCALL(),
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("ERROR_MATCH_EXPRESSION_NORETCALL"));
      then (txt, a_varDecls);

    case ( txt,
           i_et,
           a_varDecls )
      equation
        txt_0 = expTypeModelica(Tpl.emptyTxt, i_et);
        (txt, a_varDecls) = tempDecl(txt, Tpl.textString(txt_0), a_varDecls);
      then (txt, a_varDecls);
  end matchcontinue;
end fun_633;

public function daeExpMatch
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_exp;
      DAE.ExpType i_et;
      Tpl.Text l_res;

    case ( txt,
           (i_exp as DAE.MATCHEXPRESSION(et = i_et)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_res, a_varDecls) = fun_633(Tpl.emptyTxt, i_et, a_varDecls);
        (txt, l_res, a_preExp, a_varDecls) = daeExpMatch2(txt, i_exp, l_res, a_context, a_preExp, a_varDecls);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpMatch;

protected function lm_635
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_preExpInner;
  input Tpl.Text in_a_varDeclsInner;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExpInner;
  output Tpl.Text out_a_varDeclsInner;
algorithm
  (out_txt, out_a_preExpInner, out_a_varDeclsInner) :=
  matchcontinue(in_txt, in_items, in_a_preExpInner, in_a_varDeclsInner)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_preExpInner;
      Tpl.Text a_varDeclsInner;
      SimCode.Variable i_var;

    case ( txt,
           {},
           a_preExpInner,
           a_varDeclsInner )
      then (txt, a_preExpInner, a_varDeclsInner);

    case ( txt,
           i_var :: rest,
           a_preExpInner,
           a_varDeclsInner )
      equation
        (txt, a_varDeclsInner, a_preExpInner) = varInit(txt, i_var, "", 0, a_varDeclsInner, a_preExpInner);
        (txt, a_preExpInner, a_varDeclsInner) = lm_635(txt, rest, a_preExpInner, a_varDeclsInner);
      then (txt, a_preExpInner, a_varDeclsInner);

    case ( txt,
           _ :: rest,
           a_preExpInner,
           a_varDeclsInner )
      equation
        (txt, a_preExpInner, a_varDeclsInner) = lm_635(txt, rest, a_preExpInner, a_varDeclsInner);
      then (txt, a_preExpInner, a_varDeclsInner);
  end matchcontinue;
end lm_635;

protected function lm_636
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_preExpInput;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_expInput;
  input Tpl.Text in_a_varDeclsInput;
  input Tpl.Text in_a_prefix;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExpInput;
  output Tpl.Text out_a_expInput;
  output Tpl.Text out_a_varDeclsInput;
algorithm
  (out_txt, out_a_preExpInput, out_a_expInput, out_a_varDeclsInput) :=
  matchcontinue(in_txt, in_items, in_a_preExpInput, in_a_context, in_a_expInput, in_a_varDeclsInput, in_a_prefix)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_preExpInput;
      SimCode.Context a_context;
      Tpl.Text a_expInput;
      Tpl.Text a_varDeclsInput;
      Tpl.Text a_prefix;
      Integer x_i0;
      DAE.Exp i_exp;
      Tpl.Text l_decl;

    case ( txt,
           {},
           a_preExpInput,
           _,
           a_expInput,
           a_varDeclsInput,
           _ )
      then (txt, a_preExpInput, a_expInput, a_varDeclsInput);

    case ( txt,
           i_exp :: rest,
           a_preExpInput,
           a_context,
           a_expInput,
           a_varDeclsInput,
           a_prefix )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        l_decl = Tpl.writeText(Tpl.emptyTxt, a_prefix);
        l_decl = Tpl.writeTok(l_decl, Tpl.ST_STRING("_in"));
        l_decl = Tpl.writeStr(l_decl, intString(x_i0));
        a_varDeclsInput = expTypeFromExpModelica(a_varDeclsInput, i_exp);
        a_varDeclsInput = Tpl.writeTok(a_varDeclsInput, Tpl.ST_STRING(" "));
        a_varDeclsInput = Tpl.writeText(a_varDeclsInput, l_decl);
        a_varDeclsInput = Tpl.writeTok(a_varDeclsInput, Tpl.ST_STRING(";"));
        a_varDeclsInput = Tpl.writeTok(a_varDeclsInput, Tpl.ST_NEW_LINE());
        a_expInput = Tpl.writeText(a_expInput, l_decl);
        a_expInput = Tpl.writeTok(a_expInput, Tpl.ST_STRING(" = "));
        (a_expInput, a_preExpInput, a_varDeclsInput) = daeExp(a_expInput, i_exp, a_context, a_preExpInput, a_varDeclsInput);
        a_expInput = Tpl.writeTok(a_expInput, Tpl.ST_STRING(";"));
        a_expInput = Tpl.writeTok(a_expInput, Tpl.ST_NEW_LINE());
        txt = Tpl.nextIter(txt);
        (txt, a_preExpInput, a_expInput, a_varDeclsInput) = lm_636(txt, rest, a_preExpInput, a_context, a_expInput, a_varDeclsInput, a_prefix);
      then (txt, a_preExpInput, a_expInput, a_varDeclsInput);

    case ( txt,
           _ :: rest,
           a_preExpInput,
           a_context,
           a_expInput,
           a_varDeclsInput,
           a_prefix )
      equation
        (txt, a_preExpInput, a_expInput, a_varDeclsInput) = lm_636(txt, rest, a_preExpInput, a_context, a_expInput, a_varDeclsInput, a_prefix);
      then (txt, a_preExpInput, a_expInput, a_varDeclsInput);
  end matchcontinue;
end lm_636;

protected function fun_637
  input Tpl.Text in_txt;
  input Absyn.MatchType in_a_exp_matchType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_exp_matchType)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.MATCHCONTINUE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MMC_THROW()"));
      then txt;

    case ( txt,
           Absyn.MATCH() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("break"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_637;

protected function fun_638
  input Tpl.Text in_txt;
  input Absyn.MatchType in_a_exp_matchType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_exp_matchType)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.MATCHCONTINUE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("matchcontinue expression"));
      then txt;

    case ( txt,
           Absyn.MATCH() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("match expression"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_638;

protected function fun_639
  input Tpl.Text in_txt;
  input Absyn.MatchType in_a_exp_matchType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_exp_matchType)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.MATCHCONTINUE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MMC_TRY()"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_639;

protected function fun_640
  input Tpl.Text in_txt;
  input Absyn.MatchType in_a_exp_matchType;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_exp_matchType)
    local
      Tpl.Text txt;

    case ( txt,
           Absyn.MATCHCONTINUE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MMC_CATCH()"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end fun_640;

public function daeExpMatch2
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input Tpl.Text in_a_res;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_res;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_res, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_res, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_res;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<DAE.MatchCase> i_cases;
      Absyn.MatchType i_exp_matchType;
      list<DAE.Exp> i_inputs;
      list<DAE.Element> i_localDecls;
      Integer ret_15;
      Tpl.Text l_onPatternFail;
      Tpl.Text l_done;
      Tpl.Text l_ix;
      Tpl.Text l_ignore3;
      Tpl.Text l_expInput;
      Tpl.Text l_preExpInput;
      Integer ret_8;
      Tpl.Text l_prefix;
      list<SimCode.Variable> ret_6;
      Tpl.Text l_ignore2;
      Tpl.Text l_ignore;
      Tpl.Text l_varDeclsInner;
      Tpl.Text l_varDeclsInput;
      Tpl.Text l_preExpRes;
      Tpl.Text l_preExpInner;

    case ( txt,
           DAE.MATCHEXPRESSION(localDecls = i_localDecls, inputs = i_inputs, matchType = i_exp_matchType, cases = i_cases),
           a_res,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        l_preExpInner = Tpl.emptyTxt;
        l_preExpRes = Tpl.emptyTxt;
        l_varDeclsInput = Tpl.emptyTxt;
        l_varDeclsInner = Tpl.emptyTxt;
        l_ignore = Tpl.emptyTxt;
        ret_6 = SimCode.elementVars(i_localDecls);
        (l_ignore2, l_preExpInner, l_varDeclsInner) = lm_635(Tpl.emptyTxt, ret_6, l_preExpInner, l_varDeclsInner);
        l_prefix = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("tmp"));
        ret_8 = System.tmpTick();
        l_prefix = Tpl.writeStr(l_prefix, intString(ret_8));
        l_preExpInput = Tpl.emptyTxt;
        l_expInput = Tpl.emptyTxt;
        l_ignore3 = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, SOME(Tpl.ST_STRING("")), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_ignore3, l_preExpInput, l_expInput, l_varDeclsInput) = lm_636(l_ignore3, i_inputs, l_preExpInput, a_context, l_expInput, l_varDeclsInput, l_prefix);
        l_ignore3 = Tpl.popIter(l_ignore3);
        (l_ix, l_varDeclsInner) = tempDecl(Tpl.emptyTxt, "int", l_varDeclsInner);
        (l_done, l_varDeclsInner) = tempDecl(Tpl.emptyTxt, "int", l_varDeclsInner);
        l_onPatternFail = fun_637(Tpl.emptyTxt, i_exp_matchType);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("{ /* "));
        a_preExp = fun_638(a_preExp, i_exp_matchType);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE(" */\n"));
        a_preExp = Tpl.pushBlock(a_preExp, Tpl.BT_INDENT(2));
        a_preExp = Tpl.writeText(a_preExp, l_varDeclsInput);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeText(a_preExp, l_preExpInput);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeText(a_preExp, l_expInput);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE("{\n"));
        a_preExp = Tpl.pushBlock(a_preExp, Tpl.BT_INDENT(2));
        a_preExp = Tpl.writeText(a_preExp, l_varDeclsInner);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeText(a_preExp, l_preExpInner);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("for ("));
        a_preExp = Tpl.writeText(a_preExp, l_ix);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = 0, "));
        a_preExp = Tpl.writeText(a_preExp, l_done);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = 0; "));
        a_preExp = Tpl.writeText(a_preExp, l_ix);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" < "));
        ret_15 = listLength(i_cases);
        a_preExp = Tpl.writeStr(a_preExp, intString(ret_15));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" && !"));
        a_preExp = Tpl.writeText(a_preExp, l_done);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("; "));
        a_preExp = Tpl.writeText(a_preExp, l_ix);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE("++) {\n"));
        a_preExp = Tpl.pushBlock(a_preExp, Tpl.BT_INDENT(2));
        a_preExp = fun_639(a_preExp, i_exp_matchType);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("switch ("));
        a_preExp = Tpl.writeText(a_preExp, l_ix);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE(") {\n"));
        (a_preExp, a_res, l_prefix, l_onPatternFail, l_done, a_varDecls) = daeExpMatchCases(a_preExp, i_cases, a_res, l_prefix, l_onPatternFail, l_done, a_context, a_varDecls);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE("}\n"));
        a_preExp = fun_640(a_preExp, i_exp_matchType);
        a_preExp = Tpl.softNewLine(a_preExp);
        a_preExp = Tpl.popBlock(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING_LIST({
                                              "}\n",
                                              "if (!"
                                          }, false));
        a_preExp = Tpl.writeText(a_preExp, l_done);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE(") MMC_THROW();\n"));
        a_preExp = Tpl.popBlock(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_LINE("}\n"));
        a_preExp = Tpl.popBlock(a_preExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("}"));
        txt = Tpl.writeText(txt, a_res);
      then (txt, a_res, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_res,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_res, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpMatch2;

protected function lm_642
  input Tpl.Text in_txt;
  input list<DAE.Pattern> in_items;
  input Tpl.Text in_a_assignments;
  input Tpl.Text in_a_varDeclsCaseInner;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_prefix;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_assignments;
  output Tpl.Text out_a_varDeclsCaseInner;
  output Tpl.Text out_a_onPatternFail;
algorithm
  (out_txt, out_a_assignments, out_a_varDeclsCaseInner, out_a_onPatternFail) :=
  matchcontinue(in_txt, in_items, in_a_assignments, in_a_varDeclsCaseInner, in_a_onPatternFail, in_a_prefix)
    local
      Tpl.Text txt;
      list<DAE.Pattern> rest;
      Tpl.Text a_assignments;
      Tpl.Text a_varDeclsCaseInner;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_prefix;
      Integer x_i0;
      DAE.Pattern i_lhs;
      Tpl.Text txt_0;

    case ( txt,
           {},
           a_assignments,
           a_varDeclsCaseInner,
           a_onPatternFail,
           _ )
      then (txt, a_assignments, a_varDeclsCaseInner, a_onPatternFail);

    case ( txt,
           i_lhs :: rest,
           a_assignments,
           a_varDeclsCaseInner,
           a_onPatternFail,
           a_prefix )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        txt_0 = Tpl.writeText(Tpl.emptyTxt, a_prefix);
        txt_0 = Tpl.writeTok(txt_0, Tpl.ST_STRING("_in"));
        txt_0 = Tpl.writeStr(txt_0, intString(x_i0));
        (txt, txt_0, a_onPatternFail, a_varDeclsCaseInner, a_assignments) = patternMatch(txt, i_lhs, txt_0, a_onPatternFail, a_varDeclsCaseInner, a_assignments);
        txt = Tpl.nextIter(txt);
        (txt, a_assignments, a_varDeclsCaseInner, a_onPatternFail) = lm_642(txt, rest, a_assignments, a_varDeclsCaseInner, a_onPatternFail, a_prefix);
      then (txt, a_assignments, a_varDeclsCaseInner, a_onPatternFail);

    case ( txt,
           _ :: rest,
           a_assignments,
           a_varDeclsCaseInner,
           a_onPatternFail,
           a_prefix )
      equation
        (txt, a_assignments, a_varDeclsCaseInner, a_onPatternFail) = lm_642(txt, rest, a_assignments, a_varDeclsCaseInner, a_onPatternFail, a_prefix);
      then (txt, a_assignments, a_varDeclsCaseInner, a_onPatternFail);
  end matchcontinue;
end lm_642;

protected function lm_643
  input Tpl.Text in_txt;
  input list<DAE.Statement> in_items;
  input Tpl.Text in_a_varDeclsCaseInner;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDeclsCaseInner;
algorithm
  (out_txt, out_a_varDeclsCaseInner) :=
  matchcontinue(in_txt, in_items, in_a_varDeclsCaseInner, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Statement> rest;
      Tpl.Text a_varDeclsCaseInner;
      SimCode.Context a_context;
      DAE.Statement i_stmt;

    case ( txt,
           {},
           a_varDeclsCaseInner,
           _ )
      then (txt, a_varDeclsCaseInner);

    case ( txt,
           i_stmt :: rest,
           a_varDeclsCaseInner,
           a_context )
      equation
        (txt, a_varDeclsCaseInner) = algStatement(txt, i_stmt, a_context, a_varDeclsCaseInner);
        txt = Tpl.nextIter(txt);
        (txt, a_varDeclsCaseInner) = lm_643(txt, rest, a_varDeclsCaseInner, a_context);
      then (txt, a_varDeclsCaseInner);

    case ( txt,
           _ :: rest,
           a_varDeclsCaseInner,
           a_context )
      equation
        (txt, a_varDeclsCaseInner) = lm_643(txt, rest, a_varDeclsCaseInner, a_context);
      then (txt, a_varDeclsCaseInner);
  end matchcontinue;
end lm_643;

protected function lm_644
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDeclsCaseInner;
  input Tpl.Text in_a_preRes;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_res;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDeclsCaseInner;
  output Tpl.Text out_a_preRes;
algorithm
  (out_txt, out_a_varDeclsCaseInner, out_a_preRes) :=
  matchcontinue(in_txt, in_items, in_a_varDeclsCaseInner, in_a_preRes, in_a_context, in_a_res)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDeclsCaseInner;
      Tpl.Text a_preRes;
      SimCode.Context a_context;
      Tpl.Text a_res;
      Integer x_i1;
      DAE.Exp i_e;

    case ( txt,
           {},
           a_varDeclsCaseInner,
           a_preRes,
           _,
           _ )
      then (txt, a_varDeclsCaseInner, a_preRes);

    case ( txt,
           i_e :: rest,
           a_varDeclsCaseInner,
           a_preRes,
           a_context,
           a_res )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        txt = Tpl.writeText(txt, a_res);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_targ"));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, a_preRes, a_varDeclsCaseInner) = daeExp(txt, i_e, a_context, a_preRes, a_varDeclsCaseInner);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.nextIter(txt);
        (txt, a_varDeclsCaseInner, a_preRes) = lm_644(txt, rest, a_varDeclsCaseInner, a_preRes, a_context, a_res);
      then (txt, a_varDeclsCaseInner, a_preRes);

    case ( txt,
           _ :: rest,
           a_varDeclsCaseInner,
           a_preRes,
           a_context,
           a_res )
      equation
        (txt, a_varDeclsCaseInner, a_preRes) = lm_644(txt, rest, a_varDeclsCaseInner, a_preRes, a_context, a_res);
      then (txt, a_varDeclsCaseInner, a_preRes);
  end matchcontinue;
end lm_644;

protected function fun_645
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_a_c_result;
  input Tpl.Text in_a_varDeclsCaseInner;
  input Tpl.Text in_a_preRes;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_res;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDeclsCaseInner;
  output Tpl.Text out_a_preRes;
algorithm
  (out_txt, out_a_varDeclsCaseInner, out_a_preRes) :=
  matchcontinue(in_txt, in_a_c_result, in_a_varDeclsCaseInner, in_a_preRes, in_a_context, in_a_res)
    local
      Tpl.Text txt;
      Tpl.Text a_varDeclsCaseInner;
      Tpl.Text a_preRes;
      SimCode.Context a_context;
      Tpl.Text a_res;
      DAE.Exp i_e;
      list<DAE.Exp> i_exps;

    case ( txt,
           SOME(DAE.TUPLE(PR = i_exps)),
           a_varDeclsCaseInner,
           a_preRes,
           a_context,
           a_res )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, NONE(), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDeclsCaseInner, a_preRes) = lm_644(txt, i_exps, a_varDeclsCaseInner, a_preRes, a_context, a_res);
        txt = Tpl.popIter(txt);
      then (txt, a_varDeclsCaseInner, a_preRes);

    case ( txt,
           SOME(i_e),
           a_varDeclsCaseInner,
           a_preRes,
           a_context,
           a_res )
      equation
        txt = Tpl.writeText(txt, a_res);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        (txt, a_preRes, a_varDeclsCaseInner) = daeExp(txt, i_e, a_context, a_preRes, a_varDeclsCaseInner);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_varDeclsCaseInner, a_preRes);

    case ( txt,
           _,
           a_varDeclsCaseInner,
           a_preRes,
           _,
           _ )
      then (txt, a_varDeclsCaseInner, a_preRes);
  end matchcontinue;
end fun_645;

protected function lm_646
  input Tpl.Text in_txt;
  input list<SimCode.Variable> in_items;
  input Tpl.Text in_a_preExpCaseInner;
  input Tpl.Text in_a_varDeclsCaseInner;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExpCaseInner;
  output Tpl.Text out_a_varDeclsCaseInner;
algorithm
  (out_txt, out_a_preExpCaseInner, out_a_varDeclsCaseInner) :=
  matchcontinue(in_txt, in_items, in_a_preExpCaseInner, in_a_varDeclsCaseInner)
    local
      Tpl.Text txt;
      list<SimCode.Variable> rest;
      Tpl.Text a_preExpCaseInner;
      Tpl.Text a_varDeclsCaseInner;
      SimCode.Variable i_var;

    case ( txt,
           {},
           a_preExpCaseInner,
           a_varDeclsCaseInner )
      then (txt, a_preExpCaseInner, a_varDeclsCaseInner);

    case ( txt,
           i_var :: rest,
           a_preExpCaseInner,
           a_varDeclsCaseInner )
      equation
        (txt, a_varDeclsCaseInner, a_preExpCaseInner) = varInit(txt, i_var, "", 0, a_varDeclsCaseInner, a_preExpCaseInner);
        (txt, a_preExpCaseInner, a_varDeclsCaseInner) = lm_646(txt, rest, a_preExpCaseInner, a_varDeclsCaseInner);
      then (txt, a_preExpCaseInner, a_varDeclsCaseInner);

    case ( txt,
           _ :: rest,
           a_preExpCaseInner,
           a_varDeclsCaseInner )
      equation
        (txt, a_preExpCaseInner, a_varDeclsCaseInner) = lm_646(txt, rest, a_preExpCaseInner, a_varDeclsCaseInner);
      then (txt, a_preExpCaseInner, a_varDeclsCaseInner);
  end matchcontinue;
end lm_646;

protected function fun_647
  input Tpl.Text in_txt;
  input Option<DAE.Exp> in_a_c_result;
  input Tpl.Text in_a_caseRes;
  input Tpl.Text in_a_preRes;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_c_result, in_a_caseRes, in_a_preRes)
    local
      Tpl.Text txt;
      Tpl.Text a_caseRes;
      Tpl.Text a_preRes;

    case ( txt,
           NONE(),
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("MMC_THROW();"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           a_caseRes,
           a_preRes )
      equation
        txt = Tpl.writeText(txt, a_preRes);
        txt = Tpl.writeText(txt, a_caseRes);
      then txt;
  end matchcontinue;
end fun_647;

protected function lm_648
  input Tpl.Text in_txt;
  input list<DAE.MatchCase> in_items;
  input Tpl.Text in_a_done;
  input Tpl.Text in_a_res;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_prefix;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_onPatternFail;
algorithm
  (out_txt, out_a_onPatternFail) :=
  matchcontinue(in_txt, in_items, in_a_done, in_a_res, in_a_context, in_a_onPatternFail, in_a_prefix)
    local
      Tpl.Text txt;
      list<DAE.MatchCase> rest;
      Tpl.Text a_done;
      Tpl.Text a_res;
      SimCode.Context a_context;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_prefix;
      Integer x_i0;
      list<DAE.Element> i_c_localDecls;
      Option<DAE.Exp> i_c_result;
      list<DAE.Statement> i_c_body;
      list<DAE.Pattern> i_c_patterns;
      list<SimCode.Variable> ret_8;
      Tpl.Text l_0__;
      Tpl.Text l_caseRes;
      Tpl.Text l_stmts;
      Tpl.Text l_patternMatching;
      Tpl.Text l_preRes;
      Tpl.Text l_assignments;
      Tpl.Text l_preExpCaseInner;
      Tpl.Text l_varDeclsCaseInner;

    case ( txt,
           {},
           _,
           _,
           _,
           a_onPatternFail,
           _ )
      then (txt, a_onPatternFail);

    case ( txt,
           DAE.CASE(patterns = i_c_patterns, body = i_c_body, result = i_c_result, localDecls = i_c_localDecls) :: rest,
           a_done,
           a_res,
           a_context,
           a_onPatternFail,
           a_prefix )
      equation
        x_i0 = Tpl.getIteri_i0(txt);
        l_varDeclsCaseInner = Tpl.emptyTxt;
        l_preExpCaseInner = Tpl.emptyTxt;
        l_assignments = Tpl.emptyTxt;
        l_preRes = Tpl.emptyTxt;
        l_patternMatching = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, SOME(Tpl.ST_STRING("")), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_patternMatching, l_assignments, l_varDeclsCaseInner, a_onPatternFail) = lm_642(l_patternMatching, i_c_patterns, l_assignments, l_varDeclsCaseInner, a_onPatternFail, a_prefix);
        l_patternMatching = Tpl.popIter(l_patternMatching);
        l_stmts = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_NEW_LINE()), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_stmts, l_varDeclsCaseInner) = lm_643(l_stmts, i_c_body, l_varDeclsCaseInner, a_context);
        l_stmts = Tpl.popIter(l_stmts);
        (l_caseRes, l_varDeclsCaseInner, l_preRes) = fun_645(Tpl.emptyTxt, i_c_result, l_varDeclsCaseInner, l_preRes, a_context, a_res);
        ret_8 = SimCode.elementVars(i_c_localDecls);
        (l_0__, l_preExpCaseInner, l_varDeclsCaseInner) = lm_646(Tpl.emptyTxt, ret_8, l_preExpCaseInner, l_varDeclsCaseInner);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("case "));
        txt = Tpl.writeStr(txt, intString(x_i0));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(": {\n"));
        txt = Tpl.pushBlock(txt, Tpl.BT_INDENT(2));
        txt = Tpl.writeText(txt, l_varDeclsCaseInner);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_preExpCaseInner);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_patternMatching);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("/* Pattern matching succeeded */\n"));
        txt = Tpl.writeText(txt, l_assignments);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, l_stmts);
        txt = Tpl.softNewLine(txt);
        txt = fun_647(txt, i_c_result, l_caseRes, l_preRes);
        txt = Tpl.softNewLine(txt);
        txt = Tpl.writeText(txt, a_done);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING_LIST({
                                    " = 1;\n",
                                    "break;\n"
                                }, true));
        txt = Tpl.popBlock(txt);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("}"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
        txt = Tpl.nextIter(txt);
        (txt, a_onPatternFail) = lm_648(txt, rest, a_done, a_res, a_context, a_onPatternFail, a_prefix);
      then (txt, a_onPatternFail);

    case ( txt,
           _ :: rest,
           a_done,
           a_res,
           a_context,
           a_onPatternFail,
           a_prefix )
      equation
        (txt, a_onPatternFail) = lm_648(txt, rest, a_done, a_res, a_context, a_onPatternFail, a_prefix);
      then (txt, a_onPatternFail);
  end matchcontinue;
end lm_648;

public function daeExpMatchCases
  input Tpl.Text txt;
  input list<DAE.MatchCase> a_cases;
  input Tpl.Text a_res;
  input Tpl.Text a_prefix;
  input Tpl.Text a_onPatternFail;
  input Tpl.Text a_done;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_res;
  output Tpl.Text out_a_prefix;
  output Tpl.Text out_a_onPatternFail;
  output Tpl.Text out_a_done;
  output Tpl.Text out_a_varDecls;
algorithm
  out_txt := Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (out_txt, out_a_onPatternFail) := lm_648(out_txt, a_cases, a_done, a_res, a_context, a_onPatternFail, a_prefix);
  out_txt := Tpl.popIter(out_txt);
  out_a_res := a_res;
  out_a_prefix := a_prefix;
  out_a_done := a_done;
  out_a_varDecls := a_varDecls;
end daeExpMatchCases;

protected function lm_650
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExp(txt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_650(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_650(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_650;

protected function fun_651
  input Tpl.Text in_txt;
  input String in_mArg;
  input Tpl.Text in_a_dimsLenStr;
  input Tpl.Text in_a_arrayType;
  input Tpl.Text in_a_dimsValuesStr;
  input String in_a_arrName;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_mArg, in_a_dimsLenStr, in_a_arrayType, in_a_dimsValuesStr, in_a_arrName)
    local
      Tpl.Text txt;
      Tpl.Text a_dimsLenStr;
      Tpl.Text a_arrayType;
      Tpl.Text a_dimsValuesStr;
      String a_arrName;

    case ( txt,
           "metatype_array",
           _,
           _,
           a_dimsValuesStr,
           a_arrName )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("arrayGet("));
        txt = Tpl.writeStr(txt, a_arrName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeText(txt, a_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then txt;

    case ( txt,
           _,
           a_dimsLenStr,
           a_arrayType,
           a_dimsValuesStr,
           a_arrName )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("(*"));
        txt = Tpl.writeText(txt, a_arrayType);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_element_addr(&"));
        txt = Tpl.writeStr(txt, a_arrName);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_dimsLenStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, a_dimsValuesStr);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("))"));
      then txt;
  end matchcontinue;
end fun_651;

public function arrayScalarRhs
  input Tpl.Text txt;
  input DAE.ExpType a_ty;
  input list<DAE.Exp> a_subs;
  input String a_arrName;
  input SimCode.Context a_context;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
protected
  String str_4;
  Tpl.Text l_dimsValuesStr;
  Integer ret_2;
  Tpl.Text l_dimsLenStr;
  Tpl.Text l_arrayType;
algorithm
  l_arrayType := expTypeArray(Tpl.emptyTxt, a_ty);
  ret_2 := listLength(a_subs);
  l_dimsLenStr := Tpl.writeStr(Tpl.emptyTxt, intString(ret_2));
  l_dimsValuesStr := Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
  (l_dimsValuesStr, out_a_varDecls, out_a_preExp) := lm_650(l_dimsValuesStr, a_subs, a_varDecls, a_preExp, a_context);
  l_dimsValuesStr := Tpl.popIter(l_dimsValuesStr);
  str_4 := Tpl.textString(l_arrayType);
  out_txt := fun_651(txt, str_4, l_dimsLenStr, l_arrayType, l_dimsValuesStr, a_arrName);
end arrayScalarRhs;

public function daeExpList
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<DAE.Exp> i_valList;
      Tpl.Text l_expPart;
      Tpl.Text l_tmp;

    case ( txt,
           DAE.LIST(valList = i_valList),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        (l_expPart, a_preExp, a_varDecls) = daeExpListToCons(Tpl.emptyTxt, i_valList, a_context, a_preExp, a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_expPart);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(";"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpList;

public function daeExpListToCons
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_a_listItems;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_listItems, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<DAE.Exp> i_rest;
      DAE.Exp i_e;
      Tpl.Text l_restList;
      Tpl.Text l_expPart;

    case ( txt,
           {},
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_nil()"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           i_e :: i_rest,
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_expPart, a_preExp, a_varDecls) = daeExpMetaHelperConstant(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        (l_restList, a_preExp, a_varDecls) = daeExpListToCons(Tpl.emptyTxt, i_rest, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_cons("));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.writeText(txt, l_restList);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpListToCons;

public function daeExpCons
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_cdr;
      DAE.Exp i_car;
      Tpl.Text l_cdrExp;
      Tpl.Text l_carExp;
      Tpl.Text l_tmp;

    case ( txt,
           DAE.CONS(car = i_car, cdr = i_cdr),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        (l_carExp, a_preExp, a_varDecls) = daeExpMetaHelperConstant(Tpl.emptyTxt, i_car, a_context, a_preExp, a_varDecls);
        (l_cdrExp, a_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_cdr, a_context, a_preExp, a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = mmc_mk_cons("));
        a_preExp = Tpl.writeText(a_preExp, l_carExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(", "));
        a_preExp = Tpl.writeText(a_preExp, l_cdrExp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpCons;

protected function lm_656
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_e;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_e :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExpMetaHelperConstant(txt, i_e, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_656(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_656(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_656;

protected function fun_657
  input Tpl.Text in_txt;
  input Tpl.Text in_a_args;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_args)
    local
      Tpl.Text txt;

    case ( txt,
           Tpl.MEM_TEXT(tokens = {}) )
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
      then txt;
  end matchcontinue;
end fun_657;

public function daeExpMetaTuple
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      list<DAE.Exp> i_listExp;
      Tpl.Text l_tmp;
      Tpl.Text l_args;
      Integer ret_1;
      Tpl.Text l_start;

    case ( txt,
           DAE.META_TUPLE(listExp = i_listExp),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        ret_1 = listLength(i_listExp);
        l_start = daeExpMetaHelperBoxStart(Tpl.emptyTxt, ret_1);
        l_args = Tpl.pushIter(Tpl.emptyTxt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (l_args, a_varDecls, a_preExp) = lm_656(l_args, i_listExp, a_varDecls, a_preExp, a_context);
        l_args = Tpl.popIter(l_args);
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = mmc_mk_box"));
        a_preExp = Tpl.writeText(a_preExp, l_start);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING("0"));
        a_preExp = fun_657(a_preExp, l_args);
        a_preExp = Tpl.writeText(a_preExp, l_args);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(");"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpMetaTuple;

public function daeExpMetaOption
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      DAE.Exp i_e;
      Tpl.Text l_expPart;

    case ( txt,
           DAE.META_OPTION(exp = NONE()),
           _,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_none()"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.META_OPTION(exp = SOME(i_e)),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        (l_expPart, a_preExp, a_varDecls) = daeExpMetaHelperConstant(Tpl.emptyTxt, i_e, a_context, a_preExp, a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_some("));
        txt = Tpl.writeText(txt, l_expPart);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpMetaOption;

protected function lm_660
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      list<DAE.Exp> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      DAE.Exp i_exp;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_exp :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_preExp, a_varDecls) = daeExpMetaHelperConstant(txt, i_exp, a_context, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_660(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        (txt, a_varDecls, a_preExp) = lm_660(txt, rest, a_varDecls, a_preExp, a_context);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_660;

protected function fun_661
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_a_args;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input SimCode.Context in_a_context;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_args, in_a_varDecls, in_a_preExp, in_a_context)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      SimCode.Context a_context;
      list<DAE.Exp> i_args;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_args,
           a_varDecls,
           a_preExp,
           a_context )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls, a_preExp) = lm_660(txt, i_args, a_varDecls, a_preExp, a_context);
        txt = Tpl.popIter(txt);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_661;

public function daeExpMetarecordcall
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_exp, in_a_context, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      Absyn.Path i_path;
      list<DAE.Exp> i_args;
      Integer i_index;
      Tpl.Text l_tmp;
      Integer ret_5;
      Integer ret_4;
      Tpl.Text l_box;
      Tpl.Text l_argsStr;
      Integer ret_1;
      Tpl.Text l_newIndex;

    case ( txt,
           DAE.METARECORDCALL(index = i_index, args = i_args, path = i_path),
           a_context,
           a_preExp,
           a_varDecls )
      equation
        ret_1 = SimCode.incrementInt(i_index, 3);
        l_newIndex = Tpl.writeStr(Tpl.emptyTxt, intString(ret_1));
        (l_argsStr, a_varDecls, a_preExp) = fun_661(Tpl.emptyTxt, i_args, a_varDecls, a_preExp, a_context);
        l_box = Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("mmc_mk_box"));
        ret_4 = listLength(i_args);
        ret_5 = SimCode.incrementInt(ret_4, 1);
        l_box = daeExpMetaHelperBoxStart(l_box, ret_5);
        l_box = Tpl.writeText(l_box, l_newIndex);
        l_box = Tpl.writeTok(l_box, Tpl.ST_STRING(", &"));
        l_box = underscorePath(l_box, i_path);
        l_box = Tpl.writeTok(l_box, Tpl.ST_STRING("__desc"));
        l_box = Tpl.writeText(l_box, l_argsStr);
        l_box = Tpl.writeTok(l_box, Tpl.ST_STRING(")"));
        (l_tmp, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        a_preExp = Tpl.writeText(a_preExp, l_tmp);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(" = "));
        a_preExp = Tpl.writeText(a_preExp, l_box);
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_STRING(";"));
        a_preExp = Tpl.writeTok(a_preExp, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_tmp);
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           _,
           a_preExp,
           a_varDecls )
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end daeExpMetarecordcall;

public function daeExpMetaHelperConstant
  input Tpl.Text txt;
  input DAE.Exp a_e;
  input SimCode.Context a_context;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
protected
  DAE.ExpType ret_1;
  Tpl.Text l_expPart;
algorithm
  (l_expPart, out_a_preExp, out_a_varDecls) := daeExp(Tpl.emptyTxt, a_e, a_context, a_preExp, a_varDecls);
  ret_1 := Expression.typeof(a_e);
  (out_txt, l_expPart, out_a_preExp, out_a_varDecls) := daeExpMetaHelperConstantNameType(txt, l_expPart, ret_1, out_a_preExp, out_a_varDecls);
end daeExpMetaHelperConstant;

protected function lm_664
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_items;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varname;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_items, in_a_varDecls, in_a_preExp, in_a_varname)
    local
      Tpl.Text txt;
      list<DAE.ExpVar> rest;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Tpl.Text a_varname;
      DAE.ExpType i_tp;
      String i_cvname;
      Tpl.Text l_nameText;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           DAE.COMPLEX_VAR(name = i_cvname, tp = i_tp) :: rest,
           a_varDecls,
           a_preExp,
           a_varname )
      equation
        l_nameText = Tpl.writeText(Tpl.emptyTxt, a_varname);
        l_nameText = Tpl.writeTok(l_nameText, Tpl.ST_STRING("."));
        l_nameText = Tpl.writeStr(l_nameText, i_cvname);
        (txt, l_nameText, a_preExp, a_varDecls) = daeExpMetaHelperConstantNameType(txt, l_nameText, i_tp, a_preExp, a_varDecls);
        txt = Tpl.nextIter(txt);
        (txt, a_varDecls, a_preExp) = lm_664(txt, rest, a_varDecls, a_preExp, a_varname);
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           _ :: rest,
           a_varDecls,
           a_preExp,
           a_varname )
      equation
        (txt, a_varDecls, a_preExp) = lm_664(txt, rest, a_varDecls, a_preExp, a_varname);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end lm_664;

protected function fun_665
  input Tpl.Text in_txt;
  input list<DAE.ExpVar> in_a_varLst;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varname;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_preExp;
algorithm
  (out_txt, out_a_varDecls, out_a_preExp) :=
  matchcontinue(in_txt, in_a_varLst, in_a_varDecls, in_a_preExp, in_a_varname)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_preExp;
      Tpl.Text a_varname;
      list<DAE.ExpVar> i_varLst;

    case ( txt,
           {},
           a_varDecls,
           a_preExp,
           _ )
      then (txt, a_varDecls, a_preExp);

    case ( txt,
           i_varLst,
           a_varDecls,
           a_preExp,
           a_varname )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(0, NONE(), SOME(Tpl.ST_STRING(", ")), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_varDecls, a_preExp) = lm_664(txt, i_varLst, a_varDecls, a_preExp, a_varname);
        txt = Tpl.popIter(txt);
      then (txt, a_varDecls, a_preExp);
  end matchcontinue;
end fun_665;

protected function fun_666
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;
  input Tpl.Text in_a_varname;
  input Tpl.Text in_a_preExp;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_type, in_a_varname, in_a_preExp, in_a_varDecls)
    local
      Tpl.Text txt;
      Tpl.Text a_varname;
      Tpl.Text a_preExp;
      Tpl.Text a_varDecls;
      Absyn.Path i_cname;
      list<DAE.ExpVar> i_varLst;
      Tpl.Text l_args;
      Integer ret_2;
      Integer ret_1;
      Tpl.Text l_start;

    case ( txt,
           DAE.ET_INT(),
           a_varname,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeText(txt, a_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_BOOL(),
           a_varname,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeText(txt, a_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_REAL(),
           a_varname,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_rcon("));
        txt = Tpl.writeText(txt, a_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_STRING(),
           a_varname,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_scon("));
        txt = Tpl.writeText(txt, a_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_ENUMERATION(path = _),
           a_varname,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_icon("));
        txt = Tpl.writeText(txt, a_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           DAE.ET_COMPLEX(name = i_cname, varLst = i_varLst),
           a_varname,
           a_preExp,
           a_varDecls )
      equation
        ret_1 = listLength(i_varLst);
        ret_2 = SimCode.incrementInt(ret_1, 1);
        l_start = daeExpMetaHelperBoxStart(Tpl.emptyTxt, ret_2);
        (l_args, a_varDecls, a_preExp) = fun_665(Tpl.emptyTxt, i_varLst, a_varDecls, a_preExp, a_varname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmc_mk_box"));
        txt = Tpl.writeText(txt, l_start);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("2, &"));
        txt = underscorePath(txt, i_cname);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("__desc"));
        txt = Tpl.writeText(txt, l_args);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")"));
      then (txt, a_preExp, a_varDecls);

    case ( txt,
           _,
           a_varname,
           a_preExp,
           a_varDecls )
      equation
        txt = Tpl.writeText(txt, a_varname);
      then (txt, a_preExp, a_varDecls);
  end matchcontinue;
end fun_666;

public function daeExpMetaHelperConstantNameType
  input Tpl.Text txt;
  input Tpl.Text a_varname;
  input DAE.ExpType a_type;
  input Tpl.Text a_preExp;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varname;
  output Tpl.Text out_a_preExp;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_preExp, out_a_varDecls) := fun_666(txt, a_type, a_varname, a_preExp, a_varDecls);
  out_a_varname := a_varname;
end daeExpMetaHelperConstantNameType;

public function daeExpMetaHelperBoxStart
  input Tpl.Text in_txt;
  input Integer in_a_numVariables;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_numVariables)
    local
      Tpl.Text txt;
      Integer i_numVariables;

    case ( txt,
           (i_numVariables as 0) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 1) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 2) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 3) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 4) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 5) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 6) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 7) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 8) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           (i_numVariables as 9) )
      equation
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
      then txt;

    case ( txt,
           i_numVariables )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("("));
        txt = Tpl.writeStr(txt, intString(i_numVariables));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(", "));
      then txt;
  end matchcontinue;
end daeExpMetaHelperBoxStart;

public function outDecl
  input Tpl.Text txt;
  input String a_ty;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_newVar;
algorithm
  l_newVar := Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("out"));
  out_a_varDecls := Tpl.writeStr(a_varDecls, a_ty);
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_STRING(" "));
  out_a_varDecls := Tpl.writeText(out_a_varDecls, l_newVar);
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_STRING(";"));
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, l_newVar);
end outDecl;

public function tempDecl
  input Tpl.Text txt;
  input String a_ty;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
protected
  Integer ret_1;
  Tpl.Text l_newVar;
algorithm
  l_newVar := Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("tmp"));
  ret_1 := System.tmpTick();
  l_newVar := Tpl.writeStr(l_newVar, intString(ret_1));
  out_a_varDecls := Tpl.writeStr(a_varDecls, a_ty);
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_STRING(" "));
  out_a_varDecls := Tpl.writeText(out_a_varDecls, l_newVar);
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_STRING(";"));
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, l_newVar);
end tempDecl;

public function tempDeclConst
  input Tpl.Text txt;
  input String a_ty;
  input String a_val;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
protected
  Integer ret_1;
  Tpl.Text l_newVar;
algorithm
  l_newVar := Tpl.writeTok(Tpl.emptyTxt, Tpl.ST_STRING("tmp"));
  ret_1 := System.tmpTick();
  l_newVar := Tpl.writeStr(l_newVar, intString(ret_1));
  out_a_varDecls := Tpl.writeStr(a_varDecls, a_ty);
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_STRING(" "));
  out_a_varDecls := Tpl.writeText(out_a_varDecls, l_newVar);
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_STRING(" = "));
  out_a_varDecls := Tpl.writeStr(out_a_varDecls, a_val);
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_STRING(";"));
  out_a_varDecls := Tpl.writeTok(out_a_varDecls, Tpl.ST_NEW_LINE());
  out_txt := Tpl.writeText(txt, l_newVar);
end tempDeclConst;

protected function fun_672
  input Tpl.Text in_txt;
  input list<DAE.Exp> in_a_instDims;
  input DAE.ExpType in_a_var_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_instDims, in_a_var_ty)
    local
      Tpl.Text txt;
      DAE.ExpType a_var_ty;

    case ( txt,
           {},
           a_var_ty )
      equation
        txt = expTypeArrayIf(txt, a_var_ty);
      then txt;

    case ( txt,
           _,
           a_var_ty )
      equation
        txt = expTypeArray(txt, a_var_ty);
      then txt;
  end matchcontinue;
end fun_672;

public function varType
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      DAE.ExpType i_var_ty;
      list<DAE.Exp> i_instDims;

    case ( txt,
           SimCode.VARIABLE(instDims = i_instDims, ty = i_var_ty) )
      equation
        txt = fun_672(txt, i_instDims, i_var_ty);
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end varType;

public function varTypeBoxed
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;

    case ( txt,
           SimCode.VARIABLE(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_metatype"));
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end varTypeBoxed;

public function expTypeRW
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_INT"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_REAL"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_STRING"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_BOOL"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_INT"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      equation
        txt = expTypeRW(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_ARRAY"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.RECORD(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_RECORD"));
      then txt;

    case ( txt,
           DAE.ET_METATYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("TYPE_DESC_MMC"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end expTypeRW;

public function expTypeShort
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;
      Absyn.Path i_name;
      DAE.ExpType i_ty;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_OTHER() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("complex"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      equation
        txt = expTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = _)) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("complex"));
      then txt;

    case ( txt,
           DAE.ET_COMPLEX(name = i_name) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_name);
      then txt;

    case ( txt,
           DAE.ET_METATYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_FUNCTION_REFERENCE_VAR() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fnptr"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeShort:ERROR"));
      then txt;
  end matchcontinue;
end expTypeShort;

public function mmcVarType
  input Tpl.Text in_txt;
  input SimCode.Variable in_a_var;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_var)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           SimCode.VARIABLE(ty = i_ty) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = mmcExpTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           SimCode.FUNCTION_PTR(name = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_fnptr"));
      then txt;

    case ( txt,
           _ )
      then txt;
  end matchcontinue;
end mmcVarType;

public function mmcExpTypeShort
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_type;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_type)
    local
      Tpl.Text txt;

    case ( txt,
           DAE.ET_INT() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_REAL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;

    case ( txt,
           DAE.ET_STRING() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string"));
      then txt;

    case ( txt,
           DAE.ET_BOOL() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_ENUMERATION(path = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           DAE.ET_ARRAY(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("array"));
      then txt;

    case ( txt,
           DAE.ET_METATYPE() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_BOXED(ty = _) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("metatype"));
      then txt;

    case ( txt,
           DAE.ET_FUNCTION_REFERENCE_VAR() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("fnptr"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("mmcExpTypeShort:ERROR"));
      then txt;
  end matchcontinue;
end mmcExpTypeShort;

protected function fun_679
  input Tpl.Text in_txt;
  input Boolean in_a_array;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_array, in_a_ty)
    local
      Tpl.Text txt;
      DAE.ExpType a_ty;

    case ( txt,
           true,
           a_ty )
      equation
        txt = expTypeArray(txt, a_ty);
      then txt;

    case ( txt,
           false,
           a_ty )
      equation
        txt = expTypeModelica(txt, a_ty);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_679;

public function expType
  input Tpl.Text txt;
  input DAE.ExpType a_ty;
  input Boolean a_array;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_679(txt, a_array, a_ty);
end expType;

public function expTypeModelica
  input Tpl.Text txt;
  input DAE.ExpType a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, a_ty, 2);
end expTypeModelica;

public function expTypeArray
  input Tpl.Text txt;
  input DAE.ExpType a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, a_ty, 3);
end expTypeArray;

public function expTypeArrayIf
  input Tpl.Text txt;
  input DAE.ExpType a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFlag(txt, a_ty, 4);
end expTypeArrayIf;

public function expTypeFromExpShort
  input Tpl.Text txt;
  input DAE.Exp a_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, a_exp, 1);
end expTypeFromExpShort;

public function expTypeFromExpModelica
  input Tpl.Text txt;
  input DAE.Exp a_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, a_exp, 2);
end expTypeFromExpModelica;

public function expTypeFromExpArray
  input Tpl.Text txt;
  input DAE.Exp a_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, a_exp, 3);
end expTypeFromExpArray;

public function expTypeFromExpArrayIf
  input Tpl.Text txt;
  input DAE.Exp a_exp;

  output Tpl.Text out_txt;
algorithm
  out_txt := expTypeFromExpFlag(txt, a_exp, 4);
end expTypeFromExpArrayIf;

protected function fun_688
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;
      Absyn.Path i_name;

    case ( txt,
           DAE.ET_COMPLEX(name = i_name) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("struct "));
        txt = underscorePath(txt, i_name);
      then txt;

    case ( txt,
           i_ty )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = expTypeShort(txt, i_ty);
      then txt;
  end matchcontinue;
end fun_688;

protected function fun_689
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           (i_ty as DAE.ET_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = _))) )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_"));
        txt = expTypeShort(txt, i_ty);
      then txt;

    case ( txt,
           i_ty )
      equation
        txt = fun_688(txt, i_ty);
      then txt;
  end matchcontinue;
end fun_689;

protected function fun_690
  input Tpl.Text in_txt;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_ty)
    local
      Tpl.Text txt;
      DAE.ExpType i_ty;

    case ( txt,
           DAE.ET_ARRAY(ty = i_ty) )
      equation
        txt = expTypeShort(txt, i_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array"));
      then txt;

    case ( txt,
           i_ty )
      equation
        txt = expTypeFlag(txt, i_ty, 2);
      then txt;
  end matchcontinue;
end fun_690;

protected function fun_691
  input Tpl.Text in_txt;
  input Integer in_a_flag;
  input DAE.ExpType in_a_ty;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag, in_a_ty)
    local
      Tpl.Text txt;
      DAE.ExpType a_ty;

    case ( txt,
           1,
           a_ty )
      equation
        txt = expTypeShort(txt, a_ty);
      then txt;

    case ( txt,
           2,
           a_ty )
      equation
        txt = fun_689(txt, a_ty);
      then txt;

    case ( txt,
           3,
           a_ty )
      equation
        txt = expTypeShort(txt, a_ty);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("_array"));
      then txt;

    case ( txt,
           4,
           a_ty )
      equation
        txt = fun_690(txt, a_ty);
      then txt;

    case ( txt,
           _,
           _ )
      then txt;
  end matchcontinue;
end fun_691;

public function expTypeFlag
  input Tpl.Text txt;
  input DAE.ExpType a_ty;
  input Integer a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt := fun_691(txt, a_flag, a_ty);
end expTypeFlag;

protected function fun_693
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           8 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_integer"));
      then txt;
  end matchcontinue;
end fun_693;

protected function fun_694
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("real"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_real"));
      then txt;
  end matchcontinue;
end fun_694;

protected function fun_695
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("string"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_string"));
      then txt;
  end matchcontinue;
end fun_695;

protected function fun_696
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_696;

protected function fun_697
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           8 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("int"));
      then txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("integer"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_integer"));
      then txt;
  end matchcontinue;
end fun_697;

public function expTypeFromExpFlag
  input Tpl.Text in_txt;
  input DAE.Exp in_a_exp;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_exp, in_a_flag)
    local
      Tpl.Text txt;
      Integer a_flag;
      DAE.Exp i_expr;
      DAE.Exp i_exp;
      DAE.ExpType i_c_ty;
      DAE.ExpType i_ty;
      DAE.Exp i_expThen;
      DAE.Operator i_e_operator;

    case ( txt,
           DAE.ICONST(integer = _),
           a_flag )
      equation
        txt = fun_693(txt, a_flag);
      then txt;

    case ( txt,
           DAE.RCONST(real = _),
           a_flag )
      equation
        txt = fun_694(txt, a_flag);
      then txt;

    case ( txt,
           DAE.SCONST(string = _),
           a_flag )
      equation
        txt = fun_695(txt, a_flag);
      then txt;

    case ( txt,
           DAE.BCONST(bool = _),
           a_flag )
      equation
        txt = fun_696(txt, a_flag);
      then txt;

    case ( txt,
           DAE.ENUM_LITERAL(name = _),
           a_flag )
      equation
        txt = fun_697(txt, a_flag);
      then txt;

    case ( txt,
           DAE.BINARY(operator = i_e_operator),
           a_flag )
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, a_flag);
      then txt;

    case ( txt,
           DAE.UNARY(operator = i_e_operator),
           a_flag )
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, a_flag);
      then txt;

    case ( txt,
           DAE.LBINARY(operator = i_e_operator),
           a_flag )
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, a_flag);
      then txt;

    case ( txt,
           DAE.LUNARY(operator = i_e_operator),
           a_flag )
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, a_flag);
      then txt;

    case ( txt,
           DAE.RELATION(operator = i_e_operator),
           a_flag )
      equation
        txt = expTypeFromOpFlag(txt, i_e_operator, a_flag);
      then txt;

    case ( txt,
           DAE.IFEXP(expThen = i_expThen),
           a_flag )
      equation
        txt = expTypeFromExpFlag(txt, i_expThen, a_flag);
      then txt;

    case ( txt,
           DAE.CALL(ty = i_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_ty, a_flag);
      then txt;

    case ( txt,
           DAE.ARRAY(ty = i_c_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_c_ty, a_flag);
      then txt;

    case ( txt,
           DAE.MATRIX(ty = i_c_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_c_ty, a_flag);
      then txt;

    case ( txt,
           DAE.RANGE(ty = i_c_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_c_ty, a_flag);
      then txt;

    case ( txt,
           DAE.CAST(ty = i_c_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_c_ty, a_flag);
      then txt;

    case ( txt,
           DAE.CREF(ty = i_c_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_c_ty, a_flag);
      then txt;

    case ( txt,
           DAE.CODE(ty = i_c_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_c_ty, a_flag);
      then txt;

    case ( txt,
           DAE.ASUB(exp = i_exp),
           a_flag )
      equation
        txt = expTypeFromExpFlag(txt, i_exp, a_flag);
      then txt;

    case ( txt,
           DAE.REDUCTION(expr = i_expr),
           a_flag )
      equation
        txt = expTypeFromExpFlag(txt, i_expr, a_flag);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeFromExpFlag:ERROR"));
      then txt;
  end matchcontinue;
end expTypeFromExpFlag;

protected function fun_699
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_699;

protected function fun_700
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_700;

protected function fun_701
  input Tpl.Text in_txt;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_flag)
    local
      Tpl.Text txt;

    case ( txt,
           1 )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("boolean"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("modelica_boolean"));
      then txt;
  end matchcontinue;
end fun_701;

public function expTypeFromOpFlag
  input Tpl.Text in_txt;
  input DAE.Operator in_a_op;
  input Integer in_a_flag;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_op, in_a_flag)
    local
      Tpl.Text txt;
      Integer a_flag;
      DAE.ExpType i_o_ty;

    case ( txt,
           DAE.ADD(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.SUB(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.MUL(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.DIV(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.POW(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.UMINUS(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.UPLUS(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.UMINUS_ARR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.UPLUS_ARR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.ADD_ARR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.SUB_ARR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.MUL_ARR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.DIV_ARR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.MUL_SCALAR_ARRAY(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.MUL_ARRAY_SCALAR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.ADD_SCALAR_ARRAY(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.ADD_ARRAY_SCALAR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.SUB_SCALAR_ARRAY(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.SUB_ARRAY_SCALAR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.MUL_SCALAR_PRODUCT(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.MUL_MATRIX_PRODUCT(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.DIV_ARRAY_SCALAR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.DIV_SCALAR_ARRAY(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.POW_ARRAY_SCALAR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.POW_SCALAR_ARRAY(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.POW_ARR(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.POW_ARR2(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.LESS(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.LESSEQ(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.GREATER(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.GREATEREQ(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.EQUAL(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.NEQUAL(ty = i_o_ty),
           a_flag )
      equation
        txt = expTypeFlag(txt, i_o_ty, a_flag);
      then txt;

    case ( txt,
           DAE.AND(),
           a_flag )
      equation
        txt = fun_699(txt, a_flag);
      then txt;

    case ( txt,
           DAE.OR(),
           a_flag )
      equation
        txt = fun_700(txt, a_flag);
      then txt;

    case ( txt,
           DAE.NOT(),
           a_flag )
      equation
        txt = fun_701(txt, a_flag);
      then txt;

    case ( txt,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("expTypeFromOpFlag:ERROR"));
      then txt;
  end matchcontinue;
end expTypeFromOpFlag;

public function dimension
  input Tpl.Text in_txt;
  input DAE.Dimension in_a_d;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_d)
    local
      Tpl.Text txt;
      Integer i_size;
      Integer i_integer;

    case ( txt,
           DAE.DIM_INTEGER(integer = i_integer) )
      equation
        txt = Tpl.writeStr(txt, intString(i_integer));
      then txt;

    case ( txt,
           DAE.DIM_ENUM(size = i_size) )
      equation
        txt = Tpl.writeStr(txt, intString(i_size));
      then txt;

    case ( txt,
           DAE.DIM_UNKNOWN() )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(":"));
      then txt;

    case ( txt,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("INVALID_DIMENSION"));
      then txt;
  end matchcontinue;
end dimension;

public function algStmtAssignPattern
  input Tpl.Text in_txt;
  input DAE.Statement in_a_stmt;
  input SimCode.Context in_a_context;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_varDecls) :=
  matchcontinue(in_txt, in_a_stmt, in_a_context, in_a_varDecls)
    local
      Tpl.Text txt;
      SimCode.Context a_context;
      Tpl.Text a_varDecls;
      DAE.Pattern i_lhs;
      DAE.Exp i_rhs;
      Tpl.Text l_expPart;
      Tpl.Text l_assignments;
      Tpl.Text l_preExp;

    case ( txt,
           DAE.STMT_ASSIGN_PATTERN(rhs = i_rhs, lhs = i_lhs),
           a_context,
           a_varDecls )
      equation
        l_preExp = Tpl.emptyTxt;
        l_assignments = Tpl.emptyTxt;
        (l_expPart, l_preExp, a_varDecls) = daeExp(Tpl.emptyTxt, i_rhs, a_context, l_preExp, a_varDecls);
        txt = Tpl.writeText(txt, l_preExp);
        txt = Tpl.softNewLine(txt);
        (txt, l_expPart, _, a_varDecls, l_assignments) = patternMatch(txt, i_lhs, l_expPart, Tpl.strTokText(Tpl.ST_STRING("MMC_THROW()")), a_varDecls, l_assignments);
        txt = Tpl.writeText(txt, l_assignments);
      then (txt, a_varDecls);

    case ( txt,
           _,
           _,
           a_varDecls )
      then (txt, a_varDecls);
  end matchcontinue;
end algStmtAssignPattern;

protected function fun_705
  input Tpl.Text in_txt;
  input Option<DAE.ExpType> in_a_p_ty;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_unboxBuf;
  input Tpl.Text in_a_rhs;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_unboxBuf;
algorithm
  (out_txt, out_a_varDecls, out_a_unboxBuf) :=
  matchcontinue(in_txt, in_a_p_ty, in_a_varDecls, in_a_unboxBuf, in_a_rhs)
    local
      Tpl.Text txt;
      Tpl.Text a_varDecls;
      Tpl.Text a_unboxBuf;
      Tpl.Text a_rhs;
      DAE.ExpType i_et;

    case ( txt,
           SOME(i_et),
           a_varDecls,
           a_unboxBuf,
           a_rhs )
      equation
        (txt, a_unboxBuf, a_varDecls) = unboxVariable(txt, Tpl.textString(a_rhs), i_et, a_unboxBuf, a_varDecls);
      then (txt, a_varDecls, a_unboxBuf);

    case ( txt,
           _,
           a_varDecls,
           a_unboxBuf,
           a_rhs )
      equation
        txt = Tpl.writeText(txt, a_rhs);
      then (txt, a_varDecls, a_unboxBuf);
  end matchcontinue;
end fun_705;

protected function fun_706
  input Tpl.Text in_txt;
  input DAE.Exp in_a_p_exp;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_urhs;

  output Tpl.Text out_txt;
algorithm
  out_txt :=
  matchcontinue(in_txt, in_a_p_exp, in_a_onPatternFail, in_a_urhs)
    local
      Tpl.Text txt;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_urhs;
      Boolean i_c_bool;
      String i_c_string;
      Real i_c_real;
      Integer i_c_integer;

    case ( txt,
           DAE.ICONST(integer = i_c_integer),
           a_onPatternFail,
           a_urhs )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeStr(txt, intString(i_c_integer));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, a_urhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           DAE.RCONST(real = i_c_real),
           a_onPatternFail,
           a_urhs )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeStr(txt, realString(i_c_real));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, a_urhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           DAE.SCONST(string = i_c_string),
           a_onPatternFail,
           a_urhs )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (strcmp(\""));
        txt = Tpl.writeStr(txt, i_c_string);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("\", "));
        txt = Tpl.writeText(txt, a_urhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") != 0) "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           DAE.BCONST(bool = i_c_bool),
           a_onPatternFail,
           a_urhs )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if ("));
        txt = Tpl.writeStr(txt, Tpl.booleanString(i_c_bool));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" != "));
        txt = Tpl.writeText(txt, a_urhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           DAE.LIST(valList = {}),
           a_onPatternFail,
           a_urhs )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (!listEmpty("));
        txt = Tpl.writeText(txt, a_urhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           DAE.META_OPTION(exp = NONE()),
           a_onPatternFail,
           a_urhs )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (!optionNone("));
        txt = Tpl.writeText(txt, a_urhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(";"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then txt;

    case ( txt,
           _,
           _,
           _ )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_CONSTANT_PATTERN"));
      then txt;
  end matchcontinue;
end fun_706;

protected function lm_707
  input Tpl.Text in_txt;
  input list<DAE.Pattern> in_items;
  input Tpl.Text in_a_assignments;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_rhs;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_assignments;
  output Tpl.Text out_a_onPatternFail;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_assignments, out_a_onPatternFail, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_assignments, in_a_onPatternFail, in_a_rhs, in_a_varDecls)
    local
      Tpl.Text txt;
      list<DAE.Pattern> rest;
      Tpl.Text a_assignments;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_rhs;
      Tpl.Text a_varDecls;
      Integer x_i1;
      DAE.Pattern i_p;
      Tpl.Text l_tvar;

    case ( txt,
           {},
           a_assignments,
           a_onPatternFail,
           _,
           a_varDecls )
      then (txt, a_assignments, a_onPatternFail, a_varDecls);

    case ( txt,
           i_p :: rest,
           a_assignments,
           a_onPatternFail,
           a_rhs,
           a_varDecls )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        txt = Tpl.writeText(txt, l_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), "));
        txt = Tpl.writeStr(txt, intString(x_i1));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("));\n"));
        (txt, l_tvar, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p, l_tvar, a_onPatternFail, a_varDecls, a_assignments);
        txt = Tpl.nextIter(txt);
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_707(txt, rest, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
      then (txt, a_assignments, a_onPatternFail, a_varDecls);

    case ( txt,
           _ :: rest,
           a_assignments,
           a_onPatternFail,
           a_rhs,
           a_varDecls )
      equation
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_707(txt, rest, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
      then (txt, a_assignments, a_onPatternFail, a_varDecls);
  end matchcontinue;
end lm_707;

protected function lm_708
  input Tpl.Text in_txt;
  input list<DAE.Pattern> in_items;
  input Tpl.Text in_a_assignments;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_rhs;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_assignments;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_onPatternFail;
algorithm
  (out_txt, out_a_assignments, out_a_varDecls, out_a_onPatternFail) :=
  matchcontinue(in_txt, in_items, in_a_assignments, in_a_varDecls, in_a_onPatternFail, in_a_rhs)
    local
      Tpl.Text txt;
      list<DAE.Pattern> rest;
      Tpl.Text a_assignments;
      Tpl.Text a_varDecls;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_rhs;
      Integer x_i1;
      DAE.Pattern i_p;
      Tpl.Text l_nrhs;

    case ( txt,
           {},
           a_assignments,
           a_varDecls,
           a_onPatternFail,
           _ )
      then (txt, a_assignments, a_varDecls, a_onPatternFail);

    case ( txt,
           i_p :: rest,
           a_assignments,
           a_varDecls,
           a_onPatternFail,
           a_rhs )
      equation
        x_i1 = Tpl.getIteri_i0(txt);
        l_nrhs = Tpl.writeText(Tpl.emptyTxt, a_rhs);
        l_nrhs = Tpl.writeTok(l_nrhs, Tpl.ST_STRING(".targ"));
        l_nrhs = Tpl.writeStr(l_nrhs, intString(x_i1));
        (txt, l_nrhs, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p, l_nrhs, a_onPatternFail, a_varDecls, a_assignments);
        txt = Tpl.nextIter(txt);
        (txt, a_assignments, a_varDecls, a_onPatternFail) = lm_708(txt, rest, a_assignments, a_varDecls, a_onPatternFail, a_rhs);
      then (txt, a_assignments, a_varDecls, a_onPatternFail);

    case ( txt,
           _ :: rest,
           a_assignments,
           a_varDecls,
           a_onPatternFail,
           a_rhs )
      equation
        (txt, a_assignments, a_varDecls, a_onPatternFail) = lm_708(txt, rest, a_assignments, a_varDecls, a_onPatternFail, a_rhs);
      then (txt, a_assignments, a_varDecls, a_onPatternFail);
  end matchcontinue;
end lm_708;

protected function lm_709
  input Tpl.Text in_txt;
  input list<tuple<DAE.Pattern, String, DAE.ExpType>> in_items;
  input Tpl.Text in_a_assignments;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_rhs;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_assignments;
  output Tpl.Text out_a_onPatternFail;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_assignments, out_a_onPatternFail, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_assignments, in_a_onPatternFail, in_a_rhs, in_a_varDecls)
    local
      Tpl.Text txt;
      list<tuple<DAE.Pattern, String, DAE.ExpType>> rest;
      Tpl.Text a_assignments;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_rhs;
      Tpl.Text a_varDecls;
      DAE.Pattern i_p;
      String i_n;
      DAE.ExpType i_t;
      Tpl.Text txt_1;
      Tpl.Text l_tvar;

    case ( txt,
           {},
           a_assignments,
           a_onPatternFail,
           _,
           a_varDecls )
      then (txt, a_assignments, a_onPatternFail, a_varDecls);

    case ( txt,
           (i_p, i_n, i_t) :: rest,
           a_assignments,
           a_onPatternFail,
           a_rhs,
           a_varDecls )
      equation
        txt_1 = expTypeModelica(Tpl.emptyTxt, i_t);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, Tpl.textString(txt_1), a_varDecls);
        txt = Tpl.writeText(txt, l_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = "));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("."));
        txt = Tpl.writeStr(txt, i_n);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        (txt, l_tvar, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p, l_tvar, a_onPatternFail, a_varDecls, a_assignments);
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_709(txt, rest, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
      then (txt, a_assignments, a_onPatternFail, a_varDecls);

    case ( txt,
           _ :: rest,
           a_assignments,
           a_onPatternFail,
           a_rhs,
           a_varDecls )
      equation
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_709(txt, rest, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
      then (txt, a_assignments, a_onPatternFail, a_varDecls);
  end matchcontinue;
end lm_709;

protected function lm_710
  input Tpl.Text in_txt;
  input list<DAE.Pattern> in_items;
  input Tpl.Text in_a_assignments;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_rhs;
  input Tpl.Text in_a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_assignments;
  output Tpl.Text out_a_onPatternFail;
  output Tpl.Text out_a_varDecls;
algorithm
  (out_txt, out_a_assignments, out_a_onPatternFail, out_a_varDecls) :=
  matchcontinue(in_txt, in_items, in_a_assignments, in_a_onPatternFail, in_a_rhs, in_a_varDecls)
    local
      Tpl.Text txt;
      list<DAE.Pattern> rest;
      Tpl.Text a_assignments;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_rhs;
      Tpl.Text a_varDecls;
      Integer x_i2;
      DAE.Pattern i_p;
      Tpl.Text l_tvar;

    case ( txt,
           {},
           a_assignments,
           a_onPatternFail,
           _,
           a_varDecls )
      then (txt, a_assignments, a_onPatternFail, a_varDecls);

    case ( txt,
           i_p :: rest,
           a_assignments,
           a_onPatternFail,
           a_rhs,
           a_varDecls )
      equation
        x_i2 = Tpl.getIteri_i0(txt);
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        txt = Tpl.writeText(txt, l_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("), "));
        txt = Tpl.writeStr(txt, intString(x_i2));
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("));\n"));
        (txt, l_tvar, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p, l_tvar, a_onPatternFail, a_varDecls, a_assignments);
        txt = Tpl.nextIter(txt);
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_710(txt, rest, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
      then (txt, a_assignments, a_onPatternFail, a_varDecls);

    case ( txt,
           _ :: rest,
           a_assignments,
           a_onPatternFail,
           a_rhs,
           a_varDecls )
      equation
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_710(txt, rest, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
      then (txt, a_assignments, a_onPatternFail, a_varDecls);
  end matchcontinue;
end lm_710;

public function patternMatch
  input Tpl.Text in_txt;
  input DAE.Pattern in_a_pat;
  input Tpl.Text in_a_rhs;
  input Tpl.Text in_a_onPatternFail;
  input Tpl.Text in_a_varDecls;
  input Tpl.Text in_a_assignments;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_rhs;
  output Tpl.Text out_a_onPatternFail;
  output Tpl.Text out_a_varDecls;
  output Tpl.Text out_a_assignments;
algorithm
  (out_txt, out_a_rhs, out_a_onPatternFail, out_a_varDecls, out_a_assignments) :=
  matchcontinue(in_txt, in_a_pat, in_a_rhs, in_a_onPatternFail, in_a_varDecls, in_a_assignments)
    local
      Tpl.Text txt;
      Tpl.Text a_rhs;
      Tpl.Text a_onPatternFail;
      Tpl.Text a_varDecls;
      Tpl.Text a_assignments;
      DAE.ExpType i_et;
      String i_p_id;
      Integer i_index;
      list<tuple<DAE.Pattern, String, DAE.ExpType>> i_patterns_1;
      list<DAE.Pattern> i_patterns;
      DAE.Pattern i_tail;
      DAE.Pattern i_head;
      DAE.Pattern i_p_pat;
      DAE.Exp i_p_exp;
      Option<DAE.ExpType> i_p_ty;
      Integer ret_5;
      Tpl.Text l_tvarTail;
      Tpl.Text l_tvarHead;
      Tpl.Text l_tvar;
      Tpl.Text l_urhs;
      Tpl.Text l_unboxBuf;

    case ( txt,
           DAE.PAT_WILD(),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_CONSTANT(ty = i_p_ty, exp = i_p_exp),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        l_unboxBuf = Tpl.emptyTxt;
        (l_urhs, a_varDecls, l_unboxBuf) = fun_705(Tpl.emptyTxt, i_p_ty, a_varDecls, l_unboxBuf, a_rhs);
        txt = Tpl.writeText(txt, l_unboxBuf);
        txt = fun_706(txt, i_p_exp, a_onPatternFail, l_urhs);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_SOME(pat = i_p_pat),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        (l_tvar, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (optionNone("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, l_tvar);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE("), 1));\n"));
        (txt, l_tvar, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p_pat, l_tvar, a_onPatternFail, a_varDecls, a_assignments);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_CONS(head = i_head, tail = i_tail),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        (l_tvarHead, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        (l_tvarTail, a_varDecls) = tempDecl(Tpl.emptyTxt, "modelica_metatype", a_varDecls);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (listEmpty("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(")) "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.writeText(txt, l_tvarHead);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = MMC_CAR("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        txt = Tpl.writeText(txt, l_tvarTail);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" = MMC_CDR("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(");\n"));
        (txt, l_tvarHead, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_head, l_tvarHead, a_onPatternFail, a_varDecls, a_assignments);
        (txt, l_tvarTail, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_tail, l_tvarTail, a_onPatternFail, a_varDecls, a_assignments);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_META_TUPLE(patterns = i_patterns),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, SOME(Tpl.ST_STRING("")), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_707(txt, i_patterns, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
        txt = Tpl.popIter(txt);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_CALL_TUPLE(patterns = i_patterns),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(1, SOME(Tpl.ST_STRING("")), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_assignments, a_varDecls, a_onPatternFail) = lm_708(txt, i_patterns, a_assignments, a_varDecls, a_onPatternFail, a_rhs);
        txt = Tpl.popIter(txt);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_CALL_NAMED(patterns = i_patterns_1),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_709(txt, i_patterns_1, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_CALL(index = i_index, patterns = i_patterns),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("if (mmc__uniontype__metarecord__typedef__equal("));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        txt = Tpl.writeStr(txt, intString(i_index));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(","));
        ret_5 = listLength(i_patterns);
        txt = Tpl.writeStr(txt, intString(ret_5));
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(") == 0) "));
        txt = Tpl.writeText(txt, a_onPatternFail);
        txt = Tpl.writeTok(txt, Tpl.ST_LINE(";\n"));
        txt = Tpl.pushIter(txt, Tpl.ITER_OPTIONS(2, SOME(Tpl.ST_STRING("")), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE()));
        (txt, a_assignments, a_onPatternFail, a_varDecls) = lm_710(txt, i_patterns, a_assignments, a_onPatternFail, a_rhs, a_varDecls);
        txt = Tpl.popIter(txt);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_AS_FUNC_PTR(id = i_p_id, pat = i_p_pat),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING("*((modelica_fnptr*)&_"));
        a_assignments = Tpl.writeStr(a_assignments, i_p_id);
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING(") = "));
        a_assignments = Tpl.writeText(a_assignments, a_rhs);
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING(";"));
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_NEW_LINE());
        (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p_pat, a_rhs, a_onPatternFail, a_varDecls, a_assignments);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_AS(ty = NONE(), id = i_p_id, pat = i_p_pat),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING("_"));
        a_assignments = Tpl.writeStr(a_assignments, i_p_id);
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING(" = "));
        a_assignments = Tpl.writeText(a_assignments, a_rhs);
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING(";"));
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_NEW_LINE());
        (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p_pat, a_rhs, a_onPatternFail, a_varDecls, a_assignments);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           DAE.PAT_AS(ty = SOME(i_et), id = i_p_id, pat = i_p_pat),
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        l_unboxBuf = Tpl.emptyTxt;
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING("_"));
        a_assignments = Tpl.writeStr(a_assignments, i_p_id);
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING(" = "));
        (a_assignments, l_unboxBuf, a_varDecls) = unboxVariable(a_assignments, Tpl.textString(a_rhs), i_et, l_unboxBuf, a_varDecls);
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_STRING(";"));
        a_assignments = Tpl.writeTok(a_assignments, Tpl.ST_NEW_LINE());
        txt = Tpl.writeText(txt, l_unboxBuf);
        txt = Tpl.softNewLine(txt);
        (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments) = patternMatch(txt, i_p_pat, a_rhs, a_onPatternFail, a_varDecls, a_assignments);
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);

    case ( txt,
           _,
           a_rhs,
           a_onPatternFail,
           a_varDecls,
           a_assignments )
      equation
        txt = Tpl.writeTok(txt, Tpl.ST_STRING("UNKNOWN_PATTERN /* rhs: "));
        txt = Tpl.writeText(txt, a_rhs);
        txt = Tpl.writeTok(txt, Tpl.ST_STRING(" */"));
        txt = Tpl.writeTok(txt, Tpl.ST_NEW_LINE());
      then (txt, a_rhs, a_onPatternFail, a_varDecls, a_assignments);
  end matchcontinue;
end patternMatch;

public function assertCommon
  input Tpl.Text txt;
  input DAE.Exp a_condition;
  input DAE.Exp a_message;
  input SimCode.Context a_context;
  input Tpl.Text a_varDecls;

  output Tpl.Text out_txt;
  output Tpl.Text out_a_varDecls;
protected
  Tpl.Text l_msgVar;
  Tpl.Text l_condVar;
  Tpl.Text l_preExpMsg;
  Tpl.Text l_preExpCond;
algorithm
  l_preExpCond := Tpl.emptyTxt;
  l_preExpMsg := Tpl.emptyTxt;
  (l_condVar, l_preExpCond, out_a_varDecls) := daeExp(Tpl.emptyTxt, a_condition, a_context, l_preExpCond, a_varDecls);
  (l_msgVar, l_preExpMsg, out_a_varDecls) := daeExp(Tpl.emptyTxt, a_message, a_context, l_preExpMsg, out_a_varDecls);
  out_txt := Tpl.writeText(txt, l_preExpCond);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("if (!"));
  out_txt := Tpl.writeText(out_txt, l_condVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(") {\n"));
  out_txt := Tpl.pushBlock(out_txt, Tpl.BT_INDENT(2));
  out_txt := Tpl.writeText(out_txt, l_preExpMsg);
  out_txt := Tpl.softNewLine(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("MODELICA_ASSERT("));
  out_txt := Tpl.writeText(out_txt, l_msgVar);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_LINE(");\n"));
  out_txt := Tpl.popBlock(out_txt);
  out_txt := Tpl.writeTok(out_txt, Tpl.ST_STRING("}"));
end assertCommon;

end SimCodeC;